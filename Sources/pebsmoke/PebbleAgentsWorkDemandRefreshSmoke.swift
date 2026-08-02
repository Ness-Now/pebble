import Foundation
import PebbleAgents

private let refreshSoils = [
    AgentPosition(x: 1, y: 63, z: 0),
    AgentPosition(x: 1, y: 63, z: 1),
    AgentPosition(x: 1, y: 63, z: 2),
]

private func refreshAgent(_ index: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: index, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_\(index)", state: "idle", position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "work refresh fixture", startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func refreshObservation(
    _ session: AgentSimulationSession
) -> AgentEcologicalObservation {
    let configuration = session.ecologicalObservationSnapshot().configuration!
    return AgentEcologicalObservation(
        observerID: AgentID(rawValue: "agent_0")!,
        origin: AgentPosition(x: 0, y: 64, z: 0),
        worldContextKey: "work-refresh-world", dimensionKey: "overworld",
        observedAtSimulationTick: session.tick, physicalWorldTick: 120,
        civilDate: session.civilDate()!,
        biome: AgentBiomeObservation(
            biomeKey: "plains", position: AgentPosition(x: 0, y: 64, z: 0)
        ),
        water: [AgentWaterAffordance(
            fluidKey: "water", position: AgentPosition(x: 2, y: 63, z: 1),
            sourceBlock: true
        )],
        soils: refreshSoils.map {
            AgentSoilAffordance(
                blockKey: "dirt", position: $0, tillable: true,
                alreadyFarmland: false, hydrated: nil, supportsCrop: true
            )
        },
        crops: [], plants: [], animals: [], fishing: [],
        weather: AgentWeatherObservation(
            kind: .clear, raining: false, thundering: false
        ),
        physicalTime: AgentPhysicalWorldTimeObservation(
            worldTick: 120, dayTime: 120, timeOfDay: .day,
            daylightCycleEnabled: true
        ),
        diagnostics: AgentEcologicalScanDiagnostics(
            radius: 4, cellsConsidered: 405, worldReads: 405,
            chunksTouched: 1, chunksUnavailable: 0, entitiesConsidered: 0,
            resultsEmitted: 7, cacheHits: 0, cacheMisses: 1,
            completion: .complete
        ),
        expiresAtSimulationTick: session.tick + configuration.dynamicFreshnessTicks
    )
}

private func refreshSession(
    _ id: String,
    positions: [AgentPosition] = refreshSoils,
    causalBound: Int = 16_384
) -> (AgentSimulationSession, AgentAgriculturalPlotID) {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 46, memoryPolicy: .bounded(maxEntries: 64)
        ),
        agents: [refreshAgent(0), refreshAgent(1), refreshAgent(2)],
        simulationID: AgentSimulationID(rawValue: id)!,
        causalLedgerPolicy: .bounded(maxEvents: causalBound)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3)
    )
    try! session.setLifecycleEnabled(true)
    try! session.setSkillsEnabled(true)
    try! session.setEcologicalObservationEnabled(true)
    let observation = try! session.recordEcologicalObservation(
        refreshObservation(session)
    )
    try! session.setAgricultureEnabled(true)
    let plotID = try! session.planAgriculturalPlot(
        plannerID: AgentID(rawValue: "agent_0")!,
        positions: positions,
        sourceObservationEventID: observation.causalEventID,
        designatedStorageLocationID: "container:4,64,0"
    )
    try! session.setWorkCommitmentsEnabled(true)
    _ = try! session.applyWorkCommitmentOperation(.refreshDemands)
    return (session, plotID)
}

private func refreshTill(
    _ session: AgentSimulationSession,
    plotID: AgentAgriculturalPlotID,
    cellIndex: Int,
    suffix: String
) -> AgentAgriculturalActionOutcome {
    AgentAgriculturalActionOutcome(
        actionID: AgentAgriculturalActionID(
            rawValue: "work-refresh-till-\(suffix)"
        )!,
        kind: .till, actorID: AgentID(rawValue: "agent_0")!,
        plotID: plotID, cellIndex: cellIndex,
        position: refreshSoils[cellIndex],
        beforeFingerprint: 1, afterFingerprint: 2,
        civilDate: session.civilDate()!
    )
}

private func refreshMutatedCheckpoint(
    _ checkpoint: AgentSessionCheckpoint,
    mutate: (inout [String: Any]) -> Void
) -> AgentSessionCheckpoint {
    var root = try! JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(checkpoint)
    ) as! [String: Any]
    var durable = root["durableState"] as! [String: Any]
    mutate(&durable)
    let mutationBytes = try! JSONSerialization.data(
        withJSONObject: durable, options: [.sortedKeys, .withoutEscapingSlashes]
    )
    let mutatedState = try! AgentCheckpointCodec.decode(
        AgentSessionDurableState.self, from: mutationBytes
    )
    let durableBytes = try! AgentCheckpointCodec.encode(mutatedState)
    let canonical = try! JSONSerialization.jsonObject(
        with: durableBytes
    ) as! [String: Any]
    let clock = canonical["clock"] as! [String: Any]
    let simulationID = clock["simulationID"] as! String
    let tick = clock["tick"] as! Int
    let digest = AgentCheckpointDigest.sha256(durableBytes)
    let simulationDigest = AgentCheckpointDigest.sha256(Data(simulationID.utf8))
    root["durableState"] = canonical
    root["schemaVersion"] = canonical["schemaVersion"]
    root["semanticDigest"] = digest.rawValue
    root["checkpointID"] =
        "checkpoint-\(simulationDigest.rawValue.prefix(12))-t\(tick)-\(digest.rawValue.prefix(16))"
    return try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self,
        from: JSONSerialization.data(
            withJSONObject: root,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
    )
}

private func refreshRestoreRefused(
    _ checkpoint: AgentSessionCheckpoint,
    mutate: (inout [String: Any]) -> Void
) -> Bool {
    do {
        _ = try AgentSimulationSession.restoring(
            refreshMutatedCheckpoint(checkpoint, mutate: mutate)
        )
        return false
    } catch {
        return true
    }
}

private func mutateFirstRefreshDemand(
    _ durable: inout [String: Any],
    mutate: (inout [String: Any]) -> Void
) {
    var work = durable["workCommitmentState"] as! [String: Any]
    var demands = work["demands"] as! [[String: Any]]
    mutate(&demands[0])
    work["demands"] = demands
    durable["workCommitmentState"] = work
}

private func eventJSON(_ eventID: AgentCausalEventID) -> [String: Any] {
    [
        "simulationID": eventID.simulationID.rawValue,
        "sequence": eventID.sequence.rawValue,
    ]
}

func runPebbleAgentsWorkDemandRefreshSmoke() {
    section("PebbleAgents stable work-demand causal refresh")

    var (session, plotID) = refreshSession("work-refresh-tick-four")
    let initial = session.activeWorkDemands()
    let plotEvent = initial.first!.sourceEventID
    let protectedDemand = initial.first {
        $0.sourceKey.contains("-2-till")
    }!
    let commitment = try! session.applyWorkCommitmentOperation(.start(
        demandID: protectedDemand.demandID,
        candidates: [AgentWorkCandidateContext(
            agentID: AgentID(rawValue: "agent_0")!, distance: 1
        )]
    ))!
    let prepared = try! session.recordAgriculturalActionSuccess(
        refreshTill(session, plotID: plotID, cellIndex: 0, suffix: "cell-0")
    )
    for _ in 0..<4 { _ = try! session.advanceTick() }
    let beforeRefreshDemandCount = session.workCommitmentSnapshot().totalDemandCount
    let beforeRefreshCausal = session.causalLedgerSnapshot().summary.latestSequence
    _ = try! session.applyWorkCommitmentOperation(.refreshDemands)
    let refreshed = session.activeWorkDemands()
    let sameLogical = refreshed.first {
        $0.demandID == protectedDemand.demandID
    }!
    let refreshedEvents = session.causalLedgerSnapshot().events.filter {
        $0.kind == .workDemandRefreshed
            && $0.eventID.sequence.rawValue > beforeRefreshCausal
    }
    check("exact tick-four agriculture refresh no longer freezes the session",
          session.tick == 4 && sameLogical.sourceEventID == prepared.agricultureEventID)
    check("logical demand identity survives newer causal provenance",
          sameLogical.demandID == protectedDemand.demandID
            && sameLogical.source == protectedDemand.source
            && sameLogical.sourceKey == protectedDemand.sourceKey
            && sameLogical.domain == protectedDemand.domain
            && sameLogical.sourceEventID.sequence > plotEvent.sequence)
    check("refresh preserves creation time and updates bounded expiry metadata",
          sameLogical.createdAtTick == protectedDemand.createdAtTick
            && sameLogical.refreshedAtTick == 4
            && sameLogical.expiresAtTick == 12)
    check("newer provenance refreshes without duplicating logical demand",
          Set(refreshed.map(\.demandID)).count == refreshed.count
            && session.workCommitmentSnapshot().totalDemandCount
                == beforeRefreshDemandCount + 1
            && refreshedEvents.count == 3)
    check("meaningful refresh links prior Work state and newer domain provenance",
          refreshedEvents.contains {
              $0.causes.count == 2
                  && $0.causes.contains(sameLogical.sourceEventID)
          })
    check("agriculture phase change receives a different logical demand ID",
          refreshed.contains {
              $0.sourceKey.contains("-0-plant")
                  && !initial.map(\.demandID).contains($0.demandID)
          })
    check("open commitment survives demand provenance refresh",
          session.activeWorkCommitments().contains {
              $0.commitmentID == commitment.commitmentID
                  && $0.demandID == sameLogical.demandID
                  && $0.status == .active
          })

    let heartbeatCausalBefore = session.causalLedgerSnapshot().summary.latestSequence
    let heartbeatDemandCount = session.workCommitmentSnapshot().totalDemandCount
    _ = try! session.applyWorkCommitmentOperation(.refreshDemands)
    check("same-event same-tick heartbeat creates no causal spam",
          session.causalLedgerSnapshot().summary.latestSequence == heartbeatCausalBefore
            && session.workCommitmentSnapshot().totalDemandCount == heartbeatDemandCount)
    _ = try! session.advanceTick()
    let laterHeartbeatCausal = session.causalLedgerSnapshot().summary.latestSequence
    _ = try! session.applyWorkCommitmentOperation(.refreshDemands)
    let laterHeartbeat = session.activeWorkDemands().first {
        $0.demandID == sameLogical.demandID
    }!
    check("same-event heartbeat refreshes cadence without a duplicate",
          laterHeartbeat.refreshedAtTick == 5 && laterHeartbeat.expiresAtTick == 13
            && laterHeartbeat.sourceEventID == sameLogical.sourceEventID
            && session.causalLedgerSnapshot().summary.latestSequence
                == laterHeartbeatCausal)

    var (projectionSource, _) = refreshSession("work-refresh-projection")
    let canonicalProjection = projectionSource.activeWorkDemands().first!
    let projectionCheckpoint = try! projectionSource.makeCheckpoint()
    let staleProjectionCheckpoint = refreshMutatedCheckpoint(
        projectionCheckpoint
    ) { durable in
        mutateFirstRefreshDemand(&durable) { demand in
            demand["observerID"] = "agent_1"
            demand["suggestedWorkerID"] = "agent_2"
            demand["targetPosition"] = ["x": 2, "y": 64, "z": 2]
            demand["requiredToolKeys"] = ["fishing_rod", "hoe"]
            demand["requiredResourceKeys"] = ["food", "wood"]
            demand["urgency"] = 77
            demand["quantity"] = 5
            demand["cadenceTicks"] = 7
        }
    }
    projectionSource = try! AgentSimulationSession.restoring(
        staleProjectionCheckpoint
    )
    let projectionCount = projectionSource.workCommitmentSnapshot().totalDemandCount
    let projectionCausal = projectionSource.causalLedgerSnapshot().summary.latestSequence
    _ = try! projectionSource.applyWorkCommitmentOperation(.refreshDemands)
    let reconciledProjection = projectionSource.activeWorkDemands().first {
        $0.demandID == canonicalProjection.demandID
    }!
    check("same logical demand reconciles every refreshable projection field",
          reconciledProjection.sourceEventID == canonicalProjection.sourceEventID
            && reconciledProjection.observerID == canonicalProjection.observerID
            && reconciledProjection.suggestedWorkerID
                == canonicalProjection.suggestedWorkerID
            && reconciledProjection.targetPosition
                == canonicalProjection.targetPosition
            && reconciledProjection.requiredToolKeys
                == canonicalProjection.requiredToolKeys
            && reconciledProjection.requiredResourceKeys
                == canonicalProjection.requiredResourceKeys
            && reconciledProjection.urgency == canonicalProjection.urgency
            && reconciledProjection.quantity == canonicalProjection.quantity
            && reconciledProjection.cadenceTicks == canonicalProjection.cadenceTicks
            && reconciledProjection.createdAtTick == canonicalProjection.createdAtTick
            && projectionSource.workCommitmentSnapshot().totalDemandCount
                == projectionCount
            && projectionSource.causalLedgerSnapshot().summary.latestSequence
                == projectionCausal + 1)

    let realOutcome = try! session.recordAgriculturalActionSuccess(
        refreshTill(session, plotID: plotID, cellIndex: 2, suffix: "cell-2")
    )
    _ = try! session.applyWorkCommitmentOperation(.recordOutcome(
        AgentValidatedWorkOutcome(
            commitmentID: commitment.commitmentID,
            workerID: commitment.workerID, domain: .cultivation,
            sourceSuccessEventID: realOutcome.agricultureEventID,
            status: .succeeded, observerIDs: [AgentID(rawValue: "agent_0")!]
        )
    ))
    check("verified physical-domain outcome fulfills the refreshed commitment",
          session.workCommitmentSnapshot().commitments.first {
              $0.commitmentID == commitment.commitmentID
          }?.status == .fulfilled
            && session.workCommitmentSnapshot().totalEvidenceCount == 1
            && session.professionProfile(for: commitment.workerID)?
                .primaryWorkDomain == .cultivation)
    let fulfilledCount = session.workCommitmentSnapshot().totalDemandCount
    _ = try! session.applyWorkCommitmentOperation(.refreshDemands)
    let postFulfillment = session.workCommitmentSnapshot()
    check("fulfilled phase is not blindly reactivated when the domain phase changes",
          postFulfillment.demands.first {
              $0.demandID == commitment.demandID
          }?.status == .fulfilled
            && postFulfillment.demands.contains {
                $0.sourceKey.contains("-2-plant")
                    && $0.status == .active
                    && $0.demandID != commitment.demandID
            }
            && postFulfillment.totalDemandCount == fulfilledCount + 1)

    var (expired, _) = refreshSession("work-refresh-expired")
    for _ in 0..<9 { _ = try! expired.advanceTick() }
    _ = try! expired.applyWorkCommitmentOperation(.review)
    check("unrefreshed demand expires before deterministic reappearance",
          expired.workCommitmentSnapshot().demands.allSatisfy {
              $0.status == .expired
          })
    let expiredCausal = expired.causalLedgerSnapshot().summary.latestSequence
    let expiredTotal = expired.workCommitmentSnapshot().totalDemandCount
    _ = try! expired.applyWorkCommitmentOperation(.refreshDemands)
    check("expired logical demand reactivates without a new demand identity",
          expired.activeWorkDemands().count == 3
            && expired.workCommitmentSnapshot().totalDemandCount == expiredTotal
            && expired.causalLedgerSnapshot().summary.latestSequence
                == expiredCausal + 3)

    var (replay, replayPlotID) = refreshSession("work-refresh-v18-replay")
    let replayDemand = replay.activeWorkDemands().first {
        $0.sourceKey.contains("-2-till")
    }!
    let replayPlotEvent = replayDemand.sourceEventID
    let replayCommitment = try! replay.applyWorkCommitmentOperation(.start(
        demandID: replayDemand.demandID,
        candidates: [AgentWorkCandidateContext(
            agentID: AgentID(rawValue: "agent_0")!, distance: 1
        )]
    ))!
    try! replay.setAutonomousActivityEnabled(true)
    let replayBase = try! replay.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(checkpoint: replayBase, session: replay)
    let firstReplayAction = refreshTill(
        replay, plotID: replayPlotID, cellIndex: 0, suffix: "replay-cell-0"
    )
    _ = try! recorder.apply(
        .recordAgriculturalAction(firstReplayAction), to: &replay
    )
    for _ in 0..<4 {
        _ = try! recorder.apply(
            .advanceTick(perceptions: [], physicalObservations: []), to: &replay
        )
    }
    _ = try! recorder.apply(
        .applyWorkCommitmentOperation(.refreshDemands), to: &replay
    )
    let replayCheckpoint = try! replay.makeCheckpoint()
    let replayRestored = try! AgentSimulationSession.restoring(replayCheckpoint)
    check("checkpoint schema 30 preserves refreshed demand provenance byte exactly",
          replayCheckpoint.schemaVersion
            == AgentCheckpointSchema.independentEcologicalReceiptVersion
            && replayRestored.workCommitmentSnapshot()
                == replay.workCommitmentSnapshot()
            && (try! replayRestored.durableStateBytes())
                == (try! replay.durableStateBytes()))
    let replayOutcome = refreshTill(
        replay, plotID: replayPlotID, cellIndex: 2, suffix: "replay-cell-2"
    )
    _ = try! recorder.apply(
        .recordAgriculturalAction(replayOutcome), to: &replay
    )
    let replaySource = replay.causalLedgerSnapshot().events.last {
        $0.kind == .agriculturalCellPrepared
            && $0.actorID == AgentID(rawValue: "agent_0")!
    }!.eventID
    _ = try! recorder.apply(
        .applyWorkCommitmentOperation(.recordOutcome(
            AgentValidatedWorkOutcome(
                commitmentID: replayCommitment.commitmentID,
                workerID: replayCommitment.workerID, domain: .cultivation,
                sourceSuccessEventID: replaySource, status: .succeeded,
                observerIDs: [AgentID(rawValue: "agent_0")!]
            )
        )), to: &replay
    )
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "work-demand-refresh-v18")!
    )
    let replayed = try! AgentSessionReplayer.replay(
        checkpoint: replayBase, journal: journal
    )
    check("replay schema 30 reproduces refresh and later physical evidence exactly",
          replayed.report.verified
            && replayed.report.schemaVersion
                == AgentReplaySchema.independentEcologicalReceiptVersion
            && replayed.session.workCommitmentSnapshot()
                == replay.workCommitmentSnapshot()
            && (try! replayed.session.durableStateBytes())
                == (try! replay.durableStateBytes()))

    let invalidCheckpoint = replayCheckpoint
    check("restore rejects same demand ID with a different domain", refreshRestoreRefused(
        invalidCheckpoint
    ) { durable in
        mutateFirstRefreshDemand(&durable) { $0["domain"] = "hunting" }
    })
    check("restore rejects same demand ID with a different source", refreshRestoreRefused(
        invalidCheckpoint
    ) { durable in
        mutateFirstRefreshDemand(&durable) { $0["source"] = "livestock" }
    })
    check("restore rejects same demand ID with a different source key", refreshRestoreRefused(
        invalidCheckpoint
    ) { durable in
        mutateFirstRefreshDemand(&durable) {
            $0["sourceKey"] = "corrupt-logical-key"
        }
    })
    check("restore rejects cross-simulation demand provenance", refreshRestoreRefused(
        invalidCheckpoint
    ) { durable in
        mutateFirstRefreshDemand(&durable) { demand in
            var source = demand["sourceEventID"] as! [String: Any]
            source["simulationID"] = "other-simulation"
            demand["sourceEventID"] = source
        }
    })
    check("restore rejects future demand provenance", refreshRestoreRefused(
        invalidCheckpoint
    ) { durable in
        let causal = durable["causalLedger"] as! [String: Any]
        let future = (causal["latestSequence"] as! NSNumber).uint64Value + 1
        mutateFirstRefreshDemand(&durable) { demand in
            var source = demand["sourceEventID"] as! [String: Any]
            source["sequence"] = future
            demand["sourceEventID"] = source
        }
    })
    check("restore rejects a retained event from the wrong causal domain", refreshRestoreRefused(
        invalidCheckpoint
    ) { durable in
        var work = durable["workCommitmentState"] as! [String: Any]
        let invalid = work["initializedEventID"] as! [String: Any]
        var demands = work["demands"] as! [[String: Any]]
        demands[0]["sourceEventID"] = invalid
        work["demands"] = demands
        durable["workCommitmentState"] = work
    })

    let staleCheckpoint = refreshMutatedCheckpoint(replayCheckpoint) { durable in
        var agriculture = durable["agricultureState"] as! [String: Any]
        var plots = agriculture["plots"] as! [[String: Any]]
        plots[0]["lastAgricultureEventID"] = eventJSON(replayPlotEvent)
        agriculture["plots"] = plots
        durable["agricultureState"] = agriculture
    }
    var stale = try! AgentSimulationSession.restoring(staleCheckpoint)
    let staleBytes = try! stale.durableStateBytes()
    check("stale causal refresh is rejected transactionally", {
        do {
            _ = try stale.applyWorkCommitmentOperation(.refreshDemands)
            return false
        } catch AgentSessionError.workCommitment(.invalidState) {
            return (try! stale.durableStateBytes()) == staleBytes
        } catch {
            return false
        }
    }())

    var (longRun, _) = refreshSession(
        "work-refresh-long-run", causalBound: 64
    )
    for _ in 0..<900 {
        _ = try! longRun.advanceTick()
        _ = try! longRun.applyWorkCommitmentOperation(.refreshDemands)
    }
    let longSnapshot = longRun.workCommitmentSnapshot()
    let longCausal = longRun.causalLedgerSnapshot().summary
    let longCheckpoint = try! longRun.makeCheckpoint()
    var longRestored = try! AgentSimulationSession.restoring(longCheckpoint)
    let nextCausalBefore = longRestored.causalLedgerSnapshot().summary.latestSequence
    _ = try! longRestored.applyWorkCommitmentOperation(.refreshDemands)
    check("long-running heartbeats remain bounded after causal source eviction",
          longRun.tick == 900 && longSnapshot.demands.count == 3
            && longSnapshot.totalDemandCount == 3
            && longCausal.retainedEventCount == 64
            && longCausal.droppedEventCount > 0)
    check("post-eviction schema 30 checkpoint accepts legitimate refresh",
          longCheckpoint.schemaVersion
            == AgentCheckpointSchema.independentEcologicalReceiptVersion
            && longRestored.activeWorkDemands().count == 3
            && longRestored.causalLedgerSnapshot().summary.latestSequence
                == nextCausalBefore)

    var (orderingA, orderingPlotA) = refreshSession(
        "work-refresh-ordering", positions: refreshSoils
    )
    var (orderingB, orderingPlotB) = refreshSession(
        "work-refresh-ordering", positions: Array(refreshSoils.reversed())
    )
    _ = try! orderingA.recordAgriculturalActionSuccess(
        refreshTill(
            orderingA, plotID: orderingPlotA, cellIndex: 0,
            suffix: "ordering"
        )
    )
    _ = try! orderingB.recordAgriculturalActionSuccess(
        refreshTill(
            orderingB, plotID: orderingPlotB, cellIndex: 0,
            suffix: "ordering"
        )
    )
    for _ in 0..<4 {
        _ = try! orderingA.advanceTick()
        _ = try! orderingB.advanceTick()
    }
    _ = try! orderingA.applyWorkCommitmentOperation(.refreshDemands)
    _ = try! orderingB.applyWorkCommitmentOperation(.refreshDemands)
    check("input order cannot change refreshed demand state",
          orderingPlotA == orderingPlotB
            && (try! orderingA.durableStateBytes())
                == (try! orderingB.durableStateBytes()))

    print(
        "  work-refresh proof old=\(plotEvent.rawValue) "
            + "new=\(prepared.agricultureEventID.rawValue) "
            + "demand=\(protectedDemand.demandID.rawValue) "
            + "tick4=passed longTicks=\(longRun.tick) retainedDemands="
            + "\(longSnapshot.demands.count) totalDemands=\(longSnapshot.totalDemandCount) "
            + "causalRetained=\(longCausal.retainedEventCount) "
            + "causalDropped=\(longCausal.droppedEventCount)"
    )
}
