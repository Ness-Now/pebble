import Foundation
import CoreFoundation
import SQLite3
import PebbleAgents
import PebbleCore

struct OccupancyQualificationChunk: Codable {
    let cx: Int
    let cz: Int
    let terrain: String
    let entities: [String]
}

struct OccupancyQualificationBoundary: Codable {
    let worldID: String
    let worldTick: Int
    let civilizationTick: Int
    let semanticDigest: String
    let causalDigest: String
    let positions: [String: AgentPosition]
    let custody: [String: String]
    let player: String
    let intersectingSpider: String
    let chunks: [OccupancyQualificationChunk]
    let numericBits: [String: [String: String]]
    var continuationRevision: Int64?
}

/// Qualification orchestration over the ordinary GameCore/controller path.
/// Positive writer states are produced by normal seed-5 stepping. Controlled
/// attacks run in a separate phase/home and never alter those positive states.
enum PebbleContinuationEmbodimentQualification {
    enum Failure: Error { case refused(String) }
    static let worldID = "ps01-i09-seed-5-founders-24"
    static var assertionCount = 0

    static func require(_ condition: Bool, _ label: String) throws {
        assertionCount += 1
        guard condition else { throw Failure.refused(label) }
        print("[ps01-occupancy] assertion=\(assertionCount) PASS \(label)"); fflush(stdout)
    }

    static func json(_ value: Any) throws -> String {
        String(data: try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]), encoding: .utf8)!
    }

    static func configure(_ game: GameCore, _ controller: PebbleAgentController) {
        game.settings.renderDistance = 4
        controller.worldSideReceiptDatabase = game.db
        controller.installWorldContinuation(on: game)
        game.physicalSimulationCoverageProvider = { [weak controller] world in
            controller?.physicalSimulationCoverageRequest(for: world) ?? .inactive
        }
        game.prepareExternalLifecycleState = { [weak game, weak controller] in
            guard let game, let controller else { return false }
            guard game.hasWorld() else { return controller.session == nil && controller.activeWorld == nil }
            return controller.prepareForLifecyclePersistence(world: game.world)
        }
        game.finalizeExternalLifecycleState = { [weak controller] in controller?.finalizeLifecycleAfterPersistence() }
    }

    static func step(_ game: GameCore, _ controller: PebbleAgentController) throws {
        _ = game.frame(dtMs: TICK_MS)
        let deadline = Date(timeIntervalSinceNow: 60)
        while game.physicalSimulationCoverageRuntimeDiagnostics(for: game.world).totalGenerationJobsInFlight > 0 {
            guard Date() < deadline else { throw Failure.refused("bounded generation timeout") }
            _ = RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.005))
        }
        controller.update(world: game.world, player: game.player,
            worldID: game.worldRec?.id, dimension: game.dim.rawValue)
        try requireIntegrity(controller)
    }

    static func requireIntegrity(_ controller: PebbleAgentController) throws {
        guard controller.fatalSessionIntegrityFailure == nil,
              controller.candidatePhysicalHardFailure == nil,
              controller.runtimeErrorCount == 0, controller.droppedCatchUpSteps == 0 else {
            throw Failure.refused("runtime integrity: \(controller.lastError ?? "none")")
        }
    }

    static func prepareWriter(_ game: GameCore, _ controller: PebbleAgentController,
                              horizon: Int = 18000) throws {
        configure(game, controller)
        game.createWorld(name: "PS01 natural seed-5 occupancy", seedText: "5",
            mode: GameMode.survival, difficulty: 2)
        var record = game.worldRec!
        let transient = record.id
        try require(game.exitToTitle(), "ordinary initial World exit")
        game.deleteWorld(transient)
        record.id = worldID; record.lastPlayed = 0
        try require(game.db.putWorld(record), "historical matched World identity")
        game.loadWorld(worldID)
        for _ in 0..<52 { try step(game, controller) }
        let start = controller.start(world: game.world, player: game.player,
            founders: try PebbleNormalFounderProfile(count: 24))
        try require(start.succeeded && controller.cognitiveHz == 4, "24 normal founders at 4 Hz")
        for elapsed in 0..<horizon {
            try step(game, controller)
            if elapsed % 1200 == 1199 {
                print("[ps01-occupancy] PROGRESS world=\(game.world.time) tick=\(controller.session!.tick) living=\(controller.session!.snapshot().agents.count)"); fflush(stdout)
            }
        }
    }

    static func custody(_ controller: PebbleAgentController) throws -> [String: String] {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        return try controller.probesByAgentId.mapValues {
            String(data: try encoder.encode($0.carriedItems), encoding: .utf8)!
        }
    }

    static func eligible(_ world: World, cx: Int, cz: Int) -> [Entity] {
        world.entities.compactMap { $0 as? Entity }.filter {
            !$0.isPlayer && !$0.dead && $0.shouldSaveToChunk
                && floorDiv(Int($0.x.rounded(.down)), 16) == cx
                && floorDiv(Int($0.z.rounded(.down)), 16) == cz
                && (!(($0.type == "item" || $0.type == "xp_orb") && $0.age > 4000)
                    || ($0 as? ItemEntity)?.custodyProvenance != nil)
        }
    }

    static func terrainHash(_ chunk: Chunk) -> String {
        var hash: UInt64 = 14695981039346656037
        for block in chunk.blocks {
            hash = (hash ^ UInt64(block & 255)) &* 1099511628211
            hash = (hash ^ UInt64(block >> 8)) &* 1099511628211
        }
        return String(hash, radix: 16)
    }

    static func boundary(_ game: GameCore, _ controller: PebbleAgentController, natural: Bool = true, spider: Spider? = nil) throws -> OccupancyQualificationBoundary {
        let agents = controller.session!.snapshot().agents.sorted { $0.id < $1.id }
        let own = Set(controller.probesByAgentId.values.map(\.id))
        let placement = assessEntityPlacementSet(in: game.world,
            at: agents.map { EntityPlacementPosition(x: $0.position.x, y: $0.position.y, z: $0.position.z) },
            bodyWidth: 0.6, bodyHeight: 1.8, ignoringEntityIDs: own)
        let invalid = zip(agents, placement.assessments).filter { !$0.1.isValid }
        try require(agents.count == 24 && placement.overlaps.isEmpty,
            "24 living residents and no target overlap")
        var selectedSpider = spider
        if natural {
            try require(game.world.time == 18052 && controller.session!.tick == 3600,
                "matched natural World 18052 / Session 3600")
            try require(invalid.map { $0.0.id } == ["agent_1", "agent_8"]
                && invalid.allSatisfy { $0.1.rejections == [.entityCollision] },
                "same natural agent_1 and agent_8 external collision")
            let first = game.world.getEntitiesInBox(invalid[0].1.body).filter { !own.contains($0.id) }
            let second = game.world.getEntitiesInBox(invalid[1].1.body).filter { !own.contains($0.id) }
            let spiders = first.compactMap { $0 as? Spider }
            try require(first.count == 2 && first.contains { $0 === game.player }
                && spiders.count == 1 && second.count == 1 && second[0] === spiders[0],
                "naturally present Player and the same Spider intersect existing probes")
            selectedSpider = spiders[0]
        }
        guard let selectedSpider else { throw Failure.refused("natural Spider identity missing") }
        let embodiments = try controller.validatedCheckpointEmbodiments(snapshot: controller.session!.snapshot(), world: game.world)
        try require(agents.allSatisfy { agent in
            let probe = embodiments[agent.id]!.probe
            return probe.x == Double(agent.position.x) + 0.5 && probe.y == Double(agent.position.y)
                && probe.z == Double(agent.position.z) + 0.5
        }, "current live capture validates exact authoritative centered embodiments")
        let chunks = try game.world.chunks.values.sorted {
            $0.cx == $1.cx ? $0.cz < $1.cz : $0.cx < $1.cx
        }.map { chunk in
            OccupancyQualificationChunk(cx: chunk.cx, cz: chunk.cz, terrain: terrainHash(chunk),
                entities: try eligible(game.world, cx: chunk.cx, cz: chunk.cz).map { try json($0.save()) }.sorted())
        }
        return OccupancyQualificationBoundary(worldID: worldID, worldTick: game.world.time,
            civilizationTick: controller.session!.tick,
            semanticDigest: try controller.session!.durableStateDigest().rawValue,
            causalDigest: controller.session!.causalLedgerSnapshot().summary.digest,
            positions: Dictionary(uniqueKeysWithValues: agents.map { ($0.id, $0.position) }),
            custody: try custody(controller), player: try json(game.player.save()),
            intersectingSpider: try json(selectedSpider.save()), chunks: chunks,
            numericBits: try numericRecords(game), continuationRevision: nil)
    }

    static func numericFields(_ value: [String: Any]) -> [String: String] {
        var result: [String: String] = [:]
        for key in ["x", "y", "z", "vx", "vy", "vz", "yaw", "pitch", "health", "saturation", "xpProgress"] {
            if let number = value[key] as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() {
                result[key] = String(number.doubleValue.bitPattern, radix: 16)
            }
        }
        return result
    }

    static func numericRecords(_ game: GameCore) throws -> [String: [String: String]] {
        // Semantic records, including multiplicity, identify records across a
        // fresh process; ordinary runtime entity IDs play no part.
        var records: [String: [String: String]] = [:]
        let residents = game.world.chunks.values.flatMap { eligible(game.world, cx: $0.cx, cz: $0.cz) }
        for entity in [game.player!] + residents {
            let raw = entity.save(), semantic = try json(raw)
            let index = records.keys.filter { $0.hasPrefix(semantic + "#") }.count
            records[semantic + "#" + String(index)] = numericFields(raw)
        }
        return records
    }

    static func writeBoundary(_ value: OccupancyQualificationBoundary, to output: String) throws {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        try encoder.encode(value).write(to: URL(fileURLWithPath: output), options: .atomic)
    }

    static func verifyPersisted(_ game: GameCore, expected: OccupancyQualificationBoundary) throws {
        var numeric: [String: [String: String]] = [:]
        let player = game.db.getPlayer(worldID)!["data"] as! [String: Any]
        let playerSemantic = try json(player)
        try require(playerSemantic == expected.player, "persisted Player semantic owner is exact")
        numeric[playerSemantic + "#0"] = numericFields(player)
        for chunk in expected.chunks {
            guard let saved = game.db.getChunk(worldID, 0, chunk.cx, chunk.cz) else {
                try require(chunk.entities.isEmpty, "absent record has no save-eligible participants"); continue
            }
            try require(try saved.entities.map { try json($0) }.sorted() == chunk.entities,
                "resident semantic entity snapshot conserved at \(chunk.cx),\(chunk.cz)")
            try require(saved.entities.allSatisfy {
                !["player", LabCoreAgentEntity.kind].contains($0["type"] as? String ?? "")
            }, "chunk records exclude Player and transient probes at \(chunk.cx),\(chunk.cz)")
            for row in saved.entities {
                let semantic = try json(row), index = numeric.keys.filter { $0.hasPrefix(semantic + "#") }.count
                numeric[semantic + "#" + String(index)] = numericFields(row)
            }
            if chunk.cx == -5 && chunk.cz == -8 {
                try require(saved.entities.contains { $0["type"] as? String == "chicken" },
                    "old unrelated Chicken failure boundary remains present and semantically exact")
            }
        }
        try require(numeric == expected.numericBits, "every relevant persisted Binary64 bit pattern is exact")
    }

    /// Evidence-only snapshot of the successful Save/Continue boundary. The
    /// SQLite backup API captures a coherent database; no Core format changes.
    static func copyNaturalHome() throws {
        let home = ProcessInfo.processInfo.environment["CFFIXED_USER_HOME"]!
        let destination = home + ".natural"
        let fm = FileManager.default
        guard !fm.fileExists(atPath: destination),
              let enumerator = fm.enumerator(atPath: home) else { throw Failure.refused("isolated backup destination") }
        let dbs = enumerator.compactMap { $0 as? String }.filter { $0.hasSuffix("/pebble.db") }
        guard dbs.count == 1 else { throw Failure.refused("single Core database for backup") }
        try fm.copyItem(atPath: home, toPath: destination)
        let relative = dbs[0]
        for suffix in ["", "-wal", "-shm"] where fm.fileExists(atPath: destination + "/" + relative + suffix) {
            try fm.removeItem(atPath: destination + "/" + relative + suffix)
        }
        var source: OpaquePointer?, target: OpaquePointer?
        guard sqlite3_open_v2(home + "/" + relative, &source, SQLITE_OPEN_READONLY, nil) == SQLITE_OK,
              sqlite3_open(destination + "/" + relative, &target) == SQLITE_OK else {
            throw Failure.refused("open SQLite snapshot")
        }
        defer { sqlite3_close(target); sqlite3_close(source) }
        guard let backup = sqlite3_backup_init(target, "main", source, "main") else {
            throw Failure.refused("SQLite backup initialization")
        }
        let step = sqlite3_backup_step(backup, -1), finish = sqlite3_backup_finish(backup)
        try require(step == SQLITE_DONE && finish == SQLITE_OK, "consistent natural Save/Continue database and checkpoint snapshot")
    }

    static func saveContinueWriter(_ game: GameCore, _ controller: PebbleAgentController,
                                   output: String) throws {
        var expected = try boundary(game, controller)
        let states = controller.probesByAgentId.keys.sorted().map {
            PebbleAgentCheckpointProbeState(agentID: $0, probe: controller.probesByAgentId[$0]!)
        }
        let external = Set(game.world.entities.filter { !($0 is LabCoreAgentEntity) }.map(ObjectIdentifier.init))
        let capture = controller.handleCheckpoint(["save", "occupancy-capture-proof"], world: game.world)
        try require(capture.succeeded, "ordinary checkpoint capture succeeds with natural overlap")
        try require(game.saveAndFlush(), "ordinary Save/Continue succeeds with natural overlap")
        try require(try controller.session!.durableStateDigest().rawValue == expected.semanticDigest
            && custody(controller) == expected.custody && json(game.player.save()) == expected.player
            && states.allSatisfy { $0.isUnchanged(in: game.world, mappedByAgentID: controller.probesByAgentId) }
            && Set(game.world.entities.filter { !($0 is LabCoreAgentEntity) }.map(ObjectIdentifier.init)) == external,
            "Save/Continue changes no participant, position, Session state or custody")
        expected.continuationRevision = game.db.worldContinuation(worldID)!.revision
        try verifyPersisted(game, expected: expected)
        try requireIntegrity(controller)
        try writeBoundary(expected, to: output + ".natural.json")
        try copyNaturalHome()
    }

    static func finishWriter(_ game: GameCore, _ controller: PebbleAgentController,
                             output: String, alreadyContinued: Bool = false) throws {
        if !alreadyContinued { try saveContinueWriter(game, controller, output: output) }
        let natural = try JSONDecoder().decode(OccupancyQualificationBoundary.self,
            from: Data(contentsOf: URL(fileURLWithPath: output + ".natural.json")))
        let spiders = try game.world.entities.compactMap { $0 as? Spider }.filter { try json($0.save()) == natural.intersectingSpider }
        try require(spiders.count == 1, "natural Spider remains exactly one after Save/Continue")
        let spider = spiders[0]
        for _ in 0..<20 { try step(game, controller) }
        try require(game.world.time == 18072 && controller.session!.tick == 3604,
            "same writer process progresses normally after Save/Continue")
        var expected = try boundary(game, controller, natural: false, spider: spider)
        try require(game.exitToTitle() && controller.session == nil && controller.probesByAgentId.isEmpty,
            "ordinary Save/Exit succeeds before probe teardown")
        expected.continuationRevision = game.db.worldContinuation(worldID)!.revision
        try verifyPersisted(game, expected: expected)
        try writeBoundary(expected, to: output)
        print("[ps01-occupancy] WRITER_PASS semanticDigest=\(expected.semanticDigest) world=18072 population=24 custody=exact player=conserved spider=conserved"); fflush(stdout)
    }

    static func verifyReader(_ game: GameCore, _ controller: PebbleAgentController,
                             expected: OccupancyQualificationBoundary) throws {
        try require(game.worldContinuationReady && controller.session != nil,
            "fresh ordinary World entry restores before first gameplay tick")
        let session = controller.session!
        try require(game.world.time == expected.worldTick && session.tick == expected.civilizationTick
            && (try session.durableStateDigest().rawValue) == expected.semanticDigest
            && session.causalLedgerSnapshot().summary.digest == expected.causalDigest,
            "fresh World, Session and causal state match exact semantic boundary")
        try require(try custody(controller) == expected.custody && json(game.player.save()) == expected.player,
            "fresh Player and custody match their existing owners")
        let embodiments = try controller.validatedCheckpointEmbodiments(snapshot: session.snapshot(), world: game.world)
        try require(embodiments.count == 24 && embodiments.allSatisfy { id, body in
            body.position == expected.positions[id]
                && body.x == Double(body.position.x) + 0.5 && body.y == Double(body.position.y)
                && body.z == Double(body.position.z) + 0.5
        }, "exactly one recreated transient probe per authoritative live agent without teleport")
        // Materialize the writer's resident horizon through the same Core
        // loader, without a gameplay tick. This checks participants beyond the
        // checkpoint-cell neighborhood as well as the intersecting Spider.
        for first in stride(from: 0, to: expected.chunks.count, by: 270) {
            let batch = expected.chunks[first..<min(first + 270, expected.chunks.count)]
            try require(game.prepareWorldContinuationChunks(dimension: 0, coordinates: batch.map { ($0.cx, $0.cz) }),
                "Core materializes saved resident horizon without gameplay")
        }
        for chunk in expected.chunks {
            try require(try eligible(game.world, cx: chunk.cx, cz: chunk.cz).map { try json($0.save()) }.sorted() == chunk.entities
                && terrainHash(game.world.getChunk(chunk.cx, chunk.cz)!) == chunk.terrain,
                "fresh resident terrain and semantic participants match \(chunk.cx),\(chunk.cz)")
            if let saved = game.db.getChunk(worldID, 0, chunk.cx, chunk.cz) {
                try require(saved.entities.allSatisfy {
                    !["player", LabCoreAgentEntity.kind].contains($0["type"] as? String ?? "")
                }, "fresh chunk persistence cannot duplicate probes or Player at \(chunk.cx),\(chunk.cz)")
            }
        }
        try require(try numericRecords(game) == expected.numericBits,
            "fresh-process exact relevant Binary64 records survive without runtime ID equality")
        try require(game.db.worldContinuation(worldID)?.revision == expected.continuationRevision,
            "fresh reader selects the exact persisted continuation revision")
        let matchedSpiders = try game.world.entities.compactMap { $0 as? Spider }.filter {
            try json($0.save()) == expected.intersectingSpider
        }
        try require(matchedSpiders.count == 1 && game.world.entities.filter { $0 is Player }.count == 1,
            "saved intersecting Spider exactly once and Player remains single-owner")
        try require(game.world.entities.compactMap { $0 as? LabCoreAgentEntity }.count == expected.positions.count,
            "Core never chunk-restores a second probe population")
        try requireIntegrity(controller)
    }

    static func runIfRequested() -> Int32? {
        let env = ProcessInfo.processInfo.environment
        guard let phase = env["PEBBLELAB_PS01_OCCUPANCY_PHASE"] else { return nil }
        do {
            guard let home = env["CFFIXED_USER_HOME"],
                  home.hasPrefix("/tmp/") || home.hasPrefix("/private/tmp/"),
                  let output = env["PEBBLELAB_PS01_OCCUPANCY_OUTPUT"],
                  ["controlled", "write", "read", "restore-fault"].contains(phase) else {
                throw Failure.refused("explicit isolated qualification configuration required")
            }
            let game = GameCore(), controller = PebbleAgentController()
            if phase == "write" {
                try prepareWriter(game, controller)
                try finishWriter(game, controller, output: output)
            } else if phase == "controlled" {
                try prepareWriter(game, controller, horizon: 0)
                try controlledCaptureAttacks(game, controller)
            } else {
                configure(game, controller)
                let expected = try JSONDecoder().decode(OccupancyQualificationBoundary.self,
                    from: Data(contentsOf: URL(fileURLWithPath: output)))
                if phase == "restore-fault" {
                    let restore = game.restoreExternalContinuation!
                    var exactRollback = false
                    game.restoreExternalContinuation = {
                        for first in stride(from: 0, to: expected.chunks.count, by: 270) {
                            let batch = expected.chunks[first..<min(first + 270, expected.chunks.count)]
                            guard game.prepareWorldContinuationChunks(dimension: 0,
                                coordinates: batch.map { ($0.cx, $0.cz) }) else { return false }
                        }
                        let objects = Set(game.world.entities.map(ObjectIdentifier.init))
                        let states = try! game.world.entities.compactMap { $0 as? Entity }.map { try json($0.save()) }.sorted()
                        // After Core materializes the saved resident horizon,
                        // compare the complete pre-transaction object/state set.
                        let faults: [String: PebbleAgentCheckpointPositionRestoreFailurePoint] = [
                            "zero": .beforePhysicalMutation, "one": .afterFirstMissingCreation,
                            "several": .afterSeveralMissingCreations, "custody": .afterCustodyAdoption,
                            "late": .beforeSessionPublication]
                        guard let fault = faults[env["PEBBLELAB_PS01_OCCUPANCY_FAULT"] ?? "one"] else { return false }
                        controller.checkpointPositionRestoreFailurePoint = fault
                        let result = restore()
                        exactRollback = !result && controller.session == nil && controller.probesByAgentId.isEmpty
                            && game.world.entities.allSatisfy { !($0 is LabCoreAgentEntity) }
                            && objects == Set(game.world.entities.map(ObjectIdentifier.init))
                            && states == (try! game.world.entities.compactMap { $0 as? Entity }.map { try json($0.save()) }.sorted())
                        return result
                    }
                    let raw = game.db.worldContinuation(worldID)!
                    game.loadWorld(worldID)
                    try require(exactRollback && !game.worldContinuationReady && !game.worldMutationAllowed,
                        "injected restore failure rolls back every probe and preserves all external participants")
                    let after = game.db.worldContinuation(worldID)!
                    try require(after.revision == raw.revision && after.payload == raw.payload && game.exitToTitle(),
                        "failed reader exits without altering saved continuation; fresh retry remains possible")
                    game.restoreExternalContinuation = restore
                    game.loadWorld(worldID)
                    try verifyReader(game, controller, expected: expected)
                    try require(controller.probesByAgentId.count == 24,
                        "same-process retry after verified rollback recreates one exact population")
                    try require(game.exitToTitle(), "retried restore exits normally")
                } else {
                    game.loadWorld(worldID)
                    try verifyReader(game, controller, expected: expected)
                    let digest = try controller.session!.durableStateDigest()
                    let duplicate = game.restoreExternalContinuation!()
                    try require(!duplicate && controller.probesByAgentId.count == 24
                        && (try controller.session!.durableStateDigest()) == digest,
                        "restart cannot duplicate custody or embodiment")
                    for _ in 0..<20 { try step(game, controller) }
                    try require(game.world.time == expected.worldTick + 20, "ordinary continuation progresses after exact restore")
                    try requireIntegrity(controller)
                    let continued = try controller.session!.durableStateDigest().rawValue
                    try require(game.saveAndFlush() && game.exitToTitle() && controller.probesByAgentId.isEmpty,
                        "continued reader Save/Continue and Save/Exit remain coherent")
                    try json(["phase": phase, "foundersCreated": 0, "loadedDigest": expected.semanticDigest,
                        "continuedDigest": continued, "population": 24, "runtimeErrors": 0,
                        "playerConserved": true, "spiderConserved": true, "probeSetExact": true,
                        "custodyExact": true]).write(toFile: output + ".read.json", atomically: true, encoding: .utf8)
                }
            }
            print("[ps01-occupancy] QUALIFICATION_PASS phase=\(phase) assertions=\(assertionCount)"); fflush(stdout)
            return 0
        } catch {
            fputs("[ps01-occupancy] QUALIFICATION_FAIL \(error)\n", stderr)
            return 1
        }
    }

    static func controlledCaptureAttacks(_ game: GameCore, _ controller: PebbleAgentController) throws {
        let world = game.world
        let snapshot = controller.session!.snapshot()
        let agents = snapshot.agents.sorted { $0.id < $1.id }
        let id = agents[0].id, probe = controller.probesByAgentId[agents[0].id]!
        func refuses(_ label: String, world candidate: World? = nil) throws {
            do {
                _ = try controller.validatedCheckpointEmbodiments(snapshot: snapshot, world: candidate ?? world)
            } catch { try require(true, label); return }
            throw Failure.refused(label + " unexpectedly accepted")
        }
        controller.probesByAgentId[id] = nil
        try refuses("capture missing expected mapping refuses")
        controller.probesByAgentId[id] = probe
        world.entityById.removeValue(forKey: probe.id)
        try refuses("capture missing World index binding refuses")
        world.entityById[probe.id] = probe
        let slots = probe.carriedItems
        probe.carriedItems.removeLast()
        try refuses("capture invalid custody slot binding refuses")
        probe.carriedItems = slots
        world.removeEntity(probe)
        try refuses("capture missing expected physical probe refuses")
        world.addEntity(probe)
        let duplicate = LabCoreAgentEntity(world: world, labAgentId: id, physicalId: probe.physicalId)
        duplicate.setPos(probe.x, probe.y, probe.z); world.addEntity(duplicate)
        try refuses("capture duplicate physical embodiment refuses")
        world.removeEntity(duplicate)
        world.removeEntity(probe)
        let foreign = LabCoreAgentEntity(world: world, labAgentId: id, physicalId: "foreign-owner")
        foreign.setPos(probe.x, probe.y, probe.z); world.addEntity(foreign)
        controller.probesByAgentId[id] = foreign
        try refuses("capture wrong physical ownership refuses")
        world.removeEntity(foreign); world.addEntity(probe); controller.probesByAgentId[id] = probe
        let x = probe.x; probe.x += 0.125
        try refuses("capture fractional Session/probe position mismatch refuses"); probe.x = x
        probe.x += 1
        try refuses("capture Session/probe position mismatch refuses"); probe.x = x
        try refuses("capture foreign World refuses", world: World(dim: .overworld, seed: world.seed))
        controller.persistenceDimension = 1
        try refuses("capture foreign dimension refuses"); controller.persistenceDimension = 0
        let extra = LabCoreAgentEntity(world: world, labAgentId: "unowned", physicalId: "unowned")
        world.addEntity(extra)
        try refuses("capture unowned extra probe refuses"); world.removeEntity(extra)
        // A separate pure test fixture presents two distinct agent targets at
        // one position to the actual collective placement owner. It is never
        // attached as a live controller/session or allowed to mutate World.
        let encoder = JSONEncoder()
        var rows = try JSONSerialization.jsonObject(with: encoder.encode(
            Array(controller.session!.durableState().agents.prefix(2)))) as! [[String: Any]]
        rows[1]["position"] = rows[0]["position"]
        let collidingStates = try JSONDecoder().decode([AgentSessionAgentState].self,
            from: JSONSerialization.data(withJSONObject: rows))
        let fixture = try AgentSimulationSession(configuration: controller.session!.configuration,
            agents: collidingStates)
        do {
            _ = try controller.acquireCheckpointProbePlacementAuthority(
                candidateAgents: fixture.snapshot().agents,
                currentProbeStates: controller.probesByAgentId.keys.sorted().map {
                    PebbleAgentCheckpointProbeState(agentID: $0, probe: controller.probesByAgentId[$0]!)
                }, checkpointCustodySpillItems: [], world: world)
            throw Failure.refused("collective probe target overlap accepted")
        } catch let failure as Failure { throw failure }
          catch {
            try require(String(describing: error).contains("target overlap"),
                "actual Pebble collective owner refuses target-to-target overlap")
        }
        let originalPlayer = (game.player.x, game.player.y, game.player.z)
        game.player.setPos(probe.x, probe.y, probe.z)
        let existing = controller.handleCheckpoint(["save", "controlled-live-overlap"], world: world)
        try require(existing.succeeded, "controlled current live Player intersection captures")
        let states = controller.probesByAgentId.keys.sorted().map {
            PebbleAgentCheckpointProbeState(agentID: $0, probe: controller.probesByAgentId[$0]!)
        }
        let load = controller.handleCheckpoint(["load", "controlled-live-overlap"], world: world)
        try require(!load.succeeded && states.allSatisfy { $0.isUnchanged(in: world, mappedByAgentID: controller.probesByAgentId) },
            "manual checkpoint admission still refuses external collision without mutation")
        controller.probesByAgentId[id] = nil; world.removeEntity(probe)
        do {
            let unexpected = try controller.createProbe(for: agents[0], in: world)
            world.removeEntity(unexpected)
            throw Failure.refused("ordinary new placement accepted external collision")
        } catch let failure as Failure { throw failure }
          catch { try require(true, "ordinary NEW probe creation refuses equivalent external collision") }
        world.addEntity(probe); controller.probesByAgentId[id] = probe
        game.player.setPos(originalPlayer.0, originalPlayer.1, originalPlayer.2)
        _ = try controller.validatedCheckpointEmbodiments(snapshot: controller.session!.snapshot(), world: world)
        try requireIntegrity(controller)
        try require(game.exitToTitle() && controller.probesByAgentId.isEmpty,
            "controlled attacks retain coherent ownership and ordinary cleanup")
    }
}
