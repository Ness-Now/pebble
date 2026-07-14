import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func handlePhysical(_ arguments: [String]) -> PebbleAgentCommandResult {
        let subcommand = arguments.first?.lowercased() ?? "status"
        let usage = "Usage: /lab physical <on|off|status|clear>"
        guard arguments.count == 1 else { return failure(usage) }
        guard var session else { return failure("No active PebbleAgents session.") }
        do {
            switch subcommand {
            case "on":
                guard physicalFeatureEnabled else {
                    return failure(
                        "PebbleAgents physical channel disabled. Set PEBBLELAB_APP_AGENTS_PHYSICAL=1 before launch."
                    )
                }
                try session.setPhysicalEnabled(true)
                self.session = session
                trace("physical=on tick=\(session.tick) mutation=none")
                return success("PebbleAgents physical channel on; World and material state unchanged.")
            case "off":
                try session.setPhysicalEnabled(false)
                self.session = session
                trace("physical=off tick=\(session.tick) mutation=none retained=1")
                return success("PebbleAgents physical channel off; retained evidence preserved.")
            case "clear":
                guard physicalFeatureEnabled else {
                    return failure(
                        "PebbleAgents physical channel disabled. Set PEBBLELAB_APP_AGENTS_PHYSICAL=1 before launch."
                    )
                }
                try session.clearPhysicalState()
                self.session = session
                trace("physical clear tick=\(session.tick) mutation=none")
                return success("PebbleAgents physical state cleared; World and social state preserved.")
            case "status":
                let summary = session.physicalChannelSummary()
                let snapshot = session.physicalChannelSnapshot()
                let latest = snapshot.signals.last
                let perception = latest.flatMap { signal in
                    snapshot.perceptions.last { $0.signalID == signal.signalID }
                }
                let emitted = summary.retainedSignalCount + summary.evictionCounts.signals
                let soundHeard = snapshot.perceptions.filter {
                    $0.soundClarity >= snapshot.configuration.ambiguousThreshold
                }.count
                let gestureSeen = snapshot.perceptions.filter {
                    $0.gestureClarity >= snapshot.configuration.ambiguousThreshold
                }.count
                let message = "physical status gate=\(physicalFeatureEnabled ? "enabled" : "disabled") enabled=\(summary.enabled ? "yes" : "no") pending=\(summary.pendingSignalCount) emitted=\(emitted) latest=\(latest?.signalID.rawValue ?? "none") sender=\(latest?.senderID.rawValue ?? "none") recipient=\(latest?.intendedRecipientID.rawValue ?? "none") fact=\(latest?.factID.rawValue ?? "none") sound=\(perception?.soundClarity ?? 0) gesture=\(perception?.gestureClarity ?? 0) outcome=\(perception?.outcome.rawValue ?? "none") soundHeard=\(soundHeard) gestureSeen=\(gestureSeen) decoded=\(summary.decodedMessageCount) exact=\(summary.exactCount) ambiguous=\(summary.ambiguousCount) missed=\(summary.missedCount) inconclusive=\(summary.inconclusiveCount) expired=\(summary.expiredCount) evicted=\(summary.evictionCounts.signals),\(summary.evictionCounts.perceptions),\(summary.evictionCounts.presentations) events=\(summary.physicalCausalEventCount) digest=\(summary.digest)"
                trace(message)
                return success(message)
            default:
                return failure(usage)
            }
        } catch {
            return failure("PebbleAgents physical command failed: \(error)")
        }
    }

    func physicalObservations(
        world: World,
        snapshot: AgentSessionSnapshot,
        session: AgentSimulationSession
    ) -> [AgentPhysicalSignalObservation] {
        guard session.physicalEnabled else { return [] }
        return physicalSignalAdapter.observe(
            world: world,
            snapshot: session.physicalChannelSnapshot(),
            agents: snapshot.agents,
            atTick: snapshot.tick + 1
        )
    }

    func presentPhysicalSignals(world: World, session: inout AgentSimulationSession) {
        for request in session.claimPhysicalPresentationRequests() {
            world.hooks.playSound(
                "note.flute.12",
                Double(request.sourcePosition.x) + 0.5,
                Double(request.sourcePosition.y) + 1.4,
                Double(request.sourcePosition.z) + 0.5,
                0.6,
                1
            )
            let available = physicalAudioAvailable()
            trace("physical audio signal=\(request.signalID.rawValue) sender=\(request.senderID.rawValue) position=\(positionText(request.sourcePosition)) requested=1 presented=\(available ? 1 : 0) presentation=\(available ? "available" : "unavailable")")
            trace("physical gesture signal=\(request.signalID.rawValue) sender=\(request.senderID.rawValue) source=\(positionText(request.sourcePosition)) pointed=\(positionText(request.pointedPosition)) pose=on expires=\(request.expiresAtTick) mutation=none")
        }
    }

    func tracePhysicalState(at tick: Int) {
        guard let session, session.physicalEnabled else { return }
        let snapshot = session.physicalChannelSnapshot()
        for signal in snapshot.signals where signal.emittedAtTick == tick {
            trace("physical signal tick=\(tick) id=\(signal.signalID.rawValue) sender=\(signal.senderID.rawValue) recipient=\(signal.intendedRecipientID.rawValue) fact=\(signal.factID.rawValue) source=\(positionText(signal.sourcePosition)) pointed=\(positionText(signal.pointedPosition)) emittedEvent=\(signal.emittedEventID.rawValue) status=\(signal.status.rawValue)")
        }
        for perception in snapshot.perceptions where perception.observedAtTick == tick {
            trace("physical perception tick=\(tick) signal=\(perception.signalID.rawValue) observer=\(perception.observerID.rawValue) intended=\(perception.isIntendedRecipient ? 1 : 0) distance=\(perception.distanceManhattan) sound=\(perception.soundClarity) gesture=\(perception.gestureClarity) occlusions=\(perception.opaqueOcclusionCount) los=\(perception.lineOfSight ? 1 : 0) chunksReady=\(perception.chunksReady ? 1 : 0) outcome=\(perception.outcome.rawValue) perceivedEvent=\(perception.perceivedEventID.rawValue) decodedEvent=\(perception.decodedEventID?.rawValue ?? "none") mutation=none")
        }
    }

    func physicalGestureMarkers() -> [PebbleAgentPhysicalGestureMarker] {
        guard let session, session.physicalEnabled else { return [] }
        let snapshot = session.physicalChannelSnapshot()
        return snapshot.presentations.filter {
            $0.presentedAtTick != nil && snapshot.tick <= $0.expiresAtTick
        }.map {
            PebbleAgentPhysicalGestureMarker(
                signalID: $0.signalID.rawValue,
                sourcePosition: $0.sourcePosition,
                pointedPosition: $0.pointedPosition,
                expiresAtTick: $0.expiresAtTick
            )
        }.sorted { $0.signalID < $1.signalID }
    }
}
