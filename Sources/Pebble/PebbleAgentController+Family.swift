import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func handleFamily(
        _ arguments: [String],
        world: World
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab family <on|status"
            + "|propose actor recipient receipt"
            + "|accept proposal actor recipient receipt"
            + "|separate union actor recipient receipt"
            + "|lineage founder operation"
            + "|house-found founder operation"
            + "|house-cofound founderA founderB receiptA receiptB"
            + "|house-leave house agent operation>"
        guard let command = arguments.first?.lowercased() else {
            return failure(usage)
        }
        let dependencies = [
            ("PEBBLELAB_APP_AGENTS=1", featureEnabled),
            ("PEBBLELAB_APP_AGENTS_PERSISTENCE=1", persistenceFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_POPULATION=1", populationFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_LIFECYCLE=1", lifecycleFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_KINSHIP=1", kinshipFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_HOUSEHOLDS=1", householdFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_CHILDHOOD=1", childhoodFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_FAMILY=1", familyFeatureEnabled),
        ]
        let missing = dependencies.filter { !$0.1 }.map(\.0)
        guard missing.isEmpty else {
            return failure(
                "PebbleAgents family refused; missing gates: "
                    + missing.joined(separator: ", ")
            )
        }
        guard var candidate = session, activeWorld === world else {
            return failure("No active PebbleAgents session.")
        }
        do {
            var recorder = replayRecorder
            switch command {
            case "on" where arguments.count == 1:
                if !candidate.familyV1Enabled {
                    if try applyRecordedOperationIfActive(
                        .setFamilyV1Enabled(true, configuration: .live),
                        session: &candidate, recorder: &recorder
                    ) == nil {
                        try candidate.setFamilyV1Enabled(true)
                    }
                }
            case "status" where arguments.count == 1:
                break
            case "propose" where arguments.count == 4:
                guard let actor = AgentID(rawValue: arguments[1]),
                      let recipient = AgentID(rawValue: arguments[2]) else {
                    return failure(usage)
                }
                let receipt = try familyInteractionAdapter.observe(
                    world: world, session: candidate,
                    probesByAgentID: probesByAgentId,
                    receiptID: arguments[3], kind: .unionProposal,
                    actorID: actor, counterpartyID: recipient
                )
                traceFamilyPhysicalReceipt(receipt)
                if try applyRecordedOperationIfActive(
                    .proposeUnion(receipt),
                    session: &candidate, recorder: &recorder
                ) == nil {
                    _ = try candidate.proposeUnion(receipt)
                }
            case "accept" where arguments.count == 5:
                guard let proposalID = AgentUnionProposalID(rawValue: arguments[1]),
                      let actor = AgentID(rawValue: arguments[2]),
                      let proposer = AgentID(rawValue: arguments[3]) else {
                    return failure(usage)
                }
                let receipt = try familyInteractionAdapter.observe(
                    world: world, session: candidate,
                    probesByAgentID: probesByAgentId,
                    receiptID: arguments[4], kind: .unionAcceptance,
                    actorID: actor, counterpartyID: proposer
                )
                traceFamilyPhysicalReceipt(receipt)
                if try applyRecordedOperationIfActive(
                    .acceptUnion(proposalID: proposalID, receipt: receipt),
                    session: &candidate, recorder: &recorder
                ) == nil {
                    _ = try candidate.acceptUnion(
                        proposalID: proposalID, receipt: receipt
                    )
                }
            case "separate" where arguments.count == 5:
                guard let unionID = AgentUnionID(rawValue: arguments[1]),
                      let actor = AgentID(rawValue: arguments[2]),
                      let partner = AgentID(rawValue: arguments[3]) else {
                    return failure(usage)
                }
                let receipt = try familyInteractionAdapter.observe(
                    world: world, session: candidate,
                    probesByAgentID: probesByAgentId,
                    receiptID: arguments[4], kind: .unionSeparation,
                    actorID: actor, counterpartyID: partner
                )
                traceFamilyPhysicalReceipt(receipt)
                if try applyRecordedOperationIfActive(
                    .endUnion(
                        unionID: unionID, reason: .unilateralSeparation,
                        receipt: receipt
                    ),
                    session: &candidate, recorder: &recorder
                ) == nil {
                    try candidate.endUnion(
                        unionID: unionID, reason: .unilateralSeparation,
                        receipt: receipt
                    )
                }
            case "lineage" where arguments.count == 3:
                guard let founder = AgentID(rawValue: arguments[1]) else {
                    return failure(usage)
                }
                if try applyRecordedOperationIfActive(
                    .foundLineage(
                        rootPersonID: founder, actorID: founder,
                        operationID: arguments[2]
                    ),
                    session: &candidate, recorder: &recorder
                ) == nil {
                    _ = try candidate.foundLineage(
                        rootPersonID: founder, actorID: founder,
                        operationID: arguments[2]
                    )
                }
            case "house-found" where arguments.count == 3:
                guard let founder = AgentID(rawValue: arguments[1]) else {
                    return failure(usage)
                }
                if try applyRecordedOperationIfActive(
                    .foundHouse(founderID: founder, operationID: arguments[2]),
                    session: &candidate, recorder: &recorder
                ) == nil {
                    _ = try candidate.foundHouse(
                        founderID: founder, operationID: arguments[2]
                    )
                }
            case "house-cofound" where arguments.count == 5:
                guard let first = AgentID(rawValue: arguments[1]),
                      let second = AgentID(rawValue: arguments[2]) else {
                    return failure(usage)
                }
                let receipts = [
                    try familyInteractionAdapter.observe(
                        world: world, session: candidate,
                        probesByAgentID: probesByAgentId,
                        receiptID: arguments[3], kind: .houseCoFoundation,
                        actorID: first, counterpartyID: second
                    ),
                    try familyInteractionAdapter.observe(
                        world: world, session: candidate,
                        probesByAgentID: probesByAgentId,
                        receiptID: arguments[4], kind: .houseCoFoundation,
                        actorID: second, counterpartyID: first
                    ),
                ]
                receipts.forEach(traceFamilyPhysicalReceipt)
                if try applyRecordedOperationIfActive(
                    .coFoundHouse(founderIDs: [first, second], receipts: receipts),
                    session: &candidate, recorder: &recorder
                ) == nil {
                    _ = try candidate.coFoundHouse(
                        founderIDs: [first, second], receipts: receipts
                    )
                }
            case "house-leave" where arguments.count == 4:
                guard let houseID = AgentHouseID(rawValue: arguments[1]),
                      let agentID = AgentID(rawValue: arguments[2]) else {
                    return failure(usage)
                }
                if try applyRecordedOperationIfActive(
                    .leaveHouse(
                        houseID: houseID, agentID: agentID,
                        operationID: arguments[3]
                    ),
                    session: &candidate, recorder: &recorder
                ) == nil {
                    try candidate.leaveHouse(
                        houseID, agentID: agentID, operationID: arguments[3]
                    )
                }
            default:
                return failure(usage)
            }
            session = candidate
            replayRecorder = recorder
            return familyStatus(candidate)
        } catch {
            return failure("PebbleAgents family command failed: \(error)")
        }
    }

    func familyStatus(_ session: AgentSimulationSession) -> PebbleAgentCommandResult {
        let snapshot = session.familySnapshot()
        let activeUnions = snapshot.unions.filter { $0.status == .active }
        let activeMemberships = snapshot.houseMembershipPeriods.filter {
            $0.leftTick == nil
        }
        let proposalText = snapshot.proposals.map {
            "\($0.proposalID.rawValue):\($0.proposerID.rawValue)"
                + ">\($0.recipientID.rawValue):\($0.status.rawValue)"
        }.joined(separator: ",")
        let unionText = snapshot.unions.map {
            "\($0.unionID.rawValue):"
                + "\($0.partnerIDs.map(\.rawValue).joined(separator: "+"))"
                + ":\($0.status.rawValue)"
                + ":\($0.terminationReason?.rawValue ?? "none")"
        }.joined(separator: ",")
        let lineageText = snapshot.lineages.map {
            "\($0.lineageID.rawValue):\($0.rootPersonID.rawValue)"
        }.joined(separator: ",")
        let houseText = snapshot.houses.map {
            "\($0.houseID.rawValue):"
                + "\($0.founderIDs.map(\.rawValue).joined(separator: "+"))"
                + ":\($0.status.rawValue)"
        }.joined(separator: ",")
        let membershipText = snapshot.houseMembershipPeriods.map {
            "\($0.houseID.rawValue)>\($0.agentID.rawValue):\($0.basis.rawValue)"
                + ":\($0.leftTick == nil ? "active" : "ended")"
        }.joined(separator: ",")
        let householdText = session.householdSnapshot().currentMemberships.map {
            "\($0.agentID.rawValue):\($0.householdID.rawValue)"
        }.joined(separator: ",")
        let duplicateCount =
            max(0, snapshot.unions.count - Set(snapshot.unions.map(\.unionID)).count)
            + max(0, snapshot.houses.count - Set(snapshot.houses.map(\.houseID)).count)
            + max(
                0,
                activeMemberships.count
                    - Set(activeMemberships.map {
                        "\($0.houseID.rawValue)|\($0.agentID.rawValue)"
                    }).count
            )
        let message = "family enabled=\(snapshot.enabled ? 1 : 0)"
            + " schema=\(session.durableState().schemaVersion)"
            + " proposals=\(snapshot.proposals.count)"
            + " unions=\(snapshot.unions.count)"
            + " activeUnions=\(activeUnions.count)"
            + " lineages=\(snapshot.lineages.count)"
            + " houses=\(snapshot.houses.count)"
            + " activeHouseMemberships=\(activeMemberships.count)"
            + " proposalState=\(proposalText.isEmpty ? "none" : proposalText)"
            + " unionState=\(unionText.isEmpty ? "none" : unionText)"
            + " lineageState=\(lineageText.isEmpty ? "none" : lineageText)"
            + " houseState=\(houseText.isEmpty ? "none" : houseText)"
            + " membershipState=\(membershipText.isEmpty ? "none" : membershipText)"
            + " householdState=\(householdText.isEmpty ? "none" : householdText)"
            + " duplicates=\(duplicateCount)"
            + " digest=\(snapshot.digest)"
            + " mutation=none worldMutation=none"
        trace(message)
        return success(message)
    }

    private func traceFamilyPhysicalReceipt(
        _ receipt: AgentFamilyInteractionReceipt
    ) {
        let distance = abs(receipt.actorPosition.x - receipt.counterpartyPosition.x)
            + abs(receipt.actorPosition.y - receipt.counterpartyPosition.y)
            + abs(receipt.actorPosition.z - receipt.counterpartyPosition.z)
        trace(
            "family physical interaction receipt=\(receipt.receiptID)"
                + " kind=\(receipt.kind.rawValue)"
                + " actor=\(receipt.actorID.rawValue)"
                + " counterparty=\(receipt.counterpartyID.rawValue)"
                + " tick=\(receipt.observedTick)"
                + " distance=\(distance)"
                + " communication=\(receipt.communicationVerified ? 1 : 0)"
                + " probePositions="
                + "\(receipt.actorPosition.x),\(receipt.actorPosition.y),"
                + "\(receipt.actorPosition.z)>"
                + "\(receipt.counterpartyPosition.x),"
                + "\(receipt.counterpartyPosition.y),"
                + "\(receipt.counterpartyPosition.z)"
                + " worldMutation=none"
        )
    }
}
