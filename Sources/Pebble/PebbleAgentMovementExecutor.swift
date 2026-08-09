import PebbleAgents
import PebbleCore

/// Pebble-owned live navigation boundary.
///
/// Cognition supplies an intent or a coarse waypoint. PebbleCore `findPath`
/// selects the detailed physical node and `Entity.move` owns collision and
/// actual displacement. Ordinary movement and rollback never use `setPos`.
struct PebbleAgentMovementExecutor {
    struct BoundedCoreStepProof {
        let pathFound: Bool
        let reachedCoreNode: Bool
        let occupiedRefused: Bool
        let explorationBoundaryRefused: Bool
        let physicalMutationCount: Int
        let rollbackVerified: Bool
        let latePublicationRejected: Bool
        let orientationChanged: Bool
        let node: AgentPosition?
    }

    enum ExecutionError: Error {
        case duplicateOutcome(String)
        case missingSnapshot(String)
        case outcomeSetMismatch
        case unboundedPhysicalDrift(String)
        case duplicatePhysicalPosition(String)
        case rollbackPerformed(String)
        case rollbackVerificationFailed(String)
    }

    func apply(
        intents: [AgentMovementOutcome],
        snapshot: AgentSessionSnapshot,
        world: World,
        probesByAgentId: [String: LabCoreAgentEntity],
        explorationDistanceBoundary: Int,
        additionalOccupiedPositions: Set<AgentPosition> = [],
        candidatePhysicalTransaction: PebbleCandidatePhysicalTransaction? = nil,
        postApplyValidation: ([AgentVerifiedPhysicalMovement]) throws -> Void = { _ in }
    ) throws -> [AgentVerifiedPhysicalMovement] {
        let agentsByID = Dictionary(uniqueKeysWithValues: snapshot.agents.map { ($0.id, $0) })
        var intentsByID: [String: AgentMovementOutcome] = [:]
        for intent in intents {
            guard intentsByID[intent.agentId] == nil else {
                throw ExecutionError.duplicateOutcome(intent.agentId)
            }
            intentsByID[intent.agentId] = intent
        }
        let ids = snapshot.agents.map(\.id).sorted()
        guard Set(intentsByID.keys) == Set(ids), Set(probesByAgentId.keys) == Set(ids) else {
            throw ExecutionError.outcomeSetMismatch
        }
        let embodiments = try PebbleAgentEmbodiment.resolveAll(
            agentIDs: ids,
            in: world,
            mappedByAgentID: probesByAgentId
        )

        let physicalPositions = ids.compactMap { embodiments[$0]?.position }
        guard Set(physicalPositions).count == physicalPositions.count else {
            throw ExecutionError.duplicatePhysicalPosition("initial")
        }

        // A bounded drift may arise at a lifecycle or World-adapter boundary.
        // Physical truth wins and is published explicitly before any new
        // navigation intent is executed. Larger drift is not guessed away.
        let drifted = ids.filter { id in
            guard let agent = agentsByID[id], let embodiment = embodiments[id] else { return false }
            return agent.position != embodiment.position
        }
        if !drifted.isEmpty {
            let reconciled = try ids.map { id -> AgentVerifiedPhysicalMovement in
                guard let agent = agentsByID[id], let embodiment = embodiments[id],
                      let intent = intentsByID[id] else {
                    throw ExecutionError.missingSnapshot(id)
                }
                let dx = embodiment.position.x - agent.position.x
                let dy = embodiment.position.y - agent.position.y
                let dz = embodiment.position.z - agent.position.z
                guard max(abs(dx), abs(dz)) <= 1, abs(dy) <= 1 else {
                    throw ExecutionError.unboundedPhysicalDrift(id)
                }
                let status: AgentMovementStatus = (dx == 0 && dy == 0 && dz == 0)
                    ? .notRequested : .moved
                return AgentVerifiedPhysicalMovement(
                    kind: .reconciliation,
                    outcome: makeOutcome(
                        intent: intent,
                        agent: agent,
                        status: status,
                        from: agent.position,
                        to: embodiment.position,
                        requestedDirection: nil,
                        requestedDX: 0,
                        requestedDY: 0,
                        requestedDZ: 0,
                        resolution: status == .moved
                            ? "verified physical truth reconciliation"
                            : "reconciliation peer stationary",
                        worldTick: world.time
                    )
                )
            }
            try postApplyValidation(reconciled)
            return reconciled
        }

        let initiallyOccupied = Set(physicalPositions).union(additionalOccupiedPositions)
        var claimed = Set<AgentPosition>()
        var movementReservation: PebbleCandidatePhysicalCompensationReservation?
        var movedStates: [(String, LabCoreAgentPhysicalState)] = []
        var verified: [AgentVerifiedPhysicalMovement] = []

        do {
            for id in ids {
                guard let agent = agentsByID[id], let intent = intentsByID[id],
                      let embodiment = embodiments[id] else {
                    throw ExecutionError.missingSnapshot(id)
                }
                guard intent.status == .moved else {
                    verified.append(AgentVerifiedPhysicalMovement(
                        kind: .navigationStep,
                        outcome: makeOutcome(
                            intent: intent,
                            agent: agent,
                            status: intent.status,
                            from: embodiment.position,
                            to: embodiment.position,
                            requestedDirection: intent.requestedDirection,
                            requestedDX: intent.requestedDX,
                            requestedDY: intent.requestedDY,
                            requestedDZ: intent.requestedDZ,
                            resolution: intent.resolutionReason,
                            worldTick: world.time
                        )
                    ))
                    continue
                }

                // The coarse route's endpoint is a waypoint/intent. Its next
                // node is deliberately not the live physical path authority.
                let destination = agent.navigationProgress.route?.positions.last
                    ?? intent.toPosition
                guard let path = findPath(
                    world,
                    embodiment.x, embodiment.y, embodiment.z,
                    Double(destination.x) + 0.5,
                    Double(destination.y),
                    Double(destination.z) + 0.5,
                    600,
                    true
                ), let node = path.first else {
                    verified.append(blocked(
                        intent: intent,
                        agent: agent,
                        at: embodiment.position,
                        reason: "PebbleCore path unavailable",
                        worldTick: world.time
                    ))
                    continue
                }
                let next = AgentPosition(x: node.x, y: node.y, z: node.z)
                let dx = next.x - embodiment.position.x
                let dy = next.y - embodiment.position.y
                let dz = next.z - embodiment.position.z
                guard max(abs(dx), abs(dz)) == 1, (-1...1).contains(dy) else {
                    verified.append(blocked(
                        intent: intent,
                        agent: agent,
                        at: embodiment.position,
                        reason: "PebbleCore path requested unsupported vertical step",
                        worldTick: world.time
                    ))
                    continue
                }
                if agent.currentGoal.kind == .explore,
                   !permitsExplorationCoreStep(
                       from: embodiment.position,
                       to: next,
                       home: agent.homePosition,
                       maximumDistance: explorationDistanceBoundary
                   ) {
                    verified.append(blocked(
                        intent: intent,
                        agent: agent,
                        at: embodiment.position,
                        reason: "Core step exceeds exploration home boundary",
                        worldTick: world.time
                    ))
                    continue
                }
                guard !initiallyOccupied.subtracting([embodiment.position]).contains(next),
                      !claimed.contains(next) else {
                    verified.append(blocked(
                        intent: intent,
                        agent: agent,
                        at: embodiment.position,
                        reason: "physical destination occupied",
                        worldTick: world.time
                    ))
                    continue
                }

                let original = embodiment.probe.capturePhysicalState()
                if movementReservation == nil, let candidatePhysicalTransaction {
                    movementReservation = try candidatePhysicalTransaction.reserve(
                        compensationID: "movement-batch:\(snapshot.tick)"
                    )
                }
                embodiment.probe.prevX = original.x
                embodiment.probe.prevY = original.y
                embodiment.probe.prevZ = original.z
                embodiment.probe.prevYaw = original.yaw
                embodiment.probe.prevPitch = original.pitch
                embodiment.probe.yaw = detAtan2(
                    -(Double(next.x) + 0.5 - original.x),
                    Double(next.z) + 0.5 - original.z
                )
                embodiment.probe.move(
                    Double(next.x) + 0.5 - original.x,
                    Double(next.y) - original.y,
                    Double(next.z) + 0.5 - original.z
                )

                guard embodiment.position == next else {
                    try rollback(
                        embodiment.probe,
                        to: original,
                        context: "blocked-step:\(id)"
                    )
                    verified.append(blocked(
                        intent: intent,
                        agent: agent,
                        at: agent.position,
                        reason: "PebbleCore collision blocked movement",
                        worldTick: world.time
                    ))
                    continue
                }
                movedStates.append((id, original))
                claimed.insert(next)
                verified.append(AgentVerifiedPhysicalMovement(
                    kind: .navigationStep,
                    outcome: makeOutcome(
                        intent: intent,
                        agent: agent,
                        status: .moved,
                        from: agent.position,
                        to: next,
                        requestedDirection: intent.requestedDirection,
                        requestedDX: intent.requestedDX,
                        requestedDY: intent.requestedDY,
                        requestedDZ: intent.requestedDZ,
                        resolution: "PebbleCore path and Entity.move verified",
                        worldTick: world.time
                    )
                ))
            }
            try postApplyValidation(verified)
            if let candidatePhysicalTransaction,
               let movementReservation,
               !movedStates.isEmpty {
                let expectedAfter = movedStates.compactMap { id, _ in
                    embodiments[id].map {
                        (id: id, probe: $0.probe, state: $0.probe.capturePhysicalState())
                    }
                }
                let compensation = PebbleCandidatePhysicalCompensation(
                    reservation: movementReservation,
                    mutation: "verified physical movement batch",
                    agentID: movedStates.map(\.0).joined(separator: ","),
                    probeID: movedStates.compactMap { id, _ in
                        embodiments[id]?.physicalID
                    }.joined(separator: ","),
                    expectedBefore: movedStates.map {
                        "\($0.0)={\($0.1)}"
                    }.joined(separator: ";"),
                    observedState: {
                        expectedAfter.map {
                            "\($0.id)={\($0.probe.capturePhysicalState())}"
                        }.joined(separator: ";")
                    },
                    compensate: {
                        guard expectedAfter.allSatisfy({ id, probe, expected in
                            guard let embodiment = embodiments[id] else { return false }
                            return embodiment.probe === probe
                                && embodiment.isValid(in: world)
                                && probe.capturePhysicalState() == expected
                        }) else { return false }
                        for (id, original) in movedStates.reversed() {
                            guard let embodiment = embodiments[id],
                                  embodiment.isValid(in: world),
                                  embodiment.probe.restorePhysicalState(original) else {
                                return false
                            }
                        }
                        return movedStates.allSatisfy { id, original in
                            embodiments[id]?.probe.capturePhysicalState() == original
                        }
                    }
                )
                try candidatePhysicalTransaction.register(compensation)
            }
            return verified
        } catch {
            do {
                try restoreMovedStates(
                    movedStates,
                    embodiments: embodiments,
                    context: "late-publication"
                )
            } catch {
                throw ExecutionError.rollbackVerificationFailed(String(describing: error))
            }
            throw ExecutionError.rollbackPerformed(String(describing: error))
        }
    }

    /// Disposable live-proof seam over the exact Core path/move/rollback
    /// primitives used above. It never publishes a session result and always
    /// restores the temporary proof body physically before returning.
    func proveBoundedCoreStep(
        world: World,
        embodiment: PebbleAgentEmbodiment,
        destination: AgentPosition,
        occupied: Set<AgentPosition> = [],
        explorationHomePosition: AgentPosition? = nil,
        explorationDistanceBoundary: Int? = nil,
        rejectAfterPhysicalMove: Bool = false
    ) throws -> BoundedCoreStepProof {
        guard embodiment.isValid(in: world),
              let path = findPath(
                world,
                embodiment.x, embodiment.y, embodiment.z,
                Double(destination.x) + 0.5,
                Double(destination.y),
                Double(destination.z) + 0.5,
                600,
                true
              ), let node = path.first else {
            return BoundedCoreStepProof(
                pathFound: false,
                reachedCoreNode: false,
                occupiedRefused: false,
                explorationBoundaryRefused: false,
                physicalMutationCount: 0,
                rollbackVerified: true,
                latePublicationRejected: rejectAfterPhysicalMove,
                orientationChanged: false,
                node: nil
            )
        }
        let next = AgentPosition(x: node.x, y: node.y, z: node.z)
        if let explorationHomePosition, let explorationDistanceBoundary,
           !permitsExplorationCoreStep(
               from: embodiment.position,
               to: next,
               home: explorationHomePosition,
               maximumDistance: explorationDistanceBoundary
           ) {
            return BoundedCoreStepProof(
                pathFound: true,
                reachedCoreNode: false,
                occupiedRefused: false,
                explorationBoundaryRefused: true,
                physicalMutationCount: 0,
                rollbackVerified: true,
                latePublicationRejected: false,
                orientationChanged: false,
                node: next
            )
        }
        guard !occupied.contains(next) else {
            return BoundedCoreStepProof(
                pathFound: true,
                reachedCoreNode: false,
                occupiedRefused: true,
                explorationBoundaryRefused: false,
                physicalMutationCount: 0,
                rollbackVerified: true,
                latePublicationRejected: false,
                orientationChanged: false,
                node: next
            )
        }
        let original = embodiment.probe.capturePhysicalState()
        embodiment.probe.prevX = original.x
        embodiment.probe.prevY = original.y
        embodiment.probe.prevZ = original.z
        embodiment.probe.yaw = detAtan2(
            -(Double(next.x) + 0.5 - original.x),
            Double(next.z) + 0.5 - original.z
        )
        embodiment.probe.move(
            Double(next.x) + 0.5 - original.x,
            Double(next.y) - original.y,
            Double(next.z) + 0.5 - original.z
        )
        let reached = embodiment.position == next
        let orientationChanged = embodiment.probe.yaw != original.yaw
        try rollback(
            embodiment.probe,
            to: original,
            context: rejectAfterPhysicalMove ? "proof-late-publication" : "proof-cleanup"
        )
        return BoundedCoreStepProof(
            pathFound: true,
            reachedCoreNode: reached,
            occupiedRefused: false,
            explorationBoundaryRefused: false,
            physicalMutationCount: 1,
            rollbackVerified: embodiment.position == AgentPosition(
                x: Int(original.x.rounded(.down)),
                y: Int(original.y.rounded(.down)),
                z: Int(original.z.rounded(.down))
            ),
            latePublicationRejected: rejectAfterPhysicalMove && reached,
            orientationChanged: orientationChanged,
            node: next
        )
    }

    private func blocked(
        intent: AgentMovementOutcome,
        agent: AgentSnapshot,
        at position: AgentPosition,
        reason: String,
        worldTick: Int
    ) -> AgentVerifiedPhysicalMovement {
        AgentVerifiedPhysicalMovement(
            kind: .navigationStep,
            outcome: makeOutcome(
                intent: intent,
                agent: agent,
                status: .blocked,
                from: position,
                to: position,
                requestedDirection: intent.requestedDirection,
                requestedDX: intent.requestedDX,
                requestedDY: intent.requestedDY,
                requestedDZ: intent.requestedDZ,
                resolution: reason,
                worldTick: worldTick
            )
        )
    }

    private func makeOutcome(
        intent: AgentMovementOutcome,
        agent: AgentSnapshot,
        status: AgentMovementStatus,
        from: AgentPosition,
        to: AgentPosition,
        requestedDirection: AgentCardinalDirection?,
        requestedDX: Int,
        requestedDY: Int,
        requestedDZ: Int,
        resolution: String,
        worldTick: Int
    ) -> AgentMovementOutcome {
        let before = distance(from, agent.homePosition)
        let after = distance(to, agent.homePosition)
        return AgentMovementOutcome(
            agentId: intent.agentId,
            tick: intent.tick,
            status: status,
            fromPosition: from,
            toPosition: to,
            requestedDirection: requestedDirection,
            requestedDX: requestedDX,
            requestedDY: requestedDY,
            requestedDZ: requestedDZ,
            appliedDX: to.x - from.x,
            appliedDY: to.y - from.y,
            appliedDZ: to.z - from.z,
            goalKind: intent.goalKind,
            actionReason: intent.actionReason,
            resolutionReason: resolution,
            worldTickObserved: worldTick,
            distanceFromHomeBefore: before,
            distanceFromHomeAfter: after,
            distanceReducedTowardHome: max(0, before - after)
        )
    }

    private func distance(_ lhs: AgentPosition, _ rhs: AgentPosition) -> Int {
        abs(lhs.x - rhs.x) + abs(lhs.y - rhs.y) + abs(lhs.z - rhs.z)
    }

    private func permitsExplorationCoreStep(
        from: AgentPosition,
        to: AgentPosition,
        home: AgentPosition,
        maximumDistance: Int
    ) -> Bool {
        AgentFeedbackLoop.respectsExplorationHomeBoundary(
            distanceBefore: distance(from, home),
            distanceAfter: distance(to, home),
            maximumDistance: maximumDistance
        )
    }

    private func rollback(
        _ probe: LabCoreAgentEntity,
        to original: LabCoreAgentPhysicalState,
        context: String
    ) throws {
        guard probe.restorePhysicalState(original) else {
            throw ExecutionError.rollbackVerificationFailed(
                "\(context):expected={\(original)} "
                    + "observed={\(probe.capturePhysicalState())}"
            )
        }
    }

    private func restoreMovedStates(
        _ movedStates: [(String, LabCoreAgentPhysicalState)],
        embodiments: [String: PebbleAgentEmbodiment],
        context: String
    ) throws {
        for (id, original) in movedStates.reversed() {
            guard let embodiment = embodiments[id] else {
                throw ExecutionError.missingSnapshot(id)
            }
            try rollback(
                embodiment.probe,
                to: original,
                context: "\(context):\(id)"
            )
        }
    }
}
