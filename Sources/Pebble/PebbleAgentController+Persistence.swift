import Foundation
import PebbleAgents
import PebbleCore

struct PebbleAgentCheckpointProbeState {
    let agentID: String
    let probe: LabCoreAgentEntity
    let x: Double
    let y: Double
    let z: Double
    let previousX: Double
    let previousY: Double
    let previousZ: Double
    let velocityX: Double
    let velocityY: Double
    let velocityZ: Double
    let yaw: Double
    let pitch: Double
    let previousYaw: Double
    let previousPitch: Double
    let dead: Bool
    let carriedItems: [ItemStack?]

    init(agentID: String, probe: LabCoreAgentEntity) {
        self.agentID = agentID
        self.probe = probe
        x = probe.x
        y = probe.y
        z = probe.z
        previousX = probe.prevX
        previousY = probe.prevY
        previousZ = probe.prevZ
        velocityX = probe.vx
        velocityY = probe.vy
        velocityZ = probe.vz
        yaw = probe.yaw
        pitch = probe.pitch
        previousYaw = probe.prevYaw
        previousPitch = probe.prevPitch
        dead = probe.dead
        carriedItems = copyItemInventory(probe.carriedItems)
    }

    var carriedQuantity: Int {
        carriedItems.compactMap { $0?.count }.reduce(0, +)
    }

    func isUnchanged(
        in world: World,
        mappedByAgentID: [String: LabCoreAgentEntity]
    ) -> Bool {
        mappedByAgentID[agentID] === probe
            && probe.world === world
            && !probe.dead
            && world.entities.filter { $0 === probe }.count == 1
            && probe.x == x && probe.y == y && probe.z == z
            && probe.prevX == previousX
            && probe.prevY == previousY
            && probe.prevZ == previousZ
            && probe.vx == velocityX
            && probe.vy == velocityY
            && probe.vz == velocityZ
            && probe.yaw == yaw
            && probe.pitch == pitch
            && probe.prevYaw == previousYaw
            && probe.prevPitch == previousPitch
            && probe.dead == dead
            && probe.carriedItems == carriedItems
    }

    func isRestored(
        to position: AgentPosition,
        in world: World,
        mappedByAgentID: [String: LabCoreAgentEntity]
    ) -> Bool {
        mappedByAgentID[agentID] === probe
            && probe.world === world
            && !probe.dead
            && world.entities.filter { $0 === probe }.count == 1
            && AgentPosition(
                x: Int(probe.x.rounded(.down)),
                y: Int(probe.y.rounded(.down)),
                z: Int(probe.z.rounded(.down))
            ) == position
            && probe.prevX == probe.x
            && probe.prevY == probe.y
            && probe.prevZ == probe.z
            && probe.vx == 0 && probe.vy == 0 && probe.vz == 0
            && probe.prevYaw == probe.yaw
            && probe.prevPitch == probe.pitch
            && probe.carriedItems == carriedItems
    }

    func restorePriorPhysicalState() {
        probe.setPos(x, y, z)
        probe.prevX = previousX
        probe.prevY = previousY
        probe.prevZ = previousZ
        probe.vx = velocityX
        probe.vy = velocityY
        probe.vz = velocityZ
        probe.yaw = yaw
        probe.pitch = pitch
        probe.prevYaw = previousYaw
        probe.prevPitch = previousPitch
        probe.dead = dead
        probe.carriedItems = copyItemInventory(carriedItems)
    }
}

enum PebbleAgentCheckpointProbeClassification: String {
    case reusedExact = "reused_exact"
    case restoredMissing = "restored_missing"
    case repositionedVerified = "repositioned_verified"
}

struct PebbleAgentCheckpointProbePlanEntry {
    let agent: AgentSnapshot
    let classification: PebbleAgentCheckpointProbeClassification
    let currentEmbodiment: PebbleAgentEmbodiment?
}

struct PebbleAgentCheckpointProbePlan {
    let entries: [PebbleAgentCheckpointProbePlanEntry]

    var exactAgentIDs: [String] {
        entries.filter { $0.classification == .reusedExact }.map { $0.agent.id }
    }

    var missingAgentIDs: [String] {
        entries.filter { $0.classification == .restoredMissing }.map { $0.agent.id }
    }

    var repositionedAgentIDs: [String] {
        entries.filter { $0.classification == .repositionedVerified }.map { $0.agent.id }
    }

    var restorationAuthorizedAgentIDs: [String] {
        (missingAgentIDs + repositionedAgentIDs).sorted()
    }
}

enum PebbleAgentCheckpointProbePlanError: Error, CustomStringConvertible {
    case duplicateCandidatePosition(String)
    case missingPopulationIdentity(String)
    case missingLifecycleIdentity(String)
    case missingEmptyAttestation(String)
    case nonEmptyCurrentCustody(String, Int)
    case physicalHolderConflict(String)

    var description: String {
        switch self {
        case let .duplicateCandidatePosition(id):
            return "duplicate checkpoint position for \(id)"
        case let .missingPopulationIdentity(id):
            return "checkpoint agent is absent from population: \(id)"
        case let .missingLifecycleIdentity(id):
            return "checkpoint agent is absent from lifecycle: \(id)"
        case let .missingEmptyAttestation(id):
            return "protected empty-custody attestation is absent for \(id)"
        case let .nonEmptyCurrentCustody(id, quantity):
            return "current probe custody is non-empty for \(id):\(quantity)"
        case let .physicalHolderConflict(id):
            return "Material Rights resolves checkpoint agent as physical holder: \(id)"
        }
    }
}

struct PebbleAgentCheckpointProbePlanner {
    static func plan(
        candidateAgents: [AgentSnapshot],
        currentEmbodiments: [String: PebbleAgentEmbodiment],
        verifiedEmptyAgentIDs: Set<String>,
        populationAgentIDs: Set<String>,
        lifecycleAgentIDs: Set<String>,
        requirePopulationIdentity: Bool,
        requireLifecycleIdentity: Bool,
        physicalHolderAgentIDs: Set<String>
    ) throws -> PebbleAgentCheckpointProbePlan {
        let ordered = candidateAgents.sorted { $0.id < $1.id }
        var positions: [AgentPosition: String] = [:]
        var entries: [PebbleAgentCheckpointProbePlanEntry] = []
        for agent in ordered {
            if let first = positions[agent.position] {
                throw PebbleAgentCheckpointProbePlanError
                    .duplicateCandidatePosition("\(first),\(agent.id)")
            }
            positions[agent.position] = agent.id
            if requirePopulationIdentity,
               !populationAgentIDs.contains(agent.id) {
                throw PebbleAgentCheckpointProbePlanError
                    .missingPopulationIdentity(agent.id)
            }
            if requireLifecycleIdentity,
               !lifecycleAgentIDs.contains(agent.id) {
                throw PebbleAgentCheckpointProbePlanError
                    .missingLifecycleIdentity(agent.id)
            }
            guard let embodiment = currentEmbodiments[agent.id] else {
                try requireRestorationAuthority(
                    agentID: agent.id,
                    currentEmbodiment: nil,
                    verifiedEmptyAgentIDs: verifiedEmptyAgentIDs,
                    physicalHolderAgentIDs: physicalHolderAgentIDs
                )
                entries.append(PebbleAgentCheckpointProbePlanEntry(
                    agent: agent,
                    classification: .restoredMissing,
                    currentEmbodiment: nil
                ))
                continue
            }
            if embodiment.position == agent.position {
                entries.append(PebbleAgentCheckpointProbePlanEntry(
                    agent: agent,
                    classification: .reusedExact,
                    currentEmbodiment: embodiment
                ))
                continue
            }
            try requireRestorationAuthority(
                agentID: agent.id,
                currentEmbodiment: embodiment,
                verifiedEmptyAgentIDs: verifiedEmptyAgentIDs,
                physicalHolderAgentIDs: physicalHolderAgentIDs
            )
            entries.append(PebbleAgentCheckpointProbePlanEntry(
                agent: agent,
                classification: .repositionedVerified,
                currentEmbodiment: embodiment
            ))
        }
        return PebbleAgentCheckpointProbePlan(entries: entries)
    }

    private static func requireRestorationAuthority(
        agentID: String,
        currentEmbodiment: PebbleAgentEmbodiment?,
        verifiedEmptyAgentIDs: Set<String>,
        physicalHolderAgentIDs: Set<String>
    ) throws {
        guard verifiedEmptyAgentIDs.contains(agentID) else {
            throw PebbleAgentCheckpointProbePlanError
                .missingEmptyAttestation(agentID)
        }
        if let currentEmbodiment {
            let quantity = currentEmbodiment.carriedItems.compactMap {
                $0?.count
            }.reduce(0, +)
            guard quantity == 0 else {
                throw PebbleAgentCheckpointProbePlanError
                    .nonEmptyCurrentCustody(agentID, quantity)
            }
        }
        guard !physicalHolderAgentIDs.contains(agentID) else {
            throw PebbleAgentCheckpointProbePlanError
                .physicalHolderConflict(agentID)
        }
    }
}

enum PebbleAgentCheckpointPositionRestoreFailurePoint {
    case afterFirstReposition
    case afterFirstMissingCreation
}

extension PebbleAgentController {
    func handleCheckpoint(
        _ arguments: [String],
        world: World
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab checkpoint <status|list|save <name>|load <name>"
            + "|delete <name>|position-proof ...>"
        guard persistenceFeatureEnabled else {
            return failure(
                "PebbleAgents persistence disabled. Set PEBBLELAB_APP_AGENTS_PERSISTENCE=1 before launch."
            )
        }
        guard let subcommand = arguments.first?.lowercased() else { return failure(usage) }
        do {
            let store = try persistenceStore()
            switch subcommand {
            case "status":
                guard arguments.count == 1 else { return failure(usage) }
                guard let session else {
                    return success(
                        "checkpoint status gate=enabled session=inactive world=\(persistenceWorldID ?? "none") count=\(try store.checkpointNames().count)"
                    )
                }
                let readiness = checkpointReadiness(session: session)
                let safety = liveRestartSafety()
                let names = try store.checkpointNames()
                let digest = try session.durableStateDigest()
                let causal = session.causalLedgerSnapshot().summary
                let message = "checkpoint status gate=enabled ready=\(readiness.ready ? 1 : 0) restartSafe=\(safety.safe ? 1 : 0) world=\(persistenceWorldID ?? "none") dimension=\(persistenceDimension) tick=\(session.tick) simulation=\(session.simulationID.rawValue) digest=\(digest.rawValue) causalSequence=\(causal.latestSequence) count=\(names.count) latest=\(names.last?.rawValue ?? "none") recording=\(replayRecorder == nil ? "inactive" : "active") blockers=\(readiness.blockingReasons.joined(separator: ",").replacingOccurrences(of: " ", with: "_")) safetyReason=\(safety.reason.replacingOccurrences(of: " ", with: "_"))"
                trace(message)
                return success(message)
            case "list":
                guard arguments.count == 1 else { return failure(usage) }
                let names = try store.checkpointNames().map(\.rawValue)
                let message = "checkpoint list count=\(names.count) names=\(names.isEmpty ? "none" : names.joined(separator: ","))"
                trace(message)
                return success(message)
            case "save":
                guard arguments.count == 2, let name = AgentCheckpointName(rawValue: arguments[1]) else {
                    return failure(usage)
                }
                guard let session, activeWorld === world else {
                    return failure("No active PebbleAgents session.")
                }
                let wasPaused = isPaused
                isPaused = true
                credit = 0
                defer { isPaused = wasPaused }
                let readiness = checkpointReadiness(session: session)
                guard readiness.ready else {
                    return failure(
                        "Checkpoint refused at unstable boundary: \(readiness.blockingReasons.joined(separator: "; "))."
                    )
                }
                let causalBefore = session.causalLedgerSnapshot().summary
                let checkpointSnapshot = session.snapshot()
                let checkpointAgentIDs = checkpointSnapshot.agents
                    .map(\.id).sorted()
                let checkpointEmbodiments = try validatedCheckpointEmbodiments(
                    snapshot: checkpointSnapshot,
                    world: world
                )
                if session.ecologicalObservationEnabled {
                    try validateWorldEcologicalObservationReceipts(
                        for: session,
                        dimension: world.dim.rawValue
                    )
                }
                let checkpoint = try session.makeCheckpoint()
                let bytes = try AgentCheckpointCodec.encode(checkpoint)
                let binding = try worldBinding(
                    checkpoint: checkpoint,
                    world: world,
                    store: store
                )
                let reconciliation = try reconciliationBinding(
                    checkpoint: checkpoint,
                    session: session,
                    world: world,
                    store: store
                )
                let safety = liveRestartSafety()
                let verifiedEmptyProbeAgentIDs = checkpointAgentIDs.filter {
                    checkpointEmbodiments[$0]?.carriedItems.allSatisfy {
                        $0 == nil
                    } == true
                }
                let manifest = try AgentCheckpointManifest(
                    name: name,
                    checkpoint: checkpoint,
                    storageDigest: AgentCheckpointDigest.sha256(bytes),
                    byteLength: bytes.count,
                    restartSafe: safety.safe,
                    restartSafetyReason: safety.reason,
                    worldBinding: binding,
                    orchestration: AgentCheckpointLiveOrchestration(
                        cognitiveHz: cognitiveHz,
                        wasPaused: wasPaused,
                        movementEnabled: movementEnabled,
                        autoInteractionEnabled: autoInteractionEnabled,
                        economyAutoEnabled: economyAutoEnabled,
                        focusedAgentID: focusedAgentId,
                        naturalResourceScanDiagnostics: naturalResourceExecutor.state.lastScan,
                        verifiedEmptyProbeAgentIDsAtSave:
                            verifiedEmptyProbeAgentIDs
                    ),
                    reconciliationBinding: reconciliation
                )
                try store.saveCheckpoint(name: name, checkpoint: checkpoint, manifest: manifest)
                let causalAfter = session.causalLedgerSnapshot().summary
                guard causalBefore == causalAfter,
                      try session.durableStateDigest() == checkpoint.semanticDigest else {
                    throw PebbleAgentPersistenceStoreError.invalidBundle(
                        "save changed the live session"
                    )
                }
                self.session = session
                let message = "checkpoint saved name=\(name.rawValue) id=\(checkpoint.checkpointID.rawValue) tick=\(checkpoint.tick.rawValue) simulation=\(checkpoint.simulationID.rawValue) digest=\(checkpoint.semanticDigest.rawValue) storageDigest=\(manifest.storageDigest.rawValue) manifestIntegrity=v\(manifest.manifestIntegrityVersion ?? 0):\(manifest.manifestIntegrityDigest?.rawValue ?? "none") bytes=\(bytes.count) causalSequence=\(causalAfter.latestSequence) restartSafe=\(safety.safe ? 1 : 0) boundCells=\(binding.cells.count) physicalReferences=\(reconciliation?.assets.count ?? 0) world=\(binding.worldID) mutation=none"
                trace(message)
                return success(message)
            case "load":
                guard arguments.count == 2, let name = AgentCheckpointName(rawValue: arguments[1]) else {
                    return failure(usage)
                }
                guard replayRecorder == nil else {
                    return failure("Checkpoint load refused while replay recording is active.")
                }
                return try loadLiveCheckpoint(name: name, world: world, store: store)
            case "delete":
                guard arguments.count == 2, let name = AgentCheckpointName(rawValue: arguments[1]) else {
                    return failure(usage)
                }
                guard replayBaseCheckpointName != name || replayRecorder == nil else {
                    return failure("Checkpoint delete refused: active replay recording uses \(name.rawValue).")
                }
                try store.deleteCheckpoint(name: name)
                trace("checkpoint deleted name=\(name.rawValue)")
                return success("Checkpoint deleted: \(name.rawValue).")
            case "position-proof":
                return handleCheckpointPositionRestoreProof(
                    Array(arguments.dropFirst()),
                    world: world
                )
            default:
                return failure(usage)
            }
        } catch {
            return failure("PebbleAgents checkpoint command failed: \(error)")
        }
    }

    func handleReplay(_ arguments: [String]) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab replay <status|start <checkpoint-name>|stop <journal-name>|verify <checkpoint-name> <journal-name>>"
        guard persistenceFeatureEnabled else {
            return failure(
                "PebbleAgents persistence disabled. Set PEBBLELAB_APP_AGENTS_PERSISTENCE=1 before launch."
            )
        }
        guard let subcommand = arguments.first?.lowercased() else { return failure(usage) }
        do {
            let store = try persistenceStore()
            switch subcommand {
            case "status":
                guard arguments.count == 1 else { return failure(usage) }
                let records = replayRecorder?.records.count ?? 0
                let message = "replay status gate=enabled recording=\(replayRecorder == nil ? "inactive" : "active") base=\(replayBaseCheckpointName?.rawValue ?? "none") records=\(records) replayable=\(replayRecorder?.isReplayable == false ? 0 : 1)"
                trace(message)
                return success(message)
            case "start":
                guard arguments.count == 2,
                      let name = AgentCheckpointName(rawValue: arguments[1]),
                      let session else { return failure(usage) }
                guard replayRecorder == nil else {
                    return failure("Replay recording is already active.")
                }
                let stored = try store.loadCheckpoint(name: name)
                let recorder = try AgentReplayRecorder(
                    checkpoint: stored.checkpoint,
                    session: session
                )
                replayRecorder = recorder
                replayBaseCheckpointName = name
                self.session = session
                let message = "replay recording started base=\(name.rawValue) checkpoint=\(stored.checkpoint.checkpointID.rawValue) tick=\(session.tick) digest=\(stored.checkpoint.semanticDigest.rawValue) records=0"
                trace(message)
                return success(message)
            case "stop":
                guard arguments.count == 2,
                      let name = AgentCheckpointName(rawValue: arguments[1]),
                      let recorder = replayRecorder else { return failure(usage) }
                let journal = try recorder.journal(named: name)
                try store.saveReplay(name: name, journal: journal)
                replayRecorder = nil
                let base = replayBaseCheckpointName?.rawValue ?? "none"
                replayBaseCheckpointName = nil
                let message = "replay recording stopped name=\(name.rawValue) base=\(base) records=\(journal.records.count) digest=\(journal.manifest.operationsStorageDigest.rawValue) replayable=\(journal.manifest.replayable ? 1 : 0)"
                trace(message)
                return success(message)
            case "verify":
                guard arguments.count == 3,
                      let checkpointName = AgentCheckpointName(rawValue: arguments[1]),
                      let replayName = AgentCheckpointName(rawValue: arguments[2]) else {
                    return failure(usage)
                }
                let before = try session?.durableStateDigest()
                let storedCheckpoint = try store.loadCheckpoint(name: checkpointName)
                let storedReplay = try store.loadReplay(name: replayName)
                let result = try AgentSessionReplayer.replay(
                    checkpoint: storedCheckpoint.checkpoint,
                    journal: storedReplay.journal
                )
                guard result.report.verified else {
                    let divergence = result.report.divergence
                    return failure(
                        "Replay divergence record=\(divergence?.recordSequence ?? 0) kind=\(divergence?.operationKind.rawValue ?? "none") reason=\(divergence?.reason ?? "unknown")."
                    )
                }
                guard try session?.durableStateDigest() == before else {
                    throw PebbleAgentPersistenceStoreError.invalidBundle(
                        "replay verification changed the live session"
                    )
                }
                let message = "replay verified checkpoint=\(checkpointName.rawValue) journal=\(replayName.rawValue) records=\(result.report.recordsApplied) tick=\(result.report.finalTick) digest=\(result.report.finalSemanticDigest.rawValue) causalSequence=\(result.report.finalCausalSequence) causalDigest=\(result.report.finalCausalDigest) liveMutation=none worldMutation=none"
                trace(message)
                return success(message)
            default:
                return failure(usage)
            }
        } catch {
            return failure("PebbleAgents replay command failed: \(error)")
        }
    }

    func applyRecordedOperationIfActive(
        _ operation: AgentReplayOperation,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws -> AgentReplayApplicationResult? {
        guard var activeRecorder = recorder else { return nil }
        let result = try activeRecorder.apply(operation, to: &session)
        recorder = activeRecorder
        return result
    }

    func applyCommandMutationIfRecording(
        _ operation: AgentReplayOperation,
        session: inout AgentSimulationSession
    ) throws -> AgentReplayApplicationResult? {
        var recorder = replayRecorder
        let result = try applyRecordedOperationIfActive(
            operation,
            session: &session,
            recorder: &recorder
        )
        replayRecorder = recorder
        return result
    }

    func checkpointReadiness(session: AgentSimulationSession) -> AgentCheckpointReadiness {
        session.checkpointReadiness(
            pendingOperationCount: isAdvancingSession ? 1 : 0,
            replayRecordingStatus: replayRecorder == nil ? "inactive" : "active"
        )
    }

    func validatedCheckpointEmbodiments(
        snapshot: AgentSessionSnapshot,
        world: World
    ) throws -> [String: PebbleAgentEmbodiment] {
        let orderedAgents = snapshot.agents.sorted { $0.id < $1.id }
        let embodiments = try PebbleAgentEmbodiment.resolveAll(
            agentIDs: orderedAgents.map(\.id),
            in: world,
            mappedByAgentID: probesByAgentId
        )
        if let mismatch = orderedAgents.first(where: {
            embodiments[$0.id]?.position != $0.position
        }) {
            let physical = embodiments[mismatch.id]?.position
            throw PebbleAgentPersistenceStoreError.invalidBundle(
                "checkpoint save position mismatch agent=\(mismatch.id) "
                    + "session=\(positionText(mismatch.position)) "
                    + "physical=\(physical.map(positionText) ?? "missing")"
            )
        }
        return embodiments
    }

    private func persistenceStore() throws -> PebbleAgentPersistenceStore {
        guard let persistenceWorldID else {
            throw PebbleAgentPersistenceStoreError.invalidManagedRoot
        }
        return try PebbleAgentPersistenceStore(worldID: persistenceWorldID)
    }

    private func liveRestartSafety() -> (safe: Bool, reason: String) {
        if wildSubsistenceProofFixture != nil {
            return (false, "wild subsistence proof has physical attempts that are not restart-safe")
        }
        if agricultureProofFixture != nil {
            return (false, "agriculture proof fixture is app-owned and pending cleanup")
        }
        let interaction = interactionExecutor.economyState()
        if !interaction.fixtures.isEmpty {
            return (false, "interaction fixture receipts are app-only")
        }
        if naturalResourceExecutor.state.harvestCount > 0 {
            return (false, "natural harvest receipts are app-only")
        }
        if constructionExecutor.state.placedCount > 0 {
            return (false, "construction placement receipts are app-only")
        }
        return (true, "no successful live World mutation receipt is required after restart")
    }

    private func worldBinding(
        checkpoint: AgentSessionCheckpoint,
        world: World,
        store: PebbleAgentPersistenceStore
    ) throws -> AgentCheckpointWorldBinding {
        guard let anchor else { throw ControllerError.missingSession }
        let positions = try boundWorldPositions(checkpoint: checkpoint)
        var cells: [AgentCheckpointWorldCell] = []
        for position in positions {
            guard world.isChunkReady(position.x >> 4, position.z >> 4) else {
                throw AgentCheckpointError.worldBindingMismatch(
                    "chunk unavailable at \(positionText(position))"
                )
            }
            cells.append(AgentCheckpointWorldCell(
                position: position,
                blockFingerprint: world.getBlock(position.x, position.y, position.z)
            ))
        }
        return try AgentCheckpointWorldBinding(
            worldID: store.worldID,
            storageIdentity: store.storageIdentity,
            seed: world.seed,
            dimension: persistenceDimension,
            anchor: anchor,
            simulationID: checkpoint.simulationID,
            checkpointTick: checkpoint.tick,
            cells: cells
        )
    }

    private func validateWorldBinding(
        _ binding: AgentCheckpointWorldBinding,
        checkpoint: AgentSessionCheckpoint,
        world: World,
        store: PebbleAgentPersistenceStore
    ) throws {
        guard binding.worldID == store.worldID else {
            throw AgentCheckpointError.worldBindingMismatch("World ID")
        }
        guard binding.storageIdentity == store.storageIdentity else {
            throw AgentCheckpointError.worldBindingMismatch("storage identity")
        }
        guard binding.seed == world.seed else {
            throw AgentCheckpointError.worldBindingMismatch("seed")
        }
        guard binding.dimension == persistenceDimension else {
            throw AgentCheckpointError.worldBindingMismatch("dimension")
        }
        guard binding.simulationID == checkpoint.simulationID,
              binding.checkpointTick == checkpoint.tick else {
            throw AgentCheckpointError.worldBindingMismatch("session identity")
        }
        guard binding.anchor == anchor else {
            throw AgentCheckpointError.worldBindingMismatch("anchor")
        }
        let expectedBoundPositions = try boundWorldPositions(
            checkpoint: checkpoint
        )
        guard binding.cells.map(\.position) == expectedBoundPositions else {
            throw AgentCheckpointError.worldBindingMismatch(
                "bound position set"
            )
        }
        for cell in binding.cells {
            guard world.isChunkReady(cell.position.x >> 4, cell.position.z >> 4) else {
                throw AgentCheckpointError.worldBindingMismatch(
                    "chunk unavailable at \(positionText(cell.position))"
                )
            }
            guard world.getBlock(cell.position.x, cell.position.y, cell.position.z)
                    == cell.blockFingerprint else {
                throw AgentCheckpointError.worldBindingMismatch(
                    "cell changed at \(positionText(cell.position))"
                )
            }
        }
        let rebuilt = try AgentCheckpointWorldBinding(
            worldID: binding.worldID,
            storageIdentity: binding.storageIdentity,
            seed: binding.seed,
            dimension: binding.dimension,
            anchor: binding.anchor,
            simulationID: binding.simulationID,
            checkpointTick: binding.checkpointTick,
            cells: binding.cells
        )
        guard rebuilt.compatibilityDigest == binding.compatibilityDigest else {
            throw AgentCheckpointError.worldBindingMismatch("compatibility digest")
        }
    }

    private func boundWorldPositions(
        checkpoint: AgentSessionCheckpoint
    ) throws -> [AgentPosition] {
        let state = checkpoint.durableState
        var positions = Set<AgentPosition>()
        for agent in state.agents {
            positions.insert(agent.position)
            positions.insert(agent.homePosition)
            for observation in agent.lastResourceObservations { positions.insert(observation.target) }
            if let target = agent.activeResourceTarget?.target { positions.insert(target) }
            if let route = agent.navigationProgress.route {
                positions.formUnion(route.positions)
                positions.insert(route.target)
            }
        }
        positions.formUnion(state.reservations.map(\.target))
        positions.formUnion(state.socialFacts.map(\.position))
        for signal in state.physicalSignals {
            positions.insert(signal.sourcePosition)
            positions.insert(signal.pointedPosition)
        }
        for request in state.physicalPresentationRequests {
            positions.insert(request.sourcePosition)
            positions.insert(request.pointedPosition)
        }
        if let project = state.constructionProject {
            positions.insert(project.origin)
            positions.insert(project.restPosition)
            for cell in project.blueprint.cells { positions.insert(project.worldPosition(for: cell)) }
        }
        if let population = state.populationRegistry {
            positions.insert(population.settlement.anchor)
            positions.insert(population.settlement.receptionPosition)
            for member in population.members {
                positions.insert(member.receptionPosition)
                if let entry = member.entryPosition { positions.insert(entry) }
            }
            for migration in population.migrations {
                positions.insert(migration.entryPosition)
                positions.insert(migration.receptionPosition)
                positions.formUnion(migration.route)
            }
        }
        if let ecology = state.localEcologyState {
            for patch in ecology.patches {
                positions.insert(patch.habitatPosition)
                positions.insert(patch.foragePosition)
            }
        }
        guard positions.count <= AgentCheckpointLimits.maximumBoundWorldCells else {
            throw AgentCheckpointError.invalidBound("World binding cells")
        }
        return positions.sorted {
            if $0.x != $1.x { return $0.x < $1.x }
            if $0.y != $1.y { return $0.y < $1.y }
            return $0.z < $1.z
        }
    }

    private func loadLiveCheckpoint(
        name: AgentCheckpointName,
        world: World,
        store: PebbleAgentPersistenceStore
    ) throws -> PebbleAgentCommandResult {
        guard let oldSession = session, activeWorld === world else {
            return failure("No active PebbleAgents session.")
        }
        guard liveRestartSafety().safe else {
            return failure("Checkpoint load refused: current live World receipts are not restart-safe.")
        }
        let stored = try store.loadCheckpoint(name: name)
        guard stored.manifest.restartSafe else {
            return failure(
                "Checkpoint load refused: \(name.rawValue) is not restart-safe (\(stored.manifest.restartSafetyReason))."
            )
        }
        try validateWorldBinding(
            stored.manifest.worldBinding,
            checkpoint: stored.checkpoint,
            world: world,
            store: store
        )
        var candidate = try AgentSimulationSession.restoring(stored.checkpoint)
        if candidate.ecologicalObservationEnabled {
            try validateWorldEcologicalObservationReceipts(
                for: candidate,
                dimension: world.dim.rawValue
            )
        }
        if candidate.persistenceReconciliationEnabled
            && !persistenceReconciliationFeatureEnabled {
            return failure(
                "Checkpoint load refused: persistence reconciliation gate is disabled."
            )
        }
        if candidate.settlementMetricsEnabled && !multiscaleFeatureEnabled {
            return failure(
                "Checkpoint load refused: settlement metrics gate is disabled."
            )
        }
        if candidate.localEcologyEnabled && !ecologyFeatureEnabled {
            return failure("Checkpoint load refused: local ecology gate is disabled.")
        }
        if candidate.mortalityEnabled && !mortalityFeatureEnabled {
            return failure("Checkpoint load refused: mortality gate is disabled.")
        }
        if candidate.homeostasisEnabled && !homeostasisFeatureEnabled {
            return failure("Checkpoint load refused: homeostasis gate is disabled.")
        }
        if candidate.geneticsEnabled && !geneticsFeatureEnabled {
            return failure("Checkpoint load refused: genetics gate is disabled.")
        }
        if candidate.lifecycleEnabled && !lifecycleFeatureEnabled {
            trace("checkpoint load refused name=\(name.rawValue) reason=lifecycleGate")
            return failure("Checkpoint load refused: lifecycle gate is disabled.")
        }
        if candidate.kinshipEnabled && (!kinshipFeatureEnabled || !featureEnabled
            || !persistenceFeatureEnabled || !populationFeatureEnabled
            || !lifecycleFeatureEnabled) {
            trace("checkpoint load refused name=\(name.rawValue) reason=kinshipGate")
            return failure("Checkpoint load refused: kinship gate or dependency is disabled.")
        }
        if candidate.householdsEnabled && (!householdFeatureEnabled
            || !kinshipFeatureEnabled || !featureEnabled || !persistenceFeatureEnabled
            || !populationFeatureEnabled || !lifecycleFeatureEnabled) {
            trace("checkpoint load refused name=\(name.rawValue) reason=householdGate")
            return failure("Checkpoint load refused: household gate or dependency is disabled.")
        }
        if candidate.dependentCareEnabled && (!dependentCareFeatureEnabled
            || !householdFeatureEnabled || !kinshipFeatureEnabled || !featureEnabled
            || !persistenceFeatureEnabled || !populationFeatureEnabled
            || !lifecycleFeatureEnabled || !candidate.survivalEnabled) {
            trace("checkpoint load refused name=\(name.rawValue) reason=careGate")
            return failure("Checkpoint load refused: care gate or dependency is disabled.")
        }
        if candidate.childhoodV2Enabled && !childhoodFeatureEnabled {
            trace("checkpoint load refused name=\(name.rawValue) reason=childhoodGate")
            return failure("Checkpoint load refused: childhood V2 gate is disabled.")
        }
        if candidate.familyV1Enabled && !familyFeatureEnabled {
            trace("checkpoint load refused name=\(name.rawValue) reason=familyGate")
            return failure("Checkpoint load refused: family V1 gate is disabled.")
        }
        if candidate.skillsEnabled && (!skillFeatureEnabled || !featureEnabled
            || !persistenceFeatureEnabled || !populationFeatureEnabled
            || !lifecycleFeatureEnabled) {
            trace("checkpoint load refused name=\(name.rawValue) reason=skillGate")
            return failure("Checkpoint load refused: skills gate or dependency is disabled.")
        }
        if candidate.teachingEnabled && (!teachingFeatureEnabled || !skillFeatureEnabled
            || !featureEnabled || !persistenceFeatureEnabled
            || !populationFeatureEnabled || !lifecycleFeatureEnabled) {
            trace("checkpoint load refused name=\(name.rawValue) reason=teachingGate")
            return failure("Checkpoint load refused: Teaching gate or dependency is disabled.")
        }
        if candidate.ecologicalObservationEnabled
            && (!ecologicalObservationFeatureEnabled || !featureEnabled
                || !persistenceFeatureEnabled || !populationFeatureEnabled) {
            trace("checkpoint load refused name=\(name.rawValue) reason=ecologicalObservationGate")
            return failure(
                "Checkpoint load refused: ecological observation gate or dependency is disabled."
            )
        }
        if candidate.agricultureEnabled
            && (!agricultureFeatureEnabled || !featureEnabled || !persistenceFeatureEnabled
                || !populationFeatureEnabled || !lifecycleFeatureEnabled
                || !skillFeatureEnabled || !ecologicalObservationFeatureEnabled
                || !materialFeatureEnabled || !interactionFeatureEnabled) {
            trace("checkpoint load refused name=\(name.rawValue) reason=agricultureGate")
            return failure(
                "Checkpoint load refused: agriculture gate or dependency is disabled."
            )
        }
        let checkpointDigest = try candidate.durableStateDigest()
        guard checkpointDigest == stored.manifest.semanticDigest else {
            throw AgentCheckpointError.semanticDigestMismatch
        }
        let candidateAgents = candidate.snapshot().agents.sorted { $0.id < $1.id }
        let candidateAgentIDs = candidateAgents.map(\.id)
        let currentAgentIDs = oldSession.snapshot().agents.map(\.id).sorted()
        let worldProbeIDs = world.entities.compactMap {
            ($0 as? LabCoreAgentEntity)?.labAgentId
        }.sorted()
        let oldProbesByAgentID = probesByAgentId
        let oldWorldEntities = world.entities
        let candidateAgentIDSet = Set(candidateAgentIDs)
        let currentAgentIDSet = Set(currentAgentIDs)
        let retiredBootstrapAgentIDs = currentAgentIDs.filter {
            !candidateAgentIDSet.contains($0)
        }
        let restoredCheckpointAgentIDs = candidateAgentIDs.filter {
            !currentAgentIDSet.contains($0)
        }
        let retainedDeathAgentIDs = Set(
            candidate.mortalitySnapshot().records.map(\.agentID.rawValue)
        )
        let candidatePopulationIDs = Set(
            candidate.populationSnapshot().members.map(\.agentID.rawValue)
        )
        let candidateLifecycleIDs = Set(
            candidate.lifecycleSnapshot().members.map(\.agentID.rawValue)
        )
        let verifiedEmptyProbeAgentIDs =
            try stored.manifest.protectedVerifiedEmptyProbeAgentIDs(
                for: stored.checkpoint
            )
        guard worldProbeIDs == currentAgentIDs,
              verifiedEmptyProbeAgentIDs
                == Array(Set(verifiedEmptyProbeAgentIDs)).sorted(),
              Set(retiredBootstrapAgentIDs).isSubset(
                  of: retainedDeathAgentIDs
              ),
              candidate.materialRightsSnapshot().records.allSatisfy({ record in
                  !retiredBootstrapAgentIDs.contains {
                      record.lastVerifiedHolder.holder
                          == .agent(AgentID(rawValue: $0)!)
                  }
              }) else {
            return failure(
                "Checkpoint load refused: live Civilization identities do not match the checkpoint."
            )
        }
        let currentEmbodiments: [String: PebbleAgentEmbodiment]
        do {
            currentEmbodiments = try PebbleAgentEmbodiment.resolveAll(
                agentIDs: currentAgentIDs,
                in: world,
                mappedByAgentID: probesByAgentId
            )
        } catch {
            return failure(
                "Checkpoint load refused: live embodiments are not coherent (\(error))."
            )
        }
        let physicalHolderAgentIDs = Set(
            candidate.materialRightsSnapshot().records.compactMap {
                record -> String? in
                guard case let .agent(agentID) =
                    record.lastVerifiedHolder.holder else { return nil }
                return agentID.rawValue
            }
        )
        let probePlan: PebbleAgentCheckpointProbePlan
        do {
            probePlan = try PebbleAgentCheckpointProbePlanner.plan(
                candidateAgents: candidateAgents,
                currentEmbodiments: currentEmbodiments,
                verifiedEmptyAgentIDs: Set(verifiedEmptyProbeAgentIDs),
                populationAgentIDs: candidatePopulationIDs,
                lifecycleAgentIDs: candidateLifecycleIDs,
                requirePopulationIdentity: candidate.populationEnabled,
                requireLifecycleIdentity: candidate.lifecycleEnabled,
                physicalHolderAgentIDs: physicalHolderAgentIDs
            )
            guard probePlan.missingAgentIDs == restoredCheckpointAgentIDs else {
                throw PebbleAgentCheckpointProbePlanError
                    .missingPopulationIdentity("physical-plan-mismatch")
            }
            _ = try stored.manifest.validateProbeRestoration(
                restoredAgentIDs: probePlan.restorationAuthorizedAgentIDs,
                for: stored.checkpoint
            )
        } catch {
            let reason = String(describing: error)
                .replacingOccurrences(of: " ", with: "_")
            trace(
                "checkpoint probe position refused name=\(name.rawValue) "
                    + "reason=\(reason)"
            )
            return failure(
                "Checkpoint load refused: physical probe restoration is not authorized (\(error))."
            )
        }
        for entry in probePlan.entries {
            let current = entry.currentEmbodiment?.position
            let carried = entry.currentEmbodiment?.carriedItems.compactMap {
                $0?.count
            }.reduce(0, +) ?? 0
            trace(
                "checkpoint probe classification agent=\(entry.agent.id) "
                    + "checkpoint=\(positionText(entry.agent.position)) "
                    + "current=\(current.map(positionText) ?? "none") "
                    + "carried=\(carried) "
                    + "verifiedEmpty=\(verifiedEmptyProbeAgentIDs.contains(entry.agent.id) ? 1 : 0) "
                    + "presentCurrent=\(entry.currentEmbodiment == nil ? 0 : 1) "
                    + "presentCheckpoint=1 "
                    + "reconciliation=\(entry.classification.rawValue)"
            )
        }
        let reusableProbeStates = candidateAgentIDs.compactMap { agentID in
            currentEmbodiments[agentID].map {
                PebbleAgentCheckpointProbeState(
                    agentID: agentID,
                    probe: $0.probe
                )
            }
        }
        guard reusableProbeStates.count
                == candidateAgentIDs.count - restoredCheckpointAgentIDs.count
        else {
            return failure(
                "Checkpoint load refused: live embodiment capture is incomplete."
            )
        }
        let retiredProbeStates = retiredBootstrapAgentIDs.compactMap { agentID in
            currentEmbodiments[agentID].map {
                PebbleAgentCheckpointProbeState(
                    agentID: agentID,
                    probe: $0.probe
                )
            }
        }
        guard retiredProbeStates.count == retiredBootstrapAgentIDs.count,
              retiredProbeStates.allSatisfy({
                  $0.carriedItems.allSatisfy { $0 == nil }
              }) else {
            return failure(
                "Checkpoint load refused: retired bootstrap custody is not empty."
            )
        }
        let ignoredRestoreEntityIDs = Set(
            retiredProbeStates.map { $0.probe.id }
                + probePlan.entries.compactMap { entry in
                    entry.classification == .repositionedVerified
                        ? entry.currentEmbodiment?.probe.id : nil
                }
        )
        do {
            for entry in probePlan.entries where
                entry.classification != .reusedExact {
                try prevalidateCheckpointProbeTarget(
                    for: entry.agent,
                    in: world,
                    ignoringEntityIDs: ignoredRestoreEntityIDs
                )
            }
        } catch {
            trace(
                "checkpoint probe position refused name=\(name.rawValue) "
                    + "reason=invalid_target"
            )
            return failure(
                "Checkpoint load refused: checkpoint probe target is invalid (\(error))."
            )
        }

        var reconciliationSummary = "legacy_exact"
        if candidate.persistenceReconciliationEnabled {
            guard let binding = stored.manifest.reconciliationBinding else {
                throw PebbleAgentPersistenceStoreError.invalidBundle(
                    "schema v20 checkpoint has no reconciliation binding"
                )
            }
            let request = try reconciliationRequest(
                binding: binding,
                candidate: candidate,
                world: world,
                store: store
            )
            let report = try candidate.applyPersistenceReconciliation(request)
            guard report.publishable, report.run.duplicationCount == 0 else {
                throw PebbleAgentPersistenceStoreError.invalidBundle(
                    "reconciliation did not produce a publishable session"
                )
            }
            let outcomes = report.run.assetResults.map(\.outcome.rawValue)
                .joined(separator: ",")
            reconciliationSummary = "applied:\(outcomes.isEmpty ? "none" : outcomes)"
            trace(
                "persistence reconciliation run=\(report.run.runID) "
                    + "checkpoint=\(report.run.checkpointID.rawValue) "
                    + "world=\(report.run.world.worldID) "
                    + "assets=\(report.run.assetResults.count) "
                    + "activities=\(report.run.activityResults.count) "
                    + "outcomes=\(outcomes.isEmpty ? "none" : outcomes) "
                    + "duplicates=\(report.run.duplicationCount) "
                    + "causal=\(report.run.causalSequenceBefore)"
                    + ">\(report.run.causalSequenceAfter)"
            )
        } else if stored.manifest.reconciliationBinding != nil {
            throw PebbleAgentPersistenceStoreError.invalidBundle(
                "legacy checkpoint has unexpected reconciliation binding"
            )
        }

        var candidateConstructionExecutor = PebbleAgentConstructionExecutor()
        if let project = candidate.constructionProject {
            try candidateConstructionExecutor.begin(project: project)
        }
        let candidateInteractionExecutor = PebbleAgentInteractionExecutor()
        var candidateNaturalResourceExecutor = PebbleAgentNaturalResourceExecutor()
        candidateNaturalResourceExecutor.restoreScanDiagnostics(
            stored.manifest.orchestration.naturalResourceScanDiagnostics
        )
        let candidateEcologyScanDiagnostics = PebbleAgentLocalEcologyScanDiagnostics(
            lastWorldTick: world.time,
            lastReason: "restored_checkpoint_requires_fresh_read_only_validation"
        )
        let candidateForageOutcome = candidate.localEcologySnapshot().forageHistory.last
        let restoredFocus = stored.manifest.orchestration.focusedAgentID
        guard restoredFocus.map(candidateAgentIDs.contains) ?? true else {
            throw PebbleAgentPersistenceStoreError.invalidBundle(
                "orchestration focus does not belong to the checkpoint"
            )
        }

        let oldConstructionExecutor = constructionExecutor
        let oldInteractionExecutor = interactionExecutor
        let oldNaturalResourceExecutor = naturalResourceExecutor
        let oldEcologyScanDiagnostics = lastEcologyScanDiagnostics
        let oldForageOutcome = lastForageOutcome
        let oldEcologyReason = lastEcologyReason
        let oldOrchestration = (
            cognitiveHz, isPaused, movementEnabled, autoInteractionEnabled, economyAutoEnabled,
            seed, anchor, focusedAgentId, followMode, credit, lastWorldTick, lastTickResult
        )
        let reusableProbeStatesByAgentID = Dictionary(
            uniqueKeysWithValues: reusableProbeStates.map {
                ($0.agentID, $0)
            }
        )
        let injectedPositionRestoreFailure =
            checkpointPositionRestoreFailurePoint
        checkpointPositionRestoreFailurePoint = nil
        var retiredProbesRemoved: [PebbleAgentCheckpointProbeState] = []
        var repositionedProbes: [PebbleAgentCheckpointProbeState] = []
        var restoredProbesCreated: [PebbleAgentCheckpointProbeState] = []
        do {
            for retired in retiredProbeStates.sorted(by: {
                $0.agentID < $1.agentID
            }) {
                guard removeLabCoreAgentProbe(retired.probe, from: world) else {
                    throw PebbleAgentPersistenceStoreError.invalidBundle(
                        "retired bootstrap probe removal failed"
                    )
                }
                probesByAgentId.removeValue(forKey: retired.agentID)
                retiredProbesRemoved.append(retired)
            }
            for entry in probePlan.entries where
                entry.classification == .repositionedVerified {
                guard let state = reusableProbeStatesByAgentID[
                    entry.agent.id
                ] else {
                    throw PebbleAgentPersistenceStoreError.invalidBundle(
                        "checkpoint reposition state missing for \(entry.agent.id)"
                    )
                }
                repositionedProbes.append(state)
                try restoreCheckpointProbePosition(
                    state.probe,
                    for: entry.agent,
                    in: world
                )
                if injectedPositionRestoreFailure
                    == .afterFirstReposition {
                    throw PebbleAgentPersistenceStoreError.invalidBundle(
                        "injected checkpoint failure after first reposition"
                    )
                }
            }
            for entry in probePlan.entries where
                entry.classification == .restoredMissing {
                let probe = try createProbe(for: entry.agent, in: world)
                probesByAgentId[entry.agent.id] = probe
                restoredProbesCreated.append(
                    PebbleAgentCheckpointProbeState(
                        agentID: entry.agent.id,
                        probe: probe
                    )
                )
                if injectedPositionRestoreFailure
                    == .afterFirstMissingCreation {
                    throw PebbleAgentPersistenceStoreError.invalidBundle(
                        "injected checkpoint failure after first missing creation"
                    )
                }
            }
            session = candidate
            constructionExecutor = candidateConstructionExecutor
            interactionExecutor = candidateInteractionExecutor
            naturalResourceExecutor = candidateNaturalResourceExecutor
            ecologicalObservationSensor.invalidateAll()
            lastEcologyScanDiagnostics = candidateEcologyScanDiagnostics
            lastForageOutcome = candidateForageOutcome
            lastEcologyReason = "restored from checkpoint"
            cognitiveHz = stored.manifest.orchestration.cognitiveHz
            isPaused = true
            movementEnabled = stored.manifest.orchestration.movementEnabled
            autoInteractionEnabled = stored.manifest.orchestration.autoInteractionEnabled
            economyAutoEnabled = stored.manifest.orchestration.economyAutoEnabled
            seed = stored.manifest.worldBinding.seed
            anchor = stored.manifest.worldBinding.anchor
            credit = 0
            lastWorldTick = world.time
            lastTickResult = nil
            focusedAgentId = restoredFocus ?? candidateAgentIDs.first
            if followTargetId() == nil { followMode = .off }
            let oldNonProbeEntities = Set(oldWorldEntities.compactMap {
                entity -> ObjectIdentifier? in
                entity is LabCoreAgentEntity ? nil : ObjectIdentifier(entity)
            })
            let currentNonProbeEntities = Set(world.entities.compactMap {
                entity -> ObjectIdentifier? in
                entity is LabCoreAgentEntity ? nil : ObjectIdentifier(entity)
            })
            let worldEntitiesExact = oldNonProbeEntities
                    == currentNonProbeEntities
                && world.entities.compactMap {
                    ($0 as? LabCoreAgentEntity)?.labAgentId
                }.sorted() == candidateAgentIDs
            let exactProbesUnchanged = probePlan.exactAgentIDs.allSatisfy {
                reusableProbeStatesByAgentID[$0]?.isUnchanged(
                    in: world,
                    mappedByAgentID: probesByAgentId
                ) == true
            }
            let repositionedProbesVerified = probePlan.entries.filter {
                $0.classification == .repositionedVerified
            }.allSatisfy { entry in
                reusableProbeStatesByAgentID[entry.agent.id]?.isRestored(
                    to: entry.agent.position,
                    in: world,
                    mappedByAgentID: probesByAgentId
                ) == true
            }
            let restoredProbesVerified = restoredProbesCreated.allSatisfy {
                $0.isUnchanged(
                    in: world,
                    mappedByAgentID: probesByAgentId
                )
            }
            let finalEmbodiments = try PebbleAgentEmbodiment.resolveAll(
                agentIDs: candidateAgentIDs,
                in: world,
                mappedByAgentID: probesByAgentId
            )
            let positionsExact = candidateAgents.allSatisfy {
                finalEmbodiments[$0.id]?.position == $0.position
            }
            guard worldEntitiesExact, exactProbesUnchanged,
                  repositionedProbesVerified, restoredProbesVerified,
                  positionsExact,
                  Set(finalEmbodiments.values.map(\.position)).count
                    == candidateAgentIDs.count,
                  probesByAgentId.keys.sorted() == candidateAgentIDs else {
                throw PebbleAgentPersistenceStoreError.invalidBundle(
                    "verified live probe reconciliation is not exact"
                )
            }
        } catch {
            session = oldSession
            constructionExecutor = oldConstructionExecutor
            interactionExecutor = oldInteractionExecutor
            naturalResourceExecutor = oldNaturalResourceExecutor
            lastEcologyScanDiagnostics = oldEcologyScanDiagnostics
            lastForageOutcome = oldForageOutcome
            lastEcologyReason = oldEcologyReason
            cognitiveHz = oldOrchestration.0
            isPaused = oldOrchestration.1
            movementEnabled = oldOrchestration.2
            autoInteractionEnabled = oldOrchestration.3
            economyAutoEnabled = oldOrchestration.4
            seed = oldOrchestration.5
            anchor = oldOrchestration.6
            focusedAgentId = oldOrchestration.7
            followMode = oldOrchestration.8
            credit = oldOrchestration.9
            lastWorldTick = oldOrchestration.10
            lastTickResult = oldOrchestration.11
            for restored in restoredProbesCreated.reversed() where
                world.entities.contains(where: { $0 === restored.probe }) {
                guard removeLabCoreAgentProbe(restored.probe, from: world) else {
                    let rollbackFailure =
                        "checkpoint restore rollback could not remove restored probe "
                            + restored.agentID
                    lastError = rollbackFailure
                    throw PebbleAgentPersistenceStoreError.invalidBundle(
                        rollbackFailure
                    )
                }
                probesByAgentId.removeValue(forKey: restored.agentID)
            }
            for repositioned in repositionedProbes.reversed() {
                repositioned.restorePriorPhysicalState()
            }
            for retired in retiredProbesRemoved where !world.entities.contains(
                where: { $0 === retired.probe }
            ) {
                world.addEntity(retired.probe)
            }
            probesByAgentId = oldProbesByAgentID
            let worldEntityIDs = Set(world.entities.map(ObjectIdentifier.init))
            let oldWorldEntityIDs = Set(oldWorldEntities.map(ObjectIdentifier.init))
            let probesUnchanged = (reusableProbeStates + retiredProbeStates).allSatisfy {
                $0.isUnchanged(
                    in: world,
                    mappedByAgentID: probesByAgentId
                )
            }
            guard worldEntityIDs == oldWorldEntityIDs, probesUnchanged else {
                let rollbackFailure =
                    "checkpoint restore rollback could not verify exact prior probes"
                lastError = rollbackFailure
                throw PebbleAgentPersistenceStoreError.invalidBundle(rollbackFailure)
            }
            trace(
                "checkpoint probe rollback verified name=\(name.rawValue) "
                    + "repositioned=\(repositionedProbes.count) "
                    + "restoredMissing=\(restoredProbesCreated.count) "
                    + "retired=\(retiredProbesRemoved.count)"
            )
            throw error
        }
        let causal = candidate.causalLedgerSnapshot().summary
        let reconciledDigest = try candidate.durableStateDigest()
        let probeReconciliation = probePlan.repositionedAgentIDs.isEmpty
            ? (retiredBootstrapAgentIDs.isEmpty
                ? (restoredCheckpointAgentIDs.isEmpty
                    ? "reused_exact"
                    : "restored_verified:\(restoredCheckpointAgentIDs.joined(separator: ","))")
                : "retired_verified:\(retiredBootstrapAgentIDs.joined(separator: ","))")
            : "repositioned_verified:\(probePlan.repositionedAgentIDs.joined(separator: ","))"
        let retiredEvidence = retiredBootstrapAgentIDs.isEmpty
            ? "none" : retiredBootstrapAgentIDs.joined(separator: ",")
        let restoredEvidence = restoredCheckpointAgentIDs.isEmpty
            ? "none" : restoredCheckpointAgentIDs.joined(separator: ",")
        let worldMutation = probePlan.repositionedAgentIDs.isEmpty
            ? "none" : "verified_probe_position_restore"
        let message = "checkpoint loaded name=\(name.rawValue) id=\(stored.checkpoint.checkpointID.rawValue) tick=\(candidate.tick) simulation=\(candidate.simulationID.rawValue) digest=\(checkpointDigest.rawValue) reconciledDigest=\(reconciledDigest.rawValue) causalSequence=\(causal.latestSequence) causalDigest=\(causal.digest) restartSafe=1 manifestIntegrity=verified:v\(stored.manifest.manifestIntegrityVersion ?? 0) probes=\(probesByAgentId.count) paused=1 focus=\(focusedAgentId ?? "none") lifecycleEvent=none probeReconciliation=\(probeReconciliation) probeReusedExact=\(probePlan.exactAgentIDs.count) probeRestoredMissing=\(probePlan.missingAgentIDs.count) probeRepositionedVerified=\(probePlan.repositionedAgentIDs.count) probeRetiredVerified=\(retiredBootstrapAgentIDs.count) probePositionRefused=0 probeRetired=\(retiredEvidence) probeRestored=\(restoredEvidence) physicalReconciliation=\(reconciliationSummary) worldMutation=\(worldMutation)"
        trace(message)
        return success(message)
    }
}
