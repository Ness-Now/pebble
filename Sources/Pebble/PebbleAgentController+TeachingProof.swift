import Foundation
import PebbleAgents
import PebbleCore

private struct PebbleAgentTeachingProofRun {
    let digest: String
    let teacherID: String
    let studentID: String
    let studentSkillBefore: Int
    let studentSkillAfterObservation: Int
    let studentSkillAfterPractice: Int
    let exposureCount: Int
    let guidedCount: Int
    let outOfRangeRejected: Bool
}

private struct PebbleAgentTeachingProofStation {
    let fixture: PebbleAgentHarvestProofFixture
    let teacherPosition: (Double, Double, Double)
    let studentPosition: (Double, Double, Double)
}

extension PebbleAgentController {
    func handleTeachingProof(
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let gates = [
            ("PEBBLELAB_APP_AGENTS=1", featureEnabled),
            ("PEBBLELAB_APP_AGENTS_INTERACT=1", interactionFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_NATURAL=1", naturalFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_MATERIAL=1", materialFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_POPULATION=1", populationFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_LIFECYCLE=1", lifecycleFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_SKILLS=1", skillFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_TEACHING=1", teachingFeatureEnabled),
            ("PEBBLELAB_APP_PROBES=1", probesFeatureEnabled),
            ("PEBBLELAB_DEBUG_ENTITIES=1", debugEntitiesEnabled),
            ("PEBBLELAB_APP_AGENTS_TRACE=1", traceEnabled),
            (
                "PEBBLELAB_DISPOSABLE_WORLD_PROOF=1",
                environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1"
            ),
        ]
        let missing = gates.filter { !$0.1 }.map(\.0)
        guard missing.isEmpty else {
            return failure(
                "Teaching proof refused; missing gates: "
                    + missing.joined(separator: ", ")
            )
        }
        guard let published = session, activeWorld === world,
              published.populationEnabled, published.lifecycleEnabled,
              published.skillsEnabled, published.teachingEnabled else {
            return failure("Teaching proof requires population, lifecycle, skills, and Teaching.")
        }
        guard isPaused, !movementEnabled, !autoInteractionEnabled,
              !economyAutoEnabled else {
            return failure(
                "Teaching proof requires pause, movement off, and auto modes off."
            )
        }
        let teacherID = "agent_2"
        let studentID = "agent_1"
        guard let teacher = probesByAgentId[teacherID],
              let student = probesByAgentId[studentID],
              !teacher.dead, !student.dead else {
            return failure("Teaching proof requires live teacher/student embodiments.")
        }
        let originalTeacherCustody = copyItemInventory(teacher.carriedItems)
        let originalStudentCustody = copyItemInventory(student.carriedItems)
        let originalEntityIDs = world.entities.map(\.id).sorted()
        let teacherPosition = (teacher.x, teacher.y, teacher.z)
        let studentPosition = (student.x, student.y, student.z)
        guard let stations = teachingProofStations(
            world: world, player: player, teacher: teacher, student: student,
            teacherPosition: teacherPosition, studentPosition: studentPosition
        ) else {
            return failure("Teaching proof requires five distinct physical fixtures.")
        }
        let originalExecutor = naturalResourceExecutor
        do {
            let publishedBytes = try published.durableStateBytes()
            let first = try runTeachingProof(
                baseSession: published, teacherID: teacherID, studentID: studentID,
                teacher: teacher, student: student, stations: stations,
                world: world, player: player
            )
            guard cleanupTeachingProof(
                stations: stations, world: world, teacher: teacher, student: student,
                teacherCustody: originalTeacherCustody,
                studentCustody: originalStudentCustody,
                entityIDs: originalEntityIDs,
                teacherPosition: teacherPosition,
                studentPosition: studentPosition
            ) else {
                throw ControllerError.interactionBoundary(
                    "Teaching proof first cleanup failed"
                )
            }
            let second = try runTeachingProof(
                baseSession: published, teacherID: teacherID, studentID: studentID,
                teacher: teacher, student: student, stations: stations,
                world: world, player: player
            )
            let cleanup = cleanupTeachingProof(
                stations: stations, world: world, teacher: teacher, student: student,
                teacherCustody: originalTeacherCustody,
                studentCustody: originalStudentCustody,
                entityIDs: originalEntityIDs,
                teacherPosition: teacherPosition,
                studentPosition: studentPosition
            )
            naturalResourceExecutor = originalExecutor
            materialCustodyGateway.reset()
            let sessionUnchanged = try session?.durableStateBytes() == publishedBytes
            guard cleanup, sessionUnchanged, first.digest == second.digest else {
                throw ControllerError.interactionBoundary(
                    "Teaching proof determinism or publication isolation mismatch"
                )
            }
            trace(
                "teaching proof teacher=\(first.teacherID) student=\(first.studentID) "
                    + "physical=embodiments locality=CIV04 exact=1 "
                    + "teacherAction=realHarvest exposure=\(first.exposureCount) "
                    + "skillObservation=\(first.studentSkillBefore)>"
                    + "\(first.studentSkillAfterObservation) "
                    + "studentAction=realHarvest skillPractice=\(first.studentSkillAfterPractice) "
                    + "guided=\(first.guidedCount) outOfRange="
                    + "\(first.outOfRangeRejected ? "rejected" : "failed") "
                    + "worldMutation=harvestOnly teachingWorldMutation=none "
                    + "yieldBonus=0 session=unchanged custody=restored "
                    + "fixture=restored cleanup=exact runs=2 digest=\(first.digest)"
            )
            return success(
                "Teaching proof passed twice: real local demonstration gives no skill; "
                    + "student real harvest credits once; digest=\(first.digest)."
            )
        } catch {
            let cleanup = cleanupTeachingProof(
                stations: stations, world: world, teacher: teacher, student: student,
                teacherCustody: originalTeacherCustody,
                studentCustody: originalStudentCustody,
                entityIDs: originalEntityIDs,
                teacherPosition: teacherPosition,
                studentPosition: studentPosition
            )
            naturalResourceExecutor = originalExecutor
            materialCustodyGateway.reset()
            return failure(
                "Teaching proof failed: \(error); cleanup="
                    + (cleanup ? "exact" : "failed")
            )
        }
    }

    private func runTeachingProof(
        baseSession: AgentSimulationSession,
        teacherID: String,
        studentID: String,
        teacher: LabCoreAgentEntity,
        student: LabCoreAgentEntity,
        stations: [PebbleAgentTeachingProofStation],
        world: World,
        player: Player
    ) throws -> PebbleAgentTeachingProofRun {
        materialCustodyGateway.reset()
        naturalResourceExecutor.resetDiagnostics()
        resetGameRng(0xC120)
        teacher.carriedItems = Array(
            repeating: nil, count: LabCoreAgentEntity.carriedItemSlotCount
        )
        student.carriedItems = Array(
            repeating: nil, count: LabCoreAgentEntity.carriedItemSlotCount
        )
        teacher.carriedItems[0] = ItemStack(iid("iron_axe"), 1)
        student.carriedItems[0] = ItemStack(iid("iron_axe"), 1)
        var candidate = baseSession
        candidate.setEconomyEnabled(true)
        candidate.setNaturalResourcesEnabled(true)
        candidate.setSurvivalEnabled(true)
        var recorder: AgentReplayRecorder?
        let teacherAgentID = AgentID(rawValue: teacherID)!
        let studentAgentID = AgentID(rawValue: studentID)!

        for index in 0..<3 {
            try positionTeachingActors(
                session: &candidate, teacherID: teacherID, studentID: studentID,
                teacher: teacher, student: student,
                teacherPosition: stations[index].teacherPosition,
                studentPosition: stations[4].teacherPosition
            )
            let pair = try lockTeachingHarvestPair(
                session: &candidate,
                firstActorID: teacherID, firstFixture: stations[index].fixture,
                secondActorID: studentID, secondFixture: stations[4].fixture,
                world: world
            )
            _ = try performTeachingHarvest(
                session: &candidate, recorder: &recorder,
                actorID: teacherID, identity: pair.first,
                world: world, player: player,
                prefix: "civ20-training-\(index)"
            )
        }
        guard candidate.skillLevel(
            agentID: teacherAgentID, domain: .foraging
        ) >= .practiced else {
            throw ControllerError.interactionBoundary("teacher did not reach practiced")
        }
        try positionTeachingActors(
            session: &candidate, teacherID: teacherID, studentID: studentID,
            teacher: teacher, student: student,
            teacherPosition: stations[2].teacherPosition,
            studentPosition: stations[2].studentPosition
        )
        let engagement = try candidate.selectMentorAndStartApprenticeship(
            AgentMentorSelectionRequest(
                requestID: "civ20-live-mentor", studentID: studentAgentID,
                domain: .foraging, studentAccepts: true,
                candidates: [AgentMentorCandidateConsent(
                    teacherID: teacherAgentID, accepts: true
                )], requestedAtTick: candidate.tick
            )
        )!
        let studentSkillBefore = candidate.practiceUnits(
            agentID: studentAgentID, domain: .foraging
        )
        try positionTeachingActors(
            session: &candidate, teacherID: teacherID, studentID: studentID,
            teacher: teacher, student: student,
            teacherPosition: stations[3].teacherPosition,
            studentPosition: stations[4].teacherPosition
        )
        let demonstrationPair = try lockTeachingHarvestPair(
            session: &candidate,
            firstActorID: teacherID, firstFixture: stations[3].fixture,
            secondActorID: studentID, secondFixture: stations[4].fixture,
            world: world
        )
        let teacherDemonstration = try performTeachingHarvest(
            session: &candidate, recorder: &recorder,
            actorID: teacherID, identity: demonstrationPair.first,
            world: world, player: player,
            prefix: "civ20-demonstration"
        )
        try positionTeachingActors(
            session: &candidate, teacherID: teacherID, studentID: studentID,
            teacher: teacher, student: student,
            teacherPosition: stations[3].teacherPosition,
            studentPosition: stations[3].studentPosition
        )
        let observation = try teachingObservationAdapter.observe(
            world: world,
            teacher: try PebbleAgentEmbodiment.resolve(
                agentID: teacherID, in: world, mappedByAgentID: probesByAgentId
            ),
            student: try PebbleAgentEmbodiment.resolve(
                agentID: studentID, in: world, mappedByAgentID: probesByAgentId
            ),
            apprenticeshipID: engagement.apprenticeshipID, domain: .foraging,
            sourceSuccessEventID: teacherDemonstration.source,
            atTick: candidate.tick,
            configuration: candidate.configuration.physicalChannelConfiguration
        )
        let exposure = try candidate.recordTeachingDemonstration(observation)
        let skillAfterObservation = candidate.practiceUnits(
            agentID: studentAgentID, domain: .foraging
        )
        guard skillAfterObservation == studentSkillBefore else {
            throw ControllerError.interactionBoundary("observation granted skill")
        }

        let distantStudentPosition = (
            stations[3].teacherPosition.0 + 12.5,
            stations[3].teacherPosition.1,
            stations[3].teacherPosition.2
        )
        try positionTeachingActors(
            session: &candidate, teacherID: teacherID, studentID: studentID,
            teacher: teacher, student: student,
            teacherPosition: stations[3].teacherPosition,
            studentPosition: distantStudentPosition
        )
        let distantObservation = try teachingObservationAdapter.observe(
            world: world,
            teacher: try PebbleAgentEmbodiment.resolve(
                agentID: teacherID, in: world, mappedByAgentID: probesByAgentId
            ),
            student: try PebbleAgentEmbodiment.resolve(
                agentID: studentID, in: world, mappedByAgentID: probesByAgentId
            ),
            apprenticeshipID: engagement.apprenticeshipID, domain: .foraging,
            sourceSuccessEventID: teacherDemonstration.source,
            atTick: candidate.tick,
            configuration: candidate.configuration.physicalChannelConfiguration
        )
        let exposureCountBeforeNegative = candidate.teachingSnapshot().exposures.count
        let outOfRangeRejected: Bool
        do {
            _ = try candidate.recordTeachingDemonstration(distantObservation)
            outOfRangeRejected = false
        } catch AgentSessionError.teaching(.invalidObservation) {
            outOfRangeRejected = candidate.teachingSnapshot().exposures.count
                == exposureCountBeforeNegative
        }
        guard outOfRangeRejected else {
            throw ControllerError.interactionBoundary("distant exposure was not refused")
        }
        try positionTeachingActors(
            session: &candidate, teacherID: teacherID, studentID: studentID,
            teacher: teacher, student: student,
            teacherPosition: stations[4].studentPosition,
            studentPosition: stations[4].teacherPosition
        )
        let studentSuccess = try performTeachingHarvest(
            session: &candidate, recorder: &recorder,
            actorID: studentID, identity: demonstrationPair.second,
            world: world, player: player,
            prefix: "civ20-student-practice"
        )
        let skillAfterPractice = candidate.practiceUnits(
            agentID: studentAgentID, domain: .foraging
        )
        guard skillAfterPractice == studentSkillBefore + 1 else {
            throw ControllerError.interactionBoundary("student skill credit was not exact")
        }
        _ = try candidate.linkGuidedPractice(
            exposureID: exposure.exposureID,
            studentSourceSuccessEventID: studentSuccess.source,
            skillPracticeEventID: studentSuccess.skill
        )
        guard candidate.practiceUnits(
            agentID: studentAgentID, domain: .foraging
        ) == skillAfterPractice else {
            throw ControllerError.interactionBoundary("guided link double credited skill")
        }
        let teaching = candidate.teachingSnapshot()
        let relevant = candidate.causalLedgerSnapshot().events.filter {
            $0.origin == .teachingTransition || $0.kind == .skillPracticeCredited
        }.map(\.digest).joined(separator: ",")
        let digest = AgentTeachingDigest.make(
            "\(teaching.digest)|\(relevant)|\(teacherID)|\(studentID)|"
                + "\(studentSkillBefore)|\(skillAfterObservation)|"
                + "\(skillAfterPractice)|\(outOfRangeRejected ? 1 : 0)"
        )
        return PebbleAgentTeachingProofRun(
            digest: digest, teacherID: teacherID, studentID: studentID,
            studentSkillBefore: studentSkillBefore,
            studentSkillAfterObservation: skillAfterObservation,
            studentSkillAfterPractice: skillAfterPractice,
            exposureCount: teaching.exposures.count,
            guidedCount: teaching.guidedPracticeLinks.count,
            outOfRangeRejected: outOfRangeRejected
        )
    }

    private func teachingProofStations(
        world: World,
        player: Player,
        teacher: LabCoreAgentEntity,
        student: LabCoreAgentEntity,
        teacherPosition: (Double, Double, Double),
        studentPosition: (Double, Double, Double)
    ) -> [PebbleAgentTeachingProofStation]? {
        let offsets: [(Double, Double)] = [
            (0, 0), (0, 4), (0, 8), (4, 8), (8, 8),
        ]
        var stations: [PebbleAgentTeachingProofStation] = []
        defer {
            teacher.setPos(
                teacherPosition.0, teacherPosition.1, teacherPosition.2
            )
            student.setPos(
                studentPosition.0, studentPosition.1, studentPosition.2
            )
        }
        for offset in offsets {
            let teacherStation = (
                teacherPosition.0 + offset.0,
                teacherPosition.1,
                teacherPosition.2 + offset.1
            )
            let studentStation = (
                teacherStation.0 + 1.0,
                teacherStation.1,
                teacherStation.2
            )
            teacher.setPos(
                teacherStation.0, teacherStation.1, teacherStation.2
            )
            student.setPos(
                studentStation.0, studentStation.1, studentStation.2
            )
            guard let fixture = harvestProofFixture(
                world: world, actor: teacher, player: player
            ) else { return nil }
            stations.append(PebbleAgentTeachingProofStation(
                fixture: fixture,
                teacherPosition: teacherStation,
                studentPosition: studentStation
            ))
        }
        guard Set(stations.map(\.fixture.target)).count == offsets.count else {
            return nil
        }
        return stations
    }

    private func positionTeachingActors(
        session: inout AgentSimulationSession,
        teacherID: String,
        studentID: String,
        teacher: LabCoreAgentEntity,
        student: LabCoreAgentEntity,
        teacherPosition: (Double, Double, Double),
        studentPosition: (Double, Double, Double)
    ) throws {
        teacher.setPos(
            teacherPosition.0, teacherPosition.1, teacherPosition.2
        )
        student.setPos(
            studentPosition.0, studentPosition.1, studentPosition.2
        )
        for (agentID, position) in [
            (teacherID, teacherPosition), (studentID, studentPosition),
        ] {
            try session.applyExternalUpdate(AgentExternalUpdate(
                agentId: agentID,
                position: AgentPosition(
                    x: Int(position.0.rounded(.down)),
                    y: Int(position.1.rounded(.down)),
                    z: Int(position.2.rounded(.down))
                )
            ))
        }
    }

    private func lockTeachingHarvestPair(
        session: inout AgentSimulationSession,
        firstActorID: String,
        firstFixture: PebbleAgentHarvestProofFixture,
        secondActorID: String,
        secondFixture: PebbleAgentHarvestProofFixture,
        world: World
    ) throws -> (first: AgentResourceIdentity, second: AgentResourceIdentity) {
        guard firstFixture.target != secondFixture.target,
              prepareHarvestFixture(
                  firstFixture, world: world, targetCell: Int(cell(B.oak_log))
              ),
              prepareHarvestFixture(
                  secondFixture, world: world, targetCell: Int(cell(B.oak_log))
              ) else {
            throw ControllerError.interactionBoundary(
                "Teaching paired log fixture preparation failed"
            )
        }
        let snapshot = session.snapshot()
        func perception(
            actorID: String,
            fixture: PebbleAgentHarvestProofFixture
        ) throws -> AgentPerceptionInput {
            guard let actor = snapshot.agents.first(where: { $0.id == actorID }) else {
                throw ControllerError.interactionBoundary(
                    "Teaching paired harvest actor missing"
                )
            }
            let target = AgentPosition(
                x: fixture.target.x, y: fixture.target.y, z: fixture.target.z
            )
            guard let direction = AgentResourcePerception.direction(
                observerPosition: actor.position, target: target
            ) else {
                throw ControllerError.interactionBoundary(
                    "Teaching paired harvest direction missing"
                )
            }
            return AgentPerceptionInput(
                agentId: actorID,
                resourceObservations: [AgentResourceObservation(
                    resource: .wood, target: target, direction: direction,
                    distanceManhattan: 1, quantityAvailable: 1,
                    source: .naturalWorld,
                    expectedBlockFingerprint: Int(cell(B.oak_log))
                )]
            )
        }
        _ = try session.advanceTick(perceptions: [
            try perception(actorID: firstActorID, fixture: firstFixture),
            try perception(actorID: secondActorID, fixture: secondFixture),
        ])
        func identity(
            actorID: String,
            fixture: PebbleAgentHarvestProofFixture
        ) throws -> AgentResourceIdentity {
            guard let actor = session.snapshot().agents.first(where: {
                $0.id == actorID
            }), actor.resourceReservation?.agentId == actorID,
                  let identity = actor.activeResourceTarget?.identity,
                  identity.position == AgentPosition(
                      x: fixture.target.x,
                      y: fixture.target.y,
                      z: fixture.target.z
                  ), identity.resource == .wood,
                  identity.expectedBlockFingerprint == Int(cell(B.oak_log)) else {
                let diagnostic = session.snapshot().agents.first {
                    $0.id == actorID
                }
                throw ControllerError.interactionBoundary(
                    "Teaching paired harvest reservation mismatch actor=\(actorID) "
                        + "goal=\(diagnostic?.currentGoal.kind.rawValue ?? "none") "
                        + "active=\(diagnostic?.activeResourceTarget?.identity.stableKey ?? "none") "
                        + "reservation=\(diagnostic?.resourceReservation?.agentId ?? "none")"
                )
            }
            return identity
        }
        return (
            try identity(actorID: firstActorID, fixture: firstFixture),
            try identity(actorID: secondActorID, fixture: secondFixture)
        )
    }

    private func performTeachingHarvest(
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?,
        actorID: String,
        identity: AgentResourceIdentity,
        world: World,
        player: Player,
        prefix: String
    ) throws -> (source: AgentCausalEventID, skill: AgentCausalEventID) {
        let actor = session.snapshot().agents.first { $0.id == actorID }!
        guard actor.resourceReservation?.agentId == actorID else {
            let owner = session.snapshot().resourceReservations.first {
                $0.target == identity.position
                    && $0.resource == identity.resource
            }?.agentId ?? "none"
            throw ControllerError.interactionBoundary(
                "Teaching harvest reservation mismatch actor=\(actorID) owner=\(owner)"
            )
        }
        _ = try performNaturalHarvestTransaction(
            world: world, player: player, actor: actor, identity: identity,
            interactionPrefix: prefix, session: &session, recorder: &recorder
        )
        let practice = session.skillProfile(for: AgentID(rawValue: actorID)!)!
            .domainPractices.first { $0.domain == .foraging }!
        return (
            practice.lastSourceSuccessEventID,
            practice.lastSkillPracticeEventID
        )
    }

    private func cleanupTeachingProof(
        stations: [PebbleAgentTeachingProofStation],
        world: World,
        teacher: LabCoreAgentEntity,
        student: LabCoreAgentEntity,
        teacherCustody: [ItemStack?],
        studentCustody: [ItemStack?],
        entityIDs: [Int],
        teacherPosition: (Double, Double, Double),
        studentPosition: (Double, Double, Double)
    ) -> Bool {
        teacher.setPos(teacherPosition.0, teacherPosition.1, teacherPosition.2)
        student.setPos(studentPosition.0, studentPosition.1, studentPosition.2)
        student.carriedItems = copyItemInventory(studentCustody)
        let restored = stations.reversed().allSatisfy { station in
            restoreHarvestProof(
                station.fixture, world: world, actor: teacher,
                custody: teacherCustody, entityIDs: entityIDs
            )
        }
        return restored
            && teachingSlotsEqual(student.carriedItems, studentCustody)
            && teacher.x == teacherPosition.0 && teacher.y == teacherPosition.1
            && teacher.z == teacherPosition.2
            && student.x == studentPosition.0 && student.y == studentPosition.1
            && student.z == studentPosition.2
    }

    private func teachingSlotsEqual(
        _ lhs: [ItemStack?],
        _ rhs: [ItemStack?]
    ) -> Bool {
        lhs.count == rhs.count && zip(lhs, rhs).allSatisfy { left, right in
            switch (left, right) {
            case (nil, nil): return true
            case let (left?, right?): return left == right
            default: return false
            }
        }
    }
}
