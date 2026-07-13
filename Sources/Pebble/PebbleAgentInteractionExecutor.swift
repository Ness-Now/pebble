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
    let corridorObservedBlockCount: Int
    let corridorChangedAfterSetup: Int
    let corridorChangedDuringNavigation: Int
    let corridorChangedAfterHarvest: Int
    let corridorChangedAfterCleanup: Int
    let setupMutatedBlockCount: Int
    let cleanupRestoredBlockCount: Int
}

struct PebbleAgentFixtureState {
    let fixtureId: String
    let actorId: String
    let target: AgentPosition
    let resource: AgentResourceKind
    let resourceBlockName: String
    let originalBlock: Int
    let harvested: Bool
}

struct PebbleAgentEconomyFixtureState {
    let fixtures: [PebbleAgentFixtureState]
    let corridorObservedBlockCount: Int
    let corridorChangedAfterSetup: Int
    let corridorChangedDuringNavigation: Int
    let corridorChangedAfterHarvest: Int
    let corridorChangedAfterCleanup: Int
    let setupMutatedBlockCount: Int
    let cleanupRestoredBlockCount: Int
    let rollbackCount: Int
    let lastRollback: String
}

struct PebbleAgentInteractionExecutor {
    static let sandboxRadius = 8
    static let resourceBlockName = "amethyst_block"
    static let maximumFixtureCount = 3

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
        case invalidFixtureSet

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
            case .invalidFixtureSet: return "invalid economy fixture set"
            }
        }
    }

    private struct Ledger {
        let fixtureId: String
        let actorId: String
        let target: AgentPosition
        let resource: AgentResourceKind
        let resourceBlockName: String
        let originalBlock: Int
        let resourceBlock: Int
        let configuredDistance: Int
        let actorPosition: AgentPosition
        var harvested: Bool
    }

    private struct BoundarySample {
        let position: AgentPosition
        let block: Int
    }

    private struct BoundaryAudit {
        let samples: [BoundarySample]
        var changedAfterSetup = 0
        var changedDuringNavigation = 0
        var changedAfterHarvest = 0
        var changedAfterCleanup = 0
        var setupMutatedBlockCount = 0
        var cleanupRestoredBlockCount = 0
    }

    private var ledgers: [Ledger] = []
    private var boundaryAudit: BoundaryAudit?
    private(set) var rollbackCount = 0
    private(set) var lastRollback = "none"

    mutating func clearBoundaryAudit() {
        boundaryAudit = nil
    }

    func state(
        gateEnabled: Bool,
        autoEnabled: Bool = false,
        autoReason: String = "none"
    ) -> PebbleAgentInteractionState {
        let ledger = ledgers.first
        return PebbleAgentInteractionState(
            gateEnabled: gateEnabled,
            active: ledger != nil,
            actorId: ledger?.actorId,
            target: ledger?.target,
            resourceBlockName: ledger?.resourceBlockName ?? Self.resourceBlockName,
            originalBlock: ledger?.originalBlock,
            harvested: ledger?.harvested ?? false,
            setupMode: (ledger?.configuredDistance ?? 1) == 1 ? "adjacent" : "distant",
            configuredDistance: ledger?.configuredDistance,
            actualDistance: ledger.map { horizontalDistance($0.target, $0.actorPosition) },
            rollbackCount: rollbackCount,
            lastRollback: lastRollback,
            autoEnabled: autoEnabled,
            autoReason: autoReason,
            corridorObservedBlockCount: boundaryAudit?.samples.count ?? 0,
            corridorChangedAfterSetup: boundaryAudit?.changedAfterSetup ?? 0,
            corridorChangedDuringNavigation: boundaryAudit?.changedDuringNavigation ?? 0,
            corridorChangedAfterHarvest: boundaryAudit?.changedAfterHarvest ?? 0,
            corridorChangedAfterCleanup: boundaryAudit?.changedAfterCleanup ?? 0,
            setupMutatedBlockCount: boundaryAudit?.setupMutatedBlockCount ?? 0,
            cleanupRestoredBlockCount: boundaryAudit?.cleanupRestoredBlockCount ?? 0
        )
    }

    func economyState() -> PebbleAgentEconomyFixtureState {
        PebbleAgentEconomyFixtureState(
            fixtures: ledgers.map {
                PebbleAgentFixtureState(
                    fixtureId: $0.fixtureId,
                    actorId: $0.actorId,
                    target: $0.target,
                    resource: $0.resource,
                    resourceBlockName: $0.resourceBlockName,
                    originalBlock: $0.originalBlock,
                    harvested: $0.harvested
                )
            },
            corridorObservedBlockCount: boundaryAudit?.samples.count ?? 0,
            corridorChangedAfterSetup: boundaryAudit?.changedAfterSetup ?? 0,
            corridorChangedDuringNavigation: boundaryAudit?.changedDuringNavigation ?? 0,
            corridorChangedAfterHarvest: boundaryAudit?.changedAfterHarvest ?? 0,
            corridorChangedAfterCleanup: boundaryAudit?.changedAfterCleanup ?? 0,
            setupMutatedBlockCount: boundaryAudit?.setupMutatedBlockCount ?? 0,
            cleanupRestoredBlockCount: boundaryAudit?.cleanupRestoredBlockCount ?? 0,
            rollbackCount: rollbackCount,
            lastRollback: lastRollback
        )
    }

    func fixture(target: AgentPosition, resource: AgentResourceKind) -> PebbleAgentFixtureState? {
        economyState().fixtures.first { $0.target == target && $0.resource == resource }
    }

    mutating func resourceObservation(
        world: World,
        agent: AgentSnapshot,
        anchor: AgentPosition,
        maximumDistance: Int = 1
    ) throws -> AgentResourceObservation? {
        try resourceObservations(
            world: world,
            agent: agent,
            anchor: anchor,
            maximumDistance: maximumDistance
        ).first
    }

    mutating func resourceObservations(
        world: World,
        agent: AgentSnapshot,
        anchor: AgentPosition,
        maximumDistance: Int = 1
    ) throws -> [AgentResourceObservation] {
        recordBoundaryCheck(world: world, phase: .navigation)
        var observations: [AgentResourceObservation] = []
        for ledger in ledgers where !ledger.harvested && ledger.actorId == agent.id {
            guard isInsideSandbox(ledger.target, anchor: anchor) else {
                throw ExecutionError.outsideSandbox
            }
            let distance = horizontalDistance(ledger.target, agent.position)
            guard ledger.target.y == agent.position.y,
                  (1...maximumDistance).contains(distance) else { continue }
            guard world.isChunkReady(ledger.target.x >> 4, ledger.target.z >> 4) else {
                throw ExecutionError.chunkUnavailable
            }
            guard world.getBlock(ledger.target.x, ledger.target.y, ledger.target.z)
                    == ledger.resourceBlock else { continue }
            guard let direction = AgentResourcePerception.direction(
                observerPosition: agent.position,
                target: ledger.target
            ) else { continue }
            observations.append(AgentResourceObservation(
                resource: ledger.resource,
                target: ledger.target,
                direction: direction,
                distanceManhattan: distance,
                quantityAvailable: 1,
                source: .sandboxFixture
            ))
        }
        return observations
    }

    mutating func setup(
        world: World,
        actor: AgentSnapshot,
        anchor: AgentPosition,
        occupiedAgentPositions: [AgentPosition],
        playerPosition: AgentPosition,
        distance: Int = 1,
        routeToTarget: (AgentPosition) -> AgentNavigationPlan
    ) throws -> AgentPosition {
        guard ledgers.isEmpty else { throw ExecutionError.sandboxAlreadyActive }
        guard distance == 1 || (2...Self.sandboxRadius).contains(distance) else {
            throw ExecutionError.invalidSetupDistance(distance)
        }
        let resourceBlock = Int(cell(B.amethyst_block))
        boundaryAudit = BoundaryAudit(samples: [])
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
                  playerPosition != target else { continue }
            let original = world.getBlock(target.x, target.y, target.z)
            let below = world.getBlock(target.x, target.y - 1, target.z)
            let head = world.getBlock(target.x, target.y + 1, target.z)
            guard blockDefs[original >> 4].replaceable,
                  blockDefs[below >> 4].solid,
                  isAir(UInt16(truncatingIfNeeded: head)) else { continue }

            let plan: AgentNavigationPlan
            if distance == 1 {
                plan = AgentNavigationPlan(
                    positions: [actor.position],
                    visitedNodeCount: 1,
                    failure: nil
                )
            } else {
                plan = routeToTarget(target)
                guard plan.found,
                      plan.positions.first == actor.position,
                      plan.positions.last.map({ isAdjacent(target, to: $0) }) == true else {
                    continue
                }
            }
            boundaryAudit = BoundaryAudit(samples: corridorSamples(
                world: world,
                routePositions: Array(plan.positions.dropFirst())
            ))

            let mutationBoundary = AgentSandboxFixtureMutationBoundary(target: target)
            guard mutationBoundary.permittedPositions.count == 1,
                  mutationBoundary.permits(target) else {
                throw ExecutionError.mutationVerificationFailed
            }
            let returnedOriginal = world.setBlock(target.x, target.y, target.z, resourceBlock)
            boundaryAudit?.setupMutatedBlockCount = 1
            guard returnedOriginal == original,
                  world.getBlock(target.x, target.y, target.z) == resourceBlock else {
                _ = world.setBlock(target.x, target.y, target.z, original)
                guard world.getBlock(target.x, target.y, target.z) == original else {
                    throw ExecutionError.rollbackVerificationFailed
                }
                rollbackCount += 1
                lastRollback = "setup restored fixture block"
                throw ExecutionError.mutationVerificationFailed
            }
            recordBoundaryCheck(world: world, phase: .setup)
            ledgers = [Ledger(
                fixtureId: "legacy:sandboxResource:0",
                actorId: actor.id,
                target: target,
                resource: .sandboxResource,
                resourceBlockName: Self.resourceBlockName,
                originalBlock: original,
                resourceBlock: resourceBlock,
                configuredDistance: distance,
                actorPosition: actor.position,
                harvested: false
            )]
            return target
        }
        if distance == 1 { throw ExecutionError.noSafeAdjacentTarget }
        throw ExecutionError.noSafeDistantTarget(distance)
    }

    mutating func setupEconomy(
        world: World,
        actor: AgentSnapshot,
        anchor: AgentPosition,
        occupiedAgentPositions: [AgentPosition],
        playerPosition: AgentPosition,
        routeToTarget: (AgentPosition) -> AgentNavigationPlan
    ) throws -> [PebbleAgentFixtureState] {
        guard ledgers.isEmpty else { throw ExecutionError.sandboxAlreadyActive }
        let distances = [4, 3, 2, 5, 6, 7, 8]
        var selected: [(ledger: Ledger, route: [AgentPosition])] = []

        for (index, resource) in AgentResourceKind.economyFixtureOrder.enumerated() {
            let visual = resourceBlock(for: resource)
            var selectedFixture: (Ledger, [AgentPosition])?
            for distance in distances where selectedFixture == nil {
                for offset in candidateOffsets(distance: distance) where selectedFixture == nil {
                    let target = AgentPosition(
                        x: actor.position.x + offset.dx,
                        y: actor.position.y,
                        z: actor.position.z + offset.dz
                    )
                    guard isInsideSandbox(target, anchor: anchor),
                          world.isChunkReady(target.x >> 4, target.z >> 4),
                          !occupiedAgentPositions.contains(target),
                          playerPosition != target,
                          !selected.contains(where: { $0.ledger.target == target }),
                          !selected.contains(where: { $0.route.contains(target) }) else { continue }
                    let original = world.getBlock(target.x, target.y, target.z)
                    let below = world.getBlock(target.x, target.y - 1, target.z)
                    let head = world.getBlock(target.x, target.y + 1, target.z)
                    guard blockDefs[original >> 4].replaceable,
                          blockDefs[below >> 4].solid,
                          isAir(UInt16(truncatingIfNeeded: head)) else { continue }
                    let plan = routeToTarget(target)
                    guard plan.found,
                          plan.positions.first == actor.position,
                          plan.positions.last.map({ isAdjacent(target, to: $0) }) == true,
                          selected.allSatisfy({ !plan.positions.contains($0.ledger.target) }) else {
                        continue
                    }
                    selectedFixture = (Ledger(
                        fixtureId: "economy:\(resource.rawValue):\(index)",
                        actorId: actor.id,
                        target: target,
                        resource: resource,
                        resourceBlockName: visual.name,
                        originalBlock: original,
                        resourceBlock: visual.block,
                        configuredDistance: distance,
                        actorPosition: actor.position,
                        harvested: false
                    ), plan.positions)
                }
            }
            guard let selectedFixture else { throw ExecutionError.invalidFixtureSet }
            selected.append(selectedFixture)
        }
        guard selected.count == Self.maximumFixtureCount else {
            throw ExecutionError.invalidFixtureSet
        }
        let mutationBoundary = AgentSandboxFixtureSetMutationBoundary(
            targets: selected.map { $0.ledger.target }
        )
        guard mutationBoundary.isValid,
              selected.allSatisfy({ mutationBoundary.permits($0.ledger.target) }) else {
            throw ExecutionError.invalidFixtureSet
        }

        let samples = selected.flatMap { corridorSamples(
            world: world,
            routePositions: Array($0.route.dropFirst())
        ) }.reduce(into: [BoundarySample]()) { unique, sample in
            if !unique.contains(where: { $0.position == sample.position }) { unique.append(sample) }
        }
        boundaryAudit = BoundaryAudit(samples: samples)
        var mutated: [Ledger] = []
        for entry in selected {
            let ledger = entry.ledger
            guard mutationBoundary.permits(ledger.target) else {
                guard rollbackFixtureSetup(world: world, ledgers: mutated) else {
                    throw ExecutionError.rollbackVerificationFailed
                }
                throw ExecutionError.mutationVerificationFailed
            }
            let returnedOriginal = world.setBlock(
                ledger.target.x,
                ledger.target.y,
                ledger.target.z,
                ledger.resourceBlock
            )
            mutated.append(ledger)
            boundaryAudit?.setupMutatedBlockCount = mutated.count
            guard returnedOriginal == ledger.originalBlock,
                  world.getBlock(ledger.target.x, ledger.target.y, ledger.target.z)
                    == ledger.resourceBlock else {
                guard rollbackFixtureSetup(world: world, ledgers: mutated) else {
                    throw ExecutionError.rollbackVerificationFailed
                }
                throw ExecutionError.mutationVerificationFailed
            }
        }
        ledgers = selected.map(\.ledger)
        recordBoundaryCheck(world: world, phase: .setup)
        return economyState().fixtures
    }

    mutating func harvest(
        world: World,
        actor: AgentSnapshot,
        anchor: AgentPosition,
        occupiedAgentPositions: [AgentPosition],
        playerPosition: AgentPosition,
        expectedTarget: AgentPosition? = nil,
        expectedResource: AgentResourceKind? = nil,
        prevalidate: () throws -> Void,
        applyAndVerify: () throws -> Void
    ) throws {
        guard let ledgerIndex = ledgers.firstIndex(where: {
            (expectedTarget == nil || $0.target == expectedTarget)
                && (expectedResource == nil || $0.resource == expectedResource)
        }) else { throw ExecutionError.noSandbox }
        var ledger = ledgers[ledgerIndex]
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
        guard AgentSandboxFixtureMutationBoundary(target: ledger.target).permits(ledger.target) else {
            throw ExecutionError.mutationVerificationFailed
        }
        recordBoundaryCheck(world: world, phase: .navigation)
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
            ledgers[ledgerIndex] = ledger
            recordBoundaryCheck(world: world, phase: .harvest)
        } catch {
            try rollbackResource(world: world, ledger: ledger, reason: "session publication: \(error)")
            throw error
        }
    }

    @discardableResult
    mutating func cleanup(world: World) -> Bool {
        guard !ledgers.isEmpty else { return true }
        for ledger in ledgers {
            guard world.isChunkReady(ledger.target.x >> 4, ledger.target.z >> 4) else {
                rollbackCount += 1
                lastRollback = "cleanup target chunk unavailable"
                return false
            }
            guard AgentSandboxFixtureMutationBoundary(target: ledger.target).permits(ledger.target) else {
                rollbackCount += 1
                lastRollback = "cleanup mutation boundary rejected"
                return false
            }
        }
        let priorBlocks = ledgers.map { ledger in
            world.getBlock(ledger.target.x, ledger.target.y, ledger.target.z)
        }
        for ledger in ledgers {
            _ = world.setBlock(ledger.target.x, ledger.target.y, ledger.target.z, ledger.originalBlock)
        }
        boundaryAudit?.cleanupRestoredBlockCount = ledgers.count
        let restored = ledgers.allSatisfy { ledger in
            world.getBlock(ledger.target.x, ledger.target.y, ledger.target.z) == ledger.originalBlock
        }
        recordBoundaryCheck(world: world, phase: .cleanup)
        if restored {
            let count = ledgers.count
            ledgers.removeAll()
            lastRollback = "cleanup restored \(count) fixture block(s)"
            return true
        } else {
            rollbackCount += 1
            for (index, ledger) in ledgers.enumerated() {
                _ = world.setBlock(
                    ledger.target.x,
                    ledger.target.y,
                    ledger.target.z,
                    priorBlocks[index]
                )
            }
            let rollbackVerified = ledgers.enumerated().allSatisfy { index, ledger in
                world.getBlock(ledger.target.x, ledger.target.y, ledger.target.z) == priorBlocks[index]
            }
            lastRollback = rollbackVerified
                ? "cleanup restoration failed; pre-cleanup blocks restored"
                : "cleanup restoration and rollback failed"
            return false
        }
    }

    private mutating func rollbackResource(world: World, ledger: Ledger, reason: String) throws {
        guard AgentSandboxFixtureMutationBoundary(target: ledger.target).permits(ledger.target) else {
            throw ExecutionError.rollbackVerificationFailed
        }
        _ = world.setBlock(ledger.target.x, ledger.target.y, ledger.target.z, ledger.resourceBlock)
        rollbackCount += 1
        guard world.getBlock(ledger.target.x, ledger.target.y, ledger.target.z) == ledger.resourceBlock else {
            lastRollback = "failed after \(reason)"
            throw ExecutionError.rollbackVerificationFailed
        }
        lastRollback = "resource restored after \(reason)"
    }

    private mutating func rollbackFixtureSetup(world: World, ledgers: [Ledger]) -> Bool {
        for ledger in ledgers.reversed() {
            _ = world.setBlock(ledger.target.x, ledger.target.y, ledger.target.z, ledger.originalBlock)
        }
        let verified = ledgers.allSatisfy { ledger in
            world.getBlock(ledger.target.x, ledger.target.y, ledger.target.z) == ledger.originalBlock
        }
        rollbackCount += ledgers.isEmpty ? 0 : 1
        lastRollback = verified
            ? "setup restored \(ledgers.count) fixture block(s)"
            : "setup fixture rollback failed"
        return verified
    }

    private func resourceBlock(for resource: AgentResourceKind) -> (name: String, block: Int) {
        switch resource {
        case .sandboxResource: return (Self.resourceBlockName, Int(cell(B.amethyst_block)))
        case .foodRaw: return ("hay_block", Int(cell(B.hay_block)))
        case .wood: return ("oak_log", Int(cell(B.oak_log)))
        case .stone: return ("cobblestone", Int(cell(B.cobblestone)))
        }
    }

    private func candidateOffsets(distance: Int) -> [(dx: Int, dz: Int)] {
        var offsets = AgentCardinalDirection.allCases.map {
            (dx: $0.dx * distance, dz: $0.dz * distance)
        }
        for dx in -distance...distance {
            let dzMagnitude = distance - abs(dx)
            let candidates = dzMagnitude == 0
                ? [(dx: dx, dz: 0)]
                : [(dx: dx, dz: -dzMagnitude), (dx: dx, dz: dzMagnitude)]
            for candidate in candidates where !offsets.contains(where: {
                $0.dx == candidate.dx && $0.dz == candidate.dz
            }) {
                offsets.append(candidate)
            }
        }
        return offsets
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

    private enum BoundaryPhase {
        case setup
        case navigation
        case harvest
        case cleanup
    }

    private func corridorSamples(
        world: World,
        routePositions: [AgentPosition]
    ) -> [BoundarySample] {
        var samples: [BoundarySample] = []
        for position in routePositions {
            for y in (position.y - 1)...(position.y + 1) {
                let samplePosition = AgentPosition(x: position.x, y: y, z: position.z)
                samples.append(BoundarySample(
                    position: samplePosition,
                    block: world.getBlock(samplePosition.x, samplePosition.y, samplePosition.z)
                ))
            }
        }
        return samples
    }

    private mutating func recordBoundaryCheck(
        world: World,
        phase: BoundaryPhase
    ) {
        guard var audit = boundaryAudit else { return }
        let changed = audit.samples.reduce(into: 0) { count, sample in
            if world.getBlock(sample.position.x, sample.position.y, sample.position.z) != sample.block {
                count += 1
            }
        }
        switch phase {
        case .setup: audit.changedAfterSetup = changed
        case .navigation: audit.changedDuringNavigation = max(audit.changedDuringNavigation, changed)
        case .harvest: audit.changedAfterHarvest = changed
        case .cleanup: audit.changedAfterCleanup = changed
        }
        boundaryAudit = audit
    }
}
