import Foundation
import PebbleAgents

private func ecologyAgent(_ id: String, position: AgentPosition) -> AgentSessionAgentState {
    AgentSessionAgentState(
        id: id,
        state: "idle",
        position: position,
        needs: AgentNeeds(hunger: 0.45, fatigue: 0, curiosity: 0, safety: 1),
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

private func ecologySession(_ id: String) -> AgentSimulationSession {
    let configuration = try! AgentSessionConfiguration(
        seed: 46,
        resourceObservationRadius: 8,
        recentMemorySnapshotLimit: 8,
        memoryPolicy: .bounded(maxEntries: 64)
    )
    var session = try! AgentSimulationSession(
        configuration: configuration,
        agents: [
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
    try! session.initializeLocalEcology(observations: [
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
    ])
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

    var session = ecologySession("sim-ecology-smoke-a")
    let initial = session.localEcologySnapshot()
    check("ecology patches bounded and ordered", initial.patches.count == 2
        && initial.patches.map(\.patchID) == initial.patches.map(\.patchID).sorted())
    check("ecology initial yield exact", initial.conservation.initialYieldTotal == 2
        && initial.conservation.currentPatchYieldTotal == 2)
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
}
