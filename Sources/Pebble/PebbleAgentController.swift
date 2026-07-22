import Foundation
import PebbleAgents
import PebbleCore

struct PebbleAgentCommandResult {
    let succeeded: Bool
    let message: String
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
    var movementEnabled = false
    var lastMovementOutcomes: [AgentMovementOutcome] = []
    var observedGoalKinds = Set<String>()
    var lastInfluencedTracesByAgentId: [String: AgentFeedbackDecisionTrace] = [:]
    var movementWasEverEnabledSinceReset = false
    var activeWorld: World?
    var overlayModeByCommand: PebbleAgentOverlayMode?
    var followMode: PebbleAgentFollowMode = .off
    var demoActive = false
    var successfulCognitiveTicks = 0
    var blockedMovementOutcomeCount = 0
    var runtimeErrorCount = 0
    var droppedCatchUpSteps = 0
    var maxObservedMemoryCount = 0
    var maxObservedDistanceFromHome = 0
    let worldSensor = PebbleAgentWorldSensor()
    let navigationAdapter = PebbleAgentNavigationAdapter()
    let naturalResourceAdapter = PebbleAgentNaturalResourceAdapter()
    let constructionSiteAdapter = PebbleAgentConstructionSiteAdapter()
    let physicalSignalAdapter = PebbleAgentPhysicalSignalAdapter()
    let teachingObservationAdapter = PebbleAgentTeachingObservationAdapter()
    let ecologicalObservationSensor = PebbleAgentEcologicalObservationSensor()
    let physicalActionGateway = PebbleAgentPhysicalActionGateway()
    let materialCustodyGateway = PebbleAgentMaterialCustodyGateway()
    let agricultureExecutor = PebbleAgentAgricultureExecutor()
    let wildSubsistenceExecutor = PebbleAgentWildSubsistenceExecutor()
    let livestockExecutor = PebbleAgentLivestockExecutor()
    let migrationAdmissionAdapter = PebbleAgentMigrationAdmissionAdapter()
    let localEcologyAdapter = PebbleAgentLocalEcologyAdapter()
    let birthSiteAdapter = PebbleAgentBirthSiteAdapter()
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
    var replayRecorder: AgentReplayRecorder?
    var replayBaseCheckpointName: AgentCheckpointName?
    var isAdvancingSession = false
    var kinshipLateFailureProofInjected = false
    var skillLateFailureProofInjected = false
    var ecologicalObservationProofFixture: PebbleAgentEcologicalObservationProofFixture?
    var agricultureProofFixture: PebbleAgentAgricultureProofFixture?
    var wildSubsistenceProofFixture: PebbleAgentWildSubsistenceProofFixture?
    var livestockProofFixture: PebbleAgentLivestockProofFixture?
    var livestockRuntimeEntityIDByRecord: [AgentManagedAnimalRecordID: Int] = [:]

    let environment = ProcessInfo.processInfo.environment
    var featureEnabled: Bool { environment["PEBBLELAB_APP_AGENTS"] == "1" }
    var traceEnabled: Bool { environment["PEBBLELAB_APP_AGENTS_TRACE"] == "1" }
    var overlayEnabledByEnvironment: Bool { environment["PEBBLELAB_APP_AGENTS_OVERLAY"] == "1" }
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
    var populationFeatureEnabled: Bool {
        environment["PEBBLELAB_APP_AGENTS_POPULATION"] == "1"
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

    func update(world: World?, player: Player?, worldID: String? = nil, dimension: Int = 0) {
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
        guard let player else {
            stop(reason: "player unavailable")
            return
        }
        applyFollow(player: player)

        let worldTick = world.time
        guard let previousTick = lastWorldTick else {
            lastWorldTick = worldTick
            return
        }
        lastWorldTick = worldTick
        if isPaused {
            credit = 0
            return
        }
        guard worldTick >= previousTick else {
            credit = 0
            return
        }
        let elapsedWorldTicks = worldTick - previousTick
        credit += elapsedWorldTicks * cognitiveHz
        let availableSteps = credit / 20
        let executedSteps = min(availableSteps, Self.maxCognitiveStepsPerUpdate)
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
        case lifecycleBoundary(String)
        case kinshipBoundary(String)
        case kinshipLateFailureProof
        case householdBoundary(String)
        case ecologicalObservationBoundary(String)
        case agricultureBoundary(String)
        case wildSubsistenceBoundary(String)
        case livestockBoundary(String)
    }
}
