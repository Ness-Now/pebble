import Foundation
import PebbleCore

struct LabAgent: Encodable {
    let id: String
    let type: String
    var state: String
    var position: LabAgentPosition
    var needs: LabAgentNeeds
    var health: Int
    var fear: Int
    var homePosition: LabAgentPosition
    var observation: LabAgentObservation?
    var nearbyAgents: [LabNearbyAgentObservation]
    var currentGoal: LabGoal
    var lastAction: LabAgentAction?
    var lastActionEffect: LabAgentActionEffect?
    var memory: [LabMemoryEntry]
    let tickCreated: Int
    var ticksAlive: Int
    var observationCount: Int
    var nearbyObservationCount: Int
    var goalSelectionCount: Int
    var goalChangeCount: Int
    var actionCount: Int
    var actionEffectCount: Int

    var isAlive: Bool { health > 0 }

    init(id: String, x: Int, y: Int, z: Int) {
        self.id = id
        let spawnPosition = LabAgentPosition(x: x, y: y, z: z)
        type = "abstract_lab_agent"
        state = "idle"
        position = spawnPosition
        needs = LabAgentNeeds(hunger: 0, fatigue: 0, curiosity: 0.5, safety: 1)
        health = 100
        fear = 10
        homePosition = spawnPosition
        observation = nil
        nearbyAgents = []
        currentGoal = LabGoal(kind: .idle, reason: "initial goal", startedAtTick: 0, urgency: 0)
        lastAction = nil
        lastActionEffect = nil
        memory = []
        tickCreated = 0
        ticksAlive = 0
        observationCount = 0
        nearbyObservationCount = 0
        goalSelectionCount = 0
        goalChangeCount = 0
        actionCount = 0
        actionEffectCount = 0
    }

    mutating func tick() {
        needs.hunger += 0.01
        needs.fatigue += 0.005
        state = "idle"
        ticksAlive += 1
    }

    mutating func observe(world: World, tick: Int? = nil) {
        let x = position.x
        let y = position.y
        let z = position.z
        let chunkX = floorDiv(x, CHUNK_W)
        let chunkZ = floorDiv(z, CHUNK_W)
        observation = LabAgentObservation(
            x: x,
            y: y,
            z: z,
            chunkX: chunkX,
            chunkZ: chunkZ,
            chunkReady: world.isChunkReady(chunkX, chunkZ),
            surfaceY: world.surfaceY(x, z),
            height: world.heightAt(x, z),
            blockBelow: world.getBlock(x, y - 1, z),
            blockAtFeet: world.getBlock(x, y, z)
        )
        observationCount += 1
        if let tick {
            remember(
                tick: tick,
                type: "observed",
                summary: "\(id) observed chunk (\(chunkX),\(chunkZ)) at (\(x),\(y),\(z))",
                importance: 0.1
            )
        }
    }

    mutating func observeNearbyAgents(_ agents: [LabAgent], radius: Int = 8) {
        nearbyAgents = agents.compactMap { other in
            guard other.id != id else { return nil }

            let dx = other.position.x - position.x
            let dy = other.position.y - position.y
            let dz = other.position.z - position.z
            let distanceManhattan = abs(dx) + abs(dy) + abs(dz)
            guard distanceManhattan <= radius else { return nil }

            return LabNearbyAgentObservation(
                id: other.id,
                dx: dx,
                dy: dy,
                dz: dz,
                distanceManhattan: distanceManhattan
            )
        }
        nearbyObservationCount += nearbyAgents.count
    }

    mutating func selectGoal(tick: Int) -> LabGoalChange? {
        goalSelectionCount += 1

        let nextGoal: LabGoal
        if health <= 25 {
            nextGoal = LabGoal(kind: .seekSafety, reason: "health <= 25", startedAtTick: tick, urgency: 100)
        } else if fear >= 70 {
            nextGoal = LabGoal(kind: .seekSafety, reason: "fear >= 70", startedAtTick: tick, urgency: 85)
        } else if needs.safety < 0.5 {
            nextGoal = LabGoal(kind: .seekSafety, reason: "safety < 0.5", startedAtTick: tick, urgency: 90)
        } else if needs.fatigue >= 0.02 {
            nextGoal = LabGoal(kind: .rest, reason: "fatigue >= 0.02", startedAtTick: tick, urgency: 70)
        } else if !nearbyAgents.isEmpty {
            nextGoal = LabGoal(kind: .observeOtherAgent, reason: "nearby agent detected", startedAtTick: tick, urgency: 50)
        } else if needs.curiosity >= 0.5 {
            nextGoal = LabGoal(kind: .explore, reason: "curiosity >= 0.5", startedAtTick: tick, urgency: 40)
        } else {
            nextGoal = LabGoal(kind: .idle, reason: "no active need", startedAtTick: tick, urgency: 0)
        }

        guard nextGoal.kind != currentGoal.kind else { return nil }

        let change = LabGoalChange(from: currentGoal.kind, to: nextGoal.kind, goal: nextGoal)
        currentGoal = nextGoal
        goalChangeCount += 1
        return change
    }

    mutating func decideAction(tick: Int) {
        let action: LabAgentAction
        switch currentGoal.kind {
        case .seekSafety:
            action = LabAgentAction(name: "wait", reason: "goal seekSafety", tick: tick)
        case .rest:
            action = LabAgentAction(name: "rest", reason: "goal rest", tick: tick)
        case .observeOtherAgent:
            action = LabAgentAction(name: "observe_area", reason: "goal observeOtherAgent", tick: tick)
        case .explore:
            action = LabAgentAction(name: "observe_area", reason: "goal explore", tick: tick)
        case .idle:
            action = LabAgentAction(name: "wait", reason: "goal idle", tick: tick)
        }

        lastAction = action
        actionCount += 1
        remember(
            tick: tick,
            type: "action_chosen",
            summary: "\(id) chose \(action.name) because \(action.reason)",
            importance: 0.2
        )
    }

    mutating func applyLastActionEffect(tick: Int) {
        guard let action = lastAction else { return }

        let hungerBefore = needs.hunger
        let fatigueBefore = needs.fatigue
        let curiosityBefore = needs.curiosity
        let safetyBefore = needs.safety
        let fearBefore = fear
        let stateBefore = state
        let effect: String

        switch action.name {
        case "rest":
            needs.fatigue = max(0, needs.fatigue - 0.02)
            fear = max(0, fear - 1)
            state = "resting"
            effect = "fatigue -0.02, fear -1"
        case "observe_area":
            needs.curiosity = min(1, needs.curiosity + 0.01)
            state = "observing"
            effect = "curiosity +0.01"
        case "wait":
            if currentGoal.kind == .seekSafety {
                fear = max(0, fear - 1)
            }
            state = "waiting"
            effect = currentGoal.kind == .seekSafety ? "fear -1" : "no need change"
        default:
            effect = "no effect"
        }

        lastActionEffect = LabAgentActionEffect(
            action: action.name,
            effect: effect,
            tick: tick,
            hungerBefore: hungerBefore,
            hungerAfter: needs.hunger,
            fatigueBefore: fatigueBefore,
            fatigueAfter: needs.fatigue,
            curiosityBefore: curiosityBefore,
            curiosityAfter: needs.curiosity,
            safetyBefore: safetyBefore,
            safetyAfter: needs.safety,
            fearBefore: fearBefore,
            fearAfter: fear,
            stateBefore: stateBefore,
            stateAfter: state
        )
        actionEffectCount += 1
        remember(
            tick: tick,
            type: "action_effect_applied",
            summary: "\(id) applied \(action.name) effect",
            importance: 0.15
        )
    }

    mutating func remember(tick: Int, type: String, summary: String, importance: Double) {
        memory.append(LabMemoryEntry(
            tick: tick,
            type: type,
            summary: summary,
            importance: importance
        ))
    }

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case state
        case position
        case needs
        case health
        case isAlive
        case fear
        case homePosition
        case observation
        case nearbyAgents
        case currentGoal
        case lastAction
        case lastActionEffect
        case tickCreated
        case ticksAlive
        case actionCount
        case actionEffectCount
        case nearbyObservationCount
        case goalSelectionCount
        case goalChangeCount
        case memoryCount
        case recentMemory
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(state, forKey: .state)
        try container.encode(position, forKey: .position)
        try container.encode(needs, forKey: .needs)
        try container.encode(health, forKey: .health)
        try container.encode(isAlive, forKey: .isAlive)
        try container.encode(fear, forKey: .fear)
        try container.encode(homePosition, forKey: .homePosition)
        try container.encodeIfPresent(observation, forKey: .observation)
        try container.encode(nearbyAgents, forKey: .nearbyAgents)
        try container.encode(currentGoal, forKey: .currentGoal)
        try container.encodeIfPresent(lastAction, forKey: .lastAction)
        try container.encodeIfPresent(lastActionEffect, forKey: .lastActionEffect)
        try container.encode(tickCreated, forKey: .tickCreated)
        try container.encode(ticksAlive, forKey: .ticksAlive)
        try container.encode(actionCount, forKey: .actionCount)
        try container.encode(actionEffectCount, forKey: .actionEffectCount)
        try container.encode(nearbyObservationCount, forKey: .nearbyObservationCount)
        try container.encode(goalSelectionCount, forKey: .goalSelectionCount)
        try container.encode(goalChangeCount, forKey: .goalChangeCount)
        try container.encode(memory.count, forKey: .memoryCount)
        try container.encode(Array(memory.suffix(10)), forKey: .recentMemory)
    }
}

struct LabAgentPosition: Codable, Equatable {
    let x: Int
    let y: Int
    let z: Int
}

struct LabAgentNeeds: Encodable {
    var hunger: Double
    var fatigue: Double
    var curiosity: Double
    var safety: Double
}

struct LabAgentObservation: Encodable {
    let x: Int
    let y: Int
    let z: Int
    let chunkX: Int
    let chunkZ: Int
    let chunkReady: Bool
    let surfaceY: Int
    let height: Int
    let blockBelow: Int?
    let blockAtFeet: Int?
}

struct LabNearbyAgentObservation: Codable, Equatable {
    let id: String
    let dx: Int
    let dy: Int
    let dz: Int
    let distanceManhattan: Int
}

enum LabGoalKind: String, Codable, Equatable {
    case idle
    case rest
    case seekSafety
    case explore
    case observeOtherAgent
}

struct LabGoal: Codable, Equatable {
    let kind: LabGoalKind
    let reason: String
    let startedAtTick: Int
    let urgency: Int
}

struct LabGoalChange {
    let from: LabGoalKind
    let to: LabGoalKind
    let goal: LabGoal
}

struct LabAgentAction: Encodable {
    let name: String
    let reason: String
    let tick: Int
}

struct LabAgentActionEffect: Encodable {
    let action: String
    let effect: String
    let tick: Int
    let hungerBefore: Double
    let hungerAfter: Double
    let fatigueBefore: Double
    let fatigueAfter: Double
    let curiosityBefore: Double
    let curiosityAfter: Double
    let safetyBefore: Double
    let safetyAfter: Double
    let fearBefore: Int
    let fearAfter: Int
    let stateBefore: String
    let stateAfter: String
}

struct LabMemoryEntry: Encodable {
    let tick: Int
    let type: String
    let summary: String
    let importance: Double
}
