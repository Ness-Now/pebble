# PebbleLab Journal

## 2026-06-17 - Phase 3.1 Nearby Agents Social Perception V0

Branch: `lab/pebblelab-v1`

Objective: add minimal abstract social perception so each `agent_smoke` agent
can detect other nearby abstract agents without interaction or communication.

Files modified:

- `Sources/PebbleLab/LabAgent.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DECISIONS.md`
- `docs/pebblelab/JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

Behavior added:

- `LabNearbyAgentObservation` records nearby agent id, relative offset, and
  Manhattan distance.
- Each `LabAgent` now stores `nearbyAgents`.
- `agent_smoke` agents detect one another at the current distance of 4 blocks.
- `agent_snapshot.json` includes `nearbyAgents`.
- `events.ndjson` includes `agent_observed_nearby_agent`.
- `metrics.json` includes `nearbyAgentObservations` and
  `agentsWithNearbyAgents`.

Commands of validation:

- `swift build`
- `swift run -c release pebsmoke`
- `swift run -c release PebbleLab -- --scenario agent_smoke --seed 42 --ticks 3 --out runs/agent_smoke_nearby_v0`

Result: validation passed. `agent_0` observes `agent_1`, `agent_1` observes
`agent_0`, both observations report Manhattan distance `4`, and the smoke
suite remains green.

Next steps:

- Phase 3.2: `LabGoal/currentGoal v0`.

## 2026-06-17 - Phase 3.2 LabGoal CurrentGoal V0

Branch: `lab/pebblelab-v1`

Objective: add a minimal deterministic goal layer so abstract agents choose a
`currentGoal` after observations and before action selection.

Files modified:

- `Sources/PebbleLab/LabAgent.swift`
- `Sources/PebbleLab/LabEvents.swift`
- `Sources/PebbleLab/LabOutput.swift`
- `Sources/PebbleLab/main.swift`
- `docs/pebblelab/CHANGELOG.md`
- `docs/pebblelab/DECISIONS.md`
- `docs/pebblelab/JOURNAL.md`
- `docs/pebblelab/ROADMAP.md`

Behavior added:

- `LabGoalKind` and `LabGoal` model deterministic agent goals.
- Each `LabAgent` now stores a non-optional `currentGoal`.
- Goal selection runs after local/social observation and before action choice.
- `agent_smoke` agents choose `observeOtherAgent` when nearby agents are
  detected.
- `agent_snapshot.json` includes `currentGoal`.
- `events.ndjson` includes `agent_goal_changed`.
- `metrics.json` includes `agentGoalSelections`, `agentGoalChanges`, and
  `goalsByKind`.

Commands of validation:

- `swift build`
- `swift run -c release PebbleLab -- --scenario agent_smoke --seed 42 --ticks 3 --out runs/agent_smoke_goal_v0`
- `swift run -c release pebsmoke`

Result: validation passed. Both `agent_smoke` agents select
`observeOtherAgent` after nearby-agent perception, `agent_goal_changed` events
are emitted, metrics include goal selections/changes, and the smoke suite
remains green.

Next steps:

- Phase 3.3: `health/fear/homePosition v0`.
