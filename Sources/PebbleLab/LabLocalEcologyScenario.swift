import Foundation
import PebbleAgents

private struct EcologyScenarioCheck: Codable, Equatable {
    let name: String
    let passed: Bool
    let detail: String
}

private struct EcologyScenarioReport: Encodable {
    let schemaVersion = 4
    let scenario: String
    let seed: UInt32
    let success: Bool
    let checks: [EcologyScenarioCheck]
}

private struct EcologyScenarioSummary: Encodable {
    let schemaVersion = 4
    let scenario: String
    let seed: UInt32
    let simulationID: String
    let population: Int
    let residents: Int
    let patchIDs: [String]
    let initialYield: Int
    let harvested: Int
    let regenerated: Int
    let starvationDamage: Int
    let checkpointSchema: Int
    let checkpointTick: Int
    let replaySchema: Int
    let replayRecords: Int
    let finalPressure: String
    let finalCausalSequence: UInt64
    let causalDigest: String
    let durableDigest: String
    let ecologyDigest: String
    let ecologyBalanced: Bool
    let materialBalanced: Bool
    let worldMutationCount: Int
}

private struct EcologyScenarioDigests: Encodable {
    let durable: String
    let ecology: String
    let causal: String
    let checkpoint: String
    let replay: String
}

private let ecologyAnchor = AgentPosition(x: 0, y: 64, z: 0)
private let ecologyReception = AgentPosition(x: 0, y: 64, z: 3)
private let ecologyRoute = [4, 3, 2, 1, 0].map { AgentPosition(x: $0, y: 64, z: 3) }
private let ecologyHabitatA = AgentPosition(x: 1, y: 63, z: 0)
private let ecologyForageA = AgentPosition(x: 1, y: 64, z: 0)
private let ecologyHabitatB = AgentPosition(x: 3, y: 63, z: 0)
private let ecologyForageB = AgentPosition(x: 3, y: 64, z: 0)

private func ecologyScenarioAgent(_ id: String, x: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id,
        state: "idle",
        position: position,
        needs: AgentNeeds(hunger: 0.45, fatigue: 0, curiosity: 0.1, safety: 1),
        health: 100,
        fear: 0,
        homePosition: position,
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
}

private func ecologyScenarioSession(seed: UInt32) -> AgentSimulationSession {
    let configuration = try! AgentSessionConfiguration(
        seed: seed,
        nearbyRadius: 8,
        resourceObservationRadius: 8,
        recentMemorySnapshotLimit: 16,
        memoryPolicy: .bounded(maxEntries: 128)
    )
    var session = try! AgentSimulationSession(
        configuration: configuration,
        agents: [
            ecologyScenarioAgent("agent_0", x: 0),
            ecologyScenarioAgent("agent_1", x: 2),
            ecologyScenarioAgent("agent_2", x: 20),
        ],
        simulationID: try! AgentSimulationID(validating: "local-ecology-subsistence-\(seed)"),
        causalLedgerPolicy: .bounded(maxEvents: 8192)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: ecologyAnchor,
        receptionPosition: ecologyReception
    )
    _ = try! session.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: AgentMigrationWorldObservation(
            worldTick: 0,
            candidateIndex: 0,
            entryPosition: ecologyRoute[0],
            receptionPosition: ecologyReception,
            route: ecologyRoute
        )
    )
    for _ in 0..<4 {
        let migrant = session.snapshot().agents.first { $0.id == "agent_3" }!
        _ = try! session.advanceTick(perceptions: [ecologyMigrationPerception(
            position: migrant.position,
            tick: session.tick + 1
        )])
        try! session.applyMovementOutcomes(AgentMovementCoordinator.resolve(snapshot: session.snapshot()))
    }
    session.setSurvivalEnabled(true)
    session.setEconomyEnabled(true)
    return session
}

private func ecologyMigrationPerception(
    position: AgentPosition,
    tick: Int
) -> AgentPerceptionInput {
    func column(_ position: AgentPosition) -> AgentWorldColumnObservation {
        AgentWorldColumnObservation(
            position: position,
            chunkReady: true,
            surfaceY: position.y,
            height: position.y,
            blockBelow: 1,
            blockAtFeet: 0,
            blockAtHead: 0,
            groundPresent: true,
            feetClear: true,
            headClear: true
        )
    }
    let neighbors = AgentCardinalDirection.allCases.map { direction -> AgentWorldNeighborObservation in
        let target = AgentPosition(
            x: position.x + direction.dx,
            y: position.y,
            z: position.z + direction.dz
        )
        return AgentWorldNeighborObservation(
            direction: direction,
            column: column(target),
            stepDelta: 0,
            traversable: true,
            dangerousDrop: false
        )
    }
    let world = try! AgentWorldObservation(
        worldTick: tick,
        position: position,
        center: column(position),
        neighbors: neighbors,
        biomeId: 1,
        biomeName: "plains",
        combinedLight: 15,
        skyLight: 15,
        blockLight: 0,
        dayTime: 6000,
        raining: false,
        thundering: false
    )
    return AgentPerceptionInput(
        agentId: "agent_3",
        worldObservation: world,
        navigationObservation: AgentNavigationObservation(
            worldTick: tick,
            origin: position,
            target: ecologyReception,
            radius: 8,
            cells: ecologyRoute.map { AgentNavigationCell(position: $0, status: .traversable) }
        )
    )
}

private func ecologyObservations(tick: Int, fingerprintB: Int = 529) -> [AgentEcologyHabitatObservation] {
    [
        AgentEcologyHabitatObservation(
            worldTick: tick,
            candidateIndex: 0,
            habitatPosition: ecologyHabitatA,
            foragePosition: ecologyForageA,
            habitatFingerprint: 528,
            distanceFromSettlement: 1,
            directionIndex: 0,
            worldReadCount: 4
        ),
        AgentEcologyHabitatObservation(
            worldTick: tick,
            candidateIndex: 1,
            habitatPosition: ecologyHabitatB,
            foragePosition: ecologyForageB,
            habitatFingerprint: fingerprintB,
            distanceFromSettlement: 3,
            directionIndex: 1,
            worldReadCount: 4
        ),
    ]
}

private func ecologyForageIntent(
    id: String,
    patch: AgentEcologyPatch,
    agent: String,
    tick: Int
) -> AgentForageIntent {
    AgentForageIntent(
        forageID: id,
        patchID: patch.patchID,
        agentID: AgentID(rawValue: agent)!,
        tick: tick,
        target: patch.foragePosition,
        observedAtTick: tick,
        expectedHabitatFingerprint: patch.habitatFingerprint
    )
}

private func ecologyWrite<T: Encodable>(_ value: T, to url: URL) throws {
    try (AgentCheckpointCodec.encode(value) + Data([0x0a])).write(to: url, options: .atomic)
}

private func ecologyManifest(
    seed: UInt32,
    checkpoint: AgentSessionCheckpoint,
    bytes: Data
) -> AgentCheckpointManifest {
    let ecology = checkpoint.durableState.localEcologyState!
    var cells = ecology.patches.flatMap {
        [
            AgentCheckpointWorldCell(
                position: $0.habitatPosition,
                blockFingerprint: $0.habitatFingerprint
            ),
            AgentCheckpointWorldCell(position: $0.foragePosition, blockFingerprint: 0),
        ]
    }
    cells += checkpoint.durableState.agents.flatMap {
        [
            AgentCheckpointWorldCell(position: $0.position, blockFingerprint: 0),
            AgentCheckpointWorldCell(position: $0.homePosition, blockFingerprint: 0),
        ]
    }
    cells = Dictionary(cells.map { ($0.position, $0) }, uniquingKeysWith: { lhs, _ in lhs })
        .values.sorted {
            if $0.position.x != $1.position.x { return $0.position.x < $1.position.x }
            if $0.position.y != $1.position.y { return $0.position.y < $1.position.y }
            return $0.position.z < $1.position.z
        }
    return AgentCheckpointManifest(
        name: AgentCheckpointName(rawValue: "ecology-shortage")!,
        checkpoint: checkpoint,
        storageDigest: AgentCheckpointDigest.sha256(bytes),
        byteLength: bytes.count,
        restartSafe: true,
        restartSafetyReason: "local ecology is read-only World state with fully persisted bounded yield",
        worldBinding: try! AgentCheckpointWorldBinding(
            worldID: "headless-ecology-\(seed)",
            storageIdentity: "headless-ecology-storage-\(seed)",
            seed: seed,
            dimension: 0,
            anchor: ecologyAnchor,
            simulationID: checkpoint.simulationID,
            checkpointTick: checkpoint.tick,
            cells: cells
        ),
        orchestration: AgentCheckpointLiveOrchestration(
            cognitiveHz: 4,
            wasPaused: true,
            movementEnabled: true,
            autoInteractionEnabled: true,
            economyAutoEnabled: true,
            focusedAgentID: "agent_0"
        )
    )
}

func runLocalEcologySubsistenceSmoke(_ options: Options) -> Never {
    guard let outPath = options.outPath else {
        fail("local_ecology_subsistence_smoke requires an explicit --out directory")
    }
    let root = URL(fileURLWithPath: outPath, isDirectory: true)
    do {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        guard (try FileManager.default.contentsOfDirectory(atPath: root.path)).isEmpty else {
            fail("local ecology output directory must be empty: \(outPath)")
        }
    } catch { fail("failed to prepare local ecology output: \(error)") }

    var direct = ecologyScenarioSession(seed: options.seed)
    let habitatObservations = ecologyObservations(tick: direct.tick)
    let ecologyConfiguration = try! AgentLocalEcologyConfiguration(
        maximumPatches: 2,
        maximumHabitatCandidates: 4,
        observationRadius: 8,
        patchCapacity: 1,
        initialYield: 1,
        regenerationIntervalTicks: 8,
        regenerationQuantity: 1,
        maximumForageIntentsPerTick: 8,
        maximumForageHistory: 64,
        maximumPressureFrames: 32,
        maximumHabitatReadsPerScan: 256
    )
    try! direct.initializeLocalEcology(
        observations: habitatObservations,
        configuration: ecologyConfiguration
    )
    let initialEcology = direct.localEcologySnapshot()
    let patchA = initialEcology.patches.first { $0.foragePosition == ecologyForageA }!
    let patchB = initialEcology.patches.first { $0.foragePosition == ecologyForageB }!
    let nearObservations = try! direct.localEcologyResourceObservations(
        for: AgentID(rawValue: "agent_0")!,
        habitatValidations: habitatObservations
    )
    let distantObservations = try! direct.localEcologyResourceObservations(
        for: AgentID(rawValue: "agent_2")!,
        habitatValidations: habitatObservations
    )
    var forageOutcomes = try! direct.applyForageIntents(
        [
            ecologyForageIntent(id: "forage-headless-a1", patch: patchA, agent: "agent_1", tick: 4),
            ecologyForageIntent(id: "forage-headless-a0", patch: patchA, agent: "agent_0", tick: 4),
        ],
        habitatValidations: habitatObservations
    )
    forageOutcomes += try! direct.applyForageIntents(
        [ecologyForageIntent(id: "forage-headless-b1", patch: patchB, agent: "agent_1", tick: 4)],
        habitatValidations: habitatObservations
    )
    _ = try! direct.consumeFood(AgentConsumptionIntent(
        consumptionId: "consume-headless-a0",
        agentId: "agent_0",
        tick: 4
    ))
    _ = try! direct.consumeFood(AgentConsumptionIntent(
        consumptionId: "consume-headless-b1",
        agentId: "agent_1",
        tick: 4
    ))
    _ = try! direct.applyLocalEcologyEndOfTick(habitatValidations: habitatObservations)
    for nextTick in 5...7 {
        _ = try! direct.advanceTick()
        _ = try! direct.applyLocalEcologyEndOfTick(
            habitatValidations: ecologyObservations(tick: nextTick)
        )
    }
    let shortage = direct.localEcologySnapshot()
    let checkpoint = try! direct.makeCheckpoint()
    let checkpointBytes = try! AgentCheckpointCodec.encode(checkpoint)
    let manifest = ecologyManifest(seed: options.seed, checkpoint: checkpoint, bytes: checkpointBytes)
    var recorder = try! AgentReplayRecorder(checkpoint: checkpoint, session: direct)
    for nextTick in 8...13 {
        _ = try! recorder.apply(
            .advanceTick(perceptions: [], physicalObservations: []),
            to: &direct
        )
        _ = try! recorder.apply(
            .applyHabitatValidation(ecologyObservations(tick: nextTick)),
            to: &direct
        )
    }
    let regeneratedPatch = direct.localEcologySnapshot().patches.first {
        $0.patchID == patchB.patchID
    }!
    let recoveryIntent = ecologyForageIntent(
        id: "forage-headless-recovery",
        patch: regeneratedPatch,
        agent: "agent_1",
        tick: direct.tick
    )
    _ = try! recorder.apply(
        .applyForageOutcomes(
            intents: [recoveryIntent],
            habitatValidations: ecologyObservations(tick: direct.tick)
        ),
        to: &direct
    )
    _ = try! recorder.apply(
        .consumptionOutcome(try! direct.previewConsumptionOutcome(AgentConsumptionIntent(
            consumptionId: "consume-headless-recovery",
            agentId: "agent_1",
            tick: direct.tick
        ))),
        to: &direct
    )
    _ = try! recorder.apply(
        .applyHabitatValidation(ecologyObservations(tick: direct.tick)),
        to: &direct
    )
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "ecology-shortage-continuation")!
    )
    let replayed = try! AgentSessionReplayer.replay(checkpoint: checkpoint, journal: journal)
    let finalEcology = direct.localEcologySnapshot()
    let finalSummary = direct.localEcologySummary()
    let causal = direct.causalLedgerSnapshot()
    let durableBytes = try! direct.durableStateBytes()
    let replayBytes = try! replayed.session.durableStateBytes()

    var invalidated = try! AgentSimulationSession.restoring(checkpoint)
    _ = try! invalidated.applyLocalEcologyEndOfTick(
        habitatValidations: ecologyObservations(tick: invalidated.tick, fingerprintB: 999)
    )
    let invalidPatch = invalidated.localEcologySnapshot().patches.first {
        $0.patchID == patchB.patchID
    }

    var checks: [EcologyScenarioCheck] = []
    func add(_ name: String, _ passed: Bool, _ detail: String = "") {
        checks.append(EcologyScenarioCheck(name: name, passed: passed, detail: detail))
    }
    let population = direct.populationSummary()
    add("population_four_residents", population.memberCount == 4 && population.residentCount == 4)
    add("two_real_habitats", initialEcology.patches.count == 2
        && initialEcology.patches.allSatisfy { $0.habitatFingerprint > 0 })
    add("stable_patch_ids", Set(initialEcology.patches.map(\.patchID)).count == 2)
    add("initial_yield_exact", initialEcology.conservation.initialYieldTotal == 2)
    add("local_perception", nearObservations.contains { $0.patchIDForScenario == patchA.patchID })
    add("bounded_non_omniscience", distantObservations.count < initialEcology.patches.count)
    add("stable_competition", forageOutcomes.prefix(2).map(\.status) == [.succeeded, .depleted])
    add("single_credit", forageOutcomes.filter { $0.status == .succeeded }.count == 2)
    add("depletion_exact", shortage.patches.allSatisfy { $0.currentYield == 0 })
    add("scarcity_observed", shortage.pressureFrames.contains { $0.level == .scarce })
    add("critical_real", finalEcology.pressureFrames.contains {
        $0.level == .critical && $0.input.starvationDamageDelta > 0
    })
    add("non_lethal_famine", direct.snapshot().agents.allSatisfy { $0.health > 0 })
    add("regeneration_exact", finalEcology.conservation.regeneratedTotal >= 2)
    add("recovering_observed", finalEcology.pressureFrames.contains { $0.level == .recovering })
    add("ecology_conservation", finalEcology.conservation.balanced)
    add("material_conservation", direct.conservationSnapshot().balanced)
    add("schema_v4", checkpoint.schemaVersion == 4 && journal.manifest.schemaVersion == 4)
    add("checkpoint_mid_shortage", checkpoint.tick.rawValue == 7
        && shortage.patches.allSatisfy { $0.status == .depleted })
    add("restore_exact", (try! AgentSimulationSession.restoring(checkpoint).durableStateBytes())
        == checkpoint.durableStateBytesForEcologyScenario)
    add("replay_exact", replayed.report.verified && durableBytes == replayBytes)
    add("invalid_habitat_stops_patch", invalidPatch?.status == .invalidated)
    add("world_read_only", direct.conservationSnapshot().constructedTotal == 0)
    add("bounded_collections", finalEcology.forageHistory.count <= 64
        && finalEcology.pressureFrames.count <= 32)
    let success = checks.allSatisfy(\.passed)

    let checkpointDirectory = root.appendingPathComponent("ecology_checkpoint_v4", isDirectory: true)
    let replayDirectory = root.appendingPathComponent("ecology_replay_v4", isDirectory: true)
    try! FileManager.default.createDirectory(at: checkpointDirectory, withIntermediateDirectories: false)
    try! FileManager.default.createDirectory(at: replayDirectory, withIntermediateDirectories: false)
    try! checkpointBytes.write(to: checkpointDirectory.appendingPathComponent("session.json"))
    try! ecologyWrite(manifest, to: checkpointDirectory.appendingPathComponent("manifest.json"))
    try! AgentReplayCodec.encodeRecords(journal.records).write(
        to: replayDirectory.appendingPathComponent("operations.ndjson")
    )
    try! ecologyWrite(journal.manifest, to: replayDirectory.appendingPathComponent("manifest.json"))
    try! ecologyWrite(initialEcology.patches, to: root.appendingPathComponent("local_ecology_patches.json"))
    try! ecologyWrite(
        ["near": nearObservations, "distant": distantObservations],
        to: root.appendingPathComponent("local_ecology_observations.json")
    )
    try! ecologyWrite(forageOutcomes, to: root.appendingPathComponent("forage_outcomes.json"))
    try! ecologyWrite(finalEcology.conservation, to: root.appendingPathComponent("ecology_conservation.json"))
    try! ecologyWrite(finalEcology.pressureFrames, to: root.appendingPathComponent("subsistence_pressure_frames.json"))
    try! ecologyWrite(
        causal.events.filter { $0.kind.isLocalEcologyForScenario },
        to: root.appendingPathComponent("ecology_causal_chain.json")
    )
    let digest = try! direct.durableStateDigest()
    try! ecologyWrite(
        EcologyScenarioSummary(
            scenario: options.scenario,
            seed: options.seed,
            simulationID: direct.simulationID.rawValue,
            population: population.memberCount,
            residents: population.residentCount,
            patchIDs: finalEcology.patches.map(\.patchID.rawValue),
            initialYield: finalEcology.conservation.initialYieldTotal,
            harvested: finalSummary.harvested,
            regenerated: finalSummary.regenerated,
            starvationDamage: finalSummary.starvationDamage,
            checkpointSchema: checkpoint.schemaVersion,
            checkpointTick: checkpoint.tick.rawValue,
            replaySchema: journal.manifest.schemaVersion,
            replayRecords: journal.records.count,
            finalPressure: finalSummary.pressure?.rawValue ?? "none",
            finalCausalSequence: causal.summary.latestSequence,
            causalDigest: causal.summary.digest,
            durableDigest: digest.rawValue,
            ecologyDigest: finalEcology.digest,
            ecologyBalanced: finalEcology.conservation.balanced,
            materialBalanced: direct.conservationSnapshot().balanced,
            worldMutationCount: 0
        ),
        to: root.appendingPathComponent("ecology_summary.json")
    )
    try! ecologyWrite(
        EcologyScenarioDigests(
            durable: digest.rawValue,
            ecology: finalEcology.digest,
            causal: causal.summary.digest,
            checkpoint: checkpoint.semanticDigest.rawValue,
            replay: replayed.report.finalSemanticDigest.rawValue
        ),
        to: root.appendingPathComponent("ecology_digest.json")
    )
    try! ecologyWrite(
        EcologyScenarioReport(
            scenario: options.scenario,
            seed: options.seed,
            success: success,
            checks: checks
        ),
        to: root.appendingPathComponent("ecology_invariant_report.json")
    )
    guard success else {
        let failed = checks.filter { !$0.passed }.map(\.name).joined(separator: ",")
        fail("local_ecology_subsistence_smoke invariants failed: \(failed)")
    }
    print(
        "local_ecology_subsistence_smoke PASS patches=\(finalEcology.patches.count) "
            + "harvested=\(finalSummary.harvested) regenerated=\(finalSummary.regenerated) "
            + "pressure=\(finalSummary.pressure?.rawValue ?? "none") "
            + "schema=\(checkpoint.schemaVersion) digest=\(finalEcology.digest)"
    )
    exit(0)
}

private extension AgentSimulationSession {
    func previewConsumptionOutcome(_ intent: AgentConsumptionIntent) throws -> AgentConsumptionOutcome {
        let state = try self.state(for: intent.agentId)
        let available = state.resourceInventory.count(of: .foodRaw) >= intent.quantity
        return AgentConsumptionOutcome(
            consumptionId: intent.consumptionId,
            agentId: intent.agentId,
            tick: intent.tick,
            resource: intent.resource,
            quantity: intent.quantity,
            status: available ? .succeeded : .foodUnavailable,
            hungerBefore: state.needs.hunger,
            hungerAfter: available
                ? max(0, state.needs.hunger - configuration.survivalConfiguration.foodNutrition)
                : state.needs.hunger,
            reason: available
                ? "one carried foodRaw consumed atomically"
                : "no carried foodRaw available"
        )
    }
}

private extension AgentResourceObservation {
    var patchIDForScenario: AgentEcologyPatchID? { ecologyPatchID }
}

private extension AgentSessionCheckpoint {
    var durableStateBytesForEcologyScenario: Data {
        try! AgentCheckpointCodec.encode(durableState)
    }
}

private extension AgentCausalEventKind {
    var isLocalEcologyForScenario: Bool {
        switch self {
        case .localEcologyInitialized, .ecologyPatchRegistered, .ecologyPatchRegenerated,
             .ecologyForageResolved, .ecologyPatchDepleted, .ecologyPatchInvalidated,
             .subsistencePressureChanged, .localEcologyStateCleared:
            return true
        default: return false
        }
    }
}
