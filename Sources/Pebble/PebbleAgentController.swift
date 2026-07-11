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
    private var observedGoalKinds = Set<String>()
    private var activeWorld: World?
    private var overlayEnabledByCommand = false

    private let environment = ProcessInfo.processInfo.environment
    private var featureEnabled: Bool { environment["PEBBLELAB_APP_AGENTS"] == "1" }
    private var traceEnabled: Bool { environment["PEBBLELAB_APP_AGENTS_TRACE"] == "1" }
    private var overlayEnabledByEnvironment: Bool { environment["PEBBLELAB_APP_AGENTS_OVERLAY"] == "1" }

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
                guard advanceOneTick() else { return }
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
            focusedAgentId: focusedAgentId,
            observedGoalKinds: observedGoalKinds.sorted(),
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
            guard advanceOneTick() else { return failure(lastError ?? "Cognitive step failed.") }
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
        case "status":
            guard let session else {
                trace("status inactive gate=\(featureEnabled ? "enabled" : "disabled")")
                return success("PebbleAgents inactive (gate \(featureEnabled ? "enabled" : "disabled")).")
            }
            let snapshot = session.snapshot()
            let positions = snapshot.agents.map { "\($0.id)=\($0.position.x),\($0.position.y),\($0.position.z)/m\($0.movementCount)" }.joined(separator: " ")
            let message = "PebbleAgents \(isPaused ? "paused" : "running") tick=\(snapshot.tick) hz=\(cognitiveHz) probes=\(probesByAgentId.count) focus=\(focusedAgentId ?? "none") \(positions)"
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
            return failure("Usage: /lab <start|stop|clear|pause|resume|step|speed|reset|status|focus|next|overlay>")
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
            if resetSpeed { cognitiveHz = 4 }
            credit = 0
            lastWorldTick = world.time
            focusedAgentId = "agent_0"
            lastTickResult = nil
            lastError = nil
            observedGoalKinds = [AgentGoalKind.idle.rawValue]
            try createProbes(in: world)
            let verb = resetSpeed ? "start" : "reset"
            trace("\(verb) seed=\(seed) agents=3 tick=0 hz=\(cognitiveHz)")
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

    private func advanceOneTick() -> Bool {
        guard var session else { return false }
        do {
            let result = try session.advanceTick()
            self.session = session
            lastTickResult = result
            for agent in result.agents {
                observedGoalKinds.insert(agent.snapshot.currentGoal.kind.rawValue)
                guard agent.snapshot.position == agent.snapshot.homePosition,
                      agent.snapshot.distanceFromHome == 0,
                      agent.snapshot.movementCount == 0 else {
                    throw ControllerError.movementBoundary(agent.agentId)
                }
            }
            let focus = result.agents.first { $0.agentId == focusedAgentId } ?? result.agents.first
            let goals = result.agents.map { "\($0.agentId):\($0.snapshot.currentGoal.kind.rawValue)" }.joined(separator: ",")
            trace("tick=\(result.tick) goals=\(goals) focus=\(focus?.agentId ?? "none") action=\(focus?.action.name ?? "none") memory=\(focus?.snapshot.memoryCount ?? 0)")
            return true
        } catch {
            lastError = String(describing: error)
            trace("error \(error)")
            return false
        }
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
    }
}
