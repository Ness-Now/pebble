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
        // Identity is meaningful only inside the historical archive: equal unknown IDs stay unknown.
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
        try prevalidateCausalAppend(count: lifecycle.births.count + 1)
        let digest = AgentKinshipDigest.make(
            "initialize|\(persons.map { "\($0.agentID.rawValue):\($0.ordinal.rawValue)" }.joined(separator: ","))|"
                + lifecycle.births.map(\.birthID.rawValue).sorted().joined(separator: ",")
        )
        var parentages: [AgentParentageRecord] = []
        for (index, birth) in lifecycle.births.sorted(by: { $0.newbornID < $1.newbornID }).enumerated() {
            let recorded = try requiredKinshipEvent(
                kind: .kinshipParentageRecorded,
                subjectID: birth.newbornID,
                causes: [birth.populationBornEventID],
                payload: .kinship(
                    childID: birth.newbornID.rawValue,
                    birthID: birth.birthID.rawValue,
                    parentIDs: birth.progenitorIDs.map(\.rawValue),
                    personCount: persons.count,
                    parentageCount: index + 1,
                    digest: digest,
                    status: "parentageRecorded"
                ),
                summary: "kinship parentage reconstructed child=\(birth.newbornID.rawValue) parents=\(birth.progenitorIDs.map(\.rawValue).joined(separator: ","))",
                instant: AgentSimulationInstant(
                    simulationID: clock.simulationID,
                    tick: AgentSimulationTick(rawValue: birth.birthTick)!
                )
            )
            parentages.append(AgentParentageRecord(
                childID: birth.newbornID,
                parentIDs: birth.progenitorIDs,
                birthID: birth.birthID,
                birthTick: birth.birthTick,
                sourcePopulationBornEventID: birth.populationBornEventID,
                recordedEventID: recorded.eventID
            ))
        }
        let initialized = try requiredKinshipEvent(
            kind: .kinshipInitialized,
            payload: .kinship(
                childID: nil, birthID: nil, parentIDs: [],
                personCount: persons.count, parentageCount: lifecycle.births.count,
                digest: digest, status: "initialized"
            ),
            summary: "kinship initialized persons=\(persons.count) parentages=\(lifecycle.births.count)"
        )
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
                causalDroppedEventCount: causalLedger.droppedEventCount,
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
        causalDroppedEventCount: UInt64,
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
        guard causalDroppedEventCount <= causalLatestSequence,
              UInt64(causalEvents.count) == causalLatestSequence - causalDroppedEventCount,
              causalEvents.enumerated().allSatisfy({ index, event in
                  event.sequence.rawValue == causalDroppedEventCount + UInt64(index) + 1
              }) else {
            throw AgentKinshipError.invalidCausalReference(kinship.lastKinshipEventID)
        }
        let retainedEvent: (AgentCausalEventID) throws -> AgentCausalEvent? = { eventID in
            guard eventID.simulationID == clock.simulationID,
                  eventID.sequence.rawValue <= causalLatestSequence else {
                throw AgentKinshipError.invalidCausalReference(eventID)
            }
            if let event = causalEvents.first(where: { $0.eventID == eventID }) {
                return event
            }
            guard causalDroppedEventCount > 0,
                  eventID.sequence.rawValue <= causalDroppedEventCount else {
                throw AgentKinshipError.invalidCausalReference(eventID)
            }
            return nil
        }
        if let initialized = try retainedEvent(kinship.initializedEventID) {
            guard initialized.kind == .kinshipInitialized,
                  initialized.origin == .kinshipTransition,
                  initialized.actorID == nil,
                  initialized.subjectID == nil,
                  initialized.operationID == nil,
                  initialized.causes.isEmpty,
                  case let .kinship(childID, birthID, parentIDs, personCount,
                                    parentageCount, digest, status) = initialized.payload,
                  childID == nil, birthID == nil, parentIDs.isEmpty,
                  personCount > 0, personCount <= kinship.historicalPersons.count,
                  parentageCount >= 0, parentageCount <= kinship.parentageRecords.count,
                  !digest.isEmpty, status == "initialized" else {
                throw AgentKinshipError.invalidCausalReference(kinship.initializedEventID)
            }
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
            let ordinal = kinship.historicalPersons.first(where: {
                $0.agentID == record.childID
            })!.ordinal
            if let source = try retainedEvent(record.sourcePopulationBornEventID) {
                guard source.kind == .populationMemberBorn,
                      source.origin == .lifecycleTransition,
                      source.simulationTick.rawValue == record.birthTick,
                      source.actorID == record.canonicalParentIDs.first,
                      source.subjectID == record.childID,
                      source.operationID == nil,
                      source.causes.count == 1,
                      case let .birth(birthID, planID, newbornID, payloadOrdinal,
                                      progenitorIDs, position, fingerprint, status) = source.payload,
                      birthID == record.birthID.rawValue,
                      newbornID == record.childID.rawValue,
                      payloadOrdinal == ordinal.rawValue,
                      progenitorIDs == record.canonicalParentIDs.map(\.rawValue),
                      status == "born" else {
                    throw AgentKinshipError.invalidCausalReference(record.sourcePopulationBornEventID)
                }
                let siteEventID = source.causes[0]
                if let birth = lifecycle.births.first(where: { $0.newbornID == record.childID }),
                   birth.siteValidatedEventID != siteEventID {
                    throw AgentKinshipError.invalidCausalReference(siteEventID)
                }
                if let site = try retainedEvent(siteEventID) {
                    guard site.kind == .birthSiteValidated,
                          site.origin == .lifecycleTransition,
                          site.simulationTick.rawValue == record.birthTick,
                          site.actorID == record.canonicalParentIDs.first,
                          site.subjectID == record.childID,
                          site.operationID == nil,
                          case let .birth(siteBirthID, sitePlanID, siteNewbornID,
                                          siteOrdinal, siteParents, sitePosition,
                                          siteFingerprint, siteStatus) = site.payload,
                          siteBirthID == birthID,
                          sitePlanID == planID,
                          siteNewbornID == newbornID,
                          siteOrdinal == payloadOrdinal,
                          siteParents == progenitorIDs,
                          sitePosition == position,
                          siteFingerprint == fingerprint,
                          siteStatus == "siteValidated" else {
                        throw AgentKinshipError.invalidCausalReference(siteEventID)
                    }
                }
            }
            if let recorded = try retainedEvent(record.recordedEventID) {
                let expectedParentageCount = kinship.parentageRecords.filter {
                    $0.recordedEventID.sequence <= recorded.sequence
                }.count
                guard recorded.kind == .kinshipParentageRecorded,
                      recorded.origin == .kinshipTransition,
                      recorded.simulationTick.rawValue == record.birthTick,
                      recorded.actorID == nil,
                      recorded.subjectID == record.childID,
                      recorded.operationID == nil,
                      recorded.causes == [record.sourcePopulationBornEventID],
                      case let .kinship(childID, birthID, parentIDs, personCount,
                                        parentageCount, digest, status) = recorded.payload,
                      childID == record.childID.rawValue,
                      birthID == record.birthID.rawValue,
                      parentIDs == record.canonicalParentIDs.map(\.rawValue),
                      personCount >= ordinal.rawValue + 1,
                      personCount <= kinship.historicalPersons.count,
                      parentageCount == expectedParentageCount,
                      !digest.isEmpty,
                      status == "parentageRecorded" else {
                    throw AgentKinshipError.invalidCausalReference(record.recordedEventID)
                }
            }
            for parentID in record.canonicalParentIDs {
                childrenCounts[parentID, default: 0] += 1
                if childrenCounts[parentID, default: 0]
                    > kinship.configuration.maximumChildrenPerParent {
                    throw AgentKinshipError.childrenPerParentCapacityReached(parentID)
                }
            }
        }
        if let last = try retainedEvent(kinship.lastKinshipEventID) {
            let isRecordedParentage = kinship.parentageRecords.contains {
                $0.recordedEventID == last.eventID
            }
            let validLastEvent: Bool
            switch last.kind {
            case .kinshipInitialized:
                validLastEvent = last.eventID == kinship.initializedEventID
            case .kinshipParentageRecorded:
                validLastEvent = isRecordedParentage
            case .kinshipPersonRegistered:
                if case let .kinship(childID, birthID, parentIDs, personCount,
                                     parentageCount, digest, status) = last.payload {
                    validLastEvent = last.origin == .kinshipTransition
                        && last.actorID == nil
                        && last.subjectID?.rawValue == childID
                        && last.operationID == nil
                        && last.causes.count == 1
                        && birthID == nil
                        && parentIDs.isEmpty
                        && personCount > 0
                        && personCount <= kinship.historicalPersons.count
                        && parentageCount >= 0
                        && parentageCount <= kinship.parentageRecords.count
                        && !digest.isEmpty
                        && status == "rootRegistered"
                        && last.subjectID.map(known.contains) == true
                } else {
                    validLastEvent = false
                }
            default:
                validLastEvent = false
            }
            guard validLastEvent else {
                throw AgentKinshipError.invalidCausalReference(kinship.lastKinshipEventID)
            }
        }
        guard !causalEvents.contains(where: {
            [.kinshipInitialized, .kinshipPersonRegistered, .kinshipParentageRecorded]
                .contains($0.kind) && $0.sequence > kinship.lastKinshipEventID.sequence
        }) else {
            throw AgentKinshipError.invalidCausalReference(kinship.lastKinshipEventID)
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
                causalDroppedEventCount: causalLedger.droppedEventCount,
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
        summary: String,
        instant: AgentSimulationInstant? = nil
    ) throws -> AgentCausalEvent {
        guard let event = try causalLedger.append(
            instant: instant ?? simulationInstant,
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
