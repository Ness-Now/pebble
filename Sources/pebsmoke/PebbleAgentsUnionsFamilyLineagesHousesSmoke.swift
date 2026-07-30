import Foundation
import PebbleAgents

private let familyHabitat = AgentEcologyHabitatObservation(
    worldTick: 0, candidateIndex: 0,
    habitatPosition: AgentPosition(x: 1, y: 63, z: 0),
    foragePosition: AgentPosition(x: 1, y: 64, z: 0),
    habitatFingerprint: 32_032, distanceFromSettlement: 1,
    directionIndex: 0, worldReadCount: 4
)

private func familyAgent(
    _ ordinal: Int,
    hunger: Double = 0,
    health: Int = 100,
    lethalNextTick: Bool = false
) -> AgentSessionAgentState {
    let position = AgentPosition(x: ordinal, y: 64, z: 0)
    let home = AgentPosition(x: ordinal * 8, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: position,
        needs: AgentNeeds(
            hunger: hunger, fatigue: 0, curiosity: 0.1, safety: 1
        ),
        health: health, fear: 0, homePosition: home, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "CIV-32 bounded family fixture",
            startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [],
        tickCreated: 0, ticksAlive: 0, observationCount: 0,
        nearbyObservationCount: 0, goalSelectionCount: 0,
        goalChangeCount: 0, actionCount: 0, actionEffectCount: 0,
        movementCount: 0, totalManhattanDistanceMoved: 0,
        returnHomeMoveCount: 0, totalDistanceReducedTowardHome: 0,
        survivalProgress: AgentSurvivalProgress(
            status: lethalNextTick ? .starving : .stable,
            consecutiveCriticalHungerTicks: lethalNextTick ? 2 : 0
        )
    )
}

private func familySession(
    _ simulationID: String,
    order: [Int] = [0, 1, 2],
    enableFamily: Bool = true,
    enableChildhood: Bool = true,
    enableReproduction: Bool = false,
    lethalFirstAgent: Bool = false,
    firstAgentHealth: Int = 100,
    maturityAgeTicks: Int = 2
) -> AgentSimulationSession {
    let survival = try! AgentSurvivalConfiguration(
        hungerPerTick: 0.001, fatiguePerTick: 0.001,
        hungryThreshold: 0.4, criticalHungerThreshold: 0.9,
        hungerRecoveryThreshold: 0.15, fatigueThreshold: 0.65,
        fatigueRecoveryThreshold: 0.2, foodNutrition: 1,
        restRecoveryPerTick: 1,
        starvationGraceTicks: lethalFirstAgent ? 0 : 10,
        starvationDamagePerTick: 100
    )
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 32, nearbyRadius: 8, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 128),
            survivalConfiguration: survival
        ),
        agents: order.map {
            familyAgent(
                $0, hunger: lethalFirstAgent && $0 == 0 ? 1 : 0,
                health: $0 == 0
                    ? (lethalFirstAgent ? 10 : firstAgentHealth) : 100,
                lethalNextTick: lethalFirstAgent && $0 == 0
            )
        },
        simulationID: try! AgentSimulationID(validating: simulationID),
        causalLedgerPolicy: .bounded(maxEvents: 32_768)
    )
    session.setSurvivalEnabled(true)
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3)
    )
    try! session.initializeLocalEcology(observations: [familyHabitat])
    _ = try! session.applyLocalEcologyEndOfTick(
        habitatValidations: [familyHabitat]
    )
    try! session.setMortalityEnabled(true)
    try! session.setLifecycleEnabled(
        true,
        configuration: try! AgentLifecycleConfiguration(
            newbornDurationTicks: 1, maturityAgeTicks: maturityAgeTicks,
            reproductionEvaluationIntervalTicks: 1,
            reproductionPlanDelayTicks: 1,
            reproductionCooldownTicks: 1,
            maximumRetainedBirthRecords: 64,
            maximumRetainedPlanRecords: 64,
            maximumParentBirthCount: 16
        )
    )
    if !lethalFirstAgent {
        try! session.setHomeostasisEnabled(
            true,
            configuration: try! AgentHomeostasisConfiguration(
                ageVulnerabilityStartTicks: 10_000,
                incapacityHealthThreshold: 20
            )
        )
        try! session.setGeneticsEnabled(true)
    }
    try! session.setKinshipEnabled(true)
    try! session.setHouseholdsEnabled(true)
    try! session.setDependentCareEnabled(true)
    if enableChildhood {
        try! session.setChildhoodV2Enabled(true)
    }
    if enableFamily {
        try! session.setFamilyV1Enabled(true)
    }
    if enableReproduction {
        try! session.setReproductionEnabled(true)
    }
    return session
}

private func familyReceipt(
    _ session: AgentSimulationSession,
    id: String,
    kind: AgentFamilyInteractionKind,
    actor: Int,
    counterparty: Int,
    communicationVerified: Bool = true
) -> AgentFamilyInteractionReceipt {
    let agents = Dictionary(uniqueKeysWithValues:
        session.snapshot().agents.map { ($0.id, $0) }
    )
    return AgentFamilyInteractionReceipt(
        receiptID: id, kind: kind,
        actorID: AgentID(rawValue: "agent_\(actor)")!,
        counterpartyID: AgentID(rawValue: "agent_\(counterparty)")!,
        observedTick: session.tick,
        actorPosition: agents["agent_\(actor)"]!.position,
        counterpartyPosition: agents["agent_\(counterparty)"]!.position,
        communicationVerified: communicationVerified
    )
}

private func familyBirth(
    _ session: inout AgentSimulationSession,
    position: AgentPosition = AgentPosition(x: 0, y: 64, z: 4)
) -> AgentBirthRecord {
    while session.pendingBirthSitePlan() == nil {
        _ = try! session.advanceTick()
    }
    let plan = session.pendingBirthSitePlan()!
    while session.tick < plan.dueTick {
        _ = try! session.advanceTick()
    }
    return try! session.applyBirthSiteObservation(AgentBirthSiteObservation(
        planID: plan.planID, observedTick: session.tick,
        position: position, candidateIndex: 0,
        worldFingerprint: 32_001
    ))!
}

private func familyMutatedCheckpoint(
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
    let state = try! AgentCheckpointCodec.decode(
        AgentSessionDurableState.self, from: mutationBytes
    )
    let durableBytes = try! AgentCheckpointCodec.encode(state)
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
    root["checkpointID"] = "checkpoint-\(simulationDigest.rawValue.prefix(12))"
        + "-t\(tick)-\(digest.rawValue.prefix(16))"
    return try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self,
        from: JSONSerialization.data(
            withJSONObject: root,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
    )
}

private func familyRestoreRefused(
    _ checkpoint: AgentSessionCheckpoint,
    mutate: (inout [String: Any]) -> Void
) -> Bool {
    do {
        _ = try AgentSimulationSession.restoring(
            familyMutatedCheckpoint(checkpoint, mutate: mutate)
        )
        return false
    } catch {
        return true
    }
}

func runPebbleAgentsUnionsFamilyLineagesHousesSmoke() {
    section("pebble agents unions family lineages houses V1")

    let live = AgentFamilyConfiguration.live
    check("family V1 configuration is explicitly bounded",
          live.maximumActiveUnionsPerAgent == 1
            && live.maximumPendingProposals == 64
            && live.maximumUnionHistory == 256
            && live.maximumLineageFoundationsPerPerson == 1
            && live.maximumProjectedAncestryDepth == 4
            && live.maximumFoundersPerHouse == 2
            && live.maximumTransitionsPerTick == 64)
    check("family V1 configuration Codable", (try? AgentCheckpointCodec.decode(
        AgentFamilyConfiguration.self,
        from: AgentCheckpointCodec.encode(live)
    )) == live)
    var missingChildhood = familySession(
        "sim-family-needs-childhood",
        enableFamily: false, enableChildhood: false
    )
    let missingChildhoodBytes = try! missingChildhood.durableStateBytes()
    check("family V1 activation requires the schema 24 childhood authority", {
        do {
            try missingChildhood.setFamilyV1Enabled(true)
            return false
        } catch AgentSessionError.family(.childhoodRequired) {
            return (try! missingChildhood.durableStateBytes())
                == missingChildhoodBytes
        } catch {
            return false
        }
    }())
    var boundedProjection = familySession(
        "sim-family-bounded-projection",
        enableFamily: false, enableReproduction: true
    )
    try! boundedProjection.setFamilyV1Enabled(
        true,
        configuration: try! AgentFamilyConfiguration(
            maximumProjectedRelationsPerPerson: 1
        )
    )
    let boundedChild = familyBirth(&boundedProjection)
    let boundedRelations = try! boundedProjection.familyRelationProjection(
        of: boundedChild.newbornID
    )
    let boundedObserver = boundedProjection.observerSnapshot(
        worldBinding: try! AgentObserverWorldBinding(
            worldID: "world-family-bounded",
            storageIdentity: "family-bounded-store",
            seed: 32, dimension: 0,
            observedWorldTick: boundedProjection.tick
        )
    )
    check("family relation projection exposes deterministic truncation",
          boundedRelations.relations.count == 1
            && boundedRelations.totalRelationCount == 2
            && boundedRelations.truncated
            && boundedObserver.individual(boundedChild.newbornID)?
                .family?.relationsTruncated == true)

    var invalidInteraction = familySession("sim-family-invalid-interaction")
    let invalidInteractionBytes = try! invalidInteraction.durableStateBytes()
    check("self-union is refused without publication", {
        let id = AgentID(rawValue: "agent_0")!
        let position = invalidInteraction.snapshot().agents.first {
            $0.id == id.rawValue
        }!.position
        do {
            _ = try invalidInteraction.proposeUnion(
                AgentFamilyInteractionReceipt(
                    receiptID: "self-union", kind: .unionProposal,
                    actorID: id, counterpartyID: id,
                    observedTick: invalidInteraction.tick,
                    actorPosition: position, counterpartyPosition: position,
                    communicationVerified: true
                )
            )
            return false
        } catch AgentSessionError.family(.prohibitedUnion) {
            return (try! invalidInteraction.durableStateBytes())
                == invalidInteractionBytes
        } catch {
            return false
        }
    }())
    check("unverified communication cannot create a proposal", {
        do {
            _ = try invalidInteraction.proposeUnion(familyReceipt(
                invalidInteraction, id: "unverified-union",
                kind: .unionProposal, actor: 0, counterparty: 1,
                communicationVerified: false
            ))
            return false
        } catch AgentSessionError.family(.invalidInteraction) {
            return (try! invalidInteraction.durableStateBytes())
                == invalidInteractionBytes
        } catch {
            return false
        }
    }())
    var incapacitated = familySession(
        "sim-family-incapacitated", firstAgentHealth: 10
    )
    _ = try! incapacitated.advanceTick()
    check("physiologically incapacitated adult is unavailable for union", {
        guard incapacitated.homeostasisProfile(
            for: AgentID(rawValue: "agent_0")!
        )?.vitalStatus == .incapacitated else { return false }
        let bytes = try! incapacitated.durableStateBytes()
        do {
            _ = try incapacitated.proposeUnion(familyReceipt(
                incapacitated, id: "incapacitated-union",
                kind: .unionProposal, actor: 0, counterparty: 1
            ))
            return false
        } catch AgentSessionError.family(.unavailablePerson) {
            return (try! incapacitated.durableStateBytes()) == bytes
        } catch {
            return false
        }
    }())

    var session = familySession("sim-family-v1")
    let familyBefore = try! session.durableStateBytes()
    let householdBefore = session.householdSnapshot()
    let careBefore = session.dependentCareSnapshot()
    let trustBefore = session.socialSnapshot()
    let rightsBefore = session.materialRightsSnapshot()
    let proposal = try! session.proposeUnion(familyReceipt(
        session, id: "union-proposal-0001", kind: .unionProposal,
        actor: 0, counterparty: 1
    ))
    check("union proposal is explicit but not active",
          proposal.proposerID.rawValue == "agent_0"
            && proposal.recipientID.rawValue == "agent_1"
            && proposal.status == .pending
            && (try! session.activeUnion(
                for: AgentID(rawValue: "agent_0")!
            )) == nil)
    check("union proposal records physical boundary then social act",
          session.causalLedgerSnapshot().events.suffix(2).map(\.kind)
            == [.familyInteractionVerified, .unionProposed])

    let beforeWrongAcceptance = try! session.durableStateBytes()
    check("third-party acceptance is atomically refused", {
        do {
            _ = try session.acceptUnion(
                proposalID: proposal.proposalID,
                receipt: familyReceipt(
                    session, id: "union-accept-wrong", kind: .unionAcceptance,
                    actor: 2, counterparty: 0
                )
            )
            return false
        } catch AgentSessionError.family(.wrongProposalRecipient) {
            return (try! session.durableStateBytes()) == beforeWrongAcceptance
        } catch {
            return false
        }
    }())
    let union = try! session.acceptUnion(
        proposalID: proposal.proposalID,
        receipt: familyReceipt(
            session, id: "union-accept-0001", kind: .unionAcceptance,
            actor: 1, counterparty: 0
        )
    )
    check("mutual acceptance activates exactly one canonical union",
          union.partnerIDs.map(\.rawValue) == ["agent_0", "agent_1"]
            && union.status == .active
            && session.familySnapshot().unions.filter {
                $0.status == .active
            }.count == 1)
    check("union causal chain is proposal acceptance activation",
          union.proposalEventID.sequence < union.acceptanceEventID.sequence
            && union.acceptanceEventID.sequence < union.activationEventID.sequence)
    check("union creates no household care trust or material mutation",
          session.householdSnapshot() == householdBefore
            && session.dependentCareSnapshot() == careBefore
            && session.socialSnapshot() == trustBefore
            && session.materialRightsSnapshot() == rightsBefore)
    let beforeDuplicateReceipt = try! session.durableStateBytes()
    check("acceptance receipt cannot be reused", {
        do {
            _ = try session.foundLineage(
                rootPersonID: AgentID(rawValue: "agent_2")!,
                actorID: AgentID(rawValue: "agent_2")!,
                operationID: "union-accept-0001"
            )
            return false
        } catch AgentSessionError.family(.duplicateInteraction) {
            return (try! session.durableStateBytes()) == beforeDuplicateReceipt
        } catch {
            return false
        }
    }())
    check("one-active-union bound is fail-closed", {
        let bytes = try! session.durableStateBytes()
        do {
            _ = try session.proposeUnion(familyReceipt(
                session, id: "union-proposal-overbound", kind: .unionProposal,
                actor: 0, counterparty: 2
            ))
            return false
        } catch AgentSessionError.family(.activeUnionExists) {
            return (try! session.durableStateBytes()) == bytes
        } catch {
            return false
        }
    }())

    let lineage0 = try! session.foundLineage(
        rootPersonID: AgentID(rawValue: "agent_0")!,
        actorID: AgentID(rawValue: "agent_0")!,
        operationID: "lineage-found-0001"
    )
    let lineage1 = try! session.foundLineage(
        rootPersonID: AgentID(rawValue: "agent_1")!,
        actorID: AgentID(rawValue: "agent_1")!,
        operationID: "lineage-found-0002"
    )
    check("lineages persist only explicit real roots",
          session.familySnapshot().lineages.map(\.rootPersonID.rawValue)
            == ["agent_0", "agent_1"]
            && lineage0.status == .historical && lineage1.status == .historical)
    check("one lineage foundation per person is enforced", {
        do {
            _ = try session.foundLineage(
                rootPersonID: AgentID(rawValue: "agent_0")!,
                actorID: AgentID(rawValue: "agent_0")!,
                operationID: "lineage-found-duplicate"
            )
            return false
        } catch AgentSessionError.family(.duplicateLineageRoot) {
            return true
        } catch {
            return false
        }
    }())
    check("no agent can found another person's lineage", {
        do {
            _ = try session.foundLineage(
                rootPersonID: AgentID(rawValue: "agent_2")!,
                actorID: AgentID(rawValue: "agent_1")!,
                operationID: "lineage-found-for-other"
            )
            return false
        } catch AgentSessionError.family(.invalidLineageRoot) {
            return true
        } catch {
            return false
        }
    }())

    let house = try! session.coFoundHouse(
        founderIDs: [
            AgentID(rawValue: "agent_1")!,
            AgentID(rawValue: "agent_0")!,
        ],
        receipts: [
            familyReceipt(
                session, id: "house-cofound-0001-a",
                kind: .houseCoFoundation, actor: 0, counterparty: 1
            ),
            familyReceipt(
                session, id: "house-cofound-0001-b",
                kind: .houseCoFoundation, actor: 1, counterparty: 0
            ),
        ]
    )
    let houseProjection = try! session.houseProjection(house.houseID)
    check("active partners co-found one canonical house by two acts",
          house.founderIDs.map(\.rawValue) == ["agent_0", "agent_1"]
            && houseProjection.activeMemberships.map(\.agentID.rawValue)
                == ["agent_0", "agent_1"])
    check("same house does not merge distinct households",
          houseProjection.householdIDs.count == 2
            && (try! session.currentMembership(
                of: AgentID(rawValue: "agent_0")!
            ))?.householdID != (try! session.currentMembership(
                of: AgentID(rawValue: "agent_1")!
            ))?.householdID)
    check("house carries no ownership or material authority",
          session.materialRightsSnapshot() == rightsBefore)

    try! session.setReproductionEnabled(true)
    let birth = familyBirth(&session)
    let childID = birth.newbornID
    check("normal birth remains independent from union truth",
          birth.progenitorIDs == union.partnerIDs
            && session.kinshipSnapshot().parentageRecords.first {
                $0.childID == childID
            }?.canonicalParentIDs == union.partnerIDs)
    check("child joins house only from two shared canonical progenitors",
          (try! session.currentHouseMemberships(of: childID)).count == 1
            && (try! session.currentHouseMemberships(of: childID))[0].houseID
                == house.houseID
            && (try! session.currentHouseMemberships(of: childID))[0].basis
                == .sharedParentHouseAtBirth)
    let childLineages = try! session.lineages(containing: childID)
    check("lineage membership is derived from canonical parentage",
          Set(childLineages.map(\.lineage.rootPersonID))
            == Set(birth.progenitorIDs)
            && childLineages.allSatisfy {
                $0.memberIDs.contains(childID)
            })
    let parentRelations = try! session.familyRelations(
        of: AgentID(rawValue: "agent_0")!
    )
    check("family projections expose child and co-parent provenance",
          parentRelations.contains {
              $0.kind == .child && $0.relatedPersonID == childID
                  && $0.source == .canonicalParentage
          } && parentRelations.contains {
              $0.kind == .coParent
                  && $0.relatedPersonID.rawValue == "agent_1"
                  && $0.source == .sharedChild
          })
    let childRelations = try! session.familyRelations(of: childID)
    check("child projection exposes exactly two canonical parents",
          childRelations.filter { $0.kind == .parent }
            .map(\.relatedPersonID) == birth.progenitorIDs)
    check("juvenile cannot form a union or explicitly leave a house", {
        let bytes = try! session.durableStateBytes()
        let childOrdinal = Int(childID.rawValue.split(separator: "_").last!)!
        do {
            _ = try session.proposeUnion(familyReceipt(
                session, id: "juvenile-proposal", kind: .unionProposal,
                actor: childOrdinal, counterparty: 2
            ))
            return false
        } catch AgentSessionError.family(.immaturePerson) {
            do {
                try session.leaveHouse(
                    house.houseID, agentID: childID,
                    operationID: "juvenile-house-leave"
                )
                return false
            } catch AgentSessionError.family(.immaturePerson) {
                return (try! session.durableStateBytes()) == bytes
            } catch {
                return false
            }
        } catch {
            return false
        }
    }())

    let houseMembershipBeforeSeparation = try! session.currentHouseMemberships(
        of: AgentID(rawValue: "agent_0")!
    )
    let parentageBeforeSeparation = session.kinshipSnapshot()
    let careBeforeSeparation = session.dependentCareSnapshot()
    try! session.endUnion(
        unionID: union.unionID, reason: .unilateralSeparation,
        receipt: familyReceipt(
            session, id: "union-separate-0001", kind: .unionSeparation,
            actor: 1, counterparty: 0
        )
    )
    check("separation produces former partner history exactly once",
          session.familySnapshot().unions.first?.status == .ended
            && (try! session.familyRelations(
                of: AgentID(rawValue: "agent_0")!
            )).contains {
                $0.kind == .formerUnionPartner
                    && $0.relatedPersonID.rawValue == "agent_1"
            })
    let separationEvent = session.causalLedgerSnapshot().events.last {
        $0.kind == .unionEnded
    }
    check("unilateral separation causality names the actual initiating partner",
          separationEvent?.actorID?.rawValue == "agent_1"
            && separationEvent?.subjectID?.rawValue == "agent_0"
            && separationEvent?.operationID?.rawValue == "union-separate-0001")
    check("separation preserves parentage care lineage and house membership",
          session.kinshipSnapshot() == parentageBeforeSeparation
            && session.dependentCareSnapshot() == careBeforeSeparation
            && (try! session.currentHouseMemberships(
                of: AgentID(rawValue: "agent_0")!
            )) == houseMembershipBeforeSeparation
            && (try! session.lineages(containing: childID)).count == 2)
    check("ending an already ended union is atomically refused", {
        let bytes = try! session.durableStateBytes()
        do {
            try session.endUnion(
                unionID: union.unionID, reason: .unilateralSeparation,
                receipt: familyReceipt(
                    session, id: "union-separate-duplicate",
                    kind: .unionSeparation, actor: 1, counterparty: 0
                )
            )
            return false
        } catch AgentSessionError.family(.invalidUnion) {
            return (try! session.durableStateBytes()) == bytes
        } catch {
            return false
        }
    }())
    while session.lifecycleSnapshot().members.first(where: {
        $0.agentID == childID
    })?.currentStage != .mature {
        _ = try! session.advanceTick()
    }
    check("canonical parent-child union is prohibited after maturity", {
        let bytes = try! session.durableStateBytes()
        let childOrdinal = Int(childID.rawValue.split(separator: "_").last!)!
        do {
            _ = try session.proposeUnion(familyReceipt(
                session, id: "parent-child-proposal",
                kind: .unionProposal, actor: 0,
                counterparty: childOrdinal
            ))
            return false
        } catch AgentSessionError.family(.prohibitedUnion) {
            return (try! session.durableStateBytes()) == bytes
        } catch {
            return false
        }
    }())

    let observerBefore = try! session.durableStateBytes()
    let observer = session.observerSnapshot(
        worldBinding: try! AgentObserverWorldBinding(
            worldID: "world-family", storageIdentity: "family-store",
            seed: 32, dimension: 0, observedWorldTick: session.tick
        )
    )
    check("Observer schema 5 exposes read-only family authority",
          observer.header.schemaVersion == 5
            && observer.familyAuthority?.unions.count == 1
            && observer.familyAuthority?.lineages.count == 2
            && observer.familyAuthority?.houses.count == 1
            && observer.individual(
                AgentID(rawValue: "agent_0")!
            )?.family?.formerUnionPartnerIDs
                == [AgentID(rawValue: "agent_1")!]
            && (try! session.durableStateBytes()) == observerBefore)

    let checkpoint = try! session.makeCheckpoint()
    let durableBytes = try! session.durableStateBytes()
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    check("checkpoint schema 25 restores family state byte-exact",
          checkpoint.schemaVersion == AgentCheckpointSchema.familyVersion
            && (try! restored.durableStateBytes()) == durableBytes
            && restored.familySnapshot() == session.familySnapshot())
    check("restart re-derives the same lineages houses and family relations",
          (try! restored.lineages(containing: childID))
            == (try! session.lineages(containing: childID))
            && (try! restored.houseProjection(house.houseID))
                == (try! session.houseProjection(house.houseID))
            && (try! restored.familyRelations(of: childID))
                == (try! session.familyRelations(of: childID)))

    check("duplicate union corruption is refused", familyRestoreRefused(
        checkpoint
    ) { durable in
        var family = durable["familyState"] as! [String: Any]
        var unions = family["unions"] as! [[String: Any]]
        unions.append(unions[0])
        family["unions"] = unions
        durable["familyState"] = family
    })
    check("union partner/proposal mismatch corruption is refused",
          familyRestoreRefused(checkpoint) { durable in
              var family = durable["familyState"] as! [String: Any]
              var unions = family["unions"] as! [[String: Any]]
              unions[0]["partnerIDs"] = ["agent_0", "agent_2"]
              family["unions"] = unions
              durable["familyState"] = family
          })
    check("union causal event corruption is refused",
          familyRestoreRefused(checkpoint) { durable in
              var family = durable["familyState"] as! [String: Any]
              var unions = family["unions"] as! [[String: Any]]
              unions[0]["activationEventID"] = unions[0]["proposalEventID"]
              family["unions"] = unions
              durable["familyState"] = family
          })
    check("family identity counter corruption is refused",
          familyRestoreRefused(checkpoint) { durable in
              var family = durable["familyState"] as! [String: Any]
              family["nextUnionOrdinal"] = 99
              durable["familyState"] = family
          })
    check("separation cannot be relabeled as partner death",
          familyRestoreRefused(checkpoint) { durable in
              var family = durable["familyState"] as! [String: Any]
              var unions = family["unions"] as! [[String: Any]]
              unions[0]["terminationReason"] = "partnerDeath"
              family["unions"] = unions
              durable["familyState"] = family
          })
    check("duplicate house identity corruption is refused",
          familyRestoreRefused(checkpoint) { durable in
              var family = durable["familyState"] as! [String: Any]
              var houses = family["houses"] as! [[String: Any]]
              houses.append(houses[0])
              family["houses"] = houses
              durable["familyState"] = family
          })
    check("unknown lineage root corruption is refused",
          familyRestoreRefused(checkpoint) { durable in
              var family = durable["familyState"] as! [String: Any]
              var lineages = family["lineages"] as! [[String: Any]]
              lineages[0]["rootPersonID"] = "agent_unknown"
              family["lineages"] = lineages
              durable["familyState"] = family
          })
    check("child house membership with a nonmember parent is refused",
          familyRestoreRefused(checkpoint) { durable in
              var family = durable["familyState"] as! [String: Any]
              var periods = family["houseMembershipPeriods"] as! [[String: Any]]
              let childIndex = periods.firstIndex {
                  ($0["agentID"] as? String) == childID.rawValue
              }!
              periods[childIndex]["houseID"] = "house-99999999"
              family["houseMembershipPeriods"] = periods
              durable["familyState"] = family
          })

    var pending = familySession("sim-family-pending")
    let pendingProposal = try! pending.proposeUnion(familyReceipt(
        pending, id: "pending-proposal", kind: .unionProposal,
        actor: 0, counterparty: 1
    ))
    let pendingCheckpoint = try! pending.makeCheckpoint()
    var pendingRestored = try! AgentSimulationSession.restoring(pendingCheckpoint)
    let pendingUnion = try! pendingRestored.acceptUnion(
        proposalID: pendingProposal.proposalID,
        receipt: familyReceipt(
            pendingRestored, id: "pending-accept", kind: .unionAcceptance,
            actor: 1, counterparty: 0
        )
    )
    check("pending proposal survives restart and activates only once",
          pendingUnion.status == .active
            && pendingRestored.familySnapshot().unions.count == 1
            && pendingRestored.familySnapshot().proposals.first?.status == .accepted)

    var replaySession = familySession(
        "sim-family-replay", enableFamily: false
    )
    let replayBase = try! replaySession.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(
        checkpoint: replayBase, session: replaySession
    )
    _ = try! recorder.apply(
        .setFamilyV1Enabled(true, configuration: .live),
        to: &replaySession
    )
    let replayProposalReceipt = familyReceipt(
        replaySession, id: "replay-proposal", kind: .unionProposal,
        actor: 0, counterparty: 1
    )
    _ = try! recorder.apply(
        .proposeUnion(replayProposalReceipt), to: &replaySession
    )
    let replayProposalID = AgentUnionProposalID(
        rawValue: replayProposalReceipt.receiptID
    )!
    _ = try! recorder.apply(
        .acceptUnion(
            proposalID: replayProposalID,
            receipt: familyReceipt(
                replaySession, id: "replay-accept", kind: .unionAcceptance,
                actor: 1, counterparty: 0
            )
        ),
        to: &replaySession
    )
    _ = try! recorder.apply(
        .foundLineage(
            rootPersonID: AgentID(rawValue: "agent_0")!,
            actorID: AgentID(rawValue: "agent_0")!,
            operationID: "replay-lineage"
        ),
        to: &replaySession
    )
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "family-replay")!
    )
    let replayed = try! AgentSessionReplayer.replay(
        checkpoint: replayBase, journal: journal
    )
    check("schema 25 replay is byte-exact and non-duplicating",
          recorder.schemaVersion == AgentReplaySchema.familyVersion
            && replayed.session.familySnapshot().unions.count == 1
            && replayed.session.familySnapshot().lineages.count == 1
            && (try! replayed.session.durableStateBytes())
                == (try! replaySession.durableStateBytes()))

    var joinedHouse = familySession("sim-family-explicit-house-join")
    let joinProposal = try! joinedHouse.proposeUnion(familyReceipt(
        joinedHouse, id: "join-grounding-proposal", kind: .unionProposal,
        actor: 0, counterparty: 1
    ))
    _ = try! joinedHouse.acceptUnion(
        proposalID: joinProposal.proposalID,
        receipt: familyReceipt(
            joinedHouse, id: "join-grounding-accept",
            kind: .unionAcceptance, actor: 1, counterparty: 0
        )
    )
    let singleHouse = try! joinedHouse.foundHouse(
        founderID: AgentID(rawValue: "agent_0")!,
        operationID: "single-house-foundation"
    )
    try! joinedHouse.joinHouse(
        singleHouse.houseID,
        request: familyReceipt(
            joinedHouse, id: "house-join-request",
            kind: .houseJoinRequest, actor: 1, counterparty: 0
        ),
        acceptance: familyReceipt(
            joinedHouse, id: "house-join-acceptance",
            kind: .houseJoinAcceptance, actor: 0, counterparty: 1
        )
    )
    check("adult house join requires grounded request and acceptance",
          (try! joinedHouse.currentHouseMemberships(
              of: AgentID(rawValue: "agent_1")!
          )).contains {
              $0.houseID == singleHouse.houseID
                  && $0.basis == .explicitAdultJoin
          })
    try! joinedHouse.leaveHouse(
        singleHouse.houseID, agentID: AgentID(rawValue: "agent_1")!,
        operationID: "house-explicit-leave"
    )
    check("explicit house leave preserves union and historical period",
          (try! joinedHouse.currentHouseMemberships(
              of: AgentID(rawValue: "agent_1")!
          )).isEmpty
            && joinedHouse.familySnapshot().houseMembershipPeriods.contains {
                $0.agentID.rawValue == "agent_1"
                    && $0.endReason == .explicitAdultLeave
            }
            && (try! joinedHouse.activeUnion(
                for: AgentID(rawValue: "agent_1")!
            )) != nil)
    let leftHouseCheckpoint = try! joinedHouse.makeCheckpoint()
    check("explicit house leave cannot be relabeled as member death",
          familyRestoreRefused(leftHouseCheckpoint) { durable in
              var family = durable["familyState"] as! [String: Any]
              var periods = family["houseMembershipPeriods"] as! [[String: Any]]
              let index = periods.firstIndex {
                  ($0["agentID"] as? String) == "agent_1"
                      && $0["leftTick"] != nil
              }!
              periods[index]["endReason"] = "memberDeath"
              family["houseMembershipPeriods"] = periods
              durable["familyState"] = family
          })

    var independentAuthorities = familySession(
        "sim-family-house-household-independence",
        enableReproduction: true
    )
    let household0 = try! independentAuthorities.currentMembership(
        of: AgentID(rawValue: "agent_0")!
    )!.householdID
    try! independentAuthorities.moveMembers(
        memberIDs: [AgentID(rawValue: "agent_1")!], to: household0
    )
    let parent0House = try! independentAuthorities.foundHouse(
        founderID: AgentID(rawValue: "agent_0")!,
        operationID: "different-house-0"
    )
    let parent1House = try! independentAuthorities.foundHouse(
        founderID: AgentID(rawValue: "agent_1")!,
        operationID: "different-house-1"
    )
    check("same household with different houses is valid",
          (try! independentAuthorities.currentMembership(
              of: AgentID(rawValue: "agent_0")!
          ))?.householdID == (try! independentAuthorities.currentMembership(
              of: AgentID(rawValue: "agent_1")!
          ))?.householdID
            && parent0House.houseID != parent1House.houseID)
    let differentHouseBirth = familyBirth(&independentAuthorities)
    check("different parental houses yield no automatic child house",
          (try! independentAuthorities.currentHouseMemberships(
              of: differentHouseBirth.newbornID
          )).isEmpty)

    var death = familySession(
        "sim-family-partner-death", lethalFirstAgent: true
    )
    let deathProposal = try! death.proposeUnion(familyReceipt(
        death, id: "death-union-proposal", kind: .unionProposal,
        actor: 0, counterparty: 1
    ))
    let deathUnion = try! death.acceptUnion(
        proposalID: deathProposal.proposalID,
        receipt: familyReceipt(
            death, id: "death-union-accept", kind: .unionAcceptance,
            actor: 1, counterparty: 0
        )
    )
    _ = try! death.foundLineage(
        rootPersonID: AgentID(rawValue: "agent_0")!,
        actorID: AgentID(rawValue: "agent_0")!,
        operationID: "death-lineage"
    )
    let deathHouse = try! death.coFoundHouse(
        founderIDs: deathUnion.partnerIDs,
        receipts: [
            familyReceipt(
                death, id: "death-house-a", kind: .houseCoFoundation,
                actor: 0, counterparty: 1
            ),
            familyReceipt(
                death, id: "death-house-b", kind: .houseCoFoundation,
                actor: 1, counterparty: 0
            ),
        ]
    )
    _ = try! death.advanceTick()
    let afterDeathUnion = death.familySnapshot().unions.first {
        $0.unionID == deathUnion.unionID
    }
    check("partner death ends active union with explicit bounded reason",
          death.snapshot().agents.map(\.id) == ["agent_1", "agent_2"]
            && afterDeathUnion?.status == .ended
            && afterDeathUnion?.terminationReason == .partnerDeath)
    let deathUnionEvent = death.causalLedgerSnapshot().events.last {
        $0.kind == .unionEnded
    }
    let lethalEventID = death.mortalitySnapshot().records.first {
        $0.agentID.rawValue == "agent_0"
    }?.lethalDamageEventID
    check("partner death causality names the deceased and its lethal cause",
          deathUnionEvent?.actorID?.rawValue == "agent_0"
            && deathUnionEvent?.subjectID?.rawValue == "agent_1"
            && lethalEventID.map {
                deathUnionEvent?.causes.contains($0) == true
            } == true)
    check("root death preserves lineage and house without succession or assets",
          death.familySnapshot().lineages.first?.rootPersonID.rawValue == "agent_0"
            && (try! death.houseProjection(deathHouse.houseID)).house.status == .active
            && (try! death.houseProjection(deathHouse.houseID)).activeMemberships
                .map(\.agentID.rawValue) == ["agent_1"]
            && death.materialRightsSnapshot().records.isEmpty)
    let postDeathCheckpoint = try! death.makeCheckpoint()
    check("death-driven family closure restores byte-exact",
          (try! AgentSimulationSession.restoring(
              postDeathCheckpoint
          ).durableStateBytes()) == (try! death.durableStateBytes()))
    check("dead partner cannot be restored in an active union",
          familyRestoreRefused(postDeathCheckpoint) { durable in
              var family = durable["familyState"] as! [String: Any]
              var unions = family["unions"] as! [[String: Any]]
              unions[0]["status"] = "active"
              unions[0].removeValue(forKey: "terminationTick")
              unions[0].removeValue(forKey: "terminationEventID")
              unions[0].removeValue(forKey: "terminationReason")
              family["unions"] = unions
              durable["familyState"] = family
          })

    var noUnionBirth = familySession(
        "sim-family-birth-without-union", enableReproduction: true
    )
    let noUnionRecord = familyBirth(&noUnionBirth)
    check("historical birth without union remains valid",
          noUnionBirth.familySnapshot().unions.isEmpty
            && noUnionBirth.kinshipSnapshot().parentageRecords.contains {
                $0.childID == noUnionRecord.newbornID
            })

    var siblings = familySession(
        "sim-family-sibling-prohibition",
        enableReproduction: true, maturityAgeTicks: 64
    )
    var siblingBirths: [AgentBirthRecord] = []
    for index in 0..<4 {
        siblingBirths.append(familyBirth(
            &siblings,
            position: AgentPosition(x: 0, y: 64, z: 4 + index)
        ))
    }
    try! siblings.setReproductionEnabled(false)
    while siblings.tick < 80 {
        _ = try! siblings.advanceTick()
    }
    let firstChild = siblingBirths[0].newbornID
    let halfSibling = siblingBirths[1].newbornID
    let fullSibling = siblingBirths[3].newbornID
    check("fixture derives half and full siblings canonically",
          siblings.siblingRelation(
              between: firstChild, and: halfSibling
          ) == .halfSibling
            && siblings.siblingRelation(
                between: firstChild, and: fullSibling
            ) == .fullSibling)
    check("half-sibling union is prohibited after both mature", {
        let bytes = try! siblings.durableStateBytes()
        do {
            _ = try siblings.proposeUnion(familyReceipt(
                siblings, id: "half-sibling-proposal", kind: .unionProposal,
                actor: Int(firstChild.rawValue.split(separator: "_").last!)!,
                counterparty: Int(
                    halfSibling.rawValue.split(separator: "_").last!
                )!
            ))
            return false
        } catch AgentSessionError.family(.prohibitedUnion) {
            return (try! siblings.durableStateBytes()) == bytes
        } catch {
            return false
        }
    }())
    check("full-sibling union is prohibited after both mature", {
        let bytes = try! siblings.durableStateBytes()
        do {
            _ = try siblings.proposeUnion(familyReceipt(
                siblings, id: "full-sibling-proposal", kind: .unionProposal,
                actor: Int(firstChild.rawValue.split(separator: "_").last!)!,
                counterparty: Int(
                    fullSibling.rawValue.split(separator: "_").last!
                )!
            ))
            return false
        } catch AgentSessionError.family(.prohibitedUnion) {
            return (try! siblings.durableStateBytes()) == bytes
        } catch {
            return false
        }
    }())
    var canonicalOrder = familySession("sim-family-order-neutral")
    var permutedOrder = familySession(
        "sim-family-order-neutral", order: [2, 0, 1]
    )
    for index in 0..<2 {
        let proposalID = "order-proposal-\(index)"
        let acceptanceID = "order-accept-\(index)"
        if index == 0 {
            let proposal = try! canonicalOrder.proposeUnion(familyReceipt(
                canonicalOrder, id: proposalID, kind: .unionProposal,
                actor: 0, counterparty: 1
            ))
            _ = try! canonicalOrder.acceptUnion(
                proposalID: proposal.proposalID,
                receipt: familyReceipt(
                    canonicalOrder, id: acceptanceID,
                    kind: .unionAcceptance, actor: 1, counterparty: 0
                )
            )
        } else {
            let proposal = try! permutedOrder.proposeUnion(familyReceipt(
                permutedOrder, id: "order-proposal-0", kind: .unionProposal,
                actor: 0, counterparty: 1
            ))
            _ = try! permutedOrder.acceptUnion(
                proposalID: proposal.proposalID,
                receipt: familyReceipt(
                    permutedOrder, id: "order-accept-0",
                    kind: .unionAcceptance, actor: 1, counterparty: 0
                )
            )
        }
    }
    check("family durable state is neutral to founder input order",
          (try! canonicalOrder.durableStateBytes())
            == (try! permutedOrder.durableStateBytes()))
    _ = familyBefore
}
