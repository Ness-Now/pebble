import Foundation
import PebbleAgents
import PebbleCore

/// Launch-gated evidence collector for PS01 Increment 03 rendered campaigns.
/// It observes existing owners only: it never supplies roots, changes World
/// time, advances Civilization, or persists proof state.
final class PebbleIncrement03CoverageLiveProof {
    private var frame = 0
    private var batch = 0
    private var pendingBatchTrace = false
    private var firstRequestedFrame: Int?
    private var firstRequestedWorldTick: Int?
    private var firstReadyFrame: Int?
    private var firstReadyWorldTick: Int?
    private var maximumFrameMilliseconds = 0.0

    static func fromEnvironment() -> PebbleIncrement03CoverageLiveProof? {
        ProcessInfo.processInfo.environment[
            "PEBBLELAB_PS01_INCREMENT03_LIVE_PROOF"
        ] == "1" ? PebbleIncrement03CoverageLiveProof() : nil
    }

    func markCommandBatchExecuted() {
        batch += 1
        pendingBatchTrace = true
    }

    func afterFrame(
        game: GameCore,
        controller: PebbleAgentController,
        frameMilliseconds: Double,
        framesPerSecond: Int
    ) -> String? {
        frame += 1
        maximumFrameMilliseconds = max(
            maximumFrameMilliseconds,
            frameMilliseconds
        )
        let world = game.world
        let coverage = world.physicalSimulationCoverage
        if coverage.isRequested, firstRequestedFrame == nil {
            firstRequestedFrame = frame
            firstRequestedWorldTick = world.time
        }
        if coverage.isReady, firstReadyFrame == nil {
            firstReadyFrame = frame
            firstReadyWorldTick = world.time
        }
        guard pendingBatchTrace else { return nil }
        pendingBatchTrace = false
        return makeTrace(
            game: game,
            controller: controller,
            framesPerSecond: framesPerSecond
        )
    }

    private func makeTrace(
        game: GameCore,
        controller: PebbleAgentController,
        framesPerSecond: Int
    ) -> String {
        let world = game.world
        let coverage = world.physicalSimulationCoverage
        let diagnostics = game.physicalSimulationCoverageRuntimeDiagnostics(
            for: world
        )
        let session = controller.session?.snapshot()
        let population = session?.agents.count ?? 0
        let probes = controller.probesByAgentId.values.sorted {
            $0.labAgentId < $1.labAgentId
        }
        let phase: String
        switch batch {
        case 1: phase = "startup"
        case 2: phase = "near"
        case 3: phase = "departed"
        case 4: phase = "far"
        case 5: phase = "returned"
        case 6: phase = "return-stable"
        default: phase = "batch-\(batch)"
        }
        let rootAgreement = requestedRootsAgree(
            controller: controller,
            world: world,
            coverage: coverage
        )
        let sensorReadiness = sensorReadiness(
            world: world,
            session: session
        )
        let pathReadiness = pathReadiness(
            world: world,
            session: session
        )
        let civilizationDigest = (try? controller.session?
            .durableStateDigest().rawValue) ?? "none"
        let physicalDigest = relevantPhysicalDigest(
            world: world,
            coverage: coverage,
            probes: probes
        )
        let playerChunkX = floorDiv(
            Int(game.player.x.rounded(.down)), CHUNK_W
        )
        let playerChunkZ = floorDiv(
            Int(game.player.z.rounded(.down)), CHUNK_W
        )
        let nearestRootDistance = coverage.roots.map {
            max(
                abs($0.chunkX - playerChunkX),
                abs($0.chunkZ - playerChunkZ)
            )
        }.min() ?? -1
        let firstRequest = firstRequestedFrame.map(String.init) ?? "none"
        let firstRequestTick = firstRequestedWorldTick.map(String.init) ?? "none"
        let firstReady = firstReadyFrame.map(String.init) ?? "none"
        let firstReadyTick = firstReadyWorldTick.map(String.init) ?? "none"
        let convergenceFrames = firstReadyFrame.flatMap { ready in
            firstRequestedFrame.map { String(max(0, ready - $0)) }
        } ?? "pending"
        let convergenceWorldTicks = firstReadyWorldTick.flatMap { ready in
            firstRequestedWorldTick.map { String(max(0, ready - $0)) }
        } ?? "pending"
        let minimumProbeTicks = probes.map(\.ticksAlive).min() ?? 0
        let maximumProbeTicks = probes.map(\.ticksAlive).max() ?? 0
        let error = (controller.lastError ?? "none")
            .replacingOccurrences(of: " ", with: "_")
        return String(
            format: "[ps01-i03-live] phase=%@ batch=%d seed=%u "
                + "worldTick=%d civTick=%d population=%d probes=%d "
                + "coverage=%@ roots=%d chunks=%d overlapSavings=%d "
                + "dedupRatio=%.5f ready=%d pending=%d refused=%d "
                + "generationThisTick=%d generationCumulative=%d "
                + "queue=%d:%d:%d loaded=%d coveredResident=%d "
                + "playerChunk=%d,%d nearestRootChunks=%d "
                + "rootAgreement=%d sensorReady=%d sensorUnavailable=%d "
                + "pathReady=%d pathUnavailable=%d probeTicks=%d:%d "
                + "firstRequest=%@:%@ firstReady=%@:%@ "
                + "convergence=%@:%@ fps=%d frameMaxMs=%.3f "
                + "coverageDigest=%@ physicalDigest=%@ civDigest=%@ "
                + "runtimeErrors=%d hardFailure=%d lastError=%@",
            phase, batch, world.seed,
            world.time, session?.tick ?? 0, population, probes.count,
            coverage.status.rawValue, coverage.roots.count,
            coverage.deduplicatedChunkCount, coverage.overlapSavings,
            coverage.deduplicationRatio, coverage.readyChunks.count,
            coverage.unavailableChunks.count, coverage.refusedChunks.count,
            coverage.generationRequestsThisTick,
            coverage.cumulativeGenerationRequests,
            diagnostics.totalGenerationJobsInFlight,
            diagnostics.agentGenerationJobsInFlight,
            diagnostics.playerGenerationJobsInFlight,
            diagnostics.loadedChunkCount,
            diagnostics.coveredResidentChunkCount,
            playerChunkX, playerChunkZ, nearestRootDistance,
            rootAgreement ? 1 : 0,
            sensorReadiness.ready, sensorReadiness.unavailable,
            pathReadiness.ready, pathReadiness.unavailable,
            minimumProbeTicks, maximumProbeTicks,
            firstRequest, firstRequestTick, firstReady, firstReadyTick,
            convergenceFrames, convergenceWorldTicks,
            framesPerSecond, maximumFrameMilliseconds,
            coverage.stableDigest, physicalDigest, civilizationDigest,
            controller.runtimeErrorCount,
            controller.candidatePhysicalHardFailure == nil ? 0 : 1,
            error
        )
    }

    private func requestedRootsAgree(
        controller: PebbleAgentController,
        world: World,
        coverage: PhysicalSimulationCoverageSnapshot
    ) -> Bool {
        switch controller.physicalSimulationCoverageRequest(for: world) {
        case .inactive:
            return coverage.status == .inactive && coverage.roots.isEmpty
        case .refused:
            return coverage.status == .refused
        case .active(let roots):
            let planned = PhysicalSimulationCoveragePlanner.makeSnapshot(
                request: .active(roots),
                isChunkReady: { world.isChunkReady($0, $1) }
            )
            return planned.roots == coverage.roots
                && planned.coveredChunks == coverage.coveredChunks
        }
    }

    private func sensorReadiness(
        world: World,
        session: AgentSessionSnapshot?
    ) -> (ready: Int, unavailable: Int) {
        guard world.physicalSimulationCoverage.isReady,
              let agents = session?.agents else {
            return (0, session?.agents.count ?? 0)
        }
        var ready = 0
        var unavailable = 0
        let sensor = PebbleAgentWorldSensor()
        let navigation = PebbleAgentNavigationAdapter()
        for agent in agents {
            guard let observation = try? sensor.observe(
                world: world,
                agent: agent
            ) else {
                unavailable += 1
                continue
            }
            let target = AgentPosition(
                x: agent.position.x + AgentNavigationObservation.maximumRadius,
                y: agent.position.y,
                z: agent.position.z
            )
            let navigationObservation = navigation.observe(
                world: world,
                agent: agent,
                target: target,
                occupiedAgentPositions: agents.filter {
                    $0.id != agent.id
                }.map(\.position),
                goalMode: .exact
            )
            let allReady = observation.center.chunkReady
                && observation.neighbors.allSatisfy { $0.column.chunkReady }
                && !navigationObservation.cells.contains {
                    $0.status == .unavailable
                }
            if allReady { ready += 1 } else { unavailable += 1 }
        }
        return (ready, unavailable)
    }

    private func pathReadiness(
        world: World,
        session: AgentSessionSnapshot?
    ) -> (ready: Int, unavailable: Int) {
        guard world.physicalSimulationCoverage.isReady,
              let agents = session?.agents else {
            return (0, session?.agents.count ?? 0)
        }
        let domain = PhysicalPathSearchDomain(
            coverage: world.physicalSimulationCoverage
        )
        var ready = 0
        var unavailable = 0
        for agent in agents {
            let position = agent.position
            let result = findPath(
                world,
                Double(position.x) + 0.5,
                Double(position.y),
                Double(position.z) + 0.5,
                Double(position.x) + 0.5,
                Double(position.y),
                Double(position.z) + 0.5,
                600,
                true,
                within: domain
            )
            if case .path = result { ready += 1 } else { unavailable += 1 }
        }
        return (ready, unavailable)
    }

    private func relevantPhysicalDigest(
        world: World,
        coverage: PhysicalSimulationCoverageSnapshot,
        probes: [LabCoreAgentEntity]
    ) -> String {
        var hash: UInt64 = 1469598103934665603
        func mix(_ value: String) {
            for byte in value.utf8 {
                hash ^= UInt64(byte)
                hash &*= 1099511628211
            }
            hash ^= 0xff
            hash &*= 1099511628211
        }
        mix("seed:\(world.seed):dim:\(world.dim.rawValue):tick:\(world.time)")
        for position in coverage.coveredChunks {
            mix("chunk:\(position.x):\(position.z)")
            guard let chunk = world.getChunk(position.x, position.z) else {
                mix("unavailable")
                continue
            }
            for cell in chunk.blocks {
                hash ^= UInt64(cell & 0xff)
                hash &*= 1099511628211
                hash ^= UInt64(cell >> 8)
                hash &*= 1099511628211
            }
        }
        for probe in probes {
            mix(
                "probe:\(probe.labAgentId):\(probe.physicalId):"
                    + "\(probe.x):\(probe.y):\(probe.z):\(probe.ticksAlive)"
            )
        }
        let probeObjects = Set(probes.map(ObjectIdentifier.init))
        let ordinary = world.entities.compactMap { $0 as? Entity }.filter {
            !probeObjects.contains(ObjectIdentifier($0))
                && !$0.isPlayer
                && coverage.covers(
                    chunkX: floorDiv(Int($0.x.rounded(.down)), CHUNK_W),
                    chunkZ: floorDiv(Int($0.z.rounded(.down)), CHUNK_W)
                )
        }.sorted {
            let lhs = "\($0.type):\($0.x):\($0.y):\($0.z):\($0.age)"
            let rhs = "\($1.type):\($1.x):\($1.y):\($1.z):\($1.age)"
            return lhs < rhs
        }
        for entity in ordinary {
            mix(
                "entity:\(entity.type):\(entity.x):\(entity.y):"
                    + "\(entity.z):\(entity.age):\(entity.dead ? 1 : 0)"
            )
        }
        return String(format: "%016llx", hash)
    }
}
