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
        try candidate.validateHouseholdCrossDomainIfEnabled()
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
        try candidate.validateHouseholdCrossDomainIfEnabled()
        self = candidate
        return record
    }

    public mutating func moveMembers(
        memberIDs: [AgentID],
        to householdID: AgentHouseholdID
    ) throws {
        var candidate = self
        try candidate.moveMembersInPlace(memberIDs: memberIDs, to: householdID)
        try candidate.validateHouseholdCrossDomainIfEnabled()
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

    private mutating func moveMembersInPlace(
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
        state: inout AgentHouseholdState
    ) throws {
        if state.transitionTick != tick {
            state.transitionTick = tick
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
            summary: "household dissolved id=\(householdID.rawValue)"
        )
        state.households[index].status = .dissolved
        state.households[index].dissolvedTick = tick
        state.households[index].lastHouseholdEventID = event.eventID
        state.lastHouseholdEventID = event.eventID
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
                clock: clock
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
        clock: AgentSimulationClock
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
              !state.rollingDigest.isEmpty else {
            throw AgentHouseholdError.invalidState("bounds, ordering, or counters")
        }
        for record in state.households {
            guard record.householdID.rawValue == "household_\(record.ordinal.rawValue)",
                  record.settlementID == population.settlement.settlementID,
                  record.createdTick >= 0, record.createdTick <= clock.tick.rawValue,
                  record.createdEventID.simulationID == clock.simulationID,
                  record.lastHouseholdEventID.simulationID == clock.simulationID,
                  record.createdEventID.sequence <= record.lastHouseholdEventID.sequence else {
                throw AgentHouseholdError.invalidState("household identity or event")
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
                  period.joinedEventID.simulationID == clock.simulationID else {
                throw AgentHouseholdError.invalidMembership(period.agentID)
            }
            if let leftTick = period.leftTick {
                guard let leftEventID = period.leftEventID,
                      period.leftReason != nil,
                      leftTick >= period.joinedTick,
                      leftTick <= clock.tick.rawValue,
                      leftEventID.simulationID == clock.simulationID,
                      period.joinedEventID.sequence < leftEventID.sequence else {
                    throw AgentHouseholdError.invalidMembership(period.agentID)
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
            let ordered = periods.sorted(by: householdPeriodSort)
            guard ordered.filter({ $0.leftTick == nil }).count <= 1 else {
                throw AgentHouseholdError.overlappingMembership(agentID)
            }
            for pair in zip(ordered, ordered.dropFirst()) {
                guard let leftTick = pair.0.leftTick, leftTick <= pair.1.joinedTick else {
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
        summary: String
    ) throws -> AgentCausalEvent {
        guard let event = try causalLedger.append(
            instant: simulationInstant,
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
