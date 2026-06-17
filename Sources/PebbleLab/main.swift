import Foundation
import PebbleCore

struct Options {
    var seed: UInt32 = 12345
    var ticks: Int = 20
    var scenario = "empty"
    var outPath: String?
}

struct RunConfig: Encodable {
    let scenario: String
    let seed: UInt32
    let ticks: Int
    let outPath: String?
}

struct RunMetrics: Encodable {
    let scenario: String
    let seed: UInt32
    let ticksRequested: Int
    let ticksCompleted: Int
    let worldTime: Int
    let success: Bool
}

struct RunEvent: Encodable {
    let type: String
    let tick: Int
    let scenario: String?
    let seed: UInt32?
    let ticksRequested: Int?
    let worldTime: Int?
    let success: Bool?
}

func usage() -> String {
    """
    PebbleLab - headless PebbleCore simulation runner

    Usage:
      PebbleLab [--seed <UInt32>] [--ticks <Int>] [--scenario empty] [--out <path>]
      PebbleLab --help

    Options:
      --seed <UInt32>      World seed. Default: 12345
      --ticks <Int>        Number of ticks to run. Default: 20
      --scenario <String>  Scenario name. Currently supported: empty
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

let options = parseArguments(CommandLine.arguments)

guard options.scenario == "empty" else {
    fail("unsupported scenario: \(options.scenario). Currently supported: empty")
}

func writeJSON<T: Encodable>(_ value: T, to url: URL) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(value)
    try data.write(to: url, options: .atomic)
}

func encodeEventLine(_ event: RunEvent) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(event)
    guard let line = String(data: data, encoding: .utf8) else {
        throw CocoaError(.fileWriteInapplicableStringEncoding)
    }
    return line + "\n"
}

let world = World(dim: .overworld, seed: options.seed)

var ticksCompleted = 0
var eventsNDJSON = ""

if options.outPath != nil {
    do {
        eventsNDJSON += try encodeEventLine(RunEvent(
            type: "run_started",
            tick: 0,
            scenario: options.scenario,
            seed: options.seed,
            ticksRequested: options.ticks,
            worldTime: nil,
            success: nil
        ))
    } catch {
        fail("failed to encode run_started event: \(error)")
    }
}

for _ in 0..<options.ticks {
    world.tick()
    ticksCompleted += 1

    if options.outPath != nil {
        do {
            eventsNDJSON += try encodeEventLine(RunEvent(
                type: "world_tick",
                tick: ticksCompleted,
                scenario: nil,
                seed: nil,
                ticksRequested: nil,
                worldTime: world.time,
                success: nil
            ))
        } catch {
            fail("failed to encode world_tick event: \(error)")
        }
    }
}

if options.outPath != nil {
    do {
        eventsNDJSON += try encodeEventLine(RunEvent(
            type: "run_finished",
            tick: ticksCompleted,
            scenario: nil,
            seed: nil,
            ticksRequested: nil,
            worldTime: world.time,
            success: true
        ))
    } catch {
        fail("failed to encode run_finished event: \(error)")
    }
}

if let outPath = options.outPath {
    let outURL = URL(fileURLWithPath: outPath, isDirectory: true)

    do {
        try FileManager.default.createDirectory(at: outURL, withIntermediateDirectories: true)
        try writeJSON(
            RunConfig(
                scenario: options.scenario,
                seed: options.seed,
                ticks: options.ticks,
                outPath: outPath
            ),
            to: outURL.appendingPathComponent("config.json")
        )
        try writeJSON(
            RunMetrics(
                scenario: options.scenario,
                seed: options.seed,
                ticksRequested: options.ticks,
                ticksCompleted: ticksCompleted,
                worldTime: world.time,
                success: true
            ),
            to: outURL.appendingPathComponent("metrics.json")
        )
        try eventsNDJSON.write(
            to: outURL.appendingPathComponent("events.ndjson"),
            atomically: true,
            encoding: .utf8
        )
    } catch {
        fail("failed to write run outputs to \(outPath): \(error)")
    }
}

print("PebbleLab headless scenario=\(options.scenario) dim=\(world.dim.rawValue) seed=\(world.seed) ticks=\(world.time)")
