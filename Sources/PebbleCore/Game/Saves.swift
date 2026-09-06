// Persistence — a single SQLite database at
// ~/Library/Application Support/Pebble/pebble.db (WAL mode, fully mutexed):
//   worlds(id, json, lastPlayed)            — world metadata + global state
//   chunks(world, dim, cx, cz, data BLOB)   — modified chunks (VCK1 binary)
//   player(world, json)                     — player snapshot per world
//   advancements(world, json)               — earned advancement ids per world
//   world_receipts(world, kind, receiptID)  — bounded physical-boundary evidence
// Legacy installs stored loose files under saves/; they are imported once on
// first open and the old folder is kept as saves-legacy-backup. Chunk records
// keep the VCK1 container (binary blocks + JSON tail); entity-only records
// regenerate terrain from seed and re-attach saved entities.

import Foundation
import CryptoKit
import SQLite3

public struct DimState: Codable {
    public var time: Int
    public var dayTime: Int
    public var raining: Bool
    public var thundering: Bool
    public var weatherTimer: Int

    public init(time: Int = 0, dayTime: Int = 1000, raining: Bool = false,
                thundering: Bool = false, weatherTimer: Int = 24000) {
        self.time = time
        self.dayTime = dayTime
        self.raining = raining
        self.thundering = thundering
        self.weatherTimer = weatherTimer
    }
}

/// single source of truth for the app version — the title screen, the F3
/// overlay and save records all read this (Info.plist is bumped separately
/// at packaging time)
public let PEBBLE_VERSION = "1.0.2"

/// WorldMeta + the global-state extension (baseline WorldRecord extends WorldMeta)
public struct WorldRecord: Codable {
    public var id: String
    public var name: String
    public var seed: Int32
    public var gameMode: Int
    public var difficulty: Int
    public var lastPlayed: Double      // ms epoch, like Date.now()
    public var version: String
    /// keyed by dim rawValue as a string — Swift encodes [Int:] dicts as JSON
    /// arrays, and the record should read as `{"0": {...}, "1": {...}}` on disk
    public var dims: [String: DimState]
    public var spawnX: Int
    public var spawnY: Int
    public var spawnZ: Int
    public var gameRules: [String: Double]
    public var dragonKilled: Bool
    public var gatewaysSpawned: Int
    public var nextEntityId: Int

    public init(id: String, name: String, seed: Int32, gameMode: Int, difficulty: Int) {
        self.id = id
        self.name = name
        self.seed = seed
        self.gameMode = gameMode
        self.difficulty = difficulty
        lastPlayed = Date().timeIntervalSince1970 * 1000
        version = "pebble-\(PEBBLE_VERSION)"
        dims = ["0": DimState(), "1": DimState(), "2": DimState()]
        spawnX = 0
        spawnY = 80
        spawnZ = 0
        gameRules = [:]
        dragonKilled = false
        gatewaysSpawned = 0
        nextEntityId = 1
    }
}

public struct ChunkRecord {
    public var key: String
    public var worldId: String
    public var dim: Int
    public var cx: Int
    public var cz: Int
    /// absent on entity-only records: the chunk itself regenerates from seed
    public var blocks: [UInt16]?
    public var biomes: [UInt8]?
    public var blockEntities: [BlockEntityData]?
    public var entities: [[String: Any]]

    public init(key: String, worldId: String, dim: Int, cx: Int, cz: Int,
                blocks: [UInt16]? = nil, biomes: [UInt8]? = nil,
                blockEntities: [BlockEntityData]? = nil, entities: [[String: Any]] = []) {
        self.key = key
        self.worldId = worldId
        self.dim = dim
        self.cx = cx
        self.cz = cz
        self.blocks = blocks
        self.biomes = biomes
        self.blockEntities = blockEntities
        self.entities = entities
    }
}

/// JSON can't carry NaN/Infinity (structured clone could) — scrub them so one
/// blown-up velocity never poisons a whole chunk record
private func sanitizeJSON(_ v: Any) -> Any {
    if let d = v as? Double { return d.isFinite ? d : 0 }
    if let arr = v as? [Any] { return arr.map(sanitizeJSON) }
    if let dict = v as? [String: Any] { return dict.mapValues(sanitizeJSON) }
    return v
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

public struct SignInscriptionIndexLoadMetrics: Equatable {
    public let indexedChunkRows: Int
    public let migratedChunkPayloads: Int
    public let decodedVoxelCells: Int

    public init(indexedChunkRows: Int = 0, migratedChunkPayloads: Int = 0,
                decodedVoxelCells: Int = 0) {
        self.indexedChunkRows = indexedChunkRows
        self.migratedChunkPayloads = migratedChunkPayloads
        self.decodedVoxelCells = decodedVoxelCells
    }
}

public enum SignInscriptionPersistencePhase: String {
    case prepared
    case transactionBegan
    case beforeCommit
    case committedBeforeAuthority
    case authorityAdvanced
    case failed
}

public final class SaveDB {
    private var db: OpaquePointer?
    private let databaseLock = NSRecursiveLock()
    private var signInscriptionIndexSchemaReady = false
    public private(set) var lastSignInscriptionIndexLoadMetrics = SignInscriptionIndexLoadMetrics()

    /// Default-nil deterministic fault/concurrency seam used by pebsmoke.
    /// Returning false asks the current chunk transaction to roll back.
    public var testingSignInscriptionPersistenceHook: ((SignInscriptionPersistencePhase) -> Bool)?

    public init() {
        let url = vcSupportDir().appendingPathComponent("pebble.db")
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(url.path, &db, flags, nil) == SQLITE_OK else {
            fatalError("pebble.db could not be opened: \(String(cString: sqlite3_errmsg(db)))")
        }
        exec("PRAGMA journal_mode=WAL")
        exec("PRAGMA synchronous=NORMAL")
        exec("PRAGMA busy_timeout=5000")
        exec("""
        CREATE TABLE IF NOT EXISTS worlds(
            id TEXT PRIMARY KEY, json TEXT NOT NULL, lastPlayed REAL NOT NULL DEFAULT 0)
        """)
        exec("""
        CREATE TABLE IF NOT EXISTS chunks(
            world TEXT NOT NULL, dim INTEGER NOT NULL, cx INTEGER NOT NULL, cz INTEGER NOT NULL,
            data BLOB NOT NULL,
            inscriptionIndexVersion INTEGER NOT NULL DEFAULT 0,
            inscriptionIndexDigest TEXT NOT NULL DEFAULT '',
            PRIMARY KEY(world, dim, cx, cz)) WITHOUT ROWID
        """)
        exec("CREATE TABLE IF NOT EXISTS player(world TEXT PRIMARY KEY, json TEXT NOT NULL)")
        exec("CREATE TABLE IF NOT EXISTS advancements(world TEXT PRIMARY KEY, json TEXT NOT NULL)")
        exec("""
        CREATE TABLE IF NOT EXISTS world_receipts(
            world TEXT NOT NULL, kind TEXT NOT NULL, receiptID TEXT NOT NULL,
            data BLOB NOT NULL, PRIMARY KEY(world, kind, receiptID)) WITHOUT ROWID
        """)
        signInscriptionIndexSchemaReady = ensureSignInscriptionIndexSchema()
        migrateLegacySaves()
    }

    deinit { sqlite3_close(db) }

    // ---- tiny statement helpers -------------------------------------------------
    @discardableResult
    private func exec(_ sql: String) -> Bool {
        databaseLock.lock()
        defer { databaseLock.unlock() }
        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            print("[saves] exec failed: \(String(cString: sqlite3_errmsg(db))) — \(sql.prefix(60))")
            return false
        }
        return true
    }

    /// prepare + bind + step a statement; row() is called once per result row.
    /// returns false (and logs) on prepare/step errors — a silently failed
    /// write (disk full, SQLITE_ERROR) is data loss
    @discardableResult
    private func run(_ sql: String, bind: ((OpaquePointer) -> Void)? = nil,
                     row: ((OpaquePointer) -> Void)? = nil) -> Bool {
        databaseLock.lock()
        defer { databaseLock.unlock() }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else {
            print("[saves] prepare failed: \(String(cString: sqlite3_errmsg(db))) — \(sql.prefix(60))")
            return false
        }
        defer { sqlite3_finalize(stmt) }
        bind?(stmt)
        var rc = sqlite3_step(stmt)
        while rc == SQLITE_ROW { row?(stmt); rc = sqlite3_step(stmt) }
        if rc != SQLITE_DONE {
            print("[saves] step failed (\(rc)): \(String(cString: sqlite3_errmsg(db))) — \(sql.prefix(60))")
            return false
        }
        return true
    }

    private func bindText(_ stmt: OpaquePointer, _ idx: Int32, _ s: String) {
        sqlite3_bind_text(stmt, idx, s, -1, SQLITE_TRANSIENT)
    }
    private func bindData(_ stmt: OpaquePointer, _ idx: Int32, _ data: Data) {
        _ = data.withUnsafeBytes { bytes in
            sqlite3_bind_blob(
                stmt, idx, bytes.baseAddress, Int32(bytes.count),
                SQLITE_TRANSIENT
            )
        }
    }
    private func columnText(_ stmt: OpaquePointer, _ idx: Int32) -> String? {
        sqlite3_column_text(stmt, idx).map { String(cString: $0) }
    }
    private func columnData(_ stmt: OpaquePointer, _ idx: Int32) -> Data? {
        guard let bytes = sqlite3_column_blob(stmt, idx) else { return nil }
        return Data(
            bytes: bytes,
            count: Int(sqlite3_column_bytes(stmt, idx))
        )
    }

    // ---- worlds ---------------------------------------------------------------
    public func listWorlds() -> [WorldRecord] {
        var out: [WorldRecord] = []
        run("SELECT json FROM worlds", row: { stmt in
            if let json = self.columnText(stmt, 0),
               let rec = try? JSONDecoder().decode(WorldRecord.self, from: Data(json.utf8)) {
                out.append(rec)
            }
        })
        return out
    }
    public func getWorld(_ id: String) -> WorldRecord? {
        var rec: WorldRecord?
        run("SELECT json FROM worlds WHERE id=?", bind: { self.bindText($0, 1, id) }) { stmt in
            if let json = self.columnText(stmt, 0) {
                rec = try? JSONDecoder().decode(WorldRecord.self, from: Data(json.utf8))
            }
        }
        return rec
    }
    public func putWorld(_ rec: WorldRecord) {
        guard let data = try? JSONEncoder().encode(rec), let json = String(data: data, encoding: .utf8) else { return }
        run("INSERT OR REPLACE INTO worlds(id, json, lastPlayed) VALUES(?,?,?)", bind: { stmt in
            self.bindText(stmt, 1, rec.id)
            self.bindText(stmt, 2, json)
            sqlite3_bind_double(stmt, 3, rec.lastPlayed)
        })
    }
    public func deleteWorld(_ id: String) {
        databaseLock.lock()
        defer { databaseLock.unlock() }
        exec("BEGIN")
        for table in [
            "worlds", "chunks", "player", "advancements", "world_receipts",
            "sign_inscription_chunks",
        ] {
            let col = table == "worlds" ? "id" : "world"
            run("DELETE FROM \(table) WHERE \(col)=?", bind: { self.bindText($0, 1, id) })
        }
        exec("COMMIT")
    }

    // ---- World-side physical receipts ---------------------------------------

    /// Inserts immutable physical-boundary evidence. `false` means the row was
    /// not inserted (invalid input, duplicate identity, or storage failure).
    /// Callers own bounded retention and cross-authority rollback.
    @discardableResult
    public func putWorldReceiptIfAbsent(
        worldID: String,
        kind: String,
        receiptID: String,
        data: Data
    ) -> Bool {
        guard (1...240).contains(worldID.count),
              (1...64).contains(kind.count),
              (1...160).contains(receiptID.count),
              !data.isEmpty, data.count <= 1_048_576,
              [worldID, kind, receiptID].allSatisfy({ value in
                  value.allSatisfy { $0.isASCII && !$0.isNewline }
              }),
              getWorldReceipt(
                worldID: worldID, kind: kind, receiptID: receiptID
              ) == nil else {
            return false
        }
        let ok = run(
            "INSERT OR IGNORE INTO world_receipts(world,kind,receiptID,data) "
                + "VALUES(?,?,?,?)",
            bind: { statement in
                self.bindText(statement, 1, worldID)
                self.bindText(statement, 2, kind)
                self.bindText(statement, 3, receiptID)
                self.bindData(statement, 4, data)
            }
        )
        return ok && sqlite3_changes(db) == 1
    }

    public func getWorldReceipt(
        worldID: String,
        kind: String,
        receiptID: String
    ) -> Data? {
        var value: Data?
        _ = run(
            "SELECT data FROM world_receipts WHERE world=? AND kind=? "
                + "AND receiptID=?",
            bind: { statement in
                self.bindText(statement, 1, worldID)
                self.bindText(statement, 2, kind)
                self.bindText(statement, 3, receiptID)
            },
            row: { statement in value = self.columnData(statement, 0) }
        )
        return value
    }

    public func listWorldReceipts(
        worldID: String,
        kind: String
    ) -> [(receiptID: String, data: Data)] {
        var values: [(String, Data)] = []
        _ = run(
            "SELECT receiptID,data FROM world_receipts WHERE world=? "
                + "AND kind=? ORDER BY receiptID",
            bind: { statement in
                self.bindText(statement, 1, worldID)
                self.bindText(statement, 2, kind)
            },
            row: { statement in
                guard let receiptID = self.columnText(statement, 0),
                      let data = self.columnData(statement, 1) else { return }
                values.append((receiptID, data))
            }
        )
        return values
    }

    @discardableResult
    public func deleteWorldReceipt(
        worldID: String,
        kind: String,
        receiptID: String
    ) -> Bool {
        let ok = run(
            "DELETE FROM world_receipts WHERE world=? AND kind=? AND receiptID=?",
            bind: { statement in
                self.bindText(statement, 1, worldID)
                self.bindText(statement, 2, kind)
                self.bindText(statement, 3, receiptID)
            }
        )
        return ok && sqlite3_changes(db) == 1
    }

    // ---- chunks ---------------------------------------------------------------
    public func chunkKey(_ worldId: String, _ dim: Int, _ cx: Int, _ cz: Int) -> String {
        "\(worldId):\(dim):\(cx),\(cz)"
    }

    /// all saved chunk keys for a world — lets the streamer skip the DB for fresh chunks
    public func getChunkKeys(_ worldId: String) -> Set<String> {
        var keys = Set<String>()
        run("SELECT dim, cx, cz FROM chunks WHERE world=?", bind: { self.bindText($0, 1, worldId) }) { stmt in
            let dim = Int(sqlite3_column_int(stmt, 0))
            let cx = Int(sqlite3_column_int(stmt, 1))
            let cz = Int(sqlite3_column_int(stmt, 2))
            keys.insert(self.chunkKey(worldId, dim, cx, cz))
        }
        return keys
    }

    public func getChunk(_ worldId: String, _ dim: Int, _ cx: Int, _ cz: Int) -> ChunkRecord? {
        var rec: ChunkRecord?
        run("SELECT data FROM chunks WHERE world=? AND dim=? AND cx=? AND cz=?", bind: { stmt in
            self.bindText(stmt, 1, worldId)
            sqlite3_bind_int(stmt, 2, Int32(dim))
            sqlite3_bind_int(stmt, 3, Int32(cx))
            sqlite3_bind_int(stmt, 4, Int32(cz))
        }) { stmt in
            if let bytes = sqlite3_column_blob(stmt, 0) {
                let count = Int(sqlite3_column_bytes(stmt, 0))
                let data = Data(bytes: bytes, count: count)
                rec = self.decodeChunk(data, key: self.chunkKey(worldId, dim, cx, cz),
                                       worldId: worldId, dim: dim, cx: cx, cz: cz)?.record
            }
        }
        return rec
    }

    /// Loads only compact inscription metadata during normal World entry.
    /// Pre-index saves are migrated once by decoding just their version-zero
    /// chunk rows; subsequent opens never decode voxel payloads for CIV-45.
    public func loadSignInscriptionIdentityCatalog(
        worldID: String,
        nextPhysicalIdentity: Int
    ) -> SignInscriptionIdentityCatalog {
        let catalog = SignInscriptionIdentityCatalog(worldID: worldID)
        databaseLock.lock()
        defer { databaseLock.unlock() }
        lastSignInscriptionIndexLoadMetrics = SignInscriptionIndexLoadMetrics()
        guard signInscriptionIndexSchemaReady,
              migrateLegacySignInscriptionRows(worldID: worldID) else {
            catalog.markPersistentSourceInvalid()
            return catalog
        }

        var states: [SignInscriptionPersistentChunkKey: SignInscriptionPersistentChunkState] = [:]
        var indexedRows = 0
        var sourceValid = true
        let loaded = run(
            """
            SELECT c.dim,c.cx,c.cz,c.inscriptionIndexVersion,c.inscriptionIndexDigest,
                   i.chunkVersion,i.digest,i.data
            FROM chunks c
            LEFT JOIN sign_inscription_chunks i
              ON i.world=c.world AND i.dim=c.dim AND i.cx=c.cx AND i.cz=c.cz
            WHERE c.world=? ORDER BY c.dim,c.cx,c.cz
            """,
            bind: { self.bindText($0, 1, worldID) },
            row: { statement in
                indexedRows += 1
                let key = SignInscriptionPersistentChunkKey(
                    dimension: Int(sqlite3_column_int(statement, 0)),
                    cx: Int(sqlite3_column_int(statement, 1)),
                    cz: Int(sqlite3_column_int(statement, 2))
                )
                let chunkVersion = Int64(sqlite3_column_int64(statement, 3))
                let chunkDigest = self.columnText(statement, 4)
                guard sqlite3_column_type(statement, 5) != SQLITE_NULL,
                      let chunkDigest,
                      chunkVersion > 0,
                      Int64(sqlite3_column_int64(statement, 5)) == chunkVersion,
                      let indexDigest = self.columnText(statement, 6),
                      indexDigest == chunkDigest,
                      let data = self.columnData(statement, 7),
                      self.signInscriptionIndexDigest(data) == chunkDigest,
                      let envelope = try? JSONDecoder().decode(
                        SignInscriptionIndexEnvelope.self,
                        from: data
                      ),
                      let state = SignInscriptionIdentityCatalog.state(
                        from: envelope,
                        key: key,
                        nextPhysicalIdentity: nextPhysicalIdentity
                      ) else {
                    sourceValid = false
                    states[key] = SignInscriptionPersistentChunkState(valid: false, claims: [:])
                    return
                }
                states[key] = state
            }
        )
        var extraRows = 0
        let extrasLoaded = run(
            """
            SELECT COUNT(*) FROM sign_inscription_chunks i
            LEFT JOIN chunks c
              ON c.world=i.world AND c.dim=i.dim AND c.cx=i.cx AND c.cz=i.cz
            WHERE i.world=? AND c.world IS NULL
            """,
            bind: { self.bindText($0, 1, worldID) },
            row: { extraRows = Int(sqlite3_column_int64($0, 0)) }
        )
        sourceValid = sourceValid && loaded && extrasLoaded && extraRows == 0
        lastSignInscriptionIndexLoadMetrics = SignInscriptionIndexLoadMetrics(
            indexedChunkRows: indexedRows,
            migratedChunkPayloads: lastSignInscriptionIndexLoadMetrics.migratedChunkPayloads,
            decodedVoxelCells: lastSignInscriptionIndexLoadMetrics.decodedVoxelCells
        )
        catalog.replacePersistentStates(states)
        if !sourceValid { catalog.markPersistentSourceInvalid() }
        return catalog
    }

    /// Chunk payload and compact inscription index commit in one SQLite
    /// transaction. When a live catalogue is supplied, its lock spans commit
    /// and one atomic batch advancement, making reads linearizable.
    @discardableResult
    public func putChunks(
        _ records: [ChunkRecord],
        nextPhysicalIdentity: Int? = nil,
        inscriptionCatalog: SignInscriptionIdentityCatalog? = nil
    ) -> Bool {
        guard !records.isEmpty else { return true }
        guard signInscriptionIndexSchemaReady else { return false }
        var prepared: [(record: ChunkRecord, chunkData: Data,
                        state: SignInscriptionPersistentChunkState,
                        indexData: Data, digest: String)] = []
        for record in records {
            guard inscriptionCatalog == nil || inscriptionCatalog?.worldID == record.worldId,
                  let chunkData = encodeChunk(record) else { return false }
            let state = SignInscriptionIdentityCatalog.scan(
                record,
                expectedWorldID: record.worldId
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            guard let indexData = try? encoder.encode(
                SignInscriptionIdentityCatalog.envelope(for: state)
            ) else { return false }
            prepared.append((record, chunkData, state, indexData, signInscriptionIndexDigest(indexData)))
        }
        if let nextPhysicalIdentity {
            guard nextPhysicalIdentity > 0,
                  prepared.allSatisfy({ item in
                    item.state.claims.keys.allSatisfy { $0 < nextPhysicalIdentity }
                  }) else { return false }
        }
        guard testingSignInscriptionPersistenceHook?(.prepared) ?? true else {
            _ = testingSignInscriptionPersistenceHook?(.failed)
            return false
        }

        let commit = {
            self.databaseLock.lock()
            defer { self.databaseLock.unlock() }
            guard self.exec("BEGIN IMMEDIATE") else {
                _ = self.testingSignInscriptionPersistenceHook?(.failed)
                return false
            }
            guard self.testingSignInscriptionPersistenceHook?(.transactionBegan) ?? true else {
                _ = self.exec("ROLLBACK")
                _ = self.testingSignInscriptionPersistenceHook?(.failed)
                return false
            }
            if let nextPhysicalIdentity {
                for worldID in Set(prepared.map(\.record.worldId)).sorted() {
                    guard self.advanceWorldPhysicalIdentity(
                        worldID: worldID,
                        toAtLeast: nextPhysicalIdentity
                    ) else {
                        _ = self.exec("ROLLBACK")
                        _ = self.testingSignInscriptionPersistenceHook?(.failed)
                        return false
                    }
                }
            }
            var committedStates: [SignInscriptionPersistentChunkKey: SignInscriptionPersistentChunkState] = [:]
            var ok = true
            for item in prepared {
                let record = item.record
                var oldVersion: Int64 = 0
                let readVersion = self.run(
                    "SELECT inscriptionIndexVersion FROM chunks WHERE world=? AND dim=? AND cx=? AND cz=?",
                    bind: { statement in
                        self.bindText(statement, 1, record.worldId)
                        sqlite3_bind_int(statement, 2, Int32(record.dim))
                        sqlite3_bind_int(statement, 3, Int32(record.cx))
                        sqlite3_bind_int(statement, 4, Int32(record.cz))
                    },
                    row: { oldVersion = sqlite3_column_int64($0, 0) }
                )
                guard readVersion, oldVersion < Int64.max else { ok = false; break }
                let version = max(1, oldVersion + 1)
                let wroteChunk = self.run(
                    """
                    INSERT INTO chunks(world,dim,cx,cz,data,inscriptionIndexVersion,inscriptionIndexDigest)
                    VALUES(?,?,?,?,?,?,?)
                    ON CONFLICT(world,dim,cx,cz) DO UPDATE SET
                      data=excluded.data,
                      inscriptionIndexVersion=excluded.inscriptionIndexVersion,
                      inscriptionIndexDigest=excluded.inscriptionIndexDigest
                    """,
                    bind: { statement in
                        self.bindText(statement, 1, record.worldId)
                        sqlite3_bind_int(statement, 2, Int32(record.dim))
                        sqlite3_bind_int(statement, 3, Int32(record.cx))
                        sqlite3_bind_int(statement, 4, Int32(record.cz))
                        self.bindData(statement, 5, item.chunkData)
                        sqlite3_bind_int64(statement, 6, version)
                        self.bindText(statement, 7, item.digest)
                    }
                )
                let wroteIndex = self.putSignInscriptionIndexRow(
                    worldID: record.worldId,
                    key: SignInscriptionIdentityCatalog.key(for: record),
                    version: version,
                    digest: item.digest,
                    data: item.indexData
                )
                ok = ok && wroteChunk && wroteIndex
                committedStates[SignInscriptionIdentityCatalog.key(for: record)] = item.state
                if !ok { break }
            }
            guard ok, self.testingSignInscriptionPersistenceHook?(.beforeCommit) ?? true,
                  self.exec("COMMIT") else {
                _ = self.exec("ROLLBACK")
                _ = self.testingSignInscriptionPersistenceHook?(.failed)
                return false
            }
            _ = self.testingSignInscriptionPersistenceHook?(.committedBeforeAuthority)
            inscriptionCatalog?.applyCommittedStates(committedStates)
            _ = self.testingSignInscriptionPersistenceHook?(.authorityAdvanced)
            return true
        }
        if let inscriptionCatalog {
            return inscriptionCatalog.withExclusive(commit)
        }
        return commit()
    }

    private func ensureSignInscriptionIndexSchema() -> Bool {
        databaseLock.lock()
        defer { databaseLock.unlock() }
        var columns = Set<String>()
        guard run("PRAGMA table_info(chunks)", row: { statement in
            if let name = self.columnText(statement, 1) { columns.insert(name) }
        }) else { return false }
        if !columns.contains("inscriptionIndexVersion"),
           !exec("ALTER TABLE chunks ADD COLUMN inscriptionIndexVersion INTEGER NOT NULL DEFAULT 0") {
            return false
        }
        if !columns.contains("inscriptionIndexDigest"),
           !exec("ALTER TABLE chunks ADD COLUMN inscriptionIndexDigest TEXT NOT NULL DEFAULT ''") {
            return false
        }
        return exec("""
        CREATE TABLE IF NOT EXISTS sign_inscription_chunks(
            world TEXT NOT NULL, dim INTEGER NOT NULL, cx INTEGER NOT NULL, cz INTEGER NOT NULL,
            chunkVersion INTEGER NOT NULL, digest TEXT NOT NULL, data BLOB NOT NULL,
            PRIMARY KEY(world, dim, cx, cz)) WITHOUT ROWID
        """)
    }

    /// Version-zero means a row predates the compact index. Migration is one
    /// SQLite transaction: an interruption leaves version zero and retries on
    /// the next open; a committed migration is never decoded again.
    private func migrateLegacySignInscriptionRows(worldID: String) -> Bool {
        databaseLock.lock()
        defer { databaseLock.unlock() }
        var legacyRows: [(key: SignInscriptionPersistentChunkKey, data: Data)] = []
        guard run(
            """
            SELECT dim,cx,cz,data FROM chunks
            WHERE world=? AND inscriptionIndexVersion=0 ORDER BY dim,cx,cz
            """,
            bind: { self.bindText($0, 1, worldID) },
            row: { statement in
                guard let data = self.columnData(statement, 3) else { return }
                legacyRows.append((
                    SignInscriptionPersistentChunkKey(
                        dimension: Int(sqlite3_column_int(statement, 0)),
                        cx: Int(sqlite3_column_int(statement, 1)),
                        cz: Int(sqlite3_column_int(statement, 2))
                    ),
                    data
                ))
            }
        ) else { return false }
        guard !legacyRows.isEmpty else { return true }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        var prepared: [(key: SignInscriptionPersistentChunkKey,
                        state: SignInscriptionPersistentChunkState,
                        data: Data, digest: String)] = []
        var decodedVoxelCells = 0
        for row in legacyRows {
            let decoded = decodeChunk(
                row.data,
                key: chunkKey(worldID, row.key.dimension, row.key.cx, row.key.cz),
                worldId: worldID,
                dim: row.key.dimension,
                cx: row.key.cx,
                cz: row.key.cz
            )
            let state: SignInscriptionPersistentChunkState
            if let decoded, decoded.blockEntitiesValid {
                decodedVoxelCells += decoded.record.blocks?.count ?? 0
                state = SignInscriptionIdentityCatalog.scan(
                    decoded.record,
                    expectedWorldID: worldID
                )
            } else if let decoded, !decoded.signInscriptionPayloadPresent {
                decodedVoxelCells += decoded.record.blocks?.count ?? 0
                // The normal loader discards an undecodable unrelated BE
                // array. If no serialized entry even carries an inscription
                // field, that corruption cannot conceal a CIV-45 claim.
                state = SignInscriptionPersistentChunkState(valid: true, claims: [:])
            } else {
                state = SignInscriptionPersistentChunkState(valid: false, claims: [:])
            }
            guard let data = try? encoder.encode(
                SignInscriptionIdentityCatalog.envelope(for: state)
            ) else { return false }
            prepared.append((row.key, state, data, signInscriptionIndexDigest(data)))
        }

        guard exec("BEGIN IMMEDIATE") else { return false }
        var ok = true
        for item in prepared {
            let updated = run(
                """
                UPDATE chunks SET inscriptionIndexVersion=1, inscriptionIndexDigest=?
                WHERE world=? AND dim=? AND cx=? AND cz=? AND inscriptionIndexVersion=0
                """,
                bind: { statement in
                    self.bindText(statement, 1, item.digest)
                    self.bindText(statement, 2, worldID)
                    sqlite3_bind_int(statement, 3, Int32(item.key.dimension))
                    sqlite3_bind_int(statement, 4, Int32(item.key.cx))
                    sqlite3_bind_int(statement, 5, Int32(item.key.cz))
                }
            ) && sqlite3_changes(db) == 1
            ok = ok && updated && putSignInscriptionIndexRow(
                worldID: worldID,
                key: item.key,
                version: 1,
                digest: item.digest,
                data: item.data
            )
            if !ok { break }
        }
        guard ok, exec("COMMIT") else {
            _ = exec("ROLLBACK")
            return false
        }
        lastSignInscriptionIndexLoadMetrics = SignInscriptionIndexLoadMetrics(
            indexedChunkRows: 0,
            migratedChunkPayloads: prepared.count,
            decodedVoxelCells: decodedVoxelCells
        )
        return true
    }

    private func putSignInscriptionIndexRow(
        worldID: String,
        key: SignInscriptionPersistentChunkKey,
        version: Int64,
        digest: String,
        data: Data
    ) -> Bool {
        run(
            """
            INSERT INTO sign_inscription_chunks(world,dim,cx,cz,chunkVersion,digest,data)
            VALUES(?,?,?,?,?,?,?)
            ON CONFLICT(world,dim,cx,cz) DO UPDATE SET
              chunkVersion=excluded.chunkVersion,
              digest=excluded.digest,
              data=excluded.data
            """,
            bind: { statement in
                self.bindText(statement, 1, worldID)
                sqlite3_bind_int(statement, 2, Int32(key.dimension))
                sqlite3_bind_int(statement, 3, Int32(key.cx))
                sqlite3_bind_int(statement, 4, Int32(key.cz))
                sqlite3_bind_int64(statement, 5, version)
                self.bindText(statement, 6, digest)
                self.bindData(statement, 7, data)
            }
        )
    }

    private func advanceWorldPhysicalIdentity(worldID: String, toAtLeast value: Int) -> Bool {
        var current: WorldRecord?
        guard run(
            "SELECT json FROM worlds WHERE id=?",
            bind: { self.bindText($0, 1, worldID) },
            row: { statement in
                guard let json = self.columnText(statement, 0) else { return }
                current = try? JSONDecoder().decode(WorldRecord.self, from: Data(json.utf8))
            }
        ), var record = current else { return false }
        guard record.nextEntityId > 0 else { return false }
        if record.nextEntityId >= value { return true }
        record.nextEntityId = value
        guard let data = try? JSONEncoder().encode(record),
              let json = String(data: data, encoding: .utf8) else { return false }
        let updated = run(
            "UPDATE worlds SET json=? WHERE id=?",
            bind: { statement in
                self.bindText(statement, 1, json)
                self.bindText(statement, 2, worldID)
            }
        )
        return updated && sqlite3_changes(db) == 1
    }

    private func signInscriptionIndexDigest(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    // binary container: "VCK1" | u8 flags | [u32 nBlocks, u16[] LE, u32 nBiomes, u8[]] | u32 jsonLen, json
    private func encodeChunk(_ r: ChunkRecord) -> Data? {
        var data = Data("VCK1".utf8)
        let hasBlocks = r.blocks != nil && r.biomes != nil
        data.append(hasBlocks ? 1 : 0)
        func putU32(_ v: Int) {
            var le = UInt32(v).littleEndian
            withUnsafeBytes(of: &le) { data.append(contentsOf: $0) }
        }
        if hasBlocks {
            let blocks = r.blocks!, biomes = r.biomes!
            putU32(blocks.count)
            blocks.withUnsafeBufferPointer { bp in
                bp.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: blocks.count * 2) { p in
                    data.append(p, count: blocks.count * 2)  // host LE on all Apple silicon/x86
                }
            }
            putU32(biomes.count)
            data.append(contentsOf: biomes)
        }
        var tail: [String: Any] = ["entities": r.entities.map(sanitizeJSON)]
        if let bes = r.blockEntities,
           let enc = try? JSONEncoder().encode(bes),
           let obj = try? JSONSerialization.jsonObject(with: enc) {
            tail["blockEntities"] = obj
        }
        guard let json = try? JSONSerialization.data(withJSONObject: tail) else { return nil }
        putU32(json.count)
        data.append(json)
        return data
    }

    private func decodeChunk(
        _ data: Data,
        key: String,
        worldId: String,
        dim: Int,
        cx: Int,
        cz: Int
    ) -> (record: ChunkRecord, blockEntitiesValid: Bool,
          signInscriptionPayloadPresent: Bool)? {
        var rec = ChunkRecord(key: key, worldId: worldId, dim: dim, cx: cx, cz: cz)
        var off = 0
        func readU32() -> Int? {
            guard off + 4 <= data.count else { return nil }
            let v = data.subdata(in: off..<off + 4).withUnsafeBytes { $0.load(as: UInt32.self) }
            off += 4
            return Int(UInt32(littleEndian: v))
        }
        guard data.count >= 5, data.prefix(4) == Data("VCK1".utf8) else { return nil }
        off = 4
        let flags = data[off]; off += 1
        if flags & 1 != 0 {
            guard let nBlocks = readU32(), off + nBlocks * 2 <= data.count else { return nil }
            var blocks = [UInt16](repeating: 0, count: nBlocks)
            data.subdata(in: off..<off + nBlocks * 2).withUnsafeBytes { raw in
                blocks.withUnsafeMutableBytes { dst in
                    dst.copyMemory(from: raw)
                }
            }
            off += nBlocks * 2
            // clamp corrupted ids — blockDefs[cell >> 4] is indexed unchecked
            // in hot paths, and one bad blob must not crash the game
            let maxId = UInt16(blockDefs.count)
            for i in 0..<blocks.count where (blocks[i] >> 4) >= maxId { blocks[i] = 0 }
            rec.blocks = blocks
            guard let nBiomes = readU32(), off + nBiomes <= data.count else { return nil }
            rec.biomes = [UInt8](data.subdata(in: off..<off + nBiomes))
            off += nBiomes
        }
        guard let jsonLen = readU32(), off + jsonLen <= data.count,
              let tail = try? JSONSerialization.jsonObject(with: data.subdata(in: off..<off + jsonLen)) as? [String: Any]
        else { return nil }
        rec.entities = tail["entities"] as? [[String: Any]] ?? []
        var blockEntitiesValid = true
        var signInscriptionPayloadPresent = false
        if let rawBE = tail["blockEntities"] {
            if let values = rawBE as? [Any] {
                signInscriptionPayloadPresent = values.contains { value in
                    guard let object = value as? [String: Any],
                          let inscription = object["signInscription"] else { return false }
                    return !(inscription is NSNull)
                }
            } else {
                // Unknown container shape could conceal a future inscription.
                signInscriptionPayloadPresent = true
            }
            if let bytes = try? JSONSerialization.data(withJSONObject: rawBE),
               let bes = try? JSONDecoder().decode([BlockEntityData].self, from: bytes) {
                rec.blockEntities = bes
            } else {
                // Preserve the historical chunk-loader recovery policy (the
                // World can still load without malformed block entities), but
                // expose the integrity loss to stricter physical authorities.
                blockEntitiesValid = false
            }
        }
        return (rec, blockEntitiesValid, signInscriptionPayloadPresent)
    }

    // ---- player / advancements --------------------------------------------------
    public func getPlayer(_ worldId: String) -> [String: Any]? {
        var out: [String: Any]?
        run("SELECT json FROM player WHERE world=?", bind: { self.bindText($0, 1, worldId) }) { stmt in
            if let json = self.columnText(stmt, 0) {
                out = (try? JSONSerialization.jsonObject(with: Data(json.utf8))) as? [String: Any]
            }
        }
        return out
    }
    public func putPlayer(_ worldId: String, _ data: [String: Any]) {
        guard let bytes = try? JSONSerialization.data(withJSONObject: sanitizeJSON(data)),
              let json = String(data: bytes, encoding: .utf8) else { return }
        run("INSERT OR REPLACE INTO player(world, json) VALUES(?,?)", bind: { stmt in
            self.bindText(stmt, 1, worldId)
            self.bindText(stmt, 2, json)
        })
    }
    public func getAdvancements(_ worldId: String) -> [String]? {
        var out: [String]?
        run("SELECT json FROM advancements WHERE world=?", bind: { self.bindText($0, 1, worldId) }) { stmt in
            if let json = self.columnText(stmt, 0) {
                out = (try? JSONSerialization.jsonObject(with: Data(json.utf8))) as? [String]
            }
        }
        return out
    }
    public func putAdvancements(_ worldId: String, _ ids: [String]) {
        guard let bytes = try? JSONSerialization.data(withJSONObject: ids),
              let json = String(data: bytes, encoding: .utf8) else { return }
        run("INSERT OR REPLACE INTO advancements(world, json) VALUES(?,?)", bind: { stmt in
            self.bindText(stmt, 1, worldId)
            self.bindText(stmt, 2, json)
        })
    }

    // ---- legacy import ----------------------------------------------------------
    /// one-time import of the pre-1.0 loose-file layout (saves/worlds/*.json,
    /// saves/chunks/<id>/*.vck, …); the old folder is renamed, never deleted
    private func migrateLegacySaves() {
        let fm = FileManager.default
        let legacy = vcSupportDir().appendingPathComponent("saves", isDirectory: true)
        let worldsDir = legacy.appendingPathComponent("worlds")
        guard fm.fileExists(atPath: worldsDir.path),
              let files = try? fm.contentsOfDirectory(at: worldsDir, includingPropertiesForKeys: nil),
              !files.isEmpty else { return }

        var worlds = 0, chunks = 0
        for f in files where f.pathExtension == "json" {
            guard let data = try? Data(contentsOf: f),
                  let rec = try? JSONDecoder().decode(WorldRecord.self, from: data) else { continue }
            putWorld(rec)
            worlds += 1
            let id = rec.id
            if let pdata = try? Data(contentsOf: legacy.appendingPathComponent("player/\(id).json")),
               let pobj = (try? JSONSerialization.jsonObject(with: pdata)) as? [String: Any] {
                putPlayer(id, pobj)
            }
            if let adata = try? Data(contentsOf: legacy.appendingPathComponent("advancements/\(id).json")),
               let aobj = (try? JSONSerialization.jsonObject(with: adata)) as? [String] {
                putAdvancements(id, aobj)
            }
            let cdir = legacy.appendingPathComponent("chunks/\(id)", isDirectory: true)
            guard let cfiles = try? fm.contentsOfDirectory(at: cdir, includingPropertiesForKeys: nil) else { continue }
            exec("BEGIN")
            for cf in cfiles where cf.pathExtension == "vck" {
                let parts = cf.deletingPathExtension().lastPathComponent.split(separator: "_")
                guard parts.count == 3, let dim = Int(parts[0]), let cx = Int(parts[1]), let cz = Int(parts[2]),
                      let cdata = try? Data(contentsOf: cf) else { continue }
                run("INSERT OR REPLACE INTO chunks(world, dim, cx, cz, data) VALUES(?,?,?,?,?)", bind: { stmt in
                    self.bindText(stmt, 1, id)
                    sqlite3_bind_int(stmt, 2, Int32(dim))
                    sqlite3_bind_int(stmt, 3, Int32(cx))
                    sqlite3_bind_int(stmt, 4, Int32(cz))
                    cdata.withUnsafeBytes { raw in
                        _ = sqlite3_bind_blob(stmt, 5, raw.baseAddress, Int32(raw.count), SQLITE_TRANSIENT)
                    }
                })
                chunks += 1
            }
            exec("COMMIT")
        }
        let backup = vcSupportDir().appendingPathComponent("saves-legacy-backup")
        try? fm.moveItem(at: legacy, to: backup)
        print("[saves] migrated \(worlds) worlds, \(chunks) chunks into pebble.db (old files kept in saves-legacy-backup)")
        fflush(stdout)
    }
}
