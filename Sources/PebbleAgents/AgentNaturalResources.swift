public struct AgentNaturalResourceFingerprintEntry: Codable, Equatable {
    public let fingerprint: Int
    public let resource: AgentResourceKind

    public init(fingerprint: Int, resource: AgentResourceKind) {
        self.fingerprint = fingerprint
        self.resource = resource
    }
}

public enum AgentNaturalResourceFingerprintMappingError: Error, Equatable {
    case duplicateFingerprint(Int)
    case unsupportedResource(AgentResourceKind)
}

public struct AgentNaturalResourceFingerprintMapping: Codable, Equatable {
    public let entries: [AgentNaturalResourceFingerprintEntry]

    public init(entries: [AgentNaturalResourceFingerprintEntry]) throws {
        var fingerprints = Set<Int>()
        for entry in entries {
            guard entry.resource == .wood || entry.resource == .stone else {
                throw AgentNaturalResourceFingerprintMappingError.unsupportedResource(entry.resource)
            }
            guard fingerprints.insert(entry.fingerprint).inserted else {
                throw AgentNaturalResourceFingerprintMappingError.duplicateFingerprint(entry.fingerprint)
            }
        }
        self.entries = entries.sorted {
            if $0.fingerprint != $1.fingerprint { return $0.fingerprint < $1.fingerprint }
            return $0.resource.rawValue < $1.resource.rawValue
        }
    }

    public func resource(for fingerprint: Int) -> AgentResourceKind? {
        entries.first { $0.fingerprint == fingerprint }?.resource
    }
}

public struct AgentNaturalResourceScanConfiguration: Codable, Equatable {
    public static let live = AgentNaturalResourceScanConfiguration()
    public static let maximumHorizontalRadius = AgentResourcePerception.maximumDistance
    public static let maximumVerticalBelow = 2
    public static let maximumVerticalAbove = 4
    public static let maximumCandidateCount = 32
    public static let maximumObservationCount = AgentResourcePerception.maximumObservationCount

    public let horizontalRadius: Int
    public let verticalBelow: Int
    public let verticalAbove: Int
    public let maximumCandidates: Int
    public let maximumObservations: Int

    public init(
        horizontalRadius: Int = maximumHorizontalRadius,
        verticalBelow: Int = maximumVerticalBelow,
        verticalAbove: Int = maximumVerticalAbove,
        maximumCandidates: Int = maximumCandidateCount,
        maximumObservations: Int = maximumObservationCount
    ) {
        self.horizontalRadius = min(max(1, horizontalRadius), Self.maximumHorizontalRadius)
        self.verticalBelow = min(max(0, verticalBelow), Self.maximumVerticalBelow)
        self.verticalAbove = min(max(0, verticalAbove), Self.maximumVerticalAbove)
        self.maximumCandidates = min(max(1, maximumCandidates), Self.maximumCandidateCount)
        self.maximumObservations = min(max(1, maximumObservations), Self.maximumObservationCount)
    }

    public var maximumPositionCount: Int {
        let horizontalPositionCount = 2 * horizontalRadius * (horizontalRadius + 1)
        return horizontalPositionCount * (verticalBelow + verticalAbove + 1)
    }

    public var maximumApproachBlockReadCount: Int {
        maximumCandidates * AgentCardinalDirection.allCases.count * 3
    }

    public var maximumWorldBlockReadCount: Int {
        maximumPositionCount + maximumApproachBlockReadCount
    }
}

public struct AgentNaturalResourceScanSample: Codable, Equatable {
    public let position: AgentPosition
    public let chunkReady: Bool
    public let fingerprint: Int?
    public let mappedResource: AgentResourceKind?
    public let hasCardinalApproach: Bool

    public init(
        position: AgentPosition,
        chunkReady: Bool,
        fingerprint: Int? = nil,
        mappedResource: AgentResourceKind? = nil,
        hasCardinalApproach: Bool = false
    ) {
        self.position = position
        self.chunkReady = chunkReady
        self.fingerprint = fingerprint
        self.mappedResource = mappedResource
        self.hasCardinalApproach = hasCardinalApproach
    }
}

public struct AgentNaturalResourceScanDiagnostics: Codable, Equatable {
    public let positionsConsidered: Int
    public let positionsRead: Int
    public let approachBlockReads: Int
    public let mappedBlockCount: Int
    public let candidateCount: Int
    public let observationsEmitted: Int

    public var worldBlockReadCount: Int { positionsRead + approachBlockReads }

    public init(
        positionsConsidered: Int = 0,
        positionsRead: Int = 0,
        approachBlockReads: Int = 0,
        mappedBlockCount: Int = 0,
        candidateCount: Int = 0,
        observationsEmitted: Int = 0
    ) {
        self.positionsConsidered = positionsConsidered
        self.positionsRead = positionsRead
        self.approachBlockReads = approachBlockReads
        self.mappedBlockCount = mappedBlockCount
        self.candidateCount = candidateCount
        self.observationsEmitted = observationsEmitted
    }
}

public struct AgentNaturalResourceScanResult: Codable, Equatable {
    public let observations: [AgentResourceObservation]
    public let diagnostics: AgentNaturalResourceScanDiagnostics

    public init(
        observations: [AgentResourceObservation],
        diagnostics: AgentNaturalResourceScanDiagnostics,
        approachBlockReads: Int = 0
    ) {
        self.observations = observations
        self.diagnostics = AgentNaturalResourceScanDiagnostics(
            positionsConsidered: diagnostics.positionsConsidered,
            positionsRead: diagnostics.positionsRead,
            approachBlockReads: approachBlockReads,
            mappedBlockCount: diagnostics.mappedBlockCount,
            candidateCount: diagnostics.candidateCount,
            observationsEmitted: diagnostics.observationsEmitted
        )
    }
}

public enum AgentNaturalResourceScanError: Error, Equatable {
    case tooManySamples(Int)
    case duplicatePosition(AgentPosition)
    case positionOutsidePlan(AgentPosition)
    case inconsistentUnavailableSample(AgentPosition)
    case invalidMappedResource(AgentPosition)
    case missingFingerprint(AgentPosition)
}

public enum AgentNaturalResourceScanner {
    public static func positions(
        around origin: AgentPosition,
        configuration: AgentNaturalResourceScanConfiguration = .live
    ) -> [AgentPosition] {
        var horizontalOffsets: [(dx: Int, dz: Int, direction: Int)] = []
        for distance in 1...configuration.horizontalRadius {
            for dx in -distance...distance {
                let dzMagnitude = distance - abs(dx)
                let values = dzMagnitude == 0 ? [0] : [-dzMagnitude, dzMagnitude]
                for dz in values {
                    let target = AgentPosition(x: origin.x + dx, y: origin.y, z: origin.z + dz)
                    let direction = AgentResourcePerception.direction(
                        observerPosition: origin,
                        target: target
                    )
                    let directionIndex = direction.flatMap {
                        AgentCardinalDirection.allCases.firstIndex(of: $0)
                    } ?? 0
                    horizontalOffsets.append((dx, dz, directionIndex))
                }
            }
        }
        horizontalOffsets.sort {
            let lhsDistance = abs($0.dx) + abs($0.dz)
            let rhsDistance = abs($1.dx) + abs($1.dz)
            if lhsDistance != rhsDistance { return lhsDistance < rhsDistance }
            if $0.direction != $1.direction { return $0.direction < $1.direction }
            if $0.dx != $1.dx { return $0.dx < $1.dx }
            return $0.dz < $1.dz
        }

        var positions: [AgentPosition] = []
        positions.reserveCapacity(configuration.maximumPositionCount)
        for offset in horizontalOffsets {
            for dy in (-configuration.verticalBelow)...configuration.verticalAbove {
                positions.append(AgentPosition(
                    x: origin.x + offset.dx,
                    y: origin.y + dy,
                    z: origin.z + offset.dz
                ))
            }
        }
        return positions
    }

    public static func normalize(
        observerPosition: AgentPosition,
        samples: [AgentNaturalResourceScanSample],
        configuration: AgentNaturalResourceScanConfiguration = .live
    ) throws -> AgentNaturalResourceScanResult {
        guard samples.count <= configuration.maximumPositionCount else {
            throw AgentNaturalResourceScanError.tooManySamples(samples.count)
        }
        let permitted = Set(positions(around: observerPosition, configuration: configuration))
        var seen = Set<AgentPosition>()
        var mappedBlockCount = 0
        var candidates: [AgentResourceObservation] = []

        for sample in samples {
            guard permitted.contains(sample.position) else {
                throw AgentNaturalResourceScanError.positionOutsidePlan(sample.position)
            }
            guard seen.insert(sample.position).inserted else {
                throw AgentNaturalResourceScanError.duplicatePosition(sample.position)
            }
            guard sample.chunkReady else {
                guard sample.fingerprint == nil, sample.mappedResource == nil,
                      !sample.hasCardinalApproach else {
                    throw AgentNaturalResourceScanError.inconsistentUnavailableSample(sample.position)
                }
                continue
            }
            guard let resource = sample.mappedResource else { continue }
            mappedBlockCount += 1
            guard resource == .wood || resource == .stone else {
                throw AgentNaturalResourceScanError.invalidMappedResource(sample.position)
            }
            guard let fingerprint = sample.fingerprint else {
                throw AgentNaturalResourceScanError.missingFingerprint(sample.position)
            }
            guard sample.hasCardinalApproach,
                  let direction = AgentResourcePerception.direction(
                      observerPosition: observerPosition,
                      target: sample.position
                  ) else { continue }
            let distance = abs(sample.position.x - observerPosition.x)
                + abs(sample.position.y - observerPosition.y)
                + abs(sample.position.z - observerPosition.z)
            guard (1...configuration.horizontalRadius).contains(distance) else { continue }
            candidates.append(AgentResourceObservation(
                resource: resource,
                target: sample.position,
                direction: direction,
                distanceManhattan: distance,
                quantityAvailable: 1,
                source: .naturalWorld,
                expectedBlockFingerprint: fingerprint
            ))
        }

        let boundedCandidates = Array(candidates.sorted(by: AgentResourcePerception.sortsBefore)
            .prefix(configuration.maximumCandidates))
        let perResourceLimit = max(1, configuration.maximumObservations / 2)
        var boundedObservations: [AgentResourceObservation] = []
        for resource in [AgentResourceKind.wood, .stone] {
            boundedObservations += boundedCandidates
                .filter { $0.resource == resource }
                .prefix(perResourceLimit)
        }
        if boundedObservations.count < configuration.maximumObservations {
            let selected = Set(boundedObservations.map(\.identity))
            boundedObservations += boundedCandidates
                .filter { !selected.contains($0.identity) }
                .prefix(configuration.maximumObservations - boundedObservations.count)
        }
        let observations = try AgentResourcePerception.normalize(
            observerPosition: observerPosition,
            observations: boundedObservations,
            maximumDistance: configuration.horizontalRadius
        )
        return AgentNaturalResourceScanResult(
            observations: observations,
            diagnostics: AgentNaturalResourceScanDiagnostics(
                positionsConsidered: samples.count,
                positionsRead: samples.filter(\.chunkReady).count,
                mappedBlockCount: mappedBlockCount,
                candidateCount: boundedCandidates.count,
                observationsEmitted: observations.count
            )
        )
    }
}
