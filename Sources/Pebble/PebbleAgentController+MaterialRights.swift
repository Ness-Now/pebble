import PebbleAgents
import PebbleCore

struct PebbleAgentMaterialRightsProofFixture {
    let inventoriesByAgentID: [String: [ItemStack?]]
    let proofItemEntityIDs: [Int]
    let proofItemID: Int
    let probeEntityIDsByAgentID: [String: Int]
}

private enum PebbleAgentMaterialRightsProofError: Error {
    case failed(String)
}

extension PebbleAgentController {
    func handleMaterialRights(
        _ arguments: [String],
        world: World
    ) -> PebbleAgentCommandResult {
        switch arguments {
        case ["proof"]:
            return runMaterialRightsProof(world: world)
        case ["status"]:
            return materialRightsStatus()
        case ["clear"]:
            guard cleanupMaterialRightsProofFixture(world: world) else {
                return failure("Material-rights cleanup failed; session retained.")
            }
            return success("Material-rights proof custody and state cleared.")
        default:
            return failure("Usage: /lab rights <proof|status|clear>")
        }
    }

    private func runMaterialRightsProof(world: World) -> PebbleAgentCommandResult {
        let gates = [
            ("PEBBLELAB_APP_AGENTS=1", featureEnabled),
            ("PEBBLELAB_APP_AGENTS_MATERIAL=1", materialFeatureEnabled),
            ("PEBBLELAB_APP_PROBES=1", probesFeatureEnabled),
            ("PEBBLELAB_DEBUG_ENTITIES=1", debugEntitiesEnabled),
            ("PEBBLELAB_APP_AGENTS_TRACE=1", traceEnabled),
            (
                "PEBBLELAB_DISPOSABLE_WORLD_PROOF=1",
                environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1"
            ),
        ]
        let missing = gates.filter { !$0.1 }.map(\.0)
        guard missing.isEmpty else {
            return failure(
                "Material-rights proof refused; missing gates: "
                    + missing.joined(separator: ", ")
            )
        }
        guard rightsProofFixture == nil else {
            return failure("Material-rights proof already active; clear it first.")
        }
        guard var published = session, activeWorld === world else {
            return failure("Material-rights proof requires an active session in this World.")
        }
        guard isPaused, !movementEnabled, !autoInteractionEnabled else {
            return failure(
                "Material-rights proof requires pause, movement off, and interaction auto off."
            )
        }
        let requiredIDs = ["agent_0", "agent_1", "agent_2"]
        guard requiredIDs.allSatisfy({ id in
            probesByAgentId[id].map {
                !$0.dead && $0.carriedItems.allSatisfy { $0 == nil }
            } == true
        }) else {
            return failure(
                "Material-rights proof requires three live agents with empty physical custody."
            )
        }
        let fixture = PebbleAgentMaterialRightsProofFixture(
            inventoriesByAgentID: Dictionary(uniqueKeysWithValues: requiredIDs.compactMap {
                id in probesByAgentId[id].map { (id, copyItemInventory($0.carriedItems)) }
            }),
            proofItemEntityIDs: world.entities.compactMap {
                guard let item = $0 as? ItemEntity,
                      item.stack.id == iid("iron_pickaxe") else { return nil }
                return item.id
            }.sorted(),
            proofItemID: iid("iron_pickaxe"),
            probeEntityIDsByAgentID: Dictionary(uniqueKeysWithValues: requiredIDs.compactMap {
                id in probesByAgentId[id].map { (id, $0.id) }
            })
        )
        rightsProofFixture = fixture

        do {
            try published.setMaterialRightsEnabled(true)
            let assetID = AgentMaterialAssetID(rawValue: "asset:iron_pickaxe:live")!
            let ownerClaimID = AgentMaterialClaimID(rawValue: "claim:agent_0:live")!
            let competingClaimID = AgentMaterialClaimID(rawValue: "claim:agent_2:live")!
            let permissionID = AgentMaterialPermissionID(
                rawValue: "permission:agent_1:live"
            )!
            let ownerID = AgentID(rawValue: "agent_0")!
            let borrowerID = AgentID(rawValue: "agent_1")!
            let takerID = AgentID(rawValue: "agent_2")!
            let owner = probesByAgentId[ownerID.rawValue]!
            owner.carriedItems[0] = ItemStack(iid("iron_pickaxe"), 1)
            materialCustodyGateway.reset()

            let ownerObservation = try materialRightsObservation(
                actorID: ownerID,
                receiptID: "civ26-register",
                world: world
            )
            let material = AgentMaterialStackSnapshot(
                identity: ownerObservation.materialIdentity,
                count: ownerObservation.quantity
            )
            _ = try published.applyMaterialRightsOperation(.register(
                operationID: "civ26-register",
                asset: AgentMaterialAssetReference(
                    assetID: assetID,
                    materialIdentity: ownerObservation.materialIdentity,
                    quantity: ownerObservation.quantity
                ),
                observation: ownerObservation
            ))
            _ = try published.applyMaterialRightsOperation(.assertClaim(
                operationID: "civ26-owner-claim",
                assetID: assetID,
                claimID: ownerClaimID,
                claimantID: ownerID,
                basis: .produced
            ))
            _ = try published.applyMaterialRightsOperation(.recognizeOwnership(
                operationID: "civ26-recognize-owner",
                assetID: assetID,
                claimID: ownerClaimID,
                recognizingAgentIDs: [ownerID, borrowerID, takerID]
            ))

            try performMaterialRightsTransfer(
                operationID: "civ26-loan",
                assetID: assetID,
                material: material,
                requesterID: ownerID,
                sourceID: ownerID,
                destinationID: borrowerID,
                disposition: .authorized,
                world: world,
                session: &published
            )
            _ = try published.applyMaterialRightsOperation(.delegateCustody(
                operationID: "civ26-delegate-custody",
                assetID: assetID,
                custodianID: borrowerID,
                actorID: ownerID
            ))

            let borrowed = try materialRightsRecord(assetID, in: published)
            let deniedBorrower = published.evaluateMaterialUse(
                AgentMaterialUseRequest(
                    requestID: "civ26-borrower-denied",
                    assetID: assetID,
                    actorID: borrowerID,
                    use: .transferCustody,
                    verifiedHolder: borrowed.lastVerifiedHolder
                )
            )
            _ = try published.applyMaterialRightsOperation(.useAttempt(
                AgentMaterialUseAttemptOutcome(
                    operationID: "civ26-borrower-denied",
                    decision: deniedBorrower,
                    status: .notAttempted,
                    resultingObservation: nil,
                    physicalReceiptID: nil
                )
            ))
            _ = try published.applyMaterialRightsOperation(.grantUse(
                operationID: "civ26-grant-borrower",
                assetID: assetID,
                permissionID: permissionID,
                grantorID: ownerID,
                userID: borrowerID,
                allowedUses: [.transferCustody, .toolUse],
                expiresAtTick: nil
            ))
            try performMaterialRightsTransfer(
                operationID: "civ26-authorized-return",
                assetID: assetID,
                material: material,
                requesterID: borrowerID,
                sourceID: borrowerID,
                destinationID: ownerID,
                disposition: .authorized,
                world: world,
                session: &published
            )
            try performMaterialRightsTransfer(
                operationID: "civ26-second-loan",
                assetID: assetID,
                material: material,
                requesterID: ownerID,
                sourceID: ownerID,
                destinationID: borrowerID,
                disposition: .authorized,
                world: world,
                session: &published
            )
            try performMaterialRightsTransfer(
                operationID: "civ26-unauthorized-take",
                assetID: assetID,
                material: material,
                requesterID: takerID,
                sourceID: borrowerID,
                destinationID: takerID,
                disposition: .observedTransgression,
                world: world,
                session: &published
            )
            _ = try published.applyMaterialRightsOperation(.assertClaim(
                operationID: "civ26-competing-claim",
                assetID: assetID,
                claimID: competingClaimID,
                claimantID: takerID,
                basis: .contested
            ))
            try performMaterialRightsTransfer(
                operationID: "civ26-late-rollback",
                assetID: assetID,
                material: material,
                requesterID: takerID,
                sourceID: takerID,
                destinationID: ownerID,
                disposition: .observedTransgression,
                rejectAfterMutation: true,
                world: world,
                session: &published
            )

            let final = try materialRightsRecord(assetID, in: published)
            guard final.lastVerifiedHolder.holder == .agent(takerID),
                  final.custodianID == borrowerID,
                  final.recognizedOwnership?.ownerID == ownerID,
                  final.claims.map(\.claimantID) == [ownerID, takerID],
                  final.permissions.map(\.userID) == [borrowerID],
                  final.hasConflict,
                  deniedBorrower.verdict == .denied,
                  probesByAgentId[takerID.rawValue]?.carriedItems[0]?.id
                    == iid("iron_pickaxe"),
                  probesByAgentId[ownerID.rawValue]?.carriedItems.allSatisfy({
                      $0 == nil
                  }) == true,
                  probesByAgentId[borrowerID.rawValue]?.carriedItems.allSatisfy({
                      $0 == nil
                  }) == true else {
                throw PebbleAgentMaterialRightsProofError.failed(
                    "final physical/social divergence"
                )
            }
            session = published
            focusedAgentId = takerID.rawValue
            followMode = .focusedAgent
            overlayModeByCommand = .compact
            let digest = try published.durableStateDigest().rawValue
            trace(
                "rights proof asset=\(assetID.rawValue) physicalHolder=agent_2 "
                    + "custodian=agent_1 recognizedOwner=agent_0 "
                    + "claims=agent_0,agent_2 authorizedUser=agent_1 "
                    + "aligned=allowed loan=verified borrowerDenied=noUseRight "
                    + "authorizedReturn=verified unauthorizedTake=transgression "
                    + "conflict=active rollback=verified rolesAfterRollback=unchanged "
                    + "authority=PebbleCore transfer=PebbleGateway state=AgentSimulationSession "
                    + "fixture=retainedForCapture digest=\(digest)"
            )
            return success(
                "CIV-26 proof active for capture: holder agent_2, custodian agent_1, "
                    + "recognized owner agent_0, competing claims, borrower permission."
            )
        } catch {
            session = published
            let cleaned = cleanupMaterialRightsProofFixture(world: world)
            return failure(
                "Material-rights proof failed: \(error); cleanup="
                    + (cleaned ? "verified" : "failed")
            )
        }
    }

    private func performMaterialRightsTransfer(
        operationID: String,
        assetID: AgentMaterialAssetID,
        material: AgentMaterialStackSnapshot,
        requesterID: AgentID,
        sourceID: AgentID,
        destinationID: AgentID,
        disposition: AgentMaterialExecutionDisposition,
        rejectAfterMutation: Bool = false,
        world: World,
        session published: inout AgentSimulationSession
    ) throws {
        guard let sourceActor = probesByAgentId[sourceID.rawValue],
              let destinationActor = probesByAgentId[destinationID.rawValue] else {
            throw PebbleAgentMaterialRightsProofError.failed("missing physical holder")
        }
        let record = try materialRightsRecord(assetID, in: published)
        guard record.lastVerifiedHolder.holder == .agent(sourceID) else {
            throw PebbleAgentMaterialRightsProofError.failed("stale social holder")
        }
        let source = PebbleAgentMaterialCustodyEndpoint.liveAgent(sourceActor, in: world)
        let destination = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            destinationActor, in: world
        )
        guard try materialCustodyGateway.fingerprint(source)
                == record.lastVerifiedHolder.custodyFingerprint else {
            throw PebbleAgentMaterialRightsProofError.failed("stale physical holder")
        }
        let decision = published.evaluateMaterialUse(AgentMaterialUseRequest(
            requestID: "\(operationID):decision",
            assetID: assetID,
            actorID: requesterID,
            use: .transferCustody,
            verifiedHolder: record.lastVerifiedHolder
        ))
        var candidate: AgentSimulationSession?
        var publicationError: Error?
        let physical = materialCustodyGateway.transfer(
            PebbleAgentMaterialTransactionRequest(
                transactionID: operationID,
                material: material,
                expectedSourceFingerprint: try materialCustodyGateway.fingerprint(source),
                expectedDestinationFingerprint: try materialCustodyGateway.fingerprint(destination)
            ),
            from: source,
            to: destination,
            verifyAfterMutation: {
                guard !rejectAfterMutation else { return false }
                do {
                    let observation = try self.materialRightsObservation(
                        actorID: destinationID,
                        receiptID: operationID,
                        world: world
                    )
                    var staged = published
                    _ = try staged.applyMaterialRightsOperation(.physicalTransfer(
                        AgentMaterialPhysicalTransferOutcome(
                            operationID: operationID,
                            decision: decision,
                            disposition: disposition,
                            status: .succeeded,
                            destinationObservation: observation,
                            physicalReceiptID: operationID
                        )
                    ))
                    candidate = staged
                    return true
                } catch {
                    publicationError = error
                    return false
                }
            }
        )
        if rejectAfterMutation {
            guard physical.status == .verificationFailure else {
                throw PebbleAgentMaterialRightsProofError.failed(
                    "late transfer did not roll back"
                )
            }
            _ = try published.applyMaterialRightsOperation(.physicalTransfer(
                AgentMaterialPhysicalTransferOutcome(
                    operationID: operationID,
                    decision: decision,
                    disposition: disposition,
                    status: .rolledBack,
                    destinationObservation: nil,
                    physicalReceiptID: operationID
                )
            ))
            return
        }
        guard physical.status == .succeeded, let candidate else {
            throw publicationError
                ?? PebbleAgentMaterialRightsProofError.failed(
                    "physical transfer \(physical.status.rawValue)"
                )
        }
        published = candidate
    }

    private func materialRightsObservation(
        actorID: AgentID,
        receiptID: String,
        world: World
    ) throws -> AgentMaterialHolderObservation {
        guard let actor = probesByAgentId[actorID.rawValue] else {
            throw PebbleAgentMaterialRightsProofError.failed("missing actor observation")
        }
        let endpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(actor, in: world)
        let custody = try materialCustodyGateway.inspect(endpoint)
        let stacks = custody.slots.compactMap { $0 }
        guard stacks.count == 1, stacks[0].count == 1 else {
            throw PebbleAgentMaterialRightsProofError.failed(
                "physical custody is not one exact item"
            )
        }
        return AgentMaterialHolderObservation(
            holder: .agent(actorID),
            materialIdentity: stacks[0].identity,
            quantity: stacks[0].count,
            custodyFingerprint: try materialCustodyGateway.fingerprint(endpoint),
            physicalReceiptID: receiptID,
            observedAtTick: session?.tick ?? 0
        )
    }

    private func materialRightsRecord(
        _ assetID: AgentMaterialAssetID,
        in session: AgentSimulationSession
    ) throws -> AgentMaterialRightsRecord {
        guard let record = session.materialRightsSnapshot().records.first(where: {
            $0.asset.assetID == assetID
        }) else {
            throw PebbleAgentMaterialRightsProofError.failed("missing rights record")
        }
        return record
    }

    private func materialRightsStatus() -> PebbleAgentCommandResult {
        guard let session else { return failure("No active PebbleAgents session.") }
        let snapshot = session.materialRightsSnapshot()
        guard snapshot.enabled else {
            return success("Material rights disabled.")
        }
        let records = snapshot.records.map { record in
            "\(record.asset.assetID.rawValue):holder="
                + "\(record.lastVerifiedHolder.holder.stableText)"
                + ",custodian=\(record.custodianID?.rawValue ?? "none")"
                + ",owner=\(record.recognizedOwnership?.ownerID.rawValue ?? "none")"
                + ",claims=\(record.claims.map(\.claimantID.rawValue).joined(separator: "+"))"
                + ",users=\(record.permissions.map(\.userID.rawValue).joined(separator: "+"))"
                + ",conflict=\(record.hasConflict ? "yes" : "no")"
        }.joined(separator: ";")
        trace(
            "rights status enabled=1 assets=\(snapshot.records.count) "
                + "conflicts=\(snapshot.conflictCount) records=\(records)"
        )
        return success(
            "Material rights assets=\(snapshot.records.count) "
                + "conflicts=\(snapshot.conflictCount) \(records)"
        )
    }

    func cleanupMaterialRightsProofFixture(world: World) -> Bool {
        guard let fixture = rightsProofFixture else { return true }
        for (id, inventory) in fixture.inventoriesByAgentID {
            guard let actor = probesByAgentId[id] else {
                trace("rights cleanup refused reason=missingProbe id=\(id)")
                return false
            }
            actor.carriedItems = copyItemInventory(inventory)
        }
        let custodyExact = fixture.inventoriesByAgentID.allSatisfy { id, inventory in
            guard let actual = probesByAgentId[id]?.carriedItems,
                  actual.count == inventory.count else { return false }
            return zip(actual, inventory).allSatisfy { lhs, rhs in
                switch (lhs, rhs) {
                case (nil, nil): return true
                case let (lhs?, rhs?): return lhs == rhs
                default: return false
                }
            }
        }
        let proofItemEntitiesExact = world.entities.compactMap {
            guard let item = $0 as? ItemEntity,
                  item.stack.id == fixture.proofItemID else { return nil }
            return item.id
        }.sorted() == fixture.proofItemEntityIDs
        let probesExact = fixture.probeEntityIDsByAgentID.allSatisfy {
            id, entityID in
            guard let actor = probesByAgentId[id] else { return false }
            return actor.id == entityID && !actor.dead
                && world.entities.contains { $0 === actor }
        }
        guard custodyExact, proofItemEntitiesExact, probesExact else {
            trace(
                "rights cleanup refused reason=physicalMismatch custody="
                    + "\(custodyExact ? "exact" : "diverged") proofItemEntities="
                    + "\(proofItemEntitiesExact ? "exact" : "diverged") probes="
                    + "\(probesExact ? "exact" : "diverged")"
            )
            return false
        }
        if var current = session {
            do {
                try current.setMaterialRightsEnabled(false)
            } catch {
                trace("rights cleanup refused reason=stateDisable error=\(error)")
                return false
            }
            guard !current.materialRightsEnabled else {
                trace("rights cleanup refused reason=stateStillEnabled")
                return false
            }
            session = current
        }
        materialCustodyGateway.reset()
        rightsProofFixture = nil
        trace("rights cleanup custody=exact entities=exact state=cleared")
        return true
    }
}
