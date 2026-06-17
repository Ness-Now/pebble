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
    var inventory: LabInventory
    var observation: LabAgentObservation?
    var nearbyAgents: [LabNearbyAgentObservation]
    var currentGoal: LabGoal
    var lastAction: LabAgentAction?
    var lastActionEffect: LabAgentActionEffect?
    var lastMovement: LabAgentMovement?
    var memory: [LabMemoryEntry]
    let tickCreated: Int
    var ticksAlive: Int
    var observationCount: Int
    var nearbyObservationCount: Int
    var goalSelectionCount: Int
    var goalChangeCount: Int
    var actionCount: Int
    var actionEffectCount: Int
    var movementCount: Int
    var totalManhattanDistanceMoved: Int
    var returnHomeMoveCount: Int
    var totalDistanceReducedTowardHome: Int

    var isAlive: Bool { health > 0 }
    var distanceFromHome: Int {
        abs(position.x - homePosition.x) + abs(position.y - homePosition.y) + abs(position.z - homePosition.z)
    }

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
        inventory = LabInventory()
        observation = nil
        nearbyAgents = []
        currentGoal = LabGoal(kind: .idle, reason: "initial goal", startedAtTick: 0, urgency: 0)
        lastAction = nil
        lastActionEffect = nil
        lastMovement = nil
        memory = []
        tickCreated = 0
        ticksAlive = 0
        observationCount = 0
        nearbyObservationCount = 0
        goalSelectionCount = 0
        goalChangeCount = 0
        actionCount = 0
        actionEffectCount = 0
        movementCount = 0
        totalManhattanDistanceMoved = 0
        returnHomeMoveCount = 0
        totalDistanceReducedTowardHome = 0
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
        } else if needs.curiosity >= 0.8 {
            nextGoal = LabGoal(kind: .explore, reason: "curiosity >= 0.8", startedAtTick: tick, urgency: 60)
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
            if let step = movementStepTowardHome() {
                action = LabAgentAction(
                    name: "move_abstract",
                    reason: "goal seekSafety",
                    tick: tick,
                    dx: step.dx,
                    dy: 0,
                    dz: step.dz
                )
            } else {
                action = LabAgentAction(name: "wait", reason: "goal seekSafety at home", tick: tick)
            }
        case .rest:
            action = LabAgentAction(name: "rest", reason: "goal rest", tick: tick)
        case .observeOtherAgent:
            action = LabAgentAction(name: "observe_area", reason: "goal observeOtherAgent", tick: tick)
        case .explore:
            let direction = movementDirectionForAgent(id: id, tick: tick)
            action = LabAgentAction(
                name: "move_abstract",
                reason: "goal explore",
                tick: tick,
                dx: direction.dx,
                dy: 0,
                dz: direction.dz
            )
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
        case "move_abstract":
            if currentGoal.kind == .seekSafety {
                fear = max(0, fear - 1)
                effect = "fear -1"
            } else {
                needs.curiosity = max(0, needs.curiosity - 0.005)
                effect = "curiosity -0.005"
            }
            state = "moving"
        case "wait":
            if currentGoal.kind == .seekSafety {
                let reduction = distanceFromHome <= 1 ? 2 : 1
                fear = max(0, fear - reduction)
            }
            state = "waiting"
            effect = currentGoal.kind == .seekSafety
                ? (distanceFromHome <= 1 ? "fear -2" : "fear -1")
                : "no need change"
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

    mutating func applyAbstractMovement(tick: Int) -> LabAgentMovement? {
        guard let action = lastAction, action.name == "move_abstract" else {
            lastMovement = nil
            return nil
        }

        let dx = action.dx ?? 0
        let dy = action.dy ?? 0
        let dz = action.dz ?? 0
        let distance = abs(dx) + abs(dy) + abs(dz)
        guard distance > 0 else {
            lastMovement = nil
            return nil
        }

        let from = position
        let distanceFromHomeBefore = distanceFromHome
        let to = LabAgentPosition(x: from.x + dx, y: from.y, z: from.z + dz)
        position = to
        let distanceFromHomeAfter = distanceFromHome
        let distanceReducedTowardHome = max(0, distanceFromHomeBefore - distanceFromHomeAfter)

        let movement = LabAgentMovement(
            tick: tick,
            fromX: from.x,
            fromY: from.y,
            fromZ: from.z,
            toX: to.x,
            toY: to.y,
            toZ: to.z,
            dx: dx,
            dy: 0,
            dz: dz,
            distanceManhattan: distance,
            reason: action.reason,
            goal: currentGoal.kind.rawValue,
            homeX: homePosition.x,
            homeY: homePosition.y,
            homeZ: homePosition.z,
            distanceFromHomeBefore: distanceFromHomeBefore,
            distanceFromHomeAfter: distanceFromHomeAfter,
            distanceReducedTowardHome: distanceReducedTowardHome
        )
        lastMovement = movement
        movementCount += 1
        totalManhattanDistanceMoved += distance
        if currentGoal.kind == .seekSafety, distanceReducedTowardHome > 0 {
            returnHomeMoveCount += 1
            totalDistanceReducedTowardHome += distanceReducedTowardHome
        }
        remember(
            tick: tick,
            type: "moved_abstract",
            summary: "\(id) moved abstractly by (\(dx),0,\(dz)) because \(action.reason)",
            importance: 0.1
        )
        return movement
    }

    func movementStepTowardHome() -> (dx: Int, dz: Int)? {
        let dxToHome = homePosition.x - position.x
        let dzToHome = homePosition.z - position.z

        if dxToHome == 0 && dzToHome == 0 {
            return nil
        }

        if abs(dxToHome) >= abs(dzToHome), dxToHome != 0 {
            return (dxToHome > 0 ? 1 : -1, 0)
        }

        if dzToHome != 0 {
            return (0, dzToHome > 0 ? 1 : -1)
        }

        return nil
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
        case inventory
        case observation
        case nearbyAgents
        case currentGoal
        case lastAction
        case lastActionEffect
        case lastMovement
        case tickCreated
        case ticksAlive
        case actionCount
        case actionEffectCount
        case movementCount
        case totalManhattanDistanceMoved
        case returnHomeMoveCount
        case totalDistanceReducedTowardHome
        case distanceFromHome
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
        try container.encode(inventory, forKey: .inventory)
        try container.encodeIfPresent(observation, forKey: .observation)
        try container.encode(nearbyAgents, forKey: .nearbyAgents)
        try container.encode(currentGoal, forKey: .currentGoal)
        try container.encodeIfPresent(lastAction, forKey: .lastAction)
        try container.encodeIfPresent(lastActionEffect, forKey: .lastActionEffect)
        try container.encodeIfPresent(lastMovement, forKey: .lastMovement)
        try container.encode(tickCreated, forKey: .tickCreated)
        try container.encode(ticksAlive, forKey: .ticksAlive)
        try container.encode(actionCount, forKey: .actionCount)
        try container.encode(actionEffectCount, forKey: .actionEffectCount)
        try container.encode(movementCount, forKey: .movementCount)
        try container.encode(totalManhattanDistanceMoved, forKey: .totalManhattanDistanceMoved)
        try container.encode(returnHomeMoveCount, forKey: .returnHomeMoveCount)
        try container.encode(totalDistanceReducedTowardHome, forKey: .totalDistanceReducedTowardHome)
        try container.encode(distanceFromHome, forKey: .distanceFromHome)
        try container.encode(nearbyObservationCount, forKey: .nearbyObservationCount)
        try container.encode(goalSelectionCount, forKey: .goalSelectionCount)
        try container.encode(goalChangeCount, forKey: .goalChangeCount)
        try container.encode(memory.count, forKey: .memoryCount)
        try container.encode(Array(memory.suffix(10)), forKey: .recentMemory)
    }
}

func movementDirectionForAgent(id: String, tick: Int) -> (dx: Int, dz: Int) {
    let suffix = id.split(separator: "_").last.flatMap { Int($0) } ?? 0
    switch (suffix + tick) % 4 {
    case 0:
        return (1, 0)
    case 1:
        return (0, 1)
    case 2:
        return (-1, 0)
    default:
        return (0, -1)
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

struct LabInventory: Codable, Equatable {
    private(set) var items: [String: Int]

    var isEmpty: Bool { items.isEmpty }
    var totalItemCount: Int { items.values.reduce(0, +) }

    init(items: [String: Int] = [:]) {
        self.items = items.filter { _, count in count > 0 }
    }

    func count(_ item: String) -> Int {
        items[item, default: 0]
    }

    func has(_ item: String, count: Int = 1) -> Bool {
        guard count > 0 else { return false }
        return self.count(item) >= count
    }

    mutating func add(_ item: String, count: Int = 1) {
        guard count > 0 else { return }
        items[item, default: 0] += count
    }

    mutating func remove(_ item: String, count: Int = 1) -> Bool {
        guard count > 0, has(item, count: count) else { return false }
        let remaining = self.count(item) - count
        if remaining > 0 {
            items[item] = remaining
        } else {
            items.removeValue(forKey: item)
        }
        return true
    }

    enum CodingKeys: String, CodingKey {
        case items
        case totalItemCount
        case isEmpty
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedItems = try container.decode([String: Int].self, forKey: .items)
        self.init(items: decodedItems)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(items, forKey: .items)
        try container.encode(totalItemCount, forKey: .totalItemCount)
        try container.encode(isEmpty, forKey: .isEmpty)
    }
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
    let dx: Int?
    let dy: Int?
    let dz: Int?

    init(name: String, reason: String, tick: Int, dx: Int? = nil, dy: Int? = nil, dz: Int? = nil) {
        self.name = name
        self.reason = reason
        self.tick = tick
        self.dx = dx
        self.dy = dy
        self.dz = dz
    }
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

struct LabAgentMovement: Encodable {
    let tick: Int
    let fromX: Int
    let fromY: Int
    let fromZ: Int
    let toX: Int
    let toY: Int
    let toZ: Int
    let dx: Int
    let dy: Int
    let dz: Int
    let distanceManhattan: Int
    let reason: String
    let goal: String
    let homeX: Int
    let homeY: Int
    let homeZ: Int
    let distanceFromHomeBefore: Int
    let distanceFromHomeAfter: Int
    let distanceReducedTowardHome: Int
}

struct LabMemoryEntry: Encodable {
    let tick: Int
    let type: String
    let summary: String
    let importance: Double
}
