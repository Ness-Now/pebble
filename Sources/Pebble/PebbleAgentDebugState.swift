import Foundation
import PebbleAgents

struct PebbleAgentDebugState {
    let globalLines: [String]
    let focusedAgentLines: [String]
    let statusSummary: String

    init(
        snapshot: AgentSessionSnapshot,
        paused: Bool,
        cognitiveHz: Int,
        movementEnabled: Bool,
        focusedAgentId: String?,
        observedGoalKinds: [String],
        lastError: String?
    ) {
        let focus = snapshot.agents.first { $0.id == focusedAgentId } ?? snapshot.agents.first
        let status = paused ? "paused" : "running"
        statusSummary = "status=\(status) tick=\(snapshot.tick) hz=\(cognitiveHz) agents=\(snapshot.agentCount)"
        globalLines = [
            "PEBBLE AGENTS - LIVE OBSERVER",
            movementEnabled ? "movement: enabled / safe cardinal steps" : "movement: disabled / intent only",
            "status: \(status)",
            "seed: \(snapshot.seed)  tick: \(snapshot.tick)  cognitive: \(cognitiveHz) Hz",
            "agents: \(snapshot.agentCount)  focus: \(focus?.id ?? "none")",
        ] + Self.goalLines(observedGoalKinds)
            + (lastError.map { ["last error: \(Self.short($0))"] } ?? [])

        guard let agent = focus else {
            focusedAgentLines = ["No focused agent"]
            return
        }
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
                "world sensed from: \(observation.position.x),\(observation.position.y),\(observation.position.z)  tick: \(observation.worldTick)",
                "biome: \(observation.biomeName ?? "unknown")  time: \(observation.dayTime) \(weather)",
                "light c/s/b: \(observation.combinedLight.map(String.init) ?? "?")/\(observation.skyLight.map(String.init) ?? "?")/\(observation.blockLight.map(String.init) ?? "?")  surfaceY: \(observation.center.surfaceY.map(String.init) ?? "?")",
                "center ready/ground: \(observation.center.chunkReady)/\(observation.center.groundPresent)  feet/head: \(observation.center.feetClear)/\(observation.center.headClear)",
                "neighbors t/b/d: \(observation.traversableNeighborCount)/\(observation.blockedNeighborCount)/\(observation.dangerousDropCount)",
                "perception: \(Self.short(effect.reason))",
                String(format: "safety %.2f>%.2f fear %d>%d", effect.safetyBefore, effect.safetyAfter, effect.fearBefore, effect.fearAfter),
                String(format: "curiosity %.3f>%.3f observations: %d", effect.curiosityBefore, effect.curiosityAfter, agent.observationCount),
            ]
        } else {
            worldLines = ["world perception: none  observations: \(agent.observationCount)"]
        }
        var lines = [
            "FOCUS - \(agent.id)",
            "current position: \(agent.position.x),\(agent.position.y),\(agent.position.z)  state: \(agent.state)",
            "home position: \(agent.homePosition.x),\(agent.homePosition.y),\(agent.homePosition.z)  distance: \(agent.distanceFromHome)",
        ] + worldLines + [
            String(format: "needs h %.3f  f %.3f  c %.3f  s %.3f", agent.needs.hunger, agent.needs.fatigue, agent.needs.curiosity, agent.needs.safety),
            "dominant: \(Self.dominantNeed(agent.needs))  fear: \(agent.fear)  health: \(agent.health)",
            "goal: \(agent.currentGoal.kind.rawValue)  urgency: \(agent.currentGoal.urgency)",
            "goal reason: \(Self.short(agent.currentGoal.reason))",
            "action: \(action?.name ?? "none")  deltas: \(deltas)",
            "reason/effect: \(Self.short(action?.reason ?? "none", limit: 18)) / \(Self.short(agent.lastActionEffect?.effect ?? "none", limit: 18))",
            "nearby: \(nearby.isEmpty ? "none" : nearby)  memory: \(agent.memoryCount)",
        ]
        if let movement = agent.lastMovementOutcome {
            lines.append("last move: \(movement.status.rawValue)  request: \(movement.requestedDirection?.rawValue ?? "none")")
            lines.append("move from/to: \(Self.position(movement.fromPosition)) > \(Self.position(movement.toPosition))")
            lines.append("applied: \(movement.appliedDX),\(movement.appliedDY),\(movement.appliedDZ)  \(Self.short(movement.resolutionReason, limit: 22))")
        } else {
            lines.append("last movement: none")
        }
        lines.append("move count/dist/home/reduced: \(agent.movementCount)/\(agent.totalManhattanDistanceMoved)/\(agent.returnHomeMoveCount)/\(agent.totalDistanceReducedTowardHome)")
        for memory in agent.recentMemory.suffix(2) {
            lines.append("memory[\(memory.tick)]: \(Self.short(memory.summary, limit: 24))")
        }
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
