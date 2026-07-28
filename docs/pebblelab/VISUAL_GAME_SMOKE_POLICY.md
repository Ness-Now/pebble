# Pebble Civilization — Visual Game Smoke Policy V5

## Canonical invocation

Future missions may invoke this policy with:

> Apply the canonical Visual Game Smoke Policy proportionally to the risks of
> this mission.

That sentence incorporates this document. It does not require every item below
for every change; the mission selects the levels that address its actual risk.

## Purpose

Deterministic tests and controlled live fixtures cannot reveal every defect in
a spatial game. V5 adds explicit normal-world, temporal and rendered-world
inspection where physical or visible behavior can diverge from the tested
contract.

The policy was strengthened after a post-Gate-B bootstrap defect: a prepared
World could pass while fixed player-relative offsets placed agents unsafely in
normal terrain. That defect is now hardened in the published product baseline,
but its lesson is permanent:

```text
controlled boundary proof
!= arbitrary-world robustness
```

## Four evidence levels

### 1. Deterministic/headless

Use focused suites, `pebsmoke`, property checks, deterministic digests,
checkpoint/replay, conservation, bounds and fault injection to prove logical
contracts.

Question answered: is the authoritative logic deterministic and correct?

### 2. Automated live proof

Use the real Pebble executable, a disposable World, real entities and mechanics,
explicit gates, traces and verified cleanup.

Question answered: does the change traverse the real live boundary?

### 3. Adversarial playability QA

Vary relevant seeds, starting positions, natural geometry, obstacles and time.
Use the normal product path, preserve unprepared terrain and retain assertions
or telemetry that can expose defects not already encoded by the nominal
fixture.

Question answered: does the feature remain coherent outside its prepared proof
World?

### 4. Visual Game Smoke

Launch Pebble, render a real World, observe the actual phenomenon, inspect a
representative capture, and verify behavior and cleanup.

Question answered: is the implemented result visibly and physically credible?

No level substitutes for another. A screenshot does not prove conservation or
replay, and headless tests do not prove rendered-world sanity.

## Proportional selection

| Risk | Expected policy use |
| --- | --- |
| Docs, manifest, pure contracts | Structured-data/link/diff checks; no live or visual work by default. |
| Pure deterministic state, codec or read-only non-visual projection | Focused deterministic evidence; broader gate according to runtime risk. |
| Default-off adapter touching a live boundary | Automated live proof when the boundary changes; adversarial/visual only for meaningful spatial or visible risk. |
| World mutation, persistence reconciliation, navigation, physical economy or visible UI | Deterministic + live; adversarial and visual normally required. |
| Player command or behavior usable in a normal arbitrary World | Controlled proof + adversarial normal worlds + temporal observation + rendered-world inspection. |

Typical triggers include spawn, embodiment, movement, collision, pathfinding,
harvest, construction, inventory/containers, agriculture, animals, combat,
markets, infrastructure, restart reconciliation, God mode, incarnation and UI
that represents authoritative state.

Do not open Pebble or run a multi-seed campaign for documentation or a harmless
micro-edit merely as ceremony.

## Controlled and normal Worlds

Every applicable report distinguishes:

### Controlled proof World

- fixed seed and known terrain;
- explicit fixtures and resources;
- designed to isolate one boundary.

### Normal/adversarial World

- natural, unflattened terrain;
- varied relevant player positions or environments;
- no hidden cleanup that removes the difficulty being tested;
- same product entry path a player uses.

A controlled fixture can seed actors or resources when disclosed. It cannot
directly place the claimed final result or be presented as arbitrary-world
proof.

## Adversarial contract

When required, choose a small but justified matrix that can expose the actual
failure modes. Depending on the feature, consider:

- plains, forest, slope, cliff, water, island, cave or structure;
- obstructions, unavailable chunks or changed terrain;
- multiple starts and fixed seeds;
- long enough observation to see retries, cooldowns and cleanup;
- success, honest refusal and late failure/rollback.

Keep per-agent or per-actor evidence sufficient to explain:

- initial and successive physical positions;
- requested, moved and blocked outcomes;
- decisions, activities and candidates;
- cooldowns and refusal reasons;
- physical/cognitive agreement;
- completion, quiescence or failure;
- cleanup and residual entities.

Thresholds and budgets must be bounded, deterministic and justified. Legitimate
waiting is not failure when it is explained by no executable action, an active
bounded cooldown, a higher-priority need, temporary World unavailability or
honest quiescence.

## Permanent safe creation contract

Before a Civilization-controlled actor becomes active in a normal World, its
creation boundary must establish, as applicable:

- available chunk/World data;
- compatible support;
- free body volume;
- no incompatible liquid;
- no significant initial collision;
- no immediately dangerous fall;
- adequate separation from player and other actors;
- exact agreement between published cognitive and physical positions.

The search or equivalent resolution is bounded and deterministic. If enough
valid positions are unavailable, creation refuses explicitly and atomically.
No partial session, orphan entity or hidden terrain modification may survive.

Normal-world bootstrap must not flatten terrain, fill hazards, remove
structures or teleport after publication to mask invalid creation.

## Temporal behavior

A single frame cannot disprove:

- short movement loops or oscillation;
- persistent blocked motion;
- target churn;
- repeated activity abandonment;
- unjustified inactivity;
- an eligible executable activity that is never selected;
- delayed entity loss or cleanup failure.

Observe for a duration justified by the behavior and retain temporal telemetry.
Treat repeated A→B→A movement, persistent short loops, cognition/World drift,
retry storms and unexplained active-without-progress states as failures when
they cross the mission’s explicit threshold.

## Visual Game Smoke execution

When selected:

1. run the applicable live dry-run;
2. launch the real Pebble client;
3. use a disposable World and only required gates;
4. traverse the product boundary rather than a screenshot-only setup;
5. bring the client forward when the environment safely permits;
6. observe the relevant behavior over time;
7. produce and inspect at least one representative rendered-world capture;
8. compare visible state with trace, World and `AgentSimulationSession`;
9. stop and verify process, probe, entity and World cleanup.

Inspect what matters to the feature, such as:

- actor placement, support, separation and collision;
- movement, facing, route credibility and visible teleportation;
- ghost blocks, items or entities;
- physical result before/after a mutation;
- overlay or UI agreement with authoritative state;
- behavior after restart or fidelity transition.

A menu, console, loading screen or overlay without the tested phenomenon is not
visual evidence.

If the environment cannot inspect a capture, report:

```text
Representative screenshot inspected: NO
```

Do not claim completed Visual Game Smoke.

## Harness validity and cleanup

The verdict belongs to the complete command:

```text
visible behavior occurred
+ harness later failed
= validation failed
```

Missing captures, lost traces, non-zero final status, unverified rollback,
residual process/entity/probe or incomplete cleanup are failures unless the
mission explicitly classifies and resolves an infrastructure issue before
claiming product evidence.

After a discovered bug:

```text
fix
-> rerun affected focused evidence
-> rerun applicable live/adversarial scenarios
-> rerun broader gate if required
-> repeat visual inspection
-> make no unvalidated code change afterward
```

## Minimum reporting

For applicable work, report:

```text
Controlled proof scenario executed: YES/NO
Normal-world adversarial scenarios executed: YES/NO
Scenario matrix: <seeds, starts, environments>
Temporal telemetry inspected: YES/NO
Harness final exit status: <status>
Behavioral anomaly found: YES/NO

Pebble process launched: YES/NO
Real rendered World observed or captured: YES/NO
Representative screenshot inspected: YES/NO
Visual anomaly found: YES/NO
Screenshot paths: <paths>
Cleanup verified: YES/NO
```

If an anomaly is found, include reproduction, impact, cause or hypothesis,
correction/blocker and validations rerun.

## Non-claims

An adversarial campaign cannot prove absence of every bug. Visual inspection
cannot prove atomicity, conservation, causality or determinism. Together with
deterministic and live evidence, they demonstrate that plausible arbitrary-
world, temporal and visible failure modes were actively searched rather than
assumed away.

## Permanent principle

A simulation feature is not ready merely because its data is correct in a
prepared scenario. Physical and visible systems must remain coherent when the
real product path runs in a representative World and is watched over time.
