import Foundation
import PebbleAgents
import PebbleCore

/// Bounded read-only qualification around ordinary founder/World entry,
/// simulation, save and exit. No prerequisite, pair or birth is supplied.
enum PebbleIncrement09QualificationHarness {
    static func runIfRequested() -> Int32? {
        let env = ProcessInfo.processInfo.environment
        guard let phase = env["PEBBLELAB_PS01_INCREMENT09_PHASE"] else { return nil }
        do {
            guard let home = env["CFFIXED_USER_HOME"], home.hasPrefix("/tmp/"),
                  let output = env["PEBBLELAB_PS01_INCREMENT09_OUTPUT"],
                  let seed = env["PEBBLELAB_PS01_INCREMENT09_SEED"],
                  ["write", "scarcity", "plan", "read"].contains(phase) else {
                throw Failure.refused("explicit isolated qualification configuration required")
            }
            try run(phase: phase, seed: seed, output: output)
            print("[ps01-i09] PASS phase=\(phase)")
            return 0
        } catch {
            fputs("[ps01-i09] FAIL \(error)\n", stderr)
            return 1
        }
    }

    private static func run(phase: String, seed: String, output: String) throws {
        let game = GameCore()
        let controller = PebbleAgentController()
        game.settings.renderDistance = 4
        controller.worldSideReceiptDatabase = game.db
        controller.installWorldContinuation(on: game)
        game.physicalSimulationCoverageProvider = { [weak controller] world in
            controller?.physicalSimulationCoverageRequest(for: world) ?? .inactive
        }
        game.prepareExternalLifecycleState = { [weak controller, weak game] in
            guard let controller, let game else { return false }
            return controller.prepareForLifecyclePersistence(world: game.world)
        }
        game.finalizeExternalLifecycleState = { [weak controller] in
            controller?.finalizeLifecycleAfterPersistence()
        }
        let id = "ps01-i09-seed-\(seed)-founders-24"
        var assertions = 0
        func require(_ condition: Bool, _ reason: String) throws {
            assertions += 1
            guard condition else { throw Failure.refused(reason + " error=" + (controller.lastError ?? "none")) }
            print("[ps01-i09] assertion=\(assertions) PASS \(reason)")
        }
        var loadedBirths: [AgentBirthRecord] = []
        if phase == "read" {
            let before = try Data(contentsOf: URL(fileURLWithPath: output + ".session.json"))
            game.loadWorld(id)
            try require(game.hasWorld() && game.worldContinuationReady && controller.session != nil,
                        "fresh process ordinary World entry restores")
            try require(try controller.session!.durableStateBytes() == before,
                        "exact authoritative state restores including accepted plans and births")
            loadedBirths = controller.session!.birthsSnapshot()
            try exactBodies(controller, game, require)
        } else {
            game.createWorld(name: "I09 normal seed \(seed)", seedText: seed,
                             mode: GameMode.survival, difficulty: 2)
            var record = game.worldRec!
            let transient = record.id
            try require(game.exitToTitle(), "ordinary new World boundary")
            game.deleteWorld(transient)
            record.id = id
            record.lastPlayed = 0
            try require(game.db.putWorld(record), "stable seed World identity installs")
            game.loadWorld(id)
            try require(game.hasWorld() && game.worldContinuationReady,
                        "ordinary stable World entry")
            for _ in 0..<52 { try step(game, controller, id: id) }
            try require(controller.start(world: game.world, player: game.player,
                founders: try PebbleNormalFounderProfile(count: 24)).succeeded,
                "ordinary normal founder start without resources or pair")
            try require(controller.session!.normalPhysicalReproductionEnabled
                && controller.session!.reproductionEnabled,
                "normal reproduction prospectively active")
            try require(controller.session!.reproductionSnapshot().accessibleFood == nil,
                "physical food census unavailable rather than zero")
        }
        let targetBirth = seed == "14" && (phase == "write" || (phase == "read" && loadedBirths.isEmpty))
        let horizon = phase == "read" && (!loadedBirths.isEmpty || seed == "46") ? 40 : 12000
        for elapsed in 0..<horizon {
            try step(game, controller, id: id)
            try exactBodies(controller, game, require, printAssertion: false)
            let session = controller.session!
            if phase == "plan", session.lifecycleSummary().activePlanCount > 0 { break }
            if targetBirth, session.lifecycleSummary().totalBirthCount > 0 { break }
            if elapsed % 1200 == 0 {
                print("[ps01-i09] progress world=\(game.world.time) tick=\(session.tick) living=\(session.snapshot().agents.count) meals=\(session.physicalFoodSurvivalSnapshot()!.totalConsumedQuantity) plans=\(session.lifecycleSummary().activePlanCount) births=\(session.lifecycleSummary().totalBirthCount)")
                fflush(stdout)
            }
        }
        let session = controller.session!
        if phase == "scarcity" || (phase == "read" && seed == "46") {
            try require(session.birthsSnapshot().isEmpty
                && session.physicalFoodSurvivalSnapshot()!.totalConsumedQuantity == 0
                && session.lifecycleSummary().activePlanCount == 0,
                "natural scarcity correctly produces no meal, plan or birth")
        } else if phase == "plan" {
            try require(session.lifecycleSummary().activePlanCount == 1 && session.birthsSnapshot().isEmpty,
                "native accepted plan saved before due birth")
        } else {
            try require(!session.birthsSnapshot().isEmpty, "native normal birth occurs")
            try require(loadedBirths.allSatisfy { session.birthsSnapshot().contains($0) },
                "restart preserves every accepted birth identity and state")
            let birth = session.birthsSnapshot().first!
            let plan = session.lifecycleSnapshot().plans.first { $0.planID == birth.planID }!
            try require(plan.physicalSubsistenceEvidence?.meals.map(\.agentID) == birth.progenitorIDs,
                "birth derives from exact accepted physical meals of canonical parents")
            try require(session.kinshipSnapshot().parentageRecords.contains {
                $0.childID == birth.newbornID && $0.canonicalParentIDs == birth.progenitorIDs
            } && session.genotype(for: birth.newbornID)?.contributorIDs == birth.progenitorIDs,
                "kinship and inherited genetics match birth transition")
            try require(session.populationSnapshot().members.contains { $0.agentID == birth.newbornID }
                && session.lifecycleSnapshot().members.contains { $0.agentID == birth.newbornID }
                && controller.probesByAgentId[birth.newbornID.rawValue] != nil,
                "newborn population lifecycle and physical body are exact")
        }
        try require(session.populationSummary().capacity == 30,
                    "capacity remains exactly 30")
        let acquired = session.wildSubsistenceSnapshot().retainedOutcomes.reduce(0) { total, row in
            total + row.outcome.acquiredItems.filter { $0.identity.itemKey == "sweet_berries" }.reduce(0) { $0 + $1.count }
        }
        let consumed = session.physicalFoodSurvivalSnapshot()!.totalConsumedQuantity
        let carried = controller.probesByAgentId.values.reduce(0) { total, probe in
            total + probe.carriedItems.compactMap { $0 }.filter { itemName($0.id) == "sweet_berries" }.reduce(0) { $0 + $1.count }
        }
        try require(acquired == Int(consumed) + carried, "real acquisition equals consumed plus physical custody")
        try require(controller.runtimeErrorCount == 0 && controller.droppedCatchUpSteps == 0
            && controller.candidatePhysicalHardFailure == nil, "no runtime or physical integrity failure")
        let before = try session.durableStateBytes()
        try require(game.saveAndFlush(), "ordinary Save/Continue succeeds")
        try require(try controller.session!.durableStateBytes() == before,
                    "Save/Continue preserves authoritative state")
        let prefix = output + (phase == "read" ? ".read" : "")
        try before.write(to: URL(fileURLWithPath: prefix + ".session.json"), options: .atomic)
        let evidence: [String: Any] = ["phase": phase, "seed": seed, "founders": 24,
            "worldTick": game.world.time, "tick": session.tick,
            "births": session.birthsSnapshot().count, "population": session.snapshot().agents.count,
            "acquired": acquired, "consumed": consumed, "carried": carried,
            "checkpointSchema": try session.makeCheckpoint().schemaVersion,
            "semanticDigest": try session.durableStateDigest().rawValue,
            "causalDigest": session.causalLedgerSnapshot().summary.digest]
        try JSONSerialization.data(withJSONObject: evidence, options: [.prettyPrinted, .sortedKeys])
            .write(to: URL(fileURLWithPath: prefix + ".json"), options: .atomic)
        try require(game.exitToTitle() && controller.session == nil && controller.probesByAgentId.isEmpty,
                    "ordinary Save/Exit succeeds with verified cleanup")
        print("[ps01-i09] assertions=\(assertions) finalBirths=\(session.birthsSnapshot().count) schema=\(try session.makeCheckpoint().schemaVersion) probesFinal=0")
    }

    private static func exactBodies(_ controller: PebbleAgentController, _ game: GameCore,
        _ require: (Bool, String) throws -> Void, printAssertion: Bool = true) throws {
        let expected = controller.session!.expectedActiveAgentIDs().map(\.rawValue).sorted()
        let actual = game.world.entities.compactMap { ($0 as? LabCoreAgentEntity)?.labAgentId }.sorted()
        let exact = actual == expected && controller.probesByAgentId.keys.sorted() == expected
        if printAssertion { try require(exact, "exact session registry World body bijection") }
        else if !exact { throw Failure.refused("body bijection during ordinary progression") }
    }

    private static func step(_ game: GameCore, _ controller: PebbleAgentController, id: String) throws {
        _ = game.frame(dtMs: TICK_MS)
        let deadline = Date(timeIntervalSinceNow: 60)
        while game.physicalSimulationCoverageRuntimeDiagnostics(for: game.world).totalGenerationJobsInFlight > 0 {
            guard Date() < deadline else { throw Failure.refused("generation timeout") }
            _ = RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.005))
        }
        controller.update(world: game.world, player: game.player, worldID: id, dimension: game.dim.rawValue)
        if let failure = controller.fatalSessionIntegrityFailure { throw Failure.refused(failure) }
    }

    private enum Failure: Error { case refused(String) }
}
