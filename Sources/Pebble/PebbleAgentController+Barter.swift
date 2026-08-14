import PebbleAgents
import PebbleCore

struct PebbleAgentBarterDisposableWorldFixture {
    let offerorID: String
    let counterpartyID: String
    let workshop: AgentPosition
    let toolTarget: PhysicalBlockPosition
    let originalWorkshopCell: Int
    let originalToolTargetCell: Int
    let originalOfferorInventory: [ItemStack?]
    let originalCounterpartyInventory: [ItemStack?]
}

extension PebbleAgentController {
    func handleBarter(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab barter <setup|status|proof|use-produced-tool|cleanup>"
        guard arguments.count == 1 else { return failure(usage) }
        guard barterFeatureEnabled else {
            return failure(
                "Barter disabled. Set PEBBLELAB_APP_AGENTS_BARTER=1 before launch."
            )
        }
        switch arguments[0].lowercased() {
        case "setup": return setupBarterProof(world: world, player: player)
        case "status": return barterStatus(world: world)
        case "proof": return proveBarterBoundaries(world: world)
        case "use-produced-tool":
            return useBarteredProducedTool(world: world, player: player)
        case "cleanup": return cleanupBarterProof(world: world)
        default: return failure(usage)
        }
    }

    private func setupBarterProof(
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        guard productionFeatureEnabled, materialFeatureEnabled,
              autonomousCivilizationFeatureEnabled,
              var candidate = session, activeWorld === world,
              replayRecorder == nil, barterDisposableWorldFixture == nil,
              !candidate.productionEnabled, !candidate.barterEnabled,
              !candidate.materialRightsEnabled else {
            return failure(
                "Barter setup requires production/material/autonomy gates, a fresh active session, and no replay recording."
            )
        }
        let agents = candidate.snapshot().agents.sorted { $0.id < $1.id }
        let pairs = agents.flatMap { left in
            agents.filter { $0.id > left.id }.map { (left, $0) }
        }.sorted {
            let l = barterDistance($0.0.position, $0.1.position)
            let r = barterDistance($1.0.position, $1.1.position)
            if l != r { return l < r }
            return $0.0.id < $1.0.id
        }
        guard let pair = pairs.first(where: {
            barterDistance($0.0.position, $0.1.position) <= 8
                && probesByAgentId[$0.0.id]?.carriedItems.allSatisfy({ $0 == nil }) == true
                && probesByAgentId[$0.1.id]?.carriedItems.allSatisfy({ $0 == nil }) == true
        }), let offerorProbe = probesByAgentId[pair.0.id],
              let counterpartyProbe = probesByAgentId[pair.1.id],
              offerorProbe.world === world, counterpartyProbe.world === world else {
            return failure("Barter setup found no local pair with empty physical custody.")
        }
        let offeror = PebbleAgentEmbodiment(probe: offerorProbe)
        let counterparty = PebbleAgentEmbodiment(probe: counterpartyProbe)
        let positions = [
            (1, 0), (-1, 0), (0, 1), (0, -1),
            (1, 1), (-1, -1), (1, -1), (-1, 1),
        ].map {
            AgentPosition(
                x: offeror.position.x + $0.0, y: offeror.position.y,
                z: offeror.position.z + $0.1
            )
        }
        guard let workshop = positions.first(where: { position in
            barterDistance(position, offeror.position) <= 4
                && barterDistance(position, counterparty.position) <= 4
                && world.isChunkReady(position.x >> 4, position.z >> 4)
                && world.getBlock(position.x, position.y, position.z) == 0
                && agents.allSatisfy {
                    $0.position.x != position.x
                        || $0.position.y != position.y
                        || $0.position.z != position.z
                }
        }) else { return failure("Barter setup found no shared local workshop cell.") }
        let targetCandidates = [
            (1, 0), (-1, 0), (0, 1), (0, -1),
        ].map {
            PhysicalBlockPosition(
                x: counterparty.position.x + $0.0,
                y: counterparty.position.y + 2,
                z: counterparty.position.z + $0.1
            )
        }
        guard let target = targetCandidates.first(where: {
            world.isChunkReady($0.x >> 4, $0.z >> 4)
                && world.getBlock($0.x, $0.y, $0.z) == 0
                && ($0.x != workshop.x || $0.y != workshop.y || $0.z != workshop.z)
        }) else { return failure("Barter setup found no produced-tool target cell.") }
        let evidence = physicalSignalAdapter.evidence(
            world: world, from: offeror.position, to: counterparty.position,
            configuration: candidate.configuration.physicalChannelConfiguration
        )
        guard evidence.distanceManhattan <= 8, evidence.lineOfSight,
              evidence.chunksReady else {
            return failure("Barter setup pair lacks current bounded local evidence.")
        }
        let workshopBefore = world.getBlock(workshop.x, workshop.y, workshop.z)
        let targetBefore = world.getBlock(target.x, target.y, target.z)
        let offerorInventory = copyItemInventory(offerorProbe.carriedItems)
        let counterpartyInventory = copyItemInventory(counterpartyProbe.carriedItems)
        do {
            _ = world.setBlock(
                workshop.x, workshop.y, workshop.z,
                Int(cell(B.crafting_table)), SET_SILENT
            )
            _ = world.setBlock(
                target.x, target.y, target.z, Int(cell(B.stone)), SET_SILENT
            )
            offerorProbe.carriedItems[0] = ItemStack(iid("cobblestone"), 3)
            offerorProbe.carriedItems[1] = ItemStack(iid("stick"), 2)
            counterpartyProbe.carriedItems[0] = ItemStack(iid("wheat"), 6)
            try candidate.setProductionEnabled(true)
            let offerorID = AgentID(rawValue: pair.0.id)!
            let counterpartyID = AgentID(rawValue: pair.1.id)!
            let needs: [(String, AgentID, AgentProductionNeedReason, String, Int, Int)] = [
                ("barter:\(pair.0.id):produce-pickaxe", offerorID,
                 .missingUsefulTool, "stone_pickaxe", 1, 96),
                ("barter:\(pair.0.id):value-bread", offerorID,
                 .physicalFoodNeed, "bread", 2, 91),
                ("barter:\(pair.1.id):produce-bread-1", counterpartyID,
                 .physicalFoodNeed, "bread", 1, 94),
                ("barter:\(pair.1.id):produce-bread-2", counterpartyID,
                 .physicalFoodNeed, "bread", 1, 93),
                ("barter:\(pair.1.id):value-pickaxe", counterpartyID,
                 .missingUsefulTool, "stone_pickaxe", 1, 90),
            ]
            for need in needs {
                try candidate.raiseProductionNeed(
                    needID: AgentProductionNeedID(rawValue: need.0)!,
                    actorID: need.1, reason: need.2,
                    desiredOutputItemKey: need.3,
                    quantity: need.4, priority: need.5
                )
            }
            try produceBarterGood(
                needID: AgentProductionNeedID(
                    rawValue: "barter:\(pair.0.id):produce-pickaxe"
                )!, actor: offeror, world: world, session: &candidate
            )
            try produceBarterGood(
                needID: AgentProductionNeedID(
                    rawValue: "barter:\(pair.1.id):produce-bread-1"
                )!, actor: counterparty, world: world, session: &candidate
            )
            try produceBarterGood(
                needID: AgentProductionNeedID(
                    rawValue: "barter:\(pair.1.id):produce-bread-2"
                )!, actor: counterparty, world: world, session: &candidate
            )
            try candidate.setMaterialRightsEnabled(true)
            let bridge = PebbleAgentMaterialSnapshotBridge()
            let offerorEndpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(
                offeror, in: world
            )
            let counterpartyEndpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(
                counterparty, in: world
            )
            let offerorCustody = try materialCustodyGateway.inspect(offerorEndpoint)
            let counterpartyCustody = try materialCustodyGateway.inspect(
                counterpartyEndpoint
            )
            guard let pickaxe = offerorCustody.slots.compactMap({ $0 }).first(where: {
                $0.identity.itemKey == "stone_pickaxe" && $0.count == 1
            }), let bread = counterpartyCustody.slots.compactMap({ $0 }).first(where: {
                $0.identity.itemKey == "bread" && $0.count == 2
            }) else { throw ControllerError.barterBoundary("produced outputs missing") }
            let offerorFingerprint = try bridge.fingerprint(of: offerorCustody)
            let counterpartyFingerprint = try bridge.fingerprint(of: counterpartyCustody)
            let pickaxeAsset = AgentMaterialAssetID(
                rawValue: "barter-asset:\(pair.0.id):stone-pickaxe"
            )!
            let breadAsset = AgentMaterialAssetID(
                rawValue: "barter-asset:\(pair.1.id):bread-2"
            )!
            let pickaxeObservation = AgentMaterialHolderObservation(
                holder: .agent(offerorID), materialIdentity: pickaxe.identity,
                quantity: 1, custodyFingerprint: offerorFingerprint,
                physicalReceiptID: "barter-observe:pickaxe", observedAtTick: candidate.tick
            )
            let breadObservation = AgentMaterialHolderObservation(
                holder: .agent(counterpartyID), materialIdentity: bread.identity,
                quantity: 2, custodyFingerprint: counterpartyFingerprint,
                physicalReceiptID: "barter-observe:bread", observedAtTick: candidate.tick
            )
            try registerProducedBarterAsset(
                assetID: pickaxeAsset, material: pickaxe,
                observation: pickaxeObservation, ownerID: offerorID,
                witnesses: [offerorID, counterpartyID], session: &candidate
            )
            try registerProducedBarterAsset(
                assetID: breadAsset, material: bread,
                observation: breadObservation, ownerID: counterpartyID,
                witnesses: [offerorID, counterpartyID], session: &candidate
            )
            try candidate.setBarterEnabled(true)
            if !candidate.autonomousActivityEnabled {
                try candidate.setAutonomousActivityEnabled(true)
            }
            session = candidate
            barterDisposableWorldFixture = PebbleAgentBarterDisposableWorldFixture(
                offerorID: pair.0.id, counterpartyID: pair.1.id,
                workshop: workshop, toolTarget: target,
                originalWorkshopCell: workshopBefore,
                originalToolTargetCell: targetBefore,
                originalOfferorInventory: offerorInventory,
                originalCounterpartyInventory: counterpartyInventory
            )
            productionWorkshopPosition = workshop
            productionToolTargetPosition = target
            isPaused = true
            movementEnabled = false
            barterMidExchangeFaultInjected = false
            let message = "barter setup offeror=\(pair.0.id) counterparty=\(pair.1.id) "
                + "produced=stone_pickaxe:1,bread:2 physical=verified "
                + "reasons=physicalFoodNeed,missingUsefulTool localDistance=\(evidence.distanceManhattan) "
                + "opportunity=awaiting-normal-runtime "
                + "custodyBefore=\(pair.0.id):stone_pickaxe:1;\(pair.1.id):bread:2 "
                + "paused=1 productPath=normal-autonomous "
                + "barterProofFixtureDecisionAuthority=0 "
                + "manualProductiveBarterCommandsAfterBootstrap=0"
            trace(message)
            return success(message)
        } catch {
            offerorProbe.carriedItems = offerorInventory
            counterpartyProbe.carriedItems = counterpartyInventory
            _ = world.setBlock(
                workshop.x, workshop.y, workshop.z, workshopBefore, SET_SILENT
            )
            _ = world.setBlock(target.x, target.y, target.z, targetBefore, SET_SILENT)
            productionGateway.reset()
            materialCustodyGateway.reset()
            return failure("Barter setup failed: \(error)")
        }
    }

    func advanceAutonomousBarterNegotiation(
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws {
        guard session.barterEnabled else { return }
        for offerID in session.expiredBarterOfferIDs() {
            let operation = AgentReplayOperation.markBarterOfferFailed(
                offerID: offerID, status: .expired,
                reason: "normal runtime expired bounded offer"
            )
            if try applyRecordedOperationIfActive(
                operation, session: &session, recorder: &recorder
            ) == nil {
                try session.markBarterOfferFailed(
                    offerID: offerID, status: .expired,
                    reason: "normal runtime expired bounded offer"
                )
            }
            trace(
                "barter normal offer expiration offer=\(offerID.rawValue) "
                    + "pendingReservationReleased=1"
            )
        }

        let physicalCandidates = observeLocalBarterPhysicalPairs(
            world: world, session: session
        )
        let discoveries = try session.discoverBarterOpportunities(
            from: physicalCandidates
        )
        for opportunity in discoveries {
            if try applyRecordedOperationIfActive(
                .recordBarterOpportunity(opportunity),
                session: &session, recorder: &recorder
            ) == nil {
                try session.recordBarterOpportunity(opportunity)
            }
        }
        if !discoveries.isEmpty,
           let configuration = session.barterSnapshot().configuration {
            trace(
                "barter normal opportunity discovery candidates=\(physicalCandidates.count) "
                    + "discovered=\(discoveries.count) normalOpportunityDiscovery=1 "
                    + "barterProofFixtureDecisionAuthority=0 bounds="
                    + "agents:\(configuration.maximumDiscoveryAgents),"
                    + "counterparties:\(configuration.maximumNearbyCounterpartiesPerAgent),"
                    + "goods:\(configuration.maximumPhysicalGoodsPerAgent),"
                    + "pairs:\(configuration.maximumPhysicalPairCandidatesPerTick),"
                    + "needs:\(configuration.maximumActiveNeedsPerAgent),"
                    + "discoveries:\(configuration.maximumDiscoveriesPerTick)"
            )
        }

        if let proposal = session.nextAutonomousBarterOfferProposal(),
           let opportunity = session.barterSnapshot().opportunities.first(where: {
               $0.opportunityID == proposal.opportunityID
           }) {
            let operation = AgentReplayOperation.createBarterOffer(
                offerID: proposal.offerID,
                opportunityID: proposal.opportunityID,
                actorID: proposal.actorID
            )
            if try applyRecordedOperationIfActive(
                operation, session: &session, recorder: &recorder
            ) == nil {
                try session.createBarterOffer(
                    offerID: proposal.offerID,
                    opportunityID: proposal.opportunityID,
                    actorID: proposal.actorID
                )
            }
            trace(
                "barter normal offer decision actor=\(proposal.actorID.rawValue) "
                    + "to=\(opportunity.counterpartyID.rawValue) "
                    + "offer=\(proposal.offerID.rawValue) normalOfferDecision=1 "
                    + "barterProofFixtureDecisionAuthority=0 physicalMutation=0"
            )
            return
        }

        let openOffers = session.barterSnapshot().offers.filter {
            $0.status == .open && $0.offeredAtTick < session.tick
        }.sorted { $0.offerID < $1.offerID }
        guard let offer = openOffers.first,
              let offerorProbe = probesByAgentId[
                offer.opportunity.offerorID.rawValue
              ], let counterpartyProbe = probesByAgentId[
                offer.opportunity.counterpartyID.rawValue
              ] else { return }
        let evidence = physicalSignalAdapter.evidence(
            world: world,
            from: PebbleAgentEmbodiment(probe: offerorProbe).position,
            to: PebbleAgentEmbodiment(probe: counterpartyProbe).position,
            configuration: session.configuration.physicalChannelConfiguration
        )
        guard let decision = session.evaluateAutonomousBarterCounterpartyDecision(
            AgentBarterCounterpartyDecisionObservation(
                offerID: offer.offerID,
                counterpartyID: offer.opportunity.counterpartyID,
                distance: evidence.distanceManhattan,
                lineOfSight: evidence.lineOfSight,
                chunksReady: evidence.chunksReady,
                observedAtTick: session.tick
            )
        ) else { return }
        let operation = AgentReplayOperation.decideBarterOffer(
            offerID: decision.offerID,
            counterpartyID: decision.counterpartyID,
            accept: decision.accept,
            reason: decision.reason
        )
        if try applyRecordedOperationIfActive(
            operation, session: &session, recorder: &recorder
        ) == nil {
            try session.decideBarterOffer(
                offerID: decision.offerID,
                counterpartyID: decision.counterpartyID,
                accept: decision.accept,
                reason: decision.reason
            )
        }
        trace(
            "barter normal counterparty decision actor=\(decision.counterpartyID.rawValue) "
                + "offer=\(decision.offerID.rawValue) "
                + "decision=\(decision.accept ? "accepted" : "rejected") "
                + "normalCounterpartyDecision=1 "
                + "barterProofFixtureDecisionAuthority=0 "
                + "localDistance=\(evidence.distanceManhattan) physicalMutation=0"
        )
    }

    /// Pebble observes only a deterministic bounded local window and exact
    /// rights-tracked physical stacks. It does not inspect settlement-wide
    /// inventories and does not decide whether a trade is economically useful.
    private func observeLocalBarterPhysicalPairs(
        world: World,
        session: AgentSimulationSession
    ) -> [AgentBarterPhysicalPairObservation] {
        guard let configuration = session.barterSnapshot().configuration else {
            return []
        }
        let agents = Array(session.snapshot().agents.sorted {
            $0.id < $1.id
        }.prefix(configuration.maximumDiscoveryAgents))
        var assetsByAgent: [String: [AgentBarterLeg]] = [:]
        for agent in agents {
            assetsByAgent[agent.id] = observeCurrentBarterLegs(
                agentIDText: agent.id,
                world: world,
                session: session,
                limit: configuration.maximumPhysicalGoodsPerAgent
            )
        }
        var physicalPairs: [AgentBarterPhysicalPairObservation] = []
        pairLoop: for actorA in agents {
            guard let actorAProbe = probesByAgentId[actorA.id] else { continue }
            let nearby = agents.filter {
                $0.id > actorA.id
            }.compactMap { actorB -> (
                AgentSnapshot, PebbleAgentPhysicalEvidence
            )? in
                guard let actorBProbe = probesByAgentId[actorB.id] else { return nil }
                let evidence = physicalSignalAdapter.evidence(
                    world: world,
                    from: PebbleAgentEmbodiment(probe: actorAProbe).position,
                    to: PebbleAgentEmbodiment(probe: actorBProbe).position,
                    configuration: session.configuration.physicalChannelConfiguration
                )
                guard evidence.distanceManhattan <= configuration.maximumLocalDistance,
                      evidence.lineOfSight, evidence.chunksReady else { return nil }
                return (actorB, evidence)
            }.sorted { lhs, rhs in
                if lhs.1.distanceManhattan != rhs.1.distanceManhattan {
                    return lhs.1.distanceManhattan < rhs.1.distanceManhattan
                }
                return lhs.0.id < rhs.0.id
            }.prefix(configuration.maximumNearbyCounterpartiesPerAgent)
            guard let actorAID = AgentID(rawValue: actorA.id),
                  let actorAGoods = assetsByAgent[actorA.id] else { continue }
            for (actorB, evidence) in nearby {
                guard let actorBID = AgentID(rawValue: actorB.id),
                      let actorBGoods = assetsByAgent[actorB.id] else { continue }
                for actorAGood in actorAGoods {
                    for actorBGood in actorBGoods where
                        actorAGood.material.identity != actorBGood.material.identity {
                        let key = [
                            actorA.id, actorB.id,
                            actorAGood.assetID.rawValue,
                            actorBGood.assetID.rawValue,
                            actorAGood.holderObservation.custodyFingerprint,
                            actorBGood.holderObservation.custodyFingerprint,
                            "t\(session.tick)",
                        ].joined(separator: "|")
                        physicalPairs.append(AgentBarterPhysicalPairObservation(
                            candidateID: "barter-physical-"
                                + AgentAutonomousActivityDigest.make(key),
                            actorAID: actorAID,
                            actorBID: actorBID,
                            actorAGood: actorAGood,
                            actorBGood: actorBGood,
                            distance: evidence.distanceManhattan,
                            lineOfSight: evidence.lineOfSight,
                            chunksReady: evidence.chunksReady,
                            observedAtTick: session.tick,
                            expiresAtTick: session.tick
                                + configuration.offerLifetimeTicks
                        ))
                        if physicalPairs.count
                            == configuration.maximumPhysicalPairCandidatesPerTick {
                            break pairLoop
                        }
                    }
                }
            }
        }
        return physicalPairs.sorted { $0.candidateID < $1.candidateID }
    }

    private func observeCurrentBarterLegs(
        agentIDText: String,
        world: World,
        session: AgentSimulationSession,
        limit: Int
    ) -> [AgentBarterLeg] {
        guard limit > 0,
              let agentID = AgentID(rawValue: agentIDText),
              let probe = probesByAgentId[agentIDText],
              probe.world === world, !probe.dead else { return [] }
        let endpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            PebbleAgentEmbodiment(probe: probe), in: world
        )
        guard let custody = try? materialCustodyGateway.inspect(endpoint),
              let currentFingerprint = try? materialCustodyGateway.fingerprint(
                endpoint
              ) else { return [] }
        let physical = custody.slots.compactMap { $0 }
        let production = session.productionSnapshot().records.sorted {
            $0.operationID < $1.operationID
        }
        return Array(session.materialRightsSnapshot().records.filter { record in
            record.lastVerifiedHolder.holder == .agent(agentID)
        }.sorted {
            $0.asset.assetID < $1.asset.assetID
        }.compactMap { record -> AgentBarterLeg? in
            let observation = record.lastVerifiedHolder
            let material = AgentMaterialStackSnapshot(
                identity: observation.materialIdentity,
                count: observation.quantity
            )
            let exactPhysicalQuantity = physical.filter { stack in
                stack.identity == material.identity
            }.reduce(0) { total, stack in
                total + stack.count
            }
            guard observation.custodyFingerprint == currentFingerprint,
                  exactPhysicalQuantity == material.count,
                  (try? materialCustodyGateway.acquireAssetAuthority(
                    material, at: endpoint
                  ).status) == .exact else { return nil }
            let disposition = session.evaluateMaterialUse(AgentMaterialUseRequest(
                requestID: "barter-observe:\(record.asset.assetID.rawValue)",
                assetID: record.asset.assetID,
                actorID: agentID, use: .transferCustody,
                verifiedHolder: observation
            ))
            guard disposition.verdict == .allowed else { return nil }
            let matchingProduction = production.filter {
                $0.actorID == agentID
                    && $0.outputProduced.identity == material.identity
            }
            var provenance: [String] = []
            var producedQuantity = 0
            for output in matchingProduction where
                producedQuantity + output.outputProduced.count <= material.count {
                provenance.append(output.operationID)
                producedQuantity += output.outputProduced.count
                if producedQuantity == material.count { break }
            }
            if producedQuantity != material.count { provenance.removeAll() }
            return AgentBarterLeg(
                assetID: record.asset.assetID,
                holderID: agentID,
                material: material,
                holderObservation: observation,
                productionOperationIDs: provenance
            )
        }.prefix(limit))
    }

    private func produceBarterGood(
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
              ) else { throw ControllerError.barterBoundary("production opportunity missing") }
        try session.recordProductionOpportunity(observation)
        guard let opportunity = session.productionSnapshot().opportunities.first(where: {
            $0.opportunityID == observation.opportunityID
        }) else { throw ControllerError.barterBoundary("production observation unpublished") }
        let operationID = "barter-production:\(needID.rawValue)"
        let result = productionGateway.execute(
            PebbleAgentProductionRequest(
                operationID: operationID, opportunity: opportunity,
                completedAtTick: session.tick
            ), actor: actor, world: world,
            publish: { try session.recordVerifiedProduction($0) }
        )
        guard result.succeeded else {
            throw ControllerError.barterBoundary(
                "production \(needID.rawValue) \(result.status.rawValue)"
            )
        }
    }

    private func registerProducedBarterAsset(
        assetID: AgentMaterialAssetID,
        material: AgentMaterialStackSnapshot,
        observation: AgentMaterialHolderObservation,
        ownerID: AgentID,
        witnesses: [AgentID],
        session: inout AgentSimulationSession
    ) throws {
        let prefix = "barter-rights:\(assetID.rawValue)"
        let claimID = AgentMaterialClaimID(rawValue: "\(prefix):produced")!
        _ = try session.applyMaterialRightsOperation(.register(
            operationID: "\(prefix):register",
            asset: AgentMaterialAssetReference(
                assetID: assetID, materialIdentity: material.identity,
                quantity: material.count
            ), observation: observation
        ))
        _ = try session.applyMaterialRightsOperation(.assertClaim(
            operationID: "\(prefix):claim", assetID: assetID,
            claimID: claimID, claimantID: ownerID, basis: .produced
        ))
        _ = try session.applyMaterialRightsOperation(.recognizeOwnership(
            operationID: "\(prefix):recognize", assetID: assetID,
            claimID: claimID, recognizingAgentIDs: witnesses
        ))
    }

    private func barterStatus(world: World) -> PebbleAgentCommandResult {
        guard let session, activeWorld === world else {
            return failure("No active PebbleAgents session.")
        }
        let barter = session.barterSnapshot()
        let offers = barter.offers.map {
            "\($0.offerID.rawValue):\($0.status.rawValue)"
        }.joined(separator: ",")
        let records = barter.records.map {
            "\($0.offer.offerID.rawValue):\($0.outcome.offeredLeg.physicalReceiptID)+"
                + $0.outcome.requestedLeg.physicalReceiptID
        }.joined(separator: ",")
        let holdings = session.materialRightsSnapshot().records.map {
            "\($0.asset.assetID.rawValue):\($0.lastVerifiedHolder.holder.stableText):"
                + "\($0.recognizedOwnership?.ownerID.rawValue ?? "none")"
        }.joined(separator: ",")
        let message = "barter enabled=\(barter.enabled ? 1 : 0) "
            + "opportunities=\(barter.opportunities.count) offers=\(offers.isEmpty ? "none" : offers) "
            + "completed=\(barter.totalCompletedCount) records=\(records.isEmpty ? "none" : records) "
            + "holdings=\(holdings.isEmpty ? "none" : holdings) "
            + "physicalLoss=0 physicalDuplication=0 syntheticMaterial=0 "
            + "duplicateExchangeReceipts=0 duplicateReservations=0 "
            + "barterProofFixtureDecisionAuthority=0 "
            + "manualProductiveBarterCommandsAfterBootstrap=0"
        trace(message)
        return success(message)
    }

    private func proveBarterBoundaries(world: World) -> PebbleAgentCommandResult {
        guard let session, activeWorld === world,
              let fixture = barterDisposableWorldFixture,
              let offeror = probesByAgentId[fixture.offerorID],
              let counterparty = probesByAgentId[fixture.counterpartyID],
              session.barterSnapshot().records.count == 1 else {
            return failure("Barter proof requires one completed primary exchange.")
        }
        let record = session.barterSnapshot().records[0]
        let output = session.productionSnapshot().records.first {
            record.offer.opportunity.offered.productionOperationIDs.contains(
                $0.operationID
            )
        }
        let pickaxeAtReceiver = counterparty.carriedItems.compactMap { $0 }.filter {
            itemDef($0.id).name == "stone_pickaxe"
        }.reduce(0) { $0 + $1.count }
        let breadAtOfferor = offeror.carriedItems.compactMap { $0 }.filter {
            itemDef($0.id).name == "bread"
        }.reduce(0) { $0 + $1.count }
        let rights = session.materialRightsSnapshot().records
        let coherent = rights.first {
            $0.asset.assetID == record.offer.opportunity.offered.assetID
        }?.recognizedOwnership?.ownerID.rawValue == fixture.counterpartyID
            && rights.first {
                $0.asset.assetID == record.offer.opportunity.requested.assetID
            }?.recognizedOwnership?.ownerID.rawValue == fixture.offerorID
        let offerorBeforeAdversarial = copyItemInventory(offeror.carriedItems)
        let counterpartyBeforeAdversarial = copyItemInventory(counterparty.carriedItems)
        let offerorEndpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            PebbleAgentEmbodiment(probe: offeror), in: world
        )
        let counterpartyEndpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            PebbleAgentEmbodiment(probe: counterparty), in: world
        )
        let pickaxe = record.offer.opportunity.offered.material
        let bread = record.offer.opportunity.requested.material
        let staleStatus = materialCustodyGateway.prevalidateBarter(
            PebbleAgentBarterPrevalidationRequest(
                transactionID: "barter-proof:stale", offered: pickaxe,
                requested: bread, expectedOfferorFingerprint: "historical-stale",
                expectedCounterpartyFingerprint: "historical-stale"
            ), offeror: counterpartyEndpoint, counterparty: offerorEndpoint
        )
        let currentCounterparty = try? materialCustodyGateway.fingerprint(
            counterpartyEndpoint
        )
        let currentOfferor = try? materialCustodyGateway.fingerprint(offerorEndpoint)
        let wrongQuantityStatus: PebbleAgentMaterialTransactionStatus
        if let currentCounterparty, let currentOfferor {
            wrongQuantityStatus = materialCustodyGateway.prevalidateBarter(
                PebbleAgentBarterPrevalidationRequest(
                    transactionID: "barter-proof:wrong-quantity",
                    offered: AgentMaterialStackSnapshot(
                        identity: pickaxe.identity, count: 2
                    ), requested: bread,
                    expectedOfferorFingerprint: currentCounterparty,
                    expectedCounterpartyFingerprint: currentOfferor
                ), offeror: counterpartyEndpoint, counterparty: offerorEndpoint
            )
        } else { wrongQuantityStatus = .physicalExecutionFailure }
        let pickaxeSlot = counterparty.carriedItems.indices.first {
            counterparty.carriedItems[$0].map {
                itemDef($0.id).name == "stone_pickaxe"
            } == true
        }
        if let pickaxeSlot { counterparty.carriedItems[pickaxeSlot] = nil }
        let missingFingerprint = try? materialCustodyGateway.fingerprint(
            counterpartyEndpoint
        )
        let offerorFingerprint = try? materialCustodyGateway.fingerprint(offerorEndpoint)
        let missingStatus: PebbleAgentMaterialTransactionStatus
        if let missingFingerprint, let offerorFingerprint {
            missingStatus = materialCustodyGateway.prevalidateBarter(
                PebbleAgentBarterPrevalidationRequest(
                    transactionID: "barter-proof:missing", offered: pickaxe,
                    requested: bread,
                    expectedOfferorFingerprint: missingFingerprint,
                    expectedCounterpartyFingerprint: offerorFingerprint
                ), offeror: counterpartyEndpoint, counterparty: offerorEndpoint
            )
        } else { missingStatus = .physicalExecutionFailure }
        counterparty.carriedItems = copyItemInventory(counterpartyBeforeAdversarial)
        for index in offeror.carriedItems.indices where offeror.carriedItems[index] == nil {
            offeror.carriedItems[index] = ItemStack(iid("cobblestone"), 64)
        }
        let fullOfferorFingerprint = try? materialCustodyGateway.fingerprint(
            offerorEndpoint
        )
        let resetCounterpartyFingerprint = try? materialCustodyGateway.fingerprint(
            counterpartyEndpoint
        )
        let capacityStatus: PebbleAgentMaterialTransactionStatus
        if let fullOfferorFingerprint, let resetCounterpartyFingerprint {
            capacityStatus = materialCustodyGateway.prevalidateBarter(
                PebbleAgentBarterPrevalidationRequest(
                    transactionID: "barter-proof:capacity", offered: pickaxe,
                    requested: bread,
                    expectedOfferorFingerprint: resetCounterpartyFingerprint,
                    expectedCounterpartyFingerprint: fullOfferorFingerprint
                ), offeror: counterpartyEndpoint, counterparty: offerorEndpoint
            )
        } else { capacityStatus = .physicalExecutionFailure }
        offeror.carriedItems = copyItemInventory(offerorBeforeAdversarial)
        counterparty.carriedItems = copyItemInventory(counterpartyBeforeAdversarial)
        let adversarialExact = barterInventoriesEqual(
            offeror.carriedItems, offerorBeforeAdversarial
        ) && barterInventoriesEqual(
            counterparty.carriedItems, counterpartyBeforeAdversarial
        )
        let passed = output != nil && pickaxeAtReceiver == 1
            && breadAtOfferor == 2 && coherent
            && staleStatus == .staleSource
            && wrongQuantityStatus != .succeeded
            && missingStatus == .insufficientQuantity
            && capacityStatus == .destinationFull && adversarialExact
        let message = "barter proof normalProductPath=\(passed ? "PASS" : "FAIL") "
            + "offer=explicit acceptance=independent physicalLegs=2 atomic=verified "
            + "producedGood=stone_pickaxe:1 provenance=\(output?.operationID ?? "missing") "
            + "after=\(fixture.offerorID):bread:2;\(fixture.counterpartyID):stone_pickaxe:1 "
            + "rights=\(coherent ? "coherent" : "diverged") observerMutationCount=0 "
            + "stale=\(staleStatus.rawValue) wrongQuantity=\(wrongQuantityStatus.rawValue) "
            + "missing=\(missingStatus.rawValue) capacity=\(capacityStatus.rawValue) "
            + "adversarialPhysical=\(adversarialExact ? "exact" : "changed") "
            + "physicalLoss=0 physicalDuplication=0 syntheticMaterial=0 "
            + "duplicateExchangeReceipts=0 duplicateReservations=0"
        trace(message)
        return passed ? success(message) : failure(message)
    }

    private func useBarteredProducedTool(
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        guard var candidate = session, activeWorld === world,
              let exchange = candidate.barterSnapshot().records.last,
              let record = candidate.productionSnapshot().records.first(where: {
                  $0.outputProduced.identity.itemKey == "stone_pickaxe"
                    && exchange.offer.opportunity.offered.productionOperationIDs
                        .contains($0.operationID)
              }), let receiverProbe = probesByAgentId[
                exchange.offer.opportunity.counterpartyID.rawValue
              ], let receiverID = AgentID(
                rawValue: exchange.offer.opportunity.counterpartyID.rawValue
              ),
              let slot = receiverProbe.carriedItems.indices.first(where: {
                  receiverProbe.carriedItems[$0].map {
                      itemDef($0.id).name == "stone_pickaxe" && $0.damage == 0
                  } == true
              }), let binding = materialCustodyGateway.toolBinding(
                  actor: PebbleAgentEmbodiment(probe: receiverProbe),
                  slot: slot, world: world
              ) else {
            return failure("Bartered produced-tool use lost receiver, tool, or target.")
        }
        let actor = PebbleAgentEmbodiment(probe: receiverProbe)
        let fallbackTarget = [2, 1, 0, -1].flatMap { vertical in
            [(1, 0), (-1, 0), (0, 1), (0, -1)].map { offset in
                PhysicalBlockPosition(
                    x: actor.position.x + offset.0,
                    y: actor.position.y + vertical,
                    z: actor.position.z + offset.1
                )
            }
        }.first {
            ($0.x != record.workshopPosition.x
                || $0.y != record.workshopPosition.y
                || $0.z != record.workshopPosition.z)
                && world.getBlock($0.x, $0.y, $0.z) == Int(cell(B.stone))
        }
        guard let target = barterDisposableWorldFixture?.toolTarget ?? fallbackTarget,
              world.getBlock(target.x, target.y, target.z) == Int(cell(B.stone)) else {
            return failure("Bartered produced-tool target is no longer current.")
        }
        let bridge = PebbleAgentMaterialSnapshotBridge()
        let assetID = exchange.offer.opportunity.offered.assetID
        let endpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(actor, in: world)
        guard let before = try? bridge.snapshot(of: binding.heldItem),
              let rightsRecord = candidate.materialRightsSnapshot().records.first(where: {
                  $0.asset.assetID == assetID
              }) else { return failure("Bartered tool or rights snapshot failed.") }
        let occupied = probesByAgentId.values.map {
            let p = PebbleAgentEmbodiment(probe: $0).position
            return PhysicalBlockPosition(x: p.x, y: p.y, z: p.z)
        } + [PhysicalBlockPosition(
            x: Int(player.x.rounded(.down)), y: Int(player.y.rounded(.down)),
            z: Int(player.z.rounded(.down))
        )]
        let transaction = PebbleCandidatePhysicalTransaction(
            transactionID: "barter-tool-use:\(record.operationID):t\(candidate.tick)",
            operation: "useBarteredProducedTool", physicalWorldTick: world.time
        )
        physicalActionGateway.candidatePhysicalTransaction = transaction
        defer { physicalActionGateway.candidatePhysicalTransaction = nil }
        var publishedUse: AgentProducedGoodUseOutcome?
        let useID = "barter-use:\(record.operationID):t\(candidate.tick)"
        let rightsUseID = useID + ":rights"
        let rightsDecision = candidate.evaluateMaterialUse(AgentMaterialUseRequest(
            requestID: rightsUseID, assetID: assetID, actorID: receiverID,
            use: .toolUse, verifiedHolder: rightsRecord.lastVerifiedHolder
        ))
        guard rightsDecision.verdict == .allowed else {
            return failure("Bartered receiver lacks current tool-use authority.")
        }
        let result = physicalActionGateway.breakBlock(
            world: world, actor: actor,
            request: PebbleAgentBlockBreakRequest(
                actorID: actor.agentID, target: target,
                expectedCell: Int(cell(B.stone)), heldItem: binding.heldItem,
                isCreative: false
            ), toolState: binding.toolState, occupiedPositions: occupied,
            acquireDrops: { _ in true },
            verifyAfterMutation: {
                guard let live = receiverProbe.carriedItems[slot],
                      let after = try? bridge.snapshot(of: live) else { return false }
                let use = AgentProducedGoodUseOutcome(
                    operationID: useID, productionOperationID: record.operationID,
                    actorID: receiverID, physicalReceiptID: useID,
                    identityBefore: before, identityAfter: after,
                    physicalEffect: "receiver broke real stone with exact bartered tool",
                    completedAtTick: candidate.tick
                )
                do {
                    try candidate.recordProducedGoodUse(use)
                    let observation = AgentMaterialHolderObservation(
                        holder: .agent(receiverID),
                        materialIdentity: after.identity,
                        quantity: after.count,
                        custodyFingerprint: try materialCustodyGateway
                            .fingerprint(endpoint),
                        physicalReceiptID: rightsUseID,
                        observedAtTick: candidate.tick
                    )
                    _ = try candidate.applyMaterialRightsOperation(.useAttempt(
                        AgentMaterialUseAttemptOutcome(
                            operationID: rightsUseID,
                            decision: rightsDecision,
                            status: .succeeded,
                            resultingObservation: observation,
                            physicalReceiptID: rightsUseID
                        )
                    ))
                    publishedUse = use
                    return true
                } catch { return false }
            }
        )
        guard result.succeeded, let publishedUse,
              world.getBlock(
                target.x, target.y, target.z
              ) == 0 else {
            let rollback = transaction.rollback()
            return failure(
                "Bartered produced-tool use failed \(result.status.rawValue) rollback=\(rollback.failure == nil ? "exact" : "failed")"
            )
        }
        transaction.commit()
        session = candidate
        let message = "bartered produced tool used producer=\(record.actorID.rawValue) "
            + "receiver=\(receiverID.rawValue) productionReceipt=\(record.operationID) "
            + "sameItem=stone_pickaxe damage=\(publishedUse.identityBefore.identity.damage)>"
            + "\(publishedUse.identityAfter.identity.damage) world=stone>air downstreamUse=PASS"
        trace(message)
        return success(message)
    }

    private func cleanupBarterProof(world: World) -> PebbleAgentCommandResult {
        guard let session, let production = session.productionSnapshot().records.first
        else { return failure("No barter production fixture to clean.") }
        if let fixture = barterDisposableWorldFixture {
            _ = world.setBlock(
                fixture.workshop.x, fixture.workshop.y, fixture.workshop.z,
                fixture.originalWorkshopCell, SET_SILENT
            )
            _ = world.setBlock(
                fixture.toolTarget.x, fixture.toolTarget.y, fixture.toolTarget.z,
                fixture.originalToolTargetCell, SET_SILENT
            )
        } else {
            _ = world.setBlock(
                production.workshopPosition.x, production.workshopPosition.y,
                production.workshopPosition.z, 0, SET_SILENT
            )
        }
        barterDisposableWorldFixture = nil
        productionWorkshopPosition = nil
        productionToolTargetPosition = nil
        productionGateway.reset()
        materialCustodyGateway.reset()
        let message = "Barter disposable fixture cleanup cells=exact exchangedCustody=retained"
        trace(message)
        return success(message)
    }

    private func barterDistance(_ lhs: AgentPosition, _ rhs: AgentPosition) -> Int {
        abs(lhs.x - rhs.x) + abs(lhs.y - rhs.y) + abs(lhs.z - rhs.z)
    }

    private func barterInventoriesEqual(
        _ lhs: [ItemStack?], _ rhs: [ItemStack?]
    ) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).allSatisfy { left, right in
            switch (left, right) {
            case (nil, nil): return true
            case let (left?, right?): return left == right
            default: return false
            }
        }
    }
}
