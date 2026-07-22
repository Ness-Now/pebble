import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func handleDependentCare(
        _ arguments: [String],
        world: World
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab care <on|status|proof physical-food-setup>"
        guard let command = arguments.first?.lowercased(),
              arguments.count == 1
                || (arguments.count == 2 && command == "proof") else {
            return failure(usage)
        }
        let dependencies = [
            ("PEBBLELAB_APP_AGENTS=1", featureEnabled),
            ("PEBBLELAB_APP_AGENTS_PERSISTENCE=1", persistenceFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_POPULATION=1", populationFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_LIFECYCLE=1", lifecycleFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_KINSHIP=1", kinshipFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_HOUSEHOLDS=1", householdFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_CARE=1", dependentCareFeatureEnabled),
        ]
        let missing = dependencies.filter { !$0.1 }.map(\.0)
        guard missing.isEmpty else {
            trace("care gates refused missing=\(missing.joined(separator: ","))")
            return failure(
                "PebbleAgents care refused; missing gates: \(missing.joined(separator: ", "))"
            )
        }
        guard var candidate = session else { return failure("No active PebbleAgents session.") }
        guard candidate.survivalEnabled else {
            return failure("PebbleAgents care refused; survival must be enabled first.")
        }
        do {
            switch command {
            case "on":
                if !candidate.dependentCareEnabled {
                    var recorder = replayRecorder
                    if try applyRecordedOperationIfActive(
                        .setDependentCareEnabled(true, configuration: .live),
                        session: &candidate,
                        recorder: &recorder
                    ) == nil {
                        try candidate.setDependentCareEnabled(true)
                    }
                    session = candidate
                    replayRecorder = recorder
                }
                traceDependentCareState(candidate)
                return dependentCareStatus(candidate)
            case "status":
                traceDependentCareState(candidate)
                return dependentCareStatus(candidate)
            case "proof" where arguments[1].lowercased() == "physical-food-setup":
                guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1",
                      activeWorld === world,
                      candidate.physicalFoodSurvivalEnabled,
                      let configuration = candidate.dependentCareSnapshot().configuration,
                      let assignment = candidate.dependentCareSnapshot().assignments
                        .filter({ $0.status == .active })
                        .sorted(by: {
                            if $0.dependentID != $1.dependentID {
                                return $0.dependentID < $1.dependentID
                            }
                            return $0.caregiverID < $1.caregiverID
                        }).first,
                      let probe = probesByAgentId[assignment.caregiverID.rawValue],
                      let dependentProbe = probesByAgentId[assignment.dependentID.rawValue],
                      probe.carriedItems.allSatisfy({ stack in
                          guard let stack else { return true }
                          return foodConsumptionDescriptor(for: stack) == nil
                      }),
                      let slot = probe.carriedItems.firstIndex(where: { $0 == nil }) else {
                    return failure("Physical care proof setup refused.")
                }
                let caregiver = PebbleAgentEmbodiment(probe: probe)
                let dependent = PebbleAgentEmbodiment(probe: dependentProbe)
                var recorder = replayRecorder
                var shadowFood = try candidate.state(for: assignment.caregiverID)
                    .resourceInventory.count(of: .foodRaw)
                if shadowFood == 0 {
                    let shadow = AgentInteractionOutcome(
                        interactionId: "care-physical-shadow-fixture-\(candidate.tick)",
                        agentId: assignment.caregiverID.rawValue,
                        tick: candidate.tick, target: caregiver.position,
                        resource: .foodRaw, status: .succeeded,
                        inventoryDelta: AgentInventoryDelta(resource: .foodRaw, quantity: 1),
                        reason: "historical coarse shadow fixture for physical care proof"
                    )
                    if try applyRecordedOperationIfActive(
                        .interactionOutcome(shadow), session: &candidate, recorder: &recorder
                    ) == nil {
                        try candidate.applyInteractionOutcome(shadow)
                    }
                    shadowFood = try candidate.state(for: assignment.caregiverID)
                        .resourceInventory.count(of: .foodRaw)
                }
                let careBefore = candidate.dependentCareSnapshot()
                guard shadowFood > 0,
                      careBefore.activeNeeds.contains(where: {
                          $0.dependentID == assignment.dependentID
                              && $0.kind == .nourishment
                      }),
                      !careBefore.terminalOutcomes.contains(where: {
                          $0.dependentID == assignment.dependentID
                              && $0.kind == .nourishment && $0.status == .resolved
                      }) else {
                    return failure("Physical care shadow audit failed.")
                }
                trace(
                    "care physical shadow audit tick=\(candidate.tick) caregiver="
                        + "\(assignment.caregiverID.rawValue) dependent="
                        + "\(assignment.dependentID.rawValue) foodRawShadow=\(shadowFood) "
                        + "realFood=none physicalDebit=0 hungerRescue=0 historyDelta=0"
                )
                let occupied = Set<AgentPosition>(probesByAgentId.values.compactMap { other in
                    guard other !== caregiver.probe, !other.dead, other.world === world else {
                        return nil
                    }
                    return AgentPosition(
                        x: Int(other.x.rounded(.down)),
                        y: Int(other.y.rounded(.down)),
                        z: Int(other.z.rounded(.down))
                    )
                })
                let adjacentCandidates = [
                    AgentPosition(
                        x: dependent.position.x + 1,
                        y: dependent.position.y,
                        z: dependent.position.z
                    ),
                    AgentPosition(
                        x: dependent.position.x - 1,
                        y: dependent.position.y,
                        z: dependent.position.z
                    ),
                    AgentPosition(
                        x: dependent.position.x,
                        y: dependent.position.y,
                        z: dependent.position.z + 1
                    ),
                    AgentPosition(
                        x: dependent.position.x,
                        y: dependent.position.y,
                        z: dependent.position.z - 1
                    ),
                    AgentPosition(
                        x: dependent.position.x,
                        y: dependent.position.y + 1,
                        z: dependent.position.z
                    ),
                    AgentPosition(
                        x: dependent.position.x,
                        y: dependent.position.y - 1,
                        z: dependent.position.z
                    ),
                ]
                let approachTarget = adjacentCandidates.first { target in
                    guard !occupied.contains(target), let path = findPath(
                        world, caregiver.x, caregiver.y, caregiver.z,
                        Double(target.x) + 0.5, Double(target.y), Double(target.z) + 0.5,
                        600, true
                    ), !path.isEmpty else { return false }
                    var previous = caregiver.position
                    for node in path {
                        let next = AgentPosition(x: node.x, y: node.y, z: node.z)
                        guard !occupied.contains(next),
                              max(abs(next.x - previous.x), abs(next.z - previous.z)) == 1,
                              (-3...1).contains(next.y - previous.y) else { return false }
                        previous = next
                    }
                    return previous == target
                }
                guard let approachTarget else {
                    return failure("Physical care has no collision-safe Core approach.")
                }
                let approachSteps = try wildSubsistenceExecutor.approach(
                    world: world,
                    actor: caregiver,
                    target: approachTarget,
                    reach: 0
                )
                guard abs(caregiver.position.x - dependent.position.x)
                        + abs(caregiver.position.y - dependent.position.y)
                        + abs(caregiver.position.z - dependent.position.z)
                        <= configuration.careInteractionDistance else {
                    return failure("Physical care approach remained out of range.")
                }
                let update = AgentExternalUpdate(
                    agentId: assignment.caregiverID.rawValue,
                    position: caregiver.position
                )
                if try applyRecordedOperationIfActive(
                    .externalUpdate(update), session: &candidate, recorder: &recorder
                ) == nil {
                    try candidate.applyExternalUpdate(update)
                }
                probe.carriedItems[slot] = ItemStack(iid("sweet_berries"), 1)
                guard probe.carriedItems[slot]?.count == 1,
                      probe.carriedItems[slot].flatMap(foodConsumptionDescriptor)?
                        .canonicalMaterialName == "sweet_berries" else {
                    probe.carriedItems[slot] = nil
                    return failure("Physical care proof setup verification failed.")
                }
                trace(
                    "care physical food setup tick=\(candidate.tick) caregiver="
                        + "\(assignment.caregiverID.rawValue) dependent="
                        + "\(assignment.dependentID.rawValue) material=sweet_berries "
                        + "slot=\(slot) count=1 custody=real approachSteps=\(approachSteps) "
                        + "movement=CorePath+Entity.move bootstrap=bounded"
                )
                session = candidate
                replayRecorder = recorder
                return success("Physical dependent-care food fixture ready.")
            default:
                return failure(usage)
            }
        } catch {
            return failure("PebbleAgents care command failed: \(error)")
        }
    }

    func traceDependentCareState(_ session: AgentSimulationSession) {
        let snapshot = session.dependentCareSnapshot()
        trace(
            "care tick=\(session.tick) enabled=\(snapshot.enabled ? 1 : 0) "
                + "assignments=\(snapshot.assignments.filter { $0.status == .active }.count) "
                + "needs=\(snapshot.activeNeeds.count) "
                + "engagements=\(snapshot.activeEngagements.count) "
                + "atRisk=\(snapshot.atRiskDependentIDs.map(\.rawValue).joined(separator: ",")) "
                + "digest=\(snapshot.digest) worldMutation=none"
        )
    }

    private func dependentCareStatus(
        _ session: AgentSimulationSession
    ) -> PebbleAgentCommandResult {
        let snapshot = session.dependentCareSnapshot()
        let assignments = snapshot.assignments.filter { $0.status == .active }.map {
            "\($0.dependentID.rawValue)->\($0.caregiverID.rawValue)@\($0.householdID.rawValue)"
        }.joined(separator: ",")
        return success(
            "Care gate=enabled active=\(snapshot.enabled ? 1 : 0) "
                + "schema=\(snapshot.enabled ? 9 : 8) "
                + "assignments=\(assignments.isEmpty ? "none" : assignments) "
                + "needs=\(snapshot.activeNeeds.count) "
                + "engagements=\(snapshot.activeEngagements.count) "
                + "atRisk=\(snapshot.atRiskDependentIDs.map(\.rawValue).joined(separator: ",")) "
                + "digest=\(snapshot.digest) worldMutation=none."
        )
    }
}
