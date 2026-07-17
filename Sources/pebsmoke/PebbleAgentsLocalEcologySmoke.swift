import Foundation
import PebbleAgents

private func ecologyAgent(
    _ id: String,
    position: AgentPosition,
    health: Int = 100,
    inventory: AgentResourceInventory = AgentResourceInventory()
) -> AgentSessionAgentState {
    AgentSessionAgentState(
        id: id,
        state: "idle",
        position: position,
        needs: AgentNeeds(hunger: 0.45, fatigue: 0, curiosity: 0, safety: 1),
        health: health,
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
        totalDistanceReducedTowardHome: 0,
        resourceInventory: inventory
    )
}

private func ecologyHabitat(
    index: Int,
    habitat: AgentPosition,
    forage: AgentPosition,
    tick: Int = 0,
    fingerprint: Int = 528
) -> AgentEcologyHabitatObservation {
    AgentEcologyHabitatObservation(
        worldTick: tick,
        candidateIndex: index,
        habitatPosition: habitat,
        foragePosition: forage,
        habitatFingerprint: fingerprint,
        distanceFromSettlement: abs(forage.x) + abs(forage.y - 64) + abs(forage.z),
        directionIndex: index,
        worldReadCount: 4
    )
}

private func ecologyBaseSession(
    _ id: String,
    agents: [AgentSessionAgentState]? = nil
) -> AgentSimulationSession {
    let configuration = try! AgentSessionConfiguration(
        seed: 46,
        resourceObservationRadius: 8,
        recentMemorySnapshotLimit: 8,
        memoryPolicy: .bounded(maxEntries: 64)
    )
    var session = try! AgentSimulationSession(
        configuration: configuration,
        agents: agents ?? [
            ecologyAgent("agent_0", position: AgentPosition(x: 0, y: 64, z: 0)),
            ecologyAgent("agent_1", position: AgentPosition(x: 2, y: 64, z: 0)),
            ecologyAgent("agent_2", position: AgentPosition(x: 8, y: 64, z: 8)),
        ],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
    session.setSurvivalEnabled(true)
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 0)
    )
    return session
}

private func ecologySession(
    _ id: String,
    agents: [AgentSessionAgentState]? = nil,
    observations: [AgentEcologyHabitatObservation]? = nil,
    configuration: AgentLocalEcologyConfiguration = .live
) -> AgentSimulationSession {
    var session = ecologyBaseSession(id, agents: agents)
    try! session.initializeLocalEcology(observations: observations ?? [
        ecologyHabitat(
            index: 0,
            habitat: AgentPosition(x: 1, y: 63, z: 0),
            forage: AgentPosition(x: 1, y: 64, z: 0)
        ),
        ecologyHabitat(
            index: 1,
            habitat: AgentPosition(x: 0, y: 63, z: 2),
            forage: AgentPosition(x: 0, y: 64, z: 2),
            fingerprint: 529
        ),
    ], configuration: configuration)
    return session
}

func runPebbleAgentsLocalEcologySmoke() {
    section("pebble agents local ecology")

    check("ecology configuration defaults", AgentLocalEcologyConfiguration.live.maximumPatches == 4
        && AgentLocalEcologyConfiguration.live.maximumHabitatReadsPerScan == 256)
    check("ecology configuration rejects patch overflow", {
        do {
            _ = try AgentLocalEcologyConfiguration(maximumPatches: 9)
            return false
        } catch AgentLocalEcologyError.invalidConfiguration("patches") {
            return true
        } catch { return false }
    }())
    check("ecology configuration Codable", {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let bytes = try? encoder.encode(AgentLocalEcologyConfiguration.live),
              let decoded = try? JSONDecoder().decode(
                AgentLocalEcologyConfiguration.self,
                from: bytes
              ) else { return false }
        return decoded == .live
    }())

    let habitat = ecologyHabitat(
        index: 0,
        habitat: AgentPosition(x: 1, y: 63, z: 0),
        forage: AgentPosition(x: 1, y: 64, z: 0)
    )
    let same = ecologyHabitat(
        index: 7,
        habitat: AgentPosition(x: 1, y: 63, z: 0),
        forage: AgentPosition(x: 1, y: 64, z: 0)
    )
    let other = ecologyHabitat(
        index: 1,
        habitat: AgentPosition(x: 0, y: 63, z: 2),
        forage: AgentPosition(x: 0, y: 64, z: 2)
    )
    check("ecology patch identity stable", habitat.patchID == same.patchID)
    check("ecology patch identity distinct", habitat.patchID != other.patchID)

    var duplicateHabitatSession = ecologyBaseSession("sim-ecology-duplicate-habitat")
    let beforeDuplicateHabitat = try! duplicateHabitatSession.durableStateBytes()
    let duplicateHabitatRejected: Bool
    do {
        try duplicateHabitatSession.initializeLocalEcology(observations: [habitat, same])
        duplicateHabitatRejected = false
    } catch AgentSessionError.localEcology(.duplicateHabitat) {
        duplicateHabitatRejected = true
    } catch { duplicateHabitatRejected = false }
    check("ecology duplicate habitat rejected", duplicateHabitatRejected)
    check("ecology duplicate habitat atomic", beforeDuplicateHabitat
        == (try! duplicateHabitatSession.durableStateBytes()))

    let singlePatchConfiguration = try! AgentLocalEcologyConfiguration(maximumPatches: 1)
    let farHabitat = ecologyHabitat(
        index: 2,
        habitat: AgentPosition(x: 4, y: 63, z: 0),
        forage: AgentPosition(x: 4, y: 64, z: 0),
        fingerprint: 530
    )
    let orderedSelection = ecologySession(
        "sim-ecology-ordered-selection",
        observations: [farHabitat, habitat],
        configuration: singlePatchConfiguration
    )
    check("ecology habitat selection order stable", orderedSelection.localEcologySnapshot()
        .patches.map(\.patchID) == [habitat.patchID])

    var session = ecologySession("sim-ecology-smoke-a")
    let initial = session.localEcologySnapshot()
    check("ecology patches bounded and ordered", initial.patches.count == 2
        && initial.patches.map(\.patchID) == initial.patches.map(\.patchID).sorted())
    check("ecology initial yield exact", initial.conservation.initialYieldTotal == 2
        && initial.conservation.currentPatchYieldTotal == 2)
    check("ecology patch capacity and yield bounded", initial.patches.allSatisfy {
        $0.capacity == 1 && (0...$0.capacity).contains($0.currentYield)
    })
    check("ecology initial conservation", initial.conservation.balanced)
    let validations = [habitat, other]
    let near = try! session.localEcologyResourceObservations(
        for: AgentID(rawValue: "agent_0")!,
        habitatValidations: validations
    )
    let far = try! session.localEcologyResourceObservations(
        for: AgentID(rawValue: "agent_2")!,
        habitatValidations: validations
    )
    check("ecology local perception sees near patch", near.contains { $0.ecologyPatchID == habitat.patchID })
    check("ecology local perception hides out of range", far.isEmpty)
    check("ecology observation source explicit", near.allSatisfy { $0.source == .localEcology })
    let chunkUnavailable = AgentEcologyHabitatObservation(
        worldTick: 0,
        candidateIndex: 0,
        habitatPosition: habitat.habitatPosition,
        foragePosition: habitat.foragePosition,
        habitatFingerprint: habitat.habitatFingerprint,
        distanceFromSettlement: habitat.distanceFromSettlement,
        directionIndex: habitat.directionIndex,
        habitatChunkReady: false,
        forageChunkReady: false,
        worldReadCount: 1
    )
    check("ecology chunk unavailable hidden", (try! session.localEcologyResourceObservations(
        for: AgentID(rawValue: "agent_0")!,
        habitatValidations: [chunkUnavailable, other]
    )).allSatisfy { $0.ecologyPatchID != habitat.patchID })
    let mismatchedHabitat = ecologyHabitat(
        index: 0,
        habitat: habitat.habitatPosition,
        forage: habitat.foragePosition,
        fingerprint: 999
    )
    check("ecology habitat mismatch hidden", (try! session.localEcologyResourceObservations(
        for: AgentID(rawValue: "agent_0")!,
        habitatValidations: [mismatchedHabitat, other]
    )).allSatisfy { $0.ecologyPatchID != habitat.patchID })

    let maximumHabitats = (1...AgentResourcePerception.maximumObservationCount).map {
        ecologyHabitat(
            index: $0 - 1,
            habitat: AgentPosition(x: $0, y: 63, z: 0),
            forage: AgentPosition(x: $0, y: 64, z: 0),
            fingerprint: 600 + $0
        )
    }
    let maximumConfiguration = try! AgentLocalEcologyConfiguration(maximumPatches: 8)
    let maximumSession = ecologySession(
        "sim-ecology-maximum-observations",
        observations: Array(maximumHabitats.reversed()),
        configuration: maximumConfiguration
    )
    let maximumObservations = try! maximumSession.localEcologyResourceObservations(
        for: AgentID(rawValue: "agent_0")!,
        habitatValidations: Array(maximumHabitats.reversed())
    )
    check("ecology observations sorted", maximumObservations.map(\.distanceManhattan)
        == Array(1...AgentResourcePerception.maximumObservationCount))
    check("ecology maximum observations enforced", maximumObservations.count
        == AgentResourcePerception.maximumObservationCount)

    let intents = [
        AgentForageIntent(
            forageID: "forage-agent-1",
            patchID: habitat.patchID,
            agentID: AgentID(rawValue: "agent_1")!,
            tick: 0,
            target: habitat.foragePosition,
            observedAtTick: 0,
            expectedHabitatFingerprint: habitat.habitatFingerprint
        ),
        AgentForageIntent(
            forageID: "forage-agent-0",
            patchID: habitat.patchID,
            agentID: AgentID(rawValue: "agent_0")!,
            tick: 0,
            target: habitat.foragePosition,
            observedAtTick: 0,
            expectedHabitatFingerprint: habitat.habitatFingerprint
        ),
    ]
    let outcomes = try! session.applyForageIntents(intents, habitatValidations: validations)
    check("ecology stable competition winner", outcomes.map(\.agentID.rawValue) == ["agent_0", "agent_1"]
        && outcomes.map(\.status) == [.succeeded, .depleted])
    check("ecology depletion exact", session.localEcologySnapshot().patches
        .first(where: { $0.patchID == habitat.patchID }).map {
            $0.status == .depleted && $0.currentYield == 0 && $0.harvestedTotal == 1
        } == true)
    check("ecology competition single credit", (try! session.state(for: "agent_0")).resourceInventory.count(of: .foodRaw) == 1
        && (try! session.state(for: "agent_1")).resourceInventory.count(of: .foodRaw) == 0)
    check("ecology depleted patch hidden", !(try! session.localEcologyResourceObservations(
        for: AgentID(rawValue: "agent_0")!,
        habitatValidations: validations
    )).contains { $0.ecologyPatchID == habitat.patchID })
    check("ecology double conservation after forage", session.ecologyConservationSnapshot().balanced
        && session.conservationSnapshot().balanced)

    var reversed = ecologySession("sim-ecology-smoke-b")
    let reversedOutcomes = try! reversed.applyForageIntents(
        Array(intents.reversed()),
        habitatValidations: Array(validations.reversed())
    )
    check("ecology competition input order neutral", outcomes.map { ($0.agentID, $0.status) }
        .elementsEqual(reversedOutcomes.map { ($0.agentID, $0.status) }, by: ==))

    var staleSession = ecologySession("sim-ecology-stale-forage")
    let staleOutcome = try! staleSession.applyForageIntents([
        AgentForageIntent(
            forageID: "forage-stale-observation",
            patchID: habitat.patchID,
            agentID: AgentID(rawValue: "agent_0")!,
            tick: 0,
            target: habitat.foragePosition,
            observedAtTick: -2,
            expectedHabitatFingerprint: habitat.habitatFingerprint
        ),
    ], habitatValidations: validations)
    check("ecology stale forage rejected", staleOutcome.map(\.status) == [.staleObservation]
        && staleSession.localEcologySnapshot().patches
            .first(where: { $0.patchID == habitat.patchID })?.currentYield == 1)

    var distantSession = ecologySession("sim-ecology-not-adjacent-forage")
    let distantOutcome = try! distantSession.applyForageIntents([
        AgentForageIntent(
            forageID: "forage-not-adjacent",
            patchID: habitat.patchID,
            agentID: AgentID(rawValue: "agent_2")!,
            tick: 0,
            target: habitat.foragePosition,
            observedAtTick: 0,
            expectedHabitatFingerprint: habitat.habitatFingerprint
        ),
    ], habitatValidations: validations)
    check("ecology non-adjacent forage rejected", distantOutcome.map(\.status) == [.notAdjacent]
        && distantSession.localEcologySnapshot().patches
            .first(where: { $0.patchID == habitat.patchID })?.currentYield == 1)

    let oneSlotInventory = AgentResourceInventory(capacity: 1)
    let inventoryAgents = [
        ecologyAgent(
            "agent_0",
            position: AgentPosition(x: 0, y: 64, z: 0),
            inventory: oneSlotInventory
        ),
        ecologyAgent("agent_1", position: AgentPosition(x: 2, y: 64, z: 0)),
        ecologyAgent("agent_2", position: AgentPosition(x: 8, y: 64, z: 8)),
    ]
    let inventoryHabitat = ecologyHabitat(
        index: 1,
        habitat: AgentPosition(x: 0, y: 63, z: 1),
        forage: AgentPosition(x: 0, y: 64, z: 1),
        fingerprint: 531
    )
    let inventoryValidations = [habitat, inventoryHabitat]
    var inventorySession = ecologySession(
        "sim-ecology-inventory-full",
        agents: inventoryAgents,
        observations: inventoryValidations
    )
    let inventoryFirst = try! inventorySession.applyForageIntents([
        AgentForageIntent(
            forageID: "forage-fill-inventory",
            patchID: habitat.patchID,
            agentID: AgentID(rawValue: "agent_0")!,
            tick: 0,
            target: habitat.foragePosition,
            observedAtTick: 0,
            expectedHabitatFingerprint: habitat.habitatFingerprint
        ),
    ], habitatValidations: inventoryValidations)
    let inventorySecond = try! inventorySession.applyForageIntents([
        AgentForageIntent(
            forageID: "forage-inventory-full",
            patchID: inventoryHabitat.patchID,
            agentID: AgentID(rawValue: "agent_0")!,
            tick: 0,
            target: inventoryHabitat.foragePosition,
            observedAtTick: 0,
            expectedHabitatFingerprint: inventoryHabitat.habitatFingerprint
        ),
    ], habitatValidations: inventoryValidations)
    check("ecology inventory full forage rejected", inventoryFirst.map(\.status) == [.succeeded]
        && inventorySecond.map(\.status) == [.inventoryFull]
        && inventorySession.conservationSnapshot().balanced
        && inventorySession.ecologyConservationSnapshot().balanced)

    let pressureCases: [(AgentSubsistencePressureLevel, AgentSubsistencePressureInput, AgentSubsistencePressureLevel?)] = [
        (.abundant, .init(population: 4, hungry: 0, critical: 0, starvationDamageDelta: 0, availableYield: 2, carriedFood: 0, stockedFood: 0, regeneratedDelta: 0, consumedDelta: 0), nil),
        (.adequate, .init(population: 4, hungry: 1, critical: 0, starvationDamageDelta: 0, availableYield: 1, carriedFood: 0, stockedFood: 0, regeneratedDelta: 0, consumedDelta: 0), nil),
        (.scarce, .init(population: 4, hungry: 3, critical: 0, starvationDamageDelta: 0, availableYield: 1, carriedFood: 0, stockedFood: 0, regeneratedDelta: 0, consumedDelta: 0), nil),
        (.critical, .init(population: 4, hungry: 4, critical: 1, starvationDamageDelta: 10, availableYield: 0, carriedFood: 0, stockedFood: 0, regeneratedDelta: 0, consumedDelta: 0), .scarce),
        (.recovering, .init(population: 4, hungry: 1, critical: 0, starvationDamageDelta: 0, availableYield: 1, carriedFood: 0, stockedFood: 0, regeneratedDelta: 1, consumedDelta: 0), .critical),
    ]
    for (level, input, previous) in pressureCases {
        check("ecology pressure \(level.rawValue)", AgentSubsistencePressureClassifier.classify(
            input,
            previous: previous
        ) == level)
    }

    for _ in 0..<8 { _ = try! session.advanceTick() }
    let regeneratedFrame = try! session.applyLocalEcologyEndOfTick(
        habitatValidations: [
            ecologyHabitat(index: 0, habitat: habitat.habitatPosition, forage: habitat.foragePosition, tick: 8),
            ecologyHabitat(index: 1, habitat: other.habitatPosition, forage: other.foragePosition, tick: 8),
        ]
    )
    check("ecology deterministic regeneration", session.localEcologySnapshot().patches
        .first(where: { $0.patchID == habitat.patchID })?.currentYield == 1)
    check("ecology regeneration conserved", session.ecologyConservationSnapshot().balanced)
    check("ecology pressure pulse authoritative", regeneratedFrame?.tick == 8)

    let ecologyCheckpoint = try! session.makeCheckpoint()
    let ecologyCheckpointBytes = try! AgentCheckpointCodec.encode(ecologyCheckpoint.durableState)
    let restoredEcology = try! AgentSimulationSession.restoring(ecologyCheckpoint)
    check("ecology checkpoint uses v4", ecologyCheckpoint.schemaVersion == 4
        && ecologyCheckpoint.durableState.localEcologyState != nil)
    check("ecology checkpoint restore exact", try! restoredEcology.durableStateBytes()
        == ecologyCheckpointBytes)
    let corruptedCheckpointRejected: Bool = {
        guard let checkpointBytes = try? AgentCheckpointCodec.encode(ecologyCheckpoint),
              var root = try? JSONSerialization.jsonObject(with: checkpointBytes)
                as? [String: Any],
              var durable = root["durableState"] as? [String: Any],
              var harvested = durable["harvestedResourceTotals"] as? [String: Any] else {
            return false
        }
        harvested["foodRawCount"] = 999
        durable["harvestedResourceTotals"] = harvested
        root["durableState"] = durable
        guard let corruptedBytes = try? JSONSerialization.data(
            withJSONObject: root,
            options: [.sortedKeys]
        ), let corrupted = try? AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self,
            from: corruptedBytes
        ) else { return false }
        do {
            _ = try AgentSimulationSession.restoring(corrupted)
            return false
        } catch { return true }
    }()
    check("ecology corrupted conservation checkpoint refused", corruptedCheckpointRejected)

    var replayDirect = session
    var recorder = try! AgentReplayRecorder(checkpoint: ecologyCheckpoint, session: replayDirect)
    _ = try! recorder.apply(
        .advanceTick(perceptions: [], physicalObservations: []),
        to: &replayDirect
    )
    _ = try! recorder.apply(
        .applyHabitatValidation([
            ecologyHabitat(index: 0, habitat: habitat.habitatPosition, forage: habitat.foragePosition, tick: 9),
            ecologyHabitat(index: 1, habitat: other.habitatPosition, forage: other.foragePosition, tick: 9),
        ]),
        to: &replayDirect
    )
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "ecology-smoke-replay")!
    )
    let replayed = try! AgentSessionReplayer.replay(
        checkpoint: ecologyCheckpoint,
        journal: journal
    )
    check("ecology replay uses v4", journal.manifest.schemaVersion == 4)
    check("ecology replay verified", replayed.report.verified)
    check("ecology replay durable bytes exact", try! replayDirect.durableStateBytes()
        == replayed.session.durableStateBytes())
    check("ecology replay causal digest exact", replayDirect.causalLedgerSnapshot().summary.digest
        == replayed.session.causalLedgerSnapshot().summary.digest)

    var invalidated = try! AgentSimulationSession.restoring(ecologyCheckpoint)
    _ = try! invalidated.applyForageIntents([
        AgentForageIntent(
            forageID: "forage-before-invalidation",
            patchID: habitat.patchID,
            agentID: AgentID(rawValue: "agent_0")!,
            tick: 8,
            target: habitat.foragePosition,
            observedAtTick: 8,
            expectedHabitatFingerprint: habitat.habitatFingerprint
        ),
    ], habitatValidations: [
        ecologyHabitat(index: 0, habitat: habitat.habitatPosition, forage: habitat.foragePosition, tick: 8),
        ecologyHabitat(index: 1, habitat: other.habitatPosition, forage: other.foragePosition, tick: 8),
    ])
    _ = try! invalidated.applyLocalEcologyEndOfTick(habitatValidations: [
        ecologyHabitat(
            index: 0,
            habitat: habitat.habitatPosition,
            forage: habitat.foragePosition,
            tick: 8,
            fingerprint: 999
        ),
        ecologyHabitat(index: 1, habitat: other.habitatPosition, forage: other.foragePosition, tick: 8),
    ])
    for _ in 0..<8 { _ = try! invalidated.advanceTick() }
    _ = try! invalidated.applyLocalEcologyEndOfTick(habitatValidations: [
        ecologyHabitat(
            index: 0,
            habitat: habitat.habitatPosition,
            forage: habitat.foragePosition,
            tick: 16,
            fingerprint: 999
        ),
        ecologyHabitat(index: 1, habitat: other.habitatPosition, forage: other.foragePosition, tick: 16),
    ])
    check("ecology habitat mismatch invalidates patch", invalidated.localEcologySnapshot().patches
        .first(where: { $0.patchID == habitat.patchID })?.status == .invalidated)
    check("ecology invalidated patch does not regenerate", invalidated.localEcologySnapshot().patches
        .first(where: { $0.patchID == habitat.patchID })?.currentYield == 0)

    let beforeDuplicate = try! session.durableStateBytes()
    let duplicateRejected: Bool
    do {
        _ = try session.applyForageIntents([
            AgentForageIntent(
                forageID: "forage-agent-0",
                patchID: habitat.patchID,
                agentID: AgentID(rawValue: "agent_0")!,
                tick: 8,
                target: habitat.foragePosition,
                observedAtTick: 8,
                expectedHabitatFingerprint: habitat.habitatFingerprint
            ),
        ], habitatValidations: validations)
        duplicateRejected = false
    } catch {
        duplicateRejected = true
    }
    check("ecology duplicate forage rejected", duplicateRejected)
    check("ecology duplicate forage atomic", beforeDuplicate == (try! session.durableStateBytes()))
    check("ecology forage rollback exact", duplicateRejected
        && beforeDuplicate == (try! session.durableStateBytes()))
}
