import Foundation
import PebbleAgents

private let gateFBlockerEastID = AgentSettlementID(rawValue: "settlement-east")!
private let gateFBlockerWestID = AgentSettlementID(rawValue: "settlement-west")!

private func gateFBlockerAgent(
    _ id: String,
    ordinal: Int
) -> AgentSessionAgentState {
    let position = AgentPosition(x: ordinal * 2, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id, state: "idle", position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "Gate F Blocker 01 capacity fixture",
            startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [],
        tickCreated: 0, ticksAlive: ordinal,
        observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0,
        actionCount: 0, actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func gateFBlockerSession(
    _ id: String,
    maximumPopulation: Int = 8
) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 601, memoryPolicy: .bounded(maxEntries: 64)
        ),
        agents: [
            gateFBlockerAgent("agent_0", ordinal: 0),
            gateFBlockerAgent("agent_1", ordinal: 1),
            gateFBlockerAgent("agent_2", ordinal: 2),
        ],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: -2),
        configuration: try! AgentPopulationConfiguration(
            maximumActivePopulation: maximumPopulation
        )
    )
    return session
}

private func gateFBlockerSettlement(
    _ id: AgentSettlementID,
    capacity: Int,
    x: Int
) -> AgentPopulationSettlement {
    AgentPopulationSettlement(
        settlementID: id,
        anchor: AgentPosition(x: x, y: 64, z: 8),
        receptionPosition: AgentPosition(x: x, y: 64, z: 7),
        capacity: capacity, residentIDs: [], inTransitIDs: []
    )
}

private func gateFBlockerAdmission(
    _ id: String,
    ordinal: Int,
    settlementID: AgentSettlementID
) -> AgentScaledResidentAdmission {
    AgentScaledResidentAdmission(
        state: gateFBlockerAgent(id, ordinal: ordinal),
        settlementID: settlementID
    )
}

private func gateFBlockerScaleConfiguration(
    maximumSettlements: Int = 3
) -> AgentPopulationScaleConfiguration {
    try! AgentPopulationScaleConfiguration(
        maximumSettlements: maximumSettlements,
        maximumLiveAgents: 4, maximumNearAgents: 4,
        nearMaintenanceCadence: 2, dormantMaintenanceCadence: 8,
        rotationIntervalTicks: 4,
        maximumFidelityTransitionHistory: 32,
        maximumSettlementMigrationHistory: 8,
        maximumConcurrentSettlementMigrations: 1,
        maximumSettlementMigrationRouteLength: 16
    )
}

private func gateFBlockerRefusesCapacity(
    _ session: inout AgentSimulationSession,
    settlements: [AgentPopulationSettlement],
    admissions: [AgentScaledResidentAdmission]
) -> Bool {
    do {
        try session.initializePopulationScaling(
            additionalSettlements: settlements,
            additionalResidents: admissions,
            configuration: gateFBlockerScaleConfiguration(
                maximumSettlements: settlements.count + 1
            )
        )
        return false
    } catch AgentSessionError.population(.capacityReached) {
        return true
    } catch {
        return false
    }
}

func runPebbleAgentsGateFBlocker01Smoke() {
    section("Gate F Blocker 01 per-settlement admission capacity")

    var exactOne = gateFBlockerSession("gate-f-b01-exact-one")
    try! exactOne.initializePopulationScaling(
        additionalSettlements: [gateFBlockerSettlement(
            gateFBlockerEastID, capacity: 1, x: 8
        )],
        additionalResidents: [gateFBlockerAdmission(
            "agent_3", ordinal: 3, settlementID: gateFBlockerEastID
        )],
        configuration: gateFBlockerScaleConfiguration(maximumSettlements: 2)
    )
    let exactOneEast = exactOne.populationSnapshot().settlements.first {
        $0.settlementID == gateFBlockerEastID
    }
    check("Gate F Blocker 01 capacity one exact admission passes",
          exactOneEast?.capacity == 1 && exactOneEast?.residentIDs.count == 1)

    let exactOneCheckpoint = try! exactOne.makeCheckpoint()
    let exactOneRestored = try! AgentSimulationSession.restoring(
        exactOneCheckpoint
    )
    let exactOneMemberships = exactOneRestored.populationSnapshot().settlements
        .flatMap { $0.residentIDs + $0.inTransitIDs }
    check("Gate F Blocker 01 exact boundary schema-35 restore passes",
          exactOneCheckpoint.schemaVersion == 35
            && (try! exactOneRestored.durableStateBytes())
                == (try! exactOne.durableStateBytes()))
    check("Gate F Blocker 01 restored inhabitants and memberships singular",
          exactOneRestored.snapshot().agents.count == 4
            && Set(exactOneRestored.snapshot().agents.map(\.id)).count == 4
            && exactOneMemberships.count == 4
            && Set(exactOneMemberships).count == 4)

    var refused = gateFBlockerSession("gate-f-b01-refusal")
    let refusalBytes = try! refused.durableStateBytes()
    let refusalPopulation = refused.populationSnapshot()
    let refusalIdentity = refused.identitySnapshot()
    let refusalEvents = refused.causalLedgerSnapshot().events
    let refusalOrdinal = refusalPopulation.nextPopulationOrdinal
    let refusedCapacity = gateFBlockerRefusesCapacity(
        &refused,
        settlements: [gateFBlockerSettlement(
            gateFBlockerEastID, capacity: 1, x: 8
        )],
        admissions: [
            gateFBlockerAdmission(
                "agent_3", ordinal: 3, settlementID: gateFBlockerEastID
            ),
            gateFBlockerAdmission(
                "agent_4", ordinal: 4, settlementID: gateFBlockerEastID
            ),
        ]
    )
    let refusedAfter = refused.populationSnapshot()
    check("Gate F Blocker 01 capacity one two-admission batch fails closed",
          refusedCapacity)
    check("Gate F Blocker 01 refusal durable bytes unchanged",
          try! refused.durableStateBytes() == refusalBytes)
    check("Gate F Blocker 01 refusal publishes no inhabitants or members",
          refused.snapshot().agents.count == 3
            && refusedAfter.members == refusalPopulation.members
            && refused.identitySnapshot() == refusalIdentity)
    check("Gate F Blocker 01 refusal publishes no settlement or residence",
          refusedAfter.settlements == refusalPopulation.settlements)
    check("Gate F Blocker 01 refusal publishes no fidelity or scale state",
          !refused.populationScalingEnabled
            && refused.populationScaleSnapshot().fidelityRecords.isEmpty)
    check("Gate F Blocker 01 refusal publishes no causal events",
          refused.causalLedgerSnapshot().events == refusalEvents)
    check("Gate F Blocker 01 refusal consumes no population ordinal",
          refusedAfter.nextPopulationOrdinal == refusalOrdinal)

    try! refused.initializePopulationScaling(
        additionalSettlements: [gateFBlockerSettlement(
            gateFBlockerEastID, capacity: 1, x: 8
        )],
        additionalResidents: [gateFBlockerAdmission(
            "agent_3", ordinal: 3, settlementID: gateFBlockerEastID
        )],
        configuration: gateFBlockerScaleConfiguration(maximumSettlements: 2)
    )
    var directRetry = gateFBlockerSession("gate-f-b01-refusal")
    try! directRetry.initializePopulationScaling(
        additionalSettlements: [gateFBlockerSettlement(
            gateFBlockerEastID, capacity: 1, x: 8
        )],
        additionalResidents: [gateFBlockerAdmission(
            "agent_3", ordinal: 3, settlementID: gateFBlockerEastID
        )],
        configuration: gateFBlockerScaleConfiguration(maximumSettlements: 2)
    )
    check("Gate F Blocker 01 valid retry has no ordinal or event gap",
          try! refused.durableStateBytes() == directRetry.durableStateBytes()
            && refused.populationSnapshot().nextPopulationOrdinal == 4)
    let retryCheckpoint = try! refused.makeCheckpoint()
    let retryRestored = try! AgentSimulationSession.restoring(retryCheckpoint)
    check("Gate F Blocker 01 valid retry restores exactly once",
          retryCheckpoint.schemaVersion == 35
            && (try! retryRestored.durableStateBytes())
                == (try! refused.durableStateBytes()))

    let exactThreeAdmissions = (3...5).map {
        gateFBlockerAdmission(
            "agent_\($0)", ordinal: $0, settlementID: gateFBlockerEastID
        )
    }
    var exactThreeA = gateFBlockerSession("gate-f-b01-order")
    var exactThreeB = gateFBlockerSession("gate-f-b01-order")
    try! exactThreeA.initializePopulationScaling(
        additionalSettlements: [gateFBlockerSettlement(
            gateFBlockerEastID, capacity: 3, x: 8
        )],
        additionalResidents: exactThreeAdmissions,
        configuration: gateFBlockerScaleConfiguration(maximumSettlements: 2)
    )
    try! exactThreeB.initializePopulationScaling(
        additionalSettlements: [gateFBlockerSettlement(
            gateFBlockerEastID, capacity: 3, x: 8
        )],
        additionalResidents: Array(exactThreeAdmissions.reversed()),
        configuration: gateFBlockerScaleConfiguration(maximumSettlements: 2)
    )
    check("Gate F Blocker 01 capacity N exact N passes",
          exactThreeA.populationSnapshot().settlements.first {
              $0.settlementID == gateFBlockerEastID
          }?.residentIDs.count == 3)
    check("Gate F Blocker 01 caller admission order is deterministic",
          try! exactThreeA.durableStateBytes()
            == exactThreeB.durableStateBytes())

    var excessN = gateFBlockerSession("gate-f-b01-excess-n")
    let excessNBytes = try! excessN.durableStateBytes()
    let excessNAdmissions = (3...6).map {
        gateFBlockerAdmission(
            "agent_\($0)", ordinal: $0, settlementID: gateFBlockerEastID
        )
    }
    check("Gate F Blocker 01 capacity N plus one fails closed",
          gateFBlockerRefusesCapacity(
              &excessN,
              settlements: [gateFBlockerSettlement(
                  gateFBlockerEastID, capacity: 3, x: 8
              )],
              admissions: excessNAdmissions
          ) && (try! excessN.durableStateBytes()) == excessNBytes)

    var multipleFit = gateFBlockerSession("gate-f-b01-multiple-fit")
    try! multipleFit.initializePopulationScaling(
        additionalSettlements: [
            gateFBlockerSettlement(gateFBlockerWestID, capacity: 1, x: -8),
            gateFBlockerSettlement(gateFBlockerEastID, capacity: 2, x: 8),
        ],
        additionalResidents: [
            gateFBlockerAdmission(
                "agent_6", ordinal: 6, settlementID: .main
            ),
            gateFBlockerAdmission(
                "agent_4", ordinal: 4, settlementID: gateFBlockerEastID
            ),
            gateFBlockerAdmission(
                "agent_3", ordinal: 3, settlementID: gateFBlockerEastID
            ),
            gateFBlockerAdmission(
                "agent_5", ordinal: 5, settlementID: gateFBlockerWestID
            ),
        ],
        configuration: gateFBlockerScaleConfiguration()
    )
    let multipleSettlements = multipleFit.populationSnapshot().settlements
    check("Gate F Blocker 01 multiple and mixed settlement batches fit",
          multipleSettlements.first { $0.settlementID == .main }?
            .residentIDs.count == 4
            && multipleSettlements.first {
                $0.settlementID == gateFBlockerEastID
            }?.residentIDs.count == 2
            && multipleSettlements.first {
                $0.settlementID == gateFBlockerWestID
            }?.residentIDs.count == 1)
    check("Gate F Blocker 01 main settlement capacity is respected",
          multipleSettlements.first { $0.settlementID == .main }.map {
              $0.residentIDs.count <= $0.capacity
          } == true)

    var oneOver = gateFBlockerSession("gate-f-b01-mixed-atomic")
    let oneOverBytes = try! oneOver.durableStateBytes()
    check("Gate F Blocker 01 one over-capacity settlement rejects whole batch",
          gateFBlockerRefusesCapacity(
              &oneOver,
              settlements: [
                  gateFBlockerSettlement(
                      gateFBlockerWestID, capacity: 1, x: -8
                  ),
                  gateFBlockerSettlement(
                      gateFBlockerEastID, capacity: 1, x: 8
                  ),
              ],
              admissions: [
                  gateFBlockerAdmission(
                      "agent_3", ordinal: 3,
                      settlementID: gateFBlockerEastID
                  ),
                  gateFBlockerAdmission(
                      "agent_4", ordinal: 4,
                      settlementID: gateFBlockerEastID
                  ),
                  gateFBlockerAdmission(
                      "agent_5", ordinal: 5,
                      settlementID: gateFBlockerWestID
                  ),
                  gateFBlockerAdmission(
                      "agent_6", ordinal: 6, settlementID: .main
                  ),
              ]
          ) && (try! oneOver.durableStateBytes()) == oneOverBytes)

    var globalBound = gateFBlockerSession(
        "gate-f-b01-global-distinct", maximumPopulation: 5
    )
    let globalBytes = try! globalBound.durableStateBytes()
    let globalRefused = gateFBlockerRefusesCapacity(
        &globalBound,
        settlements: [
            gateFBlockerSettlement(gateFBlockerWestID, capacity: 2, x: -8),
            gateFBlockerSettlement(gateFBlockerEastID, capacity: 2, x: 8),
        ],
        admissions: [
            gateFBlockerAdmission(
                "agent_3", ordinal: 3, settlementID: .main
            ),
            gateFBlockerAdmission(
                "agent_4", ordinal: 4, settlementID: gateFBlockerEastID
            ),
            gateFBlockerAdmission(
                "agent_5", ordinal: 5, settlementID: gateFBlockerWestID
            ),
        ]
    )
    check("Gate F Blocker 01 global bound remains distinct from local fit",
          globalRefused
            && 4 <= 5 && 1 <= 2 && 1 <= 2
            && (try! globalBound.durableStateBytes()) == globalBytes)

    var unchangedInvalid = gateFBlockerSession("gate-f-b01-invalid")
    let unchangedInvalidBytes = try! unchangedInvalid.durableStateBytes()
    let duplicateID = gateFBlockerAdmission(
        "agent_3", ordinal: 3, settlementID: gateFBlockerEastID
    )
    let duplicateRefused = gateFBlockerRefusesCapacity(
        &unchangedInvalid,
        settlements: [gateFBlockerSettlement(
            gateFBlockerEastID, capacity: 4, x: 8
        )],
        admissions: [duplicateID, duplicateID]
    )
    let invalidSettlementRefused = gateFBlockerRefusesCapacity(
        &unchangedInvalid,
        settlements: [gateFBlockerSettlement(
            gateFBlockerEastID, capacity: 4, x: 8
        )],
        admissions: [gateFBlockerAdmission(
            "agent_4", ordinal: 4,
            settlementID: AgentSettlementID(rawValue: "settlement-missing")!
        )]
    )
    check("Gate F Blocker 01 duplicate and invalid settlement behavior unchanged",
          duplicateRefused && invalidSettlementRefused
            && (try! unchangedInvalid.durableStateBytes())
                == unchangedInvalidBytes)
}
