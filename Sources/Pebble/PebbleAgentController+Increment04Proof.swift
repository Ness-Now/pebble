import Foundation
import PebbleAgents
import PebbleCore

/// Disposable-world acceptance evidence for PS01 Increment 04.
///
/// The fixture controls only local terrain. Every observation, decision,
/// movement, break, custody transfer, publication, and consumption continues
/// through `advanceOneTick`, the ordinary normal-founder product path.
extension PebbleAgentController {
    func handleIncrement04Proof(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab ps01-increment-04-proof "
            + "<gateway-rng|physical-matrix|focused|performance|seed-search>"
        guard arguments == ["gateway-rng"]
                || arguments == ["physical-matrix"]
                || arguments == ["focused"]
                || arguments == ["performance"]
                || arguments == ["seed-search"] else {
            return failure(usage)
        }
        guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1" else {
            return failure("Increment 04 focused proof requires a disposable World.")
        }
        do {
            if arguments == ["seed-search"] {
                let result = try runIncrement04NaturalSeedSearch()
                print("[ps01-i04-seed-search] \(result)")
                return success(result)
            }
            if arguments == ["physical-matrix"] {
                let result = try runIncrement04PhysicalMatrix(
                    world: world, player: player
                )
                print("[ps01-i04-physical-matrix] \(result)")
                return success(result)
            }
            if arguments == ["performance"] {
                let result = try runIncrement04PerformanceSample(
                    world: world, player: player
                )
                print("[ps01-i04-performance] \(result)")
                return success(result)
            }
            let gatewayRNG = try runIncrement04GatewayRNGProof()
            print("[ps01-i04-gateway-rng] \(gatewayRNG)")
            if arguments == ["gateway-rng"] { return success(gatewayRNG) }
            guard let published = session else {
                throw ControllerError.feedbackBoundary(
                    "consumption proof requires a published founder candidate"
                )
            }
            let consumption = try runIncrement04ConsumptionAtomicityProof(
                session: published
            )
            print("[ps01-i04-consumption] \(consumption)")
            let result = try runIncrement04FocusedFounderProof(
                world: world, player: player
            )
            print("[ps01-i04-focused] \(result)")
            return success(result)
        } catch {
            print("[ps01-i04-focused] FAIL \(error)")
            return failure("Increment 04 focused proof failed: \(error)")
        }
    }

    /// Times one real controller tick after an ordinary founder start. This
    /// proof-only sampler creates no fixture and changes no scheduling policy;
    /// callers collect independent samples while the normal World is ready.
    func runIncrement04PerformanceSample(
        world: World,
        player: Player
    ) throws -> String {
        guard let beforeSession = session else {
            throw ControllerError.feedbackBoundary(
                "performance sample requires a published founder session"
            )
        }
        let founderCount = beforeSession.snapshot().agentCount
        guard (20...30).contains(founderCount),
              beforeSession.ecologicalObservationEnabled,
              beforeSession.wildSubsistenceEnabled,
              beforeSession.physicalFoodSurvivalEnabled,
              beforeSession.autonomousActivityEnabled else {
            throw ControllerError.feedbackBoundary(
                "performance sample requires the normal Increment 04 founder composition"
            )
        }
        guard world.physicalSimulationCoverage.isReady else {
            throw ControllerError.feedbackBoundary(
                "performance sample requires ready physical coverage"
            )
        }

        let tickBefore = beforeSession.tick
        let ecologicalBefore = beforeSession.ecologicalObservationSnapshot()
        let wildBefore = beforeSession.wildSubsistenceSnapshot()
        let activityBefore = beforeSession.autonomousActivitySnapshot()
        let physiologicalBefore = beforeSession.physiologicalTimeSnapshot()
        let consumedBefore = beforeSession.physicalFoodSurvivalSnapshot()?
            .totalConsumedQuantity ?? 0
        let observationSequencesBefore = Set(
            ecologicalBefore.observations.map(\.sequence)
        )
        let outcomeAttemptsBefore = Set(
            wildBefore.retainedOutcomes.map { $0.outcome.attemptID.rawValue }
        )
        let catchUpDroppedBefore = droppedCatchUpSteps

        let started = DispatchTime.now().uptimeNanoseconds
        guard advanceOneTick(world: world, player: player) else {
            throw ControllerError.feedbackBoundary(
                lastError ?? "performance sample controller tick failed"
            )
        }
        let elapsedNanoseconds = DispatchTime.now().uptimeNanoseconds - started

        guard let afterSession = session,
              afterSession.tick == tickBefore + 1 else {
            throw ControllerError.feedbackBoundary(
                "performance sample did not publish exactly one controller tick"
            )
        }
        let ecologicalAfter = afterSession.ecologicalObservationSnapshot()
        let wildAfter = afterSession.wildSubsistenceSnapshot()
        let activityAfter = afterSession.autonomousActivitySnapshot()
        let physiologicalAfter = afterSession.physiologicalTimeSnapshot()
        let consumedAfter = afterSession.physicalFoodSurvivalSnapshot()?
            .totalConsumedQuantity ?? 0
        let newObservations = ecologicalAfter.observations.filter {
            !observationSequencesBefore.contains($0.sequence)
        }
        let newOutcomes = wildAfter.retainedOutcomes.filter {
            !outcomeAttemptsBefore.contains($0.outcome.attemptID.rawValue)
        }
        let edibleObservations = newObservations.filter { record in
            record.observation.plants.contains {
                $0.edibleSourceEvidence != nil
            }
        }.count
        let scannedCells = newObservations.reduce(0) {
            $0 + $1.observation.diagnostics.cellsConsidered
        }
        let worldReads = newObservations.reduce(0) {
            $0 + $1.observation.diagnostics.worldReads
        }
        let movementRequests = lastMovementOutcomes.filter {
            $0.status != .notRequested
        }.count
        let activeOpportunities = wildAfter.opportunities.filter {
            $0.status == .selected
        }.count
        let autonomousCandidates = max(
            0,
            activityAfter.counters.candidateCount
                - activityBefore.counters.candidateCount
        )
        let acquisitionAttempts = max(
            0, wildAfter.totalAttemptCount - wildBefore.totalAttemptCount
        )
        let successfulAcquisitions = newOutcomes.filter {
            $0.outcome.status == .succeeded
        }.count
        let itemEntities = newOutcomes.reduce(0) {
            $0 + $1.outcome.physicalCausalIDs.count
        }
        let consumptions = Int(consumedAfter - consumedBefore)
        let receiptStore = try worldEcologicalObservationReceiptStore()
        let retainedWorldReceipts = receiptStore.database.listWorldReceipts(
            worldID: receiptStore.worldID,
            kind: PebbleEcologicalObservationReceipt.kind
        ).count
        let controllerMilliseconds = String(
            format: "%.3f",
            Double(elapsedNanoseconds) / 1_000_000
        )
        let physiologicalBoundaries =
            physiologicalAfter.appliedBoundaryCount
                - physiologicalBefore.appliedBoundaryCount
        let line = "PS01_INCREMENT_04_PERFORMANCE_SAMPLE "
            + "founders=\(founderCount) tick=\(tickBefore)>\(afterSession.tick) "
            + "controllerMs=\(controllerMilliseconds) "
            + "ecologicalScans=\(newObservations.count) "
            + "scannedCells=\(scannedCells) worldReads=\(worldReads) "
            + "retainedObservations=\(ecologicalAfter.observations.count) "
            + "retainedWorldReceipts=\(retainedWorldReceipts) "
            + "edibleObservations=\(edibleObservations) "
            + "activeOpportunities=\(activeOpportunities) capacityDeferrals=0 "
            + "autonomousCandidates=\(autonomousCandidates) "
            + "movementRequests=\(movementRequests) "
            + "acquisitionAttempts=\(acquisitionAttempts) "
            + "successfulAcquisitions=\(successfulAcquisitions) "
            + "itemEntities=\(itemEntities) consumptions=\(consumptions) "
            + "coverage=ready runtimeErrors=\(runtimeErrorCount) "
            + "physiologicalBoundaries=\(physiologicalBoundaries) "
            + "hardFailure=\(candidatePhysicalHardFailure == nil ? 0 : 1) "
            + "catchUpDropped=\(droppedCatchUpSteps - catchUpDroppedBefore) "
            + "catchUpDroppedTotal=\(droppedCatchUpSteps)"
        trace(line)
        return line
    }

    /// Faults one exact mature-berry action at adapter boundaries. Every case
    /// uses the production Core break, physical gateway, ItemEntity custody,
    /// and candidate hard-failure policy; the fixture only supplies bounded
    /// local cells and actors in disposable Worlds.
    private func runIncrement04PhysicalMatrix(
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
        ) -> PebbleAgentBlockBreakRequest {
            PebbleAgentBlockBreakRequest(
                actorID: actorID,
                target: position,
                expectedCell: expectedCell,
                heldItem: nil,
                isCreative: false,
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
            labAgentId: "increment04-contender-a",
            physicalId: "increment04-contender-a"
        )
        winner.setPos(0.5, 64, 0.5)
        contentionWorld.addEntity(winner)
        let loser = LabCoreAgentEntity(
            world: contentionWorld,
            labAgentId: "increment04-contender-b",
            physicalId: "increment04-contender-b"
        )
        loser.setPos(2.5, 64, 0.5)
        contentionWorld.addEntity(loser)
        let qualification = edibleBlockBreakDropQualifications(
            for: mature, heldItem: nil
        ).first!
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
            attemptID: "increment04-contention-a",
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
                attemptID: "increment04-contention-b",
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
              contentionWorld.getBlock(1, 64, 0) == 0,
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
            actorID: "increment04-stale", targetCell: Int(cell(B.sweet_berry_bush, 2))
        )
        let stale = PebbleAgentPhysicalActionGateway().breakBlock(
            world: staleFixture.0,
            actor: staleFixture.1,
            request: request(
                actorID: staleFixture.1.labAgentId,
                attempt: "increment04-stale"
            ),
            occupiedPositions: []
        )

        let deadFixture = fixture(actorID: "increment04-dead")
        deadFixture.1.dead = true
        let dead = PebbleAgentPhysicalActionGateway().breakBlock(
            world: deadFixture.0,
            actor: deadFixture.1,
            request: request(
                actorID: deadFixture.1.labAgentId,
                attempt: "increment04-dead"
            ),
            occupiedPositions: []
        )

        let farFixture = fixture(actorID: "increment04-far")
        let farTarget = PhysicalBlockPosition(x: 2, y: 64, z: 0)
        farFixture.0.setBlock(2, 64, 0, mature, SET_SILENT)
        let far = PebbleAgentPhysicalActionGateway().breakBlock(
            world: farFixture.0,
            actor: farFixture.1,
            request: request(
                actorID: farFixture.1.labAgentId,
                at: farTarget,
                attempt: "increment04-far"
            ),
            occupiedPositions: []
        )

        let unavailableFixture = fixture(
            actorID: "increment04-unavailable", actorX: 15
        )
        let unavailableTarget = PhysicalBlockPosition(x: 16, y: 64, z: 0)
        let unavailable = PebbleAgentPhysicalActionGateway().breakBlock(
            world: unavailableFixture.0,
            actor: unavailableFixture.1,
            request: request(
                actorID: unavailableFixture.1.labAgentId,
                at: unavailableTarget,
                attempt: "increment04-unavailable"
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

        let rejectedFixture = fixture(actorID: "increment04-rejected")
        gameRng = RandomX(0x8800_1144)
        let rejectedOuter = gameRng
        let rejected = PebbleAgentPhysicalActionGateway().breakBlock(
            world: rejectedFixture.0,
            actor: rejectedFixture.1,
            request: request(
                actorID: rejectedFixture.1.labAgentId,
                attempt: "increment04-rejected"
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

        let missingFixture = fixture(actorID: "increment04-missing-entity")
        gameRng = RandomX(0x8800_1144)
        let missingOuter = gameRng
        let missing = PebbleAgentPhysicalActionGateway().breakBlock(
            world: missingFixture.0,
            actor: missingFixture.1,
            request: request(
                actorID: missingFixture.1.labAgentId,
                attempt: "increment04-missing-entity"
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

        let fullFixture = fixture(actorID: "increment04-full")
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
                attemptID: "increment04-full",
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

        let publicationFixture = fixture(actorID: "increment04-publication")
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
                attemptID: "increment04-publication",
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

        let custodyFixture = fixture(actorID: "increment04-custody")
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
                transactionID: "increment04-stale-fingerprint",
                spawnedItemEntityIDs: [item.id],
                expectedDestinationFingerprint: custodyFingerprint + ":stale"
            ),
            from: source,
            to: destination
        )
        let acquired = custodyGateway.acquireItemEntities(
            PebbleAgentItemEntityAcquisitionRequest(
                transactionID: "increment04-duplicate-acquisition",
                spawnedItemEntityIDs: [item.id],
                expectedDestinationFingerprint: custodyFingerprint
            ),
            from: source,
            to: destination
        )
        let duplicate = custodyGateway.acquireItemEntities(
            PebbleAgentItemEntityAcquisitionRequest(
                transactionID: "increment04-duplicate-acquisition",
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
        let hardFixture = fixture(actorID: "increment04-hard")
        let hardTransaction = PebbleCandidatePhysicalTransaction(
            transactionID: "increment04-hard-transaction",
            operation: "increment04 physical hard-failure proof",
            physicalWorldTick: hardFixture.0.time,
            injectedCompensationFailurePrefix: "physical-action:breakBlock",
            injectedRegistrationFailurePrefix: "physical-action:breakBlock"
        )
        let hardGateway = PebbleAgentPhysicalActionGateway()
        hardGateway.candidatePhysicalTransaction = hardTransaction
        let hardOutcome = hardGateway.breakBlock(
            world: hardFixture.0,
            actor: hardFixture.1,
            request: request(
                actorID: hardFixture.1.labAgentId,
                attempt: "increment04-hard"
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

    /// Finds evidence candidates only. The result must subsequently pass in a
    /// fresh ordinary World without this proof command or proof environment.
    private func runIncrement04NaturalSeedSearch() throws -> String {
        let variable = "PEBBLELAB_PS01_INCREMENT04_SEED_SEARCH_LIMIT"
        let requestedLimit = environment[variable].flatMap(Int.init) ?? 2_048
        guard (1...10_000).contains(requestedLimit) else {
            throw ControllerError.feedbackBoundary(
                "seed search limit must be 1...10000"
            )
        }
        let configuration = AgentEcologicalObservationConfiguration.live
        let civilDate = configuration.calendar.date(atSimulationTick: 0)!
        let profile = try PebbleNormalFounderProfile(count: 20)
        let seaLevel = DIMS[Dim.overworld.rawValue].seaLevel
        let sensor = PebbleAgentEcologicalObservationSensor()
        var qualifiedWorlds = 0

        func normalSpawn(_ generator: OverworldGen) -> (x: Int, z: Int) {
            var x = 8
            var z = 8
            for radius in 0..<40 {
                let candidateX = 8 + radius * 40
                let candidateZ = 8 + ((radius * 13) % 7 - 3) * 40
                let biome = generator.surfaceBiomeAt(
                    Double(candidateX), Double(candidateZ)
                )
                let height = generator.heightEstimate(
                    Double(candidateX), Double(candidateZ)
                )
                let name = (BIOMES[Int(biome.rawValue)]?.name ?? "")
                    .lowercased()
                if height > seaLevel,
                   !name.contains("ocean"), !name.contains("river") {
                    x = candidateX
                    z = candidateZ
                    break
                }
            }
            return (x, z)
        }

        func loadChunk(_ world: World, seed: UInt32, x: Int, z: Int) {
            guard world.getChunk(x, z) == nil else { return }
            let output = generateOverworldChunk(seed, x, z)
            let chunk = Chunk(
                cx: x, cz: z, minY: world.info.minY,
                height: world.info.height
            )
            chunk.blocks = output.blocks
            chunk.biomes = output.biomes
            chunk.buildHeightmap()
            chunk.status = .lit
            world.setChunk(chunk)
        }

        // Seeds 46 and 887 were exercised first in ordinary rendered Worlds.
        // The fallback order is then the ascending unsigned seed interval,
        // excluding those already-tested canonical seeds.
        for rawSeed in 0..<requestedLimit where rawSeed != 46 && rawSeed != 887 {
            let seed = UInt32(rawSeed)
            let generator = OverworldGen(seed)
            let spawn = normalSpawn(generator)
            let spawnChunkX = floorDiv(spawn.x, CHUNK_W)
            let spawnChunkZ = floorDiv(spawn.z, CHUNK_W)
            var possibleBerryBiome = false
            for chunkZ in (spawnChunkZ - 2)...(spawnChunkZ + 2) {
                for chunkX in (spawnChunkX - 2)...(spawnChunkX + 2) {
                    let biome = generator.surfaceBiomeAt(
                        Double(chunkX * CHUNK_W + CHUNK_W / 2),
                        Double(chunkZ * CHUNK_W + CHUNK_W / 2)
                    )
                    if biome == .taiga || biome == .snowyTaiga {
                        possibleBerryBiome = true
                    }
                }
            }
            guard possibleBerryBiome else { continue }
            qualifiedWorlds += 1

            let world = World(dim: .overworld, seed: seed)
            for chunkZ in (spawnChunkZ - 2)...(spawnChunkZ + 2) {
                for chunkX in (spawnChunkX - 2)...(spawnChunkX + 2) {
                    loadChunk(world, seed: seed, x: chunkX, z: chunkZ)
                }
            }
            let surfaceY = world.surfaceY(spawn.x, spawn.z)
            let player = Player(world: world)
            player.setPos(
                Double(spawn.x) + 0.5, Double(surfaceY),
                Double(spawn.z) + 0.5
            )
            let anchor = AgentPosition(x: spawn.x, y: surfaceY, z: spawn.z)
            guard let placement = try? PebbleAgentBootstrapPlacementResolver()
                .resolve(
                    world: world, anchor: anchor, player: player,
                    socialEnabled: false, founders: profile.specification
                ) else { continue }

            for id in placement.agentIDs {
                guard let origin = placement.positionsByAgentID[id],
                      let agentID = AgentID(rawValue: id) else { continue }
                let observation = sensor.scan(
                    world: world, observerID: agentID, origin: origin,
                    worldContextKey: "ps01-i04-seed-\(rawSeed)",
                    dimensionKey: "overworld", simulationTick: 0,
                    civilDate: civilDate, configuration: configuration
                )
                guard observation.diagnostics.completion == .complete,
                      let plant = observation.plants.first(where: {
                          $0.plantKey == "sweet_berry_bush"
                              && $0.edibleSourceEvidence != nil
                      }) else { continue }
                let sourceCell = world.getBlock(
                    plant.position.x, plant.position.y, plant.position.z
                )
                let sourceStage = sourceCell & 15
                guard sourceCell >> 4 == Int(B.sweet_berry_bush),
                      sourceStage == 2 || sourceStage == 3 else { continue }
                return "PASS canonicalFirst=46,887 fallbackOrder=0..<"
                    + "\(requestedLimit) first=\(rawSeed) "
                    + "qualification=normal-spawn+20-founder-placement+"
                    + "complete-production-scan+core-qualified-mature-berry "
                    + "spawn=\(spawn.x),\(surfaceY),\(spawn.z) "
                    + "agent=\(id) origin=\(origin.x),\(origin.y),\(origin.z) "
                    + "source=\(plant.position.x),\(plant.position.y),"
                    + "\(plant.position.z) stage=\(sourceStage) "
                    + "candidateWorlds=\(qualifiedWorlds)"
            }
        }
        throw ControllerError.feedbackBoundary(
            "no normal founder mature berry candidate in canonical 46,887 "
                + "then ascending 0..<\(requestedLimit); "
                + "berry-biome worlds=\(qualifiedWorlds)"
        )
    }

    private struct Increment04GatewayRNGEvidence: Equatable {
        let digest: String
        let cellAfter: Int
        let spawnedItemEntityCount: Int
        let material: String
        let dropQuantity: Int
        let custodyQuantity: Int
        let outerRNGRestored: Bool
    }

    private func runIncrement04GatewayRNGProof() throws -> String {
        func stableDigest(_ values: [String]) -> String {
            var hash: UInt64 = 1_469_598_103_934_665_603
            for byte in values.joined(separator: "|").utf8 {
                hash ^= UInt64(byte)
                hash &*= 1_099_511_628_211
            }
            return String(format: "%016llx", hash)
        }
        func execute(
            cameraChunkX: Int,
            cameraChunkZ: Int,
            visitedFarFirst: Bool,
            outerPerturbations: Int
        ) throws -> Increment04GatewayRNGEvidence {
            let world = World(dim: .overworld, seed: 46)
            let chunk = Chunk(
                cx: 0, cz: 0, minY: world.info.minY,
                height: world.info.height
            )
            chunk.status = .lit
            world.setChunk(chunk)
            world.time = 640
            if visitedFarFirst {
                world.simCenterX = 32
                world.simCenterZ = 32
            }
            world.simCenterX = cameraChunkX
            world.simCenterZ = cameraChunkZ
            world.setBlock(0, 63, 0, Int(cell(B.stone)), SET_SILENT)
            world.setBlock(1, 63, 0, Int(cell(B.stone)), SET_SILENT)
            let mature = Int(cell(B.sweet_berry_bush, 3))
            world.setBlock(1, 64, 0, mature, SET_SILENT)
            let probe = LabCoreAgentEntity(
                world: world,
                labAgentId: "increment04-gateway-agent",
                physicalId: "increment04-gateway-agent"
            )
            probe.setPos(0.5, 64, 0.5)
            world.addEntity(probe)
            let actor = PebbleAgentEmbodiment(probe: probe)
            let physicalGateway = PebbleAgentPhysicalActionGateway()
            let materialGateway = PebbleAgentMaterialCustodyGateway()
            let destination = PebbleAgentMaterialCustodyEndpoint.liveAgent(
                actor, in: world
            )
            gameRng = RandomX(0x1a2b_3c4d)
            for _ in 0..<outerPerturbations { _ = gameRng.next() }
            let outerBefore = gameRng
            var itemState: [String] = []
            var material = "none"
            var dropQuantity = 0
            var custodyQuantity = 0
            let physical = physicalGateway.breakBlock(
                world: world,
                actor: actor,
                request: PebbleAgentBlockBreakRequest(
                    actorID: actor.agentID,
                    target: PhysicalBlockPosition(x: 1, y: 64, z: 0),
                    expectedCell: mature,
                    heldItem: nil,
                    isCreative: false,
                    directActionRandomness: PebbleAgentDirectActionRandomness(
                        operationDomain: 0x5042_4741,
                        stableAttemptID: "increment04-gateway-rng"
                    )
                ),
                occupiedPositions: []
            ) { ids in
                let items = ids.compactMap {
                    world.entityById[$0] as? ItemEntity
                }.sorted { $0.id < $1.id }
                guard items.count == ids.count,
                      let source = PebbleAgentItemEntityCustodyEndpoint(
                        spawnedItemEntityIDs: ids,
                        world: world
                      ),
                      let fingerprint = try? materialGateway.fingerprint(
                        destination
                      ) else { return false }
                itemState = items.map { item in
                    [
                        itemDef(item.stack.id).name,
                        String(item.stack.count),
                        String(item.x.bitPattern),
                        String(item.y.bitPattern),
                        String(item.z.bitPattern),
                        String(item.vx.bitPattern),
                        String(item.vy.bitPattern),
                        String(item.vz.bitPattern),
                        String(item.bobOffset.bitPattern),
                    ].joined(separator: ":")
                }
                material = items.first.map {
                    itemDef($0.stack.id).name
                } ?? "none"
                dropQuantity = items.reduce(0) { $0 + $1.stack.count }
                let acquisition = materialGateway.acquireItemEntities(
                    PebbleAgentItemEntityAcquisitionRequest(
                        transactionID: "increment04-gateway-rng-acquire",
                        spawnedItemEntityIDs: ids,
                        expectedDestinationFingerprint: fingerprint
                    ),
                    from: source,
                    to: destination
                )
                custodyQuantity = acquisition.quantityMoved
                return acquisition.succeeded
            }
            let carried = probe.carriedItems.compactMap { $0 }.filter {
                itemDef($0.id).name == "sweet_berries"
            }.reduce(0) { $0 + $1.count }
            guard physical.succeeded,
                  physical.spawnedItemEntityIDs.count == 1,
                  material == "sweet_berries",
                  (1...3).contains(dropQuantity),
                  custodyQuantity == dropQuantity,
                  carried == custodyQuantity,
                  world.getBlock(1, 64, 0) == 0,
                  physical.spawnedItemEntityIDs.allSatisfy({
                    world.entityById[$0] == nil
                  }) else {
                throw ControllerError.feedbackBoundary(
                    "gateway RNG chain failed status=\(physical.status.rawValue) "
                        + "failure=\(physical.failure?.rawValue ?? "none")"
                )
            }
            return Increment04GatewayRNGEvidence(
                digest: stableDigest([
                    "cell=\(mature)->\(world.getBlock(1, 64, 0))",
                    "entityCount=\(physical.spawnedItemEntityIDs.count)",
                    "item=\(itemState.joined(separator: ","))",
                    "custody=\(material):\(custodyQuantity)",
                    "result=\(physical.status.rawValue):"
                        + "\(physical.failure?.rawValue ?? "none")",
                ]),
                cellAfter: world.getBlock(1, 64, 0),
                spawnedItemEntityCount: physical.spawnedItemEntityIDs.count,
                material: material,
                dropQuantity: dropQuantity,
                custodyQuantity: custodyQuantity,
                outerRNGRestored: gameRng == outerBefore
            )
        }

        let near = try execute(
            cameraChunkX: 0, cameraChunkZ: 0,
            visitedFarFirst: false, outerPerturbations: 0
        )
        let far = try execute(
            cameraChunkX: 32, cameraChunkZ: 32,
            visitedFarFirst: false, outerPerturbations: 0
        )
        let returned = try execute(
            cameraChunkX: 0, cameraChunkZ: 0,
            visitedFarFirst: true, outerPerturbations: 0
        )
        let perturbed = try execute(
            cameraChunkX: 0, cameraChunkZ: 0,
            visitedFarFirst: false, outerPerturbations: 37
        )
        guard Set([
            near.digest, far.digest, returned.digest, perturbed.digest,
        ]).count == 1,
              [near, far, returned, perturbed].allSatisfy({
                  $0.cellAfter == 0
                    && $0.spawnedItemEntityCount == 1
                    && $0.material == "sweet_berries"
                    && $0.dropQuantity == $0.custodyQuantity
                    && $0.outerRNGRestored
              }) else {
            throw ControllerError.feedbackBoundary(
                "actual gateway direct-action RNG equivalence diverged"
            )
        }
        return "PASS near=\(near.digest) far=\(far.digest) "
            + "return=\(returned.digest) perturbed=\(perturbed.digest) "
            + "drop=\(near.dropQuantity) custody=\(near.custodyQuantity) "
            + "outerRNG=unchanged"
    }

    private func runIncrement04ConsumptionAtomicityProof(
        session: AgentSimulationSession
    ) throws -> String {
        enum InjectedPublicationError: Error { case rejected }
        func exactSlots(_ lhs: [ItemStack?], _ rhs: [ItemStack?]) -> Bool {
            lhs.elementsEqual(rhs, by: { left, right in
                switch (left, right) {
                case (nil, nil): return true
                case let (a?, b?): return a == b
                default: return false
                }
            })
        }
        func preparedSession() throws -> AgentSimulationSession {
            var candidate = session
            while try candidate.state(
                for: AgentID(rawValue: "agent_0")!
            ).needs.hunger
                < candidate.configuration.survivalConfiguration.hungryThreshold {
                _ = try candidate.advanceTick()
            }
            return candidate
        }
        func actor(
            quantity: Int
        ) -> (World, LabCoreAgentEntity, PebbleAgentMaterialCustodyEndpoint) {
            let world = World(dim: .overworld, seed: 46)
            let chunk = Chunk(
                cx: 0, cz: 0, minY: world.info.minY,
                height: world.info.height
            )
            chunk.status = .lit
            world.setChunk(chunk)
            let probe = LabCoreAgentEntity(
                world: world, labAgentId: "agent_0", physicalId: "agent_0"
            )
            probe.setPos(0.5, 64, 0.5)
            probe.carriedItems[0] = ItemStack(
                iid("sweet_berries"), quantity
            )
            world.addEntity(probe)
            return (
                world,
                probe,
                PebbleAgentMaterialCustodyEndpoint.liveAgent(probe, in: world)
            )
        }

        var staleSession = try preparedSession()
        let staleActor = actor(quantity: 2)
        _ = staleActor.0
        let staleGateway = PebbleAgentMaterialCustodyGateway()
        let staleIntent = try staleSession.nextPhysicalFoodConsumptionIntent(
            for: AgentID(rawValue: "agent_0")!
        )
        guard let stalePlan = try foodConsumptionExecutor.prepare(
            staleIntent, session: staleSession, source: staleActor.2,
            gateway: staleGateway
        ) else {
            throw ControllerError.physicalFoodBoundary(
                "stale fingerprint plan unavailable"
            )
        }
        let staleBytes = try staleSession.durableStateBytes()
        staleActor.1.carriedItems[1] = ItemStack(iid("stone"), 1)
        let externallyChangedSlots = copyItemInventory(
            staleActor.1.carriedItems
        )
        let stale = foodConsumptionExecutor.execute(
            stalePlan, session: &staleSession, source: staleActor.2,
            gateway: staleGateway
        )
        guard stale.status == .staleCustody,
              try staleSession.durableStateBytes() == staleBytes,
              exactSlots(staleActor.1.carriedItems, externallyChangedSlots)
        else {
            throw ControllerError.physicalFoodBoundary(
                "stale inventory fingerprint was not atomic"
            )
        }

        var removedSession = try preparedSession()
        let removedActor = actor(quantity: 2)
        _ = removedActor.0
        let removedGateway = PebbleAgentMaterialCustodyGateway()
        let removedIntent = try removedSession.nextPhysicalFoodConsumptionIntent(
            for: AgentID(rawValue: "agent_0")!
        )
        guard let removedPlan = try foodConsumptionExecutor.prepare(
            removedIntent, session: removedSession, source: removedActor.2,
            gateway: removedGateway
        ) else {
            throw ControllerError.physicalFoodBoundary(
                "removed-stack plan unavailable"
            )
        }
        let removedBytes = try removedSession.durableStateBytes()
        removedActor.1.carriedItems[removedPlan.sourceSlot] = nil
        let removed = foodConsumptionExecutor.execute(
            removedPlan, session: &removedSession, source: removedActor.2,
            gateway: removedGateway
        )
        guard removed.status == .staleCustody,
              try removedSession.durableStateBytes() == removedBytes,
              removedActor.1.carriedItems[removedPlan.sourceSlot] == nil else {
            throw ControllerError.physicalFoodBoundary(
                "removed-after-prepare stack was not refused"
            )
        }

        var rejectionSession = try preparedSession()
        let rejectionActor = actor(quantity: 2)
        _ = rejectionActor.0
        let rejectionGateway = PebbleAgentMaterialCustodyGateway()
        let rejectionIntent = try rejectionSession
            .nextPhysicalFoodConsumptionIntent(
                for: AgentID(rawValue: "agent_0")!
            )
        guard let rejectionPlan = try foodConsumptionExecutor.prepare(
            rejectionIntent, session: rejectionSession,
            source: rejectionActor.2, gateway: rejectionGateway
        ) else {
            throw ControllerError.physicalFoodBoundary(
                "post-debit rejection plan unavailable"
            )
        }
        let rejectionBytes = try rejectionSession.durableStateBytes()
        let rejectionSlots = copyItemInventory(
            rejectionActor.1.carriedItems
        )
        let rejection = foodConsumptionExecutor.execute(
            rejectionPlan, session: &rejectionSession,
            source: rejectionActor.2, gateway: rejectionGateway,
            verifyAfterDebit: { false }
        )
        guard rejection.status == .verificationFailure,
              try rejectionSession.durableStateBytes() == rejectionBytes,
              exactSlots(rejectionActor.1.carriedItems, rejectionSlots) else {
            throw ControllerError.physicalFoodBoundary(
                "post-debit publication rejection did not restore custody"
            )
        }

        var prepublicationSession = try preparedSession()
        let prepublicationActor = actor(quantity: 2)
        _ = prepublicationActor.0
        let prepublicationGateway = PebbleAgentMaterialCustodyGateway()
        let prepublicationIntent = try prepublicationSession
            .nextPhysicalFoodConsumptionIntent(
                for: AgentID(rawValue: "agent_0")!
            )
        guard let prepublicationPlan = try foodConsumptionExecutor.prepare(
            prepublicationIntent, session: prepublicationSession,
            source: prepublicationActor.2, gateway: prepublicationGateway
        ) else {
            throw ControllerError.physicalFoodBoundary(
                "prepublication rejection plan unavailable"
            )
        }
        let prepublicationBytes = try prepublicationSession.durableStateBytes()
        let prepublicationSlots = copyItemInventory(
            prepublicationActor.1.carriedItems
        )
        let prepublication = foodConsumptionExecutor.execute(
            prepublicationPlan, session: &prepublicationSession,
            source: prepublicationActor.2,
            gateway: prepublicationGateway,
            publish: { _, _ in throw InjectedPublicationError.rejected }
        )
        guard prepublication.status == .sessionRejected,
              try prepublicationSession.durableStateBytes()
                == prepublicationBytes,
              exactSlots(
                prepublicationActor.1.carriedItems, prepublicationSlots
              ) else {
            throw ControllerError.physicalFoodBoundary(
                "pre-debit session rejection mutated custody"
            )
        }

        var successSession = try preparedSession()
        let successActor = actor(quantity: 2)
        _ = successActor.0
        let successGateway = PebbleAgentMaterialCustodyGateway()
        let successIntent = try successSession.nextPhysicalFoodConsumptionIntent(
            for: AgentID(rawValue: "agent_0")!
        )
        guard let successPlan = try foodConsumptionExecutor.prepare(
            successIntent, session: successSession, source: successActor.2,
            gateway: successGateway
        ) else {
            throw ControllerError.physicalFoodBoundary(
                "successful consumption plan unavailable"
            )
        }
        let hungerBefore = try successSession.state(
            for: AgentID(rawValue: "agent_0")!
        ).needs.hunger
        let success = foodConsumptionExecutor.execute(
            successPlan, session: &successSession, source: successActor.2,
            gateway: successGateway
        )
        let slotsAfterSuccess = copyItemInventory(successActor.1.carriedItems)
        let duplicateBytes = try successSession.durableStateBytes()
        let duplicate = foodConsumptionExecutor.execute(
            successPlan, session: &successSession, source: successActor.2,
            gateway: successGateway
        )
        let hungerAfter = try successSession.state(
            for: AgentID(rawValue: "agent_0")!
        ).needs.hunger
        guard success.succeeded,
              successActor.1.carriedItems[0]?.count == 1,
              hungerAfter < hungerBefore,
              duplicate.status == .duplicate,
              try successSession.durableStateBytes() == duplicateBytes,
              exactSlots(successActor.1.carriedItems, slotsAfterSuccess) else {
            throw ControllerError.physicalFoodBoundary(
                "successful/duplicate physical consumption diverged"
            )
        }

        let insufficientActor = actor(quantity: 1)
        _ = insufficientActor.0
        let insufficientGateway = PebbleAgentMaterialCustodyGateway()
        let insufficientFingerprint = try insufficientGateway.fingerprint(
            insufficientActor.2
        )
        let insufficientBefore = copyItemInventory(
            insufficientActor.1.carriedItems
        )
        let insufficient = insufficientGateway.consume(
            PebbleAgentMaterialTransactionRequest(
                transactionID: "increment04-insufficient-consumption",
                material: AgentMaterialStackSnapshot(
                    identity: successPlan.material.identity,
                    count: 2
                ),
                expectedSourceFingerprint: insufficientFingerprint,
                expectedDestinationFingerprint: nil
            ),
            from: insufficientActor.2,
            sourceSlot: 0
        )
        guard insufficient.status == .insufficientQuantity,
              exactSlots(
                insufficientActor.1.carriedItems, insufficientBefore
              ) else {
            throw ControllerError.physicalFoodBoundary(
                "insufficient physical quantity was not atomic"
            )
        }

        return "PASS staleFingerprint=refused removedAfterPrepare=refused "
            + "insufficient=refused postDebitRollback=exact "
            + "sessionRejectDebit=0 successDebit=1 duplicateDebit=0 "
            + "hunger=\(hungerBefore)>\(hungerAfter)"
    }

    private func runIncrement04FocusedFounderProof(
        world: World,
        player: Player
    ) throws -> String {
        guard activeWorld === world, bootstrapFounderProfile != nil,
              var published = session, published.tick == 0,
              published.snapshot().agentCount == 20,
              published.survivalEnabled,
              published.skillsEnabled,
              published.ecologicalObservationEnabled,
              published.wildSubsistenceEnabled,
              published.physicalFoodSurvivalEnabled,
              published.autonomousActivityEnabled,
              !published.agricultureEnabled,
              !published.livestockEnabled,
              !published.productionEnabled,
              !published.workCommitmentsEnabled,
              !published.barterEnabled,
              !published.contractsEnabled,
              !published.marketEnabled,
              manualProductiveCommandsAfterBootstrap == 0 else {
            throw ControllerError.feedbackBoundary(
                "normal 20-founder unpublished-authority boundary unavailable"
            )
        }
        let unrelatedBefore = increment04UnrelatedDomainCounts(published)
        guard unrelatedBefore == [0, 0, 0, 0, 0, 0, 0, 0] else {
            throw ControllerError.feedbackBoundary(
                "normal founder start exposed an unrelated productive domain"
            )
        }
        guard let actor = probesByAgentId["agent_0"], actor.world === world,
              !actor.dead, actor.carriedItems.allSatisfy({ $0 == nil }) else {
            throw ControllerError.feedbackBoundary("focused actor unavailable")
        }

        let actorOrigin = AgentPosition(
            x: Int(actor.x.rounded(.down)),
            y: Int(actor.y.rounded(.down)),
            z: Int(actor.z.rounded(.down))
        )
        let occupied = Set(probesByAgentId.values.map {
            AgentPosition(
                x: Int($0.x.rounded(.down)),
                y: Int($0.y.rounded(.down)),
                z: Int($0.z.rounded(.down))
            )
        })
        let directions = [(1, 0), (-1, 0), (0, 1), (0, -1)]
        let ranked = directions.compactMap { dx, dz ->
            (target: AgentPosition, approach: AgentPosition, separation: Int)? in
            let approach = AgentPosition(
                x: actorOrigin.x + dx, y: actorOrigin.y,
                z: actorOrigin.z + dz
            )
            let target = AgentPosition(
                x: actorOrigin.x + dx * 2, y: actorOrigin.y,
                z: actorOrigin.z + dz * 2
            )
            guard !occupied.contains(approach), !occupied.contains(target) else {
                return nil
            }
            let otherSeparation = occupied.filter { $0 != actorOrigin }.map {
                abs($0.x - target.x) + abs($0.y - target.y)
                    + abs($0.z - target.z)
            }.min() ?? Int.max
            return (target, approach, otherSeparation)
        }.sorted { lhs, rhs in
            if lhs.separation != rhs.separation {
                return lhs.separation > rhs.separation
            }
            if lhs.target.x != rhs.target.x { return lhs.target.x < rhs.target.x }
            return lhs.target.z < rhs.target.z
        }
        guard let placement = ranked.first else {
            throw ControllerError.feedbackBoundary(
                "no bounded focused berry corridor available"
            )
        }
        for position in [placement.approach, placement.target] {
            world.setBlock(
                position.x, position.y - 1, position.z,
                Int(cell(B.stone)), SET_NO_NEIGHBORS
            )
            world.setBlock(position.x, position.y, position.z, 0, SET_NO_NEIGHBORS)
            world.setBlock(position.x, position.y + 1, position.z, 0, SET_NO_NEIGHBORS)
        }
        world.setBlock(
            placement.target.x, placement.target.y, placement.target.z,
            Int(cell(B.sweet_berry_bush, 3)), SET_NO_NEIGHBORS
        )
        ecologicalObservationSensor.invalidate(world: world)

        let survival = published.configuration.survivalConfiguration
        let initialCell = world.getBlock(
            placement.target.x, placement.target.y, placement.target.z
        )
        let initialEntityIDs = Set(world.entities.map(\.id))
        guard let initialFood = published.physicalFoodSurvivalSnapshot() else {
            throw ControllerError.feedbackBoundary(
                "physical food authority state unavailable"
            )
        }
        let initialWild = published.wildSubsistenceSnapshot()
        let initialMovement = try published.state(
            for: AgentID(rawValue: "agent_0")!
        ).movementCount
        var belowTicks = 0
        while let live = session,
              try live.state(for: AgentID(rawValue: "agent_0")!).needs.hunger
                < survival.hungryThreshold {
            guard advanceOneTick(world: world, player: player),
                  let after = session else {
                throw ControllerError.feedbackBoundary(
                    lastError ?? "pre-hunger founder tick failed"
                )
            }
            belowTicks += 1
            let state = try after.state(for: AgentID(rawValue: "agent_0")!)
            if state.needs.hunger < survival.hungryThreshold {
                guard after.wildSubsistenceSnapshot().opportunities.isEmpty,
                      after.autonomousActivitySnapshot().activeActivities.isEmpty,
                      world.getBlock(
                        placement.target.x, placement.target.y,
                        placement.target.z
                      ) == initialCell,
                      actor.carriedItems.allSatisfy({ $0 == nil }),
                      after.physicalFoodSurvivalSnapshot()?
                        .completedOutcomes.isEmpty == true
                else {
                    throw ControllerError.feedbackBoundary(
                        "pre-hunger berry behavior occurred at tick \(after.tick)"
                    )
                }
            }
            guard belowTicks <= 16 else {
                throw ControllerError.feedbackBoundary(
                    "hunger threshold was not reached within its configured bound"
                )
            }
        }
        guard let thresholdState = session,
              try thresholdState.state(
                for: AgentID(rawValue: "agent_0")!
              ).needs.hunger >= survival.hungryThreshold else {
            throw ControllerError.feedbackBoundary("hunger threshold not reached")
        }
        let thresholdTick = thresholdState.tick

        var acquisition: AgentSubsistenceOutcome?
        var consumption: AgentValidatedPhysicalFoodConsumptionOutcome?
        var maximumActiveOpportunities = 0
        for _ in 0..<12 {
            guard advanceOneTick(world: world, player: player),
                  let live = session else {
                throw ControllerError.feedbackBoundary(
                    lastError ?? "focused autonomous tick failed"
                )
            }
            let wild = live.wildSubsistenceSnapshot()
            maximumActiveOpportunities = max(
                maximumActiveOpportunities,
                wild.opportunities.filter {
                    $0.status == .selected && $0.expiresAtTick >= live.tick
                }.count
            )
            acquisition = wild.retainedOutcomes.reversed().map(\.outcome)
                .first(where: {
                    $0.strategy == .wildGathering
                        && $0.status == .succeeded
                        && $0.targetPosition == placement.target
                })
            consumption = live.physicalFoodSurvivalSnapshot()?
                .completedOutcomes.last(where: {
                    $0.canonicalMaterialName == "sweet_berries"
                })
            if acquisition != nil, consumption != nil { break }
        }
        guard let finalSession = session, let acquisition, let consumption,
              acquisition.actorID == consumption.agentID,
              acquisition.acquiredItems.allSatisfy({
                  $0.identity.itemKey == "sweet_berries" && $0.count > 0
              }),
              acquisition.acquiredQuantity >= consumption.quantityConsumed,
              consumption.quantityConsumed == 1,
              consumption.hungerAfter < consumption.hungerBefore,
              world.getBlock(
                placement.target.x, placement.target.y, placement.target.z
              ) == 0,
              Set(world.entities.map(\.id)).subtracting(initialEntityIDs)
                .isEmpty,
              finalSession.physicalFoodSurvivalSnapshot()?.totalConsumedQuantity
                == initialFood.totalConsumedQuantity + 1,
              finalSession.wildSubsistenceSnapshot().totalAttemptCount
                == initialWild.totalAttemptCount + 1 else {
            throw ControllerError.feedbackBoundary(
                "normal founder material chain did not complete exactly"
            )
        }
        guard let winner = probesByAgentId[acquisition.actorID.rawValue] else {
            throw ControllerError.feedbackBoundary("winning embodiment missing")
        }
        let carriedBerryCount = winner.carriedItems.compactMap { $0 }.filter {
            itemDef($0.id).name == "sweet_berries"
        }.reduce(0) { $0 + $1.count }
        guard acquisition.acquiredQuantity
                == carriedBerryCount + consumption.quantityConsumed,
              finalSession.conservationSnapshot().consumedTotal == 0,
              finalSession.snapshot().agents.allSatisfy({
                  $0.resourceInventory.count(of: .foodRaw) == 0
              }),
              maximumActiveOpportunities <= 16,
              increment04UnrelatedDomainCounts(finalSession)
                == unrelatedBefore else {
            throw ControllerError.feedbackBoundary(
                "material conservation or unrelated-domain boundary diverged"
            )
        }
        let winnerState = try finalSession.state(for: acquisition.actorID)
        let movementDelta = winnerState.movementCount - initialMovement
        guard movementDelta > 0,
              acquisition.sourceObservationEventID != nil,
              acquisition.attribution == "core-canonical-block-break",
              !consumption.physicalReceiptID.isEmpty else {
            throw ControllerError.feedbackBoundary(
                "focused path lacks movement or physical provenance "
                    + "winner=\(acquisition.actorID.rawValue) "
                    + "movement=\(movementDelta) "
                    + "observation=\(acquisition.sourceObservationEventID?.rawValue ?? "none") "
                    + "attribution=\(acquisition.attribution ?? "none") "
                    + "receipt=\(consumption.physicalReceiptID)"
            )
        }
        published = finalSession
        let digest = AgentWildSubsistenceDigest.make([
            "target=\(placement.target.x),\(placement.target.y),\(placement.target.z)",
            "threshold=\(thresholdTick)",
            "acquire=\(acquisition.completedAtTick)",
            "consume=\(consumption.tick)",
            "ids=\(acquisition.physicalCausalIDs.map(String.init).joined(separator: ","))",
            "quantity=\(acquisition.acquiredQuantity)",
            "carried=\(carriedBerryCount)",
            "hunger=\(consumption.hungerBefore)>\(consumption.hungerAfter)",
            "session=\((try published.makeCheckpoint()).semanticDigest.rawValue)",
        ].joined(separator: "|"))
        let line = "PS01_INCREMENT_04_FOCUSED_PASS "
            + "start=no-command founders=20 preHungerTicks=\(belowTicks) "
            + "thresholdTick=\(thresholdTick) acquisitionTick=\(acquisition.completedAtTick) "
            + "consumptionTick=\(consumption.tick) target=\(placement.target.x),"
            + "\(placement.target.y),\(placement.target.z) cell=\(initialCell)->0 "
            + "itemEntities=\(acquisition.physicalCausalIDs.count) "
            + "acquired=\(acquisition.acquiredQuantity) consumed=1 "
            + "carried=\(carriedBerryCount) movement=\(movementDelta) "
            + "hunger=\(consumption.hungerBefore)>\(consumption.hungerAfter) "
            + "foodRaw=0 maxOpportunities=\(maximumActiveOpportunities) "
            + "unrelated=0 digest=\(digest)"
        trace(line)
        return line
    }

    private func increment04UnrelatedDomainCounts(
        _ session: AgentSimulationSession
    ) -> [Int] {
        [
            session.wildSubsistenceSnapshot().opportunities.filter {
                $0.strategy == .fishing
            }.count,
            session.wildSubsistenceSnapshot().opportunities.filter {
                $0.strategy == .hunting
            }.count,
            session.agricultureSnapshot().plots.count,
            session.productionSnapshot().opportunities.count,
            session.activeWorkCommitments().count,
            session.marketSnapshot().tradeRecords.count,
            session.barterSnapshot().records.count,
            session.contractSnapshot().obligations.count,
        ]
    }
}
