import Foundation
import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func handleWorkProfessions(
        _ arguments: [String],
        world: World
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab work-professions <on|refresh|match|record|crisis|resume|status|final>"
        guard let command = arguments.first?.lowercased(), arguments.count == 1 else {
            return failure(usage)
        }
        let missing = workProfessionGateDependencies().filter { !$0.1 }.map(\.0)
        guard missing.isEmpty else {
            return failure("WorkProfessions refused; missing gates: " + missing.joined(separator: ", "))
        }
        guard var candidate = session, activeWorld === world else {
            return failure("No active PebbleAgents session.")
        }
        guard candidate.populationEnabled, candidate.lifecycleEnabled,
              candidate.skillsEnabled else {
            return failure("WorkProfessions requires population, lifecycle, and skills.")
        }
        do {
            var recorder = replayRecorder
            switch command {
            case "on":
                if !candidate.workCommitmentsEnabled {
                    if try applyRecordedOperationIfActive(
                        .setWorkCommitmentsEnabled(true, configuration: .live),
                        session: &candidate, recorder: &recorder
                    ) == nil { try candidate.setWorkCommitmentsEnabled(true) }
                }
            case "refresh":
                try applyLiveWorkOperation(.refreshDemands, to: &candidate, recorder: &recorder)
            case "match":
                for demand in candidate.activeWorkDemands() where
                    !candidate.activeWorkCommitments().contains(where: {
                        $0.demandID == demand.demandID
                    }) {
                    let contexts = liveWorkCandidateContexts(
                        demand: demand, session: candidate, world: world
                    )
                    try applyLiveWorkOperation(
                        .start(demandID: demand.demandID, candidates: contexts),
                        to: &candidate, recorder: &recorder
                    )
                    let selected = candidate.activeWorkCommitments().first {
                        $0.demandID == demand.demandID
                    }
                    trace(
                        "work professions match demand=\(demand.demandID.rawValue) "
                            + "domain=\(demand.domain.rawValue) candidates=\(contexts.count) "
                            + "selected=\(selected?.workerID.rawValue ?? "none") "
                            + "physicalEligibility=adapter"
                    )
                }
            case "record":
                let count = try recordAvailableLiveWorkEvidence(
                    session: &candidate, recorder: &recorder
                )
                guard count > 0 else {
                    return failure("WorkProfessions found no new verified physical outcome.")
                }
            case "crisis":
                guard let commitment = candidate.activeWorkCommitments().first(where: {
                    $0.domain == .foraging && $0.status == .active
                }) else {
                    return failure("WorkProfessions has no active foraging commitment to suspend.")
                }
                try applyLiveWorkOperation(
                    .suspend(commitmentID: commitment.commitmentID, reason: .crisis),
                    to: &candidate, recorder: &recorder
                )
                trace(
                    "work professions crisis commitment=\(commitment.commitmentID.rawValue) "
                        + "worker=\(commitment.workerID.rawValue) status=suspended professionLock=0"
                )
            case "resume":
                guard let commitment = candidate.activeWorkCommitments().first(where: {
                    $0.status == .suspended && $0.suspensionReason == .crisis
                }) else {
                    return failure("WorkProfessions has no crisis-suspended commitment.")
                }
                try applyLiveWorkOperation(
                    .resume(commitmentID: commitment.commitmentID),
                    to: &candidate, recorder: &recorder
                )
                trace(
                    "work professions resume commitment=\(commitment.commitmentID.rawValue) "
                        + "worker=\(commitment.workerID.rawValue) status=active"
                )
            case "status":
                break
            case "final":
                try verifyLiveWorkProfessionProof(candidate, world: world)
            default:
                return failure(usage)
            }
            session = candidate
            replayRecorder = recorder
            traceWorkProfessionState(candidate, reason: command)
            return workProfessionStatus(candidate)
        } catch {
            return failure("WorkProfessions command failed: \(error)")
        }
    }

    private func workProfessionGateDependencies() -> [(String, Bool)] {
        [
            ("PEBBLELAB_APP_AGENTS=1", featureEnabled),
            ("PEBBLELAB_APP_AGENTS_POPULATION=1", populationFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_LIFECYCLE=1", lifecycleFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_SKILLS=1", skillFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_WORK_PROFESSIONS=1", workProfessionsFeatureEnabled),
            ("PEBBLELAB_APP_PROBES=1", probesFeatureEnabled),
            ("PEBBLELAB_DEBUG_ENTITIES=1", debugEntitiesEnabled),
        ]
    }

    func applyLiveWorkOperation(
        _ operation: AgentWorkCommitmentOperation,
        to candidate: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws {
        if try applyRecordedOperationIfActive(
            .applyWorkCommitmentOperation(operation),
            session: &candidate, recorder: &recorder
        ) == nil { _ = try candidate.applyWorkCommitmentOperation(operation) }
    }

    func liveWorkCandidateContexts(
        demand: AgentWorkDemandSignal,
        session: AgentSimulationSession,
        world: World
    ) -> [AgentWorkCandidateContext] {
        probesByAgentId.keys.sorted().compactMap { raw in
            guard let id = AgentID(rawValue: raw), let probe = probesByAgentId[raw] else {
                return nil
            }
            let position = AgentPosition(
                x: Int(floor(probe.x)), y: Int(floor(probe.y)), z: Int(floor(probe.z))
            )
            let distance = demand.targetPosition.map {
                abs($0.x - position.x) + abs($0.y - position.y) + abs($0.z - position.z)
            } ?? 0
            let toolKeys = probe.carriedItems.compactMap { stack -> String? in
                guard let stack else { return nil }
                return itemDef(stack.id).name
            }
            let toolsAvailable = demand.requiredToolKeys.allSatisfy { required in
                switch required {
                case "hunting_weapon":
                    return toolKeys.contains { $0.hasSuffix("_sword") }
                default:
                    return toolKeys.contains(required)
                }
            }
            let resourceKeys = Set(toolKeys)
            return AgentWorkCandidateContext(
                agentID: id, capable: true,
                physicallyAvailable: probe.world === world && !probe.dead,
                toolsAvailable: toolsAvailable,
                resourcesAvailable: demand.requiredResourceKeys.allSatisfy {
                    resourceKeys.contains($0)
                },
                distance: distance, externalWorkload: 0,
                obligationPenalty: session.careTarget(for: id) == nil ? 0 : 100
            )
        }
    }

    func recordAvailableLiveWorkEvidence(
        session candidate: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws -> Int {
        let events = candidate.causalLedgerSnapshot().events
        var processed = Set(candidate.workCommitmentSnapshot().evidence.map(\.sourceEventID))
        var recorded = 0
        for commitment in candidate.activeWorkCommitments().sorted(by: {
            $0.commitmentID < $1.commitmentID
        }) {
            guard let source = events.first(where: {
                $0.eventID.sequence > commitment.startedEventID.sequence
                    && !processed.contains($0.eventID)
                    && AgentMaterialSuccessEvidence.matches(
                        $0, agentID: commitment.workerID, domain: commitment.domain
                    )
            }) else { continue }
            let observers = Array(Set([
                commitment.observerID, commitment.workerID,
            ])).sorted()
            try applyLiveWorkOperation(
                .recordOutcome(AgentValidatedWorkOutcome(
                    commitmentID: commitment.commitmentID,
                    workerID: commitment.workerID, domain: commitment.domain,
                    sourceSuccessEventID: source.eventID, status: .succeeded,
                    observerIDs: observers
                )),
                to: &candidate, recorder: &recorder
            )
            processed.insert(source.eventID)
            recorded += 1
            trace(
                "work professions outcome commitment=\(commitment.commitmentID.rawValue) "
                    + "worker=\(commitment.workerID.rawValue) domain=\(commitment.domain.rawValue) "
                    + "source=\(source.eventID.rawValue) verified=1 physicalMultiplier=0 "
                    + "abstractCredit=0"
            )
        }
        return recorded
    }

    private func verifyLiveWorkProfessionProof(
        _ session: AgentSimulationSession,
        world: World
    ) throws {
        guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1",
              let fixture = wildSubsistenceProofFixture,
              fixture.fishingComplete, fixture.huntingComplete, fixture.gatheringComplete else {
            throw ControllerError.wildSubsistenceBoundary(
                "work profession proof requires completed disposable wild work"
            )
        }
        let profiles = session.professionProfiles()
        let expected: [String: AgentSkillDomain] = [
            "agent_0": .fishing, "agent_1": .hunting, "agent_2": .foraging,
        ]
        guard session.workCommitmentSnapshot().totalEvidenceCount == 3,
              session.activeWorkCommitments().isEmpty,
              profiles.count == 3,
              profiles.allSatisfy({ expected[$0.agentID.rawValue] == $0.primaryWorkDomain }),
              session.workCommitmentSnapshot().commitments.allSatisfy({
                  $0.status == .fulfilled
              }) else {
            throw ControllerError.wildSubsistenceBoundary(
                "work commitments/profiles do not match verified physical history"
            )
        }
        let coarse = session.snapshot()
        let campDelta = coarse.campStock.totalCount - fixture.initialCampStock
        let resourceDelta = coarse.agents.reduce(0) {
            $0 + $1.resourceInventory.totalCount
        } - fixture.initialResourceInventory
        let checkpoint = try session.makeCheckpoint()
        guard campDelta == 0, resourceDelta == 0, !session.localEcologyEnabled,
              checkpoint.schemaVersion == 16 else {
            throw ControllerError.wildSubsistenceBoundary(
                "work profile proof detected ghost material or invalid schema"
            )
        }
        let profileText = profiles.map {
            "\($0.agentID.rawValue):\($0.primaryWorkDomain?.rawValue ?? "none")"
        }.joined(separator: ",")
        trace(
            "work professions proof authority=PebbleCore domains=fishing,hunting,foraging "
                + "commitments=3 outcomes=3 profiles=\(profileText) specialization=derived "
                + "physicalMultiplier=0 abstractMaterialCredit=0 campStockDelta=\(campDelta) "
                + "resourceInventoryDelta=\(resourceDelta) localEcologyDelta=0 schema=16 "
                + "GateR=acquired GateB=notAcquired digest="
                + session.workCommitmentSnapshot().digest
                + " runtimeErrors=\(runtimeErrorCount) world=\(world === activeWorld ? "active" : "stale")"
        )
    }

    private func workProfessionStatus(
        _ session: AgentSimulationSession
    ) -> PebbleAgentCommandResult {
        let snapshot = session.workCommitmentSnapshot()
        let profiles = snapshot.professionProfiles.map {
            "\($0.agentID.rawValue):\($0.primaryWorkDomain?.rawValue ?? "none")@"
                + "\($0.specializationStrengthBasisPoints)"
        }.joined(separator: ",")
        let coordination = snapshot.coordinationMetrics
        return success(
            "WorkProfessions gate=enabled active=\(snapshot.enabled ? 1 : 0) schema="
                + "\(snapshot.enabled ? 16 : session.durableState().schemaVersion) "
                + "demands=\(snapshot.demands.count) commitments=\(snapshot.commitments.count) "
                + "open=\(snapshot.commitments.filter(\.status.isOpen).count) "
                + "evidence=\(snapshot.totalEvidenceCount) profiles=\(profiles.isEmpty ? "none" : profiles) "
                + "covered=\(coordination.coveredDemandCount) "
                + "reassignments=\(snapshot.totalReassignmentCount) digest=\(snapshot.digest)."
        )
    }

    private func traceWorkProfessionState(
        _ session: AgentSimulationSession,
        reason: String
    ) {
        let snapshot = session.workCommitmentSnapshot()
        let profiles = snapshot.professionProfiles.map {
            "\($0.agentID.rawValue):\($0.primaryWorkDomain?.rawValue ?? "none")"
        }.joined(separator: ",")
        trace(
            "work professions state tick=\(session.tick) reason=\(reason) "
                + "enabled=\(snapshot.enabled ? 1 : 0) demands=\(snapshot.demands.count) "
                + "commitments=\(snapshot.commitments.count) "
                + "open=\(snapshot.commitments.filter(\.status.isOpen).count) "
                + "evidence=\(snapshot.totalEvidenceCount) profiles=\(profiles.isEmpty ? "none" : profiles) "
                + "worldMutation=none materialMutation=none digest=\(snapshot.digest)"
        )
    }
}
