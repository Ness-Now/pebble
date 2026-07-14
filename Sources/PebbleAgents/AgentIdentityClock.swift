public enum AgentIdentityError: Error, Equatable {
    case invalidAgentID(String)
    case invalidSimulationID(String)
    case invalidOperationID(String)
}

public struct AgentID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard Self.isValid(rawValue) else { return nil }
        self.rawValue = rawValue
    }

    public init(validating rawValue: String) throws {
        guard Self.isValid(rawValue) else { throw AgentIdentityError.invalidAgentID(rawValue) }
        self.rawValue = rawValue
    }

    public static func < (lhs: AgentID, rhs: AgentID) -> Bool { lhs.rawValue < rhs.rawValue }

    private static func isValid(_ value: String) -> Bool {
        guard (1...64).contains(value.utf8.count) else { return false }
        return value.utf8.allSatisfy {
            (65...90).contains($0) || (97...122).contains($0) || (48...57).contains($0)
                || $0 == 45 || $0 == 46 || $0 == 95
        }
    }
}

public struct AgentSimulationID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...128).contains(rawValue.utf8.count),
              rawValue.utf8.allSatisfy({
                  (65...90).contains($0) || (97...122).contains($0) || (48...57).contains($0)
                      || $0 == 45 || $0 == 46 || $0 == 95
              }) else { return nil }
        self.rawValue = rawValue
    }

    public init(validating rawValue: String) throws {
        guard let value = AgentSimulationID(rawValue: rawValue) else {
            throw AgentIdentityError.invalidSimulationID(rawValue)
        }
        self = value
    }

    public static func legacy(seed: UInt32) -> AgentSimulationID {
        AgentSimulationID(rawValue: "legacy-seed-\(seed)")!
    }

    public static func < (lhs: AgentSimulationID, rhs: AgentSimulationID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct AgentOperationID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...256).contains(rawValue.utf8.count),
              rawValue.utf8.allSatisfy({ (33...126).contains($0) }) else { return nil }
        self.rawValue = rawValue
    }

    public init(validating rawValue: String) throws {
        guard let value = AgentOperationID(rawValue: rawValue) else {
            throw AgentIdentityError.invalidOperationID(rawValue)
        }
        self = value
    }

    public static func < (lhs: AgentOperationID, rhs: AgentOperationID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct AgentSimulationTick: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: Int

    public init?(rawValue: Int) {
        guard rawValue >= 0 else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: AgentSimulationTick, rhs: AgentSimulationTick) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct AgentSimulationInstant: Codable, Equatable, Sendable {
    public let simulationID: AgentSimulationID
    public let tick: AgentSimulationTick

    public init(simulationID: AgentSimulationID, tick: AgentSimulationTick) {
        self.simulationID = simulationID
        self.tick = tick
    }
}

public struct AgentSimulationIdentitySnapshot: Codable, Equatable, Sendable {
    public let simulationID: AgentSimulationID
    public let agentIDs: [AgentID]

    public init(simulationID: AgentSimulationID, agentIDs: [AgentID]) {
        self.simulationID = simulationID
        self.agentIDs = agentIDs.sorted()
    }
}

public struct AgentSimulationClock: Codable, Equatable, Sendable {
    public let simulationID: AgentSimulationID
    public private(set) var tick: AgentSimulationTick

    public init(simulationID: AgentSimulationID, initialTick: AgentSimulationTick) {
        self.simulationID = simulationID
        tick = initialTick
    }

    public var instant: AgentSimulationInstant {
        AgentSimulationInstant(simulationID: simulationID, tick: tick)
    }

    public func nextTick() throws -> AgentSimulationTick {
        guard tick.rawValue < Int.max,
              let next = AgentSimulationTick(rawValue: tick.rawValue + 1) else {
            throw AgentSessionError.simulationTickOverflow
        }
        return next
    }

    mutating func advance(to nextTick: AgentSimulationTick) {
        precondition(nextTick.rawValue == tick.rawValue + 1)
        tick = nextTick
    }
}

struct AgentStateStore {
    private var storage: [AgentID: AgentSessionAgentState] = [:]

    var count: Int { storage.count }
    var keys: [String] { storage.keys.map(\.rawValue) }
    var values: [AgentSessionAgentState] { Array(storage.values) }

    subscript(rawID: String) -> AgentSessionAgentState? {
        get {
            guard let id = AgentID(rawValue: rawID) else { return nil }
            return storage[id]
        }
        set {
            guard let id = AgentID(rawValue: rawID) else {
                preconditionFailure("invalid AgentID: \(rawID)")
            }
            if let newValue {
                precondition(newValue.agentID == id)
                storage[id] = newValue
            } else {
                storage.removeValue(forKey: id)
            }
        }
    }

    func mapValues<T>(_ transform: (AgentSessionAgentState) throws -> T) rethrows -> [String: T] {
        var result: [String: T] = [:]
        for id in storage.keys.sorted() {
            result[id.rawValue] = try transform(storage[id]!)
        }
        return result
    }
}
