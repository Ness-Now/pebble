import PebbleAgents
import PebbleCore

struct PebbleAgentInteractionState {
    let gateEnabled: Bool
    let active: Bool
    let actorId: String?
    let target: AgentPosition?
    let resourceBlockName: String
    let originalBlock: Int?
    let harvested: Bool
    let setupMode: String
    let configuredDistance: Int?
    let actualDistance: Int?
    let rollbackCount: Int
    let lastRollback: String
    let autoEnabled: Bool
    let autoReason: String
}

struct PebbleAgentInteractionExecutor {
    static let sandboxRadius = 8
    static let resourceBlockName = "amethyst_block"

    enum ExecutionError: Error, CustomStringConvertible {
        case sandboxAlreadyActive
        case noSafeAdjacentTarget
        case noSafeDistantTarget(Int)
        case invalidSetupDistance(Int)
        case outsideSandbox
        case nonAdjacentTarget
        case chunkUnavailable
        case unexpectedBlock
        case occupiedTarget
        case mutationVerificationFailed
        case rollbackVerificationFailed
        case noSandbox
        case alreadyHarvested

        var description: String {
            switch self {
            case .sandboxAlreadyActive: return "interaction sandbox already active"
            case .noSafeAdjacentTarget: return "no safe adjacent sandbox target"
            case let .noSafeDistantTarget(distance): return "no safe sandbox target at distance \(distance)"
            case let .invalidSetupDistance(distance): return "invalid distant setup distance \(distance); expected 2...8"
            case .outsideSandbox: return "interaction target outside sandbox"
            case .nonAdjacentTarget: return "interaction target is not cardinal-adjacent"
            case .chunkUnavailable: return "interaction target chunk unavailable"
            case .unexpectedBlock: return "interaction target block changed unexpectedly"
            case .occupiedTarget: return "interaction target occupied"
            case .mutationVerificationFailed: return "World mutation verification failed"
            case .rollbackVerificationFailed: return "World rollback verification failed"
            case .noSandbox: return "interaction sandbox inactive"
            case .alreadyHarvested: return "interaction target already harvested"
            }
        }
    }

    private struct Ledger {
        let actorId: String
        let target: AgentPosition
        let originalBlock: Int
        let resourceBlock: Int
        let configuredDistance: Int
        let actorPosition: AgentPosition
        var harvested: Bool
    }

    private var ledger: Ledger?
    private(set) var rollbackCount = 0
    private(set) var lastRollback = "none"

    func state(
        gateEnabled: Bool,
        autoEnabled: Bool = false,
        autoReason: String = "none"
    ) -> PebbleAgentInteractionState {
        PebbleAgentInteractionState(
            gateEnabled: gateEnabled,
            active: ledger != nil,
            actorId: ledger?.actorId,
            target: ledger?.target,
            resourceBlockName: Self.resourceBlockName,
            originalBlock: ledger?.originalBlock,
            harvested: ledger?.harvested ?? false,
            setupMode: (ledger?.configuredDistance ?? 1) == 1 ? "adjacent" : "distant",
            configuredDistance: ledger?.configuredDistance,
            actualDistance: ledger.map { horizontalDistance($0.target, $0.actorPosition) },
            rollbackCount: rollbackCount,
            lastRollback: lastRollback,
            autoEnabled: autoEnabled,
            autoReason: autoReason
        )
    }

    func resourceObservation(
        world: World,
        agent: AgentSnapshot,
        anchor: AgentPosition,
        maximumDistance: Int = 1
    ) throws -> AgentResourceObservation? {
        guard let ledger, !ledger.harvested, ledger.actorId == agent.id else { return nil }
        guard isInsideSandbox(ledger.target, anchor: anchor) else {
            throw ExecutionError.outsideSandbox
        }
        let distance = horizontalDistance(ledger.target, agent.position)
        guard ledger.target.y == agent.position.y,
              (1...maximumDistance).contains(distance) else {
            throw ExecutionError.nonAdjacentTarget
        }
        guard world.isChunkReady(ledger.target.x >> 4, ledger.target.z >> 4) else {
            throw ExecutionError.chunkUnavailable
        }
        guard world.getBlock(ledger.target.x, ledger.target.y, ledger.target.z) == ledger.resourceBlock else {
            throw ExecutionError.unexpectedBlock
        }
        guard let direction = AgentResourcePerception.direction(
            observerPosition: agent.position,
            target: ledger.target
        ) else {
            throw ExecutionError.nonAdjacentTarget
        }
        return AgentResourceObservation(
            resource: .sandboxResource,
            target: ledger.target,
            direction: direction,
            distanceManhattan: distance,
            quantityAvailable: 1,
            source: .sandboxFixture
        )
    }

    mutating func setup(
        world: World,
        actor: AgentSnapshot,
        anchor: AgentPosition,
        occupiedAgentPositions: [AgentPosition],
        playerPosition: AgentPosition,
        distance: Int = 1
    ) throws -> AgentPosition {
        guard ledger == nil else { throw ExecutionError.sandboxAlreadyActive }
        guard distance == 1 || (2...Self.sandboxRadius).contains(distance) else {
            throw ExecutionError.invalidSetupDistance(distance)
        }
        let resourceBlock = Int(cell(B.amethyst_block))
        for direction in AgentCardinalDirection.allCases {
            let target = AgentPosition(
                x: actor.position.x + direction.dx * distance,
                y: actor.position.y,
                z: actor.position.z + direction.dz * distance
            )
            guard isInsideSandbox(target, anchor: anchor),
                  horizontalDistance(target, actor.position) == distance,
                  world.isChunkReady(target.x >> 4, target.z >> 4),
                  !occupiedAgentPositions.contains(target),
                  playerPosition != target,
                  corridorIsClear(
                      world: world,
                      actor: actor.position,
                      direction: direction,
                      distance: distance,
                      occupiedAgentPositions: occupiedAgentPositions,
                      playerPosition: playerPosition
                  ) else { continue }
            let original = world.getBlock(target.x, target.y, target.z)
            let originalId = original >> 4
            let below = world.getBlock(target.x, target.y - 1, target.z)
            let head = world.getBlock(target.x, target.y + 1, target.z)
            guard blockDefs[originalId].replaceable,
                  blockDefs[below >> 4].solid,
                  isAir(UInt16(truncatingIfNeeded: head)) else { continue }

            let returnedOriginal = world.setBlock(target.x, target.y, target.z, resourceBlock)
            guard returnedOriginal == original,
                  world.getBlock(target.x, target.y, target.z) == resourceBlock else {
                _ = world.setBlock(target.x, target.y, target.z, original)
                guard world.getBlock(target.x, target.y, target.z) == original else {
                    throw ExecutionError.rollbackVerificationFailed
                }
                rollbackCount += 1
                lastRollback = "setup restored original block"
                throw ExecutionError.mutationVerificationFailed
            }
            ledger = Ledger(
                actorId: actor.id,
                target: target,
                originalBlock: original,
                resourceBlock: resourceBlock,
                configuredDistance: distance,
                actorPosition: actor.position,
                harvested: false
            )
            return target
        }
        if distance == 1 { throw ExecutionError.noSafeAdjacentTarget }
        throw ExecutionError.noSafeDistantTarget(distance)
    }

    mutating func harvest(
        world: World,
        actor: AgentSnapshot,
        anchor: AgentPosition,
        occupiedAgentPositions: [AgentPosition],
        playerPosition: AgentPosition,
        prevalidate: () throws -> Void,
        applyAndVerify: () throws -> Void
    ) throws {
        guard var ledger else { throw ExecutionError.noSandbox }
        guard !ledger.harvested else { throw ExecutionError.alreadyHarvested }
        guard ledger.actorId == actor.id else { throw ExecutionError.occupiedTarget }
        guard isInsideSandbox(ledger.target, anchor: anchor) else { throw ExecutionError.outsideSandbox }
        guard isAdjacent(ledger.target, to: actor.position) else { throw ExecutionError.nonAdjacentTarget }
        guard world.isChunkReady(ledger.target.x >> 4, ledger.target.z >> 4) else {
            throw ExecutionError.chunkUnavailable
        }
        guard !occupiedAgentPositions.contains(ledger.target), playerPosition != ledger.target else {
            throw ExecutionError.occupiedTarget
        }
        guard world.getBlock(ledger.target.x, ledger.target.y, ledger.target.z) == ledger.resourceBlock else {
            throw ExecutionError.unexpectedBlock
        }
        try prevalidate()

        let removed = world.setBlock(ledger.target.x, ledger.target.y, ledger.target.z, 0)
        guard removed == ledger.resourceBlock,
              world.getBlock(ledger.target.x, ledger.target.y, ledger.target.z) == 0 else {
            try rollbackResource(world: world, ledger: ledger, reason: "harvest mutation verification")
            throw ExecutionError.mutationVerificationFailed
        }

        do {
            try applyAndVerify()
            ledger.harvested = true
            self.ledger = ledger
        } catch {
            try rollbackResource(world: world, ledger: ledger, reason: "session publication: \(error)")
            throw error
        }
    }

    @discardableResult
    mutating func cleanup(world: World) -> Bool {
        guard let ledger else { return true }
        guard world.isChunkReady(ledger.target.x >> 4, ledger.target.z >> 4) else {
            rollbackCount += 1
            lastRollback = "cleanup target chunk unavailable"
            return false
        }
        _ = world.setBlock(ledger.target.x, ledger.target.y, ledger.target.z, ledger.originalBlock)
        let restored = world.getBlock(ledger.target.x, ledger.target.y, ledger.target.z) == ledger.originalBlock
        if restored {
            self.ledger = nil
            lastRollback = "cleanup restored original block"
        } else {
            rollbackCount += 1
            lastRollback = "cleanup restoration failed"
        }
        return restored
    }

    private mutating func rollbackResource(world: World, ledger: Ledger, reason: String) throws {
        _ = world.setBlock(ledger.target.x, ledger.target.y, ledger.target.z, ledger.resourceBlock)
        rollbackCount += 1
        guard world.getBlock(ledger.target.x, ledger.target.y, ledger.target.z) == ledger.resourceBlock else {
            lastRollback = "failed after \(reason)"
            throw ExecutionError.rollbackVerificationFailed
        }
        lastRollback = "resource restored after \(reason)"
    }

    private func isInsideSandbox(_ target: AgentPosition, anchor: AgentPosition) -> Bool {
        AgentInteractionSandbox.contains(
            target: target,
            anchor: anchor,
            horizontalRadius: Self.sandboxRadius
        )
    }

    private func isAdjacent(_ target: AgentPosition, to actor: AgentPosition) -> Bool {
        AgentInteractionSandbox.isCardinalAdjacent(target: target, actor: actor)
    }

    private func horizontalDistance(_ lhs: AgentPosition, _ rhs: AgentPosition) -> Int {
        abs(lhs.x - rhs.x) + abs(lhs.z - rhs.z)
    }

    private func corridorIsClear(
        world: World,
        actor: AgentPosition,
        direction: AgentCardinalDirection,
        distance: Int,
        occupiedAgentPositions: [AgentPosition],
        playerPosition: AgentPosition
    ) -> Bool {
        guard distance > 1 else { return true }
        for step in 1..<distance {
            let position = AgentPosition(
                x: actor.x + direction.dx * step,
                y: actor.y,
                z: actor.z + direction.dz * step
            )
            guard world.isChunkReady(position.x >> 4, position.z >> 4),
                  !occupiedAgentPositions.contains(position),
                  playerPosition != position,
                  blockDefs[world.getBlock(position.x, position.y - 1, position.z) >> 4].solid,
                  isAir(UInt16(truncatingIfNeeded: world.getBlock(position.x, position.y, position.z))),
                  isAir(UInt16(truncatingIfNeeded: world.getBlock(position.x, position.y + 1, position.z))) else {
                return false
            }
        }
        return true
    }
}
