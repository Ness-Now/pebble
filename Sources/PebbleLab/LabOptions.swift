import Foundation

struct Options {
    var seed: UInt32 = 12345
    var ticks: Int = 20
    var scenario = "empty"
    var outPath: String?
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
      --scenario <String>  Scenario name. Currently supported: empty, chunk_smoke
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
