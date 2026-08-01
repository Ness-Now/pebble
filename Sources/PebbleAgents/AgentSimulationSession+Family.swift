import Foundation

extension AgentSimulationSession {
    public var familyV1Enabled: Bool { familyState != nil }

    public func familySnapshot() -> AgentFamilySnapshot {
        guard let family = familyState else {
            return AgentFamilySnapshot(
                enabled: false, configuration: nil, proposals: [], unions: [],
                lineages: [], houses: [], houseMembershipPeriods: [],
                digest: AgentFamilyDigest.make("disabled")
            )
        }
        return AgentFamilySnapshot(
            enabled: true,
            configuration: family.configuration,
            proposals: family.proposals.sorted { $0.proposalID < $1.proposalID },
            unions: family.unions.sorted { $0.unionID < $1.unionID },
            lineages: family.lineages.sorted { $0.lineageID < $1.lineageID },
            houses: family.houses.sorted { $0.houseID < $1.houseID },
            houseMembershipPeriods: family.houseMembershipPeriods.sorted(
                by: familyHouseMembershipSort
            ),
            digest: familyStateDigest(family)
        )
    }

    public func activeUnion(for agentID: AgentID) throws -> AgentUnionRecord? {
        guard let family = familyState else { return nil }
        guard historicalPerson(for: agentID) != nil else {
            throw AgentSessionError.family(.unknownPerson(agentID))
        }
        return family.unions.first {
            $0.status == .active && $0.partnerIDs.contains(agentID)
        }
    }

    public func familyRelations(
        of agentID: AgentID,
        maximumAncestryDepth: Int? = nil
    ) throws -> [AgentFamilyRelation] {
        try familyRelationProjection(
            of: agentID,
            maximumAncestryDepth: maximumAncestryDepth
        ).relations
    }

    public func familyRelationProjection(
        of agentID: AgentID,
        maximumAncestryDepth: Int? = nil
    ) throws -> AgentFamilyRelationProjection {
        guard let family = familyState, let kinship = kinshipState else {
            return AgentFamilyRelationProjection(
                personID: agentID, relations: [], totalRelationCount: 0,
                maximumAncestryDepthApplied: 0, truncated: false
            )
        }
        guard kinship.historicalPersons.contains(where: { $0.agentID == agentID }) else {
            throw AgentSessionError.family(.unknownPerson(agentID))
        }
        let limit = max(0, min(
            maximumAncestryDepth ?? family.configuration.maximumProjectedAncestryDepth,
            family.configuration.maximumProjectedAncestryDepth
        ))
        guard limit > 0 else {
            return AgentFamilyRelationProjection(
                personID: agentID, relations: [], totalRelationCount: 0,
                maximumAncestryDepthApplied: 0, truncated: false
            )
        }
        var rows: [AgentFamilyRelation] = []
        let parentageByChild = Dictionary(uniqueKeysWithValues:
            kinship.parentageRecords.map { ($0.childID, $0) }
        )
        let childRecords = kinship.parentageRecords.filter {
            $0.canonicalParentIDs.contains(agentID)
        }
        if let record = parentageByChild[agentID] {
            rows += record.canonicalParentIDs.map {
                AgentFamilyRelation(
                    kind: .parent, personID: agentID, relatedPersonID: $0,
                    source: .canonicalParentage,
                    sourceEventID: record.recordedEventID, depth: 1
                )
            }
        }
        rows += childRecords.map {
            AgentFamilyRelation(
                kind: .child, personID: agentID, relatedPersonID: $0.childID,
                source: .canonicalParentage,
                sourceEventID: $0.recordedEventID, depth: 1
            )
        }
        for other in kinship.historicalPersons.map(\.agentID).sorted()
            where other != agentID {
            let relation = siblingRelation(between: agentID, and: other)
            let kind: AgentFamilyRelationKind?
            switch relation {
            case .fullSibling: kind = .fullSibling
            case .halfSibling: kind = .halfSibling
            default: kind = nil
            }
            if let kind,
               let source = parentageByChild[agentID]?.recordedEventID {
                rows.append(AgentFamilyRelation(
                    kind: kind, personID: agentID, relatedPersonID: other,
                    source: .sharedCanonicalParent,
                    sourceEventID: source, depth: 1
                ))
            }
        }
        rows += ancestryRelations(
            from: agentID, parentageByChild: parentageByChild,
            parentageRecords: kinship.parentageRecords, maximumDepth: limit
        )
        for union in family.unions where union.partnerIDs.contains(agentID) {
            let partner = union.partnerIDs.first { $0 != agentID }!
            rows.append(AgentFamilyRelation(
                kind: union.status == .active ? .unionPartner : .formerUnionPartner,
                personID: agentID, relatedPersonID: partner,
                source: union.status == .active ? .activeUnion : .endedUnion,
                sourceEventID: union.status == .active
                    ? union.activationEventID : union.terminationEventID!,
                depth: nil
            ))
        }
        for other in kinship.historicalPersons.map(\.agentID).sorted()
            where other != agentID {
            let shared = kinship.parentageRecords.filter {
                $0.canonicalParentIDs.contains(agentID)
                    && $0.canonicalParentIDs.contains(other)
            }
            if !shared.isEmpty {
                rows.append(AgentFamilyRelation(
                    kind: .coParent, personID: agentID, relatedPersonID: other,
                    source: .sharedChild,
                    sourceEventID: shared.sorted { $0.childID < $1.childID }[0].recordedEventID,
                    depth: nil
                ))
            }
        }
        let deduplicated = Dictionary(grouping: rows) {
            "\($0.kind.rawValue)|\($0.relatedPersonID.rawValue)"
        }.values.compactMap {
            $0.sorted(by: familyRelationSort).first
        }.sorted(by: familyRelationSort)
        let bounded = Array(deduplicated.prefix(
            family.configuration.maximumProjectedRelationsPerPerson
        ))
        return AgentFamilyRelationProjection(
            personID: agentID,
            relations: bounded,
            totalRelationCount: deduplicated.count,
            maximumAncestryDepthApplied: limit,
            truncated: bounded.count < deduplicated.count
        )
    }

    public func lineageProjection(
        _ lineageID: AgentLineageID,
        maximumDepth: Int? = nil
    ) throws -> AgentLineageProjection {
        guard let family = familyState, let kinship = kinshipState,
              let lineage = family.lineages.first(where: {
                  $0.lineageID == lineageID
              }) else {
            throw AgentSessionError.family(.invalidLineageRoot(
                AgentID(rawValue: "unknown")!
            ))
        }
        let limit = max(0, min(
            maximumDepth ?? family.configuration.maximumProjectedAncestryDepth,
            family.configuration.maximumProjectedAncestryDepth
        ))
        let childrenByParent = Dictionary(grouping: kinship.parentageRecords.flatMap {
            record in record.canonicalParentIDs.map { ($0, record.childID) }
        }, by: \.0).mapValues { $0.map(\.1).sorted() }
        var frontier = [lineage.rootPersonID]
        var visited: Set<AgentID> = [lineage.rootPersonID]
        var members: [AgentID] = [lineage.rootPersonID]
        var depth = 0
        while !frontier.isEmpty, depth < limit {
            let next = Array(Set(frontier.flatMap {
                childrenByParent[$0] ?? []
            })).sorted().filter { !visited.contains($0) }
            visited.formUnion(next)
            members.append(contentsOf: next)
            frontier = next
            depth += 1
        }
        let hasMore = !frontier.flatMap { childrenByParent[$0] ?? [] }
            .filter { !visited.contains($0) }.isEmpty
        var allVisited = visited
        var remaining = frontier
        while !remaining.isEmpty {
            let next = Array(Set(remaining.flatMap {
                childrenByParent[$0] ?? []
            })).sorted().filter { !allVisited.contains($0) }
            allVisited.formUnion(next)
            remaining = next
        }
        let bounded = Array(members.sorted().prefix(
            family.configuration.maximumProjectedRelationsPerPerson
        ))
        return AgentLineageProjection(
            lineage: lineage, memberIDs: bounded,
            totalDescendantCount: max(0, allVisited.count - 1),
            maximumDepthApplied: limit,
            truncated: hasMore || bounded.count < members.count
        )
    }

    public func lineages(containing agentID: AgentID) throws -> [AgentLineageProjection] {
        guard let family = familyState, let kinship = kinshipState else { return [] }
        guard historicalPerson(for: agentID) != nil else {
            throw AgentSessionError.family(.unknownPerson(agentID))
        }
        let parentageByChild = Dictionary(uniqueKeysWithValues:
            kinship.parentageRecords.map { ($0.childID, $0.canonicalParentIDs) }
        )
        var ancestors = Set<AgentID>()
        var frontier = parentageByChild[agentID] ?? []
        while !frontier.isEmpty {
            let next = frontier.sorted().filter { !ancestors.contains($0) }
            ancestors.formUnion(next)
            frontier = next.flatMap { parentageByChild[$0] ?? [] }
        }
        return try family.lineages.sorted { $0.lineageID < $1.lineageID }.compactMap {
            guard $0.rootPersonID == agentID
                    || ancestors.contains($0.rootPersonID) else {
                return nil
            }
            return try lineageProjection($0.lineageID)
        }
    }

    public func houseProjection(_ houseID: AgentHouseID) throws -> AgentHouseProjection {
        guard let family = familyState,
              let house = family.houses.first(where: { $0.houseID == houseID }) else {
            throw AgentSessionError.family(.invalidHouse(houseID))
        }
        let active = family.houseMembershipPeriods.filter {
            $0.houseID == houseID && $0.leftTick == nil
        }.sorted(by: familyHouseMembershipSort)
        let living = active.filter {
            statesById[$0.agentID.rawValue] != nil
        }.count
        let householdIDs = Array(Set(active.compactMap {
            (try? currentMembership(of: $0.agentID))??.householdID
        })).sorted()
        return AgentHouseProjection(
            house: house, activeMemberships: active,
            livingMemberCount: living, householdIDs: householdIDs
        )
    }

    public func currentHouseMemberships(
        of agentID: AgentID
    ) throws -> [AgentHouseMembershipPeriod] {
        guard let family = familyState else { return [] }
        guard historicalPerson(for: agentID) != nil else {
            throw AgentSessionError.family(.unknownPerson(agentID))
        }
        return family.houseMembershipPeriods.filter {
            $0.agentID == agentID && $0.leftTick == nil
        }.sorted(by: familyHouseMembershipSort)
    }

    public mutating func setFamilyV1Enabled(
        _ enabled: Bool,
        configuration: AgentFamilyConfiguration = .live
    ) throws {
        guard enabled else {
            if familyV1Enabled {
                throw AgentSessionError.family(.unsafeDisable)
            }
            return
        }
        var candidate = self
        try candidate.initializeFamilyV1(configuration)
        self = candidate
    }

    private mutating func initializeFamilyV1(
        _ configuration: AgentFamilyConfiguration
    ) throws {
        guard familyState == nil else {
            throw AgentSessionError.family(.alreadyEnabled)
        }
        guard causalLedger.policy != .disabled else {
            throw AgentSessionError.family(.causalLedgerRequired)
        }
        guard populationRegistry != nil else {
            throw AgentSessionError.family(.populationRequired)
        }
        guard lifecycleState != nil else {
            throw AgentSessionError.family(.lifecycleRequired)
        }
        guard kinshipState != nil else {
            throw AgentSessionError.family(.kinshipRequired)
        }
        guard householdState != nil else {
            throw AgentSessionError.family(.householdsRequired)
        }
        guard childhoodV2Enabled else {
            throw AgentSessionError.family(.childhoodRequired)
        }
        _ = try AgentFamilyConfiguration(
            maximumPendingProposals: configuration.maximumPendingProposals,
            maximumUnionHistory: configuration.maximumUnionHistory,
            maximumActiveUnionsPerAgent: configuration.maximumActiveUnionsPerAgent,
            maximumLineages: configuration.maximumLineages,
            maximumLineageFoundationsPerPerson:
                configuration.maximumLineageFoundationsPerPerson,
            maximumProjectedAncestryDepth:
                configuration.maximumProjectedAncestryDepth,
            maximumHouses: configuration.maximumHouses,
            maximumFoundersPerHouse: configuration.maximumFoundersPerHouse,
            maximumMembersPerHouse: configuration.maximumMembersPerHouse,
            maximumHouseMembershipHistory:
                configuration.maximumHouseMembershipHistory,
            maximumTransitionsPerTick: configuration.maximumTransitionsPerTick,
            maximumInteractionDistance: configuration.maximumInteractionDistance,
            maximumProjectedRelationsPerPerson:
                configuration.maximumProjectedRelationsPerPerson
        )
        try prevalidateCausalAppend(count: 1)
        let event = try requiredFamilyEvent(
            kind: .familyV1Initialized,
            payloadStatus: "initialized",
            detail: "persons=\(kinshipState?.historicalPersons.count ?? 0)",
            summary: "family V1 initialized"
        )
        familyState = AgentFamilyState(
            configuration: configuration,
            proposals: [], unions: [], lineages: [], houses: [],
            houseMembershipPeriods: [], processedInteractionReceiptIDs: [],
            nextUnionOrdinal: 1, nextLineageOrdinal: 1, nextHouseOrdinal: 1,
            transitionTick: tick, transitionsAtTick: 1,
            rollingDigest: AgentFamilyDigest.make(
                "family-v1|\(simulationID.rawValue)|\(tick)"
            ),
            initializedEventID: event.eventID,
            lastFamilyEventID: event.eventID
        )
        try validateFamilyCrossDomainIfEnabled()
    }

    @discardableResult
    public mutating func proposeUnion(
        _ receipt: AgentFamilyInteractionReceipt
    ) throws -> AgentUnionProposal {
        var candidate = self
        let result = try candidate.proposeUnionInPlace(receipt)
        try candidate.validateFamilyCrossDomainIfEnabled()
        self = candidate
        return result
    }

    private mutating func proposeUnionInPlace(
        _ receipt: AgentFamilyInteractionReceipt
    ) throws -> AgentUnionProposal {
        guard var family = familyState else {
            throw AgentSessionError.family(.disabled)
        }
        guard family.proposals.filter({ $0.status == .pending }).count
                < family.configuration.maximumPendingProposals else {
            throw AgentSessionError.family(.proposalCapacityReached)
        }
        try validateUnionEligibility(receipt.actorID, receipt.counterpartyID, family: family)
        try prevalidateCausalAppend(count: 2)
        let interaction = try consumeFamilyInteraction(
            receipt, expected: .unionProposal, family: &family
        )
        try countFamilyTransitions(&family, count: 1)
        let proposalID = AgentUnionProposalID(rawValue: receipt.receiptID)!
        guard !family.proposals.contains(where: { $0.proposalID == proposalID }) else {
            throw AgentSessionError.family(.duplicateInteraction(receipt.receiptID))
        }
        let proposed = try requiredFamilyEvent(
            kind: .unionProposed,
            actorID: receipt.actorID, subjectID: receipt.counterpartyID,
            operationID: receipt.receiptID, causes: [interaction],
            payloadStatus: "proposed", detail: proposalID.rawValue,
            summary: "union proposed \(receipt.actorID.rawValue)>\(receipt.counterpartyID.rawValue)"
        )
        let proposal = AgentUnionProposal(
            proposalID: proposalID, proposerID: receipt.actorID,
            recipientID: receipt.counterpartyID, proposedTick: tick,
            proposalReceiptID: receipt.receiptID, proposedEventID: proposed.eventID,
            status: .pending, acceptanceTick: nil, acceptanceReceiptID: nil,
            acceptedEventID: nil, unionID: nil
        )
        family.proposals.append(proposal)
        family.proposals.sort { $0.proposalID < $1.proposalID }
        family.lastFamilyEventID = proposed.eventID
        updateFamilyDigest(&family, "proposal|\(proposalID.rawValue)")
        familyState = family
        return proposal
    }

    @discardableResult
    public mutating func acceptUnion(
        proposalID: AgentUnionProposalID,
        receipt: AgentFamilyInteractionReceipt
    ) throws -> AgentUnionRecord {
        var candidate = self
        let result = try candidate.acceptUnionInPlace(
            proposalID: proposalID, receipt: receipt
        )
        try candidate.validateFamilyCrossDomainIfEnabled()
        self = candidate
        return result
    }

    private mutating func acceptUnionInPlace(
        proposalID: AgentUnionProposalID,
        receipt: AgentFamilyInteractionReceipt
    ) throws -> AgentUnionRecord {
        guard var family = familyState else {
            throw AgentSessionError.family(.disabled)
        }
        guard family.unions.count < family.configuration.maximumUnionHistory,
              family.nextUnionOrdinal < Int.max else {
            throw AgentSessionError.family(.unionCapacityReached)
        }
        guard let index = family.proposals.firstIndex(where: {
            $0.proposalID == proposalID && $0.status == .pending
        }) else {
            throw AgentSessionError.family(.invalidProposal(proposalID))
        }
        let proposal = family.proposals[index]
        guard receipt.actorID == proposal.recipientID,
              receipt.counterpartyID == proposal.proposerID else {
            throw AgentSessionError.family(.wrongProposalRecipient(receipt.actorID))
        }
        try validateUnionEligibility(
            proposal.proposerID, proposal.recipientID, family: family
        )
        try prevalidateCausalAppend(count: 3)
        let interaction = try consumeFamilyInteraction(
            receipt, expected: .unionAcceptance, family: &family
        )
        try countFamilyTransitions(&family, count: 2)
        let accepted = try requiredFamilyEvent(
            kind: .unionAccepted,
            actorID: receipt.actorID, subjectID: receipt.counterpartyID,
            operationID: receipt.receiptID,
            causes: [proposal.proposedEventID, interaction].sorted(),
            payloadStatus: "accepted", detail: proposalID.rawValue,
            summary: "union accepted proposal=\(proposalID.rawValue)"
        )
        let unionID = AgentUnionID(
            rawValue: "union-\(String(format: "%08d", family.nextUnionOrdinal))"
        )!
        let partners = [proposal.proposerID, proposal.recipientID].sorted()
        let activated = try requiredFamilyEvent(
            kind: .unionActivated,
            actorID: partners[0], subjectID: partners[1],
            causes: [accepted.eventID],
            payloadStatus: "active", detail: unionID.rawValue,
            summary: "union activated id=\(unionID.rawValue)"
        )
        family.proposals[index].status = .accepted
        family.proposals[index].acceptanceTick = tick
        family.proposals[index].acceptanceReceiptID = receipt.receiptID
        family.proposals[index].acceptedEventID = accepted.eventID
        family.proposals[index].unionID = unionID
        let union = AgentUnionRecord(
            unionID: unionID, partnerIDs: partners, proposalID: proposalID,
            proposalTick: proposal.proposedTick,
            proposalEventID: proposal.proposedEventID,
            acceptanceTick: tick, acceptanceEventID: accepted.eventID,
            activationTick: tick, activationEventID: activated.eventID,
            status: .active, terminationTick: nil, terminationEventID: nil,
            terminationReason: nil, version: 1
        )
        family.unions.append(union)
        family.unions.sort { $0.unionID < $1.unionID }
        family.nextUnionOrdinal += 1
        family.lastFamilyEventID = activated.eventID
        updateFamilyDigest(&family, "union|\(unionID.rawValue)|active")
        familyState = family
        return union
    }

    public mutating func endUnion(
        unionID: AgentUnionID,
        reason: AgentUnionTerminationReason,
        receipt: AgentFamilyInteractionReceipt
    ) throws {
        guard reason != .partnerDeath else {
            throw AgentSessionError.family(.invalidInteraction("partnerDeath is internal"))
        }
        var candidate = self
        guard var family = candidate.familyState,
              let index = family.unions.firstIndex(where: {
                  $0.unionID == unionID && $0.status == .active
              }) else {
            throw AgentSessionError.family(.invalidUnion(unionID))
        }
        let union = family.unions[index]
        guard union.partnerIDs.contains(receipt.actorID),
              union.partnerIDs.contains(receipt.counterpartyID),
              receipt.actorID != receipt.counterpartyID else {
            throw AgentSessionError.family(.invalidInteraction("separation roles"))
        }
        try candidate.prevalidateCausalAppend(count: 2)
        let interaction = try candidate.consumeFamilyInteraction(
            receipt, expected: .unionSeparation, family: &family
        )
        try candidate.endUnionInPlace(
            at: index, reason: reason, actorID: receipt.actorID,
            causeEventIDs: [interaction],
            operationID: receipt.receiptID, family: &family
        )
        candidate.familyState = family
        try candidate.validateFamilyCrossDomainIfEnabled()
        self = candidate
    }

    @discardableResult
    public mutating func foundLineage(
        rootPersonID: AgentID,
        actorID: AgentID,
        operationID: String
    ) throws -> AgentLineageFoundation {
        var candidate = self
        let result = try candidate.foundLineageInPlace(
            rootPersonID: rootPersonID, actorID: actorID, operationID: operationID
        )
        try candidate.validateFamilyCrossDomainIfEnabled()
        self = candidate
        return result
    }

    private mutating func foundLineageInPlace(
        rootPersonID: AgentID,
        actorID: AgentID,
        operationID: String
    ) throws -> AgentLineageFoundation {
        guard var family = familyState else {
            throw AgentSessionError.family(.disabled)
        }
        guard rootPersonID == actorID else {
            throw AgentSessionError.family(.invalidLineageRoot(rootPersonID))
        }
        try validateAvailableMaturePerson(rootPersonID)
        guard family.lineages.count < family.configuration.maximumLineages,
              family.nextLineageOrdinal < Int.max else {
            throw AgentSessionError.family(.lineageCapacityReached)
        }
        guard !family.lineages.contains(where: { $0.rootPersonID == rootPersonID }) else {
            throw AgentSessionError.family(.duplicateLineageRoot(rootPersonID))
        }
        guard let operation = AgentOperationID(rawValue: operationID),
              !family.processedInteractionReceiptIDs.contains(operationID) else {
            throw AgentSessionError.family(.duplicateInteraction(operationID))
        }
        try countFamilyTransitions(&family, count: 1)
        try prevalidateCausalAppend(count: 1)
        let lineageID = AgentLineageID(
            rawValue: "lineage-\(String(format: "%08d", family.nextLineageOrdinal))"
        )!
        let event = try requiredFamilyEvent(
            kind: .lineageFounded, actorID: actorID, subjectID: rootPersonID,
            operationID: operation.rawValue, causes: [],
            payloadStatus: "founded", detail: lineageID.rawValue,
            summary: "lineage founded id=\(lineageID.rawValue) root=\(rootPersonID.rawValue)"
        )
        let lineage = AgentLineageFoundation(
            lineageID: lineageID, rootPersonID: rootPersonID,
            foundationTick: tick, foundationEventID: event.eventID,
            status: .historical, version: 1
        )
        family.lineages.append(lineage)
        family.lineages.sort { $0.lineageID < $1.lineageID }
        family.processedInteractionReceiptIDs.append(operationID)
        family.processedInteractionReceiptIDs.sort()
        family.nextLineageOrdinal += 1
        family.lastFamilyEventID = event.eventID
        updateFamilyDigest(&family, "lineage|\(lineageID.rawValue)")
        familyState = family
        return lineage
    }

    @discardableResult
    public mutating func foundHouse(
        founderID: AgentID,
        operationID: String
    ) throws -> AgentHouseRecord {
        var candidate = self
        let result = try candidate.foundHouseInPlace(
            founderIDs: [founderID], receipts: [], operationID: operationID
        )
        try candidate.validateFamilyCrossDomainIfEnabled()
        self = candidate
        return result
    }

    @discardableResult
    public mutating func coFoundHouse(
        founderIDs: [AgentID],
        receipts: [AgentFamilyInteractionReceipt]
    ) throws -> AgentHouseRecord {
        var candidate = self
        let result = try candidate.foundHouseInPlace(
            founderIDs: founderIDs, receipts: receipts, operationID: nil
        )
        try candidate.validateFamilyCrossDomainIfEnabled()
        self = candidate
        return result
    }

    private mutating func foundHouseInPlace(
        founderIDs rawFounderIDs: [AgentID],
        receipts: [AgentFamilyInteractionReceipt],
        operationID: String?
    ) throws -> AgentHouseRecord {
        guard var family = familyState else {
            throw AgentSessionError.family(.disabled)
        }
        let founders = rawFounderIDs.sorted()
        guard founders == Array(Set(founders)).sorted(),
              (1...family.configuration.maximumFoundersPerHouse).contains(founders.count),
              family.houses.count < family.configuration.maximumHouses,
              family.houseMembershipPeriods.count + founders.count
                <= family.configuration.maximumHouseMembershipHistory,
              family.nextHouseOrdinal < Int.max else {
            throw AgentSessionError.family(.invalidHouseFoundation)
        }
        for founder in founders { try validateAvailableMaturePerson(founder) }
        var causeIDs: [AgentCausalEventID] = []
        var cofoundingInteractionProofs: [AgentFamilyInteractionProof]?
        var foundationPosition = statesById[founders[0].rawValue]!.position
        if founders.count == 2 {
            guard family.unions.contains(where: {
                $0.status == .active && $0.partnerIDs == founders
            }), receipts.count == 2,
            Set(receipts.map(\.actorID)) == Set(founders),
            receipts.allSatisfy({
                $0.kind == .houseCoFoundation
                    && Set([$0.actorID, $0.counterpartyID]) == Set(founders)
            }) else {
                throw AgentSessionError.family(.invalidHouseFoundation)
            }
            try prevalidateCausalAppend(count: 5)
            var proofs: [AgentFamilyInteractionProof] = []
            for receipt in receipts.sorted(by: { $0.actorID < $1.actorID }) {
                let eventID = try consumeFamilyInteraction(
                    receipt, expected: .houseCoFoundation, family: &family
                )
                causeIDs.append(eventID)
                proofs.append(AgentFamilyInteractionProof(
                    eventID: eventID, operationID: receipt.receiptID,
                    kind: receipt.kind, actorID: receipt.actorID,
                    counterpartyID: receipt.counterpartyID,
                    tick: receipt.observedTick
                ))
            }
            cofoundingInteractionProofs = proofs
            foundationPosition = receipts.sorted { $0.actorID < $1.actorID }[0].actorPosition
        } else {
            guard let operationID, AgentOperationID(rawValue: operationID) != nil,
                  !family.processedInteractionReceiptIDs.contains(operationID) else {
                throw AgentSessionError.family(.invalidHouseFoundation)
            }
            try prevalidateCausalAppend(count: 2)
            family.processedInteractionReceiptIDs.append(operationID)
            family.processedInteractionReceiptIDs.sort()
        }
        try countFamilyTransitions(&family, count: founders.count + 1)
        let houseID = AgentHouseID(
            rawValue: "house-\(String(format: "%08d", family.nextHouseOrdinal))"
        )!
        let founded = try requiredFamilyEvent(
            kind: .houseFounded, actorID: founders[0],
            subjectID: founders.count == 2 ? founders[1] : founders[0],
            operationID: founders.count == 1 ? operationID : nil,
            causes: causeIDs.sorted(), payloadStatus: "active",
            detail: "\(houseID.rawValue)|\(founders.map(\.rawValue).joined(separator: ","))",
            summary: "house founded id=\(houseID.rawValue)"
        )
        let house = AgentHouseRecord(
            houseID: houseID, founderIDs: founders, foundationTick: tick,
            foundationPosition: foundationPosition,
            foundationEventID: founded.eventID,
            cofoundingInteractionProofs: cofoundingInteractionProofs,
            status: .active,
            lastEventID: founded.eventID, version: 1
        )
        family.houses.append(house)
        for founder in founders {
            let joined = try requiredFamilyEvent(
                kind: .houseMemberJoined, actorID: founder, subjectID: founder,
                causes: [founded.eventID], payloadStatus: "founder",
                detail: houseID.rawValue,
                summary: "house founder joined house=\(houseID.rawValue) agent=\(founder.rawValue)"
            )
            family.houseMembershipPeriods.append(AgentHouseMembershipPeriod(
                houseID: houseID, agentID: founder, basis: .founder,
                joinedTick: tick, joinedEventID: joined.eventID,
                explicitJoinConsent: nil,
                leftTick: nil, leftEventID: nil, endReason: nil
            ))
            family.houses[family.houses.count - 1].lastEventID = joined.eventID
            family.lastFamilyEventID = joined.eventID
        }
        family.houses.sort { $0.houseID < $1.houseID }
        family.houseMembershipPeriods.sort(by: familyHouseMembershipSort)
        family.nextHouseOrdinal += 1
        updateFamilyDigest(&family, "house|\(houseID.rawValue)")
        familyState = family
        return house
    }

    public mutating func joinHouse(
        _ houseID: AgentHouseID,
        request: AgentFamilyInteractionReceipt,
        acceptance: AgentFamilyInteractionReceipt
    ) throws {
        var candidate = self
        guard var family = candidate.familyState else {
            throw AgentSessionError.family(.disabled)
        }
        guard let house = family.houses.first(where: {
            $0.houseID == houseID && $0.status == .active
        }) else {
            throw AgentSessionError.family(.invalidHouse(houseID))
        }
        guard request.kind == .houseJoinRequest,
              acceptance.kind == .houseJoinAcceptance,
              request.actorID == acceptance.counterpartyID,
              request.counterpartyID == acceptance.actorID else {
            throw AgentSessionError.family(.invalidInteraction("house join roles"))
        }
        let joiningID = request.actorID
        let acceptingID = acceptance.actorID
        try candidate.validateAvailableMaturePerson(joiningID)
        try candidate.validateAvailableMaturePerson(acceptingID)
        let joiningMatureSinceTick = try candidate.familyMatureSinceTick(joiningID)
        guard family.houseMembershipPeriods.contains(where: {
            $0.houseID == houseID && $0.agentID == acceptingID && $0.leftTick == nil
        }), !family.houseMembershipPeriods.contains(where: {
            $0.houseID == houseID && $0.agentID == joiningID && $0.leftTick == nil
        }), family.houseMembershipPeriods.filter({
            $0.houseID == houseID && $0.leftTick == nil
        }).count < family.configuration.maximumMembersPerHouse,
        family.houseMembershipPeriods.count
            < family.configuration.maximumHouseMembershipHistory,
        Self.familyGroundingExists(
            joiningID, acceptingID, at: candidate.tick,
            beforeEventID: nil, family: family,
            parentageRecords: candidate.kinshipState?.parentageRecords ?? [],
            maximumDepth: family.configuration.maximumProjectedAncestryDepth
        ) else {
            throw AgentSessionError.family(.invalidHouseMembershipBasis)
        }
        try candidate.prevalidateCausalAppend(count: 3)
        let requested = try candidate.consumeFamilyInteraction(
            request, expected: .houseJoinRequest, family: &family
        )
        let accepted = try candidate.consumeFamilyInteraction(
            acceptance, expected: .houseJoinAcceptance, family: &family
        )
        let consent = AgentHouseJoinConsent(
            acceptedByID: acceptingID,
            joiningMatureSinceTick: joiningMatureSinceTick,
            request: AgentFamilyInteractionProof(
                eventID: requested, operationID: request.receiptID,
                kind: request.kind, actorID: request.actorID,
                counterpartyID: request.counterpartyID,
                tick: request.observedTick
            ),
            acceptance: AgentFamilyInteractionProof(
                eventID: accepted, operationID: acceptance.receiptID,
                kind: acceptance.kind, actorID: acceptance.actorID,
                counterpartyID: acceptance.counterpartyID,
                tick: acceptance.observedTick
            )
        )
        try candidate.countFamilyTransitions(&family, count: 1)
        let joined = try candidate.requiredFamilyEvent(
            kind: .houseMemberJoined, actorID: joiningID, subjectID: joiningID,
            causes: [requested, accepted].sorted(), payloadStatus: "explicitAdultJoin",
            detail: "\(houseID.rawValue)|acceptedBy=\(acceptingID.rawValue)",
            summary: "house member joined house=\(houseID.rawValue) agent=\(joiningID.rawValue)"
        )
        family.houseMembershipPeriods.append(AgentHouseMembershipPeriod(
            houseID: houseID, agentID: joiningID, basis: .explicitAdultJoin,
            joinedTick: candidate.tick, joinedEventID: joined.eventID,
            explicitJoinConsent: consent,
            leftTick: nil, leftEventID: nil, endReason: nil
        ))
        family.houseMembershipPeriods.sort(by: candidate.familyHouseMembershipSort)
        if let index = family.houses.firstIndex(where: { $0.houseID == house.houseID }) {
            family.houses[index].lastEventID = joined.eventID
        }
        family.lastFamilyEventID = joined.eventID
        candidate.updateFamilyDigest(
            &family, "join|\(houseID.rawValue)|\(joiningID.rawValue)"
        )
        candidate.familyState = family
        try candidate.validateFamilyCrossDomainIfEnabled()
        self = candidate
    }

    public mutating func leaveHouse(
        _ houseID: AgentHouseID,
        agentID: AgentID,
        operationID: String
    ) throws {
        var candidate = self
        guard var family = candidate.familyState,
              let membershipIndex = family.houseMembershipPeriods.firstIndex(where: {
                  $0.houseID == houseID && $0.agentID == agentID && $0.leftTick == nil
              }), AgentOperationID(rawValue: operationID) != nil,
              !family.processedInteractionReceiptIDs.contains(operationID) else {
            throw AgentSessionError.family(.missingHouseMembership(agentID, houseID))
        }
        try candidate.validateAvailableMaturePerson(agentID)
        try candidate.countFamilyTransitions(&family, count: 1)
        try candidate.prevalidateCausalAppend(count: 1)
        let left = try candidate.requiredFamilyEvent(
            kind: .houseMemberLeft, actorID: agentID, subjectID: agentID,
            operationID: operationID,
            causes: [family.houseMembershipPeriods[membershipIndex].joinedEventID],
            payloadStatus: "explicitAdultLeave", detail: houseID.rawValue,
            summary: "house member left house=\(houseID.rawValue) agent=\(agentID.rawValue)"
        )
        family.houseMembershipPeriods[membershipIndex].leftTick = candidate.tick
        family.houseMembershipPeriods[membershipIndex].leftEventID = left.eventID
        family.houseMembershipPeriods[membershipIndex].endReason = .explicitAdultLeave
        family.processedInteractionReceiptIDs.append(operationID)
        family.processedInteractionReceiptIDs.sort()
        candidate.refreshHouseStatus(houseID, family: &family, causeEventID: left.eventID)
        family.lastFamilyEventID = left.eventID
        candidate.updateFamilyDigest(
            &family, "leave|\(houseID.rawValue)|\(agentID.rawValue)"
        )
        candidate.familyState = family
        try candidate.validateFamilyCrossDomainIfEnabled()
        self = candidate
    }

    mutating func registerFamilyBirth(
        childID: AgentID,
        parentIDs: [AgentID],
        causeEventID: AgentCausalEventID
    ) throws -> AgentCausalEventID? {
        guard var family = familyState else { return nil }
        let parents = parentIDs.sorted()
        guard parents.count == 2, Set(parents).count == 2 else {
            throw AgentSessionError.family(.invalidState("birth parents"))
        }
        guard let houseID = Self.sharedParentalHouseAtBirth(
            parentIDs: parents, tick: tick, family: family
        ) else { return nil }
        guard family.houseMembershipPeriods.count
                < family.configuration.maximumHouseMembershipHistory,
              family.houseMembershipPeriods.filter({
                  $0.houseID == houseID
                      && Self.familyMembership($0, isActiveAt: tick)
              }).count < family.configuration.maximumMembersPerHouse else {
            throw AgentSessionError.family(.membershipCapacityReached)
        }
        try countFamilyTransitions(&family, count: 1)
        let event = try requiredFamilyEvent(
            kind: .houseMemberJoined, actorID: parents[0], subjectID: childID,
            causes: [causeEventID], payloadStatus: "sharedParentHouseAtBirth",
            detail: houseID.rawValue,
            summary: "child joined shared parental house=\(houseID.rawValue)"
        )
        family.houseMembershipPeriods.append(AgentHouseMembershipPeriod(
            houseID: houseID, agentID: childID,
            basis: .sharedParentHouseAtBirth, joinedTick: tick,
            joinedEventID: event.eventID, explicitJoinConsent: nil,
            leftTick: nil, leftEventID: nil, endReason: nil
        ))
        family.houseMembershipPeriods.sort(by: familyHouseMembershipSort)
        if let index = family.houses.firstIndex(where: { $0.houseID == houseID }) {
            family.houses[index].lastEventID = event.eventID
        }
        family.lastFamilyEventID = event.eventID
        updateFamilyDigest(&family, "birth-house|\(houseID.rawValue)|\(childID.rawValue)")
        familyState = family
        return event.eventID
    }

    public func familyBirthEventCount(parentIDs: [AgentID]) -> Int {
        guard let family = familyState else { return 0 }
        return Self.sharedParentalHouseAtBirth(
            parentIDs: parentIDs, tick: tick, family: family
        ) == nil ? 0 : 1
    }

    func familyDeathEventCount(agentIDs: [AgentID]) -> Int {
        guard let family = familyState else { return 0 }
        let terminalIDs = Set(agentIDs)
        let unionCount = family.unions.filter {
            $0.status == .active
                && $0.partnerIDs.contains(where: terminalIDs.contains)
        }.count
        let membershipCount = family.houseMembershipPeriods.filter {
            $0.leftTick == nil && terminalIDs.contains($0.agentID)
        }.count
        return unionCount + membershipCount
    }

    mutating func applyFamilyDeath(
        agentID: AgentID,
        causeEventID: AgentCausalEventID,
        at deathTick: Int
    ) throws -> AgentCausalEventID? {
        guard var family = familyState else { return nil }
        let unionIndices = family.unions.indices.filter {
            family.unions[$0].status == .active
                && family.unions[$0].partnerIDs.contains(agentID)
        }
        let membershipIndices = family.houseMembershipPeriods.indices.filter {
            family.houseMembershipPeriods[$0].agentID == agentID
                && family.houseMembershipPeriods[$0].leftTick == nil
        }
        try prevalidateCausalAppend(
            count: unionIndices.count + membershipIndices.count
        )
        var lastEventID: AgentCausalEventID?
        for index in unionIndices {
            try endUnionInPlace(
                at: index, reason: .partnerDeath, actorID: agentID,
                causeEventIDs: [causeEventID], operationID: nil,
                family: &family, eventTick: deathTick
            )
            lastEventID = family.lastFamilyEventID
        }
        for index in membershipIndices {
            try countFamilyTransitions(&family, count: 1)
            let membership = family.houseMembershipPeriods[index]
            let left = try requiredFamilyEvent(
                kind: .houseMemberLeft, actorID: agentID, subjectID: agentID,
                causes: [causeEventID, membership.joinedEventID].sorted(),
                payloadStatus: "memberDeath", detail: membership.houseID.rawValue,
                summary: "deceased member left house=\(membership.houseID.rawValue)"
            )
            family.houseMembershipPeriods[index].leftTick = deathTick
            family.houseMembershipPeriods[index].leftEventID = left.eventID
            family.houseMembershipPeriods[index].endReason = .memberDeath
            refreshHouseStatus(
                membership.houseID, family: &family, causeEventID: left.eventID,
                excludingLivingID: agentID
            )
            family.lastFamilyEventID = left.eventID
            lastEventID = left.eventID
        }
        updateFamilyDigest(&family, "death|\(agentID.rawValue)|\(deathTick)")
        familyState = family
        return lastEventID
    }

    func validateFamilyCrossDomainIfEnabled() throws {
        guard let family = familyState, let population = populationRegistry,
              let lifecycle = lifecycleState, let kinship = kinshipState,
              let households = householdState else { return }
        do {
            try Self.validateFamilyState(
                family, population: population, lifecycle: lifecycle,
                kinship: kinship, households: households,
                agents: Array(statesById.values), mortality: mortalityState,
                schemaVersion: durableSchemaVersionOverride
                    == AgentCheckpointSchema.familyVersion
                    ? AgentCheckpointSchema.familyVersion
                    : AgentCheckpointSchema.durableHouseConsentVersion,
                clock: clock, causalLatestSequence: causalLedger.latestSequence,
                causalDroppedEventCount: causalLedger.droppedEventCount,
                causalEvents: causalLedger.events
            )
        } catch let error as AgentFamilyError {
            throw AgentSessionError.family(error)
        }
    }

    static func validateFamilyState(
        _ family: AgentFamilyState,
        population: AgentPopulationRegistry,
        lifecycle: AgentLifecycleState,
        kinship: AgentKinshipState,
        households: AgentHouseholdState,
        agents: [AgentSessionAgentState],
        mortality: AgentMortalityState?,
        schemaVersion: Int,
        clock: AgentSimulationClock,
        causalLatestSequence: UInt64,
        causalDroppedEventCount: UInt64,
        causalEvents: [AgentCausalEvent]
    ) throws {
        _ = try AgentFamilyConfiguration(
            maximumPendingProposals: family.configuration.maximumPendingProposals,
            maximumUnionHistory: family.configuration.maximumUnionHistory,
            maximumActiveUnionsPerAgent:
                family.configuration.maximumActiveUnionsPerAgent,
            maximumLineages: family.configuration.maximumLineages,
            maximumLineageFoundationsPerPerson:
                family.configuration.maximumLineageFoundationsPerPerson,
            maximumProjectedAncestryDepth:
                family.configuration.maximumProjectedAncestryDepth,
            maximumHouses: family.configuration.maximumHouses,
            maximumFoundersPerHouse: family.configuration.maximumFoundersPerHouse,
            maximumMembersPerHouse: family.configuration.maximumMembersPerHouse,
            maximumHouseMembershipHistory:
                family.configuration.maximumHouseMembershipHistory,
            maximumTransitionsPerTick: family.configuration.maximumTransitionsPerTick,
            maximumInteractionDistance:
                family.configuration.maximumInteractionDistance,
            maximumProjectedRelationsPerPerson:
                family.configuration.maximumProjectedRelationsPerPerson
        )
        let known = Set(kinship.historicalPersons.map(\.agentID))
        let active = Set(agents.map(\.agentID))
        let mortalityRecords = mortality?.records ?? []
        let dead = Set(mortalityRecords.map(\.agentID))
        guard family.proposals == family.proposals.sorted(by: {
            $0.proposalID < $1.proposalID
        }), family.unions == family.unions.sorted(by: {
            $0.unionID < $1.unionID
        }), family.lineages == family.lineages.sorted(by: {
            $0.lineageID < $1.lineageID
        }), family.houses == family.houses.sorted(by: {
            $0.houseID < $1.houseID
        }), family.houseMembershipPeriods == family.houseMembershipPeriods.sorted(by: {
            if $0.houseID != $1.houseID { return $0.houseID < $1.houseID }
            if $0.agentID != $1.agentID { return $0.agentID < $1.agentID }
            if $0.joinedTick != $1.joinedTick { return $0.joinedTick < $1.joinedTick }
            return $0.joinedEventID < $1.joinedEventID
        }), family.processedInteractionReceiptIDs
            == family.processedInteractionReceiptIDs.sorted(),
        family.processedInteractionReceiptIDs.count
            == Set(family.processedInteractionReceiptIDs).count,
        family.processedInteractionReceiptIDs.count
            <= AgentCheckpointLimits.maximumProcessedOperationIDs,
        family.proposals.count <= family.configuration.maximumPendingProposals
            + family.configuration.maximumUnionHistory,
        family.proposals.filter({ $0.status == .pending }).count
            <= family.configuration.maximumPendingProposals,
        family.unions.count <= family.configuration.maximumUnionHistory,
        family.lineages.count <= family.configuration.maximumLineages,
        family.houses.count <= family.configuration.maximumHouses,
        family.houseMembershipPeriods.count
            <= family.configuration.maximumHouseMembershipHistory,
        family.nextUnionOrdinal == family.unions.count + 1,
        family.nextLineageOrdinal == family.lineages.count + 1,
        family.nextHouseOrdinal == family.houses.count + 1,
        family.transitionTick <= clock.tick.rawValue,
        (family.transitionTick == clock.tick.rawValue
            ? family.transitionsAtTick <= family.configuration.maximumTransitionsPerTick
            : family.transitionsAtTick >= 0),
        !family.rollingDigest.isEmpty,
        family.initializedEventID.simulationID == clock.simulationID,
        family.lastFamilyEventID.simulationID == clock.simulationID,
        family.initializedEventID.sequence <= family.lastFamilyEventID.sequence,
        family.lastFamilyEventID.sequence.rawValue <= causalLatestSequence,
        schemaVersion == AgentCheckpointSchema.familyVersion
            || schemaVersion
                == AgentCheckpointSchema.durableHouseConsentVersion
            || schemaVersion == AgentCheckpointSchema.legacyEstateVersion
            || schemaVersion == AgentCheckpointSchema.estateVersion else {
            throw AgentFamilyError.invalidState("bounds, ordering or counters")
        }
        let proposalIDs = family.proposals.map(\.proposalID)
        let unionIDs = family.unions.map(\.unionID)
        let lineageIDs = family.lineages.map(\.lineageID)
        let houseIDs = family.houses.map(\.houseID)
        guard proposalIDs.count == Set(proposalIDs).count,
              unionIDs.count == Set(unionIDs).count,
              lineageIDs.count == Set(lineageIDs).count,
              houseIDs.count == Set(houseIDs).count,
              unionIDs.enumerated().allSatisfy({
                  $0.element.rawValue
                      == "union-\(String(format: "%08d", $0.offset + 1))"
              }),
              lineageIDs.enumerated().allSatisfy({
                  $0.element.rawValue
                      == "lineage-\(String(format: "%08d", $0.offset + 1))"
              }),
              houseIDs.enumerated().allSatisfy({
                  $0.element.rawValue
                      == "house-\(String(format: "%08d", $0.offset + 1))"
              }) else {
            throw AgentFamilyError.invalidState("duplicate durable identity")
        }
        let retainedEvent: (AgentCausalEventID) throws -> AgentCausalEvent? = { id in
            guard id.simulationID == clock.simulationID,
                  id.sequence.rawValue <= causalLatestSequence else {
                throw AgentFamilyError.invalidCausalReference(id)
            }
            if let event = causalEvents.first(where: { $0.eventID == id }) {
                return event
            }
            guard causalDroppedEventCount > 0,
                  id.sequence.rawValue <= causalDroppedEventCount else {
                throw AgentFamilyError.invalidCausalReference(id)
            }
            return nil
        }
        let interactionMatches: (
            AgentCausalEventID,
            AgentFamilyInteractionKind,
            AgentID,
            AgentID,
            String,
            Int
        ) throws -> Bool = { eventID, kind, actorID, subjectID, operationID, tick in
            guard let event = try retainedEvent(eventID) else { return true }
            guard case let .operation(status, detail) = event.payload else {
                return false
            }
            return event.kind == .familyInteractionVerified
                && event.origin == .familyTransition
                && event.actorID == actorID
                && event.subjectID == subjectID
                && event.operationID?.rawValue == operationID
                && event.simulationTick.rawValue == tick
                && status == kind.rawValue
                && familyInteractionPositionIsValid(detail)
        }
        let interactionProofMatches: (
            AgentFamilyInteractionProof,
            AgentFamilyInteractionKind,
            AgentID,
            AgentID,
            Int,
            AgentCausalEventID
        ) throws -> Bool = {
            proof, kind, actorID, counterpartyID, tick, terminalEventID in
            guard proof.kind == kind,
                  proof.actorID == actorID,
                  proof.counterpartyID == counterpartyID,
                  proof.tick == tick,
                  proof.eventID.sequence < terminalEventID.sequence,
                  AgentOperationID(rawValue: proof.operationID) != nil,
                  family.processedInteractionReceiptIDs.contains(
                      proof.operationID
                  ) else {
                return false
            }
            return try interactionMatches(
                proof.eventID, kind, actorID, counterpartyID,
                proof.operationID, tick
            )
        }
        if let event = try retainedEvent(family.initializedEventID) {
            let initializedPersonCount: Int?
            if case let .operation(status, detail) = event.payload,
               status == "initialized", detail.hasPrefix("persons=") {
                initializedPersonCount = Int(detail.dropFirst("persons=".count))
            } else {
                initializedPersonCount = nil
            }
            guard event.kind == .familyV1Initialized,
                  event.origin == .familyTransition,
                  let initializedPersonCount,
                  (0...known.count).contains(initializedPersonCount) else {
                throw AgentFamilyError.invalidCausalReference(event.eventID)
            }
        }
        if let event = try retainedEvent(family.lastFamilyEventID) {
            guard event.origin == .familyTransition else {
                throw AgentFamilyError.invalidCausalReference(event.eventID)
            }
        }
        var activeUnionCounts: [AgentID: Int] = [:]
        for proposal in family.proposals {
            guard known.contains(proposal.proposerID),
                  known.contains(proposal.recipientID),
                  proposal.proposerID != proposal.recipientID,
                  proposal.proposedTick >= 0,
                  proposal.proposedTick <= clock.tick.rawValue,
                  family.processedInteractionReceiptIDs.contains(
                      proposal.proposalReceiptID
                  ) else {
                throw AgentFamilyError.invalidState("proposal identity")
            }
            if let event = try retainedEvent(proposal.proposedEventID) {
                guard event.kind == .unionProposed,
                      event.origin == .familyTransition,
                      event.actorID == proposal.proposerID,
                      event.subjectID == proposal.recipientID,
                      event.simulationTick.rawValue == proposal.proposedTick,
                      event.operationID?.rawValue == proposal.proposalReceiptID,
                      event.payload == .operation(
                          status: "proposed",
                          detail: proposal.proposalID.rawValue
                      ),
                      event.causes.count == 1,
                      try interactionMatches(
                          event.causes[0], .unionProposal,
                          proposal.proposerID, proposal.recipientID,
                          proposal.proposalReceiptID, proposal.proposedTick
                      ) else {
                    throw AgentFamilyError.invalidCausalReference(event.eventID)
                }
            }
            switch proposal.status {
            case .pending:
                guard proposal.acceptanceTick == nil,
                      proposal.acceptanceReceiptID == nil,
                      proposal.acceptedEventID == nil,
                      proposal.unionID == nil else {
                    throw AgentFamilyError.invalidState("pending proposal terminal data")
                }
            case .accepted:
                guard let acceptanceTick = proposal.acceptanceTick,
                      let receiptID = proposal.acceptanceReceiptID,
                      let acceptedEventID = proposal.acceptedEventID,
                      let unionID = proposal.unionID,
                      acceptanceTick >= proposal.proposedTick,
                      acceptanceTick <= clock.tick.rawValue,
                      family.processedInteractionReceiptIDs.contains(receiptID),
                      family.unions.contains(where: {
                          $0.unionID == unionID
                              && $0.proposalID == proposal.proposalID
                      }) else {
                    throw AgentFamilyError.invalidState("accepted proposal")
                }
                if let event = try retainedEvent(acceptedEventID) {
                    let interactionID = event.causes.first {
                        $0 != proposal.proposedEventID
                    }
                    guard event.kind == .unionAccepted,
                          event.origin == .familyTransition,
                          event.actorID == proposal.recipientID,
                          event.subjectID == proposal.proposerID,
                          event.simulationTick.rawValue == acceptanceTick,
                          event.operationID?.rawValue == receiptID,
                          event.payload == .operation(
                              status: "accepted",
                              detail: proposal.proposalID.rawValue
                          ),
                          event.causes.count == 2,
                          event.causes.contains(proposal.proposedEventID),
                          let interactionID,
                          try interactionMatches(
                              interactionID, .unionAcceptance,
                              proposal.recipientID, proposal.proposerID,
                              receiptID, acceptanceTick
                          ) else {
                        throw AgentFamilyError.invalidCausalReference(event.eventID)
                    }
                }
            }
        }
        for union in family.unions {
            let proposal = family.proposals.first {
                $0.proposalID == union.proposalID
            }
            guard union.partnerIDs == union.partnerIDs.sorted(),
                  union.partnerIDs.count == 2,
                  Set(union.partnerIDs).count == 2,
                  union.partnerIDs.allSatisfy(known.contains),
                  union.proposalTick <= union.acceptanceTick,
                  union.acceptanceTick <= union.activationTick,
                  union.activationTick <= clock.tick.rawValue,
                  union.version == 1,
                  proposal?.unionID == union.unionID,
                  [proposal?.proposerID, proposal?.recipientID]
                    .compactMap({ $0 }).sorted() == union.partnerIDs,
                  proposal?.proposedEventID == union.proposalEventID,
                  proposal?.acceptedEventID == union.acceptanceEventID,
                  !familyUnionIsProhibited(
                      union.partnerIDs[0], union.partnerIDs[1],
                      parentageRecords: kinship.parentageRecords,
                      maximumDepth: kinship.configuration.maximumAncestryDepth
                  ) else {
                throw AgentFamilyError.invalidState("union identity")
            }
            if let event = try retainedEvent(union.activationEventID) {
                guard event.kind == .unionActivated,
                      event.origin == .familyTransition,
                      event.actorID == union.partnerIDs[0],
                      event.subjectID == union.partnerIDs[1],
                      event.simulationTick.rawValue == union.activationTick,
                      event.operationID == nil,
                      event.causes == [union.acceptanceEventID],
                      event.payload == .operation(
                          status: "active", detail: union.unionID.rawValue
                      ) else {
                    throw AgentFamilyError.invalidCausalReference(event.eventID)
                }
            }
            switch union.status {
            case .active:
                guard union.terminationTick == nil,
                      union.terminationEventID == nil,
                      union.terminationReason == nil,
                      union.partnerIDs.allSatisfy(active.contains),
                      union.partnerIDs.allSatisfy({ !dead.contains($0) }) else {
                    throw AgentFamilyError.invalidState("active union")
                }
                for partner in union.partnerIDs {
                    activeUnionCounts[partner, default: 0] += 1
                }
            case .ended:
                guard let endTick = union.terminationTick,
                      let eventID = union.terminationEventID,
                      let reason = union.terminationReason,
                      endTick >= union.activationTick,
                      endTick <= clock.tick.rawValue else {
                    throw AgentFamilyError.invalidState("ended union")
                }
                let matchingDeaths = mortalityRecords.filter {
                    union.partnerIDs.contains($0.agentID)
                        && $0.deathTick == endTick
                }
                if reason == .partnerDeath, matchingDeaths.isEmpty {
                    throw AgentFamilyError.invalidState(
                        "partner death termination without mortality"
                    )
                }
                if let event = try retainedEvent(eventID) {
                    guard event.kind == .unionEnded,
                          event.origin == .familyTransition,
                          event.actorID.map(union.partnerIDs.contains) == true,
                          event.subjectID.map(union.partnerIDs.contains) == true,
                          event.actorID != event.subjectID,
                          event.simulationTick.rawValue == endTick,
                          event.causes.contains(union.activationEventID),
                          event.payload == .operation(
                              status: reason.rawValue,
                              detail: union.unionID.rawValue
                          ) else {
                        throw AgentFamilyError.invalidCausalReference(event.eventID)
                    }
                    switch reason {
                    case .unilateralSeparation:
                        guard let operationID = event.operationID?.rawValue,
                              family.processedInteractionReceiptIDs.contains(
                                  operationID
                              ),
                              event.causes.contains(where: { causeID in
                                  guard causeID != union.activationEventID else {
                                      return false
                                  }
                                  guard let cause = causalEvents.first(where: {
                                      $0.eventID == causeID
                                  }) else {
                                      return causeID.simulationID == clock.simulationID
                                          && causeID.sequence.rawValue
                                              <= causalDroppedEventCount
                                  }
                                  return cause.kind == .familyInteractionVerified
                                      && cause.actorID == event.actorID
                                      && cause.subjectID == event.subjectID
                                      && cause.operationID == event.operationID
                              }) else {
                            throw AgentFamilyError.invalidCausalReference(
                                event.eventID
                            )
                        }
                    case .partnerDeath:
                        guard event.operationID == nil,
                              let actorID = event.actorID,
                              let death = matchingDeaths.first(where: {
                                  $0.agentID == actorID
                              }),
                              event.causes.contains(death.lethalDamageEventID)
                        else {
                            throw AgentFamilyError.invalidCausalReference(
                                event.eventID
                            )
                        }
                        if let lethal = try retainedEvent(
                            death.lethalDamageEventID
                        ) {
                            guard lethal.kind == .lethalHealthDepletion,
                                  lethal.actorID == actorID,
                                  lethal.subjectID == actorID,
                                  lethal.simulationTick.rawValue == endTick else {
                                throw AgentFamilyError.invalidCausalReference(
                                    lethal.eventID
                                )
                            }
                        }
                    }
                }
            }
        }
        guard activeUnionCounts.values.allSatisfy({
            $0 <= family.configuration.maximumActiveUnionsPerAgent
        }) else {
            throw AgentFamilyError.invalidState("active union bound")
        }
        let lineageRoots = family.lineages.map(\.rootPersonID)
        guard lineageRoots.count == Set(lineageRoots).count else {
            throw AgentFamilyError.invalidState("duplicate lineage root")
        }
        for lineage in family.lineages {
            guard known.contains(lineage.rootPersonID),
                  lineage.foundationTick >= 0,
                  lineage.foundationTick <= clock.tick.rawValue,
                  lineage.version == 1 else {
                throw AgentFamilyError.invalidState("lineage")
            }
            if let event = try retainedEvent(lineage.foundationEventID) {
                guard event.kind == .lineageFounded,
                      event.origin == .familyTransition,
                      event.actorID == lineage.rootPersonID,
                      event.subjectID == lineage.rootPersonID,
                      event.simulationTick.rawValue == lineage.foundationTick,
                      event.operationID.map({
                          family.processedInteractionReceiptIDs.contains(
                              $0.rawValue
                          )
                      }) == true,
                      event.causes.isEmpty,
                      event.payload == .operation(
                          status: "founded",
                          detail: lineage.lineageID.rawValue
                      ) else {
                    throw AgentFamilyError.invalidCausalReference(event.eventID)
                }
            }
        }
        for house in family.houses {
            guard house.founderIDs == house.founderIDs.sorted(),
                  (1...family.configuration.maximumFoundersPerHouse)
                    .contains(house.founderIDs.count),
                  Set(house.founderIDs).count == house.founderIDs.count,
                  house.founderIDs.allSatisfy(known.contains),
                  house.foundationTick >= 0,
                  house.foundationTick <= clock.tick.rawValue,
                  house.version == 1 else {
                throw AgentFamilyError.invalidState("house")
            }
            let foundationEvent = try retainedEvent(house.foundationEventID)
            if house.founderIDs.count == 1 {
                guard house.cofoundingInteractionProofs == nil else {
                    throw AgentFamilyError.invalidState(
                        "single-founder house consent"
                    )
                }
                if let event = foundationEvent {
                    guard event.kind == .houseFounded,
                          event.origin == .familyTransition,
                          event.simulationTick.rawValue == house.foundationTick,
                          event.actorID == house.founderIDs[0],
                          event.subjectID == house.founderIDs[0],
                          event.causes.isEmpty,
                          event.operationID.map({
                              family.processedInteractionReceiptIDs.contains(
                                  $0.rawValue
                              )
                          }) == true,
                          event.payload == .operation(
                              status: "active",
                              detail: "\(house.houseID.rawValue)|"
                                  + house.founderIDs.map(\.rawValue)
                                    .joined(separator: ",")
                          ) else {
                        throw AgentFamilyError.invalidCausalReference(event.eventID)
                    }
                }
            } else {
                guard family.unions.contains(where: {
                    $0.partnerIDs == house.founderIDs
                        && familyUnion(
                            $0, isActiveAt: house.foundationTick,
                            beforeEventID: house.foundationEventID
                        )
                }) else {
                    throw AgentFamilyError.invalidState(
                        "co-founded house without active union"
                    )
                }
                var proofs = house.cofoundingInteractionProofs
                if proofs == nil,
                   schemaVersion == AgentCheckpointSchema.familyVersion,
                   let event = foundationEvent, event.causes.count == 2 {
                    var legacyProofs: [AgentFamilyInteractionProof] = []
                    for causeID in event.causes {
                        guard let interaction = try retainedEvent(causeID),
                              interaction.kind == .familyInteractionVerified,
                              let actorID = interaction.actorID,
                              let counterpartyID = interaction.subjectID,
                              let operationID = interaction.operationID?.rawValue
                        else {
                            throw AgentFamilyError.invalidCausalReference(
                                causeID
                            )
                        }
                        legacyProofs.append(AgentFamilyInteractionProof(
                            eventID: causeID, operationID: operationID,
                            kind: .houseCoFoundation, actorID: actorID,
                            counterpartyID: counterpartyID,
                            tick: interaction.simulationTick.rawValue
                        ))
                    }
                    proofs = legacyProofs.sorted { $0.actorID < $1.actorID }
                }
                guard let proofs,
                      proofs == proofs.sorted(by: { $0.actorID < $1.actorID }),
                      proofs.count == 2,
                      Set(proofs.map(\.eventID)).count == 2,
                      Set(proofs.map(\.operationID)).count == 2,
                      Set(proofs.map(\.actorID)) == Set(house.founderIDs),
                      proofs.allSatisfy({ proof in
                          proof.counterpartyID
                              == house.founderIDs.first {
                                  $0 != proof.actorID
                              }
                      }) else {
                    throw AgentFamilyError.invalidState(
                        "co-founding consent proof"
                    )
                }
                for proof in proofs {
                    let counterpartyID = house.founderIDs.first {
                        $0 != proof.actorID
                    }!
                    guard try interactionProofMatches(
                        proof, .houseCoFoundation, proof.actorID,
                        counterpartyID, house.foundationTick,
                        house.foundationEventID
                    ) else {
                        throw AgentFamilyError.invalidCausalReference(
                            proof.eventID
                        )
                    }
                }
                if let event = foundationEvent {
                    guard event.kind == .houseFounded,
                          event.origin == .familyTransition,
                          event.simulationTick.rawValue == house.foundationTick,
                          event.actorID == house.founderIDs[0],
                          event.subjectID == house.founderIDs[1],
                          event.operationID == nil,
                          event.causes == proofs.map(\.eventID).sorted(),
                          event.payload == .operation(
                              status: "active",
                              detail: "\(house.houseID.rawValue)|"
                                  + house.founderIDs.map(\.rawValue)
                                    .joined(separator: ",")
                          ) else {
                        throw AgentFamilyError.invalidCausalReference(event.eventID)
                    }
                }
            }
            if let event = try retainedEvent(house.lastEventID) {
                let isHouseEvent: Bool
                switch event.payload {
                case let .operation(_, detail):
                    isHouseEvent = detail == house.houseID.rawValue
                        || detail.hasPrefix("\(house.houseID.rawValue)|")
                default:
                    isHouseEvent = false
                }
                guard event.origin == .familyTransition,
                      [.houseFounded, .houseMemberJoined, .houseMemberLeft]
                        .contains(event.kind),
                      event.sequence >= house.foundationEventID.sequence,
                      isHouseEvent else {
                    throw AgentFamilyError.invalidCausalReference(event.eventID)
                }
            }
            let activeMemberships = family.houseMembershipPeriods.filter {
                $0.houseID == house.houseID && $0.leftTick == nil
            }
            guard activeMemberships.count
                    <= family.configuration.maximumMembersPerHouse,
                  Set(activeMemberships.map(\.agentID)).count
                    == activeMemberships.count,
                  (house.status == .active) == activeMemberships.contains(where: {
                      active.contains($0.agentID)
                  }) else {
                throw AgentFamilyError.invalidState("house status or members")
            }
        }
        for membership in family.houseMembershipPeriods {
            guard houseIDs.contains(membership.houseID),
                  known.contains(membership.agentID),
                  membership.joinedTick >= 0,
                  membership.joinedTick <= clock.tick.rawValue else {
                throw AgentFamilyError.invalidState("house membership")
            }
            let joinedEvent = try retainedEvent(membership.joinedEventID)
            if let leftTick = membership.leftTick {
                guard let leftEventID = membership.leftEventID,
                      let endReason = membership.endReason,
                      leftTick >= membership.joinedTick,
                      leftTick <= clock.tick.rawValue else {
                    throw AgentFamilyError.invalidState("ended house membership")
                }
                let death = mortalityRecords.first {
                    $0.agentID == membership.agentID
                        && $0.deathTick == leftTick
                }
                if endReason == .memberDeath, death == nil {
                    throw AgentFamilyError.invalidState(
                        "member death exit without mortality"
                    )
                }
                if let event = try retainedEvent(leftEventID) {
                    guard event.kind == .houseMemberLeft,
                          event.origin == .familyTransition,
                          event.actorID == membership.agentID,
                          event.subjectID == membership.agentID,
                          event.simulationTick.rawValue == leftTick,
                          event.payload == .operation(
                              status: endReason.rawValue,
                              detail: membership.houseID.rawValue
                          ) else {
                        throw AgentFamilyError.invalidCausalReference(event.eventID)
                    }
                    switch endReason {
                    case .explicitAdultLeave:
                        guard let operationID = event.operationID?.rawValue,
                              family.processedInteractionReceiptIDs.contains(
                                  operationID
                              ),
                              event.causes.contains(membership.joinedEventID)
                        else {
                            throw AgentFamilyError.invalidCausalReference(
                                event.eventID
                            )
                        }
                    case .memberDeath:
                        guard event.operationID == nil, let death,
                              event.causes.contains(death.lethalDamageEventID)
                        else {
                            throw AgentFamilyError.invalidCausalReference(
                                event.eventID
                            )
                        }
                        if let lethal = try retainedEvent(
                            death.lethalDamageEventID
                        ) {
                            guard lethal.kind == .lethalHealthDepletion,
                                  lethal.actorID == membership.agentID,
                                  lethal.subjectID == membership.agentID,
                                  lethal.simulationTick.rawValue == leftTick else {
                                throw AgentFamilyError.invalidCausalReference(
                                    lethal.eventID
                                )
                            }
                        }
                    }
                }
            } else {
                guard membership.leftEventID == nil,
                      membership.endReason == nil,
                      active.contains(membership.agentID) else {
                    throw AgentFamilyError.invalidState("active house membership")
                }
            }
            switch membership.basis {
            case .founder:
                guard membership.explicitJoinConsent == nil,
                      let house = family.houses.first(where: {
                          $0.houseID == membership.houseID
                      }),
                      house.founderIDs.contains(membership.agentID),
                      membership.joinedTick == house.foundationTick else {
                    throw AgentFamilyError.invalidState("founder membership")
                }
                if let event = joinedEvent {
                    guard event.kind == .houseMemberJoined,
                          event.origin == .familyTransition,
                          event.actorID == membership.agentID,
                          event.subjectID == membership.agentID,
                          event.simulationTick.rawValue == membership.joinedTick,
                          event.causes == [house.foundationEventID],
                          event.payload == .operation(
                              status: membership.basis.rawValue,
                              detail: membership.houseID.rawValue
                          ) else {
                        throw AgentFamilyError.invalidCausalReference(event.eventID)
                    }
                }
            case .sharedParentHouseAtBirth:
                let parentage = kinship.parentageRecords.filter {
                    $0.childID == membership.agentID
                }
                guard membership.explicitJoinConsent == nil,
                      parentage.count == 1,
                      parentage[0].canonicalParentIDs.count == 2,
                      membership.joinedTick == parentage[0].birthTick,
                      family.houseMembershipPeriods.filter({
                          $0.agentID == membership.agentID
                              && $0.basis == .sharedParentHouseAtBirth
                      }).count == 1,
                      sharedParentalHouseAtBirth(
                          parentIDs: parentage[0].canonicalParentIDs,
                          tick: membership.joinedTick, family: family
                      ) == membership.houseID else {
                    throw AgentFamilyError.invalidState(
                        "child house membership"
                    )
                }
                if let event = joinedEvent {
                    guard event.kind == .houseMemberJoined,
                          event.origin == .familyTransition,
                          event.actorID == parentage[0].canonicalParentIDs[0],
                          event.subjectID == membership.agentID,
                          event.simulationTick.rawValue == membership.joinedTick,
                          event.causes == [parentage[0].recordedEventID],
                          event.payload == .operation(
                              status: membership.basis.rawValue,
                              detail: membership.houseID.rawValue
                          ) else {
                        throw AgentFamilyError.invalidCausalReference(event.eventID)
                    }
                }
            case .explicitAdultJoin:
                var consent = membership.explicitJoinConsent
                if consent == nil,
                   schemaVersion == AgentCheckpointSchema.familyVersion,
                   let event = joinedEvent,
                   event.causes.count == 2,
                   case let .operation(_, detail) = event.payload,
                   let acceptedByID = acceptedByID(
                       from: detail, houseID: membership.houseID
                   ),
                   let matureSinceTick = familyExpectedMatureSinceTick(
                       agentID: membership.agentID, lifecycle: lifecycle
                   ) {
                    let retainedCauses = try event.causes.compactMap {
                        try retainedEvent($0)
                    }
                    guard retainedCauses.count == 2,
                          let request = retainedCauses.first(where: { event in
                              guard event.actorID == membership.agentID,
                                    event.subjectID == acceptedByID,
                                    case let .operation(status, detail) =
                                      event.payload else {
                                  return false
                              }
                              return status == AgentFamilyInteractionKind
                                .houseJoinRequest.rawValue
                                  && familyInteractionPositionIsValid(detail)
                          }),
                          let acceptance = retainedCauses.first(where: { event in
                              guard event.actorID == acceptedByID,
                                    event.subjectID == membership.agentID,
                                    case let .operation(status, detail) =
                                      event.payload else {
                                  return false
                              }
                              return status == AgentFamilyInteractionKind
                                .houseJoinAcceptance.rawValue
                                  && familyInteractionPositionIsValid(detail)
                          }),
                          let requestOperationID =
                            request.operationID?.rawValue,
                          let acceptanceOperationID =
                            acceptance.operationID?.rawValue else {
                        throw AgentFamilyError.invalidCausalReference(
                            event.eventID
                        )
                    }
                    consent = AgentHouseJoinConsent(
                        acceptedByID: acceptedByID,
                        joiningMatureSinceTick: matureSinceTick,
                        request: AgentFamilyInteractionProof(
                            eventID: request.eventID,
                            operationID: requestOperationID,
                            kind: .houseJoinRequest,
                            actorID: membership.agentID,
                            counterpartyID: acceptedByID,
                            tick: membership.joinedTick
                        ),
                        acceptance: AgentFamilyInteractionProof(
                            eventID: acceptance.eventID,
                            operationID: acceptanceOperationID,
                            kind: .houseJoinAcceptance,
                            actorID: acceptedByID,
                            counterpartyID: membership.agentID,
                            tick: membership.joinedTick
                        )
                    )
                }
                guard let consent,
                      known.contains(consent.acceptedByID),
                      consent.acceptedByID != membership.agentID,
                      consent.request.eventID != consent.acceptance.eventID,
                      consent.request.operationID
                        != consent.acceptance.operationID,
                      family.houseMembershipPeriods.contains(where: {
                          $0.houseID == membership.houseID
                              && $0.agentID == consent.acceptedByID
                              && familyMembership(
                                  $0, isActiveAt: membership.joinedTick
                              )
                      }),
                      familyMaturityMatches(
                          agentID: membership.agentID,
                          joinedTick: membership.joinedTick,
                          matureSinceTick: consent.joiningMatureSinceTick,
                          lifecycle: lifecycle
                      ),
                      familyGroundingExists(
                          membership.agentID, consent.acceptedByID,
                          at: membership.joinedTick,
                          beforeEventID: membership.joinedEventID,
                          family: family,
                          parentageRecords: kinship.parentageRecords,
                          maximumDepth:
                            family.configuration.maximumProjectedAncestryDepth
                      ),
                      try interactionProofMatches(
                          consent.request, .houseJoinRequest,
                          membership.agentID, consent.acceptedByID,
                          membership.joinedTick, membership.joinedEventID
                      ),
                      try interactionProofMatches(
                          consent.acceptance, .houseJoinAcceptance,
                          consent.acceptedByID, membership.agentID,
                          membership.joinedTick, membership.joinedEventID
                      ) else {
                    throw AgentFamilyError.invalidState(
                        "explicit house join consent"
                    )
                }
                if let event = joinedEvent {
                    guard event.kind == .houseMemberJoined,
                          event.origin == .familyTransition,
                          event.actorID == membership.agentID,
                          event.subjectID == membership.agentID,
                          event.simulationTick.rawValue == membership.joinedTick,
                          event.causes == [
                              consent.request.eventID,
                              consent.acceptance.eventID
                          ].sorted(),
                          event.payload == .operation(
                              status: membership.basis.rawValue,
                              detail: "\(membership.houseID.rawValue)"
                                  + "|acceptedBy="
                                  + consent.acceptedByID.rawValue
                          ) else {
                        throw AgentFamilyError.invalidCausalReference(event.eventID)
                    }
                }
            }
        }
        for agentID in known {
            let activeByHouse = Dictionary(grouping:
                family.houseMembershipPeriods.filter {
                    $0.agentID == agentID && $0.leftTick == nil
                }, by: \.houseID
            )
            guard activeByHouse.values.allSatisfy({ $0.count == 1 }) else {
                throw AgentFamilyError.invalidState("duplicate active membership")
            }
        }
        for parentage in kinship.parentageRecords {
            let birthMemberships = family.houseMembershipPeriods.filter {
                $0.agentID == parentage.childID
                    && $0.basis == .sharedParentHouseAtBirth
            }
            let expectedHouseID = sharedParentalHouseAtBirth(
                parentIDs: parentage.canonicalParentIDs,
                tick: parentage.birthTick, family: family
            )
            guard birthMemberships.count == (expectedHouseID == nil ? 0 : 1),
                  birthMemberships.first?.houseID == expectedHouseID else {
                throw AgentFamilyError.invalidState(
                    "missing or unexpected child house membership"
                )
            }
        }
        guard Set(population.members.map(\.agentID)) == active,
              Set(lifecycle.members.map(\.agentID)) == active else {
            throw AgentFamilyError.invalidState("active authority mismatch")
        }
    }

    private static func familyUnionIsProhibited(
        _ lhs: AgentID,
        _ rhs: AgentID,
        parentageRecords: [AgentParentageRecord],
        maximumDepth: Int
    ) -> Bool {
        let parentageByChild = Dictionary(uniqueKeysWithValues:
            parentageRecords.map { ($0.childID, $0.canonicalParentIDs) }
        )
        if parentageByChild[lhs]?.contains(rhs) == true
            || parentageByChild[rhs]?.contains(lhs) == true {
            return true
        }
        let leftParents = Set(parentageByChild[lhs] ?? [])
        let rightParents = Set(parentageByChild[rhs] ?? [])
        if !leftParents.isEmpty, !rightParents.isEmpty,
           !leftParents.intersection(rightParents).isEmpty {
            return true
        }
        func ancestor(_ possible: AgentID, _ descendant: AgentID) -> Bool {
            var frontier = parentageByChild[descendant] ?? []
            var seen = Set<AgentID>()
            var depth = 1
            while !frontier.isEmpty, depth <= maximumDepth {
                let ordered = Array(Set(frontier)).sorted()
                if ordered.contains(possible) { return true }
                seen.formUnion(ordered)
                frontier = ordered.flatMap {
                    parentageByChild[$0] ?? []
                }.filter { !seen.contains($0) }
                depth += 1
            }
            return false
        }
        return ancestor(lhs, rhs) || ancestor(rhs, lhs)
    }

    private func validateAvailableMaturePerson(_ agentID: AgentID) throws {
        guard historicalPerson(for: agentID) != nil else {
            throw AgentSessionError.family(.unknownPerson(agentID))
        }
        guard lifecycleState?.members.first(where: {
            $0.agentID == agentID
        })?.currentStage == .mature else {
            throw AgentSessionError.family(.immaturePerson(agentID))
        }
        guard let state = statesById[agentID.rawValue], state.health > 0,
              !isPhysiologicallyIncapacitated(agentID),
              populationRegistry?.members.contains(where: {
                  $0.agentID == agentID
                      && ($0.status == .resident || $0.status == .founderResident)
              }) == true,
              !isMigratingAgent(agentID.rawValue) else {
            throw AgentSessionError.family(.unavailablePerson(agentID))
        }
    }

    private func validateUnionEligibility(
        _ lhs: AgentID,
        _ rhs: AgentID,
        family: AgentFamilyState
    ) throws {
        guard lhs != rhs else {
            throw AgentSessionError.family(.prohibitedUnion(lhs, rhs))
        }
        try validateAvailableMaturePerson(lhs)
        try validateAvailableMaturePerson(rhs)
        guard !family.unions.contains(where: {
            $0.status == .active && ($0.partnerIDs.contains(lhs) || $0.partnerIDs.contains(rhs))
        }) else {
            let occupied = family.unions.first {
                $0.status == .active
                    && ($0.partnerIDs.contains(lhs) || $0.partnerIDs.contains(rhs))
            }!.partnerIDs.first {
                $0 == lhs || $0 == rhs
            }!
            throw AgentSessionError.family(.activeUnionExists(occupied))
        }
        if (try? parents(of: lhs))??.contains(rhs) == true
            || (try? parents(of: rhs))??.contains(lhs) == true
            || isAncestor(lhs, of: rhs) == .ancestor
            || isAncestor(rhs, of: lhs) == .ancestor {
            throw AgentSessionError.family(.prohibitedUnion(lhs, rhs))
        }
        switch siblingRelation(between: lhs, and: rhs) {
        case .fullSibling, .halfSibling:
            throw AgentSessionError.family(.prohibitedUnion(lhs, rhs))
        default:
            break
        }
    }

    private mutating func consumeFamilyInteraction(
        _ receipt: AgentFamilyInteractionReceipt,
        expected: AgentFamilyInteractionKind,
        family: inout AgentFamilyState
    ) throws -> AgentCausalEventID {
        guard receipt.kind == expected,
              receipt.actorID != receipt.counterpartyID,
              receipt.observedTick == tick,
              receipt.communicationVerified,
              AgentOperationID(rawValue: receipt.receiptID) != nil,
              !family.processedInteractionReceiptIDs.contains(receipt.receiptID),
              statesById[receipt.actorID.rawValue]?.position == receipt.actorPosition,
              statesById[receipt.counterpartyID.rawValue]?.position
                == receipt.counterpartyPosition,
              abs(receipt.actorPosition.x - receipt.counterpartyPosition.x)
                + abs(receipt.actorPosition.y - receipt.counterpartyPosition.y)
                + abs(receipt.actorPosition.z - receipt.counterpartyPosition.z)
                <= family.configuration.maximumInteractionDistance else {
            if family.processedInteractionReceiptIDs.contains(receipt.receiptID) {
                throw AgentSessionError.family(.duplicateInteraction(receipt.receiptID))
            }
            throw AgentSessionError.family(.invalidInteraction(receipt.receiptID))
        }
        try validateAvailableMaturePerson(receipt.actorID)
        try validateAvailableMaturePerson(receipt.counterpartyID)
        try countFamilyTransitions(&family, count: 1)
        let event = try requiredFamilyEvent(
            kind: .familyInteractionVerified,
            actorID: receipt.actorID, subjectID: receipt.counterpartyID,
            operationID: receipt.receiptID, payloadStatus: expected.rawValue,
            detail: "\(receipt.actorPosition.x),\(receipt.actorPosition.y),\(receipt.actorPosition.z)",
            summary: "family interaction verified \(expected.rawValue)"
        )
        family.processedInteractionReceiptIDs.append(receipt.receiptID)
        family.processedInteractionReceiptIDs.sort()
        family.lastFamilyEventID = event.eventID
        return event.eventID
    }

    private mutating func endUnionInPlace(
        at index: Int,
        reason: AgentUnionTerminationReason,
        actorID: AgentID,
        causeEventIDs: [AgentCausalEventID],
        operationID: String?,
        family: inout AgentFamilyState,
        eventTick: Int? = nil
    ) throws {
        guard family.unions.indices.contains(index),
              family.unions[index].status == .active,
              family.unions[index].partnerIDs.contains(actorID) else {
            throw AgentSessionError.family(.invalidState("union end index"))
        }
        try countFamilyTransitions(&family, count: 1)
        let union = family.unions[index]
        let counterpartyID = union.partnerIDs.first { $0 != actorID }!
        let event = try requiredFamilyEvent(
            kind: .unionEnded, actorID: actorID,
            subjectID: counterpartyID, operationID: operationID,
            causes: Array(Set(causeEventIDs + [union.activationEventID])).sorted(),
            payloadStatus: reason.rawValue, detail: union.unionID.rawValue,
            summary: "union ended id=\(union.unionID.rawValue) reason=\(reason.rawValue)"
        )
        family.unions[index].status = .ended
        family.unions[index].terminationTick = eventTick ?? tick
        family.unions[index].terminationEventID = event.eventID
        family.unions[index].terminationReason = reason
        family.lastFamilyEventID = event.eventID
        updateFamilyDigest(
            &family, "union|\(union.unionID.rawValue)|ended|\(reason.rawValue)"
        )
    }

    private func familyMatureSinceTick(_ agentID: AgentID) throws -> Int {
        guard let lifecycle = lifecycleState,
              let member = lifecycle.members.first(where: {
                  $0.agentID == agentID
              }) else {
            throw AgentSessionError.family(.immaturePerson(agentID))
        }
        let remaining = max(
            0, lifecycle.configuration.maturityAgeTicks - member.initialAgeTicks
        )
        let (matureSince, overflow) = member.lifecycleRegisteredTick
            .addingReportingOverflow(remaining)
        guard !overflow, matureSince <= tick else {
            throw AgentSessionError.family(.immaturePerson(agentID))
        }
        return matureSince
    }

    private static func familyMembership(
        _ membership: AgentHouseMembershipPeriod,
        isActiveAt tick: Int
    ) -> Bool {
        membership.joinedTick <= tick
            && (membership.leftTick == nil || membership.leftTick! > tick)
    }

    private static func sharedParentalHouseAtBirth(
        parentIDs: [AgentID],
        tick: Int,
        family: AgentFamilyState
    ) -> AgentHouseID? {
        let parents = parentIDs.sorted()
        guard parents.count == 2, Set(parents).count == 2 else { return nil }
        let foundedHouseIDs = Set(family.houses.compactMap {
            $0.foundationTick <= tick ? $0.houseID : nil
        })
        func activeHouseIDs(for parentID: AgentID) -> Set<AgentHouseID> {
            Set(family.houseMembershipPeriods.compactMap {
                $0.agentID == parentID
                    && familyMembership($0, isActiveAt: tick)
                    && foundedHouseIDs.contains($0.houseID)
                    ? $0.houseID : nil
            })
        }
        let common = activeHouseIDs(for: parents[0])
            .intersection(activeHouseIDs(for: parents[1]))
            .sorted()
        return common.count == 1 ? common[0] : nil
    }

    private static func familyUnion(
        _ union: AgentUnionRecord,
        isActiveAt tick: Int,
        beforeEventID: AgentCausalEventID?
    ) -> Bool {
        guard union.activationTick <= tick else { return false }
        if union.activationTick == tick, let beforeEventID,
           union.activationEventID.sequence >= beforeEventID.sequence {
            return false
        }
        guard let terminationTick = union.terminationTick else { return true }
        if terminationTick > tick { return true }
        if terminationTick < tick { return false }
        guard let beforeEventID, let terminationEventID = union.terminationEventID else {
            return false
        }
        return beforeEventID.sequence < terminationEventID.sequence
    }

    private static func familyGroundingExists(
        _ lhs: AgentID,
        _ rhs: AgentID,
        at tick: Int,
        beforeEventID: AgentCausalEventID?,
        family: AgentFamilyState,
        parentageRecords: [AgentParentageRecord],
        maximumDepth: Int
    ) -> Bool {
        if family.unions.contains(where: {
            $0.partnerIDs == [lhs, rhs].sorted()
                && familyUnion($0, isActiveAt: tick, beforeEventID: beforeEventID)
        }) {
            return true
        }
        let parentageByChild = Dictionary(uniqueKeysWithValues:
            parentageRecords.map { ($0.childID, $0.canonicalParentIDs) }
        )
        if parentageByChild[lhs]?.contains(rhs) == true
            || parentageByChild[rhs]?.contains(lhs) == true {
            return true
        }
        let leftParents = Set(parentageByChild[lhs] ?? [])
        let rightParents = Set(parentageByChild[rhs] ?? [])
        if !leftParents.isEmpty, !rightParents.isEmpty,
           !leftParents.intersection(rightParents).isEmpty {
            return true
        }
        func ancestor(_ possible: AgentID, _ descendant: AgentID) -> Bool {
            var frontier = parentageByChild[descendant] ?? []
            var seen = Set<AgentID>()
            var depth = 1
            while !frontier.isEmpty, depth <= maximumDepth {
                let ordered = Array(Set(frontier)).sorted()
                if ordered.contains(possible) { return true }
                seen.formUnion(ordered)
                frontier = ordered.flatMap {
                    parentageByChild[$0] ?? []
                }.filter { !seen.contains($0) }
                depth += 1
            }
            return false
        }
        return ancestor(lhs, rhs) || ancestor(rhs, lhs)
    }

    private static func acceptedByID(
        from detail: String,
        houseID: AgentHouseID
    ) -> AgentID? {
        let prefix = "\(houseID.rawValue)|acceptedBy="
        guard detail.hasPrefix(prefix) else { return nil }
        let rawValue = String(detail.dropFirst(prefix.count))
        guard let agentID = AgentID(rawValue: rawValue),
              detail == prefix + agentID.rawValue else {
            return nil
        }
        return agentID
    }

    private static func familyInteractionPositionIsValid(_ detail: String) -> Bool {
        let coordinates = detail.split(
            separator: ",", omittingEmptySubsequences: false
        )
        return coordinates.count == 3 && coordinates.allSatisfy {
            Int($0) != nil
        }
    }

    private static func familyMaturityMatches(
        agentID: AgentID,
        joinedTick: Int,
        matureSinceTick: Int,
        lifecycle: AgentLifecycleState
    ) -> Bool {
        guard matureSinceTick >= 0, matureSinceTick <= joinedTick else {
            return false
        }
        if let expected = familyExpectedMatureSinceTick(
            agentID: agentID, lifecycle: lifecycle
        ) {
            return expected == matureSinceTick
        }
        // Lifecycle history is bounded. New schema-26 records retain the
        // validated eligibility boundary even after an honest old member or
        // birth prefix has been evicted.
        return true
    }

    private static func familyExpectedMatureSinceTick(
        agentID: AgentID,
        lifecycle: AgentLifecycleState
    ) -> Int? {
        if let member = lifecycle.members.first(where: {
            $0.agentID == agentID
        }) {
            let remaining = max(
                0,
                lifecycle.configuration.maturityAgeTicks - member.initialAgeTicks
            )
            let (expected, overflow) = member.lifecycleRegisteredTick
                .addingReportingOverflow(remaining)
            return overflow ? nil : expected
        }
        if let birth = lifecycle.births.first(where: {
            $0.newbornID == agentID
        }) {
            let (expected, overflow) = birth.birthTick.addingReportingOverflow(
                lifecycle.configuration.maturityAgeTicks
            )
            return overflow ? nil : expected
        }
        return nil
    }

    private mutating func countFamilyTransitions(
        _ family: inout AgentFamilyState,
        count: Int
    ) throws {
        let existing = family.transitionTick == tick ? family.transitionsAtTick : 0
        guard count >= 0,
              existing + count <= family.configuration.maximumTransitionsPerTick else {
            throw AgentSessionError.family(.transitionCapacityReached)
        }
        family.transitionTick = tick
        family.transitionsAtTick = existing + count
    }

    private mutating func refreshHouseStatus(
        _ houseID: AgentHouseID,
        family: inout AgentFamilyState,
        causeEventID: AgentCausalEventID,
        excludingLivingID: AgentID? = nil
    ) {
        guard let index = family.houses.firstIndex(where: { $0.houseID == houseID }) else {
            return
        }
        let living = family.houseMembershipPeriods.contains {
            $0.houseID == houseID && $0.leftTick == nil
                && $0.agentID != excludingLivingID
                && statesById[$0.agentID.rawValue] != nil
        }
        family.houses[index].status = living ? .active : .inactiveHistorical
        family.houses[index].lastEventID = causeEventID
    }

    private mutating func requiredFamilyEvent(
        kind: AgentCausalEventKind,
        actorID: AgentID? = nil,
        subjectID: AgentID? = nil,
        operationID: String? = nil,
        causes: [AgentCausalEventID] = [],
        payloadStatus: String,
        detail: String,
        summary: String
    ) throws -> AgentCausalEvent {
        let event = try recordCausalEvent(
            kind: kind, origin: .familyTransition,
            actorID: actorID, subjectID: subjectID,
            operationID: operationID.flatMap(AgentOperationID.init(rawValue:)),
            causes: causes,
            payload: .operation(status: payloadStatus, detail: detail),
            summary: summary
        )
        guard let event else {
            throw AgentSessionError.family(.causalLedgerRequired)
        }
        return event
    }

    private func familyStateDigest(_ family: AgentFamilyState) -> String {
        let proposals = family.proposals.map {
            "\($0.proposalID.rawValue):\($0.status.rawValue)"
        }.joined(separator: ",")
        let unions = family.unions.map {
            "\($0.unionID.rawValue):\($0.partnerIDs.map(\.rawValue).joined(separator: "+")):\($0.status.rawValue)"
        }.joined(separator: ",")
        let lineages = family.lineages.map {
            "\($0.lineageID.rawValue):\($0.rootPersonID.rawValue)"
        }.joined(separator: ",")
        let houses = family.houses.map {
            "\($0.houseID.rawValue):\($0.status.rawValue)"
        }.joined(separator: ",")
        let memberships = family.houseMembershipPeriods.map {
            "\($0.houseID.rawValue):\($0.agentID.rawValue):\($0.basis.rawValue):\($0.leftTick.map(String.init) ?? "-")"
        }.joined(separator: ",")
        return AgentFamilyDigest.make(
            "\(family.rollingDigest)|\(proposals)|\(unions)|\(lineages)|\(houses)|\(memberships)"
        )
    }

    private mutating func updateFamilyDigest(
        _ family: inout AgentFamilyState,
        _ text: String
    ) {
        family.rollingDigest = AgentFamilyDigest.make(
            "\(family.rollingDigest)|\(text)|\(tick)"
        )
    }

    private func familyHouseMembershipSort(
        _ lhs: AgentHouseMembershipPeriod,
        _ rhs: AgentHouseMembershipPeriod
    ) -> Bool {
        if lhs.houseID != rhs.houseID { return lhs.houseID < rhs.houseID }
        if lhs.agentID != rhs.agentID { return lhs.agentID < rhs.agentID }
        if lhs.joinedTick != rhs.joinedTick { return lhs.joinedTick < rhs.joinedTick }
        return lhs.joinedEventID < rhs.joinedEventID
    }

    private func familyRelationSort(
        _ lhs: AgentFamilyRelation,
        _ rhs: AgentFamilyRelation
    ) -> Bool {
        if lhs.kind.rawValue != rhs.kind.rawValue {
            return lhs.kind.rawValue < rhs.kind.rawValue
        }
        if lhs.relatedPersonID != rhs.relatedPersonID {
            return lhs.relatedPersonID < rhs.relatedPersonID
        }
        return lhs.sourceEventID < rhs.sourceEventID
    }

    private func ancestryRelations(
        from agentID: AgentID,
        parentageByChild: [AgentID: AgentParentageRecord],
        parentageRecords: [AgentParentageRecord],
        maximumDepth: Int
    ) -> [AgentFamilyRelation] {
        var rows: [AgentFamilyRelation] = []
        var ancestorFrontier: [(AgentID, AgentCausalEventID)] =
            parentageByChild[agentID]?.canonicalParentIDs.map {
                ($0, parentageByChild[agentID]!.recordedEventID)
            } ?? []
        var seenAncestors = Set<AgentID>()
        var depth = 1
        while !ancestorFrontier.isEmpty, depth <= maximumDepth {
            let ordered = ancestorFrontier.sorted { $0.0 < $1.0 }
                .filter { !seenAncestors.contains($0.0) }
            seenAncestors.formUnion(ordered.map(\.0))
            if depth >= 2 {
                rows += ordered.map {
                    AgentFamilyRelation(
                        kind: depth == 2 ? .grandparent : .ancestor,
                        personID: agentID, relatedPersonID: $0.0,
                        source: .ancestryPath, sourceEventID: $0.1, depth: depth
                    )
                }
            }
            ancestorFrontier = ordered.flatMap { entry in
                parentageByChild[entry.0]?.canonicalParentIDs.map {
                    ($0, parentageByChild[entry.0]!.recordedEventID)
                } ?? []
            }
            depth += 1
        }
        let childrenByParent = Dictionary(grouping: parentageRecords.flatMap {
            record in record.canonicalParentIDs.map {
                ($0, record.childID, record.recordedEventID)
            }
        }, by: \.0).mapValues { $0.map { ($0.1, $0.2) } }
        var descendantFrontier = childrenByParent[agentID] ?? []
        var seenDescendants = Set<AgentID>()
        depth = 1
        while !descendantFrontier.isEmpty, depth <= maximumDepth {
            let ordered = descendantFrontier.sorted { $0.0 < $1.0 }
                .filter { !seenDescendants.contains($0.0) }
            seenDescendants.formUnion(ordered.map(\.0))
            if depth >= 2 {
                rows += ordered.map {
                    AgentFamilyRelation(
                        kind: depth == 2 ? .grandchild : .descendant,
                        personID: agentID, relatedPersonID: $0.0,
                        source: .ancestryPath, sourceEventID: $0.1, depth: depth
                    )
                }
            }
            descendantFrontier = ordered.flatMap {
                childrenByParent[$0.0] ?? []
            }
            depth += 1
        }
        return rows
    }
}
