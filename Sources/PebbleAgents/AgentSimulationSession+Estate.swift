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
        guard mortality.historicalEvidenceVersion
                == AgentCompactedDeathSummary.currentVersion,
              let compactedDeaths = mortality.compactedDeathSummaries,
              compactedDeaths.count == mortality.evictionCounts.deathRecords,
              compactedDeaths.allSatisfy({
                  $0.demographicAgeTicks != nil
                      && $0.lifeStageAtDeath != nil
              }) else {
            throw AgentSessionError.estate(.invalidState(
                "historical mortality evidence"
            ))
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
        guard let kinship = kinshipState else {
            throw AgentSessionError.estate(.kinshipRequired)
        }
        guard compactedDeaths.count
                <= kinship.configuration.maximumHistoricalPersons else {
            throw AgentSessionError.estate(.capacityExceeded(
                "historical mortality evidence"
            ))
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
        recomputeEstateOperationalStatus(
            estateIndex: estateIndex, authority: &authority
        )
        authority.estates[estateIndex].lastEventID = event.eventID
        authority.processedOperationIDs.append(operationID)
        authority.processedOperationIDs.sort()
        authority.lastEventID = event.eventID
        authority.rollingDigest = Self.estateStateDigest(authority)
        estateState = authority
        try validateEstateCrossDomainIfEnabled()
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
              outcome.operationID == outcome.physicalReceiptID,
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
            recomputeEstateOperationalStatus(
                estateIndex: estateIndex, authority: &authority
            )
        }
        authority.rollingDigest = Self.estateStateDigest(authority)
        estateState = authority
        try validateEstateCrossDomainIfEnabled()
        return authority.estates[estateIndex].assets[entryIndex]
    }

    mutating func openEstateForMortality(
        decedentID: AgentID,
        deathID: AgentDeathID,
        lethalAgentIDs: Set<AgentID>,
        mortality: AgentMortalityState,
        physicalCustodyResolution: AgentMortalityPhysicalCustodyResolution,
        causeEventID: AgentCausalEventID,
        at deathTick: Int
    ) throws -> (
        estateID: AgentEstateID,
        deathIDToEvict: AgentDeathID?
    )? {
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
        let deathIDToEvict =
            mortality.records.count
                >= mortality.configuration.maximumRetainedDeathRecords
            ? mortality.records.first?.deathID : nil
        if let deathIDToEvict,
           let evictionIndex = authority.estates.firstIndex(where: {
               $0.deathID == deathIDToEvict
           }) {
            guard authority.estates[evictionIndex].status.isTerminal,
                  let deathToEvict = mortality.records.first(where: {
                      $0.deathID == deathIDToEvict
                  }),
                  !estateDeathHasRetainedDurableDependency(deathToEvict)
            else {
                throw AgentSessionError.estate(.capacityExceeded("estates"))
            }
            authority.estates.remove(at: evictionIndex)
            authority.evictionCounts.settledEstates += 1
        } else if deathIDToEvict != nil {
            let retainedPreActivationDeaths = max(
                0,
                authority.activationDeathCount
                    - mortality.evictionCounts.deathRecords
            )
            guard retainedPreActivationDeaths > 0 else {
                throw AgentSessionError.estate(.invalidState(
                    "uncoordinated mortality retention"
                ))
            }
        }
        guard authority.estates.count
                < authority.configuration.maximumRetainedEstates else {
            throw AgentSessionError.estate(.capacityExceeded("estates"))
        }
        let digest = AgentEstateDigest.make(
            "\(simulationID.rawValue)|\(decedentID.rawValue)|"
                + "\(deathID.rawValue)|27"
        )
        let estateID = AgentEstateID(
            rawValue: "estate-\(digest)"
        )!
        let activeUnion = familyState?.unions.first(where: {
            $0.status == .active && $0.partnerIDs.contains(decedentID)
        })
        let partnerID = activeUnion?.partnerIDs.first { $0 != decedentID }
        let plan = try estateBeneficiaryPlan(
            decedentID: decedentID,
            activeUnion: activeUnion,
            lethalAgentIDs: lethalAgentIDs,
            deathTick: deathTick
        )
        guard plan.eligibilityRows.count
                <= authority.configuration.maximumBeneficiariesPerEstate * 4
        else {
            throw AgentSessionError.estate(.capacityExceeded(
                "successor eligibility proof"
            ))
        }
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
        let planDigest = Self.estateSuccessorPlanDigest(
            version: 1,
            estateID: estateID,
            decedentID: decedentID,
            deathID: deathID,
            deathBoundaryTick: deathTick,
            selectedTier: plan.tier,
            eligibilityRows: plan.eligibilityRows,
            activeUnionAtDeath: plan.activeUnionAtDeath
        )
        let planEvent = try requiredEstateEvent(
            kind: .estateSuccessorPlanCreated,
            subjectID: decedentID,
            causes: [opened.eventID, causeEventID].sorted(),
            payload: .operation(
                status: plan.tier.rawValue,
                detail: "\(estateID.rawValue)|"
                    + plan.beneficiaries.map {
                        $0.agentID.rawValue
                    }.joined(separator: ",")
                    + "|\(planDigest)"
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
        let status = Self.recomputedEstateOperationalStatus(
            currentStatus: allAssetsTerminal ? .settled : .openUnadministered,
            beneficiaries: plan.beneficiaries,
            administrations: administrations,
            assets: assets
        )
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
            successorPlanProof: AgentEstateSuccessorPlanProof(
                version: 1,
                estateID: estateID,
                decedentID: decedentID,
                deathID: deathID,
                deathBoundaryTick: deathTick,
                selectedTier: plan.tier,
                eligibilityRows: plan.eligibilityRows,
                activeUnionAtDeath: plan.activeUnionAtDeath,
                successorPlanEventID: planEvent.eventID,
                planDigest: planDigest
            ),
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
        return (estateID, deathIDToEvict)
    }

    private func estateDeathHasRetainedDurableDependency(
        _ death: AgentMortalityRecord
    ) -> Bool {
        if geneticsState?.genotypes.contains(where: {
            $0.agentID == death.agentID
        }) == true {
            return true
        }
        if materialRightsState?.records.contains(where: { record in
            record.lastVerifiedHolder.holder == .agent(death.agentID)
                || record.custodianID == death.agentID
                || record.claims.contains {
                    $0.claimantID == death.agentID
                }
                || record.permissions.contains {
                    $0.grantorID == death.agentID
                        || $0.userID == death.agentID
                }
                || record.recognizedOwnership.map {
                    $0.ownerID == death.agentID
                        || $0.recognizingAgentIDs.contains(death.agentID)
                } == true
        }) == true {
            return true
        }
        guard let family = familyState else { return false }
        return family.unions.contains {
            $0.terminationReason == .partnerDeath
                && $0.terminationTick == death.deathTick
                && $0.partnerIDs.contains(death.agentID)
        } || family.houseMembershipPeriods.contains {
            $0.agentID == death.agentID
                && $0.endReason == .memberDeath
                && $0.leftTick == death.deathTick
        }
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
                authority.estates[estateIndex].lastEventID = event.eventID
                authority.lastEventID = event.eventID
                try nominateReplacementEstateAdministrator(
                    estateIndex: estateIndex,
                    lethalAgentIDs: lethalAgentIDs,
                    causeEventID: event.eventID,
                    at: boundaryTick,
                    authority: &authority
                )
                recomputeEstateOperationalStatus(
                    estateIndex: estateIndex, authority: &authority
                )
            }
        }
        authority.rollingDigest = Self.estateStateDigest(authority)
        estateState = authority
    }

    mutating func applyEstateTickBoundary(at boundaryTick: Int) throws {
        try revalidateEstateCustodyAssignments(
            for: nil, at: boundaryTick
        )
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
            authority.estates[estateIndex].lastEventID = event.eventID
            authority.lastEventID = event.eventID
            try nominateReplacementEstateAdministrator(
                estateIndex: estateIndex,
                lethalAgentIDs: [],
                causeEventID: event.eventID,
                at: boundaryTick,
                authority: &authority
            )
            recomputeEstateOperationalStatus(
                estateIndex: estateIndex, authority: &authority
            )
        }
        authority.rollingDigest = Self.estateStateDigest(authority)
        estateState = authority
        try validateEstateCrossDomainIfEnabled()
    }

    mutating func revalidateEstateCustodyAssignments(
        for dependentID: AgentID?,
        at revalidationTick: Int
    ) throws {
        guard var authority = estateState,
              let lifecycle = lifecycleState,
              let childhood = dependentCareState?.childhoodV2 else {
            return
        }
        let retryableReasons: Set<AgentEstateAssetBlockReason> = [
            .minorCustodyUnavailable,
            .beneficiaryUnavailableForCustody,
        ]
        for estateIndex in authority.estates.indices
            where !authority.estates[estateIndex].status.isTerminal {
            for entryIndex in authority.estates[estateIndex].assets.indices {
                let entry = authority.estates[estateIndex].assets[entryIndex]
                guard !entry.status.isTerminal,
                      let beneficiaryID = entry.assignedBeneficiaryID,
                      dependentID == nil || beneficiaryID == dependentID,
                      entry.blockReason == nil
                        || retryableReasons.contains(entry.blockReason!),
                      let stage = lifecycle.members.first(where: {
                          $0.agentID == beneficiaryID
                      })?.currentStage else {
                    continue
                }
                let guardianship = childhood.guardianships.last {
                    $0.dependentID == beneficiaryID && $0.status == .active
                }
                let intendedCustodianID: AgentID?
                let blockReason: AgentEstateAssetBlockReason?
                if stage == .mature {
                    intendedCustodianID = beneficiaryID
                    blockReason =
                        estateAdministratorIsAvailable(beneficiaryID)
                        ? nil : .beneficiaryUnavailableForCustody
                } else {
                    intendedCustodianID = guardianship?.guardianID
                    blockReason =
                        guardianship.map {
                            estateAdministratorIsAvailable($0.guardianID)
                        } == true
                        ? nil : .minorCustodyUnavailable
                }
                let status: AgentEstateAssetStatus =
                    blockReason == nil ? .pendingSettlement : .blocked
                guard entry.intendedCustodianID != intendedCustodianID
                        || entry.blockReason != blockReason
                        || entry.status != status else {
                    continue
                }
                try prevalidateEstateTransitions(
                    &authority, count: 1, at: revalidationTick
                )
                let cause = guardianship?.startedEventID
                    ?? entry.custodyRevalidationEventID
                    ?? entry.classificationEventID
                    ?? authority.estates[estateIndex].successorPlanEventID
                let event = try requiredEstateEvent(
                    kind: blockReason == nil
                        ? .estateAssetClassified : .estateAssetBlocked,
                    actorID: intendedCustodianID,
                    subjectID: beneficiaryID,
                    causes: [cause],
                    payload: .operation(
                        status: "custodyRevalidated",
                        detail: "\(entry.entryID.rawValue)|"
                            + "\(intendedCustodianID?.rawValue ?? "none")|"
                            + "\(blockReason?.rawValue ?? "available")"
                    ),
                    summary: "estate custody revalidated entry="
                        + "\(entry.entryID.rawValue) beneficiary="
                        + beneficiaryID.rawValue
                )
                authority.estates[estateIndex].assets[entryIndex]
                    .intendedCustodianID = intendedCustodianID
                authority.estates[estateIndex].assets[entryIndex]
                    .blockReason = blockReason
                authority.estates[estateIndex].assets[entryIndex]
                    .status = status
                authority.estates[estateIndex].assets[entryIndex]
                    .custodyRevalidatedAtTick = revalidationTick
                authority.estates[estateIndex].assets[entryIndex]
                    .custodyRevalidationEventID = event.eventID
                authority.estates[estateIndex].lastEventID = event.eventID
                authority.lastEventID = event.eventID
            }
            recomputeEstateOperationalStatus(
                estateIndex: estateIndex, authority: &authority
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
                currentTick: tick,
                schemaVersion: authority.estates.allSatisfy({
                    $0.successorPlanProof != nil
                }) ? AgentCheckpointSchema.estateVersion
                    : AgentCheckpointSchema.legacyEstateVersion
            )
        } catch let error as AgentEstateError {
            throw AgentSessionError.estate(error)
        }
    }

    /// Keeps the current physical projection of an already transferred estate
    /// asset aligned with a later verified use. The immutable settlement
    /// observation and receipt remain untouched; only the entry's current
    /// destination observation follows Material Rights physical truth.
    mutating func synchronizeTransferredEstateAssetObservation(
        assetID: AgentMaterialAssetID,
        source: AgentMaterialHolderObservation,
        destination: AgentMaterialHolderObservation
    ) throws {
        guard var authority = estateState else { return }
        let matches = authority.estates.indices.flatMap { estateIndex in
            authority.estates[estateIndex].assets.indices.compactMap {
                entryIndex -> (Int, Int)? in
                authority.estates[estateIndex].assets[entryIndex]
                    .materialRightsAssetID == assetID
                    ? (estateIndex, entryIndex) : nil
            }
        }
        guard matches.count <= 1 else {
            throw AgentSessionError.estate(.invalidState(
                "duplicate transferred asset observation"
            ))
        }
        guard let (estateIndex, entryIndex) = matches.first else { return }
        let entry = authority.estates[estateIndex].assets[entryIndex]
        guard entry.status == .transferred,
              entry.destinationObservation == source,
              entry.settlementObservation != nil,
              entry.settlementReceiptID != nil,
              destination.holder == source.holder,
              destination.quantity == source.quantity,
              destination.materialIdentity.itemKey
                == source.materialIdentity.itemKey else {
            throw AgentSessionError.estate(.invalidState(
                "transferred asset current observation"
            ))
        }
        authority.estates[estateIndex].assets[entryIndex]
            .destinationObservation = destination
        authority.rollingDigest = Self.estateStateDigest(authority)
        estateState = authority
        try validateEstateCrossDomainIfEnabled()
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
        currentTick: Int,
        schemaVersion: Int
    ) throws {
        guard schemaVersion == AgentCheckpointSchema.legacyEstateVersion
                || schemaVersion == AgentCheckpointSchema.estateVersion
                || schemaVersion
                    == AgentCheckpointSchema.renewableSubsistenceVersion
                || schemaVersion
                    == AgentCheckpointSchema
                        .independentEcologicalReceiptVersion
                || schemaVersion == AgentCheckpointSchema.productionVersion
                || schemaVersion == AgentCheckpointSchema.barterVersion else {
            throw AgentEstateError.invalidState("checkpoint schema")
        }
        if schemaVersion >= AgentCheckpointSchema.estateVersion,
           authority.estates.contains(where: {
               $0.successorPlanProof == nil
           }) {
            throw AgentEstateError.invalidState(
                "schema 28 requires successor plan proof"
            )
        }
        if schemaVersion >= AgentCheckpointSchema.estateVersion {
            guard mortality.historicalEvidenceVersion
                    == AgentCompactedDeathSummary.currentVersion,
                  let summaries = mortality.compactedDeathSummaries,
                  summaries.count == mortality.evictionCounts.deathRecords,
                  summaries.count
                    <= mortality.configuration
                        .maximumCompactedDeathSummaries,
                  summaries.allSatisfy({
                      $0.demographicAgeTicks != nil
                          && $0.lifeStageAtDeath != nil
                  }) else {
                throw AgentEstateError.invalidState(
                    "historical mortality evidence"
                )
            }
        }
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
              authority.evictionCounts.settledEstates == max(
                0,
                mortality.evictionCounts.deathRecords
                    - authority.activationDeathCount
              ),
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
            let actualPlan = estate.beneficiaries.map {
                "\($0.agentID.rawValue)|\($0.basis.rawValue)|\($0.weight)|"
                    + "\($0.lifeStageAtPlan.rawValue)|"
                    + "\($0.guardianIDAtPlan?.rawValue ?? "none")"
            }
            if estate.successorPlanProof == nil {
                guard schemaVersion
                        == AgentCheckpointSchema.legacyEstateVersion else {
                    throw AgentEstateError.invalidState(
                        "legacy successor plan schema"
                    )
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
                let durablePlan = expectedPlan.beneficiaries.map {
                    "\($0.agentID.rawValue)|\($0.basis.rawValue)|"
                        + "\($0.weight)|\($0.lifeStageAtPlan.rawValue)|"
                        + "\($0.guardianIDAtPlan?.rawValue ?? "none")"
                }
                guard estate.beneficiaryTier == expectedPlan.tier,
                      actualPlan == durablePlan,
                      mortality.evictionCounts.deathRecords == 0,
                      let planEvent = try retainedCausalEvent(
                        estate.successorPlanEventID
                      ),
                      planEvent.kind == .estateSuccessorPlanCreated,
                      planEvent.origin == .estateTransition,
                      planEvent.actorID == nil,
                      planEvent.subjectID == estate.decedentID,
                      planEvent.simulationTick.rawValue == estate.deathTick,
                      planEvent.causes == [estate.openingEventID],
                      planEvent.payload == .operation(
                        status: expectedPlan.tier.rawValue,
                        detail: expectedPlan.beneficiaries.map {
                            $0.agentID.rawValue
                        }.joined(separator: ",")
                      ) else {
                    throw AgentEstateError.invalidState(
                        "legacy successor plan is not exactly revalidable"
                    )
                }
            } else {
                guard let proof = estate.successorPlanProof,
                      proof.version == 1,
                      proof.estateID == estate.estateID,
                      proof.decedentID == estate.decedentID,
                      proof.deathID == estate.deathID,
                      proof.deathBoundaryTick == estate.deathTick,
                      proof.selectedTier == estate.beneficiaryTier,
                      proof.successorPlanEventID
                        == estate.successorPlanEventID,
                      proof.eligibilityRows
                        == proof.eligibilityRows.sorted(
                            by: Self.estateEligibilityRowLess
                        ),
                      proof.eligibilityRows.count
                        <= authority.configuration
                            .maximumBeneficiariesPerEstate * 4,
                      Set(proof.eligibilityRows.map(\.agentID)).count
                        == proof.eligibilityRows.count,
                      proof.planDigest == Self.estateSuccessorPlanDigest(
                        version: proof.version,
                        estateID: proof.estateID,
                        decedentID: proof.decedentID,
                        deathID: proof.deathID,
                        deathBoundaryTick: proof.deathBoundaryTick,
                        selectedTier: proof.selectedTier,
                        eligibilityRows: proof.eligibilityRows,
                        activeUnionAtDeath: proof.activeUnionAtDeath
                      ) else {
                    throw AgentEstateError.invalidState(
                        "durable successor plan proof"
                    )
                }
                let relationships =
                    Self.estateRelationshipsForValidation(
                        decedentID: estate.decedentID,
                        deathTick: estate.deathTick,
                        family: family,
                        kinship: kinship
                    )
                let proofRelationships = proof.eligibilityRows.map {
                    ($0.agentID, $0.tier, $0.basis)
                }
                guard Self.estateRelationshipTexts(relationships)
                        == Self.estateRelationshipTexts(proofRelationships)
                else {
                    throw AgentEstateError.invalidState(
                        "successor relationship rows"
                    )
                }
                let selectedTier = [
                    AgentEstateBeneficiaryTier
                        .primaryPartnerAndChildren,
                    .secondaryParents,
                    .tertiarySiblings,
                ].first { candidateTier in
                    proof.eligibilityRows.contains {
                        $0.tier == candidateTier && $0.eligibleAtDeath
                    }
                } ?? .none
                let expectedBeneficiaries =
                    proof.eligibilityRows.compactMap { row
                        -> AgentEstateBeneficiary? in
                        guard row.tier == selectedTier,
                              row.eligibleAtDeath,
                              let stage = row.lifeStageAtPlan else {
                            return nil
                        }
                        return AgentEstateBeneficiary(
                            agentID: row.agentID,
                            tier: selectedTier,
                            basis: row.basis,
                            weight: 1,
                            lifeStageAtPlan: stage,
                            guardianIDAtPlan: row.guardianIDAtPlan,
                            allocationCount: estate.beneficiaries.first {
                                $0.agentID == row.agentID
                            }?.allocationCount ?? 0
                        )
                    }
                guard proof.selectedTier == selectedTier,
                      estate.beneficiaries == expectedBeneficiaries else {
                    throw AgentEstateError.invalidState(
                        "exact successor beneficiary list"
                    )
                }
                for row in proof.eligibilityRows {
                    guard row.agentID != estate.decedentID,
                          knownPeople.contains(row.agentID),
                          row.tier != .none,
                          row.lifeStageAtPlan != nil,
                          row.lifeStageAtPlan == .mature
                            ? row.guardianIDAtPlan == nil : true else {
                        throw AgentEstateError.invalidState(
                            "successor eligibility row"
                        )
                    }
                    let historical = try Self.estateHistoricalEligibility(
                        agentID: row.agentID,
                        at: estate.deathTick,
                        activeIDs: activeIDs,
                        lifecycle: lifecycle,
                        mortality: mortality
                    )
                    guard row.eligibleAtDeath == historical.eligible else {
                        throw AgentEstateError.invalidState(
                            "successor mortality eligibility"
                        )
                    }
                    guard row.lifeStageAtPlan == historical.lifeStage else {
                        throw AgentEstateError.invalidState(
                            "successor life stage at plan"
                        )
                    }
                    if row.eligibleAtDeath,
                       row.lifeStageAtPlan != .mature {
                        let guardian = childhood.guardianships.last {
                            $0.dependentID == row.agentID
                                && $0.startedEventID.sequence
                                    < estate.successorPlanEventID.sequence
                                && ($0.endedEventID == nil
                                    || $0.endedEventID!.sequence
                                        > estate.successorPlanEventID.sequence)
                        }?.guardianID
                        guard row.guardianIDAtPlan == guardian else {
                            throw AgentEstateError.invalidState(
                                "successor guardian at plan"
                            )
                        }
                    } else if row.guardianIDAtPlan != nil {
                        throw AgentEstateError.invalidState(
                            "ineligible successor guardian"
                        )
                    }
                }
                let unionAtDeath = family.unions.first {
                    $0.partnerIDs.contains(estate.decedentID)
                        && $0.activationTick <= estate.deathTick
                        && ($0.terminationTick == nil
                            || ($0.terminationTick == estate.deathTick
                                && $0.terminationReason == .partnerDeath))
                }
                let expectedUnionEvidence = unionAtDeath.flatMap { union in
                    union.partnerIDs.first {
                        $0 != estate.decedentID
                    }.map {
                        AgentEstateActiveUnionAtDeathEvidence(
                            unionID: union.unionID,
                            partnerID: $0,
                            activationTick: union.activationTick,
                            activationEventID: union.activationEventID
                        )
                    }
                }
                guard proof.activeUnionAtDeath == expectedUnionEvidence else {
                    throw AgentEstateError.invalidState(
                        "active union at death proof"
                    )
                }
                if let planEvent = try retainedCausalEvent(
                    estate.successorPlanEventID
                ) {
                    guard planEvent.kind == .estateSuccessorPlanCreated,
                          planEvent.origin == .estateTransition,
                          planEvent.actorID == nil,
                          planEvent.subjectID == estate.decedentID,
                          planEvent.simulationTick.rawValue
                            == estate.deathTick,
                          planEvent.causes == [
                            estate.openingEventID,
                            death.lethalDamageEventID,
                          ].sorted(),
                          planEvent.payload == .operation(
                            status: proof.selectedTier.rawValue,
                            detail: "\(estate.estateID.rawValue)|"
                                + estate.beneficiaries.map {
                                    $0.agentID.rawValue
                                }.joined(separator: ",")
                                + "|\(proof.planDigest)"
                          ) else {
                        throw AgentEstateError.invalidState(
                            "successor plan causal event"
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
                    let ownerWasDecedent =
                        entry.ownerAtOpening?.ownerID == estate.decedentID
                    let hadThirdPartyClaim = entry.claimsAtOpening.contains {
                        $0.claimantID != estate.decedentID
                    }
                    let beneficiaryAtPlan =
                        entry.assignedBeneficiaryID.flatMap { id in
                            estate.beneficiaries.first {
                                $0.agentID == id
                            }
                        }
                    let expectedKind: AgentCausalEventKind =
                        entry.materialRightsAssetID == nil
                            || hadThirdPartyClaim
                            || (ownerWasDecedent
                                && (estate.beneficiaries.isEmpty
                                    || (beneficiaryAtPlan?
                                        .lifeStageAtPlan != .mature
                                        && beneficiaryAtPlan?
                                            .guardianIDAtPlan == nil)))
                            ? .estateAssetBlocked : .estateAssetClassified
                    let originalStatus: AgentEstateAssetStatus =
                        entry.materialRightsAssetID == nil
                            ? .blocked
                            : (hadThirdPartyClaim
                                ? .blocked
                                : (!ownerWasDecedent
                                    ? .nonTransferable
                                    : (estate.beneficiaries.isEmpty
                                        || (beneficiaryAtPlan?
                                            .lifeStageAtPlan != .mature
                                            && beneficiaryAtPlan?
                                                .guardianIDAtPlan == nil)
                                        ? .blocked : .pendingSettlement)))
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
                    let custodyStage =
                        entry.custodyRevalidatedAtTick.flatMap {
                            Self.estateLifeStageForValidation(
                                agentID: beneficiary.agentID,
                                at: $0,
                                lifecycle: lifecycle,
                                mortality: mortality
                            )
                        }
                    let expectedCustodian: AgentID?
                    if entry.custodyRevalidationEventID == nil {
                        expectedCustodian =
                            beneficiary.lifeStageAtPlan == .mature
                                ? beneficiary.agentID
                                : beneficiary.guardianIDAtPlan
                    } else if custodyStage == .mature {
                        expectedCustodian = beneficiary.agentID
                    } else {
                        expectedCustodian = childhood.guardianships.last {
                            $0.dependentID == beneficiary.agentID
                                && $0.status == .active
                        }?.guardianID
                    }
                    guard entry.intendedCustodianID
                            == expectedCustodian else {
                        throw AgentEstateError.invalidState(
                            "asset custody assignment"
                        )
                    }
                    if entry.custodyRevalidationEventID != nil,
                       !entry.status.isTerminal {
                        let custodianAvailable = expectedCustodian.map { id in
                            (activeStates[id.rawValue]?.health ?? 0) > 0
                                && population.members.contains {
                                    $0.agentID == id
                                        && ($0.status == .resident
                                            || $0.status
                                                == .founderResident)
                                }
                                && homeostasis?.profiles.first {
                                    $0.agentID == id
                                }?.vitalStatus != .incapacitated
                        } == true
                        let expectedReason:
                            AgentEstateAssetBlockReason? =
                            custodianAvailable
                            ? nil
                            : (custodyStage == .mature
                                ? .beneficiaryUnavailableForCustody
                                : .minorCustodyUnavailable)
                        guard entry.blockReason == expectedReason,
                              entry.status == (expectedReason == nil
                                ? .pendingSettlement : .blocked) else {
                            throw AgentEstateError.invalidState(
                                "revalidated custody availability"
                            )
                        }
                    }
                } else if entry.intendedCustodianID != nil {
                    throw AgentEstateError.invalidState(
                        "unassigned asset custodian"
                    )
                }
                if let revalidationEventID =
                    entry.custodyRevalidationEventID {
                    guard let revalidatedAtTick =
                            entry.custodyRevalidatedAtTick,
                          revalidatedAtTick >= estate.deathTick,
                          revalidatedAtTick <= currentTick else {
                        throw AgentEstateError.invalidState(
                            "custody revalidation tick"
                        )
                    }
                    if let revalidation = try retainedCausalEvent(
                        revalidationEventID
                    ) {
                        let custodianText =
                            entry.intendedCustodianID?.rawValue ?? "none"
                        let reasonText =
                            entry.blockReason?.rawValue ?? "available"
                        guard revalidation.kind
                                == (entry.blockReason == nil
                                    ? .estateAssetClassified
                                    : .estateAssetBlocked),
                              revalidation.origin == .estateTransition,
                              revalidation.actorID
                                == entry.intendedCustodianID,
                              revalidation.subjectID
                                == entry.assignedBeneficiaryID,
                              revalidation.simulationTick.rawValue
                                == revalidatedAtTick,
                              revalidation.payload == .operation(
                                status: "custodyRevalidated",
                                detail: "\(entry.entryID.rawValue)|"
                                    + "\(custodianText)|\(reasonText)"
                              ) else {
                            throw AgentEstateError.invalidState(
                                "custody revalidation event"
                            )
                        }
                    }
                } else if entry.custodyRevalidatedAtTick != nil {
                    throw AgentEstateError.invalidState(
                        "orphan custody revalidation"
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
            let expectedOperationalStatus =
                Self.recomputedEstateOperationalStatus(
                    currentStatus: estate.status,
                    beneficiaries: estate.beneficiaries,
                    administrations: estate.administrations,
                    assets: estate.assets
                )
            guard estate.status == expectedOperationalStatus else {
                throw AgentEstateError.invalidState(
                    "estate operational status"
                )
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
        activeUnion: AgentUnionRecord?,
        lethalAgentIDs: Set<AgentID>,
        deathTick: Int
    ) throws -> (
        tier: AgentEstateBeneficiaryTier,
        beneficiaries: [AgentEstateBeneficiary],
        eligibilityRows: [AgentEstateSuccessorEligibilityRow],
        activeUnionAtDeath: AgentEstateActiveUnionAtDeathEvidence?
    ) {
        var candidates:
            [(AgentID, AgentEstateBeneficiaryTier, AgentEstateBeneficiaryBasis)]
            = []
        let activePartnerID = activeUnion?.partnerIDs.first {
            $0 != decedentID
        }
        if let activePartnerID {
            candidates.append((
                activePartnerID,
                .primaryPartnerAndChildren,
                .activeUnionPartnerAtDeath
            ))
        }
        for child in try children(of: decedentID) {
            candidates.append((
                child, .primaryPartnerAndChildren, .canonicalChild
            ))
        }
        for parent in (try parents(of: decedentID)) ?? [] {
            candidates.append((parent, .secondaryParents, .canonicalParent))
        }
        for person in kinshipState?.historicalPersons.map(\.agentID).sorted()
            ?? [] {
            switch siblingRelation(between: decedentID, and: person) {
            case .fullSibling:
                candidates.append((person, .tertiarySiblings, .fullSibling))
            case .halfSibling:
                candidates.append((person, .tertiarySiblings, .halfSibling))
            default:
                break
            }
        }
        var seen = Set<AgentID>()
        let canonical = candidates.filter {
            $0.0 != decedentID && seen.insert($0.0).inserted
        }.sorted(by: Self.estateEligibilityRowLess)
        guard let mortality = mortalityState,
              let lifecycle = lifecycleState else {
            throw AgentSessionError.estate(.lifecycleRequired)
        }
        let activeIDs = Set(statesById.values.map(\.agentID))
        let eligibilityRows = try canonical.map { id, tier, basis in
            let historical = try Self.estateHistoricalEligibility(
                agentID: id,
                at: deathTick,
                activeIDs: activeIDs,
                lifecycle: lifecycle,
                mortality: mortality
            )
            let eligible = historical.eligible
                && !lethalAgentIDs.contains(id)
            let guardian = eligible && historical.lifeStage != .mature
                ? dependentCareState?.childhoodV2?.guardianships.last {
                    $0.dependentID == id && $0.status == .active
                }?.guardianID : nil
            return AgentEstateSuccessorEligibilityRow(
                agentID: id,
                tier: tier,
                basis: basis,
                eligibleAtDeath: eligible,
                lifeStageAtPlan: historical.lifeStage,
                guardianIDAtPlan: guardian
            )
        }
        let tier = [
            AgentEstateBeneficiaryTier.primaryPartnerAndChildren,
            .secondaryParents,
            .tertiarySiblings,
        ].first {
            let candidateTier = $0
            return eligibilityRows.contains {
                $0.tier == candidateTier && $0.eligibleAtDeath
            }
        } ?? .none
        let beneficiaries: [AgentEstateBeneficiary] =
            eligibilityRows.compactMap { row -> AgentEstateBeneficiary? in
            guard row.tier == tier, row.eligibleAtDeath,
                  let stage = row.lifeStageAtPlan else {
                return nil
            }
            return AgentEstateBeneficiary(
                agentID: row.agentID, tier: tier, basis: row.basis, weight: 1,
                lifeStageAtPlan: stage,
                guardianIDAtPlan: row.guardianIDAtPlan,
                allocationCount: 0
            )
        }
        let unionEvidence = activeUnion.flatMap { union in
            activePartnerID.map {
                AgentEstateActiveUnionAtDeathEvidence(
                    unionID: union.unionID,
                    partnerID: $0,
                    activationTick: union.activationTick,
                    activationEventID: union.activationEventID
                )
            }
        }
        return (tier, beneficiaries, eligibilityRows, unionEvidence)
    }

    private static func estateEligibilityTierRank(
        _ tier: AgentEstateBeneficiaryTier
    ) -> Int {
        switch tier {
        case .primaryPartnerAndChildren: return 0
        case .secondaryParents: return 1
        case .tertiarySiblings: return 2
        case .none: return 3
        }
    }

    private static func estateEligibilityRowLess(
        _ lhs: (
            AgentID, AgentEstateBeneficiaryTier, AgentEstateBeneficiaryBasis
        ),
        _ rhs: (
            AgentID, AgentEstateBeneficiaryTier, AgentEstateBeneficiaryBasis
        )
    ) -> Bool {
        let lhsRank = estateEligibilityTierRank(lhs.1)
        let rhsRank = estateEligibilityTierRank(rhs.1)
        if lhsRank != rhsRank { return lhsRank < rhsRank }
        return lhs.0 < rhs.0
    }

    private static func estateEligibilityRowLess(
        _ lhs: AgentEstateSuccessorEligibilityRow,
        _ rhs: AgentEstateSuccessorEligibilityRow
    ) -> Bool {
        estateEligibilityRowLess(
            (lhs.agentID, lhs.tier, lhs.basis),
            (rhs.agentID, rhs.tier, rhs.basis)
        )
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

    private static func estateRelationshipsForValidation(
        decedentID: AgentID,
        deathTick: Int,
        family: AgentFamilyState,
        kinship: AgentKinshipState
    ) -> [
        (AgentID, AgentEstateBeneficiaryTier, AgentEstateBeneficiaryBasis)
    ] {
        var candidates:
            [(AgentID, AgentEstateBeneficiaryTier, AgentEstateBeneficiaryBasis)]
            = []
        if let union = family.unions.first(where: {
            $0.partnerIDs.contains(decedentID)
                && $0.activationTick <= deathTick
                && ($0.terminationTick == nil
                    || ($0.terminationTick == deathTick
                        && $0.terminationReason == .partnerDeath))
        }), let partnerID = union.partnerIDs.first(where: {
            $0 != decedentID
        }) {
            candidates.append((
                partnerID,
                .primaryPartnerAndChildren,
                .activeUnionPartnerAtDeath
            ))
        }
        let parentageByChild = Dictionary(uniqueKeysWithValues:
            kinship.parentageRecords.map { ($0.childID, $0) }
        )
        for record in kinship.parentageRecords
            where record.birthTick <= deathTick
                && record.canonicalParentIDs.contains(decedentID) {
            candidates.append((
                record.childID,
                .primaryPartnerAndChildren,
                .canonicalChild
            ))
        }
        if let record = parentageByChild[decedentID] {
            for parentID in record.canonicalParentIDs {
                candidates.append((
                    parentID, .secondaryParents, .canonicalParent
                ))
            }
            let decedentParents = Set(record.canonicalParentIDs)
            for other in kinship.parentageRecords
                where other.childID != decedentID
                    && other.birthTick <= deathTick {
                let common = decedentParents.intersection(
                    other.canonicalParentIDs
                ).count
                if common == 2 {
                    candidates.append((
                        other.childID, .tertiarySiblings, .fullSibling
                    ))
                } else if common == 1 {
                    candidates.append((
                        other.childID, .tertiarySiblings, .halfSibling
                    ))
                }
            }
        }
        var seen = Set<AgentID>()
        return candidates.filter {
            $0.0 != decedentID && seen.insert($0.0).inserted
        }.sorted(by: estateEligibilityRowLess)
    }

    private struct EstateHistoricalEligibility {
        let eligible: Bool
        let lifeStage: AgentLifeStage
    }

    private static func estateHistoricalEligibility(
        agentID: AgentID,
        at boundaryTick: Int,
        activeIDs: Set<AgentID>,
        lifecycle: AgentLifecycleState,
        mortality: AgentMortalityState
    ) throws -> EstateHistoricalEligibility {
        let retained = mortality.records.filter { $0.agentID == agentID }
        let compacted = (mortality.compactedDeathSummaries ?? []).filter {
            $0.agentID == agentID
        }
        guard retained.count + compacted.count <= 1 else {
            throw AgentEstateError.invalidState(
                "contradictory successor mortality evidence"
            )
        }
        if let death = retained.first {
            guard let ageAtDeath = death.demographicAgeTicks,
                  let stageAtDeath = death.lifeStage else {
                throw AgentEstateError.invalidState(
                    "incomplete retained successor mortality"
                )
            }
            return try estateHistoricalEligibility(
                deathTick: death.deathTick,
                ageAtDeath: ageAtDeath,
                stageAtDeath: stageAtDeath,
                boundaryTick: boundaryTick,
                lifecycle: lifecycle
            )
        }
        if let death = compacted.first {
            guard let ageAtDeath = death.demographicAgeTicks,
                  let stageAtDeath = death.lifeStageAtDeath else {
                throw AgentEstateError.invalidState(
                    "incomplete compacted successor mortality"
                )
            }
            return try estateHistoricalEligibility(
                deathTick: death.deathTick,
                ageAtDeath: ageAtDeath,
                stageAtDeath: stageAtDeath,
                boundaryTick: boundaryTick,
                lifecycle: lifecycle
            )
        }
        guard activeIDs.contains(agentID),
              let member = lifecycle.members.first(where: {
                  $0.agentID == agentID
              }) else {
            throw AgentEstateError.invalidState(
                "missing successor mortality evidence"
            )
        }
        let age: Int
        do {
            age = try member.age(at: boundaryTick)
        } catch {
            throw AgentEstateError.invalidState(
                "successor lifecycle boundary"
            )
        }
        return EstateHistoricalEligibility(
            eligible: true,
            lifeStage: estateLifeStage(age: age, lifecycle: lifecycle)
        )
    }

    private static func estateHistoricalEligibility(
        deathTick: Int,
        ageAtDeath: Int,
        stageAtDeath: AgentLifeStage,
        boundaryTick: Int,
        lifecycle: AgentLifecycleState
    ) throws -> EstateHistoricalEligibility {
        guard ageAtDeath >= 0 else {
            throw AgentEstateError.invalidState(
                "successor mortality age"
            )
        }
        guard stageAtDeath
                == estateLifeStage(age: ageAtDeath, lifecycle: lifecycle)
        else {
            throw AgentEstateError.invalidState(
                "successor mortality life stage"
            )
        }
        if deathTick <= boundaryTick {
            return EstateHistoricalEligibility(
                eligible: false,
                lifeStage: stageAtDeath
            )
        }
        let elapsed = deathTick - boundaryTick
        guard ageAtDeath >= elapsed else {
            throw AgentEstateError.invalidState(
                "successor pre-death age"
            )
        }
        return EstateHistoricalEligibility(
            eligible: true,
            lifeStage: estateLifeStage(
                age: ageAtDeath - elapsed,
                lifecycle: lifecycle
            )
        )
    }

    private static func estateLifeStage(
        age: Int,
        lifecycle: AgentLifecycleState
    ) -> AgentLifeStage {
        if age >= lifecycle.configuration.maturityAgeTicks {
            return .mature
        }
        return age >= lifecycle.configuration.newbornDurationTicks
            ? .juvenile : .newborn
    }

    private static func estateLifeStageForValidation(
        agentID: AgentID,
        at tick: Int,
        lifecycle: AgentLifecycleState,
        mortality: AgentMortalityState
    ) -> AgentLifeStage? {
        let age: Int?
        if let member = lifecycle.members.first(where: {
            $0.agentID == agentID
        }) {
            age = try? member.age(at: tick)
        } else if let laterDeath = mortality.records.first(where: {
            $0.agentID == agentID && $0.deathTick >= tick
        }), let ageAtDeath = laterDeath.demographicAgeTicks {
            age = max(0, ageAtDeath - (laterDeath.deathTick - tick))
        } else if let laterDeath = mortality.compactedDeathSummaries?
            .first(where: {
                $0.agentID == agentID && $0.deathTick >= tick
            }), let ageAtDeath = laterDeath.demographicAgeTicks {
            age = max(0, ageAtDeath - (laterDeath.deathTick - tick))
        } else {
            age = nil
        }
        guard let age else { return nil }
        return estateLifeStage(age: age, lifecycle: lifecycle)
    }

    private static func estateRelationshipTexts(
        _ rows: [
            (AgentID, AgentEstateBeneficiaryTier, AgentEstateBeneficiaryBasis)
        ]
    ) -> [String] {
        rows.map {
            "\($0.0.rawValue)|\($0.1.rawValue)|\($0.2.rawValue)"
        }
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

    private mutating func recomputeEstateOperationalStatus(
        estateIndex: Int,
        authority: inout AgentEstateState
    ) {
        let estate = authority.estates[estateIndex]
        authority.estates[estateIndex].status =
            Self.recomputedEstateOperationalStatus(
                currentStatus: estate.status,
                beneficiaries: estate.beneficiaries,
                administrations: estate.administrations,
                assets: estate.assets
            )
    }

    private static func recomputedEstateOperationalStatus(
        currentStatus: AgentEstateStatus,
        beneficiaries: [AgentEstateBeneficiary],
        administrations: [AgentEstateAdministration],
        assets: [AgentEstateAssetEntry]
    ) -> AgentEstateStatus {
        if currentStatus == .settled
            || assets.allSatisfy(\.status.isTerminal) {
            return .settled
        }
        if beneficiaries.isEmpty {
            return .dormantNoSuccessor
        }
        let terminalCount = assets.filter(\.status.isTerminal).count
        if terminalCount > 0 && terminalCount < assets.count {
            return .partiallySettled
        }
        if assets.contains(where: { $0.status == .blocked }) {
            return .blocked
        }
        return administrations.contains(where: { $0.status == .active })
            ? .openAdministered : .openUnadministered
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
                custodyRevalidatedAtTick: nil,
                custodyRevalidationEventID: nil,
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
                custodyRevalidatedAtTick: nil,
                custodyRevalidationEventID: nil,
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

    private static func estateSuccessorPlanDigest(
        version: Int,
        estateID: AgentEstateID,
        decedentID: AgentID,
        deathID: AgentDeathID,
        deathBoundaryTick: Int,
        selectedTier: AgentEstateBeneficiaryTier,
        eligibilityRows: [AgentEstateSuccessorEligibilityRow],
        activeUnionAtDeath: AgentEstateActiveUnionAtDeathEvidence?
    ) -> String {
        let rows = eligibilityRows.map {
            "\($0.agentID.rawValue):\($0.tier.rawValue):"
                + "\($0.basis.rawValue):\($0.eligibleAtDeath ? 1 : 0):"
                + "\($0.lifeStageAtPlan?.rawValue ?? "none"):"
                + "\($0.guardianIDAtPlan?.rawValue ?? "none")"
        }.joined(separator: ",")
        let union = activeUnionAtDeath.map {
            "\($0.unionID.rawValue):\($0.partnerID.rawValue):"
                + "\($0.activationTick):\($0.activationEventID.rawValue)"
        } ?? "none"
        return AgentEstateDigest.make(
            "successor-plan-v\(version)|\(estateID.rawValue)|"
                + "\(decedentID.rawValue)|\(deathID.rawValue)|"
                + "\(deathBoundaryTick)|\(selectedTier.rawValue)|"
                + "\(rows)|\(union)"
        )
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
            let planProof = estate.successorPlanProof.map {
                "\($0.version):\($0.planDigest):"
                    + "\($0.successorPlanEventID.rawValue)"
            }
            let assets = estate.assets.map {
                let base =
                    "\($0.entryID.rawValue):"
                    + "\($0.materialRightsAssetID?.rawValue ?? "none"):"
                    + "\($0.quantity):\($0.status.rawValue):"
                    + "\($0.blockReason?.rawValue ?? "none"):"
                    + "\($0.settlementReceiptID ?? "none")"
                if let eventID = $0.custodyRevalidationEventID {
                    return base + ":custody:"
                        + "\($0.custodyRevalidatedAtTick ?? -1):"
                        + eventID.rawValue + ":"
                        + "\($0.intendedCustodianID?.rawValue ?? "none")"
                }
                return base
            }.joined(separator: ",")
            let prefix =
                "\(estate.estateID.rawValue)|\(estate.deathID.rawValue)|"
                    + "\(estate.status.rawValue)|"
            if let planProof {
                return prefix + "\(planProof)|\(admins)|"
                    + "\(beneficiaries)|\(assets)"
            }
            return prefix + "\(admins)|\(beneficiaries)|\(assets)"
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
