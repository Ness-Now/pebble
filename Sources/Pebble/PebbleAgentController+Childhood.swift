import PebbleAgents

extension PebbleAgentController {
    func handleChildhood(
        _ arguments: [String]
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab childhood <on|status|delegate dependent caregiver"
            + "|reassign dependent guardian|proof guardian-separation>"
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
            ("PEBBLELAB_APP_AGENTS_CARE=1", dependentCareFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_CHILDHOOD=1", childhoodFeatureEnabled),
        ]
        let missing = dependencies.filter { !$0.1 }.map(\.0)
        guard missing.isEmpty else {
            trace("childhood gates refused missing=\(missing.joined(separator: ","))")
            return failure(
                "PebbleAgents childhood refused; missing gates: "
                    + missing.joined(separator: ", ")
            )
        }
        guard var candidate = session else {
            return failure("No active PebbleAgents session.")
        }
        guard candidate.dependentCareEnabled else {
            return failure("Childhood V2 refused; enable dependent care first.")
        }
        do {
            switch command {
            case "on" where arguments.count == 1:
                if !candidate.childhoodV2Enabled {
                    var recorder = replayRecorder
                    if try applyRecordedOperationIfActive(
                        .setChildhoodV2Enabled(true, configuration: .live),
                        session: &candidate, recorder: &recorder
                    ) == nil {
                        try candidate.setChildhoodV2Enabled(true)
                    }
                    session = candidate
                    replayRecorder = recorder
                }
            case "status" where arguments.count == 1:
                break
            case "delegate" where arguments.count == 3:
                guard let dependentID = AgentID(rawValue: arguments[1]),
                      let caregiverID = AgentID(rawValue: arguments[2]) else {
                    return failure(usage)
                }
                var recorder = replayRecorder
                if try applyRecordedOperationIfActive(
                    .delegateDependentCare(
                        dependentID: dependentID, caregiverID: caregiverID
                    ),
                    session: &candidate, recorder: &recorder
                ) == nil {
                    try candidate.delegateDependentCare(
                        dependentID: dependentID, to: caregiverID
                    )
                }
                session = candidate
                replayRecorder = recorder
            case "reassign" where arguments.count == 3:
                guard let dependentID = AgentID(rawValue: arguments[1]),
                      let guardianID = AgentID(rawValue: arguments[2]) else {
                    return failure(usage)
                }
                var recorder = replayRecorder
                if try applyRecordedOperationIfActive(
                    .reassignGuardian(
                        dependentID: dependentID, guardianID: guardianID
                    ),
                    session: &candidate, recorder: &recorder
                ) == nil {
                    try candidate.reassignGuardian(
                        dependentID: dependentID, to: guardianID
                    )
                }
                session = candidate
                replayRecorder = recorder
            case "proof" where arguments.count == 2
                    && arguments[1].lowercased() == "guardian-separation":
                guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1",
                      isPaused else {
                    return failure(
                        "Guardian-separation proof requires a paused disposable World."
                    )
                }
                let active = candidate.childhoodSnapshot().guardianships
                    .filter { $0.status == .active }
                    .sorted {
                        if $0.dependentID != $1.dependentID {
                            return $0.dependentID < $1.dependentID
                        }
                        return $0.guardianID < $1.guardianID
                    }
                guard let prior = active.first,
                      let priorChildPosition = try? candidate.state(
                          for: prior.dependentID
                      ).position else {
                    return failure(
                        "Guardian-separation proof has no active child."
                    )
                }
                let targetHousehold = candidate.householdSnapshot()
                    .currentMemberships.filter { membership in
                        membership.householdID != prior.householdID
                            && membership.agentID != prior.dependentID
                    }.sorted { lhs, rhs in
                        if lhs.householdID != rhs.householdID {
                            return lhs.householdID < rhs.householdID
                        }
                        return lhs.agentID < rhs.agentID
                    }.first?.householdID
                guard let targetHousehold else {
                    return failure(
                        "Guardian-separation proof has no target household."
                    )
                }
                let parentageBefore = candidate.kinshipSnapshot()
                    .parentageRecords.first {
                        $0.childID == prior.dependentID
                    }?.canonicalParentIDs ?? []
                let genotypeBefore = candidate.genotype(
                    for: prior.dependentID
                )?.genotypeID
                var recorder = replayRecorder
                if try applyRecordedOperationIfActive(
                    .moveHouseholdMembers(
                        memberIDs: [prior.guardianID],
                        householdID: targetHousehold
                    ),
                    session: &candidate, recorder: &recorder
                ) == nil {
                    try candidate.moveMembers(
                        memberIDs: [prior.guardianID],
                        to: targetHousehold
                    )
                }
                let replacement = try candidate.currentGuardian(
                    for: prior.dependentID
                )
                let ended = candidate.childhoodSnapshot().guardianships.first {
                    $0.dependentID == prior.dependentID
                        && $0.guardianID == prior.guardianID
                        && $0.startedEventID == prior.startedEventID
                }
                let parentageAfter = candidate.kinshipSnapshot()
                    .parentageRecords.first {
                        $0.childID == prior.dependentID
                    }?.canonicalParentIDs ?? []
                let childPositionAfter = try candidate.state(
                    for: prior.dependentID
                ).position
                guard ended?.endedReason == .householdSeparated,
                      replacement?.guardianID != prior.guardianID,
                      parentageAfter == parentageBefore,
                      candidate.genotype(for: prior.dependentID)?.genotypeID
                        == genotypeBefore,
                      childPositionAfter == priorChildPosition else {
                    return failure(
                        "Guardian-separation proof failed canonical boundary verification."
                    )
                }
                session = candidate
                replayRecorder = recorder
                let traceFields = [
                    "childhood guardian separation",
                    "dependent=\(prior.dependentID.rawValue)",
                    "formerGuardian=\(prior.guardianID.rawValue)",
                    "sourceHousehold=\(prior.householdID.rawValue)",
                    "targetHousehold=\(targetHousehold.rawValue)",
                    "endReason=\(ended!.endedReason!.rawValue)",
                    "replacement=\(replacement?.guardianID.rawValue ?? "none")",
                    "basis=\(replacement?.basis.rawValue ?? "none")",
                    "parents=\(parentageAfter.map(\.rawValue).joined(separator: ","))",
                    "genotype=\(genotypeBefore?.rawValue ?? "none")",
                    "childPositionUnchanged=1",
                    "childTeleport=0",
                    "selection=deterministic",
                    "worldMutation=none",
                ]
                trace(traceFields.joined(separator: " "))
            default:
                return failure(usage)
            }
            traceChildhoodState(candidate)
            return childhoodStatus(candidate)
        } catch {
            return failure("PebbleAgents childhood command failed: \(error)")
        }
    }

    func traceChildhoodState(_ candidate: AgentSimulationSession) {
        let childhood = candidate.childhoodSnapshot()
        let care = candidate.dependentCareSnapshot()
        let guardians = childhood.guardianships.filter {
            $0.status == .active
        }.sorted {
            $0.dependentID < $1.dependentID
        }.map {
            "\($0.dependentID.rawValue)->\($0.guardianID.rawValue)"
                + ":\($0.basis.rawValue)@\($0.householdID.rawValue)"
        }.joined(separator: ",")
        let caregivers = care.assignments.filter {
            $0.status == .active
        }.sorted {
            $0.dependentID < $1.dependentID
        }.map {
            "\($0.dependentID.rawValue)->\($0.caregiverID.rawValue)"
        }.joined(separator: ",")
        let social = childhood.socialProfiles.sorted {
            $0.agentID < $1.agentID
        }.map { profile in
            let values = profile.values.sorted {
                $0.dimension < $1.dimension
            }.map {
                "\($0.dimension.rawValue):\($0.basisPoints)"
            }.joined(separator: "+")
            return "\(profile.agentID.rawValue)[\(values)]"
        }.joined(separator: ",")
        trace(
            "childhood status enabled=\(childhood.enabled ? 1 : 0) "
                + "schema=\(childhood.enabled ? 24 : 22) tick=\(candidate.tick) "
                + "guardians=\(guardians.isEmpty ? "none" : guardians) "
                + "caregivers=\(caregivers.isEmpty ? "none" : caregivers) "
                + "atRisk=\(childhood.atRiskDependentIDs.map(\.rawValue).joined(separator: ",")) "
                + "social=\(social.isEmpty ? "none" : social) "
                + "exposures=\(childhood.totalExposureCount) "
                + "digest=\(childhood.digest) mutation=none worldMutation=none"
        )
    }

    private func childhoodStatus(
        _ candidate: AgentSimulationSession
    ) -> PebbleAgentCommandResult {
        let childhood = candidate.childhoodSnapshot()
        return success(
            "Childhood gate=enabled active=\(childhood.enabled ? 1 : 0) "
                + "schema=\(childhood.enabled ? 24 : 22) "
                + "guardians=\(childhood.guardianships.filter { $0.status == .active }.count) "
                + "atRisk=\(childhood.atRiskDependentIDs.map(\.rawValue).joined(separator: ",")) "
                + "profiles=\(childhood.socialProfiles.count) "
                + "exposures=\(childhood.totalExposureCount) "
                + "digest=\(childhood.digest) mutation=none worldMutation=none."
        )
    }
}
