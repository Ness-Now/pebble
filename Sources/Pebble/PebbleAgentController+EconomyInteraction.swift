import Foundation
import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func handleEconomy(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab economy <setup|auto on|auto off|status|clear>"
        guard let subcommand = arguments.first?.lowercased() else { return failure(usage) }

        if subcommand == "status" {
            guard arguments.count == 1 else { return failure(usage) }
            let fixtures = interactionExecutor.economyState()
            let snapshot = session?.snapshot()
            let actor = fixtures.fixtures.first?.actorId ?? focusedAgentId
            let agent = snapshot?.agents.first { $0.id == actor }
            let inventory = AgentResourceKind.allCases.map {
                "\($0.rawValue):\(agent?.resourceInventory.count(of: $0) ?? 0)"
            }.joined(separator: ",")
            let stock = AgentResourceKind.allCases.map {
                "\($0.rawValue):\(snapshot?.campStock.count(of: $0) ?? 0)"
            }.joined(separator: ",")
            let fixtureText = fixtures.fixtures.map {
                "\($0.fixtureId)@\(positionText($0.target)):\($0.harvested ? "harvested" : "available")"
            }.joined(separator: ",")
            let reservations = snapshot?.resourceReservations.map {
                "\($0.agentId):\($0.resource.rawValue)@\(positionText($0.target))"
            }.joined(separator: ",") ?? ""
            let conservation = snapshot?.conservation
            let message = "economy active=\(snapshot?.economyEnabled == true ? "yes" : "no") auto=\(economyAutoEnabled ? "on" : "off") quota=\(snapshot?.deliveryQuota ?? 0) actor=\(actor ?? "none") goal=\(agent?.currentGoal.kind.rawValue ?? "none") navigationDestination=\(agent?.navigationProgress.route?.purpose.rawValue ?? "none") inventory=\(inventory) inventoryTotal=\(agent?.resourceInventory.totalCount ?? 0)/\(agent?.resourceInventory.capacity ?? 0) campStock=\(stock) campStockTotal=\(snapshot?.campStock.totalCount ?? 0) fixtures=\(fixtureText) reservations=\(reservations.isEmpty ? "none" : reservations) deliveryOutcome=\(agent?.lastDeliveryOutcome?.status.rawValue ?? "none") memory=\(agent?.recentMemory.last?.type ?? "none") conservation=\(conservation?.harvestedTotal ?? 0):\(conservation?.carriedTotal ?? 0)+\(conservation?.campStockTotal ?? 0)+\(conservation?.consumedTotal ?? 0)+\(conservation?.constructionEscrowTotal ?? 0)+\(conservation?.constructedTotal ?? 0):\(conservation?.balanced == true ? "exact" : "diverged") corridorObserved=\(fixtures.corridorObservedBlockCount) corridorChangedSetup=\(fixtures.corridorChangedAfterSetup) corridorChangedNavigation=\(fixtures.corridorChangedDuringNavigation) corridorChangedHarvest=\(fixtures.corridorChangedAfterHarvest) corridorChangedCleanup=\(fixtures.corridorChangedAfterCleanup) fixtureSetupMutations=\(fixtures.setupMutatedBlockCount) cleanupRestoredBlocks=\(fixtures.cleanupRestoredBlockCount)"
            trace(message)
            return success(message)
        }

        guard featureEnabled else {
            return failure("PebbleAgents disabled. Set PEBBLELAB_APP_AGENTS=1 before launch.")
        }
        guard interactionFeatureEnabled else {
            return failure("PebbleAgents interaction disabled. Set PEBBLELAB_APP_AGENTS_INTERACT=1 before launch.")
        }
        guard var session, activeWorld === world, let anchor else {
            return failure("No active PebbleAgents session for this World.")
        }

        if subcommand == "auto" {
            guard arguments.count == 2,
                  arguments[1].lowercased() == "on" || arguments[1].lowercased() == "off" else {
                return failure(usage)
            }
            if arguments[1].lowercased() == "off" {
                session.setEconomyEnabled(false)
                self.session = session
                economyAutoEnabled = false
                lastEconomyReason = "disabled by command"
                trace("economy auto=off reason=command")
                return success("PebbleAgents economy automatic mode off.")
            }
            guard movementFeatureEnabled else {
                return failure("PebbleAgents movement disabled. Set PEBBLELAB_APP_AGENTS_MOVE=1 before launch.")
            }
            let fixtures = interactionExecutor.economyState().fixtures
            let actorId: String?
            if session.naturalResourcesEnabled {
                actorId = focusedAgentId
            } else if fixtures.count == PebbleAgentInteractionExecutor.maximumFixtureCount,
                      fixtures.contains(where: { !$0.harvested }),
                      let fixtureActor = fixtures.first?.actorId,
                      focusedAgentId == fixtureActor {
                actorId = fixtureActor
            } else {
                actorId = nil
            }
            guard let actorId else {
                return failure("Economy auto requires natural mode with a focused actor or three fixtures focused on their actor.")
            }
            session.setEconomyEnabled(true)
            self.session = session
            economyAutoEnabled = true
            autoInteractionEnabled = false
            lastEconomyReason = "enabled by command"
            trace("economy auto=on actor=\(actorId) quota=\(session.configuration.deliveryQuota)")
            return success("PebbleAgents economy automatic mode on for \(actorId), quota \(session.configuration.deliveryQuota).")
        }

        if subcommand == "clear" {
            guard arguments.count == 1 else { return failure(usage) }
            guard interactionExecutor.cleanup(world: world) else {
                return failure("Economy cleanup failed; fixture ledger retained.")
            }
            session.setEconomyEnabled(false)
            self.session = session
            economyAutoEnabled = false
            lastEconomyReason = "fixtures cleared"
            let cleanup = interactionExecutor.economyState()
            trace("economy clear cleanupRestoredBlocks=\(cleanup.cleanupRestoredBlockCount) corridorChangedCleanup=\(cleanup.corridorChangedAfterCleanup)")
            return success("PebbleAgents economy fixtures restored and automatic mode off.")
        }

        guard subcommand == "setup", arguments.count == 1 else { return failure(usage) }
        guard isPaused else { return failure("Economy setup requires a paused PebbleAgents session.") }
        guard !movementEnabled else { return failure("Economy setup requires movement off.") }
        guard let actorId = focusedAgentId,
              let actor = session.snapshot().agents.first(where: { $0.id == actorId }) else {
            return failure("Economy setup requires a valid focused agent.")
        }
        let occupied = session.snapshot().agents.filter { $0.id != actorId }.map(\.position)
        let playerPosition = AgentPosition(
            x: Int(player.x.rounded(.down)),
            y: Int(player.y.rounded(.down)),
            z: Int(player.z.rounded(.down))
        )
        do {
            let fixtures = try interactionExecutor.setupEconomy(
                world: world,
                actor: actor,
                anchor: anchor,
                occupiedAgentPositions: occupied,
                playerPosition: playerPosition,
                routeToTarget: { target in
                    let observation = self.navigationAdapter.observe(
                        world: world,
                        agent: actor,
                        target: target,
                        occupiedAgentPositions: occupied
                    )
                    return AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
                        start: actor.position,
                        target: target,
                        cells: observation.cells,
                        radius: observation.radius,
                        maxVisitedNodes: AgentBoundedRoutePlanner.maximumVisitedNodes,
                        maxSteps: AgentBoundedRoutePlanner.maximumRouteSteps
                    ))
                }
            )
            let boundary = interactionExecutor.economyState()
            let summary = fixtures.map {
                "\($0.fixtureId)=\($0.resource.rawValue)@\(positionText($0.target))/\($0.resourceBlockName)"
            }.joined(separator: ",")
            trace("economy setup actor=\(actorId) fixtures=\(summary) corridorObserved=\(boundary.corridorObservedBlockCount) corridorChanged=\(boundary.corridorChangedAfterSetup) fixtureSetupMutations=\(boundary.setupMutatedBlockCount)")
            return success("Economy sandbox ready: \(summary).")
        } catch {
            let boundary = interactionExecutor.economyState()
            return failure("Economy setup failed: \(error); setupMutations=\(boundary.setupMutatedBlockCount) rollback=\(boundary.lastRollback)")
        }
    }

    func handleInteraction(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab interaction <setup|setup distant <2...8>|harvest|status|auto on|auto off>"
        guard let subcommand = arguments.first?.lowercased() else { return failure(usage) }
        if subcommand == "status" {
            guard arguments.count == 1 else { return failure(usage) }
            let state = interactionExecutor.state(
                gateEnabled: interactionFeatureEnabled,
                autoEnabled: autoInteractionEnabled,
                autoReason: lastAutoInteractionReason
            )
            let target = state.target.map(positionText) ?? "none"
            let snapshot = session?.snapshot()
            let actor = state.actorId ?? focusedAgentId
            let inventory = snapshot?.agents.first { $0.id == actor }?.resourceInventory
            let actorSnapshot = snapshot?.agents.first { $0.id == actor }
            let outcome = actorSnapshot?.lastInteractionOutcome
            let interactionMemory = actorSnapshot?.recentMemory.last {
                $0.type == "resource_harvested"
                    || $0.type == "interaction_blocked"
                    || $0.type == "inventory_full"
            }?.type ?? "none"
            let activeTarget = actorSnapshot?.activeResourceTarget.map {
                "\(positionText($0.target))@selected\($0.selectedAtTick)/seen\($0.lastSeenAtTick)"
            } ?? "none"
            let navigation = actorSnapshot?.navigationProgress
            let reservationOwner = snapshot?.resourceReservations.first {
                $0.target == state.target
            }?.agentId ?? "none"
            let nextStep = navigation?.nextStep.map(positionText) ?? "none"
            let currentDistance = actorSnapshot.flatMap { agent in
                state.target.map { abs($0.x - agent.position.x) + abs($0.z - agent.position.z) }
            } ?? 0
            let message = "interaction gate=\(state.gateEnabled ? "enabled" : "disabled") sandbox=\(state.active ? "active" : "inactive") setupMode=\(state.setupMode) configuredDistance=\(state.configuredDistance ?? 0) target=\(target) actualDistance=\(currentDistance) actor=\(actor ?? "none") resourceBlock=\(state.resourceBlockName) originalBlock=\(state.originalBlock.map(String.init) ?? "none") harvested=\(state.harvested ? "yes" : "no") auto=\(state.autoEnabled ? "on" : "off") activeTarget=\(activeTarget) reservationOwner=\(reservationOwner) navigation=\(navigation?.status.rawValue ?? "idle") routeLength=\(navigation?.route?.positions.count ?? 0) routeIndex=\(navigation?.routeIndex ?? 0) stepsRemaining=\(navigation?.stepsRemaining ?? 0) nextStep=\(nextStep) replans=\(navigation?.replanCount ?? 0) invalidation=\(navigation?.lastInvalidation?.rawValue ?? "none") navigationFailure=\(navigation?.lastFailure?.rawValue ?? "none") movementOutcome=\(actorSnapshot?.lastMovementOutcome?.status.rawValue ?? "none") autoReason=\(state.autoReason.replacingOccurrences(of: " ", with: "_")) inventory=\(inventory?.totalCount ?? 0)/\(inventory?.capacity ?? 0) outcome=\(outcome?.status.rawValue ?? "none") memory=\(interactionMemory) reason=\(outcome?.reason ?? "none") rollback=\(state.rollbackCount):\(state.lastRollback) corridorObserved=\(state.corridorObservedBlockCount) corridorChangedSetup=\(state.corridorChangedAfterSetup) corridorChangedNavigation=\(state.corridorChangedDuringNavigation) corridorChangedHarvest=\(state.corridorChangedAfterHarvest) fixtureSetupMutations=\(state.setupMutatedBlockCount)"
            trace(message)
            return success(message)
        }

        if subcommand == "auto" {
            guard arguments.count == 2,
                  arguments[1].lowercased() == "on" || arguments[1].lowercased() == "off" else {
                return failure(usage)
            }
            if arguments[1].lowercased() == "off" {
                autoInteractionEnabled = false
                lastAutoInteractionReason = "disabled by command"
                trace("interaction auto=off reason=command")
                return success("PebbleAgents automatic interaction off.")
            }
            guard featureEnabled else {
                return failure("PebbleAgents disabled. Set PEBBLELAB_APP_AGENTS=1 before launch.")
            }
            guard interactionFeatureEnabled else {
                return failure("PebbleAgents interaction disabled. Set PEBBLELAB_APP_AGENTS_INTERACT=1 before launch.")
            }
            guard session != nil, activeWorld === world else {
                return failure("No active PebbleAgents session for this World.")
            }
            let state = interactionExecutor.state(gateEnabled: true)
            guard state.active, !state.harvested, let actorId = state.actorId else {
                return failure("Automatic interaction requires an active unharvested sandbox.")
            }
            guard focusedAgentId == actorId else {
                return failure("Automatic interaction requires focus on sandbox actor \(actorId).")
            }
            autoInteractionEnabled = true
            lastAutoInteractionReason = "enabled by command"
            trace("interaction auto=on actor=\(actorId) tick=\(session?.tick ?? 0)")
            return success("PebbleAgents automatic interaction on for \(actorId).")
        }

        let setupDistance: Int?
        if subcommand == "setup", arguments.count == 1 {
            setupDistance = 1
        } else if subcommand == "setup", arguments.count == 3,
                  arguments[1].lowercased() == "distant",
                  let distance = Int(arguments[2]), (2...8).contains(distance) {
            setupDistance = distance
        } else {
            setupDistance = nil
        }
        guard (subcommand == "setup" && setupDistance != nil)
                || (subcommand == "harvest" && arguments.count == 1) else {
            return failure(usage)
        }
        guard featureEnabled else {
            return failure("PebbleAgents disabled. Set PEBBLELAB_APP_AGENTS=1 before launch.")
        }
        guard interactionFeatureEnabled else {
            return failure("PebbleAgents interaction disabled. Set PEBBLELAB_APP_AGENTS_INTERACT=1 before launch.")
        }
        guard var session, activeWorld === world, let anchor else {
            return failure("No active PebbleAgents session for this World.")
        }
        guard isPaused else { return failure("Interaction requires a paused PebbleAgents session.") }
        guard !movementEnabled else { return failure("Interaction requires movement off.") }
        guard let actorId = focusedAgentId,
              let actor = session.snapshot().agents.first(where: { $0.id == actorId }) else {
            return failure("Interaction requires a valid focused agent.")
        }
        do {
            if subcommand == "setup" {
                let distance = setupDistance ?? 1
                let occupied = session.snapshot().agents.filter { $0.id != actorId }.map(\.position)
                let playerPosition = AgentPosition(
                    x: Int(player.x.rounded(.down)),
                    y: Int(player.y.rounded(.down)),
                    z: Int(player.z.rounded(.down))
                )
                let target = try interactionExecutor.setup(
                    world: world,
                    actor: actor,
                    anchor: anchor,
                    occupiedAgentPositions: occupied,
                    playerPosition: playerPosition,
                    distance: distance,
                    routeToTarget: { target in
                        let observation = self.navigationAdapter.observe(
                            world: world,
                            agent: actor,
                            target: target,
                            occupiedAgentPositions: occupied
                        )
                        return AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
                            start: actor.position,
                            target: target,
                            cells: observation.cells,
                            radius: observation.radius,
                            maxVisitedNodes: AgentBoundedRoutePlanner.maximumVisitedNodes,
                            maxSteps: AgentBoundedRoutePlanner.maximumRouteSteps
                        ))
                    }
                )
                let mode = distance == 1 ? "adjacent" : "distant"
                let boundary = interactionExecutor.state(gateEnabled: true)
                trace("interaction setup mode=\(mode) distance=\(distance) actor=\(actorId) target=\(positionText(target)) block=\(PebbleAgentInteractionExecutor.resourceBlockName) corridorObserved=\(boundary.corridorObservedBlockCount) corridorChanged=\(boundary.corridorChangedAfterSetup) fixtureSetupMutations=\(boundary.setupMutatedBlockCount)")
                return success("Interaction sandbox \(mode) distance \(distance) ready for \(actorId) at \(positionText(target)); block=\(PebbleAgentInteractionExecutor.resourceBlockName).")
            }
            let outcome = try performHarvestTransaction(
                world: world,
                player: player,
                actorId: actorId,
                expectedAction: nil,
                interactionPrefix: "g1",
                session: &session
            )
            self.session = session
            let after = session.snapshot().agents.first { $0.id == actorId }!
            trace("interaction harvest actor=\(actorId) target=\(positionText(outcome.target)) inventory=\(after.resourceInventory.totalCount)/\(after.resourceInventory.capacity) memory=resource_harvested outcome=succeeded")
            return success("\(actorId) harvested sandboxResource; inventory \(after.resourceInventory.totalCount)/\(after.resourceInventory.capacity).")
        } catch AgentSessionError.inventoryFull {
            guard let target = interactionExecutor.state(gateEnabled: true).target else {
                return failure("Inventory full.")
            }
            let outcome = AgentInteractionOutcome(
                interactionId: "g1-full:\(actorId):\(session.tick):\(positionText(target))",
                agentId: actorId,
                tick: session.tick,
                target: target,
                resource: .sandboxResource,
                status: .inventoryFull,
                inventoryDelta: AgentInventoryDelta(resource: .sandboxResource, quantity: 0),
                reason: "inventory capacity reached"
            )
            do {
                try session.applyInteractionOutcome(outcome)
                self.session = session
            } catch {
                return failure("Inventory full; failed to record outcome: \(error)")
            }
            return failure("Inventory full; World unchanged.")
        } catch {
            let boundary = interactionExecutor.state(gateEnabled: true)
            return failure("Interaction failed: \(error); setupMutations=\(boundary.setupMutatedBlockCount)")
        }
    }

    func performHarvestTransaction(
        world: World,
        player: Player,
        actorId: String,
        expectedAction: AgentAction?,
        interactionPrefix: String,
        session: inout AgentSimulationSession
    ) throws -> AgentInteractionOutcome {
        guard let actor = session.snapshot().agents.first(where: { $0.id == actorId }) else {
            throw ControllerError.interactionBoundary("missing interaction actor")
        }
        if let expectedAction,
           let naturalTarget = actor.activeResourceTarget,
           naturalTarget.source == .naturalWorld,
           expectedAction.target == naturalTarget.target,
           expectedAction.resource == naturalTarget.resource {
            return try performNaturalHarvestTransaction(
                world: world,
                player: player,
                actor: actor,
                identity: naturalTarget.identity,
                interactionPrefix: interactionPrefix,
                session: &session
            )
        }
        let availableFixtures = interactionExecutor.economyState().fixtures.filter {
            $0.actorId == actorId && !$0.harvested
        }
        guard let anchor,
              let target = expectedAction?.target ?? availableFixtures.first?.target,
              let fixture = availableFixtures.first(where: { $0.target == target }),
              let resource = expectedAction?.resource ?? Optional(fixture.resource) else {
            throw ControllerError.interactionBoundary("missing transaction boundary")
        }
        if let expectedAction {
            guard expectedAction.name == "harvest_block",
                  expectedAction.target == target,
                  expectedAction.resource == resource,
                  fixture.resource == resource else {
                throw ControllerError.interactionBoundary("harvest action target mismatch")
            }
        }
        let occupied = session.snapshot().agents.filter { $0.id != actorId }.map(\.position)
        let playerPosition = AgentPosition(
            x: Int(player.x.rounded(.down)),
            y: Int(player.y.rounded(.down)),
            z: Int(player.z.rounded(.down))
        )
        let interactionId = "\(interactionPrefix):\(actorId):\(session.tick):\(positionText(target))"
        let intent = AgentInteractionIntent(
            interactionId: interactionId,
            agentId: actorId,
            tick: session.tick,
            target: target,
            resource: resource
        )
        let before = actor
        let outcome = AgentInteractionOutcome(
            interactionId: interactionId,
            agentId: actorId,
            tick: session.tick,
            target: target,
            resource: resource,
            status: .succeeded,
            inventoryDelta: AgentInventoryDelta(resource: resource, quantity: 1),
            reason: "sandbox resource harvested"
        )
        try interactionExecutor.harvest(
            world: world,
            actor: actor,
            anchor: anchor,
            occupiedAgentPositions: occupied,
            playerPosition: playerPosition,
            expectedTarget: target,
            expectedResource: resource,
            prevalidate: { try session.prevalidateInteraction(intent) },
            applyAndVerify: {
                try session.applyInteractionOutcome(outcome)
                if environment["PEBBLELAB_APP_AGENTS_INTERACT_FAIL_AFTER_WORLD"] == "1" {
                    throw ControllerError.interactionBoundary("injected post-World failure")
                }
                let after = session.snapshot().agents.first { $0.id == actorId }!
                let expectedMemoryCount: Int
                switch session.configuration.memoryPolicy {
                case .legacyUnbounded:
                    expectedMemoryCount = before.memoryCount + 1
                case let .bounded(maxEntries):
                    expectedMemoryCount = min(maxEntries, before.memoryCount + 1)
                }
                guard after.resourceInventory.totalCount == before.resourceInventory.totalCount + 1,
                      after.resourceInventory.count(of: resource) == before.resourceInventory.count(of: resource) + 1,
                      after.lastInteractionOutcome == outcome,
                      after.memoryCount == expectedMemoryCount,
                      after.recentMemory.last?.type == "resource_harvested" else {
                    throw ControllerError.interactionBoundary(actorId)
                }
            }
        )
        return outcome
    }

    func performNaturalHarvestTransaction(
        world: World,
        player: Player,
        actor: AgentSnapshot,
        identity: AgentResourceIdentity,
        interactionPrefix: String,
        session: inout AgentSimulationSession
    ) throws -> AgentInteractionOutcome {
        let fingerprint = identity.expectedBlockFingerprint ?? -1
        let interactionId = "\(interactionPrefix)-natural:\(actor.id):\(session.tick):\(positionText(identity.position)):\(fingerprint)"
        let intent = AgentInteractionIntent(
            interactionId: interactionId,
            agentId: actor.id,
            tick: session.tick,
            target: identity.position,
            resource: identity.resource,
            source: .naturalWorld,
            expectedBlockFingerprint: identity.expectedBlockFingerprint
        )
        let outcome = AgentInteractionOutcome(
            interactionId: interactionId,
            agentId: actor.id,
            tick: session.tick,
            target: identity.position,
            resource: identity.resource,
            status: .succeeded,
            inventoryDelta: AgentInventoryDelta(resource: identity.resource, quantity: 1),
            reason: "natural resource harvested",
            source: .naturalWorld,
            expectedBlockFingerprint: identity.expectedBlockFingerprint
        )
        let snapshot = session.snapshot()
        let occupied = snapshot.agents.filter { $0.id != actor.id }.map(\.position)
        let playerPosition = AgentPosition(
            x: Int(player.x.rounded(.down)),
            y: Int(player.y.rounded(.down)),
            z: Int(player.z.rounded(.down))
        )
        let naturalGate = naturalFeatureEnabled
        let interactionGate = interactionFeatureEnabled
        let injectFailure = environment["PEBBLELAB_APP_AGENTS_NATURAL_FAIL_AFTER_WORLD"] == "1"
        let memoryPolicy = session.configuration.memoryPolicy
        try naturalResourceExecutor.harvest(
            world: world,
            actor: actor,
            identity: identity,
            occupiedAgentPositions: occupied,
            playerPosition: playerPosition,
            naturalGateEnabled: naturalGate,
            interactionGateEnabled: interactionGate,
            prevalidate: {
                try session.prevalidateInteraction(intent)
            },
            publishAndVerify: {
                var candidate = session
                try candidate.applyInteractionOutcome(outcome)
                if injectFailure {
                    throw ControllerError.interactionBoundary("injected natural publication failure")
                }
                let after = candidate.snapshot().agents.first { $0.id == actor.id }!
                let expectedMemoryCount: Int
                switch memoryPolicy {
                case .legacyUnbounded:
                    expectedMemoryCount = actor.memoryCount + 1
                case let .bounded(maxEntries):
                    expectedMemoryCount = min(maxEntries, actor.memoryCount + 1)
                }
                guard after.resourceInventory.totalCount == actor.resourceInventory.totalCount + 1,
                      after.resourceInventory.count(of: identity.resource)
                        == actor.resourceInventory.count(of: identity.resource) + 1,
                      after.lastInteractionOutcome == outcome,
                      after.memoryCount == expectedMemoryCount,
                      after.recentMemory.last?.type == "resource_harvested",
                      candidate.conservationSnapshot().balanced else {
                    throw ControllerError.interactionBoundary("natural publication verification failed")
                }
                session = candidate
            }
        )
        trace("natural harvest actor=\(actor.id) target=\(positionText(identity.position)) resource=\(identity.resource.rawValue) source=naturalWorld fingerprint=\(fingerprint) blockAfter=\(world.getBlock(identity.position.x, identity.position.y, identity.position.z)) cleanupRestore=0 inventoryCredit=1 memory=resource_harvested")
        return outcome
    }

}
