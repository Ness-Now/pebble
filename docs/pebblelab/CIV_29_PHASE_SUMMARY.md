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
  a new operation. Every embodied death requires Pebble to verify an empty
  carried inventory or transfer every real carried stack through the existing
  atomic custody gateway to a real, verified container. This is independent
  of whether Material Rights is enabled and includes stacks with no social
  asset record. Only corresponding existing records receive a verified holder
  observation: no social asset, ownership, claim or inheritance is invented.
- A Homeostasis V2 death is staged until terminal physical custody is verified.
  `lethalHealthDepletion` directly cites the same-agent, same-tick terminal
  homeostasis event; the causal path remains navigable through resource and
  commitment retirement, population exit and final death. A refused physical
  exit rolls back exactly and leaves mortality unpublished and retryable. The
  whole live boundary covers all transfers, the candidate session and replay,
  probe removals, controller indexes and final guards; a late failure restores
  the previously published World/controller/session state for the full batch.
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
30 passed, 0 failed

scripts/verify-pebblelab.sh
3374 passed, 0 failed
35/35 verification steps
```

The prior repository baseline was 3343 checks. `CIV-29` now adds 31 checks and
removes none; the publication corrections add 12 checks to the initial phase
candidate. Focused coverage includes stable physiology, natural age
progression, bounded later-life vulnerability, progressive deprivation,
recovery from verified food and rest, incapacity, single death, no post-death
agency, exact terminal-physiology causality, verified material exit and
full-boundary rollback, required custody verification without social assets,
explicit empty-probe verification, preserved social roles,
legacy-starvation compatibility, history eviction, schema-21
checkpoint/replay, Observer read-only behavior and corrupt-state refusal.

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
           → physically transfer the pickaxe and unregistered cobblestone x3
             into agent_2 custody
           → supply and consume real bread for agent_0 and agent_1
           → leave agent_2 without food
           → progress normally to incapacity at tick 22
           → capture holder and social roles in Observer
           → prove rights-disabled and rights-enabled unregistered inventory,
             explicit empty custody, no-container retry and two-death rollback
           → inject late failures after transfer, after probe removal and
             before publication; verify exact whole-boundary rollback
           → advance to terminal physiology at tick 23
           → transfer both held item kinds to a verified real container
           → update only the existing pickaxe social record
           → finalize one causally linked death and capture Chronicle
           → save a post-death schema-21 checkpoint
           → terminate process and verify two remaining probes removed
process 2: load the same SaveDB World and post-death checkpoint
           → retire only the verified empty bootstrap probe for agent_2
           → reconcile the tracked physical asset as matched
           → verify the unregistered cobblestone remains physically present
           → capture the restored Observer and Chronicle
           → continue through tick 25 with no duplication or resurrection
           → remove proof-only food/claim/checkpoint/container state
           → terminate and verify two remaining probes removed
```

Compact observed facts:

```text
World binding: wms6e4jlz7grw
simulation: live-46-14-68--18
agents before death: agent_0, agent_1, agent_2
real food consumed before restart: 42 bread
deprived person: agent_2
pre-death state: tick 22, age 30, health 4, incapacitated
tracked physical asset: asset:civ27:live-pickaxe / iron_pickaxe x1
unregistered physical item: cobblestone x3
holder before death: agent:agent_2
terminal homeostasis event: event-00000000000000000262
pending material exit event: event-00000000000000000263
verified material event: event-00000000000000000272
verified physical custody event: event-00000000000000000273
lethalHealthDepletion event: event-00000000000000000274
agentDeathFinalized event: event-00000000000000000279
physical receipt: mortality-exit:agent_2:t23:a1:9,69,-18
holder after death: container:9,69,-18
tracked quantity: 1→1
unregistered quantity: 3→3
total physical quantity: 4→4
custodian: agent_1
recognized owner: agent_0
claimants: agent_0, agent_2
authorized user: agent_1
social roles after death: unchanged
invented social records: 0
automatic inheritance: none
death: agent_2 at tick 23, compoundedHomeostaticFailure
late rollback injections: after transfer, after probe removal, before publish
rollback equality: session, replay, probes, identities, inventories
no-container result: unchanged and retryable
two-death batch: full rollback, then two successful retry deaths
post-death checkpoint: tick 23, causal sequence 279
post-restart reconciliation: matched, causal sequence 281
continued simulation: tick 25, causal sequence 297
active agents/probes: 3→2
death count: 1
resurrection or duplicate death count: 0
asset duplication count: 0
physical loss count: 0
Observer mutation count: 0
runtime errors: 0
cleanup: exact
```

All three 3024×1898 captures were inspected. They show a real rendered World
behind legible Observer panels:

```text
agent-held asset before death SHA-256:
33a762b8a2feaa2e861001fb0e46b62c11ba8499294d0050bde68c3e361b746e

verified material exit and mortality Chronicle SHA-256:
ef8161032602115ab2d4b2dc375bb310f50979da10383dd02ab88a6250ada90a

post-death restart Observer and Chronicle SHA-256:
6e0176115f0afb2fa302fda58d75f7ada2d425bd48b78517167e5dabc60cd398
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
- V1 mortality physical exit requires a bounded, existing and safe real
  container near the dying probe. If none can accept every physically carried
  stack, the physical mutation is rolled back, death is not finalized and the
  explicit pending transition remains retryable. No terrain, corpse container,
  social asset record or fictitious endpoint is created.
- Claims and ownership survive death, but inheritance, estates and automatic
  transfer are deliberately absent until `CIV-33`.
- Schema 21 preserves the civilization trajectory and binds it to the existing
  CIV-27 World-reconciliation protocol. It does not claim a globally atomic
  World/civilization save.
- `CIV-30`, renewable subsistence and `V4-GATE-D-v1` evaluation are not
  started or acquired here.
