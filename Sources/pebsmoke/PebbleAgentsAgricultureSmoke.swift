import Foundation
import PebbleAgents

private let agricultureSoils = [
    AgentPosition(x: 1, y: 63, z: 0),
    AgentPosition(x: 1, y: 63, z: 1),
]
private let agricultureLifecycle = try! AgentLifecycleConfiguration(
    newbornDurationTicks: 8,
    maturityAgeTicks: 24,
    reproductionEvaluationIntervalTicks: 1,
    reproductionPlanDelayTicks: 1,
    reproductionCooldownTicks: 1,
    maximumRetainedBirthRecords: 32,
    maximumRetainedPlanRecords: 32,
    maximumParentBirthCount: 16
)

private func agricultureAgent(_ index: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: index, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_\(index)", state: "idle", position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "agriculture fixture", startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func agricultureBase(
    _ id: String,
    causalMaximumEvents: Int = 16_384,
    preRegistrationCausalEvents: Int = 0
) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 46, memoryPolicy: .bounded(maxEntries: 128)
        ),
        agents: [agricultureAgent(0), agricultureAgent(1), agricultureAgent(2)],
        simulationID: AgentSimulationID(rawValue: id)!,
        causalLedgerPolicy: .bounded(maxEvents: causalMaximumEvents)
    )
    for index in 0..<preRegistrationCausalEvents {
        session.setEconomyEnabled(index.isMultiple(of: 2))
    }
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 2)
    )
    try! session.setLifecycleEnabled(true, configuration: agricultureLifecycle)
    try! session.setSkillsEnabled(true)
    return session
}

private func agricultureRestoreRefused(
    _ checkpoint: AgentSessionCheckpoint,
    mutate: (inout [String: Any]) -> Void
) -> Bool {
    do {
        var root = try JSONSerialization.jsonObject(
            with: AgentCheckpointCodec.encode(checkpoint)
        ) as! [String: Any]
        var durable = root["durableState"] as! [String: Any]
        mutate(&durable)
        let mutationBytes = try JSONSerialization.data(
            withJSONObject: durable,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
        let state = try AgentCheckpointCodec.decode(
            AgentSessionDurableState.self, from: mutationBytes
        )
        let durableBytes = try AgentCheckpointCodec.encode(state)
        let canonical = try JSONSerialization.jsonObject(
            with: durableBytes
        ) as! [String: Any]
        let clock = canonical["clock"] as! [String: Any]
        let simulationID = clock["simulationID"] as! String
        let tick = clock["tick"] as! Int
        let digest = AgentCheckpointDigest.sha256(durableBytes)
        let simulationDigest = AgentCheckpointDigest.sha256(
            Data(simulationID.utf8)
        )
        root["durableState"] = canonical
        root["schemaVersion"] = canonical["schemaVersion"]
        root["semanticDigest"] = digest.rawValue
        root["checkpointID"] =
            "checkpoint-\(simulationDigest.rawValue.prefix(12))"
                + "-t\(tick)-\(digest.rawValue.prefix(16))"
        let resigned = try AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self,
            from: JSONSerialization.data(
                withJSONObject: root,
                options: [.sortedKeys, .withoutEscapingSlashes]
            )
        )
        _ = try AgentSimulationSession.restoring(resigned)
        return false
    } catch {
        return true
    }
}

private func agricultureObservation(
    _ session: AgentSimulationSession,
    mature: Bool = false,
    observer: String = "agent_0"
) -> AgentEcologicalObservation {
    let configuration = session.ecologicalObservationSnapshot().configuration!
    let crops = mature ? agricultureSoils.map {
        AgentCropObservation(
            cropKey: "wheat",
            position: AgentPosition(x: $0.x, y: $0.y + 1, z: $0.z),
            growthStage: 7, maximumGrowthStage: 7, mature: true,
            supportBlockKey: "farmland"
        )
    } : []
    let resultCount = 1 + 1 + agricultureSoils.count + crops.count + 2
    return AgentEcologicalObservation(
        observerID: AgentID(rawValue: observer)!,
        origin: AgentPosition(x: 0, y: 64, z: 0),
        worldContextKey: "world-seed-46", dimensionKey: "overworld",
        observedAtSimulationTick: session.tick, physicalWorldTick: 120,
        civilDate: session.civilDate()!,
        biome: AgentBiomeObservation(
            biomeKey: "plains", position: AgentPosition(x: 0, y: 64, z: 0)
        ),
        water: [AgentWaterAffordance(
            fluidKey: "water", position: AgentPosition(x: 2, y: 63, z: 0),
            sourceBlock: true
        )],
        soils: agricultureSoils.map {
            AgentSoilAffordance(
                blockKey: mature ? "farmland" : "dirt", position: $0,
                tillable: !mature, alreadyFarmland: mature,
                hydrated: mature ? true : nil, supportsCrop: true
            )
        },
        crops: crops, plants: [], animals: [], fishing: [],
        weather: AgentWeatherObservation(kind: .clear, raining: false, thundering: false),
        physicalTime: AgentPhysicalWorldTimeObservation(
            worldTick: 120, dayTime: 120, timeOfDay: .day,
            daylightCycleEnabled: true
        ),
        diagnostics: AgentEcologicalScanDiagnostics(
            radius: 4, cellsConsidered: 405, worldReads: 405,
            chunksTouched: 1, chunksUnavailable: 0, entitiesConsidered: 0,
            resultsEmitted: resultCount, cacheHits: 0, cacheMisses: 1,
            completion: .complete
        ),
        expiresAtSimulationTick: session.tick + configuration.dynamicFreshnessTicks
    )
}

private func agricultureAction(
    _ session: AgentSimulationSession,
    plotID: AgentAgriculturalPlotID,
    cellIndex: Int?,
    kind: AgentAgriculturalActionKind,
    suffix: String,
    observationEventID: AgentCausalEventID? = nil,
    actor: String = "agent_0"
) -> AgentAgriculturalActionOutcome {
    let position = cellIndex.map { agricultureSoils[$0] } ?? agricultureSoils[0]
    let deltas: [AgentAgriculturalMaterialDelta]
    let entities: [Int]
    let custody: String?
    let storage: String?
    let reserve: Int
    let surplus: Int
    switch kind {
    case .plant:
        deltas = [AgentAgriculturalMaterialDelta(
            itemKey: "wheat_seeds", quantity: 1, direction: .consumed
        )]
        entities = []
        custody = "actor-after-plant-\(suffix)"
        storage = nil
        reserve = 0
        surplus = 0
    case .harvest:
        deltas = [
            AgentAgriculturalMaterialDelta(
                itemKey: "wheat", quantity: 1, direction: .acquired
            ),
            AgentAgriculturalMaterialDelta(
                itemKey: "wheat_seeds", quantity: 2, direction: .acquired
            ),
        ]
        entities = [cellIndex! * 2 + 1, cellIndex! * 2 + 2]
        custody = "actor-after-harvest-\(suffix)"
        storage = nil
        reserve = 0
        surplus = 0
    case .store:
        deltas = [
            AgentAgriculturalMaterialDelta(
                itemKey: "wheat", quantity: 2, direction: .stored
            ),
            AgentAgriculturalMaterialDelta(
                itemKey: "wheat_seeds", quantity: 4, direction: .stored
            ),
        ]
        entities = []
        custody = "container-after-store"
        storage = "container:4,64,0"
        reserve = 2
        surplus = 2
    default:
        deltas = []
        entities = []
        custody = nil
        storage = nil
        reserve = 0
        surplus = 0
    }
    let before: Int
    let after: Int
    switch kind {
    case .till: before = 1; after = 2
    case .plant: before = 0; after = 3
    case .maturityObserved: before = 7; after = 7
    case .harvest: before = 7; after = 0
    case .store: before = 0; after = 0
    case .reconcile: before = 3; after = 0
    }
    return AgentAgriculturalActionOutcome(
        actionID: AgentAgriculturalActionID(rawValue: "agriculture-\(suffix)")!,
        kind: kind, actorID: AgentID(rawValue: actor)!,
        plotID: plotID, cellIndex: cellIndex, position: position,
        beforeFingerprint: before, afterFingerprint: after,
        materialDeltas: deltas, sourceItemEntityIDs: entities,
        custodyFingerprint: custody, storageLocationID: storage,
        seedReserveQuantity: reserve, physicalSurplusQuantity: surplus,
        sourceObservationEventID: observationEventID,
        civilDate: session.civilDate()!
    )
}

func runPebbleAgentsAgricultureSmoke() {
    section("PebbleAgents bounded agriculture and managed surplus")

    check("agriculture gate is default off", !agricultureBase("agriculture-off").agricultureEnabled)
    check("agriculture activation requires ecological observation atomically", {
        var value = agricultureBase("agriculture-no-observation")
        let before = try! value.durableStateBytes()
        do {
            try value.setAgricultureEnabled(true)
            return false
        } catch AgentSessionError.agriculture(.ecologicalObservationRequired) {
            return !value.agricultureEnabled && (try! value.durableStateBytes()) == before
        } catch { return false }
    }())

    var session = agricultureBase("agriculture-contract")
    try! session.setEcologicalObservationEnabled(true)
    let observationRecord = try! session.recordEcologicalObservation(
        agricultureObservation(session)
    )
    let v12 = try! session.makeCheckpoint()
    let v12Restored = try! AgentSimulationSession.restoring(v12)
    check("v12 checkpoint remains loadable with agriculture empty",
          v12.schemaVersion == 12 && !v12Restored.agricultureEnabled
            && (try! v12Restored.durableStateBytes()) == (try! session.durableStateBytes()))

    let coarseBefore = session.snapshot()
    try! session.setAgricultureEnabled(true)
    check("agriculture activation promotes v13 without retroactive farms",
          session.durableState().schemaVersion == 13
            && session.agricultureSnapshot().plots.isEmpty
            && session.agricultureSnapshot().managedSurplusRecords.isEmpty)
    let plotID = try! session.planAgriculturalPlot(
        plannerID: AgentID(rawValue: "agent_0")!, positions: agricultureSoils,
        sourceObservationEventID: observationRecord.causalEventID,
        designatedStorageLocationID: "container:4,64,0"
    )
    check("fresh CIV-21 evidence creates one deterministic two-cell plot",
          session.agricultureSnapshot().plots.first?.plotID == plotID
            && session.agricultureSnapshot().plots.first?.cells.count == 2)
    check("agriculture gate changes a real decision seam",
          session.nextAgriculturalIntent(for: AgentID(rawValue: "agent_0")!)?.kind == .till)

    let conflict = try! session.reserveAgriculturalCell(
        plotID: plotID, cellIndex: 0,
        contenders: [AgentID(rawValue: "agent_1")!, AgentID(rawValue: "agent_0")!]
    )
    check("multi-agent work conflict has stable AgentID winner",
          conflict.agentID == AgentID(rawValue: "agent_0")!)
    let repeatedConflict = try! session.reserveAgriculturalCell(
        plotID: plotID, cellIndex: 0,
        contenders: [AgentID(rawValue: "agent_1")!, AgentID(rawValue: "agent_0")!]
    )
    check("one agricultural cell has at most one active reservation",
          repeatedConflict == conflict && session.agricultureSnapshot().reservations.count == 1)

    for index in agricultureSoils.indices {
        _ = try! session.recordAgriculturalActionSuccess(agricultureAction(
            session, plotID: plotID, cellIndex: index, kind: .till,
            suffix: "till-\(index)"
        ))
        _ = try! session.recordAgriculturalActionSuccess(agricultureAction(
            session, plotID: plotID, cellIndex: index, kind: .plant,
            suffix: "plant-\(index)"
        ))
    }
    check("multi-cell preparation and planting are ordered partial work",
          session.agricultureSnapshot().plots[0].cells.allSatisfy { $0.phase == .planted }
            && session.agricultureSnapshot().plots[0].phase == .growing)
    check("immature planted cells expose no harvest intent",
          session.nextAgriculturalIntent(
            for: AgentID(rawValue: "agent_0")!
          ) == nil)
    let partialCheckpoint = try! session.makeCheckpoint()
    let partialRestored = try! AgentSimulationSession.restoring(partialCheckpoint)
    check("v13 checkpoint preserves a planted active plot without World invention",
          partialCheckpoint.schemaVersion == 13
            && partialRestored.agricultureSnapshot() == session.agricultureSnapshot()
            && partialRestored.agricultureSnapshot().plots[0].phase == .growing)
    let practiceBeforeInvalid = session.practiceUnits(
        agentID: AgentID(rawValue: "agent_0")!, domain: .cultivation
    )
    let invalidBytes = try! session.durableStateBytes()
    do {
        _ = try session.recordAgriculturalActionSuccess(agricultureAction(
            session, plotID: plotID, cellIndex: 0, kind: .harvest,
            suffix: "immature-harvest"
        ))
        check("failed immature harvest grants zero practice atomically", false)
    } catch AgentSessionError.agriculture(.invalidAction) {
        check("failed immature harvest grants zero practice atomically",
              session.practiceUnits(
                agentID: AgentID(rawValue: "agent_0")!, domain: .cultivation
              ) == practiceBeforeInvalid
                && (try! session.durableStateBytes()) == invalidBytes)
    } catch {
        check("failed immature harvest grants zero practice atomically", false, "\(error)")
    }

    let matureRecord = try! session.recordEcologicalObservation(
        agricultureObservation(session, mature: true)
    )
    for index in agricultureSoils.indices {
        _ = try! session.recordAgriculturalActionSuccess(agricultureAction(
            session, plotID: plotID, cellIndex: index, kind: .maturityObserved,
            suffix: "mature-\(index)", observationEventID: matureRecord.causalEventID
        ))
        _ = try! session.recordAgriculturalActionSuccess(agricultureAction(
            session, plotID: plotID, cellIndex: index, kind: .harvest,
            suffix: "harvest-\(index)"
        ))
    }
    let beforeStoreBytes = try! session.durableStateBytes()
    let store = try! session.recordAgriculturalActionSuccess(agricultureAction(
        session, plotID: plotID, cellIndex: nil, kind: .store, suffix: "store"
    ))
    check("physical seed reserve and surplus are historical evidence only",
          store.outcome.seedReserveQuantity == 2
            && store.outcome.physicalSurplusQuantity == 2
            && session.agricultureSnapshot().managedSurplusRecords.last?.seedReserveTarget == 2)
    check("two-cell full cycle completes exactly once",
          session.agricultureSnapshot().completedCycleCount == 1
            && session.agricultureSnapshot().plots[0].phase == .cycleCompleted)
    check("cultivation practice comes only from till plant harvest successes",
          session.practiceUnits(
            agentID: AgentID(rawValue: "agent_0")!, domain: .cultivation
          ) == 6)
    let renewalObservation = try! session.recordEcologicalObservation(
        agricultureObservation(session, mature: true)
    )
    let renewalPractice = session.practiceUnits(
        agentID: AgentID(rawValue: "agent_0")!, domain: .cultivation
    )
    _ = try! session.renewAgriculturalPlot(
        plotID: plotID,
        plannerID: AgentID(rawValue: "agent_0")!,
        sourceObservationEventID: renewalObservation.causalEventID
    )
    check("fresh observed farmland reopens the same bounded plot",
          session.agricultureSnapshot().plots[0].phase == .planting
            && session.agricultureSnapshot().plots[0].cells.allSatisfy {
                $0.phase == .prepared
            }
            && session.nextAgriculturalIntent(
                for: AgentID(rawValue: "agent_0")!
            )?.kind == .plant)
    check("plot renewal creates no practice or material success",
          session.practiceUnits(
              agentID: AgentID(rawValue: "agent_0")!, domain: .cultivation
          ) == renewalPractice
            && session.agricultureSnapshot().completedCycleCount == 1)

    try! session.setTeachingEnabled(true)
    let teacherID = AgentID(rawValue: "agent_0")!
    let studentID = AgentID(rawValue: "agent_1")!
    let engagement = try! session.selectMentorAndStartApprenticeship(
        AgentMentorSelectionRequest(
            requestID: "cultivation-apprenticeship", studentID: studentID,
            domain: .cultivation, studentAccepts: true,
            candidates: [AgentMentorCandidateConsent(
                teacherID: teacherID, accepts: true
            )],
            requestedAtTick: session.tick
        )
    )!
    _ = try! session.advanceTick()
    let teachingSourceObservation = try! session.recordEcologicalObservation(
        agricultureObservation(session)
    )
    let teachingPlot = try! session.planAgriculturalPlot(
        plannerID: teacherID, positions: agricultureSoils,
        sourceObservationEventID: teachingSourceObservation.causalEventID,
        designatedStorageLocationID: "container:6,64,0"
    )
    let teacherSource = try! session.recordAgriculturalActionSuccess(agricultureAction(
        session, plotID: teachingPlot, cellIndex: 0, kind: .till,
        suffix: "teacher-demonstration-till"
    )).agricultureEventID
    let teacherPosition = try! session.state(for: teacherID).position
    let studentPosition = try! session.state(for: studentID).position
    let physical = session.configuration.physicalChannelConfiguration
    let studentBeforeTeaching = session.practiceUnits(
        agentID: studentID, domain: .cultivation
    )
    let exposure = try! session.recordTeachingDemonstration(AgentTeachingObservation(
        apprenticeshipID: engagement.apprenticeshipID,
        teacherID: teacherID, studentID: studentID, domain: .cultivation,
        sourceSuccessEventID: teacherSource,
        teacherPosition: teacherPosition, studentPosition: studentPosition,
        distanceManhattan: 1,
        soundClarity: physical.soundClarity(
            distanceManhattan: 1, opaqueOcclusionCount: 0
        ),
        gestureClarity: physical.gestureClarity(
            distanceManhattan: 1, lineOfSight: true
        ),
        opaqueOcclusionCount: 0, lineOfSight: true, chunksReady: true,
        observedAtTick: session.tick
    ))
    check("Teaching accepts real cultivation provenance without granting skill",
          exposure.domain == .cultivation
            && session.practiceUnits(agentID: studentID, domain: .cultivation)
                == studentBeforeTeaching)

    let studentObservation = try! session.recordEcologicalObservation(
        agricultureObservation(session, observer: "agent_1")
    )
    let studentPlot = try! session.planAgriculturalPlot(
        plannerID: studentID, positions: agricultureSoils,
        sourceObservationEventID: studentObservation.causalEventID,
        designatedStorageLocationID: "container:5,64,0"
    )
    _ = try! session.recordAgriculturalActionSuccess(agricultureAction(
        session, plotID: studentPlot, cellIndex: 0, kind: .till,
        suffix: "student-till", actor: "agent_1"
    ))
    check("student own real cultivation success grants exactly one practice",
          session.practiceUnits(agentID: studentID, domain: .cultivation)
            == studentBeforeTeaching + 1)
    check("agriculture creates zero ghost coarse material credit",
          session.snapshot().campStock == coarseBefore.campStock
            && session.snapshot().conservation == coarseBefore.conservation
            && session.snapshot().agents.map(\.resourceInventory)
                == coarseBefore.agents.map(\.resourceInventory))

    let duplicateBytes = try! session.durableStateBytes()
    do {
        _ = try session.recordAgriculturalActionSuccess(agricultureAction(
            session, plotID: plotID, cellIndex: nil, kind: .store, suffix: "store"
        ))
        check("duplicate agricultural outcome is atomic", false)
    } catch AgentSessionError.agriculture(.duplicateAction) {
        check("duplicate agricultural outcome is atomic",
              (try! session.durableStateBytes()) == duplicateBytes)
    } catch {
        check("duplicate agricultural outcome is atomic", false, "\(error)")
    }
    check("storage action changed durable history exactly once", beforeStoreBytes != duplicateBytes)

    let checkpoint = try! session.makeCheckpoint()
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    check("renewed agriculture checkpoint promotes v29 and restarts byte exact",
          checkpoint.schemaVersion == 29
            && (try! restored.durableStateBytes()) == (try! session.durableStateBytes()))

    var causalRetention = agricultureBase(
        "agriculture-exact-causal-retention",
        causalMaximumEvents: 64,
        preRegistrationCausalEvents: 60
    )
    try! causalRetention.setEcologicalObservationEnabled(true)
    let retentionObservation = try! causalRetention
        .recordEcologicalObservation(agricultureObservation(causalRetention))
    try! causalRetention.setAgricultureEnabled(true)
    let retentionPlot = try! causalRetention.planAgriculturalPlot(
        plannerID: AgentID(rawValue: "agent_0")!,
        positions: agricultureSoils,
        sourceObservationEventID: retentionObservation.causalEventID,
        designatedStorageLocationID: "container:9,64,0"
    )
    let retentionAction = try! causalRetention
        .recordAgriculturalActionSuccess(agricultureAction(
            causalRetention,
            plotID: retentionPlot,
            cellIndex: 0,
            kind: .till,
            suffix: "retention-till"
        ))
    let retentionCheckpoint = try! causalRetention.makeCheckpoint()
    let droppedSequence = causalRetention.causalLedgerSnapshot()
        .summary.droppedEventCount
    let droppedEventJSON = try! JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(AgentCausalEventID(
            simulationID: causalRetention.simulationID,
            sequence: AgentCausalSequence(
                rawValue: max(1, droppedSequence)
            )!
        ))
    ) as! [String: Any]
    check("agriculture fixture has an unrelated evicted causal prefix",
          droppedSequence > 0
            && causalRetention.causalLedgerSnapshot().events.contains(where: {
                $0.eventID == retentionObservation.causalEventID
            })
            && causalRetention.causalLedgerSnapshot().events.contains(where: {
                $0.eventID == retentionAction.agricultureEventID
            }))
    check("evicted source-observation ID cannot authorize retained plot",
          agricultureRestoreRefused(retentionCheckpoint) { durable in
              var agriculture = durable["agricultureState"] as! [String: Any]
              var plots = agriculture["plots"] as! [[String: Any]]
              plots[0]["sourceObservationEventID"] = droppedEventJSON
              agriculture["plots"] = plots
              durable["agricultureState"] = agriculture
          })
    check("evicted agriculture-event ID cannot authorize retained action",
          agricultureRestoreRefused(retentionCheckpoint) { durable in
              var agriculture = durable["agricultureState"] as! [String: Any]
              var actions = agriculture["retainedActions"] as! [[String: Any]]
              actions[0]["agricultureEventID"] = droppedEventJSON
              agriculture["retainedActions"] = actions
              durable["agricultureState"] = agriculture
          })
    check("planner corruption is rejected by exact observation event",
          agricultureRestoreRefused(retentionCheckpoint) { durable in
              var agriculture = durable["agricultureState"] as! [String: Any]
              var plots = agriculture["plots"] as! [[String: Any]]
              plots[0]["plannerID"] = "agent_1"
              agriculture["plots"] = plots
              durable["agricultureState"] = agriculture
          })
    check("action actor corruption is rejected by exact agriculture event",
          agricultureRestoreRefused(retentionCheckpoint) { durable in
              var agriculture = durable["agricultureState"] as! [String: Any]
              var actions = agriculture["retainedActions"] as! [[String: Any]]
              var outcome = actions[0]["outcome"] as! [String: Any]
              outcome["actorID"] = "agent_1"
              actions[0]["outcome"] = outcome
              agriculture["retainedActions"] = actions
              durable["agricultureState"] = agriculture
          })
    check("causal capacity refusal preserves agriculture byte exactly", {
        for _ in 0..<128 {
            let before = try! causalRetention.durableStateBytes()
            do {
                _ = try causalRetention.advanceTick()
            } catch AgentSessionError.agriculture(
                .invalidState("retained agriculture causal evidence capacity")
            ) {
                return (try! causalRetention.durableStateBytes()) == before
                    && causalRetention.causalLedgerSnapshot().events
                        .contains(where: {
                            $0.eventID == retentionAction.agricultureEventID
                        })
            } catch {
                return false
            }
        }
        return false
    }())
    var foundationRetention = agricultureBase(
        "agriculture-foundation-boundary",
        causalMaximumEvents: 64,
        preRegistrationCausalEvents: 60
    )
    try! foundationRetention.setEcologicalObservationEnabled(true)
    let foundationObservation = try! foundationRetention
        .recordEcologicalObservation(agricultureObservation(foundationRetention))
    try! foundationRetention.setAgricultureEnabled(true)
    _ = try! foundationRetention.planAgriculturalPlot(
        plannerID: AgentID(rawValue: "agent_0")!,
        positions: agricultureSoils,
        sourceObservationEventID: foundationObservation.causalEventID,
        designatedStorageLocationID: "container:10,64,0"
    )
    for _ in 0..<128 { _ = try! foundationRetention.advanceTick() }
    let postBoundaryCheckpoint = try! foundationRetention.makeCheckpoint()
    let postBoundaryEvents = foundationRetention.causalLedgerSnapshot().events
    check("plot foundation is causally re-anchored before source eviction",
          !postBoundaryEvents.contains(where: {
              $0.eventID == foundationObservation.causalEventID
          })
            && postBoundaryEvents.contains(where: { event in
                event.kind == .agricultureInitialized
                    && event.origin == .agricultureTransition
                    && {
                        guard case let .agriculture(
                            plotID, _, _, status, _, _, _, digest
                        ) = event.payload else { return false }
                        return plotID == nil && status == "retentionBoundary"
                            && digest.count == 16
                    }()
            }))
    check("post-eviction agriculture boundary restores byte exactly", {
        guard let restored = try? AgentSimulationSession.restoring(
            postBoundaryCheckpoint
        ) else { return false }
        return (try? restored.durableStateBytes())
            == (try? foundationRetention.durableStateBytes())
    }())
    check("post-eviction source corruption is rejected by boundary",
          agricultureRestoreRefused(postBoundaryCheckpoint) { durable in
              var agriculture = durable["agricultureState"] as! [String: Any]
              var plots = agriculture["plots"] as! [[String: Any]]
              plots[0]["sourceObservationEventID"] = droppedEventJSON
              agriculture["plots"] = plots
              durable["agricultureState"] = agriculture
          })
    check("post-eviction planner corruption is rejected by boundary",
          agricultureRestoreRefused(postBoundaryCheckpoint) { durable in
              var agriculture = durable["agricultureState"] as! [String: Any]
              var plots = agriculture["plots"] as! [[String: Any]]
              plots[0]["plannerID"] = "agent_1"
              agriculture["plots"] = plots
              durable["agricultureState"] = agriculture
          })
    check("post-eviction cell corruption is rejected by boundary",
          agricultureRestoreRefused(postBoundaryCheckpoint) { durable in
              var agriculture = durable["agricultureState"] as! [String: Any]
              var plots = agriculture["plots"] as! [[String: Any]]
              var cells = plots[0]["cells"] as! [[String: Any]]
              var position = cells[0]["position"] as! [String: Any]
              position["x"] = (position["x"] as! Int) + 1
              cells[0]["position"] = position
              plots[0]["cells"] = cells
              agriculture["plots"] = plots
              durable["agricultureState"] = agriculture
          })
    check("retained action tick corruption remains exactly rejected",
          agricultureRestoreRefused(retentionCheckpoint) { durable in
              var agriculture = durable["agricultureState"] as! [String: Any]
              var actions = agriculture["retainedActions"] as! [[String: Any]]
              var outcome = actions[0]["outcome"] as! [String: Any]
              var date = outcome["civilDate"] as! [String: Any]
              date["simulationTick"] = (date["simulationTick"] as! Int) + 1
              outcome["civilDate"] = date
              actions[0]["outcome"] = outcome
              agriculture["retainedActions"] = actions
              durable["agricultureState"] = agriculture
          })

    var replayed = try! AgentSimulationSession.restoring(v12)
    var recorder = try! AgentReplayRecorder(checkpoint: v12, session: replayed)
    _ = try! recorder.apply(
        .setAgricultureEnabled(true, configuration: .live), to: &replayed
    )
    let replayPlot = try! recorder.apply(
        .planAgriculturalPlot(
            plannerID: AgentID(rawValue: "agent_0")!, positions: agricultureSoils,
            crop: .wheat, sourceObservationEventID: observationRecord.causalEventID,
            designatedStorageLocationID: "container:4,64,0"
        ),
        to: &replayed
    )
    _ = replayPlot
    let replayPlotID = replayed.agricultureSnapshot().plots[0].plotID
    _ = try! recorder.apply(.reserveAgriculturalCell(
        plotID: replayPlotID, cellIndex: 0,
        contenders: [AgentID(rawValue: "agent_1")!, AgentID(rawValue: "agent_0")!]
    ), to: &replayed)
    for index in agricultureSoils.indices {
        _ = try! recorder.apply(.recordAgriculturalAction(agricultureAction(
            replayed, plotID: replayPlotID, cellIndex: index, kind: .till,
            suffix: "till-\(index)"
        )), to: &replayed)
        _ = try! recorder.apply(.recordAgriculturalAction(agricultureAction(
            replayed, plotID: replayPlotID, cellIndex: index, kind: .plant,
            suffix: "plant-\(index)"
        )), to: &replayed)
    }
    let replayMature = try! recorder.apply(.recordEcologicalObservation(
        agricultureObservation(replayed, mature: true)
    ), to: &replayed)
    _ = replayMature
    let replayMatureEvent = replayed.ecologicalObservations(
        for: AgentID(rawValue: "agent_0")!
    ).first!.causalEventID
    for index in agricultureSoils.indices {
        _ = try! recorder.apply(.recordAgriculturalAction(agricultureAction(
            replayed, plotID: replayPlotID, cellIndex: index,
            kind: .maturityObserved, suffix: "mature-\(index)",
            observationEventID: replayMatureEvent
        )), to: &replayed)
        _ = try! recorder.apply(.recordAgriculturalAction(agricultureAction(
            replayed, plotID: replayPlotID, cellIndex: index, kind: .harvest,
            suffix: "harvest-\(index)"
        )), to: &replayed)
    }
    _ = try! recorder.apply(.recordAgriculturalAction(agricultureAction(
        replayed, plotID: replayPlotID, cellIndex: nil, kind: .store,
        suffix: "store"
    )), to: &replayed)
    _ = try! recorder.apply(.recordEcologicalObservation(
        agricultureObservation(replayed, mature: true)
    ), to: &replayed)
    let replayRenewalEvent = replayed.ecologicalObservations(
        for: AgentID(rawValue: "agent_0")!
    ).first!.causalEventID
    _ = try! recorder.apply(.renewAgriculturalPlot(
        plotID: replayPlotID,
        plannerID: AgentID(rawValue: "agent_0")!,
        sourceObservationEventID: replayRenewalEvent
    ), to: &replayed)
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "agriculture-replay")!
    )
    let replay = try! AgentSessionReplayer.replay(checkpoint: v12, journal: journal)
    check("agriculture v13 replay is deterministic and byte exact",
          replay.report.verified && replay.report.schemaVersion == 13
            && (try! replay.session.durableStateBytes())
                == (try! replayed.durableStateBytes()))
}
