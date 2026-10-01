import Foundation
import PebbleAgents
import PebbleCore

/// Explicitly disposable fault/rollback evidence for the preserving harvest.
/// This is never used as normal-product acceptance evidence.
enum PebbleIncrement07FaultHarness {
    static func runIfRequested(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> Int32? {
        guard environment["PEBBLELAB_PS01_INCREMENT07_FAULT_MATRIX"] == "1"
        else { return nil }
        do {
            guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1",
                  let fixedHome = environment["CFFIXED_USER_HOME"],
                  fixedHome.hasPrefix("/tmp/")
                    || fixedHome.hasPrefix("/private/tmp/") else {
                throw FaultError.invalidConfiguration
            }
            let game = GameCore()
            let controller = PebbleAgentController()
            controller.worldSideReceiptDatabase = game.db
            game.physicalSimulationCoverageProvider = { [weak controller] world in
                controller?.physicalSimulationCoverageRequest(for: world) ?? .inactive
            }
            game.prepareExternalLifecycleState = { [weak controller, weak game] in
                guard let controller, let game else { return false }
                guard game.hasWorld() else {
                    return controller.session == nil && controller.activeWorld == nil
                }
                return controller.prepareForLifecyclePersistence(world: game.world)
            }
            game.finalizeExternalLifecycleState = { [weak controller] in
                controller?.finalizeLifecycleAfterPersistence()
            }
            game.createWorld(
                name: "PS01 Increment 07 disposable fault matrix",
                seedText: "46",
                mode: GameMode.survival,
                difficulty: 2
            )
            guard game.hasWorld(), let worldID = game.worldRec?.id else {
                throw FaultError.worldUnavailable
            }
            while game.world.time < 52 {
                _ = game.frame(dtMs: TICK_MS)
                let deadline = Date(timeIntervalSinceNow: 60)
                while game.physicalSimulationCoverageRuntimeDiagnostics(
                    for: game.world
                ).totalGenerationJobsInFlight > 0 {
                    guard Date() < deadline else {
                        throw FaultError.generationTimeout
                    }
                    _ = RunLoop.main.run(
                        mode: .default,
                        before: Date(timeIntervalSinceNow: 0.005)
                    )
                }
            }
            let started = controller.start(
                world: game.world,
                player: game.player,
                founders: try PebbleNormalFounderProfile(count: 20)
            )
            guard started.succeeded else {
                throw FaultError.controllerRefused(started.message)
            }
            controller.persistenceWorldID = worldID
            controller.persistenceDimension = game.dim.rawValue
            let proof = try controller.runIncrement07PhysicalMatrix(
                world: game.world,
                player: game.player
            )
            _ = controller.stop(
                reason: "increment 07 fault proof complete",
                fallbackWorld: game.world
            )
            guard game.exitToTitle() else { throw FaultError.cleanupRefused }
            game.deleteWorld(worldID)
            print(
                "[ps01-i07-fault-matrix] PASS fixtureEvidence=1 "
                    + "normalProductEvidence=0 \(proof)"
            )
            fflush(stdout)
            return 0
        } catch {
            fputs("[ps01-i07-fault-matrix] FAIL \(error)\n", stderr)
            return 1
        }
    }

    private enum FaultError: Error, CustomStringConvertible {
        case invalidConfiguration
        case worldUnavailable
        case generationTimeout
        case controllerRefused(String)
        case cleanupRefused

        var description: String {
            switch self {
            case .invalidConfiguration: return "invalid configuration"
            case .worldUnavailable: return "World unavailable"
            case .generationTimeout: return "chunk generation timeout"
            case let .controllerRefused(reason): return "controller refused: \(reason)"
            case .cleanupRefused: return "cleanup refused"
            }
        }
    }
}


extension PebbleAgentController {
    func runIncrement07PhysicalMatrix(
        world activeWorld: World,
        player: Player
    ) throws -> String {
        enum InjectedPublicationError: Error { case rejected }
        let mature = Int(cell(B.sweet_berry_bush, 3))
        let target = PhysicalBlockPosition(x: 1, y: 64, z: 0)

        func fixture(
            actorID: String,
            actorX: Int = 0,
            targetCell: Int = Int(cell(B.sweet_berry_bush, 3))
        ) -> (World, LabCoreAgentEntity) {
            let world = World(dim: .overworld, seed: 46)
            let chunk = Chunk(
                cx: actorX >> 4, cz: 0,
                minY: world.info.minY, height: world.info.height
            )
            chunk.status = .lit
            world.setChunk(chunk)
            for x in max(0, actorX - 1)...min(15, actorX + 2) {
                world.setBlock(x, 63, 0, Int(cell(B.stone)), SET_SILENT)
            }
            if (target.x >> 4) == (actorX >> 4) {
                world.setBlock(
                    target.x, target.y, target.z, targetCell, SET_SILENT
                )
            }
            let actor = LabCoreAgentEntity(
                world: world, labAgentId: actorID, physicalId: actorID
            )
            actor.setPos(Double(actorX) + 0.5, 64, 0.5)
            world.addEntity(actor)
            return (world, actor)
        }

        func request(
            actorID: String,
            at position: PhysicalBlockPosition = PhysicalBlockPosition(
                x: 1, y: 64, z: 0
            ),
            expectedCell: Int = Int(cell(B.sweet_berry_bush, 3)),
            attempt: String
        ) -> PebbleAgentSweetBerryHarvestRequest {
            PebbleAgentSweetBerryHarvestRequest(
                actorID: actorID,
                target: position,
                expectedCell: expectedCell,
                directActionRandomness: PebbleAgentDirectActionRandomness(
                    operationDomain: 0x5042_4741,
                    stableAttemptID: attempt
                )
            )
        }

        func inventoryEquals(
            _ lhs: [ItemStack?], _ rhs: [ItemStack?]
        ) -> Bool {
            lhs.elementsEqual(rhs, by: { left, right in
                switch (left, right) {
                case (nil, nil): return true
                case let (a?, b?): return a == b
                default: return false
                }
            })
        }

        // Two hungry cognitive observers share one source. The pure focused
        // suite proves only one opportunity is admitted. Here both physical
        // actors revalidate the same state so a stale second attempt cannot
        // duplicate the source, drops, custody, or publication.
        let contentionWorld = World(dim: .overworld, seed: 46)
        let contentionChunk = Chunk(
            cx: 0, cz: 0, minY: contentionWorld.info.minY,
            height: contentionWorld.info.height
        )
        contentionChunk.status = .lit
        contentionWorld.setChunk(contentionChunk)
        for x in 0...2 {
            contentionWorld.setBlock(
                x, 63, 0, Int(cell(B.stone)), SET_SILENT
            )
        }
        contentionWorld.setBlock(1, 64, 0, mature, SET_SILENT)
        let winner = LabCoreAgentEntity(
            world: contentionWorld,
            labAgentId: "increment07-contender-a",
            physicalId: "increment07-contender-a"
        )
        winner.setPos(0.5, 64, 0.5)
        contentionWorld.addEntity(winner)
        let loser = LabCoreAgentEntity(
            world: contentionWorld,
            labAgentId: "increment07-contender-b",
            physicalId: "increment07-contender-b"
        )
        loser.setPos(2.5, 64, 0.5)
        contentionWorld.addEntity(loser)
        let qualification = edibleSweetBerryHarvestQualification(
            for: mature
        )!
        let evidence = AgentObservedEdibleSourceEvidence(
            canonicalMaterialName: qualification.canonicalMaterialName,
            physicalSourceFingerprint: pebbleAgentEdibleSourceFingerprint(
                sourceCell: qualification.sourceCell,
                blockName: qualification.blockName,
                canonicalMaterialName: qualification.canonicalMaterialName
            )
        )
        let subsistence = PebbleAgentWildSubsistenceExecutor()
        let contentionPhysical = PebbleAgentPhysicalActionGateway()
        let contentionCustody = PebbleAgentMaterialCustodyGateway()
        var successPublications = 0
        let first = try subsistence.gather(
            world: contentionWorld,
            actor: PebbleAgentEmbodiment(probe: winner),
            target: target,
            expectedCell: mature,
            edibleSourceEvidence: evidence,
            attemptID: "increment07-contention-a",
            occupiedPositions: [],
            physicalGateway: contentionPhysical,
            materialGateway: contentionCustody
        ) { _, _, _, _ in successPublications += 1 }
        var staleLoser = false
        do {
            _ = try subsistence.gather(
                world: contentionWorld,
                actor: PebbleAgentEmbodiment(probe: loser),
                target: target,
                expectedCell: mature,
                edibleSourceEvidence: evidence,
                attemptID: "increment07-contention-b",
                occupiedPositions: [],
                physicalGateway: contentionPhysical,
                materialGateway: contentionCustody
            ) { _, _, _, _ in successPublications += 1 }
        } catch PebbleAgentWildSubsistenceExecutor.ExecutionError.staleWorld {
            staleLoser = true
        }
        let firstQuantity = first.acquired.reduce(0) { $0 + $1.count }
        let winnerQuantity = winner.carriedItems.compactMap { $0 }.filter {
            itemDef($0.id).name == "sweet_berries"
        }.reduce(0) { $0 + $1.count }
        guard first.status == .succeeded,
              staleLoser,
              successPublications == 1,
              contentionWorld.getBlock(1, 64, 0)
                == Int(cell(B.sweet_berry_bush, 1)),
              first.physicalCausalIDs.count == 1,
              firstQuantity == winnerQuantity,
              loser.carriedItems.allSatisfy({ $0 == nil }),
              contentionWorld.entities.compactMap({ $0 as? ItemEntity }).isEmpty
        else {
            throw ControllerError.feedbackBoundary(
                "same-source physical contention duplicated or misreported"
            )
        }

        let staleFixture = fixture(
            actorID: "increment07-stale", targetCell: Int(cell(B.sweet_berry_bush, 2))
        )
        let stale = PebbleAgentPhysicalActionGateway().harvestSweetBerryBush(
            world: staleFixture.0,
            actor: staleFixture.1,
            request: request(
                actorID: staleFixture.1.labAgentId,
                attempt: "increment07-stale"
            ),
            occupiedPositions: []
        )

        let deadFixture = fixture(actorID: "increment07-dead")
        deadFixture.1.dead = true
        let dead = PebbleAgentPhysicalActionGateway().harvestSweetBerryBush(
            world: deadFixture.0,
            actor: deadFixture.1,
            request: request(
                actorID: deadFixture.1.labAgentId,
                attempt: "increment07-dead"
            ),
            occupiedPositions: []
        )

        let farFixture = fixture(actorID: "increment07-far")
        let farTarget = PhysicalBlockPosition(x: 2, y: 64, z: 0)
        farFixture.0.setBlock(2, 64, 0, mature, SET_SILENT)
        let far = PebbleAgentPhysicalActionGateway().harvestSweetBerryBush(
            world: farFixture.0,
            actor: farFixture.1,
            request: request(
                actorID: farFixture.1.labAgentId,
                at: farTarget,
                attempt: "increment07-far"
            ),
            occupiedPositions: []
        )

        let unavailableFixture = fixture(
            actorID: "increment07-unavailable", actorX: 15
        )
        let unavailableTarget = PhysicalBlockPosition(x: 16, y: 64, z: 0)
        let unavailable = PebbleAgentPhysicalActionGateway().harvestSweetBerryBush(
            world: unavailableFixture.0,
            actor: unavailableFixture.1,
            request: request(
                actorID: unavailableFixture.1.labAgentId,
                at: unavailableTarget,
                attempt: "increment07-unavailable"
            ),
            occupiedPositions: []
        )
        guard stale.status == .staleTarget,
              stale.failure == .targetChanged,
              dead.status == .refused,
              dead.failure == .invalidActor,
              far.status == .refused,
              far.failure == .outOfReach,
              unavailable.status == .refused,
              unavailable.failure == .chunkUnavailable else {
            throw ControllerError.feedbackBoundary(
                "pre-mutation physical refusal matrix diverged"
            )
        }

        let rejectedFixture = fixture(actorID: "increment07-rejected")
        gameRng = RandomX(0x8800_1144)
        let rejectedOuter = gameRng
        let rejected = PebbleAgentPhysicalActionGateway().harvestSweetBerryBush(
            world: rejectedFixture.0,
            actor: rejectedFixture.1,
            request: request(
                actorID: rejectedFixture.1.labAgentId,
                attempt: "increment07-rejected"
            ),
            occupiedPositions: [],
            verifyAfterMutation: { false }
        )
        guard rejected.status == .verificationFailure,
              rejected.failure == .postMutationRejected,
              rejectedFixture.0.getBlock(1, 64, 0) == mature,
              rejectedFixture.0.entities.compactMap({ $0 as? ItemEntity }).isEmpty,
              gameRng == rejectedOuter else {
            throw ControllerError.feedbackBoundary(
                "post-mutation rejection did not compensate exactly"
            )
        }

        let missingFixture = fixture(actorID: "increment07-missing-entity")
        gameRng = RandomX(0x8800_1144)
        let missingOuter = gameRng
        let missing = PebbleAgentPhysicalActionGateway().harvestSweetBerryBush(
            world: missingFixture.0,
            actor: missingFixture.1,
            request: request(
                actorID: missingFixture.1.labAgentId,
                attempt: "increment07-missing-entity"
            ),
            occupiedPositions: [],
            acquireDrops: { ids in
                for id in ids {
                    if let entity = missingFixture.0.entityById[id] {
                        missingFixture.0.removeEntity(entity)
                    }
                }
                return false
            }
        )
        guard missing.status == .verificationFailure,
              missingFixture.0.getBlock(1, 64, 0) == mature,
              missingFixture.0.entities.compactMap({ $0 as? ItemEntity }).isEmpty,
              gameRng == missingOuter else {
            throw ControllerError.feedbackBoundary(
                "missing ItemEntity mismatch did not compensate exactly"
            )
        }

        let fullFixture = fixture(actorID: "increment07-full")
        for slot in fullFixture.1.carriedItems.indices {
            fullFixture.1.carriedItems[slot] = ItemStack(iid("stone"), 64)
        }
        let fullBefore = copyItemInventory(fullFixture.1.carriedItems)
        gameRng = RandomX(0x8800_1144)
        let fullOuter = gameRng
        var custodyFull = false
        do {
            _ = try subsistence.gather(
                world: fullFixture.0,
                actor: PebbleAgentEmbodiment(probe: fullFixture.1),
                target: target,
                expectedCell: mature,
                edibleSourceEvidence: evidence,
                attemptID: "increment07-full",
                occupiedPositions: [],
                physicalGateway: PebbleAgentPhysicalActionGateway(),
                materialGateway: PebbleAgentMaterialCustodyGateway()
            ) { _, _, _, _ in }
        } catch PebbleAgentWildSubsistenceExecutor.ExecutionError
            .custodyFailure(.destinationFull, _) {
            custodyFull = true
        }
        guard custodyFull,
              fullFixture.0.getBlock(1, 64, 0) == mature,
              inventoryEquals(fullFixture.1.carriedItems, fullBefore),
              fullFixture.0.entities.compactMap({ $0 as? ItemEntity }).isEmpty,
              gameRng == fullOuter else {
            throw ControllerError.feedbackBoundary(
                "full-custody refusal did not compensate exactly"
            )
        }

        let publicationFixture = fixture(actorID: "increment07-publication")
        gameRng = RandomX(0x8800_1144)
        let publicationOuter = gameRng
        var publicationRejected = false
        do {
            _ = try subsistence.gather(
                world: publicationFixture.0,
                actor: PebbleAgentEmbodiment(probe: publicationFixture.1),
                target: target,
                expectedCell: mature,
                edibleSourceEvidence: evidence,
                attemptID: "increment07-publication",
                occupiedPositions: [],
                physicalGateway: PebbleAgentPhysicalActionGateway(),
                materialGateway: PebbleAgentMaterialCustodyGateway()
            ) { _, _, _, _ in throw InjectedPublicationError.rejected }
        } catch InjectedPublicationError.rejected {
            publicationRejected = true
        }
        guard publicationRejected,
              publicationFixture.0.getBlock(1, 64, 0) == mature,
              publicationFixture.1.carriedItems.allSatisfy({ $0 == nil }),
              publicationFixture.0.entities.compactMap({ $0 as? ItemEntity }).isEmpty,
              gameRng == publicationOuter else {
            throw ControllerError.feedbackBoundary(
                "cognitive publication rejection did not compensate exactly"
            )
        }

        let custodyFixture = fixture(actorID: "increment07-custody")
        custodyFixture.0.setBlock(1, 64, 0, 0, SET_SILENT)
        let item = ItemEntity(world: custodyFixture.0, bobOffset: 0.25)
        item.stack = ItemStack(iid("sweet_berries"), 2)
        item.setPos(1.5, 64, 0.5)
        custodyFixture.0.addEntity(item)
        let source = PebbleAgentItemEntityCustodyEndpoint(
            spawnedItemEntityIDs: [item.id], world: custodyFixture.0
        )!
        let destination = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            custodyFixture.1, in: custodyFixture.0
        )
        let custodyGateway = PebbleAgentMaterialCustodyGateway()
        let custodyFingerprint = try custodyGateway.fingerprint(destination)
        let staleFingerprint = custodyGateway.acquireItemEntities(
            PebbleAgentItemEntityAcquisitionRequest(
                transactionID: "increment07-stale-fingerprint",
                spawnedItemEntityIDs: [item.id],
                expectedDestinationFingerprint: custodyFingerprint + ":stale"
            ),
            from: source,
            to: destination
        )
        let acquired = custodyGateway.acquireItemEntities(
            PebbleAgentItemEntityAcquisitionRequest(
                transactionID: "increment07-duplicate-acquisition",
                spawnedItemEntityIDs: [item.id],
                expectedDestinationFingerprint: custodyFingerprint
            ),
            from: source,
            to: destination
        )
        let duplicate = custodyGateway.acquireItemEntities(
            PebbleAgentItemEntityAcquisitionRequest(
                transactionID: "increment07-duplicate-acquisition",
                spawnedItemEntityIDs: [item.id],
                expectedDestinationFingerprint: custodyFingerprint
            ),
            from: source,
            to: destination
        )
        guard staleFingerprint.status == .staleDestination,
              acquired.succeeded,
              acquired.quantityMoved == 2,
              duplicate.status == .duplicate,
              duplicate.quantityMoved == 0,
              custodyFixture.1.carriedItems.compactMap({ $0 }).reduce(0, {
                  $0 + (itemDef($1.id).name == "sweet_berries" ? $1.count : 0)
              }) == 2,
              custodyFixture.0.entityById[item.id] == nil else {
            throw ControllerError.feedbackBoundary(
                "custody fingerprint/duplicate matrix diverged"
            )
        }

        // Registration plus compensation failure leaves an explicit diagnostic
        // and the controller's existing hard boundary blocks unsafe progress.
        guard let publishedSession = session else {
            throw ControllerError.feedbackBoundary(
                "hard-failure proof requires the published founder session"
            )
        }
        let hardFixture = fixture(actorID: "increment07-hard")
        let hardTransaction = PebbleCandidatePhysicalTransaction(
            transactionID: "increment07-hard-transaction",
            operation: "increment07 physical hard-failure proof",
            physicalWorldTick: hardFixture.0.time,
            injectedCompensationFailurePrefix:
                "physical-action:harvestSweetBerryBush",
            injectedRegistrationFailurePrefix:
                "physical-action:harvestSweetBerryBush"
        )
        let hardGateway = PebbleAgentPhysicalActionGateway()
        hardGateway.candidatePhysicalTransaction = hardTransaction
        let hardOutcome = hardGateway.harvestSweetBerryBush(
            world: hardFixture.0,
            actor: hardFixture.1,
            request: request(
                actorID: hardFixture.1.labAgentId,
                attempt: "increment07-hard"
            ),
            occupiedPositions: []
        )
        hardGateway.candidatePhysicalTransaction = nil
        let hardRollback = hardTransaction.rollback()
        let hardFailure = makeCandidatePhysicalHardFailure(
            transaction: hardTransaction,
            rollback: hardRollback,
            receiptFailure: nil,
            receiptIDs: [],
            session: publishedSession,
            world: hardFixture.0
        )
        let publishedBytes = try publishedSession.durableStateBytes()
        let priorPause = isPaused
        let priorError = lastError
        candidatePhysicalHardFailure = hardFailure
        let unsafeAdvance = advanceOneTick(
            world: activeWorld, player: player
        )
        let boundaryPaused = isPaused
        candidatePhysicalHardFailure = nil
        isPaused = priorPause
        lastError = priorError
        guard hardOutcome.status == .rollbackFailure,
              hardRollback.failure != nil,
              !unsafeAdvance,
              boundaryPaused,
              let currentSession = session,
              try currentSession.durableStateBytes() == publishedBytes else {
            throw ControllerError.feedbackBoundary(
                "candidate compensation hard-failure boundary diverged"
            )
        }

        return "PASS contention=one-of-two dropSet=1 quantity=\(firstQuantity) "
            + "loser=stale preMutation=stale,dead,chunk,outOfReach "
            + "recoverable=postMutation,itemMissing,custodyFull,publication "
            + "fingerprint=stale duplicateAcquisition=refused "
            + "hardFailure=blocked publishedSession=unchanged"
    }

}
