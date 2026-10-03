import Foundation
import PebbleAgents
import PebbleCore

private struct Increment08Boundary: Codable {
    let worldID: String
    let seed: String
    let founders: Int
    let worldTick: Int
    let civilizationTick: Int
    let living: Int
    let semanticDigest: String
    let causalDigest: String
    let acquired: Int
    let consumed: UInt64
    let carried: Int
}

/// Test orchestration only. Ordinary Core saves and World entry run the same
/// installed adapter callbacks as the rendered app. The reader never starts
/// founders or issues a manual checkpoint command.
enum PebbleIncrement08ContinuationHarness {
    static func runIfRequested() -> Int32? {
        let env = ProcessInfo.processInfo.environment
        guard let phase = env["PEBBLELAB_PS01_INCREMENT08_PHASE"] else { return nil }
        do {
            guard let home = env["CFFIXED_USER_HOME"],
                  home.hasPrefix("/tmp/") || home.hasPrefix("/private/tmp/"),
                  let output = env["PEBBLELAB_PS01_INCREMENT08_OUTPUT"],
                  let seed = env["PEBBLELAB_PS01_INCREMENT08_SEED"],
                  let count = Int(env["PEBBLELAB_PS01_INCREMENT08_FOUNDERS"] ?? "24") else {
                throw HarnessError.refused("invalid isolated configuration")
            }
            try run(phase: phase, seed: seed, count: count, output: output)
            print("[ps01-i08] PASS phase=\(phase)")
            fflush(stdout)
            return 0
        } catch {
            fputs("[ps01-i08] FAIL \(error)\n", stderr)
            return 1
        }
    }

    private static func configure(_ game: GameCore, _ controller: PebbleAgentController) {
        game.settings.renderDistance = 4
        controller.worldSideReceiptDatabase = game.db
        controller.installWorldContinuation(on: game)
        game.physicalSimulationCoverageProvider = { [weak controller] world in
            controller?.physicalSimulationCoverageRequest(for: world) ?? .inactive
        }
        game.prepareExternalLifecycleState = { [weak controller, weak game] in
            guard let controller, let game else { return false }
            guard game.hasWorld() else { return controller.session == nil && controller.activeWorld == nil }
            return controller.prepareForLifecyclePersistence(world: game.world)
        }
        game.finalizeExternalLifecycleState = { [weak controller] in controller?.finalizeLifecycleAfterPersistence() }
    }

    private static func run(phase: String, seed: String, count: Int, output: String) throws {
        let game = GameCore()
        let controller = PebbleAgentController()
        configure(game, controller)
        let id = "ps01-i08-seed-\(seed)-founders-\(count)"
        var assertions = 0
        func require(_ condition: Bool, _ label: String) throws {
            assertions += 1
            guard condition else { throw HarnessError.refused(label + " lastError=" + (controller.lastError ?? "none")) }
            print("[ps01-i08] assertion=\(assertions) PASS \(label)")
        }
        if phase == "read" {
            let boundary = try JSONDecoder().decode(Increment08Boundary.self, from: Data(contentsOf: URL(fileURLWithPath: output)))
            game.loadWorld(id)
            try require(game.hasWorld() && game.worldContinuationReady && controller.session != nil, "normal World entry restores before first tick")
            let restored = try snapshot(game, controller, seed: seed, count: count)
            try require(restored.worldTick == boundary.worldTick && restored.civilizationTick == boundary.civilizationTick, "World and civilization time belong to one boundary")
            try require(restored.semanticDigest == boundary.semanticDigest && restored.causalDigest == boundary.causalDigest, "durable state and causal evidence restore exactly")
            try require(restored.living == boundary.living && restored.carried == boundary.carried && restored.acquired == boundary.acquired && restored.consumed == boundary.consumed, "population and material conserved without new founders")
            try require(game.world.entities.compactMap { $0 as? ItemEntity }.allSatisfy { $0.custodyProvenance?.hasPrefix(pebbleCheckpointCustodySpillRoot) != true }, "disk escrow adopted exactly once")
            let duplicate = game.restoreExternalContinuation?() ?? true
            try require(!duplicate && controller.session?.tick == boundary.civilizationTick && carried(controller) == boundary.carried, "duplicate restore refuses without duplicate effects")
            // A duplicate invocation is an attack, not a World entry failure.
            controller.continuationRestoreRefused = false
            let continuationLimit = boundary.carried > 0 ? 1200 : 20
            for elapsed in 0..<continuationLimit {
                try step(game, controller, id: id)
                if boundary.carried > 0, elapsed >= 19,
                   (controller.session?.physicalFoodSurvivalSnapshot()?.totalConsumedQuantity ?? 0) > boundary.consumed { break }
            }
            let continued = try snapshot(game, controller, seed: seed, count: count)
            try require(continued.worldTick > boundary.worldTick
                && (boundary.living == 0 ? continued.living == 0 : continued.civilizationTick > boundary.civilizationTick),
                "ordinary World continuation progresses and preserves extinction")
            if boundary.carried > 0 {
                try require(continued.consumed > boundary.consumed, "restored real custody remains eligible for ordinary physical food consumption")
            }
            try require(controller.runtimeErrorCount == 0 && controller.droppedCatchUpSteps == 0 && controller.fatalSessionIntegrityFailure == nil && controller.candidatePhysicalHardFailure == nil, "continuation has no runtime integrity failure")
            try require(game.exitToTitle() && controller.session == nil && controller.probesByAgentId.isEmpty, "continued World exits through ordinary boundary")
            let report: [String: Any] = ["phase": phase, "assertions": assertions, "worldID": id,
                "foundersCreated": 0, "loadedLiving": restored.living, "loadedCarried": restored.carried,
                "loadedDigest": restored.semanticDigest, "continuedDigest": continued.semanticDigest,
                "continuedTick": continued.civilizationTick, "continuedConsumed": continued.consumed,
                "worldCleanup": true]
            try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]).write(to: URL(fileURLWithPath: output + ".read.json"), options: .atomic)
            return
        }
        guard ["write", "envelope", "faults", "portal", "replacement", "compensation", "zero", "retention", "retention-manual"].contains(phase) else { throw HarnessError.refused("invalid phase") }
        game.createWorld(name: "PS01 Increment 08 normal seed \(seed)", seedText: seed, mode: GameMode.survival, difficulty: 2)
        var record = game.worldRec!
        let transient = record.id
        try require(game.exitToTitle(), "ordinary new World boundary")
        game.deleteWorld(transient)
        record.id = id
        record.lastPlayed = 0
        try require(game.db.putWorld(record), "seed World identity installs")
        game.loadWorld(id)
        for _ in 0..<52 { try step(game, controller, id: id) }
        let started = controller.start(world: game.world, player: game.player, founders: try PebbleNormalFounderProfile(count: count))
        try require(started.succeeded, "normal founders start once")
        if phase == "compensation" {
            try require(game.exitToTitle(), "compensation fixture leaves the initial World normally")
            try runRetainedCompensation(require: require)
            print("[ps01-i08] assertions=\(assertions) compensation=PASS")
            return
        }
        if phase == "replacement" {
            try runReplacement(game, controller, id: id, require: require)
            try require(game.exitToTitle() && controller.session == nil && controller.probesByAgentId.isEmpty,
                "replacement regression final ordinary cleanup")
            try runCancellationFailures(require: require)
            try runRetainedCompensation(require: require)
            print("[ps01-i08] assertions=\(assertions) replacement=PASS")
            return
        }
        if phase == "portal" {
            // Isolate the unchanged portal attack from earlier fault seams.
            // Controlled custody is disclosed here just as in runFaults.
            let probe = controller.probesByAgentId.values.sorted { $0.labAgentId < $1.labAgentId }.first!
            probe.carriedItems[0] = ItemStack(iid("sweet_berries"), 3)
            try require(game.exitToTitle(), "isolated portal saves its controlled custody boundary")
            game.loadWorld(id)
            try require(game.worldContinuationReady && carried(controller) == 3,
                "isolated portal restores without earlier fault attacks")
            for _ in 0..<52 { try step(game, controller, id: id) }
            try runPortal(game, controller, id: id, require: require)
            try require(game.exitToTitle(), "isolated portal coherent ordinary save retry")
            print("[ps01-i08] assertions=\(assertions) portal=PASS")
            return
        }
        if phase.hasPrefix("retention") {
            let boundary = try runRetention(game, controller, id: id, seed: seed,
                count: count, manual: phase == "retention-manual", require: require)
            try JSONEncoder().encode(boundary).write(to: URL(fileURLWithPath: output), options: .atomic)
            print("[ps01-i08] assertions=\(assertions) receiptRetention=PASS manual=\(phase == "retention-manual")")
            return
        }
        if phase == "faults" {
            try runFaults(game, controller, id: id, require: require)
            try require(game.exitToTitle(), "fault campaign final ordinary cleanup")
            try runCancellationFailures(require: require)
            try runRetainedCompensation(require: require)
            print("[ps01-i08] assertions=\(assertions) faults=PASS")
            return
        }
        if phase == "zero" {
            // Existing ordinary cognition-rate control; authoritative World
            // progression and passive biology still advance one Core tick at a time.
            try require(controller.handleCommand(["speed", "1"], world: game.world, player: game.player, game: game).succeeded, "ordinary 1 Hz cognition preserves authoritative World biology")
        }
        let horizon = phase == "envelope" ? 20 : (phase == "zero" ? 180000 : (seed == "14" ? 12000 : 1200))
        for elapsed in 0..<horizon {
            try step(game, controller, id: id)
            if phase == "write", seed == "14", carried(controller) > 0 { break }
            if phase == "zero", controller.session?.snapshot().agents.isEmpty == true { break }
            if elapsed % 1200 == 0 { print("[ps01-i08] progress world=\(game.world.time) living=\(controller.session?.snapshot().agents.count ?? -1)"); fflush(stdout) }
        }
        if seed == "14", phase == "write" { try require(carried(controller) > 0, "natural nontrivial custody acquired without provisioning") }
        if phase == "zero" { try require(controller.session?.snapshot().agents.isEmpty == true, "natural zero-population reached without expected-state injection") }
        let beforeSave = try snapshot(game, controller, seed: seed, count: count)
        let probes = controller.probesByAgentId.keys.sorted().map { PebbleAgentCheckpointProbeState(agentID: $0, probe: controller.probesByAgentId[$0]!) }
        try require(game.saveAndFlush(), "ordinary capture while remaining succeeds")
        let afterSave = try snapshot(game, controller, seed: seed, count: count)
        try require(beforeSave.semanticDigest == afterSave.semanticDigest && beforeSave.carried == afterSave.carried && probes.allSatisfy { $0.isUnchanged(in: game.world, mappedByAgentID: controller.probesByAgentId) }, "capture retains exact running civilization and physical custody")
        try require(game.exitToTitle() && controller.session == nil && controller.probesByAgentId.isEmpty, "ordinary save exit succeeds and tears down only afterward")
        try JSONEncoder().encode(afterSave).write(to: URL(fileURLWithPath: output), options: .atomic)
        print("[ps01-i08] assertions=\(assertions) writeDigest=\(afterSave.semanticDigest) carried=\(afterSave.carried) living=\(afterSave.living)")
    }

    private static func runRetention(_ game: GameCore, _ controller: PebbleAgentController,
        id: String, seed: String, count: Int, manual: Bool,
        require: (Bool, String) throws -> Void) throws -> Increment08Boundary {
        for _ in 0..<20 { try step(game, controller, id: id) }
        let oldIDs = controller.requiredWorldEcologicalObservationReceiptIDs(for: controller.session!)
        try require(!oldIDs.isEmpty, "natural observations establish physical receipt input")
        try require(game.saveAndFlush(), "ordinary receipt-bearing continuation captures")
        if manual {
            try require(controller.handleCheckpoint(["save", "i08-retention-manual"], world: game.world).succeeded,
                "standalone manual history checkpoint captures")
        }
        for _ in 0..<80 { try step(game, controller, id: id) }
        let currentIDs = controller.requiredWorldEcologicalObservationReceiptIDs(for: controller.session!)
        let obsolete = oldIDs.subtracting(currentIDs)
        let physicalIDs = Set(game.db.listWorldReceipts(worldID: id,
            kind: PebbleEcologicalObservationReceipt.kind).compactMap { AgentPhysicalObservationReceiptID(rawValue: $0.receiptID) })
        try require(!obsolete.isEmpty, "natural bounded retention retires earlier observations")
        try require(currentIDs.isSubset(of: physicalIDs), "current authoritative observation receipts remain protected")
        try require(game.db.worldContinuation(id)?.payload == nil, "later physical receipts invalidate the older ordinary continuation")
        try require(manual ? obsolete.isSubset(of: physicalIDs) : obsolete.isDisjoint(with: physicalIDs),
            manual ? "manual checkpoint retains historical receipt protection" : "ordinary-only obsolete receipts retire with their invalidated boundary")
        try require(game.saveAndFlush(), "receipt retirement permits a new coherent continuation")
        let boundary = try snapshot(game, controller, seed: seed, count: count)
        try require(game.exitToTitle(), "receipt retention campaign ordinary exit")
        return boundary
    }

    private static func runReplacement(_ game: GameCore, _ controller: PebbleAgentController,
        id: String, require: (Bool, String) throws -> Void) throws {
        let world = game.world
        let runtimeErrorsBefore = controller.runtimeErrorCount
        let probe = controller.probesByAgentId.values.sorted { $0.labAgentId < $1.labAgentId }.first!
        // Disclosed adversarial custody input; no civilization outcome injection.
        probe.carriedItems[0] = ItemStack(iid("sweet_berries"), 3)
        let original = try controller.session!.durableStateBytes()
        let states = controller.probesByAgentId.keys.sorted().map {
            PebbleAgentCheckpointProbeState(agentID: $0, probe: controller.probesByAgentId[$0]!)
        }
        try require(game.saveAndFlush() && carried(controller) == 3, "replacement starts with a protected nonempty ordinary boundary")
        var writes = 0
        var publishedAtRefusal: Data?
        game.db.testingRequiredPersistenceWriteHook = { write in
            guard write == .world else { return true }
            writes += 1
            if writes == 2 { publishedAtRefusal = game.db.worldContinuation(id)?.payload }
            return writes == 1
        }
        game.createWorld(name: "B02 refused destination", seedText: "14", mode: GameMode.survival, difficulty: 2)
        game.db.testingRequiredPersistenceWriteHook = nil
        let escrow = world.entities.compactMap { $0 as? ItemEntity }.filter {
            $0.custodyProvenance?.hasPrefix(pebbleCheckpointCustodySpillRoot) == true
        }.reduce(0) { $0 + $1.stack.count }
        print("[ps01-i08] B02_REPLACEMENT writes=\(writes) session=\(controller.session != nil) carried=\(carried(controller)) escrow=\(escrow) ready=\(game.worldContinuationReady) pending=\(controller.pendingWorldContinuation != nil) hardFailure=\(controller.candidatePhysicalHardFailure != nil)")
        try require(writes == 2 && game.world === world && game.worldRec?.id == id
            && game.db.worldContinuation(id)?.payload != nil,
            "outgoing publication succeeds before destination metadata refuses")
        try require((try controller.session?.durableStateBytes()) == original
            && states.allSatisfy { $0.isUnchanged(in: world, mappedByAgentID: controller.probesByAgentId) }
            && carried(controller) == 3 && escrow == 0 && game.worldContinuationReady
            && controller.pendingWorldContinuation == nil && controller.candidatePhysicalHardFailure == nil,
            "refused replacement returns exact original live custody and civilization")
        try require(publishedAtRefusal != nil && game.db.worldContinuation(id)?.payload == publishedAtRefusal
            && game.cancelPreparedLifecycle() && game.cancelPreparedLifecycle()
            && game.cancelExternalContinuation?() == true && carried(controller) == 3,
            "duplicate cancellation preserves the coherent durable snapshot and live custody")
        let time = world.time
        try step(game, controller, id: id)
        try require(world.time > time && controller.candidatePhysicalHardFailure == nil
            && controller.runtimeErrorCount == runtimeErrorsBefore, "verified cancellation permits ordinary progression")
        try require(game.saveAndFlush() && carried(controller) == 3,
            "save retry after refused creation succeeds with exact material")

        // The loadWorld second-read refusal is an equivalent real admission
        // edge. Delete only the isolated destination during the outgoing write.
        let unavailable = id + "-unavailable"
        try require(game.db.putWorld(WorldRecord(id: unavailable, name: "B02 unavailable destination",
            seed: 14, gameMode: GameMode.survival, difficulty: 2)), "load destination initially exists")
        let beforeLoad = try controller.session!.durableStateBytes()
        var removedDestination = false
        game.db.testingRequiredPersistenceWriteHook = { write in
            if write == .world {
                game.db.deleteWorld(unavailable)
                removedDestination = true
            }
            return true
        }
        game.loadWorld(unavailable)
        game.db.testingRequiredPersistenceWriteHook = nil
        try require(removedDestination && game.db.getWorld(unavailable) == nil && game.world === world
            && game.worldRec?.id == id && carried(controller) == 3
            && (try controller.session?.durableStateBytes()) == beforeLoad
            && controller.pendingWorldContinuation == nil && controller.candidatePhysicalHardFailure == nil,
            "destination second-read refusal cancels the same outgoing custody boundary")

        let preparedTime = world.time
        let preparedBytes = try controller.session!.durableStateBytes()
        try require(game.prepareForTermination() && controller.pendingWorldContinuation != nil
            && carried(controller) == 0, "publication retains compensation until lifecycle decision")
        let published = game.db.worldContinuation(id)!.payload
        let checkpointID = controller.pendingWorldContinuation!.stored.checkpoint.checkpointID
        try step(game, controller, id: id)
        try require(world.time == preparedTime && (try controller.session?.durableStateBytes()) == preparedBytes
            && !game.saveAndFlush(), "prepared lifecycle blocks physical and civilization progression")
        try require(game.prepareForTermination() && game.db.worldContinuation(id)?.payload == published
            && controller.pendingWorldContinuation?.stored.checkpoint.checkpointID == checkpointID,
            "repeated preparation is idempotent without new custody or publication")
        try require(game.cancelPreparedLifecycle() && carried(controller) == 3
            && world.entities.compactMap { $0 as? ItemEntity }.allSatisfy {
                $0.custodyProvenance?.hasPrefix(pebbleCheckpointCustodySpillRoot) != true
            } && game.db.worldContinuation(id)?.payload == published,
            "explicit cancellation retires live escrow while preserving its durable snapshot")
        try require(game.db.putWorld(game.db.getWorld(id)!) && game.db.worldContinuation(id)?.payload == nil,
            "next physical write invalidates the cancelled boundary through existing Core authority")
        try require(game.saveAndFlush() && carried(controller) == 3 && game.db.worldContinuation(id)?.payload != nil,
            "cancelled lifecycle remains save-retryable after reference invalidation")

        let simulationID = controller.session!.simulationID
        game.createWorld(name: "B02 successful retry", seedText: "14", mode: GameMode.survival, difficulty: 2)
        let oldEscrow = world.entities.compactMap { $0 as? ItemEntity }.filter {
            $0.custodyProvenance?.hasPrefix(pebbleCheckpointCustodySpillRoot) == true
        }
        try require(game.world !== world && game.worldRec?.id != id && controller.session == nil
            && controller.probesByAgentId.isEmpty && controller.pendingWorldContinuation == nil
            && oldEscrow.reduce(0) { $0 + $1.stack.count } == 3,
            "successful replacement commits teardown once and preserves exact outgoing physical custody")
        let envelope = try JSONDecoder().decode(PebbleWorldContinuationEnvelope.self,
            from: game.db.worldContinuation(id)!.payload!)
        let stored = try PebbleAgentPersistenceStore(worldID: id).loadCheckpoint(name: envelope.continuation.name)
        game.loadWorld(id)
        try require(game.worldContinuationReady && controller.session?.simulationID == simulationID
            && controller.session?.tick == stored.checkpoint.tick.rawValue && carried(controller) == 3
            && (try controller.session?.durableStateDigest()) == stored.checkpoint.semanticDigest,
            "ordinary return after replacement restores the same civilization without duplicate effects")
    }

    private static func runRetainedCompensation(require: (Bool, String) throws -> Void) throws {
        for attack in ["completion", "cancellation"] {
            let game = GameCore()
            let controller = PebbleAgentController()
            configure(game, controller)
            game.createWorld(name: "B03 retained owner \(attack)", seedText: "46", mode: GameMode.survival, difficulty: 2)
            let id = game.worldRec!.id
            for _ in 0..<52 { try step(game, controller, id: id) }
            try require(controller.start(world: game.world, player: game.player,
                founders: try PebbleNormalFounderProfile(count: 24)).succeeded,
                "\(attack) starts an ordinary cohort")
            let probe = controller.probesByAgentId.values.sorted { $0.labAgentId < $1.labAgentId }.first!
            // Disclosed physical input, never a checkpoint or civilization outcome.
            probe.carriedItems[0] = ItemStack(iid("sweet_berries"), 3)
            let bytes = try controller.session!.durableStateBytes()
            let simulationID = controller.session!.simulationID
            let states = controller.probesByAgentId.keys.sorted().map {
                PebbleAgentCheckpointProbeState(agentID: $0, probe: controller.probesByAgentId[$0]!)
            }
            var captured: PebblePendingWorldContinuation?
            var publicationAttempted = false
            if attack == "completion" {
                game.db.testingContinuationPublicationRefusal = {
                    captured = controller.pendingWorldContinuation
                    publicationAttempted = true
                    controller.testingWorldContinuationFailure = .custodyReturnVerification
                    return true
                }
                try require(!game.exitToTitle() && publicationAttempted,
                    "completion publication attack refuses outgoing exit")
            } else {
                try require(game.prepareForTermination() && carried(controller) == 0,
                    "cancellation starts after successful outgoing publication")
                captured = controller.pendingWorldContinuation
                controller.testingWorldContinuationFailure = .custodyReturnVerification
                try require(!game.cancelPreparedLifecycle(), "cancellation verification attack refuses")
            }
            let owned = captured!
            let reference = game.db.worldContinuation(id)
            func escrow() -> Int {
                game.world.entities.compactMap { $0 as? ItemEntity }.filter {
                    $0.custodyProvenance?.hasPrefix(pebbleCheckpointCustodySpillRoot) == true
                }.reduce(0) { $0 + $1.stack.count }
            }
            func exactOwner() -> Bool {
                controller.pendingWorldContinuation?.stored.checkpoint.checkpointID == owned.stored.checkpoint.checkpointID
                    && controller.pendingWorldContinuation?.name == owned.name
                    && controller.pendingWorldContinuation?.probes.count == states.count
                    && zip(controller.pendingWorldContinuation?.probes ?? [], owned.probes).allSatisfy {
                        $0.agentID == $1.agentID && $0.probe === $1.probe
                    }
                    && controller.session?.simulationID == simulationID
                    && (try? controller.session?.durableStateBytes()) == bytes
                    && states.allSatisfy { $0.isUnchanged(in: game.world, mappedByAgentID: controller.probesByAgentId) }
                    && carried(controller) + escrow() == 3
                    && game.worldRec?.id == id
                    && game.db.worldContinuation(id)?.payload == reference?.payload
                    && game.db.worldContinuation(id)?.revision == reference?.revision
            }
            try require(controller.candidatePhysicalHardFailure != nil && exactOwner(),
                "\(attack) hard failure retains the exact compensation owner, session, probes and material")
            let time = game.world.time
            try step(game, controller, id: id)
            try require(game.world.time == time && !game.saveAndFlush() && !game.prepareForTermination()
                && !game.completePreparedLifecycle() && !game.cancelPreparedLifecycle()
                && !(game.completeExternalContinuation?(false, false) ?? true) && exactOwner(),
                "\(attack) unresolved compensation blocks progression, save, finalization and unsafe retry")
            for command in [["stop"], ["clear"], ["demo", "stop"], ["demo", "start"], ["start"],
                            ["reset"], ["step"], ["pause"], ["speed", "2"], ["checkpoint", "load", "ps01-continuation-a"], ["resume"]] {
                try require(!controller.handleCommand(command, world: game.world, player: game.player, game: game).succeeded && exactOwner(),
                    "\(attack) /lab \(command.joined(separator: " ")) refuses without disposing authority")
            }
            try require(controller.shutdown() == 0 && controller.stop(reason: "world unavailable") == 0
                && game.clearLabCoreAgentProbes() == 0 && exactOwner(),
                "\(attack) direct shutdown and Core probe cleanup refuse retained ownership")
            for command in [["status"], ["observer", "status"], ["causality", "status"], ["checkpoint", "status"], ["checkpoint", "list"], ["demo", "status"]] {
                try require(controller.handleCommand(command, world: game.world, player: game.player, game: game).succeeded && exactOwner(),
                    "\(attack) read-only \(command.joined(separator: " ")) remains available")
            }
            runCommand(game, "/labprobe clear")
            try require(exactOwner() && chatLog.last?.text.contains("cleanup refused") == true, "\(attack) ordinary /labprobe clear cannot bypass retained ownership")
            runCommand(game, "/kill @e")
            try require(exactOwner() && chatLog.last?.text.contains("cleanup refused") == true, "\(attack) ordinary /kill @e cannot destroy retained probes or custody")
            // Ordinary drop input must obey the same Core halt as ticking.
            game.player.inventory[game.player.selectedSlot] = ItemStack(iid("dirt"), 1)
            let entities = game.world.entities.count
            game.keyDown(game.keybinds["drop"]!, now: 0)
            try require(game.world.entities.count == entities && game.player.inventory[game.player.selectedSlot]?.count == 1 && exactOwner(),
                "\(attack) hard halt refuses ordinary physical drop input")
            game.db.testingContinuationPublicationRefusal = nil
            controller.testingWorldContinuationFailure = nil
            let recovered = attack == "completion" ? game.cancelPreparedLifecycle()
                : controller.handleCommand(["resume"], world: game.world, player: game.player, game: game).succeeded
            try require(recovered && controller.pendingWorldContinuation == nil
                && controller.candidatePhysicalHardFailure == nil && states.allSatisfy {
                    $0.isUnchanged(in: game.world, mappedByAgentID: controller.probesByAgentId)
                } && carried(controller) == 3 && escrow() == 0
                && (try controller.session?.durableStateBytes()) == bytes,
                "\(attack) explicit verified compensation releases only this owner and its hard latch")
            try require(game.cancelPreparedLifecycle() && (game.cancelExternalContinuation?() ?? false)
                && carried(controller) == 3 && escrow() == 0,
                "\(attack) duplicate successful cancellation is idempotent")
            try require(controller.handleCommand(["resume"], world: game.world, player: game.player, game: game).succeeded,
                "\(attack) ordinary resume works after verified recovery")
            try step(game, controller, id: id)
            try require(game.world.time > time && game.saveAndFlush() && carried(controller) == 3 && escrow() == 0,
                "\(attack) recovered progression and ordinary save retry succeed")
            game.createWorld(name: "B03 recovered replacement", seedText: "14", mode: GameMode.survival, difficulty: 2)
            try require(game.worldRec?.id != id && controller.session == nil && controller.pendingWorldContinuation == nil,
                "\(attack) replacement retry commits teardown only after recovery")
            game.loadWorld(id)
            try require(game.worldContinuationReady && controller.session?.simulationID == simulationID
                && carried(controller) == 3 && escrow() == 0,
                "\(attack) retained identity and material restore once after replacement retry")
            let firstCleanup = attack == "completion" ? "stop" : "clear"
            let secondCleanup = attack == "completion" ? "clear" : "stop"
            try require(controller.handleCommand([firstCleanup], world: game.world, player: game.player, game: game).succeeded
                && controller.handleCommand([secondCleanup], world: game.world, player: game.player, game: game).succeeded
                && controller.session == nil && controller.pendingWorldContinuation == nil && controller.probesByAgentId.isEmpty,
                "\(attack) normal stop and clear remain available after verified recovery")
            let remaining = game.world.entities.compactMap { $0 as? ItemEntity }.filter { $0.stack.id == iid("sweet_berries") }.reduce(0) { $0 + $1.stack.count }
            try require(remaining == 3, "\(attack) recovered administrative stop conserves all three physical items")
            print("[ps01-i08] B03_OWNERSHIP attack=\(attack) retained=verified recovered=verified material=3 duplication=0")
        }
    }

    private static func runCancellationFailures(require: (Bool, String) throws -> Void) throws {
        for attack in ["verification", "finalization-preflight"] {
            let game = GameCore()
            let controller = PebbleAgentController()
            configure(game, controller)
            game.createWorld(name: "B02 hard refusal \(attack)", seedText: "46", mode: GameMode.survival, difficulty: 2)
            let id = game.worldRec!.id
            for _ in 0..<52 { try step(game, controller, id: id) }
            try require(controller.start(world: game.world, player: game.player,
                founders: try PebbleNormalFounderProfile(count: 24)).succeeded,
                "\(attack) cancellation failure starts a separate normal cohort")
            let probe = controller.probesByAgentId.values.sorted { $0.labAgentId < $1.labAgentId }.first!
            probe.carriedItems[0] = ItemStack(iid("sweet_berries"), 3)
            try require(game.prepareForTermination() && carried(controller) == 0
                && controller.pendingWorldContinuation != nil && game.db.worldContinuation(id)?.payload != nil,
                "\(attack) failure begins after successful publication with protected custody")
            let payload = game.db.worldContinuation(id)!.payload
            if attack == "verification" {
                controller.testingWorldContinuationFailure = .custodyReturnVerification
                try require(!game.cancelPreparedLifecycle(), "unavailable custody-return verification refuses cancellation")
            } else {
                // Disclosed corruption: duplicate live carry while its original
                // escrow remains. Finalization must refuse before any teardown.
                probe.carriedItems[0] = ItemStack(iid("sweet_berries"), 3)
                let oldWorld = game.world
                var destinationWrites = 0
                game.db.testingRequiredPersistenceWriteHook = { write in
                    if write == .world { destinationWrites += 1 }
                    return true
                }
                game.createWorld(name: "B02 preflight refused destination", seedText: "14", mode: GameMode.survival, difficulty: 2)
                game.db.testingRequiredPersistenceWriteHook = nil
                try require(destinationWrites == 1 && game.world === oldWorld
                    && controller.session != nil && controller.candidatePhysicalHardFailure != nil,
                    "destination admission succeeds but nonempty finalization preflight cancels before teardown")
            }
            let bytes = try controller.session!.durableStateBytes()
            let material = carried(controller) + game.world.entities.compactMap { $0 as? ItemEntity }.filter {
                $0.custodyProvenance?.hasPrefix(pebbleCheckpointCustodySpillRoot) == true
            }.reduce(0) { $0 + $1.stack.count }
            try require(controller.candidatePhysicalHardFailure != nil && controller.pendingWorldContinuation != nil
                && controller.session != nil && controller.probesByAgentId.count == 24,
                "\(attack) unverified cancellation retains and hard-halts the original authority")
            let time = game.world.time
            try step(game, controller, id: id)
            try require(game.world.time == time && (try controller.session?.durableStateBytes()) == bytes
                && !game.saveAndFlush() && !game.prepareForTermination() && !game.completePreparedLifecycle()
                && !game.cancelPreparedLifecycle() && !game.exitToTitle()
                && game.db.worldContinuation(id)?.payload == payload,
                "\(attack) hard refusal blocks progression, save, teardown and duplicate cancellation")
            let afterMaterial = carried(controller) + game.world.entities.compactMap { $0 as? ItemEntity }.filter {
                $0.custodyProvenance?.hasPrefix(pebbleCheckpointCustodySpillRoot) == true
            }.reduce(0) { $0 + $1.stack.count }
            try require(afterMaterial == material && material == (attack == "verification" ? 3 : 6),
                "\(attack) refusal adds no material beyond the disclosed fault input")
            print("[ps01-i08] B02_HARD_REFUSAL attack=\(attack) retainedProbes=24 material=\(material) publishedUnchanged=1 worldHalted=1 error=\(controller.lastError ?? "none")")
            // Intentionally retained/halted failure fixture: forcing cleanup
            // would defeat the refusal being tested. The process owns this
            // isolated evidence World until campaign completion.
        }
    }

    private static func runFaults(_ game: GameCore, _ controller: PebbleAgentController, id: String, require: (Bool, String) throws -> Void) throws {
        // Controlled custody input isolates failure conservation, separate from
        // the natural positive campaign. No cognition outcome is injected.
        let probe = controller.probesByAgentId.values.sorted { $0.labAgentId < $1.labAgentId }.first!
        probe.carriedItems[0] = ItemStack(iid("sweet_berries"), 3)
        let original = try controller.session!.durableStateBytes()
        let states = controller.probesByAgentId.keys.sorted().map { PebbleAgentCheckpointProbeState(agentID: $0, probe: controller.probesByAgentId[$0]!) }
        func exact() -> Bool {
            (try? controller.session?.durableStateBytes()) == original && carried(controller) == 3
                && states.allSatisfy { $0.isUnchanged(in: game.world, mappedByAgentID: controller.probesByAgentId) }
                && game.world.entities.compactMap { $0 as? ItemEntity }.allSatisfy { $0.custodyProvenance?.hasPrefix(pebbleCheckpointCustodySpillRoot) != true }
        }
        controller.credit = 6
        try require(game.saveAndFlush() && exact() && controller.credit == 6, "controlled nonempty capture conserves runtime custody and scheduler credit")
        try require(!controller.handleCheckpoint(["delete", "PS01-CONTINUATION-A"], world: game.world).succeeded && exact(), "case-insensitive manual alias cannot delete the ordinary continuation")
        let retainedSession = controller.session
        controller.session = nil
        let missingSessionRefused = !game.exitToTitle() && game.hasWorld()
        controller.session = retainedSession
        try require(missingSessionRefused && exact(), "missing active civilization cannot fall back to a successful physical-only exit")
        controller.testingWorldContinuationFailure = .checkpointCapture
        try require(!game.exitToTitle() && exact(), "civilization capture failure preserves previous pair and runtime")
        controller.testingWorldContinuationFailure = .afterFirstCustodyPreparation
        try require(!game.exitToTitle() && exact(), "partial physical custody preparation rolls back exactly")
        try require(game.saveAndFlush() && exact(), "custody preparation refusal permits retry")
        for write in [RequiredPersistenceWrite.world, .player, .advancements] {
            game.db.testingRequiredPersistenceWriteHook = { $0 != write }
            try require(!game.exitToTitle() && game.hasWorld() && exact(), "required \(write.rawValue) failure retains retry baseline")
            game.db.testingRequiredPersistenceWriteHook = nil
            try require(game.saveAndFlush() && exact(), "retry after \(write.rawValue) refusal succeeds")
        }
        game.db.testingSignInscriptionPersistenceHook = { $0 != .beforeCommit }
        try require(!game.exitToTitle() && exact(), "chunk transaction failure retains retry custody")
        game.db.testingSignInscriptionPersistenceHook = nil
        try require(game.saveAndFlush() && exact(), "chunk failure retry has no duplicated matter")
        game.db.testingContinuationPublicationRefusal = { true }
        try require(!game.exitToTitle() && exact() && game.db.worldContinuation(id)?.payload == nil, "late publication failure selects no torn continuation")
        game.db.testingContinuationPublicationRefusal = nil
        try require(game.saveAndFlush() && exact(), "late publication retry preserves exact civilization")
        let savedProbe = controller.probesByAgentId[probe.labAgentId]!
        game.world.removeEntity(savedProbe)
        try require(!game.exitToTitle() && controller.session != nil, "unreconciled physical custody refuses before destruction")
        game.world.addEntity(savedProbe)
        try require(game.saveAndFlush() && exact(), "binding repair permits coherent retry")
        try require(game.exitToTitle(), "fault boundary exits with protected custody")
        controller.checkpointPositionRestoreFailurePoint = .afterFirstMissingCreation
        game.loadWorld(id)
        try require(!game.worldContinuationReady && controller.session == nil && controller.probesByAgentId.isEmpty, "restore failure after probe creation rolls back unpublished candidate")
        let refusedTime = game.world.time
        try step(game, controller, id: id)
        try require(game.world.time == refusedTime && !game.saveAndFlush() && !controller.start(world: game.world, player: game.player, founders: try PebbleNormalFounderProfile(count: 24)).succeeded, "refused restore blocks World time, save and replacement founders")
        try require(game.exitToTitle(), "refused restore leaves without overwriting saved evidence")
        controller.checkpointPhysicalCustodyFailurePoint = .afterFirstCustodyRestore
        game.loadWorld(id)
        try require(!game.worldContinuationReady && controller.session == nil && controller.probesByAgentId.isEmpty, "late custody restore failure returns physical escrow")
        try require(game.exitToTitle(), "late restore failure retains durable retry boundary")
        game.loadWorld(id)
        try require(game.worldContinuationReady && carried(controller) == 3 && controller.session != nil, "fresh World re-entry retries without founders")
        try require(game.exitToTitle(), "retry continuation exits normally")
        let latest = game.db.worldContinuation(id)!
        let envelope = try JSONDecoder().decode(PebbleWorldContinuationEnvelope.self, from: latest.payload!)
        let c = envelope.continuation
        func attack(_ world: String, _ dimension: Int, _ revision: Int64) throws -> Data {
            let altered = PebbleWorldContinuation(version: c.version, revision: revision,
                worldID: world, dimension: dimension, worldRecordDigest: c.worldRecordDigest,
                name: c.name, checkpointID: c.checkpointID, manifestDigest: c.manifestDigest,
                founderCount: c.founderCount)
            return try JSONEncoder().encode(PebbleWorldContinuationEnvelope(altered))
        }
        for (world, dimension, revision, label) in [("foreign-world", c.dimension, latest.revision, "incompatible World"),
                (id, 1, latest.revision, "incompatible dimension"),
                (id, c.dimension, latest.revision - 1, "stale evidence") ] {
            try require(game.db.publishWorldContinuation(id, revision: latest.revision,
                payload: try attack(world, dimension, revision)), label + " isolated input")
            game.loadWorld(id)
            try require(!game.worldContinuationReady && controller.session == nil, label + " refuses without publication")
            try require(game.exitToTitle(), label + " preserves durable retry boundary")
        }
        try require(game.db.publishWorldContinuation(id, revision: latest.revision, payload: latest.payload!), "restore exact metadata after compatibility attacks")
        let store = try PebbleAgentPersistenceStore(worldID: id)
        let checkpoint = try store.loadCheckpoint(name: c.name).checkpoint
        let position = checkpoint.durableState.agents.first!.position
        let physical = game.db.getChunk(id, c.dimension, position.x >> 4, position.z >> 4)!
        var blocked = physical
        // A controlled late physical change makes the saved actor's body volume
        // unavailable. This is a refusal attack, not normal terrain preparation.
        if var blocks = blocked.blocks {
            let minY = game.worlds[.overworld]?.info.minY ?? -64
            let index = ((position.y + 1 - minY) * 16 + (position.z & 15)) * 16 + (position.x & 15)
            blocks[index] = UInt16(Int(B.bedrock) << 4)
            blocked.blocks = blocks
        } else {
            throw HarnessError.refused("placement attack requires saved terrain")
        }
        try require(game.db.putChunks([blocked]), "unavailable physical placement input commits through Core")
        let blockedRevision = game.db.worldContinuation(id)!.revision
        try require(game.db.publishWorldContinuation(id, revision: blockedRevision,
            payload: try attack(id, c.dimension, blockedRevision)), "placement attack correlates its isolated physical revision")
        game.loadWorld(id)
        try require(!game.worldContinuationReady && controller.session == nil && controller.probesByAgentId.isEmpty, "unavailable physical placement refuses without partial civilization")
        try require(game.exitToTitle(), "placement refusal preserves durable evidence")
        try require(game.db.putChunks([physical]), "controlled placement obstruction repairs through Core")
        let repairedRevision = game.db.worldContinuation(id)!.revision
        let repairedPayload = try attack(id, c.dimension, repairedRevision)
        try require(game.db.publishWorldContinuation(id, revision: repairedRevision, payload: repairedPayload), "placement repair correlates exact restored physical boundary")
        let bundle = try PebbleAgentPersistenceStore(worldID: id).worldRoot.appendingPathComponent("checkpoints/" + envelope.continuation.name.rawValue)
        let manifest = bundle.appendingPathComponent("manifest.json")
        let manifestBytes = try Data(contentsOf: manifest)
        try FileManager.default.removeItem(at: manifest)
        game.loadWorld(id)
        try require(!game.worldContinuationReady && controller.session == nil, "missing checkpoint component refuses")
        try require(game.exitToTitle(), "missing component preserves retry evidence")
        try manifestBytes.write(to: manifest, options: .atomic)
        var corrupted = repairedPayload
        corrupted[corrupted.startIndex] = 0
        try require(game.db.publishWorldContinuation(id, revision: repairedRevision, payload: corrupted), "corrupt metadata attack installs isolated test input")
        game.loadWorld(id)
        try require(!game.worldContinuationReady && controller.session == nil, "corrupt continuation metadata refuses before civilization publication")
        try require(game.exitToTitle(), "corrupt metadata refusal does not overwrite World")
        try require(game.db.publishWorldContinuation(id, revision: repairedRevision, payload: repairedPayload), "valid metadata repair restores same boundary")
        game.loadWorld(id)
        try require(game.worldContinuationReady && carried(controller) == 3, "component and metadata repair permit exact custody recovery")
        for _ in 0..<52 { try step(game, controller, id: id) }
        try runPortal(game, controller, id: id, require: require)
        try runEscrowAttacks(game, controller, id: id, require: require)
        try runReplacement(game, controller, id: id, require: require)
    }

    private static func runEscrowAttacks(_ game: GameCore, _ controller: PebbleAgentController,
        id: String, require: (Bool, String) throws -> Void) throws {
        for attack in ["missing", "duplicate"] {
            // Allocate corruption-test identity while Core's World is active.
            // Ordinary exit legitimately clears GameCore's live dimensions.
            let duplicate = attack == "duplicate" ? ItemEntity(world: game.world, bobOffset: 0) : nil
            try require(game.exitToTitle(), "\(attack) escrow attack begins at an ordinary protected boundary")
            let boundary = game.db.worldContinuation(id)!
            let envelope = try JSONDecoder().decode(PebbleWorldContinuationEnvelope.self, from: boundary.payload!)
            let c = envelope.continuation
            let stored = try PebbleAgentPersistenceStore(worldID: id).loadCheckpoint(name: c.name)
            let position = stored.checkpoint.durableState.agents.first!.position
            let original = game.db.getChunk(id, c.dimension, position.x >> 4, position.z >> 4)!
            let tagged = original.entities.filter { ($0["custodyProvenance"] as? String)?.hasPrefix(pebbleCheckpointCustodySpillRoot) == true }
            try require(tagged.count == 1 && carried(controller) == 0,
                "\(attack) attack has one real persisted escrow stack and no live probes")
            var altered = original
            if attack == "missing" {
                altered.entities.removeAll { ($0["custodyProvenance"] as? String)?.hasPrefix(pebbleCheckpointCustodySpillRoot) == true }
            } else {
                // Corrupt only the physical test input. Allocate the distinct
                // incarnation through Core, preserving the duplicate token.
                duplicate!.load(tagged[0])
                altered.entities.append(duplicate!.save())
            }
            try require(game.db.putChunks([altered]) && game.db.worldContinuation(id)?.payload == nil,
                "\(attack) physical escrow change invalidates the preferred continuation")
            func correlate() throws -> Bool {
                let revision = game.db.worldContinuation(id)!.revision
                let input = PebbleWorldContinuation(version: c.version, revision: revision,
                    worldID: c.worldID, dimension: c.dimension, worldRecordDigest: c.worldRecordDigest,
                    name: c.name, checkpointID: c.checkpointID, manifestDigest: c.manifestDigest,
                    founderCount: c.founderCount)
                return game.db.publishWorldContinuation(id, revision: revision,
                    payload: try JSONEncoder().encode(PebbleWorldContinuationEnvelope(input)))
            }
            // A disclosed adversarial correlation bypasses the revision gate
            // so ordinary entry must reach the existing strict custody owner.
            try require(try correlate(), "\(attack) attack correlates only its isolated physical revision")
            let attackedPayload = game.db.worldContinuation(id)!.payload
            game.loadWorld(id)
            let physical = game.world.entities.compactMap { $0 as? ItemEntity }.filter {
                $0.custodyProvenance?.hasPrefix(pebbleCheckpointCustodySpillRoot) == true
            }
            let reason = attack == "missing" ? "checkpoint-bound escrow is absent" : "duplicate token"
            try require(!game.worldContinuationReady && controller.session == nil && controller.probesByAgentId.isEmpty
                && physical.count == (attack == "missing" ? 0 : 2)
                && (controller.lastError?.contains(reason) ?? false),
                "\(attack) escrow refuses ordinary entry at its exact custody predicate")
            print("[ps01-i08] escrow attack=\(attack) taggedItems=\(physical.count) sessionPublished=0 error=\(controller.lastError!)")
            let refusedTime = game.world.time
            try step(game, controller, id: id)
            try require(game.world.time == refusedTime && !game.saveAndFlush(),
                "\(attack) escrow refusal cannot progress or save a torn pair")
            try require(game.exitToTitle() && game.db.worldContinuation(id)?.payload == attackedPayload,
                "\(attack) escrow refusal leaves without rewriting the retry evidence")
            try require(game.db.putChunks([original]) && (try correlate()),
                "\(attack) escrow repair restores the exact original physical component")
            game.loadWorld(id)
            try require(game.worldContinuationReady && carried(controller) == 3
                && controller.session?.tick == stored.checkpoint.tick.rawValue
                && (try controller.session?.durableStateDigest()) == stored.checkpoint.semanticDigest
                && game.world.entities.compactMap { $0 as? ItemEntity }.allSatisfy {
                    $0.custodyProvenance?.hasPrefix(pebbleCheckpointCustodySpillRoot) != true
                }, "\(attack) escrow repair retries without founders, duplicate material or duplicate effects")
        }
    }

    private static func runPortal(_ game: GameCore, _ controller: PebbleAgentController,
        id: String, require: (Bool, String) throws -> Void) throws {
        let world = game.world
        let dimension = game.dim
        let living = controller.probesByAgentId.count
        let player = game.player!
        let portalPosition = (Int(player.x.rounded(.down)), Int(player.y.rounded(.down)), Int(player.z.rounded(.down)))
        player.portalCooldown = 0
        player.vx = 0; player.vy = 0; player.vz = 0
        player.setPos(Double(portalPosition.0) + 0.5, Double(portalPosition.1) + 0.25, Double(portalPosition.2) + 0.5)
        let priorCell = world.getBlock(portalPosition.0, portalPosition.1, portalPosition.2)
        world.setBlock(portalPosition.0, portalPosition.1, portalPosition.2, Int(cell(B.end_portal)))
        let inputBounds = player.bb()
        try require(game.worldContinuationReady
            && world.getBlockId(portalPosition.0, portalPosition.1, portalPosition.2) == Int(B.end_portal)
            && (Int(inputBounds.x0.rounded(.down))...Int(inputBounds.x1.rounded(.down))).contains(portalPosition.0)
            && (Int(inputBounds.y0.rounded(.down))...Int(inputBounds.y1.rounded(.down))).contains(portalPosition.1)
            && (Int(inputBounds.z0.rounded(.down))...Int(inputBounds.z1.rounded(.down))).contains(portalPosition.2),
            "real End portal intersects the live Player before travel")
        func diagnose(_ phase: String) throws {
            let bb = player.bb()
            let row: [String: Any] = ["phase": phase, "worldTick": world.time,
                "dimension": game.dim.rawValue, "sameWorld": game.world === world,
                "hasWorld": game.hasWorld(), "continuationReady": game.worldContinuationReady,
                "continuationRequired": game.db.worldContinuation(id) != nil,
                "paused": game.paused, "living": living, "probes": controller.probesByAgentId.count,
                "mapped": controller.probesByAgentId.values.filter { world.entityById[$0.id] === $0 }.count,
                "carried": carried(controller), "cooldown": player.portalCooldown,
                "player": [player.x, player.y, player.z], "velocity": [player.vx, player.vy, player.vz],
                "boundingBox": [bb.x0, bb.y0, bb.z0, bb.x1, bb.y1, bb.z1],
                "dead": player.dead, "health": player.health,
                "portalCell": [portalPosition.0, portalPosition.1, portalPosition.2],
                "portalBlock": world.getBlockId(portalPosition.0, portalPosition.1, portalPosition.2),
                "lastError": controller.lastError ?? "none"]
            let data = try JSONSerialization.data(withJSONObject: row, options: [.sortedKeys])
            print("[ps01-i08] portal diagnostic " + String(decoding: data, as: UTF8.self))
            if let output = ProcessInfo.processInfo.environment["PEBBLELAB_PS01_INCREMENT08_OUTPUT"] {
                try data.write(to: URL(fileURLWithPath: output + ".portal-" + phase + ".json"), options: .atomic)
            }
        }
        try diagnose("before")
        _ = game.frame(dtMs: TICK_MS)
        try diagnose("after")
        print("[ps01-i08] portal result dimension=\(game.dim.rawValue) sameWorld=\(game.world === world) probes=\(controller.probesByAgentId.count)/\(living) mapped=\(controller.probesByAgentId.values.filter { world.entityById[$0.id] === $0 }.count) custody=\(carried(controller)) cooldown=\(player.portalCooldown) player=\(player.x),\(player.y),\(player.z) input=\(portalPosition) block=\(world.getBlockId(portalPosition.0, portalPosition.1, portalPosition.2)) expectedBlock=\(B.end_portal)")
        try require(game.dim == dimension && game.world === world && controller.probesByAgentId.count == living
            && controller.probesByAgentId.values.allSatisfy { world.entityById[$0.id] === $0 }
            && carried(controller) == 3 && player.portalCooldown == 200,
            "incompatible dimension travel refuses before clearing civilization or custody")
        world.setBlock(portalPosition.0, portalPosition.1, portalPosition.2, priorCell)
        player.spawnDim = Dim.nether.rawValue
        player.spawnPoint = nil
        game.respawnPlayer()
        try require(game.dim == dimension && controller.probesByAgentId.values.allSatisfy { world.entityById[$0.id] === $0 }
            && carried(controller) == 3, "respawn preserves the required continuation dimension and custody")
    }

    private static func step(_ game: GameCore, _ controller: PebbleAgentController, id: String) throws {
        _ = game.frame(dtMs: TICK_MS)
        let deadline = Date(timeIntervalSinceNow: 60)
        while game.physicalSimulationCoverageRuntimeDiagnostics(for: game.world).totalGenerationJobsInFlight > 0 {
            guard Date() < deadline else { throw HarnessError.refused("generation timeout") }
            _ = RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.005))
        }
        controller.update(world: game.world, player: game.player, worldID: id, dimension: game.dim.rawValue)
        if let failure = controller.fatalSessionIntegrityFailure { throw HarnessError.refused("fatal integrity: \(failure)") }
    }

    private static func carried(_ controller: PebbleAgentController) -> Int {
        controller.probesByAgentId.values.reduce(0) { total, probe in
            total + probe.carriedItems.compactMap { $0 }.reduce(0) { $0 + (itemName($1.id) == "sweet_berries" ? $1.count : 0) }
        }
    }

    private static func snapshot(_ game: GameCore, _ controller: PebbleAgentController, seed: String, count: Int) throws -> Increment08Boundary {
        guard let session = controller.session else { throw HarnessError.refused("session unavailable") }
        let acquired = session.wildSubsistenceSnapshot().retainedOutcomes.reduce(0) { total, retained in
            total + retained.outcome.acquiredItems.filter { $0.identity.itemKey == "sweet_berries" }.reduce(0) { $0 + $1.count }
        }
        return Increment08Boundary(worldID: game.worldRec!.id, seed: seed, founders: count,
            worldTick: game.world.time, civilizationTick: session.tick,
            living: session.snapshot().agents.count,
            semanticDigest: try session.durableStateDigest().rawValue,
            causalDigest: session.causalLedgerSnapshot().summary.digest,
            acquired: acquired, consumed: (session.physicalFoodSurvivalSnapshot()?.totalConsumedQuantity ?? 0), carried: carried(controller))
    }

    private enum HarnessError: Error { case refused(String) }
}
