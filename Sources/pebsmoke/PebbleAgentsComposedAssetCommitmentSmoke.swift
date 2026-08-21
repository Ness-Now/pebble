import Foundation
import PebbleAgents

private func b04Agent(_ id: String, x: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id, state: "idle", position: position,
        needs: AgentNeeds(
            hunger: 0.4, fatigue: 0.1, curiosity: 0.2, safety: 1
        ), health: 100, fear: 0, homePosition: position,
        nearbyAgents: [], currentGoal: AgentGoal(
            kind: .idle, reason: "composed exact-asset commitment",
            startedAtTick: 0, urgency: 90
        ), lastAction: nil, lastActionEffect: nil, memory: [],
        tickCreated: 0, ticksAlive: 0, observationCount: 0,
        nearbyObservationCount: 0, goalSelectionCount: 0,
        goalChangeCount: 0, actionCount: 0, actionEffectCount: 0,
        movementCount: 0, totalManhattanDistanceMoved: 0,
        returnHomeMoveCount: 0, totalDistanceReducedTowardHome: 0
    )
}

private func b04Identity(_ item: String) -> AgentMaterialIdentitySnapshot {
    AgentMaterialIdentitySnapshot(
        itemKey: item, damage: 0, enchantments: [], label: nil,
        canonicalDataJSON: "{}"
    )
}

private func b04Stack(_ item: String, _ count: Int)
    -> AgentMaterialStackSnapshot {
    AgentMaterialStackSnapshot(identity: b04Identity(item), count: count)
}

private func b04Observation(
    holder: AgentMaterialPhysicalHolder,
    stack: AgentMaterialStackSnapshot,
    fingerprint: String,
    receipt: String,
    tick: Int
) -> AgentMaterialHolderObservation {
    AgentMaterialHolderObservation(
        holder: holder, materialIdentity: stack.identity,
        quantity: stack.count, custodyFingerprint: fingerprint,
        physicalReceiptID: receipt, observedAtTick: tick
    )
}

private func b04Register(
    assetID: AgentMaterialAssetID,
    owner: AgentID,
    stack: AgentMaterialStackSnapshot,
    observation: AgentMaterialHolderObservation,
    witnesses: [AgentID],
    session: inout AgentSimulationSession
) throws {
    let claimID = AgentMaterialClaimID(
        rawValue: "b04-claim:\(assetID.rawValue)"
    )!
    _ = try session.applyMaterialRightsOperation(.register(
        operationID: "b04-rights:\(assetID.rawValue):register",
        asset: AgentMaterialAssetReference(
            assetID: assetID, materialIdentity: stack.identity,
            quantity: stack.count
        ), observation: observation
    ))
    _ = try session.applyMaterialRightsOperation(.assertClaim(
        operationID: "b04-rights:\(assetID.rawValue):claim",
        assetID: assetID, claimID: claimID, claimantID: owner,
        basis: .produced
    ))
    _ = try session.applyMaterialRightsOperation(.recognizeOwnership(
        operationID: "b04-rights:\(assetID.rawValue):owner",
        assetID: assetID, claimID: claimID,
        recognizingAgentIDs: witnesses
    ))
}

private struct B04Fixture {
    var session: AgentSimulationSession
    let seller: AgentID
    let buyer: AgentID
    let merchant: AgentID
    let marketID: AgentMarketID
    let marketLocation: String
    let pickaxe: AgentMaterialAssetID
    let bread1: AgentMaterialAssetID
    let bread2: AgentMaterialAssetID
    let log: AgentMaterialAssetID
    let pickaxeStack: AgentMaterialStackSnapshot
    let bread1Stack: AgentMaterialStackSnapshot
    let bread2Stack: AgentMaterialStackSnapshot
    let logStack: AgentMaterialStackSnapshot
    let pickaxeSource: AgentMaterialHolderObservation
    let bread1Source: AgentMaterialHolderObservation
    let bread2Source: AgentMaterialHolderObservation
    let logSource: AgentMaterialHolderObservation
    let sellerBread1Reason: AgentBarterValueReason
    let sellerBread2Reason: AgentBarterValueReason
    let sellerLogReason: AgentBarterValueReason
    let buyerPickaxeReason: AgentBarterValueReason
    let buyerLogReason: AgentBarterValueReason
    let merchantBread3Reason: AgentBarterValueReason
}

private func b04Fixture(_ simulationID: String) -> B04Fixture {
    let seller = AgentID(rawValue: "seller")!
    let buyer = AgentID(rawValue: "buyer")!
    let merchant = AgentID(rawValue: "merchant")!
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 404, memoryPolicy: .bounded(maxEntries: 64)
        ), agents: [
            b04Agent("seller", x: 0), b04Agent("buyer", x: 2),
            b04Agent("merchant", x: 3),
        ], simulationID: try! AgentSimulationID(validating: simulationID),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
    try! session.setProductionEnabled(true)
    let needs: [(String, AgentID, AgentProductionNeedReason, String, Int, Int)] = [
        ("b04-need:seller:bread1", seller, .physicalFoodNeed, "bread", 1, 97),
        ("b04-need:seller:bread2", seller, .physicalFoodNeed, "bread", 2, 96),
        ("b04-need:seller:log", seller, .materialWork, "oak_log", 1, 95),
        ("b04-need:buyer:pickaxe", buyer, .missingUsefulTool,
            "stone_pickaxe", 1, 94),
        ("b04-need:buyer:log", buyer, .materialWork, "oak_log", 1, 93),
        ("b04-need:merchant:bread3", merchant, .physicalFoodNeed,
            "bread", 3, 92),
    ]
    for (id, actor, reason, item, quantity, priority) in needs {
        try! session.raiseProductionNeed(
            needID: AgentProductionNeedID(rawValue: id)!, actorID: actor,
            reason: reason, desiredOutputItemKey: item,
            quantity: quantity, priority: priority
        )
    }
    try! session.setMaterialRightsEnabled(true)
    let pickaxe = AgentMaterialAssetID(rawValue: "b04-asset:pickaxe")!
    let bread1 = AgentMaterialAssetID(rawValue: "b04-asset:bread1")!
    let bread2 = AgentMaterialAssetID(rawValue: "b04-asset:bread2")!
    let log = AgentMaterialAssetID(rawValue: "b04-asset:log")!
    let pickaxeStack = b04Stack("stone_pickaxe", 1)
    let bread1Stack = b04Stack("bread", 1)
    let bread2Stack = b04Stack("bread", 2)
    let logStack = b04Stack("oak_log", 1)
    let pickaxeSource = b04Observation(
        holder: .agent(seller), stack: pickaxeStack,
        fingerprint: "b04-seller-pickaxe", receipt: "b04-observe-pickaxe",
        tick: session.tick
    )
    let bread1Source = b04Observation(
        holder: .agent(buyer), stack: bread1Stack,
        fingerprint: "b04-buyer-bread1", receipt: "b04-observe-bread1",
        tick: session.tick
    )
    let bread2Source = b04Observation(
        holder: .agent(buyer), stack: bread2Stack,
        fingerprint: "b04-buyer-bread2", receipt: "b04-observe-bread2",
        tick: session.tick
    )
    let logSource = b04Observation(
        holder: .agent(merchant), stack: logStack,
        fingerprint: "b04-merchant-log", receipt: "b04-observe-log",
        tick: session.tick
    )
    let witnesses = [seller, buyer, merchant]
    try! b04Register(
        assetID: pickaxe, owner: seller, stack: pickaxeStack,
        observation: pickaxeSource, witnesses: witnesses, session: &session
    )
    try! b04Register(
        assetID: bread1, owner: buyer, stack: bread1Stack,
        observation: bread1Source, witnesses: witnesses, session: &session
    )
    try! b04Register(
        assetID: bread2, owner: buyer, stack: bread2Stack,
        observation: bread2Source, witnesses: witnesses, session: &session
    )
    try! b04Register(
        assetID: log, owner: merchant, stack: logStack,
        observation: logSource, witnesses: witnesses, session: &session
    )
    try! session.setBarterEnabled(true)
    try! session.setContractsEnabled(true)
    try! session.setMarketEnabled(true)
    let marketID = AgentMarketID(rawValue: "b04-market:central")!
    let marketLocation = "1,64,0"
    try! session.registerMarketPlace(
        operationID: "b04-market:register", marketID: marketID,
        position: AgentPosition(x: 1, y: 64, z: 0),
        containerLocationID: marketLocation,
        containerBlockFingerprint: 54, interactionRadius: 8,
        physicalSlotCapacity: 9
    )
    let snapshot = session.productionSnapshot()
    func reason(_ id: String) -> AgentBarterValueReason {
        AgentBarterValueReason(need: snapshot.needs.first {
            $0.needID.rawValue == id
        }!)
    }
    return B04Fixture(
        session: session, seller: seller, buyer: buyer, merchant: merchant,
        marketID: marketID, marketLocation: marketLocation,
        pickaxe: pickaxe, bread1: bread1, bread2: bread2, log: log,
        pickaxeStack: pickaxeStack, bread1Stack: bread1Stack,
        bread2Stack: bread2Stack, logStack: logStack,
        pickaxeSource: pickaxeSource, bread1Source: bread1Source,
        bread2Source: bread2Source, logSource: logSource,
        sellerBread1Reason: reason("b04-need:seller:bread1"),
        sellerBread2Reason: reason("b04-need:seller:bread2"),
        sellerLogReason: reason("b04-need:seller:log"),
        buyerPickaxeReason: reason("b04-need:buyer:pickaxe"),
        buyerLogReason: reason("b04-need:buyer:log"),
        merchantBread3Reason: reason("b04-need:merchant:bread3")
    )
}

private func b04ContractOpportunity(
    _ id: String,
    consideration: AgentBarterLeg,
    promisor: AgentID,
    promisee: AgentID,
    promisorReason: AgentBarterValueReason,
    promiseeReason: AgentBarterValueReason,
    promised: AgentMaterialStackSnapshot,
    session: AgentSimulationSession
) -> AgentContractOpportunityObservation {
    AgentContractOpportunityObservation(
        opportunityID: id, promisorID: promisor, promiseeID: promisee,
        consideration: consideration, promisorReason: promisorReason,
        promiseeReason: promiseeReason,
        promisedPerformance: AgentContractPerformanceTerms(material: promised),
        distance: 2, lineOfSight: true, chunksReady: true,
        observedAtTick: session.tick,
        expiresAtTick: session.tick
            + session.contractSnapshot().configuration!.proposalLifetimeTicks
    )
}

private func b04CreateContract(
    _ opportunity: AgentContractOpportunityObservation,
    proposalID: AgentPromiseProposalID,
    session: inout AgentSimulationSession
) throws {
    try session.recordContractOpportunity(opportunity)
    try session.createPromiseProposal(
        proposalID: proposalID, opportunityID: opportunity.opportunityID,
        promisorID: opportunity.promisorID
    )
}

private func b04BarterOpportunity(
    _ id: String,
    offered: AgentBarterLeg,
    requested: AgentBarterLeg,
    offeror: AgentID,
    counterparty: AgentID,
    offerorReason: AgentBarterValueReason,
    counterpartyReason: AgentBarterValueReason,
    session: AgentSimulationSession
) -> AgentBarterOpportunityObservation {
    AgentBarterOpportunityObservation(
        opportunityID: id, offerorID: offeror,
        counterpartyID: counterparty, offered: offered,
        requested: requested, offerorReason: offerorReason,
        counterpartyReason: counterpartyReason, distance: 2,
        lineOfSight: true, chunksReady: true, observedAtTick: session.tick,
        expiresAtTick: session.tick
            + session.barterSnapshot().configuration!.offerLifetimeTicks
    )
}

private func b04CreateBarter(
    _ opportunity: AgentBarterOpportunityObservation,
    offerID: AgentBarterOfferID,
    session: inout AgentSimulationSession
) throws {
    try session.recordBarterOpportunity(opportunity)
    try session.createBarterOffer(
        offerID: offerID, opportunityID: opportunity.opportunityID,
        actorID: opportunity.offerorID
    )
}

private func b04MarketOpportunity(
    _ id: String,
    fixture: B04Fixture,
    seller: AgentID,
    assetID: AgentMaterialAssetID,
    stack: AgentMaterialStackSnapshot,
    source: AgentMaterialHolderObservation,
    reason: AgentBarterValueReason,
    session: AgentSimulationSession
) -> AgentMarketDepositOpportunity {
    AgentMarketDepositOpportunity(
        opportunityID: id, marketID: fixture.marketID,
        sellerID: seller, offered: AgentBarterLeg(
            assetID: assetID, holderID: seller, material: stack,
            holderObservation: source
        ), quoteReason: reason,
        marketPosition: AgentPosition(x: 1, y: 64, z: 0),
        containerLocationID: fixture.marketLocation,
        currentContainerFingerprint: "b04-market-empty",
        physicalSlotCapacity: 9, physicalOccupiedSlots: 0,
        distance: 2, chunksReady: true, observedAtTick: session.tick,
        expiresAtTick: session.tick + 2
    )
}

private func b04ApplyDeposit(
    opportunity: AgentMarketDepositOpportunity,
    depositID: AgentMarketDepositID,
    fixture: B04Fixture,
    session: inout AgentSimulationSession
) throws {
    let marketObservation = b04Observation(
        holder: .container(fixture.marketLocation),
        stack: opportunity.offered.material,
        fingerprint: "b04-market:\(depositID.rawValue)",
        receipt: "b04-deposit:\(depositID.rawValue)", tick: session.tick
    )
    try session.applyVerifiedMarketDeposit(AgentVerifiedMarketDeposit(
        operationID: "b04-deposit:\(depositID.rawValue)",
        depositID: depositID, opportunityID: opportunity.opportunityID,
        marketID: fixture.marketID, sellerID: opportunity.sellerID,
        assetID: opportunity.offered.assetID,
        material: opportunity.offered.material,
        sourceObservation: opportunity.offered.holderObservation,
        marketObservation: marketObservation,
        physicalReceiptID: marketObservation.physicalReceiptID,
        completedAtTick: session.tick
    ))
}

private func b04DepositAndListLog(
    fixture: B04Fixture,
    session: inout AgentSimulationSession
) -> AgentMarketListing {
    let opportunity = b04MarketOpportunity(
        "b04-market-opportunity:log", fixture: fixture,
        seller: fixture.merchant, assetID: fixture.log,
        stack: fixture.logStack, source: fixture.logSource,
        reason: fixture.merchantBread3Reason, session: session
    )
    try! session.recordMarketDepositOpportunities([opportunity])
    let depositProposal = session.nextAutonomousMarketDepositProposal()!
    try! b04ApplyDeposit(
        opportunity: opportunity, depositID: depositProposal.depositID,
        fixture: fixture, session: &session
    )
    let listingProposal = session.nextAutonomousMarketListingProposal()!
    try! session.createMarketListing(
        operationID: "b04-market:list-log", proposal: listingProposal
    )
    return session.marketSnapshot().listings.first {
        $0.listingID == listingProposal.listingID
    }!
}

private func b04BuyerProposal(
    _ id: String,
    listing: AgentMarketListing,
    buyer: AgentID,
    assetID: AgentMaterialAssetID,
    stack: AgentMaterialStackSnapshot,
    source: AgentMaterialHolderObservation,
    reason: AgentBarterValueReason,
    session: AgentSimulationSession
) -> AgentMarketBuyerProposal {
    AgentMarketBuyerProposal(
        proposalID: AgentMarketProposalID(rawValue: id)!,
        observation: AgentMarketBuyerObservation(
            observationID: "b04-observe:\(id)", listingID: listing.listingID,
            buyerID: buyer, consideration: AgentBarterLeg(
                assetID: assetID, holderID: buyer, material: stack,
                holderObservation: source
            ), buyerReason: reason, distance: 1, chunksReady: true,
            observedAtTick: session.tick
        ), terms: AgentMarketPriceTerms(
            baseItemKey: listing.currentTerms.baseItemKey,
            quoteItemKey: listing.currentTerms.quoteItemKey,
            baseQuantity: listing.currentTerms.baseQuantity,
            quoteQuantity: stack.count
        ), rejectedAsk: stack.count != listing.currentTerms.quoteQuantity,
        reason: "bounded local buyer proposal"
    )
}

private func b04Locality(
    fixture: B04Fixture,
    proposal: AgentMarketBuyerProposal,
    session: AgentSimulationSession
) -> AgentMarketCurrentLocalityEvidence {
    func participant(
        _ id: AgentID, _ position: AgentPosition
    ) -> AgentMarketParticipantLocality {
        AgentMarketParticipantLocality(
            marketID: fixture.marketID, participantID: id,
            participantPhysicalID: "b04-physical:\(id.rawValue)",
            participantPosition: position,
            marketPosition: AgentPosition(x: 1, y: 64, z: 0),
            participantAlive: true, participantChunkReady: true,
            marketChunkReady: true, marketContainerValid: true,
            observedAtTick: session.tick
        )
    }
    return AgentMarketCurrentLocalityEvidence(
        seller: participant(
            fixture.merchant, AgentPosition(x: 3, y: 64, z: 0)
        ), buyer: participant(
            proposal.observation.buyerID, AgentPosition(x: 2, y: 64, z: 0)
        )
    )
}

private func b04SuccessfulBarter(
    offerID: AgentBarterOfferID,
    opportunity: AgentBarterOpportunityObservation,
    session: AgentSimulationSession
) -> AgentVerifiedBarterOutcome {
    AgentVerifiedBarterOutcome(
        operationID: "b04-barter:\(offerID.rawValue):completed",
        offerID: offerID,
        offeredLeg: AgentVerifiedBarterLeg(
            assetID: opportunity.offered.assetID,
            sourceObservation: opportunity.offered.holderObservation,
            destinationObservation: b04Observation(
                holder: .agent(opportunity.counterpartyID),
                stack: opportunity.offered.material,
                fingerprint: "b04-barter-destination-offered",
                receipt: "b04-barter-receipt-offered", tick: session.tick
            ), physicalReceiptID: "b04-barter-receipt-offered"
        ), requestedLeg: AgentVerifiedBarterLeg(
            assetID: opportunity.requested.assetID,
            sourceObservation: opportunity.requested.holderObservation,
            destinationObservation: b04Observation(
                holder: .agent(opportunity.offerorID),
                stack: opportunity.requested.material,
                fingerprint: "b04-barter-destination-requested",
                receipt: "b04-barter-receipt-requested", tick: session.tick
            ), physicalReceiptID: "b04-barter-receipt-requested"
        ), completedAtTick: session.tick
    )
}

func runPebbleAgentsComposedAssetCommitmentSmoke() {
    section("Gate E Blocker 04 composed exact-asset commitment authority")

    // Evaluation 04 exact seam: contract first, market deposit second.
    var evaluation = b04Fixture("gate-e-blocker-04-evaluation-regression")
    let pickaxeLeg = AgentBarterLeg(
        assetID: evaluation.pickaxe, holderID: evaluation.seller,
        material: evaluation.pickaxeStack,
        holderObservation: evaluation.pickaxeSource
    )
    let contractOpportunity = b04ContractOpportunity(
        "b04-contract-opportunity:pickaxe", consideration: pickaxeLeg,
        promisor: evaluation.buyer, promisee: evaluation.seller,
        promisorReason: evaluation.buyerPickaxeReason,
        promiseeReason: evaluation.sellerLogReason,
        promised: evaluation.logStack, session: evaluation.session
    )
    let contractProposalID = AgentPromiseProposalID(
        rawValue: "b04-contract:pickaxe"
    )!
    try! b04CreateContract(
        contractOpportunity, proposalID: contractProposalID,
        session: &evaluation.session
    )
    check("open contract acquires one exact consideration commitment",
          evaluation.session.exactAssetCommitmentSnapshot().filter {
              $0.assetID == evaluation.pickaxe
          } == [AgentExactAssetCommitment(
              assetID: evaluation.pickaxe, domain: .contract,
              logicalOperationID: "contract:\(contractProposalID.rawValue)",
              role: .contractConsideration
          )])
    let conflictingDeposit = b04MarketOpportunity(
        "b04-market-opportunity:conflicting-pickaxe", fixture: evaluation,
        seller: evaluation.seller, assetID: evaluation.pickaxe,
        stack: evaluation.pickaxeStack, source: evaluation.pickaxeSource,
        reason: evaluation.sellerBread2Reason, session: evaluation.session
    )
    try! evaluation.session.recordMarketDepositOpportunities([
        conflictingDeposit,
    ])
    check("contract commitment filters ordinary market deposit selection",
          evaluation.session.nextAutonomousMarketDepositProposal() == nil)
    let beforeConflict = try! evaluation.session.durableStateBytes()
    let conflictingDepositID = AgentMarketDepositID(
        rawValue: "b04-deposit:conflicting-pickaxe"
    )!
    check("Evaluation 04 market deposit publication fails before state mutation",
          (try? b04ApplyDeposit(
              opportunity: conflictingDeposit,
              depositID: conflictingDepositID, fixture: evaluation,
              session: &evaluation.session
          )) == nil
            && (try! evaluation.session.durableStateBytes()) == beforeConflict
            && evaluation.session.marketSnapshot().deposits.isEmpty
            && evaluation.session.materialRightsSnapshot().records.first {
                $0.asset.assetID == evaluation.pickaxe
            }?.lastVerifiedHolder == evaluation.pickaxeSource)
    let liveCheckpoint = try! evaluation.session.makeCheckpoint()
    var evaluationRestart = try! AgentSimulationSession.restoring(liveCheckpoint)
    check("schema 34 restart reconstructs contract exclusion without stored lock",
          liveCheckpoint.schemaVersion == 34
            && evaluationRestart.exactAssetCommitmentSnapshot().filter {
                $0.assetID == evaluation.pickaxe
            }.map(\.logicalOperationID) == [
                "contract:\(contractProposalID.rawValue)",
            ]
            && evaluationRestart.nextAutonomousMarketDepositProposal() == nil)
    try! evaluationRestart.withdrawPromiseProposal(
        proposalID: contractProposalID, promisorID: evaluation.buyer,
        reason: "legitimate terminal release"
    )
    check("terminal contract history releases exact asset commitment",
          !evaluationRestart.exactAssetIsEconomicallyCommitted(
              evaluation.pickaxe
          ) && evaluationRestart.contractSnapshot().proposals.first?.status
            == .withdrawn)
    let releasedDepositProposal = evaluationRestart
        .nextAutonomousMarketDepositProposal()!
    try! b04ApplyDeposit(
        opportunity: conflictingDeposit,
        depositID: releasedDepositProposal.depositID, fixture: evaluation,
        session: &evaluationRestart
    )
    check("released exact asset enters market with verified container custody",
          evaluationRestart.marketSnapshot().deposits.count == 1
            && evaluationRestart.exactAssetCommitmentSnapshot().filter {
                $0.assetID == evaluation.pickaxe
            }.map(\.logicalOperationID) == [
                "market-deposit:\(releasedDepositProposal.depositID.rawValue)",
            ]
            && evaluationRestart.materialRightsSnapshot().records.first {
                $0.asset.assetID == evaluation.pickaxe
            }?.lastVerifiedHolder.holder
                == .container(evaluation.marketLocation))
    let releasedCheckpoint = try! evaluationRestart.makeCheckpoint()
    let releasedRestart = try! AgentSimulationSession.restoring(
        releasedCheckpoint
    )
    check("second restart preserves terminal release and current market authority",
          releasedRestart.contractSnapshot().proposals.first?.status
            == .withdrawn
            && releasedRestart.marketSnapshot().deposits.count == 1
            && releasedRestart.exactAssetCommitmentSnapshot().filter {
                $0.assetID == evaluation.pickaxe
            }.allSatisfy { $0.domain == .market })

    // Market offered asset first, contract second.
    var marketFirst = b04Fixture("gate-e-blocker-04-market-offered-first")
    let marketFirstContract = b04ContractOpportunity(
        "b04-contract-opportunity:market-first",
        consideration: AgentBarterLeg(
            assetID: marketFirst.pickaxe, holderID: marketFirst.seller,
            material: marketFirst.pickaxeStack,
            holderObservation: marketFirst.pickaxeSource
        ), promisor: marketFirst.buyer, promisee: marketFirst.seller,
        promisorReason: marketFirst.buyerPickaxeReason,
        promiseeReason: marketFirst.sellerLogReason,
        promised: marketFirst.logStack, session: marketFirst.session
    )
    try! marketFirst.session.recordContractOpportunity(marketFirstContract)
    let marketFirstOpportunity = b04MarketOpportunity(
        "b04-market-opportunity:market-first", fixture: marketFirst,
        seller: marketFirst.seller, assetID: marketFirst.pickaxe,
        stack: marketFirst.pickaxeStack, source: marketFirst.pickaxeSource,
        reason: marketFirst.sellerBread2Reason, session: marketFirst.session
    )
    try! marketFirst.session.recordMarketDepositOpportunities([
        marketFirstOpportunity,
    ])
    let marketFirstDeposit = marketFirst.session
        .nextAutonomousMarketDepositProposal()!
    try! b04ApplyDeposit(
        opportunity: marketFirstOpportunity,
        depositID: marketFirstDeposit.depositID, fixture: marketFirst,
        session: &marketFirst.session
    )
    let beforeMarketFirstContract = try! marketFirst.session.durableStateBytes()
    check("live market offered asset cannot become contract consideration",
          (try? marketFirst.session.createPromiseProposal(
              proposalID: AgentPromiseProposalID(
                  rawValue: "b04-contract:market-first"
              )!, opportunityID: marketFirstContract.opportunityID,
              promisorID: marketFirstContract.promisorID
          )) == nil
            && (try! marketFirst.session.durableStateBytes())
                == beforeMarketFirstContract
            && marketFirst.session.contractSnapshot().proposals.isEmpty)

    // Contract and market buyer consideration, in both directions.
    var contractBuyer = b04Fixture("gate-e-blocker-04-contract-buyer-first")
    let contractBuyerListing = b04DepositAndListLog(
        fixture: contractBuyer, session: &contractBuyer.session
    )
    let bread1Leg = AgentBarterLeg(
        assetID: contractBuyer.bread1, holderID: contractBuyer.buyer,
        material: contractBuyer.bread1Stack,
        holderObservation: contractBuyer.bread1Source
    )
    let breadContract = b04ContractOpportunity(
        "b04-contract-opportunity:bread1", consideration: bread1Leg,
        promisor: contractBuyer.seller, promisee: contractBuyer.buyer,
        promisorReason: contractBuyer.sellerBread1Reason,
        promiseeReason: contractBuyer.buyerPickaxeReason,
        promised: contractBuyer.pickaxeStack, session: contractBuyer.session
    )
    try! b04CreateContract(
        breadContract,
        proposalID: AgentPromiseProposalID(rawValue: "b04-contract:bread1")!,
        session: &contractBuyer.session
    )
    let contractBuyerProposal = b04BuyerProposal(
        "b04-market-proposal:contract-first",
        listing: contractBuyerListing, buyer: contractBuyer.buyer,
        assetID: contractBuyer.bread1, stack: contractBuyer.bread1Stack,
        source: contractBuyer.bread1Source,
        reason: contractBuyer.buyerLogReason, session: contractBuyer.session
    )
    let beforeContractBuyer = try! contractBuyer.session.durableStateBytes()
    check("contract consideration cannot become market buyer consideration",
          (try? contractBuyer.session.proposeMarketPurchase(
              operationID: "b04-market-propose:contract-first",
              proposal: contractBuyerProposal
          )) == nil
            && (try! contractBuyer.session.durableStateBytes())
                == beforeContractBuyer
            && contractBuyer.session.marketSnapshot().proposals.isEmpty)

    var buyerFirst = b04Fixture("gate-e-blocker-04-market-buyer-first")
    let buyerFirstContract = b04ContractOpportunity(
        "b04-contract-opportunity:buyer-first",
        consideration: AgentBarterLeg(
            assetID: buyerFirst.bread1, holderID: buyerFirst.buyer,
            material: buyerFirst.bread1Stack,
            holderObservation: buyerFirst.bread1Source
        ), promisor: buyerFirst.seller, promisee: buyerFirst.buyer,
        promisorReason: buyerFirst.sellerBread1Reason,
        promiseeReason: buyerFirst.buyerPickaxeReason,
        promised: buyerFirst.pickaxeStack, session: buyerFirst.session
    )
    try! buyerFirst.session.recordContractOpportunity(buyerFirstContract)
    let buyerFirstListing = b04DepositAndListLog(
        fixture: buyerFirst, session: &buyerFirst.session
    )
    let buyerFirstProposal = b04BuyerProposal(
        "b04-market-proposal:buyer-first", listing: buyerFirstListing,
        buyer: buyerFirst.buyer, assetID: buyerFirst.bread1,
        stack: buyerFirst.bread1Stack, source: buyerFirst.bread1Source,
        reason: buyerFirst.buyerLogReason, session: buyerFirst.session
    )
    try! buyerFirst.session.proposeMarketPurchase(
        operationID: "b04-market-propose:buyer-first",
        proposal: buyerFirstProposal
    )
    let beforeBuyerFirstContract = try! buyerFirst.session.durableStateBytes()
    check("market buyer consideration cannot become contract consideration",
          (try? buyerFirst.session.createPromiseProposal(
              proposalID: AgentPromiseProposalID(
                  rawValue: "b04-contract:buyer-first"
              )!, opportunityID: buyerFirstContract.opportunityID,
              promisorID: buyerFirstContract.promisorID
          )) == nil
            && (try! buyerFirst.session.durableStateBytes())
                == beforeBuyerFirstContract)
    let rejection = try! buyerFirst.session.nextAutonomousMarketSellerDecision(
        proposalID: buyerFirstProposal.proposalID,
        currentLocality: b04Locality(
            fixture: buyerFirst, proposal: buyerFirstProposal,
            session: buyerFirst.session
        )
    )
    check("normal market cognition rejects the deliberately insufficient quote",
          !rejection.accept)
    try! buyerFirst.session.decideMarketProposal(
        operationID: "b04-market-decision:reject-buyer-first",
        decision: rejection
    )
    try! buyerFirst.session.createPromiseProposal(
        proposalID: AgentPromiseProposalID(
            rawValue: "b04-contract:buyer-first-released"
        )!, opportunityID: buyerFirstContract.opportunityID,
        promisorID: buyerFirstContract.promisorID
    )
    check("terminal market proposal releases buyer asset for contract reuse",
          buyerFirst.session.marketSnapshot().proposals.first?.status
            == .rejected
            && buyerFirst.session.exactAssetCommitmentSnapshot().filter {
                $0.assetID == buyerFirst.bread1
            }.allSatisfy { $0.domain == .contract })

    // Contract and barter in both directions and both barter roles.
    var contractBarter = b04Fixture("gate-e-blocker-04-contract-barter")
    let contractPickaxe = b04ContractOpportunity(
        "b04-contract-opportunity:contract-barter-pickaxe",
        consideration: AgentBarterLeg(
            assetID: contractBarter.pickaxe, holderID: contractBarter.seller,
            material: contractBarter.pickaxeStack,
            holderObservation: contractBarter.pickaxeSource
        ), promisor: contractBarter.buyer, promisee: contractBarter.seller,
        promisorReason: contractBarter.buyerPickaxeReason,
        promiseeReason: contractBarter.sellerLogReason,
        promised: contractBarter.logStack, session: contractBarter.session
    )
    try! b04CreateContract(
        contractPickaxe,
        proposalID: AgentPromiseProposalID(
            rawValue: "b04-contract:contract-barter-pickaxe"
        )!, session: &contractBarter.session
    )
    let pickaxeBreadBarter = b04BarterOpportunity(
        "b04-barter-opportunity:pickaxe-bread2",
        offered: AgentBarterLeg(
            assetID: contractBarter.pickaxe, holderID: contractBarter.seller,
            material: contractBarter.pickaxeStack,
            holderObservation: contractBarter.pickaxeSource
        ), requested: AgentBarterLeg(
            assetID: contractBarter.bread2, holderID: contractBarter.buyer,
            material: contractBarter.bread2Stack,
            holderObservation: contractBarter.bread2Source
        ), offeror: contractBarter.seller,
        counterparty: contractBarter.buyer,
        offerorReason: contractBarter.sellerBread2Reason,
        counterpartyReason: contractBarter.buyerPickaxeReason,
        session: contractBarter.session
    )
    try! contractBarter.session.recordBarterOpportunity(pickaxeBreadBarter)
    let beforeContractBarter = try! contractBarter.session.durableStateBytes()
    check("contract commitment blocks conflicting offered barter leg",
          (try? contractBarter.session.createBarterOffer(
              offerID: AgentBarterOfferID(
                  rawValue: "b04-barter:contract-first"
              )!, opportunityID: pickaxeBreadBarter.opportunityID,
              actorID: pickaxeBreadBarter.offerorID
          )) == nil
            && (try! contractBarter.session.durableStateBytes())
                == beforeContractBarter)

    var barterFirst = b04Fixture("gate-e-blocker-04-barter-contract")
    let barterFirstOpportunity = b04BarterOpportunity(
        "b04-barter-opportunity:barter-first",
        offered: AgentBarterLeg(
            assetID: barterFirst.pickaxe, holderID: barterFirst.seller,
            material: barterFirst.pickaxeStack,
            holderObservation: barterFirst.pickaxeSource
        ), requested: AgentBarterLeg(
            assetID: barterFirst.bread2, holderID: barterFirst.buyer,
            material: barterFirst.bread2Stack,
            holderObservation: barterFirst.bread2Source
        ), offeror: barterFirst.seller, counterparty: barterFirst.buyer,
        offerorReason: barterFirst.sellerBread2Reason,
        counterpartyReason: barterFirst.buyerPickaxeReason,
        session: barterFirst.session
    )
    let barterFirstID = AgentBarterOfferID(rawValue: "b04-barter:first")!
    try! b04CreateBarter(
        barterFirstOpportunity, offerID: barterFirstID,
        session: &barterFirst.session
    )
    let barterOfferedContract = b04ContractOpportunity(
        "b04-contract-opportunity:barter-offered",
        consideration: barterFirstOpportunity.offered,
        promisor: barterFirst.buyer, promisee: barterFirst.seller,
        promisorReason: barterFirst.buyerPickaxeReason,
        promiseeReason: barterFirst.sellerLogReason,
        promised: barterFirst.logStack, session: barterFirst.session
    )
    let barterRequestedContract = b04ContractOpportunity(
        "b04-contract-opportunity:barter-requested",
        consideration: barterFirstOpportunity.requested,
        promisor: barterFirst.seller, promisee: barterFirst.buyer,
        promisorReason: barterFirst.sellerBread2Reason,
        promiseeReason: barterFirst.buyerLogReason,
        promised: barterFirst.logStack, session: barterFirst.session
    )
    try! barterFirst.session.recordContractOpportunity(barterOfferedContract)
    try! barterFirst.session.recordContractOpportunity(barterRequestedContract)
    let beforeBarterContracts = try! barterFirst.session.durableStateBytes()
    let offeredRefused = (try? barterFirst.session.createPromiseProposal(
        proposalID: AgentPromiseProposalID(
            rawValue: "b04-contract:barter-offered"
        )!, opportunityID: barterOfferedContract.opportunityID,
        promisorID: barterOfferedContract.promisorID
    )) == nil
    let requestedRefused = (try? barterFirst.session.createPromiseProposal(
        proposalID: AgentPromiseProposalID(
            rawValue: "b04-contract:barter-requested"
        )!, opportunityID: barterRequestedContract.opportunityID,
        promisorID: barterRequestedContract.promisorID
    )) == nil
    check("both offered and requested barter legs block contract acquisition",
          offeredRefused && requestedRefused
            && (try! barterFirst.session.durableStateBytes())
                == beforeBarterContracts)

    // Market and barter: an agent-held market consideration and a market lot.
    var marketBarter = b04Fixture("gate-e-blocker-04-market-barter")
    let marketBarterListing = b04DepositAndListLog(
        fixture: marketBarter, session: &marketBarter.session
    )
    let marketBreadProposal = b04BuyerProposal(
        "b04-market-proposal:market-barter",
        listing: marketBarterListing, buyer: marketBarter.buyer,
        assetID: marketBarter.bread1, stack: marketBarter.bread1Stack,
        source: marketBarter.bread1Source,
        reason: marketBarter.buyerLogReason, session: marketBarter.session
    )
    try! marketBarter.session.proposeMarketPurchase(
        operationID: "b04-market-propose:market-barter",
        proposal: marketBreadProposal
    )
    let marketBarterOpportunity = b04BarterOpportunity(
        "b04-barter-opportunity:market-buyer-consideration",
        offered: AgentBarterLeg(
            assetID: marketBarter.pickaxe, holderID: marketBarter.seller,
            material: marketBarter.pickaxeStack,
            holderObservation: marketBarter.pickaxeSource
        ), requested: AgentBarterLeg(
            assetID: marketBarter.bread1, holderID: marketBarter.buyer,
            material: marketBarter.bread1Stack,
            holderObservation: marketBarter.bread1Source
        ), offeror: marketBarter.seller,
        counterparty: marketBarter.buyer,
        offerorReason: marketBarter.sellerBread1Reason,
        counterpartyReason: marketBarter.buyerPickaxeReason,
        session: marketBarter.session
    )
    try! marketBarter.session.recordBarterOpportunity(marketBarterOpportunity)
    check("market buyer consideration blocks requested barter leg",
          (try? marketBarter.session.createBarterOffer(
              offerID: AgentBarterOfferID(
                  rawValue: "b04-barter:market-buyer"
              )!, opportunityID: marketBarterOpportunity.opportunityID,
              actorID: marketBarterOpportunity.offerorID
          )) == nil)

    var barterMarket = b04Fixture("gate-e-blocker-04-barter-market")
    let barterMarketOpportunity = b04BarterOpportunity(
        "b04-barter-opportunity:barter-market",
        offered: AgentBarterLeg(
            assetID: barterMarket.pickaxe, holderID: barterMarket.seller,
            material: barterMarket.pickaxeStack,
            holderObservation: barterMarket.pickaxeSource
        ), requested: AgentBarterLeg(
            assetID: barterMarket.bread2, holderID: barterMarket.buyer,
            material: barterMarket.bread2Stack,
            holderObservation: barterMarket.bread2Source
        ), offeror: barterMarket.seller,
        counterparty: barterMarket.buyer,
        offerorReason: barterMarket.sellerBread2Reason,
        counterpartyReason: barterMarket.buyerPickaxeReason,
        session: barterMarket.session
    )
    try! b04CreateBarter(
        barterMarketOpportunity,
        offerID: AgentBarterOfferID(rawValue: "b04-barter:market")!,
        session: &barterMarket.session
    )
    let barterMarketDeposit = b04MarketOpportunity(
        "b04-market-opportunity:barter-offered", fixture: barterMarket,
        seller: barterMarket.seller, assetID: barterMarket.pickaxe,
        stack: barterMarket.pickaxeStack,
        source: barterMarket.pickaxeSource,
        reason: barterMarket.sellerBread2Reason,
        session: barterMarket.session
    )
    try! barterMarket.session.recordMarketDepositOpportunities([
        barterMarketDeposit,
    ])
    check("barter offered leg is excluded from ordinary market deposit",
          barterMarket.session.nextAutonomousMarketDepositProposal() == nil)
    let beforeBarterMarketDeposit = try! barterMarket.session.durableStateBytes()
    check("barter offered leg refuses authoritative market deposit publication",
          (try? b04ApplyDeposit(
              opportunity: barterMarketDeposit,
              depositID: AgentMarketDepositID(
                  rawValue: "b04-deposit:barter-offered"
              )!, fixture: barterMarket, session: &barterMarket.session
          )) == nil
            && (try! barterMarket.session.durableStateBytes())
                == beforeBarterMarketDeposit)
    let barterMarketListing = b04DepositAndListLog(
        fixture: barterMarket, session: &barterMarket.session
    )
    let barterBreadProposal = b04BuyerProposal(
        "b04-market-proposal:barter-requested",
        listing: barterMarketListing, buyer: barterMarket.buyer,
        assetID: barterMarket.bread2, stack: barterMarket.bread2Stack,
        source: barterMarket.bread2Source,
        reason: barterMarket.buyerLogReason, session: barterMarket.session
    )
    check("barter requested leg refuses market buyer proposal publication",
          (try? barterMarket.session.proposeMarketPurchase(
              operationID: "b04-market-propose:barter-requested",
              proposal: barterBreadProposal
          )) == nil)

    // One barter operation may progress; another may not steal either leg.
    var continuation = b04Fixture("gate-e-blocker-04-continuation")
    let continuationOpportunity = b04BarterOpportunity(
        "b04-barter-opportunity:continuation",
        offered: AgentBarterLeg(
            assetID: continuation.pickaxe, holderID: continuation.seller,
            material: continuation.pickaxeStack,
            holderObservation: continuation.pickaxeSource
        ), requested: AgentBarterLeg(
            assetID: continuation.bread2, holderID: continuation.buyer,
            material: continuation.bread2Stack,
            holderObservation: continuation.bread2Source
        ), offeror: continuation.seller, counterparty: continuation.buyer,
        offerorReason: continuation.sellerBread2Reason,
        counterpartyReason: continuation.buyerPickaxeReason,
        session: continuation.session
    )
    let continuationID = AgentBarterOfferID(
        rawValue: "b04-barter:continuation"
    )!
    try! b04CreateBarter(
        continuationOpportunity, offerID: continuationID,
        session: &continuation.session
    )
    let beforeSecondBarter = try! continuation.session.durableStateBytes()
    check("same exact assets cannot back a second concurrent barter offer",
          (try? continuation.session.createBarterOffer(
              offerID: AgentBarterOfferID(
                  rawValue: "b04-barter:concurrent"
              )!, opportunityID: continuationOpportunity.opportunityID,
              actorID: continuationOpportunity.offerorID
          )) == nil
            && (try! continuation.session.durableStateBytes())
                == beforeSecondBarter)
    try! continuation.session.decideBarterOffer(
        offerID: continuationID,
        counterpartyID: continuation.buyer, accept: true,
        reason: "same logical commitment continues"
    )
    check("open to accepted barter continuation retains one logical owner",
          Set(continuation.session.exactAssetCommitmentSnapshot().map {
              $0.logicalOperationID
          }) == ["barter:\(continuationID.rawValue)"]
            && (try? continuation.session.prevalidateAcceptedBarterCommitment(
                offerID: continuationID
            )) != nil)
    try! continuation.session.recordVerifiedBarter(b04SuccessfulBarter(
        offerID: continuationID, opportunity: continuationOpportunity,
        session: continuation.session
    ))
    check("completed barter releases both exact commitments",
          continuation.session.exactAssetCommitmentSnapshot().isEmpty
            && continuation.session.barterSnapshot().offers.first?.status
                == .completed)
    try! continuation.session.createBarterOffer(
        offerID: AgentBarterOfferID(rawValue: "b04-barter:after-terminal")!,
        opportunityID: continuationOpportunity.opportunityID,
        actorID: continuationOpportunity.offerorID
    )
    check("terminal barter history does not block legitimate reuse",
          continuation.session.barterSnapshot().offers.filter {
              $0.status.isPending
          }.count == 1)

    // Contract continuation, physical-authority negatives and release.
    var contractContinuation = b04Fixture(
        "gate-e-blocker-04-contract-continuation"
    )
    let contractContinuationOpportunity = b04ContractOpportunity(
        "b04-contract-opportunity:continuation",
        consideration: AgentBarterLeg(
            assetID: contractContinuation.pickaxe,
            holderID: contractContinuation.seller,
            material: contractContinuation.pickaxeStack,
            holderObservation: contractContinuation.pickaxeSource
        ), promisor: contractContinuation.buyer,
        promisee: contractContinuation.seller,
        promisorReason: contractContinuation.buyerPickaxeReason,
        promiseeReason: contractContinuation.sellerLogReason,
        promised: contractContinuation.logStack,
        session: contractContinuation.session
    )
    let contractContinuationID = AgentPromiseProposalID(
        rawValue: "b04-contract:continuation"
    )!
    try! b04CreateContract(
        contractContinuationOpportunity,
        proposalID: contractContinuationID,
        session: &contractContinuation.session
    )
    try! contractContinuation.session.decidePromiseProposal(
        proposalID: contractContinuationID,
        promiseeID: contractContinuation.seller, accept: true,
        reason: "same logical contract accepted"
    )
    let obligation = contractContinuation.session.contractSnapshot()
        .obligations.first!
    check("contract proposal to awaiting-consideration is one continuation",
          contractContinuation.session.exactAssetCommitmentSnapshot().filter {
              $0.assetID == contractContinuation.pickaxe
          }.map(\.logicalOperationID) == [
              "contract:\(contractContinuationID.rawValue)",
          ])
    func consideration(
        source: AgentMaterialHolderObservation,
        operationID: String
    ) -> AgentVerifiedContractConsiderationOutcome {
        AgentVerifiedContractConsiderationOutcome(
            operationID: operationID, obligationID: obligation.obligationID,
            transfer: AgentVerifiedContractTransfer(
                assetID: contractContinuation.pickaxe,
                sourceObservation: source,
                destinationObservation: b04Observation(
                    holder: .agent(contractContinuation.buyer),
                    stack: contractContinuation.pickaxeStack,
                    fingerprint: "b04-buyer-pickaxe",
                    receipt: operationID, tick: contractContinuation.session.tick
                ), physicalReceiptID: operationID
            ), completedAtTick: contractContinuation.session.tick
        )
    }
    let beforeWrongAuthority = try! contractContinuation.session
        .durableStateBytes()
    let wrongHolder = b04Observation(
        holder: .agent(contractContinuation.buyer),
        stack: contractContinuation.pickaxeStack,
        fingerprint: "b04-wrong-holder", receipt: "b04-wrong-holder",
        tick: contractContinuation.session.tick
    )
    let wrongQuantity = AgentMaterialHolderObservation(
        holder: .agent(contractContinuation.seller),
        materialIdentity: contractContinuation.pickaxeStack.identity,
        quantity: 2, custodyFingerprint: "b04-wrong-quantity",
        physicalReceiptID: "b04-wrong-quantity",
        observedAtTick: contractContinuation.session.tick
    )
    let wrongIdentity = AgentMaterialHolderObservation(
        holder: .agent(contractContinuation.seller),
        materialIdentity: b04Identity("iron_pickaxe"), quantity: 1,
        custodyFingerprint: "b04-wrong-identity",
        physicalReceiptID: "b04-wrong-identity",
        observedAtTick: contractContinuation.session.tick
    )
    check("valid commitment never replaces wrong current physical authority",
          (try? contractContinuation.session
            .recordVerifiedContractConsideration(consideration(
                source: wrongHolder, operationID: "b04-wrong-holder"
            ))) == nil
            && (try? contractContinuation.session
                .recordVerifiedContractConsideration(consideration(
                    source: wrongQuantity,
                    operationID: "b04-wrong-quantity"
                ))) == nil
            && (try? contractContinuation.session
                .recordVerifiedContractConsideration(consideration(
                    source: wrongIdentity,
                    operationID: "b04-wrong-identity"
                ))) == nil
            && (try! contractContinuation.session.durableStateBytes())
                == beforeWrongAuthority)
    let currentSource = b04Observation(
        holder: .agent(contractContinuation.seller),
        stack: contractContinuation.pickaxeStack,
        fingerprint: "b04-current-pickaxe",
        receipt: "b04-current-pickaxe",
        tick: contractContinuation.session.tick
    )
    try! contractContinuation.session.recordVerifiedContractConsideration(
        consideration(
            source: currentSource, operationID: "b04-contract-consideration"
        )
    )
    check("verified consideration transfer releases exact contract asset",
          contractContinuation.session.contractSnapshot().obligations.first?
            .status == .outstanding
            && !contractContinuation.session.exactAssetIsEconomicallyCommitted(
                contractContinuation.pickaxe
            ))

    // Replay derives the same authority and terminal release without matter.
    var replay = b04Fixture("gate-e-blocker-04-replay")
    let replayBase = try! replay.session.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(
        checkpoint: replayBase, session: replay.session
    )
    let replayOpportunity = b04ContractOpportunity(
        "b04-contract-opportunity:replay",
        consideration: AgentBarterLeg(
            assetID: replay.pickaxe, holderID: replay.seller,
            material: replay.pickaxeStack,
            holderObservation: replay.pickaxeSource
        ), promisor: replay.buyer, promisee: replay.seller,
        promisorReason: replay.buyerPickaxeReason,
        promiseeReason: replay.sellerLogReason,
        promised: replay.logStack, session: replay.session
    )
    let replayProposalID = AgentPromiseProposalID(
        rawValue: "b04-contract:replay"
    )!
    _ = try! recorder.apply(
        .recordContractOpportunity(replayOpportunity), to: &replay.session
    )
    _ = try! recorder.apply(.createPromiseProposal(
        proposalID: replayProposalID,
        opportunityID: replayOpportunity.opportunityID,
        promisorID: replayOpportunity.promisorID
    ), to: &replay.session)
    _ = try! recorder.apply(.withdrawPromiseProposal(
        proposalID: replayProposalID,
        promisorID: replayOpportunity.promisorID,
        reason: "replay terminal release"
    ), to: &replay.session)
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "b04-replay")!
    )
    let replayed = try! AgentSessionReplayer.replay(
        checkpoint: replayBase, journal: journal
    )
    check("replay reconstructs history but no terminal commitment or matter",
          replayed.report.verified
            && journal.manifest.schemaVersion == 34
            && replayed.session.contractSnapshot().proposals.first?.status
                == .withdrawn
            && replayed.session.exactAssetCommitmentSnapshot().isEmpty
            && replayed.session.materialRightsSnapshot()
                == replay.session.materialRightsSnapshot())

    let observerWorld = try! AgentObserverWorldBinding(
        worldID: "gate-e-blocker-04-world",
        storageIdentity: "memory:gate-e-blocker-04", seed: 404,
        dimension: 0, observedWorldTick: 0
    )
    let observerBefore = try! evaluationRestart.durableStateBytes()
    let observer = evaluationRestart.observerSnapshot(
        worldBinding: observerWorld
    )
    check("Observer schema 11 remains read-only and non-authoritative",
          observer.header.schemaVersion == 11
            && (try! evaluationRestart.durableStateBytes()) == observerBefore)

    check("Blocker 04 focused accounting retains exact conservation",
          evaluationRestart.conservationSnapshot().balanced
            && marketFirst.session.conservationSnapshot().balanced
            && contractBuyer.session.conservationSnapshot().balanced
            && buyerFirst.session.conservationSnapshot().balanced
            && contractBarter.session.conservationSnapshot().balanced
            && barterFirst.session.conservationSnapshot().balanced
            && marketBarter.session.conservationSnapshot().balanced
            && barterMarket.session.conservationSnapshot().balanced
            && continuation.session.conservationSnapshot().balanced
            && contractContinuation.session.conservationSnapshot().balanced
            && replayed.session.conservationSnapshot().balanced)
}
