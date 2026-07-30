import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func handleDependentCare(
        _ arguments: [String],
        world: World
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab care <on|status|proof "
            + "<proximity-setup|supervision-separation|supervision-resume"
            + "|physical-food-setup>>"
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
            case "proof" where arguments[1].lowercased() == "proximity-setup":
                guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1",
                      activeWorld === world,
                      let configuration = candidate.dependentCareSnapshot()
                        .configuration,
                      let assignment = candidate.dependentCareSnapshot()
                        .assignments.filter({ $0.status == .active })
                        .sorted(by: {
                            if $0.dependentID != $1.dependentID {
                                return $0.dependentID < $1.dependentID
                            }
                            return $0.caregiverID < $1.caregiverID
                        }).first else {
                    return failure("Physical care proximity setup refused.")
                }
                var recorder = replayRecorder
                let approachSteps = try approachDependentForCare(
                    assignment: assignment,
                    maximumDistance: configuration.careInteractionDistance,
                    candidate: &candidate,
                    recorder: &recorder,
                    world: world
                )
                session = candidate
                replayRecorder = recorder
                trace(
                    "care proximity setup tick=\(candidate.tick) caregiver="
                        + "\(assignment.caregiverID.rawValue) dependent="
                        + "\(assignment.dependentID.rawValue) approachSteps="
                        + "\(approachSteps) distance="
                        + "\(configuration.careInteractionDistance) "
                        + "moved=dependent movement=CorePath+Entity.move outcome=none "
                        + "socialDelta=0 worldMutation=bounded"
                )
                return success("Physical dependent-care proximity prepared.")
            case "proof" where arguments[1].lowercased()
                    == "supervision-separation":
                guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1",
                      activeWorld === world,
                      let configuration = candidate.dependentCareSnapshot()
                        .configuration,
                      let engagement = candidate.dependentCareSnapshot()
                        .activeEngagements.filter({
                            $0.kind == .supervise
                        }).sorted(by: {
                            if $0.dependentID != $1.dependentID {
                                return $0.dependentID < $1.dependentID
                            }
                            return $0.caregiverID < $1.caregiverID
                        }).first,
                      let assignment = candidate.dependentCareSnapshot()
                        .assignments.first(where: {
                            $0.status == .active
                                && $0.dependentID == engagement.dependentID
                                && $0.caregiverID == engagement.caregiverID
                        }) else {
                    return failure("Physical supervision separation refused.")
                }
                var recorder = replayRecorder
                let separationSteps = try separateDependentFromCare(
                    assignment: assignment,
                    maximumDistance: configuration.careInteractionDistance,
                    candidate: &candidate,
                    recorder: &recorder,
                    world: world
                )
                session = candidate
                replayRecorder = recorder
                trace(
                    "care supervision separation tick=\(candidate.tick) caregiver="
                        + "\(assignment.caregiverID.rawValue) dependent="
                        + "\(assignment.dependentID.rawValue) separationSteps="
                        + "\(separationSteps) distance="
                        + "\(configuration.careInteractionDistance) "
                        + "moved=dependent movement=CorePath+Entity.move "
                        + "socialDelta=0 worldMutation=bounded"
                )
                return success("Physical supervision interruption prepared.")
            case "proof" where arguments[1].lowercased()
                    == "supervision-resume":
                guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1",
                      activeWorld === world,
                      let configuration = candidate.dependentCareSnapshot()
                        .configuration,
                      let assignment = candidate.dependentCareSnapshot()
                        .assignments.filter({
                            $0.status == .active
                        }).sorted(by: {
                            if $0.dependentID != $1.dependentID {
                                return $0.dependentID < $1.dependentID
                            }
                            return $0.caregiverID < $1.caregiverID
                        }).first else {
                    return failure("Physical supervision resume refused.")
                }
                var recorder = replayRecorder
                let resumeSteps = try restorePhysicalCareProximity(
                    assignment: assignment,
                    maximumDistance: configuration.careInteractionDistance,
                    candidate: &candidate,
                    recorder: &recorder,
                    world: world
                )
                session = candidate
                replayRecorder = recorder
                let dependentState = try candidate.state(
                    for: assignment.dependentID
                )
                let caregiverState = try candidate.state(
                    for: assignment.caregiverID
                )
                let atHome = dependentState.position
                    == dependentState.homePosition
                let inRange = max(
                    abs(caregiverState.position.x - dependentState.position.x),
                    abs(caregiverState.position.y - dependentState.position.y),
                    abs(caregiverState.position.z - dependentState.position.z)
                ) <= configuration.careInteractionDistance
                trace(
                    "care supervision resume tick=\(candidate.tick) caregiver="
                        + "\(assignment.caregiverID.rawValue) dependent="
                        + "\(assignment.dependentID.rawValue) movementSteps="
                        + "\(resumeSteps) atHome=\(atHome ? 1 : 0) "
                        + "inRange=\(inRange ? 1 : 0) "
                        + "movement=CorePath+Entity.move socialDelta=0 "
                        + "worldMutation=bounded"
                )
                return success("Physical supervision resume prepared.")
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
                      probe.carriedItems.allSatisfy({ stack in
                          guard let stack else { return true }
                          return foodConsumptionDescriptor(for: stack) == nil
                      }),
                      let slot = probe.carriedItems.firstIndex(where: { $0 == nil }) else {
                    return failure("Physical care proof setup refused.")
                }
                let caregiver = PebbleAgentEmbodiment(probe: probe)
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
                let approachSteps = try approachDependentForCare(
                    assignment: assignment,
                    maximumDistance: configuration.careInteractionDistance,
                    candidate: &candidate,
                    recorder: &recorder,
                    world: world
                )
                probe.carriedItems[slot] = ItemStack(iid("bread"), 1)
                guard probe.carriedItems[slot]?.count == 1,
                      probe.carriedItems[slot].flatMap(foodConsumptionDescriptor)?
                        .canonicalMaterialName == "bread" else {
                    probe.carriedItems[slot] = nil
                    return failure("Physical care proof setup verification failed.")
                }
                trace(
                    "care physical food setup tick=\(candidate.tick) caregiver="
                        + "\(assignment.caregiverID.rawValue) dependent="
                        + "\(assignment.dependentID.rawValue) material=bread "
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

    private func approachDependentForCare(
        assignment: AgentCareAssignment,
        maximumDistance: Int,
        candidate: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?,
        world: World
    ) throws -> Int {
        guard let caregiverProbe = probesByAgentId[
                assignment.caregiverID.rawValue
              ],
              let probe = probesByAgentId[
                assignment.dependentID.rawValue
              ] else {
            throw ControllerError.lifecycleBoundary(
                "physical care embodiment missing"
            )
        }
        let caregiver = PebbleAgentEmbodiment(probe: caregiverProbe)
        let dependent = PebbleAgentEmbodiment(probe: probe)
        let distance = max(
            abs(caregiver.position.x - dependent.position.x),
            abs(caregiver.position.y - dependent.position.y),
            abs(caregiver.position.z - dependent.position.z)
        )
        if distance <= maximumDistance { return 0 }
        let occupied = Set<AgentPosition>(
            probesByAgentId.values.compactMap { other in
                guard other !== dependent.probe, !other.dead,
                      other.world === world else { return nil }
                return AgentPosition(
                    x: Int(other.x.rounded(.down)),
                    y: Int(other.y.rounded(.down)),
                    z: Int(other.z.rounded(.down))
                )
            }
        )
        let adjacentCandidates = [
            AgentPosition(
                x: caregiver.position.x + 1,
                y: caregiver.position.y,
                z: caregiver.position.z
            ),
            AgentPosition(
                x: caregiver.position.x - 1,
                y: caregiver.position.y,
                z: caregiver.position.z
            ),
            AgentPosition(
                x: caregiver.position.x,
                y: caregiver.position.y,
                z: caregiver.position.z + 1
            ),
            AgentPosition(
                x: caregiver.position.x,
                y: caregiver.position.y,
                z: caregiver.position.z - 1
            ),
            AgentPosition(
                x: caregiver.position.x,
                y: caregiver.position.y + 1,
                z: caregiver.position.z
            ),
            AgentPosition(
                x: caregiver.position.x,
                y: caregiver.position.y - 1,
                z: caregiver.position.z
            ),
        ]
        let approachNode = adjacentCandidates.compactMap {
            target -> AgentPosition? in
            guard !occupied.contains(target), let path = findPath(
                world, dependent.x, dependent.y, dependent.z,
                Double(target.x) + 0.5, Double(target.y),
                Double(target.z) + 0.5, 600, true
            ), let node = path.first else { return nil }
            let next = AgentPosition(x: node.x, y: node.y, z: node.z)
            guard !occupied.contains(next),
                  max(
                    abs(next.x - dependent.position.x),
                    abs(next.z - dependent.position.z)
                  ) == 1,
                  (-3...1).contains(next.y - dependent.position.y),
                  max(
                    abs(next.x - caregiver.position.x),
                    abs(next.y - caregiver.position.y),
                    abs(next.z - caregiver.position.z)
                  ) <= maximumDistance else {
                return nil
            }
            return next
        }.first
        guard let approachNode else {
            throw ControllerError.lifecycleBoundary(
                "physical care has no collision-safe Core approach"
            )
        }
        let original = (probe.x, probe.y, probe.z)
        do {
            let dx = Double(approachNode.x) + 0.5 - dependent.x
            let dy = Double(approachNode.y) - dependent.y
            let dz = Double(approachNode.z) + 0.5 - dependent.z
            dependent.probe.yaw = detAtan2(-dx, dz)
            dependent.probe.move(dx, dy, dz)
            guard dependent.position == approachNode else {
                throw ControllerError.lifecycleBoundary(
                    "physical care Core approach step was refused"
                )
            }
            let actualDistance = max(
                abs(caregiver.position.x - dependent.position.x),
                abs(caregiver.position.y - dependent.position.y),
                abs(caregiver.position.z - dependent.position.z)
            )
            guard actualDistance <= maximumDistance else {
                throw ControllerError.lifecycleBoundary(
                    "physical care approach remained out of range"
                )
            }
            let update = AgentExternalUpdate(
                agentId: assignment.dependentID.rawValue,
                position: dependent.position
            )
            if try applyRecordedOperationIfActive(
                .externalUpdate(update),
                session: &candidate,
                recorder: &recorder
            ) == nil {
                try candidate.applyExternalUpdate(update)
            }
        } catch {
            probe.move(original.0 - probe.x, 0, original.2 - probe.z)
            probe.move(0, original.1 - probe.y, 0)
            guard probe.x == original.0, probe.y == original.1,
                  probe.z == original.2 else {
                throw ControllerError.lifecycleBoundary(
                    "physical care approach rollback failed"
                )
            }
            throw error
        }
        return 1
    }

    private func separateDependentFromCare(
        assignment: AgentCareAssignment,
        maximumDistance: Int,
        candidate: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?,
        world: World
    ) throws -> Int {
        guard let caregiverProbe = probesByAgentId[
                assignment.caregiverID.rawValue
              ],
              let probe = probesByAgentId[
                assignment.dependentID.rawValue
              ] else {
            throw ControllerError.lifecycleBoundary(
                "physical supervision embodiment missing"
            )
        }
        let caregiver = PebbleAgentEmbodiment(probe: caregiverProbe)
        let dependent = PebbleAgentEmbodiment(probe: probe)
        let currentDistance = max(
            abs(caregiver.position.x - dependent.position.x),
            abs(caregiver.position.y - dependent.position.y),
            abs(caregiver.position.z - dependent.position.z)
        )
        guard currentDistance <= maximumDistance else { return 0 }
        let dependentHome = try candidate.state(
            for: assignment.dependentID
        ).homePosition
        let occupied = Set<AgentPosition>(
            probesByAgentId.values.compactMap { other in
                guard other !== dependent.probe, !other.dead,
                      other.world === world else { return nil }
                return AgentPosition(
                    x: Int(other.x.rounded(.down)),
                    y: Int(other.y.rounded(.down)),
                    z: Int(other.z.rounded(.down))
                )
            }
        )
        let offset = maximumDistance + 1
        let separationTargets = [dependentHome] + [
            AgentPosition(
                x: caregiver.position.x + offset,
                y: caregiver.position.y, z: caregiver.position.z
            ),
            AgentPosition(
                x: caregiver.position.x - offset,
                y: caregiver.position.y, z: caregiver.position.z
            ),
            AgentPosition(
                x: caregiver.position.x,
                y: caregiver.position.y,
                z: caregiver.position.z + offset
            ),
            AgentPosition(
                x: caregiver.position.x,
                y: caregiver.position.y,
                z: caregiver.position.z - offset
            ),
        ]
        let separationNode = separationTargets.compactMap {
            target -> AgentPosition? in
            guard let path = findPath(
                world, dependent.x, dependent.y, dependent.z,
                Double(target.x) + 0.5, Double(target.y),
                Double(target.z) + 0.5, 600, true
            ), let node = path.first else { return nil }
            let next = AgentPosition(x: node.x, y: node.y, z: node.z)
            guard !occupied.contains(next),
                  max(
                    abs(next.x - dependent.position.x),
                    abs(next.z - dependent.position.z)
                  ) == 1,
                  (-3...1).contains(next.y - dependent.position.y),
                  max(
                    abs(next.x - caregiver.position.x),
                    abs(next.y - caregiver.position.y),
                    abs(next.z - caregiver.position.z)
                  ) > maximumDistance else {
                return nil
            }
            return next
        }.first
        guard let separationNode else {
            throw ControllerError.lifecycleBoundary(
                "physical supervision has no collision-safe Core separation"
            )
        }
        let original = (probe.x, probe.y, probe.z)
        do {
            let dx = Double(separationNode.x) + 0.5 - dependent.x
            let dy = Double(separationNode.y) - dependent.y
            let dz = Double(separationNode.z) + 0.5 - dependent.z
            dependent.probe.yaw = detAtan2(-dx, dz)
            dependent.probe.move(dx, dy, dz)
            guard dependent.position == separationNode else {
                throw ControllerError.lifecycleBoundary(
                    "physical supervision Core separation step was refused"
                )
            }
            let update = AgentExternalUpdate(
                agentId: assignment.dependentID.rawValue,
                position: dependent.position
            )
            if try applyRecordedOperationIfActive(
                .externalUpdate(update),
                session: &candidate,
                recorder: &recorder
            ) == nil {
                try candidate.applyExternalUpdate(update)
            }
        } catch {
            probe.move(original.0 - probe.x, 0, original.2 - probe.z)
            probe.move(0, original.1 - probe.y, 0)
            guard probe.x == original.0, probe.y == original.1,
                  probe.z == original.2 else {
                throw ControllerError.lifecycleBoundary(
                    "physical supervision separation rollback failed"
                )
            }
            throw error
        }
        return 1
    }

    private func restorePhysicalCareProximity(
        assignment: AgentCareAssignment,
        maximumDistance: Int,
        candidate: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?,
        world: World
    ) throws -> Int {
        guard let caregiverProbe = probesByAgentId[
                assignment.caregiverID.rawValue
              ],
              let dependentProbe = probesByAgentId[
                assignment.dependentID.rawValue
              ] else {
            throw ControllerError.lifecycleBoundary(
                "physical supervision resume embodiment missing"
            )
        }
        let caregiver = PebbleAgentEmbodiment(probe: caregiverProbe)
        let dependent = PebbleAgentEmbodiment(probe: dependentProbe)
        let home = try candidate.state(for: assignment.dependentID)
            .homePosition
        let originalCaregiver = (
            caregiverProbe.x, caregiverProbe.y, caregiverProbe.z
        )
        let originalDependent = (
            dependentProbe.x, dependentProbe.y, dependentProbe.z
        )
        var candidateCopy = candidate
        var recorderCopy = recorder
        var stepCount = 0
        do {
            let occupied = Set<AgentPosition>(
                probesByAgentId.values.compactMap { other in
                    guard other !== caregiver.probe,
                          !other.dead, other.world === world else {
                        return nil
                    }
                    return AgentPosition(
                        x: Int(other.x.rounded(.down)),
                        y: Int(other.y.rounded(.down)),
                        z: Int(other.z.rounded(.down))
                    )
                }
            )
            let egressCandidates = [
                AgentPosition(x: home.x, y: home.y, z: home.z + 1),
                AgentPosition(x: home.x, y: home.y, z: home.z - 1),
                AgentPosition(x: home.x - 1, y: home.y, z: home.z),
                AgentPosition(x: home.x + 1, y: home.y, z: home.z),
            ]
            if caregiver.position == home {
                let egress = egressCandidates.first {
                    guard !occupied.contains($0),
                          let path = findPath(
                        world, caregiver.x, caregiver.y, caregiver.z,
                        Double($0.x) + 0.5, Double($0.y),
                        Double($0.z) + 0.5, 600, true
                          ), let node = path.first else { return false }
                    return AgentPosition(
                        x: node.x, y: node.y, z: node.z
                    ) == $0
                }
                guard let egress else {
                    throw ControllerError.lifecycleBoundary(
                        "physical supervision resume has no caregiver egress"
                    )
                }
                caregiver.probe.move(
                    Double(egress.x) + 0.5 - caregiver.x,
                    Double(egress.y) - caregiver.y,
                    Double(egress.z) + 0.5 - caregiver.z
                )
                guard caregiver.position == egress else {
                    throw ControllerError.lifecycleBoundary(
                        "physical supervision caregiver egress was refused"
                    )
                }
                stepCount += 1
            }
            guard findPath(
                world, dependent.x, dependent.y, dependent.z,
                Double(home.x) + 0.5, Double(home.y),
                Double(home.z) + 0.5, 600, true
            ) != nil else {
                throw ControllerError.lifecycleBoundary(
                    "physical supervision dependent has no Core route home"
                )
            }
            while dependent.position.x != home.x && stepCount < 12 {
                let before = dependent.position
                let dx = home.x > before.x ? 1.0 : -1.0
                dependent.probe.move(dx, 0, 0)
                guard dependent.position.x == before.x + Int(dx),
                      dependent.position.z == before.z else {
                    throw ControllerError.lifecycleBoundary(
                        "physical supervision dependent horizontal x step was refused"
                    )
                }
                stepCount += 1
            }
            while dependent.position.z != home.z && stepCount < 12 {
                let before = dependent.position
                let dz = home.z > before.z ? 1.0 : -1.0
                dependent.probe.move(0, 0, dz)
                guard dependent.position.z == before.z + Int(dz),
                      dependent.position.x == before.x else {
                    throw ControllerError.lifecycleBoundary(
                        "physical supervision dependent horizontal z step was refused"
                    )
                }
                stepCount += 1
            }
            if dependent.position.y != home.y && stepCount < 12 {
                dependent.probe.move(
                    0, Double(home.y - dependent.position.y), 0
                )
                guard dependent.position == home else {
                    throw ControllerError.lifecycleBoundary(
                        "physical supervision dependent vertical step was refused"
                    )
                }
                stepCount += 1
            }
            guard stepCount > 0, dependent.position == home,
                  max(
                      abs(caregiver.position.x - dependent.position.x),
                      abs(caregiver.position.y - dependent.position.y),
                    abs(caregiver.position.z - dependent.position.z)
                  ) <= maximumDistance else {
                throw ControllerError.lifecycleBoundary(
                    "physical supervision resume verification failed"
                )
            }
            for update in [
                AgentExternalUpdate(
                    agentId: assignment.caregiverID.rawValue,
                    position: caregiver.position
                ),
                AgentExternalUpdate(
                    agentId: assignment.dependentID.rawValue,
                    position: dependent.position
                ),
            ] {
                if try applyRecordedOperationIfActive(
                    .externalUpdate(update),
                    session: &candidateCopy,
                    recorder: &recorderCopy
                ) == nil {
                    try candidateCopy.applyExternalUpdate(update)
                }
            }
            candidate = candidateCopy
            recorder = recorderCopy
            return stepCount
        } catch {
            caregiverProbe.move(
                originalCaregiver.0 - caregiverProbe.x, 0,
                originalCaregiver.2 - caregiverProbe.z
            )
            caregiverProbe.move(
                0, originalCaregiver.1 - caregiverProbe.y, 0
            )
            dependentProbe.move(
                originalDependent.0 - dependentProbe.x, 0,
                originalDependent.2 - dependentProbe.z
            )
            dependentProbe.move(
                0, originalDependent.1 - dependentProbe.y, 0
            )
            guard caregiverProbe.x == originalCaregiver.0,
                  caregiverProbe.y == originalCaregiver.1,
                  caregiverProbe.z == originalCaregiver.2,
                  dependentProbe.x == originalDependent.0,
                  dependentProbe.y == originalDependent.1,
                  dependentProbe.z == originalDependent.2 else {
                throw ControllerError.lifecycleBoundary(
                    "physical supervision resume rollback failed"
                )
            }
            throw error
        }
    }

    func traceDependentCareState(_ session: AgentSimulationSession) {
        let snapshot = session.dependentCareSnapshot()
        let supervision = snapshot.activeEngagements.filter {
            $0.kind == .supervise
        }.sorted {
            if $0.dependentID != $1.dependentID {
                return $0.dependentID < $1.dependentID
            }
            return $0.caregiverID < $1.caregiverID
        }.map {
            "\($0.dependentID.rawValue)->\($0.caregiverID.rawValue)"
                + ":elapsed=\(max(0, session.tick - $0.startedTick))"
                + ":verified=\($0.verifiedEngagedTicks)"
                + ":interrupted=\($0.interruptedTicks)"
        }.joined(separator: ",")
        trace(
            "care tick=\(session.tick) enabled=\(snapshot.enabled ? 1 : 0) "
                + "assignments=\(snapshot.assignments.filter { $0.status == .active }.count) "
                + "needs=\(snapshot.activeNeeds.count) "
                + "engagements=\(snapshot.activeEngagements.count) "
                + "supervision=\(supervision.isEmpty ? "none" : supervision) "
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
