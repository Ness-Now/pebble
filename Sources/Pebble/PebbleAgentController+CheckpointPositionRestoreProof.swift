import Foundation
import PebbleAgents
import PebbleCore

private enum PebbleCheckpointPositionRestoreProofError: Error {
    case failed(String)
}

extension PebbleAgentController {
    func handleCheckpointPositionRestoreProof(
        _ arguments: [String],
        world: World
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab checkpoint position-proof "
            + "<failure <none|after-first-reposition|after-first-missing>"
            + "|stale-save <name>|nonempty-load <name>"
            + "|duplicate-load <name>|park-custody <agentID>|planner>"
        guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1" else {
            return failure(
                "Checkpoint position proof is restricted to disposable Worlds."
            )
        }
        guard activeWorld === world, session != nil else {
            return failure("Checkpoint position proof requires an active session.")
        }
        do {
            guard let command = arguments.first?.lowercased() else {
                return failure(usage)
            }
            switch command {
            case "failure":
                guard arguments.count == 2 else { return failure(usage) }
                switch arguments[1].lowercased() {
                case "none":
                    checkpointPositionRestoreFailurePoint = nil
                case "after-first-reposition":
                    checkpointPositionRestoreFailurePoint =
                        .afterFirstReposition
                case "after-first-missing":
                    checkpointPositionRestoreFailurePoint =
                        .afterFirstMissingCreation
                default:
                    return failure(usage)
                }
                let value = arguments[1].lowercased()
                trace("checkpoint position proof failurePoint=\(value)")
                return success("Checkpoint position proof failure point: \(value).")
            case "stale-save":
                guard arguments.count == 2,
                      AgentCheckpointName(rawValue: arguments[1]) != nil else {
                    return failure(usage)
                }
                return try proveStaleCheckpointSaveRefusal(
                    name: arguments[1],
                    world: world
                )
            case "nonempty-load":
                guard arguments.count == 2,
                      AgentCheckpointName(rawValue: arguments[1]) != nil else {
                    return failure(usage)
                }
                return try proveNonEmptyPositionLoadRefusal(
                    name: arguments[1],
                    world: world
                )
            case "duplicate-load":
                guard arguments.count == 2,
                      AgentCheckpointName(rawValue: arguments[1]) != nil else {
                    return failure(usage)
                }
                return try proveDuplicateProbeLoadRefusal(
                    name: arguments[1],
                    world: world
                )
            case "park-custody":
                guard arguments.count == 2 else { return failure(usage) }
                return try parkCheckpointProofCustody(
                    agentID: arguments[1],
                    world: world
                )
            case "planner":
                guard arguments.count == 1 else { return failure(usage) }
                return try proveCheckpointPositionPlanner(world: world)
            default:
                return failure(usage)
            }
        } catch {
            return failure("Checkpoint position proof failed: \(error)")
        }
    }

    private func proveStaleCheckpointSaveRefusal(
        name: String,
        world: World
    ) throws -> PebbleAgentCommandResult {
        guard let liveSession = session,
              let agent = liveSession.snapshot().agents.sorted(by: {
                  $0.id < $1.id
              }).first,
              let probe = probesByAgentId[agent.id] else {
            throw PebbleCheckpointPositionRestoreProofError.failed(
                "stale-save fixture"
            )
        }
        let initial = PebbleAgentCheckpointProbeState(
            agentID: agent.id,
            probe: probe
        )
        let initialDigest = try liveSession.durableStateDigest()
        let initialCausal = liveSession.causalLedgerSnapshot().summary
        let initialWorldObjects = world.entities.map(ObjectIdentifier.init)
        let initialMapping = probeObjectIdentifiers()
        let listBefore = handleCheckpoint(["list"], world: world)
        guard listBefore.succeeded else {
            throw PebbleCheckpointPositionRestoreProofError.failed(
                "checkpoint list before stale save"
            )
        }

        probe.setPos(probe.x + 1, probe.y, probe.z)
        let stale = PebbleAgentCheckpointProbeState(
            agentID: agent.id,
            probe: probe
        )
        let refused = handleCheckpoint(["save", name], world: world)
        let listAfter = handleCheckpoint(["list"], world: world)
        let digestAfterRefusal = try liveSession.durableStateDigest()
        let saveWasNonMutating = !refused.succeeded
            && refused.message.contains("checkpoint save position mismatch")
            && listAfter.succeeded
            && listAfter.message == listBefore.message
            && digestAfterRefusal == initialDigest
            && liveSession.causalLedgerSnapshot().summary == initialCausal
            && world.entities.map(ObjectIdentifier.init) == initialWorldObjects
            && probeObjectIdentifiers() == initialMapping
            && stale.isUnchanged(
                in: world,
                mappedByAgentID: probesByAgentId
            )
        initial.restorePriorPhysicalState()
        guard saveWasNonMutating,
              initial.isUnchanged(
                  in: world,
                  mappedByAgentID: probesByAgentId
              ) else {
            throw PebbleCheckpointPositionRestoreProofError.failed(
                "stale save atomicity"
            )
        }
        let stalePosition = AgentPosition(
            x: Int(stale.x.rounded(.down)),
            y: Int(stale.y.rounded(.down)),
            z: Int(stale.z.rounded(.down))
        )
        let message = "checkpoint position proof staleSave=refused "
            + "agent=\(agent.id) session=\(positionText(agent.position)) "
            + "physical=\(positionText(stalePosition)) "
            + "partialFiles=0 sessionMutation=0 worldMutation=0"
        trace(message)
        return success(message)
    }

    private func proveNonEmptyPositionLoadRefusal(
        name: String,
        world: World
    ) throws -> PebbleAgentCommandResult {
        guard let liveSession = session,
              let agentID = probesByAgentId.keys.sorted().first,
              let probe = probesByAgentId[agentID],
              probe.carriedItems.allSatisfy({ $0 == nil }) else {
            throw PebbleCheckpointPositionRestoreProofError.failed(
                "non-empty load fixture"
            )
        }
        let initial = PebbleAgentCheckpointProbeState(
            agentID: agentID,
            probe: probe
        )
        let initialDigest = try liveSession.durableStateDigest()
        let initialCausal = liveSession.causalLedgerSnapshot().summary
        let initialWorldObjects = world.entities.map(ObjectIdentifier.init)
        let initialMapping = probeObjectIdentifiers()
        probe.setPos(probe.x + 32, probe.y, probe.z)
        probe.carriedItems[0] = ItemStack(iid("cobblestone"), 1)
        let divergent = PebbleAgentCheckpointProbeState(
            agentID: agentID,
            probe: probe
        )
        let refused = handleCheckpoint(["load", name], world: world)
        let digestAfterRefusal = try liveSession.durableStateDigest()
        let refusedWithoutMutation = !refused.succeeded
            && refused.message.contains("current probe custody is non-empty")
            && digestAfterRefusal == initialDigest
            && liveSession.causalLedgerSnapshot().summary == initialCausal
            && world.entities.map(ObjectIdentifier.init) == initialWorldObjects
            && probeObjectIdentifiers() == initialMapping
            && divergent.isUnchanged(
                in: world,
                mappedByAgentID: probesByAgentId
            )
        initial.restorePriorPhysicalState()
        guard refusedWithoutMutation,
              initial.isUnchanged(
                  in: world,
                  mappedByAgentID: probesByAgentId
              ) else {
            throw PebbleCheckpointPositionRestoreProofError.failed(
                "non-empty load atomicity"
            )
        }
        let message = "checkpoint position proof nonEmptyMismatch=refused "
            + "agent=\(agentID) carried=1 sessionMutation=0 "
            + "worldMutation=0 physicalItemDuplication=0"
        trace(message)
        return success(message)
    }

    private func proveDuplicateProbeLoadRefusal(
        name: String,
        world: World
    ) throws -> PebbleAgentCommandResult {
        guard let liveSession = session,
              let agentID = probesByAgentId.keys.sorted().first,
              let original = probesByAgentId[agentID] else {
            throw PebbleCheckpointPositionRestoreProofError.failed(
                "duplicate load fixture"
            )
        }
        let initial = PebbleAgentCheckpointProbeState(
            agentID: agentID,
            probe: original
        )
        let initialDigest = try liveSession.durableStateDigest()
        let duplicate = LabCoreAgentEntity(
            world: world,
            labAgentId: agentID,
            physicalId: "position-proof-duplicate-\(agentID)"
        )
        duplicate.setPos(original.x, original.y, original.z)
        world.addEntity(duplicate)
        let objectsWithFixture = world.entities.map(ObjectIdentifier.init)
        let refused = handleCheckpoint(["load", name], world: world)
        let digestAfterRefusal = try liveSession.durableStateDigest()
        let duplicateWasRejected = refused.message.contains(
            "live embodiments are not coherent"
        ) || refused.message.contains(
            "live Civilization identities do not match"
        )
        let refusedWithoutMutation = !refused.succeeded
            && duplicateWasRejected
            && digestAfterRefusal == initialDigest
            && world.entities.map(ObjectIdentifier.init) == objectsWithFixture
            && probesByAgentId[agentID] === original
            && initial.isUnchanged(
                in: world,
                mappedByAgentID: probesByAgentId
            )
        guard removeLabCoreAgentProbe(duplicate, from: world),
              refusedWithoutMutation,
              initial.isUnchanged(
                  in: world,
                  mappedByAgentID: probesByAgentId
              ) else {
            throw PebbleCheckpointPositionRestoreProofError.failed(
                "duplicate load atomicity"
            )
        }
        let message = "checkpoint position proof duplicateProbe=refused "
            + "agent=\(agentID) sessionMutation=0 worldMutation=0"
        trace(message)
        return success(message)
    }

    private func proveCheckpointPositionPlanner(
        world: World
    ) throws -> PebbleAgentCommandResult {
        guard let liveSession = session,
              let agent = liveSession.snapshot().agents.sorted(by: {
                  $0.id < $1.id
              }).first,
              let probe = probesByAgentId[agent.id] else {
            throw PebbleCheckpointPositionRestoreProofError.failed(
                "planner fixture"
            )
        }
        let initial = PebbleAgentCheckpointProbeState(
            agentID: agent.id,
            probe: probe
        )
        probe.setPos(probe.x + 32, probe.y, probe.z)
        let embodiments = try PebbleAgentEmbodiment.resolveAll(
            agentIDs: liveSession.snapshot().agents.map(\.id),
            in: world,
            mappedByAgentID: probesByAgentId
        )
        let populationIDs = Set(
            liveSession.populationSnapshot().members.map(\.agentID.rawValue)
        )
        let lifecycleIDs = Set(
            liveSession.lifecycleSnapshot().members.map(\.agentID.rawValue)
        )
        let agents = liveSession.snapshot().agents
        let missingAttestationRefused: Bool
        do {
            _ = try PebbleAgentCheckpointProbePlanner.plan(
                candidateAgents: agents,
                currentEmbodiments: embodiments,
                verifiedEmptyAgentIDs: [],
                populationAgentIDs: populationIDs,
                lifecycleAgentIDs: lifecycleIDs,
                requirePopulationIdentity: true,
                requireLifecycleIdentity: true,
                physicalHolderAgentIDs: []
            )
            missingAttestationRefused = false
        } catch PebbleAgentCheckpointProbePlanError.missingEmptyAttestation {
            missingAttestationRefused = true
        }
        let holderRefused: Bool
        do {
            _ = try PebbleAgentCheckpointProbePlanner.plan(
                candidateAgents: agents,
                currentEmbodiments: embodiments,
                verifiedEmptyAgentIDs: Set(agents.map(\.id)),
                populationAgentIDs: populationIDs,
                lifecycleAgentIDs: lifecycleIDs,
                requirePopulationIdentity: true,
                requireLifecycleIdentity: true,
                physicalHolderAgentIDs: [agent.id]
            )
            holderRefused = false
        } catch PebbleAgentCheckpointProbePlanError.physicalHolderConflict {
            holderRefused = true
        }
        initial.restorePriorPhysicalState()
        guard missingAttestationRefused, holderRefused,
              initial.isUnchanged(
                  in: world,
                  mappedByAgentID: probesByAgentId
              ) else {
            throw PebbleCheckpointPositionRestoreProofError.failed(
                "planner fail-closed cases"
            )
        }
        let message = "checkpoint position proof planner "
            + "missingAttestation=refused physicalHolder=refused "
            + "sessionMutation=0 worldMutation=0"
        trace(message)
        return success(message)
    }

    private func parkCheckpointProofCustody(
        agentID: String,
        world: World
    ) throws -> PebbleAgentCommandResult {
        guard let probe = probesByAgentId[agentID], probe.world === world,
              !probe.dead,
              let container = nearestLiveAgricultureContainer(
                  world: world,
                  origin: AgentPosition(
                      x: Int(probe.x.rounded(.down)),
                      y: Int(probe.y.rounded(.down)),
                      z: Int(probe.z.rounded(.down))
                  ),
                  radius: 16
              ) else {
            throw PebbleCheckpointPositionRestoreProofError.failed(
                "custody parking fixture"
            )
        }
        let source = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            probe,
            in: world
        )
        let destination = PebbleAgentMaterialCustodyEndpoint.container(
            container,
            in: world
        )
        let sourceBefore = try materialCustodyGateway.inspect(source)
        let destinationBefore = try materialCustodyGateway.inspect(destination)
        let stacks = sourceBefore.slots.compactMap { $0 }
        guard !stacks.isEmpty else {
            throw PebbleCheckpointPositionRestoreProofError.failed(
                "custody parking requires a carried stack"
            )
        }
        var transferred = 0
        for (index, stack) in stacks.enumerated() {
            let result = materialCustodyGateway.transfer(
                PebbleAgentMaterialTransactionRequest(
                    transactionID: "gate-d-position-park-\(agentID)-\(index)",
                    material: stack,
                    expectedSourceFingerprint:
                        try materialCustodyGateway.fingerprint(source),
                    expectedDestinationFingerprint:
                        try materialCustodyGateway.fingerprint(destination)
                ),
                from: source,
                to: destination
            )
            guard result.succeeded else {
                throw PebbleCheckpointPositionRestoreProofError.failed(
                    "verified custody parking transfer"
                )
            }
            transferred += stack.count
        }
        let sourceAfter = try materialCustodyGateway.inspect(source)
        let destinationAfter = try materialCustodyGateway.inspect(destination)
        let sourceQuantity = sourceAfter.slots.compactMap { $0?.count }
            .reduce(0, +)
        let destinationDelta = destinationAfter.slots.compactMap { $0?.count }
            .reduce(0, +) - destinationBefore.slots.compactMap { $0?.count }
            .reduce(0, +)
        guard sourceQuantity == 0, destinationDelta == transferred,
              probe.carriedItems.allSatisfy({ $0 == nil }) else {
            throw PebbleCheckpointPositionRestoreProofError.failed(
                "custody parking conservation"
            )
        }
        let message = "checkpoint position proof parkedCustody "
            + "agent=\(agentID) quantity=\(transferred) "
            + "sourceAfter=0 destinationDelta=\(destinationDelta) "
            + "conservation=exact physicalMutation=verified_gateway_transfer"
        trace(message)
        return success(message)
    }

    private func probeObjectIdentifiers() -> [String: ObjectIdentifier] {
        Dictionary(uniqueKeysWithValues: probesByAgentId.map {
            ($0.key, ObjectIdentifier($0.value))
        })
    }
}
