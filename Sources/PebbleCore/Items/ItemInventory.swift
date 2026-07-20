/// Actor-neutral operations over the inventory representation already used by
/// Player, block entities, vehicles, and crafting grids.
///
/// These functions are the shared stack-rule authority for new custody
/// adapters. They operate on real `ItemStack` instances and delegate identity,
/// merge, maximum-stack, and durability rules to the item registry.

public func copyItemInventory(_ slots: [ItemStack?]) -> [ItemStack?] {
    slots.map(copyStack)
}

public func itemInventoryQuantity(
    matching prototype: ItemStack,
    in slots: [ItemStack?],
    slotFilter: ((Int) -> Bool)? = nil
) -> Int {
    slots.enumerated().reduce(0) { total, entry in
        let (index, stack) = entry
        guard slotFilter?(index) ?? true,
              let stack,
              stacksEqual(stack, prototype) else {
            return total
        }
        return total + stack.count
    }
}

public func itemInventoryInsertionCapacity(
    for prototype: ItemStack,
    in slots: [ItemStack?],
    slotFilter: ((Int) -> Bool)? = nil
) -> Int {
    guard prototype.id >= 0, prototype.id < itemDefs.count else { return 0 }
    var capacity = 0
    for (index, stack) in slots.enumerated() where slotFilter?(index) ?? true {
        if let stack, canMerge(stack, prototype) {
            capacity += max(0, maxStackOf(stack) - stack.count)
        } else if stack == nil {
            capacity += maxStackOf(prototype)
        }
    }
    return capacity
}

/// Inserts at most `quantity` units, merging before filling empty slots.
///
/// The source stack's count is reduced by the exact inserted quantity, matching
/// existing Player/hopper reference semantics. The returned quantity is never
/// larger than either the request, source count, or real registry capacity.
@discardableResult
public func insertItemStack(
    _ source: ItemStack,
    quantity: Int,
    into slots: inout [ItemStack?],
    slotFilter: ((Int) -> Bool)? = nil
) -> Int {
    guard quantity > 0,
          source.count > 0,
          source.id >= 0,
          source.id < itemDefs.count else {
        return 0
    }
    var remaining = min(quantity, source.count)
    let requested = remaining

    for index in slots.indices where remaining > 0 && (slotFilter?(index) ?? true) {
        guard let destination = slots[index], canMerge(destination, source) else { continue }
        let moved = min(remaining, max(0, maxStackOf(destination) - destination.count))
        destination.count += moved
        source.count -= moved
        remaining -= moved
    }
    for index in slots.indices where remaining > 0 && (slotFilter?(index) ?? true) {
        guard slots[index] == nil else { continue }
        let moved = min(remaining, maxStackOf(source))
        let inserted = source.copy()
        inserted.count = moved
        slots[index] = inserted
        source.count -= moved
        remaining -= moved
    }
    return requested - remaining
}

/// Extracts exactly `quantity` stack-compatible units or performs no mutation.
public func extractItemStack(
    matching prototype: ItemStack,
    quantity: Int,
    from slots: inout [ItemStack?],
    slotFilter: ((Int) -> Bool)? = nil
) -> ItemStack? {
    guard quantity > 0,
          itemInventoryQuantity(matching: prototype, in: slots, slotFilter: slotFilter) >= quantity else {
        return nil
    }
    let extracted = prototype.copy()
    extracted.count = quantity
    var remaining = quantity
    for index in slots.indices where remaining > 0 && (slotFilter?(index) ?? true) {
        guard let stack = slots[index], stacksEqual(stack, prototype) else { continue }
        let moved = min(remaining, stack.count)
        stack.count -= moved
        remaining -= moved
        if stack.count <= 0 { slots[index] = nil }
    }
    return remaining == 0 ? extracted : nil
}

public enum ItemStackDurabilityResult: String, Equatable {
    case unchanged
    case damaged
    case broken
}

/// Applies the existing durability and Unbreaking rule to a real stack.
/// Callers own the physical slot and remove the stack when `.broken` is returned.
@discardableResult
public func damageItemStack(
    _ stack: ItemStack,
    amount: Int,
    random: () -> Double
) -> ItemStackDurabilityResult {
    guard amount > 0 else { return .unchanged }
    let maximumDamage = maxDamageOf(stack)
    guard maximumDamage > 0 else { return .unchanged }
    let unbreaking = enchLevel(stack, "unbreaking")
    let before = stack.damage
    for _ in 0..<amount {
        if unbreaking > 0,
           random() < Double(unbreaking) / Double(unbreaking + 1) {
            continue
        }
        stack.damage += 1
    }
    if stack.damage >= maximumDamage { return .broken }
    return stack.damage == before ? .unchanged : .damaged
}
