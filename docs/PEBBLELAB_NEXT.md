# PebbleLab Next Steps

PebbleLab should keep moving in small, reviewable patches. The priority is to preserve the original Pebble game while growing a deterministic headless laboratory around PebbleCore.

## Immediate

### Stabilize Agent Observation

`agent_smoke` now has a first local observation path. Keep it simple and deterministic:

- verify spawn placement stays outside solid cells;
- keep observing current position, chunk readiness, `surfaceY`, `height`, and raw block values;
- avoid semantic block interpretation until there is a clear need;
- keep the agent immobile for now.

### Stabilize Abstract Actions

`agent_smoke` now has a first deterministic abstract action decision. Keep the
next step equally small:

- verify action events and metrics stay stable;
- consider one action with a small internal effect;
- avoid physical movement until the action contract is clearer.

This should remain PebbleLab-only. Do not create a PebbleCore entity, mob, pathfinder, or AI planner for this step.

## Short Term

### Improve Metrics

Useful additions:

- spawn clearance metrics;
- final observation summary;
- per-scenario success criteria;
- clearer error metrics for invalid or incomplete runs.

### Keep World Snapshots Useful

`world_snapshot.json` should remain stable and easy to inspect. Future work can add more terrain details only when needed by scenarios or agents.

## Medium Term

### Stabilize Agent Loop

`agent_smoke` now has observation, abstract actions, local memory, and internal
action effects. Keep the next work focused:

- verify `recentMemory` stays compact and deterministic;
- verify internal effects stay deterministic and do not touch the world;
- keep memory local to one agent until interaction scenarios exist.

Possible next patches:

- refine action effect metrics;
- add explicit interaction events only after single-agent memory stays stable.

### Stabilize Passive Multi-Agent Runs

`agent_smoke` now supports two passive abstract agents. Next work should keep
that multi-agent state understandable:

- verify aggregated metrics remain useful;
- avoid communication or relationship state until event formats are stable;
- consider one explicit non-social interaction event only after passive runs
  are boring and predictable.

### Agent-Agent Interaction

Only after one agent can observe and act, add controlled multi-agent scenarios:

- two abstract agents in one generated area;
- explicit interaction events;
- no social complexity at first;
- no physical PebbleCore entities yet.

## Long Term Social Agents

PebbleLab should eventually support social multi-agent simulations, but this is not implemented yet.

Future agents may be able to:

- communicate;
- send public messages;
- send private messages;
- ask for help;
- propose exchanges;
- share information;
- hide or falsify information if the simulation later chooses to model that;
- remember interactions;
- build trust or distrust;
- become friends;
- form groups;
- cooperate;
- betray;
- build reputations.

This direction should influence future design, but it should not be coded too early. The safer sequence is:

1. agent exists;
2. agent observes;
3. agent performs simple abstract actions;
4. agent remembers;
5. agents interact;
6. agents communicate socially.

## Still Avoid

- modifying PebbleCore unless a public API is clearly missing;
- creating registered entities for early lab agents;
- pathfinding before the action model is clearer;
- Python or training loops before logs and scenarios stabilize;
- RL, LLM planning, or neural models in the early PebbleLab runtime;
- touching registries, goldens, rendering, audio, resource packs, or packaging without explicit instruction.
