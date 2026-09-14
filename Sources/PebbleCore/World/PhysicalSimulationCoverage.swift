import Foundation

/// The bounded technical coverage requested by one live physical actor.
///
/// This is scheduling input only. It is neither a durable roster nor a second
/// physical position authority; callers must rebuild it from current World
/// embodiments whenever streaming runs.
public struct PhysicalSimulationCoverageRoot: Equatable, Hashable {
    public let id: String
    public let chunkX: Int
    public let chunkZ: Int

    public init(id: String, chunkX: Int, chunkZ: Int) {
        self.id = id
        self.chunkX = chunkX
        self.chunkZ = chunkZ
    }
}

public struct PhysicalSimulationChunk: Equatable, Hashable {
    public let x: Int
    public let z: Int

    public init(x: Int, z: Int) {
        self.x = x
        self.z = z
    }

    public var key: Int64 { chunkKey(x, z) }

    public static func sortsBefore(
        _ lhs: PhysicalSimulationChunk,
        _ rhs: PhysicalSimulationChunk
    ) -> Bool {
        if lhs.z != rhs.z { return lhs.z < rhs.z }
        return lhs.x < rhs.x
    }
}

/// Pebble supplies one of these values from its validated live embodiment
/// boundary. PebbleCore validates it again before it can affect streaming.
public enum PhysicalSimulationCoverageRequest: Equatable {
    case inactive
    case active([PhysicalSimulationCoverageRoot])
    case refused(String)
}

public enum PhysicalSimulationCoverageStatus: String, Equatable {
    case inactive
    case pending
    case ready
    case refused
}

/// Fixed PS01 Increment 03 limits. A one-chunk halo covers every cell in the
/// existing radius-eight sensing/navigation contract, including at a chunk
/// corner. Thirty disjoint roots therefore retain no more than 270 chunks.
public enum PhysicalSimulationCoverageContract {
    public static let chunkRadius = 1
    public static let maximumRoots = 30
    public static let chunksPerDisjointRoot = 9
    public static let maximumCoveredChunks =
        maximumRoots * chunksPerDisjointRoot
    public static let maximumGenerationJobsInFlight = 24
    public static let maximumAgentGenerationJobsInFlight = 18
    public static let reservedPlayerGenerationJobsInFlight =
        maximumGenerationJobsInFlight
            - maximumAgentGenerationJobsInFlight
}

public struct PhysicalSimulationCoverageSnapshot: Equatable {
    public let status: PhysicalSimulationCoverageStatus
    public let roots: [PhysicalSimulationCoverageRoot]
    public let coveredChunks: [PhysicalSimulationChunk]
    public let readyChunks: [PhysicalSimulationChunk]
    public let unavailableChunks: [PhysicalSimulationChunk]
    public let refusedChunks: [PhysicalSimulationChunk]
    public let rootChunkClaims: Int
    public let generationRequestsThisTick: Int
    public let cumulativeGenerationRequests: Int
    public let reason: String?

    public static let inactive = PhysicalSimulationCoverageSnapshot(
        status: .inactive,
        roots: [],
        coveredChunks: [],
        readyChunks: [],
        unavailableChunks: [],
        refusedChunks: [],
        rootChunkClaims: 0,
        generationRequestsThisTick: 0,
        cumulativeGenerationRequests: 0,
        reason: nil
    )

    public var deduplicatedChunkCount: Int { coveredChunks.count }
    public var isRequested: Bool { status != .inactive }
    public var isReady: Bool { status == .ready }
    public var overlapSavings: Int {
        max(0, rootChunkClaims - coveredChunks.count)
    }
    public var deduplicationRatio: Double {
        guard rootChunkClaims > 0 else { return 1 }
        return Double(coveredChunks.count) / Double(rootChunkClaims)
    }
    public var stableDigest: String {
        var hash: UInt64 = 1469598103934665603
        func mix(_ value: String) {
            for byte in value.utf8 {
                hash ^= UInt64(byte)
                hash &*= 1099511628211
            }
            hash ^= 0xff
            hash &*= 1099511628211
        }
        mix(status.rawValue)
        for root in roots {
            mix("\(root.id):\(root.chunkX):\(root.chunkZ)")
        }
        for chunk in coveredChunks { mix("c:\(chunk.x):\(chunk.z)") }
        for chunk in readyChunks { mix("r:\(chunk.x):\(chunk.z)") }
        for chunk in unavailableChunks { mix("u:\(chunk.x):\(chunk.z)") }
        for chunk in refusedChunks { mix("f:\(chunk.x):\(chunk.z)") }
        mix(reason ?? "none")
        return String(format: "%016llx", hash)
    }

    public func covers(chunkX: Int, chunkZ: Int) -> Bool {
        coveredChunks.binarySearch(
            PhysicalSimulationChunk(x: chunkX, z: chunkZ),
            by: PhysicalSimulationChunk.sortsBefore
        )
    }
}

public enum PhysicalSimulationCoveragePlanner {
    public static func makeSnapshot(
        request: PhysicalSimulationCoverageRequest,
        isChunkReady: (Int, Int) -> Bool,
        refusedChunks: Set<PhysicalSimulationChunk> = [],
        generationRequestsThisTick: Int = 0,
        cumulativeGenerationRequests: Int = 0
    ) -> PhysicalSimulationCoverageSnapshot {
        switch request {
        case .inactive:
            return .inactive
        case .refused(let reason):
            return refused(reason: reason)
        case .active(let requestedRoots):
            guard !requestedRoots.isEmpty else {
                return refused(reason: "active coverage contains no roots")
            }
            guard requestedRoots.count
                    <= PhysicalSimulationCoverageContract.maximumRoots else {
                return refused(
                    reason: "coverage root limit exceeded: "
                        + "\(requestedRoots.count)>"
                        + "\(PhysicalSimulationCoverageContract.maximumRoots)"
                )
            }
            guard requestedRoots.allSatisfy({ !$0.id.isEmpty }) else {
                return refused(reason: "coverage root identity is empty")
            }
            let ids = requestedRoots.map(\.id)
            guard Set(ids).count == ids.count else {
                return refused(reason: "duplicate coverage root identity")
            }

            let roots = requestedRoots.sorted {
                if $0.id != $1.id { return $0.id < $1.id }
                if $0.chunkZ != $1.chunkZ { return $0.chunkZ < $1.chunkZ }
                return $0.chunkX < $1.chunkX
            }
            let radius = PhysicalSimulationCoverageContract.chunkRadius
            var union = Set<PhysicalSimulationChunk>()
            for root in roots {
                for dz in -radius...radius {
                    for dx in -radius...radius {
                        union.insert(PhysicalSimulationChunk(
                            x: root.chunkX + dx,
                            z: root.chunkZ + dz
                        ))
                    }
                }
            }
            guard union.count
                    <= PhysicalSimulationCoverageContract.maximumCoveredChunks else {
                return refused(
                    reason: "coverage chunk limit exceeded: "
                        + "\(union.count)>"
                        + "\(PhysicalSimulationCoverageContract.maximumCoveredChunks)"
                )
            }
            let covered = union.sorted(by: PhysicalSimulationChunk.sortsBefore)
            var ready: [PhysicalSimulationChunk] = []
            var unavailable: [PhysicalSimulationChunk] = []
            for chunk in covered {
                if isChunkReady(chunk.x, chunk.z) {
                    ready.append(chunk)
                } else {
                    unavailable.append(chunk)
                }
            }
            let refusedSorted = refusedChunks
                .intersection(union)
                .sorted(by: PhysicalSimulationChunk.sortsBefore)
            let status: PhysicalSimulationCoverageStatus
            let reason: String?
            if !refusedSorted.isEmpty {
                status = .refused
                reason = "coverage generation request refused"
            } else if unavailable.isEmpty {
                status = .ready
                reason = nil
            } else {
                status = .pending
                reason = "required coverage unavailable"
            }
            return PhysicalSimulationCoverageSnapshot(
                status: status,
                roots: roots,
                coveredChunks: covered,
                readyChunks: ready,
                unavailableChunks: unavailable,
                refusedChunks: refusedSorted,
                rootChunkClaims: roots.count
                    * PhysicalSimulationCoverageContract.chunksPerDisjointRoot,
                generationRequestsThisTick: generationRequestsThisTick,
                cumulativeGenerationRequests: cumulativeGenerationRequests,
                reason: reason
            )
        }
    }

    private static func refused(
        reason: String
    ) -> PhysicalSimulationCoverageSnapshot {
        PhysicalSimulationCoverageSnapshot(
            status: .refused,
            roots: [],
            coveredChunks: [],
            readyChunks: [],
            unavailableChunks: [],
            refusedChunks: [],
            rootChunkClaims: 0,
            generationRequestsThisTick: 0,
            cumulativeGenerationRequests: 0,
            reason: reason
        )
    }
}

private extension Array where Element == PhysicalSimulationChunk {
    func binarySearch(
        _ target: PhysicalSimulationChunk,
        by areInIncreasingOrder:
            (PhysicalSimulationChunk, PhysicalSimulationChunk) -> Bool
    ) -> Bool {
        var low = 0
        var high = count
        while low < high {
            let mid = (low + high) / 2
            if self[mid] == target { return true }
            if areInIncreasingOrder(self[mid], target) {
                low = mid + 1
            } else {
                high = mid
            }
        }
        return false
    }
}
