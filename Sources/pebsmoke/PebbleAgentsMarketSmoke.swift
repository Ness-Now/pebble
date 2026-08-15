import Foundation
import PebbleAgents

private func marketAgent(_ id: String, x: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id, state: "idle", position: position,
        needs: AgentNeeds(
            hunger: 0.3, fatigue: 0.1, curiosity: 0.2, safety: 1
        ), health: 100, fear: 0, homePosition: position,
        nearbyAgents: [], currentGoal: AgentGoal(
            kind: .idle, reason: "local physical market", startedAtTick: 0,
            urgency: 80
        ), lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func marketIdentity(_ item: String) -> AgentMaterialIdentitySnapshot {
    AgentMaterialIdentitySnapshot(
        itemKey: item, damage: 0, enchantments: [], label: nil,
        canonicalDataJSON: "{}"
    )
}

private func marketStack(_ item: String, _ count: Int)
    -> AgentMaterialStackSnapshot {
    AgentMaterialStackSnapshot(identity: marketIdentity(item), count: count)
}

private func marketObservation(
    holder: AgentMaterialPhysicalHolder,
    item: String,
    count: Int,
    fingerprint: String,
    receipt: String,
    tick: Int
) -> AgentMaterialHolderObservation {
    AgentMaterialHolderObservation(
        holder: holder, materialIdentity: marketIdentity(item), quantity: count,
        custodyFingerprint: fingerprint, physicalReceiptID: receipt,
        observedAtTick: tick
    )
}

private func registerMarketAsset(
    _ id: AgentMaterialAssetID,
    owner: AgentID,
    item: String,
    count: Int,
    observation: AgentMaterialHolderObservation,
    witnesses: [AgentID],
    session: inout AgentSimulationSession
) throws {
    let claimID = AgentMaterialClaimID(
        rawValue: "claim:\(id.rawValue):produced"
    )!
    _ = try session.applyMaterialRightsOperation(.register(
        operationID: "rights:\(id.rawValue):register",
        asset: AgentMaterialAssetReference(
            assetID: id, materialIdentity: marketIdentity(item), quantity: count
        ), observation: observation
    ))
    _ = try session.applyMaterialRightsOperation(.assertClaim(
        operationID: "rights:\(id.rawValue):claim", assetID: id,
        claimID: claimID, claimantID: owner, basis: .produced
    ))
    _ = try session.applyMaterialRightsOperation(.recognizeOwnership(
        operationID: "rights:\(id.rawValue):owner", assetID: id,
        claimID: claimID, recognizingAgentIDs: witnesses
    ))
}

private struct MarketFixture {
    var session: AgentSimulationSession
    let marketID: AgentMarketID
    let location: String
    let seller: AgentID
    let buyer: AgentID
    let laterSeller: AgentID
    let pickaxe: AgentMaterialAssetID
    let bread: AgentMaterialAssetID
    let sellerReason: AgentBarterValueReason
    let buyerReason: AgentBarterValueReason
    let pickaxeSource: AgentMaterialHolderObservation
    let breadSource: AgentMaterialHolderObservation
}

private func marketFixture(
    _ simulation: String,
    enableMarket: Bool = true,
    configuration: AgentMarketConfiguration = .live
) -> MarketFixture {
    let seller = AgentID(rawValue: "seller")!
    let buyer = AgentID(rawValue: "buyer")!
    let laterSeller = AgentID(rawValue: "later_seller")!
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 137, memoryPolicy: .bounded(maxEntries: 64)
        ), agents: [
            marketAgent("seller", x: 0), marketAgent("buyer", x: 2),
            marketAgent("later_seller", x: 3),
        ], simulationID: try! AgentSimulationID(validating: simulation),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
    try! session.setProductionEnabled(true)
    let sellerNeed = AgentProductionNeedID(rawValue: "need:seller:bread")!
    let buyerNeed = AgentProductionNeedID(rawValue: "need:buyer:pickaxe")!
    try! session.raiseProductionNeed(
        needID: sellerNeed, actorID: seller, reason: .physicalFoodNeed,
        desiredOutputItemKey: "bread", quantity: 3, priority: 95
    )
    try! session.raiseProductionNeed(
        needID: buyerNeed, actorID: buyer, reason: .missingUsefulTool,
        desiredOutputItemKey: "stone_pickaxe", quantity: 1, priority: 94
    )
    try! session.setMaterialRightsEnabled(true)
    let pickaxe = AgentMaterialAssetID(rawValue: "asset:seller:pickaxe")!
    let bread = AgentMaterialAssetID(rawValue: "asset:buyer:bread2")!
    let pickaxeSource = marketObservation(
        holder: .agent(seller), item: "stone_pickaxe", count: 1,
        fingerprint: "seller:pickaxe", receipt: "observe:seller:pickaxe",
        tick: session.tick
    )
    let breadSource = marketObservation(
        holder: .agent(buyer), item: "bread", count: 2,
        fingerprint: "buyer:bread2", receipt: "observe:buyer:bread2",
        tick: session.tick
    )
    try! registerMarketAsset(
        pickaxe, owner: seller, item: "stone_pickaxe", count: 1,
        observation: pickaxeSource, witnesses: [seller, buyer, laterSeller],
        session: &session
    )
    try! registerMarketAsset(
        bread, owner: buyer, item: "bread", count: 2,
        observation: breadSource, witnesses: [seller, buyer, laterSeller],
        session: &session
    )
    let needs = session.productionSnapshot().needs
    if enableMarket {
        try! session.setMarketEnabled(true, configuration: configuration)
        try! session.registerMarketPlace(
            operationID: "market:register", marketID: AgentMarketID(
                rawValue: "market:central"
            )!, position: AgentPosition(x: 1, y: 64, z: 0),
            containerLocationID: "1,64,0", containerBlockFingerprint: 54,
            interactionRadius: 8, physicalSlotCapacity: 9
        )
    }
    return MarketFixture(
        session: session, marketID: AgentMarketID(rawValue: "market:central")!,
        location: "1,64,0", seller: seller, buyer: buyer,
        laterSeller: laterSeller, pickaxe: pickaxe, bread: bread,
        sellerReason: AgentBarterValueReason(
            need: needs.first { $0.needID == sellerNeed }!
        ), buyerReason: AgentBarterValueReason(
            need: needs.first { $0.needID == buyerNeed }!
        ), pickaxeSource: pickaxeSource, breadSource: breadSource
    )
}

private func initialMarketOpportunity(_ fixture: MarketFixture)
    -> AgentMarketDepositOpportunity {
    AgentMarketDepositOpportunity(
        opportunityID: "market-opportunity:initial",
        marketID: fixture.marketID, sellerID: fixture.seller,
        offered: AgentBarterLeg(
            assetID: fixture.pickaxe, holderID: fixture.seller,
            material: marketStack("stone_pickaxe", 1),
            holderObservation: fixture.pickaxeSource
        ), quoteReason: fixture.sellerReason,
        marketPosition: AgentPosition(x: 1, y: 64, z: 0),
        containerLocationID: fixture.location,
        currentContainerFingerprint: "market:empty", physicalSlotCapacity: 9,
        physicalOccupiedSlots: 0, distance: 1, chunksReady: true,
        observedAtTick: fixture.session.tick,
        expiresAtTick: fixture.session.tick + 2
    )
}

private func depositInitialMarketGood(
    fixture: MarketFixture,
    session: inout AgentSimulationSession
) -> AgentMarketDepositID {
    let opportunity = initialMarketOpportunity(fixture)
    try! session.recordMarketDepositOpportunities([opportunity])
    let proposal = session.nextAutonomousMarketDepositProposal()!
    let marketObservation = marketObservation(
        holder: .container(fixture.location), item: "stone_pickaxe", count: 1,
        fingerprint: "market:pickaxe", receipt: "physical:deposit:pickaxe",
        tick: session.tick
    )
    try! session.applyVerifiedMarketDeposit(AgentVerifiedMarketDeposit(
        operationID: "market:deposit:initial", depositID: proposal.depositID,
        opportunityID: opportunity.opportunityID, marketID: fixture.marketID,
        sellerID: fixture.seller, assetID: fixture.pickaxe,
        material: opportunity.offered.material,
        sourceObservation: fixture.pickaxeSource,
        marketObservation: marketObservation,
        physicalReceiptID: marketObservation.physicalReceiptID,
        completedAtTick: session.tick
    ))
    return proposal.depositID
}

private func createInitialMarketListing(
    session: inout AgentSimulationSession
) -> AgentMarketListing {
    let proposal = session.nextAutonomousMarketListingProposal()!
    try! session.createMarketListing(
        operationID: "market:list:initial", proposal: proposal
    )
    return session.marketSnapshot().listings.first {
        $0.listingID == proposal.listingID
    }!
}

private func negotiateInitialMarketTrade(
    fixture: MarketFixture,
    listing: AgentMarketListing,
    session: inout AgentSimulationSession
) -> AgentMarketProposal {
    let observation = AgentMarketBuyerObservation(
        observationID: "buyer-observation:initial",
        listingID: listing.listingID, buyerID: fixture.buyer,
        consideration: AgentBarterLeg(
            assetID: fixture.bread, holderID: fixture.buyer,
            material: marketStack("bread", 2),
            holderObservation: fixture.breadSource
        ), buyerReason: fixture.buyerReason, distance: 1,
        chunksReady: true, observedAtTick: session.tick
    )
    let buyerProposal = AgentMarketBuyerProposal(
        proposalID: AgentMarketProposalID(rawValue: "proposal:initial")!,
        observation: observation,
        terms: AgentMarketPriceTerms(
            baseItemKey: "stone_pickaxe", quoteItemKey: "bread",
            baseQuantity: 1, quoteQuantity: 2
        ), rejectedAsk: true,
        reason: "buyer rejects ask of three and offers two physical bread"
    )
    try! session.proposeMarketPurchase(
        operationID: "market:proposal:initial", proposal: buyerProposal
    )
    try! session.decideMarketProposal(
        operationID: "market:decision:initial",
        decision: AgentMarketSellerDecision(
            proposalID: buyerProposal.proposalID, sellerID: fixture.seller,
            accept: true,
            reason: "active food need makes two current bread acceptable"
        )
    )
    return session.marketSnapshot().proposals.first {
        $0.proposalID == buyerProposal.proposalID
    }!
}

private func initialMarketTrade(
    fixture: MarketFixture,
    listing: AgentMarketListing,
    proposal: AgentMarketProposal,
    session: AgentSimulationSession,
    operationID: String = "market:trade:initial"
) -> AgentVerifiedMarketTrade {
    let deposit = session.marketSnapshot().deposits.first {
        $0.depositID == listing.depositID
    }!
    return AgentVerifiedMarketTrade(
        operationID: operationID,
        tradeID: AgentMarketTradeID(rawValue: "trade:initial")!,
        marketID: fixture.marketID, listingID: listing.listingID,
        proposalID: proposal.proposalID, sellerID: fixture.seller,
        buyerID: fixture.buyer, terms: proposal.proposedTerms,
        offeredLeg: AgentVerifiedMarketTradeLeg(
            assetID: fixture.pickaxe,
            sourceObservation: deposit.lastMarketObservation,
            destinationObservation: marketObservation(
                holder: .agent(fixture.buyer), item: "stone_pickaxe", count: 1,
                fingerprint: "buyer:bread2:pickaxe",
                receipt: "physical:trade:initial:offered", tick: session.tick
            ), physicalReceiptID: "physical:trade:initial:offered"
        ), considerationLeg: AgentVerifiedMarketTradeLeg(
            assetID: fixture.bread, sourceObservation: fixture.breadSource,
            destinationObservation: marketObservation(
                holder: .agent(fixture.seller), item: "bread", count: 2,
                fingerprint: "seller:bread2",
                receipt: "physical:trade:initial:consideration", tick: session.tick
            ), physicalReceiptID: "physical:trade:initial:consideration"
        ), completedAtTick: session.tick
    )
}

func runPebbleAgentsMarketSmoke() {
    section("CIV-37 physical markets and local price discovery")

    let boundedConfiguration = try! AgentMarketConfiguration(
        maximumDeposits: 2, maximumListings: 2, maximumProposals: 2
    )
    let fixture = marketFixture(
        "civ37-market", configuration: boundedConfiguration
    )
    var session = fixture.session
    let localityBefore = try! session.durableStateBytes()
    let localOpportunity = initialMarketOpportunity(fixture)
    let nonlocalOpportunity = AgentMarketDepositOpportunity(
        opportunityID: "market-opportunity:nonlocal",
        marketID: localOpportunity.marketID,
        sellerID: localOpportunity.sellerID,
        offered: localOpportunity.offered,
        quoteReason: localOpportunity.quoteReason,
        marketPosition: localOpportunity.marketPosition,
        containerLocationID: localOpportunity.containerLocationID,
        currentContainerFingerprint:
            localOpportunity.currentContainerFingerprint,
        physicalSlotCapacity: localOpportunity.physicalSlotCapacity,
        physicalOccupiedSlots: localOpportunity.physicalOccupiedSlots,
        distance: boundedConfiguration.maximumLocalDistance + 1,
        chunksReady: true, observedAtTick: session.tick,
        expiresAtTick: session.tick + 2
    )
    check("nonlocal market discovery is rejected without mutation",
          (try? session.recordMarketDepositOpportunities([
              nonlocalOpportunity,
          ])) == nil && (try! session.durableStateBytes()) == localityBefore)
    let fullMarketOpportunity = AgentMarketDepositOpportunity(
        opportunityID: "market-opportunity:physically-full",
        marketID: localOpportunity.marketID,
        sellerID: localOpportunity.sellerID,
        offered: localOpportunity.offered,
        quoteReason: localOpportunity.quoteReason,
        marketPosition: localOpportunity.marketPosition,
        containerLocationID: localOpportunity.containerLocationID,
        currentContainerFingerprint: "market:physically-full",
        physicalSlotCapacity: localOpportunity.physicalSlotCapacity,
        physicalOccupiedSlots: localOpportunity.physicalSlotCapacity,
        distance: localOpportunity.distance,
        chunksReady: true, observedAtTick: session.tick,
        expiresAtTick: session.tick + 2
    )
    check("physically full market refuses discovery without mutation",
          (try? session.recordMarketDepositOpportunities([
              fullMarketOpportunity,
          ])) == nil && (try! session.durableStateBytes()) == localityBefore)
    let rightsBefore = session.materialRightsSnapshot()
    let depositID = depositInitialMarketGood(fixture: fixture, session: &session)
    let depositedRights = session.materialRightsSnapshot().records.first {
        $0.asset.assetID == fixture.pickaxe
    }!
    check("deposit publishes verified container custody while seller retains ownership",
          depositedRights.lastVerifiedHolder.holder == .container(fixture.location)
            && depositedRights.recognizedOwnership?.ownerID == fixture.seller
            && session.marketSnapshot().deposits.first?.depositID == depositID
            && session.marketSnapshot().priceHistory.isEmpty
            && rightsBefore != session.materialRightsSnapshot())

    let listing = createInitialMarketListing(session: &session)
    check("first local ask has explicit non-inverted rational orientation",
          listing.initialTerms.baseItemKey == "stone_pickaxe"
            && listing.initialTerms.quoteItemKey == "bread"
            && listing.initialTerms.baseQuantity == 1
            && listing.initialTerms.quoteQuantity == 3
            && !listing.historyInformed
            && session.marketSnapshot().priceHistory.isEmpty)

    let openCheckpoint = try! session.makeCheckpoint()
    let openRestored = try! AgentSimulationSession.restoring(openCheckpoint)
    check("schema 34 restart preserves real deposited custody and open listing",
          openCheckpoint.schemaVersion == 34
            && openCheckpoint.schemaVersion == AgentCheckpointSchema.marketVersion
            && openRestored.marketSnapshot().listings.first?.status == .open
            && openRestored.marketSnapshot().deposits.first?
                .lastMarketObservation.holder == .container(fixture.location))
    session = openRestored

    let nonlocalBuyerObservation = AgentMarketBuyerObservation(
        observationID: "buyer-observation:nonlocal",
        listingID: listing.listingID, buyerID: fixture.buyer,
        consideration: AgentBarterLeg(
            assetID: fixture.bread, holderID: fixture.buyer,
            material: marketStack("bread", 2),
            holderObservation: fixture.breadSource
        ), buyerReason: fixture.buyerReason,
        distance: boundedConfiguration.maximumLocalDistance + 1,
        chunksReady: true, observedAtTick: session.tick
    )
    let nonlocalBuyerProposal = AgentMarketBuyerProposal(
        proposalID: AgentMarketProposalID(rawValue: "proposal:nonlocal")!,
        observation: nonlocalBuyerObservation,
        terms: AgentMarketPriceTerms(
            baseItemKey: "stone_pickaxe", quoteItemKey: "bread",
            baseQuantity: 1, quoteQuantity: 2
        ), rejectedAsk: true,
        reason: "nonlocal buyer cannot acquire settlement authority"
    )
    let buyerLocalityBefore = try! session.durableStateBytes()
    check("nonlocal buyer proposal is rejected without mutation",
          (try? session.proposeMarketPurchase(
              operationID: "market:proposal:nonlocal",
              proposal: nonlocalBuyerProposal
          )) == nil
            && (try! session.durableStateBytes()) == buyerLocalityBefore)

    let accepted = negotiateInitialMarketTrade(
        fixture: fixture, listing: listing, session: &session
    )
    check("buyer rejects initial ask and seller explicitly accepts local counteroffer",
          accepted.rejectedAsk && accepted.proposedTerms.quoteQuantity == 2
            && accepted.status == .accepted
            && session.marketSnapshot().listings.first?.revisionCount == 1
            && session.marketSnapshot().priceHistory.isEmpty)

    let outcome = initialMarketTrade(
        fixture: fixture, listing: listing, proposal: accepted, session: session
    )
    let beforeTamper = try! session.durableStateBytes()
    let tampered = AgentVerifiedMarketTrade(
        operationID: "market:trade:tampered", tradeID: outcome.tradeID,
        marketID: outcome.marketID, listingID: outcome.listingID,
        proposalID: outcome.proposalID, sellerID: outcome.sellerID,
        buyerID: outcome.buyerID, terms: outcome.terms,
        offeredLeg: AgentVerifiedMarketTradeLeg(
            assetID: outcome.offeredLeg.assetID,
            sourceObservation: marketObservation(
                holder: .container(fixture.location), item: "stone_pickaxe",
                count: 2, fingerprint: "external-tamper",
                receipt: "external-tamper", tick: session.tick
            ), destinationObservation: outcome.offeredLeg.destinationObservation,
            physicalReceiptID: outcome.offeredLeg.physicalReceiptID
        ), considerationLeg: outcome.considerationLeg,
        completedAtTick: session.tick
    )
    check("external tamper invalidates historical settlement authority",
          (try? session.completeVerifiedMarketTrade(tampered)) == nil
            && (try! session.durableStateBytes()) == beforeTamper
            && session.marketSnapshot().priceHistory.isEmpty)

    try! session.completeVerifiedMarketTrade(outcome)
    let completed = session.marketSnapshot()
    check("completed physical settlement alone creates one local price row",
          completed.totalTradeCount == 1 && completed.tradeRecords.count == 1
            && completed.priceHistory.count == 1
            && completed.priceHistory[0].tradeID == outcome.tradeID
            && completed.priceHistory[0].terms.quoteQuantity == 2
            && completed.priceHistory[0].physicalReceiptIDs.count == 2)
    let rightsAfter = session.materialRightsSnapshot().records
    check("trade reconciles both exact assets, holders and received ownership",
          rightsAfter.first { $0.asset.assetID == fixture.pickaxe }?
            .recognizedOwnership?.ownerID == fixture.buyer
            && rightsAfter.first { $0.asset.assetID == fixture.bread }?
                .recognizedOwnership?.ownerID == fixture.seller)
    let completedBytes = try! session.durableStateBytes()
    try! session.completeVerifiedMarketTrade(outcome)
    check("completed listing cannot double-sell or add another price row",
          (try! session.durableStateBytes()) == completedBytes
            && session.marketSnapshot().priceHistory.count == 1)

    let completedCheckpoint = try! session.makeCheckpoint()
    var restored = try! AgentSimulationSession.restoring(completedCheckpoint)
    check("fresh restart preserves exact completed trade and price provenance",
          restored.marketSnapshot().priceHistory == completed.priceHistory
            && restored.marketSnapshot().tradeRecords == completed.tradeRecords)

    var isolatedMarketSession = restored
    let otherMarketID = AgentMarketID(rawValue: "market:other")!
    try! isolatedMarketSession.registerMarketPlace(
        operationID: "market:register:other", marketID: otherMarketID,
        position: AgentPosition(x: 8, y: 64, z: 0),
        containerLocationID: "8,64,0", containerBlockFingerprint: 55,
        interactionRadius: 8, physicalSlotCapacity: 9
    )
    let isolatedNeedID = AgentProductionNeedID(
        rawValue: "need:later:isolated-bread"
    )!
    try! isolatedMarketSession.raiseProductionNeed(
        needID: isolatedNeedID, actorID: fixture.laterSeller,
        reason: .physicalFoodNeed, desiredOutputItemKey: "bread",
        quantity: 2, priority: 91
    )
    let isolatedAsset = AgentMaterialAssetID(
        rawValue: "asset:later:isolated-pickaxe"
    )!
    let isolatedSource = marketObservation(
        holder: .agent(fixture.laterSeller), item: "stone_pickaxe", count: 1,
        fingerprint: "later:isolated-pickaxe",
        receipt: "observe:later:isolated-pickaxe",
        tick: isolatedMarketSession.tick
    )
    try! registerMarketAsset(
        isolatedAsset, owner: fixture.laterSeller, item: "stone_pickaxe",
        count: 1, observation: isolatedSource,
        witnesses: [fixture.seller, fixture.buyer, fixture.laterSeller],
        session: &isolatedMarketSession
    )
    let isolatedReason = AgentBarterValueReason(
        need: isolatedMarketSession.productionSnapshot().needs.first {
            $0.needID == isolatedNeedID
        }!
    )
    let isolatedOpportunity = AgentMarketDepositOpportunity(
        opportunityID: "market-opportunity:isolated",
        marketID: otherMarketID, sellerID: fixture.laterSeller,
        offered: AgentBarterLeg(
            assetID: isolatedAsset, holderID: fixture.laterSeller,
            material: marketStack("stone_pickaxe", 1),
            holderObservation: isolatedSource
        ), quoteReason: isolatedReason,
        marketPosition: AgentPosition(x: 8, y: 64, z: 0),
        containerLocationID: "8,64,0",
        currentContainerFingerprint: "other-market:empty",
        physicalSlotCapacity: 9, physicalOccupiedSlots: 0, distance: 5,
        chunksReady: true, observedAtTick: isolatedMarketSession.tick,
        expiresAtTick: isolatedMarketSession.tick + 2
    )
    try! isolatedMarketSession.recordMarketDepositOpportunities([
        isolatedOpportunity,
    ])
    let isolatedDepositID = AgentMarketDepositID(rawValue: "deposit:isolated")!
    let isolatedMarketObservation = marketObservation(
        holder: .container("8,64,0"), item: "stone_pickaxe", count: 1,
        fingerprint: "other-market:pickaxe",
        receipt: "physical:deposit:isolated",
        tick: isolatedMarketSession.tick
    )
    try! isolatedMarketSession.applyVerifiedMarketDeposit(
        AgentVerifiedMarketDeposit(
            operationID: "market:deposit:isolated",
            depositID: isolatedDepositID,
            opportunityID: isolatedOpportunity.opportunityID,
            marketID: otherMarketID, sellerID: fixture.laterSeller,
            assetID: isolatedAsset, material: marketStack("stone_pickaxe", 1),
            sourceObservation: isolatedSource,
            marketObservation: isolatedMarketObservation,
            physicalReceiptID: isolatedMarketObservation.physicalReceiptID,
            completedAtTick: isolatedMarketSession.tick
        )
    )
    let isolatedListing = isolatedMarketSession
        .nextAutonomousMarketListingProposal()!
    let isolatedBeforeForgery = try! isolatedMarketSession.durableStateBytes()
    let foreignHistoryListing = AgentMarketListingProposal(
        listingID: isolatedListing.listingID,
        depositID: isolatedListing.depositID,
        sellerID: isolatedListing.sellerID,
        terms: isolatedListing.terms,
        historyTradeIDs: [outcome.tradeID],
        reason: "foreign market history must not cross the physical boundary"
    )
    let foreignHistoryRefused = (try? isolatedMarketSession.createMarketListing(
        operationID: "market:list:isolated:foreign-history",
        proposal: foreignHistoryListing
    )) == nil
        && (try! isolatedMarketSession.durableStateBytes())
            == isolatedBeforeForgery
    try! isolatedMarketSession.createMarketListing(
        operationID: "market:list:isolated", proposal: isolatedListing
    )
    check("completed price history does not transmit to another physical market",
          isolatedListing.historyTradeIDs.isEmpty
            && foreignHistoryRefused
            && isolatedMarketSession.marketSnapshot().listings.first {
                $0.marketID == otherMarketID
            }?.historyInformed == false)

    let laterSeller = fixture.laterSeller
    let laterPickaxe = AgentMaterialAssetID(rawValue: "asset:later:pickaxe")!
    let laterBreadNeed = AgentProductionNeedID(rawValue: "need:later:bread2")!
    let originalSellerNeed = AgentProductionNeedID(rawValue: "need:seller:pickaxe")!
    try! restored.raiseProductionNeed(
        needID: laterBreadNeed, actorID: laterSeller,
        reason: .physicalFoodNeed, desiredOutputItemKey: "bread",
        quantity: 2, priority: 93
    )
    try! restored.raiseProductionNeed(
        needID: originalSellerNeed, actorID: fixture.seller,
        reason: .missingUsefulTool, desiredOutputItemKey: "stone_pickaxe",
        quantity: 1, priority: 92
    )
    let laterSource = marketObservation(
        holder: .agent(laterSeller), item: "stone_pickaxe", count: 1,
        fingerprint: "later:pickaxe", receipt: "observe:later:pickaxe",
        tick: restored.tick
    )
    try! registerMarketAsset(
        laterPickaxe, owner: laterSeller, item: "stone_pickaxe", count: 1,
        observation: laterSource,
        witnesses: [fixture.seller, fixture.buyer, laterSeller], session: &restored
    )
    let laterReason = AgentBarterValueReason(
        need: restored.productionSnapshot().needs.first {
            $0.needID == laterBreadNeed
        }!
    )
    let laterOpportunity = AgentMarketDepositOpportunity(
        opportunityID: "market-opportunity:later", marketID: fixture.marketID,
        sellerID: laterSeller, offered: AgentBarterLeg(
            assetID: laterPickaxe, holderID: laterSeller,
            material: marketStack("stone_pickaxe", 1),
            holderObservation: laterSource
        ), quoteReason: laterReason,
        marketPosition: AgentPosition(x: 1, y: 64, z: 0),
        containerLocationID: fixture.location,
        currentContainerFingerprint: "market:empty:after-trade",
        physicalSlotCapacity: 9, physicalOccupiedSlots: 0, distance: 2,
        chunksReady: true, observedAtTick: restored.tick,
        expiresAtTick: restored.tick + 2
    )
    try! restored.recordMarketDepositOpportunities([laterOpportunity])
    let laterDeposit = AgentMarketDepositID(rawValue: "deposit:later")!
    let laterMarketObservation = marketObservation(
        holder: .container(fixture.location), item: "stone_pickaxe", count: 1,
        fingerprint: "market:later-pickaxe", receipt: "physical:deposit:later",
        tick: restored.tick
    )
    try! restored.applyVerifiedMarketDeposit(AgentVerifiedMarketDeposit(
        operationID: "market:deposit:later", depositID: laterDeposit,
        opportunityID: laterOpportunity.opportunityID,
        marketID: fixture.marketID, sellerID: laterSeller,
        assetID: laterPickaxe, material: marketStack("stone_pickaxe", 1),
        sourceObservation: laterSource,
        marketObservation: laterMarketObservation,
        physicalReceiptID: laterMarketObservation.physicalReceiptID,
        completedAtTick: restored.tick
    ))
    let historyListingProposal = restored.nextAutonomousMarketListingProposal()!
    try! restored.createMarketListing(
        operationID: "market:list:later", proposal: historyListingProposal
    )
    let historyListing = restored.marketSnapshot().listings.first {
        $0.listingID == historyListingProposal.listingID
    }!
    check("post-restart comparable ask uses only restored local completed history",
          historyListing.historyInformed
            && historyListing.historyTradeIDs == [outcome.tradeID]
            && historyListing.currentTerms.quoteQuantity == 2
            && historyListing.currentTerms.baseQuantity == 1)

    let breadNow = restored.materialRightsSnapshot().records.first {
        $0.asset.assetID == fixture.bread
    }!.lastVerifiedHolder
    let laterBuyerReason = AgentBarterValueReason(
        need: restored.productionSnapshot().needs.first {
            $0.needID == originalSellerNeed
        }!
    )
    let laterBuyerProposal = AgentMarketBuyerProposal(
        proposalID: AgentMarketProposalID(rawValue: "proposal:later")!,
        observation: AgentMarketBuyerObservation(
            observationID: "buyer-observation:later",
            listingID: historyListing.listingID, buyerID: fixture.seller,
            consideration: AgentBarterLeg(
                assetID: fixture.bread, holderID: fixture.seller,
                material: marketStack("bread", 2), holderObservation: breadNow
            ), buyerReason: laterBuyerReason, distance: 1, chunksReady: true,
            observedAtTick: restored.tick
        ), terms: historyListing.currentTerms, rejectedAsk: false,
        reason: "buyer accepts restored local comparable price"
    )
    try! restored.proposeMarketPurchase(
        operationID: "market:proposal:later", proposal: laterBuyerProposal
    )
    try! restored.decideMarketProposal(
        operationID: "market:decision:later",
        decision: AgentMarketSellerDecision(
            proposalID: laterBuyerProposal.proposalID, sellerID: laterSeller,
            accept: true, reason: "current need and local history agree"
        )
    )
    let laterTrade = AgentVerifiedMarketTrade(
        operationID: "market:trade:later",
        tradeID: AgentMarketTradeID(rawValue: "trade:later")!,
        marketID: fixture.marketID, listingID: historyListing.listingID,
        proposalID: laterBuyerProposal.proposalID, sellerID: laterSeller,
        buyerID: fixture.seller, terms: historyListing.currentTerms,
        offeredLeg: AgentVerifiedMarketTradeLeg(
            assetID: laterPickaxe, sourceObservation: laterMarketObservation,
            destinationObservation: marketObservation(
                holder: .agent(fixture.seller), item: "stone_pickaxe", count: 1,
                fingerprint: "seller:pickaxe:again",
                receipt: "physical:trade:later:offered", tick: restored.tick
            ), physicalReceiptID: "physical:trade:later:offered"
        ), considerationLeg: AgentVerifiedMarketTradeLeg(
            assetID: fixture.bread, sourceObservation: breadNow,
            destinationObservation: marketObservation(
                holder: .agent(laterSeller), item: "bread", count: 2,
                fingerprint: "later:bread2",
                receipt: "physical:trade:later:consideration", tick: restored.tick
            ), physicalReceiptID: "physical:trade:later:consideration"
        ), completedAtTick: restored.tick
    )
    try! restored.completeVerifiedMarketTrade(laterTrade)
    check("second completed physical trade appends a second pair-local observation",
          restored.marketSnapshot().totalTradeCount == 2
            && restored.marketSnapshot().priceHistory.map(\.tradeID)
                == [outcome.tradeID, laterTrade.tradeID])

    let logAsset = AgentMaterialAssetID(rawValue: "asset:later:log")!
    let ironNeed = AgentProductionNeedID(rawValue: "need:later:iron")!
    try! restored.raiseProductionNeed(
        needID: ironNeed, actorID: laterSeller, reason: .materialWork,
        desiredOutputItemKey: "iron_ingot", quantity: 1, priority: 70
    )
    let logSource = marketObservation(
        holder: .agent(laterSeller), item: "oak_log", count: 1,
        fingerprint: "later:log", receipt: "observe:later:log",
        tick: restored.tick
    )
    try! registerMarketAsset(
        logAsset, owner: laterSeller, item: "oak_log", count: 1,
        observation: logSource,
        witnesses: [fixture.seller, fixture.buyer, laterSeller], session: &restored
    )
    let ironReason = AgentBarterValueReason(
        need: restored.productionSnapshot().needs.first { $0.needID == ironNeed }!
    )
    let logOpportunity = AgentMarketDepositOpportunity(
        opportunityID: "market-opportunity:log", marketID: fixture.marketID,
        sellerID: laterSeller, offered: AgentBarterLeg(
            assetID: logAsset, holderID: laterSeller,
            material: marketStack("oak_log", 1), holderObservation: logSource
        ), quoteReason: ironReason,
        marketPosition: AgentPosition(x: 1, y: 64, z: 0),
        containerLocationID: fixture.location,
        currentContainerFingerprint: "market:empty:after-second",
        physicalSlotCapacity: 9, physicalOccupiedSlots: 0, distance: 2,
        chunksReady: true, observedAtTick: restored.tick,
        expiresAtTick: restored.tick + 2
    )
    try! restored.recordMarketDepositOpportunities([logOpportunity])
    let logDeposit = AgentMarketDepositID(rawValue: "deposit:log")!
    let logMarket = marketObservation(
        holder: .container(fixture.location), item: "oak_log", count: 1,
        fingerprint: "market:log", receipt: "physical:deposit:log",
        tick: restored.tick
    )
    try! restored.applyVerifiedMarketDeposit(AgentVerifiedMarketDeposit(
        operationID: "market:deposit:log", depositID: logDeposit,
        opportunityID: logOpportunity.opportunityID,
        marketID: fixture.marketID, sellerID: laterSeller, assetID: logAsset,
        material: marketStack("oak_log", 1), sourceObservation: logSource,
        marketObservation: logMarket,
        physicalReceiptID: logMarket.physicalReceiptID,
        completedAtTick: restored.tick
    ))
    let logListingProposal = restored.nextAutonomousMarketListingProposal()!
    try! restored.createMarketListing(
        operationID: "market:list:log", proposal: logListingProposal
    )
    let logListing = restored.marketSnapshot().listings.first {
        $0.listingID == logListingProposal.listingID
    }!
    for _ in 0..<restored.marketSnapshot().configuration!.listingLifetimeTicks {
        _ = try! restored.advanceTick()
    }
    try! restored.closeMarketListing(
        operationID: "market:expire:log", listingID: logListing.listingID,
        reason: .expired
    )
    let logReturn = marketObservation(
        holder: .agent(laterSeller), item: "oak_log", count: 1,
        fingerprint: "later:log:return", receipt: "physical:withdraw:log",
        tick: restored.tick
    )
    let refreshedLogMarket = marketObservation(
        holder: .container(fixture.location), item: "oak_log", count: 1,
        fingerprint: "market:log:unrelated-slot-drift",
        receipt: "physical:observe:log:current", tick: restored.tick
    )
    try! restored.completeVerifiedMarketWithdrawal(
        AgentVerifiedMarketWithdrawal(
            operationID: "market:withdraw:log", depositID: logDeposit,
            marketID: fixture.marketID, sellerID: laterSeller,
            assetID: logAsset, sourceObservation: refreshedLogMarket,
            destinationObservation: logReturn,
            physicalReceiptID: logReturn.physicalReceiptID,
            completedAtTick: restored.tick
        )
    )
    check("unsold expiry releases reservation and verified withdrawal returns matter",
          restored.marketSnapshot().deposits.first {
              $0.depositID == logDeposit
          }?.status == .withdrawn
            && restored.materialRightsSnapshot().records.first {
                $0.asset.assetID == logAsset
            }?.lastVerifiedHolder == logReturn
            && restored.marketSnapshot().totalWithdrawalCount == 1)
    check("terminal-only compaction permits bounded lifetime market churn",
          restored.marketSnapshot().totalDepositCount == 3
            && restored.marketSnapshot().deposits.count == 1
            && restored.marketSnapshot().listings.count == 1
            && restored.marketSnapshot().proposals.isEmpty
            && restored.marketSnapshot().priceHistory.count == 2
            && restored.marketSnapshot().evictionCount >= 2)

    let world = try! AgentObserverWorldBinding(
        worldID: "civ37-world", storageIdentity: "memory:civ37",
        seed: 137, dimension: 0, observedWorldTick: restored.tick
    )
    let observerBefore = try! restored.durableStateBytes()
    let observer = restored.observerSnapshot(worldBinding: world)
    check("Observer schema 11 exposes bounded non-authoritative market provenance",
          observer.header.schemaVersion == 11
            && observer.markets?.totalTradeCount == 2
            && observer.markets?.priceHistory.count == 2
            && (try! restored.durableStateBytes()) == observerBefore)

    let finalCheckpoint = try! restored.makeCheckpoint()
    let checkpointData = try! AgentCheckpointCodec.encode(finalCheckpoint)
    var corruptData = checkpointData
    corruptData[corruptData.index(before: corruptData.endIndex)] ^= 0x01
    check("corrupt market checkpoint is refused",
          (try? AgentCheckpointCodec.decode(
              AgentSessionCheckpoint.self, from: corruptData
          )).flatMap { try? AgentSimulationSession.restoring($0) } == nil)

    var replayFixture = marketFixture("civ37-replay", enableMarket: false)
    let replayBase = try! replayFixture.session.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(
        checkpoint: replayBase, session: replayFixture.session
    )
    _ = try! recorder.apply(.setMarketEnabled(
        true, configuration: .live
    ), to: &replayFixture.session)
    _ = try! recorder.apply(.registerMarketPlace(
        operationID: "market:register", marketID: replayFixture.marketID,
        position: AgentPosition(x: 1, y: 64, z: 0),
        containerLocationID: replayFixture.location,
        containerBlockFingerprint: 54, interactionRadius: 8,
        physicalSlotCapacity: 9
    ), to: &replayFixture.session)
    let replayOpportunity = initialMarketOpportunity(replayFixture)
    _ = try! recorder.apply(.recordMarketDepositOpportunities([
        replayOpportunity,
    ]), to: &replayFixture.session)
    let replayDeposit = AgentMarketDepositID(rawValue: "deposit:replay")!
    let replayMarketObservation = marketObservation(
        holder: .container(replayFixture.location), item: "stone_pickaxe",
        count: 1, fingerprint: "market:replay:pickaxe",
        receipt: "physical:deposit:replay", tick: replayFixture.session.tick
    )
    _ = try! recorder.apply(.recordVerifiedMarketDeposit(
        AgentVerifiedMarketDeposit(
            operationID: "market:deposit:replay", depositID: replayDeposit,
            opportunityID: replayOpportunity.opportunityID,
            marketID: replayFixture.marketID, sellerID: replayFixture.seller,
            assetID: replayFixture.pickaxe,
            material: marketStack("stone_pickaxe", 1),
            sourceObservation: replayFixture.pickaxeSource,
            marketObservation: replayMarketObservation,
            physicalReceiptID: replayMarketObservation.physicalReceiptID,
            completedAtTick: replayFixture.session.tick
        )
    ), to: &replayFixture.session)
    let replayListingProposal = replayFixture.session
        .nextAutonomousMarketListingProposal()!
    _ = try! recorder.apply(.createMarketListing(
        operationID: "market:list:replay", proposal: replayListingProposal
    ), to: &replayFixture.session)
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "market-replay")!
    )
    let replayed = try! AgentSessionReplayer.replay(
        checkpoint: replayBase, journal: journal
    )
    check("replay schema 34 reproduces causal deposit and open listing exactly",
          journal.manifest.schemaVersion == 34
            && journal.manifest.schemaVersion == AgentReplaySchema.marketVersion
            && replayed.report.verified
            && replayed.session.marketSnapshot().deposits.count == 1
            && replayed.session.marketSnapshot().listings.count == 1
            && replayed.session.marketSnapshot().priceHistory.isEmpty)
}
