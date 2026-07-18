struct AgentCooperationTaskProposal {
    let task: AgentSharedTask
    let shareIntent: AgentSocialShareIntent
}

struct AgentCooperationTickPlan {
    var proposal: AgentCooperationTaskProposal?
    var offerTaskByHelperID: [String: AgentSharedTaskID]
    var terminalTransitions: [(AgentSharedTaskID, AgentSharedTaskStatus, String)]

    static let disabled = AgentCooperationTickPlan(
        proposal: nil,
        offerTaskByHelperID: [:],
        terminalTransitions: []
    )
}

extension AgentSimulationSession {
    public mutating func setCooperationEnabled(_ enabled: Bool) throws {
        if enabled, !causalLedger.isEnabled {
            throw AgentSessionError.cooperation(.causalLedgerRequired)
        }
        if enabled, !socialEnabled {
            throw AgentSessionError.cooperation(.socialRequired)
        }
        if enabled, !physicalEnabled {
            throw AgentSessionError.cooperation(.physicalRequired)
        }
        if enabled, constructionProject == nil {
            throw AgentSessionError.cooperation(.constructionProjectRequired)
        }
        guard cooperationEnabled != enabled else { return }
        if enabled {
            cooperationEnabled = true
        } else {
            try disableCooperationState(reason: "cooperation disabled")
        }
        recordFeatureToggle(name: "cooperation", enabled: enabled)
    }

    public mutating func clearCooperationState() throws {
        try prevalidateCausalAppend(count: sharedTasks.filter { !$0.status.isTerminal }.count + 1)
        let counts = (
            tasks: sharedTasks.count,
            offers: sharedTaskOffers.count,
            relations: cooperationRelations.count
        )
        for taskID in sharedTasks.filter({ !$0.status.isTerminal }).map(\.taskID).sorted() {
            try transitionTask(
                taskID: taskID,
                to: .cancelled,
                reason: "cooperation state cleared"
            )
        }
        releaseCooperationAgentState(reason: "cooperation state cleared")
        sharedTasks.removeAll()
        sharedTaskOffers.removeAll()
        cooperationRelations.removeAll()
        cooperationEvictionCounts = AgentCooperationEvictionCounts()
        lastCooperationOfferTickByIssuerID.removeAll()
        _ = try recordCausalEvent(
            kind: .cooperationStateCleared,
            origin: .controllerCommand,
            payload: .cooperationClear(
                tasks: counts.tasks,
                offers: counts.offers,
                relations: counts.relations
            ),
            summary: "cooperation state cleared"
        )
    }

    public func cooperationSnapshot() -> AgentCooperationSnapshot {
        cooperationSnapshot(tasks: sharedTasks, offers: sharedTaskOffers, relations: cooperationRelations)
    }

    public func cooperationSnapshot(for agentID: AgentID) -> AgentCooperationSnapshot {
        let tasks = sharedTasks.filter {
            $0.issuerID == agentID || $0.helperID == agentID
        }
        let taskIDs = Set(tasks.map(\.taskID))
        let offers = sharedTaskOffers.filter {
            taskIDs.contains($0.taskID) && ($0.issuerID == agentID || $0.helperID == agentID)
        }
        let relations = cooperationRelations.filter {
            $0.issuerID == agentID || $0.helperID == agentID
        }
        return cooperationSnapshot(tasks: tasks, offers: offers, relations: relations)
    }

    public func cooperationSummary() -> AgentCooperationSummary {
        let snapshot = cooperationSnapshot()
        func count(_ status: AgentSharedTaskStatus) -> Int {
            snapshot.tasks.filter { $0.status == status }.count
        }
        return AgentCooperationSummary(
            enabled: snapshot.enabled,
            taskCount: snapshot.tasks.count,
            offeredCount: count(.offered),
            acceptedCount: count(.accepted),
            activeCount: count(.active),
            completedCount: count(.completed),
            declinedCount: count(.declined),
            expiredCount: count(.expired),
            cancelledCount: count(.cancelled),
            failedCount: count(.failed),
            supersededCount: count(.superseded),
            committedMaterials: snapshot.committedMaterials,
            contributedMaterials: snapshot.contributedMaterials,
            relationCount: snapshot.relations.count,
            cooperationCausalEventCount: snapshot.cooperationCausalEventCount,
            evictionCounts: snapshot.evictionCounts,
            digest: snapshot.digest
        )
    }

    public func uncommittedConstructionDemand() -> AgentConstructionDemand? {
        guard let actual = constructionDemand() else { return nil }
        let missing = actual.missing.compactMap { amount -> AgentResourceAmount? in
            let reserved = sharedTasks.filter {
                $0.projectID == actual.projectId
                    && $0.resource == amount.resource
                    && $0.status.reservesDemand
            }.reduce(0) { $0 + $1.remainingQuantity }
            let quantity = max(0, amount.quantity - reserved)
            return quantity > 0
                ? AgentResourceAmount(resource: amount.resource, quantity: quantity)
                : nil
        }
        return AgentConstructionDemand(projectId: actual.projectId, missing: missing)
    }

    public func activeSharedTask(for agentId: String) -> AgentSharedTask? {
        sharedTasks.filter {
            $0.helperID.rawValue == agentId
                && ($0.status == .accepted || $0.status == .active)
        }.sorted(by: taskSort).first
    }

    func pendingSharedTaskOffer(for agentId: String) -> AgentSharedTask? {
        sharedTasks.filter {
            $0.helperID.rawValue == agentId && $0.status == .offered
        }.sorted(by: taskSort).first
    }

    func cooperationEligibleResources(for state: AgentSessionAgentState) -> [AgentResourceKind]? {
        guard cooperationEnabled, !isMigratingAgent(state.id),
              let task = activeSharedTask(for: state.id) else { return nil }
        return task.remainingQuantity > 0 ? [task.resource] : []
    }

    func hasActiveCooperationTask(_ state: AgentSessionAgentState) -> Bool {
        !isMigratingAgent(state.id) && activeSharedTask(for: state.id) != nil
    }

    func shouldConsiderCooperationOffer(_ state: AgentSessionAgentState) -> Bool {
        guard cooperationEnabled, !isMigratingAgent(state.id),
              let task = pendingSharedTaskOffer(for: state.id) else {
            return false
        }
        return tick + 1 <= task.offerExpiresAtTick && !isSociallyUrgent(state)
    }

    func canAcceptCooperationOffer(_ state: AgentSessionAgentState) -> Bool {
        let stageEligible = dependentCareState == nil || {
            guard let agentID = AgentID(rawValue: state.id) else { return false }
            return permitsStageCapability(.cooperateAsWorker, for: agentID)
        }()
        guard !isMigratingAgent(state.id),
              stageEligible,
              let task = pendingSharedTaskOffer(for: state.id),
              tick + 1 <= task.offerExpiresAtTick,
              !isSociallyUrgent(state),
              activeSharedTask(for: state.id) == nil,
              statesById[task.issuerID.rawValue] != nil,
              constructionProject?.projectId == task.projectID,
              constructionProject?.builderAgentId == task.issuerID.rawValue,
              trustScore(
                  sourceAgentId: state.id,
                  targetAgentId: task.issuerID.rawValue
              ) >= configuration.cooperationConfiguration.minimumTrustToAccept else {
            return false
        }
        return true
    }

    func cooperationDeliveryIsCommitted(_ state: AgentSessionAgentState) -> Bool {
        guard cooperationEnabled, let task = activeSharedTask(for: state.id) else { return false }
        let carried = state.resourceInventory.count(of: task.resource)
        return carried > 0
    }

    func prepareCooperationTick(at cooperationTick: Int) -> AgentCooperationTickPlan {
        guard cooperationEnabled, socialEnabled, physicalEnabled else { return .disabled }
        var transitions: [(AgentSharedTaskID, AgentSharedTaskStatus, String)] = []
        let actual = constructionDemand()
        for task in sharedTasks.filter({ !$0.status.isTerminal }).sorted(by: taskSort) {
            if constructionProject?.projectId != task.projectID
                || constructionProject?.builderAgentId != task.issuerID.rawValue {
                transitions.append((task.taskID, .cancelled, "construction project unavailable"))
                continue
            }
            let actualMissing = actual?.missing.first { $0.resource == task.resource }?.quantity ?? 0
            if actualMissing < task.remainingQuantity {
                transitions.append((task.taskID, .superseded, "construction demand satisfied elsewhere"))
                continue
            }
            if task.status == .draft || task.status == .signaled || task.status == .offered {
                if cooperationTick > task.offerExpiresAtTick {
                    transitions.append((task.taskID, .expired, "offer lifetime elapsed"))
                }
            } else if task.status == .accepted || task.status == .active,
                      let acceptedAtTick = task.acceptedAtTick,
                      cooperationTick > acceptedAtTick
                        + configuration.cooperationConfiguration.acceptedTaskLifetimeTicks {
                transitions.append((task.taskID, .failed, "accepted task lifetime elapsed"))
            }
        }

        var offers: [String: AgentSharedTaskID] = [:]
        for task in sharedTasks where task.status == .offered
            && cooperationTick > task.createdAtTick
            && !transitions.contains(where: { $0.0 == task.taskID }) {
            offers[task.helperID.rawValue] = task.taskID
        }

        guard transitions.isEmpty,
              let project = constructionProject,
              !isMigratingAgent(project.builderAgentId),
              project.status == .planned || project.status == .acquiringMaterials
                || project.status == .readyToFund,
              !sharedTasks.contains(where: {
                  $0.projectID == project.projectId && !$0.status.isTerminal
              }),
              !sharedTasks.contains(where: {
                  $0.projectID == project.projectId && $0.status == .completed
              }),
              lastCooperationOfferTickByIssuerID[project.builderAgentId].map({
                  cooperationTick - $0 >= configuration.cooperationConfiguration.offerCooldownTicks
              }) != false,
              terminalTaskEvictionCapacityAvailable() else {
            return AgentCooperationTickPlan(
                proposal: nil,
                offerTaskByHelperID: offers,
                terminalTransitions: transitions
            )
        }

        let demand = uncommittedConstructionDemand()
        let resourceOrder: [AgentResourceKind] = [.stone, .wood]
        guard let selectedResource = resourceOrder.first(where: { resource in
            demand?.missing.contains(where: { $0.resource == resource && $0.quantity > 0 }) == true
        }),
        let missing = demand?.missing.first(where: { $0.resource == selectedResource })?.quantity,
        let fact = socialFacts.filter({
            $0.observerID.rawValue == project.builderAgentId
                && $0.resource == selectedResource
                && !$0.isExpired(at: cooperationTick)
        }).sorted(by: { $0.factID < $1.factID }).first,
        let builderID = AgentID(rawValue: project.builderAgentId),
        let builder = statesById[project.builderAgentId] else {
            return AgentCooperationTickPlan(
                proposal: nil,
                offerTaskByHelperID: offers,
                terminalTransitions: transitions
            )
        }

        let helpers = sortedIds.compactMap {
            helperId -> (AgentID, Int, Int, Int, Int)? in
            guard helperId != project.builderAgentId,
                  !isMigratingAgent(helperId),
                  let helperID = AgentID(rawValue: helperId),
                  permitsStageCapability(.cooperateAsWorker, for: helperID),
                  let helper = statesById[helperId],
                  !isSociallyUrgent(helper),
                  (skillState == nil || activeCareEngagement(for: helperID) == nil),
                  !hasMaterialTransaction(helper),
                  activeSharedTask(for: helperId) == nil,
                  pendingSharedTaskOffer(for: helperId) == nil else { return nil }
            let distance = manhattanDistance(builder.position, helper.position)
            guard distance <= min(
                configuration.physicalChannelConfiguration.soundRadius,
                configuration.physicalChannelConfiguration.gestureRadius
            ) else { return nil }
            return (
                helperID,
                practiceUnits(agentID: helperID, domain: .materialHandling),
                cooperationReliability(issuerID: builderID, helperID: helperID),
                trustScore(sourceAgentId: helperId, targetAgentId: project.builderAgentId),
                distance
            )
        }.sorted {
            if $0.1 != $1.1 { return $0.1 > $1.1 }
            if $0.2 != $1.2 { return $0.2 > $1.2 }
            if $0.3 != $1.3 { return $0.3 > $1.3 }
            if $0.4 != $1.4 { return $0.4 < $1.4 }
            return $0.0 < $1.0
        }
        guard let helperID = helpers.first?.0 else {
            return AgentCooperationTickPlan(
                proposal: nil,
                offerTaskByHelperID: offers,
                terminalTransitions: transitions
            )
        }
        let quantity = min(configuration.cooperationConfiguration.maximumTaskQuantity, missing)
        let demandDigest = AgentSocialDigest.make(
            "\(project.projectId)|" + (demand?.missing.map {
                "\($0.resource.rawValue):\($0.quantity)"
            }.joined(separator: ",") ?? "none")
        )
        let taskID = AgentSharedTaskID(rawValue: "task-" + AgentSocialDigest.make(
            "\(simulationID.rawValue)|\(cooperationTick)|\(project.projectId)|\(builderID.rawValue)|\(helperID.rawValue)|\(selectedResource.rawValue)|\(quantity)|\(fact.factID.rawValue)"
        ))!
        let task = AgentSharedTask(
            taskID: taskID,
            kind: .deliverConstructionMaterial,
            projectID: project.projectId,
            issuerID: builderID,
            helperID: helperID,
            resource: selectedResource,
            requestedQuantity: quantity,
            contributedQuantity: 0,
            createdAtTick: cooperationTick,
            offerExpiresAtTick: cooperationTick
                + configuration.cooperationConfiguration.offerLifetimeTicks,
            acceptedAtTick: nil,
            startedAtTick: nil,
            completedAtTick: nil,
            status: .draft,
            sourceDemandDigest: demandDigest,
            sourceConstructionEventID: lastConstructionEventID,
            sourceFactID: fact.factID,
            sourceFactEventID: fact.directObservationEventID,
            physicalSignalID: nil,
            offerPerceptionEventID: nil,
            acceptanceEventID: nil,
            latestProgressEventID: nil,
            terminalEventID: nil,
            reason: skillState == nil
                ? "direct builder demand and resource fact"
                : "direct builder demand and resource fact; skill=materialHandling:"
                    + "\(practiceUnits(agentID: helperID, domain: .materialHandling))/"
                    + skillLevel(agentID: helperID, domain: .materialHandling).rawValue
        )
        return AgentCooperationTickPlan(
            proposal: AgentCooperationTaskProposal(
                task: task,
                shareIntent: AgentSocialShareIntent(
                    senderID: builderID,
                    recipientID: helperID,
                    factID: fact.factID
                )
            ),
            offerTaskByHelperID: offers,
            terminalTransitions: transitions
        )
    }

    mutating func prepareAgentsForTerminalCooperationTransitions(
        _ plan: AgentCooperationTickPlan,
        at cooperationTick: Int
    ) -> Set<String> {
        let taskIDs = Set(plan.terminalTransitions.map(\.0))
        let tasks = sharedTasks.filter { taskIDs.contains($0.taskID) }.sorted(by: taskSort)
        for task in tasks {
            releaseTaskAgentState(
                task: task,
                reason: "shared task terminal transition pending",
                startedAtTick: cooperationTick
            )
        }
        return Set(tasks.map { $0.helperID.rawValue })
    }

    mutating func applyCooperationTickPlan(
        _ plan: AgentCooperationTickPlan,
        results: [AgentSessionAgentTickResult]
    ) throws {
        guard cooperationEnabled else { return }
        for transition in plan.terminalTransitions.sorted(by: { $0.0 < $1.0 }) {
            try transitionTask(taskID: transition.0, to: transition.1, reason: transition.2)
        }
        let resultByID = Dictionary(uniqueKeysWithValues: results.map { ($0.agentId, $0) })
        if let proposal = plan.proposal,
           resultByID[proposal.task.issuerID.rawValue]?.action.name == "share_information",
           !sharedTasks.contains(where: { $0.taskID == proposal.task.taskID }) {
            try createSharedTask(proposal.task)
        }
        for helperId in plan.offerTaskByHelperID.keys.sorted() {
            guard let taskID = plan.offerTaskByHelperID[helperId],
                  let action = resultByID[helperId]?.action.name else { continue }
            if action == "accept_task" {
                try acceptSharedTask(taskID: taskID)
            } else if action == "decline_task" {
                try transitionTask(
                    taskID: taskID,
                    to: .declined,
                    reason: "helper declined offer"
                )
            }
        }
        for result in results.sorted(by: { $0.agentId < $1.agentId }) {
            guard let task = activeSharedTask(for: result.agentId), task.status == .accepted,
                  ["approach_resource", "harvest_block", "return_home", "deliver_resource"]
                    .contains(result.action.name) else { continue }
            try startSharedTask(taskID: task.taskID)
        }
    }

    mutating func markSharedTaskSignaled(
        envelope: AgentCooperationOfferEnvelope,
        emittedEventID: AgentCausalEventID
    ) throws {
        guard cooperationEnabled,
              let index = sharedTasks.firstIndex(where: { $0.taskID == envelope.taskID }),
              sharedTasks[index].status == .draft,
              sharedTasks[index].issuerID == envelope.issuerID,
              sharedTasks[index].helperID == envelope.intendedHelperID,
              sharedTasks[index].projectID == envelope.projectID,
              sharedTasks[index].resource == envelope.resource,
              sharedTasks[index].requestedQuantity == envelope.quantity,
              sharedTasks[index].sourceFactID == envelope.sourceFactID else {
            throw AgentSessionError.cooperation(.invalidOffer(envelope.taskID.rawValue))
        }
        sharedTasks[index].physicalSignalID = envelope.signalID
        sharedTasks[index].status = .signaled
        sharedTasks[index].reason = "bounded physical offer emitted"
        let causes = [
            sharedTasks[index].latestProgressEventID,
            sharedTasks[index].sourceFactEventID,
            emittedEventID,
        ].compactMap { $0 }
        let event = try requiredCooperationEvent(
            kind: .sharedTaskSignaled,
            task: sharedTasks[index],
            causes: Array(Set(causes)).sorted(),
            reason: sharedTasks[index].reason
        )
        sharedTasks[index].latestProgressEventID = event.eventID
        lastCooperationOfferTickByIssuerID[envelope.issuerID.rawValue] = tick
    }

    mutating func markSharedTaskOffered(
        envelope: AgentCooperationOfferEnvelope,
        perceptionEventID: AgentCausalEventID
    ) throws {
        guard cooperationEnabled,
              let index = sharedTasks.firstIndex(where: { $0.taskID == envelope.taskID }),
              sharedTasks[index].status == .signaled,
              sharedTasks[index].physicalSignalID == envelope.signalID,
              tick <= sharedTasks[index].offerExpiresAtTick,
              constructionProject?.projectId == sharedTasks[index].projectID,
              constructionProject?.builderAgentId == sharedTasks[index].issuerID.rawValue,
              statesById[sharedTasks[index].helperID.rawValue] != nil else { return }
        sharedTasks[index].status = .offered
        sharedTasks[index].offerPerceptionEventID = perceptionEventID
        sharedTasks[index].reason = "intended helper perceived exact physical offer"
        let causes = [
            sharedTasks[index].latestProgressEventID,
            perceptionEventID,
        ].compactMap { $0 }
        let event = try requiredCooperationEvent(
            kind: .sharedTaskOffered,
            task: sharedTasks[index],
            causes: Array(Set(causes)).sorted(),
            reason: sharedTasks[index].reason
        )
        sharedTasks[index].latestProgressEventID = event.eventID
        sharedTaskOffers.append(AgentSharedTaskOffer(
            taskID: envelope.taskID,
            signalID: envelope.signalID,
            issuerID: envelope.issuerID,
            helperID: envelope.intendedHelperID,
            offeredAtTick: tick,
            expiresAtTick: sharedTasks[index].offerExpiresAtTick,
            exactPerceptionEventID: perceptionEventID
        ))
        enforceOfferBound()
    }

    mutating func applyCooperationDeliveryProgress(
        outcome: AgentDeliveryOutcome,
        deliveryEventID: AgentCausalEventID
    ) throws {
        guard cooperationEnabled, outcome.status == .succeeded,
              let task = activeSharedTask(for: outcome.agentId),
              let index = sharedTasks.firstIndex(where: { $0.taskID == task.taskID }) else {
            return
        }
        let delivered = outcome.transferred.first { $0.resource == task.resource }?.quantity ?? 0
        let credited = min(task.remainingQuantity, delivered)
        guard credited > 0 else { return }
        sharedTasks[index].contributedQuantity += credited
        sharedTasks[index].reason = "successful camp delivery credited \(credited) \(task.resource.rawValue)"
        let progressCauses = [
            sharedTasks[index].acceptanceEventID,
            sharedTasks[index].latestProgressEventID,
            deliveryEventID,
        ].compactMap { $0 }
        let progress = try requiredCooperationEvent(
            kind: .sharedTaskProgress,
            task: sharedTasks[index],
            causes: Array(Set(progressCauses)).sorted(),
            reason: sharedTasks[index].reason
        )
        sharedTasks[index].latestProgressEventID = progress.eventID
        guard sharedTasks[index].contributedQuantity == sharedTasks[index].requestedQuantity,
              campStock.count(of: sharedTasks[index].resource)
                >= sharedTasks[index].contributedQuantity else { return }
        sharedTasks[index].status = .completed
        sharedTasks[index].completedAtTick = tick
        sharedTasks[index].reason = "requested material delivered to real camp stock"
        let completed = try requiredCooperationEvent(
            kind: .sharedTaskCompleted,
            task: sharedTasks[index],
            causes: [progress.eventID],
            reason: sharedTasks[index].reason
        )
        sharedTasks[index].terminalEventID = completed.eventID
        try applyCooperationReliability(
            taskIndex: index,
            requestedDelta: configuration.cooperationConfiguration.completionReliabilityDelta,
            cause: completed.eventID
        )
    }

    func completedCooperationCauses(for projectID: String) -> [AgentCausalEventID] {
        sharedTasks.filter {
            $0.projectID == projectID && $0.status == .completed
        }.compactMap(\.terminalEventID).sorted()
    }

    private func cooperationSnapshot(
        tasks: [AgentSharedTask],
        offers: [AgentSharedTaskOffer],
        relations: [AgentCooperationRelation]
    ) -> AgentCooperationSnapshot {
        let orderedTasks = tasks.sorted(by: taskSort)
        let orderedOffers = offers.sorted {
            if $0.offeredAtTick != $1.offeredAtTick { return $0.offeredAtTick < $1.offeredAtTick }
            return $0.taskID < $1.taskID
        }
        let orderedRelations = relations.sorted { $0.relationID < $1.relationID }
        let committed = AgentResourceAmounts.normalize(orderedTasks.filter {
            $0.status.reservesDemand
        }.map {
            AgentResourceAmount(resource: $0.resource, quantity: $0.remainingQuantity)
        })
        let contributed = AgentResourceAmounts.normalize(orderedTasks.filter {
            $0.contributedQuantity > 0
        }.map {
            AgentResourceAmount(resource: $0.resource, quantity: $0.contributedQuantity)
        })
        let eventCount = causalLedger.events.filter { $0.kind.isCooperation }.count
        let canonical = [
            "enabled=\(cooperationEnabled ? 1 : 0)",
            orderedTasks.map {
                "t|\($0.taskID.rawValue)|\($0.projectID)|\($0.issuerID.rawValue)|\($0.helperID.rawValue)|\($0.resource.rawValue)|\($0.requestedQuantity)|\($0.contributedQuantity)|\($0.status.rawValue)|\($0.createdAtTick)|\($0.physicalSignalID?.rawValue ?? "none")|\($0.offerPerceptionEventID?.rawValue ?? "none")|\($0.acceptanceEventID?.rawValue ?? "none")|\($0.terminalEventID?.rawValue ?? "none")"
            }.joined(separator: ";"),
            orderedOffers.map {
                "o|\($0.taskID.rawValue)|\($0.signalID.rawValue)|\($0.offeredAtTick)|\($0.exactPerceptionEventID.rawValue)"
            }.joined(separator: ";"),
            orderedRelations.map {
                "r|\($0.relationID.rawValue)|\($0.reliabilityScore)|\($0.completedTaskCount)|\($0.failedAcceptedTaskCount)|\($0.lastOutcome.rawValue)|\($0.lastChangedAtTick)"
            }.joined(separator: ";"),
            "evicted=\(cooperationEvictionCounts.tasks),\(cooperationEvictionCounts.offers),\(cooperationEvictionCounts.relations)",
            "events=\(eventCount)",
        ].joined(separator: "|")
        return AgentCooperationSnapshot(
            enabled: cooperationEnabled,
            tick: tick,
            configuration: configuration.cooperationConfiguration,
            tasks: orderedTasks,
            offers: orderedOffers,
            relations: orderedRelations,
            committedMaterials: committed,
            contributedMaterials: contributed,
            evictionCounts: cooperationEvictionCounts,
            cooperationCausalEventCount: eventCount,
            digest: AgentSocialDigest.make(canonical)
        )
    }

    mutating func disableCooperationState(reason: String) throws {
        try prevalidateCausalAppend(count: sharedTasks.filter { !$0.status.isTerminal }.count)
        for taskID in sharedTasks.filter({ !$0.status.isTerminal }).map(\.taskID).sorted() {
            try transitionTask(taskID: taskID, to: .cancelled, reason: reason)
        }
        cooperationEnabled = false
        releaseCooperationAgentState(reason: reason)
    }

    private mutating func releaseCooperationAgentState(reason: String) {
        let helperIDs = Set(sharedTasks.map { $0.helperID.rawValue })
        reservationsByTarget = reservationsByTarget.filter { !helperIDs.contains($0.value.agentId) }
        for helperId in helperIDs.sorted() {
            guard var state = statesById[helperId] else { continue }
            state.activeResourceTarget = nil
            state.navigationProgress = AgentNavigationProgress(lastInvalidation: .targetMissing)
            if state.currentGoal.kind == .considerSharedTask
                || state.currentGoal.kind == .fulfillSharedTask {
                state.currentGoal = AgentGoal(
                    kind: .idle,
                    reason: reason,
                    startedAtTick: tick,
                    urgency: 0
                )
            }
            statesById[helperId] = state
        }
    }

    private mutating func createSharedTask(_ task: AgentSharedTask) throws {
        try requireStageCapability(.cooperateAsWorker, for: task.helperID)
        guard cooperationEnabled,
              !sharedTasks.contains(where: { $0.taskID == task.taskID }),
              task.issuerID.rawValue == constructionProject?.builderAgentId,
              task.projectID == constructionProject?.projectId,
              task.helperID != task.issuerID,
              statesById[task.helperID.rawValue] != nil,
              task.resource == .wood || task.resource == .stone,
              (1...configuration.cooperationConfiguration.maximumTaskQuantity)
                .contains(task.requestedQuantity),
              socialFacts.contains(where: {
                  $0.factID == task.sourceFactID
                    && $0.observerID == task.issuerID
                    && $0.directObservationEventID == task.sourceFactEventID
              }),
              terminalTaskEvictionCapacityAvailable() else {
            throw AgentSessionError.cooperation(.invalidTask(task.taskID.rawValue))
        }
        let causes = [task.sourceConstructionEventID, task.sourceFactEventID]
            .compactMap { $0 }
        let event = try requiredCooperationEvent(
            kind: .sharedTaskCreated,
            task: task,
            causes: Array(Set(causes)).sorted(),
            reason: task.reason
        )
        var created = task
        created.latestProgressEventID = event.eventID
        sharedTasks.append(created)
        enforceTaskBound()
    }

    private mutating func acceptSharedTask(taskID: AgentSharedTaskID) throws {
        guard let index = sharedTasks.firstIndex(where: { $0.taskID == taskID }),
              sharedTasks[index].status == .offered,
              let helper = statesById[sharedTasks[index].helperID.rawValue],
              canAcceptCooperationOffer(helper) else {
            throw AgentSessionError.cooperation(.invalidTransition(taskID.rawValue))
        }
        sharedTasks[index].status = .accepted
        sharedTasks[index].acceptedAtTick = tick
        sharedTasks[index].reason = "helper voluntarily accepted on later tick"
        let causes = [
            sharedTasks[index].offerPerceptionEventID,
            lastDecisionEventByAgentID[sharedTasks[index].helperID],
        ].compactMap { $0 }
        let event = try requiredCooperationEvent(
            kind: .sharedTaskAccepted,
            task: sharedTasks[index],
            causes: Array(Set(causes)).sorted(),
            reason: sharedTasks[index].reason
        )
        sharedTasks[index].acceptanceEventID = event.eventID
        sharedTasks[index].latestProgressEventID = event.eventID
    }

    private mutating func startSharedTask(taskID: AgentSharedTaskID) throws {
        guard let index = sharedTasks.firstIndex(where: { $0.taskID == taskID }),
              sharedTasks[index].status == .accepted else { return }
        sharedTasks[index].status = .active
        sharedTasks[index].startedAtTick = tick
        sharedTasks[index].reason = "helper began correlated material action"
        let causes = [
            sharedTasks[index].acceptanceEventID,
            lastDecisionEventByAgentID[sharedTasks[index].helperID],
        ].compactMap { $0 }
        let event = try requiredCooperationEvent(
            kind: .sharedTaskStarted,
            task: sharedTasks[index],
            causes: Array(Set(causes)).sorted(),
            reason: sharedTasks[index].reason
        )
        sharedTasks[index].latestProgressEventID = event.eventID
        lastOutcomeEventByAgentID[sharedTasks[index].helperID] = event.eventID
    }

    private mutating func transitionTask(
        taskID: AgentSharedTaskID,
        to status: AgentSharedTaskStatus,
        reason: String
    ) throws {
        guard status.isTerminal,
              let index = sharedTasks.firstIndex(where: { $0.taskID == taskID }),
              !sharedTasks[index].status.isTerminal else { return }
        let prior = sharedTasks[index].status
        sharedTasks[index].status = status
        sharedTasks[index].reason = String(reason.prefix(96))
        let kind: AgentCausalEventKind
        switch status {
        case .declined: kind = .sharedTaskDeclined
        case .expired: kind = .sharedTaskExpired
        case .cancelled: kind = .sharedTaskCancelled
        case .failed: kind = .sharedTaskFailed
        case .superseded: kind = .sharedTaskSuperseded
        default:
            throw AgentSessionError.cooperation(.invalidTransition(taskID.rawValue))
        }
        let causes = [
            sharedTasks[index].acceptanceEventID,
            sharedTasks[index].offerPerceptionEventID,
            sharedTasks[index].latestProgressEventID,
        ].compactMap { $0 }
        let event = try requiredCooperationEvent(
            kind: kind,
            task: sharedTasks[index],
            causes: Array(Set(causes)).sorted(),
            reason: sharedTasks[index].reason
        )
        sharedTasks[index].terminalEventID = event.eventID
        if status == .failed && (prior == .accepted || prior == .active) {
            try applyCooperationReliability(
                taskIndex: index,
                requestedDelta: configuration.cooperationConfiguration.failureReliabilityDelta,
                cause: event.eventID
            )
        }
        releaseTaskAgentState(task: sharedTasks[index], reason: reason)
    }

    private mutating func releaseTaskAgentState(
        task: AgentSharedTask,
        reason: String,
        startedAtTick: Int? = nil
    ) {
        guard var helper = statesById[task.helperID.rawValue] else { return }
        releaseReservation(for: helper)
        helper.activeResourceTarget = nil
        helper.navigationProgress = AgentNavigationProgress(lastInvalidation: .targetMissing)
        if helper.currentGoal.kind == .considerSharedTask
            || helper.currentGoal.kind == .fulfillSharedTask {
            helper.currentGoal = AgentGoal(
                kind: .idle,
                reason: String(reason.prefix(96)),
                startedAtTick: startedAtTick ?? tick,
                urgency: 0
            )
        }
        statesById[helper.id] = helper
    }

    private mutating func applyCooperationReliability(
        taskIndex: Int,
        requestedDelta: Int,
        cause: AgentCausalEventID
    ) throws {
        let task = sharedTasks[taskIndex]
        let relationID = AgentCooperationRelationID(
            rawValue: "cooperation-\(task.issuerID.rawValue)-to-\(task.helperID.rawValue)"
        )!
        let existing = cooperationRelations.firstIndex { $0.relationID == relationID }
        let before = existing.map { cooperationRelations[$0].reliabilityScore } ?? 0
        let after = min(
            configuration.cooperationConfiguration.maximumReliability,
            max(configuration.cooperationConfiguration.minimumReliability, before + requestedDelta)
        )
        let actualDelta = after - before
        let event = try requiredCooperationReliabilityEvent(
            relationID: relationID,
            task: task,
            before: before,
            delta: actualDelta,
            after: after,
            cause: cause
        )
        if let existing {
            cooperationRelations[existing].reliabilityScore = after
            cooperationRelations[existing].completedTaskCount += task.status == .completed ? 1 : 0
            cooperationRelations[existing].failedAcceptedTaskCount += task.status == .failed ? 1 : 0
            cooperationRelations[existing].lastOutcome = task.status
            cooperationRelations[existing].lastChangedAtTick = tick
            cooperationRelations[existing].lastChangeEventID = event.eventID
        } else {
            cooperationRelations.append(AgentCooperationRelation(
                relationID: relationID,
                issuerID: task.issuerID,
                helperID: task.helperID,
                reliabilityScore: after,
                completedTaskCount: task.status == .completed ? 1 : 0,
                failedAcceptedTaskCount: task.status == .failed ? 1 : 0,
                lastOutcome: task.status,
                lastChangedAtTick: tick,
                lastChangeEventID: event.eventID
            ))
            enforceRelationBound()
        }
    }

    private func cooperationReliability(issuerID: AgentID, helperID: AgentID) -> Int {
        cooperationRelations.first {
            $0.issuerID == issuerID && $0.helperID == helperID
        }?.reliabilityScore ?? 0
    }

    private mutating func requiredCooperationEvent(
        kind: AgentCausalEventKind,
        task: AgentSharedTask,
        causes: [AgentCausalEventID],
        reason: String
    ) throws -> AgentCausalEvent {
        let actorID: AgentID
        switch kind {
        case .sharedTaskAccepted, .sharedTaskDeclined, .sharedTaskStarted,
             .sharedTaskProgress, .sharedTaskCompleted, .sharedTaskFailed:
            actorID = task.helperID
        default:
            actorID = task.issuerID
        }
        guard let event = try recordCausalEvent(
            kind: kind,
            origin: .cooperationTransition,
            actorID: actorID,
            subjectID: task.helperID,
            causes: causes,
            payload: .cooperationTask(
                taskID: task.taskID.rawValue,
                projectID: task.projectID,
                issuerID: task.issuerID.rawValue,
                helperID: task.helperID.rawValue,
                resource: task.resource,
                requested: task.requestedQuantity,
                contributed: task.contributedQuantity,
                status: task.status.rawValue,
                reason: String(reason.prefix(96))
            ),
            summary: "shared task \(kind.rawValue) \(task.taskID.rawValue)"
        ) else { throw AgentSessionError.cooperation(.causalLedgerRequired) }
        return event
    }

    private mutating func requiredCooperationReliabilityEvent(
        relationID: AgentCooperationRelationID,
        task: AgentSharedTask,
        before: Int,
        delta: Int,
        after: Int,
        cause: AgentCausalEventID
    ) throws -> AgentCausalEvent {
        guard let event = try recordCausalEvent(
            kind: .cooperationReliabilityChanged,
            origin: .cooperationTransition,
            actorID: task.issuerID,
            subjectID: task.helperID,
            causes: [cause],
            payload: .cooperationReliability(
                relationID: relationID.rawValue,
                taskID: task.taskID.rawValue,
                before: before,
                delta: delta,
                after: after
            ),
            summary: "cooperation reliability \(task.issuerID.rawValue)>\(task.helperID.rawValue) \(before)>\(after)"
        ) else { throw AgentSessionError.cooperation(.causalLedgerRequired) }
        return event
    }

    private func terminalTaskEvictionCapacityAvailable() -> Bool {
        sharedTasks.count < configuration.cooperationConfiguration.maximumTasks
            || sharedTasks.contains(where: { $0.status.isTerminal })
    }

    private mutating func enforceTaskBound() {
        let excess = sharedTasks.count - configuration.cooperationConfiguration.maximumTasks
        guard excess > 0 else { return }
        let removable = sharedTasks.indices.filter {
            sharedTasks[$0].status.isTerminal
        }.sorted {
            let lhs = sharedTasks[$0]
            let rhs = sharedTasks[$1]
            let lhsTick = lhs.completedAtTick ?? lhs.acceptedAtTick ?? lhs.createdAtTick
            let rhsTick = rhs.completedAtTick ?? rhs.acceptedAtTick ?? rhs.createdAtTick
            if lhsTick != rhsTick { return lhsTick < rhsTick }
            return lhs.taskID < rhs.taskID
        }
        guard removable.count >= excess else { return }
        for index in removable.prefix(excess).sorted(by: >) { sharedTasks.remove(at: index) }
        cooperationEvictionCounts.tasks += excess
    }

    private mutating func enforceOfferBound() {
        let excess = sharedTaskOffers.count - configuration.cooperationConfiguration.maximumOffers
        guard excess > 0 else { return }
        sharedTaskOffers.sort {
            if $0.offeredAtTick != $1.offeredAtTick { return $0.offeredAtTick < $1.offeredAtTick }
            return $0.taskID < $1.taskID
        }
        sharedTaskOffers.removeFirst(excess)
        cooperationEvictionCounts.offers += excess
    }

    private mutating func enforceRelationBound() {
        let excess = cooperationRelations.count
            - configuration.cooperationConfiguration.maximumRelations
        guard excess > 0 else { return }
        cooperationRelations.sort {
            if $0.lastChangedAtTick != $1.lastChangedAtTick {
                return $0.lastChangedAtTick < $1.lastChangedAtTick
            }
            return $0.relationID < $1.relationID
        }
        cooperationRelations.removeFirst(excess)
        cooperationEvictionCounts.relations += excess
    }

    private func taskSort(_ lhs: AgentSharedTask, _ rhs: AgentSharedTask) -> Bool {
        if lhs.createdAtTick != rhs.createdAtTick { return lhs.createdAtTick < rhs.createdAtTick }
        return lhs.taskID < rhs.taskID
    }
}

extension AgentCausalEventKind {
    var isCooperation: Bool {
        switch self {
        case .sharedTaskCreated, .sharedTaskSignaled, .sharedTaskOffered,
             .sharedTaskAccepted, .sharedTaskDeclined, .sharedTaskStarted,
             .sharedTaskProgress, .sharedTaskCompleted, .sharedTaskExpired,
             .sharedTaskCancelled, .sharedTaskFailed, .sharedTaskSuperseded,
             .cooperationReliabilityChanged, .cooperationStateCleared:
            return true
        default:
            return false
        }
    }
}
