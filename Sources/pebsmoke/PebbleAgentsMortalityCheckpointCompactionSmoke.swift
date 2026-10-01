import Foundation
@_spi(Testing) import PebbleAgents

/// A small owning regression: existing transitions cause starvation naturally.
/// No injected death, edited durable result or synthetic empty roster.
func runPebbleAgentsMortalityCheckpointCompactionSmoke() {
    var session = careBase("sim-mortality-checkpoint-prefix", causalMaximum: 128)
    try! session.setDependentCareEnabled(true)
    try! session.setMortalityEnabled(true)
    try! session.useLegacyCognitivePhysiologyReplayFixture(
        schemaVersion: AgentCheckpointSchema.dependentCareVersion
    )
    check("mortality prefix non-extinct checkpoint admitted", (try? AgentSimulationSession.validate(session.makeCheckpoint())) != nil
        && session.expectedActiveAgentIDs().count == 3)
    for _ in 0..<256 where !session.expectedActiveAgentIDs().isEmpty {
        _ = try! session.advanceTick()
    }
    let state = session.durableState()
    let ledger = state.causalLedger
    let care = state.dependentCareState!
    let records = state.mortalityState!.records
    if let output = ProcessInfo.processInfo.environment["PEBBLELAB_MORTALITY_PREFIX_STATE"] {
        try! session.durableStateBytes().write(to: URL(fileURLWithPath: output))
    }
    let retained = Set(ledger.events.map(\.eventID))
    check("mortality prefix ordinary starvation reaches extinction", session.expectedActiveAgentIDs().isEmpty
        && records.count == 3 && records.allSatisfy { $0.cause == .starvation })
    check("mortality prefix care boundary is legitimately evicted", ledger.droppedEventCount > 0
        && !retained.contains(care.lastCareEventID)
        && care.lastCareEventID.sequence.rawValue <= ledger.droppedEventCount)
    check("mortality prefix primary death chain remains retained", records.allSatisfy {
        retained.isSuperset(of: [$0.lethalDamageEventID, $0.resourcesRetiredEventID,
            $0.commitmentsResolvedEventID, $0.populationExitEventID, $0.deathEventID])
    })
    check("mortality prefix exits preserve durable care cause", records.allSatisfy { record in
        ledger.events.first { $0.eventID == record.populationExitEventID }?.causes
            .contains(care.lastCareEventID) == true
    })
    let checkpoint = try? session.makeCheckpoint()
    var admitted = false
    if let checkpoint {
        do { admitted = try AgentSimulationSession.validate(checkpoint).valid }
        catch { print("MORTALITY_CHECKPOINT_PREFIX_REFUSAL \(error)") }
    }
    check("mortality prefix checkpoint admits generated causal state", admitted)
    check("mortality prefix restore preserves exact durable state", checkpoint.flatMap {
        try? AgentSimulationSession.restoring($0).durableStateBytes()
    } == (try? session.durableStateBytes()))
    if let checkpoint {
        let victim = records[0]
        let exit = ledger.events.first { $0.eventID == victim.populationExitEventID }!
        let resources = ledger.events.first { $0.eventID == victim.resourcesRetiredEventID }!
        let unrelated = victim.registrationEventID
        func replacing(_ event: AgentCausalEvent, causes: [AgentCausalEventID]? = nil,
            actorID: AgentID? = nil, id: AgentCausalEventID? = nil,
            origin: AgentCausalOrigin? = nil) -> AgentCausalEvent {
            try! AgentCausalEvent(id: id ?? event.eventID, instant: event.instant,
                kind: event.kind, origin: origin ?? event.origin,
                actorID: actorID ?? event.actorID, subjectID: event.subjectID,
                operationID: event.operationID, causes: causes ?? event.causes,
                payload: event.payload, summary: event.summary)
        }
        func attack(_ label: String, replacing event: AgentCausalEvent) {
            check(label, mortalityPrefixRefused(checkpoint, expected: .invalidBound("mortality causal chain")) { state in
                var causal = state["causalLedger"] as! [String: Any]
                var events = causal["events"] as! [[String: Any]]
                let index = events.firstIndex { ($0["sequence"] as! NSNumber).uint64Value == event.sequence.rawValue }!
                events[index] = try! JSONSerialization.jsonObject(with: AgentCheckpointCodec.encode(event)) as! [String: Any]
                causal["events"] = events
                state["causalLedger"] = causal
            })
        }
        attack("mortality prefix unrelated discarded cause refuses", replacing: replacing(exit,
            causes: exit.causes.map { $0 == care.lastCareEventID ? unrelated : $0 }.sorted()))
        attack("mortality prefix extra discarded cause refuses", replacing: replacing(exit,
            causes: (exit.causes + [unrelated]).sorted()))
        attack("mortality prefix wrong retained resource causes refuse", replacing: replacing(resources,
            causes: [unrelated]))
        let lethal = ledger.events.first { $0.eventID == victim.lethalDamageEventID }!
        attack("mortality prefix wrong lethal actor refuses", replacing: replacing(lethal,
            actorID: records[1].agentID))
        check("mortality prefix missing retained primary event refuses", mortalityPrefixRefused(checkpoint,
            expected: .invalidBound("mortality causal chain")) { state in
                var causal = state["causalLedger"] as! [String: Any]
                var events = causal["events"] as! [[String: Any]]
                events.removeAll { ($0["sequence"] as! NSNumber).uint64Value == resources.sequence.rawValue }
                causal["events"] = events
                state["causalLedger"] = causal
            })
        check("mortality prefix false discarded-prefix claim refuses", mortalityPrefixRefused(checkpoint) { state in
            var causal = state["causalLedger"] as! [String: Any]
            causal["droppedEventCount"] = ledger.droppedEventCount + 1
            state["causalLedger"] = causal
        })
        let lateID = AgentCausalEventID(simulationID: session.simulationID,
            sequence: AgentCausalSequence(rawValue: ledger.latestSequence + 1)!)
        let late = replacing(resources, id: lateID)
        check("mortality prefix post-finalization mortality refuses", mortalityPrefixRefused(checkpoint,
            expected: .invalidBound("mortality causal chain")) { state in
                var causal = state["causalLedger"] as! [String: Any]
                var events = causal["events"] as! [[String: Any]]
                events.append(try! JSONSerialization.jsonObject(with: AgentCheckpointCodec.encode(late)) as! [String: Any])
                events.removeFirst()
                causal["events"] = events
                causal["latestSequence"] = ledger.latestSequence + 1
                causal["droppedEventCount"] = ledger.droppedEventCount + 1
                state["causalLedger"] = causal
            })
    }
    print("MORTALITY_CHECKPOINT_PREFIX tick=\(session.tick) deaths=\(records.count) "
        + "latest=\(ledger.latestSequence) dropped=\(ledger.droppedEventCount) "
        + "first=\(ledger.events.first?.sequence.rawValue ?? 0) care=\(care.lastCareEventID.sequence.rawValue)")
}

/// Corruption attacks recompute envelope and retained-event digests, so their
/// refusal must come from semantic admission rather than an outer checksum.
private func mortalityPrefixRefused(_ checkpoint: AgentSessionCheckpoint,
    expected: AgentCheckpointError? = nil, mutate: (inout [String: Any]) -> Void) -> Bool {
    var root = try! JSONSerialization.jsonObject(with: AgentCheckpointCodec.encode(checkpoint)) as! [String: Any]
    var state = root["durableState"] as! [String: Any]
    mutate(&state)
    let decoded = try! AgentCheckpointCodec.decode(AgentSessionDurableState.self,
        from: JSONSerialization.data(withJSONObject: state))
    let bytes = try! AgentCheckpointCodec.encode(decoded)
    let digest = AgentCheckpointDigest.sha256(bytes)
    let simulationDigest = AgentCheckpointDigest.sha256(Data(decoded.clock.simulationID.rawValue.utf8))
    root["durableState"] = try! JSONSerialization.jsonObject(with: bytes)
    root["semanticDigest"] = digest.rawValue
    root["checkpointID"] = "checkpoint-\(simulationDigest.rawValue.prefix(12))-t\(decoded.clock.tick.rawValue)-\(digest.rawValue.prefix(16))"
    let attacked = try! AgentCheckpointCodec.decode(AgentSessionCheckpoint.self,
        from: JSONSerialization.data(withJSONObject: root))
    do { _ = try AgentSimulationSession.validate(attacked); return false }
    catch { return expected.map { (error as? AgentCheckpointError) == $0 } ?? true }
}
