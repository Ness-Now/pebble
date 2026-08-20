# Gate E Blocker 02 — Evolved Current Identity vs Immutable Production Provenance

## Status

`V4-GATE-E-v1 Blocker 02: FIXED AND PUBLISHED`

This record publishes the senior-review-approved product correction. It does
not acquire Gate E, revise Evaluation 02, begin Evaluation 03, or begin
CIV-38. Remote publication verification is not claimed by this containing
commit.

- Gate E Evaluation 01: `FAIL — HISTORICAL IMMUTABLE EVIDENCE`
- Gate E Blocker 01: `FIXED AND PUBLISHED`
- Gate E Evaluation 02: `FAIL — HISTORICAL IMMUTABLE EVIDENCE`
- Gate E Blocker 02: `FIXED AND PUBLISHED`
- Gate E: `PLANNED — NOT ACQUIRED`
- Evaluation 03: `NOT_STARTED`
- CIV-38: `OPTIONAL — NOT STARTED`

## Publication record

```text
product correction commit: a67665e87774a4af8fcc7930e05c8747da1f83fc
reviewed candidate HEAD: b8dbeef60865a4fd452ca5abaac4a005ded2e592
review bundle SHA-256: 68ab04428582cbbe96c0e8bf046f45c22818a6dd9018ad6f808c87b9aea30c31
internal checksums: 59/59 PASS
senior review: APPROVED
publication verified: NO
```

## Evaluation 02 identity

- evaluated baseline:
  `9ede5d73229c3c9284d163ed17cc76bcf92ebe0e`
- evaluation evidence HEAD:
  `2f95826f474c9f2a366f4b06df90a8643beb7a98`
- evaluation verdict: `FAIL — PRODUCT CORRECTION REQUIRED`
- evaluation bundle SHA-256:
  `4e10d129927af5c8443f9f8e26fec0d276f797cf82126b93792f32c26c646d57`

Evaluation 02 remains immutable historical failure evidence. Its evidence
commits are not ancestors of this correction branch.

## Historical failure

Evaluation 02 normally produced and transferred one durable physical tool:

- asset: `gate-e-e02-00-produced-pickaxe`
- immutable origin: `stone_pickaxe`, damage `0`
- current legitimate identity after recipient use: `stone_pickaxe`, damage `1`
- `AgentMaterialAssetReference.permitsCurrentIdentity(current)`: `true`
- origin/current exact equality: `false`

The shared production-provenance matcher nevertheless compared the immutable
origin identity to the exact current identity. Ordinary CIV-35 discovery then
rejected the valid evolved tool with:

```text
barter(invalid barter opportunity gate-e-e02-00-produced-pickaxe)
```

No physical mutation survived that failure.

## Authority model

The correction preserves three independent concepts:

1. Immutable production origin records that durable asset A originated through
   production operation P as identity I0.
2. Current durable-asset continuity determines whether current identity I1 is
   representable by A under the existing Material Rights contract.
3. Current exact physical authority requires the current holder, I1, quantity,
   and custody fingerprint for an economic mutation.

`I0 != I1` is valid only when the registered durable asset already permits I1.
Historical production provenance never substitutes for current physical
authority.

## Product correction

The approved product correction and its focused/live proof infrastructure are
committed at:

```text
a67665e87774a4af8fcc7930e05c8747da1f83fc
```

`materialProductionProvenanceMatches` continues to require:

- the exact bound operation IDs;
- represented quantity equal to the current leg quantity;
- registered durable-asset quantity equal to the current leg quantity; and
- a valid immutable production-origin proof for the registered asset.

Its current-identity comparison now delegates to the canonical continuity
primitive:

```swift
record.asset.permitsCurrentIdentity(material.identity)
```

The correction does not rewrite the registered origin identity, loosen item
keys, infer current authority from provenance, or remove Blocker 01's exact
asset-to-production binding.

No durable shape changed. Checkpoint/replay remains schema `34`; Observer
remains schema `11`.

## Focused product regression

The dedicated `gate-e-blocker-02` smoke suite completed `33/33` assertions.
It proves:

- origin damage `0`, current damage `1`, and canonical continuity `true`;
- one unchanged bound operation;
- ordinary barter discovery and settlement with the evolved tool;
- damage `1 -> 2` while the origin remains damage `0`;
- stale damage-1 current authority fails after damage 2 and exact damage-2
  authority succeeds;
- different item key, wrong quantity, wrong holder, stale fingerprint, forged
  production operation, inconsistent origin, another asset's provenance, and
  disallowed continuity all fail closed;
- CIV-36 discovery and physical fulfillment accept an evolved produced leg
  only with exact current authority;
- CIV-37 deposits the exact evolved asset into real market custody and resumes
  normal listing action after schema-34 restore;
- historical agent observation cannot spend market-held matter;
- Observer 11 remains read-only; and
- compacted production history leaves the bounded immutable origin proof valid
  across evolution and restart, while corruption still fails closed.

## Fresh two-process live proof

The disposable live proof used double gates:

```text
PEBBLELAB_GATE_E_BLOCKER_02=1
PEBBLELAB_DISPOSABLE_WORLD_PROOF=1
```

These routes are inert outside the disposable proof boundary. Bootstrap
creates only agents, raw inputs, a normal crafting workstation, and two real
stone targets. Normal production and autonomous economic cognition decide the
decisive outcomes.

### Identity

- World: `PebbleLab-Disposable-Gate-E-Blocker-02-46`
- seed: `46`
- World ID: `wmt1bfbg47mwn`
- simulation: `live-46-14-68--18`
- durable asset: `barter-asset:agent_0:stone-pickaxe`
- producer: `agent_0`
- production operation:
  `barter-production:barter:agent_0:produce-pickaxe`
- immutable origin identity:
  `stone_pickaxe`, damage `0`, enchantments `[]`, canonical data `{}`
- immutable origin digest: `e91679bbdf3ee8a6`
- bound production operation count: `1`
- origin rewrite count: `0`

### Process 1

Normal CIV-34 production made the damage-0 pickaxe. Normal autonomous CIV-35
barter transferred it from `agent_0` to `agent_1`. The recipient used that
same physical tool to break real stone; the canonical drop was acquired into
physical custody and the tool became damage `1`.

Checkpoint `gate-e-blocker-02-damage1-v34` persisted:

- checkpoint ID: `checkpoint-d0d2d13d367b-t2-133c9ae8e3316f44`
- semantic digest:
  `133c9ae8e3316f44fb9eebcb0c33e46c4e6a4ea837cebc9cc0d45c03593748ad`
- schema: `34`
- holder: `agent_1`
- current identity: `stone_pickaxe`, damage `1`, quantity `1`
- origin identity: damage `0`, unchanged
- production-use receipt:
  `barter-use:barter-production:barter:agent_0:produce-pickaxe:use1`

Process 1 terminated cleanly and handed off exact protected custody.

### Process 2

A fresh process restored the damage-1 checkpoint with:

- all three probes reconciled;
- three physical custody stacks and quantity four restored;
- zero custody duplicates; and
- the physical boundary acquired before session publication.

The restored tool retained the same asset ID, origin operation and origin
damage `0`, while its exact current holder was `agent_1` and current damage was
`1`. A second normal physical use changed damage `1 -> 2`; the second canonical
stone drop entered custody and the immutable origin remained unchanged.

Normal autonomous cognition then discovered, offered, independently accepted,
and physically settled a reverse barter using the damage-2 tool. Final holder,
custodian and recognized owner were `agent_0`.

Checkpoint `gate-e-blocker-02-damage2-v34` persisted:

- checkpoint ID: `checkpoint-d0d2d13d367b-t4-24fcf4a3ec58633b`
- semantic digest:
  `24fcf4a3ec58633b7906e2561e4fb9edba0f7785788d8e1acf286cdfd995af46`
- schema: `34`
- holder: `agent_0`
- current identity: `stone_pickaxe`, damage `2`, quantity `1`
- origin identity: damage `0`, unchanged
- production-use receipt:
  `barter-use:barter-production:barter:agent_0:produce-pickaxe:use2`

The proof inspected eight captures. Both processes reported zero expected and
zero unexpected runtime errors. Cleanup restored the disposable fixture cells
exactly and removed all three probes per process. The isolated World and raw
checkpoint evidence were retained for senior review.

## Current-authority adversarial result

After each evolution, the historical origin identity was presented as though
it were current. Material Rights refused it. The exact current observation was
independently allowed. The focused suite additionally proved that a stale
damage-1 observation fails after damage 2 and that reacquired exact damage-2
authority succeeds.

Production provenance therefore remains historically valid without becoming
physical disposition authority.

## Conservation and duplicate bounds

The final live diagnostics were:

```text
physicalLoss=0
physicalDuplication=0
syntheticMaterial=0
duplicateProductionReceipts=0
duplicateBarterReceipts=0
duplicateReservations=0
observerMutationCount=0
currencyAuthority=0
```

Tool durability is identity evolution, not material duplication. Each broken
stone's canonical output was acquired through the normal custody gateway.

## Blocker 01 non-regression

The focused Blocker 01 suite completed `27/27`. Its dedicated two-process live
proof also passed:

- same producer and three matching bread x1 records;
- exact promised asset quantity `1`;
- bound provenance only P3;
- false matching attribution `0`;
- normal contract discovery `PASS`;
- displacement refusal, same-asset return, and one fulfillment; and
- zero duplicate fulfillment, physical loss, duplication, or synthetic
  material.

Gate E Blocker 01 remains fixed and published.

## Regression results

Focused owning selectors:

| Selector | Result |
| --- | ---: |
| production | 36/36 |
| barter | 54/54 |
| contracts | 30/30 |
| markets | 31/31 |
| material-rights | 23/23 |
| candidate-physical-atomicity | 3/3 |
| checkpoint-replay | 49/49 |
| persistence-reconciliation | 19/19 |
| observer | 20/20 |
| autonomous-civilization | 36/36 |

The owning selectors total `301/301` assertions. The canonical repository gate
completed `35/35` steps and `3983/3983` assertions with zero failures. Goldens
were read-only and were not regenerated.

## Non-claims

- This correction does not acquire Gate E.
- It does not turn Evaluation 02 into a pass.
- It does not start Evaluation 03 or CIV-38.
- It does not make production provenance a custody or disposition authority.
- It does not define continuity after tool destruction or item-key replacement.
- It does not change checkpoint/replay or Observer schema.
- This containing commit does not claim manual push or remote publication
  verification.

After manual publication and independent remote SHA verification, the next
authorized action is
`NEW-INDEPENDENT-V4-GATE-E-v1-EVALUATION-03`. Evaluation 03 remains completely
unstarted by this publication record.
