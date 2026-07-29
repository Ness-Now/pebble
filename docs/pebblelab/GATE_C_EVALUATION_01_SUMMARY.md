# V4-GATE-C-v1 — Independent evaluation

Date: 2026-07-29

## Status and independence

`V4-GATE-C-v1` passed an independent adversarial evaluation of the published
product baseline:

```text
3d70c67b69824133eb318391f8e7c385f8cabce8
```

The evaluation audited the published implementations and composed their real
boundaries. Phase reports were treated as evidence to verify, not as
conclusions. No product source was changed. The local status and evidence in
this report are a publication candidate; acquisition becomes canonical only
after senior review, manual push and remote verification.

## Contract

Gate C requires all of the following together:

```text
real physical rights
AND real restart
AND real reconciliation
AND zero duplication
AND causal continuity
AND understandable Observer before restart
AND understandable Observer after restart
AND read-only observation
AND deterministic bounded evidence
```

Required phases: `CIV-26`, `CIV-27`, `CIV-28`.

## Authority audit

The evaluation traced the material-rights, persistence/reconciliation and
Observer paths through these primary surfaces:

- `PebbleCore`: `World`, real entities/items/containers and `SaveDB`;
- `Pebble`: `PebbleAgentMaterialCustodyGateway`, material snapshot bridge,
  checkpoint load, physical reconciliation and Observer UI;
- `PebbleAgents`: material rights, schema-20 checkpoint/replay,
  reconciliation policy, causal ledger and Observer projection;
- `AgentSimulationSession`: sole civilization aggregate root;
- `pebsmoke`: adversarial contracts for the three phases and replay.

The ownership boundary is preserved:

| Authority | Evaluated result |
| --- | --- |
| PebbleCore | Sole World, matter and physical-persistence truth. |
| Pebble | Owns live observation, verified transfer, reconciliation and rendered UI integration. |
| PebbleAgents | Owns bounded social rights, deterministic reconciliation decisions, causality and Observer qualifications without importing a live World. |
| AgentSimulationSession | Sole civilization aggregate root and publication boundary. |
| Observer | Read-only projection and presentation; no business mutation. |

No second World, inventory, container registry, holder authority, causal
ledger or UI-owned business truth was found.

## Gate C invariant matrix

| Invariant | Evidence | Result |
| --- | --- | --- |
| Real physical rights | Real `iron_pickaxe` stack in Pebble container; holder, custodian, owner, claimant and authorized user remain distinct. | PASS |
| Failed transfer safety | Focused rights suite verifies rollback publishes no false roles. | PASS |
| Physical/social divergence | Physical holder is a container while custodian/user is `agent_1` and owner/claimant is `agent_0`. | PASS |
| Real restart | Two complete Pebble processes use the same SaveDB World and schema-20 checkpoint. | PASS |
| Reconciliation before publication | Second process reports `applied:missing`; candidate session is published only after a publishable reconciliation. | PASS |
| Physical truth prevails | The physically removed asset is not recreated; social rights survive with an explicit `missing` result. | PASS |
| Zero duplication | Reconciliation and campaign duplication counts are zero; repeated restore/observation tests are idempotent. | PASS |
| Causal continuity | Sequence advances `10 → 13 → 83`; prior refusal and reconciliation events remain inspectable. | PASS |
| Interrupted activity policy | Missing dependency causes bounded replan; normal action resumes after continuation. | PASS |
| Understandable Observer | Readable before/after rendered panels expose physical, social and causal facts separately. | PASS |
| Read-only Observer | Every open/select/filter/page/event/close check preserves tick, sequence and durable digest. | PASS |
| Deterministic bounds | Claims, permissions, scans, Chronicle, direct causes and text are bounded; truncation is explicit. | PASS |
| Continuation after restart | Simulation advances eight ticks and presents a newer `acting:goalAction` reason. | PASS |
| Cleanup | Both processes terminate; probes, checkpoint and disposable World home are removed; runtime errors are zero. | PASS |

## Focused adversarial evidence

Command:

```text
PEBBLELAB_GATE_C_EVIDENCE_DIR=<fresh-path> \
  scripts/verify-pebblelab-gate-c.sh
```

The harness first runs four published focused suites:

| Suite | Result | Adversarial contracts sampled |
| --- | ---: | --- |
| CIV-26 material rights | 21 passed, 0 failed | rollback, conflict, divergence, claim bound, causal/idempotent transitions |
| CIV-27 persistence/reconciliation | 18 passed, 0 failed | changed holder, missing, ambiguous, conflicting/duplicated, repeat restore, wrong World, incompatible schema/identity |
| CIV-28 Observer/Chronicle | 20 passed, 0 failed | stale reason, wrong-asset permission, causal bounds, truncation, repeated read-only observation |
| Checkpoint/replay | 49 passed, 0 failed | exact restore, causal sequence, cross-simulation record, truncated journal |

Total: **108 passed, 0 failed**.

## Integrated rendered two-process campaign

The campaign uses World `PebbleLab-Disposable-GateC-46`, seed `46`, three real
agents, a real container and a real `iron_pickaxe`.

Before restart:

```text
World binding: wms5y5vwa840a
simulation: live-46-14-68--18
agents: agent_0, agent_1, agent_2
asset: asset:civ27:live-pickaxe
physical holder: container:9,69,-18
custodian / authorized user: agent_1
recognized owner / claimant: agent_0
current refusal: refused:useRefused
causal event: 10
tick / sequence: 0 / 10
Observer mutation count: 0
```

After the checkpoint, process 1 removes the real container through Pebble's
normal `/setblock` command boundary and stops completely. Process 2 restores
the same SaveDB World and checkpoint. Reconciliation performs real work:

```text
physical result: asset missing
reconciliation outcome: missing
reconciliation event: 11
duplicate count: 0
post-reconciliation tick / sequence: 0 / 13
activity policy: bounded replan
```

The social custodian, owner, claim and permission survive without recreating
the missing item. The Observer exposes `replanning:boundedReplan`, and its
event view can inspect reconciliation event 11. After resuming:

```text
tick / sequence: 8 / 83
activity: observe_area
current reason: acting:goalAction
reason event: 79
```

This demonstrates that an obsolete refusal or restart reason does not mask the
newer action. The result is not injected into civilization state: the physical
change happens at the World boundary and reconciliation derives its result
from the restored World.

## Visual inspection

Both 3024×1898 captures were inspected at native resolution. Text is legible,
the Observer is visibly over a real rendered World, and the relevant rows are
not cut:

| Capture | Visible evidence | SHA-256 |
| --- | --- | --- |
| `gate-c-observer-before-restart.png` | World binding, agent 2, refusal, event 10, real asset, holder/custody/owner/claim/permission divergence | `52a33d934a8bc370c5032b170a76dd0ea236c36c51e8dfa1e18838d02cba60e9` |
| `gate-c-observer-after-restart.png` | Same World binding, agent 1, missing reconciliation, bounded replan, retained rights, event 12 in recent history | `179acebae4ab8369001acb661263bdd84d8afafa57a0442c8060264a832a6e0e` |

The explicit reconciliation event 11 was inspected through the event view in
the live trace; the representative after-restart capture shows the resulting
individual state and recent reconciliation history.

## Full validation and cleanup

```text
scripts/verify-pebblelab.sh
3343 passed, 0 failed
35/35 verification steps

git diff --check
PASS
```

Both Pebble processes exited with status 0. The final campaign reports:

```text
runtime errors: 0
duplications: 0
Observer mutations: 0
checkpoint removed: YES
transient probes removed: YES
disposable session home and World removed: YES
residual Pebble/pebsmoke/swift-run process: NO
cleanup: exact
```

## Honest limits

- The material reference identifies a bounded Pebble stack/item kind and
  quantity; it is not a universal per-unit UUID.
- Reconciliation searches bounded candidate holders. It fails closed rather
  than performing an omniscient global World scan.
- World and civilization saves are explicitly bound but are not claimed as a
  single cross-store atomic transaction.
- Observer/Chronicle remains a bounded local-session projection with retained
  ledger history, not an unlimited graph, full-text index or editor.
- This gate proves one strong integrated local rendered restart plus
  deterministic adversarial coverage. It does not prove generational
  continuity, renewable subsistence, markets or any `CIV-29` behavior.

## Verdict

```text
GATE C PASS — READY FOR SENIOR REVIEW AND MANUAL PUBLICATION

product source changes: NONE
V4-GATE-C-v1 publication candidate: ACQUIRED
CIV-29: NOT STARTED — NEXT ELIGIBLE PHASE
push attempted: NO
```
