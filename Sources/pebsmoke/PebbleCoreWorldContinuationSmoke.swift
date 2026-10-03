import Foundation
import PebbleCore

func runPebbleCoreWorldContinuationSmoke() {
    section("PS01 Increment 08 physical continuation publication")
    let db = SaveDB()
    let id = "ps01-i08-core-boundary"
    db.deleteWorld(id)
    let world = WorldRecord(id: id, name: "I08 bounded proof", seed: 46, gameMode: GameMode.survival, difficulty: 2)
    check("I08 ordinary World remains continuation-free", db.putWorld(world) && db.worldContinuation(id) == nil)
    check("I08 requirement established fail closed", db.requireWorldContinuation(id) && db.worldContinuation(id)?.payload == nil)
    let payload = Data("immutable-checkpoint-reference".utf8)
    func publish() -> Bool {
        guard let revision = db.worldContinuation(id)?.revision else { return false }
        return db.publishWorldContinuation(id, revision: revision, payload: payload)
    }
    check("I08 reference publishes at exact physical revision", publish() && db.worldContinuation(id)?.payload == payload)
    let oldRevision = db.worldContinuation(id)!.revision
    check("I08 World write atomically invalidates reference", db.putWorld(world) && db.worldContinuation(id)?.payload == nil)
    check("I08 stale revision cannot publish", !db.publishWorldContinuation(id, revision: oldRevision, payload: payload))
    _ = publish()
    check("I08 player write invalidates reference", db.putPlayer(id, ["dim": 0, "data": [:]]) && db.worldContinuation(id)?.payload == nil)
    _ = publish()
    check("I08 advancement write invalidates reference", db.putAdvancements(id, []) && db.worldContinuation(id)?.payload == nil)
    _ = publish()
    let chunk = ChunkRecord(key: db.chunkKey(id, 0, 0, 0), worldId: id, dim: 0, cx: 0, cz: 0)
    check("I08 streaming chunk commit invalidates reference", db.putChunks([chunk]) && db.worldContinuation(id)?.payload == nil)
    _ = publish()
    check("I08 physical receipt write invalidates reference", db.putWorldReceiptIfAbsent(worldID: id, kind: "i08-test", receiptID: "one", data: Data([1])) && db.worldContinuation(id)?.payload == nil)
    _ = publish()
    check("I08 physical receipt retirement atomically invalidates reference", db.deleteWorldReceipt(worldID: id, kind: "i08-test", receiptID: "one") && db.worldContinuation(id)?.payload == nil)
    _ = publish()
    let beforeRefusal = db.worldContinuation(id)!
    db.testingRequiredPersistenceWriteHook = { _ in false }
    check("I08 refused physical write preserves previous boundary", !db.putWorld(world) && db.worldContinuation(id)?.revision == beforeRefusal.revision && db.worldContinuation(id)?.payload == beforeRefusal.payload)
    db.testingRequiredPersistenceWriteHook = nil
    db.testingContinuationPublicationRefusal = { true }
    check("I08 late publication refuses without selecting candidate", !publish() && db.worldContinuation(id)?.payload == beforeRefusal.payload)
    db.testingContinuationPublicationRefusal = nil
    db.deleteWorld(id)
    check("I08 World deletion removes requirement", db.worldContinuation(id) == nil)

    let game = GameCore()
    _ = game.db.putWorld(world)
    game.loadWorld(id)
    _ = game.db.requireWorldContinuation(id)
    var phases: [String] = []
    game.requiresExternalContinuation = { true }
    game.prepareExternalContinuation = { phases.append("capture"); return true }
    game.prepareExternalLifecycleState = { phases.append("custody"); return true }
    game.completeExternalContinuation = { saved, exiting in
        phases.append("publish-\(saved)-\(exiting)")
        return saved
    }
    game.cancelExternalContinuation = { true }
    game.finalizeExternalLifecycleState = { phases.append("teardown") }
    let nether = game.worlds[.nether]!
    _ = game.prepareWorldContinuationChunks(dimension: Dim.nether.rawValue, coordinates: [(0, 0)])
    let priorAnchor = nether.getBlock(0, 70, 0)
    let chargedAnchor = Int(cell(B.respawn_anchor, 1))
    nether.setBlock(0, 70, 0, chargedAnchor)
    game.player.spawnDim = Dim.nether.rawValue
    game.player.spawnPoint = (0, 70, 0)
    let boundWorld = game.world
    game.respawnPlayer()
    check("I08 cross-dimension respawn preserves bound World and consumes no anchor charge", game.world === boundWorld && game.dim == .overworld && nether.getBlock(0, 70, 0) == chargedAnchor)
    nether.setBlock(0, 70, 0, priorAnchor)
    game.player.spawnDim = Dim.overworld.rawValue
    game.player.spawnPoint = nil
    check("I08 capture while remaining preserves loaded World", game.saveAndFlush() && game.hasWorld() && phases == ["capture", "publish-true-false"])
    phases = []
    game.db.testingRequiredPersistenceWriteHook = { $0 != .player }
    check("I08 failed exit compensates before teardown", !game.exitToTitle() && game.hasWorld() && phases == ["capture", "custody", "publish-false-false"])
    phases = []
    game.db.testingRequiredPersistenceWriteHook = nil
    check("I08 retry publishes before irreversible teardown", game.exitToTitle() && phases == ["capture", "custody", "publish-true-true", "teardown"])
    let refused = GameCore()
    refused.loadWorld(id)
    let time = refused.world.time
    _ = refused.frame(dtMs: TICK_MS)
    check("I08 required continuation without adapter cannot progress", !refused.worldContinuationReady && refused.world.time == time && !refused.saveAndFlush(synchronous: true))
    check("I08 refused entry can leave without overwriting World", refused.exitToTitle() && !refused.hasWorld())
    let missing = GameCore()
    missing.restoreExternalContinuation = { true }
    missing.loadWorld(id)
    missing.requiresExternalContinuation = { false }
    check("I08 missing live adapter cannot fall back to successful physical-only save", !missing.saveAndFlush() && !missing.exitToTitle() && missing.hasWorld())
    game.db.deleteWorld(id)
    runI08LifecycleCancellationSmoke()
}

private func runI08LifecycleCancellationSmoke() {
    section("PS01 I08 Blocker 02 lifecycle cancellation ordering")
    let game = GameCore()
    let id = "ps01-i08-core-cancellation"
    let record = WorldRecord(id: id, name: "B02 ordering", seed: 46,
        gameMode: GameMode.survival, difficulty: 2)
    _ = game.db.putWorld(record)
    game.loadWorld(id)
    _ = game.db.requireWorldContinuation(id)
    var phases: [String] = []
    var cancellations = 0
    var vanishedDestination: String?
    game.requiresExternalContinuation = { true }
    game.prepareExternalContinuation = { phases.append("capture"); return true }
    game.prepareExternalLifecycleState = { phases.append("custody"); return true }
    game.completeExternalContinuation = { [weak game] saved, exiting in
        phases.append("publish-\(saved)-\(exiting)")
        if let destination = vanishedDestination { game?.db.deleteWorld(destination) }
        return saved
    }
    game.cancelExternalContinuation = {
        cancellations += 1; phases.append("cancel"); return true
    }
    game.finalizeExternalLifecycleState = { phases.append("teardown") }
    let original = game.world
    var writes = 0
    game.db.testingRequiredPersistenceWriteHook = { write in
        guard write == .world else { return true }
        writes += 1; return writes == 1
    }
    game.createWorld(name: "B02 metadata refusal", seedText: "14", mode: GameMode.survival, difficulty: 2)
    game.db.testingRequiredPersistenceWriteHook = nil
    check("B02 destination write refusal cancels after publication before teardown",
        writes == 2 && game.world === original && phases == ["capture", "custody", "publish-true-true", "cancel"])
    check("B02 duplicate cancellation does not repeat the owner callback",
        game.cancelPreparedLifecycle() && game.cancelPreparedLifecycle() && cancellations == 1)
    phases = []
    let time = game.world.time
    let prepared = game.prepareForTermination()
    _ = game.frame(dtMs: TICK_MS)
    check("B02 prepared decision blocks physical progression and capture",
        prepared && game.world.time == time && !game.saveAndFlush())
    check("B02 repeated preparation retains one boundary",
        game.prepareForTermination() && phases == ["capture", "custody", "publish-true-true"])
    check("B02 verified cancellation resumes the old World without teardown",
        game.cancelPreparedLifecycle() && game.world === original && phases.last == "cancel" && !phases.contains("teardown"))
    let destination = "ps01-i08-core-disappearing-destination"
    var target = record; target.id = destination
    _ = game.db.putWorld(target)
    vanishedDestination = destination
    phases = []
    game.loadWorld(destination)
    vanishedDestination = nil
    check("B02 destination second-read refusal uses equivalent cancellation",
        game.db.getWorld(destination) == nil && game.world === original
        && phases == ["capture", "custody", "publish-true-true", "cancel"])
    phases = []
    game.createWorld(name: "B02 replacement retry", seedText: "14", mode: GameMode.survival, difficulty: 2)
    check("B02 replacement retry commits teardown without cancellation",
        game.world !== original && phases == ["capture", "custody", "publish-true-true", "teardown"])
    let newTime = game.world.time
    game.cancelExternalContinuation = { false }
    let finalPreparation = game.prepareForTermination()
    let refused = !game.cancelPreparedLifecycle()
    _ = game.frame(dtMs: TICK_MS)
    check("B02 failed cancellation blocks progression, save, completion and replay",
        finalPreparation && refused && game.world.time == newTime && !game.saveAndFlush()
        && !game.completePreparedLifecycle() && !game.prepareForTermination() && !game.cancelPreparedLifecycle())
    game.player.inventory[game.player.selectedSlot] = ItemStack(iid("dirt"), 1)
    let entities = game.world.entities.count
    game.keyDown(game.keybinds["drop"]!, now: 0)
    check("B03 blocked lifecycle refuses direct physical input and destructive Core probe cleanup",
        !game.worldMutationAllowed && game.world.entities.count == entities
        && game.player.inventory[game.player.selectedSlot]?.count == 1 && game.clearLabCoreAgentProbes() == 0)
    game.cancelExternalContinuation = { true }
    check("B03 explicitly re-verified cancellation recovers the existing blocked lifecycle",
        game.cancelPreparedLifecycle() && game.worldMutationAllowed && game.world.time == newTime)
    _ = game.frame(dtMs: TICK_MS)
    check("B03 recovered lifecycle progresses and duplicate cancellation remains idempotent",
        game.world.time > newTime && game.cancelPreparedLifecycle())
}
