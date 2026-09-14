import Foundation
import PebbleAgents

private func terminalContinuityAgent(
    _ ordinal: Int,
    health: Int = 100,
    lethal: Bool = false
) -> AgentSessionAgentState {
    let position = AgentPosition(
        x: (ordinal % 8) * 2,
        y: 64,
        z: (ordinal / 8) * 2
    )
    return AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: position,
        needs: AgentNeeds(
            hunger: lethal ? 1 : 0,
            fatigue: 0,
            curiosity: 0.1,
            safety: 1
        ),
        health: health, fear: 0, homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle,
            reason: "terminal continuity fixture",
            startedAtTick: 0,
            urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [],
        tickCreated: 0, ticksAlive: 0, observationCount: 0,
        nearbyObservationCount: 0, goalSelectionCount: 0,
        goalChangeCount: 0, actionCount: 0, actionEffectCount: 0,
        movementCount: 0, totalManhattanDistanceMoved: 0,
        returnHomeMoveCount: 0, totalDistanceReducedTowardHome: 0,
        survivalProgress: AgentSurvivalProgress(
            status: lethal ? .starving : .stable,
            consecutiveCriticalHungerTicks: lethal ? 2 : 0
        )
    )
}

private func terminalContinuitySession(
    simulationID: String,
    total: Int,
    lethalCount: Int,
    reverseInput: Bool = false,
    causalEvents: Int = 8_192,
    delayedLethalStart: Int? = nil
) throws -> AgentSimulationSession {
    var agents = (0..<total).map {
        terminalContinuityAgent(
            $0,
            health: $0 < lethalCount
                ? (($0 >= (delayedLethalStart ?? Int.max)) ? 20 : 10)
                : 100,
            lethal: $0 < lethalCount
        )
    }
    if reverseInput { agents.reverse() }
    var session = try AgentSimulationSession(
        configuration: AgentSessionConfiguration(
            seed: 46,
            memoryPolicy: .bounded(maxEntries: 64)
        ),
        agents: agents,
        simulationID: AgentSimulationID(validating: simulationID),
        causalLedgerPolicy: .bounded(maxEvents: causalEvents)
    )
    session.setSurvivalEnabled(true)
    let population = try AgentPopulationConfiguration(
        maximumActivePopulation: max(3, total)
    )
    try session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: -2, y: 64, z: 0),
        configuration: population
    )
    try session.setMortalityEnabled(
        true,
        configuration: .embodiedPopulationBounded(
            maximumActivePopulation: population.maximumActivePopulation
        )
    )
    return session
}

private func resolveTerminalContinuityCohort(
    _ session: inout AgentSimulationSession
) throws {
    for pending in session.pendingMortalityTransitions() {
        _ = try session.applyMortalityPhysicalCustodyOutcome(
            AgentMortalityPhysicalCustodyOutcome(
                operationID: "ps01-empty-\(pending.agentID.rawValue)-t\(session.tick)",
                terminalAgentID: pending.agentID,
                kind: .verifiedEmpty,
                physicalReceiptID:
                    "ps01-empty-receipt-\(pending.agentID.rawValue)-t\(session.tick)",
                destinationHolderID: nil,
                stackCount: 0,
                itemCount: 0,
                verifiedAtTick: session.tick
            )
        )
        _ = try session.finalizePendingMortality(for: pending.agentID)
    }
}

private func normalTerminalContinuitySession(
    count: Int,
    seed: UInt32,
    simulationID: String
) throws -> AgentSimulationSession {
    let population = try AgentPopulationConfiguration(
        maximumActivePopulation: 30
    )
    let specification = try AgentFounderSpecification(
        count: count,
        populationConfiguration: population
    )
    let positions = Dictionary(uniqueKeysWithValues:
        specification.agentIDs.enumerated().map { offset, id in
            (
                id,
                AgentPosition(
                    x: (offset % 6) * 2,
                    y: 64,
                    z: (offset / 6) * 2
                )
            )
        }
    )
    var session = try AgentSimulationSession(
        configuration: AgentSessionConfiguration(
            seed: seed,
            memoryPolicy: .bounded(maxEntries: 128)
        ),
        agents: specification.initialStates(positionsByAgentID: positions),
        simulationID: AgentSimulationID(validating: simulationID),
        causalLedgerPolicy: .bounded(maxEvents: 8_192)
    )
    try session.initializeFounderAuthorities(
        specification: specification,
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: -2, y: 64, z: 0),
        populationConfiguration: population,
        householdConfiguration: AgentHouseholdConfiguration(
            maximumHouseholdTransitionsPerTick: 30
        )
    )
    return session
}

func runPebbleAgentsTerminalPopulationContinuitySmoke() {
    section("PS01 Increment 02 terminal population continuity")

    let populationBound = try! AgentMortalityConfiguration
        .embodiedPopulationBounded(maximumActivePopulation: 30)
    check("terminal cohort bound derives from population authority",
          AgentMortalityConfiguration.live.maximumDeathsPerTick == 8
            && populationBound.maximumDeathsPerTick == 30
            && populationBound.requiresTerminalPhysicalCustodyVerification)
    check("terminal cohort bound rejects non-population capacity", {
        do {
            _ = try AgentMortalityConfiguration
                .embodiedPopulationBounded(maximumActivePopulation: 2)
            return false
        } catch AgentMortalityError.invalidConfiguration(
            "population-bounded deaths per tick"
        ) {
            return true
        } catch {
            return false
        }
    }())

    for cohort in [1, 8, 9, 20, 24, 30] {
        let total = max(3, cohort)
        var session = try! terminalContinuitySession(
            simulationID: "ps01-terminal-cohort-\(cohort)",
            total: total,
            lethalCount: cohort
        )
        let beforeActions = Dictionary(uniqueKeysWithValues:
            session.snapshot().agents.map { ($0.id, $0.actionCount) }
        )
        let terminalTick = try! session.advanceTick(perceptions:
            cohort == 1
                ? session.snapshot().agents.map {
                    AgentPerceptionInput(
                        agentId: $0.id,
                        observationCountIncrement: 1
                    )
                }
                : []
        )
        let pending = session.pendingMortalityTransitions()
        let pendingIDs = pending.map(\.agentID.rawValue)
        check("\(cohort) lethal actors stage as one terminal cohort",
              terminalTick.tick == 1 && terminalTick.agents.isEmpty
                && pending.count == cohort
                && pendingIDs == pendingIDs.sorted()
                && Set(pending.map(\.detectedAtTick)) == [1])
        check("\(cohort) terminal actors receive no post-boundary cognition",
              pending.allSatisfy {
                  (try? session.state(for: $0.agentID).actionCount)
                    == beforeActions[$0.agentID.rawValue]
              })
        if cohort == 1 {
            check("terminal boundary accepts perception only for survivors",
                  session.snapshot().agents.allSatisfy {
                      $0.observationCount == ($0.id == "agent_0" ? 0 : 1)
                  })
        }
        let pendingBytes = try! session.durableStateBytes()
        let pendingRestored = try! AgentSimulationSession.restoring(
            session.makeCheckpoint()
        )
        check("\(cohort) terminal cohort pending state restores exactly",
              try! pendingRestored.durableStateBytes() == pendingBytes)
        try! resolveTerminalContinuityCohort(&session)
        let expectedSurvivors = total - cohort
        let mortality = session.mortalitySnapshot()
        check("\(cohort) terminal cohort finalizes exactly once",
              mortality.totalDeathCount == cohort
                && mortality.pendingTransitions.isEmpty
                && Set(mortality.records.map(\.agentID.rawValue)).count
                    == cohort
                && session.populationSummary().memberCount
                    == expectedSurvivors
                && session.snapshot().agents.count == expectedSurvivors)
        let restored = try! AgentSimulationSession.restoring(
            session.makeCheckpoint()
        )
        check("\(cohort) finalized cohort checkpoint cannot resurrect",
              try! restored.durableStateBytes()
                == session.durableStateBytes()
                && restored.populationSummary().memberCount
                    == expectedSurvivors
                && restored.mortalitySnapshot().totalDeathCount == cohort)
        if expectedSurvivors > 0 {
            let survivorTick = try! session.advanceTick()
            check("\(cohort) partial mortality survivors remain cognitive",
                  survivorTick.agents.count == expectedSurvivors
                    && survivorTick.agents.allSatisfy(\.cognitionPerformed))
        }
    }

    var geneticSurvivors = try! terminalContinuitySession(
        simulationID: "ps01-terminal-genetic-survivors",
        total: 3,
        lethalCount: 1
    )
    try! geneticSurvivors.setLifecycleEnabled(true)
    try! geneticSurvivors.setHomeostasisEnabled(true)
    try! geneticSurvivors.setGeneticsEnabled(true)
    while geneticSurvivors.pendingMortalityTransitions().isEmpty,
          geneticSurvivors.tick < 30 {
        _ = try! geneticSurvivors.advanceTick()
    }
    try! resolveTerminalContinuityCohort(&geneticSurvivors)
    let geneticSurvivorSnapshot = geneticSurvivors.geneticsSnapshot()
    check("terminal cohort advances only surviving genetics at publication",
          geneticSurvivorSnapshot.development.filter(\.active).map(\.agentID)
            == [AgentID(rawValue: "agent_1")!, AgentID(rawValue: "agent_2")!]
            && geneticSurvivorSnapshot.development.filter(\.active).allSatisfy {
                $0.lastUpdatedTick == geneticSurvivors.tick
            }
            && geneticSurvivorSnapshot.development.first {
                $0.agentID.rawValue == "agent_0"
            }?.stoppedAtTick == geneticSurvivors.tick)
    check("terminal cohort genetics checkpoint restores without resurrection", {
        do {
            let checkpoint = try geneticSurvivors.makeCheckpoint()
            let restored = try AgentSimulationSession.restoring(checkpoint)
            return checkpoint.schemaVersion == AgentCheckpointSchema.geneticsVersion
                && restored.snapshot().agents.map(\.id) == ["agent_1", "agent_2"]
                && restored.geneticsSnapshot() == geneticSurvivorSnapshot
                && (try? restored.durableStateBytes())
                    == (try? geneticSurvivors.durableStateBytes())
        } catch {
            print("  · genetics terminal checkpoint diagnostic error=\(error)")
            return false
        }
    }())

    func deterministicThirty(_ reverse: Bool) -> AgentSimulationSession {
        var session = try! terminalContinuitySession(
            simulationID: "ps01-terminal-deterministic-30",
            total: 30,
            lethalCount: 30,
            reverseInput: reverse
        )
        _ = try! session.advanceTick()
        try! resolveTerminalContinuityCohort(&session)
        return session
    }
    let ordered = deterministicThirty(false)
    let reversed = deterministicThirty(true)
    check("30 cohort death IDs and causal order are input-order neutral",
          ordered.mortalitySnapshot().records.map(\.deathID)
            == reversed.mortalitySnapshot().records.map(\.deathID)
            && ordered.mortalitySnapshot().records.map(
                \.deathEventID.sequence.rawValue
            ) == reversed.mortalitySnapshot().records.map(
                \.deathEventID.sequence.rawValue
            ))
    check("30 cohort durable bytes are deterministic",
          try! ordered.durableStateBytes()
            == reversed.durableStateBytes())

    var retained = try! terminalContinuitySession(
        simulationID: "ps01-terminal-retention-35",
        total: 35,
        lethalCount: 35,
        causalEvents: 128,
        delayedLethalStart: 5
    )
    // Five agents cross first; the other thirty cross on the next boundary.
    // This attacks full-record, compacted-summary, exit-frame and ledger
    // retention in the same deterministic run.
    _ = try! retained.advanceTick()
    try! resolveTerminalContinuityCohort(&retained)
    _ = try! retained.advanceTick()
    try! resolveTerminalContinuityCohort(&retained)
    let retainedMortality = retained.mortalitySnapshot()
    check("prior history plus 30 cohort compacts mortality evidence honestly",
          retainedMortality.totalDeathCount == 35
            && retainedMortality.records.count == 32
            && retainedMortality.compactedDeathSummaries?.count == 3
            && retainedMortality.exitFrames.count == 32
            && retainedMortality.evictionCounts.deathRecords == 3
            && retainedMortality.evictionCounts.exitFrames == 3
            && retained.causalLedgerSnapshot().summary.droppedEventCount > 0)
    check("compacted extinction restores without resurrection", {
        guard let restored = try? AgentSimulationSession.restoring(
            retained.makeCheckpoint()
        ) else { return false }
        return restored.snapshot().agents.isEmpty
            && restored.populationSummary().memberCount == 0
            && restored.mortalitySnapshot().totalDeathCount == 35
            && (try? restored.durableStateBytes())
                == (try? retained.durableStateBytes())
    }())

    for count in [20, 24, 30] {
        for seed: UInt32 in [46, 887] {
            var normal = try! normalTerminalContinuitySession(
                count: count,
                seed: seed,
                simulationID: "ps01-normal-terminal-\(count)-\(seed)"
            )
            check("normal \(count) seed \(seed) uses population mortality bound",
                  normal.mortalitySnapshot().configuration?
                    .maximumDeathsPerTick == 30)
            var terminalResult: AgentSessionTickResult?
            for _ in 0..<30 where normal.pendingMortalityTransitions().isEmpty {
                terminalResult = try! normal.advanceTick()
            }
            let pending = normal.pendingMortalityTransitions()
            check("normal \(count) seed \(seed) crosses tick 23 without refusal",
                  normal.tick == 23 && pending.count == count
                    && terminalResult?.agents.isEmpty == true
                    && normal.mortalitySnapshot().totalDeathCount == 0)
            try! resolveTerminalContinuityCohort(&normal)
            let finalBytes = try! normal.durableStateBytes()
            let restored = try! AgentSimulationSession.restoring(
                normal.makeCheckpoint()
            )
            let binding = try! AgentObserverWorldBinding(
                worldID: "ps01-world-\(count)-\(seed)",
                storageIdentity: "memory:ps01-\(count)-\(seed)",
                seed: seed,
                dimension: 0,
                observedWorldTick: normal.tick
            )
            let observer = normal.observerSnapshot(worldBinding: binding)
            check("normal \(count) seed \(seed) publishes restorable extinction",
                  normal.snapshot().agents.isEmpty
                    && normal.populationSummary().memberCount == 0
                    && normal.mortalitySnapshot().totalDeathCount == count
                    && restored.snapshot().agents.isEmpty
                    && (try! restored.durableStateBytes()) == finalBytes)
            check("normal \(count) seed \(seed) Observer is honest and read-only",
                  observer.individuals.isEmpty
                    && observer.recentDeaths.count == count
                    && (try! normal.durableStateBytes()) == finalBytes)
        }
    }

    runPebbleAgentsTerminalCohortDependentAuthoritySmoke()
    runPebbleAgentsTerminalCohortWorkSmoke()
    runPebbleAgentsTerminalCohortMigrationSmoke()
    runPebbleAgentsTerminalCohortCommunicationSmoke()
}
