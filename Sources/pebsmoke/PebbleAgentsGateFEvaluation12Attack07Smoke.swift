import Foundation
import PebbleAgents

struct GateFE12A7Seed {
    var session: AgentSimulationSession
    let scenario: String
    let causal: [String: UInt64]
}

private let gateFE12A7TerminalID = AgentID(rawValue: "agent_2")!
private let gateFE12A7EastID = AgentSettlementID(rawValue: "settlement-east")!
private let gateFE12A7NewHome = AgentPosition(x: 8, y: 64, z: 0)

private struct GateFE12A7Ordinals: Codable, Equatable {
    let population: Int
    let fidelity: UInt64
    let migration: UInt64
    let household: Int
    let householdPeriods: Int
    let householdTransitions: Int
    let deaths: Int
    let estates: Int
}

private struct GateFE12A7Authority: Codable, Equatable {
    let activeAgent: Bool
    let populationMember: Bool
    let fidelityOwnerCount: Int
    let residentCount: Int
    let inTransitCount: Int
    let currentHouseholdID: String?
    let currentHouseholdCount: Int
    let mortalityPending: Bool
    let activeMigrationCount: Int
    let migrationStatus: String?
    let migrationFailure: String?
    let deathCount: Int
    let estateCount: Int
}

private struct GateFE12A7Report: Codable, Equatable {
    let phase: String
    let scenario: String
    let tick: Int
    let checkpointSchema: Int
    let observerSchema: Int
    let checkpointSHA256: String
    let durableSHA256: String
    let causal: [String: UInt64]
    let ordinals: GateFE12A7Ordinals
    let authority: GateFE12A7Authority
    let migrationRefused: Bool
    let householdRefused: Bool
    let refusalMutationCount: Int
    let replayedDeaths: Int
    let replayedEstates: Int
    let observerMutationCount: Int
    let assertions: [String: Bool]
}

private func gateFE12A7Ordinals(
    _ session: AgentSimulationSession
) -> GateFE12A7Ordinals {
    let durable = session.durableState()
    let population = durable.populationRegistry!
    let scale = population.scaleState!
    let household = durable.householdState!
    return GateFE12A7Ordinals(
        population: population.nextPopulationOrdinal.rawValue,
        fidelity: scale.nextFidelityTransitionOrdinal,
        migration: scale.nextSettlementMigrationOrdinal,
        household: household.nextHouseholdOrdinal.rawValue,
        householdPeriods: household.membershipPeriods.count,
        householdTransitions: household.transitionsAtTick,
        deaths: durable.mortalityState!.totalDeathCount,
        estates: durable.estateState!.totalEstateCount
    )
}

private func gateFE12A7Authority(
    _ session: AgentSimulationSession
) -> GateFE12A7Authority {
    let durable = session.durableState()
    let population = durable.populationRegistry!
    let scale = population.scaleState!
    let household = durable.householdState!
    let current = household.membershipPeriods.filter {
        $0.agentID == gateFE12A7TerminalID && $0.leftTick == nil
    }
    let migration = scale.settlementMigrations.last {
        $0.agentID == gateFE12A7TerminalID
    }
    return GateFE12A7Authority(
        activeAgent: session.expectedActiveAgentIDs().contains(
            gateFE12A7TerminalID
        ),
        populationMember: population.members.contains {
            $0.agentID == gateFE12A7TerminalID
        },
        fidelityOwnerCount: scale.fidelityRecords.filter {
            $0.agentID == gateFE12A7TerminalID
        }.count,
        residentCount: population.settlements.reduce(0) {
            $0 + ($1.residentIDs.contains(gateFE12A7TerminalID) ? 1 : 0)
        },
        inTransitCount: population.settlements.reduce(0) {
            $0 + ($1.inTransitIDs.contains(gateFE12A7TerminalID) ? 1 : 0)
        },
        currentHouseholdID: current.first?.householdID.rawValue,
        currentHouseholdCount: current.count,
        mortalityPending: durable.mortalityState!.pendingTransitions.contains {
            $0.agentID == gateFE12A7TerminalID
        },
        activeMigrationCount: scale.settlementMigrations.filter {
            $0.agentID == gateFE12A7TerminalID && $0.status == .inTransit
        }.count,
        migrationStatus: migration?.status.rawValue,
        migrationFailure: migration?.failure?.rawValue,
        deathCount: durable.mortalityState!.totalDeathCount,
        estateCount: durable.estateState!.totalEstateCount
    )
}

private func gateFE12A7Route(from start: AgentPosition) -> [AgentPosition] {
    let destination = AgentPosition(x: 16, y: 64, z: 0)
    var route = [start]
    var cursor = start
    while cursor.z != destination.z {
        cursor = AgentPosition(
            x: cursor.x, y: cursor.y,
            z: cursor.z + (cursor.z < destination.z ? 1 : -1)
        )
        route.append(cursor)
    }
    while cursor.x != destination.x {
        cursor = AgentPosition(
            x: cursor.x + (cursor.x < destination.x ? 1 : -1),
            y: cursor.y, z: cursor.z
        )
        route.append(cursor)
    }
    return route
}

private func gateFE12A7PendingRefusal(
    _ body: () throws -> Void
) -> Bool {
    do {
        try body()
        return false
    } catch AgentSessionError.mortality(.pendingMaterialExit(
        gateFE12A7TerminalID.rawValue
    )) {
        return true
    } catch {
        return false
    }
}

private func gateFE12A7Finalize(
    _ session: inout AgentSimulationSession,
    causal: inout [String: UInt64],
    suffix: String
) {
    let custody = try! session.applyMortalityPhysicalCustodyOutcome(
        AgentMortalityPhysicalCustodyOutcome(
            operationID: "e12-a7-empty-\(suffix)",
            terminalAgentID: gateFE12A7TerminalID,
            kind: .verifiedEmpty,
            physicalReceiptID: "e12-a7-empty-receipt-\(suffix)",
            destinationHolderID: nil, stackCount: 0, itemCount: 0,
            physicalAssets: [], verifiedAtTick: session.tick
        )
    )
    causal["physicalCustody"] = custody.eventID.sequence.rawValue
    _ = try! session.finalizePendingMortality(for: gateFE12A7TerminalID)
    let events = session.causalLedgerSnapshot().events
    causal["householdCleanup"] = events.first {
        $0.kind == .householdMembershipEnded
            && $0.subjectID == gateFE12A7TerminalID
            && $0.sequence.rawValue > causal["mortalityPending"]!
    }!.sequence.rawValue
    if let migration = events.first(where: {
        $0.kind == .settlementMigrationFailed
            && $0.subjectID == gateFE12A7TerminalID
    }) {
        causal["migrationCleanup"] = migration.sequence.rawValue
    }
    causal["deathFinal"] = events.first {
        $0.kind == .agentDeathFinalized
            && $0.subjectID == gateFE12A7TerminalID
    }!.sequence.rawValue
    let estate = session.estateSnapshot().estates.first {
        $0.decedentID == gateFE12A7TerminalID
    }!
    causal["estatePlan"] = estate.successorPlanEventID.sequence.rawValue
}

private func gateFE12A7Report(
    phase: String,
    scenario: String,
    session: AgentSimulationSession,
    causal: [String: UInt64],
    expectedStage: String,
    migrationRefused: Bool = false,
    householdRefused: Bool = false,
    refusalMutationCount: Int = 0,
    replayedDeaths: Int = 0,
    replayedEstates: Int = 0,
    extraAssertions: [String: Bool] = [:]
) -> GateFE12A7Report {
    let checkpoint = try! session.makeCheckpoint()
    let checkpointBytes = try! AgentCheckpointCodec.encode(checkpoint)
    let durableBytes = try! session.durableStateBytes()
    let observer = session.observerSnapshot(
        worldBinding: try! AgentObserverWorldBinding(
            worldID: "gate-f-e12-a7-\(scenario)-world",
            storageIdentity: "memory:gate-f-e12-a7-\(scenario)",
            seed: 1_207, dimension: 0,
            observedWorldTick: session.tick
        )
    )
    let observerMutations = (try! session.durableStateBytes())
        == durableBytes ? 0 : 1
    let ordinals = gateFE12A7Ordinals(session)
    let authority = gateFE12A7Authority(session)
    let durable = session.durableState()
    let population = durable.populationRegistry!
    let scale = population.scaleState!
    let household = durable.householdState!
    let populationIDs = population.members.map(\.agentID)
    let fidelityIDs = scale.fidelityRecords.map(\.agentID)
    let currentPeriods = household.membershipPeriods.filter {
        $0.leftTick == nil
    }
    let singular = Set(populationIDs).count == populationIDs.count
        && Set(fidelityIDs).count == fidelityIDs.count
        && Set(populationIDs) == Set(fidelityIDs)
        && session.expectedActiveAgentIDs().allSatisfy { id in
            population.settlements.reduce(0) {
                $0 + ($1.residentIDs.contains(id) ? 1 : 0)
                    + ($1.inTransitIDs.contains(id) ? 1 : 0)
            } == 1 && currentPeriods.filter { $0.agentID == id }.count == 1
        }
    var assertions: [String: Bool] = [
        "checkpoint_schema_35": checkpoint.schemaVersion == 35,
        "observer_schema_13_read_only": observer.header.schemaVersion == 13
            && observerMutations == 0,
        "aggregate_authority_singular": singular,
        "identity_ordinals_monotone": ordinals.population == 3
            && ordinals.fidelity >= 3 && ordinals.migration >= 1
            && ordinals.household >= 2,
        "zero_replay": replayedDeaths == 0 && replayedEstates == 0,
    ]
    if expectedStage == "pending-forward" {
        assertions["persisted_pending_with_existing_household"] =
            authority.mortalityPending
                && authority.currentHouseholdCount == 1
                && authority.activeMigrationCount == 0
                && authority.residentCount == 1
                && causal["existingHousehold"]! < causal["mortalityPending"]!
    } else if expectedStage == "pending-inverse" {
        assertions["household_and_migration_precede_pending"] =
            authority.mortalityPending
                && authority.currentHouseholdID == "household_2"
                && authority.activeMigrationCount == 1
                && authority.inTransitCount == 1
                && causal["householdEstablished"]!
                    < causal["migrationStarted"]!
                && causal["migrationStarted"]! < causal["mortalityPending"]!
    } else {
        assertions["terminal_cleanup_removed_all_current_authority"] =
            !authority.activeAgent && !authority.populationMember
                && authority.fidelityOwnerCount == 0
                && authority.residentCount == 0
                && authority.inTransitCount == 0
                && authority.currentHouseholdCount == 0
                && !authority.mortalityPending
                && authority.activeMigrationCount == 0
        assertions["death_estate_exactly_once"] = authority.deathCount == 1
            && authority.estateCount == 1
        assertions["household_cleanup_precedes_death"] =
            causal["mortalityPending"]! < causal["physicalCustody"]!
                && causal["householdCleanup"]! < causal["deathFinal"]!
                && causal["estatePlan"]! < causal["deathFinal"]!
        if scenario == "authority-before-pending" {
            assertions["migration_cleanup_member_died_precedes_death"] =
                authority.migrationStatus == "failed"
                    && authority.migrationFailure == "memberDied"
                    && causal["migrationCleanup"]! < causal["deathFinal"]!
        } else {
            assertions["no_migration_was_acquired"] =
                authority.migrationStatus == nil
        }
    }
    assertions.merge(extraAssertions) { _, new in new }
    return GateFE12A7Report(
        phase: phase, scenario: scenario, tick: session.tick,
        checkpointSchema: checkpoint.schemaVersion,
        observerSchema: observer.header.schemaVersion,
        checkpointSHA256: AgentCheckpointDigest.sha256(
            checkpointBytes
        ).rawValue,
        durableSHA256: AgentCheckpointDigest.sha256(durableBytes).rawValue,
        causal: causal, ordinals: ordinals, authority: authority,
        migrationRefused: migrationRefused,
        householdRefused: householdRefused,
        refusalMutationCount: refusalMutationCount,
        replayedDeaths: replayedDeaths, replayedEstates: replayedEstates,
        observerMutationCount: observerMutations, assertions: assertions
    )
}

private func gateFE12A7Write<T: Encodable>(_ value: T, to url: URL) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    try! encoder.encode(value).write(to: url, options: .atomic)
}

private struct GateFE12A7Execution {
    var session: AgentSimulationSession
    let causal: [String: UInt64]
    let migrationRefused: Bool
    let householdRefused: Bool
    let refusalMutationCount: Int
    let refusalOrdinalsExact: Bool
}

private func gateFE12A7Execute(
    _ seed: GateFE12A7Seed,
    requireRefusals: Bool,
    suffix: String
) -> GateFE12A7Execution {
    var session = seed.session
    var causal = seed.causal
    var migrationRefused = false
    var householdRefused = false
    var mutationCount = 0
    let initialBytes = try! session.durableStateBytes()
    let initialCheckpoint = try! AgentCheckpointCodec.encode(
        session.makeCheckpoint()
    )
    let initialOrdinals = gateFE12A7Ordinals(session)
    if requireRefusals {
        migrationRefused = gateFE12A7PendingRefusal {
            _ = try session.beginSettlementMigration(
                agentID: gateFE12A7TerminalID,
                destinationSettlementID: gateFE12A7EastID,
                verifiedRoute: gateFE12A7Route(
                    from: try! session.state(for: gateFE12A7TerminalID).position
                )
            )
        }
        if (try! session.durableStateBytes()) != initialBytes
            || (try! AgentCheckpointCodec.encode(session.makeCheckpoint()))
                != initialCheckpoint {
            mutationCount += 1
        }
        let target = try! session.currentMembership(
            of: AgentID(rawValue: "agent_0")!
        )!.householdID
        householdRefused = gateFE12A7PendingRefusal {
            try session.moveMembers(
                memberIDs: [gateFE12A7TerminalID], to: target
            )
        }
        if (try! session.durableStateBytes()) != initialBytes
            || (try! AgentCheckpointCodec.encode(session.makeCheckpoint()))
                != initialCheckpoint {
            mutationCount += 1
        }
    }
    let refusalOrdinalsExact = gateFE12A7Ordinals(session) == initialOrdinals
    gateFE12A7Finalize(&session, causal: &causal, suffix: suffix)
    return GateFE12A7Execution(
        session: session, causal: causal,
        migrationRefused: migrationRefused,
        householdRefused: householdRefused,
        refusalMutationCount: mutationCount,
        refusalOrdinalsExact: refusalOrdinalsExact
    )
}

private func gateFE12A7FreshIfRequested() -> Bool {
    let environment = ProcessInfo.processInfo.environment
    guard let phase = environment["PEBBLELAB_GATE_F_E12_A7_PHASE"] else {
        return false
    }
    let valid = [
        "forward-write", "forward-restore-finalize", "forward-final-reader",
        "inverse-write", "inverse-restore-finalize", "inverse-final-reader",
    ]
    guard valid.contains(phase),
          let output = environment["PEBBLELAB_GATE_F_E12_A7_OUT"] else {
        preconditionFailure("invalid Evaluation 12 Attack 07 environment")
    }
    let root = URL(fileURLWithPath: output, isDirectory: true)
    try! FileManager.default.createDirectory(
        at: root, withIntermediateDirectories: true
    )
    let inverse = phase.hasPrefix("inverse")
    let prefix = inverse ? "inverse" : "forward"
    let scenario = inverse
        ? "authority-before-pending" : "pending-before-new-authority"
    let initialCheckpointURL = root.appendingPathComponent(
        "\(prefix)_initial_checkpoint_v35.json"
    )
    let initialDurableURL = root.appendingPathComponent(
        "\(prefix)_initial_durable_state.json"
    )
    let finalCheckpointURL = root.appendingPathComponent(
        "\(prefix)_final_checkpoint_v35.json"
    )
    let finalDurableURL = root.appendingPathComponent(
        "\(prefix)_final_durable_state.json"
    )
    let reportURL = root.appendingPathComponent("\(phase)_report.json")
    if phase.hasSuffix("write") {
        let seed = gateFE12A7BuildSeed(
            "gate-f-e12-a7-fresh-\(prefix)", inverse: inverse
        )
        let checkpointBytes = try! AgentCheckpointCodec.encode(
            seed.session.makeCheckpoint()
        )
        let durableBytes = try! seed.session.durableStateBytes()
        try! checkpointBytes.write(to: initialCheckpointURL, options: .atomic)
        try! durableBytes.write(to: initialDurableURL, options: .atomic)
        let report = gateFE12A7Report(
            phase: phase, scenario: seed.scenario, session: seed.session,
            causal: seed.causal,
            expectedStage: inverse ? "pending-inverse" : "pending-forward"
        )
        gateFE12A7Write(report, to: reportURL)
        check("Attack 07 \(prefix) writer freezes composed pending authority",
              report.assertions.values.allSatisfy { $0 })
        return true
    }

    if phase.hasSuffix("restore-finalize") {
        let checkpointBytes = try! Data(contentsOf: initialCheckpointURL)
        let durableBytes = try! Data(contentsOf: initialDurableURL)
        let initialReport = try! JSONDecoder().decode(
            GateFE12A7Report.self,
            from: Data(contentsOf: root.appendingPathComponent(
                "\(prefix)-write_report.json"
            ))
        )
        let checkpoint = try! AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self, from: checkpointBytes
        )
        let restored = try! AgentSimulationSession.restoring(checkpoint)
        let initialExact = (try! restored.durableStateBytes()) == durableBytes
            && (try! AgentCheckpointCodec.encode(checkpoint)) == checkpointBytes
        let execution = gateFE12A7Execute(
            GateFE12A7Seed(
                session: restored, scenario: scenario,
                causal: initialReport.causal
            ),
            requireRefusals: !inverse,
            suffix: "fresh-\(prefix)"
        )
        let finalCheckpointBytes = try! AgentCheckpointCodec.encode(
            execution.session.makeCheckpoint()
        )
        let finalDurableBytes = try! execution.session.durableStateBytes()
        try! finalCheckpointBytes.write(
            to: finalCheckpointURL, options: .atomic
        )
        try! finalDurableBytes.write(to: finalDurableURL, options: .atomic)
        let report = gateFE12A7Report(
            phase: phase, scenario: scenario, session: execution.session,
            causal: execution.causal, expectedStage: "final",
            migrationRefused: execution.migrationRefused,
            householdRefused: execution.householdRefused,
            refusalMutationCount: execution.refusalMutationCount,
            extraAssertions: [
                "initial_restore_exact": initialExact,
                "independent_refusals_atomic": inverse
                    || (execution.migrationRefused
                        && execution.householdRefused
                        && execution.refusalMutationCount == 0
                        && execution.refusalOrdinalsExact),
            ]
        )
        gateFE12A7Write(report, to: reportURL)
        check("Attack 07 \(prefix) restore owns cleanup exactly once",
              report.assertions.values.allSatisfy { $0 })
        return true
    }

    let checkpointBytes = try! Data(contentsOf: finalCheckpointURL)
    let durableBytes = try! Data(contentsOf: finalDurableURL)
    let previous = try! JSONDecoder().decode(
        GateFE12A7Report.self,
        from: Data(contentsOf: root.appendingPathComponent(
            "\(prefix)-restore-finalize_report.json"
        ))
    )
    let checkpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self, from: checkpointBytes
    )
    let session = try! AgentSimulationSession.restoring(checkpoint)
    let deathsBefore = session.mortalitySnapshot().totalDeathCount
    let estatesBefore = session.estateSnapshot().totalEstateCount
    let report = gateFE12A7Report(
        phase: phase, scenario: scenario, session: session,
        causal: previous.causal, expectedStage: "final",
        migrationRefused: previous.migrationRefused,
        householdRefused: previous.householdRefused,
        refusalMutationCount: previous.refusalMutationCount,
        replayedDeaths: session.mortalitySnapshot().totalDeathCount
            - deathsBefore,
        replayedEstates: session.estateSnapshot().totalEstateCount
            - estatesBefore,
        extraAssertions: [
            "final_checkpoint_reencodes_exactly":
                (try? AgentCheckpointCodec.encode(checkpoint))
                    == checkpointBytes,
            "final_durable_restores_exactly":
                (try? session.durableStateBytes()) == durableBytes,
            "final_authority_matches_previous":
                gateFE12A7Authority(session) == previous.authority,
        ]
    )
    gateFE12A7Write(report, to: reportURL)
    check("Attack 07 \(prefix) final reader sees no replay or resurrection",
          report.assertions.values.allSatisfy { $0 })
    return true
}

func runPebbleAgentsGateFEvaluation12Attack07Smoke() {
    if gateFE12A7FreshIfRequested() { return }
    let forwardSeed = gateFE12A7BuildSeed(
        "gate-f-e12-a7-focused-forward", inverse: false
    )
    let inverseSeed = gateFE12A7BuildSeed(
        "gate-f-e12-a7-focused-inverse", inverse: true
    )
    let forward = gateFE12A7Execute(
        forwardSeed, requireRefusals: true, suffix: "focused-forward"
    )
    let inverse = gateFE12A7Execute(
        inverseSeed, requireRefusals: false, suffix: "focused-inverse"
    )
    let forwardReport = gateFE12A7Report(
        phase: "focused-forward", scenario: forwardSeed.scenario,
        session: forward.session, causal: forward.causal,
        expectedStage: "final",
        migrationRefused: forward.migrationRefused,
        householdRefused: forward.householdRefused,
        refusalMutationCount: forward.refusalMutationCount,
        extraAssertions: [
            "independent_refusals_atomic": forward.migrationRefused
                && forward.householdRefused
                && forward.refusalMutationCount == 0
                && forward.refusalOrdinalsExact,
        ]
    )
    let inverseReport = gateFE12A7Report(
        phase: "focused-inverse", scenario: inverseSeed.scenario,
        session: inverse.session, causal: inverse.causal,
        expectedStage: "final"
    )
    section("Gate F Evaluation 12 Attack 07 — restart terminal composition")
    for key in forwardReport.assertions.keys.sorted() {
        check("Attack 07 forward \(key)", forwardReport.assertions[key]!)
    }
    for key in inverseReport.assertions.keys.sorted() {
        check("Attack 07 inverse \(key)", inverseReport.assertions[key]!)
    }
    print(
        "GATE_F_E12_ATTACK_07_FORWARD "
            + forwardReport.causal.keys.sorted().map {
                "\($0)=\(forwardReport.causal[$0]!)"
            }.joined(separator: " ")
    )
    print(
        "GATE_F_E12_ATTACK_07_INVERSE "
            + inverseReport.causal.keys.sorted().map {
                "\($0)=\(inverseReport.causal[$0]!)"
            }.joined(separator: " ")
    )
    print(
        "GATE_F_E12_ATTACK_07_REFUSAL migration="
            + "\(forwardReport.migrationRefused ? 1 : 0) household="
            + "\(forwardReport.householdRefused ? 1 : 0) mutations="
            + "\(forwardReport.refusalMutationCount)"
    )
    print(
        "GATE_F_E12_ATTACK_07_DIGEST forward="
            + "\(forwardReport.checkpointSHA256)/\(forwardReport.durableSHA256) "
            + "inverse=\(inverseReport.checkpointSHA256)/"
            + "\(inverseReport.durableSHA256) schema=35 observer=13"
    )
}
