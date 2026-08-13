import PebbleAgents
import PebbleCore

enum PebbleAgentProductionStatus: String {
    case succeeded
    case invalidRequest
    case staleSource
    case staleWorkshop
    case outOfReach
    case unavailableInputs
    case planMismatch
    case verificationFailure
    case rollbackFailure
    case duplicate
}

struct PebbleAgentProductionRequest {
    let operationID: String
    let opportunity: AgentProductionOpportunity
    let completedAtTick: Int
}

struct PebbleAgentProductionOutcome {
    let status: PebbleAgentProductionStatus
    let verified: AgentVerifiedProductionOutcome?
    let mutationOccurred: Bool

    var succeeded: Bool { status == .succeeded && verified != nil }
}

/// Pebble-owned sensor over a real crafting-table block and one real carried
/// inventory. It previews through PebbleCore's canonical recipe registry and
/// grants no mutation authority to PebbleAgents.
struct PebbleAgentProductionSensor {
    static let maximumWorkshopRadius = 4
    private let bridge = PebbleAgentMaterialSnapshotBridge()

    func observe(
        need: AgentProductionNeed,
        actor: PebbleAgentEmbodiment,
        world: World,
        atTick tick: Int,
        lifetimeTicks: Int
    ) -> AgentProductionOpportunityObservation? {
        guard actor.isValid(in: world),
              let workshop = nearestCraftingTable(to: actor.position, world: world),
              let mutation = canonicalCraftingMutation(
                  producing: need.desiredOutputItemKey,
                  from: actor.carriedItems,
                  gridWidth: 3,
                  gridHeight: 3
              ), mutation.output.count == need.quantity,
              let custody = try? bridge.custodySnapshot(
                  locationID: "agent:\(actor.physicalID)",
                  slots: actor.carriedItems
              ), let sourceFingerprint = try? bridge.fingerprint(of: custody),
              let inputs = try? mutation.inputs.map({
                  try bridge.snapshot(of: $0.stack)
              }), let output = try? bridge.snapshot(of: mutation.output) else {
            return nil
        }
        let plan = Self.planFingerprint(
            recipeID: mutation.recipeID, workshop: workshop,
            sourceLocationID: custody.locationID, inputs: inputs, output: output
        )
        guard let opportunityID = AgentProductionOpportunityID(rawValue:
            "production:\(need.needID.rawValue):t\(tick):\(plan)"
        ) else { return nil }
        return AgentProductionOpportunityObservation(
            opportunityID: opportunityID,
            needID: need.needID,
            actorID: need.actorID,
            recipeID: mutation.recipeID,
            workshopPosition: workshop,
            workshopBlockKey: "crafting_table",
            sourceLocationID: custody.locationID,
            sourceCustodyFingerprint: sourceFingerprint,
            planFingerprint: plan,
            inputs: inputs,
            output: output,
            observedAtTick: tick,
            expiresAtTick: tick + lifetimeTicks
        )
    }

    static func planFingerprint(
        recipeID: String,
        workshop: AgentPosition,
        sourceLocationID: String,
        inputs: [AgentMaterialStackSnapshot],
        output: AgentMaterialStackSnapshot
    ) -> String {
        let inputText = inputs.map {
            "\($0.identity.itemKey):\($0.identity.damage):\($0.count)"
        }.joined(separator: ",")
        return AgentProductionDigest.make(
            "\(recipeID)|\(workshop.x),\(workshop.y),\(workshop.z)|"
                + "\(sourceLocationID)|\(inputText)|"
                + "\(output.identity.itemKey):\(output.identity.damage):\(output.count)"
        )
    }

    private func nearestCraftingTable(
        to origin: AgentPosition,
        world: World
    ) -> AgentPosition? {
        var matches: [AgentPosition] = []
        let radius = Self.maximumWorkshopRadius
        for y in (origin.y - 2)...(origin.y + 2) {
            for x in (origin.x - radius)...(origin.x + radius) {
                for z in (origin.z - radius)...(origin.z + radius) {
                    let distance = abs(x - origin.x) + abs(y - origin.y)
                        + abs(z - origin.z)
                    guard distance <= radius,
                          world.isChunkReady(x >> 4, z >> 4),
                          (world.getBlock(x, y, z) >> 4)
                            == Int(B.crafting_table) else { continue }
                    matches.append(AgentPosition(x: x, y: y, z: z))
                }
            }
        }
        return matches.sorted { lhs, rhs in
            let left = abs(lhs.x - origin.x) + abs(lhs.y - origin.y)
                + abs(lhs.z - origin.z)
            let right = abs(rhs.x - origin.x) + abs(rhs.y - origin.y)
                + abs(rhs.z - origin.z)
            if left != right { return left < right }
            if lhs.y != rhs.y { return lhs.y < rhs.y }
            if lhs.x != rhs.x { return lhs.x < rhs.x }
            return lhs.z < rhs.z
        }.first
    }
}

/// Atomic real-inventory crafting boundary. The gateway revalidates current
/// workshop, reach, full source fingerprint and canonical Core plan, mutates
/// once, verifies exact slots, then publishes Civilization state. Every late
/// refusal restores the exact prior slots; candidate rollback is registered
/// for failures after this adapter returns.
final class PebbleAgentProductionGateway {
    struct BoundarySnapshot: Equatable {
        fileprivate let receiptOrder: [String]
        fileprivate let receipts: [String: String]
    }

    private static let maximumReceipts = 256
    private let bridge = PebbleAgentMaterialSnapshotBridge()
    private var receiptOrder: [String] = []
    private var receipts: [String: String] = [:]
    var candidatePhysicalTransaction: PebbleCandidatePhysicalTransaction?

    func boundarySnapshot() -> BoundarySnapshot {
        BoundarySnapshot(receiptOrder: receiptOrder, receipts: receipts)
    }

    func restoreBoundarySnapshot(_ snapshot: BoundarySnapshot) {
        receiptOrder = snapshot.receiptOrder
        receipts = snapshot.receipts
    }

    func reset() {
        receiptOrder.removeAll(keepingCapacity: true)
        receipts.removeAll(keepingCapacity: true)
    }

    func execute(
        _ request: PebbleAgentProductionRequest,
        actor: PebbleAgentEmbodiment,
        world: World,
        verifyAfterMutation: () -> Bool = { true },
        publish: (AgentVerifiedProductionOutcome) throws -> Void
    ) -> PebbleAgentProductionOutcome {
        if receipts[request.operationID] != nil {
            return outcome(.duplicate)
        }
        let opportunity = request.opportunity
        guard AgentOperationID(rawValue: request.operationID) != nil,
              opportunity.actorID.rawValue == actor.agentID,
              opportunity.workshopBlockKey == "crafting_table",
              actor.isValid(in: world) else { return outcome(.invalidRequest) }
        let workshop = opportunity.workshopPosition
        guard world.isChunkReady(workshop.x >> 4, workshop.z >> 4),
              (world.getBlock(workshop.x, workshop.y, workshop.z) >> 4)
                == Int(B.crafting_table) else {
            return outcome(.staleWorkshop)
        }
        let distance = abs(actor.position.x - workshop.x)
            + abs(actor.position.y - workshop.y)
            + abs(actor.position.z - workshop.z)
        guard distance <= PebbleAgentProductionSensor.maximumWorkshopRadius else {
            return outcome(.outOfReach)
        }
        let endpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(actor, in: world)
        guard endpoint.locationID == opportunity.sourceLocationID,
              let before = endpoint.read(),
              let custody = try? bridge.custodySnapshot(
                  locationID: endpoint.locationID, slots: before
              ), let fingerprintBefore = try? bridge.fingerprint(of: custody) else {
            return outcome(.invalidRequest)
        }
        guard fingerprintBefore == opportunity.sourceCustodyFingerprint else {
            return outcome(.staleSource)
        }
        guard let mutation = canonicalCraftingMutation(
            producing: opportunity.output.identity.itemKey,
            from: before, gridWidth: 3, gridHeight: 3
        ) else { return outcome(.unavailableInputs) }
        guard let inputs = try? mutation.inputs.map({
            try bridge.snapshot(of: $0.stack)
        }), let outputStack = try? bridge.snapshot(of: mutation.output) else {
            return outcome(.planMismatch)
        }
        let plan = PebbleAgentProductionSensor.planFingerprint(
            recipeID: mutation.recipeID, workshop: workshop,
            sourceLocationID: endpoint.locationID, inputs: inputs,
            output: outputStack
        )
        guard mutation.recipeID == opportunity.recipeID,
              inputs == opportunity.inputs,
              outputStack == opportunity.output,
              plan == opportunity.planFingerprint else {
            return outcome(.planMismatch)
        }
        let after = mutation.inventoryAfter
        let boundaryBefore = boundarySnapshot()
        let reservation: PebbleCandidatePhysicalCompensationReservation?
        if let candidatePhysicalTransaction {
            do {
                reservation = try candidatePhysicalTransaction.reserve(
                    compensationPrefix: "production:\(request.operationID)"
                )
            } catch { return outcome(.rollbackFailure) }
        } else { reservation = nil }
        guard endpoint.write(after), exactSlots(endpoint.read(), after) else {
            return rollback(
                endpoint: endpoint, before: before,
                failure: .verificationFailure
            )
        }
        guard verifyAfterMutation(),
              let custodyAfter = try? bridge.custodySnapshot(
                  locationID: endpoint.locationID, slots: after
              ), let fingerprintAfter = try? bridge.fingerprint(of: custodyAfter),
              fingerprintAfter != fingerprintBefore else {
            return rollback(
                endpoint: endpoint, before: before,
                failure: .verificationFailure
            )
        }
        let verified = AgentVerifiedProductionOutcome(
            operationID: request.operationID,
            opportunityID: opportunity.opportunityID,
            actorID: opportunity.actorID,
            recipeID: opportunity.recipeID,
            workshopPosition: workshop,
            workshopBlockKey: opportunity.workshopBlockKey,
            sourceLocationID: endpoint.locationID,
            sourceCustodyFingerprintBefore: fingerprintBefore,
            sourceCustodyFingerprintAfter: fingerprintAfter,
            planFingerprint: plan,
            inputsConsumed: inputs,
            outputProduced: outputStack,
            physicalReceiptID: request.operationID,
            completedAtTick: request.completedAtTick
        )
        do {
            try publish(verified)
        } catch {
            return rollback(
                endpoint: endpoint, before: before,
                failure: .verificationFailure
            )
        }
        receipts[request.operationID] = fingerprintAfter
        receiptOrder.append(request.operationID)
        while receiptOrder.count > Self.maximumReceipts {
            receipts.removeValue(forKey: receiptOrder.removeFirst())
        }
        guard registerCandidateCompensation(
            reservation: reservation, endpoint: endpoint,
            before: before, after: after, boundaryBefore: boundaryBefore
        ) else {
            return outcome(.rollbackFailure)
        }
        return PebbleAgentProductionOutcome(
            status: .succeeded, verified: verified, mutationOccurred: true
        )
    }

    private func rollback(
        endpoint: PebbleAgentMaterialCustodyEndpoint,
        before: [ItemStack?],
        failure: PebbleAgentProductionStatus
    ) -> PebbleAgentProductionOutcome {
        let restored = endpoint.write(before) && exactSlots(endpoint.read(), before)
        return PebbleAgentProductionOutcome(
            status: restored ? failure : .rollbackFailure,
            verified: nil,
            mutationOccurred: true
        )
    }

    private func registerCandidateCompensation(
        reservation: PebbleCandidatePhysicalCompensationReservation?,
        endpoint: PebbleAgentMaterialCustodyEndpoint,
        before: [ItemStack?],
        after: [ItemStack?],
        boundaryBefore: BoundarySnapshot
    ) -> Bool {
        guard let reservation, let candidatePhysicalTransaction else {
            return reservation == nil
        }
        let compensation = PebbleCandidatePhysicalCompensation(
            reservation: reservation,
            mutation: "craft canonical recipe into carried inventory",
            agentID: endpoint.locationID,
            expectedBefore: "\(before)",
            observedState: { "\(String(describing: endpoint.read()))" },
            compensate: { [weak self] in
                guard let self, self.exactSlots(endpoint.read(), after),
                      endpoint.write(before),
                      self.exactSlots(endpoint.read(), before) else { return false }
                self.restoreBoundarySnapshot(boundaryBefore)
                return self.boundarySnapshot() == boundaryBefore
            }
        )
        do {
            try candidatePhysicalTransaction.registerOrCompensate(compensation)
            return true
        } catch { return false }
    }

    private func exactSlots(_ lhs: [ItemStack?]?, _ rhs: [ItemStack?]) -> Bool {
        guard let lhs, lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).allSatisfy { left, right in
            switch (left, right) {
            case (nil, nil): return true
            case let (left?, right?): return left == right
            default: return false
            }
        }
    }

    private func outcome(
        _ status: PebbleAgentProductionStatus
    ) -> PebbleAgentProductionOutcome {
        PebbleAgentProductionOutcome(
            status: status, verified: nil, mutationOccurred: false
        )
    }
}
