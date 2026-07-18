import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func resolvePendingBirthIfDue(
        world: World,
        player: Player,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws {
        guard lifecycleFeatureEnabled,
              let plan = session.pendingBirthSitePlan(),
              let settlement = session.populationSnapshot().settlement else { return }
        let playerPosition = AgentPosition(
            x: Int(player.x.rounded(.down)),
            y: Int(player.y.rounded(.down)),
            z: Int(player.z.rounded(.down))
        )
        let occupied = Set(session.snapshot().agents.map(\.position) + [playerPosition])
        let scan = birthSiteAdapter.observe(
            world: world,
            plan: plan,
            simulationTick: session.tick,
            settlement: settlement,
            occupiedPositions: occupied,
            configuration: .live
        )
        var candidate = session
        var candidateRecorder = recorder
        let record: AgentBirthRecord?
        if try applyRecordedOperationIfActive(
            .applyBirthSiteObservation(scan.observation),
            session: &candidate,
            recorder: &candidateRecorder
        ) != nil {
            record = candidate.lifecycleSnapshot().births.last {
                $0.planID == plan.planID && $0.birthTick == candidate.tick
            }
        } else {
            record = try candidate.applyBirthSiteObservation(scan.observation)
        }
        trace(
            "birth site tick=\(candidate.tick) plan=\(plan.planID.rawValue) "
                + "position=\(positionText(scan.observation.position)) "
                + "candidate=\(scan.observation.candidateIndex) "
                + "valid=\(scan.observation.isValid ? 1 : 0) "
                + "validCandidates=\(scan.validCandidateCount) "
                + "reads=\(scan.observation.worldReads) fingerprint=\(scan.observation.worldFingerprint) "
                + "mutation=none"
        )
        guard let record else {
            session = candidate
            recorder = candidateRecorder
            return
        }
        guard let newborn = candidate.snapshot().agents.first(where: {
            $0.id == record.newbornID.rawValue
        }) else {
            throw ControllerError.lifecycleBoundary("newborn candidate missing")
        }
        let probe = try createProbe(for: newborn, in: world)
        do {
            if kinshipLateFailureProofEnabled, !kinshipLateFailureProofInjected {
                _ = try candidate.durableStateBytes()
                let candidateRecorderBytes = try candidateRecorder.map {
                    try AgentReplayCodec.encodeRecords($0.records)
                }
                guard world.entities.contains(where: {
                    ($0 as? LabCoreAgentEntity)?.labAgentId == newborn.id
                }) else {
                    throw ControllerError.lifecycleBoundary("newborn proof probe missing")
                }
                kinshipLateFailureProofInjected = true
                trace(
                    "kinship late-failure candidate valid=1 tick=\(candidate.tick) "
                        + "newborn=\(newborn.id) nextOrdinal=\(candidate.populationSummary().nextPopulationOrdinal ?? -1) "
                        + "populationMembers=\(candidate.populationSnapshot().members.count) "
                        + "lifecycleMembers=\(candidate.lifecycleSnapshot().members.count) "
                        + "kinshipPeople=\(candidate.kinshipSnapshot().historicalPersons.count) "
                        + "parentages=\(candidate.kinshipSnapshot().parentageRecords.count) "
                        + "households=\(candidate.householdSnapshot().households.count) "
                        + "memberships=\(candidate.householdSnapshot().currentMemberships.count) "
                        + "causalSequence=\(candidate.causalLedgerSnapshot().summary.latestSequence) "
                        + "causalEvents=\(candidate.causalLedgerSnapshot().events.count) "
                        + "recorderRecords=\(candidateRecorder?.records.count ?? 0) "
                        + "recorderBytes=\(candidateRecorderBytes?.count ?? 0) probeCreated=1"
                )
                throw ControllerError.kinshipLateFailureProof
            }
            let expected = candidate.expectedActiveAgentIDs().map(\.rawValue).sorted()
            let worldIDs = world.entities.compactMap {
                ($0 as? LabCoreAgentEntity)?.labAgentId
            }.sorted()
            guard worldIDs == expected else {
                throw ControllerError.lifecycleBoundary(
                    "birth probe reconciliation expected=\(expected) actual=\(worldIDs)"
                )
            }
            probesByAgentId[newborn.id] = probe
            session = candidate
            recorder = candidateRecorder
        } catch {
            world.removeEntity(probe)
            isPaused = true
            throw error
        }
        let member = candidate.lifecycleSnapshot().members.first {
            $0.agentID == record.newbornID
        }
        let parentage = candidate.kinshipSnapshot().parentageRecords.first {
            $0.childID == record.newbornID
        }
        let kinshipTrace = candidate.kinshipEnabled
            ? "kinship=1 "
                + "kinshipParents=\(parentage?.canonicalParentIDs.map(\.rawValue).joined(separator: ",") ?? "none") "
                + "kinshipDigest=\(candidate.kinshipSnapshot().digest) "
            : ""
        let currentHousehold = (try? candidate.currentMembership(of: record.newbornID)) ?? nil
        let householdTrace = candidate.householdsEnabled
            ? "household=1 "
                + "householdID=\(currentHousehold?.householdID.rawValue ?? "none") "
                + "householdDigest=\(candidate.householdSnapshot().digest) "
            : ""
        let careAssignment = (try? candidate.currentCareAssignment(for: record.newbornID)) ?? nil
        let careTrace = candidate.dependentCareEnabled
            ? "care=1 "
                + "caregiver=\(careAssignment?.caregiverID.rawValue ?? "none") "
                + "careDigest=\(candidate.dependentCareSnapshot().digest) "
            : ""
        trace(
            "birth finalized tick=\(record.birthTick) birth=\(record.birthID.rawValue) "
                + "plan=\(record.planID.rawValue) newborn=\(record.newbornID.rawValue) "
                + "ordinal=\(record.ordinal.rawValue) parents=\(record.progenitorIDs.map(\.rawValue).joined(separator: ",")) "
                + "position=\(positionText(record.position)) stage=\(member?.currentStage.rawValue ?? "none") "
                + "age=\(member.flatMap { try? $0.age(at: candidate.tick) } ?? -1) "
                + kinshipTrace
                + householdTrace
                + careTrace
                + "population=\(candidate.populationSummary().memberCount) "
                + "nextOrdinal=\(candidate.populationSummary().nextPopulationOrdinal ?? -1) "
                + "probes=\(probesByAgentId.keys.sorted().joined(separator: ",")) "
                + "worldMutation=none"
        )
    }

    func kinshipLateFailureBoundarySnapshot(
        session: AgentSimulationSession,
        recorder: AgentReplayRecorder?,
        world: World
    ) throws -> PebbleKinshipLateFailureBoundarySnapshot {
        PebbleKinshipLateFailureBoundarySnapshot(
            durableSessionBytes: try session.durableStateBytes(),
            tick: session.tick,
            population: session.populationSnapshot(),
            lifecycle: session.lifecycleSnapshot(),
            kinship: session.kinshipSnapshot(),
            household: session.householdSnapshot(),
            causal: session.causalLedgerSnapshot(),
            recorderBytes: try recorder.map { try AgentReplayCodec.encodeRecords($0.records) },
            recorderRecordCount: recorder?.records.count ?? 0,
            probeIDs: probesByAgentId.keys.sorted(),
            worldEntityIDs: world.entities.compactMap {
                ($0 as? LabCoreAgentEntity)?.labAgentId
            }.sorted()
        )
    }

    func verifyKinshipLateFailureRollback(
        _ before: PebbleKinshipLateFailureBoundarySnapshot,
        world: World
    ) throws {
        guard let session else {
            throw ControllerError.kinshipBoundary("late-failure rollback lost session")
        }
        let after = try kinshipLateFailureBoundarySnapshot(
            session: session,
            recorder: replayRecorder,
            world: world
        )
        let newbornAbsent = !after.population.members.contains { $0.agentID.rawValue == "agent_4" }
            && !after.lifecycle.members.contains { $0.agentID.rawValue == "agent_4" }
            && !after.kinship.historicalPersons.contains { $0.agentID.rawValue == "agent_4" }
            && !after.household.membershipPeriods.contains { $0.agentID.rawValue == "agent_4" }
            && !after.probeIDs.contains("agent_4")
            && !after.worldEntityIDs.contains("agent_4")
        guard after.durableSessionBytes == before.durableSessionBytes,
              after.tick == before.tick,
              after.population == before.population,
              after.lifecycle == before.lifecycle,
              after.kinship == before.kinship,
              after.household == before.household,
              after.causal == before.causal,
              after.recorderBytes == before.recorderBytes,
              after.recorderRecordCount == before.recorderRecordCount,
              after.probeIDs == before.probeIDs,
              after.worldEntityIDs == before.worldEntityIDs,
              newbornAbsent else {
            throw ControllerError.kinshipBoundary("late-failure rollback diverged")
        }
        trace(
            "kinship late-failure rollback sessionBytes=exact tick=\(after.tick) "
                + "nextOrdinal=\(after.population.nextPopulationOrdinal ?? -1) "
                + "populationMembers=\(after.population.members.count) "
                + "lifecycleMembers=\(after.lifecycle.members.count) "
                + "kinshipPeople=\(after.kinship.historicalPersons.count) "
                + "parentages=\(after.kinship.parentageRecords.count) "
                + "households=\(after.household.households.count) "
                + "memberships=\(after.household.currentMemberships.count) "
                + "causalSequence=\(after.causal.summary.latestSequence) "
                + "causalEvents=\(after.causal.events.count) recorderBytes=exact "
                + "recorderRecords=\(after.recorderRecordCount) probeMap=exact "
                + "worldEntityIndexes=exact newbornAbsent=1"
        )
    }

    func handleLifecycleAge(_ arguments: [String]) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab lifecycle <on|status|clear>"
        guard let command = arguments.first?.lowercased(), arguments.count == 1 else {
            return failure(usage)
        }
        guard lifecycleFeatureEnabled else {
            return failure(
                "PebbleAgents lifecycle disabled. Set PEBBLELAB_APP_AGENTS_LIFECYCLE=1 before launch."
            )
        }
        guard var candidate = session else { return failure("No active PebbleAgents session.") }
        do {
            switch command {
            case "on":
                if !candidate.lifecycleEnabled {
                    var recorder = replayRecorder
                    if try applyRecordedOperationIfActive(
                        .setLifecycleEnabled(true, configuration: .live),
                        session: &candidate,
                        recorder: &recorder
                    ) == nil {
                        try candidate.setLifecycleEnabled(true)
                    }
                    session = candidate
                    replayRecorder = recorder
                    traceLifecycleState(at: candidate.tick)
                }
                return lifecycleAgeStatus(candidate)
            case "status":
                return lifecycleAgeStatus(candidate)
            case "clear":
                var recorder = replayRecorder
                if try applyRecordedOperationIfActive(
                    .clearLifecycleDiagnostics,
                    session: &candidate,
                    recorder: &recorder
                ) == nil {
                    try candidate.clearLifecycleDiagnostics()
                }
                session = candidate
                replayRecorder = recorder
                return success("Lifecycle diagnostics cleared; ages, lineage and births retained.")
            default:
                return failure(usage)
            }
        } catch {
            return failure("PebbleAgents lifecycle command failed: \(error)")
        }
    }

    func handleReproduction(_ arguments: [String]) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab reproduction <on|off|status>"
        guard let command = arguments.first?.lowercased(), arguments.count == 1 else {
            return failure(usage)
        }
        guard lifecycleFeatureEnabled else {
            return failure(
                "PebbleAgents lifecycle disabled. Set PEBBLELAB_APP_AGENTS_LIFECYCLE=1 before launch."
            )
        }
        guard var candidate = session else { return failure("No active PebbleAgents session.") }
        do {
            switch command {
            case "on", "off":
                let enabled = command == "on"
                var recorder = replayRecorder
                if try applyRecordedOperationIfActive(
                    .setReproductionEnabled(enabled),
                    session: &candidate,
                    recorder: &recorder
                ) == nil {
                    try candidate.setReproductionEnabled(enabled)
                }
                session = candidate
                replayRecorder = recorder
                return reproductionStatus(candidate)
            case "status":
                return reproductionStatus(candidate)
            default:
                return failure(usage)
            }
        } catch {
            return failure("PebbleAgents reproduction command failed: \(error)")
        }
    }

    func handleBirths(_ arguments: [String]) -> PebbleAgentCommandResult {
        guard arguments == ["status"], let session else {
            return failure("Usage: /lab births status")
        }
        let summary = session.lifecycleSummary()
        let latest = session.lifecycleSnapshot().births.last
        let member = latest.flatMap { birth in
            session.lifecycleSnapshot().members.first { $0.agentID == birth.newbornID }
        }
        return success(
            "Births retained=\(summary.retainedBirthCount) total=\(summary.totalBirthCount) "
                + "latest=\(latest?.birthID.rawValue ?? "none") "
                + "newborn=\(latest?.newbornID.rawValue ?? "none") "
                + "parents=\(latest?.progenitorIDs.map(\.rawValue).joined(separator: ",") ?? "none") "
                + "tick=\(latest?.birthTick ?? -1) "
                + "position=\(latest.map { positionText($0.position) } ?? "none") "
                + "stage=\(member?.currentStage.rawValue ?? "none") "
                + "nextOrdinal=\(session.populationSummary().nextPopulationOrdinal ?? -1)."
        )
    }

    func traceLifecycleState(at tick: Int) {
        guard let session, session.lifecycleEnabled else { return }
        let summary = session.lifecycleSummary()
        let reproduction = session.reproductionSnapshot()
        let plan = session.lifecycleSnapshot().plans.last { $0.status == .planned }
        let ages = session.lifecycleSnapshot().members.map {
            "\($0.agentID.rawValue):\((try? $0.age(at: session.tick)) ?? -1)/\($0.currentStage.rawValue)"
        }.joined(separator: ",")
        trace(
            "lifecycle tick=\(tick) enabled=1 reproduction=\(summary.reproductionEnabled ? 1 : 0) "
                + "newborn=\(summary.newbornCount) juvenile=\(summary.juvenileCount) "
                + "mature=\(summary.matureCount) plans=\(summary.activePlanCount) "
                + "plan=\(plan?.planID.rawValue ?? "none") due=\(plan?.dueTick ?? -1) "
                + "births=\(summary.totalBirthCount) newbornID=\(summary.latestNewbornID?.rawValue ?? "none") "
                + "ages=\(ages) nextOrdinal=\(session.populationSummary().nextPopulationOrdinal ?? -1) "
                + "probes=\(probesByAgentId.keys.sorted().joined(separator: ",")) "
                + "digest=\(summary.digest)"
        )
        trace(
            "reproduction tick=\(tick) enabled=\(reproduction.enabled ? 1 : 0) "
                + "eligible=\(reproduction.eligibleMatureResidentIDs.map(\.rawValue).joined(separator: ",")) "
                + "pairs=\(reproduction.eligiblePairs.map { $0.map(\.rawValue).joined(separator: "+") }.joined(separator: ",")) "
                + "plan=\(plan?.planID.rawValue ?? "none") parents=\(plan?.progenitorIDs.map(\.rawValue).joined(separator: ",") ?? "none") "
                + "created=\(plan?.createdTick ?? -1) due=\(plan?.dueTick ?? -1) "
                + "population=\(reproduction.populationCount)/\(reproduction.populationCapacity) "
                + "pressure=\(reproduction.pressure?.rawValue ?? "none") food=\(reproduction.accessibleFood) "
                + "lastCancellation=\(reproduction.lastCancellationReason?.rawValue ?? "none") "
                + "digest=\(reproduction.digest)"
        )
    }

    private func lifecycleAgeStatus(
        _ session: AgentSimulationSession
    ) -> PebbleAgentCommandResult {
        let summary = session.lifecycleSummary()
        let ages = session.lifecycleSnapshot().members.map { member in
            "\(member.agentID.rawValue):\((try? member.age(at: session.tick)) ?? -1)/\(member.currentStage.rawValue)"
        }.joined(separator: ",")
        return success(
            "Lifecycle gate=\(lifecycleFeatureEnabled ? "enabled" : "disabled") "
                + "active=\(summary.enabled ? 1 : 0) tick=\(session.tick) "
                + "newborn=\(summary.newbornCount) juvenile=\(summary.juvenileCount) "
                + "mature=\(summary.matureCount) births=\(summary.totalBirthCount) "
                + "members=\(ages)."
        )
    }

    private func reproductionStatus(
        _ session: AgentSimulationSession
    ) -> PebbleAgentCommandResult {
        let summary = session.lifecycleSummary()
        let plan = session.lifecycleSnapshot().plans.last { $0.status == .planned }
        let reproduction = session.reproductionSnapshot()
        return success(
            "Reproduction \(summary.reproductionEnabled ? "on" : "off"): "
                + "eligible=\(reproduction.eligibleMatureResidentIDs.count) "
                + "pairs=\(reproduction.eligiblePairs.count) "
                + "activePlans=\(summary.activePlanCount) plan=\(plan?.planID.rawValue ?? "none") "
                + "parents=\(plan?.progenitorIDs.map(\.rawValue).joined(separator: ",") ?? "none") "
                + "created=\(plan?.createdTick ?? -1) due=\(plan?.dueTick ?? -1) "
                + "population=\(reproduction.populationCount)/\(reproduction.populationCapacity) "
                + "pressure=\(reproduction.pressure?.rawValue ?? "none") "
                + "food=\(reproduction.accessibleFood) "
                + "lastCancellation=\(reproduction.lastCancellationReason?.rawValue ?? "none") "
                + "births=\(summary.totalBirthCount) digest=\(reproduction.digest)."
        )
    }
}
