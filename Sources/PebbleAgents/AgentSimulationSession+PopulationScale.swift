import Foundation

extension AgentSimulationSession {
    public var populationScalingEnabled: Bool {
        populationRegistry?.scaleState != nil
    }

    public func populationScaleSnapshot() -> AgentPopulationScaleSnapshot {
        guard let registry = populationRegistry,
              let scale = registry.scaleState else {
            return AgentPopulationScaleSnapshot(
                enabled: false,
                settlements: populationRegistry?.settlements ?? [],
                fidelityRecords: [], fidelityTransitions: [],
                settlementMigrations: [],
                workCounters: AgentFidelityWorkCounters(),
                evictedFidelityTransitionCount: 0,
                evictedSettlementMigrationCount: 0,
                digest: AgentPopulationDigest.make("scale-disabled")
            )
        }
        let settlements = registry.settlements
        let fidelity = scale.fidelityRecords.sorted { $0.agentID < $1.agentID }
        let transitions = scale.fidelityTransitions.sorted { $0.ordinal < $1.ordinal }
        let migrations = scale.settlementMigrations.sorted {
            $0.migrationID < $1.migrationID
        }
        let settlementText = settlements.map { settlement in
            let positions = [
                scalePositionText(settlement.anchor),
                scalePositionText(settlement.receptionPosition),
            ].joined(separator: "|")
            let residents = settlement.residentIDs.map(\.rawValue)
                .joined(separator: ",")
            let transit = settlement.inTransitIDs.map(\.rawValue)
                .joined(separator: ",")
            return [
                "s", settlement.settlementID.rawValue, positions,
                String(settlement.capacity), residents, transit,
            ].joined(separator: "|")
        }.joined(separator: ";")
        let fidelityText = fidelity.map { record in
            [
                "f", record.agentID.rawValue, record.fidelity.rawValue,
                String(record.enteredTick), String(record.transitionCount),
                record.lastTransitionEventID.rawValue,
            ].joined(separator: "|")
        }.joined(separator: ";")
        let transitionText = transitions.map { transition in
            [
                "t", String(transition.ordinal), transition.agentID.rawValue,
                transition.from?.rawValue ?? "none", transition.to.rawValue,
                String(transition.tick), transition.cause.rawValue,
                transition.eventID.rawValue,
            ].joined(separator: "|")
        }.joined(separator: ";")
        let migrationText = migrations.map { migration in
            let route = migration.route.map(scalePositionText)
                .joined(separator: ">")
            return [
                "m", migration.migrationID.rawValue,
                migration.agentID.rawValue,
                migration.originSettlementID.rawValue,
                migration.destinationSettlementID.rawValue,
                migration.status.rawValue, String(migration.routeCursor), route,
            ].joined(separator: "|")
        }.joined(separator: ";")
        let canonical = [
            settlementText, fidelityText, transitionText, migrationText,
            "rotation=\(scale.rotationOffset)",
            "work=\(scale.workCounters.liveCognitionExecutions),"
                + "\(scale.workCounters.nearMaintenanceExecutions),"
                + "\(scale.workCounters.dormantMaintenanceExecutions),"
                + "\(scale.workCounters.skippedFullCognitionExecutions)",
            "evicted=\(scale.evictedFidelityTransitionCount),"
                + "\(scale.evictedSettlementMigrationCount)",
        ].joined(separator: "|")
        return AgentPopulationScaleSnapshot(
            enabled: true, settlements: settlements,
            fidelityRecords: fidelity, fidelityTransitions: transitions,
            settlementMigrations: migrations, workCounters: scale.workCounters,
            evictedFidelityTransitionCount: scale.evictedFidelityTransitionCount,
            evictedSettlementMigrationCount: scale.evictedSettlementMigrationCount,
            digest: AgentPopulationDigest.make(canonical)
        )
    }

    public func fidelity(for agentID: AgentID) -> AgentSimulationFidelity {
        populationRegistry?.scaleState?.fidelityRecords.first {
            $0.agentID == agentID
        }?.fidelity ?? .live
    }

    public func fullFidelityAgentIDs() -> [AgentID] {
        guard let records = populationRegistry?.scaleState?.fidelityRecords else {
            return statesById.values.map(\.agentID).sorted()
        }
        return records.filter { $0.fidelity == .live }.map(\.agentID).sorted()
    }

    public func currentSettlementID(for agentID: AgentID) -> AgentSettlementID? {
        populationRegistry?.members.first { $0.agentID == agentID }?.settlementID
    }

    func activeSettlementMigration(
        for agentID: String
    ) -> AgentSettlementMigrationRecord? {
        populationRegistry?.scaleState?.settlementMigrations.first {
            $0.agentID.rawValue == agentID && $0.status == .inTransit
        }
    }

    /// Starts CIV-39 from the existing population owner. New inhabitants are
    /// full AgentSessionAgentState records owned by this same session. This V1
    /// deliberately refuses to splice new people into already-active
    /// lifecycle/social domain authorities; callers enable those domains after
    /// population construction or use the no-addition continuity path.
    public mutating func initializePopulationScaling(
        additionalSettlements: [AgentPopulationSettlement],
        additionalResidents: [AgentScaledResidentAdmission] = [],
        configuration: AgentPopulationScaleConfiguration = .live
    ) throws {
        var candidate = self
        try candidate.initializePopulationScalingInPlace(
            additionalSettlements: additionalSettlements,
            additionalResidents: additionalResidents,
            configuration: configuration
        )
        self = candidate
    }

    private mutating func initializePopulationScalingInPlace(
        additionalSettlements: [AgentPopulationSettlement],
        additionalResidents: [AgentScaledResidentAdmission],
        configuration: AgentPopulationScaleConfiguration
    ) throws {
        guard var registry = populationRegistry else {
            throw AgentSessionError.population(.disabled)
        }
        guard registry.scaleState == nil else {
            throw AgentSessionError.population(.alreadyEnabled)
        }
        guard additionalResidents.isEmpty || (
            mortalityState == nil && lifecycleState == nil && kinshipState == nil
                && householdState == nil && dependentCareState == nil
                && homeostasisState == nil && geneticsState == nil
                && familyState == nil && estateState == nil
        ) else {
            throw AgentSessionError.population(
                .invalidConfiguration("scaled residents require inactive lifecycle authorities")
            )
        }
        let sortedSettlements = additionalSettlements.sorted {
            $0.settlementID < $1.settlementID
        }
        guard !sortedSettlements.isEmpty,
              sortedSettlements.count + 1 <= configuration.maximumSettlements,
              Set(sortedSettlements.map(\.settlementID)).count
                == sortedSettlements.count,
              sortedSettlements.allSatisfy({
                  $0.settlementID != registry.settlement.settlementID
                      && $0.capacity > 0 && $0.residentIDs.isEmpty
                      && $0.inTransitIDs.isEmpty
              }) else {
            throw AgentSessionError.population(
                .invalidConfiguration("additional settlements")
            )
        }
        let additions = additionalResidents.sorted {
            $0.state.agentID < $1.state.agentID
        }
        guard Set(additions.map { $0.state.agentID }).count == additions.count,
              additions.allSatisfy({ statesById[$0.state.id] == nil }),
              additions.allSatisfy({ admission in
                  sortedSettlements.contains {
                      $0.settlementID == admission.settlementID
                  } || registry.settlement.settlementID == admission.settlementID
              }),
              registry.members.count + additions.count
                <= registry.configuration.maximumActivePopulation else {
            throw AgentSessionError.population(.capacityReached)
        }
        var capacityCandidate = registry
        capacityCandidate.additionalSettlements = sortedSettlements
        guard capacityCandidate.hasCommittedResidentCapacity(
            forProposedAdmissions: additions.map(\.settlementID)
        ) else {
            throw AgentSessionError.population(.capacityReached)
        }
        try prevalidateCausalAppend(
            count: 1 + sortedSettlements.count + additions.count
                + registry.members.count + additions.count
        )
        let initialized = try requiredPopulationEvent(
            kind: .populationScalingInitialized,
            causes: [registry.lastPopulationEventID],
            payload: .operation(
                status: "initialized",
                detail: "settlements=\(sortedSettlements.count + 1) population="
                    + "\(registry.members.count + additions.count)"
            ),
            summary: "population scaling initialized"
        )
        var lastEventID = initialized.eventID
        for settlement in sortedSettlements {
            let event = try requiredPopulationEvent(
                kind: .settlementRegistered,
                causes: [lastEventID],
                payload: .operation(
                    status: "registered",
                    detail: "settlement=\(settlement.settlementID.rawValue) "
                        + "anchor=\(scalePositionText(settlement.anchor))"
                ),
                summary: "settlement registered id=\(settlement.settlementID.rawValue)"
            )
            lastEventID = event.eventID
        }
        registry.additionalSettlements = sortedSettlements
        for admission in additions {
            let ordinal = registry.nextPopulationOrdinal
            guard ordinal.rawValue < Int.max,
                  let next = AgentPopulationOrdinal(rawValue: ordinal.rawValue + 1) else {
                throw AgentSessionError.population(.ordinalOverflow)
            }
            let event = try requiredPopulationEvent(
                kind: .populationMemberRegistered,
                actorID: admission.state.agentID,
                subjectID: admission.state.agentID,
                causes: [lastEventID],
                payload: .population(
                    settlementID: admission.settlementID.rawValue,
                    memberID: admission.state.id,
                    ordinal: ordinal.rawValue,
                    founder: false,
                    status: AgentPopulationMembershipStatus.resident.rawValue,
                    populationBefore: registry.members.count,
                    populationAfter: registry.members.count + 1
                ),
                summary: "scaled resident registered id=\(admission.state.id)"
            )
            statesById[admission.state.id] = admission.state
            registry.members.append(AgentPopulationMemberRecord(
                agentID: admission.state.agentID, ordinal: ordinal,
                settlementID: admission.settlementID, status: .resident,
                founder: false, registeredTick: tick, arrivalTick: tick,
                migrationID: nil, entryPosition: nil,
                receptionPosition: registry.settlement(
                    withID: admission.settlementID
                )!.receptionPosition,
                registrationEventID: event.eventID,
                arrivalEventID: event.eventID
            ))
            guard registry.updateSettlement(withID: admission.settlementID, {
                $0.residentIDs.append(admission.state.agentID)
                $0.residentIDs.sort()
            }) else {
                throw AgentSessionError.population(.admission(.settlementMissing))
            }
            registry.nextPopulationOrdinal = next
            lastEventID = event.eventID
        }
        registry.members.sort { $0.agentID < $1.agentID }
        let orderedMembers = registry.members.sorted { $0.ordinal < $1.ordinal }
        var records: [AgentFidelityRecord] = []
        var transitions: [AgentFidelityTransitionRecord] = []
        var nextTransition: UInt64 = 1
        for (index, member) in orderedMembers.enumerated() {
            let tier: AgentSimulationFidelity
            if index < configuration.maximumLiveAgents {
                tier = .live
            } else if index < configuration.maximumLiveAgents
                + configuration.maximumNearAgents {
                tier = .near
            } else {
                tier = .dormant
            }
            let event = try requiredPopulationEvent(
                kind: .fidelityTransitioned,
                actorID: member.agentID, subjectID: member.agentID,
                causes: [lastEventID],
                payload: .operation(
                    status: tier.rawValue,
                    detail: "agent=\(member.agentID.rawValue) from=none "
                        + "cause=\(AgentFidelityTransitionCause.initialPolicy.rawValue)"
                ),
                summary: "fidelity initialized agent=\(member.agentID.rawValue) "
                    + "tier=\(tier.rawValue)"
            )
            records.append(AgentFidelityRecord(
                agentID: member.agentID, fidelity: tier, enteredTick: tick,
                transitionCount: 1, lastTransitionEventID: event.eventID
            ))
            transitions.append(AgentFidelityTransitionRecord(
                ordinal: nextTransition, agentID: member.agentID,
                from: nil, to: tier, tick: tick, cause: .initialPolicy,
                eventID: event.eventID
            ))
            nextTransition += 1
            lastEventID = event.eventID
        }
        let initialTransitionExcess = max(
            0, transitions.count
                - configuration.maximumFidelityTransitionHistory
        )
        if initialTransitionExcess > 0 {
            transitions.removeFirst(initialTransitionExcess)
        }
        registry.scaleState = AgentPopulationScaleState(
            configuration: configuration,
            fidelityRecords: records.sorted { $0.agentID < $1.agentID },
            fidelityTransitions: transitions,
            settlementMigrations: [], rotationOffset: 0,
            nextFidelityTransitionOrdinal: nextTransition,
            nextSettlementMigrationOrdinal: 1,
            evictedFidelityTransitionCount: UInt64(initialTransitionExcess),
            evictedSettlementMigrationCount: 0,
            workCounters: AgentFidelityWorkCounters(),
            initializedEventID: initialized.eventID,
            lastScaleEventID: lastEventID
        )
        registry.lastPopulationEventID = lastEventID
        populationRegistry = registry
    }

    @discardableResult
    public mutating func beginSettlementMigration(
        agentID: AgentID,
        destinationSettlementID: AgentSettlementID,
        verifiedRoute: [AgentPosition]
    ) throws -> AgentSettlementMigrationRecord {
        var candidate = self
        let migration = try candidate.beginSettlementMigrationInPlace(
            agentID: agentID, destinationSettlementID: destinationSettlementID,
            verifiedRoute: verifiedRoute
        )
        self = candidate
        return migration
    }

    private mutating func beginSettlementMigrationInPlace(
        agentID: AgentID,
        destinationSettlementID: AgentSettlementID,
        verifiedRoute: [AgentPosition]
    ) throws -> AgentSettlementMigrationRecord {
        guard var registry = populationRegistry,
              var scale = registry.scaleState,
              let memberIndex = registry.members.firstIndex(where: {
                  $0.agentID == agentID
              }), let state = statesById[agentID.rawValue],
              let origin = registry.settlement(
                  withID: registry.members[memberIndex].settlementID
              ), let destination = registry.settlement(
                  withID: destinationSettlementID
              ) else {
            throw AgentSessionError.population(.disabled)
        }
        guard fidelity(for: agentID) == .live,
              origin.settlementID != destination.settlementID,
              scale.settlementMigrations.filter({ !$0.status.isTerminal }).count
                < scale.configuration.maximumConcurrentSettlementMigrations,
              registry.members[memberIndex].status != .migrating,
              origin.residentIDs.contains(agentID),
              !origin.inTransitIDs.contains(agentID) else {
            throw AgentSessionError.population(
                .admission(.migrationAlreadyActive)
            )
        }
        // The active migration record is the durable destination-slot claim.
        // Establish it before any causal, membership, fidelity or ordinal
        // publication. Restore derives the same accounting from schema 35.
        guard registry.hasCommittedResidentCapacity(
            forProposedAdmissions: [destinationSettlementID]
        ) else {
            throw AgentSessionError.population(.capacityReached)
        }
        guard verifiedRoute.count >= 2,
              verifiedRoute.count - 1
                <= scale.configuration.maximumSettlementMigrationRouteLength,
              verifiedRoute.first == state.position,
              verifiedRoute.last == destination.receptionPosition,
              Set(verifiedRoute).count == verifiedRoute.count,
              zip(verifiedRoute, verifiedRoute.dropFirst()).allSatisfy({ pair in
                  let (lhs, rhs) = pair
                  return abs(lhs.x - rhs.x) + abs(lhs.z - rhs.z) == 1
                      && (-1...1).contains(rhs.y - lhs.y)
              }) else {
            throw AgentSessionError.population(.admission(.routeUnavailable))
        }
        let ordinal = scale.nextSettlementMigrationOrdinal
        guard ordinal < UInt64.max,
              let migrationID = AgentSettlementMigrationID(
                  rawValue: "settlement-migration-"
                    + String(format: "%08llu", ordinal)
              ) else {
            throw AgentSessionError.population(.ordinalOverflow)
        }
        let event = try requiredPopulationEvent(
            kind: .settlementMigrationStarted,
            actorID: agentID, subjectID: agentID,
            causes: [scale.lastScaleEventID],
            payload: .operation(
                status: AgentSettlementMigrationStatus.inTransit.rawValue,
                detail: "migration=\(migrationID.rawValue) "
                    + "origin=\(origin.settlementID.rawValue) "
                    + "destination=\(destination.settlementID.rawValue) "
                    + "route=\(verifiedRoute.count)"
            ),
            summary: "settlement migration started id=\(migrationID.rawValue)"
        )
        let route = AgentNavigationRoute(
            purpose: .migrationArrival,
            target: destination.receptionPosition,
            positions: verifiedRoute,
            plannedAtTick: tick,
            visitedNodeCount: verifiedRoute.count
        )
        var updatedState = state
        updatedState.state = "migrating"
        updatedState.currentGoal = AgentGoal(
            kind: .migrateToSettlement,
            reason: "verified embodied travel between settlements",
            startedAtTick: tick, urgency: 90
        )
        updatedState.navigationProgress = AgentNavigationProgress(
            status: .active, route: route, routeIndex: 0,
            replanCount: 0, consecutiveBlockedMoves: 0, lastPlanTick: tick
        )
        statesById[agentID.rawValue] = updatedState
        registry.members[memberIndex].status = .migrating
        _ = registry.updateSettlement(withID: origin.settlementID) {
            $0.residentIDs.removeAll { $0 == agentID }
            if !$0.inTransitIDs.contains(agentID) {
                $0.inTransitIDs.append(agentID)
                $0.inTransitIDs.sort()
            }
        }
        let migration = AgentSettlementMigrationRecord(
            migrationID: migrationID, agentID: agentID,
            originSettlementID: origin.settlementID,
            destinationSettlementID: destination.settlementID,
            route: verifiedRoute, routeCursor: 0,
            startedTick: tick, arrivedTick: nil, status: .inTransit,
            startedEventID: event.eventID, arrivedEventID: nil,
            lastMovementEventID: nil
        )
        scale.settlementMigrations.append(migration)
        scale.settlementMigrations.sort { $0.migrationID < $1.migrationID }
        // Make room by evicting terminal history only. The just-created
        // in-flight record is current destination-capacity authority and is
        // therefore never a compaction victim, including at history bound.
        compactScaleHistories(&scale)
        scale.nextSettlementMigrationOrdinal = ordinal + 1
        scale.lastScaleEventID = event.eventID
        registry.scaleState = scale
        registry.lastPopulationEventID = event.eventID
        populationRegistry = registry
        return migration
    }

    mutating func updateSettlementMigrationsAfterMovementEvents() throws {
        guard var registry = populationRegistry,
              var scale = registry.scaleState else { return }
        let activeIndices = scale.settlementMigrations.indices.filter {
            scale.settlementMigrations[$0].status == .inTransit
        }.sorted {
            scale.settlementMigrations[$0].migrationID
                < scale.settlementMigrations[$1].migrationID
        }
        for index in activeIndices {
            let migration = scale.settlementMigrations[index]
            guard var state = statesById[migration.agentID.rawValue] else {
                throw AgentSessionError.population(
                    .invalidMigration(migration.migrationID.rawValue)
                )
            }
            // The durable route is a bounded, caller-verified intent. Pebble
            // may replan the detailed physical route from newer World truth,
            // so its local cursor is diagnostic rather than arrival authority.
            scale.settlementMigrations[index].routeCursor = min(
                max(0, migration.route.count - 1),
                max(
                    scale.settlementMigrations[index].routeCursor,
                    state.navigationProgress.routeIndex
                )
            )
            scale.settlementMigrations[index].lastMovementEventID =
                lastOutcomeEventByAgentID[migration.agentID]
            guard state.position == migration.route.last,
                  state.navigationProgress.status == .arrived,
                  state.navigationProgress.route?.purpose == .migrationArrival,
                  state.navigationProgress.route?.target == migration.route.last
            else { continue }
            guard let memberIndex = registry.members.firstIndex(where: {
                      $0.agentID == migration.agentID
                  }), registry.members[memberIndex].status == .migrating,
                  registry.members[memberIndex].settlementID
                    == migration.originSettlementID,
                  registry.settlement(withID: migration.originSettlementID)?
                    .inTransitIDs.contains(migration.agentID) == true else {
                throw AgentSessionError.population(
                    .invalidMigration(migration.migrationID.rawValue)
                )
            }
            // The in-flight record already owns exactly one destination claim.
            // Revalidate that complete committed occupancy before publishing
            // arrival. The public movement operation is a session candidate;
            // Pebble's verified movement transaction compensates physical
            // movement if this late fail-closed guard ever rejects.
            guard registry.hasCommittedResidentCapacity(),
                  !destinationResidentIDs(
                      in: registry, for: migration.destinationSettlementID
                  ).contains(migration.agentID) else {
                throw AgentSessionError.population(.capacityReached)
            }
            let event = try requiredPopulationEvent(
                kind: .settlementMigrationArrived,
                actorID: migration.agentID, subjectID: migration.agentID,
                causes: [migration.startedEventID,
                    scale.settlementMigrations[index].lastMovementEventID]
                    .compactMap { $0 }.sorted(),
                payload: .operation(
                    status: AgentSettlementMigrationStatus.arrived.rawValue,
                    detail: "migration=\(migration.migrationID.rawValue) "
                        + "origin=\(migration.originSettlementID.rawValue) "
                        + "destination=\(migration.destinationSettlementID.rawValue)"
                ),
                summary: "settlement migration arrived id="
                    + migration.migrationID.rawValue
            )
            scale.settlementMigrations[index].status = .arrived
            scale.settlementMigrations[index].routeCursor =
                max(0, migration.route.count - 1)
            scale.settlementMigrations[index].arrivedTick = tick
            scale.settlementMigrations[index].arrivedEventID = event.eventID
            registry.members[memberIndex].settlementID =
                migration.destinationSettlementID
            registry.members[memberIndex].status = .resident
            if let lifecycleIndex = lifecycleState?.members.firstIndex(where: {
                $0.agentID == migration.agentID
            }) {
                lifecycleState?.members[lifecycleIndex].settlementID =
                    migration.destinationSettlementID
                lifecycleState?.members[lifecycleIndex].lastLifecycleEventID =
                    event.eventID
                lifecycleState?.lastLifecycleEventID = event.eventID
            }
            _ = registry.updateSettlement(withID: migration.originSettlementID) {
                $0.inTransitIDs.removeAll { $0 == migration.agentID }
            }
            guard registry.updateSettlement(
                withID: migration.destinationSettlementID,
                { settlement in
                    if !settlement.residentIDs.contains(migration.agentID) {
                        settlement.residentIDs.append(migration.agentID)
                        settlement.residentIDs.sort()
                    }
                }
            ) else {
                throw AgentSessionError.population(.admission(.settlementMissing))
            }
            state.state = "idle"
            state.homePosition = migration.route.last!
            state.currentGoal = AgentGoal(
                kind: .idle, reason: "settlement migration physically arrived",
                startedAtTick: tick, urgency: 0
            )
            state.navigationProgress = AgentNavigationProgress()
            statesById[migration.agentID.rawValue] = state
            scale.lastScaleEventID = event.eventID
            registry.lastPopulationEventID = event.eventID
        }
        compactScaleHistories(&scale)
        registry.scaleState = scale
        populationRegistry = registry
    }

    private func destinationResidentIDs(
        in registry: AgentPopulationRegistry,
        for settlementID: AgentSettlementID
    ) -> [AgentID] {
        registry.settlement(withID: settlementID)?.residentIDs ?? []
    }

    func fidelityExecutionCounts(at simulationTick: Int) -> (
        live: [AgentID], nearMaintenance: Int, dormantMaintenance: Int
    ) {
        guard let scale = populationRegistry?.scaleState else {
            return (statesById.values.map(\.agentID).sorted(), 0, 0)
        }
        let live = scale.fidelityRecords.filter {
            $0.fidelity == .live
        }.map(\.agentID).sorted()
        let near = simulationTick % scale.configuration.nearMaintenanceCadence == 0
            ? scale.fidelityRecords.filter { $0.fidelity == .near }.count : 0
        let dormant = simulationTick
                % scale.configuration.dormantMaintenanceCadence == 0
            ? scale.fidelityRecords.filter { $0.fidelity == .dormant }.count : 0
        return (live, near, dormant)
    }

    mutating func recordFidelityWork(
        liveCount: Int,
        nearMaintenanceCount: Int,
        dormantMaintenanceCount: Int
    ) {
        guard var registry = populationRegistry,
              var scale = registry.scaleState else { return }
        let population = scale.fidelityRecords.count
        scale.workCounters.liveCognitionExecutions += UInt64(liveCount)
        scale.workCounters.nearMaintenanceExecutions += UInt64(
            nearMaintenanceCount
        )
        scale.workCounters.dormantMaintenanceExecutions += UInt64(
            dormantMaintenanceCount
        )
        scale.workCounters.skippedFullCognitionExecutions += UInt64(
            max(0, population - liveCount)
        )
        registry.scaleState = scale
        populationRegistry = registry
    }

    mutating func rotateFidelityIfDue(at simulationTick: Int) throws {
        guard var registry = populationRegistry,
              var scale = registry.scaleState,
              simulationTick % scale.configuration.rotationIntervalTicks == 0,
              scale.fidelityRecords.count > scale.configuration.maximumLiveAgents
        else { return }
        let ordered = registry.members.sorted { $0.ordinal < $1.ordinal }
        guard !ordered.isEmpty else { return }
        scale.rotationOffset = (scale.rotationOffset
            + scale.configuration.maximumLiveAgents) % ordered.count
        let activeMigrantIDs = Set(scale.settlementMigrations.filter {
            $0.status == .inTransit
        }.map(\.agentID))
        var desired: [AgentID: AgentSimulationFidelity] = [:]
        let pinned = activeMigrantIDs.sorted()
        for id in pinned.prefix(scale.configuration.maximumLiveAgents) {
            desired[id] = .live
        }
        let ring = (0..<ordered.count).map {
            ordered[(scale.rotationOffset + $0) % ordered.count].agentID
        }.filter { desired[$0] == nil }
        let liveRemaining = max(
            0, scale.configuration.maximumLiveAgents - desired.count
        )
        for id in ring.prefix(liveRemaining) { desired[id] = .live }
        for id in ring.dropFirst(liveRemaining).prefix(
            scale.configuration.maximumNearAgents
        ) { desired[id] = .near }
        for id in ring where desired[id] == nil { desired[id] = .dormant }
        let cause: AgentFidelityTransitionCause = activeMigrantIDs.isEmpty
            ? .scheduledRotation : .activeMigration
        let changed = scale.fidelityRecords.indices.filter {
            desired[scale.fidelityRecords[$0].agentID]
                != scale.fidelityRecords[$0].fidelity
        }.sorted {
            scale.fidelityRecords[$0].agentID
                < scale.fidelityRecords[$1].agentID
        }
        try prevalidateCausalAppend(count: changed.count)
        for index in changed {
            guard scale.nextFidelityTransitionOrdinal < UInt64.max else {
                throw AgentSessionError.population(.ordinalOverflow)
            }
            let agentID = scale.fidelityRecords[index].agentID
            let from = scale.fidelityRecords[index].fidelity
            let to = desired[agentID]!
            let event = try requiredPopulationEvent(
                kind: .fidelityTransitioned,
                actorID: agentID, subjectID: agentID,
                causes: [scale.lastScaleEventID],
                payload: .operation(
                    status: to.rawValue,
                    detail: "agent=\(agentID.rawValue) from=\(from.rawValue) "
                        + "cause=\(cause.rawValue)"
                ),
                summary: "fidelity transitioned agent=\(agentID.rawValue) "
                    + "\(from.rawValue)>\(to.rawValue)"
            )
            scale.fidelityRecords[index].fidelity = to
            scale.fidelityRecords[index].enteredTick = simulationTick
            scale.fidelityRecords[index].transitionCount += 1
            scale.fidelityRecords[index].lastTransitionEventID = event.eventID
            if to != .live,
               var state = statesById[agentID.rawValue] {
                // A lower tier cannot replay a stale exact physical intent.
                // The causal action event remains in the ledger; only the
                // ephemeral executor handoff is cleared.
                state.lastAction = nil
                state.lastActionEffect = nil
                statesById[agentID.rawValue] = state
            }
            scale.fidelityTransitions.append(AgentFidelityTransitionRecord(
                ordinal: scale.nextFidelityTransitionOrdinal,
                agentID: agentID, from: from, to: to, tick: simulationTick,
                cause: cause, eventID: event.eventID
            ))
            scale.nextFidelityTransitionOrdinal += 1
            scale.lastScaleEventID = event.eventID
            registry.lastPopulationEventID = event.eventID
        }
        compactScaleHistories(&scale)
        registry.scaleState = scale
        populationRegistry = registry
    }

    private func compactScaleHistories(_ scale: inout AgentPopulationScaleState) {
        let transitionExcess = max(
            0, scale.fidelityTransitions.count
                - scale.configuration.maximumFidelityTransitionHistory
        )
        if transitionExcess > 0 {
            scale.fidelityTransitions.removeFirst(transitionExcess)
            scale.evictedFidelityTransitionCount += UInt64(transitionExcess)
        }
        let terminalIndices = scale.settlementMigrations.indices.filter {
            scale.settlementMigrations[$0].status.isTerminal
        }
        let migrationExcess = max(
            0, scale.settlementMigrations.count
                - scale.configuration.maximumSettlementMigrationHistory
        )
        if migrationExcess > 0 {
            let removable = terminalIndices.prefix(migrationExcess)
            for index in removable.reversed() {
                scale.settlementMigrations.remove(at: index)
                scale.evictedSettlementMigrationCount += 1
            }
        }
    }

    static func validatePopulationScaleState(
        _ scale: AgentPopulationScaleState,
        registry: AgentPopulationRegistry,
        clock: AgentSimulationClock,
        departedAgentIDs: Set<AgentID> = []
    ) throws {
        let agentIDs = Set(registry.members.map(\.agentID))
        let recordIDs = scale.fidelityRecords.map(\.agentID)
        let settlements = registry.settlements
        let transitionOrdinals = scale.fidelityTransitions.map(\.ordinal)
        let migrationIDs = scale.settlementMigrations.map(\.migrationID)
        guard settlements.count >= 2,
              settlements.count <= scale.configuration.maximumSettlements,
              Set(settlements.map(\.settlementID)).count == settlements.count,
              Set(recordIDs) == agentIDs, Set(recordIDs).count == recordIDs.count,
              scale.fidelityRecords.filter({ $0.fidelity == .live }).count
                <= scale.configuration.maximumLiveAgents,
              scale.fidelityRecords.filter({ $0.fidelity == .near }).count
                <= scale.configuration.maximumNearAgents,
              scale.fidelityTransitions.count
                <= scale.configuration.maximumFidelityTransitionHistory,
              scale.settlementMigrations.count
                <= scale.configuration.maximumSettlementMigrationHistory,
              scale.settlementMigrations.filter({ !$0.status.isTerminal }).count
                <= scale.configuration.maximumConcurrentSettlementMigrations,
              scale.rotationOffset >= 0,
              scale.nextFidelityTransitionOrdinal > 0,
              scale.nextSettlementMigrationOrdinal > 0,
              Set(transitionOrdinals).count == transitionOrdinals.count,
              transitionOrdinals == transitionOrdinals.sorted(),
              transitionOrdinals.allSatisfy({
                  $0 < scale.nextFidelityTransitionOrdinal
              }),
              Set(migrationIDs).count == migrationIDs.count else {
            throw AgentCheckpointError.invalidBound("population scale")
        }
        guard registry.hasCommittedResidentCapacity() else {
            throw AgentCheckpointError.invalidBound("population settlement")
        }
        for record in scale.fidelityRecords {
            guard record.enteredTick <= clock.tick.rawValue,
                  record.transitionCount > 0,
                  record.lastTransitionEventID.simulationID
                    == clock.simulationID else {
                throw AgentCheckpointError.invalidReference(
                    record.agentID.rawValue
                )
            }
        }
        for migration in scale.settlementMigrations {
            let referencesActive = agentIDs.contains(migration.agentID)
            let referencesDeparted = departedAgentIDs.contains(
                migration.agentID
            ) && migration.status.isTerminal
            let member = registry.members.first {
                $0.agentID == migration.agentID
            }
            let origin = registry.settlement(
                withID: migration.originSettlementID
            )
            let destination = registry.settlement(
                withID: migration.destinationSettlementID
            )
            guard (referencesActive || referencesDeparted),
                  (referencesActive ? member != nil : member == nil),
                  origin != nil, destination != nil,
                  migration.originSettlementID
                    != migration.destinationSettlementID,
                  migration.route.count >= 2,
                  migration.route.count - 1
                    <= scale.configuration.maximumSettlementMigrationRouteLength,
                  migration.route.indices.contains(migration.routeCursor),
                  migration.route.first != nil,
                  migration.route.last == destination?.receptionPosition,
                  Set(migration.route).count == migration.route.count,
                  zip(migration.route, migration.route.dropFirst())
                    .allSatisfy({ pair in
                        let (lhs, rhs) = pair
                        return abs(lhs.x - rhs.x) + abs(lhs.z - rhs.z) == 1
                            && (-1...1).contains(rhs.y - lhs.y)
                    }),
                  migration.startedTick <= clock.tick.rawValue,
                  migration.arrivedTick.map({ $0 <= clock.tick.rawValue }) ?? true,
                  migration.failedTick.map({ $0 <= clock.tick.rawValue }) ?? true,
                  migration.startedEventID.simulationID == clock.simulationID,
                  migration.arrivedEventID?.simulationID == clock.simulationID
                    || migration.arrivedEventID == nil,
                  migration.failureEventID?.simulationID == clock.simulationID
                    || migration.failureEventID == nil,
                  migration.status == .inTransit
                    ? (referencesActive
                        && member?.status == .migrating
                        && member?.settlementID
                            == migration.originSettlementID
                        && origin?.inTransitIDs.contains(migration.agentID)
                            == true
                        && migration.arrivedTick == nil
                        && migration.arrivedEventID == nil
                        && migration.failure == nil
                        && migration.failedTick == nil
                        && migration.failureEventID == nil)
                    : true,
                  migration.status == .arrived
                    ? ((referencesDeparted
                            || (member?.status != .migrating
                                && member?.settlementID
                                    == migration.destinationSettlementID
                                && destination?.residentIDs.contains(
                                    migration.agentID
                                ) == true))
                        && migration.arrivedTick != nil
                        && migration.arrivedEventID != nil
                        && migration.failure == nil
                        && migration.failedTick == nil
                        && migration.failureEventID == nil)
                    : true,
                  migration.status == .failed
                    ? (referencesDeparted
                        && migration.failure == .memberDied
                        && migration.failedTick != nil
                        && migration.failureEventID != nil
                        && migration.arrivedTick == nil
                        && migration.arrivedEventID == nil)
                    : true else {
                throw AgentCheckpointError.invalidReference(
                    migration.migrationID.rawValue
                )
            }
        }
    }

    private func scalePositionText(_ position: AgentPosition) -> String {
        "\(position.x),\(position.y),\(position.z)"
    }
}
