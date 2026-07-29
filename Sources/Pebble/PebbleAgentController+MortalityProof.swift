import Foundation
import PebbleAgents
import PebbleCore

private struct PebbleMortalityPhysicalFixture {
    let controller: PebbleAgentController
    let world: World
    let container: BlockEntityData?
    let previous: AgentSessionSnapshot
    let pendingBytes: Data
    let probeInventoryByAgentID: [String: [ItemStack?]]
    let worldEntityIDs: Set<ObjectIdentifier>
    var session: AgentSimulationSession
    var recorder: AgentReplayRecorder?
}

extension PebbleAgentController {
    func verifyMortalityPhysicalCustodyFixtures() throws -> String {
        let rightsOff = try makeMortalityPhysicalFixture(
            name: "civ29-rights-off",
            carried: [["agent_0": ItemStack(iid("cobblestone"), 3)]],
            materialRightsEnabled: false,
            containerAvailable: true
        )
        var rightsOffSession = rightsOff.session
        var rightsOffRecorder = rightsOff.recorder
        try rightsOff.controller.reconcileMortalityProbes(
            previous: rightsOff.previous,
            current: &rightsOffSession,
            recorder: &rightsOffRecorder,
            world: rightsOff.world
        )
        try requireMortalityPhysicalProof(
            rightsOffSession.mortalitySnapshot().totalDeathCount == 1
                && rightsOffSession.materialRightsSnapshot().records.isEmpty
                && rightsOff.controller.probesByAgentId.keys.sorted()
                    == ["agent_1", "agent_2"]
                && physicalQuantity(
                    itemID: iid("cobblestone"),
                    in: rightsOff.container?.items
                ) == 3,
            "rights-off untracked physical transfer"
        )

        let rightsOn = try makeMortalityPhysicalFixture(
            name: "civ29-rights-on-no-record",
            carried: [["agent_0": ItemStack(iid("cobblestone"), 2)]],
            materialRightsEnabled: true,
            containerAvailable: true
        )
        var rightsOnSession = rightsOn.session
        var rightsOnRecorder = rightsOn.recorder
        try rightsOn.controller.reconcileMortalityProbes(
            previous: rightsOn.previous,
            current: &rightsOnSession,
            recorder: &rightsOnRecorder,
            world: rightsOn.world
        )
        try requireMortalityPhysicalProof(
            rightsOnSession.mortalitySnapshot().totalDeathCount == 1
                && rightsOnSession.materialRightsSnapshot().records.isEmpty
                && rightsOn.controller.probesByAgentId.keys.sorted()
                    == ["agent_1", "agent_2"]
                && physicalQuantity(
                    itemID: iid("cobblestone"),
                    in: rightsOn.container?.items
                ) == 2,
            "rights-on unregistered physical transfer"
        )

        let empty = try makeMortalityPhysicalFixture(
            name: "civ29-empty-probe",
            carried: [[:]],
            materialRightsEnabled: true,
            containerAvailable: false
        )
        var emptySession = empty.session
        var emptyRecorder = empty.recorder
        try empty.controller.reconcileMortalityProbes(
            previous: empty.previous,
            current: &emptySession,
            recorder: &emptyRecorder,
            world: empty.world
        )
        try requireMortalityPhysicalProof(
            emptySession.mortalitySnapshot().totalDeathCount == 1
                && emptySession.mortalitySnapshot().records.last?
                    .physicalCustodyResolution?.kind == .verifiedEmpty
                && empty.controller.probesByAgentId.keys.sorted()
                    == ["agent_1", "agent_2"],
            "verified-empty terminal custody"
        )

        let noContainer = try makeMortalityPhysicalFixture(
            name: "civ29-no-container",
            carried: [["agent_0": ItemStack(iid("cobblestone"), 4)]],
            materialRightsEnabled: false,
            containerAvailable: false
        )
        var noContainerSession = noContainer.session
        var noContainerRecorder = noContainer.recorder
        let noContainerReplayBefore = try noContainerRecorder.map {
            try AgentReplayCodec.encodeRecords($0.records)
        }
        var noContainerRejected = false
        do {
            try noContainer.controller.reconcileMortalityProbes(
                previous: noContainer.previous,
                current: &noContainerSession,
                recorder: &noContainerRecorder,
                world: noContainer.world
            )
        } catch {
            noContainerRejected = true
        }
        let noContainerBytesAfter = try noContainerSession
            .durableStateBytes()
        let noContainerReplayAfter = try noContainerRecorder.map {
            try AgentReplayCodec.encodeRecords($0.records)
        }
        try requireMortalityPhysicalProof(
            noContainerRejected
                && noContainerBytesAfter == noContainer.pendingBytes
                && noContainerReplayAfter == noContainerReplayBefore
                && noContainer.controller.probesByAgentId["agent_0"]?
                    .carriedItems
                    == noContainer.probeInventoryByAgentID["agent_0"]
                && noContainerSession.mortalitySnapshot().totalDeathCount == 0
                && noContainerSession.pendingMortalityTransitions().count == 1,
            "no-container retryable refusal"
        )

        let batch = try makeMortalityPhysicalFixture(
            name: "civ29-two-death-batch",
            carried: [
                ["agent_0": ItemStack(iid("cobblestone"), 2)],
                ["agent_1": ItemStack(iid("dirt"), 4)],
            ],
            materialRightsEnabled: false,
            containerAvailable: true
        )
        var batchSession = batch.session
        var batchRecorder = batch.recorder
        let batchReplayBefore = try batchRecorder.map {
            try AgentReplayCodec.encodeRecords($0.records)
        }
        var secondRejected = false
        do {
            try batch.controller.reconcileMortalityProbes(
                previous: batch.previous,
                current: &batchSession,
                recorder: &batchRecorder,
                world: batch.world,
                failurePoint: .beforePhysicalResolution(2)
            )
        } catch {
            secondRejected = true
        }
        let batchBytesAfter = try batchSession.durableStateBytes()
        let batchReplayAfter = try batchRecorder.map {
            try AgentReplayCodec.encodeRecords($0.records)
        }
        try requireMortalityPhysicalProof(
            secondRejected
                && batchBytesAfter == batch.pendingBytes
                && batchReplayAfter == batchReplayBefore
                && batch.container?.items?.allSatisfy({ $0 == nil }) == true
                && Set(batch.world.entities.map(ObjectIdentifier.init))
                    == batch.worldEntityIDs
                && batch.controller.probesByAgentId.keys.sorted()
                    == ["agent_0", "agent_1", "agent_2"]
                && batch.controller.probesByAgentId.allSatisfy {
                    $0.value.carriedItems
                        == batch.probeInventoryByAgentID[$0.key]
                }
                && batchSession.mortalitySnapshot().totalDeathCount == 0
                && batchSession.pendingMortalityTransitions().count == 2,
            "two-death batch rollback"
        )
        try batch.controller.reconcileMortalityProbes(
            previous: batch.previous,
            current: &batchSession,
            recorder: &batchRecorder,
            world: batch.world
        )
        try requireMortalityPhysicalProof(
            batchSession.mortalitySnapshot().totalDeathCount == 2
                && batch.controller.probesByAgentId.keys.sorted()
                    == ["agent_2"]
                && physicalQuantity(
                    itemID: iid("cobblestone"),
                    in: batch.container?.items
                ) == 2
                && physicalQuantity(
                    itemID: iid("dirt"),
                    in: batch.container?.items
                ) == 4,
            "two-death successful retry"
        )

        return [
            "rightsOffUntracked=transferred:3",
            "rightsOnUnregistered=transferred:2",
            "socialRecordsInvented=0",
            "emptyCustody=verified",
            "noContainer=retryable",
            "batchSecondFailure=rolledBack",
            "batchRetryDeaths=2",
            "duplications=0",
            "loss=0",
        ].joined(separator: " ")
    }

    private func makeMortalityPhysicalFixture(
        name: String,
        carried: [[String: ItemStack]],
        materialRightsEnabled: Bool,
        containerAvailable: Bool
    ) throws -> PebbleMortalityPhysicalFixture {
        let survival = try AgentSurvivalConfiguration(
            hungerPerTick: 0.01,
            fatiguePerTick: 0.01,
            hungryThreshold: 0.4,
            criticalHungerThreshold: 0.8,
            hungerRecoveryThreshold: 0.15,
            fatigueThreshold: 0.65,
            fatigueRecoveryThreshold: 0.2,
            foodNutrition: 1,
            restRecoveryPerTick: 1,
            starvationGraceTicks: 0,
            starvationDamagePerTick: 100
        )
        let states = (0..<3).map { ordinal in
            mortalityPhysicalFixtureAgent(
                ordinal: ordinal,
                terminal: ordinal < carried.count
            )
        }
        var session = try AgentSimulationSession(
            configuration: try AgentSessionConfiguration(
                seed: 129,
                memoryPolicy: .bounded(maxEntries: 32),
                survivalConfiguration: survival
            ),
            agents: states,
            simulationID: try AgentSimulationID(validating: name),
            causalLedgerPolicy: .bounded(maxEvents: 2048)
        )
        session.setSurvivalEnabled(true)
        try session.initializePopulationRegistry(
            settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
            receptionPosition: AgentPosition(x: 0, y: 64, z: 3)
        )
        try session.setMortalityEnabled(
            true, configuration: .embodiedLive
        )
        if materialRightsEnabled {
            try session.setMaterialRightsEnabled(true)
        }
        let previous = session.snapshot()
        let checkpoint = try session.makeCheckpoint()
        var recorder = try AgentReplayRecorder(
            checkpoint: checkpoint, session: session
        )
        _ = try recorder.apply(
            .advanceTick(perceptions: [], physicalObservations: []),
            to: &session
        )
        guard session.pendingMortalityTransitions().count == carried.count else {
            throw ControllerError.homeostasisBoundary(
                "physical fixture did not stage every death"
            )
        }

        let world = World(dim: .overworld, seed: 129)
        let chunk = Chunk(
            cx: 0, cz: 0, minY: world.info.minY,
            height: world.info.height
        )
        chunk.status = .lit
        world.setChunk(chunk)
        let container: BlockEntityData?
        if containerAvailable {
            let created = makeContainerBE(4, 64, 4, 27)
            world.setBlockEntity(created)
            container = created
        } else {
            container = nil
        }
        let controller = PebbleAgentController()
        controller.session = try AgentSimulationSession.restoring(checkpoint)
        controller.activeWorld = world
        var probeInventoryByAgentID: [String: [ItemStack?]] = [:]
        for ordinal in states.indices {
            let agentID = "agent_\(ordinal)"
            let probe = LabCoreAgentEntity(
                world: world,
                labAgentId: agentID,
                physicalId: "fixture-\(name)-\(agentID)"
            )
            probe.setPos(Double(ordinal), 64, 0)
            let carriedByIdentity = ordinal < carried.count
                ? carried[ordinal] : [:]
            for stack in carriedByIdentity.values.sorted(by: {
                $0.id < $1.id
            }) {
                guard let slot = probe.carriedItems.firstIndex(where: {
                    $0 == nil
                }) else {
                    throw ControllerError.homeostasisBoundary(
                        "physical fixture inventory capacity"
                    )
                }
                probe.carriedItems[slot] = stack.copy()
            }
            world.addEntity(probe)
            controller.probesByAgentId[agentID] = probe
            probeInventoryByAgentID[agentID] = copyItemInventory(
                probe.carriedItems
            )
        }
        return PebbleMortalityPhysicalFixture(
            controller: controller,
            world: world,
            container: container,
            previous: previous,
            pendingBytes: try session.durableStateBytes(),
            probeInventoryByAgentID: probeInventoryByAgentID,
            worldEntityIDs: Set(world.entities.map(ObjectIdentifier.init)),
            session: session,
            recorder: recorder
        )
    }

    private func mortalityPhysicalFixtureAgent(
        ordinal: Int,
        terminal: Bool
    ) -> AgentSessionAgentState {
        let position = AgentPosition(x: ordinal, y: 64, z: 0)
        return AgentSessionAgentState(
            id: "agent_\(ordinal)",
            state: "idle",
            position: position,
            needs: AgentNeeds(
                hunger: terminal ? 0.99 : 0,
                fatigue: 0,
                curiosity: 0,
                safety: 1
            ),
            health: terminal ? 1 : 100,
            fear: 0,
            homePosition: position,
            nearbyAgents: [],
            currentGoal: AgentGoal(
                kind: .idle,
                reason: "mortality physical fixture",
                startedAtTick: 0,
                urgency: 0
            ),
            lastAction: nil,
            lastActionEffect: nil,
            memory: [],
            tickCreated: 0,
            ticksAlive: 0,
            observationCount: 0,
            nearbyObservationCount: 0,
            goalSelectionCount: 0,
            goalChangeCount: 0,
            actionCount: 0,
            actionEffectCount: 0,
            movementCount: 0,
            totalManhattanDistanceMoved: 0,
            returnHomeMoveCount: 0,
            totalDistanceReducedTowardHome: 0,
            survivalProgress: AgentSurvivalProgress()
        )
    }

    private func physicalQuantity(
        itemID: Int,
        in slots: [ItemStack?]?
    ) -> Int {
        slots?.compactMap { $0 }.filter { $0.id == itemID }
            .reduce(0) { $0 + $1.count } ?? 0
    }

    private func requireMortalityPhysicalProof(
        _ condition: @autoclosure () throws -> Bool,
        _ reason: String
    ) throws {
        guard try condition() else {
            throw ControllerError.homeostasisBoundary(
                "mortality physical proof failed: \(reason)"
            )
        }
    }
}
