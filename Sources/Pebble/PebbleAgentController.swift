import Foundation
import PebbleAgents
import PebbleCore

struct PebbleAgentCommandResult {
    let succeeded: Bool
    let message: String
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
    var cooperationFeatureEnabled: Bool { environment["PEBBLELAB_APP_AGENTS_COOPERATION"] == "1" }
    var physicalAudioAvailable: () -> Bool = { false }
    var traceEvery: Int {
        guard let raw = environment["PEBBLELAB_APP_AGENTS_TRACE_EVERY"],
              let value = Int(raw), (1...1000).contains(value) else { return 1 }
        return value
    }

    func update(world: World?, player: Player?) {
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
    }
}
