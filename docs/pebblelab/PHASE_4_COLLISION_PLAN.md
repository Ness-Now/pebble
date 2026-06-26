# Phase 4.16A — Collision Planning Docs-Only

## Context

PebbleLab can now capture terrain columns, classify their cells, derive
traversability, find bounded paths, and consume a positive live-derived path in
an abstract movement state machine. The current positive evidence uses
candidate index zero, seed 99 at `(8,8)`, and path
`(8,64,8) -> (9,64,8)`. Abstract movement records one step and reaches its goal
without displacing an agent or performing collision.

This is not yet physical movement evidence. The next boundary is to define how
a body with dimensions can occupy or cross real space. Phase 4.16A documents
that boundary only. It adds no Swift code, collision query, movement, physics,
or mutation.

## Traversability Versus Physical Collision

**Traversability** answers a bounded abstract question: based on captured
support, feet, and head semantics, is this node theoretically passable? It is a
classification over evidence already read from the world.

**Collision** answers a geometric and physical question: can a body with known
dimensions occupy or move through the represented space without intersecting a
blocking collision shape and while retaining acceptable support?

The distinction is contractual:

- traversability reasons about a candidate column;
- collision reasons about a body volume and a transition;
- traversability does not prove clearance at every point inside a body;
- semantic kinds such as `solid` or `air` do not encode exact collision shapes;
- a path result does not prove that its edges are physically executable;
- abstract `reachedGoal` does not prove a valid live position;
- collision must not silently become pathfinding, movement, or goal selection.

The current live movement flags remain accurate: `liveAgentDisplaced` is false,
`collisionPerformed` is false, and `mutationPerformed` is false.

## Occupable Position

An **occupable node** is a candidate node whose support and free body volume
satisfy a future collision contract. It is not merely a node classified
`.traversable`.

For a node key `(x,y,z)`:

- the **foot position** is the body anchor on the horizontal plane at `y`;
- the **support cell** is normally the cell below that plane, around `y - 1`;
- **feet clearance** covers the lower body volume beginning at `y`;
- **head clearance** covers the upper body volume through the configured body
  height;
- **support sufficiency** asks whether the shape below can bear the body;
- **volume clearance** asks whether any blocking shape intersects the body.

A future `LabHuman` should be considered occupable at a node only when all of
the following are demonstrated:

1. the relevant terrain/chunk evidence is loaded and ready;
2. the support shape is recognized and sufficient under the v0 contract;
3. the body bounding box has no blocking intersection;
4. feet and head evidence are complete rather than inferred from missing data;
5. the node is within the supported world bounds;
6. no unsupported liquid, ledge, or vertical transition is required;
7. the result is deterministic for identical evidence.

Missing, unloaded, unready, out-of-bounds, or unsupported shape evidence must
never be interpreted as air or physical permission.

## Proposed LabHuman Body V0

The first fixture contract should use a deliberately simple provisional body:

- width: `0.6` blocks;
- depth: `0.6` blocks;
- height: `1.8` blocks;
- horizontal center: `(x + 0.5, z + 0.5)`;
- vertical anchor: feet plane at `y`;
- bounding box minimum: `(x + 0.2, y, z + 0.2)`;
- bounding box maximum: `(x + 0.8, y + 1.8, z + 0.8)`.

This shape is a PebbleLab planning value, not a claim about current PebbleCore
entity dimensions. The exact inclusivity of box boundaries, floating-point
representation, contact epsilon, eye height, and crouching shape remain future
contract decisions.

`LabTerrainPathNodeKey(x:y:z:)` should represent the integer block column and
feet plane. The body is centered inside that column. The anchor must remain
stable across fixtures, live queries, snapshots, and any later displacement
adapter.

## Block Collision Shapes

Terrain semantics alone are insufficient for collision:

- `solid` may represent a full cube, slab, stair, fence, wall, door, or another
  partial shape;
- `plantLike` may be non-blocking, partially blocking, or interaction-specific;
- `liquid` may permit swimming later but cannot support walking v0;
- `other` and `unknown` provide no safe geometric conclusion;
- an `air` name does not replace loaded/ready and bounds checks.

Collision v0 should recognize only a tiny explicit shape set:

1. known air cells provide empty volume;
2. known full-cube support may provide support;
3. known full-cube collision in the body volume blocks occupancy;
4. liquids do not provide walking support and do not permit occupancy v0;
5. unknown, `other`, or unmodeled special blocks return `unknown` or `blocked`;
6. no result should approximate a special shape as a full cube merely to make
   a test pass, unless the fixture contract explicitly tests that conservative
   approximation.

Slabs, stairs, fences, walls, doors, trapdoors, ladders, vines, carpets, snow
layers, plants, water, lava, and other special blocks require explicit future
shape or policy support. Until then, conservative refusal is preferable to a
false occupable result.

## Horizontal-Only Collision V0

The first collision contract should be intentionally narrow:

- four-neighbor horizontal intents only;
- start and destination at the same `y`;
- no diagonal transition;
- no vertical transition;
- no jump;
- no fall;
- no swim;
- no climb;
- no gravity simulation;
- no velocity, acceleration, or friction;
- no complex step height;
- no ledge traversal.

The query should first prove destination occupancy for a same-y transition. A
later contract may also sample the swept volume between `from` and `to`.
Neither behavior should be inferred from the current abstract movement step.

## Reserved `blocked` Status

`LabTerrainMovementStatus.blocked` is reserved for a future denied movement
intent backed by explicit collision or occupancy evidence.

Pathfinding must not invent `blocked`: it works from traversability nodes and
returns path statuses. Abstract movement path validation must not invent it
either: malformed paths remain `invalidPath`. A future collision adapter may
produce `blocked` only after a separate query explains why the body cannot
occupy or traverse the destination.

Future reports must distinguish at least:

- **path invalid**: movement input violates the path contract;
- **path found but collision blocked**: the route exists abstractly, but the
  queried physical transition is denied;
- **movement value-state reachedGoal**: abstract stepping reached the last key;
- **physical displacement denied**: collision or synchronization prevented a
  live position update.

The reason must be explicit and must preserve the collision evidence used.

## Proposed Collision Query Architecture

The following names are conceptual and must not be implemented in Phase 4.16A:

```swift
enum LabTerrainOccupancyStatus: String, Codable {
    case occupable
    case blocked
    case unsupported
    case verticalSpaceOccupied
    case liquidUnsupported
    case unknown
    case outOfBounds
    case notLoaded
    case notReady
}

struct LabTerrainCollisionQuery {
    // Node, body shape, captured evidence, and optional movement intent.
}

struct LabTerrainCollisionResult {
    // Status, reason, samples, and deterministic audit values.
}

struct LabTerrainCollisionFixture {
    // Synthetic shapes and expected result.
}

struct LabTerrainCollisionSnapshot {
    // Live read-only query provenance and result.
}

struct LabTerrainCollisionInvariantReport {
    // Checks and summary for fixture or live evidence.
}
```

Possible query inputs:

- a synthetic fixture or a read-only world observation source;
- destination node and optional source node;
- provisional bounding box;
- support, feet, and head evidence;
- `LabTerrainMovementIntent` with `from` and `to`;
- optional explicit block samples and collision-shape descriptors;
- loaded, ready, and bounds evidence.

Possible result statuses:

- `occupable`;
- `blocked`;
- `unsupported`;
- `verticalSpaceOccupied`;
- `liquidUnsupported`;
- `unknown`;
- `outOfBounds`;
- `notLoaded`;
- `notReady`.

Every result should include a stable reason, preserve the evidence order, and
state whether it came from fixtures or live read-only samples. A query should
not accept an agent decision, mutate movement state, choose a goal, run
pathfinding, or displace any entity.

## Future Source Layout

A probable future split is:

- `Sources/PebbleLab/LabTerrainCollision.swift` for pure types and occupancy
  evaluation;
- `Sources/PebbleLab/LabTerrainCollisionFixtures.swift` for synthetic fixture
  definitions and fixture reports;
- `Sources/PebbleLab/LabTerrainCollisionLive.swift` for bounded read-only world
  sampling and live snapshots.

Phase 4.16A creates none of these Swift files. The split should be revisited
after fixture requirements expose the smallest useful ownership boundaries.

## Recommended Future Phases

### Phase 4.16B — Collision Fixture Smoke

- fixture-only;
- no `World`, chunk, agent, or movement runtime;
- no pathfinding or mutation;
- synthetic full-cube, empty, unsupported, occupied, liquid, unknown, and
  bounds cases;
- deterministic body/shape intersection and occupancy results;
- dedicated report, invariants, metrics, and event.

### Phase 4.16C — Collision Live Read-Only Smoke

- bounded live sampling of one candidate node;
- asks whether the node is occupable;
- preserves loaded/ready and support/feet/head evidence;
- no movement state transition;
- no agent, placeholder, or core entity displacement;
- no world mutation.

### Phase 4.17A — Physical Movement Integration Planning Docs-Only

- plans how an approved collision result may gate one displacement;
- defines synchronization, rollback, observation, and failure contracts;
- remains docs-only.

### Phase 4.17B — Live Agent Displacement Smoke

- first real single-step displacement;
- only after fixture and live collision contracts pass;
- one agent and one explicitly approved horizontal transition;
- no gameplay route following or multi-agent movement.

## Future Outputs And Invariants

Phase 4.16B and 4.16C should use separate auditable outputs:

- `terrain_collision_fixture_report.json`;
- `terrain_collision_invariant_report.json`;
- `terrain_collision_live_snapshot.json`;
- `metrics.json`;
- `events.ndjson`.

Possible fixture metrics include case/pass/fail counts and counts by occupancy
status. Possible live metrics include samples, loaded/ready cells, occupancy
status, blocked count, and success. Aggregate events should be distinct for
fixture and live evidence; no per-sample event is needed initially.

Minimum future invariants:

1. no movement is performed;
2. no agent is displaced;
3. no physical placeholder is displaced;
4. no core entity is displaced;
5. no world mutation occurs;
6. no pathfinding is invoked;
7. no route following occurs;
8. occupancy is deterministic for identical evidence;
9. support, feet, and head evidence is preserved;
10. every blocked result has an explicit reason;
11. fixture and live results remain separated;
12. collision does not select goals;
13. collision does not mutate `LabAgent`;
14. missing or unsupported evidence never becomes `occupable`;
15. loaded/ready guards precede live block reads;
16. body dimensions and node anchor match the declared contract;
17. query inputs and sampled outputs retain deterministic order;
18. collision status alone never triggers displacement.

## Explicitly Out Of Scope

- real agent displacement;
- physical placeholder displacement;
- core entity displacement;
- gameplay route following;
- multi-agent movement;
- avoidance or reservation tables;
- jumping, falling, swimming, or climbing;
- gravity, velocity, acceleration, or friction;
- complex step height and ledge handling;
- diagonal or vertical movement;
- block mutation;
- mining or construction;
- inventory behavior;
- Python, LLM, ML, or RL integration;
- pathfinding changes;
- movement state-machine changes;
- renderer, shader, resource, registry, save/load, or golden changes.

## Risks And Mitigations

| Risk | Consequence | Mitigation |
| --- | --- | --- |
| Collision is confused with traversability | A semantic column result is treated as physical proof | Require a separate body-and-shape query and distinct status/reason output. |
| Movement grows into a physics engine | The adapter accumulates gravity, velocity, and shape logic | Keep collision pure and movement unchanged; plan physics separately. |
| Real displacement is added too early | Live state changes without validated occupancy | Fixture and live read-only collision phases must pass before displacement planning. |
| An abstract node is treated as guaranteed physical space | `found` or `reachedGoal` becomes unsafe authority | State in every snapshot that path and movement evidence are abstract until collision approves occupancy. |
| Slabs, stairs, fences, doors, or liquids are misclassified | Partial shapes produce false-positive occupancy | Restrict v0 to explicit full-cube/empty cases and return conservative unknown/blocked otherwise. |
| Hidden mutation enters live sampling | A read-only query changes chunks or entities | Audit chunk state before/after and assert all displacement/mutation flags false. |
| Hidden pathfinding enters collision | Collision begins choosing routes or alternate nodes | Accept one supplied node/intent only and assert no pathfinding invocation. |
| `blocked` is emitted without evidence | Movement failure becomes ambiguous | Require a collision status, stable reason, and preserved samples for every blocked result. |
| Future collision is not testable | Live-only behavior becomes fragile and opaque | Begin with pure fixtures, deterministic shapes, explicit inputs, and JSON reports. |

## Future Success Contracts

Phase 4.16B should be complete only when synthetic occupancy fixtures cover the
conservative v0 shape contract with no world, movement, collision side effects,
or mutation. Phase 4.16C should be complete only when a bounded live query
preserves loaded/ready evidence, leaves all states unchanged, and produces a
deterministic occupancy result.

Neither phase may claim physical movement. Phase 4.17 planning begins only
after fixture and live read-only collision evidence are independently green.

## Phase 4.16B Implementation Status

Phase 4.16B implements the fixture-only collision smoke described here. It adds
pure synthetic occupancy evaluation for support/feet/head shape evidence and a
`LabHumanV0` body contract with a `0.6 x 0.6 x 1.8` body box anchored at the
feet plane and centered in the node column.

The implemented scenario is `terrain_collision_fixture_smoke`. It writes
`terrain_collision_fixture_report.json`,
`terrain_collision_invariant_report.json`, `metrics.json`, and `events.ndjson`.
The fixture report covers all v0 occupancy statuses: `occupable`, `blocked`,
`unsupported`, `verticalSpaceOccupied`, `liquidUnsupported`, `unknown`,
`outOfBounds`, `notLoaded`, and `notReady`.

This remains a pure fixture layer. It performs no live query, no `World` access,
no chunk access, no agent displacement, no movement runtime, no pathfinding, no
route following, no physics integration, and no mutation. Phase 4.16C remains
the recommended next step for bounded live read-only occupancy sampling.

## Phase 4.16C Implementation Status

Phase 4.16C implements the first bounded live read-only collision occupancy
smoke. The scenario is `terrain_collision_live_readonly_smoke`.

The smoke reads exactly one deterministic node, `(8,64,8)`, after preparing the
normal live world chunks for seed 42. It samples:

- support at `(8,63,8)`;
- feet at `(8,64,8)`;
- head at `(8,65,8)`.

Each sample preserves loaded/ready state, block identity, semantic kind,
collision shape, and chunk-state unchanged evidence. The live adapter then
builds a `LabTerrainCollisionColumnFixture` with source
`live_readonly_fixture_adapter` and calls the same
`evaluateTerrainOccupancyFixture(...)` v0 evaluator used by Phase 4.16B.

For the validated seed 42 run, support is water and feet/head are air, so the
occupancy result is `liquidUnsupported` with reason `liquid_support`. This is a
successful non-occupable result: the phase validates bounded read-only evidence
and explicit collision classification, not movement.

The scenario writes `terrain_collision_live_snapshot.json`,
`terrain_collision_live_invariant_report.json`, `metrics.json`, and
`events.ndjson`. It still performs no agent displacement, no physical
placeholder displacement, no core entity displacement, no movement runtime, no
pathfinding, no route following, no physics integration, and no mutation.

## Recommended Validation Commands

```text
cd ~/Dev/pebble-lab
git checkout lab/pebblelab-v1
swift build
swift run -c release PebbleLab -- --scenario terrain_path_live_movement_smoke --seed 42 --ticks 5 --out runs/check_live_movement_before_collision
swift run -c release PebbleLab -- --scenario terrain_path_movement_fixture_smoke --seed 42 --ticks 0 --out runs/check_movement_fixture_before_collision
swift run -c release PebbleLab -- --scenario terrain_pathfinding_column_positive_smoke --seed 42 --ticks 5 --out runs/check_positive_path_before_collision
swift run -c release pebsmoke
git status
```

## Recommendation

Proceed with Phase 4.16B as a fixture-only occupancy contract. Start with the
provisional body and explicit full-cube/empty synthetic shapes. Keep collision
read-only and separate from both movement state and any live entity until the
fixture report can explain every result deterministically.
