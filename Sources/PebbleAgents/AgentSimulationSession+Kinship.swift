extension AgentSimulationSession {
    public var kinshipEnabled: Bool { kinshipState != nil }

    public func kinshipSnapshot() -> AgentKinshipSnapshot {
        guard let kinship = kinshipState else {
            return AgentKinshipSnapshot(
                enabled: false,
                configuration: nil,
                historicalPersons: [],
                parentageRecords: [],
                totalHistoricalPersonCount: 0,
                totalParentageRecordCount: 0,
                digest: AgentKinshipDigest.make("disabled")
            )
        }
        let persons = kinship.historicalPersons.sorted { $0.agentID < $1.agentID }
        let parentages = kinship.parentageRecords.sorted { $0.childID < $1.childID }
        return AgentKinshipSnapshot(
            enabled: true,
            configuration: kinship.configuration,
            historicalPersons: persons,
            parentageRecords: parentages,
            totalHistoricalPersonCount: kinship.totalHistoricalPersonCount,
            totalParentageRecordCount: kinship.totalParentageRecordCount,
            digest: kinshipDigest(
                configuration: kinship.configuration,
                persons: persons,
                parentages: parentages,
                rollingDigest: kinship.rollingDigest
            )
        )
    }

    public func historicalPerson(for agentID: AgentID) -> AgentHistoricalPerson? {
        kinshipState?.historicalPersons.first { $0.agentID == agentID }
    }

    public func parents(of childID: AgentID) throws -> [AgentID]? {
        guard let kinship = kinshipState,
              kinship.historicalPersons.contains(where: { $0.agentID == childID }) else {
            throw AgentSessionError.kinship(.unknownPerson(childID))
        }
        return kinship.parentageRecords.first { $0.childID == childID }?.canonicalParentIDs
    }

    public func children(of parentID: AgentID) throws -> [AgentID] {
        guard let kinship = kinshipState,
              kinship.historicalPersons.contains(where: { $0.agentID == parentID }) else {
            throw AgentSessionError.kinship(.unknownPerson(parentID))
        }
        return kinship.parentageRecords.compactMap {
            $0.canonicalParentIDs.contains(parentID) ? $0.childID : nil
        }.sorted()
    }

    public func siblingRelation(
        between lhs: AgentID,
        and rhs: AgentID
    ) -> AgentSiblingRelation {
        guard let kinship = kinshipState else { return .unknownPerson(lhs) }
        let known = Set(kinship.historicalPersons.map(\.agentID))
        guard known.contains(lhs) else { return .unknownPerson(lhs) }
        guard known.contains(rhs) else { return .unknownPerson(rhs) }
        guard lhs != rhs else { return .samePerson }
        guard let left = kinship.parentageRecords.first(where: { $0.childID == lhs }) else {
            return .unknownParentage(lhs)
        }
        guard let right = kinship.parentageRecords.first(where: { $0.childID == rhs }) else {
            return .unknownParentage(rhs)
        }
        let shared = Set(left.canonicalParentIDs).intersection(right.canonicalParentIDs).count
        if shared == 2 { return .fullSibling }
        if shared == 1 { return .halfSibling }
        return .unrelated
    }

    public func isAncestor(
        _ possibleAncestorID: AgentID,
        of descendantID: AgentID,
        maximumDepth: Int? = nil
    ) -> AgentAncestryResult {
        guard let kinship = kinshipState else { return .unknownPerson(possibleAncestorID) }
        let known = Set(kinship.historicalPersons.map(\.agentID))
        guard known.contains(possibleAncestorID) else { return .unknownPerson(possibleAncestorID) }
        guard known.contains(descendantID) else { return .unknownPerson(descendantID) }
        guard possibleAncestorID != descendantID else { return .notAncestor }
        let limit = min(maximumDepth ?? kinship.configuration.maximumAncestryDepth,
                        kinship.configuration.maximumAncestryDepth)
        guard limit > 0 else { return .depthLimitReached }
        let parentsByChild = Dictionary(uniqueKeysWithValues: kinship.parentageRecords.map {
            ($0.childID, $0.canonicalParentIDs)
        })
        var frontier = parentsByChild[descendantID] ?? []
        var visited = Set<AgentID>()
        var depth = 1
        while !frontier.isEmpty, depth <= limit {
            let ordered = Array(Set(frontier)).sorted()
            if ordered.contains(possibleAncestorID) { return .ancestor }
            visited.formUnion(ordered)
            frontier = ordered.flatMap { parentsByChild[$0] ?? [] }.filter { !visited.contains($0) }
            depth += 1
        }
        return frontier.isEmpty ? .notAncestor : .depthLimitReached
    }

    public func validateKinshipParentageDraft(
        childID: AgentID,
        ordinal: AgentPopulationOrdinal,
        parentIDs: [AgentID]
    ) throws {
        guard let kinship = kinshipState else {
            throw AgentSessionError.kinship(.lifecycleRequired)
        }
        let canonical = parentIDs.sorted()
        if let existing = kinship.parentageRecords.first(where: { $0.childID == childID }) {
            throw AgentSessionError.kinship(
                existing.canonicalParentIDs == canonical
                    ? .duplicateParentage(childID) : .parentageRewrite(childID)
            )
        }
        guard !kinship.historicalPersons.contains(where: { $0.agentID == childID }) else {
            throw AgentSessionError.kinship(.duplicatePerson(childID))
        }
        guard childID.rawValue == "agent_\(ordinal.rawValue)" else {
            throw AgentSessionError.kinship(.invalidIdentityOrdinal(childID, ordinal))
        }
        guard canonical.count == 2, Set(canonical).count == 2,
              !canonical.contains(childID) else {
            throw AgentSessionError.kinship(.invalidParentage(childID))
        }
        try prevalidateKinshipAdmission(parentIDs: canonical)
    }

    public mutating func setKinshipEnabled(
        _ enabled: Bool,
        configuration: AgentKinshipConfiguration = .live
    ) throws {
        if enabled {
            var candidate = self
            try candidate.initializeKinshipInPlace(configuration: configuration)
            self = candidate
        } else if kinshipState != nil {
            throw AgentSessionError.kinship(.unsafeDisable)
        }
    }

    private mutating func initializeKinshipInPlace(
        configuration: AgentKinshipConfiguration
    ) throws {
        guard causalLedger.isEnabled else {
            throw AgentSessionError.kinship(.causalLedgerRequired)
        }
        guard kinshipState == nil else { throw AgentSessionError.kinship(.alreadyEnabled) }
        guard let population = populationRegistry else {
            throw AgentSessionError.kinship(.populationRequired)
        }
        guard let lifecycle = lifecycleState else {
            throw AgentSessionError.kinship(.lifecycleRequired)
        }
        guard lifecycle.totalBirthCount == lifecycle.births.count,
              lifecycle.evictionCounts.births == 0 else {
            throw AgentSessionError.kinship(.incompleteBirthHistory)
        }
        let personCount = population.nextPopulationOrdinal.rawValue
        guard personCount <= configuration.maximumHistoricalPersons,
              lifecycle.births.count <= configuration.maximumParentageRecords else {
            throw AgentSessionError.kinship(
                personCount > configuration.maximumHistoricalPersons
                    ? .historicalPersonCapacityReached : .parentageCapacityReached
            )
        }
        let persons = (0..<personCount).map { ordinal -> AgentHistoricalPerson in
            AgentHistoricalPerson(
                agentID: AgentID(rawValue: "agent_\(ordinal)")!,
                ordinal: AgentPopulationOrdinal(rawValue: ordinal)!
            )
        }
        let known = Set(persons.map(\.agentID))
        var allocationEvidence: [AgentPopulationOrdinal: Set<AgentID>] = [:]
        func recordAllocation(_ agentID: AgentID, _ ordinal: AgentPopulationOrdinal) {
            allocationEvidence[ordinal, default: []].insert(agentID)
        }
        population.members.forEach { recordAllocation($0.agentID, $0.ordinal) }
        population.migrations.forEach { recordAllocation($0.migrantID, $0.ordinal) }
        lifecycle.births.forEach { recordAllocation($0.newbornID, $0.ordinal) }
        mortalityState?.records.forEach { recordAllocation($0.agentID, $0.populationOrdinal) }
        let expectedOrdinals = Set((0..<personCount).map {
            AgentPopulationOrdinal(rawValue: $0)!
        })
        guard Set(allocationEvidence.keys) == expectedOrdinals,
              allocationEvidence.allSatisfy({ ordinal, agentIDs in
                  agentIDs == [AgentID(rawValue: "agent_\(ordinal.rawValue)")!]
              }) else {
            throw AgentSessionError.kinship(.incompleteBirthHistory)
        }
        guard population.members.allSatisfy({ member in
            member.agentID.rawValue == "agent_\(member.ordinal.rawValue)"
                && known.contains(member.agentID)
        }), lifecycle.members.allSatisfy({ member in
            member.agentID.rawValue == "agent_\(member.ordinal.rawValue)"
                && known.contains(member.agentID)
        }) else {
            throw AgentSessionError.kinship(.incompleteBirthHistory)
        }
        try prevalidateCausalAppend(count: 1)
        let digest = AgentKinshipDigest.make(
            "initialize|\(persons.map { "\($0.agentID.rawValue):\($0.ordinal.rawValue)" }.joined(separator: ","))|"
                + lifecycle.births.map(\.birthID.rawValue).sorted().joined(separator: ",")
        )
        let initialized = try requiredKinshipEvent(
            kind: .kinshipInitialized,
            payload: .kinship(
                childID: nil, birthID: nil, parentIDs: [],
                personCount: persons.count, parentageCount: lifecycle.births.count,
                digest: digest, status: "initialized"
            ),
            summary: "kinship initialized persons=\(persons.count) parentages=\(lifecycle.births.count)"
        )
        let parentages = lifecycle.births.sorted { $0.newbornID < $1.newbornID }.map {
            AgentParentageRecord(
                childID: $0.newbornID,
                parentIDs: $0.progenitorIDs,
                birthID: $0.birthID,
                birthTick: $0.birthTick,
                sourcePopulationBornEventID: $0.populationBornEventID,
                recordedEventID: initialized.eventID
            )
        }
        var state = AgentKinshipState(
            configuration: configuration,
            historicalPersons: persons,
            parentageRecords: parentages,
            totalHistoricalPersonCount: persons.count,
            totalParentageRecordCount: parentages.count,
            rollingDigest: digest,
            initializedEventID: initialized.eventID,
            lastKinshipEventID: initialized.eventID
        )
        do {
            try Self.validateKinshipState(
                state,
                population: population,
                lifecycle: lifecycle,
                clock: clock,
                causalLatestSequence: causalLedger.latestSequence,
                causalEvents: causalLedger.events
            )
        } catch let error as AgentKinshipError {
            throw AgentSessionError.kinship(error)
        }
        state.historicalPersons.sort { $0.agentID < $1.agentID }
        state.parentageRecords.sort { $0.childID < $1.childID }
        kinshipState = state
    }

    func prevalidateKinshipAdmission(parentIDs: [AgentID]?) throws {
        guard let kinship = kinshipState else { return }
        guard kinship.historicalPersons.count < kinship.configuration.maximumHistoricalPersons else {
            throw AgentSessionError.kinship(.historicalPersonCapacityReached)
        }
        guard let parentIDs else { return }
        let canonicalParents = parentIDs.sorted()
        guard canonicalParents.count == 2, Set(canonicalParents).count == 2 else {
            throw AgentSessionError.kinship(.invalidParentage(canonicalParents.first
                ?? AgentID(rawValue: "invalid")!))
        }
        let known = Set(kinship.historicalPersons.map(\.agentID))
        guard canonicalParents.allSatisfy(known.contains) else {
            throw AgentSessionError.kinship(.unknownPerson(
                canonicalParents.first(where: { !known.contains($0) })!
            ))
        }
        guard kinship.parentageRecords.count < kinship.configuration.maximumParentageRecords else {
            throw AgentSessionError.kinship(.parentageCapacityReached)
        }
        for parentID in canonicalParents where
            kinship.parentageRecords.filter({ $0.canonicalParentIDs.contains(parentID) }).count
                >= kinship.configuration.maximumChildrenPerParent {
            throw AgentSessionError.kinship(.childrenPerParentCapacityReached(parentID))
        }
    }

    mutating func registerKinshipRoot(
        agentID: AgentID,
        ordinal: AgentPopulationOrdinal,
        causeEventID: AgentCausalEventID
    ) throws {
        guard var kinship = kinshipState else { return }
        try prevalidateKinshipAdmission(parentIDs: nil)
        let event = try requiredKinshipEvent(
            kind: .kinshipPersonRegistered,
            subjectID: agentID,
            causes: [causeEventID],
            payload: .kinship(
                childID: agentID.rawValue, birthID: nil, parentIDs: [],
                personCount: kinship.historicalPersons.count + 1,
                parentageCount: kinship.parentageRecords.count,
                digest: kinship.rollingDigest, status: "rootRegistered"
            ),
            summary: "kinship root registered id=\(agentID.rawValue) ordinal=\(ordinal.rawValue)"
        )
        kinship.historicalPersons.append(AgentHistoricalPerson(agentID: agentID, ordinal: ordinal))
        kinship.historicalPersons.sort { $0.agentID < $1.agentID }
        kinship.totalHistoricalPersonCount += 1
        kinship.rollingDigest = AgentKinshipDigest.make(
            "\(kinship.rollingDigest)|root|\(agentID.rawValue)|\(ordinal.rawValue)"
        )
        kinship.lastKinshipEventID = event.eventID
        kinshipState = kinship
    }

    mutating func registerKinshipBirth(
        childID: AgentID,
        ordinal: AgentPopulationOrdinal,
        parentIDs: [AgentID],
        birthID: AgentBirthID,
        birthTick: Int,
        sourcePopulationBornEventID: AgentCausalEventID
    ) throws -> AgentCausalEventID? {
        guard var kinship = kinshipState else { return nil }
        try validateKinshipParentageDraft(
            childID: childID, ordinal: ordinal, parentIDs: parentIDs
        )
        let parents = parentIDs.sorted()
        let event = try requiredKinshipEvent(
            kind: .kinshipParentageRecorded,
            subjectID: childID,
            causes: [sourcePopulationBornEventID],
            payload: .kinship(
                childID: childID.rawValue, birthID: birthID.rawValue,
                parentIDs: parents.map(\.rawValue),
                personCount: kinship.historicalPersons.count + 1,
                parentageCount: kinship.parentageRecords.count + 1,
                digest: kinship.rollingDigest, status: "parentageRecorded"
            ),
            summary: "kinship parentage recorded child=\(childID.rawValue) parents=\(parents.map(\.rawValue).joined(separator: ","))"
        )
        kinship.historicalPersons.append(AgentHistoricalPerson(agentID: childID, ordinal: ordinal))
        kinship.parentageRecords.append(AgentParentageRecord(
            childID: childID,
            parentIDs: parents,
            birthID: birthID,
            birthTick: birthTick,
            sourcePopulationBornEventID: sourcePopulationBornEventID,
            recordedEventID: event.eventID
        ))
        kinship.historicalPersons.sort { $0.agentID < $1.agentID }
        kinship.parentageRecords.sort { $0.childID < $1.childID }
        kinship.totalHistoricalPersonCount += 1
        kinship.totalParentageRecordCount += 1
        kinship.rollingDigest = AgentKinshipDigest.make(
            "\(kinship.rollingDigest)|birth|\(childID.rawValue)|\(parents.map(\.rawValue).joined(separator: ","))|\(birthID.rawValue)|\(birthTick)"
        )
        kinship.lastKinshipEventID = event.eventID
        kinshipState = kinship
        return event.eventID
    }

    static func validateKinshipState(
        _ kinship: AgentKinshipState,
        population: AgentPopulationRegistry,
        lifecycle: AgentLifecycleState,
        clock: AgentSimulationClock,
        causalLatestSequence: UInt64,
        causalEvents: [AgentCausalEvent]
    ) throws {
        _ = try AgentKinshipConfiguration(
            maximumHistoricalPersons: kinship.configuration.maximumHistoricalPersons,
            maximumParentageRecords: kinship.configuration.maximumParentageRecords,
            maximumChildrenPerParent: kinship.configuration.maximumChildrenPerParent,
            maximumAncestryDepth: kinship.configuration.maximumAncestryDepth
        )
        let personIDs = kinship.historicalPersons.map(\.agentID)
        let ordinals = kinship.historicalPersons.map(\.ordinal)
        guard personIDs == personIDs.sorted(), personIDs.count == Set(personIDs).count,
              ordinals.count == Set(ordinals).count,
              kinship.historicalPersons.count <= kinship.configuration.maximumHistoricalPersons,
              kinship.parentageRecords.count <= kinship.configuration.maximumParentageRecords,
              kinship.totalHistoricalPersonCount == kinship.historicalPersons.count,
              kinship.totalParentageRecordCount == kinship.parentageRecords.count,
              kinship.parentageRecords == kinship.parentageRecords.sorted(by: { $0.childID < $1.childID }),
              kinship.initializedEventID.simulationID == clock.simulationID,
              kinship.lastKinshipEventID.simulationID == clock.simulationID,
              kinship.initializedEventID.sequence <= kinship.lastKinshipEventID.sequence,
              kinship.lastKinshipEventID.sequence.rawValue <= causalLatestSequence,
              !kinship.rollingDigest.isEmpty else {
            throw AgentKinshipError.invalidConfiguration("state bounds or ordering")
        }
        for person in kinship.historicalPersons {
            guard person.agentID.rawValue == "agent_\(person.ordinal.rawValue)" else {
                throw AgentKinshipError.invalidIdentityOrdinal(person.agentID, person.ordinal)
            }
        }
        let known = Set(personIDs)
        let childIDs = kinship.parentageRecords.map(\.childID)
        guard childIDs.count == Set(childIDs).count else {
            throw AgentKinshipError.duplicateParentage(childIDs.first!)
        }
        var childrenCounts: [AgentID: Int] = [:]
        for record in kinship.parentageRecords {
            guard known.contains(record.childID), record.canonicalParentIDs.count == 2,
                  record.canonicalParentIDs == record.canonicalParentIDs.sorted(),
                  Set(record.canonicalParentIDs).count == 2,
                  !record.canonicalParentIDs.contains(record.childID),
                  record.canonicalParentIDs.allSatisfy(known.contains),
                  record.birthTick >= 0, record.birthTick <= clock.tick.rawValue,
                  record.sourcePopulationBornEventID.simulationID == clock.simulationID,
                  record.recordedEventID.simulationID == clock.simulationID,
                  record.sourcePopulationBornEventID.sequence < record.recordedEventID.sequence,
                  record.recordedEventID.sequence.rawValue <= causalLatestSequence else {
                throw AgentKinshipError.invalidParentage(record.childID)
            }
            if let source = causalEvents.first(where: {
                $0.eventID == record.sourcePopulationBornEventID
            }), source.kind != .populationMemberBorn || source.subjectID != record.childID {
                throw AgentKinshipError.invalidCausalReference(record.sourcePopulationBornEventID)
            }
            if let recorded = causalEvents.first(where: { $0.eventID == record.recordedEventID }),
               ![AgentCausalEventKind.kinshipInitialized, .kinshipParentageRecorded]
                .contains(recorded.kind) || recorded.kind == .kinshipParentageRecorded
                    && recorded.subjectID != record.childID {
                throw AgentKinshipError.invalidCausalReference(record.recordedEventID)
            }
            for parentID in record.canonicalParentIDs {
                childrenCounts[parentID, default: 0] += 1
                if childrenCounts[parentID, default: 0]
                    > kinship.configuration.maximumChildrenPerParent {
                    throw AgentKinshipError.childrenPerParentCapacityReached(parentID)
                }
            }
        }
        let parentsByChild = Dictionary(uniqueKeysWithValues: kinship.parentageRecords.map {
            ($0.childID, $0.canonicalParentIDs)
        })
        for childID in childIDs {
            var frontier = parentsByChild[childID] ?? []
            var visited: Set<AgentID> = [childID]
            var depth = 0
            while !frontier.isEmpty {
                guard depth < kinship.configuration.maximumAncestryDepth else {
                    throw AgentKinshipError.ancestryDepthLimitReached
                }
                let current = Array(Set(frontier)).sorted()
                guard !current.contains(childID) else {
                    throw AgentKinshipError.ancestryCycle(childID)
                }
                visited.formUnion(current)
                frontier = current.flatMap { parentsByChild[$0] ?? [] }.filter {
                    !visited.contains($0) || $0 == childID
                }
                depth += 1
            }
        }
        guard population.members.allSatisfy({ member in
            kinship.historicalPersons.contains {
                $0.agentID == member.agentID && $0.ordinal == member.ordinal
            }
        }) else { throw AgentKinshipError.incompleteBirthHistory }
        for birth in lifecycle.births {
            guard let record = kinship.parentageRecords.first(where: { $0.childID == birth.newbornID }),
                  record.birthID == birth.birthID,
                  record.birthTick == birth.birthTick,
                  record.canonicalParentIDs == birth.progenitorIDs,
                  record.sourcePopulationBornEventID == birth.populationBornEventID else {
                throw AgentKinshipError.projectionMismatch(birth.newbornID)
            }
        }
        for member in lifecycle.members where member.origin == .localBirth {
            guard let record = kinship.parentageRecords.first(where: { $0.childID == member.agentID }),
                  record.birthID == member.birthID,
                  record.canonicalParentIDs == member.progenitorIDs else {
                throw AgentKinshipError.projectionMismatch(member.agentID)
            }
        }
    }

    func validateKinshipCrossDomainIfEnabled() throws {
        guard let kinship = kinshipState else { return }
        guard let population = populationRegistry else {
            throw AgentSessionError.kinship(.populationRequired)
        }
        guard let lifecycle = lifecycleState else {
            throw AgentSessionError.kinship(.lifecycleRequired)
        }
        do {
            try Self.validateKinshipState(
                kinship,
                population: population,
                lifecycle: lifecycle,
                clock: clock,
                causalLatestSequence: causalLedger.latestSequence,
                causalEvents: causalLedger.events
            )
        } catch let error as AgentKinshipError {
            throw AgentSessionError.kinship(error)
        }
    }

    private func kinshipDigest(
        configuration: AgentKinshipConfiguration,
        persons: [AgentHistoricalPerson],
        parentages: [AgentParentageRecord],
        rollingDigest: String
    ) -> String {
        AgentKinshipDigest.make([
            "bounds=\(configuration.maximumHistoricalPersons),\(configuration.maximumParentageRecords),\(configuration.maximumChildrenPerParent),\(configuration.maximumAncestryDepth)",
            persons.map { "p|\($0.agentID.rawValue)|\($0.ordinal.rawValue)" }.joined(separator: ";"),
            parentages.map {
                "r|\($0.childID.rawValue)|\($0.canonicalParentIDs.map(\.rawValue).joined(separator: ","))|\($0.birthID.rawValue)|\($0.birthTick)|\($0.sourcePopulationBornEventID.rawValue)|\($0.recordedEventID.rawValue)"
            }.joined(separator: ";"),
            "rolling=\(rollingDigest)",
        ].joined(separator: "|"))
    }

    @discardableResult
    private mutating func requiredKinshipEvent(
        kind: AgentCausalEventKind,
        actorID: AgentID? = nil,
        subjectID: AgentID? = nil,
        causes: [AgentCausalEventID] = [],
        payload: AgentCausalPayload,
        summary: String
    ) throws -> AgentCausalEvent {
        guard let event = try recordCausalEvent(
            kind: kind,
            origin: .kinshipTransition,
            actorID: actorID,
            subjectID: subjectID,
            causes: causes.sorted(),
            payload: payload,
            summary: summary
        ) else { throw AgentSessionError.kinship(.causalLedgerRequired) }
        return event
    }
}
