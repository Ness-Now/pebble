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
        focusedAgentId: String?,
        observedGoalKinds: [String],
        lastError: String?
    ) {
        let focus = snapshot.agents.first { $0.id == focusedAgentId } ?? snapshot.agents.first
        let status = paused ? "paused" : "running"
        statusSummary = "status=\(status) tick=\(snapshot.tick) hz=\(cognitiveHz) agents=\(snapshot.agentCount)"
        globalLines = [
            "PEBBLE AGENTS - LIVE OBSERVER",
            "movement: disabled / intent only",
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
                "world tick: \(observation.worldTick)  biome: \(observation.biomeName ?? "unknown")",
                "light c/s/b: \(observation.combinedLight.map(String.init) ?? "?")/\(observation.skyLight.map(String.init) ?? "?")/\(observation.blockLight.map(String.init) ?? "?")  time: \(observation.dayTime) \(weather)",
                "center ready: \(observation.center.chunkReady)  surfaceY: \(observation.center.surfaceY.map(String.init) ?? "?")",
                "ground: \(observation.center.groundPresent)  feet/head clear: \(observation.center.feetClear)/\(observation.center.headClear)",
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
            "position: \(agent.position.x), \(agent.position.y), \(agent.position.z)  state: \(agent.state)",
        ] + worldLines + [
            String(format: "needs h %.3f  f %.3f  c %.3f  s %.3f", agent.needs.hunger, agent.needs.fatigue, agent.needs.curiosity, agent.needs.safety),
            "dominant: \(Self.dominantNeed(agent.needs))  fear: \(agent.fear)  health: \(agent.health)",
            "goal: \(agent.currentGoal.kind.rawValue)  urgency: \(agent.currentGoal.urgency)",
            "goal reason: \(Self.short(agent.currentGoal.reason))",
            "action: \(action?.name ?? "none")  deltas: \(deltas)",
            "action reason: \(Self.short(action?.reason ?? "none"))",
            "action effect: \(Self.short(agent.lastActionEffect?.effect ?? "none"))",
            "nearby: \(nearby.isEmpty ? "none" : nearby)  memory: \(agent.memoryCount)",
        ]
        for memory in agent.recentMemory.suffix(3) {
            lines.append("memory[\(memory.tick)]: \(Self.short(memory.summary, limit: 24))")
        }
        lines.append("ticks: \(agent.ticksAlive)  goals: \(agent.goalChangeCount)  actions: \(agent.actionCount)  effects: \(agent.actionEffectCount)")
        lines.append("movementCount: \(agent.movementCount)  distanceHome: \(agent.distanceFromHome)")
        if action?.name == "move_abstract" {
            lines.append("move_abstract intent / fixed position")
        }
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
}
