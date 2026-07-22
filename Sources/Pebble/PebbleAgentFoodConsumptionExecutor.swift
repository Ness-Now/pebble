import PebbleAgents
import PebbleCore

struct PebbleAgentPreparedFoodConsumption {
    let intent: AgentPhysicalFoodConsumptionIntent
    let sourceSlot: Int
    let expectedSourceFingerprint: String
    let material: AgentMaterialStackSnapshot
    let validatedOutcome: AgentValidatedPhysicalFoodConsumptionOutcome
}

enum PebbleAgentFoodConsumptionStatus: String {
    case succeeded
    case noEligibleFood
    case duplicate
    case staleCustody
    case physicalFailure
    case verificationFailure
    case rollbackFailure
    case sessionRejected
}

struct PebbleAgentFoodConsumptionResult {
    let status: PebbleAgentFoodConsumptionStatus
    let outcome: AgentValidatedPhysicalFoodConsumptionOutcome?
    let physicalStatus: PebbleAgentMaterialTransactionStatus?

    var succeeded: Bool { status == .succeeded }
}

/// Narrow Pebble adapter joining real Core food metadata, exact CIV-16
/// custody, and the pure Civilization survival outcome. It owns no inventory,
/// food registry, cognition, or hunger state.
final class PebbleAgentFoodConsumptionExecutor {
    private let bridge = PebbleAgentMaterialSnapshotBridge()

    func prepare(
        _ intent: AgentPhysicalFoodConsumptionIntent,
        session: AgentSimulationSession,
        source: PebbleAgentMaterialCustodyEndpoint,
        gateway: PebbleAgentMaterialCustodyGateway
    ) throws -> PebbleAgentPreparedFoodConsumption? {
        guard intent.tick == session.tick,
              source.locationID == "agent:\(intent.agentID.rawValue)"
                || source.locationID.hasSuffix("_\(intent.agentID.rawValue)") else {
            throw AgentSessionError.physicalFoodSurvival(
                .invalidIntent(intent.consumptionID)
            )
        }
        guard let slots = source.read() else { return nil }
        let eligible = slots.indices.compactMap { slot -> (Int, ItemStack, FoodConsumptionDescriptor)? in
            guard let stack = slots[slot],
                  let descriptor = foodConsumptionDescriptor(for: stack),
                  descriptor.food.hunger > 0,
                  !descriptor.food.alwaysEat,
                  descriptor.food.effects.isEmpty,
                  descriptor.hasSimpleDebit else { return nil }
            return (slot, stack, descriptor)
        }
        guard let (slot, stack, descriptor) = eligible.first else { return nil }
        let fingerprint = try gateway.fingerprint(source)
        let fullSnapshot = try bridge.snapshot(of: stack)
        let material = AgentMaterialStackSnapshot(identity: fullSnapshot.identity, count: 1)
        let actor = try session.state(for: intent.agentID)
        let reduction = min(1, Double(descriptor.food.hunger) / 20.0)
        let outcome = AgentValidatedPhysicalFoodConsumptionOutcome(
            consumptionID: intent.consumptionID,
            consumptionSequence: intent.consumptionSequence,
            agentID: intent.agentID,
            tick: intent.tick,
            canonicalMaterialName: descriptor.canonicalMaterialName,
            quantityConsumed: 1,
            coreHungerPoints: descriptor.food.hunger,
            coreSaturation: descriptor.food.saturation,
            normalizedHungerReduction: reduction,
            status: .succeeded,
            physicalReceiptID: intent.consumptionID,
            sourceKind: .agentCarriedInventory,
            sourceSlot: slot,
            hungerBefore: actor.needs.hunger,
            hungerAfter: max(0, actor.needs.hunger - reduction)
        )
        try session.prevalidatePhysicalFoodConsumption(outcome)
        return PebbleAgentPreparedFoodConsumption(
            intent: intent,
            sourceSlot: slot,
            expectedSourceFingerprint: fingerprint,
            material: material,
            validatedOutcome: outcome
        )
    }

    func execute(
        _ plan: PebbleAgentPreparedFoodConsumption,
        session: inout AgentSimulationSession,
        source: PebbleAgentMaterialCustodyEndpoint,
        gateway: PebbleAgentMaterialCustodyGateway,
        verifyAfterDebit: () -> Bool = { true },
        publish: (
            AgentValidatedPhysicalFoodConsumptionOutcome,
            inout AgentSimulationSession
        ) throws -> Void = { outcome, candidate in
            try candidate.applyValidatedPhysicalFoodConsumption(outcome)
        }
    ) -> PebbleAgentFoodConsumptionResult {
        var candidate = session
        do {
            try publish(plan.validatedOutcome, &candidate)
        } catch AgentSessionError.physicalFoodSurvival(.duplicateConsumption) {
            return PebbleAgentFoodConsumptionResult(
                status: .duplicate, outcome: nil, physicalStatus: nil
            )
        } catch {
            return PebbleAgentFoodConsumptionResult(
                status: .sessionRejected, outcome: nil, physicalStatus: nil
            )
        }
        let transaction = gateway.consume(
            PebbleAgentMaterialTransactionRequest(
                transactionID: plan.intent.consumptionID,
                material: plan.material,
                expectedSourceFingerprint: plan.expectedSourceFingerprint,
                expectedDestinationFingerprint: nil
            ),
            from: source,
            sourceSlot: plan.sourceSlot
        ) {
            guard verifyAfterDebit() else { return false }
            session = candidate
            return true
        }
        let status: PebbleAgentFoodConsumptionStatus
        switch transaction.status {
        case .succeeded: status = .succeeded
        case .duplicate: status = .duplicate
        case .staleSource: status = .staleCustody
        case .verificationFailure: status = .verificationFailure
        case .rollbackFailure: status = .rollbackFailure
        default: status = .physicalFailure
        }
        return PebbleAgentFoodConsumptionResult(
            status: status,
            outcome: status == .succeeded ? plan.validatedOutcome : nil,
            physicalStatus: transaction.status
        )
    }
}
