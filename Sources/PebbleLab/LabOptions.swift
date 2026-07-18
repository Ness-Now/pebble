import Foundation

struct Options {
    var seed: UInt32 = 12345
    var ticks: Int = 20
    var scenario = "empty"
    var outPath: String?
    var chunkRadius = 0
    var chunkRadiusProvided = false
    var agents = 2
    var agentsProvided = false
    var eventRate = 1
    var logWorldTicks = true
}

func usage() -> String {
    """
    PebbleLab - headless PebbleCore simulation runner

    Usage:
      PebbleLab [--seed <UInt32>] [--ticks <Int>] [--scenario empty] [--chunk-radius <Int>] [--agents <Int>] [--event-rate <Int>] [--log-world-ticks <Bool>] [--out <path>]
      PebbleLab --help

    Options:
      causal_ledger_smoke writes the bounded causal ledger proof outputs when selected with --scenario.
      social_information_trust_smoke writes the grounded social and directed-trust proof outputs.
      physical_channel_smoke writes the bounded local sound-and-gesture proof outputs.
      shared_tasks_cooperation_smoke writes the bounded shared-task material proof outputs.
      persistent_checkpoint_replay_smoke writes versioned checkpoint and pure replay proof outputs.
      settlement_metrics_multiscale_smoke writes bounded macro settlement metric and A/B neutrality outputs.
      local_ecology_subsistence_smoke writes bounded forage, pressure, checkpoint v4, and replay proof outputs.
      mortality_population_exit_smoke writes bounded mortality, population exit, checkpoint v5, and replay outputs.
      age_maturity_reproduction_smoke writes bounded lifecycle, local birth, checkpoint v6, and replay outputs.
      durable_kinship_graph_smoke writes canonical parentage, derived relations, checkpoint v7, and replay outputs.
      households_and_membership_smoke writes household periods, home projections, checkpoint v8, and replay outputs.
      dependent_care_lifecycle_smoke writes assignments, material care outcomes, capability policy, checkpoint v9, and replay outputs.
      --seed <UInt32>      World seed. Default: 12345
      --ticks <Int>        Number of ticks to run. Default: 20
      --scenario <String>  Scenario name. Currently supported: empty, chunk_smoke, agent_smoke, agents_basic, seek_safety_smoke, long_run_smoke, regression_smoke, behavior_loop_contract_fixture_smoke, behavior_loop_hardening_smoke, memory_update_from_behavior_result_fixture_smoke, memory_update_hardening_smoke, memory_retrieval_fixture_smoke, memory_retrieval_hardening_smoke, goal_selection_from_memory_fixture_smoke, goal_selection_from_memory_hardening_smoke, behavior_loop_memory_goal_bridge_fixture_smoke, behavior_loop_memory_goal_bridge_hardening_smoke, cognitive_loop_integration_fixture_smoke, cognitive_loop_integration_hardening_smoke, live_cognitive_loop_adapter_fixture_smoke, live_cognitive_loop_adapter_hardening_smoke, live_cognitive_loop_controlled_application_fixture_smoke, live_cognitive_loop_controlled_application_hardening_smoke, goal_application_dry_run_fixture_smoke, goal_application_dry_run_hardening_smoke, goal_application_snapshot_mutation_fixture_smoke, goal_application_snapshot_mutation_hardening_smoke, live_goal_application_guarded_fixture_smoke, live_goal_application_guarded_hardening_smoke, fake_live_goal_application_fixture_smoke, fake_live_goal_application_hardening_smoke, agents_basic_goal_integration_guarded_fixture_smoke, agents_basic_goal_integration_guarded_hardening_smoke, agents_basic_goal_apply_guarded_fixture_smoke, agents_basic_goal_apply_hardening_smoke, agents_basic_cognitive_loop_fixture_smoke, physical_placeholder_smoke, physical_sync_smoke, core_entity_smoke, physical_behavior_smoke, physical_behavior_multi_smoke, physical_movement_denied_smoke, physical_movement_find_occupable_smoke, physical_movement_approved_single_step_smoke, physical_movement_single_step_hardening_smoke, route_following_fixture_smoke, route_following_denied_live_smoke, route_following_approved_two_step_smoke, route_following_live_hardening_smoke, multi_agent_movement_fixture_smoke, multi_agent_movement_fixture_hardening_smoke, multi_agent_live_collision_intent_smoke, multi_agent_approved_physical_movement_smoke, multi_agent_movement_hardening_smoke, multi_agent_movement_tick_fixture_smoke, multi_agent_movement_tick_live_readonly_smoke, multi_agent_movement_tick_approved_application_smoke, multi_agent_movement_tick_hardening_smoke, agent_intent_production_fixture_smoke, agent_intent_production_hardening_smoke, agent_intent_to_tick_fixture_smoke, agent_intent_to_tick_live_readonly_smoke, agent_intent_to_tick_approved_application_smoke, agent_feedback_consumption_fixture_smoke, agent_feedback_consumption_hardening_smoke, feedback_to_agent_intent_context_fixture_smoke, feedback_to_agent_intent_context_hardening_smoke, feedback_aware_intent_policy_fixture_smoke, feedback_aware_intent_policy_hardening_smoke, feedback_aware_intent_to_tick_fixture_smoke, feedback_aware_intent_to_tick_live_readonly_smoke, feedback_aware_intent_to_tick_approved_application_smoke, multi_tick_closed_loop_fixture_smoke, multi_tick_closed_loop_hardening_smoke, multi_tick_closed_loop_live_readonly_smoke, multi_tick_closed_loop_approved_application_smoke, alternate_local_hint_fixture_smoke, alternate_local_hint_hardening_smoke, alternate_local_hint_live_readonly_smoke, alternate_local_hint_approved_application_smoke, alternate_local_hint_multi_tick_replay_smoke, agent_movement_policy_consolidation_fixture_smoke, agent_movement_policy_boundary_hardening_smoke, agent_movement_policy_consolidated_replay_regression_smoke, bounded_path_planning_fixture_smoke, bounded_path_planning_hardening_smoke, bounded_path_planning_to_tick_first_step_smoke, bounded_path_planning_approved_application_smoke, bounded_path_planning_multi_tick_replay_smoke, agent_movement_stack_contract_fixture_smoke, agent_movement_stack_contract_boundary_hardening_smoke, agent_movement_stack_replay_regression_adapter_smoke, agent_movement_stack_metrics_event_compatibility_smoke, agent_movement_stack_consolidated_multi_tick_replay_smoke, world_observation_smoke, world_observation_multi_smoke, terrain_scan_smoke, terrain_scan_edge_smoke, terrain_column_scan_smoke, terrain_column_scan_edge_smoke, terrain_pathfinding_column_smoke, terrain_pathfinding_column_edge_smoke, terrain_pathfinding_column_positive_smoke, terrain_path_live_movement_smoke, terrain_path_movement_fixture_smoke, terrain_collision_fixture_smoke, terrain_collision_live_readonly_smoke, terrain_semantics_fixture_smoke, terrain_traversability_fixture_smoke, terrain_pathfinding_fixture_smoke
      --chunk-radius <Int> Chunk radius for chunk_smoke. Default: 0. Supported: 0...1
      --agents <Int>       Agent count for agents_basic and long_run_smoke. Default: 2, or 10 for long_run_smoke. Supported: 1...100
      --event-rate <Int>   Write frequent events every N ticks. Default: 1
      --log-world-ticks <Bool>
                           Write world_tick events. Default: true
      --out <path>         Directory where run outputs are written.
      --help               Show this help and exit.
    """
}

func fail(_ message: String) -> Never {
    print("PebbleLab error: \(message)")
    print("Run `PebbleLab --help` for usage.")
    exit(1)
}

func parseArguments(_ arguments: [String]) -> Options {
    var options = Options()
    var index = 1

    while index < arguments.count {
        let argument = arguments[index]

        switch argument {
        case "--":
            break
        case "--help":
            print(usage())
            exit(0)
        case "--seed":
            index += 1
            guard index < arguments.count else { fail("missing value for --seed") }
            guard let seed = UInt32(arguments[index]) else {
                fail("invalid UInt32 value for --seed: \(arguments[index])")
            }
            options.seed = seed
        case "--ticks":
            index += 1
            guard index < arguments.count else { fail("missing value for --ticks") }
            guard let ticks = Int(arguments[index]), ticks >= 0 else {
                fail("invalid non-negative Int value for --ticks: \(arguments[index])")
            }
            options.ticks = ticks
        case "--scenario":
            index += 1
            guard index < arguments.count else { fail("missing value for --scenario") }
            options.scenario = arguments[index]
        case "--chunk-radius":
            index += 1
            guard index < arguments.count else { fail("missing value for --chunk-radius") }
            guard let radius = Int(arguments[index]) else {
                fail("invalid Int value for --chunk-radius: \(arguments[index])")
            }
            guard radius >= 0 else {
                fail("invalid --chunk-radius \(radius): must be non-negative")
            }
            guard radius <= 1 else {
                fail("invalid --chunk-radius \(radius): supported range is 0...1")
            }
            options.chunkRadius = radius
            options.chunkRadiusProvided = true
        case "--agents":
            index += 1
            guard index < arguments.count else { fail("missing value for --agents") }
            guard let agents = Int(arguments[index]) else {
                fail("invalid Int value for --agents: \(arguments[index])")
            }
            guard agents >= 1 else {
                fail("invalid --agents \(agents): must be at least 1")
            }
            guard agents <= 100 else {
                fail("invalid --agents \(agents): supported range is 1...100")
            }
            options.agents = agents
            options.agentsProvided = true
        case "--event-rate":
            index += 1
            guard index < arguments.count else { fail("missing value for --event-rate") }
            guard let eventRate = Int(arguments[index]) else {
                fail("invalid Int value for --event-rate: \(arguments[index])")
            }
            guard eventRate >= 1 else {
                fail("invalid --event-rate \(eventRate): must be at least 1")
            }
            options.eventRate = eventRate
        case "--log-world-ticks":
            index += 1
            guard index < arguments.count else { fail("missing value for --log-world-ticks") }
            switch arguments[index].lowercased() {
            case "true", "yes", "1":
                options.logWorldTicks = true
            case "false", "no", "0":
                options.logWorldTicks = false
            default:
                fail("invalid Bool value for --log-world-ticks: \(arguments[index])")
            }
        case "--out":
            index += 1
            guard index < arguments.count else { fail("missing value for --out") }
            options.outPath = arguments[index]
        default:
            fail("unknown argument: \(argument)")
        }

        index += 1
    }

    return options
}
