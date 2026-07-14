import PebbleAgents

extension PebbleAgentController {
    func handleCooperation(_ arguments: [String]) -> PebbleAgentCommandResult {
        let subcommand = arguments.first?.lowercased() ?? "status"
        let usage = "Usage: /lab cooperation <on|off|status|clear>"
        guard arguments.count == 1 else { return failure(usage) }
        guard var session else { return failure("No active PebbleAgents session.") }
        do {
            switch subcommand {
            case "on":
                guard cooperationFeatureEnabled else {
                    return failure(
                        "PebbleAgents cooperation disabled. Set PEBBLELAB_APP_AGENTS_COOPERATION=1 before launch."
                    )
                }
                guard socialFeatureEnabled, session.socialEnabled else {
                    return failure("PebbleAgents cooperation requires active social information.")
                }
                guard physicalFeatureEnabled, session.physicalEnabled else {
                    return failure("PebbleAgents cooperation requires the active physical channel.")
                }
                guard session.constructionProject != nil else {
                    return failure("PebbleAgents cooperation requires an active construction project.")
                }
                try session.setCooperationEnabled(true)
                self.session = session
                trace("cooperation=on tick=\(session.tick) mutation=none")
                return success(
                    "PebbleAgents cooperation on; economy, natural resources, construction, movement, and survival unchanged."
                )
            case "off":
                try session.setCooperationEnabled(false)
                self.session = session
                trace("cooperation=off tick=\(session.tick) mutation=none retained=1")
                return success(
                    "PebbleAgents cooperation off; material state and causal history preserved."
                )
            case "clear":
                guard cooperationFeatureEnabled else {
                    return failure(
                        "PebbleAgents cooperation disabled. Set PEBBLELAB_APP_AGENTS_COOPERATION=1 before launch."
                    )
                }
                try session.clearCooperationState()
                self.session = session
                trace("cooperation clear tick=\(session.tick) mutation=none")
                return success(
                    "PebbleAgents cooperation state cleared; social, physical, material, project, and causal history preserved."
                )
            case "status":
                let summary = session.cooperationSummary()
                let snapshot = session.cooperationSnapshot()
                let task = snapshot.tasks.last
                let helper = task.flatMap { selected in
                    session.snapshot().agents.first { $0.id == selected.helperID.rawValue }
                }
                let trust = task.map {
                    session.trustScore(
                        sourceAgentId: $0.helperID.rawValue,
                        targetAgentId: $0.issuerID.rawValue
                    )
                } ?? 0
                let reliability = task.flatMap { selected in
                    snapshot.relations.first {
                        $0.issuerID == selected.issuerID && $0.helperID == selected.helperID
                    }?.reliabilityScore
                } ?? 0
                func amount(_ resource: AgentResourceKind, in values: [AgentResourceAmount]) -> Int {
                    values.first { $0.resource == resource }?.quantity ?? 0
                }
                let message = "cooperation status gate=\(cooperationFeatureEnabled ? "enabled" : "disabled") enabled=\(summary.enabled ? "yes" : "no") project=\(session.constructionProject?.projectId ?? "none") tasks=\(summary.taskCount) task=\(task?.taskID.rawValue ?? "none") issuer=\(task?.issuerID.rawValue ?? "none") helper=\(task?.helperID.rawValue ?? "none") resource=\(task?.resource.rawValue ?? "none") requested=\(task?.requestedQuantity ?? 0) contributed=\(task?.contributedQuantity ?? 0) status=\(task?.status.rawValue ?? "none") signal=\(task?.physicalSignalID?.rawValue ?? "none") trust=\(trust) reliability=\(reliability) helperGoal=\(helper?.currentGoal.kind.rawValue ?? "none") offered=\(summary.offeredCount) accepted=\(summary.acceptedCount) active=\(summary.activeCount) completed=\(summary.completedCount) declined=\(summary.declinedCount) expired=\(summary.expiredCount) cancelled=\(summary.cancelledCount) failed=\(summary.failedCount) committedWood=\(amount(.wood, in: summary.committedMaterials)) committedStone=\(amount(.stone, in: summary.committedMaterials)) contributedWood=\(amount(.wood, in: summary.contributedMaterials)) contributedStone=\(amount(.stone, in: summary.contributedMaterials)) reliabilityEdges=\(summary.relationCount) events=\(summary.cooperationCausalEventCount) evictions=\(summary.evictionCounts.tasks),\(summary.evictionCounts.offers),\(summary.evictionCounts.relations) digest=\(summary.digest)"
                trace(message)
                return success(message)
            default:
                return failure(usage)
            }
        } catch {
            return failure("PebbleAgents cooperation command failed: \(error)")
        }
    }

    func traceCooperationState(at tick: Int) {
        guard let session, session.cooperationEnabled else { return }
        let snapshot = session.cooperationSnapshot()
        let agentsByID = Dictionary(
            uniqueKeysWithValues: session.snapshot().agents.map { ($0.id, $0) }
        )
        for task in snapshot.tasks {
            let helper = agentsByID[task.helperID.rawValue]
            let target = helper?.activeResourceTarget.map {
                "\($0.resource.rawValue)@\($0.target.x),\($0.target.y),\($0.target.z)"
            } ?? "none"
            let route = helper?.navigationProgress.route.map {
                "\($0.purpose.rawValue):\(helper?.navigationProgress.routeIndex ?? 0)/\($0.positions.count - 1)@\($0.target.x),\($0.target.y),\($0.target.z)"
            } ?? "none"
            let observedResources = helper?.lastResourceObservations.map {
                "\($0.resource.rawValue)@\($0.target.x),\($0.target.y),\($0.target.z)"
            } ?? []
            let observations = observedResources.isEmpty
                ? "none"
                : observedResources.joined(separator: ",")
            trace("cooperation task tick=\(tick) id=\(task.taskID.rawValue) project=\(task.projectID) issuer=\(task.issuerID.rawValue) helper=\(task.helperID.rawValue) resource=\(task.resource.rawValue) requested=\(task.requestedQuantity) contributed=\(task.contributedQuantity) status=\(task.status.rawValue) fact=\(task.sourceFactID.rawValue) signal=\(task.physicalSignalID?.rawValue ?? "none") offerEvent=\(task.offerPerceptionEventID?.rawValue ?? "none") acceptanceEvent=\(task.acceptanceEventID?.rawValue ?? "none") progressEvent=\(task.latestProgressEventID?.rawValue ?? "none") terminalEvent=\(task.terminalEventID?.rawValue ?? "none") helperPosition=\(helper.map { "\($0.position.x),\($0.position.y),\($0.position.z)" } ?? "none") helperGoal=\(helper?.currentGoal.kind.rawValue ?? "none") helperAction=\(helper?.lastAction?.name ?? "none") helperInventory=\(helper?.resourceInventory.count(of: task.resource) ?? 0) target=\(target) observations=\(observations) route=\(route)")
        }
        for relation in snapshot.relations where relation.lastChangedAtTick == tick {
            trace("cooperation reliability tick=\(tick) issuer=\(relation.issuerID.rawValue) helper=\(relation.helperID.rawValue) score=\(relation.reliabilityScore) completed=\(relation.completedTaskCount) failed=\(relation.failedAcceptedTaskCount) outcome=\(relation.lastOutcome.rawValue) event=\(relation.lastChangeEventID.rawValue)")
        }
    }
}
