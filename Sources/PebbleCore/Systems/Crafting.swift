// Crafting — grid matching (shaped with
// mirroring, shapeless, tags), enchanting table / anvil / grindstone math.

import Foundation

private func ingMatches(_ ing: String, _ stack: ItemStack?) -> Bool {
    guard let stack else { return false }
    let name = itemDef(stack.id).name
    if ing.hasPrefix("#") { return tagMatches(String(ing.dropFirst()), name) }
    return ing == name
}

/// match a w×h grid of stacks against all recipes; returns output or nil
public func matchCrafting(_ grid: [ItemStack?], _ gw: Int, _ gh: Int) -> (out: ItemStack, recipe: CraftRecipe)? {
    // trim grid to bounding box
    var minX = gw, minY = gh, maxX = -1, maxY = -1
    for y in 0..<gh {
        for x in 0..<gw {
            if grid[y * gw + x] != nil {
                minX = min(minX, x); maxX = max(maxX, x)
                minY = min(minY, y); maxY = max(maxY, y)
            }
        }
    }
    if maxX < 0 { return nil }
    let bw = maxX - minX + 1, bh = maxY - minY + 1

    for r in craftingRecipes {
        switch r {
        case .shapeless(let inputs, let out, let count):
            var ok = true
            var used = [Bool](repeating: false, count: gw * gh)
            for ing in inputs {
                var found = false
                for i in 0..<grid.count {
                    if used[i] || grid[i] == nil { continue }
                    if ingMatches(ing, grid[i]) { used[i] = true; found = true; break }
                }
                if !found { ok = false; break }
            }
            if ok {
                // no extra items
                var extra = false
                for i in 0..<grid.count where grid[i] != nil && !used[i] { extra = true }
                if !extra { return (ItemStack(iid(out), count), r) }
            }
        case .shaped(let rw, let rh, let rgrid, let out, let count):
            if rw != bw || rh != bh { continue }
            for mirror in [false, true] {
                var ok = true
                for y in 0..<bh where ok {
                    for x in 0..<bw where ok {
                        let rx = mirror ? bw - 1 - x : x
                        let ing = rgrid[y * rw + rx]
                        let stack = grid[(minY + y) * gw + (minX + x)]
                        if ing == nil { if stack != nil { ok = false } }
                        else if !ingMatches(ing!, stack) { ok = false }
                    }
                }
                if ok { return (ItemStack(iid(out), count), r) }
            }
        }
    }
    return nil
}

/// consume one of each ingredient; returns container items (buckets/bottles)
public func consumeCraftingGrid(_ grid: inout [ItemStack?]) -> [ItemStack] {
    var returns: [ItemStack] = []
    for i in 0..<grid.count {
        guard let s = grid[i] else { continue }
        let name = itemDef(s.id).name
        if name == "milk_bucket" || name == "water_bucket" || name == "lava_bucket" {
            returns.append(ItemStack(iid("bucket"), 1))
        }
        if name == "honey_bottle" { returns.append(ItemStack(iid("glass_bottle"), 1)) }
        s.count -= 1
        if s.count <= 0 { grid[i] = nil }
    }
    return returns
}

// ---------------------------------------------------------------------------
// Actor-neutral inventory crafting
// ---------------------------------------------------------------------------

/// One exact source-slot debit selected by the canonical recipe matcher.
///
/// This is physical planning data, not an inventory reservation. Callers must
/// still revalidate the live inventory before applying `inventoryAfter`.
public struct CanonicalCraftingInput {
    public let slot: Int
    public let stack: ItemStack
    public let quantity: Int
}

/// A pure preview of one canonical crafting transformation.
///
/// Recipe matching and ingredient/tag semantics remain in PebbleCore. The
/// returned inventory is a deep copy and no live holder is mutated here.
public struct CanonicalCraftingMutation {
    public let recipeID: String
    public let gridWidth: Int
    public let gridHeight: Int
    public let inputs: [CanonicalCraftingInput]
    public let output: ItemStack
    public let containerReturns: [ItemStack]
    public let inventoryAfter: [ItemStack?]
}

private func canonicalCraftingRecipeOutput(
    _ recipe: CraftRecipe
) -> (name: String, count: Int) {
    switch recipe {
    case let .shaped(_, _, _, out, count),
         let .shapeless(_, out, count):
        return (out, count)
    }
}

private func canonicalCraftingRecipeID(
    _ recipe: CraftRecipe,
    registrationIndex: Int
) -> String {
    let output = canonicalCraftingRecipeOutput(recipe)
    let shape: String
    switch recipe {
    case let .shaped(width, height, grid, _, _):
        shape = "shaped:\(width)x\(height):" + grid.map { $0 ?? "_" }
            .joined(separator: ",")
    case let .shapeless(inputs, _, _):
        shape = "shapeless:" + inputs.joined(separator: ",")
    }
    return "craft:\(registrationIndex):\(output.name):\(output.count):\(shape)"
}

private func canonicalCraftingIngredientMatches(
    _ ingredient: String,
    _ stack: ItemStack
) -> Bool {
    let name = itemDef(stack.id).name
    if ingredient.hasPrefix("#") {
        return tagMatches(String(ingredient.dropFirst()), name)
    }
    return ingredient == name
}

/// Resolves and previews one real crafting operation from an existing physical
/// inventory. Registration order, shaped/mirrored matching, tags, canonical
/// output, stack capacity and container returns all remain authoritative.
///
/// The search is bounded to the supplied inventory, a maximum 3x3 grid and the
/// registered recipe list. Source slots are selected in ascending order.
public func canonicalCraftingMutation(
    producing outputItemKey: String,
    from inventory: [ItemStack?],
    gridWidth: Int,
    gridHeight: Int
) -> CanonicalCraftingMutation? {
    guard !outputItemKey.isEmpty,
          (1...3).contains(gridWidth), (1...3).contains(gridHeight),
          !inventory.isEmpty, inventory.count <= 54 else { return nil }

    for (registrationIndex, recipe) in craftingRecipes.enumerated() {
        let recipeOutput = canonicalCraftingRecipeOutput(recipe)
        guard recipeOutput.name == outputItemKey else { continue }

        let ingredients: [String]
        let recipeWidth: Int
        let recipeHeight: Int
        switch recipe {
        case let .shaped(width, height, grid, _, _):
            guard width <= gridWidth, height <= gridHeight else { continue }
            ingredients = grid.compactMap { $0 }
            recipeWidth = width
            recipeHeight = height
        case let .shapeless(inputs, _, _):
            guard inputs.count <= gridWidth * gridHeight else { continue }
            ingredients = inputs
            recipeWidth = min(gridWidth, max(1, inputs.count))
            recipeHeight = max(1, (inputs.count + gridWidth - 1) / gridWidth)
        }

        var remaining = inventory.map { $0?.count ?? 0 }
        var selected: [(slot: Int, ingredient: String)] = []
        var complete = true
        for ingredient in ingredients {
            guard let slot = inventory.indices.first(where: { index in
                guard remaining[index] > 0, let stack = inventory[index] else {
                    return false
                }
                return canonicalCraftingIngredientMatches(ingredient, stack)
            }) else {
                complete = false
                break
            }
            remaining[slot] -= 1
            selected.append((slot, ingredient))
        }
        guard complete else { continue }

        var grid = [ItemStack?](
            repeating: nil,
            count: gridWidth * gridHeight
        )
        switch recipe {
        case let .shaped(width, height, recipeGrid, _, _):
            var selectedIndex = 0
            for y in 0..<height {
                for x in 0..<width {
                    guard recipeGrid[y * width + x] != nil else { continue }
                    let source = inventory[selected[selectedIndex].slot]!.copy()
                    source.count = 1
                    grid[y * gridWidth + x] = source
                    selectedIndex += 1
                }
            }
        case .shapeless:
            for (index, selection) in selected.enumerated() {
                let source = inventory[selection.slot]!.copy()
                source.count = 1
                grid[index] = source
            }
        }

        guard let matched = matchCrafting(grid, gridWidth, gridHeight),
              itemDef(matched.out.id).name == outputItemKey,
              matched.out.count == recipeOutput.count else { continue }

        let matchedRecipeID: String
        if let matchedIndex = craftingRecipes.firstIndex(where: { candidate in
            canonicalCraftingRecipeID(candidate, registrationIndex: 0)
                .split(separator: ":", maxSplits: 1).dropFirst().first
                == canonicalCraftingRecipeID(matched.recipe, registrationIndex: 0)
                    .split(separator: ":", maxSplits: 1).dropFirst().first
        }) {
            matchedRecipeID = canonicalCraftingRecipeID(
                matched.recipe,
                registrationIndex: matchedIndex
            )
        } else {
            matchedRecipeID = canonicalCraftingRecipeID(
                recipe,
                registrationIndex: registrationIndex
            )
        }

        var inventoryAfter = copyItemInventory(inventory)
        var debits: [Int: Int] = [:]
        for selection in selected { debits[selection.slot, default: 0] += 1 }
        for slot in debits.keys.sorted() {
            guard let stack = inventoryAfter[slot],
                  let quantity = debits[slot], stack.count >= quantity else {
                complete = false
                break
            }
            stack.count -= quantity
            if stack.count == 0 { inventoryAfter[slot] = nil }
        }
        guard complete else { continue }

        var consumedGrid = grid
        let returns = consumeCraftingGrid(&consumedGrid)
        let output = matched.out.copy()
        let outputInsertion = output.copy()
        guard insertItemStack(
            outputInsertion,
            quantity: outputInsertion.count,
            into: &inventoryAfter
        ) == matched.out.count,
            outputInsertion.count == 0 else { continue }
        var returnsInserted = true
        for returned in returns {
            let insertion = returned.copy()
            let quantity = insertion.count
            guard insertItemStack(
                insertion,
                quantity: quantity,
                into: &inventoryAfter
            ) == quantity, insertion.count == 0 else {
                returnsInserted = false
                break
            }
        }
        guard returnsInserted else { continue }

        let inputs = debits.keys.sorted().compactMap { slot -> CanonicalCraftingInput? in
            guard let source = inventory[slot], let quantity = debits[slot] else {
                return nil
            }
            let stack = source.copy()
            stack.count = quantity
            return CanonicalCraftingInput(
                slot: slot,
                stack: stack,
                quantity: quantity
            )
        }
        return CanonicalCraftingMutation(
            recipeID: matchedRecipeID,
            gridWidth: max(recipeWidth, gridWidth),
            gridHeight: max(recipeHeight, gridHeight),
            inputs: inputs,
            output: matched.out.copy(),
            containerReturns: returns.map { $0.copy() },
            inventoryAfter: inventoryAfter
        )
    }
    return nil
}

/// smithing: template + base + addition
public func matchSmithing(_ template: ItemStack?, _ base: ItemStack?, _ addition: ItemStack?) -> ItemStack? {
    guard let template, let base, let addition else { return nil }
    let tName = itemDef(template.id).name
    let bName = itemDef(base.id).name
    let aName = itemDef(addition.id).name
    for r in smithingRecipes {
        if r.template != tName { continue }
        if r.output == "trim" {
            // any armor + trim material
            if itemDef(base.id).armor == nil { continue }
            if !TRIM_MATERIALS.contains(aName) { continue }
            let out = base.copy()
            out.data.trim = TrimData(pattern: tName.replacingOccurrences(of: "_armor_trim", with: ""), material: aName)
            return out
        }
        if r.base == bName && r.addition == aName {
            let out = base.copy()
            out.id = iid(r.output)
            return out
        }
    }
    return nil
}

// ---------------------------------------------------------------------------
// Enchanting table
// ---------------------------------------------------------------------------
public struct EnchantOption {
    public var level: Int          // XP level cost requirement
    public var lapis: Int          // 1-3
    public var preview: EnchInstance?
    public var enchants: [EnchInstance]
}

public func enchantingOptions(_ item: ItemStack?, _ bookshelves: Int, _ seed: Int) -> [EnchantOption] {
    var out: [EnchantOption] = []
    guard let item else { return out }
    let def = itemDef(item.id)
    let isBook = def.name == "book"
    if !isBook && !ENCHANTMENTS.contains(where: { appliesTo($0, def) }) { return out }
    if !item.ench.isEmpty { return out } // already enchanted
    var rng = RandomX(UInt32(truncatingIfNeeded: seed))
    let b = min(15, bookshelves)
    let base = rng.nextInt(8) + 1 + (b >> 1) + rng.nextInt(b + 1)
    let levels = [
        Int(max(Double(base) / 3, 1)),
        Int(Double(base) * 2 / 3 + 1),
        max(base, b * 2),
    ]
    for slot in 0..<3 {
        let level = levels[slot]
        var slotRng = RandomX(UInt32(truncatingIfNeeded: seed + slot * 947))
        let enchants = selectEnchants(item, level, &slotRng)
        out.append(EnchantOption(level: level, lapis: slot + 1, preview: enchants.first, enchants: enchants))
    }
    return out
}

private func selectEnchants(_ item: ItemStack, _ level: Int, _ rng: inout RandomX) -> [EnchInstance] {
    let def = itemDef(item.id)
    let isBook = def.name == "book"
    let enchValue = enchantability(def)
    var modLevel = level + 1 + rng.nextInt((enchValue >> 2) + 1) + rng.nextInt((enchValue >> 2) + 1)
    let bonus = 1 + (rng.nextFloat() + rng.nextFloat() - 1) * 0.15
    modLevel = max(1, Int(detRound(Double(modLevel) * bonus)))
    var picked: [EnchInstance] = []
    var candidates: [(e: EnchantmentDef, lvl: Int)] = []
    for e in ENCHANTMENTS {
        if e.treasure || e.curse { continue }
        if !isBook && !appliesTo(e, def) { continue }
        var l = e.maxLevel
        while l >= 1 {
            if modLevel >= e.minPower(l) && modLevel <= e.maxPower(l) {
                candidates.append((e, l))
                break
            }
            l -= 1
        }
    }
    if candidates.isEmpty { return picked }
    let first = rng.pickWeighted(candidates) { Double($0.e.weight) }
    picked.append(EnchInstance(first.e.id, first.lvl))
    var lvl2 = modLevel
    while rng.nextFloat() < Double(lvl2 + 1) / 50 {
        lvl2 = Int((Double(lvl2) / 2).rounded(.down))
        let remaining = candidates.filter { c in
            picked.allSatisfy { p in compatible(c.e, enchDef(p.id)) } && !picked.contains { $0.id == c.e.id }
        }
        if remaining.isEmpty { break }
        let next = rng.pickWeighted(remaining) { Double($0.e.weight) }
        picked.append(EnchInstance(next.e.id, next.lvl))
    }
    return picked
}

public func applyEnchanting(_ item: ItemStack, _ option: EnchantOption) -> ItemStack {
    let def = itemDef(item.id)
    if def.name == "book" {
        return ItemStack(iid("enchanted_book"), 1, ench: option.enchants)
    }
    let result = item.copy()
    result.ench = option.enchants
    return result
}

// ---------------------------------------------------------------------------
// Anvil
// ---------------------------------------------------------------------------
public struct AnvilResult {
    public var out: ItemStack
    public var cost: Int
}

private let REPAIR_MATS: [String: String] = [
    "leather": "leather", "chainmail": "iron_ingot", "iron": "iron_ingot", "golden": "gold_ingot",
    "diamond": "diamond", "netherite": "netherite_ingot", "turtle": "scute", "elytra": "phantom_membrane",
    "wooden": "oak_planks", "stone": "cobblestone",
]

public func anvilCombine(_ left: ItemStack?, _ right: ItemStack?, _ rename: String?) -> AnvilResult? {
    guard let left else { return nil }
    let out = left.copy()
    var cost = 0.0
    let prior = (left.data.priorWork ?? 0) + (right?.data.priorWork ?? 0)
    cost += pow(2, Double(left.data.priorWork ?? 0)) - 1
    if let right { cost += pow(2, Double(right.data.priorWork ?? 0)) - 1 }

    if let right {
        let ldef = itemDef(left.id), rdef = itemDef(right.id)
        let rName = rdef.name
        let material: String? = ldef.tool != nil
            ? REPAIR_MATS[String(ldef.name.split(separator: "_")[0])]
            : ldef.armor != nil ? REPAIR_MATS[ldef.armor!.material] : nil
        if rName == "enchanted_book" && !right.ench.isEmpty {
            // book apply
            var newEnch = out.ench
            var applied = false
            for be in right.ench {
                let e = enchDef(be.id)
                if itemDef(left.id).name != "enchanted_book" && !appliesTo(e, ldef) { continue }
                let conflict = newEnch.contains { $0.id != be.id && !compatible(e, enchDef($0.id)) }
                if conflict { cost += 1; continue }
                if let idx = newEnch.firstIndex(where: { $0.id == be.id }) {
                    newEnch[idx].lvl = newEnch[idx].lvl == be.lvl ? min(e.maxLevel, newEnch[idx].lvl + 1) : max(newEnch[idx].lvl, be.lvl)
                } else {
                    newEnch.append(be)
                }
                cost += Double(be.lvl) * (e.weight >= 10 ? 1 : e.weight >= 5 ? 2 : e.weight >= 2 ? 4 : 8) / 2
                applied = true
            }
            if !applied { return nil }
            out.ench = newEnch
        } else if let material, rName == material {
            // unit repair: each mat repairs 25%
            let maxD = ldef.tool?.durability ?? ldef.armor?.durability ?? 0
            if maxD == 0 || left.damage == 0 { return nil }
            let quarter = Int((Double(maxD) / 4).rounded(.up))
            let units = min(right.count, Int((Double(left.damage) / (Double(maxD) / 4)).rounded(.up)))
            out.damage = max(0, left.damage - units * quarter)
            cost += Double(units)
            out.data.repairUnits = units
        } else if right.id == left.id {
            // combine same items
            let maxD = ldef.tool?.durability ?? ldef.armor?.durability ?? 0
            if maxD != 0 {
                let totalLife = (maxD - left.damage) + (maxD - right.damage) + Int((Double(maxD) * 0.12).rounded(.down))
                out.damage = max(0, maxD - totalLife)
                cost += 2
            }
            // merge enchants
            if !right.ench.isEmpty {
                var newEnch = out.ench
                for be in right.ench {
                    let e = enchDef(be.id)
                    let conflict = newEnch.contains { $0.id != be.id && !compatible(e, enchDef($0.id)) }
                    if conflict { cost += 1; continue }
                    if let idx = newEnch.firstIndex(where: { $0.id == be.id }) {
                        newEnch[idx].lvl = newEnch[idx].lvl == be.lvl ? min(e.maxLevel, newEnch[idx].lvl + 1) : max(newEnch[idx].lvl, be.lvl)
                    } else { newEnch.append(be) }
                    cost += Double(be.lvl)
                }
                out.ench = newEnch
            }
        } else {
            return nil
        }
    }
    if let rename, rename != (left.label ?? "") {
        out.label = rename.isEmpty ? nil : rename
        cost += 1
    }
    if cost <= 0 { return nil }
    out.data.priorWork = prior + 1
    return AnvilResult(out: out, cost: min(39, Int(cost.rounded(.up))))
}

/// grindstone: strip enchants, repair by combining, return XP value
public func grindstoneResult(_ a: ItemStack?, _ b: ItemStack?) -> (out: ItemStack, xp: Int)? {
    guard let item = a ?? b else { return nil }
    if let a, let b, a.id != b.id { return nil }
    let def = itemDef(item.id)
    let out = item.copy()
    var xp = 0
    if !out.ench.isEmpty {
        for e in out.ench {
            if !enchDef(e.id).curse { xp += enchDef(e.id).minPower(e.lvl) }
        }
        out.ench = out.ench.filter { enchDef($0.id).curse }
    }
    if let a, let b {
        let maxD = def.tool?.durability ?? def.armor?.durability ?? 0
        if maxD != 0 {
            let totalLife = (maxD - a.damage) + (maxD - b.damage) + Int((Double(maxD) * 0.05).rounded(.down))
            out.damage = max(0, maxD - totalLife)
        }
    }
    if def.name == "enchanted_book" && out.ench.isEmpty {
        out.id = iid("book")
    }
    out.data = StackData()
    return (out, min(50, Int((Double(xp) / 2).rounded(.up))))
}
