import Foundation
import PebbleAgents

struct GateFE12A6Trajectory {
    var session: AgentSimulationSession
    let order: String
    let decedentID: AgentID
    let laterSiblingID: AgentID
    let successorProof: AgentEstateSuccessorPlanProof
    let causal: [String: UInt64]
}

private struct GateFE12A6IdentityEvidence: Codable, Equatable {
    let populationIDs: [String]
    let fidelityIDs: [String]
    let nextPopulationOrdinal: Int
    let nextFidelityOrdinal: UInt64
    let migrationIDs: [String]
    let nextMigrationOrdinal: UInt64
    let householdIDs: [String]
    let nextHouseholdOrdinal: Int
    let householdMembershipPeriods: Int
    let activeGuardianships: Int
    let activeCareAssignments: Int
    let deaths: Int
    let estates: Int
}

private struct GateFE12A6AuthorityEvidence: Codable, Equatable {
    let activeAgentIDs: [String]
    let residentCount: Int
    let inTransitCount: Int
    let activeMigrationCount: Int
    let currentHouseholdCount: Int
    let decedentPopulationAuthority: Int
    let decedentFidelityAuthority: Int
    let decedentSettlementAuthority: Int
    let decedentHouseholdAuthority: Int
    let laterSiblingHouseholdID: String
    let currentGuardianID: String
}

private struct GateFE12A6Report: Codable, Equatable {
    let order: String
    let tick: Int
    let checkpointSchema: Int
    let observerSchema: Int
    let checkpointSHA256: String
    let durableSHA256: String
    let successorProofSHA256: String
    let successorProofVersion: Int
    let successorRows: [String]
    let laterSiblingInHistoricalProof: Bool
    let currentSiblingRelation: String
    let causal: [String: UInt64]
    let identity: GateFE12A6IdentityEvidence
    let authority: GateFE12A6AuthorityEvidence
    let replayedBirths: Int
    let replayedDeaths: Int
    let replayedEstates: Int
    let observerMutationCount: Int
    let assertions: [String: Bool]
}

private struct GateFE12A6FreshReaderReport: Codable, Equatable {
    let checkpointSchema: Int
    let observerSchema: Int
    let controlCheckpointSHA256: String
    let controlDurableSHA256: String
    let attackCheckpointSHA256: String
    let attackDurableSHA256: String
    let assertions: [String: Bool]
}

private func gateFE12A6ProofDigest(
    _ proof: AgentEstateSuccessorPlanProof
) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return AgentCheckpointDigest.sha256(try! encoder.encode(proof)).rawValue
}

private func gateFE12A6SiblingText(
    _ relation: AgentSiblingRelation
) -> String {
    switch relation {
    case .samePerson: return "samePerson"
    case .unrelated: return "unrelated"
    case .halfSibling: return "halfSibling"
    case .fullSibling: return "fullSibling"
    case let .unknownParentage(id):
        return "unknownParentage:\(id.rawValue)"
    case let .unknownPerson(id):
        return "unknownPerson:\(id.rawValue)"
    }
}

private func gateFE12A6Identity(
    _ session: AgentSimulationSession
) -> GateFE12A6IdentityEvidence {
    let durable = session.durableState()
    let population = durable.populationRegistry!
    let scale = population.scaleState!
    let household = durable.householdState!
    let care = durable.dependentCareState!
    let family = care.childhoodV2!
    return GateFE12A6IdentityEvidence(
        populationIDs: population.members.map { $0.agentID.rawValue }.sorted(),
        fidelityIDs: scale.fidelityRecords.map { $0.agentID.rawValue }.sorted(),
        nextPopulationOrdinal: population.nextPopulationOrdinal.rawValue,
        nextFidelityOrdinal: scale.nextFidelityTransitionOrdinal,
        migrationIDs: scale.settlementMigrations.map {
            $0.migrationID.rawValue
        }.sorted(),
        nextMigrationOrdinal: scale.nextSettlementMigrationOrdinal,
        householdIDs: household.households.map {
            $0.householdID.rawValue
        }.sorted(),
        nextHouseholdOrdinal: household.nextHouseholdOrdinal.rawValue,
        householdMembershipPeriods: household.membershipPeriods.count,
        activeGuardianships: family.guardianships.filter {
            $0.status == .active
        }.count,
        activeCareAssignments: care.assignments.filter {
            $0.status == .active
        }.count,
        deaths: durable.mortalityState!.totalDeathCount,
        estates: durable.estateState!.totalEstateCount
    )
}

private func gateFE12A6Authority(
    _ session: AgentSimulationSession,
    decedentID: AgentID,
    laterSiblingID: AgentID
) -> GateFE12A6AuthorityEvidence {
    let durable = session.durableState()
    let population = durable.populationRegistry!
    let scale = population.scaleState!
    let household = durable.householdState!
    let active = session.expectedActiveAgentIDs().sorted()
    let currentMemberships = household.membershipPeriods.filter {
        $0.leftTick == nil
    }
    let laterMembership = currentMemberships.first {
        $0.agentID == laterSiblingID
    }!
    let guardian = try! session.currentGuardian(for: laterSiblingID)!
    return GateFE12A6AuthorityEvidence(
        activeAgentIDs: active.map(\.rawValue),
        residentCount: population.settlements.reduce(0) {
            $0 + $1.residentIDs.count
        },
        inTransitCount: population.settlements.reduce(0) {
            $0 + $1.inTransitIDs.count
        },
        activeMigrationCount: scale.settlementMigrations.filter {
            $0.status == .inTransit
        }.count,
        currentHouseholdCount: currentMemberships.count,
        decedentPopulationAuthority: population.members.filter {
            $0.agentID == decedentID
        }.count,
        decedentFidelityAuthority: scale.fidelityRecords.filter {
            $0.agentID == decedentID
        }.count,
        decedentSettlementAuthority: population.settlements.reduce(0) {
            $0 + ($1.residentIDs.contains(decedentID) ? 1 : 0)
                + ($1.inTransitIDs.contains(decedentID) ? 1 : 0)
        },
        decedentHouseholdAuthority: currentMemberships.filter {
            $0.agentID == decedentID
        }.count,
        laterSiblingHouseholdID: laterMembership.householdID.rawValue,
        currentGuardianID: guardian.guardianID.rawValue
    )
}

private func gateFE12A6Report(
    trajectory: inout GateFE12A6Trajectory,
    replayedBirths: Int = 0,
    replayedDeaths: Int = 0,
    replayedEstates: Int = 0
) -> GateFE12A6Report {
    let session = trajectory.session
    let checkpoint = try! session.makeCheckpoint()
    let checkpointBytes = try! AgentCheckpointCodec.encode(checkpoint)
    let durableBytes = try! session.durableStateBytes()
    let observerBefore = durableBytes
    let observer = session.observerSnapshot(
        worldBinding: try! AgentObserverWorldBinding(
            worldID: "gate-f-e12-a6-\(trajectory.order)-world",
            storageIdentity: "memory:gate-f-e12-a6-\(trajectory.order)",
            seed: 1_206, dimension: 0,
            observedWorldTick: session.tick
        )
    )
    let observerMutations = (try! session.durableStateBytes())
        == observerBefore ? 0 : 1
    let identity = gateFE12A6Identity(session)
    let authority = gateFE12A6Authority(
        session, decedentID: trajectory.decedentID,
        laterSiblingID: trajectory.laterSiblingID
    )
    let proof = trajectory.successorProof
    let proofRows = proof.eligibilityRows.map {
        "\($0.agentID.rawValue):\($0.basis.rawValue):"
            + "\($0.eligibleAtDeath ? 1 : 0)"
    }.sorted()
    let laterInProof = proof.eligibilityRows.contains {
        $0.agentID == trajectory.laterSiblingID
            && $0.basis == .halfSibling
    }
    let currentRelation = gateFE12A6SiblingText(session.siblingRelation(
        between: trajectory.decedentID,
        and: trajectory.laterSiblingID
    ))
    let events = session.causalLedgerSnapshot().events
    let allSensitiveSameTick = trajectory.causal.values.allSatisfy { sequence in
        events.contains {
            $0.sequence.rawValue == sequence
                && $0.simulationTick.rawValue == session.tick
        }
    }
    let c = trajectory.causal
    let strictOrder: Bool
    if trajectory.order == "birth-before-plan" {
        strictOrder = c["mortalityPending"]! < c["householdMove"]!
            && c["householdMove"]! < c["populationBorn"]!
            && c["populationBorn"]! < c["parentage"]!
            && c["parentage"]! < c["guardianReassigned"]!
            && c["guardianReassigned"]! < c["physicalCustody"]!
            && c["physicalCustody"]! < c["lethalDamage"]!
            && c["lethalDamage"]! < c["estatePlan"]!
            && c["estatePlan"]! < c["deathFinal"]!
            && c["deathFinal"]! < c["migrationStart"]!
    } else {
        strictOrder = c["mortalityPending"]! < c["physicalCustody"]!
            && c["physicalCustody"]! < c["lethalDamage"]!
            && c["lethalDamage"]! < c["estatePlan"]!
            && c["estatePlan"]! < c["deathFinal"]!
            && c["deathFinal"]! < c["householdMove"]!
            && c["householdMove"]! < c["populationBorn"]!
            && c["populationBorn"]! < c["parentage"]!
            && c["parentage"]! < c["guardianReassigned"]!
            && c["guardianReassigned"]! < c["migrationStart"]!
    }
    let durable = session.durableState()
    let population = durable.populationRegistry!
    let scale = population.scaleState!
    let household = durable.householdState!
    let currentPeriods = household.membershipPeriods.filter {
        $0.leftTick == nil
    }
    let singularLocations = session.expectedActiveAgentIDs().allSatisfy { id in
        population.settlements.reduce(0) {
            $0 + ($1.residentIDs.contains(id) ? 1 : 0)
                + ($1.inTransitIDs.contains(id) ? 1 : 0)
        } == 1
    }
    let singularHouseholds = session.expectedActiveAgentIDs().allSatisfy { id in
        currentPeriods.filter { $0.agentID == id }.count == 1
    }
    let singularPopulation = Set(identity.populationIDs).count
        == identity.populationIDs.count
        && identity.populationIDs == identity.fidelityIDs
        && identity.populationIDs == authority.activeAgentIDs
    let migration = scale.settlementMigrations.first!
    let laterMembership = currentPeriods.first {
        $0.agentID == trajectory.laterSiblingID
    }!
    let guardian = try! session.currentGuardian(
        for: trajectory.laterSiblingID
    )!
    let care = durable.dependentCareState!
    let assertions: [String: Bool] = [
        "checkpoint_schema_35": checkpoint.schemaVersion == 35,
        "observer_schema_13_read_only": observer.header.schemaVersion == 13
            && observerMutations == 0,
        "all_sensitive_events_same_tick": allSensitiveSameTick,
        "sequence_not_tick_controls_history": strictOrder
            && laterInProof == (trajectory.order == "birth-before-plan"),
        "estate_v2_proof_exact": proof.version == 2
            && gateFE12A6ProofDigest(proof)
                == gateFE12A6ProofDigest(trajectory.successorProof),
        "current_half_sibling_truth": currentRelation == "halfSibling",
        "current_authority_singular": singularPopulation
            && singularLocations && singularHouseholds,
        "dead_authority_absent": authority.decedentPopulationAuthority == 0
            && authority.decedentFidelityAuthority == 0
            && authority.decedentSettlementAuthority == 0
            && authority.decedentHouseholdAuthority == 0,
        "migration_authority_coherent": migration.agentID.rawValue == "agent_1"
            && migration.status == .inTransit
            && authority.activeMigrationCount == 1
            && authority.inTransitCount == 1,
        "household_guardian_care_coherent": guardian.householdID
                == laterMembership.householdID
            && care.assignments.filter {
                $0.dependentID == trajectory.laterSiblingID
                    && $0.status == .active
                    && $0.caregiverID == guardian.guardianID
            }.count == 1,
        "identity_ordinals_monotone": identity.nextPopulationOrdinal == 5
            && identity.nextFidelityOrdinal >= 5
            && identity.nextMigrationOrdinal == 2
            && identity.nextHouseholdOrdinal
                >= Set(identity.householdIDs).count,
        "identity_sets_unique": singularPopulation
            && Set(identity.migrationIDs).count == identity.migrationIDs.count
            && Set(identity.householdIDs).count == identity.householdIDs.count,
        "death_estate_exactly_once": identity.deaths == 1
            && identity.estates == 1,
        "zero_replay": replayedBirths == 0 && replayedDeaths == 0
            && replayedEstates == 0,
    ]
    return GateFE12A6Report(
        order: trajectory.order, tick: session.tick,
        checkpointSchema: checkpoint.schemaVersion,
        observerSchema: observer.header.schemaVersion,
        checkpointSHA256: AgentCheckpointDigest.sha256(
            checkpointBytes
        ).rawValue,
        durableSHA256: AgentCheckpointDigest.sha256(durableBytes).rawValue,
        successorProofSHA256: gateFE12A6ProofDigest(proof),
        successorProofVersion: proof.version,
        successorRows: proofRows,
        laterSiblingInHistoricalProof: laterInProof,
        currentSiblingRelation: currentRelation,
        causal: trajectory.causal, identity: identity, authority: authority,
        replayedBirths: replayedBirths, replayedDeaths: replayedDeaths,
        replayedEstates: replayedEstates,
        observerMutationCount: observerMutations,
        assertions: assertions
    )
}

private func gateFE12A6Write<T: Encodable>(_ value: T, to url: URL) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    try! encoder.encode(value).write(to: url, options: .atomic)
}

private func gateFE12A6RestoredTrajectory(
    checkpointURL: URL,
    previous: GateFE12A6Report
) -> GateFE12A6Trajectory {
    let checkpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self,
        from: Data(contentsOf: checkpointURL)
    )
    let session = try! AgentSimulationSession.restoring(checkpoint)
    let estate = session.estateSnapshot().estates.first {
        $0.decedentID.rawValue == "agent_3"
    }!
    return GateFE12A6Trajectory(
        session: session, order: previous.order,
        decedentID: estate.decedentID,
        laterSiblingID: AgentID(rawValue: "agent_4")!,
        successorProof: estate.successorPlanProof!, causal: previous.causal
    )
}

private func gateFE12A6FreshIfRequested() -> Bool {
    let environment = ProcessInfo.processInfo.environment
    guard let phase = environment["PEBBLELAB_GATE_F_E12_A6_PHASE"] else {
        return false
    }
    guard ["write", "restore-verify"].contains(phase),
          let output = environment["PEBBLELAB_GATE_F_E12_A6_OUT"] else {
        preconditionFailure("invalid Evaluation 12 Attack 06 environment")
    }
    let root = URL(fileURLWithPath: output, isDirectory: true)
    try! FileManager.default.createDirectory(
        at: root, withIntermediateDirectories: true
    )
    let controlCheckpointURL = root.appendingPathComponent(
        "control_checkpoint_v35.json"
    )
    let controlDurableURL = root.appendingPathComponent(
        "control_durable_state.json"
    )
    let controlReportURL = root.appendingPathComponent("control_report.json")
    let attackCheckpointURL = root.appendingPathComponent(
        "attack_checkpoint_v35.json"
    )
    let attackDurableURL = root.appendingPathComponent(
        "attack_durable_state.json"
    )
    let attackReportURL = root.appendingPathComponent("attack_report.json")
    if phase == "write" {
        var control = gateFE12A6BuildTrajectory(
            "gate-f-e12-a6-fresh-control", birthBeforeEstatePlan: true
        )
        var attack = gateFE12A6BuildTrajectory(
            "gate-f-e12-a6-fresh-attack", birthBeforeEstatePlan: false
        )
        let controlReport = gateFE12A6Report(trajectory: &control)
        let attackReport = gateFE12A6Report(trajectory: &attack)
        try! AgentCheckpointCodec.encode(control.session.makeCheckpoint())
            .write(to: controlCheckpointURL, options: .atomic)
        try! control.session.durableStateBytes()
            .write(to: controlDurableURL, options: .atomic)
        try! AgentCheckpointCodec.encode(attack.session.makeCheckpoint())
            .write(to: attackCheckpointURL, options: .atomic)
        try! attack.session.durableStateBytes()
            .write(to: attackDurableURL, options: .atomic)
        gateFE12A6Write(controlReport, to: controlReportURL)
        gateFE12A6Write(attackReport, to: attackReportURL)
        check("Attack 06 writer preserves both causal invocation orders",
              controlReport.assertions.values.allSatisfy { $0 }
                && attackReport.assertions.values.allSatisfy { $0 })
        return true
    }

    let priorControl = try! JSONDecoder().decode(
        GateFE12A6Report.self, from: Data(contentsOf: controlReportURL)
    )
    let priorAttack = try! JSONDecoder().decode(
        GateFE12A6Report.self, from: Data(contentsOf: attackReportURL)
    )
    var control = gateFE12A6RestoredTrajectory(
        checkpointURL: controlCheckpointURL, previous: priorControl
    )
    var attack = gateFE12A6RestoredTrajectory(
        checkpointURL: attackCheckpointURL, previous: priorAttack
    )
    let controlCheckpointBytes = try! Data(contentsOf: controlCheckpointURL)
    let controlDurableBytes = try! Data(contentsOf: controlDurableURL)
    let attackCheckpointBytes = try! Data(contentsOf: attackCheckpointURL)
    let attackDurableBytes = try! Data(contentsOf: attackDurableURL)
    let controlBirths = control.session.lifecycleSnapshot().totalBirthCount
    let controlDeaths = control.session.mortalitySnapshot().totalDeathCount
    let controlEstates = control.session.estateSnapshot().totalEstateCount
    let attackBirths = attack.session.lifecycleSnapshot().totalBirthCount
    let attackDeaths = attack.session.mortalitySnapshot().totalDeathCount
    let attackEstates = attack.session.estateSnapshot().totalEstateCount
    let controlReport = gateFE12A6Report(
        trajectory: &control,
        replayedBirths: control.session.lifecycleSnapshot().totalBirthCount
            - controlBirths,
        replayedDeaths: control.session.mortalitySnapshot().totalDeathCount
            - controlDeaths,
        replayedEstates: control.session.estateSnapshot().totalEstateCount
            - controlEstates
    )
    let attackReport = gateFE12A6Report(
        trajectory: &attack,
        replayedBirths: attack.session.lifecycleSnapshot().totalBirthCount
            - attackBirths,
        replayedDeaths: attack.session.mortalitySnapshot().totalDeathCount
            - attackDeaths,
        replayedEstates: attack.session.estateSnapshot().totalEstateCount
            - attackEstates
    )
    let controlCheckpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self, from: controlCheckpointBytes
    )
    let attackCheckpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self, from: attackCheckpointBytes
    )
    let assertions: [String: Bool] = [
        "control_checkpoint_reencodes_exactly":
            (try? AgentCheckpointCodec.encode(controlCheckpoint))
                == controlCheckpointBytes,
        "attack_checkpoint_reencodes_exactly":
            (try? AgentCheckpointCodec.encode(attackCheckpoint))
                == attackCheckpointBytes,
        "control_durable_restores_exactly":
            (try? control.session.durableStateBytes()) == controlDurableBytes,
        "attack_durable_restores_exactly":
            (try? attack.session.durableStateBytes()) == attackDurableBytes,
        "reports_restore_exactly": controlReport == priorControl
            && attackReport == priorAttack,
        "causal_distinction_survives_restore":
            controlReport.laterSiblingInHistoricalProof
                && !attackReport.laterSiblingInHistoricalProof
                && controlReport.currentSiblingRelation == "halfSibling"
                && attackReport.currentSiblingRelation == "halfSibling",
        "schema35_observer13": controlReport.checkpointSchema == 35
            && attackReport.checkpointSchema == 35
            && controlReport.observerSchema == 13
            && attackReport.observerSchema == 13,
        "zero_replay": controlReport.replayedBirths == 0
            && controlReport.replayedDeaths == 0
            && controlReport.replayedEstates == 0
            && attackReport.replayedBirths == 0
            && attackReport.replayedDeaths == 0
            && attackReport.replayedEstates == 0,
    ]
    let reader = GateFE12A6FreshReaderReport(
        checkpointSchema: 35, observerSchema: 13,
        controlCheckpointSHA256: AgentCheckpointDigest.sha256(
            controlCheckpointBytes
        ).rawValue,
        controlDurableSHA256: AgentCheckpointDigest.sha256(
            controlDurableBytes
        ).rawValue,
        attackCheckpointSHA256: AgentCheckpointDigest.sha256(
            attackCheckpointBytes
        ).rawValue,
        attackDurableSHA256: AgentCheckpointDigest.sha256(
            attackDurableBytes
        ).rawValue,
        assertions: assertions
    )
    gateFE12A6Write(
        reader, to: root.appendingPathComponent("reader_report.json")
    )
    check("Attack 06 fresh reader preserves sequence-owned history",
          assertions.values.allSatisfy { $0 })
    return true
}

func runPebbleAgentsGateFEvaluation12Attack06Smoke() {
    if gateFE12A6FreshIfRequested() { return }
    var control = gateFE12A6BuildTrajectory(
        "gate-f-e12-a6-focused-control", birthBeforeEstatePlan: true
    )
    var attack = gateFE12A6BuildTrajectory(
        "gate-f-e12-a6-focused-attack", birthBeforeEstatePlan: false
    )
    let controlReport = gateFE12A6Report(trajectory: &control)
    let attackReport = gateFE12A6Report(trajectory: &attack)
    section("Gate F Evaluation 12 Attack 06 — same-tick causal interleaving")
    for key in controlReport.assertions.keys.sorted() {
        check("Attack 06 control \(key)", controlReport.assertions[key]!)
    }
    for key in attackReport.assertions.keys.sorted() {
        check("Attack 06 attack \(key)", attackReport.assertions[key]!)
    }
    check("Attack 06 current sibling truth matches across invocation orders",
          controlReport.currentSiblingRelation == "halfSibling"
            && attackReport.currentSiblingRelation == "halfSibling")
    check("Attack 06 historical sibling truth follows event sequence",
          controlReport.laterSiblingInHistoricalProof
            && !attackReport.laterSiblingInHistoricalProof)
    check("Attack 06 same tick is not treated as simultaneous",
          controlReport.tick == attackReport.tick
            && controlReport.tick == 4
            && controlReport.causal["parentage"]!
                < controlReport.causal["estatePlan"]!
            && attackReport.causal["estatePlan"]!
                < attackReport.causal["parentage"]!)
    print(
        "GATE_F_E12_ATTACK_06_CONTROL tick=\(controlReport.tick) "
            + controlReport.causal.keys.sorted().map {
                "\($0)=\(controlReport.causal[$0]!)"
            }.joined(separator: " ")
    )
    print(
        "GATE_F_E12_ATTACK_06_ATTACK tick=\(attackReport.tick) "
            + attackReport.causal.keys.sorted().map {
                "\($0)=\(attackReport.causal[$0]!)"
            }.joined(separator: " ")
    )
    print(
        "GATE_F_E12_ATTACK_06_HISTORY controlLater="
            + "\(controlReport.laterSiblingInHistoricalProof ? 1 : 0) "
            + "attackLater=\(attackReport.laterSiblingInHistoricalProof ? 1 : 0) "
            + "current=\(controlReport.currentSiblingRelation)/"
            + "\(attackReport.currentSiblingRelation)"
    )
    print(
        "GATE_F_E12_ATTACK_06_DIGEST control="
            + "\(controlReport.checkpointSHA256)/\(controlReport.durableSHA256) "
            + "attack=\(attackReport.checkpointSHA256)/"
            + "\(attackReport.durableSHA256) schema=35 observer=13"
    )
}
