# Gate D Blocker 02 — Historical ecological observer validation

## 1. Affected published baseline

This targeted product correction starts from the published product baseline:

```text
6d114abb98aee652e44fe9a81c3bab47b72ff698
```

That baseline includes checkpoint schema 29, Observer schema 7 and the
published Gate D Blocker 01 position-restoration correction. This work does
not evaluate or acquire `V4-GATE-D-v1`, and it does not start `CIV-34`.

## 2. Preserved Evaluation 02 FAIL

Independent evaluation commit
`d40ca4f8215ff14d904a1fb84aedb7ebd9185082` on historical local branch
`codex/gate-d-evaluation-02` records:

```text
GATE D FAIL — PRODUCT CORRECTION REQUIRED
```

Its report and harness remain unchanged. Evaluation 01 commit
`9232b65a8a32b2d054fe2e5c7ea80e0dd990d378` also remains immutable. The
Evaluation 02 campaign recorded a normal ecological observation by `agent_0`,
then finalized that agent's physiological death and physical exit. Schema-29
checkpoint creation subsequently failed with `checkpoint bound exceeded:
ecological observation`.

## 3. Reproduction and root cause

The old checkpoint validator required every retained observation's
`observerID` to remain in the active session-agent array. Mortality correctly
removes a dead person from active population and lifecycle while retaining the
bounded death record, estate and historical observation. The validator
therefore confused two different statements:

```text
active at checkpoint time
historically alive and authorized at observation time
```

The observation itself was valid. Its author simply died before the save.
Deleting all observations at death would have hidden the defect and erased
legitimate bounded history, so the correction preserves them while the full
death authority remains retained.

## 4. Active observations and historical evidence

One canonical validator is used by candidate-session publication and
checkpoint durable-state validation. It classifies each row as either:

```text
activeAtObservation
deceasedAfterObservationRetained
```

An active observer requires matching active session and population records,
registration no later than the observation and no contradictory mortality
authority. A deceased observer requires the exact retained full death record.
The validator never treats a historical-person ID or a compacted death summary
alone as sufficient authority for a retained schema-29 observation.

Current affordance queries remain active-agent-only. A dead observer's retained
row is historical evidence: it does not grant perception, action, knowledge,
agricultural instruction or agency to the dead person or an heir. Observer may
display the record read-only without deriving new product truth.

## 5. Registration, death and causal ordering

For an active observer, the population registration tick is at or before the
observation tick and the registration event precedes the observation event.
For a deceased observer, the exact order is:

```text
registration event sequence
< ecologicalObservationRecorded event sequence
< agentDeathFinalized event sequence
```

The observation tick must be no later than the death tick. Same-tick
observation and death are accepted only when causal sequence proves that the
observation preceded finalization.

Every retained row requires its exact `ecologicalObservationRecorded` event,
its exact direct cause and the exact applicable registration or birth event.
A deceased observer additionally requires the exact retained
`agentDeathFinalized` event. Those events must retain the expected simulation,
kind, transition origin, actor, subject, tick, context keys, result count,
read count, truncation state and observation digest. A sequence in the causal
ledger's dropped prefix is never accepted as a substitute for any of these
authorities.

All causal appends use one aggregate boundary. Before an append could evict a
required event, that boundary removes the dependent ecological row from the
candidate state, increments `evictionCounts.observations` exactly and then
allows normal causal compaction. If the last-observation or initialization
boundary is itself about to leave, the candidate first records one exact
bounded ecological retention boundary and refreshes both references. A later
observation therefore never cites an event whose meaning is no longer
available.

## 6. Death-record and compaction policy

Schema 29 uses coordinated retention without adding another historical
authority:

```text
death finalized and full death record retained
-> personal observations remain retained

full death record selected for compaction
-> all retained personal observations by that agent are evicted in the same
   candidate transaction
-> ecological observation eviction count increases exactly
-> full death record may then become a compacted death summary
```

Several rows from the same observer are removed together; rows from other
observers remain unchanged. `totalObservationCount` remains the lifetime
count. A retained observation whose only author evidence is a compacted death
summary is invalid in schema 29, and honest runtime compaction cannot publish
that state.

The mandatory audit found one exact analogue in renewable agriculture. The
immutable operational foundation of every retained plot (planner,
registration, ecological source, plot/crop/storage identities and canonical
cells) is covered by a canonical digest. Before an original source event can
leave, the central append boundary emits one exact retained
`agricultureInitialized` retention event carrying that digest and atomically
refreshes the operational plot references. This permits bounded long-running
production without trusting a dropped prefix.

Historical agriculture actions, skill events, source observations, managed
surplus, renewal records and physical receipts are not summarized by that
boundary. Their exact causal events remain pinned; an append that would evict
one is refused atomically. Validators prove actor, tick, cell, material deltas
and payload. A dropped-prefix sequence and compacted-summary-only actor
evidence both fail closed. No broader historical-actor policy was changed.

## 7. Atomicity

Ecological eviction, causal compaction, mortality compaction,
compacted-summary creation and estate/death retention operate on the candidate
aggregate. Bounds and historical agriculture dependencies are checked before
publication. The candidate ecology, agriculture, mortality, estate and causal
authorities are validated together before the aggregate is assigned.

Injected failures after row removal, counter update, causal append and causal
compaction prove byte-exact rollback of the observations, eviction counter,
causal events, dropped count, rolling digest, mortality, estate and other
aggregate authorities. No physical World mutation is introduced by this
history-validation correction.

## 8. Schema compatibility

No schema increment is required. Schema 29 already persists the ecological
record, population registration binding, retained mortality record and exact
causal events needed for validation. The correction changes coordinated
retention and validation, not the durable representation.

Schema 29 accepts active observers and observers who died after their
observation while the exact death record remains retained. It refuses unknown
observers, registration after observation, observation after death, invalid
causal binding, every retained row missing its exact causal event or direct
cause, arbitrary dropped-prefix registration/death IDs and
compacted-summary-only authority. Older schemas retain their previous
compatibility only where exact proof remains possible; otherwise restoration
fails closed.

## 9. Fully re-signed corruptions

The adversarial fixtures recompute the modified observation digest,
ecological state, causal event and rolling digest, agriculture foundation
boundary and digest where applicable, mortality binding where
applicable, checkpoint semantic digest, storage digest and manifest integrity
digest. Semantic validation rejects:

- an unknown observer;
- an active replacement whose causal actor does not match;
- a child born after the observation;
- an observer registered after the observation;
- an observer already dead before the observation;
- actor, subject, origin, tick or payload-digest corruption;
- contradictory registration or death authority;
- physical content, context, tick or observer replacement after the original
  ecological event has left the ledger, even after every recalculable digest
  is repaired;
- arbitrary registration or death event IDs selected from the dropped causal
  prefix;
- a compacted observer reintroduced without a retained full death record.

The post-eviction fixtures first remove the legitimate row through causal
pressure, then reintroduce a fully re-signed corruption without restoring its
exact causal event. These refusals are semantic and do not rely on leaving an
old checksum unrepaired.

The low-capacity campaign proves the retention matrix directly: an exact row
and event restart successfully; pressure removes only rows whose required
event is projected to leave; the lifetime observation total is unchanged and
the eviction count increases by the exact removed-row count; an unaffected
observer remains byte-identical; the event may then leave; and any artificial
row reintroduction is rejected. Pressure against retained historical
agriculture actions or receipts instead refuses the append and preserves its
complete candidate state byte-for-byte.

## 10. Two-process product campaign

The reproducible runner is:

```text
scripts/verify-pebblelab-gate-d-ecological-observer-fix.sh
```

Its final rendered campaign used World `wmsbnosi0cki2` and session
`live-46-14-66--21`. Process 1 recorded normal observations, produced normal
child `agent_3`, verified one supervision tick and an interrupted tick with no
credit, finalized `agent_0` through mortality, preserved the physical asset in
estate `estate-18506feb632c6b93`, and saved schema 29. Process 2 restored the
same World and session, retained the same dead-observer observation and death
record without recreating a dead probe, passed the Blocker 01 position
reconciliation, advanced normally, settled the asset physically, and proved a
second save/load.

The decisive retained row was:

```text
observer: agent_0
sequence: 34
observation tick: 9
registration event: live-46-14-66--21/event-00000000000000000012
observation event: live-46-14-66--21/event-00000000000000000231
death event: live-46-14-66--21/event-00000000000000000554
death ID: death-agent_0-t24-3cfeb0b74c40c179
death tick: 24
classification: deceasedAfterObservationRetained
digest before/after restart: fae65b79ac2d596c / fae65b79ac2d596c
ecological state digest before/after: 517c97280ceef2ef / 517c97280ceef2ef
```

Final campaign accounting:

```text
physical quantity: 1 / 1 / 1 / 1
active agent_0 observer count: 0
dead agent_0 probe count: 0
position mismatch after load: 0
duplication count: 0
Observer mutation count: 0
runtime errors: 0
cleanup: exact
```

Four rendered captures were opened individually and inspected at native
resolution: live observation and G1 care; retained history with open estate;
the same history after process restart; and the settled estate with continued
family and renewable state. The images are evidence of the rendered World;
the precise historical ordering remains digest-bound textual evidence.

## 11. Focused and repository validation

The final focused runs on the exact product diff reported:

| Suite | Passed | Failed |
| --- | ---: | ---: |
| ecological observation | 55 | 0 |
| mortality | 93 | 0 |
| estates/inheritance/succession | 84 | 0 |
| checkpoint/replay | 49 | 0 |
| persistence/reconciliation | 18 | 0 |
| population/migration | 66 | 0 |
| lifecycle | 80 | 0 |
| genetics/development | 45 | 0 |
| childhood/guardianship | 62 | 0 |
| dependent care | 55 | 0 |
| unions/family/lineages/houses | 83 | 0 |
| agriculture | 44 | 0 |
| renewable subsistence | 19 | 0 |
| Material Rights | 21 | 0 |
| Observer | 20 | 0 |
| **Total** | **794** | **0** |

The supplemental 900-tick `work-demand-refresh` stress reported `26 passed, 0
failed`; the bounded ledger retained 64 events while dropping 8,751 and kept
the three work demands stable. The canonical repository gate reported `3702
passed, 0 failed` and all `35/35` steps. The published Blocker 01 runner also
passed on the corrected product with three mismatches before load, zero after
load, zero probe or item duplication, zero Observer mutation, zero runtime
error and exact cleanup.

## 12. Limits

- This correction proves only the historical ecological-observer blocker. It
  is not an independent Gate D evaluation.
- A compacted death summary does not authorize a retained personal ecological
  observation in schema 29; coordinated compaction evicts that row first.
- A retained ecological row cannot outlive its exact record event, direct
  cause, registration/birth authority or retained death event. Causal pressure
  evicts the row first; lifetime totals remain monotonic.
- Immutable agriculture plot foundations may move to an exact, digest-bound
  causal retention boundary before their source event leaves. Historical
  action, skill, renewal, surplus and physical-receipt evidence remains exact;
  causal-capacity exhaustion refuses the candidate append atomically rather
  than weakening or silently discarding it.
- Personal observations are not inherited, shared knowledge or current
  instructions.
- No new unbounded history, second mortality authority, physical engine,
  estate rule or Observer mutation path is added.
- Gate D's complete generational contract must still be evaluated from a
  published corrected product HEAD by a new independent Evaluation 03.

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
