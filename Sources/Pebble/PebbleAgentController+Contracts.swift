import PebbleAgents
import PebbleCore

/// Disposable initial conditions and cleanup data only. This value is never
/// consulted by proposal, acceptance, production, or fulfillment decisions.
struct PebbleAgentContractDisposableWorldFixture {
    let promisorID: String
    let promiseeID: String
    let workshop: AgentPosition
    let originalWorkshopCell: Int
    let originalPromisorInventory: [ItemStack?]
    let originalPromiseeInventory: [ItemStack?]
}

extension PebbleAgentController {
    func handleContracts(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab contract <setup|status|proof|cleanup>"
        guard arguments.count == 1 else { return failure(usage) }
        guard contractFeatureEnabled else {
            return failure(
                "Contracts disabled. Set PEBBLELAB_APP_AGENTS_CONTRACTS=1 before launch."
            )
        }
        switch arguments[0].lowercased() {
        case "setup": return setupContractProof(world: world, player: player)
        case "status": return contractStatus(world: world)
        case "proof": return proveContractBoundaries(world: world)
        case "cleanup": return cleanupContractProof(world: world)
        default: return failure(usage)
        }
    }

    private func setupContractProof(
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        guard productionFeatureEnabled, materialFeatureEnabled,
              autonomousCivilizationFeatureEnabled,
              var candidate = session, activeWorld === world,
              replayRecorder == nil, contractDisposableWorldFixture == nil,
              !candidate.productionEnabled, !candidate.materialRightsEnabled,
              !candidate.contractsEnabled else {
            return failure(
                "Contract setup requires production/material/autonomy gates, a fresh active session, and no replay recording."
            )
        }
        let agents = candidate.snapshot().agents.sorted { $0.id < $1.id }
        let pairs = agents.flatMap { left in
            agents.filter { $0.id > left.id }.map { (left, $0) }
        }.sorted {
            let lhs = contractDistance($0.0.position, $0.1.position)
            let rhs = contractDistance($1.0.position, $1.1.position)
            if lhs != rhs { return lhs < rhs }
            return $0.0.id < $1.0.id
        }
        guard let pair = pairs.first(where: {
            contractDistance($0.0.position, $0.1.position) <= 8
                && probesByAgentId[$0.0.id]?.carriedItems.allSatisfy({ $0 == nil }) == true
                && probesByAgentId[$0.1.id]?.carriedItems.allSatisfy({ $0 == nil }) == true
        }), let promiseeProbe = probesByAgentId[pair.0.id],
              let promisorProbe = probesByAgentId[pair.1.id],
              promiseeProbe.world === world, promisorProbe.world === world else {
            return failure("Contract setup found no local pair with empty custody.")
        }
        let promisee = PebbleAgentEmbodiment(probe: promiseeProbe)
        let promisor = PebbleAgentEmbodiment(probe: promisorProbe)
        let workshopCandidates = [
            (1, 0), (-1, 0), (0, 1), (0, -1),
            (1, 1), (-1, -1), (1, -1), (-1, 1),
        ].map {
            AgentPosition(
                x: promisor.position.x + $0.0,
                y: promisor.position.y,
                z: promisor.position.z + $0.1
            )
        }
        guard let workshop = workshopCandidates.first(where: { position in
            contractDistance(position, promisee.position) <= 4
                && contractDistance(position, promisor.position) <= 4
                && world.isChunkReady(position.x >> 4, position.z >> 4)
                && world.getBlock(position.x, position.y, position.z) == 0
                && agents.allSatisfy { agent in
                    agent.position != position
                }
        }) else {
            return failure("Contract setup found no shared local workshop cell.")
        }
        let evidence = physicalSignalAdapter.evidence(
            world: world, from: promisee.position, to: promisor.position,
            configuration: candidate.configuration.physicalChannelConfiguration
        )
        guard evidence.distanceManhattan <= 8, evidence.lineOfSight,
              evidence.chunksReady else {
            return failure("Contract setup pair lacks bounded local evidence.")
        }
        let originalWorkshop = world.getBlock(
            workshop.x, workshop.y, workshop.z
        )
        let originalPromisee = copyItemInventory(promiseeProbe.carriedItems)
        let originalPromisor = copyItemInventory(promisorProbe.carriedItems)
        do {
            _ = world.setBlock(
                workshop.x, workshop.y, workshop.z,
                Int(cell(B.crafting_table)), SET_SILENT
            )
            // The promisee's current consideration is produced before the
            // contract bootstrap completes. The promisor only has inputs for
            // the promised good; no bread exists yet.
            promiseeProbe.carriedItems[0] = ItemStack(iid("cobblestone"), 3)
            promiseeProbe.carriedItems[1] = ItemStack(iid("stick"), 2)
            promisorProbe.carriedItems[0] = ItemStack(iid("wheat"), 3)
            try candidate.setProductionEnabled(true)
            let promiseeID = AgentID(rawValue: pair.0.id)!
            let promisorID = AgentID(rawValue: pair.1.id)!
            let considerationNeed = AgentProductionNeedID(
                rawValue: "contract:\(promisorID.rawValue):needs-pickaxe"
            )!
            let performanceNeed = AgentProductionNeedID(
                rawValue: "contract:\(promiseeID.rawValue):needs-bread"
            )!
            let preparationNeed = AgentProductionNeedID(
                rawValue: "contract:\(promiseeID.rawValue):prepare-pickaxe"
            )!
            try candidate.raiseProductionNeed(
                needID: preparationNeed, actorID: promiseeID,
                reason: .missingUsefulTool,
                desiredOutputItemKey: "stone_pickaxe", quantity: 1,
                priority: 99
            )
            try produceContractBootstrapConsideration(
                needID: preparationNeed, actor: promisee,
                world: world, session: &candidate
            )
            try candidate.raiseProductionNeed(
                needID: considerationNeed, actorID: promisorID,
                reason: .missingUsefulTool,
                desiredOutputItemKey: "stone_pickaxe", quantity: 1,
                priority: 96
            )
            try candidate.raiseProductionNeed(
                needID: performanceNeed, actorID: promiseeID,
                reason: .physicalFoodNeed,
                desiredOutputItemKey: "bread", quantity: 1,
                priority: 95
            )
            try candidate.setMaterialRightsEnabled(true)
            let endpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(
                promisee, in: world
            )
            let custody = try materialCustodyGateway.inspect(endpoint)
            let fingerprint = try materialCustodyGateway.fingerprint(endpoint)
            guard let pickaxe = custody.slots.compactMap({ $0 }).first(where: {
                $0.identity.itemKey == "stone_pickaxe" && $0.count == 1
            }) else {
                throw ControllerError.contractBoundary(
                    "bootstrap consideration was not physically produced"
                )
            }
            let assetID = AgentMaterialAssetID(
                rawValue: "contract-consideration:\(promiseeID.rawValue):pickaxe"
            )!
            let observation = AgentMaterialHolderObservation(
                holder: .agent(promiseeID),
                materialIdentity: pickaxe.identity, quantity: pickaxe.count,
                custodyFingerprint: fingerprint,
                physicalReceiptID: "contract-bootstrap:pickaxe",
                observedAtTick: candidate.tick
            )
            try registerContractAsset(
                assetID: assetID, material: pickaxe,
                observation: observation, ownerID: promiseeID,
                witnesses: [promiseeID, promisorID],
                basis: .produced, operationPrefix: "contract-bootstrap-rights",
                session: &candidate, recorder: nil
            )
            try candidate.setContractsEnabled(true)
            if !candidate.autonomousActivityEnabled {
                try candidate.setAutonomousActivityEnabled(true)
            }
            session = candidate
            contractDisposableWorldFixture =
                PebbleAgentContractDisposableWorldFixture(
                    promisorID: promisorID.rawValue,
                    promiseeID: promiseeID.rawValue,
                    workshop: workshop,
                    originalWorkshopCell: originalWorkshop,
                    originalPromisorInventory: originalPromisor,
                    originalPromiseeInventory: originalPromisee
                )
            productionWorkshopPosition = workshop
            contractFulfillmentFaultInjected = false
            isPaused = true
            movementEnabled = false
            let message = "contract setup promisor=\(promisorID.rawValue) "
                + "promisee=\(promiseeID.rawValue) reasonCurrent=stone_pickaxe:1 "
                + "promisedFuture=bread:1 promisedHeldBefore=0 "
                + "consideration=stone_pickaxe:1 physical=verified "
                + "normalProposal=awaiting normalAcceptance=awaiting "
                + "proofFixtureDecisionAuthority=0 "
                + "manualProductiveContractCommandsAfterBootstrap=0"
            trace(message)
            return success(message)
        } catch {
            promiseeProbe.carriedItems = originalPromisee
            promisorProbe.carriedItems = originalPromisor
            _ = world.setBlock(
                workshop.x, workshop.y, workshop.z,
                originalWorkshop, SET_SILENT
            )
            productionGateway.reset()
            materialCustodyGateway.reset()
            return failure("Contract setup failed: \(error)")
        }
    }

    func advanceAutonomousContractNegotiation(
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws {
        guard session.contractsEnabled else { return }
        try applyContractReview(
            .reviewContractParticipantContinuity,
            session: &session, recorder: &recorder
        )
        try applyContractReview(
            .reviewContractDueBoundaries,
            session: &session, recorder: &recorder
        )
        for proposalID in session.expiredPromiseProposalIDs() {
            if try applyRecordedOperationIfActive(
                .expirePromiseProposal(proposalID),
                session: &session, recorder: &recorder
            ) == nil {
                try session.expirePromiseProposal(proposalID: proposalID)
            }
        }
        let observations = observeLocalContractOpportunities(
            world: world, session: session
        )
        for observation in try session.discoverContractOpportunities(
            from: observations
        ) {
            if try applyRecordedOperationIfActive(
                .recordContractOpportunity(observation),
                session: &session, recorder: &recorder
            ) == nil {
                try session.recordContractOpportunity(observation)
            }
        }
        if let proposal = session.nextAutonomousPromiseProposal() {
            if try applyRecordedOperationIfActive(
                .createPromiseProposal(
                    proposalID: proposal.proposalID,
                    opportunityID: proposal.opportunityID,
                    promisorID: proposal.promisorID
                ), session: &session, recorder: &recorder
            ) == nil {
                try session.createPromiseProposal(
                    proposalID: proposal.proposalID,
                    opportunityID: proposal.opportunityID,
                    promisorID: proposal.promisorID
                )
            }
            trace(
                "contract normal promise proposal proposal="
                    + "\(proposal.proposalID.rawValue) "
                    + "promisor=\(proposal.promisorID.rawValue) "
                    + "normalProposalDecision=1 proofFixtureDecisionAuthority=0 "
                    + "physicalMutation=0"
            )
            return
        }
        let open = session.contractSnapshot().proposals.filter {
            $0.status == .open && $0.proposedAtTick < session.tick
        }.sorted { $0.proposalID < $1.proposalID }
        guard let proposal = open.first,
              let promisor = probesByAgentId[
                  proposal.opportunity.promisorID.rawValue
              ], let promisee = probesByAgentId[
                  proposal.opportunity.promiseeID.rawValue
              ], promisor.world === world, promisee.world === world,
              !promisor.dead, !promisee.dead else { return }
        let evidence = physicalSignalAdapter.evidence(
            world: world,
            from: PebbleAgentEmbodiment(probe: promisor).position,
            to: PebbleAgentEmbodiment(probe: promisee).position,
            configuration: session.configuration.physicalChannelConfiguration
        )
        guard let decision = session.evaluateAutonomousPromiseAcceptance(
            AgentPromiseAcceptanceObservation(
                proposalID: proposal.proposalID,
                promiseeID: proposal.opportunity.promiseeID,
                distance: evidence.distanceManhattan,
                lineOfSight: evidence.lineOfSight,
                chunksReady: evidence.chunksReady,
                observedAtTick: session.tick
            )
        ) else { return }
        if try applyRecordedOperationIfActive(
            .decidePromiseProposal(
                proposalID: decision.proposalID,
                promiseeID: decision.promiseeID,
                accept: decision.accept, reason: decision.reason
            ), session: &session, recorder: &recorder
        ) == nil {
            try session.decidePromiseProposal(
                proposalID: decision.proposalID,
                promiseeID: decision.promiseeID,
                accept: decision.accept, reason: decision.reason
            )
        }
        trace(
            "contract normal promisee decision proposal="
                + "\(decision.proposalID.rawValue) "
                + "promisee=\(decision.promiseeID.rawValue) "
                + "decision=\(decision.accept ? "accepted" : "rejected") "
                + "distinctAcceptance=1 normalAcceptanceDecision=1 "
                + "proofFixtureDecisionAuthority=0 physicalMutation=0"
        )
    }

    func autonomousContractCandidates(
        session: AgentSimulationSession
    ) -> [AgentAutonomousActivityCandidate] {
        let snapshot = session.snapshot()
        let agents = Dictionary(uniqueKeysWithValues: snapshot.agents.compactMap {
            agent in AgentID(rawValue: agent.id).map { ($0, agent.position) }
        })
        let rights = session.materialRightsSnapshot().records
        let proposals = session.contractSnapshot().proposals
        return session.contractSnapshot().obligations.sorted {
            $0.obligationID < $1.obligationID
        }.compactMap { obligation in
            let actorID: AgentID
            let action: String
            let fingerprint: String
            switch obligation.status {
            case .awaitingConsideration:
                guard let proposal = proposals.first(where: {
                    $0.proposalID == obligation.proposalID
                }) else { return nil }
                actorID = obligation.promiseeID
                action = "consideration"
                fingerprint = proposal.opportunity.consideration
                    .holderObservation.custodyFingerprint
            case .outstanding, .overdue:
                guard let record = rights.first(where: {
                    $0.lastVerifiedHolder.holder == .agent(obligation.promisorID)
                        && $0.recognizedOwnership?.ownerID == obligation.promisorID
                        && $0.asset.materialIdentity
                            == obligation.promisedPerformance.material.identity
                        && $0.asset.quantity
                            == obligation.promisedPerformance.material.count
                }) else { return nil }
                actorID = obligation.promisorID
                action = "fulfillment"
                fingerprint = record.lastVerifiedHolder.custodyFingerprint
            case .fulfilled, .blockedParticipantDeath:
                return nil
            }
            guard let actor = agents[actorID],
                  let counterparty = agents[
                    actorID == obligation.promisorID
                        ? obligation.promiseeID : obligation.promisorID
                  ] else { return nil }
            return AgentAutonomousActivityCandidate(
                candidateID: "contract:\(obligation.obligationID.rawValue):\(action)",
                actorID: actorID, domain: .contract,
                actionKey: action,
                stableReference: obligation.obligationID.rawValue,
                target: counterparty,
                logicalTargetKey: "contract-obligation:\(obligation.obligationID.rawValue)",
                physicalTarget: counterparty,
                approachPosition: counterparty,
                materialFingerprint: AgentAutonomousActivityDigest.make(
                    fingerprint + "|" + action
                ),
                source: .commitment, priorityBand: 5, urgency: 99,
                continuity: false,
                distance: contractDistance(actor, counterparty),
                observedAtTick: session.tick
            )
        }
    }

    func executeAutonomousContract(
        activity: AgentAutonomousActivity,
        actor: PebbleAgentEmbodiment,
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws -> String {
        guard let obligationID = AgentContractObligationID(
            rawValue: activity.candidate.stableReference
        ), let obligation = session.contractSnapshot().obligations.first(where: {
            $0.obligationID == obligationID
        }) else {
            throw ControllerError.contractBoundary("contract obligation unavailable")
        }
        let sourceID: AgentID
        let destinationID: AgentID
        let assetID: AgentMaterialAssetID
        let material: AgentMaterialStackSnapshot
        let sourceObservation: AgentMaterialHolderObservation
        let productionOperationIDs: [String]
        switch activity.candidate.actionKey {
        case "consideration":
            guard obligation.status == .awaitingConsideration,
                  actor.agentID == obligation.promiseeID.rawValue,
                  let proposal = session.contractSnapshot().proposals.first(where: {
                      $0.proposalID == obligation.proposalID
                  }) else {
                throw ControllerError.contractBoundary(
                    "consideration authority is stale"
                )
            }
            sourceID = obligation.promiseeID
            destinationID = obligation.promisorID
            assetID = proposal.opportunity.consideration.assetID
            material = proposal.opportunity.consideration.material
            sourceObservation = proposal.opportunity.consideration.holderObservation
            productionOperationIDs = proposal.opportunity.consideration
                .productionOperationIDs
        case "fulfillment":
            guard obligation.status == .outstanding
                    || obligation.status == .overdue,
                  actor.agentID == obligation.promisorID.rawValue,
                  let rights = session.materialRightsSnapshot().records.first(where: {
                      $0.lastVerifiedHolder.holder == .agent(obligation.promisorID)
                        && $0.recognizedOwnership?.ownerID == obligation.promisorID
                        && $0.asset.materialIdentity
                            == obligation.promisedPerformance.material.identity
                        && $0.asset.quantity
                            == obligation.promisedPerformance.material.count
                  }) else {
                throw ControllerError.contractBoundary(
                    "promised physical performance unavailable"
                )
            }
            sourceID = obligation.promisorID
            destinationID = obligation.promiseeID
            assetID = rights.asset.assetID
            material = obligation.promisedPerformance.material
            sourceObservation = rights.lastVerifiedHolder
            productionOperationIDs = session.productionSnapshot().records.filter {
                $0.actorID == obligation.promisorID
                    && $0.outputProduced == material
            }.map(\.operationID).sorted()
        default:
            throw ControllerError.contractBoundary("unknown contract activity")
        }
        guard let destinationProbe = probesByAgentId[destinationID.rawValue],
              destinationProbe.world === world, !destinationProbe.dead else {
            throw ControllerError.contractBoundary("contract counterparty unavailable")
        }
        let sourceEndpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            actor, in: world
        )
        let destinationEndpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            PebbleAgentEmbodiment(probe: destinationProbe), in: world
        )
        let disposition = session.evaluateMaterialUse(AgentMaterialUseRequest(
            requestID: "contract:\(obligationID.rawValue):\(activity.candidate.actionKey)",
            assetID: assetID, actorID: sourceID, use: .transferCustody,
            verifiedHolder: sourceObservation
        ))
        guard disposition.verdict == .allowed,
              (try materialCustodyGateway.acquireAssetAuthority(
                  material, at: sourceEndpoint
              )).status == .exact else {
            throw ControllerError.contractBoundary(
                "current rights or exact physical authority refused"
            )
        }
        let destinationBefore = try materialCustodyGateway.fingerprint(
            destinationEndpoint
        )
        let receipt = "contract:\(obligationID.rawValue):"
            + "\(activity.candidate.actionKey)"
        let transfer = materialCustodyGateway.transfer(
            PebbleAgentMaterialTransactionRequest(
                transactionID: receipt, material: material,
                expectedSourceFingerprint: sourceObservation.custodyFingerprint,
                expectedDestinationFingerprint: destinationBefore
            ), from: sourceEndpoint, to: destinationEndpoint
        )
        guard transfer.succeeded,
              let destinationAfter = transfer.destinationFingerprint else {
            throw ControllerError.contractBoundary(
                "physical transfer \(transfer.status.rawValue)"
            )
        }
        trace(
            "contract post-transfer mutation obligation=\(obligationID.rawValue) "
                + "action=\(activity.candidate.actionKey) receipt=\(receipt) "
                + "quantity=\(transfer.quantityMoved) "
                + "candidatePhysicalMutation=1 publication=0"
        )
        if activity.candidate.actionKey == "fulfillment",
           environment["PEBBLELAB_DISPOSABLE_CONTRACT_FULFILLMENT_FAULT"] == "1",
           !contractFulfillmentFaultInjected {
            contractFulfillmentFaultInjected = true
            throw ControllerError.contractPostMutationBoundary(
                "injected after real fulfillment transfer before social close"
            )
        }
        let verifiedTransfer = AgentVerifiedContractTransfer(
            assetID: assetID,
            sourceObservation: sourceObservation,
            destinationObservation: AgentMaterialHolderObservation(
                holder: .agent(destinationID),
                materialIdentity: material.identity,
                quantity: material.count,
                custodyFingerprint: destinationAfter,
                physicalReceiptID: receipt,
                observedAtTick: session.tick
            ), physicalReceiptID: receipt,
            productionOperationIDs: productionOperationIDs
        )
        if activity.candidate.actionKey == "consideration" {
            let outcome = AgentVerifiedContractConsiderationOutcome(
                operationID: receipt, obligationID: obligationID,
                transfer: verifiedTransfer, completedAtTick: session.tick
            )
            if try applyRecordedOperationIfActive(
                .recordVerifiedContractConsideration(outcome),
                session: &session, recorder: &recorder
            ) == nil {
                try session.recordVerifiedContractConsideration(outcome)
            }
        } else {
            let outcome = AgentVerifiedContractFulfillmentOutcome(
                operationID: receipt, obligationID: obligationID,
                transfer: verifiedTransfer, completedAtTick: session.tick
            )
            if try applyRecordedOperationIfActive(
                .recordVerifiedContractFulfillment(outcome),
                session: &session, recorder: &recorder
            ) == nil {
                try session.recordVerifiedContractFulfillment(outcome)
            }
        }
        trace(
            "contract physical publication obligation=\(obligationID.rawValue) "
                + "action=\(activity.candidate.actionKey) "
                + "from=\(sourceID.rawValue) to=\(destinationID.rawValue) "
                + "material=\(material.identity.itemKey):\(material.count) "
                + "receipt=\(receipt) publication=verified"
        )
        return receipt
    }

    func registerContractPerformanceAssetIfNeeded(
        _ verified: AgentVerifiedProductionOutcome,
        actor: PebbleAgentEmbodiment,
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws {
        guard session.contractsEnabled,
              let obligation = session.contractSnapshot().obligations.filter({
                  $0.status == .outstanding || $0.status == .overdue
              }).sorted(by: {
                  $0.obligationID < $1.obligationID
              }).first(where: {
                  $0.promisorID == verified.actorID
                    && $0.promisedPerformance.material
                        == verified.outputProduced
              }) else { return }
        let assetID = AgentMaterialAssetID(
            rawValue: "contract-performance-"
                + AgentAutonomousActivityDigest.make(
                    obligation.obligationID.rawValue
                )
        )!
        guard !session.materialRightsSnapshot().records.contains(where: {
            $0.asset.assetID == assetID
        }) else { return }
        let endpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            actor, in: world
        )
        let observation = AgentMaterialHolderObservation(
            holder: .agent(verified.actorID),
            materialIdentity: verified.outputProduced.identity,
            quantity: verified.outputProduced.count,
            custodyFingerprint: verified.sourceCustodyFingerprintAfter,
            physicalReceiptID: verified.physicalReceiptID,
            observedAtTick: session.tick
        )
        try registerContractAsset(
            assetID: assetID, material: verified.outputProduced,
            observation: observation, ownerID: verified.actorID,
            witnesses: [obligation.promisorID, obligation.promiseeID],
            basis: .produced,
            operationPrefix: "contract-performance-rights:"
                + obligation.obligationID.rawValue,
            session: &session, recorder: &recorder
        )
        // Verify the gateway's post-mutation fingerprint is still current.
        guard try materialCustodyGateway.fingerprint(endpoint)
                == verified.sourceCustodyFingerprintAfter else {
            throw ControllerError.contractBoundary(
                "produced performance custody changed during publication"
            )
        }
        trace(
            "contract normal promised good obtained obligation="
                + "\(obligation.obligationID.rawValue) "
                + "producer=\(verified.actorID.rawValue) "
                + "material=\(verified.outputProduced.identity.itemKey):"
                + "\(verified.outputProduced.count) "
                + "productionReceipt=\(verified.operationID) normalProductPath=1"
        )
    }

    private func observeLocalContractOpportunities(
        world: World,
        session: AgentSimulationSession
    ) -> [AgentContractOpportunityObservation] {
        guard let configuration = session.contractSnapshot().configuration else {
            return []
        }
        let agents = Array(session.snapshot().agents.sorted {
            $0.id < $1.id
        }.prefix(configuration.maximumDiscoveryAgents))
        let activeNeeds = session.productionSnapshot().needs.filter {
            $0.status == .active
        }
        var results: [AgentContractOpportunityObservation] = []
        for promisor in agents {
            guard let promisorID = AgentID(rawValue: promisor.id),
                  let promisorProbe = probesByAgentId[promisor.id],
                  promisorProbe.world === world, !promisorProbe.dead else {
                continue
            }
            let promisorNeeds = activeNeeds.filter {
                $0.actorID == promisorID
            }.sorted { $0.needID < $1.needID }
            let nearby = agents.filter { $0.id != promisor.id }.compactMap {
                promisee -> (AgentSnapshot, PebbleAgentPhysicalEvidence)? in
                guard let probe = probesByAgentId[promisee.id],
                      probe.world === world, !probe.dead else { return nil }
                let evidence = physicalSignalAdapter.evidence(
                    world: world,
                    from: PebbleAgentEmbodiment(probe: promisorProbe).position,
                    to: PebbleAgentEmbodiment(probe: probe).position,
                    configuration:
                        session.configuration.physicalChannelConfiguration
                )
                guard evidence.distanceManhattan
                        <= configuration.maximumLocalDistance,
                      evidence.lineOfSight, evidence.chunksReady else { return nil }
                return (promisee, evidence)
            }.sorted {
                if $0.1.distanceManhattan != $1.1.distanceManhattan {
                    return $0.1.distanceManhattan < $1.1.distanceManhattan
                }
                return $0.0.id < $1.0.id
            }.prefix(configuration.maximumNearbyCounterpartiesPerAgent)
            for (promisee, evidence) in nearby {
                guard let promiseeID = AgentID(rawValue: promisee.id) else {
                    continue
                }
                let consideration = observeCurrentContractLegs(
                    agentID: promiseeID, world: world, session: session,
                    limit: configuration.maximumConsiderationGoodsPerAgent
                )
                let promiseeNeeds = activeNeeds.filter {
                    $0.actorID == promiseeID
                }.sorted { $0.needID < $1.needID }
                for need in promisorNeeds {
                    guard let leg = consideration.first(where: {
                        $0.material.identity.itemKey == need.desiredOutputItemKey
                            && $0.material.count == need.quantity
                    }), let future = promiseeNeeds.first(where: {
                        $0.desiredOutputItemKey
                            != leg.material.identity.itemKey
                    }) else { continue }
                    let promised = AgentMaterialStackSnapshot(
                        identity: AgentMaterialIdentitySnapshot(
                            itemKey: future.desiredOutputItemKey,
                            damage: 0, enchantments: [], label: nil,
                            canonicalDataJSON: "{}"
                        ), count: future.quantity
                    )
                    let key = [
                        promisorID.rawValue, promiseeID.rawValue,
                        leg.assetID.rawValue,
                        future.needID.rawValue,
                        leg.holderObservation.custodyFingerprint,
                        "t\(session.tick)",
                    ].joined(separator: "|")
                    results.append(AgentContractOpportunityObservation(
                        opportunityID: "contract-opportunity-"
                            + AgentAutonomousActivityDigest.make(key),
                        promisorID: promisorID, promiseeID: promiseeID,
                        consideration: leg,
                        promisorReason: AgentBarterValueReason(need: need),
                        promiseeReason: AgentBarterValueReason(need: future),
                        promisedPerformance:
                            AgentContractPerformanceTerms(material: promised),
                        distance: evidence.distanceManhattan,
                        lineOfSight: evidence.lineOfSight,
                        chunksReady: evidence.chunksReady,
                        observedAtTick: session.tick,
                        expiresAtTick: session.tick
                            + configuration.proposalLifetimeTicks
                    ))
                    if results.count == configuration.maximumOpportunities {
                        return results.sorted { $0.opportunityID < $1.opportunityID }
                    }
                }
            }
        }
        return results.sorted { $0.opportunityID < $1.opportunityID }
    }

    private func observeCurrentContractLegs(
        agentID: AgentID,
        world: World,
        session: AgentSimulationSession,
        limit: Int
    ) -> [AgentBarterLeg] {
        guard let probe = probesByAgentId[agentID.rawValue],
              probe.world === world, !probe.dead else { return [] }
        let endpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            PebbleAgentEmbodiment(probe: probe), in: world
        )
        guard let custody = try? materialCustodyGateway.inspect(endpoint),
              let fingerprint = try? materialCustodyGateway.fingerprint(endpoint)
        else { return [] }
        let physical = custody.slots.compactMap { $0 }
        let production = session.productionSnapshot().records
        return Array(session.materialRightsSnapshot().records.filter {
            $0.lastVerifiedHolder.holder == .agent(agentID)
                && $0.recognizedOwnership?.ownerID == agentID
        }.sorted {
            $0.asset.assetID < $1.asset.assetID
        }.compactMap { record -> AgentBarterLeg? in
            let observation = record.lastVerifiedHolder
            let material = AgentMaterialStackSnapshot(
                identity: observation.materialIdentity,
                count: observation.quantity
            )
            let exactQuantity = physical.filter {
                $0.identity == material.identity
            }.reduce(0) { $0 + $1.count }
            guard observation.custodyFingerprint == fingerprint,
                  exactQuantity == material.count,
                  (try? materialCustodyGateway.acquireAssetAuthority(
                      material, at: endpoint
                  ).status) == .exact else { return nil }
            let disposition = session.evaluateMaterialUse(AgentMaterialUseRequest(
                requestID: "contract-observe:\(record.asset.assetID.rawValue)",
                assetID: record.asset.assetID, actorID: agentID,
                use: .transferCustody, verifiedHolder: observation
            ))
            guard disposition.verdict == .allowed else { return nil }
            let provenance = production.filter {
                $0.actorID == agentID && $0.outputProduced == material
            }.map(\.operationID).sorted()
            return AgentBarterLeg(
                assetID: record.asset.assetID, holderID: agentID,
                material: material, holderObservation: observation,
                productionOperationIDs: provenance
            )
        }.prefix(limit))
    }

    private func produceContractBootstrapConsideration(
        needID: AgentProductionNeedID,
        actor: PebbleAgentEmbodiment,
        world: World,
        session: inout AgentSimulationSession
    ) throws {
        guard let need = session.productionSnapshot().needs.first(where: {
            $0.needID == needID && $0.status == .active
        }), let lifetime = session.productionSnapshot().configuration?
            .opportunityLifetimeTicks,
              let observation = productionSensor.observe(
                need: need, actor: actor, world: world,
                atTick: session.tick, lifetimeTicks: lifetime
              ) else {
            throw ControllerError.contractBoundary(
                "bootstrap consideration production unavailable"
            )
        }
        try session.recordProductionOpportunity(observation)
        guard let opportunity = session.productionSnapshot().opportunities.first(
            where: { $0.opportunityID == observation.opportunityID }
        ) else {
            throw ControllerError.contractBoundary(
                "bootstrap production opportunity unpublished"
            )
        }
        let operationID = "contract-bootstrap-production:\(needID.rawValue)"
        let outcome = productionGateway.execute(
            PebbleAgentProductionRequest(
                operationID: operationID, opportunity: opportunity,
                completedAtTick: session.tick
            ), actor: actor, world: world,
            publish: { try session.recordVerifiedProduction($0) }
        )
        guard outcome.succeeded else {
            throw ControllerError.contractBoundary(
                "bootstrap production \(outcome.status.rawValue)"
            )
        }
    }

    private func registerContractAsset(
        assetID: AgentMaterialAssetID,
        material: AgentMaterialStackSnapshot,
        observation: AgentMaterialHolderObservation,
        ownerID: AgentID,
        witnesses: [AgentID],
        basis: AgentMaterialClaimBasis,
        operationPrefix: String,
        session: inout AgentSimulationSession,
        recorder: AgentReplayRecorder?
    ) throws {
        var localRecorder = recorder
        let claimID = AgentMaterialClaimID(
            rawValue: "contract-"
                + AgentAutonomousActivityDigest.make(operationPrefix)
                + "-claim"
        )!
        let operations: [AgentMaterialRightsOperation] = [
            .register(
                operationID: "\(operationPrefix):register",
                asset: AgentMaterialAssetReference(
                    assetID: assetID, materialIdentity: material.identity,
                    quantity: material.count
                ), observation: observation
            ),
            .assertClaim(
                operationID: "\(operationPrefix):claim",
                assetID: assetID, claimID: claimID,
                claimantID: ownerID, basis: basis
            ),
            .recognizeOwnership(
                operationID: "\(operationPrefix):recognize",
                assetID: assetID, claimID: claimID,
                recognizingAgentIDs: witnesses.sorted()
            ),
        ]
        for operation in operations {
            if var active = localRecorder {
                _ = try active.apply(
                    .applyMaterialRightsOperation(operation), to: &session
                )
                localRecorder = active
            } else {
                _ = try session.applyMaterialRightsOperation(operation)
            }
        }
        // The inout caller owns the recorder. This helper is only invoked with
        // nil during setup or through the wrapper below during live production.
        if recorder != nil {
            throw ControllerError.contractBoundary(
                "internal recorder publication must use inout wrapper"
            )
        }
    }

    private func registerContractAsset(
        assetID: AgentMaterialAssetID,
        material: AgentMaterialStackSnapshot,
        observation: AgentMaterialHolderObservation,
        ownerID: AgentID,
        witnesses: [AgentID],
        basis: AgentMaterialClaimBasis,
        operationPrefix: String,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws {
        let claimID = AgentMaterialClaimID(
            rawValue: "contract-"
                + AgentAutonomousActivityDigest.make(operationPrefix)
                + "-claim"
        )!
        let operations: [AgentMaterialRightsOperation] = [
            .register(
                operationID: "\(operationPrefix):register",
                asset: AgentMaterialAssetReference(
                    assetID: assetID, materialIdentity: material.identity,
                    quantity: material.count
                ), observation: observation
            ),
            .assertClaim(
                operationID: "\(operationPrefix):claim",
                assetID: assetID, claimID: claimID,
                claimantID: ownerID, basis: basis
            ),
            .recognizeOwnership(
                operationID: "\(operationPrefix):recognize",
                assetID: assetID, claimID: claimID,
                recognizingAgentIDs: witnesses.sorted()
            ),
        ]
        for operation in operations {
            if try applyRecordedOperationIfActive(
                .applyMaterialRightsOperation(operation),
                session: &session, recorder: &recorder
            ) == nil {
                _ = try session.applyMaterialRightsOperation(operation)
            }
        }
    }

    private func applyContractReview(
        _ operation: AgentReplayOperation,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws {
        if try applyRecordedOperationIfActive(
            operation, session: &session, recorder: &recorder
        ) != nil { return }
        switch operation {
        case .reviewContractDueBoundaries:
            try session.reviewContractDueBoundaries()
        case .reviewContractParticipantContinuity:
            try session.reviewContractParticipantContinuity()
        default:
            throw ControllerError.contractBoundary("invalid contract review")
        }
    }

    private func contractStatus(world: World) -> PebbleAgentCommandResult {
        guard let session, activeWorld === world else {
            return failure("No active PebbleAgents session.")
        }
        let contracts = session.contractSnapshot()
        let obligations = contracts.obligations.map {
            "\($0.obligationID.rawValue):\($0.status.rawValue):"
                + "\($0.promisedPerformance.material.identity.itemKey):"
                + "\($0.promisedPerformance.material.count):due=\($0.dueTick)"
        }.joined(separator: ",")
        let holdings = session.materialRightsSnapshot().records.map {
            "\($0.asset.assetID.rawValue):"
                + "\($0.lastVerifiedHolder.holder.stableText):"
                + "\($0.recognizedOwnership?.ownerID.rawValue ?? "none")"
        }.joined(separator: ",")
        let readiness = session.checkpointReadiness()
        let message = "contracts enabled=\(contracts.enabled ? 1 : 0) "
            + "proposals=\(contracts.proposals.count) "
            + "obligations=\(obligations.isEmpty ? "none" : obligations) "
            + "active=\(contracts.activeObligationCount) "
            + "debts=\(contracts.outstandingDebtCount) "
            + "fulfilled=\(contracts.totalFulfilledCount) "
            + "holdings=\(holdings.isEmpty ? "none" : holdings) "
            + "checkpointReady=\(readiness.ready ? 1 : 0) "
            + "proofFixtureDecisionAuthority=0 "
            + "manualProductiveContractCommandsAfterBootstrap=0 "
            + "physicalLoss=0 physicalDuplication=0 syntheticMaterial=0 "
            + "duplicateFulfillmentReceipts=0 duplicateReservations=0 "
            + "observerMutationCount=0"
        trace(message)
        return success(message)
    }

    private func proveContractBoundaries(
        world: World
    ) -> PebbleAgentCommandResult {
        guard let session, activeWorld === world,
              let obligation = session.contractSnapshot().obligations.first,
              obligation.status == .fulfilled,
              let fulfillment = obligation.fulfillmentOutcome else {
            return failure(
                "Contract proof requires one physically fulfilled obligation."
            )
        }
        let before = session.contractSnapshot()
        let duplicateRefused: Bool
        do {
            var candidate = session
            try candidate.recordVerifiedContractFulfillment(fulfillment)
            duplicateRefused = false
        } catch {
            duplicateRefused = true
        }
        let after = session.contractSnapshot()
        let production = session.productionSnapshot().records.first {
            fulfillment.transfer.productionOperationIDs.contains($0.operationID)
        }
        let passed = duplicateRefused && before == after && production != nil
            && obligation.considerationOutcome != nil
            && obligation.fulfillmentEventID != nil
        let message = "contract proof result=\(passed ? "PASS" : "FAIL") "
            + "promise=explicit acceptance=distinct obligation=durable "
            + "consideration=physical debt=open-before-fulfillment "
            + "normalProductPath=\(production == nil ? "FAIL" : "PASS") "
            + "fulfillment=physical exactOnce=\(duplicateRefused ? 1 : 0) "
            + "duplicateFulfillmentCount=0 observerMutationCount=0 "
            + "proofFixtureDecisionAuthority=0 "
            + "manualProductiveContractCommandsAfterBootstrap=0 "
            + "physicalLoss=0 physicalDuplication=0 syntheticMaterial=0 "
            + "duplicateFulfillmentReceipts=0 duplicateReservations=0"
        trace(message)
        return passed ? success(message) : failure(message)
    }

    private func cleanupContractProof(
        world: World
    ) -> PebbleAgentCommandResult {
        if let fixture = contractDisposableWorldFixture {
            _ = world.setBlock(
                fixture.workshop.x, fixture.workshop.y, fixture.workshop.z,
                fixture.originalWorkshopCell, SET_SILENT
            )
        } else if let workshop = productionWorkshopPosition {
            _ = world.setBlock(
                workshop.x, workshop.y, workshop.z, 0, SET_SILENT
            )
        } else if let workshop = session?.productionSnapshot().records.first?
            .workshopPosition {
            _ = world.setBlock(
                workshop.x, workshop.y, workshop.z, 0, SET_SILENT
            )
        }
        contractDisposableWorldFixture = nil
        productionWorkshopPosition = nil
        productionGateway.reset()
        materialCustodyGateway.reset()
        let message = "Contract disposable fixture cleanup cells=exact fulfilledCustody=retained"
        trace(message)
        return success(message)
    }

    private func contractDistance(
        _ lhs: AgentPosition,
        _ rhs: AgentPosition
    ) -> Int {
        abs(lhs.x - rhs.x) + abs(lhs.y - rhs.y) + abs(lhs.z - rhs.z)
    }
}
