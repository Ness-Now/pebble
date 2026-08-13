import PebbleAgents
import PebbleCore

private enum PebbleCheckpointEvolvedIdentityProofError: Error {
    case failed(String)
}

extension PebbleAgentController {
    func handleBlocker09CheckpointIdentityProof(
        _ command: String,
        world: World
    ) throws -> PebbleAgentCommandResult {
        guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1",
              environment["PEBBLELAB_GATE_D_BLOCKER_09"] == "1",
              activeWorld === world, let session else {
            throw PebbleCheckpointEvolvedIdentityProofError.failed(
                "Blocker 09 proof boundary"
            )
        }
        switch command.lowercased() {
        case "status":
            let context = try blocker09IdentityContext(
                session: session, world: world
            )
            try validateCheckpointMaterialRightsCustody(
                session: session,
                custodyByAgentID: context.custodyByAgentID
            )
            let message = blocker09IdentityStatus(
                context: context, session: session,
                validation: "current_exact"
            )
            trace(message)
            return success(message)
        case "adversarial":
            let message = try proveBlocker09IdentityAdversarials(
                session: session, world: world
            )
            trace(message)
            return success(message)
        default:
            throw PebbleCheckpointEvolvedIdentityProofError.failed(
                "unknown Blocker 09 identity proof"
            )
        }
    }

    private struct Blocker09IdentityContext {
        let record: AgentMaterialRightsRecord
        let holderID: AgentID
        let holderSlot: Int
        let currentStack: ItemStack
        let custodyByAgentID:
            [String: PebbleAgentCheckpointDecodedCustody]
        let settlementReceiptID: String
        let estateEntryID: String
    }

    private func blocker09IdentityContext(
        session: AgentSimulationSession,
        world: World
    ) throws -> Blocker09IdentityContext {
        let rights = session.materialRightsSnapshot().records.filter {
            $0.asset.materialIdentity.itemKey == "iron_pickaxe"
                && $0.lastVerifiedHolder.materialIdentity.itemKey
                    == "iron_pickaxe"
        }
        guard rights.count == 1, let record = rights.first,
              case let .agent(holderID) = record.lastVerifiedHolder.holder,
              let probe = probesByAgentId[holderID.rawValue],
              probe.world === world, !probe.dead else {
            throw PebbleCheckpointEvolvedIdentityProofError.failed(
                "one active inherited pickaxe record"
            )
        }
        let bridge = PebbleAgentMaterialSnapshotBridge()
        let physical = try bridge.custodySnapshot(
            locationID: "agent:pebble_app_agent_\(holderID.rawValue)",
            slots: probe.carriedItems
        )
        let matches = physical.slots.enumerated().compactMap {
            index, stack -> (Int, AgentMaterialStackSnapshot)? in
            guard let stack,
                  stack.identity == record.lastVerifiedHolder.materialIdentity,
                  stack.count == record.lastVerifiedHolder.quantity else {
                return nil
            }
            return (index, stack)
        }
        guard matches.count == 1,
              let currentStack = probe.carriedItems[matches[0].0]?.copy(),
              let estateEntry = session.estateSnapshot().estates
                .flatMap(\.assets).first(where: {
                    $0.materialRightsAssetID == record.asset.assetID
                        && $0.status == .transferred
                }),
              let settlementReceiptID = estateEntry.settlementReceiptID else {
            throw PebbleCheckpointEvolvedIdentityProofError.failed(
                "exact current physical pickaxe and settled estate"
            )
        }
        return Blocker09IdentityContext(
            record: record,
            holderID: holderID,
            holderSlot: matches[0].0,
            currentStack: currentStack,
            custodyByAgentID: try blocker09CurrentCustody(
                session: session, world: world
            ),
            settlementReceiptID: settlementReceiptID,
            estateEntryID: estateEntry.entryID.rawValue
        )
    }

    private func blocker09CurrentCustody(
        session: AgentSimulationSession,
        world: World
    ) throws -> [String: PebbleAgentCheckpointDecodedCustody] {
        Dictionary(uniqueKeysWithValues: try session.snapshot().agents.map {
            agent -> (String, PebbleAgentCheckpointDecodedCustody) in
            guard let probe = probesByAgentId[agent.id],
                  probe.world === world, !probe.dead else {
                throw PebbleCheckpointEvolvedIdentityProofError.failed(
                    "missing active probe \(agent.id)"
                )
            }
            return (
                agent.id,
                try makeCheckpointPhysicalCustodyEvidence(
                    agentID: agent.id,
                    slots: probe.carriedItems
                )
            )
        })
    }

    private func blocker09IdentityStatus(
        context: Blocker09IdentityContext,
        session: AgentSimulationSession,
        validation: String
    ) -> String {
        let current = context.record.lastVerifiedHolder
        return [
            "blocker09 checkpoint identity",
            "asset=\(context.record.asset.assetID.rawValue)",
            "holder=agent:\(context.holderID.rawValue)",
            "durableItem=\(context.record.asset.materialIdentity.itemKey)",
            "durableDamage=\(context.record.asset.materialIdentity.damage)",
            "currentItem=\(current.materialIdentity.itemKey)",
            "currentDamage=\(current.materialIdentity.damage)",
            "physicalDamage=\(context.currentStack.damage)",
            "quantity=\(current.quantity)",
            "assetContinuity=\(context.record.asset.permitsCurrentIdentity(current.materialIdentity) ? 1 : 0)",
            "checkpointValidation=\(validation)",
            "fingerprint=\(current.custodyFingerprint)",
            "estateEntry=\(context.estateEntryID)",
            "settlementReceipt=\(context.settlementReceiptID)",
            "assetCount=\(session.materialRightsSnapshot().records.filter { $0.asset.assetID == context.record.asset.assetID }.count)",
            "authority=PebbleCore+currentMaterialRightsProjection",
        ].joined(separator: " ")
    }

    private func proveBlocker09IdentityAdversarials(
        session: AgentSimulationSession,
        world: World
    ) throws -> String {
        let context = try blocker09IdentityContext(
            session: session, world: world
        )
        let sessionBefore = try session.durableStateDigest()
        let worldBefore = probesByAgentId.mapValues {
            copyItemInventory($0.carriedItems)
        }

        func expectedRefusal(
            _ name: String,
            _ mutate: (
                inout [String: [ItemStack?]], Blocker09IdentityContext
            ) throws -> Void
        ) throws -> String {
            var slotsByAgent = Dictionary(uniqueKeysWithValues:
                context.custodyByAgentID.map { ($0.key, copyItemInventory($0.value.slots)) }
            )
            try mutate(&slotsByAgent, context)
            let evidence = Dictionary(uniqueKeysWithValues: try slotsByAgent.map {
                agentID, slots in
                (agentID, try makeCheckpointPhysicalCustodyEvidence(
                    agentID: agentID, slots: slots
                ))
            })
            do {
                try validateCheckpointMaterialRightsCustody(
                    session: session, custodyByAgentID: evidence
                )
                throw PebbleCheckpointEvolvedIdentityProofError.failed(
                    "\(name) unexpectedly accepted"
                )
            } catch is PebbleAgentCheckpointCustodyError {
                return "refused"
            }
        }

        let missing = try expectedRefusal("missing") { slots, value in
            slots[value.holderID.rawValue]![value.holderSlot] = nil
        }
        let oldIdentity = try expectedRefusal("oldIdentity") { slots, value in
            slots[value.holderID.rawValue]![value.holderSlot]!.damage =
                value.record.asset.materialIdentity.damage
        }
        let futureIdentity = try expectedRefusal("futureIdentity") { slots, value in
            slots[value.holderID.rawValue]![value.holderSlot]!.damage =
                value.record.lastVerifiedHolder.materialIdentity.damage + 1
        }
        let wrongHolder = try expectedRefusal("wrongHolder") { slots, value in
            guard let other = slots.keys.sorted().first(where: {
                $0 != value.holderID.rawValue
                    && slots[$0]!.contains(where: { $0 == nil })
            }), let destination = slots[other]!.firstIndex(where: { $0 == nil }) else {
                throw PebbleCheckpointEvolvedIdentityProofError.failed(
                    "wrong-holder destination"
                )
            }
            slots[value.holderID.rawValue]![value.holderSlot] = nil
            slots[other]![destination] = value.currentStack.copy()
        }
        let wrongQuantity = try expectedRefusal("wrongQuantity") { slots, value in
            // Quantity zero is represented by absence; constructing a count-2
            // pickaxe would itself be an invalid PebbleCore ItemStack and would
            // test fixture validation rather than the checkpoint boundary.
            slots[value.holderID.rawValue]![value.holderSlot] = nil
        }
        let ambiguity = try expectedRefusal("ambiguity") { slots, value in
            guard let empty = slots[value.holderID.rawValue]!
                .firstIndex(where: { $0 == nil }) else {
                throw PebbleCheckpointEvolvedIdentityProofError.failed(
                    "ambiguity slot"
                )
            }
            slots[value.holderID.rawValue]![empty] = value.currentStack.copy()
        }

        let duplicateAssetID = AgentMaterialAssetID(
            rawValue: "asset:blocker09:duplicate-current"
        )!
        let duplicateRecord = AgentMaterialRightsRecord(
            asset: AgentMaterialAssetReference(
                assetID: duplicateAssetID,
                materialIdentity: context.record.lastVerifiedHolder.materialIdentity,
                quantity: context.record.lastVerifiedHolder.quantity
            ),
            lastVerifiedHolder: context.record.lastVerifiedHolder
        )
        let duplicateReservation: String
        do {
            try validateCheckpointMaterialRightsCustody(
                records: session.materialRightsSnapshot().records
                    + [duplicateRecord],
                sessionTick: session.tick,
                custodyByAgentID: context.custodyByAgentID
            )
            throw PebbleCheckpointEvolvedIdentityProofError.failed(
                "duplicate reservation unexpectedly accepted"
            )
        } catch is PebbleAgentCheckpointCustodyError {
            duplicateReservation = "refused"
        }

        guard try session.durableStateDigest() == sessionBefore,
              probesByAgentId.allSatisfy({ key, probe in
                  probe.carriedItems == worldBefore[key]
              }) else {
            throw PebbleCheckpointEvolvedIdentityProofError.failed(
                "adversarial proof mutated publication"
            )
        }
        return [
            "blocker09 checkpoint identity adversarial",
            "missing=\(missing)",
            "oldIdentity=\(oldIdentity)",
            "futureIdentity=\(futureIdentity)",
            "wrongHolder=\(wrongHolder)",
            "wrongQuantity=\(wrongQuantity)",
            "ambiguity=\(ambiguity)",
            "duplicateReservation=\(duplicateReservation)",
            "session=unchanged",
            "world=unchanged",
            "checkpointPublication=0",
            "handoffPublication=0",
            "authority=PebbleCore",
        ].joined(separator: " ")
    }
}
