# Pebble live-adapter rules

- `Pebble` owns platform adapters, World sensors, physical executors, UI exposure, and lifecycle integration; it does not own a second cognitive state.
- The controller orchestrates `AgentSimulationSession` and adapters. It must not duplicate goals, memory, targeting, or other cognition.
- Keep every laboratory gate disabled by default and require an exact explicit opt-in value.
- Prevalidate, bound, execute, and verify every World mutation transactionally. Publish session state only after mutation verification.
- Verify rollback after every failed transaction and cleanup after stop, reset, World replacement, dimension/lifecycle transition, and termination.
- Proxies and probes are unregistered, non-persistent, excluded from saves, and removed through the normal World lifecycle APIs.
- Keep cognitive logic out of renderers. Rendering may visualize snapshots but must never select goals, actions, targets, routes, or memories.
