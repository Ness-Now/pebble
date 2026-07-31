extension AgentSimulationSession {
    public var estatesEnabled: Bool { estateState != nil }

    public func estateSnapshot() -> AgentEstateSnapshot {
        guard let estate = estateState else {
            return AgentEstateSnapshot(
                enabled: false, activationTick: nil, configuration: nil,
                estates: [], totalEstateCount: 0, totalSettlementCount: 0,
                evictionCounts: AgentEstateEvictionCounts(),
                digest: AgentEstateDigest.make("disabled")
            )
        }
        return AgentEstateSnapshot(
            enabled: true, activationTick: estate.activationTick,
            configuration: estate.configuration,
            estates: estate.estates.sorted { $0.estateID < $1.estateID },
            totalEstateCount: estate.totalEstateCount,
            totalSettlementCount: estate.totalSettlementCount,
            evictionCounts: estate.evictionCounts,
            digest: Self.estateStateDigest(estate)
        )
    }

    public mutating func setEstatesEnabled(
        _ enabled: Bool,
        configuration: AgentEstateConfiguration = .live
    ) throws {
        var candidate = self
        try candidate.setEstatesEnabledInPlace(enabled, configuration: configuration)
        self = candidate
    }

    private mutating func setEstatesEnabledInPlace(
        _ enabled: Bool,
        configuration: AgentEstateConfiguration
    ) throws {
        guard enabled else {
            guard estateState == nil else {
                throw AgentSessionError.estate(.unsafeDisable)
            }
            return
        }
        guard estateState == nil else {
            throw AgentSessionError.estate(.alreadyEnabled)
        }
        guard causalLedger.isEnabled else {
            throw AgentSessionError.estate(.causalLedgerRequired)
        }
        guard let mortality = mortalityState,
              mortality.configuration.requiresTerminalPhysicalCustodyVerification else {
            throw AgentSessionError.estate(.mortalityRequired)
        }
        guard configuration.maximumRetainedEstates
                <= mortality.configuration.maximumRetainedDeathRecords else {
            throw AgentSessionError.estate(.invalidConfiguration(
                "retained estates exceed retained death records"
            ))
        }
        guard materialRightsState != nil else {
            throw AgentSessionError.estate(.materialRightsRequired)
        }
        guard lifecycleState != nil else {
            throw AgentSessionError.estate(.lifecycleRequired)
        }
        guard kinshipState != nil else {
            throw AgentSessionError.estate(.kinshipRequired)
        }
        guard householdState != nil else {
            throw AgentSessionError.estate(.householdsRequired)
        }
        guard dependentCareState?.childhoodV2 != nil else {
            throw AgentSessionError.estate(.childhoodRequired)
        }
        guard familyState != nil else {
            throw AgentSessionError.estate(.familyRequired)
        }
        try prevalidateCausalAppend(count: 1)
        let event = try requiredEstateEvent(
            kind: .estatesInitialized,
            payload: .feature(name: "estates", enabled: true),
            summary: "estates initialized historicalDeaths=\(mortality.totalDeathCount)"
        )
        var authority = AgentEstateState(
            configuration: configuration,
            activationTick: tick,
            activationDeathCount: mortality.totalDeathCount,
            initializedEventID: event.eventID,
            estates: [],
            processedOperationIDs: [],
            transitionTick: tick,
            transitionsAtTick: 1,
            totalEstateCount: 0,
            totalSettlementCount: 0,
            evictionCounts: AgentEstateEvictionCounts(),
            rollingDigest: AgentEstateDigest.make(
                "initialized|\(simulationID.rawValue)|\(tick)|"
                    + "\(mortality.totalDeathCount)|\(event.eventID.rawValue)"
            ),
            lastEventID: event.eventID
        )
        authority.rollingDigest = Self.estateStateDigest(authority)
        estateState = authority
    }

    @discardableResult
    public mutating func acceptEstateAdministration(
        estateID: AgentEstateID,
        administratorID: AgentID,
        operationID: String
    ) throws -> AgentEstateAdministration {
        var candidate = self
        let assignment = try candidate.acceptEstateAdministrationInPlace(
            estateID: estateID,
            administratorID: administratorID,
            operationID: operationID
        )
        self = candidate
        return assignment
    }

    private mutating func acceptEstateAdministrationInPlace(
        estateID: AgentEstateID,
        administratorID: AgentID,
        operationID: String
    ) throws -> AgentEstateAdministration {
        guard var authority = estateState else {
            throw AgentSessionError.estate(.disabled)
        }
        guard validEstateOperationID(operationID),
              !authority.processedOperationIDs.contains(operationID),
              authority.processedOperationIDs.count
                < authority.configuration.maximumProcessedOperationIDs else {
            throw AgentSessionError.estate(.invalidAcceptance(operationID))
        }
        guard let estateIndex = authority.estates.firstIndex(where: {
            $0.estateID == estateID
        }) else {
            throw AgentSessionError.estate(.unknownEstate(estateID))
        }
        guard !authority.estates[estateIndex].status.isTerminal,
              let administrationIndex = authority.estates[estateIndex]
                .administrations.lastIndex(where: {
                    $0.status == .nominated
                        && $0.administratorID == administratorID
                }),
              estateAdministratorIsAvailable(administratorID) else {
            throw AgentSessionError.estate(.invalidAdministrator(administratorID))
        }
        try prevalidateEstateTransitions(&authority, count: 1, at: tick)
        let nomination = authority.estates[estateIndex]
            .administrations[administrationIndex]
        let event = try requiredEstateEvent(
            kind: .estateAdministratorAccepted,
            actorID: administratorID,
            subjectID: authority.estates[estateIndex].decedentID,
            operationID: AgentOperationID(rawValue: operationID),
            causes: [nomination.nominationEventID],
            payload: .operation(
                status: "accepted",
                detail: estateID.rawValue
            ),
            summary: "estate administrator accepted estate=\(estateID.rawValue) "
                + "administrator=\(administratorID.rawValue)"
        )
        authority.estates[estateIndex].administrations[administrationIndex]
            .acceptedAtTick = tick
        authority.estates[estateIndex].administrations[administrationIndex]
            .acceptanceOperationID = operationID
        authority.estates[estateIndex].administrations[administrationIndex]
            .acceptanceEventID = event.eventID
        authority.estates[estateIndex].administrations[administrationIndex]
            .status = .active
        if authority.estates[estateIndex].status != .blocked,
           authority.estates[estateIndex].status != .dormantNoSuccessor {
            authority.estates[estateIndex].status = .openAdministered
        }
        authority.estates[estateIndex].lastEventID = event.eventID
        authority.processedOperationIDs.append(operationID)
        authority.processedOperationIDs.sort()
        authority.lastEventID = event.eventID
        authority.rollingDigest = Self.estateStateDigest(authority)
        estateState = authority
        return authority.estates[estateIndex].administrations[administrationIndex]
    }

    @discardableResult
    public mutating func applyEstatePhysicalSettlement(
        _ outcome: AgentEstatePhysicalSettlementOutcome
    ) throws -> AgentEstateAssetEntry {
        var candidate = self
        let result = try candidate.applyEstatePhysicalSettlementInPlace(outcome)
        self = candidate
        return result
    }

    private mutating func applyEstatePhysicalSettlementInPlace(
        _ outcome: AgentEstatePhysicalSettlementOutcome
    ) throws -> AgentEstateAssetEntry {
        guard var authority = estateState, var rights = materialRightsState else {
            throw AgentSessionError.estate(.disabled)
        }
        guard validEstateOperationID(outcome.operationID),
              !authority.processedOperationIDs.contains(outcome.operationID),
              authority.processedOperationIDs.count
                < authority.configuration.maximumProcessedOperationIDs,
              !outcome.sourceFingerprintAfterTransfer.isEmpty,
              !outcome.destinationFingerprintBeforeTransfer.isEmpty,
              outcome.physicalReceiptID == outcome.destinationObservation.physicalReceiptID,
              outcome.destinationObservation.observedAtTick == tick,
              outcome.sourceObservation.holder
                != outcome.destinationObservation.holder,
              outcome.sourceObservation.materialIdentity
                == outcome.destinationObservation.materialIdentity,
              outcome.sourceObservation.quantity
                == outcome.destinationObservation.quantity else {
            throw AgentSessionError.estate(.invalidSettlement(outcome.operationID))
        }
        guard let estateIndex = authority.estates.firstIndex(where: {
            $0.estateID == outcome.estateID
        }), !authority.estates[estateIndex].status.isTerminal else {
            throw AgentSessionError.estate(.unknownEstate(outcome.estateID))
        }
        guard let entryIndex = authority.estates[estateIndex].assets.firstIndex(where: {
            $0.entryID == outcome.entryID
        }) else {
            throw AgentSessionError.estate(.unknownAsset(outcome.entryID))
        }
        let estate = authority.estates[estateIndex]
        let entry = estate.assets[entryIndex]
        guard entry.status == .pendingSettlement,
              entry.settlementAttemptCount
                < authority.configuration.maximumSettlementAttemptsPerAsset,
              entry.assignedBeneficiaryID == outcome.beneficiaryID,
              estate.beneficiaries.contains(where: {
                  $0.agentID == outcome.beneficiaryID
              }),
              let administration = estate.administrations.last(where: {
                  $0.status == .active
              }),
              administration.administratorID == outcome.administratorID,
              administration.acceptanceEventID != nil,
              estateAdministratorIsAvailable(outcome.administratorID),
              let materialAssetID = entry.materialRightsAssetID,
              let rightsIndex = rights.records.firstIndex(where: {
                  $0.asset.assetID == materialAssetID
              }),
              rights.records[rightsIndex].lastVerifiedHolder
                == outcome.sourceObservation,
              rights.records[rightsIndex].asset.materialIdentity
                == outcome.sourceObservation.materialIdentity,
              rights.records[rightsIndex].asset.quantity
                == outcome.sourceObservation.quantity,
              rights.records[rightsIndex].recognizedOwnership?.ownerID
                == estate.decedentID,
              rights.records[rightsIndex].claims.allSatisfy({
                  $0.claimantID == estate.decedentID
              }) else {
            throw AgentSessionError.estate(.invalidSettlement(
                "authority or rights mismatch"
            ))
        }
        try validateEstateCustodyDestination(
            beneficiaryID: outcome.beneficiaryID,
            intendedCustodianID: outcome.intendedCustodianID,
            destination: outcome.destinationObservation
        )
        try prevalidateEstateTransitions(&authority, count: 4, at: tick)
        let started = try requiredEstateEvent(
            kind: .estateAssetTransferStarted,
            actorID: outcome.administratorID,
            subjectID: outcome.beneficiaryID,
            operationID: AgentOperationID(rawValue: outcome.operationID),
            causes: [
                administration.acceptanceEventID!,
                entry.classificationEventID ?? estate.successorPlanEventID,
            ].sorted(),
            payload: .operation(
                status: "started",
                detail: "\(outcome.estateID.rawValue)|\(outcome.entryID.rawValue)"
            ),
            summary: "estate asset transfer started estate="
                + "\(outcome.estateID.rawValue) entry=\(outcome.entryID.rawValue)"
        )

        let sourceHolder = outcome.sourceObservation.holder
        let destinationHolder = outcome.destinationObservation.holder
        for index in rights.records.indices
            where rights.records[index].asset.assetID != materialAssetID {
            let observation = rights.records[index].lastVerifiedHolder
            if observation.holder == sourceHolder,
               observation.custodyFingerprint
                == outcome.sourceObservation.custodyFingerprint {
                rights.records[index].lastVerifiedHolder =
                    AgentMaterialHolderObservation(
                        holder: observation.holder,
                        materialIdentity: observation.materialIdentity,
                        quantity: observation.quantity,
                        custodyFingerprint:
                            outcome.sourceFingerprintAfterTransfer,
                        physicalReceiptID: outcome.physicalReceiptID,
                        observedAtTick: tick
                    )
            } else if observation.holder == destinationHolder,
                      observation.custodyFingerprint
                        == outcome.destinationFingerprintBeforeTransfer {
                let refreshed = AgentMaterialHolderObservation(
                        holder: observation.holder,
                        materialIdentity: observation.materialIdentity,
                        quantity: observation.quantity,
                        custodyFingerprint:
                            outcome.destinationObservation.custodyFingerprint,
                        physicalReceiptID: outcome.physicalReceiptID,
                        observedAtTick: tick
                    )
                rights.records[index].lastVerifiedHolder = refreshed
                for otherEstateIndex in authority.estates.indices {
                    for otherEntryIndex in authority.estates[
                        otherEstateIndex
                    ].assets.indices
                        where authority.estates[otherEstateIndex]
                            .assets[otherEntryIndex]
                            .materialRightsAssetID
                            == rights.records[index].asset.assetID
                            && authority.estates[otherEstateIndex]
                                .assets[otherEntryIndex].status
                                == .transferred {
                        authority.estates[otherEstateIndex]
                            .assets[otherEntryIndex]
                            .destinationObservation = refreshed
                    }
                }
            }
        }
        rights.records[rightsIndex].lastVerifiedHolder =
            outcome.destinationObservation
        rights.records[rightsIndex].custodianID =
            outcome.intendedCustodianID == outcome.beneficiaryID
                ? nil : outcome.intendedCustodianID
        rights.records[rightsIndex].permissions.removeAll {
            $0.userID == estate.decedentID
        }
        rights.records[rightsIndex].claims.removeAll {
            $0.claimantID == estate.decedentID
        }
        let inheritanceClaimText = "inheritance-"
            + "\(outcome.estateID.rawValue)-\(materialAssetID.rawValue)"
        guard let inheritanceClaimID = AgentMaterialClaimID(
            rawValue: String(inheritanceClaimText.prefix(192))
        ), rights.records[rightsIndex].claims.count
            < rights.configuration.maximumClaimsPerAsset else {
            throw AgentSessionError.estate(.invalidSettlement(
                "inheritance claim"
            ))
        }
        rights.records[rightsIndex].claims.append(AgentMaterialClaim(
            claimID: inheritanceClaimID,
            claimantID: outcome.beneficiaryID,
            basis: .received,
            assertedAtTick: tick
        ))
        rights.records[rightsIndex].claims.sort { $0.claimID < $1.claimID }
        rights.records[rightsIndex].recognizedOwnership =
            AgentMaterialRecognizedOwnership(
                claimID: inheritanceClaimID,
                ownerID: outcome.beneficiaryID,
                recognizingAgentIDs: [outcome.administratorID],
                recognizedAtTick: tick
            )
        let transferred = try requiredEstateEvent(
            kind: .estateAssetTransferred,
            actorID: outcome.administratorID,
            subjectID: outcome.beneficiaryID,
            operationID: AgentOperationID(rawValue: outcome.operationID),
            causes: [started.eventID],
            payload: .operation(
                status: "physicalReceipt",
                detail: outcome.physicalReceiptID
            ),
            summary: "estate asset physically transferred receipt="
                + outcome.physicalReceiptID
        )
        let settled = try requiredEstateEvent(
            kind: .estateAssetSettled,
            actorID: outcome.administratorID,
            subjectID: outcome.beneficiaryID,
            operationID: AgentOperationID(rawValue: outcome.operationID),
            causes: [transferred.eventID],
            payload: .operation(
                status: "transferred",
                detail: "\(outcome.estateID.rawValue)|\(outcome.entryID.rawValue)"
            ),
            summary: "estate asset settled estate=\(outcome.estateID.rawValue) "
                + "entry=\(outcome.entryID.rawValue)"
        )
        let rightsOperationID = outcome.operationID + ":rights"
        guard !rights.processedOperationIDs.contains(rightsOperationID) else {
            throw AgentSessionError.estate(.invalidSettlement(
                "reused Material Rights operation"
            ))
        }
        rights.processedOperationIDs.append(rightsOperationID)
        if rights.processedOperationIDs.count
            > rights.configuration.maximumProcessedOperationIDs {
            rights.processedOperationIDs.removeFirst()
            rights.droppedOperationIDCount += 1
        }
        rights.recentTransitions.append(AgentMaterialRightsTransition(
            operationID: rightsOperationID,
            kind: .physicalTransfer,
            assetID: materialAssetID,
            status: "succeeded",
            reason: "verified inheritance custody and ownership settlement",
            eventID: settled.eventID
        ))
        if rights.recentTransitions.count
            > rights.configuration.maximumRetainedTransitions {
            rights.recentTransitions.removeFirst()
            rights.droppedTransitionCount += 1
        }
        authority.estates[estateIndex].assets[entryIndex].status = .transferred
        authority.estates[estateIndex].assets[entryIndex].blockReason = nil
        authority.estates[estateIndex].assets[entryIndex]
            .settlementAttemptCount += 1
        authority.estates[estateIndex].assets[entryIndex]
            .destinationObservation = outcome.destinationObservation
        authority.estates[estateIndex].assets[entryIndex]
            .settlementObservation = outcome.destinationObservation
        authority.estates[estateIndex].assets[entryIndex]
            .settlementReceiptID = outcome.physicalReceiptID
        authority.estates[estateIndex].assets[entryIndex]
            .settlementEventID = settled.eventID
        if let beneficiaryIndex = authority.estates[estateIndex]
            .beneficiaries.firstIndex(where: {
                $0.agentID == outcome.beneficiaryID
            }) {
            authority.estates[estateIndex].beneficiaries[beneficiaryIndex]
                .allocationCount += 1
        }
        authority.estates[estateIndex].lastEventID = settled.eventID
        authority.processedOperationIDs.append(outcome.operationID)
        authority.processedOperationIDs.sort()
        authority.lastEventID = settled.eventID
        materialRightsState = rights
        if authority.estates[estateIndex].assets.allSatisfy(\.status.isTerminal) {
            let final = try requiredEstateEvent(
                kind: .estateSettled,
                actorID: outcome.administratorID,
                subjectID: authority.estates[estateIndex].decedentID,
                causes: [settled.eventID],
                payload: .operation(
                    status: "settled",
                    detail: outcome.estateID.rawValue
                ),
                summary: "estate settled estate=\(outcome.estateID.rawValue)"
            )
            authority.estates[estateIndex].status = .settled
            authority.estates[estateIndex].settledAtTick = tick
            authority.estates[estateIndex].settledEventID = final.eventID
            authority.estates[estateIndex].lastEventID = final.eventID
            authority.lastEventID = final.eventID
            authority.totalSettlementCount += 1
            for index in authority.estates[estateIndex].administrations.indices
                where authority.estates[estateIndex].administrations[index].status
                    == .active {
                authority.estates[estateIndex].administrations[index].status = .ended
                authority.estates[estateIndex].administrations[index].endedAtTick = tick
                authority.estates[estateIndex].administrations[index].endedReason =
                    .estateSettled
                authority.estates[estateIndex].administrations[index].endedEventID =
                    final.eventID
            }
        } else {
            authority.estates[estateIndex].status = .partiallySettled
        }
        authority.rollingDigest = Self.estateStateDigest(authority)
        estateState = authority
        return authority.estates[estateIndex].assets[entryIndex]
    }

    mutating func openEstateForMortality(
        decedentID: AgentID,
        deathID: AgentDeathID,
        lethalAgentIDs: Set<AgentID>,
        physicalCustodyResolution: AgentMortalityPhysicalCustodyResolution,
        causeEventID: AgentCausalEventID,
        at deathTick: Int
    ) throws -> AgentEstateID? {
        guard var authority = estateState else { return nil }
        guard physicalCustodyResolution.verifiedAtTick == deathTick,
              physicalCustodyResolution.physicalAssets != nil,
              physicalCustodyResolution.stackCount
                == physicalCustodyResolution.physicalAssets?.count,
              physicalCustodyResolution.itemCount
                == physicalCustodyResolution.physicalAssets?
                    .reduce(0, { $0 + $1.count }),
              !authority.estates.contains(where: {
                  $0.deathID == deathID || $0.decedentID == decedentID
              }) else {
            throw AgentSessionError.estate(.invalidState(
                "physical custody or duplicate death"
            ))
        }
        guard authority.estates.filter({
            !$0.status.isTerminal
        }).count < authority.configuration.maximumOpenEstates else {
            throw AgentSessionError.estate(.capacityExceeded("estates"))
        }
        if authority.estates.count
            == authority.configuration.maximumRetainedEstates {
            guard let evictionIndex = authority.estates.indices
                .filter({ authority.estates[$0].status.isTerminal })
                .min(by: {
                    let lhs = authority.estates[$0]
                    let rhs = authority.estates[$1]
                    return lhs.deathTick == rhs.deathTick
                        ? lhs.estateID < rhs.estateID
                        : lhs.deathTick < rhs.deathTick
                }) else {
                throw AgentSessionError.estate(.capacityExceeded("estates"))
            }
            authority.estates.remove(at: evictionIndex)
            authority.evictionCounts.settledEstates += 1
        }
        let digest = AgentEstateDigest.make(
            "\(simulationID.rawValue)|\(decedentID.rawValue)|"
                + "\(deathID.rawValue)|27"
        )
        let estateID = AgentEstateID(
            rawValue: "estate-\(digest)"
        )!
        let partnerID = familyState?.unions.first(where: {
            $0.status == .active && $0.partnerIDs.contains(decedentID)
        })?.partnerIDs.first { $0 != decedentID }
        let plan = try estateBeneficiaryPlan(
            decedentID: decedentID,
            activePartnerID: partnerID,
            lethalAgentIDs: lethalAgentIDs
        )
        var assets = try estateAssetsAtOpening(
            estateID: estateID,
            decedentID: decedentID,
            physicalCustodyResolution: physicalCustodyResolution,
            beneficiaries: plan.beneficiaries
        )
        guard assets.count <= authority.configuration.maximumAssetsPerEstate else {
            throw AgentSessionError.estate(.capacityExceeded("assets"))
        }
        let allAssetsTerminal = assets.allSatisfy(\.status.isTerminal)
        let nomination = allAssetsTerminal ? nil
            : try estateAdministratorNomination(
                decedentID: decedentID,
                activePartnerID: partnerID,
                lethalAgentIDs: lethalAgentIDs
            )
        try prevalidateEstateTransitions(
            &authority,
            count: 2 + assets.count + (nomination == nil ? 0 : 1)
                + (allAssetsTerminal ? 1 : 0),
            at: deathTick
        )
        let opened = try requiredEstateEvent(
            kind: .estateOpened,
            actorID: decedentID,
            subjectID: decedentID,
            causes: [physicalCustodyResolution.eventID, causeEventID].sorted(),
            payload: .operation(
                status: "opened",
                detail: "\(estateID.rawValue)|\(deathID.rawValue)"
            ),
            summary: "estate opened estate=\(estateID.rawValue) "
                + "decedent=\(decedentID.rawValue)"
        )
        let planEvent = try requiredEstateEvent(
            kind: .estateSuccessorPlanCreated,
            subjectID: decedentID,
            causes: [opened.eventID],
            payload: .operation(
                status: plan.tier.rawValue,
                detail: plan.beneficiaries.map {
                    $0.agentID.rawValue
                }.joined(separator: ",")
            ),
            summary: "estate successor plan estate=\(estateID.rawValue) "
                + "tier=\(plan.tier.rawValue) beneficiaries="
                + "\(plan.beneficiaries.count)"
        )
        for index in assets.indices {
            let event = try requiredEstateEvent(
                kind: assets[index].status == .blocked
                    ? .estateAssetBlocked : .estateAssetClassified,
                subjectID: decedentID,
                causes: [opened.eventID],
                payload: .operation(
                    status: assets[index].status.rawValue,
                    detail: assets[index].entryID.rawValue
                ),
                summary: "estate asset \(assets[index].status.rawValue) "
                    + "entry=\(assets[index].entryID.rawValue)"
            )
            assets[index].classificationEventID = event.eventID
        }
        var administrations: [AgentEstateAdministration] = []
        var lastEventID = planEvent.eventID
        if let nomination {
            let event = try requiredEstateEvent(
                kind: .estateAdministratorNominated,
                actorID: nomination.agentID,
                subjectID: decedentID,
                causes: [opened.eventID],
                payload: .operation(
                    status: "nominated",
                    detail: "\(estateID.rawValue)|\(nomination.basis.rawValue)"
                ),
                summary: "estate administrator nominated estate="
                    + "\(estateID.rawValue) candidate=\(nomination.agentID.rawValue)"
            )
            administrations = [AgentEstateAdministration(
                administratorID: nomination.agentID,
                basis: nomination.basis,
                nominatedAtTick: deathTick,
                lifeStageAtNomination: .mature,
                nominationEventID: event.eventID,
                acceptedAtTick: nil,
                acceptanceOperationID: nil,
                acceptanceEventID: nil,
                endedAtTick: nil,
                endedReason: nil,
                endedEventID: nil,
                status: .nominated
            )]
            lastEventID = event.eventID
        }
        var status: AgentEstateStatus
        if allAssetsTerminal {
            status = .settled
        } else if plan.beneficiaries.isEmpty {
            status = .dormantNoSuccessor
        } else if assets.contains(where: { $0.status == .blocked }) {
            status = .blocked
        } else {
            status = .openUnadministered
        }
        var settledEventID: AgentCausalEventID?
        if allAssetsTerminal {
            let settled = try requiredEstateEvent(
                kind: .estateSettled,
                subjectID: decedentID,
                causes: (
                    [planEvent.eventID]
                        + assets.compactMap(\.classificationEventID)
                ).sorted(),
                payload: .operation(
                    status: assets.isEmpty
                        ? "settledEmpty" : "settledNonTransferable",
                    detail: estateID.rawValue
                ),
                summary: "empty estate settled estate=\(estateID.rawValue)"
            )
            settledEventID = settled.eventID
            lastEventID = settled.eventID
            authority.totalSettlementCount += 1
        }
        authority.estates.append(AgentEstateRecord(
            estateID: estateID,
            decedentID: decedentID,
            deathID: deathID,
            deathTick: deathTick,
            schemaVersion: 1,
            physicalCustodyResolution: physicalCustodyResolution,
            openedAtTick: deathTick,
            openingEventID: opened.eventID,
            successorPlanEventID: planEvent.eventID,
            beneficiaryTier: plan.tier,
            status: status,
            deathEventID: nil,
            administrations: administrations,
            beneficiaries: plan.beneficiaries,
            assets: assets,
            obligations: [],
            settledAtTick: allAssetsTerminal ? deathTick : nil,
            settledEventID: settledEventID,
            lastEventID: lastEventID
        ))
        authority.estates.sort { $0.estateID < $1.estateID }
        authority.totalEstateCount += 1
        authority.lastEventID = lastEventID
        authority.rollingDigest = Self.estateStateDigest(authority)
        // Personal permissions used by the decedent end with the person.
        if var rights = materialRightsState {
            for index in rights.records.indices {
                rights.records[index].permissions.removeAll {
                    $0.userID == decedentID
                }
                let recognizedClaimID =
                    rights.records[index].recognizedOwnership?.claimID
                rights.records[index].claims.removeAll {
                    $0.claimantID == decedentID
                        && $0.claimID != recognizedClaimID
                }
                if rights.records[index].custodianID == decedentID {
                    rights.records[index].custodianID = nil
                }
            }
            materialRightsState = rights
        }
        estateState = authority
        return estateID
    }

    mutating func bindEstateToFinalizedDeath(
        deathID: AgentDeathID,
        deathEventID: AgentCausalEventID
    ) throws {
        guard var authority = estateState else { return }
        guard let index = authority.estates.firstIndex(where: {
            $0.deathID == deathID
        }), authority.estates[index].deathEventID == nil else {
            throw AgentSessionError.estate(.invalidState("death binding"))
        }
        authority.estates[index].deathEventID = deathEventID
        authority.rollingDigest = Self.estateStateDigest(authority)
        estateState = authority
    }

    mutating func applyEstateAdministratorDeaths(
        _ lethalAgentIDs: Set<AgentID>,
        causeEventID: AgentCausalEventID,
        at boundaryTick: Int
    ) throws {
        guard var authority = estateState else { return }
        for estateIndex in authority.estates.indices
            where !authority.estates[estateIndex].status.isTerminal {
            for administrationIndex in authority.estates[estateIndex]
                .administrations.indices
                where lethalAgentIDs.contains(
                        authority.estates[estateIndex]
                            .administrations[administrationIndex]
                            .administratorID
                    ) {
                let prior = authority.estates[estateIndex]
                    .administrations[administrationIndex]
                if prior.status == .ended {
                    guard prior.endedAtTick == boundaryTick,
                          prior.endedReason != .died else {
                        continue
                    }
                    try prevalidateEstateTransitions(
                        &authority, count: 1, at: boundaryTick
                    )
                    let event = try requiredEstateEvent(
                        kind: .estateAdministratorEnded,
                        actorID: prior.administratorID,
                        subjectID: authority.estates[estateIndex].decedentID,
                        causes: [prior.endedEventID, causeEventID]
                            .compactMap { $0 }.sorted(),
                        payload: .operation(
                            status:
                                AgentEstateAdministratorEndReason.died.rawValue,
                            detail:
                                authority.estates[estateIndex].estateID.rawValue
                        ),
                        summary:
                            "estate administrator end finalized by death estate="
                            + authority.estates[estateIndex].estateID.rawValue
                    )
                    authority.estates[estateIndex]
                        .administrations[administrationIndex].endedReason = .died
                    authority.estates[estateIndex]
                        .administrations[administrationIndex].endedEventID =
                            event.eventID
                    authority.estates[estateIndex].lastEventID = event.eventID
                    authority.lastEventID = event.eventID
                    continue
                }
                try prevalidateEstateTransitions(
                    &authority, count: 1, at: boundaryTick
                )
                let admin = authority.estates[estateIndex]
                    .administrations[administrationIndex]
                let event = try requiredEstateEvent(
                    kind: .estateAdministratorEnded,
                    actorID: admin.administratorID,
                    subjectID: authority.estates[estateIndex].decedentID,
                    causes: [admin.nominationEventID, causeEventID].sorted(),
                    payload: .operation(
                        status: AgentEstateAdministratorEndReason.died.rawValue,
                        detail: authority.estates[estateIndex].estateID.rawValue
                    ),
                    summary: "estate administrator ended died estate="
                        + authority.estates[estateIndex].estateID.rawValue
                )
                authority.estates[estateIndex]
                    .administrations[administrationIndex].status = .ended
                authority.estates[estateIndex]
                    .administrations[administrationIndex].endedAtTick = boundaryTick
                authority.estates[estateIndex]
                    .administrations[administrationIndex].endedReason = .died
                authority.estates[estateIndex]
                    .administrations[administrationIndex].endedEventID = event.eventID
                authority.estates[estateIndex].status = .openUnadministered
                authority.estates[estateIndex].lastEventID = event.eventID
                authority.lastEventID = event.eventID
                try nominateReplacementEstateAdministrator(
                    estateIndex: estateIndex,
                    lethalAgentIDs: lethalAgentIDs,
                    causeEventID: event.eventID,
                    at: boundaryTick,
                    authority: &authority
                )
            }
        }
        authority.rollingDigest = Self.estateStateDigest(authority)
        estateState = authority
    }

    mutating func applyEstateTickBoundary(at boundaryTick: Int) throws {
        guard var authority = estateState else { return }
        for estateIndex in authority.estates.indices
            where !authority.estates[estateIndex].status.isTerminal {
            guard let administrationIndex = authority.estates[estateIndex]
                .administrations.lastIndex(where: {
                    $0.status == .active || $0.status == .nominated
                }) else { continue }
            let admin = authority.estates[estateIndex]
                .administrations[administrationIndex]
            guard !estateAdministratorIsAvailable(admin.administratorID) else {
                continue
            }
            try prevalidateEstateTransitions(
                &authority, count: 1, at: boundaryTick
            )
            let reason: AgentEstateAdministratorEndReason
            if isMigratingAgent(admin.administratorID.rawValue) {
                reason = .migrating
            } else if isPhysiologicallyIncapacitated(admin.administratorID) {
                reason = .incapacitated
            } else {
                reason = .unavailable
            }
            let event = try requiredEstateEvent(
                kind: .estateAdministratorEnded,
                actorID: admin.administratorID,
                subjectID: authority.estates[estateIndex].decedentID,
                causes: [admin.acceptanceEventID ?? admin.nominationEventID],
                payload: .operation(
                    status: reason.rawValue,
                    detail: authority.estates[estateIndex].estateID.rawValue
                ),
                summary: "estate administrator ended estate="
                    + "\(authority.estates[estateIndex].estateID.rawValue) "
                    + "reason=\(reason.rawValue)"
            )
            authority.estates[estateIndex]
                .administrations[administrationIndex].status = .ended
            authority.estates[estateIndex]
                .administrations[administrationIndex].endedAtTick = boundaryTick
            authority.estates[estateIndex]
                .administrations[administrationIndex].endedReason = reason
            authority.estates[estateIndex]
                .administrations[administrationIndex].endedEventID = event.eventID
            authority.estates[estateIndex].status = .openUnadministered
            authority.estates[estateIndex].lastEventID = event.eventID
            authority.lastEventID = event.eventID
            try nominateReplacementEstateAdministrator(
                estateIndex: estateIndex,
                lethalAgentIDs: [],
                causeEventID: event.eventID,
                at: boundaryTick,
                authority: &authority
            )
        }
        authority.rollingDigest = Self.estateStateDigest(authority)
        estateState = authority
    }

    public func validateEstateCrossDomainIfEnabled() throws {
        guard let authority = estateState,
              let mortality = mortalityState,
              let rights = materialRightsState,
              let lifecycle = lifecycleState,
              let kinship = kinshipState,
              let household = householdState,
              let childhood = dependentCareState?.childhoodV2,
              let family = familyState,
              let population = populationRegistry else {
            if estateState != nil {
                throw AgentSessionError.estate(.invalidState("missing authority"))
            }
            return
        }
        do {
            try Self.validateEstateState(
                authority,
                mortality: mortality,
                materialRights: rights,
                lifecycle: lifecycle,
                kinship: kinship,
                household: household,
                childhood: childhood,
                family: family,
                population: population,
                activeStates: statesById,
                homeostasis: homeostasisState,
                causalLedger: causalLedger,
                simulationID: simulationID,
                currentTick: tick
            )
        } catch let error as AgentEstateError {
            throw AgentSessionError.estate(error)
        }
    }

    static func validateEstateState(
        _ authority: AgentEstateState,
        mortality: AgentMortalityState,
        materialRights: AgentMaterialRightsState,
        lifecycle: AgentLifecycleState,
        kinship: AgentKinshipState,
        household: AgentHouseholdState,
        childhood: AgentChildhoodState,
        family: AgentFamilyState,
        population: AgentPopulationRegistry,
        activeStates: AgentStateStore,
        homeostasis: AgentHomeostasisState?,
        causalLedger: AgentCausalLedger,
        simulationID: AgentSimulationID,
        currentTick: Int
    ) throws {
        guard authority.activationTick >= 0,
              authority.activationTick <= currentTick,
              authority.activationDeathCount >= 0,
              authority.activationDeathCount <= mortality.totalDeathCount,
              authority.configuration.maximumRetainedEstates
                <= mortality.configuration.maximumRetainedDeathRecords,
              authority.estates == authority.estates.sorted(by: {
                  $0.estateID < $1.estateID
              }),
              authority.estates.count
                <= authority.configuration.maximumRetainedEstates,
              authority.estates.filter({ !$0.status.isTerminal }).count
                <= authority.configuration.maximumOpenEstates,
              authority.processedOperationIDs
                == authority.processedOperationIDs.sorted(),
              authority.processedOperationIDs.count
                == Set(authority.processedOperationIDs).count,
              authority.processedOperationIDs.count
                <= authority.configuration.maximumProcessedOperationIDs,
              authority.totalEstateCount
                == authority.estates.count
                    + authority.evictionCounts.settledEstates,
              authority.totalEstateCount
                == mortality.totalDeathCount
                    - authority.activationDeathCount,
              authority.totalSettlementCount
                == authority.estates.filter({ $0.status == .settled }).count
                    + authority.evictionCounts.settledEstates,
              authority.rollingDigest
                == Self.estateStateDigest(authority) else {
            throw AgentEstateError.invalidState("authority bounds")
        }
        let deaths = Dictionary(uniqueKeysWithValues:
            mortality.records.map { ($0.deathID, $0) }
        )
        guard Set(authority.estates.map(\.estateID)).count
                == authority.estates.count,
              Set(authority.estates.map(\.deathID)).count
                == authority.estates.count,
              Set(authority.estates.map(\.decedentID)).count
                == authority.estates.count else {
            throw AgentEstateError.invalidState("duplicate estate")
        }
        let expectedPostActivationDeaths = Array(
            mortality.records.suffix(authority.estates.count)
        )
        guard Set(expectedPostActivationDeaths.map(\.deathID))
                == Set(authority.estates.map(\.deathID)) else {
            throw AgentEstateError.invalidState("death coverage")
        }
        let knownPeople = Set(kinship.historicalPersons.map(\.agentID))
        let activeIDs = Set(activeStates.values.map(\.agentID))
        let lifecycleByID = Dictionary(uniqueKeysWithValues:
            lifecycle.members.map { ($0.agentID, $0) }
        )
        let rightsByID = Dictionary(uniqueKeysWithValues:
            materialRights.records.map { ($0.asset.assetID, $0) }
        )
        let retainedCausalEvent: (AgentCausalEventID) throws
            -> AgentCausalEvent? = { eventID in
            guard eventID.simulationID == simulationID,
                  eventID.sequence.rawValue <= causalLedger.latestSequence else {
                throw AgentEstateError.invalidState("causal reference")
            }
            if let event = causalLedger.events.first(where: {
                $0.eventID == eventID
            }) {
                return event
            }
            guard causalLedger.droppedEventCount > 0,
                  eventID.sequence.rawValue
                    <= causalLedger.droppedEventCount else {
                throw AgentEstateError.invalidState("causal reference")
            }
            return nil
        }
        let personWasMature: (AgentID, Int) -> Bool = { id, atTick in
            guard let member = lifecycleByID[id],
                  let age = try? member.age(at: atTick) else {
                return false
            }
            return age >= lifecycle.configuration.maturityAgeTicks
        }
        let personWasDead: (AgentID, Int) -> Bool = { id, atTick in
            mortality.records.contains {
                $0.agentID == id && $0.deathTick <= atTick
            }
        }
        var seenAssetIDs = Set<AgentMaterialAssetID>()
        var seenReceipts = Set<String>()
        var seenMortalityExitReceipts = Set<String>()
        var seenAcceptanceOperationIDs = Set<String>()
        for estate in authority.estates {
            let expectedEstateDigest = AgentEstateDigest.make(
                "\(simulationID.rawValue)|\(estate.decedentID.rawValue)|"
                    + "\(estate.deathID.rawValue)|27"
            )
            guard let death = deaths[estate.deathID],
                  death.agentID == estate.decedentID,
                  death.deathTick == estate.deathTick,
                  death.deathEventID == estate.deathEventID,
                  death.physicalCustodyResolution
                    == estate.physicalCustodyResolution,
                  estate.estateID.rawValue
                    == "estate-" + expectedEstateDigest,
                  !activeIDs.contains(estate.decedentID),
                  estate.openedAtTick == estate.deathTick,
                  estate.schemaVersion == 1,
                  estate.physicalCustodyResolution.verifiedAtTick
                    == estate.deathTick,
                  estate.physicalCustodyResolution.physicalAssets != nil,
                  estate.physicalCustodyResolution.stackCount
                    == estate.physicalCustodyResolution.physicalAssets?.count,
                  estate.physicalCustodyResolution.itemCount
                    == estate.physicalCustodyResolution.physicalAssets?
                        .reduce(0, { $0 + $1.count }),
                  seenMortalityExitReceipts.insert(
                    estate.physicalCustodyResolution.physicalReceiptID
                  ).inserted,
                  estate.assets.count
                    <= authority.configuration.maximumAssetsPerEstate,
                  estate.beneficiaries.count
                    <= authority.configuration.maximumBeneficiariesPerEstate,
                  estate.obligations.count
                    <= authority.configuration.maximumObligationsPerEstate,
                  estate.administrations.count
                    <= authority.configuration.maximumAdministrationsPerEstate,
                  estate.beneficiaries == estate.beneficiaries.sorted(by: {
                      $0.agentID < $1.agentID
                  }),
                  Set(estate.beneficiaries.map(\.agentID)).count
                    == estate.beneficiaries.count,
                  estate.assets == estate.assets.sorted(by: {
                      $0.entryID < $1.entryID
                  }),
                  Set(estate.assets.map(\.entryID)).count
                    == estate.assets.count else {
                throw AgentEstateError.invalidState("estate identity")
            }
            var expectedPhysicalByIdentity:
                [AgentMaterialIdentitySnapshot: Int] = [:]
            for stack in estate.physicalCustodyResolution.physicalAssets ?? [] {
                expectedPhysicalByIdentity[stack.identity, default: 0]
                    += stack.count
            }
            var classifiedPhysicalByIdentity:
                [AgentMaterialIdentitySnapshot: Int] = [:]
            for entry in estate.assets
                where entry.mortalityExitReceiptID
                    == estate.physicalCustodyResolution.physicalReceiptID {
                classifiedPhysicalByIdentity[
                    entry.materialIdentity, default: 0
                ] += entry.quantity
            }
            guard classifiedPhysicalByIdentity
                    == expectedPhysicalByIdentity else {
                throw AgentEstateError.invalidState(
                    "physical custody classification"
                )
            }
            if let opening = try retainedCausalEvent(estate.openingEventID) {
                guard opening.kind == .estateOpened,
                      opening.origin == .estateTransition,
                      opening.actorID == estate.decedentID,
                      opening.subjectID == estate.decedentID,
                      opening.simulationTick.rawValue == estate.deathTick,
                      opening.causes.contains(
                          estate.physicalCustodyResolution.eventID
                      ),
                      opening.causes.contains(
                        death.lethalDamageEventID
                      ) else {
                    throw AgentEstateError.invalidState("opening event")
                }
            }
            if let commitments = try retainedCausalEvent(
                death.commitmentsResolvedEventID
            ) {
                guard commitments.kind == .mortalityCommitmentsResolved,
                      commitments.actorID == estate.decedentID,
                      commitments.subjectID == estate.decedentID,
                      commitments.simulationTick.rawValue
                        == estate.deathTick,
                      commitments.causes.contains(
                        estate.openingEventID
                      ) else {
                    throw AgentEstateError.invalidState(
                        "commitments after estate opening"
                    )
                }
            }
            if let deathEventID = estate.deathEventID,
               let deathEvent = try retainedCausalEvent(deathEventID) {
                guard deathEvent.kind == .agentDeathFinalized,
                      deathEvent.actorID == estate.decedentID,
                      deathEvent.subjectID == estate.decedentID,
                      deathEvent.simulationTick.rawValue == estate.deathTick
                else {
                    throw AgentEstateError.invalidState("death event")
                }
            }
            let expectedPlan = try estatePlanForValidation(
                decedentID: estate.decedentID,
                deathTick: estate.deathTick,
                family: family,
                kinship: kinship,
                lifecycle: lifecycle,
                mortality: mortality,
                childhood: childhood
            )
            let actualPlan = estate.beneficiaries.map {
                "\($0.agentID.rawValue)|\($0.basis.rawValue)|\($0.weight)|"
                    + "\($0.lifeStageAtPlan.rawValue)|"
                    + "\($0.guardianIDAtPlan?.rawValue ?? "none")"
            }
            let durablePlan = expectedPlan.beneficiaries.map {
                "\($0.agentID.rawValue)|\($0.basis.rawValue)|\($0.weight)|"
                    + "\($0.lifeStageAtPlan.rawValue)|"
                    + "\($0.guardianIDAtPlan?.rawValue ?? "none")"
            }
            if mortality.evictionCounts.deathRecords == 0 {
                guard estate.beneficiaryTier == expectedPlan.tier,
                      actualPlan == durablePlan else {
                    throw AgentEstateError.invalidState(
                        "beneficiary plan expected=\(expectedPlan.tier.rawValue)"
                            + ":\(durablePlan.joined(separator: ",")) actual="
                            + "\(estate.beneficiaryTier.rawValue):"
                            + actualPlan.joined(separator: ",")
                    )
                }
            } else {
                for beneficiary in estate.beneficiaries {
                    guard beneficiary.weight == 1,
                          beneficiary.tier == estate.beneficiaryTier,
                          beneficiary.agentID != estate.decedentID,
                          knownPeople.contains(beneficiary.agentID),
                          !personWasDead(
                              beneficiary.agentID, estate.deathTick
                          ) else {
                        throw AgentEstateError.invalidState(
                            "historical beneficiary"
                        )
                    }
                    let relationIsValid: Bool
                    switch beneficiary.basis {
                    case .activeUnionPartnerAtDeath:
                        relationIsValid = family.unions.contains {
                            $0.partnerIDs
                                == [estate.decedentID, beneficiary.agentID]
                                    .sorted()
                                && $0.activationTick <= estate.deathTick
                                && ($0.terminationTick == nil
                                    || ($0.terminationTick
                                        == estate.deathTick
                                        && $0.terminationReason
                                            == .partnerDeath))
                        }
                    case .canonicalChild:
                        relationIsValid = kinship.parentageRecords.contains {
                            $0.childID == beneficiary.agentID
                                && $0.canonicalParentIDs.contains(
                                    estate.decedentID
                                )
                        }
                    case .canonicalParent:
                        relationIsValid = kinship.parentageRecords.contains {
                            $0.childID == estate.decedentID
                                && $0.canonicalParentIDs.contains(
                                    beneficiary.agentID
                                )
                        }
                    case .fullSibling, .halfSibling:
                        let parentage = Dictionary(uniqueKeysWithValues:
                            kinship.parentageRecords.map {
                                ($0.childID, Set($0.canonicalParentIDs))
                            }
                        )
                        let common = (parentage[estate.decedentID] ?? [])
                            .intersection(
                                parentage[beneficiary.agentID] ?? []
                            ).count
                        relationIsValid = beneficiary.basis == .fullSibling
                            ? common == 2 : common == 1
                    }
                    guard relationIsValid else {
                        throw AgentEstateError.invalidState(
                            "historical beneficiary relation"
                        )
                    }
                }
            }
            guard Set(estate.administrations.map(\.administratorID)).count
                    == estate.administrations.count,
                  Set(estate.administrations.map(\.nominationEventID)).count
                    == estate.administrations.count else {
                throw AgentEstateError.invalidState(
                    "duplicate administration"
                )
            }
            for administration in estate.administrations {
                guard knownPeople.contains(administration.administratorID) else {
                    throw AgentEstateError.invalidState(
                        "unknown administrator identity"
                    )
                }
                guard administration.nominatedAtTick >= estate.deathTick,
                      administration.nominatedAtTick <= currentTick else {
                    throw AgentEstateError.invalidState(
                        "administrator nomination tick"
                    )
                }
                let administratorMaturityEvidence: Bool
                if lifecycleByID[administration.administratorID] != nil {
                    administratorMaturityEvidence = personWasMature(
                        administration.administratorID,
                        administration.nominatedAtTick
                    )
                } else if let laterDeath = mortality.records.first(where: {
                    $0.agentID == administration.administratorID
                        && $0.deathTick >= administration.nominatedAtTick
                }) {
                    administratorMaturityEvidence =
                        laterDeath.lifeStage == .mature
                } else {
                    administratorMaturityEvidence =
                        administration.lifeStageAtNomination == .mature
                }
                guard administration.lifeStageAtNomination == .mature,
                      administratorMaturityEvidence else {
                    throw AgentEstateError.invalidState(
                        "immature administrator"
                    )
                }
                guard !personWasDead(
                    administration.administratorID,
                    administration.nominatedAtTick
                ) else {
                    throw AgentEstateError.invalidState(
                        "dead administrator at nomination"
                    )
                }
                let basisIsValid: Bool
                switch administration.basis {
                case .activeUnionPartnerAtDeath:
                    basisIsValid = estate.beneficiaries.contains {
                        $0.agentID == administration.administratorID
                            && $0.basis == .activeUnionPartnerAtDeath
                    }
                case .matureCanonicalChild:
                    basisIsValid = estate.beneficiaries.contains {
                        $0.agentID == administration.administratorID
                            && $0.basis == .canonicalChild
                    }
                case .matureCanonicalParent:
                    basisIsValid = kinship.parentageRecords.contains {
                        $0.childID == estate.decedentID
                            && $0.canonicalParentIDs.contains(
                                administration.administratorID
                            )
                    }
                case .matureSibling:
                    let parentage = Dictionary(uniqueKeysWithValues:
                        kinship.parentageRecords.map {
                            ($0.childID, Set($0.canonicalParentIDs))
                        }
                    )
                    basisIsValid = !(parentage[estate.decedentID] ?? [])
                        .intersection(
                            parentage[administration.administratorID] ?? []
                        ).isEmpty
                case .matureHouseholdAdult:
                    basisIsValid = household.membershipPeriods.contains {
                        decedentPeriod in
                        decedentPeriod.agentID == estate.decedentID
                            && decedentPeriod.joinedTick <= estate.deathTick
                            && (decedentPeriod.leftTick == nil
                                || decedentPeriod.leftTick!
                                    >= estate.deathTick)
                            && household.membershipPeriods.contains {
                                candidatePeriod in
                                candidatePeriod.agentID
                                    == administration.administratorID
                                    && candidatePeriod.householdID
                                        == decedentPeriod.householdID
                                    && candidatePeriod.joinedTick
                                        <= administration.nominatedAtTick
                                    && (candidatePeriod.leftTick == nil
                                        || candidatePeriod.leftTick!
                                            > administration.nominatedAtTick)
                            }
                    }
                }
                guard basisIsValid else {
                    throw AgentEstateError.invalidState(
                        "administrator basis"
                    )
                }
                if let nomination = try retainedCausalEvent(
                    administration.nominationEventID
                ) {
                    guard nomination.kind
                            == .estateAdministratorNominated,
                          nomination.origin == .estateTransition,
                          nomination.actorID
                            == administration.administratorID,
                          nomination.subjectID == estate.decedentID,
                          nomination.simulationTick.rawValue
                            == administration.nominatedAtTick else {
                        throw AgentEstateError.invalidState(
                            "administrator nomination event"
                        )
                    }
                }
                let currentlyAvailable =
                    (activeStates[
                        administration.administratorID.rawValue
                    ]?.health ?? 0) > 0
                    && population.members.contains {
                        $0.agentID == administration.administratorID
                            && ($0.status == .resident
                                || $0.status == .founderResident)
                    }
                    && homeostasis?.profiles.first {
                        $0.agentID == administration.administratorID
                    }?.vitalStatus != .incapacitated
                switch administration.status {
                case .nominated:
                    guard administration.acceptedAtTick == nil,
                          administration.acceptanceOperationID == nil,
                          administration.acceptanceEventID == nil,
                          administration.endedAtTick == nil,
                          administration.endedReason == nil,
                          administration.endedEventID == nil,
                          currentlyAvailable else {
                        throw AgentEstateError.invalidState(
                            "nominated administrator"
                        )
                    }
                case .active:
                    guard let acceptedAtTick = administration.acceptedAtTick,
                          acceptedAtTick >= administration.nominatedAtTick,
                          acceptedAtTick <= currentTick,
                          let operationID =
                            administration.acceptanceOperationID,
                          authority.processedOperationIDs.contains(operationID),
                          seenAcceptanceOperationIDs.insert(operationID).inserted,
                          let acceptanceEventID =
                            administration.acceptanceEventID,
                          administration.endedAtTick == nil,
                          administration.endedReason == nil,
                          administration.endedEventID == nil,
                          currentlyAvailable else {
                        throw AgentEstateError.invalidState(
                            "active administrator"
                        )
                    }
                    if let acceptance = try retainedCausalEvent(
                        acceptanceEventID
                    ) {
                        guard acceptance.kind
                                == .estateAdministratorAccepted,
                              acceptance.actorID
                                == administration.administratorID,
                              acceptance.subjectID == estate.decedentID,
                              acceptance.operationID?.rawValue == operationID,
                              acceptance.simulationTick.rawValue
                                == acceptedAtTick,
                              acceptance.causes.contains(
                                  administration.nominationEventID
                              ) else {
                            throw AgentEstateError.invalidState(
                                "administrator acceptance event"
                            )
                        }
                    }
                case .ended:
                    guard let endedAtTick = administration.endedAtTick,
                          endedAtTick >= administration.nominatedAtTick,
                          endedAtTick <= currentTick,
                          administration.endedReason != nil,
                          administration.endedEventID != nil else {
                        throw AgentEstateError.invalidState(
                            "ended administrator"
                        )
                    }
                    if administration.acceptedAtTick == nil {
                        guard administration.acceptanceOperationID == nil,
                              administration.acceptanceEventID == nil else {
                            throw AgentEstateError.invalidState(
                                "ended nomination acceptance"
                            )
                        }
                    } else {
                        guard let operationID =
                                administration.acceptanceOperationID,
                              authority.processedOperationIDs.contains(
                                  operationID
                              ),
                              seenAcceptanceOperationIDs.insert(
                                  operationID
                              ).inserted,
                              administration.acceptanceEventID != nil else {
                            throw AgentEstateError.invalidState(
                                "ended active acceptance"
                            )
                        }
                    }
                    if let endedEventID = administration.endedEventID,
                       let ended = try retainedCausalEvent(endedEventID) {
                        let exactEnd: Bool
                        if administration.endedReason == .estateSettled {
                            exactEnd = ended.kind == .estateSettled
                                && ended.eventID == estate.settledEventID
                        } else {
                            exactEnd = ended.kind
                                    == .estateAdministratorEnded
                                && ended.payload == .operation(
                                    status:
                                        administration.endedReason!.rawValue,
                                    detail: estate.estateID.rawValue
                                )
                        }
                        guard exactEnd,
                              ended.origin == .estateTransition,
                              ended.actorID
                                == administration.administratorID,
                              ended.subjectID == estate.decedentID,
                              ended.simulationTick.rawValue == endedAtTick else {
                            throw AgentEstateError.invalidState(
                                "administrator ended event"
                            )
                        }
                    }
                }
            }
            let classifiedPhysicalAssets = estate.assets.filter {
                $0.materialRightsAssetID != nil
            }.sorted {
                $0.materialRightsAssetID! < $1.materialRightsAssetID!
            }
            var expectedAssignments:
                [AgentEstateAssetEntryID: AgentID] = [:]
            for (index, entry) in classifiedPhysicalAssets.enumerated() {
                let ownerIsDecedent =
                    entry.ownerAtOpening?.ownerID == estate.decedentID
                let hasThirdPartyClaim = entry.claimsAtOpening.contains {
                    $0.claimantID != estate.decedentID
                }
                if ownerIsDecedent, !hasThirdPartyClaim,
                   !estate.beneficiaries.isEmpty {
                    expectedAssignments[entry.entryID] =
                        estate.beneficiaries[
                            index % estate.beneficiaries.count
                        ].agentID
                }
            }
            for entry in estate.assets {
                guard entry.quantity > 0,
                      entry.mortalityExitTick == estate.deathTick,
                      entry.classificationEventID != nil,
                      entry.permissionsAtOpening.allSatisfy({
                          $0.userID != estate.decedentID
                      }),
                      entry.settlementAttemptCount >= 0,
                      entry.settlementAttemptCount
                        <= authority.configuration.maximumSettlementAttemptsPerAsset,
                      entry.materialRightsAssetID != nil
                        || entry.blockReason == .sociallyUnregistered else {
                    throw AgentEstateError.invalidState("asset identity")
                }
                if let classificationEventID = entry.classificationEventID,
                   let classification = try retainedCausalEvent(
                    classificationEventID
                   ) {
                    let wasBlocked = entry.blockReason != nil
                    let expectedKind: AgentCausalEventKind =
                        wasBlocked
                            ? .estateAssetBlocked : .estateAssetClassified
                    let originalStatus: AgentEstateAssetStatus =
                        entry.status == .transferred
                            ? .pendingSettlement : entry.status
                    guard classification.kind == expectedKind,
                          classification.origin == .estateTransition,
                          classification.subjectID == estate.decedentID,
                          classification.simulationTick.rawValue
                            == estate.deathTick,
                          classification.payload == .operation(
                            status: originalStatus.rawValue,
                            detail: entry.entryID.rawValue
                          ),
                          classification.causes.contains(
                            estate.openingEventID
                          ) else {
                        throw AgentEstateError.invalidState(
                            "asset classification event"
                        )
                    }
                }
                let expectedBeneficiaryID =
                    expectedAssignments[entry.entryID]
                guard entry.assignedBeneficiaryID
                        == expectedBeneficiaryID else {
                    throw AgentEstateError.invalidState(
                        "asset successor assignment"
                    )
                }
                if let expectedBeneficiaryID,
                   let beneficiary = estate.beneficiaries.first(where: {
                       $0.agentID == expectedBeneficiaryID
                   }) {
                    let expectedCustodian =
                        beneficiary.lifeStageAtPlan == .mature
                            ? beneficiary.agentID
                            : beneficiary.guardianIDAtPlan
                    guard entry.intendedCustodianID
                            == expectedCustodian else {
                        throw AgentEstateError.invalidState(
                            "asset custody assignment"
                        )
                    }
                } else if entry.intendedCustodianID != nil {
                    throw AgentEstateError.invalidState(
                        "unassigned asset custodian"
                    )
                }
                if let assetID = entry.materialRightsAssetID {
                    guard seenAssetIDs.insert(assetID).inserted else {
                        throw AgentEstateError.invalidState(
                            "duplicate asset authority"
                        )
                    }
                    guard let current = rightsByID[assetID] else {
                        throw AgentEstateError.invalidState(
                            "missing asset authority"
                        )
                    }
                    guard current.asset.materialIdentity
                            == entry.materialIdentity,
                          current.asset.quantity == entry.quantity,
                          entry.permissionsAtOpening.allSatisfy(
                            current.permissions.contains
                          ) else {
                        throw AgentEstateError.invalidState(
                            "mismatched asset authority"
                        )
                    }
                    if entry.status == .transferred {
                        guard let beneficiary = entry.assignedBeneficiaryID,
                              current.recognizedOwnership?.ownerID == beneficiary,
                              current.lastVerifiedHolder
                                == entry.destinationObservation,
                              let receipt = entry.settlementReceiptID,
                              seenReceipts.insert(receipt).inserted,
                              entry.settlementEventID != nil,
                              entry.settlementObservation?
                                .physicalReceiptID == receipt,
                              entry.settlementObservation?
                                .materialIdentity
                                    == entry.materialIdentity,
                              entry.settlementObservation?.quantity
                                == entry.quantity,
                              entry.settlementAttemptCount == 1,
                              entry.destinationObservation?.holder
                                == entry.intendedCustodianID.map({
                                    AgentMaterialPhysicalHolder.agent($0)
                                }),
                              current.custodianID
                                == (entry.intendedCustodianID
                                    == entry.assignedBeneficiaryID
                                    ? nil : entry.intendedCustodianID) else {
                            throw AgentEstateError.invalidState("settled asset")
                        }
                        if let settlementEventID = entry.settlementEventID,
                           let settlement = try retainedCausalEvent(
                            settlementEventID
                           ) {
                            guard settlement.kind == .estateAssetSettled,
                                  settlement.origin == .estateTransition,
                                  settlement.subjectID
                                    == entry.assignedBeneficiaryID,
                                  settlement.operationID?.rawValue
                                    == entry.settlementReceiptID,
                                  settlement.simulationTick.rawValue
                                    == entry.settlementObservation?
                                        .observedAtTick else {
                                throw AgentEstateError.invalidState(
                                    "asset settlement event"
                                )
                            }
                        }
                    } else {
                        guard current.recognizedOwnership?.ownerID
                                == entry.ownerAtOpening?.ownerID,
                              current.lastVerifiedHolder.holder
                                == entry.holderAtOpening?.holder,
                              current.lastVerifiedHolder.materialIdentity
                                == entry.holderAtOpening?.materialIdentity,
                              current.lastVerifiedHolder.quantity
                                == entry.holderAtOpening?.quantity else {
                            throw AgentEstateError.invalidState(
                                "asset moved before settlement"
                            )
                        }
                    }
                    let thirdPartyClaims = entry.claimsAtOpening.filter {
                        $0.claimantID != estate.decedentID
                    }
                    if !thirdPartyClaims.isEmpty {
                        guard entry.status == .blocked,
                              entry.blockReason == .thirdPartyClaim,
                              thirdPartyClaims.allSatisfy(current.claims.contains)
                        else {
                            throw AgentEstateError.invalidState(
                                "third-party claim"
                            )
                        }
                    }
                }
                if entry.status != .transferred {
                    guard entry.destinationObservation == nil,
                          entry.settlementObservation == nil,
                          entry.settlementReceiptID == nil,
                          entry.settlementEventID == nil,
                          entry.settlementAttemptCount == 0 else {
                        throw AgentEstateError.invalidState(
                            "unsettled asset progress"
                        )
                    }
                }
            }
            if estate.status == .settled {
                guard estate.assets.allSatisfy(\.status.isTerminal),
                      estate.settledAtTick != nil,
                      estate.settledEventID != nil else {
                    throw AgentEstateError.invalidState("settled estate")
                }
                if let settledEventID = estate.settledEventID,
                   let settled = try retainedCausalEvent(settledEventID) {
                    guard settled.kind == .estateSettled,
                          settled.origin == .estateTransition,
                          settled.subjectID == estate.decedentID,
                          settled.simulationTick.rawValue
                            == estate.settledAtTick else {
                        throw AgentEstateError.invalidState(
                            "estate settlement event"
                        )
                    }
                }
            } else if estate.status == .partiallySettled {
                guard estate.assets.contains(where: \.status.isTerminal),
                      estate.assets.contains(where: { !$0.status.isTerminal }),
                      estate.settledAtTick == nil,
                      estate.settledEventID == nil else {
                    throw AgentEstateError.invalidState(
                        "partially settled estate"
                    )
                }
            } else if estate.assets.contains(where: {
                $0.status == .blocked
            }) && estate.status != .blocked
                && estate.status != .dormantNoSuccessor
                && estate.status != .partiallySettled {
                throw AgentEstateError.invalidState("blocked estate")
            }
        }
        _ = household
        _ = causalLedger
        _ = simulationID
    }

    private func estateBeneficiaryPlan(
        decedentID: AgentID,
        activePartnerID: AgentID?,
        lethalAgentIDs: Set<AgentID>
    ) throws -> (
        tier: AgentEstateBeneficiaryTier,
        beneficiaries: [AgentEstateBeneficiary]
    ) {
        let living: (AgentID) -> Bool = {
            $0 != decedentID && !lethalAgentIDs.contains($0)
                && statesById[$0.rawValue] != nil
        }
        var rows: [(AgentID, AgentEstateBeneficiaryBasis)] = []
        if let activePartnerID, living(activePartnerID) {
            rows.append((activePartnerID, .activeUnionPartnerAtDeath))
        }
        for child in try children(of: decedentID) where living(child) {
            rows.append((child, .canonicalChild))
        }
        var tier: AgentEstateBeneficiaryTier = .primaryPartnerAndChildren
        if rows.isEmpty {
            for parent in (try parents(of: decedentID)) ?? [] where living(parent) {
                rows.append((parent, .canonicalParent))
            }
            tier = .secondaryParents
        }
        if rows.isEmpty {
            for person in kinshipState?.historicalPersons.map(\.agentID).sorted()
                ?? [] where living(person) {
                switch siblingRelation(between: decedentID, and: person) {
                case .fullSibling: rows.append((person, .fullSibling))
                case .halfSibling: rows.append((person, .halfSibling))
                default: break
                }
            }
            tier = .tertiarySiblings
        }
        if rows.isEmpty { tier = .none }
        let unique = Dictionary(rows, uniquingKeysWith: { lhs, _ in lhs })
            .map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
        let beneficiaries = unique.map { id, basis in
            let stage = lifecycleState?.members.first {
                $0.agentID == id
            }?.currentStage ?? .mature
            let guardian = stage == .mature ? nil
                : dependentCareState?.childhoodV2?.guardianships.last {
                    $0.dependentID == id && $0.status == .active
                }?.guardianID
            return AgentEstateBeneficiary(
                agentID: id, tier: tier, basis: basis, weight: 1,
                lifeStageAtPlan: stage, guardianIDAtPlan: guardian,
                allocationCount: 0
            )
        }
        return (tier, beneficiaries)
    }

    private static func estatePlanForValidation(
        decedentID: AgentID,
        deathTick: Int,
        family: AgentFamilyState,
        kinship: AgentKinshipState,
        lifecycle: AgentLifecycleState,
        mortality: AgentMortalityState,
        childhood: AgentChildhoodState
    ) throws -> (
        tier: AgentEstateBeneficiaryTier,
        beneficiaries: [AgentEstateBeneficiary]
    ) {
        let deadAtOrBefore = Set(mortality.records.filter {
            $0.deathTick <= deathTick
        }.map(\.agentID))
        let living: (AgentID) -> Bool = {
            $0 != decedentID && !deadAtOrBefore.contains($0)
        }
        let partner = family.unions.first {
            $0.partnerIDs.contains(decedentID)
                && $0.activationTick <= deathTick
                && ($0.terminationTick == nil
                    || ($0.terminationTick == deathTick
                        && $0.terminationReason == .partnerDeath))
        }?.partnerIDs.first { $0 != decedentID }
        var rows: [(AgentID, AgentEstateBeneficiaryBasis)] = []
        if let partner, living(partner) {
            rows.append((partner, .activeUnionPartnerAtDeath))
        }
        for record in kinship.parentageRecords
            where record.canonicalParentIDs.contains(decedentID)
                && living(record.childID) {
            rows.append((record.childID, .canonicalChild))
        }
        var tier: AgentEstateBeneficiaryTier = .primaryPartnerAndChildren
        if rows.isEmpty,
           let parentage = kinship.parentageRecords.first(where: {
               $0.childID == decedentID
           }) {
            rows = parentage.canonicalParentIDs.filter(living).map {
                ($0, .canonicalParent)
            }
            tier = .secondaryParents
        }
        if rows.isEmpty {
            let parentageByChild = Dictionary(uniqueKeysWithValues:
                kinship.parentageRecords.map {
                    ($0.childID, Set($0.canonicalParentIDs))
                }
            )
            let parents = parentageByChild[decedentID] ?? []
            for other in kinship.historicalPersons.map(\.agentID).sorted()
                where living(other) {
                guard let otherParents = parentageByChild[other] else {
                    continue
                }
                let common = parents.intersection(otherParents).count
                if common == 2 { rows.append((other, .fullSibling)) }
                else if common == 1 { rows.append((other, .halfSibling)) }
            }
            tier = .tertiarySiblings
        }
        if rows.isEmpty { tier = .none }
        let unique = Dictionary(rows, uniquingKeysWith: { lhs, _ in lhs })
            .map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
        return (tier, unique.map { id, basis in
            let member = lifecycle.members.first { $0.agentID == id }
            let stage: AgentLifeStage
            if let member {
                let age = (try? member.age(at: deathTick)) ?? member.initialAgeTicks
                stage = age >= lifecycle.configuration.maturityAgeTicks
                    ? .mature
                    : (age >= lifecycle.configuration.newbornDurationTicks
                        ? .juvenile : .newborn)
            } else if let laterDeath = mortality.records.first(where: {
                $0.agentID == id && $0.deathTick >= deathTick
            }), let ageAtLaterDeath = laterDeath.demographicAgeTicks {
                let age = max(
                    0, ageAtLaterDeath - (laterDeath.deathTick - deathTick)
                )
                stage = age >= lifecycle.configuration.maturityAgeTicks
                    ? .mature
                    : (age >= lifecycle.configuration.newbornDurationTicks
                        ? .juvenile : .newborn)
            } else {
                stage = .mature
            }
            let guardian = stage == .mature ? nil
                : childhood.guardianships.last {
                    $0.dependentID == id && $0.startedTick <= deathTick
                        && ($0.endedTick == nil || $0.endedTick! > deathTick)
                }?.guardianID
            return AgentEstateBeneficiary(
                agentID: id, tier: tier, basis: basis, weight: 1,
                lifeStageAtPlan: stage, guardianIDAtPlan: guardian,
                allocationCount: 0
            )
        })
    }

    private func estateAdministratorNomination(
        decedentID: AgentID,
        activePartnerID: AgentID?,
        lethalAgentIDs: Set<AgentID>
    ) throws -> (agentID: AgentID, basis: AgentEstateAdministratorBasis)? {
        func first(
            _ ids: [AgentID],
            _ basis: AgentEstateAdministratorBasis
        ) -> (AgentID, AgentEstateAdministratorBasis)? {
            ids.sorted().first {
                $0 != decedentID && !lethalAgentIDs.contains($0)
                    && estateAdministratorIsAvailable($0)
            }.map { ($0, basis) }
        }
        if let activePartnerID,
           let selected = first([activePartnerID], .activeUnionPartnerAtDeath) {
            return selected
        }
        if let selected = first(
            try children(of: decedentID), .matureCanonicalChild
        ) { return selected }
        if let selected = first(
            (try parents(of: decedentID)) ?? [], .matureCanonicalParent
        ) { return selected }
        let siblings = kinshipState?.historicalPersons.map(\.agentID).filter {
            switch siblingRelation(between: decedentID, and: $0) {
            case .fullSibling, .halfSibling: return true
            default: return false
            }
        } ?? []
        if let selected = first(siblings, .matureSibling) { return selected }
        if let membership = try currentMembership(of: decedentID),
           let selected = first(
               try members(of: membership.householdID),
               .matureHouseholdAdult
           ) { return selected }
        return nil
    }

    private func replacementEstateAdministratorNomination(
        for estate: AgentEstateRecord,
        lethalAgentIDs: Set<AgentID>
    ) throws -> (agentID: AgentID, basis: AgentEstateAdministratorBasis)? {
        let excluded = Set(
            estate.administrations.map(\.administratorID)
                + [estate.decedentID]
        ).union(lethalAgentIDs)
        func first(
            _ ids: [AgentID],
            _ basis: AgentEstateAdministratorBasis
        ) -> (AgentID, AgentEstateAdministratorBasis)? {
            ids.sorted().first {
                !excluded.contains($0) && estateAdministratorIsAvailable($0)
            }.map { ($0, basis) }
        }
        if let selected = first(
            estate.beneficiaries.compactMap {
                $0.basis == .activeUnionPartnerAtDeath ? $0.agentID : nil
            },
            .activeUnionPartnerAtDeath
        ) { return selected }
        if let selected = first(
            try children(of: estate.decedentID),
            .matureCanonicalChild
        ) { return selected }
        if let selected = first(
            (try parents(of: estate.decedentID)) ?? [],
            .matureCanonicalParent
        ) { return selected }
        let siblings = kinshipState?.historicalPersons.map(\.agentID).filter {
            switch siblingRelation(between: estate.decedentID, and: $0) {
            case .fullSibling, .halfSibling: return true
            default: return false
            }
        } ?? []
        if let selected = first(
            siblings,
            .matureSibling
        ) { return selected }
        if let household = householdState,
           let decedentPeriod = household.membershipPeriods.first(where: {
               $0.agentID == estate.decedentID
                   && $0.joinedTick <= estate.deathTick
                   && ($0.leftTick == nil || $0.leftTick! >= estate.deathTick)
           }) {
            let members = household.membershipPeriods.compactMap { period in
                period.householdID == decedentPeriod.householdID
                    && period.joinedTick <= tick
                    && (period.leftTick == nil || period.leftTick! > tick)
                    ? period.agentID : nil
            }
            if let selected = first(members, .matureHouseholdAdult) {
                return selected
            }
        }
        return nil
    }

    private mutating func nominateReplacementEstateAdministrator(
        estateIndex: Int,
        lethalAgentIDs: Set<AgentID>,
        causeEventID: AgentCausalEventID,
        at nominationTick: Int,
        authority: inout AgentEstateState
    ) throws {
        let estate = authority.estates[estateIndex]
        guard !estate.status.isTerminal,
              estate.administrations.count
                < authority.configuration.maximumAdministrationsPerEstate,
              let nomination = try replacementEstateAdministratorNomination(
                  for: estate,
                  lethalAgentIDs: lethalAgentIDs
              ) else { return }
        try prevalidateEstateTransitions(
            &authority, count: 1, at: nominationTick
        )
        let event = try requiredEstateEvent(
            kind: .estateAdministratorNominated,
            actorID: nomination.agentID,
            subjectID: estate.decedentID,
            causes: [causeEventID],
            payload: .operation(
                status: "replacementNominated",
                detail: "\(estate.estateID.rawValue)|\(nomination.basis.rawValue)"
            ),
            summary: "replacement estate administrator nominated estate="
                + "\(estate.estateID.rawValue) candidate="
                + nomination.agentID.rawValue
        )
        authority.estates[estateIndex].administrations.append(
            AgentEstateAdministration(
                administratorID: nomination.agentID,
                basis: nomination.basis,
                nominatedAtTick: nominationTick,
                lifeStageAtNomination: .mature,
                nominationEventID: event.eventID,
                acceptedAtTick: nil,
                acceptanceOperationID: nil,
                acceptanceEventID: nil,
                endedAtTick: nil,
                endedReason: nil,
                endedEventID: nil,
                status: .nominated
            )
        )
        authority.estates[estateIndex].lastEventID = event.eventID
        authority.lastEventID = event.eventID
    }

    private func estateAdministratorIsAvailable(_ agentID: AgentID) -> Bool {
        guard let state = statesById[agentID.rawValue], state.health > 0,
              !isPhysiologicallyIncapacitated(agentID),
              !isMigratingAgent(agentID.rawValue),
              lifecycleState?.members.first(where: {
                  $0.agentID == agentID
              })?.currentStage == .mature,
              populationRegistry?.members.contains(where: {
                  $0.agentID == agentID
                      && ($0.status == .resident
                          || $0.status == .founderResident)
              }) == true else {
            return false
        }
        return true
    }

    private func estateAssetsAtOpening(
        estateID: AgentEstateID,
        decedentID: AgentID,
        physicalCustodyResolution: AgentMortalityPhysicalCustodyResolution,
        beneficiaries: [AgentEstateBeneficiary]
    ) throws -> [AgentEstateAssetEntry] {
        let physicalAssets = physicalCustodyResolution.physicalAssets ?? []
        let records = materialRightsState?.records.filter { record in
            record.recognizedOwnership?.ownerID == decedentID
                || record.custodianID == decedentID
                || record.claims.contains(where: { $0.claimantID == decedentID })
                || record.lastVerifiedHolder.physicalReceiptID
                    == physicalCustodyResolution.physicalReceiptID
        }.sorted { $0.asset.assetID < $1.asset.assetID } ?? []
        var entries: [AgentEstateAssetEntry] = []
        var trackedByIdentity: [AgentMaterialIdentitySnapshot: Int] = [:]
        for (index, record) in records.enumerated() {
            if record.lastVerifiedHolder.physicalReceiptID
                == physicalCustodyResolution.physicalReceiptID {
                trackedByIdentity[record.asset.materialIdentity, default: 0]
                    += record.asset.quantity
            }
            let ownerIsDecedent =
                record.recognizedOwnership?.ownerID == decedentID
            let thirdPartyClaims = record.claims.contains {
                $0.claimantID != decedentID
            }
            let assigned = ownerIsDecedent && !thirdPartyClaims
                && !beneficiaries.isEmpty
                ? beneficiaries[index % max(1, beneficiaries.count)].agentID
                : nil
            let beneficiary = assigned.flatMap { id in
                beneficiaries.first { $0.agentID == id }
            }
            let status: AgentEstateAssetStatus
            let reason: AgentEstateAssetBlockReason?
            if thirdPartyClaims {
                status = .blocked
                reason = .thirdPartyClaim
            } else if !ownerIsDecedent {
                status = .nonTransferable
                reason = nil
            } else if beneficiaries.isEmpty {
                status = .blocked
                reason = .noSuccessor
            } else if beneficiary?.lifeStageAtPlan != .mature,
                      beneficiary?.guardianIDAtPlan == nil {
                status = .blocked
                reason = .minorCustodyUnavailable
            } else {
                status = .pendingSettlement
                reason = nil
            }
            let entryID = AgentEstateAssetEntryID(
                rawValue: "estateasset-" + AgentEstateDigest.make(
                    "\(estateID.rawValue)|\(record.asset.assetID.rawValue)"
                )
            )!
            entries.append(AgentEstateAssetEntry(
                entryID: entryID,
                materialRightsAssetID: record.asset.assetID,
                materialIdentity: record.asset.materialIdentity,
                quantity: record.asset.quantity,
                mortalityExitReceiptID:
                    record.lastVerifiedHolder.physicalReceiptID,
                mortalityExitHolderID:
                    record.lastVerifiedHolder.holder.stableText,
                mortalityExitTick: physicalCustodyResolution.verifiedAtTick,
                holderAtOpening: record.lastVerifiedHolder,
                custodianAtOpening: record.custodianID,
                ownerAtOpening: record.recognizedOwnership,
                claimsAtOpening: record.claims,
                permissionsAtOpening: record.permissions.filter {
                    $0.userID != decedentID
                },
                classificationEventID: nil,
                assignedBeneficiaryID: assigned,
                intendedCustodianID: beneficiary.flatMap {
                    $0.lifeStageAtPlan == .mature
                        ? $0.agentID : $0.guardianIDAtPlan
                },
                status: status,
                blockReason: reason,
                settlementAttemptCount: 0,
                destinationObservation: nil,
                settlementObservation: nil,
                settlementReceiptID: nil,
                settlementEventID: nil
            ))
        }
        var physicalByIdentity: [AgentMaterialIdentitySnapshot: Int] = [:]
        for physical in physicalAssets {
            physicalByIdentity[physical.identity, default: 0] += physical.count
        }
        var residualOrdinal = 0
        for identity in physicalByIdentity.keys.sorted(by: {
            estateMaterialIdentityText($0) < estateMaterialIdentityText($1)
        }) {
            let tracked = trackedByIdentity[identity, default: 0]
            let residual = physicalByIdentity[identity, default: 0] - tracked
            guard residual >= 0 else {
                throw AgentSessionError.estate(.invalidState(
                    "tracked quantity exceeds physical custody"
                ))
            }
            guard residual > 0 else { continue }
            residualOrdinal += 1
            let entryID = AgentEstateAssetEntryID(
                rawValue: "estateasset-" + AgentEstateDigest.make(
                    "\(estateID.rawValue)|residual|\(residualOrdinal)|"
                        + estateMaterialIdentityText(identity)
                )
            )!
            entries.append(AgentEstateAssetEntry(
                entryID: entryID,
                materialRightsAssetID: nil,
                materialIdentity: identity,
                quantity: residual,
                mortalityExitReceiptID:
                    physicalCustodyResolution.physicalReceiptID,
                mortalityExitHolderID:
                    physicalCustodyResolution.destinationHolderID,
                mortalityExitTick: physicalCustodyResolution.verifiedAtTick,
                holderAtOpening: nil,
                custodianAtOpening: nil,
                ownerAtOpening: nil,
                claimsAtOpening: [],
                permissionsAtOpening: [],
                classificationEventID: nil,
                assignedBeneficiaryID: nil,
                intendedCustodianID: nil,
                status: .blocked,
                blockReason: .sociallyUnregistered,
                settlementAttemptCount: 0,
                destinationObservation: nil,
                settlementObservation: nil,
                settlementReceiptID: nil,
                settlementEventID: nil
            ))
        }
        return entries.sorted { $0.entryID < $1.entryID }
    }

    private func validateEstateCustodyDestination(
        beneficiaryID: AgentID,
        intendedCustodianID: AgentID?,
        destination: AgentMaterialHolderObservation
    ) throws {
        guard let stage = lifecycleState?.members.first(where: {
            $0.agentID == beneficiaryID
        })?.currentStage else {
            throw AgentSessionError.estate(.invalidSettlement(
                "beneficiary unavailable"
            ))
        }
        if stage == .mature {
            guard intendedCustodianID == beneficiaryID,
                  destination.holder == .agent(beneficiaryID),
                  statesById[beneficiaryID.rawValue] != nil,
                  !isMigratingAgent(beneficiaryID.rawValue) else {
                throw AgentSessionError.estate(.invalidSettlement(
                    "adult custody"
                ))
            }
        } else {
            guard let intendedCustodianID,
                  dependentCareState?.childhoodV2?.guardianships.contains(where: {
                      $0.dependentID == beneficiaryID
                          && $0.guardianID == intendedCustodianID
                          && $0.status == .active
                  }) == true,
                  destination.holder == .agent(intendedCustodianID),
                  estateAdministratorIsAvailable(intendedCustodianID) else {
                throw AgentSessionError.estate(.invalidSettlement(
                    "minor custody"
                ))
            }
        }
    }

    private mutating func prevalidateEstateTransitions(
        _ authority: inout AgentEstateState,
        count: Int,
        at transitionTick: Int
    ) throws {
        guard count >= 0 else {
            throw AgentSessionError.estate(.invalidState("transition count"))
        }
        if authority.transitionTick != transitionTick {
            authority.transitionTick = transitionTick
            authority.transitionsAtTick = 0
        }
        guard authority.transitionsAtTick + count
                <= authority.configuration.maximumTransitionsPerTick else {
            throw AgentSessionError.estate(.capacityExceeded("transitions"))
        }
        authority.transitionsAtTick += count
        try prevalidateCausalAppend(count: count)
    }

    private mutating func requiredEstateEvent(
        kind: AgentCausalEventKind,
        actorID: AgentID? = nil,
        subjectID: AgentID? = nil,
        operationID: AgentOperationID? = nil,
        causes: [AgentCausalEventID] = [],
        payload: AgentCausalPayload,
        summary: String
    ) throws -> AgentCausalEvent {
        guard let event = try recordCausalEvent(
            kind: kind,
            origin: .estateTransition,
            actorID: actorID,
            subjectID: subjectID,
            operationID: operationID,
            causes: causes,
            payload: payload,
            summary: summary
        ) else {
            throw AgentSessionError.estate(.causalLedgerRequired)
        }
        return event
    }

    private func validEstateOperationID(_ value: String) -> Bool {
        (1...256).contains(value.utf8.count)
            && value.utf8.allSatisfy {
                (65...90).contains($0) || (97...122).contains($0)
                    || (48...57).contains($0)
                    || $0 == 45 || $0 == 95 || $0 == 58 || $0 == 46
            }
    }

    private static func estateStateDigest(
        _ authority: AgentEstateState
    ) -> String {
        let estates = authority.estates.sorted {
            $0.estateID < $1.estateID
        }.map { estate in
            let admins = estate.administrations.map {
                "\($0.administratorID.rawValue):\($0.basis.rawValue):"
                    + "\($0.status.rawValue):\($0.acceptanceOperationID ?? "none")"
            }.joined(separator: ",")
            let beneficiaries = estate.beneficiaries.map {
                "\($0.agentID.rawValue):\($0.basis.rawValue):"
                    + "\($0.allocationCount)"
            }.joined(separator: ",")
            let assets = estate.assets.map {
                "\($0.entryID.rawValue):\($0.materialRightsAssetID?.rawValue ?? "none"):"
                    + "\($0.quantity):\($0.status.rawValue):"
                    + "\($0.blockReason?.rawValue ?? "none"):"
                    + "\($0.settlementReceiptID ?? "none")"
            }.joined(separator: ",")
            return "\(estate.estateID.rawValue)|\(estate.deathID.rawValue)|"
                + "\(estate.status.rawValue)|\(admins)|\(beneficiaries)|\(assets)"
        }.joined(separator: ";")
        return AgentEstateDigest.make(
            "\(authority.activationTick)|\(authority.activationDeathCount)|"
                + "\(authority.totalEstateCount)|\(authority.totalSettlementCount)|"
                + "\(authority.evictionCounts.settledEstates)|\(estates)|"
                + "\(authority.processedOperationIDs.joined(separator: ","))"
        )
    }
}

private func estateMaterialIdentityText(
    _ identity: AgentMaterialIdentitySnapshot
) -> String {
    let enchantments = identity.enchantments.map {
        "\($0.id):\($0.level)"
    }.joined(separator: ",")
    return "\(identity.itemKey)|\(identity.damage)|\(enchantments)|"
        + "\(identity.label ?? "none")|\(identity.canonicalDataJSON)"
}
