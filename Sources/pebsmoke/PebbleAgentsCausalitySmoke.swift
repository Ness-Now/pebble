import PebbleAgents

func runPebbleAgentsCausalitySmoke() {
    section("pebble agents stable identity and simulation clock")

    let agentID = try! AgentID(validating: "agent_0")
    let simulationID = try! AgentSimulationID(validating: "smoke-seed-42")
    let operationID = try! AgentOperationID(validating: "agent_0:interaction:1:0,64,0")
    check("typed agent identity preserves canonical string", agentID.rawValue == "agent_0")
    check("typed simulation identity preserves canonical string", simulationID.rawValue == "smoke-seed-42")
    check("typed operation identity preserves canonical string", operationID.rawValue == "agent_0:interaction:1:0,64,0")
    check("typed agent identity rejects whitespace", AgentID(rawValue: "agent 0") == nil)

    let configuration = try! AgentSessionConfiguration(
        seed: 42,
        memoryPolicy: .bounded(maxEntries: 8)
    )
    let state = AgentSessionAgentState(
        agentID: agentID,
        state: "idle",
        position: AgentPosition(x: 0, y: 64, z: 0),
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0, safety: 1),
        health: 100,
        fear: 0,
        homePosition: AgentPosition(x: 0, y: 64, z: 0),
        nearbyAgents: [],
        currentGoal: AgentGoal(kind: .idle, reason: "initial", startedAtTick: 0, urgency: 0),
        lastAction: nil,
        lastActionEffect: nil,
        memory: [],
        tickCreated: 0,
        ticksAlive: 0,
        observationCount: 0,
        nearbyObservationCount: 0,
        goalSelectionCount: 0,
        goalChangeCount: 0,
        actionCount: 0,
        actionEffectCount: 0,
        movementCount: 0,
        totalManhattanDistanceMoved: 0,
        returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
    var session = try! AgentSimulationSession(
        configuration: configuration,
        agents: [state],
        simulationID: simulationID,
        causalLedgerPolicy: .bounded(maxEvents: 32)
    )
    check("session exposes explicit simulation identity", session.simulationID == simulationID)
    _ = try! session.advanceTick()
    check("simulation clock advances exactly once per accepted tick", session.tick == 1)
    var ledger = session.causalLedgerSnapshot()
    check("causal ledger records lifecycle and tick chain", ledger.summary.latestSequence == 4)
    let perceptionEvent = ledger.events.first { $0.kind == .perception }
    let actionEvent = ledger.events.first { $0.kind == .actionSelected }
    check(
        "action causally references accepted perception or goal transition",
        perceptionEvent != nil && actionEvent?.causes.isEmpty == false
    )

    let interaction = AgentInteractionOutcome(
        interactionId: operationID.rawValue,
        agentId: agentID.rawValue,
        tick: session.tick,
        target: AgentPosition(x: 1, y: 64, z: 0),
        resource: .wood,
        status: .succeeded,
        inventoryDelta: AgentInventoryDelta(resource: .wood, quantity: 1),
        reason: "verified fixture harvest"
    )
    try! session.applyInteractionOutcome(interaction)
    ledger = session.causalLedgerSnapshot()
    let sequenceAfterInteraction = ledger.summary.latestSequence
    var duplicateRejected = false
    do {
        try session.applyInteractionOutcome(interaction)
    } catch AgentSessionError.duplicateInteraction(operationID.rawValue) {
        duplicateRejected = true
    } catch {}
    check(
        "duplicate outcome consumes no causal sequence",
        duplicateRejected && session.causalLedgerSnapshot().summary.latestSequence == sequenceAfterInteraction
    )
    check(
        "world outcome retains operation correlation",
        ledger.events.last?.operationID == operationID && ledger.events.last?.causes.isEmpty == false
    )

    let foreignSimulation = try! AgentSimulationID(validating: "foreign-seed-42")
    let one = AgentCausalSequence(rawValue: 1)!
    let two = AgentCausalSequence(rawValue: 2)!
    let eventTwo = AgentCausalEventID(simulationID: simulationID, sequence: two)
    let causeOne = AgentCausalEventID(simulationID: simulationID, sequence: one)
    let foreignOne = AgentCausalEventID(simulationID: foreignSimulation, sequence: one)
    var futureRejected = false
    var duplicateCauseRejected = false
    var crossSimulationRejected = false
    do { try AgentCausalEvent.validate(causes: [eventTwo], for: eventTwo) }
    catch AgentCausalLedgerError.nonPriorCause { futureRejected = true }
    catch {}
    do { try AgentCausalEvent.validate(causes: [causeOne, causeOne], for: eventTwo) }
    catch AgentCausalLedgerError.duplicateCause { duplicateCauseRejected = true }
    catch {}
    do { try AgentCausalEvent.validate(causes: [foreignOne], for: eventTwo) }
    catch AgentCausalLedgerError.crossSimulationCause { crossSimulationRejected = true }
    catch {}
    check("future causal reference rejected", futureRejected)
    check("duplicate causal reference rejected", duplicateCauseRejected)
    check("cross-simulation causal reference rejected", crossSimulationRejected)

    var bounded = try! AgentSimulationSession(
        configuration: configuration,
        agents: [state],
        simulationID: simulationID,
        causalLedgerPolicy: .bounded(maxEvents: 3)
    )
    _ = try! bounded.advanceTick()
    _ = try! bounded.advanceTick()
    let boundedLedger = bounded.causalLedgerSnapshot()
    check(
        "bounded ledger evicts oldest events without sequence reuse",
        boundedLedger.summary.latestSequence == 7
            && boundedLedger.summary.retainedEventCount == 3
            && boundedLedger.summary.droppedEventCount == 4
            && boundedLedger.summary.firstRetainedEventID?.sequence.rawValue == 5
    )

    var invalidTick = session
    let tickBeforeFailure = invalidTick.tick
    let sequenceBeforeFailure = invalidTick.causalLedgerSnapshot().summary.latestSequence
    var invalidInputRejected = false
    do {
        _ = try invalidTick.advanceTick(perceptions: [AgentPerceptionInput(agentId: "missing")])
    } catch AgentSessionError.unknownAgentId("missing") {
        invalidInputRejected = true
    } catch {}
    check(
        "rejected tick advances neither clock nor ledger",
        invalidInputRejected && invalidTick.tick == tickBeforeFailure
            && invalidTick.causalLedgerSnapshot().summary.latestSequence == sequenceBeforeFailure
    )

    var overflow = try! AgentSimulationSession(
        configuration: configuration,
        agents: [state],
        initialTick: Int.max,
        simulationID: simulationID
    )
    var rejectedOverflow = false
    do {
        _ = try overflow.advanceTick()
    } catch AgentSessionError.simulationTickOverflow {
        rejectedOverflow = true
    } catch {}
    check("simulation clock rejects overflow without mutation", rejectedOverflow && overflow.tick == Int.max)
    check(
        "legacy session identity is deterministic",
        (try! AgentSimulationSession(configuration: configuration, agents: [state])).simulationID.rawValue
            == "legacy-seed-42"
    )
}
