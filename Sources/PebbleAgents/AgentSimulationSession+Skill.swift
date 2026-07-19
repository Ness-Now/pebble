extension AgentSimulationSession {
    public var skillsEnabled: Bool { skillState != nil }

    public func skillSnapshot() -> AgentSkillSnapshot {
        guard let state = skillState else {
            return AgentSkillSnapshot(
                enabled: false, configuration: nil, profiles: [],
                retainedPracticeRecords: [], totalPracticeCreditCount: 0,
                totalPracticeUnits: 0, evictionCounts: AgentSkillEvictionCounts(),
                evictedPracticeDigest: AgentSkillDigest.make("empty"),
                digest: AgentSkillDigest.make("disabled")
            )
        }
        return AgentSkillSnapshot(
            enabled: true, configuration: state.configuration,
            profiles: state.profiles.sorted { $0.agentID < $1.agentID },
            retainedPracticeRecords: state.retainedPracticeRecords.sorted(by: skillRecordSort),
            totalPracticeCreditCount: state.totalPracticeCreditCount,
            totalPracticeUnits: state.totalPracticeUnits,
            evictionCounts: state.evictionCounts,
            evictedPracticeDigest: state.evictedPracticeDigest,
            digest: skillDigest(state)
        )
    }

    public func skillProfile(for agentID: AgentID) -> AgentSkillProfile? {
        skillState?.profiles.first { $0.agentID == agentID }
    }

    public func practiceUnits(
        agentID: AgentID,
        domain: AgentSkillDomain
    ) -> Int {
        skillProfile(for: agentID)?.practiceUnits(in: domain) ?? 0
    }

    public func skillLevel(
        agentID: AgentID,
        domain: AgentSkillDomain
    ) -> AgentSkillLevel {
        AgentSkillLevel(practiceUnits: practiceUnits(agentID: agentID, domain: domain))
    }

    public func retainedPracticeHistory(
        agentID: AgentID? = nil,
        domain: AgentSkillDomain? = nil
    ) -> [AgentSkillPracticeRecord] {
        guard let state = skillState else { return [] }
        return state.retainedPracticeRecords.filter {
            (agentID == nil || $0.agentID == agentID)
                && (domain == nil || $0.domain == domain)
        }.sorted(by: skillRecordSort)
    }

    public mutating func setSkillsEnabled(
        _ enabled: Bool,
        configuration: AgentSkillConfiguration = .live
    ) throws {
        if enabled {
            var candidate = self
            try candidate.initializeSkillsInPlace(configuration: configuration)
            try candidate.validateSkillStateIfEnabled()
            self = candidate
        } else if skillState != nil {
            throw AgentSessionError.skill(.unsafeDisable)
        }
    }

    private mutating func initializeSkillsInPlace(
        configuration: AgentSkillConfiguration
    ) throws {
        guard skillState == nil else { throw AgentSessionError.skill(.alreadyEnabled) }
        guard causalLedger.policy != .disabled else {
            throw AgentSessionError.skill(.causalLedgerRequired)
        }
        guard populationRegistry != nil else {
            throw AgentSessionError.skill(.populationRequired)
        }
        guard lifecycleState != nil else {
            throw AgentSessionError.skill(.lifecycleRequired)
        }
        try prevalidateCausalAppend(count: 1)
        let emptyDigest = AgentSkillDigest.make(
            "skills|\(simulationID.rawValue)|\(tick)|empty"
        )
        let event = try requiredSkillEvent(
            kind: .skillsInitialized,
            payload: .skill(
                agentID: nil, domain: nil, practiceUnits: 0,
                cumulativePracticeUnits: 0, sourceSuccessEventID: nil,
                practiceRecordCount: 0, status: "initialized", digest: emptyDigest
            ),
            summary: "skills initialized without retroactive credit"
        )
        skillState = AgentSkillState(
            configuration: configuration, profiles: [], retainedPracticeRecords: [],
            totalPracticeCreditCount: 0, totalPracticeUnits: 0,
            evictionCounts: AgentSkillEvictionCounts(),
            evictedPracticeDigest: AgentSkillDigest.make("empty"),
            rollingDigest: emptyDigest, initializedEventID: event.eventID,
            lastSkillEventID: event.eventID, lastCreditedSourceEventID: nil,
            transitionTick: tick, creditsAtTick: 0
        )
    }

    @discardableResult
    mutating func creditPracticeAfterMaterialSuccess(
        agentID: AgentID,
        domain: AgentSkillDomain,
        sourceSuccessEventID: AgentCausalEventID,
        practiceUnits: Int = 1
    ) throws -> AgentCausalEventID? {
        guard var state = skillState else { return nil }
        guard statesById[agentID.rawValue]?.health ?? 0 > 0 else {
            throw AgentSessionError.skill(.inactiveAgent(agentID))
        }
        guard practiceUnits > 0,
              practiceUnits <= state.configuration.maximumPracticeUnitsPerCredit else {
            throw AgentSessionError.skill(.invalidPracticeUnits(practiceUnits))
        }
        guard let source = causalLedger.events.first(where: {
            $0.eventID == sourceSuccessEventID
        }), skillSourceMatches(source, agentID: agentID, domain: domain) else {
            throw AgentSessionError.skill(.invalidSourceEvent(sourceSuccessEventID))
        }
        if let last = state.lastCreditedSourceEventID,
           sourceSuccessEventID.sequence <= last.sequence {
            throw AgentSessionError.skill(.duplicateSourceEvent(sourceSuccessEventID))
        }
        if state.transitionTick != tick {
            state.transitionTick = tick
            state.creditsAtTick = 0
        }
        guard state.creditsAtTick < state.configuration.maximumPracticeCreditsPerTick else {
            throw AgentSessionError.skill(.creditsPerTickReached)
        }
        var profileIndex = state.profiles.firstIndex { $0.agentID == agentID }
        if profileIndex == nil {
            guard state.profiles.count < state.configuration.maximumProfiles else {
                throw AgentSessionError.skill(.profileCapacityReached)
            }
            state.profiles.append(AgentSkillProfile(agentID: agentID, domainPractices: []))
            state.profiles.sort { $0.agentID < $1.agentID }
            profileIndex = state.profiles.firstIndex { $0.agentID == agentID }
        }
        let currentUnits = state.profiles[profileIndex!].practiceUnits(in: domain)
        let cumulativeUnits = currentUnits + practiceUnits
        guard cumulativeUnits >= currentUnits, state.totalPracticeUnits <= Int.max - practiceUnits else {
            throw AgentSessionError.skill(.invalidState("practice total overflow"))
        }
        try prevalidateCausalAppend(count: 1)
        let nextDigest = AgentSkillDigest.make(
            "\(state.rollingDigest)|\(agentID.rawValue)|\(domain.rawValue)|"
                + "\(practiceUnits)|\(cumulativeUnits)|\(sourceSuccessEventID.rawValue)|\(tick)"
        )
        let practiceEvent = try requiredSkillEvent(
            kind: .skillPracticeCredited,
            actorID: agentID,
            subjectID: agentID,
            causes: [sourceSuccessEventID],
            payload: .skill(
                agentID: agentID.rawValue, domain: domain.rawValue,
                practiceUnits: practiceUnits,
                cumulativePracticeUnits: cumulativeUnits,
                sourceSuccessEventID: sourceSuccessEventID.rawValue,
                practiceRecordCount: state.retainedPracticeRecords.count + 1,
                status: "credited", digest: nextDigest
            ),
            summary: "skill practice credited agent=\(agentID.rawValue) domain=\(domain.rawValue) units=\(practiceUnits)"
        )
        if let domainIndex = state.profiles[profileIndex!].domainPractices.firstIndex(where: {
            $0.domain == domain
        }) {
            state.profiles[profileIndex!].domainPractices[domainIndex].practiceUnits = cumulativeUnits
            state.profiles[profileIndex!].domainPractices[domainIndex].lastPracticeTick = tick
            state.profiles[profileIndex!].domainPractices[domainIndex]
                .lastSourceSuccessEventID = sourceSuccessEventID
            state.profiles[profileIndex!].domainPractices[domainIndex]
                .lastSkillPracticeEventID = practiceEvent.eventID
        } else {
            state.profiles[profileIndex!].domainPractices.append(AgentSkillDomainPractice(
                domain: domain, practiceUnits: practiceUnits, lastPracticeTick: tick,
                lastSourceSuccessEventID: sourceSuccessEventID,
                lastSkillPracticeEventID: practiceEvent.eventID
            ))
        }
        state.profiles[profileIndex!].domainPractices.sort { $0.domain < $1.domain }
        state.retainedPracticeRecords.append(AgentSkillPracticeRecord(
            agentID: agentID, domain: domain, practiceUnits: practiceUnits,
            cumulativePracticeUnits: cumulativeUnits, tick: tick,
            sourceSuccessEventID: sourceSuccessEventID,
            skillPracticeEventID: practiceEvent.eventID,
            sourceKind: source.kind, sourceStatus: skillSourceStatus(source),
            digest: nextDigest
        ))
        evictPracticeRecordsIfNeeded(&state)
        state.totalPracticeCreditCount += 1
        state.totalPracticeUnits += practiceUnits
        state.creditsAtTick += 1
        state.lastSkillEventID = practiceEvent.eventID
        state.lastCreditedSourceEventID = sourceSuccessEventID
        state.rollingDigest = nextDigest
        skillState = state
        return practiceEvent.eventID
    }

    func validateSkillStateIfEnabled() throws {
        guard let state = skillState else { return }
        guard state.profiles.count <= state.configuration.maximumProfiles,
              state.retainedPracticeRecords.count
                <= state.configuration.maximumRetainedPracticeRecords,
              state.evictionCounts.practiceRecords >= 0,
              state.totalPracticeCreditCount >= state.retainedPracticeRecords.count,
              state.totalPracticeUnits >= state.retainedPracticeRecords.reduce(0, {
                  $0 + $1.practiceUnits
              }),
              state.transitionTick <= tick,
              (0...state.configuration.maximumPracticeCreditsPerTick)
                .contains(state.creditsAtTick) else {
            throw AgentSkillError.invalidState("bounds or counters")
        }
        let agentIDs = state.profiles.map(\.agentID)
        guard Set(agentIDs).count == agentIDs.count,
              state.profiles == state.profiles.sorted(by: { $0.agentID < $1.agentID }) else {
            throw AgentSkillError.invalidState("profiles are not unique and canonical")
        }
        let historicalIDs = Set(kinshipState?.historicalPersons.map(\.agentID)
            ?? lifecycleState?.members.map(\.agentID) ?? [])
        for profile in state.profiles {
            guard historicalIDs.contains(profile.agentID),
                  profile.domainPractices == profile.domainPractices.sorted(by: {
                      $0.domain < $1.domain
                  }),
                  Set(profile.domainPractices.map(\.domain)).count
                    == profile.domainPractices.count,
                  profile.domainPractices.allSatisfy({
                      $0.practiceUnits > 0 && $0.lastPracticeTick <= tick
                          && $0.lastSourceSuccessEventID.simulationID == simulationID
                          && $0.lastSkillPracticeEventID.simulationID == simulationID
                  }) else {
                throw AgentSkillError.invalidState("profile history")
            }
        }
        let sortedRecords = state.retainedPracticeRecords.sorted(by: skillRecordSort)
        guard sortedRecords == state.retainedPracticeRecords,
              Set(sortedRecords.map(\.sourceSuccessEventID)).count == sortedRecords.count,
              Set(sortedRecords.map(\.skillPracticeEventID)).count == sortedRecords.count else {
            throw AgentSkillError.invalidState("practice records are not unique and canonical")
        }
        let retainedByAgent = Dictionary(grouping: sortedRecords, by: \.agentID)
        guard retainedByAgent.values.allSatisfy({
            $0.count <= state.configuration.maximumPracticeRecordsPerAgent
        }) else {
            throw AgentSkillError.invalidState("practice records per agent")
        }
        for record in sortedRecords {
            guard record.practiceUnits > 0,
                  record.practiceUnits <= state.configuration.maximumPracticeUnitsPerCredit,
                  record.cumulativePracticeUnits >= record.practiceUnits,
                  record.tick <= tick,
                  record.sourceSuccessEventID.simulationID == simulationID,
                  record.skillPracticeEventID.simulationID == simulationID,
                  record.sourceSuccessEventID.sequence < record.skillPracticeEventID.sequence else {
                throw AgentSkillError.invalidState("practice record")
            }
        }
        guard state.initializedEventID.simulationID == simulationID,
              state.lastSkillEventID.simulationID == simulationID,
              state.initializedEventID.sequence <= state.lastSkillEventID.sequence,
              state.lastCreditedSourceEventID?.simulationID == simulationID
                || state.lastCreditedSourceEventID == nil else {
            throw AgentSkillError.invalidState("causal identity")
        }
    }

    static func validateSkillState(
        _ state: AgentSkillState,
        population: AgentPopulationRegistry,
        lifecycle: AgentLifecycleState,
        historicalAgentIDs: Set<AgentID>,
        clock: AgentSimulationClock,
        causalLatestSequence: UInt64,
        causalDroppedEventCount: UInt64,
        causalEvents: [AgentCausalEvent]
    ) throws {
        _ = population
        _ = lifecycle
        _ = try AgentSkillConfiguration(
            maximumProfiles: state.configuration.maximumProfiles,
            maximumRetainedPracticeRecords:
                state.configuration.maximumRetainedPracticeRecords,
            maximumPracticeRecordsPerAgent:
                state.configuration.maximumPracticeRecordsPerAgent,
            maximumPracticeCreditsPerTick:
                state.configuration.maximumPracticeCreditsPerTick,
            maximumPracticeUnitsPerCredit:
                state.configuration.maximumPracticeUnitsPerCredit
        )
        guard state.profiles.count <= state.configuration.maximumProfiles,
              state.retainedPracticeRecords.count
                <= state.configuration.maximumRetainedPracticeRecords,
              state.evictionCounts.practiceRecords >= 0,
              state.totalPracticeCreditCount
                == state.retainedPracticeRecords.count
                    + state.evictionCounts.practiceRecords,
              state.totalPracticeUnits == state.profiles.reduce(0, {
                  $0 + $1.domainPractices.reduce(0) { $0 + $1.practiceUnits }
              }),
              state.transitionTick >= 0,
              state.transitionTick <= clock.tick.rawValue,
              (0...state.configuration.maximumPracticeCreditsPerTick)
                .contains(state.creditsAtTick),
              validSkillDigest(state.evictedPracticeDigest),
              validSkillDigest(state.rollingDigest) else {
            throw AgentSkillError.invalidState("bounds, totals, or digests")
        }
        let sortedProfiles = state.profiles.sorted { $0.agentID < $1.agentID }
        guard state.profiles == sortedProfiles,
              Set(sortedProfiles.map(\.agentID)).count == sortedProfiles.count else {
            throw AgentSkillError.invalidState("duplicate or noncanonical profiles")
        }
        for profile in sortedProfiles {
            guard historicalAgentIDs.contains(profile.agentID),
                  !profile.domainPractices.isEmpty,
                  profile.domainPractices == profile.domainPractices.sorted(by: {
                      $0.domain < $1.domain
                  }),
                  Set(profile.domainPractices.map(\.domain)).count
                    == profile.domainPractices.count else {
                throw AgentSkillError.invalidState("profile identity or domains")
            }
            for practice in profile.domainPractices {
                guard practice.practiceUnits > 0,
                      practice.lastPracticeTick >= 0,
                      practice.lastPracticeTick <= clock.tick.rawValue,
                      practice.lastSourceSuccessEventID.simulationID == clock.simulationID,
                      practice.lastSkillPracticeEventID.simulationID == clock.simulationID,
                      practice.lastSourceSuccessEventID.sequence
                        < practice.lastSkillPracticeEventID.sequence else {
                    throw AgentSkillError.invalidState("profile practice")
                }
            }
        }
        let records = state.retainedPracticeRecords.sorted(by: staticSkillRecordSort)
        guard records == state.retainedPracticeRecords,
              Set(records.map(\.sourceSuccessEventID)).count == records.count,
              Set(records.map(\.skillPracticeEventID)).count == records.count else {
            throw AgentSkillError.invalidState("duplicate or noncanonical records")
        }
        let recordsByAgent = Dictionary(grouping: records, by: \.agentID)
        guard recordsByAgent.values.allSatisfy({
            $0.count <= state.configuration.maximumPracticeRecordsPerAgent
        }) else {
            throw AgentSkillError.invalidState("records per agent")
        }
        let profilesByID = Dictionary(uniqueKeysWithValues: sortedProfiles.map {
            ($0.agentID, $0)
        })
        for record in records {
            guard historicalAgentIDs.contains(record.agentID),
                  record.practiceUnits > 0,
                  record.practiceUnits
                    <= state.configuration.maximumPracticeUnitsPerCredit,
                  record.cumulativePracticeUnits >= record.practiceUnits,
                  record.tick >= 0, record.tick <= clock.tick.rawValue,
                  record.sourceSuccessEventID.simulationID == clock.simulationID,
                  record.skillPracticeEventID.simulationID == clock.simulationID,
                  record.sourceSuccessEventID.sequence
                    < record.skillPracticeEventID.sequence,
                  validSkillDigest(record.digest),
                  profilesByID[record.agentID]?.practiceUnits(in: record.domain)
                    ?? 0 >= record.cumulativePracticeUnits else {
                throw AgentSkillError.invalidState("practice record")
            }
        }
        for profile in sortedProfiles {
            for practice in profile.domainPractices {
                if let latest = records.filter({
                    $0.agentID == profile.agentID && $0.domain == practice.domain
                }).last {
                    guard latest.cumulativePracticeUnits == practice.practiceUnits,
                          latest.sourceSuccessEventID
                            == practice.lastSourceSuccessEventID,
                          latest.skillPracticeEventID
                            == practice.lastSkillPracticeEventID else {
                        throw AgentSkillError.invalidState("profile/record projection")
                    }
                }
            }
        }
        let latestSource = sortedProfiles.flatMap(\.domainPractices)
            .map(\.lastSourceSuccessEventID).max()
        guard latestSource == state.lastCreditedSourceEventID,
              state.initializedEventID.simulationID == clock.simulationID,
              state.lastSkillEventID.simulationID == clock.simulationID,
              state.initializedEventID.sequence <= state.lastSkillEventID.sequence,
              causalDroppedEventCount <= causalLatestSequence,
              UInt64(causalEvents.count)
                == causalLatestSequence - causalDroppedEventCount,
              causalEvents.enumerated().allSatisfy({ index, event in
                  event.sequence.rawValue
                    == causalDroppedEventCount + UInt64(index) + 1
              }) else {
            throw AgentSkillError.invalidState("causal pointers or retained window")
        }
        let eventsByID = Dictionary(uniqueKeysWithValues: causalEvents.map {
            ($0.eventID, $0)
        })
        func validateReference(
            _ eventID: AgentCausalEventID,
            matches: (AgentCausalEvent) -> Bool
        ) throws {
            guard eventID.simulationID == clock.simulationID,
                  eventID.sequence.rawValue <= causalLatestSequence else {
                throw AgentSkillError.invalidCausalReference(eventID)
            }
            if let event = eventsByID[eventID] {
                guard matches(event) else {
                    throw AgentSkillError.invalidCausalReference(eventID)
                }
            } else if eventID.sequence.rawValue > causalDroppedEventCount {
                throw AgentSkillError.invalidCausalReference(eventID)
            }
        }
        try validateReference(state.initializedEventID) { event in
            guard event.kind == .skillsInitialized,
                  event.origin == .skillTransition,
                  event.actorID == nil, event.subjectID == nil,
                  event.causes.isEmpty,
                  case let .skill(
                      agentID, domain, units, cumulative, sourceID,
                      recordCount, status, digest
                  ) = event.payload else { return false }
            return agentID == nil && domain == nil && units == 0 && cumulative == 0
                && sourceID == nil && recordCount == 0 && status == "initialized"
                && digest == AgentSkillDigest.make(
                    "skills|\(clock.simulationID.rawValue)|"
                        + "\(event.simulationTick.rawValue)|empty"
                )
        }
        func matchesSkillEvent(
            _ event: AgentCausalEvent,
            record: AgentSkillPracticeRecord
        ) -> Bool {
            guard event.kind == .skillPracticeCredited,
                  event.origin == .skillTransition,
                  event.simulationTick.rawValue == record.tick,
                  event.actorID == record.agentID,
                  event.subjectID == record.agentID,
                  event.causes == [record.sourceSuccessEventID],
                  case let .skill(
                      agentID, domain, units, cumulative, sourceID,
                      recordCount, status, digest
                  ) = event.payload else { return false }
            return agentID == record.agentID.rawValue
                && domain == record.domain.rawValue
                && units == record.practiceUnits
                && cumulative == record.cumulativePracticeUnits
                && sourceID == record.sourceSuccessEventID.rawValue
                && recordCount > 0
                && recordCount <= state.configuration.maximumRetainedPracticeRecords + 1
                && status == "credited" && digest == record.digest
        }
        func sourceMatches(
            _ event: AgentCausalEvent,
            record: AgentSkillPracticeRecord
        ) -> Bool {
            guard event.kind == record.sourceKind,
                  event.simulationTick.rawValue == record.tick,
                  event.actorID == record.agentID else { return false }
            switch (record.domain, event.kind, event.payload) {
            case let (.foraging, .ecologyForageResolved, .ecologyForage(
                _, _, agentID, status, yieldBefore, yieldAfter,
                inventoryBefore, inventoryAfter
            )):
                return event.origin == .ecologyTransition && event.subjectID == nil
                    && event.operationID != nil
                    && agentID == record.agentID.rawValue
                    && status == record.sourceStatus && status == "succeeded"
                    && yieldAfter == yieldBefore - 1
                    && inventoryAfter == inventoryBefore + 1
            case let (.materialHandling, .delivery, .operation(status, _)):
                return event.origin == .worldOutcome && event.subjectID == nil
                    && event.operationID != nil
                    && status == record.sourceStatus && status == "succeeded"
            case let (.construction, .constructionPlacement, .operation(status, _)):
                return event.origin == .worldOutcome && event.subjectID == nil
                    && event.operationID != nil
                    && status == record.sourceStatus && status == "succeeded"
            case let (.caregiving, .careProvided, .dependentCare(
                dependentID, caregiverID, _, _, needKind, _, _, status, _, quantity, _
            )):
                return event.origin == .dependentCareTransition
                    && event.operationID == nil
                    && event.subjectID?.rawValue == dependentID
                    && caregiverID == record.agentID.rawValue
                    && needKind == "nourishment" && status == record.sourceStatus
                    && status == "provided" && quantity == 1
                    && event.causes.count == 1
            default:
                return false
            }
        }
        func sourceMatchesProfile(
            _ event: AgentCausalEvent,
            profile: AgentSkillProfile,
            practice: AgentSkillDomainPractice
        ) -> Bool {
            guard event.simulationTick.rawValue == practice.lastPracticeTick,
                  event.actorID == profile.agentID else { return false }
            switch (practice.domain, event.kind, event.payload) {
            case let (.foraging, .ecologyForageResolved, .ecologyForage(
                _, _, agentID, status, yieldBefore, yieldAfter,
                inventoryBefore, inventoryAfter
            )):
                return event.origin == .ecologyTransition && event.subjectID == nil
                    && event.operationID != nil
                    && agentID == profile.agentID.rawValue && status == "succeeded"
                    && yieldAfter == yieldBefore - 1
                    && inventoryAfter == inventoryBefore + 1
            case let (.materialHandling, .delivery, .operation(status, _)):
                return event.origin == .worldOutcome && event.subjectID == nil
                    && event.operationID != nil
                    && status == "succeeded"
            case let (.construction, .constructionPlacement, .operation(status, _)):
                return event.origin == .worldOutcome && event.subjectID == nil
                    && event.operationID != nil
                    && status == "succeeded"
            case let (.caregiving, .careProvided, .dependentCare(
                dependentID, caregiverID, _, _, needKind, _, _, status, _, quantity, _
            )):
                return event.origin == .dependentCareTransition
                    && event.operationID == nil
                    && event.subjectID?.rawValue == dependentID
                    && caregiverID == profile.agentID.rawValue
                    && needKind == "nourishment" && status == "provided"
                    && quantity == 1 && event.causes.count == 1
            default:
                return false
            }
        }
        for record in records {
            try validateReference(record.sourceSuccessEventID) {
                sourceMatches($0, record: record)
            }
            try validateReference(record.skillPracticeEventID) {
                matchesSkillEvent($0, record: record)
            }
        }
        for profile in sortedProfiles {
            for practice in profile.domainPractices {
                try validateReference(practice.lastSourceSuccessEventID) { event in
                    sourceMatchesProfile(event, profile: profile, practice: practice)
                }
                try validateReference(practice.lastSkillPracticeEventID) { event in
                    guard event.kind == .skillPracticeCredited,
                          event.origin == .skillTransition,
                          event.actorID == profile.agentID,
                          event.subjectID == profile.agentID,
                          event.simulationTick.rawValue == practice.lastPracticeTick,
                          event.causes == [practice.lastSourceSuccessEventID],
                          case let .skill(
                              agentID, domain, units, cumulative, sourceID,
                              _, status, _
                          ) = event.payload else { return false }
                    return agentID == profile.agentID.rawValue
                        && domain == practice.domain.rawValue && units > 0
                        && cumulative == practice.practiceUnits
                        && sourceID == practice.lastSourceSuccessEventID.rawValue
                        && status == "credited"
                }
            }
        }
        let retainedSkillEvents = causalEvents.filter {
            $0.origin == .skillTransition
                && ($0.kind == .skillsInitialized || $0.kind == .skillPracticeCredited)
        }
        if let latest = retainedSkillEvents.last {
            guard latest.eventID == state.lastSkillEventID else {
                throw AgentSkillError.invalidCausalReference(state.lastSkillEventID)
            }
        } else if state.lastSkillEventID.sequence.rawValue > causalDroppedEventCount {
            throw AgentSkillError.invalidCausalReference(state.lastSkillEventID)
        }
        try validateReference(state.lastSkillEventID) { event in
            event.origin == .skillTransition
                && (event.kind == .skillsInitialized || event.kind == .skillPracticeCredited)
        }
    }

    private static func staticSkillRecordSort(
        _ lhs: AgentSkillPracticeRecord,
        _ rhs: AgentSkillPracticeRecord
    ) -> Bool {
        if lhs.skillPracticeEventID != rhs.skillPracticeEventID {
            return lhs.skillPracticeEventID < rhs.skillPracticeEventID
        }
        if lhs.agentID != rhs.agentID { return lhs.agentID < rhs.agentID }
        return lhs.domain < rhs.domain
    }

    private static func validSkillDigest(_ value: String) -> Bool {
        value.count == 16 && value.allSatisfy {
            $0.isNumber || ("a"..."f").contains(String($0))
        }
    }

    private func skillSourceMatches(
        _ event: AgentCausalEvent,
        agentID: AgentID,
        domain: AgentSkillDomain
    ) -> Bool {
        guard event.simulationID == simulationID,
              event.simulationTick.rawValue == tick,
              event.actorID == agentID else { return false }
        switch (domain, event.kind, event.payload) {
        case let (.foraging, .ecologyForageResolved, .ecologyForage(
            _, _, payloadAgentID, status, yieldBefore, yieldAfter,
            inventoryBefore, inventoryAfter
        )):
            return payloadAgentID == agentID.rawValue && status == "succeeded"
                && yieldAfter == yieldBefore - 1 && inventoryAfter == inventoryBefore + 1
        case let (.materialHandling, .delivery, .operation(status, _)):
            return status == "succeeded"
        case let (.construction, .constructionPlacement, .operation(status, _)):
            return status == "succeeded"
        case let (.caregiving, .careProvided, .dependentCare(
            _, caregiverID, _, _, needKind, _, _, status, _, materialQuantity, _
        )):
            return caregiverID == agentID.rawValue && needKind == "nourishment"
                && status == "provided" && materialQuantity == 1
        default:
            return false
        }
    }

    private func skillSourceStatus(_ event: AgentCausalEvent) -> String {
        switch event.payload {
        case let .operation(status, _): return status
        case let .ecologyForage(_, _, _, status, _, _, _, _): return status
        case let .dependentCare(_, _, _, _, _, _, _, status, _, _, _): return status
        default: return "unknown"
        }
    }

    private mutating func requiredSkillEvent(
        kind: AgentCausalEventKind,
        actorID: AgentID? = nil,
        subjectID: AgentID? = nil,
        causes: [AgentCausalEventID] = [],
        payload: AgentCausalPayload,
        summary: String
    ) throws -> AgentCausalEvent {
        guard let event = try causalLedger.append(
            instant: simulationInstant, kind: kind, origin: .skillTransition,
            actorID: actorID, subjectID: subjectID, operationID: nil,
            causes: causes, payload: payload, summary: summary
        ) else { throw AgentSessionError.skill(.causalLedgerRequired) }
        return event
    }

    private func skillRecordSort(
        _ lhs: AgentSkillPracticeRecord,
        _ rhs: AgentSkillPracticeRecord
    ) -> Bool {
        if lhs.skillPracticeEventID != rhs.skillPracticeEventID {
            return lhs.skillPracticeEventID < rhs.skillPracticeEventID
        }
        if lhs.agentID != rhs.agentID { return lhs.agentID < rhs.agentID }
        return lhs.domain < rhs.domain
    }

    private func skillDigest(_ state: AgentSkillState) -> String {
        let profiles = state.profiles.sorted { $0.agentID < $1.agentID }.map { profile in
            profile.agentID.rawValue + ":" + profile.domainPractices.sorted {
                $0.domain < $1.domain
            }.map { "\($0.domain.rawValue)=\($0.practiceUnits)" }.joined(separator: ",")
        }.joined(separator: ";")
        return AgentSkillDigest.make(
            "\(state.rollingDigest)|\(profiles)|\(state.totalPracticeCreditCount)|"
                + "\(state.totalPracticeUnits)|\(state.evictionCounts.practiceRecords)|"
                + state.evictedPracticeDigest
        )
    }

    private func evictPracticeRecordsIfNeeded(_ state: inout AgentSkillState) {
        state.retainedPracticeRecords.sort(by: skillRecordSort)
        while let overfullAgent = Dictionary(
            grouping: state.retainedPracticeRecords, by: \.agentID
        ).filter({
            $0.value.count > state.configuration.maximumPracticeRecordsPerAgent
        }).keys.sorted().first,
              let index = state.retainedPracticeRecords.firstIndex(where: {
                  $0.agentID == overfullAgent
              }) {
            evictPracticeRecord(at: index, state: &state)
        }
        while state.retainedPracticeRecords.count
                > state.configuration.maximumRetainedPracticeRecords {
            evictPracticeRecord(at: 0, state: &state)
        }
    }

    private func evictPracticeRecord(at index: Int, state: inout AgentSkillState) {
        let removed = state.retainedPracticeRecords.remove(at: index)
        state.evictionCounts.practiceRecords += 1
        state.evictedPracticeDigest = AgentSkillDigest.make(
            "\(state.evictedPracticeDigest)|\(removed.agentID.rawValue)|"
                + "\(removed.domain.rawValue)|\(removed.practiceUnits)|"
                + "\(removed.sourceSuccessEventID.rawValue)|\(removed.skillPracticeEventID.rawValue)"
        )
    }
}
