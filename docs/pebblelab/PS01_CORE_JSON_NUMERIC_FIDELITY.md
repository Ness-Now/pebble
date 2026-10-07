# PS01 — Core JSON numeric fidelity

This correction gives schema-owned finite `Double` fields one end-to-end
invariant: the current writer preserves the input Binary64 value, and the
reader restores the correctly rounded Binary64 value represented by the
durable JSON token. Comparisons use `bitPattern`, including signed zero.
JSON, SQLite and VCK1 remain the persistence representation.

The qualification baseline is `bf804aa74b8a4a99bb44b7c2e65a35e2a6aa5476`,
tree `0530c309bb1be0460b4cdf25381ee630050f0b73`, sole parent
`07a88bdc91d0fa15494b073674125f4de84354bc`, in `Ness-Now/pebble`.
The fetched `lab/pebblelab-v1` and an independent `git ls-remote` agreed on
that exact authority. The candidate identity, full-index patch and SHA-256
manifest belong to the review package; Git remains publication authority.

## Both defects reproduced before implementation

The clean canonical Core was built and linked into an external probe. Each
case used `Entity.save`, `SaveDB.putChunks`, actual SQLite VCK1 bytes and
`SaveDB.getChunk`/`Entity.load`. A separate OS process independently decoded
the durable bytes. No protected draft supplied an implementation patch.

| Canonical case | Native bits | Durable token | Foundation `doubleValue` / owner bits | `JSONDecoder` of durable bytes |
| --- | --- | --- | --- | --- |
| Accepted velocity | `3fb64bc177620800` | `0.087093440672134648` | `3fb64bc177620802` | `3fb64bc177620800` |
| Real Chicken velocity X | `bfb6dd9adda2435d` | `-0.089318923101257622` | `bfb6dd9adda2435c` | `bfb6dd9adda2435d` |
| Real Chicken velocity Z | `bf81c198cd9559d2` | `-0.0086700380076480156` | `bf81c198cd9559d0` | `bf81c198cd9559d2` |
| Nested `EntityData.swelling` | `3f4bda1bd51d42c8` | `0.00084997519500448131` | `3f4bda1bd51d42c6` | `3f4bda1bd51d42c6` |

For swelling, `JSONEncoder` first emitted the correct token
`0.0008499751950044815`. `JSONSerialization` materialized an
`NSDecimalNumber`; `as? Double` and `doubleValue` both yielded the changed
`c6` bits. The old sanitizer emitted that changed native Double. The durable
token consequently represented `c6` before any reader ran. This reproduction
contains no Boolean field and does not depend on the Boolean defect.

All four original decimal tokens materialized as `NSDecimalNumber`, CFNumber
type ID 22, not CFBoolean (type ID 21), with Objective-C type `d` on the
qualification host. Their `stringValue` and direct JSONSerialization
re-encoding retained the originating decimal token. That does not make
`stringValue` a universal exact route. The old sanitizer would also replace
the accepted read token with `0.087093440672134675` if handed that dynamic
number for another write. The actual canonical velocity row above still
contains its correct original token.

Evidence: `baseline-probe.log`, `canonical-scalar-stages.log`,
`fixture-reader.log`, and immutable `canonical-fixtures/` in the review package.
The canonical fresh-reader probe exited 2 for the demonstrated numeric failure.

## Foundation boundary classification

The audit independently repeated 32 token cases and seven original scalar
classes, then explicitly exercised native Swift Double, NSNumber(Double),
JSONSerialization NSDecimalNumber, native Int, integer NSNumber, CFBoolean,
native Bool, NSNull, String, arrays and dictionaries. It recorded casts,
`doubleValue`, `stringValue`, re-encoding, sanitation and typed decoding.

| Input | Relevant behavior and selected treatment |
| --- | --- |
| Native Double / NSNumber(Double) | Standard JSONSerialization numeric bytes decode exactly in the finite corpus. Keep finite values rather than replacing them during sanitation. |
| NSDecimalNumber from JSON | `as? Double` and `doubleValue` can differ from the original token. Re-enter standard JSONDecoder through numeric JSON bytes for schema Double extraction. |
| Native Int / integer NSNumber | Preserve integer values and existing integer readers. The materializer tries representable nonzero Int before Double. |
| CFBoolean / Bool | NSNumber ancestry is insufficient numeric evidence. Reject CFBoolean in the Double reader; materialize JSON Boolean as Bool. |
| NSNull / String / array / dictionary | Never coerce these into a scalar Double. Preserve each owner's fallback and recurse only when materializing/sanitizing collections. |

Universal `NSNumber.stringValue` parsing is disproved: the middle subnormal
becomes an adjacent value, minimum normal becomes maximum subnormal, and
maximum finite becomes infinity. Integer-form `-0` also loses its sign under
the old JSONSerialization materialization. Original-byte JSONDecoder handles
these cases, including `-0` and `-0.0`, exactly.

The canonical deterministic audit used seed `0x5053303142494e36` and 100,000
raw patterns: 48 nonfinite exclusions, 99,952 finite values, 282 typed bridge
mismatches, and zero original-byte JSONDecoder mismatches. Sources and full
classification output are retained in the review package.

## Closed write-path inventory

Classification: A = exact Double; B = integer; C = Boolean;
D = direct typed codec without dynamic numeric conversion; E = not persisted.
Every Core Codable-to-dynamic save bridge and entity save/load override was
audited, with corresponding Pebble, Agents and Lab source searches.

| Owner / persisted route | Classification and action |
| --- | --- |
| `Entity.save` / `EntityData` | A: swelling, open, swimTarget. B: variant, colors, sizes, timers and IDs. C: optional flags. Replace typed-byte dynamic materialization with the shared standard decoder. |
| Entity / Mob | A: x/y/z, vx/vy/vz, yaw/pitch, health. B: age, fire, ownerId. C: persistent, sitting, baby and other subclass flags. Retain native finite scalars in shared sanitation. |
| Player | A: inherited pose, health, saturation, xpProgress, every stats value. B: hunger, slots, XP level, mode, spawn coordinates/dimension. Shared writer and exact reader. |
| ItemEntity; Player inventory, enderChest, armor, offHand; Boat/Minecart; Villager trades | ItemStack, StackData, EnchInstance, TrimData and TradeOffer contain B/C/strings and recursive typed items, no Double. Existing typed item/trade codecs remain. |
| ActiveEffect | B: duration/amplifier; C: ambient/showParticles; string ID. No Double. Existing typed codec remains. |
| HorseBase and descendants | A: speed/jumpStrength; B/C inherited counters and flags. Common scalar writer and exact readers. |
| BlockEntityData | A: xpBank/progress; B: coordinates, counters, lootSeed, levels and nested item integers; C: flags. Replace both typed-byte and durable-byte dynamic materialization. |
| WorldRecord / DimState | A: lastPlayed/gameRules. B/C: remaining typed World fields. D: original-byte JSONEncoder/JSONDecoder already exact; retain. |
| Sign inscription index, continuation and receipt records | D: typed integer/string/opaque Data owners; no manual dynamic Double extraction. Retain existing owners. |
| Legacy Player import | Original JSON bytes cross a dynamic bridge before `putPlayer`. Use the same exact materializer; no migration or new import policy. |
| Settings | D: typed settings codec, outside World persistence. Retain. |
| Other runtime numeric fields | E: projectile damage/power, previous pose, fallDistance/gravity, Player exhaustion/total XP/mining/attack state absent from the persistence schema. No new persistence promise. |

## Closed read-path inventory

Classification: A = exact Binary64 field; B = integer;
C = typed JSONDecoder owner; D = nonpersistent/configuration/fixture.

| Owner | Class, complete fields and fallback |
| --- | --- |
| `Entity.load` / `dnum` | A: x/y/z, vx/vy/vz, yaw/pitch; fallback 0. All entity subclasses inherit this reader. |
| `Mob.load` | A: health; fallback maxHealth. LivingEntity has no separate persistence reader. |
| `HorseBase.load` | A: jumpStrength/speed; fallback 0.7/0.2. Horse, Donkey, Mule, SkeletonHorse and Llama inherit it. |
| `Player.load` | A: saturation/xpProgress/health; fallback 5/0/20. Stats values use the same exact reader; any non-number member retains the whole-map empty fallback. |
| Entity, ItemEntity, XPOrb, FallingBlock, TNT, EndCrystal, Mob, Slime, Villager, Minecart, Player and GameCore dimension load | B: `inum` and direct `intValue`/integer arrays; counters, IDs, fuse, targets, trade level/XP, fuel, hunger, slots, mode and spawn coordinates. Readers remain unchanged. |
| EntityData / BlockEntityData | C: Double fields named in the write inventory; reserialization into their existing typed decoder receives exact native numeric values. |
| WorldRecord/DimState, item stacks, effects, trades, snapshot copies, index and adapter payloads | C: existing typed decoding. Item/effect/trade payloads contain no Double. |
| Resource pack configuration, filesystem size, smoke/golden fixtures and omitted runtime state | D: no new physical persistence owner. |

The canonical Core had no `floatValue` or `int64Value` manual JSON reader.
Its only `[String: NSNumber]` Double map was Player.stats. All persisted manual
`doubleValue` extractions are covered above. The correction leaves one
production `doubleValue` use solely as a finite-validation predicate; its
result is never emitted as the persisted scalar. No approximate comparison
is introduced. The source-search transcripts accompany the package.

## Architecture and safety contracts

[PersistenceJSON.swift](../../Sources/PebbleCore/Game/PersistenceJSON.swift)
uses one private temporary `Decodable` box to materialize the existing
Any/dictionary/array representation. Standard JSONDecoder owns numeric token
parsing. The box distinguishes Boolean, nonzero representable Int, Double,
String, null and collections; zero is decoded as Double to preserve `-0`.
It introduces no generic JSON enum, retained second tree or custom parser.

The typed EntityData and block-entity write bridges use this materializer
before the existing JSONSerialization writer. Durable chunk, Player and
legacy Player bytes use it before their existing owners. `persistedDouble`
returns native Double directly and re-decodes other numeric objects through
standard JSON bytes while rejecting CFBoolean. It never parses `stringValue`.

The sanitizer validates NSNumber finiteness but retains the original finite
object. Dynamic nonfinite values become numeric zero recursively, preserving
finite siblings. Existing typed failure policies remain: failed EntityData
encoding omits the bag; failed block-entity encoding omits the array; invalid
WorldRecord encoding refuses that write. NaN and either infinity never reach
JSONSerialization. Tests exercise each policy distinctly.

Representative actual integer ranges, including Int32 endpoints, ±30,000,000,
−1/0/1 and 65,535, retain exact counters and nested item state. Integer readers
are untouched. This is not an arbitrary Int64 redesign or claim.

Retaining primitive identity incidentally preserves current writer Boolean
tokens. Historical numeric 0/1-to-Bool compatibility remains unresolved:
an old EntityData bag containing a numeric `charged` flag still fails its
existing typed decode. A focused check proves that residual behavior. No
PersistedBooleanDecoding owner migration or full Boolean fixture campaign is
included, and no Boolean publication claim is made.

## Exact-bit qualification and fixture matrix

[PebbleCoreJSONNumericFidelitySmoke.swift](../../Sources/pebsmoke/PebbleCoreJSONNumericFidelitySmoke.swift)
adds focused and opt-in corpus modes. The focused suite also runs in the
ordinary canonical smoke suite; no existing check is bypassed or weakened.

| Fixture class | Required and measured result |
| --- | --- |
| Current writer → durable SQLite/VCK1 → current reader | Original bits preserved, including swelling, its neighbors, the three velocity cases, signs/fractions, ±0, representative subnormals, minimum normal, maximum finite and exponent forms. |
| Historical canonical correct-token rows | Fresh corrected reader restores the original bits of all three velocity fixtures. |
| Historical canonical already-altered swelling row | Fresh corrected reader and independent JSONDecoder both restore stored `3f4bda1bd51d42c6`. They do not assert recovery of lost `3f4bda1bd51d42c8`. |

The expanded focused suite passed **196/0** in release. It covers every typed
EntityData Double field, both block-entity Double fields, typed World numeric
fields, all manual Player/Horse/Mob routes, CFBoolean rejection, malformed
fallbacks, recursive nonfinite safety, integer and nested inventory behavior.

The production corpus uses the fixed seed and 100,000 raw patterns, excludes
only the 48 nonfinite patterns by the declared finite contract, and tests
all **99,952 finite values with zero exact mismatches**. Each batch traverses
Entity.save, native velocity and typed swelling, SaveDB, actual SQLite/VCK1,
independent original-byte JSONDecoder, getChunk and Entity.load. No observed
failure is filtered away. Signed-zero distinctions pass the explicit edge
fixtures; the random corpus does not substitute for those fixtures.

## Natural save, process restart and rendered proof

The external natural harness uses GameCore, ordinary seeded terrain (seed 5),
normal entity factories and 41 physical `GameCore.frame` steps. A Chicken's
velocity naturally reaches `bfb41205bc01a36e`. A legitimate Creeper swelling
value `3f4bda1bd51d42c8` is deliberately assigned to exercise the typed owner;
that value is disclosed as a fixture, not claimed as natural evolution.
Player and both entities have their numeric bits captured before ordinary
`saveAndFlush(synchronous: true)` and `exitToTitle`. Neither save uses SQL
rewrites, flattening or hidden terrain preparation.

Writer PID 33115 and fresh reader PID 33515 agree exactly on the three selected
records at World tick 41. Independent decoder PID 34330 reads actual durable
bytes from all 95 chunk tails and the Player envelope, and confirms the same
selected values. Earlier harness attempts that ticked only ecology or assumed
an unwrapped Player row are retained and explicitly excluded from the proof.

After `scripts/verify-pebblelab-live.sh --dry-run` passed, the real release
Pebble app loaded an isolated copy of this saved World. It advanced normally
to tick 121, moved only the camera with the existing command hook, rendered
180 frames and closed through normal AppKit termination. The accepted
`live-restored-final.png` visibly shows the restored Chicken and Creeper in
unmodified terrain. Foliage-obstructed and loading-screen attempts are retained
as rejected captures. The screenshot supplements exact data proof.

A separate post-app reader (PID 37249) compares the actual durable records
using original-byte JSONDecoder against fresh GameCore owners: **126 records,
1,130 scalar exact-bit comparisons, PASS** at tick 121, plus exact available
nested Double fields. The comparison consumes a multiset with exact counts;
ordinary overlapping pigs invalidate a unique-position harness assumption,
not numeric fidelity. The failed unique-position assertion and diagnostic
are preserved. No entity identity persistence change is made.

This is a bounded numeric persistence qualification in natural terrain, not
live-occupancy continuation, I09 or a general gameplay campaign. All launched
Pebble processes exited; isolated artifacts were retained for review.

## Owning validation and canonical gate

Commands run from the candidate worktree with distinct disposable
`CFFIXED_USER_HOME` directories. Exact command/environment records and logs
are in the package.

| Command / mode | Result |
| --- | --- |
| `swift build -c debug --target PebbleCore` on unmodified baseline | Exit 0; both defect probes then reproduced the failures. |
| `swift build -c debug --product pebsmoke` | Exit 0. |
| `PEBBLELAB_SMOKE_ONLY=core-json-numeric .build/arm64-apple-macosx/release/pebsmoke` | Exit 0; 196 passed, 0 failed. |
| `PEBBLELAB_SMOKE_ONLY=core-json-numeric-corpus .build/debug/pebsmoke` | Exit 0; 99,952 finite, 48 excluded, zero mismatches; two aggregate checks passed. |
| `PEBBLELAB_SMOKE_ONLY=core-resident-entities .build/debug/pebsmoke` | Exit 0; 69 parent checks plus all fresh-reader children passed. |
| Owning modes: materials, candidate-physical-atomicity, civ-45-correction07, civ-45-correction08, ps01-increment-06-restart, checkpoint-replay | Exit 0 each; respectively 35, 3, 8, 6, 782 and 49 checks, zero failures. |
| `scripts/verify-pebblelab.sh` | Builds 1–4 passed; stage 5 reported 6,081 passed, 3 failed; exit 1. Exactly the accepted zoo bit-identical, combat lockstep and eight A* node-identical failures. |
| External supplemental driver, canonical stages 6–35 verbatim | Exit 0; all stages 6–35 passed. Driver explicitly excludes already-reported stages 1–5 and does not claim the canonical gate passed. |
| `scripts/verify-pebblelab-live.sh --dry-run` | Exit 0; real-app and fresh-reader evidence described above. |
| `git diff --check`, documentation link check, final source inventory | Passed. |

The full gate includes entity serialization/load, Player and nested items,
effects, movement, World/save reconciliation, replay/determinism and the
complete resident suite. Resident creation, update, stale clear, transfer,
multiple entities, Player ownership, transient exclusion, Item/XP policy,
full/entity-only records, failure/retry freshness and fresh readers remain
green. Resident chunk-selection code is unchanged. No golden was regenerated;
no comparator, existing fixture or existing check was weakened.

## Measured cost

The identical external benchmark links canonical and corrected debug Core
objects on the same arm64 macOS / Swift 6.3.2 host. Five runs per case report
median microseconds per operation; logs retain every sample. These are
benchmarks, not release latency guarantees or performance thresholds.

| Operation | Canonical µs | Corrected µs |
| --- | ---: | ---: |
| Eleven-value Foundation scalar corpus | 9.61 | 47.32 |
| EntityData save/load | 27.63 | 34.49 |
| Nested Player inventory save/load | 1,351.15 | 1,355.59 |
| 32-entity durable chunk save/load | 526.39 | 1,374.83 |
| Durable Player restore | 813.54 | 4,774.30 |

Standard decoder materialization costs more for chunk and Player restore.
The correction makes this tradeoff explicit and introduces no lossy fast path.

## Historical irrecoverability and scope

**Already-persisted nested numeric values whose historical writer changed the
durable token cannot be retroactively reconstructed exactly without unavailable
information.** The corrected reader restores the value actually represented by
the stored token. It guesses no adjacent bits, performs no recovery migration,
and does not rewrite old Worlds merely because their tokens arose from this bug.
Historical evidence is distinct from a current-writer failure.

The correction adds no VCK1/schema/database change, binary side channel,
custom floating-point parser, second cognition owner or physical system.
Full historical Boolean compatibility, live-occupancy continuation, I09,
Mob.ownerId relation persistence, durable Entity.id and checkpoint redesign
remain outside its scope. Protected worktree HEAD/status/diff/file hashes
are checked before and after qualification and included in the package.

Disposition: `PS01_CORE_JSON_NUMERIC_FIDELITY_CORRECTION_READY_FOR_INDEPENDENT_REVIEW`.

Push attempted: NO
