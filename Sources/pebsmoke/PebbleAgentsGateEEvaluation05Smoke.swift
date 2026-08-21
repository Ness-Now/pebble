import Foundation
import PebbleAgents

private func e05Reason(
    _ id: String,
    actor: AgentID,
    item: String,
    quantity: Int,
    priority: Int,
    session: inout AgentSimulationSession
) -> AgentBarterValueReason {
    let needID = AgentProductionNeedID(rawValue: id)!
    try! session.raiseProductionNeed(
        needID: needID, actorID: actor, reason: .materialWork,
        desiredOutputItemKey: item, quantity: quantity, priority: priority
    )
    return AgentBarterValueReason(need: session.productionSnapshot().needs.first {
        $0.needID == needID
    }!)
}

@discardableResult
private func e05Produce(
    operationID: String,
    needID: AgentProductionNeedID,
    actor: AgentID,
    output: AgentMaterialStackSnapshot,
    sourceBefore: String,
    sourceAfter: String,
    physicalReceiptID: String? = nil,
    session: inout AgentSimulationSession
) -> AgentVerifiedProductionOutcome {
    let inputs = output.identity.itemKey == "stone_pickaxe"
        ? [b04Stack("cobblestone", 3), b04Stack("stick", 2)]
        : [b04Stack("wheat", 3)]
    let opportunity = AgentProductionOpportunityObservation(
        opportunityID: AgentProductionOpportunityID(
            rawValue: "e05-opportunity:\(operationID)"
        )!,
        needID: needID, actorID: actor,
        recipeID: "e05-canonical:\(output.identity.itemKey)",
        workshopPosition: AgentPosition(x: 1, y: 64, z: 1),
        workshopBlockKey: "crafting_table",
        sourceLocationID: "agent:\(actor.rawValue)",
        sourceCustodyFingerprint: sourceBefore,
        planFingerprint: "e05-plan:\(operationID)",
        inputs: inputs,
        output: output, observedAtTick: session.tick,
        expiresAtTick: session.tick + 2
    )
    try! session.recordProductionOpportunity(opportunity)
    let outcome = AgentVerifiedProductionOutcome(
        operationID: operationID,
        opportunityID: opportunity.opportunityID,
        actorID: actor, recipeID: opportunity.recipeID,
        workshopPosition: opportunity.workshopPosition,
        workshopBlockKey: opportunity.workshopBlockKey,
        sourceLocationID: opportunity.sourceLocationID,
        sourceCustodyFingerprintBefore: sourceBefore,
        sourceCustodyFingerprintAfter: sourceAfter,
        planFingerprint: opportunity.planFingerprint,
        inputsConsumed: opportunity.inputs,
        outputProduced: output,
        physicalReceiptID: physicalReceiptID
            ?? "e05-production-receipt:\(operationID)",
        completedAtTick: session.tick
    )
    try! session.recordVerifiedProduction(outcome)
    return outcome
}

private func e05BindProduction(
    assetID: AgentMaterialAssetID,
    operationID: String,
    session: inout AgentSimulationSession
) {
    _ = try! session.applyMaterialRightsOperation(.bindProductionProvenance(
        operationID: "e05-bind:\(assetID.rawValue)",
        assetID: assetID, productionOperationIDs: [operationID]
    ))
}

@discardableResult
private func e05EvolvePickaxe(
    assetID: AgentMaterialAssetID,
    actor: AgentID,
    session: inout AgentSimulationSession
) -> AgentMaterialHolderObservation {
    let current = session.materialRightsSnapshot().records.first {
        $0.asset.assetID == assetID
    }!.lastVerifiedHolder
    let decision = session.evaluateMaterialUse(AgentMaterialUseRequest(
        requestID: "e05-tool-use-request", assetID: assetID,
        actorID: actor, use: .toolUse, verifiedHolder: current
    ))
    let evolved = AgentMaterialHolderObservation(
        holder: .agent(actor),
        materialIdentity: AgentMaterialIdentitySnapshot(
            itemKey: "stone_pickaxe", damage: 1, enchantments: [],
            label: nil, canonicalDataJSON: "{}"
        ),
        quantity: 1, custodyFingerprint: "e05-pickaxe-damage-1",
        physicalReceiptID: "e05-tool-use-damage-1",
        observedAtTick: session.tick
    )
    _ = try! session.applyMaterialRightsOperation(.useAttempt(
        AgentMaterialUseAttemptOutcome(
            operationID: "e05-tool-use-damage-1", decision: decision,
            status: .succeeded, resultingObservation: evolved,
            physicalReceiptID: evolved.physicalReceiptID
        )
    ))
    return evolved
}

private func e05Leg(
    assetID: AgentMaterialAssetID,
    holder: AgentID,
    session: AgentSimulationSession
) -> AgentBarterLeg {
    let record = session.materialRightsSnapshot().records.first {
        $0.asset.assetID == assetID
    }!
    return AgentBarterLeg(
        assetID: assetID, holderID: holder,
        material: AgentMaterialStackSnapshot(
            identity: record.lastVerifiedHolder.materialIdentity,
            count: record.lastVerifiedHolder.quantity
        ), holderObservation: record.lastVerifiedHolder,
        productionOperationIDs:
            record.productionProvenance?.operationIDs ?? []
    )
}

private func e05Locality(
    fixture: B04Fixture,
    seller: AgentID,
    buyer: AgentID,
    sellerAlive: Bool = true,
    buyerAlive: Bool = true,
    tick: Int
) -> AgentMarketCurrentLocalityEvidence {
    func participant(
        _ id: AgentID, x: Int, alive: Bool
    ) -> AgentMarketParticipantLocality {
        AgentMarketParticipantLocality(
            marketID: fixture.marketID, participantID: id,
            participantPhysicalID: "e05-physical:\(id.rawValue)",
            participantPosition: AgentPosition(x: x, y: 64, z: 0),
            marketPosition: AgentPosition(x: 1, y: 64, z: 0),
            participantAlive: alive, participantChunkReady: true,
            marketChunkReady: true, marketContainerValid: true,
            observedAtTick: tick
        )
    }
    return AgentMarketCurrentLocalityEvidence(
        seller: participant(seller, x: 0, alive: sellerAlive),
        buyer: participant(buyer, x: 2, alive: buyerAlive)
    )
}

func runPebbleAgentsGateEEvaluation05Smoke() {
    section("Gate E Evaluation 05 independent whole-system composition")

    var fixture = b04Fixture("gate-e-evaluation-05-composition")
    let pickaxeNeedID = AgentProductionNeedID(
        rawValue: "e05-need:seller:produce-pickaxe"
    )!
    try! fixture.session.raiseProductionNeed(
        needID: pickaxeNeedID, actorID: fixture.seller,
        reason: .missingUsefulTool, desiredOutputItemKey: "stone_pickaxe",
        quantity: 1, priority: 100
    )
    let pickaxeProduction = e05Produce(
        operationID: "e05-production:pickaxe",
        needID: pickaxeNeedID, actor: fixture.seller,
        output: fixture.pickaxeStack,
        sourceBefore: "e05-pickaxe-inputs",
        sourceAfter: fixture.pickaxeSource.custodyFingerprint,
        physicalReceiptID: fixture.pickaxeSource.physicalReceiptID,
        session: &fixture.session
    )
    e05BindProduction(
        assetID: fixture.pickaxe,
        operationID: pickaxeProduction.operationID,
        session: &fixture.session
    )
    let origin = fixture.session.materialRightsSnapshot().records.first {
        $0.asset.assetID == fixture.pickaxe
    }!.productionProvenance
    check("exact produced pickaxe binds one immutable origin",
          origin?.operationIDs == [pickaxeProduction.operationID]
            && origin?.representedQuantity == 1
            && fixture.session.productionSnapshot().needs.first {
                $0.needID == pickaxeNeedID
            }?.status == .fulfilled)

    let firstBarter = b04BarterOpportunity(
        "e05-barter-opportunity:produced-pickaxe",
        offered: e05Leg(
            assetID: fixture.pickaxe, holder: fixture.seller,
            session: fixture.session
        ),
        requested: e05Leg(
            assetID: fixture.bread2, holder: fixture.buyer,
            session: fixture.session
        ),
        offeror: fixture.seller, counterparty: fixture.buyer,
        offerorReason: fixture.sellerBread2Reason,
        counterpartyReason: fixture.buyerPickaxeReason,
        session: fixture.session
    )
    let firstBarterID = AgentBarterOfferID(
        rawValue: "e05-barter:produced-pickaxe"
    )!
    try! b04CreateBarter(
        firstBarter, offerID: firstBarterID, session: &fixture.session
    )
    check("live barter commits both exact assets under one operation",
          Set(fixture.session.exactAssetCommitmentSnapshot().map {
              $0.logicalOperationID
          }) == ["barter:\(firstBarterID.rawValue)"]
            && fixture.session.exactAssetCommitmentSnapshot().count == 2)
    try! fixture.session.decideBarterOffer(
        offerID: firstBarterID, counterpartyID: fixture.buyer,
        accept: true, reason: "evaluation ordinary exact exchange"
    )
    try! fixture.session.recordVerifiedBarter(b04SuccessfulBarter(
        offerID: firstBarterID, opportunity: firstBarter,
        session: fixture.session
    ))
    let afterBarter = fixture.session.materialRightsSnapshot().records
    check("verified barter moves exact ownership and releases commitments",
          afterBarter.first { $0.asset.assetID == fixture.pickaxe }?
            .recognizedOwnership?.ownerID == fixture.buyer
            && afterBarter.first { $0.asset.assetID == fixture.bread2 }?
                .recognizedOwnership?.ownerID == fixture.seller
            && fixture.session.exactAssetCommitmentSnapshot().isEmpty)
    check("barter receipt closes only its two exact quantity-bearing needs",
          fixture.session.productionSnapshot().needs.first {
              $0.needID == fixture.sellerBread2Reason.needID
          }?.status == .fulfilled
            && fixture.session.productionSnapshot().needs.first {
                $0.needID == fixture.buyerPickaxeReason.needID
            }?.status == .fulfilled
            && fixture.session.productionSnapshot().needs.first {
                $0.needID == fixture.merchantBread3Reason.needID
            }?.status == .active)

    let evolved = e05EvolvePickaxe(
        assetID: fixture.pickaxe, actor: fixture.buyer,
        session: &fixture.session
    )
    let evolvedRecord = fixture.session.materialRightsSnapshot().records.first {
        $0.asset.assetID == fixture.pickaxe
    }!
    check("legitimate tool evolution preserves durable asset and origin",
          evolved.materialIdentity.damage == 1
            && evolvedRecord.asset.materialIdentity.damage == 0
            && evolvedRecord.productionProvenance?.operationIDs
                == [pickaxeProduction.operationID])

    let sellerPickaxeReason = e05Reason(
        "e05-need:seller:contract-pickaxe", actor: fixture.seller,
        item: "stone_pickaxe", quantity: 1, priority: 100,
        session: &fixture.session
    )
    let buyerBreadReason = e05Reason(
        "e05-need:buyer:contract-bread", actor: fixture.buyer,
        item: "bread", quantity: 1, priority: 99,
        session: &fixture.session
    )
    let contractOpportunity = b04ContractOpportunity(
        "e05-contract-opportunity:evolved-pickaxe",
        consideration: e05Leg(
            assetID: fixture.pickaxe, holder: fixture.buyer,
            session: fixture.session
        ),
        promisor: fixture.seller, promisee: fixture.buyer,
        promisorReason: sellerPickaxeReason,
        promiseeReason: buyerBreadReason,
        promised: fixture.bread1Stack, session: fixture.session
    )
    let contractID = AgentPromiseProposalID(
        rawValue: "e05-contract:evolved-pickaxe"
    )!
    try! b04CreateContract(
        contractOpportunity, proposalID: contractID,
        session: &fixture.session
    )
    try! fixture.session.decidePromiseProposal(
        proposalID: contractID, promiseeID: fixture.buyer,
        accept: true, reason: "evaluation distinct acceptance"
    )
    let acceptedObligation = fixture.session.contractSnapshot()
        .obligations.first { $0.proposalID == contractID }!
    check("accepted contract commits only concrete consideration",
          fixture.session.exactAssetCommitmentSnapshot().filter {
              $0.domain == .contract
          }.map(\.assetID) == [fixture.pickaxe]
            && !fixture.session.exactAssetCommitmentSnapshot().contains {
                $0.assetID == fixture.bread1
            }
            && acceptedObligation.status == .awaitingConsideration)

    let conflict = b04MarketOpportunity(
        "e05-market-opportunity:contract-conflict", fixture: fixture,
        seller: fixture.buyer, assetID: fixture.pickaxe,
        stack: AgentMaterialStackSnapshot(
            identity: evolved.materialIdentity, count: 1
        ), source: evolved, reason: buyerBreadReason,
        session: fixture.session
    )
    try! fixture.session.recordMarketDepositOpportunities([conflict])
    let beforeConflict = try! fixture.session.durableStateBytes()
    check("contract-bound exact asset refuses unrelated market use atomically",
          fixture.session.nextAutonomousMarketDepositProposal() == nil
            && (try? b04ApplyDeposit(
                opportunity: conflict,
                depositID: AgentMarketDepositID(
                    rawValue: "e05-deposit:contract-conflict"
                )!, fixture: fixture, session: &fixture.session
            )) == nil
            && (try! fixture.session.durableStateBytes()) == beforeConflict)

    let acceptedCheckpoint = try! fixture.session.makeCheckpoint()
    fixture.session = try! AgentSimulationSession.restoring(acceptedCheckpoint)
    check("schema 34 restart derives the same singular live contract authority",
          acceptedCheckpoint.schemaVersion == 34
            && fixture.session.exactAssetCommitmentSnapshot().filter {
                $0.assetID == fixture.pickaxe
            }.map(\.logicalOperationID)
                == ["contract:\(contractID.rawValue)"]
            && fixture.session.contractSnapshot().obligations.first {
                $0.proposalID == contractID
            }?.status == .awaitingConsideration)

    let currentPickaxe = fixture.session.materialRightsSnapshot().records.first {
        $0.asset.assetID == fixture.pickaxe
    }!.lastVerifiedHolder
    let considerationReceipt = "e05-contract-consideration"
    let considerationDestination = AgentMaterialHolderObservation(
        holder: .agent(fixture.seller),
        materialIdentity: currentPickaxe.materialIdentity,
        quantity: 1, custodyFingerprint: "e05-returned-pickaxe",
        physicalReceiptID: considerationReceipt,
        observedAtTick: fixture.session.tick
    )
    try! fixture.session.recordVerifiedContractConsideration(
        AgentVerifiedContractConsiderationOutcome(
            operationID: considerationReceipt,
            obligationID: acceptedObligation.obligationID,
            transfer: AgentVerifiedContractTransfer(
                assetID: fixture.pickaxe,
                sourceObservation: currentPickaxe,
                destinationObservation: considerationDestination,
                physicalReceiptID: considerationReceipt,
                productionOperationIDs: [pickaxeProduction.operationID]
            ), completedAtTick: fixture.session.tick
        )
    )
    check("same contract continuation returns evolved asset to former owner",
          fixture.session.contractSnapshot().obligations.first {
              $0.proposalID == contractID
          }?.status == .outstanding
            && fixture.session.materialRightsSnapshot().records.first {
                $0.asset.assetID == fixture.pickaxe
            }?.recognizedOwnership?.ownerID == fixture.seller
            && fixture.session.exactAssetCommitmentSnapshot().allSatisfy {
                $0.assetID != fixture.pickaxe
            })
    check("verified consideration closes its exact need and creates no bread",
          fixture.session.productionSnapshot().needs.first {
              $0.needID == sellerPickaxeReason.needID
          }?.status == .fulfilled
            && fixture.session.materialRightsSnapshot().records.filter {
                $0.asset.materialIdentity.itemKey == "bread"
                    && $0.asset.quantity == 1
            }.count == 1)

    let performanceNeed = fixture.session.productionSnapshot().needs.first {
        $0.actorID == fixture.seller && $0.status == .active
            && $0.needID.rawValue.hasPrefix("contract:obligation-")
            && $0.desiredOutputItemKey == "bread" && $0.quantity == 1
    }!
    let performanceProduction = e05Produce(
        operationID: "e05-production:contract-bread",
        needID: performanceNeed.needID, actor: fixture.seller,
        output: fixture.bread1Stack,
        sourceBefore: "e05-contract-bread-inputs",
        sourceAfter: "e05-contract-bread-produced",
        session: &fixture.session
    )
    let performanceAsset = AgentMaterialAssetID(
        rawValue: "e05-asset:contract-bread"
    )!
    let performanceSource = AgentMaterialHolderObservation(
        holder: .agent(fixture.seller),
        materialIdentity: fixture.bread1Stack.identity,
        quantity: 1,
        custodyFingerprint: performanceProduction.sourceCustodyFingerprintAfter,
        physicalReceiptID: performanceProduction.physicalReceiptID,
        observedAtTick: fixture.session.tick
    )
    try! b04Register(
        assetID: performanceAsset, owner: fixture.seller,
        stack: fixture.bread1Stack, observation: performanceSource,
        witnesses: [fixture.seller, fixture.buyer, fixture.merchant],
        session: &fixture.session
    )
    e05BindProduction(
        assetID: performanceAsset,
        operationID: performanceProduction.operationID,
        session: &fixture.session
    )
    let fulfillmentReceipt = "e05-contract-fulfillment"
    let performanceDestination = AgentMaterialHolderObservation(
        holder: .agent(fixture.buyer),
        materialIdentity: fixture.bread1Stack.identity,
        quantity: 1, custodyFingerprint: "e05-contract-bread-received",
        physicalReceiptID: fulfillmentReceipt,
        observedAtTick: fixture.session.tick
    )
    try! fixture.session.recordVerifiedContractFulfillment(
        AgentVerifiedContractFulfillmentOutcome(
            operationID: fulfillmentReceipt,
            obligationID: acceptedObligation.obligationID,
            transfer: AgentVerifiedContractTransfer(
                assetID: performanceAsset,
                sourceObservation: performanceSource,
                destinationObservation: performanceDestination,
                physicalReceiptID: fulfillmentReceipt,
                productionOperationIDs: [performanceProduction.operationID]
            ), completedAtTick: fixture.session.tick
        )
    )
    check("verified exact produced performance fulfills contract once",
          fixture.session.contractSnapshot().obligations.first {
              $0.proposalID == contractID
          }?.status == .fulfilled
            && fixture.session.contractSnapshot().totalFulfilledCount == 1
            && fixture.session.productionSnapshot().needs.first {
                $0.needID == buyerBreadReason.needID
            }?.status == .fulfilled)
    let fulfilledBytes = try! fixture.session.durableStateBytes()
    check("terminal contract refuses duplicate fulfillment without mutation",
          (try? fixture.session.recordVerifiedContractFulfillment(
              AgentVerifiedContractFulfillmentOutcome(
                  operationID: fulfillmentReceipt,
                  obligationID: acceptedObligation.obligationID,
                  transfer: AgentVerifiedContractTransfer(
                      assetID: performanceAsset,
                      sourceObservation: performanceSource,
                      destinationObservation: performanceDestination,
                      physicalReceiptID: fulfillmentReceipt,
                      productionOperationIDs: [performanceProduction.operationID]
                  ), completedAtTick: fixture.session.tick
              )
          )) == nil
            && (try! fixture.session.durableStateBytes()) == fulfilledBytes)

    let marketSellerReason = e05Reason(
        "e05-need:seller:market-bread", actor: fixture.seller,
        item: "bread", quantity: 1, priority: 100,
        session: &fixture.session
    )
    let marketBuyerReason = e05Reason(
        "e05-need:buyer:market-pickaxe", actor: fixture.buyer,
        item: "stone_pickaxe", quantity: 1, priority: 100,
        session: &fixture.session
    )
    let currentReturnedPickaxe = fixture.session.materialRightsSnapshot()
        .records.first { $0.asset.assetID == fixture.pickaxe }!
        .lastVerifiedHolder
    let marketOpportunity = b04MarketOpportunity(
        "e05-market-opportunity:returned-pickaxe", fixture: fixture,
        seller: fixture.seller, assetID: fixture.pickaxe,
        stack: AgentMaterialStackSnapshot(
            identity: currentReturnedPickaxe.materialIdentity, count: 1
        ), source: currentReturnedPickaxe, reason: marketSellerReason,
        session: fixture.session
    )
    try! fixture.session.recordMarketDepositOpportunities([marketOpportunity])
    let depositProposal = fixture.session.nextAutonomousMarketDepositProposal()!
    try! b04ApplyDeposit(
        opportunity: marketOpportunity, depositID: depositProposal.depositID,
        fixture: fixture, session: &fixture.session
    )
    let listingProposal = fixture.session.nextAutonomousMarketListingProposal()!
    try! fixture.session.createMarketListing(
        operationID: "e05-market-listing", proposal: listingProposal
    )
    let listing = fixture.session.marketSnapshot().listings.first {
        $0.listingID == listingProposal.listingID
    }!
    let currentPerformanceBread = fixture.session.materialRightsSnapshot()
        .records.first { $0.asset.assetID == performanceAsset }!
        .lastVerifiedHolder
    let buyerProposal = b04BuyerProposal(
        "e05-market-proposal:contract-bread",
        listing: listing, buyer: fixture.buyer,
        assetID: performanceAsset, stack: fixture.bread1Stack,
        source: currentPerformanceBread, reason: marketBuyerReason,
        session: fixture.session
    )
    try! fixture.session.proposeMarketPurchase(
        operationID: "e05-market-propose", proposal: buyerProposal
    )
    let beforeUnavailable = try! fixture.session.durableStateBytes()
    check("unavailable seller cannot reactivate historical market authority",
          (try? fixture.session.nextAutonomousMarketSellerDecision(
              proposalID: buyerProposal.proposalID,
              currentLocality: e05Locality(
                  fixture: fixture, seller: fixture.seller,
                  buyer: fixture.buyer, sellerAlive: false,
                  tick: fixture.session.tick
              )
          )) == nil
            && (try! fixture.session.durableStateBytes()) == beforeUnavailable)
    let sellerDecision = try! fixture.session.nextAutonomousMarketSellerDecision(
        proposalID: buyerProposal.proposalID,
        currentLocality: e05Locality(
            fixture: fixture, seller: fixture.seller,
            buyer: fixture.buyer, tick: fixture.session.tick
        )
    )
    try! fixture.session.decideMarketProposal(
        operationID: "e05-market-decision", decision: sellerDecision
    )
    let acceptedMarket = fixture.session.marketSnapshot().proposals.first {
        $0.proposalID == buyerProposal.proposalID
    }!
    let beforeUnavailableSettlement = try! fixture.session.durableStateBytes()
    check("unavailable buyer blocks settlement while reservation remains retryable",
          (try? fixture.session.prevalidateMarketSettlementLocality(
              proposalID: buyerProposal.proposalID,
              currentLocality: e05Locality(
                  fixture: fixture, seller: fixture.seller,
                  buyer: fixture.buyer, buyerAlive: false,
                  tick: fixture.session.tick
              )
          )) == nil
            && (try! fixture.session.durableStateBytes())
                == beforeUnavailableSettlement
            && acceptedMarket.status == .accepted)

    let deposit = fixture.session.marketSnapshot().deposits.first {
        $0.depositID == listing.depositID
    }!
    let trade = AgentVerifiedMarketTrade(
        operationID: "e05-market-trade",
        tradeID: AgentMarketTradeID(rawValue: "e05-trade:returned-pickaxe")!,
        marketID: fixture.marketID, listingID: listing.listingID,
        proposalID: buyerProposal.proposalID,
        sellerID: fixture.seller, buyerID: fixture.buyer,
        terms: acceptedMarket.proposedTerms,
        offeredLeg: AgentVerifiedMarketTradeLeg(
            assetID: fixture.pickaxe,
            sourceObservation: deposit.lastMarketObservation,
            destinationObservation: AgentMaterialHolderObservation(
                holder: .agent(fixture.buyer),
                materialIdentity: currentReturnedPickaxe.materialIdentity,
                quantity: 1, custodyFingerprint: "e05-market-pickaxe-received",
                physicalReceiptID: "e05-market-offered-receipt",
                observedAtTick: fixture.session.tick
            ), physicalReceiptID: "e05-market-offered-receipt"
        ),
        considerationLeg: AgentVerifiedMarketTradeLeg(
            assetID: performanceAsset,
            sourceObservation: currentPerformanceBread,
            destinationObservation: AgentMaterialHolderObservation(
                holder: .agent(fixture.seller),
                materialIdentity: fixture.bread1Stack.identity,
                quantity: 1, custodyFingerprint: "e05-market-bread-received",
                physicalReceiptID: "e05-market-consideration-receipt",
                observedAtTick: fixture.session.tick
            ), physicalReceiptID: "e05-market-consideration-receipt"
        ), completedAtTick: fixture.session.tick
    )
    try! fixture.session.prevalidateMarketSettlementLocality(
        proposalID: buyerProposal.proposalID,
        currentLocality: e05Locality(
            fixture: fixture, seller: fixture.seller,
            buyer: fixture.buyer, tick: fixture.session.tick
        )
    )
    try! fixture.session.completeVerifiedMarketTrade(trade)
    let completedMarket = fixture.session.marketSnapshot()
    let completedRights = fixture.session.materialRightsSnapshot().records
    check("verified market settlement returns evolved tool to former holder",
          completedRights.first { $0.asset.assetID == fixture.pickaxe }?
            .recognizedOwnership?.ownerID == fixture.buyer
            && completedRights.first { $0.asset.assetID == fixture.pickaxe }?
                .lastVerifiedHolder.materialIdentity.damage == 1
            && completedRights.first { $0.asset.assetID == fixture.pickaxe }?
                .productionProvenance?.operationIDs
                == [pickaxeProduction.operationID])
    check("market settlement creates one local oriented price row only after receipts",
          completedMarket.totalTradeCount == 1
            && completedMarket.priceHistory.count == 1
            && completedMarket.priceHistory[0].marketID == fixture.marketID
            && completedMarket.priceHistory[0].tradeID == trade.tradeID
            && completedMarket.priceHistory[0].physicalReceiptIDs
                == ["e05-market-consideration-receipt",
                    "e05-market-offered-receipt"].sorted())
    check("verified market receipts close only their exact motivating needs",
          fixture.session.productionSnapshot().needs.first {
              $0.needID == marketSellerReason.needID
          }?.status == .fulfilled
            && fixture.session.productionSnapshot().needs.first {
                $0.needID == marketBuyerReason.needID
            }?.status == .fulfilled
            && fixture.session.productionSnapshot().needs.first {
                $0.needID == fixture.merchantBread3Reason.needID
            }?.status == .active)
    check("terminal economic history grants no current commitment authority",
          fixture.session.exactAssetCommitmentSnapshot().isEmpty
            && fixture.session.evaluateCurrentBarterMaterialUse(
                requestID: "e05-stale-owner-attempt",
                assetID: fixture.pickaxe, actorID: fixture.seller,
                currentObservation: currentReturnedPickaxe
            ) == nil)

    let finalCheckpoint = try! fixture.session.makeCheckpoint()
    let restored = try! AgentSimulationSession.restoring(finalCheckpoint)
    check("final schema 34 restart preserves origin, current identity, contracts and prices",
          finalCheckpoint.schemaVersion == 34
            && restored.contractSnapshot().totalFulfilledCount == 1
            && restored.marketSnapshot().totalTradeCount == 1
            && restored.marketSnapshot().priceHistory.count == 1
            && restored.materialRightsSnapshot().records.first {
                $0.asset.assetID == fixture.pickaxe
            }?.lastVerifiedHolder.materialIdentity.damage == 1
            && restored.materialRightsSnapshot().records.first {
                $0.asset.assetID == fixture.pickaxe
            }?.productionProvenance?.operationIDs
                == [pickaxeProduction.operationID]
            && restored.exactAssetCommitmentSnapshot().isEmpty)

    let observerBinding = try! AgentObserverWorldBinding(
        worldID: "gate-e-evaluation-05-world",
        storageIdentity: "memory:gate-e-evaluation-05", seed: 405,
        dimension: 0, observedWorldTick: 0
    )
    let beforeObserver = try! restored.durableStateBytes()
    let observer = restored.observerSnapshot(worldBinding: observerBinding)
    check("Observer schema 11 is read-only across the composed history",
          observer.header.schemaVersion == 11
            && (try! restored.durableStateBytes()) == beforeObserver)
    check("composed campaign remains bounded and conserves modeled state",
          restored.conservationSnapshot().balanced
            && restored.productionSnapshot().records.count
                <= restored.productionSnapshot().configuration!.maximumRecords
            && restored.barterSnapshot().offers.count
                <= restored.barterSnapshot().configuration!.maximumOffers
            && restored.contractSnapshot().obligations.count
                <= restored.contractSnapshot().configuration!.maximumObligations
            && restored.marketSnapshot().priceHistory.count
                <= restored.marketSnapshot().configuration!.maximumPriceHistoryRows)
}
