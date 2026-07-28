# Codex mission method — Guided autonomy V2

## Purpose

This operational method explains how to assign and review Codex work without
turning the mission prompt into a remote implementation plan. It complements
`AGENTS.md`; it does not duplicate or override mandatory repository rules.

The core contract is:

```text
freedom over technical means
+ precision about outcomes
+ strict invariants and scope
+ honest proportional evidence
```

## Responsibilities

### User

- owns product priorities and final repository control;
- reviews local commits;
- performs every push manually.

### Supervisor

- preserves vision and roadmap coherence;
- defines the outcome, timing, invariants, non-goals and evidence threshold;
- reviews architecture decisions and proof;
- authorizes or refuses publication.

### Codex

- verifies Git and reads applicable rules;
- audits real code and challenges incorrect assumptions;
- chooses architecture, files, migrations, tests and commit structure;
- implements and validates locally;
- reports blockers and limitations;
- never pushes or silently changes a gate contract.

### GitHub

Published code and evidence on the verified canonical SHA are the external
record. A local report, commit or passing suite is not publication.

## What a mission should specify

1. Exact repository, canonical branch and expected starting SHA.
2. Present program state and why this work is next.
3. A behavioral or documentary outcome, not a proposed class diagram.
4. The checkpoint’s claims and non-claims.
5. Permanent and task-specific invariants.
6. Explicit out-of-scope domains.
7. Evidence properties and canonical commands where relevant.
8. Local commit and final-report expectations.
9. `No push`.

## What a mission should usually leave to Codex

- file and type names;
- internal data structures;
- extraction points and local refactors;
- migration mechanics after repository audit;
- exact test cases and adversarial scenarios;
- commit count and grouping.

Prescribe these only when an incident, migration or ownership risk makes the
constraint itself part of the contract.

## Mission types

### New vertical

Use when the product result is clear but its design should be discovered.
Codex audits and implements in one run unless it finds a genuine architecture
blocker.

### Investigation

Use when the cause, criterion or correct owner is uncertain. The mission begins
read-only and may conclude:

```text
IMPLEMENT
CRITERION INCORRECT
STOP AND REDESIGN
INSUFFICIENT EVIDENCE
```

Implementation requires explicit scope if it was not part of the original
mandate.

### Targeted correction

Use when a real defect and expected behavior are known. State the regression
contract and boundaries, but allow Codex to choose the maintainable correction.
A correction does not automatically become a `CIV-XX` phase or reopen a gate.

### Documentation canonization

Use when program memory, authority or status is stale. It changes no product
behavior and uses structured-data, link, contradiction and diff validation.

## Risk calibration

- Level A: docs, projections and local refactors — broad autonomy, targeted
  checks.
- Level B: durable civilization state, cross-domain adapters and
  checkpoint/replay — guided autonomy with explicit ownership and migration
  proof.
- Level C: World mutation, inventory/custody, persistence, navigation, combat
  and scale — strict conservation, rollback, negative cases and live proof.
- Normal-world/player integration — add adversarial and rendered-world
  validation under the canonical V5 policy.

More risk means stronger contracts and evidence, not a prewritten
implementation.

## Reusable mission template

```text
You are the senior autonomous developer for Pebble Civilization.

Repository: <path>
Canonical branch: <branch>
Expected starting HEAD: <sha>
Never push.

## Preflight
Verify repository, remote branch, exact HEAD, clean worktree and all applicable
AGENTS.md. Stop without editing on a baseline mismatch.

## Mission
<descriptive phase, correction, investigation or docs title>

## Context and why now
<current acquired state and immediate reason>

## Outcome
<observable behavior or documentation result>

## Must prove
- <positive contract>
- <negative or refusal contract>
- <atomicity/conservation/replay as relevant>

## Invariants
- PebbleCore remains physical truth.
- Pebble remains the live adapter/executor boundary.
- PebbleAgents remains deterministic civilization authority.
- AgentSimulationSession remains the sole civilization aggregate root.
- Add only task-specific invariants that materially constrain safety.

## Out of scope
- <explicit neighboring domains>

## Technical mandate
Audit the real repository and choose the smallest coherent architecture,
files, tests and reviewable commits. Reuse existing owners. Challenge an
incorrect mission assumption rather than coding around it.

## Validation
Apply repository validation proportionally to risk. Use the canonical scripts
and Visual Game Smoke Policy only where applicable. Never inject the result
being proved.

## Report
State initial/final Git, decisions, changes, commands and exact results,
remaining limits, commits and `Push attempted: NO`.
```

## Review checklist

The supervisor checks:

- Did the change produce the requested result without opening another phase?
- Does each state and transition still have one owner?
- Were existing Pebble mechanics audited and reused?
- Do tests traverse the real boundary and include refusal/failure cases?
- Did a fixture create the claimed outcome?
- Are conservation, bounds, determinism and replay proportionate to the risk?
- Was visual evidence actually inspected when claimed?
- Does the full command, including cleanup, finish successfully?
- Are limitations explicit?
- Does the remote remain unchanged until manual publication?

## When to become more prescriptive

Constrain a mission more tightly when the constraint is itself known safety
knowledge, for example:

- an expired cooldown must stop blocking;
- schema versions must migrate or fail before mutation;
- World mutation follows prevalidate → mutate → verify → publish, with verified
  rollback;
- a historical retry storm or fake-live pattern needs a permanent regression;
- a gate’s contract version must not change after seeing campaign results.

Do not convert these behavioral constraints into mandatory internal type names
without necessity.

## Permanent rule

Frame the what, why, boundaries and proof. Let Codex discover the how from the
code that actually exists.
