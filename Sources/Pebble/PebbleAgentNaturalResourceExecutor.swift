import PebbleAgents
import PebbleCore

struct PebbleAgentNaturalResourceState {
    var lastScan = AgentNaturalResourceScanDiagnostics()
    var lastTarget: AgentResourceIdentity?
    var lastHarvest = "none"
    var lastRollback = "none"
    var harvestCount = 0
    var rollbackCount = 0
}

struct PebbleAgentNaturalHarvestResult {
    let physical: PebbleAgentPhysicalActionOutcome
    let acquisition: PebbleAgentItemEntityAcquisitionOutcome
    let toolSlot: Int?
}

struct PebbleAgentNaturalResourceExecutor {
    enum ExecutionError: Error, Equatable, CustomStringConvertible {
        case gateDisabled
        case invalidSource
        case invalidResource
        case missingFingerprint
        case nonAdjacentTarget
        case chunkUnavailable
        case occupiedTarget
        case unexpectedBlock
        case mappingMismatch
        case missingPhysicalActor
        case noCanonicalDrops
        case custodyFailure(PebbleAgentMaterialTransactionStatus)
        case physicalFailure(PebbleAgentPhysicalActionStatus)
        case mutationVerificationFailed
        case rollbackVerificationFailed

        var description: String {
            switch self {
            case .gateDisabled: return "natural harvest gate disabled"
            case .invalidSource: return "natural harvest received a non-natural target"
            case .invalidResource: return "natural harvest supports only wood and stone"
            case .missingFingerprint: return "natural target fingerprint missing"
            case .nonAdjacentTarget: return "natural target is not cardinal-adjacent"
            case .chunkUnavailable: return "natural target chunk unavailable"
            case .occupiedTarget: return "natural target occupied"
            case .unexpectedBlock: return "natural target block changed"
            case .mappingMismatch: return "natural target mapping changed"
            case .missingPhysicalActor: return "natural harvest physical actor mismatch"
            case .noCanonicalDrops: return "natural harvest produced no canonical drops"
            case let .custodyFailure(status): return "natural harvest custody failed: \(status.rawValue)"
            case let .physicalFailure(status): return "natural harvest physical action failed: \(status.rawValue)"
            case .mutationVerificationFailed: return "natural World mutation verification failed"
            case .rollbackVerificationFailed: return "natural World rollback verification failed"
            }
        }
    }

    private(set) var state = PebbleAgentNaturalResourceState()

    mutating func recordScan(_ result: AgentNaturalResourceScanResult) {
        state.lastScan = result.diagnostics
        state.lastTarget = result.observations.first?.identity
    }

    mutating func harvest(
        world: World,
        actor: AgentSnapshot,
        physicalActor: LabCoreAgentEntity,
        identity: AgentResourceIdentity,
        transactionID: String,
        occupiedAgentPositions: [AgentPosition],
        playerPosition: AgentPosition,
        naturalGateEnabled: Bool,
        interactionGateEnabled: Bool,
        physicalGateway: PebbleAgentPhysicalActionGateway,
        custodyGateway: PebbleAgentMaterialCustodyGateway,
        prevalidate: () throws -> Void,
        publishAndVerify: (PebbleAgentItemEntityAcquisitionOutcome) throws -> Bool
    ) throws -> PebbleAgentNaturalHarvestResult {
        guard naturalGateEnabled, interactionGateEnabled else {
            throw ExecutionError.gateDisabled
        }
        guard identity.source == .naturalWorld else { throw ExecutionError.invalidSource }
        guard identity.resource == .wood || identity.resource == .stone else {
            throw ExecutionError.invalidResource
        }
        guard let fingerprint = identity.expectedBlockFingerprint else {
            throw ExecutionError.missingFingerprint
        }
        let mutationBoundary = AgentNaturalResourceMutationBoundary(identity: identity)
        guard mutationBoundary.isValid,
              mutationBoundary.permittedPositions.count == 1,
              mutationBoundary.permits(identity.position) else {
            throw ExecutionError.invalidSource
        }
        guard AgentInteractionSandbox.isCardinalAdjacent(
            target: identity.position,
            actor: actor.position
        ) else {
            throw ExecutionError.nonAdjacentTarget
        }
        guard world.isChunkReady(identity.position.x >> 4, identity.position.z >> 4) else {
            throw ExecutionError.chunkUnavailable
        }
        guard !occupiedAgentPositions.contains(identity.position),
              playerPosition != identity.position else {
            throw ExecutionError.occupiedTarget
        }
        guard world.getBlock(identity.position.x, identity.position.y, identity.position.z)
                == fingerprint else {
            throw ExecutionError.unexpectedBlock
        }
        guard PebbleAgentNaturalResourceMapping.resource(for: fingerprint) == identity.resource else {
            throw ExecutionError.mappingMismatch
        }
        guard physicalActor.world === world,
              physicalActor.labAgentId == actor.id,
              !physicalActor.dead else {
            throw ExecutionError.missingPhysicalActor
        }
        try prevalidate()

        let destination = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            physicalActor,
            in: world
        )
        guard destination.isValid else { throw ExecutionError.missingPhysicalActor }
        let tool = custodyGateway.harvestToolBinding(
            actor: physicalActor,
            targetCell: fingerprint,
            world: world
        )
        let occupied = occupiedAgentPositions.map {
            PhysicalBlockPosition(x: $0.x, y: $0.y, z: $0.z)
        } + [PhysicalBlockPosition(
            x: playerPosition.x,
            y: playerPosition.y,
            z: playerPosition.z
        )]
        var acquisition: PebbleAgentItemEntityAcquisitionOutcome?
        var publicationError: Error?
        let physical = physicalGateway.breakBlock(
            world: world,
            actor: physicalActor,
            request: PebbleAgentBlockBreakRequest(
                actorID: actor.id,
                target: PhysicalBlockPosition(
                    x: identity.position.x,
                    y: identity.position.y,
                    z: identity.position.z
                ),
                expectedCell: fingerprint,
                heldItem: tool?.heldItem,
                isCreative: false
            ),
            toolState: tool?.toolState ?? .none,
            occupiedPositions: occupied,
            acquireDrops: { entityIDs in
                guard let source = PebbleAgentItemEntityCustodyEndpoint(
                    spawnedItemEntityIDs: entityIDs,
                    world: world
                ) else { return false }
                let destinationFingerprint: String
                do {
                    destinationFingerprint = try custodyGateway.fingerprint(destination)
                } catch {
                    publicationError = error
                    return false
                }
                let result = custodyGateway.acquireItemEntities(
                    PebbleAgentItemEntityAcquisitionRequest(
                        transactionID: transactionID,
                        spawnedItemEntityIDs: entityIDs,
                        expectedDestinationFingerprint: destinationFingerprint
                    ),
                    from: source,
                    to: destination,
                    verifyAfterMutation: { acquired in
                        do {
                            return try publishAndVerify(acquired)
                        } catch {
                            publicationError = error
                            return false
                        }
                    }
                )
                acquisition = result
                return result.succeeded
            }
        )
        guard physical.succeeded else {
            if physical.status == .rollbackFailure {
                throw ExecutionError.rollbackVerificationFailed
            }
            if let publicationError { throw publicationError }
            if let acquisition {
                throw ExecutionError.custodyFailure(acquisition.status)
            }
            if physical.status == .verificationFailure,
               physical.failure == .postMutationRejected {
                throw ExecutionError.noCanonicalDrops
            }
            throw ExecutionError.physicalFailure(physical.status)
        }
        guard let acquisition, acquisition.succeeded,
              acquisition.acquired.map(\.entityID) == physical.spawnedItemEntityIDs,
              !acquisition.acquired.isEmpty else {
            throw ExecutionError.mutationVerificationFailed
        }

        state.lastTarget = identity
        let drops = acquisition.acquired.map {
            "\($0.material.identity.itemKey)x\($0.material.count)"
        }.joined(separator: ",")
        state.lastHarvest = "\(identity.resource.rawValue)@\(positionText(identity.position))#\(fingerprint)->\(drops)"
        state.harvestCount += 1
        return PebbleAgentNaturalHarvestResult(
            physical: physical,
            acquisition: acquisition,
            toolSlot: tool?.slot
        )
    }

    mutating func resetDiagnostics() {
        state = PebbleAgentNaturalResourceState()
    }

    mutating func restoreScanDiagnostics(_ diagnostics: AgentNaturalResourceScanDiagnostics?) {
        state.lastScan = diagnostics ?? AgentNaturalResourceScanDiagnostics()
    }

    private func positionText(_ position: AgentPosition) -> String {
        "\(position.x),\(position.y),\(position.z)"
    }
}
