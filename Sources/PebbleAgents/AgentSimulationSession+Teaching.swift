import Foundation

extension AgentSimulationSession {
    public var teachingEnabled: Bool { teachingState != nil }

    public func teachingSnapshot() -> AgentTeachingSnapshot {
        guard let state = teachingState else {
            return AgentTeachingSnapshot(
                enabled: false, configuration: nil, apprenticeships: [],
                demonstrations: [], exposures: [], guidedPracticeLinks: [],
                totalApprenticeshipCount: 0, totalDemonstrationCount: 0,
                totalExposureCount: 0, totalGuidedPracticeCount: 0,
                evictionCounts: AgentTeachingEvictionCounts(),
                evictedHistoryDigest: AgentTeachingDigest.make("empty"),
                digest: AgentTeachingDigest.make("disabled")
            )
        }
        return AgentTeachingSnapshot(
            enabled: true, configuration: state.configuration,
            apprenticeships: state.apprenticeships.sorted(by: teachingApprenticeshipSort),
            demonstrations: state.demonstrations.sorted(by: teachingDemonstrationSort),
            exposures: state.exposures.sorted(by: teachingExposureSort),
            guidedPracticeLinks: state.guidedPracticeLinks.sorted(by: teachingGuidedSort),
            totalApprenticeshipCount: state.totalApprenticeshipCount,
            totalDemonstrationCount: state.totalDemonstrationCount,
            totalExposureCount: state.totalExposureCount,
            totalGuidedPracticeCount: state.totalGuidedPracticeCount,
            evictionCounts: state.evictionCounts,
            evictedHistoryDigest: state.evictedHistoryDigest,
            digest: teachingDigest(state)
        )
    }

    public func activeApprenticeship(
        studentID: AgentID,
        domain: AgentSkillDomain
    ) -> AgentApprenticeshipEngagement? {
        teachingState?.apprenticeships.first {
            $0.studentID == studentID && $0.domain == domain && $0.status == .active
        }
    }

    public func freshLearningExposures(
        studentID: AgentID,
        domain: AgentSkillDomain,
        at exposureTick: Int? = nil
    ) -> [AgentLearningExposure] {
        let selectedTick = exposureTick ?? tick
        return teachingState?.exposures.filter {
            $0.studentID == studentID && $0.domain == domain
                && $0.isFresh(at: selectedTick)
        }.sorted(by: teachingExposureSort) ?? []
    }

    public func autonomousTeachingReviewSnapshot() -> AgentAutonomousTeachingReviewSnapshot {
        latestAutonomousTeachingReview ?? AgentAutonomousTeachingReviewSnapshot(
            reviewedAtTick: tick,
            cadenceDue: tick % AgentTeachingParticipationPolicy.reviewIntervalTicks == 0,
            opportunitiesConsidered: 0, requestsAttempted: 0, accepted: 0,
            refusedStudent: 0, refusedTeacher: 0, noMentor: 0, started: 0,
            active: teachingState?.apprenticeships.filter {
                $0.status == .active
            }.count ?? 0,
            ended: teachingState?.apprenticeships.filter {
                $0.status.isTerminal
            }.count ?? 0,
            attempts: []
        )
    }

    public func teachingParticipationDecision(
        for participantID: AgentID,
        role: AgentTeachingParticipationRole
    ) -> AgentTeachingParticipationDecision {
        AgentTeachingParticipationPolicy.decide(
            teachingParticipationContext(for: participantID, role: role)
        )
    }

    /// Reviews bounded, contextual opportunities at the normal deterministic
    /// cadence. The existing CIV-20 selector remains the sole mentor-ranking
    /// and apprenticeship-start authority.
    @discardableResult
    public mutating func reviewLocalApprenticeshipOpportunities(
        _ opportunities: [AgentLocalApprenticeshipOpportunity]
    ) throws -> AgentAutonomousTeachingReviewSnapshot {
        var candidate = self
        let review = try candidate.reviewLocalApprenticeshipOpportunitiesInPlace(
            opportunities
        )
        self = candidate
        return review
    }

    private mutating func reviewLocalApprenticeshipOpportunitiesInPlace(
        _ opportunities: [AgentLocalApprenticeshipOpportunity]
    ) throws -> AgentAutonomousTeachingReviewSnapshot {
        guard let teaching = teachingState else {
            throw AgentSessionError.teaching(.disabled)
        }
        let cadenceDue = tick % AgentTeachingParticipationPolicy.reviewIntervalTicks == 0
        let activeCount = teaching.apprenticeships.filter { $0.status == .active }.count
        let endedCount = teaching.apprenticeships.filter { $0.status.isTerminal }.count
        guard cadenceDue else {
            let review = AgentAutonomousTeachingReviewSnapshot(
                reviewedAtTick: tick, cadenceDue: false,
                opportunitiesConsidered: 0, requestsAttempted: 0, accepted: 0,
                refusedStudent: 0, refusedTeacher: 0, noMentor: 0, started: 0,
                active: activeCount, ended: endedCount, attempts: []
            )
            latestAutonomousTeachingReview = review
            return review
        }
        guard opportunities.count <= AgentAutonomousActivityConfiguration.live
                .maximumCandidatesPerDecision else {
            throw AgentSessionError.teaching(.invalidRequest("local opportunity bound"))
        }
        let sorted = opportunities.sorted(by: localOpportunitySort)
        guard Set(sorted.map {
            "\($0.studentID.rawValue)|\($0.domain.rawValue)"
        }).count == sorted.count else {
            throw AgentSessionError.teaching(.invalidRequest("duplicate local opportunity"))
        }

        var attempts: [AgentLocalApprenticeshipAttempt] = []
        var requestsAttempted = 0
        var refusedStudent = 0
        var refusedTeacher = 0
        var noMentor = 0
        var started = 0

        for opportunity in sorted {
            guard opportunity.observedAtTick == tick,
                  !opportunity.contextReference.isEmpty,
                  statesById[opportunity.studentID.rawValue] != nil,
                  !opportunity.localMentorCandidateIDs.isEmpty,
                  opportunity.localMentorCandidateIDs.count
                    <= teaching.configuration.maximumMentorCandidates,
                  Set(opportunity.localMentorCandidateIDs).count
                    == opportunity.localMentorCandidateIDs.count else {
                throw AgentSessionError.teaching(
                    .invalidRequest(opportunity.contextReference)
                )
            }
            let locallyObserved = Set(
                statesById[opportunity.studentID.rawValue]!.nearbyAgents.compactMap {
                    AgentID(rawValue: $0.id)
                }
            )
            guard opportunity.localMentorCandidateIDs.allSatisfy({
                $0 != opportunity.studentID && locallyObserved.contains($0)
            }) else {
                throw AgentSessionError.teaching(
                    .invalidRequest("nonlocal mentor candidate")
                )
            }

            let studentDecision = teachingParticipationDecision(
                for: opportunity.studentID, role: .student
            )
            if activeApprenticeship(
                studentID: opportunity.studentID, domain: opportunity.domain
            ) != nil {
                attempts.append(AgentLocalApprenticeshipAttempt(
                    opportunity: opportunity, studentDecision: studentDecision,
                    teacherDecisions: [],
                    disposition: .activeApprenticeshipExists,
                    apprenticeshipID: activeApprenticeship(
                        studentID: opportunity.studentID, domain: opportunity.domain
                    )?.apprenticeshipID
                ))
                continue
            }
            let recentTerminal = teachingState!.apprenticeships
                .filter {
                    $0.studentID == opportunity.studentID
                        && $0.domain == opportunity.domain
                        && $0.status.isTerminal
                        && $0.endedAtTick != nil
                }
                .sorted(by: teachingApprenticeshipSort)
                .last
            if let endedAtTick = recentTerminal?.endedAtTick,
               tick - endedAtTick
                < AgentTeachingParticipationPolicy.reengagementCooldownTicks {
                attempts.append(AgentLocalApprenticeshipAttempt(
                    opportunity: opportunity, studentDecision: studentDecision,
                    teacherDecisions: [],
                    disposition: .reengagementCooldown,
                    apprenticeshipID: recentTerminal?.apprenticeshipID
                ))
                continue
            }
            guard studentDecision.accepts else {
                refusedStudent += 1
                attempts.append(AgentLocalApprenticeshipAttempt(
                    opportunity: opportunity, studentDecision: studentDecision,
                    teacherDecisions: [], disposition: .studentRefused,
                    apprenticeshipID: nil
                ))
                continue
            }

            let teacherDecisions = opportunity.localMentorCandidateIDs.sorted().map {
                teachingParticipationDecision(for: $0, role: .teacher)
            }
            refusedTeacher += teacherDecisions.filter { !$0.accepts }.count
            requestsAttempted += 1
            let request = AgentMentorSelectionRequest(
                requestID: autonomousTeachingRequestID(
                    opportunity: opportunity, ordinal: attempts.count + 1
                ),
                studentID: opportunity.studentID,
                domain: opportunity.domain,
                studentAccepts: studentDecision.accepts,
                candidates: teacherDecisions.map {
                    AgentMentorCandidateConsent(
                        teacherID: $0.participantID, accepts: $0.accepts
                    )
                },
                requestedAtTick: tick
            )
            do {
                if let engagement = try selectMentorAndStartApprenticeshipInPlace(request) {
                    started += 1
                    attempts.append(AgentLocalApprenticeshipAttempt(
                        opportunity: opportunity, studentDecision: studentDecision,
                        teacherDecisions: teacherDecisions, disposition: .started,
                        apprenticeshipID: engagement.apprenticeshipID
                    ))
                }
            } catch AgentSessionError.teaching(.noEligibleMentor) {
                noMentor += 1
                attempts.append(AgentLocalApprenticeshipAttempt(
                    opportunity: opportunity, studentDecision: studentDecision,
                    teacherDecisions: teacherDecisions, disposition: .noEligibleMentor,
                    apprenticeshipID: nil
                ))
            }
        }
        let review = AgentAutonomousTeachingReviewSnapshot(
            reviewedAtTick: tick, cadenceDue: true,
            opportunitiesConsidered: sorted.count,
            requestsAttempted: requestsAttempted, accepted: started,
            refusedStudent: refusedStudent, refusedTeacher: refusedTeacher,
            noMentor: noMentor, started: started,
            active: teachingState!.apprenticeships.filter {
                $0.status == .active
            }.count,
            ended: teachingState!.apprenticeships.filter {
                $0.status.isTerminal
            }.count,
            attempts: attempts
        )
        latestAutonomousTeachingReview = review
        return review
    }

    /// Called by the existing autonomous decision transition. Domain
    /// relevance comes only from current bounded activity candidates and their
    /// locally observed peers; no domain sweep or population oracle exists.
    mutating func reviewAutonomousLocalApprenticeships(
        from candidates: [AgentAutonomousActivityCandidate]
    ) throws {
        guard teachingState != nil else {
            latestAutonomousTeachingReview = nil
            return
        }
        struct RelevantContext {
            let studentID: AgentID
            let domain: AgentSkillDomain
            let reason: AgentLocalApprenticeshipReason
            let reference: String
        }
        var contexts: [RelevantContext] = []
        for candidate in candidates.sorted(by: candidateSort) {
            guard candidate.observedAtTick == tick,
                  let domain = candidate.domain.skillDomain,
                  let actorState = statesById[candidate.actorID.rawValue] else {
                continue
            }
            contexts.append(RelevantContext(
                studentID: candidate.actorID, domain: domain,
                reason: .currentAutonomousActivity,
                reference: candidate.candidateID
            ))
            for nearby in actorState.nearbyAgents.sorted(by: {
                if $0.distanceManhattan != $1.distanceManhattan {
                    return $0.distanceManhattan < $1.distanceManhattan
                }
                return $0.id < $1.id
            }) {
                guard let peerID = AgentID(rawValue: nearby.id),
                      statesById[peerID.rawValue]?.nearbyAgents.contains(where: {
                          $0.id == candidate.actorID.rawValue
                      }) == true else { continue }
                contexts.append(RelevantContext(
                    studentID: peerID, domain: domain,
                    reason: .nearbyLocalProductiveActivity,
                    reference: candidate.candidateID
                ))
            }
        }
        var selectedByKey: [String: RelevantContext] = [:]
        for context in contexts.sorted(by: {
            if $0.studentID != $1.studentID { return $0.studentID < $1.studentID }
            if $0.domain != $1.domain { return $0.domain < $1.domain }
            if $0.reason != $1.reason { return $0.reason.rawValue < $1.reason.rawValue }
            return $0.reference < $1.reference
        }) {
            let key = "\(context.studentID.rawValue)|\(context.domain.rawValue)"
            if selectedByKey[key] == nil { selectedByKey[key] = context }
        }
        let maximumMentors = teachingState!.configuration.maximumMentorCandidates
        let opportunities = selectedByKey.values.sorted {
            if $0.studentID != $1.studentID { return $0.studentID < $1.studentID }
            return $0.domain < $1.domain
        }.compactMap { context -> AgentLocalApprenticeshipOpportunity? in
            guard let student = statesById[context.studentID.rawValue] else { return nil }
            let local = student.nearbyAgents.compactMap {
                AgentID(rawValue: $0.id)
            }.filter {
                $0 != context.studentID && statesById[$0.rawValue] != nil
            }.sorted()
            let bounded = Array(local.prefix(maximumMentors))
            guard !bounded.isEmpty else { return nil }
            return AgentLocalApprenticeshipOpportunity(
                studentID: context.studentID, domain: context.domain,
                localMentorCandidateIDs: bounded, reason: context.reason,
                contextReference: context.reference, observedAtTick: tick
            )
        }
        _ = try reviewLocalApprenticeshipOpportunitiesInPlace(opportunities)
    }

    public mutating func setTeachingEnabled(
        _ enabled: Bool,
        configuration teachingConfiguration: AgentTeachingConfiguration = .live
    ) throws {
        if enabled {
            var candidate = self
            try candidate.initializeTeachingInPlace(configuration: teachingConfiguration)
            try candidate.validateTeachingStateIfEnabled()
            self = candidate
        } else if teachingState != nil {
            throw AgentSessionError.teaching(.unsafeDisable)
        }
    }

    private mutating func initializeTeachingInPlace(
        configuration teachingConfiguration: AgentTeachingConfiguration
    ) throws {
        guard teachingState == nil else {
            throw AgentSessionError.teaching(.alreadyEnabled)
        }
        guard causalLedger.policy != .disabled else {
            throw AgentSessionError.teaching(.causalLedgerRequired)
        }
        guard populationRegistry != nil else {
            throw AgentSessionError.teaching(.populationRequired)
        }
        guard lifecycleState != nil else {
            throw AgentSessionError.teaching(.lifecycleRequired)
        }
        guard skillState != nil else {
            throw AgentSessionError.teaching(.skillsRequired)
        }
        guard teachingConfiguration.maximumObservationDistance
                <= configuration.physicalChannelConfiguration.gestureRadius else {
            throw AgentSessionError.teaching(
                .invalidConfiguration("observation distance exceeds physical gesture radius")
            )
        }
        try prevalidateCausalAppend(count: 1)
        let digest = AgentTeachingDigest.make(
            "teaching|\(simulationID.rawValue)|\(tick)|empty"
        )
        let event = try requiredTeachingEvent(
            kind: .teachingInitialized,
            payload: teachingPayload(status: "initialized", digest: digest),
            summary: "teaching initialized without retroactive exposure"
        )
        teachingState = AgentTeachingState(
            configuration: teachingConfiguration, apprenticeships: [],
            demonstrations: [], exposures: [], guidedPracticeLinks: [],
            totalApprenticeshipCount: 0, totalDemonstrationCount: 0,
            totalExposureCount: 0, totalGuidedPracticeCount: 0,
            evictionCounts: AgentTeachingEvictionCounts(),
            evictedHistoryDigest: AgentTeachingDigest.make("empty"),
            rollingDigest: digest, initializedEventID: event.eventID,
            lastTeachingEventID: event.eventID, transitionTick: tick,
            demonstrationsAtTick: 0
        )
    }

    /// Selects a real mentor and starts a temporary engagement. Candidate
    /// consent is explicit; skill, trust, locality and availability are read
    /// from the aggregate root and ranked with a stable ID tie-break.
    @discardableResult
    public mutating func selectMentorAndStartApprenticeship(
        _ request: AgentMentorSelectionRequest
    ) throws -> AgentApprenticeshipEngagement? {
        var candidate = self
        let result = try candidate.selectMentorAndStartApprenticeshipInPlace(request)
        self = candidate
        return result
    }

    private mutating func selectMentorAndStartApprenticeshipInPlace(
        _ request: AgentMentorSelectionRequest
    ) throws -> AgentApprenticeshipEngagement? {
        guard var state = teachingState else {
            throw AgentSessionError.teaching(.disabled)
        }
        guard !request.requestID.isEmpty, request.requestID.utf8.count <= 160,
              request.requestedAtTick == tick,
              !request.candidates.isEmpty,
              request.candidates.count <= state.configuration.maximumMentorCandidates,
              Set(request.candidates.map(\.teacherID)).count == request.candidates.count else {
            throw AgentSessionError.teaching(.invalidRequest(request.requestID))
        }
        guard statesById[request.studentID.rawValue] != nil else {
            throw AgentSessionError.teaching(.unknownAgent(request.studentID))
        }
        guard teachingStudentIsEligible(request.studentID) else {
            throw AgentSessionError.teaching(.ineligibleStudent(request.studentID))
        }
        guard request.studentAccepts else { return nil }
        guard activeApprenticeship(studentID: request.studentID, domain: request.domain) == nil else {
            throw AgentSessionError.teaching(
                .activeApprenticeshipExists(request.studentID, request.domain)
            )
        }
        let active = state.apprenticeships.filter { $0.status == .active }
        guard active.count < state.configuration.maximumActiveApprenticeships else {
            throw AgentSessionError.teaching(.apprenticeshipCapacityReached)
        }
        let studentUnits = practiceUnits(agentID: request.studentID, domain: request.domain)
        let studentPosition = statesById[request.studentID.rawValue]!.position
        struct RankedMentor {
            let id: AgentID
            let units: Int
            let trust: Int
            let distance: Int
            let skillEventID: AgentCausalEventID
        }
        let ranked: [RankedMentor] = request.candidates.compactMap { consent in
            let teacherID = consent.teacherID
            guard consent.accepts, teacherID != request.studentID,
                  teachingTeacherIsEligible(teacherID, domain: request.domain),
                  let teacherPosition = statesById[teacherID.rawValue]?.position else {
                return nil
            }
            let units = practiceUnits(agentID: teacherID, domain: request.domain)
            guard units > studentUnits,
                  skillLevel(agentID: teacherID, domain: request.domain) >= .practiced,
                  active.filter({ $0.teacherID == teacherID }).count
                    < state.configuration.maximumApprenticesPerTeacher,
                  let skillEventID = skillProfile(for: teacherID)?.domainPractices.first(where: {
                      $0.domain == request.domain
                  })?.lastSkillPracticeEventID else { return nil }
            let distance = teachingDistance(teacherPosition, studentPosition)
            guard distance <= state.configuration.maximumObservationDistance else { return nil }
            return RankedMentor(
                id: teacherID, units: units,
                trust: trustScore(
                    sourceAgentId: request.studentID.rawValue,
                    targetAgentId: teacherID.rawValue
                ),
                distance: distance, skillEventID: skillEventID
            )
        }.sorted { lhs, rhs in
            if lhs.units != rhs.units { return lhs.units > rhs.units }
            if lhs.trust != rhs.trust { return lhs.trust > rhs.trust }
            if lhs.distance != rhs.distance { return lhs.distance < rhs.distance }
            return lhs.id < rhs.id
        }
        guard let selected = ranked.first else {
            throw AgentSessionError.teaching(.noEligibleMentor)
        }
        let ordinal = state.totalApprenticeshipCount + 1
        guard ordinal > state.totalApprenticeshipCount,
              let apprenticeshipID = AgentApprenticeshipID(
                rawValue: "apprenticeship-\(String(format: "%08d", ordinal))"
              ), tick <= Int.max - state.configuration.maximumApprenticeshipDurationTicks else {
            throw AgentSessionError.teaching(.invalidState("apprenticeship ordinal"))
        }
        try prevalidateCausalAppend(count: 1)
        let nextDigest = AgentTeachingDigest.make(
            "\(state.rollingDigest)|start|\(apprenticeshipID.rawValue)|"
                + "\(selected.id.rawValue)|\(request.studentID.rawValue)|"
                + "\(request.domain.rawValue)|\(selected.units)|\(selected.trust)|"
                + "\(selected.distance)|\(tick)"
        )
        var causes = [state.lastTeachingEventID, selected.skillEventID]
        if let trustEvent = socialTrustRelations.first(where: {
            $0.sourceID == request.studentID && $0.targetID == selected.id
        })?.lastChangeEventID {
            causes.append(trustEvent)
        }
        let event = try requiredTeachingEvent(
            kind: .apprenticeshipStarted, actorID: selected.id,
            subjectID: request.studentID, causes: Array(Set(causes)).sorted(),
            payload: teachingPayload(
                apprenticeshipID: apprenticeshipID, teacherID: selected.id,
                studentID: request.studentID, domain: request.domain,
                status: "active", reason: "mentorSelected", digest: nextDigest
            ),
            summary: "apprenticeship started id=\(apprenticeshipID.rawValue)"
        )
        let engagement = AgentApprenticeshipEngagement(
            apprenticeshipID: apprenticeshipID, requestID: request.requestID,
            teacherID: selected.id, studentID: request.studentID, domain: request.domain,
            startedAtTick: tick,
            expiresAtTick: tick + state.configuration.maximumApprenticeshipDurationTicks,
            endedAtTick: nil, status: .active, endReason: nil,
            teacherPracticeUnitsAtSelection: selected.units,
            trustAtSelection: selected.trust, distanceAtSelection: selected.distance,
            startedEventID: event.eventID, lastEventID: event.eventID
        )
        state.apprenticeships.append(engagement)
        state.totalApprenticeshipCount = ordinal
        state.lastTeachingEventID = event.eventID
        state.rollingDigest = nextDigest
        evictTeachingHistoryIfNeeded(&state)
        teachingState = state
        return engagement
    }

    @discardableResult
    public mutating func recordTeachingDemonstration(
        _ observation: AgentTeachingObservation
    ) throws -> AgentLearningExposure {
        var candidate = self
        let exposure = try candidate.recordTeachingDemonstrationInPlace(observation)
        self = candidate
        return exposure
    }

    private mutating func recordTeachingDemonstrationInPlace(
        _ observation: AgentTeachingObservation
    ) throws -> AgentLearningExposure {
        guard var state = teachingState else {
            throw AgentSessionError.teaching(.disabled)
        }
        guard let engagementIndex = state.apprenticeships.firstIndex(where: {
            $0.apprenticeshipID == observation.apprenticeshipID
        }) else {
            throw AgentSessionError.teaching(.unknownApprenticeship(observation.apprenticeshipID))
        }
        let engagement = state.apprenticeships[engagementIndex]
        guard engagement.status == .active,
              engagement.teacherID == observation.teacherID,
              engagement.studentID == observation.studentID,
              engagement.domain == observation.domain,
              tick <= engagement.expiresAtTick else {
            throw AgentSessionError.teaching(.invalidObservation("inactive engagement"))
        }
        guard teachingTeacherIsEligible(observation.teacherID, domain: observation.domain) else {
            throw AgentSessionError.teaching(.ineligibleTeacher(observation.teacherID))
        }
        guard teachingStudentIsEligible(observation.studentID) else {
            throw AgentSessionError.teaching(.ineligibleStudent(observation.studentID))
        }
        guard observation.observedAtTick == tick,
              observation.teacherPosition == statesById[observation.teacherID.rawValue]?.position,
              observation.studentPosition == statesById[observation.studentID.rawValue]?.position,
              observation.distanceManhattan == teachingDistance(
                  observation.teacherPosition, observation.studentPosition
              ), observation.distanceManhattan <= state.configuration.maximumObservationDistance,
              observation.opaqueOcclusionCount >= 0 else {
            throw AgentSessionError.teaching(.invalidObservation("identity, position, or distance"))
        }
        let outcome = configuration.physicalChannelConfiguration.classify(
            soundClarity: observation.soundClarity,
            gestureClarity: observation.gestureClarity,
            lineOfSight: observation.lineOfSight,
            chunksReady: observation.chunksReady,
            isIntendedRecipient: true
        )
        guard outcome == .exact else {
            throw AgentSessionError.teaching(.invalidObservation("physical perception not exact"))
        }
        guard let source = causalLedger.events.first(where: {
            $0.eventID == observation.sourceSuccessEventID
        }), source.simulationID == simulationID,
              AgentMaterialSuccessEvidence.matches(
                  source, agentID: observation.teacherID, domain: observation.domain
              ) else {
            throw AgentSessionError.teaching(.invalidSourceEvent(observation.sourceSuccessEventID))
        }
        guard source.eventID.sequence > engagement.startedEventID.sequence,
              source.simulationTick.rawValue > engagement.startedAtTick,
              source.simulationTick.rawValue <= tick,
              tick - source.simulationTick.rawValue
                <= state.configuration.demonstrationFreshnessTicks else {
            throw AgentSessionError.teaching(.staleDemonstration(source.eventID))
        }
        guard !state.demonstrations.contains(where: {
            $0.teacherID == observation.teacherID
                && $0.studentID == observation.studentID
                && $0.domain == observation.domain
                && $0.sourceSuccessEventID == observation.sourceSuccessEventID
        }) else {
            throw AgentSessionError.teaching(.duplicateDemonstration(source.eventID))
        }
        if state.transitionTick != tick {
            state.transitionTick = tick
            state.demonstrationsAtTick = 0
        }
        guard state.demonstrationsAtTick
                < state.configuration.maximumDemonstrationsPerTick else {
            throw AgentSessionError.teaching(.demonstrationsPerTickReached)
        }
        let ordinal = state.totalDemonstrationCount + 1
        let exposureOrdinal = state.totalExposureCount + 1
        guard ordinal > state.totalDemonstrationCount,
              exposureOrdinal > state.totalExposureCount,
              let demonstrationID = AgentDemonstrationID(
                rawValue: "demonstration-\(String(format: "%08d", ordinal))"
              ), let exposureID = AgentLearningExposureID(
                rawValue: "exposure-\(String(format: "%08d", exposureOrdinal))"
              ), tick <= Int.max - state.configuration.exposureFreshnessTicks else {
            throw AgentSessionError.teaching(.invalidState("demonstration ordinal"))
        }
        try prevalidateCausalAppend(count: 1)
        let nextDigest = AgentTeachingDigest.make(
            "\(state.rollingDigest)|observe|\(demonstrationID.rawValue)|"
                + "\(exposureID.rawValue)|\(observation.teacherID.rawValue)|"
                + "\(observation.studentID.rawValue)|\(observation.domain.rawValue)|"
                + "\(source.eventID.rawValue)|\(observation.distanceManhattan)|\(tick)"
        )
        let event = try requiredTeachingEvent(
            kind: .demonstrationObserved, actorID: observation.teacherID,
            subjectID: observation.studentID,
            causes: [engagement.lastEventID, source.eventID].sorted(),
            payload: teachingPayload(
                apprenticeshipID: engagement.apprenticeshipID,
                demonstrationID: demonstrationID, exposureID: exposureID,
                teacherID: observation.teacherID, studentID: observation.studentID,
                domain: observation.domain, sourceSuccessEventID: source.eventID,
                status: "attended", digest: nextDigest
            ),
            summary: "demonstration observed id=\(demonstrationID.rawValue)"
        )
        let demonstration = AgentDemonstrationRecord(
            demonstrationID: demonstrationID,
            apprenticeshipID: engagement.apprenticeshipID,
            teacherID: observation.teacherID, studentID: observation.studentID,
            domain: observation.domain, sourceSuccessEventID: source.eventID,
            observedAtTick: tick, teacherPosition: observation.teacherPosition,
            studentPosition: observation.studentPosition,
            distanceManhattan: observation.distanceManhattan, attention: .attended,
            demonstrationEventID: event.eventID, digest: nextDigest
        )
        let exposure = AgentLearningExposure(
            exposureID: exposureID, demonstrationID: demonstrationID,
            apprenticeshipID: engagement.apprenticeshipID,
            teacherID: observation.teacherID, studentID: observation.studentID,
            domain: observation.domain, sourceSuccessEventID: source.eventID,
            demonstrationEventID: event.eventID, observedAtTick: tick,
            expiresAtTick: tick + state.configuration.exposureFreshnessTicks,
            attention: .attended, status: .observed,
            guidedPracticeEventID: nil, digest: nextDigest
        )
        state.demonstrations.append(demonstration)
        state.exposures.append(exposure)
        state.apprenticeships[engagementIndex].lastEventID = event.eventID
        state.totalDemonstrationCount = ordinal
        state.totalExposureCount = exposureOrdinal
        state.demonstrationsAtTick += 1
        state.lastTeachingEventID = event.eventID
        state.rollingDigest = nextDigest
        evictTeachingHistoryIfNeeded(&state)
        teachingState = state
        return exposure
    }

    @discardableResult
    public mutating func linkGuidedPractice(
        exposureID: AgentLearningExposureID,
        studentSourceSuccessEventID: AgentCausalEventID,
        skillPracticeEventID: AgentCausalEventID
    ) throws -> AgentGuidedPracticeLink {
        var candidate = self
        let link = try candidate.linkGuidedPracticeInPlace(
            exposureID: exposureID,
            studentSourceSuccessEventID: studentSourceSuccessEventID,
            skillPracticeEventID: skillPracticeEventID
        )
        self = candidate
        return link
    }

    private mutating func linkGuidedPracticeInPlace(
        exposureID: AgentLearningExposureID,
        studentSourceSuccessEventID: AgentCausalEventID,
        skillPracticeEventID: AgentCausalEventID
    ) throws -> AgentGuidedPracticeLink {
        guard var state = teachingState else {
            throw AgentSessionError.teaching(.disabled)
        }
        guard let exposureIndex = state.exposures.firstIndex(where: {
            $0.exposureID == exposureID
        }) else {
            throw AgentSessionError.teaching(.invalidGuidedPractice("unknown exposure"))
        }
        let exposure = state.exposures[exposureIndex]
        guard exposure.status == .observed, exposure.isFresh(at: tick),
              state.apprenticeships.contains(where: {
                  $0.apprenticeshipID == exposure.apprenticeshipID && $0.status == .active
              }) else {
            throw AgentSessionError.teaching(.invalidGuidedPractice("inactive context"))
        }
        guard !state.guidedPracticeLinks.contains(where: {
            $0.skillPracticeEventID == skillPracticeEventID
        }) else {
            throw AgentSessionError.teaching(.duplicateGuidedPractice(skillPracticeEventID))
        }
        guard let source = causalLedger.events.first(where: {
            $0.eventID == studentSourceSuccessEventID
        }), AgentMaterialSuccessEvidence.matches(
            source, agentID: exposure.studentID, domain: exposure.domain
        ), source.simulationTick.rawValue == tick,
              source.eventID.sequence > exposure.demonstrationEventID.sequence,
              let skillEvent = causalLedger.events.first(where: {
                  $0.eventID == skillPracticeEventID
              }), skillEvent.kind == .skillPracticeCredited,
              skillEvent.origin == .skillTransition,
              skillEvent.actorID == exposure.studentID,
              skillEvent.subjectID == exposure.studentID,
              skillEvent.causes == [studentSourceSuccessEventID],
              skillEvent.simulationTick.rawValue == tick,
              case let .skill(
                  agentID, domain, units, _, sourceID, _, status, _
              ) = skillEvent.payload,
              agentID == exposure.studentID.rawValue,
              domain == exposure.domain.rawValue, units == 1,
              sourceID == studentSourceSuccessEventID.rawValue,
              status == "credited" else {
            throw AgentSessionError.teaching(.invalidGuidedPractice("material/skill provenance"))
        }
        try prevalidateCausalAppend(count: 1)
        let nextDigest = AgentTeachingDigest.make(
            "\(state.rollingDigest)|guided|\(exposureID.rawValue)|"
                + "\(studentSourceSuccessEventID.rawValue)|"
                + "\(skillPracticeEventID.rawValue)|\(tick)"
        )
        let event = try requiredTeachingEvent(
            kind: .guidedPracticeLinked, actorID: exposure.studentID,
            subjectID: exposure.studentID,
            causes: [
                exposure.demonstrationEventID,
                studentSourceSuccessEventID,
                skillPracticeEventID,
            ].sorted(),
            payload: teachingPayload(
                apprenticeshipID: exposure.apprenticeshipID,
                demonstrationID: exposure.demonstrationID,
                exposureID: exposure.exposureID, teacherID: exposure.teacherID,
                studentID: exposure.studentID, domain: exposure.domain,
                sourceSuccessEventID: studentSourceSuccessEventID,
                skillPracticeEventID: skillPracticeEventID,
                status: "linked", digest: nextDigest
            ),
            summary: "guided practice linked exposure=\(exposureID.rawValue)"
        )
        let link = AgentGuidedPracticeLink(
            exposureID: exposureID, apprenticeshipID: exposure.apprenticeshipID,
            teacherID: exposure.teacherID, studentID: exposure.studentID,
            domain: exposure.domain,
            studentSourceSuccessEventID: studentSourceSuccessEventID,
            skillPracticeEventID: skillPracticeEventID, linkedAtTick: tick,
            guidedPracticeEventID: event.eventID, digest: nextDigest
        )
        state.exposures[exposureIndex].status = .guidedPracticeLinked
        state.exposures[exposureIndex].guidedPracticeEventID = event.eventID
        state.guidedPracticeLinks.append(link)
        state.totalGuidedPracticeCount += 1
        state.lastTeachingEventID = event.eventID
        state.rollingDigest = nextDigest
        evictTeachingHistoryIfNeeded(&state)
        teachingState = state
        return link
    }

    public mutating func endApprenticeship(
        _ apprenticeshipID: AgentApprenticeshipID,
        by participantID: AgentID,
        reason: AgentApprenticeshipEndReason
    ) throws {
        var candidate = self
        try candidate.endApprenticeshipInPlace(
            apprenticeshipID, participantID: participantID, reason: reason, at: tick
        )
        self = candidate
    }

    private mutating func endApprenticeshipInPlace(
        _ apprenticeshipID: AgentApprenticeshipID,
        participantID: AgentID,
        reason: AgentApprenticeshipEndReason,
        at endTick: Int
    ) throws {
        guard var state = teachingState else {
            throw AgentSessionError.teaching(.disabled)
        }
        guard let index = state.apprenticeships.firstIndex(where: {
            $0.apprenticeshipID == apprenticeshipID
        }) else {
            throw AgentSessionError.teaching(.unknownApprenticeship(apprenticeshipID))
        }
        let engagement = state.apprenticeships[index]
        guard engagement.status == .active else { return }
        guard participantID == engagement.teacherID || participantID == engagement.studentID else {
            throw AgentSessionError.teaching(.invalidParticipant(participantID))
        }
        let status: AgentApprenticeshipStatus
        switch reason {
        case .completed: status = .completed
        case .expired: status = .expired
        default: status = .interrupted
        }
        try prevalidateCausalAppend(count: 1)
        let nextDigest = AgentTeachingDigest.make(
            "\(state.rollingDigest)|end|\(apprenticeshipID.rawValue)|"
                + "\(status.rawValue)|\(reason.rawValue)|\(endTick)"
        )
        let event = try requiredTeachingEvent(
            kind: .apprenticeshipEnded, actorID: participantID,
            subjectID: engagement.studentID, causes: [engagement.lastEventID],
            payload: teachingPayload(
                apprenticeshipID: apprenticeshipID, teacherID: engagement.teacherID,
                studentID: engagement.studentID, domain: engagement.domain,
                status: status.rawValue, reason: reason.rawValue, digest: nextDigest
            ),
            summary: "apprenticeship ended id=\(apprenticeshipID.rawValue) reason=\(reason.rawValue)"
        )
        state.apprenticeships[index].status = status
        state.apprenticeships[index].endReason = reason
        state.apprenticeships[index].endedAtTick = endTick
        state.apprenticeships[index].lastEventID = event.eventID
        state.lastTeachingEventID = event.eventID
        state.rollingDigest = nextDigest
        evictTeachingHistoryIfNeeded(&state)
        teachingState = state
    }

    mutating func reconcileTeachingBoundary(at teachingTick: Int) throws {
        guard teachingState != nil else { return }
        let active = teachingState!.apprenticeships.filter { $0.status == .active }
            .sorted(by: teachingApprenticeshipSort)
        for engagement in active {
            let reason: AgentApprenticeshipEndReason?
            if statesById[engagement.teacherID.rawValue] == nil
                || statesById[engagement.studentID.rawValue] == nil {
                reason = .participantUnavailable
            } else if isMigratingAgent(engagement.teacherID.rawValue)
                        || isMigratingAgent(engagement.studentID.rawValue) {
                reason = .migration
            } else if teachingHasCriticalHunger(engagement.teacherID)
                        || teachingHasCriticalHunger(engagement.studentID) {
                reason = .criticalHunger
            } else if activeCareEngagement(for: engagement.teacherID) != nil
                        || activeCareEngagement(for: engagement.studentID) != nil {
                reason = .carePriority
            } else if teachingIsUnsafe(engagement.teacherID)
                        || teachingIsUnsafe(engagement.studentID) {
                reason = .unsafeContext
            } else if teachingTick > engagement.expiresAtTick {
                reason = .expired
            } else {
                reason = nil
            }
            if let reason {
                try endApprenticeshipInPlace(
                    engagement.apprenticeshipID,
                    participantID: engagement.studentID,
                    reason: reason,
                    at: teachingTick
                )
            }
        }
    }

    func validateTeachingStateIfEnabled() throws {
        guard let state = teachingState else { return }
        var historicalIDs = Set(lifecycleState?.members.map(\.agentID) ?? [])
        historicalIDs.formUnion(kinshipState?.historicalPersons.map(\.agentID) ?? [])
        historicalIDs.formUnion(mortalityState?.records.map(\.agentID) ?? [])
        try Self.validateTeachingState(
            state, historicalAgentIDs: historicalIDs,
            activeAgentIDs: Set(statesById.values.map(\.agentID)), clock: clock,
            physicalConfiguration: configuration.physicalChannelConfiguration,
            causalLatestSequence: causalLedger.latestSequence,
            causalDroppedEventCount: causalLedger.droppedEventCount,
            causalEvents: causalLedger.events
        )
    }

    static func validateTeachingState(
        _ state: AgentTeachingState,
        historicalAgentIDs: Set<AgentID>,
        activeAgentIDs: Set<AgentID>,
        clock: AgentSimulationClock,
        physicalConfiguration: AgentPhysicalChannelConfiguration,
        causalLatestSequence: UInt64,
        causalDroppedEventCount: UInt64,
        causalEvents: [AgentCausalEvent]
    ) throws {
        _ = try AgentTeachingConfiguration(
            maximumMentorCandidates: state.configuration.maximumMentorCandidates,
            maximumActiveApprenticeships: state.configuration.maximumActiveApprenticeships,
            maximumRetainedApprenticeships: state.configuration.maximumRetainedApprenticeships,
            maximumApprenticesPerTeacher: state.configuration.maximumApprenticesPerTeacher,
            maximumRetainedDemonstrations: state.configuration.maximumRetainedDemonstrations,
            maximumRetainedExposures: state.configuration.maximumRetainedExposures,
            maximumExposuresPerStudent: state.configuration.maximumExposuresPerStudent,
            maximumRetainedGuidedPracticeLinks:
                state.configuration.maximumRetainedGuidedPracticeLinks,
            maximumDemonstrationsPerTick: state.configuration.maximumDemonstrationsPerTick,
            maximumApprenticeshipDurationTicks:
                state.configuration.maximumApprenticeshipDurationTicks,
            demonstrationFreshnessTicks: state.configuration.demonstrationFreshnessTicks,
            exposureFreshnessTicks: state.configuration.exposureFreshnessTicks,
            maximumObservationDistance: state.configuration.maximumObservationDistance
        )
        guard state.configuration.maximumObservationDistance
                <= physicalConfiguration.gestureRadius,
              state.apprenticeships.count
                <= state.configuration.maximumRetainedApprenticeships,
              state.demonstrations.count
                <= state.configuration.maximumRetainedDemonstrations,
              state.exposures.count <= state.configuration.maximumRetainedExposures,
              state.guidedPracticeLinks.count
                <= state.configuration.maximumRetainedGuidedPracticeLinks,
              state.apprenticeships.filter({ $0.status == .active }).count
                <= state.configuration.maximumActiveApprenticeships,
              state.totalApprenticeshipCount
                == state.apprenticeships.count + state.evictionCounts.apprenticeships,
              state.totalDemonstrationCount
                == state.demonstrations.count + state.evictionCounts.demonstrations,
              state.totalExposureCount
                == state.exposures.count + state.evictionCounts.exposures,
              state.totalGuidedPracticeCount
                == state.guidedPracticeLinks.count
                    + state.evictionCounts.guidedPracticeLinks,
              state.transitionTick <= clock.tick.rawValue,
              (0...state.configuration.maximumDemonstrationsPerTick)
                .contains(state.demonstrationsAtTick),
              teachingDigestIsValid(state.evictedHistoryDigest),
              teachingDigestIsValid(state.rollingDigest) else {
            throw AgentTeachingError.invalidState("bounds, counters, or digests")
        }
        guard state.apprenticeships == state.apprenticeships.sorted(by: staticApprenticeshipSort),
              state.demonstrations == state.demonstrations.sorted(by: staticDemonstrationSort),
              state.exposures == state.exposures.sorted(by: staticExposureSort),
              state.guidedPracticeLinks == state.guidedPracticeLinks.sorted(by: staticGuidedSort),
              Set(state.apprenticeships.map(\.apprenticeshipID)).count
                == state.apprenticeships.count,
              Set(state.demonstrations.map(\.demonstrationID)).count
                == state.demonstrations.count,
              Set(state.exposures.map(\.exposureID)).count == state.exposures.count,
              Set(state.guidedPracticeLinks.map(\.skillPracticeEventID)).count
                == state.guidedPracticeLinks.count else {
            throw AgentTeachingError.invalidState("noncanonical or duplicate history")
        }
        let exposureGroups = Dictionary(grouping: state.exposures, by: \.studentID)
        guard exposureGroups.values.allSatisfy({
            $0.count <= state.configuration.maximumExposuresPerStudent
        }) else { throw AgentTeachingError.invalidState("exposures per student") }
        let activeGroups = Dictionary(
            grouping: state.apprenticeships.filter { $0.status == .active },
            by: \.teacherID
        )
        guard activeGroups.values.allSatisfy({
            $0.count <= state.configuration.maximumApprenticesPerTeacher
        }) else { throw AgentTeachingError.invalidState("apprentices per teacher") }
        for item in state.apprenticeships {
            guard historicalAgentIDs.contains(item.teacherID),
                  historicalAgentIDs.contains(item.studentID),
                  item.teacherID != item.studentID,
                  item.startedAtTick >= 0, item.startedAtTick <= clock.tick.rawValue,
                  item.expiresAtTick >= item.startedAtTick,
                  item.expiresAtTick - item.startedAtTick
                    <= state.configuration.maximumApprenticeshipDurationTicks,
                  item.startedEventID.simulationID == clock.simulationID,
                  item.lastEventID.simulationID == clock.simulationID,
                  item.startedEventID.sequence <= item.lastEventID.sequence,
                  (item.status == .active
                    ? item.endedAtTick == nil && item.endReason == nil
                        && activeAgentIDs.contains(item.teacherID)
                        && activeAgentIDs.contains(item.studentID)
                    : item.endedAtTick != nil && item.endReason != nil) else {
                throw AgentTeachingError.invalidState("apprenticeship record")
            }
        }
        for item in state.demonstrations {
            guard historicalAgentIDs.contains(item.teacherID),
                  historicalAgentIDs.contains(item.studentID),
                  item.teacherID != item.studentID,
                  item.observedAtTick >= 0, item.observedAtTick <= clock.tick.rawValue,
                  item.distanceManhattan >= 0,
                  item.distanceManhattan <= state.configuration.maximumObservationDistance,
                  item.sourceSuccessEventID.simulationID == clock.simulationID,
                  item.demonstrationEventID.simulationID == clock.simulationID,
                  item.sourceSuccessEventID.sequence
                    < item.demonstrationEventID.sequence,
                  teachingDigestIsValid(item.digest) else {
                throw AgentTeachingError.invalidState("demonstration record")
            }
        }
        for item in state.exposures {
            guard historicalAgentIDs.contains(item.teacherID),
                  historicalAgentIDs.contains(item.studentID),
                  item.observedAtTick >= 0, item.observedAtTick <= clock.tick.rawValue,
                  item.expiresAtTick >= item.observedAtTick,
                  item.expiresAtTick - item.observedAtTick
                    == state.configuration.exposureFreshnessTicks,
                  item.sourceSuccessEventID.sequence
                    < item.demonstrationEventID.sequence,
                  (item.status == .observed) == (item.guidedPracticeEventID == nil),
                  teachingDigestIsValid(item.digest) else {
                throw AgentTeachingError.invalidState("exposure record")
            }
        }
        for item in state.guidedPracticeLinks {
            guard historicalAgentIDs.contains(item.teacherID),
                  historicalAgentIDs.contains(item.studentID),
                  item.linkedAtTick >= 0, item.linkedAtTick <= clock.tick.rawValue,
                  item.studentSourceSuccessEventID.sequence
                    < item.skillPracticeEventID.sequence,
                  item.skillPracticeEventID.sequence
                    < item.guidedPracticeEventID.sequence,
                  teachingDigestIsValid(item.digest) else {
                throw AgentTeachingError.invalidState("guided practice record")
            }
        }
        guard causalDroppedEventCount <= causalLatestSequence,
              UInt64(causalEvents.count) == causalLatestSequence - causalDroppedEventCount,
              state.initializedEventID.simulationID == clock.simulationID,
              state.lastTeachingEventID.simulationID == clock.simulationID,
              state.initializedEventID.sequence <= state.lastTeachingEventID.sequence else {
            throw AgentTeachingError.invalidState("causal window")
        }
        let eventsByID = Dictionary(uniqueKeysWithValues: causalEvents.map { ($0.eventID, $0) })
        func validateReference(
            _ eventID: AgentCausalEventID,
            matches: (AgentCausalEvent) -> Bool
        ) throws {
            guard eventID.simulationID == clock.simulationID,
                  eventID.sequence.rawValue <= causalLatestSequence else {
                throw AgentTeachingError.invalidCausalReference(eventID)
            }
            if let event = eventsByID[eventID] {
                guard matches(event) else {
                    throw AgentTeachingError.invalidCausalReference(eventID)
                }
            } else if eventID.sequence.rawValue > causalDroppedEventCount {
                throw AgentTeachingError.invalidCausalReference(eventID)
            }
        }
        try validateReference(state.initializedEventID) {
            $0.kind == .teachingInitialized && $0.origin == .teachingTransition
        }
        try validateReference(state.lastTeachingEventID) {
            $0.origin == .teachingTransition
        }
        for item in state.apprenticeships {
            try validateReference(item.startedEventID) {
                $0.kind == .apprenticeshipStarted && $0.origin == .teachingTransition
                    && $0.actorID == item.teacherID && $0.subjectID == item.studentID
            }
            try validateReference(item.lastEventID) {
                $0.origin == .teachingTransition
                    && ($0.kind == .apprenticeshipStarted
                        || $0.kind == .demonstrationObserved
                        || $0.kind == .apprenticeshipEnded)
            }
        }
        for item in state.demonstrations {
            try validateReference(item.sourceSuccessEventID) {
                AgentMaterialSuccessEvidence.matches(
                    $0, agentID: item.teacherID, domain: item.domain
                )
            }
            try validateReference(item.demonstrationEventID) {
                $0.kind == .demonstrationObserved
                    && $0.origin == .teachingTransition
                    && $0.actorID == item.teacherID && $0.subjectID == item.studentID
                    && $0.causes.contains(item.sourceSuccessEventID)
            }
        }
        for item in state.guidedPracticeLinks {
            try validateReference(item.studentSourceSuccessEventID) {
                AgentMaterialSuccessEvidence.matches(
                    $0, agentID: item.studentID, domain: item.domain
                )
            }
            try validateReference(item.skillPracticeEventID) {
                $0.kind == .skillPracticeCredited && $0.actorID == item.studentID
                    && $0.causes == [item.studentSourceSuccessEventID]
            }
            try validateReference(item.guidedPracticeEventID) {
                $0.kind == .guidedPracticeLinked && $0.origin == .teachingTransition
                    && $0.causes.contains(item.skillPracticeEventID)
            }
        }
    }

    private func teachingTeacherIsEligible(
        _ teacherID: AgentID,
        domain: AgentSkillDomain
    ) -> Bool {
        guard teachingParticipationDecision(for: teacherID, role: .teacher).accepts,
              lifecycleState?.members.first(where: {
                  $0.agentID == teacherID
              })?.currentStage == .mature else { return false }
        return skillLevel(agentID: teacherID, domain: domain) >= .practiced
    }

    private func teachingStudentIsEligible(_ studentID: AgentID) -> Bool {
        guard teachingParticipationDecision(for: studentID, role: .student).accepts,
              let stage = lifecycleState?.members.first(where: {
                  $0.agentID == studentID
              })?.currentStage else { return false }
        return stage != .newborn
            && AgentStageCapabilityPolicy.policy(for: stage).permits(.perceive)
    }

    private func teachingParticipationContext(
        for id: AgentID,
        role: AgentTeachingParticipationRole
    ) -> AgentTeachingParticipationContext {
        let state = statesById[id.rawValue]
        let activeApprenticeships = teachingState?.apprenticeships.filter {
            $0.status == .active && $0.teacherID == id
        }.count ?? 0
        return AgentTeachingParticipationContext(
            participantID: id, role: role,
            active: state.map { $0.health > 0 } ?? false,
            lifecycleStage: lifecycleState?.members.first {
                $0.agentID == id
            }?.currentStage,
            migrating: isMigratingAgent(id.rawValue),
            criticalHunger: state.map {
                $0.needs.hunger
                    >= configuration.survivalConfiguration.criticalHungerThreshold
            } ?? false,
            urgentCarePriority: activeCareEngagement(for: id) != nil,
            unsafe: state.map {
                $0.needs.safety <= 0 || $0.currentGoal.kind == .seekSafety
            } ?? true,
            incompatibleUrgentResponsibility: activeAutonomousActivity(for: id)?
                .candidate.domain == .dependentCare,
            teacherCapacityAvailable: activeApprenticeships
                < (teachingState?.configuration.maximumApprenticesPerTeacher ?? 0)
        )
    }

    private func teachingHasCriticalHunger(_ id: AgentID) -> Bool {
        guard let state = statesById[id.rawValue] else { return false }
        return state.needs.hunger
            >= configuration.survivalConfiguration.criticalHungerThreshold
    }

    private func teachingIsUnsafe(_ id: AgentID) -> Bool {
        statesById[id.rawValue]?.needs.safety ?? 0 <= 0
    }

    private func teachingDistance(_ lhs: AgentPosition, _ rhs: AgentPosition) -> Int {
        abs(lhs.x - rhs.x) + abs(lhs.y - rhs.y) + abs(lhs.z - rhs.z)
    }

    private func localOpportunitySort(
        _ lhs: AgentLocalApprenticeshipOpportunity,
        _ rhs: AgentLocalApprenticeshipOpportunity
    ) -> Bool {
        if lhs.studentID != rhs.studentID { return lhs.studentID < rhs.studentID }
        if lhs.domain != rhs.domain { return lhs.domain < rhs.domain }
        if lhs.reason != rhs.reason { return lhs.reason.rawValue < rhs.reason.rawValue }
        return lhs.contextReference < rhs.contextReference
    }

    private func autonomousTeachingRequestID(
        opportunity: AgentLocalApprenticeshipOpportunity,
        ordinal: Int
    ) -> String {
        String(
            "auto-apprenticeship-\(tick)-\(ordinal)-"
                + "\(opportunity.studentID.rawValue)-\(opportunity.domain.rawValue)"
        ).prefix(160).description
    }

    private mutating func requiredTeachingEvent(
        kind: AgentCausalEventKind,
        actorID: AgentID? = nil,
        subjectID: AgentID? = nil,
        causes: [AgentCausalEventID] = [],
        payload: AgentCausalPayload,
        summary: String
    ) throws -> AgentCausalEvent {
        guard let event = try causalLedger.append(
            instant: simulationInstant, kind: kind, origin: .teachingTransition,
            actorID: actorID, subjectID: subjectID, operationID: nil,
            causes: causes, payload: payload, summary: summary
        ) else { throw AgentSessionError.teaching(.causalLedgerRequired) }
        return event
    }

    private func teachingPayload(
        apprenticeshipID: AgentApprenticeshipID? = nil,
        demonstrationID: AgentDemonstrationID? = nil,
        exposureID: AgentLearningExposureID? = nil,
        teacherID: AgentID? = nil,
        studentID: AgentID? = nil,
        domain: AgentSkillDomain? = nil,
        sourceSuccessEventID: AgentCausalEventID? = nil,
        skillPracticeEventID: AgentCausalEventID? = nil,
        status: String,
        reason: String? = nil,
        digest: String
    ) -> AgentCausalPayload {
        .teaching(
            apprenticeshipID: apprenticeshipID?.rawValue,
            demonstrationID: demonstrationID?.rawValue,
            exposureID: exposureID?.rawValue,
            teacherID: teacherID?.rawValue,
            studentID: studentID?.rawValue,
            domain: domain?.rawValue,
            sourceSuccessEventID: sourceSuccessEventID?.rawValue,
            skillPracticeEventID: skillPracticeEventID?.rawValue,
            status: status, reason: reason, digest: digest
        )
    }

    private func teachingDigest(_ state: AgentTeachingState) -> String {
        let active = state.apprenticeships.filter { $0.status == .active }.map {
            "\($0.apprenticeshipID.rawValue):\($0.teacherID.rawValue)>"
                + "\($0.studentID.rawValue):\($0.domain.rawValue)"
        }.joined(separator: ";")
        return AgentTeachingDigest.make(
            "\(state.rollingDigest)|\(active)|\(state.totalApprenticeshipCount)|"
                + "\(state.totalDemonstrationCount)|\(state.totalExposureCount)|"
                + "\(state.totalGuidedPracticeCount)|\(state.evictionCounts.apprenticeships),"
                + "\(state.evictionCounts.demonstrations),\(state.evictionCounts.exposures),"
                + "\(state.evictionCounts.guidedPracticeLinks)|\(state.evictedHistoryDigest)"
        )
    }

    private mutating func evictTeachingHistoryIfNeeded(_ state: inout AgentTeachingState) {
        state.apprenticeships.sort(by: teachingApprenticeshipSort)
        while state.apprenticeships.count
                > state.configuration.maximumRetainedApprenticeships,
              let index = state.apprenticeships.firstIndex(where: { $0.status.isTerminal }) {
            let removed = state.apprenticeships.remove(at: index)
            recordTeachingEviction(
                "apprenticeship|\(removed.apprenticeshipID.rawValue)",
                state: &state
            )
            state.evictionCounts.apprenticeships += 1
        }
        state.demonstrations.sort(by: teachingDemonstrationSort)
        while state.demonstrations.count
                > state.configuration.maximumRetainedDemonstrations {
            let removed = state.demonstrations.removeFirst()
            recordTeachingEviction(
                "demonstration|\(removed.demonstrationID.rawValue)", state: &state
            )
            state.evictionCounts.demonstrations += 1
        }
        state.exposures.sort(by: teachingExposureSort)
        while let student = Dictionary(grouping: state.exposures, by: \.studentID)
            .filter({
                $0.value.count > state.configuration.maximumExposuresPerStudent
            }).keys.sorted().first,
              let index = state.exposures.firstIndex(where: { $0.studentID == student }) {
            let removed = state.exposures.remove(at: index)
            recordTeachingEviction(
                "exposure|\(removed.exposureID.rawValue)", state: &state
            )
            state.evictionCounts.exposures += 1
        }
        while state.exposures.count > state.configuration.maximumRetainedExposures {
            let removed = state.exposures.removeFirst()
            recordTeachingEviction(
                "exposure|\(removed.exposureID.rawValue)", state: &state
            )
            state.evictionCounts.exposures += 1
        }
        state.guidedPracticeLinks.sort(by: teachingGuidedSort)
        while state.guidedPracticeLinks.count
                > state.configuration.maximumRetainedGuidedPracticeLinks {
            let removed = state.guidedPracticeLinks.removeFirst()
            recordTeachingEviction(
                "guided|\(removed.guidedPracticeEventID.rawValue)", state: &state
            )
            state.evictionCounts.guidedPracticeLinks += 1
        }
    }

    private func recordTeachingEviction(
        _ text: String,
        state: inout AgentTeachingState
    ) {
        state.evictedHistoryDigest = AgentTeachingDigest.make(
            "\(state.evictedHistoryDigest)|\(text)"
        )
    }

    private func teachingApprenticeshipSort(
        _ lhs: AgentApprenticeshipEngagement,
        _ rhs: AgentApprenticeshipEngagement
    ) -> Bool { lhs.apprenticeshipID < rhs.apprenticeshipID }

    private func teachingDemonstrationSort(
        _ lhs: AgentDemonstrationRecord,
        _ rhs: AgentDemonstrationRecord
    ) -> Bool { lhs.demonstrationEventID < rhs.demonstrationEventID }

    private func teachingExposureSort(
        _ lhs: AgentLearningExposure,
        _ rhs: AgentLearningExposure
    ) -> Bool { lhs.demonstrationEventID < rhs.demonstrationEventID }

    private func teachingGuidedSort(
        _ lhs: AgentGuidedPracticeLink,
        _ rhs: AgentGuidedPracticeLink
    ) -> Bool { lhs.guidedPracticeEventID < rhs.guidedPracticeEventID }

    private static func staticApprenticeshipSort(
        _ lhs: AgentApprenticeshipEngagement,
        _ rhs: AgentApprenticeshipEngagement
    ) -> Bool { lhs.apprenticeshipID < rhs.apprenticeshipID }

    private static func staticDemonstrationSort(
        _ lhs: AgentDemonstrationRecord,
        _ rhs: AgentDemonstrationRecord
    ) -> Bool { lhs.demonstrationEventID < rhs.demonstrationEventID }

    private static func staticExposureSort(
        _ lhs: AgentLearningExposure,
        _ rhs: AgentLearningExposure
    ) -> Bool { lhs.demonstrationEventID < rhs.demonstrationEventID }

    private static func staticGuidedSort(
        _ lhs: AgentGuidedPracticeLink,
        _ rhs: AgentGuidedPracticeLink
    ) -> Bool { lhs.guidedPracticeEventID < rhs.guidedPracticeEventID }

    private static func teachingDigestIsValid(_ value: String) -> Bool {
        value.count == 16 && value.allSatisfy {
            $0.isNumber || ("a"..."f").contains(String($0))
        }
    }
}
