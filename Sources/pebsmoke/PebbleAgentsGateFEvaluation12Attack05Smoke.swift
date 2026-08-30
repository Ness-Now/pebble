import Foundation
import PebbleAgents

struct GateFE12A5Seed {
    var session: AgentSimulationSession
    let successorProofSHA256: String
    let seedCausal: [String: UInt64]
}

private let gateFE12A5Parent0 = AgentID(rawValue: "agent_0")!
private let gateFE12A5Parent1 = AgentID(rawValue: "agent_1")!
private let gateFE12A5Parent2 = AgentID(rawValue: "agent_2")!
private let gateFE12A5Decedent = AgentID(rawValue: "agent_3")!
private let gateFE12A5FullSibling = AgentID(rawValue: "agent_4")!
private let gateFE12A5HalfSibling = AgentID(rawValue: "agent_5")!
private let gateFE12A5Grandchild = AgentID(rawValue: "agent_6")!

private func gateFE12A5ProofDigest(
    _ proof: AgentEstateSuccessorPlanProof
) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return AgentCheckpointDigest.sha256(try! encoder.encode(proof)).rawValue
}

private func gateFE12A5Interaction(
    _ session: AgentSimulationSession,
    id: String,
    kind: AgentFamilyInteractionKind,
    actor: AgentID,
    counterparty: AgentID
) -> AgentFamilyInteractionReceipt {
    let states = Dictionary(uniqueKeysWithValues: session.snapshot().agents.map {
        (AgentID(rawValue: $0.id)!, $0)
    })
    return AgentFamilyInteractionReceipt(
        receiptID: id, kind: kind,
        actorID: actor, counterpartyID: counterparty,
        observedTick: session.tick,
        actorPosition: states[actor]!.position,
        counterpartyPosition: states[counterparty]!.position,
        communicationVerified: true
    )
}

private func gateFE12A5CreateUnion(
    _ session: inout AgentSimulationSession,
    first: AgentID,
    second: AgentID,
    suffix: String
) -> AgentUnionRecord {
    let proposal = try! session.proposeUnion(gateFE12A5Interaction(
        session, id: "e12-a5-union-\(suffix)-proposal",
        kind: .unionProposal, actor: first, counterparty: second
    ))
    return try! session.acceptUnion(
        proposalID: proposal.proposalID,
        receipt: gateFE12A5Interaction(
            session, id: "e12-a5-union-\(suffix)-accept",
            kind: .unionAcceptance, actor: second, counterparty: first
        )
    )
}

private func gateFE12A5EndUnion(
    _ session: inout AgentSimulationSession,
    union: AgentUnionRecord,
    actor: AgentID,
    counterparty: AgentID,
    suffix: String
) {
    try! session.endUnion(
        unionID: union.unionID, reason: .unilateralSeparation,
        receipt: gateFE12A5Interaction(
            session, id: "e12-a5-separate-\(suffix)",
            kind: .unionSeparation, actor: actor,
            counterparty: counterparty
        )
    )
}

private func gateFE12A5Birth(
    _ session: inout AgentSimulationSession,
    position: AgentPosition,
    fingerprint: Int
) -> AgentBirthRecord {
    var attempts = 0
    while session.pendingBirthSitePlan() == nil && attempts < 32 {
        gateFE12A5AdvanceSupported(&session)
        attempts += 1
    }
    let plan = session.pendingBirthSitePlan()!
    while session.tick < plan.dueTick {
        gateFE12A5AdvanceSupported(&session)
    }
    let birth = try! session.applyBirthSiteObservation(
        AgentBirthSiteObservation(
            planID: plan.planID, observedTick: session.tick,
            position: position, candidateIndex: 0,
            worldFingerprint: fingerprint
        )
    )
    precondition(
        birth != nil,
        "Attack 05 supported birth refused tick=\(session.tick) plan=\(plan)"
    )
    return birth!
}

private struct GateFE12A5Evolution {
    var session: AgentSimulationSession
    let proofDigest: String
    let causal: [String: UInt64]
}

private func gateFE12A5Evolve(_ seed: GateFE12A5Seed) -> GateFE12A5Evolution {
    var session = seed.session
    var iterations = 0
    while session.populationScaleSnapshot().settlementMigrations.contains(
        where: { $0.status == .inTransit }
    ) && iterations < 24 {
        gateFE12A5AdvanceSupported(&session)
        iterations += 1
    }
    let returnMigration = session.populationScaleSnapshot()
        .settlementMigrations.first {
            $0.migrationID.rawValue == "settlement-migration-00000002"
        }!
    precondition(returnMigration.status == .arrived)

    let parentHousehold = try! session.currentMembership(
        of: gateFE12A5Parent0
    )!.householdID
    if try! session.currentMembership(of: gateFE12A5Parent2)!.householdID
        != parentHousehold {
        try! session.moveMembers(
            memberIDs: [gateFE12A5Parent2], to: parentHousehold
        )
    }

    let originalUnion = try! session.activeUnion(for: gateFE12A5Parent0)!
    gateFE12A5EndUnion(
        &session, union: originalUnion, actor: gateFE12A5Parent1,
        counterparty: gateFE12A5Parent0, suffix: "original"
    )
    let secondUnion = gateFE12A5CreateUnion(
        &session, first: gateFE12A5Parent0, second: gateFE12A5Parent2,
        suffix: "half-sibling"
    )
    let sharedHouseID = try! session.currentHouseMemberships(
        of: gateFE12A5Parent0
    ).first!.houseID
    try! session.joinHouse(
        sharedHouseID,
        request: gateFE12A5Interaction(
            session, id: "e12-a5-house-join-request",
            kind: .houseJoinRequest, actor: gateFE12A5Parent2,
            counterparty: gateFE12A5Parent0
        ),
        acceptance: gateFE12A5Interaction(
            session, id: "e12-a5-house-join-acceptance",
            kind: .houseJoinAcceptance, actor: gateFE12A5Parent0,
            counterparty: gateFE12A5Parent2
        )
    )
    try! session.setReproductionEnabled(true)
    let halfBirth = gateFE12A5Birth(
        &session, position: AgentPosition(x: 1, y: 64, z: 1),
        fingerprint: 120_505
    )
    precondition(halfBirth.newbornID == gateFE12A5HalfSibling)
    try! session.setReproductionEnabled(false)
    gateFE12A5EndUnion(
        &session, union: secondUnion, actor: gateFE12A5Parent0,
        counterparty: gateFE12A5Parent2, suffix: "half-sibling"
    )

    while session.lifecycleSnapshot().members.first(where: {
        $0.agentID == gateFE12A5FullSibling
    })?.currentStage != .mature && iterations < 48 {
        gateFE12A5AdvanceSupported(&session)
        iterations += 1
    }
    precondition(session.lifecycleSnapshot().members.first {
        $0.agentID == gateFE12A5FullSibling
    }?.currentStage == .mature)
    let thirdUnion = gateFE12A5CreateUnion(
        &session, first: gateFE12A5FullSibling,
        second: gateFE12A5Parent2, suffix: "multigeneration"
    )
    try! session.setReproductionEnabled(true)
    let grandchildBirth = gateFE12A5Birth(
        &session, position: AgentPosition(x: 1, y: 64, z: 2),
        fingerprint: 120_506
    )
    precondition(grandchildBirth.newbornID == gateFE12A5Grandchild)
    try! session.setReproductionEnabled(false)

    let halfParentage = session.kinshipSnapshot().parentageRecords.first {
        $0.childID == gateFE12A5HalfSibling
    }!
    let grandParentage = session.kinshipSnapshot().parentageRecords.first {
        $0.childID == gateFE12A5Grandchild
    }!
    let endedOriginal = session.familySnapshot().unions.first {
        $0.unionID == originalUnion.unionID
    }!
    let endedSecond = session.familySnapshot().unions.first {
        $0.unionID == secondUnion.unionID
    }!
    let activeThird = session.familySnapshot().unions.first {
        $0.unionID == thirdUnion.unionID
    }!
    var causal = seed.seedCausal
    causal["returnArrival"] = returnMigration.arrivedEventID!.sequence.rawValue
    causal["originalSeparation"] = endedOriginal.terminationEventID!.sequence.rawValue
    causal["secondUnion"] = secondUnion.activationEventID.sequence.rawValue
    causal["halfSiblingBirth"] = halfBirth.populationBornEventID.sequence.rawValue
    causal["halfSiblingParentage"] = halfParentage.recordedEventID.sequence.rawValue
    causal["secondSeparation"] = endedSecond.terminationEventID!.sequence.rawValue
    causal["thirdUnion"] = activeThird.activationEventID.sequence.rawValue
    causal["grandchildBirth"] = grandchildBirth.populationBornEventID.sequence.rawValue
    causal["grandchildParentage"] = grandParentage.recordedEventID.sequence.rawValue
    return GateFE12A5Evolution(
        session: session, proofDigest: seed.successorProofSHA256,
        causal: causal
    )
}

private struct GateFE12A5Identities: Codable, Equatable {
    let nextPopulationOrdinal: Int
    let nextFidelityOrdinal: UInt64
    let nextMigrationOrdinal: UInt64
    let nextHouseholdOrdinal: Int
    let nextUnionOrdinal: Int
    let nextLineageOrdinal: Int
    let nextFamilyHouseOrdinal: Int
    let populationIDs: [String]
    let fidelityIDs: [String]
    let migrationIDs: [String]
    let householdIDs: [String]
    let unionIDs: [String]
    let lineageIDs: [String]
    let familyHouseIDs: [String]
    let deathCount: Int
    let estateCount: Int
}

private struct GateFE12A5Report: Codable, Equatable {
    let phase: String
    let tick: Int
    let checkpointSchema: Int
    let observerSchema: Int
    let checkpointSHA256: String
    let durableSHA256: String
    let successorProofSHA256: String
    let successorProofVersion: Int
    let historicalProofRowIDs: [String]
    let fullSiblingRelation: String
    let halfSiblingRelation: String
    let grandchildRelation: Bool
    let grandchildLineageRoots: [String]
    let grandchildFamilyHouseCount: Int
    let currentGuardianIDs: [String]
    let migrationStatuses: [String]
    let causal: [String: UInt64]
    let identities: GateFE12A5Identities
    let replayedBirths: Int
    let replayedDeaths: Int
    let replayedEstates: Int
    let observerMutationCount: Int
    let assertions: [String: Bool]
}

private func gateFE12A5Identities(
    _ session: AgentSimulationSession
) -> GateFE12A5Identities {
    let durable = session.durableState()
    let population = durable.populationRegistry!
    let scale = population.scaleState!
    let household = durable.householdState!
    let family = durable.familyState!
    return GateFE12A5Identities(
        nextPopulationOrdinal: population.nextPopulationOrdinal.rawValue,
        nextFidelityOrdinal: scale.nextFidelityTransitionOrdinal,
        nextMigrationOrdinal: scale.nextSettlementMigrationOrdinal,
        nextHouseholdOrdinal: household.nextHouseholdOrdinal.rawValue,
        nextUnionOrdinal: family.nextUnionOrdinal,
        nextLineageOrdinal: family.nextLineageOrdinal,
        nextFamilyHouseOrdinal: family.nextHouseOrdinal,
        populationIDs: population.members.map { $0.agentID.rawValue }.sorted(),
        fidelityIDs: scale.fidelityRecords.map { $0.agentID.rawValue }.sorted(),
        migrationIDs: scale.settlementMigrations.map {
            $0.migrationID.rawValue
        }.sorted(),
        householdIDs: household.households.map {
            $0.householdID.rawValue
        }.sorted(),
        unionIDs: family.unions.map { $0.unionID.rawValue }.sorted(),
        lineageIDs: family.lineages.map { $0.lineageID.rawValue }.sorted(),
        familyHouseIDs: family.houses.map { $0.houseID.rawValue }.sorted(),
        deathCount: session.mortalitySnapshot().totalDeathCount,
        estateCount: session.estateSnapshot().totalEstateCount
    )
}

private func gateFE12A5CurrentAuthorityIsSingular(
    _ session: AgentSimulationSession
) -> Bool {
    let durable = session.durableState()
    let population = durable.populationRegistry!
    let scale = population.scaleState!
    let household = durable.householdState!
    return session.expectedActiveAgentIDs().allSatisfy { id in
        population.members.filter { $0.agentID == id }.count == 1
            && scale.fidelityRecords.filter { $0.agentID == id }.count == 1
            && population.settlements.reduce(0) { total, settlement in
                total + (settlement.residentIDs.contains(id) ? 1 : 0)
                    + (settlement.inTransitIDs.contains(id) ? 1 : 0)
            } == 1
            && household.membershipPeriods.filter {
                $0.agentID == id && $0.leftTick == nil
            }.count == 1
    }
}

private func gateFE12A5DeadAuthorityIsAbsent(
    _ session: AgentSimulationSession
) -> Bool {
    let durable = session.durableState()
    let population = durable.populationRegistry!
    let scale = population.scaleState!
    let household = durable.householdState!
    return !session.expectedActiveAgentIDs().contains(gateFE12A5Decedent)
        && !population.members.contains { $0.agentID == gateFE12A5Decedent }
        && !scale.fidelityRecords.contains { $0.agentID == gateFE12A5Decedent }
        && !population.settlements.contains {
            $0.residentIDs.contains(gateFE12A5Decedent)
                || $0.inTransitIDs.contains(gateFE12A5Decedent)
        }
        && !household.membershipPeriods.contains {
            $0.agentID == gateFE12A5Decedent && $0.leftTick == nil
        }
}

private func gateFE12A5SiblingRelationText(
    _ relation: AgentSiblingRelation
) -> String {
    switch relation {
    case .samePerson:
        return "samePerson"
    case .unrelated:
        return "unrelated"
    case .halfSibling:
        return "halfSibling"
    case .fullSibling:
        return "fullSibling"
    case let .unknownParentage(agentID):
        return "unknownParentage:\(agentID.rawValue)"
    case let .unknownPerson(agentID):
        return "unknownPerson:\(agentID.rawValue)"
    }
}

private func gateFE12A5Report(
    phase: String,
    session: inout AgentSimulationSession,
    expectedProofDigest: String,
    causal: [String: UInt64],
    expectedStage: String,
    observerSchema: Int = 13,
    observerMutationCount: Int = 0,
    replayedBirths: Int = 0,
    replayedDeaths: Int = 0,
    replayedEstates: Int = 0
) -> GateFE12A5Report {
    let checkpoint = try! session.makeCheckpoint()
    let checkpointBytes = try! AgentCheckpointCodec.encode(checkpoint)
    let durableBytes = try! session.durableStateBytes()
    let estate = session.estateSnapshot().estates.first {
        $0.decedentID == gateFE12A5Decedent
    }!
    let proof = estate.successorPlanProof!
    let proofDigest = gateFE12A5ProofDigest(proof)
    let identities = gateFE12A5Identities(session)
    let family = session.familySnapshot()
    let migrations = session.populationScaleSnapshot().settlementMigrations
    let fullRelation = gateFE12A5SiblingRelationText(session.siblingRelation(
        between: gateFE12A5Decedent, and: gateFE12A5FullSibling
    ))
    let halfRelation = session.kinshipSnapshot().historicalPersons.contains {
        $0.agentID == gateFE12A5HalfSibling
    } ? gateFE12A5SiblingRelationText(session.siblingRelation(
        between: gateFE12A5FullSibling, and: gateFE12A5HalfSibling
    )) : "notBorn"
    let grandchildExists = session.kinshipSnapshot().historicalPersons.contains {
        $0.agentID == gateFE12A5Grandchild
    }
    let grandchildRelation = grandchildExists && (try! session.familyRelations(
        of: gateFE12A5Parent0
    )).contains {
        $0.kind == .grandchild && $0.relatedPersonID == gateFE12A5Grandchild
    }
    let lineageRoots = grandchildExists ? (try! session.lineages(
        containing: gateFE12A5Grandchild
    )).map { $0.lineage.rootPersonID.rawValue }.sorted() : []
    let familyHouseCount = grandchildExists ? (try! session
        .currentHouseMemberships(of: gateFE12A5Grandchild)).count : 0
    let historicalPersonIDs = Set(
        session.kinshipSnapshot().historicalPersons.map(\.agentID)
    )
    let guardianIDs = [gateFE12A5FullSibling, gateFE12A5HalfSibling,
                       gateFE12A5Grandchild].filter {
        historicalPersonIDs.contains($0)
    }.compactMap {
        try! session.currentGuardian(for: $0)?.guardianID.rawValue
    }.sorted()
    let proofRows = proof.eligibilityRows.map { $0.agentID.rawValue }.sorted()
    let populationIDs = identities.populationIDs
    let fidelityIDs = identities.fidelityIDs
    let household = session.householdSnapshot()
    let parentages = session.kinshipSnapshot().parentageRecords
    var assertions: [String: Bool] = [
        "checkpoint_schema_35": checkpoint.schemaVersion == 35,
        "observer_schema_13_read_only": observerSchema == 13
            && observerMutationCount == 0,
        "estate_v2_proof_exact": proof.version == 2
            && proofDigest == expectedProofDigest,
        "pre_plan_full_sibling_stays_exact": fullRelation == "fullSibling"
            && proofRows.contains(gateFE12A5FullSibling.rawValue),
        "identity_sets_unique": Set(populationIDs).count == populationIDs.count
            && Set(fidelityIDs).count == fidelityIDs.count
            && Set(identities.migrationIDs).count == identities.migrationIDs.count
            && Set(identities.householdIDs).count == identities.householdIDs.count
            && Set(identities.unionIDs).count == identities.unionIDs.count
            && Set(identities.lineageIDs).count == identities.lineageIDs.count
            && Set(identities.familyHouseIDs).count
                == identities.familyHouseIDs.count,
        "identity_ordinals_monotone": identities.nextPopulationOrdinal
                >= populationIDs.count
            && identities.nextHouseholdOrdinal >= household.households.count
            && identities.nextUnionOrdinal >= family.unions.count
            && identities.nextLineageOrdinal >= family.lineages.count
            && identities.nextFamilyHouseOrdinal >= family.houses.count
            && identities.nextMigrationOrdinal > UInt64(migrations.count),
        "authority_singular": gateFE12A5CurrentAuthorityIsSingular(session),
        "dead_authority_absent": gateFE12A5DeadAuthorityIsAbsent(session),
        "death_estate_exactly_once": identities.deathCount == 1
            && identities.estateCount == 1,
        "zero_replay": replayedBirths == 0 && replayedDeaths == 0
            && replayedEstates == 0,
    ]
    if expectedStage == "seed" {
        assertions["seed_has_two_births_and_active_return_migration"] =
            identities.nextPopulationOrdinal == 5
                && migrations.filter { $0.status == .inTransit }.count == 1
                && parentages.map(\.childID).contains(gateFE12A5Decedent)
                && parentages.map(\.childID).contains(gateFE12A5FullSibling)
                && halfRelation == "notBorn" && !grandchildExists
    } else {
        let grandParentage = parentages.first {
            $0.childID == gateFE12A5Grandchild
        }
        assertions["full_half_and_multigeneration_truth_exact"] =
            halfRelation == "halfSibling" && grandchildRelation
                && Set(grandParentage?.canonicalParentIDs ?? [])
                    == Set([gateFE12A5Parent2, gateFE12A5FullSibling])
                && lineageRoots == ["agent_0", "agent_1"]
                && familyHouseCount > 0
        assertions["later_family_never_retroactive_in_estate"] =
            !proofRows.contains(gateFE12A5HalfSibling.rawValue)
                && !proofRows.contains(gateFE12A5Grandchild.rawValue)
                && causal["estatePlan"]! < causal["halfSiblingParentage"]!
                && causal["halfSiblingParentage"]! < causal["grandchildParentage"]!
        assertions["three_union_histories_are_ordered"] = family.unions.count == 3
            && family.unions.filter { $0.status == .ended }.count == 2
            && family.unions.filter { $0.status == .active }.count == 1
            && causal["originalSeparation"]! < causal["secondUnion"]!
            && causal["secondUnion"]! < causal["secondSeparation"]!
            && causal["secondSeparation"]! < causal["thirdUnion"]!
        assertions["civ39_migration_history_stays_coherent"] =
            migrations.count == 2
                && migrations.allSatisfy { $0.status == .arrived }
                && Set(migrations.map(\.migrationID)).count == 2
        assertions["population_and_fidelity_cover_six_live_people"] =
            identities.nextPopulationOrdinal == 7
                && populationIDs.count == 6 && fidelityIDs == populationIDs
    }
    return GateFE12A5Report(
        phase: phase, tick: session.tick,
        checkpointSchema: checkpoint.schemaVersion,
        observerSchema: observerSchema,
        checkpointSHA256: AgentCheckpointDigest.sha256(checkpointBytes).rawValue,
        durableSHA256: AgentCheckpointDigest.sha256(durableBytes).rawValue,
        successorProofSHA256: proofDigest,
        successorProofVersion: proof.version,
        historicalProofRowIDs: proofRows,
        fullSiblingRelation: fullRelation,
        halfSiblingRelation: halfRelation,
        grandchildRelation: grandchildRelation,
        grandchildLineageRoots: lineageRoots,
        grandchildFamilyHouseCount: familyHouseCount,
        currentGuardianIDs: guardianIDs,
        migrationStatuses: migrations.map { $0.status.rawValue },
        causal: causal, identities: identities,
        replayedBirths: replayedBirths,
        replayedDeaths: replayedDeaths,
        replayedEstates: replayedEstates,
        observerMutationCount: observerMutationCount,
        assertions: assertions
    )
}

private func gateFE12A5Write<T: Encodable>(_ value: T, to url: URL) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    try! encoder.encode(value).write(to: url, options: .atomic)
}

private func gateFE12A5RebuildReport(
    _ report: GateFE12A5Report,
    assertions: [String: Bool],
    observerSchema: Int? = nil
) -> GateFE12A5Report {
    GateFE12A5Report(
        phase: report.phase, tick: report.tick,
        checkpointSchema: report.checkpointSchema,
        observerSchema: observerSchema ?? report.observerSchema,
        checkpointSHA256: report.checkpointSHA256,
        durableSHA256: report.durableSHA256,
        successorProofSHA256: report.successorProofSHA256,
        successorProofVersion: report.successorProofVersion,
        historicalProofRowIDs: report.historicalProofRowIDs,
        fullSiblingRelation: report.fullSiblingRelation,
        halfSiblingRelation: report.halfSiblingRelation,
        grandchildRelation: report.grandchildRelation,
        grandchildLineageRoots: report.grandchildLineageRoots,
        grandchildFamilyHouseCount: report.grandchildFamilyHouseCount,
        currentGuardianIDs: report.currentGuardianIDs,
        migrationStatuses: report.migrationStatuses,
        causal: report.causal, identities: report.identities,
        replayedBirths: report.replayedBirths,
        replayedDeaths: report.replayedDeaths,
        replayedEstates: report.replayedEstates,
        observerMutationCount: report.observerMutationCount,
        assertions: assertions
    )
}

private func gateFE12A5FreshIfRequested() -> Bool {
    let environment = ProcessInfo.processInfo.environment
    guard let phase = environment["PEBBLELAB_GATE_F_E12_A5_PHASE"] else {
        return false
    }
    guard ["write-seed", "restore-evolve", "restore-verify"].contains(phase),
          let output = environment["PEBBLELAB_GATE_F_E12_A5_OUT"] else {
        preconditionFailure("invalid Evaluation 12 Attack 05 environment")
    }
    let root = URL(fileURLWithPath: output, isDirectory: true)
    try! FileManager.default.createDirectory(
        at: root, withIntermediateDirectories: true
    )
    let seedCheckpointURL = root.appendingPathComponent("seed_checkpoint_v35.json")
    let seedDurableURL = root.appendingPathComponent("seed_durable_state.json")
    let evolvedCheckpointURL = root.appendingPathComponent("evolved_checkpoint_v35.json")
    let evolvedDurableURL = root.appendingPathComponent("evolved_durable_state.json")
    let process1URL = root.appendingPathComponent("process_1_report.json")
    let process2URL = root.appendingPathComponent("process_2_report.json")

    if phase == "write-seed" {
        var seed = gateFE12A5BuildSeed("gate-f-e12-a5-fresh")
        let report = gateFE12A5Report(
            phase: phase, session: &seed.session,
            expectedProofDigest: seed.successorProofSHA256,
            causal: seed.seedCausal, expectedStage: "seed"
        )
        try! AgentCheckpointCodec.encode(seed.session.makeCheckpoint())
            .write(to: seedCheckpointURL, options: .atomic)
        try! seed.session.durableStateBytes()
            .write(to: seedDurableURL, options: .atomic)
        gateFE12A5Write(report, to: process1URL)
        check("Attack 05 writer checkpoints evolved-family seed",
              report.assertions.values.allSatisfy { $0 })
        return true
    }

    if phase == "restore-evolve" {
        let checkpointBytes = try! Data(contentsOf: seedCheckpointURL)
        let durableBytes = try! Data(contentsOf: seedDurableURL)
        let previous = try! JSONDecoder().decode(
            GateFE12A5Report.self, from: Data(contentsOf: process1URL)
        )
        let checkpoint = try! AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self, from: checkpointBytes
        )
        let restored = try! AgentSimulationSession.restoring(checkpoint)
        let restoredDurable = try! restored.durableStateBytes()
        let observerBefore = restoredDurable
        let observer = restored.observerSnapshot(worldBinding:
            try! AgentObserverWorldBinding(
                worldID: "gate-f-e12-a5-world",
                storageIdentity: "memory:gate-f-e12-a5", seed: 1_212,
                dimension: 0, observedWorldTick: restored.tick
            )
        )
        let observerMutations = (try! restored.durableStateBytes())
            == observerBefore ? 0 : 1
        var evolution = gateFE12A5Evolve(GateFE12A5Seed(
            session: restored,
            successorProofSHA256: previous.successorProofSHA256,
            seedCausal: previous.causal
        ))
        var report = gateFE12A5Report(
            phase: phase, session: &evolution.session,
            expectedProofDigest: evolution.proofDigest,
            causal: evolution.causal, expectedStage: "evolved",
            observerSchema: observer.header.schemaVersion,
            observerMutationCount: observerMutations
        )
        var assertions = report.assertions
        assertions["seed_checkpoint_reencodes_exactly"] =
            (try? AgentCheckpointCodec.encode(checkpoint)) == checkpointBytes
        assertions["seed_durable_restores_exactly"] = restoredDurable == durableBytes
        report = gateFE12A5RebuildReport(
            report, assertions: assertions,
            observerSchema: observer.header.schemaVersion
        )
        try! AgentCheckpointCodec.encode(evolution.session.makeCheckpoint())
            .write(to: evolvedCheckpointURL, options: .atomic)
        try! evolution.session.durableStateBytes()
            .write(to: evolvedDurableURL, options: .atomic)
        gateFE12A5Write(report, to: process2URL)
        check("Attack 05 fresh restore continues multigeneration truth",
              report.assertions.values.allSatisfy { $0 })
        return true
    }

    let checkpointBytes = try! Data(contentsOf: evolvedCheckpointURL)
    let durableBytes = try! Data(contentsOf: evolvedDurableURL)
    let previous = try! JSONDecoder().decode(
        GateFE12A5Report.self, from: Data(contentsOf: process2URL)
    )
    let checkpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self, from: checkpointBytes
    )
    var session = try! AgentSimulationSession.restoring(checkpoint)
    let restoredDurable = try! session.durableStateBytes()
    let birthsBefore = session.lifecycleSnapshot().totalBirthCount
    let deathsBefore = session.mortalitySnapshot().totalDeathCount
    let estatesBefore = session.estateSnapshot().totalEstateCount
    gateFE12A5AdvanceSupported(&session)
    var report = gateFE12A5Report(
        phase: phase, session: &session,
        expectedProofDigest: previous.successorProofSHA256,
        causal: previous.causal, expectedStage: "evolved",
        replayedBirths: session.lifecycleSnapshot().totalBirthCount - birthsBefore,
        replayedDeaths: session.mortalitySnapshot().totalDeathCount - deathsBefore,
        replayedEstates: session.estateSnapshot().totalEstateCount - estatesBefore
    )
    var assertions = report.assertions
    assertions["evolved_checkpoint_reencodes_exactly"] =
        (try? AgentCheckpointCodec.encode(checkpoint)) == checkpointBytes
    assertions["evolved_durable_restores_exactly"] = restoredDurable == durableBytes
    report = gateFE12A5RebuildReport(report, assertions: assertions)
    gateFE12A5Write(report, to: root.appendingPathComponent("process_3_report.json"))
    check("Attack 05 final reader preserves family/Estate/scale truth",
          report.assertions.values.allSatisfy { $0 })
    return true
}

func runPebbleAgentsGateFEvaluation12Attack05Smoke() {
    if gateFE12A5FreshIfRequested() { return }
    var evolution = gateFE12A5Evolve(
        gateFE12A5BuildSeed("gate-f-e12-a5-focused")
    )
    let report = gateFE12A5Report(
        phase: "focused", session: &evolution.session,
        expectedProofDigest: evolution.proofDigest,
        causal: evolution.causal, expectedStage: "evolved"
    )
    section("Gate F Evaluation 12 Attack 05 — evolved family/Estate/scale")
    for key in report.assertions.keys.sorted() {
        check("Attack 05 \(key)", report.assertions[key]!)
    }
    print(
        "GATE_F_E12_ATTACK_05_CAUSAL plan=\(report.causal["estatePlan"]!) "
            + "return=\(report.causal["returnArrival"]!) "
            + "half=\(report.causal["halfSiblingParentage"]!) "
            + "grand=\(report.causal["grandchildParentage"]!)"
    )
    print(
        "GATE_F_E12_ATTACK_05_FAMILY full=\(report.fullSiblingRelation) "
            + "half=\(report.halfSiblingRelation) "
            + "grandchild=\(report.grandchildRelation ? 1 : 0) "
            + "lineages=\(report.grandchildLineageRoots.joined(separator: ",")) "
            + "familyHouses=\(report.grandchildFamilyHouseCount)"
    )
    print(
        "GATE_F_E12_ATTACK_05_IDENTITY population="
            + "\(report.identities.nextPopulationOrdinal) fidelity="
            + "\(report.identities.nextFidelityOrdinal) migration="
            + "\(report.identities.nextMigrationOrdinal) household="
            + "\(report.identities.nextHouseholdOrdinal) union="
            + "\(report.identities.nextUnionOrdinal) death="
            + "\(report.identities.deathCount) estate="
            + "\(report.identities.estateCount)"
    )
    print(
        "GATE_F_E12_ATTACK_05_DIGEST checkpoint=\(report.checkpointSHA256) "
            + "durable=\(report.durableSHA256) proof="
            + "\(report.successorProofSHA256) schema="
            + "\(report.checkpointSchema) observer=\(report.observerSchema)"
    )
}
