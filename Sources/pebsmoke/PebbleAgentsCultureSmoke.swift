import Foundation
@_spi(Testing) import PebbleAgents

private let cultureMain0 = AgentID(rawValue: "agent_0")!
private let cultureMain1 = AgentID(rawValue: "agent_1")!
private let cultureMain2 = AgentID(rawValue: "agent_2")!
private let cultureEast0 = AgentID(rawValue: "culture-east-0")!
private let cultureEast1 = AgentID(rawValue: "culture-east-1")!
private let cultureEast2 = AgentID(rawValue: "culture-east-2")!
private let cultureEastSettlement = AgentSettlementID(rawValue: "culture-east")!

private func cultureAgent(
    _ id: AgentID,
    x: Int,
    health: Int = 100,
    lethalNextTick: Bool = false
) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id.rawValue,
        state: "idle",
        position: position,
        needs: AgentNeeds(
            hunger: lethalNextTick ? 1 : -10,
            fatigue: 0,
            curiosity: 0,
            safety: 1
        ),
        health: health,
        fear: 0,
        homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle,
            reason: "CIV-47 deterministic culture fixture",
            startedAtTick: 0,
            urgency: 0
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
        totalDistanceReducedTowardHome: 0,
        survivalProgress: lethalNextTick ? AgentSurvivalProgress(
            status: .starving,
            consecutiveCriticalHungerTicks: 2
        ) : nil
    )
}

private func culturePreparedSession(
    id: String,
    causalMaximumEvents: Int = 128
) throws -> (AgentSimulationSession, AgentKnowledgePropositionID) {
    var session = try AgentSimulationSession(
        configuration: try AgentSessionConfiguration(
            seed: 147,
            nearbyRadius: 16,
            resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 64),
            socialConfiguration: try AgentSocialConfiguration(
                communicationRadius: 8,
                minimumTrustToVerify: -100,
                claimLifetimeTicks: 64,
                messageLifetimeTicks: 64,
                maximumFactsPerAgent: 8,
                maximumBeliefsPerAgent: 8,
                maximumTrustRelations: 32,
                maximumRetainedMessages: 32,
                shareCooldownTicks: 1
            )
        ),
        agents: [
            cultureAgent(cultureMain0, x: 0),
            cultureAgent(cultureMain1, x: 2),
            cultureAgent(cultureMain2, x: 4),
        ],
        simulationID: try AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: causalMaximumEvents)
    )
    try session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 1),
        configuration: try AgentPopulationConfiguration(
            maximumActivePopulation: 6,
            maximumMigrationRecords: 8
        )
    )
    try session.initializePopulationScaling(
        additionalSettlements: [AgentPopulationSettlement(
            settlementID: cultureEastSettlement,
            anchor: AgentPosition(x: 7, y: 64, z: 1),
            receptionPosition: AgentPosition(x: 7, y: 64, z: 1),
            capacity: 6,
            residentIDs: [],
            inTransitIDs: []
        )],
        additionalResidents: [
            AgentScaledResidentAdmission(
                state: cultureAgent(cultureEast0, x: 9),
                settlementID: cultureEastSettlement
            ),
            AgentScaledResidentAdmission(
                state: cultureAgent(cultureEast1, x: 10),
                settlementID: cultureEastSettlement
            ),
            AgentScaledResidentAdmission(
                state: cultureAgent(cultureEast2, x: 12),
                settlementID: cultureEastSettlement
            ),
        ],
        configuration: try AgentPopulationScaleConfiguration(
            maximumSettlements: 2,
            maximumLiveAgents: 2,
            maximumNearAgents: 2,
            nearMaintenanceCadence: 2,
            dormantMaintenanceCadence: 8,
            rotationIntervalTicks: 4,
            maximumFidelityTransitionHistory: 32,
            maximumSettlementMigrationHistory: 4,
            maximumConcurrentSettlementMigrations: 1,
            maximumSettlementMigrationRouteLength: 32
        )
    )
    try session.setSocialEnabled(true)
    try session.setKnowledgeGraphEnabled(true)
    _ = try session.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: cultureMain0.rawValue,
        socialResourceObservations: [AgentResourceObservation(
            resource: .wood,
            target: AgentPosition(x: 3, y: 64, z: 0),
            direction: .east,
            distanceManhattan: 3,
            quantityAvailable: 1,
            source: .naturalWorld,
            expectedBlockFingerprint: 47_001
        )]
    )])
    let proposition = session.knowledgeSnapshot().beliefs.first {
        $0.ownerID == cultureMain0 && $0.stance == .accepted
    }!.propositionID
    try session.setLanguageEnabled(true)
    let senses = AgentLanguagePack.frenchReference.entries.map(\.senseID)
    for agentID in [cultureMain0, cultureMain1] {
        try session.seedLanguagePrior(for: agentID, senseIDs: senses)
    }
    try session.setOralTransmissionEnabled(
        true,
        configuration: try AgentOralConfiguration(
            maximumTransmissionRecords: 16,
            maximumFaithfulDistance: 1
        )
    )
    return (session, proposition)
}

private func cultureStance(
    _ session: AgentSimulationSession,
    agentID: AgentID,
    practiceID: AgentCulturePracticeID
) -> AgentCultureStance? {
    session.distributedCultureSnapshot().individuals.first {
        $0.agentID == agentID
    }?.stances.first { $0.practice.practiceID == practiceID }
}

private func cultureWritingReceipt(
    _ plan: AgentWritingPlan,
    actorID: AgentID,
    session: AgentSimulationSession
) -> AgentWritingPhysicalReceipt {
    AgentWritingPhysicalReceipt(
        worldID: plan.worldID,
        dimension: plan.dimension,
        cell: plan.cell,
        blockKey: "oak_sign",
        artifactID: plan.artifactID,
        materialID: plan.materialID,
        contentDigest: plan.contentDigest,
        lines: plan.lines,
        actorID: actorID,
        actorPosition: try! session.state(for: actorID).position,
        observedAtTick: session.tick
    )
}

private func cultureWrite(
    _ session: inout AgentSimulationSession,
    propositionID: AgentKnowledgePropositionID,
    materialID: Int,
    cell: AgentPosition
) throws -> AgentWrittenArtifact {
    let plan = try session.prepareWriting(
        authorID: cultureMain0,
        propositionID: propositionID,
        materialID: materialID,
        dimension: "0",
        cell: cell
    )
    return try session.acceptWriting(
        plan,
        receipt: cultureWritingReceipt(
            plan,
            actorID: cultureMain0,
            session: session
        )
    )
}

private func cultureRecord(
    _ session: AgentSimulationSession,
    operationID: String
) -> AgentCultureRecord? {
    session.distributedCultureSnapshot().individuals
        .flatMap(\.history)
        .first { $0.operationID == operationID }
}

private func cultureRefusal(
    _ name: String,
    session: AgentSimulationSession,
    expectedError: AgentCultureError? = nil,
    operation: (inout AgentSimulationSession) throws -> Void
) {
    var candidate = session
    let before = try! candidate.durableStateBytes()
    do {
        try operation(&candidate)
        check(name, false, "unexpected success")
    } catch let AgentSessionError.culture(error) {
        check(name, expectedError.map { $0 == error } ?? true, "\(error)")
    } catch {
        check(name, expectedError == nil, "\(error)")
    }
    check(name + " is atomic", try! candidate.durableStateBytes() == before)
}

private func cultureMigrationRoute() -> [AgentPosition] {
    [AgentPosition(x: 0, y: 64, z: 0)]
        + (0...7).map { AgentPosition(x: $0, y: 64, z: 1) }
}

private func cultureMigrationPerception(
    session: AgentSimulationSession,
    route: [AgentPosition]
) -> AgentPerceptionInput {
    let state = try! session.state(for: cultureMain0)
    func column(_ position: AgentPosition) -> AgentWorldColumnObservation {
        AgentWorldColumnObservation(
            position: position,
            chunkReady: true,
            surfaceY: position.y,
            height: position.y,
            blockBelow: 1,
            blockAtFeet: 0,
            blockAtHead: 0,
            groundPresent: true,
            feetClear: true,
            headClear: true
        )
    }
    let neighbors = AgentCardinalDirection.allCases.map { direction in
        let position = AgentPosition(
            x: state.position.x + direction.dx,
            y: state.position.y,
            z: state.position.z + direction.dz
        )
        return AgentWorldNeighborObservation(
            direction: direction,
            column: column(position),
            stepDelta: 0,
            traversable: true,
            dangerousDrop: false
        )
    }
    return AgentPerceptionInput(
        agentId: cultureMain0.rawValue,
        worldObservation: try! AgentWorldObservation(
            worldTick: session.tick + 1,
            position: state.position,
            center: column(state.position),
            neighbors: neighbors,
            biomeId: 1,
            biomeName: "plains",
            combinedLight: 15,
            skyLight: 15,
            blockLight: 0,
            dayTime: 6_000,
            raining: false,
            thundering: false
        ),
        navigationObservation: AgentNavigationObservation(
            worldTick: session.tick + 1,
            origin: state.position,
            target: route.last!,
            radius: AgentNavigationObservation.maximumRadius,
            cells: route.map {
                AgentNavigationCell(position: $0, status: .traversable)
            }
        )
    )
}

private func cultureCompleteMigration(
    _ session: inout AgentSimulationSession
) throws {
    let route = cultureMigrationRoute()
    _ = try session.beginSettlementMigration(
        agentID: cultureMain0,
        destinationSettlementID: cultureEastSettlement,
        verifiedRoute: route
    )
    for _ in 1..<route.count {
        _ = try session.advanceTick(perceptions: [
            cultureMigrationPerception(session: session, route: route),
        ])
        try session.applyMovementOutcomes(
            AgentMovementCoordinator.resolve(snapshot: session.snapshot())
        )
    }
}

private func cultureResignedCheckpoint(
    _ checkpoint: AgentSessionCheckpoint,
    reattestCulture: Bool = false,
    mutateDurable: (inout [String: Any]) -> Void
) -> AgentSessionCheckpoint {
    var root = try! JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(checkpoint)
    ) as! [String: Any]
    var durable = root["durableState"] as! [String: Any]
    mutateDurable(&durable)
    var mutatedBytes = try! JSONSerialization.data(
        withJSONObject: durable,
        options: [.sortedKeys, .withoutEscapingSlashes]
    )
    if reattestCulture {
        mutatedBytes = try! reattestCultureDurableStateForTesting(mutatedBytes)
    }
    let mutatedState = try! AgentCheckpointCodec.decode(
        AgentSessionDurableState.self,
        from: mutatedBytes
    )
    let canonicalBytes = try! AgentCheckpointCodec.encode(mutatedState)
    let canonical = try! JSONSerialization.jsonObject(
        with: canonicalBytes
    ) as! [String: Any]
    let clock = canonical["clock"] as! [String: Any]
    let simulationID = clock["simulationID"] as! String
    let tick = clock["tick"] as! Int
    let digest = AgentCheckpointDigest.sha256(canonicalBytes)
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

private func cultureMutateRecord(
    _ durable: inout [String: Any],
    operationID: String,
    mutation: (inout [String: Any]) -> Void
) {
    var culture = durable["distributedCultureState"] as! [String: Any]
    var individuals = culture["individuals"] as! [[String: Any]]
    var mutated = false
    for individualIndex in individuals.indices {
        var history = individuals[individualIndex]["history"] as! [[String: Any]]
        for recordIndex in history.indices
        where history[recordIndex]["operationID"] as? String == operationID {
            mutation(&history[recordIndex])
            mutated = true
        }
        individuals[individualIndex]["history"] = history
    }
    precondition(mutated)
    culture["individuals"] = individuals
    durable["distributedCultureState"] = culture
}

private func cultureRecordEventObject(
    _ durable: [String: Any],
    operationID: String
) -> [String: Any] {
    let culture = durable["distributedCultureState"] as! [String: Any]
    let individuals = culture["individuals"] as! [[String: Any]]
    for individual in individuals {
        for record in individual["history"] as! [[String: Any]]
        where record["operationID"] as? String == operationID {
            return record["eventID"] as! [String: Any]
        }
    }
    preconditionFailure("missing culture record \(operationID)")
}

private func cultureMutateRecordCausalEvent(
    _ durable: inout [String: Any],
    operationID: String,
    mutation: (inout [String: Any]) -> Void
) {
    let target = cultureRecordEventObject(durable, operationID: operationID)
    var ledger = durable["causalLedger"] as! [String: Any]
    var events = ledger["events"] as! [[String: Any]]
    let index = events.firstIndex {
        NSDictionary(dictionary: $0["eventID"] as! [String: Any])
            .isEqual(to: target)
    }!
    mutation(&events[index])
    ledger["events"] = events
    durable["causalLedger"] = ledger
}

private func cultureReplaceString(
    in value: Any,
    matching old: String,
    with new: String
) -> Any {
    if let string = value as? String { return string == old ? new : string }
    if let array = value as? [Any] {
        return array.map {
            cultureReplaceString(in: $0, matching: old, with: new)
        }
    }
    if let dictionary = value as? [String: Any] {
        return dictionary.mapValues {
            cultureReplaceString(in: $0, matching: old, with: new)
        }
    }
    return value
}

private func cultureRestoreRefuses(
    _ name: String,
    checkpoint: AgentSessionCheckpoint,
    mutation: (inout [String: Any]) -> Void
) {
    let hostile = cultureResignedCheckpoint(
        checkpoint,
        reattestCulture: true,
        mutateDurable: mutation
    )
    do {
        _ = try AgentSimulationSession.restoring(hostile)
        check(name, false, "accepted reattested hostile state")
    } catch {
        check(name, true, "\(error)")
    }
}

func runPebbleAgentsCultureSmoke() {
    section("PebbleAgents distributed culture, norms and rituals (CIV-47)")
    do {
        var (session, propositionID) = try culturePreparedSession(
            id: "civ47-distributed-culture"
        )
        let base = try session.makeCheckpoint()
        let baseBytes = try AgentCheckpointCodec.encode(base)
        check("pre-CIV-47 schema remains oral schema 38", base.schemaVersion == 38)
        check("published pre-CIV-47 checkpoint restores exactly",
              try AgentCheckpointCodec.encode(
                AgentSimulationSession.restoring(base).makeCheckpoint()
              ) == baseBytes)

        var recorder = try AgentReplayRecorder(checkpoint: base, session: session)
        let cultureConfiguration = try AgentCultureConfiguration(
            maximumIndividuals: 6,
            maximumPracticesPerIndividual: 4,
            maximumHistoryPerIndividual: 32,
            maximumOperationReceipts: 32,
            maximumParticipantsPerUse: 4,
            maximumWitnessesPerUse: 4,
            adoptionExposureThreshold: 2,
            inactivityTicksBeforeDecline: 16
        )
        _ = try recorder.apply(.setDistributedCultureEnabled(
            true, configuration: cultureConfiguration
        ), to: &session)
        _ = try recorder.apply(.originateCulturalPractice(
            operationID: "civ47-root-ritual",
            originatorID: cultureMain0,
            form: .ritual(try AgentCultureRitualPattern(
                context: .remembrance,
                orderedSteps: [.assemble, .speakNames, .disperse],
                minimumParticipants: 1
            ))
        ), to: &session)
        let root = cultureRecord(session, operationID: "civ47-root-ritual")!
            .practice

        let unboundOralResult = try recorder.apply(.transmitOralClaim(
            speakerID: cultureMain0,
            recipientID: cultureMain1,
            propositionID: propositionID,
            renderingMode: .deterministicCompositional,
            acceptedEffect: nil
        ), to: &session)
        let unboundOral = unboundOralResult.oralTransmissionResult!
        cultureRefusal(
            "unrelated wood oral carrier cannot expose remembrance ritual",
            session: session
        ) {
            _ = try $0.recordCulturalExposure(
                operationID: "civ47-unbound-oral-exposure",
                targetID: cultureMain1,
                sourceAgentID: cultureMain0,
                practiceID: root.practiceID,
                carrier: .oral(unboundOral.transmissionID)
            )
        }
        let oralResult = try recorder.apply(.transmitCulturalPracticeOrally(
            operationID: "civ47-oral-exposure-main1",
            sourceAgentID: cultureMain0,
            targetID: cultureMain1,
            practiceID: root.practiceID,
            accompanyingPropositionID: propositionID,
            renderingMode: .deterministicCompositional,
            acceptedEffect: nil
        ), to: &session)
        let oral = oralResult.oralTransmissionResult!
        check("oral carrier commits the exact cultural practice descriptor",
              oral.contentAttachment?.namespace
                == "pebble.culture.practice.v1"
                && oral.contentAttachment?.contentID == root.practiceID.rawValue
                && cultureRecord(
                    session, operationID: "civ47-oral-exposure-main1"
                )?.carrierContentDigest
                    == oral.contentAttachment?.contentDigest)
        let epistemicAfterCarrier = session.knowledgeSnapshot()
        let languageAfterCarrier = session.languageSnapshot()
        let populationAfterCarrier = session.populationSnapshot()
        check("bound oral cultural exposure does not auto-adopt",
              cultureStance(session, agentID: cultureMain1,
                            practiceID: root.practiceID)?.status == .exposed)
        _ = try recorder.apply(.enactCulturalPractice(
            operationID: "civ47-root-demonstration-main1",
            practitionerID: cultureMain0,
            practiceID: root.practiceID,
            coParticipantIDs: [],
            witnessIDs: [cultureMain1]
        ), to: &session)
        check("witness exposure remains distinct from adoption",
              cultureStance(session, agentID: cultureMain1,
                            practiceID: root.practiceID)?.status == .exposed
                && cultureStance(session, agentID: cultureMain1,
                                 practiceID: root.practiceID)?.exposureCount == 2)
        _ = try recorder.apply(.considerCulturalPractice(
            operationID: "civ47-adopt-root-main1",
            agentID: cultureMain1,
            practiceID: root.practiceID
        ), to: &session)
        let adoption = cultureRecord(
            session, operationID: "civ47-adopt-root-main1"
        )!
        let adoptionEvent = session.causalLedgerSnapshot().events.first {
            $0.eventID == adoption.eventID
        }!
        check("adoption is causally linked to the individual's exposure",
              adoption.outcome == .adopted
                && adoptionEvent.causes.contains {
                    $0 == cultureRecord(
                        session,
                        operationID: "civ47-root-demonstration-main1"
                    )!.eventID
                })

        let afterAdoption = try session.durableStateBytes()
        _ = try session.considerCulturalPractice(
            operationID: "civ47-adopt-root-main1",
            agentID: cultureMain1,
            practiceID: root.practiceID
        )
        check("same adoption retry is byte-idempotent",
              try session.durableStateBytes() == afterAdoption)

        _ = try recorder.apply(.enactCulturalPractice(
            operationID: "civ47-root-shared-use",
            practitionerID: cultureMain0,
            practiceID: root.practiceID,
            coParticipantIDs: [cultureMain1],
            witnessIDs: []
        ), to: &session)
        _ = try recorder.apply(.createCulturalVariation(
            operationID: "civ47-remembrance-variation",
            creatorID: cultureMain1,
            parentPracticeID: root.practiceID,
            form: .ritual(try AgentCultureRitualPattern(
                context: .remembrance,
                orderedSteps: [.assemble, .exchangeToken, .speakNames, .disperse],
                minimumParticipants: 1
            ))
        ), to: &session)
        let variation = cultureRecord(
            session, operationID: "civ47-remembrance-variation"
        )!.practice
        check("variation retains immutable causal lineage",
              variation.parentPracticeID == root.practiceID
                && variation.rootPracticeID == root.practiceID
                && variation.generation == root.generation + 1
                && cultureRecord(session, operationID: "civ47-root-ritual")!
                    .practice == root)

        for ordinal in 1...2 {
            _ = try recorder.apply(.enactCulturalPractice(
                operationID: "civ47-variation-demo-\(ordinal)",
                practitionerID: cultureMain1,
                practiceID: variation.practiceID,
                coParticipantIDs: [],
                witnessIDs: [cultureMain2]
            ), to: &session)
        }
        _ = try recorder.apply(.considerCulturalPractice(
            operationID: "civ47-adopt-variation-main2",
            agentID: cultureMain2,
            practiceID: variation.practiceID
        ), to: &session)
        _ = try recorder.apply(.enactCulturalPractice(
            operationID: "civ47-variation-shared-use",
            practitionerID: cultureMain1,
            practiceID: variation.practiceID,
            coParticipantIDs: [cultureMain2],
            witnessIDs: []
        ), to: &session)
        _ = try recorder.apply(.enactCulturalPractice(
            operationID: "civ47-root-demo-main2",
            practitionerID: cultureMain0,
            practiceID: root.practiceID,
            coParticipantIDs: [],
            witnessIDs: [cultureMain2]
        ), to: &session)
        _ = try recorder.apply(.considerCulturalPractice(
            operationID: "civ47-reject-root-main2",
            agentID: cultureMain2,
            practiceID: root.practiceID
        ), to: &session)
        check("competing history can cause rejection",
              cultureStance(session, agentID: cultureMain2,
                            practiceID: root.practiceID)?.status == .rejected)
        _ = try recorder.apply(.reviewCulturalContinuity(
            operationID: "civ47-cease-root-main1",
            agentID: cultureMain1,
            practiceID: root.practiceID
        ), to: &session)
        let main1Root = cultureStance(
            session, agentID: cultureMain1, practiceID: root.practiceID
        )!
        check("superseded practice ceases without erasing history",
              main1Root.status == .ceased
                && cultureRecord(session, operationID: "civ47-oral-exposure-main1") != nil
                && cultureRecord(session, operationID: "civ47-adopt-root-main1") != nil)

        _ = try recorder.apply(.originateCulturalPractice(
            operationID: "civ47-aid-norm",
            originatorID: cultureMain0,
            form: .norm(AgentCultureNormPattern(
                context: .scarcityAid,
                expectedAction: .offerBeforePrivateUse
            ))
        ), to: &session)
        let norm = cultureRecord(session, operationID: "civ47-aid-norm")!.practice
        _ = try recorder.apply(.enactCulturalPractice(
            operationID: "civ47-aid-norm-use",
            practitionerID: cultureMain0,
            practiceID: norm.practiceID,
            coParticipantIDs: [],
            witnessIDs: [cultureMain1]
        ), to: &session)

        let projectionBytesBefore = try session.durableStateBytes()
        let mainProjection = try session.culturalPrevalence(in: .settlement(.main))
        let eastProjection = try session.culturalPrevalence(
            in: .settlement(cultureEastSettlement)
        )
        check("settlements diverge from different causal histories",
              mainProjection.entries.count == 3
                && !mainProjection.entries.allSatisfy { $0.totalUseCount == 0 }
                && eastProjection.entries.isEmpty)
        check("prevalence is a read-only projection",
              try session.durableStateBytes() == projectionBytesBefore
                && mainProjection.metrics.historicalRowsVisited == 0
                && mainProjection.metrics.stanceRowsVisited
                    <= mainProjection.metrics.maximumStanceRowsVisited)
        check("local transitions create no remote cultural rows",
              session.distributedCultureSnapshot().individuals.allSatisfy {
                ![cultureEast0, cultureEast1, cultureEast2].contains($0.agentID)
              })
        cultureRefusal("cross-settlement witness is refused", session: session) {
            _ = try $0.enactCulturalPractice(
                operationID: "civ47-forbidden-global-sync",
                practitionerID: cultureMain0,
                practiceID: root.practiceID,
                witnessIDs: [cultureEast0]
            )
        }
        cultureRefusal("social authority cannot disappear under culture",
                       session: session) {
            try $0.setSocialEnabled(false)
        }

        check("culture does not duplicate epistemic authority",
              session.knowledgeSnapshot() == epistemicAfterCarrier
                && session.languageSnapshot() == languageAfterCarrier)
        check("culture does not mutate population or future authorities",
              session.populationSnapshot() == populationAfterCarrier
                && !session.skillsEnabled
                && !session.materialRightsEnabled
                && !session.householdsEnabled
                && !session.familyV1Enabled)

        cultureRefusal("conflicting operation retry is refused", session: session) {
            _ = try $0.originateCulturalPractice(
                operationID: "civ47-aid-norm",
                originatorID: cultureMain0,
                form: .norm(AgentCultureNormPattern(
                    context: .reciprocalWork,
                    expectedAction: .reciprocateAfterAid
                ))
            )
        }
        cultureRefusal("duplicate carrier exposure is refused", session: session) {
            _ = try $0.recordCulturalExposure(
                operationID: "civ47-duplicate-carrier",
                targetID: cultureMain1,
                sourceAgentID: cultureMain0,
                practiceID: root.practiceID,
                carrier: .oral(oral.transmissionID)
            )
        }

        let checkpoint = try session.makeCheckpoint()
        let checkpointBytes = try AgentCheckpointCodec.encode(checkpoint)
        check("CIV-47 checkpoint advances to schema 42",
              checkpoint.schemaVersion == 42)
        let restored = try AgentSimulationSession.restoring(checkpoint)
        check("schema 42 restart is byte exact",
              try AgentCheckpointCodec.encode(restored.makeCheckpoint())
                == checkpointBytes)
        let restoredOral = restored.oralTransmissionState?.transmissions.first {
            $0.transmissionID == oral.transmissionID
        }
        check("carrier-content linkage survives schema 42 restart",
              restoredOral?.contentAttachment == oral.contentAttachment
                && cultureRecord(
                    restored, operationID: "civ47-oral-exposure-main1"
                )?.carrierEventID == oral.receiptEventID)
        check("decline and lineage survive restart without resurrection",
              cultureStance(restored, agentID: cultureMain1,
                            practiceID: root.practiceID)?.status == .ceased
                && cultureStance(restored, agentID: cultureMain2,
                                 practiceID: root.practiceID)?.status == .rejected
                && cultureStance(restored, agentID: cultureMain1,
                                 practiceID: variation.practiceID)?
                    .practice.parentPracticeID == root.practiceID)

        let journal = try recorder.journal(
            named: AgentCheckpointName(rawValue: "civ47-replay")!
        )
        check("CIV-47 replay envelope advances to schema 42",
              journal.manifest.schemaVersion == 42)
        let replay = try AgentSessionReplayer.replay(
            checkpoint: base,
            journal: journal
        )
        check("schema 42 replay is deterministic and byte exact",
              try replay.session.durableStateBytes()
                == session.durableStateBytes())
        check("carrier-content linkage is replay deterministic",
              replay.session.oralTransmissionState?.transmissions.first {
                  $0.transmissionID == oral.transmissionID
              }?.contentAttachment == oral.contentAttachment)

        let missingCulture = cultureResignedCheckpoint(checkpoint) {
            $0.removeValue(forKey: "distributedCultureState")
        }
        do {
            _ = try AgentSimulationSession.restoring(missingCulture)
            check("schema 42 refuses missing cultural durable state", false)
        } catch {
            check("schema 42 refuses missing cultural durable state", true, "\(error)")
        }
        let hostileCultureIdentity = cultureResignedCheckpoint(checkpoint) {
            var culture = $0["distributedCultureState"] as! [String: Any]
            var individuals = culture["individuals"] as! [[String: Any]]
            individuals[0]["agentID"] = "civ47-invented-identity"
            culture["individuals"] = individuals
            $0["distributedCultureState"] = culture
        }
        do {
            _ = try AgentSimulationSession.restoring(hostileCultureIdentity)
            check("schema 42 refuses invented cultural identity", false)
        } catch {
            check("schema 42 refuses invented cultural identity", true, "\(error)")
        }
        let hostileCultureBound = cultureResignedCheckpoint(checkpoint) {
            var culture = $0["distributedCultureState"] as! [String: Any]
            var configuration = culture["configuration"] as! [String: Any]
            configuration["maximumIndividuals"] = 1
            culture["configuration"] = configuration
            $0["distributedCultureState"] = culture
        }
        do {
            _ = try AgentSimulationSession.restoring(hostileCultureBound)
            check("schema 42 refuses hostile cultural bounds", false)
        } catch {
            check("schema 42 refuses hostile cultural bounds", true, "\(error)")
        }
        cultureRestoreRefuses(
            "schema 42 refuses retained causal event kind mismatch",
            checkpoint: checkpoint
        ) {
            cultureMutateRecordCausalEvent(
                &$0,
                operationID: "civ47-oral-exposure-main1"
            ) { $0["kind"] = "culturePracticeConsidered" }
        }
        cultureRestoreRefuses(
            "schema 42 refuses retained causal payload mismatch",
            checkpoint: checkpoint
        ) {
            cultureMutateRecordCausalEvent(
                &$0,
                operationID: "civ47-oral-exposure-main1"
            ) { event in
                event["payload"] = cultureReplaceString(
                    in: event["payload"]!,
                    matching: cultureRecord(
                        session,
                        operationID: "civ47-oral-exposure-main1"
                    )!.requestDigest,
                    with: String(repeating: "0", count: 64)
                )
            }
        }
        cultureRestoreRefuses(
            "schema 42 refuses retained causal actor relation mismatch",
            checkpoint: checkpoint
        ) {
            cultureMutateRecordCausalEvent(
                &$0,
                operationID: "civ47-oral-exposure-main1"
            ) { $0["actorID"] = cultureMain2.rawValue }
        }
        cultureRestoreRefuses(
            "schema 42 refuses retained causal subject relation mismatch",
            checkpoint: checkpoint
        ) {
            cultureMutateRecordCausalEvent(
                &$0,
                operationID: "civ47-oral-exposure-main1"
            ) { $0["subjectID"] = cultureMain2.rawValue }
        }
        cultureRestoreRefuses(
            "schema 42 refuses retained causal origin mismatch",
            checkpoint: checkpoint
        ) {
            cultureMutateRecordCausalEvent(
                &$0,
                operationID: "civ47-oral-exposure-main1"
            ) { $0["origin"] = "oralTransition" }
        }
        cultureRestoreRefuses(
            "schema 42 refuses retained causal cause mismatch",
            checkpoint: checkpoint
        ) {
            cultureMutateRecordCausalEvent(
                &$0,
                operationID: "civ47-oral-exposure-main1"
            ) { event in
                var causes = event["causes"] as! [[String: Any]]
                causes.removeFirst()
                event["causes"] = causes
            }
        }
        cultureRestoreRefuses(
            "schema 42 refuses jointly reattested fabricated required causes",
            checkpoint: checkpoint
        ) { durable in
            let ledger = durable["causalLedger"] as! [String: Any]
            let firstEvent = (ledger["events"] as! [[String: Any]])[0]
            let fabricatedCause = firstEvent["eventID"] as! [String: Any]
            var changedCauses: [[String: Any]] = []
            cultureMutateRecord(
                &durable,
                operationID: "civ47-oral-exposure-main1"
            ) { record in
                var causes = record["causes"] as! [[String: Any]]
                causes[0] = fabricatedCause
                changedCauses = causes
                record["causes"] = causes
            }
            cultureMutateRecordCausalEvent(
                &durable,
                operationID: "civ47-oral-exposure-main1"
            ) { $0["causes"] = changedCauses }
        }
        cultureRestoreRefuses(
            "schema 42 refuses record originator actor mismatch",
            checkpoint: checkpoint
        ) {
            cultureMutateRecord(&$0, operationID: "civ47-root-ritual") {
                $0["actorID"] = cultureMain1.rawValue
            }
        }
        cultureRestoreRefuses(
            "schema 42 refuses carrier cultural-content mismatch",
            checkpoint: checkpoint
        ) {
            cultureMutateRecord(
                &$0,
                operationID: "civ47-oral-exposure-main1"
            ) {
                $0["carrierContentDigest"] = String(repeating: "f", count: 64)
            }
        }
        let futureSchema = cultureResignedCheckpoint(checkpoint) {
            $0["schemaVersion"] = 43
        }
        do {
            _ = try AgentSimulationSession.restoring(futureSchema)
            check("future schema 43 is refused", false)
        } catch {
            check("future schema 43 is refused", true, "\(error)")
        }

        let cultureBeforeFidelityTick = session.distributedCultureState!
        _ = try session.advanceTick()
        check("fidelity cadence preserves durable individual culture",
              session.distributedCultureState?.individuals
                == cultureBeforeFidelityTick.individuals
                && [cultureMain0, cultureMain1, cultureMain2,
                    cultureEast0, cultureEast1, cultureEast2].contains {
                        session.fidelity(for: $0) == .dormant
                    })

        var compacted = restored
        for _ in 0..<192 {
            try compacted.appendCausalRetentionTestEvent()
        }
        let compactedLedger = compacted.causalLedgerSnapshot()
        let compactedCheckpoint = try compacted.makeCheckpoint()
        let compactedRestored = try AgentSimulationSession.restoring(
            compactedCheckpoint
        )
        check("bounded causal compaction retains a culture boundary",
              compactedLedger.summary.droppedEventCount > 0
                && compacted.distributedCultureState?.boundary != nil
                && compactedLedger.events.contains {
                    $0.eventID == compacted.distributedCultureState?.boundary?.eventID
                })
        let compactedRestartBytes = try compactedRestored.durableStateBytes()
        let compactedBytes = try compacted.durableStateBytes()
        check("compaction preserves cultural state and exact restart",
              compactedRestored.distributedCultureState?.individuals
                == restored.distributedCultureState?.individuals
                && compactedRestartBytes == compactedBytes)
        check("compaction preserves carrier-content causal attestation",
              cultureRecord(
                  compactedRestored,
                  operationID: "civ47-oral-exposure-main1"
              )?.carrierContentDigest == oral.contentAttachment?.contentDigest
                && cultureRecord(
                    compactedRestored,
                    operationID: "civ47-oral-exposure-main1"
                )?.carrierEventID == oral.receiptEventID)

        let durableObject = try JSONSerialization.jsonObject(
            with: session.durableStateBytes()
        ) as! [String: Any]
        let cultureBytes = try JSONSerialization.data(
            withJSONObject: durableObject["distributedCultureState"]!,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
        let cultureText = String(decoding: cultureBytes, as: UTF8.self)
        check("durable culture contains no collective authority or provider",
              !cultureText.contains("settlementCulture")
                && !cultureText.contains("prevalence")
                && !cultureText.contains("projection")
                && !cultureText.lowercased().contains("provider")
                && !cultureText.lowercased().contains("llm"))
        check("boundedness is structural and sparse",
              cultureConfiguration.maximumIndividuals == 6
                && cultureConfiguration.maximumPracticesPerIndividual == 4
                && cultureConfiguration.maximumHistoryPerIndividual == 32
                && session.distributedCultureSnapshot().individuals.count == 3
                && mainProjection.metrics.historicalRowsVisited == 0)
        do {
            _ = try session.culturalPrevalence(in: .individuals(
                (0...cultureConfiguration.maximumIndividuals).map {
                    AgentID(rawValue: "civ47-projection-\($0)")!
                }
            ))
            check("explicit prevalence scope is bounded before sort and lookup", false)
        } catch AgentSessionError.culture(
            .invalidState("projection individual input bound")
        ) {
            check("explicit prevalence scope is bounded before sort and lookup", true)
        } catch {
            check("explicit prevalence scope is bounded before sort and lookup", false,
                  "\(error)")
        }
        cultureRefusal(
            "co-participant input is bounded before Set and sort",
            session: session,
            expectedError: .invalidState("use participant input bound")
        ) {
            _ = try $0.enactCulturalPractice(
                operationID: "civ47-oversized-co-participants",
                practitionerID: cultureMain0,
                practiceID: root.practiceID,
                coParticipantIDs: Array(
                    repeating: cultureEast0,
                    count: cultureConfiguration.maximumParticipantsPerUse
                )
            )
        }
        cultureRefusal(
            "witness input is bounded before Set and sort",
            session: session,
            expectedError: .invalidState("use participant input bound")
        ) {
            _ = try $0.enactCulturalPractice(
                operationID: "civ47-oversized-witnesses",
                practitionerID: cultureMain0,
                practiceID: root.practiceID,
                witnessIDs: Array(
                    repeating: cultureEast0,
                    count: cultureConfiguration.maximumWitnessesPerUse + 1
                )
            )
        }
        cultureRefusal(
            "carrier identifier is bounded before canonicalization and hashing",
            session: session,
            expectedError: .invalidCarrier("carrier identifier")
        ) {
            _ = try $0.recordCulturalExposure(
                operationID: "civ47-oversized-carrier",
                targetID: cultureMain1,
                sourceAgentID: cultureMain0,
                practiceID: root.practiceID,
                carrier: .writingReading(String(repeating: "x", count: 193))
            )
        }

        var mortalityCulture = try AgentSimulationSession(
            configuration: try AgentSessionConfiguration(
                seed: 147,
                memoryPolicy: .bounded(maxEntries: 32)
            ),
            agents: [
                cultureAgent(
                    cultureMain0, x: 0, health: 10, lethalNextTick: true
                ),
                cultureAgent(cultureMain1, x: 2),
                cultureAgent(cultureMain2, x: 4),
            ],
            simulationID: try AgentSimulationID(
                validating: "civ47-mortality-continuity"
            ),
            causalLedgerPolicy: .bounded(maxEvents: 128)
        )
        mortalityCulture.setSurvivalEnabled(true)
        try mortalityCulture.initializePopulationRegistry(
            settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
            receptionPosition: AgentPosition(x: 0, y: 64, z: 1)
        )
        try mortalityCulture.setSocialEnabled(true)
        try mortalityCulture.setDistributedCultureEnabled(true)
        let mortalPractice = try mortalityCulture.originateCulturalPractice(
            operationID: "civ47-mortal-origin",
            originatorID: cultureMain0,
            form: .norm(AgentCultureNormPattern(
                context: .scarcityAid,
                expectedAction: .offerBeforePrivateUse
            ))
        ).practice
        try mortalityCulture.setMortalityEnabled(true)
        _ = try mortalityCulture.advanceTick()
        let departedCulture = cultureStance(
            mortalityCulture,
            agentID: cultureMain0,
            practiceID: mortalPractice.practiceID
        )
        let livingProjection = try mortalityCulture.culturalPrevalence(
            in: .settlement(.main)
        )
        check("mortality retains bounded culture as history, not membership",
              departedCulture?.status == .adopted
                && mortalityCulture.mortalitySnapshot().records.contains {
                    $0.agentID == cultureMain0
                }
                && !livingProjection.memberIDs.contains(cultureMain0)
                && livingProjection.entries.isEmpty)
        let mortalityCheckpoint = try mortalityCulture.makeCheckpoint()
        let mortalityRestart = try AgentSimulationSession.restoring(
            mortalityCheckpoint
        )
        check("departed culture survives restart without agent resurrection",
              cultureStance(
                mortalityRestart,
                agentID: cultureMain0,
                practiceID: mortalPractice.practiceID
              ) == departedCulture
                && !mortalityRestart.populationSnapshot().members.contains {
                    $0.agentID == cultureMain0
                })

        var (binding, bindingProposition) = try culturePreparedSession(
            id: "civ47-carrier-content-binding"
        )
        try binding.setDistributedCultureEnabled(true)
        let bindingRoot = try binding.originateCulturalPractice(
            operationID: "civ47-binding-root",
            originatorID: cultureMain0,
            form: .ritual(try AgentCultureRitualPattern(
                context: .remembrance,
                orderedSteps: [.assemble, .speakNames, .disperse],
                minimumParticipants: 1
            ))
        ).practice
        let bindingNorm = try binding.originateCulturalPractice(
            operationID: "civ47-binding-other",
            originatorID: cultureMain0,
            form: .norm(AgentCultureNormPattern(
                context: .scarcityAid,
                expectedAction: .offerBeforePrivateUse
            ))
        ).practice
        _ = try binding.transmitCulturalPracticeOrally(
            operationID: "civ47-binding-other-exposure",
            sourceAgentID: cultureMain0,
            targetID: cultureMain1,
            practiceID: bindingNorm.practiceID,
            accompanyingPropositionID: bindingProposition,
            renderingMode: .deterministicCompositional
        )
        let otherCarrier = cultureRecord(
            binding,
            operationID: "civ47-binding-other-exposure"
        )!.carrier!
        cultureRefusal(
            "real carrier bound to another practice cannot expose requested practice",
            session: binding
        ) {
            _ = try $0.recordCulturalExposure(
                operationID: "civ47-binding-mismatch",
                targetID: cultureMain1,
                sourceAgentID: cultureMain0,
                practiceID: bindingRoot.practiceID,
                carrier: otherCarrier
            )
        }
        let bindingBeforeRetry = try binding.durableStateBytes()
        let bindingRetry = try binding.transmitCulturalPracticeOrally(
            operationID: "civ47-binding-other-exposure",
            sourceAgentID: cultureMain0,
            targetID: cultureMain1,
            practiceID: bindingNorm.practiceID,
            accompanyingPropositionID: bindingProposition,
            renderingMode: .deterministicCompositional
        )
        let bindingAfterRetry = try binding.durableStateBytes()
        check("bound oral carrier retry is byte-idempotent",
              bindingRetry.eventID == cultureRecord(
                  binding,
                  operationID: "civ47-binding-other-exposure"
              )?.eventID
                && bindingAfterRetry == bindingBeforeRetry)

        var (unsupportedCarriers, carrierProposition) = try culturePreparedSession(
            id: "civ47-unsupported-carriers"
        )
        try unsupportedCarriers.setDistributedCultureEnabled(true)
        let unsupportedPractice = try unsupportedCarriers
            .originateCulturalPractice(
                operationID: "civ47-unsupported-carrier-practice",
                originatorID: cultureMain0,
                form: .norm(AgentCultureNormPattern(
                    context: .scarcityAid,
                    expectedAction: .offerBeforePrivateUse
                ))
            ).practice
        try unsupportedCarriers.setWritingEnabled(
            true,
            worldID: "civ47-carrier-world",
            configuration: try AgentWritingConfiguration(
                maximumArtifacts: 2,
                maximumReadings: 2,
                maximumLiteracyRecords: 4
            )
        )
        for agentID in [cultureMain0, cultureMain1] {
            try unsupportedCarriers.seedWritingEducationalPrior(for: agentID)
        }
        let catalogueArtifact = try cultureWrite(
            &unsupportedCarriers,
            propositionID: carrierProposition,
            materialID: 47_001,
            cell: AgentPosition(x: 1, y: 64, z: 0)
        )
        let manuscriptArtifact = try cultureWrite(
            &unsupportedCarriers,
            propositionID: carrierProposition,
            materialID: 47_002,
            cell: AgentPosition(x: 1, y: 64, z: 1)
        )
        let reading = try unsupportedCarriers.readWriting(
            artifactID: catalogueArtifact.artifactID,
            readerID: cultureMain1,
            receipt: cultureWritingReceipt(
                catalogueArtifact.plan,
                actorID: cultureMain1,
                session: unsupportedCarriers
            )
        )
        cultureRefusal(
            "real CIV-45 reading fails closed without cultural-content commitment",
            session: unsupportedCarriers,
            expectedError: .invalidCarrier(
                "writing carrier has no cultural-content commitment"
            )
        ) {
            _ = try $0.recordCulturalExposure(
                operationID: "civ47-writing-fail-closed",
                targetID: cultureMain1,
                sourceAgentID: cultureMain0,
                practiceID: unsupportedPractice.practiceID,
                carrier: .writingReading(reading.readingID)
            )
        }
        try unsupportedCarriers.setArchiveEnabled(
            true,
            worldID: "civ47-carrier-world",
            configuration: try AgentArchiveConfiguration(
                maximumCollections: 1,
                maximumManuscripts: 1,
                maximumRetrievals: 1,
                maximumSearchResults: 1
            )
        )
        let catalogueReceipt = cultureWritingReceipt(
            catalogueArtifact.plan,
            actorID: cultureMain0,
            session: unsupportedCarriers
        )
        let collection = try unsupportedCarriers.createArchiveCollection(
            operationID: "civ47-carrier-collection",
            kind: .library,
            catalogueArtifactID: catalogueArtifact.artifactID,
            curatorID: cultureMain0,
            catalogueReceipt: catalogueReceipt
        )
        _ = try unsupportedCarriers.catalogueArchiveManuscript(
            operationID: "civ47-carrier-catalogue",
            collectionID: collection.collectionID,
            artifactID: manuscriptArtifact.artifactID,
            relationship: .source,
            cataloguerID: cultureMain0,
            catalogueReceipt: catalogueReceipt,
            artifactReceipt: cultureWritingReceipt(
                manuscriptArtifact.plan,
                actorID: cultureMain0,
                session: unsupportedCarriers
            )
        )
        let archiveIndex = try unsupportedCarriers.rebuildArchiveIndex()
        let archiveSelection = try unsupportedCarriers.searchArchive(
            archiveIndex,
            collectionID: collection.collectionID,
            query: .artifact(manuscriptArtifact.artifactID),
            requesterID: cultureMain0,
            catalogueReceipt: catalogueReceipt
        ).hits[0].selection
        _ = try unsupportedCarriers.retrieveArchiveManuscript(
            operationID: "civ47-real-archive-retrieval",
            selection: archiveSelection,
            readerID: cultureMain1,
            receipt: cultureWritingReceipt(
                manuscriptArtifact.plan,
                actorID: cultureMain1,
                session: unsupportedCarriers
            )
        )
        cultureRefusal(
            "real CIV-46 retrieval fails closed without cultural-content commitment",
            session: unsupportedCarriers,
            expectedError: .invalidCarrier(
                "archive carrier has no cultural-content commitment"
            )
        ) {
            _ = try $0.recordCulturalExposure(
                operationID: "civ47-archive-fail-closed",
                targetID: cultureMain1,
                sourceAgentID: cultureMain0,
                practiceID: unsupportedPractice.practiceID,
                carrier: .archiveRetrieval("civ47-real-archive-retrieval")
            )
        }

        var (locality, _) = try culturePreparedSession(
            id: "civ47-lexicographic-locality"
        )
        try locality.setDistributedCultureEnabled(true)
        let localityPractice = try locality.originateCulturalPractice(
            operationID: "civ47-locality-practice",
            originatorID: cultureMain0,
            form: .norm(AgentCultureNormPattern(
                context: .reciprocalWork,
                expectedAction: .reciprocateAfterAid
            ))
        ).practice
        for ordinal in 1...2 {
            _ = try locality.enactCulturalPractice(
                operationID: "civ47-locality-demo-\(ordinal)",
                practitionerID: cultureMain0,
                practiceID: localityPractice.practiceID,
                witnessIDs: [cultureMain1]
            )
        }
        _ = try locality.considerCulturalPractice(
            operationID: "civ47-locality-adopt",
            agentID: cultureMain1,
            practiceID: localityPractice.practiceID
        )
        try cultureCompleteMigration(&locality)
        check("lexically smaller co-participant is in the remote settlement",
              cultureMain0 < cultureMain1
                && locality.populationSnapshot().members.first {
                    $0.agentID == cultureMain0
                }?.settlementID == cultureEastSettlement
                && locality.populationSnapshot().members.first {
                    $0.agentID == cultureMain1
                }?.settlementID == .main,
              "members=\(locality.populationSnapshot().members) "
                + "position=\(try locality.state(for: cultureMain0).position) "
                + "migrations=\(locality.populationScaleSnapshot().settlementMigrations)")
        cultureRefusal(
            "remote lexically smaller co-participant is refused by identity",
            session: locality,
            expectedError: .nonLocal(cultureMain1, cultureMain0)
        ) {
            _ = try $0.enactCulturalPractice(
                operationID: "civ47-locality-adversarial",
                practitionerID: cultureMain1,
                practiceID: localityPractice.practiceID,
                coParticipantIDs: [cultureMain0]
            )
        }

        var (capacity, _) = try culturePreparedSession(
            id: "civ47-culture-capacity",
            causalMaximumEvents: 128
        )
        try capacity.setDistributedCultureEnabled(
            true,
            configuration: try AgentCultureConfiguration(
                maximumIndividuals: 6,
                maximumPracticesPerIndividual: 2,
                maximumHistoryPerIndividual: 2,
                maximumOperationReceipts: 1,
                maximumParticipantsPerUse: 2,
                maximumWitnessesPerUse: 2,
                adoptionExposureThreshold: 2,
                inactivityTicksBeforeDecline: 4
            )
        )
        _ = try capacity.originateCulturalPractice(
            operationID: "civ47-capacity-first",
            originatorID: cultureMain0,
            form: .norm(AgentCultureNormPattern(
                context: .scarcityAid,
                expectedAction: .offerBeforePrivateUse
            ))
        )
        cultureRefusal("operation capacity is a hard structural bound", session: capacity) {
            _ = try $0.originateCulturalPractice(
                operationID: "civ47-capacity-second",
                originatorID: cultureMain0,
                form: .norm(AgentCultureNormPattern(
                    context: .reciprocalWork,
                    expectedAction: .reciprocateAfterAid
                ))
            )
        }
        check("provider-off path completes with authoritative results",
              replay.report.verified
                && eastProjection.entries.isEmpty
                && mainProjection.entries.count == 3)
    } catch {
        check("CIV-47 culture campaign completes", false, "\(error)")
    }
}
