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

        let stale = try makeMortalityPhysicalFixture(
            name: "ps01-inc02-stale-tracked-source",
            carried: [[
                "tracked": ItemStack(iid("iron_pickaxe"), 1),
                "untracked": ItemStack(iid("cobblestone"), 2),
            ]],
            materialRightsEnabled: true,
            containerAvailable: true,
            trackedAssetAgentID: "agent_0"
        )
        var staleSession = stale.session
        var staleRecorder = stale.recorder
        guard let staleProbe = stale.controller.probesByAgentId["agent_0"],
              let emptySlot = staleProbe.carriedItems.firstIndex(where: {
                  $0 == nil
              }) else {
            throw ControllerError.homeostasisBoundary(
                "stale-source fixture inventory"
            )
        }
        staleProbe.carriedItems[emptySlot] = ItemStack(iid("dirt"), 1)
        let stalePhysicalBoundary = copyItemInventory(
            staleProbe.carriedItems
        )
        var staleRejected = false
        do {
            try stale.controller.reconcileMortalityProbes(
                previous: stale.previous,
                current: &staleSession,
                recorder: &staleRecorder,
                world: stale.world
            )
        } catch {
            staleRejected = true
        }
        let staleBytesAfter = try staleSession.durableStateBytes()
        try requireMortalityPhysicalProof(
            staleRejected
                && staleBytesAfter == stale.pendingBytes
                && staleProbe.carriedItems == stalePhysicalBoundary
                && stale.container?.items?.allSatisfy({ $0 == nil }) == true
                && staleSession.mortalitySnapshot().totalDeathCount == 0
                && staleSession.pendingMortalityTransitions().count == 1,
            "changed tracked source refusal"
        )

        let full = try makeMortalityPhysicalFixture(
            name: "ps01-inc02-full-destination",
            carried: [[
                "untracked": ItemStack(iid("cobblestone"), 2),
            ]],
            materialRightsEnabled: false,
            containerAvailable: true
        )
        var fullSession = full.session
        var fullRecorder = full.recorder
        guard let fullContainer = full.container,
              let fullSlots = fullContainer.items else {
            throw ControllerError.homeostasisBoundary(
                "full-destination fixture container"
            )
        }
        for slot in fullSlots.indices {
            fullContainer.items?[slot] = ItemStack(iid("dirt"), 64)
        }
        let fullContainerBoundary = copyItemInventory(
            fullContainer.items ?? []
        )
        var fullRejected = false
        do {
            try full.controller.reconcileMortalityProbes(
                previous: full.previous,
                current: &fullSession,
                recorder: &fullRecorder,
                world: full.world
            )
        } catch {
            fullRejected = true
        }
        let fullBytesAfter = try fullSession.durableStateBytes()
        try requireMortalityPhysicalProof(
            fullRejected
                && fullBytesAfter == full.pendingBytes
                && fullContainer.items == fullContainerBoundary
                && full.controller.probesByAgentId["agent_0"]?
                    .carriedItems == full.probeInventoryByAgentID["agent_0"]
                && fullSession.mortalitySnapshot().totalDeathCount == 0
                && fullSession.pendingMortalityTransitions().count == 1,
            "capacity-constrained destination refusal"
        )

        let massCarried: [[String: ItemStack]] = [
            [
                "tracked": ItemStack(iid("iron_pickaxe"), 1),
                "untracked": ItemStack(iid("cobblestone"), 2),
            ],
            ["untracked": ItemStack(iid("dirt"), 4)],
            [:],
            ["untracked": ItemStack(iid("oak_log"), 3)],
            [:], [:], [:], [:], [:],
        ]
        let mass = try makeMortalityPhysicalFixture(
            name: "ps01-inc02-nine-death-custody",
            carried: massCarried,
            materialRightsEnabled: true,
            containerAvailable: true,
            trackedAssetAgentID: "agent_0"
        )
        var massSession = mass.session
        var massRecorder = mass.recorder
        let massReplayBefore = try massRecorder.map {
            try AgentReplayCodec.encodeRecords($0.records)
        }
        var massTransferFailureRejected = false
        do {
            try mass.controller.reconcileMortalityProbes(
                previous: mass.previous,
                current: &massSession,
                recorder: &massRecorder,
                world: mass.world,
                failurePoint: .beforePhysicalResolution(5)
            )
        } catch {
            massTransferFailureRejected = true
        }
        let massTransferBytesAfter = try massSession.durableStateBytes()
        let massTransferReplayAfter = try massRecorder.map {
            try AgentReplayCodec.encodeRecords($0.records)
        }
        try requireMortalityPhysicalProof(
            massTransferFailureRejected
                && massTransferBytesAfter == mass.pendingBytes
                && massTransferReplayAfter == massReplayBefore
                && mass.container?.items?.allSatisfy({ $0 == nil }) == true
                && Set(mass.world.entities.map(ObjectIdentifier.init))
                    == mass.worldEntityIDs
                && mass.controller.probesByAgentId.count == 9
                && mass.controller.probesByAgentId.allSatisfy {
                    $0.value.carriedItems
                        == mass.probeInventoryByAgentID[$0.key]
                }
                && massSession.mortalitySnapshot().totalDeathCount == 0
                && massSession.pendingMortalityTransitions().count == 9,
            "nine-death failure after four custody resolutions"
        )
        var massProbeFailureRejected = false
        do {
            try mass.controller.reconcileMortalityProbes(
                previous: mass.previous,
                current: &massSession,
                recorder: &massRecorder,
                world: mass.world,
                failurePoint: .afterProbeRemoval
            )
        } catch {
            massProbeFailureRejected = true
        }
        let massProbeBytesAfter = try massSession.durableStateBytes()
        let massProbeReplayAfter = try massRecorder.map {
            try AgentReplayCodec.encodeRecords($0.records)
        }
        try requireMortalityPhysicalProof(
            massProbeFailureRejected
                && massProbeBytesAfter == mass.pendingBytes
                && massProbeReplayAfter == massReplayBefore
                && mass.container?.items?.allSatisfy({ $0 == nil }) == true
                && Set(mass.world.entities.map(ObjectIdentifier.init))
                    == mass.worldEntityIDs
                && mass.controller.probesByAgentId.count == 9
                && mass.controller.probesByAgentId.allSatisfy {
                    $0.value.carriedItems
                        == mass.probeInventoryByAgentID[$0.key]
                }
                && massSession.mortalitySnapshot().totalDeathCount == 0
                && massSession.pendingMortalityTransitions().count == 9,
            "nine-death failure after probe removals"
        )
        try mass.controller.reconcileMortalityProbes(
            previous: mass.previous,
            current: &massSession,
            recorder: &massRecorder,
            world: mass.world
        )
        let massMortality = massSession.mortalitySnapshot()
        let massReceipts = massMortality.records.compactMap {
            $0.physicalCustodyResolution?.physicalReceiptID
        }
        let massRights = massSession.materialRightsSnapshot().records
        let massRestored = try AgentSimulationSession.restoring(
            massSession.makeCheckpoint()
        )
        let massRestoredBytes = try massRestored.durableStateBytes()
        let massSessionBytes = try massSession.durableStateBytes()
        try requireMortalityPhysicalProof(
            massMortality.totalDeathCount == 9
                && massMortality.pendingTransitions.isEmpty
                && massMortality.records.count == 9
                && massMortality.records.allSatisfy {
                    $0.deathTick == 1
                        && $0.physicalCustodyResolution != nil
                }
                && massReceipts.count == 9
                && Set(massReceipts).count == 9
                && massSession.populationSummary().memberCount == 0
                && massSession.snapshot().agents.isEmpty
                && mass.controller.probesByAgentId.isEmpty
                && mass.world.entities.compactMap {
                    $0 as? LabCoreAgentEntity
                }.isEmpty
                && physicalQuantity(
                    itemID: iid("iron_pickaxe"),
                    in: mass.container?.items
                ) == 1
                && physicalQuantity(
                    itemID: iid("cobblestone"),
                    in: mass.container?.items
                ) == 2
                && physicalQuantity(
                    itemID: iid("dirt"),
                    in: mass.container?.items
                ) == 4
                && physicalQuantity(
                    itemID: iid("oak_log"),
                    in: mass.container?.items
                ) == 3
                && massRights.count == 1
                && massRights[0].lastVerifiedHolder.holder
                    == .container("4,64,4")
                && massRestored.snapshot().agents.isEmpty
                && massRestored.mortalitySnapshot().totalDeathCount == 9
                && massRestoredBytes == massSessionBytes,
            "nine-death mixed custody publication and restore"
        )

        return [
            "rightsOffUntracked=transferred:3",
            "rightsOnUnregistered=transferred:2",
            "socialRecordsInvented=0",
            "emptyCustody=verified",
            "noContainer=retryable",
            "batchSecondFailure=rolledBack",
            "batchRetryDeaths=2",
            "staleSource=refused",
            "fullDestination=retryable",
            "massCustodyCohort=9",
            "massTrackedAssets=1",
            "massUntrackedItems=9",
            "massEmptyCustody=6",
            "massAfterFour=rolledBack",
            "massAfterProbeRemoval=rolledBack",
            "massRetryDeaths=9",
            "massReceipts=9",
            "duplications=0",
            "loss=0",
        ].joined(separator: " ")
    }

    private func makeMortalityPhysicalFixture(
        name: String,
        carried: [[String: ItemStack]],
        materialRightsEnabled: Bool,
        containerAvailable: Bool,
        trackedAssetAgentID: String? = nil
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
        let states = (0..<max(3, carried.count)).map { ordinal in
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
        let populationConfiguration = try AgentPopulationConfiguration(
            maximumActivePopulation: max(8, states.count)
        )
        try session.initializePopulationRegistry(
            settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
            receptionPosition: AgentPosition(x: 0, y: 64, z: 3),
            configuration: populationConfiguration
        )
        try session.setMortalityEnabled(
            true,
            configuration: states.count > 8
                ? .embodiedPopulationBounded(
                    maximumActivePopulation:
                        populationConfiguration.maximumActivePopulation
                )
                : .embodiedLive
        )
        if materialRightsEnabled {
            try session.setMaterialRightsEnabled(true)
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
        if let trackedAssetAgentID {
            guard materialRightsEnabled,
                  let trackedAgentID = AgentID(
                    rawValue: trackedAssetAgentID
                  ),
                  let probe = controller.probesByAgentId[
                    trackedAssetAgentID
                  ] else {
                throw ControllerError.homeostasisBoundary(
                    "tracked physical fixture agent"
                )
            }
            let endpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(
                probe, in: world
            )
            let custody = try controller.materialCustodyGateway.inspect(
                endpoint
            )
            guard let tracked = custody.slots.compactMap({ $0 }).first(where: {
                $0.identity.itemKey == "iron_pickaxe"
            }), tracked.count == 1 else {
                throw ControllerError.homeostasisBoundary(
                    "tracked physical fixture item"
                )
            }
            let assetID = AgentMaterialAssetID(
                rawValue: "asset:\(name):tracked-pickaxe"
            )!
            let claimID = AgentMaterialClaimID(
                rawValue: "claim:\(name):tracked-owner"
            )!
            _ = try session.applyMaterialRightsOperation(.register(
                operationID: "\(name)-register-tracked",
                asset: AgentMaterialAssetReference(
                    assetID: assetID,
                    materialIdentity: tracked.identity,
                    quantity: tracked.count
                ),
                observation: AgentMaterialHolderObservation(
                    holder: .agent(trackedAgentID),
                    materialIdentity: tracked.identity,
                    quantity: tracked.count,
                    custodyFingerprint: try controller
                        .materialCustodyGateway.fingerprint(endpoint),
                    physicalReceiptID: "\(name)-physical-acquisition",
                    observedAtTick: session.tick
                )
            ))
            _ = try session.applyMaterialRightsOperation(.assertClaim(
                operationID: "\(name)-claim-tracked",
                assetID: assetID,
                claimID: claimID,
                claimantID: trackedAgentID,
                basis: .found
            ))
            _ = try session.applyMaterialRightsOperation(.recognizeOwnership(
                operationID: "\(name)-recognize-tracked",
                assetID: assetID,
                claimID: claimID,
                recognizingAgentIDs: [trackedAgentID]
            ))
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
        controller.session = try AgentSimulationSession.restoring(checkpoint)
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
