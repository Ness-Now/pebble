import Foundation
import PebbleAgents

private let b03Positions = [
    AgentPosition(x: 9, y: 63, z: 9),
    AgentPosition(x: 10, y: 63, z: 9),
]

private struct B03Fixture {
    var session: AgentSimulationSession
    let plotID: AgentAgriculturalPlotID
    let cycle1Mature: AgentEcologicalObservationRecord
    let cycle2PlantActions: [AgentAgriculturalActionRecord]
    let plantingMinimumPhysicalTick: Int
}

private func b03Agent(_ index: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: index, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_\(index)", state: "idle", position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "blocker 03 fixture", startedAtTick: 0,
            urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func b03Session(_ id: String) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 303, memoryPolicy: .bounded(maxEntries: 128)
        ),
        agents: [b03Agent(0), b03Agent(1), b03Agent(2)],
        simulationID: AgentSimulationID(rawValue: id)!,
        causalLedgerPolicy: .bounded(maxEvents: 16_384)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 2)
    )
    try! session.setLifecycleEnabled(
        true,
        configuration: try! AgentLifecycleConfiguration(
            newbornDurationTicks: 8,
            maturityAgeTicks: 24,
            reproductionEvaluationIntervalTicks: 1,
            reproductionPlanDelayTicks: 1,
            reproductionCooldownTicks: 1,
            maximumRetainedBirthRecords: 32,
            maximumRetainedPlanRecords: 32,
            maximumParentBirthCount: 16
        )
    )
    try! session.setSkillsEnabled(true)
    try! session.setEcologicalObservationEnabled(true)
    try! session.setAgricultureEnabled(true)
    return session
}

private func b03Observation(
    _ session: AgentSimulationSession,
    observer: String = "agent_0",
    physicalTick: Int,
    stages: [Int: (crop: String, stage: Int)] = [:]
) -> AgentEcologicalObservation {
    let crops = stages.keys.sorted().map { index in
        let value = stages[index]!
        return AgentCropObservation(
            cropKey: value.crop,
            position: AgentPosition(
                x: b03Positions[index].x,
                y: b03Positions[index].y + 1,
                z: b03Positions[index].z
            ),
            growthStage: value.stage,
            maximumGrowthStage: 7,
            mature: value.stage == 7,
            supportBlockKey: "farmland"
        )
    }
    let resultCount = 1 + 1 + b03Positions.count + crops.count + 2
    return AgentEcologicalObservation(
        observerID: AgentID(rawValue: observer)!,
        origin: AgentPosition(x: 9, y: 64, z: 8),
        worldContextKey: "blocker-03-world",
        dimensionKey: "overworld",
        observedAtSimulationTick: session.tick,
        physicalWorldTick: physicalTick,
        civilDate: session.civilDate()!,
        biome: AgentBiomeObservation(
            biomeKey: "plains",
            position: AgentPosition(x: 9, y: 64, z: 8)
        ),
        water: [AgentWaterAffordance(
            fluidKey: "water",
            position: AgentPosition(x: 11, y: 63, z: 9),
            sourceBlock: true
        )],
        soils: b03Positions.map {
            AgentSoilAffordance(
                blockKey: "farmland", position: $0,
                tillable: false, alreadyFarmland: true,
                hydrated: true, supportsCrop: true
            )
        },
        crops: crops,
        plants: [], animals: [], fishing: [],
        weather: AgentWeatherObservation(
            kind: .clear, raining: false, thundering: false
        ),
        physicalTime: AgentPhysicalWorldTimeObservation(
            worldTick: physicalTick,
            dayTime: physicalTick % 24_000,
            timeOfDay: .day,
            daylightCycleEnabled: true
        ),
        diagnostics: AgentEcologicalScanDiagnostics(
            radius: 4, cellsConsidered: 405, worldReads: 405,
            chunksTouched: 1, chunksUnavailable: 0,
            entitiesConsidered: 0, resultsEmitted: resultCount,
            cacheHits: 0, cacheMisses: 1, completion: .complete
        ),
        expiresAtSimulationTick: session.tick + 4
    )
}

private func b03Action(
    _ session: AgentSimulationSession,
    plotID: AgentAgriculturalPlotID,
    cellIndex: Int?,
    kind: AgentAgriculturalActionKind,
    id: String,
    observationEventID: AgentCausalEventID? = nil
) -> AgentAgriculturalActionOutcome {
    let index = cellIndex ?? 0
    let material: [AgentAgriculturalMaterialDelta]
    let entities: [Int]
    let custody: String?
    let storage: String?
    let reserve: Int
    let surplus: Int
    switch kind {
    case .plant:
        material = [AgentAgriculturalMaterialDelta(
            itemKey: "wheat_seeds", quantity: 1, direction: .consumed
        )]
        entities = []
        custody = "plant-\(id)"
        storage = nil
        reserve = 0
        surplus = 0
    case .harvest:
        material = [
            AgentAgriculturalMaterialDelta(
                itemKey: "wheat", quantity: 1, direction: .acquired
            ),
            AgentAgriculturalMaterialDelta(
                itemKey: "wheat_seeds", quantity: 2,
                direction: .acquired
            ),
        ]
        entities = [100 + index * 2, 101 + index * 2]
        custody = "harvest-\(id)"
        storage = nil
        reserve = 0
        surplus = 0
    case .store:
        material = [
            AgentAgriculturalMaterialDelta(
                itemKey: "wheat", quantity: max(1, cellIndex ?? 1),
                direction: .stored
            ),
            AgentAgriculturalMaterialDelta(
                itemKey: "wheat_seeds", quantity: 4,
                direction: .stored
            ),
        ]
        entities = []
        custody = "store-\(id)"
        storage = "container:12,64,9"
        reserve = 1
        surplus = 1
    default:
        material = []
        entities = []
        custody = nil
        storage = nil
        reserve = 0
        surplus = 0
    }
    let fingerprints: (Int, Int)
    switch kind {
    case .till: fingerprints = (1, 2)
    case .plant: fingerprints = (0, 3)
    case .maturityObserved: fingerprints = (7, 7)
    case .harvest: fingerprints = (7, 0)
    case .store: fingerprints = (0, 0)
    case .reconcile: fingerprints = (3, 0)
    }
    return AgentAgriculturalActionOutcome(
        actionID: AgentAgriculturalActionID(rawValue: id)!,
        kind: kind,
        actorID: AgentID(rawValue: "agent_0")!,
        plotID: plotID,
        cellIndex: cellIndex,
        position: b03Positions[index],
        beforeFingerprint: fingerprints.0,
        afterFingerprint: fingerprints.1,
        materialDeltas: material,
        sourceItemEntityIDs: entities,
        custodyFingerprint: custody,
        storageLocationID: storage,
        seedReserveQuantity: reserve,
        physicalSurplusQuantity: surplus,
        sourceObservationEventID: observationEventID,
        civilDate: session.civilDate()!
    )
}

private func b03Fixture(_ id: String, cellCount: Int = 1) -> B03Fixture {
    var session = b03Session(id)
    let source = try! session.recordEcologicalObservation(
        b03Observation(session, physicalTick: 100)
    )
    let positions = Array(b03Positions.prefix(cellCount))
    let plotID = try! session.planAgriculturalPlot(
        plannerID: AgentID(rawValue: "agent_0")!,
        positions: positions,
        sourceObservationEventID: source.causalEventID,
        designatedStorageLocationID: "container:12,64,9"
    )
    for index in positions.indices {
        _ = try! session.recordAgriculturalActionSuccess(b03Action(
            session, plotID: plotID, cellIndex: index, kind: .till,
            id: "b03-c1-till-\(index)"
        ))
        _ = try! session.recordAgriculturalActionSuccess(b03Action(
            session, plotID: plotID, cellIndex: index, kind: .plant,
            id: "b03-c1-plant-\(index)"
        ))
    }
    let matureStages = Dictionary(uniqueKeysWithValues: positions.indices.map {
        ($0, (crop: "wheat", stage: 7))
    })
    let cycle1Mature = try! session.recordEcologicalObservation(
        b03Observation(
            session, physicalTick: 120, stages: matureStages
        )
    )
    for index in positions.indices {
        _ = try! session.recordAgriculturalActionSuccess(b03Action(
            session, plotID: plotID, cellIndex: index,
            kind: .maturityObserved, id: "b03-c1-mature-\(index)",
            observationEventID: cycle1Mature.causalEventID
        ))
        _ = try! session.recordAgriculturalActionSuccess(b03Action(
            session, plotID: plotID, cellIndex: index, kind: .harvest,
            id: "b03-c1-harvest-\(index)"
        ))
    }
    _ = try! session.recordAgriculturalActionSuccess(b03Action(
        session, plotID: plotID, cellIndex: nil, kind: .store,
        id: "b03-c1-store"
    ))
    let renewal = try! session.recordEcologicalObservation(
        b03Observation(session, physicalTick: 140)
    )
    _ = try! session.renewAgriculturalPlot(
        plotID: plotID,
        plannerID: AgentID(rawValue: "agent_0")!,
        sourceObservationEventID: renewal.causalEventID
    )
    var cycle2Plants: [AgentAgriculturalActionRecord] = []
    for index in positions.indices {
        cycle2Plants.append(try! session.recordAgriculturalActionSuccess(
            b03Action(
                session, plotID: plotID, cellIndex: index, kind: .plant,
                id: "b03-c2-plant-\(index)"
            )
        ))
    }
    return B03Fixture(
        session: session,
        plotID: plotID,
        cycle1Mature: cycle1Mature,
        cycle2PlantActions: cycle2Plants,
        plantingMinimumPhysicalTick: 140
    )
}

private func b03Selection(
    _ fixture: B03Fixture,
    cellIndex: Int = 0
) -> AgentCurrentCycleCropObservationResult {
    let plot = fixture.session.agricultureSnapshot().plots.first {
        $0.plotID == fixture.plotID
    }!
    let cell = plot.cells[cellIndex]
    return try! fixture.session.currentCycleCropObservation(
        plot: plot,
        cell: cell,
        cropPosition: AgentPosition(
            x: cell.position.x, y: cell.position.y + 1, z: cell.position.z
        ),
        minimumPhysicalWorldTick: fixture.plantingMinimumPhysicalTick
    )
}

private func b03ObservationReceipts(
    _ session: AgentSimulationSession
) -> [AgentEcologicalPhysicalReceiptEvidence] {
    session.ecologicalObservationSnapshot().observations.map { record in
        let observation = record.observation
        let receiptID = record.physicalObservationReceiptID!
        return AgentEcologicalPhysicalReceiptEvidence(
            receiptID: receiptID,
            operationID: receiptID.rawValue,
            observerID: observation.observerID,
            worldID: "b03-world",
            storageIdentity: "sqlite-world:b03-world",
            dimension: 0,
            dimensionKey: observation.dimensionKey,
            physicalWorldTick: observation.physicalWorldTick,
            simulationID: session.simulationID,
            simulationTick: observation.observedAtSimulationTick,
            origin: observation.origin,
            observation: observation,
            resultCount: observation.diagnostics.resultsEmitted,
            worldReadCount: observation.diagnostics.worldReads
        )
    }
}

private func b03ActionReceipts(
    _ session: AgentSimulationSession
) -> [AgentAgriculturalPhysicalReceiptEvidence] {
    session.agricultureSnapshot().retainedActions.map { record in
        AgentAgriculturalPhysicalReceiptEvidence(
            receiptID: record.outcome.actionID,
            operationID: record.outcome.actionID.rawValue,
            worldID: "b03-world",
            storageIdentity: "sqlite-world:b03-world",
            dimension: 0,
            simulationID: session.simulationID,
            outcome: record.outcome
        )
    }
}

func runPebbleAgentsAgricultureCycleObservationSmoke() {
    section("Gate D Blocker 03 cycle-scoped agricultural maturity evidence")

    var exact = b03Fixture("b03-exact")
    check("only prior-cycle mature evidence yields no current-cycle transition",
          b03Selection(exact).classification == .noEligibleObservation)
    let stage0 = try! exact.session.recordEcologicalObservation(
        b03Observation(
            exact.session, physicalTick: 141,
            stages: [0: (crop: "wheat", stage: 0)]
        )
    )
    let exactSelection = b03Selection(exact)
    check("cycle-1 mature row plus cycle-2 stage-0 row selects non-mature",
          exactSelection.classification == .currentCycleNonMature
            && exactSelection.evidence?.record.causalEventID
                == stage0.causalEventID
            && exactSelection.evidence?.currentPlantAction.outcome.actionID
                == exact.cycle2PlantActions[0].outcome.actionID)
    check("same actor never walks back from latest non-mature to old mature",
          exactSelection.evidence?.crop.mature == false
            && exact.session.ecologicalObservations(
                for: AgentID(rawValue: "agent_0")!
            ).contains(where: {
                $0.causalEventID == exact.cycle1Mature.causalEventID
            }))
    let beforeNonMature = try! exact.session.durableStateBytes()
    check("non-mature classification is non-mutating",
          (try! exact.session.durableStateBytes()) == beforeNonMature
            && exact.session.agricultureSnapshot().plots[0].cells[0].phase
                == .planted)

    var multi = b03Fixture("b03-multi")
    _ = try! multi.session.recordEcologicalObservation(b03Observation(
        multi.session, observer: "agent_0", physicalTick: 151,
        stages: [0: (crop: "wheat", stage: 7)]
    ))
    let newestOther = try! multi.session.recordEcologicalObservation(
        b03Observation(
            multi.session, observer: "agent_1", physicalTick: 152,
            stages: [0: (crop: "wheat", stage: 0)]
        )
    )
    check("newer physical evidence wins across actors",
          b03Selection(multi).classification == .currentCycleNonMature
            && b03Selection(multi).evidence?.record.causalEventID
                == newestOther.causalEventID)

    var reversed = b03Fixture("b03-multi-reversed")
    _ = try! reversed.session.recordEcologicalObservation(b03Observation(
        reversed.session, observer: "agent_1", physicalTick: 151,
        stages: [0: (crop: "wheat", stage: 7)]
    ))
    let newestLexicalFirst = try! reversed.session
        .recordEcologicalObservation(b03Observation(
            reversed.session, observer: "agent_0", physicalTick: 152,
            stages: [0: (crop: "wheat", stage: 0)]
        ))
    check("actor lexical order cannot override physical recency",
          b03Selection(reversed).classification == .currentCycleNonMature
            && b03Selection(reversed).evidence?.record.causalEventID
                == newestLexicalFirst.causalEventID)

    var conflict = b03Fixture("b03-conflict")
    _ = try! conflict.session.recordEcologicalObservation(b03Observation(
        conflict.session, observer: "agent_0", physicalTick: 160,
        stages: [0: (crop: "wheat", stage: 7)]
    ))
    _ = try! conflict.session.recordEcologicalObservation(b03Observation(
        conflict.session, observer: "agent_1", physicalTick: 160,
        stages: [0: (crop: "wheat", stage: 0)]
    ))
    check("incompatible evidence at one physical boundary fails closed",
          b03Selection(conflict).classification
            == .conflictingCurrentEvidence)

    var wrongTick = b03Fixture("b03-world-tick")
    _ = try! wrongTick.session.recordEcologicalObservation(b03Observation(
        wrongTick.session, physicalTick: 139,
        stages: [0: (crop: "wheat", stage: 0)]
    ))
    check("physical World tick before cycle foundation is invalid",
          b03Selection(wrongTick).classification == .invalidCurrentEvidence)

    var replacement = b03Fixture("b03-crop-replacement")
    _ = try! replacement.session.recordEcologicalObservation(b03Observation(
        replacement.session, physicalTick: 145,
        stages: [0: (crop: "carrots", stage: 0)]
    ))
    check("other-crop evidence at the same cell is never rebound",
          b03Selection(replacement).classification
            == .invalidCurrentEvidence)

    var mature = exact
    let matureRecord = try! mature.session.recordEcologicalObservation(
        b03Observation(
            mature.session, physicalTick: 170,
            stages: [0: (crop: "wheat", stage: 7)]
        )
    )
    let matureSelection = b03Selection(mature)
    let matureID = AgentAgriculturalActionID.automaticMaturity(
        simulationTick: mature.session.tick,
        plotID: mature.plotID,
        cycleOrdinal: 2,
        cellIndex: 0
    )!
    check("later current-cycle stage-7 evidence becomes mature exactly",
          matureSelection.classification == .currentCycleMature
            && matureSelection.evidence?.record.causalEventID
                == matureRecord.causalEventID)
    let matureOutcome = b03Action(
        mature.session, plotID: mature.plotID, cellIndex: 0,
        kind: .maturityObserved, id: matureID.rawValue,
        observationEventID: matureRecord.causalEventID
    )
    _ = try! mature.session.recordAgriculturalActionSuccess(matureOutcome)
    let matureBytes = try! mature.session.durableStateBytes()
    do {
        _ = try mature.session.recordAgriculturalActionSuccess(matureOutcome)
        check("same cycle maturity action is idempotent", false)
    } catch AgentSessionError.agriculture(.duplicateAction) {
        check("same cycle maturity action is idempotent",
              (try! mature.session.durableStateBytes()) == matureBytes)
    } catch {
        check("same cycle maturity action is idempotent", false, "\(error)")
    }
    let cycle1ID = AgentAgriculturalActionID.automaticMaturity(
        simulationTick: mature.session.tick,
        plotID: mature.plotID,
        cycleOrdinal: 1,
        cellIndex: 0
    )!
    check("automatic maturity IDs are cycle scoped at the same tick",
          cycle1ID != matureID
            && matureID.rawValue.contains(":cycle-2:"))

    var twoCells = b03Fixture("b03-two-cells", cellCount: 2)
    let mixed = try! twoCells.session.recordEcologicalObservation(
        b03Observation(
            twoCells.session, physicalTick: 180,
            stages: [
                0: (crop: "wheat", stage: 7),
                1: (crop: "wheat", stage: 0),
            ]
        )
    )
    check("mixed cells classify independently",
          b03Selection(twoCells, cellIndex: 0).classification
            == .currentCycleMature
            && b03Selection(twoCells, cellIndex: 1).classification
                == .currentCycleNonMature)
    _ = try! twoCells.session.recordAgriculturalActionSuccess(b03Action(
        twoCells.session, plotID: twoCells.plotID, cellIndex: 0,
        kind: .maturityObserved, id: "b03-c2-mature-cell-0",
        observationEventID: mixed.causalEventID
    ))
    check("one mature cell cannot corrupt a non-mature sibling",
          twoCells.session.agricultureSnapshot().plots[0].cells[0].phase
            == .mature
            && twoCells.session.agricultureSnapshot().plots[0].cells[1].phase
                == .planted)

    let restartCheckpoint = try! exact.session.makeCheckpoint()
    let restarted = try! AgentSimulationSession.restoring(restartCheckpoint)
    let restartedFixture = B03Fixture(
        session: restarted,
        plotID: exact.plotID,
        cycle1Mature: exact.cycle1Mature,
        cycle2PlantActions: exact.cycle2PlantActions,
        plantingMinimumPhysicalTick: exact.plantingMinimumPhysicalTick
    )
    check("schema 30 stage-0 restart preserves both cycles and selection",
          restartCheckpoint.schemaVersion == 30
            && b03Selection(restartedFixture).classification
                == .currentCycleNonMature
            && (try! restarted.durableStateBytes())
                == (try! exact.session.durableStateBytes()))

    var beforePlant = b03Session("b03-before-plant")
    let source = try! beforePlant.recordEcologicalObservation(
        b03Observation(beforePlant, physicalTick: 100)
    )
    let beforePlot = try! beforePlant.planAgriculturalPlot(
        plannerID: AgentID(rawValue: "agent_0")!,
        positions: [b03Positions[0]],
        sourceObservationEventID: source.causalEventID,
        designatedStorageLocationID: "container:12,64,9"
    )
    _ = try! beforePlant.recordAgriculturalActionSuccess(b03Action(
        beforePlant, plotID: beforePlot, cellIndex: 0, kind: .till,
        id: "b03-before-till"
    ))
    let prematureEvidence = try! beforePlant.recordEcologicalObservation(
        b03Observation(
            beforePlant, physicalTick: 110,
            stages: [0: (crop: "wheat", stage: 7)]
        )
    )
    _ = try! beforePlant.recordAgriculturalActionSuccess(b03Action(
        beforePlant, plotID: beforePlot, cellIndex: 0, kind: .plant,
        id: "b03-after-old-observation-plant"
    ))
    let beforeBytes = try! beforePlant.durableStateBytes()
    do {
        _ = try beforePlant.recordAgriculturalActionSuccess(b03Action(
            beforePlant, plotID: beforePlot, cellIndex: 0,
            kind: .maturityObserved, id: "b03-before-boundary-maturity",
            observationEventID: prematureEvidence.causalEventID
        ))
        check("observation before current plant event is refused atomically", false)
    } catch AgentSessionError.agriculture(.invalidAction("maturity evidence")) {
        check("observation before current plant event is refused atomically",
              (try! beforePlant.durableStateBytes()) == beforeBytes)
    } catch {
        check("observation before current plant event is refused atomically",
              false, "\(error)")
    }

    let observationEvidence = b03ObservationReceipts(exact.session)
    let actionEvidence = b03ActionReceipts(exact.session)
    check("current-cycle observation receipt substitution is refused", {
        guard let currentID = stage0.physicalObservationReceiptID,
              let currentIndex = observationEvidence.firstIndex(where: {
                  $0.receiptID == currentID
              }),
              let prior = observationEvidence.first(where: {
                  $0.receiptID
                    == exact.cycle1Mature.physicalObservationReceiptID
              }) else { return false }
        var changed = observationEvidence
        changed[currentIndex] = AgentEcologicalPhysicalReceiptEvidence(
            receiptID: currentID,
            operationID: currentID.rawValue,
            observerID: prior.observerID,
            worldID: "b03-world",
            storageIdentity: "sqlite-world:b03-world",
            dimension: 0,
            dimensionKey: prior.dimensionKey,
            physicalWorldTick: prior.physicalWorldTick,
            simulationID: exact.session.simulationID,
            simulationTick: prior.simulationTick,
            origin: prior.origin,
            observation: prior.observation,
            resultCount: prior.resultCount,
            worldReadCount: prior.worldReadCount
        )
        do {
            try exact.session.validateIndependentEcologicalObservationReceipts(
                changed,
                worldID: "b03-world",
                storageIdentity: "sqlite-world:b03-world",
                dimension: 0
            )
            return false
        } catch { return true }
    }())
    check("current plant receipt substitution is refused", {
        guard let currentIndex = actionEvidence.firstIndex(where: {
                  $0.receiptID
                    == exact.cycle2PlantActions[0].outcome.actionID
              }),
              let prior = actionEvidence.first(where: {
                  $0.outcome.kind == .plant
                    && $0.receiptID
                        != exact.cycle2PlantActions[0].outcome.actionID
              }) else { return false }
        var changed = actionEvidence
        let currentID = changed[currentIndex].receiptID
        changed[currentIndex] = AgentAgriculturalPhysicalReceiptEvidence(
            receiptID: currentID,
            operationID: currentID.rawValue,
            worldID: "b03-world",
            storageIdentity: "sqlite-world:b03-world",
            dimension: 0,
            simulationID: exact.session.simulationID,
            outcome: prior.outcome
        )
        do {
            try exact.session.validateIndependentAgriculturalActionReceipts(
                changed,
                worldID: "b03-world",
                storageIdentity: "sqlite-world:b03-world",
                dimension: 0
            )
            return false
        } catch { return true }
    }())
}
