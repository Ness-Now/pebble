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
        let hungerCommitted = input.survivalEnabled
            && input.currentGoalKind == .satisfyHunger
            && input.needs.hunger > input.hungerRecoveryThreshold
        let restCommitted = input.survivalEnabled
            && input.currentGoalKind == .rest
            && input.needs.fatigue > input.fatigueRecoveryThreshold
        if input.survivalEnabled
            && (input.needs.hunger >= input.criticalHungerThreshold || hungerCommitted) {
            nextGoal = AgentGoal(
                kind: .satisfyHunger,
                reason: input.needs.hunger >= input.criticalHungerThreshold
                    ? "critical hunger requires food"
                    : "hunger recovery committed",
                startedAtTick: input.tick,
                urgency: 110
            )
        } else if input.health <= 25 {
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
        } else if input.survivalEnabled && input.needs.hunger >= input.hungryThreshold {
            nextGoal = AgentGoal(
                kind: .satisfyHunger,
                reason: "hunger threshold reached",
                startedAtTick: input.tick,
                urgency: 82
            )
        } else if input.survivalEnabled
                    && (input.needs.fatigue >= input.fatigueThreshold || restCommitted) {
            nextGoal = AgentGoal(
                kind: .rest,
                reason: restCommitted ? "fatigue recovery committed" : "fatigue threshold reached",
                startedAtTick: input.tick,
                urgency: 81
            )
        } else if input.shouldDeliverResources {
            nextGoal = AgentGoal(
                kind: .deliverResources,
                reason: "delivery quota reached or delivery committed",
                startedAtTick: input.tick,
                urgency: 80
            )
        } else if input.hasCommittedResourceTask && input.hasInventoryCapacity {
            nextGoal = AgentGoal(
                kind: .collectResource,
                reason: "reserved sandbox resource task active",
                startedAtTick: input.tick,
                urgency: 75
            )
        } else if !input.survivalEnabled && input.needs.fatigue >= 0.02 {
            nextGoal = AgentGoal(
                kind: .rest,
                reason: "fatigue >= 0.02",
                startedAtTick: input.tick,
                urgency: 70
            )
        } else if input.hasCollectibleAdjacentResource && input.hasInventoryCapacity {
            nextGoal = AgentGoal(
                kind: .collectResource,
                reason: "adjacent sandbox resource available",
                startedAtTick: input.tick,
                urgency: 65
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
            let recovery = input.survivalEnabled
                ? (input.distanceFromHome == 0 ? input.restRecoveryPerTick : 0)
                : 0.02
            needs.fatigue = max(0, needs.fatigue - recovery)
            fear = max(0, fear - 1)
            state = "resting"
            effect = input.survivalEnabled
                ? "fatigue -\(recovery), fear -1"
                : "fatigue -0.02, fear -1"
        case "observe_area":
            needs.curiosity = min(1, needs.curiosity + 0.01)
            state = "observing"
            effect = "curiosity +0.01"
        case "harvest_block":
            state = "interacting"
            effect = "awaiting interaction outcome"
        case "approach_resource":
            state = "planning"
            effect = "awaiting bounded navigation"
        case "return_home":
            state = "planning"
            effect = "awaiting bounded navigation home"
        case "deliver_resource":
            state = "delivering"
            effect = "awaiting delivery transaction"
        case "consume_food":
            state = "consuming"
            effect = "awaiting consumption transaction"
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
