import Foundation
import PebbleAgents
import PebbleCore

private enum PebblePersistenceReconciliationProofError: Error {
    case failed(String)
}

extension PebbleAgentController {
    func handlePersistenceReconciliation(
        _ arguments: [String],
        world: World
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab persistence-reconciliation <setup|status|cleanup>"
        guard let command = arguments.first?.lowercased(), arguments.count == 1 else {
            return failure(usage)
        }
        guard persistenceReconciliationFeatureEnabled else {
            return failure(
                "Persistence reconciliation disabled. Set "
                    + "PEBBLELAB_APP_AGENTS_RECONCILIATION=1 before launch."
            )
        }
        switch command {
        case "setup":
            return setupPersistenceReconciliationProof(world: world)
        case "status":
            return persistenceReconciliationStatus()
        case "cleanup":
            return cleanupPersistenceReconciliationProof(world: world)
        default:
            return failure(usage)
        }
    }

    private func setupPersistenceReconciliationProof(
        world: World
    ) -> PebbleAgentCommandResult {
        let gates = [
            ("PEBBLELAB_APP_AGENTS_PERSISTENCE=1", persistenceFeatureEnabled),
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
                "Persistence-reconciliation proof refused; missing gates: "
                    + missing.joined(separator: ", ")
            )
        }
        guard var staged = session, activeWorld === world else {
            return failure("Persistence reconciliation requires an active session.")
        }
        guard isPaused, !movementEnabled, !autoInteractionEnabled else {
            return failure(
                "Persistence reconciliation requires pause, movement off, and interaction auto off."
            )
        }
        guard !staged.materialRightsEnabled,
              !staged.persistenceReconciliationEnabled,
              !staged.autonomousActivityEnabled else {
            return failure("Persistence reconciliation proof state is already active.")
        }
        let ids = staged.identitySnapshot().agentIDs.sorted()
        guard ids.map(\.rawValue) == ["agent_0", "agent_1", "agent_2"],
              ids.allSatisfy({ probesByAgentId[$0.rawValue] != nil }) else {
            return failure("Persistence reconciliation proof requires exactly three live agents.")
        }
        guard let position = reconciliationProofContainerPosition(world: world) else {
            return failure("No bounded natural support is available for the proof container.")
        }

        let beforeBlock = world.getBlock(position.x, position.y, position.z)
        let beforeEntity = world.getBlockEntity(position.x, position.y, position.z)
        guard beforeBlock == 0, beforeEntity == nil else {
            return failure("Proof container cell is not initially empty.")
        }
        do {
            _ = world.setBlock(
                position.x, position.y, position.z,
                Int(cell(B.chest))
            )
            let container = makeContainerBE(position.x, position.y, position.z, 27)
            container.items?[0] = ItemStack(iid("iron_pickaxe"), 1)
            world.setBlockEntity(container)
            guard world.getBlock(position.x, position.y, position.z)
                    == Int(cell(B.chest)),
                  world.getBlockEntity(position.x, position.y, position.z) === container else {
                throw PebblePersistenceReconciliationProofError.failed(
                    "real container publication"
                )
            }

            let endpoint = PebbleAgentMaterialCustodyEndpoint.container(
                container, in: world
            )
            let custody = try materialCustodyGateway.inspect(endpoint)
            let stacks = custody.slots.compactMap { $0 }
            guard stacks.count == 1, stacks[0].count == 1,
                  stacks[0].identity.itemKey == "iron_pickaxe" else {
                throw PebblePersistenceReconciliationProofError.failed(
                    "exact physical item"
                )
            }
            let holder = AgentMaterialPhysicalHolder.container(
                "\(position.x),\(position.y),\(position.z)"
            )
            let observation = AgentMaterialHolderObservation(
                holder: holder,
                materialIdentity: stacks[0].identity,
                quantity: stacks[0].count,
                custodyFingerprint: try materialCustodyGateway.fingerprint(endpoint),
                physicalReceiptID: "civ27-live-container-setup",
                observedAtTick: staged.tick
            )
            let assetID = AgentMaterialAssetID(rawValue: "asset:civ27:live-pickaxe")!
            let owner = ids[0]
            let custodian = ids[1]
            let claimID = AgentMaterialClaimID(rawValue: "claim:civ27:live-owner")!
            try staged.setMaterialRightsEnabled(true)
            _ = try staged.applyMaterialRightsOperation(.register(
                operationID: "civ27-live-register",
                asset: AgentMaterialAssetReference(
                    assetID: assetID,
                    materialIdentity: stacks[0].identity,
                    quantity: stacks[0].count
                ),
                observation: observation
            ))
            _ = try staged.applyMaterialRightsOperation(.assertClaim(
                operationID: "civ27-live-claim",
                assetID: assetID,
                claimID: claimID,
                claimantID: owner,
                basis: .produced
            ))
            _ = try staged.applyMaterialRightsOperation(.recognizeOwnership(
                operationID: "civ27-live-recognize",
                assetID: assetID,
                claimID: claimID,
                recognizingAgentIDs: ids
            ))
            _ = try staged.applyMaterialRightsOperation(.delegateCustody(
                operationID: "civ27-live-custody",
                assetID: assetID,
                custodianID: custodian,
                actorID: owner
            ))
            _ = try staged.applyMaterialRightsOperation(.grantUse(
                operationID: "civ27-live-use",
                assetID: assetID,
                permissionID: AgentMaterialPermissionID(
                    rawValue: "permission:civ27:live-custodian"
                )!,
                grantorID: owner,
                userID: custodian,
                allowedUses: [.toolUse],
                expiresAtTick: nil
            ))
            try staged.setAutonomousActivityEnabled(true)
            _ = try staged.selectAutonomousActivities([
                AgentAutonomousActivityCandidate(
                    candidateID: "civ27-live-durable-activity",
                    actorID: custodian,
                    domain: .construction,
                    actionKey: "toolUse",
                    stableReference: holder.stableText,
                    target: AgentPosition(
                        x: position.x, y: position.y, z: position.z
                    ),
                    materialFingerprint: "iron_pickaxe:0",
                    source: .commitment,
                    priorityBand: 20,
                    urgency: 60,
                    distance: 1,
                    observedAtTick: staged.tick
                ),
            ])
            try staged.setPersistenceReconciliationEnabled(true)
            session = staged
            let causal = staged.causalLedgerSnapshot().summary
            let message = [
                "persistence reconciliation setup",
                "world=\(persistenceWorldID ?? "none")",
                "container=\(position.x),\(position.y),\(position.z)",
                "asset=\(assetID.rawValue)",
                "holder=\(holder.stableText)",
                "custodian=\(custodian.rawValue)",
                "owner=\(owner.rawValue)",
                "claimants=\(owner.rawValue)",
                "authorized=\(custodian.rawValue)",
                "activity=active",
                "agents=3",
                "physicalItems=1",
                "causalSequence=\(causal.latestSequence)",
                "schema=20",
                "worldMutation=realContainer",
            ].joined(separator: " ")
            trace(message)
            return success(message)
        } catch {
            _ = world.setBlock(position.x, position.y, position.z, beforeBlock)
            let rollbackExact = world.getBlock(position.x, position.y, position.z)
                    == beforeBlock
                && world.getBlockEntity(position.x, position.y, position.z) === beforeEntity
            guard rollbackExact else {
                let message = "persistence reconciliation setup rollback failed"
                lastError = message
                return failure(message)
            }
            return failure("Persistence reconciliation setup failed: \(error)")
        }
    }

    private func persistenceReconciliationStatus() -> PebbleAgentCommandResult {
        guard let session else { return failure("No active PebbleAgents session.") }
        let snapshot = session.persistenceReconciliationSnapshot()
        let rights = session.materialRightsSnapshot()
        let record = rights.records.first
        let result = snapshot.latestResults.first
        let causal = session.causalLedgerSnapshot().summary
        let message = [
            "persistence reconciliation status",
            "enabled=\(snapshot.enabled ? 1 : 0)",
            "runs=\(snapshot.recentRuns.count)",
            "outcome=\(result?.outcome.rawValue ?? "pending")",
            "asset=\(record?.asset.assetID.rawValue ?? "none")",
            "holder=\(record?.lastVerifiedHolder.holder.stableText ?? "none")",
            "custodian=\(record?.custodianID?.rawValue ?? "none")",
            "owner=\(record?.recognizedOwnership?.ownerID.rawValue ?? "none")",
            "claims=\(record?.claims.count ?? 0)",
            "permissions=\(record?.permissions.count ?? 0)",
            "activity=\(session.autonomousActivitySnapshot().activeActivities.count)",
            "agents=\(session.identitySnapshot().agentIDs.count)",
            "duplicates=\(snapshot.recentRuns.last?.duplicationCount ?? 0)",
            "tick=\(session.tick)",
            "causalSequence=\(causal.latestSequence)",
        ].joined(separator: " ")
        trace(message)
        return success(message)
    }

    private func cleanupPersistenceReconciliationProof(
        world: World
    ) -> PebbleAgentCommandResult {
        guard var staged = session, activeWorld === world else {
            return failure("No active PebbleAgents session.")
        }
        guard isPaused else {
            return failure("Pause the session before persistence cleanup.")
        }
        guard let record = staged.materialRightsSnapshot().records.first,
              case let .container(location) = record.lastVerifiedHolder.holder,
              let position = reconciliationContainerPosition(location),
              world.getBlock(position.x, position.y, position.z)
                == Int(cell(B.chest)),
              let container = world.getBlockEntity(
                  position.x, position.y, position.z
              ),
              container.type == "container",
              let physical = container.items?.compactMap({ $0 }),
              physical.filter({ $0.id == iid("iron_pickaxe") })
                .reduce(0, { $0 + $1.count }) == 1,
              physical.filter({ $0.id == iid("cobblestone") })
                .reduce(0, { $0 + $1.count }) == 3,
              physical.reduce(0, { $0 + $1.count }) == 4 else {
            return failure("Persistence cleanup refused: physical proof asset is not exact.")
        }
        container.items = Array(repeating: nil, count: container.items?.count ?? 27)
        _ = world.setBlock(position.x, position.y, position.z, 0)
        guard world.getBlock(position.x, position.y, position.z) == 0,
              world.getBlockEntity(position.x, position.y, position.z) == nil else {
            lastError = "persistence cleanup rollback verification failed"
            return failure(lastError!)
        }
        do {
            if staged.autonomousActivityEnabled {
                _ = try staged.selectAutonomousActivities([])
                try staged.setAutonomousActivityEnabled(false)
            }
            try staged.setPersistenceReconciliationEnabled(false)
            try staged.setMaterialRightsEnabled(false)
            session = staged
        } catch {
            lastError = "persistence cleanup state failure after exact World cleanup: \(error)"
            return failure(lastError!)
        }
        materialCustodyGateway.reset()
        let probesExact = staged.identitySnapshot().agentIDs.allSatisfy { id in
            probesByAgentId[id.rawValue].map { probe in
                !probe.dead && probe.world === world
                    && world.entities.filter { $0 === probe }.count == 1
            } == true
        }
        guard probesExact else {
            lastError = "persistence cleanup probe verification failed"
            return failure(lastError!)
        }
        let message = "persistence reconciliation cleanup world=exact "
            + "trackedAssetRemoved=1 untrackedItemsRemoved=3 "
            + "state=cleared probes=\(probesByAgentId.count) duplicates=0"
        trace(message)
        return success(message)
    }

    private func reconciliationProofContainerPosition(
        world: World
    ) -> PhysicalBlockPosition? {
        guard let anchor else { return nil }
        let offsets = [
            (5, 0), (5, 1), (5, -1), (-5, 0), (-5, 1), (-5, -1),
            (0, 5), (1, 5), (-1, 5), (0, -5), (1, -5), (-1, -5),
        ]
        let occupied = Set(probesByAgentId.values.map {
            PhysicalBlockPosition(
                x: Int(floor($0.x)), y: Int(floor($0.y)), z: Int(floor($0.z))
            )
        })
        for (dx, dz) in offsets {
            let x = anchor.x + dx
            let z = anchor.z + dz
            let verticalOffsets = [0, 1, -1, 2, -2, 3, -3]
            for dy in verticalOffsets {
                let y = anchor.y + dy
                let position = PhysicalBlockPosition(x: x, y: y, z: z)
                guard world.isChunkReady(x >> 4, z >> 4),
                      y > world.info.minY,
                      world.getBlock(x, y, z) == 0,
                      world.getBlock(x, y + 1, z) == 0,
                      world.getBlockEntity(x, y, z) == nil,
                      blockDefs[world.getBlock(x, y - 1, z) >> 4].solid,
                      !occupied.contains(position) else { continue }
                return position
            }
        }
        return nil
    }

    func reconciliationBinding(
        checkpoint: AgentSessionCheckpoint,
        session: AgentSimulationSession,
        world: World,
        store: PebbleAgentPersistenceStore
    ) throws -> AgentPersistenceReconciliationBinding? {
        guard session.persistenceReconciliationEnabled else { return nil }
        let rights = session.materialRightsSnapshot()
        guard rights.records.count
                <= AgentPersistenceReconciliationConfiguration.live
                    .maximumAssetReferences else {
            throw AgentPersistenceReconciliationError.assetReferenceMismatch
        }
        let civilizationHolders = session.identitySnapshot().agentIDs.map {
            AgentMaterialPhysicalHolder.agent($0)
        }
        let expectations = rights.records.map { record in
            let compatibleKnownHolders = rights.records.compactMap { other in
                other.asset.materialIdentity.itemKey
                    == record.asset.materialIdentity.itemKey
                    ? other.lastVerifiedHolder.holder : nil
            }
            return AgentPersistenceAssetExpectation(
                asset: record.asset,
                savedObservation: record.lastVerifiedHolder,
                candidateHolders: compatibleKnownHolders
                    + civilizationHolders
                    + [record.lastVerifiedHolder.holder]
            )
        }
        return AgentPersistenceReconciliationBinding(
            world: AgentPersistenceWorldIdentity(
                worldID: store.worldID,
                storageIdentity: store.storageIdentity,
                seed: world.seed,
                dimension: persistenceDimension
            ),
            checkpointID: checkpoint.checkpointID,
            simulationID: checkpoint.simulationID,
            checkpointTick: checkpoint.tick,
            causalSequence: session.causalLedgerSnapshot().summary.latestSequence,
            assets: expectations
        )
    }

    func reconciliationRequest(
        binding: AgentPersistenceReconciliationBinding,
        candidate: AgentSimulationSession,
        world: World,
        store: PebbleAgentPersistenceStore
    ) throws -> AgentPersistenceReconciliationRequest {
        let sets = try binding.assets.map { expectation in
            AgentPersistenceAssetObservationSet(
                assetID: expectation.asset.assetID,
                observations: try expectation.candidateHolders.flatMap { holder in
                    try reconciliationObservations(
                        expectation: expectation,
                        holder: holder,
                        tick: candidate.tick,
                        checkpointID: binding.checkpointID,
                        world: world
                    )
                }
            )
        }
        let allAssetsAvailable = sets.allSatisfy { !$0.observations.isEmpty }
        let resolutions = candidate.autonomousActivitySnapshot().activeActivities.map {
            activity in
            let targetReady = activity.candidate.target.map {
                world.isChunkReady($0.x >> 4, $0.z >> 4)
            } ?? true
            let actorPresent = probesByAgentId[activity.candidate.actorID.rawValue] != nil
            let valid = allAssetsAvailable && targetReady && actorPresent
            return AgentPersistenceActivityResolution(
                activityID: activity.activityID,
                actorID: activity.candidate.actorID,
                policy: valid ? .revalidateThenResume : .replan,
                reason: valid
                    ? "actor, target, physical references, and permissions revalidated"
                    : "restart invalidated an actor, target, or physical reference"
            )
        }
        return AgentPersistenceReconciliationRequest(
            runID: "restore:\(binding.checkpointID.rawValue)",
            binding: binding,
            restoredWorld: AgentPersistenceWorldIdentity(
                worldID: store.worldID,
                storageIdentity: store.storageIdentity,
                seed: world.seed,
                dimension: persistenceDimension
            ),
            observedWorldTick: world.time,
            assetObservations: sets,
            activityResolutions: resolutions
        )
    }

    private func reconciliationObservations(
        expectation: AgentPersistenceAssetExpectation,
        holder: AgentMaterialPhysicalHolder,
        tick: Int,
        checkpointID: AgentCheckpointID,
        world: World
    ) throws -> [AgentMaterialHolderObservation] {
        let endpoint: PebbleAgentMaterialCustodyEndpoint?
        switch holder {
        case let .agent(id):
            endpoint = probesByAgentId[id.rawValue].map {
                PebbleAgentMaterialCustodyEndpoint.liveAgent($0, in: world)
            }
        case let .container(location):
            endpoint = reconciliationContainerPosition(location).flatMap {
                world.getBlockEntity($0.x, $0.y, $0.z)
            }.map {
                PebbleAgentMaterialCustodyEndpoint.container($0, in: world)
            }
        }
        guard let endpoint, endpoint.isValid else { return [] }
        let custody = try materialCustodyGateway.inspect(endpoint)
        let compatible = custody.slots.compactMap { $0 }.filter {
            $0.identity.itemKey == expectation.asset.materialIdentity.itemKey
        }
        let total = compatible.reduce(0) { $0 + $1.count }
        guard total > 0 else { return [] }
        let fingerprint = try materialCustodyGateway.fingerprint(endpoint)
        if total == expectation.asset.quantity, let identity = compatible.first?.identity {
            return [AgentMaterialHolderObservation(
                holder: holder,
                materialIdentity: identity,
                quantity: total,
                custodyFingerprint: fingerprint,
                physicalReceiptID: String(
                    "restore:\(checkpointID.rawValue):\(holder.stableText)".prefix(256)
                ),
                observedAtTick: tick
            )]
        }
        // More compatible units than the bounded asset quantity are
        // deliberately reported as multiple same-holder observations. The
        // pure aggregate classifies this as ambiguous instead of guessing.
        return compatible.prefix(2).map { stack in
            AgentMaterialHolderObservation(
                holder: holder,
                materialIdentity: stack.identity,
                quantity: expectation.asset.quantity,
                custodyFingerprint: fingerprint,
                physicalReceiptID: String(
                    "restore:\(checkpointID.rawValue):\(holder.stableText):ambiguous"
                        .prefix(256)
                ),
                observedAtTick: tick
            )
        }
    }

    private func reconciliationContainerPosition(
        _ text: String
    ) -> PhysicalBlockPosition? {
        let normalized = text.hasPrefix("container:")
            ? String(text.dropFirst("container:".count)) : text
        let values = normalized.split(separator: ",").compactMap {
            Int($0.trimmingCharacters(in: .whitespaces))
        }
        guard values.count == 3 else { return nil }
        return PhysicalBlockPosition(x: values[0], y: values[1], z: values[2])
    }
}
