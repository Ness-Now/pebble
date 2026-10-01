import Foundation
import PebbleCore

private struct StreamingOrderSnapshot: Equatable {
    let commitOrder: [String]
    let targetReadiness: [String]
    let entitySequence: [String]
    let nextEntityID: Int
    let maximumConcurrentCalculations: Int
    let maximumGenerationCapacity: Int
    let heldUntilWaveComplete: Bool
    let waveStalledWorldTick: Bool
}

private func streamingWait(
    seconds: TimeInterval = 20,
    _ condition: () -> Bool
) -> Bool {
    let deadline = Date(timeIntervalSinceNow: seconds)
    while Date() < deadline {
        if condition() { return true }
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.005))
    }
    return condition()
}

private func streamingRecord(_ id: String) -> WorldRecord {
    var record = WorldRecord(
        id: id,
        name: "Core ordered chunk commit",
        seed: 14,
        gameMode: GameMode.creative,
        difficulty: 0
    )
    record.spawnX = 0
    record.spawnY = 65
    record.spawnZ = 0
    record.nextEntityId = 1
    return record
}

private func streamingEntity(
    type: String,
    x: Double,
    y: Double,
    z: Double
) -> [String: Any] {
    [
        "type": type,
        "x": x, "y": y, "z": z,
        "vx": 0.0, "vy": 0.0, "vz": 0.0,
        "yaw": 0.0, "pitch": 0.0,
        "age": 0, "fire": 0,
        "persistent": true,
    ]
}

private func streamingChunkRecord(
    game: GameCore,
    worldID: String,
    dimension: Dim,
    cx: Int,
    cz: Int,
    entityType: String
) -> ChunkRecord {
    let info = DIMS[dimension.rawValue]
    let chunk = Chunk(
        cx: cx,
        cz: cz,
        minY: info.minY,
        height: info.height
    )
    return ChunkRecord(
        key: game.db.chunkKey(worldID, dimension.rawValue, cx, cz),
        worldId: worldID,
        dim: dimension.rawValue,
        cx: cx,
        cz: cz,
        blocks: chunk.blocks,
        biomes: chunk.biomes,
        entities: [streamingEntity(
            type: entityType,
            x: Double(cx * CHUNK_W) + 0.5,
            y: Double(info.minY + 4),
            z: Double(cz * CHUNK_W) + 0.5
        )]
    )
}

private func streamingInstall(
    _ game: GameCore,
    worldID: String,
    targets: [(Dim, Int, Int, String)]
) -> Bool {
    game.db.deleteWorld(worldID)
    guard game.db.putWorld(streamingRecord(worldID)) else { return false }
    return game.db.putChunks(targets.map {
        streamingChunkRecord(
            game: game,
            worldID: worldID,
            dimension: $0.0,
            cx: $0.1,
            cz: $0.2,
            entityType: $0.3
        )
    })
}

private func streamingEventKey(_ event: ChunkGenerationTestingEvent) -> String {
    "\(event.requestSequence):\(event.dimension):\(event.chunkX):\(event.chunkZ)"
}

private func streamingForcedOrderSnapshot(
    label: String,
    reverseCompletion: Bool
) -> StreamingOrderSnapshot? {
    let game = GameCore()
    let worldID = "ps01-i07-stream-order-\(label)"
    let targets: [(Dim, Int, Int, String)] = [
        (.overworld, 12, 0, "cow"),
        (.nether, 12, 0, "pig"),
        (.end, 12, 0, "sheep"),
    ]
    guard streamingInstall(game, worldID: worldID, targets: targets) else {
        return nil
    }
    game.loadWorld(worldID)
    for world in game.worlds.values {
        world.randomTickSpeed = 0
        world.gameRules["doMobSpawning"] = 0
        world.gameRules["doWeatherCycle"] = 0
    }

    let calculationLock = NSLock()
    let calculationRelease = DispatchSemaphore(value: 0)
    var calculationsStarted = 0
    game.testingChunkGenerationCalculationHook = { _ in
        calculationLock.lock()
        calculationsStarted += 1
        let releaseAll = calculationsStarted == targets.count
        calculationLock.unlock()
        if releaseAll {
            for _ in targets { calculationRelease.signal() }
        }
        _ = calculationRelease.wait(timeout: .now() + 10)
    }

    var deliveries: [UInt64: () -> Void] = [:]
    var requests: [UInt64: ChunkGenerationTestingEvent] = [:]
    game.testingChunkGenerationCompletionGate = { event, deliver in
        requests[event.requestSequence] = event
        deliveries[event.requestSequence] = deliver
    }
    var committed: [String] = []
    game.testingChunkGenerationResolutionHook = { event in
        if event.disposition == .adopted {
            committed.append(streamingEventKey(event.request))
        }
    }

    for (dimension, cx, cz, _) in targets {
        guard let world = game.worlds[dimension],
              game.testingRequestChunkForPersistenceFreshness(
                world, cx: cx, cz: cz
              ) else {
            return nil
        }
    }
    guard streamingWait({ deliveries.count == targets.count }) else { return nil }
    let worldTickBeforeHeldWave = game.world.time
    _ = game.frame(dtMs: TICK_MS)
    let waveStalledWorldTick = game.world.time == worldTickBeforeHeldWave

    let requestedSequences = requests.keys.sorted()
    let deliveryOrder = reverseCompletion
        ? Array(requestedSequences.reversed())
        : requestedSequences
    var heldUntilWaveComplete = true
    for (index, sequence) in deliveryOrder.enumerated() {
        deliveries[sequence]?()
        if index + 1 < deliveryOrder.count,
           targets.contains(where: { dimension, cx, cz, _ in
               game.worlds[dimension]?.getChunk(cx, cz) != nil
           }) {
            heldUntilWaveComplete = false
        }
    }
    game.testingChunkGenerationCompletionGate = nil
    game.testingChunkGenerationCalculationHook = nil

    guard streamingWait({
        game.testingChunkGenerationRuntimeDiagnostics().outstandingRequestCount == 0
    }) else { return nil }

    let readiness = targets.map { dimension, cx, cz, _ in
        "\(dimension.rawValue):\(cx):\(cz):\(game.worlds[dimension]?.isChunkReady(cx, cz) == true)"
    }
    let entities = game.worlds.keys.sorted(by: { $0.rawValue < $1.rawValue }).flatMap {
        dimension -> [String] in
        guard let world = game.worlds[dimension] else { return [] }
        return world.entities.compactMap { reference -> Entity? in
            guard let entity = reference as? Entity, !entity.isPlayer else { return nil }
            return entity
        }.sorted(by: { $0.id < $1.id }).map {
            "\(dimension.rawValue):\($0.id):\($0.type):\($0.x):\($0.y):\($0.z)"
        }
    }
    let diagnostics = game.testingChunkGenerationRuntimeDiagnostics()
    let snapshot = StreamingOrderSnapshot(
        commitOrder: committed,
        targetReadiness: readiness,
        entitySequence: entities,
        nextEntityID: peekNextEntityId(),
        maximumConcurrentCalculations: diagnostics.maximumConcurrentCalculationCount,
        maximumGenerationCapacity: diagnostics.maximumGenerationCapacity,
        heldUntilWaveComplete: heldUntilWaveComplete,
        waveStalledWorldTick: waveStalledWorldTick
    )
    _ = game.exitToTitle()
    game.db.deleteWorld(worldID)
    return snapshot
}

private func runStreamingCompletionOrderProof() {
    let forward = streamingForcedOrderSnapshot(
        label: "forward", reverseCompletion: false
    )
    let reverse = streamingForcedOrderSnapshot(
        label: "reverse", reverseCompletion: true
    )
    check(
        "Core generation keeps concurrent calculation capacity",
        forward?.maximumConcurrentCalculations ?? 0 >= 3
            && reverse?.maximumConcurrentCalculations ?? 0 >= 3
            && forward?.maximumGenerationCapacity == 24
            && reverse?.maximumGenerationCapacity == 24
    )
    check(
        "opposite worker completion orders commit one request order",
        forward != nil
            && forward?.commitOrder == reverse?.commitOrder
            && forward?.commitOrder == ["0:0:12:0", "1:1:12:0", "2:2:12:0"]
            && forward?.heldUntilWaveComplete == true
            && reverse?.heldUntilWaveComplete == true
            && forward?.waveStalledWorldTick == true
            && reverse?.waveStalledWorldTick == true
    )
    check(
        "ordered commit preserves identical ready chunks and physical identities",
        forward?.targetReadiness == reverse?.targetReadiness
            && forward?.targetReadiness.allSatisfy({ $0.hasSuffix(":true") }) == true
            && forward?.entitySequence == reverse?.entitySequence
            && forward?.nextEntityID == reverse?.nextEntityID
    )
}

private func runStreamingFreshnessTombstoneProof() {
    let game = GameCore()
    let worldID = "ps01-i07-stream-freshness"
    let targets: [(Dim, Int, Int, String)] = [
        (.overworld, 14, 0, "cow"),
        (.overworld, 15, 0, "pig"),
    ]
    guard streamingInstall(game, worldID: worldID, targets: targets) else {
        check("ordered freshness fixture installs", false)
        return
    }
    game.loadWorld(worldID)
    var deliveries: [UInt64: () -> Void] = [:]
    game.testingChunkGenerationCompletionGate = { event, deliver in
        deliveries[event.requestSequence] = deliver
    }
    var resolutions: [String] = []
    game.testingChunkGenerationResolutionHook = { event in
        resolutions.append(
            "\(event.request.requestSequence):\(event.disposition.rawValue)"
        )
    }
    for (_, cx, cz, _) in targets {
        _ = game.testingRequestChunkForPersistenceFreshness(
            game.world, cx: cx, cz: cz
        )
    }
    guard streamingWait({ deliveries[0] != nil && deliveries[1] != nil }) else {
        check("ordered freshness completions arrive", false)
        return
    }
    deliveries[1]?()
    let bufferedBeforeFreshness = game.testingChunkGenerationRuntimeDiagnostics()
    let superseded = game.testingSupersedeChunkGenerationSaveSequence(
        game.world, cx: 14, cz: 0
    ) != nil
    deliveries[0]?()
    guard streamingWait({ deliveries[2] != nil }) else {
        check("stale ordered request deterministically requeues", false)
        return
    }
    game.testingChunkGenerationCompletionGate = nil
    deliveries[2]?()
    let drained = streamingWait {
        game.testingChunkGenerationRuntimeDiagnostics().outstandingRequestCount == 0
    }
    check(
        "save-freshness tombstone advances ordered commit horizon",
        bufferedBeforeFreshness.completedAwaitingCommitCount == 1
            && bufferedBeforeFreshness.nextCommitSequence == 0
            && superseded
            && drained
            && resolutions == [
                "0:requeuedForSaveFreshness",
                "1:adopted",
                "2:adopted",
            ]
            && game.world.isChunkReady(14, 0)
            && game.world.isChunkReady(15, 0)
    )
    _ = game.exitToTitle()
    game.db.deleteWorld(worldID)
}

private func runStreamingPlayerCancellationProof() {
    let game = GameCore()
    let worldID = "ps01-i07-stream-player-cancel"
    let targets: [(Dim, Int, Int, String)] = [
        (.overworld, 20, 0, "cow"),
    ]
    guard streamingInstall(game, worldID: worldID, targets: targets) else {
        check("ordered player-cancellation fixture installs", false)
        return
    }
    game.loadWorld(worldID)
    game.player.setPos(20 * 16 + 0.5, 65, 0.5)
    var deliveries: [UInt64: () -> Void] = [:]
    game.testingChunkGenerationCompletionGate = { event, deliver in
        deliveries[event.requestSequence] = deliver
    }
    var resolutions: [String] = []
    game.testingChunkGenerationResolutionHook = { event in
        resolutions.append(
            "\(event.request.requestSequence):\(event.disposition.rawValue)"
        )
    }
    guard game.testingRequestPlayerStreamingChunkForDeterminism(
        game.world, cx: 20, cz: 0
    ), streamingWait({ deliveries[0] != nil }) else {
        check("player-stream cancellation reaches deterministic gate", false)
        return
    }

    game.player.setPos(0.5, 65, 0.5)
    deliveries[0]?()
    let cancellationAdvanced = streamingWait {
        game.testingChunkGenerationRuntimeDiagnostics().outstandingRequestCount == 0
    }
    let afterCancellation = game.testingChunkGenerationRuntimeDiagnostics()
    let cancelledChunkStayedAbsent = game.world.getChunk(20, 0) == nil
    let explicitReplacement = game.testingRequestChunkForPersistenceFreshness(
        game.world, cx: 20, cz: 0
    )
    guard explicitReplacement, streamingWait({ deliveries[1] != nil }) else {
        check("explicit replacement follows player-stream tombstone", false)
        return
    }
    deliveries[1]?()
    game.testingChunkGenerationCompletionGate = nil
    let replacementAdopted = streamingWait {
        game.world.isChunkReady(20, 0)
            && game.testingChunkGenerationRuntimeDiagnostics()
                .outstandingRequestCount == 0
    }
    check(
        "obsolete player-stream request tombstones without blocking later commit",
        cancellationAdvanced
            && afterCancellation.nextCommitSequence == 1
            && cancelledChunkStayedAbsent
            && replacementAdopted
            && resolutions == [
                "0:discardedNoLongerRequested",
                "1:adopted",
            ]
    )
    _ = game.exitToTitle()
    game.db.deleteWorld(worldID)
}

private func runStreamingWorldEpochProof() {
    let game = GameCore()
    let oldID = "ps01-i07-stream-old-world"
    let newID = "ps01-i07-stream-new-world"
    let oldTargets: [(Dim, Int, Int, String)] = [(.overworld, 16, 0, "cow")]
    let newTargets: [(Dim, Int, Int, String)] = [(.overworld, 17, 0, "pig")]
    guard streamingInstall(game, worldID: oldID, targets: oldTargets),
          game.db.putWorld(streamingRecord(newID)),
          game.db.putChunks(newTargets.map {
            streamingChunkRecord(
                game: game,
                worldID: newID,
                dimension: $0.0,
                cx: $0.1,
                cz: $0.2,
                entityType: $0.3
            )
          }) else {
        check("ordered World epoch fixture installs", false)
        return
    }
    game.loadWorld(oldID)
    var oldDelivery: (() -> Void)?
    game.testingChunkGenerationCompletionGate = { _, deliver in
        oldDelivery = deliver
    }
    var discardedOldEpoch = false
    game.testingChunkGenerationResolutionHook = { event in
        if event.disposition == .discardedWorldEpoch {
            discardedOldEpoch = true
        }
    }
    _ = game.testingRequestChunkForPersistenceFreshness(
        game.world, cx: 16, cz: 0
    )
    guard streamingWait({ oldDelivery != nil }) else {
        check("old World completion reaches deterministic gate", false)
        return
    }
    game.loadWorld(newID)
    game.testingChunkGenerationCompletionGate = nil
    oldDelivery?()
    let oldCompletionDiscarded = discardedOldEpoch
        && game.worldRec?.id == newID
        && game.world.getChunk(16, 0) == nil
        && game.testingChunkGenerationRuntimeDiagnostics().outstandingRequestCount == 0
    _ = game.testingRequestChunkForPersistenceFreshness(
        game.world, cx: 17, cz: 0
    )
    let newWorldProgresses = streamingWait {
        game.world.isChunkReady(17, 0)
            && game.testingChunkGenerationRuntimeDiagnostics().outstandingRequestCount == 0
    }
    check(
        "old World completion cannot commit or block replacement World",
        oldCompletionDiscarded && newWorldProgresses
    )
    _ = game.exitToTitle()
    game.db.deleteWorld(oldID)
    game.db.deleteWorld(newID)
}

private func runStreamingLightOrderProof() {
    let game = GameCore()
    let worldID = "ps01-i07-stream-light-order"
    let targetCoordinates = [
        (0, -5),
        (3, -4),
        (4, -3),
        (5, 0),
        (4, 3),
    ]
    let targets: [(Dim, Int, Int, String)] = targetCoordinates.map {
        (.overworld, $0.0, $0.1, "cow")
    }
    guard streamingInstall(game, worldID: worldID, targets: targets) else {
        check("deterministic light-order fixture installs", false)
        return
    }
    game.loadWorld(worldID)
    game.world.randomTickSpeed = 0
    game.world.gameRules["doMobSpawning"] = 0
    let targetKeys = Set(targetCoordinates.map { chunkKey($0.0, $0.1) })
    for (cx, cz) in targetCoordinates {
        for dz in -1...1 {
            for dx in -1...1 {
                let nx = cx + dx
                let nz = cz + dz
                let key = chunkKey(nx, nz)
                if targetKeys.contains(key) || game.world.getChunk(nx, nz) != nil {
                    continue
                }
                let chunk = Chunk(
                    cx: nx,
                    cz: nz,
                    minY: game.world.info.minY,
                    height: game.world.info.height
                )
                chunk.status = .generated
                game.world.setChunk(chunk)
            }
        }
    }
    for (cx, cz) in targetCoordinates {
        _ = game.testingRequestChunkForPersistenceFreshness(
            game.world, cx: cx, cz: cz
        )
    }
    guard streamingWait({
        game.testingChunkGenerationRuntimeDiagnostics().outstandingRequestCount == 0
    }) else {
        check("deterministic light-order targets commit", false)
        return
    }
    _ = game.frame(dtMs: TICK_MS)
    let statuses = targetCoordinates.map {
        game.world.getChunk($0.0, $0.1)?.status
    }
    check(
        "equal-distance lighting uses coordinate tie-break and fixed work bound",
        statuses.prefix(4).allSatisfy({ $0 == .lit })
            && statuses.last == .generated
    )
    _ = game.exitToTitle()
    game.db.deleteWorld(worldID)
}

private struct StreamingLightChunkSnapshot: Equatable {
    let key: Int64
    let status: Chunk.ChunkStatus
    let blocks: [UInt16]
    let skyLight: [UInt8]
    let blockLight: [UInt8]
}

private struct StreamingLightSnapshot: Equatable {
    let worldTick: Int
    let chunks: [StreamingLightChunkSnapshot]
    let pendingLightKeys: [Int64]
    let scheduledWork: [[Int]]
    let entities: [String]
    let nextEntityID: Int
}

private func streamingLightSnapshot(_ game: GameCore) -> StreamingLightSnapshot {
    StreamingLightSnapshot(
        worldTick: game.world.time,
        chunks: game.world.chunks.keys.sorted().compactMap { key in
            guard let c = game.world.chunks[key] else { return nil }
            return StreamingLightChunkSnapshot(
                key: key, status: c.status, blocks: c.blocks,
                skyLight: c.skyLight, blockLight: c.blockLight
            )
        },
        pendingLightKeys: game.testingPendingLightChunkKeys(),
        scheduledWork: game.world.testingScheduledTickSnapshot(),
        entities: game.world.entities.compactMap { $0 as? Entity }
            .sorted(by: { $0.id < $1.id }).map {
                "\($0.id):\($0.type):\($0.x):\($0.y):\($0.z):\($0.vx):\($0.vy):\($0.vz)"
            },
        nextEntityID: peekNextEntityId()
    )
}

private func streamingFrameSchedule(
    label: String, batched: Bool
) -> [StreamingLightSnapshot]? {
    let previousGameRNG = gameRng
    resetGameRng(14)
    defer { gameRng = previousGameRNG }
    let game = GameCore()
    let worldID = "ps01-i07-light-cadence-\(label)"
    let targets = [(0, -5), (3, -4), (4, -3), (5, 0), (4, 3)]
    guard streamingInstall(
        game, worldID: worldID,
        targets: targets.map { (.overworld, $0.0, $0.1, "cow") }
    ) else { return nil }
    // Dry spawn avoids unrelated worldgen-fluid work in this small fixture.
    var spawnRecords: [ChunkRecord] = []
    for cz in -1...1 {
        for cx in -1...1 {
            var record = streamingChunkRecord(
                game: game, worldID: worldID, dimension: .overworld,
                cx: cx, cz: cz, entityType: "cow"
            )
            record.entities = []
            spawnRecords.append(record)
        }
    }
    guard game.db.putChunks(spawnRecords) else { return nil }
    game.loadWorld(worldID)
    defer {
        _ = game.exitToTitle()
        game.db.deleteWorld(worldID)
    }
    game.settings.renderDistance = 4
    game.world.randomTickSpeed = 0
    game.world.gameRules["doMobSpawning"] = 0
    game.world.gameRules["doWeatherCycle"] = 0
    // A fully resident, inert streaming ring isolates lighting from asynchronous
    // calculation (whose ordering is separately tested above). Targets alone
    // enter the real production lighting queue through ordered chunk adoption.
    let targetKeys = Set(targets.map { chunkKey($0.0, $0.1) })
    for cz in -6...6 {
        for cx in -6...6 where !targetKeys.contains(chunkKey(cx, cz)) {
            let c = Chunk(cx: cx, cz: cz, minY: game.world.info.minY,
                          height: game.world.info.height)
            c.status = .lit
            game.world.setChunk(c)
        }
    }
    for (cx, cz) in targets {
        _ = game.testingRequestChunkForPersistenceFreshness(game.world, cx: cx, cz: cz)
    }
    guard streamingWait({
        game.testingChunkGenerationRuntimeDiagnostics().outstandingRequestCount == 0
    }) else { return nil }
    // Fixture setup only: no scheduled work is injected. Production lightChunk
    // must wake these actual fluids, and ordinary World ticks must execute them.
    for (cx, cz) in targets {
        guard let c = game.world.getChunk(cx, cz) else { return nil }
        c.set(8, 65, 8, B.water << 4)
        c.set(10, 65, 10, (B.lava << 4) | 1)
    }
    let initial = streamingLightSnapshot(game)
    for _ in 0..<3 { _ = game.frame(dtMs: 0) }
    check(
        "\(label): zero-tick frames leave lighting, fluids, identities and World unchanged",
        initial == streamingLightSnapshot(game)
            && initial.scheduledWork.isEmpty
            && targetKeys.isSubset(of: Set(initial.pendingLightKeys))
    )
    for ticks in (batched ? [2] : [1, 1]) {
        _ = game.frame(dtMs: Double(ticks) * TICK_MS)
    }
    let afterTwo = streamingLightSnapshot(game)
    check(
        "\(label): two World ticks light five chunks and schedule exact fluid due times",
        afterTwo.worldTick == 2
            && afterTwo.pendingLightKeys.isEmpty
            && targets.allSatisfy { game.world.getChunk($0.0, $0.1)?.status == .lit }
            && afterTwo.scheduledWork.map { $0[0] } == [5, 5, 5, 5, 6, 30, 30, 30, 30, 31]
    )
    for ticks in (batched ? [4] : [1, 1, 1, 1]) {
        _ = game.frame(dtMs: Double(ticks) * TICK_MS)
    }
    let afterSix = streamingLightSnapshot(game)
    check(
        "\(label): scheduled water physically flows under ordinary World ticks",
        afterSix.worldTick == 6 && targets.allSatisfy {
            game.world.getBlockId($0.0 * CHUNK_W + 8, 64, $0.1 * CHUNK_W + 8) == Int(B.water)
        }
    )
    return [initial, afterTwo, afterSix]
}

private func runStreamingFrameCadenceProof() {
    let separate = streamingFrameSchedule(label: "one-tick-frames", batched: false)
    let batched = streamingFrameSchedule(label: "two-and-four-tick-frames", batched: true)
    check(
        "render batching preserves exact lighting, scheduled work, physical cells and identities",
        separate != nil && separate == batched
    )
}

func runPebbleCoreStreamingDeterminismSmoke() {
    section("PS01 Increment 07 Core streaming determinism")
    runStreamingCompletionOrderProof()
    runStreamingFreshnessTombstoneProof()
    runStreamingPlayerCancellationProof()
    runStreamingWorldEpochProof()
    runStreamingLightOrderProof()
    runStreamingFrameCadenceProof()
}
