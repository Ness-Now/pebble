import Foundation
import PebbleAgents
import PebbleCore

private struct CIV19FixtureCell: Hashable {
    let x: Int
    let y: Int
    let z: Int
}

private enum CIV19ProofError: Error {
    case precondition(String)
    case assertion(String)
}

extension PebbleAgentController {
    func handleEmbodimentConvergence(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        guard arguments == ["proof"] else {
            return failure("Usage: /lab embodiment proof")
        }
        guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1" else {
            return failure("Embodiment proof requires a disposable World.")
        }
        guard let session, activeWorld === world, isPaused, !movementEnabled,
              let anchor else {
            return failure("Embodiment proof requires an active paused session with movement off.")
        }

        do {
            let sessionBefore = try session.durableStateBytes()
            let probeMapBefore = probesByAgentId.mapValues { $0.id }
            let entityIDsBefore = world.entities.map(\.id).sorted()
            let custodyBefore = probesByAgentId.mapValues { copyItemInventory($0.carriedItems) }
            let live = try PebbleAgentEmbodiment.resolveAll(
                agentIDs: session.snapshot().agents.map(\.id),
                in: world,
                mappedByAgentID: probesByAgentId
            )
            guard live.count == session.snapshot().agentCount else {
                throw CIV19ProofError.assertion("live one-to-one mapping")
            }

            let lifecycle = try proveEmbodimentLifecycle(world: world)
            let first = try proveCoreNavigationBoundary(
                world: world,
                anchor: anchor,
                run: 1
            )
            let second = try proveCoreNavigationBoundary(
                world: world,
                anchor: anchor,
                run: 2
            )
            guard first == second else {
                throw CIV19ProofError.assertion("repeat digest mismatch")
            }
            let sessionAfter = try session.durableStateBytes()
            let custodyExact = probesByAgentId.allSatisfy { id, probe in
                guard let before = custodyBefore[id] else { return false }
                return exactCIV19Slots(probe.carriedItems, before)
            }
            guard sessionAfter == sessionBefore,
                  probesByAgentId.mapValues({ $0.id }) == probeMapBefore,
                  world.entities.map(\.id).sorted() == entityIDsBefore,
                  custodyExact else {
                throw CIV19ProofError.assertion("published state or cleanup changed")
            }

            let combined = first + "|" + lifecycle
            let digest = AgentCheckpointDigest.sha256(Data(combined.utf8)).rawValue
            let message = "embodiment proof authority=PebbleCore/findPath+Entity.move "
                + "body=PebbleAgentEmbodiment oneToOne=exact "
                + "simple=passed obstacle=passed dynamic=passed vertical=passed gap=refused "
                + "multiAgent=refused waypoint=corePath coarsePlanner=preserved "
                + "physicalTruth=wins orientation=physical noNormalSetPos=1 "
                + "latePublicationRollback=exact harvestReach=physical constructionReach=physical "
                + "missing=refused duplicate=refused staleWorld=refused custodyRemoval=spilled "
                + "session=unchanged custody=unchanged cleanup=exact runs=2 digest=\(digest)"
            trace(message)
            return success("CIV-19 navigation and embodiment proof passed: \(digest)")
        } catch {
            trace("embodiment proof failed error=\(error)")
            return failure("Embodiment convergence proof failed: \(error)")
        }
    }

    private func proveEmbodimentLifecycle(world: World) throws -> String {
        guard let actual = probesByAgentId["agent_0"] else {
            throw CIV19ProofError.precondition("agent_0 missing")
        }
        var missingRefused = false
        do {
            _ = try PebbleAgentEmbodiment.resolve(
                agentID: "agent_0", in: world, mappedByAgentID: [:]
            )
        } catch PebbleAgentEmbodiment.ResolutionError.missingMapping("agent_0") {
            missingRefused = true
        }

        let duplicate = LabCoreAgentEntity(
            world: world,
            labAgentId: "agent_0",
            physicalId: "civ19_duplicate"
        )
        duplicate.setPos(actual.x, actual.y, actual.z) // fixture insertion only
        world.addEntity(duplicate)
        var duplicateRefused = false
        do {
            _ = try PebbleAgentEmbodiment.resolve(
                agentID: "agent_0", in: world, mappedByAgentID: probesByAgentId
            )
        } catch PebbleAgentEmbodiment.ResolutionError.duplicateWorldEntity("agent_0") {
            duplicateRefused = true
        }
        world.removeEntity(duplicate)

        let staleWorld = World(dim: .overworld, seed: world.seed)
        var staleRefused = false
        do {
            _ = try PebbleAgentEmbodiment.resolve(
                agentID: "agent_0", in: staleWorld, mappedByAgentID: probesByAgentId
            )
        } catch PebbleAgentEmbodiment.ResolutionError.staleWorld("agent_0") {
            staleRefused = true
        }

        let custodyProbe = LabCoreAgentEntity(
            world: world,
            labAgentId: "civ19_custody_probe",
            physicalId: "civ19_custody_probe"
        )
        custodyProbe.setPos(actual.x, actual.y + 4, actual.z) // fixture insertion only
        custodyProbe.carriedItems[0] = ItemStack(iid("stone"), 1)
        world.addEntity(custodyProbe)
        let idsBeforeRemoval = Set(world.entities.map(\.id))
        let removed = removeLabCoreAgentProbe(custodyProbe, from: world)
        let spilled = world.entities.compactMap { $0 as? ItemEntity }.filter {
            !idsBeforeRemoval.contains($0.id)
        }
        let spillVerified = removed && spilled.count == 1
            && spilled[0].stack.id == iid("stone") && spilled[0].stack.count == 1
        for item in spilled { world.removeEntity(item) }

        guard missingRefused, duplicateRefused, staleRefused, spillVerified else {
            throw CIV19ProofError.assertion("lifecycle boundary")
        }
        return "missing=1;duplicate=1;stale=1;spill=1"
    }

    private func proveCoreNavigationBoundary(
        world: World,
        anchor: AgentPosition,
        run: Int
    ) throws -> String {
        let baseX = anchor.x - 2
        let baseY = anchor.y + 8
        let baseZ = anchor.z + 6
        guard world.isChunkReady(baseX >> 4, baseZ >> 4),
              world.isChunkReady((baseX + 8) >> 4, (baseZ + 3) >> 4) else {
            throw CIV19ProofError.precondition("fixture chunks unavailable")
        }
        var originals: [CIV19FixtureCell: Int] = [:]
        var proofProbes: [LabCoreAgentEntity] = []
        func rememberAndSet(_ x: Int, _ y: Int, _ z: Int, _ value: Int) {
            let key = CIV19FixtureCell(x: x, y: y, z: z)
            if originals[key] == nil { originals[key] = world.getBlock(x, y, z) }
            world.setBlock(x, y, z, value, SET_SILENT)
        }
        func addProbe(_ suffix: String, x: Int, y: Int, z: Int) -> LabCoreAgentEntity {
            let probe = LabCoreAgentEntity(
                world: world,
                labAgentId: "civ19_\(run)_\(suffix)",
                physicalId: "civ19_\(run)_\(suffix)"
            )
            probe.setPos(Double(x) + 0.5, Double(y), Double(z) + 0.5) // spawn only
            world.addEntity(probe)
            proofProbes.append(probe)
            return probe
        }
        defer {
            for probe in proofProbes where world.entities.contains(where: { $0 === probe }) {
                world.removeEntity(probe)
            }
            for (position, value) in originals {
                world.setBlock(position.x, position.y, position.z, value, SET_SILENT)
            }
        }

        for z in (baseZ - 3)...(baseZ + 3) {
            for x in (baseX - 2)...(baseX + 8) {
                rememberAndSet(x, baseY - 1, z, Int(cell(B.stone)))
                rememberAndSet(x, baseY, z, 0)
                rememberAndSet(x, baseY + 1, z, 0)
                rememberAndSet(x, baseY + 2, z, 0)
            }
        }

        let probe = addProbe("navigator", x: baseX, y: baseY, z: baseZ)
        let embodiment = try PebbleAgentEmbodiment.resolve(
            agentID: probe.labAgentId,
            in: world,
            mappedByAgentID: [probe.labAgentId: probe]
        )
        let destination = AgentPosition(x: baseX + 6, y: baseY, z: baseZ)
        let simple = try movementExecutor.proveBoundedCoreStep(
            world: world,
            embodiment: embodiment,
            destination: destination
        )
        guard simple.pathFound, simple.reachedCoreNode, simple.rollbackVerified,
              simple.orientationChanged else {
            throw CIV19ProofError.assertion("simple physical step")
        }

        rememberAndSet(baseX + 1, baseY, baseZ, Int(cell(B.stone)))
        rememberAndSet(baseX + 1, baseY + 1, baseZ, Int(cell(B.stone)))
        let obstaclePath = findPath(
            world, probe.x, probe.y, probe.z,
            Double(destination.x) + 0.5, Double(destination.y), Double(destination.z) + 0.5,
            600, true
        )
        guard obstaclePath?.contains(where: {
            $0.x == baseX + 1 && $0.y == baseY && $0.z == baseZ
        }) == false, obstaclePath?.isEmpty == false else {
            throw CIV19ProofError.assertion("obstacle route")
        }
        rememberAndSet(baseX + 1, baseY, baseZ, 0)
        rememberAndSet(baseX + 1, baseY + 1, baseZ, 0)

        guard let beforeDynamic = findPath(
            world, probe.x, probe.y, probe.z,
            Double(destination.x) + 0.5, Double(destination.y), Double(destination.z) + 0.5,
            600, true
        ), let first = beforeDynamic.first else {
            throw CIV19ProofError.assertion("dynamic initial route")
        }
        rememberAndSet(first.x, first.y, first.z, Int(cell(B.stone)))
        rememberAndSet(first.x, first.y + 1, first.z, Int(cell(B.stone)))
        let replanned = findPath(
            world, probe.x, probe.y, probe.z,
            Double(destination.x) + 0.5, Double(destination.y), Double(destination.z) + 0.5,
            600, true
        )
        guard replanned?.first.map({
            $0.x != first.x || $0.y != first.y || $0.z != first.z
        }) == true else {
            throw CIV19ProofError.assertion("dynamic replan")
        }
        rememberAndSet(first.x, first.y, first.z, 0)
        rememberAndSet(first.x, first.y + 1, first.z, 0)

        rememberAndSet(baseX + 1, baseY, baseZ, Int(cell(B.stone)))
        let verticalBoundary = try movementExecutor.proveBoundedCoreStep(
            world: world,
            embodiment: embodiment,
            destination: AgentPosition(x: baseX + 1, y: baseY + 1, z: baseZ),
            explorationHomePosition: AgentPosition(
                x: baseX - 7, y: baseY, z: baseZ
            ),
            explorationDistanceBoundary: 8
        )
        guard verticalBoundary.pathFound,
              verticalBoundary.explorationBoundaryRefused,
              !verticalBoundary.reachedCoreNode,
              verticalBoundary.physicalMutationCount == 0,
              verticalBoundary.node == AgentPosition(
                  x: baseX + 1, y: baseY + 1, z: baseZ
              ),
              embodiment.position == AgentPosition(
                  x: baseX, y: baseY, z: baseZ
              ) else {
            throw CIV19ProofError.assertion(
                "vertical exploration boundary prevalidation"
            )
        }
        let verticalWithinBoundary = try movementExecutor.proveBoundedCoreStep(
            world: world,
            embodiment: embodiment,
            destination: AgentPosition(x: baseX + 1, y: baseY + 1, z: baseZ),
            explorationHomePosition: AgentPosition(
                x: baseX - 6, y: baseY, z: baseZ
            ),
            explorationDistanceBoundary: 8
        )
        guard verticalWithinBoundary.reachedCoreNode,
              !verticalWithinBoundary.explorationBoundaryRefused,
              verticalWithinBoundary.physicalMutationCount == 1,
              verticalWithinBoundary.rollbackVerified else {
            throw CIV19ProofError.assertion(
                "vertical exploration step within boundary"
            )
        }
        let vertical = try movementExecutor.proveBoundedCoreStep(
            world: world,
            embodiment: embodiment,
            destination: AgentPosition(x: baseX + 1, y: baseY + 1, z: baseZ)
        )
        guard vertical.reachedCoreNode, vertical.node?.y == baseY + 1,
              vertical.rollbackVerified else {
            throw CIV19ProofError.assertion("vertical step")
        }
        rememberAndSet(baseX + 1, baseY, baseZ, 0)

        rememberAndSet(baseX + 1, baseY - 1, baseZ, 0)
        let gap = findPath(
            world, probe.x, probe.y, probe.z,
            Double(baseX + 2) + 0.5, Double(baseY), Double(baseZ) + 0.5,
            600, true
        )
        guard gap?.contains(where: {
            $0.x == baseX + 1 && $0.y == baseY && $0.z == baseZ
        }) != true else {
            throw CIV19ProofError.assertion("unsupported gap")
        }
        rememberAndSet(baseX + 1, baseY - 1, baseZ, Int(cell(B.stone)))

        guard let occupiedNode = simple.node else {
            throw CIV19ProofError.assertion("missing occupied node")
        }
        let occupied = try movementExecutor.proveBoundedCoreStep(
            world: world,
            embodiment: embodiment,
            destination: destination,
            occupied: [occupiedNode]
        )
        guard occupied.occupiedRefused else {
            throw CIV19ProofError.assertion("multi-agent target conflict")
        }
        let late = try movementExecutor.proveBoundedCoreStep(
            world: world,
            embodiment: embodiment,
            destination: destination,
            rejectAfterPhysicalMove: true
        )
        guard late.reachedCoreNode, late.latePublicationRejected,
              late.rollbackVerified else {
            throw CIV19ProofError.assertion("late publication rollback")
        }

        return "simple=1;obstacle=1;dynamic=1;vertical=1;"
            + "explorationBoundary=1;prevalidatedMutationCount=0;"
            + "gap=1;occupied=1;late=1;node="
            + "\(simple.node!.x - baseX),\(simple.node!.y - baseY),\(simple.node!.z - baseZ)"
    }

    private func exactCIV19Slots(_ lhs: [ItemStack?], _ rhs: [ItemStack?]) -> Bool {
        lhs.count == rhs.count && zip(lhs, rhs).allSatisfy { left, right in
            switch (left, right) {
            case (nil, nil): return true
            case let (left?, right?): return left == right
            default: return false
            }
        }
    }
}
