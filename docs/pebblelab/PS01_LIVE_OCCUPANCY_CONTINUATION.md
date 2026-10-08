# PS01 live occupancy continuation

The seed-5 continuation blocker arose when ordinary gameplay brought the Player
and one Spider into already-authoritative probe bodies. At World 18052 / Session
3600, agent_1 intersected both and agent_8 intersected the same Spider. All 24
living agents retained their exact Session positions; probe-to-probe overlap was
zero. Capture rejected the existing bodies using the new-placement
`entityCollision` rule. The unchanged c7de0c baseline reproduced this failure.

## Ownership and contracts

`AgentSimulationSession` remains the sole civilization aggregate. `World` and
Core own physics, ordinary entities, chunk persistence and the Player owner.
Pebble owns probe binding, custody, capture, reconciliation and verified rollback.

Current embodiment capture validates the exact living Session/probe/World
bijection, canonical physical ownership, index binding, dimension, transient
body shape, centered position, custody and target geometry. It retains terrain,
support and fluid/hazard checks. An external live intersection alone is accepted
as existing gameplay state.

New placement and manual checkpoint admission remain strict. Core placement
assessment is unchanged, including external collisions, blocks, support,
fluids/hazards and target overlap. Probe identity and World/dimension ownership
checks remain required.

## Exact continuation capability

Core issues `WorldContinuationRestorationAuthority` only during synchronous
persisted World entry. It binds the selected raw continuation revision/payload,
WorldRecord, restored World/dimension/environment, separate persisted Player
semantics, and complete persisted chunk entity semantics. It records temporary
receipts for the actual objects Core restored; semantic clones, removed bodies,
new bodies, duplicates, foreign objects and altered state cannot borrow a saved
row. Runtime ordinary `Entity.id` is only a current-process index.

Existing schema owners interpret typed historical Boolean subpayloads. Exact
finite Binary64 interpretation remains the published Core codec. No collision
history, durable ordinary entity ID, persistent exemption, database format or
VCK1 change is added. Receipts are bounded to 279 saved chunks and 32,768 bodies.
Only individually authenticated tagged custody escrow may be absent after its
verified adoption by Pebble.

During callback entry, Core readiness is false. Normal frames/ticks and direct
Player orientation/hotbar input cannot progress the World. Entry resets the
generation epoch, restores Player and initial chunks, invokes the callback
inline, materializes bounded continuation chunks synchronously, reconciles
probes/custody, then expires the capability before publishing readiness.
No RunLoop/await or gameplay/ecology tick occurs inside the production restore
callback. Scheduled terrain work progresses only in later ticks; mesh work is
presentation. A retained capability cannot authorize later placement.

Pebble authenticates the existing envelope and manifest before acquiring Core's
capability. It publishes the restored Session only after exact physical and
custody reconciliation. Existing rollback restores the prior participant set,
probe bindings, escrow, custody and chunk modification flags; unverifiable
rollback remains a hard failure. Fault seams cover zero, one and three probe
creations, custody adoption and the late pre-publication boundary.

## Published dependency chain

- Resident ordinary entity persistence: `bf804aa74b8a4a99bb44b7c2e65a35e2a6aa5476`.
- Exact finite JSON Binary64 fidelity: `ed1f1fc1668817e938a0986b3b18709df4c4df52`.
- Schema-owned historical typed Boolean compatibility: `c7de0c870b78fd527287f29362fb7f028fe6cd1d`.

This correction starts directly from c7de0c, tree
`4df810378642050c8b3831789b61904ce728cf6b`, sole parent ed1f1fc. It changes
neither `PersistenceJSON.swift` nor `LegacyBooleanJSON.swift`, resident selection,
goldens or fixtures. It adds no roadmap phase or I09 behavior.

## Historical reconstruction

The protected historical branch remains an unqualified draft based on bf804aa,
virtual tree `25679717740c55678e30ff8fb55b00ba923c1a13` (11 paths, +1440/-44).
Its old document is historical evidence. The semantic three-way audit identified
compatible adapter concepts, a Core proof requiring reconstruction, reusable
test concepts and obsolete blocker wording. The old subset semantic check and
integer-cell-only position checks were excluded. GameCore call sites themselves
are unchanged between the old baseline and c7de0c; the published dependency
changes belong to their existing codec/schema owners.

| Final path | Derivation |
| --- | --- |
| `Sources/PebbleCore/Game/GameCore.swift` | Independently re-derived callback lifetime, chunk-loader receipts, lifecycle cleanup and Player input halt; historical callback idea selectively reconstructed. Numeric/Boolean helpers and resident-selection body unchanged. |
| `Sources/PebbleCore/Game/WorldContinuationRestoration.swift` | Materially redesigned proof: exact complete persisted semantic sets plus short-lived receipts for the actual Core-restored objects; new canonical schema owners supply numeric and historical Boolean interpretation. No durable ordinary ID or collision history. |
| `Sources/Pebble/PebbleAgentController+Lifecycle.swift` | Selectively reconstructed validated historical capability call at the unchanged canonical creation owner; ordinary admission unchanged. |
| `Sources/Pebble/PebbleAgentController+Persistence.swift` | Selectively reconstructed capture/admission distinction and authenticated collective placement; independently added exact centered coordinates, ownership checks, duplicate-safe construction, and bounded fault points using existing rollback. |
| `Sources/Pebble/PebbleAgentController+WorldContinuation.swift` | Selectively reconstructed acquisition after existing envelope/checkpoint authentication, with unchanged canonical envelope and bounded chunk owner. |
| `Sources/Pebble/PebbleContinuationEmbodimentQualification.swift` | Historical test concepts selectively reconstructed, with independently re-derived dual persisted boundaries, SQLite snapshot, ordinary post-continue progression, numeric bits, full fault matrix and same-process retry. |
| `Sources/Pebble/main.swift` | Historical renderer capture concepts selectively reconstructed; independently added rendered post-continue stage. Existing Metal renderer and camera owner reused; no gameplay actor staging. |
| `Sources/pebsmoke/PebbleCoreContinuationRestorationSmoke.swift` | Historical controlled test concepts selectively reconstructed; independently extended removed/replaced/foreign geometry and reentrant Player-input attacks. |
| `Sources/pebsmoke/main.swift` | Independently integrated mode and final invocation into c7de0c dispatcher, preserving all numeric, Boolean and resident modes. |
| `scripts/verify-pebblelab-ps01-occupancy-continuation.sh` | Historical launcher concepts selectively reconstructed; independently extended dual boundaries, five fault reader copies, retries, fresh readers and deterministic comparison. |
| `docs/pebblelab/PS01_LIVE_OCCUPANCY_CONTINUATION.md` | New stable document; historical stopped-draft document is not reused. |


## Natural product qualification

Three independent final-source writers used ordinary seed 5, difficulty 2,
24 normal founders, 4 Hz cognition and ordinary World stepping. Two ran the
production Core/controller through the headless launcher; the third ran the
actual Pebble AppDelegate and Metal renderer. No Player movement, Spider
placement, actor teleport, collider deletion or probe relocation was used to
create or resolve the overlap.

All three produced identical complete boundary records:

| Boundary | World / Session | Revision | Session digest |
| --- | --- | --- | --- |
| Natural capture and Save/Continue | 18052 / 3600 | 163740 | `ce2fb297742a90b941b09fa5c22d43d3fd298e1db2bd22c4c9f67f314ed1636f` |
| Save/Exit after 20 ordinary World ticks | 18072 / 3604 | 163958 | `545c749843aaa0863f9ec2f96bb237e7e0048a09a61777dc779a1b308cdbf2ed` |

At the natural boundary there were 24 living agents, one centered probe per
Session resident, no probe-to-probe overlap, one Player owner, and exactly one
matching naturally generated Spider intersecting agent_1 and agent_8. The
Player's natural saved health was zero; its existing owner and semantic state
were conserved. Save/Continue preserved the running objects, positions,
Session and custody, then ordinary World progression continued. Save/Exit
completed its durable boundary and normal shutdown.

Four independent headless readers restored copies of both writers' natural and
Save/Exit boundaries, each before gameplay ticking, then progressed normally
and completed Save/Continue and Save/Exit. The actual app independently restored
and rendered the natural boundary; another independent reader restored its
Save/Exit boundary. Readers converged on the recorded continuation semantics.
Ordinary runtime entity IDs were not compared across processes.

The complete saved horizon contained 121 chunks and 113 ordinary resident
records. Player plus resident records supplied 114 numeric records with 1,023
relevant exact Binary64 fields. Whole semantic records, terrain, numeric bits,
custody and probe exclusion survived. In particular, both unrelated Chicken
records in chunk (-5,-8), including subnormal velocities and typed Boolean
state, survived the former failure boundary. Historical/current Boolean decoding
also passed the unchanged schema-owner fresh-process qualification. No transient
probe appeared in chunk persistence.

The natural boundary's nine-slot agent custody was empty and conserved exactly.
Nonempty custody was additionally qualified in a disclosed controlled fixture
with three real berries, including persisted escrow, all five fault points,
verified rollback and same-process retry. That fixture is separate from the
natural gameplay proof.

## Adversarial and regression qualification

The 25 required attack/conservation cases passed. They include strict admission
into the same overlapping geometry; target overlap; missing, duplicate,
misbound and misplaced probes; foreign World/dimension; stale boundary;
changed Player/mob state; new, removed and duplicated colliders; terrain,
support and fluid/hazard checks; expired capability; and exact retry/custody.
Core's focused authority suite passed 38 checks; adapter capture/admission
passed 19; the unchanged I08 fault campaign passed 169. The nonempty five-point
rollback/retry fixture passed 30. An additional retained-capability check proved
that ordinary placement reports `entityCollision` after callback expiry.

Each of five natural-boundary fault readers forced failure before any probe,
after one, after three, after custody adoption and immediately before Session
publication. Each passed 253 checks, preserved the ordinary participant set and
Player, removed partial probes, preserved the selected durable payload/revision,
and retried in the same process without duplication. Each of four independent
headless boundary readers passed 252 checks.

Nineteen applicable owning smoke modes passed 2,766 parent checks. The unchanged
numeric corpus covered 99,952 finite values with zero exact mismatches;
`core-json-numeric` passed 196 checks. `core-boolean-legacy` passed 414, including
fresh-process legacy/current/mixed checks. Resident persistence passed 69 parent
checks plus 60 across 14 fresh readers: creation, update, stale clear,
cross-chunk transfer, multiple residents, separate Player ownership, transient
probe exclusion, Item/XP policy, full/entity-only records and failure/retry.
The remaining owning modes cover placement, embodiment, actions, reconciliation,
checkpoint replay, continuation, materials/rights, population, lifecycle,
mortality, retained historical identity, I08, PS01 increment 06 restart and
candidate physical atomicity.

The unchanged canonical gate stopped at stage 5 with 6,533 passed and exactly
three historical failures: zoo bit identity, combat lockstep and eight A* path
node identity. The unchanged baseline had 6,495 passed and the same three
failures; the 38 added authority checks account for the increase. There was no
new failure, regold, fixture change or weakened comparator. All supplemental
stages 6–35 passed; their canonical suffix was executed verbatim. Debug and
release builds passed.

Qualification entry points are:

```sh
scripts/verify-pebblelab-live.sh --dry-run
scripts/verify-pebblelab-ps01-occupancy-continuation.sh --dry-run
scripts/verify-pebblelab-ps01-occupancy-continuation.sh --headless /tmp/ps01-occupancy-proof
scripts/verify-pebblelab-ps01-occupancy-continuation.sh --live /tmp/ps01-occupancy-visual
PEBBLELAB_SMOKE_ONLY=continuation-restoration .build/arm64-apple-macosx/release/pebsmoke
PEBBLELAB_SMOKE_ONLY=core-json-numeric .build/arm64-apple-macosx/release/pebsmoke
PEBBLELAB_SMOKE_ONLY=core-json-numeric-corpus .build/arm64-apple-macosx/release/pebsmoke
PEBBLELAB_SMOKE_ONLY=core-boolean-legacy .build/arm64-apple-macosx/release/pebsmoke
PEBBLELAB_SMOKE_ONLY=core-resident-entities .build/arm64-apple-macosx/release/pebsmoke
scripts/verify-pebblelab.sh
```

Use isolated `CFFIXED_USER_HOME` values as the occupancy launcher does. The review
package records exact executed arguments, environments, exit codes, source and
binary hashes, full-index patch, complete semantic snapshots, database copies,
fault logs and SHA-256 manifest.

## Visual Game Smoke

Actual Metal captures cover the natural writer boundary, its post-continue
rendered state and an independent fresh-reader state. Natural night forest
terrain remains coherent, the World/Player presentation and HUD load, probes
and ordinary livestock are visible, and the views show no obvious added or
missing population after restore. These images do not enumerate all 24 bodies
or independently identify the intersecting Spider, which is occluded by
canopy, night and legitimate intersections. Exact semantic checks establish
population, one Player owner and one matching Spider. No exposure, actor,
terrain or time edit was applied for screenshots.
