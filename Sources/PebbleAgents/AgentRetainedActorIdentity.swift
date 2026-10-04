/// A derived validation view of existing mortality authority, never a stored
/// identity registry. The mortality owner/checkpoint validator authenticates
/// these records and summaries; a spelling, ordinal range or kinship row alone
/// does not admit a departed executor's retained history.
struct AgentRetainedActorIdentity {
    let activeIDs: Set<AgentID>
    let mortality: AgentMortalityState?

    func permitsHistory(
        for actorID: AgentID,
        at tick: Int,
        eventID: AgentCausalEventID? = nil
    ) -> Bool {
        guard tick >= 0 else { return false }
        if activeIDs.contains(actorID) { return true }
        if let death = mortality?.records.first(where: { $0.agentID == actorID }) {
            guard tick <= death.deathTick else { return false }
            return eventID.map {
                $0.simulationID == death.deathEventID.simulationID
                    && death.registrationEventID.sequence < $0.sequence
                    && $0.sequence < death.deathEventID.sequence
            } ?? true
        }
        if let death = mortality?.compactedDeathSummaries?.first(where: {
            $0.agentID == actorID
        }) {
            guard tick <= death.deathTick else { return false }
            // Compacted mortality proves identity and the terminal boundary,
            // not an independently reconstructible registration/causal prefix.
            return eventID.map {
                $0.simulationID == death.deathEventID.simulationID
                    && $0.sequence < death.deathEventID.sequence
            } ?? true
        }
        return false
    }
}
