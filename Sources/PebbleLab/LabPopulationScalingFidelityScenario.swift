import Darwin
import Foundation
import PebbleAgents

private struct CIV39ScaleMeasurement: Encodable {
    let mode: String
    let populationCount: Int
    let settlementCount: Int
    let ticks: Int
    let liveCount: Int
    let nearCount: Int
    let dormantCount: Int
    let wallNanoseconds: UInt64
    let cpuUserMicroseconds: Int64
    let cpuSystemMicroseconds: Int64
    let representativePeakRSSBytes: Int64
    let checkpointBytes: Int
    let restoreNanoseconds: UInt64
    let retainedAgentCount: Int
    let retainedFidelityTransitions: Int
    let evictedFidelityTransitions: UInt64
    let liveCognitionExecutions: UInt64
    let nearMaintenanceExecutions: UInt64
    let dormantMaintenanceExecutions: UInt64
    let skippedFullCognitionExecutions: UInt64
    let checkpointSchema: Int
    let durableDigest: String
    let scaleDigest: String
    let restoreExact: Bool
}

private struct CIV39ScaleEnvironment: Encodable {
    let command: String
    let operatingSystem: String
    let processorCount: Int
    let activeProcessorCount: Int
    let physicalMemoryBytes: UInt64
    let swiftBuildConfiguration: String
    let timer: String
    let memorySource: String
}

private struct CIV39ScaleReport: Encodable {
    let schemaVersion: Int
    let scenario: String
    let seed: UInt32
    let success: Bool
    let environment: CIV39ScaleEnvironment
    let measurements: [CIV39ScaleMeasurement]
    let assertions: [String: Bool]
    let limitations: [String]
}

private struct CIV39DeterminismReport: Encodable {
    let durableBytesDeterministic: Bool
    let tierDigestDeterministic: Bool
    let digest: String
}

private struct CIV39ResourceUsage {
    let userMicroseconds: Int64
    let systemMicroseconds: Int64
    let peakRSSBytes: Int64
}

private final class CIV39RestoreBox: @unchecked Sendable {
    var bytes: Data?
}

private func civ39RestoreBytes(
    _ checkpoint: AgentSessionCheckpoint
) -> (bytes: Data, nanoseconds: UInt64) {
    let box = CIV39RestoreBox()
    let before = DispatchTime.now().uptimeNanoseconds
    let thread = Thread {
        let restored = try! AgentSimulationSession.restoring(checkpoint)
        box.bytes = try! restored.durableStateBytes()
    }
    // PebbleLab's historical monolithic debug entry point has a large main
    // stack frame. A fresh-process-style worker gives schema validation its
    // own explicit bounded stack and makes the measurement reproducible.
    thread.stackSize = 32 * 1_024 * 1_024
    thread.start()
    while !thread.isFinished { Thread.sleep(forTimeInterval: 0.001) }
    let after = DispatchTime.now().uptimeNanoseconds
    return (box.bytes!, after - before)
}

private let civ39LabEastID = AgentSettlementID(
    rawValue: "settlement-east"
)!

private func civ39LabUsage() -> CIV39ResourceUsage {
    var usage = rusage()
    _ = getrusage(RUSAGE_SELF, &usage)
    func microseconds(_ value: timeval) -> Int64 {
        Int64(value.tv_sec) * 1_000_000 + Int64(value.tv_usec)
    }
    return CIV39ResourceUsage(
        userMicroseconds: microseconds(usage.ru_utime),
        systemMicroseconds: microseconds(usage.ru_stime),
        // Darwin reports ru_maxrss in bytes.
        peakRSSBytes: Int64(usage.ru_maxrss)
    )
}

private func civ39LabAgent(
    _ id: String, ordinal: Int
) -> AgentSessionAgentState {
    let position = AgentPosition(
        x: (ordinal % 16) * 2,
        y: 64,
        z: (ordinal / 16) * 2
    )
    return AgentSessionAgentState(
        id: id, state: "idle", position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "CIV-39 measured fixture",
            startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [],
        tickCreated: 0, ticksAlive: ordinal,
        observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0,
        actionCount: 0, actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func civ39LabSession(
    seed: UInt32,
    population: Int,
    mode: String
) -> AgentSimulationSession {
    let liveCount = mode == "full" ? population : 4
    let nearCount = mode == "full" ? 1 : 12
    let configuration = try! AgentPopulationScaleConfiguration(
        maximumSettlements: 2,
        maximumLiveAgents: liveCount,
        maximumNearAgents: nearCount,
        nearMaintenanceCadence: 4,
        dormantMaintenanceCadence: 16,
        rotationIntervalTicks: 8,
        maximumFidelityTransitionHistory: 128,
        maximumSettlementMigrationHistory: 16,
        maximumConcurrentSettlementMigrations: 1,
        maximumSettlementMigrationRouteLength: 32
    )
    let simulationID = try! AgentSimulationID(
        validating: "civ39-scale-\(mode)-\(population)-\(seed)"
    )
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: seed,
            nearbyRadius: 8,
            resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 32)
        ),
        agents: [
            civ39LabAgent("agent_0", ordinal: 0),
            civ39LabAgent("agent_1", ordinal: 1),
            civ39LabAgent("agent_2", ordinal: 2),
        ],
        simulationID: simulationID,
        causalLedgerPolicy: .bounded(maxEvents: 65_536)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: -2),
        configuration: try! AgentPopulationConfiguration(
            maximumActivePopulation: population,
            maximumMigrationRecords: 16
        )
    )
    let admissions = (3..<population).map { ordinal in
        AgentScaledResidentAdmission(
            state: civ39LabAgent(
                String(format: "agent_%03d", ordinal), ordinal: ordinal
            ),
            settlementID: ordinal.isMultiple(of: 2)
                ? .main : civ39LabEastID
        )
    }
    try! session.initializePopulationScaling(
        additionalSettlements: [AgentPopulationSettlement(
            settlementID: civ39LabEastID,
            anchor: AgentPosition(x: 32, y: 64, z: 16),
            receptionPosition: AgentPosition(x: 32, y: 64, z: 18),
            capacity: population, residentIDs: [], inTransitIDs: []
        )],
        additionalResidents: admissions,
        configuration: configuration
    )
    return session
}

private func civ39Measure(
    seed: UInt32,
    population: Int,
    mode: String,
    ticks: Int,
    artifactRoot: URL? = nil
) -> CIV39ScaleMeasurement {
    var session = civ39LabSession(
        seed: seed, population: population, mode: mode
    )
    let usageBefore = civ39LabUsage()
    let wallBefore = DispatchTime.now().uptimeNanoseconds
    for _ in 0..<ticks { _ = try! session.advanceTick() }
    let wallAfter = DispatchTime.now().uptimeNanoseconds
    let usageAfterTicks = civ39LabUsage()
    let checkpoint = try! session.makeCheckpoint()
    let checkpointBytes = try! AgentCheckpointCodec.encode(checkpoint)
    let restore = civ39RestoreBytes(checkpoint)
    let usageAfterRestore = civ39LabUsage()
    let scale = session.populationScaleSnapshot()
    let durable = try! session.durableStateDigest()
    let sessionBytes = try! session.durableStateBytes()
    if let artifactRoot {
        try! AgentCheckpointCodec.encode(checkpoint).write(
            to: artifactRoot.appendingPathComponent(
                "largest_tiered_checkpoint_v35.json"
            ), options: .atomic
        )
        try! civ39WriteJSON(
            scale,
            to: artifactRoot.appendingPathComponent(
                "largest_tiered_scale.json"
            )
        )
    }
    return CIV39ScaleMeasurement(
        mode: mode,
        populationCount: population,
        settlementCount: scale.settlements.count,
        ticks: ticks,
        liveCount: scale.liveCount,
        nearCount: scale.nearCount,
        dormantCount: scale.dormantCount,
        wallNanoseconds: wallAfter - wallBefore,
        cpuUserMicroseconds: usageAfterTicks.userMicroseconds
            - usageBefore.userMicroseconds,
        cpuSystemMicroseconds: usageAfterTicks.systemMicroseconds
            - usageBefore.systemMicroseconds,
        representativePeakRSSBytes: usageAfterRestore.peakRSSBytes,
        checkpointBytes: checkpointBytes.count,
        restoreNanoseconds: restore.nanoseconds,
        retainedAgentCount: checkpoint.durableState.agents.count,
        retainedFidelityTransitions: scale.fidelityTransitions.count,
        evictedFidelityTransitions: scale.evictedFidelityTransitionCount,
        liveCognitionExecutions: scale.workCounters.liveCognitionExecutions,
        nearMaintenanceExecutions:
            scale.workCounters.nearMaintenanceExecutions,
        dormantMaintenanceExecutions:
            scale.workCounters.dormantMaintenanceExecutions,
        skippedFullCognitionExecutions:
            scale.workCounters.skippedFullCognitionExecutions,
        checkpointSchema: checkpoint.schemaVersion,
        durableDigest: durable.rawValue,
        scaleDigest: scale.digest,
        restoreExact: restore.bytes == sessionBytes
    )
}

private func civ39WriteJSON<T: Encodable>(_ value: T, to url: URL) throws {
    try (AgentCheckpointCodec.encode(value) + Data([0x0a])).write(
        to: url, options: .atomic
    )
}

func runPopulationScalingFidelitySmoke(_ options: Options) -> Never {
    guard let outPath = options.outPath else {
        fail("population_scaling_fidelity_smoke requires an explicit --out directory")
    }
    guard options.ticks >= 16 else {
        fail("population_scaling_fidelity_smoke requires --ticks >= 16")
    }
    let root = URL(fileURLWithPath: outPath, isDirectory: true)
    do {
        try FileManager.default.createDirectory(
            at: root, withIntermediateDirectories: true
        )
        guard try FileManager.default.contentsOfDirectory(
            atPath: root.path
        ).isEmpty else {
            fail("population scaling output directory must be empty: \(outPath)")
        }
    } catch {
        fail("failed to prepare population scaling output: \(error)")
    }

    let sizes = [24, 64, 128]
    var measurements: [CIV39ScaleMeasurement] = []
    for population in sizes {
        measurements.append(civ39Measure(
            seed: options.seed, population: population,
            mode: "full", ticks: options.ticks
        ))
        measurements.append(civ39Measure(
            seed: options.seed, population: population,
            mode: "tiered", ticks: options.ticks,
            artifactRoot: population == sizes.last ? root : nil
        ))
    }

    var deterministicA = civ39LabSession(
        seed: options.seed, population: 128, mode: "tiered"
    )
    var deterministicB = civ39LabSession(
        seed: options.seed, population: 128, mode: "tiered"
    )
    for _ in 0..<options.ticks {
        _ = try! deterministicA.advanceTick()
        _ = try! deterministicB.advanceTick()
    }
    let deterministicBytes = try! deterministicA.durableStateBytes()
        == deterministicB.durableStateBytes()
    let deterministicDigest = deterministicA.populationScaleSnapshot().digest
        == deterministicB.populationScaleSnapshot().digest

    let grouped = Dictionary(grouping: measurements, by: \.populationCount)
    let workBounded = sizes.allSatisfy { population in
        guard let rows = grouped[population],
              let full = rows.first(where: { $0.mode == "full" }),
              let tiered = rows.first(where: { $0.mode == "tiered" })
        else { return false }
        return full.liveCognitionExecutions
                == UInt64(population * options.ticks)
            && tiered.liveCognitionExecutions == UInt64(4 * options.ticks)
            && tiered.skippedFullCognitionExecutions
                == UInt64((population - 4) * options.ticks)
    }
    let assertions = [
        "all_schema_35": measurements.allSatisfy { $0.checkpointSchema == 35 },
        "all_restore_exact": measurements.allSatisfy(\.restoreExact),
        "all_two_settlements": measurements.allSatisfy {
            $0.settlementCount == 2
        },
        "all_populations_retained": measurements.allSatisfy {
            $0.populationCount == $0.retainedAgentCount
        },
        "tiered_work_is_bounded": workBounded,
        "tier_assignment_deterministic": deterministicDigest,
        "durable_bytes_deterministic": deterministicBytes,
        "transition_history_bounded": measurements.allSatisfy {
            $0.retainedFidelityTransitions <= 128
        },
    ]
    let report = CIV39ScaleReport(
        schemaVersion: 1,
        scenario: options.scenario,
        seed: options.seed,
        success: assertions.values.allSatisfy { $0 },
        environment: CIV39ScaleEnvironment(
            command: CommandLine.arguments.joined(separator: " "),
            operatingSystem: ProcessInfo.processInfo
                .operatingSystemVersionString,
            processorCount: ProcessInfo.processInfo.processorCount,
            activeProcessorCount: ProcessInfo.processInfo.activeProcessorCount,
            physicalMemoryBytes: ProcessInfo.processInfo.physicalMemory,
            swiftBuildConfiguration: "SwiftPM debug product",
            timer: "DispatchTime monotonic uptime nanoseconds",
            memorySource: "Darwin getrusage(RUSAGE_SELF).ru_maxrss; "
                + "representative process peak, cumulative per process"
        ),
        measurements: measurements,
        assertions: assertions,
        limitations: [
            "One local-machine baseline; no universal performance guarantee.",
            "Peak RSS is process-cumulative, not per-configuration allocation.",
            "Restore time includes launching a fresh 32 MiB-stack worker thread to isolate the historical PebbleLab main frame.",
            "NEAR and DORMANT V1 maintenance records cadence work only; they do not synthesize exact physical events.",
        ]
    )
    do {
        try civ39WriteJSON(
            report,
            to: root.appendingPathComponent("scale_measurements.json")
        )
        try civ39WriteJSON(
            CIV39DeterminismReport(
                durableBytesDeterministic: deterministicBytes,
                tierDigestDeterministic: deterministicDigest,
                digest: deterministicA.populationScaleSnapshot().digest
            ),
            to: root.appendingPathComponent("determinism.json")
        )
    } catch {
        fail("failed to write population scaling outputs: \(error)")
    }
    guard report.success else {
        for key in assertions.keys.sorted() where assertions[key] == false {
            print("FAIL \(key)")
        }
        exit(1)
    }
    print(
        "population_scaling_fidelity_smoke PASS configurations="
            + "\(measurements.count) populations=24,64,128 ticks="
            + "\(options.ticks) deterministic=1"
    )
    exit(0)
}
