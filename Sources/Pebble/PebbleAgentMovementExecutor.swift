import PebbleAgents
import PebbleCore

struct PebbleAgentMovementExecutor {
    enum ExecutionError: Error {
        case duplicateOutcome(String)
        case missingProbe(String)
        case inconsistentProbe(String)
        case unexpectedProbe(String)
        case finalPositionMismatch(String)
        case rollbackPerformed(String)
    }

    private struct ProbePosition {
        let x: Double
        let y: Double
        let z: Double
        let prevX: Double
        let prevY: Double
        let prevZ: Double
    }

    func apply(
        outcomes: [AgentMovementOutcome],
        probesByAgentId: [String: LabCoreAgentEntity],
        postApplyValidation: () throws -> Void = {}
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

        let moved = outcomes.sorted(by: { $0.agentId < $1.agentId }).filter { $0.status == .moved }
        let originals = Dictionary(uniqueKeysWithValues: moved.map { outcome in
            let probe = probesByAgentId[outcome.agentId]!
            return (outcome.agentId, ProbePosition(
                x: probe.x, y: probe.y, z: probe.z,
                prevX: probe.prevX, prevY: probe.prevY, prevZ: probe.prevZ
            ))
        })

        do {
            for outcome in moved {
                let probe = probesByAgentId[outcome.agentId]!
                let source = originals[outcome.agentId]!
                probe.setPos(
                    Double(outcome.toPosition.x) + 0.5,
                    Double(outcome.toPosition.y),
                    Double(outcome.toPosition.z) + 0.5
                )
                probe.prevX = source.x
                probe.prevY = source.y
                probe.prevZ = source.z
            }

            for outcome in moved {
                let probe = probesByAgentId[outcome.agentId]!
                guard probe.x == Double(outcome.toPosition.x) + 0.5,
                      probe.y == Double(outcome.toPosition.y),
                      probe.z == Double(outcome.toPosition.z) + 0.5 else {
                    throw ExecutionError.finalPositionMismatch(outcome.agentId)
                }
            }
            try postApplyValidation()
        } catch {
            for outcome in moved {
                guard let original = originals[outcome.agentId],
                      let probe = probesByAgentId[outcome.agentId] else { continue }
                probe.setPos(original.x, original.y, original.z)
                probe.prevX = original.prevX
                probe.prevY = original.prevY
                probe.prevZ = original.prevZ
            }
            let restored = moved.allSatisfy { outcome in
                guard let original = originals[outcome.agentId],
                      let probe = probesByAgentId[outcome.agentId] else { return false }
                return probe.x == original.x && probe.y == original.y && probe.z == original.z
                    && probe.prevX == original.prevX && probe.prevY == original.prevY && probe.prevZ == original.prevZ
            }
            if restored {
                throw ExecutionError.rollbackPerformed(String(describing: error))
            }
            throw ExecutionError.rollbackPerformed("rollback verification failed after \(error)")
        }
    }
}
