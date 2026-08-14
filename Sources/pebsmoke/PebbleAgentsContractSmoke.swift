import Foundation
import PebbleAgents

private func contractAgent(_ id: String, x: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id, state: "idle", position: position,
        needs: AgentNeeds(
            hunger: id == "creditor" ? 0.9 : 0.2,
            fatigue: 0, curiosity: 0.2, safety: 1
        ), health: 100, fear: 0, homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "contract test", startedAtTick: 0,
            urgency: 80
        ), lastAction: nil, lastActionEffect: nil, memory: [],
        tickCreated: 0, ticksAlive: 0, observationCount: 0,
        nearbyObservationCount: 0, goalSelectionCount: 0,
        goalChangeCount: 0, actionCount: 0, actionEffectCount: 0,
        movementCount: 0, totalManhattanDistanceMoved: 0,
        returnHomeMoveCount: 0, totalDistanceReducedTowardHome: 0
    )
}

private func contractIdentity(_ item: String) -> AgentMaterialIdentitySnapshot {
    AgentMaterialIdentitySnapshot(
        itemKey: item, damage: 0, enchantments: [], label: nil,
        canonicalDataJSON: "{}"
    )
}

private func contractStack(
    _ item: String, _ count: Int
) -> AgentMaterialStackSnapshot {
    AgentMaterialStackSnapshot(identity: contractIdentity(item), count: count)
}

private func contractRegisterAsset(
    id: AgentMaterialAssetID,
    stack: AgentMaterialStackSnapshot,
    holder: AgentID,
    fingerprint: String,
    receipt: String,
    session: inout AgentSimulationSession
) throws -> AgentMaterialHolderObservation {
    let observation = AgentMaterialHolderObservation(
        holder: .agent(holder), materialIdentity: stack.identity,
        quantity: stack.count, custodyFingerprint: fingerprint,
        physicalReceiptID: receipt, observedAtTick: session.tick
    )
    let claim = AgentMaterialClaimID(
        rawValue: "contract-claim-"
            + AgentAutonomousActivityDigest.make(id.rawValue)
    )!
    _ = try session.applyMaterialRightsOperation(.register(
        operationID: "contract-rights:\(id.rawValue):register",
        asset: AgentMaterialAssetReference(
            assetID: id, materialIdentity: stack.identity,
            quantity: stack.count
        ), observation: observation
    ))
    _ = try session.applyMaterialRightsOperation(.assertClaim(
        operationID: "contract-rights:\(id.rawValue):claim",
        assetID: id, claimID: claim, claimantID: holder,
        basis: .produced
    ))
    _ = try session.applyMaterialRightsOperation(.recognizeOwnership(
        operationID: "contract-rights:\(id.rawValue):recognize",
        assetID: id, claimID: claim,
        recognizingAgentIDs: [
            AgentID(rawValue: "creditor")!, AgentID(rawValue: "debtor")!,
        ]
    ))
    return observation
}

private struct ContractSmokeFixture {
    var session: AgentSimulationSession
    let opportunity: AgentContractOpportunityObservation
    let considerationAssetID: AgentMaterialAssetID
}

private func contractFixture(
    _ simulationID: String = "civ36-contract",
    configuration: AgentContractConfiguration = .live
) -> ContractSmokeFixture {
    let creditor = AgentID(rawValue: "creditor")!
    let debtor = AgentID(rawValue: "debtor")!
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 136, memoryPolicy: .bounded(maxEntries: 64)
        ), agents: [
            contractAgent("creditor", x: 0),
            contractAgent("debtor", x: 2),
        ], simulationID: try! AgentSimulationID(validating: simulationID),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
    try! session.setProductionEnabled(true)
    let debtorNeed = AgentProductionNeedID(
        rawValue: "contract:debtor:needs-pickaxe"
    )!
    let creditorNeed = AgentProductionNeedID(
        rawValue: "contract:creditor:needs-bread"
    )!
    try! session.raiseProductionNeed(
        needID: debtorNeed, actorID: debtor,
        reason: .missingUsefulTool,
        desiredOutputItemKey: "stone_pickaxe", quantity: 1,
        priority: 96
    )
    try! session.raiseProductionNeed(
        needID: creditorNeed, actorID: creditor,
        reason: .physicalFoodNeed,
        desiredOutputItemKey: "bread", quantity: 1,
        priority: 95
    )
    try! session.setMaterialRightsEnabled(true)
    let assetID = AgentMaterialAssetID(
        rawValue: "contract-asset-creditor-pickaxe"
    )!
    let observation = try! contractRegisterAsset(
        id: assetID, stack: contractStack("stone_pickaxe", 1),
        holder: creditor, fingerprint: "creditor-pickaxe",
        receipt: "physical-creditor-pickaxe", session: &session
    )
    try! session.setContractsEnabled(true, configuration: configuration)
    let needs = session.productionSnapshot().needs
    return ContractSmokeFixture(
        session: session,
        opportunity: AgentContractOpportunityObservation(
            opportunityID: "contract-opportunity-primary",
            promisorID: debtor, promiseeID: creditor,
            consideration: AgentBarterLeg(
                assetID: assetID, holderID: creditor,
                material: contractStack("stone_pickaxe", 1),
                holderObservation: observation,
                productionOperationIDs: []
            ),
            promisorReason: AgentBarterValueReason(
                need: needs.first { $0.needID == debtorNeed }!
            ),
            promiseeReason: AgentBarterValueReason(
                need: needs.first { $0.needID == creditorNeed }!
            ),
            promisedPerformance: AgentContractPerformanceTerms(
                material: contractStack("bread", 1)
            ), distance: 2, lineOfSight: true, chunksReady: true,
            observedAtTick: 0,
            expiresAtTick: configuration.proposalLifetimeTicks
        ), considerationAssetID: assetID
    )
}

private func formContract(
    fixture: ContractSmokeFixture,
    proposalText: String,
    session: inout AgentSimulationSession
) throws -> AgentDurableContractObligation {
    try session.recordContractOpportunity(fixture.opportunity)
    let proposalID = AgentPromiseProposalID(rawValue: proposalText)!
    try session.createPromiseProposal(
        proposalID: proposalID,
        opportunityID: fixture.opportunity.opportunityID,
        promisorID: fixture.opportunity.promisorID
    )
    _ = try session.advanceTick()
    try session.decidePromiseProposal(
        proposalID: proposalID,
        promiseeID: fixture.opportunity.promiseeID,
        accept: true,
        reason: "creditor distinctly accepts exact bread terms"
    )
    return session.contractSnapshot().obligations.first {
        $0.proposalID == proposalID
    }!
}

private func contractConsideration(
    obligation: AgentDurableContractObligation,
    fixture: ContractSmokeFixture,
    suffix: String,
    session: inout AgentSimulationSession
) throws -> AgentVerifiedContractConsiderationOutcome {
    let outcome = AgentVerifiedContractConsiderationOutcome(
        operationID: "contract-consideration-\(suffix)",
        obligationID: obligation.obligationID,
        transfer: AgentVerifiedContractTransfer(
            assetID: fixture.considerationAssetID,
            sourceObservation: fixture.opportunity.consideration
                .holderObservation,
            destinationObservation: AgentMaterialHolderObservation(
                holder: .agent(obligation.promisorID),
                materialIdentity: fixture.opportunity.consideration
                    .material.identity,
                quantity: fixture.opportunity.consideration.material.count,
                custodyFingerprint: "debtor-after-consideration-\(suffix)",
                physicalReceiptID: "contract-consideration-\(suffix)",
                observedAtTick: session.tick
            ), physicalReceiptID: "contract-consideration-\(suffix)",
            productionOperationIDs: []
        ), completedAtTick: session.tick
    )
    try session.recordVerifiedContractConsideration(outcome)
    return outcome
}

private func produceContractPerformance(
    obligation: AgentDurableContractObligation,
    suffix: String,
    session: inout AgentSimulationSession
) throws -> (AgentMaterialAssetID, AgentVerifiedProductionOutcome) {
    let needID = AgentProductionNeedID(
        rawValue: "contract:\(obligation.obligationID.rawValue):perform"
    )!
    let need = session.productionSnapshot().needs.first {
        $0.needID == needID && $0.status == .active
    }!
    let opportunity = AgentProductionOpportunityObservation(
        opportunityID: AgentProductionOpportunityID(
            rawValue: "contract-production-\(suffix)"
        )!, needID: need.needID, actorID: need.actorID,
        recipeID: "craft:bread",
        workshopPosition: AgentPosition(x: 1, y: 64, z: 0),
        workshopBlockKey: "crafting_table",
        sourceLocationID: "agent:debtor",
        sourceCustodyFingerprint: "debtor-wheat-\(suffix)",
        planFingerprint: "contract-plan-\(suffix)",
        inputs: [contractStack("wheat", 3)],
        output: obligation.promisedPerformance.material,
        observedAtTick: session.tick, expiresAtTick: session.tick + 2
    )
    try session.recordProductionOpportunity(opportunity)
    let production = AgentVerifiedProductionOutcome(
        operationID: "contract-production-\(suffix)",
        opportunityID: opportunity.opportunityID,
        actorID: obligation.promisorID, recipeID: opportunity.recipeID,
        workshopPosition: opportunity.workshopPosition,
        workshopBlockKey: opportunity.workshopBlockKey,
        sourceLocationID: opportunity.sourceLocationID,
        sourceCustodyFingerprintBefore: opportunity.sourceCustodyFingerprint,
        sourceCustodyFingerprintAfter: "debtor-bread-\(suffix)",
        planFingerprint: opportunity.planFingerprint,
        inputsConsumed: opportunity.inputs,
        outputProduced: obligation.promisedPerformance.material,
        physicalReceiptID: "contract-production-\(suffix)",
        completedAtTick: session.tick
    )
    try session.recordVerifiedProduction(production)
    let assetID = AgentMaterialAssetID(
        rawValue: "contract-performance-\(suffix)"
    )!
    _ = try contractRegisterAsset(
        id: assetID, stack: obligation.promisedPerformance.material,
        holder: obligation.promisorID,
        fingerprint: production.sourceCustodyFingerprintAfter,
        receipt: production.physicalReceiptID, session: &session
    )
    return (assetID, production)
}

private func fulfillContract(
    obligation: AgentDurableContractObligation,
    assetID: AgentMaterialAssetID,
    production: AgentVerifiedProductionOutcome,
    suffix: String,
    session: inout AgentSimulationSession
) throws -> AgentVerifiedContractFulfillmentOutcome {
    let source = session.materialRightsSnapshot().records.first {
        $0.asset.assetID == assetID
    }!.lastVerifiedHolder
    let receipt = "contract-fulfillment-\(suffix)"
    let outcome = AgentVerifiedContractFulfillmentOutcome(
        operationID: receipt, obligationID: obligation.obligationID,
        transfer: AgentVerifiedContractTransfer(
            assetID: assetID, sourceObservation: source,
            destinationObservation: AgentMaterialHolderObservation(
                holder: .agent(obligation.promiseeID),
                materialIdentity: obligation.promisedPerformance.material.identity,
                quantity: obligation.promisedPerformance.material.count,
                custodyFingerprint: "creditor-bread-\(suffix)",
                physicalReceiptID: receipt, observedAtTick: session.tick
            ), physicalReceiptID: receipt,
            productionOperationIDs: [production.operationID]
        ), completedAtTick: session.tick
    )
    try session.recordVerifiedContractFulfillment(outcome)
    return outcome
}

func runPebbleAgentsContractSmoke() {
    section("CIV-36 debt, promises and durable contracts")

    var rejected = contractFixture("civ36-rejected")
    let rejectedRights = rejected.session.materialRightsSnapshot()
    try! rejected.session.recordContractOpportunity(rejected.opportunity)
    let rejectedID = AgentPromiseProposalID(rawValue: "promise-rejected")!
    try! rejected.session.createPromiseProposal(
        proposalID: rejectedID,
        opportunityID: rejected.opportunity.opportunityID,
        promisorID: rejected.opportunity.promisorID
    )
    check("promise proposal creates no matter, custody, debt, or obligation",
          rejected.session.materialRightsSnapshot() == rejectedRights
            && rejected.session.contractSnapshot().obligations.isEmpty)
    try! rejected.session.decidePromiseProposal(
        proposalID: rejectedID,
        promiseeID: rejected.opportunity.promiseeID,
        accept: false, reason: "creditor refuses the proposed due terms"
    )
    check("rejected promise creates no contract obligation or debt",
          rejected.session.contractSnapshot().obligations.isEmpty
            && rejected.session.contractSnapshot().proposals.first?.status
                == .rejected)

    var withdrawn = contractFixture("civ36-withdrawn")
    try! withdrawn.session.recordContractOpportunity(withdrawn.opportunity)
    let withdrawnID = AgentPromiseProposalID(rawValue: "promise-withdrawn")!
    try! withdrawn.session.createPromiseProposal(
        proposalID: withdrawnID,
        opportunityID: withdrawn.opportunity.opportunityID,
        promisorID: withdrawn.opportunity.promisorID
    )
    try! withdrawn.session.withdrawPromiseProposal(
        proposalID: withdrawnID,
        promisorID: withdrawn.opportunity.promisorID
    )
    check("pre-acceptance withdrawal is terminal and cannot be accepted",
          (try? withdrawn.session.decidePromiseProposal(
              proposalID: withdrawnID,
              promiseeID: withdrawn.opportunity.promiseeID,
              accept: true, reason: "too late"
          )) == nil
            && withdrawn.session.contractSnapshot().obligations.isEmpty)

    let dedupFixture = contractFixture("civ36-reverse-dedup")
    var dedupSession = dedupFixture.session
    _ = try! formContract(
        fixture: dedupFixture, proposalText: "promise-dedup",
        session: &dedupSession
    )
    let reverseAssetID = AgentMaterialAssetID(
        rawValue: "contract-asset-debtor-bread"
    )!
    let reverseHolder = try! contractRegisterAsset(
        id: reverseAssetID, stack: contractStack("bread", 1),
        holder: dedupFixture.opportunity.promisorID,
        fingerprint: "debtor-produced-bread",
        receipt: "physical-debtor-produced-bread", session: &dedupSession
    )
    let reverseOpportunity = AgentContractOpportunityObservation(
        opportunityID: "contract-opportunity-reverse-duplicate",
        promisorID: dedupFixture.opportunity.promiseeID,
        promiseeID: dedupFixture.opportunity.promisorID,
        consideration: AgentBarterLeg(
            assetID: reverseAssetID,
            holderID: dedupFixture.opportunity.promisorID,
            material: contractStack("bread", 1),
            holderObservation: reverseHolder,
            productionOperationIDs: []
        ),
        promisorReason: dedupFixture.opportunity.promiseeReason,
        promiseeReason: dedupFixture.opportunity.promisorReason,
        promisedPerformance: AgentContractPerformanceTerms(
            material: contractStack("stone_pickaxe", 1)
        ), distance: 2, lineOfSight: true, chunksReady: true,
        observedAtTick: dedupSession.tick,
        expiresAtTick: dedupSession.tick
            + dedupSession.contractSnapshot().configuration!
                .proposalLifetimeTicks
    )
    check("negotiated reason pair cannot regenerate as reverse promise",
          (try! dedupSession.discoverContractOpportunities(
              from: [reverseOpportunity]
          )).isEmpty
            && (try? dedupSession.recordContractOpportunity(
                reverseOpportunity
            )) == nil)

    let fixture = contractFixture()
    var session = fixture.session
    let rightsBeforeContract = session.materialRightsSnapshot()
    let obligation = try! formContract(
        fixture: fixture, proposalText: "promise-primary", session: &session
    )
    check("distinct promisee acceptance creates durable obligation, not debt yet",
          obligation.promisorID != obligation.promiseeID
            && obligation.status == .awaitingConsideration
            && session.contractSnapshot().outstandingDebtCount == 0
            && session.materialRightsSnapshot() == rightsBeforeContract)
    check("accepted terms preserve exact future identity quantity and due tick",
          obligation.promisedPerformance.material == contractStack("bread", 1)
            && obligation.promisedPerformance.fullPerformanceRequired
            && obligation.dueTick > obligation.acceptedAtTick)
    check("accepted obligation blocks unilateral post-acceptance withdrawal",
          (try? session.withdrawPromiseProposal(
              proposalID: obligation.proposalID,
              promisorID: obligation.promisorID
          )) == nil)
    let consideration = try! contractConsideration(
        obligation: obligation, fixture: fixture,
        suffix: "primary", session: &session
    )
    check("real current consideration opens debt and transfers exact rights",
          session.contractSnapshot().obligations.first?.status == .outstanding
            && session.contractSnapshot().outstandingDebtCount == 1
            && session.materialRightsSnapshot().records.first {
                $0.asset.assetID == fixture.considerationAssetID
            }?.recognizedOwnership?.ownerID == obligation.promisorID
            && consideration.transfer.physicalReceiptID
                == "contract-consideration-primary")
    check("consideration causally raises debtor production need without materializing output",
          session.productionSnapshot().needs.contains {
              $0.needID.rawValue
                == "contract:\(obligation.obligationID.rawValue):perform"
                && $0.actorID == obligation.promisorID
                && $0.status == .active
          }
            && !session.materialRightsSnapshot().records.contains {
                $0.asset.materialIdentity == contractIdentity("bread")
                    && $0.lastVerifiedHolder.holder == .agent(obligation.promisorID)
            })
    check("open debt is checkpoint-ready because no physical mutation is in flight",
          session.checkpointReadiness().ready)
    let openCheckpoint = try! session.makeCheckpoint()
    var restoredOpen = try! AgentSimulationSession.restoring(openCheckpoint)
    check("open debt survives fresh schema-33 restart byte exactly",
          openCheckpoint.schemaVersion == AgentCheckpointSchema.contractVersion
            && AgentCheckpointSchema.contractVersion == 33
            && restoredOpen.contractSnapshot().obligations.first?.status
                == .outstanding
            && (try! restoredOpen.durableStateBytes())
                == (try! session.durableStateBytes()))

    let fakeFulfillment = AgentVerifiedContractFulfillmentOutcome(
        operationID: "contract-fulfillment-missing",
        obligationID: obligation.obligationID,
        transfer: AgentVerifiedContractTransfer(
            assetID: AgentMaterialAssetID(rawValue: "missing-bread")!,
            sourceObservation: AgentMaterialHolderObservation(
                holder: .agent(obligation.promisorID),
                materialIdentity: contractIdentity("bread"), quantity: 1,
                custodyFingerprint: "missing", physicalReceiptID: "missing",
                observedAtTick: restoredOpen.tick
            ), destinationObservation: AgentMaterialHolderObservation(
                holder: .agent(obligation.promiseeID),
                materialIdentity: contractIdentity("bread"), quantity: 1,
                custodyFingerprint: "missing-destination",
                physicalReceiptID: "contract-fulfillment-missing",
                observedAtTick: restoredOpen.tick
            ), physicalReceiptID: "contract-fulfillment-missing"
        ), completedAtTick: restoredOpen.tick
    )
    let beforeMissing = try! restoredOpen.durableStateBytes()
    check("missing physical good cannot fulfill debt",
          (try? restoredOpen.recordVerifiedContractFulfillment(
              fakeFulfillment
          )) == nil
            && (try! restoredOpen.durableStateBytes()) == beforeMissing)

    let produced = try! produceContractPerformance(
        obligation: obligation, suffix: "primary", session: &restoredOpen
    )
    check("normal production record obtains exact promised good later",
          produced.1.actorID == obligation.promisorID
            && produced.1.outputProduced == obligation.promisedPerformance.material
            && restoredOpen.productionSnapshot().records.contains {
                $0.operationID == produced.1.operationID
            })
    var failedCandidate = restoredOpen
    _ = try! fulfillContract(
        obligation: obligation, assetID: produced.0,
        production: produced.1, suffix: "discarded-candidate",
        session: &failedCandidate
    )
    check("discarded post-transfer candidate leaves published debt open for retry",
          restoredOpen.contractSnapshot().obligations.first?.status
                == .outstanding
            && failedCandidate.contractSnapshot().obligations.first?.status
                == .fulfilled)
    let fulfillment = try! fulfillContract(
        obligation: obligation, assetID: produced.0,
        production: produced.1, suffix: "primary", session: &restoredOpen
    )
    check("immediate retry fulfills exact obligation with real receipt once",
          restoredOpen.contractSnapshot().obligations.first?.status == .fulfilled
            && restoredOpen.contractSnapshot().totalFulfilledCount == 1
            && fulfillment.transfer.productionOperationIDs
                == [produced.1.operationID])
    let fulfilledBytes = try! restoredOpen.durableStateBytes()
    check("repeat fulfillment cannot double-spend or publish duplicate receipt",
          (try? restoredOpen.recordVerifiedContractFulfillment(
              fulfillment
          )) == nil
            && (try! restoredOpen.durableStateBytes()) == fulfilledBytes
            && restoredOpen.contractSnapshot().totalFulfilledCount == 1)
    let fulfilledCheckpoint = try! restoredOpen.makeCheckpoint()
    let restoredFulfilled = try! AgentSimulationSession.restoring(
        fulfilledCheckpoint
    )
    check("fulfilled contract survives restart without duplicate execution",
          restoredFulfilled.contractSnapshot().totalFulfilledCount == 1
            && restoredFulfilled.contractSnapshot().obligations.first?.status
                == .fulfilled
            && (try? restoredFulfilled.prevalidateVerifiedContractFulfillment(
                fulfillment
            )) == nil)

    let observerWorld = try! AgentObserverWorldBinding(
        worldID: "civ36-world", storageIdentity: "memory:civ36",
        seed: 136, dimension: 0, observedWorldTick: 0
    )
    let observerBefore = try! restoredOpen.durableStateBytes()
    let observer = restoredOpen.observerSnapshot(worldBinding: observerWorld)
    check("Observer schema 10 distinguishes fulfilled contracts read-only",
          observer.header.schemaVersion == 10
            && observer.contracts?.obligations.first?.status == .fulfilled
            && (try! restoredOpen.durableStateBytes()) == observerBefore)

    let overdueFixture = contractFixture(
        "civ36-overdue",
        configuration: try! AgentContractConfiguration(
            maximumOpportunities: 8, maximumProposals: 8,
            maximumObligations: 8, maximumProcessedOperations: 64,
            proposalLifetimeTicks: 2, performanceDueTicks: 2,
            maximumLocalDistance: 8
        )
    )
    var overdueSession = overdueFixture.session
    let overdueObligation = try! formContract(
        fixture: overdueFixture, proposalText: "promise-overdue",
        session: &overdueSession
    )
    _ = try! contractConsideration(
        obligation: overdueObligation, fixture: overdueFixture,
        suffix: "overdue", session: &overdueSession
    )
    while overdueSession.tick <= overdueObligation.dueTick {
        _ = try! overdueSession.advanceTick()
    }
    try! overdueSession.reviewContractDueBoundaries()
    check("due boundary marks overdue but retains debt without enforcement",
          overdueSession.contractSnapshot().obligations.first?.status == .overdue
            && overdueSession.contractSnapshot().outstandingDebtCount == 1
            && overdueSession.checkpointReadiness().ready)

    var replayFixture = contractFixture("civ36-replay")
    let replayBase = try! replayFixture.session.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(
        checkpoint: replayBase, session: replayFixture.session
    )
    _ = try! recorder.apply(
        .recordContractOpportunity(replayFixture.opportunity),
        to: &replayFixture.session
    )
    let replayProposal = AgentPromiseProposalID(rawValue: "promise-replay")!
    _ = try! recorder.apply(.createPromiseProposal(
        proposalID: replayProposal,
        opportunityID: replayFixture.opportunity.opportunityID,
        promisorID: replayFixture.opportunity.promisorID
    ), to: &replayFixture.session)
    _ = try! recorder.apply(.decidePromiseProposal(
        proposalID: replayProposal,
        promiseeID: replayFixture.opportunity.promiseeID,
        accept: true, reason: "replay acceptance"
    ), to: &replayFixture.session)
    let replayObligation = replayFixture.session.contractSnapshot()
        .obligations.first!
    let replayConsideration = AgentVerifiedContractConsiderationOutcome(
        operationID: "contract-consideration-replay",
        obligationID: replayObligation.obligationID,
        transfer: AgentVerifiedContractTransfer(
            assetID: replayFixture.considerationAssetID,
            sourceObservation: replayFixture.opportunity.consideration
                .holderObservation,
            destinationObservation: AgentMaterialHolderObservation(
                holder: .agent(replayObligation.promisorID),
                materialIdentity: replayFixture.opportunity.consideration
                    .material.identity,
                quantity: 1, custodyFingerprint: "debtor-replay",
                physicalReceiptID: "contract-consideration-replay",
                observedAtTick: replayFixture.session.tick
            ), physicalReceiptID: "contract-consideration-replay"
        ), completedAtTick: replayFixture.session.tick
    )
    _ = try! recorder.apply(
        .recordVerifiedContractConsideration(replayConsideration),
        to: &replayFixture.session
    )
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "contract-replay")!
    )
    let replayed = try! AgentSessionReplayer.replay(
        checkpoint: replayBase, journal: journal
    )
    check("schema-33 replay reproduces accepted open debt without World execution",
          journal.manifest.schemaVersion == AgentReplaySchema.contractVersion
            && AgentReplaySchema.contractVersion == 33
            && replayed.report.verified
            && replayed.session.contractSnapshot().outstandingDebtCount == 1
            && journal.records.map(\.operationKind) == [
                .contractOpportunity, .promiseProposal,
                .promiseDecision, .contractConsideration,
            ])

    let churnConfiguration = try! AgentContractConfiguration(
        maximumOpportunities: 8, maximumProposals: 2,
        maximumObligations: 2, maximumProcessedOperations: 64,
        proposalLifetimeTicks: 2, performanceDueTicks: 8,
        maximumLocalDistance: 8
    )
    var churnFixture = contractFixture(
        "civ36-churn", configuration: churnConfiguration
    )
    var churn = churnFixture.session
    var lifetimeContracts = 0
    for cycle in 0..<5 {
        if cycle > 0 {
            let creditor = AgentID(rawValue: "creditor")!
            let debtor = AgentID(rawValue: "debtor")!
            let asset = AgentMaterialAssetID(
                rawValue: "contract-churn-consideration-\(cycle)"
            )!
            let observation = try! contractRegisterAsset(
                id: asset, stack: contractStack("stone_pickaxe", 1),
                holder: creditor, fingerprint: "creditor-churn-\(cycle)",
                receipt: "creditor-churn-\(cycle)", session: &churn
            )
            let debtorNeed = AgentProductionNeedID(
                rawValue: "contract-churn-debtor-\(cycle)"
            )!
            let creditorNeed = AgentProductionNeedID(
                rawValue: "contract-churn-creditor-\(cycle)"
            )!
            try! churn.raiseProductionNeed(
                needID: debtorNeed, actorID: debtor,
                reason: .missingUsefulTool,
                desiredOutputItemKey: "stone_pickaxe", quantity: 1,
                priority: 90
            )
            try! churn.raiseProductionNeed(
                needID: creditorNeed, actorID: creditor,
                reason: .physicalFoodNeed,
                desiredOutputItemKey: "bread", quantity: 1,
                priority: 89
            )
            let needs = churn.productionSnapshot().needs
            churnFixture = ContractSmokeFixture(
                session: churn,
                opportunity: AgentContractOpportunityObservation(
                    opportunityID: "contract-churn-opportunity-\(cycle)",
                    promisorID: debtor, promiseeID: creditor,
                    consideration: AgentBarterLeg(
                        assetID: asset, holderID: creditor,
                        material: contractStack("stone_pickaxe", 1),
                        holderObservation: observation,
                        productionOperationIDs: []
                    ),
                    promisorReason: AgentBarterValueReason(
                        need: needs.first { $0.needID == debtorNeed }!
                    ),
                    promiseeReason: AgentBarterValueReason(
                        need: needs.first { $0.needID == creditorNeed }!
                    ), promisedPerformance: AgentContractPerformanceTerms(
                        material: contractStack("bread", 1)
                    ), distance: 2, lineOfSight: true, chunksReady: true,
                    observedAtTick: churn.tick,
                    expiresAtTick: churn.tick
                        + churnConfiguration.proposalLifetimeTicks
                ), considerationAssetID: asset
            )
        }
        let cycleObligation = try! formContract(
            fixture: churnFixture,
            proposalText: "promise-churn-\(cycle)", session: &churn
        )
        _ = try! contractConsideration(
            obligation: cycleObligation, fixture: churnFixture,
            suffix: "churn-\(cycle)", session: &churn
        )
        let cycleProduction = try! produceContractPerformance(
            obligation: cycleObligation, suffix: "churn-\(cycle)",
            session: &churn
        )
        _ = try! fulfillContract(
            obligation: cycleObligation, assetID: cycleProduction.0,
            production: cycleProduction.1, suffix: "churn-\(cycle)",
            session: &churn
        )
        lifetimeContracts += 1
    }
    check("terminal contract churn beyond twice cap remains sustainable",
          lifetimeContracts == 5
            && churn.contractSnapshot().obligations.count
                == churnConfiguration.maximumObligations
            && churn.contractSnapshot().proposals.count
                == churnConfiguration.maximumProposals
            && churn.contractSnapshot().evictionCount > 0
            && churn.contractSnapshot().totalObligationCount == 5
            && churn.contractSnapshot().totalFulfilledCount == 5)

    let pendingCreditor = AgentID(rawValue: "creditor")!
    let pendingDebtor = AgentID(rawValue: "debtor")!
    let pendingAsset = AgentMaterialAssetID(
        rawValue: "contract-churn-consideration-pending"
    )!
    let pendingObservation = try! contractRegisterAsset(
        id: pendingAsset, stack: contractStack("stone_pickaxe", 1),
        holder: pendingCreditor, fingerprint: "creditor-churn-pending",
        receipt: "creditor-churn-pending", session: &churn
    )
    let pendingDebtorNeed = AgentProductionNeedID(
        rawValue: "contract-churn-debtor-pending"
    )!
    let pendingCreditorNeed = AgentProductionNeedID(
        rawValue: "contract-churn-creditor-pending"
    )!
    try! churn.raiseProductionNeed(
        needID: pendingDebtorNeed, actorID: pendingDebtor,
        reason: .missingUsefulTool,
        desiredOutputItemKey: "stone_pickaxe", quantity: 1, priority: 90
    )
    try! churn.raiseProductionNeed(
        needID: pendingCreditorNeed, actorID: pendingCreditor,
        reason: .physicalFoodNeed,
        desiredOutputItemKey: "bread", quantity: 1, priority: 89
    )
    let pendingNeeds = churn.productionSnapshot().needs
    let pendingFixture = ContractSmokeFixture(
        session: churn,
        opportunity: AgentContractOpportunityObservation(
            opportunityID: "contract-churn-opportunity-pending",
            promisorID: pendingDebtor, promiseeID: pendingCreditor,
            consideration: AgentBarterLeg(
                assetID: pendingAsset, holderID: pendingCreditor,
                material: contractStack("stone_pickaxe", 1),
                holderObservation: pendingObservation,
                productionOperationIDs: []
            ),
            promisorReason: AgentBarterValueReason(
                need: pendingNeeds.first { $0.needID == pendingDebtorNeed }!
            ),
            promiseeReason: AgentBarterValueReason(
                need: pendingNeeds.first { $0.needID == pendingCreditorNeed }!
            ), promisedPerformance: AgentContractPerformanceTerms(
                material: contractStack("bread", 1)
            ), distance: 2, lineOfSight: true, chunksReady: true,
            observedAtTick: churn.tick,
            expiresAtTick: churn.tick
                + churnConfiguration.proposalLifetimeTicks
        ), considerationAssetID: pendingAsset
    )
    let pending = try! formContract(
        fixture: pendingFixture,
        proposalText: "promise-pending-retained", session: &churn
    )
    check("active awaiting-consideration obligation is never evicted",
          churn.contractSnapshot().obligations.contains {
              $0.obligationID == pending.obligationID
                && $0.status == .awaitingConsideration
          }
            && churn.contractSnapshot().obligations.count
                == churnConfiguration.maximumObligations)
    let churnCheckpoint = try! churn.makeCheckpoint()
    let churnRestart = try! AgentSimulationSession.restoring(churnCheckpoint)
    check("bounded active and compacted terminal contract semantics restore",
          churnRestart.contractSnapshot().obligations.contains {
              $0.obligationID == pending.obligationID
                && $0.status == .awaitingConsideration
          }
            && churnRestart.contractSnapshot().totalObligationCount == 6)

    let checkpointData = try! AgentCheckpointCodec.encode(fulfilledCheckpoint)
    var corruptData = checkpointData
    corruptData[corruptData.index(before: corruptData.endIndex)] ^= 0x01
    check("corrupt fulfilled contract checkpoint is refused",
          (try? AgentCheckpointCodec.decode(
              AgentSessionCheckpoint.self, from: corruptData
          )) == nil)
}
