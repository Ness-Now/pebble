# Phase 4 Physical Placeholder Sync

Date: 2026-06-18

Branch: `lab/pebblelab-v1`

Purpose: define the Phase 4.2A contract for synchronizing PebbleLab-only
physical placeholders with abstract `LabAgent` movement.

## Scope

Phase 4.2A keeps the physical representation non-invasive:

- no PebbleCore entity is created;
- no entity registry is modified;
- no existing mob is changed;
- no renderer, audio, resource pack, packaging, or golden file is touched;
- no pathfinding, collision, gravity, save/load, combat, item stack, crafting,
  or construction logic is introduced.

The physical placeholder remains a PebbleLab-side handle used to prove bridge
identity, tick accounting, position synchronization, metrics, and snapshots.

## Sync Contract

`LabAgentPhysicalBridge` owns `LabPhysicalAgentHandle` values. Each handle maps
one abstract `LabAgent.id` to one stable `physicalId`, such as
`agent_0 -> physical_agent_0`.

After abstract agent movement for a tick, the bridge:

1. finds the matching `LabAgent`;
2. compares physical and abstract positions;
3. updates the physical position only when they differ;
4. records a `LabPhysicalAgentSync` with before/after positions and Manhattan
   distance;
5. leaves already synchronized handles untouched.

The recommended tick order is:

1. `world.tick()`
2. abstract agent needs, observation, goals, actions, effects, and movement
3. `physicalBridge.tick()`
4. `physicalBridge.sync(with:tick:)`

Sync happens after abstract movement so the placeholder does not trail the
agent by one tick.

## Outputs

`physical_sync_smoke` writes the same run files as other PebbleLab scenarios,
plus `physical_snapshot.json`.

The physical snapshot records:

- abstract position;
- physical placeholder position;
- final divergence;
- placeholder tick count.

`events.ndjson` includes `lab_physical_agent_synced` only when a real correction
is applied.

`metrics.json` includes:

- `physicalAgentsSynced`;
- `physicalSyncEvents`;
- `physicalSyncDistance`;
- `abstractPhysicalDivergence`;
- `maxAbstractPhysicalDivergence`.

For a healthy sync run, final divergence should be zero.

## Validation

The Phase 4.2A validation run is:

```sh
cd ~/Dev/pebble-lab
swift run -c release PebbleLab -- --scenario physical_sync_smoke --seed 42 --ticks 5 --out runs/check_physical_sync
```

Expected result:

- `success = true`;
- at least one `lab_physical_agent_synced` event;
- `physicalSyncEvents > 0`;
- `abstractPhysicalDivergence = 0`;
- `maxAbstractPhysicalDivergence = 0`.

The full validation also runs existing Phase 3 scenarios,
`physical_placeholder_smoke`, `regression_smoke`, and `pebsmoke`.

## Next Step

Phase 4.2B should be a registry-safe real PebbleCore entity feasibility patch or
an additional planning step before any entity registration occurs.
