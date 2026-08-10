import PebbleAgents
import PebbleCore

private enum PebbleCheckpointPhysicalCustodyProofError: Error {
    case failed(String)
}

extension PebbleAgentController {
    func handleCheckpointPhysicalCustodyProof(
        _ arguments: [String],
        world: World
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab checkpoint custody-proof "
            + "<failure <none|after-first-custody>"
            + "|multi-slot-setup <agentID>"
            + "|conflicting-bootstrap <agentID>|status <agentID>>"
        guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1"
        else {
            return failure(
                "Checkpoint custody proof is restricted to disposable Worlds."
            )
        }
        guard activeWorld === world, session != nil else {
            return failure("Checkpoint custody proof requires an active session.")
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
                    checkpointPhysicalCustodyFailurePoint = nil
                case "after-first-custody":
                    checkpointPhysicalCustodyFailurePoint =
                        .afterFirstCustodyRestore
                default:
                    return failure(usage)
                }
                let value = arguments[1].lowercased()
                trace("checkpoint custody proof failurePoint=\(value)")
                return success(
                    "Checkpoint custody proof failure point: \(value)."
                )
            case "multi-slot-setup":
                guard arguments.count == 2 else { return failure(usage) }
                return try setupCheckpointMultiSlotCustody(
                    agentID: arguments[1],
                    world: world
                )
            case "conflicting-bootstrap":
                guard arguments.count == 2 else { return failure(usage) }
                return try setupConflictingBootstrapCustody(
                    agentID: arguments[1],
                    world: world
                )
            case "status":
                guard arguments.count == 2 else { return failure(usage) }
                return try checkpointCustodyProofStatus(
                    agentID: arguments[1],
                    world: world
                )
            default:
                return failure(usage)
            }
        } catch {
            return failure("Checkpoint custody proof failed: \(error)")
        }
    }

    private func setupCheckpointMultiSlotCustody(
        agentID: String,
        world: World
    ) throws -> PebbleAgentCommandResult {
        guard let probe = probesByAgentId[agentID], probe.world === world,
              !probe.dead,
              probe.carriedItems.count
                == LabCoreAgentEntity.carriedItemSlotCount,
              probe.carriedItems.allSatisfy({ $0 == nil }) else {
            throw PebbleCheckpointPhysicalCustodyProofError.failed(
                "multi-slot fixture requires exact empty custody"
            )
        }
        var data = StackData()
        data.priorWork = 2
        data.repairUnits = 1
        let tool = ItemStack(
            iid("iron_hoe"),
            1,
            damage: 7,
            ench: [EnchInstance("efficiency", 2)],
            label: "Gate D custody continuity",
            data: data
        )
        probe.carriedItems[0] = tool
        let evidence = try makeCheckpointPhysicalCustodyEvidence(
            agentID: agentID,
            slots: probe.carriedItems
        )
        guard evidence.slots[0] == tool,
              evidence.evidence.items.count == 1,
              evidence.evidence.items[0].slotOrdinal == 0,
              evidence.evidence.items[0].itemKey == "iron_hoe" else {
            probe.carriedItems[0] = nil
            throw PebbleCheckpointPhysicalCustodyProofError.failed(
                "multi-slot fixture verification"
            )
        }
        let message = "checkpoint custody proof multiSlotSetup "
            + "agent=\(agentID) toolSlot=0 item=iron_hoe count=1 damage=7 "
            + "enchantments=efficiency:2 label=present priorWork=2 "
            + "repairUnits=1 fingerprint="
            + evidence.evidence.custodyFingerprint.rawValue
            + " physicalMutation=bounded-proof-fixture"
        trace(message)
        return success(message)
    }

    private func setupConflictingBootstrapCustody(
        agentID: String,
        world: World
    ) throws -> PebbleAgentCommandResult {
        guard let probe = probesByAgentId[agentID], probe.world === world,
              !probe.dead,
              probe.carriedItems.allSatisfy({ $0 == nil }) else {
            throw PebbleCheckpointPhysicalCustodyProofError.failed(
                "conflicting bootstrap fixture requires empty custody"
            )
        }
        probe.carriedItems[3] = ItemStack(iid("cobblestone"), 2)
        guard probe.carriedItems[3]?.id == iid("cobblestone"),
              probe.carriedItems[3]?.count == 2 else {
            probe.carriedItems[3] = nil
            throw PebbleCheckpointPhysicalCustodyProofError.failed(
                "conflicting bootstrap fixture verification"
            )
        }
        let message = "checkpoint custody proof conflictingBootstrap "
            + "agent=\(agentID) slot=3 item=cobblestone count=2 "
            + "custody=real"
        trace(message)
        return success(message)
    }

    private func checkpointCustodyProofStatus(
        agentID: String,
        world: World
    ) throws -> PebbleAgentCommandResult {
        guard let probe = probesByAgentId[agentID], probe.world === world,
              !probe.dead else {
            throw PebbleCheckpointPhysicalCustodyProofError.failed(
                "status probe"
            )
        }
        let custody = try makeCheckpointPhysicalCustodyEvidence(
            agentID: agentID,
            slots: probe.carriedItems
        )
        let breadSlots = probe.carriedItems.enumerated().compactMap {
            index, stack -> (Int, Int)? in
            guard let stack, stack.id == iid("bread") else { return nil }
            return (index, stack.count)
        }
        let breadSlot = breadSlots.count == 1
            ? String(breadSlots[0].0) : "none"
        let breadCount = breadSlots.reduce(0) { $0 + $1.1 }
        let tool = probe.carriedItems[0]
        let toolExact = tool?.id == iid("iron_hoe")
            && tool?.count == 1
            && tool?.damage == 7
            && tool?.ench == [EnchInstance("efficiency", 2)]
            && tool?.label == "Gate D custody continuity"
            && tool?.data.priorWork == 2
            && tool?.data.repairUnits == 1
        let tagged = world.entities.compactMap { $0 as? ItemEntity }.filter {
            $0.custodyProvenance?.hasPrefix(
                "pebblelab-checkpoint-custody-v1:"
            ) == true
        }
        let duplicateTokens = Dictionary(grouping: tagged) {
            $0.custodyProvenance ?? ""
        }.values.filter { $0.count > 1 }.count
        let message = "checkpoint custody proof status agent=\(agentID) "
            + "toolSlot=\(toolExact ? "0" : "none") toolExact="
            + "\(toolExact ? 1 : 0) breadSlot=\(breadSlot) "
            + "breadCount=\(breadCount) stacks=\(custody.stackCount) "
            + "quantity=\(custody.carriedQuantity) fingerprint="
            + custody.evidence.custodyFingerprint.rawValue
            + " taggedSpills=\(tagged.count) exact=\(toolExact ? 1 : 0) "
            + "duplicates=\(duplicateTokens)"
        trace(message)
        return success(message)
    }
}
