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

struct LabPhysicalAgentLink: Encodable {
    let agentId: String
    let physicalId: String
    let kind: String
    let abstractPosition: LabAgentPosition
    let physicalPosition: LabAgentPosition
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

    func snapshotLinks(for agents: [LabAgent]) -> [LabPhysicalAgentLink] {
        handles.map { handle in
            let abstractPosition = agents.first { $0.id == handle.agentId }?.position ?? handle.position
            return LabPhysicalAgentLink(
                agentId: handle.agentId,
                physicalId: handle.physicalId,
                kind: handle.kind,
                abstractPosition: abstractPosition,
                physicalPosition: handle.position,
                spawnedAtTick: handle.spawnedAtTick,
                ticksAlive: handle.ticksAlive
            )
        }
    }
}
