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
        identity: AgentResourceIdentity,
        occupiedAgentPositions: [AgentPosition],
        playerPosition: AgentPosition,
        naturalGateEnabled: Bool,
        interactionGateEnabled: Bool,
        prevalidate: () throws -> Void,
        publishAndVerify: () throws -> Void
    ) throws {
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
        try prevalidate()

        let returnedOriginal = world.setBlock(
            identity.position.x,
            identity.position.y,
            identity.position.z,
            0
        )
        guard returnedOriginal == fingerprint else {
            try rollback(world: world, identity: identity, originalFingerprint: returnedOriginal)
            throw ExecutionError.unexpectedBlock
        }
        guard world.getBlock(identity.position.x, identity.position.y, identity.position.z) == 0 else {
            try rollback(world: world, identity: identity, originalFingerprint: returnedOriginal)
            throw ExecutionError.mutationVerificationFailed
        }
        do {
            try publishAndVerify()
        } catch {
            try rollback(world: world, identity: identity, originalFingerprint: returnedOriginal)
            throw error
        }

        state.lastTarget = identity
        state.lastHarvest = "\(identity.resource.rawValue)@\(positionText(identity.position))#\(fingerprint)"
        state.harvestCount += 1
    }

    mutating func resetDiagnostics() {
        state = PebbleAgentNaturalResourceState()
    }

    mutating func restoreScanDiagnostics(_ diagnostics: AgentNaturalResourceScanDiagnostics?) {
        state.lastScan = diagnostics ?? AgentNaturalResourceScanDiagnostics()
    }

    private mutating func rollback(
        world: World,
        identity: AgentResourceIdentity,
        originalFingerprint: Int
    ) throws {
        _ = world.setBlock(
            identity.position.x,
            identity.position.y,
            identity.position.z,
            originalFingerprint
        )
        guard world.getBlock(identity.position.x, identity.position.y, identity.position.z)
                == originalFingerprint else {
            state.lastRollback = "failed@\(positionText(identity.position))"
            throw ExecutionError.rollbackVerificationFailed
        }
        state.rollbackCount += 1
        state.lastRollback = "restored@\(positionText(identity.position))#\(originalFingerprint)"
    }

    private func positionText(_ position: AgentPosition) -> String {
        "\(position.x),\(position.y),\(position.z)"
    }
}
