import Foundation
import PebbleAgents
import PebbleCore

/// Explicitly gated, non-authoritative focused evidence for the shared
/// navigation adapter. It may inspect a copied saved World or build a bounded
/// disposable fixture; it never participates in an ordinary product launch.
enum PebbleIncrement07InvalidStartHarness {
    private static let gate = "PEBBLELAB_PS01_INCREMENT07_INVALIDSTART"

    private enum HarnessError: Error, CustomStringConvertible {
        case invalidConfiguration(String)
        case assertion(String)

        var description: String {
            switch self {
            case .invalidConfiguration(let message): return message
            case .assertion(let message): return message
            }
        }
    }

    static func runIfRequested(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> Int32? {
        guard let mode = environment[gate] else { return nil }
        do {
            switch mode {
            case "focused":
                try runFocused()
            default:
                throw HarnessError.invalidConfiguration("unknown mode \(mode)")
            }
            return 0
        } catch {
            fputs("[ps01-i07-invalid-start] FAIL \(error)\n", stderr)
            return 1
        }
    }

    private static func runFocused() throws {
        // GameCore owns frozen registry initialization. The fixture does not
        // enter or advance a World through this instance.
        _ = GameCore()
        let world = flatWorld()
        let adapter = PebbleAgentNavigationAdapter()
        let start = AgentPosition(x: 0, y: 64, z: 0)
        let target = AgentPosition(x: 3, y: 64, z: 0)

        let ordinary = adapter.observe(
            world: world, origin: start, target: target,
            occupiedAgentPositions: [], goalMode: .exact
        )
        let ordinaryPlan = plan(ordinary, start: start, target: target, mode: .exact)
        try require(ordinaryPlan.found, "ordinary clean-air route")

        world.setBlock(start.x, start.y, start.z, Int(cell(B.short_grass)), SET_SILENT)
        let passableAssessment = assessEntityPlacement(
            in: world,
            at: EntityPlacementPosition(x: start.x, y: start.y, z: start.z),
            bodyWidth: 0.6,
            bodyHeight: 1.8
        )
        let passable = adapter.observe(
            world: world, origin: start, target: target,
            occupiedAgentPositions: [], goalMode: .exact
        )
        let passablePlan = plan(passable, start: start, target: target, mode: .exact)
        try require(passableAssessment.isValid, "Core passable vegetation placement")
        try require(status(in: passable, at: start) == .traversable,
                    "adapter passable vegetation start")
        try require(passablePlan.found && passablePlan.positions.first == start,
                    "passable vegetation bounded route")

        let occupied = AgentPosition(x: 1, y: 64, z: 0)
        let occupancy = adapter.observe(
            world: world, origin: start, target: target,
            occupiedAgentPositions: [occupied], goalMode: .exact
        )
        try require(status(in: occupancy, at: occupied) == .blocked,
                    "other-agent occupancy")

        let unsupported = AgentPosition(x: 8, y: 65, z: 8)
        let supportedTarget = AgentPosition(x: 10, y: 64, z: 8)
        let invalid = adapter.observe(
            world: world, origin: unsupported, target: supportedTarget,
            occupiedAgentPositions: [], goalMode: .exact
        )
        let invalidPlan = plan(
            invalid, start: unsupported, target: supportedTarget, mode: .exact
        )
        try require(invalidPlan.failure == .invalidStart,
                    "unsupported true invalid start")

        let blockedStart = AgentPosition(x: 5, y: 64, z: 5)
        world.setBlock(
            blockedStart.x, blockedStart.y, blockedStart.z,
            Int(cell(B.stone)), SET_SILENT
        )
        let blocked = adapter.observe(
            world: world, origin: blockedStart,
            target: AgentPosition(x: 6, y: 64, z: 5),
            occupiedAgentPositions: [], goalMode: .exact
        )
        try require(status(in: blocked, at: blockedStart) == .blocked,
                    "solid body obstruction")

        let drop = AgentPosition(x: 4, y: 64, z: 4)
        world.setBlock(drop.x, drop.y - 1, drop.z, 0, SET_SILENT)
        let dropObservation = adapter.observe(
            world: world, origin: start, target: target,
            occupiedAgentPositions: [], goalMode: .exact
        )
        try require(status(in: dropObservation, at: drop) == .dangerousDrop,
                    "dangerous drop remains dangerous")

        let adjacentTarget = AgentPosition(x: 2, y: 64, z: 0)
        let adjacent = adapter.observe(
            world: world, origin: start, target: adjacentTarget,
            occupiedAgentPositions: [], goalMode: .cardinalAdjacent
        )
        let adjacentPlan = plan(
            adjacent, start: start, target: adjacentTarget,
            mode: .cardinalAdjacent
        )
        try require(status(in: adjacent, at: adjacentTarget) == .blocked,
                    "cardinal target collision semantics")
        try require(adjacentPlan.found,
                    "cardinal approach remains reachable")

        let productChain = try runFocusedProductChain()

        print(
            "[ps01-i07-invalid-start] FOCUSED_PASS ordinaryRoute="
                + "\(ordinaryPlan.positions.count) passableBlock=short_grass "
                + "corePlacement=valid passableRoute=\(passablePlan.positions.count) "
                + "trueInvalid=invalidStart otherOccupancy=blocked "
                + "solidObstruction=blocked dangerousDrop=dangerousDrop "
                + "cardinalTarget=blocked cardinalApproach=found "
                + productChain
        )
    }

    private static func runFocusedProductChain() throws -> String {
        let game = GameCore()
        let world = flatWorld()
        world.time = 100
        let player = Player(world: world)
        player.setPos(0.5, 64, 0.5)
        world.addEntity(player)
        let controller = PebbleAgentController()
        controller.worldSideReceiptDatabase = game.db
        controller.persistenceWorldID = "ps01-i07-invalidstart-focused"
        controller.persistenceDimension = Dim.overworld.rawValue
        let started = controller.start(
            world: world,
            player: player,
            founders: try PebbleNormalFounderProfile(count: 24)
        )
        try require(
            started.succeeded,
            "focused normal founder start: \(started.message)"
        )
        guard let session = controller.session,
              let anchor = session.snapshot().agents.first?.position else {
            throw HarnessError.assertion("focused founder session")
        }
        let occupied = Set(session.snapshot().agents.map(\.position))
        let directions = [(1, 0), (-1, 0), (0, 1), (0, -1)]
        guard let selected = directions.compactMap({ dx, dz ->
            (approach: AgentPosition, target: AgentPosition)? in
            let approach = AgentPosition(
                x: anchor.x + dx, y: anchor.y, z: anchor.z + dz
            )
            let target = AgentPosition(
                x: anchor.x + dx * 2, y: anchor.y, z: anchor.z + dz * 2
            )
            guard !occupied.contains(approach), !occupied.contains(target) else {
                return nil
            }
            return (approach, target)
        }).first else {
            throw HarnessError.assertion("focused berry corridor")
        }
        for probe in controller.probesByAgentId.values {
            let position = PebbleAgentEmbodiment(probe: probe).position
            world.setBlock(
                position.x, position.y, position.z,
                Int(cell(B.short_grass)), SET_SILENT
            )
            let assessment = assessEntityPlacement(
                in: world,
                at: EntityPlacementPosition(
                    x: position.x, y: position.y, z: position.z
                ),
                bodyWidth: probe.width,
                bodyHeight: probe.height,
                ignoringEntityIDs: Set(world.entities.map(\.id))
            )
            try require(assessment.isValid, "focused passable founder start")
        }
        world.setBlock(
            selected.target.x, selected.target.y - 1, selected.target.z,
            Int(cell(B.grass_block)), SET_SILENT
        )
        world.setBlock(
            selected.target.x, selected.target.y, selected.target.z,
            Int(cell(B.sweet_berry_bush, 2)), SET_SILENT
        )
        world.setBlock(
            selected.target.x, selected.target.y + 1, selected.target.z,
            0, SET_SILENT
        )
        world.applyPhysicalSimulationCoverage(
            controller.physicalSimulationCoverageRequest(for: world)
        )
        try require(
            world.physicalSimulationCoverage.isReady,
            "focused physical coverage"
        )
        controller.ecologicalObservationSensor.invalidate(world: world)

        var sawFreshEvidence = false
        var sawSelectedOpportunity = false
        var sawSelectedActivity = false
        var sawRoute = false
        var success: AgentSubsistenceOutcome?
        for step in 0 ..< 56 {
            // Focused setup controls the initial source, but hunger still
            // arrives only from genuine Core World progression at the
            // published 1,200-World-tick physiological boundary. Once the
            // normal hungry threshold is reached, cognition resumes at its
            // ordinary five-World-tick cadence so movement is not starved by
            // the characterization harness itself.
            let worldTicks = step < 8 ? 1_200 : 5
            for _ in 0 ..< worldTicks { world.tick() }
            guard controller.advanceOneTick(world: world, player: player) else {
                throw HarnessError.assertion(
                    "focused product tick: \(controller.lastError ?? "unknown")"
                )
            }
            guard let live = controller.session else {
                throw HarnessError.assertion("focused product publication")
            }
            sawFreshEvidence = sawFreshEvidence
                || live.ecologicalObservationSnapshot().observations.contains {
                    record in record.observation.plants.contains {
                        $0.position == selected.target
                            && $0.edibleSourceEvidence != nil
                    }
                }
            sawSelectedOpportunity = sawSelectedOpportunity
                || live.wildSubsistenceSnapshot().opportunities.contains {
                    $0.lastObservedPosition == selected.target
                        && $0.status == .selected
                }
            sawSelectedActivity = sawSelectedActivity
                || live.autonomousActivitySnapshot().activeActivities.contains {
                    $0.candidate.physicalTarget == selected.target
                        && $0.candidate.domain == .wildGathering
                }
            sawRoute = sawRoute || live.snapshot().agents.contains {
                $0.navigationProgress.route?.positions.isEmpty == false
            }
            success = live.wildSubsistenceSnapshot().retainedOutcomes
                .reversed().map(\.outcome).first {
                    $0.targetPosition == selected.target
                        && $0.status == .succeeded
                        && $0.attribution
                            == "core-canonical-preserving-sweet-berry-harvest"
                }
            if success != nil { break }
        }
        guard let success else {
            let live = controller.session
            let wild = live?.wildSubsistenceSnapshot()
            let activities = live?.autonomousActivitySnapshot()
            let navigation = live?.snapshot().agents.filter {
                $0.navigationProgress.status != .idle
                    || $0.lastAction?.name == "approach_activity"
            }.map { agent in
                let progress = agent.navigationProgress
                let routeCount = progress.route?.positions.count ?? 0
                let failure = progress.lastFailure?.rawValue ?? "none"
                return "\(agent.id)@\(positionDescription(agent.position)):"
                    + "\(progress.status.rawValue):\(progress.routeIndex)/"
                    + "\(routeCount):\(failure)"
            }.joined(separator: ",") ?? "none"
            let movement = controller.lastMovementOutcomes.filter {
                $0.status != .notRequested
            }.map {
                "\($0.agentId):\($0.status.rawValue):\($0.resolutionReason)"
            }.joined(separator: ",")
            throw HarnessError.assertion(
                "focused product physical approach fresh=\(sawFreshEvidence ? 1 : 0) "
                    + "opportunity=\(sawSelectedOpportunity ? 1 : 0) "
                    + "activity=\(sawSelectedActivity ? 1 : 0) "
                    + "route=\(sawRoute ? 1 : 0) attempts="
                    + "\(wild?.totalAttemptCount ?? -1) opportunities="
                    + "\(wild?.opportunities.count ?? -1) activities="
                    + "\(activities?.activeActivities.count ?? -1) source="
                    + "\(world.getBlock(selected.target.x, selected.target.y, selected.target.z)) "
                    + "navigation=\(navigation) movement=\(movement) "
                    + "lastError=\(controller.lastError ?? "none")"
            )
        }
        try require(sawFreshEvidence, "focused fresh mature evidence")
        try require(sawSelectedOpportunity, "focused opportunity selection")
        try require(sawSelectedActivity, "focused autonomous activity selection")
        try require(sawRoute, "focused bounded route publication")
        try require(
            world.getBlock(
                selected.target.x, selected.target.y, selected.target.z
            ) == Int(cell(B.sweet_berry_bush, 1)),
            "focused preserving harvest"
        )
        try require(success.sourceObservationEventID != nil,
                    "focused acquisition observation provenance")
        return "productChain=freshEvidence>selectedOpportunity>selectedActivity>"
            + "boundedRoute>physicalApproach>preservingHarvest actor="
            + "\(success.actorID.rawValue) acquired=\(success.acquiredQuantity)"
    }

    private static func flatWorld() -> World {
        let world = World(dim: .overworld, seed: 92)
        for chunkZ in -3 ... 3 {
            for chunkX in -3 ... 3 {
                let chunk = Chunk(
                    cx: chunkX, cz: chunkZ,
                    minY: world.info.minY, height: world.info.height
                )
                for localZ in 0 ..< CHUNK_W {
                    for localX in 0 ..< CHUNK_W {
                        chunk.set(
                            localX, 63, localZ,
                            cell(B.grass_block)
                        )
                    }
                }
                chunk.buildHeightmap()
                chunk.status = .lit
                world.setChunk(chunk)
            }
        }
        return world
    }

    private static func plan(
        _ observation: AgentNavigationObservation,
        start: AgentPosition,
        target: AgentPosition,
        mode: AgentNavigationGoalMode
    ) -> AgentNavigationPlan {
        AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
            start: start,
            target: target,
            goalMode: mode,
            cells: observation.cells,
            radius: observation.radius,
            maxVisitedNodes: AgentBoundedRoutePlanner.maximumVisitedNodes,
            maxSteps: AgentBoundedRoutePlanner.maximumRouteSteps
        ))
    }

    private static func status(
        in observation: AgentNavigationObservation,
        at position: AgentPosition
    ) -> AgentNavigationCellStatus? {
        observation.cells.first(where: { $0.position == position })?.status
    }

    private static func positionDescription(_ position: AgentPosition) -> String {
        "\(position.x),\(position.y),\(position.z)"
    }

    private static func require(
        _ condition: @autoclosure () -> Bool,
        _ label: String
    ) throws {
        guard condition() else { throw HarnessError.assertion(label) }
    }
}
