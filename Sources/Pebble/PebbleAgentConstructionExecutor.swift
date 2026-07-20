import PebbleAgents
import PebbleCore

struct PebbleAgentConstructionState {
    var projectId: String?
    var origin: AgentPosition?
    var placedCount = 0
    var lastPlacement = "none"
    var lastMaterial = "none"
    var lastPhysicalStatus = "none"
    var lastCommittedEffectCount = 0
    var lastFailure = "none"
    var rollbackCount = 0
    var cleanupRestoredBlockCount = 0
    var lastClear = "none"
}

struct PebbleAgentConstructionExecutor {
    enum ExecutionError: Error, CustomStringConvertible {
        case projectAlreadyActive
        case projectMissing
        case gateDisabled
        case autoDisabled
        case projectMismatch
        case invalidCell
        case invalidMaterial
        case missingMaterial
        case wrongMaterial
        case invalidReach
        case chunkUnavailable
        case occupied
        case staleFingerprint
        case previousCellChanged
        case mutationVerificationFailed
        case structureValidationFailed
        case rollbackVerificationFailed
        case clearVerificationFailed

        var description: String {
            switch self {
            case .projectAlreadyActive: return "construction project already active"
            case .projectMissing: return "construction project missing"
            case .gateDisabled: return "construction gate disabled"
            case .autoDisabled: return "construction auto mode disabled"
            case .projectMismatch: return "construction project mismatch"
            case .invalidCell: return "construction cell is not the ordered next cell"
            case .invalidMaterial: return "construction material mapping invalid"
            case .missingMaterial: return "construction builder has no required real material"
            case .wrongMaterial: return "construction builder custody has only incompatible material"
            case .invalidReach: return "construction target outside bounded placement reach"
            case .chunkUnavailable: return "construction target chunk unavailable"
            case .occupied: return "construction target or work position occupied"
            case .staleFingerprint: return "construction target fingerprint changed"
            case .previousCellChanged: return "previously constructed cell changed"
            case .mutationVerificationFailed: return "construction World mutation verification failed"
            case .structureValidationFailed: return "completed shelter structure validation failed"
            case .rollbackVerificationFailed: return "construction World rollback verification failed"
            case .clearVerificationFailed: return "construction clear verification failed"
            }
        }
    }

    private struct LedgerCell {
        let index: Int
        let target: AgentPosition
        let originalFingerprint: Int
        let requiredBlockID: Int
        let resource: AgentResourceKind
        var placed: Bool
        var placedFingerprint: Int?
    }

    private struct Ledger {
        let projectId: String
        let origin: AgentPosition
        let entrance: AgentPosition
        let rest: AgentPosition
        var cells: [LedgerCell]
    }

    private var ledger: Ledger?
    private(set) var state = PebbleAgentConstructionState()

    mutating func begin(project: AgentConstructionProject) throws {
        guard ledger == nil else { throw ExecutionError.projectAlreadyActive }
        let entrance = offset(project.origin, project.blueprint.entranceOffset)
        let cells = try project.blueprint.cells.map { cell -> LedgerCell in
            guard let original = project.originalFingerprint(for: cell.index),
                  let construction = PebbleAgentConstructionMapping.fingerprint(
                      for: cell.resource
                  ) else {
                throw ExecutionError.invalidMaterial
            }
            return LedgerCell(
                index: cell.index,
                target: project.worldPosition(for: cell),
                originalFingerprint: original,
                requiredBlockID: construction >> 4,
                resource: cell.resource,
                placed: false,
                placedFingerprint: nil
            )
        }
        ledger = Ledger(
            projectId: project.projectId,
            origin: project.origin,
            entrance: entrance,
            rest: project.restPosition,
            cells: cells
        )
        state = PebbleAgentConstructionState(
            projectId: project.projectId,
            origin: project.origin,
            placedCount: 0,
            lastPlacement: "none",
            lastMaterial: "none",
            lastPhysicalStatus: "none",
            lastCommittedEffectCount: 0,
            lastFailure: "none",
            rollbackCount: state.rollbackCount,
            cleanupRestoredBlockCount: 0,
            lastClear: "none"
        )
    }

    mutating func place(
        world: World,
        actor: AgentSnapshot,
        physicalActor: LabCoreAgentEntity,
        project: AgentConstructionProject,
        intent: AgentPlacementIntent,
        occupiedAgentPositions: [AgentPosition],
        playerPosition: AgentPosition,
        buildGateEnabled: Bool,
        buildAutoEnabled: Bool,
        materialGateway: PebbleAgentMaterialCustodyGateway,
        physicalGateway: PebbleAgentPhysicalActionGateway,
        prevalidate: () throws -> Void,
        publishAndVerify: (_ finalCell: Bool, _ actualFingerprint: Int) throws -> Void
    ) throws {
        guard buildGateEnabled else { throw ExecutionError.gateDisabled }
        guard buildAutoEnabled else { throw ExecutionError.autoDisabled }
        guard var ledger else { throw ExecutionError.projectMissing }
        guard ledger.projectId == project.projectId,
              project.projectId == intent.projectId,
              actor.id == project.builderAgentId,
              actor.id == intent.builderAgentId else {
            throw ExecutionError.projectMismatch
        }
        guard physicalActor.labAgentId == actor.id,
              !physicalActor.dead,
              physicalActor.world === world,
              AgentPosition(
                x: Int(physicalActor.x.rounded(.down)),
                y: Int(physicalActor.y.rounded(.down)),
                z: Int(physicalActor.z.rounded(.down))
              ) == actor.position else {
            throw ExecutionError.projectMismatch
        }
        guard ledger.cells.indices.contains(intent.cellIndex),
              intent.cellIndex == project.nextCellIndex,
              let blueprintCell = project.nextCell,
              let expectedTarget = project.nextTarget,
              let expectedWork = project.nextWorkPosition,
              intent.target == expectedTarget,
              intent.workPosition == expectedWork,
              intent.resource == blueprintCell.resource,
              ledger.cells[intent.cellIndex].target == intent.target,
              !ledger.cells[intent.cellIndex].placed else {
            throw ExecutionError.invalidCell
        }
        let target = intent.target
        let horizontalReach = abs(target.x - actor.position.x) + abs(target.z - actor.position.z)
        let verticalReach = target.y - actor.position.y
        guard actor.position == intent.workPosition,
              horizontalReach == 1,
              (0...2).contains(verticalReach) else {
            throw ExecutionError.invalidReach
        }
        guard world.isChunkReady(target.x >> 4, target.z >> 4) else {
            throw ExecutionError.chunkUnavailable
        }
        guard !occupiedAgentPositions.contains(intent.workPosition),
              playerPosition != intent.workPosition else {
            throw ExecutionError.occupied
        }
        let cell = ledger.cells[intent.cellIndex]
        let currentFingerprint = world.getBlock(target.x, target.y, target.z)
        guard currentFingerprint == cell.originalFingerprint else {
            throw ExecutionError.staleFingerprint
        }
        guard priorCellsConform(world: world, ledger: ledger, before: intent.cellIndex) else {
            throw ExecutionError.previousCellChanged
        }
        try prevalidate()

        guard let binding = materialGateway.placementBinding(
            actor: physicalActor,
            requiredBlockID: cell.requiredBlockID
        ) else {
            let hasAnyMaterial = physicalActor.carriedItems.contains {
                guard let stack = $0 else { return false }
                return stack.count > 0 && itemDef(stack.id).block != nil
            }
            throw hasAnyMaterial ? ExecutionError.wrongMaterial : ExecutionError.missingMaterial
        }
        let physicalTarget = PhysicalBlockPosition(x: target.x, y: target.y, z: target.z)
        let hit = RaycastHit(
            x: target.x,
            y: target.y,
            z: target.z,
            face: placementFace(target: target, workPosition: intent.workPosition),
            cell: currentFingerprint,
            t: 0,
            px: Double(target.x) + 0.5,
            py: Double(target.y) + 0.5,
            pz: Double(target.z) + 0.5
        )
        let finalCell = intent.cellIndex == ledger.cells.count - 1
        var boundaryError: Error?
        let physical = physicalGateway.placeBlock(
            world: world,
            actor: physicalActor,
            request: PebbleAgentBlockPlacementRequest(
                actorID: actor.id,
                hit: hit,
                target: physicalTarget,
                expectedCell: cell.originalFingerprint,
                blockID: cell.requiredBlockID,
                heldItem: binding.heldItem,
                orientation: BlockPlacementOrientation(
                    yaw: physicalActor.yaw,
                    pitch: physicalActor.pitch
                )
            ),
            custody: binding.custody,
            occupiedPositions: occupiedAgentPositions.map {
                PhysicalBlockPosition(x: $0.x, y: $0.y, z: $0.z)
            } + [PhysicalBlockPosition(
                x: playerPosition.x,
                y: playerPosition.y,
                z: playerPosition.z
            )],
            verifyAfterMutation: {
                let actual = world.getBlock(target.x, target.y, target.z)
                guard actual >> 4 == cell.requiredBlockID,
                      self.priorCellsConform(
                        world: world,
                        ledger: ledger,
                        before: intent.cellIndex
                      ) else {
                    boundaryError = ExecutionError.mutationVerificationFailed
                    return false
                }
                if finalCell, !self.completeStructureConforms(
                    world: world,
                    ledger: ledger,
                    pending: cell,
                    pendingFingerprint: actual
                ) {
                    boundaryError = ExecutionError.structureValidationFailed
                    return false
                }
                do {
                    try publishAndVerify(finalCell, actual)
                    return true
                } catch {
                    boundaryError = error
                    return false
                }
            }
        )
        state.lastPhysicalStatus = physical.status.rawValue
        state.lastCommittedEffectCount = physical.committedEffectCount
        guard physical.succeeded else {
            if physical.status == .verificationFailure {
                state.rollbackCount += 1
                state.lastFailure = "rolledBack@\(positionText(target))"
            } else if physical.status == .rollbackFailure {
                state.lastFailure = "rollbackFailed@\(positionText(target))"
                throw ExecutionError.rollbackVerificationFailed
            }
            if let boundaryError { throw boundaryError }
            switch physical.failure {
            case .targetChanged: throw ExecutionError.staleFingerprint
            case .occupiedTarget: throw ExecutionError.occupied
            case .chunkUnavailable: throw ExecutionError.chunkUnavailable
            default: throw ExecutionError.mutationVerificationFailed
            }
        }
        ledger.cells[intent.cellIndex].placed = true
        ledger.cells[intent.cellIndex].placedFingerprint = physical.after
        self.ledger = ledger
        state.placedCount = ledger.cells.filter(\.placed).count
        state.lastPlacement = "\(intent.cellIndex):\(intent.resource.rawValue)@\(positionText(target))"
        let afterCount = physicalActor.carriedItems[binding.slot]?.count ?? 0
        state.lastMaterial = "slot=\(binding.slot):item=\(itemDef(binding.heldItem.id).name):before=\(binding.heldItem.count):after=\(afterCount)"
        state.lastFailure = "none"
    }

    mutating func clear(
        world: World,
        project: AgentConstructionProject,
        prevalidate: () throws -> Void,
        publishAndVerify: () throws -> Void
    ) throws {
        guard let ledger, ledger.projectId == project.projectId else {
            throw ExecutionError.projectMissing
        }
        let placed = ledger.cells.filter(\.placed)
        guard placed.allSatisfy({ cell in
            world.isChunkReady(cell.target.x >> 4, cell.target.z >> 4)
                && cell.placedFingerprint.map {
                    world.getBlock(cell.target.x, cell.target.y, cell.target.z) == $0
                } == true
        }) else {
            throw ExecutionError.clearVerificationFailed
        }
        try prevalidate()
        var restored: [LedgerCell] = []
        do {
            for cell in placed.reversed() {
                let returned = world.setBlock(
                    cell.target.x,
                    cell.target.y,
                    cell.target.z,
                    cell.originalFingerprint
                )
                guard returned == cell.placedFingerprint,
                      world.getBlock(cell.target.x, cell.target.y, cell.target.z)
                        == cell.originalFingerprint else {
                    throw ExecutionError.clearVerificationFailed
                }
                restored.append(cell)
            }
        } catch {
            try reapplyConstruction(world: world, cells: restored.reversed())
            throw error
        }
        do {
            try publishAndVerify()
        } catch {
            try reapplyConstruction(world: world, cells: restored.reversed())
            state.lastFailure = "clearPublicationFailed"
            throw error
        }
        state.cleanupRestoredBlockCount = restored.count
        state.lastClear = "restored=\(restored.count)"
        state.projectId = nil
        state.origin = nil
        state.placedCount = 0
        self.ledger = nil
    }

    @discardableResult
    mutating func cleanup(world: World) -> Bool {
        guard let ledger else { return true }
        let placed = ledger.cells.filter(\.placed)
        guard placed.allSatisfy({ cell in
            world.isChunkReady(cell.target.x >> 4, cell.target.z >> 4)
                && cell.placedFingerprint.map {
                    world.getBlock(cell.target.x, cell.target.y, cell.target.z) == $0
                } == true
        }) else {
            state.lastFailure = "cleanupStructureChanged"
            return false
        }
        var restored: [LedgerCell] = []
        do {
            for cell in placed.reversed() {
                let returned = world.setBlock(
                    cell.target.x,
                    cell.target.y,
                    cell.target.z,
                    cell.originalFingerprint
                )
                guard returned == cell.placedFingerprint,
                      world.getBlock(cell.target.x, cell.target.y, cell.target.z)
                        == cell.originalFingerprint else {
                    throw ExecutionError.clearVerificationFailed
                }
                restored.append(cell)
            }
        } catch {
            try? reapplyConstruction(world: world, cells: restored.reversed())
            state.lastFailure = "cleanupRollbackFailed"
            return false
        }
        state.cleanupRestoredBlockCount = restored.count
        state.lastClear = "lifecycleRestored=\(restored.count)"
        state.projectId = nil
        state.origin = nil
        state.placedCount = 0
        self.ledger = nil
        return true
    }

    private func priorCellsConform(world: World, ledger: Ledger, before index: Int) -> Bool {
        ledger.cells.prefix(index).allSatisfy { cell in
            cell.placed
                && cell.placedFingerprint.map { fingerprint in
                    world.getBlock(cell.target.x, cell.target.y, cell.target.z) == fingerprint
                } == true
        }
    }

    private func completeStructureConforms(
        world: World,
        ledger: Ledger,
        pending: LedgerCell,
        pendingFingerprint: Int
    ) -> Bool {
        let cellsConform = ledger.cells.allSatisfy { cell in
            let expected = cell.index == pending.index
                ? pendingFingerprint
                : cell.placedFingerprint
            return (cell.index == pending.index || cell.placed)
                && expected.map {
                    world.getBlock(cell.target.x, cell.target.y, cell.target.z) == $0
                } == true
        }
        let entranceFeet = world.getBlock(ledger.entrance.x, ledger.entrance.y, ledger.entrance.z)
        let entranceHead = world.getBlock(ledger.entrance.x, ledger.entrance.y + 1, ledger.entrance.z)
        let restFeet = world.getBlock(ledger.rest.x, ledger.rest.y, ledger.rest.z)
        let restHead = world.getBlock(ledger.rest.x, ledger.rest.y + 1, ledger.rest.z)
        let restFloor = world.getBlock(ledger.rest.x, ledger.rest.y - 1, ledger.rest.z)
        let roof = world.getBlock(ledger.rest.x, ledger.rest.y + 2, ledger.rest.z)
        return cellsConform
            && isAir(UInt16(truncatingIfNeeded: entranceFeet))
            && isAir(UInt16(truncatingIfNeeded: entranceHead))
            && isAir(UInt16(truncatingIfNeeded: restFeet))
            && isAir(UInt16(truncatingIfNeeded: restHead))
            && blockDefs[restFloor >> 4].solid
            && roof >> 4 == PebbleAgentConstructionMapping.woodFingerprint >> 4
    }

    private func reapplyConstruction<C: Collection>(world: World, cells: C) throws
    where C.Element == LedgerCell {
        for cell in cells {
            guard let placedFingerprint = cell.placedFingerprint else {
                throw ExecutionError.rollbackVerificationFailed
            }
            _ = world.setBlock(
                cell.target.x,
                cell.target.y,
                cell.target.z,
                placedFingerprint
            )
            guard world.getBlock(cell.target.x, cell.target.y, cell.target.z)
                    == placedFingerprint else {
                throw ExecutionError.rollbackVerificationFailed
            }
        }
    }

    private func placementFace(
        target: AgentPosition,
        workPosition: AgentPosition
    ) -> Int {
        let dx = workPosition.x - target.x
        let dz = workPosition.z - target.z
        if dx < 0 { return Dir.west }
        if dx > 0 { return Dir.east }
        if dz < 0 { return Dir.north }
        if dz > 0 { return Dir.south }
        return workPosition.y < target.y ? Dir.down : Dir.up
    }

    private func offset(_ origin: AgentPosition, _ relative: AgentPosition) -> AgentPosition {
        AgentPosition(
            x: origin.x + relative.x,
            y: origin.y + relative.y,
            z: origin.z + relative.z
        )
    }

    private func positionText(_ position: AgentPosition) -> String {
        "\(position.x),\(position.y),\(position.z)"
    }
}
