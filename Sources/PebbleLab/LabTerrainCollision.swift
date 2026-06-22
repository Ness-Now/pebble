enum LabTerrainOccupancyStatus: String, Codable {
    case occupable
    case blocked
    case unsupported
    case verticalSpaceOccupied
    case liquidUnsupported
    case unknown
    case outOfBounds
    case notLoaded
    case notReady
}

struct LabTerrainBodyBox: Codable, Equatable {
    let width: Double
    let depth: Double
    let height: Double
}

struct LabTerrainBodyContract: Codable, Equatable {
    let name: String
    let bodyBox: LabTerrainBodyBox
    let anchor: String
    let horizontalCentering: String
}

enum LabTerrainCollisionShape: String, Codable {
    case empty
    case fullCube
    case liquid
    case unknown
}

enum LabTerrainCollisionCellRole: String, Codable {
    case support
    case feet
    case head
}

struct LabTerrainCollisionCellFixture: Codable {
    let role: LabTerrainCollisionCellRole
    let shape: LabTerrainCollisionShape
    let shapeName: String
    let loaded: Bool
    let ready: Bool
}

struct LabTerrainCollisionColumnFixture: Codable {
    let name: String
    let x: Int
    let y: Int
    let z: Int
    let inBounds: Bool
    let source: String
    let support: LabTerrainCollisionCellFixture?
    let feet: LabTerrainCollisionCellFixture
    let head: LabTerrainCollisionCellFixture
}

struct LabTerrainCollisionResult: Codable {
    let x: Int
    let y: Int
    let z: Int
    let status: LabTerrainOccupancyStatus
    let reason: String
    let source: String
    let body: LabTerrainBodyContract
    let support: LabTerrainCollisionCellFixture?
    let feet: LabTerrainCollisionCellFixture
    let head: LabTerrainCollisionCellFixture
}

func labTerrainHumanBodyContractV0() -> LabTerrainBodyContract {
    LabTerrainBodyContract(
        name: "LabHumanV0",
        bodyBox: LabTerrainBodyBox(width: 0.6, depth: 0.6, height: 1.8),
        anchor: "feet_plane",
        horizontalCentering: "node_center"
    )
}

func evaluateTerrainOccupancyFixture(
    _ fixture: LabTerrainCollisionColumnFixture,
    body: LabTerrainBodyContract
) -> LabTerrainCollisionResult {
    func result(
        _ status: LabTerrainOccupancyStatus,
        reason: String
    ) -> LabTerrainCollisionResult {
        LabTerrainCollisionResult(
            x: fixture.x,
            y: fixture.y,
            z: fixture.z,
            status: status,
            reason: reason,
            source: fixture.source,
            body: body,
            support: fixture.support,
            feet: fixture.feet,
            head: fixture.head
        )
    }

    guard fixture.inBounds else {
        return result(.outOfBounds, reason: "candidate_out_of_bounds")
    }
    let orderedCells = [fixture.support, fixture.feet, fixture.head]
    for cell in orderedCells {
        guard let cell else {
            continue
        }
        guard cell.loaded else {
            return result(.notLoaded, reason: "\(cell.role.rawValue)_not_loaded")
        }
        guard cell.ready else {
            return result(.notReady, reason: "\(cell.role.rawValue)_not_ready")
        }
    }
    guard let support = fixture.support else {
        return result(.unsupported, reason: "missing_support")
    }

    switch support.shape {
    case .fullCube:
        break
    case .liquid:
        return result(.liquidUnsupported, reason: "liquid_support")
    case .empty:
        return result(.unsupported, reason: "empty_support")
    case .unknown:
        if support.shapeName.hasPrefix("special_") {
            return result(.unknown, reason: "unmodeled_special_shape")
        }
        return result(.unknown, reason: "unknown_support_shape")
    }

    switch fixture.feet.shape {
    case .empty:
        break
    case .fullCube:
        return result(.blocked, reason: "feet_full_cube_blocks_body")
    case .liquid:
        return result(.blocked, reason: "liquid_feet_blocks_occupancy")
    case .unknown:
        return result(.unknown, reason: "unknown_feet_shape")
    }

    switch fixture.head.shape {
    case .empty:
        return result(.occupable, reason: "full_cube_support_empty_body_volume")
    case .fullCube:
        return result(.verticalSpaceOccupied, reason: "head_full_cube_blocks_body")
    case .liquid:
        return result(.blocked, reason: "liquid_head_blocks_occupancy")
    case .unknown:
        return result(.unknown, reason: "unknown_head_shape")
    }
}
