import PebbleAgents
import PebbleCore

private enum PebbleAgentEstateBoundaryError: Error {
    case invalid(String)
}

extension PebbleAgentController {
    func handleEstates(
        _ arguments: [String],
        world: World
    ) -> PebbleAgentCommandResult {
        guard var staged = session else {
            return failure("Estates require an active session.")
        }
        do {
            switch arguments.first?.lowercased() {
            case "on" where arguments.count == 1:
                if try applyRecordedOperationIfActive(
                    .setEstatesEnabled(true, configuration: .live),
                    session: &staged,
                    recorder: &replayRecorder
                ) == nil {
                    try staged.setEstatesEnabled(true)
                }
                session = staged
                return success(
                    "Estates enabled schema=28 activationTick=\(staged.tick)."
                )
            case "status" where arguments.count == 1:
                let message = estateStatusEvidence(in: staged)
                trace(message)
                return success(message)
            case "accept" where arguments.count == 3:
                guard let estateID = resolveEstateID(
                        arguments[1], in: staged
                      ),
                      let administratorID = AgentID(rawValue: arguments[2])
                else {
                    return failure(
                        "Usage: /lab estates accept <estateID> <administratorID>"
                    )
                }
                let operationID = "estate-accept:"
                    + "\(estateID.rawValue):\(administratorID.rawValue):t\(staged.tick)"
                if try applyRecordedOperationIfActive(
                    .acceptEstateAdministration(
                        estateID: estateID,
                        administratorID: administratorID,
                        operationID: operationID
                    ),
                    session: &staged,
                    recorder: &replayRecorder
                ) == nil {
                    _ = try staged.acceptEstateAdministration(
                        estateID: estateID,
                        administratorID: administratorID,
                        operationID: operationID
                    )
                }
                session = staged
                let message =
                    "estate administration accepted estate=\(estateID.rawValue) "
                    + "administrator=\(administratorID.rawValue) count=1"
                trace(message)
                return success(message)
            case "settle" where arguments.count == 3:
                guard let estateID = resolveEstateID(
                        arguments[1], in: staged
                      ),
                      let entryID = resolveEstateEntryID(
                        arguments[2], estateID: estateID, in: staged
                      ) else {
                    return failure(
                        "Usage: /lab estates settle <estateID> <entryID>"
                    )
                }
                let entry = try settleEstateAsset(
                    estateID: estateID,
                    entryID: entryID,
                    session: &staged,
                    recorder: &replayRecorder,
                    world: world
                )
                session = staged
                let message =
                    "estate asset settled estate=\(estateID.rawValue) "
                    + "entry=\(entry.entryID.rawValue) "
                    + "status=\(entry.status.rawValue) "
                    + "beneficiary=\(entry.assignedBeneficiaryID?.rawValue ?? "none") "
                    + "custodian=\(entry.intendedCustodianID?.rawValue ?? "none") "
                    + "receipt=\(entry.settlementReceiptID ?? "none")"
                trace(message)
                return success(message)
            case "proof" where arguments.count == 4
                    && arguments[1].lowercased() == "rollback":
                guard let estateID = resolveEstateID(
                        arguments[2], in: staged
                      ),
                      let entryID = resolveEstateEntryID(
                        arguments[3], estateID: estateID, in: staged
                      ) else {
                    return failure(
                        "Usage: /lab estates proof rollback <estateID> "
                            + "<entryID>"
                    )
                }
                let evidence = try proveEstateSettlementRollback(
                    estateID: estateID,
                    entryID: entryID,
                    session: &staged,
                    recorder: &replayRecorder,
                    world: world
                )
                trace(evidence)
                return success(evidence)
            case "proof" where arguments.count == 2
                    && arguments[1].lowercased() == "cleanup":
                let evidence = try cleanupEstatePhysicalProof(
                    session: staged, world: world
                )
                trace(evidence)
                return success(evidence)
            default:
                return failure(
                    "Usage: /lab estates <on|status|accept <estateID> "
                        + "<administratorID>|settle <estateID> <entryID>|"
                        + "proof <rollback <estateID> <entryID>|cleanup>>"
                )
            }
        } catch {
            return failure("Estate boundary refused: \(error)")
        }
    }

    private func cleanupEstatePhysicalProof(
        session: AgentSimulationSession,
        world: World
    ) throws -> String {
        guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1",
              isPaused, activeWorld === world,
              let estate = session.estateSnapshot().estates.last,
              estate.status == .settled,
              estate.assets.count == 1,
              let entry = estate.assets.first,
              entry.status == .transferred,
              let assetID = entry.materialRightsAssetID,
              let record = session.materialRightsSnapshot().records.first(
                where: { $0.asset.assetID == assetID }
              ),
              case let .agent(holderID) =
                record.lastVerifiedHolder.holder,
              holderID == entry.intendedCustodianID,
              let probe = probesByAgentId[holderID.rawValue],
              probe.world === world, !probe.dead,
              case let .container(location) =
                entry.holderAtOpening?.holder,
              let position = estateContainerPosition(location),
              world.getBlock(position.x, position.y, position.z)
                == Int(cell(B.chest)),
              let container = world.getBlockEntity(
                position.x, position.y, position.z
              ),
              container.type == "container",
              container.items?.allSatisfy({ $0 == nil }) == true else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "settled estate cleanup fixture is not exact"
            )
        }
        let probeBefore = copyItemInventory(probe.carriedItems)
        let matchingSlots = probeBefore.indices.filter { index in
            guard let stack = probeBefore[index] else { return false }
            return stack.id == iid("iron_pickaxe")
                && stack.count == entry.quantity
        }
        guard matchingSlots.count == 1,
              probeBefore.compactMap({ $0 }).count == 1 else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "settled successor custody is not exact"
            )
        }
        var clearedProbe = probeBefore
        clearedProbe[matchingSlots[0]] = nil
        probe.carriedItems = clearedProbe
        _ = world.setBlock(position.x, position.y, position.z, 0)
        guard probe.carriedItems.allSatisfy({ $0 == nil }),
              world.getBlock(position.x, position.y, position.z) == 0,
              world.getBlockEntity(position.x, position.y, position.z) == nil,
              probesByAgentId.values.allSatisfy({
                  $0.carriedItems.allSatisfy { $0 == nil }
              }) else {
            probe.carriedItems = probeBefore
            _ = world.setBlock(
                position.x, position.y, position.z, Int(cell(B.chest))
            )
            world.setBlockEntity(container)
            throw PebbleAgentEstateBoundaryError.invalid(
                "settled estate cleanup rollback required"
            )
        }
        return "estate proof cleanup world=exact trackedAssetRemoved=1 "
            + "fixtureContainerRemoved=1 untrackedItemsRemoved=0 "
            + "session=unchanged probes=\(probesByAgentId.count) duplicates=0"
    }

    private func estateContainerPosition(
        _ text: String
    ) -> PhysicalBlockPosition? {
        let normalized = text.hasPrefix("container:")
            ? String(text.dropFirst("container:".count)) : text
        let values = normalized.split(separator: ",").compactMap {
            Int($0.trimmingCharacters(in: .whitespaces))
        }
        guard values.count == 3 else { return nil }
        return PhysicalBlockPosition(
            x: values[0], y: values[1], z: values[2]
        )
    }

    private func estateStatusEvidence(
        in session: AgentSimulationSession
    ) -> String {
        let snapshot = session.estateSnapshot()
        guard let latest = snapshot.estates.max(by: {
            if $0.deathTick != $1.deathTick {
                return $0.deathTick < $1.deathTick
            }
            return $0.estateID < $1.estateID
        }) else {
            return [
                "estates",
                "schema=28",
                "enabled=\(snapshot.enabled ? 1 : 0)",
                "activation=\(snapshot.activationTick ?? -1)",
                "count=\(snapshot.totalEstateCount)",
                "settlements=\(snapshot.totalSettlementCount)",
                "latest=none",
                "digest=\(snapshot.digest)",
            ].joined(separator: " ")
        }
        let activeAdministration = latest.administrations.last {
            $0.status == .active
        }
        let latestAdministration = latest.administrations.last
        let beneficiaries = latest.beneficiaries.map {
            "\($0.agentID.rawValue):\($0.basis.rawValue):"
                + "\($0.lifeStageAtPlan.rawValue):"
                + "\($0.guardianIDAtPlan?.rawValue ?? "none")"
        }.joined(separator: ",")
        let rightsByID = Dictionary(
            uniqueKeysWithValues: session.materialRightsSnapshot().records.map {
                ($0.asset.assetID, $0)
            }
        )
        let assets = latest.assets.map { entry in
            let rights = entry.materialRightsAssetID.flatMap { rightsByID[$0] }
            return [
                entry.entryID.rawValue,
                entry.materialRightsAssetID?.rawValue ?? "unregistered",
                "\(entry.materialIdentity.itemKey):\(entry.quantity)",
                entry.holderAtOpening?.holder.stableText ?? "none",
                entry.ownerAtOpening?.ownerID.rawValue ?? "none",
                entry.assignedBeneficiaryID?.rawValue ?? "none",
                entry.intendedCustodianID?.rawValue ?? "none",
                entry.status.rawValue,
                entry.blockReason?.rawValue ?? "none",
                rights?.lastVerifiedHolder.holder.stableText ?? "none",
                rights?.recognizedOwnership?.ownerID.rawValue ?? "none",
                rights?.custodianID?.rawValue ?? "none",
                entry.settlementReceiptID ?? "none",
            ].joined(separator: "~")
        }.joined(separator: ",")
        let physical = latest.physicalCustodyResolution
        let duplicateCount = snapshot.estates.count
            - Set(snapshot.estates.map(\.estateID)).count
        return [
            "estates",
            "schema=28",
            "enabled=\(snapshot.enabled ? 1 : 0)",
            "activation=\(snapshot.activationTick ?? -1)",
            "count=\(snapshot.totalEstateCount)",
            "retained=\(snapshot.estates.count)",
            "settlements=\(snapshot.totalSettlementCount)",
            "latest=\(latest.estateID.rawValue)",
            "decedent=\(latest.decedentID.rawValue)",
            "death=\(latest.deathID.rawValue)",
            "deathTick=\(latest.deathTick)",
            "status=\(latest.status.rawValue)",
            "tier=\(latest.beneficiaryTier.rawValue)",
            "beneficiaries=\(beneficiaries)",
            "successorPlanVersion=\(latest.successorPlanProof?.version ?? 0)",
            "successorPlanDigest=\(latest.successorPlanProof?.planDigest ?? "none")",
            "successorPlanRows=\(latest.successorPlanProof?.eligibilityRows.count ?? 0)",
            "successorPlanEvent=\(latest.successorPlanEventID.rawValue)",
            "administrator=\(activeAdministration?.administratorID.rawValue ?? "none")",
            "administrationStatus=\(latestAdministration?.status.rawValue ?? "none")",
            "acceptance=\(latestAdministration?.acceptanceOperationID ?? "none")",
            "physical=\(physical.kind.rawValue)",
            "physicalReceipt=\(physical.physicalReceiptID)",
            "physicalHolder=\(physical.destinationHolderID ?? "none")",
            "physicalStacks=\(physical.stackCount)",
            "physicalItems=\(physical.itemCount)",
            "assets=\(assets)",
            "duplicateEstateIDs=\(duplicateCount)",
            "openingEvent=\(latest.openingEventID.rawValue)",
            "successorEvent=\(latest.successorPlanEventID.rawValue)",
            "deathEvent=\(latest.deathEventID?.rawValue ?? "none")",
            "settledEvent=\(latest.settledEventID?.rawValue ?? "none")",
            "digest=\(snapshot.digest)",
        ].joined(separator: " ")
    }

    private func resolveEstateID(
        _ value: String,
        in session: AgentSimulationSession
    ) -> AgentEstateID? {
        if value.lowercased() != "latest" {
            return AgentEstateID(rawValue: value)
        }
        return session.estateSnapshot().estates.max {
            if $0.deathTick != $1.deathTick {
                return $0.deathTick < $1.deathTick
            }
            return $0.estateID < $1.estateID
        }?.estateID
    }

    private func resolveEstateEntryID(
        _ value: String,
        estateID: AgentEstateID,
        in session: AgentSimulationSession
    ) -> AgentEstateAssetEntryID? {
        if value.lowercased() != "next" {
            return AgentEstateAssetEntryID(rawValue: value)
        }
        return session.estateSnapshot().estates.first {
            $0.estateID == estateID
        }?.assets.filter {
            $0.status == .pendingSettlement
        }.min {
            $0.entryID < $1.entryID
        }?.entryID
    }

    private func proveEstateSettlementRollback(
        estateID: AgentEstateID,
        entryID: AgentEstateAssetEntryID,
        session staged: inout AgentSimulationSession,
        recorder stagedRecorder: inout AgentReplayRecorder?,
        world: World
    ) throws -> String {
        guard let estate = staged.estateSnapshot().estates.first(where: {
            $0.estateID == estateID
        }), let entry = estate.assets.first(where: {
            $0.entryID == entryID
        }), let materialAssetID = entry.materialRightsAssetID,
              let custodianID = entry.intendedCustodianID,
              let rights = staged.materialRightsSnapshot().records.first(
                where: { $0.asset.assetID == materialAssetID }
              ),
              let destinationProbe =
                probesByAgentId[custodianID.rawValue] else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "rollback proof assignment unavailable"
            )
        }
        let source = try estateCustodyEndpoint(
            for: rights.lastVerifiedHolder.holder, world: world
        )
        let destination = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            destinationProbe, in: world
        )
        let sourceBefore = try materialCustodyGateway.inspect(source)
        let destinationBefore = try materialCustodyGateway.inspect(destination)
        let sessionBefore = try staged.durableStateBytes()
        let estateBefore = staged.estateSnapshot()
        let rightsBefore = staged.materialRightsSnapshot()
        let replayBefore = (
            records: stagedRecorder?.records.count,
            dropped: stagedRecorder?.droppedRecordCount,
            reason: stagedRecorder?.nonReplayableReason
        )
        var rejected = false
        do {
            _ = try settleEstateAsset(
                estateID: estateID,
                entryID: entryID,
                session: &staged,
                recorder: &stagedRecorder,
                world: world,
                rejectAfterCandidatePublication: true
            )
        } catch {
            rejected = true
        }
        let sourceAfter = try materialCustodyGateway.inspect(source)
        let destinationAfter = try materialCustodyGateway.inspect(destination)
        let replayAfter = (
            records: stagedRecorder?.records.count,
            dropped: stagedRecorder?.droppedRecordCount,
            reason: stagedRecorder?.nonReplayableReason
        )
        guard rejected,
              try staged.durableStateBytes() == sessionBefore,
              staged.estateSnapshot() == estateBefore,
              staged.materialRightsSnapshot() == rightsBefore,
              sourceAfter == sourceBefore,
              destinationAfter == destinationBefore,
              replayAfter.records == replayBefore.records,
              replayAfter.dropped == replayBefore.dropped,
              replayAfter.reason == replayBefore.reason else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "late settlement rollback diverged"
            )
        }
        return "estate settlement rollback lateFailure=verified "
            + "session=exact estate=exact materialRights=exact "
            + "source=restored destination=restored replay=unchanged"
    }

    @discardableResult
    func settleEstateAsset(
        estateID: AgentEstateID,
        entryID: AgentEstateAssetEntryID,
        session published: inout AgentSimulationSession,
        recorder publishedRecorder: inout AgentReplayRecorder?,
        world: World,
        rejectAfterCandidatePublication: Bool = false
    ) throws -> AgentEstateAssetEntry {
        guard let estate = published.estateSnapshot().estates.first(where: {
            $0.estateID == estateID
        }), let entry = estate.assets.first(where: {
            $0.entryID == entryID
        }), entry.status == .pendingSettlement,
              let materialAssetID = entry.materialRightsAssetID,
              let beneficiaryID = entry.assignedBeneficiaryID,
              let intendedCustodianID = entry.intendedCustodianID,
              let administratorID = estate.administrations.last(where: {
                  $0.status == .active
              })?.administratorID,
              let record = published.materialRightsSnapshot().records.first(where: {
                  $0.asset.assetID == materialAssetID
              }),
              record.lastVerifiedHolder.holder
                == entry.holderAtOpening?.holder,
              record.lastVerifiedHolder.materialIdentity
                == entry.materialIdentity,
              record.lastVerifiedHolder.quantity == entry.quantity
        else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "estate assignment unavailable"
            )
        }
        let source = try estateCustodyEndpoint(
            for: record.lastVerifiedHolder.holder, world: world
        )
        guard let destinationProbe = probesByAgentId[
            intendedCustodianID.rawValue
        ] else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "beneficiary custodian probe missing"
            )
        }
        let destination = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            destinationProbe, in: world
        )
        let sourceFingerprint = try materialCustodyGateway.fingerprint(source)
        guard sourceFingerprint
                == record.lastVerifiedHolder.custodyFingerprint else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "stale estate source"
            )
        }
        let destinationFingerprint = try materialCustodyGateway.fingerprint(
            destination
        )
        let operationID = "estate-settle:"
            + "\(estateID.rawValue):\(entryID.rawValue):t\(published.tick)"
        let gatewayBefore = materialCustodyGateway.boundarySnapshot()
        var candidateSession: AgentSimulationSession?
        var candidateRecorder: AgentReplayRecorder?
        var publicationError: Error?
        let outcome = materialCustodyGateway.transfer(
            PebbleAgentMaterialTransactionRequest(
                transactionID: operationID,
                material: AgentMaterialStackSnapshot(
                    identity: entry.materialIdentity,
                    count: entry.quantity
                ),
                expectedSourceFingerprint: sourceFingerprint,
                expectedDestinationFingerprint: destinationFingerprint
            ),
            from: source,
            to: destination,
            verifyAfterMutation: {
                do {
                    let custody = try self.materialCustodyGateway.inspect(
                        destination
                    )
                    let sourceFingerprintAfterTransfer =
                        try self.materialCustodyGateway.fingerprint(source)
                    let quantity = custody.slots.compactMap { $0 }.filter {
                        $0.identity == entry.materialIdentity
                    }.reduce(0) { $0 + $1.count }
                    guard quantity >= entry.quantity else {
                        return false
                    }
                    let destinationObservation = AgentMaterialHolderObservation(
                        holder: .agent(intendedCustodianID),
                        materialIdentity: entry.materialIdentity,
                        quantity: entry.quantity,
                        custodyFingerprint: try self.materialCustodyGateway
                            .fingerprint(destination),
                        physicalReceiptID: operationID,
                        observedAtTick: published.tick
                    )
                    let socialOutcome = AgentEstatePhysicalSettlementOutcome(
                        operationID: operationID,
                        estateID: estateID,
                        entryID: entryID,
                        administratorID: administratorID,
                        beneficiaryID: beneficiaryID,
                        intendedCustodianID: intendedCustodianID,
                        sourceObservation: record.lastVerifiedHolder,
                        destinationObservation: destinationObservation,
                        sourceFingerprintAfterTransfer:
                            sourceFingerprintAfterTransfer,
                        destinationFingerprintBeforeTransfer:
                            destinationFingerprint,
                        physicalReceiptID: operationID
                    )
                    var staged = published
                    var stagedRecorder = publishedRecorder
                    if try self.applyRecordedOperationIfActive(
                        .applyEstatePhysicalSettlement(socialOutcome),
                        session: &staged,
                        recorder: &stagedRecorder
                    ) == nil {
                        _ = try staged.applyEstatePhysicalSettlement(
                            socialOutcome
                        )
                    }
                    try staged.validateEstateCrossDomainIfEnabled()
                    guard !rejectAfterCandidatePublication else {
                        return false
                    }
                    candidateSession = staged
                    candidateRecorder = stagedRecorder
                    return true
                } catch {
                    publicationError = error
                    return false
                }
            }
        )
        guard outcome.status == PebbleAgentMaterialTransactionStatus.succeeded,
              let candidateSession else {
            if outcome.status
                != PebbleAgentMaterialTransactionStatus.rollbackFailure {
                materialCustodyGateway.restoreBoundarySnapshot(gatewayBefore)
            }
            throw publicationError
                ?? PebbleAgentEstateBoundaryError.invalid(
                    "physical settlement \(outcome.status.rawValue)"
                )
        }
        published = candidateSession
        publishedRecorder = candidateRecorder
        guard let settled = published.estateSnapshot().estates.first(where: {
            $0.estateID == estateID
        })?.assets.first(where: {
            $0.entryID == entryID
        }), settled.status == .transferred else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "settlement publication missing"
            )
        }
        return settled
    }

    private func estateCustodyEndpoint(
        for holder: AgentMaterialPhysicalHolder,
        world: World
    ) throws -> PebbleAgentMaterialCustodyEndpoint {
        switch holder {
        case let .agent(agentID):
            guard let probe = probesByAgentId[agentID.rawValue] else {
                throw PebbleAgentEstateBoundaryError.invalid(
                    "source probe missing"
                )
            }
            return .liveAgent(probe, in: world)
        case let .container(value):
            let coordinates = value.split(separator: ",").compactMap {
                Int($0)
            }
            guard coordinates.count == 3,
                  let container = world.getBlockEntity(
                      coordinates[0], coordinates[1], coordinates[2]
                  ), container.type == "container", container.items != nil else {
                throw PebbleAgentEstateBoundaryError.invalid(
                    "source container missing"
                )
            }
            return .container(container, in: world)
        }
    }
}
