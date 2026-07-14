import Foundation
import PebbleAgents

private struct CausalLedgerDigestReport: Encodable {
    let schemaVersion = 1
    let simulationID: AgentSimulationID
    let latestSequence: UInt64
    let digest: String
}

private struct CausalLedgerInvariantCheck: Encodable {
    let name: String
    let passed: Bool
}

private struct CausalLedgerInvariantReport: Encodable {
    let schemaVersion = 1
    let scenario: String
    let seed: UInt32
    let success: Bool
    let checks: [CausalLedgerInvariantCheck]
}

private func causalState(id: String, inventoryCapacity: Int = 16) -> AgentSessionAgentState {
    AgentSessionAgentState(
        agentID: try! AgentID(validating: id), state: "idle",
        position: AgentPosition(x: 0, y: 64, z: 0),
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0.8, safety: 1),
        health: 100, fear: 0, homePosition: AgentPosition(x: 0, y: 64, z: 0),
        nearbyAgents: [],
        currentGoal: AgentGoal(kind: .idle, reason: "initial", startedAtTick: 0, urgency: 0),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0, ticksAlive: 0,
        observationCount: 0, nearbyObservationCount: 0, goalSelectionCount: 0,
        goalChangeCount: 0, actionCount: 0, actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0,
        resourceInventory: AgentResourceInventory(capacity: inventoryCapacity)
    )
}

func runCausalLedgerSmoke(_ options: Options) -> Never {
    guard let outPath = options.outPath else {
        fail("causal_ledger_smoke requires an explicit --out directory")
    }
    let simulationID = try! AgentSimulationID(validating: "headless-seed-\(options.seed)")
    let configuration = try! AgentSessionConfiguration(
        seed: options.seed, nearbyRadius: 8, resourceObservationRadius: 8,
        recentMemorySnapshotLimit: 8, memoryPolicy: .bounded(maxEntries: 64),
        campStockCapacity: 64
    )
    var session = try! AgentSimulationSession(
        configuration: configuration, agents: [causalState(id: "agent_0")],
        simulationID: simulationID, causalLedgerPolicy: .bounded(maxEvents: 256)
    )
    session.setEconomyEnabled(true)
    let origin = AgentPosition(x: 4, y: 64, z: 4)
    let project = try! AgentConstructionProject(
        projectId: "causal-project", builderAgentId: "agent_0", origin: origin,
        createdAtTick: session.tick, previousHomePosition: AgentPosition(x: 0, y: 64, z: 0),
        originalFingerprints: AgentBlueprint.fixedLeanToV1.cells.map {
            AgentConstructionCellFingerprint(cellIndex: $0.index, originalFingerprint: 100 + $0.index)
        }
    )
    try! session.createConstructionProject(project)
    try! session.setBuildAutoEnabled(true)

    let resourceTarget = AgentPosition(x: 2, y: 64, z: 0)
    let perception = AgentPerceptionInput(
        agentId: "agent_0", observationCountIncrement: 1,
        resourceObservations: [AgentResourceObservation(
            resource: .wood, target: resourceTarget, direction: .east,
            distanceManhattan: 2, quantityAvailable: 1, source: .sandboxFixture
        )],
        navigationObservation: AgentNavigationObservation(
            worldTick: 1, origin: AgentPosition(x: 0, y: 64, z: 0), target: resourceTarget,
            cells: [
                AgentNavigationCell(position: AgentPosition(x: 0, y: 64, z: 0), status: .traversable),
                AgentNavigationCell(position: AgentPosition(x: 1, y: 64, z: 0), status: .traversable),
            ]
        )
    )
    _ = try! session.advanceTick(perceptions: [perception])
    try! session.applyMovementOutcomes(AgentMovementCoordinator.resolve(snapshot: session.snapshot()))

    var firstInteraction: AgentInteractionOutcome?
    for index in 0..<9 {
        let resource: AgentResourceKind = index < 6 ? .wood : .stone
        let outcome = AgentInteractionOutcome(
            interactionId: "agent_0:fixture:\(index)", agentId: "agent_0", tick: session.tick,
            target: AgentPosition(x: index + 10, y: 64, z: 0), resource: resource,
            status: .succeeded, inventoryDelta: AgentInventoryDelta(resource: resource, quantity: 1),
            reason: "verified fixture harvest"
        )
        try! session.applyInteractionOutcome(outcome)
        if firstInteraction == nil { firstInteraction = outcome }
    }
    let sequenceBeforeDuplicate = session.causalLedgerSnapshot().summary.latestSequence
    var duplicateRejected = false
    do { try session.applyInteractionOutcome(firstInteraction!) }
    catch AgentSessionError.duplicateInteraction(_) { duplicateRejected = true }
    catch {}
    let sequenceAfterDuplicate = session.causalLedgerSnapshot().summary.latestSequence

    _ = try! session.deliverResources(AgentDeliveryIntent(
        deliveryId: "agent_0:delivery:\(session.tick)", agentId: "agent_0", tick: session.tick,
        position: AgentPosition(x: 0, y: 64, z: 0)
    ))
    _ = try! session.fundConstructionProject(
        fundingId: "causal-project:fund:\(session.tick)", builderAgentId: "agent_0",
        fundingTick: session.tick
    )
    for cell in AgentBlueprint.fixedLeanToV1.cells {
        let activeProject = session.snapshot().constructionProject!
        try! session.applyExternalUpdate(AgentExternalUpdate(
            agentId: "agent_0", position: activeProject.workPosition(for: cell)
        ))
        try! session.applyPlacementOutcome(AgentPlacementOutcome(
            placementId: "causal-project:place:\(cell.index)", projectId: "causal-project",
            builderAgentId: "agent_0", tick: session.tick, cellIndex: cell.index,
            target: activeProject.worldPosition(for: cell), resource: cell.resource,
            status: .succeeded, reason: "verified fixture placement"
        ))
        if cell.index < AgentBlueprint.fixedLeanToV1.cells.count - 1 { _ = try! session.advanceTick() }
    }
    try! session.completeConstructionProject(projectId: "causal-project", completionTick: session.tick)

    let ledger = session.causalLedgerSnapshot()
    let events = ledger.events
    let sequences = events.map { $0.eventID.sequence.rawValue }
    let eventIDs = events.map { $0.eventID.rawValue }
    let validActors = Set(session.snapshot().agents.map(\.id))
    let sequenceMonotone = zip(sequences, sequences.dropFirst()).allSatisfy { $0 < $1 }
    let causesValid = events.allSatisfy { event in
        event.causes.allSatisfy {
            $0.simulationID == simulationID && $0.sequence < event.eventID.sequence
        }
    }
    let kinds = Set(events.map(\.kind))
    let materialChainPresent = [AgentCausalEventKind.constructionFunding, .constructionPlacement, .constructionCompletion].allSatisfy { kinds.contains($0) }
    let socialSeedChainPresent = [AgentCausalEventKind.perception, .actionSelected, .interaction].allSatisfy { kinds.contains($0) }
        && events.first(where: { $0.kind == .actionSelected })?.causes.isEmpty == false
        && events.first(where: { $0.kind == .interaction })?.causes.isEmpty == false

    let permutationID = try! AgentSimulationID(validating: "permutation-seed-\(options.seed)")
    let permutationInputs = [AgentPerceptionInput(agentId: "agent_b"), AgentPerceptionInput(agentId: "agent_a")]
    var permutationA = try! AgentSimulationSession(
        configuration: configuration, agents: [causalState(id: "agent_a"), causalState(id: "agent_b")],
        simulationID: permutationID, causalLedgerPolicy: .bounded(maxEvents: 32)
    )
    var permutationB = try! AgentSimulationSession(
        configuration: configuration, agents: [causalState(id: "agent_b"), causalState(id: "agent_a")],
        simulationID: permutationID, causalLedgerPolicy: .bounded(maxEvents: 32)
    )
    _ = try! permutationA.advanceTick(perceptions: permutationInputs)
    _ = try! permutationB.advanceTick(perceptions: Array(permutationInputs.reversed()))
    let permutationStable = permutationA.causalLedgerSnapshot() == permutationB.causalLedgerSnapshot()

    var eviction = try! AgentSimulationSession(
        configuration: configuration, agents: [causalState(id: "agent_0")],
        simulationID: try! AgentSimulationID(validating: "eviction-seed-\(options.seed)"),
        causalLedgerPolicy: .bounded(maxEvents: 3)
    )
    _ = try! eviction.advanceTick()
    _ = try! eviction.advanceTick()
    let evictionSummary = eviction.causalLedgerSnapshot().summary
    let evictionExact = evictionSummary.latestSequence > 3
        && evictionSummary.retainedEventCount == 3
        && evictionSummary.droppedEventCount == evictionSummary.latestSequence - 3
        && evictionSummary.firstRetainedEventID?.sequence.rawValue == evictionSummary.droppedEventCount + 1
        && evictionSummary.lastRetainedEventID?.sequence.rawValue == evictionSummary.latestSequence
        && !evictionSummary.retainedCauseCoverageComplete

    let checks = [
        CausalLedgerInvariantCheck(name: "simulation_id_stable", passed: events.allSatisfy { $0.instant.simulationID == simulationID }),
        CausalLedgerInvariantCheck(name: "ticks_monotone", passed: zip(events.map { $0.instant.tick.rawValue }, events.dropFirst().map { $0.instant.tick.rawValue }).allSatisfy { $0 <= $1 }),
        CausalLedgerInvariantCheck(name: "sequences_strictly_increasing", passed: sequenceMonotone),
        CausalLedgerInvariantCheck(name: "event_ids_unique", passed: Set(eventIDs).count == eventIDs.count),
        CausalLedgerInvariantCheck(name: "actors_valid", passed: events.allSatisfy { $0.actorID.map { validActors.contains($0.rawValue) } ?? true }),
        CausalLedgerInvariantCheck(name: "operation_ids_correlated", passed: events.filter { $0.kind == .interaction || $0.kind == .delivery || $0.kind == .constructionFunding || $0.kind == .constructionPlacement }.allSatisfy { $0.operationID != nil }),
        CausalLedgerInvariantCheck(name: "causes_prior_same_simulation_acyclic", passed: causesValid),
        CausalLedgerInvariantCheck(name: "observation_action_outcome_chain", passed: socialSeedChainPresent),
        CausalLedgerInvariantCheck(name: "funding_placement_completion_chain", passed: materialChainPresent),
        CausalLedgerInvariantCheck(name: "rejected_duplicate_has_no_event", passed: duplicateRejected && sequenceBeforeDuplicate == sequenceAfterDuplicate),
        CausalLedgerInvariantCheck(name: "equivalent_input_permutation_stable", passed: permutationStable),
        CausalLedgerInvariantCheck(name: "bounded_eviction_exact_no_id_reuse", passed: evictionExact),
        CausalLedgerInvariantCheck(name: "material_conservation_exact", passed: session.conservationSnapshot().balanced),
    ]
    let report = CausalLedgerInvariantReport(
        scenario: "causal_ledger_smoke", seed: options.seed,
        success: checks.allSatisfy(\.passed), checks: checks
    )
    if !report.success {
        let failed = checks.filter { !$0.passed }.map(\.name).joined(separator: ",")
        fail("causal_ledger_smoke invariant failure: \(failed)")
    }

    let directory = URL(fileURLWithPath: outPath, isDirectory: true)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    do {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try writeCausalJSON(ledger, name: "causal_ledger.json", directory: directory, encoder: encoder)
        try writeCausalJSON(ledger.summary, name: "causal_ledger_summary.json", directory: directory, encoder: encoder)
        try writeCausalJSON(CausalLedgerDigestReport(
            simulationID: simulationID, latestSequence: ledger.summary.latestSequence,
            digest: ledger.summary.digest
        ), name: "causal_ledger_digest.json", directory: directory, encoder: encoder)
        try writeCausalJSON(report, name: "causal_ledger_invariant_report.json", directory: directory, encoder: encoder)
    } catch { fail("failed to write causal ledger outputs to \(outPath): \(error)") }
    print("causal_ledger_smoke PASS events=\(ledger.summary.retainedEventCount) sequence=\(ledger.summary.latestSequence) digest=\(ledger.summary.digest)")
    exit(0)
}

private func writeCausalJSON<T: Encodable>(
    _ value: T, name: String, directory: URL, encoder: JSONEncoder
) throws {
    let data = try encoder.encode(value)
    try (data + Data([0x0A])).write(to: directory.appendingPathComponent(name), options: .atomic)
}
