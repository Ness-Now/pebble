import Foundation

/// Actor-neutral identity for an immutable inscription on an existing sign.
/// The opaque content commitment has no semantic or truth meaning in Core.
/// Identity belongs to this material instance, not to a World coordinate.
public struct SignInscription: Codable, Equatable {
    public let artifactID: String
    public let materialID: Int
    public let contentDigest: String
    public let worldID: String
    public let dimension: Int
    public let x: Int
    public let y: Int
    public let z: Int
    public let lines: [String]

    public init(artifactID: String, materialID: Int, contentDigest: String, worldID: String,
                dimension: Int, x: Int, y: Int, z: Int, lines: [String]) throws {
        self.artifactID = artifactID; self.contentDigest = contentDigest
        self.materialID = materialID
        self.worldID = worldID; self.dimension = dimension
        self.x = x; self.y = y; self.z = z; self.lines = lines
        try validate()
    }

    public func validate() throws {
        guard materialID > 0, materialID < Int.max,
              (1...128).contains(worldID.utf8.count),
              artifactID.hasPrefix("inscription-"), artifactID.utf8.count == 76,
              artifactID.dropFirst(12).allSatisfy({ $0.isHexDigit && !$0.isUppercase }),
              contentDigest.utf8.count == 64,
              contentDigest.allSatisfy({ $0.isHexDigit && !$0.isUppercase }),
              Dim(rawValue: dimension) != nil,
              [x, y, z].allSatisfy({ (-30_000_000...30_000_000).contains($0) }),
              lines.count == 4,
              lines.allSatisfy({ (1...64).contains($0.utf8.count)
                && $0.unicodeScalars.allSatisfy { $0.value >= 32 && $0.value != 127 } }) else {
            throw SignInscriptionError.invalid
        }
    }
}

public enum SignInscriptionError: Error { case invalid, unavailable, occupied }

struct SignInscriptionMaterialLocation: Hashable {
    let dimension: Int
    let x: Int
    let y: Int
    let z: Int
}

private struct SignInscriptionPersistentChunkKey: Hashable {
    let dimension: Int
    let cx: Int
    let cz: Int
}

private struct SignInscriptionPersistentChunkState {
    let valid: Bool
    let claims: [Int: Set<SignInscriptionMaterialLocation>]
}

/// A World-global view derived from every persisted chunk record. It is shared
/// by all dimensions of one live World and updated only after a chunk batch is
/// durably committed. It is an integrity authority, not a second persistence
/// store: the physical inscriptions remain owned by their chunk block entities.
public final class SignInscriptionIdentityCatalog {
    public let worldID: String

    private let lock = NSLock()
    private var persistentSourceValid = true
    private var chunks: [SignInscriptionPersistentChunkKey: SignInscriptionPersistentChunkState] = [:]

    init(worldID: String) {
        self.worldID = worldID
    }

    func markPersistentSourceInvalid() {
        lock.lock()
        persistentSourceValid = false
        lock.unlock()
    }

    func markPersistentChunkInvalid(dimension: Int, cx: Int, cz: Int) {
        let key = SignInscriptionPersistentChunkKey(dimension: dimension, cx: cx, cz: cz)
        lock.lock()
        chunks[key] = SignInscriptionPersistentChunkState(valid: false, claims: [:])
        lock.unlock()
    }

    func replacePersistentChunkRecord(
        _ record: ChunkRecord,
        nextPhysicalIdentity: Int
    ) {
        let key = SignInscriptionPersistentChunkKey(
            dimension: record.dim,
            cx: record.cx,
            cz: record.cz
        )
        let state = scan(record, nextPhysicalIdentity: nextPhysicalIdentity)
        lock.lock()
        chunks[key] = state
        lock.unlock()
    }

    func replacePersistentChunkRecords(
        _ records: [ChunkRecord],
        nextPhysicalIdentity: Int
    ) {
        for record in records {
            replacePersistentChunkRecord(record, nextPhysicalIdentity: nextPhysicalIdentity)
        }
    }

    func validatedPersistentClaims() -> [Int: Set<SignInscriptionMaterialLocation>]? {
        lock.lock()
        defer { lock.unlock() }
        guard persistentSourceValid, chunks.values.allSatisfy(\.valid) else { return nil }
        var claims: [Int: Set<SignInscriptionMaterialLocation>] = [:]
        for state in chunks.values {
            for (materialID, locations) in state.claims {
                claims[materialID, default: []].formUnion(locations)
            }
        }
        return claims
    }

    private func scan(
        _ record: ChunkRecord,
        nextPhysicalIdentity: Int
    ) -> SignInscriptionPersistentChunkState {
        let blockEntities = record.blockEntities ?? []
        guard blockEntities.contains(where: { $0.signInscription != nil }) else {
            return SignInscriptionPersistentChunkState(valid: true, claims: [:])
        }
        guard record.worldId == worldID,
              let dimension = Dim(rawValue: record.dim),
              nextPhysicalIdentity > 0,
              let blocks = record.blocks,
              blocks.count == CHUNK_W * CHUNK_W * DIMS[dimension.rawValue].height else {
            return SignInscriptionPersistentChunkState(valid: false, claims: [:])
        }

        let info = DIMS[dimension.rawValue]
        var occupiedCells = Set<SignInscriptionMaterialLocation>()
        for blockEntity in blockEntities {
            let location = SignInscriptionMaterialLocation(
                dimension: record.dim,
                x: blockEntity.x,
                y: blockEntity.y,
                z: blockEntity.z
            )
            guard floorDiv(blockEntity.x, CHUNK_W) == record.cx,
                  floorDiv(blockEntity.z, CHUNK_W) == record.cz,
                  blockEntity.y >= info.minY,
                  blockEntity.y < info.minY + info.height,
                  occupiedCells.insert(location).inserted else {
                return SignInscriptionPersistentChunkState(valid: false, claims: [:])
            }
        }

        var claims: [Int: Set<SignInscriptionMaterialLocation>] = [:]
        for blockEntity in blockEntities {
            guard let inscription = blockEntity.signInscription else { continue }
            let location = SignInscriptionMaterialLocation(
                dimension: record.dim,
                x: blockEntity.x,
                y: blockEntity.y,
                z: blockEntity.z
            )
            let localX = posMod(blockEntity.x, CHUNK_W)
            let localZ = posMod(blockEntity.z, CHUNK_W)
            let index = ((blockEntity.y - info.minY) * CHUNK_W + localZ) * CHUNK_W + localX
            let blockID = Int(blocks[index] >> 4)
            do {
                try inscription.validate()
            } catch {
                return SignInscriptionPersistentChunkState(valid: false, claims: [:])
            }
            guard inscription.worldID == worldID,
                  inscription.dimension == record.dim,
                  inscription.x == blockEntity.x,
                  inscription.y == blockEntity.y,
                  inscription.z == blockEntity.z,
                  inscription.lines == blockEntity.lines,
                  inscription.materialID < nextPhysicalIdentity,
                  blockEntity.type == "sign",
                  blockDefs.indices.contains(blockID),
                  blockDefs[blockID].shape == .sign else {
                return SignInscriptionPersistentChunkState(valid: false, claims: [:])
            }
            claims[inscription.materialID, default: []].insert(location)
        }
        return SignInscriptionPersistentChunkState(valid: true, claims: claims)
    }
}

extension World {
    private func globallyUniqueMaterialIdentityClaims() throws
        -> [Int: Set<SignInscriptionMaterialLocation>] {
        var claims: [Int: Set<SignInscriptionMaterialLocation>]
        if let catalog = signInscriptionIdentityCatalog {
            guard let persistent = catalog.validatedPersistentClaims() else {
                throw SignInscriptionError.invalid
            }
            claims = persistent
        } else {
            claims = [:]
        }

        for chunk in chunks.values {
            var occupiedCells = Set<SignInscriptionMaterialLocation>()
            for blockEntity in chunk.blockEntities.values {
                let location = SignInscriptionMaterialLocation(
                    dimension: dim.rawValue,
                    x: blockEntity.x,
                    y: blockEntity.y,
                    z: blockEntity.z
                )
                guard floorDiv(blockEntity.x, CHUNK_W) == chunk.cx,
                      floorDiv(blockEntity.z, CHUNK_W) == chunk.cz,
                      chunk.inYRange(blockEntity.y),
                      occupiedCells.insert(location).inserted else {
                    throw SignInscriptionError.invalid
                }
                guard let inscription = blockEntity.signInscription else { continue }
                try inscription.validate()
                let blockID = getBlock(blockEntity.x, blockEntity.y, blockEntity.z) >> 4
                guard inscription.dimension == dim.rawValue,
                      inscription.x == blockEntity.x,
                      inscription.y == blockEntity.y,
                      inscription.z == blockEntity.z,
                      inscription.lines == blockEntity.lines,
                      inscription.materialID < peekNextEntityId(),
                      blockEntity.type == "sign",
                      blockDefs.indices.contains(blockID),
                      blockDefs[blockID].shape == .sign,
                      signInscriptionIdentityCatalog == nil
                        || inscription.worldID == signInscriptionIdentityCatalog?.worldID else {
                    throw SignInscriptionError.invalid
                }
                claims[inscription.materialID, default: []].insert(location)
            }
        }
        guard claims.values.allSatisfy({ $0.count == 1 }) else {
            throw SignInscriptionError.invalid
        }
        return claims
    }

    public func inspectSignInscription(at x: Int, _ y: Int, _ z: Int) throws -> SignInscription {
        guard [x, y, z].allSatisfy({ (-30_000_000...30_000_000).contains($0) }),
              let chunk = getChunkAt(x, z), chunk.inYRange(y),
              blockDefs.indices.contains(getBlock(x, y, z) >> 4),
              blockDefs[getBlock(x, y, z) >> 4].shape == .sign,
              let be = getBlockEntity(x, y, z), be.type == "sign",
              be.x == x, be.y == y, be.z == z,
              let inscription = be.signInscription else { throw SignInscriptionError.unavailable }
        try inscription.validate()
        let claims = try globallyUniqueMaterialIdentityClaims()
        guard claims[inscription.materialID]?.count == 1,
              inscription.x == x, inscription.y == y, inscription.z == z,
              inscription.dimension == dim.rawValue, inscription.lines == be.lines else {
            throw SignInscriptionError.invalid
        }
        return inscription
    }

    /// Writes no block and creates no item. The blank material support must
    /// already exist through ordinary Pebble placement/inventory semantics.
    public func inscribeSign(_ inscription: SignInscription) throws {
        try inscription.validate()
        let (x, y, z) = (inscription.x, inscription.y, inscription.z)
        guard inscription.dimension == dim.rawValue,
              let chunk = getChunkAt(x, z), chunk.inYRange(y),
              blockDefs.indices.contains(getBlock(x, y, z) >> 4),
              blockDefs[getBlock(x, y, z) >> 4].shape == .sign,
              let be = getBlockEntity(x, y, z), be.type == "sign",
              be.x == x, be.y == y, be.z == z else { throw SignInscriptionError.unavailable }
        guard be.signInscription == nil, be.lines == ["", "", "", ""] else {
            throw SignInscriptionError.occupied
        }
        let claims = try globallyUniqueMaterialIdentityClaims()
        guard claims[inscription.materialID] == nil,
              signInscriptionIdentityCatalog == nil
                || inscription.worldID == signInscriptionIdentityCatalog?.worldID else {
            throw SignInscriptionError.invalid
        }
        try claimPhysicalIdentity(inscription.materialID)
        be.lines = inscription.lines
        be.signInscription = inscription
        chunk.modified = true
    }

    /// A synchronous failed inscription releases its physical identity only
    /// while that exact inscription is still the last allocation. A later
    /// allocation or substituted material is a hard rollback failure.
    public func rollbackSignInscription(_ inscription: SignInscription) throws {
        let (x, y, z) = (inscription.x, inscription.y, inscription.z)
        guard let be = getBlockEntity(x, y, z), be.signInscription == inscription,
              be.lines == inscription.lines else { throw PhysicalIdentityError.rollbackUnverified }
        try rollbackPhysicalIdentity(inscription.materialID)
        be.lines = ["", "", "", ""]
        be.signInscription = nil
    }
}
