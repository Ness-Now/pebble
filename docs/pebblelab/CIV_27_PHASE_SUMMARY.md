# CIV-27 — Durable World/Civilization Persistence and Reconciliation V1

## Verdict and baseline

`CIV-27` is complete in its bounded contract at product commit
`eb63a62a6d5e6851bd11b98926591db3be608f5d`.

Gate R and Gate B remain acquired. `V4-GATE-C-v1` remains planned. This phase
does not start `CIV-28`.

## Contract proved

- PebbleCore `SaveDB` remains the only physical World persistence authority.
- Pebble loads the real World before observing bounded physical references and
  before publishing a restored `AgentSimulationSession`.
- Checkpoint/replay schema 20 binds the expected World/storage identity, seed,
  dimension, checkpoint tick, causal sequence and bounded asset expectations.
- The restored World prevails for existence, holder, quantity, container and
  material identity. Reconciliation reports `matched`,
  `changedButReconcilable`, `missing`, `ambiguous`,
  `duplicatedOrConflicting` or `invalid`.
- Claims, recognized ownership, custody and permissions survive a missing or
  moved physical asset without inventing it. A missing asset blocks stale use.
- Ambiguous, conflicting, invalid, wrong-World and incompatible-schema inputs
  fail before candidate-session publication.
- Interrupted activities receive an explicit bounded policy: resume,
  revalidate then resume, replan, rollback or causal cancellation. The live
  proof revalidates one commitment-sourced activity before continuation.
- Applying the same reconciliation run twice is idempotent. Agent identities,
  claims, obligations, events and physical items are not duplicated.
- Reconciliation corrections extend the existing causal ledger; simulation
  ticks and event sequences do not regress.

`AgentSimulationSession` remains the sole civilization aggregate root.
PebbleAgents contains no World, inventory, container or physical-transfer
implementation.

## Deterministic evidence

```text
PEBBLELAB_SMOKE_ONLY=persistence-reconciliation swift run pebsmoke
18 passed, 0 failed

PEBBLELAB_SMOKE_ONLY=material-rights swift run pebsmoke
21 passed, 0 failed

PEBBLELAB_SMOKE_ONLY=checkpoint-replay swift run pebsmoke
49 passed, 0 failed

scripts/verify-pebblelab.sh
3323 passed, 0 failed
35/35 verification steps
```

The prior repository baseline was 3305 checks. `CIV-27` adds 18 checks and
removes none.

## Real restart and visual evidence

Command:

```text
scripts/verify-pebblelab-civ27.sh
```

Result: **PASS**, exit status 0.

The harness used World `PebbleLab-Disposable-CIV27-46`, seed 46, and two
separate Pebble processes:

```text
process 1: create real World and chest → insert one iron_pickaxe
           → establish CIV-26 rights and one active activity
           → write schema-20 checkpoint → capture → terminate
process 2: load the same SaveDB World → create fresh transient probes
           → restore checkpoint → observe/reconcile asset as matched
           → revalidate activity → continue 8 ticks → capture → cleanup
```

Compact observed trace:

```text
World ID: wms51k0va3xaq
simulation ID: live-46-14-68--18
agents: agent_0, agent_1, agent_2 before and after
asset: asset:civ27:live-pickaxe
physical holder: container:9,69,-18 before and after
custodian/authorized user: agent_1
recognized owner/claimant: agent_0
checkpoint causal sequence: 9
post-reconciliation causal sequence: 12
continued tick/sequence: 8/82
duplication count: 0
runtime errors: 0
cleanup: exact; chest/item and checkpoint removed; three probes removed
```

Both 3024×1898 captures were inspected. They show the same rendered forest,
same chest and same three agent probes before and after restart, with the
rights projection unchanged and causal/tick continuation visible.

```text
before PNG SHA-256:
6b58b03ede9d6463bc3813fb5dd56ca74dbbe98a95c4e8df02e7defe129192ee

after PNG SHA-256:
907916de562d579c8ae05d0497dce1f27e4ec12a19c67d2619403645c994ae60
```

## Honest V1 limits

- World and civilization persistence are separate stores. V1 detects and
  reconciles their boundary; it does not claim a global atomic disk
  transaction.
- The physical asset reference uses Pebble stack identity and quantity, not a
  universal per-unit UUID.
- Reconciliation scans only holders declared in the bounded checkpoint:
  civilization agents and known compatible material-rights holders. An asset
  moved into an unknown container is reported missing/unresolved, never found
  by an unbounded World scan or recreated.
- V1 supports schema 20 plus the repository's existing supported schemas. It
  does not provide arbitrary historical migrations.
- The live fixture proves one real local World, container and item across an
  actual process boundary. It is not cloud/network persistence, a scale test
  or a global recovery guarantee.
- Observer and Chronicle V1 remains `CIV-28`. Gate C, markets, currency, debt,
  inheritance, land law and tribunals are not implemented or acquired here.
