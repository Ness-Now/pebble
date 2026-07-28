# PebbleLab development workflow

## Canonical inputs

Begin at [`CODEX_START_HERE.md`](../../CODEX_START_HERE.md). Verify Git, then
read `CURRENT_STATE.md`, the root and applicable local `AGENTS.md`, and only the
canonical or operational documents relevant to the mission.

Authority is scoped:

```text
published code, tests and Git HEAD
= implemented reality

AGENTS.md and applicable workflows
= mandatory working rules

vision
= durable product target

roadmap and manifest
= canonical program and status

gate reports and evidence
= verifiable history

old plans and handoffs
= non-directive historical context
```

## Mission contract

A mission defines:

- exact Git baseline and cleanliness requirements;
- product or documentation outcome;
- why the outcome belongs now;
- non-negotiable invariants;
- explicit non-goals;
- evidence proportional to risk;
- local Git and reporting expectations.

The mission should not prescribe structures, files or commit count without a
concrete reason. Codex audits the repository and chooses the smallest coherent
implementation. Use
[`METHOD_CODEX_AUTONOMIE_GUIDEE.md`](METHOD_CODEX_AUTONOMIE_GUIDEE.md) when
designing or reviewing a mission.

Not every change is a `CIV-XX` phase. Corrections, gate evidence, tooling and
documentation canonization use descriptive non-CIV identifiers and must not
silently start a product phase.

## Preflight

Before any edit:

1. verify repository path;
2. fetch the relevant remote refs;
3. compare the requested remote branch to the exact expected SHA;
4. verify current branch, HEAD and `git status --short`;
5. create or switch to a dedicated clean local branch when requested;
6. read all applicable instructions.

Stop without editing if a task requires an exact remote baseline and the remote
has moved.

## Reuse-First audit

Every physical vertical begins by locating the existing owner:

```text
physical need
-> inspect PebbleCore and Pebble
-> reuse existing behavior
-> otherwise adapt or extract the smallest actor-neutral primitive
```

Civilization owns intent, identity, reasons, social state and coarse
waypoints. Pebble/PebbleCore own live World observation, detailed pathfinding,
collision, movement, items, entities and physical outcomes. Publish to
`AgentSimulationSession` only after verification.

## Delivery cycle

1. Audit the real call path and current tests.
2. Define the behavioral contract and ownership boundary.
3. Implement one coherent vertical or documentation outcome.
4. Run focused positive, negative and failure-path evidence.
5. Run broader validation once when justified by risk.
6. Inspect the diff for unrelated or generated changes.
7. Create coherent local commits.
8. Report facts, limitations and final Git state.
9. User reviews and pushes manually.
10. Published SHA is verified remotely before phase or gate status advances.

Local evidence is not remote publication. A local green result never acquires a
gate by itself.

## Proportional validation

### Risk A — documentation and contracts

When no executable, configuration, generated baseline or runtime behavior
changes:

- parse JSON and other structured files;
- check local Markdown links and named paths;
- search canonical documents for status contradictions;
- run existing documentation validators if present;
- run `git diff --check`.

Do not run Swift builds, live campaigns or the full product gate merely as
ceremony.

### Risk B — deterministic runtime or default-off adapters

Run focused tests for the changed contract and
`scripts/verify-pebblelab.sh` at the end. Add live dry-run or live proof only
when a live boundary is affected.

### Risk C — World mutation, persistence, physical systems or scale

Require bounded prevalidation, mutation, verification, publication and
verified rollback. Run focused fault injection, the repository gate, applicable
live proof, and the risk-selected parts of the canonical Visual Game Smoke
Policy.

### Risk D — normal player/World integration

Use controlled proof, adversarial normal-world variation, temporal observation
and representative rendered-world inspection. Never present a prepared fixture
as proof of arbitrary-world robustness.

Apply the canonical Visual Game Smoke Policy proportionally to the risks of
this mission.

## Canonical commands

Headless repository gate:

```bash
scripts/verify-pebblelab.sh
```

Live planning and launcher:

```bash
scripts/verify-pebblelab-live.sh --dry-run
scripts/verify-pebblelab-live.sh <applicable-mode>
```

Follow [`../pebblelab-3d-live-prototype.md`](../pebblelab-3d-live-prototype.md)
for disposable-world rules and evidence handling.

## Reporting

Every final report includes:

- initial and final branch/HEAD/status;
- changed documents or code surfaces and why;
- commits created;
- every validation command with exit status and exact result;
- remaining limits or debt;
- whether any live or visual claim was actually inspected;
- `Push attempted: NO`.

Codex never pushes, never regolds and never converts a local candidate into a
published phase or acquired gate.
