import Foundation
import PebbleAgents

private let gateFB07Origin = AgentPosition(x: 0, y: 64, z: 0)
private let gateFB07BirthPosition = AgentPosition(x: 0, y: 64, z: 4)
private let gateFB07EastID = AgentSettlementID(rawValue: "settlement-east")!
private let gateFB07Habitat = AgentEcologyHabitatObservation(
    worldTick: 0, candidateIndex: 0,
    habitatPosition: AgentPosition(x: 1, y: 63, z: 0),
    foragePosition: AgentPosition(x: 1, y: 64, z: 0),
    habitatFingerprint: 70_032, distanceFromSettlement: 1,
    directionIndex: 0, worldReadCount: 4
)

private func gateFB07Agent(_ ordinal: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: ordinal, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0.1, safety: 1),
        health: 100, fear: 0, homePosition: gateFB07Origin,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "Gate F Blocker 07 temporal fixture",
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

private func gateFB07Session(
    _ simulationID: String,
    reproductionEnabled: Bool = true,
    causalMaximumEvents: Int = 65_536
) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 707, nearbyRadius: 8, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 128)
        ),
        agents: (0..<3).map(gateFB07Agent),
        simulationID: try! AgentSimulationID(validating: simulationID),
        causalLedgerPolicy: .bounded(maxEvents: causalMaximumEvents)
    )
    session.setSurvivalEnabled(true)
    try! session.initializePopulationRegistry(
        settlementAnchor: gateFB07Origin,
        receptionPosition: gateFB07Origin,
        configuration: try! AgentPopulationConfiguration(
            maximumActivePopulation: 8,
            maximumMigrationRecords: 16
        )
    )
    try! session.initializeLocalEcology(observations: [gateFB07Habitat])
    _ = try! session.applyLocalEcologyEndOfTick(
        habitatValidations: [gateFB07Habitat]
    )
    try! session.setMortalityEnabled(true)
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
    try! session.setHomeostasisEnabled(
        true,
        configuration: try! AgentHomeostasisConfiguration(
            ageVulnerabilityStartTicks: 10_000,
            incapacityHealthThreshold: 20
        )
    )
    try! session.setGeneticsEnabled(true)
    try! session.setKinshipEnabled(true)
    try! session.setHouseholdsEnabled(true)
    try! session.setDependentCareEnabled(true)
    try! session.setChildhoodV2Enabled(true)
    try! session.setFamilyV1Enabled(true)
    try! session.initializePopulationScaling(
        additionalSettlements: [AgentPopulationSettlement(
            settlementID: gateFB07EastID,
            anchor: AgentPosition(x: 16, y: 64, z: 0),
            receptionPosition: AgentPosition(x: 16, y: 64, z: 0),
            capacity: 2, residentIDs: [], inTransitIDs: []
        )],
        configuration: try! AgentPopulationScaleConfiguration(
            maximumSettlements: 2, maximumLiveAgents: 8,
            maximumNearAgents: 2, nearMaintenanceCadence: 2,
            dormantMaintenanceCadence: 8, rotationIntervalTicks: 4,
            maximumFidelityTransitionHistory: 32,
            maximumSettlementMigrationHistory: 8,
            maximumConcurrentSettlementMigrations: 1,
            maximumSettlementMigrationRouteLength: 32
        )
    )
    if reproductionEnabled {
        try! session.setReproductionEnabled(true)
    }
    return session
}

private func gateFB07Receipt(
    _ session: AgentSimulationSession,
    id: String,
    kind: AgentFamilyInteractionKind,
    actorID: AgentID,
    counterpartyID: AgentID,
    communicationVerified: Bool = true
) -> AgentFamilyInteractionReceipt {
    let states = Dictionary(uniqueKeysWithValues:
        session.snapshot().agents.map { (AgentID(rawValue: $0.id)!, $0) }
    )
    return AgentFamilyInteractionReceipt(
        receiptID: id, kind: kind,
        actorID: actorID, counterpartyID: counterpartyID,
        observedTick: session.tick,
        actorPosition: states[actorID]!.position,
        counterpartyPosition: states[counterpartyID]!.position,
        communicationVerified: communicationVerified
    )
}

private func gateFB07Plan(
    _ session: inout AgentSimulationSession
) -> AgentReproductionPlan {
    while session.pendingBirthSitePlan() == nil {
        _ = try! session.advanceTick()
    }
    return session.pendingBirthSitePlan()!
}

private func gateFB07AdvanceToDue(
    _ session: inout AgentSimulationSession,
    plan: AgentReproductionPlan
) {
    while session.tick < plan.dueTick {
        _ = try! session.advanceTick()
    }
}

private func gateFB07Birth(
    _ session: inout AgentSimulationSession,
    plan: AgentReproductionPlan
) -> AgentBirthRecord {
    try! session.applyBirthSiteObservation(AgentBirthSiteObservation(
        planID: plan.planID, observedTick: session.tick,
        position: gateFB07BirthPosition, candidateIndex: 0,
        worldFingerprint: 70_001
    ))!
}

private func gateFB07Union(
    _ session: inout AgentSimulationSession,
    parents: [AgentID],
    prefix: String
) -> AgentUnionRecord {
    let ordered = parents.sorted()
    let proposal = try! session.proposeUnion(gateFB07Receipt(
        session, id: "\(prefix)-proposal", kind: .unionProposal,
        actorID: ordered[0], counterpartyID: ordered[1]
    ))
    return try! session.acceptUnion(
        proposalID: proposal.proposalID,
        receipt: gateFB07Receipt(
            session, id: "\(prefix)-accept", kind: .unionAcceptance,
            actorID: ordered[1], counterpartyID: ordered[0]
        )
    )
}

private func gateFB07Cofound(
    _ session: inout AgentSimulationSession,
    parents: [AgentID],
    prefix: String
) -> AgentHouseRecord {
    let ordered = parents.sorted()
    return try! session.coFoundHouse(
        founderIDs: ordered,
        receipts: [
            gateFB07Receipt(
                session, id: "\(prefix)-cofound-a",
                kind: .houseCoFoundation,
                actorID: ordered[0], counterpartyID: ordered[1]
            ),
            gateFB07Receipt(
                session, id: "\(prefix)-cofound-b",
                kind: .houseCoFoundation,
                actorID: ordered[1], counterpartyID: ordered[0]
            ),
        ]
    )
}

private func gateFB07Join(
    _ session: inout AgentSimulationSession,
    houseID: AgentHouseID,
    joiningID: AgentID,
    acceptingID: AgentID,
    prefix: String
) {
    try! session.joinHouse(
        houseID,
        request: gateFB07Receipt(
            session, id: "\(prefix)-join-request",
            kind: .houseJoinRequest,
            actorID: joiningID, counterpartyID: acceptingID
        ),
        acceptance: gateFB07Receipt(
            session, id: "\(prefix)-join-accept",
            kind: .houseJoinAcceptance,
            actorID: acceptingID, counterpartyID: joiningID
        )
    )
}

private func gateFB07BirthMemberships(
    _ session: AgentSimulationSession,
    childID: AgentID
) -> [AgentHouseMembershipPeriod] {
    session.familySnapshot().houseMembershipPeriods.filter {
        $0.agentID == childID && $0.basis == .sharedParentHouseAtBirth
    }
}

private func gateFB07MutatedCheckpoint(
    _ checkpoint: AgentSessionCheckpoint,
    mutate: (inout [String: Any]) -> Void
) -> AgentSessionCheckpoint {
    var root = try! JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(checkpoint)
    ) as! [String: Any]
    var durable = root["durableState"] as! [String: Any]
    mutate(&durable)
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
    let simulationDigest = AgentCheckpointDigest.sha256(Data(simulationID.utf8))
    root["durableState"] = canonical
    root["schemaVersion"] = canonical["schemaVersion"]
    root["semanticDigest"] = digest.rawValue
    root["checkpointID"] = "checkpoint-\(simulationDigest.rawValue.prefix(12))"
        + "-t\(tick)-\(digest.rawValue.prefix(16))"
    return try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self,
        from: JSONSerialization.data(
            withJSONObject: root,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
    )
}

private func gateFB07RestoreRejects(
    _ checkpoint: AgentSessionCheckpoint,
    mutate: (inout [String: Any]) -> Void
) -> Bool {
    do {
        _ = try AgentSimulationSession.restoring(
            gateFB07MutatedCheckpoint(checkpoint, mutate: mutate)
        )
        return false
    } catch {
        return true
    }
}

private func gateFB07CurrentAuthorityIsSingular(
    _ session: AgentSimulationSession
) -> Bool {
    let agents = session.snapshot().agents
    let population = session.populationSnapshot().members
    let lifecycle = session.lifecycleSnapshot().members
    let fidelity = session.populationScaleSnapshot().fidelityRecords
    let households = session.householdSnapshot().membershipPeriods
    return agents.allSatisfy { state in
        let id = AgentID(rawValue: state.id)!
        return population.filter {
            $0.agentID == id
                && ($0.status == .founderResident
                    || $0.status == .resident || $0.status == .migrating)
        }.count == 1
            && lifecycle.filter { $0.agentID == id }.count == 1
            && fidelity.filter { $0.agentID == id }.count == 1
            && households.filter { $0.agentID == id && $0.leftTick == nil }.count == 1
    }
}

private func gateFB07FixtureDigest(
    _ session: AgentSimulationSession
) -> String {
    AgentCheckpointDigest.sha256(try! session.durableStateBytes()).rawValue
}

private struct GateFB07FreshFixture {
    let session: AgentSimulationSession
    let birth: AgentBirthRecord
    let parentage: AgentParentageRecord
    let union: AgentUnionRecord
    let house: AgentHouseRecord
}

private struct GateFB07FreshReport: Encodable {
    let schemaVersion: Int
    let fixture: String
    let phase: String
    let tick: Int
    let checkpointSchema: Int
    let observerSchema: Int
    let birthTick: Int
    let birthEventSequence: AgentCausalSequence
    let parentageRecordedSequence: AgentCausalSequence
    let unionActivationSequence: AgentCausalSequence
    let houseFoundationSequence: AgentCausalSequence
    let founderJoinSequences: [AgentCausalSequence]
    let childBirthMemberships: Int
    let durableBytes: Int
    let semanticDigest: String
    let continuationDigest: String?
    let replayedBirths: Int
    let replayedHouseFoundations: Int
    let replayedChildMemberships: Int
    let duplicateCurrentAuthority: Int
    let assertions: [String: Bool]
}

private func gateFB07FreshFixture(_ fixture: String) -> GateFB07FreshFixture {
    var session = gateFB07Session("gate-f-b07-fresh-\(fixture)")
    let plan = gateFB07Plan(&session)
    gateFB07AdvanceToDue(&session, plan: plan)
    let birth: AgentBirthRecord
    let union: AgentUnionRecord
    let house: AgentHouseRecord
    if fixture == "post" {
        birth = gateFB07Birth(&session, plan: plan)
        union = gateFB07Union(
            &session, parents: plan.progenitorIDs, prefix: "fresh-post"
        )
        house = gateFB07Cofound(
            &session, parents: plan.progenitorIDs, prefix: "fresh-post"
        )
    } else {
        union = gateFB07Union(
            &session, parents: plan.progenitorIDs, prefix: "fresh-pre"
        )
        house = gateFB07Cofound(
            &session, parents: plan.progenitorIDs, prefix: "fresh-pre"
        )
        birth = gateFB07Birth(&session, plan: plan)
    }
    let parentage = session.kinshipSnapshot().parentageRecords.first {
        $0.childID == birth.newbornID
    }!
    return GateFB07FreshFixture(
        session: session, birth: birth, parentage: parentage,
        union: union, house: house
    )
}

private func gateFB07WriteJSON<T: Encodable>(_ value: T, to url: URL) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    try encoder.encode(value).write(to: url, options: .atomic)
}

private func gateFB07FreshProcessIfRequested() -> Bool {
    let environment = ProcessInfo.processInfo.environment
    guard let phase = environment["PEBBLELAB_GATE_F_BLOCKER_07_FRESH_PHASE"]
    else { return false }
    guard let fixture = environment["PEBBLELAB_GATE_F_BLOCKER_07_FIXTURE"],
          ["post", "pre"].contains(fixture),
          let out = environment["PEBBLELAB_GATE_F_BLOCKER_07_OUT"] else {
        preconditionFailure("invalid Gate F Blocker 07 fresh-process environment")
    }
    let root = URL(fileURLWithPath: out, isDirectory: true)
    try! FileManager.default.createDirectory(
        at: root, withIntermediateDirectories: true
    )
    let checkpointURL = root.appendingPathComponent("checkpoint_v35.json")
    let durableURL = root.appendingPathComponent("durable_state.json")
    if phase == "write" {
        let built = gateFB07FreshFixture(fixture)
        let checkpoint = try! built.session.makeCheckpoint()
        let checkpointBytes = try! AgentCheckpointCodec.encode(checkpoint)
        let durableBytes = try! built.session.durableStateBytes()
        try! checkpointBytes.write(to: checkpointURL, options: .atomic)
        try! durableBytes.write(to: durableURL, options: .atomic)
        let memberships = gateFB07BirthMemberships(
            built.session, childID: built.birth.newbornID
        )
        let founderJoins = built.session.familySnapshot().houseMembershipPeriods
            .filter {
                $0.houseID == built.house.houseID && $0.basis == .founder
            }.map { $0.joinedEventID.sequence }.sorted()
        let expectedMemberships = fixture == "post" ? 0 : 1
        let report = GateFB07FreshReport(
            schemaVersion: 1, fixture: fixture, phase: "write-checkpoint-exit",
            tick: built.session.tick, checkpointSchema: checkpoint.schemaVersion,
            observerSchema: 13, birthTick: built.birth.birthTick,
            birthEventSequence:
                built.parentage.sourcePopulationBornEventID.sequence,
            parentageRecordedSequence: built.parentage.recordedEventID.sequence,
            unionActivationSequence: built.union.activationEventID.sequence,
            houseFoundationSequence: built.house.foundationEventID.sequence,
            founderJoinSequences: founderJoins,
            childBirthMemberships: memberships.count,
            durableBytes: durableBytes.count,
            semanticDigest: checkpoint.semanticDigest.rawValue,
            continuationDigest: nil, replayedBirths: 0,
            replayedHouseFoundations: 0, replayedChildMemberships: 0,
            duplicateCurrentAuthority:
                gateFB07CurrentAuthorityIsSingular(built.session) ? 0 : 1,
            assertions: [
                "schema_35": checkpoint.schemaVersion == 35,
                "birth_membership_exact": memberships.count == expectedMemberships,
                "causal_order_exact": fixture == "post"
                    ? built.parentage.sourcePopulationBornEventID.sequence
                        < built.house.foundationEventID.sequence
                    : built.house.foundationEventID.sequence
                        < built.parentage.sourcePopulationBornEventID.sequence,
                "singular_current_authority":
                    gateFB07CurrentAuthorityIsSingular(built.session),
            ]
        )
        try! gateFB07WriteJSON(
            report, to: root.appendingPathComponent("process_1_report.json")
        )
        check("fresh \(fixture) process 1 writes exact schema 35 fixture",
              report.assertions.values.allSatisfy { $0 })
        return true
    }
    precondition(phase == "restore")
    let checkpointBytes = try! Data(contentsOf: checkpointURL)
    let savedDurableBytes = try! Data(contentsOf: durableURL)
    let checkpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self, from: checkpointBytes
    )
    var session = try! AgentSimulationSession.restoring(checkpoint)
    let restoredBytes = try! session.durableStateBytes()
    let familyBefore = session.familySnapshot()
    let lifecycleBefore = session.lifecycleSnapshot()
    let parentage = session.kinshipSnapshot().parentageRecords.last!
    let childID = parentage.childID
    let membershipsBefore = gateFB07BirthMemberships(session, childID: childID)
    let observerBytesBefore = try! session.durableStateBytes()
    let observer = session.observerSnapshot(
        worldBinding: try! AgentObserverWorldBinding(
            worldID: "gate-f-b07-fresh-world",
            storageIdentity: "memory:gate-f-b07-fresh", seed: 707,
            dimension: 0, observedWorldTick: session.tick
        )
    )
    let observerReadOnly = (try! session.durableStateBytes()) == observerBytesBefore
    _ = try! session.advanceTick()
    let continued = try! session.makeCheckpoint()
    let replayedBirths = session.lifecycleSnapshot().totalBirthCount
        - lifecycleBefore.totalBirthCount
    let replayedHouses = session.familySnapshot().houses.count
        - familyBefore.houses.count
    let replayedMemberships = gateFB07BirthMemberships(session, childID: childID).count
        - membershipsBefore.count
    let house = familyBefore.houses.last!
    let union = familyBefore.unions.last!
    let founderJoins = familyBefore.houseMembershipPeriods.filter {
        $0.houseID == house.houseID && $0.basis == .founder
    }.map { $0.joinedEventID.sequence }.sorted()
    let expectedMemberships = fixture == "post" ? 0 : 1
    let report = GateFB07FreshReport(
        schemaVersion: 1, fixture: fixture,
        phase: "fresh-restore-continuation",
        tick: session.tick, checkpointSchema: checkpoint.schemaVersion,
        observerSchema: observer.header.schemaVersion,
        birthTick: parentage.birthTick,
        birthEventSequence: parentage.sourcePopulationBornEventID.sequence,
        parentageRecordedSequence: parentage.recordedEventID.sequence,
        unionActivationSequence: union.activationEventID.sequence,
        houseFoundationSequence: house.foundationEventID.sequence,
        founderJoinSequences: founderJoins,
        childBirthMemberships: membershipsBefore.count,
        durableBytes: restoredBytes.count,
        semanticDigest: checkpoint.semanticDigest.rawValue,
        continuationDigest: continued.semanticDigest.rawValue,
        replayedBirths: replayedBirths,
        replayedHouseFoundations: replayedHouses,
        replayedChildMemberships: replayedMemberships,
        duplicateCurrentAuthority:
            gateFB07CurrentAuthorityIsSingular(session) ? 0 : 1,
        assertions: [
            "fresh_restore_byte_exact": restoredBytes == savedDurableBytes,
            "birth_membership_exact": membershipsBefore.count == expectedMemberships,
            "observer_schema_13": observer.header.schemaVersion == 13,
            "observer_read_only": observerReadOnly,
            "zero_replayed_births": replayedBirths == 0,
            "zero_replayed_houses": replayedHouses == 0,
            "zero_replayed_memberships": replayedMemberships == 0,
            "singular_current_authority":
                gateFB07CurrentAuthorityIsSingular(session),
        ]
    )
    try! gateFB07WriteJSON(
        report, to: root.appendingPathComponent("process_2_report.json")
    )
    check("fresh \(fixture) process 2 restores and continues exactly",
          report.assertions.values.allSatisfy { $0 })
    return true
}

func runPebbleAgentsGateFBlocker07Smoke() {
    section("Gate F Blocker 07 same-tick birth / Family causal authority")
    if gateFB07FreshProcessIfRequested() { return }

    var postBirth = gateFB07Session("gate-f-b07-post-birth")
    let postPlan = gateFB07Plan(&postBirth)
    gateFB07AdvanceToDue(&postBirth, plan: postPlan)
    let postBirthRecord = gateFB07Birth(&postBirth, plan: postPlan)
    let postParentage = postBirth.kinshipSnapshot().parentageRecords.first {
        $0.childID == postBirthRecord.newbornID
    }!
    let postUnion = gateFB07Union(
        &postBirth, parents: postPlan.progenitorIDs, prefix: "post"
    )
    let postParents = postPlan.progenitorIDs.sorted()
    let beforeExpectedRefusal = try! postBirth.durableStateBytes()
    let expectedRefusalWasAtomic: Bool
    do {
        _ = try postBirth.coFoundHouse(
            founderIDs: postParents,
            receipts: [
                gateFB07Receipt(
                    postBirth, id: "post-refused-a",
                    kind: .houseCoFoundation,
                    actorID: postParents[0], counterpartyID: postParents[1],
                    communicationVerified: false
                ),
                gateFB07Receipt(
                    postBirth, id: "post-refused-b",
                    kind: .houseCoFoundation,
                    actorID: postParents[1], counterpartyID: postParents[0]
                ),
            ]
        )
        expectedRefusalWasAtomic = false
    } catch {
        expectedRefusalWasAtomic =
            (try! postBirth.durableStateBytes()) == beforeExpectedRefusal
    }
    let houseOrdinalBefore = postBirth.familySnapshot().houses.count
    let postHouse = gateFB07Cofound(
        &postBirth, parents: postPlan.progenitorIDs, prefix: "post"
    )
    let postFounderJoins = postBirth.familySnapshot().houseMembershipPeriods
        .filter { $0.houseID == postHouse.houseID && $0.basis == .founder }
    check("Evaluation 07 exact post-birth same-tick co-foundation succeeds",
          postHouse.foundationTick == postBirthRecord.birthTick
            && postHouse.foundationEventID.sequence
                > postParentage.sourcePopulationBornEventID.sequence)
    check("post-birth same-tick house consumes exactly one house identity",
          expectedRefusalWasAtomic
            && postBirth.familySnapshot().houses.count == houseOrdinalBefore + 1)
    check("rejected co-foundation preserves exact retry identity and ordinals",
          expectedRefusalWasAtomic
            && postHouse.houseID.rawValue
                == String(format: "house-%08d", houseOrdinalBefore + 1))
    check("post-birth same-tick house creates no retroactive child authority",
          gateFB07BirthMemberships(
              postBirth, childID: postBirthRecord.newbornID
          ).isEmpty)
    check("post-birth causal evidence orders birth before union and house",
          postParentage.sourcePopulationBornEventID.sequence
            < postParentage.recordedEventID.sequence
            && postParentage.sourcePopulationBornEventID.sequence
                < postUnion.activationEventID.sequence
            && postUnion.activationEventID.sequence
                < postHouse.foundationEventID.sequence
            && postFounderJoins.allSatisfy {
                postHouse.foundationEventID.sequence < $0.joinedEventID.sequence
            })
    let postBytes = try! postBirth.durableStateBytes()
    let postCheckpoint = try! postBirth.makeCheckpoint()
    let postRestored = try! AgentSimulationSession.restoring(postCheckpoint)
    check("post-birth schema 35 restore is byte exact",
          postCheckpoint.schemaVersion == 35
            && (try! postRestored.durableStateBytes()) == postBytes)
    check("post-birth restore never reinterprets child membership",
          gateFB07BirthMemberships(
              postRestored, childID: postBirthRecord.newbornID
          ).isEmpty)
    var postContinued = postRestored
    _ = try! postContinued.advanceTick()
    check("post-birth continuation has no delayed or duplicate Family effect",
          gateFB07BirthMemberships(
              postContinued, childID: postBirthRecord.newbornID
          ).isEmpty
            && postContinued.familySnapshot().houses.count
                == postRestored.familySnapshot().houses.count)

    var preBirth = gateFB07Session("gate-f-b07-pre-birth")
    let prePlan = gateFB07Plan(&preBirth)
    gateFB07AdvanceToDue(&preBirth, plan: prePlan)
    _ = gateFB07Union(&preBirth, parents: prePlan.progenitorIDs, prefix: "pre")
    let preHouse = gateFB07Cofound(
        &preBirth, parents: prePlan.progenitorIDs, prefix: "pre"
    )
    let preBirthRecord = gateFB07Birth(&preBirth, plan: prePlan)
    let preParentage = preBirth.kinshipSnapshot().parentageRecords.first {
        $0.childID == preBirthRecord.newbornID
    }!
    let preMemberships = gateFB07BirthMemberships(
        preBirth, childID: preBirthRecord.newbornID
    )
    check("same-tick pre-birth shared house grants one birth membership",
          preMemberships.count == 1
            && preMemberships[0].houseID == preHouse.houseID)
    check("same-tick pre-birth causal evidence orders foundation before birth",
          preHouse.foundationTick == preBirthRecord.birthTick
            && preHouse.foundationEventID.sequence
                < preParentage.sourcePopulationBornEventID.sequence
            && preParentage.sourcePopulationBornEventID.sequence
                < preParentage.recordedEventID.sequence
            && preMemberships[0].joinedEventID.sequence
                > preParentage.recordedEventID.sequence)
    let preBytes = try! preBirth.durableStateBytes()
    let preCheckpoint = try! preBirth.makeCheckpoint()
    let preRestored = try! AgentSimulationSession.restoring(preCheckpoint)
    check("same-tick pre-birth schema 35 restore is exact",
          preCheckpoint.schemaVersion == 35
            && (try! preRestored.durableStateBytes()) == preBytes
            && gateFB07BirthMemberships(
                preRestored, childID: preBirthRecord.newbornID
            ).count == 1)

    var previousTick = gateFB07Session(
        "gate-f-b07-previous-tick", reproductionEnabled: false
    )
    while previousTick.tick < 2 { _ = try! previousTick.advanceTick() }
    let expectedPreviousParents = [
        AgentID(rawValue: "agent_0")!, AgentID(rawValue: "agent_1")!,
    ]
    _ = gateFB07Union(
        &previousTick, parents: expectedPreviousParents, prefix: "previous"
    )
    let previousHouse = gateFB07Cofound(
        &previousTick, parents: expectedPreviousParents, prefix: "previous"
    )
    _ = try! previousTick.advanceTick()
    try! previousTick.setReproductionEnabled(true)
    let previousPlan = gateFB07Plan(&previousTick)
    gateFB07AdvanceToDue(&previousTick, plan: previousPlan)
    let previousBirth = gateFB07Birth(&previousTick, plan: previousPlan)
    check("previous-tick shared house grants one birth membership",
          previousPlan.progenitorIDs == expectedPreviousParents
            && previousHouse.foundationTick < previousBirth.birthTick
            && gateFB07BirthMemberships(
                previousTick, childID: previousBirth.newbornID
            ).count == 1)

    var joinBefore = gateFB07Session("gate-f-b07-join-before")
    let joinBeforePlan = gateFB07Plan(&joinBefore)
    _ = gateFB07Union(
        &joinBefore, parents: joinBeforePlan.progenitorIDs,
        prefix: "join-before"
    )
    let joinBeforeParents = joinBeforePlan.progenitorIDs.sorted()
    let joinBeforeHouse = try! joinBefore.foundHouse(
        founderID: joinBeforeParents[0], operationID: "join-before-found"
    )
    gateFB07AdvanceToDue(&joinBefore, plan: joinBeforePlan)
    gateFB07Join(
        &joinBefore, houseID: joinBeforeHouse.houseID,
        joiningID: joinBeforeParents[1], acceptingID: joinBeforeParents[0],
        prefix: "join-before"
    )
    let joinBeforePeriod = joinBefore.familySnapshot().houseMembershipPeriods
        .first { $0.houseID == joinBeforeHouse.houseID
            && $0.agentID == joinBeforeParents[1] }!
    let joinBeforeBirth = gateFB07Birth(&joinBefore, plan: joinBeforePlan)
    let joinBeforeParentage = joinBefore.kinshipSnapshot().parentageRecords.first {
        $0.childID == joinBeforeBirth.newbornID
    }!
    check("parent joined earlier in birth tick counts at birth",
          joinBeforePeriod.joinedTick == joinBeforeBirth.birthTick
            && joinBeforePeriod.joinedEventID.sequence
                < joinBeforeParentage.sourcePopulationBornEventID.sequence
            && gateFB07BirthMemberships(
                joinBefore, childID: joinBeforeBirth.newbornID
            ).count == 1)

    var joinAfter = gateFB07Session("gate-f-b07-join-after")
    let joinAfterPlan = gateFB07Plan(&joinAfter)
    _ = gateFB07Union(
        &joinAfter, parents: joinAfterPlan.progenitorIDs,
        prefix: "join-after"
    )
    let joinAfterParents = joinAfterPlan.progenitorIDs.sorted()
    let joinAfterHouse = try! joinAfter.foundHouse(
        founderID: joinAfterParents[0], operationID: "join-after-found"
    )
    gateFB07AdvanceToDue(&joinAfter, plan: joinAfterPlan)
    let joinAfterBirth = gateFB07Birth(&joinAfter, plan: joinAfterPlan)
    let joinAfterParentage = joinAfter.kinshipSnapshot().parentageRecords.first {
        $0.childID == joinAfterBirth.newbornID
    }!
    gateFB07Join(
        &joinAfter, houseID: joinAfterHouse.houseID,
        joiningID: joinAfterParents[1], acceptingID: joinAfterParents[0],
        prefix: "join-after"
    )
    let joinAfterPeriod = joinAfter.familySnapshot().houseMembershipPeriods
        .first { $0.houseID == joinAfterHouse.houseID
            && $0.agentID == joinAfterParents[1] }!
    check("parent joined later in birth tick does not count retroactively",
          joinAfterPeriod.joinedTick == joinAfterBirth.birthTick
            && joinAfterPeriod.joinedEventID.sequence
                > joinAfterParentage.sourcePopulationBornEventID.sequence
            && gateFB07BirthMemberships(
                joinAfter, childID: joinAfterBirth.newbornID
            ).isEmpty)

    var leaveBefore = gateFB07Session("gate-f-b07-leave-before")
    let leaveBeforePlan = gateFB07Plan(&leaveBefore)
    _ = gateFB07Union(
        &leaveBefore, parents: leaveBeforePlan.progenitorIDs,
        prefix: "leave-before"
    )
    let leaveBeforeHouse = gateFB07Cofound(
        &leaveBefore, parents: leaveBeforePlan.progenitorIDs,
        prefix: "leave-before"
    )
    gateFB07AdvanceToDue(&leaveBefore, plan: leaveBeforePlan)
    let leavingBeforeID = leaveBeforePlan.progenitorIDs.sorted()[1]
    try! leaveBefore.leaveHouse(
        leaveBeforeHouse.houseID, agentID: leavingBeforeID,
        operationID: "leave-before-birth"
    )
    let leftBefore = leaveBefore.familySnapshot().houseMembershipPeriods.first {
        $0.houseID == leaveBeforeHouse.houseID && $0.agentID == leavingBeforeID
    }!
    let leaveBeforeBirth = gateFB07Birth(&leaveBefore, plan: leaveBeforePlan)
    let leaveBeforeParentage = leaveBefore.kinshipSnapshot().parentageRecords.first {
        $0.childID == leaveBeforeBirth.newbornID
    }!
    check("parent left earlier in birth tick does not count at birth",
          leftBefore.leftTick == leaveBeforeBirth.birthTick
            && leftBefore.leftEventID!.sequence
                < leaveBeforeParentage.sourcePopulationBornEventID.sequence
            && gateFB07BirthMemberships(
                leaveBefore, childID: leaveBeforeBirth.newbornID
            ).isEmpty)

    var leaveAfter = gateFB07Session("gate-f-b07-leave-after")
    let leaveAfterPlan = gateFB07Plan(&leaveAfter)
    _ = gateFB07Union(
        &leaveAfter, parents: leaveAfterPlan.progenitorIDs,
        prefix: "leave-after"
    )
    let leaveAfterHouse = gateFB07Cofound(
        &leaveAfter, parents: leaveAfterPlan.progenitorIDs,
        prefix: "leave-after"
    )
    gateFB07AdvanceToDue(&leaveAfter, plan: leaveAfterPlan)
    let leaveAfterBirth = gateFB07Birth(&leaveAfter, plan: leaveAfterPlan)
    let leaveAfterParentage = leaveAfter.kinshipSnapshot().parentageRecords.first {
        $0.childID == leaveAfterBirth.newbornID
    }!
    let leavingAfterID = leaveAfterPlan.progenitorIDs.sorted()[1]
    try! leaveAfter.leaveHouse(
        leaveAfterHouse.houseID, agentID: leavingAfterID,
        operationID: "leave-after-birth"
    )
    let leftAfter = leaveAfter.familySnapshot().houseMembershipPeriods.first {
        $0.houseID == leaveAfterHouse.houseID && $0.agentID == leavingAfterID
    }!
    check("parent left later in birth tick remains active at birth",
          leftAfter.leftTick == leaveAfterBirth.birthTick
            && leftAfter.leftEventID!.sequence
                > leaveAfterParentage.sourcePopulationBornEventID.sequence
            && gateFB07BirthMemberships(
                leaveAfter, childID: leaveAfterBirth.newbornID
            ).count == 1)
    let leaveAfterCheckpoint = try! leaveAfter.makeCheckpoint()
    let leaveAfterRestored = try! AgentSimulationSession.restoring(
        leaveAfterCheckpoint
    )
    check("same-tick leave-after historical authority restores exactly",
          gateFB07BirthMemberships(
              leaveAfterRestored, childID: leaveAfterBirth.newbornID
          ).count == 1
            && (try! leaveAfterRestored.durableStateBytes())
                == (try! leaveAfter.durableStateBytes()))

    var compacted = gateFB07Session(
        "gate-f-b07-causal-retention", causalMaximumEvents: 48
    )
    let compactedPlan = gateFB07Plan(&compacted)
    gateFB07AdvanceToDue(&compacted, plan: compactedPlan)
    _ = gateFB07Union(
        &compacted, parents: compactedPlan.progenitorIDs,
        prefix: "compacted"
    )
    let compactedHouse = gateFB07Cofound(
        &compacted, parents: compactedPlan.progenitorIDs,
        prefix: "compacted"
    )
    let compactedBirth = gateFB07Birth(&compacted, plan: compactedPlan)
    let compactedParentage = compacted.kinshipSnapshot().parentageRecords.first {
        $0.childID == compactedBirth.newbornID
    }!
    try! compacted.setReproductionEnabled(false)
    while compacted.causalLedgerSnapshot().summary.droppedEventCount
            < compactedParentage.recordedEventID.sequence.rawValue {
        _ = try! compacted.advanceTick()
    }
    let compactedSnapshot = compacted.causalLedgerSnapshot()
    let compactedCheckpoint = try! compacted.makeCheckpoint()
    let compactedRestored = try! AgentSimulationSession.restoring(
        compactedCheckpoint
    )
    check("durable causal IDs preserve temporal truth after event-body compaction",
          compactedSnapshot.summary.droppedEventCount
            >= compactedParentage.recordedEventID.sequence.rawValue
            && !compactedSnapshot.events.contains {
                $0.eventID == compactedHouse.foundationEventID
                    || $0.eventID
                        == compactedParentage.sourcePopulationBornEventID
                    || $0.eventID == compactedParentage.recordedEventID
            }
            && gateFB07BirthMemberships(
                compactedRestored, childID: compactedBirth.newbornID
            ).count == 1
            && (try! compactedRestored.durableStateBytes())
                == (try! compacted.durableStateBytes()))

    check("missing required child birth membership rejects schema 35",
          gateFB07RestoreRejects(preCheckpoint) { durable in
              var family = durable["familyState"] as! [String: Any]
              var periods = family["houseMembershipPeriods"] as! [[String: Any]]
              periods.removeAll {
                  ($0["agentID"] as? String) == preBirthRecord.newbornID.rawValue
                    && ($0["basis"] as? String) == "sharedParentHouseAtBirth"
              }
              family["houseMembershipPeriods"] = periods
              durable["familyState"] = family
          })
    check("unexpected post-birth child membership rejects schema 35",
          gateFB07RestoreRejects(postCheckpoint) { durable in
              var family = durable["familyState"] as! [String: Any]
              var periods = family["houseMembershipPeriods"] as! [[String: Any]]
              var injected = periods.first {
                  ($0["houseID"] as? String) == postHouse.houseID.rawValue
              }!
              injected["agentID"] = postBirthRecord.newbornID.rawValue
              injected["basis"] = "sharedParentHouseAtBirth"
              injected["joinedTick"] = postBirthRecord.birthTick
              injected.removeValue(forKey: "explicitJoinConsent")
              periods.append(injected)
              family["houseMembershipPeriods"] = periods
              durable["familyState"] = family
          })
    check("wrong-house child birth membership rejects schema 35",
          gateFB07RestoreRejects(preCheckpoint) { durable in
              var family = durable["familyState"] as! [String: Any]
              var periods = family["houseMembershipPeriods"] as! [[String: Any]]
              let index = periods.firstIndex {
                  ($0["agentID"] as? String) == preBirthRecord.newbornID.rawValue
                    && ($0["basis"] as? String) == "sharedParentHouseAtBirth"
              }!
              periods[index]["houseID"] = "house-99999999"
              family["houseMembershipPeriods"] = periods
              durable["familyState"] = family
          })
    check("same-tick causal sequence manipulation rejects schema 35",
          gateFB07RestoreRejects(preCheckpoint) { durable in
              let kinship = durable["kinshipState"] as! [String: Any]
              let parentage = (kinship["parentageRecords"] as! [[String: Any]])[0]
              let recordedEventID = parentage["recordedEventID"]!
              var family = durable["familyState"] as! [String: Any]
              var houses = family["houses"] as! [[String: Any]]
              houses[0]["foundationEventID"] = recordedEventID
              family["houses"] = houses
              durable["familyState"] = family
          })

    check("focused fixtures preserve singular current authority",
          [postBirth, preBirth, previousTick, joinBefore, joinAfter,
           leaveBefore, leaveAfter].allSatisfy(gateFB07CurrentAuthorityIsSingular))
    check("historical Family membership never duplicates current membership",
          [postBirth, preBirth, previousTick, joinBefore, joinAfter,
           leaveBefore, leaveAfter].allSatisfy { session in
              let active = session.familySnapshot().houseMembershipPeriods
                  .filter { $0.leftTick == nil }
              return Dictionary(grouping: active, by: {
                  "\($0.agentID.rawValue)|\($0.houseID.rawValue)"
              }).values.allSatisfy { $0.count == 1 }
          })
    check("focused checkpoint schema remains 35 and Observer remains 13",
          postCheckpoint.schemaVersion == 35
            && preCheckpoint.schemaVersion == 35
            && postBirth.observerSnapshot(
                worldBinding: try! AgentObserverWorldBinding(
                    worldID: "gate-f-b07-world",
                    storageIdentity: "memory:gate-f-b07", seed: 707,
                    dimension: 0, observedWorldTick: postBirth.tick
                )
            ).header.schemaVersion == 13)
    check("focused deterministic digests are stable across exact restores",
          gateFB07FixtureDigest(postBirth) == gateFB07FixtureDigest(postRestored)
            && gateFB07FixtureDigest(preBirth) == gateFB07FixtureDigest(preRestored))
}
