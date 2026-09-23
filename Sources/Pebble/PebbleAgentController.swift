import Foundation
import PebbleAgents
import PebbleCore

struct PebbleAgentCommandResult {
    let succeeded: Bool
    let message: String
}

enum PebbleAgentCivilizationSchedulingStatus: Equatable {
    case running
    case intentionallyPaused
    case fatalIntegrityHalted(String)

    var statusText: String {
        switch self {
        case .running: return "running"
        case .intentionallyPaused: return "paused"
        case let .fatalIntegrityHalted(reason):
            return "fatal-integrity-halted(\(reason))"
        }
    }
}

struct PebbleKinshipLateFailureBoundarySnapshot {
    let durableSessionBytes: Data
    let tick: Int
    let population: AgentPopulationSnapshot
    let lifecycle: AgentLifecycleSnapshot
    let kinship: AgentKinshipSnapshot
    let household: AgentHouseholdSnapshot
    let care: AgentDependentCareSnapshot
    let causal: AgentCausalLedgerSnapshot
    let recorderBytes: Data?
    let recorderRecordCount: Int
    let probeIDs: [String]
    let worldEntityIDs: [String]
}

final class PebbleAgentController {
    private static let maxCognitiveStepsPerUpdate = 8
    var session: AgentSimulationSession?
    var isPaused = false
    var cognitiveHz = 4
    var credit = 0
    var lastWorldTick: Int?
    var seed: UInt32 = 0
    var anchor: AgentPosition?
    var focusedAgentId: String?
    var probesByAgentId: [String: LabCoreAgentEntity] = [:]
    var lastTickResult: AgentSessionTickResult?
    var lastError: String?
    /// A normal-session integrity violation is not transient unavailability.
    /// Once latched, this exact civilization session remains halted until it
    /// is explicitly stopped/replaced; scheduler updates never retry it.
    var fatalSessionIntegrityFailure: String?
    var schedulingStatus: PebbleAgentCivilizationSchedulingStatus {
        if let fatalSessionIntegrityFailure {
            return .fatalIntegrityHalted(fatalSessionIntegrityFailure)
        }
        if let candidatePhysicalHardFailure {
            return .fatalIntegrityHalted(
                "candidate physical hard failure: \(candidatePhysicalHardFailure)"
            )
        }
        return isPaused ? .intentionallyPaused : .running
    }
    var movementEnabled = false
    var lastMovementOutcomes: [AgentMovementOutcome] = []
    var observedGoalKinds = Set<String>()
    var lastInfluencedTracesByAgentId: [String: AgentFeedbackDecisionTrace] = [:]
    var movementWasEverEnabledSinceReset = false
    var activeWorld: World?
    weak var lifecyclePreparedWorld: World?
    var overlayModeByCommand: PebbleAgentOverlayMode?
    var observerUIState = PebbleObserverUIState()
    var followMode: PebbleAgentFollowMode = .off
    var demoActive = false
    var successfulCognitiveTicks = 0
    var blockedMovementOutcomeCount = 0
    var runtimeErrorCount = 0
    var civ39CheckpointRestoreCount = 0
    var droppedCatchUpSteps = 0
    var maxObservedMemoryCount = 0
    var maxObservedDistanceFromHome = 0
    let worldSensor = PebbleAgentWorldSensor()
    let navigationAdapter = PebbleAgentNavigationAdapter()
    let naturalResourceAdapter = PebbleAgentNaturalResourceAdapter()
    let constructionSiteAdapter = PebbleAgentConstructionSiteAdapter()
    let physicalSignalAdapter = PebbleAgentPhysicalSignalAdapter()
    let familyInteractionAdapter = PebbleAgentFamilyInteractionAdapter()
    let teachingObservationAdapter = PebbleAgentTeachingObservationAdapter()
    let ecologicalObservationSensor = PebbleAgentEcologicalObservationSensor()
    let physicalActionGateway = PebbleAgentPhysicalActionGateway()
    let materialCustodyGateway = PebbleAgentMaterialCustodyGateway()
    let productionSensor = PebbleAgentProductionSensor()
    let productionGateway = PebbleAgentProductionGateway()
    let foodConsumptionExecutor = PebbleAgentFoodConsumptionExecutor()
    let agricultureExecutor = PebbleAgentAgricultureExecutor()
    let wildSubsistenceExecutor = PebbleAgentWildSubsistenceExecutor()
    let livestockExecutor = PebbleAgentLivestockExecutor()
    let migrationAdmissionAdapter = PebbleAgentMigrationAdmissionAdapter()
    let localEcologyAdapter = PebbleAgentLocalEcologyAdapter()
    let birthSiteAdapter = PebbleAgentBirthSiteAdapter()
    var bootstrapFounderProfile: PebbleNormalFounderProfile?
    let bootstrapPlacementResolver = PebbleAgentBootstrapPlacementResolver()
    let movementExecutor = PebbleAgentMovementExecutor()
    let cameraFollow = PebbleAgentCameraFollow()
    var interactionExecutor = PebbleAgentInteractionExecutor()
    var naturalResourceExecutor = PebbleAgentNaturalResourceExecutor()
    var constructionExecutor = PebbleAgentConstructionExecutor()
    var lastConstructionSiteDiagnostics = PebbleAgentConstructionSiteDiagnostics()
    var autoInteractionEnabled = false
    var lastAutoInteractionReason = "none"
    var lastInteractionAttempted = false
    var lastInteractionSucceeded = false
    var lastInteractionBlocked = false
    var economyAutoEnabled = false
    var lastEconomyReason = "none"
    var lastDeliverySucceeded = false
    var lastConsumptionSucceeded = false
    var lastSurvivalReason = "none"
    var lastNaturalReason = "none"
    var lastConstructionReason = "none"
    var lastEcologyScanDiagnostics = PebbleAgentLocalEcologyScanDiagnostics()
    var lastEcologyReason = "none"
    var lastForageOutcome: AgentForageOutcome?
    var persistenceWorldID: String?
    var persistenceDimension = 0
    var worldSideReceiptDatabase: SaveDB?
    var replayRecorder: AgentReplayRecorder?
    var replayBaseCheckpointName: AgentCheckpointName?
    var checkpointPositionRestoreFailurePoint:
        PebbleAgentCheckpointPositionRestoreFailurePoint?
    var checkpointPhysicalCustodyFailurePoint:
        PebbleAgentCheckpointPhysicalCustodyFailurePoint?
    var checkpointCustodyHandoff: PebbleAgentCheckpointCustodyHandoff?
    var isAdvancingSession = false
    var kinshipLateFailureProofInjected = false
    var skillLateFailureProofInjected = false
    var candidateMovementLateFailureProofInjected = false
    var candidateRenewableLateFailureProofInjected = false
    var productionWorkshopPosition: AgentPosition?
    var productionToolTargetPosition: PhysicalBlockPosition?
    /// Disposable World restoration data only. It has no discovery, offer or
    /// counterparty-decision authority.
    var barterDisposableWorldFixture: PebbleAgentBarterDisposableWorldFixture?
    var barterMidExchangeFaultInjected = false
    var contractDisposableWorldFixture: PebbleAgentContractDisposableWorldFixture?
    var contractFulfillmentFaultInjected = false
    var contractConsiderationPublicationFaultInjected = false
    var contractFulfillmentPublicationFaultInjected = false
    var marketMidSettlementFaultInjected = false
    var marketPostMutationFaultInjected = false
    var marketRemoteSettlementRefusalCount = 0
    var marketNormalSellerRejectionCount = 0
    var marketNormalSellerAcceptanceCount = 0
    var marketRemoteBuyerRestoreState: LabCoreAgentPhysicalState?
    var marketDisposableWorldFixture: PebbleAgentMarketDisposableWorldFixture?
    var candidateAgricultureNavigationFailureProofInjected = false
    var increment05IntegrityFailureProofPending = false
    var increment05IntegrityFailureProofAttemptCount = 0
    var ecologicalObservationProofFixture: PebbleAgentEcologicalObservationProofFixture?
    var agricultureProofFixture: PebbleAgentAgricultureProofFixture?
    var wildSubsistenceProofFixture: PebbleAgentWildSubsistenceProofFixture?
    var livestockProofFixture: PebbleAgentLivestockProofFixture?
    var livestockRuntimeEntityIDByRecord: [AgentManagedAnimalRecordID: Int] = [:]
    var passiveSocietyFixture: PebbleAgentPassiveSocietyFixture?
    var passiveSocietyAudit = PebbleAgentPassiveSocietyAudit()
    var workDemandRefreshAudit = PebbleAgentWorkDemandRefreshAudit()
    var rightsProofFixture: PebbleAgentMaterialRightsProofFixture?
    var passiveObserverBootstrapComplete = false
    var manualProductiveCommandsAfterBootstrap = 0
    var mortalityMaterialExitAttempt = 0
    var activeCandidatePhysicalTransaction: PebbleCandidatePhysicalTransaction?
    var activeCandidateReceiptTransaction:
        PebbleWorldEcologicalObservationReceiptTransaction?
    var activeEcologicalObservationReplayBatch:
        [AgentEcologicalObservationReceiptBinding]?
    var candidatePhysicalHardFailure: PebbleCandidatePhysicalHardFailure?
    var worldReceiptAttemptSerial: UInt64 = 0
    var ecologicalObservationReceiptValidationCache =
        PebbleEcologicalObservationReceiptValidationCache()
    var lastPhysicalSimulationCoverageTraceKey: String?

    let environment = ProcessInfo.processInfo.environment
    var featureEnabled: Bool { environment["PEBBLELAB_APP_AGENTS"] == "1" }
    var traceEnabled: Bool { environment["PEBBLELAB_APP_AGENTS_TRACE"] == "1" }
    var overlayEnabledByEnvironment: Bool { environment["PEBBLELAB_APP_AGENTS_OVERLAY"] == "1" }
    var observerFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_OBSERVER"] == "1"
    }
    var movementFeatureEnabled: Bool { environment["PEBBLELAB_APP_AGENTS_MOVE"] == "1" }
    var probesFeatureEnabled: Bool { environment["PEBBLELAB_APP_PROBES"] == "1" }
    var debugEntitiesEnabled: Bool { environment["PEBBLELAB_DEBUG_ENTITIES"] == "1" }
    var interactionFeatureEnabled: Bool { environment["PEBBLELAB_APP_AGENTS_INTERACT"] == "1" }
    var naturalFeatureEnabled: Bool { environment["PEBBLELAB_APP_AGENTS_NATURAL"] == "1" }
    var buildFeatureEnabled: Bool { environment["PEBBLELAB_APP_AGENTS_BUILD"] == "1" }
    var socialFeatureEnabled: Bool { environment["PEBBLELAB_APP_AGENTS_SOCIAL"] == "1" }
    var physicalFeatureEnabled: Bool { environment["PEBBLELAB_APP_AGENTS_PHYSICAL"] == "1" }
    var materialFeatureEnabled: Bool { environment["PEBBLELAB_APP_AGENTS_MATERIAL"] == "1" }
    var cooperationFeatureEnabled: Bool { environment["PEBBLELAB_APP_AGENTS_COOPERATION"] == "1" }
    var persistenceFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_PERSISTENCE"] == "1"
    }
    var persistenceReconciliationFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_RECONCILIATION"] == "1"
    }
    var populationFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_POPULATION"] == "1"
    }
    var populationScaleFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_SCALE"] == "1"
    }
    var multiscaleFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_MULTISCALE"] == "1"
    }
    var ecologyFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_ECOLOGY"] == "1"
    }
    var mortalityFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_MORTALITY"] == "1"
    }
    var homeostasisFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_HOMEOSTASIS"] == "1"
    }
    var geneticsFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_GENETICS"] == "1"
    }
    var lifecycleFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_LIFECYCLE"] == "1"
    }
    var kinshipFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_KINSHIP"] == "1"
    }
    var householdFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_HOUSEHOLDS"] == "1"
    }
    var dependentCareFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_CARE"] == "1"
    }
    var childhoodFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_CHILDHOOD"] == "1"
    }
    var familyFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_FAMILY"] == "1"
    }
    var skillFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_SKILLS"] == "1"
    }
    var teachingFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_TEACHING"] == "1"
    }
    var ecologicalObservationFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_ECOLOGICAL_OBSERVATION"] == "1"
    }
    var agricultureFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_AGRICULTURE"] == "1"
    }
    var wildSubsistenceFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_WILD_SUBSISTENCE"] == "1"
    }
    var livestockFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_LIVESTOCK"] == "1"
    }
    var workProfessionsFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_WORK_PROFESSIONS"] == "1"
    }
    var autonomousCivilizationFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_AUTONOMOUS_CIVILIZATION"] == "1"
    }
    var productionFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_PRODUCTION"] == "1"
    }
    var barterFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_BARTER"] == "1"
    }
    var contractFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_CONTRACTS"] == "1"
    }
    var marketFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_MARKETS"] == "1"
    }
    var safeBootstrapLateFailureProofEnabled: Bool {
        environment["PEBBLELAB_DISPOSABLE_SAFE_BOOTSTRAP_LATE_FAILURE_PROOF"] == "1"
            && environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1"
    }
    var kinshipLateFailureProofEnabled: Bool {
        let lineageProof = environment["PEBBLELAB_DISPOSABLE_KINSHIP_LATE_FAILURE_PROOF"] == "1"
        let careProof = environment["PEBBLELAB_DISPOSABLE_CARE_LATE_FAILURE_PROOF"] == "1"
            && householdFeatureEnabled && dependentCareFeatureEnabled
        return (lineageProof || careProof)
            && environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1"
            && featureEnabled && persistenceFeatureEnabled && populationFeatureEnabled
            && lifecycleFeatureEnabled && kinshipFeatureEnabled
            && probesFeatureEnabled && debugEntitiesEnabled && traceEnabled
    }
    var physicalAudioAvailable: () -> Bool = { false }
    var traceEvery: Int {
        guard let raw = environment["PEBBLELAB_APP_AGENTS_TRACE_EVERY"],
              let value = Int(raw), (1...1000).contains(value) else { return 1 }
        return value
    }

    func update(
        world: World?,
        player: Player?,
        worldID: String? = nil,
        dimension: Int = 0,
        maximumSimulationTick: Int? = nil
    ) {
        persistenceWorldID = worldID
        persistenceDimension = dimension
        guard let world else {
            if session != nil { stop(reason: "world unavailable") }
            return
        }
        if let activeWorld, activeWorld !== world {
            stop(reason: "world replaced")
            return
        }
        guard session != nil else { return }
        guard fatalSessionIntegrityFailure == nil,
              candidatePhysicalHardFailure == nil else {
            credit = 0
            return
        }
        guard let player else {
            stop(reason: "player unavailable")
            return
        }
        applyFollow(player: player)

        let worldTick = world.time
        guard let previousWorldTick = lastWorldTick else {
            do {
                try session?.rebasePhysiologicalTime(toWorldTick: worldTick)
            } catch {
                runtimeErrorCount += 1
                lastError = "physiological World-time bind refused: \(error)"
                isPaused = true
                credit = 0
            }
            lastWorldTick = worldTick
            return
        }
        guard worldTick >= previousWorldTick else {
            runtimeErrorCount += 1
            lastError = "physiological World time moved backward "
                + "\(previousWorldTick)>\(worldTick)"
            isPaused = true
            credit = 0
            return
        }
        let expectedCoverage = physicalSimulationCoverageRequest(for: world)
        let coverage = world.physicalSimulationCoverage
        let coverageMismatchReason: String?
        let coverageReady: Bool
        switch expectedCoverage {
        case .inactive:
            coverageReady = coverage.status == .inactive
            coverageMismatchReason = coverageReady
                ? nil : "inactive authority still has World coverage"
        case .active(let roots):
            coverageReady = coverage.status == .ready
                && coverage.roots.count == roots.count
                && Set(coverage.roots) == Set(roots)
            coverageMismatchReason = coverageReady
                ? nil : "derived roots not yet reconciled by World coverage"
        case .refused(let reason):
            coverageReady = false
            coverageMismatchReason = reason
        }
        guard coverageReady else {
            // Coverage readiness is a pre-observation boundary. No sensor,
            // path request or Civilization tick may convert unavailable World
            // state into a negative physical fact.
            lastWorldTick = worldTick
            credit = 0
            let expectedRefused: Bool
            if case .refused = expectedCoverage {
                expectedRefused = true
            } else {
                expectedRefused = false
            }
            let effectiveStatus: PhysicalSimulationCoverageStatus =
                expectedRefused || coverage.status == .refused
                    ? .refused : .pending
            let effectiveReason = coverageMismatchReason ?? coverage.reason
            let key = "\(effectiveStatus.rawValue)|\(coverage.stableDigest)"
                + "|\(effectiveReason ?? "none")"
            if key != lastPhysicalSimulationCoverageTraceKey {
                if effectiveStatus == .refused {
                    runtimeErrorCount += 1
                    lastError = effectiveReason
                        ?? "physical simulation coverage refused"
                }
                trace(
                    "physical coverage status=\(effectiveStatus.rawValue) "
                        + "roots=\(coverage.roots.count) "
                        + "chunks=\(coverage.deduplicatedChunkCount) "
                        + "ready=\(coverage.readyChunks.count) "
                        + "unavailable=\(coverage.unavailableChunks.count) "
                        + "generationRequests="
                        + "\(coverage.generationRequestsThisTick) "
                        + "digest=\(coverage.stableDigest) "
                        + "reason=\(effectiveReason ?? "none")"
                )
                lastPhysicalSimulationCoverageTraceKey = key
            }
            return
        }
        let readyKey = "\(coverage.status.rawValue)|\(coverage.stableDigest)"
        if readyKey != lastPhysicalSimulationCoverageTraceKey {
            trace(
                "physical coverage status=\(coverage.status.rawValue) "
                    + "roots=\(coverage.roots.count) "
                    + "chunks=\(coverage.deduplicatedChunkCount) "
                    + "overlapSavings=\(coverage.overlapSavings) "
                    + "digest=\(coverage.stableDigest)"
            )
            lastPhysicalSimulationCoverageTraceKey = readyKey
        }
        lastWorldTick = worldTick
        if isPaused {
            credit = 0
            return
        }
        let elapsedWorldTicks = worldTick - previousWorldTick
        credit += elapsedWorldTicks * cognitiveHz
        let availableSteps = credit / 20
        let horizonRemaining = maximumSimulationTick.map {
            max(0, $0 - (session?.tick ?? $0))
        } ?? Self.maxCognitiveStepsPerUpdate
        let executedSteps = min(
            availableSteps,
            Self.maxCognitiveStepsPerUpdate,
            horizonRemaining
        )
        for _ in 0..<executedSteps {
            guard advanceOneTick(world: world, player: player) else { return }
            credit -= 20
        }
        if availableSteps > Self.maxCognitiveStepsPerUpdate {
            let dropped = availableSteps - Self.maxCognitiveStepsPerUpdate
            droppedCatchUpSteps += dropped
            credit %= 20
            trace("catchup dropped=\(dropped) total=\(droppedCatchUpSteps)")
        }
    }

    enum ControllerError: Error {
        case missingSession
        case persistableProbe(String)
        case invalidProbeSet([String])
        case movementBoundary(String)
        case unsafeMovement(String)
        case feedbackBoundary(String)
        case interactionBoundary(String)
        case constructionBoundary(String)
        case socialBoundary(String)
        case populationBoundary(String)
        case settlementMetricsBoundary(String)
        case ecologyBoundary(String)
        case mortalityBoundary(String)
        case mortalityRollbackBoundary(String)
        case homeostasisBoundary(String)
        case lifecycleBoundary(String)
        case kinshipBoundary(String)
        case kinshipLateFailureProof
        case householdBoundary(String)
        case ecologicalObservationBoundary(String)
        case agricultureBoundary(String)
        case wildSubsistenceBoundary(String)
        case livestockBoundary(String)
        case physicalFoodBoundary(String)
        case bootstrapPlacementBoundary(String)
        case bootstrapRollbackBoundary(String)
        case familyBoundary(String)
        case barterBoundary(String)
        case barterPostMutationBoundary(String)
        case contractBoundary(String)
        case contractPostMutationBoundary(String)
        case marketBoundary(String)
        case marketPostMutationBoundary(String)
    }
}
