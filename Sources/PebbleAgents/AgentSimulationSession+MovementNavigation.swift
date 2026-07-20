extension AgentSimulationSession {
    public mutating func applyExternalUpdate(_ update: AgentExternalUpdate) throws {
        guard var state = statesById[update.agentId] else {
            throw AgentSessionError.unknownAgentId(update.agentId)
        }
        if let position = update.position {
            state.position = position
        }
        appendMemories(update.memoryEntries, to: &state.memory)
        if let movementCount = update.movementCount {
            state.movementCount = movementCount
        }
        if let total = update.totalManhattanDistanceMoved {
            state.totalManhattanDistanceMoved = total
        }
        if let count = update.returnHomeMoveCount {
            state.returnHomeMoveCount = count
        }
        if let total = update.totalDistanceReducedTowardHome {
            state.totalDistanceReducedTowardHome = total
        }
        statesById[update.agentId] = state
    }

    public mutating func applyMovementOutcomes(_ outcomes: [AgentMovementOutcome]) throws {
        var candidate = self
        try candidate.applyMovementOutcomesInPlace(outcomes, verifiedKinds: nil)
        self = candidate
    }

    /// Publishes positions observed after Pebble-owned physical movement.
    ///
    /// Detailed path selection, collision, and embodiment validity are adapter
    /// responsibilities. This method validates the pure result and deliberately
    /// does not require it to equal a coarse planner's suggested next cell.
    public mutating func applyVerifiedPhysicalMovements(
        _ movements: [AgentVerifiedPhysicalMovement]
    ) throws {
        var kinds: [String: AgentVerifiedPhysicalMovementKind] = [:]
        for movement in movements {
            guard kinds[movement.outcome.agentId] == nil else {
                throw AgentSessionError.duplicateMovementOutcome(movement.outcome.agentId)
            }
            kinds[movement.outcome.agentId] = movement.kind
        }
        var candidate = self
        try candidate.applyMovementOutcomesInPlace(
            movements.map(\.outcome),
            verifiedKinds: kinds
        )
        self = candidate
    }

    private mutating func applyMovementOutcomesInPlace(
        _ outcomes: [AgentMovementOutcome],
        verifiedKinds: [String: AgentVerifiedPhysicalMovementKind]?
    ) throws {
        let populationArrivalEventCapacity = populationRegistry?.migrations.contains {
            $0.status == .admitted || $0.status == .inTransit
        } == true ? 2 : 0
        let currentHouseholdIDs = Set(
            householdSnapshot().currentMemberships.map(\.agentID)
        )
        let householdArrivalEventCapacity = householdState == nil ? 0
            : (populationRegistry?.migrations.contains {
                ($0.status == .admitted || $0.status == .inTransit)
                    && !currentHouseholdIDs.contains($0.migrantID)
            } == true ? 2 : 0)
        let settlementPulseCapacity = settlementMetricsState?.nextPulseTick == tick ? 1 : 0
        try prevalidateCausalAppend(
            count: outcomes.count + populationArrivalEventCapacity
                + householdArrivalEventCapacity + settlementPulseCapacity
        )
        let ids = sortedIds
        guard outcomes.count == ids.count else {
            throw AgentSessionError.movementOutcomeCountMismatch(expected: ids.count, actual: outcomes.count)
        }
        var byId: [String: AgentMovementOutcome] = [:]
        for outcome in outcomes {
            guard statesById[outcome.agentId] != nil else {
                throw AgentSessionError.unknownAgentId(outcome.agentId)
            }
            guard byId[outcome.agentId] == nil else {
                throw AgentSessionError.duplicateMovementOutcome(outcome.agentId)
            }
            byId[outcome.agentId] = outcome
        }
        for id in ids where byId[id] == nil {
            throw AgentSessionError.missingMovementOutcome(id)
        }

        let initialPositions = statesById.mapValues(\.position)
        var destinationKeys = [String]()
        for id in ids {
            guard let state = statesById[id], let outcome = byId[id] else { continue }
            let verifiedKind = verifiedKinds?[id]
            guard outcome.tick == tick else { throw AgentSessionError.movementTickMismatch(id) }
            guard outcome.fromPosition == state.position else {
                throw AgentSessionError.movementFromPositionMismatch(id)
            }
            guard outcome.goalKind == state.currentGoal.kind else {
                throw AgentSessionError.movementGoalMismatch(id)
            }
            let dx = outcome.toPosition.x - outcome.fromPosition.x
            let dy = outcome.toPosition.y - outcome.fromPosition.y
            let dz = outcome.toPosition.z - outcome.fromPosition.z
            switch outcome.status {
            case .moved:
                try requireStageCapability(.autonomousMovement, for: state.agentID)
                guard dx == outcome.appliedDX, dy == outcome.appliedDY, dz == outcome.appliedDZ else {
                    throw AgentSessionError.inconsistentMovementDelta(id)
                }
                let validHorizontalDelta = verifiedKind == nil
                    ? abs(dx) + abs(dz) == 1
                    : max(abs(dx), abs(dz)) == 1
                guard validHorizontalDelta else {
                    throw AgentSessionError.invalidCardinalMovement(id)
                }
                guard (-1...1).contains(dy) else {
                    throw AgentSessionError.invalidVerticalMovement(id)
                }
                if verifiedKind == .reconciliation {
                    guard outcome.requestedDirection == nil,
                          outcome.requestedDX == 0,
                          outcome.requestedDY == 0,
                          outcome.requestedDZ == 0 else {
                        throw AgentSessionError.movementActionMismatch(id)
                    }
                } else {
                    guard let action = state.lastAction,
                          action.name == "move_abstract"
                            || action.name == "approach_resource"
                            || action.name == "return_home"
                            || action.name == "approach_construction"
                            || action.name == "approach_information"
                            || action.name == "approach_settlement"
                            || action.name == "approach_dependent",
                          outcome.requestedDX == (action.dx ?? 0),
                          outcome.requestedDY == (action.dy ?? 0),
                          outcome.requestedDZ == (action.dz ?? 0),
                          outcome.actionReason == action.reason else {
                        throw AgentSessionError.movementActionMismatch(id)
                    }
                    if verifiedKind == nil {
                        guard outcome.appliedDX == outcome.requestedDX,
                              outcome.appliedDZ == outcome.requestedDZ,
                              outcome.requestedDirection?.dx == outcome.appliedDX,
                              outcome.requestedDirection?.dz == outcome.appliedDZ else {
                            throw AgentSessionError.movementDirectionMismatch(id)
                        }
                    }
                }
                let destinationKey = positionKey(outcome.toPosition)
                guard !destinationKeys.contains(destinationKey) else {
                    throw AgentSessionError.duplicateMovementDestination
                }
                destinationKeys.append(destinationKey)
                if initialPositions.contains(where: { otherId, position in
                    otherId != id && position == outcome.toPosition
                }) {
                    throw AgentSessionError.occupiedMovementDestination(id)
                }
            case .blocked, .notRequested:
                guard outcome.toPosition == outcome.fromPosition,
                      outcome.appliedDX == 0,
                      outcome.appliedDY == 0,
                      outcome.appliedDZ == 0 else {
                    throw AgentSessionError.invalidStationaryMovement(id)
                }
            }
            let distanceBefore = manhattanDistance(outcome.fromPosition, state.homePosition)
            let distanceAfter = manhattanDistance(outcome.toPosition, state.homePosition)
            guard outcome.distanceFromHomeBefore == distanceBefore,
                  outcome.distanceFromHomeAfter == distanceAfter,
                  outcome.distanceReducedTowardHome == max(0, distanceBefore - distanceAfter) else {
                throw AgentSessionError.movementHomeMetricsMismatch(id)
            }
        }

        var updated = statesById
        for id in ids {
            guard var state = updated[id], let outcome = byId[id] else { continue }
            let verifiedKind = verifiedKinds?[id]
            state.lastMovementOutcome = outcome
            switch outcome.status {
            case .moved:
                state.position = outcome.toPosition
                if verifiedKind != .reconciliation {
                    state.movementCount += 1
                    state.totalManhattanDistanceMoved += abs(outcome.appliedDX)
                        + abs(outcome.appliedDZ)
                    if (state.currentGoal.kind == .seekSafety
                            || state.currentGoal.kind == .deliverResources
                            || (survivalEnabled && state.currentGoal.kind == .rest)),
                       outcome.distanceReducedTowardHome > 0 {
                        state.returnHomeMoveCount += 1
                        state.totalDistanceReducedTowardHome += outcome.distanceReducedTowardHome
                    }
                }
                if state.lastAction?.name == "approach_resource"
                    || state.lastAction?.name == "return_home"
                    || state.lastAction?.name == "approach_construction"
                    || state.lastAction?.name == "approach_information"
                    || state.lastAction?.name == "approach_settlement"
                    || state.lastAction?.name == "approach_dependent" {
                    guard let route = state.navigationProgress.route,
                          state.navigationProgress.status == .active else {
                        throw AgentSessionError.movementActionMismatch(id)
                    }
                    if verifiedKind == .navigationStep {
                        if outcome.toPosition == route.positions.last {
                            state.navigationProgress = AgentNavigationProgress(
                                status: .arrived,
                                route: route,
                                routeIndex: max(0, route.positions.count - 1),
                                replanCount: state.navigationProgress.replanCount,
                                consecutiveBlockedMoves: 0,
                                lastPlanTick: state.navigationProgress.lastPlanTick,
                                lastInvalidation: state.navigationProgress.lastInvalidation,
                                lastFailure: nil
                            )
                        } else {
                            // Preserve the coarse route as a waypoint/intent
                            // artifact. Advance its cursor only when the Core
                            // result happens to land on a later coarse node;
                            // otherwise the next cognition tick may replan from
                            // physical truth without stalling live movement.
                            let matchedIndex = route.positions.firstIndex(
                                of: outcome.toPosition
                            )
                            let routeIndex = matchedIndex.map {
                                max(state.navigationProgress.routeIndex, $0)
                            } ?? state.navigationProgress.routeIndex
                            state.navigationProgress = AgentNavigationProgress(
                                status: .active,
                                route: route,
                                routeIndex: routeIndex,
                                replanCount: state.navigationProgress.replanCount,
                                consecutiveBlockedMoves: 0,
                                lastPlanTick: state.navigationProgress.lastPlanTick,
                                lastInvalidation: state.navigationProgress.lastInvalidation,
                                lastFailure: nil
                            )
                        }
                    } else if verifiedKind == nil {
                        guard state.navigationProgress.nextStep == outcome.toPosition else {
                            throw AgentSessionError.movementActionMismatch(id)
                        }
                        let nextIndex = state.navigationProgress.routeIndex + 1
                        let arrived = nextIndex == route.positions.count - 1
                        state.navigationProgress = AgentNavigationProgress(
                            status: arrived ? .arrived : .active,
                            route: route,
                            routeIndex: nextIndex,
                            replanCount: state.navigationProgress.replanCount,
                            consecutiveBlockedMoves: 0,
                            lastPlanTick: state.navigationProgress.lastPlanTick,
                            lastInvalidation: state.navigationProgress.lastInvalidation,
                            lastFailure: nil
                        )
                    }
                } else if verifiedKind == .reconciliation {
                    state.navigationProgress = AgentNavigationProgress(
                        replanCount: state.navigationProgress.replanCount,
                        lastPlanTick: state.navigationProgress.lastPlanTick,
                        lastInvalidation: .targetChanged
                    )
                }
                if let entry = AgentFeedbackLoop.movementMemoryEntry(outcome: outcome) {
                    appendMemory(entry, to: &state.memory)
                    state.feedbackMemoryWriteCount += 1
                }
            case .blocked:
                if state.lastAction?.name == "approach_resource"
                    || state.lastAction?.name == "return_home"
                    || state.lastAction?.name == "approach_construction"
                    || state.lastAction?.name == "approach_information"
                    || state.lastAction?.name == "approach_settlement"
                    || state.lastAction?.name == "approach_dependent" {
                    state.navigationProgress = AgentNavigationProgress(
                        status: state.navigationProgress.status,
                        route: state.navigationProgress.route,
                        routeIndex: state.navigationProgress.routeIndex,
                        replanCount: state.navigationProgress.replanCount,
                        consecutiveBlockedMoves: state.navigationProgress.consecutiveBlockedMoves + 1,
                        lastPlanTick: state.navigationProgress.lastPlanTick,
                        lastInvalidation: state.navigationProgress.lastInvalidation,
                        lastFailure: .movementBlocked
                    )
                }
                if let entry = AgentFeedbackLoop.movementMemoryEntry(outcome: outcome) {
                    if AgentFeedbackLoop.isDuplicateBlockedMemory(
                        candidate: entry,
                        memory: state.memory,
                        currentTick: tick,
                        configuration: configuration.feedbackLoopConfiguration
                    ) {
                        state.feedbackMemoryDeduplicatedCount += 1
                    } else {
                        appendMemory(entry, to: &state.memory)
                        state.feedbackMemoryWriteCount += 1
                    }
                }
            case .notRequested:
                break
            }
            updated[id] = state
        }
        statesById = updated
        for outcome in outcomes.sorted(by: { $0.agentId < $1.agentId }) {
            let agentID = AgentID(rawValue: outcome.agentId)!
            let event = try recordCausalEvent(
                kind: .movement,
                origin: .worldOutcome,
                actorID: agentID,
                causes: lastDecisionEventByAgentID[agentID].map { [$0] } ?? [],
                payload: .movement(
                    status: outcome.status.rawValue,
                    from: outcome.fromPosition,
                    to: outcome.toPosition
                ),
                summary: "movement \(outcome.status.rawValue) actor=\(outcome.agentId)"
            )
            if let eventID = event?.eventID {
                lastOutcomeEventByAgentID[agentID] = eventID
            }
        }
        try updatePopulationAfterMovementEvents()
        _ = try applySettlementMetricsPulseIfDue()
    }

    mutating func reconcileReservations(at reservationTick: Int) {
        var candidateIdsByTarget: [String: [String]] = [:]
        for id in sortedIds {
            guard let target = statesById[id]?.activeResourceTarget else { continue }
            candidateIdsByTarget[reservationKey(
                target: target.target,
                resource: target.resource,
                source: target.source,
                expectedBlockFingerprint: target.expectedBlockFingerprint,
                ecologyPatchID: target.ecologyPatchID
            ), default: []]
                .append(id)
        }

        var updated: [String: AgentResourceReservation] = [:]
        for key in candidateIdsByTarget.keys.sorted() {
            guard let ids = candidateIdsByTarget[key]?.sorted(),
                  let firstId = ids.first,
                  let target = statesById[firstId]?.activeResourceTarget else { continue }
            let prior = reservationsByTarget[key]
            let owner = prior.flatMap { ids.contains($0.agentId) ? $0.agentId : nil } ?? firstId
            updated[key] = AgentResourceReservation(
                agentId: owner,
                target: target.target,
                resource: target.resource,
                source: target.source,
                expectedBlockFingerprint: target.expectedBlockFingerprint,
                ecologyPatchID: target.ecologyPatchID,
                acquiredAtTick: prior?.agentId == owner ? prior!.acquiredAtTick : reservationTick,
                expiresAtTick: reservationTick + configuration.reservationLifetimeTicks
            )
            for id in ids where id != owner {
                guard var state = statesById[id] else { continue }
                state.navigationProgress = AgentNavigationProgress(
                    status: .failed,
                    replanCount: state.navigationProgress.replanCount,
                    lastPlanTick: state.navigationProgress.lastPlanTick,
                    lastInvalidation: .reservationConflict,
                    lastFailure: .reservationConflict
                )
                statesById[id] = state
            }
        }
        reservationsByTarget = updated
    }

    mutating func updateNavigation(
        state: inout AgentSessionAgentState,
        observation: AgentNavigationObservation?,
        tick navigationTick: Int
    ) {
        let purpose: AgentNavigationPurpose
        let targetPosition: AgentPosition
        let targetResource: AgentResourceKind?
        let goalMode: AgentNavigationGoalMode
        switch state.currentGoal.kind {
        case .migrateToSettlement:
            guard let migration = migrationRecord(for: state.id) else {
                state.navigationProgress = AgentNavigationProgress(
                    status: .failed,
                    lastInvalidation: .targetMissing,
                    lastFailure: .targetMissing
                )
                return
            }
            releaseReservation(for: state)
            purpose = .migrationArrival
            targetPosition = migration.receptionPosition
            targetResource = nil
            goalMode = .exact
            if state.position == migration.receptionPosition {
                state.navigationProgress = AgentNavigationProgress(
                    status: .arrived,
                    route: state.navigationProgress.route,
                    routeIndex: state.navigationProgress.route.map {
                        max(0, $0.positions.count - 1)
                    } ?? 0,
                    replanCount: state.navigationProgress.replanCount,
                    consecutiveBlockedMoves: 0,
                    lastPlanTick: state.navigationProgress.lastPlanTick,
                    lastInvalidation: state.navigationProgress.lastInvalidation
                )
                return
            }
        case .collectResource, .satisfyHunger, .fulfillSharedTask:
            if state.activeResourceTarget == nil,
               state.currentGoal.kind == .collectResource
                    || state.currentGoal.kind == .fulfillSharedTask,
               let observation,
               let survey = constructionMaterialSurveyTarget(
                   for: state.id,
                   observations: state.lastResourceObservations,
                   atTick: navigationTick
               ),
               AgentConstructionMaterialSurvey.permitsNormalizedTarget(
                   observation.target,
                   desiredTarget: survey,
                   home: state.homePosition,
                   currentPosition: state.position
               ) {
                purpose = .constructionSurvey
                targetPosition = observation.target
                targetResource = nil
                goalMode = .exact
                if state.navigationProgress.route?.purpose != .constructionSurvey
                    || state.navigationProgress.route?.target != targetPosition {
                    state.navigationProgress = AgentNavigationProgress(
                        lastInvalidation: .targetChanged
                    )
                }
                if state.position == targetPosition {
                    state.navigationProgress = AgentNavigationProgress(
                        status: .arrived,
                        route: state.navigationProgress.route,
                        routeIndex: state.navigationProgress.route.map {
                            max(0, $0.positions.count - 1)
                        } ?? 0,
                        replanCount: state.navigationProgress.replanCount,
                        lastPlanTick: state.navigationProgress.lastPlanTick,
                        lastInvalidation: state.navigationProgress.lastInvalidation
                    )
                    return
                }
                break
            }
            guard let target = state.activeResourceTarget else {
                if state.navigationProgress.status != .idle || state.navigationProgress.route != nil {
                    state.navigationProgress = AgentNavigationProgress(
                        lastInvalidation: state.navigationProgress.lastInvalidation ?? .targetMissing
                    )
                }
                return
            }
            if state.currentGoal.kind == .satisfyHunger, target.resource != .foodRaw {
                releaseReservation(for: state)
                state.activeResourceTarget = nil
                state.navigationProgress = AgentNavigationProgress(
                    lastInvalidation: .targetChanged,
                    lastFailure: .targetChanged
                )
                return
            }
            purpose = .resource
            targetPosition = target.target
            targetResource = target.resource
            goalMode = .cardinalAdjacent
            if target.distanceManhattan <= 1 {
                if let route = state.navigationProgress.route {
                    state.navigationProgress = AgentNavigationProgress(
                        status: .arrived,
                        route: route,
                        routeIndex: min(state.navigationProgress.routeIndex, route.positions.count - 1),
                        replanCount: state.navigationProgress.replanCount,
                        consecutiveBlockedMoves: 0,
                        lastPlanTick: state.navigationProgress.lastPlanTick,
                        lastInvalidation: state.navigationProgress.lastInvalidation
                    )
                }
                return
            }
            guard let reservation = reservation(for: state), reservation.agentId == state.id else {
                state.navigationProgress = AgentNavigationProgress(
                    status: .failed,
                    replanCount: state.navigationProgress.replanCount,
                    lastPlanTick: state.navigationProgress.lastPlanTick,
                    lastInvalidation: .reservationLost,
                    lastFailure: .reservationLost
                )
                return
            }
        case .deliverResources:
            guard economyEnabled, !state.resourceInventory.isEmpty else {
                state.navigationProgress = AgentNavigationProgress()
                return
            }
            releaseReservation(for: state)
            purpose = .homeDelivery
            targetPosition = boundedHomeTarget(
                state: state,
                observation: observation
            )
            targetResource = nil
            goalMode = .exact
            if state.position == state.homePosition {
                state.navigationProgress = AgentNavigationProgress(
                    status: .arrived,
                    route: state.navigationProgress.route,
                    routeIndex: state.navigationProgress.route.map {
                        max(0, $0.positions.count - 1)
                    } ?? 0,
                    replanCount: state.navigationProgress.replanCount,
                    lastPlanTick: state.navigationProgress.lastPlanTick,
                    lastInvalidation: state.navigationProgress.lastInvalidation
                )
                return
            }
        case .rest:
            guard survivalEnabled else {
                releaseReservation(for: state)
                state.navigationProgress = AgentNavigationProgress()
                return
            }
            releaseReservation(for: state)
            purpose = .homeRest
            targetPosition = boundedHomeTarget(
                state: state,
                observation: observation
            )
            targetResource = nil
            goalMode = .exact
            if state.position == state.homePosition {
                state.navigationProgress = AgentNavigationProgress(
                    status: .arrived,
                    route: state.navigationProgress.route,
                    routeIndex: state.navigationProgress.route.map {
                        max(0, $0.positions.count - 1)
                    } ?? 0,
                    replanCount: state.navigationProgress.replanCount,
                    lastPlanTick: state.navigationProgress.lastPlanTick,
                    lastInvalidation: state.navigationProgress.lastInvalidation
                )
                return
            }
        case .buildShelter:
            guard buildAutoEnabled,
                  let project = constructionProject,
                  project.builderAgentId == state.id else {
                releaseReservation(for: state)
                state.navigationProgress = AgentNavigationProgress()
                return
            }
            releaseReservation(for: state)
            if project.status == .readyToFund {
                purpose = .homeDelivery
                targetPosition = boundedHomeTarget(
                    state: state,
                    observation: observation
                )
                targetResource = nil
                goalMode = .exact
            } else if (project.status == .funded || project.status == .building),
                      let workPosition = project.nextWorkPosition {
                purpose = .constructionWork
                targetPosition = workPosition
                targetResource = project.nextCell?.resource
                goalMode = .exact
            } else {
                state.navigationProgress = AgentNavigationProgress()
                return
            }
            if state.position == targetPosition {
                state.navigationProgress = AgentNavigationProgress(
                    status: .arrived,
                    route: state.navigationProgress.route,
                    routeIndex: state.navigationProgress.route.map {
                        max(0, $0.positions.count - 1)
                    } ?? 0,
                    replanCount: state.navigationProgress.replanCount,
                    lastPlanTick: state.navigationProgress.lastPlanTick,
                    lastInvalidation: state.navigationProgress.lastInvalidation
                )
                return
            }
        case .verifySocialInformation:
            guard socialEnabled,
                  let request = socialVerificationRequest(for: state.id) else {
                releaseReservation(for: state)
                state.navigationProgress = AgentNavigationProgress(
                    lastInvalidation: .targetMissing
                )
                return
            }
            releaseReservation(for: state)
            purpose = .socialVerification
            targetPosition = boundedSocialTarget(
                state: state,
                destination: request.position,
                observation: observation
            )
            targetResource = request.resource
            goalMode = targetPosition == request.position ? .cardinalAdjacent : .exact
            if manhattanDistance(state.position, request.position) <= 1 {
                state.navigationProgress = AgentNavigationProgress(
                    status: .arrived,
                    route: state.navigationProgress.route,
                    routeIndex: state.navigationProgress.route.map {
                        max(0, $0.positions.count - 1)
                    } ?? 0,
                    replanCount: state.navigationProgress.replanCount,
                    lastPlanTick: state.navigationProgress.lastPlanTick,
                    lastInvalidation: state.navigationProgress.lastInvalidation
                )
                return
            }
        case .provideDependentCare:
            guard dependentCareState != nil,
                  let dependentID = careTarget(for: state.agentID),
                  let dependent = statesById[dependentID.rawValue] else {
                releaseReservation(for: state)
                state.navigationProgress = AgentNavigationProgress(
                    lastInvalidation: .targetMissing
                )
                return
            }
            releaseReservation(for: state)
            purpose = .dependentCare
            targetPosition = boundedSocialTarget(
                state: state, destination: dependent.position, observation: observation
            )
            targetResource = nil
            goalMode = targetPosition == dependent.position ? .cardinalAdjacent : .exact
            if manhattanDistance(state.position, dependent.position)
                <= dependentCareState!.configuration.careInteractionDistance {
                state.navigationProgress = AgentNavigationProgress(
                    status: .arrived, route: state.navigationProgress.route,
                    routeIndex: state.navigationProgress.route.map {
                        max(0, $0.positions.count - 1)
                    } ?? 0,
                    replanCount: state.navigationProgress.replanCount,
                    lastPlanTick: state.navigationProgress.lastPlanTick,
                    lastInvalidation: state.navigationProgress.lastInvalidation
                )
                return
            }
        case .dependentReturnHome:
            releaseReservation(for: state)
            purpose = .dependentReturnHome
            targetPosition = boundedHomeTarget(state: state, observation: observation)
            targetResource = nil
            goalMode = .exact
            if state.position == state.homePosition {
                state.navigationProgress = AgentNavigationProgress(
                    status: .arrived, route: state.navigationProgress.route,
                    routeIndex: state.navigationProgress.route.map {
                        max(0, $0.positions.count - 1)
                    } ?? 0,
                    replanCount: state.navigationProgress.replanCount,
                    lastPlanTick: state.navigationProgress.lastPlanTick,
                    lastInvalidation: state.navigationProgress.lastInvalidation
                )
                return
            }
        default:
            releaseReservation(for: state)
            if state.navigationProgress.route != nil {
                state.navigationProgress = AgentNavigationProgress(lastInvalidation: .reservationLost)
            }
            return
        }
        guard let observation else {
            if state.navigationProgress.route != nil {
                state.navigationProgress = AgentNavigationProgress(
                    replanCount: state.navigationProgress.replanCount,
                    lastPlanTick: state.navigationProgress.lastPlanTick,
                    lastInvalidation: .perceptionMissing,
                    lastFailure: .perceptionMissing
                )
            }
            return
        }
        guard observation.target == targetPosition else {
            state.navigationProgress = AgentNavigationProgress(
                status: .failed,
                replanCount: state.navigationProgress.replanCount,
                lastPlanTick: state.navigationProgress.lastPlanTick,
                lastInvalidation: .targetChanged,
                lastFailure: .targetChanged
            )
            return
        }
        if let worldTick = state.lastWorldObservation?.worldTick,
           observation.worldTick != worldTick {
            state.navigationProgress = AgentNavigationProgress(
                status: .failed,
                replanCount: state.navigationProgress.replanCount,
                lastPlanTick: state.navigationProgress.lastPlanTick,
                lastInvalidation: .perceptionStale,
                lastFailure: .perceptionStale
            )
            return
        }

        var invalidation = state.navigationProgress.lastInvalidation
        var shouldPlan = state.navigationProgress.route == nil
        if let route = state.navigationProgress.route {
            let routeMatches = route.purpose == purpose
                && route.target == targetPosition
                && route.resource == targetResource
                && route.positions.indices.contains(state.navigationProgress.routeIndex)
                && route.positions[state.navigationProgress.routeIndex] == state.position
            if !routeMatches {
                shouldPlan = true
                invalidation = .targetChanged
            } else if state.navigationProgress.consecutiveBlockedMoves > 0 {
                shouldPlan = true
                invalidation = .movementBlocked
            } else if let next = state.navigationProgress.nextStep,
                      !observation.cells.contains(where: {
                          $0.position == next && $0.status == .traversable
                      }) {
                shouldPlan = true
                invalidation = .nextStepInvalid
            } else {
                state.navigationProgress = AgentNavigationProgress(
                    status: state.navigationProgress.status,
                    route: route,
                    routeIndex: state.navigationProgress.routeIndex,
                    replanCount: state.navigationProgress.replanCount,
                    consecutiveBlockedMoves: state.navigationProgress.consecutiveBlockedMoves,
                    lastPlanTick: state.navigationProgress.lastPlanTick,
                    lastInvalidation: state.navigationProgress.lastInvalidation,
                    lastFailure: nil
                )
                return
            }
        }
        guard shouldPlan else { return }
        if let lastPlanTick = state.navigationProgress.lastPlanTick,
           navigationTick - lastPlanTick < configuration.navigationReplanCooldownTicks {
            return
        }
        let isReplan = state.navigationProgress.lastPlanTick != nil
        let nextReplanCount = state.navigationProgress.replanCount + (isReplan ? 1 : 0)
        guard nextReplanCount <= configuration.navigationMaxReplans else {
            state.navigationProgress = AgentNavigationProgress(
                status: .failed,
                replanCount: state.navigationProgress.replanCount,
                lastPlanTick: state.navigationProgress.lastPlanTick,
                lastInvalidation: invalidation,
                lastFailure: .replanLimitReached
            )
            if purpose == .resource {
                releaseReservation(for: state)
                rememberFailedNaturalResourceTarget(for: state)
            }
            return
        }

        let plan = AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
            start: state.position,
            target: targetPosition,
            goalMode: goalMode,
            cells: observation.cells,
            radius: observation.radius,
            maxVisitedNodes: AgentBoundedRoutePlanner.maximumVisitedNodes,
            maxSteps: AgentBoundedRoutePlanner.maximumRouteSteps
        ))
        guard plan.found else {
            state.navigationProgress = AgentNavigationProgress(
                status: .failed,
                replanCount: nextReplanCount,
                lastPlanTick: navigationTick,
                lastInvalidation: invalidation,
                lastFailure: plan.failure ?? .noRoute
            )
            return
        }
        let route = AgentNavigationRoute(
            purpose: purpose,
            target: targetPosition,
            resource: targetResource,
            positions: plan.positions,
            plannedAtTick: navigationTick,
            visitedNodeCount: plan.visitedNodeCount
        )
        state.navigationProgress = AgentNavigationProgress(
            status: route.positions.count == 1 ? .arrived : .active,
            route: route,
            routeIndex: 0,
            replanCount: nextReplanCount,
            consecutiveBlockedMoves: 0,
            lastPlanTick: navigationTick,
            lastInvalidation: invalidation,
            lastFailure: nil
        )
    }

    func boundedHomeTarget(
        state: AgentSessionAgentState,
        observation: AgentNavigationObservation?
    ) -> AgentPosition {
        if state.navigationProgress.status == .active,
           let route = state.navigationProgress.route,
           route.purpose == .homeDelivery || route.purpose == .homeRest,
           observation?.target == route.target {
            return route.target
        }
        guard AgentBoundedTravel.requiresWaypoint(
            from: state.position,
            to: state.homePosition
        ), let target = observation?.target else {
            return state.homePosition
        }
        let desired = AgentBoundedTravel.desiredWaypoint(
            from: state.position,
            toward: state.homePosition
        )
        return AgentBoundedTravel.permitsNormalizedWaypoint(
            target,
            desiredWaypoint: desired,
            current: state.position,
            destination: state.homePosition
        ) ? target : state.homePosition
    }

    func boundedSocialTarget(
        state: AgentSessionAgentState,
        destination: AgentPosition,
        observation: AgentNavigationObservation?
    ) -> AgentPosition {
        if state.navigationProgress.status == .active,
           let route = state.navigationProgress.route,
           route.purpose == .socialVerification,
           observation?.target == route.target {
            return route.target
        }
        guard AgentBoundedTravel.requiresWaypoint(
            from: state.position,
            to: destination
        ), let target = observation?.target else {
            return destination
        }
        let desired = AgentBoundedTravel.desiredWaypoint(
            from: state.position,
            toward: destination
        )
        return AgentBoundedTravel.permitsNormalizedWaypoint(
            target,
            desiredWaypoint: desired,
            current: state.position,
            destination: destination
        ) ? target : destination
    }

    func reservation(for state: AgentSessionAgentState) -> AgentResourceReservation? {
        guard let target = state.activeResourceTarget else { return nil }
        return reservationsByTarget[reservationKey(
            target: target.target,
            resource: target.resource,
            source: target.source,
            expectedBlockFingerprint: target.expectedBlockFingerprint,
            ecologyPatchID: target.ecologyPatchID
        )]
            .flatMap { $0.agentId == state.id ? $0 : nil }
    }

    mutating func releaseReservation(for state: AgentSessionAgentState) {
        guard let target = state.activeResourceTarget else { return }
        let key = reservationKey(
            target: target.target,
            resource: target.resource,
            source: target.source,
            expectedBlockFingerprint: target.expectedBlockFingerprint,
            ecologyPatchID: target.ecologyPatchID
        )
        if reservationsByTarget[key]?.agentId == state.id {
            reservationsByTarget.removeValue(forKey: key)
        }
    }

    mutating func rememberFailedNaturalResourceTarget(
        for state: AgentSessionAgentState
    ) {
        guard let target = state.activeResourceTarget,
              target.source == .naturalWorld else { return }
        let key = target.identity.stableKey
        var keys = failedNaturalResourceTargetKeysByAgentId[state.id] ?? []
        guard !keys.contains(key) else { return }
        keys.append(key)
        if keys.count > Self.maximumFailedNaturalResourceTargetsPerAgent {
            keys.removeFirst(keys.count - Self.maximumFailedNaturalResourceTargetsPerAgent)
        }
        failedNaturalResourceTargetKeysByAgentId[state.id] = keys
    }

    func reservationKey(
        target: AgentPosition,
        resource: AgentResourceKind,
        source: AgentResourceObservationSource = .sandboxFixture,
        expectedBlockFingerprint: Int? = nil,
        ecologyPatchID: AgentEcologyPatchID? = nil
    ) -> String {
        AgentResourceIdentity(
            source: source,
            position: target,
            resource: resource,
            expectedBlockFingerprint: expectedBlockFingerprint,
            ecologyPatchID: ecologyPatchID
        ).stableKey
    }

    func reservationSort(
        _ lhs: AgentResourceReservation,
        _ rhs: AgentResourceReservation
    ) -> Bool {
        let lhsKey = reservationKey(
            target: lhs.target,
            resource: lhs.resource,
            source: lhs.source,
            expectedBlockFingerprint: lhs.expectedBlockFingerprint,
            ecologyPatchID: lhs.ecologyPatchID
        )
        let rhsKey = reservationKey(
            target: rhs.target,
            resource: rhs.resource,
            source: rhs.source,
            expectedBlockFingerprint: rhs.expectedBlockFingerprint,
            ecologyPatchID: rhs.ecologyPatchID
        )
        if lhsKey != rhsKey { return lhsKey < rhsKey }
        return lhs.agentId < rhs.agentId
    }

}
