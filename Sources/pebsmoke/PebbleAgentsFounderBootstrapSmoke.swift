import Foundation
@_spi(Testing) import PebbleAgents

private func founderSpecification(_ count: Int = 24) throws -> AgentFounderSpecification {
    try AgentFounderSpecification(count: count, populationConfiguration: AgentPopulationConfiguration(maximumActivePopulation: 30))
}

private func founderCandidate(_ count: Int, ledger: Int = 8192) throws -> AgentSimulationSession {
    let spec = try founderSpecification(count)
    let positions = Dictionary(uniqueKeysWithValues: spec.agentIDs.enumerated().map {
        ($0.element, AgentPosition(x: $0.offset % 6 * 2, y: 64, z: $0.offset / 6 * 2))
    })
    return try AgentSimulationSession(
        configuration: AgentSessionConfiguration(seed: 46, memoryPolicy: .bounded(maxEntries: 128)),
        agents: spec.initialStates(positionsByAgentID: positions),
        simulationID: AgentSimulationID(validating: "normal-founders-46"),
        causalLedgerPolicy: .bounded(maxEvents: ledger)
    )
}

private func initializeFounders(_ session: inout AgentSimulationSession, count: Int) throws {
    try session.initializeFounderAuthorities(
        specification: founderSpecification(count),
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: -2, y: 64, z: 0),
        populationConfiguration: AgentPopulationConfiguration(maximumActivePopulation: 30),
        householdConfiguration: AgentHouseholdConfiguration(maximumHouseholdTransitionsPerTick: 30)
    )
}

func runPebbleAgentsFounderBootstrapSmoke() {
    print("\n--- Normal founder bootstrap ---")
    for count in [-1, 0, 31, 128, Int.max] {
        do {
            _ = try founderSpecification(count)
            check("founder count \(count) refused", false)
        } catch { check("founder count \(count) refused", true) }
    }
    do {
        check("PS01 range is not universal population law", try founderSpecification(19).count == 19)
        for count in [20, 24, 30] {
            var session = try founderCandidate(count)
            try initializeFounders(&session, count: count)
            let ids = try founderSpecification(count).agentIDs.sorted()
            let bytes = try session.durableStateBytes()
            let population = session.populationSnapshot()
            let storedPersons = session.durableState().kinshipState?.historicalPersons ?? []
            check("\(count) canonical stored person ordering and independent ordinals", storedPersons.map(\.agentID.rawValue) == ids
                && storedPersons.allSatisfy { $0.agentID.rawValue == "agent_\($0.ordinal.rawValue)" })
            check("\(count) exact founder population and ordinal", population.members.map(\.agentID.rawValue) == ids
                && population.members.allSatisfy { $0.founder && $0.agentID.rawValue == "agent_\($0.ordinal.rawValue)" }
                && population.nextPopulationOrdinal == count)
            check("\(count) lifecycle and kinship identity", session.lifecycleSnapshot().members.map(\.agentID.rawValue) == ids
                && session.kinshipSnapshot().historicalPersons.map(\.agentID.rawValue).sorted() == ids)
            check("\(count) genetics and physiology identity", session.geneticsSnapshot().genotypes.map(\.agentID.rawValue).sorted() == ids
                && session.homeostasisSnapshot().profiles.map(\.agentID.rawValue).sorted() == ids)
            check("\(count) singleton household membership", session.householdSnapshot().currentMemberships.map(\.agentID.rawValue) == ids
                && session.householdSnapshot().households.count == count)
            check("\(count) no seeded family or births", session.familySnapshot().unions.isEmpty
                && session.familySnapshot().houses.isEmpty && session.lifecycleSnapshot().births.isEmpty
                && session.kinshipSnapshot().parentageRecords.isEmpty)
            check("\(count) no reduced fidelity", !session.populationScalingEnabled)
            let checkpoint = try session.makeCheckpoint()
            let encoded = try AgentCheckpointCodec.encode(checkpoint)
            let decoded = try AgentCheckpointCodec.decode(AgentSessionCheckpoint.self, from: encoded)
            let restored = try AgentSimulationSession.restoring(decoded)
            check("\(count) checkpoint exact bytes and probe IDs", try restored.durableStateBytes() == bytes
                && restored.expectedActiveAgentIDs().map(\.rawValue).sorted() == ids)
            var repeated = try founderCandidate(count)
            try initializeFounders(&repeated, count: count)
            check("\(count) repeated initialization exact", try repeated.durableStateBytes() == bytes)
            let binding = try AgentObserverWorldBinding(worldID: "founder-world", storageIdentity: "founder-world", seed: 46, dimension: 0, observedWorldTick: 0)
            let observer = session.observerSnapshot(worldBinding: binding)
            let limited = session.observerSnapshot(worldBinding: binding, configuration: try AgentObserverConfiguration(maximumAgents: 4))
            check("\(count) Observer founder set and explicit truncation", observer.individuals.map(\.agentID.rawValue) == ids
                && observer.truncation.agentsOmitted == 0 && limited.individuals.count == 4
                && limited.truncation.agentsOmitted == count - 4 && limited.truncation.isTruncated)
            check("\(count) Observer read only", try session.durableStateBytes() == bytes)
            if let directory = ProcessInfo.processInfo.environment["PEBBLELAB_FOUNDER_EVIDENCE_DIR"] {
                let root = URL(fileURLWithPath: directory)
                try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
                try encoded.write(to: root.appendingPathComponent("founders-\(count)-checkpoint.json"))
                try AgentCheckpointCodec.encode(observer).write(to: root.appendingPathComponent("founders-\(count)-observer.json"))
                try AgentCheckpointCodec.encode(restored.expectedActiveAgentIDs()).write(to: root.appendingPathComponent("founders-\(count)-restored-probe-ids.json"))
            }
            var fullCognition = true
            for _ in 0..<4 {
                let result = try session.advanceTick()
                fullCognition = fullCognition && result.agents.count == count
                    && result.agents.allSatisfy(\.cognitionPerformed)
            }
            check("\(count) every founder gets every cognition tick", fullCognition)
        }
        for stage in AgentFounderInitializationStage.allCases {
            var candidate = try founderCandidate(24)
            let before = try candidate.durableStateBytes()
            do {
                try candidate.initializeFounderAuthorities(
                    specification: founderSpecification(),
                    settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
                    receptionPosition: AgentPosition(x: -2, y: 64, z: 0),
                    populationConfiguration: AgentPopulationConfiguration(maximumActivePopulation: 30),
                    householdConfiguration: AgentHouseholdConfiguration(maximumHouseholdTransitionsPerTick: 30),
                    failAfter: stage
                )
                check("late \(stage.rawValue) failure atomically refused", false)
            } catch {
                check("late \(stage.rawValue) failure atomically refused", try candidate.durableStateBytes() == before
                    && !candidate.populationEnabled && String(describing: error).contains("after \(stage.rawValue)"))
                print("FOUNDERS_ATTACK stage=\(stage.rawValue) rollback=exact error=\(error)")
            }
        }
        for attack in ["population-capacity", "household-transitions", "household-history", "late-dependency", "causal-capacity"] {
            var candidate = try founderCandidate(24, ledger: attack == "causal-capacity" ? 24 : 8192)
            let before = try candidate.durableStateBytes()
            do {
                try candidate.initializeFounderAuthorities(
                    specification: founderSpecification(),
                    settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
                    receptionPosition: AgentPosition(x: -2, y: 64, z: 0),
                    childhood: attack != "late-dependency",
                    populationConfiguration: try AgentPopulationConfiguration(maximumActivePopulation: attack == "population-capacity" ? 23 : 30),
                    householdConfiguration: try AgentHouseholdConfiguration(
                        maximumHistoricalHouseholds: attack == "household-history" ? 23 : 256,
                        maximumActiveHouseholds: attack == "household-history" ? 23 : 64,
                        maximumHouseholdTransitionsPerTick: attack == "household-transitions" ? 16 : 30)
                )
                check("\(attack) refuses atomically", false)
            } catch {
                check("\(attack) refuses atomically", try candidate.durableStateBytes() == before && !candidate.populationEnabled)
                print("FOUNDERS_ATTACK \(attack) rollback=exact error=\(error)")
            }
        }
        let original = try founderCandidate(24)
        var noncanonical = try AgentSimulationSession(
            configuration: original.configuration,
            agents: Array(original.durableState().agents.dropFirst()),
            causalLedgerPolicy: .bounded(maxEvents: 8192)
        )
        let noncanonicalBefore = try noncanonical.durableStateBytes()
        do {
            try noncanonical.initializePopulationRegistry(
                settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
                receptionPosition: AgentPosition(x: -2, y: 64, z: 0),
                configuration: AgentPopulationConfiguration(maximumActivePopulation: 30)
            )
            check("noncontiguous deterministic IDs refused", false)
        } catch { check("noncontiguous deterministic IDs refused", try noncanonical.durableStateBytes() == noncanonicalBefore) }
        var reordered = try AgentSimulationSession(
            configuration: original.configuration, agents: original.durableState().agents.reversed(),
            simulationID: original.simulationID, causalLedgerPolicy: .bounded(maxEvents: 8192)
        )
        var ordered = original
        try initializeFounders(&ordered, count: 24)
        try initializeFounders(&reordered, count: 24)
        check("reversed source order retains canonical bytes", try ordered.durableStateBytes() == reordered.durableStateBytes())
        var minimal = original
        try minimal.initializeFounderAuthorities(
            specification: founderSpecification(),
            settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
            receptionPosition: AgentPosition(x: -2, y: 64, z: 0),
            lifecycle: false, kinship: false, households: false, dependentCare: false,
            childhood: false, family: false, mortality: false, homeostasis: false, genetics: false,
            populationConfiguration: AgentPopulationConfiguration(maximumActivePopulation: 30)
        )
        check("disabled dependent domains stay disabled", minimal.populationSummary().founderCount == 24
            && !minimal.lifecycleEnabled && !minimal.geneticsEnabled && !minimal.householdsEnabled)
        var states = original.durableState().agents
        states[1] = states[0]
        do {
            _ = try AgentSimulationSession(configuration: original.configuration, agents: states)
            check("duplicate identity refused", false)
        } catch { check("duplicate identity refused", true) }
        let spec = try founderSpecification()
        do {
            _ = try spec.initialStates(positionsByAgentID: [:])
            check("missing placements refused", false)
        } catch { check("missing placements refused", true) }
        let overlap = Dictionary(uniqueKeysWithValues: spec.agentIDs.map { ($0, AgentPosition(x: 0, y: 64, z: 0)) })
        do {
            _ = try spec.initialStates(positionsByAgentID: overlap)
            check("overlapping placements refused", false)
        } catch { check("overlapping placements refused", true) }
        var legacy = try AgentSimulationSession(configuration: original.configuration, agents: Array(original.durableState().agents.filter { ["agent_0", "agent_1", "agent_2"].contains($0.id) }), causalLedgerPolicy: .bounded(maxEvents: 8192))
        try legacy.initializePopulationRegistry(settlementAnchor: AgentPosition(x: 0, y: 64, z: 0), receptionPosition: AgentPosition(x: -2, y: 64, z: 0))
        check("legacy three founder registry retained", legacy.populationSnapshot().nextPopulationOrdinal == 3 && legacy.populationSnapshot().members.count == 3)
    } catch { check("founder campaign unexpected error: \(error)", false) }
}
