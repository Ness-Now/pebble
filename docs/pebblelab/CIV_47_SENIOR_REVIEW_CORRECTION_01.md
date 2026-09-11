# CIV-47 — Senior Review Correction 01

## Immutable review history

```text
Canonical baseline: 70cb245e089987bc829ac138b0988eb3fc825d57
Original reviewed candidate: 27806ac721e8e3570cc31f9e8cac2a001de4d4ca
Original reviewed tree: 2f24e73e6f6ef40f34d017692a84fdf9a24ba6cf
Original reviewed ZIP SHA-256: b13cd2f4ca354f2f91e9fe5024b4fbf8d465122c4540fe8e8ae958791d6f6d53
Original verdict: CORRECTION REQUIRED
Original findings: P0 0 / P1 4
Correction 01 product/test commit: 45701f56169218b70f2e698dc0dea67bb1d027c0
Correction 01 senior-reviewed candidate: 874a844ba54b66210ac303912193038c9f4ee6e0
Correction 01 senior-reviewed tree: fec66e6423e594c568b700ced191fbafd87b5523
Correction 01 review ZIP: PebbleLab-CIV47-Correction01-LocalReview-874a844-FINAL.zip
Correction 01 review ZIP SHA-256: 23f084707c1ab3929ef37b02462229f15711dd8aa050f631a30df7e0888ca8a6
Correction 01 senior verdict: PASS — SENIOR REVIEW APPROVED
Correction 01 findings: P0 0 / P1 0
Correction 01 status: SENIOR REVIEW APPROVED / NOT PUBLISHED / NOT REMOTE VERIFIED
Gate G: PLANNED / UNEVALUATED / NOT ACQUIRED
Next authorized action: PREPARE-PROTECTED-PUBLICATION-CIV-47-SENIOR-APPROVED-CANDIDATE
```

This document records the completed independent senior re-review of Correction
01. It does not alter the original `CORRECTION REQUIRED` verdict and does not
claim publication, remote verification or Gate G evaluation.

## Finding 01 — carrier cultural-content binding

The original API proved that a carrier and source existed but let the caller
pair that carrier with any practice held by the source. Correction 01 adds the
smallest honest supported path:

- an atomic CIV-47 operation creates a normal CIV-43 oral transmission with a
  bounded opaque attachment;
- the attachment commits the CIV-47 namespace, exact practice ID and digest of
  the full immutable practice descriptor;
- the culture exposure retains carrier event ID, content digest and the
  source's exact adopted-status cause;
- restore checks the oral record and retained oral causal event against that
  commitment;
- plain oral carriers, carriers committed to another practice and current
  CIV-45/CIV-46 carriers without cultural commitments fail closed.

The attachment is carrier data, not a CIV-41 belief, CIV-42 semantic graph,
World truth or global culture registry. CIV-47 remains the sole interpreter of
its namespace.

## Finding 02 — locality by identity

Use participants are canonically sorted only after their public input count is
bounded. Authorization iterates all participants where identity differs from
the practitioner; it never depends on array position. Witnesses remain checked
under the same existing social/settlement locality contract. The adversarial
proof establishes shared legitimate adoption, migrates `agent_0` to east,
keeps practitioner `agent_1` in main, proves `agent_0 < agent_1`, and verifies
an exact byte-identical refusal.

## Finding 03 — pre-bounded public inputs

The following caller-variable inputs are bounded before proportional
normalization:

- explicit individual projection IDs before sorting, Set construction and
  authority lookup;
- co-participant and witness IDs before Set construction, sorting, joining and
  request hashing;
- writing/archive carrier strings before canonicalization and hashing;
- schema-42 cultural collections and strings before whole-state boundary
  encoding and hashing.

The existing CIV-47 configuration remains the single source of collection
bounds. No new generic validation authority was introduced.

## Finding 04 — schema-42 causal linkage

For every retained culture event, restore now validates authoritative event
kind, origin, actor, subject, tick, exact causes and culture payload against the
record. Exposure additionally validates source status, carrier event, oral
attachment and content commitment. A bounded semantic replay over unique
operation records reconstructs source status, competition choices, outcomes,
required causes and final sparse individual stances.

Hostile re-signed checkpoints cover event kind, payload, actor, subject,
origin, causes, jointly altered record/event causes, originator/actor relation
and carrier linkage. Correctly compacted histories remain valid through the
existing culture and causal retention boundaries.

## Validation

On product/test commit `45701f56169218b70f2e698dc0dea67bb1d027c0`:

- targeted Debug: 73/73 PASS;
- release CIV-41→47 chain: PASS, CIV-47 73/73;
- repository gate: 35/35 steps and 4755/4755 assertions PASS;
- exact restart, replay/idempotence, compaction, mortality continuity,
  failure atomicity, two-settlement divergence and provider-off proofs pass.

The candidate commit could not contain its own identity. Its exact identity and
review ZIP were recorded in the external bundle manifest and are now recorded
above by this documentation-only successor.

Independent re-review of exact candidate
`874a844ba54b66210ac303912193038c9f4ee6e0`, tree
`fec66e6423e594c568b700ced191fbafd87b5523`, returned **PASS — SENIOR REVIEW
APPROVED** with **P0 0 / P1 0**. The four original P1 findings remain recorded
above as historical findings closed by Correction 01.

```text
CIV-47: PASS — SENIOR REVIEW APPROVED / NOT PUBLISHED / NOT REMOTE VERIFIED
Senior review approved: YES
Gate G evaluated: NO
Gate G acquired: NO
Push attempted: NO
```
