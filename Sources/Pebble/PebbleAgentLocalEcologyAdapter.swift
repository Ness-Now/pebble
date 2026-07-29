import PebbleAgents
import PebbleCore

struct PebbleAgentLocalEcologyScanDiagnostics: Codable, Equatable {
    var candidatesInspected = 0
    var habitatsValid = 0
    var duplicateHabitatsDiscarded = 0
    var worldReads = 0
    var chunksUnavailable = 0
    var lastWorldTick = 0
    var lastReason = "none"
}

struct PebbleAgentLocalEcologyScanResult {
    let observations: [AgentEcologyHabitatObservation]
    let diagnostics: PebbleAgentLocalEcologyScanDiagnostics
}

struct PebbleAgentLocalEcologyAdapter {
    static let maximumInitialPatches = 2

    private let offsets: [(x: Int, z: Int, direction: Int)] = [
        (2, 0, 1), (0, 2, 2), (-2, 0, 3), (0, -2, 0),
        (3, 0, 1), (0, 3, 2), (-3, 0, 3), (0, -3, 0),
        (2, 1, 1), (1, 2, 2), (-2, 1, 3), (-1, -2, 0),
        (2, -1, 1), (-1, 2, 2), (-2, -1, 3), (1, -2, 0),
    ]
    private let habitatNames = Set([
        "grass_block", "dirt", "coarse_dirt", "podzol", "moss_block",
        "sand", "red_sand", "gravel",
    ])

    func scanInitial(
        world: World,
        settlement: AgentPopulationSettlement,
        occupiedPositions: Set<AgentPosition>,
        residentPositions: [AgentPosition],
        playerPosition: AgentPosition,
        configuration: AgentLocalEcologyConfiguration = .live
    ) throws -> PebbleAgentLocalEcologyScanResult {
        var diagnostics = PebbleAgentLocalEcologyScanDiagnostics(
            lastWorldTick: world.time,
            lastReason: "bounded_initial_scan"
        )
        var observations: [AgentEcologyHabitatObservation] = []
        let bases = Array(residentPositions.prefix(2))
        guard bases.count == 2 else {
            throw AgentLocalEcologyError.invalidHabitat("two resident scan origins required")
        }
        let candidates = bases.flatMap { base in
            offsets.prefix(configuration.maximumHabitatCandidates / bases.count).map {
                (base: base, offset: $0)
            }
        }
        for (index, candidate) in candidates.prefix(configuration.maximumHabitatCandidates).enumerated() {
            guard diagnostics.worldReads < configuration.maximumHabitatReadsPerScan else { break }
            diagnostics.candidatesInspected += 1
            let x = candidate.base.x + candidate.offset.x
            let z = candidate.base.z + candidate.offset.z
            guard world.isChunkReady(x >> 4, z >> 4) else {
                diagnostics.chunksUnavailable += 1
                continue
            }
            let forage = AgentPosition(x: x, y: world.surfaceY(x, z), z: z)
            let habitat = AgentPosition(x: x, y: forage.y - 1, z: z)
            let sample = inspect(
                world: world,
                habitat: habitat,
                forage: forage,
                occupiedPositions: occupiedPositions,
                playerPosition: playerPosition,
                readsRemaining: configuration.maximumHabitatReadsPerScan - diagnostics.worldReads
            )
            diagnostics.worldReads += sample.reads
            guard sample.valid, let fingerprint = sample.fingerprint else { continue }
            diagnostics.habitatsValid += 1
            observations.append(AgentEcologyHabitatObservation(
                worldTick: world.time,
                candidateIndex: index,
                settlementID: settlement.settlementID,
                habitatPosition: habitat,
                foragePosition: forage,
                habitatFingerprint: fingerprint,
                distanceFromSettlement: manhattan(settlement.anchor, forage),
                directionIndex: candidate.offset.direction,
                worldReadCount: sample.reads
            ))
        }
        let limit = min(Self.maximumInitialPatches, configuration.maximumPatches)
        var selected: [AgentEcologyHabitatObservation] = []
        var selectedPatchIDs = Set<AgentEcologyPatchID>()
        for observation in observations.sorted(by: AgentEcologyHabitatObservation.sortsBefore) {
            guard selectedPatchIDs.insert(observation.patchID).inserted else {
                diagnostics.duplicateHabitatsDiscarded += 1
                continue
            }
            selected.append(observation)
            if selected.count == limit { break }
        }
        return PebbleAgentLocalEcologyScanResult(observations: selected, diagnostics: diagnostics)
    }

    func validate(
        world: World,
        settlement: AgentPopulationSettlement,
        patches: [AgentEcologyPatch],
        maximumReads: Int = 256
    ) -> PebbleAgentLocalEcologyScanResult {
        var diagnostics = PebbleAgentLocalEcologyScanDiagnostics(
            lastWorldTick: world.time,
            lastReason: "registered_patch_validation"
        )
        var observations: [AgentEcologyHabitatObservation] = []
        for (index, patch) in patches.sorted(by: { $0.patchID < $1.patchID }).enumerated() {
            guard diagnostics.worldReads < maximumReads else { break }
            diagnostics.candidatesInspected += 1
            let sample = inspect(
                world: world,
                habitat: patch.habitatPosition,
                forage: patch.foragePosition,
                occupiedPositions: [],
                playerPosition: nil,
                readsRemaining: maximumReads - diagnostics.worldReads
            )
            diagnostics.worldReads += sample.reads
            if !sample.chunkReady { diagnostics.chunksUnavailable += 1 }
            if sample.valid { diagnostics.habitatsValid += 1 }
            observations.append(AgentEcologyHabitatObservation(
                worldTick: world.time,
                candidateIndex: index,
                settlementID: settlement.settlementID,
                habitatPosition: patch.habitatPosition,
                foragePosition: patch.foragePosition,
                habitatFingerprint: sample.fingerprint ?? -1,
                distanceFromSettlement: manhattan(settlement.anchor, patch.foragePosition),
                directionIndex: directionIndex(from: settlement.anchor, to: patch.foragePosition),
                habitatChunkReady: sample.chunkReady,
                forageChunkReady: sample.chunkReady,
                habitatValid: sample.habitatValid,
                forageAccessible: sample.forageAccessible,
                worldReadCount: max(1, sample.reads)
            ))
        }
        return PebbleAgentLocalEcologyScanResult(observations: observations, diagnostics: diagnostics)
    }

    private func inspect(
        world: World,
        habitat: AgentPosition,
        forage: AgentPosition,
        occupiedPositions: Set<AgentPosition>,
        playerPosition: AgentPosition?,
        readsRemaining: Int
    ) -> (
        valid: Bool,
        chunkReady: Bool,
        habitatValid: Bool,
        forageAccessible: Bool,
        fingerprint: Int?,
        reads: Int
    ) {
        guard readsRemaining >= 3,
              world.isChunkReady(habitat.x >> 4, habitat.z >> 4),
              world.isChunkReady(forage.x >> 4, forage.z >> 4) else {
            return (false, false, false, false, nil, 0)
        }
        let fingerprint = world.getBlock(habitat.x, habitat.y, habitat.z)
        let feet = world.getBlock(forage.x, forage.y, forage.z)
        let head = world.getBlock(forage.x, forage.y + 1, forage.z)
        let habitatID = fingerprint >> 4
        let habitatValid = habitatID >= 0 && habitatID < blockDefs.count
            && blockDefs[habitatID].solid
            && habitatNames.contains(blockDefs[habitatID].name)
        let approach = hasCardinalApproach(
            world: world,
            forage: forage,
            occupiedPositions: occupiedPositions,
            playerPosition: playerPosition,
            readsRemaining: readsRemaining - 3
        )
        let forageAccessible = isAir(UInt16(truncatingIfNeeded: feet))
            && isAir(UInt16(truncatingIfNeeded: head))
            && !occupiedPositions.contains(forage)
            && playerPosition != forage
            && approach.available
        return (
            habitatValid && forageAccessible,
            true,
            habitatValid,
            forageAccessible,
            fingerprint,
            3 + approach.reads
        )
    }

    private func hasCardinalApproach(
        world: World,
        forage: AgentPosition,
        occupiedPositions: Set<AgentPosition>,
        playerPosition: AgentPosition?,
        readsRemaining: Int
    ) -> (available: Bool, reads: Int) {
        var reads = 0
        for direction in AgentCardinalDirection.allCases {
            guard reads + 3 <= readsRemaining else { break }
            let x = forage.x + direction.dx
            let z = forage.z + direction.dz
            guard world.isChunkReady(x >> 4, z >> 4) else { continue }
            let candidate = AgentPosition(x: x, y: world.surfaceY(x, z), z: z)
            let below = world.getBlock(x, candidate.y - 1, z)
            let feet = world.getBlock(x, candidate.y, z)
            let head = world.getBlock(x, candidate.y + 1, z)
            reads += 3
            let belowID = below >> 4
            if candidate.y == forage.y,
               belowID >= 0, belowID < blockDefs.count, blockDefs[belowID].solid,
               isAir(UInt16(truncatingIfNeeded: feet)),
               isAir(UInt16(truncatingIfNeeded: head)),
               !occupiedPositions.contains(candidate), playerPosition != candidate {
                return (true, reads)
            }
        }
        return (false, reads)
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
