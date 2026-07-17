import Foundation
import PebbleAgents

private func mortalityAgent(
    _ id: String,
    health: Int = 100,
    lethalNextTick: Bool = false
) -> AgentSessionAgentState {
    AgentSessionAgentState(
        id: id,
        state: "idle",
        position: AgentPosition(x: Int(id.suffix(1)) ?? 0, y: 64, z: 0),
        needs: AgentNeeds(
            hunger: lethalNextTick ? 1 : 0,
            fatigue: 0,
            curiosity: 0,
            safety: 1
        ),
        health: health,
        fear: 0,
        homePosition: AgentPosition(x: Int(id.suffix(1)) ?? 0, y: 64, z: 0),
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
        totalDistanceReducedTowardHome: 0,
        survivalProgress: AgentSurvivalProgress(
            status: lethalNextTick ? .starving : .stable,
            consecutiveCriticalHungerTicks: lethalNextTick ? 2 : 0
        )
    )
}

private func mortalitySession(_ simulation: String) -> AgentSimulationSession {
    let configuration = try! AgentSessionConfiguration(
        seed: 46,
        memoryPolicy: .bounded(maxEntries: 64)
    )
    var session = try! AgentSimulationSession(
        configuration: configuration,
        agents: [
            mortalityAgent("agent_0", health: 10, lethalNextTick: true),
            mortalityAgent("agent_1"),
            mortalityAgent("agent_2"),
        ],
        simulationID: try! AgentSimulationID(validating: simulation),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
    session.setSurvivalEnabled(true)
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 0)
    )
    try! session.setMortalityEnabled(true)
    return session
}

func runPebbleAgentsMortalityPopulationExitSmoke() {
    section("pebble agents mortality and population exit")

    let live = AgentMortalityConfiguration.live
    check("mortality configuration defaults", live.maximumDeathsPerTick == 8
        && live.maximumRetainedDeathRecords == 32
        && live.maximumFinalMemoryEntries == 8
        && live.maximumCancelledCommitmentIDsPerDeath == 32
        && live.maximumExitFrames == 32)
    check("mortality rejects zero deaths per tick", {
        do {
            _ = try AgentMortalityConfiguration(maximumDeathsPerTick: 0)
            return false
        } catch AgentMortalityError.invalidConfiguration("deaths per tick") {
            return true
        } catch { return false }
    }())
    check("mortality rejects oversized death history", {
        do {
            _ = try AgentMortalityConfiguration(maximumRetainedDeathRecords: 65)
            return false
        } catch AgentMortalityError.invalidConfiguration("death records") {
            return true
        } catch { return false }
    }())
    check("mortality accepts zero final memories", (try? AgentMortalityConfiguration(
        maximumFinalMemoryEntries: 0
    )) != nil)
    check("mortality rejects oversized final memories", (try? AgentMortalityConfiguration(
        maximumFinalMemoryEntries: 17
    )) == nil)
    check("mortality accepts zero commitment IDs", (try? AgentMortalityConfiguration(
        maximumCancelledCommitmentIDsPerDeath: 0
    )) != nil)
    check("mortality rejects oversized exit history", (try? AgentMortalityConfiguration(
        maximumExitFrames: 65
    )) == nil)
    check("mortality configuration Codable", {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let bytes = try? encoder.encode(live),
              let decoded = try? JSONDecoder().decode(
                  AgentMortalityConfiguration.self,
                  from: bytes
              ) else { return false }
        return decoded == live
    }())
    check("mortality cause V1 is starvation only", AgentMortalityCause.allCases == [.starvation])
    check("death ID validates canonical form", AgentDeathID(
        rawValue: "death-agent_3-t33-0123456789abcdef"
    ) != nil)
    check("death ID rejects path punctuation", AgentDeathID(rawValue: "death/agent_3") == nil)

    let historical = AgentResourceConservationSnapshot(
        harvested: [AgentResourceAmount(resource: .wood, quantity: 2)],
        carried: [AgentResourceAmount(resource: .wood, quantity: 2)],
        campStock: []
    )
    check("mortality-off conservation remains exact", historical.balanced
        && historical.unrecoveredAtDeathTotal == 0)
    let terminal = AgentResourceConservationSnapshot(
        harvested: [AgentResourceAmount(resource: .wood, quantity: 2)],
        carried: [],
        campStock: [],
        unrecoveredAtDeath: [AgentResourceAmount(resource: .wood, quantity: 2)]
    )
    check("mortality terminal custody conserves resources", terminal.balanced
        && terminal.unrecoveredAtDeathTotal == 2)
    check("mortality terminal custody cannot hide duplication", !AgentResourceConservationSnapshot(
        harvested: [AgentResourceAmount(resource: .wood, quantity: 2)],
        carried: [AgentResourceAmount(resource: .wood, quantity: 1)],
        campStock: [],
        unrecoveredAtDeath: [AgentResourceAmount(resource: .wood, quantity: 2)]
    ).balanced)

    var activationRefusal = mortalitySession("sim-mortality-activation-refusal")
    try! activationRefusal.setMortalityEnabled(false)
    let invalidConfiguration = try! AgentSessionConfiguration(
        seed: 46,
        memoryPolicy: .bounded(maxEntries: 64)
    )
    var invalidSession = try! AgentSimulationSession(
        configuration: invalidConfiguration,
        agents: [
            mortalityAgent("agent_0", health: 0, lethalNextTick: true),
            mortalityAgent("agent_1"),
            mortalityAgent("agent_2"),
        ],
        simulationID: try! AgentSimulationID(validating: "sim-mortality-invalid-health"),
        causalLedgerPolicy: .bounded(maxEvents: 128)
    )
    invalidSession.setSurvivalEnabled(true)
    try! invalidSession.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 0)
    )
    let invalidBefore = try! invalidSession.durableStateBytes()
    check("mortality activation rejects zero health", {
        do {
            try invalidSession.setMortalityEnabled(true)
            return false
        } catch AgentSessionError.mortality(.nonLivingAgent("agent_0")) {
            return true
        } catch { return false }
    }())
    check("mortality activation refusal atomic", invalidBefore
        == (try! invalidSession.durableStateBytes()))

    var session = mortalitySession("sim-mortality-lethal")
    let result = try! session.advanceTick()
    let mortality = session.mortalitySnapshot()
    let record = mortality.records.first
    check("mortality lethal health reaches zero", record?.healthBeforeLethalDamage == 10
        && record?.finalHealth == 0)
    check("mortality starvation cause", record?.cause == .starvation)
    check("mortality death tick exact", record?.deathTick == 1)
    check("mortality removes active state", session.snapshot().agents.map(\.id)
        == ["agent_1", "agent_2"])
    check("mortality population exits three to two", session.populationSummary().memberCount == 2
        && mortality.exitFrames.first?.populationBefore == 3
        && mortality.exitFrames.first?.populationAfter == 2)
    check("mortality lethal agent has no terminal result", !result.agents.contains {
        $0.agentId == "agent_0"
    })
    check("mortality survivors retain cognition", result.agents.map(\.agentId)
        == ["agent_1", "agent_2"])
    check("mortality death record has lethal memory", record?.finalMemory.last?.type
        == "starvation_damage")
    check("mortality empty inventory remains conserved", session.conservationSnapshot().balanced
        && mortality.unrecoveredAtDeath.isEmpty)
    check("mortality active IDs equal population members", session.expectedActiveAgentIDs()
        == session.populationSnapshot().members.map(\.agentID))
    check("mortality cannot disable after death", {
        do {
            try session.setMortalityEnabled(false)
            return false
        } catch AgentSessionError.mortality(.unsafeDisable) {
            return true
        } catch { return false }
    }())

    var checkpointSource = mortalitySession("sim-mortality-checkpoint")
    let preDeathCheckpoint = try! checkpointSource.makeCheckpoint()
    check("mortality checkpoint uses v5", preDeathCheckpoint.schemaVersion == 5)
    let preDeathBytes = try! checkpointSource.durableStateBytes()
    let preDeathRestored = try! AgentSimulationSession.restoring(preDeathCheckpoint)
    check("mortality pre-death restore exact", preDeathBytes
        == (try! preDeathRestored.durableStateBytes()))
    var recorder = try! AgentReplayRecorder(
        checkpoint: preDeathCheckpoint,
        session: checkpointSource
    )
    _ = try! recorder.apply(
        .advanceTick(perceptions: [], physicalObservations: []),
        to: &checkpointSource
    )
    let postDeathBytes = try! checkpointSource.durableStateBytes()
    let postDeathCheckpoint = try! checkpointSource.makeCheckpoint()
    check("mortality post-death checkpoint uses v5", postDeathCheckpoint.schemaVersion == 5)
    let postDeathRestored = try! AgentSimulationSession.restoring(postDeathCheckpoint)
    check("mortality post-death restore exact", postDeathBytes
        == (try! postDeathRestored.durableStateBytes()))
    check("mortality restore does not resurrect", postDeathRestored.expectedActiveAgentIDs()
        .map(\.rawValue) == ["agent_1", "agent_2"])
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "mortality-lethal")!
    )
    let replay = try! AgentSessionReplayer.replay(
        checkpoint: preDeathCheckpoint,
        journal: journal
    )
    check("mortality replay schema v5", journal.manifest.schemaVersion == 5)
    check("mortality replay verifies lethal tick", replay.report.verified)
    check("mortality replay exact post-death bytes", postDeathBytes
        == (try! replay.session.durableStateBytes()))

    var resources = mortalitySession("sim-mortality-resources")
    try! resources.applyInteractionOutcome(AgentInteractionOutcome(
        interactionId: "mortality-wood",
        agentId: "agent_0",
        tick: 0,
        target: AgentPosition(x: 0, y: 64, z: 1),
        resource: .wood,
        status: .succeeded,
        inventoryDelta: AgentInventoryDelta(resource: .wood, quantity: 1),
        reason: "authoritative fixture harvest"
    ))
    try! resources.applyInteractionOutcome(AgentInteractionOutcome(
        interactionId: "mortality-stone",
        agentId: "agent_0",
        tick: 0,
        target: AgentPosition(x: 0, y: 64, z: -1),
        resource: .stone,
        status: .succeeded,
        inventoryDelta: AgentInventoryDelta(resource: .stone, quantity: 1),
        reason: "authoritative fixture harvest"
    ))
    _ = try! resources.advanceTick()
    let resourceDeath = resources.mortalitySnapshot()
    check("mortality retires multiple carried resources", resourceDeath.records.first?
        .carriedInventory == [
            AgentResourceAmount(resource: .wood, quantity: 1),
            AgentResourceAmount(resource: .stone, quantity: 1),
        ])
    check("mortality terminal custody exact", resourceDeath.unrecoveredAtDeath == [
        AgentResourceAmount(resource: .wood, quantity: 1),
        AgentResourceAmount(resource: .stone, quantity: 1),
    ])
    check("mortality resource transfer conserved", resources.conservationSnapshot().balanced
        && resources.conservationSnapshot().carriedTotal == 0
        && resources.conservationSnapshot().unrecoveredAtDeathTotal == 2)

    func simultaneous(
        _ reversed: Bool,
        mortalityConfiguration: AgentMortalityConfiguration = .live
    ) -> AgentSimulationSession {
        let config = try! AgentSessionConfiguration(
            seed: 46,
            memoryPolicy: .bounded(maxEntries: 64)
        )
        var agents = [
            mortalityAgent("agent_0", health: 10, lethalNextTick: true),
            mortalityAgent("agent_1", health: 10, lethalNextTick: true),
            mortalityAgent("agent_2", health: 10, lethalNextTick: true),
        ]
        if reversed { agents.reverse() }
        var value = try! AgentSimulationSession(
            configuration: config,
            agents: agents,
            simulationID: try! AgentSimulationID(validating: "sim-mortality-simultaneous"),
            causalLedgerPolicy: .bounded(maxEvents: 4096)
        )
        value.setSurvivalEnabled(true)
        try! value.initializePopulationRegistry(
            settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
            receptionPosition: AgentPosition(x: 0, y: 64, z: 0)
        )
        try! value.setMortalityEnabled(true, configuration: mortalityConfiguration)
        _ = try! value.advanceTick()
        return value
    }
    var simultaneousA = simultaneous(false)
    let simultaneousB = simultaneous(true)
    check("mortality simultaneous deaths sorted", simultaneousA.mortalitySnapshot()
        .records.map(\.agentID.rawValue) == ["agent_0", "agent_1", "agent_2"])
    check("mortality simultaneous input order neutral", (try! simultaneousA.durableStateBytes())
        == (try! simultaneousB.durableStateBytes()))
    check("mortality zero active snapshot safe", simultaneousA.snapshot().agents.isEmpty
        && simultaneousA.populationSummary().memberCount == 0)
    let emptyTick = try! simultaneousA.advanceTick()
    check("mortality zero active tick safe", emptyTick.tick == 2 && emptyTick.agents.isEmpty)

    let boundedMortality = try! AgentMortalityConfiguration(
        maximumRetainedDeathRecords: 1,
        maximumExitFrames: 1
    )
    let evicted = simultaneous(false, mortalityConfiguration: boundedMortality)
    let evictedSnapshot = evicted.mortalitySnapshot()
    check("mortality death record eviction deterministic", evictedSnapshot.totalDeathCount == 3
        && evictedSnapshot.records.map(\.agentID.rawValue) == ["agent_2"]
        && evictedSnapshot.evictionCounts.deathRecords == 2)
    check("mortality processed IDs match retained records", evictedSnapshot.processedDeathIDs
        == evictedSnapshot.records.map(\.deathID))
    check("mortality exit frame eviction deterministic", evictedSnapshot.exitFrames
        .map(\.agentID.rawValue) == ["agent_2"]
        && evictedSnapshot.evictionCounts.exitFrames == 2)
    check("mortality bounded checkpoint restores exact", {
        guard let restored = try? AgentSimulationSession.restoring(evicted.makeCheckpoint()) else {
            return false
        }
        return (try? evicted.durableStateBytes()) == (try? restored.durableStateBytes())
    }())

    var transitioningMetrics = mortalitySession("sim-mortality-metrics-transition")
    try! transitioningMetrics.setSettlementMetricsEnabled(true)
    for _ in 0..<4 { _ = try! transitioningMetrics.advanceTick() }
    let mortalityFrame = try! transitioningMetrics.applySettlementMetricsPulseIfDue()
    check("mortality settlement transition classified", mortalityFrame?.condition
        == .transitioning && mortalityFrame?.reasonCode == "population_changed")
    check("mortality settlement death and exit delta", mortalityFrame?.mortality?.deathDelta == 1
        && mortalityFrame?.mortality?.exitDelta == 1
        && mortalityFrame?.populationEventDelta == 1)
    check("mortality settlement population reduced", mortalityFrame?.population.members == 2
        && mortalityFrame?.mortality?.totalDeathCount == 1)

    var zeroMetrics = simultaneous(false)
    try! zeroMetrics.setSettlementMetricsEnabled(true)
    for _ in 0..<4 { _ = try! zeroMetrics.advanceTick() }
    let zeroFrame = try! zeroMetrics.applySettlementMetricsPulseIfDue()
    check("mortality zero active settlement pulse safe", zeroFrame?.population.members == 0
        && zeroFrame?.condition == .stable)

    let migrationConfiguration = try! AgentSessionConfiguration(
        seed: 46,
        memoryPolicy: .bounded(maxEntries: 128)
    )
    var migration = try! AgentSimulationSession(
        configuration: migrationConfiguration,
        agents: [
            mortalityAgent("agent_0"),
            mortalityAgent("agent_1"),
            mortalityAgent("agent_2"),
        ],
        simulationID: try! AgentSimulationID(validating: "sim-mortality-migrant"),
        causalLedgerPolicy: .bounded(maxEvents: 8192)
    )
    migration.setSurvivalEnabled(true)
    try! migration.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3)
    )
    try! migration.setMortalityEnabled(true)
    for index in 0..<3 {
        try! migration.applyInteractionOutcome(AgentInteractionOutcome(
            interactionId: "founder-food-\(index)",
            agentId: "agent_\(index)",
            tick: 0,
            target: AgentPosition(x: index, y: 64, z: 1),
            resource: .foodRaw,
            status: .succeeded,
            inventoryDelta: AgentInventoryDelta(resource: .foodRaw, quantity: 1),
            reason: "authoritative fixture harvest"
        ))
    }
    let route = [4, 3, 2, 1, 0].map { AgentPosition(x: $0, y: 64, z: 3) }
    _ = try! migration.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: AgentMigrationWorldObservation(
            worldTick: 0,
            candidateIndex: 0,
            entryPosition: route[0],
            receptionPosition: route.last!,
            route: route
        )
    )
    for step in 1...27 {
        _ = try! migration.advanceTick()
        if step == 16 {
            for index in 0..<3 {
                let id = "agent_\(index)"
                let state = try! migration.state(for: id)
                try! migration.applyConsumptionOutcome(AgentConsumptionOutcome(
                    consumptionId: "founder-consume-\(index)",
                    agentId: id,
                    tick: migration.tick,
                    resource: .foodRaw,
                    quantity: 1,
                    status: .succeeded,
                    hungerBefore: state.needs.hunger,
                    hungerAfter: 0,
                    reason: "one carried foodRaw consumed atomically"
                ))
            }
        }
    }
    let failedMigration = migration.migrationSnapshot().migrations.first
    check("mortality migrant exit typed member died", failedMigration?.status == .failed
        && failedMigration?.failure == .memberDied)
    check("mortality migrant removed without arrival", migration.expectedActiveAgentIDs()
        .map(\.rawValue) == ["agent_0", "agent_1", "agent_2"]
        && migration.populationSnapshot().settlement?.inTransitIDs.isEmpty == true)
    let replacement = try! migration.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: AgentMigrationWorldObservation(
            worldTick: migration.tick,
            candidateIndex: 0,
            entryPosition: route[0],
            receptionPosition: route.last!,
            route: route
        )
    )
    check("mortality replacement is agent four", replacement.migrantID.rawValue == "agent_4")
    check("mortality replacement ordinal monotone", migration.populationSummary()
        .nextPopulationOrdinal == 5 && !migration.expectedActiveAgentIDs().map(\.rawValue)
        .contains("agent_3"))
}
