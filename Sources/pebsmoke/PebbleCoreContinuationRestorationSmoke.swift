import Foundation
import PebbleCore

/// Controlled authority attacks. The natural product overlap is qualified by
/// Pebble's separate seed-5 campaign; these fixtures isolate Core's scope.
func runPebbleCoreContinuationRestorationSmoke() {
    let priorRuntimeFrontier = peekNextEntityId()
    defer { resetEntityIds(priorRuntimeFrontier) }
    section("Authenticated saved World occupancy and restoration lifetime")
    let writer = GameCore()
    let id = "ps01-core-continuation-restoration"
    writer.db.deleteWorld(id)
    var record = WorldRecord(id: id, name: "PebbleLab-Disposable-Restoration-5",
        seed: 5, gameMode: GameMode.creative, difficulty: 2)
    record.spawnX = 8; record.spawnY = 76; record.spawnZ = -112
    check("restoration fixture World installs", writer.db.putWorld(record))
    writer.loadWorld(id)
    let world = writer.world
    let found = findSafeEntityPlacements(in: world,
        anchor: EntityPlacementPosition(x: 10, y: 75, z: -112),
        preferredPositions: [], reservedPoints: [],
        configuration: BoundedEntityPlacementSearchConfiguration(
            requiredCount: 1, horizontalRadius: 4, verticalRadius: 4,
            maximumCandidateEvaluations: 1024, bodyWidth: 0.6, bodyHeight: 1.8,
            minimumSelectedHorizontalDistance: 0, minimumReservedHorizontalDistance: 0,
            minimumEgressCount: 0, maximumSafeDrop: 1),
        ignoringEntityIDs: Set(world.entities.map(\.id)))
    check("restoration controlled support is naturally available", found.isComplete)
    guard let target = found.positions.first else { writer.db.deleteWorld(id); return }
    writer.player.setPos(Double(target.x) + 0.5, Double(target.y), Double(target.z) + 0.5)
    let spider = spawnMob(world, "spider", writer.player.x, writer.player.y,
                          writer.player.z) as! Spider
    spider.health = 13; spider.age = 17
    let probe = LabCoreAgentEntity(world: world, labAgentId: "fixture",
                                   physicalId: "fixture-transient")
    probe.setPos(writer.player.x, writer.player.y, writer.player.z)
    world.addEntity(probe)
    check("restoration fixture ordinary physical barrier succeeds", writer.saveAndFlush(synchronous: true))
    let saved = writer.db.getChunk(id, 0, target.x >> 4, target.z >> 4)!
    check("restoration Spider persisted exactly once", saved.entities.filter { $0["type"] as? String == "spider" }.count == 1)
    check("restoration transient probe and Player excluded from chunk owner",
        saved.entities.allSatisfy { ![LabCoreAgentEntity.kind, "player"].contains($0["type"] as? String ?? "") })
    check("restoration requirement uses existing boundary", writer.db.requireWorldContinuation(id))
    let payload = Data("core-opaque-restoration-test".utf8)
    check("restoration selected physical revision publishes",
        writer.db.publishWorldContinuation(id, revision: writer.db.worldContinuation(id)!.revision, payload: payload))

    var retained: WorldContinuationRestorationAuthority?
    let reader = GameCore()
    reader.restoreExternalContinuation = {
        do {
            let current = reader.world
            let boundary = reader.db.worldContinuation(id)!
            let authority = try reader.acquireWorldContinuationRestorationAuthority(in: current, boundary: boundary)
            retained = authority
            func collisions() throws -> Set<Int> {
                try authority.authenticatedCollisionIDs(in: current, at: [target], bodyWidth: 0.6, bodyHeight: 1.8)
            }
            func refuses(_ action: () throws -> Void) -> Bool {
                do { try action(); return false } catch { return true }
            }
            let bodies = current.entities.compactMap { $0 as? Spider }
            guard bodies.count == 1 else { check("restoration single saved Spider materializes", false); return false }
            let restored = bodies[0]
            let ids = try collisions()
            check("restoration saved Player and Spider authenticate semantically", ids == Set([reader.player.id, restored.id]))
            check("restoration ordinary admission still refuses identical overlap",
                assessEntityPlacement(in: current, at: target, bodyWidth: 0.6, bodyHeight: 1.8).rejections.contains(.entityCollision))
            check("restoration authenticated overlap retains geometry checks",
                assessEntityPlacement(in: current, at: target, bodyWidth: 0.6, bodyHeight: 1.8, ignoringEntityIDs: ids).isValid)
            check("restoration target-to-target overlap remains refused",
                !assessEntityPlacementSet(in: current, at: [target, target], bodyWidth: 0.6, bodyHeight: 1.8, ignoringEntityIDs: ids).isValid)
            let time = current.time
            _ = reader.frame(dtMs: TICK_MS)
            check("restoration callback halts reentrant gameplay and saving",
                current.time == time && !reader.worldMutationAllowed && !reader.saveAndFlush())
            let foreign = World(dim: .overworld, seed: current.seed)
            check("restoration foreign World refuses", refuses {
                _ = try authority.authenticatedCollisionIDs(in: foreign, at: [target], bodyWidth: 0.6, bodyHeight: 1.8)
            })
            reader.dim = .nether
            check("restoration foreign dimension refuses", refuses { _ = try collisions() })
            reader.dim = .overworld
            restored.health += 1
            check("restoration changed ordinary state refuses", refuses { _ = try collisions() })
            restored.health -= 1
            let width = restored.width
            restored.width += 0.1
            check("restoration altered collider geometry refuses", refuses { _ = try collisions() })
            restored.width = width
            current.removeEntity(restored)
            check("restoration removed expected collider cannot borrow authority", refuses { _ = try collisions() })
            let replacement = loadEntity(current, restored.save())!
            current.addEntity(replacement)
            check("restoration exact semantic replacement lacks Core receipt", refuses { _ = try collisions() })
            current.removeEntity(replacement); current.addEntity(restored)
            let alien = loadEntity(foreign, restored.save())!
            current.addEntity(alien)
            check("restoration foreign World collider refuses", refuses { _ = try collisions() })
            current.removeEntity(alien)
            withExtendedLifetime(foreign) {}
            let nether = World(dim: .nether, seed: current.seed)
            let alienDimension = loadEntity(nether, restored.save())!
            current.addEntity(alienDimension)
            check("restoration foreign dimension collider refuses", refuses { _ = try collisions() })
            current.removeEntity(alienDimension)
            withExtendedLifetime(nether) {}
            let orientation = (reader.player.yaw, reader.player.pitch, reader.player.selectedSlot)
            reader.mouseDelta(20, 10); reader.wheelHotbar(1)
            check("restoration reentrant Player input remains halted",
                reader.player.yaw == orientation.0 && reader.player.pitch == orientation.1
                    && reader.player.selectedSlot == orientation.2)
            let playerX = reader.player.x
            reader.player.x += 0.1
            check("restoration changed Player state refuses", refuses { _ = try collisions() })
            reader.player.x = playerX
            let duplicate = loadEntity(current, restored.save())!
            current.addEntity(duplicate)
            check("restoration excess equivalent persisted body refuses", refuses { _ = try collisions() })
            current.removeEntity(duplicate)
            let newcomer = spawnMob(current, "cow", reader.player.x, reader.player.y, reader.player.z)!
            check("restoration newly spawned external body refuses", refuses { _ = try collisions() })
            current.removeEntity(newcomer)
            let transient = LabCoreAgentEntity(world: current, labAgentId: "foreign", physicalId: "foreign")
            transient.setPos(reader.player.x, reader.player.y, reader.player.z)
            current.addEntity(transient)
            check("restoration arbitrary transient body refuses", refuses { _ = try collisions() })
            current.removeEntity(transient)
            let ownIds = try collisions()
            let foot = current.getBlock(target.x, target.y, target.z)
            let support = current.getBlock(target.x, target.y - 1, target.z)
            current.setBlock(target.x, target.y, target.z, Int(cell(B.stone)))
            check("restoration obstruction remains strict",
                assessEntityPlacement(in: current, at: target, bodyWidth: 0.6, bodyHeight: 1.8, ignoringEntityIDs: ownIds).rejections.contains(.bodyObstructed))
            current.setBlock(target.x, target.y, target.z, Int(foot))
            current.setBlock(target.x, target.y - 1, target.z, 0)
            check("restoration support remains strict",
                assessEntityPlacement(in: current, at: target, bodyWidth: 0.6, bodyHeight: 1.8, ignoringEntityIDs: ownIds).rejections.contains(.incompatibleSupport))
            current.setBlock(target.x, target.y - 1, target.z, Int(support))
            for (block, label) in [(B.water, "water"), (B.lava, "lava"), (B.fire, "fire"), (B.powder_snow, "powder snow")] {
                current.setBlock(target.x, target.y, target.z, Int(cell(block)))
                check("restoration \(label) remains strict",
                    assessEntityPlacement(in: current, at: target, bodyWidth: 0.6, bodyHeight: 1.8, ignoringEntityIDs: ownIds).rejections.contains(.incompatibleFluid))
            }
            current.setBlock(target.x, target.y, target.z, Int(foot))
            current.setBlock(target.x, target.y - 1, target.z, Int(cell(B.magma_block)))
            check("restoration hazardous support remains strict",
                assessEntityPlacement(in: current, at: target, bodyWidth: 0.6, bodyHeight: 1.8, ignoringEntityIDs: ownIds).rejections.contains(.incompatibleSupport))
            current.setBlock(target.x, target.y - 1, target.z, Int(support))
            check("restoration attacks conserve original Player and Spider",
                try collisions() == ownIds && current.entities.compactMap { $0 as? Player }.count == 1
                    && current.entities.compactMap { $0 as? Spider }.count == 1)
            return true
        } catch { check("restoration controlled callback succeeds", false, "\(error)"); return false }
    }
    reader.loadWorld(id)
    check("restoration callback completes before progression", reader.worldContinuationReady && retained != nil)
    do {
        _ = try retained?.authenticatedCollisionIDs(in: reader.world, at: [target], bodyWidth: 0.6, bodyHeight: 1.8)
        check("restoration retained scope expires on callback return", false)
    } catch { check("restoration retained scope expires on callback return", true) }
    do {
        _ = try reader.acquireWorldContinuationRestorationAuthority(in: reader.world, boundary: reader.db.worldContinuation(id)!)
        check("restoration ordinary active World cannot acquire authority", false)
    } catch { check("restoration ordinary active World cannot acquire authority", true) }

    let stale = GameCore()
    stale.restoreExternalContinuation = {
        do {
            let boundary = stale.db.worldContinuation(id)!
            let authority = try stale.acquireWorldContinuationRestorationAuthority(in: stale.world, boundary: boundary)
            let wrote = stale.db.putAdvancements(id, [])
            do {
                _ = try authority.authenticatedCollisionIDs(in: stale.world, at: [target], bodyWidth: 0.6, bodyHeight: 1.8)
                check("restoration intervening physical revision refuses", false)
            } catch { check("restoration intervening physical revision refuses", wrote) }
            return false
        } catch { check("restoration stale attack acquires selected boundary first", false, "\(error)"); return false }
    }
    stale.loadWorld(id)
    check("restoration failed callback leaves progression halted", !stale.worldContinuationReady && !stale.worldMutationAllowed)
    writer.db.deleteWorld(id)
}
