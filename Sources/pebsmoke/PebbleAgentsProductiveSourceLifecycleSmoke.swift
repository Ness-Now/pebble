import PebbleAgents

private func productiveSourceAgent() -> AgentSessionAgentState {
    let position = AgentPosition(x: 0, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_0", state: "idle", position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "productive source fixture",
            startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func productiveSourceSession(
    _ id: String,
    configuration: AgentProductiveSourceConfiguration = .live
) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 46, memoryPolicy: .bounded(maxEntries: 32)
        ),
        agents: [productiveSourceAgent()],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 256)
    )
    try! session.setAutonomousActivityEnabled(true)
    try! session.setProductiveSourceLifecycleEnabled(
        true, configuration: configuration
    )
    return session
}

private func productiveObservation(
    key: String = "wild:sweet_berry_bush@2,64,0",
    domain: AgentAutonomousActivityDomain = .wildGathering,
    material: String = "sweet_berry_bush:ripe",
    disposition: AgentProductiveSourceDisposition = .viable,
    tick: Int = 0,
    observationReference: String = "event-1",
    unavailableReason: String? = nil,
    withdrawalReason: String? = nil,
    renewalReason: String? = nil,
    position: AgentPosition = AgentPosition(x: 2, y: 64, z: 0)
) -> AgentProductiveSourceObservation {
    AgentProductiveSourceObservation(
        sourceKey: key,
        domain: domain,
        materialFingerprint: material,
        observedAtTick: tick,
        observerID: AgentID(rawValue: "agent_0")!,
        physicalPosition: position,
        disposition: disposition,
        observationReference: observationReference,
        temporarilyUnavailableReason: unavailableReason,
        withdrawalReason: withdrawalReason,
        renewalReason: renewalReason
    )
}

func runPebbleAgentsProductiveSourceLifecycleSmoke() {
    section("PebbleAgents local productive source lifecycle")

    let executableAgriculture = AgentProductiveSourceExecutionFacts(
        hasPendingPhysicalAction: true,
        requiresTool: true,
        toolAvailable: true,
        requiresMaterial: true,
        materialAvailable: true,
        requiresPhysicalSupport: true,
        physicalSupportAvailable: true
    )
    check(
        "material-compatible agriculture is executable only with a pending action and all physical preconditions",
        executableAgriculture.executable
            && executableAgriculture.blocker == nil
    )
    check(
        "missing agricultural tool is an explicit execution blocker",
        AgentProductiveSourceExecutionFacts(
            hasPendingPhysicalAction: true,
            requiresTool: true,
            toolAvailable: false
        ).blocker == .toolUnavailable
    )
    check(
        "missing agricultural material is an explicit execution blocker",
        AgentProductiveSourceExecutionFacts(
            hasPendingPhysicalAction: true,
            requiresMaterial: true,
            materialAvailable: false
        ).blocker == .materialUnavailable
    )
    check(
        "an already completed action cannot leave a viable source",
        AgentProductiveSourceExecutionFacts(
            hasPendingPhysicalAction: false
        ).blocker == .noPendingPhysicalAction
    )

    var unchanged = productiveSourceSession("productive-source-unchanged")
    _ = try! unchanged.recordProductiveSourceObservations([
        productiveObservation()
    ])
    let first = unchanged.productiveSourceSnapshot()
    _ = try! unchanged.recordProductiveSourceObservations([
        productiveObservation(observationReference: "event-2")
    ])
    let second = unchanged.productiveSourceSnapshot()
    check(
        "first local observation establishes one viable source",
        first.sources.count == 1
            && first.sources[0].viability == .viable
            && first.transitions.map(\.to).contains(.observed)
    )
    check(
        "unchanged source is not renewed by a new event ID",
        second.sources[0].renewalCount == 0
            && second.sources[0].observationReference == "event-2"
            && second.counters.renewedCount == 0
    )

    _ = try! unchanged.recordProductiveSourceObservations([
        productiveObservation(
            material: "sweet_berry_bush:empty",
            disposition: .depleted,
            withdrawalReason: "fruit physically absent"
        )
    ])
    check(
        "materially exhausted source becomes depleted",
        unchanged.productiveSourceSnapshot().sources[0].viability == .depleted
    )
    _ = try! unchanged.recordProductiveSourceObservations([
        productiveObservation(
            material: "sweet_berry_bush:ripe-again",
            renewalReason: "locally observed fruit state changed"
        )
    ])
    check(
        "materially changed local source becomes renewed",
        unchanged.productiveSourceSnapshot().sources[0].viability == .renewed
            && unchanged.productiveSourceSnapshot().sources[0].renewalCount == 1
    )
    check(
        "logical source generation ignores event IDs but advances on material renewal",
        first.sources[0].logicalGenerationKey
            == second.sources[0].logicalGenerationKey
            && unchanged.productiveSourceSnapshot().sources[0]
                .logicalGenerationKey != second.sources[0].logicalGenerationKey
    )

    var unavailable = productiveSourceSession("productive-source-unavailable")
    _ = try! unavailable.recordProductiveSourceObservations([
        productiveObservation(
            disposition: .temporarilyUnavailable,
            unavailableReason: "required tool absent"
        )
    ])
    check(
        "temporary physical precondition is represented explicitly",
        unavailable.productiveSourceSnapshot().sources[0].viability
            == .temporarilyUnavailable
            && unavailable.productiveSourceSnapshot().sources[0]
                .temporarilyUnavailableReason == "required tool absent"
    )
    _ = try! unavailable.recordProductiveSourceObservations([
        productiveObservation(
            observationReference: "event-tool-returned",
            renewalReason: "required tool physically present"
        )
    ])
    check(
        "restored physical precondition renews the source",
        unavailable.productiveSourceSnapshot().sources[0].viability == .renewed
    )

    var disappeared = productiveSourceSession("productive-source-disappeared")
    _ = try! disappeared.recordProductiveSourceObservations([
        productiveObservation()
    ])
    _ = try! disappeared.recordProductiveSourceObservations([
        productiveObservation(
            disposition: .withdrawn,
            observationReference: "event-absent",
            withdrawalReason: "target locally observed absent"
        )
    ])
    check(
        "locally absent source is withdrawn",
        disappeared.productiveSourceSnapshot().sources[0].viability == .withdrawn
    )
    _ = try! disappeared.recordProductiveSourceObservations([
        productiveObservation(
            observationReference: "event-redetected",
            renewalReason: "target locally redetected"
        )
    ])
    check(
        "physical redetection renews a withdrawn source",
        disappeared.productiveSourceSnapshot().sources[0].viability == .renewed
    )

    var multiple = productiveSourceSession("productive-source-multiple")
    _ = try! multiple.recordProductiveSourceObservations([
        productiveObservation(key: "wild:sweet_berry_bush@2,64,0"),
        productiveObservation(
            key: "wild:sweet_berry_bush@5,64,0",
            material: "sweet_berry_bush:young",
            observationReference: "event-other",
            position: AgentPosition(x: 5, y: 64, z: 0)
        ),
    ])
    check(
        "two physical sources in one domain retain distinct stable identity",
        multiple.productiveSourceSnapshot().sources.map(\.sourceKey)
            == [
                "wild:sweet_berry_bush@2,64,0",
                "wild:sweet_berry_bush@5,64,0",
            ]
    )
    check(
        "domain-position lookup selects the exact eligible local source",
        multiple.productiveSource(
            domain: .wildGathering,
            at: AgentPosition(x: 5, y: 64, z: 0)
        )?.sourceKey == "wild:sweet_berry_bush@5,64,0"
    )

    let boundedConfiguration = try! AgentProductiveSourceConfiguration(
        maximumSources: 2,
        maximumTransitions: 4,
        maximumObservationAgeTicks: 4
    )
    var bounded = productiveSourceSession(
        "productive-source-bounded", configuration: boundedConfiguration
    )
    for index in 0..<3 {
        _ = try! bounded.recordProductiveSourceObservations([
            productiveObservation(
                key: "wild:plant@\(index),64,0",
                material: "plant:\(index)",
                observationReference: "event-\(index)"
            )
        ])
        if index < 2 { _ = try! bounded.advanceTick() }
    }
    let boundedSnapshot = bounded.productiveSourceSnapshot()
    check(
        "source collection evicts deterministically at its bound",
        boundedSnapshot.sources.count == 2
            && boundedSnapshot.sources.map(\.sourceKey)
                == ["wild:plant@1,64,0", "wild:plant@2,64,0"]
            && boundedSnapshot.evictionCount > 0
    )
    check(
        "transition history is independently bounded",
        boundedSnapshot.transitions.count == 4
    )

    for _ in 0..<5 { _ = try! bounded.advanceTick() }
    _ = try! bounded.reviewProductiveSources()
    check(
        "stale local evidence withdraws rather than magically renews",
        bounded.productiveSourceSnapshot().sources.allSatisfy {
            $0.viability == .withdrawn
                && $0.withdrawalReason == "local observation stale"
        }
    )

    var success = productiveSourceSession("productive-source-success")
    let agriculture = productiveObservation(
        key: "agriculture:wheat@2,64,0",
        domain: .agriculture,
        material: "wheat:stage-7",
        observationReference: "crop-stage-7"
    )
    _ = try! success.recordProductiveSourceObservations([agriculture])
    _ = try! success.recordProductiveSourceSuccess(
        sourceKey: agriculture.sourceKey,
        expectedMaterialFingerprint: agriculture.materialFingerprint,
        physicalReceiptID: "harvest-receipt-1"
    )
    check(
        "verified physical success is attributed without synthesizing renewal",
        success.productiveSourceSnapshot().sources[0].lastPhysicalSuccessTick
            == success.tick
            && success.productiveSourceSnapshot().sources[0].renewalCount == 0
    )

    let checkpoint = try! success.makeCheckpoint()
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    check(
        "productive sources checkpoint inside schema v18 exactly",
        checkpoint.schemaVersion == AgentCheckpointSchema.autonomousActivityVersion
            && restored.productiveSourceSnapshot()
                == success.productiveSourceSnapshot()
            && (try! restored.durableStateDigest())
                == (try! success.durableStateDigest())
    )

    var replayDirect = productiveSourceSession("productive-source-replay")
    let replayBase = try! replayDirect.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(
        checkpoint: replayBase, session: replayDirect
    )
    let replayObservation = productiveObservation(
        key: "livestock:managed-animal-1",
        domain: .livestock,
        material: "sheep:product-ready",
        observationReference: "animal-event-1"
    )
    _ = try! recorder.apply(
        .recordProductiveSourceObservations([replayObservation]),
        to: &replayDirect
    )
    _ = try! recorder.apply(
        .recordProductiveSourceSuccess(
            sourceKey: replayObservation.sourceKey,
            expectedMaterialFingerprint:
                replayObservation.materialFingerprint,
            physicalReceiptID: "shear-receipt-1"
        ),
        to: &replayDirect
    )
    let replay = try! AgentSessionReplayer.replay(
        checkpoint: replayBase,
        journal: try! recorder.journal(
            named: AgentCheckpointName(rawValue: "productive-source")!
        )
    )
    check(
        "productive lifecycle operations replay to exact semantic state",
        replay.report.divergence == nil
            && replay.session.productiveSourceSnapshot()
                == replayDirect.productiveSourceSnapshot()
            && replay.report.finalSemanticDigest
                == (try! replayDirect.durableStateDigest())
    )

    let durableText = String(
        data: try! success.durableStateBytes(), encoding: .utf8
    )!
    check(
        "durable source lifecycle contains no World or runtime entity identity",
        !durableText.contains("World")
            && !durableText.contains("runtimeEntity")
            && !durableText.contains("ItemStack")
    )
}
