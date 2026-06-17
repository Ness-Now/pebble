import Foundation
import PebbleCore

struct LabPhysicalAgentHandle: Codable, Equatable {
    let agentId: String
    let physicalId: String
    var position: LabAgentPosition
    let kind: String
    let spawnedAtTick: Int
    var ticksAlive: Int

    mutating func tick() {
        ticksAlive += 1
    }
}

struct LabPhysicalAgentSync: Codable, Equatable {
    let agentId: String
    let physicalId: String
    let fromPosition: LabAgentPosition
    let toPosition: LabAgentPosition
    let abstractPosition: LabAgentPosition
    let distanceManhattan: Int
    let tick: Int
}

struct LabPhysicalAgentLink: Encodable {
    let agentId: String
    let physicalId: String
    let kind: String
    let abstractPosition: LabAgentPosition
    let physicalPosition: LabAgentPosition
    let divergence: Int
    let spawnedAtTick: Int
    let ticksAlive: Int
}

struct PhysicalSnapshot: Encodable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let physicalAgents: [LabPhysicalAgentLink]
}

struct LabCoreAgentSync: Codable, Equatable {
    let agentId: String
    let physicalId: String
    let coreEntityId: Int
    let fromPosition: LabAgentPosition
    let toPosition: LabAgentPosition
    let abstractPosition: LabAgentPosition
    let distanceManhattan: Int
    let tick: Int
}

struct LabCoreAgentLink: Encodable {
    let agentId: String
    let physicalId: String
    let coreEntityId: Int
    let kind: String
    let abstractPosition: LabAgentPosition
    let coreEntityPosition: LabAgentPosition
    let divergence: Int
    let ticksAlive: Int
}

struct CoreEntitySnapshot: Encodable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let coreEntities: [LabCoreAgentLink]
}

struct LabAgentPhysicalBridge {
    private(set) var handles: [LabPhysicalAgentHandle] = []

    var count: Int { handles.count }
    var linkCount: Int { handles.count }
    var tickCount: Int { handles.reduce(0) { $0 + $1.ticksAlive } }

    mutating func spawnPlaceholder(for agent: LabAgent, tick: Int) -> LabPhysicalAgentHandle {
        let handle = LabPhysicalAgentHandle(
            agentId: agent.id,
            physicalId: "physical_\(agent.id)",
            position: agent.position,
            kind: "lab_physical_placeholder",
            spawnedAtTick: tick,
            ticksAlive: 0
        )
        handles.append(handle)
        return handle
    }

    mutating func tick() {
        for index in handles.indices {
            handles[index].tick()
        }
    }

    mutating func sync(with agents: [LabAgent], tick: Int) -> [LabPhysicalAgentSync] {
        var syncs: [LabPhysicalAgentSync] = []

        for index in handles.indices {
            guard let agent = agents.first(where: { $0.id == handles[index].agentId }) else {
                continue
            }

            let fromPosition = handles[index].position
            let toPosition = agent.position
            let distance = Self.manhattanDistance(fromPosition, toPosition)
            guard distance > 0 else {
                continue
            }

            handles[index].position = toPosition
            syncs.append(LabPhysicalAgentSync(
                agentId: handles[index].agentId,
                physicalId: handles[index].physicalId,
                fromPosition: fromPosition,
                toPosition: toPosition,
                abstractPosition: toPosition,
                distanceManhattan: distance,
                tick: tick
            ))
        }

        return syncs
    }

    func snapshotLinks(for agents: [LabAgent]) -> [LabPhysicalAgentLink] {
        handles.map { handle in
            let abstractPosition = agents.first { $0.id == handle.agentId }?.position ?? handle.position
            return LabPhysicalAgentLink(
                agentId: handle.agentId,
                physicalId: handle.physicalId,
                kind: handle.kind,
                abstractPosition: abstractPosition,
                physicalPosition: handle.position,
                divergence: Self.manhattanDistance(abstractPosition, handle.position),
                spawnedAtTick: handle.spawnedAtTick,
                ticksAlive: handle.ticksAlive
            )
        }
    }

    func totalDivergence(from agents: [LabAgent]) -> Int {
        snapshotLinks(for: agents).reduce(0) { $0 + $1.divergence }
    }

    func maxDivergence(from agents: [LabAgent]) -> Int {
        snapshotLinks(for: agents).map(\.divergence).max() ?? 0
    }

    private static func manhattanDistance(_ a: LabAgentPosition, _ b: LabAgentPosition) -> Int {
        abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z)
    }
}

struct LabCoreEntityBridge {
    private(set) var entities: [LabCoreAgentEntity] = []

    var count: Int { entities.count }
    var linkCount: Int { entities.count }
    var tickCount: Int { entities.reduce(0) { $0 + $1.ticksAlive } }

    mutating func spawnCoreEntity(
        for agent: LabAgent,
        physicalId: String,
        world: World
    ) -> LabCoreAgentEntity {
        let entity = LabCoreAgentEntity(
            world: world,
            labAgentId: agent.id,
            physicalId: physicalId
        )
        Self.setEntity(entity, to: agent.position)
        world.addEntity(entity)
        entities.append(entity)
        return entity
    }

    func tick() {
        for entity in entities {
            entity.tick()
        }
    }

    func sync(with agents: [LabAgent], tick: Int) -> [LabCoreAgentSync] {
        var syncs: [LabCoreAgentSync] = []

        for entity in entities {
            guard let agent = agents.first(where: { $0.id == entity.labAgentId }) else {
                continue
            }

            let fromPosition = Self.entityPosition(entity)
            let toPosition = agent.position
            let distance = Self.manhattanDistance(fromPosition, toPosition)
            guard distance > 0 else {
                continue
            }

            Self.setEntity(entity, to: toPosition)
            syncs.append(LabCoreAgentSync(
                agentId: entity.labAgentId,
                physicalId: entity.physicalId,
                coreEntityId: entity.id,
                fromPosition: fromPosition,
                toPosition: toPosition,
                abstractPosition: toPosition,
                distanceManhattan: distance,
                tick: tick
            ))
        }

        return syncs
    }

    func snapshotLinks(for agents: [LabAgent]) -> [LabCoreAgentLink] {
        entities.map { entity in
            let corePosition = Self.entityPosition(entity)
            let abstractPosition = agents.first { $0.id == entity.labAgentId }?.position ?? corePosition
            return LabCoreAgentLink(
                agentId: entity.labAgentId,
                physicalId: entity.physicalId,
                coreEntityId: entity.id,
                kind: entity.type,
                abstractPosition: abstractPosition,
                coreEntityPosition: corePosition,
                divergence: Self.manhattanDistance(abstractPosition, corePosition),
                ticksAlive: entity.ticksAlive
            )
        }
    }

    func totalDivergence(from agents: [LabAgent]) -> Int {
        snapshotLinks(for: agents).reduce(0) { $0 + $1.divergence }
    }

    func maxDivergence(from agents: [LabAgent]) -> Int {
        snapshotLinks(for: agents).map(\.divergence).max() ?? 0
    }

    private static func entityPosition(_ entity: LabCoreAgentEntity) -> LabAgentPosition {
        LabAgentPosition(
            x: Int(entity.x.rounded()),
            y: Int(entity.y.rounded()),
            z: Int(entity.z.rounded())
        )
    }

    private static func setEntity(_ entity: LabCoreAgentEntity, to position: LabAgentPosition) {
        entity.setPos(Double(position.x), Double(position.y), Double(position.z))
    }

    private static func manhattanDistance(_ a: LabAgentPosition, _ b: LabAgentPosition) -> Int {
        abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z)
    }
}
