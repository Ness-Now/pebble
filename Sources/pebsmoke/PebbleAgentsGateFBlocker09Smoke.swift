import Foundation
import PebbleAgents

private let gateFB09Origin = AgentPosition(x: 0, y: 64, z: 0)
private let gateFB09BirthPosition = AgentPosition(x: 1, y: 64, z: 4)
private let gateFB09EastID = AgentSettlementID(rawValue: "settlement-east")!
private let gateFB09Habitats = (0..<3).map { ordinal in
    AgentEcologyHabitatObservation(
        worldTick: 0, candidateIndex: ordinal,
        habitatPosition: AgentPosition(x: ordinal * 2 + 1, y: 63, z: 0),
        foragePosition: AgentPosition(x: ordinal * 2 + 1, y: 64, z: 0),
        habitatFingerprint: 90_032 + ordinal,
        distanceFromSettlement: ordinal * 2 + 1,
        directionIndex: ordinal, worldReadCount: 4
    )
}

private func gateFB09Founder(_ ordinal: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: ordinal * 2, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0.1, safety: 1),
        health: 100, fear: 0, homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "Gate F Blocker 09 public fixture",
            startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [],
        tickCreated: 0, ticksAlive: 0, observationCount: 0,
        nearbyObservationCount: 0, goalSelectionCount: 0,
        goalChangeCount: 0, actionCount: 0, actionEffectCount: 0,
        movementCount: 0, totalManhattanDistanceMoved: 0,
        returnHomeMoveCount: 0, totalDistanceReducedTowardHome: 0,
        survivalProgress: AgentSurvivalProgress()
    )
}

private func gateFB09Session(
    _ simulationID: String,
    hungerPerTick: Double = 0.45,
    causalMaximumEvents: Int = 65_536,
    founderCount: Int = 3,
    includeScale: Bool = true
) -> AgentSimulationSession {
    let survival = try! AgentSurvivalConfiguration(
        hungerPerTick: hungerPerTick, fatiguePerTick: 0.001,
        hungryThreshold: 0.4, criticalHungerThreshold: 0.9,
        hungerRecoveryThreshold: 0.15, fatigueThreshold: 0.65,
        fatigueRecoveryThreshold: 0.2, foodNutrition: 1,
        restRecoveryPerTick: 1, starvationGraceTicks: 0,
        starvationDamagePerTick: 100
    )
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 909, nearbyRadius: 8, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 128),
            survivalConfiguration: survival
        ),
        agents: (0..<founderCount).map(gateFB09Founder),
        simulationID: try! AgentSimulationID(validating: simulationID),
        causalLedgerPolicy: .bounded(maxEvents: causalMaximumEvents)
    )
    session.setSurvivalEnabled(true)
    try! session.initializePopulationRegistry(
        settlementAnchor: gateFB09Origin,
        receptionPosition: gateFB09Origin,
        configuration: try! AgentPopulationConfiguration(
            maximumActivePopulation: founderCount + 2,
            maximumMigrationRecords: 16
        )
    )
    try! session.initializeLocalEcology(
        observations: Array(gateFB09Habitats.prefix(founderCount)),
        configuration: try! AgentLocalEcologyConfiguration(
            maximumPatches: founderCount, maximumHabitatCandidates: 8,
            observationRadius: 8, patchCapacity: 4, initialYield: 4,
            regenerationIntervalTicks: 8, regenerationQuantity: 1,
            maximumForageIntentsPerTick: 8, maximumForageHistory: 64,
            maximumPressureFrames: 32, maximumHabitatReadsPerScan: 64
        )
    )
    _ = try! session.applyLocalEcologyEndOfTick(
        habitatValidations: Array(gateFB09Habitats.prefix(founderCount))
    )
    try! session.setLifecycleEnabled(
        true,
        configuration: try! AgentLifecycleConfiguration(
            newbornDurationTicks: 1, maturityAgeTicks: 2,
            reproductionEvaluationIntervalTicks: 1,
            reproductionPlanDelayTicks: 1,
            reproductionCooldownTicks: 1,
            maximumRetainedBirthRecords: 64,
            maximumRetainedPlanRecords: 64,
            maximumParentBirthCount: 16
        )
    )
    try! session.setKinshipEnabled(true)
    try! session.setHouseholdsEnabled(true)
    if includeScale {
        try! session.initializePopulationScaling(
            additionalSettlements: [AgentPopulationSettlement(
                settlementID: gateFB09EastID,
                anchor: AgentPosition(x: 16, y: 64, z: 0),
                receptionPosition: AgentPosition(x: 16, y: 64, z: 0),
                capacity: 2, residentIDs: [], inTransitIDs: []
            )],
            configuration: try! AgentPopulationScaleConfiguration(
                maximumSettlements: 2,
                maximumLiveAgents: founderCount + 2,
                maximumNearAgents: 2, nearMaintenanceCadence: 2,
                dormantMaintenanceCadence: 8, rotationIntervalTicks: 4,
                maximumFidelityTransitionHistory: 32,
                maximumSettlementMigrationHistory: 8,
                maximumConcurrentSettlementMigrations: 1,
                maximumSettlementMigrationRouteLength: 32
            )
        )
    }
    try! session.setDependentCareEnabled(true)
    try! session.setChildhoodV2Enabled(true)
    try! session.setFamilyV1Enabled(true)
    try! session.setMaterialRightsEnabled(true)
    try! session.setMortalityEnabled(true, configuration: .embodiedLive)
    try! session.setEstatesEnabled(true)
    try! session.setReproductionEnabled(true)
    return session
}

private func gateFB09Birth(
    _ session: inout AgentSimulationSession,
    plan: AgentReproductionPlan,
    fingerprint: Int
) -> AgentBirthRecord {
    let record = try! session.applyBirthSiteObservation(AgentBirthSiteObservation(
        planID: plan.planID, observedTick: session.tick,
        position: gateFB09BirthPosition, candidateIndex: 0,
        worldFingerprint: fingerprint
    ))
    guard let record else {
        preconditionFailure(
            "birth cancelled tick=\(session.tick) plan=\(plan.planID.rawValue) "
                + "reproduction=\(session.reproductionSnapshot())"
        )
    }
    return record
}

private struct GateFB09BoundaryFixture {
    var session: AgentSimulationSession
    let firstBirth: AgentBirthRecord
    let laterPlan: AgentReproductionPlan
    let founderCount: Int
}

private func gateFB09FeedFounders(
    _ session: inout AgentSimulationSession,
    founderCount: Int = 3,
    ordinals: [Int]? = nil
) {
    let selected = ordinals ?? Array(0..<founderCount)
    let intents = selected.compactMap { ordinal -> AgentForageIntent? in
        let id = "agent_\(ordinal)"
        guard session.snapshot().agents.contains(where: { $0.id == id }) else {
            return nil
        }
        let habitat = gateFB09Habitats[ordinal]
        return AgentForageIntent(
            forageID: "\(session.simulationID.rawValue)-forage-\(id)-t\(session.tick)",
            patchID: habitat.patchID,
            agentID: AgentID(rawValue: id)!, tick: session.tick,
            target: habitat.foragePosition, observedAtTick: session.tick,
            expectedHabitatFingerprint: habitat.habitatFingerprint
        )
    }
    let outcomes = try! session.applyForageIntents(
        intents,
        habitatValidations: Array(gateFB09Habitats.prefix(founderCount))
    )
    precondition(outcomes.allSatisfy { $0.status == .succeeded })
    for ordinal in selected {
        let id = "agent_\(ordinal)"
        _ = try! session.consumeFood(AgentConsumptionIntent(
            consumptionId: "\(session.simulationID.rawValue)-feed-\(id)-t\(session.tick)",
            agentId: id, tick: session.tick,
            resource: .foodRaw, quantity: 1
        ))
    }
}

private func gateFB09BoundaryFixture(
    _ simulationID: String,
    hungerPerTick: Double = 0.45,
    causalMaximumEvents: Int = 65_536,
    founderCount: Int = 3,
    includeScale: Bool = true
) -> GateFB09BoundaryFixture {
    var session = gateFB09Session(
        simulationID,
        hungerPerTick: hungerPerTick,
        causalMaximumEvents: causalMaximumEvents,
        founderCount: founderCount,
        includeScale: includeScale
    )
    while session.pendingBirthSitePlan() == nil {
        _ = try! session.advanceTick()
        gateFB09FeedFounders(&session, founderCount: founderCount)
    }
    let firstPlan = session.pendingBirthSitePlan()!
    let firstBirth = gateFB09Birth(
        &session, plan: firstPlan, fingerprint: 90_001
    )
    while session.tick < 4 {
        _ = try! session.advanceTick()
        if session.tick < 4 {
            gateFB09FeedFounders(&session, founderCount: founderCount)
        }
    }
    let laterPlan = session.pendingBirthSitePlan()!
    precondition(firstBirth.newbornID
        == AgentID(rawValue: "agent_\(founderCount)")!)
    let expectedLaterParents = founderCount == 2
        ? [AgentID(rawValue: "agent_0")!, AgentID(rawValue: "agent_1")!]
        : [AgentID(rawValue: "agent_0")!, AgentID(rawValue: "agent_2")!]
    precondition(laterPlan.progenitorIDs == expectedLaterParents)
    precondition(session.pendingMortalityTransitions().contains {
        $0.agentID == firstBirth.newbornID
    })
    return GateFB09BoundaryFixture(
        session: session, firstBirth: firstBirth, laterPlan: laterPlan,
        founderCount: founderCount
    )
}

private func gateFB09FullSiblingBoundaryFixture(
    _ simulationID: String
) -> GateFB09BoundaryFixture {
    var session = gateFB09Session(simulationID)
    while session.pendingBirthSitePlan() == nil {
        _ = try! session.advanceTick()
        gateFB09FeedFounders(&session)
    }
    let firstPlan = session.pendingBirthSitePlan()!
    let firstBirth = gateFB09Birth(
        &session, plan: firstPlan, fingerprint: 90_019
    )
    let migrantID = AgentID(rawValue: "agent_2")!
    let migrantHabitat = gateFB09Habitats[2]
    let extraForage = try! session.applyForageIntents([
        AgentForageIntent(
            forageID: "\(simulationID)-migration-food",
            patchID: migrantHabitat.patchID,
            agentID: migrantID, tick: session.tick,
            target: migrantHabitat.foragePosition,
            observedAtTick: session.tick,
            expectedHabitatFingerprint: migrantHabitat.habitatFingerprint
        ),
    ], habitatValidations: gateFB09Habitats)
    precondition(extraForage.first?.status == .succeeded)
    _ = try! session.beginSettlementMigration(
        agentID: migrantID,
        destinationSettlementID: gateFB09EastID,
        verifiedRoute: (4...16).map {
            AgentPosition(x: $0, y: 64, z: 0)
        }
    )
    _ = try! session.advanceTick()
    gateFB09FeedFounders(&session, ordinals: [0, 1])
    _ = try! session.consumeFood(AgentConsumptionIntent(
        consumptionId: "\(simulationID)-migrant-feed-t\(session.tick)",
        agentId: migrantID.rawValue, tick: session.tick,
        resource: .foodRaw, quantity: 1
    ))
    _ = try! session.advanceTick()
    let laterPlan = session.pendingBirthSitePlan()!
    precondition(laterPlan.progenitorIDs == [
        AgentID(rawValue: "agent_0")!, AgentID(rawValue: "agent_1")!,
    ])
    precondition(session.pendingMortalityTransitions().contains {
        $0.agentID == firstBirth.newbornID
    })
    return GateFB09BoundaryFixture(
        session: session, firstBirth: firstBirth, laterPlan: laterPlan,
        founderCount: 3
    )
}

private struct GateFB09MortalityAuditResult {
    let tick: Int
    let estatePlanSequence: UInt64
    let laterPendingSequence: UInt64
    let laterCustodySequence: UInt64
    let laterLethalSequence: UInt64
    let laterDeathFinalSequence: UInt64
    let pendingParentEligibleAtPlan: Bool
    let selectedTier: AgentEstateBeneficiaryTier
    let beneficiaryIDs: [AgentID]
    let earlierProofImmutable: Bool
    let finalizationSucceededExactlyOnce: Bool
    let continuationWithoutReplay: Bool
    let checkpointRemainsExact: Bool
}

private func gateFB09PendingSuccessorFixture(
    _ simulationID: String,
    fingerprint: Int,
    causalMaximumEvents: Int = 65_536
) -> (
    session: AgentSimulationSession,
    firstBirth: AgentBirthRecord,
    pendingParent: AgentID,
    childEstate: AgentEstateRecord
) {
    var session = gateFB09Session(
        simulationID, causalMaximumEvents: causalMaximumEvents
    )
    while session.pendingBirthSitePlan() == nil {
        _ = try! session.advanceTick()
        gateFB09FeedFounders(&session)
    }
    let firstBirth = gateFB09Birth(
        &session, plan: session.pendingBirthSitePlan()!,
        fingerprint: fingerprint
    )
    _ = try! session.advanceTick()
    gateFB09FeedFounders(&session, ordinals: [1, 2])
    _ = try! session.advanceTick()
    let parent = AgentID(rawValue: "agent_0")!
    precondition(session.pendingMortalityTransitions().contains {
        $0.agentID == firstBirth.newbornID
    })
    precondition(session.pendingMortalityTransitions().contains {
        $0.agentID == parent
    })
    _ = gateFB09ResolveEmptyCustody(
        &session, agentID: firstBirth.newbornID
    )
    _ = try! session.finalizePendingMortality(for: firstBirth.newbornID)
    return (
        session, firstBirth, parent,
        gateFB09Estate(session, decedentID: firstBirth.newbornID)
    )
}

private func gateFB09MortalityEligibilityAudit()
    -> GateFB09MortalityAuditResult
{
    let fixture = gateFB09PendingSuccessorFixture(
        "gate-f-b09-mortality-audit", fingerprint: 90_060
    )
    var session = fixture.session
    let firstBirth = fixture.firstBirth
    let parent = fixture.pendingParent
    let childEstate = fixture.childEstate
    let parentPending = session.pendingMortalityTransitions().first {
        $0.agentID == parent
    }!
    let custody = gateFB09ResolveEmptyCustody(&session, agentID: parent)
    let childProof = childEstate.successorPlanProof!
    let parentDeath = try! session.finalizePendingMortality(for: parent)
    let proofAfter = gateFB09Estate(
        session, decedentID: firstBirth.newbornID
    ).successorPlanProof!
    let deathsAfter = session.mortalitySnapshot().totalDeathCount
    let estatesAfter = session.estateSnapshot().totalEstateCount
    let restored = gateFB09RestoreExact(session)
    var continuationWithoutReplay = false
    if var continued = restored {
        gateFB09FeedFounders(&continued, ordinals: [1, 2])
        _ = try! continued.advanceTick()
        continuationWithoutReplay =
            continued.mortalitySnapshot().totalDeathCount == deathsAfter
            && continued.estateSnapshot().totalEstateCount == estatesAfter
    }
    return GateFB09MortalityAuditResult(
        tick: session.tick,
        estatePlanSequence:
            childEstate.successorPlanEventID.sequence.rawValue,
        laterPendingSequence:
            parentPending.pendingEventID.sequence.rawValue,
        laterCustodySequence: custody.eventID.sequence.rawValue,
        laterLethalSequence:
            parentDeath.lethalDamageEventID.sequence.rawValue,
        laterDeathFinalSequence:
            parentDeath.deathEventID.sequence.rawValue,
        pendingParentEligibleAtPlan:
            childProof.eligibilityRows.first {
                $0.agentID == parent
            }?.eligibleAtDeath ?? true,
        selectedTier: childProof.selectedTier,
        beneficiaryIDs: childEstate.beneficiaries.map(\.agentID),
        earlierProofImmutable: childProof == proofAfter,
        finalizationSucceededExactlyOnce:
            deathsAfter == 2 && estatesAfter == 2
                && !session.pendingMortalityTransitions().contains {
                    $0.agentID == parent
                },
        continuationWithoutReplay: continuationWithoutReplay,
        checkpointRemainsExact: restored != nil
    )
}

private func gateFB09FinalizedBeforePlanAudit()
    -> (Bool, UInt64, UInt64, Bool, Bool)
{
    var session = gateFB09Session("gate-f-b09-finalized-before-plan")
    while session.pendingBirthSitePlan() == nil {
        _ = try! session.advanceTick()
        gateFB09FeedFounders(&session)
    }
    let firstBirth = gateFB09Birth(
        &session, plan: session.pendingBirthSitePlan()!, fingerprint: 90_061
    )
    _ = try! session.advanceTick()
    gateFB09FeedFounders(&session, ordinals: [1, 2])
    _ = try! session.advanceTick()
    let parent = AgentID(rawValue: "agent_0")!
    _ = gateFB09ResolveEmptyCustody(&session, agentID: parent)
    let parentDeath = try! session.finalizePendingMortality(for: parent)
    _ = gateFB09ResolveEmptyCustody(
        &session, agentID: firstBirth.newbornID
    )
    _ = try! session.finalizePendingMortality(for: firstBirth.newbornID)
    let childEstate = gateFB09Estate(
        session, decedentID: firstBirth.newbornID
    )
    let parentRow = childEstate.successorPlanProof?.eligibilityRows.first {
        $0.agentID == parent
    }
    let childRow = gateFB09Estate(
        session, decedentID: parent
    ).successorPlanProof?.eligibilityRows.first {
        $0.agentID == firstBirth.newbornID
    }
    return (
        parentDeath.deathEventID.sequence
            < childEstate.successorPlanEventID.sequence,
        parentDeath.deathEventID.sequence.rawValue,
        childEstate.successorPlanEventID.sequence.rawValue,
        parentRow?.eligibleAtDeath == false
            && childRow?.eligibleAtDeath == false,
        gateFB09RestoreExact(session) != nil
    )
}

private func gateFB09LaterTickMortalityAudit()
    -> (Bool, UInt64, UInt64, UInt64, Bool, Bool)
{
    var fixture = gateFB09BoundaryFixture(
        "gate-f-b09-later-mortality"
    )
    _ = gateFB09ResolveEmptyCustody(
        &fixture.session, agentID: fixture.firstBirth.newbornID
    )
    _ = try! fixture.session.finalizePendingMortality(
        for: fixture.firstBirth.newbornID
    )
    let parent = AgentID(rawValue: "agent_0")!
    let proofBefore = gateFB09Estate(
        fixture.session, decedentID: fixture.firstBirth.newbornID
    ).successorPlanProof!
    gateFB09FeedFounders(&fixture.session, ordinals: [1, 2])
    _ = try! fixture.session.advanceTick()
    let pending = fixture.session.pendingMortalityTransitions().first {
        $0.agentID == parent
    }!
    _ = gateFB09ResolveEmptyCustody(&fixture.session, agentID: parent)
    let death = try! fixture.session.finalizePendingMortality(for: parent)
    let proofAfter = gateFB09Estate(
        fixture.session, decedentID: fixture.firstBirth.newbornID
    ).successorPlanProof!
    return (
        proofBefore.successorPlanEventID.sequence < pending.pendingEventID.sequence,
        proofBefore.successorPlanEventID.sequence.rawValue,
        pending.pendingEventID.sequence.rawValue,
        death.deathEventID.sequence.rawValue,
        proofBefore.eligibilityRows.first {
            $0.agentID == parent
        }?.eligibleAtDeath == true && proofBefore == proofAfter,
        gateFB09RestoreExact(fixture.session) != nil
    )
}

private func gateFB09MortalityCompactionAudit() -> Bool {
    let fixture = gateFB09PendingSuccessorFixture(
        "gate-f-b09-mortality-compaction", fingerprint: 90_063,
        causalMaximumEvents: 32
    )
    var session = fixture.session
    let proof = fixture.childEstate.successorPlanProof!
    let pending = session.pendingMortalityTransitions().first {
        $0.agentID == fixture.pendingParent
    }!
    while session.causalLedgerSnapshot().summary.droppedEventCount
            < proof.successorPlanEventID.sequence.rawValue {
        try! session.setReproductionEnabled(!session.reproductionEnabled)
    }
    _ = gateFB09ResolveEmptyCustody(
        &session, agentID: fixture.pendingParent
    )
    let death = try! session.finalizePendingMortality(
        for: fixture.pendingParent
    )
    while session.causalLedgerSnapshot().summary.droppedEventCount
            < death.deathEventID.sequence.rawValue {
        try! session.setReproductionEnabled(!session.reproductionEnabled)
    }
    let ledger = session.causalLedgerSnapshot()
    let restored = gateFB09RestoreExact(session)
    return !ledger.events.contains {
        $0.eventID == pending.pendingEventID
            || $0.eventID == proof.successorPlanEventID
            || $0.eventID == death.lethalDamageEventID
            || $0.eventID == death.deathEventID
    } && restored.map {
        gateFB09Estate(
            $0, decedentID: fixture.firstBirth.newbornID
        ).successorPlanProof == proof
            && gateFB09Estate(
                $0, decedentID: fixture.firstBirth.newbornID
            ).successorPlanProof?.eligibilityRows.first {
                $0.agentID == fixture.pendingParent
            }?.eligibleAtDeath == false
            && $0.mortalitySnapshot().totalDeathCount == 2
            && $0.estateSnapshot().totalEstateCount == 2
    } == true
}

@discardableResult
private func gateFB09ResolveEmptyCustody(
    _ session: inout AgentSimulationSession,
    agentID: AgentID
) -> AgentMortalityPhysicalCustodyResolution {
    try! session.applyMortalityPhysicalCustodyOutcome(
        AgentMortalityPhysicalCustodyOutcome(
            operationID: "\(session.simulationID.rawValue)-empty-custody-\(agentID.rawValue)-t\(session.tick)",
            terminalAgentID: agentID,
            kind: .verifiedEmpty,
            physicalReceiptID: "\(session.simulationID.rawValue)-empty-exit-\(agentID.rawValue)-t\(session.tick)",
            destinationHolderID: nil,
            stackCount: 0, itemCount: 0, physicalAssets: [],
            verifiedAtTick: session.tick
        )
    )
}

private func gateFB09Estate(
    _ session: AgentSimulationSession,
    decedentID: AgentID
) -> AgentEstateRecord {
    session.estateSnapshot().estates.first {
        $0.decedentID == decedentID
    }!
}

private func gateFB09Parentage(
    _ session: AgentSimulationSession,
    childID: AgentID
) -> AgentParentageRecord {
    session.kinshipSnapshot().parentageRecords.first {
        $0.childID == childID
    }!
}

private func gateFB09RestoreExact(
    _ session: AgentSimulationSession
) -> AgentSimulationSession? {
    do {
        let checkpoint = try session.makeCheckpoint()
        let bytes = try AgentCheckpointCodec.encode(checkpoint)
        let restored = try AgentSimulationSession.restoring(
            AgentCheckpointCodec.decode(
                AgentSessionCheckpoint.self, from: bytes
            )
        )
        return try restored.durableStateBytes()
            == session.durableStateBytes() ? restored : nil
    } catch {
        return nil
    }
}

private func gateFB09CurrentAuthorityIsSingular(
    _ session: AgentSimulationSession
) -> Bool {
    let agents = session.snapshot().agents
    let population = session.populationSnapshot().members
    let lifecycle = session.lifecycleSnapshot().members
    let fidelity = session.populationScaleSnapshot().fidelityRecords
    let households = session.householdSnapshot().membershipPeriods
    return agents.allSatisfy { state in
        let id = AgentID(rawValue: state.id)!
        return population.filter { $0.agentID == id }.count == 1
            && lifecycle.filter { $0.agentID == id }.count == 1
            && fidelity.filter { $0.agentID == id }.count == 1
            && households.filter {
                $0.agentID == id && $0.leftTick == nil
            }.count == 1
    }
}

private func gateFB09PlanDigest(
    _ proof: AgentEstateSuccessorPlanProof
) -> String {
    let rows = proof.eligibilityRows.map {
        "\($0.agentID.rawValue):\($0.tier.rawValue):"
            + "\($0.basis.rawValue):\($0.eligibleAtDeath ? 1 : 0):"
            + "\($0.lifeStageAtPlan?.rawValue ?? "none"):"
            + "\($0.guardianIDAtPlan?.rawValue ?? "none")"
    }.joined(separator: ",")
    let union = proof.activeUnionAtDeath.map {
        "\($0.unionID.rawValue):\($0.partnerID.rawValue):"
            + "\($0.activationTick):\($0.activationEventID.rawValue)"
    } ?? "none"
    let text = "successor-plan-v\(proof.version)|\(proof.estateID.rawValue)|"
        + "\(proof.decedentID.rawValue)|\(proof.deathID.rawValue)|"
        + "\(proof.deathBoundaryTick)|\(proof.selectedTier.rawValue)|"
        + "\(rows)|\(union)"
    return AgentMortalityDigest.make("estate-v1|\(text)")
}

private func gateFB09EstateRollingDigest(
    _ authority: AgentEstateState
) -> String {
    let estates = authority.estates.sorted {
        $0.estateID < $1.estateID
    }.map { estate in
        let administrations = estate.administrations.map {
            "\($0.administratorID.rawValue):\($0.basis.rawValue):"
                + "\($0.status.rawValue):"
                + "\($0.acceptanceOperationID ?? "none")"
        }.joined(separator: ",")
        let beneficiaries = estate.beneficiaries.map {
            "\($0.agentID.rawValue):\($0.basis.rawValue):"
                + "\($0.allocationCount)"
        }.joined(separator: ",")
        let assets = estate.assets.map {
            let base = "\($0.entryID.rawValue):"
                + "\($0.materialRightsAssetID?.rawValue ?? "none"):"
                + "\($0.quantity):\($0.status.rawValue):"
                + "\($0.blockReason?.rawValue ?? "none"):"
                + "\($0.settlementReceiptID ?? "none")"
            if let eventID = $0.custodyRevalidationEventID {
                return base + ":custody:"
                    + "\($0.custodyRevalidatedAtTick ?? -1):"
                    + eventID.rawValue + ":"
                    + "\($0.intendedCustodianID?.rawValue ?? "none")"
            }
            return base
        }.joined(separator: ",")
        let prefix = "\(estate.estateID.rawValue)|"
            + "\(estate.deathID.rawValue)|\(estate.status.rawValue)|"
        if let proof = estate.successorPlanProof {
            return prefix + "\(proof.version):\(proof.planDigest):"
                + "\(proof.successorPlanEventID.rawValue)|"
                + "\(administrations)|\(beneficiaries)|\(assets)"
        }
        return prefix + "\(administrations)|\(beneficiaries)|\(assets)"
    }.joined(separator: ";")
    let text = "\(authority.activationTick)|"
        + "\(authority.activationDeathCount)|\(authority.totalEstateCount)|"
        + "\(authority.totalSettlementCount)|"
        + "\(authority.evictionCounts.settledEstates)|\(estates)|"
        + "\(authority.processedOperationIDs.joined(separator: ","))"
    return AgentMortalityDigest.make("estate-v1|\(text)")
}

private func gateFB09MutatedCheckpoint(
    _ checkpoint: AgentSessionCheckpoint,
    refreshEstateDigests: Bool = true,
    mutate: (inout [String: Any]) -> Void
) -> AgentSessionCheckpoint {
    var root = try! JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(checkpoint)
    ) as! [String: Any]
    var durable = root["durableState"] as! [String: Any]
    mutate(&durable)
    if refreshEstateDigests,
       var estateJSON = durable["estateState"] as? [String: Any] {
        var estates = estateJSON["estates"] as! [[String: Any]]
        for index in estates.indices {
            guard var proofJSON = estates[index]["successorPlanProof"]
                as? [String: Any] else { continue }
            let proofBytes = try! JSONSerialization.data(
                withJSONObject: proofJSON,
                options: [.sortedKeys, .withoutEscapingSlashes]
            )
            let proof = try! AgentCheckpointCodec.decode(
                AgentEstateSuccessorPlanProof.self, from: proofBytes
            )
            proofJSON["planDigest"] = gateFB09PlanDigest(proof)
            estates[index]["successorPlanProof"] = proofJSON
        }
        estateJSON["estates"] = estates
        let estateBytes = try! JSONSerialization.data(
            withJSONObject: estateJSON,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
        let estate = try! AgentCheckpointCodec.decode(
            AgentEstateState.self, from: estateBytes
        )
        estateJSON["rollingDigest"] = gateFB09EstateRollingDigest(estate)
        durable["estateState"] = estateJSON
    }
    let mutationBytes = try! JSONSerialization.data(
        withJSONObject: durable,
        options: [.sortedKeys, .withoutEscapingSlashes]
    )
    let state = try! AgentCheckpointCodec.decode(
        AgentSessionDurableState.self, from: mutationBytes
    )
    let durableBytes = try! AgentCheckpointCodec.encode(state)
    let canonical = try! JSONSerialization.jsonObject(
        with: durableBytes
    ) as! [String: Any]
    let clock = canonical["clock"] as! [String: Any]
    let simulationID = clock["simulationID"] as! String
    let tick = clock["tick"] as! Int
    let digest = AgentCheckpointDigest.sha256(durableBytes)
    let simulationDigest = AgentCheckpointDigest.sha256(
        Data(simulationID.utf8)
    )
    root["durableState"] = canonical
    root["schemaVersion"] = canonical["schemaVersion"]
    root["semanticDigest"] = digest.rawValue
    root["checkpointID"] =
        "checkpoint-\(simulationDigest.rawValue.prefix(12))"
            + "-t\(tick)-\(digest.rawValue.prefix(16))"
    return try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self,
        from: JSONSerialization.data(
            withJSONObject: root,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
    )
}

private func gateFB09RestoreError(
    _ checkpoint: AgentSessionCheckpoint
) -> String? {
    do {
        _ = try AgentSimulationSession.restoring(checkpoint)
        return nil
    } catch {
        return String(describing: error)
    }
}

private struct GateFB09FreshReport: Codable, Equatable {
    let schemaVersion: Int
    let phase: String
    let tick: Int
    let checkpointSchema: Int
    let observerSchema: Int
    let checkpointBytes: Int
    let durableBytes: Int
    let checkpointSHA256: String
    let durableSHA256: String
    let estatePlanSequence: UInt64
    let laterBirthSequence: UInt64?
    let laterParentageSequence: UInt64?
    let currentSiblingRelation: String
    let historicalLaterSiblingRows: Int
    let replayedDeaths: Int
    let replayedEstates: Int
    let duplicateCurrentAuthority: Int
    let observerMutationCount: Int
    let assertions: [String: Bool]
}

private func gateFB09WriteJSON<T: Encodable>(
    _ value: T, to url: URL
) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [
        .prettyPrinted, .sortedKeys, .withoutEscapingSlashes,
    ]
    try encoder.encode(value).write(to: url, options: .atomic)
}

private struct GateFB09MortalityFreshReport: Codable, Equatable {
    let schemaVersion: Int
    let phase: String
    let tick: Int
    let checkpointSchema: Int
    let observerSchema: Int
    let checkpointBytes: Int
    let durableBytes: Int
    let checkpointSHA256: String
    let durableSHA256: String
    let pendingSequence: UInt64
    let estatePlanSequence: UInt64
    let lethalSequence: UInt64?
    let deathFinalSequence: UInt64?
    let pendingParentEligibleAtPlan: Bool
    let deathCount: Int
    let estateCount: Int
    let replayedDeaths: Int
    let replayedEstates: Int
    let duplicateCurrentAuthority: Int
    let observerMutationCount: Int
    let assertions: [String: Bool]
}

private struct GateFB09CompatibilityReport: Codable, Equatable {
    let schemaVersion: Int
    let sourceCheckpoint: String
    let checkpointSchema: Int
    let observerSchema: Int
    let checkpointBytes: Int
    let checkpointSHA256: String
    let durableSHA256: String
    let deathCount: Int
    let estateCount: Int
    let compactedDeathCount: Int
    let replayedDeaths: Int
    let replayedEstates: Int
    let duplicateCurrentAuthority: Int
    let observerMutationCount: Int
    let assertions: [String: Bool]
}

private func gateFB09CompatibilityReaderIfRequested() -> Bool {
    let environment = ProcessInfo.processInfo.environment
    guard let source = environment[
        "PEBBLELAB_GATE_F_BLOCKER_09_COMPAT_CHECKPOINT"
    ] else { return false }
    guard let output = environment[
        "PEBBLELAB_GATE_F_BLOCKER_09_COMPAT_REPORT"
    ] else {
        preconditionFailure("missing Blocker 09 compatibility report path")
    }
    let sourceURL = URL(fileURLWithPath: source)
    let checkpointBytes = try! Data(contentsOf: sourceURL)
    let checkpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self, from: checkpointBytes
    )
    var session = try! AgentSimulationSession.restoring(checkpoint)
    let durableBytes = try! session.durableStateBytes()
    let deathsBefore = session.mortalitySnapshot().totalDeathCount
    let estatesBefore = session.estateSnapshot().totalEstateCount
    let compacted = session.mortalitySnapshot().compactedDeathSummaries?
        .count ?? 0
    let observerBytes = try! session.durableStateBytes()
    let observer = session.observerSnapshot(
        worldBinding: try! AgentObserverWorldBinding(
            worldID: "gate-f-b09-compat-world",
            storageIdentity: "memory:gate-f-b09-compat", seed: 909,
            dimension: 0, observedWorldTick: session.tick
        )
    )
    let observerMutations = (try! session.durableStateBytes())
        == observerBytes ? 0 : 1
    _ = try! session.advanceTick()
    let continued = try! session.makeCheckpoint()
    let replayedDeaths = session.mortalitySnapshot().totalDeathCount
        - deathsBefore
    let replayedEstates = session.estateSnapshot().totalEstateCount
        - estatesBefore
    let exactCheckpoint = (try? AgentCheckpointCodec.encode(checkpoint))
        == checkpointBytes
    let report = GateFB09CompatibilityReport(
        schemaVersion: 1, sourceCheckpoint: source,
        checkpointSchema: checkpoint.schemaVersion,
        observerSchema: observer.header.schemaVersion,
        checkpointBytes: checkpointBytes.count,
        checkpointSHA256: AgentCheckpointDigest.sha256(
            checkpointBytes
        ).rawValue,
        durableSHA256: AgentCheckpointDigest.sha256(durableBytes).rawValue,
        deathCount: deathsBefore, estateCount: estatesBefore,
        compactedDeathCount: compacted,
        replayedDeaths: replayedDeaths, replayedEstates: replayedEstates,
        duplicateCurrentAuthority:
            gateFB09CurrentAuthorityIsSingular(session) ? 0 : 1,
        observerMutationCount: observerMutations,
        assertions: [
            "old_checkpoint_reencodes_exactly": exactCheckpoint,
            "checkpoint_schema_35": checkpoint.schemaVersion == 35,
            "observer_schema_13": observer.header.schemaVersion == 13,
            "observer_read_only": observerMutations == 0,
            "continuation_schema_35": continued.schemaVersion == 35,
            "zero_death_replay": replayedDeaths == 0,
            "zero_estate_replay": replayedEstates == 0,
            "singular_current_authority":
                gateFB09CurrentAuthorityIsSingular(session),
        ]
    )
    try! gateFB09WriteJSON(
        report, to: URL(fileURLWithPath: output)
    )
    check("published schema-35 checkpoint restores in corrected reader",
          report.assertions.values.allSatisfy { $0 })
    return true
}

private func gateFB09MortalityFreshProcessIfRequested() -> Bool {
    let environment = ProcessInfo.processInfo.environment
    guard let phase = environment[
        "PEBBLELAB_GATE_F_BLOCKER_09_MORTALITY_FRESH_PHASE"
    ] else { return false }
    guard ["write-pending", "restore-finalize-write", "restore-continue"]
            .contains(phase),
          let output = environment[
              "PEBBLELAB_GATE_F_BLOCKER_09_MORTALITY_OUT"
          ] else {
        preconditionFailure(
            "invalid Gate F Blocker 09 mortality fresh-process environment"
        )
    }
    let root = URL(fileURLWithPath: output, isDirectory: true)
    try! FileManager.default.createDirectory(
        at: root, withIntermediateDirectories: true
    )
    let preCheckpointURL = root.appendingPathComponent(
        "pending_checkpoint_v35.json"
    )
    let preDurableURL = root.appendingPathComponent(
        "pending_durable_state.json"
    )
    let postCheckpointURL = root.appendingPathComponent(
        "finalized_checkpoint_v35.json"
    )
    let postDurableURL = root.appendingPathComponent(
        "finalized_durable_state.json"
    )
    let child = AgentID(rawValue: "agent_3")!
    let parent = AgentID(rawValue: "agent_0")!

    if phase == "write-pending" {
        let fixture = gateFB09PendingSuccessorFixture(
            "gate-f-b09-mortality-fresh", fingerprint: 90_070
        )
        let session = fixture.session
        let pending = session.pendingMortalityTransitions().first {
            $0.agentID == parent
        }!
        let estate = gateFB09Estate(session, decedentID: child)
        let parentEligible = estate.successorPlanProof?.eligibilityRows.first {
            $0.agentID == parent
        }?.eligibleAtDeath ?? true
        let checkpoint = try! session.makeCheckpoint()
        let checkpointBytes = try! AgentCheckpointCodec.encode(checkpoint)
        let durableBytes = try! session.durableStateBytes()
        try! checkpointBytes.write(to: preCheckpointURL, options: .atomic)
        try! durableBytes.write(to: preDurableURL, options: .atomic)
        let report = GateFB09MortalityFreshReport(
            schemaVersion: 1, phase: phase, tick: session.tick,
            checkpointSchema: checkpoint.schemaVersion, observerSchema: 13,
            checkpointBytes: checkpointBytes.count,
            durableBytes: durableBytes.count,
            checkpointSHA256: AgentCheckpointDigest.sha256(
                checkpointBytes
            ).rawValue,
            durableSHA256: AgentCheckpointDigest.sha256(
                durableBytes
            ).rawValue,
            pendingSequence: pending.pendingEventID.sequence.rawValue,
            estatePlanSequence:
                estate.successorPlanEventID.sequence.rawValue,
            lethalSequence: nil, deathFinalSequence: nil,
            pendingParentEligibleAtPlan: parentEligible,
            deathCount: session.mortalitySnapshot().totalDeathCount,
            estateCount: session.estateSnapshot().totalEstateCount,
            replayedDeaths: 0, replayedEstates: 0,
            duplicateCurrentAuthority:
                gateFB09CurrentAuthorityIsSingular(session) ? 0 : 1,
            observerMutationCount: 0,
            assertions: [
                "checkpoint_schema_35": checkpoint.schemaVersion == 35,
                "pending_precedes_plan": pending.pendingEventID.sequence
                    < estate.successorPlanEventID.sequence,
                "pending_parent_ineligible": !parentEligible,
                "one_death_one_estate":
                    session.mortalitySnapshot().totalDeathCount == 1
                    && session.estateSnapshot().totalEstateCount == 1,
                "pending_parent_retained":
                    session.pendingMortalityTransitions().contains {
                        $0.agentID == parent
                    },
                "singular_current_authority":
                    gateFB09CurrentAuthorityIsSingular(session),
            ]
        )
        try! gateFB09WriteJSON(
            report, to: root.appendingPathComponent("process_1_report.json")
        )
        check("mortality fresh process 1 writes pending-successor state",
              report.assertions.values.allSatisfy { $0 })
        return true
    }

    if phase == "restore-finalize-write" {
        let checkpointBytes = try! Data(contentsOf: preCheckpointURL)
        let durableBytes = try! Data(contentsOf: preDurableURL)
        let checkpoint = try! AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self, from: checkpointBytes
        )
        var session = try! AgentSimulationSession.restoring(checkpoint)
        let restoredPreDurable = try! session.durableStateBytes()
        let proofBefore = gateFB09Estate(
            session, decedentID: child
        ).successorPlanProof!
        let pending = session.pendingMortalityTransitions().first {
            $0.agentID == parent
        }!
        _ = gateFB09ResolveEmptyCustody(&session, agentID: parent)
        let death = try! session.finalizePendingMortality(for: parent)
        let proofAfter = gateFB09Estate(
            session, decedentID: child
        ).successorPlanProof!
        let postCheckpoint = try! session.makeCheckpoint()
        let postCheckpointBytes = try! AgentCheckpointCodec.encode(
            postCheckpoint
        )
        let postDurableBytes = try! session.durableStateBytes()
        try! postCheckpointBytes.write(
            to: postCheckpointURL, options: .atomic
        )
        try! postDurableBytes.write(to: postDurableURL, options: .atomic)
        let parentEligible = proofBefore.eligibilityRows.first {
            $0.agentID == parent
        }?.eligibleAtDeath ?? true
        let report = GateFB09MortalityFreshReport(
            schemaVersion: 1, phase: phase, tick: session.tick,
            checkpointSchema: postCheckpoint.schemaVersion,
            observerSchema: 13,
            checkpointBytes: postCheckpointBytes.count,
            durableBytes: postDurableBytes.count,
            checkpointSHA256: AgentCheckpointDigest.sha256(
                postCheckpointBytes
            ).rawValue,
            durableSHA256: AgentCheckpointDigest.sha256(
                postDurableBytes
            ).rawValue,
            pendingSequence: pending.pendingEventID.sequence.rawValue,
            estatePlanSequence:
                proofBefore.successorPlanEventID.sequence.rawValue,
            lethalSequence: death.lethalDamageEventID.sequence.rawValue,
            deathFinalSequence: death.deathEventID.sequence.rawValue,
            pendingParentEligibleAtPlan: parentEligible,
            deathCount: session.mortalitySnapshot().totalDeathCount,
            estateCount: session.estateSnapshot().totalEstateCount,
            replayedDeaths: 0, replayedEstates: 0,
            duplicateCurrentAuthority:
                gateFB09CurrentAuthorityIsSingular(session) ? 0 : 1,
            observerMutationCount: 0,
            assertions: [
                "pending_checkpoint_bytes_exact":
                    (try? AgentCheckpointCodec.encode(checkpoint))
                        == checkpointBytes,
                "pending_durable_bytes_exact":
                    restoredPreDurable == durableBytes,
                "pending_parent_ineligible": !parentEligible,
                "immutable_estate_proof": proofBefore == proofAfter,
                "pending_death_finalized":
                    !session.pendingMortalityTransitions().contains {
                        $0.agentID == parent
                    },
                "two_deaths_two_estates":
                    session.mortalitySnapshot().totalDeathCount == 2
                    && session.estateSnapshot().totalEstateCount == 2,
                "postfinal_checkpoint_schema_35":
                    postCheckpoint.schemaVersion == 35,
                "singular_current_authority":
                    gateFB09CurrentAuthorityIsSingular(session),
            ]
        )
        try! gateFB09WriteJSON(
            report, to: root.appendingPathComponent("process_2_report.json")
        )
        check("mortality fresh process 2 finalizes pending successor",
              report.assertions.values.allSatisfy { $0 })
        return true
    }

    let checkpointBytes = try! Data(contentsOf: postCheckpointURL)
    let durableBytes = try! Data(contentsOf: postDurableURL)
    let checkpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self, from: checkpointBytes
    )
    var session = try! AgentSimulationSession.restoring(checkpoint)
    let restoredDurable = try! session.durableStateBytes()
    let estateBefore = gateFB09Estate(session, decedentID: child)
    let proof = estateBefore.successorPlanProof!
    let parentRecord = session.mortalitySnapshot().records.first {
        $0.agentID == parent
    }!
    let deathsBefore = session.mortalitySnapshot().totalDeathCount
    let estatesBefore = session.estateSnapshot().totalEstateCount
    let observerBytes = try! session.durableStateBytes()
    let observer = session.observerSnapshot(
        worldBinding: try! AgentObserverWorldBinding(
            worldID: "gate-f-b09-mortality-fresh-world",
            storageIdentity: "memory:gate-f-b09-mortality-fresh",
            seed: 909, dimension: 0, observedWorldTick: session.tick
        )
    )
    let observerMutations = (try! session.durableStateBytes())
        == observerBytes ? 0 : 1
    gateFB09FeedFounders(&session, ordinals: [1, 2])
    _ = try! session.advanceTick()
    let continued = try! session.makeCheckpoint()
    let replayedDeaths = session.mortalitySnapshot().totalDeathCount
        - deathsBefore
    let replayedEstates = session.estateSnapshot().totalEstateCount
        - estatesBefore
    let parentEligible = proof.eligibilityRows.first {
        $0.agentID == parent
    }?.eligibleAtDeath ?? true
    let report = GateFB09MortalityFreshReport(
        schemaVersion: 1, phase: phase, tick: session.tick,
        checkpointSchema: continued.schemaVersion,
        observerSchema: observer.header.schemaVersion,
        checkpointBytes: checkpointBytes.count,
        durableBytes: durableBytes.count,
        checkpointSHA256: AgentCheckpointDigest.sha256(
            checkpointBytes
        ).rawValue,
        durableSHA256: AgentCheckpointDigest.sha256(durableBytes).rawValue,
        pendingSequence:
            parentRecord.pendingMaterialExitEventID!.sequence.rawValue,
        estatePlanSequence:
            proof.successorPlanEventID.sequence.rawValue,
        lethalSequence:
            parentRecord.lethalDamageEventID.sequence.rawValue,
        deathFinalSequence: parentRecord.deathEventID.sequence.rawValue,
        pendingParentEligibleAtPlan: parentEligible,
        deathCount: deathsBefore, estateCount: estatesBefore,
        replayedDeaths: replayedDeaths, replayedEstates: replayedEstates,
        duplicateCurrentAuthority:
            gateFB09CurrentAuthorityIsSingular(session) ? 0 : 1,
        observerMutationCount: observerMutations,
        assertions: [
            "finalized_checkpoint_bytes_exact":
                (try? AgentCheckpointCodec.encode(checkpoint))
                    == checkpointBytes,
            "finalized_durable_bytes_exact": restoredDurable == durableBytes,
            "pending_parent_historically_ineligible": !parentEligible,
            "two_deaths_two_estates": deathsBefore == 2 && estatesBefore == 2,
            "observer_schema_13": observer.header.schemaVersion == 13,
            "observer_read_only": observerMutations == 0,
            "continuation_schema_35": continued.schemaVersion == 35,
            "zero_death_replay": replayedDeaths == 0,
            "zero_estate_replay": replayedEstates == 0,
            "singular_current_authority":
                gateFB09CurrentAuthorityIsSingular(session),
        ]
    )
    try! gateFB09WriteJSON(
        report, to: root.appendingPathComponent("process_3_report.json")
    )
    check("mortality fresh process 3 restores and continues without replay",
          report.assertions.values.allSatisfy { $0 })
    return true
}

private func gateFB09FreshProcessIfRequested() -> Bool {
    let environment = ProcessInfo.processInfo.environment
    guard let phase = environment[
        "PEBBLELAB_GATE_F_BLOCKER_09_FRESH_PHASE"
    ] else { return false }
    guard ["write-prebirth", "restore-birth-write", "restore-continue"]
            .contains(phase),
          let output = environment[
              "PEBBLELAB_GATE_F_BLOCKER_09_OUT"
          ] else {
        preconditionFailure(
            "invalid Gate F Blocker 09 fresh-process environment"
        )
    }
    let root = URL(fileURLWithPath: output, isDirectory: true)
    try! FileManager.default.createDirectory(
        at: root, withIntermediateDirectories: true
    )
    let preCheckpointURL = root.appendingPathComponent(
        "prebirth_checkpoint_v35.json"
    )
    let preDurableURL = root.appendingPathComponent(
        "prebirth_durable_state.json"
    )
    let postCheckpointURL = root.appendingPathComponent(
        "postbirth_checkpoint_v35.json"
    )
    let postDurableURL = root.appendingPathComponent(
        "postbirth_durable_state.json"
    )
    let firstChild = AgentID(rawValue: "agent_3")!
    let laterChild = AgentID(rawValue: "agent_4")!

    if phase == "write-prebirth" {
        var fixture = gateFB09BoundaryFixture("gate-f-b09-fresh")
        _ = gateFB09ResolveEmptyCustody(
            &fixture.session, agentID: fixture.firstBirth.newbornID
        )
        _ = try! fixture.session.finalizePendingMortality(
            for: fixture.firstBirth.newbornID
        )
        let estate = gateFB09Estate(
            fixture.session, decedentID: fixture.firstBirth.newbornID
        )
        let checkpoint = try! fixture.session.makeCheckpoint()
        let checkpointBytes = try! AgentCheckpointCodec.encode(checkpoint)
        let durableBytes = try! fixture.session.durableStateBytes()
        try! checkpointBytes.write(to: preCheckpointURL, options: .atomic)
        try! durableBytes.write(to: preDurableURL, options: .atomic)
        let report = GateFB09FreshReport(
            schemaVersion: 1, phase: phase, tick: fixture.session.tick,
            checkpointSchema: checkpoint.schemaVersion, observerSchema: 13,
            checkpointBytes: checkpointBytes.count,
            durableBytes: durableBytes.count,
            checkpointSHA256: AgentCheckpointDigest.sha256(
                checkpointBytes
            ).rawValue,
            durableSHA256: AgentCheckpointDigest.sha256(
                durableBytes
            ).rawValue,
            estatePlanSequence:
                estate.successorPlanEventID.sequence.rawValue,
            laterBirthSequence: nil, laterParentageSequence: nil,
            currentSiblingRelation: "notBorn",
            historicalLaterSiblingRows: estate.successorPlanProof?
                .eligibilityRows.filter { $0.agentID == laterChild }.count ?? -1,
            replayedDeaths: 0, replayedEstates: 0,
            duplicateCurrentAuthority:
                gateFB09CurrentAuthorityIsSingular(fixture.session) ? 0 : 1,
            observerMutationCount: 0,
            assertions: [
                "checkpoint_schema_35": checkpoint.schemaVersion == 35,
                "death_and_estate_once":
                    fixture.session.mortalitySnapshot().totalDeathCount == 1
                    && fixture.session.estateSnapshot().totalEstateCount == 1,
                "later_child_not_yet_born":
                    !fixture.session.identitySnapshot().agentIDs.contains(
                        laterChild
                    ),
                "prebirth_proof_has_no_later_child":
                    estate.successorPlanProof?.eligibilityRows.contains {
                        $0.agentID == laterChild
                    } == false,
                "singular_current_authority":
                    gateFB09CurrentAuthorityIsSingular(fixture.session),
            ]
        )
        try! gateFB09WriteJSON(
            report, to: root.appendingPathComponent("process_1_report.json")
        )
        check("fresh process 1 writes pre-birth schema-35 state",
              report.assertions.values.allSatisfy { $0 })
        return true
    }

    if phase == "restore-birth-write" {
        let checkpointBytes = try! Data(contentsOf: preCheckpointURL)
        let durableBytes = try! Data(contentsOf: preDurableURL)
        let checkpoint = try! AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self, from: checkpointBytes
        )
        var session = try! AgentSimulationSession.restoring(checkpoint)
        let restoredPrebirthDurable = try! session.durableStateBytes()
        let proofBefore = gateFB09Estate(
            session, decedentID: firstChild
        ).successorPlanProof!
        let plan = session.pendingBirthSitePlan()!
        let birth = gateFB09Birth(
            &session, plan: plan, fingerprint: 90_051
        )
        let parentage = gateFB09Parentage(session, childID: birth.newbornID)
        let estateAfter = gateFB09Estate(session, decedentID: firstChild)
        let postCheckpoint = try! session.makeCheckpoint()
        let postCheckpointBytes = try! AgentCheckpointCodec.encode(
            postCheckpoint
        )
        let postDurableBytes = try! session.durableStateBytes()
        try! postCheckpointBytes.write(
            to: postCheckpointURL, options: .atomic
        )
        try! postDurableBytes.write(to: postDurableURL, options: .atomic)
        let report = GateFB09FreshReport(
            schemaVersion: 1, phase: phase, tick: session.tick,
            checkpointSchema: postCheckpoint.schemaVersion,
            observerSchema: 13,
            checkpointBytes: postCheckpointBytes.count,
            durableBytes: postDurableBytes.count,
            checkpointSHA256: AgentCheckpointDigest.sha256(
                postCheckpointBytes
            ).rawValue,
            durableSHA256: AgentCheckpointDigest.sha256(
                postDurableBytes
            ).rawValue,
            estatePlanSequence:
                estateAfter.successorPlanEventID.sequence.rawValue,
            laterBirthSequence:
                parentage.sourcePopulationBornEventID.sequence.rawValue,
            laterParentageSequence:
                parentage.recordedEventID.sequence.rawValue,
            currentSiblingRelation: "halfSibling",
            historicalLaterSiblingRows: estateAfter.successorPlanProof?
                .eligibilityRows.filter { $0.agentID == laterChild }.count ?? -1,
            replayedDeaths: 0, replayedEstates: 0,
            duplicateCurrentAuthority:
                gateFB09CurrentAuthorityIsSingular(session) ? 0 : 1,
            observerMutationCount: 0,
            assertions: [
                "prebirth_checkpoint_bytes_exact":
                    (try? AgentCheckpointCodec.encode(checkpoint))
                        == checkpointBytes,
                "prebirth_durable_bytes_exact":
                    restoredPrebirthDurable == durableBytes,
                "later_birth_identity_exact": birth.newbornID == laterChild,
                "later_parentage_after_plan":
                    proofBefore.successorPlanEventID.sequence
                        < parentage.sourcePopulationBornEventID.sequence
                    && proofBefore.successorPlanEventID.sequence
                        < parentage.recordedEventID.sequence,
                "current_half_sibling": session.siblingRelation(
                    between: firstChild, and: laterChild
                ) == .halfSibling,
                "immutable_estate_proof":
                    estateAfter.successorPlanProof == proofBefore,
                "historical_later_sibling_absent":
                    estateAfter.successorPlanProof?.eligibilityRows.contains {
                        $0.agentID == laterChild
                    } == false,
                "postbirth_checkpoint_schema_35":
                    postCheckpoint.schemaVersion == 35,
                "singular_current_authority":
                    gateFB09CurrentAuthorityIsSingular(session),
            ]
        )
        try! gateFB09WriteJSON(
            report, to: root.appendingPathComponent("process_2_report.json")
        )
        check("fresh process 2 restores, births, and writes post-birth state",
              report.assertions.values.allSatisfy { $0 })
        return true
    }

    let checkpointBytes = try! Data(contentsOf: postCheckpointURL)
    let durableBytes = try! Data(contentsOf: postDurableURL)
    let checkpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self, from: checkpointBytes
    )
    var session = try! AgentSimulationSession.restoring(checkpoint)
    let restoredDurable = try! session.durableStateBytes()
    let estateBefore = gateFB09Estate(session, decedentID: firstChild)
    let deathsBefore = session.mortalitySnapshot().totalDeathCount
    let estatesBefore = session.estateSnapshot().totalEstateCount
    let observerBytes = try! session.durableStateBytes()
    let observer = session.observerSnapshot(
        worldBinding: try! AgentObserverWorldBinding(
            worldID: "gate-f-b09-fresh-world",
            storageIdentity: "memory:gate-f-b09-fresh", seed: 909,
            dimension: 0, observedWorldTick: session.tick
        )
    )
    let observerMutationCount = (try! session.durableStateBytes())
        == observerBytes ? 0 : 1
    gateFB09FeedFounders(&session)
    _ = try! session.advanceTick()
    let continuation = try! session.makeCheckpoint()
    let replayedDeaths = session.mortalitySnapshot().totalDeathCount
        - deathsBefore
    let replayedEstates = session.estateSnapshot().totalEstateCount
        - estatesBefore
    let report = GateFB09FreshReport(
        schemaVersion: 1, phase: phase, tick: session.tick,
        checkpointSchema: continuation.schemaVersion,
        observerSchema: observer.header.schemaVersion,
        checkpointBytes: checkpointBytes.count,
        durableBytes: durableBytes.count,
        checkpointSHA256: AgentCheckpointDigest.sha256(
            checkpointBytes
        ).rawValue,
        durableSHA256: AgentCheckpointDigest.sha256(durableBytes).rawValue,
        estatePlanSequence:
            estateBefore.successorPlanEventID.sequence.rawValue,
        laterBirthSequence: gateFB09Parentage(
            session, childID: laterChild
        ).sourcePopulationBornEventID.sequence.rawValue,
        laterParentageSequence: gateFB09Parentage(
            session, childID: laterChild
        ).recordedEventID.sequence.rawValue,
        currentSiblingRelation: "halfSibling",
        historicalLaterSiblingRows: estateBefore.successorPlanProof?
            .eligibilityRows.filter { $0.agentID == laterChild }.count ?? -1,
        replayedDeaths: replayedDeaths, replayedEstates: replayedEstates,
        duplicateCurrentAuthority:
            gateFB09CurrentAuthorityIsSingular(session) ? 0 : 1,
        observerMutationCount: observerMutationCount,
        assertions: [
            "postbirth_checkpoint_bytes_exact":
                (try? AgentCheckpointCodec.encode(checkpoint))
                    == checkpointBytes,
            "postbirth_durable_bytes_exact": restoredDurable == durableBytes,
            "current_half_sibling": session.siblingRelation(
                between: firstChild, and: laterChild
            ) == .halfSibling,
            "historical_later_sibling_absent":
                estateBefore.successorPlanProof?.eligibilityRows.contains {
                    $0.agentID == laterChild
                } == false,
            "identity_ordinals_exact":
                session.populationSnapshot().nextPopulationOrdinal == 5
                && session.durableState().populationRegistry?.scaleState?
                    .nextFidelityTransitionOrdinal == 6,
            "observer_schema_13": observer.header.schemaVersion == 13,
            "observer_read_only": observerMutationCount == 0,
            "continuation_schema_35": continuation.schemaVersion == 35,
            "zero_death_replay": replayedDeaths == 0,
            "zero_estate_replay": replayedEstates == 0,
            "singular_current_authority":
                gateFB09CurrentAuthorityIsSingular(session),
        ]
    )
    try! gateFB09WriteJSON(
        report, to: root.appendingPathComponent("process_3_report.json")
    )
    check("fresh process 3 restores and continues without replay",
          report.assertions.values.allSatisfy { $0 })
    return true
}

func runPebbleAgentsGateFBlocker09Smoke() {
    section("Gate F Blocker 09 — Estate / Kinship causal successor authority")
    if gateFB09CompatibilityReaderIfRequested() { return }
    if gateFB09MortalityFreshProcessIfRequested() { return }
    if gateFB09FreshProcessIfRequested() { return }

    var control = gateFB09BoundaryFixture("gate-f-b09-control")
    let controlLaterBirth = gateFB09Birth(
        &control.session, plan: control.laterPlan, fingerprint: 90_002
    )
    let controlParentage = gateFB09Parentage(
        control.session, childID: controlLaterBirth.newbornID
    )
    _ = gateFB09ResolveEmptyCustody(
        &control.session, agentID: control.firstBirth.newbornID
    )
    let controlDeath = try! control.session.finalizePendingMortality(
        for: control.firstBirth.newbornID
    )
    let controlEstate = gateFB09Estate(
        control.session, decedentID: control.firstBirth.newbornID
    )
    check("same-tick sibling recorded before plan is retained historically",
          control.session.tick == 4
            && controlParentage.recordedEventID.sequence
                < controlEstate.successorPlanEventID.sequence
            && controlEstate.successorPlanProof?.eligibilityRows.contains {
                $0.agentID == controlLaterBirth.newbornID
                    && $0.basis == .halfSibling
            } == true
            && gateFB09RestoreExact(control.session) != nil)

    var attack = gateFB09BoundaryFixture("gate-f-b09-attack")
    _ = gateFB09ResolveEmptyCustody(
        &attack.session, agentID: attack.firstBirth.newbornID
    )
    let attackDeath = try! attack.session.finalizePendingMortality(
        for: attack.firstBirth.newbornID
    )
    let proofBeforeBirth = gateFB09Estate(
        attack.session, decedentID: attack.firstBirth.newbornID
    ).successorPlanProof!
    let attackLaterBirth = gateFB09Birth(
        &attack.session, plan: attack.laterPlan, fingerprint: 90_003
    )
    let attackParentage = gateFB09Parentage(
        attack.session, childID: attackLaterBirth.newbornID
    )
    let attackEstate = gateFB09Estate(
        attack.session, decedentID: attack.firstBirth.newbornID
    )
    let attackRestored = gateFB09RestoreExact(attack.session)
    check("same-tick sibling recorded after plan is excluded historically",
          attack.session.tick == 4
            && attackEstate.successorPlanEventID.sequence
                < attackParentage.sourcePopulationBornEventID.sequence
            && attackEstate.successorPlanEventID.sequence
                < attackParentage.recordedEventID.sequence
            && attackEstate.successorPlanProof == proofBeforeBirth
            && attackEstate.successorPlanProof?.eligibilityRows.contains {
                $0.agentID == attackLaterBirth.newbornID
            } == false)
    check("current Kinship retains the later half-sibling",
          attack.session.siblingRelation(
            between: attack.firstBirth.newbornID,
            and: attackLaterBirth.newbornID
          ) == .halfSibling)
    check("post-plan public birth remains schema-35 checkpointable",
          (try? attack.session.makeCheckpoint().schemaVersion) == 35
            && attackRestored != nil)
    check("post-plan restore preserves immutable Estate proof",
          attackRestored.map {
              gateFB09Estate(
                $0, decedentID: attack.firstBirth.newbornID
              ).successorPlanProof == proofBeforeBirth
                && $0.siblingRelation(
                    between: attack.firstBirth.newbornID,
                    and: attackLaterBirth.newbornID
                ) == .halfSibling
          } == true)
    check("exact Evaluation 09 identities and ordinals are conserved",
          attackDeath.agentID == AgentID(rawValue: "agent_3")!
            && attackDeath.populationOrdinal.rawValue == 3
            && attackLaterBirth.newbornID == AgentID(rawValue: "agent_4")!
            && attackLaterBirth.ordinal.rawValue == 4
            && attack.session.populationSnapshot().nextPopulationOrdinal == 5
            && attack.session.durableState().populationRegistry?.scaleState?
                .nextFidelityTransitionOrdinal == 6
            && attack.session.durableState().populationRegistry?.scaleState?
                .nextSettlementMigrationOrdinal == 1
            && attack.session.householdSnapshot().nextHouseholdOrdinal == 3
            && attack.session.durableState().familyState?.nextUnionOrdinal == 1
            && attack.session.durableState().familyState?.nextHouseOrdinal == 1)
    check("focused current authority remains singular",
          gateFB09CurrentAuthorityIsSingular(control.session)
            && gateFB09CurrentAuthorityIsSingular(attack.session))
    let observerBytes = try! attack.session.durableStateBytes()
    let observer = attack.session.observerSnapshot(
        worldBinding: try! AgentObserverWorldBinding(
            worldID: "gate-f-b09-world",
            storageIdentity: "memory:gate-f-b09", seed: 909,
            dimension: 0, observedWorldTick: attack.session.tick
        )
    )
    check("checkpoint schema 35 and Observer schema 13 remain unchanged",
          observer.header.schemaVersion == 13
            && (try! attack.session.makeCheckpoint()).schemaVersion == 35
            && (try! attack.session.durableStateBytes()) == observerBytes)

    let attackCheckpoint = try! attack.session.makeCheckpoint()
    let controlCheckpoint = try! control.session.makeCheckpoint()
    let postBoundaryRelationship = gateFB09MutatedCheckpoint(
        attackCheckpoint
    ) { durable in
        var authority = durable["estateState"] as! [String: Any]
        var estates = authority["estates"] as! [[String: Any]]
        var proof = estates[0]["successorPlanProof"] as! [String: Any]
        var rows = proof["eligibilityRows"] as! [[String: Any]]
        var row = rows.last!
        row["agentID"] = attackLaterBirth.newbornID.rawValue
        row["tier"] = AgentEstateBeneficiaryTier.tertiarySiblings.rawValue
        row["basis"] = AgentEstateBeneficiaryBasis.halfSibling.rawValue
        row["eligibleAtDeath"] = true
        row["lifeStageAtPlan"] = AgentLifeStage.newborn.rawValue
        row.removeValue(forKey: "guardianIDAtPlan")
        rows.append(row)
        proof["eligibilityRows"] = rows
        estates[0]["successorPlanProof"] = proof
        authority["estates"] = estates
        durable["estateState"] = authority
    }
    check("strict proof rejects post-boundary parentage relationship",
          gateFB09RestoreError(postBoundaryRelationship)?.contains(
            "successor relationship rows"
          ) == true)

    let omittedPriorRelationship = gateFB09MutatedCheckpoint(
        controlCheckpoint
    ) { durable in
        var authority = durable["estateState"] as! [String: Any]
        var estates = authority["estates"] as! [[String: Any]]
        var proof = estates[0]["successorPlanProof"] as! [String: Any]
        var rows = proof["eligibilityRows"] as! [[String: Any]]
        rows.removeAll {
            ($0["agentID"] as? String) == controlLaterBirth.newbornID.rawValue
        }
        proof["eligibilityRows"] = rows
        estates[0]["successorPlanProof"] = proof
        authority["estates"] = estates
        durable["estateState"] = authority
    }
    check("strict proof rejects omitted pre-boundary relationship",
          gateFB09RestoreError(omittedPriorRelationship)?.contains(
            "successor relationship rows"
          ) == true)

    let wrongRelationshipBasis = gateFB09MutatedCheckpoint(
        controlCheckpoint
    ) { durable in
        var authority = durable["estateState"] as! [String: Any]
        var estates = authority["estates"] as! [[String: Any]]
        var proof = estates[0]["successorPlanProof"] as! [String: Any]
        var rows = proof["eligibilityRows"] as! [[String: Any]]
        let index = rows.firstIndex {
            ($0["agentID"] as? String) == controlLaterBirth.newbornID.rawValue
        }!
        rows[index]["basis"] = AgentEstateBeneficiaryBasis.fullSibling.rawValue
        proof["eligibilityRows"] = rows
        estates[0]["successorPlanProof"] = proof
        authority["estates"] = estates
        durable["estateState"] = authority
    }
    check("strict proof rejects wrong parentage relationship basis",
          gateFB09RestoreError(wrongRelationshipBasis)?.contains(
            "successor relationship rows"
          ) == true)

    let wrongBeneficiaries = gateFB09MutatedCheckpoint(
        attackCheckpoint
    ) { durable in
        var authority = durable["estateState"] as! [String: Any]
        var estates = authority["estates"] as! [[String: Any]]
        var beneficiaries = estates[0]["beneficiaries"] as! [[String: Any]]
        beneficiaries.removeLast()
        estates[0]["beneficiaries"] = beneficiaries
        authority["estates"] = estates
        durable["estateState"] = authority
    }
    check("strict proof rejects wrong beneficiary tier/list",
          gateFB09RestoreError(wrongBeneficiaries)?.contains(
            "exact successor beneficiary list"
          ) == true)

    let malformedPlanIdentity = gateFB09MutatedCheckpoint(
        attackCheckpoint
    ) { durable in
        var authority = durable["estateState"] as! [String: Any]
        var estates = authority["estates"] as! [[String: Any]]
        var eventID = estates[0]["successorPlanEventID"] as! [String: Any]
        eventID["simulationID"] = "gate-f-b09-foreign"
        estates[0]["successorPlanEventID"] = eventID
        var proof = estates[0]["successorPlanProof"] as! [String: Any]
        proof["successorPlanEventID"] = eventID
        estates[0]["successorPlanProof"] = proof
        authority["estates"] = estates
        durable["estateState"] = authority
    }
    check("strict proof rejects foreign successor-plan identity",
          gateFB09RestoreError(malformedPlanIdentity) != nil)

    let malformedParentageIdentity = gateFB09MutatedCheckpoint(
        attackCheckpoint, refreshEstateDigests: false
    ) { durable in
        var kinship = durable["kinshipState"] as! [String: Any]
        var records = kinship["parentageRecords"] as! [[String: Any]]
        let index = records.firstIndex {
            ($0["childID"] as? String) == attackLaterBirth.newbornID.rawValue
        }!
        var eventID = records[index]["recordedEventID"] as! [String: Any]
        eventID["simulationID"] = "gate-f-b09-foreign"
        records[index]["recordedEventID"] = eventID
        kinship["parentageRecords"] = records
        durable["kinshipState"] = kinship
    }
    let malformedParentageError = gateFB09RestoreError(
        malformedParentageIdentity
    )
    print("GATE_F_BLOCKER_09_MALFORMED_PARENTAGE_ERROR "
        + "\(malformedParentageError ?? "none")")
    check("Kinship rejects malformed parentage causal identity",
          malformedParentageError != nil)

    let mortalityAudit = gateFB09MortalityEligibilityAudit()
    print("GATE_F_BLOCKER_09_MORTALITY_AUDIT "
        + "tick=\(mortalityAudit.tick) "
        + "plan=\(mortalityAudit.estatePlanSequence) "
        + "pending=\(mortalityAudit.laterPendingSequence) "
        + "laterCustody=\(mortalityAudit.laterCustodySequence) "
        + "lethal=\(mortalityAudit.laterLethalSequence) "
        + "deathFinal=\(mortalityAudit.laterDeathFinalSequence) "
        + "checkpointExact=\(mortalityAudit.checkpointRemainsExact ? 1 : 0) "
        + "pendingParentEligible="
        + "\(mortalityAudit.pendingParentEligibleAtPlan ? 1 : 0) "
        + "tier=\(mortalityAudit.selectedTier.rawValue) "
        + "beneficiaries="
        + mortalityAudit.beneficiaryIDs.map(\.rawValue).joined(separator: ","))
    check("pre-plan pending successor is ineligible and later finalizes",
          mortalityAudit.laterPendingSequence
            < mortalityAudit.estatePlanSequence
            && mortalityAudit.estatePlanSequence
                < mortalityAudit.laterCustodySequence
            && mortalityAudit.laterCustodySequence
                < mortalityAudit.laterLethalSequence
            && mortalityAudit.laterLethalSequence
                < mortalityAudit.laterDeathFinalSequence
            && !mortalityAudit.pendingParentEligibleAtPlan
            && mortalityAudit.selectedTier == .secondaryParents
            && mortalityAudit.beneficiaryIDs == [
                AgentID(rawValue: "agent_1")!,
            ]
            && mortalityAudit.earlierProofImmutable
            && mortalityAudit.finalizationSucceededExactlyOnce
            && mortalityAudit.continuationWithoutReplay
            && mortalityAudit.checkpointRemainsExact)

    let finalizedBefore = gateFB09FinalizedBeforePlanAudit()
    print("GATE_F_BLOCKER_09_FINALIZED_BEFORE_PLAN "
        + "deathFinal=\(finalizedBefore.1) plan=\(finalizedBefore.2)")
    check("finalized-before-plan successors are historically ineligible",
          finalizedBefore.0 && finalizedBefore.3 && finalizedBefore.4)

    let laterMortality = gateFB09LaterTickMortalityAudit()
    print("GATE_F_BLOCKER_09_LATER_MORTALITY "
        + "plan=\(laterMortality.1) pending=\(laterMortality.2) "
        + "deathFinal=\(laterMortality.3)")
    check("post-plan later-tick mortality is not retroactive",
          laterMortality.0 && laterMortality.4 && laterMortality.5)

    let mortalityNegative = gateFB09PendingSuccessorFixture(
        "gate-f-b09-mortality-negatives", fingerprint: 90_062
    )
    let mortalityNegativeCheckpoint = try! mortalityNegative.session
        .makeCheckpoint()
    let pendingParentID = mortalityNegative.pendingParent
    let validParentID = AgentID(rawValue: "agent_1")!
    let wrongEligible = gateFB09MutatedCheckpoint(
        mortalityNegativeCheckpoint
    ) { durable in
        var authority = durable["estateState"] as! [String: Any]
        var estates = authority["estates"] as! [[String: Any]]
        var proof = estates[0]["successorPlanProof"] as! [String: Any]
        var rows = proof["eligibilityRows"] as! [[String: Any]]
        let rowIndex = rows.firstIndex {
            ($0["agentID"] as? String) == pendingParentID.rawValue
        }!
        rows[rowIndex]["eligibleAtDeath"] = true
        proof["eligibilityRows"] = rows
        estates[0]["successorPlanProof"] = proof
        var beneficiaries = estates[0]["beneficiaries"] as! [[String: Any]]
        var beneficiary = beneficiaries[0]
        beneficiary["agentID"] = pendingParentID.rawValue
        beneficiaries.append(beneficiary)
        beneficiaries.sort {
            ($0["agentID"] as! String) < ($1["agentID"] as! String)
        }
        estates[0]["beneficiaries"] = beneficiaries
        authority["estates"] = estates
        durable["estateState"] = authority
    }
    check("strict proof rejects eligible pre-plan pending successor",
          gateFB09RestoreError(wrongEligible)?.contains(
            "successor mortality eligibility"
          ) == true)

    let wrongIneligible = gateFB09MutatedCheckpoint(
        mortalityNegativeCheckpoint
    ) { durable in
        var authority = durable["estateState"] as! [String: Any]
        var estates = authority["estates"] as! [[String: Any]]
        var proof = estates[0]["successorPlanProof"] as! [String: Any]
        var rows = proof["eligibilityRows"] as! [[String: Any]]
        let rowIndex = rows.firstIndex {
            ($0["agentID"] as? String) == validParentID.rawValue
        }!
        rows[rowIndex]["eligibleAtDeath"] = false
        proof["eligibilityRows"] = rows
        proof["selectedTier"] = AgentEstateBeneficiaryTier.none.rawValue
        estates[0]["successorPlanProof"] = proof
        estates[0]["beneficiaryTier"] =
            AgentEstateBeneficiaryTier.none.rawValue
        estates[0]["beneficiaries"] = []
        authority["estates"] = estates
        durable["estateState"] = authority
    }
    check("strict proof rejects ineligible living successor",
          gateFB09RestoreError(wrongIneligible)?.contains(
            "successor mortality eligibility"
          ) == true)

    let wrongLifeStage = gateFB09MutatedCheckpoint(
        mortalityNegativeCheckpoint
    ) { durable in
        var authority = durable["estateState"] as! [String: Any]
        var estates = authority["estates"] as! [[String: Any]]
        var proof = estates[0]["successorPlanProof"] as! [String: Any]
        var rows = proof["eligibilityRows"] as! [[String: Any]]
        let rowIndex = rows.firstIndex {
            ($0["agentID"] as? String) == validParentID.rawValue
        }!
        rows[rowIndex]["lifeStageAtPlan"] = AgentLifeStage.newborn.rawValue
        proof["eligibilityRows"] = rows
        estates[0]["successorPlanProof"] = proof
        var beneficiaries = estates[0]["beneficiaries"] as! [[String: Any]]
        beneficiaries[0]["lifeStageAtPlan"] = AgentLifeStage.newborn.rawValue
        estates[0]["beneficiaries"] = beneficiaries
        authority["estates"] = estates
        durable["estateState"] = authority
    }
    check("strict proof rejects wrong mortality life stage at plan",
          gateFB09RestoreError(wrongLifeStage)?.contains(
            "successor life stage at plan"
          ) == true)

    let wrongMortalitySimulation = gateFB09MutatedCheckpoint(
        mortalityNegativeCheckpoint
    ) { durable in
        var mortality = durable["mortalityState"] as! [String: Any]
        var pending = mortality["pendingTransitions"] as! [[String: Any]]
        let index = pending.firstIndex {
            ($0["agentID"] as? String) == pendingParentID.rawValue
        }!
        var eventID = pending[index]["pendingEventID"] as! [String: Any]
        eventID["simulationID"] = "gate-f-b09-foreign"
        pending[index]["pendingEventID"] = eventID
        mortality["pendingTransitions"] = pending
        durable["mortalityState"] = mortality
    }
    check("Mortality rejects foreign pending causal identity",
          gateFB09RestoreError(wrongMortalitySimulation) != nil)

    let impossibleMortalitySequence = gateFB09MutatedCheckpoint(
        mortalityNegativeCheckpoint
    ) { durable in
        var mortality = durable["mortalityState"] as! [String: Any]
        var pending = mortality["pendingTransitions"] as! [[String: Any]]
        let index = pending.firstIndex {
            ($0["agentID"] as? String) == pendingParentID.rawValue
        }!
        var eventID = pending[index]["pendingEventID"] as! [String: Any]
        eventID["sequence"] = UInt64.max
        pending[index]["pendingEventID"] = eventID
        mortality["pendingTransitions"] = pending
        durable["mortalityState"] = mortality
    }
    check("Mortality rejects impossible pending causal sequence",
          gateFB09RestoreError(impossibleMortalitySequence) != nil)
    check("mortality causal authority survives event-body compaction",
          gateFB09MortalityCompactionAudit())

    var previousTick = gateFB09Session(
        "gate-f-b09-previous-tick", hungerPerTick: 0.31
    )
    while previousTick.pendingBirthSitePlan() == nil {
        _ = try! previousTick.advanceTick()
        gateFB09FeedFounders(&previousTick)
    }
    let previousFirstPlan = previousTick.pendingBirthSitePlan()!
    let previousFirstBirth = gateFB09Birth(
        &previousTick, plan: previousFirstPlan, fingerprint: 90_010
    )
    while previousTick.tick < 4 {
        _ = try! previousTick.advanceTick()
        if previousTick.tick < 4 {
            gateFB09FeedFounders(&previousTick)
        }
    }
    let previousLaterPlan = previousTick.pendingBirthSitePlan()!
    let previousLaterBirth = gateFB09Birth(
        &previousTick, plan: previousLaterPlan, fingerprint: 90_011
    )
    gateFB09FeedFounders(&previousTick)
    _ = try! previousTick.advanceTick()
    _ = gateFB09ResolveEmptyCustody(
        &previousTick, agentID: previousFirstBirth.newbornID
    )
    _ = try! previousTick.finalizePendingMortality(
        for: previousFirstBirth.newbornID
    )
    let previousEstate = gateFB09Estate(
        previousTick, decedentID: previousFirstBirth.newbornID
    )
    check("previous-tick half-sibling remains historical authority",
          previousLaterBirth.birthTick < previousEstate.deathTick
            && previousEstate.successorPlanProof?.eligibilityRows.contains {
                $0.agentID == previousLaterBirth.newbornID
                    && $0.basis == .halfSibling
            } == true
            && gateFB09RestoreExact(previousTick) != nil)

    var laterTick = gateFB09BoundaryFixture("gate-f-b09-later-tick")
    _ = gateFB09ResolveEmptyCustody(
        &laterTick.session, agentID: laterTick.firstBirth.newbornID
    )
    _ = try! laterTick.session.finalizePendingMortality(
        for: laterTick.firstBirth.newbornID
    )
    let laterTickProof = gateFB09Estate(
        laterTick.session, decedentID: laterTick.firstBirth.newbornID
    ).successorPlanProof!
    gateFB09FeedFounders(
        &laterTick.session, ordinals: [0, 2]
    )
    _ = try! laterTick.session.advanceTick()
    let laterTickBirth = gateFB09Birth(
        &laterTick.session, plan: laterTick.laterPlan,
        fingerprint: 90_012
    )
    check("later-tick half-sibling is current but excluded historically",
          laterTickBirth.birthTick == 5
            && laterTick.session.siblingRelation(
                between: laterTick.firstBirth.newbornID,
                and: laterTickBirth.newbornID
            ) == .halfSibling
            && gateFB09Estate(
                laterTick.session,
                decedentID: laterTick.firstBirth.newbornID
            ).successorPlanProof == laterTickProof
            && laterTickProof.eligibilityRows.contains {
                $0.agentID == laterTickBirth.newbornID
            } == false
            && gateFB09RestoreExact(laterTick.session) != nil)

    var fullControl = gateFB09FullSiblingBoundaryFixture(
        "gate-f-b09-full-control"
    )
    let fullControlBirth = gateFB09Birth(
        &fullControl.session, plan: fullControl.laterPlan,
        fingerprint: 90_020
    )
    _ = gateFB09ResolveEmptyCustody(
        &fullControl.session, agentID: fullControl.firstBirth.newbornID
    )
    _ = try! fullControl.session.finalizePendingMortality(
        for: fullControl.firstBirth.newbornID
    )
    let fullControlEstate = gateFB09Estate(
        fullControl.session, decedentID: fullControl.firstBirth.newbornID
    )
    check("same-tick full sibling before plan is included",
          fullControl.session.siblingRelation(
            between: fullControl.firstBirth.newbornID,
            and: fullControlBirth.newbornID
          ) == .fullSibling
            && fullControlEstate.successorPlanProof?.eligibilityRows.contains {
                $0.agentID == fullControlBirth.newbornID
                    && $0.basis == .fullSibling
            } == true
            && gateFB09RestoreExact(fullControl.session) != nil)

    var fullAttack = gateFB09FullSiblingBoundaryFixture(
        "gate-f-b09-full-attack"
    )
    _ = gateFB09ResolveEmptyCustody(
        &fullAttack.session, agentID: fullAttack.firstBirth.newbornID
    )
    _ = try! fullAttack.session.finalizePendingMortality(
        for: fullAttack.firstBirth.newbornID
    )
    let fullProof = gateFB09Estate(
        fullAttack.session, decedentID: fullAttack.firstBirth.newbornID
    ).successorPlanProof!
    let fullAttackBirth = gateFB09Birth(
        &fullAttack.session, plan: fullAttack.laterPlan,
        fingerprint: 90_021
    )
    check("same-tick full sibling after plan is excluded historically",
          fullAttack.session.siblingRelation(
            between: fullAttack.firstBirth.newbornID,
            and: fullAttackBirth.newbornID
          ) == .fullSibling
            && gateFB09Estate(
                fullAttack.session,
                decedentID: fullAttack.firstBirth.newbornID
            ).successorPlanProof == fullProof
            && fullProof.eligibilityRows.contains {
                $0.agentID == fullAttackBirth.newbornID
            } == false
            && gateFB09RestoreExact(fullAttack.session) != nil)

    var schema28 = gateFB09BoundaryFixture(
        "gate-f-b09-schema28", includeScale: false
    )
    _ = gateFB09ResolveEmptyCustody(
        &schema28.session, agentID: schema28.firstBirth.newbornID
    )
    _ = try! schema28.session.finalizePendingMortality(
        for: schema28.firstBirth.newbornID
    )
    let schema28Proof = gateFB09Estate(
        schema28.session, decedentID: schema28.firstBirth.newbornID
    ).successorPlanProof!
    let schema28LaterBirth = gateFB09Birth(
        &schema28.session, plan: schema28.laterPlan,
        fingerprint: 90_030
    )
    check("schema 28 applies strict causal parentage authority",
          (try! schema28.session.makeCheckpoint()).schemaVersion == 28
            && schema28.session.siblingRelation(
                between: schema28.firstBirth.newbornID,
                and: schema28LaterBirth.newbornID
            ) == .halfSibling
            && gateFB09Estate(
                schema28.session,
                decedentID: schema28.firstBirth.newbornID
            ).successorPlanProof == schema28Proof
            && gateFB09RestoreExact(schema28.session) != nil)
    check("schema 27 remains legacy and schemas 28 through 35 remain strict",
          AgentCheckpointSchema.estateValidationSemantics(for: 27)
            == .legacySuccessorPlanRevalidation
            && (28...35).allSatisfy {
                AgentCheckpointSchema.estateValidationSemantics(for: $0)
                    == .strictDurableSuccessorPlan
            })
    check("unsupported future schema remains rejected",
          AgentCheckpointSchema.estateValidationSemantics(for: 36) == nil
            && !AgentCheckpointSchema.supports(36))

    var compacted = gateFB09BoundaryFixture(
        "gate-f-b09-compacted", causalMaximumEvents: 32
    )
    _ = gateFB09ResolveEmptyCustody(
        &compacted.session, agentID: compacted.firstBirth.newbornID
    )
    _ = try! compacted.session.finalizePendingMortality(
        for: compacted.firstBirth.newbornID
    )
    let compactedProof = gateFB09Estate(
        compacted.session, decedentID: compacted.firstBirth.newbornID
    ).successorPlanProof!
    let compactedLaterBirth = gateFB09Birth(
        &compacted.session, plan: compacted.laterPlan,
        fingerprint: 90_040
    )
    let compactedParentage = gateFB09Parentage(
        compacted.session, childID: compactedLaterBirth.newbornID
    )
    while compacted.session.causalLedgerSnapshot().summary.droppedEventCount
            < compactedParentage.recordedEventID.sequence.rawValue {
        try! compacted.session.setReproductionEnabled(
            !compacted.session.reproductionEnabled
        )
    }
    let compactedLedger = compacted.session.causalLedgerSnapshot()
    let compactedRestored = gateFB09RestoreExact(compacted.session)
    check("durable causal IDs preserve Estate history after event-body compaction",
          compactedLedger.summary.droppedEventCount
            >= compactedParentage.recordedEventID.sequence.rawValue
            && !compactedLedger.events.contains {
                $0.eventID == compactedProof.successorPlanEventID
                    || $0.eventID
                        == compactedParentage.sourcePopulationBornEventID
                    || $0.eventID == compactedParentage.recordedEventID
            }
            && compactedRestored.map {
                gateFB09Estate(
                    $0, decedentID: compacted.firstBirth.newbornID
                ).successorPlanProof == compactedProof
                    && $0.siblingRelation(
                        between: compacted.firstBirth.newbornID,
                        and: compactedLaterBirth.newbornID
                    ) == .halfSibling
            } == true)

    print("GATE_F_BLOCKER_09_CAUSAL_MATRIX "
        + "controlTick=\(control.session.tick) "
        + "controlBorn=\(controlParentage.sourcePopulationBornEventID.sequence.rawValue) "
        + "controlParentage=\(controlParentage.recordedEventID.sequence.rawValue) "
        + "controlLethal=\(controlDeath.lethalDamageEventID.sequence.rawValue) "
        + "controlEstateOpen=\(controlEstate.openingEventID.sequence.rawValue) "
        + "controlPlan=\(controlEstate.successorPlanEventID.sequence.rawValue) "
        + "controlDeathFinal=\(controlDeath.deathEventID.sequence.rawValue) "
        + "attackTick=\(attack.session.tick) "
        + "attackLethal=\(attackDeath.lethalDamageEventID.sequence.rawValue) "
        + "attackEstateOpen=\(attackEstate.openingEventID.sequence.rawValue) "
        + "attackPlan=\(attackEstate.successorPlanEventID.sequence.rawValue) "
        + "attackDeathFinal=\(attackDeath.deathEventID.sequence.rawValue) "
        + "laterBorn=\(attackParentage.sourcePopulationBornEventID.sequence.rawValue) "
        + "laterParentage=\(attackParentage.recordedEventID.sequence.rawValue)")
    let attackDurable = attack.session.durableState()
    print("GATE_F_BLOCKER_09_ORDINALS "
        + "deathOrdinal=\(attackDeath.populationOrdinal.rawValue) "
        + "birthOrdinal=\(attackLaterBirth.ordinal.rawValue) "
        + "nextPopulation=\(attack.session.populationSnapshot().nextPopulationOrdinal ?? -1) "
        + "nextFidelity=\(attackDurable.populationRegistry?.scaleState?.nextFidelityTransitionOrdinal ?? 0) "
        + "nextMigration=\(attackDurable.populationRegistry?.scaleState?.nextSettlementMigrationOrdinal ?? 0) "
        + "nextHousehold=\(attack.session.householdSnapshot().nextHouseholdOrdinal ?? -1) "
        + "nextUnion=\(attackDurable.familyState?.nextUnionOrdinal ?? -1) "
        + "nextHouse=\(attackDurable.familyState?.nextHouseOrdinal ?? -1)")
}
