import PebbleAgents
import PebbleCore

/// Read-only Pebble boundary for CIV-32 consent. It observes the two actual
/// probes and bounded World communication geometry. It never writes social
/// state and cannot create a union, lineage or house by itself.
struct PebbleAgentFamilyInteractionAdapter {
    let physicalAdapter = PebbleAgentPhysicalSignalAdapter()

    func observe(
        world: World,
        session: AgentSimulationSession,
        probesByAgentID: [String: LabCoreAgentEntity],
        receiptID: String,
        kind: AgentFamilyInteractionKind,
        actorID: AgentID,
        counterpartyID: AgentID
    ) throws -> AgentFamilyInteractionReceipt {
        guard let configuration = session.familySnapshot().configuration,
              let actorProbe = probesByAgentID[actorID.rawValue],
              let counterpartyProbe = probesByAgentID[counterpartyID.rawValue],
              actorProbe.world === world, counterpartyProbe.world === world,
              !actorProbe.dead, !counterpartyProbe.dead,
              actorProbe.labAgentId == actorID.rawValue,
              counterpartyProbe.labAgentId == counterpartyID.rawValue else {
            throw PebbleAgentController.ControllerError.familyBoundary(
                "missing, dead, stale, or mismatched family probe"
            )
        }
        let actorPosition = AgentPosition(
            x: Int(actorProbe.x.rounded(.down)),
            y: Int(actorProbe.y.rounded(.down)),
            z: Int(actorProbe.z.rounded(.down))
        )
        let counterpartyPosition = AgentPosition(
            x: Int(counterpartyProbe.x.rounded(.down)),
            y: Int(counterpartyProbe.y.rounded(.down)),
            z: Int(counterpartyProbe.z.rounded(.down))
        )
        let sessionAgents = Dictionary(uniqueKeysWithValues:
            session.snapshot().agents.compactMap { snapshot in
                AgentID(rawValue: snapshot.id).map { ($0, snapshot.position) }
            }
        )
        guard sessionAgents[actorID] == actorPosition,
              sessionAgents[counterpartyID] == counterpartyPosition else {
            throw PebbleAgentController.ControllerError.familyBoundary(
                "probe/session position mismatch"
            )
        }
        let evidence = physicalAdapter.evidence(
            world: world, from: actorPosition, to: counterpartyPosition,
            configuration: .live
        )
        guard evidence.chunksReady,
              evidence.distanceManhattan <= configuration.maximumInteractionDistance,
              evidence.lineOfSight || evidence.soundClarity > 0 else {
            throw PebbleAgentController.ControllerError.familyBoundary(
                "family communication not physically verified"
            )
        }
        return AgentFamilyInteractionReceipt(
            receiptID: receiptID, kind: kind,
            actorID: actorID, counterpartyID: counterpartyID,
            observedTick: session.tick,
            actorPosition: actorPosition,
            counterpartyPosition: counterpartyPosition,
            communicationVerified: true
        )
    }
}
