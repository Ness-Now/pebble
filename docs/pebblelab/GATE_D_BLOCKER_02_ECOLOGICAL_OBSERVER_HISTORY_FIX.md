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

When retained, the ecological causal event must have the exact simulation,
kind, transition origin, actor, subject, tick, context keys, result count,
read count, truncation state and observation digest. An honestly evicted event
is accepted only under the existing bounded-ledger prefix policy and still
requires independent active-population or retained-death authority.

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

The mandatory audit found one exact analogue: a retained renewable-agriculture
plot can have a planner who later dies. Agriculture validation now proves such
a planner or retained action actor through active population or the exact full
death record, with the same registration/action/death ordering. A retained
agriculture record pins that full death authority; compacted-summary-only
evidence fails closed. No broader historical-actor policy was changed.

## 7. Atomicity

Ecological eviction, mortality compaction, compacted-summary creation and
estate/death retention operate on the candidate aggregate. Bounds and
historical agriculture dependencies are checked before publication. The
candidate ecology, mortality, estate and causal authorities are validated
together before the aggregate is assigned.

Injected capacity and late-candidate failures prove that the published
session retains the original observations, death record, exact eviction
counter, estate and causal ledger. No physical World mutation is introduced by
this history-validation correction.

## 8. Schema compatibility

No schema increment is required. Schema 29 already persists the ecological
record, population registration binding, retained mortality record, causal
IDs and integrity digests needed for exact validation.

Schema 29 accepts active observers and observers who died after their
observation while the exact death record remains retained. It refuses unknown
observers, registration after observation, observation after death, invalid
causal binding and compacted-summary-only authority. Older schemas retain
their previous compatibility only where exact proof remains possible;
otherwise restoration fails closed.

## 9. Fully re-signed corruptions

The adversarial fixtures recompute the modified observation digest,
ecological state, causal event and rolling digest, mortality binding where
applicable, checkpoint semantic digest, storage digest and manifest integrity
digest. Semantic validation rejects:

- an unknown observer;
- an active replacement whose causal actor does not match;
- a child born after the observation;
- an observer registered after the observation;
- an observer already dead before the observation;
- actor, subject, origin, tick or payload-digest corruption;
- contradictory registration or death authority;
- a compacted observer reintroduced without a retained full death record.

These refusals do not rely on leaving an old checksum unrepaired.

## 10. Two-process product campaign

The reproducible runner is:

```text
scripts/verify-pebblelab-gate-d-ecological-observer-fix.sh
```

Its final rendered campaign used World `wmsbewsw4i1sb` and session
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
digest before/after restart: cf59861f7d72703d / cf59861f7d72703d
ecological state digest before/after: 1c86d0d3175b784a / 1c86d0d3175b784a
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
| ecological observation | 44 | 0 |
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
| agriculture | 32 | 0 |
| renewable subsistence | 19 | 0 |
| Material Rights | 21 | 0 |
| Observer | 20 | 0 |
| **Total** | **771** | **0** |

The canonical repository gate reported `3679 passed, 0 failed` and all
`35/35` steps. The published Blocker 01 runner also passed on the corrected
product with three mismatches before load, zero after load, zero probe or item
duplication, zero Observer mutation, zero runtime error and exact cleanup.

## 12. Limits

- This correction proves only the historical ecological-observer blocker. It
  is not an independent Gate D evaluation.
- A compacted death summary does not authorize a retained personal ecological
  observation in schema 29; coordinated compaction evicts that row first.
- Agriculture records that still need a dead historical actor pin the full
  death record instead of adding a general actor-history authority.
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
