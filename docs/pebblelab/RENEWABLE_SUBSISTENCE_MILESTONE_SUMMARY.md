# V4-MILESTONE-RENEWABLE-SUBSISTENCE-v1

## Verdict and baseline

`V4-MILESTONE-RENEWABLE-SUBSISTENCE-v1` is complete in its bounded contract as
a local review candidate. It was implemented from the published `CIV-33`
canonical baseline:

```text
7cd1bd3f65a4dc5943f8229b9444ac425c98c677
```

The product and rendered proof are separated into these reviewable commits:

```text
4c14795  Close the physical renewable subsistence loop
d92fe68  Add rendered renewable-cycle restart campaign
```

This report intentionally does not self-reference its containing documentation
commit. Gate R, Gate B and `V4-GATE-C-v1` remain acquired and published.
`CIV-00` through `CIV-33` remain complete and published. Gate D is not
evaluated or acquired; its evaluation is the next eligible program action.
`CIV-34` is not started.

## Reused physical authorities

The milestone extends the existing physical crop loop instead of creating a
parallel farming or inventory engine:

```text
PebbleCore crop blocks and random-tick growth
→ Pebble physical agriculture prevalidation/execution/rollback
→ AgentSimulationSession bounded agricultural receipts
→ existing physical food consumption
→ checkpoint/replay and read-only Observer projection
```

Carrots are the smallest honest dual-use resource for the proof: the same real
item is edible and is the canonical planting input for the carrots crop. The
existing Pebble executor remains the only physical agriculture boundary;
PebbleCore remains the authority for blocks, crop stage, items, containers,
World ticks and matter. `AgentSimulationSession` remains the sole civilization
aggregate root.

The mature carrots crop yields the deterministic bounded Core quantity `3...5`.
This supports a verified food debit, a verified second planting and a physical
surplus without an external injection. Agriculture crop selection, maturity
checks and receipts are crop-aware while preserving canonical ordering and
bounded plots.

## Durable renewal evidence

Agriculture now records a bounded cycle ordinal and one durable renewal row
that binds:

```text
plot and crop
second-cycle planting action
exact first-cycle source planting and harvest actions
source physical output quantity
second-cycle physical input quantity
tick and causal event
```

The row is not an independent milestone authority. The milestone status is a
pure projection derived from agricultural plots, retained physical-action
receipts and the physical-food ledger. Validation rechecks exact source action
identity, crop, plot, quantity, ordering and causal fields. Retention pins the
receipts required to prove a live renewal; when bounded capacity cannot retain
them, the candidate transaction fails closed.

Checkpoint/replay schema 29 persists this bounded agricultural proof. Observer
schema 7 exposes only a read-only projection: crop, cycle, first output,
consumed quantity, reserved/replanted quantity, second output, status and block
reason. Observer never mutates agriculture, food or the World.

## Exact physical accounting

The final two-process rendered campaign used World `wmsajoh1p9s88` and session
`live-46-14-66--21`:

| Boundary | Quantity | Proof |
| --- | ---: | --- |
| Initialization | 1 carrot | Only external reproductive input, before the explicit initialization boundary |
| First plant | -1 | One physical planting receipt; free initial stock becomes zero |
| First harvest | +5 | One mature carrots crop, one physical harvest receipt |
| Food consumption | -1 | Existing physical-food receipt; hunger `0.05 → 0` |
| Stored surplus | 3 | Existing physical container transfer |
| Reserved seed | 1 | Exact output of the first harvest |
| Second plant | -1 | Exact first-harvest provenance; stage-0 crop established |
| Second harvest | +3 | One mature crop after restart |
| Final loose matter | 6 | Agent 1 + container 5; no crop remains at the site |

Each growth boundary used 17 authorized World ticks. After initialization
closed there were zero external injections and zero direct World block
mutations. Planting, growth, harvesting, food consumption and storage used
normal product mechanics.

## Restart and integrity

The first process saved the second cycle at stage 0 with three carrots in the
container and one carrot physically committed to the crop. It terminated
fully. A new process loaded the same World, simulation, plot, crop stage,
container quantity, agricultural evidence and source provenance, then advanced
the second crop only through new World ticks.

The checkpoint uses schema 29. Its manifest integrity digest
`b7f798abf05572fcd3fb6fd4cd96de5c83317bece6075e7551cbdeb6f574b95d`
was verified before restoration. No growth was credited during process stop.
The derived completion appeared once after the second physical harvest.

## Validation

Focused suites:

```text
renewable-subsistence: 19 passed, 0 failed
ecological-observation: 17 passed, 0 failed
harvest: 46 passed, 0 failed
agriculture: 32 passed, 0 failed
physical-actions: 38 passed, 0 failed
materials: 30 passed, 0 failed
homeostasis-health: 30 passed, 0 failed
physical-food-survival: 50 passed, 0 failed
lifecycle: 80 passed, 0 failed
skills: 59 passed, 0 failed
teaching: 41 passed, 0 failed
work-professions: 29 passed, 0 failed
material-rights: 21 passed, 0 failed
checkpoint-replay: 49 passed, 0 failed
persistence-reconciliation: 18 passed, 0 failed
observer: 20 passed, 0 failed
mortality: 93 passed, 0 failed
estates-inheritance-succession: 84 passed, 0 failed
```

Repository gate:

```text
3652 passed, 0 failed
35/35 verification steps
```

Rendered campaign:

```text
schema 29 two-process restart: PASS
same World/session/plot/stage-0 crop: YES
manifest integrity: verified
external injections after initialization: 0
direct World block mutations after initialization: 0
duplicate receipts: 0
duplicate sites: 0
Observer mutations: 0
runtime errors: 0
cleanup: exact
```

Four native-resolution captures were inspected: first physical planting,
first physical harvest, the same second-cycle crop after restart and final
second harvest. The UI remained readable and exposed the expected causal and
Observer evidence without graphical or runtime errors.

## Limits

This milestone proves one bounded renewable physical subsistence loop. It does
not implement or claim:

- a general food economy or autonomous population-scale supply policy;
- markets, prices, trade, taxation, land tenure or farm ownership;
- irrigation, seasons, weather-driven yield or soil depletion;
- crop genetics, mutation, disease or selective breeding;
- tools, workshops, industrial production or the systems of `CIV-34`;
- Gate D evaluation or acquisition.

`V4-GATE-D-v1` remains a separate, not-yet-executed evaluation. `CIV-34`
remains not started.
