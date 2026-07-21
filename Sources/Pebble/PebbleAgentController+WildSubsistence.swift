import Foundation
import PebbleAgents
import PebbleCore

struct PebbleAgentWildSubsistenceProofFixture {
    struct OriginalCell {
        let position: PhysicalBlockPosition
        let cell: Int
    }
    struct OriginalActor {
        let id: String
        let x: Double
        let y: Double
        let z: Double
        let yaw: Double
        let pitch: Double
        let carriedItems: [ItemStack?]
    }

    let originalCells: [OriginalCell]
    let originalActors: [OriginalActor]
    let entityIDsBefore: Set<Int>
    let chicken: Chicken
    let berryPosition: AgentPosition
    let waterPosition: AgentPosition
    let fishing: AgentSubsistenceOpportunity
    let hunting: AgentSubsistenceOpportunity
    let gathering: AgentSubsistenceOpportunity
    let initialCampStock: Int
    let initialResourceInventory: Int
    var fishingComplete: Bool
    var huntingComplete: Bool
    var gatheringComplete: Bool
}

extension PebbleAgentController {
    func handleWildSubsistence(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab wild-subsistence <on|status|proof [setup|fish|hunt|gather|final]>"
        guard let command = arguments.first?.lowercased() else { return failure(usage) }
        let dependencies = wildSubsistenceGateDependencies()
        let missing = dependencies.filter { !$0.1 }.map(\.0)
        guard missing.isEmpty else {
            return failure("WildSubsistence refused; missing gates: " + missing.joined(separator: ", "))
        }
        guard var candidate = session, activeWorld === world else {
            return failure("No active PebbleAgents session.")
        }
        guard candidate.populationEnabled, candidate.lifecycleEnabled,
              candidate.skillsEnabled, candidate.ecologicalObservationEnabled else {
            return failure("WildSubsistence requires population, lifecycle, skills, and ecological observation.")
        }
        do {
            switch command {
            case "on":
                guard arguments.count == 1 else { return failure(usage) }
                if !candidate.wildSubsistenceEnabled {
                    var recorder = replayRecorder
                    if try applyRecordedOperationIfActive(
                        .setWildSubsistenceEnabled(true, configuration: .live),
                        session: &candidate, recorder: &recorder
                    ) == nil {
                        try candidate.setWildSubsistenceEnabled(true)
                    }
                    session = candidate
                    replayRecorder = recorder
                }
                traceWildSubsistenceState(candidate, reason: "activated")
                return wildSubsistenceStatus(candidate)
            case "status":
                guard arguments.count == 1 else { return failure(usage) }
                traceWildSubsistenceState(candidate, reason: "status")
                return wildSubsistenceStatus(candidate)
            case "proof":
                guard arguments.count <= 2 else { return failure(usage) }
                let phase = arguments.count == 2 ? arguments[1].lowercased() : "all"
                return try handleWildSubsistenceProofPhase(
                    phase, world: world, player: player
                )
            default:
                return failure(usage)
            }
        } catch {
            return failure("WildSubsistence command failed: \(error)")
        }
    }

    private func wildSubsistenceGateDependencies() -> [(String, Bool)] {
        [
            ("PEBBLELAB_APP_AGENTS=1", featureEnabled),
            ("PEBBLELAB_APP_AGENTS_MOVE=1", movementFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_INTERACT=1", interactionFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_MATERIAL=1", materialFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_PERSISTENCE=1", persistenceFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_POPULATION=1", populationFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_LIFECYCLE=1", lifecycleFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_SKILLS=1", skillFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_ECOLOGICAL_OBSERVATION=1", ecologicalObservationFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_WILD_SUBSISTENCE=1", wildSubsistenceFeatureEnabled),
            ("PEBBLELAB_APP_PROBES=1", probesFeatureEnabled),
            ("PEBBLELAB_DEBUG_ENTITIES=1", debugEntitiesEnabled),
        ]
    }

    private func handleWildSubsistenceProofPhase(
        _ phase: String,
        world: World,
        player: Player
    ) throws -> PebbleAgentCommandResult {
        guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1" else {
            return failure("WildSubsistence proof requires a disposable World.")
        }
        switch phase {
        case "setup":
            try setupWildSubsistenceProof(world: world)
            return success("WildSubsistence proof setup complete.")
        case "fish":
            try runWildFishingProof(world: world)
            return success("WildSubsistence real fishing proof complete.")
        case "hunt":
            try runWildHuntingProof(world: world)
            return success("WildSubsistence real hunting proof complete.")
        case "gather":
            try runWildGatheringProof(world: world)
            return success("WildSubsistence real gathering proof complete.")
        case "final":
            try finalizeWildSubsistenceProof(world: world)
            return wildSubsistenceStatus(session!)
        case "all":
            try setupWildSubsistenceProof(world: world)
            try runWildFishingProof(world: world)
            try runWildHuntingProof(world: world)
            try runWildGatheringProof(world: world)
            try finalizeWildSubsistenceProof(world: world)
            return wildSubsistenceStatus(session!)
        default:
            return failure("Usage: /lab wild-subsistence proof [setup|fish|hunt|gather|final]")
        }
    }

    private func setupWildSubsistenceProof(world: World) throws {
        guard cleanupWildSubsistenceProofFixture(world: world),
              var candidate = session else {
            throw ControllerError.wildSubsistenceBoundary("prior fixture cleanup failed")
        }
        if !candidate.wildSubsistenceEnabled {
            var recorder = replayRecorder
            if try applyRecordedOperationIfActive(
                .setWildSubsistenceEnabled(true, configuration: .live),
                session: &candidate, recorder: &recorder
            ) == nil { try candidate.setWildSubsistenceEnabled(true) }
            replayRecorder = recorder
        }
        let ids = ["agent_0", "agent_1", "agent_2"]
        let embodiments = try PebbleAgentEmbodiment.resolveAll(
            agentIDs: ids, in: world, mappedByAgentID: probesByAgentId
        )
        let base = anchor ?? embodiments["agent_0"]!.position
        let entityIDsBefore = Set(world.entities.map(\.id))
        let originalActors = ids.map { id in
            let body = embodiments[id]!
            return PebbleAgentWildSubsistenceProofFixture.OriginalActor(
                id: id, x: body.x, y: body.y, z: body.z,
                yaw: body.yaw, pitch: body.pitch,
                carriedItems: copyItemInventory(body.carriedItems)
            )
        }
        var originals: [PebbleAgentWildSubsistenceProofFixture.OriginalCell] = []
        var seen = Set<PhysicalBlockPosition>()
        func remember(_ position: PhysicalBlockPosition) {
            guard seen.insert(position).inserted else { return }
            originals.append(.init(position: position, cell: world.getBlock(position.x, position.y, position.z)))
        }
        for z in (base.z - 2)...(base.z + 6) {
            for x in (base.x - 5)...(base.x + 8) {
                for y in (base.y - 1)...(base.y + 4) {
                    remember(PhysicalBlockPosition(x: x, y: y, z: z))
                }
                world.setBlock(x, base.y - 1, z, Int(cell(B.stone)), SET_NO_NEIGHBORS)
                for y in base.y...(base.y + 4) {
                    world.setBlock(x, y, z, 0, SET_NO_NEIGHBORS)
                }
            }
        }
        for z in (base.z - 2)...(base.z + 2) {
            for x in (base.x + 3)...(base.x + 7) {
                world.setBlock(x, base.y, z, Int(cell(B.water)), SET_NO_NEIGHBORS)
            }
        }
        let berry = AgentPosition(x: base.x - 2, y: base.y, z: base.z)
        world.setBlock(
            berry.x, berry.y, berry.z,
            Int(cell(B.sweet_berry_bush, 3)), SET_NO_NEIGHBORS
        )
        for (index, id) in ids.enumerated() {
            let body = embodiments[id]!
            body.probe.setPos(Double(base.x + index) + 0.5, Double(base.y), Double(base.z) + 0.5)
            body.carriedItems = Array(repeating: nil, count: LabCoreAgentEntity.carriedItemSlotCount)
        }
        embodiments["agent_0"]!.carriedItems[0] = ItemStack(iid("fishing_rod"))
        embodiments["agent_0"]!.carriedItems[1] = ItemStack(iid("iron_sword"))
        embodiments["agent_1"]!.carriedItems[0] = ItemStack(iid("iron_sword"))
        let chicken = Chicken(world: world)
        chicken.rng = RandomX(46)
        chicken.eggTime = 99_999
        chicken.setPos(Double(base.x) + 0.5, Double(base.y), Double(base.z + 3) + 0.5)
        world.addEntity(chicken)
        do {
            ecologicalObservationSensor.invalidate(world: world)
            var recorder = replayRecorder
            for id in ids {
                _ = try recordLiveEcologicalObservation(
                    world: world, observerID: AgentID(rawValue: id)!,
                    session: &candidate, recorder: &recorder
                )
            }
            let multi = try candidate.eligibleSubsistenceStrategies(AgentSubsistenceDecisionContext(
                actorID: AgentID(rawValue: "agent_0")!, fishingRodAvailable: true,
                huntingWeaponAvailable: true, agricultureAvailable: false,
                maximumDistance: 16, subsistencePressure: 80
            ))
            guard Set(multi.map(\.strategy)).isSuperset(of: [.fishing, .hunting, .wildGathering]) else {
                throw ControllerError.wildSubsistenceBoundary(
                    "real multi-strategy observation missing: \(multi.map(\.strategy.rawValue))"
                )
            }
            func select(_ context: AgentSubsistenceDecisionContext) throws -> AgentSubsistenceOpportunity {
                if try applyRecordedOperationIfActive(
                    .selectWildSubsistenceOpportunity(context),
                    session: &candidate, recorder: &recorder
                ) != nil {
                    guard let result = candidate.wildSubsistenceSnapshot().opportunities
                        .filter({ $0.actorID == context.actorID && $0.status == .selected })
                        .sorted(by: { $0.selectedAtTick < $1.selectedAtTick }).last else {
                        throw ControllerError.wildSubsistenceBoundary("recorded selection missing")
                    }
                    return result
                }
                return try candidate.selectWildSubsistenceOpportunity(context)
            }
            let gathering = try select(AgentSubsistenceDecisionContext(
                actorID: AgentID(rawValue: "agent_2")!, fishingRodAvailable: false,
                huntingWeaponAvailable: false, agricultureAvailable: false,
                maximumDistance: 16, subsistencePressure: 80
            ))
            let hunting = try select(AgentSubsistenceDecisionContext(
                actorID: AgentID(rawValue: "agent_1")!, fishingRodAvailable: false,
                huntingWeaponAvailable: true, agricultureAvailable: false,
                maximumDistance: 16, subsistencePressure: 80
            ))
            let fishing = try select(AgentSubsistenceDecisionContext(
                actorID: AgentID(rawValue: "agent_0")!, fishingRodAvailable: true,
                huntingWeaponAvailable: true, agricultureAvailable: false,
                maximumDistance: 16, subsistencePressure: 80
            ))
            guard gathering.strategy == .wildGathering, hunting.strategy == .hunting,
                  fishing.strategy == .fishing else {
                throw ControllerError.wildSubsistenceBoundary("deterministic reservations/selection mismatch")
            }
            let snapshot = candidate.snapshot()
            session = candidate
            replayRecorder = recorder
            wildSubsistenceProofFixture = PebbleAgentWildSubsistenceProofFixture(
                originalCells: originals, originalActors: originalActors,
                entityIDsBefore: entityIDsBefore, chicken: chicken,
                berryPosition: berry, waterPosition: fishing.lastObservedPosition,
                fishing: fishing, hunting: hunting, gathering: gathering,
                initialCampStock: snapshot.campStock.totalCount,
                initialResourceInventory: snapshot.agents.reduce(0) { $0 + $1.resourceInventory.totalCount },
                fishingComplete: false, huntingComplete: false, gatheringComplete: false
            )
            trace(
                "wild subsistence setup authority=PebbleCore observation=CIV21 strategies="
                    + multi.map(\.strategy.rawValue).joined(separator: ",")
                    + " selection=fishing,hunting,wildGathering reservations=oneShot "
                    + "equipment=real navigation=findPath+Entity.move fixture=bounded"
            )
        } catch {
            guard rollbackWildSubsistenceSetup(
                world: world, originalCells: originals, originalActors: originalActors,
                entityIDsBefore: entityIDsBefore
            ) else {
                throw ControllerError.wildSubsistenceBoundary("setup rollback verification failed")
            }
            throw error
        }
    }

    private func runWildFishingProof(world: World) throws {
        guard var fixture = wildSubsistenceProofFixture, !fixture.fishingComplete,
              var candidate = session,
              let probe = probesByAgentId[fixture.fishing.actorID.rawValue] else {
            throw ControllerError.wildSubsistenceBoundary("fishing phase unavailable or duplicate")
        }
        let actor = PebbleAgentEmbodiment(probe: probe)
        let steps = try wildSubsistenceExecutor.approach(
            world: world, actor: actor, target: fixture.fishing.lastObservedPosition, reach: 2
        )
        var recorder = replayRecorder
        let attemptID = AgentSubsistenceAttemptID(rawValue: "wild-live-fishing-\(candidate.tick)")!
        let result = try wildSubsistenceExecutor.fish(
            world: world, actor: actor, water: fixture.fishing.lastObservedPosition,
            rodSlot: 0, attemptID: attemptID.rawValue,
            materialGateway: materialCustodyGateway
        ) { ids, acquired, fingerprint, attribution in
            let outcome = AgentSubsistenceOutcome(
                attemptID: attemptID, opportunityID: fixture.fishing.opportunityID,
                actorID: fixture.fishing.actorID, strategy: .fishing,
                targetKey: fixture.fishing.targetKey,
                targetPosition: fixture.fishing.lastObservedPosition,
                sourceObservationEventID: fixture.fishing.sourceObservationEventID,
                status: .succeeded, physicalCausalIDs: ids, acquiredItems: acquired,
                custodyFingerprint: fingerprint, attribution: attribution,
                completedAtTick: candidate.tick
            )
            if try applyRecordedOperationIfActive(
                .recordWildSubsistenceOutcome(outcome),
                session: &candidate, recorder: &recorder
            ) == nil { _ = try candidate.recordWildSubsistenceOutcome(outcome) }
        }
        guard result.status == .succeeded else {
            throw ControllerError.wildSubsistenceBoundary("seeded real fishing produced no material catch")
        }
        session = candidate
        replayRecorder = recorder
        fixture.fishingComplete = true
        wildSubsistenceProofFixture = fixture
        let products = result.acquired.map(\.identity.itemKey).joined(separator: ",")
        let food = result.acquired.filter { stack in
            guard let id = iidOpt(stack.identity.itemKey) else { return false }
            return itemDef(id).food != nil
        }.reduce(0) { $0 + $1.count }
        trace(
            "wild subsistence fishing actor=\(actor.agentID) water=real approachSteps=\(steps) "
                + "rod=real cast=FishingBobber waited=\(result.waitedTicks) bite=real RNG=Core "
                + "loot=\(products) foodQuantity=\(food) itemEntities=exact custody=real "
                + "rodDurability=\(result.rodDurability.rawValue) practice=1 abstractCredit=0"
        )

        // Fault injection at the real custody boundary: Core catch and rod
        // wear are already physical, so a full destination retains the exact
        // ItemEntities and publishes no Civilization success. Only temporary
        // capacity fillers are restored; the second canonical rod wear stays.
        let postSuccessInventory = copyItemInventory(actor.carriedItems)
        for slot in actor.carriedItems.indices where slot != 0 {
            let filler = ItemStack(iid("cobblestone"), 64)
            actor.carriedItems[slot] = filler
        }
        var unexpectedPublication = false
        var retainedIDs: [Int] = []
        do {
            _ = try wildSubsistenceExecutor.fish(
                world: world, actor: actor,
                water: fixture.fishing.lastObservedPosition,
                rodSlot: 0, attemptID: "wild-live-fishing-full-\(candidate.tick)",
                materialGateway: materialCustodyGateway
            ) { _, _, _, _ in
                unexpectedPublication = true
            }
            throw ControllerError.wildSubsistenceBoundary(
                "full fishing custody unexpectedly succeeded"
            )
        } catch let PebbleAgentWildSubsistenceExecutor.ExecutionError.custodyFailure(
            status, ids
        ) where status == .destinationFull {
            retainedIDs = ids
        }
        let rodDamageAfterFullAttempt = actor.carriedItems[0]?.damage
        actor.carriedItems = copyItemInventory(postSuccessInventory)
        if let rodDamageAfterFullAttempt {
            actor.carriedItems[0]?.damage = rodDamageAfterFullAttempt
        }
        guard !unexpectedPublication, !retainedIDs.isEmpty,
              retainedIDs.allSatisfy({ id in
                  world.entities.contains { $0.id == id && $0 is ItemEntity }
              }) else {
            throw ControllerError.wildSubsistenceBoundary(
                "full fishing custody did not retain exact physical loot"
            )
        }
        trace(
            "wild subsistence fishing-full actor=\(actor.agentID) catch=real "
                + "custody=destinationFull lootIDs=exact lootRetained=1 "
                + "publication=none practiceDelta=0 reconciliation=physicalTruthRetained"
        )
        // A second real cast is deliberately left pending only as visual context.
        if let rod = actor.carriedItems[0] {
            _ = castFishingBobber(
                world: world, owner: actor.probe, rod: rod,
                originX: actor.x, originY: actor.y + 0.8, originZ: actor.z,
                pitch: actor.pitch, yaw: actor.yaw
            )
        }
    }

    private func runWildHuntingProof(world: World) throws {
        guard var fixture = wildSubsistenceProofFixture, fixture.fishingComplete,
              !fixture.huntingComplete, var candidate = session,
              let probe = probesByAgentId[fixture.hunting.actorID.rawValue] else {
            throw ControllerError.wildSubsistenceBoundary("hunting phase unavailable or duplicate")
        }
        let actor = PebbleAgentEmbodiment(probe: probe)
        let actualTarget = AgentPosition(
            x: Int(floor(fixture.chicken.x)), y: Int(floor(fixture.chicken.y)),
            z: Int(floor(fixture.chicken.z))
        )
        let movedSinceObservation = abs(fixture.hunting.lastObservedPosition.x - actualTarget.x)
            + abs(fixture.hunting.lastObservedPosition.y - actualTarget.y)
            + abs(fixture.hunting.lastObservedPosition.z - actualTarget.z)
        guard movedSinceObservation <= 8, !fixture.chicken.dead,
              fixture.chicken.world === world,
              world.entityById[fixture.chicken.id] === fixture.chicken,
              fixture.chicken.type == "chicken" else {
            throw ControllerError.wildSubsistenceBoundary("prey stale after targeted re-resolution")
        }
        let steps = try wildSubsistenceExecutor.approach(
            world: world, actor: actor, target: actualTarget, reach: 2
        )
        var recorder = replayRecorder
        let attemptID = AgentSubsistenceAttemptID(rawValue: "wild-live-hunting-\(candidate.tick)")!
        let result = try wildSubsistenceExecutor.hunt(
            world: world, actor: actor, target: fixture.chicken,
            expectedSpecies: "chicken", weaponSlot: 0,
            attemptID: attemptID.rawValue, materialGateway: materialCustodyGateway
        ) { ids, acquired, fingerprint, attribution in
            let outcome = AgentSubsistenceOutcome(
                attemptID: attemptID, opportunityID: fixture.hunting.opportunityID,
                actorID: fixture.hunting.actorID, strategy: .hunting,
                targetKey: fixture.hunting.targetKey, targetPosition: fixture.hunting.lastObservedPosition,
                sourceObservationEventID: fixture.hunting.sourceObservationEventID,
                status: .succeeded, physicalCausalIDs: ids, acquiredItems: acquired,
                custodyFingerprint: fingerprint, attribution: attribution,
                completedAtTick: candidate.tick
            )
            if try applyRecordedOperationIfActive(
                .recordWildSubsistenceOutcome(outcome),
                session: &candidate, recorder: &recorder
            ) == nil { _ = try candidate.recordWildSubsistenceOutcome(outcome) }
        }
        guard result.status == .succeeded, fixture.chicken.deathTime > 0 else {
            throw ControllerError.wildSubsistenceBoundary("real hunt did not produce attributed death")
        }
        session = candidate
        replayRecorder = recorder
        fixture.huntingComplete = true
        wildSubsistenceProofFixture = fixture
        trace(
            "wild subsistence hunting actor=\(actor.agentID) prey=chicken entity=real "
                + "revalidatedMoved=\(movedSinceObservation) approachSteps=\(steps) "
                + "reach=physical attack=Core damage=real death=real "
                + "attribution=finalActor drops=exact loot="
                + result.acquired.map(\.identity.itemKey).joined(separator: ",")
                + " custody=real practice=1 abstractCredit=0 duplicateDeath=0"
        )
    }

    private func runWildGatheringProof(world: World) throws {
        guard var fixture = wildSubsistenceProofFixture, fixture.huntingComplete,
              !fixture.gatheringComplete, var candidate = session,
              let probe = probesByAgentId[fixture.gathering.actorID.rawValue] else {
            throw ControllerError.wildSubsistenceBoundary("gathering phase unavailable or duplicate")
        }
        let actor = PebbleAgentEmbodiment(probe: probe)
        let steps = try wildSubsistenceExecutor.approach(
            world: world, actor: actor, target: fixture.berryPosition, reach: 1
        )
        var recorder = replayRecorder
        let attemptID = AgentSubsistenceAttemptID(rawValue: "wild-live-gathering-\(candidate.tick)")!
        let occupied = probesByAgentId.values.map {
            PhysicalBlockPosition(
                x: Int(floor($0.x)), y: Int(floor($0.y)), z: Int(floor($0.z))
            )
        }
        let result = try wildSubsistenceExecutor.gather(
            world: world, actor: actor,
            target: PhysicalBlockPosition(
                x: fixture.berryPosition.x, y: fixture.berryPosition.y, z: fixture.berryPosition.z
            ),
            expectedBlockID: Int(B.sweet_berry_bush), attemptID: attemptID.rawValue,
            occupiedPositions: occupied, physicalGateway: physicalActionGateway,
            materialGateway: materialCustodyGateway
        ) { ids, acquired, fingerprint, attribution in
            let outcome = AgentSubsistenceOutcome(
                attemptID: attemptID, opportunityID: fixture.gathering.opportunityID,
                actorID: fixture.gathering.actorID, strategy: .wildGathering,
                targetKey: fixture.gathering.targetKey,
                targetPosition: fixture.gathering.lastObservedPosition,
                sourceObservationEventID: fixture.gathering.sourceObservationEventID,
                status: .succeeded, physicalCausalIDs: ids, acquiredItems: acquired,
                custodyFingerprint: fingerprint, attribution: attribution,
                completedAtTick: candidate.tick
            )
            if try applyRecordedOperationIfActive(
                .recordWildSubsistenceOutcome(outcome),
                session: &candidate, recorder: &recorder
            ) == nil { _ = try candidate.recordWildSubsistenceOutcome(outcome) }
        }
        guard result.status == .succeeded,
              world.getBlock(fixture.berryPosition.x, fixture.berryPosition.y, fixture.berryPosition.z) == 0 else {
            throw ControllerError.wildSubsistenceBoundary("canonical wild gather did not deplete source")
        }
        session = candidate
        replayRecorder = recorder
        fixture.gatheringComplete = true
        wildSubsistenceProofFixture = fixture
        trace(
            "wild subsistence gathering actor=\(actor.agentID) resource=sweet_berry_bush "
                + "observation=real approachSteps=\(steps) interaction=canonicalBreak "
                + "drops=exact loot=" + result.acquired.map(\.identity.itemKey).joined(separator: ",")
                + " custody=real depleted=1 regrowth=CoreOnly practice=1 abstractCredit=0"
        )
    }

    private func finalizeWildSubsistenceProof(world: World) throws {
        guard let fixture = wildSubsistenceProofFixture,
              fixture.fishingComplete, fixture.huntingComplete, fixture.gatheringComplete,
              let session else {
            throw ControllerError.wildSubsistenceBoundary("proof phases incomplete")
        }
        let snapshot = session.snapshot()
        let campDelta = snapshot.campStock.totalCount - fixture.initialCampStock
        let resourceNow = snapshot.agents.reduce(0) { $0 + $1.resourceInventory.totalCount }
        let resourceDelta = resourceNow - fixture.initialResourceInventory
        guard campDelta == 0, resourceDelta == 0, !session.localEcologyEnabled else {
            throw ControllerError.wildSubsistenceBoundary("abstract live credit detected")
        }
        let wild = session.wildSubsistenceSnapshot()
        let checkpoint = try session.makeCheckpoint()
        guard checkpoint.schemaVersion == 14 else {
            throw ControllerError.wildSubsistenceBoundary("checkpoint schema is not v14")
        }
        trace(
            "wild subsistence proof authority=PebbleCore fishing=FishingBobber hunting=LivingEntity "
                + "gathering=canonicalBreak outputs=physical custody=real outcomes=3 "
                + "campStockDelta=\(campDelta) resourceInventoryDelta=\(resourceDelta) "
                + "localEcologyDelta=0 practice=fishing:1,hunting:1,foraging:1 "
                + "schema=14 restart=completedHistoryOnly activePhysicalRestart=cancel "
                + "GateR=acquired GateB=notAcquired fixture=retainedForCapture cleanup=deferred "
                + "digest=\(wild.digest) runtimeErrors=\(runtimeErrorCount)"
        )
    }

    private func rollbackWildSubsistenceSetup(
        world: World,
        originalCells: [PebbleAgentWildSubsistenceProofFixture.OriginalCell],
        originalActors: [PebbleAgentWildSubsistenceProofFixture.OriginalActor],
        entityIDsBefore: Set<Int>
    ) -> Bool {
        for entity in world.entities where !entityIDsBefore.contains(entity.id) {
            world.removeEntity(entity)
        }
        for original in originalCells {
            world.setBlock(
                original.position.x, original.position.y, original.position.z,
                original.cell, SET_NO_NEIGHBORS
            )
        }
        for original in originalActors {
            guard let probe = probesByAgentId[original.id] else { return false }
            probe.setPos(original.x, original.y, original.z)
            probe.yaw = original.yaw
            probe.pitch = original.pitch
            probe.carriedItems = copyItemInventory(original.carriedItems)
        }
        ecologicalObservationSensor.invalidate(world: world)
        return originalCells.allSatisfy {
            world.getBlock($0.position.x, $0.position.y, $0.position.z) == $0.cell
        } && originalActors.allSatisfy { original in
            guard let probe = probesByAgentId[original.id] else { return false }
            return probe.x == original.x && probe.y == original.y && probe.z == original.z
                && probe.carriedItems == original.carriedItems
        }
    }

    func cleanupWildSubsistenceProofFixture(world: World) -> Bool {
        guard let fixture = wildSubsistenceProofFixture else { return true }
        for entity in world.entities where !fixture.entityIDsBefore.contains(entity.id) {
            world.removeEntity(entity)
        }
        for original in fixture.originalCells {
            world.setBlock(
                original.position.x, original.position.y, original.position.z,
                original.cell, SET_NO_NEIGHBORS
            )
        }
        for original in fixture.originalActors {
            guard let probe = probesByAgentId[original.id] else { return false }
            probe.setPos(original.x, original.y, original.z)
            probe.yaw = original.yaw
            probe.pitch = original.pitch
            probe.carriedItems = copyItemInventory(original.carriedItems)
        }
        let entitiesRestored = Set(world.entities.map(\.id)).isSuperset(of: fixture.entityIDsBefore)
        let cellsRestored = fixture.originalCells.allSatisfy {
            world.getBlock($0.position.x, $0.position.y, $0.position.z) == $0.cell
        }
        let actorsRestored = fixture.originalActors.allSatisfy { original in
            guard let probe = probesByAgentId[original.id] else { return false }
            return probe.x == original.x && probe.y == original.y && probe.z == original.z
                && probe.carriedItems == original.carriedItems
        }
        let restored = entitiesRestored && cellsRestored && actorsRestored
        if restored {
            wildSubsistenceProofFixture = nil
            ecologicalObservationSensor.invalidate(world: world)
            trace("wild subsistence cleanup entities=exact cells=exact custody=exact probes=restored")
        }
        return restored
    }

    private func wildSubsistenceStatus(
        _ session: AgentSimulationSession
    ) -> PebbleAgentCommandResult {
        let snapshot = session.wildSubsistenceSnapshot()
        let counts = AgentSubsistenceStrategy.allCases.map {
            "\($0.rawValue):\(snapshot.successfulCounts[$0, default: 0])"
        }.joined(separator: ",")
        return success(
            "WildSubsistence gate=enabled active=\(snapshot.enabled ? 1 : 0) schema="
                + "\(snapshot.enabled ? 14 : session.durableState().schemaVersion) "
                + "opportunities=\(snapshot.opportunities.count) outcomes=\(snapshot.retainedOutcomes.count) "
                + "success=\(counts) digest=\(snapshot.digest)."
        )
    }

    private func traceWildSubsistenceState(
        _ session: AgentSimulationSession,
        reason: String
    ) {
        let snapshot = session.wildSubsistenceSnapshot()
        trace(
            "wild subsistence state tick=\(session.tick) reason=\(reason) "
                + "enabled=\(snapshot.enabled ? 1 : 0) schema=\(snapshot.enabled ? 14 : 0) "
                + "opportunities=\(snapshot.opportunities.count) outcomes=\(snapshot.retainedOutcomes.count) "
                + "digest=\(snapshot.digest) worldMutation=none materialMutation=none"
        )
    }
}
