import Foundation
import PebbleAgents
import PebbleCore

struct PebbleAgentCommandResult {
    let succeeded: Bool
    let message: String
}

final class PebbleAgentController {
    private static let maxCognitiveStepsPerUpdate = 8
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
    private var overlayModeByCommand: PebbleAgentOverlayMode?
    private(set) var followMode: PebbleAgentFollowMode = .off
    private(set) var demoActive = false
    private(set) var successfulCognitiveTicks = 0
    private(set) var blockedMovementOutcomeCount = 0
    private(set) var runtimeErrorCount = 0
    private(set) var droppedCatchUpSteps = 0
    private(set) var maxObservedMemoryCount = 0
    private(set) var maxObservedDistanceFromHome = 0
    private let worldSensor = PebbleAgentWorldSensor()
    private let navigationAdapter = PebbleAgentNavigationAdapter()
    private let movementExecutor = PebbleAgentMovementExecutor()
    private let cameraFollow = PebbleAgentCameraFollow()
    private var interactionExecutor = PebbleAgentInteractionExecutor()
    private(set) var autoInteractionEnabled = false
    private var lastAutoInteractionReason = "none"
    private var lastInteractionAttempted = false
    private var lastInteractionSucceeded = false
    private var lastInteractionBlocked = false
    private(set) var economyAutoEnabled = false
    private var lastEconomyReason = "none"
    private var lastDeliverySucceeded = false

    private let environment = ProcessInfo.processInfo.environment
    private var featureEnabled: Bool { environment["PEBBLELAB_APP_AGENTS"] == "1" }
    private var traceEnabled: Bool { environment["PEBBLELAB_APP_AGENTS_TRACE"] == "1" }
    private var overlayEnabledByEnvironment: Bool { environment["PEBBLELAB_APP_AGENTS_OVERLAY"] == "1" }
    private var movementFeatureEnabled: Bool { environment["PEBBLELAB_APP_AGENTS_MOVE"] == "1" }
    private var probesFeatureEnabled: Bool { environment["PEBBLELAB_APP_PROBES"] == "1" }
    private var debugEntitiesEnabled: Bool { environment["PEBBLELAB_DEBUG_ENTITIES"] == "1" }
    private var interactionFeatureEnabled: Bool { environment["PEBBLELAB_APP_AGENTS_INTERACT"] == "1" }
    private var traceEvery: Int {
        guard let raw = environment["PEBBLELAB_APP_AGENTS_TRACE_EVERY"],
              let value = Int(raw), (1...1000).contains(value) else { return 1 }
        return value
    }

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
        guard let player else {
            stop(reason: "player unavailable")
            return
        }
        applyFollow(player: player)

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
        let elapsedWorldTicks = worldTick - previousTick
        credit += elapsedWorldTicks * cognitiveHz
        let availableSteps = credit / 20
        let executedSteps = min(availableSteps, Self.maxCognitiveStepsPerUpdate)
        for _ in 0..<executedSteps {
            guard advanceOneTick(world: world, player: player) else { return }
            credit -= 20
        }
        if availableSteps > Self.maxCognitiveStepsPerUpdate {
            let dropped = availableSteps - Self.maxCognitiveStepsPerUpdate
            droppedCatchUpSteps += dropped
            credit %= 20
            trace("catchup dropped=\(dropped) total=\(droppedCatchUpSteps)")
        }
    }

    func debugState(f3Visible: Bool) -> PebbleAgentDebugState? {
        let mode = overlayModeByCommand
            ?? (f3Visible ? .full : overlayEnabledByEnvironment ? .compact : .off)
        guard let session, mode != .off else { return nil }
        let latestInfluenced = lastInfluencedTracesByAgentId.sorted {
            if $0.value.tick != $1.value.tick { return $0.value.tick > $1.value.tick }
            return $0.key < $1.key
        }.first
        let focusedInfluenced = focusedAgentId.flatMap { lastInfluencedTracesByAgentId[$0] }
        return PebbleAgentDebugState(
            snapshot: session.snapshot(),
            mode: mode,
            paused: isPaused,
            cognitiveHz: cognitiveHz,
            movementEnabled: movementEnabled,
            followMode: followMode,
            demoActive: demoActive,
            focusedAgentId: focusedAgentId,
            observedGoalKinds: observedGoalKinds.sorted(),
            lastInfluencedDecisionTrace: focusedInfluenced ?? latestInfluenced?.value,
            lastInfluencedDecisionAgentId: focusedInfluenced == nil ? latestInfluenced?.key : focusedAgentId,
            runtimeErrorCount: runtimeErrorCount,
            droppedCatchUpSteps: droppedCatchUpSteps,
            lastError: lastError,
            interaction: interactionExecutor.state(
                gateEnabled: interactionFeatureEnabled,
                autoEnabled: autoInteractionEnabled,
                autoReason: lastAutoInteractionReason
            ),
            economyFixtures: interactionExecutor.economyState(),
            economyReason: lastEconomyReason
        )
    }

    func handleCommand(_ arguments: [String], world: World, player: Player) -> PebbleAgentCommandResult {
        let command = arguments.first?.lowercased() ?? "status"
        switch command {
        case "help":
            guard arguments.count == 1 else { return failure("Usage: /lab help") }
            return success("/lab lifecycle: start stop clear | time control: pause resume step speed <1|2|4|8> reset | inspection: status focus <agentId|next> next follow <agentId|focus|next|off> overlay <off|compact|full> | movement: movement <on|off> | interaction: interaction <setup|setup distant <2...8>|harvest|status|auto on|auto off> | economy: economy <setup|auto on|auto off|status|clear> | demo: demo [start|stop|status]")
        case "demo":
            return handleDemo(Array(arguments.dropFirst()), world: world, player: player)
        case "start":
            guard arguments.count == 1 else { return failure("Usage: /lab start") }
            return start(world: world, player: player)
        case "stop", "clear":
            guard arguments.count == 1 else { return failure("Usage: /lab \(command)") }
            let removed = stop(reason: command, fallbackWorld: world)
            return success("PebbleAgents stopped; probes removed: \(removed)")
        case "pause":
            guard arguments.count == 1 else { return failure("Usage: /lab pause") }
            guard session != nil else { return failure("No active PebbleAgents session.") }
            isPaused = true
            lastWorldTick = world.time
            credit = 0
            trace("pause tick=\(session?.tick ?? 0)")
            return success("PebbleAgents paused at tick \(session?.tick ?? 0).")
        case "resume":
            guard arguments.count == 1 else { return failure("Usage: /lab resume") }
            guard session != nil else { return failure("No active PebbleAgents session.") }
            isPaused = false
            lastWorldTick = world.time
            credit = 0
            trace("resume tick=\(session?.tick ?? 0)")
            return success("PebbleAgents resumed at \(cognitiveHz) Hz.")
        case "step":
            guard arguments.count == 1 else { return failure("Usage: /lab step") }
            guard session != nil else { return failure("No active PebbleAgents session.") }
            guard advanceOneTick(world: world, player: player) else { return failure(lastError ?? "Cognitive step failed.") }
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
            guard arguments.count == 1 else { return failure("Usage: /lab reset") }
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
        case "interaction":
            return handleInteraction(Array(arguments.dropFirst()), world: world, player: player)
        case "economy":
            return handleEconomy(Array(arguments.dropFirst()), world: world, player: player)
        case "status":
            guard arguments.count == 1 else { return failure("Usage: /lab status") }
            guard let session else {
                trace("status inactive gate=\(featureEnabled ? "enabled" : "disabled")")
                return success("PebbleAgents inactive (gate \(featureEnabled ? "enabled" : "disabled")).")
            }
            let snapshot = session.snapshot()
            let positions = snapshot.agents.map { "\($0.id)=\($0.position.x),\($0.position.y),\($0.position.z)/m\($0.movementCount)/o\($0.observationCount)" }.joined(separator: " ")
            let overlay = effectiveOverlayMode(f3Visible: false).rawValue
            let message = "PebbleAgents \(isPaused ? "paused" : "running") tick=\(snapshot.tick) hz=\(cognitiveHz) movement=\(movementEnabled ? "on" : "off") autoInteraction=\(autoInteractionEnabled ? "on" : "off") economy=\(snapshot.economyEnabled ? "on" : "off") probes=\(probesByAgentId.count) focus=\(focusedAgentId ?? "none") follow=\(followMode.statusText) overlay=\(overlay) demo=\(demoActive ? "on" : "off") catchupDropped=\(droppedCatchUpSteps) \(positions)"
            trace("status \(message)")
            return success(message)
        case "focus":
            guard session != nil else { return failure("No active PebbleAgents session.") }
            guard arguments.count == 2 else { return failure("Usage: /lab focus <agentId|next>") }
            return setFocus(arguments[1])
        case "next":
            guard arguments.count == 1 else { return failure("Usage: /lab next") }
            guard session != nil else { return failure("No active PebbleAgents session.") }
            return setFocus("next")
        case "follow":
            guard session != nil else { return failure("No active PebbleAgents session.") }
            guard arguments.count == 2 else { return failure("Usage: /lab follow <agentId|focus|next|off>") }
            let requested = arguments[1]
            switch requested.lowercased() {
            case "off":
                followMode = .off
            case "focus":
                followMode = .focusedAgent
            case "next":
                let result = setFocus("next")
                guard result.succeeded else { return result }
                followMode = .focusedAgent
            default:
                guard probesByAgentId[requested] != nil else { return failure("Unknown agent id: \(requested)") }
                followMode = .fixedAgent(requested)
            }
            trace("follow=\(followMode.statusText) tick=\(session?.tick ?? 0)")
            applyFollow(player: player)
            return success("PebbleAgents follow: \(followMode.statusText).")
        case "overlay":
            guard arguments.count == 2 else {
                return failure("Usage: /lab overlay <off|compact|full>")
            }
            let requested = arguments[1].lowercased()
            switch requested {
            case "off": overlayModeByCommand = .off
            case "on", "compact": overlayModeByCommand = .compact
            case "full": overlayModeByCommand = .full
            default: return failure("Usage: /lab overlay <off|compact|full>")
            }
            return success("PebbleAgents overlay \(overlayModeByCommand!.rawValue).")
        default:
            return failure("Unknown /lab command. Use /lab help.")
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
        let preservedFocus = focusedAgentId
        let preservedFollowMode = followMode
        let preservedDemoActive = demoActive
        guard interactionExecutor.cleanup(world: world) else {
            return failure("PebbleAgents rebuild refused: interaction sandbox cleanup failed.")
        }
        interactionExecutor.clearBoundaryAudit()
        _ = clearLabCoreAgentProbes(in: world)
        probesByAgentId.removeAll()
        do {
            let configuration = try AgentSessionConfiguration(
                seed: seed,
                nearbyRadius: 8,
                resourceObservationRadius: 8,
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
            focusedAgentId = resetSpeed ? "agent_0" : (preservedFocus ?? "agent_0")
            followMode = resetSpeed ? .off : preservedFollowMode
            demoActive = resetSpeed ? false : preservedDemoActive
            lastTickResult = nil
            lastError = nil
            autoInteractionEnabled = false
            lastAutoInteractionReason = "none"
            lastInteractionAttempted = false
            lastInteractionSucceeded = false
            lastInteractionBlocked = false
            economyAutoEnabled = false
            lastEconomyReason = "none"
            lastDeliverySucceeded = false
            observedGoalKinds = [AgentGoalKind.idle.rawValue]
            resetRunCounters()
            try createProbes(in: world)
            if followTargetId() == nil { followMode = .off }
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
            ("agent_0", AgentPosition(x: anchor.x + 6, y: anchor.y, z: anchor.z - 3), 80, 0, 0.2),
            ("agent_1", AgentPosition(x: anchor.x + 7, y: anchor.y, z: anchor.z - 3), 10, 0.03, 0.2),
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
            guard !probe.shouldSaveToChunk, !probe.persistent else {
                throw ControllerError.persistableProbe(agent.id)
            }
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

    private func advanceOneTick(world: World, player: Player) -> Bool {
        guard activeWorld === world, var session else { return false }
        lastInteractionAttempted = false
        lastInteractionSucceeded = false
        lastInteractionBlocked = false
        lastDeliverySucceeded = false
        do {
            let preCognitive = session.snapshot()
            let perceptions = try preCognitive.agents.map { agent in
                let resourceObservations: [AgentResourceObservation]
                if autoInteractionEnabled || economyAutoEnabled {
                    guard let anchor else { throw ControllerError.missingSession }
                    resourceObservations = try interactionExecutor.resourceObservations(
                        world: world,
                        agent: agent,
                        anchor: anchor,
                        maximumDistance: session.configuration.resourceObservationRadius
                    )
                } else {
                    resourceObservations = []
                }
                let navigationObservation: AgentNavigationObservation?
                let navigationTarget: AgentPosition?
                let navigationGoalMode: AgentNavigationGoalMode
                if agent.currentGoal.kind == .deliverResources,
                   !agent.resourceInventory.isEmpty {
                    navigationTarget = agent.homePosition
                    navigationGoalMode = .exact
                } else {
                    navigationTarget = agent.activeResourceTarget?.target
                        ?? resourceObservations.first?.target
                    navigationGoalMode = .cardinalAdjacent
                }
                if movementEnabled, let target = navigationTarget {
                    navigationObservation = navigationAdapter.observe(
                        world: world,
                        agent: agent,
                        target: target,
                        occupiedAgentPositions: preCognitive.agents
                            .filter { $0.id != agent.id }
                            .map(\.position),
                        goalMode: navigationGoalMode
                    )
                } else {
                    navigationObservation = nil
                }
                return AgentPerceptionInput(
                    agentId: agent.id,
                    worldObservation: try worldSensor.observe(world: world, agent: agent),
                    resourceObservations: resourceObservations,
                    navigationObservation: navigationObservation
                )
            }
            let result = try session.advanceTick(perceptions: perceptions)
            let interactionActions = result.agents
                .filter { $0.action.name == "harvest_block" }
                .sorted { $0.agentId < $1.agentId }
            if let interaction = interactionActions.first {
                guard autoInteractionEnabled || economyAutoEnabled else {
                    throw ControllerError.interactionBoundary("harvest action without automatic interaction")
                }
                lastInteractionAttempted = true
                _ = try performHarvestTransaction(
                    world: world,
                    player: player,
                    actorId: interaction.agentId,
                    expectedAction: interaction.action,
                    interactionPrefix: "g2",
                    session: &session
                )
                lastInteractionSucceeded = true
                lastAutoInteractionReason = "automatic harvest succeeded"
            }
            let deliveryActions = result.agents
                .filter { $0.action.name == "deliver_resource" }
                .sorted { $0.agentId < $1.agentId }
            if let delivery = deliveryActions.first {
                guard economyAutoEnabled else {
                    throw ControllerError.interactionBoundary("delivery action without automatic economy")
                }
                let actor = session.snapshot().agents.first { $0.id == delivery.agentId }!
                let deliveryId = "economy-delivery:\(delivery.agentId):\(session.tick)"
                let outcome = try session.deliverResources(AgentDeliveryIntent(
                    deliveryId: deliveryId,
                    agentId: delivery.agentId,
                    tick: session.tick,
                    position: actor.position
                ))
                lastDeliverySucceeded = outcome.status == .succeeded
                lastEconomyReason = outcome.reason
            }
            if movementEnabled {
                let outcomes = AgentMovementCoordinator.resolve(snapshot: session.snapshot())
                try session.applyMovementOutcomes(outcomes)
                let finalSnapshot = session.snapshot()
                try movementExecutor.apply(
                    outcomes: outcomes,
                    probesByAgentId: probesByAgentId,
                    postApplyValidation: {
                        try validatePostTick(snapshot: finalSnapshot, result: result)
                    }
                )
                lastMovementOutcomes = outcomes
            } else {
                lastMovementOutcomes = []
                try validatePostTick(snapshot: session.snapshot(), result: result)
            }
            let finalSnapshot = session.snapshot()
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
            let resourceSeen = focus?.lastResourceObservations.first.map {
                "\($0.resource.rawValue)@\(positionText($0.target))"
            } ?? "none"
            let resourceDistance = focus?.lastResourceObservations.first?.distanceManhattan ?? 0
            let activeResourceTarget = focus?.activeResourceTarget.map {
                "\(positionText($0.target))@selected\($0.selectedAtTick)/seen\($0.lastSeenAtTick)"
            } ?? "none"
            let navigation = focus?.navigationProgress
            let reservationOwner = focus?.resourceReservation?.agentId ?? "none"
            let routeNext = navigation?.nextStep.map(positionText) ?? "none"
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
            let economyFixtures = interactionExecutor.economyState()
            let fixtureSummary = economyFixtures.fixtures.map {
                "\($0.fixtureId):\($0.harvested ? "harvested" : "available")"
            }.joined(separator: ",")
            let inventorySummary = AgentResourceKind.allCases.map {
                "\($0.rawValue):\(focus?.resourceInventory.count(of: $0) ?? 0)"
            }.joined(separator: ",")
            let stockSummary = AgentResourceKind.allCases.map {
                "\($0.rawValue):\(finalSnapshot.campStock.count(of: $0))"
            }.joined(separator: ",")
            let deliveryOutcome = focus?.lastDeliveryOutcome
            successfulCognitiveTicks += 1
            blockedMovementOutcomeCount += blocked
            maxObservedMemoryCount = max(maxObservedMemoryCount, finalSnapshot.agents.map(\.memoryCount).max() ?? 0)
            maxObservedDistanceFromHome = max(maxObservedDistanceFromHome, finalSnapshot.agents.map(\.distanceFromHome).max() ?? 0)
            let message = "tick=\(result.tick) movement=\(movementEnabled ? "on" : "off") moved=\(moved) blocked=\(blocked) outcomes=\(outcomes) positions=\(positions) goals=\(goals) focus=\(focus?.id ?? "none") action=\(focus?.lastAction?.name ?? "none") focusMove=\(focusMovement) memory=\(focus?.memoryCount ?? 0) retrieved=\(retrieved) influenced=\(influenced) dedup=\(deduplicated) decisionAgent=\(decisionAgent?.id ?? "none") memoryUsed=\(memoryUsed) decisionChanged=\(decision?.actionChanged == true ? 1 : 0) baseMove=\(baseMove) finalMove=\(finalMove) dominant=\(dominant) decisionReason=\(decisionReason) world_observed=1 perception=\(perceptionSummary) observations=\(observations) resourceSeen=\(resourceSeen) resourceDistance=\(resourceDistance) activeTarget=\(activeResourceTarget) reservationOwner=\(reservationOwner) navigationPurpose=\(navigation?.route?.purpose.rawValue ?? "none") navigation=\(navigation?.status.rawValue ?? "idle") routeLength=\(navigation?.route?.positions.count ?? 0) routeIndex=\(navigation?.routeIndex ?? 0) stepsRemaining=\(navigation?.stepsRemaining ?? 0) nextStep=\(routeNext) replans=\(navigation?.replanCount ?? 0) invalidation=\(navigation?.lastInvalidation?.rawValue ?? "none") navigationFailure=\(navigation?.lastFailure?.rawValue ?? "none") autoInteraction=\(autoInteractionEnabled ? "on" : "off") interactionAttempted=\(lastInteractionAttempted ? 1 : 0) interactionSucceeded=\(lastInteractionSucceeded ? 1 : 0) interactionBlocked=\(lastInteractionBlocked ? 1 : 0) economy=\(finalSnapshot.economyEnabled ? "on" : "off") quota=\(finalSnapshot.deliveryQuota) inventoryByResource=\(inventorySummary) campStock=\(stockSummary) fixtures=\(fixtureSummary) deliveryOutcome=\(deliveryOutcome?.status.rawValue ?? "none") deliverySucceeded=\(lastDeliverySucceeded ? 1 : 0) conservation=\(finalSnapshot.conservation.harvestedTotal):\(finalSnapshot.conservation.carriedTotal)+\(finalSnapshot.conservation.campStockTotal):\(finalSnapshot.conservation.balanced ? "exact" : "diverged") corridorObserved=\(economyFixtures.corridorObservedBlockCount) corridorChanged=\(economyFixtures.corridorChangedDuringNavigation) fixtureSetupMutations=\(economyFixtures.setupMutatedBlockCount)"
            traceTick(
                message,
                tick: result.tick,
                important: decision?.actionChanged == true || lastInteractionAttempted
            )
            return true
        } catch {
            if autoInteractionEnabled {
                autoInteractionEnabled = false
                lastInteractionBlocked = true
                lastAutoInteractionReason = "disabled after blocking failure: \(error)"
            }
            if economyAutoEnabled {
                economyAutoEnabled = false
                lastEconomyReason = "disabled after blocking failure: \(error)"
            }
            lastError = String(describing: error)
            runtimeErrorCount += 1
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

    private func handleDemo(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let subcommand = arguments.first?.lowercased() ?? "start"
        guard arguments.count <= 1 else { return failure("Usage: /lab demo [start|stop|status]") }
        switch subcommand {
        case "start":
            let gates = [
                ("PEBBLELAB_APP_AGENTS=1", featureEnabled),
                ("PEBBLELAB_APP_AGENTS_MOVE=1", movementFeatureEnabled),
                ("PEBBLELAB_APP_PROBES=1", probesFeatureEnabled),
                ("PEBBLELAB_DEBUG_ENTITIES=1", debugEntitiesEnabled),
            ]
            let missing = gates.filter { !$0.1 }.map(\.0)
            guard missing.isEmpty else {
                return failure("PebbleAgents demo refused; missing gates: \(missing.joined(separator: ", "))")
            }
            if session != nil || activeWorld != nil {
                _ = stop(reason: "demo restart", fallbackWorld: world)
            }
            let result = start(world: world, player: player)
            guard result.succeeded else { return result }
            cognitiveHz = 4
            isPaused = false
            movementEnabled = true
            movementWasEverEnabledSinceReset = true
            focusedAgentId = "agent_2"
            followMode = .focusedAgent
            overlayModeByCommand = .compact
            demoActive = true
            credit = 0
            lastWorldTick = world.time
            applyFollow(player: player)
            trace("demo start agents=3 hz=4 movement=on focus=agent_2 follow=focus overlay=compact")
            return success("PebbleAgents demo active: 3 agents, 4 Hz, movement on, focus agent_2, follow focus, overlay compact.")
        case "stop":
            let removed = stop(reason: "demo stop", fallbackWorld: world)
            trace("demo stop probesRemoved=\(removed)")
            return success("PebbleAgents demo stopped; probes removed: \(removed).")
        case "status":
            let active = session != nil
            return success("PebbleAgents demo \(demoActive && active ? "active" : "inactive") session=\(active ? "active" : "inactive") agents=\(session?.snapshot().agentCount ?? 0) hz=\(cognitiveHz) movement=\(movementEnabled ? "on" : "off") focus=\(focusedAgentId ?? "none") follow=\(followMode.statusText) overlay=\(effectiveOverlayMode(f3Visible: false).rawValue) probes=\(probesByAgentId.count).")
        default:
            return failure("Usage: /lab demo [start|stop|status]")
        }
    }

    private func handleEconomy(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab economy <setup|auto on|auto off|status|clear>"
        guard let subcommand = arguments.first?.lowercased() else { return failure(usage) }

        if subcommand == "status" {
            guard arguments.count == 1 else { return failure(usage) }
            let fixtures = interactionExecutor.economyState()
            let snapshot = session?.snapshot()
            let actor = fixtures.fixtures.first?.actorId ?? focusedAgentId
            let agent = snapshot?.agents.first { $0.id == actor }
            let inventory = AgentResourceKind.allCases.map {
                "\($0.rawValue):\(agent?.resourceInventory.count(of: $0) ?? 0)"
            }.joined(separator: ",")
            let stock = AgentResourceKind.allCases.map {
                "\($0.rawValue):\(snapshot?.campStock.count(of: $0) ?? 0)"
            }.joined(separator: ",")
            let fixtureText = fixtures.fixtures.map {
                "\($0.fixtureId)@\(positionText($0.target)):\($0.harvested ? "harvested" : "available")"
            }.joined(separator: ",")
            let reservations = snapshot?.resourceReservations.map {
                "\($0.agentId):\($0.resource.rawValue)@\(positionText($0.target))"
            }.joined(separator: ",") ?? ""
            let conservation = snapshot?.conservation
            let message = "economy active=\(snapshot?.economyEnabled == true ? "yes" : "no") auto=\(economyAutoEnabled ? "on" : "off") quota=\(snapshot?.deliveryQuota ?? 0) actor=\(actor ?? "none") goal=\(agent?.currentGoal.kind.rawValue ?? "none") navigationDestination=\(agent?.navigationProgress.route?.purpose.rawValue ?? "none") inventory=\(inventory) inventoryTotal=\(agent?.resourceInventory.totalCount ?? 0)/\(agent?.resourceInventory.capacity ?? 0) campStock=\(stock) campStockTotal=\(snapshot?.campStock.totalCount ?? 0) fixtures=\(fixtureText) reservations=\(reservations.isEmpty ? "none" : reservations) deliveryOutcome=\(agent?.lastDeliveryOutcome?.status.rawValue ?? "none") memory=\(agent?.recentMemory.last?.type ?? "none") conservation=\(conservation?.harvestedTotal ?? 0):\(conservation?.carriedTotal ?? 0)+\(conservation?.campStockTotal ?? 0):\(conservation?.balanced == true ? "exact" : "diverged") corridorObserved=\(fixtures.corridorObservedBlockCount) corridorChangedSetup=\(fixtures.corridorChangedAfterSetup) corridorChangedNavigation=\(fixtures.corridorChangedDuringNavigation) corridorChangedHarvest=\(fixtures.corridorChangedAfterHarvest) corridorChangedCleanup=\(fixtures.corridorChangedAfterCleanup) fixtureSetupMutations=\(fixtures.setupMutatedBlockCount) cleanupRestoredBlocks=\(fixtures.cleanupRestoredBlockCount)"
            trace(message)
            return success(message)
        }

        guard featureEnabled else {
            return failure("PebbleAgents disabled. Set PEBBLELAB_APP_AGENTS=1 before launch.")
        }
        guard interactionFeatureEnabled else {
            return failure("PebbleAgents interaction disabled. Set PEBBLELAB_APP_AGENTS_INTERACT=1 before launch.")
        }
        guard var session, activeWorld === world, let anchor else {
            return failure("No active PebbleAgents session for this World.")
        }

        if subcommand == "auto" {
            guard arguments.count == 2,
                  arguments[1].lowercased() == "on" || arguments[1].lowercased() == "off" else {
                return failure(usage)
            }
            if arguments[1].lowercased() == "off" {
                session.setEconomyEnabled(false)
                self.session = session
                economyAutoEnabled = false
                lastEconomyReason = "disabled by command"
                trace("economy auto=off reason=command")
                return success("PebbleAgents economy automatic mode off.")
            }
            guard movementFeatureEnabled else {
                return failure("PebbleAgents movement disabled. Set PEBBLELAB_APP_AGENTS_MOVE=1 before launch.")
            }
            let fixtures = interactionExecutor.economyState().fixtures
            guard fixtures.count == PebbleAgentInteractionExecutor.maximumFixtureCount,
                  fixtures.contains(where: { !$0.harvested }),
                  let actorId = fixtures.first?.actorId,
                  focusedAgentId == actorId else {
                return failure("Economy auto requires three fixtures and focus on their actor.")
            }
            session.setEconomyEnabled(true)
            self.session = session
            economyAutoEnabled = true
            autoInteractionEnabled = false
            lastEconomyReason = "enabled by command"
            trace("economy auto=on actor=\(actorId) quota=\(session.configuration.deliveryQuota)")
            return success("PebbleAgents economy automatic mode on for \(actorId), quota \(session.configuration.deliveryQuota).")
        }

        if subcommand == "clear" {
            guard arguments.count == 1 else { return failure(usage) }
            guard interactionExecutor.cleanup(world: world) else {
                return failure("Economy cleanup failed; fixture ledger retained.")
            }
            session.setEconomyEnabled(false)
            self.session = session
            economyAutoEnabled = false
            lastEconomyReason = "fixtures cleared"
            let cleanup = interactionExecutor.economyState()
            trace("economy clear cleanupRestoredBlocks=\(cleanup.cleanupRestoredBlockCount) corridorChangedCleanup=\(cleanup.corridorChangedAfterCleanup)")
            return success("PebbleAgents economy fixtures restored and automatic mode off.")
        }

        guard subcommand == "setup", arguments.count == 1 else { return failure(usage) }
        guard isPaused else { return failure("Economy setup requires a paused PebbleAgents session.") }
        guard !movementEnabled else { return failure("Economy setup requires movement off.") }
        guard let actorId = focusedAgentId,
              let actor = session.snapshot().agents.first(where: { $0.id == actorId }) else {
            return failure("Economy setup requires a valid focused agent.")
        }
        let occupied = session.snapshot().agents.filter { $0.id != actorId }.map(\.position)
        let playerPosition = AgentPosition(
            x: Int(player.x.rounded(.down)),
            y: Int(player.y.rounded(.down)),
            z: Int(player.z.rounded(.down))
        )
        do {
            let fixtures = try interactionExecutor.setupEconomy(
                world: world,
                actor: actor,
                anchor: anchor,
                occupiedAgentPositions: occupied,
                playerPosition: playerPosition,
                routeToTarget: { target in
                    let observation = self.navigationAdapter.observe(
                        world: world,
                        agent: actor,
                        target: target,
                        occupiedAgentPositions: occupied
                    )
                    return AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
                        start: actor.position,
                        target: target,
                        cells: observation.cells,
                        radius: observation.radius,
                        maxVisitedNodes: AgentBoundedRoutePlanner.maximumVisitedNodes,
                        maxSteps: AgentBoundedRoutePlanner.maximumRouteSteps
                    ))
                }
            )
            let boundary = interactionExecutor.economyState()
            let summary = fixtures.map {
                "\($0.fixtureId)=\($0.resource.rawValue)@\(positionText($0.target))/\($0.resourceBlockName)"
            }.joined(separator: ",")
            trace("economy setup actor=\(actorId) fixtures=\(summary) corridorObserved=\(boundary.corridorObservedBlockCount) corridorChanged=\(boundary.corridorChangedAfterSetup) fixtureSetupMutations=\(boundary.setupMutatedBlockCount)")
            return success("Economy sandbox ready: \(summary).")
        } catch {
            let boundary = interactionExecutor.economyState()
            return failure("Economy setup failed: \(error); setupMutations=\(boundary.setupMutatedBlockCount) rollback=\(boundary.lastRollback)")
        }
    }

    private func handleInteraction(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab interaction <setup|setup distant <2...8>|harvest|status|auto on|auto off>"
        guard let subcommand = arguments.first?.lowercased() else { return failure(usage) }
        if subcommand == "status" {
            guard arguments.count == 1 else { return failure(usage) }
            let state = interactionExecutor.state(
                gateEnabled: interactionFeatureEnabled,
                autoEnabled: autoInteractionEnabled,
                autoReason: lastAutoInteractionReason
            )
            let target = state.target.map(positionText) ?? "none"
            let snapshot = session?.snapshot()
            let actor = state.actorId ?? focusedAgentId
            let inventory = snapshot?.agents.first { $0.id == actor }?.resourceInventory
            let actorSnapshot = snapshot?.agents.first { $0.id == actor }
            let outcome = actorSnapshot?.lastInteractionOutcome
            let interactionMemory = actorSnapshot?.recentMemory.last {
                $0.type == "resource_harvested"
                    || $0.type == "interaction_blocked"
                    || $0.type == "inventory_full"
            }?.type ?? "none"
            let activeTarget = actorSnapshot?.activeResourceTarget.map {
                "\(positionText($0.target))@selected\($0.selectedAtTick)/seen\($0.lastSeenAtTick)"
            } ?? "none"
            let navigation = actorSnapshot?.navigationProgress
            let reservationOwner = snapshot?.resourceReservations.first {
                $0.target == state.target
            }?.agentId ?? "none"
            let nextStep = navigation?.nextStep.map(positionText) ?? "none"
            let currentDistance = actorSnapshot.flatMap { agent in
                state.target.map { abs($0.x - agent.position.x) + abs($0.z - agent.position.z) }
            } ?? 0
            let message = "interaction gate=\(state.gateEnabled ? "enabled" : "disabled") sandbox=\(state.active ? "active" : "inactive") setupMode=\(state.setupMode) configuredDistance=\(state.configuredDistance ?? 0) target=\(target) actualDistance=\(currentDistance) actor=\(actor ?? "none") resourceBlock=\(state.resourceBlockName) originalBlock=\(state.originalBlock.map(String.init) ?? "none") harvested=\(state.harvested ? "yes" : "no") auto=\(state.autoEnabled ? "on" : "off") activeTarget=\(activeTarget) reservationOwner=\(reservationOwner) navigation=\(navigation?.status.rawValue ?? "idle") routeLength=\(navigation?.route?.positions.count ?? 0) routeIndex=\(navigation?.routeIndex ?? 0) stepsRemaining=\(navigation?.stepsRemaining ?? 0) nextStep=\(nextStep) replans=\(navigation?.replanCount ?? 0) invalidation=\(navigation?.lastInvalidation?.rawValue ?? "none") navigationFailure=\(navigation?.lastFailure?.rawValue ?? "none") movementOutcome=\(actorSnapshot?.lastMovementOutcome?.status.rawValue ?? "none") autoReason=\(state.autoReason.replacingOccurrences(of: " ", with: "_")) inventory=\(inventory?.totalCount ?? 0)/\(inventory?.capacity ?? 0) outcome=\(outcome?.status.rawValue ?? "none") memory=\(interactionMemory) reason=\(outcome?.reason ?? "none") rollback=\(state.rollbackCount):\(state.lastRollback) corridorObserved=\(state.corridorObservedBlockCount) corridorChangedSetup=\(state.corridorChangedAfterSetup) corridorChangedNavigation=\(state.corridorChangedDuringNavigation) corridorChangedHarvest=\(state.corridorChangedAfterHarvest) fixtureSetupMutations=\(state.setupMutatedBlockCount)"
            trace(message)
            return success(message)
        }

        if subcommand == "auto" {
            guard arguments.count == 2,
                  arguments[1].lowercased() == "on" || arguments[1].lowercased() == "off" else {
                return failure(usage)
            }
            if arguments[1].lowercased() == "off" {
                autoInteractionEnabled = false
                lastAutoInteractionReason = "disabled by command"
                trace("interaction auto=off reason=command")
                return success("PebbleAgents automatic interaction off.")
            }
            guard featureEnabled else {
                return failure("PebbleAgents disabled. Set PEBBLELAB_APP_AGENTS=1 before launch.")
            }
            guard interactionFeatureEnabled else {
                return failure("PebbleAgents interaction disabled. Set PEBBLELAB_APP_AGENTS_INTERACT=1 before launch.")
            }
            guard session != nil, activeWorld === world else {
                return failure("No active PebbleAgents session for this World.")
            }
            let state = interactionExecutor.state(gateEnabled: true)
            guard state.active, !state.harvested, let actorId = state.actorId else {
                return failure("Automatic interaction requires an active unharvested sandbox.")
            }
            guard focusedAgentId == actorId else {
                return failure("Automatic interaction requires focus on sandbox actor \(actorId).")
            }
            autoInteractionEnabled = true
            lastAutoInteractionReason = "enabled by command"
            trace("interaction auto=on actor=\(actorId) tick=\(session?.tick ?? 0)")
            return success("PebbleAgents automatic interaction on for \(actorId).")
        }

        let setupDistance: Int?
        if subcommand == "setup", arguments.count == 1 {
            setupDistance = 1
        } else if subcommand == "setup", arguments.count == 3,
                  arguments[1].lowercased() == "distant",
                  let distance = Int(arguments[2]), (2...8).contains(distance) {
            setupDistance = distance
        } else {
            setupDistance = nil
        }
        guard (subcommand == "setup" && setupDistance != nil)
                || (subcommand == "harvest" && arguments.count == 1) else {
            return failure(usage)
        }
        guard featureEnabled else {
            return failure("PebbleAgents disabled. Set PEBBLELAB_APP_AGENTS=1 before launch.")
        }
        guard interactionFeatureEnabled else {
            return failure("PebbleAgents interaction disabled. Set PEBBLELAB_APP_AGENTS_INTERACT=1 before launch.")
        }
        guard var session, activeWorld === world, let anchor else {
            return failure("No active PebbleAgents session for this World.")
        }
        guard isPaused else { return failure("Interaction requires a paused PebbleAgents session.") }
        guard !movementEnabled else { return failure("Interaction requires movement off.") }
        guard let actorId = focusedAgentId,
              let actor = session.snapshot().agents.first(where: { $0.id == actorId }) else {
            return failure("Interaction requires a valid focused agent.")
        }
        do {
            if subcommand == "setup" {
                let distance = setupDistance ?? 1
                let occupied = session.snapshot().agents.filter { $0.id != actorId }.map(\.position)
                let playerPosition = AgentPosition(
                    x: Int(player.x.rounded(.down)),
                    y: Int(player.y.rounded(.down)),
                    z: Int(player.z.rounded(.down))
                )
                let target = try interactionExecutor.setup(
                    world: world,
                    actor: actor,
                    anchor: anchor,
                    occupiedAgentPositions: occupied,
                    playerPosition: playerPosition,
                    distance: distance,
                    routeToTarget: { target in
                        let observation = self.navigationAdapter.observe(
                            world: world,
                            agent: actor,
                            target: target,
                            occupiedAgentPositions: occupied
                        )
                        return AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
                            start: actor.position,
                            target: target,
                            cells: observation.cells,
                            radius: observation.radius,
                            maxVisitedNodes: AgentBoundedRoutePlanner.maximumVisitedNodes,
                            maxSteps: AgentBoundedRoutePlanner.maximumRouteSteps
                        ))
                    }
                )
                let mode = distance == 1 ? "adjacent" : "distant"
                let boundary = interactionExecutor.state(gateEnabled: true)
                trace("interaction setup mode=\(mode) distance=\(distance) actor=\(actorId) target=\(positionText(target)) block=\(PebbleAgentInteractionExecutor.resourceBlockName) corridorObserved=\(boundary.corridorObservedBlockCount) corridorChanged=\(boundary.corridorChangedAfterSetup) fixtureSetupMutations=\(boundary.setupMutatedBlockCount)")
                return success("Interaction sandbox \(mode) distance \(distance) ready for \(actorId) at \(positionText(target)); block=\(PebbleAgentInteractionExecutor.resourceBlockName).")
            }
            let outcome = try performHarvestTransaction(
                world: world,
                player: player,
                actorId: actorId,
                expectedAction: nil,
                interactionPrefix: "g1",
                session: &session
            )
            self.session = session
            let after = session.snapshot().agents.first { $0.id == actorId }!
            trace("interaction harvest actor=\(actorId) target=\(positionText(outcome.target)) inventory=\(after.resourceInventory.totalCount)/\(after.resourceInventory.capacity) memory=resource_harvested outcome=succeeded")
            return success("\(actorId) harvested sandboxResource; inventory \(after.resourceInventory.totalCount)/\(after.resourceInventory.capacity).")
        } catch AgentSessionError.inventoryFull {
            guard let target = interactionExecutor.state(gateEnabled: true).target else {
                return failure("Inventory full.")
            }
            let outcome = AgentInteractionOutcome(
                interactionId: "g1-full:\(actorId):\(session.tick):\(positionText(target))",
                agentId: actorId,
                tick: session.tick,
                target: target,
                resource: .sandboxResource,
                status: .inventoryFull,
                inventoryDelta: AgentInventoryDelta(resource: .sandboxResource, quantity: 0),
                reason: "inventory capacity reached"
            )
            do {
                try session.applyInteractionOutcome(outcome)
                self.session = session
            } catch {
                return failure("Inventory full; failed to record outcome: \(error)")
            }
            return failure("Inventory full; World unchanged.")
        } catch {
            let boundary = interactionExecutor.state(gateEnabled: true)
            return failure("Interaction failed: \(error); setupMutations=\(boundary.setupMutatedBlockCount)")
        }
    }

    private func performHarvestTransaction(
        world: World,
        player: Player,
        actorId: String,
        expectedAction: AgentAction?,
        interactionPrefix: String,
        session: inout AgentSimulationSession
    ) throws -> AgentInteractionOutcome {
        let availableFixtures = interactionExecutor.economyState().fixtures.filter {
            $0.actorId == actorId && !$0.harvested
        }
        guard let anchor,
              let actor = session.snapshot().agents.first(where: { $0.id == actorId }),
              let target = expectedAction?.target ?? availableFixtures.first?.target,
              let fixture = availableFixtures.first(where: { $0.target == target }),
              let resource = expectedAction?.resource ?? Optional(fixture.resource) else {
            throw ControllerError.interactionBoundary("missing transaction boundary")
        }
        if let expectedAction {
            guard expectedAction.name == "harvest_block",
                  expectedAction.target == target,
                  expectedAction.resource == resource,
                  fixture.resource == resource else {
                throw ControllerError.interactionBoundary("harvest action target mismatch")
            }
        }
        let occupied = session.snapshot().agents.filter { $0.id != actorId }.map(\.position)
        let playerPosition = AgentPosition(
            x: Int(player.x.rounded(.down)),
            y: Int(player.y.rounded(.down)),
            z: Int(player.z.rounded(.down))
        )
        let interactionId = "\(interactionPrefix):\(actorId):\(session.tick):\(positionText(target))"
        let intent = AgentInteractionIntent(
            interactionId: interactionId,
            agentId: actorId,
            tick: session.tick,
            target: target,
            resource: resource
        )
        let before = actor
        let outcome = AgentInteractionOutcome(
            interactionId: interactionId,
            agentId: actorId,
            tick: session.tick,
            target: target,
            resource: resource,
            status: .succeeded,
            inventoryDelta: AgentInventoryDelta(resource: resource, quantity: 1),
            reason: "sandbox resource harvested"
        )
        try interactionExecutor.harvest(
            world: world,
            actor: actor,
            anchor: anchor,
            occupiedAgentPositions: occupied,
            playerPosition: playerPosition,
            expectedTarget: target,
            expectedResource: resource,
            prevalidate: { try session.prevalidateInteraction(intent) },
            applyAndVerify: {
                try session.applyInteractionOutcome(outcome)
                if environment["PEBBLELAB_APP_AGENTS_INTERACT_FAIL_AFTER_WORLD"] == "1" {
                    throw ControllerError.interactionBoundary("injected post-World failure")
                }
                let after = session.snapshot().agents.first { $0.id == actorId }!
                let expectedMemoryCount: Int
                switch session.configuration.memoryPolicy {
                case .legacyUnbounded:
                    expectedMemoryCount = before.memoryCount + 1
                case let .bounded(maxEntries):
                    expectedMemoryCount = min(maxEntries, before.memoryCount + 1)
                }
                guard after.resourceInventory.totalCount == before.resourceInventory.totalCount + 1,
                      after.resourceInventory.count(of: resource) == before.resourceInventory.count(of: resource) + 1,
                      after.lastInteractionOutcome == outcome,
                      after.memoryCount == expectedMemoryCount,
                      after.recentMemory.last?.type == "resource_harvested" else {
                    throw ControllerError.interactionBoundary(actorId)
                }
            }
        )
        return outcome
    }

    private func effectiveOverlayMode(f3Visible: Bool) -> PebbleAgentOverlayMode {
        overlayModeByCommand
            ?? (f3Visible ? .full : overlayEnabledByEnvironment ? .compact : .off)
    }

    private func followTargetId() -> String? {
        switch followMode {
        case .off: return nil
        case .focusedAgent: return focusedAgentId
        case let .fixedAgent(agentId): return agentId
        }
    }

    private func applyFollow(player: Player) {
        guard followMode != .off else { return }
        guard let agentId = followTargetId(), let probe = probesByAgentId[agentId] else {
            let prior = followMode.statusText
            followMode = .off
            trace("follow off reason=target unavailable target=\(prior)")
            return
        }
        _ = cameraFollow.orient(player: player, toward: probe)
    }

    private func resetRunCounters() {
        successfulCognitiveTicks = 0
        blockedMovementOutcomeCount = 0
        runtimeErrorCount = 0
        droppedCatchUpSteps = 0
        maxObservedMemoryCount = 0
        maxObservedDistanceFromHome = 0
    }

    @discardableResult
    private func stop(reason: String, fallbackWorld: World? = nil) -> Int {
        let snapshot = session?.snapshot()
        let followStatus = followMode.statusText
        let wasDemo = demoActive
        let cleanupWorld = activeWorld ?? fallbackWorld
        let interactionBeforeCleanup = interactionExecutor.state(gateEnabled: interactionFeatureEnabled)
        let interactionRestored = cleanupWorld.map { interactionExecutor.cleanup(world: $0) }
            ?? !interactionBeforeCleanup.active
        let interactionAfterCleanup = interactionExecutor.state(gateEnabled: interactionFeatureEnabled)
        if !interactionRestored {
            runtimeErrorCount += 1
            trace("error interaction cleanup failed reason=\(reason.replacingOccurrences(of: " ", with: "_"))")
        }
        let removed = cleanupWorld.map { clearLabCoreAgentProbes(in: $0) } ?? 0
        if let snapshot {
            let movementCount = snapshot.agents.reduce(0) { $0 + $1.movementCount }
            let retrieved = snapshot.agents.reduce(0) { $0 + $1.memoryRetrievalCount }
            let influenced = snapshot.agents.reduce(0) { $0 + $1.memoryInfluencedDecisionCount }
            let dedup = snapshot.agents.reduce(0) { $0 + $1.feedbackMemoryDeduplicatedCount }
            trace("summary reason=\(reason.replacingOccurrences(of: " ", with: "_")) seed=\(seed) ticks=\(successfulCognitiveTicks) hz=\(cognitiveHz) agents=\(snapshot.agentCount) movementCount=\(movementCount) blocked=\(blockedMovementOutcomeCount) memoryMax=\(maxObservedMemoryCount) retrieved=\(retrieved) influenced=\(influenced) dedup=\(dedup) maxDistanceHome=\(maxObservedDistanceFromHome) runtimeErrors=\(runtimeErrorCount) catchupDropped=\(droppedCatchUpSteps) probesRemoved=\(removed) follow=\(followStatus) demo=\(wasDemo ? 1 : 0) interactionRestored=\(interactionRestored ? 1 : 0) interactionTarget=\(interactionBeforeCleanup.target.map(positionText) ?? "none") conservation=\(snapshot.conservation.harvestedTotal):\(snapshot.conservation.carriedTotal)+\(snapshot.conservation.campStockTotal):\(snapshot.conservation.balanced ? "exact" : "diverged") corridorObserved=\(interactionAfterCleanup.corridorObservedBlockCount) corridorChangedCleanup=\(interactionAfterCleanup.corridorChangedAfterCleanup) cleanupRestoredBlocks=\(interactionAfterCleanup.cleanupRestoredBlockCount)")
        }
        interactionExecutor.clearBoundaryAudit()
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
        overlayModeByCommand = nil
        followMode = .off
        demoActive = false
        autoInteractionEnabled = false
        lastAutoInteractionReason = "none"
        lastInteractionAttempted = false
        lastInteractionSucceeded = false
        lastInteractionBlocked = false
        economyAutoEnabled = false
        lastEconomyReason = "none"
        lastDeliverySucceeded = false
        lastError = nil
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

    private func traceTick(_ message: String, tick: Int, important: Bool) {
        guard important || tick % traceEvery == 0 else { return }
        trace(message)
    }

    private enum ControllerError: Error {
        case missingSession
        case persistableProbe(String)
        case invalidProbeSet([String])
        case movementBoundary(String)
        case unsafeMovement(String)
        case feedbackBoundary(String)
        case interactionBoundary(String)
    }
}
