import Foundation
import PebbleAgents
import PebbleCore

private func physicalFoodAgent(
    hunger: Double,
    inventory: AgentResourceInventory = AgentResourceInventory(capacity: 128)
) -> AgentSessionAgentState {
    let position = AgentPosition(x: 0, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_food", state: "idle", position: position,
        needs: AgentNeeds(hunger: hunger, fatigue: 0, curiosity: 0, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(kind: .idle, reason: "fixture", startedAtTick: 0, urgency: 0),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0, resourceInventory: inventory
    )
}

private func physicalFoodSession(
    _ id: String,
    hunger: Double,
    inventory: AgentResourceInventory = AgentResourceInventory(capacity: 128),
    survival: AgentSurvivalConfiguration = .live
) -> AgentSimulationSession {
    let configuration = try! AgentSessionConfiguration(
        seed: 46, memoryPolicy: .bounded(maxEntries: 128),
        survivalConfiguration: survival
    )
    return try! AgentSimulationSession(
        configuration: configuration,
        agents: [physicalFoodAgent(hunger: hunger, inventory: inventory)],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
}

private func physicalOutcome(
    _ session: AgentSimulationSession,
    id: String,
    material: String,
    hungerPoints: Int,
    saturation: Double,
    slot: Int = 0
) -> AgentValidatedPhysicalFoodConsumptionOutcome {
    let actor = try! session.state(for: "agent_food")
    let reduction = min(1, Double(hungerPoints) / 20)
    return AgentValidatedPhysicalFoodConsumptionOutcome(
        consumptionID: id,
        agentID: actor.agentID,
        tick: session.tick,
        canonicalMaterialName: material,
        quantityConsumed: 1,
        coreHungerPoints: hungerPoints,
        coreSaturation: saturation,
        normalizedHungerReduction: reduction,
        status: .succeeded,
        physicalReceiptID: id,
        sourceLocationID: "agent:physical_food_probe",
        sourceSlot: slot,
        hungerBefore: actor.needs.hunger,
        hungerAfter: max(0, actor.needs.hunger - reduction)
    )
}

private func seedLegacyAbstractFood(
    _ session: inout AgentSimulationSession,
    count: Int
) {
    for index in 0..<count {
        try! session.applyInteractionOutcome(AgentInteractionOutcome(
            interactionId: "legacy-food-fixture-\(index)",
            agentId: "agent_food",
            tick: session.tick,
            target: AgentPosition(x: index, y: 64, z: 1),
            resource: .foodRaw,
            status: .succeeded,
            inventoryDelta: AgentInventoryDelta(resource: .foodRaw, quantity: 1),
            reason: "historical coarse food fixture"
        ))
    }
}

func runPebbleCorePhysicalFoodSurvivalSmoke() {
    section("PebbleCore canonical food semantics and Player parity")

    func descriptor(_ name: String) -> FoodConsumptionDescriptor? {
        foodConsumptionDescriptor(for: ItemStack(iid(name)))
    }
    let berries = descriptor("sweet_berries")
    let cod = descriptor("cod")
    let salmon = descriptor("salmon")
    let chicken = descriptor("chicken")
    let bread = descriptor("bread")
    let wheat = descriptor("wheat")
    let cookedSalmon = descriptor("cooked_salmon")
    check("food matrix sweet berries exact", berries?.canonicalMaterialName == "sweet_berries"
        && berries?.food.hunger == 2 && berries?.food.saturation == 0.4
        && berries?.disposition == .consumeStack)
    check("food matrix cod exact", cod?.food.hunger == 2 && cod?.food.saturation == 0.4)
    check("food matrix salmon exact", salmon?.food.hunger == 2 && salmon?.food.saturation == 0.4)
    check("food matrix raw chicken exact registry and effect", chicken?.canonicalMaterialName == "chicken"
        && chicken?.food.hunger == 2 && chicken?.food.saturation == 1.2
        && chicken?.food.effects.first?.effect == "hunger")
    check("food matrix bread exact", bread?.food.hunger == 5 && bread?.food.saturation == 6)
    check("food matrix wheat is not directly edible", wheat == nil && itemDef(iid("wheat")).food == nil)
    check("food matrix second differentiated food", cookedSalmon?.food.hunger == 6
        && cookedSalmon?.food.saturation == 9.6)
    check("special remainder metadata exact", descriptor("mushroom_stew")?.disposition == .replaceWithBowl
        && descriptor("milk_bucket")?.disposition == .replaceWithBucketAndClearEffects)
    check("special teleport metadata exact", descriptor("chorus_fruit")?.disposition == .teleportThenConsume)
    check("always-eat and effect metadata exact", descriptor("golden_apple")?.food.alwaysEat == true
        && descriptor("golden_apple")?.hasEffects == true)

    var carried: [ItemStack?] = [ItemStack(iid("sweet_berries"), 2)]
    let selected = carried.indices.first {
        carried[$0].flatMap(foodConsumptionDescriptor)?.hasSimpleDebit == true
    }
    let extracted = extractItemStack(
        matching: ItemStack(iid("sweet_berries"), 1), quantity: 1,
        from: &carried, slotFilter: { $0 == selected }
    )
    check("Core exact simple food debit", selected == 0 && extracted?.count == 1
        && carried[0]?.count == 1)

    let world = World(dim: .overworld, seed: 46)
    let player = Player(world: world)
    let context = InteractCtx(world: world, player: player)
    player.hunger = 10
    player.saturation = 1
    player.inventory[player.selectedSlot] = ItemStack(iid("bread"), 2)
    finishUsingItem(context)
    check("Player simple food hunger and saturation parity", player.hunger == 15
        && player.saturation == 7)
    check("Player simple food exact debit parity", player.mainHand?.count == 1
        && itemDef(player.mainHand!.id).name == "bread")

    player.hunger = 10
    player.saturation = 0
    player.inventory[player.selectedSlot] = ItemStack(iid("mushroom_stew"), 1)
    finishUsingItem(context)
    check("Player bowl remainder parity", player.hunger == 16
        && player.mainHand.map { itemDef($0.id).name } == "bowl")

    player.hunger = 20
    player.inventory[player.selectedSlot] = ItemStack(iid("golden_apple"), 1)
    check("Player always-eat start parity", useItem(context, nil))
    finishUsingItem(context)
    check("Player food effects parity", player.effects.contains { $0.id == "regeneration" }
        && player.effects.contains { $0.id == "absorption" })

    player.setGameMode(GameMode.creative)
    player.inventory[player.selectedSlot] = ItemStack(iid("bread"), 2)
    check("Player creative always starts food use", useItem(context, nil))
    finishUsingItem(context)
    check("Player creative food debit parity", player.mainHand?.count == 2)
}

func runPebbleAgentsPhysicalFoodSurvivalSmoke() {
    section("PebbleAgents conserved physical food survival")

    var disabled = physicalFoodSession("sim-food-disabled", hunger: 0.6)
    check("physical food authority defaults off", disabled.foodAuthorityMode == .legacyAbstract
        && !disabled.physicalFoodSurvivalEnabled)
    check("physical food activation requires survival", {
        do { try disabled.setPhysicalFoodSurvivalEnabled(true); return false }
        catch AgentSessionError.physicalFoodSurvival(.survivalRequired) { return true }
        catch { return false }
    }())

    var legacy = physicalFoodSession("sim-food-legacy", hunger: 0.6)
    seedLegacyAbstractFood(&legacy, count: 1)
    legacy.setSurvivalEnabled(true)
    let legacyOutcome = try! legacy.consumeFood(AgentConsumptionIntent(
        consumptionId: "legacy-food", agentId: "agent_food", tick: 0
    ))
    check("legacy foodRaw remains compatible while physical gate off",
          legacyOutcome.status == .succeeded
            && (try! legacy.state(for: "agent_food")).needs.hunger == 0)

    var shadow = physicalFoodSession("sim-food-shadow", hunger: 0.8)
    seedLegacyAbstractFood(&shadow, count: 100)
    shadow.setSurvivalEnabled(true)
    try! shadow.setPhysicalFoodSurvivalEnabled(true)
    let shadowBefore = try! shadow.durableStateBytes()
    check("physical authority disables foodRaw consumption", {
        do {
            _ = try shadow.consumeFood(AgentConsumptionIntent(
                consumptionId: "shadow-food", agentId: "agent_food", tick: 0
            ))
            return false
        } catch AgentSessionError.physicalFoodSurvival(.legacyAbstractAuthorityDisabled) {
            return true
        } catch { return false }
    }())
    check("shadow refusal is atomic", (try! shadow.durableStateBytes()) == shadowBefore
        && (try! shadow.state(for: "agent_food")).resourceInventory.count(of: .foodRaw) == 100)

    let berry = physicalOutcome(
        shadow, id: "physical-berry", material: "sweet_berries",
        hungerPoints: 2, saturation: 0.4
    )
    try! shadow.applyValidatedPhysicalFoodConsumption(berry)
    let berryState = try! shadow.state(for: "agent_food")
    let physical = shadow.physicalFoodSurvivalSnapshot()!
    check("real berry nutrition uses Core 2 of 20 bridge", abs(berryState.needs.hunger - 0.7) < 1e-12
        && physical.completedOutcomes.last == berry)
    check("physical consumption updates canonical survival progress",
          berryState.survivalProgress?.foodConsumedCount == 1
            && berryState.survivalProgress?.consecutiveCriticalHungerTicks == 0)
    check("physical eating creates no abstract debit or credit",
          berryState.resourceInventory.count(of: .foodRaw) == 100
            && shadow.conservationSnapshot().consumedTotal == 0)
    let duplicateBytes = try! shadow.durableStateBytes()
    check("duplicate validated outcome refused", {
        do { try shadow.applyValidatedPhysicalFoodConsumption(berry); return false }
        catch AgentSessionError.physicalFoodSurvival(.duplicateConsumption("physical-berry")) {
            return true
        } catch { return false }
    }())
    check("duplicate outcome has no second survival effect",
          (try! shadow.durableStateBytes()) == duplicateBytes
            && shadow.physicalFoodSurvivalSnapshot()?.completedOutcomes.count == 1)

    var breadSession = physicalFoodSession("sim-food-bread", hunger: 0.8)
    breadSession.setSurvivalEnabled(true)
    try! breadSession.setPhysicalFoodSurvivalEnabled(true)
    try! breadSession.applyValidatedPhysicalFoodConsumption(physicalOutcome(
        breadSession, id: "physical-bread", material: "bread",
        hungerPoints: 5, saturation: 6
    ))
    check("different FoodDef values produce different survival effects",
          (try! breadSession.state(for: "agent_food")).needs.hunger == 0.55
            && berry.normalizedHungerReduction == 0.1)

    var full = physicalFoodSession("sim-food-full", hunger: 0)
    full.setSurvivalEnabled(true)
    try! full.setPhysicalFoodSurvivalEnabled(true)
    full.setSurvivalEnabled(false)
    check("physical authority keeps canonical survival enabled",
          full.survivalEnabled && full.physicalFoodSurvivalEnabled)
    check("full-hunger physical consumption refused", {
        let outcome = physicalOutcome(
            full, id: "physical-full", material: "bread",
            hungerPoints: 5, saturation: 6
        )
        do { try full.applyValidatedPhysicalFoodConsumption(outcome); return false }
        catch AgentSessionError.physicalFoodSurvival(.noHungerNeed) { return true }
        catch { return false }
    }())

    let starvationConfig = try! AgentSurvivalConfiguration(
        hungerPerTick: 0.05, fatiguePerTick: 0.01,
        hungryThreshold: 0.4, criticalHungerThreshold: 0.8,
        hungerRecoveryThreshold: 0.15, fatigueThreshold: 0.9,
        fatigueRecoveryThreshold: 0.2, foodNutrition: 1,
        restRecoveryPerTick: 1, starvationGraceTicks: 0,
        starvationDamagePerTick: 10
    )
    var starving = physicalFoodSession(
        "sim-food-starving", hunger: 0.8,
        survival: starvationConfig
    )
    seedLegacyAbstractFood(&starving, count: 100)
    starving.setSurvivalEnabled(true)
    try! starving.setPhysicalFoodSurvivalEnabled(true)
    _ = try! starving.advanceTick()
    check("abstract foodRaw cannot prevent canonical starvation",
          (try! starving.state(for: "agent_food")).health == 90
            && (try! starving.state(for: "agent_food")).resourceInventory.count(of: .foodRaw) == 100)

    var rescued = physicalFoodSession(
        "sim-food-rescued", hunger: 0.8, survival: starvationConfig
    )
    rescued.setSurvivalEnabled(true)
    try! rescued.setPhysicalFoodSurvivalEnabled(true)
    try! rescued.applyValidatedPhysicalFoodConsumption(physicalOutcome(
        rescued, id: "physical-rescue", material: "sweet_berries",
        hungerPoints: 2, saturation: 0.4
    ))
    _ = try! rescued.advanceTick()
    check("physical food changes the same hunger used by starvation",
          (try! rescued.state(for: "agent_food")).health == 100
            && abs((try! rescued.state(for: "agent_food")).needs.hunger - 0.75) < 1e-12)

    let checkpoint = try! rescued.makeCheckpoint()
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    check("physical food checkpoint writes v17", checkpoint.schemaVersion == 17)
    check("physical food v17 restore is byte exact",
          (try! restored.durableStateBytes()) == (try! rescued.durableStateBytes()))
    check("v1 through v16 remain supported and default physical state absent",
          (1...16).allSatisfy(AgentCheckpointSchema.supports)
            && disabled.durableState().physicalFoodSurvivalState == nil)

    var replayBase = physicalFoodSession("sim-food-replay", hunger: 0.8)
    replayBase.setSurvivalEnabled(true)
    let replayCheckpoint = try! replayBase.makeCheckpoint()
    var replayed = replayBase
    var recorder = try! AgentReplayRecorder(checkpoint: replayCheckpoint, session: replayed)
    try! recorder.apply(.setPhysicalFoodSurvivalEnabled(true), to: &replayed)
    let replayOutcome = physicalOutcome(
        replayed, id: "physical-replay", material: "bread",
        hungerPoints: 5, saturation: 6
    )
    try! recorder.apply(.validatedPhysicalFoodConsumption(replayOutcome), to: &replayed)
    let journal = try! recorder.journal(named: AgentCheckpointName(rawValue: "physical-food")!)
    let verification = try! AgentSessionReplayer.replay(
        checkpoint: replayCheckpoint, journal: journal
    )
    check("physical food replay is v17 validated outcomes only",
          journal.manifest.schemaVersion == 17 && verification.report.verified)
    check("physical food replay restores history and causal digest",
          (try! verification.session.durableStateBytes()) == (try! replayed.durableStateBytes())
            && verification.report.finalCausalDigest
                == replayed.causalLedgerSnapshot().summary.digest)

    try! replayed.setPhysicalFoodSurvivalEnabled(false)
    check("disabling physical authority restores legacy without conversion",
          replayed.foodAuthorityMode == .legacyAbstract
            && replayed.physicalFoodSurvivalSnapshot() == nil)
    let disabledAgain = try! replayed.durableStateBytes()
    try! replayed.setPhysicalFoodSurvivalEnabled(false)
    check("physical authority disable is byte-idempotent",
          (try! replayed.durableStateBytes()) == disabledAgain)
}
