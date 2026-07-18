extension AgentSimulationSession {
    public var householdsEnabled: Bool { householdState != nil }

    public func householdSnapshot() -> AgentHouseholdSnapshot {
        guard let state = householdState else {
            return AgentHouseholdSnapshot(
                enabled: false,
                configuration: nil,
                households: [],
                membershipPeriods: [],
                currentMemberships: [],
                nextHouseholdOrdinal: nil,
                totalHistoricalHouseholdCount: 0,
                totalMembershipPeriodCount: 0,
                digest: AgentHouseholdDigest.make("disabled")
            )
        }
        let households = state.households.sorted(by: householdRecordSort)
        let periods = state.membershipPeriods.sorted(by: householdPeriodSort)
        let recordsByID = Dictionary(uniqueKeysWithValues: households.map {
            ($0.householdID, $0)
        })
        let current = periods.compactMap { period -> AgentCurrentHouseholdMembership? in
            guard period.leftTick == nil, let record = recordsByID[period.householdID] else {
                return nil
            }
            return AgentCurrentHouseholdMembership(
                agentID: period.agentID,
                householdID: period.householdID,
                residenceAnchor: record.residenceAnchor,
                joinedTick: period.joinedTick,
                joinedReason: period.joinedReason
            )
        }.sorted { $0.agentID < $1.agentID }
        return AgentHouseholdSnapshot(
            enabled: true,
            configuration: state.configuration,
            households: households,
            membershipPeriods: periods,
            currentMemberships: current,
            nextHouseholdOrdinal: state.nextHouseholdOrdinal.rawValue,
            totalHistoricalHouseholdCount: state.totalHistoricalHouseholdCount,
            totalMembershipPeriodCount: state.totalMembershipPeriodCount,
            digest: householdDigest(state)
        )
    }

    public func household(for agentID: AgentID) throws -> AgentHouseholdRecord? {
        guard let state = householdState else { return nil }
        guard historicalPerson(for: agentID) != nil else {
            throw AgentSessionError.household(.unknownAgent(agentID))
        }
        guard let membership = state.membershipPeriods.first(where: {
            $0.agentID == agentID && $0.leftTick == nil
        }) else { return nil }
        return state.households.first { $0.householdID == membership.householdID }
    }

    public func members(of householdID: AgentHouseholdID) throws -> [AgentID] {
        guard let state = householdState else { return [] }
        guard let household = state.households.first(where: { $0.householdID == householdID }) else {
            throw AgentSessionError.household(.unknownHousehold(householdID))
        }
        guard household.status == .active else {
            throw AgentSessionError.household(.dissolvedHousehold(householdID))
        }
        return state.membershipPeriods.compactMap {
            $0.householdID == householdID && $0.leftTick == nil ? $0.agentID : nil
        }.sorted()
    }

    public func currentMembership(
        of agentID: AgentID
    ) throws -> AgentCurrentHouseholdMembership? {
        guard let state = householdState else { return nil }
        guard historicalPerson(for: agentID) != nil else {
            throw AgentSessionError.household(.unknownAgent(agentID))
        }
        guard let period = state.membershipPeriods.first(where: {
            $0.agentID == agentID && $0.leftTick == nil
        }), let household = state.households.first(where: {
            $0.householdID == period.householdID
        }) else { return nil }
        return AgentCurrentHouseholdMembership(
            agentID: agentID,
            householdID: period.householdID,
            residenceAnchor: household.residenceAnchor,
            joinedTick: period.joinedTick,
            joinedReason: period.joinedReason
        )
    }

    public func membershipHistory(
        of agentID: AgentID
    ) throws -> [AgentHouseholdMembershipPeriod] {
        guard let state = householdState else { return [] }
        guard historicalPerson(for: agentID) != nil else {
            throw AgentSessionError.household(.unknownAgent(agentID))
        }
        return state.membershipPeriods.filter { $0.agentID == agentID }
            .sorted(by: householdPeriodSort)
    }

    public mutating func setHouseholdsEnabled(
        _ enabled: Bool,
        configuration: AgentHouseholdConfiguration = .live
    ) throws {
        if enabled {
            var candidate = self
            try candidate.initializeHouseholdsInPlace(configuration: configuration)
            self = candidate
        } else if householdState != nil {
            throw AgentSessionError.household(.unsafeDisable)
        }
    }

    public mutating func formHousehold(
        memberIDs: [AgentID],
        residenceAnchor: AgentPosition
    ) throws -> AgentHouseholdRecord {
        var candidate = self
        let record = try candidate.formHouseholdInPlace(
            memberIDs: memberIDs,
            residenceAnchor: residenceAnchor,
            joinedReason: .formedHousehold
        )
        try candidate.applyDependentCareTickBoundary(at: candidate.tick)
        try candidate.validateHouseholdCrossDomainIfEnabled()
        try candidate.validateDependentCareCrossDomainIfEnabled()
        self = candidate
        return record
    }

    public mutating func createSingletonHousehold(
        for agentID: AgentID,
        residenceAnchor: AgentPosition,
        reason: AgentHouseholdMembershipReason
    ) throws -> AgentHouseholdRecord {
        guard [.formedHousehold, .birth, .migrationAdmission].contains(reason) else {
            throw AgentSessionError.household(.invalidMembership(agentID))
        }
        var candidate = self
        let record = try candidate.formHouseholdInPlace(
            memberIDs: [agentID],
            residenceAnchor: residenceAnchor,
            joinedReason: reason
        )
        try candidate.applyDependentCareTickBoundary(at: candidate.tick)
        try candidate.validateHouseholdCrossDomainIfEnabled()
        try candidate.validateDependentCareCrossDomainIfEnabled()
        self = candidate
        return record
    }

    public mutating func moveMembers(
        memberIDs: [AgentID],
        to householdID: AgentHouseholdID
    ) throws {
        var candidate = self
        try candidate.moveMembersInPlace(memberIDs: memberIDs, to: householdID)
        try candidate.applyDependentCareTickBoundary(at: candidate.tick)
        try candidate.validateHouseholdCrossDomainIfEnabled()
        try candidate.validateDependentCareCrossDomainIfEnabled()
        self = candidate
    }

    private mutating func initializeHouseholdsInPlace(
        configuration: AgentHouseholdConfiguration
    ) throws {
        guard causalLedger.isEnabled else {
            throw AgentSessionError.household(.causalLedgerRequired)
        }
        guard householdState == nil else {
            throw AgentSessionError.household(.alreadyEnabled)
        }
        guard let population = populationRegistry else {
            throw AgentSessionError.household(.populationRequired)
        }
        guard lifecycleState != nil else {
            throw AgentSessionError.household(.lifecycleRequired)
        }
        guard kinshipState != nil else {
            throw AgentSessionError.household(.kinshipRequired)
        }
        let residents = population.members.filter {
            $0.status == .founderResident || $0.status == .resident
        }.sorted { $0.agentID < $1.agentID }
        guard residents.allSatisfy({ statesById[$0.agentID.rawValue] != nil }) else {
            throw AgentSessionError.household(.invalidState("resident without AgentState"))
        }
        var groups: [AgentPosition: [AgentID]] = [:]
        for member in residents {
            groups[statesById[member.agentID.rawValue]!.homePosition, default: []]
                .append(member.agentID)
        }
        let orderedGroups = groups.map { anchor, ids in
            (anchor: anchor, ids: ids.sorted())
        }.sorted {
            if householdPositionLess($0.anchor, $1.anchor) { return true }
            if householdPositionLess($1.anchor, $0.anchor) { return false }
            return $0.ids[0] < $1.ids[0]
        }
        guard orderedGroups.count <= configuration.maximumHistoricalHouseholds else {
            throw AgentSessionError.household(.householdCapacityReached)
        }
        guard orderedGroups.count <= configuration.maximumActiveHouseholds else {
            throw AgentSessionError.household(.activeHouseholdCapacityReached)
        }
        guard residents.count <= configuration.maximumMembershipPeriods else {
            throw AgentSessionError.household(.membershipPeriodCapacityReached)
        }
        guard orderedGroups.allSatisfy({
            $0.ids.count <= configuration.maximumMembersPerHousehold
        }) else {
            throw AgentSessionError.household(.memberCapacityReached(
                AgentHouseholdID(rawValue: "household_0")!
            ))
        }
        guard residents.count <= configuration.maximumHouseholdTransitionsPerTick else {
            throw AgentSessionError.household(.transitionCapacityReached)
        }
        try prevalidateCausalAppend(count: 1 + orderedGroups.count + residents.count)
        let digest = AgentHouseholdDigest.make(
            "initialize|" + orderedGroups.map {
                "\(householdPositionText($0.anchor)):\($0.ids.map(\.rawValue).joined(separator: ","))"
            }.joined(separator: ";")
        )
        let initialized = try requiredHouseholdEvent(
            kind: .householdsInitialized,
            payload: .household(
                householdID: nil, ordinal: nil,
                settlementID: population.settlement.settlementID.rawValue,
                agentID: nil, residenceAnchor: nil,
                householdCount: orderedGroups.count,
                membershipCount: residents.count,
                reason: AgentHouseholdMembershipReason.initialization.rawValue,
                status: "initialized", digest: digest
            ),
            summary: "households initialized households=\(orderedGroups.count) memberships=\(residents.count)"
        )
        var state = AgentHouseholdState(
            configuration: configuration,
            households: [],
            membershipPeriods: [],
            nextHouseholdOrdinal: AgentHouseholdOrdinal(rawValue: 0)!,
            totalHistoricalHouseholdCount: 0,
            totalMembershipPeriodCount: 0,
            transitionTick: tick,
            transitionsAtTick: residents.count,
            rollingDigest: digest,
            initializedEventID: initialized.eventID,
            lastHouseholdEventID: initialized.eventID
        )
        for group in orderedGroups {
            let ordinal = state.nextHouseholdOrdinal
            let householdID = AgentHouseholdID(rawValue: "household_\(ordinal.rawValue)")!
            let created = try requiredHouseholdEvent(
                kind: .householdCreated,
                causes: [state.lastHouseholdEventID],
                payload: householdPayload(
                    householdID: householdID, ordinal: ordinal,
                    settlementID: population.settlement.settlementID,
                    agentID: nil, anchor: group.anchor,
                    householdCount: state.households.count + 1,
                    membershipCount: state.membershipPeriods.count,
                    reason: .initialization, status: "created", digest: digest
                ),
                summary: "household created id=\(householdID.rawValue) reason=initialization"
            )
            var record = AgentHouseholdRecord(
                householdID: householdID, ordinal: ordinal,
                settlementID: population.settlement.settlementID,
                residenceAnchor: group.anchor, createdTick: tick,
                createdEventID: created.eventID, status: .active,
                dissolvedTick: nil, lastHouseholdEventID: created.eventID
            )
            state.households.append(record)
            state.totalHistoricalHouseholdCount += 1
            state.nextHouseholdOrdinal = AgentHouseholdOrdinal(
                rawValue: ordinal.rawValue + 1
            )!
            state.lastHouseholdEventID = created.eventID
            for agentID in group.ids {
                let joined = try requiredHouseholdEvent(
                    kind: .householdMembershipStarted,
                    actorID: agentID, subjectID: agentID,
                    causes: [created.eventID],
                    payload: householdPayload(
                        householdID: householdID, ordinal: ordinal,
                        settlementID: population.settlement.settlementID,
                        agentID: agentID, anchor: group.anchor,
                        householdCount: state.households.count,
                        membershipCount: state.membershipPeriods.count + 1,
                        reason: .initialization, status: "membershipStarted", digest: digest
                    ),
                    summary: "household membership started agent=\(agentID.rawValue) household=\(householdID.rawValue)"
                )
                state.membershipPeriods.append(AgentHouseholdMembershipPeriod(
                    agentID: agentID, householdID: householdID,
                    joinedTick: tick, joinedEventID: joined.eventID,
                    joinedReason: .initialization,
                    leftTick: nil, leftEventID: nil, leftReason: nil
                ))
                state.totalMembershipPeriodCount += 1
                state.lastHouseholdEventID = joined.eventID
                record.lastHouseholdEventID = joined.eventID
            }
            state.households[state.households.count - 1] = record
        }
        state.households.sort(by: householdRecordSort)
        state.membershipPeriods.sort(by: householdPeriodSort)
        householdState = state
        try validateHouseholdCrossDomainIfEnabled()
    }

    private mutating func formHouseholdInPlace(
        memberIDs: [AgentID],
        residenceAnchor: AgentPosition,
        joinedReason: AgentHouseholdMembershipReason
    ) throws -> AgentHouseholdRecord {
        guard var state = householdState else {
            throw AgentSessionError.household(.kinshipRequired)
        }
        let members = try prevalidatedHouseholdMembers(memberIDs, state: state)
        guard state.households.count < state.configuration.maximumHistoricalHouseholds else {
            throw AgentSessionError.household(.householdCapacityReached)
        }
        guard members.count <= state.configuration.maximumMembersPerHousehold else {
            throw AgentSessionError.household(.memberCapacityReached(
                AgentHouseholdID(rawValue: "household_\(state.nextHouseholdOrdinal.rawValue)")!
            ))
        }
        guard state.membershipPeriods.count + members.count
                <= state.configuration.maximumMembershipPeriods else {
            throw AgentSessionError.household(.membershipPeriodCapacityReached)
        }
        try prevalidateHouseholdTransitionCount(members.count, state: &state)
        let sourceIDs = Set(members.compactMap { currentHouseholdID(for: $0, in: state) })
        let moving = Set(members)
        let dissolvedSourceIDs = sourceIDs.filter { sourceID in
            currentMemberIDs(of: sourceID, in: state).allSatisfy(moving.contains)
        }.sorted()
        let activeCount = state.households.filter { $0.status == .active }.count
            + 1 - dissolvedSourceIDs.count
        guard activeCount <= state.configuration.maximumActiveHouseholds else {
            throw AgentSessionError.household(.activeHouseholdCapacityReached)
        }
        guard state.nextHouseholdOrdinal.rawValue < Int.max,
              let next = AgentHouseholdOrdinal(
                rawValue: state.nextHouseholdOrdinal.rawValue + 1
              ), let householdID = AgentHouseholdID(
                rawValue: "household_\(state.nextHouseholdOrdinal.rawValue)"
              ) else { throw AgentSessionError.household(.ordinalOverflow) }
        let eventCount = 1 + members.count * 2 + dissolvedSourceIDs.count
        try prevalidateCausalAppend(count: eventCount)
        let priorLast = state.lastHouseholdEventID
        let created = try requiredHouseholdEvent(
            kind: .householdCreated,
            causes: [priorLast],
            payload: householdPayload(
                householdID: householdID, ordinal: state.nextHouseholdOrdinal,
                settlementID: populationRegistry!.settlement.settlementID,
                agentID: nil, anchor: residenceAnchor,
                householdCount: state.households.count + 1,
                membershipCount: state.membershipPeriods.count,
                reason: joinedReason, status: "created", digest: state.rollingDigest
            ),
            summary: "household created id=\(householdID.rawValue) reason=\(joinedReason.rawValue)"
        )
        var newRecord = AgentHouseholdRecord(
            householdID: householdID, ordinal: state.nextHouseholdOrdinal,
            settlementID: populationRegistry!.settlement.settlementID,
            residenceAnchor: residenceAnchor, createdTick: tick,
            createdEventID: created.eventID, status: .active,
            dissolvedTick: nil, lastHouseholdEventID: created.eventID
        )
        state.households.append(newRecord)
        state.nextHouseholdOrdinal = next
        state.totalHistoricalHouseholdCount += 1
        state.lastHouseholdEventID = created.eventID
        var endedBySource: [AgentHouseholdID: [AgentCausalEventID]] = [:]
        for agentID in members {
            let priorIndex = state.membershipPeriods.firstIndex {
                $0.agentID == agentID && $0.leftTick == nil
            }!
            let prior = state.membershipPeriods[priorIndex]
            let ended = try requiredHouseholdEvent(
                kind: .householdMembershipEnded,
                actorID: agentID, subjectID: agentID,
                causes: [created.eventID, prior.joinedEventID].sorted(),
                payload: householdPayload(
                    householdID: prior.householdID,
                    ordinal: state.households.first {
                        $0.householdID == prior.householdID
                    }!.ordinal,
                    settlementID: populationRegistry!.settlement.settlementID,
                    agentID: agentID,
                    anchor: state.households.first {
                        $0.householdID == prior.householdID
                    }!.residenceAnchor,
                    householdCount: state.households.count,
                    membershipCount: state.membershipPeriods.count,
                    reason: .leftForNewHousehold, status: "membershipEnded",
                    digest: state.rollingDigest
                ),
                summary: "household membership ended agent=\(agentID.rawValue) household=\(prior.householdID.rawValue)"
            )
            state.membershipPeriods[priorIndex].leftTick = tick
            state.membershipPeriods[priorIndex].leftEventID = ended.eventID
            state.membershipPeriods[priorIndex].leftReason = .leftForNewHousehold
            if let sourceIndex = state.households.firstIndex(where: {
                $0.householdID == prior.householdID
            }) {
                state.households[sourceIndex].lastHouseholdEventID = ended.eventID
            }
            endedBySource[prior.householdID, default: []].append(ended.eventID)
            let joined = try requiredHouseholdEvent(
                kind: .householdMembershipStarted,
                actorID: agentID, subjectID: agentID,
                causes: [created.eventID, ended.eventID].sorted(),
                payload: householdPayload(
                    householdID: householdID, ordinal: newRecord.ordinal,
                    settlementID: newRecord.settlementID, agentID: agentID,
                    anchor: residenceAnchor,
                    householdCount: state.households.count,
                    membershipCount: state.membershipPeriods.count + 1,
                    reason: joinedReason, status: "membershipStarted",
                    digest: state.rollingDigest
                ),
                summary: "household membership started agent=\(agentID.rawValue) household=\(householdID.rawValue)"
            )
            state.membershipPeriods.append(AgentHouseholdMembershipPeriod(
                agentID: agentID, householdID: householdID,
                joinedTick: tick, joinedEventID: joined.eventID,
                joinedReason: joinedReason,
                leftTick: nil, leftEventID: nil, leftReason: nil
            ))
            state.totalMembershipPeriodCount += 1
            newRecord.lastHouseholdEventID = joined.eventID
            state.lastHouseholdEventID = joined.eventID
            var agent = statesById[agentID.rawValue]!
            agent.homePosition = residenceAnchor
            agent.navigationProgress = AgentNavigationProgress()
            statesById[agentID.rawValue] = agent
        }
        state.households[state.households.firstIndex {
            $0.householdID == householdID
        }!] = newRecord
        for sourceID in dissolvedSourceIDs {
            try dissolveHouseholdInPlace(
                sourceID, causeEventIDs: endedBySource[sourceID] ?? [], state: &state
            )
        }
        state.transitionsAtTick += members.count
        state.rollingDigest = AgentHouseholdDigest.make(
            "\(state.rollingDigest)|form|\(householdID.rawValue)|"
                + members.map(\.rawValue).joined(separator: ",")
                + "|\(householdPositionText(residenceAnchor))|\(tick)"
        )
        state.households.sort(by: householdRecordSort)
        state.membershipPeriods.sort(by: householdPeriodSort)
        householdState = state
        return newRecord
    }

    mutating func moveMembersInPlace(
        memberIDs: [AgentID],
        to householdID: AgentHouseholdID
    ) throws {
        guard var state = householdState else {
            throw AgentSessionError.household(.kinshipRequired)
        }
        let members = try prevalidatedHouseholdMembers(memberIDs, state: state)
        guard let targetIndex = state.households.firstIndex(where: {
            $0.householdID == householdID
        }) else { throw AgentSessionError.household(.unknownHousehold(householdID)) }
        guard state.households[targetIndex].status == .active else {
            throw AgentSessionError.household(.dissolvedHousehold(householdID))
        }
        guard members.allSatisfy({ currentHouseholdID(for: $0, in: state) != householdID }) else {
            throw AgentSessionError.household(.noOp)
        }
        let existing = currentMemberIDs(of: householdID, in: state).count
        guard existing + members.count <= state.configuration.maximumMembersPerHousehold else {
            throw AgentSessionError.household(.memberCapacityReached(householdID))
        }
        guard state.membershipPeriods.count + members.count
                <= state.configuration.maximumMembershipPeriods else {
            throw AgentSessionError.household(.membershipPeriodCapacityReached)
        }
        try prevalidateHouseholdTransitionCount(members.count, state: &state)
        let moving = Set(members)
        let sourceIDs = Set(members.compactMap { currentHouseholdID(for: $0, in: state) })
        let dissolvedSourceIDs = sourceIDs.filter { sourceID in
            sourceID != householdID
                && currentMemberIDs(of: sourceID, in: state).allSatisfy(moving.contains)
        }.sorted()
        try prevalidateCausalAppend(
            count: members.count * 2 + dissolvedSourceIDs.count
        )
        let target = state.households[targetIndex]
        var endedBySource: [AgentHouseholdID: [AgentCausalEventID]] = [:]
        var lastTargetEvent = target.lastHouseholdEventID
        for agentID in members {
            let priorIndex = state.membershipPeriods.firstIndex {
                $0.agentID == agentID && $0.leftTick == nil
            }!
            let prior = state.membershipPeriods[priorIndex]
            let source = state.households.first { $0.householdID == prior.householdID }!
            let ended = try requiredHouseholdEvent(
                kind: .householdMembershipEnded,
                actorID: agentID, subjectID: agentID,
                causes: [prior.joinedEventID, target.lastHouseholdEventID].sorted(),
                payload: householdPayload(
                    householdID: source.householdID, ordinal: source.ordinal,
                    settlementID: source.settlementID, agentID: agentID,
                    anchor: source.residenceAnchor,
                    householdCount: state.households.count,
                    membershipCount: state.membershipPeriods.count,
                    reason: .leftForNewHousehold, status: "membershipEnded",
                    digest: state.rollingDigest
                ),
                summary: "household membership ended agent=\(agentID.rawValue) household=\(source.householdID.rawValue)"
            )
            state.membershipPeriods[priorIndex].leftTick = tick
            state.membershipPeriods[priorIndex].leftEventID = ended.eventID
            state.membershipPeriods[priorIndex].leftReason = .leftForNewHousehold
            if let sourceIndex = state.households.firstIndex(where: {
                $0.householdID == source.householdID
            }) {
                state.households[sourceIndex].lastHouseholdEventID = ended.eventID
            }
            endedBySource[source.householdID, default: []].append(ended.eventID)
            let joined = try requiredHouseholdEvent(
                kind: .householdMembershipStarted,
                actorID: agentID, subjectID: agentID,
                causes: [ended.eventID, lastTargetEvent].sorted(),
                payload: householdPayload(
                    householdID: target.householdID, ordinal: target.ordinal,
                    settlementID: target.settlementID, agentID: agentID,
                    anchor: target.residenceAnchor,
                    householdCount: state.households.count,
                    membershipCount: state.membershipPeriods.count + 1,
                    reason: .joinedHousehold, status: "membershipStarted",
                    digest: state.rollingDigest
                ),
                summary: "household membership started agent=\(agentID.rawValue) household=\(target.householdID.rawValue)"
            )
            state.membershipPeriods.append(AgentHouseholdMembershipPeriod(
                agentID: agentID, householdID: target.householdID,
                joinedTick: tick, joinedEventID: joined.eventID,
                joinedReason: .joinedHousehold,
                leftTick: nil, leftEventID: nil, leftReason: nil
            ))
            state.totalMembershipPeriodCount += 1
            lastTargetEvent = joined.eventID
            state.lastHouseholdEventID = joined.eventID
            var agent = statesById[agentID.rawValue]!
            agent.homePosition = target.residenceAnchor
            agent.navigationProgress = AgentNavigationProgress()
            statesById[agentID.rawValue] = agent
        }
        state.households[targetIndex].lastHouseholdEventID = lastTargetEvent
        for sourceID in dissolvedSourceIDs {
            try dissolveHouseholdInPlace(
                sourceID, causeEventIDs: endedBySource[sourceID] ?? [], state: &state
            )
        }
        state.transitionsAtTick += members.count
        state.rollingDigest = AgentHouseholdDigest.make(
            "\(state.rollingDigest)|move|\(householdID.rawValue)|"
                + members.map(\.rawValue).joined(separator: ",") + "|\(tick)"
        )
        state.households.sort(by: householdRecordSort)
        state.membershipPeriods.sort(by: householdPeriodSort)
        householdState = state
    }

    private func prevalidatedHouseholdMembers(
        _ memberIDs: [AgentID],
        state: AgentHouseholdState
    ) throws -> [AgentID] {
        guard !memberIDs.isEmpty else {
            throw AgentSessionError.household(.emptyMemberList)
        }
        let members = memberIDs.sorted()
        guard Set(members).count == members.count else {
            let duplicate = members.first { id in memberIDs.filter { $0 == id }.count > 1 }!
            throw AgentSessionError.household(.duplicateMember(duplicate))
        }
        guard let population = populationRegistry else {
            throw AgentSessionError.household(.populationRequired)
        }
        for agentID in members {
            guard statesById[agentID.rawValue] != nil,
                  population.members.contains(where: {
                      $0.agentID == agentID
                          && ($0.status == .founderResident || $0.status == .resident)
                  }) else {
                throw AgentSessionError.household(.invalidResident(agentID))
            }
            guard state.membershipPeriods.contains(where: {
                $0.agentID == agentID && $0.leftTick == nil
            }) else {
                throw AgentSessionError.household(.invalidMembership(agentID))
            }
        }
        return members
    }

    private func prevalidateHouseholdTransitionCount(
        _ count: Int,
        at transitionTick: Int? = nil,
        state: inout AgentHouseholdState
    ) throws {
        let effectiveTick = transitionTick ?? tick
        if state.transitionTick != effectiveTick {
            state.transitionTick = effectiveTick
            state.transitionsAtTick = 0
        }
        guard count >= 0, state.transitionsAtTick + count
                <= state.configuration.maximumHouseholdTransitionsPerTick else {
            throw AgentSessionError.household(.transitionCapacityReached)
        }
    }

    private mutating func dissolveHouseholdInPlace(
        _ householdID: AgentHouseholdID,
        causeEventIDs: [AgentCausalEventID],
        at transitionTick: Int? = nil,
        state: inout AgentHouseholdState
    ) throws {
        guard let index = state.households.firstIndex(where: {
            $0.householdID == householdID
        }), state.households[index].status == .active else {
            throw AgentSessionError.household(.dissolvedHousehold(householdID))
        }
        guard currentMemberIDs(of: householdID, in: state).isEmpty else {
            throw AgentSessionError.household(.invalidState("dissolve non-empty household"))
        }
        let record = state.households[index]
        let effectiveTick = transitionTick ?? tick
        let event = try requiredHouseholdEvent(
            kind: .householdDissolved,
            causes: causeEventIDs.sorted(),
            payload: householdPayload(
                householdID: householdID, ordinal: record.ordinal,
                settlementID: record.settlementID, agentID: nil,
                anchor: record.residenceAnchor,
                householdCount: state.households.count,
                membershipCount: state.membershipPeriods.count,
                reason: .householdDissolution, status: "dissolved",
                digest: state.rollingDigest
            ),
            summary: "household dissolved id=\(householdID.rawValue)",
            instant: AgentSimulationInstant(
                simulationID: simulationID,
                tick: AgentSimulationTick(rawValue: effectiveTick)!
            )
        )
        state.households[index].status = .dissolved
        state.households[index].dissolvedTick = effectiveTick
        state.households[index].lastHouseholdEventID = event.eventID
        state.lastHouseholdEventID = event.eventID
    }

    func householdBirthEventCount(
        parentIDs: [AgentID],
        preferredHouseholdID: AgentHouseholdID? = nil
    ) throws -> Int {
        guard let state = householdState else { return 0 }
        guard parentIDs.count == 2,
              let first = currentHouseholdID(for: parentIDs[0], in: state),
              let second = currentHouseholdID(for: parentIDs[1], in: state) else {
            throw AgentSessionError.household(.invalidMembership(
                parentIDs.first ?? AgentID(rawValue: "agent_0")!
            ))
        }
        guard state.membershipPeriods.count < state.configuration.maximumMembershipPeriods else {
            throw AgentSessionError.household(.membershipPeriodCapacityReached)
        }
        var preview = state
        try prevalidateHouseholdTransitionCount(1, state: &preview)
        if first == second || preferredHouseholdID != nil {
            let targetID = preferredHouseholdID ?? first
            guard state.households.contains(where: {
                $0.householdID == targetID && $0.status == .active
            }) else {
                throw AgentSessionError.household(.unknownHousehold(targetID))
            }
            guard currentMemberIDs(of: targetID, in: state).count
                    < state.configuration.maximumMembersPerHousehold else {
                throw AgentSessionError.household(.memberCapacityReached(targetID))
            }
            return 1
        }
        try prevalidateNewHouseholdCapacity(state)
        return 2
    }

    mutating func registerHouseholdBirth(
        childID: AgentID,
        parentIDs: [AgentID],
        residenceAnchor: AgentPosition,
        causeEventID: AgentCausalEventID,
        preferredHouseholdID: AgentHouseholdID? = nil
    ) throws -> AgentCausalEventID? {
        guard var state = householdState else { return nil }
        _ = try householdBirthEventCount(
            parentIDs: parentIDs, preferredHouseholdID: preferredHouseholdID
        )
        let first = currentHouseholdID(for: parentIDs[0], in: state)!
        let second = currentHouseholdID(for: parentIDs[1], in: state)!
        let target: AgentHouseholdRecord
        if let preferredHouseholdID {
            target = state.households.first { $0.householdID == preferredHouseholdID }!
        } else if first == second {
            target = state.households.first { $0.householdID == first }!
        } else {
            target = try createRootHouseholdInPlace(
                agentID: childID,
                residenceAnchor: residenceAnchor,
                reason: .birth,
                causeEventID: causeEventID,
                state: &state,
                createMembership: false
            )
        }
        let joined = try startRootMembershipInPlace(
            agentID: childID,
            household: target,
            reason: .birth,
            causeEventIDs: [causeEventID, target.lastHouseholdEventID].sorted(),
            state: &state
        )
        if state.transitionTick != tick {
            state.transitionTick = tick
            state.transitionsAtTick = 0
        }
        state.transitionsAtTick += 1
        state.rollingDigest = AgentHouseholdDigest.make(
            "\(state.rollingDigest)|birth|\(childID.rawValue)|\(target.householdID.rawValue)|\(tick)"
        )
        state.households.sort(by: householdRecordSort)
        state.membershipPeriods.sort(by: householdPeriodSort)
        householdState = state
        return joined.eventID
    }

    func prevalidateHouseholdMigrationAdmission() throws {
        guard let state = householdState else { return }
        try prevalidateNewHouseholdCapacity(state)
        guard state.membershipPeriods.count < state.configuration.maximumMembershipPeriods else {
            throw AgentSessionError.household(.membershipPeriodCapacityReached)
        }
        var preview = state
        try prevalidateHouseholdTransitionCount(1, state: &preview)
    }

    mutating func registerHouseholdMigrationAdmission(
        agentID: AgentID,
        residenceAnchor: AgentPosition,
        causeEventID: AgentCausalEventID
    ) throws {
        guard var state = householdState else { return }
        try prevalidateHouseholdMigrationAdmission()
        _ = try createRootHouseholdInPlace(
            agentID: agentID,
            residenceAnchor: residenceAnchor,
            reason: .migrationAdmission,
            causeEventID: causeEventID,
            state: &state,
            createMembership: true
        )
        if state.transitionTick != tick {
            state.transitionTick = tick
            state.transitionsAtTick = 0
        }
        state.transitionsAtTick += 1
        state.rollingDigest = AgentHouseholdDigest.make(
            "\(state.rollingDigest)|migration|\(agentID.rawValue)|\(householdPositionText(residenceAnchor))|\(tick)"
        )
        state.households.sort(by: householdRecordSort)
        state.membershipPeriods.sort(by: householdPeriodSort)
        householdState = state
    }

    mutating func registerHouseholdArrivalIfNeeded(
        agentID: AgentID,
        residenceAnchor: AgentPosition,
        causeEventID: AgentCausalEventID
    ) throws {
        guard let state = householdState,
              currentHouseholdID(for: agentID, in: state) == nil else { return }
        try registerHouseholdMigrationAdmission(
            agentID: agentID,
            residenceAnchor: residenceAnchor,
            causeEventID: causeEventID
        )
    }

    func householdDeathEventCount(
        agentIDs: [AgentID],
        at deathTick: Int
    ) throws -> Int {
        guard let state = householdState else { return 0 }
        let ids = agentIDs.sorted()
        for agentID in ids where currentHouseholdID(for: agentID, in: state) == nil {
            throw AgentSessionError.household(.invalidMembership(agentID))
        }
        var preview = state
        try prevalidateHouseholdTransitionCount(ids.count, at: deathTick, state: &preview)
        let dying = Set(ids)
        let sourceIDs = Set(ids.compactMap { currentHouseholdID(for: $0, in: state) })
        let dissolved = sourceIDs.filter { householdID in
            currentMemberIDs(of: householdID, in: state).allSatisfy(dying.contains)
        }.count
        return ids.count + dissolved
    }

    mutating func closeHouseholdMembershipForDeath(
        agentID: AgentID,
        causeEventID: AgentCausalEventID,
        at deathTick: Int
    ) throws -> AgentCausalEventID? {
        guard var state = householdState else { return nil }
        var preview = state
        try prevalidateHouseholdTransitionCount(1, at: deathTick, state: &preview)
        guard let periodIndex = state.membershipPeriods.firstIndex(where: {
            $0.agentID == agentID && $0.leftTick == nil
        }) else { throw AgentSessionError.household(.invalidMembership(agentID)) }
        let period = state.membershipPeriods[periodIndex]
        let householdIndex = state.households.firstIndex {
            $0.householdID == period.householdID
        }!
        let household = state.households[householdIndex]
        let ended = try requiredHouseholdEvent(
            kind: .householdMembershipEnded,
            actorID: agentID, subjectID: agentID,
            causes: [period.joinedEventID, causeEventID].sorted(),
            payload: householdPayload(
                householdID: household.householdID, ordinal: household.ordinal,
                settlementID: household.settlementID, agentID: agentID,
                anchor: household.residenceAnchor,
                householdCount: state.households.count,
                membershipCount: state.membershipPeriods.count,
                reason: .death, status: "membershipEnded", digest: state.rollingDigest
            ),
            summary: "household membership ended death agent=\(agentID.rawValue) household=\(household.householdID.rawValue)",
            instant: AgentSimulationInstant(
                simulationID: simulationID,
                tick: AgentSimulationTick(rawValue: deathTick)!
            )
        )
        state.membershipPeriods[periodIndex].leftTick = deathTick
        state.membershipPeriods[periodIndex].leftEventID = ended.eventID
        state.membershipPeriods[periodIndex].leftReason = .death
        state.households[householdIndex].lastHouseholdEventID = ended.eventID
        state.lastHouseholdEventID = ended.eventID
        var lastEventID = ended.eventID
        if currentMemberIDs(of: household.householdID, in: state).isEmpty {
            try dissolveHouseholdInPlace(
                household.householdID, causeEventIDs: [ended.eventID],
                at: deathTick, state: &state
            )
            lastEventID = state.lastHouseholdEventID
        }
        if state.transitionTick != deathTick {
            state.transitionTick = deathTick
            state.transitionsAtTick = 0
        }
        state.transitionsAtTick += 1
        state.rollingDigest = AgentHouseholdDigest.make(
            "\(state.rollingDigest)|death|\(agentID.rawValue)|\(household.householdID.rawValue)|\(deathTick)"
        )
        state.households.sort(by: householdRecordSort)
        state.membershipPeriods.sort(by: householdPeriodSort)
        householdState = state
        return lastEventID
    }

    private func prevalidateNewHouseholdCapacity(
        _ state: AgentHouseholdState
    ) throws {
        guard state.households.count < state.configuration.maximumHistoricalHouseholds else {
            throw AgentSessionError.household(.householdCapacityReached)
        }
        guard state.households.filter({ $0.status == .active }).count
                < state.configuration.maximumActiveHouseholds else {
            throw AgentSessionError.household(.activeHouseholdCapacityReached)
        }
        guard state.nextHouseholdOrdinal.rawValue < Int.max else {
            throw AgentSessionError.household(.ordinalOverflow)
        }
    }

    private mutating func createRootHouseholdInPlace(
        agentID: AgentID,
        residenceAnchor: AgentPosition,
        reason: AgentHouseholdMembershipReason,
        causeEventID: AgentCausalEventID,
        state: inout AgentHouseholdState,
        createMembership: Bool
    ) throws -> AgentHouseholdRecord {
        try prevalidateNewHouseholdCapacity(state)
        let ordinal = state.nextHouseholdOrdinal
        let householdID = AgentHouseholdID(rawValue: "household_\(ordinal.rawValue)")!
        let created = try requiredHouseholdEvent(
            kind: .householdCreated,
            causes: Array(Set([causeEventID, state.lastHouseholdEventID])).sorted(),
            payload: householdPayload(
                householdID: householdID, ordinal: ordinal,
                settlementID: populationRegistry!.settlement.settlementID,
                agentID: nil, anchor: residenceAnchor,
                householdCount: state.households.count + 1,
                membershipCount: state.membershipPeriods.count,
                reason: reason, status: "created", digest: state.rollingDigest
            ),
            summary: "household created id=\(householdID.rawValue) reason=\(reason.rawValue)"
        )
        var record = AgentHouseholdRecord(
            householdID: householdID, ordinal: ordinal,
            settlementID: populationRegistry!.settlement.settlementID,
            residenceAnchor: residenceAnchor, createdTick: tick,
            createdEventID: created.eventID, status: .active,
            dissolvedTick: nil, lastHouseholdEventID: created.eventID
        )
        state.households.append(record)
        state.nextHouseholdOrdinal = AgentHouseholdOrdinal(rawValue: ordinal.rawValue + 1)!
        state.totalHistoricalHouseholdCount += 1
        state.lastHouseholdEventID = created.eventID
        if createMembership {
            let joined = try startRootMembershipInPlace(
                agentID: agentID, household: record, reason: reason,
                causeEventIDs: [causeEventID, created.eventID].sorted(), state: &state
            )
            record.lastHouseholdEventID = joined.eventID
            state.households[state.households.firstIndex {
                $0.householdID == householdID
            }!] = record
        }
        return record
    }

    private mutating func startRootMembershipInPlace(
        agentID: AgentID,
        household: AgentHouseholdRecord,
        reason: AgentHouseholdMembershipReason,
        causeEventIDs: [AgentCausalEventID],
        state: inout AgentHouseholdState
    ) throws -> AgentCausalEvent {
        guard !state.membershipPeriods.contains(where: {
            $0.agentID == agentID && $0.leftTick == nil
        }) else { throw AgentSessionError.household(.overlappingMembership(agentID)) }
        guard state.membershipPeriods.count < state.configuration.maximumMembershipPeriods else {
            throw AgentSessionError.household(.membershipPeriodCapacityReached)
        }
        let joined = try requiredHouseholdEvent(
            kind: .householdMembershipStarted,
            actorID: agentID, subjectID: agentID,
            causes: Array(Set(causeEventIDs)).sorted(),
            payload: householdPayload(
                householdID: household.householdID, ordinal: household.ordinal,
                settlementID: household.settlementID, agentID: agentID,
                anchor: household.residenceAnchor,
                householdCount: state.households.count,
                membershipCount: state.membershipPeriods.count + 1,
                reason: reason, status: "membershipStarted", digest: state.rollingDigest
            ),
            summary: "household membership started agent=\(agentID.rawValue) household=\(household.householdID.rawValue)"
        )
        state.membershipPeriods.append(AgentHouseholdMembershipPeriod(
            agentID: agentID, householdID: household.householdID,
            joinedTick: tick, joinedEventID: joined.eventID,
            joinedReason: reason, leftTick: nil, leftEventID: nil, leftReason: nil
        ))
        state.totalMembershipPeriodCount += 1
        if let index = state.households.firstIndex(where: {
            $0.householdID == household.householdID
        }) {
            state.households[index].lastHouseholdEventID = joined.eventID
        }
        state.lastHouseholdEventID = joined.eventID
        return joined
    }

    func validateHouseholdCrossDomainIfEnabled() throws {
        guard let household = householdState else { return }
        guard let population = populationRegistry else {
            throw AgentSessionError.household(.populationRequired)
        }
        guard lifecycleState != nil else {
            throw AgentSessionError.household(.lifecycleRequired)
        }
        guard kinshipState != nil else {
            throw AgentSessionError.household(.kinshipRequired)
        }
        do {
            try Self.validateHouseholdState(
                household,
                population: population,
                agents: statesById.values.sorted { $0.agentID < $1.agentID },
                kinship: kinshipState!,
                clock: clock,
                causalLatestSequence: causalLedger.latestSequence,
                causalDroppedEventCount: causalLedger.droppedEventCount,
                causalEvents: causalLedger.events
            )
        } catch let error as AgentHouseholdError {
            throw AgentSessionError.household(error)
        }
    }

    static func validateHouseholdState(
        _ state: AgentHouseholdState,
        population: AgentPopulationRegistry,
        agents: [AgentSessionAgentState],
        kinship: AgentKinshipState,
        clock: AgentSimulationClock,
        causalLatestSequence: UInt64,
        causalDroppedEventCount: UInt64,
        causalEvents: [AgentCausalEvent]
    ) throws {
        _ = try AgentHouseholdConfiguration(
            maximumHistoricalHouseholds: state.configuration.maximumHistoricalHouseholds,
            maximumMembershipPeriods: state.configuration.maximumMembershipPeriods,
            maximumActiveHouseholds: state.configuration.maximumActiveHouseholds,
            maximumMembersPerHousehold: state.configuration.maximumMembersPerHousehold,
            maximumHouseholdTransitionsPerTick: state.configuration.maximumHouseholdTransitionsPerTick
        )
        let householdIDs = state.households.map(\.householdID)
        let ordinals = state.households.map(\.ordinal)
        guard state.households == state.households.sorted(by: householdRecordSort),
              state.membershipPeriods == state.membershipPeriods.sorted(by: householdPeriodSort),
              householdIDs.count == Set(householdIDs).count,
              ordinals.count == Set(ordinals).count,
              state.households.count <= state.configuration.maximumHistoricalHouseholds,
              state.membershipPeriods.count <= state.configuration.maximumMembershipPeriods,
              state.households.filter({ $0.status == .active }).count
                <= state.configuration.maximumActiveHouseholds,
              state.totalHistoricalHouseholdCount == state.households.count,
              state.totalMembershipPeriodCount == state.membershipPeriods.count,
              state.nextHouseholdOrdinal.rawValue > (ordinals.map(\.rawValue).max() ?? -1),
              state.transitionTick >= 0, state.transitionTick <= clock.tick.rawValue,
              state.transitionsAtTick >= 0,
              state.transitionsAtTick <= state.configuration.maximumHouseholdTransitionsPerTick,
              state.initializedEventID.simulationID == clock.simulationID,
              state.lastHouseholdEventID.simulationID == clock.simulationID,
              state.initializedEventID.sequence <= state.lastHouseholdEventID.sequence,
              state.lastHouseholdEventID.sequence.rawValue <= causalLatestSequence,
              !state.rollingDigest.isEmpty else {
            throw AgentHouseholdError.invalidState("bounds, ordering, or counters")
        }
        guard causalDroppedEventCount <= causalLatestSequence,
              UInt64(causalEvents.count) == causalLatestSequence - causalDroppedEventCount,
              causalEvents.enumerated().allSatisfy({ index, event in
                  event.sequence.rawValue == causalDroppedEventCount + UInt64(index) + 1
              }) else {
            throw AgentHouseholdError.invalidCausalReference(state.lastHouseholdEventID)
        }
        let retainedEvent: (AgentCausalEventID) throws -> AgentCausalEvent? = { eventID in
            guard eventID.simulationID == clock.simulationID,
                  eventID.sequence.rawValue <= causalLatestSequence else {
                throw AgentHouseholdError.invalidCausalReference(eventID)
            }
            if let event = causalEvents.first(where: { $0.eventID == eventID }) {
                return event
            }
            guard causalDroppedEventCount > 0,
                  eventID.sequence.rawValue <= causalDroppedEventCount else {
                throw AgentHouseholdError.invalidCausalReference(eventID)
            }
            return nil
        }
        if let initialized = try retainedEvent(state.initializedEventID) {
            guard initialized.kind == .householdsInitialized,
                  initialized.origin == .householdTransition,
                  initialized.actorID == nil, initialized.subjectID == nil,
                  initialized.operationID == nil, initialized.causes.isEmpty,
                  case let .household(
                    householdID, ordinal, settlementID, agentID, anchor,
                    householdCount, membershipCount, reason, status, digest
                  ) = initialized.payload,
                  householdID == nil, ordinal == nil,
                  settlementID == population.settlement.settlementID.rawValue,
                  agentID == nil, anchor == nil,
                  householdCount > 0, householdCount <= state.households.count,
                  membershipCount > 0, membershipCount <= state.membershipPeriods.count,
                  reason == AgentHouseholdMembershipReason.initialization.rawValue,
                  status == "initialized", !digest.isEmpty else {
                throw AgentHouseholdError.invalidCausalReference(state.initializedEventID)
            }
        }
        for record in state.households {
            guard record.householdID.rawValue == "household_\(record.ordinal.rawValue)",
                  record.settlementID == population.settlement.settlementID,
                  record.createdTick >= 0, record.createdTick <= clock.tick.rawValue,
                  record.createdEventID.simulationID == clock.simulationID,
                  record.lastHouseholdEventID.simulationID == clock.simulationID,
                  record.createdEventID.sequence <= record.lastHouseholdEventID.sequence,
                  record.lastHouseholdEventID.sequence.rawValue <= causalLatestSequence else {
                throw AgentHouseholdError.invalidState("household identity or event")
            }
            if let created = try retainedEvent(record.createdEventID) {
                let creationReason = state.membershipPeriods.filter {
                    $0.householdID == record.householdID
                }.min { $0.joinedEventID < $1.joinedEventID }?.joinedReason.rawValue
                guard created.kind == .householdCreated,
                      created.origin == .householdTransition,
                      created.simulationTick.rawValue == record.createdTick,
                      created.actorID == nil, created.subjectID == nil,
                      created.operationID == nil, !created.causes.isEmpty,
                      case let .household(
                        householdID, ordinal, settlementID, agentID, anchor,
                        householdCount, membershipCount, reason, status, digest
                      ) = created.payload,
                      householdID == record.householdID.rawValue,
                      ordinal == record.ordinal.rawValue,
                      settlementID == record.settlementID.rawValue,
                      agentID == nil, anchor == record.residenceAnchor,
                      householdCount > 0, householdCount <= state.households.count,
                      membershipCount >= 0,
                      membershipCount <= state.membershipPeriods.count,
                      reason == creationReason, status == "created", !digest.isEmpty else {
                    throw AgentHouseholdError.invalidCausalReference(record.createdEventID)
                }
            }
            switch record.status {
            case .active:
                guard record.dissolvedTick == nil else {
                    throw AgentHouseholdError.invalidState("active household dissolved")
                }
            case .dissolved:
                guard let dissolvedTick = record.dissolvedTick,
                      dissolvedTick >= record.createdTick,
                      dissolvedTick <= clock.tick.rawValue else {
                    throw AgentHouseholdError.invalidState("invalid dissolution")
                }
            }
        }
        let recordsByID = Dictionary(uniqueKeysWithValues: state.households.map {
            ($0.householdID, $0)
        })
        let knownPeople = Set(kinship.historicalPersons.map(\.agentID))
        var periodsByAgent: [AgentID: [AgentHouseholdMembershipPeriod]] = [:]
        var openByHousehold: [AgentHouseholdID: [AgentID]] = [:]
        for period in state.membershipPeriods {
            guard knownPeople.contains(period.agentID),
                  let record = recordsByID[period.householdID],
                  period.joinedTick >= record.createdTick,
                  period.joinedTick <= clock.tick.rawValue,
                  period.joinedEventID.simulationID == clock.simulationID,
                  period.joinedEventID.sequence.rawValue <= causalLatestSequence else {
                throw AgentHouseholdError.invalidMembership(period.agentID)
            }
            if let joined = try retainedEvent(period.joinedEventID) {
                guard joined.kind == .householdMembershipStarted,
                      joined.origin == .householdTransition,
                      joined.simulationTick.rawValue == period.joinedTick,
                      joined.actorID == period.agentID,
                      joined.subjectID == period.agentID,
                      joined.operationID == nil, !joined.causes.isEmpty,
                      case let .household(
                        householdID, ordinal, settlementID, agentID, anchor,
                        householdCount, membershipCount, reason, status, digest
                      ) = joined.payload,
                      householdID == period.householdID.rawValue,
                      ordinal == record.ordinal.rawValue,
                      settlementID == record.settlementID.rawValue,
                      agentID == period.agentID.rawValue,
                      anchor == record.residenceAnchor,
                      householdCount > 0, householdCount <= state.households.count,
                      membershipCount > 0,
                      membershipCount <= state.membershipPeriods.count,
                      reason == period.joinedReason.rawValue,
                      status == "membershipStarted", !digest.isEmpty else {
                    throw AgentHouseholdError.invalidCausalReference(period.joinedEventID)
                }
            }
            if let leftTick = period.leftTick {
                guard let leftEventID = period.leftEventID,
                      period.leftReason != nil,
                      leftTick >= period.joinedTick,
                      leftTick <= clock.tick.rawValue,
                      leftEventID.simulationID == clock.simulationID,
                      period.joinedEventID.sequence < leftEventID.sequence,
                      leftEventID.sequence.rawValue <= causalLatestSequence else {
                    throw AgentHouseholdError.invalidMembership(period.agentID)
                }
                if let left = try retainedEvent(leftEventID) {
                    guard left.kind == .householdMembershipEnded,
                          left.origin == .householdTransition,
                          left.simulationTick.rawValue == leftTick,
                          left.actorID == period.agentID,
                          left.subjectID == period.agentID,
                          left.operationID == nil,
                          left.causes.contains(period.joinedEventID),
                          case let .household(
                            householdID, ordinal, settlementID, agentID, anchor,
                            householdCount, membershipCount, reason, status, digest
                          ) = left.payload,
                          householdID == period.householdID.rawValue,
                          ordinal == record.ordinal.rawValue,
                          settlementID == record.settlementID.rawValue,
                          agentID == period.agentID.rawValue,
                          anchor == record.residenceAnchor,
                          householdCount > 0, householdCount <= state.households.count,
                          membershipCount > 0,
                          membershipCount <= state.membershipPeriods.count,
                          reason == period.leftReason?.rawValue,
                          status == "membershipEnded", !digest.isEmpty else {
                        throw AgentHouseholdError.invalidCausalReference(leftEventID)
                    }
                }
            } else {
                guard period.leftEventID == nil, period.leftReason == nil,
                      record.status == .active else {
                    throw AgentHouseholdError.invalidMembership(period.agentID)
                }
                openByHousehold[period.householdID, default: []].append(period.agentID)
            }
            periodsByAgent[period.agentID, default: []].append(period)
        }
        for (agentID, periods) in periodsByAgent {
            let ordered = periods.sorted {
                if $0.joinedTick != $1.joinedTick { return $0.joinedTick < $1.joinedTick }
                return $0.joinedEventID < $1.joinedEventID
            }
            guard ordered.filter({ $0.leftTick == nil }).count <= 1 else {
                throw AgentHouseholdError.overlappingMembership(agentID)
            }
            for pair in zip(ordered, ordered.dropFirst()) {
                guard let leftTick = pair.0.leftTick, leftTick <= pair.1.joinedTick,
                      leftTick != pair.1.joinedTick
                        || pair.0.leftEventID!.sequence < pair.1.joinedEventID.sequence else {
                    throw AgentHouseholdError.overlappingMembership(agentID)
                }
            }
        }
        for record in state.households {
            let members = (openByHousehold[record.householdID] ?? []).sorted()
            guard members.count <= state.configuration.maximumMembersPerHousehold else {
                throw AgentHouseholdError.memberCapacityReached(record.householdID)
            }
            if record.status == .active, members.isEmpty {
                throw AgentHouseholdError.invalidState("active household empty")
            }
            if record.status == .dissolved, !members.isEmpty {
                throw AgentHouseholdError.invalidState("dissolved household has member")
            }
            if record.status == .dissolved,
               let event = try retainedEvent(record.lastHouseholdEventID) {
                guard event.kind == .householdDissolved,
                      event.origin == .householdTransition,
                      event.simulationTick.rawValue == record.dissolvedTick,
                      event.actorID == nil, event.subjectID == nil,
                      event.operationID == nil, !event.causes.isEmpty,
                      case let .household(
                        householdID, ordinal, settlementID, agentID, anchor,
                        householdCount, membershipCount, reason, status, digest
                      ) = event.payload,
                      householdID == record.householdID.rawValue,
                      ordinal == record.ordinal.rawValue,
                      settlementID == record.settlementID.rawValue,
                      agentID == nil, anchor == record.residenceAnchor,
                      householdCount > 0, householdCount <= state.households.count,
                      membershipCount > 0,
                      membershipCount <= state.membershipPeriods.count,
                      reason == AgentHouseholdMembershipReason.householdDissolution.rawValue,
                      status == "dissolved", !digest.isEmpty else {
                    throw AgentHouseholdError.invalidCausalReference(record.lastHouseholdEventID)
                }
            }
        }
        let agentsByID = Dictionary(uniqueKeysWithValues: agents.map { ($0.agentID, $0) })
        let membersByID = Dictionary(uniqueKeysWithValues: population.members.map {
            ($0.agentID, $0)
        })
        for member in population.members {
            let open = periodsByAgent[member.agentID]?.first { $0.leftTick == nil }
            let resident = member.status == .founderResident || member.status == .resident
            let admittedAfterActivation = member.status == .migrating
                && member.registrationEventID.sequence > state.initializedEventID.sequence
            if resident || admittedAfterActivation {
                guard let open, let household = recordsByID[open.householdID],
                      let agent = agentsByID[member.agentID],
                      agent.homePosition == household.residenceAnchor else {
                    throw AgentHouseholdError.projectionMismatch(member.agentID)
                }
            } else if let open, let household = recordsByID[open.householdID],
                      agentsByID[member.agentID]?.homePosition != household.residenceAnchor {
                throw AgentHouseholdError.projectionMismatch(member.agentID)
            }
        }
        for (agentID, periods) in periodsByAgent where periods.contains(where: {
            $0.leftTick == nil
        }) {
            guard membersByID[agentID] != nil, agentsByID[agentID] != nil else {
                throw AgentHouseholdError.invalidMembership(agentID)
            }
        }
        let knownEventIDs = Set(
            [state.initializedEventID]
                + state.households.flatMap { [$0.createdEventID, $0.lastHouseholdEventID] }
                + state.membershipPeriods.flatMap {
                    [$0.joinedEventID] + ($0.leftEventID.map { [$0] } ?? [])
                }
        )
        guard knownEventIDs.contains(state.lastHouseholdEventID) else {
            throw AgentHouseholdError.invalidCausalReference(state.lastHouseholdEventID)
        }
        _ = try retainedEvent(state.lastHouseholdEventID)
        guard !causalEvents.contains(where: {
            [.householdsInitialized, .householdCreated, .householdMembershipStarted,
             .householdMembershipEnded, .householdDissolved].contains($0.kind)
                && $0.sequence > state.lastHouseholdEventID.sequence
        }) else {
            throw AgentHouseholdError.invalidCausalReference(state.lastHouseholdEventID)
        }
    }

    private func currentHouseholdID(
        for agentID: AgentID,
        in state: AgentHouseholdState
    ) -> AgentHouseholdID? {
        state.membershipPeriods.first {
            $0.agentID == agentID && $0.leftTick == nil
        }?.householdID
    }

    private func currentMemberIDs(
        of householdID: AgentHouseholdID,
        in state: AgentHouseholdState
    ) -> [AgentID] {
        state.membershipPeriods.compactMap {
            $0.householdID == householdID && $0.leftTick == nil ? $0.agentID : nil
        }.sorted()
    }

    private func householdDigest(_ state: AgentHouseholdState) -> String {
        AgentHouseholdDigest.make([
            "bounds=\(state.configuration.maximumHistoricalHouseholds),\(state.configuration.maximumMembershipPeriods),\(state.configuration.maximumActiveHouseholds),\(state.configuration.maximumMembersPerHousehold),\(state.configuration.maximumHouseholdTransitionsPerTick)",
            state.households.sorted(by: householdRecordSort).map {
                "h|\($0.householdID.rawValue)|\($0.ordinal.rawValue)|\($0.settlementID.rawValue)|\(householdPositionText($0.residenceAnchor))|\($0.createdTick)|\($0.status.rawValue)|\($0.dissolvedTick.map(String.init) ?? "none")|\($0.createdEventID.rawValue)|\($0.lastHouseholdEventID.rawValue)"
            }.joined(separator: ";"),
            state.membershipPeriods.sorted(by: householdPeriodSort).map {
                "m|\($0.agentID.rawValue)|\($0.householdID.rawValue)|\($0.joinedTick)|\($0.joinedReason.rawValue)|\($0.leftTick.map(String.init) ?? "none")|\($0.leftReason?.rawValue ?? "none")|\($0.joinedEventID.rawValue)|\($0.leftEventID?.rawValue ?? "none")"
            }.joined(separator: ";"),
            "next=\(state.nextHouseholdOrdinal.rawValue)",
            "total=\(state.totalHistoricalHouseholdCount),\(state.totalMembershipPeriodCount)",
            "transition=\(state.transitionTick),\(state.transitionsAtTick)",
            "rolling=\(state.rollingDigest)",
        ].joined(separator: "|"))
    }

    private func householdPayload(
        householdID: AgentHouseholdID?,
        ordinal: AgentHouseholdOrdinal?,
        settlementID: AgentSettlementID?,
        agentID: AgentID?,
        anchor: AgentPosition?,
        householdCount: Int,
        membershipCount: Int,
        reason: AgentHouseholdMembershipReason?,
        status: String,
        digest: String
    ) -> AgentCausalPayload {
        .household(
            householdID: householdID?.rawValue,
            ordinal: ordinal?.rawValue,
            settlementID: settlementID?.rawValue,
            agentID: agentID?.rawValue,
            residenceAnchor: anchor,
            householdCount: householdCount,
            membershipCount: membershipCount,
            reason: reason?.rawValue,
            status: status,
            digest: digest
        )
    }

    @discardableResult
    private mutating func requiredHouseholdEvent(
        kind: AgentCausalEventKind,
        actorID: AgentID? = nil,
        subjectID: AgentID? = nil,
        causes: [AgentCausalEventID] = [],
        payload: AgentCausalPayload,
        summary: String,
        instant: AgentSimulationInstant? = nil
    ) throws -> AgentCausalEvent {
        guard let event = try causalLedger.append(
            instant: instant ?? simulationInstant,
            kind: kind,
            origin: .householdTransition,
            actorID: actorID,
            subjectID: subjectID,
            causes: causes.sorted(),
            payload: payload,
            summary: summary
        ) else { throw AgentSessionError.household(.causalLedgerRequired) }
        return event
    }
}

private func householdPositionLess(_ lhs: AgentPosition, _ rhs: AgentPosition) -> Bool {
    if lhs.x != rhs.x { return lhs.x < rhs.x }
    if lhs.y != rhs.y { return lhs.y < rhs.y }
    return lhs.z < rhs.z
}

private func householdPositionText(_ value: AgentPosition) -> String {
    "\(value.x),\(value.y),\(value.z)"
}

private func householdRecordSort(
    _ lhs: AgentHouseholdRecord,
    _ rhs: AgentHouseholdRecord
) -> Bool {
    lhs.ordinal < rhs.ordinal
}

private func householdPeriodSort(
    _ lhs: AgentHouseholdMembershipPeriod,
    _ rhs: AgentHouseholdMembershipPeriod
) -> Bool {
    if lhs.agentID != rhs.agentID { return lhs.agentID < rhs.agentID }
    if lhs.joinedTick != rhs.joinedTick { return lhs.joinedTick < rhs.joinedTick }
    if lhs.householdID != rhs.householdID { return lhs.householdID < rhs.householdID }
    return lhs.joinedEventID < rhs.joinedEventID
}
