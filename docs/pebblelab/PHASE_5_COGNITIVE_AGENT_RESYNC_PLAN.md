# Phase 5 — Cognitive Agent Resync Plan

## Purpose

Return PebbleLab from movement-stack infrastructure work toward AI agents and
society simulation. Phase 4.28 closed the abstract movement/intention/feedback/
planning/arbitration/replay stack. Phase 5 should use that stack as a bounded
sub-layer while resynchronizing ownership of perception, memory, needs, mood,
goals, inventory meaning, behavior loops, and later social simulation.

This plan is documentation-only. It does not add Swift runtime behavior,
scenarios, metrics, events, World reads, World mutation, route following,
Python, LLM, or RL.

## Current confirmed foundation

PebbleLab already has:

- a headless executable target;
- deterministic runner options, scenario selection, seeded execution, and output
  directories;
- JSON reports, metrics, events, digests, and invariant reports;
- abstract agents with earlier history around nearby social perception, goals,
  health/fear/home state, inventory, and abstract movement;
- physical placeholder and unregistered Core entity probe history, kept
  carefully bounded and non-persistent;
- read-only terrain/world observation history;
- a consolidated movement stack covering intent production, feedback
  consumption, feedback-aware policy, alternate local hints, multi-tick closed
  loop, movement policy consolidation, bounded planning, first-step handoff,
  tick arbitration, approved lab-map-only application, replay regression,
  boundary hardening, and metrics/events compatibility;
- policy versions v0, v1, v2, and v3 as explicit opt-in modes;
- v4 reserved-only;
- Phase 4.28F consolidated replay proving the current stack evidence remains
  deterministic and boundary-clean.

## Important distinction

The movement stack is not a cognitive agent.

Movement intent, policy choice, prior feedback consumption, first-step planning,
tick arbitration, and replay proof are not memory, mood, social behavior, needs
management, long-term goal ownership, communication, or gameplay autonomy.

A route or first-step proof is not gameplay behavior. The current stack proves
that bounded abstract movement decisions can be proposed, arbitrated, applied
to lab maps where approved, audited, and replayed deterministically. It does
not prove that agents understand why they move, remember consequences, pursue
owned goals, coordinate socially, manipulate inventory meaningfully, mine,
build, or participate in a society.

## Cognitive loop target

The target behavior loop for future phases is:

```text
perception
-> memory
-> needs
-> mood
-> goal
-> intent
-> movement stack
-> action result
-> feedback
-> memory update
```

Ownership should remain explicit:

- perception captures bounded observations and social evidence;
- memory stores durable, deterministic agent-local facts or episodes;
- needs track internal pressures without selecting movement directly;
- mood summarizes short-term affective state from needs, memory, and feedback;
- goal selection chooses one bounded objective from agent state;
- intent turns the current goal into a proposed action;
- movement stack arbitrates only movement-relevant intent and feedback;
- action result records what happened;
- feedback reports approval, denial, movement, blockage, or other result;
- memory update decides what the agent learns from the result.

## Immediate audit questions

Before coding more behavior, Phase 5.0A should audit:

- current `LabAgent` fields and which are cognitive state versus movement or
  report state;
- current `LabGoal` fields and whether they represent durable ownership,
  per-tick selection, or scenario fixture data;
- current `LabMemoryEntry` fields and whether memory has clear write/read
  ownership;
- current needs, including health, fear, home, hunger-like future needs, and
  whether each is implemented or only implied;
- inventory status, including whether `LabInventory` is state, gameplay, report
  evidence, or future capability;
- social perception status, especially nearby-agent observations versus actual
  social behavior;
- movement stack entry points that a future behavior loop may call without
  taking over arbitration or application;
- reports needed to distinguish cognitive state changes from movement-stack
  outputs;
- scenarios to preserve as non-regression coverage before adding behavior-loop
  fixtures.

## Recommended next implementation phases

- Phase 5.0B - Cognitive Agent State Audit Smoke or Docs;
- Phase 5.1 - Behavior Loop Contract Fixture;
- Phase 5.2 - Memory Update From Movement Feedback Fixture;
- Phase 5.3 - Goal To Movement Intent Bridge Fixture;
- Phase 5.4 - agents_basic_behavior_loop_smoke;
- Phase 5.5 - Multi-Agent Social Perception Behavior Smoke.

Phase 5.0B may remain docs-only if the audit shows current types need a clear
contract before code. If it becomes a smoke, it should be fixture-first and
report-only, with no new movement runtime, no World mutation, and no route
following.

## Safe integration boundaries

The movement stack may be used as a sub-layer only after a cognitive loop owns
why an agent wants to move. The stack should continue to own movement
arbitration evidence, first-step-only handoff, feedback timing, lab-map-only
approved application, and replay invariants.

The cognitive loop should not read live World or collision through movement
policy. It should consume bounded perception results through explicit inputs.
It should not treat planner advisory steps as commitments, future route state,
or behavior memory unless a later docs-only phase creates that contract.

Memory and goal updates should be deterministic, agent-local unless explicitly
shared, and reportable. Feedback from movement can inform memory, needs, or
mood only through a future explicit bridge fixture.

## Next scenarios

The next concrete scenario after planning should be small and contract-shaped.
Good candidates:

- a fixture-only cognitive state audit report;
- a behavior-loop contract fixture with synthetic perception and feedback;
- a memory-update-from-feedback fixture that records one bounded memory entry;
- a goal-to-movement-intent bridge fixture that proves ownership boundaries
  without route following.

Avoid starting with a live World scenario, social group dynamics, construction,
mining, inventory gameplay, or Python/LLM/RL integration.

## Out of scope

- World mutation;
- construction;
- mining;
- Python;
- LLM;
- RL;
- complex society;
- uncontrolled route following;
- unbounded pathfinding;
- dynamic replanning;
- reservation runtime;
- save/load changes;
- renderer changes;
- resource changes;
- registry changes;
- goldens changes;
- physical Core entity movement;
- physical placeholder movement;
- communication runtime;
- social behavior runtime beyond planned bounded fixtures.

## Definition of done for Phase 5.0A

- Docs updated;
- roadmap resynced;
- Phase 4.28 closure recorded;
- Phase 5 cognitive direction recorded;
- no Swift runtime changes;
- no new scenario;
- no runtime metrics or events;
- no tests required beyond build/docs sanity;
- next prompt can start from Phase 5.0B.

## Phase 5.0A Status

Phase 5.0A is implemented as
`PHASE_5_0A_COGNITIVE_AGENT_STATE_AUDIT.md`.

The audit confirms that PebbleLab already has a minimal abstract-agent
cognitive loop with needs, goal selection, action choice, action effects,
memory entries, nearby-agent perception, inventory state, home/safety/fear
state, abstract movement, and reporting. It also confirms that this loop is
not yet a full behavior architecture: mood, emotional memory, relationship
modeling, social trust, communication, task boards, community state, long-term
planning, learning, Python, LLM, and RL remain out of scope.

The recommended next phase has been resynced to Phase 5.1A - Behavior Loop
Contract Planning.
