import Foundation
import PebbleAgents

private let b02Producer = AgentID(rawValue: "agent_0")!
private let b02Holder = AgentID(rawValue: "agent_1")!
private let b02Counterparty = AgentID(rawValue: "agent_2")!

private func b02Agent(_ id: String, x: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id, state: "idle", position: position,
        needs: AgentNeeds(hunger: 0.4, fatigue: 0, curiosity: 0.2, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "evolved production identity",
            startedAtTick: 0, urgency: 80
        ), lastAction: nil, lastActionEffect: nil, memory: [],
        tickCreated: 0, ticksAlive: 0, observationCount: 0,
        nearbyObservationCount: 0, goalSelectionCount: 0,
        goalChangeCount: 0, actionCount: 0, actionEffectCount: 0,
        movementCount: 0, totalManhattanDistanceMoved: 0,
        returnHomeMoveCount: 0, totalDistanceReducedTowardHome: 0
    )
}

private func b02Identity(
    _ itemKey: String,
    damage: Int = 0
) -> AgentMaterialIdentitySnapshot {
    AgentMaterialIdentitySnapshot(
        itemKey: itemKey, damage: damage, enchantments: [], label: nil,
        canonicalDataJSON: "{}"
    )
}

private func b02Stack(
    _ itemKey: String,
    count: Int = 1,
    damage: Int = 0
) -> AgentMaterialStackSnapshot {
    AgentMaterialStackSnapshot(
        identity: b02Identity(itemKey, damage: damage), count: count
    )
}

private struct B02Fixture {
    var session: AgentSimulationSession
    let assetID: AgentMaterialAssetID
    let production: AgentVerifiedProductionOutcome
    let breadAssetID: AgentMaterialAssetID
}

private func b02RegisterAsset(
    assetID: AgentMaterialAssetID,
    stack: AgentMaterialStackSnapshot,
    holder: AgentID,
    fingerprint: String,
    receipt: String,
    productionOperationIDs: [String],
    witnesses: [AgentID],
    session: inout AgentSimulationSession
) throws -> AgentMaterialHolderObservation {
    let observation = AgentMaterialHolderObservation(
        holder: .agent(holder), materialIdentity: stack.identity,
        quantity: stack.count, custodyFingerprint: fingerprint,
        physicalReceiptID: receipt, observedAtTick: session.tick
    )
    let prefix = "blocker-02-rights:\(assetID.rawValue)"
    let claimID = AgentMaterialClaimID(rawValue: "\(prefix):claim")!
    _ = try session.applyMaterialRightsOperation(.register(
        operationID: "\(prefix):register",
        asset: AgentMaterialAssetReference(
            assetID: assetID, materialIdentity: stack.identity,
            quantity: stack.count
        ), observation: observation
    ))
    if !productionOperationIDs.isEmpty {
        _ = try session.applyMaterialRightsOperation(.bindProductionProvenance(
            operationID: "\(prefix):bind", assetID: assetID,
            productionOperationIDs: productionOperationIDs.sorted()
        ))
    }
    _ = try session.applyMaterialRightsOperation(.assertClaim(
        operationID: "\(prefix):claim", assetID: assetID,
        claimID: claimID, claimantID: holder,
        basis: productionOperationIDs.isEmpty ? .found : .produced
    ))
    _ = try session.applyMaterialRightsOperation(.recognizeOwnership(
        operationID: "\(prefix):recognize", assetID: assetID,
        claimID: claimID, recognizingAgentIDs: witnesses
    ))
    return observation
}

private func b02Fixture(
    _ simulationID: String,
    maximumProductionRecords: Int = 256
) -> B02Fixture {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 402, memoryPolicy: .bounded(maxEntries: 64)
        ), agents: [
            b02Agent("agent_0", x: 0), b02Agent("agent_1", x: 2),
            b02Agent("agent_2", x: 4),
        ], simulationID: try! AgentSimulationID(validating: simulationID),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
    try! session.setProductionEnabled(
        true,
        configuration: try! AgentProductionConfiguration(
            maximumRecords: maximumProductionRecords
        )
    )
    try! session.setMaterialRightsEnabled(true)

    let needID = AgentProductionNeedID(rawValue: "blocker-02:pickaxe")!
    try! session.raiseProductionNeed(
        needID: needID, actorID: b02Producer, reason: .missingUsefulTool,
        desiredOutputItemKey: "stone_pickaxe", quantity: 1, priority: 99
    )
    let opportunity = AgentProductionOpportunityObservation(
        opportunityID: AgentProductionOpportunityID(
            rawValue: "blocker-02:production-opportunity"
        )!, needID: needID, actorID: b02Producer,
        recipeID: "craft:stone_pickaxe",
        workshopPosition: AgentPosition(x: 1, y: 64, z: 0),
        workshopBlockKey: "crafting_table",
        sourceLocationID: "agent:agent_0",
        sourceCustodyFingerprint: "blocker-02:raw-inputs",
        planFingerprint: "blocker-02:pickaxe-plan",
        inputs: [b02Stack("cobblestone", count: 3), b02Stack("stick", count: 2)],
        output: b02Stack("stone_pickaxe"), observedAtTick: session.tick,
        expiresAtTick: session.tick + 2
    )
    try! session.recordProductionOpportunity(opportunity)
    let production = AgentVerifiedProductionOutcome(
        operationID: "blocker-02:produce:stone-pickaxe",
        opportunityID: opportunity.opportunityID, actorID: b02Producer,
        recipeID: opportunity.recipeID,
        workshopPosition: opportunity.workshopPosition,
        workshopBlockKey: opportunity.workshopBlockKey,
        sourceLocationID: opportunity.sourceLocationID,
        sourceCustodyFingerprintBefore: opportunity.sourceCustodyFingerprint,
        sourceCustodyFingerprintAfter: "blocker-02:pickaxe-produced",
        planFingerprint: opportunity.planFingerprint,
        inputsConsumed: opportunity.inputs, outputProduced: opportunity.output,
        physicalReceiptID: "blocker-02:produce:stone-pickaxe",
        completedAtTick: session.tick
    )
    try! session.recordVerifiedProduction(production)
    let assetID = AgentMaterialAssetID(
        rawValue: "gate-e-blocker-02-produced-pickaxe"
    )!
    _ = try! b02RegisterAsset(
        assetID: assetID, stack: production.outputProduced,
        holder: b02Producer,
        fingerprint: production.sourceCustodyFingerprintAfter,
        receipt: production.physicalReceiptID,
        productionOperationIDs: [production.operationID],
        witnesses: [b02Producer, b02Holder, b02Counterparty],
        session: &session
    )
    _ = try! session.applyMaterialRightsOperation(.grantUse(
        operationID: "blocker-02:rights:recipient-use",
        assetID: assetID,
        permissionID: AgentMaterialPermissionID(
            rawValue: "blocker-02:recipient-use"
        )!, grantorID: b02Producer, userID: b02Holder,
        allowedUses: [.toolUse, .transferCustody], expiresAtTick: nil
    ))
    let source = session.materialRightsSnapshot().records.first {
        $0.asset.assetID == assetID
    }!.lastVerifiedHolder
    let transferRequest = AgentMaterialUseRequest(
        requestID: "blocker-02:transfer-request", assetID: assetID,
        actorID: b02Producer, use: .transferCustody, verifiedHolder: source
    )
    let transferDecision = session.evaluateMaterialUse(transferRequest)
    let transferred = AgentMaterialHolderObservation(
        holder: .agent(b02Holder), materialIdentity: source.materialIdentity,
        quantity: source.quantity,
        custodyFingerprint: "blocker-02:holder:damage-0",
        physicalReceiptID: "blocker-02:transfer-to-holder",
        observedAtTick: session.tick
    )
    _ = try! session.applyMaterialRightsOperation(.physicalTransfer(
        AgentMaterialPhysicalTransferOutcome(
            operationID: "blocker-02:transfer-to-holder",
            decision: transferDecision, disposition: .authorized,
            status: .succeeded, destinationObservation: transferred,
            physicalReceiptID: transferred.physicalReceiptID
        )
    ))
    let producerClaim = AgentMaterialClaimID(
        rawValue: "blocker-02-rights:\(assetID.rawValue):claim"
    )!
    _ = try! session.applyMaterialRightsOperation(.withdrawClaim(
        operationID: "blocker-02:rights:producer-releases-claim",
        assetID: assetID, claimID: producerClaim, actorID: b02Producer
    ))
    let recipientClaim = AgentMaterialClaimID(
        rawValue: "blocker-02:rights:recipient-claim"
    )!
    _ = try! session.applyMaterialRightsOperation(.assertClaim(
        operationID: "blocker-02:rights:recipient-claim",
        assetID: assetID, claimID: recipientClaim,
        claimantID: b02Holder, basis: .received
    ))
    _ = try! session.applyMaterialRightsOperation(.recognizeOwnership(
        operationID: "blocker-02:rights:recipient-owner",
        assetID: assetID, claimID: recipientClaim,
        recognizingAgentIDs: [b02Producer, b02Holder, b02Counterparty]
    ))
    let useRequest = AgentMaterialUseRequest(
        requestID: "blocker-02:use:damage-1", assetID: assetID,
        actorID: b02Holder, use: .toolUse, verifiedHolder: transferred
    )
    let useDecision = session.evaluateMaterialUse(useRequest)
    let evolved = AgentMaterialHolderObservation(
        holder: .agent(b02Holder),
        materialIdentity: b02Identity("stone_pickaxe", damage: 1),
        quantity: 1, custodyFingerprint: "blocker-02:holder:damage-1",
        physicalReceiptID: "blocker-02:use:damage-1",
        observedAtTick: session.tick
    )
    _ = try! session.applyMaterialRightsOperation(.useAttempt(
        AgentMaterialUseAttemptOutcome(
            operationID: "blocker-02:use:damage-1", decision: useDecision,
            status: .succeeded, resultingObservation: evolved,
            physicalReceiptID: evolved.physicalReceiptID
        )
    ))

    let breadAssetID = AgentMaterialAssetID(
        rawValue: "gate-e-blocker-02-counterparty-bread"
    )!
    _ = try! b02RegisterAsset(
        assetID: breadAssetID, stack: b02Stack("bread"),
        holder: b02Counterparty, fingerprint: "blocker-02:bread-current",
        receipt: "blocker-02:bread-observed", productionOperationIDs: [],
        witnesses: [b02Producer, b02Holder, b02Counterparty],
        session: &session
    )
    try! session.raiseProductionNeed(
        needID: AgentProductionNeedID(rawValue: "blocker-02:holder:bread")!,
        actorID: b02Holder, reason: .physicalFoodNeed,
        desiredOutputItemKey: "bread", quantity: 1, priority: 98
    )
    try! session.raiseProductionNeed(
        needID: AgentProductionNeedID(rawValue: "blocker-02:counterparty:tool")!,
        actorID: b02Counterparty, reason: .missingUsefulTool,
        desiredOutputItemKey: "stone_pickaxe", quantity: 1, priority: 97
    )
    try! session.setBarterEnabled(true)
    return B02Fixture(
        session: session, assetID: assetID, production: production,
        breadAssetID: breadAssetID
    )
}

private func b02Leg(
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
        productionOperationIDs: record.productionProvenance?.operationIDs ?? []
    )
}

private func b02PhysicalPair(
    _ fixture: B02Fixture,
    session: AgentSimulationSession,
    suffix: String
) -> AgentBarterPhysicalPairObservation {
    AgentBarterPhysicalPairObservation(
        candidateID: "blocker-02:barter:\(suffix)",
        actorAID: b02Holder, actorBID: b02Counterparty,
        actorAGood: b02Leg(
            assetID: fixture.assetID, holder: b02Holder, session: session
        ), actorBGood: b02Leg(
            assetID: fixture.breadAssetID, holder: b02Counterparty,
            session: session
        ), distance: 2, lineOfSight: true, chunksReady: true,
        observedAtTick: session.tick,
        expiresAtTick: session.tick
            + session.barterSnapshot().configuration!.offerLifetimeTicks
    )
}

private func b02PhysicalPair(
    _ fixture: B02Fixture,
    session: AgentSimulationSession,
    suffix: String,
    toolLeg: AgentBarterLeg
) -> AgentBarterPhysicalPairObservation {
    AgentBarterPhysicalPairObservation(
        candidateID: "blocker-02:barter:\(suffix)",
        actorAID: b02Holder, actorBID: b02Counterparty,
        actorAGood: toolLeg, actorBGood: b02Leg(
            assetID: fixture.breadAssetID, holder: b02Counterparty,
            session: session
        ), distance: 2, lineOfSight: true, chunksReady: true,
        observedAtTick: session.tick,
        expiresAtTick: session.tick
            + session.barterSnapshot().configuration!.offerLifetimeTicks
    )
}

@discardableResult
private func b02EvolveTool(
    assetID: AgentMaterialAssetID,
    actorID: AgentID,
    damage: Int,
    suffix: String,
    session: inout AgentSimulationSession
) throws -> AgentMaterialHolderObservation {
    let source = session.materialRightsSnapshot().records.first {
        $0.asset.assetID == assetID
    }!.lastVerifiedHolder
    let request = AgentMaterialUseRequest(
        requestID: "blocker-02:use-request:\(suffix)", assetID: assetID,
        actorID: actorID, use: .toolUse, verifiedHolder: source
    )
    let decision = session.evaluateMaterialUse(request)
    guard decision.verdict == .allowed else {
        throw AgentMaterialRightsError.unauthorized(decision.reason.rawValue)
    }
    let observation = AgentMaterialHolderObservation(
        holder: .agent(actorID),
        materialIdentity: b02Identity("stone_pickaxe", damage: damage),
        quantity: 1, custodyFingerprint: "blocker-02:current:\(suffix)",
        physicalReceiptID: "blocker-02:use:\(suffix)",
        observedAtTick: session.tick
    )
    _ = try session.applyMaterialRightsOperation(.useAttempt(
        AgentMaterialUseAttemptOutcome(
            operationID: "blocker-02:use:\(suffix)", decision: decision,
            status: .succeeded, resultingObservation: observation,
            physicalReceiptID: observation.physicalReceiptID
        )
    ))
    return observation
}

private func b02DiscoveryFailsClosed(
    pair: AgentBarterPhysicalPairObservation,
    session: AgentSimulationSession
) -> Bool {
    let before = try! session.durableStateBytes()
    do {
        let discoveries = try session.discoverBarterOpportunities(from: [pair])
        return discoveries.isEmpty && (try! session.durableStateBytes()) == before
    } catch {
        return (try! session.durableStateBytes()) == before
    }
}

private func b02SettleBarter(
    fixture: B02Fixture,
    suffix: String,
    session: inout AgentSimulationSession
) throws -> AgentVerifiedBarterOutcome {
    let opportunity = try session.discoverBarterOpportunities(from: [
        b02PhysicalPair(fixture, session: session, suffix: suffix),
    ]).first!
    try session.recordBarterOpportunity(opportunity)
    let proposal = session.nextAutonomousBarterOfferProposal()!
    try session.createBarterOffer(
        offerID: proposal.offerID, opportunityID: proposal.opportunityID,
        actorID: proposal.actorID
    )
    _ = try session.advanceTick()
    let decision = session.evaluateAutonomousBarterCounterpartyDecision(
        AgentBarterCounterpartyDecisionObservation(
            offerID: proposal.offerID,
            counterpartyID: opportunity.counterpartyID,
            distance: 2, lineOfSight: true, chunksReady: true,
            observedAtTick: session.tick
        )
    )!
    try session.decideBarterOffer(
        offerID: decision.offerID, counterpartyID: decision.counterpartyID,
        accept: decision.accept, reason: decision.reason
    )
    let receipt = "blocker-02:barter-settlement:\(suffix)"
    let outcome = AgentVerifiedBarterOutcome(
        operationID: receipt, offerID: proposal.offerID,
        offeredLeg: AgentVerifiedBarterLeg(
            assetID: opportunity.offered.assetID,
            sourceObservation: opportunity.offered.holderObservation,
            destinationObservation: AgentMaterialHolderObservation(
                holder: .agent(opportunity.counterpartyID),
                materialIdentity: opportunity.offered.material.identity,
                quantity: opportunity.offered.material.count,
                custodyFingerprint: "blocker-02:counterparty:pickaxe:\(suffix)",
                physicalReceiptID: "\(receipt):pickaxe",
                observedAtTick: session.tick
            ), physicalReceiptID: "\(receipt):pickaxe"
        ), requestedLeg: AgentVerifiedBarterLeg(
            assetID: opportunity.requested.assetID,
            sourceObservation: opportunity.requested.holderObservation,
            destinationObservation: AgentMaterialHolderObservation(
                holder: .agent(opportunity.offerorID),
                materialIdentity: opportunity.requested.material.identity,
                quantity: opportunity.requested.material.count,
                custodyFingerprint: "blocker-02:holder:bread:\(suffix)",
                physicalReceiptID: "\(receipt):bread",
                observedAtTick: session.tick
            ), physicalReceiptID: "\(receipt):bread"
        ), completedAtTick: session.tick
    )
    try session.recordVerifiedBarter(outcome)
    return outcome
}

private func b02ContractDiscoveryPasses(_ fixture: B02Fixture) -> Bool {
    var session = fixture.session
    do {
        try session.setContractsEnabled(true)
        let needs = session.productionSnapshot().needs
        let holderNeed = needs.first {
            $0.needID.rawValue == "blocker-02:holder:bread"
        }!
        let counterpartyNeed = needs.first {
            $0.needID.rawValue == "blocker-02:counterparty:tool"
        }!
        let opportunity = AgentContractOpportunityObservation(
            opportunityID: "blocker-02:contract:evolved-consideration",
            promisorID: b02Counterparty, promiseeID: b02Holder,
            consideration: b02Leg(
                assetID: fixture.assetID, holder: b02Holder, session: session
            ), promisorReason: AgentBarterValueReason(need: counterpartyNeed),
            promiseeReason: AgentBarterValueReason(need: holderNeed),
            promisedPerformance: AgentContractPerformanceTerms(
                material: b02Stack("bread")
            ), distance: 2, lineOfSight: true, chunksReady: true,
            observedAtTick: session.tick,
            expiresAtTick: session.tick
                + session.contractSnapshot().configuration!.proposalLifetimeTicks
        )
        let before = try session.durableStateBytes()
        let result = try session.discoverContractOpportunities(from: [opportunity])
        let after = try session.durableStateBytes()
        return result.count == 1
            && result[0].consideration.material.identity.damage == 1
            && result[0].consideration.productionOperationIDs
                == [fixture.production.operationID]
            && after == before
    } catch {
        return false
    }
}

private func b02ContractPerformancePasses(_ fixture: B02Fixture) -> Bool {
    var session = fixture.session
    do {
        try session.setContractsEnabled(true)
        let needs = session.productionSnapshot().needs
        let holderNeed = needs.first {
            $0.needID.rawValue == "blocker-02:holder:bread"
        }!
        let counterpartyNeed = needs.first {
            $0.needID.rawValue == "blocker-02:counterparty:tool"
        }!
        let opportunity = AgentContractOpportunityObservation(
            opportunityID: "blocker-02:contract:evolved-performance",
            promisorID: b02Holder, promiseeID: b02Counterparty,
            consideration: b02Leg(
                assetID: fixture.breadAssetID, holder: b02Counterparty,
                session: session
            ), promisorReason: AgentBarterValueReason(need: holderNeed),
            promiseeReason: AgentBarterValueReason(need: counterpartyNeed),
            promisedPerformance: AgentContractPerformanceTerms(
                material: b02Leg(
                    assetID: fixture.assetID, holder: b02Holder,
                    session: session
                ).material
            ), distance: 2, lineOfSight: true, chunksReady: true,
            observedAtTick: session.tick,
            expiresAtTick: session.tick
                + session.contractSnapshot().configuration!.proposalLifetimeTicks
        )
        let discovery = try session.discoverContractOpportunities(
            from: [opportunity]
        ).first!
        try session.recordContractOpportunity(discovery)
        let proposal = session.nextAutonomousPromiseProposal()!
        try session.createPromiseProposal(
            proposalID: proposal.proposalID,
            opportunityID: proposal.opportunityID,
            promisorID: proposal.promisorID
        )
        _ = try session.advanceTick()
        try session.decidePromiseProposal(
            proposalID: proposal.proposalID,
            promiseeID: b02Counterparty, accept: true,
            reason: "counterparty accepts exact evolved tool performance"
        )
        let obligation = session.contractSnapshot().obligations.first!
        let breadRecord = session.materialRightsSnapshot().records.first {
            $0.asset.assetID == fixture.breadAssetID
        }!
        let considerationReceipt = "blocker-02:contract:consideration"
        try session.recordVerifiedContractConsideration(
            AgentVerifiedContractConsiderationOutcome(
                operationID: considerationReceipt,
                obligationID: obligation.obligationID,
                transfer: AgentVerifiedContractTransfer(
                    assetID: fixture.breadAssetID,
                    sourceObservation: AgentMaterialHolderObservation(
                        holder: .agent(b02Counterparty),
                        materialIdentity:
                            breadRecord.lastVerifiedHolder.materialIdentity,
                        quantity: breadRecord.lastVerifiedHolder.quantity,
                        custodyFingerprint:
                            breadRecord.lastVerifiedHolder.custodyFingerprint,
                        physicalReceiptID:
                            "blocker-02:contract:bread-current",
                        observedAtTick: session.tick
                    ), destinationObservation: AgentMaterialHolderObservation(
                        holder: .agent(b02Holder),
                        materialIdentity:
                            breadRecord.lastVerifiedHolder.materialIdentity,
                        quantity: breadRecord.lastVerifiedHolder.quantity,
                        custodyFingerprint:
                            "blocker-02:contract:bread-destination",
                        physicalReceiptID: considerationReceipt,
                        observedAtTick: session.tick
                    ), physicalReceiptID: considerationReceipt,
                    productionOperationIDs: []
                ), completedAtTick: session.tick
            )
        )
        let toolRecord = session.materialRightsSnapshot().records.first {
            $0.asset.assetID == fixture.assetID
        }!
        let fulfillmentReceipt = "blocker-02:contract:fulfillment"
        try session.recordVerifiedContractFulfillment(
            AgentVerifiedContractFulfillmentOutcome(
                operationID: fulfillmentReceipt,
                obligationID: obligation.obligationID,
                transfer: AgentVerifiedContractTransfer(
                    assetID: fixture.assetID,
                    sourceObservation: AgentMaterialHolderObservation(
                        holder: .agent(b02Holder),
                        materialIdentity:
                            toolRecord.lastVerifiedHolder.materialIdentity,
                        quantity: toolRecord.lastVerifiedHolder.quantity,
                        custodyFingerprint:
                            toolRecord.lastVerifiedHolder.custodyFingerprint,
                        physicalReceiptID:
                            "blocker-02:contract:tool-current",
                        observedAtTick: session.tick
                    ), destinationObservation: AgentMaterialHolderObservation(
                        holder: .agent(b02Counterparty),
                        materialIdentity:
                            toolRecord.lastVerifiedHolder.materialIdentity,
                        quantity: toolRecord.lastVerifiedHolder.quantity,
                        custodyFingerprint:
                            "blocker-02:contract:tool-destination",
                        physicalReceiptID: fulfillmentReceipt,
                        observedAtTick: session.tick
                    ), physicalReceiptID: fulfillmentReceipt,
                    productionOperationIDs: [fixture.production.operationID]
                ), completedAtTick: session.tick
            )
        )
        let final = session.materialRightsSnapshot().records.first {
            $0.asset.assetID == fixture.assetID
        }!
        return session.contractSnapshot().totalFulfilledCount == 1
            && final.lastVerifiedHolder.materialIdentity.damage == 1
            && final.productionProvenance?.origins.first?
                .outputProduced.identity.damage == 0
            && final.productionProvenance?.operationIDs
                == [fixture.production.operationID]
    } catch {
        return false
    }
}

private func b02ProduceCompactionRecord(
    ordinal: Int,
    session: inout AgentSimulationSession
) throws -> AgentVerifiedProductionOutcome {
    let needID = AgentProductionNeedID(
        rawValue: "blocker-02:compaction:\(ordinal)"
    )!
    try session.raiseProductionNeed(
        needID: needID, actorID: b02Producer, reason: .materialWork,
        desiredOutputItemKey: "cobblestone", quantity: 1, priority: 80
    )
    let opportunity = AgentProductionOpportunityObservation(
        opportunityID: AgentProductionOpportunityID(
            rawValue: "blocker-02:compaction-opportunity:\(ordinal)"
        )!, needID: needID, actorID: b02Producer,
        recipeID: "proof:cobblestone",
        workshopPosition: AgentPosition(x: 1, y: 64, z: 0),
        workshopBlockKey: "crafting_table",
        sourceLocationID: "agent:agent_0",
        sourceCustodyFingerprint: "blocker-02:compaction-before:\(ordinal)",
        planFingerprint: "blocker-02:compaction-plan:\(ordinal)",
        inputs: [b02Stack("stone")], output: b02Stack("cobblestone"),
        observedAtTick: session.tick, expiresAtTick: session.tick + 2
    )
    try session.recordProductionOpportunity(opportunity)
    let outcome = AgentVerifiedProductionOutcome(
        operationID: "blocker-02:compaction-production:\(ordinal)",
        opportunityID: opportunity.opportunityID, actorID: b02Producer,
        recipeID: opportunity.recipeID,
        workshopPosition: opportunity.workshopPosition,
        workshopBlockKey: opportunity.workshopBlockKey,
        sourceLocationID: opportunity.sourceLocationID,
        sourceCustodyFingerprintBefore: opportunity.sourceCustodyFingerprint,
        sourceCustodyFingerprintAfter: "blocker-02:compaction-after:\(ordinal)",
        planFingerprint: opportunity.planFingerprint,
        inputsConsumed: opportunity.inputs, outputProduced: opportunity.output,
        physicalReceiptID: "blocker-02:compaction-production:\(ordinal)",
        completedAtTick: session.tick
    )
    try session.recordVerifiedProduction(outcome)
    return outcome
}

private func b02ForgedOriginIdentityFailsClosed(
    _ checkpoint: AgentSessionCheckpoint
) -> Bool {
    do {
        var root = try JSONSerialization.jsonObject(
            with: AgentCheckpointCodec.encode(checkpoint)
        ) as! [String: Any]
        var durable = root["durableState"] as! [String: Any]
        var rights = durable["materialRightsState"] as! [String: Any]
        var records = rights["records"] as! [[String: Any]]
        let index = records.firstIndex { $0["productionProvenance"] != nil }!
        var provenance = records[index]["productionProvenance"] as! [String: Any]
        var origins = provenance["origins"] as! [[String: Any]]
        let original = checkpoint.durableState.materialRightsState!.records[index]
            .productionProvenance!.origins[0]
        let forged = AgentMaterialProductionOriginProof(
            operationID: original.operationID, producerID: original.producerID,
            outputProduced: AgentMaterialStackSnapshot(
                identity: b02Identity("stone_pickaxe", damage: 9),
                count: original.outputProduced.count
            ), physicalReceiptID: original.physicalReceiptID,
            sourceLocationID: original.sourceLocationID,
            sourceCustodyFingerprintBefore:
                original.sourceCustodyFingerprintBefore,
            sourceCustodyFingerprintAfter:
                original.sourceCustodyFingerprintAfter,
            completedAtTick: original.completedAtTick,
            causalEventID: original.causalEventID
        )
        origins[0] = try JSONSerialization.jsonObject(
            with: AgentCheckpointCodec.encode(forged)
        ) as! [String: Any]
        provenance["origins"] = origins
        records[index]["productionProvenance"] = provenance
        rights["records"] = records
        durable["materialRightsState"] = rights
        let mutated = try JSONSerialization.data(
            withJSONObject: durable,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
        let state = try AgentCheckpointCodec.decode(
            AgentSessionDurableState.self, from: mutated
        )
        let durableBytes = try AgentCheckpointCodec.encode(state)
        let canonical = try JSONSerialization.jsonObject(
            with: durableBytes
        ) as! [String: Any]
        let clock = canonical["clock"] as! [String: Any]
        let simulationID = clock["simulationID"] as! String
        let tick = clock["tick"] as! Int
        let digest = AgentCheckpointDigest.sha256(durableBytes)
        let simulationDigest = AgentCheckpointDigest.sha256(
            Data(simulationID.utf8)
        )
        root["durableState"] = canonical
        root["schemaVersion"] = canonical["schemaVersion"]
        root["semanticDigest"] = digest.rawValue
        root["checkpointID"] =
            "checkpoint-\(simulationDigest.rawValue.prefix(12))"
                + "-t\(tick)-\(digest.rawValue.prefix(16))"
        let resigned = try AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self,
            from: JSONSerialization.data(
                withJSONObject: root,
                options: [.sortedKeys, .withoutEscapingSlashes]
            )
        )
        _ = try AgentSimulationSession.restoring(resigned)
        return false
    } catch {
        return true
    }
}

func runPebbleAgentsEvolvedProductionIdentitySmoke() {
    section("Gate E Blocker 02 evolved current identity and immutable production origin")

    let fixture = b02Fixture("gate-e-blocker-02-primary")
    let record = fixture.session.materialRightsSnapshot().records.first {
        $0.asset.assetID == fixture.assetID
    }!
    check("immutable production origin remains damage zero",
          record.productionProvenance?.origins.first?.outputProduced.identity.damage == 0)
    check("current verified identity advances to damage one",
          record.lastVerifiedHolder.materialIdentity.damage == 1)
    check("durable asset continuity permits the evolved identity",
          record.asset.permitsCurrentIdentity(record.lastVerifiedHolder.materialIdentity))
    check("immutable origin and current full identity remain unequal",
          record.asset.materialIdentity != record.lastVerifiedHolder.materialIdentity)
    check("production provenance remains one unchanged exact operation",
          record.productionProvenance?.operationIDs == [fixture.production.operationID])

    let beforeDiscovery = try! fixture.session.durableStateBytes()
    let discoveries = try? fixture.session.discoverBarterOpportunities(
        from: [b02PhysicalPair(
            fixture, session: fixture.session, suffix: "damage-1"
        )]
    )
    check("normal barter discovery accepts the same legitimately evolved produced asset",
          discoveries?.count == 1
            && discoveries?.first?.offered.material.identity.damage == 1
            && discoveries?.first?.offered.productionOperationIDs
                == [fixture.production.operationID])
    check("barter discovery remains a pure non-mutating evaluation",
          (try! fixture.session.durableStateBytes()) == beforeDiscovery)

    let currentTool = b02Leg(
        assetID: fixture.assetID, holder: b02Holder, session: fixture.session
    )
    func toolLeg(
        identity: AgentMaterialIdentitySnapshot,
        quantity: Int,
        holder: AgentMaterialPhysicalHolder = .agent(b02Holder),
        fingerprint: String? = nil,
        operationIDs: [String]? = nil,
        assetID: AgentMaterialAssetID? = nil
    ) -> AgentBarterLeg {
        let observation = AgentMaterialHolderObservation(
            holder: holder, materialIdentity: identity, quantity: quantity,
            custodyFingerprint:
                fingerprint ?? currentTool.holderObservation.custodyFingerprint,
            physicalReceiptID: currentTool.holderObservation.physicalReceiptID,
            observedAtTick: fixture.session.tick
        )
        return AgentBarterLeg(
            assetID: assetID ?? fixture.assetID, holderID: b02Holder,
            material: AgentMaterialStackSnapshot(
                identity: identity, count: quantity
            ), holderObservation: observation,
            productionOperationIDs: operationIDs
                ?? currentTool.productionOperationIDs
        )
    }
    check("different item key fails closed",
          b02DiscoveryFailsClosed(
              pair: b02PhysicalPair(
                  fixture, session: fixture.session,
                  suffix: "wrong-item",
                  toolLeg: toolLeg(identity: b02Identity("iron_pickaxe"), quantity: 1)
              ), session: fixture.session
          ))
    check("wrong current quantity fails closed",
          b02DiscoveryFailsClosed(
              pair: b02PhysicalPair(
                  fixture, session: fixture.session,
                  suffix: "wrong-quantity",
                  toolLeg: toolLeg(
                      identity: currentTool.material.identity, quantity: 2
                  )
              ), session: fixture.session
          ))
    check("current holder mismatch fails closed",
          b02DiscoveryFailsClosed(
              pair: b02PhysicalPair(
                  fixture, session: fixture.session,
                  suffix: "wrong-holder",
                  toolLeg: toolLeg(
                      identity: currentTool.material.identity, quantity: 1,
                      holder: .agent(b02Producer)
                  )
              ), session: fixture.session
          ))
    check("stale current custody fingerprint fails closed",
          b02DiscoveryFailsClosed(
              pair: b02PhysicalPair(
                  fixture, session: fixture.session,
                  suffix: "stale-fingerprint",
                  toolLeg: toolLeg(
                      identity: currentTool.material.identity, quantity: 1,
                      fingerprint: "blocker-02:stale-fingerprint"
                  )
              ), session: fixture.session
          ))
    check("forged production operation fails closed",
          b02DiscoveryFailsClosed(
              pair: b02PhysicalPair(
                  fixture, session: fixture.session,
                  suffix: "forged-operation",
                  toolLeg: toolLeg(
                      identity: currentTool.material.identity, quantity: 1,
                      operationIDs: ["blocker-02:forged-production"]
                  )
              ), session: fixture.session
          ))
    check("production provenance cannot authorize another durable asset",
          b02DiscoveryFailsClosed(
              pair: b02PhysicalPair(
                  fixture, session: fixture.session,
                  suffix: "cross-asset",
                  toolLeg: toolLeg(
                      identity: currentTool.material.identity, quantity: 1,
                      assetID: fixture.breadAssetID
                  )
              ), session: fixture.session
          ))
    check("identity outside canonical asset continuity fails closed",
          !record.asset.permitsCurrentIdentity(b02Identity("iron_pickaxe"))
            && b02DiscoveryFailsClosed(
                pair: b02PhysicalPair(
                    fixture, session: fixture.session,
                    suffix: "continuity-refusal",
                    toolLeg: toolLeg(
                        identity: b02Identity("iron_pickaxe"), quantity: 1
                    )
                ), session: fixture.session
            ))
    check("validly digested origin identity inconsistent with registration fails closed",
          b02ForgedOriginIdentityFailsClosed(
              try! fixture.session.makeCheckpoint()
          ))

    check("CIV-36 contract discovery accepts evolved produced consideration",
          b02ContractDiscoveryPasses(fixture))
    check("CIV-36 fulfillment accepts evolved produced performance with exact current authority",
          b02ContractPerformancePasses(fixture))

    var authority = fixture.session
    let damageOnePair = b02PhysicalPair(
        fixture, session: authority, suffix: "stale-after-second-use"
    )
    let originBeforeSecondUse = authority.materialRightsSnapshot().records.first {
        $0.asset.assetID == fixture.assetID
    }!.productionProvenance
    _ = try! b02EvolveTool(
        assetID: fixture.assetID, actorID: b02Holder, damage: 2,
        suffix: "damage-2", session: &authority
    )
    let afterSecondUse = authority.materialRightsSnapshot().records.first {
        $0.asset.assetID == fixture.assetID
    }!
    check("second legitimate durability evolution advances damage one to two",
          afterSecondUse.lastVerifiedHolder.materialIdentity.damage == 2
            && afterSecondUse.asset.assetID == fixture.assetID)
    check("immutable production origin remains unchanged after second evolution",
          afterSecondUse.productionProvenance == originBeforeSecondUse
            && afterSecondUse.productionProvenance?.origins.first?
                .outputProduced.identity.damage == 0)
    check("stale damage-one current authority is refused after damage two",
          b02DiscoveryFailsClosed(pair: damageOnePair, session: authority))
    let damageTwoDiscoveries = try! authority.discoverBarterOpportunities(
        from: [b02PhysicalPair(
            fixture, session: authority, suffix: "damage-2-current"
        )]
    )
    check("reacquired exact damage-two authority succeeds",
          damageTwoDiscoveries.count == 1
            && damageTwoDiscoveries[0].offered.material.identity.damage == 2)

    var settled = b02Fixture("gate-e-blocker-02-settlement")
    let settlement = try! b02SettleBarter(
        fixture: settled, suffix: "evolved", session: &settled.session
    )
    let settledRecord = settled.session.materialRightsSnapshot().records.first {
        $0.asset.assetID == settled.assetID
    }!
    check("normal barter settlement transfers the evolved produced tool",
          settled.session.barterSnapshot().totalCompletedCount == 1
            && settledRecord.lastVerifiedHolder.holder == .agent(b02Counterparty)
            && settledRecord.lastVerifiedHolder.materialIdentity.damage == 1
            && settledRecord.recognizedOwnership?.ownerID == b02Counterparty
            && settledRecord.productionProvenance?.operationIDs
                == [settled.production.operationID])
    let settledBytes = try! settled.session.durableStateBytes()
    let duplicateSettlementRefused =
        (try? settled.session.recordVerifiedBarter(settlement)) == nil
    check("duplicate evolved-tool barter receipt remains exactly once",
          duplicateSettlementRefused
            && settled.session.barterSnapshot().totalCompletedCount == 1
            && settled.session.barterSnapshot().records.count == 1
            && (try! settled.session.durableStateBytes()) == settledBytes)
    _ = try! b02EvolveTool(
        assetID: settled.assetID, actorID: b02Counterparty, damage: 2,
        suffix: "settled-damage-2", session: &settled.session
    )

    let marketNeedID = AgentProductionNeedID(
        rawValue: "blocker-02:market-seller:bread"
    )!
    try! settled.session.raiseProductionNeed(
        needID: marketNeedID, actorID: b02Counterparty,
        reason: .physicalFoodNeed, desiredOutputItemKey: "bread",
        quantity: 1, priority: 99
    )
    try! settled.session.setMarketEnabled(true)
    let marketID = AgentMarketID(rawValue: "blocker-02:market")!
    try! settled.session.registerMarketPlace(
        operationID: "blocker-02:market:register", marketID: marketID,
        position: AgentPosition(x: 3, y: 64, z: 0),
        containerLocationID: "3,64,0", containerBlockFingerprint: 402,
        interactionRadius: 8, physicalSlotCapacity: 9
    )
    let marketSource = settled.session.materialRightsSnapshot().records.first {
        $0.asset.assetID == settled.assetID
    }!.lastVerifiedHolder
    let marketReason = AgentBarterValueReason(
        need: settled.session.productionSnapshot().needs.first {
            $0.needID == marketNeedID
        }!
    )
    let marketOpportunity = AgentMarketDepositOpportunity(
        opportunityID: "blocker-02:market:opportunity",
        marketID: marketID, sellerID: b02Counterparty,
        offered: b02Leg(
            assetID: settled.assetID, holder: b02Counterparty,
            session: settled.session
        ), quoteReason: marketReason,
        marketPosition: AgentPosition(x: 3, y: 64, z: 0),
        containerLocationID: "3,64,0",
        currentContainerFingerprint: "blocker-02:market:empty",
        physicalSlotCapacity: 9, physicalOccupiedSlots: 0,
        distance: 1, chunksReady: true,
        observedAtTick: settled.session.tick,
        expiresAtTick: settled.session.tick + 2
    )
    let replayBase = try! settled.session.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(
        checkpoint: replayBase, session: settled.session
    )
    _ = try! recorder.apply(
        .recordMarketDepositOpportunities([marketOpportunity]),
        to: &settled.session
    )
    let depositProposal = settled.session.nextAutonomousMarketDepositProposal()!
    let marketObservation = AgentMaterialHolderObservation(
        holder: .container("3,64,0"),
        materialIdentity: marketSource.materialIdentity,
        quantity: marketSource.quantity,
        custodyFingerprint: "blocker-02:market:damage-2",
        physicalReceiptID: "blocker-02:market:deposit",
        observedAtTick: settled.session.tick
    )
    let deposit = AgentVerifiedMarketDeposit(
        operationID: "blocker-02:market:deposit",
        depositID: depositProposal.depositID,
        opportunityID: marketOpportunity.opportunityID, marketID: marketID,
        sellerID: b02Counterparty, assetID: settled.assetID,
        material: marketOpportunity.offered.material,
        sourceObservation: marketSource, marketObservation: marketObservation,
        physicalReceiptID: marketObservation.physicalReceiptID,
        completedAtTick: settled.session.tick
    )
    _ = try! recorder.apply(
        .recordVerifiedMarketDeposit(deposit), to: &settled.session
    )
    let depositCheckpoint = try! settled.session.makeCheckpoint()
    var depositRestored = try! AgentSimulationSession.restoring(
        depositCheckpoint
    )
    let restoredDepositRecord = depositRestored.materialRightsSnapshot().records
        .first { $0.asset.assetID == settled.assetID }!
    check("CIV-37 deposits the exact evolved produced asset in market custody",
          depositRestored.marketSnapshot().totalDepositCount == 1
            && restoredDepositRecord.lastVerifiedHolder.holder
                == .container("3,64,0")
            && restoredDepositRecord.lastVerifiedHolder.materialIdentity.damage == 2
            && restoredDepositRecord.productionProvenance?.operationIDs
                == [settled.production.operationID])
    let listingProposal = depositRestored.nextAutonomousMarketListingProposal()!
    try! depositRestored.createMarketListing(
        operationID: "blocker-02:market:list:restored",
        proposal: listingProposal
    )
    check("fresh restore continues normal market action with evolved asset",
          depositRestored.marketSnapshot().listings.first?.status == .open
            && depositRestored.marketSnapshot().listings.first?.depositID
                == depositProposal.depositID)
    let originalListingProposal = settled.session
        .nextAutonomousMarketListingProposal()!
    _ = try! recorder.apply(
        .createMarketListing(
            operationID: "blocker-02:market:list:restored",
            proposal: originalListingProposal
        ), to: &settled.session
    )
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "blocker-02-continuation")!
    )
    let replayed = try! AgentSessionReplayer.replay(
        checkpoint: replayBase, journal: journal
    )
    let replayedRecord = replayed.session.materialRightsSnapshot().records.first {
        $0.asset.assetID == settled.assetID
    }!
    check("schema-34 replay preserves historical origin and current damage without duplication",
          replayBase.schemaVersion == 34
            && depositCheckpoint.schemaVersion == 34
            && journal.manifest.schemaVersion == 34
            && replayed.report.verified
            && replayedRecord.productionProvenance?.origins.first?
                .outputProduced.identity.damage == 0
            && replayedRecord.lastVerifiedHolder.materialIdentity.damage == 2
            && replayed.session.productionSnapshot().totalProductionCount == 1
            && replayed.session.barterSnapshot().totalCompletedCount == 1
            && replayed.session.marketSnapshot().totalDepositCount == 1)
    let preDepositPair = AgentBarterPhysicalPairObservation(
        candidateID: "blocker-02:barter:market-stale",
        actorAID: b02Holder, actorBID: b02Counterparty,
        actorAGood: b02Leg(
            assetID: settled.session.materialRightsSnapshot().records.first {
                $0.asset.assetID == settled.breadAssetID
            }!.asset.assetID,
            holder: b02Holder, session: settled.session
        ), actorBGood: AgentBarterLeg(
            assetID: settled.assetID, holderID: b02Counterparty,
            material: AgentMaterialStackSnapshot(
                identity: marketSource.materialIdentity,
                count: marketSource.quantity
            ), holderObservation: marketSource,
            productionOperationIDs: [settled.production.operationID]
        ), distance: 2, lineOfSight: true, chunksReady: true,
        observedAtTick: settled.session.tick,
        expiresAtTick: settled.session.tick
            + settled.session.barterSnapshot().configuration!.offerLifetimeTicks
    )
    check("historical production provenance cannot spend market-held matter",
          b02DiscoveryFailsClosed(
              pair: preDepositPair, session: settled.session
          ))
    let staleMarketDecision = settled.session.evaluateMaterialUse(
        AgentMaterialUseRequest(
            requestID: "blocker-02:market-held-stale-use",
            assetID: settled.assetID, actorID: b02Counterparty,
            use: .transferCustody, verifiedHolder: marketSource
        )
    )
    check("market-held current authority defeats the historical agent observation",
          staleMarketDecision.verdict == .denied
            && staleMarketDecision.reason == .stalePhysicalObservation)

    let observerWorld = try! AgentObserverWorldBinding(
        worldID: "world-gate-e-blocker-02",
        storageIdentity: "sqlite-world:gate-e-blocker-02",
        seed: 402, dimension: 0, observedWorldTick: 402
    )
    let observerBefore = try! depositRestored.durableStateDigest()
    let observerTick = depositRestored.tick
    let observerSequence = depositRestored.causalLedgerSnapshot().summary
        .latestSequence
    let observerA = depositRestored.observerSnapshot(worldBinding: observerWorld)
    let observerB = depositRestored.observerSnapshot(worldBinding: observerWorld)
    let observedAsset = observerA.individual(b02Counterparty)?.materialAssets
        .first { $0.assetID == settled.assetID }
    check("Observer 11 exposes the evolved asset and current holder read-only",
          observerA.header.schemaVersion == 11
            && observedAsset?.itemKey == "stone_pickaxe"
            && observedAsset?.physicalHolder == "container:3,64,0"
            && observerA == observerB
            && (try! depositRestored.durableStateDigest()) == observerBefore
            && depositRestored.tick == observerTick
            && depositRestored.causalLedgerSnapshot().summary.latestSequence
                == observerSequence)

    var compacted = b02Fixture(
        "gate-e-blocker-02-compaction", maximumProductionRecords: 1
    )
    _ = try! b02ProduceCompactionRecord(
        ordinal: 1, session: &compacted.session
    )
    check("bounded production compaction evicts the source production record",
          compacted.session.productionSnapshot().records.count == 1
            && !compacted.session.productionSnapshot().records.contains {
                $0.operationID == compacted.production.operationID
            })
    let compactedCheckpoint = try! compacted.session.makeCheckpoint()
    let compactedRestored = try! AgentSimulationSession.restoring(
        compactedCheckpoint
    )
    let compactedRecord = compactedRestored.materialRightsSnapshot().records
        .first { $0.asset.assetID == compacted.assetID }!
    let compactedDiscovery = try! compactedRestored
        .discoverBarterOpportunities(from: [b02PhysicalPair(
            compacted, session: compactedRestored,
            suffix: "compacted-restored"
        )])
    check("immutable origin proof survives compaction, evolution, and restart",
          compactedRecord.productionProvenance?.operationIDs
            == [compacted.production.operationID]
            && compactedRecord.productionProvenance?.origins.first?
                .outputProduced.identity.damage == 0
            && compactedRecord.lastVerifiedHolder.materialIdentity.damage == 1
            && compactedDiscovery.count == 1)
    check("corrupt retained origin after compaction still fails closed",
          b02ForgedOriginIdentityFailsClosed(compactedCheckpoint))

    check("focused correction conserves bounded product receipts and authorities",
          fixture.session.productionSnapshot().totalProductionCount == 1
            && fixture.session.barterSnapshot().totalCompletedCount == 0
            && settled.session.productionSnapshot().totalProductionCount == 1
            && settled.session.barterSnapshot().totalCompletedCount == 1
            && settled.session.marketSnapshot().totalDepositCount == 1
            && settled.session.materialRightsSnapshot().records.filter {
                $0.asset.assetID == settled.assetID
            }.count == 1)
}
