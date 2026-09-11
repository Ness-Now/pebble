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
            anchor: AgentPosition(x: 24, y: 64, z: 0),
            receptionPosition: AgentPosition(x: 24, y: 64, z: 1),
            capacity: 6,
            residentIDs: [],
            inTransitIDs: []
        )],
        additionalResidents: [
            AgentScaledResidentAdmission(
                state: cultureAgent(cultureEast0, x: 24),
                settlementID: cultureEastSettlement
            ),
            AgentScaledResidentAdmission(
                state: cultureAgent(cultureEast1, x: 26),
                settlementID: cultureEastSettlement
            ),
            AgentScaledResidentAdmission(
                state: cultureAgent(cultureEast2, x: 28),
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
            maximumSettlementMigrationRouteLength: 16
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
    operation: (inout AgentSimulationSession) throws -> Void
) {
    var candidate = session
    let before = try! candidate.durableStateBytes()
    do {
        try operation(&candidate)
        check(name, false, "unexpected success")
    } catch {
        check(name, true, "\(error)")
    }
    check(name + " is atomic", try! candidate.durableStateBytes() == before)
}

private func cultureResignedCheckpoint(
    _ checkpoint: AgentSessionCheckpoint,
    mutateDurable: (inout [String: Any]) -> Void
) -> AgentSessionCheckpoint {
    var root = try! JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(checkpoint)
    ) as! [String: Any]
    var durable = root["durableState"] as! [String: Any]
    mutateDurable(&durable)
    let mutatedBytes = try! JSONSerialization.data(
        withJSONObject: durable,
        options: [.sortedKeys, .withoutEscapingSlashes]
    )
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

        let oralResult = try recorder.apply(.transmitOralClaim(
            speakerID: cultureMain0,
            recipientID: cultureMain1,
            propositionID: propositionID,
            renderingMode: .deterministicCompositional,
            acceptedEffect: nil
        ), to: &session)
        let oral = oralResult.oralTransmissionResult!
        let epistemicAfterCarrier = session.knowledgeSnapshot()
        let languageAfterCarrier = session.languageSnapshot()
        let populationAfterCarrier = session.populationSnapshot()

        _ = try recorder.apply(.recordCulturalExposure(
            operationID: "civ47-oral-exposure-main1",
            targetID: cultureMain1,
            sourceAgentID: cultureMain0,
            practiceID: root.practiceID,
            carrier: .oral(oral.transmissionID)
        ), to: &session)
        check("valid oral exposure does not auto-adopt",
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
            check("explicit prevalence scope has a structural input bound", false)
        } catch {
            check("explicit prevalence scope has a structural input bound", true,
                  "\(error)")
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
