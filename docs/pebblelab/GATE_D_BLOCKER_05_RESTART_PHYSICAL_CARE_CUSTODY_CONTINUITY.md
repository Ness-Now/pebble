# Gate D Blocker 05 — Restart physical-care custody continuity

## Status

```text
Gate D Evaluation 05: EVALUATED_FAIL_NOT_ACQUIRED — HISTORICAL EVIDENCE
Gate D Blocker 05: BLOCKER_FIX_LOCAL_CANDIDATE
Gate D: EVALUATED_FAIL_NOT_ACQUIRED
CIV-34: NOT_STARTED
next action: senior review and manual publication of Gate D Blocker 05
```

This product correction does not rerun Evaluation 05 and does not acquire
Gate D. A future independent Evaluation 06 is required after publication.

## Root cause

`LabCoreAgentEntity` is deliberately unregistered and nonpersistent
(`shouldSaveToChunk == false`). Blocker 01 could therefore restore a missing or
moved probe only when an integrity-protected save-time attestation proved that
its custody was empty. Evaluation 05 reached a legitimate restart-safe
checkpoint while caregiver `agent_0` held one real bread. The fresh bootstrap
created empty placeholder probes, and the loader correctly failed closed
because it had no durable physical proof authorizing non-empty restoration.

The checkpoint's `restartSafe=1` claim was consequently stronger than the
save-time evidence. There was no corruption or permissive adoption: the
checkpoint session remained unpublished at tick zero.

## Authority and chosen boundary

The correction uses bounded physical-custody restart evidence plus the
existing PebbleCore World entity save path:

- PebbleCore `World`, `ItemStack`, `LabCoreAgentEntity` and `ItemEntity` remain
  the only physical truth.
- Pebble owns capture, validation, reconciliation, mutation, verification and
  rollback.
- PebbleAgents stores opaque protected bytes and hashes. It never decodes an
  `ItemStack`, owns an inventory, or creates matter from kinship, care or
  Material Rights claims.
- `AgentSimulationSession` remains only the civilization aggregate and
  projection.

At save, Pebble canonically encodes every occupied probe slot and round-trips
it through the real `ItemStack` codec. Evidence records agent identity, slot
count, slot ordinal, registry item key, quantity, damage, canonical stack
bytes, per-stack digest and a complete-custody fingerprint. The canonical
bytes cover the actual `ItemStack` model, including enchantments, label and
all `StackData` fields: potion, trim, sherds, charged state, prior work,
repair units, nested contents, lodestone and flight state. Bounds cover slot
count, stack size/count, metadata lengths, nesting depth, aggregate nested
stacks and encoded byte size.

## Manifest compatibility and save honesty

Session checkpoint schema 30 and Observer schema 7 are unchanged. The live
manifest integrity version is 2 only when protected non-empty custody evidence
is present. Empty-custody saves omit the new evidence and preserve the exact
version-1 semantics used by Blocker 01. Version-1 manifests remain readable;
an older manifest cannot authorize non-empty restoration.

A save fails before publication if exact stack capture/round-trip, physical
embodiment identity, slot completeness, registry bounds or relevant Material
Rights constraints cannot be proved. Therefore a supported non-empty custody
can truthfully publish `restartSafe=1`; an unsupported custody cannot silently
produce that claim.

## Physical escrow and reconciliation

On an exact graceful shutdown, `removeLabCoreAgentProbe` converts each carried
stack once into a real `ItemEntity`. Before that mutation, one centralized
freshness validator compares the live boundary against the handoff captured by
the checkpoint save. It requires the same checkpoint name and identity,
simulation and tick, semantic digest, causal sequence and digest, live World
object and protected World binding, exact session/mapping/World probe
population, exact probe object and position, complete canonical slot custody
and fingerprint, and absence of a pre-existing checkpoint escrow. Future
movement or action paths do not maintain a fragile invalidation flag; the
complete boundary is re-derived at the instant of handoff.

Each protected spill has a version-2 integrity-linked token derived from the
checkpoint ID, manifest-v2 integrity digest, agent, slot and protected stack
digest. Thus a physically identical escrow from another checkpoint or another
manifest boundary is foreign. The spill is inert, unpickable, non-expiring,
non-merging and protected from destructive damage while it is escrowed.
Creation marks its existing World chunk modified so the normal PebbleCore save
persists the entity; there is no second World save or inventory engine. An
ordinary spill also dirties its existing chunk, so current post-checkpoint
matter is not silently dropped merely because a checkpoint handoff became
stale.

At fresh load, Pebble adopts only the complete exact set of checkpoint-bound
escrow entities. Manifest-v2 evidence alone is not physical authority to
recreate matter. If no tagged escrow exists, only an exact same-process probe
boundary may be reused without mutation; a fresh process cannot satisfy that
condition and fails closed before physical mutation. Abrupt process loss
without a persisted escrow is therefore not supported by this bounded
correction. Partial sets, duplicate tokens, foreign tokens, stack or position
divergence and contradictory current custody are also refused. Adoption
removes each escrow entity, marks its chunk for the normal World save, then
writes the exact saved slots through the existing physical custody endpoint.
One physical stack has one representation before and after the boundary.

## Senior review correction 01

The candidate at reviewed head
`c8125c7ffafedb81a3295d7b9fbce7844fbd24fb` retained the checkpoint custody
handoff after save but tested its shutdown freshness mainly through agent-set
and slot equality. A post-checkpoint move could consequently label current
matter at a new position as escrow for an older checkpoint. A second seam let
a fresh loader reconstruct manifest custody whenever no tagged spill was
observed.

The correction closes both seams. A stale position, session/causal boundary,
World binding, population, probe identity or custody fingerprint prevents all
checkpoint provenance tags. The resulting ordinary current matter is saved by
the normal World path. A later attempt to load the older checkpoint observes
no matching checkpoint-bound escrow and refuses before probe, custody or
session mutation. Protected evidence describes and verifies expected custody;
it never establishes that missing World matter is safe to recreate.

## Atomic load

Before mutation the loader validates manifest integrity, World binding,
checkpoint identities, complete custody evidence, exact stack decoding,
Material Rights constraints, bootstrap probe uniqueness, target placement and
the complete escrow set. It then performs one bounded transaction:

1. retire, reposition or create authorized probes;
2. remove the verified escrow set;
3. restore exact physical slots;
4. publish the candidate session and orchestration;
5. verify the complete World entity set, probe population, positions and
   custody.

Rollback restores the prior session and orchestration, every prior probe
field and slot, removes newly created probes, re-adds the same escrow entity
objects, restores affected chunk dirty flags, and verifies exact entity and
probe identity sets. An injected failure after the first non-empty custody
restore proves that no item, G1 probe or candidate session leaks.

## Material Rights and care continuity

Material Rights is a constraint, never a source of matter. For a physical
holder, save and load validate holder identity, material identity, quantity,
aggregate duplicate references and a current-tick custody fingerprint when
available. A recognized owner or caregiver cannot cause an item to be
created.

The dedicated two-process proof creates legitimate G1 `agent_3`, with
`agent_0` as parent, canonical guardian and caregiver in `household_0`.
`agent_0` carries a non-trivial damaged/enchanted/labeled tool in slot 0 and
one real bread in slot 1. After fresh restart, the loader restores the exact
checkpoint positions, creates the missing G1 probe, restores both physical
stacks exactly once, and republishes the same family and care context. The
next productive tick uses the normal dependent-care mechanism, debits bread
from slot 1 exactly once, publishes the normal care and childhood outcomes,
and performs no refill or duplicate receipt.

## Evidence and limits

The dedicated runner is
`scripts/verify-pebblelab-gate-d-restart-physical-care-custody-fix.sh`. It
also proves multi-slot exactness, rollback after physical restore, protected
evidence corruption refusal and contradictory bootstrap-custody refusal. The
senior-review additions prove that post-checkpoint movement creates no false
escrow and that post-checkpoint custody mutation cannot trigger manifest-only
reconstruction over surviving World matter. Both stale loads preserve the
same relevant World material counts before and after refusal. The
empty-custody Blocker 01 path and Blockers 02 through 04 remain separate
mandatory regressions.

This is deliberately not a general physical persistence subsystem. It covers
only complete custody of nonpersistent Lab probes at a verified restart-safe
checkpoint. Unknown containers, arbitrary World items and social assertions
remain outside this restoration authority and fail closed rather than being
guessed.
