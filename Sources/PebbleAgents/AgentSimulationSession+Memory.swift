extension AgentSimulationSession {
    var sortedIds: [String] {
        statesById.keys.sorted()
    }

    func distanceFromHome(_ state: AgentSessionAgentState) -> Int {
        abs(state.position.x - state.homePosition.x)
            + abs(state.position.y - state.homePosition.y)
            + abs(state.position.z - state.homePosition.z)
    }

    func positionKey(_ position: AgentPosition) -> String {
        "\(position.x),\(position.y),\(position.z)"
    }

    func positionText(_ position: AgentPosition) -> String {
        "(\(position.x),\(position.y),\(position.z))"
    }

    func manhattanDistance(_ lhs: AgentPosition, _ rhs: AgentPosition) -> Int {
        abs(lhs.x - rhs.x) + abs(lhs.y - rhs.y) + abs(lhs.z - rhs.z)
    }

    func appendMemory(
        _ entry: AgentMemoryEntry,
        to memory: inout [AgentMemoryEntry]
    ) {
        AgentCognitiveTransitions.appendLegacyUnboundedMemory(entry, to: &memory)
        applyMemoryPolicy(configuration.memoryPolicy, to: &memory)
    }

    func appendMemories(
        _ entries: [AgentMemoryEntry],
        to memory: inout [AgentMemoryEntry]
    ) {
        for entry in entries {
            appendMemory(entry, to: &memory)
        }
    }
}

func applyMemoryPolicy(_ policy: AgentMemoryPolicy, to memory: inout [AgentMemoryEntry]) {
    guard case let .bounded(maxEntries) = policy, memory.count > maxEntries else { return }
    memory = Array(memory.suffix(maxEntries))
}
