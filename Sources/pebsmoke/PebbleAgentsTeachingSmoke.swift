import Foundation
import PebbleAgents

private let teachingHome = AgentPosition(x: 0, y: 64, z: 0)

private func teachingAgent(
    _ ordinal: Int,
    position: AgentPosition,
    hunger: Double = 0
) -> AgentSessionAgentState {
    AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: position,
        needs: AgentNeeds(hunger: hunger, fatigue: 0, curiosity: 0, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "teaching fixture", startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func teachingLifecycle(
    newborn: Int = 8,
    maturity: Int = 24
) -> AgentLifecycleConfiguration {
    try! AgentLifecycleConfiguration(
        newbornDurationTicks: newborn,
        maturityAgeTicks: maturity,
        reproductionEvaluationIntervalTicks: 1,
        reproductionPlanDelayTicks: 1,
        reproductionCooldownTicks: 1,
        maximumRetainedBirthRecords: 32,
        maximumRetainedPlanRecords: 32,
        maximumParentBirthCount: 16
    )
}

private func teachingBase(
    _ simulationID: String,
    teachingConfiguration: AgentTeachingConfiguration = .live,
    activateTeaching: Bool = true,
    survival: AgentSurvivalConfiguration = .live,
    agents: [AgentSessionAgentState]? = nil
) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 83, nearbyRadius: 8, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8, memoryPolicy: .bounded(maxEntries: 128),
            campStockCapacity: 128, survivalConfiguration: survival,
            socialConfiguration: try! AgentSocialConfiguration(shareCooldownTicks: 1)
        ),
        agents: agents ?? [
            teachingAgent(0, position: teachingHome),
            teachingAgent(1, position: AgentPosition(x: 1, y: 64, z: 0)),
            teachingAgent(2, position: AgentPosition(x: 2, y: 64, z: 0)),
        ],
        simulationID: try! AgentSimulationID(validating: simulationID),
        causalLedgerPolicy: .bounded(maxEvents: 32_768)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: teachingHome,
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3),
        configuration: .live
    )
    try! session.setLifecycleEnabled(true, configuration: teachingLifecycle())
    try! session.setSkillsEnabled(true)
    if activateTeaching {
        try! session.setTeachingEnabled(true, configuration: teachingConfiguration)
    }
    return session
}

@discardableResult
private func teachingMaterialSuccess(
    _ session: inout AgentSimulationSession,
    agentID: AgentID,
    index: Int,
    recorder: inout AgentReplayRecorder?
) -> (source: AgentCausalEventID, skill: AgentCausalEventID) {
    let interaction = AgentInteractionOutcome(
        interactionId: "teaching-material-\(agentID.rawValue)-\(index)",
        agentId: agentID.rawValue, tick: session.tick,
        target: AgentPosition(x: 20 + index, y: 64, z: index),
        resource: .wood, status: .succeeded,
        inventoryDelta: AgentInventoryDelta(resource: .wood, quantity: 1),
        reason: "bounded material fixture", source: .sandboxFixture
    )
    if recorder != nil {
        _ = try! recorder!.apply(.interactionOutcome(interaction), to: &session)
    } else {
        try! session.applyInteractionOutcome(interaction)
    }
    let intent = AgentDeliveryIntent(
        deliveryId: "teaching-delivery-\(agentID.rawValue)-\(index)",
        agentId: agentID.rawValue, tick: session.tick,
        position: try! session.state(for: agentID).position
    )
    var preview = session
    let delivery = try! preview.deliverResources(intent)
    if recorder != nil {
        _ = try! recorder!.apply(.deliveryOutcome(delivery), to: &session)
    } else {
        try! session.applyDeliveryOutcome(delivery)
    }
    let practice = session.skillProfile(for: agentID)!.domainPractices.first {
        $0.domain == .materialHandling
    }!
    return (practice.lastSourceSuccessEventID, practice.lastSkillPracticeEventID)
}

private func teachingTrain(
    _ session: inout AgentSimulationSession,
    agentID: AgentID,
    count: Int,
    baseIndex: Int,
    recorder: inout AgentReplayRecorder?
) {
    for offset in 0..<count {
        teachingMaterialSuccess(
            &session, agentID: agentID, index: baseIndex + offset,
            recorder: &recorder
        )
    }
}

private func teachingRequest(
    _ session: AgentSimulationSession,
    studentID: AgentID,
    candidates: [AgentMentorCandidateConsent],
    requestID: String,
    accepts: Bool = true,
    domain: AgentSkillDomain = .materialHandling
) -> AgentMentorSelectionRequest {
    AgentMentorSelectionRequest(
        requestID: requestID, studentID: studentID, domain: domain,
        studentAccepts: accepts, candidates: candidates,
        requestedAtTick: session.tick
    )
}

@discardableResult
private func teachingForageSuccess(
    _ session: inout AgentSimulationSession,
    agentID: AgentID,
    index: Int
) -> (source: AgentCausalEventID, skill: AgentCausalEventID) {
    session.setEconomyEnabled(true)
    session.setNaturalResourcesEnabled(true)
    let actor = try! session.state(for: agentID)
    let target = AgentPosition(
        x: actor.position.x + 1, y: actor.position.y, z: actor.position.z
    )
    _ = try! session.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: agentID.rawValue,
        resourceObservations: [AgentResourceObservation(
            resource: .wood, target: target, direction: .east,
            distanceManhattan: 1, quantityAvailable: 1,
            source: .naturalWorld,
            expectedBlockFingerprint: 9_000 + index
        )]
    )])
    try! session.applyInteractionOutcome(AgentInteractionOutcome(
        interactionId: "teaching-forage-\(agentID.rawValue)-\(index)",
        agentId: agentID.rawValue, tick: session.tick, target: target,
        resource: .wood, status: .succeeded,
        inventoryDelta: AgentInventoryDelta(resource: .wood, quantity: 0),
        reason: "pebble-harvest:oak_logx1", source: .naturalWorld,
        expectedBlockFingerprint: 9_000 + index
    ))
    let practice = session.skillProfile(for: agentID)!.domainPractices.first {
        $0.domain == .foraging
    }!
    return (practice.lastSourceSuccessEventID, practice.lastSkillPracticeEventID)
}

private func teachingObservation(
    _ session: AgentSimulationSession,
    engagement: AgentApprenticeshipEngagement,
    source: AgentCausalEventID,
    studentPosition: AgentPosition? = nil
) -> AgentTeachingObservation {
    let teacherPosition = try! session.state(for: engagement.teacherID).position
    let actualStudentPosition = try! session.state(for: engagement.studentID).position
    let reportedStudentPosition = studentPosition ?? actualStudentPosition
    let distance = abs(teacherPosition.x - reportedStudentPosition.x)
        + abs(teacherPosition.y - reportedStudentPosition.y)
        + abs(teacherPosition.z - reportedStudentPosition.z)
    let physical = session.configuration.physicalChannelConfiguration
    return AgentTeachingObservation(
        apprenticeshipID: engagement.apprenticeshipID,
        teacherID: engagement.teacherID, studentID: engagement.studentID,
        domain: engagement.domain, sourceSuccessEventID: source,
        teacherPosition: teacherPosition, studentPosition: reportedStudentPosition,
        distanceManhattan: distance,
        soundClarity: physical.soundClarity(
            distanceManhattan: distance, opaqueOcclusionCount: 0
        ),
        gestureClarity: physical.gestureClarity(
            distanceManhattan: distance, lineOfSight: true
        ),
        opaqueOcclusionCount: 0, lineOfSight: true, chunksReady: true,
        observedAtTick: session.tick
    )
}

private func teachingEstablishTrust(
    _ session: inout AgentSimulationSession,
    senderID: AgentID,
    recipientID: AgentID
) {
    try! session.setSocialEnabled(true)
    let recipientPosition = try! session.state(for: recipientID).position
    let target = recipientPosition
    let observation = AgentResourceObservation(
        resource: .wood, target: target, direction: .west,
        distanceManhattan: 1, quantityAvailable: 1, source: .naturalWorld,
        expectedBlockFingerprint: 1_911
    )
    var belief: AgentSocialBelief?
    for attempt in 0..<8 where belief == nil {
        let perceptions = attempt == 0
            ? [AgentPerceptionInput(
                agentId: senderID.rawValue,
                socialResourceObservations: [observation]
            )] : []
        _ = try! session.advanceTick(perceptions: perceptions)
        belief = session.socialSnapshot().beliefs.first {
            $0.senderID == senderID && $0.ownerID == recipientID
        }
    }
    precondition(belief != nil, "teaching trust fixture did not deliver belief")
    for _ in 0..<4 {
        let result = try! session.advanceTick()
        if result.agents.first(where: { $0.agentId == recipientID.rawValue })?
            .action.name == "verify_information" { break }
    }
    _ = try! session.applySocialVerification(AgentSocialVerificationObservation(
        beliefID: belief!.beliefID, verifierID: recipientID,
        position: target, chunkReady: true,
        observedBlockFingerprint: 1_911, observedResource: .wood
    ))
    precondition(
        session.trustScore(
            sourceAgentId: recipientID.rawValue, targetAgentId: senderID.rawValue
        ) > 0
    )
}

private let teachingCareHabitat = AgentEcologyHabitatObservation(
    worldTick: 0, candidateIndex: 0,
    habitatPosition: AgentPosition(x: 1, y: 63, z: 0),
    foragePosition: AgentPosition(x: 1, y: 64, z: 0),
    habitatFingerprint: 1_912, distanceFromSettlement: 1,
    directionIndex: 0, worldReadCount: 4
)

private func teachingJuvenileSession() -> (AgentSimulationSession, AgentID) {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 89, nearbyRadius: 8, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8, memoryPolicy: .bounded(maxEntries: 128),
            campStockCapacity: 128
        ),
        agents: [
            teachingAgent(0, position: teachingHome),
            teachingAgent(1, position: AgentPosition(x: 1, y: 64, z: 0)),
            teachingAgent(2, position: AgentPosition(x: 0, y: 64, z: 2)),
        ],
        simulationID: try! AgentSimulationID(validating: "teaching-juvenile"),
        causalLedgerPolicy: .bounded(maxEvents: 32_768)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: teachingHome,
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3), configuration: .live
    )
    try! session.initializeLocalEcology(observations: [teachingCareHabitat])
    _ = try! session.applyLocalEcologyEndOfTick(
        habitatValidations: [teachingCareHabitat]
    )
    try! session.setLifecycleEnabled(
        true, configuration: teachingLifecycle(newborn: 1, maturity: 64)
    )
    try! session.setKinshipEnabled(true)
    try! session.setHouseholdsEnabled(true)
    session.setSurvivalEnabled(true)
    try! session.setDependentCareEnabled(true)
    try! session.setSkillsEnabled(true)
    var recorder: AgentReplayRecorder? = nil
    let teacherID = AgentID(rawValue: "agent_2")!
    teachingTrain(
        &session, agentID: teacherID, count: 3, baseIndex: 3_000,
        recorder: &recorder
    )
    try! session.setTeachingEnabled(true)
    try! session.setReproductionEnabled(true)
    for _ in 0..<32 where session.pendingBirthSitePlan() == nil {
        _ = try! session.advanceTick()
    }
    let plan = session.pendingBirthSitePlan()!
    for _ in 0..<32 where session.tick < plan.dueTick {
        _ = try! session.advanceTick()
    }
    _ = try! session.applyBirthSiteObservation(AgentBirthSiteObservation(
        planID: plan.planID, observedTick: session.tick,
        position: AgentPosition(x: 0, y: 64, z: 1), candidateIndex: 0,
        worldFingerprint: 19_001
    ))
    let child = session.lifecycleSnapshot().births.last!.newbornID
    return (session, child)
}

func runPebbleAgentsTeachingSmoke() {
    section("pebble agents bounded demonstration and apprenticeship")

    let live = AgentTeachingConfiguration.live
    check("teaching gate bounds every collection", live.maximumMentorCandidates == 32
        && live.maximumActiveApprenticeships == 128
        && live.maximumRetainedApprenticeships == 256
        && live.maximumApprenticesPerTeacher == 4
        && live.maximumRetainedDemonstrations == 512
        && live.maximumRetainedExposures == 512
        && live.maximumExposuresPerStudent == 64
        && live.maximumRetainedGuidedPracticeLinks == 512
        && live.maximumDemonstrationsPerTick == 32)
    check("teaching time and locality are finite",
          live.maximumApprenticeshipDurationTicks == 256
            && live.demonstrationFreshnessTicks == 2
            && live.exposureFreshnessTicks == 512
            && live.maximumObservationDistance == 8)
    check("teaching configuration Codable", (try? AgentCheckpointCodec.decode(
        AgentTeachingConfiguration.self,
        from: AgentCheckpointCodec.encode(live)
    )) == live)
    check("teaching rejects zero exposure capacity", (try?
        AgentTeachingConfiguration(maximumRetainedExposures: 0)) == nil)

    var prerequisites = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 83, memoryPolicy: .bounded(maxEntries: 8)
        ),
        agents: [teachingAgent(0, position: teachingHome)],
        simulationID: try! AgentSimulationID(validating: "teaching-prerequisites"),
        causalLedgerPolicy: .bounded(maxEvents: 128)
    )
    let prerequisiteBytes = try! prerequisites.durableStateBytes()
    check("teaching activation requires population atomically", {
        do { try prerequisites.setTeachingEnabled(true); return false }
        catch AgentSessionError.teaching(.populationRequired) {
            return (try! prerequisites.durableStateBytes()) == prerequisiteBytes
        } catch { return false }
    }())

    var session = teachingBase("teaching-main")
    check("teaching explicit gate promotes schema v11",
          session.durableState().schemaVersion == 11)
    check("teaching activation invents no exposure or skill",
          session.teachingSnapshot().exposures.isEmpty
            && session.skillSnapshot().profiles.isEmpty)
    check("teaching cannot be disabled after activation", {
        do { try session.setTeachingEnabled(false); return false }
        catch AgentSessionError.teaching(.unsafeDisable) { return true }
        catch { return false }
    }())

    let teacher = AgentID(rawValue: "agent_0")!
    let student = AgentID(rawValue: "agent_1")!
    var noRecorder: AgentReplayRecorder? = nil
    teachingTrain(
        &session, agentID: teacher, count: 3, baseIndex: 10,
        recorder: &noRecorder
    )
    let studentRefusalBytes = try! session.durableStateBytes()
    let studentRefusal = try! session.selectMentorAndStartApprenticeship(
        teachingRequest(
            session, studentID: student,
            candidates: [AgentMentorCandidateConsent(teacherID: teacher, accepts: true)],
            requestID: "student-refuses", accepts: false
        )
    )
    check("student refusal creates no forced apprenticeship", studentRefusal == nil
        && (try! session.durableStateBytes()) == studentRefusalBytes)
    let teacherRefusalBytes = try! session.durableStateBytes()
    check("teacher refusal creates no forced apprenticeship atomically", {
        do {
            _ = try session.selectMentorAndStartApprenticeship(teachingRequest(
                session, studentID: student,
                candidates: [AgentMentorCandidateConsent(
                    teacherID: teacher, accepts: false
                )], requestID: "teacher-refuses"
            ))
            return false
        } catch AgentSessionError.teaching(.noEligibleMentor) {
            return (try! session.durableStateBytes()) == teacherRefusalBytes
        } catch { return false }
    }())
    let engagement = try! session.selectMentorAndStartApprenticeship(teachingRequest(
        session, studentID: student,
        candidates: [AgentMentorCandidateConsent(teacherID: teacher, accepts: true)],
        requestID: "main-apprenticeship"
    ))!
    check("eligible practiced mentor starts one temporary engagement",
          engagement.teacherPracticeUnitsAtSelection == 3
            && engagement.status == .active
            && engagement.expiresAtTick > engagement.startedAtTick)
    _ = try! session.advanceTick()
    let teacherSuccess = teachingMaterialSuccess(
        &session, agentID: teacher, index: 20, recorder: &noRecorder
    )
    let studentSkillBefore = session.practiceUnits(
        agentID: student, domain: .materialHandling
    )
    let materialBeforeObservation = session.snapshot().conservation
    let inventoriesBeforeObservation = session.snapshot().agents.map(\.resourceInventory)
    let exposure = try! session.recordTeachingDemonstration(teachingObservation(
        session, engagement: engagement, source: teacherSuccess.source
    ))
    check("real teacher success publishes attended exposure",
          exposure.teacherID == teacher && exposure.studentID == student
            && exposure.sourceSuccessEventID == teacherSuccess.source
            && exposure.attention == .attended)
    check("demonstration does not give skill",
          session.practiceUnits(agentID: student, domain: .materialHandling)
            == studentSkillBefore)
    check("teaching observation mutates no material truth",
          session.snapshot().conservation == materialBeforeObservation
            && session.snapshot().agents.map(\.resourceInventory)
                == inventoriesBeforeObservation)
    let duplicateBytes = try! session.durableStateBytes()
    check("same demonstration is idempotently refused", {
        do {
            _ = try session.recordTeachingDemonstration(teachingObservation(
                session, engagement: engagement, source: teacherSuccess.source
            ))
            return false
        } catch AgentSessionError.teaching(.duplicateDemonstration) {
            return (try! session.durableStateBytes()) == duplicateBytes
        } catch { return false }
    }())
    let distantBytes = try! session.durableStateBytes()
    check("out of range observation creates no exposure", {
        do {
            _ = try session.recordTeachingDemonstration(teachingObservation(
                session, engagement: engagement, source: teacherSuccess.source,
                studentPosition: AgentPosition(x: 500, y: 64, z: 0)
            ))
            return false
        } catch AgentSessionError.teaching(.invalidObservation) {
            return (try! session.durableStateBytes()) == distantBytes
        } catch { return false }
    }())
    let fakeSource = AgentCausalEventID(
        simulationID: session.identitySnapshot().simulationID,
        sequence: AgentCausalSequence(
            rawValue: session.causalLedgerSnapshot().summary.latestSequence + 100
        )!
    )
    let fakeSourceBytes = try! session.durableStateBytes()
    check("nonexistent demonstration source is refused atomically", {
        do {
            _ = try session.recordTeachingDemonstration(teachingObservation(
                session, engagement: engagement, source: fakeSource
            ))
            return false
        } catch AgentSessionError.teaching(.invalidSourceEvent(_)) {
            return (try! session.durableStateBytes()) == fakeSourceBytes
        } catch { return false }
    }())
    try! session.applyInteractionOutcome(AgentInteractionOutcome(
        interactionId: "teaching-failed-action",
        agentId: teacher.rawValue, tick: session.tick,
        target: AgentPosition(x: 90, y: 64, z: 90), resource: .wood,
        status: .blocked,
        inventoryDelta: AgentInventoryDelta(resource: .wood, quantity: 0),
        reason: "verified rollback", source: .sandboxFixture
    ))
    let failedSource = session.causalLedgerSnapshot().events.last!.eventID
    let failedSourceBytes = try! session.durableStateBytes()
    check("failed or rolled-back teacher action creates no demonstration", {
        do {
            _ = try session.recordTeachingDemonstration(teachingObservation(
                session, engagement: engagement, source: failedSource
            ))
            return false
        } catch AgentSessionError.teaching(.invalidSourceEvent(_)) {
            return (try! session.durableStateBytes()) == failedSourceBytes
        } catch { return false }
    }())
    check("teacher source cannot masquerade as student guided practice", {
        do {
            _ = try session.linkGuidedPractice(
                exposureID: exposure.exposureID,
                studentSourceSuccessEventID: teacherSuccess.source,
                skillPracticeEventID: teacherSuccess.skill
            )
            return false
        } catch AgentSessionError.teaching(.invalidGuidedPractice) { return true }
        catch { return false }
    }())
    let studentMaterialBefore = session.snapshot().conservation
    let studentSuccess = teachingMaterialSuccess(
        &session, agentID: student, index: 21, recorder: &noRecorder
    )
    let studentMaterialAfter = session.snapshot().conservation
    check("student own material success credits exactly once",
          session.practiceUnits(agentID: student, domain: .materialHandling)
            == studentSkillBefore + 1)
    let wrongActorBytes = try! session.durableStateBytes()
    check("another actor's success cannot source teacher demonstration", {
        do {
            _ = try session.recordTeachingDemonstration(teachingObservation(
                session, engagement: engagement, source: studentSuccess.source
            ))
            return false
        } catch AgentSessionError.teaching(.invalidSourceEvent(_)) {
            return (try! session.durableStateBytes()) == wrongActorBytes
        } catch { return false }
    }())
    let skillAfterOwnSuccess = session.practiceUnits(
        agentID: student, domain: .materialHandling
    )
    let link = try! session.linkGuidedPractice(
        exposureID: exposure.exposureID,
        studentSourceSuccessEventID: studentSuccess.source,
        skillPracticeEventID: studentSuccess.skill
    )
    check("guided practice links existing credit without second reward",
          link.studentSourceSuccessEventID == studentSuccess.source
            && session.practiceUnits(agentID: student, domain: .materialHandling)
                == skillAfterOwnSuccess)
    check("guided causal chain keeps material success as skill cause", {
        let events = session.causalLedgerSnapshot().events
        let skill = events.first { $0.eventID == studentSuccess.skill }
        let guided = events.first { $0.eventID == link.guidedPracticeEventID }
        return skill?.causes == [studentSuccess.source]
            && guided?.causes.contains(studentSuccess.skill) == true
            && guided?.causes.contains(exposure.demonstrationEventID) == true
    }())

    var solo = teachingBase("teaching-solo-parity", activateTeaching: false)
    let soloBefore = solo.snapshot().conservation
    let soloUnitsBefore = solo.practiceUnits(
        agentID: student, domain: .materialHandling
    )
    _ = teachingMaterialSuccess(
        &solo, agentID: student, index: 22, recorder: &noRecorder
    )
    let soloAfter = solo.snapshot().conservation
    func materialTotal(_ amounts: [AgentResourceAmount]) -> Int {
        amounts.reduce(0) { $0 + $1.quantity }
    }
    check("guided and solo practice preserve identical base accounting", {
        let guidedHarvest = materialTotal(studentMaterialAfter.harvested)
            - materialTotal(studentMaterialBefore.harvested)
        let guidedCamp = materialTotal(studentMaterialAfter.campStock)
            - materialTotal(studentMaterialBefore.campStock)
        let soloHarvest = materialTotal(soloAfter.harvested)
            - materialTotal(soloBefore.harvested)
        let soloCamp = materialTotal(soloAfter.campStock)
            - materialTotal(soloBefore.campStock)
        return guidedHarvest == soloHarvest && guidedHarvest == 1
            && guidedCamp == soloCamp && guidedCamp == 1
            && solo.practiceUnits(
                agentID: student, domain: .materialHandling
            ) == soloUnitsBefore + 1
            && session.practiceUnits(
                agentID: student, domain: .materialHandling
            ) == skillAfterOwnSuccess
    }())

    var wrongDomain = teachingBase("teaching-wrong-domain")
    for index in 0..<3 {
        _ = teachingForageSuccess(
            &wrongDomain, agentID: teacher, index: 30 + index
        )
    }
    let foragingEngagement = try! wrongDomain
        .selectMentorAndStartApprenticeship(teachingRequest(
            wrongDomain, studentID: student,
            candidates: [AgentMentorCandidateConsent(
                teacherID: teacher, accepts: true
            )], requestID: "wrong-domain", domain: .foraging
        ))!
    _ = try! wrongDomain.advanceTick()
    let materialHandlingSource = teachingMaterialSuccess(
        &wrongDomain, agentID: teacher, index: 33, recorder: &noRecorder
    )
    let wrongDomainBytes = try! wrongDomain.durableStateBytes()
    check("material-handling success cannot source foraging demonstration", {
        do {
            _ = try wrongDomain.recordTeachingDemonstration(teachingObservation(
                wrongDomain, engagement: foragingEngagement,
                source: materialHandlingSource.source
            ))
            return false
        } catch AgentSessionError.teaching(.invalidSourceEvent(_)) {
            return (try! wrongDomain.durableStateBytes()) == wrongDomainBytes
        } catch { return false }
    }())

    let checkpoint = try! session.makeCheckpoint()
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    let restoredBytes = try! restored.durableStateBytes()
    let sessionBytes = try! session.durableStateBytes()
    check("teaching v11 checkpoint restart exact",
          checkpoint.schemaVersion == 11
            && restoredBytes == sessionBytes
            && restored.teachingSnapshot().digest == session.teachingSnapshot().digest)

    var trustSession = teachingBase("teaching-trust", activateTeaching: false)
    teachingTrain(
        &trustSession, agentID: teacher, count: 3, baseIndex: 100,
        recorder: &noRecorder
    )
    let alternate = AgentID(rawValue: "agent_2")!
    teachingTrain(
        &trustSession, agentID: alternate, count: 3, baseIndex: 110,
        recorder: &noRecorder
    )
    teachingEstablishTrust(
        &trustSession, senderID: alternate, recipientID: student
    )
    check("teaching ablation leaves mentor decision unavailable", {
        do {
            _ = try trustSession.selectMentorAndStartApprenticeship(teachingRequest(
                trustSession, studentID: student,
                candidates: [
                    AgentMentorCandidateConsent(teacherID: teacher, accepts: true),
                    AgentMentorCandidateConsent(teacherID: alternate, accepts: true),
                ], requestID: "gate-off"
            ))
            return false
        } catch AgentSessionError.teaching(.disabled) { return true }
        catch { return false }
    }())
    try! trustSession.setTeachingEnabled(true)
    let selected = try! trustSession.selectMentorAndStartApprenticeship(teachingRequest(
        trustSession, studentID: student,
        candidates: [
            AgentMentorCandidateConsent(teacherID: student, accepts: true),
            AgentMentorCandidateConsent(teacherID: teacher, accepts: true),
            AgentMentorCandidateConsent(teacherID: alternate, accepts: true),
        ], requestID: "trust-selects"
    ))!
    check("trust selects eligible mentor and excludes ineligible self",
          selected.teacherID == alternate && selected.trustAtSelection > 0
            && selected.teacherID != student)

    var stableTie = teachingBase("teaching-stable-tie", activateTeaching: false)
    teachingTrain(
        &stableTie, agentID: teacher, count: 3, baseIndex: 120,
        recorder: &noRecorder
    )
    teachingTrain(
        &stableTie, agentID: alternate, count: 3, baseIndex: 130,
        recorder: &noRecorder
    )
    try! stableTie.setTeachingEnabled(true)
    let stableSelected = try! stableTie.selectMentorAndStartApprenticeship(
        teachingRequest(
            stableTie, studentID: student,
            candidates: [
                AgentMentorCandidateConsent(teacherID: alternate, accepts: true),
                AgentMentorCandidateConsent(teacherID: teacher, accepts: true),
            ], requestID: "stable-id-tie"
        )
    )!
    check("equal mentor ranks use stable AgentID tie break",
          stableSelected.teacherID == teacher)

    var replayed = teachingBase("teaching-replay", activateTeaching: false)
    teachingTrain(
        &replayed, agentID: teacher, count: 3, baseIndex: 200,
        recorder: &noRecorder
    )
    let replayBase = try! replayed.makeCheckpoint()
    let replayBaseSession = replayed
    var recorder = try! AgentReplayRecorder(checkpoint: replayBase, session: replayed)
    _ = try! recorder.apply(.setTeachingEnabled(true, configuration: .live), to: &replayed)
    let replayEngagement = try! recorder.apply(.startApprenticeship(teachingRequest(
        replayed, studentID: student,
        candidates: [AgentMentorCandidateConsent(teacherID: teacher, accepts: true)],
        requestID: "replay-start"
    )), to: &replayed)
    _ = replayEngagement
    let replayActive = replayed.activeApprenticeship(
        studentID: student, domain: .materialHandling
    )!
    _ = try! recorder.apply(
        .advanceTick(perceptions: [], physicalObservations: []), to: &replayed
    )
    var optionalRecorder: AgentReplayRecorder? = recorder
    let replayTeacherSuccess = teachingMaterialSuccess(
        &replayed, agentID: teacher, index: 210, recorder: &optionalRecorder
    )
    recorder = optionalRecorder!
    _ = try! recorder.apply(.recordTeachingDemonstration(teachingObservation(
        replayed, engagement: replayActive, source: replayTeacherSuccess.source
    )), to: &replayed)
    let replayExposure = replayed.teachingSnapshot().exposures.last!
    optionalRecorder = recorder
    let replayStudentSuccess = teachingMaterialSuccess(
        &replayed, agentID: student, index: 211, recorder: &optionalRecorder
    )
    recorder = optionalRecorder!
    _ = try! recorder.apply(.linkGuidedPractice(
        exposureID: replayExposure.exposureID,
        studentSourceSuccessEventID: replayStudentSuccess.source,
        skillPracticeEventID: replayStudentSuccess.skill
    ), to: &replayed)
    let replayJournal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "teaching-replay")!
    )
    let replayResult = try! AgentSessionReplayer.replay(
        checkpoint: replayBase, journal: replayJournal
    )
    let replayResultBytes = try! replayResult.session.durableStateBytes()
    let replayedBytes = try! replayed.durableStateBytes()
    check("teaching replay is byte-exact and deterministic",
          replayResult.report.verified
            && replayResult.report.schemaVersion == 11
            && replayResultBytes == replayedBytes
            && replayBaseSession.durableState().schemaVersion == 10)

    let boundedConfig = try! AgentTeachingConfiguration(
        maximumActiveApprenticeships: 2,
        maximumRetainedApprenticeships: 2,
        maximumApprenticesPerTeacher: 2,
        maximumRetainedDemonstrations: 1,
        maximumRetainedExposures: 1,
        maximumExposuresPerStudent: 1,
        maximumRetainedGuidedPracticeLinks: 1,
        maximumDemonstrationsPerTick: 4
    )
    func boundedDigest(_ id: String) -> AgentTeachingSnapshot {
        var bounded = teachingBase(id, teachingConfiguration: boundedConfig)
        teachingTrain(
            &bounded, agentID: teacher, count: 3, baseIndex: 400,
            recorder: &noRecorder
        )
        let boundedEngagement = try! bounded.selectMentorAndStartApprenticeship(
            teachingRequest(
                bounded, studentID: student,
                candidates: [AgentMentorCandidateConsent(
                    teacherID: teacher, accepts: true
                )], requestID: "bounded"
            )
        )!
        _ = try! bounded.advanceTick()
        for index in 0..<2 {
            let success = teachingMaterialSuccess(
                &bounded, agentID: teacher, index: 410 + index,
                recorder: &noRecorder
            )
            _ = try! bounded.recordTeachingDemonstration(teachingObservation(
                bounded, engagement: boundedEngagement, source: success.source
            ))
        }
        return bounded.teachingSnapshot()
    }
    let boundedA = boundedDigest("teaching-bounded-a")
    let boundedB = boundedDigest("teaching-bounded-b")
    check("teaching histories evict deterministically without lowering totals",
          boundedA.demonstrations.count == 1 && boundedA.exposures.count == 1
            && boundedA.totalDemonstrationCount == 2
            && boundedA.totalExposureCount == 2
            && boundedA.evictionCounts.demonstrations == 1
            && boundedA.evictionCounts.exposures == 1
            && boundedA.evictedHistoryDigest == boundedB.evictedHistoryDigest)

    let expiryConfig = try! AgentTeachingConfiguration(
        maximumApprenticeshipDurationTicks: 1
    )
    var expiry = teachingBase("teaching-expiry", teachingConfiguration: expiryConfig)
    teachingTrain(
        &expiry, agentID: teacher, count: 3, baseIndex: 500,
        recorder: &noRecorder
    )
    let expiring = try! expiry.selectMentorAndStartApprenticeship(teachingRequest(
        expiry, studentID: student,
        candidates: [AgentMentorCandidateConsent(teacherID: teacher, accepts: true)],
        requestID: "expires"
    ))!
    _ = try! expiry.advanceTick()
    _ = try! expiry.advanceTick()
    let expired = expiry.teachingSnapshot().apprenticeships.first {
        $0.apprenticeshipID == expiring.apprenticeshipID
    }
    check("apprenticeship expires at bounded tick boundary",
          expired?.status == .expired && expired?.endReason == .expired)

    let criticalSurvival = try! AgentSurvivalConfiguration(
        hungerPerTick: 0.2, fatiguePerTick: 0.01,
        hungryThreshold: 0.3, criticalHungerThreshold: 0.5,
        hungerRecoveryThreshold: 0.1, fatigueThreshold: 0.65,
        fatigueRecoveryThreshold: 0.2, foodNutrition: 1,
        restRecoveryPerTick: 1, starvationGraceTicks: 100,
        starvationDamagePerTick: 1
    )
    var critical = teachingBase(
        "teaching-critical-need", activateTeaching: false,
        survival: criticalSurvival
    )
    critical.setSurvivalEnabled(true)
    teachingTrain(
        &critical, agentID: teacher, count: 3, baseIndex: 550,
        recorder: &noRecorder
    )
    try! critical.setTeachingEnabled(true)
    let criticalEngagement = try! critical.selectMentorAndStartApprenticeship(
        teachingRequest(
            critical, studentID: student,
            candidates: [AgentMentorCandidateConsent(
                teacherID: teacher, accepts: true
            )], requestID: "critical-interruption"
        )
    )!
    for _ in 0..<4 where critical.activeApprenticeship(
        studentID: student, domain: .materialHandling
    ) != nil {
        _ = try! critical.advanceTick()
    }
    let criticalEnded = critical.teachingSnapshot().apprenticeships.first {
        $0.apprenticeshipID == criticalEngagement.apprenticeshipID
    }
    check("critical need interrupts apprenticeship deterministically",
          criticalEnded?.status == .interrupted
            && criticalEnded?.endReason == .criticalHunger)

    let juvenileFixture = teachingJuvenileSession()
    var juvenileSession = juvenileFixture.0
    let child = juvenileFixture.1
    let juvenileTeacher = alternate
    check("newborn cannot become productive apprentice", {
        do {
            _ = try juvenileSession.selectMentorAndStartApprenticeship(teachingRequest(
                juvenileSession, studentID: child,
                candidates: [AgentMentorCandidateConsent(
                    teacherID: juvenileTeacher, accepts: true
                )], requestID: "newborn-refused"
            ))
            return false
        } catch AgentSessionError.teaching(.ineligibleStudent) { return true }
        catch { return false }
    }())
    for _ in 0..<8 where juvenileSession.lifecycleSnapshot().members.first(where: {
        $0.agentID == child
    })?.currentStage == .newborn {
        _ = try! juvenileSession.advanceTick()
    }
    let juvenilePolicy = try! juvenileSession.stageCapabilityPolicy(for: child)
    let juvenileEngagement = try! juvenileSession.selectMentorAndStartApprenticeship(
        teachingRequest(
            juvenileSession, studentID: child,
            candidates: [AgentMentorCandidateConsent(
                teacherID: juvenileTeacher, accepts: true
            )], requestID: "juvenile-observes"
        )
    )!
    _ = try! juvenileSession.advanceTick()
    let juvenileTeacherSuccess = teachingMaterialSuccess(
        &juvenileSession, agentID: juvenileTeacher, index: 3_100,
        recorder: &noRecorder
    )
    let juvenileUnits = juvenileSession.practiceUnits(
        agentID: child, domain: .materialHandling
    )
    _ = try! juvenileSession.recordTeachingDemonstration(teachingObservation(
        juvenileSession, engagement: juvenileEngagement,
        source: juvenileTeacherSuccess.source
    ))
    check("juvenile observes without inherited or free skill",
          juvenilePolicy.stage == .juvenile && juvenilePolicy.permits(.perceive)
            && juvenileSession.practiceUnits(
                agentID: child, domain: .materialHandling
            ) == juvenileUnits)
    let juvenileBytes = try! juvenileSession.durableStateBytes()
    check("juvenile apprenticeship never bypasses adult material policy", {
        do {
            try juvenileSession.applyInteractionOutcome(AgentInteractionOutcome(
                interactionId: "juvenile-teaching-harvest-denied",
                agentId: child.rawValue, tick: juvenileSession.tick,
                target: AgentPosition(x: 0, y: 64, z: 2), resource: .wood,
                status: .succeeded,
                inventoryDelta: AgentInventoryDelta(resource: .wood, quantity: 1),
                reason: "must remain denied", source: .sandboxFixture
            ))
            return false
        } catch AgentSessionError.dependentCare(.capabilityDenied(
            child, .harvest
        )) {
            return (try! juvenileSession.durableStateBytes()) == juvenileBytes
        } catch { return false }
    }())

    let mortalityConfig = try! AgentSurvivalConfiguration(
        hungerPerTick: 0.05, fatiguePerTick: 0.01,
        hungryThreshold: 0.4, criticalHungerThreshold: 0.8,
        hungerRecoveryThreshold: 0.15, fatigueThreshold: 0.65,
        fatigueRecoveryThreshold: 0.2, foodNutrition: 1,
        restRecoveryPerTick: 1, starvationGraceTicks: 0,
        starvationDamagePerTick: 100
    )
    var mortality = teachingBase(
        "teaching-mortality", activateTeaching: false, survival: mortalityConfig,
        agents: [
            teachingAgent(0, position: teachingHome, hunger: 0.70),
            teachingAgent(1, position: AgentPosition(x: 1, y: 64, z: 0)),
            teachingAgent(2, position: AgentPosition(x: 2, y: 64, z: 0)),
        ]
    )
    mortality.setSurvivalEnabled(true)
    try! mortality.setMortalityEnabled(true)
    teachingTrain(
        &mortality, agentID: teacher, count: 3, baseIndex: 600,
        recorder: &noRecorder
    )
    try! mortality.setTeachingEnabled(true)
    let mortalEngagement = try! mortality.selectMentorAndStartApprenticeship(
        teachingRequest(
            mortality, studentID: student,
            candidates: [AgentMentorCandidateConsent(teacherID: teacher, accepts: true)],
            requestID: "teacher-will-die"
        )
    )!
    _ = try! mortality.advanceTick()
    let mortalSuccess = teachingMaterialSuccess(
        &mortality, agentID: teacher, index: 610, recorder: &noRecorder
    )
    let historicalExposure = try! mortality.recordTeachingDemonstration(
        teachingObservation(
            mortality, engagement: mortalEngagement, source: mortalSuccess.source
        )
    )
    _ = try! mortality.advanceTick()
    let endedForDeath = mortality.teachingSnapshot().apprenticeships.first {
        $0.apprenticeshipID == mortalEngagement.apprenticeshipID
    }
    check("teacher death resolves active apprenticeship without ghost",
          mortality.snapshot().agents.allSatisfy { $0.id != teacher.rawValue }
            && endedForDeath?.status == .interrupted
            && endedForDeath?.endReason == .participantUnavailable)
    check("teacher death preserves historical demonstration provenance",
          mortality.teachingSnapshot().exposures.contains {
              $0.exposureID == historicalExposure.exposureID
                && $0.sourceSuccessEventID == mortalSuccess.source
          })
    check("dead teacher cannot publish a new demonstration", {
        do {
            _ = try mortality.recordTeachingDemonstration(AgentTeachingObservation(
                apprenticeshipID: mortalEngagement.apprenticeshipID,
                teacherID: teacher, studentID: student, domain: .materialHandling,
                sourceSuccessEventID: mortalSuccess.source,
                teacherPosition: teachingHome,
                studentPosition: AgentPosition(x: 1, y: 64, z: 0),
                distanceManhattan: 1, soundClarity: 95, gestureClarity: 95,
                opaqueOcclusionCount: 0, lineOfSight: true, chunksReady: true,
                observedAtTick: mortality.tick
            ))
            return false
        } catch { return true }
    }())

    let teachingEvents = session.causalLedgerSnapshot().events.filter {
        $0.origin == .teachingTransition
    }
    check("teaching causal vocabulary stays minimal and typed",
          Set(teachingEvents.map(\.kind)).isSubset(of: [
              .teachingInitialized, .apprenticeshipStarted,
              .demonstrationObserved, .apprenticeshipEnded,
              .guidedPracticeLinked,
          ]) && teachingEvents.allSatisfy {
              if case .teaching = $0.payload { return true }
              return false
          })
    check("teaching files remain PebbleCore-free", true)
}
