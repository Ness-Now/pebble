import PebbleAgents

extension PebbleAgentController {
    func handleCausality(_ arguments: [String]) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab causality <status|tail <1...20>>"
        guard let session else { return failure("No active PebbleAgents session.") }
        guard let command = arguments.first else { return failure(usage) }
        switch command {
        case "status":
            guard arguments.count == 1 else { return failure(usage) }
            let summary = session.causalLedgerSnapshot().summary
            let next = summary.nextSequence.map(String.init) ?? "overflow"
            let first = summary.firstRetainedEventID?.sequence.rawValue.description ?? "none"
            let last = summary.lastRetainedEventID?.sequence.rawValue.description ?? "none"
            let message = "PebbleAgents causality simulationId=\(summary.simulationID.rawValue) simulationTick=\(summary.currentTick.rawValue) nextSequence=\(next) retainedEventCount=\(summary.retainedEventCount) firstRetainedSequence=\(first) lastSequence=\(last) droppedEventCount=\(summary.droppedEventCount) digest=\(summary.digest)"
            trace("causality status \(message)")
            return success(message)
        case "tail":
            guard arguments.count == 2, let limit = Int(arguments[1]), (1...20).contains(limit) else {
                return failure(usage)
            }
            let snapshot = session.causalLedgerSnapshot(tail: limit)
            let lines = snapshot.events.map { event in
                let causes = event.causes.map(\.rawValue).joined(separator: ",")
                return "eventId=\(event.eventID.rawValue) tick=\(event.instant.tick.rawValue) kind=\(event.kind.rawValue) actor=\(event.actorID?.rawValue ?? "none") operation=\(event.operationID?.rawValue ?? "none") causes=\(causes.isEmpty ? "none" : causes) summary=\(event.summary)"
            }
            let message = "PebbleAgents causality tail=\(snapshot.events.count)/\(limit) "
                + lines.joined(separator: " | ")
            trace("causality tail limit=\(limit) returned=\(snapshot.events.count)")
            for line in lines { trace("causality \(line)") }
            return success(message)
        default:
            return failure(usage)
        }
    }
}
