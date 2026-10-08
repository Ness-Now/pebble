import Foundation

public enum WorldContinuationRestorationError: Error {
    case expired
    case incompatibleBoundary
    case unauthenticatedEntity
}

/// A proof issued by Core's synchronous persisted World entry. Existing Player
/// and chunk owners define semantics; short-lived object receipts distinguish
/// their restored incarnations from later replacements. Nothing is persisted.
public final class WorldContinuationRestorationAuthority {
    private struct Body {
        let entity: Entity
        let semantics: Data
        let width: Double
        let height: Double
        let noGravity: Bool
    }
    private weak var game: GameCore?
    private let world: World
    private let worldID: String
    private let recordBytes: Data
    private let boundary: WorldContinuationRecord
    private let playerReceipt: Body
    private let rules: [String: Double]
    private var chunks: [Int64: [Body]] = [:]
    private var invalid = false
    // Normal continuation materializes at most 270 cells' chunks plus the
    // nine spawn chunks. Receipts are bounded and expire with this callback.
    private static let maximumChunks = 279
    private static let maximumBodies = 32_768

    init(game: GameCore, world: World, record: WorldRecord,
         boundary: WorldContinuationRecord) throws {
        self.game = game; self.world = world; worldID = record.id
        recordBytes = try Self.bytes(record); self.boundary = boundary
        guard let player = game.player, player.world === world else {
            throw WorldContinuationRestorationError.incompatibleBoundary
        }
        playerReceipt = Body(entity: player, semantics: try Self.semanticBytes(player.save()),
            width: player.width, height: player.height, noGravity: player.noGravity)
        rules = world.gameRules
        for chunk in world.chunks.values.sorted(by: {
            $0.cx == $1.cx ? $0.cz < $1.cz : $0.cx < $1.cx
        }) {
            if let saved = game.db.getChunk(worldID, world.dim.rawValue, chunk.cx, chunk.cz) {
                try captureChunk(saved, game: game)
            }
        }
    }

    func matches(_ expected: WorldContinuationRecord) -> Bool {
        boundary.revision == expected.revision && boundary.payload == expected.payload
            && expected.payload != nil
    }

    private static func bytes<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(value)
    }

    /// Interpret only the typed subpayloads through their existing schema
    /// owners. This preserves the published historical 0/1 Boolean contract;
    /// arbitrary numeric siblings never become flags. Numeric fields retain
    /// the published standard-decoder Binary64 representation.
    private static func semanticBytes(_ raw: [String: Any]) throws -> Data {
        var value = raw
        func typed<T: Codable>(_ key: String, _ type: T.Type, _ schema: LegacyBooleanSchema) throws {
            guard let payload = value[key] else { return }
            guard let decoded = decodeLegacyBooleanJSON(type, from: payload, schema: schema,
                                                        options: [.fragmentsAllowed]) else {
                throw WorldContinuationRestorationError.unauthenticatedEntity
            }
            value[key] = try decodePersistenceJSON(bytes(decoded))
        }
        try typed("data", EntityData.self, .entityData)
        try typed("stack", ItemStack.self, .itemStack)
        try typed("offHand", ItemStack.self, .itemStack)
        for key in ["inventory", "enderChest", "armor", "chestItems"] {
            try typed(key, [ItemStack?].self, .itemStacks)
        }
        try typed("effects", [ActiveEffect].self, .effects)
        try typed("offers", [TradeOffer].self, .tradeOffers)
        return try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])
    }

    private func location(_ entity: Entity) throws -> Int64 {
        guard entity.x.isFinite, entity.y.isFinite, entity.z.isFinite,
              entity.x >= Double(Int.min), entity.x < Double(Int.max),
              entity.z >= Double(Int.min), entity.z < Double(Int.max) else {
            throw WorldContinuationRestorationError.unauthenticatedEntity
        }
        return chunkKey(floorDiv(ifloor(entity.x), 16), floorDiv(ifloor(entity.z), 16))
    }

    private func captureChunk(_ saved: ChunkRecord, game: GameCore) throws {
        let key = chunkKey(saved.cx, saved.cz)
        guard chunks[key] == nil, chunks.count < Self.maximumChunks,
              saved.entities.count <= Self.maximumBodies,
              chunks.values.reduce(0, { $0 + $1.count }) + saved.entities.count <= Self.maximumBodies else {
            throw WorldContinuationRestorationError.unauthenticatedEntity
        }
        let bodies = try world.entities.compactMap { $0 as? Entity }.filter {
            try game.isChunkPersistentEntity($0) && location($0) == key
        }
        guard bodies.count == saved.entities.count,
              Set(bodies.map(ObjectIdentifier.init)).count == bodies.count else {
            throw WorldContinuationRestorationError.unauthenticatedEntity
        }
        var remaining: [Data: Int] = [:]
        for row in saved.entities { remaining[try Self.semanticBytes(row), default: 0] += 1 }
        var receipt: [Body] = []
        for body in bodies {
            guard body.world === world, world.entityById[body.id] === body,
                  world.entities.filter({ $0 === body }).count == 1 else {
                throw WorldContinuationRestorationError.unauthenticatedEntity
            }
            let semantics = try Self.semanticBytes(body.save())
            guard let count = remaining[semantics], count > 0 else {
                throw WorldContinuationRestorationError.unauthenticatedEntity
            }
            remaining[semantics] = count - 1
            receipt.append(Body(entity: body, semantics: semantics, width: body.width,
                                height: body.height, noGravity: body.noGravity))
        }
        chunks[key] = receipt
    }

    /// Only Core's saved-chunk loader records newly restored objects. A new
    /// spawned mob or a semantic clone added by the adapter has no receipt.
    func noteRestoredChunk(in requested: World, record: ChunkRecord) {
        guard requested === world, let game else { return }
        do { try captureChunk(record, game: game) } catch { invalid = true }
    }

    private func validatedGame(in requested: World) throws -> GameCore {
        guard let game, game.isCurrentContinuationRestorationAuthority(self) else {
            throw WorldContinuationRestorationError.expired
        }
        guard !invalid, requested === world, game.hasWorld(), game.world === world,
              game.dim == world.dim, let current = game.worldRec, current.id == worldID,
              try Self.bytes(current) == recordBytes,
              let persisted = game.db.getWorld(worldID), try Self.bytes(persisted) == recordBytes,
              let selected = game.db.worldContinuation(worldID), matches(selected),
              let state = current.dims[String(world.dim.rawValue)],
              world.seed == UInt32(bitPattern: current.seed), world.time == state.time,
              world.dayTime == state.dayTime, world.raining == state.raining,
              world.thundering == state.thundering, world.weatherTimer == state.weatherTimer,
              world.difficulty == current.difficulty, world.gameRules == rules,
              let player = game.player, player === playerReceipt.entity, player.world === world, !player.dead,
              player.width == playerReceipt.width, player.height == playerReceipt.height,
              player.noGravity == playerReceipt.noGravity,
              try Self.semanticBytes(player.save()) == playerReceipt.semantics,
              world.entityById[player.id] === player,
              world.entities.filter({ $0 === player }).count == 1,
              game.worlds.values.flatMap({ $0.entities }).filter({ $0 is Player }).count == 1,
              let savedPlayer = game.db.getPlayer(worldID),
              (savedPlayer["dim"] as? NSNumber)?.intValue == world.dim.rawValue,
              let playerData = savedPlayer["data"] as? [String: Any],
              try Self.semanticBytes(player.save()) == Self.semanticBytes(playerData) else {
            throw WorldContinuationRestorationError.incompatibleBoundary
        }
        return game
    }

    private func validateBodies(game: GameCore, ignoring: Set<Int>) throws {
        let receipts = chunks.values.flatMap { $0 }
        for id in ignoring {
            if let body = world.entityById[id] as? Entity, !body.shouldSaveToChunk,
               !body.isPlayer, body.world === world { continue }
            guard let receipt = receipts.first(where: { $0.entity.id == id }),
                  let escrow = receipt.entity as? ItemEntity, escrow.custodyProvenance != nil else {
                throw WorldContinuationRestorationError.unauthenticatedEntity
            }
        }
        for (key, expected) in chunks {
            let current = try world.entities.compactMap { $0 as? Entity }.filter {
                try game.isChunkPersistentEntity($0) && location($0) == key
            }
            for body in current {
                guard expected.contains(where: { $0.entity === body }) else {
                    throw WorldContinuationRestorationError.unauthenticatedEntity
                }
            }
            for receipt in expected {
                let body = receipt.entity
                guard body.world === world, !body.dead, game.isChunkPersistentEntity(body),
                      try location(body) == key, body.width == receipt.width,
                      body.height == receipt.height, body.noGravity == receipt.noGravity,
                      try Self.semanticBytes(body.save()) == receipt.semantics else {
                    throw WorldContinuationRestorationError.unauthenticatedEntity
                }
                let occurrences = world.entities.filter { $0 === body }.count
                if ignoring.contains(body.id), let escrow = body as? ItemEntity,
                   escrow.custodyProvenance != nil, occurrences == 0 {
                    guard world.entityById[body.id] == nil else {
                        throw WorldContinuationRestorationError.unauthenticatedEntity
                    }
                } else {
                    guard occurrences == 1, world.entityById[body.id] === body else {
                        throw WorldContinuationRestorationError.unauthenticatedEntity
                    }
                }
            }
        }
    }

    /// Returned IDs index only authenticated current objects in this process.
    /// They are never persisted or compared with a previous process's IDs.
    public func authenticatedCollisionIDs(
        in requestedWorld: World, at positions: [EntityPlacementPosition],
        bodyWidth: Double, bodyHeight: Double, ignoringEntityIDs: Set<Int> = []
    ) throws -> Set<Int> {
        let game = try validatedGame(in: requestedWorld)
        guard positions.count <= 4096, bodyWidth.isFinite, bodyHeight.isFinite,
              bodyWidth > 0, bodyWidth <= 1, bodyHeight > 0,
              bodyHeight <= Double(world.info.height) else {
            throw WorldContinuationRestorationError.incompatibleBoundary
        }
        try validateBodies(game: game, ignoring: ignoringEntityIDs)
        var result = Set<Int>()
        let restored = chunks.values.flatMap { $0 }.map(\.entity)
        for position in positions {
            let assessment = assessEntityPlacement(in: world, at: position,
                bodyWidth: bodyWidth, bodyHeight: bodyHeight, ignoringEntityIDs: ignoringEntityIDs)
            for reference in world.getEntitiesInBox(assessment.body) where !ignoringEntityIDs.contains(reference.id) {
                guard let entity = reference as? Entity, entity.world === world,
                      world.entityById[entity.id] === entity,
                      world.entities.filter({ $0 === entity }).count == 1,
                      entity === game.player || restored.contains(where: { $0 === entity }) else {
                    throw WorldContinuationRestorationError.unauthenticatedEntity
                }
                result.insert(entity.id)
            }
        }
        _ = try validatedGame(in: requestedWorld)
        return result
    }
}
