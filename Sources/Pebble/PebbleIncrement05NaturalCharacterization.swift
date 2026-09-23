import Foundation
import PebbleAgents
import PebbleCore

/// Launch-gated, headless observation of the normal PS01 product composition.
/// The harness owns only the requested seed, founder count, elapsed-World-time
/// horizon, and evidence output. GameCore and PebbleAgentController retain all
/// physical, scheduling, cognition, and publication authority.
private struct PebbleIncrement05NaturalCharacterizationReport: Codable {
    let seed: UInt32
    let founders: Int
    let targetWorldTicks: Int
    let worldStart: Int
    let worldEnd: Int
    let eligibleWorldTicks: Int
    let civilizationTick: Int
    let living: Int
    let deaths: Int
    let causalRetained: Int
    let causalDropped: UInt64
    let causalFirst: String?
    let causalLast: String?
    let causalDigest: String
    let semanticDigest: String
    let membershipAuthorityEvent: String?
    let membershipProjectionSize: Int
    let membershipAuthorityPublicationCount: Int
    let agent0RegistrationEvent: String?
    let agent0RegistrationRetained: Bool
    let ecologicalRetained: Int
    let ecologicalEvicted: Int
    let ecologicalTotal: UInt64
    let retainedBerryObservationRows: Int
    let observedBerryObservationEvents: Int
    let wildOpportunityTotal: Int
    let wildAttemptTotal: Int
    let wildGatherSuccesses: Int
    let physicalFoodConsumed: UInt64
    let pathReadinessFailures: Int
    let temporalFallbacks: Int
    let physiologicalBoundaries: Int
    let physiologicalRemainder: Int
    let hungerMinimum: Double
    let hungerMaximum: Double
    let fatigueMinimum: Double
    let fatigueMaximum: Double
    let runtimeErrors: Int
    let fatalIntegrityHalted: Bool
    let catchUpDrops: Int
    let coverageRootCount: Int
    let coverageRootsMatchAgentProbes: Bool
    let neutralPlayerStayedAtSpawn: Bool
}

private struct PebbleIncrement05PerformanceReport: Codable {
    let seed: UInt32
    let founders: Int
    let warmupSamples: Int
    let plateauSamples: Int
    let medianMilliseconds: Double
    let p95Milliseconds: Double
    let maximumMilliseconds: Double
    let runtimeErrors: Int
    let catchUpDrops: Int
    let temporalFallbacks: Int
    let physiologicalBoundaries: Int
}

enum PebbleIncrement05NaturalCharacterization {
    private static let gate =
        "PEBBLELAB_PS01_INCREMENT05_HEADLESS_CHARACTERIZATION"

    /// Returns nil for every ordinary Pebble launch. A non-nil status means
    /// this explicitly gated harness owned the process and no AppKit/render
    /// execution context should be created.
    static func runIfRequested(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> Int32? {
        guard environment[gate] == "1" else { return nil }
        do {
            try run(environment: environment)
            return 0
        } catch {
            fputs("[ps01-i05-headless] FAIL \(error)\n", stderr)
            return 1
        }
    }

    private static func run(environment: [String: String]) throws {
        guard let seedText = environment[
            "PEBBLELAB_PS01_INCREMENT05_HEADLESS_SEED"
        ], let signedSeed = Int32(seedText), let outputPath = environment[
            "PEBBLELAB_PS01_INCREMENT05_HEADLESS_OUTPUT"
        ], !outputPath.isEmpty else {
            throw HarnessError.invalidConfiguration(
                "seed and explicit evidence output are required"
            )
        }
        let mode = environment[
            "PEBBLELAB_PS01_INCREMENT05_HEADLESS_MODE"
        ] ?? "characterization"
        guard mode == "characterization" || mode == "performance" else {
            throw HarnessError.invalidConfiguration("unknown harness mode \(mode)")
        }
        let founders = Int(environment[
            "PEBBLELAB_PS01_INCREMENT05_HEADLESS_FOUNDERS"
        ] ?? "") ?? 20
        let targetWorldTicks = Int(environment[
            "PEBBLELAB_PS01_INCREMENT05_HEADLESS_WORLD_TICKS"
        ] ?? "") ?? 1_200
        if mode == "characterization" {
            guard founders == 20, targetWorldTicks == 1_200 else {
                throw HarnessError.invalidConfiguration(
                    "final characterization requires 20 founders and 1200 World ticks"
                )
            }
        } else {
            guard [20, 24, 30].contains(founders) else {
                throw HarnessError.invalidConfiguration(
                    "performance requires 20, 24, or 30 founders"
                )
            }
        }
        guard let fixedHome = environment["CFFIXED_USER_HOME"],
              fixedHome.hasPrefix("/tmp/")
                || fixedHome.hasPrefix("/private/tmp/") else {
            throw HarnessError.invalidConfiguration(
                "an isolated temporary CFFIXED_USER_HOME is required"
            )
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
        let missingGates = requiredGates.filter { environment[$0] != "1" }
        guard missingGates.isEmpty else {
            throw HarnessError.invalidConfiguration(
                "normal founder gates missing: \(missingGates.joined(separator: ","))"
            )
        }
        guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] != "1" else {
            throw HarnessError.invalidConfiguration(
                "disposable proof behavior is forbidden"
            )
        }

        let seed = UInt32(bitPattern: signedSeed)
        let controller = PebbleAgentController()
        let game = GameCore()
        controller.worldSideReceiptDatabase = game.db
        game.physicalSimulationCoverageProvider = { [weak controller] world in
            controller?.physicalSimulationCoverageRequest(for: world)
                ?? .inactive
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

        // Use GameCore's canonical create-world policy to select the spawn,
        // then reload the same record under a deterministic evidence identity.
        // World/chunk generation still occurs solely through GameCore.
        game.createWorld(
            name: "PS01 Increment 05 characterization",
            seedText: seedText,
            mode: GameMode.survival,
            difficulty: 2
        )
        guard game.hasWorld(), var record = game.worldRec else {
            throw HarnessError.worldUnavailable
        }
        let transientWorldID = record.id
        guard game.exitToTitle() else {
            throw HarnessError.cleanupRefused("initial canonical World")
        }
        game.deleteWorld(transientWorldID)
        record.id = "ps01-i05-headless-seed-\(seed)"
        record.name = "PS01 Increment 05 seed \(seed)"
        record.lastPlayed = 0
        guard game.db.putWorld(record) else {
            throw HarnessError.worldUnavailable
        }
        game.loadWorld(record.id)
        guard game.hasWorld(), game.world.seed == seed else {
            throw HarnessError.worldUnavailable
        }

        // Match the accepted normal seed-46 startup boundary. The Player stays
        // neutral at canonical spawn; it is never moved to load agent regions.
        while game.world.time < 52 {
            _ = game.frame(dtMs: TICK_MS)
            try drainGeneration(in: game)
        }
        let neutralPlayerStart = (
            x: game.player.x, y: game.player.y, z: game.player.z
        )
        let started = controller.start(
            world: game.world,
            player: game.player,
            founders: try PebbleNormalFounderProfile(count: founders)
        )
        guard started.succeeded else {
            throw HarnessError.controllerStartRefused(started.message)
        }
        let coverageRequest = controller.physicalSimulationCoverageRequest(
            for: game.world
        )
        let coverageRoots: [PhysicalSimulationCoverageRoot]
        if case let .active(roots) = coverageRequest {
            coverageRoots = roots
        } else {
            throw HarnessError.coverageUnavailable
        }
        let probePhysicalIDs = Set(
            controller.probesByAgentId.values.map(\.physicalId)
        )
        let coverageRootIDs = Set(coverageRoots.map(\.id))
        let coverageMatchesProbes = coverageRoots.count == founders
            && coverageRootIDs == probePhysicalIDs

        _ = game.frame(dtMs: TICK_MS)
        try drainGeneration(in: game)
        controller.update(
            world: game.world, player: game.player,
            worldID: record.id, dimension: game.dim.rawValue
        )
        let worldStart = game.world.time
        if mode == "performance" {
            try runPerformance(
                seed: seed, founders: founders, outputPath: outputPath,
                controller: controller, game: game
            )
            _ = controller.stop(
                reason: "headless performance complete",
                fallbackWorld: game.world
            )
            guard game.exitToTitle() else {
                throw HarnessError.cleanupRefused("completed performance World")
            }
            game.deleteWorld(record.id)
            return
        }
        var observedBerryEventIDs = Set<AgentCausalEventID>()
        var observedWildAttemptIDs = Set<AgentSubsistenceAttemptID>()
        var observedMembershipAuthorityEventIDs = Set<AgentCausalEventID>()
        var pathReadinessFailures = 0
        var temporalFallbacks = 0

        while game.world.time - worldStart < targetWorldTicks {
            _ = game.frame(dtMs: TICK_MS)
            try drainGeneration(in: game)
            let priorTick = controller.session?.tick
            let priorTemporal = controller.session?.physiologicalTimeSnapshot()
            controller.update(
                world: game.world, player: game.player,
                worldID: record.id, dimension: game.dim.rawValue
            )
            guard controller.fatalSessionIntegrityFailure == nil else {
                throw HarnessError.fatalIntegrity(
                    controller.fatalSessionIntegrityFailure!
                )
            }
            if let session = controller.session {
                let temporal = session.physiologicalTimeSnapshot()
                if session.tick == priorTick,
                   let priorTemporal,
                   temporal.lastReconciledWorldTick
                        != priorTemporal.lastReconciledWorldTick {
                    temporalFallbacks += 1
                    pathReadinessFailures += 1
                }
                for record in session.ecologicalObservationSnapshot().observations
                where record.observation.plants.contains(where: {
                    $0.plantKey == "sweet_berry_bush"
                }) {
                    observedBerryEventIDs.insert(record.causalEventID)
                }
                for outcome in session.wildSubsistenceSnapshot().retainedOutcomes {
                    observedWildAttemptIDs.insert(outcome.outcome.attemptID)
                }
                for event in session.causalLedgerSnapshot().events
                where event.kind == .populationMembershipAuthorityRetained {
                    observedMembershipAuthorityEventIDs.insert(event.eventID)
                }
            }
        }

        guard let session = controller.session else {
            throw HarnessError.sessionUnavailable
        }
        let snapshot = session.snapshot()
        let living = snapshot.agents.filter(\.isAlive)
        let hunger = living.map { $0.needs.hunger }
        let fatigue = living.map { $0.needs.fatigue }
        let physiological = session.physiologicalTimeSnapshot()
        let causal = session.causalLedgerSnapshot()
        let population = session.populationSnapshot()
        let ecology = session.ecologicalObservationSnapshot()
        let wild = session.wildSubsistenceSnapshot()
        let food = session.physicalFoodSurvivalSnapshot()
        let mortality = session.mortalitySnapshot()
        let authorityEvents = causal.events.filter {
            $0.kind == .populationMembershipAuthorityRetained
        }
        let authorityEvent = authorityEvents.last
        let authorityProjectionSize: Int
        if let authorityEvent,
           case let .populationMembershipAuthority(members, _) =
                authorityEvent.payload {
            authorityProjectionSize = members.count
        } else {
            authorityProjectionSize = 0
        }
        let agent0Registration = population.members.first {
            $0.agentID.rawValue == "agent_0"
        }?.registrationEventID
        let retainedBerryRows = ecology.observations.filter {
            $0.observation.plants.contains { $0.plantKey == "sweet_berry_bush" }
        }.count
        let gatherSuccesses = wild.retainedOutcomes.filter {
            $0.outcome.strategy == .wildGathering
                && $0.outcome.status == .succeeded
        }.count
        let checkpoint = try session.makeCheckpoint()
        let report = PebbleIncrement05NaturalCharacterizationReport(
            seed: seed,
            founders: founders,
            targetWorldTicks: targetWorldTicks,
            worldStart: worldStart,
            worldEnd: game.world.time,
            eligibleWorldTicks: game.world.time - worldStart,
            civilizationTick: session.tick,
            living: living.count,
            deaths: mortality.totalDeathCount,
            causalRetained: causal.summary.retainedEventCount,
            causalDropped: causal.summary.droppedEventCount,
            causalFirst: causal.summary.firstRetainedEventID?.rawValue,
            causalLast: causal.summary.lastRetainedEventID?.rawValue,
            causalDigest: causal.summary.digest,
            semanticDigest: checkpoint.semanticDigest.rawValue,
            membershipAuthorityEvent: authorityEvent?.eventID.rawValue,
            membershipProjectionSize: authorityProjectionSize,
            membershipAuthorityPublicationCount:
                observedMembershipAuthorityEventIDs.count,
            agent0RegistrationEvent: agent0Registration?.rawValue,
            agent0RegistrationRetained: agent0Registration.map { id in
                causal.events.contains { $0.eventID == id }
            } ?? false,
            ecologicalRetained: ecology.observations.count,
            ecologicalEvicted: ecology.evictionCounts.observations,
            ecologicalTotal: ecology.totalObservationCount,
            retainedBerryObservationRows: retainedBerryRows,
            observedBerryObservationEvents: observedBerryEventIDs.count,
            wildOpportunityTotal: wild.totalOpportunityCount,
            wildAttemptTotal: wild.totalAttemptCount,
            wildGatherSuccesses: gatherSuccesses,
            physicalFoodConsumed: food?.totalConsumedQuantity ?? 0,
            pathReadinessFailures: pathReadinessFailures,
            temporalFallbacks: temporalFallbacks,
            physiologicalBoundaries: physiological.appliedBoundaryCount,
            physiologicalRemainder: physiological.remainderWorldTicks,
            hungerMinimum: hunger.min() ?? 0,
            hungerMaximum: hunger.max() ?? 0,
            fatigueMinimum: fatigue.min() ?? 0,
            fatigueMaximum: fatigue.max() ?? 0,
            runtimeErrors: controller.runtimeErrorCount,
            fatalIntegrityHalted:
                controller.fatalSessionIntegrityFailure != nil,
            catchUpDrops: controller.droppedCatchUpSteps,
            coverageRootCount: coverageRoots.count,
            coverageRootsMatchAgentProbes: coverageMatchesProbes,
            neutralPlayerStayedAtSpawn:
                game.player.x == neutralPlayerStart.x
                    && game.player.z == neutralPlayerStart.z
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let reportData = try encoder.encode(report)
        try reportData.write(
            to: URL(fileURLWithPath: outputPath), options: .atomic
        )
        print(
            "[ps01-i05-headless] PASS seed=\(seed) "
                + "world=\(worldStart)>\(game.world.time) "
                + "civilizationTick=\(session.tick) living=\(living.count) "
                + "deaths=\(mortality.totalDeathCount) "
                + "semanticDigest=\(checkpoint.semanticDigest.rawValue) "
                + "causalDigest=\(causal.summary.digest) "
                + "coverageRoots=\(coverageRoots.count) "
                + "cameraAuthority=none output=\(outputPath)"
        )
        fflush(stdout)

        _ = controller.stop(
            reason: "headless characterization complete",
            fallbackWorld: game.world
        )
        guard game.exitToTitle() else {
            throw HarnessError.cleanupRefused("completed evidence World")
        }
        game.deleteWorld(record.id)
    }

    private static func runPerformance(
        seed: UInt32,
        founders: Int,
        outputPath: String,
        controller: PebbleAgentController,
        game: GameCore
    ) throws {
        let warmupSamples = 3
        let plateauSamples = founders == 20 ? 13 : (founders == 24 ? 14 : 15)
        var timings: [Double] = []
        var physiologicalBoundaries = 0

        for index in 0..<(warmupSamples + plateauSamples) {
            for _ in 0..<5 {
                _ = game.frame(dtMs: TICK_MS)
                try drainGeneration(in: game)
            }
            let before = controller.session?.physiologicalTimeSnapshot()
            let result = try controller.runIncrement04PerformanceSample(
                world: game.world, player: game.player
            )
            let fields = Dictionary(uniqueKeysWithValues: result.split(separator: " ")
                .compactMap { field -> (String, String)? in
                    let pair = field.split(separator: "=", maxSplits: 1)
                    guard pair.count == 2 else { return nil }
                    return (String(pair[0]), String(pair[1]))
                })
            guard let millisecondsText = fields["controllerMs"],
                  let milliseconds = Double(millisecondsText),
                  fields["hardFailure"] == "0",
                  fields["coverage"] == "ready" else {
                throw HarnessError.invalidPerformanceSample(result)
            }
            if index >= warmupSamples { timings.append(milliseconds) }
            if let before, let after = controller.session?.physiologicalTimeSnapshot() {
                physiologicalBoundaries += max(
                    0, after.appliedBoundaryCount - before.appliedBoundaryCount
                )
            }
        }

        let sorted = timings.sorted()
        guard sorted.count == plateauSamples else {
            throw HarnessError.invalidPerformanceSample("missing plateau samples")
        }
        let report = PebbleIncrement05PerformanceReport(
            seed: seed,
            founders: founders,
            warmupSamples: warmupSamples,
            plateauSamples: plateauSamples,
            medianMilliseconds: percentile(sorted, 0.5),
            p95Milliseconds: percentile(sorted, 0.95),
            maximumMilliseconds: sorted.last ?? 0,
            runtimeErrors: controller.runtimeErrorCount,
            catchUpDrops: controller.droppedCatchUpSteps,
            temporalFallbacks: 0,
            physiologicalBoundaries: physiologicalBoundaries
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(report).write(
            to: URL(fileURLWithPath: outputPath), options: .atomic
        )
        print(
            String(
                format: "[ps01-i05-performance] PASS founders=%d median=%.3f p95=%.3f max=%.3f output=%@",
                founders, report.medianMilliseconds, report.p95Milliseconds,
                report.maximumMilliseconds, outputPath
            )
        )
        fflush(stdout)
    }

    private static func percentile(_ sorted: [Double], _ fraction: Double) -> Double {
        guard !sorted.isEmpty else { return 0 }
        let rank = Double(sorted.count - 1) * fraction
        let lower = Int(rank.rounded(.down))
        let upper = Int(rank.rounded(.up))
        guard lower != upper else { return sorted[lower] }
        let weight = rank - Double(lower)
        return sorted[lower] * (1 - weight) + sorted[upper] * weight
    }

    private static func drainGeneration(in game: GameCore) throws {
        let deadline = Date(timeIntervalSinceNow: 60)
        while game.physicalSimulationCoverageRuntimeDiagnostics(
            for: game.world
        ).totalGenerationJobsInFlight > 0 {
            guard Date() < deadline else {
                throw HarnessError.generationTimeout
            }
            _ = RunLoop.main.run(
                mode: .default,
                before: Date(timeIntervalSinceNow: 0.005)
            )
        }
    }

    private enum HarnessError: Error, CustomStringConvertible {
        case invalidConfiguration(String)
        case worldUnavailable
        case controllerStartRefused(String)
        case coverageUnavailable
        case generationTimeout
        case sessionUnavailable
        case fatalIntegrity(String)
        case invalidPerformanceSample(String)
        case cleanupRefused(String)

        var description: String {
            switch self {
            case let .invalidConfiguration(reason):
                return "invalid configuration: \(reason)"
            case .worldUnavailable:
                return "canonical World unavailable"
            case let .controllerStartRefused(reason):
                return "controller start refused: \(reason)"
            case .coverageUnavailable:
                return "agent-owned physical coverage unavailable"
            case .generationTimeout:
                return "canonical chunk generation did not quiesce"
            case .sessionUnavailable:
                return "controller session unavailable"
            case let .fatalIntegrity(reason):
                return "fatal integrity halt: \(reason)"
            case let .invalidPerformanceSample(reason):
                return "invalid performance sample: \(reason)"
            case let .cleanupRefused(reason):
                return "cleanup refused: \(reason)"
            }
        }
    }
}
