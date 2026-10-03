import Foundation
import PebbleAgents
import PebbleCore

/// Correlation evidence only: checkpoint and World remain their existing owners.
struct PebbleWorldContinuation: Codable {
    let version: Int
    let revision: Int64
    let worldID: String
    let dimension: Int
    let worldRecordDigest: AgentCheckpointDigest
    let name: AgentCheckpointName
    let checkpointID: AgentCheckpointID
    let manifestDigest: AgentCheckpointDigest
    let founderCount: Int
}

enum PebbleWorldContinuationFailure {
    case checkpointCapture
    case afterFirstCustodyPreparation
    case custodyReturnVerification
}

struct PebbleWorldContinuationEnvelope: Codable {
    let continuation: PebbleWorldContinuation
    let digest: AgentCheckpointDigest

    init(_ continuation: PebbleWorldContinuation) throws {
        self.continuation = continuation
        digest = try continuationDigest(continuation)
    }

    func validated() throws -> PebbleWorldContinuation {
        guard digest == (try continuationDigest(continuation)) else {
            throw ContinuationError.refused("continuation integrity digest mismatch")
        }
        return continuation
    }
}

struct PebblePendingWorldContinuation {
    let name: AgentCheckpointName
    let stored: PebbleAgentStoredCheckpoint
    let probes: [PebbleAgentCheckpointProbeState]
    let previousHandoff: PebbleAgentCheckpointCustodyHandoff?
    let founderCount: Int
}

extension PebbleAgentController {
    /// Shared by the normal app and proofs; no startup fixture or founder load.
    func installWorldContinuation(on game: GameCore) {
        game.requiresExternalContinuation = { [weak self] in
            self?.session != nil && self?.bootstrapFounderProfile != nil
        }
        game.prepareExternalContinuation = { [weak self, weak game] in
            guard let self, let game else { return false }
            return self.prepareWorldContinuation(game: game)
        }
        game.completeExternalContinuation = { [weak self, weak game] saved, exiting in
            guard let self, let game else { return false }
            return self.completeWorldContinuation(game: game, saved: saved, exiting: exiting)
        }
        game.cancelExternalContinuation = { [weak self, weak game] in
            guard let self, let game else { return false }
            return self.cancelWorldContinuation(game: game)
        }
        game.restoreExternalContinuation = { [weak self, weak game] in
            guard let self, let game else { return false }
            return self.restoreWorldContinuation(game: game)
        }
    }

    private func prepareWorldContinuation(game: GameCore) -> Bool {
        defer { testingWorldContinuationFailure = nil }
        guard pendingWorldContinuation == nil, !continuationRestoreRefused,
              fatalSessionIntegrityFailure == nil,
              candidatePhysicalHardFailure == nil,
              let profile = bootstrapFounderProfile, session != nil,
              activeWorld === game.world, let id = game.worldRec?.id,
              persistenceFeatureEnabled, replayRecorder == nil else {
            lastError = "normal continuation capture refused at an unstable boundary"
            return false
        }
        persistenceWorldID = id
        persistenceDimension = game.dim.rawValue
        do {
            if testingWorldContinuationFailure == .checkpointCapture {
                throw ContinuationError.refused("injected civilization capture failure")
            }
            let store = try PebbleAgentPersistenceStore(worldID: id)
            let prior = game.db.worldContinuation(id)?.payload.flatMap {
                try? JSONDecoder().decode(PebbleWorldContinuationEnvelope.self, from: $0).validated()
            }
            let name = AgentCheckpointName(rawValue:
                prior?.name.rawValue == "ps01-continuation-a"
                    ? "ps01-continuation-b" : "ps01-continuation-a")!
            // At most two ordinary bundles. Only the unselected slot is reusable.
            if try store.checkpointNames().contains(name) {
                try store.deleteCheckpoint(name: name)
            }
            guard game.db.requireWorldContinuation(id) else {
                throw ContinuationError.refused("continuation requirement could not be persisted")
            }
            let previousHandoff = checkpointCustodyHandoff
            let result = handleCheckpoint(["save", name.rawValue], world: game.world, normalContinuationCapture: true)
            guard result.succeeded else { throw ContinuationError.refused(result.message) }
            let stored = try store.loadCheckpoint(name: name)
            guard stored.manifest.restartSafe else {
                throw ContinuationError.refused(stored.manifest.restartSafetyReason)
            }
            pendingWorldContinuation = PebblePendingWorldContinuation(
                name: name, stored: stored,
                probes: probesByAgentId.keys.sorted().compactMap { id in
                    probesByAgentId[id].map { PebbleAgentCheckpointProbeState(agentID: id, probe: $0) }
                }, previousHandoff: previousHandoff,
                founderCount: profile.specification.count)
            guard prepareForLifecyclePersistence(world: game.world) else {
                _ = completeWorldContinuation(game: game, saved: false, exiting: false)
                return false
            }
            return true
        } catch {
            lastError = "normal continuation capture refused: \(error)"
            trace(lastError!)
            return false
        }
    }

    private func completeWorldContinuation(game: GameCore, saved: Bool, exiting: Bool) -> Bool {
        guard candidatePhysicalHardFailure == nil, fatalSessionIntegrityFailure == nil,
              let pending = pendingWorldContinuation,
              let id = game.worldRec?.id else { return false }
        var preparedSpills: [ItemEntity]?
        var custodyReturned = false
        // A hard-failure diagnostic cannot replace these exact snapshots.
        // Publication alone also leaves the live owner reversible.
        defer { if custodyReturned { pendingWorldContinuation = nil } }
        do {
            let spills = try continuationSpills(pending, world: game.world, requireComplete: saved)
            preparedSpills = spills
            if !saved || !exiting {
                try returnContinuationCustody(pending, spills: spills, world: game.world)
                custodyReturned = true
            }
            guard saved, let record = game.db.getWorld(id),
                  let boundary = game.db.worldContinuation(id),
                  let manifestDigest = pending.stored.manifest.manifestIntegrityDigest else {
                throw ContinuationError.refused("World barrier failed; live custody retained")
            }
            let continuation = PebbleWorldContinuation(
                version: 1, revision: boundary.revision, worldID: id,
                dimension: game.dim.rawValue,
                worldRecordDigest: try continuationWorldDigest(record),
                name: pending.name, checkpointID: pending.stored.checkpoint.checkpointID,
                manifestDigest: manifestDigest, founderCount: pending.founderCount)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            guard game.db.publishWorldContinuation(id, revision: boundary.revision,
                                                   payload: try encoder.encode(PebbleWorldContinuationEnvelope(continuation))) else {
                throw ContinuationError.refused("late continuation publication failed")
            }
            trace("normal continuation saved name=\(pending.name.rawValue) revision=\(boundary.revision) exiting=\(exiting ? 1 : 0) custody=verified simulation=\(pending.stored.checkpoint.simulationID.rawValue)")
            // Publication is a durable snapshot, not irreversible teardown.
            // A replacement caller may still refuse destination admission.
            return true
        } catch {
            if !custodyReturned {
                do {
                    guard let preparedSpills else {
                        throw ContinuationError.refused("custody handoff could not be reconciled")
                    }
                    try returnContinuationCustody(pending, spills: preparedSpills, world: game.world)
                    custodyReturned = true
                } catch {
                    latchWorldContinuationHardFailure("\(error)", game: game)
                }
            }
            lastError = "normal continuation refused: \(error)"
            trace(lastError!)
            return false
        }
    }

    private func cancelWorldContinuation(game: GameCore) -> Bool {
        guard let pending = pendingWorldContinuation else {
            return candidatePhysicalHardFailure == nil
        }
        // Only this retained owner's failed compensation can be re-verified.
        // Never clear a different physical failure or fatal integrity latch.
        guard fatalSessionIntegrityFailure == nil else { return false }
        if let failure = candidatePhysicalHardFailure {
            guard failure.operation == "normal continuation",
                  failure.transactionID == "world-continuation",
                  failure.worldID == game.worldRec?.id,
                  failure.sessionID == session?.simulationID.rawValue,
                  failure.checkpointID == pending.stored.checkpoint.checkpointID.rawValue else { return false }
        }
        do {
            guard session != nil, activeWorld === game.world else {
                throw ContinuationError.refused("prepared civilization owner is unavailable")
            }
            let spills = try continuationSpills(pending, world: game.world, requireComplete: false)
            try returnContinuationCustody(pending, spills: spills, world: game.world)
            pendingWorldContinuation = nil
            candidatePhysicalHardFailure = nil
            // Recovery remains paused until explicit normal resume.
            // Disk keeps the coherent published checkpoint+escrow snapshot.
            // Dirty live chunks invalidate that reference on their next write,
            // exactly as for the existing Save/Continue custody return.
            trace("normal continuation lifecycle cancelled custody=verified")
            return true
        } catch {
            latchWorldContinuationHardFailure("\(error)", game: game)
            lastError = "normal continuation cancellation refused: \(error)"
            trace(lastError!)
            return false
        }
    }

    private func latchWorldContinuationHardFailure(_ reason: String, game: GameCore) {
        candidatePhysicalHardFailure = PebbleCandidatePhysicalHardFailure(
            operation: "normal continuation", transactionID: "world-continuation",
            mutation: "checkpoint custody handoff", expectedPhysicalState: "exact pre-save custody",
            observedPhysicalState: "unverifiable custody", compensationAttempt: "returnContinuationCustody",
            compensationError: reason, completedCompensations: [], remainingCompensations: ["custody reconciliation"],
            publishedSessionStatus: "retained and halted", physicalWorldTick: game.world.time,
            candidateReceiptIDs: [], worldID: game.worldRec?.id ?? "unknown",
            sessionID: session?.simulationID.rawValue ?? "none", checkpointID: pendingWorldContinuation?.stored.checkpoint.checkpointID.rawValue,
            agentID: nil, probeID: nil)
        isPaused = true
        credit = 0
        trace("CANDIDATE_PHYSICAL_HARD_FAILURE normal continuation rollback: \(reason)")
    }

    private func returnContinuationCustody(_ pending: PebblePendingWorldContinuation, spills: [ItemEntity], world: World) throws {
        // Returning custody changes only the live physical incarnation. Disk
        // retains the exact tagged escrow that restore will adopt.
        for item in spills {
            world.removeEntity(item)
            world.getChunkAt(Int(item.x.rounded(.down)), Int(item.z.rounded(.down)))?.modified = true
        }
        for state in pending.probes { state.restorePriorPhysicalState() }
        guard testingWorldContinuationFailure != .custodyReturnVerification,
              pending.probes.allSatisfy({ $0.isUnchanged(in: world, mappedByAgentID: probesByAgentId) }),
              spills.allSatisfy({ item in !world.entities.contains(where: { $0 === item }) }) else {
            throw ContinuationError.refused("live custody return could not be verified")
        }
        lifecyclePreparedWorld = nil
        checkpointCustodyHandoff = pending.previousHandoff
    }

    private func continuationSpills(_ pending: PebblePendingWorldContinuation, world: World, requireComplete: Bool) throws -> [ItemEntity] {
        let evidence = try pending.stored.manifest.protectedProbeCustodyEvidence(for: pending.stored.checkpoint) ?? []
        guard let digest = pending.stored.manifest.manifestIntegrityDigest else {
            throw ContinuationError.refused("missing custody boundary")
        }
        var expected: [String: ItemStack] = [:]
        for row in evidence {
            guard let state = pending.probes.first(where: { $0.agentID == row.agentID }) else {
                throw ContinuationError.refused("missing handoff probe")
            }
            if !requireComplete && state.probe.carriedItems == state.carriedItems { continue }
            guard state.probe.carriedItems.allSatisfy({ $0 == nil }) else {
                throw ContinuationError.refused("partial probe custody handoff")
            }
            let custody = try decodeCheckpointPhysicalCustodyEvidence(row)
            for item in row.items {
                expected[checkpointCustodySpillToken(checkpointID: pending.stored.checkpoint.checkpointID,
                    boundaryDigest: digest, agentID: row.agentID, item: item)] = custody.slots[item.slotOrdinal]!
            }
        }
        let spills = world.entities.compactMap { $0 as? ItemEntity }.filter {
            $0.custodyProvenance?.hasPrefix(pebbleCheckpointCustodySpillRoot) == true
        }
        guard pending.probes.count == probesByAgentId.count,
              pending.probes.allSatisfy({ state in
                  probesByAgentId[state.agentID] === state.probe
                    && world.entityById[state.probe.id] === state.probe
                    && state.probe.world === world && !state.probe.dead
                    && state.probe.x == state.x && state.probe.y == state.y && state.probe.z == state.z
              }),
              spills.count == expected.count,
              Set(spills.compactMap(\.custodyProvenance)) == Set(expected.keys),
              spills.allSatisfy({ !$0.dead && $0.world === world && expected[$0.custodyProvenance!] == $0.stack }),
              pending.probes.allSatisfy({ (!requireComplete && $0.probe.carriedItems == $0.carriedItems) || $0.probe.carriedItems.allSatisfy { $0 == nil } }) else {
            throw ContinuationError.refused("physical handoff is incomplete or conflicting")
        }
        return spills.sorted { $0.custodyProvenance! < $1.custodyProvenance! }
    }

    private func restoreWorldContinuation(game: GameCore) -> Bool {
        guard session == nil, activeWorld == nil else {
            lastError = "normal continuation restore refused: civilization already active"
            return false
        }
        continuationRestoreRefused = false
        guard let id = game.worldRec?.id else { return false }
        persistenceWorldID = id
        persistenceDimension = game.dim.rawValue
        guard let boundary = game.db.worldContinuation(id) else { return true }
        do {
            guard featureEnabled, persistenceFeatureEnabled,
                  session == nil, activeWorld == nil,
                  let bytes = boundary.payload else {
                throw ContinuationError.refused("required continuation is unavailable or its gates are disabled")
            }
            let continuation = try JSONDecoder().decode(PebbleWorldContinuationEnvelope.self, from: bytes).validated()
            guard continuation.version == 1, continuation.worldID == id,
                  continuation.revision == boundary.revision,
                  continuation.dimension == game.dim.rawValue,
                  continuation.worldRecordDigest == (try continuationWorldDigest(game.worldRec!)) else {
                throw ContinuationError.refused("stale or incompatible continuation boundary")
            }
            let profile = try PebbleNormalFounderProfile(count: continuation.founderCount)
            let store = try PebbleAgentPersistenceStore(worldID: id)
            let stored = try store.loadCheckpoint(name: continuation.name)
            guard stored.checkpoint.checkpointID == continuation.checkpointID,
                  stored.manifest.manifestIntegrityDigest == continuation.manifestDigest else {
                throw ContinuationError.refused("checkpoint does not belong to the World boundary")
            }
            let cells = stored.manifest.worldBinding.cells
            let chunks = Set(cells.map { chunkKey($0.position.x >> 4, $0.position.z >> 4) }).sorted().map { key -> (Int, Int) in
                let position = cells.first { chunkKey($0.position.x >> 4, $0.position.z >> 4) == key }!.position
                return (position.x >> 4, position.z >> 4)
            }
            guard game.prepareWorldContinuationChunks(dimension: continuation.dimension, coordinates: chunks) else {
                throw ContinuationError.refused("continuation physical chunks are unavailable")
            }
            anchor = stored.manifest.worldBinding.anchor
            let result = try loadLiveCheckpoint(name: continuation.name, world: game.world, store: store, continuingWorld: true)
            guard result.succeeded else { throw ContinuationError.refused(result.message) }
            bootstrapFounderProfile = profile
            isPaused = stored.manifest.orchestration.wasPaused
            game.world.applyPhysicalSimulationCoverage(physicalSimulationCoverageRequest(for: game.world))
            trace("normal continuation restored name=\(continuation.name.rawValue) revision=\(boundary.revision) foundersCreated=0 agents=\(session!.snapshot().agents.count) simulation=\(session!.simulationID.rawValue)")
            return true
        } catch {
            continuationRestoreRefused = true
            anchor = nil
            lastError = "normal continuation restore refused: \(error)"
            trace(lastError!)
            return false
        }
    }
}

private func continuationWorldDigest(_ record: WorldRecord) throws -> AgentCheckpointDigest {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return AgentCheckpointDigest.sha256(try encoder.encode(record))
}

private enum ContinuationError: Error {
    case refused(String)
}

private func continuationDigest(_ continuation: PebbleWorldContinuation) throws -> AgentCheckpointDigest {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return AgentCheckpointDigest.sha256(try encoder.encode(continuation))
}
