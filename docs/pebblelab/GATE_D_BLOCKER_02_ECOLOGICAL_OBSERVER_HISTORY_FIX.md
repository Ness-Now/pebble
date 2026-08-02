# Gate D Blocker 02 — Historical ecological observer validation

## 1. Scope and affected baseline

This targeted correction starts from published product baseline:

```text
6d114abb98aee652e44fe9a81c3bab47b72ff698
```

That baseline includes checkpoint schema 29, Observer schema 7 and the
published Gate D Blocker 01 position-restoration correction. Independent Gate
D Evaluation 02 is preserved at commit
`d40ca4f8215ff14d904a1fb84aedb7ebd9185082` with verdict:

```text
GATE D FAIL — PRODUCT CORRECTION REQUIRED
```

Evaluation 01 commit `9232b65a8a32b2d054fe2e5c7ea80e0dd990d378`
also remains immutable. This work fixes one product boundary. It does not
evaluate or acquire `V4-GATE-D-v1`, and it does not start `CIV-34`.

## 2. Reproduction and final root cause

Evaluation 02 recorded a normal physical ecological observation by `agent_0`,
then finalized that agent's physiological death and physical exit. The first
defect required every retained observation author to remain active at
checkpoint time. The earlier correction replaced that rule with exact
historical registration, observation and death ordering and coordinated
causal retention.

The final data-consistency validation identified a separate issue. An
ecological row and its `ecologicalObservationRecorded` event were stored in the
same civilization checkpoint. A coherent mutation test could update both,
then recompute the causal, checkpoint, storage and manifest digests. Those
digests proved internal consistency, but not that the resulting physical
content came from the World scan.

The final distinction is therefore:

```text
causal consistency
!=
independent physical authenticity
```

The physical content now requires an authority outside the civilization
checkpoint.

## 3. Independent World-side receipt authority

`PebbleCore.SaveDB` now owns an opaque `world_receipts` table keyed by World,
receipt kind and receipt ID. Pebble writes typed, immutable receipts into this
World persistence. PebbleAgents receives only read-only evidence projections;
it does not import PebbleCore and does not own a second physical or ecological
engine.

For a real scan, Pebble persists a bounded
`PebbleEcologicalObservationReceipt` containing:

```text
receipt and operation identity
observer identity
World ID and sqlite World storage identity
dimension and dimension key
physical World tick and civilization simulation tick
origin
the normalized physical observation
result and World-read counts
physical-sensor provenance flag
canonical receipt digest
```

The receipt bytes are not encoded in `AgentSessionDurableState`, the causal
ledger, the checkpoint manifest or Observer. They remain in World persistence
and are loaded independently for cross-store reconciliation.

The normal publication chain is:

```text
physical World scan
-> independent World-side receipt persisted by Pebble
-> causal event containing the receipt identity and observation digest
-> ecological row containing the same receipt identity
```

The causal event establishes civilization ordering. The independent receipt
establishes the exact physical content.

## 4. Schema 30 and cross-store reconciliation

Checkpoint schema 30 is required whenever retained ecological rows or
agricultural plots exist. Every retained ecological row has exactly one valid
physical receipt reference. Before save and before load publication, Pebble
loads the required receipts from World persistence and requires exact equality
of:

```text
observer
World and storage identity
dimension and context
physical and simulation ticks
origin
complete normalized observation
result and read counts
observation digest
receipt identity and digest
causal operation and payload
```

The checkpoint is never published when a receipt is missing, duplicated,
invalid or belongs to another World. A coherent mutation of the row and causal
event cannot change the separately persisted receipt, so cross-store
reconciliation refuses the candidate semantically.

Compatibility is deliberately fail closed:

```text
schema 30 + retained observation
-> independent receipt mandatory

schema 29 + retained observation
-> refused because the independent proof does not exist

schema 29 + no retained observation or plot
-> remains readable under its other contracts
```

Observer schema 7 remains unchanged and read-only.

## 5. Historical observer and causal ordering

One canonical validator is used by candidate publication and checkpoint
durable-state validation. It classifies a row as:

```text
activeAtObservation
deceasedAfterObservationRetained
```

An active observer requires matching active session and population records,
registration no later than the observation and no contradictory mortality
authority. A deceased observer requires the exact retained death record. A
historical-person ID or compacted death summary alone never authorizes a
retained personal observation.

The exact retained ordering is:

```text
registration or birth event
< ecologicalObservationRecorded event
< agentDeathFinalized event, when the observer later dies
```

Same-tick observation and death require strict causal sequence. A sequence in
the dropped prefix is not an authority. Each retained row keeps its exact
observation event, direct cause, registration or birth authority and, for a
deceased observer, exact death authority.

A dead observer's row is historical evidence only. It does not grant current
perception, knowledge, action, agriculture instruction or agency to the dead
person or any heir.

## 6. Coordinated retention

The row, required causal authorities and World receipt are bounded together.
Before causal pressure would remove a required event, the aggregate candidate
evicts the dependent ecological row and increments
`evictionCounts.observations` exactly. Only then may the event leave. The
receipt remains while either the row, its causal event or a saved checkpoint
references it; once all such references are gone, Pebble removes it from World
persistence.

The order is:

```text
row eviction
-> lifetime total unchanged and eviction counter updated
-> causal event released
-> independent World-side receipt released
```

Mortality compaction uses the same doctrine. Personal observations remain
while the full death record is retained. Before that record becomes a compact
summary, dependent rows are evicted atomically. Runtime cannot publish:

```text
retained row + missing receipt
retained row + missing exact causal authority
retained deceased-observer row + compacted-summary-only authority
duplicate receipt identity
```

World receipt capacity is explicit and deterministic: 73,728 ecological
receipts and 18,432 agricultural action receipts per World. Capacity failure
refuses the candidate before any civilization publication.

## 7. Atomicity and rollback

Receipt insertion/removal is tracked by a Pebble transaction until the
civilization candidate and replay candidate both validate. Failures after
receipt creation, causal append, row creation, candidate eviction, receipt
counter update or cross-domain validation restore the prior receipt bytes and
leave the published session unchanged.

The verified invariant is:

```text
physical scan + World receipt + causal event + ecological row
-> all published
or
-> none published
```

Rollback tests compare durable session bytes, ecological counters, causal
events, causal dropped count and rolling digest. Duplicate and full-capacity
receipt paths leave no partial receipt. Receipt cleanup also protects all
retained on-disk checkpoints for the same World.

## 8. Agriculture binding

Agricultural plot foundation and renewal records reference the exact source
ecological receipt in addition to their causal source. Cross-store validation
re-derives the source observation from the World-side receipt and checks the
planner, source event, crop, cells, storage and renewal evidence.

Pebble also persists the already-authoritative till, plant, maturity, harvest,
transfer and renewal action outcomes as bounded World-side agricultural action
receipts. Retained action rows must equal those receipts exactly. Planting or
harvest receipt substitution, material-delta changes and source-observation
receipt substitution fail cross-store reconciliation.

This adds no second agriculture journal or engine. Pebble's existing physical
executors still perform and verify all World and material mutations; the new
store persists their receipts outside the civilization checkpoint.

## 9. Coherent mutation tests

The focused fixtures recompute every recalculable bundle field: observation,
causal event and rolling digests, ecological and agricultural durable digests,
checkpoint semantic digest, storage digest and manifest integrity digest. The
unchanged independent World-side receipt rejects:

- combined physical-row and causal-event changes with dropped event count
  equal to zero;
- the same combined changes with a nonzero dropped prefix;
- biome, origin, soil/crop content or physical World tick changes;
- World context or dimension changes;
- receipt substitution, absence, duplication or invalid digest;
- receipt evidence from another World;
- registration, death, actor, subject, tick, kind, origin or payload mismatch;
- agricultural source-observation or physical-action receipt substitution.

These are data-consistency refusals, not leftover checksum failures. Exact
receipt evidence accepts active and deceased historical observers and remains
byte-identical across repeated save/load.

The low-capacity campaign proves that only the affected row is removed before
its event, unrelated observers remain unchanged, counters are exact, the event
then becomes evictable, and the receipt is finally released. Injected failures
at each candidate boundary restore the complete prior state.

## 10. Fresh two-process product campaign

The reproducible runner is:

```text
scripts/verify-pebblelab-gate-d-ecological-observer-fix.sh
```

Its final fresh run used:

```text
World: wmsbu8ijg5vu1
storage: sqlite-world:wmsbu8ijg5vu1
session: live-46-14-66--21
observer: agent_0
observation sequence: 34
observation tick: 9
observation event: live-46-14-66--21/event-00000000000000000231
receipt: eco-c504ba4efee1d7232a19a9cb8e22bdd750bb6dde
observation digest: 7bcbc4ab8f949942
receipt digest: 59d6a5f8befae53640900a3552431d22aca6546d175fd11ea12d8d0ec42e8fc1
death: death-agent_0-t24-3cfeb0b74c40c179
death event: live-46-14-66--21/event-00000000000000000554
estate: estate-18506feb632c6b93
checkpoint schema: 30
```

Process 1 created the receipt from a real World scan, produced normal child
`agent_3`, verified supervision and interruption accounting, finalized
`agent_0` through mortality, preserved its physical asset in the open estate
and saved schema 30. Process 2 restored the same World and session, validated
the same independent receipt before publication, kept `agent_0` dead without
recreating its probe, passed the Blocker 01 position reconciliation, continued
normally, settled the asset physically and completed repeated save/load.

Final accounting:

```text
physical quantity: 1 / 1 / 1 / 1
active dead-observer count: 0
dead-observer probe count: 0
position mismatch after load: 0
duplication count: 0
Observer mutation count: 0
runtime errors: 0
cleanup: exact
```

Four 3024×1898 rendered captures were opened individually at native
resolution. They show G1 care before death, historical observation with an
open estate, the same state after process restart, and the settled estate.

## 11. Validation

The final focused runs on the exact product diff reported:

| Suite | Passed | Failed |
| --- | ---: | ---: |
| ecological observation | 68 | 0 |
| agriculture | 48 | 0 |
| renewable subsistence | 19 | 0 |
| mortality | 93 | 0 |
| estates/inheritance/succession | 84 | 0 |
| checkpoint/replay | 49 | 0 |
| persistence/reconciliation | 18 | 0 |
| Material Rights | 21 | 0 |
| Observer | 20 | 0 |
| **Total** | **420** | **0** |

Schema-30 regressions additionally passed `livestock` 40/0, wild subsistence
47/0 and work-demand-refresh 26/0. The canonical repository gate reported:

```text
3719 passed, 0 failed
35/35 steps
exit 0
```

The final Blocker 01 regression reported three position mismatches before
load, zero afterward, zero probe or physical-item duplication, zero Observer
mutation, zero runtime error and exact cleanup.

## 12. Limits

- This correction proves only Gate D Blocker 02. It is not an independent Gate
  D evaluation.
- Legacy schema 29 checkpoints with retained observations or plots lack the
  independent receipt reference and fail closed.
- Personal observations are not inherited, shared knowledge or current
  instructions.
- Receipt retention is bounded. When required evidence cannot be retained,
  the candidate operation is refused or the dependent row is evicted before
  proof loss.
- The World receipt store is physical evidence, not inventory, cognition,
  social state or a second ecology/agriculture engine.
- Gate D's full generational contract still requires a new independent
  Evaluation 03 from the published corrected product.

## 13. Program status

```text
Gate D Blocker 01: FIXED AND PUBLISHED
Gate D Blocker 02: FIXED — LOCAL REVIEW CANDIDATE
Evaluation 02 former blocker: CLEARED ON CORRECTED PRODUCT
V4-GATE-D-v1: NOT EVALUATED
next authorized action after publication: NEW INDEPENDENT V4-GATE-D-v1 EVALUATION 03
CIV-34: NOT STARTED
```

Publication still requires senior review, a manual push and remote
verification. Push attempted by Codex: NO.
