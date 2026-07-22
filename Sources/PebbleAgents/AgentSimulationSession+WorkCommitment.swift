import Foundation

extension AgentSimulationSession {
    public var workCommitmentsEnabled: Bool { workCommitmentState != nil }

    public func workCommitmentSnapshot() -> AgentWorkCommitmentSnapshot {
        guard let state = workCommitmentState else {
            return AgentWorkCommitmentSnapshot(
                enabled: false, configuration: nil, demands: [], commitments: [], evidence: [],
                professionProfiles: [], specializationMetrics: [], dependencyMetrics: [],
                coordinationMetrics: workCoordinationMetrics(),
                localReputations: [], matchingAttempts: [], totalDemandCount: 0,
                totalCommitmentCount: 0, totalEvidenceCount: 0,
                totalReassignmentCount: 0, evictionCounts: AgentWorkEvictionCounts(),
                digest: AgentWorkDigest.make("disabled")
            )
        }
        return AgentWorkCommitmentSnapshot(
            enabled: true, configuration: state.configuration,
            demands: state.demands.sorted(by: workDemandSort),
            commitments: state.commitments.sorted(by: workCommitmentSort),
            evidence: state.retainedEvidence.sorted(by: workEvidenceSort),
            professionProfiles: professionProfiles(),
            specializationMetrics: specializationMetrics(),
            dependencyMetrics: workDependencyMetrics(),
            coordinationMetrics: workCoordinationMetrics(),
            localReputations: state.localReputations.sorted(by: workReputationSort),
            matchingAttempts: state.matchingAttempts.sorted(by: workMatchingAttemptSort),
            totalDemandCount: state.totalDemandCount,
            totalCommitmentCount: state.totalCommitmentCount,
            totalEvidenceCount: state.totalEvidenceCount,
            totalReassignmentCount: state.totalReassignmentCount,
            evictionCounts: state.evictionCounts,
            digest: workCommitmentDigest(state)
        )
    }

    public func activeWorkCommitments(for workerID: AgentID? = nil) -> [AgentWorkCommitment] {
        guard let state = workCommitmentState else { return [] }
        return state.commitments.filter {
            $0.status.isOpen && (workerID == nil || $0.workerID == workerID)
        }.sorted(by: workCommitmentSort)
    }

    public func activeWorkDemands(domain: AgentSkillDomain? = nil) -> [AgentWorkDemandSignal] {
        guard let state = workCommitmentState else { return [] }
        return state.demands.filter {
            $0.status.isActive && $0.expiresAtTick >= tick
                && (domain == nil || $0.domain == domain)
        }.sorted(by: workDemandSort)
    }

    public func localWorkReputation(
        observerID: AgentID,
        workerID: AgentID,
        domain: AgentSkillDomain
    ) -> AgentLocalWorkReputation? {
        workCommitmentState?.localReputations.first {
            $0.observerID == observerID && $0.workerID == workerID && $0.domain == domain
        }
    }

    public mutating func setWorkCommitmentsEnabled(
        _ enabled: Bool,
        configuration: AgentWorkCommitmentConfiguration = .live
    ) throws {
        if enabled {
            guard workCommitmentState == nil else {
                throw AgentSessionError.workCommitment(.alreadyEnabled)
            }
            guard causalLedger.policy != .disabled else {
                throw AgentSessionError.workCommitment(.causalLedgerRequired)
            }
            guard populationRegistry != nil else {
                throw AgentSessionError.workCommitment(.populationRequired)
            }
            guard lifecycleState != nil else {
                throw AgentSessionError.workCommitment(.lifecycleRequired)
            }
            guard skillState != nil else {
                throw AgentSessionError.workCommitment(.skillsRequired)
            }
            var candidate = self
            try candidate.prevalidateCausalAppend(count: 1)
            let digest = AgentWorkDigest.make(
                "work|\(candidate.simulationID.rawValue)|\(candidate.tick)|empty"
            )
            let event = try candidate.requiredWorkEvent(
                kind: .workCommitmentsInitialized,
                payload: candidate.workPayload(status: "initialized", digest: digest),
                summary: "work commitments initialized without retroactive history"
            )
            candidate.workCommitmentState = AgentWorkCommitmentState(
                configuration: configuration, demands: [], commitments: [],
                retainedEvidence: [], localReputations: [], domainHistories: [],
                matchingAttempts: [], processedSourceEventIDs: [],
                lastProcessedSourceEventID: nil, totalDemandCount: 0,
                totalCommitmentCount: 0, totalEvidenceCount: 0,
                totalReassignmentCount: 0, evictionCounts: AgentWorkEvictionCounts(),
                rollingDigest: digest, initializedEventID: event.eventID,
                lastWorkEventID: event.eventID, transitionTick: candidate.tick,
                transitionsAtTick: 1
            )
            try candidate.validateWorkCommitmentStateIfEnabled()
            self = candidate
        } else if workCommitmentState != nil {
            throw AgentSessionError.workCommitment(.unsafeDisable)
        }
    }

    @discardableResult
    public mutating func applyWorkCommitmentOperation(
        _ operation: AgentWorkCommitmentOperation
    ) throws -> AgentWorkCommitment? {
        var candidate = self
        let result: AgentWorkCommitment?
        switch operation {
        case .refreshDemands:
            try candidate.refreshWorkDemandsInPlace()
            result = nil
        case let .start(demandID, contexts):
            result = try candidate.startWorkCommitmentInPlace(
                demandID: demandID, candidates: contexts
            )
        case let .renew(commitmentID):
            result = try candidate.renewWorkCommitmentInPlace(commitmentID)
        case let .suspend(commitmentID, reason):
            result = try candidate.suspendWorkCommitmentInPlace(commitmentID, reason: reason)
        case let .resume(commitmentID):
            result = try candidate.resumeWorkCommitmentInPlace(commitmentID)
        case let .end(commitmentID, reason):
            result = try candidate.endWorkCommitmentInPlace(commitmentID, reason: reason)
        case let .replace(commitmentID, contexts):
            result = try candidate.replaceWorkCommitmentInPlace(
                commitmentID, candidates: contexts
            )
        case let .recordOutcome(outcome):
            try candidate.recordValidatedWorkOutcomeInPlace(outcome)
            result = candidate.workCommitmentState?.commitments.first {
                $0.commitmentID == outcome.commitmentID
            }
        case .review:
            try candidate.reviewWorkCommitmentsInPlace()
            result = nil
        }
        try candidate.validateWorkCommitmentStateIfEnabled()
        self = candidate
        return result
    }

    public func matchingScore(
        for demandID: AgentWorkDemandID,
        candidate context: AgentWorkCandidateContext
    ) -> AgentWorkMatchScore? {
        guard let state = workCommitmentState,
              let demand = state.demands.first(where: {
                  $0.demandID == demandID && $0.status.isActive && $0.expiresAtTick >= tick
              }), workCandidateEligible(context, demand: demand, state: state) else {
            return nil
        }
        let skill = min(400, practiceUnits(agentID: context.agentID, domain: demand.domain) * 20)
        let continuity = demand.suggestedWorkerID == context.agentID
            || state.commitments.contains {
                $0.workerID == context.agentID && $0.domain == demand.domain && $0.status.isOpen
            } ? 160 : 0
        let reputation = localWorkReputation(
            observerID: demand.observerID, workerID: context.agentID, domain: demand.domain
        )?.score ?? 0
        let trust = socialEnabled
            ? trustScore(
                sourceAgentId: demand.observerID.rawValue,
                targetAgentId: context.agentID.rawValue
            ) : 0
        let activeLoad = state.commitments.filter {
            $0.workerID == context.agentID && $0.status.isOpen
        }.count + context.externalWorkload
        let carePenalty = dependentCareState != nil && careTarget(for: context.agentID) != nil
            && demand.domain != .caregiving ? 100 : 0
        return AgentWorkMatchScore(
            capability: 1_000,
            skillAndPractice: skill,
            continuity: continuity,
            localReputation: max(-100, min(100, reputation)),
            trust: max(-100, min(100, trust)),
            proximity: max(0, 160 - context.distance * 5),
            availability: max(0, 160 - activeLoad * 40),
            obligations: -(context.obligationPenalty + carePenalty),
            toolsAndResources: 160,
            urgency: demand.urgency
        )
    }

    private mutating func refreshWorkDemandsInPlace() throws {
        guard var state = workCommitmentState else {
            throw AgentSessionError.workCommitment(.disabled)
        }
        try beginWorkTransition(&state)
        let fresh = derivedWorkDemandSignals(configuration: state.configuration)
        let freshIDs = Set(fresh.map(\.demandID))
        for index in state.demands.indices where state.demands[index].status.isActive
            && !freshIDs.contains(state.demands[index].demandID) {
            state.demands[index].status = .withdrawn
        }
        for signal in fresh.sorted(by: workDemandSort) {
            if let index = state.demands.firstIndex(where: { $0.demandID == signal.demandID }) {
                guard state.demands[index].sourceEventID == signal.sourceEventID,
                      state.demands[index].domain == signal.domain else {
                    throw AgentSessionError.workCommitment(.invalidState("demand identity changed"))
                }
                state.demands[index].refreshedAtTick = tick
                state.demands[index].expiresAtTick = signal.expiresAtTick
                if state.demands[index].status == .expired
                    || state.demands[index].status == .withdrawn {
                    state.demands[index].status = .active
                    state.demands[index].terminalEventID = nil
                }
                continue
            }
            guard state.demands.filter(\.status.isActive).count
                    < state.configuration.maximumActiveDemands else {
                throw AgentSessionError.workCommitment(.capacityReached("active demands"))
            }
            try prevalidateCausalAppend(count: 1)
            let digest = AgentWorkDigest.make(
                "\(state.rollingDigest)|demand|\(signal.demandID.rawValue)|\(tick)"
            )
            let event = try requiredWorkEvent(
                kind: .workDemandRefreshed,
                actorID: signal.observerID,
                causes: [signal.sourceEventID],
                payload: workPayload(
                    demand: signal, status: "active", quantity: signal.quantity,
                    digest: digest
                ),
                summary: "work demand source=\(signal.source.rawValue) domain=\(signal.domain.rawValue)"
            )
            state.demands.append(signal)
            state.totalDemandCount += 1
            state.lastWorkEventID = event.eventID
            state.rollingDigest = digest
        }
        state.demands.sort(by: workDemandSort)
        evictWorkStateIfNeeded(&state)
        workCommitmentState = state
    }

    private func derivedWorkDemandSignals(
        configuration: AgentWorkCommitmentConfiguration
    ) -> [AgentWorkDemandSignal] {
        var values: [AgentWorkDemandSignal] = []
        func make(
            source: AgentWorkDemandSource,
            key: String,
            eventID: AgentCausalEventID,
            observerID: AgentID,
            suggested: AgentID?,
            domain: AgentSkillDomain,
            position: AgentPosition?,
            tools: [String] = [],
            resources: [String] = [],
            urgency: Int,
            quantity: Int = 1,
            cadence: Int = 4
        ) -> AgentWorkDemandSignal {
            let token = AgentWorkDigest.make("\(source.rawValue)|\(key)|\(domain.rawValue)")
            return AgentWorkDemandSignal(
                demandID: AgentWorkDemandID(rawValue: "work-demand-\(source.rawValue)-\(token)")!,
                source: source, sourceKey: key, sourceEventID: eventID,
                observerID: observerID, suggestedWorkerID: suggested, domain: domain,
                targetPosition: position, requiredToolKeys: tools,
                requiredResourceKeys: resources, urgency: urgency, quantity: quantity,
                cadenceTicks: cadence, createdAtTick: tick,
                expiresAtTick: tick + configuration.demandLifetimeTicks
            )
        }

        if let agriculture = agricultureState {
            for plot in agriculture.plots where ![.cycleCompleted, .cancelled, .blocked].contains(plot.phase) {
                for cell in plot.cells {
                    let spec: (AgentAgriculturalActionKind, [String], [String])?
                    switch cell.phase {
                    case .planned: spec = (.till, ["hoe"], [])
                    case .prepared: spec = (.plant, [], ["\(plot.crop.rawValue)_planting_item"])
                    case .mature: spec = (.harvest, [], [])
                    case .planted, .harvested, .blocked: spec = nil
                    }
                    if let spec {
                        values.append(make(
                            source: .agriculture,
                            key: "\(plot.plotID.rawValue)-\(cell.index)-\(spec.0.rawValue)",
                            eventID: cell.lastWorkEventID ?? plot.lastAgricultureEventID,
                            observerID: plot.plannerID, suggested: nil, domain: .cultivation,
                            position: cell.position, tools: spec.1, resources: spec.2,
                            urgency: 65, cadence: 4
                        ))
                    }
                }
            }
        }
        if let wild = wildSubsistenceState {
            for opportunity in wild.opportunities where opportunity.status == .selected
                && opportunity.expiresAtTick >= tick {
                let domain: AgentSkillDomain
                let tools: [String]
                switch opportunity.strategy {
                case .fishing: domain = .fishing; tools = ["fishing_rod"]
                case .hunting: domain = .hunting; tools = ["hunting_weapon"]
                case .wildGathering: domain = .foraging; tools = []
                case .agriculture: domain = .cultivation; tools = []
                }
                values.append(make(
                    source: .wildSubsistence, key: opportunity.opportunityID.rawValue,
                    eventID: opportunity.selectedEventID, observerID: opportunity.actorID,
                    suggested: opportunity.actorID, domain: domain,
                    position: opportunity.lastObservedPosition, tools: tools,
                    urgency: 70, cadence: 3
                ))
            }
        }
        if let livestock = livestockState {
            for task in livestock.activeTasks where !task.status.terminal
                && task.expiresAtTick >= tick {
                values.append(make(
                    source: .livestock, key: task.taskID.rawValue,
                    eventID: task.createdEventID, observerID: task.responsibleAgentID,
                    suggested: task.responsibleAgentID, domain: .husbandry,
                    position: task.targetPosition,
                    resources: task.kind == .feed || task.kind == .breed ? ["compatible_feed"] : [],
                    urgency: task.kind == .recoverMissing ? 90 : 60, cadence: 4
                ))
            }
        }
        if let project = constructionProject, project.isActive,
           let eventID = lastConstructionEventID,
           let builder = AgentID(rawValue: project.builderAgentId) {
            let demand = constructionDemand()
            let acquiring = demand?.isSatisfied == false
            values.append(make(
                source: .construction,
                key: project.projectId + "-" + (acquiring
                    ? "materials-" + (demand?.missing.map {
                        "\($0.resource.rawValue):\($0.quantity)"
                    }.joined(separator: ",") ?? "none")
                    : "cell-\(project.nextCell?.index ?? -1)"),
                eventID: eventID,
                observerID: builder, suggested: builder,
                domain: acquiring ? .materialHandling : .construction,
                position: acquiring ? project.origin : project.nextWorkPosition,
                resources: acquiring ? (demand?.eligibleResources.map(\.rawValue) ?? []) : [],
                urgency: 55, quantity: acquiring ? max(1, demand?.missing.reduce(0) { $0 + $1.quantity } ?? 1) : 1,
                cadence: 4
            ))
        }
        if let care = dependentCareState {
            for need in care.activeNeeds where need.status == .active {
                guard let observer = need.assignedCaregiverID
                        ?? statesById.values.map(\.agentID).sorted().first else { continue }
                values.append(make(
                    source: .dependentCare, key: need.needID.rawValue,
                    eventID: need.raisedEventID, observerID: observer,
                    suggested: need.assignedCaregiverID, domain: .caregiving,
                    position: statesById[need.dependentID.rawValue]?.position,
                    resources: need.kind == .nourishment ? ["food"] : [],
                    urgency: min(100, 70 + need.severity), cadence: 2
                ))
            }
        }
        for task in sharedTasks where !task.status.isTerminal && task.status.reservesDemand {
            let source = task.latestProgressEventID ?? task.acceptanceEventID
                ?? task.sourceConstructionEventID ?? task.sourceFactEventID
            values.append(make(
                source: .cooperation, key: task.taskID.rawValue, eventID: source,
                observerID: task.issuerID, suggested: task.helperID,
                domain: .materialHandling,
                position: constructionProject?.origin,
                resources: [task.resource.rawValue], urgency: 60,
                quantity: max(1, task.remainingQuantity), cadence: 3
            ))
        }
        return values.sorted(by: workDemandSort)
    }

    private mutating func startWorkCommitmentInPlace(
        demandID: AgentWorkDemandID,
        candidates contexts: [AgentWorkCandidateContext]
    ) throws -> AgentWorkCommitment? {
        guard var state = workCommitmentState else {
            throw AgentSessionError.workCommitment(.disabled)
        }
        try beginWorkTransition(&state)
        guard let demand = state.demands.first(where: { $0.demandID == demandID }) else {
            throw AgentSessionError.workCommitment(.unknownDemand(demandID))
        }
        guard demand.status.isActive && demand.expiresAtTick >= tick else {
            throw AgentSessionError.workCommitment(.inactiveDemand(demandID))
        }
        guard Set(contexts.map(\.agentID)).count == contexts.count else {
            throw AgentSessionError.workCommitment(.invalidTransition("duplicate candidates"))
        }
        let scored = contexts.compactMap { context -> (AgentWorkCandidateContext, AgentWorkMatchScore)? in
            matchingScore(for: demandID, candidate: context).map { (context, $0) }
        }.sorted { lhs, rhs in
            if lhs.1.total != rhs.1.total { return lhs.1.total > rhs.1.total }
            return lhs.0.agentID < rhs.0.agentID
        }
        let eligible = scored.map { $0.0.agentID }
        let rejected = contexts.map(\.agentID).filter { !eligible.contains($0) }.sorted()
        guard let selected = scored.first else {
            state.matchingAttempts.append(AgentWorkMatchingAttempt(
                demandID: demandID, selectedWorkerID: nil, eligibleWorkerIDs: [],
                rejectedWorkerIDs: rejected, selectedScore: nil,
                attemptedAtTick: tick, causalEventID: nil
            ))
            evictWorkStateIfNeeded(&state)
            workCommitmentState = state
            return nil
        }
        let ordinal = state.totalCommitmentCount + 1
        let commitmentID = AgentWorkCommitmentID(
            rawValue: "work-commitment-" + String(format: "%08d", ordinal)
        )!
        try prevalidateCausalAppend(count: 2)
        let matchDigest = AgentWorkDigest.make(
            "\(state.rollingDigest)|match|\(demandID.rawValue)|\(selected.0.agentID.rawValue)|\(selected.1.total)"
        )
        let matchEvent = try requiredWorkEvent(
            kind: .workMatchingSelected, actorID: demand.observerID,
            subjectID: selected.0.agentID, causes: [demand.sourceEventID],
            payload: workPayload(
                demand: demand, workerID: selected.0.agentID,
                status: "selected", quantity: demand.quantity,
                score: selected.1.total, digest: matchDigest
            ),
            summary: "work match demand=\(demandID.rawValue) worker=\(selected.0.agentID.rawValue) score=\(selected.1.total)"
        )
        let startDigest = AgentWorkDigest.make(
            "\(matchDigest)|start|\(commitmentID.rawValue)|\(tick)"
        )
        let startEvent = try requiredWorkEvent(
            kind: .workCommitmentStarted, actorID: selected.0.agentID,
            subjectID: selected.0.agentID, causes: [matchEvent.eventID],
            payload: workPayload(
                demand: demand, commitmentID: commitmentID,
                workerID: selected.0.agentID, status: "active",
                quantity: demand.quantity, score: selected.1.total, digest: startDigest
            ),
            summary: "work commitment started id=\(commitmentID.rawValue) domain=\(demand.domain.rawValue)"
        )
        let commitment = AgentWorkCommitment(
            commitmentID: commitmentID, demandID: demandID,
            workerID: selected.0.agentID, observerID: demand.observerID,
            domain: demand.domain, startedAtTick: tick,
            startedEventID: startEvent.eventID,
            reviewAtTick: tick + state.configuration.reviewIntervalTicks,
            expiresAtTick: tick + state.configuration.commitmentLifetimeTicks,
            status: .active, suspensionReason: nil, outcomeCount: 0,
            successfulOutcomeCount: 0, lastOutcomeEventID: nil,
            terminalTick: nil, terminalEventID: nil, replacementCommitmentID: nil
        )
        state.commitments.append(commitment)
        state.totalCommitmentCount += 1
        state.matchingAttempts.append(AgentWorkMatchingAttempt(
            demandID: demandID, selectedWorkerID: selected.0.agentID,
            eligibleWorkerIDs: eligible, rejectedWorkerIDs: rejected,
            selectedScore: selected.1, attemptedAtTick: tick,
            causalEventID: matchEvent.eventID
        ))
        state.lastWorkEventID = startEvent.eventID
        state.rollingDigest = startDigest
        evictWorkStateIfNeeded(&state)
        workCommitmentState = state
        return commitment
    }

    private mutating func renewWorkCommitmentInPlace(
        _ commitmentID: AgentWorkCommitmentID
    ) throws -> AgentWorkCommitment {
        let currentTick = tick
        return try transitionOpenCommitment(
            commitmentID, allowed: [.active], kind: .workCommitmentRenewed,
            status: .active, suspensionReason: nil, statusText: "renewed"
        ) { commitment, configuration in
            commitment.reviewAtTick = currentTick + configuration.reviewIntervalTicks
            commitment.expiresAtTick = currentTick + configuration.commitmentLifetimeTicks
        }
    }

    private mutating func suspendWorkCommitmentInPlace(
        _ commitmentID: AgentWorkCommitmentID,
        reason: AgentWorkSuspensionReason
    ) throws -> AgentWorkCommitment {
        let currentTick = tick
        return try transitionOpenCommitment(
            commitmentID, allowed: [.active], kind: .workCommitmentSuspended,
            status: .suspended, suspensionReason: reason,
            statusText: "suspended:\(reason.rawValue)"
        ) { commitment, configuration in
            commitment.reviewAtTick = currentTick + configuration.reviewIntervalTicks
        }
    }

    private mutating func resumeWorkCommitmentInPlace(
        _ commitmentID: AgentWorkCommitmentID
    ) throws -> AgentWorkCommitment {
        let currentTick = tick
        return try transitionOpenCommitment(
            commitmentID, allowed: [.suspended], kind: .workCommitmentResumed,
            status: .active, suspensionReason: nil, statusText: "resumed"
        ) { commitment, configuration in
            commitment.reviewAtTick = currentTick + configuration.reviewIntervalTicks
            commitment.expiresAtTick = max(
                commitment.expiresAtTick,
                currentTick + configuration.reviewIntervalTicks
            )
        }
    }

    private mutating func transitionOpenCommitment(
        _ commitmentID: AgentWorkCommitmentID,
        allowed: Set<AgentWorkCommitmentStatus>,
        kind: AgentCausalEventKind,
        status: AgentWorkCommitmentStatus,
        suspensionReason: AgentWorkSuspensionReason?,
        statusText: String,
        mutate: (inout AgentWorkCommitment, AgentWorkCommitmentConfiguration) -> Void
    ) throws -> AgentWorkCommitment {
        guard var state = workCommitmentState else {
            throw AgentSessionError.workCommitment(.disabled)
        }
        try beginWorkTransition(&state)
        guard let index = state.commitments.firstIndex(where: {
            $0.commitmentID == commitmentID
        }) else { throw AgentSessionError.workCommitment(.unknownCommitment(commitmentID)) }
        guard allowed.contains(state.commitments[index].status) else {
            throw AgentSessionError.workCommitment(.invalidTransition(statusText))
        }
        var commitment = state.commitments[index]
        mutate(&commitment, state.configuration)
        try prevalidateCausalAppend(count: 1)
        let digest = AgentWorkDigest.make(
            "\(state.rollingDigest)|\(statusText)|\(commitmentID.rawValue)|\(tick)"
        )
        let event = try requiredWorkEvent(
            kind: kind, actorID: commitment.workerID, subjectID: commitment.workerID,
            causes: [state.lastWorkEventID],
            payload: workPayload(
                commitment: commitment, status: statusText, digest: digest
            ),
            summary: "work commitment \(statusText) id=\(commitmentID.rawValue)"
        )
        commitment.status = status
        commitment.suspensionReason = suspensionReason
        state.commitments[index] = commitment
        state.lastWorkEventID = event.eventID
        state.rollingDigest = digest
        workCommitmentState = state
        return commitment
    }

    private mutating func endWorkCommitmentInPlace(
        _ commitmentID: AgentWorkCommitmentID,
        reason: AgentWorkEndReason
    ) throws -> AgentWorkCommitment {
        guard var state = workCommitmentState else {
            throw AgentSessionError.workCommitment(.disabled)
        }
        try beginWorkTransition(&state)
        guard let index = state.commitments.firstIndex(where: {
            $0.commitmentID == commitmentID
        }) else { throw AgentSessionError.workCommitment(.unknownCommitment(commitmentID)) }
        guard state.commitments[index].status.isOpen else {
            throw AgentSessionError.workCommitment(.invalidTransition("end terminal"))
        }
        var commitment = state.commitments[index]
        try prevalidateCausalAppend(count: 1)
        let digest = AgentWorkDigest.make(
            "\(state.rollingDigest)|end|\(commitmentID.rawValue)|\(reason.rawValue)|\(tick)"
        )
        let event = try requiredWorkEvent(
            kind: .workCommitmentEnded, actorID: commitment.workerID,
            subjectID: commitment.workerID, causes: [state.lastWorkEventID],
            payload: workPayload(
                commitment: commitment, status: "ended:\(reason.rawValue)", digest: digest
            ),
            summary: "work commitment ended id=\(commitmentID.rawValue) reason=\(reason.rawValue)"
        )
        commitment.status = reason == .expired ? .expired : .ended
        commitment.terminalTick = tick
        commitment.terminalEventID = event.eventID
        state.commitments[index] = commitment
        state.lastWorkEventID = event.eventID
        state.rollingDigest = digest
        workCommitmentState = state
        return commitment
    }

    private mutating func replaceWorkCommitmentInPlace(
        _ commitmentID: AgentWorkCommitmentID,
        candidates: [AgentWorkCandidateContext]
    ) throws -> AgentWorkCommitment? {
        guard let existing = workCommitmentState?.commitments.first(where: {
            $0.commitmentID == commitmentID
        }), existing.status.isOpen else {
            throw AgentSessionError.workCommitment(.unknownCommitment(commitmentID))
        }
        _ = try endWorkCommitmentInPlace(commitmentID, reason: .replacement)
        guard let replacement = try startWorkCommitmentInPlace(
            demandID: existing.demandID,
            candidates: candidates.filter { $0.agentID != existing.workerID }
        ) else {
            throw AgentSessionError.workCommitment(.noEligibleWorker(existing.demandID))
        }
        guard var state = workCommitmentState,
              let oldIndex = state.commitments.firstIndex(where: {
                  $0.commitmentID == commitmentID
              }), let newIndex = state.commitments.firstIndex(where: {
                  $0.commitmentID == replacement.commitmentID
              }) else { throw AgentSessionError.workCommitment(.invalidState("replacement")) }
        try beginWorkTransition(&state)
        try prevalidateCausalAppend(count: 1)
        let digest = AgentWorkDigest.make(
            "\(state.rollingDigest)|reassign|\(commitmentID.rawValue)|\(replacement.commitmentID.rawValue)"
        )
        let event = try requiredWorkEvent(
            kind: .workCommitmentReassigned, actorID: replacement.workerID,
            subjectID: existing.workerID,
            causes: [state.commitments[oldIndex].terminalEventID, replacement.startedEventID]
                .compactMap { $0 }.sorted(),
            payload: workPayload(
                commitment: replacement, status: "reassigned",
                digest: digest
            ),
            summary: "work commitment reassigned old=\(commitmentID.rawValue) new=\(replacement.commitmentID.rawValue)"
        )
        state.commitments[oldIndex].status = .reassigned
        state.commitments[oldIndex].replacementCommitmentID = replacement.commitmentID
        state.commitments[newIndex].lastOutcomeEventID = nil
        state.totalReassignmentCount += 1
        state.lastWorkEventID = event.eventID
        state.rollingDigest = digest
        workCommitmentState = state
        return state.commitments[newIndex]
    }

    private mutating func recordValidatedWorkOutcomeInPlace(
        _ outcome: AgentValidatedWorkOutcome
    ) throws {
        guard var state = workCommitmentState else {
            throw AgentSessionError.workCommitment(.disabled)
        }
        try beginWorkTransition(&state)
        guard let commitmentIndex = state.commitments.firstIndex(where: {
            $0.commitmentID == outcome.commitmentID
        }) else {
            throw AgentSessionError.workCommitment(.unknownCommitment(outcome.commitmentID))
        }
        var commitment = state.commitments[commitmentIndex]
        guard !state.processedSourceEventIDs.contains(outcome.sourceSuccessEventID),
              state.lastProcessedSourceEventID.map({
                  outcome.sourceSuccessEventID > $0
              }) ?? true else {
            throw AgentSessionError.workCommitment(.duplicateSourceEvent(outcome.sourceSuccessEventID))
        }
        guard commitment.status == .active,
              commitment.workerID == outcome.workerID,
              commitment.domain == outcome.domain else {
            throw AgentSessionError.workCommitment(.invalidOutcome("commitment identity or status"))
        }
        guard let source = causalLedger.events.first(where: {
            $0.eventID == outcome.sourceSuccessEventID
        }), source.eventID.sequence > commitment.startedEventID.sequence,
              workOutcomeSourceMatches(source, outcome: outcome) else {
            throw AgentSessionError.workCommitment(.invalidOutcome("source evidence"))
        }
        guard outcome.quantity > 0, outcome.observerIDs.count <= 8,
              outcome.observerIDs.allSatisfy({ statesById[$0.rawValue] != nil }) else {
            throw AgentSessionError.workCommitment(.invalidOutcome("quantity or observers"))
        }
        let causalCount = 1 + outcome.observerIDs.count
            + (outcome.status == .succeeded
                && commitment.successfulOutcomeCount + outcome.quantity
                    >= (state.demands.first { $0.demandID == commitment.demandID }?.quantity ?? 1)
                ? 1 : 0)
        try prevalidateCausalAppend(count: causalCount)
        let evidenceDigest = AgentWorkDigest.make(
            "\(state.rollingDigest)|outcome|\(outcome.sourceSuccessEventID.rawValue)|"
                + "\(outcome.status.rawValue)|\(outcome.quantity)|\(outcome.observerIDs.map(\.rawValue).joined(separator: ","))"
        )
        let evidenceEvent = try requiredWorkEvent(
            kind: .workOutcomeValidated, actorID: outcome.workerID,
            subjectID: outcome.workerID, causes: [outcome.sourceSuccessEventID],
            payload: workPayload(
                commitment: commitment, observerID: outcome.observerIDs.first,
                sourceEventID: outcome.sourceSuccessEventID,
                status: outcome.status.rawValue, quantity: outcome.quantity,
                digest: evidenceDigest
            ),
            summary: "work outcome normalized worker=\(outcome.workerID.rawValue) domain=\(outcome.domain.rawValue) status=\(outcome.status.rawValue)"
        )
        let evidence = AgentWorkEvidence(
            commitmentID: commitment.commitmentID, demandID: commitment.demandID,
            workerID: outcome.workerID, domain: outcome.domain,
            sourceEventID: outcome.sourceSuccessEventID, sourceKind: source.kind,
            status: outcome.status, quantity: outcome.quantity,
            observedBy: outcome.observerIDs, recordedAtTick: tick,
            workEventID: evidenceEvent.eventID, digest: evidenceDigest
        )
        state.retainedEvidence.append(evidence)
        state.processedSourceEventIDs.append(outcome.sourceSuccessEventID)
        state.processedSourceEventIDs.sort()
        state.lastProcessedSourceEventID = outcome.sourceSuccessEventID
        state.totalEvidenceCount += 1
        commitment.outcomeCount += outcome.quantity
        if outcome.status == .succeeded { commitment.successfulOutcomeCount += outcome.quantity }
        commitment.lastOutcomeEventID = evidenceEvent.eventID
        updateWorkDomainHistory(&state, outcome: outcome)
        var finalDigest = evidenceDigest
        var finalEventID = evidenceEvent.eventID
        for observerID in outcome.observerIDs {
            let reputationEvent = try updateLocalWorkReputation(
                &state, observerID: observerID, evidence: evidence,
                cause: evidenceEvent.eventID
            )
            finalEventID = reputationEvent.eventID
            finalDigest = AgentWorkDigest.make(
                "\(finalDigest)|reputation|\(observerID.rawValue)|\(reputationEvent.eventID.rawValue)"
            )
        }
        state.commitments[commitmentIndex] = commitment
        let required = state.demands.first {
            $0.demandID == commitment.demandID
        }?.quantity ?? 1
        if outcome.status == .succeeded && commitment.successfulOutcomeCount >= required {
            let fulfilledDigest = AgentWorkDigest.make(
                "\(finalDigest)|fulfilled|\(commitment.commitmentID.rawValue)|\(tick)"
            )
            let fulfilled = try requiredWorkEvent(
                kind: .workCommitmentFulfilled, actorID: commitment.workerID,
                subjectID: commitment.workerID, causes: [evidenceEvent.eventID],
                payload: workPayload(
                    commitment: commitment, status: "fulfilled", quantity: required,
                    digest: fulfilledDigest
                ),
                summary: "work commitment fulfilled id=\(commitment.commitmentID.rawValue)"
            )
            state.commitments[commitmentIndex].status = .fulfilled
            state.commitments[commitmentIndex].terminalTick = tick
            state.commitments[commitmentIndex].terminalEventID = fulfilled.eventID
            if let demandIndex = state.demands.firstIndex(where: {
                $0.demandID == commitment.demandID
            }) {
                state.demands[demandIndex].status = .fulfilled
                state.demands[demandIndex].terminalEventID = fulfilled.eventID
            }
            if let historyIndex = state.domainHistories.firstIndex(where: {
                $0.workerID == commitment.workerID && $0.domain == commitment.domain
            }) { state.domainHistories[historyIndex].completedCommitmentCount += 1 }
            state.lastWorkEventID = fulfilled.eventID
            state.rollingDigest = fulfilledDigest
        } else {
            state.lastWorkEventID = finalEventID
            state.rollingDigest = finalDigest
        }
        evictWorkStateIfNeeded(&state)
        workCommitmentState = state
    }

    private mutating func reviewWorkCommitmentsInPlace() throws {
        guard let state = workCommitmentState else {
            throw AgentSessionError.workCommitment(.disabled)
        }
        workCommitmentState = state
        let carePreempted = state.commitments.filter {
            $0.status == .active && $0.domain != .caregiving
                && careTarget(for: $0.workerID) != nil
        }.map(\.commitmentID).sorted()
        for id in carePreempted {
            _ = try suspendWorkCommitmentInPlace(id, reason: .dependentCare)
        }
        let careReleased = (workCommitmentState?.commitments ?? []).filter {
            $0.status == .suspended && $0.suspensionReason == .dependentCare
                && careTarget(for: $0.workerID) == nil
        }.map(\.commitmentID).sorted()
        for id in careReleased { _ = try resumeWorkCommitmentInPlace(id) }
        let expired = (workCommitmentState?.commitments ?? []).filter {
            $0.status.isOpen && $0.expiresAtTick < tick
        }.map(\.commitmentID).sorted()
        for id in expired { _ = try endWorkCommitmentInPlace(id, reason: .expired) }
        guard var final = workCommitmentState else { return }
        for index in final.commitments.indices where final.commitments[index].status.isOpen
            && final.commitments[index].reviewAtTick <= tick {
            final.commitments[index].reviewAtTick = tick + final.configuration.reviewIntervalTicks
        }
        for index in final.demands.indices where final.demands[index].status.isActive
            && final.demands[index].expiresAtTick < tick {
            final.demands[index].status = .expired
        }
        evictWorkStateIfNeeded(&final)
        workCommitmentState = final
    }

    mutating func endWorkCommitmentsForTerminalAgent(
        _ agentID: AgentID
    ) throws {
        guard workCommitmentState != nil else { return }
        for id in activeWorkCommitments(for: agentID).map(\.commitmentID) {
            _ = try endWorkCommitmentInPlace(id, reason: .workerDied)
        }
    }

    private func workCandidateEligible(
        _ context: AgentWorkCandidateContext,
        demand: AgentWorkDemandSignal,
        state: AgentWorkCommitmentState
    ) -> Bool {
        guard context.capable, context.physicallyAvailable,
              context.toolsAvailable, context.resourcesAvailable,
              (demand.domain == .caregiving || careTarget(for: context.agentID) == nil),
              statesById[context.agentID.rawValue]?.health ?? 0 > 0,
              populationRegistry?.members.first(where: {
                  $0.agentID == context.agentID
              }).map({ $0.status != .migrating }) == true,
              lifecycleState?.members.first(where: {
                  $0.agentID == context.agentID
              })?.currentStage == .mature else { return false }
        let workload = state.commitments.filter {
            $0.workerID == context.agentID && $0.status.isOpen
        }.count + context.externalWorkload
        return workload < state.configuration.maximumConcurrentCommitmentsPerAgent
            && demand.expiresAtTick >= tick
    }

    private func workOutcomeSourceMatches(
        _ event: AgentCausalEvent,
        outcome: AgentValidatedWorkOutcome
    ) -> Bool {
        guard event.simulationID == simulationID,
              event.actorID == outcome.workerID,
              event.simulationTick.rawValue <= tick else { return false }
        if outcome.status == .succeeded {
            return AgentMaterialSuccessEvidence.matches(
                event, agentID: outcome.workerID, domain: outcome.domain
            )
        }
        let domainMatches: Bool
        switch outcome.domain {
        case .cultivation:
            domainMatches = event.origin == .agricultureTransition
        case .fishing, .hunting:
            domainMatches = event.origin == .wildSubsistenceTransition
        case .foraging:
            domainMatches = event.origin == .wildSubsistenceTransition
                || event.origin == .ecologyTransition || event.origin == .worldOutcome
        case .husbandry:
            domainMatches = event.origin == .livestockTransition
        case .construction:
            domainMatches = event.kind == .constructionPlacement
        case .caregiving:
            domainMatches = event.origin == .dependentCareTransition
        case .materialHandling:
            domainMatches = event.kind == .delivery
                || event.origin == .cooperationTransition
        }
        guard domainMatches else { return false }
        let status = AgentMaterialSuccessEvidence.status(event)
        switch outcome.status {
        case .failed: return status == "failed" || status == "unmet"
        case .blocked: return status == "blocked" || status == "reconciled"
        case .interrupted: return status == "interrupted"
        case .succeeded: return false
        }
    }

    private mutating func updateLocalWorkReputation(
        _ state: inout AgentWorkCommitmentState,
        observerID: AgentID,
        evidence: AgentWorkEvidence,
        cause: AgentCausalEventID
    ) throws -> AgentCausalEvent {
        let delta: Int
        switch evidence.status {
        case .succeeded: delta = 10
        case .failed: delta = -6
        case .blocked: delta = 0
        case .interrupted: delta = -1
        }
        let index = state.localReputations.firstIndex {
            $0.observerID == observerID && $0.workerID == evidence.workerID
                && $0.domain == evidence.domain
        }
        let before = index.map { state.localReputations[$0].score } ?? 0
        let after = max(-100, min(100, before + delta))
        let digest = AgentWorkDigest.make(
            "\(state.rollingDigest)|reputation|\(observerID.rawValue)|"
                + "\(evidence.workerID.rawValue)|\(evidence.domain.rawValue)|\(before)|\(after)"
        )
        let event = try requiredWorkEvent(
            kind: .workReputationUpdated, actorID: observerID,
            subjectID: evidence.workerID, causes: [cause],
            payload: workPayload(
                commitmentID: evidence.commitmentID,
                workerID: evidence.workerID, observerID: observerID,
                domain: evidence.domain, sourceEventID: evidence.sourceEventID,
                status: evidence.status.rawValue, quantity: evidence.quantity,
                score: after, digest: digest
            ),
            summary: "local work reputation observer=\(observerID.rawValue) worker=\(evidence.workerID.rawValue) \(before)>\(after)"
        )
        if let index {
            state.localReputations[index].score = after
            switch evidence.status {
            case .succeeded: state.localReputations[index].successCount += evidence.quantity
            case .failed: state.localReputations[index].failureCount += evidence.quantity
            case .blocked: state.localReputations[index].blockedCount += evidence.quantity
            case .interrupted: state.localReputations[index].interruptionCount += evidence.quantity
            }
            state.localReputations[index].lastEvidenceEventID = evidence.workEventID
            state.localReputations[index].lastChangedAtTick = tick
        } else {
            state.localReputations.append(AgentLocalWorkReputation(
                observerID: observerID, workerID: evidence.workerID,
                domain: evidence.domain, score: after,
                successCount: evidence.status == .succeeded ? evidence.quantity : 0,
                failureCount: evidence.status == .failed ? evidence.quantity : 0,
                blockedCount: evidence.status == .blocked ? evidence.quantity : 0,
                interruptionCount: evidence.status == .interrupted ? evidence.quantity : 0,
                lastEvidenceEventID: evidence.workEventID, lastChangedAtTick: tick
            ))
        }
        state.localReputations.sort(by: workReputationSort)
        return event
    }

    private func updateWorkDomainHistory(
        _ state: inout AgentWorkCommitmentState,
        outcome: AgentValidatedWorkOutcome
    ) {
        let index = state.domainHistories.firstIndex {
            $0.workerID == outcome.workerID && $0.domain == outcome.domain
        }
        if let index {
            state.domainHistories[index].outcomeCount += outcome.quantity
            switch outcome.status {
            case .succeeded: state.domainHistories[index].successCount += outcome.quantity
            case .failed: state.domainHistories[index].failureCount += outcome.quantity
            case .blocked: state.domainHistories[index].blockedCount += outcome.quantity
            case .interrupted: state.domainHistories[index].interruptionCount += outcome.quantity
            }
            state.domainHistories[index].lastWorkTick = tick
        } else {
            state.domainHistories.append(AgentWorkDomainHistory(
                workerID: outcome.workerID, domain: outcome.domain,
                outcomeCount: outcome.quantity,
                successCount: outcome.status == .succeeded ? outcome.quantity : 0,
                failureCount: outcome.status == .failed ? outcome.quantity : 0,
                blockedCount: outcome.status == .blocked ? outcome.quantity : 0,
                interruptionCount: outcome.status == .interrupted ? outcome.quantity : 0,
                completedCommitmentCount: 0, firstWorkTick: tick, lastWorkTick: tick
            ))
            state.domainHistories.sort {
                if $0.workerID != $1.workerID { return $0.workerID < $1.workerID }
                return $0.domain < $1.domain
            }
        }
    }

    private func beginWorkTransition(
        _ state: inout AgentWorkCommitmentState
    ) throws {
        if state.transitionTick != tick {
            state.transitionTick = tick
            state.transitionsAtTick = 0
        }
        guard state.transitionsAtTick < state.configuration.maximumTransitionsPerTick else {
            throw AgentSessionError.workCommitment(.transitionsPerTickReached)
        }
        state.transitionsAtTick += 1
    }

    private mutating func requiredWorkEvent(
        kind: AgentCausalEventKind,
        actorID: AgentID? = nil,
        subjectID: AgentID? = nil,
        causes: [AgentCausalEventID] = [],
        payload: AgentCausalPayload,
        summary: String
    ) throws -> AgentCausalEvent {
        guard let event = try causalLedger.append(
            instant: simulationInstant, kind: kind, origin: .workCommitmentTransition,
            actorID: actorID, subjectID: subjectID, operationID: nil,
            causes: causes, payload: payload, summary: summary
        ) else { throw AgentSessionError.workCommitment(.causalLedgerRequired) }
        return event
    }

    private func workPayload(
        demand: AgentWorkDemandSignal? = nil,
        commitment: AgentWorkCommitment? = nil,
        commitmentID: AgentWorkCommitmentID? = nil,
        workerID: AgentID? = nil,
        observerID: AgentID? = nil,
        domain: AgentSkillDomain? = nil,
        sourceEventID: AgentCausalEventID? = nil,
        status: String,
        quantity: Int = 0,
        score: Int = 0,
        digest: String
    ) -> AgentCausalPayload {
        .work(
            demandID: demand?.demandID.rawValue ?? commitment?.demandID.rawValue,
            commitmentID: commitmentID?.rawValue ?? commitment?.commitmentID.rawValue,
            workerID: workerID?.rawValue ?? commitment?.workerID.rawValue,
            observerID: observerID?.rawValue ?? demand?.observerID.rawValue
                ?? commitment?.observerID.rawValue,
            domain: domain?.rawValue ?? demand?.domain.rawValue ?? commitment?.domain.rawValue,
            sourceEventID: sourceEventID?.rawValue ?? demand?.sourceEventID.rawValue,
            status: status, quantity: quantity, score: score, digest: digest
        )
    }

    private func workCommitmentDigest(_ state: AgentWorkCommitmentState) -> String {
        let demands = state.demands.sorted(by: workDemandSort).map {
            "\($0.demandID.rawValue):\($0.status.rawValue):\($0.refreshedAtTick):\($0.expiresAtTick)"
        }.joined(separator: ";")
        let commitments = state.commitments.sorted(by: workCommitmentSort).map {
            "\($0.commitmentID.rawValue):\($0.workerID.rawValue):\($0.domain.rawValue):\($0.status.rawValue):\($0.outcomeCount):\($0.successfulOutcomeCount)"
        }.joined(separator: ";")
        let evidence = state.retainedEvidence.sorted(by: workEvidenceSort).map {
            "\($0.sourceEventID.rawValue):\($0.status.rawValue):\($0.quantity):\($0.digest)"
        }.joined(separator: ";")
        let reputations = state.localReputations.sorted(by: workReputationSort).map {
            "\($0.observerID.rawValue):\($0.workerID.rawValue):\($0.domain.rawValue):\($0.score):\($0.lastEvidenceEventID.rawValue)"
        }.joined(separator: ";")
        let histories = state.domainHistories.sorted {
            $0.workerID == $1.workerID ? $0.domain < $1.domain : $0.workerID < $1.workerID
        }.map {
            "\($0.workerID.rawValue):\($0.domain.rawValue):\($0.outcomeCount):\($0.successCount):\($0.completedCommitmentCount):\($0.lastWorkTick)"
        }.joined(separator: ";")
        let profiles = professionProfiles().map {
            "\($0.agentID.rawValue):\($0.digest)"
        }.joined(separator: ";")
        return AgentWorkDigest.make(
            "\(state.rollingDigest)|\(demands)|\(commitments)|\(evidence)|\(reputations)|\(histories)|\(profiles)|\(state.totalDemandCount)|"
                + "\(state.totalCommitmentCount)|\(state.totalEvidenceCount)|"
                + "\(state.totalReassignmentCount)|\(state.evictionCounts.demands)|"
                + "\(state.evictionCounts.commitments)|\(state.evictionCounts.evidence)|"
                + "\(state.evictionCounts.reputations)|\(state.evictionCounts.matchingAttempts)|"
                + "\(state.evictionCounts.processedSourceEventIDs)|"
                + "\(state.lastProcessedSourceEventID?.rawValue ?? "none")"
        )
    }

    private func evictWorkStateIfNeeded(_ state: inout AgentWorkCommitmentState) {
        state.demands.sort(by: workDemandSort)
        let terminalDemandIndices = state.demands.indices.filter {
            !state.demands[$0].status.isActive
        }
        let maximumDemands = state.configuration.maximumActiveDemands * 2
        if state.demands.count > maximumDemands {
            let remove = min(state.demands.count - maximumDemands, terminalDemandIndices.count)
            for index in terminalDemandIndices.prefix(remove).reversed() {
                state.demands.remove(at: index)
                state.evictionCounts.demands += 1
            }
        }
        state.commitments.sort(by: workCommitmentSort)
        while state.commitments.count > state.configuration.maximumRetainedCommitments,
              let index = state.commitments.firstIndex(where: { !$0.status.isOpen }) {
            state.commitments.remove(at: index)
            state.evictionCounts.commitments += 1
        }
        state.retainedEvidence.sort(by: workEvidenceSort)
        while let overfull = Dictionary(grouping: state.retainedEvidence, by: \.workerID)
            .filter({ $0.value.count > state.configuration.maximumEvidencePerAgent })
            .keys.sorted().first,
              let index = state.retainedEvidence.firstIndex(where: { $0.workerID == overfull }) {
            state.retainedEvidence.remove(at: index)
            state.evictionCounts.evidence += 1
        }
        while state.retainedEvidence.count > state.configuration.maximumRetainedEvidence {
            state.retainedEvidence.removeFirst()
            state.evictionCounts.evidence += 1
        }
        state.localReputations.sort(by: workReputationSort)
        while state.localReputations.count > state.configuration.maximumReputationEntries {
            state.localReputations.removeFirst()
            state.evictionCounts.reputations += 1
        }
        state.matchingAttempts.sort(by: workMatchingAttemptSort)
        while state.matchingAttempts.count > state.configuration.maximumRetainedMatchingAttempts {
            state.matchingAttempts.removeFirst()
            state.evictionCounts.matchingAttempts += 1
        }
        let sourceBound = max(
            state.configuration.maximumRetainedEvidence * 4,
            state.configuration.maximumRetainedEvidence
        )
        while state.processedSourceEventIDs.count > sourceBound {
            state.processedSourceEventIDs.removeFirst()
            state.evictionCounts.processedSourceEventIDs += 1
        }
    }

    func validateWorkCommitmentStateIfEnabled() throws {
        guard let state = workCommitmentState else { return }
        _ = try AgentWorkCommitmentConfiguration(
            maximumActiveDemands: state.configuration.maximumActiveDemands,
            maximumRetainedCommitments: state.configuration.maximumRetainedCommitments,
            maximumRetainedEvidence: state.configuration.maximumRetainedEvidence,
            maximumEvidencePerAgent: state.configuration.maximumEvidencePerAgent,
            maximumReputationEntries: state.configuration.maximumReputationEntries,
            maximumRetainedMatchingAttempts: state.configuration.maximumRetainedMatchingAttempts,
            maximumConcurrentCommitmentsPerAgent:
                state.configuration.maximumConcurrentCommitmentsPerAgent,
            maximumTransitionsPerTick: state.configuration.maximumTransitionsPerTick,
            demandLifetimeTicks: state.configuration.demandLifetimeTicks,
            commitmentLifetimeTicks: state.configuration.commitmentLifetimeTicks,
            reviewIntervalTicks: state.configuration.reviewIntervalTicks,
            recentHistoryWindowTicks: state.configuration.recentHistoryWindowTicks
        )
        guard populationRegistry != nil, lifecycleState != nil, skillState != nil,
              state.demands == state.demands.sorted(by: workDemandSort),
              Set(state.demands.map(\.demandID)).count == state.demands.count,
              state.demands.filter(\.status.isActive).count
                <= state.configuration.maximumActiveDemands,
              state.commitments == state.commitments.sorted(by: workCommitmentSort),
              Set(state.commitments.map(\.commitmentID)).count == state.commitments.count,
              state.commitments.count <= state.configuration.maximumRetainedCommitments,
              state.retainedEvidence == state.retainedEvidence.sorted(by: workEvidenceSort),
              state.retainedEvidence.count <= state.configuration.maximumRetainedEvidence,
              Set(state.retainedEvidence.map(\.sourceEventID)).count
                == state.retainedEvidence.count,
              state.processedSourceEventIDs == state.processedSourceEventIDs.sorted(),
              Set(state.processedSourceEventIDs).count == state.processedSourceEventIDs.count,
              state.lastProcessedSourceEventID.map({ highWater in
                  state.processedSourceEventIDs.last.map { $0 <= highWater } ?? true
              }) ?? state.processedSourceEventIDs.isEmpty,
              state.totalDemandCount >= state.demands.count,
              state.totalCommitmentCount >= state.commitments.count,
              state.totalEvidenceCount
                == state.retainedEvidence.count + state.evictionCounts.evidence,
              state.transitionTick <= tick,
              (0...state.configuration.maximumTransitionsPerTick)
                .contains(state.transitionsAtTick) else {
            throw AgentSessionError.workCommitment(.invalidState("bounds or canonical order"))
        }
        let knownAgents = Set(lifecycleState?.members.map(\.agentID) ?? [])
        guard state.commitments.allSatisfy({
            knownAgents.contains($0.workerID) && $0.startedAtTick <= tick
                && $0.startedEventID.simulationID == simulationID
        }), state.retainedEvidence.allSatisfy({
            knownAgents.contains($0.workerID) && $0.recordedAtTick <= tick
                && $0.sourceEventID.sequence < $0.workEventID.sequence
        }), state.localReputations.allSatisfy({
            knownAgents.contains($0.observerID) && knownAgents.contains($0.workerID)
                && (-100...100).contains($0.score)
        }), state.initializedEventID.simulationID == simulationID,
              state.lastWorkEventID.simulationID == simulationID else {
            throw AgentSessionError.workCommitment(.invalidState("identity or causal references"))
        }
    }

    private func workDemandSort(
        _ lhs: AgentWorkDemandSignal,
        _ rhs: AgentWorkDemandSignal
    ) -> Bool { lhs.demandID < rhs.demandID }

    private func workCommitmentSort(
        _ lhs: AgentWorkCommitment,
        _ rhs: AgentWorkCommitment
    ) -> Bool { lhs.commitmentID < rhs.commitmentID }

    private func workEvidenceSort(_ lhs: AgentWorkEvidence, _ rhs: AgentWorkEvidence) -> Bool {
        if lhs.workEventID != rhs.workEventID { return lhs.workEventID < rhs.workEventID }
        return lhs.workerID < rhs.workerID
    }

    private func workReputationSort(
        _ lhs: AgentLocalWorkReputation,
        _ rhs: AgentLocalWorkReputation
    ) -> Bool {
        if lhs.observerID != rhs.observerID { return lhs.observerID < rhs.observerID }
        if lhs.workerID != rhs.workerID { return lhs.workerID < rhs.workerID }
        return lhs.domain < rhs.domain
    }

    private func workMatchingAttemptSort(
        _ lhs: AgentWorkMatchingAttempt,
        _ rhs: AgentWorkMatchingAttempt
    ) -> Bool {
        if lhs.attemptedAtTick != rhs.attemptedAtTick {
            return lhs.attemptedAtTick < rhs.attemptedAtTick
        }
        if lhs.demandID != rhs.demandID { return lhs.demandID < rhs.demandID }
        return (lhs.selectedWorkerID?.rawValue ?? "") < (rhs.selectedWorkerID?.rawValue ?? "")
    }
}
