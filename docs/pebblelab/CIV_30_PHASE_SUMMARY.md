# CIV-30 — Genetics, Development and Phenotype V1

## Verdict and baseline

`CIV-30` is complete in its bounded contract as a local review candidate. It
was implemented from the published canonical baseline:

```text
c1eda66dfacdd16911207b6fc8fd58df8581b99f
```

The product work is separated into three commits:

```text
be157f1  Implement bounded deterministic genetics V1
994c3ce  Integrate rendered genetics birth and restart
453ff02  Harden CIV-30 checkpoint and inherited genetics integrity
```

This report intentionally does not self-reference its containing documentation
commit. Gate R, Gate B and `V4-GATE-C-v1` remain acquired and published.
`V4-GATE-D-v1` and
`V4-MILESTONE-RENEWABLE-SUBSISTENCE-v1` remain planned. `CIV-31` is not
started and is the next eligible phase.

## Contract proved

- Genetics V1 is a closed model with four diploid loci:
  `homeostaticResilience`, `recoveryEfficiency`,
  `deprivationTolerance` and `expressionTempo`. Each contribution is one of
  `reduced`, `reference` or `enhanced`. Profile and transition collections are
  explicitly bounded.
- Genetics is off by default and requires explicit activation after
  population, lifecycle, homeostasis and the causal ledger exist. Activation
  assigns every active founder exactly once in stable agent-ID order.
  Founder alleles depend only on the simulation identity, agent identity,
  locus, copy and model version. They do not depend on dictionary iteration,
  input order, frame rate or wall-clock state.
- A normal lifecycle birth derives the child's immutable genotype from the
  reproduction plan's two canonical progenitors. Each locus records one
  contribution from each parent, including source genotype, source allele
  index and causal creation event. Parent input order is canonicalized;
  distinct birth and child identities provide deterministic sibling
  variation. V1 performs no general mutation.
- Validation binds every inherited genotype to exactly one canonical birth
  record: child ID, birth ID, ordered progenitors and creation tick must match.
  Every active `localBirth` lifecycle member has exactly one such inherited
  genotype; bootstrap and imported roots follow the existing founder policy.
  Retained causal evidence must be the same-child, same-tick
  `genotypeInherited` event by the first canonical progenitor and must cite the
  corresponding `birthSiteValidated` event. Honest causal-ledger eviction
  remains accepted under the existing bounded historical-reference policy.
- Birth publication is one candidate transaction. Child cognitive state,
  population member, lifecycle record, parentage, household membership,
  inherited genotype, development, phenotype and causal provenance either
  publish together or do not publish. A rejected or late-failing birth leaves
  neither a child without genotype nor an orphan genotype.
- Imported migrants receive one deterministic root genotype in the same
  population admission transaction. This is explicit founder-style
  initialization for an external population root, not a mutation or a second
  genetics owner.
- Development is a bounded authoritative projection of lifecycle age/stage
  and accumulated CIV-29 physiological exposure. Expression maturity is
  monotone, exposure is a bounded deterministic moving average, and
  trajectories are `protected`, `stable` or `strained`. Development stops at
  the causal death boundary and does not resume after checkpoint restore.
- Phenotype is derived from immutable genotype and current development. It is
  not independently editable or persisted as a second source of truth.
  Checkpoint validation recomputes the expected values and rejects divergence.
- Expressed modifiers affect only the existing CIV-29 homeostasis calculations
  for resilience, recovery and deprivation tolerance. Each value is clamped
  to the configured `-800...800` basis-point range, and the underlying health,
  needs, age and mortality authorities remain unchanged.
- Genetics adds no profession, skill, knowledge, intelligence, personality,
  household role, status, claim, permission or other automatic social
  outcome. Existing kinship and household changes at birth remain owned by
  their existing transitions.
- Genotype assignment, inheritance, significant development and phenotype
  changes extend the causal ledger. Snapshot and Observer projections preserve
  stable ordering and per-locus parental provenance.
- Checkpoint/replay schema 22 preserves genotype, development, phenotype and
  their causal events byte-exactly. Restart never redraws alleles, duplicates
  an assignment or applies development twice.
- Observer schema 3 projects the authoritative genotype, development and
  phenotype in a read-only UI. Opening, navigating or closing Observer changes
  no tick, causal sequence or durable digest.

`PebbleAgents` remains a pure deterministic runtime.
`AgentSimulationSession` remains the sole civilization aggregate root.
Pebble owns live scans, probe creation, World verification, UI exposure and
rollback. PebbleCore remains physical truth. No parallel World, persistence,
farming, inventory, health, lifecycle or social engine was introduced.

## Integration corrections

### Bounded local-ecology deduplication

Two adjacent resident scan origins can identify the same physical habitat and
therefore the same `patchID`. The Pebble adapter now sorts observations by the
existing canonical comparator, retains the first unique patch IDs up to the
existing initial-patch bound and counts duplicates discarded. PebbleAgents
continues to reject duplicate habitat input; its invariants were not relaxed.

The rendered proof observed:

```text
patches=2
duplicateHabitatsDiscarded=1
World reads=177/256
```

### Atomic genetics, kinship and household birth

The population-born event now carries the optional inherited-genotype event as
a causal input. Kinship validation accepts only the existing birth-site cause
and at most one same-child, same-tick `genotypeInherited` cause rooted in that
site event. The combined deterministic test restores the completed
child/parentage/household/genotype transaction byte-exactly.

### Fail-closed persistent-child physical restoration

Pebble's schema-22 live manifest records the sorted active agent IDs whose
resolved probes had exactly empty carried inventories at save time. On load, a
checkpoint identity absent from the fresh bootstrap may receive a new
transient probe only when all of the following hold:

- the manifest has a versioned canonical SHA-256 integrity digest covering
  its schema, checkpoint identity and storage digest, World binding, restart
  safety, reconciliation binding and complete live orchestration, including
  the empty-probe attestation;
- that digest is verified before any manifest field can authorize World
  mutation and is rechecked while validating the temporary save bundle;
- the identity is a validated active checkpoint agent;
- it is present in both population and lifecycle;
- no probe for it exists in the bootstrap World or controller index;
- the live manifest attests that its carried inventory was empty at save;
- no Material Rights record resolves to it as the last verified physical
  holder;
- its persisted position passes normal bounded physical creation assessment;
- the candidate World entities, probe identities and controller indexes verify
  before session publication.

Any failure removes newly created probes, restores retired bootstrap probes,
restores the prior session and controller fields, and verifies exact prior
World entity identities and probe state before returning the original error.
An agent carrying any item is not recreated empty. Holder reconciliation
continues to use CIV-27; this is not a second World save or persistence engine.
For schema 22 the attestation is mandatory, sorted, unique, bounded, composed
only of valid checkpoint agent IDs and protected by the digest. Older
unprotected manifests remain historically loadable where otherwise valid, but
cannot authorize recreation of an agent absent from bootstrap.

## Deterministic evidence

Commands rerun after product commit `453ff02`:

```text
PEBBLELAB_SMOKE_ONLY=genetics-development swift run pebsmoke
45 passed, 0 failed

PEBBLELAB_SMOKE_ONLY=lifecycle swift run pebsmoke
80 passed, 0 failed

PEBBLELAB_SMOKE_ONLY=homeostasis-health swift run pebsmoke
30 passed, 0 failed

PEBBLELAB_SMOKE_ONLY=checkpoint-replay swift run pebsmoke
49 passed, 0 failed

PEBBLELAB_SMOKE_ONLY=observer swift run pebsmoke
20 passed, 0 failed

scripts/verify-pebblelab.sh
3419 passed, 0 failed
35/35 verification steps
exit status 0
```

The repository gate log was produced after the last product-file change and
therefore corresponds to `453ff02`. Focused coverage includes bounds, founder
uniqueness, input-order neutrality, migration, normal inheritance, per-locus
provenance, canonical birth/progenitor/tick binding, retained causal binding,
honest event eviction, local-birth and founder-origin corruption refusal,
kinship/household atomicity, sibling variation, rejected-birth rollback,
physiological exposure, immutable genotype, bounded CIV-29 effects, monotone
development, transition eviction, Observer immutability, schema-22 manifest
integrity and structural attestation checks, legacy fail-closed probe
restoration, checkpoint/replay and post-mortem development stop.

## Rendered two-process restart evidence

Command:

```text
scripts/verify-pebblelab-civ30.sh
```

Result: **PASS**, exit status 0.

The harness used World `PebbleLab-Disposable-CIV30-46`, seed 46, two separate
Pebble processes for the rendered restart, and a third isolated process for
the corrupt-manifest refusal:

```text
process 1: bootstrap three real probes in a rendered World
           → initialize population, ecology, lifecycle, kinship, households,
             homeostasis, genetics and read-only Observer
           → assign three deterministic founder genotypes
           → create a normal reproduction plan
           → finalize the normal birth of agent_3
           → publish parentage, household membership, inherited genotype and
             per-locus parental provenance in the same candidate transaction
           → save a schema-22 checkpoint with empty child custody attested
             inside a valid manifest integrity digest
           → terminate and remove all four transient probes
process 2: load the same SaveDB World and schema-22 checkpoint
           → recreate only missing agent_3 through the verified-empty rule
           → preserve the same World, session, child, genotype and provenance
           → continue newborn → juvenile and development 0 → 2500
           → save a continued schema-22 checkpoint
           → close Observer and delete both proof checkpoints
           → terminate and remove all four transient probes
process 3: start a fresh three-probe bootstrap session
           → alter agent_3 to agent_9 in a copied protected attestation without
             updating the stored manifest digest
           → refuse load with storageDigestMismatch before World/session/index
             mutation
           → prove identical status, checkpoint digest and genetics state
           → delete the tampered managed checkpoint and remove all three probes
```

Compact observed facts:

```text
World identity: wms6lyssg6j3q
session identity: live-46-14-66--21
parents: agent_0, agent_1
child: agent_3
founder agent_0: genotype-agent_0-v1-3dc50798e7eee585
founder agent_1: genotype-agent_1-v1-9e31719f6724e830
founder agent_2: genotype-agent_2-v1-632c2faaa76a7fcb
child genotype: genotype-agent_3-v1-7eb9e1b0ffbd955e
deprivationTolerance: agent_0 reduced + agent_1 reduced
expressionTempo: agent_0 reduced + agent_1 enhanced
homeostaticResilience: agent_0 enhanced + agent_1 reduced
recoveryEfficiency: agent_0 reduced + agent_1 enhanced
genotype causal event sequence: 71
birth record: birth-00000001
post-birth checkpoint causal boundary: sequence 77
stage: newborn → juvenile
development: 0 → 2500
phenotype deprivationTolerance: 0 → -200
other expressed phenotype modifiers: 0 → 0
restart: complete process 1 termination → new process 2
probe reconciliation: restored_verified:agent_3
manifest integrity digest: e61e8b451e2250770672004f8149f7d88549275ed103699b7948b0add011be00
manifest empty-custody evidence: protected and required by restored_verified
tampered attestation: agent_3 → agent_9 without digest update
tampered load result: storageDigestMismatch before mutation
refused-load World/session/probe/index equality: exact
genotype after restart: exact match
assignment count: 1
duplication count: 0
Observer mutation count: 0
runtime errors: 0
cleanup: exact
```

All four 3024×1898 captures were inspected. They show a real rendered forest
World behind legible read-only Observer panels:

```text
founder agent_0 SHA-256:
886b0ea2baa2c15f00616da9cce00af4e543dd876bf5cc09d711b4483aa47c81

founder agent_1 SHA-256:
ecf3474c9408812b9f86194a6694f8ac19a95375cc2a417fdc34d608298b2ad2

child inheritance SHA-256:
a17895483ffcec952a774feb105dea7e07074402ea9785be0f4da34b743c6a3a

child after restart SHA-256:
bb28256cfb2c55a9982ed3c66d1ba502ed167de4a4c572f1e01f0fc2131c7543
```

No visual anomaly, runtime error, residual process, residual checkpoint,
duplicate identity, duplicate assignment or Observer mutation was found.

## Honest V1 limits

- There is no general mutation model, recombination beyond deterministic
  diploid contribution selection, genetic disease or genetic predisposition
  catalog.
- The model encodes no sex, gender, detailed appearance, intelligence or
  personality.
- Development V1 is bounded physiological expression, not childhood social
  development V2, education, knowledge acquisition or skill formation.
- This phase does not implement guardianship, unions, lineages, houses,
  estates, inheritance or succession.
- A persistent missing probe can be recreated only from explicit
  verified-empty custody evidence protected by the schema-22 manifest
  integrity digest. Older unprotected manifests, non-empty custody and
  unresolved physical custody remain fail-closed and are not guessed.
- Schema 22 binds civilization state to the existing CIV-27 World protocol;
  it does not claim a globally atomic World/civilization save.
- Renewable subsistence was not implemented or evaluated. Gate D remains
  planned and unacquired.
