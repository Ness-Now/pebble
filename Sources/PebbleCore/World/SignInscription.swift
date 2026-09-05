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

extension World {
    private func loadedMaterialIdentityOccurrences(_ materialID: Int) -> Int {
        chunks.values.reduce(into: 0) { count, chunk in
            count += chunk.blockEntities.values.reduce(into: 0) { matches, blockEntity in
                if blockEntity.signInscription?.materialID == materialID { matches += 1 }
            }
        }
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
        guard inscription.materialID < peekNextEntityId(),
              loadedMaterialIdentityOccurrences(inscription.materialID) == 1,
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
        guard loadedMaterialIdentityOccurrences(inscription.materialID) == 0 else {
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
