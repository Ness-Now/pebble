# Gate D Blocker 01 — Verified physical position restoration

## 1. Affected published baseline

This targeted product correction starts from the published product baseline:

```text
47104f70894b20e7d7db0042cb93f047540c336d
```

The baseline contains checkpoint schema 29 and Observer schema 7. This work
does not evaluate or acquire `V4-GATE-D-v1`, and it does not start `CIV-34`.

## 2. Preserved FAIL evidence

Independent evaluation commit
`9232b65a8a32b2d054fe2e5c7ea80e0dd990d378` on historical local branch
`codex/gate-d-evaluation-01` records:

```text
GATE D FAIL — PRODUCT CORRECTION REQUIRED
```

Its `docs/pebblelab/GATE_D_EVALUATION_01_SUMMARY.md` report and evaluation
runner remain unchanged. The reported composed checkpoint was schema 29 for
World `wmsapr1gca3ro`, session `live-46-14-66--21`, and normal child
`agent_3`. A fresh process refused it with `checkpoint positions differ from
live physical truth`.

## 3. Reproduction

The published loader compared every shared checkpoint agent to its fresh
bootstrap probe and accepted only exact positions. The bootstrap recreates
the three founder probes at launch; those probes are not World-persisted
entities. Normal movement before save can therefore make their saved physical
positions differ from the new process placeholders. A child born after
bootstrap is absent and already had a separately protected creation path.

The focused two-process campaign reproduces both cases together:

| Agent | Checkpoint | Fresh bootstrap | Classification |
| --- | --- | --- | --- |
| `agent_0` | `19,66,-25` | `20,66,-24` | `repositioned_verified` |
| `agent_1` | `20,66,-23` | `21,66,-24` | `repositioned_verified` |
| `agent_2` | `22,66,-23` | `22,66,-24` | `repositioned_verified` |
| `agent_3` | `18,67,-24` | absent | `restored_missing` |

Before load there are three shared-position mismatches and one missing probe.
After load every checkpoint agent has one physical probe at its checkpoint
position, with zero mismatches and zero duplicate probes.

## 4. Root cause and authority audit

- Founders are recreated by the Pebble bootstrap in each process. Their
  `LabCoreAgentEntity` probes are nonpersistent placeholders, not SaveDB
  entities.
- `AgentSnapshot.position` is the civilization projection synchronized from
  verified movement. Checkpoint save previously did not recheck it against
  every live probe.
- `createProbe(for:in:)` maps an `AgentPosition` to the center of its physical
  cell and initializes previous and current coordinates coherently.
- `prevX`, `prevY`, and `prevZ` feed entity interpolation and movement state;
  preserving bootstrap previous coordinates would create a false restart
  delta.
- A probe carries physical matter in its real `carriedItems` slots. The
  manifest's digest-protected `verifiedEmptyProbeAgentIDsAtSave` attests only
  which checkpoint probes were observed with all of those slots empty at
  save.
- Material Rights independently records the last verified physical holder.
  An agent resolved as that holder cannot use empty-probe restoration.
- `liveRestartSafety()` protects app-only physical receipts, but is not an
  authority for distinguishing a fresh process from a progressed same-process
  session.
- The existing absent-probe path already recreated a population/lifecycle
  identity only from protected empty custody and no contradictory holder.
- Probe retirement and creation were transactional, but shared probes had no
  verified reposition operation or corresponding rollback state.

No second World, movement, inventory, custody, or persistence engine is added.

## 5. Previous semantics

The old load boundary had two outcomes:

```text
checkpoint-only active agent with protected empty custody
→ create one probe at the checkpoint position

shared active agent at a different position
→ refuse load
```

That rule was fail-closed, but it treated a fresh bootstrap placeholder as
non-reconcilable live progress and blocked a valid composed restart.

## 6. New load semantics

One deterministic planner classifies every checkpoint agent in canonical ID
order:

```text
reused_exact
restored_missing
repositioned_verified
refused
```

Exact probes are reused without mutation. Missing probes retain the existing
protected creation path. A shared mismatched probe is repositioned only when
the checkpoint/world binding is valid, population and lifecycle identities
are valid, the checkpoint manifest protects its empty-custody attestation,
the current probe is unique, live, attached to the same World and physically
empty, and no Material Rights record resolves that agent as physical holder.

Invalid targets, duplicate probes or positions, missing identity or
attestation, non-empty current custody, contradictory holders and incomplete
final probe sets refuse the load before publication.

After physical work, all embodiments are resolved again. Final agent IDs,
probe object uniqueness, positions, mappings and session positions must match
the checkpoint exactly. A real reposition is reported as:

```text
worldMutation=verified_probe_position_restore
```

## 7. Save-time position validation

Save now resolves every live checkpoint embodiment and compares its physical
cell with `AgentSnapshot.position` before checkpoint creation or bundle
writing:

```text
session position == physical embodiment position
→ save may continue

session position != physical embodiment position
→ save refused with bounded agent/session/physical diagnostics
```

The refusal changes no session, causal ledger, World entity, probe, inventory,
checkpoint list or partial bundle.

## 8. Position and movement restoration

Verified reposition uses the Pebble entity boundary, not a second position
authority. It sets the target cell center, makes current and previous
coordinates equal, clears velocity, and aligns previous/current yaw and pitch.
The same embodiment resolver used by normal runtime verification must then
recover the checkpoint `AgentPosition` exactly.

This prevents interpolation from the bootstrap location, a false movement
delta, stale navigation coordinates and a visible post-restart jump.

## 9. Custody policy

Schema-29 empty-custody evidence is sufficient for this bounded correction.
Both a protected save-time attestation and an actually empty current probe are
required for a mismatched or missing probe. Any Material Rights physical-holder
record is a contradiction.

V1 intentionally refuses a position mismatch on a non-empty probe. It does not
attempt a general carried-inventory restore, recreate items, infer custody or
move unproven matter.

## 10. Atomicity and rollback

Before World mutation, load retains the old session, executors,
orchestration, probe mapping, exact World entity objects, each affected probe
object, current/previous position, velocity, orientation, dead state and a
deep copy of carried inventory.

Injected failures after the first reposition and after missing-child creation
prove rollback. Created probes are removed; repositioned probes regain every
captured field; retired probes are re-added; the old mapping and session are
restored. Verification uses object identity as well as agent IDs. No error can
leave a second probe, a checkpoint-position probe with the old session, an
unmapped child, altered inventory or a changed World entity set.

## 11. Same-process policy

The correction adopts the same bounded policy for fresh- and same-process
loads. A shared mismatched probe may return to the checkpoint position only if
it is empty and fully reconcilable under the protected manifest, identity,
World-binding and Material Rights checks. Tick zero alone is not trusted.

This supports legitimate same-process rollback without treating all live
divergence as disposable. A non-empty or contradictory probe remains
fail-closed in both cases.

## 12. Compatibility

No schema change is required. Schema 29 already contains the durable position,
canonical World binding, integrity-protected empty-custody attestation,
restart-safety metadata and Material Rights/reconciliation state needed by the
protocol. The loader additionally requires the World-binding cell-position
set to equal the positions canonically derived from the checkpoint.

Valid schema-29 bundles with sufficient proof remain readable. A divergence
that cannot satisfy those existing proofs is refused. No new interpretation
of a durable field and no schema-30 data are introduced.

## 13. Targeted campaign and regressions

The reproducible runner is:

```text
scripts/verify-pebblelab-gate-d-position-restore-fix.sh
```

Its final campaign uses World `wmsat85ib194e` and session
`live-46-14-66--21`. Process 1 produces `agent_3` by normal birth, preserves
its inherited genotype, canonical parentage, guardian/caregiver and verified
supervision, proves an interrupted tick receives no credit, moves real probes
and saves schema 29. Process 2 begins from three fresh founder probes, proves
non-empty and duplicate-probe refusals, proves both rollback injection points,
repositions three founders, creates the missing child, repeats the same load
idempotently, continues two ticks and saves again.

Final results:

```text
focused suites: 650 passed, 0 failed
repository gate: 3652 passed, 0 failed
repository steps: 35/35
position mismatches before load: 3
position mismatches after load: 0
probe duplication: 0
physical item duplication: 0
Observer mutation: 0
runtime errors: 0
cleanup: exact
```

Three rendered 3024×1898 captures were individually inspected: coherent G1
state at save, the fresh three-founder bootstrap, and the restored four-agent
state. Continued tick/checkpoint evidence is textual and digest-bound; no
unstable transitional UI capture is claimed.

## 14. Limits

- This correction proves the formerly blocked composed restart only. It is not
  a new independent Gate D evaluation.
- Non-empty mismatched probes remain unsupported and fail closed.
- The protocol does not make civilization position superior to arbitrary live
  physical state; restoration requires the complete bounded proof above.
- It does not provide cross-store atomicity, general inventory restoration,
  global World scanning or a new reconciliation authority.
- Gate D's three-level genealogy, mature G1 reproduction, G0 death and estate
  settlement must still be reevaluated independently from a published fixed
  product HEAD.

## 15. Program status

```text
former Gate D blocker: CLEARED — LOCAL REVIEW CANDIDATE
V4-GATE-D-v1: NOT EVALUATED
next authorized action after publication: NEW INDEPENDENT V4-GATE-D-v1 EVALUATION
CIV-34: NOT STARTED
```

Publication still requires senior review, a manual push and remote
verification. Push attempted by Codex: NO.
