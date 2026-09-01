import Foundation
import PebbleAgents

private func knowledgeLifecycleAgent(
    _ id: String,
    x: Int,
    hunger: Double = 0,
    health: Int = 100,
    lethalNextTick: Bool = false
) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id,
        state: "idle",
        position: position,
        needs: AgentNeeds(
            hunger: lethalNextTick ? 1 : hunger,
            fatigue: 0,
            curiosity: 0,
            safety: 1
        ),
        health: lethalNextTick ? 10 : health,
        fear: 0,
        homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle,
            reason: "CIV-41 Correction 01 fixture",
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
        survivalProgress: AgentSurvivalProgress(
            status: lethalNextTick ? .starving : .stable,
            consecutiveCriticalHungerTicks: lethalNextTick ? 2 : 0
        )
    )
}

private func knowledgeLifecyclePerception(
    observerID: AgentID,
    observerX: Int,
    targetX: Int,
    observerZ: Int = 0,
    targetZ: Int = 0,
    fingerprint: Int
) -> AgentPerceptionInput {
    AgentPerceptionInput(
        agentId: observerID.rawValue,
        socialResourceObservations: [AgentResourceObservation(
            resource: .wood,
            target: AgentPosition(x: targetX, y: 64, z: targetZ),
            direction: targetX < observerX ? .west : .east,
            distanceManhattan:
                abs(targetX - observerX) + abs(targetZ - observerZ),
            quantityAvailable: 1,
            source: .naturalWorld,
            expectedBlockFingerprint: fingerprint
        )]
    )
}

private func knowledgeLifecycleSession(
    _ id: String,
    lethalID: String = "agent_0",
    additionalLethalID: String? = nil
) -> AgentSimulationSession {
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
            seed: 1_041,
            nearbyRadius: 16,
            resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 64),
            socialConfiguration: social
        ),
        agents: [
            knowledgeLifecycleAgent(
                "agent_0", x: 0,
                hunger: lethalID == "agent_0"
                    || additionalLethalID == "agent_0" ? 0 : -10
            ),
            knowledgeLifecycleAgent(
                "agent_1", x: 1,
                hunger: lethalID == "agent_1"
                    || additionalLethalID == "agent_1" ? 0 : -10
            ),
            knowledgeLifecycleAgent("agent_2", x: 20, hunger: -10),
        ],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 16_384)
    )
    try! session.setSocialEnabled(true)
    try! session.setKnowledgeGraphEnabled(true)
    return session
}

@discardableResult
private func knowledgeLifecycleDeliverClaim(
    _ session: inout AgentSimulationSession
) -> AgentKnowledgeSourceClaim {
    let sourceID = AgentID(rawValue: "agent_0")!
    _ = try! session.advanceTick(perceptions: [knowledgeLifecyclePerception(
        observerID: sourceID,
        observerX: 0,
        targetX: 2,
        fingerprint: 41_001
    )])
    for _ in 0..<8 where session.knowledgeSnapshot().claims.isEmpty {
        _ = try! session.advanceTick()
    }
    let claim = session.knowledgeSnapshot().claims.first
    precondition(claim != nil, "real local source claim was not delivered")
    return claim!
}

private func knowledgeLifecyclePreparedDeath(
    _ id: String,
    lethalID: String = "agent_0",
    additionalLethalID: String? = nil
) -> AgentSimulationSession {
    var session = knowledgeLifecycleSession(
        id, lethalID: lethalID, additionalLethalID: additionalLethalID
    )
    _ = knowledgeLifecycleDeliverClaim(&session)
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 0)
    )
    return session
}

private func knowledgeLifecycleFinalizeDeath(
    _ session: inout AgentSimulationSession,
    agentID: String = "agent_0"
) {
    session.setSurvivalEnabled(true)
    try! session.setMortalityEnabled(true)
    for _ in 0..<64 where session.snapshot().agents.contains(where: {
        $0.id == agentID
    }) {
        _ = try! session.advanceTick()
    }
    precondition(!session.snapshot().agents.contains {
        $0.id == agentID
    }, "informed agent did not die through mortality")
}

private let knowledgeLifecycleHabitats = (0..<3).map { ordinal in
    AgentEcologyHabitatObservation(
        worldTick: 0,
        candidateIndex: ordinal,
        habitatPosition: AgentPosition(
            x: ordinal * 2 + 1, y: 63, z: 0
        ),
        foragePosition: AgentPosition(
            x: ordinal * 2 + 1, y: 64, z: 0
        ),
        habitatFingerprint: 41_100 + ordinal,
        distanceFromSettlement: ordinal * 2 + 1,
        directionIndex: ordinal,
        worldReadCount: 4
    )
}

private func knowledgeLifecycleFeedFounders(
    _ session: inout AgentSimulationSession
) {
    let intents = (0..<3).compactMap { ordinal -> AgentForageIntent? in
        let agentID = AgentID(rawValue: "agent_\(ordinal)")!
        guard let state = try? session.state(for: agentID),
              state.needs.hunger >= 0.8 else { return nil }
        let habitat = knowledgeLifecycleHabitats[ordinal]
        return AgentForageIntent(
            forageID:
                "civ41-churn-feed-agent_\(ordinal)-t\(session.tick)",
            patchID: habitat.patchID,
            agentID: agentID,
            tick: session.tick,
            target: habitat.foragePosition,
            observedAtTick: session.tick,
            expectedHabitatFingerprint: habitat.habitatFingerprint
        )
    }
    guard !intents.isEmpty else { return }
    let outcomes = try! session.applyForageIntents(
        intents, habitatValidations: knowledgeLifecycleHabitats
    )
    precondition(outcomes.allSatisfy { $0.status == .succeeded })
    for intent in intents.sorted(by: { $0.agentID < $1.agentID }) {
        let outcome = try! session.consumeFood(AgentConsumptionIntent(
            consumptionId:
                "civ41-churn-consume-\(intent.agentID.rawValue)-t\(session.tick)",
            agentId: intent.agentID.rawValue,
            tick: session.tick
        ))
        precondition(outcome.status == .succeeded)
    }
}

@discardableResult
private func knowledgeLifecycleChurnAdvance(
    _ session: inout AgentSimulationSession,
    perceptions: [AgentPerceptionInput] = []
) -> AgentSessionTickResult {
    let result = try! session.advanceTick(perceptions: perceptions)
    _ = try! session.applyLocalEcologyEndOfTick(
        habitatValidations: knowledgeLifecycleHabitats
    )
    knowledgeLifecycleFeedFounders(&session)
    return result
}

private func knowledgeLifecycleChurn(
    reversed: Bool
) -> (AgentKnowledgeSnapshot, AgentMortalitySnapshot, Int) {
    let survival = try! AgentSurvivalConfiguration(
        hungerPerTick: 0.45,
        fatiguePerTick: AgentSurvivalConfiguration.live.fatiguePerTick,
        hungryThreshold: 0.8,
        criticalHungerThreshold: 0.9,
        hungerRecoveryThreshold:
            AgentSurvivalConfiguration.live.hungerRecoveryThreshold,
        fatigueThreshold: AgentSurvivalConfiguration.live.fatigueThreshold,
        fatigueRecoveryThreshold:
            AgentSurvivalConfiguration.live.fatigueRecoveryThreshold,
        foodNutrition: AgentSurvivalConfiguration.live.foodNutrition,
        restRecoveryPerTick:
            AgentSurvivalConfiguration.live.restRecoveryPerTick,
        starvationGraceTicks: 1,
        starvationDamagePerTick: 100
    )
    let knowledge = try! AgentKnowledgeConfiguration(
        maximumPropositions: 32,
        maximumEvidence: 32,
        maximumClaims: 16,
        maximumUnderstandings: 32,
        maximumBeliefs: 16,
        maximumRevisions: 32,
        maximumEvidencePerAgent: 16,
        maximumClaimsPerAgent: 16,
        maximumUnderstandingsPerAgent: 16,
        maximumBeliefsPerAgent: 16,
        maximumRevisionsPerAgent: 32
    )
    let lifecycle = try! AgentLifecycleConfiguration(
        newbornDurationTicks: 2,
        maturityAgeTicks: 8,
        reproductionEvaluationIntervalTicks: 1,
        reproductionPlanDelayTicks: 1,
        reproductionCooldownTicks: 1,
        maximumConcurrentPlans: 1,
        maximumBirthsPerTick: 1,
        maximumRetainedBirthRecords: 64,
        maximumRetainedPlanRecords: 64,
        maximumParentBirthCount: 64,
        maximumBirthSiteCandidates: 16,
        birthSiteRadius: 4,
        maximumBirthSiteWorldReads: 128,
        maximumLifecycleFrames: 128
    )
    let ids = ["agent_0", "agent_1", "agent_2"]
    let xByID = ["agent_0": 0, "agent_1": 2, "agent_2": 4]
    let orderedIDs = reversed ? Array(ids.reversed()) : ids
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 1_042,
            nearbyRadius: 8,
            resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 64),
            survivalConfiguration: survival,
            socialConfiguration: try! AgentSocialConfiguration(
                shareCooldownTicks: 1
            )
        ),
        agents: orderedIDs.map {
            knowledgeLifecycleAgent($0, x: xByID[$0]!, hunger: -64)
        },
        simulationID: try! AgentSimulationID(
            validating: "civ41-correction-churn"
        ),
        causalLedgerPolicy: .bounded(maxEvents: 16_384)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 0),
        configuration: try! AgentPopulationConfiguration(
            maximumActivePopulation: 4,
            maximumMigrationRecords: 16
        )
    )
    try! session.initializeLocalEcology(
        observations: knowledgeLifecycleHabitats,
        configuration: try! AgentLocalEcologyConfiguration(
            maximumPatches: 3,
            maximumHabitatCandidates: 8,
            observationRadius: 8,
            patchCapacity: 4,
            initialYield: 4,
            regenerationIntervalTicks: 2,
            regenerationQuantity: 1,
            maximumForageIntentsPerTick: 8,
            maximumForageHistory: 128,
            maximumPressureFrames: 64,
            maximumHabitatReadsPerScan: 64
        )
    )
    _ = try! session.applyLocalEcologyEndOfTick(
        habitatValidations: knowledgeLifecycleHabitats
    )
    try! session.setSocialEnabled(true)
    try! session.setKnowledgeGraphEnabled(true, configuration: knowledge)
    try! session.setLifecycleEnabled(true, configuration: lifecycle)
    try! session.setReproductionEnabled(true)
    session.setSurvivalEnabled(true)
    try! session.setMortalityEnabled(true)

    let churnCount = knowledge.maximumBeliefsPerAgent + 1
    for index in 0..<churnCount {
        for _ in 0..<16 where session.pendingBirthSitePlan() == nil {
            _ = knowledgeLifecycleChurnAdvance(&session)
        }
        precondition(
            session.pendingBirthSitePlan() != nil,
            "real reproduction plan did not materialize at churn \(index) "
                + "tick=\(session.tick) active=\(session.expectedActiveAgentIDs().map(\.rawValue)) "
                + "lifecycle=\(session.lifecycleSummary()) reproduction=\(session.reproductionSnapshot()) "
                + "ecology=\(session.localEcologySummary())"
        )
        let plan = session.pendingBirthSitePlan()!
        let birth = try! session.applyBirthSiteObservation(
            AgentBirthSiteObservation(
                planID: plan.planID,
                observedTick: session.tick,
                position: AgentPosition(x: 0, y: 64, z: 4),
                candidateIndex: 0,
                worldFingerprint: 41_200 + index
            )
        )!
        _ = knowledgeLifecycleChurnAdvance(&session, perceptions: [
            knowledgeLifecyclePerception(
                observerID: birth.newbornID,
                observerX: 0,
                targetX: 1,
                observerZ: 4,
                targetZ: 4,
                fingerprint: 42_000 + index
            ),
        ])
        precondition(session.knowledgeSnapshot().beliefs.contains {
            $0.ownerID == birth.newbornID
        }, "born agent did not acquire knowledge through the product path")
        for _ in 0..<16 where session.snapshot().agents.contains(where: {
            $0.id == birth.newbornID.rawValue
        }) {
            _ = knowledgeLifecycleChurnAdvance(&session)
        }
        precondition(
            !session.snapshot().agents.contains {
                $0.id == birth.newbornID.rawValue
            },
            "born informed agent did not die at churn \(index)"
        )
    }

    _ = knowledgeLifecycleChurnAdvance(&session, perceptions: [knowledgeLifecyclePerception(
        observerID: AgentID(rawValue: "agent_0")!,
        observerX: 0,
        targetX: 1,
        fingerprint: 49_999
    )])
    return (
        session.knowledgeSnapshot(), session.mortalitySnapshot(),
        session.lifecycleSummary().totalBirthCount
    )
}

func runPebbleAgentsKnowledgeLifecycleRestartWriteSmoke() {
    section("CIV-41 Correction 01 departed cognition restart writer")
    guard let path = ProcessInfo.processInfo.environment[
        "PEBBLELAB_CIV41_CORRECTION_CHECKPOINT_PATH"
    ], !path.isEmpty else {
        check("correction writer receives checkpoint path", false)
        return
    }
    var session = knowledgeLifecyclePreparedDeath(
        "civ41-correction-fresh-process"
    )
    knowledgeLifecycleFinalizeDeath(&session)
    let checkpoint = try! session.makeCheckpoint()
    let bytes = try! AgentCheckpointCodec.encode(checkpoint)
    try! bytes.write(to: URL(fileURLWithPath: path), options: .atomic)
    let graph = session.knowledgeSnapshot()
    check("correction writer emits schema 36", checkpoint.schemaVersion == 36)
    check("correction writer has terminal history and no dead current owner",
          graph.departedBeliefs.count == 1
            && !graph.beliefs.contains {
                $0.ownerID.rawValue == "agent_0"
            })
    check("correction writer persists nonempty checkpoint", !bytes.isEmpty)
    print("  CIV41_CORRECTION_RESTART_WRITE bytes=\(bytes.count) schema=\(checkpoint.schemaVersion) digest=\(checkpoint.semanticDigest.rawValue) graph=\(graph.digest)")
}

func runPebbleAgentsKnowledgeLifecycleRestartReadSmoke() {
    section("CIV-41 Correction 01 departed cognition restart reader")
    guard let path = ProcessInfo.processInfo.environment[
        "PEBBLELAB_CIV41_CORRECTION_CHECKPOINT_PATH"
    ], !path.isEmpty else {
        check("correction reader receives checkpoint path", false)
        return
    }
    let bytes = try! Data(contentsOf: URL(fileURLWithPath: path))
    let checkpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self, from: bytes
    )
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    let graph = restored.knowledgeSnapshot()
    let reencoded = try! AgentCheckpointCodec.encode(
        restored.makeCheckpoint()
    )
    check("correction fresh process decodes schema 36",
          checkpoint.schemaVersion == 36)
    check("correction fresh process preserves exact checkpoint bytes",
          reencoded == bytes)
    check("correction restart does not resurrect departed cognition",
          graph.departedBeliefs.count == 1
            && !restored.snapshot().agents.contains {
                $0.id == "agent_0"
            }
            && !graph.beliefs.contains {
                $0.ownerID.rawValue == "agent_0"
            })
    check("correction restart preserves dead-source claim attribution",
          graph.claims.first?.sourceAgentID.rawValue == "agent_0"
            && graph.claims.first?.recipientID.rawValue == "agent_1")
    print("  CIV41_CORRECTION_RESTART_READ bytes=\(bytes.count) schema=\(checkpoint.schemaVersion) digest=\(checkpoint.semanticDigest.rawValue) graph=\(graph.digest)")
}

func runPebbleAgentsKnowledgeLifecycleSmoke() {
    section("CIV-41 Senior Review Correction 01 lifecycle composition")

    var session = knowledgeLifecyclePreparedDeath(
        "civ41-correction-decisive"
    )
    let before = session.knowledgeSnapshot()
    let recipientBefore = before.beliefs.first {
        $0.ownerID.rawValue == "agent_1"
    }!
    let remoteBefore = before.beliefs.filter {
        $0.ownerID.rawValue == "agent_2"
    }
    let base = try! session.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(
        checkpoint: base, session: session
    )
    _ = try! recorder.apply(.setSurvivalEnabled(true), to: &session)
    _ = try! recorder.apply(
        .setMortalityEnabled(true, configuration: .live), to: &session
    )
    for _ in 0..<64 where session.snapshot().agents.contains(where: {
        $0.id == "agent_0"
    }) {
        _ = try! recorder.apply(
            .advanceTick(perceptions: [], physicalObservations: []),
            to: &session
        )
    }
    let after = session.knowledgeSnapshot()
    let death = session.mortalitySnapshot().records.last!

    check("real mortality terminalizes an informed inhabitant",
          death.agentID.rawValue == "agent_0"
            && !session.snapshot().agents.contains {
                $0.id == "agent_0"
            })
    check("departed owner has no current CIV-41 authority",
          !after.beliefs.contains { $0.ownerID == death.agentID }
            && !after.understandings.contains { $0.ownerID == death.agentID }
            && !after.claims.contains { $0.recipientID == death.agentID }
            && !after.revisions.contains { $0.ownerID == death.agentID })
    let historical = after.departedBeliefs.first {
        $0.ownerID == death.agentID
    }
    check("terminal history preserves dead owner and direct basis",
          historical?.deathID == death.deathID
            && historical?.deathEventID == death.deathEventID
            && historical?.proposition.propositionID
                == before.beliefs.first {
                    $0.ownerID == death.agentID
                }?.propositionID
            && {
                guard case .evidence = historical?.basis else { return false }
                return true
            }())
    check("unrelated living and remote beliefs are unchanged",
          after.beliefs.first {
              $0.ownerID.rawValue == "agent_1"
          } == recipientBefore
            && after.beliefs.filter {
                $0.ownerID.rawValue == "agent_2"
            } == remoteBefore)
    let retainedClaim = after.claims.first
    check("source death preserves attributed recipient claim",
          retainedClaim?.sourceAgentID == death.agentID
            && retainedClaim?.recipientID.rawValue == "agent_1"
            && after.understandings.contains {
                $0.ownerID.rawValue == "agent_1"
                    && $0.basis == .sourceClaim(retainedClaim!.claimID)
            })
    check("dead source evidence is retained only as claim provenance",
          after.evidence.count == 1
            && after.evidence.first?.observerID == death.agentID
            && retainedClaim?.sourceEvidenceID == after.evidence.first?.evidenceID
            && after.evidence.first?.authority == .validatedWorldObservation)
    check("death creates no shared or magical knowledge",
          !after.beliefs.contains { $0.ownerID.rawValue == "agent_2" }
            && after.claims.count == 1
            && after.departedBeliefs.count == 1)

    var attributedDeath = knowledgeLifecyclePreparedDeath(
        "civ41-correction-attributed-death", lethalID: "agent_1"
    )
    let attributedBefore = attributedDeath.knowledgeSnapshot()
    let attributedClaim = attributedBefore.claims.first!
    let sourceBeliefBefore = attributedBefore.beliefs.first {
        $0.ownerID.rawValue == "agent_0"
    }
    knowledgeLifecycleFinalizeDeath(
        &attributedDeath, agentID: "agent_1"
    )
    let attributedAfter = attributedDeath.knowledgeSnapshot()
    let attributedHistory = attributedAfter.departedBeliefs.first
    check("departed hearsay remains a historical attributed claim", {
        guard attributedHistory?.ownerID.rawValue == "agent_1",
              case let .sourceClaim(
                claimID, sourceAgentID, sourceEvidenceID,
                sourceEvidenceAuthority, _, _, socialMessageID, _, _, _
              ) = attributedHistory?.basis else { return false }
        return claimID == attributedClaim.claimID
            && sourceAgentID.rawValue == "agent_0"
            && sourceEvidenceID == attributedClaim.sourceEvidenceID
            && sourceEvidenceAuthority == .validatedWorldObservation
            && socialMessageID == attributedClaim.socialMessageID
    }())
    check("recipient death neither promotes nor spreads historical hearsay",
          attributedAfter.beliefs.first {
              $0.ownerID.rawValue == "agent_0"
          } == sourceBeliefBefore
            && attributedAfter.claims.isEmpty
            && !attributedAfter.evidence.contains {
                $0.observerID.rawValue == "agent_1"
            }
            && !attributedAfter.beliefs.contains {
                $0.ownerID.rawValue == "agent_2"
            })

    var jointDeath = knowledgeLifecyclePreparedDeath(
        "civ41-correction-joint-death",
        lethalID: "agent_0",
        additionalLethalID: "agent_1"
    )
    knowledgeLifecycleFinalizeDeath(&jointDeath)
    for _ in 0..<64 where jointDeath.snapshot().agents.contains(where: {
        $0.id == "agent_1"
    }) {
        _ = try! jointDeath.advanceTick()
    }
    let jointAfter = jointDeath.knowledgeSnapshot()
    check("last recipient death releases dead-source live provenance",
          !jointDeath.snapshot().agents.contains { $0.id == "agent_1" }
            && jointAfter.departedBeliefs.count == 2
            && jointAfter.claims.isEmpty
            && jointAfter.understandings.isEmpty
            && jointAfter.beliefs.isEmpty
            && jointAfter.evidence.isEmpty)
    check("released provenance remains self-contained terminal history", {
        guard let terminalClaim = jointAfter.departedBeliefs.first(where: {
            $0.ownerID.rawValue == "agent_1"
        }), case let .sourceClaim(
            _, sourceAgentID, _, authority, _, _, _, _, _, _
        ) = terminalClaim.basis else { return false }
        return sourceAgentID.rawValue == "agent_0"
            && authority == .validatedWorldObservation
    }())

    let checkpoint = try! session.makeCheckpoint()
    let checkpointBytes = try! AgentCheckpointCodec.encode(checkpoint)
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    check("post-death schema-36 restore is byte and graph exact",
          checkpoint.schemaVersion == 36
            && (try! restored.durableStateBytes())
                == (try! session.durableStateBytes())
            && restored.knowledgeSnapshot() == after
            && (try! AgentCheckpointCodec.encode(restored.makeCheckpoint()))
                == checkpointBytes)
    check("post-death restore does not resurrect current cognition",
          !restored.snapshot().agents.contains { $0.id == "agent_0" }
            && !restored.knowledgeSnapshot().beliefs.contains {
                $0.ownerID.rawValue == "agent_0"
            })

    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "civ41-correction-death")!
    )
    let replayA = try! AgentSessionReplayer.replay(
        checkpoint: base, journal: journal
    )
    let replayB = try! AgentSessionReplayer.replay(
        checkpoint: base, journal: journal
    )
    check("mortality replay reproduces terminal cognition exactly once",
          replayA.report.verified
            && (try! replayA.session.durableStateBytes())
                == (try! session.durableStateBytes())
            && replayA.session.knowledgeSnapshot().departedBeliefs.count == 1
            && replayA.session.knowledgeSnapshot()
                == replayB.session.knowledgeSnapshot())

    let churnA = knowledgeLifecycleChurn(reversed: false)
    let churnB = knowledgeLifecycleChurn(reversed: true)
    check("real birth-knowledge-death churn exceeds current retention window",
          churnA.2 == 17
            && churnA.1.totalDeathCount == 17
            && churnA.0.departedBeliefs.count == 16
            && churnA.0.departedBeliefEvictionCount == 1)
    check("departed churn cannot consume living current-belief capacity",
          churnA.0.beliefs.count == 1
            && churnA.0.beliefs.first?.ownerID.rawValue == "agent_0"
            && churnA.0.understandings.allSatisfy {
                $0.ownerID.rawValue == "agent_0"
            })
    check("historical compaction preserves attribution without live pinning",
          churnA.0.departedBeliefs.allSatisfy {
              $0.ownerID.rawValue.hasPrefix("agent_")
                && $0.deathEventID.sequence
                    > $0.lastRevisionEventID.sequence
          }
            && churnA.0.claims.isEmpty
            && churnA.0.evidence.count == 1)
    check("birth/death compaction is registration-order deterministic",
          churnA.0 == churnB.0
            && churnA.1 == churnB.1
            && churnA.2 == churnB.2)

    let observer = session.observerSnapshot(
        worldBinding: try! AgentObserverWorldBinding(
            worldID: "civ41-correction-world",
            storageIdentity: "civ41-correction-storage",
            seed: 1_041,
            dimension: 0,
            observedWorldTick: session.tick
        )
    )
    check("Observer 14 exposes historical versus current cognition read-only",
          observer.header.schemaVersion == 14
            && observer.knowledge?.departedBeliefs == after.departedBeliefs
            && observer.knowledge?.beliefs == after.beliefs
            && session.knowledgeSnapshot() == after)

    print("  CIV41_CORRECTION_DEATH dead=\(death.agentID.rawValue) current=\(after.beliefs.count) historical=\(after.departedBeliefs.count) claims=\(after.claims.count) schema=\(checkpoint.schemaVersion) graph=\(after.digest)")
    print("  CIV41_CORRECTION_REPLAY records=\(journal.records.count) verified=\(replayA.report.verified) historical=\(replayA.session.knowledgeSnapshot().departedBeliefs.count)")
    print("  CIV41_CORRECTION_CHURN births=\(churnA.2) deaths=\(churnA.1.totalDeathCount) current=\(churnA.0.beliefs.count) historical=\(churnA.0.departedBeliefs.count)/\(churnA.0.configuration!.maximumDepartedBeliefs) historicalEvicted=\(churnA.0.departedBeliefEvictionCount) graph=\(churnA.0.digest)")
}
