import Foundation
import PebbleAgents
import PebbleCore

private struct PebbleIncrement07RestartBoundary: Codable {
    let phase: String
    let seed: UInt32
    let founders: Int
    let worldID: String
    let worldTick: Int
    let civilizationTick: Int
    let targetKey: String
    let target: AgentPosition
    let firstAttemptID: String
    let firstActorID: String
    let firstAcquisitionQuantity: Int
    let sourceStage: Int
    let totalAcquired: Int
    let totalConsumed: UInt64
    let totalCarried: Int
    let semanticDigest: String
    let causalDigest: String
    let checkpointSchema: Int
    let checkpointSaveSucceeded: Bool
    let worldSaveSucceeded: Bool
}

private struct PebbleIncrement07RestartContinuation: Codable {
    let phase: String
    let seed: UInt32
    let founders: Int
    let worldID: String
    let loadedWorldTick: Int
    let loadedCivilizationTick: Int
    let loadedSourceStage: Int
    let loadedTotalAcquired: Int
    let loadedTotalConsumed: UInt64
    let loadedTotalCarried: Int
    let loadedCheckpointSchema: Int
    let restartCreatedGrowth: Bool
    let restartCreatedMaterial: Bool
    let renewedWorldTick: Int
    let renewedSourceStage: Int
    let secondAttemptID: String
    let secondActorID: String
    let secondAcquisitionWorldTick: Int
    let secondAcquisitionCivilizationTick: Int
    let secondAcquisitionQuantity: Int
    let sourceStageAfterSecondAcquisition: Int
    let finalTotalAcquired: Int
    let finalTotalConsumed: UInt64
    let finalTotalCarried: Int
    let materialConservationExact: Bool
    let sameSourceRenewalExact: Bool
    let runtimeErrors: Int
    let catchUpDrops: Int
    let fatalIntegrityHalted: Bool
    let semanticDigest: String
    let causalDigest: String
    let checkpointSchema: Int
    let worldCleanupSucceeded: Bool
}

/// Two-process normal-product restart evidence. The harness selects only the
/// natural seed, founder count and maximum elapsed horizon. Hunger, observation,
/// decision, movement, acquisition, consumption and regrowth remain owned by
/// the ordinary product authorities.
enum PebbleIncrement07RestartHarness {
    private static let gate = "PEBBLELAB_PS01_INCREMENT07_RESTART_PHASE"
    private static let checkpointName = "ps01-i07-renewal-boundary"

    static func runIfRequested(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> Int32? {
        guard let phase = environment[gate] else { return nil }
        do {
            try run(phase: phase, environment: environment)
            return 0
        } catch {
            fputs("[ps01-i07-restart] FAIL phase=\(phase) \(error)\n", stderr)
            return 1
        }
    }

    private static func run(
        phase: String,
        environment: [String: String]
    ) throws {
        guard phase == "write" || phase == "read",
              let seedText = environment["PEBBLELAB_PS01_INCREMENT07_RESTART_SEED"],
              let signedSeed = Int32(seedText),
              let outputPath = environment["PEBBLELAB_PS01_INCREMENT07_RESTART_OUTPUT"],
              !outputPath.isEmpty,
              let boundaryPath = environment[
                  "PEBBLELAB_PS01_INCREMENT07_RESTART_BOUNDARY"
              ], !boundaryPath.isEmpty,
              let fixedHome = environment["CFFIXED_USER_HOME"],
              fixedHome.hasPrefix("/tmp/") || fixedHome.hasPrefix("/private/tmp/") else {
            throw RestartError.invalidConfiguration
        }
        let requiredGates = [
            "PEBBLELAB_APP_AGENTS", "PEBBLELAB_APP_PROBES",
            "PEBBLELAB_DEBUG_ENTITIES", "PEBBLELAB_APP_AGENTS_MOVE",
            "PEBBLELAB_APP_AGENTS_INTERACT", "PEBBLELAB_APP_AGENTS_MATERIAL",
            "PEBBLELAB_APP_AGENTS_PERSISTENCE",
            "PEBBLELAB_APP_AGENTS_POPULATION",
            "PEBBLELAB_APP_AGENTS_LIFECYCLE",
            "PEBBLELAB_APP_AGENTS_KINSHIP",
            "PEBBLELAB_APP_AGENTS_HOUSEHOLDS",
            "PEBBLELAB_APP_AGENTS_CARE",
            "PEBBLELAB_APP_AGENTS_CHILDHOOD",
            "PEBBLELAB_APP_AGENTS_FAMILY",
            "PEBBLELAB_APP_AGENTS_MORTALITY",
            "PEBBLELAB_APP_AGENTS_HOMEOSTASIS",
            "PEBBLELAB_APP_AGENTS_GENETICS",
            "PEBBLELAB_APP_AGENTS_SKILLS",
            "PEBBLELAB_APP_AGENTS_ECOLOGICAL_OBSERVATION",
            "PEBBLELAB_APP_AGENTS_WILD_SUBSISTENCE",
            "PEBBLELAB_APP_AGENTS_AUTONOMOUS_CIVILIZATION",
        ]
        guard requiredGates.allSatisfy({ environment[$0] == "1" }),
              environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] != "1" else {
            throw RestartError.invalidConfiguration
        }

        let seed = UInt32(bitPattern: signedSeed)
        let founders = 24
        let worldID = "ps01-i07-restart-seed-\(seed)"
        let controller = PebbleAgentController()
        let game = GameCore()
        configure(controller: controller, game: game)

        if phase == "write" {
            try createCanonicalWorld(
                game: game, seedText: seedText, seed: seed, worldID: worldID
            )
        } else {
            guard game.db.getWorld(worldID) != nil else {
                throw RestartError.worldUnavailable
            }
            game.loadWorld(worldID)
            guard game.hasWorld(), game.world.seed == seed else {
                throw RestartError.worldUnavailable
            }
        }

        while game.world.time < 52 {
            _ = game.frame(dtMs: TICK_MS)
            try drainGeneration(in: game)
        }
        let started = controller.start(
            world: game.world,
            player: game.player,
            founders: try PebbleNormalFounderProfile(count: founders)
        )
        guard started.succeeded else {
            throw RestartError.controllerRefused(started.message)
        }
        controller.persistenceWorldID = worldID
        controller.persistenceDimension = game.dim.rawValue

        if phase == "write" {
            try runWriter(
                outputPath: outputPath,
                boundaryPath: boundaryPath,
                seed: seed,
                founders: founders,
                worldID: worldID,
                controller: controller,
                game: game
            )
        } else {
            try runReader(
                outputPath: outputPath,
                boundaryPath: boundaryPath,
                seed: seed,
                founders: founders,
                worldID: worldID,
                controller: controller,
                game: game
            )
        }
    }

    private static func runWriter(
        outputPath: String,
        boundaryPath: String,
        seed: UInt32,
        founders: Int,
        worldID: String,
        controller: PebbleAgentController,
        game: GameCore
    ) throws {
        var seenAttempts = Set<AgentSubsistenceAttemptID>()
        var firstOutcome: AgentSubsistenceOutcome?
        let startWorldTick = game.world.time
        while game.world.time - startWorldTick < 48_000 {
            _ = game.frame(dtMs: TICK_MS)
            try drainGeneration(in: game)
            controller.update(
                world: game.world,
                player: game.player,
                worldID: worldID,
                dimension: game.dim.rawValue
            )
            guard controller.fatalSessionIntegrityFailure == nil,
                  let session = controller.session else {
                throw RestartError.fatalIntegrity
            }
            for record in session.wildSubsistenceSnapshot().retainedOutcomes
            where seenAttempts.insert(record.outcome.attemptID).inserted {
                let outcome = record.outcome
                if firstOutcome == nil,
                   outcome.status == .succeeded,
                   outcome.attribution
                    == "core-canonical-preserving-sweet-berry-harvest" {
                    firstOutcome = outcome
                }
            }
            if let firstOutcome,
               session.physicalFoodSurvivalSnapshot()?.totalConsumedQuantity ?? 0 > 0 {
                let source = game.world.getBlock(
                    firstOutcome.targetPosition.x,
                    firstOutcome.targetPosition.y,
                    firstOutcome.targetPosition.z
                )
                if source == Int(cell(B.sweet_berry_bush, 1)) { break }
            }
        }
        guard let session = controller.session,
              let firstOutcome,
              session.physicalFoodSurvivalSnapshot()?.totalConsumedQuantity ?? 0 > 0,
              game.world.getBlock(
                  firstOutcome.targetPosition.x,
                  firstOutcome.targetPosition.y,
                  firstOutcome.targetPosition.z
              ) == Int(cell(B.sweet_berry_bush, 1)) else {
            throw RestartError.boundaryNotReached
        }
        let checkpoint = try session.makeCheckpoint()
        let save = controller.handleCheckpoint(
            ["save", checkpointName], world: game.world
        )
        guard save.succeeded else {
            throw RestartError.checkpointRefused(save.message)
        }
        let wild = session.wildSubsistenceSnapshot()
        let boundary = PebbleIncrement07RestartBoundary(
            phase: "write",
            seed: seed,
            founders: founders,
            worldID: worldID,
            worldTick: game.world.time,
            civilizationTick: session.tick,
            targetKey: firstOutcome.targetKey,
            target: firstOutcome.targetPosition,
            firstAttemptID: firstOutcome.attemptID.rawValue,
            firstActorID: firstOutcome.actorID.rawValue,
            firstAcquisitionQuantity: sweetBerryQuantity(firstOutcome),
            sourceStage: 1,
            totalAcquired: totalSweetBerriesAcquired(wild),
            totalConsumed:
                session.physicalFoodSurvivalSnapshot()?.totalConsumedQuantity ?? 0,
            totalCarried: totalSweetBerriesCarried(by: controller),
            semanticDigest: checkpoint.semanticDigest.rawValue,
            causalDigest: session.causalLedgerSnapshot().summary.digest,
            checkpointSchema: checkpoint.schemaVersion,
            checkpointSaveSucceeded: true,
            worldSaveSucceeded: false
        )
        guard boundary.totalAcquired
                == boundary.totalCarried + Int(boundary.totalConsumed),
              boundary.checkpointSchema == 45 else {
            throw RestartError.conservation
        }
        guard game.exitToTitle() else { throw RestartError.worldSaveRefused }
        let saved = PebbleIncrement07RestartBoundary(
            phase: boundary.phase,
            seed: boundary.seed,
            founders: boundary.founders,
            worldID: boundary.worldID,
            worldTick: boundary.worldTick,
            civilizationTick: boundary.civilizationTick,
            targetKey: boundary.targetKey,
            target: boundary.target,
            firstAttemptID: boundary.firstAttemptID,
            firstActorID: boundary.firstActorID,
            firstAcquisitionQuantity: boundary.firstAcquisitionQuantity,
            sourceStage: boundary.sourceStage,
            totalAcquired: boundary.totalAcquired,
            totalConsumed: boundary.totalConsumed,
            totalCarried: boundary.totalCarried,
            semanticDigest: boundary.semanticDigest,
            causalDigest: boundary.causalDigest,
            checkpointSchema: boundary.checkpointSchema,
            checkpointSaveSucceeded: true,
            worldSaveSucceeded: true
        )
        try writeJSON(saved, to: boundaryPath)
        try writeJSON(saved, to: outputPath)
        print(
            "[ps01-i07-restart] PASS phase=write worldTick=\(saved.worldTick) "
                + "civilizationTick=\(saved.civilizationTick) target="
                + "\(saved.target.x),\(saved.target.y),\(saved.target.z) "
                + "acquired=\(saved.totalAcquired) consumed="
                + "\(saved.totalConsumed) carried=\(saved.totalCarried)"
        )
        fflush(stdout)
    }

    private static func runReader(
        outputPath: String,
        boundaryPath: String,
        seed: UInt32,
        founders: Int,
        worldID: String,
        controller: PebbleAgentController,
        game: GameCore
    ) throws {
        let boundary = try JSONDecoder().decode(
            PebbleIncrement07RestartBoundary.self,
            from: Data(contentsOf: URL(fileURLWithPath: boundaryPath))
        )
        guard boundary.seed == seed, boundary.founders == founders,
              boundary.worldID == worldID else {
            throw RestartError.invalidBoundary
        }
        let load = controller.handleCheckpoint(
            ["load", checkpointName], world: game.world
        )
        guard load.succeeded, let loaded = controller.session else {
            throw RestartError.checkpointRefused(load.message)
        }
        let loadedWorldTick = game.world.time
        let loadedSource = game.world.getBlock(
            boundary.target.x, boundary.target.y, boundary.target.z
        )
        let loadedWild = loaded.wildSubsistenceSnapshot()
        let loadedAcquired = totalSweetBerriesAcquired(loadedWild)
        let loadedConsumed = loaded.physicalFoodSurvivalSnapshot()?
            .totalConsumedQuantity ?? 0
        let loadedCarried = totalSweetBerriesCarried(by: controller)
        let loadedCheckpoint = try loaded.makeCheckpoint()
        guard loadedWorldTick == boundary.worldTick,
              loadedSource == Int(cell(B.sweet_berry_bush, 1)),
              loadedAcquired == boundary.totalAcquired,
              loadedConsumed == boundary.totalConsumed,
              loadedCarried == boundary.totalCarried,
              loadedCheckpoint.schemaVersion == 45 else {
            throw RestartError.restartMutation
        }
        let resume = controller.handleCommand(
            ["resume"], world: game.world, player: game.player
        )
        guard resume.succeeded else {
            throw RestartError.controllerRefused(resume.message)
        }
        let existingAttempts = Set(
            loadedWild.retainedOutcomes.map { $0.outcome.attemptID }
        )
        var renewedWorldTick: Int?
        var renewedStage: Int?
        var secondOutcome: AgentSubsistenceOutcome?
        let continuationStart = game.world.time
        while game.world.time - continuationStart < 48_000 {
            _ = game.frame(dtMs: TICK_MS)
            try drainGeneration(in: game)
            let sourceBeforeCognition = game.world.getBlock(
                boundary.target.x, boundary.target.y, boundary.target.z
            )
            if renewedWorldTick == nil,
               sourceBeforeCognition >> 4 == Int(B.sweet_berry_bush),
               sourceBeforeCognition & 15 >= 2 {
                renewedWorldTick = game.world.time
                renewedStage = sourceBeforeCognition & 15
            }
            controller.update(
                world: game.world,
                player: game.player,
                worldID: worldID,
                dimension: game.dim.rawValue
            )
            guard controller.fatalSessionIntegrityFailure == nil,
                  let session = controller.session else {
                throw RestartError.fatalIntegrity
            }
            secondOutcome = session.wildSubsistenceSnapshot().retainedOutcomes
                .map(\.outcome)
                .first { outcome in
                    !existingAttempts.contains(outcome.attemptID)
                        && outcome.status == .succeeded
                        && outcome.targetKey == boundary.targetKey
                        && outcome.attribution
                            == "core-canonical-preserving-sweet-berry-harvest"
                }
            if secondOutcome != nil, renewedWorldTick != nil { break }
        }
        guard let session = controller.session,
              let renewedWorldTick,
              let renewedStage,
              let secondOutcome else {
            throw RestartError.renewalNotReached
        }
        let finalSource = game.world.getBlock(
            boundary.target.x, boundary.target.y, boundary.target.z
        )
        let finalWild = session.wildSubsistenceSnapshot()
        let finalAcquired = totalSweetBerriesAcquired(finalWild)
        let finalConsumed = session.physicalFoodSurvivalSnapshot()?
            .totalConsumedQuantity ?? 0
        let finalCarried = totalSweetBerriesCarried(by: controller)
        let finalCheckpoint = try session.makeCheckpoint()
        let conservation = finalAcquired
            == finalCarried + Int(finalConsumed)
        let sameSource = secondOutcome.targetPosition == boundary.target
            && renewedWorldTick > boundary.worldTick
            && finalSource == Int(cell(B.sweet_berry_bush, 1))
        guard conservation, sameSource,
              controller.runtimeErrorCount == 0,
              controller.droppedCatchUpSteps == 0 else {
            throw RestartError.conservation
        }
        let finalWorldTick = game.world.time
        let reportBase = PebbleIncrement07RestartContinuation(
            phase: "read",
            seed: seed,
            founders: founders,
            worldID: worldID,
            loadedWorldTick: loadedWorldTick,
            loadedCivilizationTick: loaded.tick,
            loadedSourceStage: loadedSource & 15,
            loadedTotalAcquired: loadedAcquired,
            loadedTotalConsumed: loadedConsumed,
            loadedTotalCarried: loadedCarried,
            loadedCheckpointSchema: loadedCheckpoint.schemaVersion,
            restartCreatedGrowth: loadedSource != Int(cell(B.sweet_berry_bush, 1)),
            restartCreatedMaterial:
                loadedAcquired != boundary.totalAcquired
                    || loadedConsumed != boundary.totalConsumed
                    || loadedCarried != boundary.totalCarried,
            renewedWorldTick: renewedWorldTick,
            renewedSourceStage: renewedStage,
            secondAttemptID: secondOutcome.attemptID.rawValue,
            secondActorID: secondOutcome.actorID.rawValue,
            secondAcquisitionWorldTick: finalWorldTick,
            secondAcquisitionCivilizationTick: secondOutcome.completedAtTick,
            secondAcquisitionQuantity: sweetBerryQuantity(secondOutcome),
            sourceStageAfterSecondAcquisition: finalSource & 15,
            finalTotalAcquired: finalAcquired,
            finalTotalConsumed: finalConsumed,
            finalTotalCarried: finalCarried,
            materialConservationExact: conservation,
            sameSourceRenewalExact: sameSource,
            runtimeErrors: controller.runtimeErrorCount,
            catchUpDrops: controller.droppedCatchUpSteps,
            fatalIntegrityHalted:
                controller.fatalSessionIntegrityFailure != nil,
            semanticDigest: finalCheckpoint.semanticDigest.rawValue,
            causalDigest: session.causalLedgerSnapshot().summary.digest,
            checkpointSchema: finalCheckpoint.schemaVersion,
            worldCleanupSucceeded: false
        )
        _ = controller.stop(
            reason: "increment 07 restart proof complete",
            fallbackWorld: game.world
        )
        guard game.exitToTitle() else { throw RestartError.worldSaveRefused }
        game.deleteWorld(worldID)
        let cleaned = PebbleIncrement07RestartContinuation(
            phase: reportBase.phase,
            seed: reportBase.seed,
            founders: reportBase.founders,
            worldID: reportBase.worldID,
            loadedWorldTick: reportBase.loadedWorldTick,
            loadedCivilizationTick: reportBase.loadedCivilizationTick,
            loadedSourceStage: reportBase.loadedSourceStage,
            loadedTotalAcquired: reportBase.loadedTotalAcquired,
            loadedTotalConsumed: reportBase.loadedTotalConsumed,
            loadedTotalCarried: reportBase.loadedTotalCarried,
            loadedCheckpointSchema: reportBase.loadedCheckpointSchema,
            restartCreatedGrowth: reportBase.restartCreatedGrowth,
            restartCreatedMaterial: reportBase.restartCreatedMaterial,
            renewedWorldTick: reportBase.renewedWorldTick,
            renewedSourceStage: reportBase.renewedSourceStage,
            secondAttemptID: reportBase.secondAttemptID,
            secondActorID: reportBase.secondActorID,
            secondAcquisitionWorldTick: reportBase.secondAcquisitionWorldTick,
            secondAcquisitionCivilizationTick:
                reportBase.secondAcquisitionCivilizationTick,
            secondAcquisitionQuantity: reportBase.secondAcquisitionQuantity,
            sourceStageAfterSecondAcquisition:
                reportBase.sourceStageAfterSecondAcquisition,
            finalTotalAcquired: reportBase.finalTotalAcquired,
            finalTotalConsumed: reportBase.finalTotalConsumed,
            finalTotalCarried: reportBase.finalTotalCarried,
            materialConservationExact: reportBase.materialConservationExact,
            sameSourceRenewalExact: reportBase.sameSourceRenewalExact,
            runtimeErrors: reportBase.runtimeErrors,
            catchUpDrops: reportBase.catchUpDrops,
            fatalIntegrityHalted: reportBase.fatalIntegrityHalted,
            semanticDigest: reportBase.semanticDigest,
            causalDigest: reportBase.causalDigest,
            checkpointSchema: reportBase.checkpointSchema,
            worldCleanupSucceeded: game.db.getWorld(worldID) == nil
        )
        try writeJSON(cleaned, to: outputPath)
        print(
            "[ps01-i07-restart] PASS phase=read loadedWorldTick="
                + "\(cleaned.loadedWorldTick) renewedWorldTick="
                + "\(cleaned.renewedWorldTick) secondWorldTick="
                + "\(cleaned.secondAcquisitionWorldTick) acquired="
                + "\(cleaned.finalTotalAcquired) consumed="
                + "\(cleaned.finalTotalConsumed) carried="
                + "\(cleaned.finalTotalCarried) cleanup="
                + "\(cleaned.worldCleanupSucceeded ? 1 : 0)"
        )
        fflush(stdout)
    }

    private static func configure(
        controller: PebbleAgentController,
        game: GameCore
    ) {
        controller.worldSideReceiptDatabase = game.db
        game.physicalSimulationCoverageProvider = { [weak controller] world in
            controller?.physicalSimulationCoverageRequest(for: world) ?? .inactive
        }
        game.prepareExternalLifecycleState = { [weak controller, weak game] in
            guard let controller, let game else { return false }
            guard game.hasWorld() else {
                return controller.session == nil && controller.activeWorld == nil
            }
            return controller.prepareForLifecyclePersistence(world: game.world)
        }
        game.finalizeExternalLifecycleState = { [weak controller] in
            controller?.finalizeLifecycleAfterPersistence()
        }
    }

    private static func createCanonicalWorld(
        game: GameCore,
        seedText: String,
        seed: UInt32,
        worldID: String
    ) throws {
        game.createWorld(
            name: "PS01 Increment 07 restart",
            seedText: seedText,
            mode: GameMode.survival,
            difficulty: 2
        )
        guard game.hasWorld(), var record = game.worldRec else {
            throw RestartError.worldUnavailable
        }
        let transientID = record.id
        guard game.exitToTitle() else { throw RestartError.worldSaveRefused }
        game.deleteWorld(transientID)
        record.id = worldID
        record.name = "PS01 Increment 07 restart seed \(seed)"
        record.lastPlayed = 0
        guard game.db.putWorld(record) else { throw RestartError.worldUnavailable }
        game.loadWorld(worldID)
        guard game.hasWorld(), game.world.seed == seed else {
            throw RestartError.worldUnavailable
        }
    }

    private static func sweetBerryQuantity(
        _ outcome: AgentSubsistenceOutcome
    ) -> Int {
        outcome.acquiredItems.filter {
            $0.identity.itemKey == "sweet_berries"
        }.reduce(0) { $0 + $1.count }
    }

    private static func totalSweetBerriesAcquired(
        _ snapshot: AgentWildSubsistenceSnapshot
    ) -> Int {
        snapshot.retainedOutcomes.reduce(0) {
            $0 + sweetBerryQuantity($1.outcome)
        }
    }

    private static func totalSweetBerriesCarried(
        by controller: PebbleAgentController
    ) -> Int {
        controller.probesByAgentId.values.reduce(0) { total, probe in
            total + probe.carriedItems.compactMap { $0 }.reduce(0) { partial, stack in
                partial + (itemName(stack.id) == "sweet_berries" ? stack.count : 0)
            }
        }
    }

    private static func drainGeneration(in game: GameCore) throws {
        let deadline = Date(timeIntervalSinceNow: 60)
        while game.physicalSimulationCoverageRuntimeDiagnostics(
            for: game.world
        ).totalGenerationJobsInFlight > 0 {
            guard Date() < deadline else { throw RestartError.generationTimeout }
            _ = RunLoop.main.run(
                mode: .default,
                before: Date(timeIntervalSinceNow: 0.005)
            )
        }
    }

    private static func writeJSON<T: Encodable>(
        _ value: T,
        to path: String
    ) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(value).write(
            to: URL(fileURLWithPath: path), options: .atomic
        )
    }

    private enum RestartError: Error, CustomStringConvertible {
        case invalidConfiguration
        case worldUnavailable
        case controllerRefused(String)
        case checkpointRefused(String)
        case boundaryNotReached
        case renewalNotReached
        case invalidBoundary
        case restartMutation
        case conservation
        case fatalIntegrity
        case generationTimeout
        case worldSaveRefused

        var description: String {
            switch self {
            case .invalidConfiguration: return "invalid configuration"
            case .worldUnavailable: return "World unavailable"
            case let .controllerRefused(reason): return "controller refused: \(reason)"
            case let .checkpointRefused(reason): return "checkpoint refused: \(reason)"
            case .boundaryNotReached: return "first renewal boundary not reached"
            case .renewalNotReached: return "post-restart renewal not reached"
            case .invalidBoundary: return "restart boundary identity mismatch"
            case .restartMutation: return "restart created growth or material"
            case .conservation: return "material/source conservation diverged"
            case .fatalIntegrity: return "fatal session integrity failure"
            case .generationTimeout: return "chunk generation timeout"
            case .worldSaveRefused: return "World save/cleanup refused"
            }
        }
    }
}
