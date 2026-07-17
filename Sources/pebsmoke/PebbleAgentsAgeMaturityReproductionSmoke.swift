import Foundation
import PebbleAgents

private let lifecycleHabitat = AgentEcologyHabitatObservation(
    worldTick: 0,
    candidateIndex: 0,
    habitatPosition: AgentPosition(x: 1, y: 63, z: 0),
    foragePosition: AgentPosition(x: 1, y: 64, z: 0),
    habitatFingerprint: 528,
    distanceFromSettlement: 1,
    directionIndex: 0,
    worldReadCount: 4
)

private func lifecycleSmokeAgent(
    _ id: String,
    x: Int,
    hunger: Double = 0,
    health: Int = 100
) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id,
        state: "idle",
        position: position,
        needs: AgentNeeds(hunger: hunger, fatigue: 0, curiosity: 0.1, safety: 1),
        health: health,
        fear: 0,
        homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "lifecycle fixture", startedAtTick: 0, urgency: 0
        ),
        lastAction: nil,
        lastActionEffect: nil,
        memory: [],
        tickCreated: 0,
        ticksAlive: 0,
        observationCount: 0,
        nearbyObservationCount: 0,
        goalSelectionCount: 0,
        goalChangeCount: 0,
        actionCount: 0,
        actionEffectCount: 0,
        movementCount: 0,
        totalManhattanDistanceMoved: 0,
        returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func lifecycleSmokeBase(
    _ id: String,
    populationConfiguration: AgentPopulationConfiguration = .live,
    agentOrder: [String] = ["agent_0", "agent_1", "agent_2"],
    hungerByID: [String: Double] = [:],
    healthByID: [String: Int] = [:],
    survivalConfiguration: AgentSurvivalConfiguration = .live,
    ecologyConfiguration: AgentLocalEcologyConfiguration = .live
) -> AgentSimulationSession {
    let configuration = try! AgentSessionConfiguration(
        seed: 46,
        nearbyRadius: 8,
        resourceObservationRadius: 8,
        recentMemorySnapshotLimit: 8,
        memoryPolicy: .bounded(maxEntries: 64),
        survivalConfiguration: survivalConfiguration
    )
    let xByID = ["agent_0": 0, "agent_1": 2, "agent_2": 4]
    var session = try! AgentSimulationSession(
        configuration: configuration,
        agents: agentOrder.map {
            lifecycleSmokeAgent(
                $0,
                x: xByID[$0]!,
                hunger: hungerByID[$0] ?? 0,
                health: healthByID[$0] ?? 100
            )
        },
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 8192)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3),
        configuration: populationConfiguration
    )
    try! session.initializeLocalEcology(
        observations: [lifecycleHabitat],
        configuration: ecologyConfiguration
    )
    _ = try! session.applyLocalEcologyEndOfTick(habitatValidations: [lifecycleHabitat])
    return session
}

private func lifecycleAdvance(
    _ session: inout AgentSimulationSession,
    to target: Int
) {
    while session.tick < target { _ = try! session.advanceTick() }
}

@discardableResult
private func lifecycleResolveBirth(
    _ session: inout AgentSimulationSession,
    position: AgentPosition
) -> AgentBirthRecord {
    let plan = session.pendingBirthSitePlan()!
    return try! session.applyBirthSiteObservation(AgentBirthSiteObservation(
        planID: plan.planID,
        observedTick: session.tick,
        position: position,
        candidateIndex: 0,
        worldFingerprint: 9_001 + session.lifecycleSummary().totalBirthCount
    ))!
}

func runPebbleAgentsAgeMaturityReproductionSmoke() {
    section("pebble agents age maturity reproduction")

    let configuration = AgentLifecycleConfiguration.live
    check("lifecycle configuration defaults",
          configuration.newbornDurationTicks == 2
            && configuration.maturityAgeTicks == 8
            && configuration.maximumConcurrentPlans == 1
            && configuration.maximumBirthsPerTick == 1)
    check("lifecycle configuration rejects newborn zero", {
        do {
            _ = try AgentLifecycleConfiguration(newbornDurationTicks: 0)
            return false
        } catch AgentLifecycleError.invalidConfiguration("bounds") { return true }
        catch { return false }
    }())
    check("lifecycle configuration rejects maturity overlap", {
        do {
            _ = try AgentLifecycleConfiguration(newbornDurationTicks: 2, maturityAgeTicks: 2)
            return false
        } catch AgentLifecycleError.invalidConfiguration("bounds") { return true }
        catch { return false }
    }())
    check("lifecycle configuration Codable", {
        let bytes = try! AgentCheckpointCodec.encode(configuration)
        return (try? AgentCheckpointCodec.decode(
            AgentLifecycleConfiguration.self, from: bytes
        )) == configuration
    }())

    var disabled = lifecycleSmokeBase("sim-lifecycle-disabled")
    let disabledBefore = try! disabled.durableStateBytes()
    _ = try! disabled.advanceTick()
    check("lifecycle off by default", !disabled.lifecycleEnabled && !disabled.reproductionEnabled)
    check("lifecycle gate off emits no lifecycle event", disabled.causalLedgerSnapshot().events
        .allSatisfy { !$0.kind.rawValue.hasPrefix("lifecycle")
            && !$0.kind.rawValue.hasPrefix("reproduction")
            && !$0.kind.rawValue.hasPrefix("birth")
            && $0.kind != .populationMemberBorn })
    check("lifecycle gate off checkpoint remains v4", try! disabled.makeCheckpoint().schemaVersion == 4)
    check("lifecycle gate off durable shape excludes lifecycle", !String(
        data: try! disabled.durableStateBytes(), encoding: .utf8
    )!.contains("lifecycleState"))
    check("lifecycle gate off only advances historical state", disabledBefore
        != (try! disabled.durableStateBytes()))

    var session = lifecycleSmokeBase("sim-lifecycle-reproduction")
    let cognitiveBefore = session.snapshot().agents.map {
        ($0.id, $0.ticksAlive, $0.observationCount, $0.actionCount)
    }
    try! session.setLifecycleEnabled(true)
    let initialized = session.lifecycleSnapshot()
    check("lifecycle initialization registers all founders", initialized.members.map(\.agentID.rawValue)
        == ["agent_0", "agent_1", "agent_2"])
    check("lifecycle founders mature at activation", initialized.members.allSatisfy {
        $0.origin == .bootstrapResident && $0.currentStage == .mature
            && (try? $0.age(at: 0)) == configuration.maturityAgeTicks
    })
    check("lifecycle activation leaves cognition unchanged", cognitiveBefore.elementsEqual(
        session.snapshot().agents.map { ($0.id, $0.ticksAlive, $0.observationCount, $0.actionCount) },
        by: ==
    ))
    check("lifecycle initialization causal chain", session.causalLedgerSnapshot().events
        .filter { $0.kind == .lifecycleMemberRegistered }.count == 3)
    check("lifecycle checkpoint uses v6", try! session.makeCheckpoint().schemaVersion == 6)
    check("lifecycle cannot be disabled after durable initialization", {
        do { try session.setLifecycleEnabled(false); return false }
        catch AgentSessionError.lifecycle(.unsafeDisable) { return true }
        catch { return false }
    }())

    try! session.setReproductionEnabled(true)
    check("reproduction explicit enable", session.reproductionEnabled)
    check("reproduction snapshot uses true eligibility", session.reproductionSnapshot()
        .eligiblePairs.first?.map(\.rawValue) == ["agent_0", "agent_1"])
    var permuted = lifecycleSmokeBase(
        "sim-lifecycle-reproduction",
        agentOrder: ["agent_2", "agent_0", "agent_1"]
    )
    try! permuted.setLifecycleEnabled(true)
    try! permuted.setReproductionEnabled(true)
    check("reproduction input order neutral before planning", try! permuted.durableStateBytes()
        == session.durableStateBytes())
    lifecycleAdvance(&session, to: 2)
    lifecycleAdvance(&permuted, to: 2)
    let plan = session.pendingBirthSitePlan()
        ?? session.lifecycleSnapshot().plans.first { $0.status == .planned }
    check("reproduction deterministic plan created", plan?.progenitorIDs.map(\.rawValue)
        == ["agent_0", "agent_1"] && plan?.createdTick == 2 && plan?.dueTick == 4)
    check("reproduction maximum one active plan", session.lifecycleSnapshot().plans
        .filter { $0.status == .planned }.count == 1)
    check("reproduction input order neutral plan bytes", try! permuted.durableStateBytes()
        == session.durableStateBytes())
    check("reproduction plan records planning context", plan?.populationAtPlanning == 3
        && plan?.pressureAtPlanning == .abundant)
    let midPlanCheckpoint = try! session.makeCheckpoint()
    let midPlanBytes = try! session.durableStateBytes()
    let midPlanRestored = try! AgentSimulationSession.restoring(midPlanCheckpoint)
    check("lifecycle v6 mid-plan restore exact", try! midPlanRestored.durableStateBytes()
        == midPlanBytes)
    check("lifecycle v6 mid-plan preserves due tick", midPlanRestored.lifecycleSnapshot()
        .plans.first?.dueTick == 4)

    lifecycleAdvance(&session, to: 4)
    let duePlan = session.pendingBirthSitePlan()!
    let preBirth = session.snapshot()
    let birthPosition = AgentPosition(x: 0, y: 64, z: 4)
    let record = try! session.applyBirthSiteObservation(AgentBirthSiteObservation(
        planID: duePlan.planID,
        observedTick: session.tick,
        position: birthPosition,
        candidateIndex: 0,
        worldFingerprint: 9_001
    ))!
    let postBirth = session.snapshot()
    let newborn = postBirth.agents.first { $0.id == record.newbornID.rawValue }!
    check("local birth consumes next population ordinal", record.newbornID.rawValue == "agent_3"
        && session.populationSummary().nextPopulationOrdinal == 4)
    check("local birth population three to four", preBirth.agentCount == 3
        && postBirth.agentCount == 4 && session.populationSummary().memberCount == 4)
    check("local birth creates resident without migration", session.populationSnapshot().members
        .contains { $0.agentID == record.newbornID && $0.status == .resident
            && $0.migrationID == nil })
    check("local birth newborn state exact", newborn.position == birthPosition
        && newborn.homePosition == birthPosition && newborn.health == 100
        && newborn.resourceInventory.isEmpty && newborn.ticksAlive == 0)
    check("local birth no birth-tick cognition", newborn.observationCount == 0
        && newborn.goalSelectionCount == 0 && newborn.actionCount == 0
        && newborn.actionEffectCount == 0 && newborn.movementCount == 0)
    check("local birth memory bounded", newborn.recentMemory.count == 1
        && newborn.recentMemory.first?.type == "local_birth")
    check("local birth lineage exactly two sorted", session.lifecycleSnapshot().members
        .first { $0.agentID == record.newbornID }?.progenitorIDs.map(\.rawValue)
        == ["agent_0", "agent_1"])
    check("local birth record causal order", record.siteValidatedEventID.sequence
        < record.populationBornEventID.sequence
        && record.populationBornEventID.sequence < record.finalizedEventID.sequence)
    check("local birth material conservation neutral", preBirth.conservation == postBirth.conservation
        && postBirth.conservation.balanced && session.ecologyConservationSnapshot().balanced)
    check("local birth plan completed", session.lifecycleSnapshot().plans.last?.status == .completed)
    check("local birth parent cooldown recorded", session.lifecycleSnapshot().members
        .filter { record.progenitorIDs.contains($0.agentID) }.allSatisfy {
            $0.completedBirthCount == 1 && $0.lastCompletedBirthTick == 4
        })
    check("local birth frame delta exact", session.lifecycleSnapshot().frames.last?.birthDelta == 1)

    let birthCheckpoint = try! session.makeCheckpoint()
    let birthBytes = try! session.durableStateBytes()
    let birthRestored = try! AgentSimulationSession.restoring(birthCheckpoint)
    check("lifecycle v6 post-birth restore exact", try! birthRestored.durableStateBytes() == birthBytes)
    check("lifecycle v6 post-birth no duplicate birth", birthRestored.lifecycleSummary().totalBirthCount == 1
        && birthRestored.populationSummary().nextPopulationOrdinal == 4)

    _ = try! session.advanceTick()
    let afterFirstCognition = session.snapshot().agents.first { $0.id == "agent_3" }!
    check("newborn first cognition is next tick", afterFirstCognition.ticksAlive == 1
        && afterFirstCognition.goalSelectionCount == 1
        && afterFirstCognition.actionCount == 1)
    lifecycleAdvance(&session, to: 6)
    check("newborn transitions to juvenile at age two", session.lifecycleSnapshot().members
        .first { $0.agentID.rawValue == "agent_3" }?.currentStage == .juvenile
        && (try! session.demographicAge(for: AgentID(rawValue: "agent_3")!)) == 2)
    lifecycleAdvance(&session, to: 12)
    check("juvenile transitions to mature at age eight", session.lifecycleSnapshot().members
        .first { $0.agentID.rawValue == "agent_3" }?.currentStage == .mature
        && (try! session.demographicAge(for: AgentID(rawValue: "agent_3")!)) == 8)
    check("ticksAlive remains separate from demographic age", try! session.state(for: "agent_3").ticksAlive == 8
        && (try! session.demographicAge(for: AgentID(rawValue: "agent_0")!)) == 20)
    check("reproduction cooldown prevents immediate second birth", session.lifecycleSummary().totalBirthCount == 1
        && session.lifecycleSummary().activePlanCount == 0)

    var adequate = lifecycleSmokeBase(
        "sim-lifecycle-adequate",
        hungerByID: ["agent_0": 0.5]
    )
    try! adequate.setLifecycleEnabled(true)
    try! adequate.setReproductionEnabled(true)
    lifecycleAdvance(&adequate, to: 2)
    check("reproduction adequate pressure permits plan", adequate.localEcologySummary().pressure == .adequate
        && adequate.pendingBirthSitePlan() == nil
        && adequate.lifecycleSnapshot().plans.first?.status == .planned)

    var scarce = lifecycleSmokeBase(
        "sim-lifecycle-scarce",
        hungerByID: ["agent_0": 0.5, "agent_1": 0.5, "agent_2": 0.5]
    )
    try! scarce.setLifecycleEnabled(true)
    try! scarce.setReproductionEnabled(true)
    lifecycleAdvance(&scarce, to: 2)
    check("reproduction scarce pressure blocks plan", scarce.localEcologySummary().pressure == .scarce
        && scarce.lifecycleSnapshot().plans.isEmpty)

    let depletedEcology = try! AgentLocalEcologyConfiguration(initialYield: 0)
    var critical = lifecycleSmokeBase(
        "sim-lifecycle-critical",
        hungerByID: ["agent_0": 0.8, "agent_1": 0.8, "agent_2": 0.8],
        ecologyConfiguration: depletedEcology
    )
    try! critical.setLifecycleEnabled(true)
    try! critical.setReproductionEnabled(true)
    lifecycleAdvance(&critical, to: 2)
    check("reproduction critical pressure blocks plan", critical.localEcologySummary().pressure == .critical
        && critical.lifecycleSnapshot().plans.isEmpty)

    var full = lifecycleSmokeBase(
        "sim-lifecycle-population-full",
        populationConfiguration: try! AgentPopulationConfiguration(maximumActivePopulation: 3)
    )
    try! full.setLifecycleEnabled(true)
    try! full.setReproductionEnabled(true)
    lifecycleAdvance(&full, to: 4)
    check("reproduction population full creates no plan", full.lifecycleSnapshot().plans.isEmpty
        && full.populationSummary().nextPopulationOrdinal == 3)

    var atomic = lifecycleSmokeBase("sim-lifecycle-atomic")
    try! atomic.setLifecycleEnabled(true)
    try! atomic.setReproductionEnabled(true)
    lifecycleAdvance(&atomic, to: 4)
    let atomicBefore = try! atomic.durableStateBytes()
    let wrongPlan = AgentReproductionPlanID(rawValue: "reproduction-plan-unknown")!
    let rejected: Bool
    do {
        _ = try atomic.applyBirthSiteObservation(AgentBirthSiteObservation(
            planID: wrongPlan,
            observedTick: atomic.tick,
            position: AgentPosition(x: 0, y: 64, z: 4),
            candidateIndex: 0,
            worldFingerprint: 1
        ))
        rejected = false
    } catch AgentSessionError.lifecycle(.invalidPlan("reproduction-plan-unknown")) {
        rejected = true
    } catch { rejected = false }
    check("reproduction invalid observation rejected", rejected)
    check("reproduction invalid observation atomic bytes", atomicBefore
        == (try! atomic.durableStateBytes()))

    var imported = lifecycleSmokeBase("sim-lifecycle-imported")
    try! imported.setLifecycleEnabled(true)
    _ = try! imported.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: AgentMigrationWorldObservation(
            worldTick: 0,
            candidateIndex: 0,
            entryPosition: AgentPosition(x: 1, y: 64, z: 3),
            receptionPosition: AgentPosition(x: 0, y: 64, z: 3),
            route: [AgentPosition(x: 1, y: 64, z: 3), AgentPosition(x: 0, y: 64, z: 3)]
        )
    )
    let importedMember = imported.lifecycleSnapshot().members.first {
        $0.agentID.rawValue == "agent_3"
    }
    check("lifecycle imported migrant mature", importedMember?.origin == .importedMigrant
        && importedMember?.currentStage == .mature
        && (try? importedMember!.age(at: imported.tick)) == configuration.maturityAgeTicks)
    check("reproduction excludes migrant in transit", !imported.reproductionSnapshot()
        .eligibleMatureResidentIDs.map(\.rawValue).contains("agent_3"))

    let liveSurvival = AgentSurvivalConfiguration.live
    let immediateStarvation = try! AgentSurvivalConfiguration(
        hungerPerTick: liveSurvival.hungerPerTick,
        fatiguePerTick: liveSurvival.fatiguePerTick,
        hungryThreshold: liveSurvival.hungryThreshold,
        criticalHungerThreshold: liveSurvival.criticalHungerThreshold,
        hungerRecoveryThreshold: liveSurvival.hungerRecoveryThreshold,
        fatigueThreshold: liveSurvival.fatigueThreshold,
        fatigueRecoveryThreshold: liveSurvival.fatigueRecoveryThreshold,
        foodNutrition: liveSurvival.foodNutrition,
        restRecoveryPerTick: liveSurvival.restRecoveryPerTick,
        starvationGraceTicks: 0,
        starvationDamagePerTick: liveSurvival.starvationDamagePerTick
    )
    let fourFoodEcology = try! AgentLocalEcologyConfiguration(
        patchCapacity: 4,
        initialYield: 4,
        regenerationQuantity: 1
    )
    var parentDeath = lifecycleSmokeBase(
        "sim-lifecycle-parent-death",
        hungerByID: ["agent_0": 0.74, "agent_1": 0.74],
        healthByID: ["agent_0": 10, "agent_1": 10],
        survivalConfiguration: immediateStarvation,
        ecologyConfiguration: fourFoodEcology
    )
    try! parentDeath.setLifecycleEnabled(true)
    try! parentDeath.setReproductionEnabled(true)
    lifecycleAdvance(&parentDeath, to: 2)
    let deathPlanID = parentDeath.lifecycleSnapshot().plans.first!.planID
    parentDeath.setSurvivalEnabled(true)
    try! parentDeath.setMortalityEnabled(true)
    _ = try! parentDeath.advanceTick()
    let deathPlan = parentDeath.lifecycleSnapshot().plans.first { $0.planID == deathPlanID }
    check("reproduction parent death cancels pending plan", deathPlan?.status == .cancelled
        && deathPlan?.reason == .parentDied && parentDeath.lifecycleSummary().totalBirthCount == 0)
    check("lifecycle one mature survivor remains safe", parentDeath.lifecycleSummary().matureCount == 1
        && parentDeath.reproductionSnapshot().eligiblePairs.isEmpty)
    check("reproduction parent death consumes no ordinal", parentDeath.populationSummary()
        .nextPopulationOrdinal == 3)

    var lineage = lifecycleSmokeBase("sim-lifecycle-lineage")
    try! lineage.setLifecycleEnabled(true)
    try! lineage.setReproductionEnabled(true)
    lifecycleAdvance(&lineage, to: 4)
    _ = lifecycleResolveBirth(&lineage, position: AgentPosition(x: 0, y: 64, z: 4))
    lifecycleAdvance(&lineage, to: 22)
    _ = lifecycleResolveBirth(&lineage, position: AgentPosition(x: 1, y: 64, z: 4))
    lifecycleAdvance(&lineage, to: 40)
    _ = lifecycleResolveBirth(&lineage, position: AgentPosition(x: -1, y: 64, z: 4))
    lifecycleAdvance(&lineage, to: 47)
    try! lineage.setReproductionEnabled(false)
    lifecycleAdvance(&lineage, to: 48)
    let lineagePairs = Set(lineage.reproductionSnapshot().eligiblePairs.map {
        $0.map(\.rawValue).joined(separator: "+")
    })
    check("reproduction excludes direct parent child", !lineagePairs.contains("agent_0+agent_3")
        && !lineagePairs.contains("agent_2+agent_4"))
    check("reproduction excludes siblings", !lineagePairs.contains("agent_3+agent_5"))
    check("reproduction retains unrelated pair", lineagePairs.contains("agent_1+agent_2"))
    check("lineage creates no implicit social relation", lineage.socialSnapshot().facts.isEmpty
        && lineage.socialSnapshot().trustRelations.isEmpty)

    var replayBase = lifecycleSmokeBase("sim-lifecycle-replay")
    let v4Checkpoint = try! replayBase.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(checkpoint: v4Checkpoint, session: replayBase)
    _ = try! recorder.apply(
        .setLifecycleEnabled(true, configuration: .live), to: &replayBase
    )
    _ = try! recorder.apply(.setReproductionEnabled(true), to: &replayBase)
    _ = try! recorder.apply(
        .advanceTick(perceptions: [], physicalObservations: []), to: &replayBase
    )
    _ = try! recorder.apply(
        .advanceTick(perceptions: [], physicalObservations: []), to: &replayBase
    )
    _ = try! recorder.apply(
        .advanceTick(perceptions: [], physicalObservations: []), to: &replayBase
    )
    _ = try! recorder.apply(
        .advanceTick(perceptions: [], physicalObservations: []), to: &replayBase
    )
    let replayPlan = replayBase.pendingBirthSitePlan()!
    _ = try! recorder.apply(.applyBirthSiteObservation(AgentBirthSiteObservation(
        planID: replayPlan.planID,
        observedTick: replayBase.tick,
        position: birthPosition,
        candidateIndex: 0,
        worldFingerprint: 9_001
    )), to: &replayBase)
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "lifecycle-reproduction")!
    )
    let replayed = try! AgentSessionReplayer.replay(
        checkpoint: v4Checkpoint, journal: journal
    )
    check("lifecycle replay schema v6", journal.manifest.schemaVersion == 6)
    check("lifecycle replay verified", replayed.report.verified)
    check("lifecycle replay durable bytes exact", try! replayBase.durableStateBytes()
        == replayed.session.durableStateBytes())
    check("lifecycle replay birth identity exact", replayed.session.lifecycleSummary().latestNewbornID?.rawValue
        == "agent_3")
    check("lifecycle replay causal digest exact", replayBase.causalLedgerSnapshot().summary.digest
        == replayed.session.causalLedgerSnapshot().summary.digest)
}
