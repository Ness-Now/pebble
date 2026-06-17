# PebbleLab Next Steps

These are recommended next steps, in a conservative order.

## 1. Improve `chunk_smoke`

Find a safe public way to create, load, or generate a small chunk area without
touching rendering, audio, registries, or goldens.

Definition of Done:

- `chunk_smoke` reports meaningful chunk metrics.
- The scenario remains deterministic.
- `empty` remains unchanged.

## 2. Clarify Scenario Structure

Keep `LabScenarios.swift` small for now. If scenarios grow, introduce a light
scenario protocol or table only when duplication becomes real.

Avoid:

- a heavy `LabRunner`
- a heavy `LabWorldBuilder`
- scenario abstractions before there are multiple real scenarios

## 3. Add More Useful Metrics

Possible metrics:

- chunks loaded or touched
- world time
- blocks changed
- entities observed
- scenario-specific success checks

Metrics should stay JSON-serializable and deterministic.

## 4. Add Better Event Coverage

Possible event additions:

- scenario checkpoints
- chunk probes
- block observations
- entity observations once agents/entities are introduced

Keep NDJSON one object per line.

## 5. Expand Abstract Agent Behavior

The first abstract agent exists in `agent_smoke`. Next steps should keep it
small and deterministic.

Possible additions:

- richer needs
- a single abstract action such as observe or wait
- action events
- simple terrain observation from `world_snapshot.json`

Avoid RL, Python, LLM planning, or new registered PebbleCore entities.

## 6. Delay Python Integration

Python should start as read-only analysis of `runs/` artifacts. Training,
models, and active control should wait until the Swift runner is stable.

## 7. Avoid PebbleCore Changes Where Possible

Prefer PebbleLab-side code until a clear missing public API is identified.

If PebbleCore must change:

- keep the patch small
- preserve determinism
- run `swift build`
- run `swift run -c release pebsmoke` for core simulation changes
- do not touch registries or goldens without explicit approval
