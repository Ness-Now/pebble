import PebbleCore

func runPebbleCoreProductionSmoke() {
    section("core canonical production")

    let stoneInputs: [ItemStack?] = [
        ItemStack(iid("cobblestone"), 3),
        ItemStack(iid("stick"), 2),
        nil,
    ]
    let stone = canonicalCraftingMutation(
        producing: "stone_pickaxe",
        from: stoneInputs,
        gridWidth: 3,
        gridHeight: 3
    )
    check(
        "production resolves registered stone pickaxe recipe",
        stone?.recipeID.contains(":stone_pickaxe:1:shaped:") == true
    )
    check(
        "production consumes exact stone pickaxe inputs",
        stone?.inputs.map { itemDef($0.stack.id).name + ":\($0.quantity)" }
            == ["cobblestone:3", "stick:2"]
    )
    check(
        "production creates canonical stone pickaxe output",
        stone.map {
            itemDef($0.output.id).name == "stone_pickaxe"
                && $0.output.count == 1 && $0.output.damage == 0
        } == true
    )
    check(
        "production inventory transformation conserves exact inputs",
        stone?.inventoryAfter.compactMap { $0 }.count == 1
            && stone?.inventoryAfter.compactMap({ $0 }).first.map {
                itemDef($0.id).name == "stone_pickaxe" && $0.count == 1
            } == true
    )
    check(
        "production preview does not mutate source inventory",
        stoneInputs[0]?.count == 3 && stoneInputs[1]?.count == 2
    )

    let bread = canonicalCraftingMutation(
        producing: "bread",
        from: [ItemStack(iid("wheat"), 3)],
        gridWidth: 3,
        gridHeight: 3
    )
    check(
        "production supports second canonical recipe",
        bread.map {
            $0.recipeID.contains(":bread:1:shaped:")
                && itemDef($0.output.id).name == "bread"
                && $0.inputs.count == 1 && $0.inputs[0].quantity == 3
        } == true
    )
    check(
        "production refuses missing ingredient",
        canonicalCraftingMutation(
            producing: "stone_pickaxe",
            from: [ItemStack(iid("cobblestone"), 3), ItemStack(iid("stick"), 1)],
            gridWidth: 3,
            gridHeight: 3
        ) == nil
    )
    check(
        "production refuses wrong quantity",
        canonicalCraftingMutation(
            producing: "bread",
            from: [ItemStack(iid("wheat"), 2)],
            gridWidth: 3,
            gridHeight: 3
        ) == nil
    )
    check(
        "production refuses wrong material identity",
        canonicalCraftingMutation(
            producing: "bread",
            from: [ItemStack(iid("carrot"), 3)],
            gridWidth: 3,
            gridHeight: 3
        ) == nil
    )
    check(
        "production refuses three-wide recipe without workstation grid",
        canonicalCraftingMutation(
            producing: "stone_pickaxe",
            from: stoneInputs,
            gridWidth: 2,
            gridHeight: 2
        ) == nil
    )

    var full: [ItemStack?] = [
        ItemStack(iid("cobblestone"), 64),
        ItemStack(iid("stick"), 64),
    ]
    while full.count < 16 { full.append(ItemStack(iid("dirt"), 64)) }
    check(
        "production refuses when canonical output has no custody capacity",
        canonicalCraftingMutation(
            producing: "stone_pickaxe",
            from: full,
            gridWidth: 3,
            gridHeight: 3
        ) == nil
    )

    let tagged = canonicalCraftingMutation(
        producing: "wooden_pickaxe",
        from: [ItemStack(iid("oak_planks"), 3), ItemStack(iid("stick"), 2)],
        gridWidth: 3,
        gridHeight: 3
    )
    check(
        "production delegates tag resolution to canonical recipe authority",
        tagged.map { itemDef($0.output.id).name == "wooden_pickaxe" } == true
    )
}
