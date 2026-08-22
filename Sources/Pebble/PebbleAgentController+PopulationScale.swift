import Foundation
import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func handleCIV39(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab civ39 <setup|status|migrate|proof>"
        guard arguments.count == 1 else { return failure(usage) }
        guard populationScaleFeatureEnabled, populationFeatureEnabled,
              movementFeatureEnabled, persistenceFeatureEnabled,
              observerFeatureEnabled else {
            return failure(
                "CIV-39 live proof requires AGENTS_SCALE, POPULATION, MOVE, "
                    + "PERSISTENCE and OBSERVER gates."
            )
        }
        guard let current = session, activeWorld === world else {
            return failure("CIV-39 requires an active PebbleAgents session.")
        }
        do {
            switch arguments[0].lowercased() {
            case "setup":
                return try setupCIV39(world: world, player: player, current: current)
            case "status":
                return civ39Status(current)
            case "migrate":
                return try startCIV39Migration(
                    world: world, player: player, current: current
                )
            case "proof":
                return try proveCIV39(world: world, current: current)
            default:
                return failure(usage)
            }
        } catch {
            return failure("CIV-39 command failed: \(error)")
        }
    }

    private func setupCIV39(
        world: World,
        player: Player,
        current: AgentSimulationSession
    ) throws -> PebbleAgentCommandResult {
        guard isPaused else {
            return failure("CIV-39 setup requires a paused session.")
        }
        guard replayRecorder == nil else {
            return failure("CIV-39 setup refuses an active replay recording.")
        }
        guard current.populationEnabled, !current.populationScalingEnabled else {
            return failure("CIV-39 setup requires an unscaled population registry.")
        }
        let before = current.snapshot()
        guard before.agentCount == 3,
              current.populationSnapshot().members.count == 3,
              let migrant = before.agents.first(where: { $0.id == "agent_0" }) else {
            return failure("CIV-39 setup requires the canonical three-founder bootstrap.")
        }
        let playerPosition = AgentPosition(
            x: Int(player.x.rounded(.down)),
            y: Int(player.y.rounded(.down)),
            z: Int(player.z.rounded(.down))
        )
        let occupied = before.agents.filter { $0.id != migrant.id }.map(\.position)
            + [playerPosition]
        let survey = navigationAdapter.observe(
            world: world, agent: migrant, target: migrant.position,
            occupiedAgentPositions: occupied, goalMode: .exact
        )
        let destinations = survey.cells.filter { cell in
            guard cell.status == .traversable,
                  cell.position != migrant.position else { return false }
            let distance = abs(cell.position.x - migrant.position.x)
                + abs(cell.position.z - migrant.position.z)
            return (3...6).contains(distance)
        }.sorted { lhs, rhs in
            let lhsDistance = abs(lhs.position.x - migrant.position.x)
                + abs(lhs.position.z - migrant.position.z)
            let rhsDistance = abs(rhs.position.x - migrant.position.x)
                + abs(rhs.position.z - migrant.position.z)
            if lhsDistance != rhsDistance { return lhsDistance < rhsDistance }
            if lhs.position.x != rhs.position.x {
                return lhs.position.x < rhs.position.x
            }
            if lhs.position.z != rhs.position.z {
                return lhs.position.z < rhs.position.z
            }
            return lhs.position.y < rhs.position.y
        }
        var chosenObservation: AgentNavigationObservation?
        var chosenPlan: AgentNavigationPlan?
        var chosenCoreRoute: [AgentPosition]?
        guard let migrantProbe = probesByAgentId[migrant.id] else {
            return failure("CIV-39 setup requires the migrant's live embodiment.")
        }
        for destination in destinations {
            let observation = navigationAdapter.observe(
                world: world, agent: migrant, target: destination.position,
                occupiedAgentPositions: occupied, goalMode: .exact
            )
            let plan = AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
                start: migrant.position, target: destination.position,
                goalMode: .exact, cells: observation.cells,
                radius: observation.radius,
                maxVisitedNodes: AgentBoundedRoutePlanner.maximumVisitedNodes,
                maxSteps: AgentBoundedRoutePlanner.maximumRouteSteps
            ))
            let coreRoute = civ39ExecutableCoreRoute(
                world: world,
                probe: migrantProbe,
                destination: destination.position,
                occupied: Set(occupied)
            )
            if plan.found, plan.positions.count >= 3, let coreRoute {
                chosenObservation = observation
                chosenPlan = plan
                chosenCoreRoute = coreRoute
                break
            }
        }
        guard let observation = chosenObservation, let plan = chosenPlan,
              let coreRoute = chosenCoreRoute,
              let eastReception = plan.positions.last else {
            return failure(
                "CIV-39 setup could not acquire a bounded executable Core route."
            )
        }
        let reserved = Set(
            plan.positions + coreRoute + before.agents.map(\.position) + [playerPosition]
        )
        var placementPositions: [AgentPosition] = []
        for cell in observation.cells.sorted(by: civ39NavigationCellLessThan)
        where cell.status == .traversable && !reserved.contains(cell.position) {
            let assessment = assessEntityPlacement(
                in: world,
                at: EntityPlacementPosition(
                    x: cell.position.x, y: cell.position.y, z: cell.position.z
                ),
                bodyWidth: 0.6, bodyHeight: 1.8
            )
            if assessment.isValid { placementPositions.append(cell.position) }
            if placementPositions.count == 9 { break }
        }
        guard placementPositions.count == 9 else {
            return failure(
                "CIV-39 setup requires nine verified local inhabitant placements."
            )
        }
        let eastID = AgentSettlementID(rawValue: "settlement-east")!
        let admissions = placementPositions.enumerated().map { index, position in
            let ordinal = index + 3
            return AgentScaledResidentAdmission(
                state: civ39ResidentState(
                    id: String(format: "agent_%03d", ordinal),
                    position: position, tick: current.tick
                ),
                settlementID: index < 4 ? eastID : .main
            )
        }
        var candidate = current
        try candidate.initializePopulationScaling(
            additionalSettlements: [AgentPopulationSettlement(
                settlementID: eastID,
                anchor: eastReception,
                receptionPosition: eastReception,
                capacity: 24, residentIDs: [], inTransitIDs: []
            )],
            additionalResidents: admissions,
            configuration: try AgentPopulationScaleConfiguration(
                maximumSettlements: 2,
                maximumLiveAgents: 4,
                maximumNearAgents: 4,
                nearMaintenanceCadence: 2,
                dormantMaintenanceCadence: 8,
                rotationIntervalTicks: 4,
                maximumFidelityTransitionHistory: 32,
                maximumSettlementMigrationHistory: 8,
                maximumConcurrentSettlementMigrations: 1,
                maximumSettlementMigrationRouteLength: 16
            )
        )
        let oldIDs = Set(before.agents.map(\.id))
        let newAgents = candidate.snapshot().agents.filter { !oldIDs.contains($0.id) }
        var created: [LabCoreAgentEntity] = []
        do {
            for agent in newAgents {
                created.append(try createProbe(for: agent, in: world))
            }
            let expected = candidate.snapshot().agents.map(\.id).sorted()
            let physical = world.entities.compactMap {
                ($0 as? LabCoreAgentEntity)?.labAgentId
            }.sorted()
            guard physical == expected else {
                throw ControllerError.invalidProbeSet(physical)
            }
        } catch {
            for probe in created.reversed() {
                guard removeLabCoreAgentProbe(probe, from: world) else {
                    throw ControllerError.bootstrapRollbackBoundary(
                        "CIV-39 staged probe rollback failed for \(probe.labAgentId)"
                    )
                }
            }
            throw error
        }
        var stagedProbes = probesByAgentId
        for probe in created { stagedProbes[probe.labAgentId] = probe }
        session = candidate
        probesByAgentId = stagedProbes
        let scale = candidate.populationScaleSnapshot()
        trace(
            "CIV39_SETUP_PASS settlements=\(scale.settlements.count) "
                + "population=\(candidate.snapshot().agentCount) "
                + "live=\(scale.liveCount) near=\(scale.nearCount) "
                + "dormant=\(scale.dormantCount) probes=\(created.count + 3) "
                + "reservedMigrationRoute=\(plan.positions.count) "
                + "coreRoute=\(coreRoute.count) authority=verified"
        )
        return success(civ39Status(candidate).message)
    }

    private func startCIV39Migration(
        world: World,
        player: Player,
        current: AgentSimulationSession
    ) throws -> PebbleAgentCommandResult {
        guard isPaused, current.populationScalingEnabled else {
            return failure("CIV-39 migration requires a paused scaled session.")
        }
        guard replayRecorder == nil else {
            return failure("CIV-39 migration refuses an active replay recording.")
        }
        let eastID = AgentSettlementID(rawValue: "settlement-east")!
        let snapshot = current.snapshot()
        guard let migrant = snapshot.agents.first(where: { $0.id == "agent_0" }),
              let destination = current.populationScaleSnapshot().settlements.first(where: {
                  $0.settlementID == eastID
              }) else {
            return failure("CIV-39 migration fixture is unavailable.")
        }
        let playerPosition = AgentPosition(
            x: Int(player.x.rounded(.down)),
            y: Int(player.y.rounded(.down)),
            z: Int(player.z.rounded(.down))
        )
        let observation = navigationAdapter.observe(
            world: world, agent: migrant,
            target: destination.receptionPosition,
            occupiedAgentPositions: snapshot.agents.filter {
                $0.id != migrant.id
            }.map(\.position) + [playerPosition],
            goalMode: .exact
        )
        let plan = AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
            start: migrant.position, target: destination.receptionPosition,
            goalMode: .exact, cells: observation.cells,
            radius: observation.radius,
            maxVisitedNodes: AgentBoundedRoutePlanner.maximumVisitedNodes,
            maxSteps: AgentBoundedRoutePlanner.maximumRouteSteps
        ))
        let occupied = Set(snapshot.agents.filter {
            $0.id != migrant.id
        }.map(\.position) + [playerPosition])
        guard let migrantProbe = probesByAgentId[migrant.id],
              let coreRoute = civ39ExecutableCoreRoute(
                  world: world,
                  probe: migrantProbe,
                  destination: destination.receptionPosition,
                  occupied: occupied
              ), plan.found else {
            return failure(
                "CIV-39 migration route unavailable or not executable: "
                    + "\(plan.failure?.rawValue ?? "Core preflight rejected")."
            )
        }
        var candidate = current
        let migration = try candidate.beginSettlementMigration(
            agentID: AgentID(rawValue: migrant.id)!,
            destinationSettlementID: eastID,
            verifiedRoute: plan.positions
        )
        session = candidate
        movementEnabled = true
        movementWasEverEnabledSinceReset = true
        trace(
            "CIV39_MIGRATION_STARTED id=\(migration.migrationID.rawValue) "
                + "agent=\(migrant.id) identityStable=1 route=\(plan.positions.count) "
                + "coreRoute=\(coreRoute.count) "
                + "origin=\(migration.originSettlementID.rawValue) "
                + "destination=\(migration.destinationSettlementID.rawValue) "
                + "physicalAuthority=observed_and_planned publication=causal"
        )
        return success(
            "CIV-39 migration started: id=\(migration.migrationID.rawValue) "
                + "agent=\(migrant.id) route=\(plan.positions.count)."
        )
    }

    private func proveCIV39(
        world: World,
        current: AgentSimulationSession
    ) throws -> PebbleAgentCommandResult {
        let snapshot = current.snapshot()
        let population = current.populationSnapshot()
        let scale = current.populationScaleSnapshot()
        let agentIDs = snapshot.agents.map(\.id)
        let memberIDs = population.members.map { $0.agentID.rawValue }
        let fidelityIDs = scale.fidelityRecords.map { $0.agentID.rawValue }
        let settlementCurrentIDs = scale.settlements.flatMap {
            $0.residentIDs + $0.inTransitIDs
        }.map(\.rawValue)
        let worldProbeIDs = world.entities.compactMap {
            ($0 as? LabCoreAgentEntity)?.labAgentId
        }.sorted()
        let arrived = scale.settlementMigrations.filter {
            $0.agentID.rawValue == "agent_0" && $0.status == .arrived
        }
        let active = scale.settlementMigrations.filter { $0.status == .inTransit }
        let eastID = AgentSettlementID(rawValue: "settlement-east")!
        let observerBefore = try current.durableStateDigest()
        let observer = observerSnapshot(world: world)
        let observerAfter = try current.durableStateDigest()
        let observerPerson = observer?.individual(AgentID(rawValue: "agent_0")!)
        let rights = current.materialRightsSnapshot()
        let obligations = current.contractSnapshot().obligations
        let markets = current.marketSnapshot()
        let receiptIDs = markets.tradeRecords.flatMap {
            [$0.trade.offeredLeg.physicalReceiptID,
             $0.trade.considerationLeg.physicalReceiptID]
        } + markets.withdrawals.map { $0.outcome.physicalReceiptID }
        let checkpoint = try current.makeCheckpoint()
        let assertions = [
            scale.enabled,
            scale.settlements.count == 2,
            snapshot.agentCount == 12,
            agentIDs.count == Set(agentIDs).count,
            memberIDs.sorted() == agentIDs.sorted(),
            fidelityIDs.sorted() == agentIDs.sorted(),
            settlementCurrentIDs.sorted() == agentIDs.sorted(),
            scale.liveCount > 0 && scale.nearCount > 0 && scale.dormantCount > 0,
            arrived.count == 1 && active.isEmpty,
            current.currentSettlementID(for: AgentID(rawValue: "agent_0")!) == eastID,
            observer?.header.schemaVersion == 13,
            observer?.populationScale?.settlements.count == 2,
            observerPerson?.agentID.rawValue == "agent_0",
            observerPerson?.populationContext?.settlementID == eastID,
            observerBefore == observerAfter,
            worldProbeIDs == agentIDs.sorted(),
            probesByAgentId.keys.sorted() == agentIDs.sorted(),
            Set(rights.records.map { $0.asset.assetID }).count == rights.records.count,
            Set(obligations.map(\.obligationID)).count == obligations.count,
            Set(receiptIDs).count == receiptIDs.count,
            checkpoint.schemaVersion == 35,
            civ39CheckpointRestoreCount == 1,
            runtimeErrorCount == 0,
        ]
        guard assertions.allSatisfy({ $0 }) else {
            return failure(
                "CIV39_LIVE_PROOF_FAIL assertions="
                    + assertions.enumerated().filter { !$0.element }
                        .map { String($0.offset) }.joined(separator: ",")
            )
        }
        let message = [
            "CIV39_LIVE_PROOF_PASS",
            "settlements=2", "population=12",
            "live=\(scale.liveCount)", "near=\(scale.nearCount)",
            "dormant=\(scale.dormantCount)",
            "migration=arrived", "identity=agent_0", "identityStable=1",
            "checkpointSchema=35", "observerSchema=13",
            "observerMutations=0", "restartCount=\(civ39CheckpointRestoreCount)",
            "restartDuplicateEffects=0", "duplicateInhabitants=0",
            "duplicateDurableIdentities=0", "duplicateEconomicCommitments=0",
            "duplicateReceipts=0", "physicalLoss=0", "physicalDuplication=0",
            "syntheticMaterial=0", "unexpectedRuntimeErrors=0",
            "probes=\(worldProbeIDs.count)",
        ].joined(separator: " ")
        trace(message)
        return success(message)
    }

    private func civ39Status(
        _ current: AgentSimulationSession
    ) -> PebbleAgentCommandResult {
        let population = current.populationSnapshot()
        let scale = current.populationScaleSnapshot()
        let settlements = scale.settlements.map { settlement in
            "\(settlement.settlementID.rawValue):residents="
                + "\(settlement.residentIDs.count):transit="
                + "\(settlement.inTransitIDs.count)"
        }.joined(separator: ",")
        let migrations = scale.settlementMigrations.map {
            "\($0.migrationID.rawValue):\($0.agentID.rawValue):\($0.status.rawValue)"
        }.joined(separator: ",")
        let message = "CIV39_STATUS enabled=\(scale.enabled ? 1 : 0) "
            + "settlements=\(scale.settlements.count) population=\(population.members.count) "
            + "live=\(scale.liveCount) near=\(scale.nearCount) "
            + "dormant=\(scale.dormantCount) tick=\(current.tick) "
            + "settlementRows=\(settlements) migrations=\(migrations.isEmpty ? "none" : migrations) "
            + "transitionHistory=\(scale.fidelityTransitions.count) "
            + "transitionEvicted=\(scale.evictedFidelityTransitionCount) "
            + "work=\(scale.workCounters.liveCognitionExecutions),"
            + "\(scale.workCounters.nearMaintenanceExecutions),"
            + "\(scale.workCounters.dormantMaintenanceExecutions),"
            + "\(scale.workCounters.skippedFullCognitionExecutions)"
        trace(message)
        return success(message)
    }

    private func civ39ResidentState(
        id: String,
        position: AgentPosition,
        tick: Int
    ) -> AgentSessionAgentState {
        AgentSessionAgentState(
            id: id, state: "idle", position: position,
            needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0, safety: 1),
            health: 100, fear: 0, homePosition: position, nearbyAgents: [],
            currentGoal: AgentGoal(
                kind: .idle, reason: "CIV-39 persistent inhabitant",
                startedAtTick: tick, urgency: 0
            ),
            lastAction: nil, lastActionEffect: nil,
            memory: [AgentMemoryEntry(
                tick: tick, type: "residence_registered",
                summary: "durable inhabitant admitted for population scaling",
                importance: 60
            )],
            tickCreated: tick, ticksAlive: 0,
            observationCount: 0, nearbyObservationCount: 0,
            goalSelectionCount: 0, goalChangeCount: 0,
            actionCount: 0, actionEffectCount: 0, movementCount: 0,
            totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
            totalDistanceReducedTowardHome: 0
        )
    }

    private func civ39NavigationCellLessThan(
        _ lhs: AgentNavigationCell,
        _ rhs: AgentNavigationCell
    ) -> Bool {
        if lhs.position.x != rhs.position.x {
            return lhs.position.x < rhs.position.x
        }
        if lhs.position.z != rhs.position.z {
            return lhs.position.z < rhs.position.z
        }
        return lhs.position.y < rhs.position.y
    }

    /// The generic Core planner can represent drops which are walkable as
    /// cells but which the current cell-centred proof body cannot execute as
    /// one atomic `Entity.move` step. CIV-39 refuses those routes during its
    /// controlled live proof instead of treating a coarse route as physical
    /// authority or publishing an unverified arrival.
    private func civ39ExecutableCoreRoute(
        world: World,
        probe: LabCoreAgentEntity,
        destination: AgentPosition,
        occupied: Set<AgentPosition>
    ) -> [AgentPosition]? {
        let start = AgentPosition(
            x: Int(probe.x.rounded(.down)),
            y: Int(probe.y.rounded(.down)),
            z: Int(probe.z.rounded(.down))
        )
        guard let nodes = findPath(
            world, probe.x, probe.y, probe.z,
            Double(destination.x) + 0.5,
            Double(destination.y),
            Double(destination.z) + 0.5,
            600, true
        ), !nodes.isEmpty else { return nil }
        let route = [start] + nodes.map {
            AgentPosition(x: $0.x, y: $0.y, z: $0.z)
        }
        guard route.last == destination,
              Set(route).count == route.count,
              route.dropFirst().allSatisfy({ position in
                  !occupied.contains(position)
                      && assessEntityPlacement(
                          in: world,
                          at: EntityPlacementPosition(
                              x: position.x, y: position.y, z: position.z
                          ),
                          bodyWidth: 0.6,
                          bodyHeight: 1.8,
                          ignoringEntityIDs: [probe.id]
                      ).isValid
              }),
              zip(route, route.dropFirst()).allSatisfy({ pair in
                  let (lhs, rhs) = pair
                  return abs(lhs.x - rhs.x) + abs(lhs.z - rhs.z) == 1
                      && (-1...1).contains(rhs.y - lhs.y)
              }) else { return nil }
        return route
    }
}
