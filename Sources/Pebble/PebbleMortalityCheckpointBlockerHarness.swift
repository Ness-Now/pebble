import Foundation
import PebbleAgents
import PebbleCore

/// Launch-gated diagnostics only. Runs canonical normal founders, one ordinary
/// World tick at a time, then asks the existing checkpoint owner to admit state.
/// No I08 continuation, physical fixture, injected death or replacement roster.
enum PebbleMortalityCheckpointBlockerHarness {
    static func runIfRequested() -> Int32? {
        let env = ProcessInfo.processInfo.environment
        guard env["PEBBLELAB_MORTALITY_CHECKPOINT_BLOCKER"] == "1" else { return nil }
        do {
            guard let home = env["CFFIXED_USER_HOME"],
                  home.hasPrefix("/tmp/") || home.hasPrefix("/private/tmp/"),
                  let output = env["PEBBLELAB_MORTALITY_CHECKPOINT_OUTPUT"] else {
                throw DiagnosticError.refused("isolated home and output required")
            }
            try run(output: output)
            return 0
        } catch {
            fputs("[mortality-checkpoint] FAIL \(error)\n", stderr)
            return 1
        }
    }

    private static func run(output: String) throws {
        let directory = URL(fileURLWithPath: output, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let game = GameCore()
        let controller = PebbleAgentController()
        game.settings.renderDistance = 4
        controller.worldSideReceiptDatabase = game.db
        game.physicalSimulationCoverageProvider = { [weak controller] world in
            controller?.physicalSimulationCoverageRequest(for: world) ?? .inactive
        }
        game.prepareExternalLifecycleState = { [weak controller, weak game] in
            guard let controller, let game else { return false }
            guard game.hasWorld() else { return controller.session == nil && controller.activeWorld == nil }
            return controller.prepareForLifecyclePersistence(world: game.world)
        }
        game.finalizeExternalLifecycleState = { [weak controller] in
            controller?.finalizeLifecycleAfterPersistence()
        }
        var assertions = 0
        func require(_ value: Bool, _ label: String) throws {
            assertions += 1
            guard value else { throw DiagnosticError.refused(label) }
            print("[mortality-checkpoint] assertion=\(assertions) PASS \(label)")
            fflush(stdout)
        }
        let id = "ps01-i08-seed-46-founders-24"
        game.createWorld(name: "PS01 checkpoint blocker natural seed 46", seedText: "46", mode: GameMode.survival, difficulty: 2)
        try require(game.hasWorld(), "canonical natural World created")
        var record = game.worldRec!
        let transientID = record.id
        try require(game.exitToTitle(), "initial empty World saves normally")
        game.deleteWorld(transientID)
        record.id = id
        record.lastPlayed = 0
        try require(game.db.putWorld(record), "isolated stable World identity")
        game.loadWorld(id)
        for _ in 0..<52 { try step(game, controller, id: id) }
        try require(controller.start(world: game.world, player: game.player,
            founders: try PebbleNormalFounderProfile(count: 24)).succeeded,
            "24 normal founders admitted by existing product path")
        try require(controller.handleCommand(["speed", "1"], world: game.world,
            player: game.player, game: game).succeeded, "ordinary 1 Hz cognition")
        let living = controller.session!
        try living.durableStateBytes().write(to: directory.appendingPathComponent("non-extinct-state.json"))
        _ = try AgentSimulationSession.validate(living.makeCheckpoint())
        try require(living.snapshot().agents.count == 24, "non-extinct checkpoint admitted")
        var lastPopulation = 24
        for elapsed in 0..<180000 {
            try step(game, controller, id: id)
            let count = controller.session!.snapshot().agents.count
            if elapsed == 2000 {
                let middle = controller.session!
                try middle.durableStateBytes().write(to: directory.appendingPathComponent("non-extinct-compacted-state.json"))
                try require(middle.durableState().causalLedger.droppedEventCount > 0
                    && count == 24 && (try AgentSimulationSession.validate(middle.makeCheckpoint())).valid,
                    "normal non-extinct checkpoint admitted after compaction")
            }
            if count != lastPopulation {
                try controller.session!.durableStateBytes().write(to: directory.appendingPathComponent("cohort-\(count)-state.json"))
                print("[mortality-checkpoint] cohort worldTick=\(game.world.time) civilizationTick=\(controller.session!.tick) living=\(count)")
                lastPopulation = count
            }
            if count == 0 { break }
            if elapsed % 1200 == 0 {
                print("[mortality-checkpoint] progress worldTick=\(game.world.time) civilizationTick=\(controller.session!.tick) living=\(count)")
                fflush(stdout)
            }
        }
        let session = controller.session!
        try require(session.snapshot().agents.isEmpty, "natural extinction without injected mortality")
        try session.durableStateBytes().write(to: directory.appendingPathComponent("terminal-state.json"))
        try require(controller.fatalSessionIntegrityFailure == nil && controller.runtimeErrorCount == 0,
            "normal runtime has no integrity error")
        controller.persistenceWorldID = id
        controller.persistenceDimension = game.dim.rawValue
        let saved = controller.handleCheckpoint(["save", "natural-terminal"], world: game.world)
        print("[mortality-checkpoint] existingCheckpointSave succeeded=\(saved.succeeded) message=\(saved.message)")
        let report: [String: Any] = ["worldTick": game.world.time,
            "civilizationTick": session.tick, "living": session.snapshot().agents.count,
            "checkpointSaveSucceeded": saved.succeeded, "message": saved.message,
            "causalDigest": session.causalLedgerSnapshot().summary.digest]
        try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
            .write(to: directory.appendingPathComponent("result.json"))
        try require(saved.succeeded, "existing terminal checkpoint admission")
        let store = try PebbleAgentPersistenceStore(worldID: id)
        let stored = try store.loadCheckpoint(name: AgentCheckpointName(rawValue: "natural-terminal")!)
        let restored = try AgentSimulationSession.restoring(stored.checkpoint)
        try require(restored.expectedActiveAgentIDs().isEmpty
            && restored.simulationID == session.simulationID
            && (try restored.durableStateBytes()) == session.durableStateBytes(),
            "stored natural terminal checkpoint restores exact identity and durable state without founders")
        try require(game.exitToTitle(), "existing lifecycle cleanup")
        print("[mortality-checkpoint] PASS assertions=\(assertions) probes=\(controller.probesByAgentId.count)")
    }

    private static func step(_ game: GameCore, _ controller: PebbleAgentController, id: String) throws {
        _ = game.frame(dtMs: TICK_MS)
        let deadline = Date(timeIntervalSinceNow: 60)
        while game.physicalSimulationCoverageRuntimeDiagnostics(for: game.world).totalGenerationJobsInFlight > 0 {
            guard Date() < deadline else { throw DiagnosticError.refused("generation timeout") }
            _ = RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.005))
        }
        controller.update(world: game.world, player: game.player, worldID: id, dimension: game.dim.rawValue)
        if let failure = controller.fatalSessionIntegrityFailure { throw DiagnosticError.refused(failure) }
    }

    private enum DiagnosticError: Error { case refused(String) }
}
