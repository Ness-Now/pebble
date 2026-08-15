# V4-GATE-E-v1 Blocker 01 — Exact Produced-Asset Provenance

Status: **IMPLEMENTED_LOCAL_REVIEW_CANDIDATE**

This record describes a local product correction. It does not acquire Gate E,
publish the correction, revise Evaluation 01, begin Evaluation 02, or begin
CIV-38.

## Immutable Evaluation 01 result

```text
evaluated baseline: 5bc9d3088c2550fb042fe065235cb0154a226ff0
evaluation evidence HEAD: e75ab82981169baf1cdc67d9454e6d569e989167
evaluation verdict: FAIL — PRODUCT CORRECTION REQUIRED
evaluation review bundle SHA-256: 9db1a5b478f1ed0ca9efcac5612efc29928b61143a92e198123285920444fc93
```

Evaluation 01 remains historical immutable FAIL evidence. The discovered
composition had three distinct `bread x1` production operations for agent_1
and one exact `bread x1` promised-performance asset. Product discovery
attributed all three matching operations to that one asset. The fail-closed
contract validator received production quantity 3 for a leg of quantity 1 and
correctly rejected the opportunity.

## Root cause

Published CIV-35 and CIV-36 reconstructed provenance by searching production
history for every record with the current holder and the same output snapshot.
That relationship was not causal: holder, material and quantity do not identify
which physical asset came from which production. It also confused historical
origin with current custody and could not remain sound when bounded production
history compacted.

The existing exact-quantity validator is unchanged. No record is selected by
age, array position or approximate match, and no excess quantity is ignored.

## Reuse-first audit

The canonical owners were audited before correction:

- `AgentProductionRecord` already held operation identity, producer, output,
  physical receipt, location, completion tick and causal event, but not the
  source custody fingerprints required to bind a rights asset exactly.
- CIV-26 Material Rights already supplied the durable `AgentMaterialAssetID`,
  exact registered quantity and identity, current holder observation, claims,
  ownership, permissions, physical transfer receipts and checkpoint state.
- CIV-35 barter legs and CIV-36 contract legs already carried
  `productionOperationIDs`, but their product adapters populated them with the
  non-causal actor/output-history search.
- Production retention was already bounded by `maximumRecords` (256 by
  default). A rights asset can outlive its retained production record.
- Produced-tool downstream use depended on retained production records and
  therefore needed the same durable origin seam after a normal transfer or
  compaction.

No pre-existing durable exact `AgentMaterialAssetID` to production-operation
relationship existed. The correction therefore adds the smallest coherent
seam to the existing Material Rights authority rather than adding a second
asset, inventory, production or contract system.

## Authority model

Four concepts remain separate:

1. PebbleCore and current Pebble observation are physical truth and current
   mutation authority.
2. A Material Rights record identifies one exact stack-scoped durable asset and
   its last verified holder observation.
3. `AgentMaterialProductionProvenance` is immutable historical origin evidence
   attached to that exact rights asset.
4. Barter and contract records cite the asset-bound operation IDs but still
   require current exact holder, identity, quantity and
   `currentCustodyFingerprint` before a physical mutation.

Holder and owner changes do not rewrite the producer. Historical origin cannot
authorize movement of missing or displaced matter.

## Exact binding

`bindProductionProvenance` can bind a previously unbound rights asset only from
live retained production records. It requires:

- nonempty, unique, deterministically sorted operation IDs, bounded by the
  causal-event cause limit;
- every named operation to exist and no operation to be bound to another asset;
- exact producer/source, output identity, physical receipt and final custody
  fingerprint agreement with the registered asset;
- exact represented quantity equality;
- for legitimate multi-operation assets, a continuous before/after custody
  fingerprint chain in causal order.

The binding copies a minimal `AgentMaterialProductionOriginProof` per origin:
operation ID, producer, exact output, physical receipt, source, before/after
fingerprints, completion tick, causal event and a deterministic proof digest.
The proof is then validated as durable Material Rights state.

For the Evaluation 01 collision, the selected P3 rights asset has exactly:

```text
matching same-actor bread x1 records: 3
asset quantity: 1
bound origins: contract-bootstrap-production:gate-e-blocker-01:agent_1:bread:p3
represented provenance quantity: 1
other matching records: 2
false matching records attributed: 0
```

## Fail-closed cases

Focused regression proves refusal for:

- same actor, material and quantity attached to a different physical asset;
- a different actor with the same material;
- a production record whose output no longer establishes current matter;
- a forged operation ID;
- output identity mismatch;
- output quantity mismatch;
- an ambiguous multi-operation custody chain; and
- claimed provenance whose retained causal record is missing at binding time.

An ordinary rights asset with no provenance remains usable when the barter or
contract leg makes no provenance claim. Provenance never reconstructs absent
matter.

## Retention and persistence policy

Production history remains bounded; it is not retained indefinitely for an
asset. Once an exact binding has been validated while its source records are
live, the immutable minimal origin proof travels with the durable Material
Rights record. If the full production record is later compacted, the proof
continues to validate from its digest, causal identity, exact output and
custody chain. If a retained record still exists, every copied field must match
it exactly. Divergence, corruption or a dangling causal reference fails closed.

No checkpoint schema bump is required. `productionProvenance` is an optional
field on the existing Codable Material Rights record in the existing
schema-33 CIV-36 checkpoint. Older schema-33 state decodes the absent optional
field as no provenance claim; newly bound provenance round-trips exactly.
Restore performs no World operation, does not reassign provenance and does not
duplicate it. Observer remains read-only at schema 10.

## Integrations preserved

- CIV-36 normal discovery and fulfillment read only the exact promised asset's
  bound IDs. The exact quantity validator and Senior Review Correction 01
  publication/rollback/current-fingerprint defenses remain intact.
- CIV-35 normal barter discovery uses the exact asset-bound IDs. Multiple
  identical same-actor outputs do not cross-attribute.
- A transferred produced tool retains its original producer proof. Legitimate
  downstream use recognizes that proof after ownership transfer and production
  compaction, while current tool custody and durability remain physical truth.

## Validation

Focused Blocker 01 smoke:

```text
27 passed, 0 failed
```

Owning regressions:

```text
production: 36 passed, 0 failed
barter: 54 passed, 0 failed
contracts: 30 passed, 0 failed
material-rights: 23 passed, 0 failed
checkpoint-replay: 49 passed, 0 failed
persistence-reconciliation: 19 passed, 0 failed
candidate-physical-atomicity: 3 passed, 0 failed
observer: 20 passed, 0 failed
autonomous-civilization: 36 passed, 0 failed
total: 270 passed, 0 failed
```

Final canonical repository gate after all product changes:

```text
35/35 verification steps
3950 passed, 0 failed
goldens: NOT REGENERATED
```

## Targeted two-process product proof

The disposable blocker proof uses the corrected product, not the Evaluation 01
runtime harness. Process 1 performs three normal distinct bread productions,
registers three real exact rights assets, creates a normal one-bread CIV-36
obligation, transfers real consideration, opens debt and saves schema-33 state.
Process 2 restores fresh, observes all three production records, discovers only
P3 for the promised asset, and exercises the Evaluation 01 current-authority
adversarial sequence.

Moving the exact P3 asset elsewhere makes fulfillment refuse and leaves debt
open with no synthetic replacement. Legitimately returning that same asset
restores current authority; normal discovery and physical fulfillment then
succeed exactly once. The final proof reports:

```text
fresh processes: 2
matching production records: 3
promised asset quantity: 1
selected provenance operation count: 1
selected provenance quantity: 1
false matching operations attributed: 0
duplicate fulfillment: 0
physicalLoss: 0
physicalDuplication: 0
syntheticMaterial: 0
observerMutationCount: 0
captures inspected: 9
unexpected runtime errors: 0
checkpoint schema: 33
Observer schema: 10
```

## Status and non-claims

```text
V4-GATE-E-v1 Blocker 01: IMPLEMENTED_LOCAL_REVIEW_CANDIDATE
Gate E Evaluation 01: FAIL — HISTORICAL IMMUTABLE EVIDENCE
Gate E: PLANNED — NOT ACQUIRED
Evaluation 02: NOT_STARTED
CIV-38: OPTIONAL — NOT STARTED
push: NOT_ATTEMPTED
```

This candidate is not published or senior-review approved. A completely fresh
independent Evaluation 02 is required only after review, manual publication and
remote verification of the blocker correction.
