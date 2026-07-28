# CIV-26 — Possession, Custody, Claims and Use Rights V1

## Verdict and baseline

`CIV-26` is complete in its bounded contract at product commit
`b410b47040deaa8d7b949c8c58023dadf9349f03`.

Gate R and Gate B remain acquired. `V4-GATE-C-v1` remains planned. This phase
does not start `CIV-27`.

## Contract proved

- PebbleCore remains physical truth for item existence, stack identity,
  location, container and holder.
- Pebble performs bounded inventory-to-inventory transfers, verifies the real
  result and owns rollback.
- PebbleAgents records a bounded social asset reference, delegated custodian,
  locally recognized owner, concurrent claims, explicit use permissions,
  decisions and causal transitions.
- `AgentSimulationSession` remains the sole civilization aggregate root.
- Physical transfer, claim assertion, ownership recognition, custody
  delegation and permission grant/revocation are separate operations.
- A denied use creates no physical result. An observed unauthorized transfer
  can preserve the earlier claim and record a transgression.
- Failed or rolled-back physical transfer publishes no false holder, custody
  or claim transition.
- Checkpoint and replay schema 19 preserve the bounded state and exact durable
  digest.

Recognition is explicit and local to a bounded witness list. It is not a
global legal oracle.

## Deterministic evidence

```text
PEBBLELAB_SMOKE_ONLY=material-rights swift run -c release pebsmoke
21 passed, 0 failed

scripts/verify-pebblelab.sh
3305 passed, 0 failed
35/35 verification steps
```

The prior repository baseline was 3284 checks. `CIV-26` adds 21 checks and
removes none.

## Targeted live evidence

Command:

```text
scripts/verify-pebblelab-live.sh --rights
```

Result: **PASS**, exit status 0.

Scenario:

```text
World: PebbleLab-Disposable-Rights-46
seed: 46
player anchor: 14,68,-18
asset: one real iron_pickaxe
physical holder: agent_2
delegated custodian: agent_1
locally recognized owner: agent_0
active claimants: agent_0, agent_2
authorized user: agent_1
conflict: active
late transfer failure: rolled back, roles unchanged
```

The real Pebble custody gateway performed the transfers. The final screenshot
was inspected at 3024×1898 and showed a rendered forest World plus the compact
rights projection. Its SHA-256 is
`97505e60b99e2e45408070547ec8ae5494c389eb9e9c611644d11321222205ff`.

Cleanup restored all three inventories, retained the exact three proof probes
until normal shutdown, left no proof iron-pickaxe `ItemEntity`, cleared the
rights fixture, removed all three probes at shutdown and reported
`runtimeErrors=0`.

## Honest V1 limits

- The social asset reference binds a stable civilization ID to a verified
  Pebble stack identity and bounded quantity. It is not a new physical item
  registry and does not claim universal per-unit UUIDs.
- The last verified holder is an observation, not a second inventory.
- Full World-save restart, reconciliation and recovery from externally changed
  physical custody belong to `CIV-27`.
- Markets, prices, currency, debt, taxation, land law, courts, police,
  inheritance and estates are not implemented.
- Observer V1 remains `CIV-28`; the compact live overlay exists only as
  targeted phase evidence.
