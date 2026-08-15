import Foundation
import PebbleAgents

private let b01Producer = AgentID(rawValue: "producer")!
private let b01Counterparty = AgentID(rawValue: "counterparty")!
private let b01Keeper = AgentID(rawValue: "keeper")!

private func b01Agent(_ id: String, x: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id, state: "idle", position: position,
        needs: AgentNeeds(hunger: 0.5, fatigue: 0, curiosity: 0.2, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "exact production provenance",
            startedAtTick: 0, urgency: 80
        ), lastAction: nil, lastActionEffect: nil, memory: [],
        tickCreated: 0, ticksAlive: 0, observationCount: 0,
        nearbyObservationCount: 0, goalSelectionCount: 0,
        goalChangeCount: 0, actionCount: 0, actionEffectCount: 0,
        movementCount: 0, totalManhattanDistanceMoved: 0,
        returnHomeMoveCount: 0, totalDistanceReducedTowardHome: 0
    )
}

private func b01Identity(_ item: String) -> AgentMaterialIdentitySnapshot {
    AgentMaterialIdentitySnapshot(
        itemKey: item, damage: 0, enchantments: [], label: nil,
        canonicalDataJSON: "{}"
    )
}

private func b01Stack(_ item: String, _ count: Int) -> AgentMaterialStackSnapshot {
    AgentMaterialStackSnapshot(identity: b01Identity(item), count: count)
}

private func b01Session(
    _ id: String,
    maximumProductionRecords: Int = 16
) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 401, memoryPolicy: .bounded(maxEntries: 64)
        ), agents: [
            b01Agent("producer", x: 0),
            b01Agent("counterparty", x: 2),
            b01Agent("keeper", x: 4),
        ], simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
    try! session.setProductionEnabled(
        true,
        configuration: try! AgentProductionConfiguration(
            maximumRecords: maximumProductionRecords
        )
    )
    try! session.setMaterialRightsEnabled(true)
    return session
}

@discardableResult
private func b01Produce(
    ordinal: Int,
    item: String = "bread",
    actorID: AgentID = b01Producer,
    sourceBefore: String,
    sourceAfter: String,
    session: inout AgentSimulationSession
) throws -> AgentVerifiedProductionOutcome {
    let needID = AgentProductionNeedID(
        rawValue: "blocker-01:\(actorID.rawValue):\(item):\(ordinal)"
    )!
    try session.raiseProductionNeed(
        needID: needID, actorID: actorID,
        reason: item == "bread" ? .physicalFoodNeed : .materialWork,
        desiredOutputItemKey: item, quantity: 1, priority: 90
    )
    let input = item == "bread"
        ? b01Stack("wheat", 3) : b01Stack("cobblestone", 1)
    let opportunity = AgentProductionOpportunityObservation(
        opportunityID: AgentProductionOpportunityID(
            rawValue: "blocker-01-opportunity-\(actorID.rawValue)-\(item)-\(ordinal)"
        )!, needID: needID, actorID: actorID,
        recipeID: "craft:\(item)",
        workshopPosition: AgentPosition(x: 1, y: 64, z: 0),
        workshopBlockKey: "crafting_table",
        sourceLocationID: "agent:\(actorID.rawValue)",
        sourceCustodyFingerprint: sourceBefore,
        planFingerprint: "blocker-01-plan-\(actorID.rawValue)-\(item)-\(ordinal)",
        inputs: [input], output: b01Stack(item, 1),
        observedAtTick: session.tick, expiresAtTick: session.tick + 2
    )
    try session.recordProductionOpportunity(opportunity)
    let operationID = "blocker-01-production:\(actorID.rawValue):\(item):p\(ordinal)"
    let outcome = AgentVerifiedProductionOutcome(
        operationID: operationID,
        opportunityID: opportunity.opportunityID,
        actorID: actorID, recipeID: opportunity.recipeID,
        workshopPosition: opportunity.workshopPosition,
        workshopBlockKey: opportunity.workshopBlockKey,
        sourceLocationID: opportunity.sourceLocationID,
        sourceCustodyFingerprintBefore: sourceBefore,
        sourceCustodyFingerprintAfter: sourceAfter,
        planFingerprint: opportunity.planFingerprint,
        inputsConsumed: opportunity.inputs,
        outputProduced: opportunity.output,
        physicalReceiptID: operationID,
        completedAtTick: session.tick
    )
    try session.recordVerifiedProduction(outcome)
    return outcome
}

@discardableResult
private func b01RegisterAsset(
    _ assetID: AgentMaterialAssetID,
    material: AgentMaterialStackSnapshot,
    holder: AgentID,
    fingerprint: String,
    receipt: String,
    productionOperationIDs: [String] = [],
    claimBasis: AgentMaterialClaimBasis = .produced,
    session: inout AgentSimulationSession
) throws -> AgentMaterialHolderObservation {
    let observation = AgentMaterialHolderObservation(
        holder: .agent(holder), materialIdentity: material.identity,
        quantity: material.count, custodyFingerprint: fingerprint,
        physicalReceiptID: receipt, observedAtTick: session.tick
    )
    let prefix = "blocker-01-rights:\(assetID.rawValue)"
    let claimID = AgentMaterialClaimID(rawValue: "\(prefix):claim")!
    _ = try session.applyMaterialRightsOperation(.register(
        operationID: "\(prefix):register",
        asset: AgentMaterialAssetReference(
            assetID: assetID, materialIdentity: material.identity,
            quantity: material.count
        ), observation: observation
    ))
    if !productionOperationIDs.isEmpty {
        _ = try session.applyMaterialRightsOperation(.bindProductionProvenance(
            operationID: "\(prefix):production-provenance",
            assetID: assetID,
            productionOperationIDs: productionOperationIDs.sorted()
        ))
    }
    _ = try session.applyMaterialRightsOperation(.assertClaim(
        operationID: "\(prefix):claim", assetID: assetID,
        claimID: claimID, claimantID: holder, basis: claimBasis
    ))
    _ = try session.applyMaterialRightsOperation(.recognizeOwnership(
        operationID: "\(prefix):recognize", assetID: assetID,
        claimID: claimID,
        recognizingAgentIDs: [b01Producer, b01Counterparty, b01Keeper]
    ))
    return observation
}

@discardableResult
private func b01Transfer(
    assetID: AgentMaterialAssetID,
    actorID: AgentID,
    destinationID: AgentID,
    suffix: String,
    session: inout AgentSimulationSession
) throws -> AgentMaterialHolderObservation {
    let source = session.materialRightsSnapshot().records.first {
        $0.asset.assetID == assetID
    }!.lastVerifiedHolder
    let request = AgentMaterialUseRequest(
        requestID: "blocker-01-transfer-request:\(suffix)",
        assetID: assetID, actorID: actorID, use: .transferCustody,
        verifiedHolder: source
    )
    let decision = session.evaluateMaterialUse(request)
    guard decision.verdict == .allowed else {
        throw AgentMaterialRightsError.unauthorized(decision.reason.rawValue)
    }
    let receipt = "blocker-01-transfer:\(suffix)"
    let destination = AgentMaterialHolderObservation(
        holder: .agent(destinationID),
        materialIdentity: source.materialIdentity,
        quantity: source.quantity,
        custodyFingerprint: "blocker-01-custody:\(suffix)",
        physicalReceiptID: receipt, observedAtTick: session.tick
    )
    _ = try session.applyMaterialRightsOperation(.physicalTransfer(
        AgentMaterialPhysicalTransferOutcome(
            operationID: receipt, decision: decision,
            disposition: .authorized, status: .succeeded,
            destinationObservation: destination,
            physicalReceiptID: receipt
        )
    ))
    return destination
}

private func b01GrantReturnPermission(
    assetID: AgentMaterialAssetID,
    session: inout AgentSimulationSession
) throws {
    _ = try session.applyMaterialRightsOperation(.grantUse(
        operationID: "blocker-01-return-permission:\(assetID.rawValue)",
        assetID: assetID,
        permissionID: AgentMaterialPermissionID(
            rawValue: "blocker-01-return:\(assetID.rawValue)"
        )!, grantorID: b01Producer, userID: b01Keeper,
        allowedUses: [.transferCustody], expiresAtTick: nil
    ))
}

private struct B01ThreeBreadFixture {
    var session: AgentSimulationSession
    let productions: [AgentVerifiedProductionOutcome]
    let assets: [AgentMaterialAssetID]
}

private func b01ThreeBreadFixture(
    _ id: String,
    maximumProductionRecords: Int = 16
) -> B01ThreeBreadFixture {
    var session = b01Session(
        id, maximumProductionRecords: maximumProductionRecords
    )
    var productions: [AgentVerifiedProductionOutcome] = []
    var assets: [AgentMaterialAssetID] = []
    for ordinal in 1...3 {
        let production = try! b01Produce(
            ordinal: ordinal,
            sourceBefore: "blocker-01-p\(ordinal)-before",
            sourceAfter: "blocker-01-p\(ordinal)-after",
            session: &session
        )
        let assetID = AgentMaterialAssetID(
            rawValue: "blocker-01-asset-bread-p\(ordinal)"
        )!
        try! b01RegisterAsset(
            assetID, material: b01Stack("bread", 1), holder: b01Producer,
            fingerprint: production.sourceCustodyFingerprintAfter,
            receipt: production.physicalReceiptID,
            productionOperationIDs: [production.operationID],
            session: &session
        )
        if ordinal < 3 {
            try! b01GrantReturnPermission(assetID: assetID, session: &session)
            try! b01Transfer(
                assetID: assetID, actorID: b01Producer,
                destinationID: b01Keeper, suffix: "park-p\(ordinal)",
                session: &session
            )
        }
        productions.append(production)
        assets.append(assetID)
    }
    return B01ThreeBreadFixture(
        session: session, productions: productions, assets: assets
    )
}

private func b01ValueNeed(
    _ text: String,
    actorID: AgentID,
    item: String,
    session: inout AgentSimulationSession
) throws -> AgentProductionNeedID {
    let id = AgentProductionNeedID(rawValue: text)!
    try session.raiseProductionNeed(
        needID: id, actorID: actorID, reason: .materialWork,
        desiredOutputItemKey: item, quantity: 1, priority: 98
    )
    return id
}

private func b01Leg(
    assetID: AgentMaterialAssetID,
    holderID: AgentID,
    session: AgentSimulationSession
) -> AgentBarterLeg {
    let record = session.materialRightsSnapshot().records.first {
        $0.asset.assetID == assetID
    }!
    return AgentBarterLeg(
        assetID: assetID, holderID: holderID,
        material: AgentMaterialStackSnapshot(
            identity: record.lastVerifiedHolder.materialIdentity,
            count: record.lastVerifiedHolder.quantity
        ), holderObservation: record.lastVerifiedHolder,
        productionOperationIDs:
            record.productionProvenance?.operationIDs ?? []
    )
}

private func b01ResignedProvenanceMutationRefused(
    _ checkpoint: AgentSessionCheckpoint
) -> Bool {
    do {
        var root = try JSONSerialization.jsonObject(
            with: AgentCheckpointCodec.encode(checkpoint)
        ) as! [String: Any]
        var durable = root["durableState"] as! [String: Any]
        var rights = durable["materialRightsState"] as! [String: Any]
        var records = rights["records"] as! [[String: Any]]
        let index = records.firstIndex {
            $0["productionProvenance"] != nil
        }!
        var provenance = records[index]["productionProvenance"]
            as! [String: Any]
        var origins = provenance["origins"] as! [[String: Any]]
        origins[0]["operationID"] = "blocker-01-production:producer:bread:forged"
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

func runPebbleAgentsExactProductionProvenanceSmoke() {
    section("Gate E Blocker 01 exact produced-asset provenance binding")

    let fixture = b01ThreeBreadFixture("gate-e-blocker-01-collision")
    let selected = fixture.session.materialRightsSnapshot().records.first {
        $0.asset.assetID == fixture.assets[2]
    }!
    let matching = fixture.session.productionSnapshot().records.filter {
        $0.actorID == b01Producer && $0.outputProduced == b01Stack("bread", 1)
    }
    check("three same-actor same-output production records remain visible",
          matching.count == 3)
    check("exact promised asset quantity is one",
          selected.asset.quantity == 1)
    check("selected production provenance contains one operation",
          selected.productionProvenance?.operationIDs.count == 1)
    check("selected provenance identifies P3 exactly",
          selected.productionProvenance?.operationIDs
            == [fixture.productions[2].operationID])
    check("selected provenance output sum is exactly one",
          selected.productionProvenance?.representedQuantity == 1)
    check("other matching production operations are not attributed",
          Set(matching.map(\.operationID)).subtracting(
            selected.productionProvenance?.operationIDs ?? []
          ).count == 2)

    var discovery = fixture.session
    let breadNeed = try! b01ValueNeed(
        "blocker-01:counterparty:needs-bread", actorID: b01Counterparty,
        item: "bread", session: &discovery
    )
    let oakNeed = try! b01ValueNeed(
        "blocker-01:producer:needs-oak", actorID: b01Producer,
        item: "oak_log", session: &discovery
    )
    try! discovery.setContractsEnabled(true)
    let needs = discovery.productionSnapshot().needs
    let collisionOpportunity = AgentContractOpportunityObservation(
        opportunityID: "blocker-01-contract-discovery-collision",
        promisorID: b01Counterparty, promiseeID: b01Producer,
        consideration: b01Leg(
            assetID: fixture.assets[2], holderID: b01Producer,
            session: discovery
        ), promisorReason: AgentBarterValueReason(
            need: needs.first { $0.needID == breadNeed }!
        ), promiseeReason: AgentBarterValueReason(
            need: needs.first { $0.needID == oakNeed }!
        ), promisedPerformance: AgentContractPerformanceTerms(
            material: b01Stack("oak_log", 1)
        ), distance: 2, lineOfSight: true, chunksReady: true,
        observedAtTick: discovery.tick,
        expiresAtTick: discovery.tick
            + discovery.contractSnapshot().configuration!.proposalLifetimeTicks
    )
    let collisionDiscoveries = try! discovery.discoverContractOpportunities(
        from: [collisionOpportunity]
    )
    check("normal contract discovery accepts the exact P3 asset",
          collisionDiscoveries.count == 1
            && collisionDiscoveries[0].consideration.productionOperationIDs
                == [fixture.productions[2].operationID])

    let transferred = fixture.session
    let p1Before = transferred.materialRightsSnapshot().records.first {
        $0.asset.assetID == fixture.assets[0]
    }!.productionProvenance
    check("production origin survives a normal custody transfer",
          transferred.materialRightsSnapshot().records.first {
              $0.asset.assetID == fixture.assets[0]
          }?.lastVerifiedHolder.holder == .agent(b01Keeper)
            && transferred.materialRightsSnapshot().records.first {
                $0.asset.assetID == fixture.assets[0]
            }?.productionProvenance == p1Before)

    var negativeBase = b01Session("gate-e-blocker-01-negatives")
    let np1 = try! b01Produce(
        ordinal: 1, sourceBefore: "n1-before", sourceAfter: "n1-after",
        session: &negativeBase
    )
    let np2 = try! b01Produce(
        ordinal: 2, sourceBefore: "n2-before", sourceAfter: "n2-after",
        session: &negativeBase
    )
    let np3 = try! b01Produce(
        ordinal: 3, sourceBefore: "n3-before", sourceAfter: "n3-after",
        session: &negativeBase
    )
    var forged = negativeBase
    let forgedAsset = AgentMaterialAssetID(rawValue: "blocker-01-forged")!
    _ = try! b01RegisterAsset(
        forgedAsset, material: b01Stack("bread", 1), holder: b01Producer,
        fingerprint: np3.sourceCustodyFingerprintAfter,
        receipt: np3.physicalReceiptID, session: &forged
    )
    let forgedBytes = try! forged.durableStateBytes()
    check("forged production operation ID fails closed",
          (try? forged.applyMaterialRightsOperation(.bindProductionProvenance(
              operationID: "blocker-01-bind-forged", assetID: forgedAsset,
              productionOperationIDs: ["blocker-01-production:forged"]
          ))) == nil && (try! forged.durableStateBytes()) == forgedBytes)

    var identityMismatch = negativeBase
    let identityAsset = AgentMaterialAssetID(rawValue: "blocker-01-identity")!
    _ = try! b01RegisterAsset(
        identityAsset, material: b01Stack("wheat", 1), holder: b01Producer,
        fingerprint: np3.sourceCustodyFingerprintAfter,
        receipt: np3.physicalReceiptID, session: &identityMismatch
    )
    check("production output identity mismatch fails closed",
          (try? identityMismatch.applyMaterialRightsOperation(
              .bindProductionProvenance(
                  operationID: "blocker-01-bind-identity",
                  assetID: identityAsset,
                  productionOperationIDs: [np3.operationID]
              )
          )) == nil)

    var quantityMismatch = negativeBase
    let quantityAsset = AgentMaterialAssetID(rawValue: "blocker-01-quantity")!
    _ = try! b01RegisterAsset(
        quantityAsset, material: b01Stack("bread", 2), holder: b01Producer,
        fingerprint: np3.sourceCustodyFingerprintAfter,
        receipt: np3.physicalReceiptID, session: &quantityMismatch
    )
    check("production output quantity mismatch fails closed",
          (try? quantityMismatch.applyMaterialRightsOperation(
              .bindProductionProvenance(
                  operationID: "blocker-01-bind-quantity",
                  assetID: quantityAsset,
                  productionOperationIDs: [np3.operationID]
              )
          )) == nil)

    var ambiguous = negativeBase
    let ambiguousAsset = AgentMaterialAssetID(rawValue: "blocker-01-ambiguous")!
    _ = try! b01RegisterAsset(
        ambiguousAsset, material: b01Stack("bread", 1), holder: b01Producer,
        fingerprint: np3.sourceCustodyFingerprintAfter,
        receipt: np3.physicalReceiptID, session: &ambiguous
    )
    check("ambiguous exact provenance fails closed",
          (try? ambiguous.applyMaterialRightsOperation(
              .bindProductionProvenance(
                  operationID: "blocker-01-bind-ambiguous",
                  assetID: ambiguousAsset,
                  productionOperationIDs: [
                      np1.operationID, np2.operationID, np3.operationID,
                  ].sorted()
              )
          )) == nil)

    var differentActor = negativeBase
    let actorAsset = AgentMaterialAssetID(rawValue: "blocker-01-wrong-actor")!
    _ = try! b01RegisterAsset(
        actorAsset, material: b01Stack("bread", 1), holder: b01Counterparty,
        fingerprint: np3.sourceCustodyFingerprintAfter,
        receipt: np3.physicalReceiptID, session: &differentActor
    )
    check("different actor with the same material cannot claim provenance",
          (try? differentActor.applyMaterialRightsOperation(
              .bindProductionProvenance(
                  operationID: "blocker-01-bind-wrong-actor",
                  assetID: actorAsset,
                  productionOperationIDs: [np3.operationID]
              )
          )) == nil)

    var missingClaim = negativeBase
    let missingAsset = AgentMaterialAssetID(rawValue: "blocker-01-missing-claim")!
    let missingObservation = try! b01RegisterAsset(
        missingAsset, material: b01Stack("bread", 1), holder: b01Producer,
        fingerprint: np3.sourceCustodyFingerprintAfter,
        receipt: np3.physicalReceiptID, session: &missingClaim
    )
    let missingNeedA = try! b01ValueNeed(
        "blocker-01:missing:a", actorID: b01Counterparty,
        item: "bread", session: &missingClaim
    )
    let missingNeedB = try! b01ValueNeed(
        "blocker-01:missing:b", actorID: b01Producer,
        item: "oak_log", session: &missingClaim
    )
    try! missingClaim.setContractsEnabled(true)
    let missingNeeds = missingClaim.productionSnapshot().needs
    let missingProvenanceOpportunity = AgentContractOpportunityObservation(
        opportunityID: "blocker-01-missing-provenance",
        promisorID: b01Counterparty, promiseeID: b01Producer,
        consideration: AgentBarterLeg(
            assetID: missingAsset, holderID: b01Producer,
            material: b01Stack("bread", 1),
            holderObservation: missingObservation,
            productionOperationIDs: [np3.operationID]
        ), promisorReason: AgentBarterValueReason(
            need: missingNeeds.first { $0.needID == missingNeedA }!
        ), promiseeReason: AgentBarterValueReason(
            need: missingNeeds.first { $0.needID == missingNeedB }!
        ), promisedPerformance: AgentContractPerformanceTerms(
            material: b01Stack("oak_log", 1)
        ), distance: 2, lineOfSight: true, chunksReady: true,
        observedAtTick: missingClaim.tick,
        expiresAtTick: missingClaim.tick
            + missingClaim.contractSnapshot().configuration!.proposalLifetimeTicks
    )
    check("missing provenance where provenance is claimed fails closed",
          (try? missingClaim.discoverContractOpportunities(
              from: [missingProvenanceOpportunity]
          )) == nil)

    var crossAsset = negativeBase
    let firstAsset = AgentMaterialAssetID(rawValue: "blocker-01-cross-a")!
    let secondAsset = AgentMaterialAssetID(rawValue: "blocker-01-cross-b")!
    _ = try! b01RegisterAsset(
        firstAsset, material: b01Stack("bread", 1), holder: b01Producer,
        fingerprint: np3.sourceCustodyFingerprintAfter,
        receipt: np3.physicalReceiptID,
        productionOperationIDs: [np3.operationID], session: &crossAsset
    )
    _ = try! b01RegisterAsset(
        secondAsset, material: b01Stack("bread", 1), holder: b01Producer,
        fingerprint: np3.sourceCustodyFingerprintAfter,
        receipt: np3.physicalReceiptID, session: &crossAsset
    )
    check("same production operation cannot cross-attribute another asset",
          (try? crossAsset.applyMaterialRightsOperation(
              .bindProductionProvenance(
                  operationID: "blocker-01-bind-cross-asset",
                  assetID: secondAsset,
                  productionOperationIDs: [np3.operationID]
              )
          )) == nil)

    var fullContract = b01ThreeBreadFixture("gate-e-blocker-01-contract")
    let oakAsset = AgentMaterialAssetID(rawValue: "blocker-01-oak-consideration")!
    let oakObservation = try! b01RegisterAsset(
        oakAsset, material: b01Stack("oak_log", 1),
        holder: b01Counterparty, fingerprint: "counterparty-oak",
        receipt: "counterparty-oak-observed", claimBasis: .found,
        session: &fullContract.session
    )
    let producerOakNeed = try! b01ValueNeed(
        "blocker-01:contract:producer-oak", actorID: b01Producer,
        item: "oak_log", session: &fullContract.session
    )
    let counterpartyBreadNeed = try! b01ValueNeed(
        "blocker-01:contract:counterparty-bread", actorID: b01Counterparty,
        item: "bread", session: &fullContract.session
    )
    try! fullContract.session.setContractsEnabled(true)
    let contractNeeds = fullContract.session.productionSnapshot().needs
    let contractOpportunity = AgentContractOpportunityObservation(
        opportunityID: "blocker-01-full-contract",
        promisorID: b01Producer, promiseeID: b01Counterparty,
        consideration: AgentBarterLeg(
            assetID: oakAsset, holderID: b01Counterparty,
            material: b01Stack("oak_log", 1),
            holderObservation: oakObservation, productionOperationIDs: []
        ), promisorReason: AgentBarterValueReason(
            need: contractNeeds.first { $0.needID == producerOakNeed }!
        ), promiseeReason: AgentBarterValueReason(
            need: contractNeeds.first { $0.needID == counterpartyBreadNeed }!
        ), promisedPerformance: AgentContractPerformanceTerms(
            material: b01Stack("bread", 1)
        ), distance: 2, lineOfSight: true, chunksReady: true,
        observedAtTick: fullContract.session.tick,
        expiresAtTick: fullContract.session.tick
            + fullContract.session.contractSnapshot().configuration!
                .proposalLifetimeTicks
    )
    try! fullContract.session.recordContractOpportunity(contractOpportunity)
    let proposal = fullContract.session.nextAutonomousPromiseProposal()!
    try! fullContract.session.createPromiseProposal(
        proposalID: proposal.proposalID,
        opportunityID: proposal.opportunityID,
        promisorID: proposal.promisorID
    )
    _ = try! fullContract.session.advanceTick()
    try! fullContract.session.decidePromiseProposal(
        proposalID: proposal.proposalID,
        promiseeID: b01Counterparty, accept: true,
        reason: "counterparty accepts exact one-bread performance"
    )
    let awaiting = fullContract.session.contractSnapshot().obligations.first!
    let considerationReceipt = "blocker-01-contract-consideration"
    try! fullContract.session.recordVerifiedContractConsideration(
        AgentVerifiedContractConsiderationOutcome(
            operationID: considerationReceipt,
            obligationID: awaiting.obligationID,
            transfer: AgentVerifiedContractTransfer(
                assetID: oakAsset,
                sourceObservation: AgentMaterialHolderObservation(
                    holder: .agent(b01Counterparty),
                    materialIdentity: b01Identity("oak_log"), quantity: 1,
                    custodyFingerprint: "counterparty-oak-current",
                    physicalReceiptID: "counterparty-oak-current",
                    observedAtTick: fullContract.session.tick
                ), destinationObservation: AgentMaterialHolderObservation(
                    holder: .agent(b01Producer),
                    materialIdentity: b01Identity("oak_log"), quantity: 1,
                    custodyFingerprint: "producer-oak-after",
                    physicalReceiptID: considerationReceipt,
                    observedAtTick: fullContract.session.tick
                ), physicalReceiptID: considerationReceipt,
                productionOperationIDs: []
            ), completedAtTick: fullContract.session.tick
        )
    )
    let openCheckpoint = try! fullContract.session.makeCheckpoint()
    var openRestored = try! AgentSimulationSession.restoring(openCheckpoint)
    check("open debt and exact provenance survive fresh restart",
          openRestored.contractSnapshot().obligations.first?.status
            == .outstanding
            && openRestored.materialRightsSnapshot().records.first {
                $0.asset.assetID == fullContract.assets[2]
            }?.productionProvenance?.operationIDs
                == [fullContract.productions[2].operationID])
    try! b01GrantReturnPermission(
        assetID: fullContract.assets[2], session: &openRestored
    )
    try! b01Transfer(
        assetID: fullContract.assets[2], actorID: b01Producer,
        destinationID: b01Keeper, suffix: "promised-displaced",
        session: &openRestored
    )
    let outstanding = openRestored.contractSnapshot().obligations.first!
    func fulfillment(
        _ session: AgentSimulationSession,
        suffix: String
    ) -> AgentVerifiedContractFulfillmentOutcome {
        let source = session.materialRightsSnapshot().records.first {
            $0.asset.assetID == fullContract.assets[2]
        }!.lastVerifiedHolder
        let receipt = "blocker-01-fulfillment:\(suffix)"
        return AgentVerifiedContractFulfillmentOutcome(
            operationID: receipt, obligationID: outstanding.obligationID,
            transfer: AgentVerifiedContractTransfer(
                assetID: fullContract.assets[2],
                sourceObservation: AgentMaterialHolderObservation(
                    holder: .agent(b01Producer),
                    materialIdentity: b01Identity("bread"), quantity: 1,
                    custodyFingerprint: source.custodyFingerprint,
                    physicalReceiptID: "blocker-01-current:\(suffix)",
                    observedAtTick: session.tick
                ), destinationObservation: AgentMaterialHolderObservation(
                    holder: .agent(b01Counterparty),
                    materialIdentity: b01Identity("bread"), quantity: 1,
                    custodyFingerprint: "counterparty-bread:\(suffix)",
                    physicalReceiptID: receipt, observedAtTick: session.tick
                ), physicalReceiptID: receipt,
                productionOperationIDs: [fullContract.productions[2].operationID]
            ), completedAtTick: session.tick
        )
    }
    let displacedBytes = try! openRestored.durableStateBytes()
    check("displaced promised asset refuses fulfillment",
          (try? openRestored.recordVerifiedContractFulfillment(
              fulfillment(openRestored, suffix: "displaced")
          )) == nil)
    check("displacement leaves debt open and creates no synthetic replacement",
          openRestored.contractSnapshot().obligations.first?.status
            == .outstanding
            && openRestored.productionSnapshot().totalProductionCount == 3
            && (try! openRestored.durableStateBytes()) == displacedBytes)
    try! b01Transfer(
        assetID: fullContract.assets[2], actorID: b01Keeper,
        destinationID: b01Producer, suffix: "promised-returned",
        session: &openRestored
    )
    let returnedProof = openRestored.materialRightsSnapshot().records.first {
        $0.asset.assetID == fullContract.assets[2]
    }!.productionProvenance
    check("same exact promised asset returns with origin unchanged",
          returnedProof?.operationIDs
            == [fullContract.productions[2].operationID])
    let completed = fulfillment(openRestored, suffix: "returned")
    try! openRestored.recordVerifiedContractFulfillment(completed)
    check("physical fulfillment succeeds once after exact return",
          openRestored.contractSnapshot().obligations.first?.status == .fulfilled
            && openRestored.contractSnapshot().totalFulfilledCount == 1)
    let fulfilledBytes = try! openRestored.durableStateBytes()
    check("duplicate fulfillment remains refused",
          (try? openRestored.recordVerifiedContractFulfillment(completed)) == nil
            && (try! openRestored.durableStateBytes()) == fulfilledBytes)
    check("production origin survives contract holder and owner transfer",
          openRestored.materialRightsSnapshot().records.first {
              $0.asset.assetID == fullContract.assets[2]
          }?.recognizedOwnership?.ownerID == b01Counterparty
            && openRestored.materialRightsSnapshot().records.first {
                $0.asset.assetID == fullContract.assets[2]
            }?.productionProvenance == returnedProof)

    var barter = b01ThreeBreadFixture("gate-e-blocker-01-barter")
    let barterOak = AgentMaterialAssetID(rawValue: "blocker-01-barter-oak")!
    let barterOakObservation = try! b01RegisterAsset(
        barterOak, material: b01Stack("oak_log", 1),
        holder: b01Counterparty, fingerprint: "barter-oak-current",
        receipt: "barter-oak-current", claimBasis: .found,
        session: &barter.session
    )
    _ = try! b01ValueNeed(
        "blocker-01:barter:producer-oak", actorID: b01Producer,
        item: "oak_log", session: &barter.session
    )
    _ = try! b01ValueNeed(
        "blocker-01:barter:counterparty-bread", actorID: b01Counterparty,
        item: "bread", session: &barter.session
    )
    try! barter.session.setBarterEnabled(true)
    let lifetime = barter.session.barterSnapshot().configuration!.offerLifetimeTicks
    let physicalPair = AgentBarterPhysicalPairObservation(
        candidateID: "blocker-01-barter-physical",
        actorAID: b01Counterparty, actorBID: b01Producer,
        actorAGood: AgentBarterLeg(
            assetID: barterOak, holderID: b01Counterparty,
            material: b01Stack("oak_log", 1),
            holderObservation: barterOakObservation,
            productionOperationIDs: []
        ), actorBGood: b01Leg(
            assetID: barter.assets[2], holderID: b01Producer,
            session: barter.session
        ), distance: 2, lineOfSight: true, chunksReady: true,
        observedAtTick: barter.session.tick,
        expiresAtTick: barter.session.tick + lifetime
    )
    let barterDiscovery = try! barter.session.discoverBarterOpportunities(
        from: [physicalPair]
    ).first!
    try! barter.session.recordBarterOpportunity(barterDiscovery)
    let barterOffer = barter.session.nextAutonomousBarterOfferProposal()!
    try! barter.session.createBarterOffer(
        offerID: barterOffer.offerID,
        opportunityID: barterOffer.opportunityID,
        actorID: barterOffer.actorID
    )
    _ = try! barter.session.advanceTick()
    let barterDecision = barter.session.evaluateAutonomousBarterCounterpartyDecision(
        AgentBarterCounterpartyDecisionObservation(
            offerID: barterOffer.offerID,
            counterpartyID: barterDiscovery.counterpartyID,
            distance: 2, lineOfSight: true, chunksReady: true,
            observedAtTick: barter.session.tick
        )
    )!
    try! barter.session.decideBarterOffer(
        offerID: barterDecision.offerID,
        counterpartyID: barterDecision.counterpartyID,
        accept: barterDecision.accept, reason: barterDecision.reason
    )
    let barterReceipt = "blocker-01-barter-complete"
    try! barter.session.recordVerifiedBarter(AgentVerifiedBarterOutcome(
        operationID: barterReceipt, offerID: barterOffer.offerID,
        offeredLeg: AgentVerifiedBarterLeg(
            assetID: barterOak,
            sourceObservation: physicalPair.actorAGood.holderObservation,
            destinationObservation: AgentMaterialHolderObservation(
                holder: .agent(b01Producer),
                materialIdentity: b01Identity("oak_log"), quantity: 1,
                custodyFingerprint: "barter-producer-oak",
                physicalReceiptID: "blocker-01-barter-oak",
                observedAtTick: barter.session.tick
            ), physicalReceiptID: "blocker-01-barter-oak"
        ), requestedLeg: AgentVerifiedBarterLeg(
            assetID: barter.assets[2],
            sourceObservation: physicalPair.actorBGood.holderObservation,
            destinationObservation: AgentMaterialHolderObservation(
                holder: .agent(b01Counterparty),
                materialIdentity: b01Identity("bread"), quantity: 1,
                custodyFingerprint: "barter-counterparty-bread",
                physicalReceiptID: "blocker-01-barter-bread",
                observedAtTick: barter.session.tick
            ), physicalReceiptID: "blocker-01-barter-bread"
        ), completedAtTick: barter.session.tick
    ))
    let barteredBread = barter.session.materialRightsSnapshot().records.first {
        $0.asset.assetID == barter.assets[2]
    }!
    check("CIV-35 exact identical-output provenance completes physical exchange",
          barter.session.barterSnapshot().totalCompletedCount == 1
            && barterDiscovery.requested.productionOperationIDs
                == [barter.productions[2].operationID]
            && barteredBread.productionProvenance?.operationIDs
                == [barter.productions[2].operationID]
            && barteredBread.recognizedOwnership?.ownerID == b01Counterparty)

    var compacted = b01ThreeBreadFixture(
        "gate-e-blocker-01-compaction", maximumProductionRecords: 3
    )
    for ordinal in 4...6 {
        _ = try! b01Produce(
            ordinal: ordinal, item: "cobblestone",
            sourceBefore: "compaction-\(ordinal)-before",
            sourceAfter: "compaction-\(ordinal)-after",
            session: &compacted.session
        )
    }
    let p3ID = compacted.productions[2].operationID
    check("bounded production history evicts the original record",
          !compacted.session.productionSnapshot().records.contains {
              $0.operationID == p3ID
          } && compacted.session.productionSnapshot().records.count == 3)
    let compactedCheckpoint = try! compacted.session.makeCheckpoint()
    let compactedRestored = try! AgentSimulationSession.restoring(
        compactedCheckpoint
    )
    check("minimal validated origin proof survives compaction and restart",
          compactedRestored.materialRightsSnapshot().records.first {
              $0.asset.assetID == compacted.assets[2]
          }?.productionProvenance?.operationIDs == [p3ID]
            && (try! compactedRestored.durableStateBytes())
                == (try! compacted.session.durableStateBytes()))
    check("fully re-signed forged compacted provenance fails closed",
          b01ResignedProvenanceMutationRefused(compactedCheckpoint))

    check("Blocker 01 conservation and Observer authority remain exact",
          fixture.session.materialRightsSnapshot().records.count == 3
            && fixture.session.productionSnapshot().totalProductionCount == 3)
}
