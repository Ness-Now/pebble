extension AgentSimulationSession {
    func prevalidateCausalAppend(count: Int) throws {
        try causalLedger.prevalidateAppend(count: count)
    }

    @discardableResult
    mutating func recordCausalEvent(
        kind: AgentCausalEventKind,
        origin: AgentCausalOrigin,
        actorID: AgentID? = nil,
        subjectID: AgentID? = nil,
        operationID: AgentOperationID? = nil,
        causes: [AgentCausalEventID] = [],
        payload: AgentCausalPayload,
        summary: String
    ) throws -> AgentCausalEvent? {
        try causalLedger.append(
            instant: simulationInstant,
            kind: kind,
            origin: origin,
            actorID: actorID,
            subjectID: subjectID,
            operationID: operationID,
            causes: causes,
            payload: payload,
            summary: summary
        )
    }

    mutating func recordFeatureToggle(name: String, enabled: Bool) {
        try! recordCausalEvent(
            kind: .featureToggle,
            origin: .session,
            payload: .feature(name: name, enabled: enabled),
            summary: "\(name) \(enabled ? "enabled" : "disabled")"
        )
    }

    @discardableResult
    mutating func recordAcceptedOperation(
        kind: AgentCausalEventKind,
        agentId: String,
        operationId: String,
        status: String,
        detail: String,
        origin: AgentCausalOrigin = .worldOutcome,
        extraCauses: [AgentCausalEventID] = []
    ) -> AgentCausalEventID? {
        guard let agentID = AgentID(rawValue: agentId) else { return nil }
        let cause: AgentCausalEventID?
        switch kind {
        case .constructionPlacement, .constructionCompletion, .constructionClear:
            cause = lastConstructionEventID
        case .constructionFunding:
            cause = lastOutcomeEventByAgentID[agentID] ?? lastDecisionEventByAgentID[agentID]
        case .interaction, .delivery, .consumption:
            cause = lastOutcomeEventByAgentID[agentID] ?? lastDecisionEventByAgentID[agentID]
        default:
            cause = lastDecisionEventByAgentID[agentID]
        }
        let causes = Array(Set(extraCauses + (cause.map { [$0] } ?? []))).sorted()
        let event = try! recordCausalEvent(
            kind: kind,
            origin: origin,
            actorID: agentID,
            operationID: AgentOperationID(rawValue: operationId),
            causes: Array(causes.prefix(AgentCausalEvent.maximumCauseCount)),
            payload: .operation(status: String(status.prefix(64)), detail: String(detail.prefix(160))),
            summary: "\(kind.rawValue) \(status) actor=\(agentId)"
        )
        guard let eventID = event?.eventID else { return nil }
        lastOutcomeEventByAgentID[agentID] = eventID
        if kind == .constructionFunding || kind == .constructionPlacement
            || kind == .constructionCompletion || kind == .constructionClear {
            lastConstructionEventID = eventID
        }
        return eventID
    }
}
