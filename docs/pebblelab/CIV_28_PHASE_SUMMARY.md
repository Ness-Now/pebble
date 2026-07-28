# CIV-28 — Observer and Chronicle V1

## Verdict and baseline

`CIV-28` is complete in its bounded contract at product commit
`57d7a57dec3956ba3d4bd30a837fa9417a29efb6`.

Gate R and Gate B remain acquired. `V4-GATE-C-v1` is ready for a separate
independent evaluation but is not acquired. `CIV-29` is not eligible.

## Contract proved

- `AgentSimulationSession` produces one versioned Observer snapshot at a
  coherent tick and causal sequence. The header binds the session, restored
  World/storage identity, snapshot generation and truncation state.
- Individuals expose bounded authoritative needs, current activity, structured
  reason, household, relations, practice/profession, physical position,
  material roles and recent causal references.
- Reasons distinguish acting, waiting, blocked, refused, failed, replanning,
  restart reconciliation and unavailable state. A reason may reference its
  authoritative subject, dependency and exact causal event.
- Chronicle rows are a deterministic projection of the existing causal ledger,
  not a second history. Global, individual and asset filters preserve stable
  newest-first sequence order and expose missing causes or truncation.
- Physical holder observations remain distinct from social custodian,
  recognized owner, claimants and authorized users.
- UI open/close, selection, pagination, filtering and causal navigation only
  present snapshot fields. Repeated observation changes no tick, durable
  digest or causal sequence.
- Reconciliation reasons only explain their still-active activity; a later
  action cannot remain masked by an obsolete activity or restart reason.
- Checkpoint/replay remains schema 20. Observer state is reconstructed from the
  aggregate and restored World binding, so no second persisted truth is added.

PebbleCore remains physical truth, Pebble owns live World binding and rendered
UI, PebbleAgents owns civilization qualification and causality, and
`AgentSimulationSession` remains the sole civilization aggregate root.

## Deterministic evidence

```text
swift build -c debug --product pebsmoke
PASS

PEBBLELAB_SMOKE_ONLY=observer .build/debug/pebsmoke
17 passed, 0 failed

scripts/verify-pebblelab.sh
3340 passed, 0 failed
35/35 verification steps
```

The prior repository baseline was 3323 checks. `CIV-28` adds 17 checks and
removes none.

## Rendered restart and visual evidence

Command:

```text
PEBBLELAB_CIV28_EVIDENCE_DIR=/tmp/PebbleLab-CIV28-final6 \
  scripts/verify-pebblelab-civ28.sh
```

Result: **PASS**, exit status 0.

The harness used World `PebbleLab-Disposable-CIV28-46`, seed 46, and two
separate Pebble processes:

```text
process 1: create real World/container/item and CIV-26 rights
           → record denied use with no physical attempt
           → save schema-20 checkpoint
           → open/select/filter/navigate read-only Observer
           → capture → terminate
process 2: load the same SaveDB World and checkpoint
           → reconcile rights and interrupted activity
           → open Observer and follow reconciliation event
           → capture → continue eight ticks
           → verify current action/reason → exact cleanup
```

Compact observed trace:

```text
World ID: wms59k423dvfm
simulation ID: live-46-14-68--18
agents: agent_0, agent_1, agent_2 before and after
asset: asset:civ27:live-pickaxe
physical holder: container:9,69,-18
custodian/authorized user: agent_1
recognized owner/claimant: agent_0
pre-restart refusal: agent_2 / refused:useRefused / event 10
post-restart activity: agent_1 / toolUse
post-restart reason: interruptedReconciled:persistenceReconciled / event 12
causal sequence: 10 before, 13 after reconciliation, 83 after continuation
continued tick/action/reason: 8 / observe_area / acting:goalAction
snapshot mutation: none; tick, sequence and digest stable on every read
bounded proof: 2 agents shown, 1 omitted; 12 events omitted after restart
duplication count: 0
runtime errors: 0
cleanup: exact; item/container state and checkpoint removed; probes removed
```

Both 3024×1898 captures were inspected at native resolution. They show a real
rendered normal World and legible Observer panels. Before restart, the selected
agent's refused use, physical/social divergence and causal event are visible.
After restart, the same World/session/asset roles and the activity's
reconciliation reason/event are visible.

```text
before PNG SHA-256:
bcc33c5a6dfc9355b97aef579d096c0734b38d03973fbb39ebf9e7fd2f112820

after PNG SHA-256:
e99eb35d416c6cca9e934a1b40db4f1ce05eccb847900c14330049b37d7ef4b3
```

## Honest V1 limits

- Observer V1 is local to one active civilization session and its explicit
  World binding. It is not an omniscient multi-settlement observer.
- Collections, text and causal depth are bounded. Truncation is explicit; V1
  provides neither unlimited graph traversal nor full-text search/export.
- Physical position is a verified session projection supplied through Pebble,
  not a direct World read from PebbleAgents.
- Chronicle exposes retained ledger history. Events already evicted under the
  causal retention policy are reported as missing/truncated, not reconstructed
  speculatively.
- The Observer is not an editor, admin console or business-rule engine.
- The campaign proves one rendered local restart scenario plus deterministic
  adversarial cases. Gate C still requires its own independent evaluation.
- Markets, currency, inheritance, land law, tribunals and `CIV-29` are not
  implemented or started here.
