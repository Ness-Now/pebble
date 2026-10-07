# PS01 — Core typed JSON Boolean legacy compatibility

The correction restores historical numeric Boolean flags at their schema-owned
entity/Player load boundaries. The numeric-fidelity dependency already preserves
new Boolean writes. No writer transformation is added here. Git is publication
authority; this document records the bounded correction and its evidence.

Qualification baseline: `ed1f1fc1668817e938a0986b3b18709df4c4df52`, tree
`723ba38df190b11f5376ae176903f7356f9df3a9`, sole parent
`bf804aa74b8a4a99bb44b7c2e65a35e2a6aa5476`, subject
`fix(core): preserve JSON Binary64 semantics across persistence`.
Fetched origin and independent `git ls-remote` agree. Connectivity, sole-parent,
merge-base, non-shallow and replacement checks establish clean ancestry.
The new managed worktree starts at that exact commit. Protected I09,
live-occupancy and historical Boolean drafts supply evidence only.

## Pre-edit reproduction

An external probe linked only the clean baseline Core objects. Separate OS
processes installed the immutable historical SQLite VCK1/Player bytes, loaded
those bytes, wrote current typed objects, and read current durable records.

| Case | Baseline observation |
| --- | --- |
| Historical Chicken `airborne:0`, `gene:"sentinel-preserve"` | Typed EntityData fails; the entire bag becomes empty and gene is lost. |
| Historical Chicken `airborne:1`, same valid siblings | Same whole-bag loss. |
| Historical Player items, effects and bag | Inventory/effects/bag fallback reproduces the accepted loss. |
| Current false/true Chicken and Player | Bool flags and unrelated siblings survive. |
| Current recursively nested items/effects/all Player containers | Durable flags are JSON true/false; typed load succeeds. |

Writer, historical reader and current reader PIDs were 45110, 45109 and 45111;
fixture installer PID was 45108. Independent Python JSON inspection confirms
current Boolean tokens and unchanged historical numeric tokens in actual rows.
The [immutable fixtures](../../Tests/Fixtures/CoreTypedJSON/README.md) retain
source canonical identity, SHA-256 and owner expectations. They are never
regenerated using the current writer or modified in place.

## Closed Boolean owner inventory

Exactly two production sanitizer entry points exist: `encodeChunk` sanitizes
entity dictionaries; `putPlayer` sanitizes the complete Player dictionary.
All Core entity save/load overrides and Codable bridges were re-audited.

| Owner | Bool keys | Persisted route | Historically exposed | Compatibility owner |
| --- | --- | --- | --- | --- |
| EntityData | puffed, grazing, baby, brown, sheared, charged, captain, cold, hanging, aiming, airborne, crossed, leatherBoots, persistent | Entity.save → chunk entities → SaveDB/VCK1; Player.save → putPlayer | Yes, all optional flags | Entity.load's EntityData schema |
| StackData | charged | ItemEntity.stack → chunk entities | Yes | ItemEntity.load's ItemStack schema |
| StackData | charged | Player inventory/armor/enderChest/offHand → putPlayer | Yes | Player.load's item/array schemas |
| StackData | charged | Boat/Minecart.chestItems → chunk entities | Yes | Each vehicle load's item-array schema |
| StackData | charged | Villager.offers buyA/buyB/sell → chunk entities | Yes | Villager.load's trade schema |
| StackData | charged | Recursive contents under each exposed ItemStack | Yes | Same item schema follows only data.contents |
| ActiveEffect | ambient, showParticles | Player.effects → putPlayer | Yes, optional flags | Player.load's effects schema |
| Player nested EntityData/items/effects | Same keys above | Loose-file legacy Player import → existing putPlayer → getPlayer → Player.load | Yes | Same Player/Entity load boundaries; importer unchanged |
| BlockEntityData | glowing, extending, isSourceHead, active, exactTeleport, canSummon | Separate JSONEncoder/materializer → blockEntities VCK1 tail → typed decoder | No | Existing strict decoder; no compatibility conversion |
| StackData under BlockEntityData | charged | items/disc/item and their recursive contents in blockEntities tail | No | Existing strict block-entity typed decoder |
| WorldRecord/DimState | dragonKilled, externalContinuationRequired; raining, thundering | Direct JSONEncoder/JSONDecoder World row | No | Existing strict typed codec |
| SignInscriptionIndexEnvelope | valid | Separate direct typed inscription index stored transactionally beside chunks | No | Existing strict index codec |
| Settings | fancyGraphics, smoothLighting, bloom, shadows, clouds, viewBobbing, invertY, subtitles, autoJump, reduceMotion, reducedFlashes, highContrast, simpleMesh | Direct JSONEncoder/JSONDecoder settings.json | No | Existing strict settings codec |
| EntityPlacementPosition/ReservedPoint | None; isValid/isComplete belong to separate runtime assessments | Coordinate-only Codable values outside entity/Player sanitation | No | Existing coordinate owners |
| Entity/Mob/subclass scalar flags | persistent, baby, sitting, saddled, tamed, hasChest, showBottom, captain | Native Swift scalar writes in entity dictionaries | Native Boolean identity was retained; existing dynamic Bool readers already handle numeric 0/1 | Existing subclass readers unchanged |
| LivingEntity effects/equipment; WanderingTrader runtime offers | Runtime flags / StackData where present | No separate persistent override for these fields | No additional exposed typed route | No new persistence promise |
| Advancements/keybinds | None | String-array/string-dictionary codecs | No | Existing owners |
| Block/item/effect registry definitions | Definition flags such as opaque, solid, meat and beneficial | Runtime registries; not persisted World typed payloads | No | Registry construction |

EntityData numeric siblings remain variant/color/size/pattern/stingTimer/
buckTimer/loveCause integers, swelling/open Doubles and swimTarget Double array.
Gene/deathCause/deathAttacker remain strings. ItemStack id/count/damage, enchant
levels, StackData priorWork/repairUnits/flight/lodestone, trade maxUses/uses/xp,
and effect duration/amplifier remain numeric. TrimData and enchant IDs are
strings. No other Bool-bearing Codable owner enters the sanitized graph.

## Reader boundary and malformed policy

[LegacyBooleanJSON.swift](../../Sources/PebbleCore/Game/LegacyBooleanJSON.swift)
first attempts the existing standard typed decode. Successful current payloads
return immediately, avoiding a second walk or codec pass. Only a failed decode
may normalize known legacy fields and retry the same standard decoder.

The schema identifies exact keys and recursive paths. Numeric NSNumber values
exactly equal to zero or one become false or true at those Bool fields.
CFBoolean already has Boolean identity. Missing/null optional fields retain
nil. Other numbers (including adjacent nonzero Binary64 values), strings
`"true"`/`"false"`, arrays and objects remain untouched and fail their existing
typed owner. There is no generic dictionary traversal or numeric-to-Bool pass.
Normalizers use the existing dictionary/array representation, copy only changed
paths, and do not parse numeric tokens or retain a second JSON type tree.

EntityData corruption still resets the bag. ItemEntity corruption still defaults
the stack; Player corruption resets the affected item container or rejects its
effects array; vehicle corruption clears chest items; Villager corruption clears
offers. A valid historical Bool no longer triggers these policies. Unrelated
corruption is not partially salvaged. Ordinary standalone EntityData, StackData,
ActiveEffect and BlockEntityData decoders remain strict.

The shared PersistenceJSON materializer, persistedDouble, standard JSONDecoder
numeric semantics, sanitation, VCK1 encoding, SQLite schema and resident chunk
selection are unchanged. No migration, version bump or rewrite-on-open is
introduced. Reading the raw historical rows leaves their VCK1 and Player bytes
identical. Normal future gameplay saves naturally emit Boolean tokens.

## Regression matrix

The [focused suite](../../Sources/pebsmoke/PebbleCoreLegacyBooleanSmoke.swift)
runs in normal pebsmoke and as `PEBBLELAB_SMOKE_ONLY=core-boolean-legacy`.
Each of all 14 EntityData flags is tested with false, true, numeric 0/1,
0.0/1.0, null, missing and every unsupported representation. Complete typed
bag equality proves sibling conservation. StackData and both ActiveEffect flags
have the same positive/negative matrix across their owning load boundaries.
Current and historical recursive items, all Player containers, both vehicles
and all three Villager trade positions are covered. Unexposed block-entity
flags/items remain strict and current block-container writes still succeed.

Separate OS processes exercise current writer/reader, immutable legacy
installer/reader, and mixed Boolean/Double writer/reader pairs. The mixed fixture
combines known airborne 0/1 with velocity bits `3fb64bc177620800`, swelling bits
`3f4bda1bd51d42c8` and signed-zero open. All exact comparisons remain bitPattern
comparisons; numeric 0/1 siblings stay numeric, and CFBoolean cannot satisfy a
Double owner. The mixed fixture is disclosed synthetic input; it is separate
from the immutable historical fixture campaign.

A separate installer derives disclosed malformed VCK1/Player fixtures without
changing the source bytes. Fresh baseline and corrected readers each pass the
same 16 negative-policy checks: unsupported numbers, strings, arrays and objects
retain whole-bag/container/default policies, while independent numeric Player
siblings survive. This completes the durable current/current, independent
token inspection, immutable legacy/current and malformed/current matrix.

The numeric suite was first run unchanged: 195/1, solely because its residual
Boolean assertion expected the historical defect to remain. That assertion now
requires charged false and the exact 0.1 sibling bits. No numeric test,
comparator, edge fixture or finite-corpus expectation was weakened or removed.
The historical correct-token numeric matrix restores the three original velocity
patterns; already-altered historical swelling restores its stored c6 pattern,
with no claim to reconstruct unavailable original c8 bits.

## Normal writer, real app and fresh readers

The normal writer uses genuine seed-5 terrain, a bounded 105-chunk search for
an existing generated Chicken, and 41 normal GameCore frames. Chicken.tick
produces airborne false; a sentinel gene and an explicitly assigned exact-bit
swelling sibling exercise bag conservation. Player has disclosed typed item
and effect fixtures. Ordinary synchronous save and exit write the records.
Writer PID 47614 and fresh reader PID 47493 agree on complete typed state,
all captured numeric bit patterns and exactly one Player/selected Chicken.
No positive writer proof rewrites SQLite.

After the live dry-run, the real debug Pebble client opens an isolated copy
containing the immutable six-entity VCK1 record and the historical Player
payload in its normal World envelope. Only camera position/orientation in this
derived visual copy is adjusted before launch; every historical typed flag and
all other Player siblings remain unchanged. Source fixtures and the original
normal World remain immutable. SHA-256 records distinguish the original inner
Player payload and this disclosed derived envelope.

The client advances from tick 41 to 121, then the existing exact-tick capture
hook freezes simulation while rendering 600 frames. The inspected capture
shows both Chicken models, the Minecart and Villager in unmodified forest
terrain, with coherent Player item/effect UI. Loading-screen, distant-camera
and uncommitted-terrain attempts are retained as rejected visual evidence.

The initial static reader verified all six legacy owners before physics.
During the warm-up, the fixture Boat falls more than three blocks and uses
Core Boat.onLand/breakBoat: it becomes one oak chest Boat item and its two
exact chest stacks. A static six-entity assertion therefore fails after normal
physics. The post-physics reader instead requires precisely those three causal
drops, consumes the complete expected stack multiset once, and retains exact
Minecart/trade/Player nested payloads, both Chicken bags and the generated
Chicken's hard numeric sibling. No product rule or persistence comparator is
changed to accommodate the fixture. The failed static assumption is retained.

The post-app numeric reader independently decodes actual durable JSON and
compares every restored record with exact multiplicity: **132 records / 1,179
scalar bit-pattern comparisons**, plus available nested Double fields, PASS at
tick 121. The Boolean/physical reader passes complete recursive stack
conservation and all selected Bool owners. Every Pebble process exits through
normal termination; disposable files remain for review. This is a bounded
historical persistence/VGS proof, not a live-occupancy campaign.

## Measured compatibility cost

Identical warmed debug benchmarks compare exact published ed1f1fc Core with
this correction on the same host. Five timed rounds per operation report
median microseconds. Only this mission's compiler was briefly suspended during
timing and resumed in a finally block. Contended measurements are retained and
explicitly excluded. These measurements are not a release latency guarantee.

| Current valid payload | ed1f1fc µs | Correction µs | Change |
| --- | ---: | ---: | ---: |
| EntityData restore | 9.735 | 9.782 | +0.047 / +0.5% |
| 36-slot nested inventory/effects restore | 429.761 | 436.639 | +6.878 / +1.6% |
| Durable Player restore | 2,470.614 | 2,484.933 | +14.320 / +0.6% |
| 32-entity durable chunk restore | 2,484.355 | 2,467.118 | −17.236 / −0.7% |

An initial always-normalize design added substantial nested-restore overhead.
The final strict-first owner boundary avoids that extra current-payload walk
and conversion. No cache or dirty-state subsystem is added.

| Immutable legacy payload | ed1f1fc µs | Correction µs | Change |
| --- | ---: | ---: | ---: |
| EntityData restore | 27.221 | 58.833 | +31.612 / +116.1% |
| Nested inventory/effects restore | 256.239 | 689.116 | +432.877 / +168.9% |
| Durable Player restore | 2,067.030 | 2,511.172 | +444.142 / +21.5% |
| Six-entity durable chunk restore | 4,158.651 | 4,811.472 | +652.821 / +15.7% |

The legacy baseline timings execute the broken fallback and lose typed bags,
containers and effects. They do less work; these relative costs are not
comparisons of equivalent successful restorations. Corrected legacy reads pay
for the failed strict attempt, narrow normalization and successful typed retry.
Ordinary subsequent gameplay writes naturally emit current Boolean tokens,
without a rewrite-on-open requirement.

## Qualification results

All commands use the managed correction checkout and disposable persistence
homes. `PEBBLELAB_SMOKE_ONLY=<mode> .build/debug/pebsmoke` selects the focused
rows below; complete commands/environments and logs are in the review package.

| Qualification | Result |
| --- | --- |
| core-boolean-legacy | 414 parent checks, plus 50 checks in six separate OS processes; zero failures |
| Retained current/legacy/mixed storage readers and loose-file import | All pass; raw historical VCK1/Player bytes remain unchanged after reads |
| Malformed durable baseline/correction readers | Same 16 policy checks pass in each fresh process |
| core-json-numeric | 196/0 after replacing only the obsolete residual-Boolean assertion; unchanged run retained as 195/1 |
| core-json-numeric-corpus | 99,952 finite values; zero exact mismatches; 48 non-finite patterns excluded |
| Historical numeric fixture matrix | Exact stored-token semantics preserved, including already-altered historical tokens |
| core-resident-entities | 69 parent checks plus 60 checks in 14 fresh OS readers; zero failures |
| materials / candidate-physical-atomicity | 35/0 and 3/0 |
| civ-45-correction07 / civ-45-correction08 | 8/0 and 6/0 |
| ps01-increment-06-restart / checkpoint-replay | 782/0 and 49/0 |
| Normal World writer / fresh reader | Complete typed state and exact numeric bits pass at tick 41 |
| Live dry-run / real app / fresh readers | Dry-run and normal app termination pass; causal Boolean conservation and 132-record exact numeric reader pass |
| scripts/verify-pebblelab.sh | Debug and all three release products build; full smoke reports 6,495 passed / exactly three accepted historical failures; exit 1 at stage 5 |
| Supplemental canonical stages 6–35 | All 30 stages pass; command tail byte-identical to canonical; exit 0 |
| Source/docs/diff and protected worktrees | Relative links, unchanged persistence/numeric ownership surfaces, fixture hashes and git diff checks pass; protected changes remain identical |

The three canonical failures are exactly zoo bit-identical, combat lockstep
and eight A* paths node-identical. No new unexplained failure appears. The
supplemental driver changes only its repository-root assignment and replaces
stages 1–5 with a disclosed `STEP=5`; its remaining commands/comparators match
the canonical script byte for byte. The canonical script itself is unchanged.

The external review package contains exact commands/environments, source and
linkage manifests, immutable fixture provenance, raw DB/VCK1/Player bytes,
fresh-reader PIDs, complete assertion logs, canonical/supplemental gate results,
real-app captures, performance samples, protected-worktree checks, exact
baseline/candidate identities, full-index patch and SHA-256 manifest.

This is the historical typed-Boolean correction only. It does not continue
live occupancy, I09, collision semantics, entity identity, Mob.ownerId or any
civilization product phase. No golden is regenerated and no publication command
is attempted.
