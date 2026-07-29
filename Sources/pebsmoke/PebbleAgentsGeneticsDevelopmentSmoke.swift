import Foundation
import PebbleAgents

private let geneticsHabitat = AgentEcologyHabitatObservation(
    worldTick: 0,
    candidateIndex: 0,
    habitatPosition: AgentPosition(x: 1, y: 63, z: 0),
    foragePosition: AgentPosition(x: 1, y: 64, z: 0),
    habitatFingerprint: 3_022,
    distanceFromSettlement: 1,
    directionIndex: 0,
    worldReadCount: 4
)

private let geneticsStableSurvival = try! AgentSurvivalConfiguration(
    hungerPerTick: 0.001,
    fatiguePerTick: 0.001,
    hungryThreshold: 0.4,
    criticalHungerThreshold: 0.8,
    hungerRecoveryThreshold: 0.15,
    fatigueThreshold: 0.65,
    fatigueRecoveryThreshold: 0.2,
    foodNutrition: 1,
    restRecoveryPerTick: 1,
    starvationGraceTicks: 0,
    starvationDamagePerTick: 100
)

private let geneticsFastSurvival = try! AgentSurvivalConfiguration(
    hungerPerTick: 0.1,
    fatiguePerTick: 0.1,
    hungryThreshold: 0.4,
    criticalHungerThreshold: 0.8,
    hungerRecoveryThreshold: 0.15,
    fatigueThreshold: 0.65,
    fatigueRecoveryThreshold: 0.2,
    foodNutrition: 1,
    restRecoveryPerTick: 1,
    starvationGraceTicks: 0,
    starvationDamagePerTick: 100
)

private func geneticsAgent(
    _ id: String,
    hunger: Double = 0,
    fatigue: Double = 0
) -> AgentSessionAgentState {
    let ordinal = Int(id.split(separator: "_").last ?? "0") ?? 0
    let position = AgentPosition(x: ordinal * 2, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id,
        state: "idle",
        position: position,
        needs: AgentNeeds(
            hunger: hunger, fatigue: fatigue, curiosity: 0.1, safety: 1
        ),
        health: 100,
        fear: 0,
        homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle,
            reason: "CIV-30 deterministic fixture",
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
        totalDistanceReducedTowardHome: 0
    )
}

private func geneticsSession(
    _ simulationID: String,
    order: [String] = ["agent_0", "agent_1", "agent_2"],
    hungerByID: [String: Double] = [:],
    fatigueByID: [String: Double] = [:],
    survival: AgentSurvivalConfiguration = geneticsStableSurvival,
    homeostasis: AgentHomeostasisConfiguration = .live,
    mortality: AgentMortalityConfiguration = .live,
    genetics: AgentGeneticsConfiguration = .live,
    lifecycle: AgentLifecycleConfiguration = .live,
    enableGenetics: Bool = true
) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 30,
            memoryPolicy: .bounded(maxEntries: 128),
            survivalConfiguration: survival
        ),
        agents: order.map {
            geneticsAgent(
                $0,
                hunger: hungerByID[$0] ?? 0,
                fatigue: fatigueByID[$0] ?? 0
            )
        },
        simulationID: try! AgentSimulationID(validating: simulationID),
        causalLedgerPolicy: .bounded(maxEvents: 16_384)
    )
    session.setSurvivalEnabled(true)
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3)
    )
    try! session.initializeLocalEcology(
        observations: [geneticsHabitat]
    )
    _ = try! session.applyLocalEcologyEndOfTick(
        habitatValidations: [geneticsHabitat]
    )
    try! session.setMortalityEnabled(true, configuration: mortality)
    try! session.setLifecycleEnabled(true, configuration: lifecycle)
    try! session.setHomeostasisEnabled(true, configuration: homeostasis)
    if enableGenetics {
        try! session.setGeneticsEnabled(true, configuration: genetics)
    }
    return session
}

private func geneticsAdvance(
    _ session: inout AgentSimulationSession,
    to targetTick: Int
) {
    while session.tick < targetTick {
        _ = try! session.advanceTick()
    }
}

@discardableResult
private func geneticsBirth(
    _ session: inout AgentSimulationSession
) -> AgentBirthRecord {
    try! session.setReproductionEnabled(true)
    geneticsAdvance(&session, to: 4)
    let plan = session.pendingBirthSitePlan()!
    return try! session.applyBirthSiteObservation(
        AgentBirthSiteObservation(
            planID: plan.planID,
            observedTick: session.tick,
            position: AgentPosition(x: 0, y: 64, z: 4),
            candidateIndex: 0,
            worldFingerprint: 30_001
        )
    )!
}

private func geneticsCausalPathExists(
    events: [AgentCausalEvent],
    from descendantID: AgentCausalEventID,
    to ancestorID: AgentCausalEventID,
    maximumDepth: Int = 16
) -> Bool {
    let byID = Dictionary(uniqueKeysWithValues: events.map { ($0.eventID, $0) })
    var frontier: [(AgentCausalEventID, Int)] = [(descendantID, 0)]
    var visited: Set<AgentCausalEventID> = []
    while let (eventID, depth) = frontier.first {
        frontier.removeFirst()
        if eventID == ancestorID { return true }
        guard depth < maximumDepth,
              visited.insert(eventID).inserted,
              let event = byID[eventID] else { continue }
        frontier.append(contentsOf: event.causes.map { ($0, depth + 1) })
    }
    return false
}

func runPebbleAgentsGeneticsDevelopmentSmoke() {
    section("CIV-30 genetics, development, and phenotype V1")

    check("genetics V1 is closed and bounded",
          AgentGeneticLocus.allCases.count == 4
            && AgentGeneticAllele.allCases.count == 3
            && AgentPhenotypeTraitID.allCases.count == 4)
    check("genetics configuration rejects unsupported model versions", {
        do {
            _ = try AgentGeneticsConfiguration(modelVersion: 2)
            return false
        } catch AgentGeneticsError.invalidConfiguration("model version") {
            return true
        } catch {
            return false
        }
    }())
    check("genetics configuration rejects unbounded profiles", {
        do {
            _ = try AgentGeneticsConfiguration(maximumProfiles: 513)
            return false
        } catch AgentGeneticsError.invalidConfiguration("profiles") {
            return true
        } catch {
            return false
        }
    }())

    var founders = geneticsSession("civ30-founders")
    let founderSnapshot = founders.geneticsSnapshot()
    check("explicit activation assigns every founder exactly once",
          founderSnapshot.enabled
            && founderSnapshot.genotypes.map(\.agentID.rawValue)
                == ["agent_0", "agent_1", "agent_2"]
            && founderSnapshot.genotypes.allSatisfy {
                $0.origin == .founder
                    && $0.contributorIDs == [$0.agentID]
                    && $0.loci.count == 4
                    && $0.loci.allSatisfy { $0.contributions.count == 2 }
            })
    check("founder initialization is causally explicit",
          founders.causalLedgerSnapshot().events.filter {
              $0.kind == .geneticsInitialized
          }.count == 1
            && founders.causalLedgerSnapshot().events.filter {
                $0.kind == .founderGenotypeAssigned
            }.count == 3
            && founderSnapshot.totalTransitionCount == 4)
    check("persisted founder genomes cannot be silently regenerated", {
        let before = try! founders.durableStateBytes()
        do {
            try founders.setGeneticsEnabled(true)
            return false
        } catch AgentSessionError.genetics(.alreadyEnabled) {
            return (try! founders.durableStateBytes()) == before
        } catch {
            return false
        }
    }())

    let permuted = geneticsSession(
        "civ30-founders",
        order: ["agent_2", "agent_0", "agent_1"]
    )
    check("founder genomes do not depend on input iteration order",
          permuted.geneticsSnapshot().genotypes
            == founderSnapshot.genotypes
            && (try! permuted.durableStateBytes())
                == (try! founders.durableStateBytes()))

    var imported = geneticsSession("civ30-imported-root")
    let migrationRoute = [
        AgentPosition(x: 4, y: 64, z: 3),
        AgentPosition(x: 3, y: 64, z: 3),
        AgentPosition(x: 2, y: 64, z: 3),
        AgentPosition(x: 1, y: 64, z: 3),
        AgentPosition(x: 0, y: 64, z: 3),
    ]
    let migration = try! imported.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: AgentMigrationWorldObservation(
            worldTick: 0,
            candidateIndex: 0,
            entryPosition: migrationRoute[0],
            receptionPosition: migrationRoute.last!,
            route: migrationRoute,
            entryChunkReady: true,
            entrySafe: true,
            entryUnoccupied: true,
            receptionChunkReady: true,
            receptionSafe: true,
            receptionUnoccupied: true
        )
    )
    let importedGenotype = imported.genotype(for: migration.migrantID)
    check("imported population roots receive one deterministic genotype atomically",
          migration.migrantID.rawValue == "agent_3"
            && importedGenotype?.origin == .founder
            && importedGenotype?.contributorIDs == [migration.migrantID]
            && imported.geneticsSnapshot().genotypes.count == 4
            && imported.homeostasisProfile(for: migration.migrantID) != nil)
    check("imported genotype survives immediate checkpoint validation",
          (try? AgentSimulationSession.restoring(
              try! imported.makeCheckpoint()
          ).genotype(for: migration.migrantID)) == importedGenotype)

    let founderCheckpoint = try! founders.makeCheckpoint()
    let founderRestored = try! AgentSimulationSession.restoring(
        founderCheckpoint
    )
    check("genetics checkpoint schema 22 round-trips exactly",
          founderCheckpoint.schemaVersion == AgentCheckpointSchema.geneticsVersion
            && (try! founderRestored.durableStateBytes())
                == (try! founders.durableStateBytes())
            && founderRestored.geneticsSnapshot() == founderSnapshot)

    var birthSession = geneticsSession("civ30-inheritance")
    let birth = geneticsBirth(&birthSession)
    let child = birth.newbornID
    let childGenotype = birthSession.genotype(for: child)!
    check("normal birth atomically publishes an inherited genotype",
          birthSession.snapshot().agents.contains {
              $0.id == child.rawValue
          }
            && childGenotype.origin == .inherited
            && childGenotype.birthID == birth.birthID
            && childGenotype.contributorIDs == birth.progenitorIDs
            && birthSession.development(for: child) != nil
            && birthSession.phenotype(for: child) != nil)
    let parentGenotypes = Dictionary(uniqueKeysWithValues:
        birth.progenitorIDs.map { ($0, birthSession.genotype(for: $0)!) }
    )
    let inheritedContributionsValid = childGenotype.loci.allSatisfy { locus in
        locus.contributions.count == 2
            && Set(locus.contributions.map(\.contributorID))
                == Set(birth.progenitorIDs)
            && locus.contributions.allSatisfy { contribution in
                guard let parent = parentGenotypes[contribution.contributorID],
                      contribution.sourceGenotypeID == parent.genotypeID,
                      let parentLocus = parent.loci.first(where: {
                          $0.locus == locus.locus
                      })
                else { return false }
                return parentLocus.contributions[
                    contribution.sourceAlleleIndex
                ].allele == contribution.allele
            }
    }
    check("every child allele comes from its canonical contributor",
          inheritedContributionsValid)
    let birthLedger = birthSession.causalLedgerSnapshot()
    let inheritedEvent = birthLedger.events.first {
        $0.eventID == childGenotype.creationEventID
    }
    check("birth Chronicle links parents, genotype, and child publication",
          inheritedEvent?.kind == .genotypeInherited
            && Set(inheritedEvent?.causes ?? []).isSuperset(of: Set(
                birth.progenitorIDs.compactMap {
                    parentGenotypes[$0]?.creationEventID
                }
            ))
            && geneticsCausalPathExists(
                events: birthLedger.events,
                from: birth.finalizedEventID,
                to: childGenotype.creationEventID
            ))

    var permutedBirth = geneticsSession(
        "civ30-inheritance",
        order: ["agent_2", "agent_1", "agent_0"]
    )
    let permutedRecord = geneticsBirth(&permutedBirth)
    check("canonical inheritance is neutral to parent and input ordering",
          permutedRecord.newbornID == child
            && permutedBirth.genotype(for: child) == childGenotype
            && (try! permutedBirth.durableStateBytes())
                == (try! birthSession.durableStateBytes()))

    let siblingLifecycle = try! AgentLifecycleConfiguration(
        reproductionCooldownTicks: 3
    )
    let siblingHomeostasis = try! AgentHomeostasisConfiguration(
        ageVulnerabilityStartTicks: 1_000,
        baseHealthDamagePerTick: 50
    )
    var siblingSession = geneticsSession(
        "civ30-siblings",
        hungerByID: ["agent_2": 0.9],
        fatigueByID: ["agent_2": 0.9],
        homeostasis: siblingHomeostasis,
        lifecycle: siblingLifecycle
    )
    while siblingSession.mortalitySnapshot().totalDeathCount == 0 {
        _ = try! siblingSession.advanceTick()
    }
    try! siblingSession.setReproductionEnabled(true)
    while siblingSession.pendingBirthSitePlan() == nil {
        _ = try! siblingSession.advanceTick()
    }
    let firstSiblingPlan = siblingSession.pendingBirthSitePlan()!
    let firstSiblingBirth = try! siblingSession.applyBirthSiteObservation(
        AgentBirthSiteObservation(
            planID: firstSiblingPlan.planID,
            observedTick: siblingSession.tick,
            position: AgentPosition(x: 0, y: 64, z: 4),
            candidateIndex: 0,
            worldFingerprint: 30_003
        )
    )!
    let firstSiblingGenotype = siblingSession.genotype(
        for: firstSiblingBirth.newbornID
    )!
    while siblingSession.pendingBirthSitePlan() == nil {
        _ = try! siblingSession.advanceTick()
    }
    let siblingPlan = siblingSession.pendingBirthSitePlan()!
    let siblingBirth = try! siblingSession.applyBirthSiteObservation(
        AgentBirthSiteObservation(
            planID: siblingPlan.planID,
            observedTick: siblingSession.tick,
            position: AgentPosition(x: 1, y: 64, z: 4),
            candidateIndex: 0,
            worldFingerprint: 30_004
        )
    )!
    let siblingGenotype = siblingSession.genotype(
        for: siblingBirth.newbornID
    )!
    check("distinct birth identities deterministically vary sibling inheritance",
          siblingBirth.progenitorIDs == firstSiblingBirth.progenitorIDs
            && siblingGenotype.origin == .inherited
            && siblingGenotype.immutableDigest
                != firstSiblingGenotype.immutableDigest,
          "parents1=\(firstSiblingBirth.progenitorIDs) "
            + "parents2=\(siblingBirth.progenitorIDs) "
            + "first=\(firstSiblingGenotype.loci.map { $0.contributions.map { $0.allele.rawValue } }) "
            + "second=\(siblingGenotype.loci.map { $0.contributions.map { $0.allele.rawValue } })")

    var rejectedBirth = geneticsSession("civ30-birth-atomicity")
    try! rejectedBirth.setReproductionEnabled(true)
    geneticsAdvance(&rejectedBirth, to: 4)
    let rejectedBefore = try! rejectedBirth.durableStateBytes()
    let unknownPlan = AgentReproductionPlanID(
        rawValue: "civ30-unknown-plan"
    )!
    check("rejected birth publishes neither child nor orphan genotype", {
        do {
            _ = try rejectedBirth.applyBirthSiteObservation(
                AgentBirthSiteObservation(
                    planID: unknownPlan,
                    observedTick: rejectedBirth.tick,
                    position: AgentPosition(x: 0, y: 64, z: 4),
                    candidateIndex: 0,
                    worldFingerprint: 30_002
                )
            )
            return false
        } catch {
            return rejectedBirth.snapshot().agentCount == 3
                && rejectedBirth.geneticsSnapshot().genotypes.count == 3
                && (try! rejectedBirth.durableStateBytes()) == rejectedBefore
        }
    }())

    var stableExposure = geneticsSession("civ30-environment")
    let stableInitialGenotype = stableExposure.genotype(
        for: AgentID(rawValue: "agent_0")!
    )!
    var stressedExposure = geneticsSession(
        "civ30-environment",
        hungerByID: ["agent_0": 0.9],
        fatigueByID: ["agent_0": 0.9]
    )
    geneticsAdvance(&stableExposure, to: 3)
    geneticsAdvance(&stressedExposure, to: 3)
    let stableDevelopment = stableExposure.development(
        for: AgentID(rawValue: "agent_0")!
    )!
    let stressedDevelopment = stressedExposure.development(
        for: AgentID(rawValue: "agent_0")!
    )!
    check("same genotype develops differently under real physiological exposure",
          stableExposure.genotype(for: AgentID(rawValue: "agent_0")!)
            == stressedExposure.genotype(for: AgentID(rawValue: "agent_0")!)
            && stableDevelopment.physiologicalExposureBasisPoints
                < stressedDevelopment.physiologicalExposureBasisPoints
            && stableExposure.phenotype(
                for: AgentID(rawValue: "agent_0")!
            ) != stressedExposure.phenotype(
                for: AgentID(rawValue: "agent_0")!
            ))
    check("development never rewrites immutable genotype",
          stableExposure.genotype(for: AgentID(rawValue: "agent_0")!)
            == stableInitialGenotype)

    let founderZero = stableExposure.genotype(
        for: AgentID(rawValue: "agent_0")!
    )!
    let founderOne = stableExposure.genotype(
        for: AgentID(rawValue: "agent_1")!
    )!
    check("different founder genotypes can express bounded physical variance",
          founderZero.immutableDigest != founderOne.immutableDigest
            && zip(founderZero.loci, founderOne.loci).contains {
                $0.potentialBasisPoints != $1.potentialBasisPoints
            }
            && stableExposure.phenotype(
                for: AgentID(rawValue: "agent_0")!
            )!.traits.allSatisfy {
                (-800...800).contains($0.expressedModifierBasisPoints)
            })

    var physiologicalVariance = geneticsSession(
        "civ30-physiological-effect",
        hungerByID: [
            "agent_0": 0.9, "agent_1": 0.9, "agent_2": 0.9,
        ],
        fatigueByID: [
            "agent_0": 0.9, "agent_1": 0.9, "agent_2": 0.9,
        ],
        survival: geneticsFastSurvival
    )
    let relevantModifiers = ["agent_0", "agent_1", "agent_2"].map {
        let id = AgentID(rawValue: $0)!
        return [
            physiologicalVariance.phenotypeModifier(
                .homeostaticResilience, for: id
            ),
            physiologicalVariance.phenotypeModifier(
                .deprivationTolerance, for: id
            ),
        ]
    }
    _ = try! physiologicalVariance.advanceTick()
    let physiologicalProfiles = physiologicalVariance.homeostasisSnapshot()
        .profiles
    check("bounded phenotype modifiers affect existing CIV-29 physiology",
          Set(relevantModifiers.map { $0.map(String.init).joined(separator: ":") })
                .count > 1
            && Set(physiologicalProfiles.map(\.stressBasisPoints)).count > 1
            && physiologicalProfiles.allSatisfy {
                $0.activeFactors.filter {
                    $0.code == .phenotypeExpression
                }.allSatisfy { !$0.harmful }
            })

    var stageSession = geneticsSession("civ30-stage")
    let stageGenotype = stageSession.genotype(
        for: AgentID(rawValue: "agent_0")!
    )!
    let initialMaturity = stageSession.development(
        for: AgentID(rawValue: "agent_0")!
    )!.expressionMaturityBasisPoints
    geneticsAdvance(&stageSession, to: 3)
    let laterDevelopment = stageSession.development(
        for: AgentID(rawValue: "agent_0")!
    )!
    check("normal time advances maturation without changing genotype",
          laterDevelopment.expressionMaturityBasisPoints >= initialMaturity
            && laterDevelopment.updateCount == 3
            && stageSession.genotype(
                for: AgentID(rawValue: "agent_0")!
            ) == stageGenotype)
    let developmentEvents = stageSession.causalLedgerSnapshot().events.filter {
        $0.kind == .developmentChanged
    }
    check("development events use the authoritative boundary tick",
          developmentEvents.allSatisfy {
              $0.simulationTick.rawValue == $0.instant.tick.rawValue
                  && $0.simulationTick.rawValue > 0
          })

    let boundedGenetics = try! AgentGeneticsConfiguration(
        maximumRetainedTransitions: 3,
        significantChangeBasisPoints: 1
    )
    var bounded = geneticsSession(
        "civ30-bounded",
        genetics: boundedGenetics
    )
    geneticsAdvance(&bounded, to: 8)
    let boundedSnapshot = bounded.geneticsSnapshot()
    check("genetics transition retention is bounded with explicit eviction",
          boundedSnapshot.recentTransitions.count == 3
            && boundedSnapshot.transitionEvictionCount > 0
            && boundedSnapshot.totalTransitionCount
                == boundedSnapshot.recentTransitions.count
                    + boundedSnapshot.transitionEvictionCount)

    let observerWorld = try! AgentObserverWorldBinding(
        worldID: "world-civ30",
        storageIdentity: "sqlite-world:world-civ30",
        seed: 30,
        dimension: 0,
        observedWorldTick: birthSession.tick
    )
    let observerBefore = try! birthSession.durableStateDigest()
    let observerSequence = birthSession.causalLedgerSnapshot().summary
        .latestSequence
    let observer = birthSession.observerSnapshot(
        worldBinding: observerWorld
    )
    let observedChild = observer.individual(child)!
    check("Observer schema 3 exposes authoritative genetics layers",
          observer.header.schemaVersion == 3
            && observedChild.genetics?.origin == .inherited
            && observedChild.genetics?.development.active == true
            && observedChild.genetics?.phenotype.count == 4)
    check("genetics observation remains strictly read-only",
          (try! birthSession.durableStateDigest()) == observerBefore
            && birthSession.causalLedgerSnapshot().summary.latestSequence
                == observerSequence)

    var checkpointContinuation = birthSession
    let checkpoint = try! checkpointContinuation.makeCheckpoint()
    var restoredContinuation = try! AgentSimulationSession.restoring(
        checkpoint
    )
    _ = try! checkpointContinuation.advanceTick()
    _ = try! restoredContinuation.advanceTick()
    check("restart never redraws alleles or duplicates development",
          checkpoint.schemaVersion == AgentCheckpointSchema.geneticsVersion
            && (try! restoredContinuation.durableStateBytes())
                == (try! checkpointContinuation.durableStateBytes())
            && restoredContinuation.genotype(for: child)
                == checkpointContinuation.genotype(for: child))

    var replayTarget = geneticsSession("civ30-replay")
    let replayCheckpoint = try! replayTarget.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(
        checkpoint: replayCheckpoint,
        session: replayTarget
    )
    _ = try! recorder.apply(
        .advanceTick(perceptions: [], physicalObservations: []),
        to: &replayTarget
    )
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "civ30-genetics")!
    )
    let replay = try! AgentSessionReplayer.replay(
        checkpoint: replayCheckpoint,
        journal: journal
    )
    check("checkpoint replay schema 22 is byte exact",
          journal.manifest.schemaVersion == AgentReplaySchema.geneticsVersion
            && replay.report.verified
            && (try! replay.session.durableStateBytes())
                == (try! replayTarget.durableStateBytes()))

    var upgrade = geneticsSession(
        "civ30-schema21-upgrade",
        enableGenetics: false
    )
    let upgradeCheckpoint = try! upgrade.makeCheckpoint()
    var upgradeRecorder = try! AgentReplayRecorder(
        checkpoint: upgradeCheckpoint,
        session: upgrade
    )
    _ = try! upgradeRecorder.apply(
        .setGeneticsEnabled(true, configuration: .live),
        to: &upgrade
    )
    let upgradeJournal = try! upgradeRecorder.journal(
        named: AgentCheckpointName(rawValue: "civ30-schema21-upgrade")!
    )
    let upgradeReplay = try! AgentSessionReplayer.replay(
        checkpoint: upgradeCheckpoint,
        journal: upgradeJournal
    )
    check("schema 21 requires explicit replayable founder activation",
          upgradeCheckpoint.schemaVersion
                == AgentCheckpointSchema.homeostasisVersion
            && upgradeJournal.manifest.schemaVersion
                == AgentReplaySchema.geneticsVersion
            && upgradeReplay.report.verified
            && (try! upgradeReplay.session.durableStateBytes())
                == (try! upgrade.durableStateBytes()))

    check("schema 22 refuses corrupt or unknown allele data", {
        let bytes = try! AgentCheckpointCodec.encode(
            try! birthSession.makeCheckpoint()
        )
        let text = String(data: bytes, encoding: .utf8)!
        guard let range = text.range(
            of: "\"allele\":\"enhanced\""
        ) ?? text.range(of: "\"allele\":\"reference\"")
            ?? text.range(of: "\"allele\":\"reduced\"")
        else { return false }
        let corrupt = text.replacingCharacters(
            in: range,
            with: "\"allele\":\"unknown\""
        )
        return (try? AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self,
            from: Data(corrupt.utf8)
        )) == nil
    }())

    let lethalHomeostasis = try! AgentHomeostasisConfiguration(
        maximumEpisodesPerProfile: 2,
        maximumRetainedTransitions: 8,
        ageVulnerabilityStartTicks: 1_000,
        baseHealthDamagePerTick: 50
    )
    var terminal = geneticsSession(
        "civ30-terminal",
        hungerByID: ["agent_0": 0.9],
        fatigueByID: ["agent_0": 0.9],
        survival: geneticsFastSurvival,
        homeostasis: lethalHomeostasis
    )
    let terminalAgent = AgentID(rawValue: "agent_0")!
    let terminalGenotype = terminal.genotype(for: terminalAgent)!
    for _ in 0..<12
        where terminal.mortalitySnapshot().totalDeathCount == 0 {
        _ = try! terminal.advanceTick()
    }
    let terminalPhenotype = terminal.phenotype(for: terminalAgent)!
    let stoppedDevelopment = terminal.development(for: terminalAgent)
    let stoppedUpdateCount = stoppedDevelopment?.updateCount
    let terminalCheckpoint = try! terminal.makeCheckpoint()
    var terminalRestored = try! AgentSimulationSession.restoring(
        terminalCheckpoint
    )
    _ = try! terminalRestored.advanceTick()
    check("death preserves historical genetics and stops development",
          terminal.mortalitySnapshot().totalDeathCount == 1
            && terminal.genotype(for: terminalAgent) == terminalGenotype
            && terminal.phenotype(for: terminalAgent) == terminalPhenotype
            && stoppedDevelopment?.active == false
            && stoppedDevelopment?.stoppedAtTick != nil
            && terminalRestored.development(for: terminalAgent)?.updateCount
                == stoppedUpdateCount
            && terminalRestored.genotype(for: terminalAgent)
                == terminalGenotype,
          "deaths=\(terminal.mortalitySnapshot().totalDeathCount) "
            + "pending=\(terminal.pendingMortalityTransitions().count) "
            + "tick=\(terminal.tick) active="
            + "\(String(describing: stoppedDevelopment?.active)) "
            + "stopped=\(String(describing: stoppedDevelopment?.stoppedAtTick)) "
            + "phenotypeEqual="
            + "\(terminal.phenotype(for: terminalAgent) == terminalPhenotype)")
}
