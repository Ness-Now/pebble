import Foundation
import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func handleBuild(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab build <setup|auto on|auto off|status|clear>"
        guard let subcommand = arguments.first?.lowercased() else {
            return failure(usage)
        }
        guard var session, activeWorld === world else {
            return failure("No active PebbleAgents session for this World.")
        }

        if subcommand == "status" {
            guard arguments.count == 1 else { return failure(usage) }
            let snapshot = session.snapshot()
            let project = snapshot.constructionProject
            let builder = project.flatMap { active in
                snapshot.agents.first { $0.id == active.builderAgentId }
            }
            let demand = session.constructionDemand()
            let required = project?.materialRequirements.map {
                "\($0.resource.rawValue):\($0.quantity)"
            }.joined(separator: ",") ?? "wood:6,stone:3"
            let missing = demand?.missing.map {
                "\($0.resource.rawValue):\($0.quantity)"
            }.joined(separator: ",") ?? "none"
            let escrow = project.map {
                "wood:\($0.materialEscrow.count(of: .wood)),stone:\($0.materialEscrow.count(of: .stone))"
            } ?? "wood:0,stone:0"
            let placed = project.map {
                "wood:\($0.placedMaterialTotals.count(of: .wood)),stone:\($0.placedMaterialTotals.count(of: .stone))"
            } ?? "wood:0,stone:0"
            let stock = "wood:\(snapshot.campStock.count(of: .wood)),stone:\(snapshot.campStock.count(of: .stone))"
            let conservation = snapshot.conservation
            let executor = constructionExecutor.state
            let message = "build gate=\(buildFeatureEnabled ? "enabled" : "disabled") auto=\(snapshot.buildAutoEnabled ? "on" : "off") project=\(project?.projectId ?? "none") blueprint=\(project?.blueprintId ?? AgentBlueprint.fixedLeanToV1Id) builder=\(project?.builderAgentId ?? "none") origin=\(project.map { positionText($0.origin) } ?? "none") status=\(project?.status.rawValue ?? "none") required=\(required) missing=\(missing.isEmpty ? "none" : missing) escrow=\(escrow) placedMaterials=\(placed) placed=\(project?.placedCellIndices.count ?? 0)/\(project?.blueprint.cells.count ?? 9) nextCell=\(project?.nextCellIndex ?? 0) nextTarget=\(project?.nextTarget.map(positionText) ?? "none") work=\(project?.nextWorkPosition.map(positionText) ?? "none") builderPosition=\(builder.map { positionText($0.position) } ?? "none") navigation=\(builder?.navigationProgress.status.rawValue ?? "idle") route=\(builder?.navigationProgress.route?.positions.count ?? 0):\(builder?.navigationProgress.routeIndex ?? 0) stock=\(stock) home=\(builder.map { positionText($0.homePosition) } ?? "none") rest=\(project.map { positionText($0.restPosition) } ?? "none") lastPlacement=\(project?.lastPlacementOutcome?.status.rawValue ?? executor.lastPlacement) failure=\(project?.lastFailure?.rawValue ?? executor.lastFailure) rollback=\(executor.rollbackCount) clear=\(executor.lastClear) siteCandidates=\(lastConstructionSiteDiagnostics.candidatesConsidered) siteReads=\(lastConstructionSiteDiagnostics.positionsRead) siteBest=\(lastConstructionSiteDiagnostics.maximumWorkPositionsFound)/9@\(lastConstructionSiteDiagnostics.bestOrigin.map(positionText) ?? "none"): \(lastConstructionSiteDiagnostics.bestFlags) siteRejects=chunk:\(lastConstructionSiteDiagnostics.chunkRejected),floor:\(lastConstructionSiteDiagnostics.floorRejected),replaceable:\(lastConstructionSiteDiagnostics.replaceableRejected),liquid:\(lastConstructionSiteDiagnostics.liquidRejected),natural:\(lastConstructionSiteDiagnostics.naturalRejected),reserved:\(lastConstructionSiteDiagnostics.reservedRejected),work:\(lastConstructionSiteDiagnostics.workRejected),occupancy:\(lastConstructionSiteDiagnostics.occupancyRejected),route:\(lastConstructionSiteDiagnostics.routeRejected) conservation=\(conservation.harvestedTotal):\(conservation.carriedTotal)+\(conservation.campStockTotal)+\(conservation.consumedTotal)+\(conservation.constructionEscrowTotal)+\(conservation.constructedTotal):\(conservation.balanced ? "exact" : "diverged") reason=\(lastConstructionReason.replacingOccurrences(of: " ", with: "_"))"
            trace(message)
            return success(message)
        }

        guard featureEnabled else {
            return failure("PebbleAgents disabled. Set PEBBLELAB_APP_AGENTS=1 before launch.")
        }
        guard buildFeatureEnabled else {
            return failure("PebbleAgents construction disabled. Set PEBBLELAB_APP_AGENTS_BUILD=1 before launch.")
        }

        if subcommand == "auto" {
            guard arguments.count == 2,
                  arguments[1].lowercased() == "on"
                    || arguments[1].lowercased() == "off" else {
                return failure(usage)
            }
            let enabled = arguments[1].lowercased() == "on"
            if enabled, !movementFeatureEnabled {
                return failure("PebbleAgents movement disabled. Set PEBBLELAB_APP_AGENTS_MOVE=1 before launch.")
            }
            do {
                if try applyCommandMutationIfRecording(
                    .setBuildAutoEnabled(enabled),
                    session: &session
                ) == nil {
                    try session.setBuildAutoEnabled(enabled)
                }
                self.session = session
                lastConstructionReason = enabled ? "enabled by command" : "suspended by command"
                trace("build auto=\(enabled ? "on" : "off") tick=\(session.tick) mutation=none")
                return success("PebbleAgents construction automatic mode \(enabled ? "on" : "off").")
            } catch {
                return failure("Construction auto mode failed: \(error)")
            }
        }

        if subcommand == "clear" {
            guard arguments.count == 1 else { return failure(usage) }
            guard isPaused else {
                return failure("Construction clear requires a paused PebbleAgents session.")
            }
            guard !movementEnabled else {
                return failure("Construction clear requires movement off.")
            }
            guard let project = session.constructionProject else {
                return failure("No construction project to clear.")
            }
            var candidate = session
            var candidateRecorder = replayRecorder
            let injectClearFailure = environment[
                "PEBBLELAB_APP_AGENTS_BUILD_FAIL_CLEAR_AFTER_WORLD"
            ] == "1"
            do {
                try constructionExecutor.clear(
                    world: world,
                    project: project,
                    prevalidate: {
                        try session.prevalidateConstructionClear(projectId: project.projectId)
                    },
                    publishAndVerify: {
                        if try applyRecordedOperationIfActive(
                            .clearConstructionProject(projectID: project.projectId),
                            session: &candidate,
                            recorder: &candidateRecorder
                        ) == nil {
                            try candidate.clearConstructionProject(projectId: project.projectId)
                        }
                        if injectClearFailure {
                            throw ControllerError.constructionBoundary(
                                "injected construction clear publication failure"
                            )
                        }
                        guard candidate.constructionProject == nil,
                              candidate.conservationSnapshot().balanced else {
                            throw ControllerError.constructionBoundary(
                                "construction clear publication verification failed"
                            )
                        }
                    }
                )
                session = candidate
                replayRecorder = candidateRecorder
                self.session = session
                lastConstructionReason = "cleared and restored"
                let restored = constructionExecutor.state.cleanupRestoredBlockCount
                trace("build clear project=\(project.projectId) restored=\(restored) conservation=exact")
                return success("Construction cleared; restored \(restored) project blocks and refunded materials.")
            } catch {
                return failure("Construction clear failed: \(error)")
            }
        }

        guard subcommand == "setup", arguments.count == 1 else {
            return failure(usage)
        }
        guard isPaused else {
            return failure("Construction setup requires a paused PebbleAgents session.")
        }
        guard !movementEnabled else {
            return failure("Construction setup requires movement off.")
        }
        guard session.constructionProject == nil else {
            return failure("Construction setup refused: a project already exists.")
        }
        guard let builderId = focusedAgentId,
              let builder = session.snapshot().agents.first(where: { $0.id == builderId }) else {
            return failure("Construction setup requires a valid focused builder.")
        }
        let occupied = session.snapshot().agents
            .filter { $0.id != builderId }
            .map(\.position)
        let playerPosition = AgentPosition(
            x: Int(player.x.rounded(.down)),
            y: Int(player.y.rounded(.down)),
            z: Int(player.z.rounded(.down))
        )
        var siteDiagnostics = PebbleAgentConstructionSiteDiagnostics()
        do {
            let selection = try constructionSiteAdapter.select(
                world: world,
                builder: builder,
                occupiedAgentPositions: occupied,
                playerPosition: playerPosition,
                tick: session.tick,
                diagnostics: &siteDiagnostics
            )
            var candidate = session
            var candidateRecorder = replayRecorder
            if try applyRecordedOperationIfActive(
                .createConstructionProject(selection.project),
                session: &candidate,
                recorder: &candidateRecorder
            ) == nil {
                try candidate.createConstructionProject(selection.project)
            }
            var executorCandidate = constructionExecutor
            try executorCandidate.begin(project: selection.project)
            session = candidate
            replayRecorder = candidateRecorder
            constructionExecutor = executorCandidate
            self.session = session
            lastConstructionSiteDiagnostics = selection.diagnostics
            lastConstructionReason = "safe site selected read-only"
            trace("build setup project=\(selection.project.projectId) builder=\(builderId) origin=\(positionText(selection.project.origin)) candidates=\(selection.diagnostics.candidatesConsidered) positionsRead=\(selection.diagnostics.positionsRead) worldMutations=0")
            return success("Construction project \(selection.project.projectId) planned at \(positionText(selection.project.origin)); setup mutations: 0.")
        } catch {
            siteDiagnostics.lastFailure = String(describing: error)
            lastConstructionSiteDiagnostics = siteDiagnostics
            lastConstructionReason = "setup failed without mutation"
            return failure("Construction setup failed without World mutation: \(error)")
        }
    }

}
