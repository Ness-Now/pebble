# PebbleLab runner rules

- Keep the runner headless and deterministic. Every reproducible scenario uses an explicit seed and bounded tick count.
- Preserve historical CLI behavior, output filenames, sorted JSON encodings, NDJSON event meaning, and existing report fields unless a migration is explicitly required.
- Reuse `PebbleAgents`; never copy or reimplement its cognitive transitions, session state, or targeting logic here.
- Keep reports, fixtures, scenario routing, and output formatting outside the shared runtime kernel.
- Write run outputs only to an explicit caller-provided location, normally a temporary or ignored directory.
- Experiments must distinguish World truth, agent belief, transmitted claims, and observed outcomes.
- Future scenarios must retain observable seed, configuration, and causal evidence.
- Society V1 and Medieval Civilization V1 are acceptance milestones, not behaviors to script artificially.
