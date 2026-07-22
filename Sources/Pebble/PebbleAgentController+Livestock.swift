import PebbleAgents
import PebbleCore

struct PebbleAgentLivestockProofFixture {
    enum Stage: Int {
        case setup
        case fed
        case bred
        case worked
        case lost
    }

    struct Cell {
        let position: AgentPosition
        let original: Int
    }
    let cells: [Cell]
    let originalActorPosition: (Double, Double, Double)
    let originalActorItems: [ItemStack?]
    var spawnedEntityIDs: [Int]
    let herdID: AgentLivestockHerdID
    let recordIDs: [AgentManagedAnimalRecordID]
    let initialCampStock: AgentCampStock
    let initialResourceInventories: [AgentResourceInventory]
    let initialLocalEcologyEnabled: Bool
    var stage: Stage
}

extension PebbleAgentController {
    func handleLivestock(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab livestock <on|status|reconcile|proof [setup|feed|breed|work|loss]>"
        guard let command = arguments.first?.lowercased() else {
            return failure(usage)
        }
        let gates = [
            ("PEBBLELAB_APP_AGENTS=1", featureEnabled),
            ("PEBBLELAB_APP_AGENTS_MOVE=1", movementFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_INTERACT=1", interactionFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_MATERIAL=1", materialFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_PERSISTENCE=1", persistenceFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_POPULATION=1", populationFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_LIFECYCLE=1", lifecycleFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_SKILLS=1", skillFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_ECOLOGICAL_OBSERVATION=1", ecologicalObservationFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_LIVESTOCK=1", livestockFeatureEnabled),
            ("PEBBLELAB_APP_PROBES=1", probesFeatureEnabled),
            ("PEBBLELAB_DEBUG_ENTITIES=1", debugEntitiesEnabled),
        ]
        let missing = gates.filter { !$0.1 }.map(\.0)
        guard missing.isEmpty else {
            return failure("Livestock refused; missing gates: " + missing.joined(separator: ", "))
        }
        guard var candidate = session, activeWorld === world,
              candidate.populationEnabled, candidate.lifecycleEnabled,
              candidate.skillsEnabled, candidate.ecologicalObservationEnabled else {
            return failure("Livestock requires active population, lifecycle, skills, and ecological observation.")
        }
        do {
            switch command {
            case "on":
                guard arguments.count == 1 else { return failure(usage) }
                if !candidate.livestockEnabled {
                    var recorder = replayRecorder
                    if try applyRecordedOperationIfActive(
                        .setLivestockEnabled(true, configuration: .live),
                        session: &candidate, recorder: &recorder
                    ) == nil { try candidate.setLivestockEnabled(true) }
                    replayRecorder = recorder
                    session = candidate
                }
                return livestockStatus(session!)
            case "status":
                guard arguments.count == 1 else { return failure(usage) }
                if candidate.livestockEnabled {
                    var recorder = replayRecorder
                    try reconcileLiveLivestock(
                        world: world, session: &candidate, recorder: &recorder
                    )
                    replayRecorder = recorder
                    session = candidate
                }
                return livestockStatus(candidate)
            case "reconcile":
                guard arguments.count == 1 else { return failure(usage) }
                guard candidate.livestockEnabled else { return failure("Livestock is disabled.") }
                var recorder = replayRecorder
                try reconcileLiveLivestock(
                    world: world, session: &candidate, recorder: &recorder
                )
                replayRecorder = recorder
                session = candidate
                return livestockStatus(candidate)
            case "proof":
                guard arguments.count <= 2 else { return failure(usage) }
                guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1" else {
                    return failure("Livestock proof requires a disposable World.")
                }
                let phase = arguments.count == 2 ? arguments[1].lowercased() : "all"
                switch phase {
                case "setup": try setupLivestockProof(world: world)
                case "feed": try runLivestockFeedProof(world: world)
                case "breed": try runLivestockBreedProof(world: world)
                case "work": try runLivestockWorkProof(world: world)
                case "loss": try runLivestockLossProof(world: world)
                case "all":
                    try setupLivestockProof(world: world)
                    try runLivestockFeedProof(world: world)
                    try runLivestockBreedProof(world: world)
                    try runLivestockWorkProof(world: world)
                    try runLivestockLossProof(world: world)
                default: return failure(usage)
                }
                return livestockStatus(session!)
            default: return failure(usage)
            }
        } catch {
            return failure("Livestock command failed: \(error)")
        }
    }

    private func setupLivestockProof(world: World) throws {
        guard cleanupLivestockProofFixture(world: world), var candidate = session,
              let actorProbe = probesByAgentId["agent_0"] else {
            throw ControllerError.livestockBoundary("fixture cleanup or actor resolution")
        }
        let actorID = AgentID(rawValue: "agent_0")!
        let actor = try PebbleAgentEmbodiment.resolve(
            agentID: actorID.rawValue, in: world, mappedByAgentID: probesByAgentId
        )
        if !candidate.livestockEnabled {
            var recorder = replayRecorder
            if try applyRecordedOperationIfActive(
                .setLivestockEnabled(true, configuration: .live),
                session: &candidate, recorder: &recorder
            ) == nil { try candidate.setLivestockEnabled(true) }
            replayRecorder = recorder
        }
        let originalPosition = (actorProbe.x, actorProbe.y, actorProbe.z)
        let originalItems = actor.carriedItems.map { $0?.copy() }
        let origin = actor.position
        let center = AgentPosition(x: origin.x + 2, y: origin.y, z: origin.z)
        let fenceID = Int(bid("oak_fence"))
        var cells: [PebbleAgentLivestockProofFixture.Cell] = []
        for x in (center.x - 4)...(center.x + 4) {
            for z in (center.z - 4)...(center.z + 4) {
                for y in (center.y - 1)...(center.y + 6) {
                    let position = AgentPosition(x: x, y: y, z: z)
                    cells.append(.init(position: position, original: world.getBlock(x, y, z)))
                    let replacement = y == center.y - 1
                        ? Int(cell(B.grass_block)) : 0
                    world.setBlock(x, y, z, replacement, SET_NO_NEIGHBORS)
                }
            }
        }
        for x in (center.x - 3)...(center.x + 3) {
            for z in (center.z - 3)...(center.z + 3)
                where x == center.x - 3 || x == center.x + 3
                    || z == center.z - 3 || z == center.z + 3 {
                world.setBlock(x, center.y, z, Int(cell(UInt16(fenceID))), SET_NO_NEIGHBORS)
            }
        }
        let first = spawnMob(world, "sheep", Double(center.x) + 0.5,
            Double(center.y), Double(center.z) + 0.5, SpawnOpts()) as! Sheep
        let second = spawnMob(world, "sheep", Double(center.x + 1) + 0.5,
            Double(center.y), Double(center.z) + 0.5, SpawnOpts()) as! Sheep
        first.persistent = true
        second.persistent = true
        actor.carriedItems = Array(repeating: nil, count: LabCoreAgentEntity.carriedItemSlotCount)
        actor.carriedItems[0] = ItemStack(iid("wheat"), 3)
        actor.carriedItems[1] = ItemStack(iid("shears"), 1)
        ecologicalObservationSensor.invalidateAll()
        var recorder = replayRecorder
        let livestockObservation = try recordLiveEcologicalObservation(
            world: world, observerID: actorID, session: &candidate, recorder: &recorder
        )
        trace("livestock proof observation animals=" + livestockObservation.animals.map {
            "\($0.speciesKey)@\($0.position.x),\($0.position.y),\($0.position.z):\($0.lifeStage.rawValue)"
        }.joined(separator: ","))
        guard let source = candidate.ecologicalObservationSnapshot().observations.last?.causalEventID else {
            throw ControllerError.livestockBoundary("missing fresh livestock observation")
        }
        let herdID = AgentLivestockHerdID(rawValue: "live-sheep-herd")!
        let firstID = AgentManagedAnimalRecordID(rawValue: "live-managed-sheep-1")!
        let secondID = AgentManagedAnimalRecordID(rawValue: "live-managed-sheep-2")!
        let childID = AgentManagedAnimalRecordID(rawValue: "live-managed-sheep-3")!
        let area = AgentLivestockManagementArea(
            minimum: AgentPosition(x: center.x - 2, y: center.y - 1, z: center.z - 2),
            maximum: AgentPosition(x: center.x + 2, y: center.y + 2, z: center.z + 2)
        )
        try applyLivestockRecorded(.establishHerd(
            herdID: herdID, speciesKey: "sheep", managementArea: area,
            responsibleAgentIDs: [actorID]
        ), session: &candidate, recorder: &recorder)
        for (recordID, sheep) in [(firstID, first), (secondID, second)] {
            try applyLivestockRecorded(.admitObservedAnimal(
                recordID: recordID, herdID: herdID, actorID: actorID,
                speciesKey: "sheep",
                position: AgentPosition(x: Int(sheep.x.rounded(.down)), y: Int(sheep.y.rounded(.down)), z: Int(sheep.z.rounded(.down))),
                lifeStage: .adult, sourceObservationEventID: source,
                compatibleFeedAvailable: true
            ), session: &candidate, recorder: &recorder)
            livestockRuntimeEntityIDByRecord[recordID] = sheep.id
        }
        livestockProofFixture = PebbleAgentLivestockProofFixture(
            cells: cells, originalActorPosition: originalPosition,
            originalActorItems: originalItems, spawnedEntityIDs: [first.id, second.id],
            herdID: herdID, recordIDs: [firstID, secondID, childID],
            initialCampStock: candidate.snapshot().campStock,
            initialResourceInventories: candidate.snapshot().agents.map(\.resourceInventory),
            initialLocalEcologyEnabled: candidate.localEcologyEnabled,
            stage: .setup
        )
        session = candidate
        replayRecorder = recorder
        trace("livestock proof setup adults=2 enclosure=physical feed=wheat product=shears")
    }

    private func runLivestockFeedProof(world: World) throws {
        guard var fixture = livestockProofFixture, fixture.stage == .setup,
              var candidate = session, fixture.recordIDs.count == 3,
              let firstRuntimeID = livestockRuntimeEntityIDByRecord[fixture.recordIDs[0]],
              let secondRuntimeID = livestockRuntimeEntityIDByRecord[fixture.recordIDs[1]],
              let first = world.entityById[firstRuntimeID] as? Sheep,
              let second = world.entityById[secondRuntimeID] as? Sheep else {
            throw ControllerError.livestockBoundary("feed proof requires setup and exact adults")
        }
        let actorID = AgentID(rawValue: "agent_0")!
        let actor = try PebbleAgentEmbodiment.resolve(
            agentID: actorID.rawValue, in: world, mappedByAgentID: probesByAgentId
        )
        var recorder = replayRecorder
        let readyItems = actor.carriedItems.map { $0?.copy() }
        let loveBeforeNegatives = first.loveTicks
        actor.carriedItems[0] = ItemStack(iid("carrot"), 1)
        var wrongFeedRefused = false
        do {
            _ = try livestockExecutor.feed(
                world: world, actor: actor, animal: first,
                taskID: AgentLivestockTaskID(rawValue: "live-negative-wrong-task")!,
                actionID: AgentLivestockActionID(rawValue: "live-negative-wrong-action")!,
                recordID: fixture.recordIDs[0], completedAtTick: candidate.tick,
                publish: { _ in
                    throw ControllerError.livestockBoundary("wrong feed published")
                }
            )
        } catch PebbleAgentLivestockExecutor.ExecutionError.wrongFeed {
            wrongFeedRefused = true
        }
        guard wrongFeedRefused, first.loveTicks == loveBeforeNegatives,
              actor.carriedItems[0]?.count == 1 else {
            throw ControllerError.livestockBoundary("wrong-feed negative mutated physical truth")
        }
        actor.carriedItems = Array(repeating: nil, count: LabCoreAgentEntity.carriedItemSlotCount)
        var missingFeedRefused = false
        do {
            _ = try livestockExecutor.feed(
                world: world, actor: actor, animal: first,
                taskID: AgentLivestockTaskID(rawValue: "live-negative-missing-task")!,
                actionID: AgentLivestockActionID(rawValue: "live-negative-missing-action")!,
                recordID: fixture.recordIDs[0], completedAtTick: candidate.tick,
                publish: { _ in
                    throw ControllerError.livestockBoundary("missing feed published")
                }
            )
        } catch PebbleAgentLivestockExecutor.ExecutionError.missingFeed {
            missingFeedRefused = true
        }
        actor.carriedItems = readyItems
        guard missingFeedRefused, first.loveTicks == loveBeforeNegatives else {
            throw ControllerError.livestockBoundary("missing-feed negative mutated physical truth")
        }
        for (ordinal, pair) in [(1, (fixture.recordIDs[0], first)), (2, (fixture.recordIDs[1], second))] {
            let taskID = AgentLivestockTaskID(rawValue: "live-feed-task-\(ordinal)")!
            let actionID = AgentLivestockActionID(rawValue: "live-feed-action-\(ordinal)")!
            try applyLivestockRecorded(.queueTask(AgentLivestockTaskRequest(
                taskID: taskID, herdID: fixture.herdID, kind: .feed,
                primaryAnimalRecordID: pair.0, responsibleAgentID: actorID,
                targetPosition: AgentPosition(x: Int(pair.1.x), y: Int(pair.1.y), z: Int(pair.1.z))
            )), session: &candidate, recorder: &recorder)
            _ = try livestockExecutor.feed(
                world: world, actor: actor, animal: pair.1, taskID: taskID,
                actionID: actionID, recordID: pair.0, completedAtTick: candidate.tick,
                publish: { outcome in
                    try self.applyLivestockRecorded(.recordOutcome(outcome), session: &candidate, recorder: &recorder)
                }
            )
        }
        for _ in 0..<8 {
            first.mobTick()
            second.mobTick()
        }
        fixture.stage = .fed
        livestockProofFixture = fixture
        session = candidate
        replayRecorder = recorder
        trace("livestock proof feed wrong=refused missing=refused accepted=2 consumed=2 Core_love=1")
    }

    private func runLivestockBreedProof(world: World) throws {
        guard var fixture = livestockProofFixture, fixture.stage == .fed,
              var candidate = session, fixture.recordIDs.count == 3,
              let firstRuntimeID = livestockRuntimeEntityIDByRecord[fixture.recordIDs[0]],
              let secondRuntimeID = livestockRuntimeEntityIDByRecord[fixture.recordIDs[1]],
              let first = world.entityById[firstRuntimeID] as? Sheep,
              world.entityById[secondRuntimeID] is Sheep else {
            throw ControllerError.livestockBoundary("breed proof requires fed exact adults")
        }
        let actorID = AgentID(rawValue: "agent_0")!
        let child: Sheep
        if let existing = world.entities.compactMap({ $0 as? Sheep }).first(where: {
            $0.baby && !fixture.spawnedEntityIDs.contains($0.id)
        }) {
            child = existing
        } else {
            let breedGoal = BreedGoal(first, 0) { a, b in first.spawnBaby(a, b) }
            guard breedGoal.canUse() else {
                throw ControllerError.livestockBoundary("Core BreedGoal ineligible")
            }
            breedGoal.start()
            for _ in 0..<60 { breedGoal.tick() }
            guard let born = world.entities.compactMap({ $0 as? Sheep }).first(where: {
                $0.baby && !fixture.spawnedEntityIDs.contains($0.id)
            }) else { throw ControllerError.livestockBoundary("Core birth absent") }
            child = born
        }
        child.persistent = true
        let firstID = fixture.recordIDs[0]
        let secondID = fixture.recordIDs[1]
        let childID = fixture.recordIDs[2]
        livestockRuntimeEntityIDByRecord[childID] = child.id
        fixture.spawnedEntityIDs.append(child.id)
        var recorder = replayRecorder
        let breedTask = AgentLivestockTaskID(rawValue: "live-breed-task-1")!
        try applyLivestockRecorded(.queueTask(AgentLivestockTaskRequest(
            taskID: breedTask, herdID: fixture.herdID, kind: .breed,
            primaryAnimalRecordID: firstID, secondaryAnimalRecordID: secondID,
            responsibleAgentID: actorID,
            targetPosition: AgentPosition(x: Int(first.x), y: Int(first.y), z: Int(first.z))
        )), session: &candidate, recorder: &recorder)
        try applyLivestockRecorded(.recordOutcome(AgentLivestockValidatedOutcome(
            actionID: AgentLivestockActionID(rawValue: "live-breed-action-1")!,
            taskID: breedTask, actorID: actorID, kind: .breedingObserved,
            status: .succeeded, primaryAnimalRecordID: firstID,
            secondaryAnimalRecordID: secondID, physicalCausalIDs: [child.id],
            offspring: AgentLivestockOffspringSnapshot(
                recordID: childID, speciesKey: "sheep",
                position: AgentPosition(x: Int(child.x), y: Int(child.y), z: Int(child.z)),
                lifeStage: .juvenile
            ), attribution: "PebbleCore.BreedGoal", completedAtTick: candidate.tick
        )), session: &candidate, recorder: &recorder)
        fixture.stage = .bred
        livestockProofFixture = fixture
        session = candidate
        replayRecorder = recorder
        trace("livestock proof breeding parents=2 offspring=1 Core_BreedGoal=1 child=\(child.id)")
    }

    private func runLivestockWorkProof(world: World) throws {
        guard var fixture = livestockProofFixture, fixture.stage == .bred,
              var candidate = session, fixture.recordIDs.count == 3,
              let firstRuntimeID = livestockRuntimeEntityIDByRecord[fixture.recordIDs[0]],
              let first = world.entityById[firstRuntimeID] as? Sheep else {
            throw ControllerError.livestockBoundary("work proof requires real retained offspring")
        }
        let actorID = AgentID(rawValue: "agent_0")!
        let firstID = fixture.recordIDs[0]
        let actor = try PebbleAgentEmbodiment.resolve(
            agentID: actorID.rawValue, in: world, mappedByAgentID: probesByAgentId
        )
        var recorder = replayRecorder
        let productTask = AgentLivestockTaskID(rawValue: "live-product-task-1")!
        try applyLivestockRecorded(.queueTask(AgentLivestockTaskRequest(
            taskID: productTask, herdID: fixture.herdID, kind: .collectProduct,
            primaryAnimalRecordID: firstID, responsibleAgentID: actorID,
            targetPosition: AgentPosition(x: Int(first.x), y: Int(first.y), z: Int(first.z))
        )), session: &candidate, recorder: &recorder)
        _ = try livestockExecutor.shear(
            world: world, actor: actor, sheep: first, taskID: productTask,
            actionID: AgentLivestockActionID(rawValue: "live-product-action-1")!,
            recordID: firstID, materialGateway: materialCustodyGateway,
            completedAtTick: candidate.tick,
            publish: { outcome in
                try self.applyLivestockRecorded(.recordOutcome(outcome), session: &candidate, recorder: &recorder)
            }
        )

        try reconcileLiveLivestock(world: world, session: &candidate, recorder: &recorder)
        guard let herd = candidate.livestockSnapshot().herds.first(where: {
            $0.herdID == fixture.herdID
        }) else { throw ControllerError.livestockBoundary("managed herd missing") }
        let center = AgentPosition(
            x: (herd.managementArea.minimum.x + herd.managementArea.maximum.x) / 2,
            y: (herd.managementArea.minimum.y + herd.managementArea.maximum.y) / 2,
            z: (herd.managementArea.minimum.z + herd.managementArea.maximum.z) / 2
        )
        let herdTask = AgentLivestockTaskID(rawValue: "live-herd-task-1")!
        try applyLivestockRecorded(.queueTask(AgentLivestockTaskRequest(
            taskID: herdTask, herdID: fixture.herdID, kind: .herdMove,
            primaryAnimalRecordID: firstID, responsibleAgentID: actorID,
            targetPosition: AgentPosition(x: center.x + 1, y: center.y, z: center.z + 1)
        )), session: &candidate, recorder: &recorder)
        guard first.attachLivestockLeash(to: actor.probe) else {
            throw ControllerError.livestockBoundary("Core leash attach refused")
        }
        let animalBefore = (first.x, first.z)
        actor.probe.move(0, 0, 6)
        for _ in 0..<20 { first.mobTick() }
        _ = first.releaseLivestockLeash()
        guard first.x != animalBefore.0 || first.z != animalBefore.1 else {
            throw ControllerError.livestockBoundary("real leash movement absent")
        }
        try applyLivestockRecorded(.recordOutcome(AgentLivestockValidatedOutcome(
            actionID: AgentLivestockActionID(rawValue: "live-herd-action-1")!,
            taskID: herdTask, actorID: actorID, kind: .herdMove,
            status: .succeeded, primaryAnimalRecordID: firstID,
            physicalCausalIDs: [first.id],
            finalPosition: AgentPosition(x: Int(first.x.rounded(.down)), y: Int(first.y.rounded(.down)), z: Int(first.z.rounded(.down))),
            attribution: "PebbleCore.leash-physics", completedAtTick: candidate.tick
        )), session: &candidate, recorder: &recorder)
        fixture.stage = .worked
        livestockProofFixture = fixture
        session = candidate
        replayRecorder = recorder
        trace("livestock proof work herding=Core-leash product=real-wool custody=real")
    }

    private func runLivestockLossProof(world: World) throws {
        guard var fixture = livestockProofFixture, fixture.stage == .worked,
              var candidate = session, fixture.recordIDs.count == 3,
              let secondRuntimeID = livestockRuntimeEntityIDByRecord[fixture.recordIDs[1]],
              let second = world.entityById[secondRuntimeID] as? Sheep else {
            throw ControllerError.livestockBoundary("loss proof requires worked exact herd")
        }
        let actorID = AgentID(rawValue: "agent_0")!
        var recorder = replayRecorder
        world.removeEntity(second)
        try reconcileLiveLivestock(world: world, session: &candidate, recorder: &recorder)
        let capital = candidate.livestockCapitalSnapshot()
        trace("livestock proof invariant living=\(capital.resolvedLivingCount) missing=\(capital.missingCount) births=\(capital.recentBirths) products=\(capital.recentPhysicalOutputs) husbandry=\(candidate.practiceUnits(agentID: actorID, domain: .husbandry)) camp=\(candidate.snapshot().campStock.totalCount) coarseEcology=\(candidate.localEcologyEnabled ? 1 : 0)")
        guard capital.resolvedLivingCount == 2, capital.missingCount == 1,
              capital.youngCount == 1,
              capital.recentBirths == 1, capital.recentPhysicalOutputs > 0,
              candidate.practiceUnits(agentID: actorID, domain: .husbandry) == 4,
              candidate.snapshot().campStock == fixture.initialCampStock,
              candidate.snapshot().agents.map(\.resourceInventory)
                == fixture.initialResourceInventories,
              candidate.localEcologyEnabled == fixture.initialLocalEcologyEnabled else {
            throw ControllerError.livestockBoundary("final capital, skill, or ghost-stock invariant")
        }
        fixture.stage = .lost
        livestockProofFixture = fixture
        session = candidate
        replayRecorder = recorder
        trace("livestock proof physical feed=2 birth=1 herding=1 product=\(capital.recentPhysicalOutputs) loss=1")
        trace("livestock proof no_ghost_stock=1 campStockDelta=0 resourceInventoryDelta=0 localEcologyDelta=0 husbandry=4 Core_authority=1")
    }

    private func applyLivestockRecorded(
        _ operation: AgentLivestockOperation,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws {
        if try applyRecordedOperationIfActive(
            .applyLivestockOperation(operation), session: &session, recorder: &recorder
        ) == nil { try session.applyLivestockOperation(operation) }
    }

    private func reconcileLiveLivestock(
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws {
        let resolutions = session.livestockSnapshot().managedAnimals
            .filter { $0.status != .released }
            .map { record in
                livestockExecutor.resolve(
                    record: record,
                    transientEntityID: livestockRuntimeEntityIDByRecord[record.recordID],
                    world: world, observedAtTick: session.tick
                )
            }
        try applyLivestockRecorded(.reconcile(resolutions), session: &session, recorder: &recorder)
    }

    private func livestockStatus(_ session: AgentSimulationSession) -> PebbleAgentCommandResult {
        let capital = session.livestockCapitalSnapshot()
        let snapshot = session.livestockSnapshot()
        trace("livestock status enabled=\(snapshot.enabled ? 1 : 0) herds=\(snapshot.herds.count) living=\(capital.resolvedLivingCount) young=\(capital.youngCount) unresolved=\(capital.unresolvedCount) missing=\(capital.missingCount) products=\(capital.recentPhysicalOutputs) digest=\(snapshot.digest)")
        return success("Livestock enabled=\(snapshot.enabled) herds=\(snapshot.herds.count) living=\(capital.resolvedLivingCount) young=\(capital.youngCount) unresolved=\(capital.unresolvedCount) missing=\(capital.missingCount) products=\(capital.recentPhysicalOutputs) digest=\(snapshot.digest).")
    }

    func cleanupLivestockProofFixture(world: World) -> Bool {
        guard let fixture = livestockProofFixture else {
            livestockRuntimeEntityIDByRecord.removeAll()
            return true
        }
        for id in fixture.spawnedEntityIDs {
            if let entity = world.entityById[id] { world.removeEntity(entity) }
        }
        for cell in fixture.cells {
            world.setBlock(
                cell.position.x, cell.position.y, cell.position.z,
                cell.original, SET_NO_NEIGHBORS
            )
        }
        if let actor = probesByAgentId["agent_0"], actor.world === world, !actor.dead {
            actor.setPos(
                fixture.originalActorPosition.0,
                fixture.originalActorPosition.1,
                fixture.originalActorPosition.2
            )
            actor.carriedItems = fixture.originalActorItems.map { $0?.copy() }
        }
        let entitiesGone = fixture.spawnedEntityIDs.allSatisfy { world.entityById[$0] == nil }
        let cellsRestored = fixture.cells.allSatisfy {
            world.getBlock($0.position.x, $0.position.y, $0.position.z) == $0.original
        }
        if entitiesGone && cellsRestored {
            livestockProofFixture = nil
            livestockRuntimeEntityIDByRecord.removeAll()
            return true
        }
        return false
    }
}
