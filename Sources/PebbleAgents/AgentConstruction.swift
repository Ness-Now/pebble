public enum AgentConstructionError: Error, Equatable {
    case invalidBlueprintId
    case invalidFootprint
    case invalidMaximumHeight
    case invalidCellCount(Int)
    case duplicateCellIndex(Int)
    case discontinuousCellIndices
    case duplicateCellPosition(AgentPosition)
    case cellOutsideFootprint(Int)
    case reservedCellOccupied(Int)
    case unsupportedMaterial(AgentResourceKind)
    case invalidMaterialQuantity(AgentResourceKind, Int)
    case materialRequirementsMismatch
    case invalidFingerprintCount(Int)
    case fingerprintCellMismatch(Int)
    case invalidWorkPositionCount(Int)
    case invalidWorkPosition(Int)
    case invalidProject
    case invalidSiteCandidateCount(Int)
}

public struct AgentBlueprintCell: Codable, Equatable {
    public let index: Int
    public let relativePosition: AgentPosition
    public let resource: AgentResourceKind
    public let workOffset: AgentPosition

    public init(
        index: Int,
        relativePosition: AgentPosition,
        resource: AgentResourceKind,
        workOffset: AgentPosition
    ) {
        self.index = index
        self.relativePosition = relativePosition
        self.resource = resource
        self.workOffset = workOffset
    }
}

public struct AgentBlueprint: Codable, Equatable {
    public static let fixedLeanToV1Id = "fixedLeanToV1"
    public static let fixedLeanToV1: AgentBlueprint = try! AgentBlueprint(
        blueprintId: fixedLeanToV1Id,
        footprintWidth: 3,
        footprintDepth: 3,
        maximumHeight: 3,
        cells: [
            AgentBlueprintCell(index: 0, relativePosition: AgentPosition(x: 0, y: 0, z: 2), resource: .stone, workOffset: AgentPosition(x: 0, y: 0, z: 3)),
            AgentBlueprintCell(index: 1, relativePosition: AgentPosition(x: 1, y: 0, z: 2), resource: .stone, workOffset: AgentPosition(x: 1, y: 0, z: 3)),
            AgentBlueprintCell(index: 2, relativePosition: AgentPosition(x: 2, y: 0, z: 2), resource: .stone, workOffset: AgentPosition(x: 2, y: 0, z: 3)),
            AgentBlueprintCell(index: 3, relativePosition: AgentPosition(x: 0, y: 1, z: 2), resource: .wood, workOffset: AgentPosition(x: 0, y: 0, z: 3)),
            AgentBlueprintCell(index: 4, relativePosition: AgentPosition(x: 1, y: 1, z: 2), resource: .wood, workOffset: AgentPosition(x: 1, y: 0, z: 3)),
            AgentBlueprintCell(index: 5, relativePosition: AgentPosition(x: 2, y: 1, z: 2), resource: .wood, workOffset: AgentPosition(x: 2, y: 0, z: 3)),
            AgentBlueprintCell(index: 6, relativePosition: AgentPosition(x: 0, y: 2, z: 1), resource: .wood, workOffset: AgentPosition(x: 0, y: 0, z: 0)),
            AgentBlueprintCell(index: 7, relativePosition: AgentPosition(x: 1, y: 2, z: 1), resource: .wood, workOffset: AgentPosition(x: 1, y: 0, z: 0)),
            AgentBlueprintCell(index: 8, relativePosition: AgentPosition(x: 2, y: 2, z: 1), resource: .wood, workOffset: AgentPosition(x: 2, y: 0, z: 0)),
        ],
        entranceOffset: AgentPosition(x: 1, y: 0, z: 0),
        restOffset: AgentPosition(x: 1, y: 0, z: 1),
        materialRequirements: [
            AgentResourceAmount(resource: .wood, quantity: 6),
            AgentResourceAmount(resource: .stone, quantity: 3),
        ]
    )

    public let blueprintId: String
    public let footprintWidth: Int
    public let footprintDepth: Int
    public let maximumHeight: Int
    public let cells: [AgentBlueprintCell]
    public let entranceOffset: AgentPosition
    public let restOffset: AgentPosition
    public let materialRequirements: [AgentResourceAmount]

    public init(
        blueprintId: String,
        footprintWidth: Int,
        footprintDepth: Int,
        maximumHeight: Int,
        cells: [AgentBlueprintCell],
        entranceOffset: AgentPosition,
        restOffset: AgentPosition,
        materialRequirements: [AgentResourceAmount]
    ) throws {
        guard !blueprintId.isEmpty else { throw AgentConstructionError.invalidBlueprintId }
        guard footprintWidth > 0, footprintDepth > 0 else {
            throw AgentConstructionError.invalidFootprint
        }
        guard maximumHeight > 0 else { throw AgentConstructionError.invalidMaximumHeight }
        guard !cells.isEmpty, cells.count <= 64 else {
            throw AgentConstructionError.invalidCellCount(cells.count)
        }
        let ordered = cells.sorted { $0.index < $1.index }
        guard ordered.map(\.index) == Array(0..<ordered.count) else {
            throw AgentConstructionError.discontinuousCellIndices
        }
        var positions = Set<AgentPosition>()
        var indices = Set<Int>()
        for cell in ordered {
            guard indices.insert(cell.index).inserted else {
                throw AgentConstructionError.duplicateCellIndex(cell.index)
            }
            guard positions.insert(cell.relativePosition).inserted else {
                throw AgentConstructionError.duplicateCellPosition(cell.relativePosition)
            }
            guard (0..<footprintWidth).contains(cell.relativePosition.x),
                  (0..<maximumHeight).contains(cell.relativePosition.y),
                  (0..<footprintDepth).contains(cell.relativePosition.z) else {
                throw AgentConstructionError.cellOutsideFootprint(cell.index)
            }
            guard cell.relativePosition != entranceOffset,
                  cell.relativePosition != restOffset else {
                throw AgentConstructionError.reservedCellOccupied(cell.index)
            }
            guard cell.resource == .wood || cell.resource == .stone else {
                throw AgentConstructionError.unsupportedMaterial(cell.resource)
            }
        }
        let normalized = AgentResourceAmounts.normalize(materialRequirements)
        guard normalized.allSatisfy({
            ($0.resource == .wood || $0.resource == .stone) && $0.quantity > 0
        }) else {
            let invalid = normalized.first { $0.resource != .wood && $0.resource != .stone }
            throw AgentConstructionError.unsupportedMaterial(invalid?.resource ?? .sandboxResource)
        }
        let derived = AgentResourceAmounts.normalize(ordered.map {
            AgentResourceAmount(resource: $0.resource, quantity: 1)
        })
        guard normalized == derived else {
            throw AgentConstructionError.materialRequirementsMismatch
        }
        self.blueprintId = blueprintId
        self.footprintWidth = footprintWidth
        self.footprintDepth = footprintDepth
        self.maximumHeight = maximumHeight
        self.cells = ordered
        self.entranceOffset = entranceOffset
        self.restOffset = restOffset
        self.materialRequirements = normalized
    }
}

public struct AgentConstructionMaterialState: Codable, Equatable {
    public private(set) var wood: Int
    public private(set) var stone: Int

    public var total: Int { wood + stone }
    public var amounts: [AgentResourceAmount] {
        [
            wood > 0 ? AgentResourceAmount(resource: .wood, quantity: wood) : nil,
            stone > 0 ? AgentResourceAmount(resource: .stone, quantity: stone) : nil,
        ].compactMap { $0 }
    }

    public init() {
        wood = 0
        stone = 0
    }

    public init(amounts: [AgentResourceAmount]) throws {
        self.init()
        for amount in AgentResourceAmounts.normalize(amounts) {
            guard amount.resource == .wood || amount.resource == .stone else {
                throw AgentConstructionError.unsupportedMaterial(amount.resource)
            }
            guard amount.quantity > 0 else {
                throw AgentConstructionError.invalidMaterialQuantity(amount.resource, amount.quantity)
            }
            _ = add(amount.resource, quantity: amount.quantity)
        }
    }

    public func count(of resource: AgentResourceKind) -> Int {
        switch resource {
        case .wood: return wood
        case .stone: return stone
        case .sandboxResource, .foodRaw: return 0
        }
    }

    public func canRemove(_ resource: AgentResourceKind, quantity: Int = 1) -> Bool {
        quantity > 0 && count(of: resource) >= quantity
    }

    @discardableResult
    public mutating func add(_ resource: AgentResourceKind, quantity: Int = 1) -> Bool {
        guard quantity > 0 else { return false }
        switch resource {
        case .wood: wood += quantity
        case .stone: stone += quantity
        case .sandboxResource, .foodRaw: return false
        }
        return true
    }

    @discardableResult
    public mutating func remove(_ resource: AgentResourceKind, quantity: Int = 1) -> Bool {
        guard canRemove(resource, quantity: quantity) else { return false }
        switch resource {
        case .wood: wood -= quantity
        case .stone: stone -= quantity
        case .sandboxResource, .foodRaw: return false
        }
        return true
    }
}

public struct AgentConstructionCellFingerprint: Codable, Equatable {
    public let cellIndex: Int
    public let originalFingerprint: Int

    public init(cellIndex: Int, originalFingerprint: Int) {
        self.cellIndex = cellIndex
        self.originalFingerprint = originalFingerprint
    }
}

public enum AgentConstructionStatus: String, Codable, Equatable {
    case planned
    case acquiringMaterials
    case readyToFund
    case funded
    case building
    case blocked
    case completed
}

/// Selects which material boundary makes a construction cell spendable.
///
/// The coarse mode preserves the historical headless escrow transaction. The
/// physical mode is represented without a new persisted field: a project that
/// starts funded with empty coarse material states can advance only after its
/// live adapter verifies a real Pebble custody debit.
public enum AgentConstructionMaterialAuthority: Equatable {
    case coarseEscrow
    case physicalCustody
}

public enum AgentConstructionFailure: String, Codable, Equatable {
    case noSafeBuildSite
    case gateDisabled
    case autoDisabled
    case projectAlreadyExists
    case projectMissing
    case invalidBuilder
    case insufficientMaterials
    case invalidStatus
    case invalidCell
    case staleFingerprint
    case occupied
    case chunkUnavailable
    case insufficientEscrow
    case structureChanged
    case routeUnavailable
    case publicationFailed
    case rollbackFailed
    case clearFailed
    case builderDied
}

public enum AgentPlacementStatus: String, Codable, Equatable {
    case succeeded
    case blocked
    case staleTarget
    case occupied
    case insufficientMaterial
    case invalidCell
    case rollbackFailed
}

public struct AgentPlacementIntent: Equatable {
    public let placementId: String
    public let projectId: String
    public let builderAgentId: String
    public let tick: Int
    public let cellIndex: Int
    public let target: AgentPosition
    public let workPosition: AgentPosition
    public let resource: AgentResourceKind

    public init(
        placementId: String,
        projectId: String,
        builderAgentId: String,
        tick: Int,
        cellIndex: Int,
        target: AgentPosition,
        workPosition: AgentPosition,
        resource: AgentResourceKind
    ) {
        self.placementId = placementId
        self.projectId = projectId
        self.builderAgentId = builderAgentId
        self.tick = tick
        self.cellIndex = cellIndex
        self.target = target
        self.workPosition = workPosition
        self.resource = resource
    }
}

public struct AgentPlacementOutcome: Codable, Equatable {
    public let placementId: String
    public let projectId: String
    public let builderAgentId: String
    public let tick: Int
    public let cellIndex: Int
    public let target: AgentPosition
    public let resource: AgentResourceKind
    public let status: AgentPlacementStatus
    public let reason: String

    public init(
        placementId: String,
        projectId: String,
        builderAgentId: String,
        tick: Int,
        cellIndex: Int,
        target: AgentPosition,
        resource: AgentResourceKind,
        status: AgentPlacementStatus,
        reason: String
    ) {
        self.placementId = placementId
        self.projectId = projectId
        self.builderAgentId = builderAgentId
        self.tick = tick
        self.cellIndex = cellIndex
        self.target = target
        self.resource = resource
        self.status = status
        self.reason = reason
    }
}

public struct AgentConstructionProject: Codable, Equatable {
    public let projectId: String
    public let blueprint: AgentBlueprint
    public var blueprintId: String { blueprint.blueprintId }
    public let builderAgentId: String
    public let origin: AgentPosition
    public private(set) var status: AgentConstructionStatus
    public let createdAtTick: Int
    public private(set) var completedAtTick: Int?
    public let previousHomePosition: AgentPosition
    public let restPosition: AgentPosition
    public let originalFingerprints: [AgentConstructionCellFingerprint]
    public let workPositions: [AgentPosition]
    public let materialRequirements: [AgentResourceAmount]
    public private(set) var materialEscrow: AgentConstructionMaterialState
    public private(set) var placedMaterialTotals: AgentConstructionMaterialState
    public private(set) var placedCellIndices: [Int]
    public private(set) var nextCellIndex: Int
    public private(set) var lastPlacementOutcome: AgentPlacementOutcome?
    public private(set) var lastFailure: AgentConstructionFailure?

    public var isActive: Bool { status != .completed }
    public var materialAuthority: AgentConstructionMaterialAuthority {
        let physicallyActiveStatus = status == .funded || status == .building
            || status == .blocked || status == .completed
        return physicallyActiveStatus
            && materialEscrow.total == 0
            && placedMaterialTotals.total == 0
            ? .physicalCustody
            : .coarseEscrow
    }
    public var installedMaterialTotals: AgentConstructionMaterialState {
        guard materialAuthority == .physicalCustody else { return placedMaterialTotals }
        var totals = AgentConstructionMaterialState()
        for index in placedCellIndices {
            guard blueprint.cells.indices.contains(index) else { continue }
            _ = totals.add(blueprint.cells[index].resource)
        }
        return totals
    }
    public var nextCell: AgentBlueprintCell? {
        blueprint.cells.first { $0.index == nextCellIndex }
    }
    public var nextTarget: AgentPosition? { nextCell.map(worldPosition) }
    public var nextWorkPosition: AgentPosition? { nextCell.map(workPosition) }

    public init(
        projectId: String,
        blueprint: AgentBlueprint = .fixedLeanToV1,
        builderAgentId: String,
        origin: AgentPosition,
        createdAtTick: Int,
        previousHomePosition: AgentPosition,
        originalFingerprints: [AgentConstructionCellFingerprint],
        workPositions: [AgentPosition]? = nil,
        materialAuthority: AgentConstructionMaterialAuthority = .coarseEscrow
    ) throws {
        guard !projectId.isEmpty, !builderAgentId.isEmpty, createdAtTick >= 0 else {
            throw AgentConstructionError.invalidProject
        }
        let ordered = originalFingerprints.sorted { $0.cellIndex < $1.cellIndex }
        guard ordered.count == blueprint.cells.count else {
            throw AgentConstructionError.invalidFingerprintCount(ordered.count)
        }
        guard ordered.map(\.cellIndex) == blueprint.cells.map(\.index) else {
            throw AgentConstructionError.fingerprintCellMismatch(
                ordered.first?.cellIndex ?? -1
            )
        }
        let resolvedWorkPositions = workPositions ?? blueprint.cells.map {
            Self.offset(origin, by: $0.workOffset)
        }
        guard resolvedWorkPositions.count == blueprint.cells.count else {
            throw AgentConstructionError.invalidWorkPositionCount(resolvedWorkPositions.count)
        }
        for (cell, work) in zip(blueprint.cells, resolvedWorkPositions) {
            let target = Self.offset(origin, by: cell.relativePosition)
            let horizontal = abs(target.x - work.x) + abs(target.z - work.z)
            let vertical = target.y - work.y
            guard horizontal == 1, (0...2).contains(vertical), target != work else {
                throw AgentConstructionError.invalidWorkPosition(cell.index)
            }
        }
        self.projectId = projectId
        self.blueprint = blueprint
        self.builderAgentId = builderAgentId
        self.origin = origin
        status = materialAuthority == .physicalCustody ? .funded : .acquiringMaterials
        self.createdAtTick = createdAtTick
        completedAtTick = nil
        self.previousHomePosition = previousHomePosition
        restPosition = Self.offset(origin, by: blueprint.restOffset)
        self.originalFingerprints = ordered
        self.workPositions = resolvedWorkPositions
        materialRequirements = blueprint.materialRequirements
        materialEscrow = AgentConstructionMaterialState()
        placedMaterialTotals = AgentConstructionMaterialState()
        placedCellIndices = []
        nextCellIndex = 0
        lastPlacementOutcome = nil
        lastFailure = nil
    }

    public func worldPosition(for cell: AgentBlueprintCell) -> AgentPosition {
        Self.offset(origin, by: cell.relativePosition)
    }

    public func workPosition(for cell: AgentBlueprintCell) -> AgentPosition {
        workPositions[cell.index]
    }

    public func originalFingerprint(for cellIndex: Int) -> Int? {
        originalFingerprints.first { $0.cellIndex == cellIndex }?.originalFingerprint
    }

    public func missingMaterials(
        campStock: AgentCampStock,
        builderInventory: AgentResourceInventory
    ) -> [AgentResourceAmount] {
        materialRequirements.compactMap { requirement in
            let available = campStock.count(of: requirement.resource)
                + builderInventory.count(of: requirement.resource)
                + materialEscrow.count(of: requirement.resource)
                + placedMaterialTotals.count(of: requirement.resource)
            let missing = max(0, requirement.quantity - available)
            return missing > 0
                ? AgentResourceAmount(resource: requirement.resource, quantity: missing)
                : nil
        }
    }

    mutating func markReadyToFund() {
        guard status == .acquiringMaterials || status == .planned else { return }
        status = .readyToFund
        lastFailure = nil
    }

    mutating func fund(_ materials: AgentConstructionMaterialState) {
        materialEscrow = materials
        status = .funded
        lastFailure = nil
    }

    mutating func applyPlacement(_ outcome: AgentPlacementOutcome) -> Bool {
        lastPlacementOutcome = outcome
        guard outcome.status == .succeeded,
              outcome.cellIndex == nextCellIndex,
              let cell = nextCell,
              cell.resource == outcome.resource else {
            lastFailure = outcome.status == .insufficientMaterial
                ? .insufficientEscrow
                : .invalidCell
            return false
        }
        let materialAccepted: Bool
        switch materialAuthority {
        case .coarseEscrow:
            materialAccepted = materialEscrow.remove(cell.resource)
                && placedMaterialTotals.add(cell.resource)
        case .physicalCustody:
            // The live Pebble adapter owns and verifies the real ItemStack
            // debit before it publishes this outcome. No coarse value moves.
            materialAccepted = true
        }
        guard materialAccepted else {
            lastFailure = outcome.status == .insufficientMaterial
                ? .insufficientEscrow
                : .invalidCell
            return false
        }
        placedCellIndices.append(cell.index)
        nextCellIndex += 1
        status = .building
        lastFailure = nil
        return true
    }

    mutating func recordFailure(
        _ failure: AgentConstructionFailure,
        blocksProject: Bool = true
    ) {
        if blocksProject { status = .blocked }
        lastFailure = failure
    }

    mutating func resumeAfterRecoverableFailure() {
        guard status == .blocked,
              lastFailure == .occupied
                || lastFailure == .chunkUnavailable
                || lastFailure == .routeUnavailable
                || lastFailure == .insufficientMaterials
                || lastFailure == .publicationFailed else { return }
        status = placedCellIndices.isEmpty ? .funded : .building
        lastFailure = nil
    }

    mutating func complete(at tick: Int) {
        status = .completed
        completedAtTick = tick
        lastFailure = nil
    }

    private static func offset(_ origin: AgentPosition, by offset: AgentPosition) -> AgentPosition {
        AgentPosition(
            x: origin.x + offset.x,
            y: origin.y + offset.y,
            z: origin.z + offset.z
        )
    }
}

public struct AgentConstructionDemand: Codable, Equatable {
    public let projectId: String
    public let missing: [AgentResourceAmount]

    public var isSatisfied: Bool { missing.isEmpty }
    public var eligibleResources: [AgentResourceKind] { missing.map(\.resource) }

    public init(projectId: String, missing: [AgentResourceAmount]) {
        self.projectId = projectId
        self.missing = AgentResourceAmounts.normalize(missing).filter {
            $0.resource == .wood || $0.resource == .stone
        }
    }
}

public enum AgentConstructionMaterialSurvey {
    public static let maximumDistanceFromHome = 16
    public static let stepDistance = 4

    public static func horizontalTarget(
        home: AgentPosition,
        currentPosition: AgentPosition,
        tick: Int
    ) -> AgentPosition {
        let easternLimit = home.x + maximumDistanceFromHome
        let targetX = currentPosition.x >= easternLimit
            ? easternLimit - stepDistance
            : min(easternLimit, currentPosition.x + stepDistance)
        return AgentPosition(
            x: targetX,
            y: home.y,
            z: currentPosition.z
        )
    }

    public static func permitsNormalizedTarget(
        _ target: AgentPosition,
        desiredTarget: AgentPosition,
        home: AgentPosition,
        currentPosition: AgentPosition
    ) -> Bool {
        let distanceFromDesired = abs(target.x - desiredTarget.x)
            + abs(target.z - desiredTarget.z)
        let distanceFromHome = abs(target.x - home.x) + abs(target.z - home.z)
        let distanceFromCurrent = abs(target.x - currentPosition.x)
            + abs(target.z - currentPosition.z)
        return distanceFromDesired <= AgentNavigationObservation.maximumRadius
            && distanceFromHome <= maximumDistanceFromHome
            && distanceFromCurrent <= AgentNavigationObservation.maximumRadius
    }
}

public struct AgentConstructionSiteCandidate: Codable, Equatable {
    public let origin: AgentPosition
    public let candidateIndex: Int
    public let chunksReady: Bool
    public let solidFloor: Bool
    public let replaceableCells: Bool
    public let liquidFree: Bool
    public let naturalResourcesClear: Bool
    public let reservedSpacesClear: Bool
    public let workPositionsClear: Bool
    public let occupancyClear: Bool
    public let routeFound: Bool
    public let positionsRead: Int
    public let originalFingerprints: [AgentConstructionCellFingerprint]

    public var valid: Bool {
        chunksReady && solidFloor && replaceableCells && liquidFree
            && naturalResourcesClear && reservedSpacesClear && workPositionsClear
            && occupancyClear && routeFound
    }

    public init(
        origin: AgentPosition,
        candidateIndex: Int,
        chunksReady: Bool,
        solidFloor: Bool,
        replaceableCells: Bool,
        liquidFree: Bool,
        naturalResourcesClear: Bool,
        reservedSpacesClear: Bool,
        workPositionsClear: Bool,
        occupancyClear: Bool,
        routeFound: Bool,
        positionsRead: Int,
        originalFingerprints: [AgentConstructionCellFingerprint]
    ) {
        self.origin = origin
        self.candidateIndex = candidateIndex
        self.chunksReady = chunksReady
        self.solidFloor = solidFloor
        self.replaceableCells = replaceableCells
        self.liquidFree = liquidFree
        self.naturalResourcesClear = naturalResourcesClear
        self.reservedSpacesClear = reservedSpacesClear
        self.workPositionsClear = workPositionsClear
        self.occupancyClear = occupancyClear
        self.routeFound = routeFound
        self.positionsRead = max(0, positionsRead)
        self.originalFingerprints = originalFingerprints.sorted { $0.cellIndex < $1.cellIndex }
    }
}

public enum AgentConstructionSiteSelector {
    public static let maximumCandidateCount = 32
    public static let maximumHorizontalDistance = 6

    public static func select(
        home: AgentPosition,
        candidates: [AgentConstructionSiteCandidate]
    ) throws -> AgentConstructionSiteCandidate? {
        guard candidates.count <= maximumCandidateCount else {
            throw AgentConstructionError.invalidSiteCandidateCount(candidates.count)
        }
        return candidates.filter(\.valid).sorted {
            let lhsDistance = horizontalDistance(home, $0.origin)
            let rhsDistance = horizontalDistance(home, $1.origin)
            if lhsDistance != rhsDistance { return lhsDistance < rhsDistance }
            let lhsDirection = directionIndex(home, $0.origin)
            let rhsDirection = directionIndex(home, $1.origin)
            if lhsDirection != rhsDirection { return lhsDirection < rhsDirection }
            if $0.origin.x != $1.origin.x { return $0.origin.x < $1.origin.x }
            if $0.origin.z != $1.origin.z { return $0.origin.z < $1.origin.z }
            if $0.origin.y != $1.origin.y { return $0.origin.y < $1.origin.y }
            return $0.candidateIndex < $1.candidateIndex
        }.first
    }

    private static func horizontalDistance(_ lhs: AgentPosition, _ rhs: AgentPosition) -> Int {
        abs(lhs.x - rhs.x) + abs(lhs.z - rhs.z)
    }

    private static func directionIndex(_ origin: AgentPosition, _ target: AgentPosition) -> Int {
        AgentResourcePerception.direction(observerPosition: origin, target: target).flatMap {
            AgentCardinalDirection.allCases.firstIndex(of: $0)
        } ?? 0
    }
}

public struct AgentConstructionMutationBoundary: Codable, Equatable {
    public let permittedPositions: [AgentPosition]

    public var isValid: Bool {
        permittedPositions.count == AgentBlueprint.fixedLeanToV1.cells.count
            && Set(permittedPositions).count == permittedPositions.count
    }

    public init(project: AgentConstructionProject) {
        permittedPositions = project.blueprint.cells.map(project.worldPosition)
    }

    public func permits(_ position: AgentPosition) -> Bool {
        isValid && permittedPositions.contains(position)
    }
}
