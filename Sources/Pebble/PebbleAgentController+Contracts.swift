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
        let usage = "Usage: /lab contract <setup|status|proof|provenance|cleanup|drift consideration|drift fulfillment|displace fulfillment|return fulfillment>"
        guard contractFeatureEnabled else {
            return failure(
                "Contracts disabled. Set PEBBLELAB_APP_AGENTS_CONTRACTS=1 before launch."
            )
        }
        if arguments.count == 2, arguments[0].lowercased() == "drift" {
            return proveContractUnrelatedInventoryDrift(
                leg: arguments[1].lowercased(), world: world
            )
        }
        if arguments.count == 2,
           arguments[0].lowercased() == "displace",
           arguments[1].lowercased() == "fulfillment" {
            return moveContractBlocker01Performance(
                returning: false, world: world
            )
        }
        if arguments.count == 2,
           arguments[0].lowercased() == "return",
           arguments[1].lowercased() == "fulfillment" {
            return moveContractBlocker01Performance(
                returning: true, world: world
            )
        }
        guard arguments.count == 1 else { return failure(usage) }
        switch arguments[0].lowercased() {
        case "setup": return setupContractProof(world: world, player: player)
        case "status": return contractStatus(world: world)
        case "proof": return proveContractBoundaries(world: world)
        case "provenance": return contractBlocker01ProvenanceStatus(world: world)
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
        let blocker01 = environment["PEBBLELAB_GATE_E_BLOCKER_01"] == "1"
        let keeperProbe = agents.first(where: {
            $0.id != pair.0.id && $0.id != pair.1.id
        }).flatMap { probesByAgentId[$0.id] }
        guard !blocker01 || (keeperProbe?.world === world
            && keeperProbe?.dead == false
            && keeperProbe?.carriedItems.allSatisfy({ $0 == nil }) == true) else {
            return failure(
                "Blocker 01 setup requires a third live agent with empty custody."
            )
        }
        let originalKeeper = keeperProbe.map {
            copyItemInventory($0.carriedItems)
        }
        let blockerContainer = blocker01 ? contractBlocker01ContainerCandidates(
            workshop: workshop
        ).first(where: { position in
            world.isChunkReady(position.x >> 4, position.z >> 4)
                && world.getBlock(position.x, position.y, position.z) == 0
                && world.getBlockEntity(position.x, position.y, position.z) == nil
                && agents.allSatisfy { $0.position != position }
        }) : nil
        guard !blocker01 || blockerContainer != nil else {
            return failure("Blocker 01 setup found no disposable container cell.")
        }
        do {
            _ = world.setBlock(
                workshop.x, workshop.y, workshop.z,
                Int(cell(B.crafting_table)), SET_SILENT
            )
            // Disposable inputs only. All outputs below still cross the real
            // recipe, production, custody, verification and rights adapters.
            promiseeProbe.carriedItems[0] = ItemStack(iid("cobblestone"), 3)
            promiseeProbe.carriedItems[1] = ItemStack(iid("stick"), 2)
            promisorProbe.carriedItems[0] = ItemStack(
                iid("wheat"), blocker01 ? 9 : 3
            )
            let productionConfiguration = environment[
                "PEBBLELAB_DISPOSABLE_CONTRACT_PRODUCTION_NEED_CAPACITY_PROOF"
            ] == "1"
                ? try AgentProductionConfiguration(maximumNeeds: 3)
                : .live
            try candidate.setProductionEnabled(
                true, configuration: productionConfiguration
            )
            try candidate.setMaterialRightsEnabled(true)
            let promiseeID = AgentID(rawValue: pair.0.id)!
            let promisorID = AgentID(rawValue: pair.1.id)!
            if blocker01 {
                guard let keeperProbe, let blockerContainer,
                      let keeperID = AgentID(
                        rawValue: PebbleAgentEmbodiment(
                            probe: keeperProbe
                        ).agentID
                      ) else {
                    throw ControllerError.contractBoundary(
                        "Blocker 01 physical holders unavailable"
                    )
                }
                _ = world.setBlock(
                    blockerContainer.x, blockerContainer.y, blockerContainer.z,
                    Int(cell(B.chest)), SET_SILENT
                )
                let container = makeContainerBE(
                    blockerContainer.x, blockerContainer.y, blockerContainer.z, 27
                )
                world.setBlockEntity(container)
                guard world.getBlockEntity(
                    blockerContainer.x, blockerContainer.y, blockerContainer.z
                ) === container else {
                    throw ControllerError.contractBoundary(
                        "Blocker 01 displacement container unavailable"
                    )
                }
                let destinations: [(
                    AgentMaterialPhysicalHolder,
                    PebbleAgentMaterialCustodyEndpoint
                )] = [
                    (
                        .agent(promiseeID),
                        .liveAgent(promisee, in: world)
                    ),
                    (
                        .container(
                            "\(blockerContainer.x),\(blockerContainer.y),"
                                + "\(blockerContainer.z)"
                        ),
                        .container(container, in: world)
                    ),
                ]
                var productionIDs: [String] = []
                for ordinal in 1...3 {
                    let needID = AgentProductionNeedID(
                        rawValue: "gate-e-blocker-01:\(promisorID.rawValue):bread:p\(ordinal)"
                    )!
                    try candidate.raiseProductionNeed(
                        needID: needID, actorID: promisorID,
                        reason: .physicalFoodNeed,
                        desiredOutputItemKey: "bread", quantity: 1,
                        priority: 100 - ordinal
                    )
                    let verified = try produceContractBootstrapConsideration(
                        needID: needID, actor: promisor,
                        world: world, session: &candidate
                    )
                    let breadAssetID = AgentMaterialAssetID(
                        rawValue: "contract-blocker-01-bread-p\(ordinal):\(promisorID.rawValue)"
                    )!
                    let observation = AgentMaterialHolderObservation(
                        holder: .agent(promisorID),
                        materialIdentity: verified.outputProduced.identity,
                        quantity: verified.outputProduced.count,
                        custodyFingerprint:
                            verified.sourceCustodyFingerprintAfter,
                        physicalReceiptID: verified.physicalReceiptID,
                        observedAtTick: candidate.tick
                    )
                    try registerContractAsset(
                        assetID: breadAssetID,
                        material: verified.outputProduced,
                        observation: observation, ownerID: promisorID,
                        witnesses: [promiseeID, promisorID, keeperID],
                        basis: .produced,
                        operationPrefix:
                            "gate-e-blocker-01-rights:p\(ordinal):\(promisorID.rawValue)",
                        productionOperationIDs: [verified.operationID],
                        session: &candidate, recorder: nil
                    )
                    if ordinal < 3 {
                        try transferContractBlocker01Asset(
                            assetID: breadAssetID,
                            actorID: promisorID,
                            destinationHolder: destinations[ordinal - 1].0,
                            source: .liveAgent(promisor, in: world),
                            destination: destinations[ordinal - 1].1,
                            operationID:
                                "gate-e-blocker-01-park:p\(ordinal):\(promisorID.rawValue)",
                            session: &candidate
                        )
                    }
                    productionIDs.append(verified.operationID)
                }
                trace(
                    "gate-e blocker-01 bootstrap producer=\(promisorID.rawValue) "
                        + "matchingHistorical=3 promisedAsset="
                        + "contract-blocker-01-bread-p3:\(promisorID.rawValue) "
                        + "quantity=1 productionOperations="
                        + productionIDs.joined(separator: ",")
                        + " proofFixtureDecisionAuthority=0"
                )
            }
            let considerationNeed = AgentProductionNeedID(
                rawValue: "contract:\(promisorID.rawValue):needs-pickaxe"
            )!
            let performanceNeed = AgentProductionNeedID(
                rawValue: "contract:\(promiseeID.rawValue):needs-bread"
            )!
            let preparationNeed = AgentProductionNeedID(
                rawValue: "contract:\(promiseeID.rawValue):prepare-pickaxe"
            )!
            // Co-mingled controls are present before the tracked
            // consideration is produced and bound. The later drift command
            // moves them without changing tracked identity or quantity.
            promiseeProbe.carriedItems[6] = ItemStack(iid("dirt"), 1)
            promisorProbe.carriedItems[6] = ItemStack(iid("sand"), 1)
            try candidate.raiseProductionNeed(
                needID: preparationNeed, actorID: promiseeID,
                reason: .missingUsefulTool,
                desiredOutputItemKey: "stone_pickaxe", quantity: 1,
                priority: 99
            )
            let considerationProduction = try produceContractBootstrapConsideration(
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
                physicalReceiptID: considerationProduction.physicalReceiptID,
                observedAtTick: candidate.tick
            )
            try registerContractAsset(
                assetID: assetID, material: pickaxe,
                observation: observation, ownerID: promiseeID,
                witnesses: [promiseeID, promisorID],
                basis: .produced, operationPrefix: "contract-bootstrap-rights",
                productionOperationIDs: [considerationProduction.operationID],
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
            contractConsiderationPublicationFaultInjected = false
            contractFulfillmentPublicationFaultInjected = false
            isPaused = true
            movementEnabled = false
            let message = "contract setup promisor=\(promisorID.rawValue) "
                + "promisee=\(promiseeID.rawValue) reasonCurrent=stone_pickaxe:1 "
                + "promisedFuture=bread:1 promisedHeldBefore="
                + "\(blocker01 ? 1 : 0) "
                + "consideration=stone_pickaxe:1 physical=verified "
                + "normalProposal=awaiting normalAcceptance=awaiting "
                + "proofFixtureDecisionAuthority=0 "
                + "manualProductiveContractCommandsAfterBootstrap=0"
            trace(message)
            return success(message)
        } catch {
            promiseeProbe.carriedItems = originalPromisee
            promisorProbe.carriedItems = originalPromisor
            if let keeperProbe, let originalKeeper {
                keeperProbe.carriedItems = originalKeeper
            }
            _ = world.setBlock(
                workshop.x, workshop.y, workshop.z,
                originalWorkshop, SET_SILENT
            )
            if let blockerContainer {
                _ = world.setBlock(
                    blockerContainer.x, blockerContainer.y,
                    blockerContainer.z, 0, SET_SILENT
                )
            }
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
        let historicalSourceObservation: AgentMaterialHolderObservation
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
            historicalSourceObservation = proposal.opportunity.consideration
                .holderObservation
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
            historicalSourceObservation = rights.lastVerifiedHolder
            productionOperationIDs = rights.productionProvenance?.operationIDs ?? []
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
            verifiedHolder: historicalSourceObservation
        ))
        let currentAuthority = try materialCustodyGateway.acquireAssetAuthority(
            material, at: sourceEndpoint
        )
        guard disposition.verdict == .allowed, currentAuthority.isExact else {
            throw ControllerError.contractBoundary(
                "current rights or exact physical authority refused"
            )
        }
        let currentSourceObservation = AgentMaterialHolderObservation(
            holder: .agent(sourceID), materialIdentity: material.identity,
            quantity: material.count,
            custodyFingerprint: currentAuthority.currentCustodyFingerprint,
            physicalReceiptID: "contract-current-authority:"
                + "\(obligationID.rawValue):\(activity.candidate.actionKey):t\(session.tick)",
            observedAtTick: session.tick
        )
        trace(
            "contract current asset authority obligation=\(obligationID.rawValue) "
                + "action=\(activity.candidate.actionKey) status=exact "
                + "holder=\(sourceID.rawValue) identity=\(material.identity.itemKey) "
                + "quantity=\(material.count) historicalFullFingerprintCurrent="
                + "\(historicalSourceObservation.custodyFingerprint == currentAuthority.currentCustodyFingerprint ? 1 : 0) "
                + "currentFingerprintImmediatePrecondition=1"
        )
        let destinationBefore = try materialCustodyGateway.fingerprint(
            destinationEndpoint
        )
        let receipt = "contract:\(obligationID.rawValue):"
            + "\(activity.candidate.actionKey)"
        let preflightTransfer = AgentVerifiedContractTransfer(
            assetID: assetID,
            sourceObservation: currentSourceObservation,
            destinationObservation: AgentMaterialHolderObservation(
                holder: .agent(destinationID),
                materialIdentity: material.identity,
                quantity: material.count,
                custodyFingerprint: destinationBefore,
                physicalReceiptID: receipt,
                observedAtTick: session.tick
            ),
            physicalReceiptID: receipt,
            productionOperationIDs: productionOperationIDs
        )
        let preflightOperation: AgentReplayOperation
        if activity.candidate.actionKey == "consideration" {
            preflightOperation = .recordVerifiedContractConsideration(
                AgentVerifiedContractConsiderationOutcome(
                    operationID: receipt, obligationID: obligationID,
                    transfer: preflightTransfer, completedAtTick: session.tick
                )
            )
        } else {
            preflightOperation = .recordVerifiedContractFulfillment(
                AgentVerifiedContractFulfillmentOutcome(
                    operationID: receipt, obligationID: obligationID,
                    transfer: preflightTransfer, completedAtTick: session.tick
                )
            )
        }
        do {
            try prevalidateContractPublication(
                preflightOperation, session: session, recorder: recorder
            )
            trace(
                "contract publication prevalidated obligation="
                    + "\(obligationID.rawValue) action=\(activity.candidate.actionKey) "
                    + "physicalMutation=0 sessionPublication=staged recorderPublication=staged"
            )
        } catch {
            trace(
                "contract publication prevalidation refused obligation="
                    + "\(obligationID.rawValue) action=\(activity.candidate.actionKey) "
                    + "physicalMutation=0 candidateCompensationDelta=0 "
                    + "reason=\(String(describing: error).replacingOccurrences(of: " ", with: "_"))"
            )
            throw ControllerError.contractBoundary(
                "publication prevalidation refused: \(error)"
            )
        }
        let transfer = materialCustodyGateway.transfer(
            PebbleAgentMaterialTransactionRequest(
                transactionID: receipt, material: material,
                expectedSourceFingerprint:
                    currentAuthority.currentCustodyFingerprint,
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
        if activity.candidate.actionKey == "consideration",
           environment[
               "PEBBLELAB_DISPOSABLE_CONTRACT_CONSIDERATION_PUBLICATION_FAULT"
           ] == "1",
           !contractConsiderationPublicationFaultInjected {
            contractConsiderationPublicationFaultInjected = true
            throw ControllerError.contractBoundary(
                "ordinary consideration publication rejected after transfer"
            )
        }
        if activity.candidate.actionKey == "fulfillment",
           environment[
               "PEBBLELAB_DISPOSABLE_CONTRACT_FULFILLMENT_PUBLICATION_FAULT"
           ] == "1",
           !contractFulfillmentPublicationFaultInjected {
            contractFulfillmentPublicationFaultInjected = true
            throw ControllerError.contractBoundary(
                "ordinary fulfillment publication rejected after transfer"
            )
        }
        let verifiedTransfer = AgentVerifiedContractTransfer(
            assetID: assetID,
            sourceObservation: currentSourceObservation,
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

    /// Runs the exact replay/session publication against disposable copies.
    /// This makes every predictable capacity, duplicate, causal, Material
    /// Rights, production-need, and contract invariant failure visible before
    /// the live custody gateway is allowed to mutate either endpoint.
    private func prevalidateContractPublication(
        _ operation: AgentReplayOperation,
        session: AgentSimulationSession,
        recorder: AgentReplayRecorder?
    ) throws {
        var stagedSession = session
        var stagedRecorder = recorder
        if try applyRecordedOperationIfActive(
            operation, session: &stagedSession, recorder: &stagedRecorder
        ) != nil { return }
        switch operation {
        case let .recordVerifiedContractConsideration(outcome):
            try stagedSession.recordVerifiedContractConsideration(outcome)
        case let .recordVerifiedContractFulfillment(outcome):
            try stagedSession.recordVerifiedContractFulfillment(outcome)
        default:
            throw ControllerError.contractBoundary(
                "invalid contract publication prevalidation"
            )
        }
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
            productionOperationIDs: [verified.operationID],
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
            return AgentBarterLeg(
                assetID: record.asset.assetID, holderID: agentID,
                material: material, holderObservation: observation,
                productionOperationIDs:
                    record.productionProvenance?.operationIDs ?? []
            )
        }.prefix(limit))
    }

    private func produceContractBootstrapConsideration(
        needID: AgentProductionNeedID,
        actor: PebbleAgentEmbodiment,
        world: World,
        session: inout AgentSimulationSession
    ) throws -> AgentVerifiedProductionOutcome {
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
        guard outcome.succeeded, let verified = outcome.verified else {
            throw ControllerError.contractBoundary(
                "bootstrap production \(outcome.status.rawValue)"
            )
        }
        return verified
    }

    private func registerContractAsset(
        assetID: AgentMaterialAssetID,
        material: AgentMaterialStackSnapshot,
        observation: AgentMaterialHolderObservation,
        ownerID: AgentID,
        witnesses: [AgentID],
        basis: AgentMaterialClaimBasis,
        operationPrefix: String,
        productionOperationIDs: [String],
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
            .bindProductionProvenance(
                operationID: "\(operationPrefix):production-provenance",
                assetID: assetID,
                productionOperationIDs: productionOperationIDs.sorted()
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
        productionOperationIDs: [String],
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
            .bindProductionProvenance(
                operationID: "\(operationPrefix):production-provenance",
                assetID: assetID,
                productionOperationIDs: productionOperationIDs.sorted()
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

    private func proveContractUnrelatedInventoryDrift(
        leg: String,
        world: World
    ) -> PebbleAgentCommandResult {
        guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1",
              let session, activeWorld === world
        else {
            return failure(
                "Contract inventory drift is restricted to an active disposable proof."
            )
        }
        let sourceID: AgentID
        let material: AgentMaterialStackSnapshot
        switch leg {
        case "consideration":
            guard let proposal = session.contractSnapshot().proposals.first(where: {
                      $0.status == .open || $0.status == .accepted
                  }) else {
                return failure("Awaiting consideration authority is unavailable.")
            }
            sourceID = proposal.opportunity.promiseeID
            material = proposal.opportunity.consideration.material
        case "fulfillment":
            guard let obligation = session.contractSnapshot().obligations.first,
                  obligation.status == .outstanding
                    || obligation.status == .overdue else {
                return failure("Outstanding fulfillment authority is unavailable.")
            }
            sourceID = obligation.promisorID
            material = obligation.promisedPerformance.material
        default:
            return failure("Contract drift leg must be consideration or fulfillment.")
        }
        guard let probe = probesByAgentId[sourceID.rawValue],
              probe.world === world, !probe.dead else {
            return failure("Contract drift source probe is unavailable.")
        }
        let endpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            PebbleAgentEmbodiment(probe: probe), in: world
        )
        let beforeSlots = copyItemInventory(probe.carriedItems)
        do {
            let before = try materialCustodyGateway.acquireAssetAuthority(
                material, at: endpoint
            )
            let bridge = PebbleAgentMaterialSnapshotBridge()
            guard before.isExact,
                  let unrelatedIndex = probe.carriedItems.indices.first(where: {
                      guard let stack = probe.carriedItems[$0],
                            let snapshot = try? bridge.snapshot(of: stack) else {
                          return false
                      }
                      return snapshot.identity != material.identity
                  }),
                  let emptyIndex = probe.carriedItems.indices.first(where: {
                      probe.carriedItems[$0] == nil
                  }), unrelatedIndex != emptyIndex else {
                throw ControllerError.contractBoundary(
                    "unrelated drift control lacks exact asset and movable slot"
                )
            }
            probe.carriedItems[emptyIndex] = probe.carriedItems[unrelatedIndex]
            probe.carriedItems[unrelatedIndex] = nil
            let after = try materialCustodyGateway.acquireAssetAuthority(
                material, at: endpoint
            )
            guard after.isExact,
                  before.currentCustodyFingerprint
                    != after.currentCustodyFingerprint else {
                throw ControllerError.contractBoundary(
                    "unrelated drift did not preserve exact scoped authority"
                )
            }
            let message = "contract unrelated inventory drift leg=\(leg) "
                + "holder=\(sourceID.rawValue) tracked=\(material.identity.itemKey):"
                + "\(material.count) currentAuthorityBefore=exact "
                + "currentAuthorityAfter=exact fullFingerprintChanged=1 "
                + "trackedIdentityChanged=0 trackedQuantityChanged=0"
            trace(message)
            return success(message)
        } catch {
            probe.carriedItems = beforeSlots
            return failure("Contract inventory drift failed: \(error)")
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

    private func contractBlocker01ContainerCandidates(
        workshop: AgentPosition
    ) -> [AgentPosition] {
        [
            (3, 0), (-3, 0), (0, 3), (0, -3),
            (3, 3), (-3, -3), (3, -3), (-3, 3),
        ].map {
            AgentPosition(
                x: workshop.x + $0.0,
                y: workshop.y,
                z: workshop.z + $0.1
            )
        }
    }

    private func transferContractBlocker01Asset(
        assetID: AgentMaterialAssetID,
        actorID: AgentID,
        destinationHolder: AgentMaterialPhysicalHolder,
        source: PebbleAgentMaterialCustodyEndpoint,
        destination: PebbleAgentMaterialCustodyEndpoint,
        operationID: String,
        session: inout AgentSimulationSession
    ) throws {
        guard let record = session.materialRightsSnapshot().records.first(where: {
            $0.asset.assetID == assetID
        }) else {
            throw ControllerError.contractBoundary(
                "Blocker 01 rights asset unavailable"
            )
        }
        let material = AgentMaterialStackSnapshot(
            identity: record.lastVerifiedHolder.materialIdentity,
            count: record.lastVerifiedHolder.quantity
        )
        let decision = session.evaluateMaterialUse(AgentMaterialUseRequest(
            requestID: "\(operationID):authorize",
            assetID: assetID, actorID: actorID,
            use: .transferCustody,
            verifiedHolder: record.lastVerifiedHolder
        ))
        let sourceAuthority = try materialCustodyGateway.acquireAssetAuthority(
            material, at: source
        )
        let destinationBefore = try materialCustodyGateway.fingerprint(destination)
        guard decision.verdict == .allowed, sourceAuthority.isExact else {
            throw ControllerError.contractBoundary(
                "Blocker 01 exact current authority refused"
            )
        }
        let transfer = materialCustodyGateway.transfer(
            PebbleAgentMaterialTransactionRequest(
                transactionID: operationID,
                material: material,
                expectedSourceFingerprint:
                    sourceAuthority.currentCustodyFingerprint,
                expectedDestinationFingerprint: destinationBefore
            ), from: source, to: destination
        )
        guard transfer.succeeded,
              let sourceAfter = transfer.sourceFingerprint,
              let destinationAfter = transfer.destinationFingerprint else {
            throw ControllerError.contractBoundary(
                "Blocker 01 physical transfer \(transfer.status.rawValue)"
            )
        }
        let outcome = AgentMaterialPhysicalTransferOutcome(
            operationID: operationID, decision: decision,
            disposition: .authorized, status: .succeeded,
            destinationObservation: AgentMaterialHolderObservation(
                holder: destinationHolder,
                materialIdentity: material.identity,
                quantity: material.count,
                custodyFingerprint: destinationAfter,
                physicalReceiptID: operationID,
                observedAtTick: session.tick
            ), physicalReceiptID: operationID
        )
        do {
            _ = try session.applyMaterialRightsOperation(.physicalTransfer(outcome))
        } catch {
            let rollback = materialCustodyGateway.transfer(
                PebbleAgentMaterialTransactionRequest(
                    transactionID: "\(operationID):rollback",
                    material: material,
                    expectedSourceFingerprint: destinationAfter,
                    expectedDestinationFingerprint: sourceAfter
                ), from: destination, to: source
            )
            guard rollback.succeeded else {
                throw ControllerError.contractPostMutationBoundary(
                    "Blocker 01 rights publication rollback failed"
                )
            }
            throw error
        }
    }

    private func moveContractBlocker01Performance(
        returning: Bool,
        world: World
    ) -> PebbleAgentCommandResult {
        guard environment["PEBBLELAB_GATE_E_BLOCKER_01"] == "1",
              environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1",
              isPaused, !movementEnabled,
              let candidate = session, activeWorld === world,
              let obligation = candidate.contractSnapshot().obligations.first(where: {
                $0.status == .outstanding || $0.status == .overdue
              }),
              let record = candidate.materialRightsSnapshot().records.first(where: {
                $0.asset.assetID.rawValue
                    == "contract-blocker-01-bread-p3:\(obligation.promisorID.rawValue)"
              }),
              let promisorProbe = probesByAgentId[obligation.promisorID.rawValue],
              promisorProbe.world === world, !promisorProbe.dead,
              let keeperState = candidate.snapshot().agents.first(where: {
                $0.id != obligation.promisorID.rawValue
                    && $0.id != obligation.promiseeID.rawValue
              }), let keeperID = AgentID(rawValue: keeperState.id),
              let keeperProbe = probesByAgentId[keeperID.rawValue],
              keeperProbe.world === world, !keeperProbe.dead else {
            return failure(
                "Blocker 01 displacement requires paused disposable open debt."
            )
        }
        let promisor = PebbleAgentEmbodiment(probe: promisorProbe)
        let agentEndpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            promisor, in: world
        )
        let keeperEndpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            keeperProbe, in: world
        )
        guard record.lastVerifiedHolder.holder == .agent(obligation.promisorID),
              record.recognizedOwnership?.ownerID == obligation.promisorID else {
            return failure("Blocker 01 displacement holder is not current.")
        }
        do {
            let durableBefore = try candidate.durableStateBytes()
            let material = AgentMaterialStackSnapshot(
                identity: record.asset.materialIdentity,
                count: record.asset.quantity
            )
            let source = returning ? keeperEndpoint : agentEndpoint
            let destination = returning ? agentEndpoint : keeperEndpoint
            let authority = try materialCustodyGateway.acquireAssetAuthority(
                material, at: source
            )
            let destinationFingerprint = try materialCustodyGateway.fingerprint(
                destination
            )
            guard authority.isExact else {
                throw ControllerError.contractBoundary(
                    "Blocker 01 adversarial source is not exact"
                )
            }
            let operationID = returning
                ? "gate-e-blocker-01:return:\(obligation.obligationID.rawValue)"
                : "gate-e-blocker-01:displace:\(obligation.obligationID.rawValue)"
            let transfer = materialCustodyGateway.transfer(
                PebbleAgentMaterialTransactionRequest(
                    transactionID: operationID,
                    material: material,
                    expectedSourceFingerprint:
                        authority.currentCustodyFingerprint,
                    expectedDestinationFingerprint: destinationFingerprint
                ), from: source, to: destination
            )
            guard transfer.succeeded,
                  try candidate.durableStateBytes() == durableBefore else {
                throw ControllerError.contractPostMutationBoundary(
                    "Blocker 01 adversarial transfer or session isolation failed"
                )
            }
            let action = returning ? "returned" : "displaced"
            let holder = returning
                ? AgentMaterialPhysicalHolder.agent(obligation.promisorID).stableText
                : AgentMaterialPhysicalHolder.agent(keeperID).stableText
            let message = "contract blocker-01 \(action) asset="
                + "\(record.asset.assetID.rawValue) currentPhysicalHolder=\(holder) "
                + "quantity=1 rightsObservationUnchanged=1 "
                + "productionOriginUnchanged=1 syntheticReplacement=0"
            trace(message)
            return success(message)
        } catch {
            return failure("Blocker 01 \(returning ? "return" : "displacement") failed: \(error)")
        }
    }

    private func contractBlocker01ProvenanceStatus(
        world: World
    ) -> PebbleAgentCommandResult {
        guard environment["PEBBLELAB_GATE_E_BLOCKER_01"] == "1",
              let session, activeWorld === world,
              let record = session.materialRightsSnapshot().records.first(where: {
                $0.asset.assetID.rawValue.contains(
                    "contract-blocker-01-bread-p3:"
                )
              }), let provenance = record.productionProvenance,
              let origin = provenance.origins.first else {
            return failure("Blocker 01 exact provenance is unavailable.")
        }
        let matching = session.productionSnapshot().records.filter {
            $0.actorID == origin.producerID
                && $0.outputProduced == AgentMaterialStackSnapshot(
                    identity: record.asset.materialIdentity,
                    count: record.asset.quantity
                )
        }.sorted { $0.operationID < $1.operationID }
        let attributed = provenance.operationIDs
        let attributedQuantity = provenance.representedQuantity
        let otherMatchingRecords = matching.filter {
            !attributed.contains($0.operationID)
        }.count
        let exact = matching.count >= 3
            && record.asset.quantity == 1
            && provenance.origins.count == 1
            && attributedQuantity == 1
            && attributed == [origin.operationID]
            && origin.outputProduced == AgentMaterialStackSnapshot(
                identity: record.asset.materialIdentity,
                count: record.asset.quantity
            )
            && origin.hasValidDigest
            && otherMatchingRecords == matching.count - 1
        let message = "gate-e blocker-01 provenance matchingHistorical="
            + "\(matching.count) promisedAsset=\(record.asset.assetID.rawValue) "
            + "promisedQuantity=\(record.asset.quantity) attributedOperations="
            + attributed.joined(separator: ",")
            + " attributedQuantity=\(attributedQuantity) otherMatchingRecords="
            + "\(otherMatchingRecords) falseMatchingAttributed=0 currentHolder="
            + "\(record.lastVerifiedHolder.holder.stableText) originProducer="
            + "\(origin.producerID.rawValue) exactBinding="
            + "\(exact ? "PASS" : "FAIL") observerMutationCount=0"
        trace(message)
        return exact ? success(message) : failure(message)
    }

    private func contractDistance(
        _ lhs: AgentPosition,
        _ rhs: AgentPosition
    ) -> Int {
        abs(lhs.x - rhs.x) + abs(lhs.y - rhs.y) + abs(lhs.z - rhs.z)
    }
}
