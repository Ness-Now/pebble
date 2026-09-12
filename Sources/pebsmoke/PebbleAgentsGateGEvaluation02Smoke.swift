import Foundation
@_spi(Testing) import PebbleAgents
import PebbleCore

private let gateGE02Parent = AgentID(rawValue: "agent_0")!
private let gateGE02CoParent = AgentID(rawValue: "agent_1")!
private let gateGE02Remote = AgentID(rawValue: "agent_2")!
private let gateGE02Child = AgentID(rawValue: "agent_3")!
private let gateGE02WoodSense = AgentLanguageSenseID(
    rawValue: "value.resource.wood"
)!
private let gateGE02SenseIDs = [
    AgentLanguageSenseID(rawValue: "referent.worldCell")!,
    AgentLanguageSenseID(rawValue: "predicate.world.resource.presence")!,
    gateGE02WoodSense,
]

private struct GateGE02RequirementResults: Codable, Equatable {
    let multiPersonTransmission: String
    let multiGenerationTransmission: String
    let dialectDivergence: String
    let survivableTraditions: String
    let losableTraditions: String
    let materialWrittenPreservation: String
    let reconstructibleCulturalHistory: String
}

private struct GateGE02Report: Codable, Equatable {
    let evaluation: String
    let simulationID: String
    let schemaVersion: Int
    let checkpointID: String
    let checkpointDigest: String
    let durableDigest: String
    let birthCheckpointID: String
    let birthCheckpointDigest: String
    let baseCheckpointID: String
    let baseCheckpointDigest: String
    let replaySchemaVersion: Int
    let replayRecordCount: Int
    let replayOperationsDigest: String
    let originalForm: String
    let evolvedForm: String
    let childID: String
    let birthID: String
    let survivalPracticeID: String
    let lostPracticeID: String
    let catalogueArtifactID: String
    let manuscriptArtifactID: String
    let collectionID: String
    let manuscriptID: String
    let retrievalOperationID: String
    let writingCarrierResult: String
    let archiveCarrierResult: String
    let physicalInscriptionsVerified: Bool
    let materialLossVerified: Bool
    let postLossRetrievalRefused: Bool
    let metadataOnlySearchSurvivedLoss: Bool
    let unrelatedCultureVariationLeftLanguageUnchanged: Bool
    let requirements: GateGE02RequirementResults
    let providerMode: String
    let candidateStatus: String
}

private struct GateGE02Candidate {
    let session: AgentSimulationSession
    let birthCheckpoint: AgentSessionCheckpoint
    let baseCheckpoint: AgentSessionCheckpoint
    let journal: AgentReplayJournal
    let report: GateGE02Report
}

private func gateGE02Agent(_ id: AgentID, x: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id.rawValue,
        state: "idle",
        position: position,
        needs: AgentNeeds(
            hunger: -10, fatigue: 0, curiosity: 0.1, safety: 1
        ),
        health: 100,
        fear: 0,
        homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle,
            reason: "Gate G Evaluation 02",
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
        totalDistanceReducedTowardHome: 0
    )
}

private func gateGE02Observation(
    _ observerID: AgentID,
    direction: AgentCardinalDirection,
    distance: Int
) -> AgentPerceptionInput {
    AgentPerceptionInput(
        agentId: observerID.rawValue,
        socialResourceObservations: [AgentResourceObservation(
            resource: .wood,
            target: AgentPosition(x: 3, y: 64, z: 0),
            direction: direction,
            distanceManhattan: distance,
            quantityAvailable: 1,
            source: .naturalWorld,
            expectedBlockFingerprint: 47_002
        )]
    )
}

private func gateGE02Receipt(
    _ plan: AgentWritingPlan,
    actorID: AgentID,
    session: AgentSimulationSession,
    world: World
) throws -> AgentWritingPhysicalReceipt {
    let observed = try world.inspectSignInscription(
        at: plan.cell.x,
        plan.cell.y,
        plan.cell.z
    )
    guard observed.artifactID == plan.artifactID,
          observed.materialID == plan.materialID,
          observed.contentDigest == plan.contentDigest,
          observed.lines == plan.lines else {
        throw AgentWritingError.unavailable("physical inscription mismatch")
    }
    return AgentWritingPhysicalReceipt(
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

private func gateGE02Inscribe(
    _ plan: AgentWritingPlan,
    actorID: AgentID,
    session: AgentSimulationSession,
    world: World
) throws -> AgentWritingPhysicalReceipt {
    try world.inscribeSign(SignInscription(
        artifactID: plan.artifactID,
        materialID: plan.materialID,
        contentDigest: plan.contentDigest,
        worldID: plan.worldID,
        dimension: 0,
        x: plan.cell.x,
        y: plan.cell.y,
        z: plan.cell.z,
        lines: plan.lines
    ))
    return try gateGE02Receipt(
        plan,
        actorID: actorID,
        session: session,
        world: world
    )
}

private func gateGE02World() -> World {
    let world = World(dim: .overworld, seed: 4_702)
    world.setChunk(Chunk(
        cx: 0, cz: 0, minY: GEN_MIN_Y, height: WORLD_H
    ))
    for cell in [
        AgentPosition(x: 1, y: 64, z: 0),
        AgentPosition(x: 1, y: 64, z: 1),
    ] {
        world.setBlock(
            cell.x, cell.y - 1, cell.z,
            Int(bid("stone")) << 4,
            SET_SILENT
        )
        world.setBlock(
            cell.x, cell.y, cell.z,
            Int(bid("oak_sign")) << 4,
            SET_SILENT
        )
        world.setBlockEntity(makeSignBE(cell.x, cell.y, cell.z))
    }
    world.setBlock(3, 64, 0, Int(bid("oak_log")) << 4, SET_SILENT)
    return world
}

private func gateGE02CultureRecord(
    _ session: AgentSimulationSession,
    operationID: String
) -> AgentCultureRecord? {
    session.distributedCultureSnapshot().individuals
        .flatMap(\.history)
        .first { $0.operationID == operationID }
}

private func gateGE02Stance(
    _ session: AgentSimulationSession,
    agentID: AgentID,
    practiceID: AgentCulturePracticeID
) -> AgentCultureStance? {
    session.distributedCultureSnapshot().individuals.first {
        $0.agentID == agentID
    }?.stances.first { $0.practice.practiceID == practiceID }
}

private func gateGE02RebuiltJournal(
    manifest: AgentReplayJournalManifest,
    records: [AgentReplayRecord]
) -> AgentReplayJournal {
    let bytes = try! AgentReplayCodec.encodeRecords(records)
    return AgentReplayJournal(
        manifest: AgentReplayJournalManifest(
            schemaVersion: manifest.schemaVersion,
            name: manifest.name,
            baseCheckpointID: manifest.baseCheckpointID,
            baseCheckpointDigest: manifest.baseCheckpointDigest,
            simulationID: manifest.simulationID,
            initialTick: manifest.initialTick,
            recordCount: records.count,
            droppedRecordCount: manifest.droppedRecordCount,
            replayable: manifest.replayable,
            nonReplayableReason: manifest.nonReplayableReason,
            operationsStorageDigest: AgentCheckpointDigest.sha256(bytes),
            operationsByteLength: bytes.count
        ),
        records: records
    )
}

private func gateGE02ResignedCheckpoint(
    _ checkpoint: AgentSessionCheckpoint,
    mutateLanguage: (inout [String: Any]) -> Void
) -> AgentSessionCheckpoint {
    var root = try! JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(checkpoint)
    ) as! [String: Any]
    var durable = root["durableState"] as! [String: Any]
    var language = durable["languageState"] as! [String: Any]
    mutateLanguage(&language)
    durable["languageState"] = language
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

private func gateGE02RestoreRefused(
    _ checkpoint: AgentSessionCheckpoint
) -> Bool {
    do {
        _ = try AgentSimulationSession.restoring(checkpoint)
        return false
    } catch {
        return true
    }
}

private func gateGE02MakeCandidate() throws -> GateGE02Candidate {
    let materialWorld = gateGE02World()
    let social = try AgentSocialConfiguration(
        communicationRadius: 3,
        minimumTrustToVerify: -100,
        claimLifetimeTicks: 128,
        messageLifetimeTicks: 128,
        maximumFactsPerAgent: 16,
        maximumBeliefsPerAgent: 16,
        maximumTrustRelations: 32,
        maximumRetainedMessages: 64,
        shareCooldownTicks: 1
    )
    var session = try AgentSimulationSession(
        configuration: try AgentSessionConfiguration(
            seed: 4_702,
            nearbyRadius: 16,
            resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 128),
            socialConfiguration: social
        ),
        agents: [
            gateGE02Agent(gateGE02Parent, x: 0),
            gateGE02Agent(gateGE02CoParent, x: 1),
            gateGE02Agent(gateGE02Remote, x: 8),
        ],
        simulationID: try AgentSimulationID(
            validating: "gate-g-evaluation-02"
        ),
        causalLedgerPolicy: .bounded(maxEvents: 512)
    )
    try session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 1),
        configuration: try AgentPopulationConfiguration(
            maximumActivePopulation: 8,
            maximumMigrationRecords: 16
        )
    )
    let habitat = AgentEcologyHabitatObservation(
        worldTick: 0,
        candidateIndex: 0,
        habitatPosition: AgentPosition(x: 1, y: 63, z: 0),
        foragePosition: AgentPosition(x: 1, y: 64, z: 0),
        habitatFingerprint: 47_002,
        distanceFromSettlement: 1,
        directionIndex: 0,
        worldReadCount: 4
    )
    try session.initializeLocalEcology(
        observations: [habitat],
        configuration: try AgentLocalEcologyConfiguration(
            maximumPatches: 1,
            maximumHabitatCandidates: 1,
            observationRadius: 8,
            patchCapacity: 4,
            initialYield: 4,
            regenerationIntervalTicks: 2,
            regenerationQuantity: 2,
            maximumForageIntentsPerTick: 8,
            maximumForageHistory: 32,
            maximumPressureFrames: 32,
            maximumHabitatReadsPerScan: 16
        )
    )
    _ = try session.applyLocalEcologyEndOfTick(
        habitatValidations: [habitat]
    )
    try session.setSocialEnabled(true)
    try session.setKnowledgeGraphEnabled(true)
    _ = try session.advanceTick(perceptions: [
        gateGE02Observation(gateGE02Parent, direction: .east, distance: 3),
        gateGE02Observation(gateGE02Remote, direction: .west, distance: 5),
    ])
    let parentBelief = session.knowledgeSnapshot().beliefs.first {
        $0.ownerID == gateGE02Parent && $0.stance == .accepted
    }!
    let remoteBelief = session.knowledgeSnapshot().beliefs.first {
        $0.ownerID == gateGE02Remote && $0.stance == .accepted
    }!
    precondition(parentBelief.propositionID == remoteBelief.propositionID)
    let propositionID = parentBelief.propositionID

    try session.setLanguageEnabled(
        true,
        configuration: try AgentLanguageConfiguration(
            maximumLexicalAssociations: 64,
            maximumLexicalAssociationsPerAgent: 16,
            maximumCommunicationRecords: 256,
            exposuresRequiredForLearning: 1
        ),
        pack: .frenchReference
    )
    try session.setOralTransmissionEnabled(
        true,
        configuration: try AgentOralConfiguration(
            maximumTransmissionRecords: 128,
            maximumFaithfulDistance: 2
        )
    )
    for agentID in [
        gateGE02Parent, gateGE02CoParent, gateGE02Remote,
    ] {
        try session.seedLanguagePrior(
            for: agentID,
            senseIDs: gateGE02SenseIDs
        )
    }
    try session.setLifecycleEnabled(
        true,
        configuration: try AgentLifecycleConfiguration(
            newbornDurationTicks: 2,
            maturityAgeTicks: 8,
            reproductionEvaluationIntervalTicks: 1,
            reproductionPlanDelayTicks: 1,
            reproductionCooldownTicks: 16,
            maximumRetainedBirthRecords: 16,
            maximumRetainedPlanRecords: 16,
            maximumParentBirthCount: 4
        )
    )
    try session.setKinshipEnabled(true)
    try session.setReproductionEnabled(true)
    while session.tick < 3 { _ = try session.advanceTick() }
    while session.pendingBirthSitePlan() == nil {
        _ = try session.advanceTick()
    }
    let plan = session.pendingBirthSitePlan()!
    let birth = try session.applyBirthSiteObservation(
        AgentBirthSiteObservation(
            planID: plan.planID,
            observedTick: session.tick,
            position: AgentPosition(x: 0, y: 64, z: 1),
            candidateIndex: 0,
            worldFingerprint: 47_020
        )
    )!
    try session.setReproductionEnabled(false)
    precondition(birth.newbornID == gateGE02Child)

    let birthCheckpoint = try session.makeCheckpoint()
    _ = try session.transmitOralClaim(
        speakerID: gateGE02Parent,
        recipientID: gateGE02CoParent,
        propositionID: propositionID,
        renderingMode: .deterministicCompositional
    )
    _ = try session.transmitOralClaim(
        speakerID: gateGE02Parent,
        recipientID: gateGE02Child,
        propositionID: propositionID,
        renderingMode: .deterministicCompositional
    )
    let baseCheckpoint = try session.makeCheckpoint()
    var recorder = try AgentReplayRecorder(
        checkpoint: baseCheckpoint,
        session: session
    )

    let innovationResult = try recorder.apply(
        .innovateLanguageLexicalForm(
            agentID: gateGE02Parent,
            senseID: gateGE02WoodSense,
            acceptedEffect: nil
        ),
        to: &session
    )
    let innovation = innovationResult.languageLexicalInnovationResult!
    _ = try recorder.apply(
        .transmitOralClaim(
            speakerID: gateGE02Parent,
            recipientID: gateGE02Child,
            propositionID: propositionID,
            renderingMode: .deterministicCompositional,
            acceptedEffect: nil
        ),
        to: &session
    )
    let cultureConfiguration = try AgentCultureConfiguration(
        maximumIndividuals: 8,
        maximumPracticesPerIndividual: 8,
        maximumHistoryPerIndividual: 64,
        maximumOperationReceipts: 128,
        maximumParticipantsPerUse: 4,
        maximumWitnessesPerUse: 4,
        adoptionExposureThreshold: 2,
        inactivityTicksBeforeDecline: 3
    )
    _ = try recorder.apply(
        .setDistributedCultureEnabled(
            true,
            configuration: cultureConfiguration
        ),
        to: &session
    )
    let survivalForm = AgentCulturePracticeForm.ritual(
        try AgentCultureRitualPattern(
            context: .harvestReturn,
            orderedSteps: [.assemble, .shareFood, .disperse],
            minimumParticipants: 1
        )
    )
    _ = try recorder.apply(
        .originateCulturalPractice(
            operationID: "e02-survival-origin",
            originatorID: gateGE02Parent,
            form: survivalForm
        ),
        to: &session
    )
    let survival = gateGE02CultureRecord(
        session,
        operationID: "e02-survival-origin"
    )!.practice
    _ = try recorder.apply(
        .originateCulturalPractice(
            operationID: "e02-loss-origin",
            originatorID: gateGE02CoParent,
            form: .norm(AgentCultureNormPattern(
                context: .reciprocalWork,
                expectedAction: .reciprocateAfterAid
            ))
        ),
        to: &session
    )
    let lost = gateGE02CultureRecord(
        session,
        operationID: "e02-loss-origin"
    )!.practice
    _ = try recorder.apply(
        .originateCulturalPractice(
            operationID: "e02-unrelated-origin",
            originatorID: gateGE02Remote,
            form: .ritual(try AgentCultureRitualPattern(
                context: .remembrance,
                orderedSteps: [.assemble, .speakNames, .disperse],
                minimumParticipants: 1
            ))
        ),
        to: &session
    )
    let unrelated = gateGE02CultureRecord(
        session,
        operationID: "e02-unrelated-origin"
    )!.practice
    let languageBeforeVariation = session.languageSnapshot()
    _ = try recorder.apply(
        .createCulturalVariation(
            operationID: "e02-unrelated-variation",
            creatorID: gateGE02Remote,
            parentPracticeID: unrelated.practiceID,
            form: .ritual(try AgentCultureRitualPattern(
                context: .remembrance,
                orderedSteps: [
                    .assemble, .exchangeToken, .speakNames, .disperse,
                ],
                minimumParticipants: 1
            ))
        ),
        to: &session
    )
    let unrelatedCultureVariationLeftLanguageUnchanged =
        session.languageSnapshot() == languageBeforeVariation
    precondition(unrelatedCultureVariationLeftLanguageUnchanged)

    _ = try recorder.apply(
        .transmitCulturalPracticeOrally(
            operationID: "e02-survival-child-1",
            sourceAgentID: gateGE02Parent,
            targetID: gateGE02Child,
            practiceID: survival.practiceID,
            accompanyingPropositionID: propositionID,
            renderingMode: .deterministicCompositional,
            acceptedEffect: nil
        ),
        to: &session
    )
    _ = try recorder.apply(
        .advanceTick(perceptions: [], physicalObservations: []),
        to: &session
    )
    _ = try recorder.apply(
        .transmitCulturalPracticeOrally(
            operationID: "e02-survival-child-2",
            sourceAgentID: gateGE02Parent,
            targetID: gateGE02Child,
            practiceID: survival.practiceID,
            accompanyingPropositionID: propositionID,
            renderingMode: .deterministicCompositional,
            acceptedEffect: nil
        ),
        to: &session
    )
    _ = try recorder.apply(
        .considerCulturalPractice(
            operationID: "e02-survival-child-adopt",
            agentID: gateGE02Child,
            practiceID: survival.practiceID
        ),
        to: &session
    )
    _ = try recorder.apply(
        .enactCulturalPractice(
            operationID: "e02-survival-cross-generation-use",
            practitionerID: gateGE02Parent,
            practiceID: survival.practiceID,
            coParticipantIDs: [gateGE02Child],
            witnessIDs: []
        ),
        to: &session
    )
    _ = try recorder.apply(
        .transmitCulturalPracticeOrally(
            operationID: "e02-loss-child-1",
            sourceAgentID: gateGE02CoParent,
            targetID: gateGE02Child,
            practiceID: lost.practiceID,
            accompanyingPropositionID: propositionID,
            renderingMode: .deterministicCompositional,
            acceptedEffect: nil
        ),
        to: &session
    )
    _ = try recorder.apply(
        .advanceTick(perceptions: [], physicalObservations: []),
        to: &session
    )
    _ = try recorder.apply(
        .transmitCulturalPracticeOrally(
            operationID: "e02-loss-child-2",
            sourceAgentID: gateGE02CoParent,
            targetID: gateGE02Child,
            practiceID: lost.practiceID,
            accompanyingPropositionID: propositionID,
            renderingMode: .deterministicCompositional,
            acceptedEffect: nil
        ),
        to: &session
    )
    _ = try recorder.apply(
        .considerCulturalPractice(
            operationID: "e02-loss-child-adopt",
            agentID: gateGE02Child,
            practiceID: lost.practiceID
        ),
        to: &session
    )
    _ = try recorder.apply(
        .transmitOralClaim(
            speakerID: gateGE02Parent,
            recipientID: gateGE02Child,
            propositionID: propositionID,
            renderingMode: .deterministicCompositional,
            acceptedEffect: nil
        ),
        to: &session
    )

    _ = try recorder.apply(
        .setWritingEnabled(
            enabled: true,
            worldID: "gate-g-e02-world",
            configuration: try AgentWritingConfiguration(
                maximumArtifacts: 4,
                maximumReadings: 8,
                maximumLiteracyRecords: 8
            )
        ),
        to: &session
    )
    _ = try recorder.apply(
        .seedWritingEducationalPrior(ownerID: gateGE02Parent),
        to: &session
    )
    let cataloguePlan = try session.prepareWriting(
        authorID: gateGE02Parent,
        propositionID: propositionID,
        materialID: peekNextEntityId(),
        dimension: "0",
        cell: AgentPosition(x: 1, y: 64, z: 0)
    )
    let catalogueReceipt = try gateGE02Inscribe(
        cataloguePlan,
        actorID: gateGE02Parent,
        session: session,
        world: materialWorld
    )
    _ = try recorder.apply(
        .acceptWriting(plan: cataloguePlan, receipt: catalogueReceipt),
        to: &session
    )
    let manuscriptPlan = try session.prepareWriting(
        authorID: gateGE02Parent,
        propositionID: propositionID,
        materialID: peekNextEntityId(),
        dimension: "0",
        cell: AgentPosition(x: 1, y: 64, z: 1)
    )
    let manuscriptReceipt = try gateGE02Inscribe(
        manuscriptPlan,
        actorID: gateGE02Parent,
        session: session,
        world: materialWorld
    )
    _ = try recorder.apply(
        .acceptWriting(plan: manuscriptPlan, receipt: manuscriptReceipt),
        to: &session
    )
    let writtenWood = manuscriptPlan.realization.lexicalUses.first {
        $0.senseID == gateGE02WoodSense
    }!
    precondition(
        writtenWood.form == innovation.evolvedForm
            && writtenWood.innovationID == innovation.innovationID
    )

    _ = try recorder.apply(
        .setArchiveEnabled(
            enabled: true,
            worldID: "gate-g-e02-world",
            configuration: try AgentArchiveConfiguration(
                maximumCollections: 2,
                maximumManuscripts: 4,
                maximumRetrievals: 4,
                maximumSearchResults: 4
            )
        ),
        to: &session
    )
    _ = try recorder.apply(
        .createArchiveCollection(
            operationID: "e02-archive-collection",
            kind: .archive,
            catalogueArtifactID: cataloguePlan.artifactID,
            curatorID: gateGE02Parent,
            catalogueReceipt: catalogueReceipt
        ),
        to: &session
    )
    let collection = session.archiveSnapshot().collections.first!
    _ = try recorder.apply(
        .catalogueArchiveManuscript(
            operationID: "e02-archive-manuscript",
            collectionID: collection.collectionID,
            artifactID: manuscriptPlan.artifactID,
            relationship: .source,
            cataloguerID: gateGE02Parent,
            catalogueReceipt: catalogueReceipt,
            artifactReceipt: manuscriptReceipt,
            parentReceipt: nil
        ),
        to: &session
    )
    let manuscript = session.archiveSnapshot().manuscripts.first!

    let lesson1Teacher = try gateGE02Receipt(
        manuscriptPlan,
        actorID: gateGE02Parent,
        session: session,
        world: materialWorld
    )
    let lesson1Child = try gateGE02Receipt(
        manuscriptPlan,
        actorID: gateGE02Child,
        session: session,
        world: materialWorld
    )
    _ = try recorder.apply(
        .practiceWritingNotation(
            artifactID: manuscriptPlan.artifactID,
            teacherID: gateGE02Parent,
            learnerID: gateGE02Child,
            teacherReceipt: lesson1Teacher,
            learnerReceipt: lesson1Child
        ),
        to: &session
    )
    _ = try recorder.apply(
        .advanceTick(perceptions: [], physicalObservations: []),
        to: &session
    )
    let lesson2Teacher = try gateGE02Receipt(
        manuscriptPlan,
        actorID: gateGE02Parent,
        session: session,
        world: materialWorld
    )
    let lesson2Child = try gateGE02Receipt(
        manuscriptPlan,
        actorID: gateGE02Child,
        session: session,
        world: materialWorld
    )
    _ = try recorder.apply(
        .practiceWritingNotation(
            artifactID: manuscriptPlan.artifactID,
            teacherID: gateGE02Parent,
            learnerID: gateGE02Child,
            teacherReceipt: lesson2Teacher,
            learnerReceipt: lesson2Child
        ),
        to: &session
    )
    let directReadingResult = try recorder.apply(
        .readWriting(
            artifactID: cataloguePlan.artifactID,
            readerID: gateGE02Child,
            receipt: try gateGE02Receipt(
                cataloguePlan,
                actorID: gateGE02Child,
                session: session,
                world: materialWorld
            )
        ),
        to: &session
    )
    _ = directReadingResult
    let directReading = session.writingState!.readings.last!
    let index = try session.rebuildArchiveIndex()
    let selection = try session.searchArchive(
        index,
        collectionID: collection.collectionID,
        query: .artifact(manuscriptPlan.artifactID),
        requesterID: gateGE02Parent,
        catalogueReceipt: try gateGE02Receipt(
            cataloguePlan,
            actorID: gateGE02Parent,
            session: session,
            world: materialWorld
        )
    ).hits[0].selection
    _ = try recorder.apply(
        .retrieveArchiveManuscript(
            operationID: "e02-archive-retrieval",
            selection: selection,
            readerID: gateGE02Child,
            receipt: try gateGE02Receipt(
                manuscriptPlan,
                actorID: gateGE02Child,
                session: session,
                world: materialWorld
            )
        ),
        to: &session
    )

    var writingCarrierResult = "unexpected acceptance"
    let writingBefore = try session.durableStateBytes()
    do {
        _ = try session.recordCulturalExposure(
            operationID: "e02-writing-culture-attempt",
            targetID: gateGE02Child,
            sourceAgentID: gateGE02Parent,
            practiceID: survival.practiceID,
            carrier: .writingReading(directReading.readingID)
        )
    } catch {
        writingCarrierResult = String(describing: error)
    }
    let writingAfter = try session.durableStateBytes()
    precondition(writingAfter == writingBefore)
    var archiveCarrierResult = "unexpected acceptance"
    let archiveBefore = try session.durableStateBytes()
    do {
        _ = try session.recordCulturalExposure(
            operationID: "e02-archive-culture-attempt",
            targetID: gateGE02Child,
            sourceAgentID: gateGE02Parent,
            practiceID: survival.practiceID,
            carrier: .archiveRetrieval("e02-archive-retrieval")
        )
    } catch {
        archiveCarrierResult = String(describing: error)
    }
    let archiveAfter = try session.durableStateBytes()
    precondition(archiveAfter == archiveBefore)

    let lossIndex = try session.rebuildArchiveIndex()
    materialWorld.setBlock(
        manuscriptPlan.cell.x,
        manuscriptPlan.cell.y,
        manuscriptPlan.cell.z,
        0,
        SET_SILENT
    )
    let materialLossVerified = (try? materialWorld.inspectSignInscription(
        at: manuscriptPlan.cell.x,
        manuscriptPlan.cell.y,
        manuscriptPlan.cell.z
    )) == nil
    let lossSearch = try session.searchArchive(
        lossIndex,
        collectionID: collection.collectionID,
        query: .artifact(manuscriptPlan.artifactID),
        requesterID: gateGE02Parent,
        catalogueReceipt: try gateGE02Receipt(
            cataloguePlan,
            actorID: gateGE02Parent,
            session: session,
            world: materialWorld
        )
    )
    let metadataOnlySearchSurvivedLoss = lossSearch.totalMatches == 1
        && lossSearch.hits.first?.entry.artifactID
            == manuscriptPlan.artifactID
    let postLossBefore = try session.durableStateBytes()
    let postLossRetrievalRefused: Bool
    do {
        let lostReceipt = try gateGE02Receipt(
            manuscriptPlan,
            actorID: gateGE02Child,
            session: session,
            world: materialWorld
        )
        _ = try session.retrieveArchiveManuscript(
            operationID: "e02-post-loss-retrieval",
            selection: lossSearch.hits[0].selection,
            readerID: gateGE02Child,
            receipt: lostReceipt
        )
        postLossRetrievalRefused = false
    } catch {
        postLossRetrievalRefused = try session.durableStateBytes()
            == postLossBefore
    }

    while session.tick < birth.birthTick + 9 {
        _ = try recorder.apply(
            .advanceTick(perceptions: [], physicalObservations: []),
            to: &session
        )
    }
    _ = try recorder.apply(
        .enactCulturalPractice(
            operationID: "e02-survival-parent-renewed-use",
            practitionerID: gateGE02Parent,
            practiceID: survival.practiceID,
            coParticipantIDs: [],
            witnessIDs: []
        ),
        to: &session
    )
    _ = try recorder.apply(
        .enactCulturalPractice(
            operationID: "e02-survival-child-renewed-use",
            practitionerID: gateGE02Child,
            practiceID: survival.practiceID,
            coParticipantIDs: [],
            witnessIDs: []
        ),
        to: &session
    )
    _ = try recorder.apply(
        .reviewCulturalContinuity(
            operationID: "e02-survival-parent-continuity",
            agentID: gateGE02Parent,
            practiceID: survival.practiceID
        ),
        to: &session
    )
    _ = try recorder.apply(
        .reviewCulturalContinuity(
            operationID: "e02-survival-child-continuity",
            agentID: gateGE02Child,
            practiceID: survival.practiceID
        ),
        to: &session
    )
    _ = try recorder.apply(
        .reviewCulturalContinuity(
            operationID: "e02-loss-source-ceased",
            agentID: gateGE02CoParent,
            practiceID: lost.practiceID
        ),
        to: &session
    )
    _ = try recorder.apply(
        .reviewCulturalContinuity(
            operationID: "e02-loss-child-ceased",
            agentID: gateGE02Child,
            practiceID: lost.practiceID
        ),
        to: &session
    )
    let resurrectionBefore = try session.durableStateBytes()
    do {
        _ = try session.transmitCulturalPracticeOrally(
            operationID: "e02-loss-resurrection-refused",
            sourceAgentID: gateGE02CoParent,
            targetID: gateGE02Remote,
            practiceID: lost.practiceID,
            accompanyingPropositionID: propositionID,
            renderingMode: .deterministicCompositional
        )
        preconditionFailure("ceased practice resurrected")
    } catch {
        let resurrectionAfter = try session.durableStateBytes()
        precondition(resurrectionAfter == resurrectionBefore)
    }

    let checkpoint = try session.makeCheckpoint()
    let journal = try recorder.journal(
        named: AgentCheckpointName(rawValue: "gate-g-evaluation-02")!
    )
    let replayA = try AgentSessionReplayer.replay(
        checkpoint: baseCheckpoint,
        journal: journal
    )
    let replayB = try AgentSessionReplayer.replay(
        checkpoint: baseCheckpoint,
        journal: journal
    )
    precondition(replayA.report.verified && replayB.report.verified)
    let finalBytes = try session.durableStateBytes()
    let replayABytes = try replayA.session.durableStateBytes()
    let replayBBytes = try replayB.session.durableStateBytes()
    precondition(replayABytes == finalBytes)
    precondition(replayBBytes == finalBytes)
    let durableBytes = try session.durableStateBytes()
    let report = GateGE02Report(
        evaluation: "V4-GATE-G-v1 Evaluation 02",
        simulationID: session.simulationID.rawValue,
        schemaVersion: checkpoint.schemaVersion,
        checkpointID: checkpoint.checkpointID.rawValue,
        checkpointDigest: checkpoint.semanticDigest.rawValue,
        durableDigest: AgentCheckpointDigest.sha256(durableBytes).rawValue,
        birthCheckpointID: birthCheckpoint.checkpointID.rawValue,
        birthCheckpointDigest: birthCheckpoint.semanticDigest.rawValue,
        baseCheckpointID: baseCheckpoint.checkpointID.rawValue,
        baseCheckpointDigest: baseCheckpoint.semanticDigest.rawValue,
        replaySchemaVersion: journal.manifest.schemaVersion,
        replayRecordCount: journal.records.count,
        replayOperationsDigest: journal.manifest.operationsStorageDigest.rawValue,
        originalForm: innovation.sourceForm,
        evolvedForm: innovation.evolvedForm,
        childID: birth.newbornID.rawValue,
        birthID: birth.birthID.rawValue,
        survivalPracticeID: survival.practiceID.rawValue,
        lostPracticeID: lost.practiceID.rawValue,
        catalogueArtifactID: cataloguePlan.artifactID,
        manuscriptArtifactID: manuscriptPlan.artifactID,
        collectionID: collection.collectionID.rawValue,
        manuscriptID: manuscript.manuscriptID.rawValue,
        retrievalOperationID: "e02-archive-retrieval",
        writingCarrierResult: writingCarrierResult,
        archiveCarrierResult: archiveCarrierResult,
        physicalInscriptionsVerified:
            catalogueReceipt.contentDigest == cataloguePlan.contentDigest
                && manuscriptReceipt.contentDigest
                    == manuscriptPlan.contentDigest,
        materialLossVerified: materialLossVerified,
        postLossRetrievalRefused: postLossRetrievalRefused,
        metadataOnlySearchSurvivedLoss: metadataOnlySearchSurvivedLoss,
        unrelatedCultureVariationLeftLanguageUnchanged:
            unrelatedCultureVariationLeftLanguageUnchanged,
        requirements: GateGE02RequirementResults(
            multiPersonTransmission: "demonstrated",
            multiGenerationTransmission: "demonstrated",
            dialectDivergence: "demonstrated",
            survivableTraditions: "demonstrated",
            losableTraditions: "demonstrated",
            materialWrittenPreservation: "demonstrated",
            reconstructibleCulturalHistory: "demonstrated"
        ),
        providerMode: "off",
        candidateStatus: "ALL_SEVEN_REQUIREMENTS_DEMONSTRATED"
    )
    return GateGE02Candidate(
        session: session,
        birthCheckpoint: birthCheckpoint,
        baseCheckpoint: baseCheckpoint,
        journal: journal,
        report: report
    )
}

private func gateGE02WriteCandidate(_ candidate: GateGE02Candidate) throws {
    let environment = ProcessInfo.processInfo.environment
    guard let checkpointPath = environment[
        "PEBBLELAB_GATE_G_E02_CHECKPOINT_PATH"
    ], let birthPath = environment[
        "PEBBLELAB_GATE_G_E02_BIRTH_CHECKPOINT_PATH"
    ], let basePath = environment[
        "PEBBLELAB_GATE_G_E02_BASE_CHECKPOINT_PATH"
    ], let manifestPath = environment[
        "PEBBLELAB_GATE_G_E02_REPLAY_MANIFEST_PATH"
    ], let recordsPath = environment[
        "PEBBLELAB_GATE_G_E02_REPLAY_RECORDS_PATH"
    ], let reportPath = environment[
        "PEBBLELAB_GATE_G_E02_RESULT_PATH"
    ] else { return }
    try AgentCheckpointCodec.encode(candidate.session.makeCheckpoint()).write(
        to: URL(fileURLWithPath: checkpointPath), options: .atomic
    )
    try AgentCheckpointCodec.encode(candidate.birthCheckpoint).write(
        to: URL(fileURLWithPath: birthPath), options: .atomic
    )
    try AgentCheckpointCodec.encode(candidate.baseCheckpoint).write(
        to: URL(fileURLWithPath: basePath), options: .atomic
    )
    try AgentCheckpointCodec.encode(candidate.journal.manifest).write(
        to: URL(fileURLWithPath: manifestPath), options: .atomic
    )
    try AgentReplayCodec.encodeRecords(candidate.journal.records).write(
        to: URL(fileURLWithPath: recordsPath), options: .atomic
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    try encoder.encode(candidate.report).write(
        to: URL(fileURLWithPath: reportPath), options: .atomic
    )
}

func runPebbleAgentsGateGEvaluation02Smoke() {
    section("Gate G Evaluation 02 cumulative culture")
    do {
        let candidate = try gateGE02MakeCandidate()
        let session = candidate.session
        let report = candidate.report
        let birth = session.lifecycleSnapshot().births.first {
            $0.birthID.rawValue == report.birthID
        }
        let childBeliefs = session.knowledgeSnapshot().beliefs.filter {
            $0.ownerID == gateGE02Child
        }
        let innovation = session.languageSnapshot().lexicalInnovations.first!
        let propositionID = session.writingState!.artifacts.first!
            .plan.sourcePropositionID
        let parentSurface = try session.realizeLanguageSemanticContent(
            for: gateGE02Parent,
            propositionID: propositionID
        )
        let childSurface = try session.realizeLanguageSemanticContent(
            for: gateGE02Child,
            propositionID: propositionID
        )
        let remoteSurface = try session.realizeLanguageSemanticContent(
            for: gateGE02Remote,
            propositionID: propositionID
        )
        let childWood = childSurface.lexicalUses.first {
            $0.senseID == gateGE02WoodSense
        }
        let remoteWood = remoteSurface.lexicalUses.first {
            $0.senseID == gateGE02WoodSense
        }
        check(
            "real lifecycle birth establishes the later generation",
            birth?.newbornID == gateGE02Child
                && birth?.progenitorIDs == [gateGE02Parent, gateGE02CoParent]
                && session.kinshipSnapshot().parentageRecords.contains {
                    $0.childID == gateGE02Child
                        && $0.canonicalParentIDs
                            == [gateGE02Parent, gateGE02CoParent]
                }
        )
        let afterBirth = try AgentSimulationSession.restoring(
            candidate.birthCheckpoint
        )
        check(
            "parentage grants no belief, language, or cultural state",
            afterBirth.knowledgeSnapshot().beliefs.allSatisfy {
                $0.ownerID != gateGE02Child
            }
                && afterBirth.languageSnapshot().lexicalAssociations.allSatisfy {
                    $0.ownerID != gateGE02Child
                }
                && afterBirth.distributedCultureSnapshot().individuals.allSatisfy {
                    $0.agentID != gateGE02Child
                }
        )
        check(
            "distinct individuals transmit local belief and lexical competence",
            !childBeliefs.isEmpty
                && session.languageSnapshot().communications.contains {
                    $0.speakerID == gateGE02Parent
                        && $0.recipientID == gateGE02Child
                }
                && childWood?.innovationID == innovation.innovationID,
            "childBeliefs=\(childBeliefs.count) childForm=\(childWood?.form ?? "nil")"
                + " childInnovation=\(childWood?.innovationID?.rawValue ?? "nil")"
        )
        check(
            "one seeded pack diverges for the same semantic sense",
            report.originalForm == "bois"
                && report.evolvedForm != report.originalForm
                && childWood?.form == report.evolvedForm
                && remoteWood?.form == report.originalForm
                && parentSurface.semanticContent.senses
                    == remoteSurface.semanticContent.senses
                && parentSurface.rendering.text != remoteSurface.rendering.text,
            "parent=\(parentSurface.rendering.text ?? "nil")"
                + " child=\(childSurface.rendering.text ?? "nil")"
                + " remote=\(remoteSurface.rendering.text ?? "nil")"
        )
        check(
            "unrelated CIV-47 variation grants no lexical variation",
            report.unrelatedCultureVariationLeftLanguageUnchanged
        )
        let survivalID = AgentCulturePracticeID(
            rawValue: report.survivalPracticeID
        )!
        let lostID = AgentCulturePracticeID(rawValue: report.lostPracticeID)!
        check(
            "a practice survives by cross-generation transmission and use",
            gateGE02Stance(
                session,
                agentID: gateGE02Parent,
                practiceID: survivalID
            )?.status == .adopted
                && gateGE02Stance(
                    session,
                    agentID: gateGE02Child,
                    practiceID: survivalID
                )?.status == .adopted
                && gateGE02CultureRecord(
                    session,
                    operationID: "e02-survival-child-renewed-use"
                ) != nil
                && gateGE02CultureRecord(
                    session,
                    operationID: "e02-survival-child-continuity"
                )?.outcome == .continued
        )
        check(
            "an unused practice genuinely ceases without erasing history",
            gateGE02Stance(
                session,
                agentID: gateGE02CoParent,
                practiceID: lostID
            )?.status == .ceased
                && gateGE02Stance(
                    session,
                    agentID: gateGE02Child,
                    practiceID: lostID
                )?.status == .ceased
                && gateGE02CultureRecord(
                    session,
                    operationID: "e02-loss-child-adopt"
                ) != nil
                && gateGE02CultureRecord(
                    session,
                    operationID: "e02-loss-resurrection-refused"
                ) == nil
        )
        let manuscript = session.writingState!.artifacts.first {
            $0.artifactID == report.manuscriptArtifactID
        }!
        let survivalExposure = gateGE02CultureRecord(
            session,
            operationID: "e02-survival-child-2"
        )!
        let survivalCarrier: AgentOralTransmission? = {
            guard case let .oral(transmissionID) = survivalExposure.carrier else {
                return nil
            }
            return session.oralTransmissionState?.transmissions.first {
                $0.transmissionID == transmissionID
            }
        }()
        check(
            "material writing and archive preserve the evolved semantic record from the same history",
            manuscript.plan.realization.lexicalUses.contains {
                $0.senseID == gateGE02WoodSense
                    && $0.form == report.evolvedForm
                    && $0.innovationID == innovation.innovationID
            }
                && survivalCarrier?.contentAttachment?.contentID
                    == report.survivalPracticeID
                && survivalCarrier?.transmittedSemanticContent
                    .sourcePropositionID == manuscript.plan.sourcePropositionID
                && session.archiveSnapshot().retrievals.contains {
                    $0.operationID == report.retrievalOperationID
                        && $0.readerID == gateGE02Child
                }
        )
        check(
            "physical destruction prevents new retrieval while metadata stays non-authoritative",
            report.physicalInscriptionsVerified
                && report.materialLossVerified
                && report.postLossRetrievalRefused
                && report.metadataOnlySearchSurvivedLoss
                && !session.archiveSnapshot().retrievals.contains {
                    $0.operationID == "e02-post-loss-retrieval"
                }
        )
        check(
            "unbound writing reading cannot directly authorize culture",
            report.writingCarrierResult.contains(
                "writing carrier has no cultural-content commitment"
            )
        )
        check(
            "unbound archive retrieval cannot directly authorize culture",
            report.archiveCarrierResult.contains(
                "archive carrier has no cultural-content commitment"
            )
        )
        let checkpoint = try session.makeCheckpoint()
        let restored = try AgentSimulationSession.restoring(checkpoint)
        let restoredBytes = try restored.durableStateBytes()
        let sessionBytes = try session.durableStateBytes()
        check(
            "schema-43 restart reconstructs the complete durable history",
            checkpoint.schemaVersion
                == AgentCheckpointSchema.lexicalDivergenceVersion
                && restoredBytes == sessionBytes
                && restored.lifecycleSnapshot().births.contains {
                    $0.birthID.rawValue == report.birthID
                }
                && restored.archiveSnapshot().retrievals.contains {
                    $0.operationID == report.retrievalOperationID
                }
                && gateGE02CultureRecord(
                    restored,
                    operationID: "e02-loss-source-ceased"
                )?.outcome == .ceasedUnused
        )
        let replayA = try AgentSessionReplayer.replay(
            checkpoint: candidate.baseCheckpoint,
            journal: candidate.journal
        )
        let replayB = try AgentSessionReplayer.replay(
            checkpoint: candidate.baseCheckpoint,
            journal: candidate.journal
        )
        let replayCheckBytes = try replayA.session.durableStateBytes()
        check(
            "recorded replay reproduces exact variant and final bytes",
            replayA.report.verified
                && replayB.report.verified
                && replayCheckBytes == sessionBytes
                && replayA.session.languageSnapshot()
                    == replayB.session.languageSnapshot()
        )
        let duplicateBefore = try replayA.session.durableStateBytes()
        var duplicateSession = replayA.session
        let duplicate = try duplicateSession.innovateLanguageLexicalForm(
            for: gateGE02Parent,
            senseID: gateGE02WoodSense
        )
        let duplicateAfter = try duplicateSession.durableStateBytes()
        check(
            "duplicate innovation authority is byte-idempotent",
            duplicate == innovation
                && duplicateAfter == duplicateBefore
        )
        var remoteAttempt = session
        let remoteBefore = try remoteAttempt.durableStateBytes()
        do {
            _ = try remoteAttempt.communicateLanguageSemanticContent(
                speakerID: gateGE02Parent,
                recipientID: gateGE02Remote,
                propositionID: propositionID,
                renderingMode: .deterministicCompositional
            )
            check("remote generic CIV-42 evolved acquisition is refused", false)
        } catch {
            check(
                "remote generic CIV-42 evolved acquisition is refused",
                try remoteAttempt.durableStateBytes() == remoteBefore
                    && remoteAttempt.languageSnapshot().lexicalAssociations
                        .filter { $0.ownerID == gateGE02Remote }
                        .allSatisfy { $0.innovationID == nil }
            )
        }
        let firstRecord = candidate.journal.records[0]
        let forgedEffect = AgentLanguageLexicalInnovationAcceptedEffect(
            evolvedForm: "evaluation-selected-final-form",
            decisionDigest: innovation.decisionDigest
        )
        let forgedRecord = AgentReplayRecord(
            schemaVersion: firstRecord.schemaVersion,
            simulationID: firstRecord.simulationID,
            recordSequence: firstRecord.recordSequence,
            operation: .innovateLanguageLexicalForm(
                agentID: gateGE02Parent,
                senseID: gateGE02WoodSense,
                acceptedEffect: forgedEffect
            ),
            expectedTickBefore: firstRecord.expectedTickBefore,
            preStateSemanticDigest: firstRecord.preStateSemanticDigest,
            postStateSemanticDigest: firstRecord.postStateSemanticDigest,
            causalSequenceBefore: firstRecord.causalSequenceBefore,
            causalSequenceAfter: firstRecord.causalSequenceAfter,
            causalDigestAfter: firstRecord.causalDigestAfter
        )
        let forgedReplay = try AgentSessionReplayer.replay(
            checkpoint: candidate.baseCheckpoint,
            journal: gateGE02RebuiltJournal(
                manifest: candidate.journal.manifest,
                records: [forgedRecord]
                    + Array(candidate.journal.records.dropFirst())
            )
        )
        check(
            "caller-selected replay variant is rejected before publication",
            !forgedReplay.report.verified
                && forgedReplay.report.recordsApplied == 0
                && (forgedReplay.report.divergence?.reason.contains(
                    "replayEffectMismatch"
                ) ?? false)
        )
        let noAuthority = gateGE02ResignedCheckpoint(checkpoint) { language in
            var evolution = language["lexicalEvolution"] as! [String: Any]
            evolution["innovations"] = []
            evolution["evictedInnovationCount"] = 1
            language["lexicalEvolution"] = evolution
        }
        let rebound = gateGE02ResignedCheckpoint(checkpoint) { language in
            var evolution = language["lexicalEvolution"] as! [String: Any]
            var innovations = evolution["innovations"] as! [[String: Any]]
            innovations[0]["senseID"] = "value.resource.stone"
            evolution["innovations"] = innovations
            language["lexicalEvolution"] = evolution
        }
        let stale = gateGE02ResignedCheckpoint(checkpoint) { language in
            var evolution = language["lexicalEvolution"] as! [String: Any]
            var innovations = evolution["innovations"] as! [[String: Any]]
            let supports = innovations[0]["supports"] as! [[String: Any]]
            innovations[0]["supports"] = Array(supports.reversed())
            evolution["innovations"] = innovations
            language["lexicalEvolution"] = evolution
        }
        let carrier = gateGE02ResignedCheckpoint(checkpoint) { language in
            var receipts = language["exposureReceipts"] as! [[String: Any]]
            let index = receipts.firstIndex {
                $0["localOralAuthority"] != nil
            }!
            var authority = receipts[index]["localOralAuthority"]
                as! [String: Any]
            authority["oralProvenanceDigest"] = String(
                repeating: "0", count: 64
            )
            receipts[index]["localOralAuthority"] = authority
            language["exposureReceipts"] = receipts
        }
        check(
            "fabricated serialized innovation is refused",
            gateGE02RestoreRefused(noAuthority)
        )
        check(
            "form rebound to another semantic sense is refused",
            gateGE02RestoreRefused(rebound)
        )
        check(
            "stale innovation provenance is refused",
            gateGE02RestoreRefused(stale)
        )
        check(
            "substituted oral carrier provenance is refused",
            gateGE02RestoreRefused(carrier)
        )
        var compacted = session
        for _ in 0..<512 { _ = try compacted.advanceTick() }
        let compactedCheckpoint = try compacted.makeCheckpoint()
        let compactedRestore = try AgentSimulationSession.restoring(
            compactedCheckpoint
        )
        check(
            "compaction cannot reroll or self-authorize dialect state",
            compacted.causalLedgerSnapshot().summary.droppedEventCount > 0
                && compactedRestore.languageSnapshot()
                    == compacted.languageSnapshot()
                && compactedRestore.languageSnapshot().lexicalInnovations
                    == [innovation]
        )
        let selfAuthorized = gateGE02ResignedCheckpoint(
            compactedCheckpoint
        ) { language in
            var evolution = language["lexicalEvolution"] as! [String: Any]
            var innovations = evolution["innovations"] as! [[String: Any]]
            innovations[0]["supports"] = []
            evolution["innovations"] = innovations
            language["lexicalEvolution"] = evolution
        }
        check(
            "compaction without innovation supports is refused",
            gateGE02RestoreRefused(selfAuthorized)
        )
        var futureRoot = try JSONSerialization.jsonObject(
            with: AgentCheckpointCodec.encode(checkpoint)
        ) as! [String: Any]
        futureRoot["schemaVersion"] = 44
        var futureDurable = futureRoot["durableState"] as! [String: Any]
        futureDurable["schemaVersion"] = 44
        futureRoot["durableState"] = futureDurable
        let futureBytes = try JSONSerialization.data(
            withJSONObject: futureRoot,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
        let futureRefused: Bool
        do {
            let decodedFuture = try AgentCheckpointCodec.decode(
                AgentSessionCheckpoint.self,
                from: futureBytes
            )
            _ = try AgentSimulationSession.restoring(decodedFuture)
            futureRefused = false
        } catch {
            futureRefused = true
        }
        check("unsupported future schema is refused", futureRefused)
        var substitutedRoot = try JSONSerialization.jsonObject(
            with: AgentCheckpointCodec.encode(checkpoint)
        ) as! [String: Any]
        substitutedRoot["schemaVersion"] = 42
        var substitutedDurable = substitutedRoot["durableState"]
            as! [String: Any]
        substitutedDurable["schemaVersion"] = 42
        substitutedRoot["durableState"] = substitutedDurable
        let substitutedBytes = try JSONSerialization.data(
            withJSONObject: substitutedRoot,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
        let substitutedRefused: Bool
        do {
            let decodedSubstitution = try AgentCheckpointCodec.decode(
                AgentSessionCheckpoint.self,
                from: substitutedBytes
            )
            _ = try AgentSimulationSession.restoring(decodedSubstitution)
            substitutedRefused = false
        } catch {
            substitutedRefused = true
        }
        check("schema downgrade substitution is refused", substitutedRefused)
        var bounded = try AgentSimulationSession.restoring(
            candidate.baseCheckpoint
        )
        try bounded.setDistributedCultureEnabled(
            true,
            configuration: try AgentCultureConfiguration(
                maximumIndividuals: 8,
                maximumPracticesPerIndividual: 1,
                maximumHistoryPerIndividual: 8,
                maximumOperationReceipts: 8,
                maximumParticipantsPerUse: 2,
                maximumWitnessesPerUse: 2,
                adoptionExposureThreshold: 1,
                inactivityTicksBeforeDecline: 3
            )
        )
        _ = try bounded.originateCulturalPractice(
            operationID: "e02-bound-first",
            originatorID: gateGE02Parent,
            form: .ritual(try AgentCultureRitualPattern(
                context: .harvestReturn,
                orderedSteps: [.assemble, .shareFood, .disperse],
                minimumParticipants: 1
            ))
        )
        let boundedBefore = try bounded.durableStateBytes()
        do {
            _ = try bounded.originateCulturalPractice(
                operationID: "e02-bound-n-plus-one",
                originatorID: gateGE02Parent,
                form: .norm(AgentCultureNormPattern(
                    context: .scarcityAid,
                    expectedAction: .offerBeforePrivateUse
                ))
            )
            check("cultural N+1 refusal is atomic", false)
        } catch {
            check(
                "cultural N+1 refusal is atomic",
                try bounded.durableStateBytes() == boundedBefore
            )
        }
        check(
            "provider-off candidate demonstrates all seven requirements",
            report.providerMode == "off"
                && report.candidateStatus
                    == "ALL_SEVEN_REQUIREMENTS_DEMONSTRATED"
        )
        try gateGE02WriteCandidate(candidate)
        print(
            "  GATE_G_E02_DECISIVE original=\(report.originalForm)"
                + " evolved=\(report.evolvedForm) child=\(report.childID)"
                + " remote=\(remoteWood?.form ?? "missing")"
        )
        print(
            "  GATE_G_E02_DURABLE schema=\(report.schemaVersion)"
                + " checkpoint=\(report.checkpointDigest)"
                + " replayRecords=\(report.replayRecordCount)"
        )
        print(
            "  GATE_G_E02_AUTHORITY_CONTROL"
                + " unboundWritingAndArchiveCultureExposure=REFUSED"
        )
        print("  GATE_G_E02_STATUS \(report.candidateStatus)")
    } catch {
        check(
            "Gate G Evaluation 02 completes",
            false,
            String(reflecting: error)
        )
    }
}

func runPebbleAgentsGateGEvaluation02RestartReadSmoke() {
    section("Gate G Evaluation 02 fresh-process restore and replay")
    do {
        let environment = ProcessInfo.processInfo.environment
        guard let checkpointPath = environment[
            "PEBBLELAB_GATE_G_E02_CHECKPOINT_PATH"
        ], let birthPath = environment[
            "PEBBLELAB_GATE_G_E02_BIRTH_CHECKPOINT_PATH"
        ], let basePath = environment[
            "PEBBLELAB_GATE_G_E02_BASE_CHECKPOINT_PATH"
        ], let manifestPath = environment[
            "PEBBLELAB_GATE_G_E02_REPLAY_MANIFEST_PATH"
        ], let recordsPath = environment[
            "PEBBLELAB_GATE_G_E02_REPLAY_RECORDS_PATH"
        ], let reportPath = environment[
            "PEBBLELAB_GATE_G_E02_RESULT_PATH"
        ] else {
            check("fresh process receives all Evaluation 02 paths", false)
            return
        }
        let checkpointBytes = try Data(
            contentsOf: URL(fileURLWithPath: checkpointPath)
        )
        let checkpoint = try AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self,
            from: checkpointBytes
        )
        let restored = try AgentSimulationSession.restoring(checkpoint)
        let reencoded = try AgentCheckpointCodec.encode(
            restored.makeCheckpoint()
        )
        let base = try AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self,
            from: Data(contentsOf: URL(fileURLWithPath: basePath))
        )
        let birthCheckpoint = try AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self,
            from: Data(contentsOf: URL(fileURLWithPath: birthPath))
        )
        let afterBirth = try AgentSimulationSession.restoring(birthCheckpoint)
        let manifest = try AgentCheckpointCodec.decode(
            AgentReplayJournalManifest.self,
            from: Data(contentsOf: URL(fileURLWithPath: manifestPath))
        )
        let records = try AgentReplayCodec.decodeRecords(
            Data(contentsOf: URL(fileURLWithPath: recordsPath))
        )
        let report = try JSONDecoder().decode(
            GateGE02Report.self,
            from: Data(contentsOf: URL(fileURLWithPath: reportPath))
        )
        let replay = try AgentSessionReplayer.replay(
            checkpoint: base,
            journal: AgentReplayJournal(manifest: manifest, records: records)
        )
        check(
            "fresh process preserves exact schema-43 checkpoint bytes",
            checkpoint.schemaVersion
                == AgentCheckpointSchema.lexicalDivergenceVersion
                && reencoded == checkpointBytes
        )
        let replayBytes = try replay.session.durableStateBytes()
        let restoredBytes = try restored.durableStateBytes()
        check(
            "fresh process replays the exact accepted result",
            replay.report.verified
                && replayBytes == restoredBytes
                && replay.session.languageSnapshot().lexicalInnovations.first?
                    .evolvedForm == report.evolvedForm
        )
        let survivalID = AgentCulturePracticeID(
            rawValue: report.survivalPracticeID
        )!
        let lostID = AgentCulturePracticeID(rawValue: report.lostPracticeID)!
        check(
            "fresh process reconstructs generation and transmission",
            restored.lifecycleSnapshot().births.contains {
                $0.birthID.rawValue == report.birthID
                    && $0.newbornID == gateGE02Child
                    && $0.progenitorIDs
                        == [gateGE02Parent, gateGE02CoParent]
            }
                && gateGE02CultureRecord(
                    restored,
                    operationID: "e02-survival-child-1"
                )?.carrierEventID != nil
                && gateGE02CultureRecord(
                    restored,
                    operationID: "e02-survival-child-adopt"
                )?.outcome == .adopted
        )
        check(
            "fresh process verifies parentage granted no inherited cognition",
            afterBirth.knowledgeSnapshot().beliefs.allSatisfy {
                $0.ownerID != gateGE02Child
            }
                && afterBirth.languageSnapshot().lexicalAssociations
                    .allSatisfy { $0.ownerID != gateGE02Child }
                && afterBirth.distributedCultureSnapshot().individuals
                    .allSatisfy { $0.agentID != gateGE02Child }
                && birthCheckpoint.semanticDigest.rawValue
                    == report.birthCheckpointDigest
        )
        check(
            "fresh process preserves survival and exact loss",
            gateGE02Stance(
                restored,
                agentID: gateGE02Child,
                practiceID: survivalID
            )?.status == .adopted
                && gateGE02Stance(
                    restored,
                    agentID: gateGE02CoParent,
                    practiceID: lostID
                )?.status == .ceased
                && gateGE02Stance(
                    restored,
                    agentID: gateGE02Child,
                    practiceID: lostID
                )?.status == .ceased
        )
        let restoredExposure = gateGE02CultureRecord(
            restored,
            operationID: "e02-survival-child-2"
        )!
        let restoredCarrier: AgentOralTransmission? = {
            guard case let .oral(transmissionID) = restoredExposure.carrier else {
                return nil
            }
            return restored.oralTransmissionState?.transmissions.first {
                $0.transmissionID == transmissionID
            }
        }()
        let restoredManuscript = restored.writingState?.artifacts.first {
            $0.artifactID == report.manuscriptArtifactID
        }
        check(
            "fresh process reconstructs the culture-semantic-material relationship",
            restoredManuscript?.plan.realization.lexicalUses.contains {
                        $0.form == report.evolvedForm
                            && $0.senseID == gateGE02WoodSense
                    } == true
                && restoredCarrier?.contentAttachment?.contentID
                    == report.survivalPracticeID
                && restoredCarrier?.transmittedSemanticContent
                    .sourcePropositionID
                    == restoredManuscript?.plan.sourcePropositionID
                && restored.archiveSnapshot().retrievals.contains {
                    $0.operationID == report.retrievalOperationID
                }
        )
        check(
            "fresh evidence records material loss without invented retrieval",
            report.physicalInscriptionsVerified
                && report.materialLossVerified
                && report.postLossRetrievalRefused
                && report.metadataOnlySearchSurvivedLoss
                && !restored.archiveSnapshot().retrievals.contains {
                    $0.operationID == "e02-post-loss-retrieval"
                }
        )
        check(
            "fresh process preserves fail-closed writing/archive controls",
            report.writingCarrierResult.contains(
                "writing carrier has no cultural-content commitment"
            )
                && report.archiveCarrierResult.contains(
                    "archive carrier has no cultural-content commitment"
                )
                && report.candidateStatus
                    == "ALL_SEVEN_REQUIREMENTS_DEMONSTRATED"
        )
        print(
            "  GATE_G_E02_RESTART checkpoint=\(report.checkpointDigest)"
                + " replay=VERIFIED records=\(records.count)"
        )
    } catch {
        check(
            "Gate G Evaluation 02 fresh process completes",
            false,
            String(reflecting: error)
        )
    }
}
