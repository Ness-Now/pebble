# PebbleLab Changelog

## Unreleased

- Added `nearbyAgents` social perception v0 for abstract `agent_smoke` agents.
- Added `agent_observed_nearby_agent` NDJSON events.
- Added `nearbyAgentObservations` and `agentsWithNearbyAgents` metrics.
- Added `LabGoal/currentGoal` v0 for abstract PebbleLab agents.
- Added `agent_goal_changed` NDJSON events.
- Added `agentGoalSelections`, `agentGoalChanges`, and `goalsByKind` metrics.
- Added health, fear and homePosition v0 for abstract PebbleLab agents.
- Added `agent_home_assigned` NDJSON events and health/fear/home metrics.
- Added `LabInventory` minimal v0 for abstract PebbleLab agents.
- Added `agent_inventory_assigned` NDJSON events and inventory metrics.
- Added `agents_basic` scenario with configurable `--agents` count.
- Added abstract movement v0 for PebbleLab agents.
- Added abstract seekSafety movement toward `homePosition`.
- Added `long_run_smoke` scenario and event rate controls.
- Added `regression_smoke` scenario with compact `regression_report.json`.
- Documented Phase 4 physical agent spike plan.
- Added physical placeholder smoke for PebbleLab agents.
- Added physical placeholder synchronization with abstract movement.
- Documented real PebbleCore entity feasibility for PebbleLab agents.
- Added unregistered PebbleCore entity probe for PebbleLab agents.
- Added invariant report for the PebbleLab core entity probe.
- Documented debug visibility plan for PebbleLab core entities.
- Added gated wireframe debug marker for PebbleLab core entities.
- Documented transient app-side probe lifecycle plan.
- Added explicit chunk-save exclusion policy for PebbleLab core entity probes.
- Added gated app-side lifecycle commands for PebbleLab core entity probes.
- Documented visual app validation workflow for PebbleLab probes.
- Recorded successful manual visual validation for PebbleLab app probes.
- Added cleanup hardening for PebbleLab app probes.
- Documented scripted screenshot validation workflow for PebbleLab probes.
- Added first simple physical behavior smoke for PebbleLab core entities.
- Added multi-agent physical behavior smoke for PebbleLab core entities.
- Added invariant report for multi-agent physical behavior smoke.
