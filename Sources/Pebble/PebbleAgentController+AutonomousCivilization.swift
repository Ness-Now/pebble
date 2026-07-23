import PebbleAgents
import PebbleCore

/// Read-only, process-local evidence for the work-demand reconciliation seam.
/// These counters never participate in decisions, replay, or checkpoint state.
struct PebbleAgentWorkDemandRefreshAudit {
    var attempts = 0
    var sameProvenanceHeartbeats = 0
    var meaningfulRefreshes = 0
    var newLogicalDemands = 0
    var withdrawals = 0
    var reactivations = 0
    var commitmentsPreserved = 0
    var workDemandRefreshedEvents = 0
    var actualIdentityRejections = 0
    var staleProvenanceRejections = 0
}

extension PebbleAgentController {
    func handleAutonomousCivilization(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab autonomous-civilization <on|off|status|passive>"
        guard arguments.count == 1, let command = arguments.first?.lowercased() else {
            return failure(usage)
        }
        guard autonomousCivilizationFeatureEnabled else {
            return failure(
                "Autonomous Civilization disabled. Set "
                    + "PEBBLELAB_APP_AGENTS_AUTONOMOUS_CIVILIZATION=1 before launch."
            )
        }
        guard var candidate = session, activeWorld === world else {
            return failure("No active PebbleAgents session.")
        }
        do {
            var recorder = replayRecorder
            switch command {
            case "on", "passive":
                if command == "passive" {
                    try preparePassiveSocietySlice(
                        world: world, session: &candidate, recorder: &recorder
                    )
                }
                if !candidate.autonomousActivityEnabled {
                    if try applyRecordedOperationIfActive(
                        .setAutonomousActivityEnabled(true, configuration: .live),
                        session: &candidate, recorder: &recorder
                    ) == nil {
                        try candidate.setAutonomousActivityEnabled(true)
                    }
                }
                movementEnabled = true
                movementWasEverEnabledSinceReset = true
                followMode = .off
                demoActive = false
                passiveObserverBootstrapComplete = command == "passive"
                if passiveObserverBootstrapComplete {
                    manualProductiveCommandsAfterBootstrap = 0
                    if environment["PEBBLELAB_GATE_B3_ACCEPTANCE"] == "1" {
                        trace(
                            "GATE_B_BOOTSTRAP_COMPLETE tick=\(candidate.tick) agents="
                                + "\(candidate.snapshot().agentCount) productiveCommandsAfter=0"
                        )
                    }
                    trace(
                        "PLAYABLE_SLICE_BOOTSTRAP_COMPLETE tick=\(candidate.tick) agents="
                            + "\(candidate.snapshot().agentCount) follow=off productiveCommandsAfter=0"
                    )
                }
            case "off":
                if candidate.autonomousActivitySnapshot().activeActivities.isEmpty {
                    if try applyRecordedOperationIfActive(
                        .setAutonomousActivityEnabled(false, configuration: .live),
                        session: &candidate, recorder: &recorder
                    ) == nil {
                        try candidate.setAutonomousActivityEnabled(false)
                    }
                } else {
                    return failure("Autonomous Civilization has active activities.")
                }
                passiveObserverBootstrapComplete = false
            case "status": break
            default: return failure(usage)
            }
            session = candidate
            replayRecorder = recorder
            let state = candidate.autonomousActivitySnapshot()
            let counters = state.counters
            let completed = state.recentRecords.filter {
                $0.outcome.lifecycle == .completed
            }
            let activeAgents = Set(completed.map { $0.activity.candidate.actorID }).count
            let domains = Set(completed.map { $0.activity.candidate.domain.rawValue })
                .sorted().joined(separator: ",")
            return success(
                "Autonomous Civilization \(state.enabled ? "on" : "off") "
                    + "active=\(state.activeActivities.count) records=\(state.recentRecords.count) "
                    + "decisions=\(counters.decisionCount) candidates=\(counters.candidateCount) "
                    + "starts=\(counters.startCount) completed=\(counters.completionCount) "
                    + "blocked=\(counters.blockCount) switches=\(counters.switchCount) "
                    + "manualProductive=\(manualProductiveCommandsAfterBootstrap) "
                    + "completedAgents=\(activeAgents) domains=\(domains.isEmpty ? "none" : domains) "
                    + "idleLongest=\(counters.longestIdleTicks) "
                    + "bootstrap=\(passiveObserverBootstrapComplete ? "complete" : "pending") "
                    + "follow=\(followMode.statusText)."
            )
        } catch {
            return failure("Autonomous Civilization command failed: \(error)")
        }
    }

    func prepareAutonomousCivilizationDecision(
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws {
        guard session.autonomousActivityEnabled else { return }
        if session.workCommitmentsEnabled,
           let configuration = session.workCommitmentSnapshot().configuration,
           session.tick % configuration.reviewIntervalTicks == 0 {
            let before = session.workCommitmentSnapshot()
            let causalSequenceBefore = session.causalLedgerSnapshot().summary.latestSequence
            workDemandRefreshAudit.attempts += 1
            do {
                try applyLiveWorkOperation(.refreshDemands, to: &session, recorder: &recorder)
            } catch {
                let description = String(describing: error)
                if description.contains("demand logical identity changed") {
                    workDemandRefreshAudit.actualIdentityRejections += 1
                }
                if description.contains("stale demand causal provenance") {
                    workDemandRefreshAudit.staleProvenanceRejections += 1
                }
                traceWorkDemandRefreshFailure(error: description, tick: session.tick)
                throw error
            }
            recordWorkDemandRefresh(
                before: before,
                after: session.workCommitmentSnapshot(),
                causalSequenceBefore: causalSequenceBefore,
                causalSequenceAfter: session.causalLedgerSnapshot().summary.latestSequence,
                tick: session.tick
            )
            try applyLiveWorkOperation(.review, to: &session, recorder: &recorder)
            for suspended in session.activeWorkCommitments().filter({
                $0.status == .suspended && $0.suspensionReason == .crisis
            }) {
                guard let demand = session.activeWorkDemands().first(where: {
                    $0.demandID == suspended.demandID
                }) else { continue }
                let replacements = liveWorkCandidateContexts(
                    demand: demand, session: session, world: world
                ).filter { $0.agentID != suspended.workerID }
                guard replacements.contains(where: {
                    $0.capable && $0.physicallyAvailable && $0.toolsAvailable
                        && $0.resourcesAvailable
                }) else { continue }
                try applyLiveWorkOperation(
                    .replace(
                        commitmentID: suspended.commitmentID,
                        candidates: replacements
                    ),
                    to: &session, recorder: &recorder
                )
            }
            for demand in session.activeWorkDemands() where
                !session.activeWorkCommitments().contains(where: {
                    $0.demandID == demand.demandID
                }) {
                let contexts = liveWorkCandidateContexts(
                    demand: demand, session: session, world: world
                )
                guard contexts.contains(where: {
                    $0.capable && $0.physicallyAvailable && $0.toolsAvailable
                        && $0.resourcesAvailable
                }) else { continue }
                try applyLiveWorkOperation(
                    .start(
                        demandID: demand.demandID,
                        candidates: contexts
                    ),
                    to: &session, recorder: &recorder
                )
            }
        }
        if session.wildSubsistenceEnabled {
            for agent in session.snapshot().agents.sorted(by: { $0.id < $1.id }) {
                guard let actorID = AgentID(rawValue: agent.id),
                      !session.wildSubsistenceSnapshot().opportunities.contains(where: {
                          $0.actorID == actorID && $0.status == .selected
                              && $0.expiresAtTick >= session.tick
                      }), let probe = probesByAgentId[agent.id], probe.world === world,
                      !probe.dead else { continue }
                let itemNames = probe.carriedItems.compactMap { stack in
                    stack.map { itemDef($0.id).name }
                }
                let context = AgentSubsistenceDecisionContext(
                    actorID: actorID,
                    fishingRodAvailable: itemNames.contains("fishing_rod"),
                    huntingWeaponAvailable: itemNames.contains { $0.hasSuffix("_sword") },
                    // Agriculture is exposed below from its canonical plot intent.
                    // Wild Subsistence must not create a second agricultural receipt path.
                    agricultureAvailable: false,
                    maximumDistance: 16,
                    subsistencePressure: max(0, min(100, Int(agent.needs.hunger * 100)))
                )
                guard let eligible = try? session.eligibleSubsistenceStrategies(context),
                      !eligible.isEmpty else { continue }
                if try applyRecordedOperationIfActive(
                    .selectWildSubsistenceOpportunity(context),
                    session: &session, recorder: &recorder
                ) == nil { _ = try session.selectWildSubsistenceOpportunity(context) }
            }
        }
        let snapshot = session.snapshot()
        var candidates: [AgentAutonomousActivityCandidate] = []
        let currentByActor = Dictionary(uniqueKeysWithValues:
            session.autonomousActivitySnapshot().activeActivities.map {
                ($0.candidate.actorID, $0.candidate.candidateID)
            }
        )
        func distance(_ a: AgentPosition, _ b: AgentPosition) -> Int {
            abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z)
        }
        func commitment(
            _ actorID: AgentID, domains: Set<AgentSkillDomain>
        ) -> AgentWorkCommitment? {
            session.activeWorkCommitments(for: actorID).first {
                $0.status == .active && domains.contains($0.domain)
            }
        }
        for agent in snapshot.agents.sorted(by: { $0.id < $1.id }) {
            guard let actorID = AgentID(rawValue: agent.id) else { continue }
            if let intent = session.nextAgriculturalIntent(for: actorID),
               session.agricultureSnapshot().plots.first(where: {
                   $0.plotID == intent.plotID
               })?.plannerID == actorID {
                let id = "agriculture:\(actorID.rawValue):\(intent.plotID.rawValue):"
                    + "\(intent.cellIndex ?? -1):\(intent.kind.rawValue)"
                let work = commitment(actorID, domains: [.cultivation])
                let target = intent.kind == .store
                    ? agricultureStoragePosition(for: intent.plotID, session: session) ?? intent.position
                    : AgentPosition(
                        x: intent.position.x, y: intent.position.y + 1,
                        z: intent.position.z
                    )
                candidates.append(AgentAutonomousActivityCandidate(
                    candidateID: id, actorID: actorID, domain: .agriculture,
                    actionKey: intent.kind.rawValue, stableReference: intent.plotID.rawValue,
                    target: target, source: work == nil ? .opportunity : .commitment,
                    priorityBand: work == nil ? 30 : 20, urgency: work == nil ? 62 : 76,
                    continuity: currentByActor[actorID] == id,
                    distance: distance(agent.position, target),
                    commitmentID: work?.commitmentID, observedAtTick: session.tick
                ))
            }
        }
        for opportunity in session.wildSubsistenceSnapshot().opportunities where
            opportunity.status == .selected && opportunity.expiresAtTick >= session.tick {
            guard let agent = snapshot.agents.first(where: {
                $0.id == opportunity.actorID.rawValue
            }) else { continue }
            let domain: AgentAutonomousActivityDomain
            let workDomains: Set<AgentSkillDomain>
            switch opportunity.strategy {
            case .fishing: domain = .fishing; workDomains = [.fishing]
            case .hunting: domain = .hunting; workDomains = [.hunting]
            case .wildGathering: domain = .wildGathering; workDomains = [.foraging]
            case .agriculture: domain = .agriculture; workDomains = [.cultivation]
            }
            let work = commitment(opportunity.actorID, domains: workDomains)
            let id = "subsistence:\(opportunity.opportunityID.rawValue)"
            let navigationTarget = AgentPosition(
                x: opportunity.lastObservedPosition.x,
                y: opportunity.lastObservedPosition.y < agent.position.y
                    ? opportunity.lastObservedPosition.y + 1
                    : opportunity.lastObservedPosition.y,
                z: opportunity.lastObservedPosition.z
            )
            candidates.append(AgentAutonomousActivityCandidate(
                candidateID: id, actorID: opportunity.actorID, domain: domain,
                actionKey: opportunity.strategy.rawValue,
                stableReference: opportunity.opportunityID.rawValue,
                target: navigationTarget,
                source: work == nil ? .opportunity : .commitment,
                priorityBand: work == nil ? 35 : 20,
                urgency: max(50, min(90, opportunity.score)),
                continuity: currentByActor[opportunity.actorID] == id,
                distance: distance(agent.position, navigationTarget),
                commitmentID: work?.commitmentID, observedAtTick: session.tick
            ))
        }
        for task in session.livestockSnapshot().activeTasks where
            !task.status.terminal && task.expiresAtTick >= session.tick {
            guard let agent = snapshot.agents.first(where: {
                $0.id == task.responsibleAgentID.rawValue
            }) else { continue }
            let work = commitment(task.responsibleAgentID, domains: [.husbandry])
            let id = "livestock:\(task.taskID.rawValue)"
            candidates.append(AgentAutonomousActivityCandidate(
                candidateID: id, actorID: task.responsibleAgentID, domain: .livestock,
                actionKey: task.kind.rawValue, stableReference: task.taskID.rawValue,
                target: task.targetPosition,
                source: work == nil ? .responsibility : .commitment,
                priorityBand: work == nil ? 25 : 20, urgency: 72,
                continuity: currentByActor[task.responsibleAgentID] == id,
                distance: distance(agent.position, task.targetPosition),
                commitmentID: work?.commitmentID, observedAtTick: session.tick
            ))
        }
        if try applyRecordedOperationIfActive(
            .selectAutonomousActivities(candidates),
            session: &session, recorder: &recorder
        ) == nil {
            _ = try session.selectAutonomousActivities(candidates)
        }
        if session.teachingEnabled {
            let review = session.autonomousTeachingReviewSnapshot()
            if review.cadenceDue {
                trace(
                    "autonomous teaching review tick=\(review.reviewedAtTick) "
                        + "opportunities=\(review.opportunitiesConsidered) "
                        + "requests=\(review.requestsAttempted) accepted=\(review.accepted) "
                        + "refusedStudent=\(review.refusedStudent) "
                        + "refusedTeacher=\(review.refusedTeacher) "
                        + "noMentor=\(review.noMentor) started=\(review.started) "
                        + "active=\(review.active) ended=\(review.ended) "
                        + "manualSelectMentorCalls=0"
                )
                for attempt in review.attempts where attempt.disposition == .started {
                    guard let apprenticeshipID = attempt.apprenticeshipID,
                          let engagement = session.teachingSnapshot().apprenticeships.first(
                            where: { $0.apprenticeshipID == apprenticeshipID }
                          ) else { continue }
                    let studentReason = attempt.studentDecision.refusalReason?.rawValue
                        ?? "accept"
                    let teacherReason = attempt.teacherDecisions.first(where: {
                        $0.participantID == engagement.teacherID
                    })?.refusalReason?.rawValue ?? "accept"
                    let studentPractice = session.practiceUnits(
                        agentID: engagement.studentID,
                        domain: engagement.domain
                    )
                    trace(
                        "autonomous apprenticeship started id=\(apprenticeshipID.rawValue) "
                            + "teacher=\(engagement.teacherID.rawValue) "
                            + "student=\(engagement.studentID.rawValue) "
                            + "domain=\(engagement.domain.rawValue) "
                            + "teacherPractice=\(engagement.teacherPracticeUnitsAtSelection) "
                            + "studentPractice=\(studentPractice) "
                            + "distance=\(engagement.distanceAtSelection) "
                            + "studentDecision=\(studentReason) teacherDecision=\(teacherReason) "
                            + "reason=\(attempt.opportunity.reason.rawValue) "
                            + "manualInitiation=0"
                    )
                }
            }
        }
        recordPassiveSocietyDecisionAudit(candidates: candidates, session: session)
    }

    private func workDemandProjectionChanged(
        _ previous: AgentWorkDemandSignal,
        _ current: AgentWorkDemandSignal
    ) -> Bool {
        previous.observerID != current.observerID
            || previous.suggestedWorkerID != current.suggestedWorkerID
            || previous.targetPosition != current.targetPosition
            || previous.requiredToolKeys != current.requiredToolKeys
            || previous.requiredResourceKeys != current.requiredResourceKeys
            || previous.urgency != current.urgency
            || previous.quantity != current.quantity
            || previous.cadenceTicks != current.cadenceTicks
    }

    private func recordWorkDemandRefresh(
        before: AgentWorkCommitmentSnapshot,
        after: AgentWorkCommitmentSnapshot,
        causalSequenceBefore: UInt64,
        causalSequenceAfter: UInt64,
        tick: Int
    ) {
        let beforeByID = Dictionary(uniqueKeysWithValues: before.demands.map {
            ($0.demandID, $0)
        })
        let afterByID = Dictionary(uniqueKeysWithValues: after.demands.map {
            ($0.demandID, $0)
        })
        let created = after.demands.filter { beforeByID[$0.demandID] == nil }
        let withdrawn = before.demands.filter { demand in
            demand.status.isActive
                && afterByID[demand.demandID]?.status == .withdrawn
        }
        var heartbeats = 0
        var meaningful = 0
        var reactivations = 0
        for current in after.demands.sorted(by: { $0.demandID < $1.demandID }) {
            guard let previous = beforeByID[current.demandID] else { continue }
            let provenanceAdvanced =
                current.sourceEventID.sequence > previous.sourceEventID.sequence
            let reactivated = !previous.status.isActive && current.status.isActive
            if provenanceAdvanced
                || workDemandProjectionChanged(previous, current)
                || reactivated {
                meaningful += 1
                if reactivated { reactivations += 1 }
                traceWorkDemandRefreshDetail(
                    previous: previous,
                    current: current,
                    reactivated: reactivated
                )
            } else if current.status.isActive {
                heartbeats += 1
            }
        }
        let preserved = before.commitments.filter { commitment in
            commitment.status.isOpen
                && after.commitments.contains {
                    $0.commitmentID == commitment.commitmentID
                        && $0.demandID == commitment.demandID
                        && $0.workerID == commitment.workerID
                        && $0.status == commitment.status
                }
        }.count
        let causalDelta = Int(causalSequenceAfter - causalSequenceBefore)
        workDemandRefreshAudit.sameProvenanceHeartbeats += heartbeats
        workDemandRefreshAudit.meaningfulRefreshes += meaningful
        workDemandRefreshAudit.newLogicalDemands += created.count
        workDemandRefreshAudit.withdrawals += withdrawn.count
        workDemandRefreshAudit.reactivations += reactivations
        workDemandRefreshAudit.commitmentsPreserved += preserved
        workDemandRefreshAudit.workDemandRefreshedEvents += causalDelta
        guard workDemandRefreshProofEnabled else { return }
        trace(
            "work demand refresh tick=\(tick) "
                + "attempt=\(workDemandRefreshAudit.attempts) "
                + "heartbeat=\(heartbeats) meaningful=\(meaningful) "
                + "new=\(created.count) withdrawn=\(withdrawn.count) "
                + "reactivated=\(reactivations) commitmentsPreserved=\(preserved) "
                + "events=\(causalDelta) totalDemands=\(before.totalDemandCount)"
                + ">\(after.totalDemandCount) retained=\(after.demands.count) "
                + "runtimeErrors=\(runtimeErrorCount)"
        )
    }

    private var workDemandRefreshProofEnabled: Bool {
        environment["PEBBLELAB_WORK_DEMAND_REFRESH_PROOF"] == "1"
    }

    private func traceWorkDemandRefreshDetail(
        previous: AgentWorkDemandSignal,
        current: AgentWorkDemandSignal,
        reactivated: Bool
    ) {
        guard workDemandRefreshProofEnabled else { return }
        trace(
            "work demand reconciled demand=\(current.demandID.rawValue) "
                + "source=\(current.source.rawValue) sourceKey=\(current.sourceKey) "
                + "domain=\(current.domain.rawValue) "
                + "oldSource=\(previous.sourceEventID.rawValue) "
                + "newSource=\(current.sourceEventID.rawValue) "
                + "createdAt=\(current.createdAtTick) "
                + "refreshedAt=\(current.refreshedAtTick) "
                + "reactivated=\(reactivated ? 1 : 0)"
        )
    }

    private func traceWorkDemandRefreshFailure(error: String, tick: Int) {
        guard workDemandRefreshProofEnabled else { return }
        trace(
            "work demand refresh rejected tick=\(tick) "
                + "identityRejects=\(workDemandRefreshAudit.actualIdentityRejections) "
                + "staleRejects=\(workDemandRefreshAudit.staleProvenanceRejections) "
                + "error=\(error.replacingOccurrences(of: " ", with: "_"))"
        )
    }

    private func agricultureStoragePosition(
        for plotID: AgentAgriculturalPlotID,
        session: AgentSimulationSession
    ) -> AgentPosition? {
        guard let raw = session.agricultureSnapshot().plots.first(where: {
            $0.plotID == plotID
        })?.designatedStorageLocationID.split(separator: ":").last else { return nil }
        let values = raw.split(separator: ",").compactMap { Int($0) }
        guard values.count == 3 else { return nil }
        return AgentPosition(x: values[0], y: values[1], z: values[2])
    }
}
