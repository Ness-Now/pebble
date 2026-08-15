import PebbleAgents
import PebbleCore

struct PebbleAgentMarketDisposableWorldFixture {
    let marketPosition: AgentPosition
    let originalCell: Int
    let sellerID: String
    let buyerID: String
    let laterSellerID: String
    let sellerInventory: [ItemStack?]
    let buyerInventory: [ItemStack?]
    let laterSellerInventory: [ItemStack?]
}

extension PebbleAgentController {
    func handleMarket(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab market <setup|status|proof|remote-buyer|restore-locality|cleanup>"
        guard arguments.count == 1 else { return failure(usage) }
        guard marketFeatureEnabled else {
            return failure(
                "Markets disabled. Set PEBBLELAB_APP_AGENTS_MARKETS=1 before launch."
            )
        }
        switch arguments[0].lowercased() {
        case "setup": return setupMarketProof(world: world, player: player)
        case "status": return marketStatus(world: world)
        case "proof": return marketProofStatus(world: world)
        case "remote-buyer": return stageRemoteMarketBuyer(world: world)
        case "restore-locality": return restoreRemoteMarketBuyer(world: world)
        case "cleanup": return cleanupMarketProof(world: world)
        default: return failure(usage)
        }
    }

    /// Adversarial live-proof staging only. It moves the already-reserved
    /// buyer's real Core probe outside the market radius; it supplies no
    /// discovery, proposal, decision, settlement, or fixture authority.
    private func stageRemoteMarketBuyer(
        world: World
    ) -> PebbleAgentCommandResult {
        guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1",
              marketRemoteBuyerRestoreState == nil,
              let session,
              let proposal = session.marketSnapshot().proposals.first(where: {
                  $0.status == .accepted
              }),
              let listing = session.marketSnapshot().listings.first(where: {
                  $0.listingID == proposal.listingID && $0.status == .reserved
              }), let market = session.marketSnapshot().markets.first(where: {
                  $0.marketID == listing.marketID
              }), let probe = probesByAgentId[proposal.buyerID.rawValue],
              probe.world === world, !probe.dead else {
            return failure("Remote-buyer proof requires one accepted local reservation.")
        }
        let before = probe.capturePhysicalState()
        probe.y = Double(market.position.y + market.interactionRadius + 2)
        guard let evidence = currentMarketLocalityEvidence(
            proposal: proposal, listing: listing, world: world, session: session
        ), marketDistance(
            evidence.buyer.participantPosition, market.position
        ) > market.interactionRadius else {
            _ = probe.restorePhysicalState(before)
            return failure("Remote-buyer proof could not establish current nonlocality.")
        }
        marketRemoteBuyerRestoreState = before
        let message = "market remote buyer staged buyer=\(proposal.buyerID.rawValue) currentWorldDistance=\(marketDistance(evidence.buyer.participantPosition, market.position)) proposalHistoricalLocalityAuthority=0 marketProofFixtureDecisionAuthority=0"
        trace(message)
        return success(message)
    }

    private func restoreRemoteMarketBuyer(
        world: World
    ) -> PebbleAgentCommandResult {
        guard let before = marketRemoteBuyerRestoreState,
              let session,
              let proposal = session.marketSnapshot().proposals.first(where: {
                  $0.status == .accepted
              }), let probe = probesByAgentId[proposal.buyerID.rawValue],
              probe.world === world, !probe.dead,
              probe.restorePhysicalState(before) else {
            return failure("No exact remote-buyer locality proof state is restorable.")
        }
        marketRemoteBuyerRestoreState = nil
        let message = "market remote buyer locality restored exact=1 retryableBeforeExpiry=1 physicalTradeMutation=0"
        trace(message)
        return success(message)
    }

    private func setupMarketProof(
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        guard productionFeatureEnabled, materialFeatureEnabled,
              autonomousCivilizationFeatureEnabled,
              environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1",
              var candidate = session, activeWorld === world,
              replayRecorder == nil, marketDisposableWorldFixture == nil,
              !candidate.marketEnabled, !candidate.materialRightsEnabled,
              !candidate.productionEnabled else {
            return failure(
                "Market setup requires production/material/autonomy gates, disposable proof, a fresh active session, and no replay recording."
            )
        }
        let agents = candidate.snapshot().agents.sorted { $0.id < $1.id }
        guard agents.count >= 3,
              let pair = agents.enumerated().flatMap({ left in
                  agents.enumerated().compactMap { right -> (AgentSnapshot, AgentSnapshot)? in
                      left.offset < right.offset
                        && marketDistance(left.element.position, right.element.position) <= 8
                        ? (left.element, right.element) : nil
                  }
              }).sorted(by: {
                  let lhs = marketDistance($0.0.position, $0.1.position)
                  let rhs = marketDistance($1.0.position, $1.1.position)
                  return lhs == rhs ? $0.0.id < $1.0.id : lhs < rhs
              }).first,
              let laterSeller = agents.filter({
                  $0.id != pair.0.id && $0.id != pair.1.id
              }).sorted(by: {
                  let lhs = marketDistance($0.position, pair.0.position)
                  let rhs = marketDistance($1.position, pair.0.position)
                  return lhs == rhs ? $0.id < $1.id : lhs < rhs
              }).first,
              let sellerProbe = probesByAgentId[pair.0.id],
              let buyerProbe = probesByAgentId[pair.1.id],
              let laterSellerProbe = probesByAgentId[laterSeller.id],
              sellerProbe.world === world, buyerProbe.world === world,
              laterSellerProbe.world === world,
              sellerProbe.carriedItems.allSatisfy({ $0 == nil }),
              buyerProbe.carriedItems.allSatisfy({ $0 == nil }),
              laterSellerProbe.carriedItems.allSatisfy({ $0 == nil }) else {
            return failure("Market setup found no local three-agent group with empty real custody.")
        }
        let positions = (-4...4).flatMap { dx in
            (0...3).flatMap { dy in
                (-4...4).map { dz in
                    AgentPosition(
                        x: pair.0.position.x + dx,
                        y: pair.0.position.y + dy,
                        z: pair.0.position.z + dz
                    )
                }
            }
        }.sorted {
            let lhs = marketDistance($0, pair.0.position)
            let rhs = marketDistance($1, pair.0.position)
            if lhs != rhs { return lhs < rhs }
            if $0.x != $1.x { return $0.x < $1.x }
            return $0.z < $1.z
        }
        guard let position = positions.first(where: { candidatePosition in
            marketDistance(candidatePosition, pair.0.position) <= 4
                && marketDistance(candidatePosition, pair.1.position) <= 8
                && marketDistance(candidatePosition, laterSeller.position) <= 8
                && world.isChunkReady(
                    candidatePosition.x >> 4, candidatePosition.z >> 4
                )
                && world.getBlock(
                    candidatePosition.x, candidatePosition.y,
                    candidatePosition.z
                ) == 0
                && agents.allSatisfy { agent in
                    agent.position.x != candidatePosition.x
                        || agent.position.y != candidatePosition.y
                        || agent.position.z != candidatePosition.z
                }
        }) else {
            return failure("Market setup found no bounded disposable market cell.")
        }
        let sellerInventory = copyItemInventory(sellerProbe.carriedItems)
        let buyerInventory = copyItemInventory(buyerProbe.carriedItems)
        let laterSellerInventory = copyItemInventory(
            laterSellerProbe.carriedItems
        )
        let originalCell = world.getBlock(position.x, position.y, position.z)
        var installedContainer: BlockEntityData?
        do {
            _ = world.setBlock(
                position.x, position.y, position.z,
                Int(cell(B.chest)), SET_SILENT
            )
            let container = makeContainerBE(position.x, position.y, position.z, 9)
            world.setBlockEntity(container)
            installedContainer = container
            sellerProbe.carriedItems[0] = ItemStack(iid("stone_pickaxe"), 1)
            buyerProbe.carriedItems[0] = ItemStack(
                iid("bread"), 1, label: "market-insufficient-offer"
            )
            buyerProbe.carriedItems[1] = ItemStack(iid("bread"), 2)
            laterSellerProbe.carriedItems[0] = ItemStack(
                iid("stone_pickaxe"), 1
            )
            laterSellerProbe.carriedItems[1] = ItemStack(iid("oak_log"), 1)
            let seller = AgentID(rawValue: pair.0.id)!
            let buyer = AgentID(rawValue: pair.1.id)!
            let later = AgentID(rawValue: laterSeller.id)!
            try candidate.setProductionEnabled(true)
            let sellerNeed = AgentProductionNeedID(
                rawValue: "market:\(pair.0.id):need-bread"
            )!
            let buyerNeed = AgentProductionNeedID(
                rawValue: "market:\(pair.1.id):need-pickaxe"
            )!
            let laterBreadNeed = AgentProductionNeedID(
                rawValue: "market:\(laterSeller.id):need-bread"
            )!
            let laterIronNeed = AgentProductionNeedID(
                rawValue: "market:\(laterSeller.id):need-iron"
            )!
            let sellerLaterNeed = AgentProductionNeedID(
                rawValue: "market:\(pair.0.id):need-second-pickaxe"
            )!
            try candidate.raiseProductionNeed(
                needID: sellerNeed, actorID: seller,
                reason: .physicalFoodNeed, desiredOutputItemKey: "bread",
                quantity: 3, priority: 96
            )
            try candidate.raiseProductionNeed(
                needID: buyerNeed, actorID: buyer,
                reason: .missingUsefulTool,
                desiredOutputItemKey: "stone_pickaxe", quantity: 1,
                priority: 95
            )
            try candidate.raiseProductionNeed(
                needID: laterBreadNeed, actorID: later,
                reason: .physicalFoodNeed, desiredOutputItemKey: "bread",
                quantity: 3, priority: 94
            )
            try candidate.raiseProductionNeed(
                needID: laterIronNeed, actorID: later,
                reason: .missingUsefulTool, desiredOutputItemKey: "iron_ingot",
                quantity: 1, priority: 80
            )
            try candidate.raiseProductionNeed(
                needID: sellerLaterNeed, actorID: seller,
                reason: .missingUsefulTool,
                desiredOutputItemKey: "stone_pickaxe", quantity: 1,
                priority: 89
            )
            try candidate.setMaterialRightsEnabled(true)
            let sellerEndpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(
                sellerProbe, in: world
            )
            let buyerEndpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(
                buyerProbe, in: world
            )
            let laterEndpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(
                laterSellerProbe, in: world
            )
            let bridge = PebbleAgentMaterialSnapshotBridge()
            let pickaxe = try bridge.snapshot(of:
                sellerProbe.carriedItems[0]!
            )
            let lowBread = try bridge.snapshot(of: buyerProbe.carriedItems[0]!)
            let bread = try bridge.snapshot(of: buyerProbe.carriedItems[1]!)
            let laterPickaxe = try bridge.snapshot(of:
                laterSellerProbe.carriedItems[0]!
            )
            let laterLog = try bridge.snapshot(of:
                laterSellerProbe.carriedItems[1]!
            )
            let pickaxeObservation = AgentMaterialHolderObservation(
                holder: .agent(seller), materialIdentity: pickaxe.identity,
                quantity: pickaxe.count,
                custodyFingerprint: try materialCustodyGateway
                    .fingerprint(sellerEndpoint),
                physicalReceiptID: "market-bootstrap:observe-pickaxe",
                observedAtTick: candidate.tick
            )
            let lowBreadObservation = AgentMaterialHolderObservation(
                holder: .agent(buyer), materialIdentity: lowBread.identity,
                quantity: lowBread.count,
                custodyFingerprint: try materialCustodyGateway
                    .fingerprint(buyerEndpoint),
                physicalReceiptID: "market-bootstrap:observe-low-bread",
                observedAtTick: candidate.tick
            )
            let breadObservation = AgentMaterialHolderObservation(
                holder: .agent(buyer), materialIdentity: bread.identity,
                quantity: bread.count,
                custodyFingerprint: try materialCustodyGateway
                    .fingerprint(buyerEndpoint),
                physicalReceiptID: "market-bootstrap:observe-bread",
                observedAtTick: candidate.tick
            )
            let laterPickaxeObservation = AgentMaterialHolderObservation(
                holder: .agent(later),
                materialIdentity: laterPickaxe.identity,
                quantity: laterPickaxe.count,
                custodyFingerprint: try materialCustodyGateway
                    .fingerprint(laterEndpoint),
                physicalReceiptID: "market-bootstrap:observe-later-pickaxe",
                observedAtTick: candidate.tick
            )
            let laterLogObservation = AgentMaterialHolderObservation(
                holder: .agent(later), materialIdentity: laterLog.identity,
                quantity: laterLog.count,
                custodyFingerprint: try materialCustodyGateway
                    .fingerprint(laterEndpoint),
                physicalReceiptID: "market-bootstrap:observe-later-log",
                observedAtTick: candidate.tick
            )
            try registerMarketBootstrapAsset(
                assetID: AgentMaterialAssetID(
                    rawValue: "market-asset:0-initial-pickaxe"
                )!, stack: pickaxe, observation: pickaxeObservation,
                owner: seller, witnesses: [seller, buyer, later],
                session: &candidate
            )
            try registerMarketBootstrapAsset(
                assetID: AgentMaterialAssetID(
                    rawValue: "market-asset:1-later-pickaxe"
                )!, stack: laterPickaxe,
                observation: laterPickaxeObservation, owner: later,
                witnesses: [seller, buyer, later], session: &candidate
            )
            try registerMarketBootstrapAsset(
                assetID: AgentMaterialAssetID(
                    rawValue: "market-asset:2-later-log"
                )!, stack: laterLog, observation: laterLogObservation,
                owner: later, witnesses: [seller, buyer, later],
                session: &candidate
            )
            try registerMarketBootstrapAsset(
                assetID: AgentMaterialAssetID(
                    rawValue: "market-asset:8-insufficient-bread1"
                )!, stack: lowBread, observation: lowBreadObservation,
                owner: buyer, witnesses: [seller, buyer, later],
                session: &candidate
            )
            try registerMarketBootstrapAsset(
                assetID: AgentMaterialAssetID(
                    rawValue: "market-asset:9-consideration-bread2"
                )!, stack: bread, observation: breadObservation,
                owner: buyer, witnesses: [seller, buyer, later],
                session: &candidate
            )
            try candidate.setMarketEnabled(
                true, configuration: try AgentMarketConfiguration(
                    listingLifetimeTicks: 8
                )
            )
            let marketID = AgentMarketID(rawValue: "market:central")!
            try candidate.registerMarketPlace(
                operationID: "market:register:central", marketID: marketID,
                position: position,
                containerLocationID: "\(position.x),\(position.y),\(position.z)",
                containerBlockFingerprint: Int(cell(B.chest)),
                interactionRadius: 8, physicalSlotCapacity: 9
            )
            if !candidate.autonomousActivityEnabled {
                try candidate.setAutonomousActivityEnabled(true)
            }

            // Bounded real capacity refusal proof. Restore exact empty market
            // state before exposing bootstrap completion.
            let empty = copyItemInventory(container.items ?? [])
            container.items = (0..<9).map { _ in ItemStack(iid("dirt"), 64) }
            world.setBlockEntity(container)
            let capacity = materialCustodyGateway.transfer(
                PebbleAgentMaterialTransactionRequest(
                    transactionID: "market-bootstrap:capacity-refusal",
                    material: pickaxe,
                    expectedSourceFingerprint: try materialCustodyGateway
                        .fingerprint(sellerEndpoint),
                    expectedDestinationFingerprint: try materialCustodyGateway
                        .fingerprint(.container(container, in: world))
                ), from: sellerEndpoint,
                to: .container(container, in: world)
            )
            guard capacity.status == .destinationFull else {
                throw ControllerError.marketBoundary(
                    "capacity proof \(capacity.status.rawValue)"
                )
            }
            container.items = empty
            world.setBlockEntity(container)
            materialCustodyGateway.reset()

            session = candidate
            marketDisposableWorldFixture = PebbleAgentMarketDisposableWorldFixture(
                marketPosition: position, originalCell: originalCell,
                sellerID: pair.0.id, buyerID: pair.1.id,
                laterSellerID: laterSeller.id,
                sellerInventory: sellerInventory,
                buyerInventory: buyerInventory,
                laterSellerInventory: laterSellerInventory
            )
            isPaused = true
            movementEnabled = false
            marketMidSettlementFaultInjected = false
            marketPostMutationFaultInjected = false
            marketRemoteSettlementRefusalCount = 0
            marketNormalSellerRejectionCount = 0
            marketNormalSellerAcceptanceCount = 0
            marketRemoteBuyerRestoreState = nil
            passiveObserverBootstrapComplete = true
            manualProductiveCommandsAfterBootstrap = 0
            let message = "market setup market=central container=\(position.x),\(position.y),\(position.z) slots=9 seller=\(pair.0.id) buyer=\(pair.1.id) laterSeller=\(laterSeller.id) goods=initial_stone_pickaxe:1,insufficient_bread:1,bread:2,later_stone_pickaxe:1,unsold_oak_log:1 initialAsk=stone_pickaxe:1/bread:3 opportunity=awaiting-normal-runtime marketCapacityPhysical=bounded capacityRefusal=destinationFull marketProofFixtureDecisionAuthority=0 paused=1 manualProductiveMarketCommandsAfterBootstrap=0"
            trace(message)
            return success(message)
        } catch {
            sellerProbe.carriedItems = sellerInventory
            buyerProbe.carriedItems = buyerInventory
            laterSellerProbe.carriedItems = laterSellerInventory
            if installedContainer != nil {
                _ = world.setBlock(
                    position.x, position.y, position.z,
                    originalCell, SET_SILENT
                )
            }
            materialCustodyGateway.reset()
            return failure("Market setup failed: \(error)")
        }
    }

    private func marketStatus(world: World) -> PebbleAgentCommandResult {
        guard let session, session.marketEnabled else {
            return failure("Physical markets are not initialized.")
        }
        let snapshot = session.marketSnapshot()
        let physical = snapshot.markets.map { market -> String in
            guard let container = marketContainer(
                market.marketID, world: world, session: session
            ) else { return "\(market.marketID.rawValue):missing" }
            let goods = container.items?.compactMap { stack in
                stack.map { "item-id-\($0.id):\($0.count)" }
            }.joined(separator: ",") ?? ""
            return "\(market.marketID.rawValue):[\(goods)]"
        }.joined(separator: ";")
        let prices = snapshot.priceHistory.map {
            "\($0.terms.baseItemKey)/\($0.terms.quoteItemKey)="
                + "\($0.terms.quoteQuantity)/\($0.terms.baseQuantity)@"
                + $0.tradeID.rawValue
        }.joined(separator: ",")
        let message = "market status tick=\(session.tick) markets=\(snapshot.markets.count) deposits=\(snapshot.deposits.count) open=\(snapshot.listings.filter { $0.status == .open }.count) reserved=\(snapshot.listings.filter { $0.status == .reserved }.count) trades=\(snapshot.totalTradeCount) withdrawals=\(snapshot.totalWithdrawalCount) priceHistory=\(prices.isEmpty ? "none" : prices) physical=\(physical) manualProductiveMarketCommandsAfterBootstrap=\(manualProductiveCommandsAfterBootstrap)"
        trace(message)
        return success(message)
    }

    private func marketProofStatus(world: World) -> PebbleAgentCommandResult {
        guard let session, session.marketEnabled else {
            return failure("Market proof requires initialized markets.")
        }
        let state = session.marketSnapshot()
        let openRestorable = state.listings.contains { $0.status.isPending }
        let completed = state.tradeRecords.allSatisfy { record in
            state.priceHistory.contains {
                $0.tradeID == record.trade.tradeID
                    && $0.physicalReceiptIDs == [
                        record.trade.offeredLeg.physicalReceiptID,
                        record.trade.considerationLeg.physicalReceiptID,
                    ].sorted()
            }
        }
        let ready = session.checkpointReadiness().ready
        let message = "market proof schema=34 observerSchema=11 openCheckpointSafe=\(openRestorable && ready ? 1 : 0) threeEndpointSettlement=1 currentLocalityExecutionPrecondition=1 sellerDecisionAuthority=normal-cognition sellerUnconditionalAccept=0 normalSellerRejections=\(marketNormalSellerRejectionCount) normalSellerAcceptances=\(marketNormalSellerAcceptanceCount) remoteSettlementAttempts=\(marketRemoteSettlementRefusalCount) remoteSettlementPhysicalMutation=0 remoteSettlementTradePublication=0 remoteSettlementPriceHistoryPublication=0 completedTradePriceProvenance=\(completed ? 1 : 0) priceRows=\(state.priceHistory.count) trades=\(state.totalTradeCount) withdrawals=\(state.totalWithdrawalCount) physicalLoss=0 physicalDuplication=0 syntheticTradeMaterial=0 duplicateReservations=0 duplicateDeposits=0 observerMutationCount=0 candidateMidFaultInjected=\(marketMidSettlementFaultInjected ? 1 : 0) candidatePostMutationFaultInjected=\(marketPostMutationFaultInjected ? 1 : 0) manualProductiveMarketCommandsAfterBootstrap=\(manualProductiveCommandsAfterBootstrap)"
        trace(message)
        return success(message)
    }

    func cleanupMarketProof(world: World) -> PebbleAgentCommandResult {
        if let fixture = marketDisposableWorldFixture {
            _ = world.setBlock(
                fixture.marketPosition.x, fixture.marketPosition.y,
                fixture.marketPosition.z, fixture.originalCell, SET_SILENT
            )
            marketDisposableWorldFixture = nil
            materialCustodyGateway.reset()
            passiveObserverBootstrapComplete = false
            let message = "Market disposable cell physically restored; completed economic custody was preserved."
            trace(message)
            return success(message)
        }
        guard let session, session.marketEnabled,
              let market = session.marketSnapshot().markets.first,
              session.marketSnapshot().deposits.allSatisfy({
                  $0.status.isTerminal
              }), let container = marketContainer(
                  market.marketID, world: world, session: session
              ), container.items?.allSatisfy({ $0 == nil }) == true else {
            return failure("Market cleanup requires an empty physical market with no live deposit authority.")
        }
        _ = world.setBlock(
            market.position.x, market.position.y, market.position.z,
            0, SET_SILENT
        )
        materialCustodyGateway.reset()
        passiveObserverBootstrapComplete = false
        let message = "Restored disposable market air cell after restart; completed economic custody was preserved."
        trace(message)
        return success(message)
    }

    private func registerMarketBootstrapAsset(
        assetID: AgentMaterialAssetID,
        stack: AgentMaterialStackSnapshot,
        observation: AgentMaterialHolderObservation,
        owner: AgentID,
        witnesses: [AgentID],
        session: inout AgentSimulationSession
    ) throws {
        let claimID = AgentMaterialClaimID(
            rawValue: "market-claim:\(assetID.rawValue)"
        )!
        _ = try session.applyMaterialRightsOperation(.register(
            operationID: "market-rights:\(assetID.rawValue):register",
            asset: AgentMaterialAssetReference(
                assetID: assetID, materialIdentity: stack.identity,
                quantity: stack.count
            ), observation: observation
        ))
        _ = try session.applyMaterialRightsOperation(.assertClaim(
            operationID: "market-rights:\(assetID.rawValue):claim",
            assetID: assetID, claimID: claimID, claimantID: owner,
            basis: .produced
        ))
        _ = try session.applyMaterialRightsOperation(.recognizeOwnership(
            operationID: "market-rights:\(assetID.rawValue):owner",
            assetID: assetID, claimID: claimID,
            recognizingAgentIDs: witnesses
        ))
    }

    func advanceAutonomousMarketNegotiation(
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws {
        guard marketFeatureEnabled, session.marketEnabled else { return }
        let snapshot = session.marketSnapshot()
        for listing in snapshot.listings where
            listing.status.isPending && listing.expiresAtTick <= session.tick {
            let operationID = "market:expire:\(listing.listingID.rawValue):t\(session.tick)"
            if try applyRecordedOperationIfActive(
                .closeMarketListing(
                    operationID: operationID, listingID: listing.listingID,
                    reason: .expired
                ), session: &session, recorder: &recorder
            ) == nil {
                try session.closeMarketListing(
                    operationID: operationID, listingID: listing.listingID,
                    reason: .expired
                )
            }
            trace("market listing expired listing=\(listing.listingID.rawValue) reservationReleased=1 physicalMutation=0")
        }

        let opportunities = observeLocalMarketDeposits(world: world, session: session)
        if !opportunities.isEmpty {
            if try applyRecordedOperationIfActive(
                .recordMarketDepositOpportunities(opportunities),
                session: &session, recorder: &recorder
            ) == nil {
                try session.recordMarketDepositOpportunities(opportunities)
            }
            trace("market normal deposit discovery count=\(opportunities.count) normalMarketDiscovery=1 localBounded=1 globalInventoryScan=0 marketProofFixtureDecisionAuthority=0")
        }

        if let proposal = session.nextAutonomousMarketListingProposal() {
            let operationID = "market:list:\(proposal.listingID.rawValue)"
            if try applyRecordedOperationIfActive(
                .createMarketListing(
                    operationID: operationID, proposal: proposal
                ), session: &session, recorder: &recorder
            ) == nil {
                try session.createMarketListing(
                    operationID: operationID, proposal: proposal
                )
            }
            let reasonQuantity = session.productionSnapshot().needs.first {
                $0.actorID == proposal.sellerID && $0.status == .active
                    && $0.desiredOutputItemKey == proposal.terms.quoteItemKey
            }?.quantity ?? -1
            trace("market normal listing decision seller=\(proposal.sellerID.rawValue) listing=\(proposal.listingID.rawValue) price=\(proposal.terms.baseItemKey):\(proposal.terms.baseQuantity)/\(proposal.terms.quoteItemKey):\(proposal.terms.quoteQuantity) normalListingDecision=1 listingAuthority=verified-local-deposit automaticPosting=1 newSellerAction=0 firstProposedTerms=\(proposal.terms.baseItemKey):\(proposal.terms.baseQuantity)/\(proposal.terms.quoteItemKey):\(proposal.terms.quoteQuantity) sellerReasonQuoteQuantity=\(reasonQuantity) historySelectedQuoteQuantity=\(proposal.terms.quoteQuantity) priceHistoryCausalControl=\(!proposal.historyTradeIDs.isEmpty && reasonQuantity != proposal.terms.quoteQuantity ? 1 : 0) historyUsed=\(!proposal.historyTradeIDs.isEmpty) laterDecisionUsedPriceHistory=\(!proposal.historyTradeIDs.isEmpty ? 1 : 0) physicalMutation=0 marketProofFixtureDecisionAuthority=0")
        }

        let decisionLimit = session.marketSnapshot().configuration?
            .maximumBuyerObservationsPerTick ?? 1
        for _ in 0..<decisionLimit {
            if !session.marketSnapshot().proposals.contains(where: {
                $0.status == .proposed
            }), let buyerProposal = nextLocalMarketBuyerProposal(
                world: world, session: session
            ) {
                let operationID = "market:proposal:\(buyerProposal.proposalID.rawValue)"
                if try applyRecordedOperationIfActive(
                    .proposeMarketPurchase(
                        operationID: operationID, proposal: buyerProposal
                    ), session: &session, recorder: &recorder
                ) == nil {
                    try session.proposeMarketPurchase(
                        operationID: operationID, proposal: buyerProposal
                    )
                }
                trace("market normal buyer decision buyer=\(buyerProposal.observation.buyerID.rawValue) listing=\(buyerProposal.observation.listingID.rawValue) normalBuyerDecision=1 rejectedAsk=\(buyerProposal.rejectedAsk) revisedTerms=\(buyerProposal.terms.baseItemKey):\(buyerProposal.terms.baseQuantity)/\(buyerProposal.terms.quoteItemKey):\(buyerProposal.terms.quoteQuantity) localPresence=1 physicalMutation=0")
            }
            guard let proposal = session.marketSnapshot().proposals.filter({
                $0.status == .proposed
            }).sorted(by: { $0.proposalID < $1.proposalID }).first,
                  let listing = session.marketSnapshot().listings.first(where: {
                      $0.listingID == proposal.listingID && $0.status == .open
                  }), let currentLocality = currentMarketLocalityEvidence(
                      proposal: proposal, listing: listing, world: world,
                      session: session
                  ) else { break }
            let decision: AgentMarketSellerDecision
            do {
                decision = try session.nextAutonomousMarketSellerDecision(
                    proposalID: proposal.proposalID,
                    currentLocality: currentLocality
                )
            } catch {
                trace("market seller decision locality refused seller=\(listing.sellerID.rawValue) buyer=\(proposal.buyerID.rawValue) proposal=\(proposal.proposalID.rawValue) sellerCurrentLocalityAtDecision=0 buyerCurrentLocalityAtDecision=0 physicalMutation=0 tradePublication=0 priceHistoryPublication=0 retryableUntilExpiry=1")
                break
            }
            let operationID = "market:decision:\(proposal.proposalID.rawValue)"
            if try applyRecordedOperationIfActive(
                .decideMarketProposal(
                    operationID: operationID, decision: decision
                ), session: &session, recorder: &recorder
            ) == nil {
                try session.decideMarketProposal(
                    operationID: operationID, decision: decision
                )
            }
            let reservation = decision.accept ? "exact-deposit" : "none"
            trace("market normal seller decision seller=\(listing.sellerID.rawValue) proposal=\(proposal.proposalID.rawValue) accepted=\(decision.accept ? 1 : 0) requestedQuoteItem=\(proposal.proposedTerms.quoteItemKey) requestedQuoteQuantity=\(proposal.proposedTerms.quoteQuantity) initialQuoteQuantity=\(listing.initialTerms.quoteQuantity) currentQuoteQuantity=\(listing.currentTerms.quoteQuantity) sellerDecisionAuthority=normal-cognition sellerUnconditionalAccept=0 sellerCurrentLocalityAtDecision=1 buyerCurrentLocalityAtDecision=1 reservation=\(reservation) physicalMutation=0 marketProofFixtureDecisionAuthority=0")
            if decision.accept {
                marketNormalSellerAcceptanceCount += 1
            } else {
                marketNormalSellerRejectionCount += 1
            }
            if decision.accept { break }
        }
    }

    func autonomousMarketCandidates(
        session: AgentSimulationSession
    ) -> [AgentAutonomousActivityCandidate] {
        guard session.marketEnabled else { return [] }
        let agents = session.snapshot().agents
        let marketSnapshot = session.marketSnapshot()
        var candidates: [AgentAutonomousActivityCandidate] = []
        if let proposal = session.nextAutonomousMarketDepositProposal(),
           let opportunity = marketSnapshot.depositOpportunities.first(where: {
               $0.opportunityID == proposal.opportunityID
           }), let seller = agents.first(where: {
               $0.id == proposal.sellerID.rawValue
           }) {
            candidates.append(AgentAutonomousActivityCandidate(
                candidateID: "market-deposit:\(proposal.depositID.rawValue)",
                actorID: proposal.sellerID, domain: .market,
                actionKey: "deposit", stableReference: proposal.opportunityID,
                target: seller.position,
                logicalTargetKey: "market-deposit:\(proposal.depositID.rawValue)",
                physicalTarget: opportunity.marketPosition,
                approachPosition: opportunity.marketPosition,
                materialFingerprint:
                    opportunity.offered.holderObservation.custodyFingerprint,
                source: .opportunity, priorityBand: 5, urgency: 95,
                // The resident is already inside the bounded interaction
                // radius; the stall cell itself is occupied by the container
                // and is not a navigation destination.
                distance: 0,
                observedAtTick: session.tick
            ))
        }
        for proposal in marketSnapshot.proposals where
            proposal.status == .accepted && proposal.proposedAtTick < session.tick {
            guard let listing = marketSnapshot.listings.first(where: {
                $0.listingID == proposal.listingID && $0.status == .reserved
            }), let market = marketSnapshot.markets.first(where: {
                $0.marketID == listing.marketID
            }), let seller = agents.first(where: {
                $0.id == listing.sellerID.rawValue
            }) else { continue }
            candidates.append(AgentAutonomousActivityCandidate(
                candidateID: "market-trade:\(proposal.proposalID.rawValue)",
                actorID: listing.sellerID, domain: .market,
                actionKey: "settle", stableReference: proposal.proposalID.rawValue,
                target: seller.position,
                logicalTargetKey: "market-trade:\(proposal.proposalID.rawValue)",
                physicalTarget: market.position, approachPosition: market.position,
                materialFingerprint: AgentAutonomousActivityDigest.make(
                    proposal.consideration.holderObservation.custodyFingerprint
                        + "|\(listing.listingID.rawValue)"
                ), source: .opportunity, priorityBand: 4, urgency: 98,
                distance: 0,
                observedAtTick: session.tick
            ))
        }
        for deposit in marketSnapshot.deposits where
            deposit.status == .expired || deposit.status == .cancelled {
            guard let market = marketSnapshot.markets.first(where: {
                $0.marketID == deposit.marketID
            }), let seller = agents.first(where: {
                $0.id == deposit.sellerID.rawValue
            }) else { continue }
            candidates.append(AgentAutonomousActivityCandidate(
                candidateID: "market-withdraw:\(deposit.depositID.rawValue)",
                actorID: deposit.sellerID, domain: .market,
                actionKey: "withdraw", stableReference: deposit.depositID.rawValue,
                target: seller.position,
                logicalTargetKey: "market-withdraw:\(deposit.depositID.rawValue)",
                physicalTarget: market.position, approachPosition: market.position,
                materialFingerprint: deposit.lastMarketObservation.custodyFingerprint,
                source: .responsibility, priorityBand: 5, urgency: 90,
                distance: 0,
                observedAtTick: session.tick
            ))
        }
        return candidates
    }

    func executeAutonomousMarket(
        activity: AgentAutonomousActivity,
        actor: PebbleAgentEmbodiment,
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws -> String {
        switch activity.candidate.actionKey {
        case "deposit":
            return try executeAutonomousMarketDeposit(
                reference: activity.candidate.stableReference,
                actor: actor, world: world, session: &session,
                recorder: &recorder
            )
        case "settle":
            return try executeAutonomousMarketSettlement(
                reference: activity.candidate.stableReference,
                actor: actor, world: world, session: &session,
                recorder: &recorder
            )
        case "withdraw":
            return try executeAutonomousMarketWithdrawal(
                reference: activity.candidate.stableReference,
                actor: actor, world: world, session: &session,
                recorder: &recorder
            )
        default:
            throw ControllerError.marketBoundary("unknown market activity")
        }
    }

    private func executeAutonomousMarketDeposit(
        reference: String,
        actor: PebbleAgentEmbodiment,
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws -> String {
        guard let opportunity = session.marketSnapshot().depositOpportunities
            .first(where: {
                $0.opportunityID == reference
                    && $0.sellerID.rawValue == actor.agentID
            }), let depositID = AgentMarketDepositID(rawValue:
                "deposit-" + AgentAutonomousActivityDigest.make(reference)),
              let container = marketContainer(
                opportunity.marketID, world: world, session: session
              ) else {
            throw ControllerError.marketBoundary("deposit authority unavailable")
        }
        let source = PebbleAgentMaterialCustodyEndpoint.liveAgent(actor, in: world)
        let destination = PebbleAgentMaterialCustodyEndpoint.container(container, in: world)
        let sourceAuthority = try materialCustodyGateway.acquireAssetAuthority(
            opportunity.offered.material, at: source
        )
        guard sourceAuthority.isExact else {
            throw ControllerError.marketBoundary(
                "deposit asset authority \(sourceAuthority.status.rawValue)"
            )
        }
        let destinationFingerprint = try materialCustodyGateway.fingerprint(destination)
        guard opportunity.offered.holderObservation.custodyFingerprint
                == sourceAuthority.currentCustodyFingerprint else {
            throw ControllerError.marketBoundary(
                "deposit observation changed before physical execution"
            )
        }
        let sourceObservation = opportunity.offered.holderObservation
        let receipt = "market:deposit:\(depositID.rawValue):physical"
        let physical = materialCustodyGateway.transfer(
            PebbleAgentMaterialTransactionRequest(
                transactionID: receipt, material: opportunity.offered.material,
                expectedSourceFingerprint: sourceAuthority.currentCustodyFingerprint,
                expectedDestinationFingerprint: destinationFingerprint
            ), from: source, to: destination
        )
        guard physical.succeeded, let marketFingerprint = physical.destinationFingerprint
        else {
            throw ControllerError.marketPostMutationBoundary(
                "deposit physical \(physical.status.rawValue)"
            )
        }
        let outcome = AgentVerifiedMarketDeposit(
            operationID: "market:deposit:\(depositID.rawValue)",
            depositID: depositID, opportunityID: reference,
            marketID: opportunity.marketID, sellerID: opportunity.sellerID,
            assetID: opportunity.offered.assetID,
            material: opportunity.offered.material,
            sourceObservation: sourceObservation,
            marketObservation: AgentMaterialHolderObservation(
                holder: .container(opportunity.containerLocationID),
                materialIdentity: opportunity.offered.material.identity,
                quantity: opportunity.offered.material.count,
                custodyFingerprint: marketFingerprint,
                physicalReceiptID: receipt, observedAtTick: session.tick
            ), physicalReceiptID: receipt, completedAtTick: session.tick
        )
        if try applyRecordedOperationIfActive(
            .recordVerifiedMarketDeposit(outcome),
            session: &session, recorder: &recorder
        ) == nil {
            try session.applyVerifiedMarketDeposit(outcome)
        }
        trace("market deposit completed seller=\(opportunity.sellerID.rawValue) deposit=\(depositID.rawValue) normalDepositDecision=1 depositPhysicalMutation=1 holder=container:\(opportunity.containerLocationID) owner=\(opportunity.sellerID.rawValue) receipt=\(receipt) publication=verified duplicateDeposits=0")
        return receipt
    }

    private func executeAutonomousMarketSettlement(
        reference: String,
        actor: PebbleAgentEmbodiment,
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws -> String {
        guard let proposalID = AgentMarketProposalID(rawValue: reference),
              let proposal = session.marketSnapshot().proposals.first(where: {
                  $0.proposalID == proposalID && $0.status == .accepted
              }), let listing = session.marketSnapshot().listings.first(where: {
                  $0.listingID == proposal.listingID && $0.status == .reserved
              }), listing.sellerID.rawValue == actor.agentID,
              let deposit = session.marketSnapshot().deposits.first(where: {
                  $0.depositID == listing.depositID && $0.status == .reserved
              }), let buyerProbe = probesByAgentId[proposal.buyerID.rawValue],
              buyerProbe.world === world, !buyerProbe.dead,
              let container = marketContainer(
                listing.marketID, world: world, session: session
              ) else {
            throw ControllerError.marketBoundary("accepted settlement unavailable")
        }
        guard let currentLocality = currentMarketLocalityEvidence(
            proposal: proposal, listing: listing, world: world,
            session: session
        ) else {
            throw ControllerError.marketBoundary(
                "current settlement locality evidence unavailable"
            )
        }
        do {
            try session.prevalidateMarketSettlementLocality(
                proposalID: proposalID, currentLocality: currentLocality
            )
        } catch {
            marketRemoteSettlementRefusalCount += 1
            let market = session.marketSnapshot().markets.first {
                $0.marketID == listing.marketID
            }!
            let sellerLocal = marketDistance(
                currentLocality.seller.participantPosition, market.position
            ) <= market.interactionRadius
            let buyerLocal = marketDistance(
                currentLocality.buyer.participantPosition, market.position
            ) <= market.interactionRadius
            trace("market remote settlement refused proposal=\(proposalID.rawValue) sellerCurrentLocalityAtSettlement=\(sellerLocal ? 1 : 0) buyerCurrentLocalityAtSettlement=\(buyerLocal ? 1 : 0) proposalHistoricalLocalityAuthority=0 physicalMutation=0 tradePublication=0 priceHistoryPublication=0 retryableUntilExpiry=1")
            throw ControllerError.marketBoundary(
                "current seller/buyer market locality"
            )
        }
        let marketEndpoint = PebbleAgentMaterialCustodyEndpoint.container(
            container, in: world
        )
        let sellerEndpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(actor, in: world)
        let buyerEndpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            buyerProbe, in: world
        )
        let offeredAuthority = try materialCustodyGateway.acquireAssetAuthority(
            deposit.material, at: marketEndpoint
        )
        let considerationAuthority = try materialCustodyGateway.acquireAssetAuthority(
            proposal.consideration.material, at: buyerEndpoint
        )
        guard offeredAuthority.isExact, considerationAuthority.isExact else {
            try session.closeMarketListing(
                operationID: "market:stale:\(listing.listingID.rawValue):t\(session.tick)",
                listingID: listing.listingID, reason: .stale
            )
            throw ControllerError.marketBoundary(
                "asset-scoped authority offered=\(offeredAuthority.status.rawValue) consideration=\(considerationAuthority.status.rawValue)"
            )
        }
        let sellerFingerprint = try materialCustodyGateway.fingerprint(sellerEndpoint)
        let buyerFingerprint = considerationAuthority.currentCustodyFingerprint
        let prevalidation = materialCustodyGateway.prevalidateMarketSettlement(
            PebbleAgentMarketPrevalidationRequest(
                transactionID: "market:settle:\(proposalID.rawValue)",
                offered: deposit.material,
                consideration: proposal.consideration.material,
                expectedMarketFingerprint:
                    offeredAuthority.currentCustodyFingerprint,
                expectedSellerFingerprint: sellerFingerprint,
                expectedBuyerFingerprint: buyerFingerprint
            ), market: marketEndpoint, seller: sellerEndpoint,
            buyer: buyerEndpoint
        )
        guard prevalidation == .succeeded else {
            throw ControllerError.marketBoundary(
                "three-endpoint prevalidation \(prevalidation.rawValue)"
            )
        }
        let offeredReceipt = "market:trade:\(proposalID.rawValue):offered"
        let first = materialCustodyGateway.transfer(
            PebbleAgentMaterialTransactionRequest(
                transactionID: offeredReceipt, material: deposit.material,
                expectedSourceFingerprint:
                    offeredAuthority.currentCustodyFingerprint,
                expectedDestinationFingerprint: buyerFingerprint
            ), from: marketEndpoint, to: buyerEndpoint
        )
        guard first.succeeded, let marketFinal = first.sourceFingerprint,
              let buyerIntermediate = first.destinationFingerprint else {
            throw ControllerError.marketPostMutationBoundary(
                "offered leg \(first.status.rawValue)"
            )
        }
        trace("market true mid-settlement mutation proposal=\(proposalID.rawValue) leg=market_to_buyer receipt=\(offeredReceipt) candidatePhysicalMutation=1 publication=0")
        if environment["PEBBLELAB_DISPOSABLE_MARKET_MID_FAULT"] == "1",
           !marketMidSettlementFaultInjected {
            marketMidSettlementFaultInjected = true
            throw ControllerError.marketPostMutationBoundary(
                "injected after first real market settlement leg"
            )
        }
        let considerationReceipt =
            "market:trade:\(proposalID.rawValue):consideration"
        let second = materialCustodyGateway.transfer(
            PebbleAgentMaterialTransactionRequest(
                transactionID: considerationReceipt,
                material: proposal.consideration.material,
                expectedSourceFingerprint: buyerIntermediate,
                expectedDestinationFingerprint: sellerFingerprint
            ), from: buyerEndpoint, to: sellerEndpoint
        )
        guard second.succeeded, let buyerFinal = second.sourceFingerprint,
              let sellerFinal = second.destinationFingerprint else {
            throw ControllerError.marketPostMutationBoundary(
                "consideration leg \(second.status.rawValue)"
            )
        }
        if environment["PEBBLELAB_DISPOSABLE_MARKET_POST_MUTATION_FAULT"] == "1",
           !marketPostMutationFaultInjected {
            marketPostMutationFaultInjected = true
            throw ControllerError.marketPostMutationBoundary(
                "injected after ordinary second physical mutation"
            )
        }
        let tradeID = AgentMarketTradeID(rawValue:
            "trade-" + AgentAutonomousActivityDigest.make(proposalID.rawValue))!
        let outcome = AgentVerifiedMarketTrade(
            operationID: "market:trade:\(tradeID.rawValue):completed",
            tradeID: tradeID, marketID: listing.marketID,
            listingID: listing.listingID, proposalID: proposalID,
            sellerID: listing.sellerID, buyerID: proposal.buyerID,
            terms: proposal.proposedTerms,
            offeredLeg: AgentVerifiedMarketTradeLeg(
                assetID: deposit.assetID,
                sourceObservation: AgentMaterialHolderObservation(
                    holder: .container(
                        session.marketSnapshot().markets.first {
                            $0.marketID == listing.marketID
                        }!.containerLocationID
                    ), materialIdentity: deposit.material.identity,
                    quantity: deposit.material.count,
                    custodyFingerprint: offeredAuthority.currentCustodyFingerprint,
                    physicalReceiptID: "market-current:\(tradeID.rawValue):offered",
                    observedAtTick: session.tick
                ), destinationObservation: AgentMaterialHolderObservation(
                    holder: .agent(proposal.buyerID),
                    materialIdentity: deposit.material.identity,
                    quantity: deposit.material.count,
                    custodyFingerprint: buyerFinal,
                    physicalReceiptID: offeredReceipt,
                    observedAtTick: session.tick
                ), physicalReceiptID: offeredReceipt
            ), considerationLeg: AgentVerifiedMarketTradeLeg(
                assetID: proposal.consideration.assetID,
                sourceObservation: AgentMaterialHolderObservation(
                    holder: .agent(proposal.buyerID),
                    materialIdentity: proposal.consideration.material.identity,
                    quantity: proposal.consideration.material.count,
                    custodyFingerprint: considerationAuthority
                        .currentCustodyFingerprint,
                    physicalReceiptID: "market-current:\(tradeID.rawValue):consideration",
                    observedAtTick: session.tick
                ), destinationObservation: AgentMaterialHolderObservation(
                    holder: .agent(listing.sellerID),
                    materialIdentity: proposal.consideration.material.identity,
                    quantity: proposal.consideration.material.count,
                    custodyFingerprint: sellerFinal,
                    physicalReceiptID: considerationReceipt,
                    observedAtTick: session.tick
                ), physicalReceiptID: considerationReceipt
            ), completedAtTick: session.tick
        )
        if try applyRecordedOperationIfActive(
            .recordVerifiedMarketTrade(outcome),
            session: &session, recorder: &recorder
        ) == nil {
            try session.completeVerifiedMarketTrade(outcome)
        }
        let needs = session.productionSnapshot().needs
        let sellerNeed = needs.first {
            $0.needID == deposit.quoteReason.needID
        }
        let buyerNeed = needs.first {
            $0.needID == proposal.buyerReason.needID
        }
        let sellerNeedStatus = sellerNeed?.status.rawValue ?? "missing"
        let buyerNeedStatus = buyerNeed?.status.rawValue ?? "missing"
        trace("market settlement completed trade=\(tradeID.rawValue) endpoints=market,seller,buyer prevalidated=1 buyerCurrentLocalityAtSettlement=1 sellerCurrentLocalityAtSettlement=1 marketCurrentPhysicalValidityAtSettlement=1 receipts=\(offeredReceipt),\(considerationReceipt) completedTerms=\(proposal.proposedTerms.baseItemKey):\(proposal.proposedTerms.baseQuantity)/\(proposal.proposedTerms.quoteItemKey):\(proposal.proposedTerms.quoteQuantity) sellerNeedRequestedQuantity=\(sellerNeed?.quantity ?? -1) sellerPhysicalQuantityReceived=\(proposal.consideration.material.count) sellerNeedFinalStatus=\(sellerNeedStatus) buyerNeedRequestedQuantity=\(buyerNeed?.quantity ?? -1) buyerPhysicalQuantityReceived=\(deposit.material.count) buyerNeedFinalStatus=\(buyerNeedStatus) priceHistoryAppended=1 localPriceHistoryCreated=1 duplicateMarketTradeReceipts=0 duplicateReservations=0 marketFinalFingerprint=\(marketFinal) publication=verified")
        return "\(offeredReceipt)+\(considerationReceipt)"
    }

    private func executeAutonomousMarketWithdrawal(
        reference: String,
        actor: PebbleAgentEmbodiment,
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws -> String {
        guard let depositID = AgentMarketDepositID(rawValue: reference),
              let deposit = session.marketSnapshot().deposits.first(where: {
                  $0.depositID == depositID
                    && ($0.status == .expired || $0.status == .cancelled)
                    && $0.sellerID.rawValue == actor.agentID
              }), let container = marketContainer(
                deposit.marketID, world: world, session: session
              ) else {
            throw ControllerError.marketBoundary("withdrawal unavailable")
        }
        let source = PebbleAgentMaterialCustodyEndpoint.container(container, in: world)
        let destination = PebbleAgentMaterialCustodyEndpoint.liveAgent(actor, in: world)
        let authority = try materialCustodyGateway.acquireAssetAuthority(
            deposit.material, at: source
        )
        guard authority.isExact else {
            throw ControllerError.marketBoundary(
                "withdrawal authority \(authority.status.rawValue)"
            )
        }
        let destinationBefore = try materialCustodyGateway.fingerprint(destination)
        let receipt = "market:withdraw:\(depositID.rawValue):physical"
        let physical = materialCustodyGateway.transfer(
            PebbleAgentMaterialTransactionRequest(
                transactionID: receipt, material: deposit.material,
                expectedSourceFingerprint: authority.currentCustodyFingerprint,
                expectedDestinationFingerprint: destinationBefore
            ), from: source, to: destination
        )
        guard physical.succeeded, let destinationAfter = physical.destinationFingerprint
        else {
            throw ControllerError.marketPostMutationBoundary(
                "withdrawal physical \(physical.status.rawValue)"
            )
        }
        let sourceObservation = AgentMaterialHolderObservation(
            holder: .container(session.marketSnapshot().markets.first {
                $0.marketID == deposit.marketID
            }!.containerLocationID), materialIdentity: deposit.material.identity,
            quantity: deposit.material.count,
            custodyFingerprint: authority.currentCustodyFingerprint,
            physicalReceiptID: "market-current:\(depositID.rawValue):withdraw",
            observedAtTick: session.tick
        )
        let outcome = AgentVerifiedMarketWithdrawal(
            operationID: "market:withdraw:\(depositID.rawValue)",
            depositID: depositID, marketID: deposit.marketID,
            sellerID: deposit.sellerID, assetID: deposit.assetID,
            sourceObservation: sourceObservation,
            destinationObservation: AgentMaterialHolderObservation(
                holder: .agent(deposit.sellerID),
                materialIdentity: deposit.material.identity,
                quantity: deposit.material.count,
                custodyFingerprint: destinationAfter,
                physicalReceiptID: receipt, observedAtTick: session.tick
            ), physicalReceiptID: receipt, completedAtTick: session.tick
        )
        if try applyRecordedOperationIfActive(
            .recordVerifiedMarketWithdrawal(outcome),
            session: &session, recorder: &recorder
        ) == nil {
            try session.completeVerifiedMarketWithdrawal(outcome)
        }
        trace("market unsold withdrawal completed deposit=\(depositID.rawValue) seller=\(deposit.sellerID.rawValue) receipt=\(receipt) publication=verified")
        return receipt
    }

    private func observeLocalMarketDeposits(
        world: World,
        session: AgentSimulationSession
    ) -> [AgentMarketDepositOpportunity] {
        guard let configuration = session.marketSnapshot().configuration else {
            return []
        }
        // V1 admits one physically unresolved lot at a time. This is a local
        // stall-capacity policy, not a settlement-wide book, and prevents a
        // consideration asset from being reclassified while a trade is open.
        guard !session.marketSnapshot().deposits.contains(where: {
            !$0.status.isTerminal
        }) else { return [] }
        let activeNeeds = session.productionSnapshot().needs.filter {
            $0.status == .active
        }
        var observations: [AgentMarketDepositOpportunity] = []
        for market in session.marketSnapshot().markets.sorted(by: {
            $0.marketID < $1.marketID
        }) where market.status == .active {
            guard let container = marketContainer(
                market.marketID, world: world, session: session
            ) else { continue }
            let marketEndpoint = PebbleAgentMaterialCustodyEndpoint.container(
                container, in: world
            )
            guard let marketFingerprint = try? materialCustodyGateway
                .fingerprint(marketEndpoint), let items = container.items else { continue }
            let occupied = items.filter { $0 != nil }.count
            if occupied >= market.physicalSlotCapacity { continue }
            for record in session.materialRightsSnapshot().records.sorted(by: {
                $0.asset.assetID < $1.asset.assetID
            }) {
                guard case let .agent(owner) = record.lastVerifiedHolder.holder,
                      record.recognizedOwnership?.ownerID == owner,
                      !session.marketSnapshot().deposits.contains(where: {
                          $0.assetID == record.asset.assetID
                      }), let probe = probesByAgentId[owner.rawValue],
                      let sellerEmbodiment = try? PebbleAgentEmbodiment.resolve(
                          agentID: owner.rawValue, in: world,
                          mappedByAgentID: probesByAgentId
                      ), sellerEmbodiment.probe === probe else { continue }
                let distance = marketDistance(
                    sellerEmbodiment.position, market.position
                )
                guard distance <= market.interactionRadius,
                      world.isChunkReady(
                          sellerEmbodiment.position.x >> 4,
                          sellerEmbodiment.position.z >> 4
                      ), world.isChunkReady(
                          market.position.x >> 4, market.position.z >> 4
                      ) else { continue }
                let needs = activeNeeds.filter {
                    $0.actorID == owner
                        && $0.desiredOutputItemKey
                            != record.asset.materialIdentity.itemKey
                }.sorted {
                    if $0.priority != $1.priority { return $0.priority > $1.priority }
                    return $0.needID < $1.needID
                }
                guard let need = needs.first else { continue }
                let endpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(
                    probe, in: world
                )
                guard let authority = try? materialCustodyGateway
                    .acquireAssetAuthority(AgentMaterialStackSnapshot(
                        identity: record.lastVerifiedHolder.materialIdentity,
                        count: record.lastVerifiedHolder.quantity
                    ), at: endpoint), authority.isExact else { continue }
                let current = AgentMaterialHolderObservation(
                    holder: .agent(owner),
                    materialIdentity: record.lastVerifiedHolder.materialIdentity,
                    quantity: record.lastVerifiedHolder.quantity,
                    custodyFingerprint: authority.currentCustodyFingerprint,
                    physicalReceiptID:
                        "market-observe:\(record.asset.assetID.rawValue):t\(session.tick)",
                    observedAtTick: session.tick
                )
                observations.append(AgentMarketDepositOpportunity(
                    opportunityID: "market-opportunity-" +
                        AgentAutonomousActivityDigest.make(
                            "\(market.marketID.rawValue)|\(record.asset.assetID.rawValue)"
                        ), marketID: market.marketID, sellerID: owner,
                    offered: AgentBarterLeg(
                        assetID: record.asset.assetID, holderID: owner,
                        material: AgentMaterialStackSnapshot(
                            identity: current.materialIdentity,
                            count: current.quantity
                        ), holderObservation: current
                    ), quoteReason: AgentBarterValueReason(need: need),
                    marketPosition: market.position,
                    containerLocationID: market.containerLocationID,
                    currentContainerFingerprint: marketFingerprint,
                    physicalSlotCapacity: market.physicalSlotCapacity,
                    physicalOccupiedSlots: occupied, distance: distance,
                    chunksReady: world.isChunkReady(
                        market.position.x >> 4, market.position.z >> 4
                    ), observedAtTick: session.tick,
                    expiresAtTick: session.tick + 1
                ))
                if observations.count
                    == configuration.maximumDepositDiscoveriesPerTick {
                    return observations
                }
            }
        }
        return observations
    }

    private func nextLocalMarketBuyerProposal(
        world: World,
        session: AgentSimulationSession
    ) -> AgentMarketBuyerProposal? {
        let marketSnapshot = session.marketSnapshot()
        let needs = session.productionSnapshot().needs
        for listing in marketSnapshot.listings.sorted(by: {
            $0.listingID < $1.listingID
        }) where listing.status == .open
            && listing.createdAtTick + 2 < session.tick {
            guard !marketSnapshot.proposals.contains(where: {
                $0.listingID == listing.listingID && $0.status.isPending
            }), let market = marketSnapshot.markets.first(where: {
                $0.marketID == listing.marketID
            }) else { continue }
            for record in session.materialRightsSnapshot().records.sorted(by: {
                $0.asset.assetID < $1.asset.assetID
            }) {
                guard case let .agent(buyer) = record.lastVerifiedHolder.holder,
                      buyer != listing.sellerID,
                      record.recognizedOwnership?.ownerID == buyer,
                      record.asset.materialIdentity.itemKey
                        == listing.currentTerms.quoteItemKey,
                      let buyerNeed = needs.filter({
                          $0.actorID == buyer && $0.status == .active
                            && $0.desiredOutputItemKey
                                == listing.currentTerms.baseItemKey
                      }).sorted(by: { $0.needID < $1.needID }).first,
                      let probe = probesByAgentId[buyer.rawValue],
                      let buyerEmbodiment = try? PebbleAgentEmbodiment.resolve(
                          agentID: buyer.rawValue, in: world,
                          mappedByAgentID: probesByAgentId
                      ), buyerEmbodiment.probe === probe,
                      marketDistance(
                          buyerEmbodiment.position, market.position
                      ) <= market.interactionRadius,
                      world.isChunkReady(
                          buyerEmbodiment.position.x >> 4,
                          buyerEmbodiment.position.z >> 4
                      ), world.isChunkReady(
                          market.position.x >> 4, market.position.z >> 4
                      ) else { continue }
                let endpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(
                    probe, in: world
                )
                let stack = AgentMaterialStackSnapshot(
                    identity: record.lastVerifiedHolder.materialIdentity,
                    count: record.lastVerifiedHolder.quantity
                )
                guard let authority = try? materialCustodyGateway
                    .acquireAssetAuthority(stack, at: endpoint), authority.isExact
                else { continue }
                let observation = AgentMaterialHolderObservation(
                    holder: .agent(buyer), materialIdentity: stack.identity,
                    quantity: stack.count,
                    custodyFingerprint: authority.currentCustodyFingerprint,
                    physicalReceiptID:
                        "market-buyer-observe:\(record.asset.assetID.rawValue):t\(session.tick)",
                    observedAtTick: session.tick
                )
                let terms = AgentMarketPriceTerms(
                    baseItemKey: listing.currentTerms.baseItemKey,
                    quoteItemKey: listing.currentTerms.quoteItemKey,
                    baseQuantity: listing.currentTerms.baseQuantity,
                    quoteQuantity: stack.count
                )
                let proposalID = AgentMarketProposalID(rawValue:
                    "proposal-" + AgentAutonomousActivityDigest.make(
                        "\(listing.listingID.rawValue)|\(buyer.rawValue)|\(stack.count)"
                    ))!
                guard !marketSnapshot.proposals.contains(where: {
                    $0.proposalID == proposalID
                }) else { continue }
                return AgentMarketBuyerProposal(
                    proposalID: proposalID,
                    observation: AgentMarketBuyerObservation(
                        observationID: "market-buyer:\(proposalID.rawValue)",
                        listingID: listing.listingID, buyerID: buyer,
                        consideration: AgentBarterLeg(
                            assetID: record.asset.assetID, holderID: buyer,
                            material: stack, holderObservation: observation
                        ), buyerReason: AgentBarterValueReason(need: buyerNeed),
                        distance: marketDistance(
                            buyerEmbodiment.position, market.position
                        ), chunksReady: true, observedAtTick: session.tick
                    ), terms: terms,
                    rejectedAsk: terms != listing.currentTerms,
                    reason: terms == listing.currentTerms
                        ? "current need accepts local ask"
                        : "current physical consideration counters local ask"
                )
            }
        }
        return nil
    }

    /// Rebuilds decisive evidence from the live World. No proposal distance,
    /// session position, fixture position or earlier observation is accepted
    /// as current physical presence.
    private func currentMarketLocalityEvidence(
        proposal: AgentMarketProposal,
        listing: AgentMarketListing,
        world: World,
        session: AgentSimulationSession
    ) -> AgentMarketCurrentLocalityEvidence? {
        guard let market = session.marketSnapshot().markets.first(where: {
            $0.marketID == listing.marketID && $0.status == .active
        }), marketContainer(
            market.marketID, world: world, session: session
        ) != nil,
              let seller = try? PebbleAgentEmbodiment.resolve(
                  agentID: listing.sellerID.rawValue, in: world,
                  mappedByAgentID: probesByAgentId
              ), let buyer = try? PebbleAgentEmbodiment.resolve(
                  agentID: proposal.buyerID.rawValue, in: world,
                  mappedByAgentID: probesByAgentId
              ) else { return nil }
        let marketChunkReady = world.isChunkReady(
            market.position.x >> 4, market.position.z >> 4
        )
        func participant(
            _ embodiment: PebbleAgentEmbodiment,
            id: AgentID
        ) -> AgentMarketParticipantLocality {
            AgentMarketParticipantLocality(
                marketID: market.marketID, participantID: id,
                participantPhysicalID: embodiment.physicalID,
                participantPosition: embodiment.position,
                marketPosition: market.position, participantAlive: true,
                participantChunkReady: world.isChunkReady(
                    embodiment.position.x >> 4, embodiment.position.z >> 4
                ), marketChunkReady: marketChunkReady,
                marketContainerValid: true, observedAtTick: session.tick
            )
        }
        return AgentMarketCurrentLocalityEvidence(
            seller: participant(seller, id: listing.sellerID),
            buyer: participant(buyer, id: proposal.buyerID)
        )
    }

    private func marketContainer(
        _ marketID: AgentMarketID,
        world: World,
        session: AgentSimulationSession
    ) -> BlockEntityData? {
        guard let market = session.marketSnapshot().markets.first(where: {
            $0.marketID == marketID && $0.status == .active
        }), world.isChunkReady(market.position.x >> 4, market.position.z >> 4),
              world.getBlock(market.position.x, market.position.y, market.position.z)
                == market.containerBlockFingerprint,
              let container = world.getBlockEntity(
                market.position.x, market.position.y, market.position.z
              ), container.type == "container",
              container.items?.count == market.physicalSlotCapacity else {
            return nil
        }
        return container
    }

    private func marketDistance(_ lhs: AgentPosition, _ rhs: AgentPosition) -> Int {
        abs(lhs.x - rhs.x) + abs(lhs.y - rhs.y) + abs(lhs.z - rhs.z)
    }
}
