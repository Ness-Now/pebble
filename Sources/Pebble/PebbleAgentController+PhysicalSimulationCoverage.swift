import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    /// Rebuilds technical coverage solely from the current Civilization
    /// session and its exact live physical embodiments. No result is retained
    /// as a second roster and no World scheduling operation occurs here.
    func physicalSimulationCoverageRequest(
        for world: World
    ) -> PhysicalSimulationCoverageRequest {
        guard let session else {
            let worldProbes = world.entities.compactMap {
                $0 as? LabCoreAgentEntity
            }
            guard activeWorld == nil,
                  probesByAgentId.isEmpty,
                  worldProbes.isEmpty else {
                return .refused(
                    "inactive session has live physical probe authority"
                )
            }
            return .inactive
        }
        guard activeWorld === world else {
            return .refused("active session World does not match coverage World")
        }

        let agents = session.snapshot().agents.sorted { $0.id < $1.id }
        let agentIDs = agents.map(\.id)
        guard agentIDs.count
                <= PhysicalSimulationCoverageContract.maximumRoots else {
            return .refused(
                "active population exceeds physical coverage root bound: "
                    + "\(agentIDs.count)>"
                    + "\(PhysicalSimulationCoverageContract.maximumRoots)"
            )
        }
        let worldProbes = world.entities.compactMap {
            $0 as? LabCoreAgentEntity
        }
        guard probesByAgentId.keys.sorted() == agentIDs,
              worldProbes.map(\.labAgentId).sorted() == agentIDs else {
            return .refused(
                "session, probe registry and World probe identities disagree"
            )
        }
        if agentIDs.isEmpty { return .inactive }
        guard let embodiments = try? PebbleAgentEmbodiment.resolveAll(
            agentIDs: agentIDs,
            in: world,
            mappedByAgentID: probesByAgentId
        ), embodiments.count == agentIDs.count else {
            return .refused("live physical embodiment resolution failed")
        }
        let physicalIDs = agentIDs.compactMap { embodiments[$0]?.physicalID }
        guard physicalIDs.count == agentIDs.count,
              Set(physicalIDs).count == physicalIDs.count else {
            return .refused("live physical coverage identity is not unique")
        }
        guard agents.allSatisfy({ agent in
            embodiments[agent.id]?.position == agent.position
        }) else {
            return .refused(
                "session and live physical positions disagree at coverage boundary"
            )
        }

        return .active(agentIDs.compactMap { agentID in
            guard let embodiment = embodiments[agentID] else { return nil }
            return PhysicalSimulationCoverageRoot(
                id: embodiment.physicalID,
                chunkX: floorDiv(embodiment.position.x, CHUNK_W),
                chunkZ: floorDiv(embodiment.position.z, CHUNK_W)
            )
        })
    }
}
