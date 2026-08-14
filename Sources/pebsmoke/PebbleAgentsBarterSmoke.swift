import PebbleAgents

private func barterAgent(_ id: String, x: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id, state: "idle", position: position,
        needs: AgentNeeds(hunger: id == "agent_a" ? 0.9 : 0.2,
                          fatigue: 0, curiosity: 0.2, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "local material need", startedAtTick: 0,
            urgency: 80
        ),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func barterIdentity(
    _ item: String, damage: Int = 0
) -> AgentMaterialIdentitySnapshot {
    AgentMaterialIdentitySnapshot(
        itemKey: item, damage: damage, enchantments: [], label: nil,
        canonicalDataJSON: "{}"
    )
}

private func barterStack(
    _ item: String, _ count: Int, damage: Int = 0
) -> AgentMaterialStackSnapshot {
    AgentMaterialStackSnapshot(
        identity: barterIdentity(item, damage: damage), count: count
    )
}

private struct BarterSmokeFixture {
    var session: AgentSimulationSession
    let opportunity: AgentBarterOpportunityObservation
    let pickaxeProductionID: String
}

private func appendProduction(
    needID: AgentProductionNeedID,
    actorID: AgentID,
    reason: AgentProductionNeedReason,
    item: String,
    sourceBefore: String,
    sourceAfter: String,
    operationID: String,
    session: inout AgentSimulationSession
) throws {
    try session.raiseProductionNeed(
        needID: needID, actorID: actorID, reason: reason,
        desiredOutputItemKey: item, priority: 90
    )
    let inputs = item == "stone_pickaxe"
        ? [barterStack("cobblestone", 3), barterStack("stick", 2)]
        : [barterStack("wheat", 3)]
    let observation = AgentProductionOpportunityObservation(
        opportunityID: AgentProductionOpportunityID(
            rawValue: "production:\(needID.rawValue):plan"
        )!, needID: needID, actorID: actorID,
        recipeID: "craft:\(item)",
        workshopPosition: AgentPosition(x: 1, y: 64, z: 0),
        workshopBlockKey: "crafting_table",
        sourceLocationID: "agent:probe-\(actorID.rawValue)",
        sourceCustodyFingerprint: sourceBefore,
        planFingerprint: "plan:\(operationID)", inputs: inputs,
        output: barterStack(item, 1), observedAtTick: session.tick,
        expiresAtTick: session.tick + 2
    )
    try session.recordProductionOpportunity(observation)
    try session.recordVerifiedProduction(AgentVerifiedProductionOutcome(
        operationID: operationID,
        opportunityID: observation.opportunityID, actorID: actorID,
        recipeID: observation.recipeID,
        workshopPosition: observation.workshopPosition,
        workshopBlockKey: observation.workshopBlockKey,
        sourceLocationID: observation.sourceLocationID,
        sourceCustodyFingerprintBefore: sourceBefore,
        sourceCustodyFingerprintAfter: sourceAfter,
        planFingerprint: observation.planFingerprint,
        inputsConsumed: inputs, outputProduced: barterStack(item, 1),
        physicalReceiptID: operationID, completedAtTick: session.tick
    ))
}

private func fulfillExistingBarterNeed(
    needID: AgentProductionNeedID,
    actorID: AgentID,
    item: String,
    operationID: String,
    session: inout AgentSimulationSession
) throws {
    let inputs = item == "stone_pickaxe"
        ? [barterStack("cobblestone", 3), barterStack("stick", 2)]
        : [barterStack("wheat", 3)]
    let observation = AgentProductionOpportunityObservation(
        opportunityID: AgentProductionOpportunityID(
            rawValue: "production:\(needID.rawValue):fulfilled"
        )!, needID: needID, actorID: actorID,
        recipeID: "craft:\(item)",
        workshopPosition: AgentPosition(x: 1, y: 64, z: 0),
        workshopBlockKey: "crafting_table",
        sourceLocationID: "agent:probe-\(actorID.rawValue)",
        sourceCustodyFingerprint: "need-before:\(operationID)",
        planFingerprint: "plan:\(operationID)", inputs: inputs,
        output: barterStack(item, 1), observedAtTick: session.tick,
        expiresAtTick: session.tick + 2
    )
    try session.recordProductionOpportunity(observation)
    try session.recordVerifiedProduction(AgentVerifiedProductionOutcome(
        operationID: operationID,
        opportunityID: observation.opportunityID, actorID: actorID,
        recipeID: observation.recipeID,
        workshopPosition: observation.workshopPosition,
        workshopBlockKey: observation.workshopBlockKey,
        sourceLocationID: observation.sourceLocationID,
        sourceCustodyFingerprintBefore: observation.sourceCustodyFingerprint,
        sourceCustodyFingerprintAfter: "need-after:\(operationID)",
        planFingerprint: observation.planFingerprint,
        inputsConsumed: inputs, outputProduced: barterStack(item, 1),
        physicalReceiptID: operationID, completedAtTick: session.tick
    ))
}

private func registerBarterAsset(
    id: AgentMaterialAssetID,
    stack: AgentMaterialStackSnapshot,
    observation: AgentMaterialHolderObservation,
    owner: AgentID,
    witnesses: [AgentID],
    session: inout AgentSimulationSession
) throws {
    let claimID = AgentMaterialClaimID(rawValue: "claim:\(id.rawValue):produced")!
    _ = try session.applyMaterialRightsOperation(.register(
        operationID: "rights:\(id.rawValue):register",
        asset: AgentMaterialAssetReference(
            assetID: id, materialIdentity: stack.identity,
            quantity: stack.count
        ), observation: observation
    ))
    _ = try session.applyMaterialRightsOperation(.assertClaim(
        operationID: "rights:\(id.rawValue):claim", assetID: id,
        claimID: claimID, claimantID: owner, basis: .produced
    ))
    _ = try session.applyMaterialRightsOperation(.recognizeOwnership(
        operationID: "rights:\(id.rawValue):recognize", assetID: id,
        claimID: claimID, recognizingAgentIDs: witnesses
    ))
}

private func barterFixture(
    _ id: String = "civ35-barter",
    configuration: AgentBarterConfiguration = .live
) -> BarterSmokeFixture {
    let a = AgentID(rawValue: "agent_a")!
    let b = AgentID(rawValue: "agent_b")!
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 135, memoryPolicy: .bounded(maxEntries: 64)
        ), agents: [barterAgent("agent_a", x: 0), barterAgent("agent_b", x: 2)],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
    try! session.setProductionEnabled(true)
    let pickaxeProductionID = "produce:agent_a:stone_pickaxe"
    try! appendProduction(
        needID: AgentProductionNeedID(rawValue: "need:a:produce-pickaxe")!,
        actorID: a, reason: .missingUsefulTool, item: "stone_pickaxe",
        sourceBefore: "a-inputs", sourceAfter: "a-pickaxe",
        operationID: pickaxeProductionID, session: &session
    )
    try! appendProduction(
        needID: AgentProductionNeedID(rawValue: "need:b:produce-bread-1")!,
        actorID: b, reason: .physicalFoodNeed, item: "bread",
        sourceBefore: "b-wheat-6", sourceAfter: "b-wheat-3-bread-1",
        operationID: "produce:agent_b:bread:1", session: &session
    )
    try! appendProduction(
        needID: AgentProductionNeedID(rawValue: "need:b:produce-bread-2")!,
        actorID: b, reason: .physicalFoodNeed, item: "bread",
        sourceBefore: "b-wheat-3-bread-1", sourceAfter: "b-bread-2",
        operationID: "produce:agent_b:bread:2", session: &session
    )
    let needA = AgentProductionNeedID(rawValue: "need:a:value-bread")!
    let needB = AgentProductionNeedID(rawValue: "need:b:value-pickaxe")!
    try! session.raiseProductionNeed(
        needID: needA, actorID: a, reason: .physicalFoodNeed,
        desiredOutputItemKey: "bread", quantity: 2, priority: 95
    )
    try! session.raiseProductionNeed(
        needID: needB, actorID: b, reason: .missingUsefulTool,
        desiredOutputItemKey: "stone_pickaxe", quantity: 1, priority: 92
    )
    try! session.setMaterialRightsEnabled(true)
    let pickaxeAsset = AgentMaterialAssetID(rawValue: "asset:a:pickaxe")!
    let breadAsset = AgentMaterialAssetID(rawValue: "asset:b:bread-2")!
    let pickaxeObservation = AgentMaterialHolderObservation(
        holder: .agent(a), materialIdentity: barterIdentity("stone_pickaxe"),
        quantity: 1, custodyFingerprint: "a-pickaxe",
        physicalReceiptID: "observe:a-pickaxe", observedAtTick: 0
    )
    let breadObservation = AgentMaterialHolderObservation(
        holder: .agent(b), materialIdentity: barterIdentity("bread"),
        quantity: 2, custodyFingerprint: "b-bread-2",
        physicalReceiptID: "observe:b-bread-2", observedAtTick: 0
    )
    try! registerBarterAsset(
        id: pickaxeAsset, stack: barterStack("stone_pickaxe", 1),
        observation: pickaxeObservation, owner: a, witnesses: [a, b],
        session: &session
    )
    try! registerBarterAsset(
        id: breadAsset, stack: barterStack("bread", 2),
        observation: breadObservation, owner: b, witnesses: [a, b],
        session: &session
    )
    try! session.setBarterEnabled(true, configuration: configuration)
    let needs = session.productionSnapshot().needs
    let opportunity = AgentBarterOpportunityObservation(
        opportunityID: "local:a:b:primary", offerorID: a, counterpartyID: b,
        offered: AgentBarterLeg(
            assetID: pickaxeAsset, holderID: a,
            material: barterStack("stone_pickaxe", 1),
            holderObservation: pickaxeObservation,
            productionOperationIDs: [pickaxeProductionID]
        ), requested: AgentBarterLeg(
            assetID: breadAsset, holderID: b,
            material: barterStack("bread", 2),
            holderObservation: breadObservation,
            productionOperationIDs: ["produce:agent_b:bread:1", "produce:agent_b:bread:2"]
        ),
        offerorReason: AgentBarterValueReason(
            need: needs.first { $0.needID == needA }!
        ), counterpartyReason: AgentBarterValueReason(
            need: needs.first { $0.needID == needB }!
        ), distance: 2, lineOfSight: true, chunksReady: true,
        observedAtTick: 0, expiresAtTick: 4
    )
    return BarterSmokeFixture(
        session: session, opportunity: opportunity,
        pickaxeProductionID: pickaxeProductionID
    )
}

private func barterPhysicalPair(
    _ opportunity: AgentBarterOpportunityObservation,
    tick: Int,
    lifetime: Int,
    suffix: String
) -> AgentBarterPhysicalPairObservation {
    AgentBarterPhysicalPairObservation(
        candidateID: "physical:\(suffix):t\(tick)",
        actorAID: opportunity.offerorID,
        actorBID: opportunity.counterpartyID,
        actorAGood: opportunity.offered,
        actorBGood: opportunity.requested,
        distance: opportunity.distance,
        lineOfSight: opportunity.lineOfSight,
        chunksReady: opportunity.chunksReady,
        observedAtTick: tick,
        expiresAtTick: tick + lifetime
    )
}

private func discoverCurrentBarterOpportunity(
    from template: AgentBarterOpportunityObservation,
    suffix: String,
    session: inout AgentSimulationSession
) -> AgentBarterOpportunityObservation {
    let lifetime = session.barterSnapshot().configuration!.offerLifetimeTicks
    let physical = barterPhysicalPair(
        template, tick: session.tick, lifetime: lifetime, suffix: suffix
    )
    let discovered = try! session.discoverBarterOpportunities(from: [physical])
    precondition(discovered.count == 1)
    try! session.recordBarterOpportunity(discovered[0])
    return discovered[0]
}

private func addNonProducedBarterPair(
    session: inout AgentSimulationSession
) -> AgentBarterPhysicalPairObservation {
    let a = AgentID(rawValue: "agent_a")!
    let b = AgentID(rawValue: "agent_b")!
    let logAsset = AgentMaterialAssetID(rawValue: "asset:a:oak-log")!
    let cobbleAsset = AgentMaterialAssetID(rawValue: "asset:b:cobble-3")!
    let logObservation = AgentMaterialHolderObservation(
        holder: .agent(a), materialIdentity: barterIdentity("oak_log"),
        quantity: 1, custodyFingerprint: "a-pickaxe",
        physicalReceiptID: "observe:a-log", observedAtTick: session.tick
    )
    let cobbleObservation = AgentMaterialHolderObservation(
        holder: .agent(b), materialIdentity: barterIdentity("cobblestone"),
        quantity: 3, custodyFingerprint: "b-bread-2",
        physicalReceiptID: "observe:b-cobble", observedAtTick: session.tick
    )
    try! registerBarterAsset(
        id: logAsset, stack: barterStack("oak_log", 1),
        observation: logObservation, owner: a, witnesses: [a, b],
        session: &session
    )
    try! registerBarterAsset(
        id: cobbleAsset, stack: barterStack("cobblestone", 3),
        observation: cobbleObservation, owner: b, witnesses: [a, b],
        session: &session
    )
    try! session.raiseProductionNeed(
        needID: AgentProductionNeedID(rawValue: "need:a:value-cobble")!,
        actorID: a, reason: .materialWork,
        desiredOutputItemKey: "cobblestone", quantity: 3, priority: 88
    )
    try! session.raiseProductionNeed(
        needID: AgentProductionNeedID(rawValue: "need:b:value-log")!,
        actorID: b, reason: .materialWork,
        desiredOutputItemKey: "oak_log", quantity: 1, priority: 87
    )
    let lifetime = session.barterSnapshot().configuration!.offerLifetimeTicks
    return AgentBarterPhysicalPairObservation(
        candidateID: "physical:non-produced:t\(session.tick)",
        actorAID: a, actorBID: b,
        actorAGood: AgentBarterLeg(
            assetID: logAsset, holderID: a,
            material: barterStack("oak_log", 1),
            holderObservation: logObservation,
            productionOperationIDs: []
        ),
        actorBGood: AgentBarterLeg(
            assetID: cobbleAsset, holderID: b,
            material: barterStack("cobblestone", 3),
            holderObservation: cobbleObservation,
            productionOperationIDs: []
        ),
        distance: 2, lineOfSight: true, chunksReady: true,
        observedAtTick: session.tick,
        expiresAtTick: session.tick + lifetime
    )
}

private func successfulBarterOutcome(
    offerID: AgentBarterOfferID,
    opportunity: AgentBarterOpportunityObservation,
    tick: Int
) -> AgentVerifiedBarterOutcome {
    AgentVerifiedBarterOutcome(
        operationID: "barter:\(offerID.rawValue):completed",
        offerID: offerID,
        offeredLeg: AgentVerifiedBarterLeg(
            assetID: opportunity.offered.assetID,
            sourceObservation: opportunity.offered.holderObservation,
            destinationObservation: AgentMaterialHolderObservation(
                holder: .agent(opportunity.counterpartyID),
                materialIdentity: opportunity.offered.material.identity,
                quantity: opportunity.offered.material.count,
                custodyFingerprint: "b-final-pickaxe",
                physicalReceiptID: "physical:offered", observedAtTick: tick
            ), physicalReceiptID: "physical:offered"
        ),
        requestedLeg: AgentVerifiedBarterLeg(
            assetID: opportunity.requested.assetID,
            sourceObservation: opportunity.requested.holderObservation,
            destinationObservation: AgentMaterialHolderObservation(
                holder: .agent(opportunity.offerorID),
                materialIdentity: opportunity.requested.material.identity,
                quantity: opportunity.requested.material.count,
                custodyFingerprint: "a-final-bread",
                physicalReceiptID: "physical:requested", observedAtTick: tick
            ), physicalReceiptID: "physical:requested"
        ), completedAtTick: tick
    )
}

func runPebbleAgentsBarterSmoke() {
    section("CIV-35 spot barter, exact authority, persistence and replay")

    var normalFixture = barterFixture("civ35-normal-runtime")
    let normalPhysical = barterPhysicalPair(
        normalFixture.opportunity,
        tick: normalFixture.session.tick,
        lifetime: normalFixture.session.barterSnapshot().configuration!
            .offerLifetimeTicks,
        suffix: "normal-runtime"
    )
    let normalBefore = try! normalFixture.session.durableStateBytes()
    let normalDiscoveries = try! normalFixture.session
        .discoverBarterOpportunities(from: [normalPhysical])
    check("normal runtime discovers barter from bounded physical input without proof fixture",
          normalDiscoveries.count == 1
            && normalDiscoveries[0].offered.productionOperationIDs
                == [normalFixture.pickaxeProductionID]
            && (try! normalFixture.session.durableStateBytes()) == normalBefore)
    try! normalFixture.session.recordBarterOpportunity(normalDiscoveries[0])
    let normalProposal = normalFixture.session.nextAutonomousBarterOfferProposal()
    check("normal runtime cognition creates stable offer without proof fixture",
          normalProposal?.actorID == normalFixture.opportunity.offerorID
            && normalProposal?.offerID.rawValue.hasPrefix("barter-") == true)
    try! normalFixture.session.createBarterOffer(
        offerID: normalProposal!.offerID,
        opportunityID: normalProposal!.opportunityID,
        actorID: normalProposal!.actorID
    )
    _ = try! normalFixture.session.advanceTick()
    let localRefusal = normalFixture.session
        .evaluateAutonomousBarterCounterpartyDecision(
            AgentBarterCounterpartyDecisionObservation(
                offerID: normalProposal!.offerID,
                counterpartyID: normalFixture.opportunity.counterpartyID,
                distance: 2, lineOfSight: false, chunksReady: true,
                observedAtTick: normalFixture.session.tick
            )
        )
    check("normal counterparty can refuse when current local evidence changes",
          localRefusal?.accept == false)
    let normalDecision = normalFixture.session
        .evaluateAutonomousBarterCounterpartyDecision(
            AgentBarterCounterpartyDecisionObservation(
                offerID: normalProposal!.offerID,
                counterpartyID: normalFixture.opportunity.counterpartyID,
                distance: 2, lineOfSight: true, chunksReady: true,
                observedAtTick: normalFixture.session.tick
            )
        )
    check("normal counterparty independently accepts from current need and locality",
          normalDecision?.accept == true
            && normalDecision?.counterpartyID
                == normalFixture.opportunity.counterpartyID)
    try! normalFixture.session.decideBarterOffer(
        offerID: normalDecision!.offerID,
        counterpartyID: normalDecision!.counterpartyID,
        accept: normalDecision!.accept,
        reason: normalDecision!.reason
    )

    var changedNeedFixture = barterFixture("civ35-changed-need")
    let changedOpportunity = discoverCurrentBarterOpportunity(
        from: changedNeedFixture.opportunity,
        suffix: "changed-need",
        session: &changedNeedFixture.session
    )
    let changedProposal = changedNeedFixture.session
        .nextAutonomousBarterOfferProposal()!
    try! changedNeedFixture.session.createBarterOffer(
        offerID: changedProposal.offerID,
        opportunityID: changedProposal.opportunityID,
        actorID: changedProposal.actorID
    )
    _ = try! changedNeedFixture.session.advanceTick()
    try! fulfillExistingBarterNeed(
        needID: changedOpportunity.counterpartyReason.needID,
        actorID: changedOpportunity.counterpartyID,
        item: changedOpportunity.offered.material.identity.itemKey,
        operationID: "produce:changed-counterparty-need",
        session: &changedNeedFixture.session
    )
    let changedNeedDecision = changedNeedFixture.session
        .evaluateAutonomousBarterCounterpartyDecision(
            AgentBarterCounterpartyDecisionObservation(
                offerID: changedProposal.offerID,
                counterpartyID: changedOpportunity.counterpartyID,
                distance: 2, lineOfSight: true, chunksReady: true,
                observedAtTick: changedNeedFixture.session.tick
            )
        )
    check("fulfilled counterparty need changes normal decision to refusal",
          changedNeedDecision?.accept == false
            && changedNeedDecision?.reason.contains("no longer values") == true)

    var fixture = barterFixture()
    var session = fixture.session
    let beforeOpportunity = try! session.durableStateBytes()
    try! session.recordBarterOpportunity(fixture.opportunity)
    check("local opportunity records no exchange or custody mutation",
          session.barterSnapshot().records.isEmpty
            && session.materialRightsSnapshot().records.map(\.lastVerifiedHolder)
                == fixture.session.materialRightsSnapshot().records.map(\.lastVerifiedHolder)
            && beforeOpportunity != (try! session.durableStateBytes()))

    let rejectedID = AgentBarterOfferID(rawValue: "rejected-first")!
    try! session.createBarterOffer(
        offerID: rejectedID, opportunityID: fixture.opportunity.opportunityID,
        actorID: fixture.opportunity.offerorID
    )
    let beforeReject = session.materialRightsSnapshot()
    try! session.decideBarterOffer(
        offerID: rejectedID,
        counterpartyID: fixture.opportunity.counterpartyID,
        accept: false, reason: "current local need is not urgent enough"
    )
    check("counterparty independently rejects without physical publication",
          session.barterSnapshot().offers.first {
              $0.offerID == rejectedID
          }?.status == .rejected
            && session.barterSnapshot().records.isEmpty
            && session.materialRightsSnapshot() == beforeReject)

    let offerID = AgentBarterOfferID(rawValue: "primary")!
    try! session.createBarterOffer(
        offerID: offerID, opportunityID: fixture.opportunity.opportunityID,
        actorID: fixture.opportunity.offerorID
    )
    check("explicit offer reserves both exact assets but moves no matter",
          session.barterSnapshot().offers.first {
              $0.offerID == offerID
          }?.status == .open
            && session.materialRightsSnapshot() == beforeReject)
    let competingID = AgentBarterOfferID(rawValue: "competing")!
    check("concurrent offer cannot reserve either exact side twice",
          (try? session.createBarterOffer(
              offerID: competingID,
              opportunityID: fixture.opportunity.opportunityID,
              actorID: fixture.opportunity.offerorID
          )) == nil)
    check("pending offer checkpoint fails closed",
          !session.checkpointReadiness().ready
            && (try? session.makeCheckpoint()) == nil)
    try! session.decideBarterOffer(
        offerID: offerID,
        counterpartyID: fixture.opportunity.counterpartyID,
        accept: true, reason: "exact produced tool satisfies current local need"
    )
    check("acceptance is explicit counterparty authority and still moves no matter",
          session.barterSnapshot().offers.first {
              $0.offerID == offerID
          }?.status == .accepted
            && session.materialRightsSnapshot() == beforeReject)

    let outcome = successfulBarterOutcome(
        offerID: offerID, opportunity: fixture.opportunity, tick: session.tick
    )
    var stale = outcome
    let staleOutcome = AgentVerifiedBarterOutcome(
        operationID: "barter:stale:completed", offerID: offerID,
        offeredLeg: AgentVerifiedBarterLeg(
            assetID: outcome.offeredLeg.assetID,
            sourceObservation: AgentMaterialHolderObservation(
                holder: .agent(fixture.opportunity.offerorID),
                materialIdentity: fixture.opportunity.offered.material.identity,
                quantity: 1, custodyFingerprint: "external-change",
                physicalReceiptID: "external", observedAtTick: session.tick
            ), destinationObservation: outcome.offeredLeg.destinationObservation,
            physicalReceiptID: outcome.offeredLeg.physicalReceiptID
        ), requestedLeg: outcome.requestedLeg, completedAtTick: session.tick
    )
    stale = staleOutcome
    let beforeStale = try! session.durableStateBytes()
    check("stale source fingerprint refuses historical accepted authority",
          (try? session.recordVerifiedBarter(stale)) == nil
            && (try! session.durableStateBytes()) == beforeStale)
    try! session.recordVerifiedBarter(outcome)
    let rights = session.materialRightsSnapshot().records
    check("completed barter publishes both exact physical receipts once",
          session.barterSnapshot().records.count == 1
            && session.barterSnapshot().totalCompletedCount == 1
            && session.barterSnapshot().records[0].outcome.offeredLeg
                .physicalReceiptID == "physical:offered"
            && session.barterSnapshot().records[0].outcome.requestedLeg
                .physicalReceiptID == "physical:requested")
    check("voluntary exchange reconciles holder owner custodian and received claim",
          rights.first { $0.asset.assetID == fixture.opportunity.offered.assetID }
            .map {
                $0.lastVerifiedHolder.holder == .agent(fixture.opportunity.counterpartyID)
                    && $0.recognizedOwnership?.ownerID
                        == fixture.opportunity.counterpartyID
                    && $0.custodianID == fixture.opportunity.counterpartyID
                    && $0.claims.contains {
                        $0.claimantID == fixture.opportunity.counterpartyID
                            && $0.basis == .received
                    }
            } == true
            && rights.first {
                $0.asset.assetID == fixture.opportunity.requested.assetID
            }?.recognizedOwnership?.ownerID == fixture.opportunity.offerorID)
    let afterCompleted = try! session.durableStateBytes()
    check("duplicate exchange operation cannot publish or move again",
          (try? session.recordVerifiedBarter(outcome)) == nil
            && (try! session.durableStateBytes()) == afterCompleted)

    let use = AgentProducedGoodUseOutcome(
        operationID: "use:bartered-pickaxe",
        productionOperationID: fixture.pickaxeProductionID,
        actorID: fixture.opportunity.counterpartyID,
        physicalReceiptID: "physical:bartered-pickaxe-use",
        identityBefore: barterStack("stone_pickaxe", 1),
        identityAfter: barterStack("stone_pickaxe", 1, damage: 1),
        physicalEffect: "receiver broke real stone with exact exchanged tool",
        completedAtTick: session.tick
    )
    try! session.recordProducedGoodUse(use)
    check("receiver can use exact CIV-34 produced tool after barter",
          session.productionSnapshot().useRecords.last?.outcome.actorID
            == fixture.opportunity.counterpartyID
            && session.productionSnapshot().useRecords.last?.outcome
                .productionOperationID == fixture.pickaxeProductionID)

    let checkpoint = try! session.makeCheckpoint()
    check("completed barter checkpoint advances exact schema 32",
          checkpoint.schemaVersion == AgentCheckpointSchema.barterVersion
            && AgentCheckpointSchema.barterVersion == 32)
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    check("fresh restart preserves exchanged rights and one history record",
          (try! restored.durableStateBytes()) == (try! session.durableStateBytes())
            && restored.barterSnapshot().records.count == 1
            && restored.barterSnapshot().pendingOfferCount == 0)
    check("fresh restart cannot repeat completed exchange",
          (try? restored.prevalidateVerifiedBarter(outcome)) == nil
            && restored.barterSnapshot().totalCompletedCount == 1)

    let world = try! AgentObserverWorldBinding(
        worldID: "civ35-world", storageIdentity: "memory:civ35",
        seed: 135, dimension: 0, observedWorldTick: 0
    )
    let beforeObserver = try! session.durableStateBytes()
    let observer = session.observerSnapshot(worldBinding: world)
    check("Observer schema 9 exposes bounded offer reasons and physical receipts",
          observer.header.schemaVersion == 9
            && observer.barter?.records.first?.offer.opportunity.offerorReason.reason
                == .physicalFoodNeed
            && observer.barter?.records.first?.outcome.requestedLeg.physicalReceiptID
                == "physical:requested")
    check("Observer barter projection is read-only",
          (try! session.durableStateBytes()) == beforeObserver)

    var withdrawnFixture = barterFixture("civ35-withdrawn")
    try! withdrawnFixture.session.recordBarterOpportunity(
        withdrawnFixture.opportunity
    )
    let withdrawnID = AgentBarterOfferID(rawValue: "withdrawn")!
    try! withdrawnFixture.session.createBarterOffer(
        offerID: withdrawnID,
        opportunityID: withdrawnFixture.opportunity.opportunityID,
        actorID: withdrawnFixture.opportunity.offerorID
    )
    try! withdrawnFixture.session.withdrawBarterOffer(
        offerID: withdrawnID,
        actorID: withdrawnFixture.opportunity.offerorID
    )
    check("withdrawn bounded offer cannot later authorize acceptance",
          (try? withdrawnFixture.session.decideBarterOffer(
              offerID: withdrawnID,
              counterpartyID: withdrawnFixture.opportunity.counterpartyID,
              accept: true, reason: "too late"
          )) == nil
            && withdrawnFixture.session.barterSnapshot().records.isEmpty)

    var malformedFixture = barterFixture("civ35-malformed")
    let selfOpportunity = AgentBarterOpportunityObservation(
        opportunityID: "invalid-self", offerorID: fixture.opportunity.offerorID,
        counterpartyID: fixture.opportunity.offerorID,
        offered: fixture.opportunity.offered,
        requested: fixture.opportunity.requested,
        offerorReason: fixture.opportunity.offerorReason,
        counterpartyReason: fixture.opportunity.counterpartyReason,
        distance: 0, lineOfSight: true, chunksReady: true,
        observedAtTick: 0, expiresAtTick: 4
    )
    check("self trade and duplicate participant are rejected",
          (try? malformedFixture.session.recordBarterOpportunity(selfOpportunity)) == nil)

    var unauthorizedFixture = barterFixture("civ35-unauthorized")
    let heldAsset = unauthorizedFixture.opportunity.offered.assetID
    let foreignClaim = AgentMaterialClaimID(rawValue: "claim:foreign-owner")!
    _ = try! unauthorizedFixture.session.applyMaterialRightsOperation(.assertClaim(
        operationID: "rights:foreign-owner:claim", assetID: heldAsset,
        claimID: foreignClaim,
        claimantID: unauthorizedFixture.opportunity.counterpartyID,
        basis: .contested
    ))
    _ = try! unauthorizedFixture.session.applyMaterialRightsOperation(
        .recognizeOwnership(
            operationID: "rights:foreign-owner:recognize", assetID: heldAsset,
            claimID: foreignClaim,
            recognizingAgentIDs: [
                unauthorizedFixture.opportunity.offerorID,
                unauthorizedFixture.opportunity.counterpartyID,
            ]
        )
    )
    try! unauthorizedFixture.session.recordBarterOpportunity(
        unauthorizedFixture.opportunity
    )
    let unauthorizedID = AgentBarterOfferID(rawValue: "unauthorized")!
    try! unauthorizedFixture.session.createBarterOffer(
        offerID: unauthorizedID,
        opportunityID: unauthorizedFixture.opportunity.opportunityID,
        actorID: unauthorizedFixture.opportunity.offerorID
    )
    try! unauthorizedFixture.session.decideBarterOffer(
        offerID: unauthorizedID,
        counterpartyID: unauthorizedFixture.opportunity.counterpartyID,
        accept: true, reason: "accept subject to rights"
    )
    var unauthorizedRights = unauthorizedFixture.session.materialRightsSnapshot()
    let decision = unauthorizedFixture.session.evaluateMaterialUse(
        AgentMaterialUseRequest(
            requestID: "unauthorized-disposition",
            assetID: unauthorizedFixture.opportunity.offered.assetID,
            actorID: unauthorizedFixture.opportunity.offerorID,
            use: .transferCustody,
            verifiedHolder: unauthorizedFixture.opportunity.offered.holderObservation
        )
    )
    unauthorizedRights = unauthorizedFixture.session.materialRightsSnapshot()
    check("physical holder without ownership or permission cannot dispose",
          decision.verdict == .denied
            && decision.reason == .noUseRight
            && (try? unauthorizedFixture.session.prevalidateVerifiedBarter(
                successfulBarterOutcome(
                    offerID: unauthorizedID,
                    opportunity: unauthorizedFixture.opportunity,
                    tick: unauthorizedFixture.session.tick
                )
            )) == nil
            && unauthorizedRights.records.count == 2)

    var replayFixture = barterFixture("civ35-replay")
    let base = try! replayFixture.session.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(
        checkpoint: base, session: replayFixture.session
    )
    _ = try! recorder.apply(
        .recordBarterOpportunity(replayFixture.opportunity),
        to: &replayFixture.session
    )
    let replayOfferID = AgentBarterOfferID(rawValue: "replay-primary")!
    _ = try! recorder.apply(.createBarterOffer(
        offerID: replayOfferID,
        opportunityID: replayFixture.opportunity.opportunityID,
        actorID: replayFixture.opportunity.offerorID
    ), to: &replayFixture.session)
    _ = try! recorder.apply(.decideBarterOffer(
        offerID: replayOfferID,
        counterpartyID: replayFixture.opportunity.counterpartyID,
        accept: true, reason: "local replay decision"
    ), to: &replayFixture.session)
    _ = try! recorder.apply(.recordVerifiedBarter(successfulBarterOutcome(
        offerID: replayOfferID,
        opportunity: replayFixture.opportunity,
        tick: replayFixture.session.tick
    )), to: &replayFixture.session)
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "barter-replay")!
    )
    let replayed = try! AgentSessionReplayer.replay(
        checkpoint: base, journal: journal
    )
    check("barter replay schema 32 reproduces social history only",
          journal.manifest.schemaVersion == AgentReplaySchema.barterVersion
            && AgentReplaySchema.barterVersion == 32
            && replayed.report.verified
            && replayed.session.barterSnapshot().records.count == 1)
    check("replay operations retain offer decision before verified publication",
          journal.records.map(\.operationKind) == [
              .barterOpportunity, .barterOffer, .barterDecision, .barterOutcome,
          ])

    let churnConfiguration = try! AgentBarterConfiguration(
        maximumOpportunities: 8,
        maximumOffers: 8,
        maximumRecords: 32,
        maximumProcessedOperations: 128,
        offerLifetimeTicks: 2,
        maximumLocalDistance: 8
    )
    var churn = barterFixture(
        "civ35-offer-churn", configuration: churnConfiguration
    )
    let terminalCycle: [AgentBarterOfferStatus] = [
        .rejected, .withdrawn, .stale, .failed, .expired,
    ]
    var terminalStatusesObserved: Set<String> = []
    var maximumRetainedOffers = 0
    var lifetimeOfferAttempts = 0
    for attempt in 0..<21 {
        _ = discoverCurrentBarterOpportunity(
            from: churn.opportunity,
            suffix: "churn-\(attempt)",
            session: &churn.session
        )
        let proposal = churn.session.nextAutonomousBarterOfferProposal()!
        try! churn.session.createBarterOffer(
            offerID: proposal.offerID,
            opportunityID: proposal.opportunityID,
            actorID: proposal.actorID
        )
        lifetimeOfferAttempts += 1
        maximumRetainedOffers = max(
            maximumRetainedOffers,
            churn.session.barterSnapshot().offers.count
        )
        let terminal = terminalCycle[attempt % terminalCycle.count]
        switch terminal {
        case .rejected:
            try! churn.session.decideBarterOffer(
                offerID: proposal.offerID,
                counterpartyID: churn.opportunity.counterpartyID,
                accept: false, reason: "bounded churn rejection"
            )
        case .withdrawn:
            try! churn.session.withdrawBarterOffer(
                offerID: proposal.offerID,
                actorID: churn.opportunity.offerorID,
                reason: "bounded churn withdrawal"
            )
        case .stale, .failed:
            try! churn.session.markBarterOfferFailed(
                offerID: proposal.offerID,
                status: terminal,
                reason: "bounded churn \(terminal.rawValue)"
            )
        case .expired:
            for _ in 0...churnConfiguration.offerLifetimeTicks {
                _ = try! churn.session.advanceTick()
            }
            try! churn.session.markBarterOfferFailed(
                offerID: proposal.offerID,
                status: .expired,
                reason: "bounded churn expiration"
            )
        case .open, .accepted, .completed:
            preconditionFailure("terminal churn configured with pending status")
        }
        terminalStatusesObserved.insert(terminal.rawValue)
        check("terminal churn attempt \(attempt + 1) releases reservation",
              churn.session.barterSnapshot().offers.first {
                  $0.offerID == proposal.offerID
              }?.status == terminal
                && churn.session.barterSnapshot().pendingOfferCount == 0)
        if terminal != .expired { _ = try! churn.session.advanceTick() }
    }
    check("all rejected expired withdrawn stale and failed states participate in churn",
          terminalStatusesObserved == Set(terminalCycle.map(\.rawValue)))
    check("terminal offer churn beyond twice the configured cap remains bounded",
          lifetimeOfferAttempts == 21
            && maximumRetainedOffers == churnConfiguration.maximumOffers
            && churn.session.barterSnapshot().offers.count
                == churnConfiguration.maximumOffers
            && churn.session.barterSnapshot().evictionCount > 0)

    _ = discoverCurrentBarterOpportunity(
        from: churn.opportunity,
        suffix: "pending-original",
        session: &churn.session
    )
    let retainedPending = churn.session.nextAutonomousBarterOfferProposal()!
    try! churn.session.createBarterOffer(
        offerID: retainedPending.offerID,
        opportunityID: retainedPending.opportunityID,
        actorID: retainedPending.actorID
    )
    lifetimeOfferAttempts += 1
    maximumRetainedOffers = max(
        maximumRetainedOffers, churn.session.barterSnapshot().offers.count
    )
    let nonProducedPhysical = addNonProducedBarterPair(session: &churn.session)
    let nonProducedDiscoveries = try! churn.session.discoverBarterOpportunities(
        from: [nonProducedPhysical]
    )
    check("ordinary rights-tracked goods do not require CIV-34 provenance",
          nonProducedDiscoveries.count == 1
            && nonProducedDiscoveries[0].offered.productionOperationIDs.isEmpty
            && nonProducedDiscoveries[0].requested.productionOperationIDs.isEmpty)
    try! churn.session.recordBarterOpportunity(nonProducedDiscoveries[0])
    let secondPending = churn.session.nextAutonomousBarterOfferProposal()!
    try! churn.session.createBarterOffer(
        offerID: secondPending.offerID,
        opportunityID: secondPending.opportunityID,
        actorID: secondPending.actorID
    )
    lifetimeOfferAttempts += 1
    maximumRetainedOffers = max(
        maximumRetainedOffers, churn.session.barterSnapshot().offers.count
    )
    let pendingAfterCapacityReclaim = churn.session.barterSnapshot().offers
        .filter { $0.status.isPending }.map(\.offerID)
    check("capacity reclamation never evicts pending reservation authority",
          pendingAfterCapacityReclaim.sorted()
            == [retainedPending.offerID, secondPending.offerID].sorted()
            && churn.session.barterSnapshot().offers.count
                == churnConfiguration.maximumOffers)
    try! churn.session.withdrawBarterOffer(
        offerID: retainedPending.offerID,
        actorID: churn.opportunity.offerorID,
        reason: "prepare compacted restart"
    )
    try! churn.session.withdrawBarterOffer(
        offerID: secondPending.offerID,
        actorID: nonProducedDiscoveries[0].offerorID,
        reason: "prepare compacted restart"
    )
    let compactedCheckpoint = try! churn.session.makeCheckpoint()
    var compactedRestart = try! AgentSimulationSession.restoring(
        compactedCheckpoint
    )
    let restoredCompactedBytes = try! compactedRestart.durableStateBytes()
    check("terminal compaction checkpoint restores the same bounded semantics",
          restoredCompactedBytes == (try! churn.session.durableStateBytes())
            && compactedRestart.barterSnapshot().pendingOfferCount == 0
            && compactedRestart.barterSnapshot().offers.count
                == churnConfiguration.maximumOffers)
    _ = try! compactedRestart.advanceTick()
    _ = discoverCurrentBarterOpportunity(
        from: churn.opportunity,
        suffix: "after-compaction-restart",
        session: &compactedRestart
    )
    let postRestartProposal = compactedRestart
        .nextAutonomousBarterOfferProposal()!
    try! compactedRestart.createBarterOffer(
        offerID: postRestartProposal.offerID,
        opportunityID: postRestartProposal.opportunityID,
        actorID: postRestartProposal.actorID
    )
    lifetimeOfferAttempts += 1
    maximumRetainedOffers = max(
        maximumRetainedOffers,
        compactedRestart.barterSnapshot().offers.count
    )
    check("new offer succeeds after more than maximumOffers terminal churn and restart",
          lifetimeOfferAttempts == 24
            && maximumRetainedOffers == churnConfiguration.maximumOffers
            && compactedRestart.barterSnapshot().pendingOfferCount == 1
            && compactedRestart.barterSnapshot().offers.contains {
                $0.offerID == postRestartProposal.offerID && $0.status == .open
            }
            && compactedRestart.barterSnapshot().offers.allSatisfy {
                $0.offerID == postRestartProposal.offerID || !$0.status.isPending
            })

    fixture.session = session
    check("campaign accounting remains exact with no synthetic economic state",
          fixture.session.barterSnapshot().totalCompletedCount == 1
            && fixture.session.barterSnapshot().records.count == 1
            && fixture.session.materialRightsSnapshot().records.count == 2)
}
