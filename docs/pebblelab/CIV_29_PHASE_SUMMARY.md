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
  a new operation. Before finalization, each verified agent-held asset is
  transferred through Pebble's existing atomic custody gateway to a real,
  verified container. Only the physical holder changes: no item is deleted,
  duplicated or inherited and no social role is transferred.
- A Homeostasis V2 death is staged until required material exits succeed.
  `lethalHealthDepletion` directly cites the same-agent, same-tick terminal
  homeostasis event; the causal path remains navigable through resource and
  commitment retirement, population exit and final death. A refused physical
  exit rolls back exactly and leaves mortality unpublished and retryable.
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
25 passed, 0 failed

scripts/verify-pebblelab.sh
3369 passed, 0 failed
35/35 verification steps
```

The prior repository baseline was 3343 checks. `CIV-29` now adds 26 checks and
removes none; this corrective change adds 7 checks to the initial phase
candidate. Focused coverage includes stable physiology, natural age
progression, bounded later-life vulnerability, progressive deprivation,
recovery from verified food and rest, incapacity, single death, no post-death
agency, exact terminal-physiology causality, verified material exit and
rollback, preserved social roles, legacy-starvation compatibility, history
eviction, schema-21 checkpoint/replay, Observer read-only behavior and
corrupt-state refusal.

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
           → physically transfer the pickaxe into agent_2 custody
           → supply and consume real bread for agent_0 and agent_1
           → leave agent_2 without food
           → progress normally to incapacity at tick 22
           → capture holder and social roles in Observer
           → inject one verified physical rollback
           → advance to terminal physiology at tick 23
           → transfer the held pickaxe to a verified real container
           → finalize one causally linked death and capture Chronicle
           → save a post-death schema-21 checkpoint
           → terminate process and verify two remaining probes removed
process 2: load the same SaveDB World and post-death checkpoint
           → retire only the verified empty bootstrap probe for agent_2
           → reconcile the same physical asset as matched
           → capture the restored Observer and Chronicle
           → continue through tick 25 with no duplication or resurrection
           → remove proof-only food/claim/checkpoint/container state
           → terminate and verify two remaining probes removed
```

Compact observed facts:

```text
World binding: wms69943oletf
simulation: live-46-14-68--18
agents before death: agent_0, agent_1, agent_2
real food consumed before restart: 42 bread
deprived person: agent_2
pre-death state: tick 22, age 30, health 4, incapacitated
physical asset: asset:civ27:live-pickaxe / iron_pickaxe x1
holder before death: agent:agent_2
terminal homeostasis event: event-00000000000000000262
pending material exit event: event-00000000000000000263
verified material event: event-00000000000000000272
lethalHealthDepletion event: event-00000000000000000273
agentDeathFinalized event: event-00000000000000000278
physical receipt: mortality-exit:agent_2:t23:a2:9,69,-18
holder after death: container:9,69,-18
quantity: 1→1
custodian: agent_1
recognized owner: agent_0
claimants: agent_0, agent_2
authorized user: agent_1
social roles after death: unchanged
automatic inheritance: none
death: agent_2 at tick 23, compoundedHomeostaticFailure
post-death checkpoint: tick 23, causal sequence 278
post-restart reconciliation: matched, causal sequence 280
continued simulation: tick 25, causal sequence 296
active agents/probes: 3→2
death count: 1
resurrection or duplicate death count: 0
asset duplication count: 0
Observer mutation count: 0
runtime errors: 0
cleanup: exact
```

All three 3024×1898 captures were inspected. They show a real rendered World
behind legible Observer panels:

```text
agent-held asset before death SHA-256:
554e870e63ba647e58c3e5a34ac135bef5b3c0c0defae254f5bcad5a99f5bd11

verified material exit and mortality Chronicle SHA-256:
a1231fb82ece2246d1dde918dd862a00f84c3f9169e8078a126df934d1026dbd

post-death restart Observer and Chronicle SHA-256:
7985e462273cf9bbf8a2ef32162b2dfcbfa910cc8c9614ec8c8df9788b8edc61
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
- V1 mortality material exit requires a bounded, existing and safe real
  container near the dying probe. If none can accept every verified held
  stack, the physical mutation is rolled back, death is not finalized and the
  explicit pending transition remains retryable. No terrain, corpse container
  or fictitious endpoint is created.
- Claims and ownership survive death, but inheritance, estates and automatic
  transfer are deliberately absent until `CIV-33`.
- Schema 21 preserves the civilization trajectory and binds it to the existing
  CIV-27 World-reconciliation protocol. It does not claim a globally atomic
  World/civilization save.
- `CIV-30`, renewable subsistence and `V4-GATE-D-v1` evaluation are not
  started or acquired here.
