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

public enum SignInscriptionError: Error {
    case invalid
    case unavailable
    case occupied
    case staleAuthority
}

/// Opaque proof of a physical inscription observation. The generation is
/// diagnostic only: callers cannot construct or validate this token. A World
/// must revalidate it while holding its physical-authority critical section.
public struct SignInscriptionAuthorityObservation {
    public let inscription: SignInscription
    public let generation: UInt64

    fileprivate let worldIdentifier: ObjectIdentifier
    fileprivate let catalogIdentifier: ObjectIdentifier?

    fileprivate init(
        inscription: SignInscription,
        generation: UInt64,
        world: World,
        catalog: SignInscriptionIdentityCatalog?
    ) {
        self.inscription = inscription
        self.generation = generation
        worldIdentifier = ObjectIdentifier(world)
        catalogIdentifier = catalog.map(ObjectIdentifier.init)
    }
}

struct SignInscriptionMaterialLocation: Hashable, Codable {
    let dimension: Int
    let x: Int
    let y: Int
    let z: Int
}

struct SignInscriptionPersistentChunkKey: Hashable, Codable {
    let dimension: Int
    let cx: Int
    let cz: Int
}

struct SignInscriptionPersistentChunkState: Equatable {
    let valid: Bool
    let claims: [Int: Set<SignInscriptionMaterialLocation>]
}

struct SignInscriptionIndexClaim: Codable, Equatable {
    let materialID: Int
    let location: SignInscriptionMaterialLocation
}

struct SignInscriptionIndexEnvelope: Codable {
    let formatVersion: Int
    let valid: Bool
    let claims: [SignInscriptionIndexClaim]
}

private final class WeakInscriptionWorld {
    weak var value: World?
    init(_ value: World) { self.value = value }
}

/// World-global material-identity authority. Durable per-chunk claims come
/// from SaveDB's transactionally maintained compact index. Dirty unloaded
/// chunks stage an override, and every resident chunk supersedes both durable
/// and staged state. Physical observations carry a generation token; only a
/// revalidation/finalization closure under this same critical section may use
/// one to authorize an external publication.
public final class SignInscriptionIdentityCatalog {
    public let worldID: String

    private let lock = NSRecursiveLock()
    private var persistentSourceValid = true
    private var chunks: [SignInscriptionPersistentChunkKey: SignInscriptionPersistentChunkState] = [:]
    private var stagedChunks: [SignInscriptionPersistentChunkKey: SignInscriptionPersistentChunkState] = [:]
    private var worlds: [ObjectIdentifier: WeakInscriptionWorld] = [:]
    private var authorityGeneration: UInt64 = 0

    /// Default-nil deterministic concurrency seam used only by pebsmoke.
    public var testingReadCriticalSectionHook: (() -> Void)?

    init(worldID: String) {
        self.worldID = worldID
    }

    public var generation: UInt64 {
        withExclusive { authorityGeneration }
    }

    public func isCurrentGeneration(_ generation: UInt64) -> Bool {
        withExclusive { authorityGeneration == generation }
    }

    func register(_ world: World) {
        withExclusive {
            worlds[ObjectIdentifier(world)] = WeakInscriptionWorld(world)
        }
    }

    @discardableResult
    func withExclusive<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }

    func markPersistentSourceInvalid() {
        withExclusive {
            persistentSourceValid = false
            advanceGeneration()
        }
    }

    func markPersistentChunkInvalid(dimension: Int, cx: Int, cz: Int) {
        let key = SignInscriptionPersistentChunkKey(dimension: dimension, cx: cx, cz: cz)
        withExclusive {
            chunks[key] = SignInscriptionPersistentChunkState(valid: false, claims: [:])
            advanceGeneration()
        }
    }

    func replacePersistentStates(
        _ states: [SignInscriptionPersistentChunkKey: SignInscriptionPersistentChunkState]
    ) {
        withExclusive {
            chunks = states
            advanceGeneration()
        }
    }

    func stageCurrentChunkRecord(_ record: ChunkRecord) {
        let key = Self.key(for: record)
        let state = Self.scan(record, expectedWorldID: worldID)
        withExclusive {
            stagedChunks[key] = state
            advanceGeneration()
        }
    }

    /// Called by SaveDB while already holding this catalogue's recursive lock
    /// across SQLite commit. The entire durable batch becomes visible at once.
    func applyCommittedStates(
        _ states: [SignInscriptionPersistentChunkKey: SignInscriptionPersistentChunkState]
    ) {
        withExclusive {
            for (key, state) in states {
                chunks[key] = state
                if stagedChunks[key] == state { stagedChunks.removeValue(forKey: key) }
            }
            advanceGeneration()
        }
    }

    func withCurrentClaims<T>(
        nextPhysicalIdentity: Int,
        _ body: ([Int: Set<SignInscriptionMaterialLocation>], UInt64) throws -> T
    ) throws -> T {
        try withExclusive {
            guard persistentSourceValid, nextPhysicalIdentity > 0 else {
                throw SignInscriptionError.invalid
            }
            var current = chunks
            for (key, state) in stagedChunks { current[key] = state }

            var resident: [SignInscriptionPersistentChunkKey: SignInscriptionPersistentChunkState] = [:]
            var releasedWorlds: [ObjectIdentifier] = []
            for (identifier, reference) in worlds {
                guard let world = reference.value else {
                    releasedWorlds.append(identifier)
                    continue
                }
                for (key, state) in world.signInscriptionResidentChunkStates(expectedWorldID: worldID) {
                    if let existing = resident[key], existing != state {
                        throw SignInscriptionError.invalid
                    }
                    resident[key] = state
                }
            }
            for identifier in releasedWorlds { worlds.removeValue(forKey: identifier) }
            for (key, state) in resident { current[key] = state }
            guard current.values.allSatisfy(\.valid) else {
                throw SignInscriptionError.invalid
            }

            var claims: [Int: Set<SignInscriptionMaterialLocation>] = [:]
            for state in current.values {
                for (materialID, locations) in state.claims {
                    guard materialID > 0, materialID < nextPhysicalIdentity else {
                        throw SignInscriptionError.invalid
                    }
                    claims[materialID, default: []].formUnion(locations)
                }
            }
            guard claims.values.allSatisfy({ $0.count == 1 }) else {
                throw SignInscriptionError.invalid
            }
            testingReadCriticalSectionHook?()
            return try body(claims, authorityGeneration)
        }
    }

    static func key(for record: ChunkRecord) -> SignInscriptionPersistentChunkKey {
        SignInscriptionPersistentChunkKey(dimension: record.dim, cx: record.cx, cz: record.cz)
    }

    static func envelope(
        for state: SignInscriptionPersistentChunkState
    ) -> SignInscriptionIndexEnvelope {
        let claims = state.claims.flatMap { materialID, locations in
            locations.map { SignInscriptionIndexClaim(materialID: materialID, location: $0) }
        }.sorted {
            ($0.materialID, $0.location.dimension, $0.location.x, $0.location.y, $0.location.z)
                < ($1.materialID, $1.location.dimension, $1.location.x, $1.location.y, $1.location.z)
        }
        return SignInscriptionIndexEnvelope(formatVersion: 1, valid: state.valid, claims: claims)
    }

    static func state(
        from envelope: SignInscriptionIndexEnvelope,
        key: SignInscriptionPersistentChunkKey,
        nextPhysicalIdentity: Int
    ) -> SignInscriptionPersistentChunkState? {
        guard envelope.formatVersion == 1,
              nextPhysicalIdentity > 0,
              envelope.valid || envelope.claims.isEmpty else { return nil }
        if !envelope.valid {
            return SignInscriptionPersistentChunkState(valid: false, claims: [:])
        }
        guard let dimension = Dim(rawValue: key.dimension) else { return nil }
        let info = DIMS[dimension.rawValue]
        var occupied = Set<SignInscriptionMaterialLocation>()
        var claims: [Int: Set<SignInscriptionMaterialLocation>] = [:]
        for claim in envelope.claims {
            let location = claim.location
            guard claim.materialID > 0, claim.materialID < nextPhysicalIdentity,
                  location.dimension == key.dimension,
                  floorDiv(location.x, CHUNK_W) == key.cx,
                  floorDiv(location.z, CHUNK_W) == key.cz,
                  location.y >= info.minY, location.y < info.minY + info.height,
                  occupied.insert(location).inserted else { return nil }
            claims[claim.materialID, default: []].insert(location)
        }
        return SignInscriptionPersistentChunkState(valid: true, claims: claims)
    }

    static func scan(
        _ record: ChunkRecord,
        expectedWorldID: String?
    ) -> SignInscriptionPersistentChunkState {
        scan(
            dimension: record.dim,
            cx: record.cx,
            cz: record.cz,
            expectedWorldID: expectedWorldID,
            blocks: record.blocks,
            blockEntities: record.blockEntities ?? []
        )
    }

    static func scan(
        world: World,
        chunk: Chunk,
        expectedWorldID: String?
    ) -> SignInscriptionPersistentChunkState {
        scan(
            dimension: world.dim.rawValue,
            cx: chunk.cx,
            cz: chunk.cz,
            expectedWorldID: expectedWorldID,
            blocks: chunk.blocks,
            blockEntities: Array(chunk.blockEntities.values)
        )
    }

    private static func scan(
        dimension: Int,
        cx: Int,
        cz: Int,
        expectedWorldID: String?,
        blocks: [UInt16]?,
        blockEntities: [BlockEntityData]
    ) -> SignInscriptionPersistentChunkState {
        let inscribed = blockEntities.filter { $0.signInscription != nil }
        guard !inscribed.isEmpty else {
            return SignInscriptionPersistentChunkState(valid: true, claims: [:])
        }
        guard let dim = Dim(rawValue: dimension),
              let blocks,
              blocks.count == CHUNK_W * CHUNK_W * DIMS[dim.rawValue].height else {
            return SignInscriptionPersistentChunkState(valid: false, claims: [:])
        }

        let info = DIMS[dim.rawValue]
        var occupiedCells = Set<SignInscriptionMaterialLocation>()
        var claims: [Int: Set<SignInscriptionMaterialLocation>] = [:]
        for blockEntity in inscribed {
            guard let inscription = blockEntity.signInscription else { continue }
            let location = SignInscriptionMaterialLocation(
                dimension: dimension,
                x: blockEntity.x,
                y: blockEntity.y,
                z: blockEntity.z
            )
            let localX = posMod(blockEntity.x, CHUNK_W)
            let localZ = posMod(blockEntity.z, CHUNK_W)
            guard floorDiv(blockEntity.x, CHUNK_W) == cx,
                  floorDiv(blockEntity.z, CHUNK_W) == cz,
                  blockEntity.y >= info.minY,
                  blockEntity.y < info.minY + info.height,
                  occupiedCells.insert(location).inserted else {
                return SignInscriptionPersistentChunkState(valid: false, claims: [:])
            }
            let index = ((blockEntity.y - info.minY) * CHUNK_W + localZ) * CHUNK_W + localX
            let blockID = Int(blocks[index] >> 4)
            do {
                try inscription.validate()
            } catch {
                return SignInscriptionPersistentChunkState(valid: false, claims: [:])
            }
            guard expectedWorldID == nil || inscription.worldID == expectedWorldID,
                  inscription.dimension == dimension,
                  inscription.x == blockEntity.x,
                  inscription.y == blockEntity.y,
                  inscription.z == blockEntity.z,
                  inscription.lines == blockEntity.lines,
                  blockEntity.type == "sign",
                  blockDefs.indices.contains(blockID),
                  blockDefs[blockID].shape == .sign else {
                return SignInscriptionPersistentChunkState(valid: false, claims: [:])
            }
            claims[inscription.materialID, default: []].insert(location)
        }
        return SignInscriptionPersistentChunkState(valid: true, claims: claims)
    }

    private func advanceGeneration() {
        authorityGeneration = authorityGeneration == UInt64.max ? 1 : authorityGeneration + 1
    }
}

extension World {
    func signInscriptionResidentChunkStates(
        expectedWorldID: String?
    ) -> [SignInscriptionPersistentChunkKey: SignInscriptionPersistentChunkState] {
        var states: [SignInscriptionPersistentChunkKey: SignInscriptionPersistentChunkState] = [:]
        for chunk in chunks.values {
            let key = SignInscriptionPersistentChunkKey(
                dimension: dim.rawValue,
                cx: chunk.cx,
                cz: chunk.cz
            )
            states[key] = SignInscriptionIdentityCatalog.scan(
                world: self,
                chunk: chunk,
                expectedWorldID: expectedWorldID
            )
        }
        return states
    }

    private func withGloballyUniqueMaterialIdentityClaims<T>(
        _ body: ([Int: Set<SignInscriptionMaterialLocation>], UInt64) throws -> T
    ) throws -> T {
        if let catalog = signInscriptionIdentityCatalog {
            return try catalog.withCurrentClaims(nextPhysicalIdentity: peekNextEntityId(), body)
        }
        let states = signInscriptionResidentChunkStates(expectedWorldID: nil)
        guard states.values.allSatisfy(\.valid) else { throw SignInscriptionError.invalid }
        var claims: [Int: Set<SignInscriptionMaterialLocation>] = [:]
        for state in states.values {
            for (materialID, locations) in state.claims {
                claims[materialID, default: []].formUnion(locations)
            }
        }
        guard claims.keys.allSatisfy({ $0 > 0 && $0 < peekNextEntityId() }),
              claims.values.allSatisfy({ $0.count == 1 }) else {
            throw SignInscriptionError.invalid
        }
        return try body(claims, 0)
    }

    private func withInscriptionAuthorityLock<T>(_ body: () throws -> T) rethrows -> T {
        if let catalog = signInscriptionIdentityCatalog {
            return try catalog.withExclusive(body)
        }
        return try body()
    }

    private func currentInscriptionWorldID() -> String {
        signInscriptionIdentityCatalog?.worldID ?? ""
    }

    private func ensureAllClaimsUnique(_ claims: [Int: Set<SignInscriptionMaterialLocation>]) throws {
        guard claims.values.allSatisfy({ $0.count == 1 }) else {
            throw SignInscriptionError.invalid
        }
    }

    private func validatedSignInscription(
        at x: Int,
        _ y: Int,
        _ z: Int,
        claims: [Int: Set<SignInscriptionMaterialLocation>]
    ) throws -> SignInscription {
        guard [x, y, z].allSatisfy({ (-30_000_000...30_000_000).contains($0) }),
              let chunk = getChunkAt(x, z), chunk.inYRange(y),
              blockDefs.indices.contains(getBlock(x, y, z) >> 4),
              blockDefs[getBlock(x, y, z) >> 4].shape == .sign,
              let be = getBlockEntity(x, y, z), be.type == "sign",
              be.x == x, be.y == y, be.z == z,
              let inscription = be.signInscription else { throw SignInscriptionError.unavailable }
        try inscription.validate()
        try ensureAllClaimsUnique(claims)
        guard claims[inscription.materialID]?.count == 1,
              inscription.x == x, inscription.y == y, inscription.z == z,
              inscription.dimension == dim.rawValue, inscription.lines == be.lines else {
            throw SignInscriptionError.invalid
        }
        return inscription
    }

    public func observeSignInscriptionAuthority(
        at x: Int,
        _ y: Int,
        _ z: Int
    ) throws -> SignInscriptionAuthorityObservation {
        try withGloballyUniqueMaterialIdentityClaims { claims, generation in
            let inscription = try validatedSignInscription(at: x, y, z, claims: claims)
            return SignInscriptionAuthorityObservation(
                inscription: inscription,
                generation: generation,
                world: self,
                catalog: signInscriptionIdentityCatalog
            )
        }
    }

    /// Executes against the current physical authority without allowing its
    /// validation to escape the critical section. The closure is opaque to
    /// Core and must be owned by the adapter that bridges to an external state.
    public func withCurrentSignInscriptionAuthority<T>(
        at x: Int,
        _ y: Int,
        _ z: Int,
        _ body: (SignInscription) throws -> T
    ) throws -> T {
        try withGloballyUniqueMaterialIdentityClaims { claims, _ in
            let inscription = try validatedSignInscription(at: x, y, z, claims: claims)
            return try body(inscription)
        }
    }

    /// Linearization point for any publication authorized by observed physical
    /// inscriptions. Core revalidates only physical state, then runs an opaque
    /// closure while save/index authority remains locked. A generation change
    /// refuses before the closure can execute.
    public func withValidatedSignInscriptionAuthorities<T>(
        _ observations: [SignInscriptionAuthorityObservation],
        _ body: () throws -> T
    ) throws -> T {
        guard !observations.isEmpty,
              observations.allSatisfy({
                  $0.worldIdentifier == ObjectIdentifier(self)
                    && $0.catalogIdentifier == signInscriptionIdentityCatalog.map(ObjectIdentifier.init)
              }) else {
            throw SignInscriptionError.invalid
        }
        return try withGloballyUniqueMaterialIdentityClaims { claims, generation in
            guard observations.allSatisfy({ $0.generation == generation }) else {
                throw SignInscriptionError.staleAuthority
            }
            for observation in observations {
                let inscription = observation.inscription
                let current = try validatedSignInscription(
                    at: inscription.x,
                    inscription.y,
                    inscription.z,
                    claims: claims
                )
                guard current == inscription else { throw SignInscriptionError.staleAuthority }
            }
            return try body()
        }
    }

    public func inspectSignInscription(at x: Int, _ y: Int, _ z: Int) throws -> SignInscription {
        try observeSignInscriptionAuthority(at: x, y, z).inscription
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
        try withGloballyUniqueMaterialIdentityClaims { claims, _ in
            try ensureAllClaimsUnique(claims)
            guard claims[inscription.materialID] == nil,
                  signInscriptionIdentityCatalog == nil
                    || inscription.worldID == currentInscriptionWorldID() else {
                throw SignInscriptionError.invalid
            }
            try claimPhysicalIdentity(inscription.materialID)
            be.lines = inscription.lines
            be.signInscription = inscription
            chunk.modified = true
        }
    }

    /// A synchronous failed inscription releases its physical identity only
    /// while that exact inscription is still the last allocation. A later
    /// allocation or substituted material is a hard rollback failure.
    public func rollbackSignInscription(_ inscription: SignInscription) throws {
        let (x, y, z) = (inscription.x, inscription.y, inscription.z)
        try withInscriptionAuthorityLock {
            guard let be = getBlockEntity(x, y, z), be.signInscription == inscription,
                  be.lines == inscription.lines else { throw PhysicalIdentityError.rollbackUnverified }
            try rollbackPhysicalIdentity(inscription.materialID)
            be.lines = ["", "", "", ""]
            be.signInscription = nil
        }
    }

    /// Clears an exact failed candidate without releasing its identity. This is
    /// the conservative rollback used after authority could not be established:
    /// a concurrent save may already have made the identity externally visible.
    public func abandonSignInscription(_ inscription: SignInscription) throws {
        let (x, y, z) = (inscription.x, inscription.y, inscription.z)
        try withInscriptionAuthorityLock {
            guard let chunk = getChunkAt(x, z),
                  let be = getBlockEntity(x, y, z),
                  be.signInscription == inscription,
                  be.lines == inscription.lines else {
                throw PhysicalIdentityError.rollbackUnverified
            }
            be.lines = ["", "", "", ""]
            be.signInscription = nil
            chunk.modified = true
        }
    }
}
