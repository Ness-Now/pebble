# CIV-29 — Homeostasis, Health, Aging and Mortality V2

## Verdict and baseline

`CIV-29` is complete in its bounded contract as a local publication
candidate. It was implemented from published baseline:

```text
3452bf92a0f324a2fb9bd9824fc729ec3b4b860c
```

This report intentionally does not self-reference the commit containing the
phase. Gate R, Gate B and `V4-GATE-C-v1` remain acquired; Gate C is not
reevaluated. `CIV-30` is not started.

## Contract proved

- `AgentNeeds`, the existing `AgentSessionAgentState.health` reserve,
  lifecycle age/stage and mortality records remain the underlying
  authorities. Homeostasis V2 adds one bounded trajectory over them, not a
  second needs, age, health-point or mortality engine.
- Each active person has a derived vital status, health condition and trend,
  bounded energy reserve, physiological stress, recovery capacity,
  age-vulnerability value, contributing factors and health episodes.
- Real physical food consumption and normal rest are the only recovery inputs
  used by V2. Recovery is gradual and bounded; no food or health is created.
- Persistent compounded hunger and fatigue move through observable
  intermediate conditions before incapacity and causal death. Incapacity
  interrupts autonomous activity. Death is finalized once, removes the active
  cognitive/physical actor, and prevents later action, consumption, aging or
  resurrection.
- Later life reduces recovery capacity and stress tolerance within explicit
  bounds. Age alone does not schedule death or grant profession, skill,
  knowledge or status.
- Mortality preserves household/kinship history and passive material claims,
  ownership, permissions and obligations. A deceased claimant cannot initiate
  a new operation. No item is deleted, transferred or inherited by this phase.
- Profiles, factors, episodes and retained transitions have explicit bounds.
  Evictions are counted. Checkpoint/replay schema 21 preserves the exact
  trajectory and rejects invalid bounds before session publication.
- Observer schema 2 reads the authoritative projection and exposes age,
  stage, vital status, condition, trend, reserves, factors, limitation and
  terminal mortality. Repeated observation changes no tick, causal sequence
  or durable bytes.

PebbleCore remains physical truth. Pebble owns real food/container operations,
physical embodiment removal, rendered UI and lifecycle verification.
PebbleAgents owns deterministic physiology and causal decisions.
`AgentSimulationSession` remains the sole civilization aggregate root.

## Deterministic evidence

```text
PEBBLELAB_SMOKE_ONLY=homeostasis-health swift run pebsmoke
19 passed, 0 failed

scripts/verify-pebblelab.sh
3362 passed, 0 failed
35/35 verification steps
```

The prior repository baseline was 3343 checks. `CIV-29` adds 19 checks and
removes none. Focused coverage includes stable physiology, natural age
progression, bounded later-life vulnerability, progressive deprivation,
recovery from verified food and rest, incapacity, single death, no post-death
agency, preserved claims, history eviction, schema-21 checkpoint/replay,
Observer read-only behavior and corrupt-state refusal.

Related published suites for mortality, lifecycle, physical food,
material rights, persistence/reconciliation and Observer also pass inside the
repository gate.

## Rendered restart and visual evidence

Command:

```text
PEBBLELAB_CIV29_EVIDENCE_DIR=<fresh-temporary-evidence-directory> \
  scripts/verify-pebblelab-civ29.sh
```

Result: **PASS**, exit status 0.

The harness used World `PebbleLab-Disposable-CIV29-46`, seed 46, and two
separate Pebble processes:

```text
process 1: bootstrap three real probes in a rendered World
           → register one real iron pickaxe and divergent social claims
           → supply and consume real bread for agent_0 and agent_1
           → leave agent_2 without food
           → progress normally to incapacity at tick 22
           → save schema-21 checkpoint and capture Observer
           → terminate process and verify three probes removed
process 2: load the same SaveDB World and checkpoint
           → reconcile the physical asset as matched
           → capture restored degradation at tick 22
           → advance normally to one causal death at tick 23
           → capture mortality Chronicle
           → continue through tick 25 with no resurrection
           → remove proof-only food/claim/checkpoint/container state
           → terminate and verify two remaining probes removed
```

Compact observed facts:

```text
World binding: wms63ymk34eeb
simulation: live-46-14-68--18
agents before restart: agent_0, agent_1, agent_2
real food consumed before restart: 42 bread
deprived person at checkpoint: agent_2
checkpoint state: tick 22, age 30, health 4, incapacitated
causal sequence: 256 before restart, 258 after reconciliation
physical asset: asset:civ27:live-pickaxe / iron_pickaxe x1
holder: container:9,69,-18
custodian: agent_1
recognized owner: agent_0
claimants: agent_0, agent_2
authorized user: agent_1
death: agent_2 at tick 23, compoundedHomeostaticFailure
post-death causal sequence: 276
active agents/probes: 3→2
death count: 1
resurrection or duplicate death count: 0
Observer mutation count: 0
runtime errors: 0
cleanup: exact
```

All three 3024×1898 captures were inspected. They show a real rendered World
behind legible Observer panels:

```text
pre-restart incapacity SHA-256:
bcbbf7570a32c8557a3373d01274518462fc73614a845ea6c97cb294aeb83ebd

post-restart restored progression SHA-256:
ecb8d26c0a6000eeadbcf693d026c3027c01d631f04a5ace9249ffcad5178701

final mortality Chronicle SHA-256:
e76157e18b8e4070e61d0e02c04b7758df193b2ca74944c486d3e9ca1de7774e
```

## Honest V2 limits

- This phase models needs-grounded deprivation and recovery, not a disease
  catalog, contagion, medicine, complex wounds or combat health.
- A distinct long-term impairment mechanic is not implemented. Temporary
  health condition and retained episodes are not presented as permanent
  disability.
- The lab tick scale makes aging and the proof trajectory observable quickly;
  it is not a real-time demographic calibration.
- Pebble provides no corpse primitive required by this phase, so no corpse
  system was invented. The transient agent probe is removed through the
  existing physical boundary.
- Claims and ownership survive death, but inheritance, estates and automatic
  transfer are deliberately absent until `CIV-33`.
- Schema 21 preserves the civilization trajectory and binds it to the existing
  CIV-27 World-reconciliation protocol. It does not claim a globally atomic
  World/civilization save.
- `CIV-30`, renewable subsistence and `V4-GATE-D-v1` evaluation are not
  started or acquired here.
