import Foundation
import PebbleAgents

enum PebbleAgentOverlayMode: String {
    case off
    case compact
    case full
}

struct PebbleAgentDebugState {
    let globalLines: [String]
    let focusedAgentLines: [String]
    let statusSummary: String

    init(
        snapshot: AgentSessionSnapshot,
        mode: PebbleAgentOverlayMode,
        paused: Bool,
        cognitiveHz: Int,
        movementEnabled: Bool,
        followMode: PebbleAgentFollowMode,
        demoActive: Bool,
        focusedAgentId: String?,
        observedGoalKinds: [String],
        lastInfluencedDecisionTrace: AgentFeedbackDecisionTrace?,
        lastInfluencedDecisionAgentId: String?,
        runtimeErrorCount: Int,
        droppedCatchUpSteps: Int,
        lastError: String?,
        interaction: PebbleAgentInteractionState
    ) {
        let focus = snapshot.agents.first { $0.id == focusedAgentId } ?? snapshot.agents.first
        let status = paused ? "paused" : "running"
        statusSummary = "status=\(status) tick=\(snapshot.tick) hz=\(cognitiveHz) agents=\(snapshot.agentCount)"
        guard let agent = focus else {
            globalLines = ["PEBBLE AGENTS - 3D LIVE PROTOTYPE"]
            focusedAgentLines = ["No focused agent"]
            return
        }

        let currentFeedback = agent.lastFeedbackDecisionTrace.flatMap {
            $0.memoryRecordsUsed.isEmpty ? nil : $0
        } ?? lastInfluencedDecisionTrace
        if mode == .compact {
            let decisionAgent = lastInfluencedDecisionAgentId.flatMap { id in
                snapshot.agents.first { $0.id == id }
            } ?? agent
            globalLines = [
                "PEBBLE AGENTS - 3D LIVE PROTOTYPE",
                "status: \(status)  demo: \(demoActive ? "on" : "off")  tick: \(snapshot.tick)",
                "clock: \(cognitiveHz) Hz  paused: \(paused ? "yes" : "no")",
                "movement: \(movementEnabled ? "on" : "off")  follow: \(followMode.statusText)",
                "agents: \(snapshot.agentCount) focus: \(agent.id) goals: \(Self.short(observedGoalKinds.joined(separator: ","), limit: 22))",
            ]
            let base = currentFeedback?.baseDirection?.rawValue ?? currentFeedback?.baseAction.name ?? agent.lastAction?.name ?? "none"
            let final = currentFeedback?.finalDirection?.rawValue ?? currentFeedback?.finalAction.name ?? agent.lastAction?.name ?? "none"
            let movement = agent.lastMovementOutcome.map {
                "\($0.status.rawValue) \($0.requestedDirection?.rawValue ?? "none")"
            } ?? "none"
            let perception = agent.lastWorldObservation.map {
                "t/b/d \($0.traversableNeighborCount)/\($0.blockedNeighborCount)/\($0.dangerousDropCount)"
            } ?? "none"
            let memory = currentFeedback?.memoryRecordsUsed.first.map {
                "\($0.type)@\($0.tick) age \($0.ageTicks)"
            } ?? "none"
            let factor = currentFeedback?.dominantFactor.kind.rawValue ?? "basePolicy"
            let reason = currentFeedback?.reason ?? agent.lastAction?.reason ?? "none"
            let interactionTarget = interaction.target.map(Self.position) ?? "none"
            let resourceSeen = agent.lastResourceObservations.first.map {
                "\($0.resource.rawValue)@\(Self.position($0.target)) d=\($0.distanceManhattan)"
            } ?? "none"
            let activeTarget = agent.activeResourceTarget.map {
                "\(Self.position($0.target)) s\($0.selectedAtTick)/l\($0.lastSeenAtTick)"
            } ?? "none"
            let navigation = agent.navigationProgress
            let route = "\(navigation.status.rawValue) \(navigation.routeIndex)/\(max(0, (navigation.route?.positions.count ?? 1) - 1)) rem \(navigation.stepsRemaining)"
            let nextStep = navigation.nextStep.map(Self.position) ?? "none"
            let interactionOutcome = agent.lastInteractionOutcome
            let interactionMemory = agent.recentMemory.last { memory in
                memory.type == "resource_harvested" || memory.type == "interaction_blocked" || memory.type == "inventory_full"
            }?.type ?? "none"
            focusedAgentLines = [
                "FOCUS \(agent.id) pos \(Self.position(agent.position)) home d=\(agent.distanceFromHome)",
                "need: \(Self.dominantNeed(agent.needs))  goal: \(agent.currentGoal.kind.rawValue)",
                "action: \(base) > \(final)\(currentFeedback?.actionChanged == true ? " changed" : "")",
                "movement: \(movement)",
                "perception: \(perception)",
                "memory used\(lastInfluencedDecisionAgentId.map { " (\($0))" } ?? ""): \(memory)",
                "factor: \(factor)",
                "reason: \(Self.short(reason, limit: 38))",
                "memory/retrieved/influenced/dedup: \(decisionAgent.memoryCount)/\(decisionAgent.memoryRetrievalCount)/\(decisionAgent.memoryInfluencedDecisionCount)/\(decisionAgent.feedbackMemoryDeduplicatedCount)",
                "inventory: \(agent.resourceInventory.totalCount)/\(agent.resourceInventory.capacity) sandboxResource=\(agent.resourceInventory.count(of: .sandboxResource))",
                "resourceSeen: \(resourceSeen)",
                "activeTarget: \(activeTarget)",
                "reservation: \(agent.resourceReservation?.agentId ?? "none")  navigation: \(route)",
                "next/replans/failure: \(nextStep) / \(navigation.replanCount) / \(navigation.lastFailure?.rawValue ?? navigation.lastInvalidation?.rawValue ?? "none")",
                "interaction: \(interaction.active ? (interaction.harvested ? "harvested" : "ready") : "inactive") target \(interactionTarget) auto \(interaction.autoEnabled ? "on" : "off")",
                "outcome: \(interactionOutcome?.status.rawValue ?? "none") delta \(interactionOutcome?.inventoryDelta.quantity ?? 0) memory \(interactionMemory)",
                "rollback: \(interaction.rollbackCount) \(Self.short(interaction.lastRollback, limit: 30))",
                "errors: \(runtimeErrorCount)  catchup dropped: \(droppedCatchUpSteps)",
            ]
            return
        }

        globalLines = [
            "PEBBLE AGENTS - 3D LIVE PROTOTYPE",
            "mode: full  demo: \(demoActive ? "on" : "off")  follow: \(followMode.statusText)",
            movementEnabled ? "movement: enabled / safe cardinal steps" : "movement: disabled / intent only",
            "status: \(status)",
            "seed: \(snapshot.seed)  tick: \(snapshot.tick)  cognitive: \(cognitiveHz) Hz",
            "agents: \(snapshot.agentCount)  focus: \(agent.id)",
        ] + Self.goalLines(observedGoalKinds)
            + ["errors: \(runtimeErrorCount)  catchup dropped: \(droppedCatchUpSteps)"]
            + (lastError.map { ["last error: \(Self.short($0))"] } ?? [])

        let action = agent.lastAction
        let deltas = action.map {
            "(\($0.dx.map(String.init) ?? "nil"), \($0.dy.map(String.init) ?? "nil"), \($0.dz.map(String.init) ?? "nil"))"
        } ?? "n/a"
        let nearby = agent.nearbyAgents.map(\.id).joined(separator: ", ")
        let worldLines: [String]
        if let observation = agent.lastWorldObservation,
           let effect = agent.lastWorldPerceptionEffect {
            let weather = observation.thundering ? "thunder" : observation.raining ? "rain" : "clear"
            worldLines = [
                "world sensed from: \(Self.position(observation.position)) tick: \(observation.worldTick)",
                "biome: \(observation.biomeName ?? "unknown") time: \(observation.dayTime) \(weather)",
                "light c/s/b: \(observation.combinedLight.map(String.init) ?? "?")/\(observation.skyLight.map(String.init) ?? "?")/\(observation.blockLight.map(String.init) ?? "?") surfaceY: \(observation.center.surfaceY.map(String.init) ?? "?")",
                "center ready/ground: \(observation.center.chunkReady)/\(observation.center.groundPresent) feet/head: \(observation.center.feetClear)/\(observation.center.headClear)",
                "neighbors t/b/d: \(observation.traversableNeighborCount)/\(observation.blockedNeighborCount)/\(observation.dangerousDropCount)",
                "perception: \(Self.short(effect.reason))",
                String(format: "safety %.2f>%.2f fear %d>%d", effect.safetyBefore, effect.safetyAfter, effect.fearBefore, effect.fearAfter),
                String(format: "curiosity %.3f>%.3f observations: %d", effect.curiosityBefore, effect.curiosityAfter, agent.observationCount),
            ]
        } else {
            worldLines = ["world perception: none observations: \(agent.observationCount)"]
        }
        var feedbackLines = [
            "feedback write/dedup/retrieved/used: \(agent.feedbackMemoryWriteCount)/\(agent.feedbackMemoryDeduplicatedCount)/\(agent.memoryRetrievalCount)/\(agent.memoryInfluencedDecisionCount)",
        ]
        if let decision = currentFeedback, let memory = decision.memoryRecordsUsed.first {
            if let lastInfluencedDecisionAgentId {
                feedbackLines.append("decision agent: \(lastInfluencedDecisionAgentId)")
            }
            feedbackLines.append("memory used: \(memory.type)@\(memory.tick) age \(memory.ageTicks)")
            feedbackLines.append("memory summary: \(Self.short(memory.summary, limit: 26))")
            let base = decision.baseDirection?.rawValue ?? decision.baseAction.name
            let final = decision.finalDirection?.rawValue ?? decision.finalAction.name
            feedbackLines.append("decision: \(base) > \(final) changed")
            feedbackLines.append("dominant: \(decision.dominantFactor.kind.rawValue)")
            feedbackLines.append("feedback reason: \(Self.short(decision.reason, limit: 30))")
        } else {
            feedbackLines.append("memory used: none dominant: basePolicy")
            feedbackLines.append("decision: base action retained")
        }
        var movementLines: [String] = []
        if let movement = agent.lastMovementOutcome {
            movementLines.append("last move: \(movement.status.rawValue) request: \(movement.requestedDirection?.rawValue ?? "none")")
            movementLines.append("move from/to: \(Self.position(movement.fromPosition)) > \(Self.position(movement.toPosition))")
            movementLines.append("applied: \(movement.appliedDX),\(movement.appliedDY),\(movement.appliedDZ) \(Self.short(movement.resolutionReason, limit: 22))")
        } else {
            movementLines.append("last movement: none")
        }
        movementLines.append("move count/dist/home/reduced: \(agent.movementCount)/\(agent.totalManhattanDistanceMoved)/\(agent.returnHomeMoveCount)/\(agent.totalDistanceReducedTowardHome)")

        let fullResourceSeen = agent.lastResourceObservations.first.map {
            "\($0.resource.rawValue)@\(Self.position($0.target)) \($0.direction.rawValue) distance \($0.distanceManhattan)"
        } ?? "none"
        let fullActiveTarget = agent.activeResourceTarget.map {
            "\(Self.position($0.target)) selected \($0.selectedAtTick) seen \($0.lastSeenAtTick)"
        } ?? "none"
        let reservationExpiry = agent.resourceReservation.map { String($0.expiresAtTick) } ?? "none"
        let navigationNext = agent.navigationProgress.nextStep.map(Self.position) ?? "none"
        var lines = [
            "FOCUS - \(agent.id)",
            "current position: \(Self.position(agent.position)) state: \(agent.state)",
            "home position: \(Self.position(agent.homePosition)) distance: \(agent.distanceFromHome)",
        ] + feedbackLines + movementLines + worldLines + [
            String(format: "needs h %.3f f %.3f c %.3f s %.3f", agent.needs.hunger, agent.needs.fatigue, agent.needs.curiosity, agent.needs.safety),
            "dominant: \(Self.dominantNeed(agent.needs)) fear: \(agent.fear) health: \(agent.health)",
            "goal: \(agent.currentGoal.kind.rawValue) urgency: \(agent.currentGoal.urgency)",
            "goal reason: \(Self.short(agent.currentGoal.reason))",
            "action: \(action?.name ?? "none") deltas: \(deltas)",
            "action target/resource: \(action?.target.map(Self.position) ?? "none") / \(action?.resource?.rawValue ?? "none")",
            "reason/effect: \(Self.short(action?.reason ?? "none", limit: 18)) / \(Self.short(agent.lastActionEffect?.effect ?? "none", limit: 18))",
            "nearby: \(nearby.isEmpty ? "none" : nearby) memory: \(agent.memoryCount)",
            "inventory: \(agent.resourceInventory.totalCount)/\(agent.resourceInventory.capacity) sandboxResource: \(agent.resourceInventory.count(of: .sandboxResource))",
            "resource seen: \(fullResourceSeen)",
            "active resource target: \(fullActiveTarget)",
            "resource reservation owner: \(agent.resourceReservation?.agentId ?? "none") expires: \(reservationExpiry)",
            "navigation status/route/index: \(agent.navigationProgress.status.rawValue) / \(agent.navigationProgress.route?.positions.count ?? 0) / \(agent.navigationProgress.routeIndex)",
            "navigation remaining/next/replans: \(agent.navigationProgress.stepsRemaining) / \(navigationNext) / \(agent.navigationProgress.replanCount)",
            "navigation invalidation/failure: \(agent.navigationProgress.lastInvalidation?.rawValue ?? "none") / \(agent.navigationProgress.lastFailure?.rawValue ?? "none")",
            "interaction target/status: \(interaction.target.map(Self.position) ?? "none") / \(interaction.active ? (interaction.harvested ? "harvested" : "ready") : "inactive") auto: \(interaction.autoEnabled ? "on" : "off")",
            "interaction auto reason: \(Self.short(interaction.autoReason, limit: 28))",
            "interaction outcome: \(agent.lastInteractionOutcome?.status.rawValue ?? "none") reason: \(Self.short(agent.lastInteractionOutcome?.reason ?? "none", limit: 24))",
            "interaction delta/memory: \(agent.lastInteractionOutcome?.inventoryDelta.quantity ?? 0) / \(agent.recentMemory.last?.type ?? "none")",
            "interaction rollback: \(interaction.rollbackCount) \(Self.short(interaction.lastRollback, limit: 28))",
        ]
        lines.append("ticks: \(agent.ticksAlive) goals: \(agent.goalChangeCount) actions/effects: \(agent.actionCount)/\(agent.actionEffectCount)")
        focusedAgentLines = lines
    }

    private static func dominantNeed(_ needs: AgentNeedsSnapshot) -> String {
        let values = [
            ("hunger", needs.hunger),
            ("fatigue", needs.fatigue),
            ("curiosity", needs.curiosity),
            ("safety", 1 - needs.safety),
        ]
        return values.max { $0.1 < $1.1 }?.0 ?? "none"
    }

    private static func goalLines(_ goals: [String]) -> [String] {
        var lines: [String] = []
        var current = "goals:"
        for goal in goals {
            let candidate = current == "goals:" ? "\(current) \(goal)" : "\(current), \(goal)"
            if candidate.count > 34 {
                lines.append(current)
                current = "goals+: \(goal)"
            } else {
                current = candidate
            }
        }
        lines.append(current)
        return lines
    }

    private static func short(_ text: String, limit: Int = 32) -> String {
        guard text.count > limit else { return text }
        return String(text.prefix(limit - 1)) + "~"
    }

    private static func position(_ position: AgentPosition) -> String {
        "\(position.x),\(position.y),\(position.z)"
    }
}
