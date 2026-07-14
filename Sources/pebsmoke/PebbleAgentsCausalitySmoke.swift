import Foundation
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
    check("typed agent identity rejects empty values", AgentID(rawValue: "") == nil)
    check("typed agent identity rejects overlong values", AgentID(rawValue: String(repeating: "a", count: 65)) == nil)
    check("typed agent identity rejects non-ASCII values", AgentID(rawValue: "agent_é") == nil)
    check(
        "typed agent identity comparison is lexical",
        [AgentID(rawValue: "agent_10")!, AgentID(rawValue: "agent_2")!].sorted().map(\.rawValue)
            == ["agent_10", "agent_2"]
    )
    let identityEncoder = JSONEncoder()
    let identityDecoder = JSONDecoder()
    check(
        "typed identities preserve Codable round trips",
        (try? identityDecoder.decode(AgentID.self, from: identityEncoder.encode(agentID))) == agentID
            && (try? identityDecoder.decode(AgentSimulationID.self, from: identityEncoder.encode(simulationID))) == simulationID
            && (try? identityDecoder.decode(AgentOperationID.self, from: identityEncoder.encode(operationID))) == operationID
    )
    check("typed simulation identity rejects invalid values", AgentSimulationID(rawValue: "bad simulation") == nil)
    check("typed operation identity rejects empty values", AgentOperationID(rawValue: "") == nil)

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
    check("legacy string agent accessor derives from typed identity", state.id == agentID.rawValue)
    check("session exposes explicit simulation identity", session.simulationID == simulationID)
    check("simulation clock exposes the validated initial tick", session.tick == 0 && session.clock.tick.rawValue == 0)
    check(
        "legacy simulation identity fallback is seed stable",
        AgentSimulationID.legacy(seed: 42) == AgentSimulationID.legacy(seed: 42)
            && AgentSimulationID.legacy(seed: 42) != AgentSimulationID.legacy(seed: 43)
    )
    var duplicateAgentRejected = false
    do {
        _ = try AgentSimulationSession(configuration: configuration, agents: [state, state])
    } catch AgentSessionError.duplicateAgentId("agent_0") {
        duplicateAgentRejected = true
    } catch {}
    check("duplicate typed agent identity is rejected", duplicateAgentRejected)

    let secondState = AgentSessionAgentState(
        agentID: try! AgentID(validating: "agent_1"), state: "idle",
        position: AgentPosition(x: 1, y: 64, z: 0), needs: state.needs,
        health: 100, fear: 0, homePosition: AgentPosition(x: 1, y: 64, z: 0),
        nearbyAgents: [], currentGoal: state.currentGoal, lastAction: nil,
        lastActionEffect: nil, memory: [], tickCreated: 0, ticksAlive: 0,
        observationCount: 0, nearbyObservationCount: 0, goalSelectionCount: 0,
        goalChangeCount: 0, actionCount: 0, actionEffectCount: 0,
        movementCount: 0, totalManhattanDistanceMoved: 0,
        returnHomeMoveCount: 0, totalDistanceReducedTowardHome: 0
    )
    let orderedIdentity = try! AgentSimulationSession(
        configuration: configuration, agents: [state, secondState]
    ).identitySnapshot()
    let reversedIdentity = try! AgentSimulationSession(
        configuration: configuration, agents: [secondState, state]
    ).identitySnapshot()
    check("typed session identity is input-order independent", orderedIdentity == reversedIdentity)
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
    var causeLimitRejected = false
    var causeOrderRejected = false
    var payloadMismatchRejected = false
    do { try AgentCausalEvent.validate(causes: [eventTwo], for: eventTwo) }
    catch AgentCausalLedgerError.nonPriorCause { futureRejected = true }
    catch {}
    do { try AgentCausalEvent.validate(causes: [causeOne, causeOne], for: eventTwo) }
    catch AgentCausalLedgerError.duplicateCause { duplicateCauseRejected = true }
    catch {}
    do { try AgentCausalEvent.validate(causes: [foreignOne], for: eventTwo) }
    catch AgentCausalLedgerError.crossSimulationCause { crossSimulationRejected = true }
    catch {}
    let eventTen = AgentCausalEventID(
        simulationID: simulationID,
        sequence: AgentCausalSequence(rawValue: 10)!
    )
    let nineCauses = (1...9).map {
        AgentCausalEventID(simulationID: simulationID, sequence: AgentCausalSequence(rawValue: UInt64($0))!)
    }
    do { try AgentCausalEvent.validate(causes: nineCauses, for: eventTen) }
    catch AgentCausalLedgerError.tooManyCauses(9) { causeLimitRejected = true }
    catch {}
    do { try AgentCausalEvent.validate(causes: [eventTwo, causeOne], for: eventTen) }
    catch AgentCausalLedgerError.nonPriorCause { causeOrderRejected = true }
    catch {}
    do {
        try AgentCausalEvent.validate(
            payload: .feature(name: "movement", enabled: true),
            for: .movement
        )
    } catch AgentCausalLedgerError.payloadMismatch(.movement) {
        payloadMismatchRejected = true
    } catch {}
    check("future causal reference rejected", futureRejected)
    check("duplicate causal reference rejected", duplicateCauseRejected)
    check("cross-simulation causal reference rejected", crossSimulationRejected)
    check("causal reference count is explicitly bounded", causeLimitRejected)
    check("causal references require canonical order", causeOrderRejected)
    check("causal event kind rejects mismatched payload", payloadMismatchRejected)
    check(
        "causal event kind accepts its typed payload",
        (try? AgentCausalEvent.validate(
            payload: .movement(
                status: "moved",
                from: AgentPosition(x: 0, y: 64, z: 0),
                to: AgentPosition(x: 1, y: 64, z: 0)
            ),
            for: .movement
        )) != nil
    )

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
    let encodedLedger = try! JSONEncoder().encode(ledger)
    check(
        "causal ledger snapshot preserves Codable round trip",
        try! JSONDecoder().decode(AgentCausalLedgerSnapshot.self, from: encodedLedger) == ledger
    )
    check(
        "causal ledger sequences are contiguous and event IDs unique",
        ledger.events.map(\.sequence.rawValue) == Array(1...ledger.summary.latestSequence)
            && Set(ledger.events.map(\.eventID)).count == ledger.events.count
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
