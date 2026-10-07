# Immutable historical typed Boolean fixtures

These bytes were extracted from real SQLite rows written by a separate process
linked to unchanged canonical `bf804aa74b8a4a99bb44b7c2e65a35e2a6aa5476`
(tree `0530c309bb1be0460b4cdf25381ee630050f0b73`). The protected historical
Boolean mission retained them. Their hashes were independently checked against
the numeric-fidelity review's protected-worktree manifest before reuse.
Do not regenerate or edit these fixtures with the current writer.

| File | SHA-256 |
| --- | --- |
| canonical-bf804aa.vck | e3f0816deb0061b610cd705c88207fa199404bbe572a74744dd1ec9deb680a0b |
| canonical-bf804aa-player.json | 475b7502cb74c51499b4317d9b6b1591774df6b8b83e9cc4f5aea7f7889f73ab |

The VCK1 entity-only record contains six entities: false/true Chicken bags,
ItemEntity, Boat, Minecart and Villager. Chicken bags include historical
`"airborne":0` / `"airborne":1` alongside `"gene":"sentinel-preserve"`,
all 14 optional EntityData Bool fields, numeric 0/1 counters, strings and arrays.
Player contains EntityData, all inventory containers, recursive StackData and
both ActiveEffect flags. StackData.charged and effect flags are numeric 0/1.

Compatibility is owned by the historically sanitized entity/Player reader
boundary, then by the exact schema keys. Expected typed values are the original
false/true values, with all valid siblings conserved. The raw installer bypasses
the current writer and separate OS readers use production SaveDB/loadEntity/
Player.load. Reads must not rewrite the durable bytes. BlockEntityData's own
flags and its direct typed item codec were not exposed and remain strict.
