import Foundation
import PebbleAgents

private func childhoodMutatedCheckpoint(
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

private func childhoodRestoreRefused(
    _ checkpoint: AgentSessionCheckpoint,
    mutate: (inout [String: Any]) -> Void
) -> Bool {
    do {
        _ = try AgentSimulationSession.restoring(
            childhoodMutatedCheckpoint(checkpoint, mutate: mutate)
        )
        return false
    } catch {
        return true
    }
}

private func mutateChildhood(
    _ durable: inout [String: Any],
    _ mutation: (inout [String: Any]) -> Void
) {
    var care = durable["dependentCareState"] as! [String: Any]
    var childhood = care["childhoodV2"] as! [String: Any]
    mutation(&childhood)
    care["childhoodV2"] = childhood
    durable["dependentCareState"] = care
}

private func childhoodAdvance(
    _ recorder: inout AgentReplayRecorder,
    _ session: inout AgentSimulationSession
) -> AgentSessionTickResult {
    try! recorder.apply(
        .advanceTick(perceptions: [], physicalObservations: []),
        to: &session
    ).tickResult!
}

private func childhoodMortalityAgent(
    _ ordinal: Int,
    home: AgentPosition
) -> AgentSessionAgentState {
    AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: home,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0.1, safety: 1),
        health: 100, fear: 0, homePosition: home, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "childhood mortality fixture",
            startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [],
        tickCreated: 0, ticksAlive: 0, observationCount: 0,
        nearbyObservationCount: 0, goalSelectionCount: 0,
        goalChangeCount: 0, actionCount: 0, actionEffectCount: 0,
        movementCount: 0, totalManhattanDistanceMoved: 0,
        returnHomeMoveCount: 0, totalDistanceReducedTowardHome: 0
    )
}

private func childhoodMortalityBase() -> AgentSimulationSession {
    let home = AgentPosition(x: 0, y: 64, z: 0)
    let habitat = AgentEcologyHabitatObservation(
        worldTick: 0, candidateIndex: 0,
        habitatPosition: AgentPosition(x: 1, y: 63, z: 0),
        foragePosition: AgentPosition(x: 1, y: 64, z: 0),
        habitatFingerprint: 31_031, distanceFromSettlement: 1,
        directionIndex: 0, worldReadCount: 4
    )
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 31, nearbyRadius: 8, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 64),
            survivalConfiguration: try! AgentSurvivalConfiguration(
                hungerPerTick: 0.30, fatiguePerTick: 0.005,
                hungryThreshold: 0.4, criticalHungerThreshold: 0.95,
                hungerRecoveryThreshold: 0.15, fatigueThreshold: 0.65,
                fatigueRecoveryThreshold: 0.2, foodNutrition: 0.6,
                restRecoveryPerTick: 1, starvationGraceTicks: 3,
                starvationDamagePerTick: 100
            )
        ),
        agents: [
            childhoodMortalityAgent(0, home: home),
            childhoodMortalityAgent(1, home: home),
            childhoodMortalityAgent(2, home: home),
        ],
        simulationID: try! AgentSimulationID(
            validating: "sim-childhood-guardian-death"
        ),
        causalLedgerPolicy: .bounded(maxEvents: 16_384)
    )
    session.setSurvivalEnabled(true)
    try! session.initializePopulationRegistry(
        settlementAnchor: home,
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3),
        configuration: .live
    )
    try! session.initializeLocalEcology(observations: [habitat])
    _ = try! session.applyLocalEcologyEndOfTick(
        habitatValidations: [habitat]
    )
    try! session.setLifecycleEnabled(
        true,
        configuration: try! AgentLifecycleConfiguration(
            newbornDurationTicks: 8, maturityAgeTicks: 64,
            reproductionEvaluationIntervalTicks: 1,
            reproductionPlanDelayTicks: 1,
            reproductionCooldownTicks: 1,
            maximumRetainedBirthRecords: 32,
            maximumRetainedPlanRecords: 32,
            maximumParentBirthCount: 16
        )
    )
    try! session.setKinshipEnabled(true)
    try! session.setHouseholdsEnabled(true)
    try! session.setDependentCareEnabled(true)
    try! session.setChildhoodV2Enabled(true)
    try! session.setReproductionEnabled(true)
    return session
}

func runPebbleAgentsChildhoodGuardianshipSmoke() {
    section("pebble agents childhood guardianship social development V2")

    let live = AgentChildhoodConfiguration.live
    check("childhood configuration is bounded",
          live.maximumRetainedGuardianships == 256
            && live.maximumDependentsPerGuardian == 4
            && live.maximumSocialProfiles == 64
            && live.maximumRetainedExposures == 512
            && live.maximumExposuresPerChild == 64
            && live.maximumTransitionsPerTick == 64
            && live.minimumSupervisionTicks == 2
            && live.maximumDimensionBasisPoints == 10_000)
    check("childhood configuration Codable", (try? AgentCheckpointCodec.decode(
        AgentChildhoodConfiguration.self,
        from: AgentCheckpointCodec.encode(live)
    )) == live)

    var missingCare = careBase("sim-childhood-missing-care")
    let missingCareBytes = try! missingCare.durableStateBytes()
    check("childhood activation without care is atomic and refused", {
        do {
            try missingCare.setChildhoodV2Enabled(true)
            return false
        } catch AgentSessionError.childhood(.dependentCareRequired) {
            return (try! missingCare.durableStateBytes()) == missingCareBytes
        } catch {
            return false
        }
    }())

    var session = careBase("sim-childhood-v2")
    try! session.setDependentCareEnabled(true)
    try! session.setReproductionEnabled(true)
    let v9Checkpoint = try! session.makeCheckpoint()
    let socialBefore = session.socialSnapshot()
    let skillsBefore = session.skillSnapshot()
    var recorder = try! AgentReplayRecorder(
        checkpoint: v9Checkpoint, session: session
    )
    _ = try! recorder.apply(
        .setChildhoodV2Enabled(true, configuration: live), to: &session
    )
    check("childhood activation promotes checkpoint schema 23",
          session.childhoodV2Enabled
            && (try! session.makeCheckpoint()).schemaVersion
                == AgentCheckpointSchema.childhoodVersion
            && recorder.schemaVersion == AgentReplaySchema.childhoodVersion)
    check("childhood activation does not invent trust or skill",
          session.socialSnapshot() == socialBefore
            && session.skillSnapshot() == skillsBefore)
    check("mature founders have no invented guardianship",
          session.childhoodSnapshot().guardianships.isEmpty
            && session.childhoodSnapshot().socialProfiles.isEmpty)

    let birth = careBirth(
        &recorder, &session,
        position: AgentPosition(x: 0, y: 64, z: 0),
        candidateIndex: 0
    )
    let childID = birth.newbornID
    let guardian = try! session.currentGuardian(for: childID)
    let careAssignment = try! session.currentCareAssignment(for: childID)
    check("normal birth publishes one deterministic canonical-parent guardian",
          guardian?.guardianID == AgentID(rawValue: "agent_0")!
            && guardian?.basis == .canonicalParent
            && session.childhoodSnapshot().guardianships.filter {
                $0.dependentID == childID && $0.status == .active
            }.count == 1)
    check("guardian and care executor begin aligned but remain distinct records",
          careAssignment?.caregiverID == guardian?.guardianID
            && careAssignment?.startedEventID != guardian?.startedEventID)
    check("guardianship retains canonical parentage and household",
          session.kinshipSnapshot().parentageRecords.first {
              $0.childID == childID
          }?.canonicalParentIDs == birth.progenitorIDs
            && (try! session.currentMembership(of: childID))?.householdID
                == guardian?.householdID)
    check("birth creates causal guardian continuity only",
          session.socialDevelopmentProfile(for: childID)?.values.first {
              $0.dimension == .guardianContinuity
          }?.basisPoints == 100
            && session.childhoodSnapshot().totalExposureCount == 1)
    let newbornCapabilities = try! session.childhoodCapabilities(for: childID)
    check("newborn adult capabilities are structurally denied",
          newbornCapabilities.allowed == [.perceive]
            && [.harvest, .deliver, .build, .cooperateAsWorker,
                .reproduce, .voluntaryMigration].allSatisfy {
                    newbornCapabilities.refused.contains($0)
                })

    let parentageBeforeDelegation = session.kinshipSnapshot()
    let householdBeforeDelegation = session.householdSnapshot()
    _ = try! recorder.apply(
        .delegateDependentCare(
            dependentID: childID,
            caregiverID: AgentID(rawValue: "agent_1")!
        ),
        to: &session
    )
    check("temporary care delegation does not rewrite guardian",
          (try! session.currentGuardian(for: childID))?.guardianID
            == AgentID(rawValue: "agent_0")!
            && (try! session.currentCareAssignment(for: childID))?.caregiverID
                == AgentID(rawValue: "agent_1")!)
    check("temporary care delegation does not rewrite parentage or household",
          session.kinshipSnapshot() == parentageBeforeDelegation
            && session.householdSnapshot() == householdBeforeDelegation)

    _ = try! recorder.apply(
        .reassignGuardian(
            dependentID: childID,
            guardianID: AgentID(rawValue: "agent_1")!
        ),
        to: &session
    )
    let reassigned = try! session.currentGuardian(for: childID)
    check("explicit same-household guardian reassignment is durable",
          reassigned?.guardianID == AgentID(rawValue: "agent_1")!
            && reassigned?.basis == .explicitReassignment
            && session.childhoodSnapshot().guardianships.filter {
                $0.dependentID == childID && $0.status == .ended
            }.count == 1)
    check("guardian reassignment does not rewrite canonical parents",
          session.kinshipSnapshot().parentageRecords.first {
              $0.childID == childID
          }?.canonicalParentIDs == birth.progenitorIDs)
    let bytesBeforeCrossHousehold = try! session.durableStateBytes()
    check("cross-household guardian assignment fails atomically", {
        do {
            try session.reassignGuardian(
                dependentID: childID,
                to: AgentID(rawValue: "agent_2")!
            )
            return false
        } catch AgentSessionError.childhood(.ineligibleGuardian) {
            return (try! session.durableStateBytes()) == bytesBeforeCrossHousehold
        } catch {
            return false
        }
    }())
    let otherHouseholdID = (try! session.currentMembership(
        of: AgentID(rawValue: "agent_2")!
    ))!.householdID
    let childHouseholdID = (try! session.currentMembership(of: childID))!
        .householdID
    let childPositionBeforeFallback = try! session.state(for: childID).position
    _ = try! recorder.apply(
        .moveHouseholdMembers(
            memberIDs: [AgentID(rawValue: "agent_2")!],
            householdID: childHouseholdID
        ),
        to: &session
    )
    _ = try! recorder.apply(
        .reassignGuardian(
            dependentID: childID,
            guardianID: AgentID(rawValue: "agent_2")!
        ),
        to: &session
    )
    check("eligible non-parent household adult can become guardian",
          try! session.currentGuardian(for: childID)?.guardianID
            == AgentID(rawValue: "agent_2")!
            && session.kinshipSnapshot().parentageRecords.first {
                $0.childID == childID
            }?.canonicalParentIDs == birth.progenitorIDs)
    check("guardian reassignment never teleports the child",
          try! session.state(for: childID).position
            == childPositionBeforeFallback)

    _ = childhoodAdvance(&recorder, &session)
    let engagement = session.dependentCareSnapshot().activeEngagements.first {
        $0.dependentID == childID && $0.kind == .supervise
    }
    let exposureBeforeEarlyCompletion = session.childhoodSnapshot()
        .totalExposureCount
    check("supervision starts a timed real engagement", engagement != nil
        && engagement!.startedTick <= session.tick)
    let early = try! session.completeDependentCareInteraction(
        caregiverID: AgentID(rawValue: "agent_1")!,
        dependentID: childID
    )
    check("instantaneous supervision is refused without social growth",
          !early
            && session.childhoodSnapshot().totalExposureCount
                == exposureBeforeEarlyCompletion)
    _ = childhoodAdvance(&recorder, &session)
    _ = childhoodAdvance(&recorder, &session)
    _ = try! recorder.apply(
        .completeDependentCareInteraction(
            caregiverID: AgentID(rawValue: "agent_1")!,
            dependentID: childID
        ),
        to: &session
    )
    check("elapsed supervision produces bounded causal social exposure",
          session.socialDevelopmentProfile(for: childID)?.values.first {
              $0.dimension == .supervisedInteraction
          }?.basisPoints == 140
            && session.childhoodSnapshot().exposures.last?
                .dimension == .supervisedInteraction
            && session.childhoodSnapshot().exposures.last?
                .participantID == AgentID(rawValue: "agent_1")!)
    check("social development did not mutate trust",
          session.socialSnapshot().trustRelations
            == socialBefore.trustRelations)
    _ = try! recorder.apply(
        .setPhysicalFoodSurvivalEnabled(true), to: &session
    )
    let physicalCaregiverID = AgentID(rawValue: "agent_1")!
    for _ in 0..<16 where session.careEngagement(
        for: physicalCaregiverID
    )?.kind != .provideFood {
        _ = childhoodAdvance(&recorder, &session)
    }
    let foodEngagement = session.careEngagement(for: physicalCaregiverID)
    let stableCareBefore = session.socialDevelopmentProfile(
        for: childID
    )?.values.first {
        $0.dimension == .stableCareExposure
    }?.basisPoints ?? 0
    let physicalIntent = try! session.nextPhysicalDependentFoodIntent(
        caregiverID: physicalCaregiverID, dependentID: childID
    )
    let hungerBefore = try! session.state(for: childID).needs.hunger
    let physicalOutcome = AgentValidatedPhysicalDependentFoodOutcome(
        intent: physicalIntent, canonicalMaterialName: "sweet_berries",
        quantityConsumed: 1, coreHungerPoints: 2,
        coreSaturation: 0.4, sourceSlot: 0,
        physicalReceiptID: physicalIntent.provisionID,
        hungerBefore: hungerBefore,
        hungerAfter: max(0, hungerBefore - 0.1)
    )
    _ = try! recorder.apply(
        .validatedPhysicalDependentFood(physicalOutcome), to: &session
    )
    check("verified physical nourishment produces one stable-care exposure",
          foodEngagement?.kind == .provideFood
            && session.socialDevelopmentProfile(for: childID)?.values.first {
                $0.dimension == .stableCareExposure
            }?.basisPoints == stableCareBefore + 160
            && session.dependentCareSnapshot().terminalOutcomes.filter {
                $0.dependentID == childID
                    && $0.kind == .nourishment
                    && $0.status == .resolved
            }.count == 1)
    let afterPhysicalCareBytes = try! session.durableStateBytes()
    check("physical care receipt cannot resolve or expose twice", {
        do {
            try session.applyValidatedPhysicalDependentFood(physicalOutcome)
            return false
        } catch {
            return (try! session.durableStateBytes())
                == afterPhysicalCareBytes
        }
    }())
    while session.tick < birth.birthTick + 8 {
        _ = childhoodAdvance(&recorder, &session)
    }
    let juvenileCapabilities = try! session.childhoodCapabilities(for: childID)
    check("juvenile has partial autonomy without adult gateways",
          juvenileCapabilities.allowed.contains(.autonomousMovement)
            && juvenileCapabilities.allowed.contains(.returnHome)
            && juvenileCapabilities.allowed.contains(.selfConsumeCarriedFood)
            && juvenileCapabilities.refused.contains(.harvest)
            && juvenileCapabilities.refused.contains(.build)
            && juvenileCapabilities.refused.contains(.reproduce))
    _ = try! recorder.apply(
        .setAutonomousActivityEnabled(true, configuration: .live),
        to: &session
    )
    let adultActivityCandidate = AgentAutonomousActivityCandidate(
        candidateID: "juvenile-construction-refused",
        actorID: childID, domain: .construction,
        actionKey: "build", stableReference: "fixture",
        source: .opportunity, priorityBand: 50, urgency: 50,
        distance: 0, observedAtTick: session.tick
    )
    let beforeAdultActivityAttempt = try! session.durableStateBytes()
    check("juvenile adult autonomous activity is refused before mutation", {
        do {
            _ = try session.selectAutonomousActivities([
                adultActivityCandidate
            ])
            return false
        } catch AgentSessionError.dependentCare(
            .capabilityDenied(_, .build)
        ) {
            return (try! session.durableStateBytes())
                == beforeAdultActivityAttempt
        } catch {
            return false
        }
    }())

    let observerBytesBefore = try! session.durableStateBytes()
    let observer = session.observerSnapshot(
        worldBinding: try! AgentObserverWorldBinding(
            worldID: "childhood-world",
            storageIdentity: "childhood-store",
            seed: 67, dimension: 0, observedWorldTick: session.tick
        )
    )
    let observedChild = observer.individual(childID)?.childhood
    check("Observer schema 4 exposes read-only childhood authority",
          observer.header.schemaVersion == 4
            && observedChild?.guardianID == AgentID(rawValue: "agent_2")!
            && observedChild?.currentCaregiverID
                == AgentID(rawValue: "agent_1")!
            && observedChild?.atRisk == false
            && observedChild?.socialDevelopment.count
                == AgentSocialDevelopmentDimension.allCases.count)
    check("Observer childhood projection mutates nothing",
          (try! session.durableStateBytes()) == observerBytesBefore)

    let secondBirth = careBirth(
        &recorder, &session,
        position: AgentPosition(x: 1, y: 64, z: 0),
        candidateIndex: 1
    )
    let secondChildID = secondBirth.newbornID
    check("a second local child remains newborn and dependent",
          secondChildID != childID
            && session.lifecycleSnapshot().members.first {
                $0.agentID == secondChildID
            }?.currentStage == .newborn
            && (try! session.currentGuardian(for: secondChildID)) != nil)

    let checkpoint = try! session.makeCheckpoint()
    let checkpointBytes = try! session.durableStateBytes()
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    check("schema 23 checkpoint restores guardianship and social state exactly",
          checkpoint.schemaVersion == AgentCheckpointSchema.childhoodVersion
            && (try! restored.durableStateBytes()) == checkpointBytes
            && restored.childhoodSnapshot() == session.childhoodSnapshot())
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "civ31-childhood")!
    )
    let replayed = try! AgentSessionReplayer.replay(
        checkpoint: v9Checkpoint, journal: journal
    )
    check("schema 23 replay is byte exact",
          journal.manifest.schemaVersion == AgentReplaySchema.childhoodVersion
            && replayed.report.verified
            && (try! replayed.session.durableStateBytes())
                == (try! session.durableStateBytes()))

    check("duplicate active guardian corruption is refused",
          childhoodRestoreRefused(checkpoint) { durable in
              mutateChildhood(&durable) { childhood in
                  var guardians = childhood["guardianships"] as! [[String: Any]]
                  guardians.append(guardians.last!)
                  childhood["guardianships"] = guardians
                  childhood["totalGuardianshipCount"] =
                      (childhood["totalGuardianshipCount"] as! Int) + 1
              }
          })
    check("guardian and dependent identity corruption is refused",
          childhoodRestoreRefused(checkpoint) { durable in
              mutateChildhood(&durable) { childhood in
                  var guardians = childhood["guardianships"] as! [[String: Any]]
                  let active = guardians.firstIndex {
                      ($0["status"] as? String) == "active"
                  }!
                  guardians[active]["guardianID"] = childID.rawValue
                  childhood["guardianships"] = guardians
              }
          })
    check("guardian absent from population corruption is refused",
          childhoodRestoreRefused(checkpoint) { durable in
              mutateChildhood(&durable) { childhood in
                  var guardians = childhood["guardianships"] as! [[String: Any]]
                  let active = guardians.firstIndex {
                      ($0["status"] as? String) == "active"
                  }!
                  guardians[active]["guardianID"] = "agent_999"
                  childhood["guardianships"] = guardians
              }
          })
    check("juvenile guardian corruption is refused",
          childhoodRestoreRefused(checkpoint) { durable in
              mutateChildhood(&durable) { childhood in
                  var guardians = childhood["guardianships"] as! [[String: Any]]
                  let active = guardians.firstIndex {
                      ($0["dependentID"] as? String) == secondChildID.rawValue
                          && ($0["status"] as? String) == "active"
                  }!
                  guardians[active]["guardianID"] = childID.rawValue
                  childhood["guardianships"] = guardians
              }
          })
    check("guardian capacity corruption is refused",
          childhoodRestoreRefused(checkpoint) { durable in
              mutateChildhood(&durable) { childhood in
                  var configuration =
                      childhood["configuration"] as! [String: Any]
                  configuration["maximumDependentsPerGuardian"] = 1
                  childhood["configuration"] = configuration
                  var guardians = childhood["guardianships"] as! [[String: Any]]
                  let firstActive = guardians.firstIndex {
                      ($0["dependentID"] as? String) == childID.rawValue
                          && ($0["status"] as? String) == "active"
                  }!
                  let secondActive = guardians.firstIndex {
                      ($0["dependentID"] as? String) == secondChildID.rawValue
                          && ($0["status"] as? String) == "active"
                  }!
                  guardians[firstActive]["guardianID"] =
                      guardians[secondActive]["guardianID"]
                  childhood["guardianships"] = guardians
              }
          })
    check("cross-household guardian corruption is refused",
          childhoodRestoreRefused(checkpoint) { durable in
              mutateChildhood(&durable) { childhood in
                  var guardians = childhood["guardianships"] as! [[String: Any]]
                  let active = guardians.firstIndex {
                      ($0["status"] as? String) == "active"
                  }!
                  guardians[active]["householdID"] =
                      otherHouseholdID.rawValue
                  childhood["guardianships"] = guardians
              }
          })
    check("unknown social profile identity corruption is refused",
          childhoodRestoreRefused(checkpoint) { durable in
              mutateChildhood(&durable) { childhood in
                  var profiles = childhood["socialProfiles"] as! [[String: Any]]
                  profiles[0]["agentID"] = "agent_unknown"
                  childhood["socialProfiles"] = profiles
              }
          })
    check("out-of-bounds social dimension corruption is refused",
          childhoodRestoreRefused(checkpoint) { durable in
              mutateChildhood(&durable) { childhood in
                  var profiles = childhood["socialProfiles"] as! [[String: Any]]
                  var values = profiles[0]["values"] as! [[String: Any]]
                  values[0]["basisPoints"] = 10_001
                  profiles[0]["values"] = values
                  childhood["socialProfiles"] = profiles
              }
          })
    check("non-causal social exposure corruption is refused",
          childhoodRestoreRefused(checkpoint) { durable in
              mutateChildhood(&durable) { childhood in
                  var exposures = childhood["exposures"] as! [[String: Any]]
                  exposures[0]["sourceEventID"] =
                      childhood["initializedEventID"]
                  childhood["exposures"] = exposures
              }
          })
    check("social counter corruption is refused",
          childhoodRestoreRefused(checkpoint) { durable in
              mutateChildhood(&durable) { childhood in
                  childhood["totalExposureCount"] = 99_999
              }
          })
    check("guardian causal identity corruption is refused",
          childhoodRestoreRefused(checkpoint) { durable in
              mutateChildhood(&durable) { childhood in
                  var guardians = childhood["guardianships"] as! [[String: Any]]
                  let active = guardians.firstIndex {
                      ($0["status"] as? String) == "active"
                  }!
                  guardians[active]["basis"] = "canonicalParent"
                  childhood["guardianships"] = guardians
              }
          })
    check("legacy care checkpoint remains readable with childhood absent",
          v9Checkpoint.schemaVersion == AgentCheckpointSchema.dependentCareVersion
            && !((try! AgentSimulationSession.restoring(v9Checkpoint))
                .childhoodV2Enabled))

    var mortality = childhoodMortalityBase()
    let mortalityBase = try! mortality.makeCheckpoint()
    var mortalityRecorder = try! AgentReplayRecorder(
        checkpoint: mortalityBase, session: mortality
    )
    let mortalityBirth = careBirth(
        &mortalityRecorder, &mortality,
        position: AgentPosition(x: 0, y: 64, z: 0),
        candidateIndex: 0
    )
    let mortalityChildID = mortalityBirth.newbornID
    let originalGuardianID = try! mortality.currentGuardian(
        for: mortalityChildID
    )!.guardianID
    _ = try! mortalityRecorder.apply(
        .setMortalityEnabled(true, configuration: .live),
        to: &mortality
    )
    for _ in 0..<5 {
        if !mortality.snapshot().agents.contains(where: {
            ["agent_0", "agent_1", "agent_2"].contains($0.id)
        }) { break }
        _ = childhoodAdvance(&mortalityRecorder, &mortality)
    }
    let postGuardianDeaths = mortality.childhoodSnapshot()
    check("guardian death ends responsibility and leaves no invented adult",
          !mortality.snapshot().agents.contains {
              ["agent_0", "agent_1", "agent_2"].contains($0.id)
          }
            && mortality.snapshot().agents.contains {
                $0.id == mortalityChildID.rawValue
            }
            && (try! mortality.currentGuardian(
                for: mortalityChildID
            )) == nil
            && (try! mortality.currentCareAssignment(
                for: mortalityChildID
            )) == nil)
    check("no eligible guardian is explicit at-risk with visible unmet care",
          postGuardianDeaths.atRiskDependentIDs.contains(mortalityChildID)
            && mortality.dependentCareSnapshot().atRiskDependentIDs
                .contains(mortalityChildID)
            && mortality.dependentCareSnapshot().activeNeeds.contains {
                $0.dependentID == mortalityChildID
                    && $0.status == .unmet
            }
            && postGuardianDeaths.guardianships.contains {
                $0.dependentID == mortalityChildID
                    && $0.guardianID == originalGuardianID
                    && $0.endedReason == .guardianDied
            })
    check("guardian death at-risk state has causal social evidence",
          postGuardianDeaths.exposures.contains {
              $0.agentID == mortalityChildID
                    && $0.dimension == .unmetCareExposure
          }
            && mortality.causalLedgerSnapshot().events.contains {
                $0.kind == .guardianUnavailable
                    && $0.subjectID == mortalityChildID
            })
    let socialAtRisk = mortality.socialDevelopmentProfile(
        for: mortalityChildID
    )
    for _ in 0..<32 where mortality.snapshot().agents.contains(where: {
        $0.id == mortalityChildID.rawValue
    }) {
        _ = childhoodAdvance(&mortalityRecorder, &mortality)
    }
    let childDeathTick = mortality.mortalitySnapshot().records.first {
        $0.agentID == mortalityChildID
    }?.deathTick
    _ = childhoodAdvance(&mortalityRecorder, &mortality)
    check("dead child cannot continue social development",
          childDeathTick != nil
            && mortality.socialDevelopmentProfile(
                for: mortalityChildID
            ) == socialAtRisk)
    let deadChildCheckpoint = try! mortality.makeCheckpoint()
    check("post-death social timestamp corruption is refused",
          childhoodRestoreRefused(deadChildCheckpoint) { durable in
              mutateChildhood(&durable) { childhood in
                  var profiles = childhood["socialProfiles"] as! [[String: Any]]
                  let profile = profiles.firstIndex {
                      ($0["agentID"] as? String) == mortalityChildID.rawValue
                  }!
                  var values = profiles[profile]["values"] as! [[String: Any]]
                  values[0]["lastChangedTick"] = childDeathTick! + 1
                  profiles[profile]["values"] = values
                  profiles[profile]["lastSignificantChangeTick"] =
                      childDeathTick! + 1
                  childhood["socialProfiles"] = profiles
              }
          })

    var maturityAdvanceError: String?
    while session.tick < birth.birthTick + 24 && maturityAdvanceError == nil {
        do {
            _ = try session.advanceTick()
        } catch {
            maturityAdvanceError = "tick=\(session.tick) error=\(error)"
        }
    }
    let matureCapabilities = try! session.childhoodCapabilities(for: childID)
    let matureStage = session.lifecycleSnapshot().members.first {
        $0.agentID == childID
    }?.currentStage
    let matureGuardian = try! session.currentGuardian(for: childID)
    let matureCare = try! session.currentCareAssignment(for: childID)
    check("maturity closes dependency and unlocks existing adult gateways",
          maturityAdvanceError == nil
            && matureStage == .mature
            && matureGuardian == nil
            && matureCare == nil
            && matureCapabilities.allowed.map(\.rawValue).sorted()
                == AgentStageCapability.allCases.map(\.rawValue).sorted()
            && matureCapabilities.refused.isEmpty
            && matureCapabilities.autonomyReadinessBasisPoints == 10_000,
          maturityAdvanceError
            ?? "stage=\(String(describing: matureStage)) "
                + "guardian=\(String(describing: matureGuardian?.guardianID)) "
                + "care=\(String(describing: matureCare?.caregiverID)) "
                + "allowed=\(matureCapabilities.allowed.count) "
                + "refused=\(matureCapabilities.refused.count) "
                + "readiness=\(matureCapabilities.autonomyReadinessBasisPoints)")
}
