extension AgentSimulationSession {
    public var materialRightsEnabled: Bool { materialRightsState != nil }

    public func materialRightsSnapshot() -> AgentMaterialRightsSnapshot {
        AgentMaterialRightsSnapshot(state: materialRightsState)
    }

    public mutating func setMaterialRightsEnabled(
        _ enabled: Bool,
        configuration: AgentMaterialRightsConfiguration = .live
    ) throws {
        if enabled {
            guard causalLedger.isEnabled else {
                throw AgentSessionError.materialRights(.causalLedgerRequired)
            }
            guard materialRightsState == nil else { return }
            try prevalidateCausalAppend(count: 1)
            materialRightsState = AgentMaterialRightsState(configuration: configuration)
            _ = try recordCausalEvent(
                kind: .materialRightsInitialized,
                origin: .session,
                payload: .feature(name: "materialRights", enabled: true),
                summary: "material rights initialized assets=0"
            )
        } else {
            guard materialRightsState != nil else { return }
            materialRightsState = nil
            recordFeatureToggle(name: "materialRights", enabled: false)
        }
    }

    public func evaluateMaterialUse(
        _ request: AgentMaterialUseRequest
    ) -> AgentMaterialUseDecision {
        guard let rights = materialRightsState,
              let record = rights.records.first(where: {
                  $0.asset.assetID == request.assetID
              }) else {
            return AgentMaterialUseDecision(
                request: request,
                verdict: .denied,
                reason: .unknownAsset,
                conflictObserved: false
            )
        }
        if let reconciliation = persistenceReconciliationState?.latestResults
            .first(where: { $0.assetID == request.assetID }),
           !reconciliation.outcome.hasVerifiedPhysicalAsset {
            return AgentMaterialUseDecision(
                request: request,
                verdict: .denied,
                reason: .physicalAssetUnresolved,
                conflictObserved: record.hasConflict
            )
        }
        guard record.lastVerifiedHolder == request.verifiedHolder else {
            return AgentMaterialUseDecision(
                request: request,
                verdict: .denied,
                reason: .stalePhysicalObservation,
                conflictObserved: record.hasConflict
            )
        }
        guard case let .agent(holderID) = request.verifiedHolder.holder,
              holderID == request.actorID else {
            return AgentMaterialUseDecision(
                request: request,
                verdict: .denied,
                reason: .requesterNotPhysicalHolder,
                conflictObserved: record.hasConflict
            )
        }
        if record.recognizedOwnership?.ownerID == request.actorID {
            return AgentMaterialUseDecision(
                request: request,
                verdict: .allowed,
                reason: .recognizedOwner,
                conflictObserved: record.hasConflict
            )
        }
        if record.permissions.contains(where: {
            $0.userID == request.actorID && $0.permits(request.use, at: tick)
        }) {
            return AgentMaterialUseDecision(
                request: request,
                verdict: .allowed,
                reason: .explicitPermission,
                conflictObserved: record.hasConflict
            )
        }
        return AgentMaterialUseDecision(
            request: request,
            verdict: .denied,
            reason: .noUseRight,
            conflictObserved: record.hasConflict
        )
    }

    @discardableResult
    public mutating func applyMaterialRightsOperation(
        _ operation: AgentMaterialRightsOperation
    ) throws -> AgentMaterialRightsApplicationResult {
        var candidate = self
        let result = try candidate.applyMaterialRightsOperationInPlace(operation)
        self = candidate
        return result
    }

    private mutating func applyMaterialRightsOperationInPlace(
        _ operation: AgentMaterialRightsOperation
    ) throws -> AgentMaterialRightsApplicationResult {
        guard var rights = materialRightsState else {
            throw AgentSessionError.materialRights(.disabled)
        }
        let operationID = operation.operationID
        guard validMaterialRightsText(operationID, maximum: 256) else {
            throw AgentSessionError.materialRights(.invalidOperation(operationID))
        }
        let assetID = try materialRightsAssetID(for: operation)
        if rights.processedOperationIDs.contains(operationID) {
            return AgentMaterialRightsApplicationResult(
                status: .duplicate,
                operationID: operationID,
                assetID: assetID
            )
        }
        try prevalidateCausalAppend(count: 1)

        let transition: (
            AgentMaterialRightsTransitionKind,
            AgentCausalEventKind,
            AgentID?,
            String,
            String
        )
        switch operation {
        case let .register(_, asset, observation):
            guard rights.records.count < rights.configuration.maximumAssets else {
                throw AgentSessionError.materialRights(.assetLimitReached)
            }
            guard !rights.records.contains(where: { $0.asset.assetID == asset.assetID }) else {
                throw AgentSessionError.materialRights(.duplicateAsset(asset.assetID))
            }
            try validateMaterialAsset(asset, observation: observation)
            rights.records.append(AgentMaterialRightsRecord(
                asset: asset,
                lastVerifiedHolder: observation
            ))
            rights.records.sort { $0.asset.assetID < $1.asset.assetID }
            transition = (
                .assetRegistered, .materialAssetRegistered,
                observation.holder.agentID,
                "applied",
                "verified physical asset registered"
            )

        case let .assertClaim(_, id, claimID, claimantID, basis):
            try requireMaterialRightsAgent(claimantID)
            let index = try materialRightsRecordIndex(id, in: rights)
            guard rights.records[index].claims.count
                    < rights.configuration.maximumClaimsPerAsset else {
                throw AgentSessionError.materialRights(.claimLimitReached)
            }
            guard !rights.records[index].claims.contains(where: {
                $0.claimID == claimID
            }) else {
                throw AgentSessionError.materialRights(.duplicateClaim(claimID))
            }
            rights.records[index].claims.append(AgentMaterialClaim(
                claimID: claimID,
                claimantID: claimantID,
                basis: basis,
                assertedAtTick: tick
            ))
            rights.records[index].claims.sort { $0.claimID < $1.claimID }
            transition = (
                .claimAsserted, .materialClaimChanged, claimantID, "applied",
                "claim asserted basis=\(basis.rawValue)"
            )

        case let .withdrawClaim(_, id, claimID, actorID):
            try requireMaterialRightsAgent(actorID)
            let index = try materialRightsRecordIndex(id, in: rights)
            guard let claimIndex = rights.records[index].claims.firstIndex(where: {
                $0.claimID == claimID
            }) else {
                throw AgentSessionError.materialRights(.unknownClaim(claimID))
            }
            let claim = rights.records[index].claims[claimIndex]
            guard actorID == claim.claimantID
                    || actorID == rights.records[index].recognizedOwnership?.ownerID else {
                throw AgentSessionError.materialRights(.unauthorized("claim withdrawal"))
            }
            rights.records[index].claims.remove(at: claimIndex)
            if rights.records[index].recognizedOwnership?.claimID == claimID {
                rights.records[index].recognizedOwnership = nil
            }
            transition = (
                .claimWithdrawn, .materialClaimChanged, actorID, "applied",
                "claim withdrawn"
            )

        case let .recognizeOwnership(_, id, claimID, recognizingAgentIDs):
            let index = try materialRightsRecordIndex(id, in: rights)
            let witnesses = Array(Set(recognizingAgentIDs)).sorted()
            guard !witnesses.isEmpty,
                  witnesses.count == recognizingAgentIDs.count,
                  witnesses.count <= rights.configuration.maximumRecognitionWitnesses else {
                throw AgentSessionError.materialRights(.recognitionLimitReached)
            }
            for witness in witnesses { try requireMaterialRightsAgent(witness) }
            guard let claim = rights.records[index].claims.first(where: {
                $0.claimID == claimID
            }) else {
                throw AgentSessionError.materialRights(.unknownClaim(claimID))
            }
            rights.records[index].recognizedOwnership = AgentMaterialRecognizedOwnership(
                claimID: claimID,
                ownerID: claim.claimantID,
                recognizingAgentIDs: witnesses,
                recognizedAtTick: tick
            )
            transition = (
                .ownershipRecognized, .materialOwnershipRecognized,
                claim.claimantID, "applied",
                "ownership recognized by \(witnesses.count) local witnesses"
            )

        case let .delegateCustody(_, id, custodianID, actorID):
            try requireMaterialRightsAgent(custodianID)
            try requireMaterialRightsAgent(actorID)
            let index = try materialRightsRecordIndex(id, in: rights)
            guard actorID == rights.records[index].recognizedOwnership?.ownerID
                    || actorID == rights.records[index].custodianID else {
                throw AgentSessionError.materialRights(.unauthorized("custody delegation"))
            }
            rights.records[index].custodianID = custodianID
            transition = (
                .custodyDelegated, .materialCustodyChanged, actorID, "applied",
                "custody delegated to \(custodianID.rawValue)"
            )

        case let .grantUse(
            _, id, permissionID, grantorID, userID, allowedUses, expiresAtTick
        ):
            try requireMaterialRightsAgent(grantorID)
            try requireMaterialRightsAgent(userID)
            let index = try materialRightsRecordIndex(id, in: rights)
            guard grantorID == rights.records[index].recognizedOwnership?.ownerID else {
                throw AgentSessionError.materialRights(.unauthorized("use grant"))
            }
            guard !allowedUses.isEmpty,
                  allowedUses.count == Set(allowedUses).count,
                  expiresAtTick.map({ $0 >= tick }) ?? true else {
                throw AgentSessionError.materialRights(.invalidOperation(operationID))
            }
            guard rights.records[index].permissions.count
                    < rights.configuration.maximumPermissionsPerAsset else {
                throw AgentSessionError.materialRights(.permissionLimitReached)
            }
            guard !rights.records[index].permissions.contains(where: {
                $0.permissionID == permissionID
            }) else {
                throw AgentSessionError.materialRights(.duplicatePermission(permissionID))
            }
            rights.records[index].permissions.append(AgentMaterialUsePermission(
                permissionID: permissionID,
                grantorID: grantorID,
                userID: userID,
                allowedUses: allowedUses,
                grantedAtTick: tick,
                expiresAtTick: expiresAtTick
            ))
            rights.records[index].permissions.sort {
                $0.permissionID < $1.permissionID
            }
            transition = (
                .useGranted, .materialUsePermissionChanged, grantorID, "applied",
                "use granted to \(userID.rawValue)"
            )

        case let .revokeUse(_, id, permissionID, actorID):
            try requireMaterialRightsAgent(actorID)
            let index = try materialRightsRecordIndex(id, in: rights)
            guard let permissionIndex = rights.records[index].permissions.firstIndex(where: {
                $0.permissionID == permissionID
            }) else {
                throw AgentSessionError.materialRights(.unknownPermission(permissionID))
            }
            let permission = rights.records[index].permissions[permissionIndex]
            guard actorID == permission.grantorID
                    || actorID == rights.records[index].recognizedOwnership?.ownerID else {
                throw AgentSessionError.materialRights(.unauthorized("use revocation"))
            }
            rights.records[index].permissions.remove(at: permissionIndex)
            transition = (
                .useRevoked, .materialUsePermissionChanged, actorID, "applied",
                "use permission revoked"
            )

        case let .physicalTransfer(outcome):
            let index = try materialRightsRecordIndex(
                outcome.decision.request.assetID, in: rights
            )
            let expected = evaluateMaterialUse(outcome.decision.request)
            guard expected == outcome.decision,
                  rights.records[index].lastVerifiedHolder
                    == outcome.decision.request.verifiedHolder else {
                throw AgentSessionError.materialRights(
                    .stalePhysicalObservation(outcome.decision.request.assetID)
                )
            }
            switch outcome.disposition {
            case .authorized:
                guard outcome.decision.verdict == .allowed else {
                    throw AgentSessionError.materialRights(
                        .invalidPhysicalOutcome(operationID)
                    )
                }
            case .observedTransgression:
                guard outcome.decision.verdict == .denied else {
                    throw AgentSessionError.materialRights(
                        .invalidPhysicalOutcome(operationID)
                    )
                }
            }
            if outcome.status == .succeeded {
                guard let destination = outcome.destinationObservation,
                      validMaterialRightsText(outcome.physicalReceiptID ?? "", maximum: 256),
                      destination.physicalReceiptID == outcome.physicalReceiptID,
                      destination.observedAtTick == tick,
                      destination.materialIdentity
                        == rights.records[index].lastVerifiedHolder.materialIdentity,
                      destination.quantity == rights.records[index].lastVerifiedHolder.quantity,
                      destination.holder
                        != rights.records[index].lastVerifiedHolder.holder else {
                    throw AgentSessionError.materialRights(
                        .invalidPhysicalOutcome(operationID)
                    )
                }
                rights.records[index].lastVerifiedHolder = destination
            } else {
                guard outcome.destinationObservation == nil else {
                    throw AgentSessionError.materialRights(
                        .invalidPhysicalOutcome(operationID)
                    )
                }
            }
            transition = (
                .physicalTransfer, .materialPhysicalCustodyObserved,
                outcome.decision.request.actorID,
                outcome.status.rawValue,
                "\(outcome.disposition.rawValue):\(outcome.decision.reason.rawValue)"
            )

        case let .useAttempt(outcome):
            let index = try materialRightsRecordIndex(
                outcome.decision.request.assetID, in: rights
            )
            let expected = evaluateMaterialUse(outcome.decision.request)
            guard expected == outcome.decision,
                  rights.records[index].lastVerifiedHolder
                    == outcome.decision.request.verifiedHolder else {
                throw AgentSessionError.materialRights(
                    .stalePhysicalObservation(outcome.decision.request.assetID)
                )
            }
            if outcome.decision.verdict == .denied {
                guard outcome.status == .notAttempted,
                      outcome.resultingObservation == nil,
                      outcome.physicalReceiptID == nil else {
                    throw AgentSessionError.materialRights(
                        .invalidPhysicalOutcome(operationID)
                    )
                }
            } else if outcome.status == .succeeded {
                guard let observation = outcome.resultingObservation,
                      validMaterialRightsText(outcome.physicalReceiptID ?? "", maximum: 256),
                      observation.physicalReceiptID == outcome.physicalReceiptID,
                      observation.observedAtTick == tick,
                      observation.holder == rights.records[index].lastVerifiedHolder.holder,
                      observation.quantity == rights.records[index].lastVerifiedHolder.quantity,
                      observation.materialIdentity.itemKey
                        == rights.records[index].lastVerifiedHolder.materialIdentity.itemKey else {
                    throw AgentSessionError.materialRights(
                        .invalidPhysicalOutcome(operationID)
                    )
                }
                rights.records[index].lastVerifiedHolder = observation
            } else {
                guard outcome.resultingObservation == nil else {
                    throw AgentSessionError.materialRights(
                        .invalidPhysicalOutcome(operationID)
                    )
                }
            }
            transition = (
                .useAttempt, .materialUseDecided,
                outcome.decision.request.actorID,
                outcome.status.rawValue,
                "\(outcome.decision.verdict.rawValue):\(outcome.decision.reason.rawValue)"
            )
        }

        let updatedRecord = rights.records.first { $0.asset.assetID == assetID }!
        let holderText = updatedRecord.lastVerifiedHolder.holder.stableText
        let custodianText = updatedRecord.custodianID?.rawValue ?? "none"
        let ownerText = updatedRecord.recognizedOwnership?.ownerID.rawValue ?? "none"
        let conflictText = updatedRecord.hasConflict ? "1" : "0"
        let eventDetail = [
            "asset=\(assetID.rawValue)",
            transition.4,
            "holder=\(holderText)",
            "custodian=\(custodianText)",
            "owner=\(ownerText)",
            "claims=\(updatedRecord.claims.count)",
            "permissions=\(updatedRecord.permissions.count)",
            "conflict=\(conflictText)",
        ].joined(separator: " ")
        let event = try recordCausalEvent(
            kind: transition.1,
            origin: .materialRightsTransition,
            actorID: transition.2,
            operationID: AgentOperationID(rawValue: operationID),
            payload: .operation(
                status: transition.3,
                detail: String(eventDetail.prefix(160))
            ),
            summary: "material rights \(transition.0.rawValue) asset=\(assetID.rawValue)"
        )
        retainMaterialRightsOperationID(operationID, in: &rights)
        retainMaterialRightsTransition(AgentMaterialRightsTransition(
            operationID: operationID,
            kind: transition.0,
            assetID: assetID,
            status: transition.3,
            reason: transition.4,
            eventID: event?.eventID
        ), in: &rights)
        materialRightsState = rights
        try validateMaterialRightsStateIfEnabled()
        return AgentMaterialRightsApplicationResult(
            status: .applied,
            operationID: operationID,
            assetID: assetID
        )
    }

    func validateMaterialRightsStateIfEnabled() throws {
        guard let rights = materialRightsState else { return }
        guard rights.records.count <= rights.configuration.maximumAssets,
              rights.records.map(\.asset.assetID)
                == rights.records.map(\.asset.assetID).sorted(),
              Set(rights.records.map(\.asset.assetID)).count == rights.records.count,
              rights.recentTransitions.count
                <= rights.configuration.maximumRetainedTransitions,
              rights.processedOperationIDs.count
                <= rights.configuration.maximumProcessedOperationIDs,
              Set(rights.processedOperationIDs).count
                == rights.processedOperationIDs.count else {
            throw AgentSessionError.materialRights(.invalidState("global bounds"))
        }
        for record in rights.records {
            try validateMaterialAsset(
                record.asset, observation: record.lastVerifiedHolder,
                allowIdentityEvolution: true
            )
            if case let .agent(holder) = record.lastVerifiedHolder.holder {
                try requireMaterialRightsAgent(holder)
            }
            if let custodian = record.custodianID {
                try validateHistoricalMaterialRightsSubject(custodian)
            }
            guard record.claims.count <= rights.configuration.maximumClaimsPerAsset,
                  record.claims.map(\.claimID) == record.claims.map(\.claimID).sorted(),
                  Set(record.claims.map(\.claimID)).count == record.claims.count,
                  record.permissions.count
                    <= rights.configuration.maximumPermissionsPerAsset,
                  record.permissions.map(\.permissionID)
                    == record.permissions.map(\.permissionID).sorted(),
                  Set(record.permissions.map(\.permissionID)).count
                    == record.permissions.count else {
                throw AgentSessionError.materialRights(.invalidState("record bounds"))
            }
            for claim in record.claims {
                try validateHistoricalMaterialRightsSubject(claim.claimantID)
            }
            for permission in record.permissions {
                try validateHistoricalMaterialRightsSubject(permission.grantorID)
                try validateHistoricalMaterialRightsSubject(permission.userID)
                guard !permission.allowedUses.isEmpty,
                      permission.allowedUses == permission.allowedUses.sorted(),
                      Set(permission.allowedUses).count == permission.allowedUses.count else {
                    throw AgentSessionError.materialRights(.invalidState("permission"))
                }
            }
            if let ownership = record.recognizedOwnership {
                try validateHistoricalMaterialRightsSubject(ownership.ownerID)
                guard let claim = record.claims.first(where: {
                    $0.claimID == ownership.claimID
                }), claim.claimantID == ownership.ownerID,
                      !ownership.recognizingAgentIDs.isEmpty,
                      ownership.recognizingAgentIDs
                        == ownership.recognizingAgentIDs.sorted(),
                      Set(ownership.recognizingAgentIDs).count
                        == ownership.recognizingAgentIDs.count,
                      ownership.recognizingAgentIDs.count
                        <= rights.configuration.maximumRecognitionWitnesses else {
                    throw AgentSessionError.materialRights(.invalidState("recognition"))
                }
                for witness in ownership.recognizingAgentIDs {
                    try validateHistoricalMaterialRightsSubject(witness)
                }
            }
        }
        guard rights.recentTransitions.allSatisfy({ transition in
            rights.records.contains(where: {
                $0.asset.assetID == transition.assetID
            }) && (transition.eventID?.sequence.rawValue ?? 0) <= causalLedger.latestSequence
        }) else {
            throw AgentSessionError.materialRights(.invalidState("transition causality"))
        }
    }

    private func materialRightsAssetID(
        for operation: AgentMaterialRightsOperation
    ) throws -> AgentMaterialAssetID {
        switch operation {
        case let .register(_, asset, _): return asset.assetID
        case let .assertClaim(_, id, _, _, _),
             let .withdrawClaim(_, id, _, _),
             let .recognizeOwnership(_, id, _, _),
             let .delegateCustody(_, id, _, _),
             let .grantUse(_, id, _, _, _, _, _),
             let .revokeUse(_, id, _, _):
            return id
        case let .physicalTransfer(outcome): return outcome.decision.request.assetID
        case let .useAttempt(outcome): return outcome.decision.request.assetID
        }
    }

    private func materialRightsRecordIndex(
        _ assetID: AgentMaterialAssetID,
        in rights: AgentMaterialRightsState
    ) throws -> Int {
        guard let index = rights.records.firstIndex(where: {
            $0.asset.assetID == assetID
        }) else {
            throw AgentSessionError.materialRights(.unknownAsset(assetID))
        }
        return index
    }

    private func requireMaterialRightsAgent(_ agentID: AgentID) throws {
        guard statesById[agentID.rawValue] != nil else {
            throw AgentSessionError.materialRights(.unknownAgent(agentID))
        }
    }

    /// Social references are durable historical assertions, not capabilities.
    /// Their subjects may be deceased; only a new operation still requires an
    /// active agent through `requireMaterialRightsAgent`.
    private func validateHistoricalMaterialRightsSubject(
        _ agentID: AgentID
    ) throws {
        let active = statesById[agentID.rawValue] != nil
        let deceased = mortalityState?.records.contains {
            $0.agentID == agentID
        } == true
        guard active || deceased else {
            throw AgentSessionError.materialRights(.unknownAgent(agentID))
        }
    }

    private func validateMaterialAsset(
        _ asset: AgentMaterialAssetReference,
        observation: AgentMaterialHolderObservation,
        allowIdentityEvolution: Bool = false
    ) throws {
        let identity = observation.materialIdentity
        guard asset.quantity > 0, asset.quantity <= 4096,
              observation.quantity == asset.quantity,
              observation.observedAtTick >= 0, observation.observedAtTick <= tick,
              validMaterialRightsText(identity.itemKey, maximum: 128),
              identity.damage >= 0,
              identity.enchantments.count <= 32,
              identity.enchantments.allSatisfy({
                  validMaterialRightsText($0.id, maximum: 128) && $0.level > 0
              }),
              (identity.label?.count ?? 0) <= 256,
              identity.canonicalDataJSON.utf8.count <= 4096,
              validMaterialRightsText(observation.custodyFingerprint, maximum: 8192),
              validMaterialRightsText(observation.physicalReceiptID, maximum: 256),
              allowIdentityEvolution
                ? identity.itemKey == asset.materialIdentity.itemKey
                : identity == asset.materialIdentity else {
            throw AgentSessionError.materialRights(.invalidPhysicalOutcome(
                asset.assetID.rawValue
            ))
        }
        if case let .container(location) = observation.holder {
            guard validMaterialRightsText(location, maximum: 256) else {
                throw AgentSessionError.materialRights(.invalidPhysicalOutcome(
                    asset.assetID.rawValue
                ))
            }
        }
    }

    private func validMaterialRightsText(_ text: String, maximum: Int) -> Bool {
        !text.isEmpty && text.utf8.count <= maximum && !text.contains("\n")
    }

    private func retainMaterialRightsOperationID(
        _ operationID: String,
        in rights: inout AgentMaterialRightsState
    ) {
        rights.processedOperationIDs.append(operationID)
        if rights.processedOperationIDs.count
            > rights.configuration.maximumProcessedOperationIDs {
            rights.processedOperationIDs.removeFirst()
            rights.droppedOperationIDCount += 1
        }
    }

    private func retainMaterialRightsTransition(
        _ transition: AgentMaterialRightsTransition,
        in rights: inout AgentMaterialRightsState
    ) {
        rights.recentTransitions.append(transition)
        if rights.recentTransitions.count
            > rights.configuration.maximumRetainedTransitions {
            rights.recentTransitions.removeFirst()
            rights.droppedTransitionCount += 1
        }
    }
}

private extension AgentMaterialPhysicalHolder {
    var agentID: AgentID? {
        if case let .agent(id) = self { return id }
        return nil
    }
}
