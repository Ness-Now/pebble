# PebbleLab Roadmap

## Phase 3.1 - Nearby Agents Social Perception V0

Status: done and validated.

Goal: abstract agents can observe nearby abstract agents by relative position
and Manhattan distance. This is perception only, not interaction.

## Phase 3.2 - LabGoal/currentGoal V0

Status: done and validated.

Goal: abstract agents choose a deterministic `currentGoal` before selecting an
action. This is not a planner and does not mutate the world.

## Phase 3.3 - health/fear/homePosition V0

Status: done and validated.

Goal: abstract agents track health, fear, and home position without pathfinding,
physical entities, inventory, or social relationships.

## Phase 3.4 - LabInventory Minimal V0

Status: done and validated.

Goal: abstract agents carry a small deterministic string-keyed inventory
without item registries, physical pickup, block interaction, crafting, or
sharing.

## Phase 3.5 - agents_basic Scenario And --agents N

Status: done and validated.

Goal: keep `agent_smoke` as a fixed two-agent validation scenario while adding
`agents_basic` as a configurable deterministic multi-agent simulation scenario.

## Phase 3.6 - Abstract Movement V0

Status: done and validated.

Goal: agents can update abstract positions from selected actions without
pathfinding, PebbleCore entities, collision, gravity, or world mutation.

## Phase 3.7 - Abstract ReturnHome / seekSafety Movement

Status: done and validated.

Goal: agents with `seekSafety` move one abstract X/Z step toward their
`homePosition`, still without pathfinding, collision, physical entities, or
world mutation.

## Phase 3.8 - long_run_smoke And Event Rate Controls

Status: done and validated.

Goal: run longer deterministic abstract-agent simulations while throttling
frequent NDJSON events without changing internal simulation metrics.

## Phase 3.9 - Scenario Success Criteria And Regression Report

Status: done and validated.

Goal: provide a compact `regression_smoke` report with scenario criteria,
key metrics, and pass/fail checks for quick PebbleLab health validation.

## Phase 4.0 - Physical Agent Spike Planning

Status: done and validated.

Goal: plan the first physical-agent spike without implementing entities yet,
including ownership boundaries, PebbleCore risks, integration options, and
required test coverage.

## Phase 4.1 - Physical Agent Placeholder Spawn

Next recommended step: add one opt-in physical-agent placeholder smoke that
keeps `LabAgent` as the abstract cognitive state and introduces physical
representation incrementally through an isolated bridge.
