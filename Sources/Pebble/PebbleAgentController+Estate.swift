import Foundation
import PebbleAgents
import PebbleCore

private enum PebbleAgentEstateBoundaryError: Error {
    case invalid(String)
    case injectedLateSettlementFailure
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
            case "proof" where arguments.count == 4
                    && arguments[1].lowercased() == "physical"
                    && environment["PEBBLELAB_GATE_D_BLOCKER_06"] == "1":
                guard let estateID = resolveEstateID(
                        arguments[2], in: staged
                      ),
                      let entryID = resolveEstateEntryID(
                        arguments[3], estateID: estateID, in: staged
                      ) else {
                    return failure(
                        "Usage: /lab estates proof physical <estateID> <entryID>"
                    )
                }
                let evidence = try estatePhysicalAuthorityEvidence(
                    estateID: estateID,
                    entryID: entryID,
                    session: staged,
                    world: world
                )
                trace(evidence)
                return success(evidence)
            case "proof" where arguments.count == 4
                    && arguments[1].lowercased() == "authority"
                    && environment["PEBBLELAB_GATE_D_BLOCKER_06"] == "1":
                guard let estateID = resolveEstateID(
                        arguments[2], in: staged
                      ),
                      let entryID = resolveEstateEntryID(
                        arguments[3], estateID: estateID, in: staged
                      ) else {
                    return failure(
                        "Usage: /lab estates proof authority <estateID> <entryID>"
                    )
                }
                let evidence = try proveEstateSourceAuthorityAdversarial(
                    estateID: estateID,
                    entryID: entryID,
                    session: staged,
                    world: world
                )
                trace(evidence)
                return success(evidence)
            case "proof" where arguments.count == 4
                    && arguments[1].lowercased() == "pre-mutation-refusal"
                    && environment["PEBBLELAB_GATE_D_BLOCKER_06"] == "1":
                guard let estateID = resolveEstateID(
                        arguments[2], in: staged
                      ),
                      let entryID = resolveEstateEntryID(
                        arguments[3], estateID: estateID, in: staged
                      ) else {
                    return failure(
                        "Usage: /lab estates proof pre-mutation-refusal "
                            + "<estateID> <entryID>"
                    )
                }
                let evidence = try proveEstateRollbackRejectsPreMutationFailure(
                    estateID: estateID,
                    entryID: entryID,
                    session: &staged,
                    recorder: &replayRecorder,
                    world: world
                )
                trace(evidence)
                return success(evidence)
            case "proof" where arguments.count == 2
                    && arguments[1].lowercased() == "blocker06-cleanup"
                    && environment["PEBBLELAB_GATE_D_BLOCKER_06"] == "1":
                let evidence = try cleanupBlocker06EstateProof(
                    session: staged, world: world
                )
                trace(evidence)
                return success(evidence)
            case "proof" where arguments.count == 2
                    && arguments[1].lowercased()
                        == "blocker07-inherited-use"
                    && environment["PEBBLELAB_GATE_D_BLOCKER_07"] == "1":
                let evidence = try proveBlocker07InheritedEstateUse(
                    session: &staged, world: world
                )
                session = staged
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
                        + "proof <rollback|physical|authority|"
                        + "pre-mutation-refusal <estateID> <entryID>|"
                        + "cleanup|blocker06-cleanup>>"
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
        if value.lowercased() == "tracked" {
            return session.estateSnapshot().estates.first {
                $0.estateID == estateID
            }?.assets.filter {
                $0.materialRightsAssetID != nil
            }.min {
                $0.entryID < $1.entryID
            }?.entryID
        }
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

    private func estatePhysicalAuthorityEvidence(
        estateID: AgentEstateID,
        entryID: AgentEstateAssetEntryID,
        session: AgentSimulationSession,
        world: World
    ) throws -> String {
        guard let estate = session.estateSnapshot().estates.first(where: {
            $0.estateID == estateID
        }), let entry = estate.assets.first(where: {
            $0.entryID == entryID
        }), let sourceHolder = entry.holderAtOpening?.holder,
              let custodianID = entry.intendedCustodianID,
              let destinationProbe = probesByAgentId[custodianID.rawValue],
              let assetID = entry.materialRightsAssetID,
              let rights = session.materialRightsSnapshot().records.first(
                where: { $0.asset.assetID == assetID }
              ) else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "Blocker 06 physical evidence unavailable"
            )
        }
        let source = try estateCustodyEndpoint(for: sourceHolder, world: world)
        let destination = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            destinationProbe, in: world
        )
        let sourceCustody = try materialCustodyGateway.inspect(source)
        let destinationCustody = try materialCustodyGateway.inspect(destination)
        let sourceFingerprint = try materialCustodyGateway.fingerprint(source)
        let destinationFingerprint = try materialCustodyGateway.fingerprint(
            destination
        )
        let sourceStacks = sourceCustody.slots.compactMap { $0 }
        let destinationStacks = destinationCustody.slots.compactMap { $0 }
        let trackedSource = sourceStacks.filter {
            $0.identity == entry.materialIdentity
        }.reduce(0) { $0 + $1.count }
        let trackedDestination = destinationStacks.filter {
            $0.identity == entry.materialIdentity
        }.reduce(0) { $0 + $1.count }
        let hoeSource = sourceStacks.filter {
            $0.identity.itemKey == "iron_hoe"
        }.reduce(0) { $0 + $1.count }
        let hoeDestination = destinationStacks.filter {
            $0.identity.itemKey == "iron_hoe"
        }.reduce(0) { $0 + $1.count }
        let receiptCount = estate.assets.filter {
            $0.settlementReceiptID == entry.settlementReceiptID
                && entry.settlementReceiptID != nil
        }.count
        guard trackedSource + trackedDestination == entry.quantity,
              hoeSource + hoeDestination == 1,
              entry.status == .pendingSettlement
                ? (trackedSource == entry.quantity
                    && trackedDestination == 0
                    && rights.lastVerifiedHolder.holder == sourceHolder)
                : (entry.status == .transferred
                    && trackedSource == 0
                    && trackedDestination == entry.quantity
                    && rights.lastVerifiedHolder.holder == .agent(custodianID)),
              receiptCount <= 1 else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "Blocker 06 physical conservation diverged"
            )
        }
        let sourceDigest = AgentCheckpointDigest.sha256(
            Data(sourceFingerprint.utf8)
        ).rawValue
        let destinationDigest = AgentCheckpointDigest.sha256(
            Data(destinationFingerprint.utf8)
        ).rawValue
        return "estate physical authority estate=\(estateID.rawValue) "
            + "entry=\(entryID.rawValue) status=\(entry.status.rawValue) "
            + "trackedSource=\(trackedSource) trackedDestination=\(trackedDestination) "
            + "hoeSource=\(hoeSource) hoeDestination=\(hoeDestination) "
            + "trackedTotal=\(trackedSource + trackedDestination) "
            + "hoeTotal=\(hoeSource + hoeDestination) physicalLoss=0 "
            + "physicalDuplication=0 syntheticMaterial=0 "
            + "estateReceiptCount=\(receiptCount) duplicateReceipt=0 "
            + "rightsHolder=\(rights.lastVerifiedHolder.holder.stableText) "
            + "sourceFingerprint=\(sourceDigest) "
            + "destinationFingerprint=\(destinationDigest)"
    }

    private func proveEstateSourceAuthorityAdversarial(
        estateID: AgentEstateID,
        entryID: AgentEstateAssetEntryID,
        session: AgentSimulationSession,
        world: World
    ) throws -> String {
        guard let estate = session.estateSnapshot().estates.first(where: {
            $0.estateID == estateID
        }), let entry = estate.assets.first(where: {
            $0.entryID == entryID
        }), entry.status == .pendingSettlement,
              let sourceHolder = entry.holderAtOpening?.holder,
              let custodianID = entry.intendedCustodianID,
              let destinationProbe = probesByAgentId[custodianID.rawValue]
        else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "Blocker 06 authority proof assignment unavailable"
            )
        }
        let source = try estateCustodyEndpoint(for: sourceHolder, world: world)
        let destination = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            destinationProbe, in: world
        )
        guard let sourceBefore = source.read(),
              let destinationBefore = destination.read() else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "Blocker 06 authority proof custody unavailable"
            )
        }
        let bridge = PebbleAgentMaterialSnapshotBridge()
        let trackedSlots = try sourceBefore.indices.filter { index in
            try sourceBefore[index].map {
                try bridge.snapshot(of: $0).identity == entry.materialIdentity
            } ?? false
        }
        let hoeSlots = try sourceBefore.indices.filter { index in
            try sourceBefore[index].map {
                try bridge.snapshot(of: $0).identity.itemKey == "iron_hoe"
            } ?? false
        }
        guard trackedSlots.count == 1, hoeSlots.count == 1,
              sourceBefore.indices.contains(where: {
                  sourceBefore[$0] == nil
              }) else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "Blocker 06 authority fixture is not co-mingled exact"
            )
        }
        let expected = AgentMaterialStackSnapshot(
            identity: entry.materialIdentity, count: entry.quantity
        )
        let initial = try materialCustodyGateway.acquireAssetAuthority(
            expected, at: source
        )
        guard initial.status == .exact else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "Blocker 06 initial authority is not exact"
            )
        }
        let sessionBefore = try session.durableStateBytes()
        let gatewayBefore = materialCustodyGateway.boundarySnapshot()

        func restorePhysical() -> Bool {
            source.write(sourceBefore) && destination.write(destinationBefore)
                && (try? materialCustodyGateway.inspect(source))
                    == (try? bridge.custodySnapshot(
                        locationID: source.locationID, slots: sourceBefore
                    ))
                && (try? materialCustodyGateway.inspect(destination))
                    == (try? bridge.custodySnapshot(
                        locationID: destination.locationID,
                        slots: destinationBefore
                    ))
        }
        do {
            var unrelatedRemoved = copyItemInventory(sourceBefore)
            unrelatedRemoved[hoeSlots[0]] = nil
            guard source.write(unrelatedRemoved),
                  try materialCustodyGateway.acquireAssetAuthority(
                    expected, at: source
                  ).status == .exact,
                  restorePhysical() else {
                throw PebbleAgentEstateBoundaryError.invalid(
                    "unrelated removal changed tracked authority"
                )
            }

            var trackedRemoved = copyItemInventory(sourceBefore)
            trackedRemoved[trackedSlots[0]] = nil
            guard source.write(trackedRemoved),
                  try materialCustodyGateway.acquireAssetAuthority(
                    expected, at: source
                  ).status == .missing,
                  restorePhysical() else {
                throw PebbleAgentEstateBoundaryError.invalid(
                    "tracked removal was not refused"
                )
            }

            let trackedChanged = copyItemInventory(sourceBefore)
            trackedChanged[trackedSlots[0]]?.damage += 1
            guard source.write(trackedChanged),
                  try materialCustodyGateway.acquireAssetAuthority(
                    expected, at: source
                  ).status == .identityMismatch,
                  restorePhysical() else {
                throw PebbleAgentEstateBoundaryError.invalid(
                    "tracked identity change was not refused"
                )
            }

            var trackedDuplicated = copyItemInventory(sourceBefore)
            let emptySlot = trackedDuplicated.firstIndex { $0 == nil }!
            trackedDuplicated[emptySlot] = sourceBefore[trackedSlots[0]]?.copy()
            guard source.write(trackedDuplicated),
                  try materialCustodyGateway.acquireAssetAuthority(
                    expected, at: source
                  ).status == .ambiguous,
                  restorePhysical() else {
                throw PebbleAgentEstateBoundaryError.invalid(
                    "tracked duplicate was not refused"
                )
            }

            var wrongSource = copyItemInventory(sourceBefore)
            var wrongDestination = copyItemInventory(destinationBefore)
            let moved = wrongSource[trackedSlots[0]]!.copy()
            wrongSource[trackedSlots[0]] = nil
            guard insertItemStack(
                    moved, quantity: entry.quantity, into: &wrongDestination
                  ) == entry.quantity,
                  moved.count == 0,
                  source.write(wrongSource),
                  destination.write(wrongDestination),
                  try materialCustodyGateway.acquireAssetAuthority(
                    expected, at: source
                  ).status == .missing,
                  restorePhysical() else {
                throw PebbleAgentEstateBoundaryError.invalid(
                    "wrong-holder tracked asset was not refused"
                )
            }
        } catch {
            _ = restorePhysical()
            materialCustodyGateway.restoreBoundarySnapshot(gatewayBefore)
            throw error
        }
        materialCustodyGateway.restoreBoundarySnapshot(gatewayBefore)
        guard restorePhysical(),
              try session.durableStateBytes() == sessionBefore else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "Blocker 06 adversarial proof restoration failed"
            )
        }
        return "estate source authority adversarial unrelatedAdded=allowed "
            + "unrelatedRemoved=allowed trackedRemoved=refused:missing "
            + "trackedChanged=refused:identityMismatch "
            + "trackedDuplicated=refused:ambiguous "
            + "wrongHolder=refused:missing physical=restored "
            + "session=unchanged gatewayReceipts=unchanged failClosed=1"
    }

    private func proveEstateRollbackRejectsPreMutationFailure(
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
        }), entry.status == .pendingSettlement,
              let sourceHolder = entry.holderAtOpening?.holder,
              let custodianID = entry.intendedCustodianID,
              let destinationProbe = probesByAgentId[custodianID.rawValue]
        else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "pre-mutation refusal proof assignment unavailable"
            )
        }
        let source = try estateCustodyEndpoint(for: sourceHolder, world: world)
        let destination = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            destinationProbe, in: world
        )
        guard let sourceBefore = source.read(),
              let destinationBefore = destination.read() else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "pre-mutation refusal custody unavailable"
            )
        }
        let bridge = PebbleAgentMaterialSnapshotBridge()
        let trackedSlots = try sourceBefore.indices.filter { index in
            try sourceBefore[index].map {
                try bridge.snapshot(of: $0).identity == entry.materialIdentity
            } ?? false
        }
        guard trackedSlots.count == 1 else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "pre-mutation refusal tracked source is not exact"
            )
        }
        var wrongSource = copyItemInventory(sourceBefore)
        var wrongDestination = copyItemInventory(destinationBefore)
        let moved = wrongSource[trackedSlots[0]]!.copy()
        wrongSource[trackedSlots[0]] = nil
        guard insertItemStack(
                moved, quantity: entry.quantity, into: &wrongDestination
              ) == entry.quantity,
              moved.count == 0,
              source.write(wrongSource), destination.write(wrongDestination)
        else {
            _ = source.write(sourceBefore)
            _ = destination.write(destinationBefore)
            throw PebbleAgentEstateBoundaryError.invalid(
                "pre-mutation refusal fault setup failed"
            )
        }
        let staleSource = try materialCustodyGateway.inspect(source)
        let staleDestination = try materialCustodyGateway.inspect(destination)
        let sessionBefore = try staged.durableStateBytes()
        let estateBefore = staged.estateSnapshot()
        let rightsBefore = staged.materialRightsSnapshot()
        let recorderBefore = (
            records: stagedRecorder?.records.count,
            dropped: stagedRecorder?.droppedRecordCount,
            reason: stagedRecorder?.nonReplayableReason
        )
        var refusedAtPreMutationBoundary = false
        do {
            _ = try proveEstateSettlementRollback(
                estateID: estateID,
                entryID: entryID,
                session: &staged,
                recorder: &stagedRecorder,
                world: world
            )
        } catch let PebbleAgentEstateBoundaryError.invalid(message) {
            refusedAtPreMutationBoundary = message.contains("seamReached=0")
                && message.contains("physicalMutationOccurred=0")
                && message.contains("lateFailureVerified=0")
                && message.contains("rollbackClaim=none")
        } catch {
            refusedAtPreMutationBoundary = false
        }
        let proofLeftFaultStateExact =
            try materialCustodyGateway.inspect(source) == staleSource
                && materialCustodyGateway.inspect(destination) == staleDestination
        let sourceExpected = try bridge.custodySnapshot(
            locationID: source.locationID, slots: sourceBefore
        )
        let destinationExpected = try bridge.custodySnapshot(
            locationID: destination.locationID, slots: destinationBefore
        )
        let sourceRestored = source.write(sourceBefore)
        let destinationRestored = destination.write(destinationBefore)
        let sourceRestoredExact = try materialCustodyGateway.inspect(source)
            == sourceExpected
        let destinationRestoredExact = try materialCustodyGateway.inspect(
            destination
        ) == destinationExpected
        let restored = sourceRestored && destinationRestored
            && sourceRestoredExact && destinationRestoredExact
        let recorderAfter = (
            records: stagedRecorder?.records.count,
            dropped: stagedRecorder?.droppedRecordCount,
            reason: stagedRecorder?.nonReplayableReason
        )
        guard refusedAtPreMutationBoundary,
              proofLeftFaultStateExact,
              restored,
              try staged.durableStateBytes() == sessionBefore,
              staged.estateSnapshot() == estateBefore,
              staged.materialRightsSnapshot() == rightsBefore,
              recorderAfter.records == recorderBefore.records,
              recorderAfter.dropped == recorderBefore.dropped,
              recorderAfter.reason == recorderBefore.reason else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "pre-mutation refusal proof diverged"
            )
        }
        return "estate rollback proof refused seamReached=0 "
            + "physicalMutationOccurred=0 lateFailureVerified=0 "
            + "rollbackClaim=none staleTrackedAsset=wrongHolder "
            + "proofState=unchanged fixture=restored session=unchanged "
            + "estate=unchanged materialRights=unchanged replay=unchanged"
    }

    private func cleanupBlocker06EstateProof(
        session: AgentSimulationSession,
        world: World
    ) throws -> String {
        guard let estate = session.estateSnapshot().estates.last,
              let entry = estate.assets.first(where: {
                  $0.materialRightsAssetID != nil
              }), entry.status == .transferred,
              let sourceHolder = entry.holderAtOpening?.holder,
              case let .container(location) = sourceHolder,
              let position = estateContainerPosition(location),
              let container = world.getBlockEntity(
                position.x, position.y, position.z
              ), container.type == "container",
              let custodianID = entry.intendedCustodianID,
              let destinationProbe = probesByAgentId[custodianID.rawValue]
        else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "Blocker 06 cleanup fixture unavailable"
            )
        }
        let source = PebbleAgentMaterialCustodyEndpoint.container(
            container, in: world
        )
        let destination = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            destinationProbe, in: world
        )
        guard let sourceBefore = source.read(),
              let destinationBefore = destination.read() else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "Blocker 06 cleanup custody unavailable"
            )
        }
        let bridge = PebbleAgentMaterialSnapshotBridge()
        let sourceSnapshot = try bridge.custodySnapshot(
            locationID: source.locationID, slots: sourceBefore
        )
        let destinationSnapshot = try bridge.custodySnapshot(
            locationID: destination.locationID, slots: destinationBefore
        )
        guard sourceSnapshot.slots.compactMap({ $0 }).count == 1,
              sourceSnapshot.slots.compactMap({ $0 }).first?.identity.itemKey
                == "iron_hoe",
              sourceSnapshot.slots.compactMap({ $0 }).first?.count == 1,
              destinationSnapshot.slots.compactMap({ $0 }).count == 1,
              destinationSnapshot.slots.compactMap({ $0 }).first?.identity
                == entry.materialIdentity,
              destinationSnapshot.slots.compactMap({ $0 }).first?.count
                == entry.quantity else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "Blocker 06 cleanup material is not exact"
            )
        }
        let emptySource = Array<ItemStack?>(
            repeating: nil, count: sourceBefore.count
        )
        let emptyDestination = Array<ItemStack?>(
            repeating: nil, count: destinationBefore.count
        )
        guard source.write(emptySource), destination.write(emptyDestination)
        else {
            _ = source.write(sourceBefore)
            _ = destination.write(destinationBefore)
            throw PebbleAgentEstateBoundaryError.invalid(
                "Blocker 06 cleanup inventory mutation failed"
            )
        }
        _ = world.setBlock(position.x, position.y, position.z, 0)
        guard world.getBlock(position.x, position.y, position.z) == 0,
              world.getBlockEntity(position.x, position.y, position.z) == nil,
              destinationProbe.carriedItems.allSatisfy({ $0 == nil }) else {
            _ = world.setBlock(
                position.x, position.y, position.z, Int(cell(B.chest))
            )
            container.items = copyItemInventory(sourceBefore)
            world.setBlockEntity(container)
            destinationProbe.carriedItems = copyItemInventory(destinationBefore)
            throw PebbleAgentEstateBoundaryError.invalid(
                "Blocker 06 cleanup rollback required"
            )
        }
        return "estate blocker06 cleanup world=exact trackedPickaxeRemoved=1 "
            + "unregisteredHoeRemoved=1 fixtureContainerRemoved=1 "
            + "session=unchanged probes=\(probesByAgentId.count) duplicates=0"
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
        var rejectedAtInjectedLateSeam = false
        var physicalMutationOccurred = false
        do {
            _ = try settleEstateAsset(
                estateID: estateID,
                entryID: entryID,
                session: &staged,
                recorder: &stagedRecorder,
                world: world,
                injectFailureAfterVerifiedPhysicalMutation: {
                    physicalMutationOccurred = true
                }
            )
        } catch PebbleAgentEstateBoundaryError.injectedLateSettlementFailure {
            rejectedAtInjectedLateSeam = true
        } catch {
            guard physicalMutationOccurred else {
                throw PebbleAgentEstateBoundaryError.invalid(
                    "estate rollback proof refused seamReached=0 "
                        + "physicalMutationOccurred=0 lateFailureVerified=0 "
                        + "rollbackClaim=none cause=\(error)"
                )
            }
            throw error
        }
        let sourceAfter = try materialCustodyGateway.inspect(source)
        let destinationAfter = try materialCustodyGateway.inspect(destination)
        let replayAfter = (
            records: stagedRecorder?.records.count,
            dropped: stagedRecorder?.droppedRecordCount,
            reason: stagedRecorder?.nonReplayableReason
        )
        guard rejectedAtInjectedLateSeam,
              physicalMutationOccurred,
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
            + "source=restored destination=restored replay=unchanged "
            + "physicalMutationOccurred=1 postMutationVerified=1 "
            + "faultInjectionReached=1 rollbackClaim=exact"
    }

    @discardableResult
    func settleEstateAsset(
        estateID: AgentEstateID,
        entryID: AgentEstateAssetEntryID,
        session published: inout AgentSimulationSession,
        recorder publishedRecorder: inout AgentReplayRecorder?,
        world: World,
        injectFailureAfterVerifiedPhysicalMutation: (() -> Void)? = nil
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
        let currentSourceAuthority = try materialCustodyGateway
            .acquireAssetAuthority(
                AgentMaterialStackSnapshot(
                    identity: entry.materialIdentity,
                    count: entry.quantity
                ),
                at: source
            )
        guard currentSourceAuthority.isExact else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "stale estate source trackedAsset="
                    + currentSourceAuthority.status.rawValue
            )
        }
        let sourceFingerprint =
            currentSourceAuthority.currentCustodyFingerprint
        let destinationCustody = try materialCustodyGateway.inspect(destination)
        guard destinationCustody.slots.compactMap({ $0 }).allSatisfy({
            $0.identity != entry.materialIdentity
        }) else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "ambiguous estate destination"
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
                    let matchingDestination = custody.slots.compactMap { $0 }.filter {
                        $0.identity == entry.materialIdentity
                    }
                    let sourceAfter = try self.materialCustodyGateway.inspect(
                        source
                    )
                    guard matchingDestination.count == 1,
                          matchingDestination[0].count == entry.quantity,
                          sourceAfter.slots.compactMap({ $0 }).allSatisfy({
                              $0.identity != entry.materialIdentity
                          }) else {
                        return false
                    }
                    if let injectFailureAfterVerifiedPhysicalMutation {
                        injectFailureAfterVerifiedPhysicalMutation()
                        publicationError = PebbleAgentEstateBoundaryError
                            .injectedLateSettlementFailure
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

    /// Exercises a settled inherited tool through the existing physical
    /// action and Material Rights boundaries immediately after checkpoint
    /// load. This proof command is restricted to a disposable World and does
    /// not create either material or social authority.
    private func proveBlocker07InheritedEstateUse(
        session published: inout AgentSimulationSession,
        world: World
    ) throws -> String {
        guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1",
              environment["PEBBLELAB_GATE_D_BLOCKER_07"] == "1",
              activeWorld === world, isPaused, !movementEnabled,
              let estate = published.estateSnapshot().estates.last,
              let entry = estate.assets.first(where: {
                  $0.status == .transferred
                      && $0.materialIdentity.itemKey == "iron_pickaxe"
              }),
              entry.settlementReceiptID != nil,
              let assetID = entry.materialRightsAssetID,
              let record = published.materialRightsSnapshot().records.first(
                  where: { $0.asset.assetID == assetID }
              ),
              case let .agent(holderID) = record.lastVerifiedHolder.holder,
              record.recognizedOwnership?.ownerID == holderID,
              entry.intendedCustodianID == holderID,
              let probe = probesByAgentId[holderID.rawValue],
              probe.world === world, !probe.dead else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "blocker07 inherited-use authority"
            )
        }
        let reconciliation = published.persistenceReconciliationSnapshot()
        guard reconciliation.recentRuns.count == 1,
              reconciliation.latestResults.first(where: {
                  $0.assetID == assetID
              })?.outcome.hasVerifiedPhysicalAsset == true else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "blocker07 inherited-use current physical reconciliation"
            )
        }

        let endpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            probe, in: world
        )
        let custodyBefore = try materialCustodyGateway.inspect(endpoint)
        let matchingBefore = custodyBefore.slots.enumerated().filter {
            $0.element?.identity == record.lastVerifiedHolder.materialIdentity
                && $0.element?.count == record.lastVerifiedHolder.quantity
        }
        let fingerprintBefore = try materialCustodyGateway.fingerprint(endpoint)
        guard matchingBefore.count == 1,
              fingerprintBefore == record.lastVerifiedHolder.custodyFingerprint,
              record.lastVerifiedHolder.quantity == 1 else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "blocker07 inherited-use stale tracked asset"
            )
        }

        let actor = PebbleAgentEmbodiment(probe: probe)
        let origin = PhysicalBlockPosition(
            x: Int(probe.x.rounded(.down)),
            y: Int(probe.y.rounded(.down)),
            z: Int(probe.z.rounded(.down))
        )
        let occupied = probesByAgentId.values.filter {
            !$0.dead && $0.world === world
        }.map {
            PhysicalBlockPosition(
                x: Int($0.x.rounded(.down)),
                y: Int($0.y.rounded(.down)),
                z: Int($0.z.rounded(.down))
            )
        }
        let offsets = [(1, 0), (-1, 0), (0, 1), (0, -1)]
        let targets = [-1, 0, 1, 2].flatMap { dy in
            offsets.map { dx, dz in
                PhysicalBlockPosition(
                    x: origin.x + dx, y: origin.y + dy,
                    z: origin.z + dz
                )
            }
        }.filter { target in
            world.getBlock(target.x, target.y, target.z) != 0
                && world.isChunkReady(target.x >> 4, target.z >> 4)
                && world.getBlockEntity(
                    target.x, target.y, target.z
                ) == nil
                && !occupied.contains(target)
        }
        guard let target = targets.first else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "blocker07 inherited-use natural target"
            )
        }
        let blockBefore = world.getBlock(target.x, target.y, target.z)
        guard let binding = materialCustodyGateway.harvestToolBinding(
            actor: probe, targetCell: blockBefore, world: world
        ), binding.slot == matchingBefore[0].offset,
              binding.heldItem.id == iid("iron_pickaxe") else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "blocker07 inherited-use tool binding"
            )
        }

        let damageBefore = binding.heldItem.damage
        let operationID = "gate-d-blocker07-inherited-tool-use:"
            + "\(estate.estateID.rawValue):t\(published.tick)"
        let decision = published.evaluateMaterialUse(AgentMaterialUseRequest(
            requestID: operationID + ":decision",
            assetID: assetID,
            actorID: holderID,
            use: .toolUse,
            verifiedHolder: record.lastVerifiedHolder
        ))
        guard decision.verdict == .allowed,
              decision.reason == .recognizedOwner else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "blocker07 inherited-use right refused "
                    + "verdict=\(decision.verdict.rawValue) "
                    + "reason=\(decision.reason.rawValue)"
            )
        }

        let gatewayBefore = materialCustodyGateway.boundarySnapshot()
        var candidateSession: AgentSimulationSession?
        var publicationError: Error?
        var acquiredDropQuantity = 0
        let outcome = physicalActionGateway.breakBlock(
            world: world,
            actor: actor,
            request: PebbleAgentBlockBreakRequest(
                actorID: holderID.rawValue,
                target: target,
                expectedCell: blockBefore,
                heldItem: binding.heldItem,
                isCreative: false
            ),
            toolState: binding.toolState,
            occupiedPositions: occupied,
            acquireDrops: { entityIDs in
                guard !entityIDs.isEmpty else { return true }
                guard let source = PebbleAgentItemEntityCustodyEndpoint(
                    spawnedItemEntityIDs: entityIDs, world: world
                ) else { return false }
                guard let destinationFingerprint = try? self
                    .materialCustodyGateway.fingerprint(endpoint) else {
                    return false
                }
                let result = self.materialCustodyGateway.acquireItemEntities(
                    PebbleAgentItemEntityAcquisitionRequest(
                        transactionID: operationID + ":drops",
                        spawnedItemEntityIDs: entityIDs,
                        expectedDestinationFingerprint: destinationFingerprint
                    ),
                    from: source,
                    to: endpoint
                )
                acquiredDropQuantity = result.quantityMoved
                return result.succeeded
            },
            verifyAfterMutation: {
                do {
                    let custodyAfter = try self.materialCustodyGateway.inspect(
                        endpoint
                    )
                    let matches = custodyAfter.slots.compactMap({ $0 }).filter {
                        $0.identity.itemKey == "iron_pickaxe"
                            && $0.count == record.lastVerifiedHolder.quantity
                    }
                    guard matches.count == 1,
                          matches[0].identity.damage == damageBefore + 1,
                          world.getBlock(
                            target.x, target.y, target.z
                          ) == 0 else { return false }
                    let observation = AgentMaterialHolderObservation(
                        holder: .agent(holderID),
                        materialIdentity: matches[0].identity,
                        quantity: matches[0].count,
                        custodyFingerprint: try self.materialCustodyGateway
                            .fingerprint(endpoint),
                        physicalReceiptID: operationID,
                        observedAtTick: published.tick
                    )
                    var staged = published
                    _ = try staged.applyMaterialRightsOperation(.useAttempt(
                        AgentMaterialUseAttemptOutcome(
                            operationID: operationID,
                            decision: decision,
                            status: .succeeded,
                            resultingObservation: observation,
                            physicalReceiptID: operationID
                        )
                    ))
                    try staged.validateEstateCrossDomainIfEnabled()
                    candidateSession = staged
                    return true
                } catch {
                    publicationError = error
                    return false
                }
            }
        )
        guard outcome.succeeded, let candidateSession else {
            if outcome.status != .rollbackFailure {
                materialCustodyGateway.restoreBoundarySnapshot(gatewayBefore)
            }
            throw publicationError
                ?? PebbleAgentEstateBoundaryError.invalid(
                    "blocker07 inherited-use physical action "
                        + outcome.status.rawValue
                )
        }
        published = candidateSession

        let custodyAfter = try materialCustodyGateway.inspect(endpoint)
        let pickaxesAfter = custodyAfter.slots.compactMap({ $0 }).filter {
            $0.identity.itemKey == "iron_pickaxe"
        }
        let updated = published.materialRightsSnapshot().records.first {
            $0.asset.assetID == assetID
        }
        let updatedEntry = published.estateSnapshot().estates.first {
            $0.estateID == estate.estateID
        }?.assets.first { $0.entryID == entry.entryID }
        guard pickaxesAfter.count == 1,
              pickaxesAfter[0].count == 1,
              pickaxesAfter[0].identity.damage == damageBefore + 1,
              updated?.lastVerifiedHolder.materialIdentity
                == pickaxesAfter[0].identity,
              updated?.lastVerifiedHolder.holder == .agent(holderID),
              updatedEntry?.status == .transferred,
              updatedEntry?.settlementReceiptID == entry.settlementReceiptID,
              updatedEntry?.destinationObservation
                == updated?.lastVerifiedHolder else {
            throw PebbleAgentEstateBoundaryError.invalid(
                "blocker07 inherited-use publication verification"
            )
        }
        return [
            "blocker07 inherited estate use",
            "estate=\(estate.estateID.rawValue)",
            "entry=\(entry.entryID.rawValue)",
            "asset=\(assetID.rawValue)",
            "actor=\(holderID.rawValue)",
            "holder=agent:\(holderID.rawValue)",
            "right=\(decision.reason.rawValue)",
            "tool=iron_pickaxe",
            "damage=\(damageBefore)>\(pickaxesAfter[0].identity.damage)",
            "target=\(target.x),\(target.y),\(target.z)",
            "block=\(blockBefore)>0",
            "dropsAcquired=\(acquiredDropQuantity)",
            "physicalMutationOccurred=1",
            "postMutationVerified=1",
            "rightsPublication=1",
            "estateEntryStatus=transferred",
            "estateReceiptCount=1",
            "reconciliationRuns=\(reconciliation.recentRuns.count)",
            "firstAttempt=allowed",
            "physicalLoss=0",
            "physicalDuplication=0",
            "syntheticMaterial=0",
            "fingerprint=\(fingerprintBefore)>"
                + "\(updated!.lastVerifiedHolder.custodyFingerprint)",
            "authority=PebbleCore+PebbleGateway",
        ].joined(separator: " ")
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
