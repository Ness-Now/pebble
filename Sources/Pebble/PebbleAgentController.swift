import Foundation
import PebbleAgents
import PebbleCore

struct PebbleAgentCommandResult {
    let succeeded: Bool
    let message: String
}

final class PebbleAgentController {
    private(set) var session: AgentSimulationSession?
    private(set) var isPaused = false
    private(set) var cognitiveHz = 4
    private(set) var credit = 0
    private(set) var lastWorldTick: Int?
    private(set) var seed: UInt32 = 0
    private(set) var anchor: AgentPosition?
    private(set) var focusedAgentId: String?
    private(set) var probesByAgentId: [String: LabCoreAgentEntity] = [:]
    private(set) var lastTickResult: AgentSessionTickResult?
    private(set) var lastError: String?
    private(set) var movementEnabled = false
    private(set) var lastMovementOutcomes: [AgentMovementOutcome] = []
    private var observedGoalKinds = Set<String>()
    private var lastInfluencedTracesByAgentId: [String: AgentFeedbackDecisionTrace] = [:]
    private var movementWasEverEnabledSinceReset = false
    private var activeWorld: World?
    private var overlayEnabledByCommand = false
    private let worldSensor = PebbleAgentWorldSensor()
    private let movementExecutor = PebbleAgentMovementExecutor()

    private let environment = ProcessInfo.processInfo.environment
    private var featureEnabled: Bool { environment["PEBBLELAB_APP_AGENTS"] == "1" }
    private var traceEnabled: Bool { environment["PEBBLELAB_APP_AGENTS_TRACE"] == "1" }
    private var overlayEnabledByEnvironment: Bool { environment["PEBBLELAB_APP_AGENTS_OVERLAY"] == "1" }
    private var movementFeatureEnabled: Bool { environment["PEBBLELAB_APP_AGENTS_MOVE"] == "1" }

    func update(world: World?, player: Player?) {
        guard let world else {
            if session != nil { stop(reason: "world unavailable") }
            return
        }
        if let activeWorld, activeWorld !== world {
            stop(reason: "world replaced")
            return
        }
        guard session != nil else { return }
        guard player != nil else {
            stop(reason: "player unavailable")
            return
        }

        let worldTick = world.time
        guard let previousTick = lastWorldTick else {
            lastWorldTick = worldTick
            return
        }
        lastWorldTick = worldTick
        if isPaused {
            credit = 0
            return
        }
        guard worldTick >= previousTick else {
            credit = 0
            return
        }
        for _ in previousTick..<worldTick {
            credit += cognitiveHz
            while credit >= 20 {
                guard advanceOneTick(world: world) else { return }
                credit -= 20
            }
        }
    }

    func debugState(f3Visible: Bool) -> PebbleAgentDebugState? {
        guard let session,
              f3Visible || overlayEnabledByEnvironment || overlayEnabledByCommand else { return nil }
        return PebbleAgentDebugState(
            snapshot: session.snapshot(),
            paused: isPaused,
            cognitiveHz: cognitiveHz,
            movementEnabled: movementEnabled,
            focusedAgentId: focusedAgentId,
            observedGoalKinds: observedGoalKinds.sorted(),
            lastInfluencedDecisionTrace: focusedAgentId.flatMap {
                lastInfluencedTracesByAgentId[$0]
            },
            lastError: lastError
        )
    }

    func handleCommand(_ arguments: [String], world: World, player: Player) -> PebbleAgentCommandResult {
        let command = arguments.first?.lowercased() ?? "status"
        switch command {
        case "start":
            return start(world: world, player: player)
        case "stop", "clear":
            let removed = stop(reason: command)
            return success("PebbleAgents stopped; probes removed: \(removed)")
        case "pause":
            guard session != nil else { return failure("No active PebbleAgents session.") }
            isPaused = true
            lastWorldTick = world.time
            credit = 0
            trace("pause tick=\(session?.tick ?? 0)")
            return success("PebbleAgents paused at tick \(session?.tick ?? 0).")
        case "resume":
            guard session != nil else { return failure("No active PebbleAgents session.") }
            isPaused = false
            lastWorldTick = world.time
            credit = 0
            trace("resume tick=\(session?.tick ?? 0)")
            return success("PebbleAgents resumed at \(cognitiveHz) Hz.")
        case "step":
            guard session != nil else { return failure("No active PebbleAgents session.") }
            guard advanceOneTick(world: world) else { return failure(lastError ?? "Cognitive step failed.") }
            trace("step tick=\(session?.tick ?? 0)")
            return success("PebbleAgents stepped to tick \(session?.tick ?? 0).")
        case "speed":
            guard session != nil else { return failure("No active PebbleAgents session.") }
            guard arguments.count == 2, let hz = Int(arguments[1]), [1, 2, 4, 8].contains(hz) else {
                return failure("Usage: /lab speed <1|2|4|8>")
            }
            cognitiveHz = hz
            credit = 0
            return success("PebbleAgents speed set to \(hz) Hz.")
        case "reset":
            guard session != nil, activeWorld === world, let anchor else {
                return failure("No active PebbleAgents session.")
            }
            return rebuild(world: world, anchor: anchor, seed: seed, resetSpeed: false)
        case "movement":
            guard session != nil else { return failure("No active PebbleAgents session.") }
            guard arguments.count == 2, arguments[1] == "on" || arguments[1] == "off" else {
                return failure("Usage: /lab movement <on|off>")
            }
            if arguments[1] == "on" {
                guard movementFeatureEnabled else {
                    return failure("PebbleAgents movement disabled. Set PEBBLELAB_APP_AGENTS_MOVE=1 before launch.")
                }
                movementEnabled = true
                movementWasEverEnabledSinceReset = true
            } else {
                movementEnabled = false
            }
            let movementStatus = movementEnabled ? "on" : "off"
            trace("movement=\(movementStatus) tick=\(session?.tick ?? 0)")
            return success("PebbleAgents movement \(movementStatus).")
        case "status":
            guard let session else {
                trace("status inactive gate=\(featureEnabled ? "enabled" : "disabled")")
                return success("PebbleAgents inactive (gate \(featureEnabled ? "enabled" : "disabled")).")
            }
            let snapshot = session.snapshot()
            let positions = snapshot.agents.map { "\($0.id)=\($0.position.x),\($0.position.y),\($0.position.z)/m\($0.movementCount)/o\($0.observationCount)" }.joined(separator: " ")
            let message = "PebbleAgents \(isPaused ? "paused" : "running") tick=\(snapshot.tick) hz=\(cognitiveHz) movement=\(movementEnabled ? "on" : "off") probes=\(probesByAgentId.count) focus=\(focusedAgentId ?? "none") \(positions)"
            trace("status \(message)")
            return success(message)
        case "focus":
            guard session != nil else { return failure("No active PebbleAgents session.") }
            guard arguments.count == 2 else { return failure("Usage: /lab focus <agentId|next>") }
            return setFocus(arguments[1])
        case "next":
            guard session != nil else { return failure("No active PebbleAgents session.") }
            return setFocus("next")
        case "overlay":
            guard arguments.count == 2, arguments[1] == "on" || arguments[1] == "off" else {
                return failure("Usage: /lab overlay <on|off>")
            }
            overlayEnabledByCommand = arguments[1] == "on"
            return success("PebbleAgents overlay \(arguments[1]).")
        default:
            return failure("Usage: /lab <start|stop|clear|pause|resume|step|speed|reset|movement|status|focus|next|overlay>")
        }
    }

    @discardableResult
    func shutdown() -> Int {
        stop(reason: "termination")
    }

    private func start(world: World, player: Player) -> PebbleAgentCommandResult {
        guard featureEnabled else {
            trace("error disabled; set PEBBLELAB_APP_AGENTS=1")
            return failure("PebbleAgents disabled. Set PEBBLELAB_APP_AGENTS=1 before launch.")
        }
        if session != nil || activeWorld != nil { _ = stop(reason: "restart") }
        let anchor = AgentPosition(
            x: Int(player.x.rounded(.down)),
            y: Int(player.y.rounded(.down)),
            z: Int(player.z.rounded(.down))
        )
        return rebuild(world: world, anchor: anchor, seed: world.seed, resetSpeed: true)
    }

    private func rebuild(world: World, anchor: AgentPosition, seed: UInt32, resetSpeed: Bool) -> PebbleAgentCommandResult {
        let preservedMovementEnabled = movementEnabled
        _ = clearLabCoreAgentProbes(in: world)
        probesByAgentId.removeAll()
        do {
            let configuration = try AgentSessionConfiguration(
                seed: seed,
                nearbyRadius: 8,
                recentMemorySnapshotLimit: 6,
                memoryPolicy: .bounded(maxEntries: 128)
            )
            session = try AgentSimulationSession(
                configuration: configuration,
                agents: initialAgentStates(anchor: anchor),
                initialTick: 0
            )
            self.seed = seed
            self.anchor = anchor
            activeWorld = world
            isPaused = false
            if resetSpeed {
                cognitiveHz = 4
                movementEnabled = movementFeatureEnabled
            } else {
                movementEnabled = preservedMovementEnabled
            }
            movementWasEverEnabledSinceReset = movementEnabled
            lastMovementOutcomes = []
            lastInfluencedTracesByAgentId.removeAll()
            credit = 0
            lastWorldTick = world.time
            focusedAgentId = "agent_0"
            lastTickResult = nil
            lastError = nil
            observedGoalKinds = [AgentGoalKind.idle.rawValue]
            try createProbes(in: world)
            let verb = resetSpeed ? "start" : "reset"
            trace("\(verb) seed=\(seed) agents=3 tick=0 hz=\(cognitiveHz) movement=\(movementEnabled ? "on" : "off")")
            return success(resetSpeed ? "PebbleAgents started: 3 agents at 4 Hz." : "PebbleAgents reset to tick 0.")
        } catch {
            lastError = String(describing: error)
            _ = stop(reason: "start failure")
            trace("error \(error)")
            return failure("PebbleAgents start failed: \(error)")
        }
    }

    private func initialAgentStates(anchor: AgentPosition) -> [AgentSessionAgentState] {
        let specifications: [(String, AgentPosition, Int, Double, Double)] = [
            ("agent_0", AgentPosition(x: anchor.x - 2, y: anchor.y, z: anchor.z), 80, 0, 0.2),
            ("agent_1", AgentPosition(x: anchor.x, y: anchor.y, z: anchor.z + 2), 10, 0.03, 0.2),
            ("agent_2", AgentPosition(x: anchor.x + 2, y: anchor.y, z: anchor.z), 10, 0, 0.9),
        ]
        return specifications.map { id, position, fear, fatigue, curiosity in
            AgentSessionAgentState(
                id: id,
                state: "idle",
                position: position,
                needs: AgentNeeds(hunger: 0, fatigue: fatigue, curiosity: curiosity, safety: 1),
                health: 100,
                fear: fear,
                homePosition: position,
                nearbyAgents: [],
                currentGoal: AgentGoal(kind: .idle, reason: "initial goal", startedAtTick: 0, urgency: 0),
                lastAction: nil,
                lastActionEffect: nil,
                memory: [],
                tickCreated: 0,
                ticksAlive: 0,
                observationCount: 0,
                nearbyObservationCount: 0,
                goalSelectionCount: 0,
                goalChangeCount: 0,
                actionCount: 0,
                actionEffectCount: 0,
                movementCount: 0,
                totalManhattanDistanceMoved: 0,
                returnHomeMoveCount: 0,
                totalDistanceReducedTowardHome: 0
            )
        }
    }

    private func createProbes(in world: World) throws {
        guard let session else { throw ControllerError.missingSession }
        for agent in session.snapshot().agents {
            let probe = LabCoreAgentEntity(
                world: world,
                labAgentId: agent.id,
                physicalId: "pebble_app_agent_\(agent.id)"
            )
            guard !probe.shouldSaveToChunk else { throw ControllerError.persistableProbe(agent.id) }
            probe.setPos(Double(agent.position.x) + 0.5, Double(agent.position.y), Double(agent.position.z) + 0.5)
            probe.prevX = probe.x
            probe.prevY = probe.y
            probe.prevZ = probe.z
            world.addEntity(probe)
            probesByAgentId[agent.id] = probe
        }
        let ids = world.entities.compactMap { $0 as? LabCoreAgentEntity }.map(\.labAgentId).sorted()
        let expected = session.snapshot().agents.map(\.id).sorted()
        guard ids == expected, probesByAgentId.count == 3 else {
            throw ControllerError.invalidProbeSet(ids)
        }
    }

    private func advanceOneTick(world: World) -> Bool {
        guard activeWorld === world, var session else { return false }
        do {
            let preCognitive = session.snapshot()
            let perceptions = try preCognitive.agents.map { agent in
                AgentPerceptionInput(
                    agentId: agent.id,
                    worldObservation: try worldSensor.observe(world: world, agent: agent)
                )
            }
            let result = try session.advanceTick(perceptions: perceptions)
            if movementEnabled {
                let outcomes = AgentMovementCoordinator.resolve(snapshot: session.snapshot())
                try session.applyMovementOutcomes(outcomes)
                try movementExecutor.apply(outcomes: outcomes, probesByAgentId: probesByAgentId)
                lastMovementOutcomes = outcomes
            } else {
                lastMovementOutcomes = []
            }
            let finalSnapshot = session.snapshot()
            try validatePostTick(snapshot: finalSnapshot, result: result)
            self.session = session
            lastTickResult = result
            for agent in finalSnapshot.agents { observedGoalKinds.insert(agent.currentGoal.kind.rawValue) }
            for agent in finalSnapshot.agents {
                if let trace = agent.lastFeedbackDecisionTrace,
                   trace.actionChanged,
                   !trace.memoryRecordsUsed.isEmpty {
                    lastInfluencedTracesByAgentId[agent.id] = trace
                }
            }
            let focus = finalSnapshot.agents.first { $0.id == focusedAgentId } ?? finalSnapshot.agents.first
            let goals = finalSnapshot.agents.map { "\($0.id):\($0.currentGoal.kind.rawValue)" }.joined(separator: ",")
            let perception = focus?.lastWorldObservation
            let safety = focus?.lastWorldPerceptionEffect?.safetyAfter ?? 0
            let perceptionSummary = "t\(perception?.traversableNeighborCount ?? 0)/b\(perception?.blockedNeighborCount ?? 0)/d\(perception?.dangerousDropCount ?? 0)/s\(String(format: "%.2f", safety))"
            let observations = finalSnapshot.agents.map { "\($0.id):\($0.observationCount)" }.joined(separator: ",")
            let moved = lastMovementOutcomes.filter { $0.status == .moved }.count
            let blocked = lastMovementOutcomes.filter { $0.status == .blocked }.count
            let outcomes = lastMovementOutcomes.map { "\($0.agentId):\($0.status.rawValue)" }.joined(separator: ",")
            let positions = finalSnapshot.agents.map { "\($0.id):\($0.position.x),\($0.position.y),\($0.position.z)/m\($0.movementCount)" }.joined(separator: ";")
            let focusMovement = focus?.lastMovementOutcome.map { outcome in
                if outcome.status == .blocked { return "blocked:\(outcome.resolutionReason)" }
                let direction = outcome.requestedDirection?.rawValue ?? "none"
                return "\(outcome.status.rawValue):\(direction):from=\(positionText(outcome.fromPosition)):to=\(positionText(outcome.toPosition))"
            } ?? "none"
            let retrieved = finalSnapshot.agents.reduce(0) { $0 + $1.memoryRetrievalCount }
            let influenced = finalSnapshot.agents.reduce(0) { $0 + $1.memoryInfluencedDecisionCount }
            let deduplicated = finalSnapshot.agents.reduce(0) { $0 + $1.feedbackMemoryDeduplicatedCount }
            let currentInfluenced = finalSnapshot.agents.first {
                $0.lastFeedbackDecisionTrace?.actionChanged == true
                    && !($0.lastFeedbackDecisionTrace?.memoryRecordsUsed.isEmpty ?? true)
            }
            let decisionAgent = (
                focus?.lastFeedbackDecisionTrace?.actionChanged == true ? focus : currentInfluenced
            ) ?? focus
            let decision = decisionAgent?.lastFeedbackDecisionTrace
            let memoryUsed = decision?.memoryRecordsUsed.first.map { "\($0.type)@\($0.tick)" } ?? "none"
            let baseMove = decision?.baseDirection?.rawValue ?? decision?.baseAction.name ?? "none"
            let finalMove = decision?.finalDirection?.rawValue ?? decision?.finalAction.name ?? "none"
            let dominant = decision?.dominantFactor.kind.rawValue ?? "none"
            let decisionReason = decision?.reason.replacingOccurrences(of: " ", with: "_") ?? "none"
            trace("tick=\(result.tick) movement=\(movementEnabled ? "on" : "off") moved=\(moved) blocked=\(blocked) outcomes=\(outcomes) positions=\(positions) goals=\(goals) focus=\(focus?.id ?? "none") action=\(focus?.lastAction?.name ?? "none") focusMove=\(focusMovement) memory=\(focus?.memoryCount ?? 0) retrieved=\(retrieved) influenced=\(influenced) dedup=\(deduplicated) decisionAgent=\(decisionAgent?.id ?? "none") memoryUsed=\(memoryUsed) decisionChanged=\(decision?.actionChanged == true ? 1 : 0) baseMove=\(baseMove) finalMove=\(finalMove) dominant=\(dominant) decisionReason=\(decisionReason) world_observed=1 perception=\(perceptionSummary) observations=\(observations)")
            return true
        } catch {
            lastError = String(describing: error)
            trace("error \(error)")
            return false
        }
    }

    private func validatePostTick(snapshot: AgentSessionSnapshot, result: AgentSessionTickResult) throws {
        var positions = Set<String>()
        for agent in snapshot.agents {
            guard agent.lastWorldObservation != nil,
                  agent.lastWorldPerceptionEffect != nil,
                  agent.observationCount >= result.tick,
                  positions.insert(positionText(agent.position)).inserted,
                  let probe = probesByAgentId[agent.id],
                  probe.labAgentId == agent.id,
                  probe.x == Double(agent.position.x) + 0.5,
                  probe.y == Double(agent.position.y),
                  probe.z == Double(agent.position.z) + 0.5 else {
                throw ControllerError.movementBoundary(agent.id)
            }
            guard agent.memoryCount <= 128,
                  agent.memoryRetrievalCount >= agent.memoryInfluencedDecisionCount,
                  let decision = agent.lastFeedbackDecisionTrace else {
                throw ControllerError.feedbackBoundary(agent.id)
            }
            if !decision.memoryRecordsUsed.isEmpty {
                guard decision.actionChanged,
                      decision.dominantFactor.kind == .movementFeedback else {
                    throw ControllerError.feedbackBoundary(agent.id)
                }
            }
            if movementEnabled, agent.distanceFromHome > 8 {
                throw ControllerError.feedbackBoundary(agent.id)
            }
            if !movementWasEverEnabledSinceReset {
                guard agent.position == agent.homePosition,
                      agent.distanceFromHome == 0,
                      agent.movementCount == 0 else {
                    throw ControllerError.movementBoundary(agent.id)
                }
            }
            if let outcome = agent.lastMovementOutcome,
               outcome.tick == result.tick,
               outcome.status == .moved {
                guard agent.movementCount > 0,
                      let observation = agent.lastWorldObservation,
                      let direction = outcome.requestedDirection,
                      let neighbor = observation.neighbors.first(where: { $0.direction == direction }),
                      neighbor.traversable,
                      !neighbor.dangerousDrop,
                      neighbor.column.chunkReady else {
                    throw ControllerError.unsafeMovement(agent.id)
                }
            }
        }
        guard probesByAgentId.count == snapshot.agentCount else {
            throw ControllerError.invalidProbeSet(probesByAgentId.keys.sorted())
        }
    }

    private func positionText(_ position: AgentPosition) -> String {
        "\(position.x),\(position.y),\(position.z)"
    }

    private func setFocus(_ requested: String) -> PebbleAgentCommandResult {
        guard let session else { return failure("No active PebbleAgents session.") }
        let ids = session.snapshot().agents.map(\.id)
        let next: String
        if requested.lowercased() == "next" {
            let index = ids.firstIndex(of: focusedAgentId ?? "") ?? -1
            next = ids[(index + 1) % ids.count]
        } else {
            guard ids.contains(requested) else { return failure("Unknown agent id: \(requested)") }
            next = requested
        }
        focusedAgentId = next
        return success("PebbleAgents focus: \(next).")
    }

    @discardableResult
    private func stop(reason: String) -> Int {
        let removed = activeWorld.map { clearLabCoreAgentProbes(in: $0) } ?? 0
        session = nil
        activeWorld = nil
        probesByAgentId.removeAll()
        isPaused = false
        credit = 0
        lastWorldTick = nil
        anchor = nil
        focusedAgentId = nil
        lastTickResult = nil
        movementEnabled = false
        movementWasEverEnabledSinceReset = false
        lastMovementOutcomes = []
        lastInfluencedTracesByAgentId.removeAll()
        observedGoalKinds.removeAll()
        overlayEnabledByCommand = false
        trace("stop probesRemoved=\(removed) reason=\(reason)")
        return removed
    }

    private func success(_ message: String) -> PebbleAgentCommandResult {
        PebbleAgentCommandResult(succeeded: true, message: message)
    }

    private func failure(_ message: String) -> PebbleAgentCommandResult {
        lastError = message
        trace("error \(message)")
        return PebbleAgentCommandResult(succeeded: false, message: message)
    }

    private func trace(_ message: String) {
        guard traceEnabled else { return }
        print("[lab-live] \(message)")
        fflush(stdout)
    }

    private enum ControllerError: Error {
        case missingSession
        case persistableProbe(String)
        case invalidProbeSet([String])
        case movementBoundary(String)
        case unsafeMovement(String)
        case feedbackBoundary(String)
    }
}
