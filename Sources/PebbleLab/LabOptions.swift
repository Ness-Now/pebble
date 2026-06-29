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
      --seed <UInt32>      World seed. Default: 12345
      --ticks <Int>        Number of ticks to run. Default: 20
      --scenario <String>  Scenario name. Currently supported: empty, chunk_smoke, agent_smoke, agents_basic, seek_safety_smoke, long_run_smoke, regression_smoke, physical_placeholder_smoke, physical_sync_smoke, core_entity_smoke, physical_behavior_smoke, physical_behavior_multi_smoke, physical_movement_denied_smoke, physical_movement_find_occupable_smoke, physical_movement_approved_single_step_smoke, physical_movement_single_step_hardening_smoke, route_following_fixture_smoke, route_following_denied_live_smoke, route_following_approved_two_step_smoke, route_following_live_hardening_smoke, multi_agent_movement_fixture_smoke, multi_agent_movement_fixture_hardening_smoke, multi_agent_live_collision_intent_smoke, multi_agent_approved_physical_movement_smoke, multi_agent_movement_hardening_smoke, multi_agent_movement_tick_fixture_smoke, multi_agent_movement_tick_live_readonly_smoke, multi_agent_movement_tick_approved_application_smoke, multi_agent_movement_tick_hardening_smoke, agent_intent_production_fixture_smoke, agent_intent_production_hardening_smoke, agent_intent_to_tick_fixture_smoke, agent_intent_to_tick_live_readonly_smoke, agent_intent_to_tick_approved_application_smoke, agent_feedback_consumption_fixture_smoke, agent_feedback_consumption_hardening_smoke, feedback_to_agent_intent_context_fixture_smoke, feedback_to_agent_intent_context_hardening_smoke, feedback_aware_intent_policy_fixture_smoke, feedback_aware_intent_policy_hardening_smoke, feedback_aware_intent_to_tick_fixture_smoke, feedback_aware_intent_to_tick_live_readonly_smoke, world_observation_smoke, world_observation_multi_smoke, terrain_scan_smoke, terrain_scan_edge_smoke, terrain_column_scan_smoke, terrain_column_scan_edge_smoke, terrain_pathfinding_column_smoke, terrain_pathfinding_column_edge_smoke, terrain_pathfinding_column_positive_smoke, terrain_path_live_movement_smoke, terrain_path_movement_fixture_smoke, terrain_collision_fixture_smoke, terrain_collision_live_readonly_smoke, terrain_semantics_fixture_smoke, terrain_traversability_fixture_smoke, terrain_pathfinding_fixture_smoke
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
