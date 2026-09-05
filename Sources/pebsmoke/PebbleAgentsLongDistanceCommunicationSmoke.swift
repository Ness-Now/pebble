import Foundation
import PebbleAgents

private let communicationAuthor = AgentID(rawValue: "agent_0")!
private let communicationCarrier = AgentID(rawValue: "agent_1")!
private let communicationDestination = AgentID(rawValue: "agent_2")!

private let communicationSenseIDs = [
    AgentLanguageSenseID(rawValue: "referent.worldCell")!,
    AgentLanguageSenseID(
        rawValue: "predicate.world.resource.presence"
    )!,
    AgentLanguageSenseID(rawValue: "value.resource.wood")!,
]

private func communicationAgent(
    _ id: AgentID,
    x: Int,
    lethal: Bool = false,
    health: Int? = nil
) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id.rawValue,
        state: "idle",
        position: position,
        needs: AgentNeeds(
            hunger: lethal ? 0.39 : -10,
            fatigue: 0,
            curiosity: 0,
            safety: 1
        ),
        health: health ?? (lethal ? 26 : 100),
        fear: 0,
        homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle,
            reason: "CIV-44 fixture",
            startedAtTick: 0,
            urgency: 0
        ),
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
        survivalProgress: nil
    )
}

private func communicationKnowledgeConfiguration(
    maximumBeliefs: Int
) -> AgentKnowledgeConfiguration {
    try! AgentKnowledgeConfiguration(
        maximumPropositions: 64,
        maximumEvidence: 64,
        maximumClaims: 64,
        maximumUnderstandings: 64,
        maximumBeliefs: maximumBeliefs,
        maximumRevisions: 128,
        maximumEvidencePerAgent: 8,
        maximumClaimsPerAgent: 8,
        maximumUnderstandingsPerAgent: 8,
        maximumBeliefsPerAgent: 8,
        maximumRevisionsPerAgent: 16
    )
}

private func communicationPrepared(
    id: String,
    reversed: Bool = false,
    transportConfiguration: AgentLongDistanceCommunicationConfiguration
        = .live,
    knowledgeConfiguration: AgentKnowledgeConfiguration = .live,
    causalMaximumEvents: Int = 16_384,
    lethalID: AgentID? = nil,
    healthByAgentID: [AgentID: Int] = [:],
    starvationDamagePerTick: Int = 100,
    enableLongDistance: Bool = true
) -> (AgentSimulationSession, AgentKnowledgePropositionID) {
    let agents = [
        communicationAgent(
            communicationAuthor,
            x: 0,
            lethal: lethalID == communicationAuthor
                || healthByAgentID[communicationAuthor] != nil,
            health: healthByAgentID[communicationAuthor]
        ),
        communicationAgent(
            communicationCarrier,
            x: 1,
            lethal: lethalID == communicationCarrier
                || healthByAgentID[communicationCarrier] != nil,
            health: healthByAgentID[communicationCarrier]
        ),
        communicationAgent(
            communicationDestination,
            x: 8,
            lethal: lethalID == communicationDestination
                || healthByAgentID[communicationDestination] != nil,
            health: healthByAgentID[communicationDestination]
        ),
    ]
    let survival = lethalID == nil ? AgentSurvivalConfiguration.live : try!
        AgentSurvivalConfiguration(
            hungerPerTick: 1,
            fatiguePerTick: AgentSurvivalConfiguration.live.fatiguePerTick,
            hungryThreshold: AgentSurvivalConfiguration.live.hungryThreshold,
            criticalHungerThreshold:
                AgentSurvivalConfiguration.live.criticalHungerThreshold,
            hungerRecoveryThreshold:
                AgentSurvivalConfiguration.live.hungerRecoveryThreshold,
            fatigueThreshold:
                AgentSurvivalConfiguration.live.fatigueThreshold,
            fatigueRecoveryThreshold:
                AgentSurvivalConfiguration.live.fatigueRecoveryThreshold,
            foodNutrition: AgentSurvivalConfiguration.live.foodNutrition,
            restRecoveryPerTick:
                AgentSurvivalConfiguration.live.restRecoveryPerTick,
            starvationGraceTicks: 0,
            starvationDamagePerTick: starvationDamagePerTick
        )
    let social = try! AgentSocialConfiguration(
        communicationRadius: 2,
        minimumTrustToVerify: -100,
        claimLifetimeTicks: 64,
        messageLifetimeTicks: 48,
        maximumFactsPerAgent: 8,
        maximumBeliefsPerAgent: 8,
        maximumTrustRelations: 32,
        maximumRetainedMessages: 32,
        shareCooldownTicks: 1
    )
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 144,
            nearbyRadius: 16,
            resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 64),
            survivalConfiguration: survival,
            socialConfiguration: social
        ),
        agents: reversed ? Array(agents.reversed()) : agents,
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: causalMaximumEvents)
    )
    try! session.setSocialEnabled(true)
    try! session.setKnowledgeGraphEnabled(
        true,
        configuration: knowledgeConfiguration
    )
    _ = try! session.advanceTick(perceptions: [
        AgentPerceptionInput(
            agentId: communicationAuthor.rawValue,
            socialResourceObservations: [AgentResourceObservation(
                resource: .wood,
                target: AgentPosition(x: 2, y: 64, z: 0),
                direction: .east,
                distanceManhattan: 2,
                quantityAvailable: 1,
                source: .naturalWorld,
                expectedBlockFingerprint: 44_001
            )]
        ),
    ])
    let propositionID = session.knowledgeSnapshot().beliefs.first {
        $0.ownerID == communicationAuthor && $0.stance == .accepted
    }!.propositionID
    precondition(
        !session.knowledgeSnapshot().beliefs.contains {
            $0.ownerID == communicationDestination
        },
        "CIV-44 fixture accidentally informed remote destination"
    )
    try! session.setLanguageEnabled(
        true,
        configuration: try! AgentLanguageConfiguration(
            maximumLexicalAssociations: 64,
            maximumLexicalAssociationsPerAgent: 16,
            maximumCommunicationRecords: 64,
            exposuresRequiredForLearning: 1
        ),
        pack: .frenchReference
    )
    try! session.setOralTransmissionEnabled(
        true,
        configuration: try! AgentOralConfiguration(
            maximumTransmissionRecords: 32,
            maximumFaithfulDistance: 1
        )
    )
    try! session.seedLanguagePrior(
        for: communicationAuthor,
        senseIDs: communicationSenseIDs
    )
    try! session.setAutonomousActivityEnabled(true)
    if enableLongDistance {
        try! session.setLongDistanceCommunicationEnabled(
            true,
            configuration: transportConfiguration
        )
    }
    return (session, propositionID)
}

private func communicationNavigationObservation(
    origin: AgentPosition,
    target: AgentPosition,
    tick: Int
) -> AgentNavigationObservation {
    let range = min(origin.x, target.x)...max(origin.x, target.x)
    return AgentNavigationObservation(
        worldTick: tick,
        origin: origin,
        target: target,
        cells: range.map { x in
            let position = AgentPosition(x: x, y: origin.y, z: origin.z)
            return AgentNavigationCell(
                position: position,
                status: position == target ? .blocked : .traversable
            )
        }
    )
}

private func communicationMovementOutcomes(
    result: AgentSessionTickResult,
    session: AgentSimulationSession,
    carrierID: AgentID,
    carrierStatus: AgentMovementStatus
) -> [AgentMovementOutcome] {
    let resultByID = Dictionary(uniqueKeysWithValues:
        result.agents.map { ($0.agentId, $0) }
    )
    return session.snapshot().agents.sorted { $0.id < $1.id }.map { agent in
        let isCarrier = agent.id == carrierID.rawValue
        let action = resultByID[agent.id]!.action
        let direction: AgentCardinalDirection?
        switch (action.dx, action.dz) {
        case (1, 0): direction = isCarrier ? .east : nil
        case (-1, 0): direction = isCarrier ? .west : nil
        case (0, -1): direction = isCarrier ? .north : nil
        case (0, 1): direction = isCarrier ? .south : nil
        default: direction = nil
        }
        let moved = isCarrier && carrierStatus == .moved
        let destination = moved && direction != nil
            ? AgentPosition(
                x: agent.position.x + direction!.dx,
                y: agent.position.y,
                z: agent.position.z + direction!.dz
            )
            : agent.position
        let before = abs(agent.position.x - agent.homePosition.x)
            + abs(agent.position.y - agent.homePosition.y)
            + abs(agent.position.z - agent.homePosition.z)
        let after = abs(destination.x - agent.homePosition.x)
            + abs(destination.y - agent.homePosition.y)
            + abs(destination.z - agent.homePosition.z)
        return AgentMovementOutcome(
            agentId: agent.id,
            tick: session.tick,
            status: isCarrier ? carrierStatus : .notRequested,
            fromPosition: agent.position,
            toPosition: destination,
            requestedDirection: direction,
            requestedDX: direction?.dx ?? 0,
            requestedDY: 0,
            requestedDZ: direction?.dz ?? 0,
            appliedDX: moved ? (direction?.dx ?? 0) : 0,
            appliedDY: 0,
            appliedDZ: moved ? (direction?.dz ?? 0) : 0,
            goalKind: agent.currentGoal.kind,
            actionReason: action.reason,
            resolutionReason: moved
                ? "accepted generic civilization movement"
                : "no accepted movement",
            worldTickObserved: session.tick,
            distanceFromHomeBefore: before,
            distanceFromHomeAfter: after,
            distanceReducedTowardHome: max(0, before - after)
        )
    }
}

private func communicationAdvance(
    session: inout AgentSimulationSession,
    transportID: AgentCommunicationTransportID,
    carrierStatus: AgentMovementStatus = .moved
) {
    let record = session.longDistanceCommunicationSnapshot().transports.first {
        $0.transportID == transportID
    }!
    let carrier = session.snapshot().agents.first {
        $0.id == record.carrierID.rawValue
    }!
    let destination = session.snapshot().agents.first {
        $0.id == record.destinationID.rawValue
    }!
    let result = try! session.advanceTick(perceptions: [
        AgentPerceptionInput(
            agentId: record.carrierID.rawValue,
            navigationObservation: communicationNavigationObservation(
                origin: carrier.position,
                target: destination.position,
                tick: session.tick
            )
        ),
    ])
    if carrierStatus == .moved {
        let carrierResult = result.agents.first {
            $0.agentId == record.carrierID.rawValue
        }
        precondition(
            carrierResult?.action.name == "approach_activity",
            "CIV-44 carrier did not use generic activity navigation; agents="
                + result.agents.map(\.agentId).joined(separator: ",")
        )
    }
    try! session.applyMovementOutcomes(
        communicationMovementOutcomes(
            result: result,
            session: session,
            carrierID: record.carrierID,
            carrierStatus: carrierStatus
        )
    )
}

@discardableResult
private func communicationReachArrival(
    session: inout AgentSimulationSession,
    transportID: AgentCommunicationTransportID
) -> AgentCommunicationTransport {
    let candidates = session.longDistanceCommunicationActivityCandidates()
    precondition(candidates.count == 1)
    _ = try! session.selectAutonomousActivities(candidates)
    for _ in 0..<32 {
        let record = session.longDistanceCommunicationSnapshot().transports
            .first { $0.transportID == transportID }!
        if record.status != .inTransit { return record }
        communicationAdvance(session: &session, transportID: transportID)
    }
    preconditionFailure("CIV-44 transport did not terminate bounded travel")
}

private func communicationVerifiedReconciliationMovements(
    session: AgentSimulationSession,
    agentID: AgentID,
    dx: Int,
    status: AgentMovementStatus = .moved
) -> [AgentVerifiedPhysicalMovement] {
    session.snapshot().agents.sorted {
        $0.id < $1.id
    }.map { agent -> AgentVerifiedPhysicalMovement in
        let moving = agent.id == agentID.rawValue
        let to = moving
            ? AgentPosition(
                x: agent.position.x + dx,
                y: agent.position.y,
                z: agent.position.z
            ) : agent.position
        let before = abs(agent.position.x - agent.homePosition.x)
            + abs(agent.position.y - agent.homePosition.y)
            + abs(agent.position.z - agent.homePosition.z)
        let after = abs(to.x - agent.homePosition.x)
            + abs(to.y - agent.homePosition.y)
            + abs(to.z - agent.homePosition.z)
        return AgentVerifiedPhysicalMovement(
            kind: .reconciliation,
            outcome: AgentMovementOutcome(
                agentId: agent.id,
                tick: session.tick,
                status: moving ? status : .notRequested,
                fromPosition: agent.position,
                toPosition: to,
                requestedDirection: nil,
                requestedDX: 0,
                requestedDY: 0,
                requestedDZ: 0,
                appliedDX: moving ? dx : 0,
                appliedDY: 0,
                appliedDZ: 0,
                goalKind: agent.currentGoal.kind,
                actionReason: "verified physical reconciliation",
                resolutionReason: moving
                    ? "accepted verified physical reconciliation"
                    : "no accepted movement",
                worldTickObserved: session.tick,
                distanceFromHomeBefore: before,
                distanceFromHomeAfter: after,
                distanceReducedTowardHome: max(0, before - after)
            )
        )
    }
}

private func communicationApplyVerifiedReconciliationStep(
    session: inout AgentSimulationSession,
    agentID: AgentID,
    dx: Int
) {
    let outcomes = communicationVerifiedReconciliationMovements(
        session: session,
        agentID: agentID,
        dx: dx
    )
    try! session.applyVerifiedPhysicalMovements(outcomes)
}

@discardableResult
private func communicationReachArrivalThroughVerifiedReconciliation(
    session: inout AgentSimulationSession,
    transportID: AgentCommunicationTransportID
) -> AgentCommunicationTransport {
    for _ in 0..<32 {
        let record = session.longDistanceCommunicationSnapshot().transports
            .first { $0.transportID == transportID }!
        if record.status != .inTransit { return record }
        let carrier = session.snapshot().agents.first {
            $0.id == record.carrierID.rawValue
        }!
        let destination = session.snapshot().agents.first {
            $0.id == record.destinationID.rawValue
        }!
        communicationApplyVerifiedReconciliationStep(
            session: &session,
            agentID: record.carrierID,
            dx: destination.position.x > carrier.position.x ? 1 : -1
        )
    }
    preconditionFailure("CIV-44 verified reconciliation did not arrive")
}

private func communicationRefusal(
    _ name: String,
    session: AgentSimulationSession,
    operation: (inout AgentSimulationSession) throws -> Void,
    matches: (Error) -> Bool
) {
    let before = try! session.durableStateDigest()
    var candidate = session
    do {
        try operation(&candidate)
        check(name, false, "accepted")
    } catch {
        check(name, matches(error), "\(error)")
    }
    check(
        "\(name) is an exact atomic no-op",
        try! candidate.durableStateDigest() == before
    )
}

private func communicationResignedCheckpoint(
    _ checkpoint: AgentSessionCheckpoint,
    mutateDurable: (inout [String: Any]) -> Void
) -> AgentSessionCheckpoint {
    var root = try! JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(checkpoint)
    ) as! [String: Any]
    var durable = root["durableState"] as! [String: Any]
    mutateDurable(&durable)
    let mutatedBytes = try! JSONSerialization.data(
        withJSONObject: durable,
        options: [.sortedKeys, .withoutEscapingSlashes]
    )
    let mutatedState = try! AgentCheckpointCodec.decode(
        AgentSessionDurableState.self,
        from: mutatedBytes
    )
    let canonicalBytes = try! AgentCheckpointCodec.encode(mutatedState)
    let canonical = try! JSONSerialization.jsonObject(
        with: canonicalBytes
    ) as! [String: Any]
    let clock = canonical["clock"] as! [String: Any]
    let simulationID = clock["simulationID"] as! String
    let tick = clock["tick"] as! Int
    let digest = AgentCheckpointDigest.sha256(canonicalBytes)
    let simulationDigest = AgentCheckpointDigest.sha256(
        Data(simulationID.utf8)
    )
    root["durableState"] = canonical
    root["schemaVersion"] = canonical["schemaVersion"]
    root["semanticDigest"] = digest.rawValue
    root["checkpointID"] =
        "checkpoint-\(simulationDigest.rawValue.prefix(12))"
            + "-t\(tick)-\(digest.rawValue.prefix(16))"
    return try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self,
        from: JSONSerialization.data(
            withJSONObject: root,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
    )
}

private func communicationRestoreError(
    _ checkpoint: AgentSessionCheckpoint
) -> String? {
    do {
        _ = try AgentSimulationSession.restoring(checkpoint)
        return nil
    } catch AgentSessionError.longDistanceCommunication(
        .invalidState(let reason)
    ) {
        return "communication:\(reason)"
    } catch {
        return "unexpected:\(error)"
    }
}

private func communicationCompleted(
    id: String,
    reversed: Bool = false,
    renderingMode: AgentLanguageRenderingMode = .noRendering
) -> (AgentSimulationSession, AgentCommunicationTransport) {
    var (session, propositionID) = communicationPrepared(
        id: id,
        reversed: reversed
    )
    let transport = try! session.beginLongDistanceCommunication(
        authorID: communicationAuthor,
        carrierID: communicationCarrier,
        destinationID: communicationDestination,
        propositionID: propositionID,
        renderingMode: renderingMode
    )
    _ = communicationReachArrival(
        session: &session,
        transportID: transport.transportID
    )
    let delivered = try! session.deliverLongDistanceCommunication(
        transportID: transport.transportID,
        renderingMode: renderingMode
    )
    return (session, delivered)
}

private enum CommunicationTerminalEvictionRoute: Equatable {
    case pickup
    case delivery
}

private struct CommunicationTerminalEvictionResult {
    let session: AgentSimulationSession
    let transportID: AgentCommunicationTransportID
    let dependentTransmissionID: AgentOralTransmissionID
    let controlCheckpoint: AgentSessionCheckpoint
    let replayVerified: Bool
    let expectedDeathCount: Int
}

private func communicationTerminalEvictionScenario(
    id: String,
    route: CommunicationTerminalEvictionRoute
) -> CommunicationTerminalEvictionResult {
    let isDelivery = route == .delivery
    let lethalID = isDelivery
        ? communicationDestination : communicationCarrier
    let pressureID = isDelivery
        ? communicationCarrier : communicationDestination
    var (session, propositionID) = communicationPrepared(
        id: id,
        knowledgeConfiguration: communicationKnowledgeConfiguration(
            maximumBeliefs: isDelivery ? 4 : 3
        ),
        lethalID: lethalID,
        healthByAgentID: [pressureID: 60],
        starvationDamagePerTick: 20
    )
    let started = try! session.beginLongDistanceCommunication(
        authorID: communicationAuthor,
        carrierID: communicationCarrier,
        destinationID: communicationDestination,
        propositionID: propositionID,
        renderingMode: .noRendering
    )
    let terminal: AgentCommunicationTransport
    if isDelivery {
        _ = communicationReachArrivalThroughVerifiedReconciliation(
            session: &session,
            transportID: started.transportID
        )
        terminal = try! session.deliverLongDistanceCommunication(
            transportID: started.transportID,
            renderingMode: .noRendering
        )
        communicationApplyVerifiedReconciliationStep(
            session: &session,
            agentID: communicationCarrier,
            dx: -1
        )
        communicationApplyVerifiedReconciliationStep(
            session: &session,
            agentID: communicationCarrier,
            dx: -1
        )
    } else {
        terminal = started
        communicationApplyVerifiedReconciliationStep(
            session: &session,
            agentID: communicationCarrier,
            dx: 1
        )
        communicationApplyVerifiedReconciliationStep(
            session: &session,
            agentID: communicationCarrier,
            dx: 1
        )
    }
    let dependentTransmissionID = isDelivery
        ? terminal.deliveryTransmissionID! : terminal.pickupTransmissionID
    let preDeathBeliefOwner = isDelivery
        ? communicationDestination : communicationCarrier
    let preDeathPosition = session.snapshot().agents.first {
        $0.id == preDeathBeliefOwner.rawValue
    }!.position
    // The delivery route needs two terminal beliefs from its first death,
    // while the oldest one must remain the CIV-43-dependent delivery belief
    // so one later eviction exercises the reviewed dependency. Cell +4 gives
    // that deterministic belief-ID order without changing production policy.
    let preDeathObservationDistance = isDelivery ? 4 : 1
    _ = try! session.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: preDeathBeliefOwner.rawValue,
        socialResourceObservations: [AgentResourceObservation(
            resource: .stone,
            target: AgentPosition(
                x: preDeathPosition.x + preDeathObservationDistance,
                y: preDeathPosition.y,
                z: preDeathPosition.z
            ),
            direction: .east,
            distanceManhattan: preDeathObservationDistance,
            quantityAvailable: 1,
            source: .naturalWorld,
            expectedBlockFingerprint: isDelivery ? 44_004 : 44_003
        )]
    )])
    let dependentBeliefID = isDelivery
        ? terminal.destinationBeliefID! : terminal.carrierBeliefID
    let terminalOwnerBeliefs = session.knowledgeSnapshot().beliefs.filter {
        $0.ownerID == preDeathBeliefOwner
    }.sorted { $0.beliefID < $1.beliefID }
    precondition(
        terminalOwnerBeliefs.first?.beliefID == dependentBeliefID,
        "CIV-44 terminal-eviction fixture lost deterministic dependency order"
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 0)
    )
    let pressurePosition = session.snapshot().agents.first {
        $0.id == pressureID.rawValue
    }!.position
    let pressurePerception = AgentPerceptionInput(
        agentId: pressureID.rawValue,
        socialResourceObservations: [
            AgentResourceObservation(
                resource: .wood,
                target: AgentPosition(
                    x: pressurePosition.x + 1,
                    y: pressurePosition.y,
                    z: pressurePosition.z
                ),
                direction: .east,
                distanceManhattan: 1,
                quantityAvailable: 1,
                source: .naturalWorld,
                expectedBlockFingerprint: isDelivery ? 44_006 : 44_005
            ),
            AgentResourceObservation(
                resource: .stone,
                target: AgentPosition(
                    x: pressurePosition.x - 1,
                    y: pressurePosition.y,
                    z: pressurePosition.z
                ),
                direction: .west,
                distanceManhattan: 1,
                quantityAvailable: 1,
                source: .naturalWorld,
                expectedBlockFingerprint: isDelivery ? 44_008 : 44_007
            ),
        ]
    )
    let base = try! session.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(
        checkpoint: base,
        session: session
    )
    _ = try! recorder.apply(.setSurvivalEnabled(true), to: &session)
    _ = try! recorder.apply(
        .setMortalityEnabled(true, configuration: .live),
        to: &session
    )
    _ = try! recorder.apply(
        .advanceTick(perceptions: [], physicalObservations: []),
        to: &session
    )
    _ = try! recorder.apply(
        .advanceTick(
            perceptions: [pressurePerception],
            physicalObservations: []
        ),
        to: &session
    )
    precondition(
        !session.snapshot().agents.contains { $0.id == lethalID.rawValue },
        "CIV-44 terminal-eviction fixture did not finalize first death"
    )
    let controlCheckpoint = try! session.makeCheckpoint()
    for _ in 0..<8 where session.oralTransmissionSnapshot()
        .transmissions.contains(where: {
            $0.transmissionID == dependentTransmissionID
        }) {
        _ = try! recorder.apply(
            .advanceTick(perceptions: [], physicalObservations: []),
            to: &session
        )
    }
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: id)!
    )
    let replay = try! AgentSessionReplayer.replay(
        checkpoint: base,
        journal: journal
    )
    return CommunicationTerminalEvictionResult(
        session: session,
        transportID: started.transportID,
        dependentTransmissionID: dependentTransmissionID,
        controlCheckpoint: controlCheckpoint,
        replayVerified: replay.report.verified
            && replay.report.finalSemanticDigest
                == (try! session.durableStateDigest()),
        expectedDeathCount: 2
    )
}

private func communicationTerminalEvictionProof() {
    for (route, label) in [
        (CommunicationTerminalEvictionRoute.pickup, "pickup"),
        (CommunicationTerminalEvictionRoute.delivery, "delivery"),
    ] {
        let result = communicationTerminalEvictionScenario(
            id: "civ44-terminal-eviction-\(label)",
            route: route
        )
        let controlTransport = result.controlCheckpoint.durableState
            .longDistanceCommunicationState!.transports.first {
                $0.transportID == result.transportID
            }
        let controlOral = result.controlCheckpoint.durableState
            .oralTransmissionState!.transmissions
        let finalTransport = result.session.longDistanceCommunicationSnapshot()
        let finalOral = result.session.oralTransmissionSnapshot()
        let finalKnowledge = result.session.knowledgeSnapshot()
        let controlKnowledge = result.controlCheckpoint.durableState
            .knowledgeGraphState!
        let controlBeliefsByOwner = Dictionary(
            grouping: controlKnowledge.beliefs,
            by: { $0.ownerID.rawValue }
        ).mapValues(\.count)
        let controlHealthByOwner = Dictionary(
            uniqueKeysWithValues: result.controlCheckpoint.durableState
                .agents.map { ($0.id, $0.health) }
        )
        let terminalEvictionDetail = [
            "controlBeliefs=\(controlBeliefsByOwner)",
            "controlHealth=\(controlHealthByOwner)",
            "controlTick=\(result.controlCheckpoint.durableState.clock.tick.rawValue)",
            "controlDeparted=\((controlKnowledge.departedBeliefs ?? []).count)",
            "departed=\(finalKnowledge.departedBeliefs.count)",
            "departedEvicted=\(finalKnowledge.departedBeliefEvictionCount)",
            "beliefs=\(finalKnowledge.beliefs.count)",
            "deaths=\(result.session.mortalitySnapshot().totalDeathCount)",
            "live=\(result.session.snapshot().agents.map(\.id).sorted())",
        ].joined(separator: " ")
        check("\(label) dependency is initially retained after death",
            controlTransport != nil
                && controlTransport!.status.isTerminal
                && controlOral.contains {
                    $0.transmissionID == result.dependentTransmissionID
                })
        check("\(label) departed-belief pressure performs real eviction",
            finalKnowledge.departedBeliefEvictionCount > 0
                && result.session.mortalitySnapshot().totalDeathCount
                    == result.expectedDeathCount,
            terminalEvictionDetail)
        check("\(label) CIV-43 eviction leaves no CIV-44 orphan",
            !finalOral.transmissions.contains {
                $0.transmissionID == result.dependentTransmissionID
            }
                && !finalTransport.transports.contains {
                    $0.transportID == result.transportID
                }
                && finalTransport.evictedTransportCount == 1
                && finalTransport.totalStartedCount == 1,
            terminalEvictionDetail)
        let checkpoint = try! result.session.makeCheckpoint()
        let checkpointBytes = try! AgentCheckpointCodec.encode(checkpoint)
        let restartExact: Bool
        let restartDetail: String
        do {
            let restored = try AgentSimulationSession.restoring(checkpoint)
            let restoredBytes = try AgentCheckpointCodec.encode(
                restored.makeCheckpoint()
            )
            restartExact = restoredBytes == checkpointBytes
                && !restored.longDistanceCommunicationSnapshot()
                    .transports.contains {
                        $0.transportID == result.transportID
                    }
            restartDetail = restartExact
                ? "exact" : "restored bytes or retained transport diverged"
        } catch {
            restartExact = false
            restartDetail = "\(error)"
        }
        check("\(label) reconciled checkpoint restarts without resurrection",
            restartExact, restartDetail)
        check("\(label) terminal reconciliation replays exactly",
            result.replayVerified)

        let oldTransportState = result.controlCheckpoint.durableState
            .longDistanceCommunicationState!
        let staleResurrection = communicationResignedCheckpoint(checkpoint) {
            durable in
            let oldBytes = try! AgentCheckpointCodec.encode(
                oldTransportState
            )
            durable["longDistanceCommunicationState"] =
                try! JSONSerialization.jsonObject(with: oldBytes)
        }
        check("\(label) former authentic transport cannot resurrect",
            communicationRestoreError(staleResurrection) != nil)
    }
}

private func communicationMobileDestinationProof() {
    var (session, propositionID) = communicationPrepared(
        id: "civ44-mobile-destination"
    )
    let transport = try! session.beginLongDistanceCommunication(
        authorID: communicationAuthor,
        carrierID: communicationCarrier,
        destinationID: communicationDestination,
        propositionID: propositionID,
        renderingMode: .noRendering
    )
    let carrierStart = session.snapshot().agents.first {
        $0.id == communicationCarrier.rawValue
    }!.position
    let beforeUnauthorizedRewrite = try! session.durableStateDigest()
    var unauthorizedRewrite = session
    let unauthorizedDX = carrierStart.x
        - session.snapshot().agents.first {
            $0.id == communicationDestination.rawValue
        }!.position.x
    let unauthorizedRejected: Bool
    do {
        try unauthorizedRewrite.applyVerifiedPhysicalMovements(
            communicationVerifiedReconciliationMovements(
                session: unauthorizedRewrite,
                agentID: communicationDestination,
                dx: unauthorizedDX,
                status: .notRequested
            )
        )
        unauthorizedRejected = false
    } catch AgentSessionError.invalidStationaryMovement(let agentID) {
        unauthorizedRejected = agentID == communicationDestination.rawValue
    } catch {
        unauthorizedRejected = false
    }
    let unauthorizedTransport = unauthorizedRewrite
        .longDistanceCommunicationSnapshot().transports.first {
            $0.transportID == transport.transportID
        }
    check("abstract destination position rewrite is refused atomically",
        unauthorizedRejected
            && (try! unauthorizedRewrite.durableStateDigest())
                == beforeUnauthorizedRewrite
            && unauthorizedTransport?.status == .inTransit
            && !unauthorizedRewrite.knowledgeSnapshot().beliefs.contains {
                $0.ownerID == communicationDestination
            })
    for _ in 0..<16 {
        let carrier = session.snapshot().agents.first {
            $0.id == communicationCarrier.rawValue
        }!
        let destination = session.snapshot().agents.first {
            $0.id == communicationDestination.rawValue
        }!
        if abs(carrier.position.x - destination.position.x)
                + abs(carrier.position.y - destination.position.y)
                + abs(carrier.position.z - destination.position.z) <= 1 {
            break
        }
        let destinationActivity = AgentAutonomousActivityCandidate(
            candidateID: "mobile-destination-activity",
            actorID: communicationDestination,
            domain: .materialHandling,
            actionKey: "meet_carrier",
            stableReference: "mobile-destination-activity",
            target: carrier.position,
            logicalTargetKey: "mobile-destination-target",
            physicalTarget: carrier.position,
            approachPosition: carrier.position,
            materialFingerprint: "mobile-destination-accepted-movement",
            source: .responsibility,
            priorityBand: 15,
            urgency: 80,
            continuity: true,
            distance: abs(destination.position.x - carrier.position.x)
                + abs(destination.position.y - carrier.position.y)
                + abs(destination.position.z - carrier.position.z),
            observedAtTick: session.tick
        )
        _ = try! session.selectAutonomousActivities(
            session.longDistanceCommunicationActivityCandidates()
                + [destinationActivity]
        )
        let result = try! session.advanceTick(perceptions: [
            AgentPerceptionInput(
                agentId: communicationCarrier.rawValue,
                navigationObservation: communicationNavigationObservation(
                    origin: carrier.position,
                    target: destination.position,
                    tick: session.tick
                )
            ),
            AgentPerceptionInput(
                agentId: communicationDestination.rawValue,
                navigationObservation: communicationNavigationObservation(
                    origin: destination.position,
                    target: carrier.position,
                    tick: session.tick
                )
            ),
        ])
        try! session.applyMovementOutcomes(
            communicationMovementOutcomes(
                result: result,
                session: session,
                carrierID: communicationDestination,
                carrierStatus: .moved
            )
        )
    }
    let arrived = session.longDistanceCommunicationSnapshot().transports
        .first { $0.transportID == transport.transportID }!
    let arrivalEvent = arrived.arrivalEventID.flatMap { arrivalID in
        session.causalLedgerSnapshot().events.first {
            $0.eventID == arrivalID
        }
    }
    let acceptedDestinationMovement = arrivalEvent?.causes.contains {
        causeID in
        session.causalLedgerSnapshot().events.contains { event in
            guard event.eventID == causeID,
                  event.kind == .movement,
                  event.origin == .worldOutcome,
                  event.actorID == communicationDestination,
                  case let .movement(status, _, _) = event.payload else {
                return false
            }
            return status == AgentMovementStatus.moved.rawValue
        }
    } == true
    check("accepted destination movement can causally satisfy arrival",
        arrived.status == .arrived
            && arrived.progress.isEmpty
            && arrived.arrivalPosition == carrierStart
            && acceptedDestinationMovement)
}

private func communicationReplayProof() {
    // The published predecessor schema is the replay base. Enabling CIV-44
    // must be the first v39 operation.
    let predecessor = communicationPreparedWithoutLongDistance(
        id: "civ44-replay"
    )
    var session = predecessor.0
    let propositionID = predecessor.1
    let predecessorCheckpoint = try! session.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(
        checkpoint: predecessorCheckpoint,
        session: session
    )
    _ = try! recorder.apply(
        .setLongDistanceCommunicationEnabled(true, configuration: .live),
        to: &session
    )
    let pickup = try! recorder.apply(
        .beginLongDistanceCommunication(
            authorID: communicationAuthor,
            carrierID: communicationCarrier,
            destinationID: communicationDestination,
            propositionID: propositionID,
            renderingMode: .noRendering,
            acceptedPickupEffect: nil
        ),
        to: &session
    ).oralTransmissionResult!
    let transportID = session.longDistanceCommunicationSnapshot()
        .transports[0].transportID
    _ = try! recorder.apply(
        .selectAutonomousActivities(
            session.longDistanceCommunicationActivityCandidates()
        ),
        to: &session
    )
    for _ in 0..<32 {
        let transport = session.longDistanceCommunicationSnapshot()
            .transports[0]
        if transport.status != .inTransit { break }
        let carrier = session.snapshot().agents.first {
            $0.id == transport.carrierID.rawValue
        }!
        let destination = session.snapshot().agents.first {
            $0.id == transport.destinationID.rawValue
        }!
        let result = try! recorder.apply(
            .advanceTick(
                perceptions: [AgentPerceptionInput(
                    agentId: transport.carrierID.rawValue,
                    navigationObservation: communicationNavigationObservation(
                        origin: carrier.position,
                        target: destination.position,
                        tick: session.tick
                    )
                )],
                physicalObservations: []
            ),
            to: &session
        ).tickResult!
        _ = try! recorder.apply(
            .movementOutcomes(communicationMovementOutcomes(
                result: result,
                session: session,
                carrierID: transport.carrierID,
                carrierStatus: .moved
            )),
            to: &session
        )
    }
    _ = try! recorder.apply(
        .deliverLongDistanceCommunication(
            transportID: transportID,
            renderingMode: .noRendering,
            acceptedDeliveryEffect: nil
        ),
        to: &session
    )
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "civ44-replay")!
    )
    let replay = try! AgentSessionReplayer.replay(
        checkpoint: predecessorCheckpoint,
        journal: journal
    )
    check("schema-38 predecessor checkpoint remains supported",
        predecessorCheckpoint.schemaVersion
            == AgentCheckpointSchema.oralTransmissionVersion)
    check("replay schema advances to 39",
        journal.manifest.schemaVersion
            == AgentReplaySchema.longDistanceCommunicationVersion)
    check("replay journals accepted pickup and delivery effects",
        journal.records.contains { record in
            if case .beginLongDistanceCommunication(
                _, _, _, _, _, let effect
            ) = record.operation { return effect != nil }
            return false
        } && journal.records.contains { record in
            if case .deliverLongDistanceCommunication(
                _, _, let effect
            ) = record.operation { return effect != nil }
            return false
        })
    check("replay reproduces exact CIV-44 durable state",
        replay.report.verified
            && replay.report.finalSemanticDigest
                == (try! session.durableStateDigest()))
    check("repeated replay duplicates no transport authority",
        try! AgentSessionReplayer.replay(
            checkpoint: predecessorCheckpoint,
            journal: journal
        ).report.finalSemanticDigest == replay.report.finalSemanticDigest)

    let pickupEffect = journal.records.compactMap { record in
        if case .beginLongDistanceCommunication(
            _, _, _, _, _, let effect?
        ) = record.operation { return effect }
        return nil
    }.first!
    let deliveryIndex = journal.records.firstIndex { record in
        if case .deliverLongDistanceCommunication = record.operation {
            return true
        }
        return false
    }!
    let originalDelivery = journal.records[deliveryIndex]
    guard case let .deliverLongDistanceCommunication(
        deliveryTransportID, deliveryRenderingMode, _
    ) = originalDelivery.operation else {
        preconditionFailure("CIV-44 replay delivery fixture")
    }
    let forgedDelivery = AgentReplayRecord(
        schemaVersion: originalDelivery.schemaVersion,
        simulationID: originalDelivery.simulationID,
        recordSequence: originalDelivery.recordSequence,
        operation: .deliverLongDistanceCommunication(
            transportID: deliveryTransportID,
            renderingMode: deliveryRenderingMode,
            acceptedDeliveryEffect: pickupEffect
        ),
        expectedTickBefore: originalDelivery.expectedTickBefore,
        preStateSemanticDigest: originalDelivery.preStateSemanticDigest,
        postStateSemanticDigest: originalDelivery.postStateSemanticDigest,
        causalSequenceBefore: originalDelivery.causalSequenceBefore,
        causalSequenceAfter: originalDelivery.causalSequenceAfter,
        causalDigestAfter: originalDelivery.causalDigestAfter
    )
    var forgedRecords = journal.records
    forgedRecords[deliveryIndex] = forgedDelivery
    let forgedBytes = try! AgentReplayCodec.encodeRecords(forgedRecords)
    let forgedJournal = AgentReplayJournal(
        manifest: AgentReplayJournalManifest(
            schemaVersion: journal.manifest.schemaVersion,
            name: journal.manifest.name,
            baseCheckpointID: journal.manifest.baseCheckpointID,
            baseCheckpointDigest: journal.manifest.baseCheckpointDigest,
            simulationID: journal.manifest.simulationID,
            initialTick: journal.manifest.initialTick,
            recordCount: forgedRecords.count,
            droppedRecordCount: journal.manifest.droppedRecordCount,
            replayable: journal.manifest.replayable,
            nonReplayableReason: journal.manifest.nonReplayableReason,
            operationsStorageDigest:
                AgentCheckpointDigest.sha256(forgedBytes),
            operationsByteLength: forgedBytes.count
        ),
        records: forgedRecords
    )
    let hostileReplay = try! AgentSessionReplayer.replay(
        checkpoint: predecessorCheckpoint,
        journal: forgedJournal
    )
    check("re-signed replay cannot substitute pickup effect at delivery",
        !hostileReplay.report.verified
            && hostileReplay.report.recordsApplied == deliveryIndex)

    let future = AgentReplayJournal(
        manifest: AgentReplayJournalManifest(
            schemaVersion:
                AgentReplaySchema.longDistanceCommunicationVersion + 1,
            name: journal.manifest.name,
            baseCheckpointID: journal.manifest.baseCheckpointID,
            baseCheckpointDigest: journal.manifest.baseCheckpointDigest,
            simulationID: journal.manifest.simulationID,
            initialTick: journal.manifest.initialTick,
            recordCount: journal.manifest.recordCount,
            droppedRecordCount: journal.manifest.droppedRecordCount,
            replayable: journal.manifest.replayable,
            nonReplayableReason: journal.manifest.nonReplayableReason,
            operationsStorageDigest:
                journal.manifest.operationsStorageDigest,
            operationsByteLength: journal.manifest.operationsByteLength
        ),
        records: journal.records
    )
    let futureRejected: Bool
    do {
        _ = try AgentSessionReplayer.replay(
            checkpoint: predecessorCheckpoint,
            journal: future
        )
        futureRejected = false
    } catch AgentReplayError.unsupportedSchema(let version) {
        futureRejected = version
            == AgentReplaySchema.longDistanceCommunicationVersion + 1
    } catch {
        futureRejected = false
    }
    check("future replay schema 40 is refused", futureRejected)
    print(
        "  CIV44_REPLAY records=\(journal.records.count) "
            + "pickup=\(pickup.transmissionID.rawValue) "
            + "schema=\(journal.manifest.schemaVersion) "
            + "verified=\(replay.report.verified)"
    )
}

private func communicationPreparedWithoutLongDistance(
    id: String
) -> (AgentSimulationSession, AgentKnowledgePropositionID) {
    communicationPrepared(id: id, enableLongDistance: false)
}

private func communicationCompactionProof() {
    let configuration = try! AgentLongDistanceCommunicationConfiguration(
        maximumRetainedTransports: 1,
        maximumJourneySteps: 16,
        maximumTransportDistance: 16
    )
    var (session, propositionID) = communicationPrepared(
        id: "civ44-compaction",
        transportConfiguration: configuration
    )
    let first = try! session.beginLongDistanceCommunication(
        authorID: communicationAuthor,
        carrierID: communicationCarrier,
        destinationID: communicationDestination,
        propositionID: propositionID,
        renderingMode: .noRendering
    )
    communicationRefusal(
        "active transport is never compacted for admission",
        session: session,
        operation: {
            _ = try $0.beginLongDistanceCommunication(
                authorID: communicationAuthor,
                carrierID: communicationCarrier,
                destinationID: communicationDestination,
                propositionID: propositionID,
                renderingMode: .noRendering
            )
        },
        matches: {
            if case AgentSessionError.longDistanceCommunication(
                .carrierBusy
            ) = $0 { return true }
            return false
        }
    )
    _ = communicationReachArrival(
        session: &session,
        transportID: first.transportID
    )
    _ = try! session.deliverLongDistanceCommunication(
        transportID: first.transportID,
        renderingMode: .noRendering
    )
    propositionID = session.knowledgeSnapshot().beliefs.first {
        $0.ownerID == communicationDestination && $0.stance == .accepted
    }!.propositionID
    let second = try! session.beginLongDistanceCommunication(
        authorID: communicationDestination,
        carrierID: communicationCarrier,
        destinationID: communicationAuthor,
        propositionID: propositionID,
        renderingMode: .noRendering
    )
    let snapshot = session.longDistanceCommunicationSnapshot()
    check("terminal-only transport compaction is exact and bounded",
        snapshot.transports.map(\.transportID) == [second.transportID]
            && snapshot.evictedTransportCount == 1
            && snapshot.totalStartedCount == 2)
    let restored = try! AgentSimulationSession.restoring(
        session.makeCheckpoint()
    )
    check("compacted transport boundary restarts without resurrection",
        restored.longDistanceCommunicationSnapshot() == snapshot)

    let stepBound = try! AgentLongDistanceCommunicationConfiguration(
        maximumRetainedTransports: 2,
        maximumJourneySteps: 1,
        maximumTransportDistance: 16
    )
    var (bounded, boundedProposition) = communicationPrepared(
        id: "civ44-step-bound",
        transportConfiguration: stepBound
    )
    let boundedTransport = try! bounded.beginLongDistanceCommunication(
        authorID: communicationAuthor,
        carrierID: communicationCarrier,
        destinationID: communicationDestination,
        propositionID: boundedProposition,
        renderingMode: .noRendering
    )
    _ = try! bounded.selectAutonomousActivities(
        bounded.longDistanceCommunicationActivityCandidates()
    )
    communicationAdvance(
        session: &bounded,
        transportID: boundedTransport.transportID
    )
    communicationAdvance(
        session: &bounded,
        transportID: boundedTransport.transportID
    )
    let boundedResult = bounded.longDistanceCommunicationSnapshot()
        .transports[0]
    check("journey-step bound fails closed without destination effect",
        boundedResult.status == .failed
            && boundedResult.failure == .journeyStepLimit
            && boundedResult.progress.count == 1
            && !bounded.knowledgeSnapshot().beliefs.contains {
                $0.ownerID == communicationDestination
            })
}

private func communicationMortalityProof() {
    for (lethalID, expectedFailure, label) in [
        (
            communicationCarrier,
            AgentCommunicationTransportFailure.carrierDied,
            "carrier"
        ),
        (
            communicationDestination,
            AgentCommunicationTransportFailure.destinationDied,
            "destination"
        ),
    ] {
        var (session, propositionID) = communicationPrepared(
            id: "civ44-mortality-\(label)",
            lethalID: lethalID
        )
        let transport = try! session.beginLongDistanceCommunication(
            authorID: communicationAuthor,
            carrierID: communicationCarrier,
            destinationID: communicationDestination,
            propositionID: propositionID,
            renderingMode: .noRendering
        )
        if lethalID == communicationDestination {
            _ = communicationReachArrival(
                session: &session,
                transportID: transport.transportID
            )
        }
        try! session.initializePopulationRegistry(
            settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
            receptionPosition: AgentPosition(x: 0, y: 64, z: 0)
        )
        session.setSurvivalEnabled(true)
        try! session.setMortalityEnabled(true)
        for _ in 0..<64 where session.snapshot().agents.contains(where: {
            $0.id == lethalID.rawValue
        }) {
            _ = try! session.advanceTick()
        }
        let failed = session.longDistanceCommunicationSnapshot()
            .transports[0]
        check("\(label) death terminates transport without delivery",
            failed.status == .failed
                && failed.failure == expectedFailure
                && failed.deliveryTransmissionID == nil
                && !session.knowledgeSnapshot().beliefs.contains {
                    $0.ownerID == communicationDestination
                        && lethalID != communicationDestination
                })
        let restored = try! AgentSimulationSession.restoring(
            session.makeCheckpoint()
        )
        check("\(label) death restart cannot resurrect transport",
            restored.longDistanceCommunicationSnapshot().transports[0]
                .status == .failed
                && !restored.snapshot().agents.contains {
                    $0.id == lethalID.rawValue
                })
    }

    var (authorDeath, propositionID) = communicationPrepared(
        id: "civ44-mortality-author",
        lethalID: communicationAuthor
    )
    let transport = try! authorDeath.beginLongDistanceCommunication(
        authorID: communicationAuthor,
        carrierID: communicationCarrier,
        destinationID: communicationDestination,
        propositionID: propositionID,
        renderingMode: .noRendering
    )
    try! authorDeath.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 0)
    )
    authorDeath.setSurvivalEnabled(true)
    try! authorDeath.setMortalityEnabled(true)
    for _ in 0..<64 where authorDeath.snapshot().agents.contains(where: {
        $0.id == communicationAuthor.rawValue
    }) {
        _ = try! authorDeath.advanceTick()
    }
    check("author death after accepted pickup preserves historical message",
        authorDeath.longDistanceCommunicationSnapshot().transports[0]
            .status == .inTransit
            && !authorDeath.snapshot().agents.contains {
                $0.id == communicationAuthor.rawValue
            })
    let authorDeathRestored = try! AgentSimulationSession.restoring(
        authorDeath.makeCheckpoint()
    )
    check("historically attributed pickup survives author lifecycle exit",
        authorDeathRestored.longDistanceCommunicationSnapshot().transports[0]
            .transportID == transport.transportID
            && authorDeathRestored.longDistanceCommunicationSnapshot()
                .transports[0].authorID == communicationAuthor
            && authorDeathRestored.longDistanceCommunicationSnapshot()
                .transports[0].status == .inTransit)
}

private func communicationCausalCompactionProof() {
    var (session, propositionID) = communicationPrepared(
        id: "civ44-causal-compaction",
        causalMaximumEvents: 64
    )
    let transport = try! session.beginLongDistanceCommunication(
        authorID: communicationAuthor,
        carrierID: communicationCarrier,
        destinationID: communicationDestination,
        propositionID: propositionID,
        renderingMode: .noRendering
    )
    _ = communicationReachArrival(
        session: &session,
        transportID: transport.transportID
    )
    _ = try! session.deliverLongDistanceCommunication(
        transportID: transport.transportID,
        renderingMode: .noRendering
    )
    let snapshot = session.longDistanceCommunicationSnapshot()
    let causal = session.causalLedgerSnapshot()
    let restored = try! AgentSimulationSession.restoring(
        session.makeCheckpoint()
    )
    check("causal FIFO compaction retains exact current transport authority",
        causal.summary.droppedEventCount > 0
            && snapshot.provenanceBoundary != nil
            && restored.longDistanceCommunicationSnapshot() == snapshot)
}

func runPebbleAgentsLongDistanceCommunicationSmoke() {
    section("CIV-44 compositional long-distance communication V1")

    var (session, propositionID) = communicationPrepared(
        id: "civ44-decisive"
    )
    let predecessor = communicationPreparedWithoutLongDistance(
        id: "civ44-predecessor"
    ).0
    check("published schema-38 checkpoint still restores exactly",
        try! AgentCheckpointCodec.encode(
            AgentSimulationSession.restoring(predecessor.makeCheckpoint())
                .makeCheckpoint()
        ) == (try! AgentCheckpointCodec.encode(predecessor.makeCheckpoint())))

    communicationRefusal(
        "remote CIV-43 call cannot provide free delivery",
        session: session,
        operation: {
            _ = try $0.transmitOralClaim(
                speakerID: communicationAuthor,
                recipientID: communicationDestination,
                propositionID: propositionID,
                renderingMode: .noRendering
            )
        },
        matches: {
            if case AgentSessionError.oral(.nonLocal) = $0 { return true }
            return false
        }
    )
    var directCIV42 = session
    let directCIV42Knowledge = directCIV42.knowledgeSnapshot()
    let directCIV42Record = try! directCIV42
        .communicateLanguageSemanticContent(
        speakerID: communicationAuthor,
        recipientID: communicationDestination,
        propositionID: propositionID,
        renderingMode: .noRendering
    )
    check("direct remote CIV-42 call creates no CIV-44 or CIV-41 delivery",
        directCIV42Record.recipientID == communicationDestination
            && directCIV42.longDistanceCommunicationSnapshot()
                .transports.isEmpty
            && directCIV42.knowledgeSnapshot().evidence
                == directCIV42Knowledge.evidence
            && directCIV42.knowledgeSnapshot().claims
                == directCIV42Knowledge.claims
            && directCIV42.knowledgeSnapshot().understandings
                == directCIV42Knowledge.understandings
            && directCIV42.knowledgeSnapshot().beliefs
                == directCIV42Knowledge.beliefs
            && directCIV42.knowledgeSnapshot().revisions
                == directCIV42Knowledge.revisions
            && !directCIV42.knowledgeSnapshot().beliefs.contains {
                $0.ownerID == communicationDestination
            })
    let transport = try! session.beginLongDistanceCommunication(
        authorID: communicationAuthor,
        carrierID: communicationCarrier,
        destinationID: communicationDestination,
        propositionID: propositionID,
        renderingMode: .noRendering
    )
    let pickupCheckpoint = try! session.makeCheckpoint()
    let pickupRestored = try! AgentSimulationSession.restoring(
        pickupCheckpoint
    )
    let evidenceBefore = session.knowledgeSnapshot().evidence
    let migrationBefore = session.migrationSnapshot()
    check("pickup captures semantic identity without informing destination",
        transport.status == .inTransit
            && transport.originSemanticContentDigest.count == 64
            && transport.carriedSemanticContentDigest.count == 64
            && transport.carrierBeliefRevisionEventID.sequence
                < transport.dispatchEventID.sequence
            && !session.knowledgeSnapshot().beliefs.contains {
                $0.ownerID == communicationDestination
            })
    check("checkpoint restart during transport preserves no-delivery state",
        pickupRestored.longDistanceCommunicationSnapshot()
            == session.longDistanceCommunicationSnapshot()
            && !pickupRestored.knowledgeSnapshot().beliefs.contains {
                $0.ownerID == communicationDestination
            })
    check("communication activity uses generic non-migration navigation",
        session.longDistanceCommunicationActivityCandidates().first?.domain
            == .communication
            && session.migrationSnapshot() == migrationBefore)
    communicationRefusal(
        "explicit delivery before arrival is refused",
        session: session,
        operation: {
            _ = try $0.deliverLongDistanceCommunication(
                transportID: transport.transportID,
                renderingMode: .noRendering
            )
        },
        matches: {
            if case AgentSessionError.longDistanceCommunication(
                .transportNotArrived
            ) = $0 { return true }
            return false
        }
    )

    var neverArrived = session
    _ = try! neverArrived.selectAutonomousActivities(
        neverArrived.longDistanceCommunicationActivityCandidates()
    )
    communicationAdvance(
        session: &neverArrived,
        transportID: transport.transportID,
        carrierStatus: .blocked
    )
    let blocked = neverArrived.longDistanceCommunicationSnapshot()
        .transports[0]
    check("transport that never receives accepted movement never progresses",
        blocked.status == .inTransit
            && blocked.progress.isEmpty
            && !neverArrived.knowledgeSnapshot().beliefs.contains {
                $0.ownerID == communicationDestination
            })

    let arrived = communicationReachArrival(
        session: &session,
        transportID: transport.transportID
    )
    let causal = session.causalLedgerSnapshot().events
    check("arrival is composed only from accepted movement publications",
        arrived.status == .arrived
            && arrived.progress.count == arrived.initialDistance - 1
            && arrived.progress.allSatisfy { step in
                causal.contains {
                    $0.eventID == step.movementEventID
                        && $0.kind == .movement
                        && $0.origin == .worldOutcome
                }
            })
    check("arrival alone still has no destination epistemic effect",
        !session.knowledgeSnapshot().beliefs.contains {
            $0.ownerID == communicationDestination
        })
    check("carrier travel never changes migration or residence authority",
        session.migrationSnapshot() == migrationBefore)

    var independentlyRevised = session
    _ = try! independentlyRevised.advanceTick(perceptions: [
        AgentPerceptionInput(
            agentId: communicationCarrier.rawValue,
            socialResourceObservations: [AgentResourceObservation(
                resource: .stone,
                target: AgentPosition(x: 2, y: 64, z: 0),
                direction: .west,
                distanceManhattan: 5,
                quantityAvailable: 1,
                source: .naturalWorld,
                expectedBlockFingerprint: 44_002
            )]
        ),
    ])
    communicationRefusal(
        "independent carrier belief revision cannot rewrite carried content",
        session: independentlyRevised,
        operation: {
            _ = try $0.deliverLongDistanceCommunication(
                transportID: transport.transportID,
                renderingMode: .noRendering
            )
        },
        matches: {
            if case AgentSessionError.longDistanceCommunication(
                .carrierBeliefChanged
            ) = $0 { return true }
            return false
        }
    )

    let reaffirmedCarrierBelief = session.knowledgeSnapshot().beliefs.first {
        $0.ownerID == communicationCarrier
            && $0.beliefID == transport.carrierBeliefID
    }!
    check("same-content carrier reaffirmation preserves pickup commitment",
        reaffirmedCarrierBelief.propositionID
            == transport.carriedPropositionID
            && reaffirmedCarrierBelief.lastRevisionEventID.sequence
                > transport.carrierBeliefRevisionEventID.sequence)

    let delivered = try! session.deliverLongDistanceCommunication(
        transportID: transport.transportID,
        renderingMode: .noRendering
    )
    let oral = session.oralTransmissionSnapshot().transmissions
    let pickup = oral.first {
        $0.transmissionID == delivered.pickupTransmissionID
    }!
    let handoff = oral.first {
        $0.transmissionID == delivered.deliveryTransmissionID
    }!
    let destinationBelief = session.knowledgeSnapshot().beliefs.first {
        $0.ownerID == communicationDestination
            && $0.beliefID == delivered.destinationBeliefID
    }!
    check("delivered chain reconstructs source, author, carrier and destination",
        pickup.speakerID == delivered.authorID
            && pickup.recipientID == delivered.carrierID
            && pickup.sourceAuthorityID == delivered.sourceAuthorityID
            && pickup.interpretedSemanticContent.digest
                == delivered.carriedSemanticContentDigest
            && handoff.speakerID == delivered.carrierID
            && handoff.recipientID == delivered.destinationID
            && handoff.sourceBeliefRevisionEventID.sequence
                > delivered.carrierBeliefRevisionEventID.sequence
            && handoff.transmittedSemanticContent.digest
                == delivered.carriedSemanticContentDigest
            && destinationBelief.propositionID
                == handoff.interpretedSemanticContent.sourcePropositionID)
    check("NO_RENDERING is a complete normal delivery path",
        session.languageSnapshot().communications.filter {
            $0.communicationID == pickup.languageCommunicationID
                || $0.communicationID == handoff.languageCommunicationID
        }.allSatisfy { $0.rendering == .noRendering })
    check("information transport never mutates observation/world truth",
        session.knowledgeSnapshot().evidence == evidenceBefore)
    check("delivery terminates the communication activity only after handoff",
        delivered.status == .delivered
            && session.autonomousActivitySnapshot().activeActivities.isEmpty)

    let checkpoint = try! session.makeCheckpoint()
    let bytes = try! AgentCheckpointCodec.encode(checkpoint)
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    check("schema-39 restart preserves the exact transport graph",
        checkpoint.schemaVersion
            == AgentCheckpointSchema.longDistanceCommunicationVersion
            && restored.longDistanceCommunicationSnapshot()
                == session.longDistanceCommunicationSnapshot())
    check("schema-39 restart remains byte exact",
        try! AgentCheckpointCodec.encode(restored.makeCheckpoint()) == bytes)

    let forgedContent = communicationResignedCheckpoint(checkpoint) {
        durable in
        var state = durable["longDistanceCommunicationState"]
            as! [String: Any]
        var records = state["transports"] as! [[String: Any]]
        records[0]["carriedSemanticContentDigest"] =
            String(repeating: "0", count: 64)
        state["transports"] = records
        durable["longDistanceCommunicationState"] = state
    }
    check("re-signed carried-content substitution is rejected",
        communicationRestoreError(forgedContent) != nil)

    let pickupRoot = try! JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(pickupCheckpoint)
    ) as! [String: Any]
    let pickupDurable = pickupRoot["durableState"] as! [String: Any]
    let staleState = pickupDurable["longDistanceCommunicationState"]!
    let staleResurrection = communicationResignedCheckpoint(checkpoint) {
        durable in
        durable["longDistanceCommunicationState"] = staleState
    }
    check("formerly authentic boundary cannot resurrect in-transit authority",
        communicationRestoreError(staleResurrection)?.contains(
            "transport provenance boundary"
        ) == true)

    let future = communicationResignedCheckpoint(checkpoint) { durable in
        durable["schemaVersion"] =
            AgentCheckpointSchema.longDistanceCommunicationVersion + 1
    }
    let futureRejected: Bool
    do {
        _ = try AgentSimulationSession.restoring(future)
        futureRejected = false
    } catch AgentCheckpointError.unsupportedSchema(let version) {
        futureRejected = version
            == AgentCheckpointSchema.longDistanceCommunicationVersion + 1
    } catch {
        futureRejected = false
    }
    check("future checkpoint schema 40 is refused", futureRejected)

    let ordered = communicationCompleted(
        id: "civ44-order",
        reversed: false,
        renderingMode: .deterministicCompositional
    ).0
    let reversed = communicationCompleted(
        id: "civ44-order",
        reversed: true,
        renderingMode: .deterministicCompositional
    ).0
    check("registration order does not change transport or knowledge history",
        ordered.longDistanceCommunicationSnapshot().digest
            == reversed.longDistanceCommunicationSnapshot().digest
            && ordered.knowledgeSnapshot().digest
                == reversed.knowledgeSnapshot().digest)
    check("deterministic compositional rendering remains non-authoritative",
        ordered.languageSnapshot().communications.allSatisfy {
            $0.rendering.text != nil
        })

    communicationReplayProof()
    communicationCompactionProof()
    communicationCausalCompactionProof()
    communicationMortalityProof()
    communicationTerminalEvictionProof()
    communicationMobileDestinationProof()

    print(
        "  CIV44_CHAIN transport=\(delivered.transportID.rawValue) "
            + "author=\(delivered.authorID.rawValue) "
            + "carrier=\(delivered.carrierID.rawValue) "
            + "destination=\(delivered.destinationID.rawValue) "
            + "pickup=\(pickup.transmissionID.rawValue) "
            + "steps=\(delivered.progress.count) "
            + "arrival=\(delivered.arrivalEventID!.rawValue) "
            + "delivery=\(delivered.deliveryEventID!.rawValue) "
            + "semantic=\(delivered.carriedSemanticContentDigest)"
    )
    print(
        "  CIV44_RESTART schema=\(checkpoint.schemaVersion) "
            + "digest=\(checkpoint.semanticDigest.rawValue) "
            + "boundary=\(delivered.provenanceDigest)"
    )
}

func runPebbleAgentsLongDistanceCommunicationRestartWriteSmoke() {
    section("CIV-44 fresh-process checkpoint write")
    let session = communicationCompleted(id: "civ44-fresh-process").0
    let bytes = try! AgentCheckpointCodec.encode(session.makeCheckpoint())
    let path = ProcessInfo.processInfo.environment[
        "PEBBLELAB_CIV44_CHECKPOINT_PATH"
    ]!
    try! bytes.write(to: URL(fileURLWithPath: path), options: .atomic)
    check("CIV-44 fresh-process checkpoint write", !bytes.isEmpty)

    let terminal = communicationTerminalEvictionScenario(
        id: "civ44-fresh-process-terminal-eviction",
        route: .delivery
    ).session
    let terminalBytes = try! AgentCheckpointCodec.encode(
        terminal.makeCheckpoint()
    )
    try! terminalBytes.write(
        to: URL(fileURLWithPath: path + ".terminal-eviction"),
        options: .atomic
    )
    check("CIV-44 reconciled terminal checkpoint write",
        !terminalBytes.isEmpty
            && terminal.longDistanceCommunicationSnapshot()
                .transports.isEmpty)
}

func runPebbleAgentsLongDistanceCommunicationRestartReadSmoke() {
    section("CIV-44 fresh-process checkpoint read")
    let path = ProcessInfo.processInfo.environment[
        "PEBBLELAB_CIV44_CHECKPOINT_PATH"
    ]!
    let bytes = try! Data(contentsOf: URL(fileURLWithPath: path))
    let checkpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self,
        from: bytes
    )
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    check("CIV-44 fresh-process schema is 39",
        checkpoint.schemaVersion
            == AgentCheckpointSchema.longDistanceCommunicationVersion)
    check("CIV-44 fresh-process delivery survives",
        restored.longDistanceCommunicationSnapshot().transports.count == 1
            && restored.longDistanceCommunicationSnapshot().transports[0]
                .status == .delivered)
    check("CIV-44 fresh-process bytes remain exact",
        try! AgentCheckpointCodec.encode(restored.makeCheckpoint()) == bytes)

    let terminalBytes = try! Data(
        contentsOf: URL(fileURLWithPath: path + ".terminal-eviction")
    )
    let terminalCheckpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self,
        from: terminalBytes
    )
    let terminalRestored = try! AgentSimulationSession.restoring(
        terminalCheckpoint
    )
    check("CIV-44 fresh-process terminal reconciliation survives",
        terminalRestored.longDistanceCommunicationSnapshot()
            .transports.isEmpty
            && terminalRestored.longDistanceCommunicationSnapshot()
                .evictedTransportCount == 1)
    check("CIV-44 fresh-process terminal bytes remain exact",
        try! AgentCheckpointCodec.encode(
            terminalRestored.makeCheckpoint()
        ) == terminalBytes)
}
