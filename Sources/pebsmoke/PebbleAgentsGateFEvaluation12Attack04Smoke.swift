import Foundation
import PebbleAgents
import PebbleCore

private let gateFE12A4Actor = AgentID(rawValue: "agent_0")!
private let gateFE12A4Peer1 = AgentID(rawValue: "agent_1")!
private let gateFE12A4Peer2 = AgentID(rawValue: "agent_2")!
private let gateFE12A4Main = AgentPosition(x: 0, y: 64, z: 0)
private let gateFE12A4East = AgentPosition(x: 1, y: 64, z: 0)
private let gateFE12A4EastID = AgentSettlementID(rawValue: "settlement-east")!

private func gateFE12A4Founder(_ ordinal: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: 0, y: 64, z: ordinal * 2)
    return AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0.1, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "Gate F Evaluation 12 Attack 04",
            startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0,
        survivalProgress: AgentSurvivalProgress()
    )
}

private func gateFE12A4Base(_ simulationID: String) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 1_234, nearbyRadius: 8, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 64)
        ),
        agents: (0..<3).map(gateFE12A4Founder),
        simulationID: try! AgentSimulationID(validating: simulationID),
        causalLedgerPolicy: .bounded(maxEvents: 512)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: gateFE12A4Main,
        receptionPosition: AgentPosition(x: 0, y: 64, z: 6),
        configuration: try! AgentPopulationConfiguration(
            maximumActivePopulation: 6, maximumMigrationRecords: 8
        )
    )
    try! session.setLifecycleEnabled(true)
    try! session.setKinshipEnabled(true)
    try! session.setHouseholdsEnabled(
        true,
        configuration: try! AgentHouseholdConfiguration(
            maximumHistoricalHouseholds: 4,
            maximumMembershipPeriods: 16,
            maximumActiveHouseholds: 4,
            maximumMembersPerHousehold: 4,
            maximumHouseholdTransitionsPerTick: 16
        )
    )
    try! session.initializePopulationScaling(
        additionalSettlements: [AgentPopulationSettlement(
            settlementID: gateFE12A4EastID,
            anchor: gateFE12A4East,
            receptionPosition: gateFE12A4East,
            capacity: 3, residentIDs: [], inTransitIDs: []
        )],
        configuration: try! AgentPopulationScaleConfiguration(
            maximumSettlements: 2, maximumLiveAgents: 3,
            maximumNearAgents: 1, nearMaintenanceCadence: 2,
            dormantMaintenanceCadence: 8, rotationIntervalTicks: 4,
            maximumFidelityTransitionHistory: 16,
            maximumSettlementMigrationHistory: 8,
            maximumConcurrentSettlementMigrations: 1,
            maximumSettlementMigrationRouteLength: 8
        )
    )
    return session
}

private func gateFE12A4Begin(_ session: inout AgentSimulationSession) throws {
    _ = try session.beginSettlementMigration(
        agentID: gateFE12A4Actor,
        destinationSettlementID: gateFE12A4EastID,
        verifiedRoute: [gateFE12A4Main, gateFE12A4East]
    )
}

private func gateFE12A4ConsumeLastHouseholdIdentity(
    _ session: inout AgentSimulationSession
) throws {
    _ = try session.formHousehold(
        memberIDs: [gateFE12A4Peer1, gateFE12A4Peer2],
        residenceAnchor: AgentPosition(x: 0, y: 64, z: 3)
    )
}

private func gateFE12A4LateState(_ simulationID: String) -> AgentSimulationSession {
    var session = gateFE12A4Base(simulationID)
    try! gateFE12A4Begin(&session)
    try! gateFE12A4ConsumeLastHouseholdIdentity(&session)
    return session
}

private func gateFE12A4Column(
    _ position: AgentPosition
) -> AgentWorldColumnObservation {
    AgentWorldColumnObservation(
        position: position, chunkReady: true, surfaceY: position.y,
        height: position.y, blockBelow: 1, blockAtFeet: 0,
        blockAtHead: 0, groundPresent: true, feetClear: true, headClear: true
    )
}

private func gateFE12A4Perception(
    _ session: AgentSimulationSession
) -> AgentPerceptionInput {
    let migration = session.populationScaleSnapshot().settlementMigrations.first!
    let state = try! session.state(for: gateFE12A4Actor)
    return AgentPerceptionInput(
        agentId: gateFE12A4Actor.rawValue,
        worldObservation: try! AgentWorldObservation(
            worldTick: session.tick + 1, position: state.position,
            center: gateFE12A4Column(state.position),
            neighbors: AgentCardinalDirection.allCases.map { direction in
                let target = AgentPosition(
                    x: state.position.x + direction.dx, y: state.position.y,
                    z: state.position.z + direction.dz
                )
                return AgentWorldNeighborObservation(
                    direction: direction, column: gateFE12A4Column(target),
                    stepDelta: 0, traversable: true, dangerousDrop: false
                )
            },
            biomeId: 1, biomeName: "plains", combinedLight: 15,
            skyLight: 15, blockLight: 0, dayTime: 6_000,
            raining: false, thundering: false
        ),
        navigationObservation: AgentNavigationObservation(
            worldTick: session.tick + 1, origin: state.position,
            target: migration.route.last!, radius: 8,
            cells: migration.route.map {
                AgentNavigationCell(position: $0, status: .traversable)
            }
        )
    )
}

private struct GateFE12A4PhysicalBoundary {
    let accepted: Bool
    let refusal: String?
    let physicalReachedCandidate: Bool
    let physicalRestored: Bool
    let physicalBefore: String
    let physicalAfter: String
    let worldEntityIDsBefore: [String]
    let worldEntityIDsAfter: [String]
}

private func gateFE12A4World(
    _ session: AgentSimulationSession
) -> (World, [String: LabCoreAgentEntity]) {
    let world = World(dim: .overworld, seed: 1_234)
    for chunkZ in -1...1 {
        for chunkX in -1...1 {
            let chunk = Chunk(
                cx: chunkX, cz: chunkZ,
                minY: world.info.minY, height: world.info.height
            )
            chunk.buildHeightmap()
            chunk.status = .lit
            world.setChunk(chunk)
        }
    }
    for x in -8...8 {
        for z in -8...8 {
            world.setBlock(x, 63, z, Int(cell(B.stone)), SET_SILENT)
        }
    }
    var probes: [String: LabCoreAgentEntity] = [:]
    for state in session.snapshot().agents.sorted(by: { $0.id < $1.id }) {
        let probe = LabCoreAgentEntity(
            world: world, labAgentId: state.id,
            physicalId: "gate-f-e12-a4:\(state.id)"
        )
        probe.setPos(
            Double(state.position.x) + 0.5, Double(state.position.y),
            Double(state.position.z) + 0.5
        )
        world.addEntity(probe)
        probes[state.id] = probe
    }
    return (world, probes)
}

private func gateFE12A4ExecutePhysicalBoundary(
    published: inout AgentSimulationSession
) -> GateFE12A4PhysicalBoundary {
    let publishedBytes = try! published.durableStateBytes()
    let (world, probes) = gateFE12A4World(published)
    let probe = probes[gateFE12A4Actor.rawValue]!
    let physicalBefore = probe.capturePhysicalState()
    let worldIDsBefore = world.entities.compactMap {
        ($0 as? LabCoreAgentEntity)?.labAgentId
    }.sorted()
    var candidate = published
    _ = try! candidate.advanceTick(perceptions: [gateFE12A4Perception(candidate)])
    let outcomes = AgentMovementCoordinator.resolve(snapshot: candidate.snapshot())
    let actor = outcomes.first { $0.agentId == gateFE12A4Actor.rawValue }!
    precondition(actor.status == .moved)
    let path = findPath(
        world, probe.x, probe.y, probe.z,
        Double(actor.toPosition.x) + 0.5, Double(actor.toPosition.y),
        Double(actor.toPosition.z) + 0.5, 600, true
    )
    precondition(
        path?.first != nil,
        "Core path missing probe=\(probe.x),\(probe.y),\(probe.z) "
            + "outcome=\(actor.fromPosition)>\(actor.toPosition) "
            + "below=\(world.getBlock(actor.toPosition.x, actor.toPosition.y - 1, actor.toPosition.z)) "
            + "feet=\(world.getBlock(actor.toPosition.x, actor.toPosition.y, actor.toPosition.z)) "
            + "head=\(world.getBlock(actor.toPosition.x, actor.toPosition.y + 1, actor.toPosition.z))"
    )
    let node = path!.first!
    probe.move(
        Double(node.x) + 0.5 - probe.x,
        Double(node.y) - probe.y,
        Double(node.z) + 0.5 - probe.z
    )
    let candidateReached = Int(probe.x.rounded(.down)) == actor.toPosition.x
        && Int(probe.y.rounded(.down)) == actor.toPosition.y
        && Int(probe.z.rounded(.down)) == actor.toPosition.z
    do {
        try candidate.applyVerifiedPhysicalMovements(outcomes.map {
            AgentVerifiedPhysicalMovement(kind: .navigationStep, outcome: $0)
        })
        published = candidate
        let after = probe.capturePhysicalState()
        return GateFE12A4PhysicalBoundary(
            accepted: true, refusal: nil,
            physicalReachedCandidate: candidateReached,
            physicalRestored: false,
            physicalBefore: String(describing: physicalBefore),
            physicalAfter: String(describing: after),
            worldEntityIDsBefore: worldIDsBefore,
            worldEntityIDsAfter: world.entities.compactMap {
                ($0 as? LabCoreAgentEntity)?.labAgentId
            }.sorted()
        )
    } catch {
        let restored = probe.restorePhysicalState(physicalBefore)
            && probe.capturePhysicalState() == physicalBefore
            && (try! published.durableStateBytes()) == publishedBytes
        return GateFE12A4PhysicalBoundary(
            accepted: false, refusal: String(describing: error),
            physicalReachedCandidate: candidateReached,
            physicalRestored: restored,
            physicalBefore: String(describing: physicalBefore),
            physicalAfter: String(describing: probe.capturePhysicalState()),
            worldEntityIDsBefore: worldIDsBefore,
            worldEntityIDsAfter: world.entities.compactMap {
                ($0 as? LabCoreAgentEntity)?.labAgentId
            }.sorted()
        )
    }
}

private struct GateFE12A4Report: Codable, Equatable {
    let phase: String
    let tick: Int
    let checkpointSchema: Int
    let observerSchema: Int
    let checkpointSHA256: String
    let durableSHA256: String
    let migrationStatus: String
    let migrationStartSequence: UInt64
    let householdConsumptionSequence: UInt64?
    let arrivalSequence: UInt64?
    let actorResidentCount: Int
    let actorTransitCount: Int
    let householdCount: Int
    let membershipPeriodCount: Int
    let nextHouseholdOrdinal: Int
    let nextMigrationOrdinal: UInt64
    let arrivalCount: Int
    let movementCount: Int
    let refusal: String?
    let physicalReachedCandidate: Bool
    let physicalRestored: Bool
    let physicalBefore: String
    let physicalAfter: String
    let worldEntityIDsBefore: [String]
    let worldEntityIDsAfter: [String]
    let assertions: [String: Bool]
}

private func gateFE12A4Report(
    phase: String,
    session: inout AgentSimulationSession,
    boundary: GateFE12A4PhysicalBoundary?,
    expected: String,
    observerSchema: Int = 13,
    observerMutationCount: Int = 0
) -> GateFE12A4Report {
    let checkpoint = try! session.makeCheckpoint()
    let checkpointBytes = try! AgentCheckpointCodec.encode(checkpoint)
    let durableBytes = try! session.durableStateBytes()
    let scale = session.populationScaleSnapshot()
    let durableScale = session.durableState().populationRegistry!.scaleState!
    let migration = scale.settlementMigrations.first!
    let households = session.householdSnapshot()
    let population = session.populationSnapshot()
    let actorResidentCount = population.settlements.filter {
        $0.residentIDs.contains(gateFE12A4Actor)
    }.count
    let actorTransitCount = population.settlements.filter {
        $0.inTransitIDs.contains(gateFE12A4Actor)
    }.count
    let events = session.causalLedgerSnapshot().events
    let formation = events.last {
        $0.kind == .householdCreated
            && $0.eventID.sequence.rawValue > migration.startedEventID.sequence.rawValue
    }
    let arrival = events.last {
        $0.kind == .settlementMigrationArrived
            && $0.actorID == gateFE12A4Actor
    }
    var assertions: [String: Bool] = [
        "checkpoint_schema_35": checkpoint.schemaVersion == 35,
        "observer_schema_13_read_only": observerSchema == 13
            && observerMutationCount == 0,
        "identity_ordinals_monotone": households.nextHouseholdOrdinal
            == households.totalHistoricalHouseholdCount
            && durableScale.nextSettlementMigrationOrdinal == 2,
        "single_current_authority": actorResidentCount + actorTransitCount == 1,
        "world_entity_set_stable": boundary.map {
            $0.worldEntityIDsBefore == $0.worldEntityIDsAfter
                && Set($0.worldEntityIDsAfter).count == 3
        } ?? true,
    ]
    if expected == "pre-boundary" {
        assertions["late_refusal_state_is_reachable"] = migration.status == .inTransit
            && households.households.count == 4
            && households.nextHouseholdOrdinal == 4
            && formation != nil && actorResidentCount == 0
            && actorTransitCount == 1 && arrival == nil
    } else if expected == "refused" {
        assertions["real_physical_candidate_reached_then_restored"] =
            boundary?.accepted == false
                && boundary?.physicalReachedCandidate == true
                && boundary?.physicalRestored == true
                && boundary?.physicalBefore == boundary?.physicalAfter
        assertions["civilization_refusal_is_household_capacity"] =
            boundary?.refusal?.contains("historical household capacity reached") == true
        assertions["refusal_publishes_nothing"] = migration.status == .inTransit
            && actorResidentCount == 0 && actorTransitCount == 1
            && arrival == nil && session.snapshot().agents.first {
                $0.id == gateFE12A4Actor.rawValue
            }?.movementCount == 0
            && households.nextHouseholdOrdinal == 4
    } else if expected == "accepted" {
        assertions["control_arrival_commits_both_authorities"] =
            boundary?.accepted == true
                && boundary?.physicalReachedCandidate == true
                && migration.status == .arrived
                && actorResidentCount == 1 && actorTransitCount == 0
                && arrival != nil && households.nextHouseholdOrdinal == 4
    }
    return GateFE12A4Report(
        phase: phase, tick: session.tick,
        checkpointSchema: checkpoint.schemaVersion,
        observerSchema: observerSchema,
        checkpointSHA256: AgentCheckpointDigest.sha256(checkpointBytes).rawValue,
        durableSHA256: AgentCheckpointDigest.sha256(durableBytes).rawValue,
        migrationStatus: migration.status.rawValue,
        migrationStartSequence: migration.startedEventID.sequence.rawValue,
        householdConsumptionSequence: formation?.eventID.sequence.rawValue,
        arrivalSequence: arrival?.eventID.sequence.rawValue,
        actorResidentCount: actorResidentCount,
        actorTransitCount: actorTransitCount,
        householdCount: households.households.count,
        membershipPeriodCount: households.membershipPeriods.count,
        nextHouseholdOrdinal: households.nextHouseholdOrdinal!,
        nextMigrationOrdinal: durableScale.nextSettlementMigrationOrdinal,
        arrivalCount: events.filter {
            $0.kind == .settlementMigrationArrived
                && $0.actorID == gateFE12A4Actor
        }.count,
        movementCount: session.snapshot().agents.first {
            $0.id == gateFE12A4Actor.rawValue
        }!.movementCount,
        refusal: boundary?.refusal,
        physicalReachedCandidate: boundary?.physicalReachedCandidate ?? false,
        physicalRestored: boundary?.physicalRestored ?? false,
        physicalBefore: boundary?.physicalBefore ?? "not-run",
        physicalAfter: boundary?.physicalAfter ?? "not-run",
        worldEntityIDsBefore: boundary?.worldEntityIDsBefore ?? [],
        worldEntityIDsAfter: boundary?.worldEntityIDsAfter ?? [],
        assertions: assertions
    )
}

private func gateFE12A4Write<T: Encodable>(_ value: T, to url: URL) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    try! encoder.encode(value).write(to: url, options: .atomic)
}

private func gateFE12A4FreshIfRequested() -> Bool {
    let environment = ProcessInfo.processInfo.environment
    guard let phase = environment["PEBBLELAB_GATE_F_E12_A4_PHASE"] else {
        return false
    }
    guard ["write", "restore-refuse", "restore-verify"].contains(phase),
          let output = environment["PEBBLELAB_GATE_F_E12_A4_OUT"] else {
        preconditionFailure("invalid Evaluation 12 Attack 04 environment")
    }
    let root = URL(fileURLWithPath: output, isDirectory: true)
    try! FileManager.default.createDirectory(
        at: root, withIntermediateDirectories: true
    )
    let beforeCheckpoint = root.appendingPathComponent("before_checkpoint_v35.json")
    let beforeDurable = root.appendingPathComponent("before_durable_state.json")
    let afterCheckpoint = root.appendingPathComponent("after_checkpoint_v35.json")
    let afterDurable = root.appendingPathComponent("after_durable_state.json")
    if phase == "write" {
        var session = gateFE12A4LateState("gate-f-e12-a4-fresh")
        let report = gateFE12A4Report(
            phase: phase, session: &session, boundary: nil,
            expected: "pre-boundary"
        )
        try! AgentCheckpointCodec.encode(session.makeCheckpoint())
            .write(to: beforeCheckpoint, options: .atomic)
        try! session.durableStateBytes().write(to: beforeDurable, options: .atomic)
        gateFE12A4Write(report, to: root.appendingPathComponent("process_1_report.json"))
        check("Attack 04 writer checkpoints reachable late-refusal authority",
              report.assertions.values.allSatisfy { $0 })
        return true
    }
    let initialBytes = try! Data(contentsOf: beforeCheckpoint)
    let initialDurable = try! Data(contentsOf: beforeDurable)
    let checkpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self, from: initialBytes
    )
    var session = try! AgentSimulationSession.restoring(checkpoint)
    if phase == "restore-refuse" {
        let restored = try! session.durableStateBytes()
        let observerBefore = restored
        let observer = session.observerSnapshot(worldBinding:
            try! AgentObserverWorldBinding(
                worldID: "gate-f-e12-a4-world",
                storageIdentity: "memory:gate-f-e12-a4", seed: 1_234,
                dimension: 0, observedWorldTick: session.tick
            )
        )
        let observerMutation = (try! session.durableStateBytes()) == observerBefore ? 0 : 1
        let boundary = gateFE12A4ExecutePhysicalBoundary(published: &session)
        var report = gateFE12A4Report(
            phase: phase, session: &session, boundary: boundary,
            expected: "refused", observerSchema: observer.header.schemaVersion,
            observerMutationCount: observerMutation
        )
        var assertions = report.assertions
        assertions["initial_checkpoint_reencodes_exactly"] =
            (try? AgentCheckpointCodec.encode(checkpoint)) == initialBytes
        assertions["initial_durable_restores_exactly"] = restored == initialDurable
        assertions["refusal_restores_exact_durable_truth"] =
            (try! session.durableStateBytes()) == initialDurable
        report = GateFE12A4Report(
            phase: report.phase, tick: report.tick,
            checkpointSchema: report.checkpointSchema,
            observerSchema: report.observerSchema,
            checkpointSHA256: report.checkpointSHA256,
            durableSHA256: report.durableSHA256,
            migrationStatus: report.migrationStatus,
            migrationStartSequence: report.migrationStartSequence,
            householdConsumptionSequence: report.householdConsumptionSequence,
            arrivalSequence: report.arrivalSequence,
            actorResidentCount: report.actorResidentCount,
            actorTransitCount: report.actorTransitCount,
            householdCount: report.householdCount,
            membershipPeriodCount: report.membershipPeriodCount,
            nextHouseholdOrdinal: report.nextHouseholdOrdinal,
            nextMigrationOrdinal: report.nextMigrationOrdinal,
            arrivalCount: report.arrivalCount,
            movementCount: report.movementCount,
            refusal: report.refusal,
            physicalReachedCandidate: report.physicalReachedCandidate,
            physicalRestored: report.physicalRestored,
            physicalBefore: report.physicalBefore,
            physicalAfter: report.physicalAfter,
            worldEntityIDsBefore: report.worldEntityIDsBefore,
            worldEntityIDsAfter: report.worldEntityIDsAfter,
            assertions: assertions
        )
        try! AgentCheckpointCodec.encode(session.makeCheckpoint())
            .write(to: afterCheckpoint, options: .atomic)
        try! session.durableStateBytes().write(to: afterDurable, options: .atomic)
        gateFE12A4Write(report, to: root.appendingPathComponent("process_2_report.json"))
        check("Attack 04 fresh physical arrival refusal rolls back exactly",
              report.assertions.values.allSatisfy { $0 })
        return true
    }
    let refusedBytes = try! Data(contentsOf: afterCheckpoint)
    let refusedDurable = try! Data(contentsOf: afterDurable)
    let refusedCheckpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self, from: refusedBytes
    )
    session = try! AgentSimulationSession.restoring(refusedCheckpoint)
    var report = gateFE12A4Report(
        phase: phase, session: &session, boundary: nil,
        expected: "pre-boundary"
    )
    var assertions = report.assertions
    assertions["post_refusal_checkpoint_reencodes_exactly"] =
        (try? AgentCheckpointCodec.encode(refusedCheckpoint)) == refusedBytes
    assertions["post_refusal_durable_restores_exactly"] =
        (try! session.durableStateBytes()) == refusedDurable
    assertions["refusal_checkpoint_equals_pre_transaction"] =
        refusedBytes == initialBytes && refusedDurable == initialDurable
    assertions["no_arrival_or_movement_replay"] =
        report.arrivalCount == 0 && report.movementCount == 0
    report = GateFE12A4Report(
        phase: report.phase, tick: report.tick,
        checkpointSchema: report.checkpointSchema,
        observerSchema: report.observerSchema,
        checkpointSHA256: report.checkpointSHA256,
        durableSHA256: report.durableSHA256,
        migrationStatus: report.migrationStatus,
        migrationStartSequence: report.migrationStartSequence,
        householdConsumptionSequence: report.householdConsumptionSequence,
        arrivalSequence: report.arrivalSequence,
        actorResidentCount: report.actorResidentCount,
        actorTransitCount: report.actorTransitCount,
        householdCount: report.householdCount,
        membershipPeriodCount: report.membershipPeriodCount,
        nextHouseholdOrdinal: report.nextHouseholdOrdinal,
        nextMigrationOrdinal: report.nextMigrationOrdinal,
        arrivalCount: report.arrivalCount,
        movementCount: report.movementCount,
        refusal: report.refusal,
        physicalReachedCandidate: report.physicalReachedCandidate,
        physicalRestored: report.physicalRestored,
        physicalBefore: report.physicalBefore,
        physicalAfter: report.physicalAfter,
        worldEntityIDsBefore: report.worldEntityIDsBefore,
        worldEntityIDsAfter: report.worldEntityIDsAfter,
        assertions: assertions
    )
    gateFE12A4Write(report, to: root.appendingPathComponent("process_3_report.json"))
    check("Attack 04 final reader preserves pre-transaction truth",
          report.assertions.values.allSatisfy { $0 })
    return true
}

func runPebbleAgentsGateFEvaluation12Attack04Smoke() {
    if gateFE12A4FreshIfRequested() { return }
    section("Gate F Evaluation 12 Attack 04 — physical/civilization atomicity")

    var early = gateFE12A4Base("gate-f-e12-a4-early")
    try! gateFE12A4ConsumeLastHouseholdIdentity(&early)
    let earlyBytes = try! early.durableStateBytes()
    let earlyHouseholds = early.householdSnapshot()
    let earlyScale = early.populationScaleSnapshot()
    var earlyRefused = false
    do {
        try gateFE12A4Begin(&early)
    } catch AgentSessionError.household(.householdCapacityReached) {
        earlyRefused = true
    } catch {}
    check("Attack 04 prevalidation refusal occurs before physical candidate",
          earlyRefused && (try! early.durableStateBytes()) == earlyBytes)
    check("Attack 04 prevalidation refusal consumes no identity or ordinal",
          early.householdSnapshot() == earlyHouseholds
            && early.populationScaleSnapshot() == earlyScale)

    var late = gateFE12A4LateState("gate-f-e12-a4-late")
    let lateBytes = try! late.durableStateBytes()
    let lateHouseholds = late.householdSnapshot()
    let lateScale = late.populationScaleSnapshot()
    let lateBoundary = gateFE12A4ExecutePhysicalBoundary(published: &late)
    let lateReport = gateFE12A4Report(
        phase: "focused-late", session: &late, boundary: lateBoundary,
        expected: "refused"
    )
    for key in lateReport.assertions.keys.sorted() {
        check("Attack 04 late \(key)", lateReport.assertions[key]!)
    }
    check("Attack 04 late refusal leaves session bytes exact",
          (try! late.durableStateBytes()) == lateBytes)
    check("Attack 04 late refusal consumes no identity or ordinal",
          late.householdSnapshot() == lateHouseholds
            && late.populationScaleSnapshot() == lateScale)

    var control = gateFE12A4Base("gate-f-e12-a4-control")
    try! gateFE12A4Begin(&control)
    let controlBoundary = gateFE12A4ExecutePhysicalBoundary(published: &control)
    let controlReport = gateFE12A4Report(
        phase: "focused-control", session: &control,
        boundary: controlBoundary, expected: "accepted"
    )
    for key in controlReport.assertions.keys.sorted() {
        check("Attack 04 control \(key)", controlReport.assertions[key]!)
    }

    print(
        "GATE_F_E12_ATTACK_04_CAUSAL migration="
            + "\(lateReport.migrationStartSequence) household="
            + "\(lateReport.householdConsumptionSequence ?? 0) "
            + "refusedArrival=none controlArrival="
            + "\(controlReport.arrivalSequence ?? 0)"
    )
    print(
        "GATE_F_E12_ATTACK_04_AUTHORITY late=\(lateReport.migrationStatus) "
            + "resident=\(lateReport.actorResidentCount) "
            + "transit=\(lateReport.actorTransitCount) "
            + "physicalCandidate=\(lateReport.physicalReachedCandidate ? 1 : 0) "
            + "rollback=\(lateReport.physicalRestored ? 1 : 0)"
    )
    print(
        "GATE_F_E12_ATTACK_04_IDENTITY household="
            + "\(lateReport.householdCount)/next\(lateReport.nextHouseholdOrdinal) "
            + "periods=\(lateReport.membershipPeriodCount) migrationNext="
            + "\(lateReport.nextMigrationOrdinal) arrivals="
            + "\(lateReport.arrivalCount) moves=\(lateReport.movementCount)"
    )
    print(
        "GATE_F_E12_ATTACK_04_DIGEST checkpoint="
            + "\(lateReport.checkpointSHA256) durable="
            + "\(lateReport.durableSHA256) schema="
            + "\(lateReport.checkpointSchema) observer="
            + "\(lateReport.observerSchema)"
    )
}
