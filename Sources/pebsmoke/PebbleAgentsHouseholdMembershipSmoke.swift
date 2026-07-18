import Foundation
import PebbleAgents

private let householdHabitat = AgentEcologyHabitatObservation(
    worldTick: 0,
    candidateIndex: 0,
    habitatPosition: AgentPosition(x: 1, y: 63, z: 0),
    foragePosition: AgentPosition(x: 1, y: 64, z: 0),
    habitatFingerprint: 812,
    distanceFromSettlement: 1,
    directionIndex: 0,
    worldReadCount: 4
)

private let householdLifecycleConfiguration = try! AgentLifecycleConfiguration(
    newbornDurationTicks: 1,
    maturityAgeTicks: 64,
    reproductionEvaluationIntervalTicks: 1,
    reproductionPlanDelayTicks: 1,
    reproductionCooldownTicks: 1,
    maximumRetainedBirthRecords: 32,
    maximumRetainedPlanRecords: 32,
    maximumParentBirthCount: 16
)

private func householdAgent(
    _ ordinal: Int,
    home: AgentPosition
) -> AgentSessionAgentState {
    AgentSessionAgentState(
        id: "agent_\(ordinal)",
        state: "idle",
        position: home,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0.1, safety: 1),
        health: 100,
        fear: 0,
        homePosition: home,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "household fixture", startedAtTick: 0, urgency: 0
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

private func householdBase(
    _ simulationID: String,
    householdConfiguration: AgentHouseholdConfiguration = .live,
    enablePopulation: Bool = true,
    enableLifecycle: Bool = true,
    enableKinship: Bool = true
) -> AgentSimulationSession {
    let lethalSurvival = try! AgentSurvivalConfiguration(
        hungerPerTick: 1,
        fatiguePerTick: 0.005,
        hungryThreshold: 0.4,
        criticalHungerThreshold: 0.8,
        hungerRecoveryThreshold: 0.15,
        fatigueThreshold: 0.65,
        fatigueRecoveryThreshold: 0.2,
        foodNutrition: 1,
        restRecoveryPerTick: 1,
        starvationGraceTicks: 0,
        starvationDamagePerTick: 100
    )
    let configuration = try! AgentSessionConfiguration(
        seed: 59,
        nearbyRadius: 8,
        resourceObservationRadius: 8,
        recentMemorySnapshotLimit: 8,
        memoryPolicy: .bounded(maxEntries: 64),
        survivalConfiguration: lethalSurvival
    )
    let homeA = AgentPosition(x: 0, y: 64, z: 0)
    let homeB = AgentPosition(x: 4, y: 64, z: 0)
    var session = try! AgentSimulationSession(
        configuration: configuration,
        agents: [
            householdAgent(0, home: homeA),
            householdAgent(1, home: homeA),
            householdAgent(2, home: homeB),
        ],
        simulationID: try! AgentSimulationID(validating: simulationID),
        causalLedgerPolicy: .bounded(maxEvents: 8192)
    )
    guard enablePopulation else { return session }
    try! session.initializePopulationRegistry(
        settlementAnchor: homeA,
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3),
        configuration: .live
    )
    try! session.initializeLocalEcology(observations: [householdHabitat])
    _ = try! session.applyLocalEcologyEndOfTick(
        habitatValidations: [householdHabitat]
    )
    guard enableLifecycle else { return session }
    try! session.setLifecycleEnabled(
        true, configuration: householdLifecycleConfiguration
    )
    guard enableKinship else { return session }
    try! session.setKinshipEnabled(true)
    return session
}

private func householdAdvance(
    recorder: inout AgentReplayRecorder,
    session: inout AgentSimulationSession
) {
    _ = try! recorder.apply(
        .advanceTick(perceptions: [], physicalObservations: []), to: &session
    )
}

private func householdBirth(
    recorder: inout AgentReplayRecorder,
    session: inout AgentSimulationSession,
    position: AgentPosition,
    candidateIndex: Int
) -> AgentBirthRecord {
    while session.pendingBirthSitePlan() == nil {
        householdAdvance(recorder: &recorder, session: &session)
    }
    let plan = session.pendingBirthSitePlan()!
    while session.tick < plan.dueTick {
        householdAdvance(recorder: &recorder, session: &session)
    }
    _ = try! recorder.apply(
        .applyBirthSiteObservation(AgentBirthSiteObservation(
            planID: plan.planID,
            observedTick: session.tick,
            position: position,
            candidateIndex: candidateIndex,
            worldFingerprint: 14_000 + candidateIndex
        )),
        to: &session
    )
    return session.lifecycleSnapshot().births.last!
}

private func householdMigrationObservation(tick: Int) -> AgentMigrationWorldObservation {
    AgentMigrationWorldObservation(
        worldTick: tick,
        candidateIndex: 0,
        entryPosition: AgentPosition(x: 0, y: 64, z: 5),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3),
        route: [
            AgentPosition(x: 0, y: 64, z: 5),
            AgentPosition(x: 0, y: 64, z: 4),
            AgentPosition(x: 0, y: 64, z: 3),
        ]
    )
}

private func householdMutatedCheckpoint(
    _ checkpoint: AgentSessionCheckpoint,
    mutate: (inout [String: Any]) -> Void
) -> AgentSessionCheckpoint {
    var root = try! JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(checkpoint)
    ) as! [String: Any]
    var durable = root["durableState"] as! [String: Any]
    mutate(&durable)
    let mutatedJSON = try! JSONSerialization.data(
        withJSONObject: durable,
        options: [.sortedKeys, .withoutEscapingSlashes]
    )
    let mutatedState = try! AgentCheckpointCodec.decode(
        AgentSessionDurableState.self,
        from: mutatedJSON
    )
    let durableBytes = try! AgentCheckpointCodec.encode(mutatedState)
    let digest = AgentCheckpointDigest.sha256(durableBytes)
    let canonical = try! JSONSerialization.jsonObject(
        with: durableBytes
    ) as! [String: Any]
    let clock = canonical["clock"] as! [String: Any]
    let simulationID = clock["simulationID"] as! String
    let tick = clock["tick"] as! Int
    let simulationDigest = AgentCheckpointDigest.sha256(Data(simulationID.utf8))
    root["durableState"] = canonical
    root["schemaVersion"] = canonical["schemaVersion"]
    root["semanticDigest"] = digest.rawValue
    root["checkpointID"] = "checkpoint-\(simulationDigest.rawValue.prefix(12))-t\(tick)-\(digest.rawValue.prefix(16))"
    return try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self,
        from: JSONSerialization.data(
            withJSONObject: root,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
    )
}

private func householdRestoreRefused(
    _ checkpoint: AgentSessionCheckpoint,
    mutate: (inout [String: Any]) -> Void
) -> Bool {
    do {
        _ = try AgentSimulationSession.restoring(
            householdMutatedCheckpoint(checkpoint, mutate: mutate)
        )
        return false
    } catch {
        return true
    }
}

func runPebbleAgentsHouseholdMembershipSmoke() {
    section("pebble agents households and membership")

    let live = AgentHouseholdConfiguration.live
    check("household live bounds", live.maximumHistoricalHouseholds == 256
        && live.maximumMembershipPeriods == 2048
        && live.maximumActiveHouseholds == 64
        && live.maximumMembersPerHousehold == 16
        && live.maximumHouseholdTransitionsPerTick == 16)
    check("household configuration Codable", (try? AgentCheckpointCodec.decode(
        AgentHouseholdConfiguration.self,
        from: AgentCheckpointCodec.encode(live)
    )) == live)
    check("household rejects historical underflow", {
        do { _ = try AgentHouseholdConfiguration(maximumHistoricalHouseholds: 0); return false }
        catch AgentHouseholdError.invalidConfiguration("historical households") { return true }
        catch { return false }
    }())
    check("household rejects active above historical", {
        do {
            _ = try AgentHouseholdConfiguration(
                maximumHistoricalHouseholds: 2, maximumActiveHouseholds: 3
            )
            return false
        } catch AgentHouseholdError.invalidConfiguration("active households") { return true }
        catch { return false }
    }())
    check("household rejects period underflow", {
        do { _ = try AgentHouseholdConfiguration(maximumMembershipPeriods: 0); return false }
        catch AgentHouseholdError.invalidConfiguration("membership periods") { return true }
        catch { return false }
    }())
    check("household rejects member overflow", {
        do { _ = try AgentHouseholdConfiguration(maximumMembersPerHousehold: 65); return false }
        catch AgentHouseholdError.invalidConfiguration("members per household") { return true }
        catch { return false }
    }())
    check("household rejects transition overflow", {
        do { _ = try AgentHouseholdConfiguration(maximumHouseholdTransitionsPerTick: 257); return false }
        catch AgentHouseholdError.invalidConfiguration("transitions per tick") { return true }
        catch { return false }
    }())

    var noPopulation = householdBase(
        "sim-household-no-population", enablePopulation: false
    )
    let noPopulationBytes = try! noPopulation.durableStateBytes()
    check("household activation without population atomic", {
        do { try noPopulation.setHouseholdsEnabled(true); return false }
        catch AgentSessionError.household(.populationRequired) {
            return (try! noPopulation.durableStateBytes()) == noPopulationBytes
        } catch { return false }
    }())
    var noLifecycle = householdBase(
        "sim-household-no-lifecycle", enableLifecycle: false
    )
    let noLifecycleBytes = try! noLifecycle.durableStateBytes()
    check("household activation without lifecycle atomic", {
        do { try noLifecycle.setHouseholdsEnabled(true); return false }
        catch AgentSessionError.household(.lifecycleRequired) {
            return (try! noLifecycle.durableStateBytes()) == noLifecycleBytes
        } catch { return false }
    }())
    var noKinship = householdBase(
        "sim-household-no-kinship", enableKinship: false
    )
    let noKinshipBytes = try! noKinship.durableStateBytes()
    check("household activation without kinship atomic", {
        do { try noKinship.setHouseholdsEnabled(true); return false }
        catch AgentSessionError.household(.kinshipRequired) {
            return (try! noKinship.durableStateBytes()) == noKinshipBytes
        } catch { return false }
    }())

    var preactivationMigrant = householdBase("sim-household-preactivation-migrant")
    _ = try! preactivationMigrant.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: householdMigrationObservation(tick: preactivationMigrant.tick)
    )
    let migratingID = preactivationMigrant.populationSnapshot().migrations.last!.migrantID
    try! preactivationMigrant.setHouseholdsEnabled(true)
    check("household preactivation migrant remains unassigned in transit",
          preactivationMigrant.populationSnapshot().members.first {
            $0.agentID == migratingID
          }?.status == .migrating
            && (try! preactivationMigrant.currentMembership(of: migratingID)) == nil)

    var session = householdBase("sim-household-durable")
    let v7Checkpoint = try! session.makeCheckpoint()
    let v7Bytes = try! session.durableStateBytes()
    check("household gate off schema v7", v7Checkpoint.schemaVersion == 7)
    check("household gate off omits state", !String(data: v7Bytes, encoding: .utf8)!
        .contains("householdState"))
    var recorder = try! AgentReplayRecorder(checkpoint: v7Checkpoint, session: session)
    _ = try! recorder.apply(
        .setHouseholdsEnabled(true, configuration: .live), to: &session
    )
    let initialized = session.householdSnapshot()
    check("household activation groups by home", initialized.households.count == 2
        && initialized.currentMemberships.count == 3
        && (try! session.members(of: AgentHouseholdID(rawValue: "household_0")!))
            == [AgentID(rawValue: "agent_0")!, AgentID(rawValue: "agent_1")!]
        && (try! session.members(of: AgentHouseholdID(rawValue: "household_1")!))
            == [AgentID(rawValue: "agent_2")!])
    check("household activation schema v8", (try! session.makeCheckpoint()).schemaVersion == 8)
    let activationBytes = try! session.durableStateBytes()
    let activationRestored = try! AgentSimulationSession.restoring(session.makeCheckpoint())
    check("household restart before transition exact",
          try! activationRestored.durableStateBytes() == activationBytes)

    let newAnchor = AgentPosition(x: 8, y: 64, z: 0)
    _ = try! recorder.apply(.formHousehold(
        memberIDs: [AgentID(rawValue: "agent_2")!, AgentID(rawValue: "agent_1")!],
        residenceAnchor: newAnchor
    ), to: &session)
    let formed = AgentHouseholdID(rawValue: "household_2")!
    check("household formation canonical members", try! session.members(of: formed)
        == [AgentID(rawValue: "agent_1")!, AgentID(rawValue: "agent_2")!])
    check("household formation updates homes", try! session.state(for: AgentID(rawValue: "agent_1")!).homePosition == newAnchor
        && (try! session.state(for: AgentID(rawValue: "agent_2")!)).homePosition == newAnchor)
    check("empty source household dissolves", session.householdSnapshot().households.first {
        $0.householdID == AgentHouseholdID(rawValue: "household_1")!
    }?.status == .dissolved)
    check("unrelated founders may cohabit", session.siblingRelation(
        between: AgentID(rawValue: "agent_1")!, and: AgentID(rawValue: "agent_2")!
    ) == .unknownParentage(AgentID(rawValue: "agent_1")!))

    _ = try! recorder.apply(.moveHouseholdMembers(
        memberIDs: [AgentID(rawValue: "agent_1")!],
        householdID: AgentHouseholdID(rawValue: "household_0")!
    ), to: &session)
    check("household move updates current membership", try! session.currentMembership(
        of: AgentID(rawValue: "agent_1")!
    )?.householdID == AgentHouseholdID(rawValue: "household_0")!)
    check("membership history retained", try! session.membershipHistory(
        of: AgentID(rawValue: "agent_1")!
    ).count == 3)

    _ = try! recorder.apply(.setReproductionEnabled(true), to: &session)
    let sameHouseholdBirth = householdBirth(
        recorder: &recorder,
        session: &session,
        position: AgentPosition(x: 2, y: 64, z: 4),
        candidateIndex: 0
    )
    let parents = sameHouseholdBirth.progenitorIDs
    check("same-household birth uses CIV-11", sameHouseholdBirth.newbornID.rawValue == "agent_3")
    check("same-household newborn joins parent household", try! session.currentMembership(
        of: sameHouseholdBirth.newbornID
    )?.householdID == AgentHouseholdID(rawValue: "household_0")!)
    check("newborn home follows shared household", try! session.state(
        for: sameHouseholdBirth.newbornID
    ).homePosition == AgentPosition(x: 0, y: 64, z: 0))

    _ = try! recorder.apply(.moveHouseholdMembers(
        memberIDs: [parents[1]], householdID: formed
    ), to: &session)
    let splitHouseholdBirth = householdBirth(
        recorder: &recorder,
        session: &session,
        position: AgentPosition(x: 3, y: 64, z: 4),
        candidateIndex: 1
    )
    let splitMembership = try! session.currentMembership(of: splitHouseholdBirth.newbornID)!
    check("split-parent birth uses CIV-11", splitHouseholdBirth.newbornID.rawValue == "agent_4")
    check("split-parent newborn gets singleton", try! session.members(
        of: splitMembership.householdID
    ) == [splitHouseholdBirth.newbornID])
    check("split-parent newborn home is birth anchor", splitMembership.residenceAnchor
        == splitHouseholdBirth.position
        && (try! session.state(for: splitHouseholdBirth.newbornID)).homePosition
            == splitHouseholdBirth.position)

    _ = try! recorder.apply(.setReproductionEnabled(false), to: &session)
    let migrantResult = try! recorder.apply(.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: householdMigrationObservation(tick: session.tick)
    ), to: &session)
    let migrant = session.populationSnapshot().migrations.last!.migrantID
    let migrantMembership = try! session.currentMembership(of: migrant)!
    check("admitted migrant gets singleton", migrantResult.tick == session.tick
        && (try! session.members(of: migrantMembership.householdID)) == [migrant])
    check("migrant household anchored on reception", migrantMembership.residenceAnchor
        == AgentPosition(x: 0, y: 64, z: 3))
    check("migrant remains kinship root", try! session.parents(of: migrant) == nil)

    let beforeMortalityKinship = session.kinshipSnapshot()
    _ = try! recorder.apply(.setSurvivalEnabled(true), to: &session)
    _ = try! recorder.apply(
        .setMortalityEnabled(true, configuration: .live), to: &session
    )
    householdAdvance(recorder: &recorder, session: &session)
    check("mortality closes every membership", session.householdSnapshot()
        .currentMemberships.isEmpty)
    check("mortality dissolves empty households", session.householdSnapshot().households
        .allSatisfy { $0.status == .dissolved })
    check("mortality retains household history", session.householdSnapshot()
        .membershipPeriods.count == session.householdSnapshot().totalMembershipPeriodCount)
    check("mortality leaves kinship unchanged", session.kinshipSnapshot().historicalPersons
        == beforeMortalityKinship.historicalPersons
        && session.kinshipSnapshot().parentageRecords == beforeMortalityKinship.parentageRecords)

    let finalCheckpoint = try! session.makeCheckpoint()
    let finalBytes = try! session.durableStateBytes()
    let restored = try! AgentSimulationSession.restoring(finalCheckpoint)
    check("household checkpoint v8", finalCheckpoint.schemaVersion == 8)
    check("household restart exact", try! restored.durableStateBytes() == finalBytes
        && restored.householdSnapshot() == session.householdSnapshot())
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "household-replay")!
    )
    let replayed = try! AgentSessionReplayer.replay(
        checkpoint: v7Checkpoint, journal: journal
    )
    check("household replay schema v8", journal.manifest.schemaVersion == 8)
    check("household replay byte exact", replayed.report.verified
        && (try! replayed.session.durableStateBytes()) == finalBytes
        && replayed.session.householdSnapshot() == session.householdSnapshot())

    let eventKinds = session.causalLedgerSnapshot().events.filter {
        $0.subjectID == sameHouseholdBirth.newbornID
            && $0.simulationTick.rawValue == sameHouseholdBirth.birthTick
    }.map(\.kind)
    check("household birth causal order", eventKinds == [
        .birthSiteValidated, .populationMemberBorn, .kinshipParentageRecorded,
        .householdMembershipStarted, .birthFinalized,
    ])
    check("household IDs never reused", session.householdSnapshot().households
        .map(\.householdID.rawValue) == (0..<session.householdSnapshot().households.count)
            .map { "household_\($0)" })

    var negative = householdBase("sim-household-negative")
    try! negative.setHouseholdsEnabled(true)
    let negativeBytes = try! negative.durableStateBytes()
    check("household empty formation atomic", {
        do {
            _ = try negative.formHousehold(
                memberIDs: [], residenceAnchor: AgentPosition(x: 9, y: 64, z: 0)
            )
            return false
        } catch AgentSessionError.household(.emptyMemberList) {
            return (try! negative.durableStateBytes()) == negativeBytes
        } catch { return false }
    }())
    check("household duplicate member atomic", {
        let id = AgentID(rawValue: "agent_0")!
        do {
            _ = try negative.formHousehold(
                memberIDs: [id, id], residenceAnchor: AgentPosition(x: 9, y: 64, z: 0)
            )
            return false
        } catch AgentSessionError.household(.duplicateMember(id)) {
            return (try! negative.durableStateBytes()) == negativeBytes
        } catch { return false }
    }())
    check("household unknown agent atomic", {
        do {
            _ = try negative.formHousehold(
                memberIDs: [AgentID(rawValue: "agent_99")!],
                residenceAnchor: AgentPosition(x: 9, y: 64, z: 0)
            )
            return false
        } catch AgentSessionError.household(.invalidResident) {
            return (try! negative.durableStateBytes()) == negativeBytes
        } catch { return false }
    }())
    check("household unknown target atomic", {
        do {
            try negative.moveMembers(
                memberIDs: [AgentID(rawValue: "agent_0")!],
                to: AgentHouseholdID(rawValue: "household_99")!
            )
            return false
        } catch AgentSessionError.household(.unknownHousehold) {
            return (try! negative.durableStateBytes()) == negativeBytes
        } catch { return false }
    }())
    check("household no-op move atomic", {
        do {
            try negative.moveMembers(
                memberIDs: [AgentID(rawValue: "agent_0")!],
                to: AgentHouseholdID(rawValue: "household_0")!
            )
            return false
        } catch AgentSessionError.household(.noOp) {
            return (try! negative.durableStateBytes()) == negativeBytes
        } catch { return false }
    }())

    var dissolvedTarget = householdBase("sim-household-dissolved-target")
    try! dissolvedTarget.setHouseholdsEnabled(true)
    _ = try! dissolvedTarget.advanceTick()
    _ = try! dissolvedTarget.formHousehold(
        memberIDs: [AgentID(rawValue: "agent_2")!],
        residenceAnchor: AgentPosition(x: 9, y: 64, z: 0)
    )
    let dissolvedTargetBytes = try! dissolvedTarget.durableStateBytes()
    check("household dissolved target move atomic", {
        let householdID = AgentHouseholdID(rawValue: "household_1")!
        do {
            try dissolvedTarget.moveMembers(
                memberIDs: [AgentID(rawValue: "agent_0")!], to: householdID
            )
            return false
        } catch AgentSessionError.household(.dissolvedHousehold(householdID)) {
            return (try! dissolvedTarget.durableStateBytes()) == dissolvedTargetBytes
        } catch { return false }
    }())

    var historicalBound = householdBase("sim-household-historical-bound")
    let historicalBoundBytes = try! historicalBound.durableStateBytes()
    check("household activation historical capacity atomic", {
        do {
            try historicalBound.setHouseholdsEnabled(true, configuration:
                try AgentHouseholdConfiguration(
                    maximumHistoricalHouseholds: 1,
                    maximumMembershipPeriods: 8,
                    maximumActiveHouseholds: 1
                )
            )
            return false
        } catch AgentSessionError.household(.householdCapacityReached) {
            return (try! historicalBound.durableStateBytes()) == historicalBoundBytes
        } catch { return false }
    }())
    var activeBound = householdBase("sim-household-active-bound")
    let activeBoundBytes = try! activeBound.durableStateBytes()
    check("household activation active capacity atomic", {
        do {
            try activeBound.setHouseholdsEnabled(true, configuration:
                try AgentHouseholdConfiguration(maximumActiveHouseholds: 1)
            )
            return false
        } catch AgentSessionError.household(.activeHouseholdCapacityReached) {
            return (try! activeBound.durableStateBytes()) == activeBoundBytes
        } catch { return false }
    }())
    var periodActivationBound = householdBase("sim-household-period-activation-bound")
    let periodActivationBytes = try! periodActivationBound.durableStateBytes()
    check("household activation period capacity atomic", {
        do {
            try periodActivationBound.setHouseholdsEnabled(true, configuration:
                try AgentHouseholdConfiguration(maximumMembershipPeriods: 2)
            )
            return false
        } catch AgentSessionError.household(.membershipPeriodCapacityReached) {
            return (try! periodActivationBound.durableStateBytes()) == periodActivationBytes
        } catch { return false }
    }())
    var memberActivationBound = householdBase("sim-household-member-activation-bound")
    let memberActivationBytes = try! memberActivationBound.durableStateBytes()
    check("household activation member capacity atomic", {
        do {
            try memberActivationBound.setHouseholdsEnabled(true, configuration:
                try AgentHouseholdConfiguration(maximumMembersPerHousehold: 1)
            )
            return false
        } catch AgentSessionError.household(.memberCapacityReached) {
            return (try! memberActivationBound.durableStateBytes()) == memberActivationBytes
        } catch { return false }
    }())
    var transitionActivationBound = householdBase("sim-household-transition-activation-bound")
    let transitionActivationBytes = try! transitionActivationBound.durableStateBytes()
    check("household activation transition capacity atomic", {
        do {
            try transitionActivationBound.setHouseholdsEnabled(true, configuration:
                try AgentHouseholdConfiguration(maximumHouseholdTransitionsPerTick: 2)
            )
            return false
        } catch AgentSessionError.household(.transitionCapacityReached) {
            return (try! transitionActivationBound.durableStateBytes()) == transitionActivationBytes
        } catch { return false }
    }())

    var historicalFormation = householdBase("sim-household-historical-formation")
    try! historicalFormation.setHouseholdsEnabled(true, configuration:
        try! AgentHouseholdConfiguration(
            maximumHistoricalHouseholds: 2,
            maximumActiveHouseholds: 2
        )
    )
    _ = try! historicalFormation.advanceTick()
    let historicalFormationBytes = try! historicalFormation.durableStateBytes()
    check("household formation historical capacity atomic", {
        do {
            _ = try historicalFormation.formHousehold(
                memberIDs: [AgentID(rawValue: "agent_0")!],
                residenceAnchor: AgentPosition(x: 9, y: 64, z: 0)
            )
            return false
        } catch AgentSessionError.household(.householdCapacityReached) {
            return (try! historicalFormation.durableStateBytes()) == historicalFormationBytes
        } catch { return false }
    }())
    var periodFormation = householdBase("sim-household-period-formation")
    try! periodFormation.setHouseholdsEnabled(true, configuration:
        try! AgentHouseholdConfiguration(maximumMembershipPeriods: 3)
    )
    _ = try! periodFormation.advanceTick()
    let periodFormationBytes = try! periodFormation.durableStateBytes()
    check("household formation period capacity atomic", {
        do {
            _ = try periodFormation.formHousehold(
                memberIDs: [AgentID(rawValue: "agent_0")!],
                residenceAnchor: AgentPosition(x: 9, y: 64, z: 0)
            )
            return false
        } catch AgentSessionError.household(.membershipPeriodCapacityReached) {
            return (try! periodFormation.durableStateBytes()) == periodFormationBytes
        } catch { return false }
    }())
    var memberMoveBound = householdBase("sim-household-member-move-bound")
    try! memberMoveBound.setHouseholdsEnabled(true, configuration:
        try! AgentHouseholdConfiguration(maximumMembersPerHousehold: 2)
    )
    _ = try! memberMoveBound.advanceTick()
    let memberMoveBytes = try! memberMoveBound.durableStateBytes()
    check("household move member capacity atomic", {
        do {
            try memberMoveBound.moveMembers(
                memberIDs: [AgentID(rawValue: "agent_2")!],
                to: AgentHouseholdID(rawValue: "household_0")!
            )
            return false
        } catch AgentSessionError.household(.memberCapacityReached) {
            return (try! memberMoveBound.durableStateBytes()) == memberMoveBytes
        } catch { return false }
    }())
    var transitionBound = householdBase("sim-household-transition-bound")
    try! transitionBound.setHouseholdsEnabled(true, configuration:
        try! AgentHouseholdConfiguration(maximumHouseholdTransitionsPerTick: 3)
    )
    let transitionBoundBytes = try! transitionBound.durableStateBytes()
    check("household same-tick transition capacity atomic", {
        do {
            _ = try transitionBound.formHousehold(
                memberIDs: [AgentID(rawValue: "agent_0")!],
                residenceAnchor: AgentPosition(x: 9, y: 64, z: 0)
            )
            return false
        } catch AgentSessionError.household(.transitionCapacityReached) {
            return (try! transitionBound.durableStateBytes()) == transitionBoundBytes
        } catch { return false }
    }())

    var migrationBound = householdBase("sim-household-migration-bound")
    try! migrationBound.setHouseholdsEnabled(true, configuration:
        try! AgentHouseholdConfiguration(maximumMembershipPeriods: 3)
    )
    _ = try! migrationBound.advanceTick()
    let migrationBoundBytes = try! migrationBound.durableStateBytes()
    check("household migration capacity atomic", {
        do {
            _ = try migrationBound.admitMigration(
                intent: AgentMigrationAdmissionIntent(),
                observation: householdMigrationObservation(tick: migrationBound.tick)
            )
            return false
        } catch AgentSessionError.household(.membershipPeriodCapacityReached) {
            return (try! migrationBound.durableStateBytes()) == migrationBoundBytes
                && migrationBound.populationSummary().nextPopulationOrdinal == 3
        } catch { return false }
    }())

    var birthBound = householdBase("sim-household-birth-bound")
    try! birthBound.setHouseholdsEnabled(true, configuration:
        try! AgentHouseholdConfiguration(maximumMembershipPeriods: 3)
    )
    try! birthBound.setReproductionEnabled(true)
    while birthBound.pendingBirthSitePlan() == nil { _ = try! birthBound.advanceTick() }
    let boundPlan = birthBound.pendingBirthSitePlan()!
    while birthBound.tick < boundPlan.dueTick { _ = try! birthBound.advanceTick() }
    let birthBoundBytes = try! birthBound.durableStateBytes()
    let birthBoundOrdinal = birthBound.populationSummary().nextPopulationOrdinal
    check("household birth capacity atomic", {
        do {
            _ = try birthBound.applyBirthSiteObservation(AgentBirthSiteObservation(
                planID: boundPlan.planID,
                observedTick: birthBound.tick,
                position: AgentPosition(x: 2, y: 64, z: 4),
                candidateIndex: 0,
                worldFingerprint: 16_000
            ))
            return false
        } catch AgentSessionError.household(.membershipPeriodCapacityReached) {
            return (try! birthBound.durableStateBytes()) == birthBoundBytes
                && birthBound.populationSummary().nextPopulationOrdinal == birthBoundOrdinal
        } catch { return false }
    }())

    var deathBound = householdBase("sim-household-death-bound")
    try! deathBound.setHouseholdsEnabled(true, configuration:
        try! AgentHouseholdConfiguration(maximumHouseholdTransitionsPerTick: 3)
    )
    _ = try! deathBound.advanceTick()
    _ = try! deathBound.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: householdMigrationObservation(tick: deathBound.tick)
    )
    deathBound.setSurvivalEnabled(true)
    try! deathBound.setMortalityEnabled(true)
    let deathBoundBytes = try! deathBound.durableStateBytes()
    check("household mortality transition capacity atomic", {
        do { _ = try deathBound.advanceTick(); return false }
        catch AgentSessionError.household(.transitionCapacityReached) {
            return (try! deathBound.durableStateBytes()) == deathBoundBytes
                && deathBound.mortalitySummary().totalDeathCount == 0
        } catch { return false }
    }())

    var corrupt = householdBase("sim-household-corrupt")
    try! corrupt.setHouseholdsEnabled(true)
    _ = try! corrupt.advanceTick()
    _ = try! corrupt.formHousehold(
        memberIDs: [AgentID(rawValue: "agent_2")!],
        residenceAnchor: AgentPosition(x: 9, y: 64, z: 0)
    )
    let corruptCheckpoint = try! corrupt.makeCheckpoint()
    check("household checkpoint duplicate open refused", householdRestoreRefused(
        corruptCheckpoint
    ) { durable in
        var household = durable["householdState"] as! [String: Any]
        var periods = household["membershipPeriods"] as! [[String: Any]]
        let open = periods.first { $0["leftTick"] == nil }!
        periods.append(open)
        household["membershipPeriods"] = periods
        household["totalMembershipPeriodCount"] = periods.count
        durable["householdState"] = household
    })
    check("household checkpoint left tick before join refused", householdRestoreRefused(
        corruptCheckpoint
    ) { durable in
        var household = durable["householdState"] as! [String: Any]
        var periods = household["membershipPeriods"] as! [[String: Any]]
        let index = periods.firstIndex { $0["leftTick"] != nil }!
        periods[index]["leftTick"] = -1
        household["membershipPeriods"] = periods
        durable["householdState"] = household
    })
    check("household checkpoint overlapping periods refused", householdRestoreRefused(
        corruptCheckpoint
    ) { durable in
        var household = durable["householdState"] as! [String: Any]
        var periods = household["membershipPeriods"] as! [[String: Any]]
        let indices = periods.indices.filter { periods[$0]["agentID"] as? String == "agent_2" }
        periods[indices.last!]["joinedTick"] = 0
        household["membershipPeriods"] = periods
        durable["householdState"] = household
    })
    check("household checkpoint home projection refused", householdRestoreRefused(
        corruptCheckpoint
    ) { durable in
        var agents = durable["agents"] as! [[String: Any]]
        agents[0]["homePosition"] = ["x": 99, "y": 64, "z": 99]
        durable["agents"] = agents
    })
    check("household checkpoint duplicate ordinal refused", householdRestoreRefused(
        corruptCheckpoint
    ) { durable in
        var household = durable["householdState"] as! [String: Any]
        var records = household["households"] as! [[String: Any]]
        records[1]["ordinal"] = records[0]["ordinal"]
        household["households"] = records
        durable["householdState"] = household
    })
    check("household checkpoint duplicate ID refused", householdRestoreRefused(
        corruptCheckpoint
    ) { durable in
        var household = durable["householdState"] as! [String: Any]
        var records = household["households"] as! [[String: Any]]
        records[1]["householdID"] = records[0]["householdID"]
        household["households"] = records
        durable["householdState"] = household
    })
    check("household checkpoint active empty refused", householdRestoreRefused(
        corruptCheckpoint
    ) { durable in
        var household = durable["householdState"] as! [String: Any]
        var periods = household["membershipPeriods"] as! [[String: Any]]
        periods.removeAll {
            $0["householdID"] as? String == "household_2" && $0["leftTick"] == nil
        }
        household["membershipPeriods"] = periods
        household["totalMembershipPeriodCount"] = periods.count
        durable["householdState"] = household
    })
    check("household checkpoint dissolved with open member refused", householdRestoreRefused(
        corruptCheckpoint
    ) { durable in
        var household = durable["householdState"] as! [String: Any]
        var records = household["households"] as! [[String: Any]]
        let index = records.firstIndex { $0["householdID"] as? String == "household_2" }!
        records[index]["status"] = "dissolved"
        records[index]["dissolvedTick"] = 1
        household["households"] = records
        durable["householdState"] = household
    })
    check("household checkpoint current member absent from population refused", householdRestoreRefused(
        corruptCheckpoint
    ) { durable in
        var population = durable["populationRegistry"] as! [String: Any]
        var members = population["members"] as! [[String: Any]]
        members.removeAll { $0["agentID"] as? String == "agent_0" }
        population["members"] = members
        durable["populationRegistry"] = population
    })
    check("household checkpoint foreign causal reference refused", householdRestoreRefused(
        corruptCheckpoint
    ) { durable in
        var household = durable["householdState"] as! [String: Any]
        var eventID = household["initializedEventID"] as! [String: Any]
        eventID["simulationID"] = "foreign-household-simulation"
        household["initializedEventID"] = eventID
        durable["householdState"] = household
    })
    check("household unknown checkpoint version refused", householdRestoreRefused(
        corruptCheckpoint
    ) { durable in
        durable["schemaVersion"] = 9
    })

    let deadAgent = AgentID(rawValue: "agent_0")!
    let deadBytes = try! session.durableStateBytes()
    check("household dead agent formation refused atomic", {
        do {
            _ = try session.formHousehold(
                memberIDs: [deadAgent],
                residenceAnchor: AgentPosition(x: 10, y: 64, z: 0)
            )
            return false
        } catch AgentSessionError.household(.invalidResident(deadAgent)) {
            return (try! session.durableStateBytes()) == deadBytes
        } catch { return false }
    }())
}
