public enum AgentCognitiveTransitions {
    public static func advanceTick(needs: AgentNeeds) -> AgentTickTransitionResult {
        var nextNeeds = needs
        nextNeeds.hunger += 0.01
        nextNeeds.fatigue += 0.005
        return AgentTickTransitionResult(needs: nextNeeds, state: "idle")
    }

    public static func observeNearbyAgents(
        observerId: String,
        observerPosition: AgentPosition,
        peers: [AgentPeerSnapshot],
        radius: Int = 8
    ) -> [AgentNearbyObservation] {
        peers.compactMap { peer in
            guard peer.id != observerId else { return nil }

            let dx = peer.position.x - observerPosition.x
            let dy = peer.position.y - observerPosition.y
            let dz = peer.position.z - observerPosition.z
            let distanceManhattan = abs(dx) + abs(dy) + abs(dz)
            guard distanceManhattan <= radius else { return nil }

            return AgentNearbyObservation(
                id: peer.id,
                dx: dx,
                dy: dy,
                dz: dz,
                distanceManhattan: distanceManhattan
            )
        }
    }

    public static func selectGoal(_ input: AgentGoalSelectionInput) -> AgentGoalChange? {
        let nextGoal: AgentGoal
        if input.health <= 25 {
            nextGoal = AgentGoal(
                kind: .seekSafety,
                reason: "health <= 25",
                startedAtTick: input.tick,
                urgency: 100
            )
        } else if input.fear >= 70 {
            nextGoal = AgentGoal(
                kind: .seekSafety,
                reason: "fear >= 70",
                startedAtTick: input.tick,
                urgency: 85
            )
        } else if input.needs.safety < 0.5 {
            nextGoal = AgentGoal(
                kind: .seekSafety,
                reason: "safety < 0.5",
                startedAtTick: input.tick,
                urgency: 90
            )
        } else if input.needs.fatigue >= 0.02 {
            nextGoal = AgentGoal(
                kind: .rest,
                reason: "fatigue >= 0.02",
                startedAtTick: input.tick,
                urgency: 70
            )
        } else if input.needs.curiosity >= 0.8 {
            nextGoal = AgentGoal(
                kind: .explore,
                reason: "curiosity >= 0.8",
                startedAtTick: input.tick,
                urgency: 60
            )
        } else if input.hasNearbyAgents {
            nextGoal = AgentGoal(
                kind: .observeOtherAgent,
                reason: "nearby agent detected",
                startedAtTick: input.tick,
                urgency: 50
            )
        } else if input.needs.curiosity >= 0.5 {
            nextGoal = AgentGoal(
                kind: .explore,
                reason: "curiosity >= 0.5",
                startedAtTick: input.tick,
                urgency: 40
            )
        } else {
            nextGoal = AgentGoal(
                kind: .idle,
                reason: "no active need",
                startedAtTick: input.tick,
                urgency: 0
            )
        }

        guard nextGoal.kind != input.currentGoalKind else { return nil }
        return AgentGoalChange(from: input.currentGoalKind, to: nextGoal.kind, goal: nextGoal)
    }

    public static func applyActionEffect(
        _ input: AgentActionEffectInput
    ) -> AgentActionEffectResult {
        let needsBefore = input.needs
        let fearBefore = input.fear
        let stateBefore = input.state
        var needs = needsBefore
        var fear = fearBefore
        var state = stateBefore
        let effect: String

        switch input.action.name {
        case "rest":
            needs.fatigue = max(0, needs.fatigue - 0.02)
            fear = max(0, fear - 1)
            state = "resting"
            effect = "fatigue -0.02, fear -1"
        case "observe_area":
            needs.curiosity = min(1, needs.curiosity + 0.01)
            state = "observing"
            effect = "curiosity +0.01"
        case "move_abstract":
            if input.goalKind == .seekSafety {
                fear = max(0, fear - 1)
                effect = "fear -1"
            } else {
                needs.curiosity = max(0, needs.curiosity - 0.005)
                effect = "curiosity -0.005"
            }
            state = "moving"
        case "wait":
            if input.goalKind == .seekSafety {
                let reduction = input.distanceFromHome <= 1 ? 2 : 1
                fear = max(0, fear - reduction)
            }
            state = "waiting"
            effect = input.goalKind == .seekSafety
                ? (input.distanceFromHome <= 1 ? "fear -2" : "fear -1")
                : "no need change"
        default:
            effect = "no effect"
        }

        let actionEffect = AgentActionEffect(
            action: input.action.name,
            effect: effect,
            tick: input.tick,
            hungerBefore: needsBefore.hunger,
            hungerAfter: needs.hunger,
            fatigueBefore: needsBefore.fatigue,
            fatigueAfter: needs.fatigue,
            curiosityBefore: needsBefore.curiosity,
            curiosityAfter: needs.curiosity,
            safetyBefore: needsBefore.safety,
            safetyAfter: needs.safety,
            fearBefore: fearBefore,
            fearAfter: fear,
            stateBefore: stateBefore,
            stateAfter: state
        )
        return AgentActionEffectResult(
            needs: needs,
            fear: fear,
            state: state,
            actionEffect: actionEffect
        )
    }

    public static func appendLegacyUnboundedMemory(
        _ entry: AgentMemoryEntry,
        to memory: inout [AgentMemoryEntry]
    ) {
        memory.append(entry)
    }
}
