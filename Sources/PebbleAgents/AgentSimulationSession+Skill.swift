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
            sourceKind: source.kind, sourceStatus: skillSourceStatus(source)
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
