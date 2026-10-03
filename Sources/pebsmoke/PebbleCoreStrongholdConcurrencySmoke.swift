import Foundation
import PebbleCore

private func strongholdContext(_ seed: UInt32) -> GenCtx {
    GenCtx(seed: seed, heightAt: { _, _ in 64 }, biomeAt: { _, _ in 0 }, dim: 0)
}

private func strongholdPlanShape(_ plan: StructurePlan?) -> [[Int]]? {
    guard let plan else { return nil }
    return plan.pieces.map { [$0.x0, $0.y0, $0.z0, $0.x1, $0.y1, $0.z1] }
        + [plan.ref.map { [$0.x0, $0.y0, $0.z0, $0.x1, $0.y1, $0.z1] } ?? []]
}

private func strongholdWait(_ condition: () -> Bool) -> Bool {
    let deadline = Date(timeIntervalSinceNow: 30)
    while Date() < deadline {
        if condition() { return true }
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.005))
    }
    return condition()
}

/// Schedules the real registered check without supplying a plan or chunk.
/// The incoming synchronous lookup releases two preempted outgoing workers,
/// then waits until an outgoing worker reaches the same production check.
private final class StrongholdOverlapSchedule {
    let releaseWorkers = DispatchSemaphore(value: 0)
    let outgoingLookup = DispatchSemaphore(value: 0)
    private let lock = NSLock()
    private var incomingStarted = false
    private var outgoingStarted = false
    private var acquiredOverlap = false
    private var timedOut = false

    func beforeCalculation() {
        if releaseWorkers.wait(timeout: .now() + 30) != .success {
            lock.lock(); timedOut = true; lock.unlock()
        }
    }

    func beforeCheck(incoming: Bool) {
        lock.lock()
        let firstIncoming = incoming && !incomingStarted
        let firstOutgoing = !incoming && incomingStarted && !outgoingStarted
        if firstIncoming { incomingStarted = true }
        if firstOutgoing { outgoingStarted = true }
        lock.unlock()
        if firstIncoming {
            releaseWorkers.signal()
            releaseWorkers.signal()
            let reached = outgoingLookup.wait(timeout: .now() + 30) == .success
            lock.lock(); acquiredOverlap = reached; timedOut = timedOut || !reached; lock.unlock()
        }
        if firstOutgoing { outgoingLookup.signal() }
    }

    var succeeded: Bool {
        lock.lock(); defer { lock.unlock() }
        return acquiredOverlap && !timedOut
    }
}

private func strongholdReplacement(_ def: StructureDef, registryIndex: Int) {
    let game = GameCore()
    let seeds: [UInt32] = [14, 73, 887, 14]
    let ids = seeds.enumerated().map { "ps01-b04-stronghold-\($0.offset)" }
    defer {
        _ = game.exitToTitle()
        for id in ids { game.db.deleteWorld(id) }
    }
    for (index, seed) in seeds.enumerated() {
        game.db.deleteWorld(ids[index])
        let origin = strongholdPositions(seed)[0]
        var rec = WorldRecord(id: ids[index], name: "B04 Core overlap", seed: Int32(bitPattern: seed),
                              gameMode: GameMode.creative, difficulty: 0)
        rec.spawnX = origin.0 * 16 + 8
        rec.spawnY = 65
        rec.spawnZ = origin.1 * 16 + 8
        check("B04 World record \(index) admitted", game.db.putWorld(rec))
    }
    game.loadWorld(ids[0])
    check("B04 ordinary initial World load", game.hasWorld() && game.world.seed == seeds[0])
    guard game.hasWorld() else { return }

    for boundary in 1..<seeds.count {
        let oldWorld = game.world
        let oldOrigin = strongholdPositions(oldWorld.seed)[0]
        let newSeed = seeds[boundary]
        let newOrigin = strongholdPositions(newSeed)[0]
        // Capture the seed's production output before the overlap. No World
        // result is installed by the harness; loadWorld must produce it itself.
        let expected = generateChunk(.overworld, newSeed, newOrigin.0, newOrigin.1)
        let schedule = StrongholdOverlapSchedule()
        let oldEpoch = game.testingChunkGenerationRuntimeDiagnostics().epoch
        var discarded = 0
        game.testingChunkGenerationResolutionHook = { event in
            if event.request.epoch == oldEpoch && event.disposition == .discardedWorldEpoch {
                discarded += 1
            }
        }
        // Replace only the check's scheduling envelope, preserving registry
        // order, all definition fields and the exact original check/plan.
        STRUCTURES[registryIndex] = StructureDef(
            id: def.id, spacing: def.spacing, separation: def.separation,
            salt: def.salt, maxRadiusChunks: def.maxRadiusChunks,
            check: { ctx, x, z, rng in
                schedule.beforeCheck(incoming: ctx.seed == newSeed)
                return def.check(ctx, x, z, rng)
            }, plan: def.plan
        )
        game.testingChunkGenerationCalculationHook = { _ in schedule.beforeCalculation() }
        check("B04 outgoing own stronghold request \(boundary)",
              game.testingRequestChunkForPersistenceFreshness(oldWorld, cx: oldOrigin.0 + 2, cz: oldOrigin.1))
        check("B04 outgoing request at incoming coordinates \(boundary)",
              game.testingRequestChunkForPersistenceFreshness(oldWorld, cx: newOrigin.0, cz: newOrigin.1))
        check("B04 two old calculations in flight \(boundary)", strongholdWait {
            game.testingChunkGenerationRuntimeDiagnostics().activeCalculationCount == 2
        })
        game.loadWorld(ids[boundary])
        game.testingChunkGenerationCalculationHook = nil
        check("B04 synchronous incoming/old worker lookup overlap \(boundary)", schedule.succeeded)
        check("B04 ordinary replacement advances epoch \(boundary)",
              game.hasWorld() && game.world !== oldWorld && game.world.seed == newSeed
              && game.testingChunkGenerationRuntimeDiagnostics().epoch == oldEpoch + 1)
        let resolved = strongholdWait {
            discarded == 2 && game.testingChunkGenerationRuntimeDiagnostics().activeCalculationCount == 0
        }
        check("B04 both stale calculations discarded \(boundary)", resolved)
        // Restore the registry only after every calculation and delivery ends.
        guard resolved else {
            print("\n\(passed) passed, \(failed) failed"); exit(1)
        }
        STRUCTURES[registryIndex] = def
        game.testingChunkGenerationResolutionHook = nil
        let chunk = game.world.getChunk(newOrigin.0, newOrigin.1)
        check("B04 incoming blocks equal isolated seeded generation \(boundary)", chunk?.blocks == expected.blocks)
        check("B04 incoming biomes equal isolated seeded generation \(boundary)", chunk?.biomes == expected.biomes)
        check("B04 stale work installs no chunk in outgoing World \(boundary)",
              oldWorld.getChunk(oldOrigin.0 + 2, oldOrigin.1) == nil
              && oldWorld.getChunk(newOrigin.0, newOrigin.1) == nil)
        print("B04_OVERLAP boundary=\(boundary) oldSeed=\(oldWorld.seed) newSeed=\(newSeed) stale=\(discarded) epoch=\(oldEpoch + 1)")
    }
}

func runPebbleCoreStrongholdConcurrencySmoke() {
    section("Core cross-World stronghold ownership and concurrency")
    registerAllBlocks(); registerAllItems(); registerAllBiomes(); registerAllRecipes()
    registerAllLootTables(); registerAllEntities(); registerAllSystems(); registerAllStructures()
    guard let index = STRUCTURES.firstIndex(where: { $0.id == "stronghold" }) else {
        check("B04 canonical stronghold registered", false); return
    }
    let def = STRUCTURES[index]
    let seeds: [UInt32] = [0, 14, 46, 73, 887, UInt32.max]
    for seed in seeds {
        let positions = strongholdPositions(seed)
        let ctx = strongholdContext(seed)
        check("B04 seed \(seed) has 19 repeatable ring positions", positions.count == 19
              && positions.map { [$0.0, $0.1] } == strongholdPositions(seed).map { [$0.0, $0.1] })
        for (x, z) in positions {
            let rng = Rng(123)
            let state = rng.r
            check("B04 seed \(seed) placement (\(x),\(z))", def.check(ctx, x, z, rng) && rng.r == state)
            let expected = def.plan(ctx, x, z, Rng(hash2(seed, x, z, def.salt ^ 0x1234)))
            check("B04 seed \(seed) plan repeat (\(x),\(z))",
                  strongholdPlanShape(getPlan(def, ctx, x, z)) == strongholdPlanShape(expected)
                  && strongholdPlanShape(getPlan(def, ctx, x, z)) == strongholdPlanShape(expected))
            for foreign in seeds where foreign != seed {
                let other = strongholdContext(foreign)
                let belongs = strongholdPositions(foreign).contains { $0.0 == x && $0.1 == z }
                check("B04 cached seed \(seed) origin queried by \(foreign) (\(x),\(z))",
                      (getPlan(def, other, x, z) != nil) == belongs)
            }
        }
    }
    let lock = NSLock()
    let group = DispatchGroup()
    var mismatches = 0
    for seed in seeds {
        group.enter()
        DispatchQueue.global().async {
            let ctx = strongholdContext(seed)
            var localMismatches = 0
            for _ in 0..<64 {
                for (x, z) in strongholdPositions(seed) {
                    if !def.check(ctx, x, z, Rng(0)) { localMismatches += 1 }
                    let expected = def.plan(ctx, x, z, Rng(hash2(seed, x, z, def.salt ^ 0x1234)))
                    if strongholdPlanShape(getPlan(def, ctx, x, z)) != strongholdPlanShape(expected) {
                        localMismatches += 1
                    }
                }
            }
            lock.lock(); mismatches += localMismatches; lock.unlock()
            group.leave()
        }
    }
    let finished = group.wait(timeout: .now() + 30) == .success
    check("B04 six concurrent seeded lookups finish within bound", finished)
    guard finished else {
        print("\n\(passed) passed, \(failed) failed"); exit(1)
    }
    check("B04 7296 concurrent placement/plan pairs remain exact", mismatches == 0, "mismatches=\(mismatches)")
    strongholdReplacement(def, registryIndex: index)
}

/// Ungated control: one retained Core, normal frame streaming and loadWorld.
/// No continuation controller, callbacks or generation scheduling envelopes.
func runPebbleCoreStrongholdOrdinaryReplacementSmoke(replacements: Int) {
    section("Core ordinary World replacement (\(replacements) boundaries)")
    registerAllBlocks(); registerAllItems(); registerAllBiomes(); registerAllRecipes()
    registerAllLootTables(); registerAllEntities(); registerAllSystems()
    let game = GameCore()
    game.createWorld(name: "B04 ordinary seed 14", seedText: "14",
                     mode: GameMode.survival, difficulty: 2)
    let initialID = game.worldRec?.id
    let ids = (1...replacements).map { "ps01-b04-ordinary-\($0)" }
    defer {
        _ = game.exitToTitle()
        if let initialID { game.db.deleteWorld(initialID) }
        for id in ids { game.db.deleteWorld(id) }
    }
    check("B04 ordinary seed-14 creation", game.hasWorld() && game.world.seed == 14)
    guard game.hasWorld() else { return }
    for boundary in 1...replacements {
        let id = ids[boundary - 1]
        game.db.deleteWorld(id)
        let seed: Int32 = boundary % 2 == 0 ? 14 : 73
        var rec = WorldRecord(id: id, name: "B04 ordinary replacement", seed: seed,
                              gameMode: GameMode.creative, difficulty: 1)
        rec.spawnX = 1; rec.spawnY = 65; rec.spawnZ = 1
        check("B04 ordinary destination \(boundary) stored", game.db.putWorld(rec))
        let oldWorld = game.world
        _ = game.frame(dtMs: TICK_MS)
        let before = game.testingChunkGenerationRuntimeDiagnostics()
        check("B04 ordinary outgoing wave \(boundary) admitted", before.outstandingRequestCount > 0)
        game.loadWorld(id)
        check("B04 ordinary replacement \(boundary) admitted", game.hasWorld()
              && game.worldRec?.id == id && game.world !== oldWorld
              && game.world.seed == UInt32(bitPattern: seed)
              && game.testingChunkGenerationRuntimeDiagnostics().epoch == before.epoch + 1)
        let expected = generateChunk(.overworld, UInt32(bitPattern: seed), 0, 0)
        check("B04 ordinary destination \(boundary) matches seed", game.world.getChunk(0, 0)?.blocks == expected.blocks)
        print("B04_ORDINARY boundary=\(boundary) oldSeed=\(oldWorld.seed) newSeed=\(seed) outstanding=\(before.outstandingRequestCount) active=\(before.activeCalculationCount)")
    }
    check("B04 ordinary calculations finish within bound", strongholdWait {
        game.testingChunkGenerationRuntimeDiagnostics().activeCalculationCount == 0
    })
}
