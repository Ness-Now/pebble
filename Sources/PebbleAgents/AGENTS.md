# PebbleAgents rules

- Keep this target a pure, deterministic runtime with no dependency on `PebbleCore`, AppKit, Metal, rendering, persistence, or platform services.
- Never read or mutate `World` directly. Consume validated observations and outcomes supplied by adapters.
- `AgentSimulationSession` is the source of truth for shared cognitive state and transitions; do not introduce a second kernel or parallel state owner.
- Sort all decision-relevant inputs and use explicit, stable tie-breaks. Never rely on `Dictionary` or `Set` iteration order.
- Keep state, memories, observations, queues, and collections explicitly bounded for live configurations.
- Attach provenance to information whenever it can materially affect a decision.
- Keep aptitude, development, knowledge, skill, and culture as distinct state and concepts.
- Do not add direct LLM or network APIs to the kernel. Future external-model outputs are structured proposals validated before application.
- Keep histories bounded or explicitly persisted under a versioned policy.
- Preserve deterministic baselines when extending agent domains.
- Preserve snapshot fields, `Codable` representations, enum raw values, and existing encoding compatibility unless a migration is explicitly in scope.
