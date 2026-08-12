import Foundation

/// Integer foot position for a body placed at the center of a World cell.
///
/// The type is actor-neutral: it carries no Civilization identity or state.
public struct EntityPlacementPosition: Hashable, Codable {
    public let x: Int
    public let y: Int
    public let z: Int

    public init(x: Int, y: Int, z: Int) {
        self.x = x
        self.y = y
        self.z = z
    }
}

/// Exact World-space point that a placement must remain separated from.
///
/// Callers use this for already-present actors or other reserved geometry
/// whose position is not necessarily centered in an integer cell.
public struct EntityPlacementReservedPoint: Hashable, Codable {
    public let x: Double
    public let y: Double
    public let z: Double

    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}

public enum EntityPlacementRejection: String, CaseIterable, Hashable {
    case invalidConfiguration
    case outsideWorld
    case chunkUnavailable
    case incompatibleSupport
    case bodyObstructed
    case incompatibleFluid
    case entityCollision
    case reservedSeparation
    case selectedSeparation
    case dangerousAdjacentDrop
    case insufficientEgress
}

public struct EntityPlacementAssessment {
    public let position: EntityPlacementPosition
    public let body: AABB
    public let rejections: [EntityPlacementRejection]

    public var isValid: Bool { rejections.isEmpty }
}

/// One physical overlap inside a caller-supplied target set.
///
/// The positions are canonicalized so diagnostics do not depend on the order
/// in which a transaction intends to apply its targets.
public struct EntityPlacementSetOverlap: Hashable {
    public let first: EntityPlacementPosition
    public let second: EntityPlacementPosition

    public init(
        first: EntityPlacementPosition,
        second: EntityPlacementPosition
    ) {
        if Self.less(first, second) {
            self.first = first
            self.second = second
        } else {
            self.first = second
            self.second = first
        }
    }

    private static func less(
        _ lhs: EntityPlacementPosition,
        _ rhs: EntityPlacementPosition
    ) -> Bool {
        if lhs.x != rhs.x { return lhs.x < rhs.x }
        if lhs.y != rhs.y { return lhs.y < rhs.y }
        return lhs.z < rhs.z
    }
}

/// Read-only validation of one complete physical placement target set.
///
/// `assessments` retain the caller's order for per-target diagnostics while
/// `overlaps` are canonical and therefore independent of application order.
/// A set is valid only when every target is valid against the current World
/// boundary and no two target AABBs intersect each other.
public struct EntityPlacementSetAssessment {
    public let assessments: [EntityPlacementAssessment]
    public let overlaps: [EntityPlacementSetOverlap]

    public var isValid: Bool {
        assessments.allSatisfy(\.isValid) && overlaps.isEmpty
    }
}

public struct BoundedEntityPlacementSearchConfiguration {
    public let requiredCount: Int
    public let horizontalRadius: Int
    public let verticalRadius: Int
    public let maximumCandidateEvaluations: Int
    public let bodyWidth: Double
    public let bodyHeight: Double
    public let minimumSelectedHorizontalDistance: Double
    public let minimumReservedHorizontalDistance: Double
    public let minimumEgressCount: Int
    public let maximumSafeDrop: Int

    public init(
        requiredCount: Int,
        horizontalRadius: Int,
        verticalRadius: Int,
        maximumCandidateEvaluations: Int,
        bodyWidth: Double,
        bodyHeight: Double,
        minimumSelectedHorizontalDistance: Double,
        minimumReservedHorizontalDistance: Double,
        minimumEgressCount: Int,
        maximumSafeDrop: Int
    ) {
        self.requiredCount = requiredCount
        self.horizontalRadius = horizontalRadius
        self.verticalRadius = verticalRadius
        self.maximumCandidateEvaluations = maximumCandidateEvaluations
        self.bodyWidth = bodyWidth
        self.bodyHeight = bodyHeight
        self.minimumSelectedHorizontalDistance = minimumSelectedHorizontalDistance
        self.minimumReservedHorizontalDistance = minimumReservedHorizontalDistance
        self.minimumEgressCount = minimumEgressCount
        self.maximumSafeDrop = maximumSafeDrop
    }
}

public struct BoundedEntityPlacementSearchResult {
    public let positions: [EntityPlacementPosition]
    public let requiredCount: Int
    public let candidatesEvaluated: Int
    public let maximumCandidateEvaluations: Int
    public let rejectionCounts: [EntityPlacementRejection: Int]

    public var isComplete: Bool { positions.count == requiredCount }
}

private let entityPlacementDirections: [(x: Int, z: Int)] = [
    (0, -1), (1, 0), (0, 1), (-1, 0),
]

/// Validates one cell-centered body against PebbleCore's loaded chunks,
/// collision shapes, fluids, support geometry, and live entity AABBs.
///
/// This function is read-only. It deliberately does not place or move an
/// entity, and it does not guess that an unavailable chunk is empty.
public func assessEntityPlacement(
    in world: World,
    at position: EntityPlacementPosition,
    bodyWidth: Double,
    bodyHeight: Double,
    ignoringEntityIDs: Set<Int> = []
) -> EntityPlacementAssessment {
    let centerX = Double(position.x) + 0.5
    let centerZ = Double(position.z) + 0.5
    let halfWidth = bodyWidth / 2
    let body = AABB(
        centerX - halfWidth,
        Double(position.y),
        centerZ - halfWidth,
        centerX + halfWidth,
        Double(position.y) + bodyHeight,
        centerZ + halfWidth
    )
    guard bodyWidth > 0, bodyWidth <= 1, bodyHeight > 0 else {
        return EntityPlacementAssessment(
            position: position,
            body: body,
            rejections: [.invalidConfiguration]
        )
    }

    var rejections: [EntityPlacementRejection] = []
    let maximumY = world.info.minY + world.info.height
    if position.y <= world.info.minY
        || Double(position.y) + bodyHeight > Double(maximumY) {
        rejections.append(.outsideWorld)
    }

    // World.forEachCollisionBox reads one cell beyond its query so connected
    // shapes (fences, walls, stairs) resolve against real neighboring chunks.
    let queryX0 = Int((body.x0 - 1).rounded(.down))
    let queryX1 = Int((body.x1 + 1).rounded(.down))
    let queryZ0 = Int((body.z0 - 1).rounded(.down))
    let queryZ1 = Int((body.z1 + 1).rounded(.down))
    var chunkUnavailable = false
    var checkedChunks = Set<Int64>()
    for z in [queryZ0, queryZ1] {
        for x in [queryX0, queryX1] {
            let cx = floorDiv(x, CHUNK_W)
            let cz = floorDiv(z, CHUNK_W)
            let key = chunkKey(cx, cz)
            if checkedChunks.insert(key).inserted, !world.isChunkReady(cx, cz) {
                chunkUnavailable = true
            }
        }
    }
    if chunkUnavailable {
        rejections.append(.chunkUnavailable)
        return EntityPlacementAssessment(
            position: position,
            body: body,
            rejections: rejections
        )
    }

    let supportCell = world.getBlock(position.x, position.y - 1, position.z)
    let supportID = supportCell >> 4
    let supportName = blockDefs[supportID].name
    let hazardousSupports: Set<String> = [
        "cactus", "campfire", "soul_campfire", "magma_block", "powder_snow",
    ]
    var exactSupport = false
    let supportContact = AABB(
        body.x0,
        Double(position.y) - 0.001,
        body.z0,
        body.x1,
        Double(position.y) + 0.000_001,
        body.z1
    )
    world.forEachCollisionBox(supportContact) { box in
        if abs(box.y1 - Double(position.y)) <= 0.000_001
            && box.x0 < body.x1 && box.x1 > body.x0
            && box.z0 < body.z1 && box.z1 > body.z0 {
            exactSupport = true
        }
    }
    if !sturdyTop(supportCell) || !exactSupport
        || hazardousSupports.contains(supportName)
        || world.isWaterAt(position.x, position.y - 1, position.z)
        || world.isLavaAt(position.x, position.y - 1, position.z) {
        rejections.append(.incompatibleSupport)
    }

    var bodyObstructed = false
    world.forEachCollisionBox(body) { box in
        if box.intersects(body) { bodyObstructed = true }
    }
    if bodyObstructed { rejections.append(.bodyObstructed) }

    let epsilon = 0.000_001
    let bodyX0 = Int(body.x0.rounded(.down))
    let bodyX1 = Int((body.x1 - epsilon).rounded(.down))
    let bodyY0 = Int(body.y0.rounded(.down))
    let bodyY1 = Int((body.y1 - epsilon).rounded(.down))
    let bodyZ0 = Int(body.z0.rounded(.down))
    let bodyZ1 = Int((body.z1 - epsilon).rounded(.down))
    var incompatibleFluid = false
    for y in bodyY0...bodyY1 {
        for z in bodyZ0...bodyZ1 {
            for x in bodyX0...bodyX1 {
                let name = blockDefs[world.getBlockId(x, y, z)].name
                if world.isWaterAt(x, y, z) || world.isLavaAt(x, y, z)
                    || name == "powder_snow" || name == "fire"
                    || name == "soul_fire" {
                    incompatibleFluid = true
                }
            }
        }
    }
    if incompatibleFluid { rejections.append(.incompatibleFluid) }

    let collisions = world.getEntitiesInBox(body).filter {
        !ignoringEntityIDs.contains($0.id)
    }
    if !collisions.isEmpty { rejections.append(.entityCollision) }

    return EntityPlacementAssessment(
        position: position,
        body: body,
        rejections: rejections
    )
}

/// Validates a complete set of equal-sized entity targets against PebbleCore.
///
/// The ignored IDs are bounded caller-owned physical entities whose current
/// positions are being replaced by the same atomic target set. They remain
/// excluded only from the World-side checks in this call; the returned set
/// assessment still checks every target body against every other target body.
public func assessEntityPlacementSet(
    in world: World,
    at positions: [EntityPlacementPosition],
    bodyWidth: Double,
    bodyHeight: Double,
    ignoringEntityIDs: Set<Int> = []
) -> EntityPlacementSetAssessment {
    let assessments = positions.map {
        assessEntityPlacement(
            in: world,
            at: $0,
            bodyWidth: bodyWidth,
            bodyHeight: bodyHeight,
            ignoringEntityIDs: ignoringEntityIDs
        )
    }
    var overlapSet = Set<EntityPlacementSetOverlap>()
    guard assessments.count > 1 else {
        return EntityPlacementSetAssessment(
            assessments: assessments,
            overlaps: []
        )
    }
    for firstIndex in assessments.indices.dropLast() {
        for secondIndex in assessments.indices where secondIndex > firstIndex {
            let first = assessments[firstIndex]
            let second = assessments[secondIndex]
            if first.body.intersects(second.body) {
                overlapSet.insert(EntityPlacementSetOverlap(
                    first: first.position,
                    second: second.position
                ))
            }
        }
    }
    let overlaps = overlapSet.sorted {
        if $0.first != $1.first {
            if $0.first.x != $1.first.x {
                return $0.first.x < $1.first.x
            }
            if $0.first.y != $1.first.y {
                return $0.first.y < $1.first.y
            }
            return $0.first.z < $1.first.z
        }
        if $0.second.x != $1.second.x {
            return $0.second.x < $1.second.x
        }
        if $0.second.y != $1.second.y {
            return $0.second.y < $1.second.y
        }
        return $0.second.z < $1.second.z
    }
    return EntityPlacementSetAssessment(
        assessments: assessments,
        overlaps: overlaps
    )
}

/// Finds a requested number of safe cell-centered positions using a stable,
/// bounded order. The search is read-only and returns a partial result when
/// its explicit budget cannot satisfy the request.
public func findSafeEntityPlacements(
    in world: World,
    anchor: EntityPlacementPosition,
    preferredPositions: [EntityPlacementPosition],
    reservedPoints: [EntityPlacementReservedPoint],
    configuration: BoundedEntityPlacementSearchConfiguration,
    ignoringEntityIDs: Set<Int> = []
) -> BoundedEntityPlacementSearchResult {
    let validConfiguration = configuration.requiredCount > 0
        && configuration.horizontalRadius >= 0
        && configuration.verticalRadius >= 0
        && configuration.maximumCandidateEvaluations > 0
        && configuration.bodyWidth > 0 && configuration.bodyWidth <= 1
        && configuration.bodyHeight > 0
        && configuration.minimumSelectedHorizontalDistance >= 0
        && configuration.minimumReservedHorizontalDistance >= 0
        && (0...entityPlacementDirections.count).contains(
            configuration.minimumEgressCount
        )
        && configuration.maximumSafeDrop >= 0
    guard validConfiguration else {
        return BoundedEntityPlacementSearchResult(
            positions: [],
            requiredCount: configuration.requiredCount,
            candidatesEvaluated: 0,
            maximumCandidateEvaluations: configuration.maximumCandidateEvaluations,
            rejectionCounts: [.invalidConfiguration: 1]
        )
    }

    var candidates: [EntityPlacementPosition] = []
    var seenCandidates = Set<EntityPlacementPosition>()
    func appendCandidate(_ position: EntityPlacementPosition) {
        if seenCandidates.insert(position).inserted { candidates.append(position) }
    }

    // Preserve caller-provided legacy or product-preferred cells first.
    for position in preferredPositions { appendCandidate(position) }

    var verticalOffsets: [Int] = [0]
    if configuration.verticalRadius > 0 {
        for distance in 1...configuration.verticalRadius {
            verticalOffsets.append(-distance)
            verticalOffsets.append(distance)
        }
    }
    for position in preferredPositions {
        for dy in verticalOffsets.dropFirst() {
            appendCandidate(EntityPlacementPosition(
                x: position.x, y: position.y + dy, z: position.z
            ))
        }
    }

    // Then expand in deterministic square rings around the supplied anchor.
    for radius in 0...configuration.horizontalRadius {
        if radius == 0 {
            for dy in verticalOffsets {
                appendCandidate(EntityPlacementPosition(
                    x: anchor.x, y: anchor.y + dy, z: anchor.z
                ))
            }
            continue
        }
        for x in (anchor.x - radius)...(anchor.x + radius) {
            for z in [anchor.z - radius, anchor.z + radius] {
                for dy in verticalOffsets {
                    appendCandidate(EntityPlacementPosition(
                        x: x, y: anchor.y + dy, z: z
                    ))
                }
            }
        }
        if radius > 1 {
            for z in (anchor.z - radius + 1)...(anchor.z + radius - 1) {
                for x in [anchor.x + radius, anchor.x - radius] {
                    for dy in verticalOffsets {
                        appendCandidate(EntityPlacementPosition(
                            x: x, y: anchor.y + dy, z: z
                        ))
                    }
                }
            }
        } else {
            for x in [anchor.x + radius, anchor.x - radius] {
                for dy in verticalOffsets {
                    appendCandidate(EntityPlacementPosition(
                        x: x, y: anchor.y + dy, z: anchor.z
                    ))
                }
            }
        }
    }

    func horizontalDistance(
        _ lhs: EntityPlacementPosition,
        _ rhs: EntityPlacementReservedPoint
    ) -> Double {
        hypot(Double(lhs.x) + 0.5 - rhs.x, Double(lhs.z) + 0.5 - rhs.z)
    }

    func horizontalDistance(
        _ lhs: EntityPlacementPosition,
        _ rhs: EntityPlacementPosition
    ) -> Double {
        hypot(Double(lhs.x - rhs.x), Double(lhs.z - rhs.z))
    }

    var selected: [EntityPlacementPosition] = []
    var evaluated = 0
    var rejectionCounts: [EntityPlacementRejection: Int] = [:]
    func reject(_ reason: EntityPlacementRejection) {
        rejectionCounts[reason, default: 0] += 1
    }

    for candidate in candidates {
        if selected.count == configuration.requiredCount
            || evaluated == configuration.maximumCandidateEvaluations {
            break
        }
        evaluated += 1
        let assessment = assessEntityPlacement(
            in: world,
            at: candidate,
            bodyWidth: configuration.bodyWidth,
            bodyHeight: configuration.bodyHeight,
            ignoringEntityIDs: ignoringEntityIDs
        )
        guard assessment.isValid else {
            for rejection in assessment.rejections { reject(rejection) }
            continue
        }
        guard reservedPoints.allSatisfy({
            horizontalDistance(candidate, $0)
                >= configuration.minimumReservedHorizontalDistance
        }) else {
            reject(.reservedSeparation)
            continue
        }
        guard selected.allSatisfy({
            horizontalDistance(candidate, $0)
                >= configuration.minimumSelectedHorizontalDistance
        }) else {
            reject(.selectedSeparation)
            continue
        }

        var egressCount = 0
        var hasDangerousAdjacentDrop = false
        for direction in entityPlacementDirections {
            var egressFound = false
            for dy in [0, 1] + Array(1...max(1, configuration.maximumSafeDrop)).map({ -$0 }) {
                if dy < -configuration.maximumSafeDrop { continue }
                let neighbor = EntityPlacementPosition(
                    x: candidate.x + direction.x,
                    y: candidate.y + dy,
                    z: candidate.z + direction.z
                )
                let neighborAssessment = assessEntityPlacement(
                    in: world,
                    at: neighbor,
                    bodyWidth: configuration.bodyWidth,
                    bodyHeight: configuration.bodyHeight,
                    ignoringEntityIDs: ignoringEntityIDs
                )
                if neighborAssessment.isValid {
                    egressFound = true
                    break
                }
            }
            if egressFound {
                egressCount += 1
                continue
            }
            let levelNeighbor = EntityPlacementPosition(
                x: candidate.x + direction.x,
                y: candidate.y,
                z: candidate.z + direction.z
            )
            let levelAssessment = assessEntityPlacement(
                in: world,
                at: levelNeighbor,
                bodyWidth: configuration.bodyWidth,
                bodyHeight: configuration.bodyHeight,
                ignoringEntityIDs: ignoringEntityIDs
            )
            if (
                levelAssessment.rejections.contains(.incompatibleSupport)
                    && !levelAssessment.rejections.contains(.bodyObstructed)
            ) || levelAssessment.rejections.contains(.incompatibleFluid) {
                hasDangerousAdjacentDrop = true
            }
        }
        if hasDangerousAdjacentDrop {
            reject(.dangerousAdjacentDrop)
            continue
        }
        guard egressCount >= configuration.minimumEgressCount else {
            reject(.insufficientEgress)
            continue
        }
        selected.append(candidate)
    }

    return BoundedEntityPlacementSearchResult(
        positions: selected,
        requiredCount: configuration.requiredCount,
        candidatesEvaluated: evaluated,
        maximumCandidateEvaluations: configuration.maximumCandidateEvaluations,
        rejectionCounts: rejectionCounts
    )
}
