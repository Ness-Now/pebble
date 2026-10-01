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
    let elapsedSeconds: Double
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
    let movementOutcomes: Int?
    let physicalPathSearches: Int?
    let successfulPhysicalPathMovements: Int?
    let provenNoPath: Int?
    let readinessUnavailableOutcomes: Int?
    let nodeBudgetExhausted: Int?
    let coverageLimited: Int?
    let coverageUnavailable: Int?
    let readinessUnavailableByAgent: [String: Int]?
    let agent11ReadinessRecurrences: Int?
    let maximumConsecutiveReadinessUnavailable: Int?
    let directDeferralDecisions: Int?
    let navigationReplans: Int?
    let maximumRepeatedIdenticalUnavailableRequestCount: Int?
    let maximumNoProgressWorldTicks: Int?
    let routedReadinessAttemptBound: Int?
    let identicalDirectRequestBound: Int?
    let cohortPublications: Int?
    let cohortPublicationsWithReadiness: Int?
    let mixedReadinessAndMovementCohorts: Int?
    let checkpointSchemaVersion: Int?
    let checkpointRoundTripExact: Bool?
    let replayRoundTripExact: Bool?
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
    let renewableFoodContinuity: PebbleIncrement07RenewableFoodContinuityReport?
    let scarcityControl: PebbleIncrement07ScarcityReport?
}

private struct PebbleIncrement07ScarcityReport: Codable {
    let observedEdibleBerryEvents: Int
    let preservingAcquisitionCount: Int
    let totalSweetBerriesAcquired: Int
    let totalSweetBerriesConsumed: UInt64
    let totalSweetBerriesCarried: Int
    let initialSweetBerriesCarried: Int
    let fabricatedFood: Bool
}

private struct PebbleIncrement07RenewableFoodContinuityReport: Codable {
    let targetKey: String?
    let targetX: Int?
    let targetY: Int?
    let targetZ: Int?
    let firstActorID: String?
    let firstAcquisitionWorldTick: Int?
    let firstAcquisitionCivilizationTick: Int?
    let firstAcquisitionQuantity: Int?
    let sourceStageAfterFirstAcquisition: Int?
    let firstConsumptionWorldTick: Int?
    let firstConsumptionCivilizationTick: Int?
    let firstConsumptionActorID: String?
    let firstConsumptionQuantity: Int?
    let renewedWorldTick: Int?
    let renewedSourceStage: Int?
    let secondActorID: String?
    let secondAcquisitionWorldTick: Int?
    let secondAcquisitionCivilizationTick: Int?
    let secondAcquisitionQuantity: Int?
    let sourceStageAfterSecondAcquisition: Int?
    let preservingAcquisitionCount: Int
    let totalSweetBerriesAcquired: Int
    let totalSweetBerriesConsumed: UInt64
    let totalSweetBerriesCarried: Int
    let initialSweetBerriesCarried: Int
    let materialConservationExact: Bool
    let sameSourceRenewalExact: Bool
    let normalProductEntry: Bool
    let coverageDiagnostic: PebbleIncrement07CoverageDiagnosticReport
}

private struct PebbleIncrement07CoverageDiagnosticReport: Codable {
    let observedWorldTicksAfterFirstHarvest: Int
    let coveredWorldTicks: Int
    let readyRandomTickEligibleWorldTicks: Int
    let coveredProportion: Double
    let firstUncoveredWorldTick: Int?
    let sourceLightAfterFirstHarvest: Double?
    let minimumObservedLight: Double?
    let maximumObservedLight: Double?
    let minimumNearestLiveFounderManhattanDistance: Int?
    let maximumNearestLiveFounderManhattanDistance: Int?
    let lastNearestLiveFounderManhattanDistance: Int?
    let lastCoveringRootIDs: [String]
    let sourceStageTransitions: [String]
    let randomTickCoordinateHitCount: Int?
    let randomTickCoordinateHitCountUnavailableReason: String
}

private struct PebbleIncrement07SourceTransitionReport: Codable {
    let worldTick: Int
    let stageBefore: Int?
    let stageAfter: Int
    let cause: String
}

private struct PebbleIncrement07MaterialTrackerReport: Codable {
    let targetKey: String?
    let targetX: Int?
    let targetY: Int?
    let targetZ: Int?
    let firstActorID: String?
    let firstHarvestWorldTick: Int?
    let firstHarvestCivilizationTick: Int?
    let firstSourceStageBeforeHarvest: Int?
    let firstCoreDropQuantity: Int?
    let firstCustodyAcquiredQuantity: Int?
    let firstConsumptionWorldTick: Int?
    let firstConsumptionCivilizationTick: Int?
    let firstConsumptionActorID: String?
    let firstConsumptionQuantity: Int?
    let sourceStageAfterFirstHarvest: Int?
    let sourceTransitions: [PebbleIncrement07SourceTransitionReport]
    let renewedWorldTick: Int?
    let renewedSourceStage: Int?
    let secondFreshEvidenceWorldTick: Int?
    let secondFreshEvidenceCivilizationTick: Int?
    let secondFreshEvidenceActorIDs: [String]
    let secondDecisionActorID: String?
    let secondDecisionHunger: Double?
    let sourceReservationActorID: String?
    let opportunityID: String?
    let activityID: String?
    let navigationStartX: Int?
    let navigationStartY: Int?
    let navigationStartZ: Int?
    let navigationStartClassification: String?
    let navigationStatus: String?
    let navigationRoute: [String]
    let navigationReplanCount: Int?
    let navigationPriorFailure: String?
    let pathReadinessResult: String?
    let movementStatus: String?
    let movementResolution: String?
    let secondActorID: String?
    let secondHarvestWorldTick: Int?
    let secondHarvestCivilizationTick: Int?
    let secondSourceStageBeforeHarvest: Int?
    let secondCoreDropQuantity: Int?
    let secondCustodyAcquiredQuantity: Int?
    let secondConsumptionWorldTick: Int?
    let secondConsumptionCivilizationTick: Int?
    let secondConsumptionActorID: String?
    let secondConsumptionQuantity: Int?
    let sourceStageAfterSecondHarvest: Int?
    let preservingAcquisitionCount: Int
    let initialSweetBerriesCarried: Int
    let totalSweetBerriesAcquired: Int
    let totalSweetBerriesConsumed: UInt64
    let totalSweetBerriesCarried: Int
    let materialConservationExact: Bool
}

private struct PebbleIncrement07RuntimeHealthReport: Codable {
    let worldStart: Int
    let worldEnd: Int
    let eligibleWorldTicks: Int
    let civilizationTick: Int
    let living: Int
    let deaths: Int
    let runtimeErrors: Int
    let fatalIntegrityHalted: Bool
    let fatalIntegrityReason: String?
    let catchUpDrops: Int
    let temporalFallbacks: Int
    let pathReadinessFailures: Int
    let readinessUnavailableOutcomes: Int
    let nodeBudgetExhausted: Int
    let coverageLimited: Int
    let coverageUnavailable: Int
}

private struct PebbleIncrement07DurableCampaignReport: Codable {
    let formatVersion: Int
    let seed: UInt32
    let founders: Int
    let behavioralAcceptance: Bool
    let behavioralDisposition: String
    let materialTracker: PebbleIncrement07MaterialTrackerReport
    let runtimeHealth: PebbleIncrement07RuntimeHealthReport
    let checkpointStatus: String
    let checkpointError: String?
}

private struct PebbleIncrement07RenewalTracker {
    var targetKey: String?
    var targetPosition: AgentPosition?
    var firstActorID: String?
    var firstAcquisitionWorldTick: Int?
    var firstAcquisitionCivilizationTick: Int?
    var firstAcquisitionQuantity: Int?
    var firstSourceStageBeforeAcquisition: Int?
    var firstCoreDropQuantity: Int?
    var firstCustodyAcquiredQuantity: Int?
    var sourceStageAfterFirstAcquisition: Int?
    var firstConsumptionWorldTick: Int?
    var firstConsumptionCivilizationTick: Int?
    var firstConsumptionActorID: String?
    var firstConsumptionQuantity: Int?
    var renewedWorldTick: Int?
    var renewedSourceStage: Int?
    var secondActorID: String?
    var secondAcquisitionWorldTick: Int?
    var secondAcquisitionCivilizationTick: Int?
    var secondAcquisitionQuantity: Int?
    var secondSourceStageBeforeAcquisition: Int?
    var secondCoreDropQuantity: Int?
    var secondCustodyAcquiredQuantity: Int?
    var secondConsumptionWorldTick: Int?
    var secondConsumptionCivilizationTick: Int?
    var secondConsumptionActorID: String?
    var secondConsumptionQuantity: Int?
    var sourceStageAfterSecondAcquisition: Int?
    var seenAttemptIDs = Set<AgentSubsistenceAttemptID>()
    var seenConsumptionIDs = Set<String>()
    var preservingAcquisitionCount = 0
    var totalSweetBerriesAcquired = 0
    var coverageObservedTicks = 0
    var coverageCoveredTicks = 0
    var coverageReadyEligibleTicks = 0
    var firstUncoveredWorldTick: Int?
    var sourceLightAfterFirstHarvest: Double?
    var minimumObservedLight: Double?
    var maximumObservedLight: Double?
    var minimumNearestLiveFounderDistance: Int?
    var maximumNearestLiveFounderDistance: Int?
    var lastNearestLiveFounderDistance: Int?
    var lastCoveringRootIDs: [String] = []
    var lastObservedSourceStage: Int?
    var sourceStageTransitions: [String] = []
    var sourceTransitions: [PebbleIncrement07SourceTransitionReport] = []
    var renewalDetectedCivilizationTick: Int?
    var secondFreshEvidenceWorldTick: Int?
    var secondFreshEvidenceCivilizationTick: Int?
    var secondFreshEvidenceActorIDs: [String] = []
    var secondDecisionActorID: String?
    var secondDecisionHunger: Double?
    var sourceReservationActorID: String?
    var secondOpportunityID: String?
    var secondActivityID: String?
    var navigationStart: AgentPosition?
    var navigationStartClassification: String?
    var navigationStatus: String?
    var navigationRoute: [String] = []
    var navigationReplanCount: Int?
    var navigationPriorFailure: String?
    var pathReadinessResult: String?
    var movementStatus: String?
    var movementResolution: String?
}

private struct PebbleIncrement05PerformanceReport: Codable {
    let seed: UInt32
    let founders: Int
    let worldStart: Int
    let worldEnd: Int
    let civilizationStartTick: Int
    let civilizationEndTick: Int
    let warmupSamples: Int
    let plateauSamples: Int
    let medianMilliseconds: Double
    let p95Milliseconds: Double
    let maximumMilliseconds: Double
    let elapsedSeconds: Double
    let runtimeErrors: Int
    let catchUpDrops: Int
    let temporalFallbacks: Int
    let physiologicalBoundaries: Int
    let movementOutcomes: Int?
    let readinessUnavailableOutcomes: Int?
    let physicalPathSearches: Int?
    let successfulPhysicalPathMovements: Int?
    let provenNoPath: Int?
    let nodeBudgetExhausted: Int?
    let coverageLimited: Int?
    let coverageUnavailable: Int?
    let maximumNoProgressWorldTicks: Int?
    let fatalIntegrityHalted: Bool
}

enum PebbleIncrement05NaturalCharacterization {
    private static let increment05Gate =
        "PEBBLELAB_PS01_INCREMENT05_HEADLESS_CHARACTERIZATION"
    private static let increment06Gate =
        "PEBBLELAB_PS01_INCREMENT06_HEADLESS_CHARACTERIZATION"
    private static let increment07Gate =
        "PEBBLELAB_PS01_INCREMENT07_HEADLESS_CHARACTERIZATION"
    private static let increment07ReportingSanityGate =
        "PEBBLELAB_PS01_INCREMENT07_REPORTING_SANITY"

    /// Returns nil for every ordinary Pebble launch. A non-nil status means
    /// this explicitly gated harness owned the process and no AppKit/render
    /// execution context should be created.
    static func runIfRequested(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> Int32? {
        let increment: Int
        if environment[increment07Gate] == "1" {
            increment = 7
        } else if environment[increment06Gate] == "1" {
            increment = 6
        } else if environment[increment05Gate] == "1" {
            increment = 5
        } else {
            return nil
        }
        do {
            try run(environment: environment, increment: increment)
            return 0
        } catch {
            fputs("[ps01-i\(String(format: "%02d", increment))-headless] FAIL \(error)\n", stderr)
            return 1
        }
    }

    private static func run(
        environment: [String: String],
        increment: Int
    ) throws {
        let prefix = "PEBBLELAB_PS01_INCREMENT\(String(format: "%02d", increment))_HEADLESS_"
        guard let seedText = environment[prefix + "SEED"],
              let signedSeed = Int32(seedText),
              let outputPath = environment[prefix + "OUTPUT"],
              !outputPath.isEmpty else {
            throw HarnessError.invalidConfiguration(
                "seed and explicit evidence output are required"
            )
        }
        let seed = UInt32(bitPattern: signedSeed)
        if increment == 7,
           environment[increment07ReportingSanityGate] == "1" {
            try runIncrement07ReportingSanity(
                seed: seed,
                outputPath: outputPath
            )
        }
        let mode = environment[prefix + "MODE"] ?? "characterization"
        guard mode == "characterization" || mode == "performance"
                || (increment == 7 && mode == "scarcity") else {
            throw HarnessError.invalidConfiguration("unknown harness mode \(mode)")
        }
        let founders = Int(environment[prefix + "FOUNDERS"] ?? "") ?? 20
        let targetWorldTicks = Int(
            environment[prefix + "WORLD_TICKS"] ?? ""
        ) ?? 1_200
        if mode == "characterization", increment < 7 {
            guard founders == 20, targetWorldTicks == 1_200 else {
                throw HarnessError.invalidConfiguration(
                    "final characterization requires 20 founders and 1200 World ticks"
                )
            }
        } else if mode == "characterization" {
            guard founders == 24, targetWorldTicks >= 9_600,
                  targetWorldTicks <= 120_000 else {
                throw HarnessError.invalidConfiguration(
                    "increment 07 characterization requires 24 founders and 9600...120000 World ticks"
                )
            }
        } else if mode == "performance" {
            guard [20, 24, 30].contains(founders) else {
                throw HarnessError.invalidConfiguration(
                    "performance requires 20, 24, or 30 founders"
                )
            }
        } else {
            guard founders == 24, targetWorldTicks >= 9_600,
                  targetWorldTicks <= 24_000 else {
                throw HarnessError.invalidConfiguration(
                    "increment 07 scarcity requires 24 founders and 9600...24000 World ticks"
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

        let runStartedAt = Date()
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
            name: "PS01 Increment \(String(format: "%02d", increment)) characterization",
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
        record.id = "ps01-i\(String(format: "%02d", increment))-headless-seed-\(seed)"
        record.name = "PS01 Increment \(String(format: "%02d", increment)) seed \(seed)"
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
                increment: increment,
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
        var observedEdibleBerryEventIDs = Set<AgentCausalEventID>()
        var observedWildAttemptIDs = Set<AgentSubsistenceAttemptID>()
        var observedMembershipAuthorityEventIDs = Set<AgentCausalEventID>()
        var pathReadinessFailures = 0
        var temporalFallbacks = 0
        var movementOutcomes = 0
        var physicalPathSearches = 0
        var successfulPhysicalPathMovements = 0
        var provenNoPath = 0
        var readinessUnavailableOutcomes = 0
        var nodeBudgetExhausted = 0
        var coverageLimited = 0
        var coverageUnavailable = 0
        var readinessUnavailableByAgent: [String: Int] = [:]
        var consecutiveReadinessUnavailableByAgent: [String: Int] = [:]
        var maximumConsecutiveReadinessUnavailable = 0
        var directDeferralDecisions = 0
        var navigationReplans = 0
        var maximumRepeatedIdenticalUnavailableRequestCount = 0
        var lastNavigationReplanCountByAgent = Dictionary(
            uniqueKeysWithValues: (controller.session?.snapshot().agents ?? [])
                .map { ($0.id, $0.navigationProgress.replanCount) }
        )
        var cohortPublications = 0
        var cohortPublicationsWithReadiness = 0
        var mixedReadinessAndMovementCohorts = 0
        var lastProgressWorldTick = worldStart
        var maximumNoProgressWorldTicks = 0
        var renewalTracker = PebbleIncrement07RenewalTracker()
        let initialSweetBerriesCarried = totalSweetBerriesCarried(by: controller)
        var nextProgressWorldTick = worldStart + 1_200

        while game.world.time - worldStart < targetWorldTicks {
            _ = game.frame(dtMs: TICK_MS)
            try drainGeneration(in: game)
            if increment == 7,
               renewalTracker.firstAcquisitionWorldTick != nil,
               renewalTracker.renewedWorldTick == nil,
               let position = renewalTracker.targetPosition {
                let source = game.world.getBlock(position.x, position.y, position.z)
                if source >> 4 == Int(B.sweet_berry_bush), source & 15 >= 2 {
                    renewalTracker.renewedWorldTick = game.world.time
                    renewalTracker.renewedSourceStage = source & 15
                    renewalTracker.renewalDetectedCivilizationTick =
                        controller.session?.tick
                }
            }
            if increment == 7, let session = controller.session {
                observeIncrement07Coverage(
                    tracker: &renewalTracker,
                    session: session,
                    world: game.world
                )
            }
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
                let tickDelta = max(0, session.tick - (priorTick ?? session.tick))
                let movementBatch = controller.lastMovementOutcomes
                let unavailable = movementBatch.filter {
                    $0.status == .readinessUnavailable
                }
                if tickDelta > 0 {
                    let sessionSnapshot = session.snapshot()
                    maximumNoProgressWorldTicks = max(
                        maximumNoProgressWorldTicks,
                        game.world.time - lastProgressWorldTick
                    )
                    lastProgressWorldTick = game.world.time
                    cohortPublications += tickDelta
                    movementOutcomes += movementBatch.count
                    physicalPathSearches += movementBatch.filter(
                        isPhysicalPathSearchOutcome
                    ).count
                    successfulPhysicalPathMovements += movementBatch.filter {
                        $0.status == .moved
                            && $0.resolutionReason
                                == "PebbleCore path and Entity.move verified"
                    }.count
                    provenNoPath += movementBatch.filter {
                        $0.status == .blocked
                            && $0.resolutionReason
                                == "PebbleCore bounded path absent"
                    }.count
                    readinessUnavailableOutcomes += unavailable.count
                    for outcome in unavailable {
                        switch outcome.pathReadinessReason {
                        case .nodeBudgetExhausted?: nodeBudgetExhausted += 1
                        case .coverageLimited?: coverageLimited += 1
                        case .coverageUnavailable?: coverageUnavailable += 1
                        case nil: break
                        }
                    }
                    if !unavailable.isEmpty {
                        cohortPublicationsWithReadiness += tickDelta
                    }
                    if !unavailable.isEmpty,
                       movementBatch.contains(where: { $0.status == .moved }) {
                        mixedReadinessAndMovementCohorts += 1
                    }
                    let unavailableIDs = Set(unavailable.map(\.agentId))
                    for agent in sessionSnapshot.agents {
                        let priorReplans = lastNavigationReplanCountByAgent[
                            agent.id, default: agent.navigationProgress.replanCount
                        ]
                        navigationReplans += max(
                            0, agent.navigationProgress.replanCount - priorReplans
                        )
                        lastNavigationReplanCountByAgent[agent.id] =
                            agent.navigationProgress.replanCount
                        if agent.lastFeedbackDecisionTrace?.tick == session.tick,
                           agent.lastFeedbackDecisionTrace?.dominantFactor.kind
                            == .pathReadinessDeferral,
                           agent.lastAction?.reason
                            == "bounded direct physical path readiness deferred until intent changes" {
                            directDeferralDecisions += 1
                        }
                        if unavailableIDs.contains(agent.id) {
                            readinessUnavailableByAgent[agent.id, default: 0] += 1
                            let repeatedAttemptCount = agent.lastAction?.name
                                == "move_abstract"
                                ? 1
                                : agent.navigationProgress.replanCount + 1
                            maximumRepeatedIdenticalUnavailableRequestCount = max(
                                maximumRepeatedIdenticalUnavailableRequestCount,
                                repeatedAttemptCount
                            )
                            let consecutive = consecutiveReadinessUnavailableByAgent[
                                agent.id, default: 0
                            ] + 1
                            consecutiveReadinessUnavailableByAgent[agent.id] = consecutive
                            maximumConsecutiveReadinessUnavailable = max(
                                maximumConsecutiveReadinessUnavailable, consecutive
                            )
                        } else {
                            consecutiveReadinessUnavailableByAgent[agent.id] = 0
                        }
                    }
                } else {
                    maximumNoProgressWorldTicks = max(
                        maximumNoProgressWorldTicks,
                        game.world.time - lastProgressWorldTick
                    )
                }
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
                    if record.observation.plants.contains(where: {
                        $0.plantKey == "sweet_berry_bush"
                            && $0.edibleSourceEvidence != nil
                    }) {
                        observedEdibleBerryEventIDs.insert(record.causalEventID)
                    }
                }
                for outcome in session.wildSubsistenceSnapshot().retainedOutcomes {
                    observedWildAttemptIDs.insert(outcome.outcome.attemptID)
                }
                if increment == 7 {
                    observeIncrement07Renewal(
                        tracker: &renewalTracker,
                        session: session,
                        world: game.world
                    )
                    if tickDelta > 0 {
                        observeIncrement07Reentry(
                            tracker: &renewalTracker,
                            controller: controller,
                            session: session,
                            world: game.world
                        )
                    }
                }
                for event in session.causalLedgerSnapshot().events
                where event.kind == .populationMembershipAuthorityRetained {
                    observedMembershipAuthorityEventIDs.insert(event.eventID)
                }
            }
            if increment == 7,
               renewalTracker.secondAcquisitionWorldTick != nil,
               renewalTracker.firstConsumptionWorldTick != nil {
                break
            }
            if increment == 7, game.world.time >= nextProgressWorldTick {
                let progressConsumed = controller.session?
                    .physicalFoodSurvivalSnapshot()?.totalConsumedQuantity ?? 0
                let livingCount = controller.session?.snapshot().agents
                    .filter(\.isAlive).count ?? 0
                let target = renewalTracker.targetPosition.map {
                    "\($0.x),\($0.y),\($0.z)"
                } ?? "none"
                let sourceCell = renewalTracker.targetPosition.map {
                    game.world.getBlock($0.x, $0.y, $0.z)
                }
                let sourceStage = sourceCell.map { $0 & 15 } ?? -1
                let coveredProportion = renewalTracker.coverageObservedTicks == 0
                    ? 0
                    : Double(renewalTracker.coverageCoveredTicks)
                        / Double(renewalTracker.coverageObservedTicks)
                print(
                    "[ps01-i07-headless] progress worldTicks="
                        + "\(game.world.time - worldStart) civilizationTick="
                        + "\(controller.session?.tick ?? -1) acquisitions="
                        + "\(renewalTracker.preservingAcquisitionCount) consumed="
                        + "\(progressConsumed) renewed="
                        + "\(renewalTracker.renewedWorldTick == nil ? 0 : 1) "
                        + "living=\(livingCount) target=\(target) firstWorldTick="
                        + "\(renewalTracker.firstAcquisitionWorldTick ?? -1) "
                        + "renewedWorldTick=\(renewalTracker.renewedWorldTick ?? -1) "
                        + "sourceStage=\(sourceStage) coveredTicks="
                        + "\(renewalTracker.coverageCoveredTicks)/"
                        + "\(renewalTracker.coverageObservedTicks) coveredProportion="
                        + String(format: "%.6f", coveredProportion)
                        + " readyRandomTickEligibleTicks="
                        + "\(renewalTracker.coverageReadyEligibleTicks) nearestLive="
                        + "\(renewalTracker.lastNearestLiveFounderDistance ?? -1) "
                        + "freshEvidenceActors="
                        + "\(renewalTracker.secondFreshEvidenceActorIDs.count) "
                        + "decisionActor="
                        + "\(renewalTracker.secondDecisionActorID ?? "none") "
                        + "coveringRoots="
                        + "\(renewalTracker.lastCoveringRootIDs.joined(separator: ","))"
                )
                fflush(stdout)
                nextProgressWorldTick += 1_200
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
        let finalSweetBerriesCarried = totalSweetBerriesCarried(by: controller)
        let totalConsumed = food?.totalConsumedQuantity ?? 0
        let increment07RuntimeHealth = PebbleIncrement07RuntimeHealthReport(
            worldStart: worldStart,
            worldEnd: game.world.time,
            eligibleWorldTicks: game.world.time - worldStart,
            civilizationTick: session.tick,
            living: living.count,
            deaths: mortality.totalDeathCount,
            runtimeErrors: controller.runtimeErrorCount,
            fatalIntegrityHalted: controller.fatalSessionIntegrityFailure != nil,
            fatalIntegrityReason: controller.fatalSessionIntegrityFailure.map {
                String(describing: $0)
            },
            catchUpDrops: controller.droppedCatchUpSteps,
            temporalFallbacks: temporalFallbacks,
            pathReadinessFailures: pathReadinessFailures,
            readinessUnavailableOutcomes: readinessUnavailableOutcomes,
            nodeBudgetExhausted: nodeBudgetExhausted,
            coverageLimited: coverageLimited,
            coverageUnavailable: coverageUnavailable
        )
        func writeIncrement07Evidence(
            checkpointStatus: String,
            checkpointError: String?
        ) throws {
            guard increment == 7 else { return }
            let behavioral = increment07BehavioralDisposition(renewalTracker)
            let report = PebbleIncrement07DurableCampaignReport(
                formatVersion: 1,
                seed: seed,
                founders: founders,
                behavioralAcceptance: behavioral.accepted,
                behavioralDisposition: behavioral.disposition,
                materialTracker: increment07MaterialTrackerReport(
                    renewalTracker,
                    initialSweetBerriesCarried: initialSweetBerriesCarried,
                    finalSweetBerriesCarried: finalSweetBerriesCarried,
                    totalConsumed: totalConsumed
                ),
                runtimeHealth: increment07RuntimeHealth,
                checkpointStatus: checkpointStatus,
                checkpointError: checkpointError
            )
            try writeIncrement07DurableCampaignReport(
                report,
                outputPath: outputPath
            )
        }

        // Persist the behavioral/material/runtime observation before any
        // terminal checkpoint work. A checkpoint refusal must never erase an
        // otherwise complete campaign trace.
        try writeIncrement07Evidence(
            checkpointStatus: "notAttempted",
            checkpointError: nil
        )

        let checkpoint: AgentSessionCheckpoint
        let checkpointRoundTripExact: Bool
        let replayRoundTripExact: Bool
        do {
            checkpoint = try session.makeCheckpoint()
            let checkpointBytes = try AgentCheckpointCodec.encode(checkpoint)
            let decodedCheckpoint = try AgentCheckpointCodec.decode(
                AgentSessionCheckpoint.self,
                from: checkpointBytes
            )
            let restored = try AgentSimulationSession.restoring(decodedCheckpoint)
            checkpointRoundTripExact = try restored.durableStateBytes()
                == session.durableStateBytes()
            if increment >= 6 {
                // Keep the natural campaign on the normal product path. Recording
                // every product operation would repeatedly encode the growing
                // journal and turn characterization time into proof-instrumentation
                // time. Operation replay is covered by the focused boundary tests;
                // here the native terminal checkpoint must also be a valid exact
                // replay base in a fresh reconstructed session.
                let recorder = try AgentReplayRecorder(
                    checkpoint: checkpoint,
                    session: restored
                )
                let journal = try recorder.journal(
                    named: AgentCheckpointName(
                        rawValue: "ps01-i06-seed-\(seed)"
                    )!
                )
                let replay = try AgentSessionReplayer.replay(
                    checkpoint: checkpoint,
                    journal: journal
                )
                replayRoundTripExact = try replay.report.verified
                    && replay.session.durableStateBytes()
                        == session.durableStateBytes()
            } else {
                replayRoundTripExact = false
            }
            try writeIncrement07Evidence(
                checkpointStatus: "passed",
                checkpointError: nil
            )
        } catch {
            try writeIncrement07Evidence(
                checkpointStatus: "failed",
                checkpointError: String(describing: error)
            )
            throw error
        }
        if increment >= 6 {
            guard session.tick >= (game.world.time - worldStart) / 5,
                  pathReadinessFailures == 0,
                  temporalFallbacks == 0,
                  controller.runtimeErrorCount == 0,
                  controller.droppedCatchUpSteps == 0,
                  checkpointRoundTripExact,
                  replayRoundTripExact else {
                throw HarnessError.livenessInvariant(
                    "tick=\(session.tick) readinessFailures=\(pathReadinessFailures) "
                        + "fallbacks=\(temporalFallbacks) runtimeErrors="
                        + "\(controller.runtimeErrorCount) catchUpDrops="
                        + "\(controller.droppedCatchUpSteps) checkpoint="
                        + "\(checkpointRoundTripExact) replay=\(replayRoundTripExact)"
                )
            }
        }
        let renewalReport: PebbleIncrement07RenewableFoodContinuityReport?
        let scarcityReport: PebbleIncrement07ScarcityReport?
        if increment == 7, mode == "characterization" {
            let conservationExact = renewalTracker.totalSweetBerriesAcquired
                + initialSweetBerriesCarried
                == finalSweetBerriesCarried + Int(totalConsumed)
            let sameSourceExact = renewalTracker.targetKey != nil
                && renewalTracker.sourceStageAfterFirstAcquisition == 1
                && renewalTracker.firstConsumptionWorldTick != nil
                && renewalTracker.renewedWorldTick != nil
                && renewalTracker.secondAcquisitionWorldTick != nil
                && renewalTracker.sourceStageAfterSecondAcquisition == 1
                && renewalTracker.secondAcquisitionWorldTick!
                    > renewalTracker.renewedWorldTick!
            guard sameSourceExact, conservationExact,
                  initialSweetBerriesCarried == 0 else {
                throw HarnessError.renewalInvariant(
                    "sameSource=\(sameSourceExact) conservation=\(conservationExact) "
                        + "initial=\(initialSweetBerriesCarried) acquired="
                        + "\(renewalTracker.totalSweetBerriesAcquired) consumed="
                        + "\(totalConsumed) carried=\(finalSweetBerriesCarried)"
                )
            }
            renewalReport = PebbleIncrement07RenewableFoodContinuityReport(
                targetKey: renewalTracker.targetKey,
                targetX: renewalTracker.targetPosition?.x,
                targetY: renewalTracker.targetPosition?.y,
                targetZ: renewalTracker.targetPosition?.z,
                firstActorID: renewalTracker.firstActorID,
                firstAcquisitionWorldTick: renewalTracker.firstAcquisitionWorldTick,
                firstAcquisitionCivilizationTick:
                    renewalTracker.firstAcquisitionCivilizationTick,
                firstAcquisitionQuantity: renewalTracker.firstAcquisitionQuantity,
                sourceStageAfterFirstAcquisition:
                    renewalTracker.sourceStageAfterFirstAcquisition,
                firstConsumptionWorldTick: renewalTracker.firstConsumptionWorldTick,
                firstConsumptionCivilizationTick:
                    renewalTracker.firstConsumptionCivilizationTick,
                firstConsumptionActorID: renewalTracker.firstConsumptionActorID,
                firstConsumptionQuantity: renewalTracker.firstConsumptionQuantity,
                renewedWorldTick: renewalTracker.renewedWorldTick,
                renewedSourceStage: renewalTracker.renewedSourceStage,
                secondActorID: renewalTracker.secondActorID,
                secondAcquisitionWorldTick: renewalTracker.secondAcquisitionWorldTick,
                secondAcquisitionCivilizationTick:
                    renewalTracker.secondAcquisitionCivilizationTick,
                secondAcquisitionQuantity: renewalTracker.secondAcquisitionQuantity,
                sourceStageAfterSecondAcquisition:
                    renewalTracker.sourceStageAfterSecondAcquisition,
                preservingAcquisitionCount: renewalTracker.preservingAcquisitionCount,
                totalSweetBerriesAcquired: renewalTracker.totalSweetBerriesAcquired,
                totalSweetBerriesConsumed: totalConsumed,
                totalSweetBerriesCarried: finalSweetBerriesCarried,
                initialSweetBerriesCarried: initialSweetBerriesCarried,
                materialConservationExact: conservationExact,
                sameSourceRenewalExact: sameSourceExact,
                normalProductEntry: true,
                coverageDiagnostic: increment07CoverageReport(renewalTracker)
            )
            scarcityReport = nil
        } else if increment == 7 {
            let fabricated = observedEdibleBerryEventIDs.isEmpty
                && (renewalTracker.totalSweetBerriesAcquired != 0
                    || totalConsumed != 0 || finalSweetBerriesCarried != 0)
            guard !fabricated,
                  observedEdibleBerryEventIDs.isEmpty,
                  renewalTracker.preservingAcquisitionCount == 0,
                  renewalTracker.totalSweetBerriesAcquired == 0,
                  totalConsumed == 0,
                  initialSweetBerriesCarried == 0,
                  finalSweetBerriesCarried == 0 else {
                throw HarnessError.scarcityInvariant(
                    "edibleEvidence=\(observedEdibleBerryEventIDs.count) "
                        + "acquisitions=\(renewalTracker.preservingAcquisitionCount) "
                        + "acquired=\(renewalTracker.totalSweetBerriesAcquired) "
                        + "consumed=\(totalConsumed) carried=\(finalSweetBerriesCarried)"
                )
            }
            renewalReport = nil
            scarcityReport = PebbleIncrement07ScarcityReport(
                observedEdibleBerryEvents: observedEdibleBerryEventIDs.count,
                preservingAcquisitionCount: renewalTracker.preservingAcquisitionCount,
                totalSweetBerriesAcquired: renewalTracker.totalSweetBerriesAcquired,
                totalSweetBerriesConsumed: totalConsumed,
                totalSweetBerriesCarried: finalSweetBerriesCarried,
                initialSweetBerriesCarried: initialSweetBerriesCarried,
                fabricatedFood: fabricated
            )
        } else {
            renewalReport = nil
            scarcityReport = nil
        }
        let report = PebbleIncrement05NaturalCharacterizationReport(
            seed: seed,
            founders: founders,
            targetWorldTicks: targetWorldTicks,
            worldStart: worldStart,
            worldEnd: game.world.time,
            eligibleWorldTicks: game.world.time - worldStart,
            elapsedSeconds: Date().timeIntervalSince(runStartedAt),
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
            movementOutcomes: increment >= 6 ? movementOutcomes : nil,
            physicalPathSearches: increment >= 6 ? physicalPathSearches : nil,
            successfulPhysicalPathMovements:
                increment >= 6 ? successfulPhysicalPathMovements : nil,
            provenNoPath: increment >= 6 ? provenNoPath : nil,
            readinessUnavailableOutcomes:
                increment >= 6 ? readinessUnavailableOutcomes : nil,
            nodeBudgetExhausted: increment >= 6 ? nodeBudgetExhausted : nil,
            coverageLimited: increment >= 6 ? coverageLimited : nil,
            coverageUnavailable: increment >= 6 ? coverageUnavailable : nil,
            readinessUnavailableByAgent:
                increment >= 6 ? readinessUnavailableByAgent : nil,
            agent11ReadinessRecurrences:
                increment >= 6 ? readinessUnavailableByAgent["agent_11", default: 0] : nil,
            maximumConsecutiveReadinessUnavailable:
                increment >= 6 ? maximumConsecutiveReadinessUnavailable : nil,
            directDeferralDecisions:
                increment >= 6 ? directDeferralDecisions : nil,
            navigationReplans: increment >= 6 ? navigationReplans : nil,
            maximumRepeatedIdenticalUnavailableRequestCount:
                increment >= 6
                    ? maximumRepeatedIdenticalUnavailableRequestCount : nil,
            maximumNoProgressWorldTicks:
                increment >= 6 ? maximumNoProgressWorldTicks : nil,
            routedReadinessAttemptBound:
                increment >= 6 ? session.configuration.navigationMaxReplans + 1 : nil,
            identicalDirectRequestBound: increment >= 6 ? 1 : nil,
            cohortPublications: increment >= 6 ? cohortPublications : nil,
            cohortPublicationsWithReadiness:
                increment >= 6 ? cohortPublicationsWithReadiness : nil,
            mixedReadinessAndMovementCohorts:
                increment >= 6 ? mixedReadinessAndMovementCohorts : nil,
            checkpointSchemaVersion:
                increment >= 6 ? checkpoint.schemaVersion : nil,
            checkpointRoundTripExact:
                increment >= 6 ? checkpointRoundTripExact : nil,
            replayRoundTripExact:
                increment >= 6 ? replayRoundTripExact : nil,
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
                    && game.player.z == neutralPlayerStart.z,
            renewableFoodContinuity: renewalReport,
            scarcityControl: scarcityReport
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let reportData = try encoder.encode(report)
        try reportData.write(
            to: URL(fileURLWithPath: outputPath), options: .atomic
        )
        print(
            "[ps01-i\(String(format: "%02d", increment))-headless] PASS seed=\(seed) "
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
        increment: Int,
        seed: UInt32,
        founders: Int,
        outputPath: String,
        controller: PebbleAgentController,
        game: GameCore
    ) throws {
        let runStartedAt = Date()
        let warmupSamples = 3
        let plateauSamples = founders == 20 ? 13 : (founders == 24 ? 14 : 15)
        let worldStart = game.world.time
        let civilizationStartTick = controller.session?.tick ?? 0
        var lastProgressWorldTick = worldStart
        var maximumNoProgressWorldTicks = 0
        var timings: [Double] = []
        var physiologicalBoundaries = 0
        var movementOutcomes = 0
        var readinessUnavailableOutcomes = 0
        var physicalPathSearches = 0
        var successfulPhysicalPathMovements = 0
        var provenNoPath = 0
        var nodeBudgetExhausted = 0
        var coverageLimited = 0
        var coverageUnavailable = 0

        for index in 0..<(warmupSamples + plateauSamples) {
            for _ in 0..<5 {
                _ = game.frame(dtMs: TICK_MS)
                try drainGeneration(in: game)
            }
            let priorTick = controller.session?.tick
            let before = controller.session?.physiologicalTimeSnapshot()
            let result = try controller.runIncrement04PerformanceSample(
                world: game.world, player: game.player
            )
            if controller.session?.tick != priorTick {
                maximumNoProgressWorldTicks = max(
                    maximumNoProgressWorldTicks,
                    game.world.time - lastProgressWorldTick
                )
                lastProgressWorldTick = game.world.time
            } else {
                maximumNoProgressWorldTicks = max(
                    maximumNoProgressWorldTicks,
                    game.world.time - lastProgressWorldTick
                )
            }
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
            movementOutcomes += controller.lastMovementOutcomes.count
            for outcome in controller.lastMovementOutcomes
            where outcome.status == .readinessUnavailable {
                readinessUnavailableOutcomes += 1
                switch outcome.pathReadinessReason {
                case .nodeBudgetExhausted?: nodeBudgetExhausted += 1
                case .coverageLimited?: coverageLimited += 1
                case .coverageUnavailable?: coverageUnavailable += 1
                case nil: break
                }
            }
            physicalPathSearches += controller.lastMovementOutcomes.filter(
                isPhysicalPathSearchOutcome
            ).count
            successfulPhysicalPathMovements += controller.lastMovementOutcomes
                .filter {
                    $0.status == .moved
                        && $0.resolutionReason
                            == "PebbleCore path and Entity.move verified"
                }.count
            provenNoPath += controller.lastMovementOutcomes.filter {
                $0.status == .blocked
                    && $0.resolutionReason == "PebbleCore bounded path absent"
            }.count
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
            worldStart: worldStart,
            worldEnd: game.world.time,
            civilizationStartTick: civilizationStartTick,
            civilizationEndTick: controller.session?.tick ?? 0,
            warmupSamples: warmupSamples,
            plateauSamples: plateauSamples,
            medianMilliseconds: percentile(sorted, 0.5),
            p95Milliseconds: percentile(sorted, 0.95),
            maximumMilliseconds: sorted.last ?? 0,
            elapsedSeconds: Date().timeIntervalSince(runStartedAt),
            runtimeErrors: controller.runtimeErrorCount,
            catchUpDrops: controller.droppedCatchUpSteps,
            temporalFallbacks: 0,
            physiologicalBoundaries: physiologicalBoundaries,
            movementOutcomes: movementOutcomes,
            readinessUnavailableOutcomes: readinessUnavailableOutcomes,
            physicalPathSearches: physicalPathSearches,
            successfulPhysicalPathMovements: successfulPhysicalPathMovements,
            provenNoPath: provenNoPath,
            nodeBudgetExhausted: nodeBudgetExhausted,
            coverageLimited: coverageLimited,
            coverageUnavailable: coverageUnavailable,
            maximumNoProgressWorldTicks: maximumNoProgressWorldTicks,
            fatalIntegrityHalted:
                controller.fatalSessionIntegrityFailure != nil
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(report).write(
            to: URL(fileURLWithPath: outputPath), options: .atomic
        )
        print(
            String(
                format: "[ps01-i%02d-performance] PASS founders=%d median=%.3f p95=%.3f max=%.3f output=%@",
                increment, founders, report.medianMilliseconds, report.p95Milliseconds,
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

    private static func isPhysicalPathSearchOutcome(
        _ outcome: AgentMovementOutcome
    ) -> Bool {
        outcome.status == .readinessUnavailable
            || outcome.resolutionReason == "PebbleCore path and Entity.move verified"
            || outcome.resolutionReason == "PebbleCore bounded path absent"
            || outcome.resolutionReason
                == "PebbleCore bounded path has no next step"
            || outcome.resolutionReason
                == "PebbleCore path requested unsupported vertical step"
            || outcome.resolutionReason
                == "Core step exceeds exploration home boundary"
            || outcome.resolutionReason == "physical destination occupied"
            || outcome.resolutionReason
                == "PebbleCore collision blocked movement"
    }

    private static func runIncrement07ReportingSanity(
        seed: UInt32,
        outputPath: String
    ) throws {
        let tracker = PebbleIncrement07RenewalTracker()
        let runtime = PebbleIncrement07RuntimeHealthReport(
            worldStart: 0,
            worldEnd: 0,
            eligibleWorldTicks: 0,
            civilizationTick: 0,
            living: 0,
            deaths: 0,
            runtimeErrors: 0,
            fatalIntegrityHalted: false,
            fatalIntegrityReason: nil,
            catchUpDrops: 0,
            temporalFallbacks: 0,
            pathReadinessFailures: 0,
            readinessUnavailableOutcomes: 0,
            nodeBudgetExhausted: 0,
            coverageLimited: 0,
            coverageUnavailable: 0
        )
        func report(status: String, error: String?) -> PebbleIncrement07DurableCampaignReport {
            let behavioral = increment07BehavioralDisposition(tracker)
            return PebbleIncrement07DurableCampaignReport(
                formatVersion: 1,
                seed: seed,
                founders: 0,
                behavioralAcceptance: behavioral.accepted,
                behavioralDisposition: behavioral.disposition,
                materialTracker: increment07MaterialTrackerReport(
                    tracker,
                    initialSweetBerriesCarried: 0,
                    finalSweetBerriesCarried: 0,
                    totalConsumed: 0
                ),
                runtimeHealth: runtime,
                checkpointStatus: status,
                checkpointError: error
            )
        }
        try writeIncrement07DurableCampaignReport(
            report(status: "notAttempted", error: nil),
            outputPath: outputPath
        )
        let injected = "injected reporting-sanity checkpoint validation failure"
        try writeIncrement07DurableCampaignReport(
            report(status: "failed", error: injected),
            outputPath: outputPath
        )
        throw HarnessError.injectedCheckpointFailure(injected)
    }

    private static func increment07BehavioralDisposition(
        _ tracker: PebbleIncrement07RenewalTracker
    ) -> (accepted: Bool, disposition: String) {
        let accepted = tracker.targetKey != nil
            && tracker.sourceStageAfterFirstAcquisition == 1
            && tracker.firstConsumptionWorldTick != nil
            && tracker.renewedWorldTick != nil
            && tracker.secondAcquisitionWorldTick != nil
            && tracker.sourceStageAfterSecondAcquisition == 1
            && tracker.secondAcquisitionWorldTick! > tracker.renewedWorldTick!
        if accepted { return (true, "sameSourceSecondAcquisitionVerified") }
        if tracker.firstAcquisitionWorldTick == nil {
            return (false, "noFirstPreservingAcquisition")
        }
        if tracker.firstConsumptionWorldTick == nil {
            return (false, "firstAcquisitionWithoutPhysicalConsumption")
        }
        if tracker.renewedWorldTick == nil {
            return (false, "noAuthoritativeSameSourceRenewal")
        }
        if tracker.secondFreshEvidenceCivilizationTick == nil {
            return (false, "renewedSourceWithoutFreshEvidence")
        }
        if tracker.secondDecisionActorID == nil {
            return (false, "freshEvidenceWithoutSecondAutonomousDecision")
        }
        return (false, "secondAutonomousDecisionWithoutSameSourceAcquisition")
    }

    private static func increment07MaterialTrackerReport(
        _ tracker: PebbleIncrement07RenewalTracker,
        initialSweetBerriesCarried: Int,
        finalSweetBerriesCarried: Int,
        totalConsumed: UInt64
    ) -> PebbleIncrement07MaterialTrackerReport {
        PebbleIncrement07MaterialTrackerReport(
            targetKey: tracker.targetKey,
            targetX: tracker.targetPosition?.x,
            targetY: tracker.targetPosition?.y,
            targetZ: tracker.targetPosition?.z,
            firstActorID: tracker.firstActorID,
            firstHarvestWorldTick: tracker.firstAcquisitionWorldTick,
            firstHarvestCivilizationTick:
                tracker.firstAcquisitionCivilizationTick,
            firstSourceStageBeforeHarvest:
                tracker.firstSourceStageBeforeAcquisition,
            firstCoreDropQuantity: tracker.firstCoreDropQuantity,
            firstCustodyAcquiredQuantity:
                tracker.firstCustodyAcquiredQuantity,
            firstConsumptionWorldTick: tracker.firstConsumptionWorldTick,
            firstConsumptionCivilizationTick:
                tracker.firstConsumptionCivilizationTick,
            firstConsumptionActorID: tracker.firstConsumptionActorID,
            firstConsumptionQuantity: tracker.firstConsumptionQuantity,
            sourceStageAfterFirstHarvest:
                tracker.sourceStageAfterFirstAcquisition,
            sourceTransitions: tracker.sourceTransitions,
            renewedWorldTick: tracker.renewedWorldTick,
            renewedSourceStage: tracker.renewedSourceStage,
            secondFreshEvidenceWorldTick:
                tracker.secondFreshEvidenceWorldTick,
            secondFreshEvidenceCivilizationTick:
                tracker.secondFreshEvidenceCivilizationTick,
            secondFreshEvidenceActorIDs:
                tracker.secondFreshEvidenceActorIDs,
            secondDecisionActorID: tracker.secondDecisionActorID,
            secondDecisionHunger: tracker.secondDecisionHunger,
            sourceReservationActorID: tracker.sourceReservationActorID,
            opportunityID: tracker.secondOpportunityID,
            activityID: tracker.secondActivityID,
            navigationStartX: tracker.navigationStart?.x,
            navigationStartY: tracker.navigationStart?.y,
            navigationStartZ: tracker.navigationStart?.z,
            navigationStartClassification:
                tracker.navigationStartClassification,
            navigationStatus: tracker.navigationStatus,
            navigationRoute: tracker.navigationRoute,
            navigationReplanCount: tracker.navigationReplanCount,
            navigationPriorFailure: tracker.navigationPriorFailure,
            pathReadinessResult: tracker.pathReadinessResult,
            movementStatus: tracker.movementStatus,
            movementResolution: tracker.movementResolution,
            secondActorID: tracker.secondActorID,
            secondHarvestWorldTick: tracker.secondAcquisitionWorldTick,
            secondHarvestCivilizationTick:
                tracker.secondAcquisitionCivilizationTick,
            secondSourceStageBeforeHarvest:
                tracker.secondSourceStageBeforeAcquisition,
            secondCoreDropQuantity: tracker.secondCoreDropQuantity,
            secondCustodyAcquiredQuantity:
                tracker.secondCustodyAcquiredQuantity,
            secondConsumptionWorldTick: tracker.secondConsumptionWorldTick,
            secondConsumptionCivilizationTick:
                tracker.secondConsumptionCivilizationTick,
            secondConsumptionActorID: tracker.secondConsumptionActorID,
            secondConsumptionQuantity: tracker.secondConsumptionQuantity,
            sourceStageAfterSecondHarvest:
                tracker.sourceStageAfterSecondAcquisition,
            preservingAcquisitionCount: tracker.preservingAcquisitionCount,
            initialSweetBerriesCarried: initialSweetBerriesCarried,
            totalSweetBerriesAcquired: tracker.totalSweetBerriesAcquired,
            totalSweetBerriesConsumed: totalConsumed,
            totalSweetBerriesCarried: finalSweetBerriesCarried,
            materialConservationExact:
                tracker.totalSweetBerriesAcquired + initialSweetBerriesCarried
                    == finalSweetBerriesCarried + Int(totalConsumed)
        )
    }

    private static func writeIncrement07DurableCampaignReport(
        _ report: PebbleIncrement07DurableCampaignReport,
        outputPath: String
    ) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(report)
        // The sibling remains the durable separated evidence even when the
        // primary path is later replaced by the established complete report.
        try data.write(
            to: URL(fileURLWithPath: outputPath + ".evidence.json"),
            options: .atomic
        )
        try data.write(
            to: URL(fileURLWithPath: outputPath),
            options: .atomic
        )
    }

    private static func observedSweetBerryStage(
        for outcome: AgentSubsistenceOutcome,
        session: AgentSimulationSession
    ) -> Int? {
        guard let eventID = outcome.sourceObservationEventID,
              let observation = session.ecologicalObservationSnapshot()
                .observations.first(where: { $0.causalEventID == eventID }),
              let evidence = observation.observation.plants.first(where: {
                  $0.plantKey == "sweet_berry_bush"
                      && $0.position == outcome.targetPosition
              })?.edibleSourceEvidence else { return nil }
        for stage in 2...3 where evidence.physicalSourceFingerprint
            == pebbleAgentEdibleSourceFingerprint(
                sourceCell: Int(cell(B.sweet_berry_bush, stage)),
                blockName: "sweet_berry_bush",
                canonicalMaterialName: "sweet_berries"
            ) {
            return stage
        }
        return nil
    }

    private static func observeIncrement07Renewal(
        tracker: inout PebbleIncrement07RenewalTracker,
        session: AgentSimulationSession,
        world: World
    ) {
        for record in session.wildSubsistenceSnapshot().retainedOutcomes
        where tracker.seenAttemptIDs.insert(record.outcome.attemptID).inserted {
            let outcome = record.outcome
            guard outcome.strategy == .wildGathering,
                  outcome.status == .succeeded,
                  outcome.attribution
                    == "core-canonical-preserving-sweet-berry-harvest" else {
                continue
            }
            let quantity = outcome.acquiredItems.filter {
                $0.identity.itemKey == "sweet_berries"
            }.reduce(0) { $0 + $1.count }
            tracker.preservingAcquisitionCount += 1
            tracker.totalSweetBerriesAcquired += quantity
            let source = world.getBlock(
                outcome.targetPosition.x,
                outcome.targetPosition.y,
                outcome.targetPosition.z
            )
            let sourceStage = source & 15
            let observedSourceStage = observedSweetBerryStage(
                for: outcome,
                session: session
            )
            if tracker.targetKey == nil {
                tracker.targetKey = outcome.targetKey
                tracker.targetPosition = outcome.targetPosition
                tracker.firstActorID = outcome.actorID.rawValue
                tracker.firstAcquisitionWorldTick = world.time
                tracker.firstAcquisitionCivilizationTick = session.tick
                tracker.firstAcquisitionQuantity = quantity
                tracker.firstSourceStageBeforeAcquisition = observedSourceStage
                // The preserving transaction transfers every Core-spawned
                // ItemEntity stack into exact custody before publication.
                // A succeeded outcome therefore proves the same quantity at
                // both sides of that physical boundary.
                tracker.firstCoreDropQuantity = quantity
                tracker.firstCustodyAcquiredQuantity = quantity
                tracker.sourceStageAfterFirstAcquisition = sourceStage
                tracker.sourceLightAfterFirstHarvest = world.lightAt(
                    outcome.targetPosition.x,
                    outcome.targetPosition.y,
                    outcome.targetPosition.z
                )
                tracker.lastObservedSourceStage = sourceStage
                tracker.sourceStageTransitions.append(
                    "worldTick=\(world.time):stage=\(sourceStage):firstHarvest"
                )
                tracker.sourceTransitions.append(
                    PebbleIncrement07SourceTransitionReport(
                        worldTick: world.time,
                        stageBefore: observedSourceStage,
                        stageAfter: sourceStage,
                        cause: "firstPreservingHarvest"
                    )
                )
            } else if outcome.targetKey == tracker.targetKey,
                      tracker.renewedWorldTick != nil,
                      tracker.secondAcquisitionWorldTick == nil {
                tracker.secondActorID = outcome.actorID.rawValue
                tracker.secondAcquisitionWorldTick = world.time
                tracker.secondAcquisitionCivilizationTick = session.tick
                tracker.secondAcquisitionQuantity = quantity
                tracker.secondSourceStageBeforeAcquisition = observedSourceStage
                tracker.secondCoreDropQuantity = quantity
                tracker.secondCustodyAcquiredQuantity = quantity
                tracker.sourceStageAfterSecondAcquisition = sourceStage
                tracker.sourceTransitions.append(
                    PebbleIncrement07SourceTransitionReport(
                        worldTick: world.time,
                        stageBefore: observedSourceStage,
                        stageAfter: sourceStage,
                        cause: "secondPreservingHarvest"
                    )
                )
            }
        }
        guard tracker.firstAcquisitionWorldTick != nil,
              let physical = session.physicalFoodSurvivalSnapshot() else { return }
        for outcome in physical.completedOutcomes
        where tracker.seenConsumptionIDs.insert(outcome.consumptionID).inserted {
            guard outcome.canonicalMaterialName == "sweet_berries" else { continue }
            if tracker.firstConsumptionWorldTick == nil {
                tracker.firstConsumptionWorldTick = world.time
                tracker.firstConsumptionCivilizationTick = session.tick
                tracker.firstConsumptionActorID = outcome.agentID.rawValue
                tracker.firstConsumptionQuantity = outcome.quantityConsumed
            } else if tracker.secondAcquisitionCivilizationTick != nil,
                      tracker.secondConsumptionWorldTick == nil {
                tracker.secondConsumptionWorldTick = world.time
                tracker.secondConsumptionCivilizationTick = session.tick
                tracker.secondConsumptionActorID = outcome.agentID.rawValue
                tracker.secondConsumptionQuantity = outcome.quantityConsumed
            }
        }
    }

    /// Records only the causal facts needed to bind renewed physical evidence
    /// to the ordinary selected activity and movement outcome. This observer
    /// never publishes evidence, reserves work, or mutates physical/cognitive
    /// state.
    private static func observeIncrement07Reentry(
        tracker: inout PebbleIncrement07RenewalTracker,
        controller: PebbleAgentController,
        session: AgentSimulationSession,
        world: World
    ) {
        guard let target = tracker.targetPosition,
              let renewalTick = tracker.renewedWorldTick,
              let renewalCivilizationTick = tracker.renewalDetectedCivilizationTick,
              world.time >= renewalTick,
              session.tick > renewalCivilizationTick else { return }

        let snapshot = session.snapshot()
        let wild = session.wildSubsistenceSnapshot()
        let autonomous = session.autonomousActivitySnapshot()
        var freshActors = Set<String>()
        var freshWorldTicks: [Int] = []
        var freshCivilizationTicks: [Int] = []

        for agent in snapshot.agents.sorted(by: { $0.id < $1.id }) {
            guard let actorID = AgentID(rawValue: agent.id) else { continue }
            let observation = session.ecologicalObservations(for: actorID)
                .first?.observation
            let observedPlant = observation?.plants.first {
                $0.plantKey == "sweet_berry_bush" && $0.position == target
            }
            let hasFreshEdibleEvidence = observation?.isFresh(
                atSimulationTick: session.tick
            ) == true && observedPlant?.edibleSourceEvidence?
                .canonicalMaterialName == "sweet_berries"
            if hasFreshEdibleEvidence {
                freshActors.insert(agent.id)
                if let tick = observation?.physicalWorldTick {
                    freshWorldTicks.append(tick)
                }
                if let tick = observation?.observedAtSimulationTick {
                    freshCivilizationTicks.append(tick)
                }
            }

            let selectedTracked = wild.opportunities.first {
                $0.actorID == actorID && $0.status == .selected
                    && $0.expiresAtTick >= session.tick
                    && $0.lastObservedPosition == target
                    && $0.strategy == .wildGathering
            }
            let active = autonomous.activeActivities.first {
                $0.candidate.actorID == actorID
            }
            let activeTracked = active?.candidate.domain == .wildGathering
                && active?.candidate.physicalTarget == target
            guard selectedTracked != nil || activeTracked else { continue }

            let switchedActor = tracker.secondDecisionActorID != agent.id
            if switchedActor {
                tracker.navigationStart = nil
                tracker.navigationStartClassification = nil
                tracker.navigationStatus = nil
                tracker.navigationRoute = []
                tracker.navigationReplanCount = nil
                tracker.navigationPriorFailure = nil
                tracker.pathReadinessResult = nil
                tracker.movementStatus = nil
                tracker.movementResolution = nil
            }
            tracker.secondDecisionActorID = agent.id
            tracker.secondDecisionHunger = agent.needs.hunger
            tracker.sourceReservationActorID = selectedTracked?.actorID.rawValue
            tracker.secondOpportunityID = selectedTracked?.opportunityID.rawValue
            tracker.secondActivityID = activeTracked ? active?.activityID : nil
            if tracker.navigationStart == nil {
                tracker.navigationStart = agent.position
                let occupied = snapshot.agents.filter {
                    $0.id != agent.id && $0.isAlive
                }.map(\.position)
                let navigation = controller.navigationAdapter.observe(
                    world: world,
                    agent: agent,
                    target: target,
                    occupiedAgentPositions: occupied,
                    goalMode: .cardinalAdjacent
                )
                let statuses = navigation.cells.filter {
                    $0.position == agent.position
                }.map { $0.status.rawValue }.sorted()
                tracker.navigationStartClassification = statuses.isEmpty
                    ? "absent" : statuses.joined(separator: ",")
            }
            tracker.navigationStatus = agent.navigationProgress.status.rawValue
            if let route = agent.navigationProgress.route {
                tracker.navigationRoute = route.positions.map {
                    "\($0.x),\($0.y),\($0.z)"
                }
            }
            tracker.navigationReplanCount = agent.navigationProgress.replanCount
            tracker.navigationPriorFailure =
                agent.navigationProgress.lastFailure?.rawValue
            if let movement = controller.lastMovementOutcomes.last(where: {
                $0.agentId == agent.id
            }) {
                tracker.pathReadinessResult =
                    movement.pathReadinessReason?.rawValue ?? "ready"
                tracker.movementStatus = movement.status.rawValue
                tracker.movementResolution = movement.resolutionReason
            }
            if switchedActor {
                print(
                    "[ps01-i07-reentry] selected worldTick=\(world.time) "
                        + "civilizationTick=\(session.tick) actor=\(agent.id) "
                        + "target=\(target.x),\(target.y),\(target.z) hunger="
                        + "\(agent.needs.hunger)"
                )
                fflush(stdout)
            }
        }

        guard !freshActors.isEmpty else { return }
        let priorActors = Set(tracker.secondFreshEvidenceActorIDs)
        tracker.secondFreshEvidenceActorIDs = Array(
            priorActors.union(freshActors)
        ).sorted()
        if tracker.secondFreshEvidenceCivilizationTick == nil {
            tracker.secondFreshEvidenceCivilizationTick =
                freshCivilizationTicks.min() ?? session.tick
            tracker.secondFreshEvidenceWorldTick =
                freshWorldTicks.min() ?? world.time
            print(
                "[ps01-i07-reentry] freshEvidence worldTick="
                    + "\(tracker.secondFreshEvidenceWorldTick ?? world.time) "
                    + "civilizationTick="
                    + "\(tracker.secondFreshEvidenceCivilizationTick ?? session.tick) "
                    + "actors="
                    + tracker.secondFreshEvidenceActorIDs.joined(separator: ",")
            )
            fflush(stdout)
        }
    }
    /// Reads the coverage snapshot installed by the just-completed Core frame.
    /// It neither requests coverage nor registers a physical interest.
    private static func observeIncrement07Coverage(
        tracker: inout PebbleIncrement07RenewalTracker,
        session: AgentSimulationSession,
        world: World
    ) {
        guard tracker.firstAcquisitionWorldTick != nil,
              let position = tracker.targetPosition else { return }
        let chunkX = floorDiv(position.x, CHUNK_W)
        let chunkZ = floorDiv(position.z, CHUNK_W)
        let coverage = world.physicalSimulationCoverage
        let covered = coverage.covers(chunkX: chunkX, chunkZ: chunkZ)
        let coveringRoots = coverage.roots.filter {
            abs($0.chunkX - chunkX)
                <= PhysicalSimulationCoverageContract.chunkRadius
                && abs($0.chunkZ - chunkZ)
                    <= PhysicalSimulationCoverageContract.chunkRadius
        }.map(\.id).sorted()
        let source = world.getBlock(position.x, position.y, position.z)
        let sourceID = source >> 4
        let sourceStage = source & 15
        let light = world.lightAt(position.x, position.y, position.z)
        let randomTickRegistered = sourceID >= 0
            && sourceID < RANDOM_TICKS.count
            && RANDOM_TICKS[sourceID] == 1
        let readyEligible = coverage.status == .ready
            && covered
            && world.isChunkReady(chunkX, chunkZ)
            && world.randomTickSpeed > 0
            && randomTickRegistered

        tracker.coverageObservedTicks += 1
        if covered {
            tracker.coverageCoveredTicks += 1
        } else if tracker.firstUncoveredWorldTick == nil {
            tracker.firstUncoveredWorldTick = world.time
        }
        if readyEligible { tracker.coverageReadyEligibleTicks += 1 }
        tracker.lastCoveringRootIDs = coveringRoots
        tracker.minimumObservedLight = min(
            tracker.minimumObservedLight ?? light, light
        )
        tracker.maximumObservedLight = max(
            tracker.maximumObservedLight ?? light, light
        )
        let living = session.snapshot().agents.filter(\.isAlive)
        let nearest = living.map {
            abs($0.position.x - position.x)
                + abs($0.position.y - position.y)
                + abs($0.position.z - position.z)
        }.min()
        tracker.lastNearestLiveFounderDistance = nearest
        if let nearest {
            tracker.minimumNearestLiveFounderDistance = min(
                tracker.minimumNearestLiveFounderDistance ?? nearest, nearest
            )
            tracker.maximumNearestLiveFounderDistance = max(
                tracker.maximumNearestLiveFounderDistance ?? nearest, nearest
            )
        }
        if tracker.lastObservedSourceStage != sourceStage {
            let priorStage = tracker.lastObservedSourceStage
            tracker.lastObservedSourceStage = sourceStage
            tracker.sourceStageTransitions.append(
                "worldTick=\(world.time):stage=\(sourceStage):"
                    + "covered=\(covered ? 1 : 0):light=\(light)"
            )
            tracker.sourceTransitions.append(
                PebbleIncrement07SourceTransitionReport(
                    worldTick: world.time,
                    stageBefore: priorStage,
                    stageAfter: sourceStage,
                    cause: "authoritativeWorldObservation"
                )
            )
            print(
                "[ps01-i07-coverage] sourceTransition worldTick=\(world.time) "
                    + "target=\(position.x),\(position.y),\(position.z) "
                    + "stage=\(sourceStage) covered=\(covered ? 1 : 0) "
                    + "coverageStatus=\(coverage.status.rawValue) "
                    + "randomTickEligible=\(readyEligible ? 1 : 0) "
                    + "light=\(light) nearestLive=\(nearest ?? -1) roots="
                    + coveringRoots.joined(separator: ",")
            )
            fflush(stdout)
        }
    }

    private static func increment07CoverageReport(
        _ tracker: PebbleIncrement07RenewalTracker
    ) -> PebbleIncrement07CoverageDiagnosticReport {
        PebbleIncrement07CoverageDiagnosticReport(
            observedWorldTicksAfterFirstHarvest: tracker.coverageObservedTicks,
            coveredWorldTicks: tracker.coverageCoveredTicks,
            readyRandomTickEligibleWorldTicks:
                tracker.coverageReadyEligibleTicks,
            coveredProportion: tracker.coverageObservedTicks == 0
                ? 0
                : Double(tracker.coverageCoveredTicks)
                    / Double(tracker.coverageObservedTicks),
            firstUncoveredWorldTick: tracker.firstUncoveredWorldTick,
            sourceLightAfterFirstHarvest: tracker.sourceLightAfterFirstHarvest,
            minimumObservedLight: tracker.minimumObservedLight,
            maximumObservedLight: tracker.maximumObservedLight,
            minimumNearestLiveFounderManhattanDistance:
                tracker.minimumNearestLiveFounderDistance,
            maximumNearestLiveFounderManhattanDistance:
                tracker.maximumNearestLiveFounderDistance,
            lastNearestLiveFounderManhattanDistance:
                tracker.lastNearestLiveFounderDistance,
            lastCoveringRootIDs: tracker.lastCoveringRootIDs,
            sourceStageTransitions: tracker.sourceStageTransitions,
            randomTickCoordinateHitCount: nil,
            randomTickCoordinateHitCountUnavailableReason:
                "Core exposes authoritative coverage and cell transitions but no "
                    + "per-coordinate random-tick sample counter; adding a scheduler "
                    + "callback was intentionally avoided for read-only diagnosis"
        )
    }

    private static func totalSweetBerriesCarried(
        by controller: PebbleAgentController
    ) -> Int {
        controller.probesByAgentId.values.reduce(0) { total, probe in
            total + probe.carriedItems.compactMap { $0 }.reduce(0) { subtotal, stack in
                subtotal + (itemName(stack.id) == "sweet_berries" ? stack.count : 0)
            }
        }
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
        case livenessInvariant(String)
        case renewalInvariant(String)
        case scarcityInvariant(String)
        case cleanupRefused(String)
        case injectedCheckpointFailure(String)

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
            case let .livenessInvariant(reason):
                return "path-readiness liveness invariant failed: \(reason)"
            case let .renewalInvariant(reason):
                return "renewal invariant failed: \(reason)"
            case let .scarcityInvariant(reason):
                return "scarcity invariant failed: \(reason)"
            case let .cleanupRefused(reason):
                return "cleanup refused: \(reason)"
            case let .injectedCheckpointFailure(reason):
                return "checkpoint validation failed: \(reason)"
            }
        }
    }
}
