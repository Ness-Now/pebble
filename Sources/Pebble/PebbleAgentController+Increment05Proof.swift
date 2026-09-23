import Foundation
import PebbleAgents
import PebbleCore

private struct PebbleIncrement05ControllerEvidence: Equatable {
    let hunger: Double
    let fatigue: Double
    let age: Int
    let energy: Int
    let stress: Int
    let health: Int
    let deathCount: Int
    let elapsedWorldTicks: Int
    let remainderWorldTicks: Int
    let appliedBoundaries: Int
    let pendingBoundaries: Int
}

private struct PebbleIncrement05ControllerFixture {
    let controller: PebbleAgentController
    let world: World
    let player: Player
    let coverageRequest: PhysicalSimulationCoverageRequest
}

private struct PebbleIncrement05FailedAttemptEvidence {
    let fixture: PebbleIncrement05ControllerFixture
    let recordCount: Int
    let replayVerified: Bool
}

/// Disposable, launch-gated proof of the real Pebble controller scheduling
/// boundary. It creates no normal product command or persistent authority.
extension PebbleAgentController {
    func traceIncrement05NaturalCharacterization(
        world: World,
        startWorldTick: Int
    ) -> Bool {
        guard environment[
            "PEBBLELAB_PS01_INCREMENT05_CHARACTERIZATION"
        ] == "1", activeWorld === world, let session else {
            return false
        }
        let snapshot = session.snapshot()
        let agents = snapshot.agents
        let living = agents.filter(\.isAlive)
        let hunger = living.map { $0.needs.hunger }
        let fatigue = living.map { $0.needs.fatigue }
        let health = living.map(\.health)
        let restCount = living.reduce(0) {
            $0 + ($1.survivalProgress?.restTicks ?? 0)
        }
        let food = session.physicalFoodSurvivalSnapshot()
        let wild = session.wildSubsistenceSnapshot()
        let berryAcquisitions = wild.retainedOutcomes.filter { record in
            record.outcome.status == .succeeded
                && record.outcome.acquiredItems.contains {
                    $0.identity.itemKey == "sweet_berries"
                }
        }.count
        let berryOpportunities = wild.opportunities.filter {
            $0.edibleSourceEvidence?
                .canonicalMaterialName == "sweet_berries"
        }.count
        let physiological = session.physiologicalTimeSnapshot()
        let causal = session.causalLedgerSnapshot()
        let population = session.populationSnapshot()
        let membershipAuthorities = causal.events.filter {
            $0.kind == .populationMembershipAuthorityRetained
        }
        let currentMembershipAuthority = membershipAuthorities.last?.eventID
        let agent0Registration = population.members.first {
            $0.agentID.rawValue == "agent_0"
        }?.registrationEventID
        let ecological = session.ecologicalObservationSnapshot()
        let line = "PS01_INCREMENT_05_NATURAL_CHARACTERIZATION "
            + "seed=\(world.seed) founders=\(snapshot.agentCount) "
            + "living=\(living.count) deaths="
            + "\(session.mortalitySnapshot().totalDeathCount) "
            + "worldTicks=\(world.time - startWorldTick) "
            + "worldStart=\(startWorldTick) worldEnd=\(world.time) "
            + "worldDayFraction="
            + String(format: "%.6f", Double(world.time - startWorldTick) / 24_000)
            + " civilizationTicks=\(session.tick) "
            + "boundaries=\(physiological.appliedBoundaryCount) "
            + "pending=\(physiological.pendingBoundaryCount) "
            + "remainder=\(physiological.remainderWorldTicks) "
            + "hungerMin=\(String(format: "%.2f", hunger.min() ?? 0)) "
            + "hungerMax=\(String(format: "%.2f", hunger.max() ?? 0)) "
            + "fatigueMin=\(String(format: "%.2f", fatigue.min() ?? 0)) "
            + "fatigueMax=\(String(format: "%.2f", fatigue.max() ?? 0)) "
            + "healthMin=\(health.min() ?? 0) "
            + "healthMax=\(health.max() ?? 0) "
            + "berryOpportunities=\(berryOpportunities) "
            + "berryAcquisitions=\(berryAcquisitions) "
            + "consumptions=\(food?.totalConsumedQuantity ?? 0) "
            + "restBoundaries=\(restCount) "
            + "causalRetained=\(causal.summary.retainedEventCount) "
            + "causalDropped=\(causal.summary.droppedEventCount) "
            + "causalFirst="
            + "\(causal.summary.firstRetainedEventID?.rawValue ?? "none") "
            + "causalLast="
            + "\(causal.summary.lastRetainedEventID?.rawValue ?? "none") "
            + "agent0RegistrationRetained="
            + "\(agent0Registration.map { id in causal.events.contains { $0.eventID == id } } == true ? 1 : 0) "
            + "currentMembershipAuthority="
            + "\(currentMembershipAuthority?.rawValue ?? "none") "
            + "retainedMembershipAuthorities=\(membershipAuthorities.count) "
            + "ecologicalRetained=\(ecological.observations.count) "
            + "ecologicalEvicted="
            + "\(ecological.evictionCounts.observations) "
            + "fatalIntegrity=\(fatalSessionIntegrityFailure == nil ? 0 : 1) "
            + "runtimeErrors=\(runtimeErrorCount) "
            + "catchUpDropped=\(droppedCatchUpSteps)"
        trace(line)
        print("[ps01-i05-natural] \(line)")
        return true
    }

    func handleIncrement05TemporalProof() -> PebbleAgentCommandResult {
        guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1" else {
            return failure(
                "Increment 05 temporal proof requires a disposable World."
            )
        }
        do {
            let result = try runIncrement05TemporalControllerProof()
            print("[ps01-i05-temporal] \(result)")
            return success(result)
        } catch {
            print("[ps01-i05-temporal] FAIL \(error)")
            return failure("Increment 05 temporal proof failed: \(error)")
        }
    }

    private func runIncrement05TemporalControllerProof() throws -> String {
        let frequencyFixtures = try [1, 2, 4, 8].map {
            try runIncrement05ControllerSchedule(hz: $0)
        }
        let reference = try increment05ControllerEvidence(
            frequencyFixtures[0].controller
        )
        let frequencyEvidence = try frequencyFixtures.map {
            try increment05ControllerEvidence($0.controller)
        }
        try requireIncrement05TemporalProof(
            frequencyEvidence.allSatisfy { $0 == reference }
                && frequencyFixtures.map {
                    $0.controller.session?.tick ?? -1
                } == [60, 120, 240, 480],
            "controller 1/2/4/8 Hz invariance"
        )

        let speed = try makeIncrement05ControllerFixture()
        for (hz, endTick) in [(4, 300), (8, 600), (2, 900), (4, 1_200)] {
            let speedResult = speed.controller.handleCommand(
                ["speed", "\(hz)"], world: speed.world, player: speed.player
            )
            try requireIncrement05TemporalProof(
                speedResult.succeeded, "speed \(hz) command"
            )
            try advanceIncrement05Controller(
                speed, throughWorldTick: endTick
            )
        }
        try requireIncrement05TemporalProof(
            try increment05ControllerEvidence(speed.controller) == reference
                && speed.controller.session?.tick == 270,
            "controller mid-run speed invariance"
        )

        let step = try makeIncrement05ControllerFixture()
        let stepBefore = try increment05ControllerEvidence(step.controller)
        for _ in 0..<32 {
            let result = step.controller.handleCommand(
                ["step"], world: step.world, player: step.player
            )
            try requireIncrement05TemporalProof(
                result.succeeded, "cognitive step"
            )
        }
        try requireIncrement05TemporalProof(
            try increment05ControllerEvidence(step.controller) == stepBefore
                && step.controller.session?.tick == 32,
            "controller cognitive step grants no biology"
        )

        let frozen = try makeIncrement05ControllerFixture()
        try advanceIncrement05Controller(frozen, throughWorldTick: 600)
        let frozenBefore = try increment05ControllerEvidence(
            frozen.controller
        )
        for _ in 0..<64 {
            frozen.controller.update(
                world: frozen.world, player: frozen.player
            )
        }
        try requireIncrement05TemporalProof(
            try increment05ControllerEvidence(frozen.controller)
                == frozenBefore,
            "frozen World freezes physiology"
        )
        try advanceIncrement05Controller(frozen, throughWorldTick: 1_200)
        try requireIncrement05TemporalProof(
            try increment05ControllerEvidence(frozen.controller) == reference,
            "frozen World resumes without debt"
        )

        let labPause = try makeIncrement05ControllerFixture()
        try advanceIncrement05Controller(labPause, throughWorldTick: 600)
        let paused = labPause.controller.handleCommand(
            ["pause"], world: labPause.world, player: labPause.player
        )
        try requireIncrement05TemporalProof(
            paused.succeeded, "lab pause entry"
        )
        for tick in 601...1_200 {
            labPause.world.time = tick
            labPause.controller.update(
                world: labPause.world, player: labPause.player
            )
        }
        let resumed = labPause.controller.handleCommand(
            ["resume"], world: labPause.world, player: labPause.player
        )
        try requireIncrement05TemporalProof(
            resumed.succeeded, "lab pause resume"
        )
        try advanceIncrement05Controller(labPause, throughWorldTick: 1_800)
        try requireIncrement05TemporalProof(
            try increment05ControllerEvidence(labPause.controller) == reference
                && labPause.controller.session?.tick == 240,
            "lab pause excludes suspended World time"
        )

        let pending = try makeIncrement05ControllerFixture()
        try advanceIncrement05Controller(pending, throughWorldTick: 600)
        pending.world.removeChunk(-1, -1)
        for tick in 601...1_199 {
            pending.world.time = tick
            pending.world.applyPhysicalSimulationCoverage(
                pending.coverageRequest
            )
            try requireIncrement05TemporalProof(
                pending.world.physicalSimulationCoverage.status == .pending,
                "coverage pending state"
            )
            pending.controller.update(
                world: pending.world, player: pending.player
            )
        }
        installIncrement05Chunk(in: pending.world, x: -1, z: -1)
        pending.world.applyPhysicalSimulationCoverage(
            pending.coverageRequest
        )
        try advanceIncrement05Controller(pending, throughWorldTick: 1_204)
        let pendingEvidence = try increment05ControllerEvidence(
            pending.controller
        )
        try requireIncrement05TemporalProof(
            pendingEvidence.appliedBoundaries == 1
                && pendingEvidence.remainderWorldTicks == 4
                && pendingEvidence.hunger == 0.05
                && pendingEvidence.fatigue == 0.06,
            "coverage pending retains eligible biology"
        )

        let refused = try makeIncrement05ControllerFixture()
        try advanceIncrement05Controller(refused, throughWorldTick: 600)
        let refusedChunk = PhysicalSimulationChunk(x: -1, z: -1)
        for tick in 601...1_199 {
            refused.world.time = tick
            refused.world.applyPhysicalSimulationCoverage(
                refused.coverageRequest,
                refusedChunks: [refusedChunk]
            )
            refused.controller.update(
                world: refused.world, player: refused.player
            )
        }
        refused.world.applyPhysicalSimulationCoverage(
            refused.coverageRequest
        )
        try advanceIncrement05Controller(refused, throughWorldTick: 1_204)
        let refusedEvidence = try increment05ControllerEvidence(
            refused.controller
        )
        try requireIncrement05TemporalProof(
            refusedEvidence.appliedBoundaries == 1
                && refusedEvidence.remainderWorldTicks == 4
                && refused.controller.runtimeErrorCount > 0,
            "coverage refusal retains eligible biology"
        )

        let oversized = try makeIncrement05ControllerFixture()
        oversized.world.removeChunk(-1, -1)
        for tick in 1...9_601 {
            oversized.world.time = tick
            oversized.world.applyPhysicalSimulationCoverage(
                oversized.coverageRequest
            )
            oversized.controller.update(
                world: oversized.world, player: oversized.player
            )
        }
        installIncrement05Chunk(in: oversized.world, x: -1, z: -1)
        oversized.world.applyPhysicalSimulationCoverage(
            oversized.coverageRequest
        )
        try advanceIncrement05Controller(
            oversized, throughWorldTick: 9_606
        )
        let oversizedEvidence = try increment05ControllerEvidence(
            oversized.controller
        )
        let oversizedLastError = oversized.controller.lastError ?? "none"
        try requireIncrement05TemporalProof(
            oversized.controller.runtimeErrorCount > 0
                && oversized.controller.lastError?.contains(
                    "elapsedWorldTickLimitExceeded"
                ) == true
                && oversized.controller.session?.tick == 0
                && oversizedEvidence.elapsedWorldTicks == 0,
            "oversized coverage catch-up fails closed "
                + "errors=\(oversized.controller.runtimeErrorCount) "
                + "last=\(oversizedLastError) "
                + "tick=\(oversized.controller.session?.tick ?? -1) "
                + "elapsed=\(oversizedEvidence.elapsedWorldTicks)"
        )

        let repeated = try makeIncrement05ControllerFixture()
        for _ in 0..<32 {
            repeated.controller.update(
                world: repeated.world, player: repeated.player
            )
        }
        try requireIncrement05TemporalProof(
            repeated.controller.session?.tick == 0
                && (try increment05ControllerEvidence(repeated.controller))
                    .elapsedWorldTicks == 0,
            "repeated World tick is idempotent"
        )

        let backward = try makeIncrement05ControllerFixture(
            initialWorldTick: 100
        )
        backward.world.time = 99
        backward.controller.update(
            world: backward.world, player: backward.player
        )
        try requireIncrement05TemporalProof(
            backward.controller.runtimeErrorCount == 1
                && backward.controller.isPaused
                && backward.controller.session?.tick == 0
                && (try increment05ControllerEvidence(backward.controller))
                    .elapsedWorldTicks == 0,
            "backward World tick fails closed"
        )

        let fatal = try makeIncrement05ControllerFixture()
        guard let fatalPublishedSession = fatal.controller.session else {
            throw ControllerError.homeostasisBoundary(
                "fatal-latch proof session missing"
            )
        }
        let fatalCheckpoint = try fatalPublishedSession.makeCheckpoint()
        fatal.controller.replayRecorder = try AgentReplayRecorder(
            checkpoint: fatalCheckpoint,
            session: fatalPublishedSession
        )
        let fatalSessionBytes = try fatalPublishedSession.durableStateBytes()
        let fatalRecorderBytes = try AgentReplayCodec.encodeRecords(
            fatal.controller.replayRecorder?.records ?? []
        )
        let fatalProbeState = fatal.controller.probesByAgentId["agent_0"]!
            .capturePhysicalState()
        let fatalWorldEntityIDs = fatal.world.entities.map(ObjectIdentifier.init)
        fatal.controller.increment05IntegrityFailureProofPending = true
        fatal.world.time = 5
        fatal.world.applyPhysicalSimulationCoverage(fatal.coverageRequest)
        fatal.controller.update(world: fatal.world, player: fatal.player)
        let fatalAfterSessionBytes = try fatal.controller.session?
            .durableStateBytes()
        let fatalAfterRecorderBytes = try AgentReplayCodec.encodeRecords(
            fatal.controller.replayRecorder?.records ?? []
        )
        try requireIncrement05TemporalProof(
            fatal.controller.increment05IntegrityFailureProofAttemptCount == 1
                && fatal.controller.runtimeErrorCount == 1
                && fatal.controller.fatalSessionIntegrityFailure != nil
                && fatal.controller.schedulingStatus.statusText.hasPrefix(
                    "fatal-integrity-halted("
                )
                && fatal.controller.session?.tick == 0
                && fatalAfterSessionBytes == fatalSessionBytes
                && fatalAfterRecorderBytes == fatalRecorderBytes
                && fatal.controller.probesByAgentId["agent_0"]?
                    .capturePhysicalState() == fatalProbeState
                && fatal.world.entities.map(ObjectIdentifier.init)
                    == fatalWorldEntityIDs,
            "integrity failure latches once after exact rollback"
        )
        for worldTick in 6...200 {
            fatal.world.time = worldTick
            fatal.world.applyPhysicalSimulationCoverage(
                fatal.coverageRequest
            )
            fatal.controller.update(world: fatal.world, player: fatal.player)
        }
        let fatalBeforeCommandSessionBytes = try fatal.controller.session?
            .durableStateBytes()
        let fatalBeforeCommandRecorderBytes = try AgentReplayCodec
            .encodeRecords(fatal.controller.replayRecorder?.records ?? [])
        let fatalBeforeCommandPhysiology = fatal.controller.session?
            .physiologicalTimeSnapshot()
        let fatalBeforeCommandTick = fatal.controller.session?.tick
        let fatalBeforeCommandLastWorldTick = fatal.controller.lastWorldTick
        let fatalBeforeCommandProbeState = fatal.controller
            .probesByAgentId["agent_0"]!.capturePhysicalState()
        let fatalBeforeCommandWorldEntityIDs = fatal.world.entities.map(
            ObjectIdentifier.init
        )
        let refusedFatalCommands = [
            ["pause"],
            ["resume"],
            ["step"],
            ["survival", "on"],
            ["speed", "8"],
        ]
        var fatalCommandGateExact = true
        for command in refusedFatalCommands {
            let result = fatal.controller.handleCommand(
                command, world: fatal.world, player: fatal.player
            )
            let sessionBytes = try fatal.controller.session?
                .durableStateBytes()
            let recorderBytes = try AgentReplayCodec.encodeRecords(
                fatal.controller.replayRecorder?.records ?? []
            )
            fatalCommandGateExact = fatalCommandGateExact
                && !result.succeeded
                && result.message.contains("fatally halted")
                && sessionBytes == fatalBeforeCommandSessionBytes
                && recorderBytes == fatalBeforeCommandRecorderBytes
                && fatal.controller.session?.tick == fatalBeforeCommandTick
                && fatal.controller.session?.physiologicalTimeSnapshot()
                    == fatalBeforeCommandPhysiology
                && fatal.controller.lastWorldTick
                    == fatalBeforeCommandLastWorldTick
                && fatal.controller.runtimeErrorCount == 1
                && fatal.controller.increment05IntegrityFailureProofAttemptCount
                    == 1
                && fatal.controller.probesByAgentId["agent_0"]?
                    .capturePhysicalState() == fatalBeforeCommandProbeState
                && fatal.world.entities.map(ObjectIdentifier.init)
                    == fatalBeforeCommandWorldEntityIDs
        }
        let fatalStatus = fatal.controller.handleCommand(
            ["status"], world: fatal.world, player: fatal.player
        )
        let fatalCausality = fatal.controller.handleCommand(
            ["causality", "status"],
            world: fatal.world,
            player: fatal.player
        )
        let fatalProlongedSessionBytes = try fatal.controller.session?
            .durableStateBytes()
        let fatalProlongedRecorderBytes = try AgentReplayCodec.encodeRecords(
            fatal.controller.replayRecorder?.records ?? []
        )
        try requireIncrement05TemporalProof(
            fatal.controller.increment05IntegrityFailureProofAttemptCount == 1
                && fatal.controller.runtimeErrorCount == 1
                && fatal.controller.session?.tick == 0
                && fatal.controller.replayRecorder?.records.isEmpty == true
                && fatalCommandGateExact
                && fatalStatus.succeeded
                && fatalStatus.message.contains("fatal-integrity-halted(")
                && fatalCausality.succeeded
                && fatalProlongedSessionBytes == fatalSessionBytes
                && fatalProlongedRecorderBytes == fatalRecorderBytes,
            "fatal command policy blocks mutation and preserves inspection"
        )
        let fatalStop = fatal.controller.handleCommand(
            ["stop"], world: fatal.world, player: fatal.player
        )
        try requireIncrement05TemporalProof(
            fatalStop.succeeded
                && fatal.controller.session == nil
                && fatal.controller.fatalSessionIntegrityFailure == nil,
            "explicit stop terminates the fatal execution context"
        )
        let restoredExecution = try makeIncrement05ControllerFixture()
        restoredExecution.controller.session = try AgentSimulationSession
            .restoring(fatalCheckpoint)
        restoredExecution.world.time = 5
        restoredExecution.world.applyPhysicalSimulationCoverage(
            restoredExecution.coverageRequest
        )
        restoredExecution.controller.update(
            world: restoredExecution.world,
            player: restoredExecution.player
        )
        try requireIncrement05TemporalProof(
            restoredExecution.controller.schedulingStatus == .running
                && restoredExecution.controller.session?.tick == 1
                && restoredExecution.controller.runtimeErrorCount == 0,
            "last valid checkpoint starts a fresh execution context"
        )

        let failedSchedules = try [1, 2, 4, 8].map {
            try runIncrement05FailedAttemptSchedule(hz: $0)
        }
        let failedReference = try increment05ControllerEvidence(
            failedSchedules[0].fixture.controller
        )
        let failedEvidence = try failedSchedules.map {
            try increment05ControllerEvidence($0.fixture.controller)
        }
        try requireIncrement05TemporalProof(
            failedEvidence.allSatisfy { $0 == failedReference }
                && failedSchedules.map {
                    $0.fixture.controller.session?.tick ?? -1
                } == [0, 0, 0, 0]
                && failedSchedules.map(\.recordCount)
                    == [60, 120, 240, 480]
                && failedSchedules.allSatisfy(\.replayVerified),
            "failed cognition preserves 1/2/4/8 Hz physiology and replay"
        )
        try requireIncrement05TemporalProof(
            failedReference.appliedBoundaries == 1
                && failedReference.remainderWorldTicks == 0
                && failedReference.hunger == 0.05
                && failedReference.fatigue == 0.06,
            "failed cognition publishes all due physiology"
        )

        let recovered = try makeIncrement05ControllerFixture()
        let recoveryBase = try recovered.controller.session!.makeCheckpoint()
        recovered.controller.replayRecorder = try AgentReplayRecorder(
            checkpoint: recoveryBase,
            session: recovered.controller.session!
        )
        for worldTick in stride(from: 5, through: 1_195, by: 5) {
            recovered.world.time = worldTick
            try requireIncrement05TemporalProof(
                recovered.controller
                    .publishEligiblePhysiologyAfterCompensatedFailure(
                        world: recovered.world,
                        publishedRecorder: recovered.controller.replayRecorder,
                        failure: "increment05-proof-path-readiness"
                    ),
                "failed cognition temporal publication before recovery"
            )
        }
        recovered.world.time = 1_200
        recovered.world.applyPhysicalSimulationCoverage(
            recovered.coverageRequest
        )
        try requireIncrement05TemporalProof(
            recovered.controller.advanceOneTick(
                world: recovered.world, player: recovered.player
            ),
            "cognition recovers after temporal-only publications"
        )
        let recoveredEvidence = try increment05ControllerEvidence(
            recovered.controller
        )
        try requireIncrement05TemporalProof(
            recovered.controller.session?.tick == 1
                && recoveredEvidence == reference
                && recovered.controller.replayRecorder?.records.count == 241,
            "recovery publishes one normal advance after 239 fallbacks "
                + "tick=\(recovered.controller.session?.tick ?? -1) "
                + "records=\(recovered.controller.replayRecorder?.records.count ?? -1) "
                + "recovered=\(recoveredEvidence) reference=\(reference)"
        )
        try verifyIncrement05ControllerReplay(
            controller: recovered.controller,
            checkpoint: recoveryBase,
            name: "increment-05-temporal-failure-recovery"
        )

        let lethal = try makeIncrement05ControllerFixture(
            hunger: 1,
            fatigue: 1,
            health: 1,
            homeostasisConfiguration: try AgentHomeostasisConfiguration(
                baseHealthDamagePerTick: 25
            )
        )
        let lethalBase = try lethal.controller.session!.makeCheckpoint()
        lethal.controller.replayRecorder = try AgentReplayRecorder(
            checkpoint: lethalBase,
            session: lethal.controller.session!
        )
        lethal.world.time = 3_600
        try requireIncrement05TemporalProof(
            lethal.controller.publishEligiblePhysiologyAfterCompensatedFailure(
                world: lethal.world,
                publishedRecorder: lethal.controller.replayRecorder,
                failure: "increment05-proof-terminal-path-readiness"
            ),
            "temporal fallback terminal publication"
        )
        try requireIncrement05TemporalProof(
            lethal.controller.session?.tick == 0
                && lethal.controller.session?.snapshot().agents.isEmpty == true
                && lethal.controller.session?.mortalitySnapshot()
                    .totalDeathCount == 1
                && lethal.controller.probesByAgentId.isEmpty
                && lethal.world.entities.compactMap {
                    $0 as? LabCoreAgentEntity
                }.isEmpty,
            "temporal fallback reuses terminal probe and cohort boundary"
        )
        try verifyIncrement05ControllerReplay(
            controller: lethal.controller,
            checkpoint: lethalBase,
            name: "increment-05-temporal-failure-mortality"
        )

        return "PASS hz=1/2/4/8 speed=4-8-2-4 pause=world+lab "
            + "step=32 coverage=pending+refused+oversized "
            + "failedHz=1/2/4/8 failedRecords=60/120/240/480 "
            + "recovery=239+2 mortalityFallback=1 fatalLatch=1 "
            + "boundary=\(reference.appliedBoundaries) "
            + "hunger=\(String(format: "%.2f", reference.hunger)) "
            + "fatigue=\(String(format: "%.2f", reference.fatigue))"
    }

    private func makeIncrement05ControllerFixture(
        initialWorldTick: Int = 0,
        hunger: Double = 0,
        fatigue: Double = 0,
        health: Int = 100,
        homeostasisConfiguration: AgentHomeostasisConfiguration = .live
    ) throws -> PebbleIncrement05ControllerFixture {
        let world = World(dim: .overworld, seed: 5)
        world.time = initialWorldTick
        for z in -1...1 {
            for x in -1...1 {
                installIncrement05Chunk(in: world, x: x, z: z)
            }
        }
        let position = AgentPosition(x: 0, y: 64, z: 0)
        let agent = AgentSessionAgentState(
            id: "agent_0", state: "idle", position: position,
            needs: AgentNeeds(
                hunger: hunger, fatigue: fatigue, curiosity: 0, safety: 1
            ),
            health: health, fear: 0, homePosition: position,
            nearbyAgents: [],
            currentGoal: AgentGoal(
                kind: .idle, reason: "temporal controller fixture",
                startedAtTick: 0, urgency: 0
            ),
            lastAction: nil, lastActionEffect: nil, memory: [],
            tickCreated: 0, ticksAlive: 0, observationCount: 0,
            nearbyObservationCount: 0, goalSelectionCount: 0,
            goalChangeCount: 0, actionCount: 0, actionEffectCount: 0,
            movementCount: 0, totalManhattanDistanceMoved: 0,
            returnHomeMoveCount: 0, totalDistanceReducedTowardHome: 0
        )
        var session = try AgentSimulationSession(
            configuration: AgentSessionConfiguration(
                seed: 5, memoryPolicy: .bounded(maxEntries: 64)
            ),
            agents: [agent],
            simulationID: AgentSimulationID(
                validating: "increment-05-controller"
            ),
            causalLedgerPolicy: .bounded(maxEvents: 16_384)
        )
        session.setSurvivalEnabled(true)
        try session.initializePopulationRegistry(
            settlementAnchor: position,
            receptionPosition: AgentPosition(x: 0, y: 64, z: 3),
            configuration: AgentPopulationConfiguration(
                maximumActivePopulation: 3
            )
        )
        try session.setMortalityEnabled(true)
        try session.setLifecycleEnabled(true)
        try session.setHomeostasisEnabled(
            true, configuration: homeostasisConfiguration
        )

        let probe = LabCoreAgentEntity(
            world: world,
            labAgentId: "agent_0",
            physicalId: "increment-05-controller-agent-0"
        )
        probe.setPos(0, 64, 0)
        world.addEntity(probe)
        let player = Player(world: world)
        player.setPos(32, 80, 32)
        let controller = PebbleAgentController()
        controller.activeWorld = world
        controller.session = session
        controller.probesByAgentId = ["agent_0": probe]
        let request = controller.physicalSimulationCoverageRequest(
            for: world
        )
        world.applyPhysicalSimulationCoverage(request)
        try requireIncrement05TemporalProof(
            world.physicalSimulationCoverage.isReady,
            "controller fixture coverage"
        )
        controller.update(world: world, player: player)
        try requireIncrement05TemporalProof(
            controller.session?.physiologicalTimeSnapshot()
                .lastReconciledWorldTick == initialWorldTick,
            "controller fixture World bind"
        )
        return PebbleIncrement05ControllerFixture(
            controller: controller,
            world: world,
            player: player,
            coverageRequest: request
        )
    }

    private func runIncrement05FailedAttemptSchedule(
        hz: Int
    ) throws -> PebbleIncrement05FailedAttemptEvidence {
        let fixture = try makeIncrement05ControllerFixture()
        guard let initialSession = fixture.controller.session else {
            throw ControllerError.homeostasisBoundary(
                "failed-attempt proof session missing"
            )
        }
        let checkpoint = try initialSession.makeCheckpoint()
        fixture.controller.replayRecorder = try AgentReplayRecorder(
            checkpoint: checkpoint,
            session: initialSession
        )
        let initialAgent = try initialSession.state(for: "agent_0")
        let initialProbe = fixture.controller.probesByAgentId["agent_0"]!
            .capturePhysicalState()
        let initialWorldEntityCount = fixture.world.entities.count
        let attempts = hz * 60
        for attempt in 1...attempts {
            fixture.world.time = attempt * 1_200 / attempts
            try requireIncrement05TemporalProof(
                fixture.controller
                    .publishEligiblePhysiologyAfterCompensatedFailure(
                        world: fixture.world,
                        publishedRecorder: fixture.controller.replayRecorder,
                        failure: "increment05-proof-path-readiness"
                    ),
                "failed-attempt temporal publication \(hz) Hz #\(attempt)"
            )
        }
        guard let finalSession = fixture.controller.session,
              let recorder = fixture.controller.replayRecorder else {
            throw ControllerError.homeostasisBoundary(
                "failed-attempt proof publication missing"
            )
        }
        let finalAgent = try finalSession.state(for: "agent_0")
        let finalProbe = fixture.controller.probesByAgentId["agent_0"]!
            .capturePhysicalState()
        try requireIncrement05TemporalProof(
            finalAgent.currentGoal == initialAgent.currentGoal
                && finalAgent.lastAction == initialAgent.lastAction
                && finalAgent.lastActionEffect == initialAgent.lastActionEffect
                && finalAgent.goalSelectionCount
                    == initialAgent.goalSelectionCount
                && finalAgent.actionCount == initialAgent.actionCount
                && finalAgent.movementCount == initialAgent.movementCount
                && finalAgent.memory == initialAgent.memory
                && finalProbe == initialProbe
                && fixture.world.entities.count == initialWorldEntityCount,
            "failed cognition leaks no cognitive or physical candidate state"
        )
        let journal = try recorder.journal(
            named: AgentCheckpointName(
                rawValue: "increment-05-failed-\(hz)hz"
            )!
        )
        let replay = try AgentSessionReplayer.replay(
            checkpoint: checkpoint,
            journal: journal
        )
        let replayBytes = try replay.session.durableStateBytes()
        let finalBytes = try finalSession.durableStateBytes()
        let replayVerified = replay.report.verified
            && replayBytes == finalBytes
            && recorder.records.allSatisfy {
                $0.operationKind == .physiologicalTime
            }
        return PebbleIncrement05FailedAttemptEvidence(
            fixture: fixture,
            recordCount: recorder.records.count,
            replayVerified: replayVerified
        )
    }

    private func verifyIncrement05ControllerReplay(
        controller: PebbleAgentController,
        checkpoint: AgentSessionCheckpoint,
        name: String
    ) throws {
        guard let recorder = controller.replayRecorder,
              let live = controller.session else {
            throw ControllerError.homeostasisBoundary(
                "controller replay evidence missing"
            )
        }
        let journal = try recorder.journal(
            named: AgentCheckpointName(rawValue: name)!
        )
        let replay = try AgentSessionReplayer.replay(
            checkpoint: checkpoint,
            journal: journal
        )
        let replayBytes = try replay.session.durableStateBytes()
        let liveBytes = try live.durableStateBytes()
        try requireIncrement05TemporalProof(
            replay.report.verified && replayBytes == liveBytes,
            "controller failed-attempt replay converges for \(name)"
        )
    }

    private func runIncrement05ControllerSchedule(
        hz: Int
    ) throws -> PebbleIncrement05ControllerFixture {
        let fixture = try makeIncrement05ControllerFixture()
        let command = fixture.controller.handleCommand(
            ["speed", "\(hz)"], world: fixture.world,
            player: fixture.player
        )
        try requireIncrement05TemporalProof(
            command.succeeded, "controller speed \(hz)"
        )
        try advanceIncrement05Controller(
            fixture, throughWorldTick: 1_200
        )
        return fixture
    }

    private func advanceIncrement05Controller(
        _ fixture: PebbleIncrement05ControllerFixture,
        throughWorldTick target: Int
    ) throws {
        guard target >= fixture.world.time else {
            throw ControllerError.homeostasisBoundary(
                "temporal proof target moved backward"
            )
        }
        if target == fixture.world.time { return }
        for tick in (fixture.world.time + 1)...target {
            fixture.world.time = tick
            fixture.world.applyPhysicalSimulationCoverage(
                fixture.coverageRequest
            )
            fixture.controller.update(
                world: fixture.world, player: fixture.player
            )
        }
    }

    private func increment05ControllerEvidence(
        _ controller: PebbleAgentController
    ) throws -> PebbleIncrement05ControllerEvidence {
        guard let session = controller.session,
              let profile = session.homeostasisSnapshot().profiles.first else {
            throw ControllerError.homeostasisBoundary(
                "temporal controller evidence missing"
            )
        }
        let state = try session.state(for: "agent_0")
        let physiological = session.physiologicalTimeSnapshot()
        return PebbleIncrement05ControllerEvidence(
            hunger: state.needs.hunger,
            fatigue: state.needs.fatigue,
            age: try session.demographicAge(
                for: AgentID(rawValue: "agent_0")!
            ),
            energy: profile.energyReserveBasisPoints,
            stress: profile.stressBasisPoints,
            health: state.health,
            deathCount: session.mortalitySnapshot().totalDeathCount,
            elapsedWorldTicks: physiological.totalElapsedWorldTicks,
            remainderWorldTicks: physiological.remainderWorldTicks,
            appliedBoundaries: physiological.appliedBoundaryCount,
            pendingBoundaries: physiological.pendingBoundaryCount
        )
    }

    private func requireIncrement05TemporalProof(
        _ condition: Bool,
        _ boundary: String
    ) throws {
        guard condition else {
            throw ControllerError.homeostasisBoundary(
                "Increment 05 temporal proof: \(boundary)"
            )
        }
    }
}

private func installIncrement05Chunk(
    in world: World,
    x: Int,
    z: Int
) {
    let chunk = Chunk(
        cx: x, cz: z, minY: world.info.minY, height: world.info.height
    )
    chunk.status = .lit
    world.setChunk(chunk)
}
