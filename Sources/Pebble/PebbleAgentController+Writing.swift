import Foundation
import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func handleWriting(
        _ arguments: [String],
        world: World,
        player: Player,
        game: GameCore?
    ) -> PebbleAgentCommandResult {
        guard environment["PEBBLELAB_APP_AGENTS_WRITING"] == "1",
              activeWorld === world, var current = session,
              let worldID = persistenceWorldID, isPaused, !movementEnabled else {
            return failure("Writing requires its explicit gate, an active paused World session and movement off.")
        }
        let adapter = PebbleAgentWritingAdapter()
        var commandRecorder = replayRecorder
        func recorded(_ operation: AgentReplayOperation) throws -> Bool {
            try applyRecordedOperationIfActive(operation, session: &current, recorder: &commandRecorder) != nil
        }
        do {
            switch arguments.first {
            case "on" where arguments.count == 1:
                guard commandRecorder == nil || (current.socialEnabled && current.knowledgeGraphEnabled
                    && current.languageState?.enabled == true) else {
                    throw AgentWritingError.unavailable("recording activation requires a CIV-41/42 base checkpoint")
                }
                try current.setSocialEnabled(true)
                try current.setKnowledgeGraphEnabled(true)
                try current.setLanguageEnabled(true)
                if try !recorded(.setWritingEnabled(enabled: true, worldID: worldID, configuration: .live)) {
                    try current.setWritingEnabled(true, worldID: worldID)
                }
            case "prior" where arguments.count == 2:
                let id = arguments[1]
                guard let owner = AgentID(rawValue: id) else { throw AgentWritingError.invalidState("owner") }
                if try !recorded(.seedWritingEducationalPrior(ownerID: owner)) {
                    try current.seedWritingEducationalPrior(for: owner)
                }
            case "inscribe" where arguments.count == 6:
                let (id, proposition, x, y, z) = (arguments[1], arguments[2], arguments[3], arguments[4], arguments[5])
                guard let author = AgentID(rawValue: id), let actor = probesByAgentId[id],
                      let proposition = AgentKnowledgePropositionID(rawValue: proposition),
                      let x = Int(x), let y = Int(y), let z = Int(z) else {
                    throw AgentWritingError.invalidState("inscribe arguments")
                }
                let plan = try current.prepareWriting(authorID: author, propositionID: proposition,
                    materialID: peekNextEntityId(), dimension: String(world.dim.rawValue), cell: AgentPosition(x: x, y: y, z: z))
                _ = try adapter.inscribe(plan: plan, actor: actor, world: world, worldID: worldID,
                    session: current, publication: { candidate, receipt in
                        if try self.applyRecordedOperationIfActive(.acceptWriting(plan: plan, receipt: receipt),
                            session: &candidate, recorder: &commandRecorder) != nil {
                            return candidate.writingState!.artifacts.last!
                        }
                        return try candidate.acceptWriting(plan, receipt: receipt)
                    }, commit: { committed in
                        current = committed
                        self.session = committed
                        self.replayRecorder = commandRecorder
                    })
            case "read" where arguments.count == 3:
                let (id, artifactID) = (arguments[1], arguments[2])
                guard let actor = probesByAgentId[id], let artifact = current.writingState?.artifacts.first(where: {
                    $0.artifactID == artifactID
                }) else { throw AgentWritingError.unavailable("reader or inscription") }
                _ = try adapter.read(artifact: artifact, actor: actor, world: world,
                    worldID: worldID, session: current, publication: { candidate, receipt in
                        if try self.applyRecordedOperationIfActive(
                            .readWriting(artifactID: artifactID, readerID: receipt.actorID, receipt: receipt),
                            session: &candidate,
                            recorder: &commandRecorder
                        ) != nil {
                            return candidate.writingState!.readings.last!
                        }
                        return try candidate.readWriting(
                            artifactID: artifactID,
                            readerID: receipt.actorID,
                            receipt: receipt
                        )
                    }, commit: { committed in
                        current = committed
                        self.session = committed
                        self.replayRecorder = commandRecorder
                    })
            case "practice" where arguments.count == 4:
                let (teacher, learner, artifactID) = (arguments[1], arguments[2], arguments[3])
                guard let teacherActor = probesByAgentId[teacher], let learnerActor = probesByAgentId[learner],
                      let artifact = current.writingState?.artifacts.first(where: { $0.artifactID == artifactID }) else {
                    throw AgentWritingError.unavailable("lesson participants or inscription")
                }
                try adapter.practice(artifact: artifact, teacher: teacherActor, learner: learnerActor,
                    world: world, worldID: worldID, session: current,
                    publication: { candidate, teacherReceipt, learnerReceipt in
                        if try self.applyRecordedOperationIfActive(
                            .practiceWritingNotation(
                                artifactID: artifactID,
                                teacherID: teacherReceipt.actorID,
                                learnerID: learnerReceipt.actorID,
                                teacherReceipt: teacherReceipt,
                                learnerReceipt: learnerReceipt
                            ),
                            session: &candidate,
                            recorder: &commandRecorder
                        ) == nil {
                            try candidate.practiceWritingNotation(
                                artifactID: artifactID,
                                teacherID: teacherReceipt.actorID,
                                learnerID: learnerReceipt.actorID,
                                teacherReceipt: teacherReceipt,
                                learnerReceipt: learnerReceipt
                            )
                        }
                    }, commit: { committed in
                        current = committed
                        self.session = committed
                        self.replayRecorder = commandRecorder
                    })
            case "status" where arguments.count == 2:
                let id = arguments[1]
                guard let actor = probesByAgentId[id] else { throw AgentWritingError.unavailable("actor") }
                for artifact in current.writingState?.artifacts ?? [] {
                    let present = (try? adapter.inspect(plan: artifact.plan, actor: actor,
                        world: world, worldID: worldID, tick: current.tick)) != nil
                    trace("writing inspection artifact=\(artifact.artifactID) localMaterialAccess=\(present ? "verified" : "unavailable") historicalOnly=1")
                }
            case "proof" where arguments.count == 2:
                let phase = arguments[1]
                guard commandRecorder == nil else { throw AgentWritingError.unavailable("proof while recording") }
                return runWritingProof(phase: phase, world: world, player: player, game: game)
            default:
                return failure("Usage: /lab writing on|prior <agent>|inscribe <agent> <proposition> <x> <y> <z>|read <agent> <artifact>|practice <teacher> <learner> <artifact>|status <agent>")
            }
            session = current
            replayRecorder = commandRecorder
            return success("Writing operation accepted; World access remains local and verified.")
        } catch {
            trace("writing refused reason=\(error)")
            return failure("Writing refused: \(error)")
        }
    }
}
