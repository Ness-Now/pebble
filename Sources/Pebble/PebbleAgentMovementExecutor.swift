import PebbleAgents
import PebbleCore

struct PebbleAgentMovementExecutor {
    enum ExecutionError: Error {
        case duplicateOutcome(String)
        case missingProbe(String)
        case inconsistentProbe(String)
        case unexpectedProbe(String)
        case finalPositionMismatch(String)
    }

    func apply(
        outcomes: [AgentMovementOutcome],
        probesByAgentId: [String: LabCoreAgentEntity]
    ) throws {
        var seen = Set<String>()
        for outcome in outcomes {
            guard seen.insert(outcome.agentId).inserted else {
                throw ExecutionError.duplicateOutcome(outcome.agentId)
            }
            guard let probe = probesByAgentId[outcome.agentId] else {
                throw ExecutionError.missingProbe(outcome.agentId)
            }
            guard probe.labAgentId == outcome.agentId else {
                throw ExecutionError.inconsistentProbe(outcome.agentId)
            }
        }
        for (id, probe) in probesByAgentId {
            guard probe.labAgentId == id else { throw ExecutionError.inconsistentProbe(id) }
            guard seen.contains(id) else { throw ExecutionError.unexpectedProbe(id) }
        }

        for outcome in outcomes.sorted(by: { $0.agentId < $1.agentId }) where outcome.status == .moved {
            let probe = probesByAgentId[outcome.agentId]!
            probe.prevX = probe.x
            probe.prevY = probe.y
            probe.prevZ = probe.z
            probe.setPos(
                Double(outcome.toPosition.x) + 0.5,
                Double(outcome.toPosition.y),
                Double(outcome.toPosition.z) + 0.5
            )
        }

        for outcome in outcomes where outcome.status == .moved {
            let probe = probesByAgentId[outcome.agentId]!
            guard probe.x == Double(outcome.toPosition.x) + 0.5,
                  probe.y == Double(outcome.toPosition.y),
                  probe.z == Double(outcome.toPosition.z) + 0.5 else {
                throw ExecutionError.finalPositionMismatch(outcome.agentId)
            }
        }
    }
}
