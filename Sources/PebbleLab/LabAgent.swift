import Foundation
import PebbleAgents
import PebbleCore

typealias LabAgentPosition = AgentPosition
typealias LabGoalKind = AgentGoalKind
typealias LabGoal = AgentGoal
typealias LabAgentAction = AgentAction
typealias LabAgentNeeds = AgentNeeds
typealias LabNearbyAgentObservation = AgentNearbyObservation
typealias LabGoalChange = AgentGoalChange
typealias LabAgentActionEffect = AgentActionEffect
typealias LabMemoryEntry = AgentMemoryEntry

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
        let result = AgentCognitiveTransitions.advanceTick(needs: needs)
        needs = result.needs
        state = result.state
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
        let peers = agents.map { other in
            AgentPeerSnapshot(id: other.id, position: other.position)
        }
        nearbyAgents = AgentCognitiveTransitions.observeNearbyAgents(
            observerId: id,
            observerPosition: position,
            peers: peers,
            radius: radius
        )
        nearbyObservationCount += nearbyAgents.count
    }

    mutating func selectGoal(tick: Int) -> LabGoalChange? {
        goalSelectionCount += 1
        guard let change = AgentCognitiveTransitions.selectGoal(AgentGoalSelectionInput(
            tick: tick,
            health: health,
            fear: fear,
            needs: needs,
            hasNearbyAgents: !nearbyAgents.isEmpty,
            currentGoalKind: currentGoal.kind
        )) else { return nil }
        currentGoal = change.goal
        goalChangeCount += 1
        return change
    }

    mutating func decideAction(tick: Int) {
        let action = AgentActionDecider.decide(AgentActionDecisionInput(
            agentId: id,
            tick: tick,
            goalKind: currentGoal.kind,
            position: position,
            homePosition: homePosition
        ))

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
        let result = AgentCognitiveTransitions.applyActionEffect(AgentActionEffectInput(
            action: action,
            goalKind: currentGoal.kind,
            distanceFromHome: distanceFromHome,
            needs: needs,
            fear: fear,
            state: state,
            tick: tick,
        ))
        needs = result.needs
        fear = result.fear
        state = result.state
        lastActionEffect = result.actionEffect
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

    mutating func remember(tick: Int, type: String, summary: String, importance: Double) {
        AgentCognitiveTransitions.appendLegacyUnboundedMemory(AgentMemoryEntry(
            tick: tick,
            type: type,
            summary: summary,
            importance: importance
        ), to: &memory)
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
