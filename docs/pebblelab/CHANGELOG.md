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
