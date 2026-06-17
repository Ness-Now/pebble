import Foundation

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
