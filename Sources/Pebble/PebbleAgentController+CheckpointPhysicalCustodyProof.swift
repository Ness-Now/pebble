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
            + "|conflicting-bootstrap <agentID>"
            + "|verified-move <agentID>|status <agentID>"
            + "|world-material-status>"
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
            case "verified-move":
                guard arguments.count == 2 else { return failure(usage) }
                return try performCheckpointProofVerifiedMovement(
                    agentID: arguments[1],
                    world: world
                )
            case "status":
                guard arguments.count == 2 else { return failure(usage) }
                return try checkpointCustodyProofStatus(
                    agentID: arguments[1],
                    world: world
                )
            case "world-material-status":
                guard arguments.count == 1 else { return failure(usage) }
                return try checkpointCustodyWorldMaterialStatus(world: world)
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

    /// Moves one live probe through PebbleCore collision/path semantics and
    /// publishes the resulting physical truth through the normal verified
    /// movement-reconciliation transition. This is disposable proof setup,
    /// not a second movement implementation.
    private func performCheckpointProofVerifiedMovement(
        agentID: String,
        world: World
    ) throws -> PebbleAgentCommandResult {
        guard var candidate = session,
              replayRecorder == nil,
              let probe = probesByAgentId[agentID],
              probe.world === world, !probe.dead else {
            throw PebbleCheckpointPhysicalCustodyProofError.failed(
                "verified movement fixture"
            )
        }
        let beforeSession = candidate
        let before = PebbleAgentEmbodiment(probe: probe)
        let beforePosition = before.position
        let original = probe.capturePhysicalState()
        let occupied = Set(probesByAgentId.values.compactMap {
            other -> AgentPosition? in
            guard other !== probe, other.world === world, !other.dead else {
                return nil
            }
            return PebbleAgentEmbodiment(probe: other).position
        })
        let target = [
            AgentPosition(x: beforePosition.x - 1,
                          y: beforePosition.y, z: beforePosition.z),
            AgentPosition(x: beforePosition.x,
                          y: beforePosition.y, z: beforePosition.z - 1),
            AgentPosition(x: beforePosition.x + 1,
                          y: beforePosition.y, z: beforePosition.z),
            AgentPosition(x: beforePosition.x,
                          y: beforePosition.y, z: beforePosition.z + 1),
        ].compactMap { destination -> AgentPosition? in
            guard !occupied.contains(destination),
                  let path = findPath(
                    world, before.x, before.y, before.z,
                    Double(destination.x) + 0.5, Double(destination.y),
                    Double(destination.z) + 0.5, 600, true
                  ), let node = path.first else { return nil }
            let next = AgentPosition(x: node.x, y: node.y, z: node.z)
            guard !occupied.contains(next),
                  max(abs(next.x - beforePosition.x),
                      abs(next.z - beforePosition.z)) == 1,
                  abs(next.y - beforePosition.y) <= 1 else { return nil }
            return next
        }.first
        guard let target else {
            throw PebbleCheckpointPhysicalCustodyProofError.failed(
                "verified movement has no bounded Core path"
            )
        }
        do {
            probe.prevX = probe.x
            probe.prevY = probe.y
            probe.prevZ = probe.z
            let dx = Double(target.x) + 0.5 - probe.x
            let dy = Double(target.y) - probe.y
            let dz = Double(target.z) + 0.5 - probe.z
            probe.yaw = detAtan2(-dx, dz)
            probe.move(dx, dy, dz)
            guard PebbleAgentEmbodiment(probe: probe).position == target else {
                throw PebbleCheckpointPhysicalCustodyProofError.failed(
                    "verified movement Core mutation refused"
                )
            }
            // Publish the verified Core position through the same external
            // physical-boundary update used by the live care adapter.
            try candidate.applyExternalUpdate(AgentExternalUpdate(
                agentId: agentID,
                position: target
            ))
            guard candidate.snapshot().agents.first(where: {
                $0.id == agentID
            })?.position == target,
                  target != beforePosition else {
                throw PebbleCheckpointPhysicalCustodyProofError.failed(
                    "verified movement publication"
                )
            }
            session = candidate
        } catch {
            session = beforeSession
            guard probe.restorePhysicalState(original) else {
                throw PebbleCheckpointPhysicalCustodyProofError.failed(
                    "verified movement rollback"
                )
            }
            throw error
        }
        let message = "checkpoint custody proof verifiedMove "
            + "agent=\(agentID) from=\(beforePosition.x),"
            + "\(beforePosition.y),\(beforePosition.z) to=\(target.x),"
            + "\(target.y),\(target.z) authority=PebbleCore "
            + "publication=verified_external_update"
        trace(message)
        return success(message)
    }

    private func checkpointCustodyWorldMaterialStatus(
        world: World
    ) throws -> PebbleAgentCommandResult {
        let probes = world.entities.compactMap { $0 as? LabCoreAgentEntity }
        let itemEntities = world.entities.compactMap { $0 as? ItemEntity }
        let probeStacks = probes.flatMap { $0.carriedItems.compactMap { $0 } }
        let worldStacks = itemEntities.map(\.stack)
        let relevantItemIDs = Set([iid("bread"), iid("iron_hoe")])
        let relevantWorldStacks = worldStacks.filter {
            relevantItemIDs.contains($0.id)
        }
        func quantity(_ name: String, in stacks: [ItemStack]) -> Int {
            let itemID = iid(name)
            return stacks.filter { $0.id == itemID }.reduce(0) {
                $0 + $1.count
            }
        }
        let tagged = itemEntities.filter {
            $0.custodyProvenance?.hasPrefix(
                "pebblelab-checkpoint-custody-v"
            ) == true
        }
        let duplicateTokens = Dictionary(grouping: tagged) {
            $0.custodyProvenance ?? ""
        }.values.filter { $0.count > 1 }.count
        let locations = itemEntities.sorted {
            if $0.x != $1.x { return $0.x < $1.x }
            if $0.y != $1.y { return $0.y < $1.y }
            return $0.z < $1.z
        }.map {
            "\(itemDef($0.stack.id).name):\($0.stack.count)@"
                + "\(Int($0.x.rounded(.down))),"
                + "\(Int($0.y.rounded(.down))),"
                + "\(Int($0.z.rounded(.down))):"
                + "\($0.custodyProvenance == nil ? "ordinary" : "protected")"
        }.joined(separator: ";")
        let message = "checkpoint custody proof worldMaterial "
            + "probeStacks=\(probeStacks.count) probeQuantity="
            + "\(probeStacks.reduce(0) { $0 + $1.count }) "
            + "relevantWorldStacks=\(relevantWorldStacks.count) "
            + "relevantWorldQuantity="
            + "\(relevantWorldStacks.reduce(0) { $0 + $1.count }) "
            + "breadProbe=\(quantity("bread", in: probeStacks)) "
            + "breadWorld=\(quantity("bread", in: worldStacks)) "
            + "toolProbe=\(quantity("iron_hoe", in: probeStacks)) "
            + "toolWorld=\(quantity("iron_hoe", in: worldStacks)) "
            + "taggedSpills=\(tagged.count) "
            + "ordinarySpills=\(itemEntities.count - tagged.count) "
            + "duplicateTokens=\(duplicateTokens) locations="
            + "\(locations.isEmpty ? "none" : locations)"
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
                "pebblelab-checkpoint-custody-v"
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
