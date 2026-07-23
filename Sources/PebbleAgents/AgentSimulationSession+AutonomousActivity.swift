extension AgentSimulationSession {
    public var autonomousActivityEnabled: Bool { autonomousActivityState != nil }

    public func autonomousActivitySnapshot() -> AgentAutonomousActivitySnapshot {
        guard let state = autonomousActivityState else {
            return AgentAutonomousActivitySnapshot(
                enabled: false, activeActivities: [], recentRecords: [], cooldowns: [],
                counters: AgentAutonomousActivityCounters(), evictionCount: 0
            )
        }
        return AgentAutonomousActivitySnapshot(
            enabled: true,
            activeActivities: state.activeActivities.sorted(by: activitySort),
            recentRecords: state.recentRecords,
            cooldowns: state.cooldowns.sorted(by: cooldownSort),
            counters: state.counters,
            evictionCount: state.evictionCount
        )
    }

    public func activeAutonomousActivity(for actorID: AgentID) -> AgentAutonomousActivity? {
        autonomousActivityState?.activeActivities.first { $0.candidate.actorID == actorID }
    }

    public mutating func setAutonomousActivityEnabled(
        _ enabled: Bool,
        configuration: AgentAutonomousActivityConfiguration = .live
    ) throws {
        if enabled {
            if autonomousActivityState == nil {
                autonomousActivityState = AgentAutonomousActivityState(configuration: configuration)
                recordFeatureToggle(name: "autonomousActivity", enabled: true)
            }
            return
        }
        guard autonomousActivityState?.activeActivities.isEmpty != false else {
            throw AgentSessionError.autonomousActivity(.invalidCandidate("active work must end first"))
        }
        if autonomousActivityState != nil {
            autonomousActivityState = nil
            recordFeatureToggle(name: "autonomousActivity", enabled: false)
        }
    }

    /// Selects at most one physical intent per actor from bounded, externally
    /// observed candidates. Ranking is explicit and deterministic; this is not
    /// a second scheduler and it never executes a physical operation.
    @discardableResult
    public mutating func selectAutonomousActivities(
        _ candidates: [AgentAutonomousActivityCandidate]
    ) throws -> [AgentAutonomousActivity] {
        var candidateSession = self
        let selected = try candidateSession.selectAutonomousActivitiesInPlace(candidates)
        self = candidateSession
        return selected
    }

    private mutating func selectAutonomousActivitiesInPlace(
        _ candidates: [AgentAutonomousActivityCandidate]
    ) throws -> [AgentAutonomousActivity] {
        guard var state = autonomousActivityState else {
            throw AgentSessionError.autonomousActivity(.disabled)
        }
        guard candidates.count <= state.configuration.maximumCandidatesPerDecision else {
            throw AgentSessionError.autonomousActivity(.candidateLimitReached)
        }
        guard Set(candidates.map(\.candidateID)).count == candidates.count else {
            throw AgentSessionError.autonomousActivity(.invalidCandidate("duplicate candidate ID"))
        }
        for candidate in candidates {
            guard statesById[candidate.actorID.rawValue] != nil else {
                throw AgentSessionError.autonomousActivity(.unknownAgent(candidate.actorID))
            }
            guard !candidate.candidateID.isEmpty, !candidate.actionKey.isEmpty,
                  !candidate.stableReference.isEmpty,
                  candidate.observedAtTick <= tick + 1 else {
                throw AgentSessionError.autonomousActivity(.invalidCandidate(candidate.candidateID))
            }
        }
        try reviewAutonomousLocalApprenticeships(from: candidates)
        state.counters.decisionCount += 1
        state.counters.candidateCount += candidates.count
        state.cooldowns.removeAll { $0.untilTick < tick }
        let available = candidates.filter { candidate in
            !state.cooldowns.contains {
                $0.actorID == candidate.actorID && $0.candidateID == candidate.candidateID
                    && $0.untilTick >= tick
            }
        }
        let grouped = Dictionary(grouping: available, by: \.actorID)
        let actorIDs = Set(grouped.keys).union(state.activeActivities.map { $0.candidate.actorID })
        var nextActive: [AgentAutonomousActivity] = []
        for actorID in actorIDs.sorted() {
            let choices = (grouped[actorID] ?? []).sorted(by: candidateSort)
            let previous = state.activeActivities.first { $0.candidate.actorID == actorID }
            guard let winner = choices.first else {
                if let previous {
                    appendTerminalRecord(
                        previous, lifecycle: .stale, reason: "candidate no longer observed",
                        state: &state
                    )
                }
                continue
            }
            let lifecycle: AgentAutonomousActivityLifecycle = winner.distance <= 1
                ? .ready : .traveling
            if var previous, previous.candidate.candidateID == winner.candidateID {
                previous = AgentAutonomousActivity(
                    activityID: previous.activityID, candidate: winner,
                    selectedAtTick: previous.selectedAtTick, updatedAtTick: tick,
                    lifecycle: lifecycle
                )
                nextActive.append(previous)
                continue
            }
            if let previous {
                appendTerminalRecord(
                    previous, lifecycle: .interrupted,
                    reason: "higher-ranked candidate selected", state: &state
                )
                state.counters.switchCount += 1
            }
            let nextStart = state.counters.startCount + 1
            let activityID = String(
                "activity:\(nextStart):\(actorID.rawValue):\(winner.candidateID)".prefix(160)
            )
            let activity = AgentAutonomousActivity(
                activityID: activityID,
                candidate: winner, selectedAtTick: tick, updatedAtTick: tick,
                lifecycle: lifecycle == .traveling ? .selected : .ready
            )
            nextActive.append(activity)
            state.counters.startCount += 1
            if winner.source == .commitment { state.counters.commitmentSelectionCount += 1 }
            if winner.source == .need { state.counters.needSelectionCount += 1 }
            if winner.domain == .dependentCare { state.counters.careSelectionCount += 1 }
        }
        guard nextActive.count <= state.configuration.maximumActiveActivities else {
            throw AgentSessionError.autonomousActivity(.candidateLimitReached)
        }
        state.activeActivities = nextActive.sorted(by: activitySort)
        if state.activeActivities.isEmpty {
            state.counters.currentIdleTicks += 1
            state.counters.longestIdleTicks = max(
                state.counters.longestIdleTicks, state.counters.currentIdleTicks
            )
        } else {
            state.counters.currentIdleTicks = 0
        }
        evictActivityState(&state)
        autonomousActivityState = state
        return state.activeActivities
    }

    @discardableResult
    public mutating func recordAutonomousActivityOutcome(
        _ outcome: AgentAutonomousActivityOutcome
    ) throws -> AgentAutonomousActivityRecord {
        var candidate = self
        let record = try candidate.recordAutonomousActivityOutcomeInPlace(outcome)
        self = candidate
        return record
    }

    private mutating func recordAutonomousActivityOutcomeInPlace(
        _ outcome: AgentAutonomousActivityOutcome
    ) throws -> AgentAutonomousActivityRecord {
        guard var state = autonomousActivityState else {
            throw AgentSessionError.autonomousActivity(.disabled)
        }
        guard outcome.lifecycle.isTerminal else {
            throw AgentSessionError.autonomousActivity(.invalidCandidate("outcome is not terminal"))
        }
        guard let index = state.activeActivities.firstIndex(where: {
            $0.candidate.actorID == outcome.actorID
        }) else {
            throw AgentSessionError.autonomousActivity(.noActiveActivity(outcome.actorID))
        }
        var activity = state.activeActivities[index]
        guard activity.activityID == outcome.activityID else {
            throw AgentSessionError.autonomousActivity(.activityMismatch(outcome.activityID))
        }
        activity.updatedAtTick = outcome.completedAtTick
        activity.lifecycle = outcome.lifecycle
        let record = AgentAutonomousActivityRecord(activity: activity, outcome: outcome)
        state.activeActivities.remove(at: index)
        state.recentRecords.append(record)
        switch outcome.lifecycle {
        case .completed:
            state.counters.completionCount += 1
        case .blocked:
            state.counters.blockCount += 1
            state.cooldowns.append(AgentAutonomousActivityCooldown(
                actorID: outcome.actorID,
                candidateID: activity.candidate.candidateID,
                untilTick: outcome.completedAtTick + state.configuration.blockedCooldownTicks
            ))
        default: break
        }
        evictActivityState(&state)
        autonomousActivityState = state
        return record
    }

    private func appendTerminalRecord(
        _ activity: AgentAutonomousActivity,
        lifecycle: AgentAutonomousActivityLifecycle,
        reason: String,
        state: inout AgentAutonomousActivityState
    ) {
        var terminal = activity
        terminal.updatedAtTick = tick
        terminal.lifecycle = lifecycle
        state.recentRecords.append(AgentAutonomousActivityRecord(
            activity: terminal,
            outcome: AgentAutonomousActivityOutcome(
                activityID: terminal.activityID, actorID: terminal.candidate.actorID,
                lifecycle: lifecycle, completedAtTick: tick, reason: reason
            )
        ))
    }

    private func evictActivityState(_ state: inout AgentAutonomousActivityState) {
        if state.recentRecords.count > state.configuration.maximumRetainedRecords {
            let remove = state.recentRecords.count - state.configuration.maximumRetainedRecords
            state.recentRecords.removeFirst(remove)
            state.evictionCount += remove
        }
        state.cooldowns.sort(by: cooldownSort)
        if state.cooldowns.count > state.configuration.maximumCooldowns {
            let remove = state.cooldowns.count - state.configuration.maximumCooldowns
            state.cooldowns.removeFirst(remove)
            state.evictionCount += remove
        }
    }

    func candidateSort(
        _ lhs: AgentAutonomousActivityCandidate,
        _ rhs: AgentAutonomousActivityCandidate
    ) -> Bool {
        if lhs.priorityBand != rhs.priorityBand { return lhs.priorityBand < rhs.priorityBand }
        if lhs.urgency != rhs.urgency { return lhs.urgency > rhs.urgency }
        if lhs.continuity != rhs.continuity { return lhs.continuity && !rhs.continuity }
        if lhs.distance != rhs.distance { return lhs.distance < rhs.distance }
        if lhs.domain != rhs.domain { return lhs.domain.rawValue < rhs.domain.rawValue }
        return lhs.candidateID < rhs.candidateID
    }

    func activitySort(_ lhs: AgentAutonomousActivity, _ rhs: AgentAutonomousActivity) -> Bool {
        if lhs.candidate.actorID != rhs.candidate.actorID {
            return lhs.candidate.actorID < rhs.candidate.actorID
        }
        return lhs.activityID < rhs.activityID
    }

    func cooldownSort(
        _ lhs: AgentAutonomousActivityCooldown,
        _ rhs: AgentAutonomousActivityCooldown
    ) -> Bool {
        if lhs.untilTick != rhs.untilTick { return lhs.untilTick < rhs.untilTick }
        if lhs.actorID != rhs.actorID { return lhs.actorID < rhs.actorID }
        return lhs.candidateID < rhs.candidateID
    }
}
