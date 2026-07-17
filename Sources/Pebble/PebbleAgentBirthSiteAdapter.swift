import PebbleAgents
import PebbleCore

struct PebbleAgentBirthSiteScanResult {
    let observation: AgentBirthSiteObservation
    let validCandidateCount: Int
}

struct PebbleAgentBirthSiteAdapter {
    private let offsets: [(x: Int, z: Int)] = [
        (0, 1), (1, 0), (0, -1), (-1, 0),
        (1, 1), (1, -1), (-1, -1), (-1, 1),
        (0, 2), (2, 0), (0, -2), (-2, 0),
        (2, 1), (1, 2), (-1, 2), (-2, 1),
    ]

    func observe(
        world: World,
        plan: AgentReproductionPlan,
        simulationTick: Int,
        settlement: AgentPopulationSettlement,
        occupiedPositions: Set<AgentPosition>,
        configuration: AgentLifecycleConfiguration
    ) -> PebbleAgentBirthSiteScanResult {
        var observations: [AgentBirthSiteObservation] = []
        var reads = 0
        for (index, offset) in offsets.prefix(configuration.maximumBirthSiteCandidates).enumerated() {
            guard reads + 3 <= configuration.maximumBirthSiteWorldReads else { break }
            let x = settlement.receptionPosition.x + offset.x
            let z = settlement.receptionPosition.z + offset.z
            let chunkReady = world.isChunkReady(x >> 4, z >> 4)
            let position = AgentPosition(
                x: x,
                y: chunkReady ? world.surfaceY(x, z) : settlement.receptionPosition.y,
                z: z
            )
            let below = chunkReady ? world.getBlock(x, position.y - 1, z) : 0
            let feet = chunkReady ? world.getBlock(x, position.y, z) : 0
            let head = chunkReady ? world.getBlock(x, position.y + 1, z) : 0
            reads += chunkReady ? 3 : 0
            let belowID = below >> 4
            let floorSolid = chunkReady && belowID >= 0 && belowID < blockDefs.count
                && blockDefs[belowID].solid && belowID != Int(B.water)
                && belowID != Int(B.lava)
            let feetFree = chunkReady && isAir(UInt16(truncatingIfNeeded: feet))
            let headFree = chunkReady && isAir(UInt16(truncatingIfNeeded: head))
            let fingerprint = below &* 31 &+ feet &* 17 &+ head
            observations.append(AgentBirthSiteObservation(
                planID: plan.planID,
                observedTick: simulationTick,
                settlementID: settlement.settlementID,
                floorPosition: AgentPosition(x: x, y: position.y - 1, z: z),
                position: position,
                candidateIndex: index,
                worldFingerprint: fingerprint,
                chunkReady: chunkReady,
                floorSolid: floorSolid,
                feetFree: feetFree,
                headFree: headFree,
                unoccupied: !occupiedPositions.contains(position),
                candidatesConsidered: min(
                    offsets.count, configuration.maximumBirthSiteCandidates
                ),
                worldReads: max(1, reads),
                distanceFromReception: manhattan(position, settlement.receptionPosition),
                scanDiagnostics: "bounded_read_only_scan"
            ))
        }
        let valid = observations.filter(\.isValid).sorted { lhs, rhs in
            let lhsDistance = manhattan(lhs.position, settlement.receptionPosition)
            let rhsDistance = manhattan(rhs.position, settlement.receptionPosition)
            if lhsDistance != rhsDistance { return lhsDistance < rhsDistance }
            if lhs.candidateIndex != rhs.candidateIndex {
                return lhs.candidateIndex < rhs.candidateIndex
            }
            if lhs.position.x != rhs.position.x { return lhs.position.x < rhs.position.x }
            if lhs.position.y != rhs.position.y { return lhs.position.y < rhs.position.y }
            return lhs.position.z < rhs.position.z
        }
        let selected = valid.first ?? observations.first ?? AgentBirthSiteObservation(
            planID: plan.planID,
            observedTick: simulationTick,
            settlementID: settlement.settlementID,
            floorPosition: AgentPosition(
                x: settlement.receptionPosition.x,
                y: settlement.receptionPosition.y - 1,
                z: settlement.receptionPosition.z
            ),
            position: settlement.receptionPosition,
            candidateIndex: 0,
            worldFingerprint: 0,
            chunkReady: false,
            floorSolid: false,
            feetFree: false,
            headFree: false,
            unoccupied: false,
            candidatesConsidered: 1,
            worldReads: 1,
            distanceFromReception: 0,
            scanDiagnostics: "no_candidate"
        )
        return PebbleAgentBirthSiteScanResult(
            observation: selected,
            validCandidateCount: valid.count
        )
    }

    private func manhattan(_ lhs: AgentPosition, _ rhs: AgentPosition) -> Int {
        abs(lhs.x - rhs.x) + abs(lhs.y - rhs.y) + abs(lhs.z - rhs.z)
    }
}
