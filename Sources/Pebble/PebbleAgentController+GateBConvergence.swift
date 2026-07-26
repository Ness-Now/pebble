import Foundation
import PebbleAgents
import PebbleCore

/// Read-only, process-comparable evidence for the bounded convergence mission.
///
/// This value is deliberately not persisted and owns no simulation state. All
/// hashes are derived from existing PebbleAgents snapshots or exact PebbleCore
/// observations. The aggregate digest also covers the unprinted World entity
/// projection so checkpoint reconciliation compares both sides of the live
/// binding without turning transient Core identities into durable cognition.
struct PebbleGateBConvergenceSemanticSnapshot: Equatable {
    let tick: Int
    let durable: String
    let population: String
    let agentCount: Int
    let alive: Int
    let positionsHome: String
    let activities: String
    let materialCustody: String
    let food: String
    let agriculture: String
    let livestock: String
    let care: String
    let teaching: String
    let work: String
    let skills: String
    let causal: String
    let causalSequence: UInt64
    let worldEntities: Int
    let semanticDigest: String
    let completions: Int
    fileprivate let worldEntityDigest: String

    fileprivate var tracePayload: String {
        "tick=\(tick) durable=\(durable) population=\(population) "
            + "agentCount=\(agentCount) alive=\(alive) positionsHome=\(positionsHome) "
            + "activities=\(activities) materialCustody=\(materialCustody) food=\(food) "
            + "agriculture=\(agriculture) livestock=\(livestock) care=\(care) "
            + "teaching=\(teaching) work=\(work) skills=\(skills) causal=\(causal) "
            + "causalSequence=\(causalSequence) worldEntities=\(worldEntities) "
            + "semanticDigest=\(semanticDigest) worldEntityDigest=\(worldEntityDigest)"
    }
}

/// Exact diagnostic state for the seed-887 custody boundary. Encoded
/// inventories retain slot order and full material identity while the compact
/// total string makes the physical conservation equation independently
/// inspectable. This state is transient evidence, never persistence.
struct PebbleGateBConvergenceCustodySnapshot: Equatable {
    let tick: Int
    let durable: String
    let civilizationAgentIDs: String
    let probeRuntimeBindings: String
    let worldEntityIDs: String
    let agentInventories: String
    let containerInventories: String
    let looseItemEntities: String
    let agentFingerprints: String
    let containerFingerprints: String
    let materialTotals: String
    let agentMaterialQuantity: Int
    let containerMaterialQuantity: Int
    let looseMaterialQuantity: Int
    let trackedCustodyDigest: String

    var totalMaterialQuantity: Int {
        agentMaterialQuantity + containerMaterialQuantity + looseMaterialQuantity
    }

    fileprivate var tracePayload: String {
        "tick=\(tick) durable=\(durable) "
            + "civilizationAgentIDs=\(civilizationAgentIDs) "
            + "probeRuntimeBindings=\(probeRuntimeBindings) "
            + "worldEntityIDs=\(worldEntityIDs) "
            + "agentInventories=\(agentInventories) "
            + "containerInventories=\(containerInventories) "
            + "looseItemEntities=\(looseItemEntities) "
            + "agentFingerprints=\(agentFingerprints) "
            + "containerFingerprints=\(containerFingerprints) "
            + "materialTotals=\(materialTotals) "
            + "agentMaterialQuantity=\(agentMaterialQuantity) "
            + "containerMaterialQuantity=\(containerMaterialQuantity) "
            + "looseMaterialQuantity=\(looseMaterialQuantity) "
            + "totalMaterialQuantity=\(totalMaterialQuantity) "
            + "trackedCustodyDigest=\(trackedCustodyDigest)"
    }
}

struct PebbleGateBConvergenceChurnSnapshot: Equatable {
    let tick: Int
    let retained: Int
    let evicted: Int
    let starts: Int
    let completed: Int
    let blocked: Int
    let stale: Int
    let interrupted: Int
    let superseded: Int
    let sameCandidateRestarts: Int
    let sameTargetRestarts: Int
    let sameCandidateTargetRestarts: Int
    let continuations: Int
    let crossFamilySwitches: Int
    let lifetimeSamples: Int
    let lifetimeMinimum: Int
    let lifetimeMaximum: Int
    let lifetimeTotal: Int
    let sameObservedFailureRun: Int
    let sameObservedFailureSpan: Int
    let blocking: Bool
    let blockingReasons: String

    fileprivate var tracePayload: String {
        "tick=\(tick) retained=\(retained) evicted=\(evicted) starts=\(starts) "
            + "completed=\(completed) blocked=\(blocked) stale=\(stale) "
            + "interrupted=\(interrupted) superseded=\(superseded) "
            + "sameCandidateRestarts=\(sameCandidateRestarts) "
            + "sameTargetRestarts=\(sameTargetRestarts) "
            + "sameCandidateTargetRestarts=\(sameCandidateTargetRestarts) "
            + "continuations=\(continuations) "
            + "crossFamilySwitches=\(crossFamilySwitches) "
            + "lifetimeSamples=\(lifetimeSamples) lifetimeMinimum=\(lifetimeMinimum) "
            + "lifetimeMaximum=\(lifetimeMaximum) lifetimeTotal=\(lifetimeTotal) "
            + "maxLifetime=\(lifetimeMaximum) "
            + "sameObservedFailureRun=\(sameObservedFailureRun) "
            + "sameObservedFailureSpan=\(sameObservedFailureSpan) "
            + "blocking=\(blocking ? 1 : 0) blockingReasons=\(blockingReasons)"
    }
}

private struct PebbleGateBConvergenceFoodAgentProjection: Encodable {
    let id: String
    let hunger: Double
    let health: Int
    let survival: AgentSurvivalProgress?
}

private struct PebbleGateBConvergenceProbeBindingProjection: Encodable {
    let agentID: String
    let runtimeEntityID: Int
    let physicalID: String
}

private struct PebbleGateBConvergenceLooseItemProjection: Encodable {
    let runtimeEntityID: Int
    let xBits: UInt64
    let yBits: UInt64
    let zBits: UInt64
    let stack: AgentMaterialStackSnapshot
}

extension PebbleAgentController {
    private var gateBConvergenceInstrumentationEnabled: Bool {
        environment["PEBBLELAB_GATE_B_CONVERGENCE"] == "1"
    }

    /// Captures exact logical and live physical state without mutating either
    /// authority. A disabled mission returns nil and performs no observation.
    func gateBConvergenceSemanticSnapshot(
        world: World
    ) throws -> PebbleGateBConvergenceSemanticSnapshot? {
        guard gateBConvergenceInstrumentationEnabled else { return nil }
        guard let session, activeWorld === world else {
            throw ControllerError.feedbackBoundary(
                "Gate B convergence semantic snapshot requires the active session World"
            )
        }

        let sessionSnapshot = session.snapshot()
        let agents = sessionSnapshot.agents.sorted { $0.id < $1.id }
        let autonomy = session.autonomousActivitySnapshot()
        let causalSummary = session.causalLedgerSnapshot().summary
        let custody = try gateBConvergenceMaterialCustody(
            agentIDs: agents.map(\.id), world: world
        )
        let worldEntityDigest = try gateBConvergenceWorldEntityDigest(world: world)

        let positionsHomeCanonical = agents.map {
            "\($0.id)|\(gateBConvergencePosition($0.position))|"
                + "\(gateBConvergencePosition($0.homePosition))|\($0.isAlive ? 1 : 0)"
        }.joined(separator: ";")
        let foodCanonical = try gateBConvergenceFoodCanonical(
            session: session, agents: agents, custody: custody
        )

        let durable = try session.durableStateDigest().rawValue
        let population = try gateBConvergenceDigest(session.populationSnapshot())
        let positionsHome = gateBConvergenceDigest(positionsHomeCanonical)
        let activities = try gateBConvergenceDigest(autonomy)
        let materialCustody = try gateBConvergenceDigest(custody)
        let food = gateBConvergenceDigest(foodCanonical)
        let agriculture = try gateBConvergenceDigest(session.agricultureSnapshot())
        let livestock = try gateBConvergenceDigest(session.livestockSnapshot())
        let care = try gateBConvergenceDigest(session.dependentCareSnapshot())
        let teaching = try gateBConvergenceDigest(session.teachingSnapshot())
        let work = try gateBConvergenceDigest(session.workCommitmentSnapshot())
        let skills = try gateBConvergenceDigest(session.skillSnapshot())
        let causal = try gateBConvergenceDigest(causalSummary)
        let alive = agents.filter(\.isAlive).count
        let semanticCanonical = [
            "tick=\(session.tick)",
            "durable=\(durable)",
            "population=\(population)",
            "agentCount=\(agents.count)",
            "alive=\(alive)",
            "positionsHome=\(positionsHome)",
            "activities=\(activities)",
            "materialCustody=\(materialCustody)",
            "food=\(food)",
            "agriculture=\(agriculture)",
            "livestock=\(livestock)",
            "care=\(care)",
            "teaching=\(teaching)",
            "work=\(work)",
            "skills=\(skills)",
            "causal=\(causal)",
            "causalSequence=\(causalSummary.latestSequence)",
            "worldEntities=\(world.entities.count)",
            "worldEntityDigest=\(worldEntityDigest)",
            "completions=\(autonomy.counters.completionCount)",
        ].joined(separator: "|")

        return PebbleGateBConvergenceSemanticSnapshot(
            tick: session.tick,
            durable: durable,
            population: population,
            agentCount: agents.count,
            alive: alive,
            positionsHome: positionsHome,
            activities: activities,
            materialCustody: materialCustody,
            food: food,
            agriculture: agriculture,
            livestock: livestock,
            care: care,
            teaching: teaching,
            work: work,
            skills: skills,
            causal: causal,
            causalSequence: causalSummary.latestSequence,
            worldEntities: world.entities.count,
            semanticDigest: gateBConvergenceDigest(semanticCanonical),
            completions: autonomy.counters.completionCount,
            worldEntityDigest: worldEntityDigest
        )
    }

    /// Emits exactly the public semantic keys consumed by the convergence
    /// parser. `semanticDigest` and `completions` remain available on the
    /// comparable structure for checkpoint orchestration.
    @discardableResult
    func traceGateBConvergenceSemantic(
        world: World
    ) throws -> PebbleGateBConvergenceSemanticSnapshot? {
        guard let snapshot = try gateBConvergenceSemanticSnapshot(world: world) else {
            return nil
        }
        trace("GATE_B_CONVERGENCE_SEMANTIC \(snapshot.tracePayload)")
        return snapshot
    }

    /// Describes churn without confusing bounded retention with lifetime
    /// counters. Starts/completions/blocks/switch interruptions come from the
    /// durable counters; stale reasons, exact retry motifs, and lifetimes come
    /// from the exact retained autonomous record window. It is diagnostic only:
    /// no completion threshold is interpreted as success.
    ///
    /// `blocking` identifies one exact churn motif: at least four consecutive
    /// terminal failures spanning at least 32 ticks for the same actor,
    /// candidate, target, observation tick, lifecycle, and verbatim reason,
    /// with no intervening record for that actor. A completion, a fresh
    /// observation, or any candidate/outcome change resets the run. Thus the
    /// flag reports a proven long unchanged retry loop in the bounded retained
    /// window, not a heuristic completion ratio.
    func gateBConvergenceChurnSnapshot() -> PebbleGateBConvergenceChurnSnapshot? {
        guard gateBConvergenceInstrumentationEnabled, let session else { return nil }
        let autonomy = session.autonomousActivitySnapshot()
        let records = autonomy.recentRecords
        let lifetimes = records.map {
            max(0, $0.outcome.completedAtTick - $0.activity.selectedAtTick)
        }
        let lifecycleCounts = Dictionary(
            grouping: records, by: \.outcome.lifecycle
        ).mapValues(\.count)

        var candidateOccurrences: [String: Int] = [:]
        var targetOccurrences: [String: Int] = [:]
        var candidateTargetOccurrences: [String: Int] = [:]
        var lastFamilyByActor: [String: String] = [:]
        var continuations = 0
        var crossFamilySwitches = 0
        var lastFailureSignatureByActor: [String: String] = [:]
        var currentFailureRunByActor: [String: Int] = [:]
        var failureRunStartByActor: [String: Int] = [:]
        var sameObservedFailureRun = 0
        var sameObservedFailureSpan = 0
        var blockingMotif = false
        for record in records {
            let candidate = record.activity.candidate
            let actor = candidate.actorID.rawValue
            candidateOccurrences[
                gateBConvergenceCandidateRestartKey(candidate), default: 0
            ] += 1
            if candidate.target != nil {
                targetOccurrences[
                    gateBConvergenceTargetRestartKey(candidate), default: 0
                ] += 1
            }
            candidateTargetOccurrences[
                gateBConvergenceRestartKey(candidate), default: 0
            ] += 1

            let family = passiveActivityFamily(candidate.domain)
            if let previous = lastFamilyByActor[actor] {
                if previous == family {
                    continuations += 1
                } else {
                    crossFamilySwitches += 1
                }
            }
            lastFamilyByActor[actor] = family

            if record.outcome.lifecycle == .completed {
                lastFailureSignatureByActor.removeValue(forKey: actor)
                currentFailureRunByActor[actor] = 0
                failureRunStartByActor.removeValue(forKey: actor)
            } else {
                let signature = gateBConvergenceFailureSignature(record)
                let unchanged = lastFailureSignatureByActor[actor] == signature
                let run = unchanged
                    ? currentFailureRunByActor[actor, default: 0] + 1 : 1
                if !unchanged {
                    failureRunStartByActor[actor] = record.activity.selectedAtTick
                }
                lastFailureSignatureByActor[actor] = signature
                currentFailureRunByActor[actor] = run
                let span = max(
                    0,
                    record.outcome.completedAtTick
                        - failureRunStartByActor[
                            actor, default: record.activity.selectedAtTick
                        ]
                )
                sameObservedFailureRun = max(
                    sameObservedFailureRun, run
                )
                sameObservedFailureSpan = max(
                    sameObservedFailureSpan, span
                )
                blockingMotif = blockingMotif || (run >= 4 && span >= 32)
            }
        }
        for activity in autonomy.activeActivities {
            candidateOccurrences[
                gateBConvergenceCandidateRestartKey(activity.candidate), default: 0
            ] += 1
            if activity.candidate.target != nil {
                targetOccurrences[
                    gateBConvergenceTargetRestartKey(activity.candidate), default: 0
                ] += 1
            }
            candidateTargetOccurrences[
                gateBConvergenceRestartKey(activity.candidate), default: 0
            ] += 1
        }
        let candidateRestarts = candidateOccurrences.values.reduce(0) {
            $0 + max(0, $1 - 1)
        }
        let targetRestarts = targetOccurrences.values.reduce(0) {
            $0 + max(0, $1 - 1)
        }
        let candidateTargetRestarts = candidateTargetOccurrences.values.reduce(0) {
            $0 + max(0, $1 - 1)
        }
        let blocking = Dictionary(
            grouping: records.filter { $0.outcome.lifecycle == .blocked },
            by: { gateBConvergenceToken($0.outcome.reason) }
        ).mapValues(\.count)
        let blockingReasons = blocking.keys.sorted().map {
            "\($0):\(blocking[$0] ?? 0)"
        }.joined(separator: ",")

        return PebbleGateBConvergenceChurnSnapshot(
            tick: session.tick,
            retained: records.count,
            evicted: autonomy.evictionCount,
            starts: autonomy.counters.startCount,
            completed: autonomy.counters.completionCount,
            blocked: autonomy.counters.blockCount,
            stale: lifecycleCounts[.stale, default: 0],
            interrupted: autonomy.counters.switchCount,
            superseded: records.filter {
                $0.outcome.lifecycle == .interrupted
                    && $0.outcome.reason == "higher-ranked candidate selected"
            }.count,
            sameCandidateRestarts: candidateRestarts,
            sameTargetRestarts: targetRestarts,
            sameCandidateTargetRestarts: candidateTargetRestarts,
            continuations: continuations,
            crossFamilySwitches: crossFamilySwitches,
            lifetimeSamples: lifetimes.count,
            lifetimeMinimum: lifetimes.min() ?? 0,
            lifetimeMaximum: lifetimes.max() ?? 0,
            lifetimeTotal: lifetimes.reduce(0, +),
            sameObservedFailureRun: sameObservedFailureRun,
            sameObservedFailureSpan: sameObservedFailureSpan,
            blocking: blockingMotif,
            blockingReasons: blockingReasons.isEmpty ? "none" : blockingReasons
        )
    }

    func traceGateBConvergenceChurn() {
        guard let snapshot = gateBConvergenceChurnSnapshot() else { return }
        trace("GATE_B_CONVERGENCE_CHURN \(snapshot.tracePayload)")
    }

    /// Proves all collections involved in the soak remain within their product
    /// caps. World entities intentionally expose only an observed count because
    /// PebbleCore has no Civilization-specific global entity cap.
    func traceGateBConvergenceBounds(world: World) {
        guard gateBConvergenceInstrumentationEnabled,
              let session, activeWorld === world else { return }
        let durable = session.durableState()
        let agents = session.snapshot().agents
        let autonomy = session.autonomousActivitySnapshot()
        let work = session.workCommitmentSnapshot()
        let teaching = session.teachingSnapshot()
        let care = session.dependentCareSnapshot()
        let livestock = session.livestockSnapshot()
        let agriculture = session.agricultureSnapshot()
        let ecology = session.localEcologySnapshot()
        let skills = session.skillSnapshot()
        let causal = session.causalLedgerSnapshot().summary
        let food = session.physicalFoodSurvivalSnapshot()

        var pairs: [(String, Int, Int)] = []
        func append(_ name: String, _ count: Int, _ cap: Int) {
            pairs.append((name, count, cap))
        }

        if let configuration = durable.autonomousActivityState?.configuration {
            append(
                "activitiesActive", autonomy.activeActivities.count,
                configuration.maximumActiveActivities
            )
            append(
                "activitiesRetained", autonomy.recentRecords.count,
                configuration.maximumRetainedRecords
            )
            append(
                "activitiesCooldowns", autonomy.cooldowns.count,
                configuration.maximumCooldowns
            )
        } else {
            append("activitiesActive", 0, 0)
            append("activitiesRetained", 0, 0)
            append("activitiesCooldowns", 0, 0)
        }

        if let configuration = work.configuration {
            append("workDemands", work.demands.count, configuration.maximumActiveDemands)
            append(
                "workCommitments", work.commitments.count,
                configuration.maximumRetainedCommitments
            )
            append(
                "workEvidence", work.evidence.count,
                configuration.maximumRetainedEvidence
            )
        } else {
            append("workDemands", 0, 0)
            append("workCommitments", 0, 0)
            append("workEvidence", 0, 0)
        }

        if let configuration = teaching.configuration {
            append(
                "teachingActive",
                teaching.apprenticeships.filter { !$0.status.isTerminal }.count,
                configuration.maximumActiveApprenticeships
            )
            append(
                "teachingApprenticeships", teaching.apprenticeships.count,
                configuration.maximumRetainedApprenticeships
            )
            append(
                "teachingDemonstrations", teaching.demonstrations.count,
                configuration.maximumRetainedDemonstrations
            )
            append(
                "teachingExposures", teaching.exposures.count,
                configuration.maximumRetainedExposures
            )
            append(
                "teachingGuided", teaching.guidedPracticeLinks.count,
                configuration.maximumRetainedGuidedPracticeLinks
            )
        } else {
            append("teachingActive", 0, 0)
            append("teachingApprenticeships", 0, 0)
            append("teachingDemonstrations", 0, 0)
            append("teachingExposures", 0, 0)
            append("teachingGuided", 0, 0)
        }

        if let configuration = care.configuration {
            append("careAssignments", care.assignments.count, configuration.maximumAssignments)
            append("careNeeds", care.activeNeeds.count, configuration.maximumActiveNeeds)
            append(
                "careEngagements", care.activeEngagements.count,
                configuration.maximumActiveEngagements
            )
            append(
                "careOutcomes", care.terminalOutcomes.count,
                configuration.maximumRetainedOutcomes
            )
        } else {
            append("careAssignments", 0, 0)
            append("careNeeds", 0, 0)
            append("careEngagements", 0, 0)
            append("careOutcomes", 0, 0)
        }

        if let state = durable.livestockState {
            let configuration = state.configuration
            append("livestockHerds", livestock.herds.count, configuration.maximumHerds)
            append(
                "livestockAnimals", livestock.managedAnimals.count,
                configuration.maximumHerds * configuration.maximumManagedAnimalsPerHerd
            )
            append(
                "livestockTasks", livestock.activeTasks.count,
                configuration.maximumActiveTasks
            )
            append(
                "livestockReservations", livestock.reservations.count,
                configuration.maximumReservations
            )
            append(
                "livestockRecords", livestock.retainedTaskRecords.count,
                configuration.maximumRetainedTaskRecords
            )
            append(
                "livestockBreeding", livestock.breedingDecisions.count,
                configuration.maximumRetainedBreedingDecisions
            )
            append(
                "livestockProducts", livestock.productRecords.count,
                configuration.maximumRetainedProductRecords
            )
            append(
                "livestockLosses", livestock.lossRecords.count,
                configuration.maximumRetainedLossRecords
            )
        } else {
            append("livestockHerds", 0, 0)
            append("livestockAnimals", 0, 0)
            append("livestockTasks", 0, 0)
            append("livestockReservations", 0, 0)
            append("livestockRecords", 0, 0)
            append("livestockBreeding", 0, 0)
            append("livestockProducts", 0, 0)
            append("livestockLosses", 0, 0)
        }

        if let configuration = agriculture.configuration {
            append("agriculturePlots", agriculture.plots.count, configuration.maximumPlots)
            append(
                "agricultureReservations", agriculture.reservations.count,
                configuration.maximumReservations
            )
            append(
                "agricultureActions", agriculture.retainedActions.count,
                configuration.maximumRetainedActions
            )
            append(
                "agricultureSurplus", agriculture.managedSurplusRecords.count,
                configuration.maximumRetainedSurplusRecords
            )
        } else {
            append("agriculturePlots", 0, 0)
            append("agricultureReservations", 0, 0)
            append("agricultureActions", 0, 0)
            append("agricultureSurplus", 0, 0)
        }

        if let configuration = ecology.configuration {
            append(
                "ecologyPatches", ecology.patches.count,
                configuration.maximumPatches
            )
            append(
                "ecologyForageHistory", ecology.forageHistory.count,
                configuration.maximumForageHistory
            )
            append(
                "ecologyPressureFrames", ecology.pressureFrames.count,
                configuration.maximumPressureFrames
            )
        } else {
            append("ecologyPatches", 0, 0)
            append("ecologyForageHistory", 0, 0)
            append("ecologyPressureFrames", 0, 0)
        }

        if let configuration = skills.configuration {
            append("skillProfiles", skills.profiles.count, configuration.maximumProfiles)
            append(
                "skillRecords", skills.retainedPracticeRecords.count,
                configuration.maximumRetainedPracticeRecords
            )
        } else {
            append("skillProfiles", 0, 0)
            append("skillRecords", 0, 0)
        }

        let causalCap: Int
        switch durable.causalLedger.policy {
        case .disabled: causalCap = 0
        case let .bounded(maxEvents): causalCap = maxEvents
        }
        append("causalRetained", causal.retainedEventCount, causalCap)
        append(
            "physicalFoodIDs", food?.recentConsumptionIDs.count ?? 0,
            food == nil ? 0 : AgentPhysicalFoodSurvivalState.maximumRetainedConsumptionIDs
        )
        append(
            "physicalFoodOutcomes", food?.completedOutcomes.count ?? 0,
            food == nil ? 0 : AgentPhysicalFoodSurvivalState.maximumRetainedOutcomes
        )

        let routes = agents.compactMap(\.navigationProgress.route)
        let maximumRouteSteps = routes.map { max(0, $0.positions.count - 1) }.max() ?? 0
        let standardRouteCap = AgentBoundedRoutePlanner.maximumRouteSteps
        let routeCap = max(
            standardRouteCap,
            durable.populationRegistry?.configuration.maximumRouteLength ?? 0
        )
        let totalWaypoints = routes.reduce(0) {
            $0 + max(0, $1.positions.count - 1)
        }
        append("navigationRoutes", routes.count, agents.count)
        append("navigationMaxRoute", maximumRouteSteps, routeCap)
        append("navigationWaypoints", totalWaypoints, agents.count * routeCap)

        let agentCap = durable.populationRegistry?.configuration.maximumActivePopulation
            ?? agents.count
        append("agents", agents.count, agentCap)

        let valid = pairs.allSatisfy {
            $0.1 >= 0 && $0.2 >= 0 && $0.1 <= $0.2
        }
        let payload = pairs.map { "\($0.0)=\($0.1)/\($0.2)" }
            .joined(separator: " ")
        trace(
            "GATE_B_CONVERGENCE_BOUNDS valid=\(valid ? 1 : 0) "
                + "\(payload) worldEntities=\(world.entities.count)"
        )
    }

    /// A strict, read-only session-to-World reconciliation check for the
    /// checkpoint boundary. It neither repairs mappings nor rebuilds probes.
    func liveBindingsReconciled(world: World) -> Bool {
        guard gateBConvergenceInstrumentationEnabled,
              let session, activeWorld === world else { return false }
        let agents = session.snapshot().agents.sorted { $0.id < $1.id }
        let ids = agents.map(\.id)
        let worldProbeIDs = world.entities.compactMap {
            ($0 as? LabCoreAgentEntity)?.labAgentId
        }.sorted()
        guard ids == probesByAgentId.keys.sorted(),
              worldProbeIDs == ids,
              let embodiments = try? PebbleAgentEmbodiment.resolveAll(
                agentIDs: ids, in: world, mappedByAgentID: probesByAgentId
              ) else {
            return false
        }
        return agents.allSatisfy {
            embodiments[$0.id]?.position == $0.position
        }
    }

    /// Captures every physical custody holder in the bounded convergence
    /// fixture plus every loose ItemEntity. Runtime entity IDs are evidence
    /// only; Civilization AgentID remains the stable identity.
    func gateBConvergenceCustodySnapshot(
        world: World
    ) throws -> PebbleGateBConvergenceCustodySnapshot? {
        guard gateBConvergenceInstrumentationEnabled else { return nil }
        guard let session, activeWorld === world else {
            throw ControllerError.feedbackBoundary(
                "Gate B convergence custody snapshot requires the active session World"
            )
        }
        let agentIDs = session.snapshot().agents.map(\.id).sorted()
        let embodiments = try PebbleAgentEmbodiment.resolveAll(
            agentIDs: agentIDs,
            in: world,
            mappedByAgentID: probesByAgentId
        )
        let bridge = PebbleAgentMaterialSnapshotBridge()
        let agents = try agentIDs.map { agentID in
            try materialCustodyGateway.inspect(
                .liveAgent(embodiments[agentID]!, in: world)
            )
        }
        let containers: [AgentMaterialCustodySnapshot]
        if let fixture = passiveSocietyFixture {
            containers = [try materialCustodyGateway.inspect(
                .container(fixture.container, in: world)
            )]
        } else {
            containers = []
        }
        let loose: [PebbleGateBConvergenceLooseItemProjection] =
            try world.entities.compactMap { entity in
            guard let item = entity as? ItemEntity, !item.dead else { return nil }
            return PebbleGateBConvergenceLooseItemProjection(
                runtimeEntityID: item.id,
                xBits: item.x.bitPattern,
                yBits: item.y.bitPattern,
                zBits: item.z.bitPattern,
                stack: try bridge.snapshot(of: item.stack)
            )
        }.sorted { $0.runtimeEntityID < $1.runtimeEntityID }
        let bindings = agentIDs.map { agentID in
            let probe = embodiments[agentID]!.probe
            return PebbleGateBConvergenceProbeBindingProjection(
                agentID: agentID,
                runtimeEntityID: probe.id,
                physicalID: probe.physicalId
            )
        }
        let agentFingerprints = try agents.map { custody in
            let digest = try gateBConvergenceDigest(custody)
            return "\(custody.locationID):\(digest)"
        }.joined(separator: ",")
        let containerFingerprints = try containers.map { custody in
            let digest = try gateBConvergenceDigest(custody)
            return "\(custody.locationID):\(digest)"
        }.joined(separator: ",")
        var totals: [String: Int] = [:]
        func accumulate(_ stack: AgentMaterialStackSnapshot) {
            totals[stack.identity.itemKey, default: 0] += stack.count
        }
        for custody in agents + containers {
            for stack in custody.slots.compactMap({ $0 }) {
                accumulate(stack)
            }
        }
        for item in loose {
            accumulate(item.stack)
        }
        let materialTotals = totals.keys.sorted().map {
            "\($0):\(totals[$0]!)"
        }.joined(separator: ",")
        let agentQuantity = agents.reduce(0) { partial, custody in
            partial + custody.slots.compactMap({ $0 }).reduce(0) {
                $0 + $1.count
            }
        }
        let containerQuantity = containers.reduce(0) { partial, custody in
            partial + custody.slots.compactMap({ $0 }).reduce(0) {
                $0 + $1.count
            }
        }
        let looseQuantity = loose.reduce(0) { $0 + $1.stack.count }
        let agentInventories = try gateBConvergenceBase64(agents)
        let containerInventories = try gateBConvergenceBase64(containers)
        let looseItemEntities = try gateBConvergenceBase64(loose)
        let probeRuntimeBindings = try gateBConvergenceBase64(bindings)
        let worldEntityIDs = world.entities.map {
            "\($0.id):\(($0 as? Entity)?.type ?? String(describing: type(of: $0)))"
        }.sorted().joined(separator: ",")
        let durable = try session.durableStateDigest().rawValue
        let canonical = [
            durable,
            agentIDs.joined(separator: ","),
            probeRuntimeBindings,
            worldEntityIDs,
            agentInventories,
            containerInventories,
            looseItemEntities,
            materialTotals,
        ].joined(separator: "|")
        return PebbleGateBConvergenceCustodySnapshot(
            tick: session.tick,
            durable: durable,
            civilizationAgentIDs: agentIDs.joined(separator: ","),
            probeRuntimeBindings: probeRuntimeBindings,
            worldEntityIDs: worldEntityIDs,
            agentInventories: agentInventories,
            containerInventories: containerInventories,
            looseItemEntities: looseItemEntities,
            agentFingerprints: agentFingerprints.isEmpty ? "none" : agentFingerprints,
            containerFingerprints: (
                containerFingerprints.isEmpty ? "none" : containerFingerprints
            ),
            materialTotals: materialTotals.isEmpty ? "none" : materialTotals,
            agentMaterialQuantity: agentQuantity,
            containerMaterialQuantity: containerQuantity,
            looseMaterialQuantity: looseQuantity,
            trackedCustodyDigest: gateBConvergenceDigest(canonical)
        )
    }

    func traceGateBConvergenceCustody(
        phase: String,
        world: World
    ) -> PebbleGateBConvergenceCustodySnapshot? {
        do {
            guard let snapshot = try gateBConvergenceCustodySnapshot(world: world) else {
                return nil
            }
            trace(
                "GATE_B_CONVERGENCE_CUSTODY phase=\(gateBConvergenceToken(phase)) "
                    + snapshot.tracePayload
            )
            return snapshot
        } catch {
            trace(
                "GATE_B_CONVERGENCE_CUSTODY_ERROR "
                    + "phase=\(gateBConvergenceToken(phase)) "
                    + "reason=\(gateBConvergenceToken(String(describing: error)))"
            )
            return nil
        }
    }

    /// Convenience entry point for final-horizon evidence. Checkpoint callers
    /// can use `gateBConvergenceSemanticSnapshot` directly before and after
    /// loading so equality is tested without emitting an intermediate state.
    @discardableResult
    func traceGateBConvergenceEvidence(
        world: World
    ) -> PebbleGateBConvergenceSemanticSnapshot? {
        guard gateBConvergenceInstrumentationEnabled else { return nil }
        do {
            let semantic = try traceGateBConvergenceSemantic(world: world)
            traceGateBConvergenceChurn()
            traceGateBConvergenceBounds(world: world)
            return semantic
        } catch {
            trace(
                "GATE_B_CONVERGENCE_EVIDENCE_ERROR reason="
                    + gateBConvergenceToken(String(describing: error))
            )
            return nil
        }
    }

    private func gateBConvergenceMaterialCustody(
        agentIDs: [String],
        world: World
    ) throws -> [AgentMaterialCustodySnapshot] {
        let embodiments = try PebbleAgentEmbodiment.resolveAll(
            agentIDs: agentIDs, in: world, mappedByAgentID: probesByAgentId
        )
        var snapshots = try agentIDs.sorted().map { id in
            try materialCustodyGateway.inspect(
                .liveAgent(embodiments[id]!, in: world)
            )
        }
        if let fixture = passiveSocietyFixture {
            snapshots.append(try materialCustodyGateway.inspect(
                .container(fixture.container, in: world)
            ))
        }
        return snapshots.sorted { $0.locationID < $1.locationID }
    }

    private func gateBConvergenceFoodCanonical(
        session: AgentSimulationSession,
        agents: [AgentSnapshot],
        custody: [AgentMaterialCustodySnapshot]
    ) throws -> String {
        let logical = try AgentCheckpointCodec.encode(
            session.physicalFoodSurvivalSnapshot()
        )
        let needs = try AgentCheckpointCodec.encode(agents.map {
            PebbleGateBConvergenceFoodAgentProjection(
                id: $0.id, hunger: $0.needs.hunger, health: $0.health,
                survival: $0.survivalProgress
            )
        })
        let physicalFood = try AgentCheckpointCodec.encode(custody.map { location in
            AgentMaterialCustodySnapshot(
                locationID: location.locationID,
                slots: location.slots.map { stack in
                    guard let stack, let itemID = iidOpt(stack.identity.itemKey),
                          itemDef(itemID).food != nil else { return nil }
                    return stack
                }
            )
        })
        return String(decoding: logical, as: UTF8.self)
            + "|" + String(decoding: needs, as: UTF8.self)
            + "|" + String(decoding: physicalFood, as: UTF8.self)
    }

    private func gateBConvergenceWorldEntityDigest(world: World) throws -> String {
        let bridge = PebbleAgentMaterialSnapshotBridge()
        let projections = try world.entities.map { entity in
            let concrete = entity as? Entity
            var values = [
                concrete?.type ?? String(describing: type(of: entity)),
                String(entity.x.bitPattern, radix: 16),
                String(entity.y.bitPattern, radix: 16),
                String(entity.z.bitPattern, radix: 16),
                entity.dead ? "1" : "0",
                concrete?.persistent == true ? "1" : "0",
            ]
            if let living = entity as? LivingEntity {
                values.append(String(living.health.bitPattern, radix: 16))
            }
            if let item = entity as? ItemEntity {
                let snapshot = try bridge.snapshot(of: item.stack)
                values.append(String(
                    decoding: try AgentCheckpointCodec.encode(snapshot),
                    as: UTF8.self
                ))
            }
            if let probe = entity as? LabCoreAgentEntity {
                values.append(probe.labAgentId)
                values.append(probe.physicalId)
            }
            if let mob = entity as? Mob {
                values.append(mob.baby ? "baby" : "adult")
                values.append("\(mob.growUpAge)")
                values.append("\(mob.loveTicks)")
                values.append("\(mob.breedCooldown)")
            }
            if let sheep = entity as? Sheep {
                values.append(sheep.sheared ? "sheared" : "wool")
                values.append("color=\(sheep.color)")
            }
            return values.joined(separator: "|")
        }
        let fixtureCells = passiveSocietyFixture?.originalCells.map {
            "cell|\($0.position.x)|\($0.position.y)|\($0.position.z)|"
                + "\(world.getBlock($0.position.x, $0.position.y, $0.position.z))"
        } ?? []
        let canonical = (projections + fixtureCells).sorted().joined(separator: ";")
        return gateBConvergenceDigest(canonical)
    }

    private func gateBConvergenceRestartKey(
        _ candidate: AgentAutonomousActivityCandidate
    ) -> String {
        let target = candidate.target.map(gateBConvergencePosition) ?? "none"
        return "\(candidate.actorID.rawValue)|\(candidate.candidateID)|\(target)"
    }

    private func gateBConvergenceCandidateRestartKey(
        _ candidate: AgentAutonomousActivityCandidate
    ) -> String {
        "\(candidate.actorID.rawValue)|\(candidate.candidateID)"
    }

    private func gateBConvergenceTargetRestartKey(
        _ candidate: AgentAutonomousActivityCandidate
    ) -> String {
        "\(candidate.actorID.rawValue)|"
            + "\(candidate.target.map(gateBConvergencePosition) ?? "none")"
    }

    private func gateBConvergenceFailureSignature(
        _ record: AgentAutonomousActivityRecord
    ) -> String {
        gateBConvergenceRestartKey(record.activity.candidate)
            + "|observation=\(record.activity.candidate.observedAtTick)"
            + "|\(record.outcome.lifecycle.rawValue)|\(record.outcome.reason)"
    }

    private func gateBConvergencePosition(_ position: AgentPosition) -> String {
        "\(position.x),\(position.y),\(position.z)"
    }

    private func gateBConvergenceToken(_ value: String) -> String {
        let normalized = value.lowercased().map {
            $0.isASCII && ($0.isLetter || $0.isNumber || "-_.".contains($0))
                ? $0 : "_"
        }
        let collapsed = String(normalized).replacingOccurrences(
            of: "__+", with: "_", options: .regularExpression
        )
        return String(collapsed.prefix(120))
    }

    private func gateBConvergenceDigest<T: Encodable>(
        _ value: T
    ) throws -> String {
        AgentCheckpointDigest.sha256(
            try AgentCheckpointCodec.encode(value)
        ).rawValue
    }

    private func gateBConvergenceDigest(_ value: String) -> String {
        AgentCheckpointDigest.sha256(Data(value.utf8)).rawValue
    }

    private func gateBConvergenceBase64<T: Encodable>(
        _ value: T
    ) throws -> String {
        try AgentCheckpointCodec.encode(value).base64EncodedString()
    }
}
