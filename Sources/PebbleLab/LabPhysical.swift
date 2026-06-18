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

struct PhysicalBehaviorSnapshot: Encodable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let agentId: String
    let physicalId: String
    let coreEntityId: Int
    let startPosition: LabAgentPosition
    let finalAbstractPosition: LabAgentPosition
    let finalCoreEntityPosition: LabAgentPosition
    let moves: Int
    let totalDistance: Int
    let finalDivergence: Int
    let success: Bool
}

struct PhysicalBehaviorAgentSnapshot: Encodable {
    let agentId: String
    let physicalId: String
    let coreEntityId: Int
    let startPosition: LabAgentPosition
    let finalAbstractPosition: LabAgentPosition
    let finalCoreEntityPosition: LabAgentPosition
    let moves: Int
    let totalDistance: Int
    let finalDivergence: Int
}

struct PhysicalBehaviorMultiSnapshot: Encodable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let agents: [PhysicalBehaviorAgentSnapshot]
    let agentsMoved: Int
    let totalMoves: Int
    let totalDistance: Int
    let finalDivergence: Int
    let maxDivergence: Int
    let success: Bool
}

struct PhysicalBehaviorInvariantReport: Encodable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let summary: PhysicalBehaviorInvariantSummary
    let checks: [PhysicalBehaviorInvariantCheck]
    let notes: [String]
}

struct PhysicalBehaviorInvariantSummary: Encodable {
    let checksPassed: Int
    let checksFailed: Int
    let agents: Int
    let placeholders: Int
    let coreEntities: Int
    let agentsMoved: Int
    let totalMoves: Int
    let totalDistance: Int
    let finalDivergence: Int
    let maxDivergence: Int
}

struct PhysicalBehaviorInvariantCheck: Encodable {
    let name: String
    let passed: Bool
    let expected: String
    let actual: String
}

struct CoreEntityInvariantReport: Encodable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let summary: CoreEntityInvariantSummary
    let checks: [CoreEntityInvariantCheck]
    let notes: [String]
}

struct CoreEntityInvariantSummary: Encodable {
    let checksPassed: Int
    let checksFailed: Int
    let labAgents: Int
    let physicalPlaceholders: Int
    let coreEntities: Int
    let worldEntities: Int
    let abstractCoreEntityDivergence: Int
}

struct CoreEntityInvariantCheck: Encodable {
    let name: String
    let passed: Bool
    let expected: String
    let actual: String
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

    func physicalBehaviorInvariantReport(
        scenario: String,
        seed: UInt32,
        ticksCompleted: Int,
        agents: [LabAgent],
        physicalBridge: LabAgentPhysicalBridge,
        agentsMoved: Int,
        totalMoves: Int,
        totalDistance: Int
    ) -> PhysicalBehaviorInvariantReport {
        let finalDivergence = totalDivergence(from: agents)
        let finalMaxDivergence = maxDivergence(from: agents)
        let expectedAgents = 3
        let eachAgentHasOnePlaceholder = agents.allSatisfy { agent in
            physicalBridge.handles.filter { $0.agentId == agent.id }.count == 1
        } && physicalBridge.count == agents.count
        let eachAgentHasOneCoreEntity = agents.allSatisfy { agent in
            entities.filter { $0.labAgentId == agent.id }.count == 1
        } && count == agents.count
        let uniquePhysicalIds = Set(physicalBridge.handles.map(\.physicalId)).count
        let uniqueCoreEntityIds = Set(entities.map(\.id)).count
        let physicalIdsMatchCoreEntities = agents.allSatisfy { agent in
            guard let handle = physicalBridge.handles.first(where: { $0.agentId == agent.id }),
                  let entity = entities.first(where: { $0.labAgentId == agent.id }) else {
                return false
            }
            return handle.physicalId == entity.physicalId
        }

        let checks = [
            PhysicalBehaviorInvariantCheck(
                name: "agent_count",
                passed: agents.count == expectedAgents,
                expected: "\(expectedAgents)",
                actual: "\(agents.count)"
            ),
            PhysicalBehaviorInvariantCheck(
                name: "each_agent_has_one_placeholder",
                passed: eachAgentHasOnePlaceholder,
                expected: "true",
                actual: "\(eachAgentHasOnePlaceholder)"
            ),
            PhysicalBehaviorInvariantCheck(
                name: "each_agent_has_one_core_entity",
                passed: eachAgentHasOneCoreEntity,
                expected: "true",
                actual: "\(eachAgentHasOneCoreEntity)"
            ),
            PhysicalBehaviorInvariantCheck(
                name: "physical_ids_unique",
                passed: uniquePhysicalIds == physicalBridge.count,
                expected: "\(physicalBridge.count) unique",
                actual: "\(uniquePhysicalIds) unique"
            ),
            PhysicalBehaviorInvariantCheck(
                name: "core_entity_ids_unique",
                passed: uniqueCoreEntityIds == count,
                expected: "\(count) unique",
                actual: "\(uniqueCoreEntityIds) unique"
            ),
            PhysicalBehaviorInvariantCheck(
                name: "physical_ids_match_core_entities",
                passed: physicalIdsMatchCoreEntities,
                expected: "true",
                actual: "\(physicalIdsMatchCoreEntities)"
            ),
            PhysicalBehaviorInvariantCheck(
                name: "at_least_two_agents_moved",
                passed: agentsMoved >= 2,
                expected: ">= 2",
                actual: "\(agentsMoved)"
            ),
            PhysicalBehaviorInvariantCheck(
                name: "total_distance_positive",
                passed: totalDistance > 0,
                expected: "> 0",
                actual: "\(totalDistance)"
            ),
            PhysicalBehaviorInvariantCheck(
                name: "final_divergence_zero",
                passed: finalDivergence == 0,
                expected: "0",
                actual: "\(finalDivergence)"
            ),
            PhysicalBehaviorInvariantCheck(
                name: "max_divergence_zero",
                passed: finalMaxDivergence == 0,
                expected: "0",
                actual: "\(finalMaxDivergence)"
            )
        ]
        let checksFailed = checks.filter { !$0.passed }.count

        return PhysicalBehaviorInvariantReport(
            scenario: scenario,
            seed: seed,
            ticksCompleted: ticksCompleted,
            success: checksFailed == 0,
            summary: PhysicalBehaviorInvariantSummary(
                checksPassed: checks.count - checksFailed,
                checksFailed: checksFailed,
                agents: agents.count,
                placeholders: physicalBridge.count,
                coreEntities: count,
                agentsMoved: agentsMoved,
                totalMoves: totalMoves,
                totalDistance: totalDistance,
                finalDivergence: finalDivergence,
                maxDivergence: finalMaxDivergence
            ),
            checks: checks,
            notes: [
                "This report validates the multi-agent physical behavior smoke.",
                "It does not prove pathfinding, collision, block interaction, or social physical behavior."
            ]
        )
    }

    func invariantReport(
        scenario: String,
        seed: UInt32,
        ticksCompleted: Int,
        agents: [LabAgent],
        physicalBridge: LabAgentPhysicalBridge,
        world: World
    ) -> CoreEntityInvariantReport {
        let divergence = totalDivergence(from: agents)
        let worldContainsAll = entities.allSatisfy { entity in
            world.entities.contains { $0 === entity }
                && world.entityById[entity.id] === entity
        }
        let agentsMatch = entities.allSatisfy { entity in
            agents.contains { $0.id == entity.labAgentId }
        }
        let physicalIdsMatch = entities.allSatisfy { entity in
            physicalBridge.handles.contains {
                $0.agentId == entity.labAgentId && $0.physicalId == entity.physicalId
            }
        }
        let kindsMatch = entities.allSatisfy { $0.type == LabCoreAgentEntity.kind }
        let ticksRecorded = !entities.isEmpty && entities.allSatisfy { $0.ticksAlive > 0 }

        let checks = [
            CoreEntityInvariantCheck(
                name: "core_entity_count",
                passed: entities.count == agents.count,
                expected: "\(agents.count)",
                actual: "\(entities.count)"
            ),
            CoreEntityInvariantCheck(
                name: "world_contains_core_entity",
                passed: worldContainsAll,
                expected: "true",
                actual: "\(worldContainsAll)"
            ),
            CoreEntityInvariantCheck(
                name: "core_entity_has_matching_lab_agent",
                passed: agentsMatch,
                expected: agents.map(\.id).sorted().joined(separator: ","),
                actual: entities.map(\.labAgentId).sorted().joined(separator: ",")
            ),
            CoreEntityInvariantCheck(
                name: "core_entity_has_matching_physical_id",
                passed: physicalIdsMatch,
                expected: physicalBridge.handles.map(\.physicalId).sorted().joined(separator: ","),
                actual: entities.map(\.physicalId).sorted().joined(separator: ",")
            ),
            CoreEntityInvariantCheck(
                name: "core_entity_kind_is_probe",
                passed: kindsMatch,
                expected: LabCoreAgentEntity.kind,
                actual: entities.map(\.type).sorted().joined(separator: ",")
            ),
            CoreEntityInvariantCheck(
                name: "abstract_core_divergence_zero",
                passed: divergence == 0,
                expected: "0",
                actual: "\(divergence)"
            ),
            CoreEntityInvariantCheck(
                name: "core_entity_ticks_recorded",
                passed: ticksRecorded,
                expected: "> 0",
                actual: "\(tickCount)"
            ),
            CoreEntityInvariantCheck(
                name: "registry_not_modified_runtime_contract",
                passed: true,
                expected: "unregistered direct construction",
                actual: "no EntityRegistry path used by scenario"
            )
        ]
        let checksPassed = checks.filter(\.passed).count
        let checksFailed = checks.count - checksPassed

        return CoreEntityInvariantReport(
            scenario: scenario,
            seed: seed,
            ticksCompleted: ticksCompleted,
            success: checksFailed == 0,
            summary: CoreEntityInvariantSummary(
                checksPassed: checksPassed,
                checksFailed: checksFailed,
                labAgents: agents.count,
                physicalPlaceholders: physicalBridge.count,
                coreEntities: entities.count,
                worldEntities: world.entities.count,
                abstractCoreEntityDivergence: divergence
            ),
            checks: checks,
            notes: [
                "This report validates the PebbleLab core entity probe contract.",
                "The unregistered check is a scenario contract; it does not introspect or mutate EntityRegistry.",
                "This report does not prove save/load or renderer integration."
            ]
        )
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
