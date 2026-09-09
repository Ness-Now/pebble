import PebbleCore

struct PebbleAgentStreamingCustodyProofAcquisition {
    let probe: LabCoreAgentEntity
    let sourceEntityID: Int
    let stack: ItemStack
}

extension PebbleAgentController {
    /// Disposable proof support that obtains custody through the production
    /// ItemEntity acquisition gateway. The proof never writes probe inventory
    /// directly, so streaming is exercised against a real custody outcome.
    func acquireStreamingCustodyProofItem(
        world: World,
        agentID: String,
        itemName: String,
        count: Int,
        transactionID: String
    ) throws -> PebbleAgentStreamingCustodyProofAcquisition {
        guard activeWorld === world,
              session != nil,
              let probe = probesByAgentId[agentID],
              PebbleAgentEmbodiment(probe: probe).isValid(in: world),
              probe.carriedItems.allSatisfy({ $0 == nil }) else {
            throw ControllerError.feedbackBoundary(
                "streaming custody proof requires one empty live embodiment"
            )
        }
        let stack = ItemStack(iid(itemName), count)
        let sourceItem = spawnItem(
            world, probe.x, probe.y + 0.5, probe.z, stack.copy(), 0, 0, 0
        )
        guard let source = PebbleAgentItemEntityCustodyEndpoint(
            spawnedItemEntityIDs: [sourceItem.id], world: world
        ) else {
            world.removeEntity(sourceItem)
            throw ControllerError.feedbackBoundary(
                "streaming custody proof source endpoint unavailable"
            )
        }
        let destination = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            probe, in: world
        )
        let outcome = materialCustodyGateway.acquireItemEntities(
            PebbleAgentItemEntityAcquisitionRequest(
                transactionID: transactionID,
                spawnedItemEntityIDs: [sourceItem.id],
                expectedDestinationFingerprint:
                    try materialCustodyGateway.fingerprint(destination)
            ),
            from: source,
            to: destination
        )
        guard outcome.succeeded,
              outcome.quantityMoved == count,
              !world.entities.contains(where: { $0 === sourceItem }),
              probe.carriedItems.compactMap({ $0 }).reduce(0, {
                  $0 + ($1 == stack ? $1.count : 0)
              }) == count else {
            throw ControllerError.feedbackBoundary(
                "streaming custody proof gateway acquisition failed"
            )
        }
        return PebbleAgentStreamingCustodyProofAcquisition(
            probe: probe,
            sourceEntityID: sourceItem.id,
            stack: stack
        )
    }
}
