import PebbleAgents
import PebbleCore

struct PebbleAgentNaturalResourceMappingEntry: Equatable {
    let blockName: String
    let fingerprint: Int
    let metadata: Int
    let resource: AgentResourceKind
}

enum PebbleAgentNaturalResourceMapping {
    static var entries: [PebbleAgentNaturalResourceMappingEntry] {
        [
            PebbleAgentNaturalResourceMappingEntry(
                blockName: "oak_log",
                fingerprint: Int(cell(B.oak_log)),
                metadata: 0,
                resource: .wood
            ),
            PebbleAgentNaturalResourceMappingEntry(
                blockName: "birch_log",
                fingerprint: Int(cell(B.birch_log)),
                metadata: 0,
                resource: .wood
            ),
            PebbleAgentNaturalResourceMappingEntry(
                blockName: "stone",
                fingerprint: Int(cell(B.stone)),
                metadata: 0,
                resource: .stone
            ),
        ]
    }

    static func resource(for fingerprint: Int) -> AgentResourceKind? {
        contract.resource(for: fingerprint)
    }

    static func blockName(for fingerprint: Int) -> String? {
        entries.first { $0.fingerprint == fingerprint }?.blockName
    }

    private static let contract = try! AgentNaturalResourceFingerprintMapping(entries: entries.map {
        AgentNaturalResourceFingerprintEntry(
            fingerprint: $0.fingerprint,
            resource: $0.resource
        )
    })
}

struct PebbleAgentNaturalResourceAdapter {
    static let configuration = AgentNaturalResourceScanConfiguration.live

    private let navigationAdapter = PebbleAgentNavigationAdapter()

    func scan(
        world: World,
        agent: AgentSnapshot,
        occupiedAgentPositions: [AgentPosition],
        playerPosition: AgentPosition,
        priorityTarget: AgentPosition? = nil
    ) throws -> AgentNaturalResourceScanResult {
        let positions = AgentNaturalResourceScanner.positions(
            around: agent.position,
            configuration: Self.configuration
        )
        var samples: [AgentNaturalResourceScanSample] = []
        samples.reserveCapacity(positions.count)
        var mapped: [(index: Int, resource: AgentResourceKind, position: AgentPosition)] = []

        for position in positions {
            guard world.isChunkReady(position.x >> 4, position.z >> 4) else {
                samples.append(AgentNaturalResourceScanSample(
                    position: position,
                    chunkReady: false
                ))
                continue
            }
            let fingerprint = world.getBlock(position.x, position.y, position.z)
            let resource = PebbleAgentNaturalResourceMapping.resource(for: fingerprint)
            samples.append(AgentNaturalResourceScanSample(
                position: position,
                chunkReady: true,
                fingerprint: fingerprint,
                mappedResource: resource,
                hasCardinalApproach: false
            ))
            if let resource {
                mapped.append((samples.count - 1, resource, position))
            }
        }

        mapped.sort { lhs, rhs in
            let lhsResource = lhs.resource == .wood ? 0 : 1
            let rhsResource = rhs.resource == .wood ? 0 : 1
            if lhsResource != rhsResource { return lhsResource < rhsResource }
            let lhsDistance = manhattan(lhs.position, agent.position)
            let rhsDistance = manhattan(rhs.position, agent.position)
            if lhsDistance != rhsDistance { return lhsDistance < rhsDistance }
            let lhsDirection = directionIndex(from: agent.position, to: lhs.position)
            let rhsDirection = directionIndex(from: agent.position, to: rhs.position)
            if lhsDirection != rhsDirection { return lhsDirection < rhsDirection }
            if lhs.position.x != rhs.position.x { return lhs.position.x < rhs.position.x }
            if lhs.position.y != rhs.position.y { return lhs.position.y < rhs.position.y }
            return lhs.position.z < rhs.position.z
        }

        var boundedMapped: [(index: Int, resource: AgentResourceKind, position: AgentPosition)] = []
        let perResourceLimit = max(1, Self.configuration.maximumCandidates / 2)
        if let priorityTarget,
           let priority = mapped.first(where: { $0.position == priorityTarget }) {
            boundedMapped.append(priority)
        }
        for resource in [AgentResourceKind.wood, .stone] {
            let selectedIndices = Set(boundedMapped.map(\.index))
            let selectedForResource = boundedMapped.filter { $0.resource == resource }.count
            boundedMapped += mapped.filter {
                $0.resource == resource && !selectedIndices.contains($0.index)
            }.prefix(max(0, perResourceLimit - selectedForResource))
        }
        if boundedMapped.count < Self.configuration.maximumCandidates {
            let selectedIndices = Set(boundedMapped.map(\.index))
            boundedMapped += mapped
                .filter { !selectedIndices.contains($0.index) }
                .prefix(Self.configuration.maximumCandidates - boundedMapped.count)
        }

        var approachBlockReads = 0
        for candidate in boundedMapped {
            let sample = samples[candidate.index]
            let targetOccupied = occupiedAgentPositions.contains(candidate.position)
                || playerPosition == candidate.position
            let approach = targetOccupied
                ? (available: false, blockReads: 0)
                : navigationAdapter.hasCardinalApproach(
                    world: world,
                    target: candidate.position,
                    occupiedAgentPositions: occupiedAgentPositions + [playerPosition]
                )
            approachBlockReads += approach.blockReads
            samples[candidate.index] = AgentNaturalResourceScanSample(
                position: sample.position,
                chunkReady: true,
                fingerprint: sample.fingerprint,
                mappedResource: sample.mappedResource,
                hasCardinalApproach: approach.available
            )
        }

        let normalized = try AgentNaturalResourceScanner.normalize(
            observerPosition: agent.position,
            samples: samples,
            configuration: Self.configuration
        )
        return AgentNaturalResourceScanResult(
            observations: normalized.observations,
            diagnostics: normalized.diagnostics,
            approachBlockReads: approachBlockReads
        )
    }

    func observeSocialVerification(
        world: World,
        request: AgentSocialVerificationRequest
    ) -> AgentSocialVerificationObservation {
        let position = request.position
        guard world.isChunkReady(position.x >> 4, position.z >> 4) else {
            return AgentSocialVerificationObservation(
                beliefID: request.beliefID,
                verifierID: request.verifierID,
                position: position,
                chunkReady: false
            )
        }
        let fingerprint = world.getBlock(position.x, position.y, position.z)
        return AgentSocialVerificationObservation(
            beliefID: request.beliefID,
            verifierID: request.verifierID,
            position: position,
            chunkReady: true,
            observedBlockFingerprint: fingerprint,
            observedResource: PebbleAgentNaturalResourceMapping.resource(for: fingerprint)
        )
    }

    private func manhattan(_ lhs: AgentPosition, _ rhs: AgentPosition) -> Int {
        abs(lhs.x - rhs.x) + abs(lhs.y - rhs.y) + abs(lhs.z - rhs.z)
    }

    private func directionIndex(from origin: AgentPosition, to target: AgentPosition) -> Int {
        AgentResourcePerception.direction(observerPosition: origin, target: target).flatMap {
            AgentCardinalDirection.allCases.firstIndex(of: $0)
        } ?? 0
    }
}
