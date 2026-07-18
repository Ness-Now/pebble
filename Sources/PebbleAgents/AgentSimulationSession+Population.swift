import Foundation

extension AgentSimulationSession {
    public var populationEnabled: Bool { populationRegistry != nil }

    public func populationSnapshot() -> AgentPopulationSnapshot {
        guard let registry = populationRegistry else {
            return AgentPopulationSnapshot(
                enabled: false,
                settlement: nil,
                members: [],
                migrations: [],
                nextPopulationOrdinal: nil,
                evictionCounts: AgentPopulationEvictionCounts(),
                populationCausalEventCount: 0,
                digest: AgentPopulationDigest.make("disabled")
            )
        }
        let members = registry.members.sorted { $0.agentID < $1.agentID }
        let migrations = registry.migrations.sorted { $0.migrationID < $1.migrationID }
        let eventCount = causalLedger.events.filter { $0.kind.isPopulation }.count
        let canonical = [
            "settlement=\(registry.settlement.settlementID.rawValue)",
            "anchor=\(positionText(registry.settlement.anchor))",
            "reception=\(positionText(registry.settlement.receptionPosition))",
            "capacity=\(registry.settlement.capacity)",
            "residents=\(registry.settlement.residentIDs.map(\.rawValue).joined(separator: ","))",
            "transit=\(registry.settlement.inTransitIDs.map(\.rawValue).joined(separator: ","))",
            members.map {
                "m|\($0.agentID.rawValue)|\($0.ordinal.rawValue)|\($0.status.rawValue)|\($0.founder ? 1 : 0)|\($0.registeredTick)|\($0.arrivalTick.map(String.init) ?? "none")|\($0.migrationID?.rawValue ?? "none")|\($0.registrationEventID.rawValue)|\($0.arrivalEventID?.rawValue ?? "none")"
            }.joined(separator: ";"),
            migrations.map {
                "g|\($0.migrationID.rawValue)|\($0.migrantID.rawValue)|\($0.ordinal.rawValue)|\($0.status.rawValue)|\($0.routeCursor)|\($0.route.map(positionText).joined(separator: ">"))|\($0.deadlineTick)|\($0.failure?.rawValue ?? "none")|\($0.proposedEventID.rawValue)|\($0.admittedEventID.rawValue)|\($0.startedEventID.rawValue)|\($0.arrivedEventID?.rawValue ?? "none")|\($0.lastMovementEventID?.rawValue ?? "none")"
            }.joined(separator: ";"),
            "next=\(registry.nextPopulationOrdinal.rawValue)",
            "evicted=\(registry.evictionCounts.terminalMigrations),\(registry.evictionCounts.diagnostics)",
            "last=\(registry.lastPopulationEventID.rawValue)",
            "events=\(eventCount)",
        ].joined(separator: "|")
        return AgentPopulationSnapshot(
            enabled: true,
            settlement: registry.settlement,
            members: members,
            migrations: migrations,
            nextPopulationOrdinal: registry.nextPopulationOrdinal.rawValue,
            evictionCounts: registry.evictionCounts,
            populationCausalEventCount: eventCount,
            digest: AgentPopulationDigest.make(canonical)
        )
    }

    public func populationSummary() -> AgentPopulationSummary {
        let snapshot = populationSnapshot()
        return AgentPopulationSummary(
            enabled: snapshot.enabled,
            settlementID: snapshot.settlement?.settlementID,
            capacity: snapshot.settlement?.capacity ?? 0,
            memberCount: snapshot.members.count,
            founderCount: snapshot.members.filter(\.founder).count,
            residentCount: snapshot.members.filter {
                $0.status == .founderResident || $0.status == .resident
            }.count,
            migratingCount: snapshot.members.filter { $0.status == .migrating }.count,
            nextPopulationOrdinal: snapshot.nextPopulationOrdinal,
            activeMigrationCount: snapshot.migrations.filter {
                $0.status == .admitted || $0.status == .inTransit
            }.count,
            arrivedMigrationCount: snapshot.migrations.filter { $0.status == .arrived }.count,
            rejectedMigrationCount: snapshot.migrations.filter { $0.status == .rejected }.count,
            failedMigrationCount: snapshot.migrations.filter { $0.status == .failed }.count,
            populationCausalEventCount: snapshot.populationCausalEventCount,
            evictionCounts: snapshot.evictionCounts,
            digest: snapshot.digest
        )
    }

    public func migrationSnapshot() -> AgentMigrationSnapshot {
        let migrations = populationRegistry?.migrations.sorted {
            $0.migrationID < $1.migrationID
        } ?? []
        let active = migrations.first {
            $0.status == .admitted || $0.status == .inTransit
        }?.migrationID
        let canonical = migrations.map {
            "\($0.migrationID.rawValue)|\($0.migrantID.rawValue)|\($0.status.rawValue)|\($0.routeCursor)|\($0.failure?.rawValue ?? "none")"
        }.joined(separator: ";")
        return AgentMigrationSnapshot(
            enabled: populationRegistry != nil,
            migrations: migrations,
            activeMigrationID: active,
            digest: AgentPopulationDigest.make(canonical)
        )
    }

    public func populationSnapshot(for agentID: AgentID) -> AgentPopulationSnapshot {
        guard let registry = populationRegistry,
              let member = registry.members.first(where: { $0.agentID == agentID }) else {
            return AgentPopulationSnapshot(
                enabled: populationRegistry != nil,
                settlement: nil,
                members: [],
                migrations: [],
                nextPopulationOrdinal: nil,
                evictionCounts: AgentPopulationEvictionCounts(),
                populationCausalEventCount: 0,
                digest: AgentPopulationDigest.make("unregistered|\(agentID.rawValue)")
            )
        }
        let migration = member.migrationID.flatMap { id in
            registry.migrations.first { $0.migrationID == id }
        }
        return AgentPopulationSnapshot(
            enabled: true,
            settlement: nil,
            members: [member],
            migrations: migration.map { [$0] } ?? [],
            nextPopulationOrdinal: nil,
            evictionCounts: AgentPopulationEvictionCounts(),
            populationCausalEventCount: 0,
            digest: AgentPopulationDigest.make(
                "\(member.agentID.rawValue)|\(member.status.rawValue)|\(migration?.status.rawValue ?? "none")"
            )
        )
    }

    public func expectedActiveAgentIDs() -> [AgentID] {
        statesById.values.map(\.agentID).sorted()
    }

    public mutating func initializePopulationRegistry(
        settlementAnchor: AgentPosition,
        receptionPosition: AgentPosition,
        configuration: AgentPopulationConfiguration = .live
    ) throws {
        guard causalLedger.isEnabled else {
            throw AgentSessionError.population(.causalLedgerRequired)
        }
        guard populationRegistry == nil else {
            throw AgentSessionError.population(.alreadyEnabled)
        }
        let founderIDs = sortedIds
        guard founderIDs == ["agent_0", "agent_1", "agent_2"] else {
            throw AgentSessionError.population(
                .invalidFounder(founderIDs.joined(separator: ","))
            )
        }
        try prevalidateCausalAppend(count: founderIDs.count + 1)
        let initialized = try requiredPopulationEvent(
            kind: .populationRegistryInitialized,
            payload: .population(
                settlementID: AgentSettlementID.main.rawValue,
                memberID: nil,
                ordinal: nil,
                founder: nil,
                status: "initialized",
                populationBefore: founderIDs.count,
                populationAfter: founderIDs.count
            ),
            summary: "population registry initialized founders=\(founderIDs.count)"
        )
        var members: [AgentPopulationMemberRecord] = []
        var latest = initialized.eventID
        for (ordinalValue, rawID) in founderIDs.enumerated() {
            let agentID = AgentID(rawValue: rawID)!
            let ordinal = AgentPopulationOrdinal(rawValue: ordinalValue)!
            let event = try requiredPopulationEvent(
                kind: .populationMemberRegistered,
                actorID: agentID,
                subjectID: agentID,
                causes: [initialized.eventID],
                payload: .population(
                    settlementID: AgentSettlementID.main.rawValue,
                    memberID: rawID,
                    ordinal: ordinalValue,
                    founder: true,
                    status: AgentPopulationMembershipStatus.founderResident.rawValue,
                    populationBefore: founderIDs.count,
                    populationAfter: founderIDs.count
                ),
                summary: "founder registered member=\(rawID)"
            )
            latest = event.eventID
            members.append(AgentPopulationMemberRecord(
                agentID: agentID,
                ordinal: ordinal,
                settlementID: .main,
                status: .founderResident,
                founder: true,
                registeredTick: tick,
                arrivalTick: tick,
                migrationID: nil,
                entryPosition: nil,
                receptionPosition: receptionPosition,
                registrationEventID: event.eventID,
                arrivalEventID: event.eventID
            ))
        }
        populationRegistry = AgentPopulationRegistry(
            configuration: configuration,
            settlement: AgentPopulationSettlement(
                anchor: settlementAnchor,
                receptionPosition: receptionPosition,
                capacity: configuration.maximumActivePopulation,
                residentIDs: members.map(\.agentID),
                inTransitIDs: []
            ),
            members: members,
            migrations: [],
            nextPopulationOrdinal: AgentPopulationOrdinal(rawValue: 3)!,
            evictionCounts: AgentPopulationEvictionCounts(),
            initializedEventID: initialized.eventID,
            lastPopulationEventID: latest
        )
    }

    public mutating func setPopulationEnabled(
        _ enabled: Bool,
        settlementAnchor: AgentPosition? = nil,
        receptionPosition: AgentPosition? = nil,
        configuration: AgentPopulationConfiguration = .live
    ) throws {
        if enabled {
            guard let settlementAnchor, let receptionPosition else {
                throw AgentSessionError.population(
                    .invalidConfiguration("settlement positions")
                )
            }
            try initializePopulationRegistry(
                settlementAnchor: settlementAnchor,
                receptionPosition: receptionPosition,
                configuration: configuration
            )
        } else if populationRegistry != nil {
            throw AgentSessionError.population(.unsafeDisable)
        }
    }

    @discardableResult
    public mutating func admitMigration(
        intent: AgentMigrationAdmissionIntent,
        observation: AgentMigrationWorldObservation
    ) throws -> AgentMigrationRecord {
        var candidate = self
        try candidate.prevalidateKinshipAdmission(parentIDs: nil)
        try candidate.prevalidateHouseholdMigrationAdmission()
        try candidate.prevalidateCausalAppend(
            count: 4 + (candidate.lifecycleState == nil ? 0 : 1)
                + (candidate.kinshipState == nil ? 0 : 1)
                + (candidate.householdState == nil ? 0 : 2)
        )
        let migration = try candidate.admitMigrationInPlace(
            intent: intent,
            observation: observation
        )
        if let member = candidate.populationRegistry?.members.first(where: {
            $0.agentID == migration.migrantID
        }) {
            try candidate.registerImportedLifecycleMemberIfNeeded(member)
            try candidate.registerKinshipRoot(
                agentID: member.agentID,
                ordinal: member.ordinal,
                causeEventID: member.registrationEventID
            )
            try candidate.registerHouseholdMigrationAdmission(
                agentID: member.agentID,
                residenceAnchor: member.receptionPosition,
                causeEventID: candidate.kinshipState?.lastKinshipEventID
                    ?? member.registrationEventID
            )
        }
        try candidate.validateKinshipCrossDomainIfEnabled()
        try candidate.validateHouseholdCrossDomainIfEnabled()
        try candidate.validateDependentCareCrossDomainIfEnabled()
        self = candidate
        return migration
    }

    mutating func admitMigrationInPlace(
        intent: AgentMigrationAdmissionIntent,
        observation: AgentMigrationWorldObservation
    ) throws -> AgentMigrationRecord {
        guard var registry = populationRegistry else {
            throw AgentSessionError.population(.disabled)
        }
        guard registry.members.count < registry.configuration.maximumActivePopulation else {
            throw AgentSessionError.population(.admission(.populationFull))
        }
        guard !registry.migrations.contains(where: {
            $0.origin == intent.origin
                && $0.destinationSettlementID == intent.destinationSettlementID
                && $0.entryPosition == observation.entryPosition
                && !$0.status.isTerminal
        }) else {
            throw AgentSessionError.population(.admission(.duplicateAdmission))
        }
        guard registry.migrations.filter({
            $0.status == .admitted || $0.status == .inTransit
        }).count < registry.configuration.maximumConcurrentMigrations else {
            throw AgentSessionError.population(.admission(.migrationAlreadyActive))
        }
        guard intent.origin == .outsideNorth,
              intent.destinationSettlementID == registry.settlement.settlementID,
              observation.receptionPosition == registry.settlement.receptionPosition,
              (0..<registry.configuration.maximumEntryCandidates).contains(
                  observation.candidateIndex
              ) else {
            throw AgentSessionError.population(.admission(.invalidWorldObservation))
        }
        guard observation.entryChunkReady else {
            throw AgentSessionError.population(.admission(.entryChunkUnavailable))
        }
        guard observation.entrySafe else {
            throw AgentSessionError.population(.admission(.noValidEntry))
        }
        guard observation.entryUnoccupied else {
            throw AgentSessionError.population(.admission(.entryOccupied))
        }
        guard observation.receptionChunkReady, observation.receptionSafe,
              observation.receptionUnoccupied else {
            throw AgentSessionError.population(.admission(.receptionUnavailable))
        }
        let route = observation.route
        guard route.count >= 2,
              route.first == observation.entryPosition,
              route.last == observation.receptionPosition,
              route.count - 1 <= registry.configuration.maximumRouteLength,
              manhattanDistance(observation.entryPosition, observation.receptionPosition)
                <= registry.configuration.maximumMigrationDistance,
              Set(route).count == route.count,
              zip(route, route.dropFirst()).allSatisfy({ pair in
                  let (lhs, rhs) = pair
                  return abs(lhs.x - rhs.x) + abs(lhs.z - rhs.z) == 1
                      && (-1...1).contains(rhs.y - lhs.y)
              }) else {
            throw AgentSessionError.population(.admission(.routeUnavailable))
        }
        let ordinal = registry.nextPopulationOrdinal
        let rawAgentID = "agent_\(ordinal.rawValue)"
        guard let agentID = AgentID(rawValue: rawAgentID),
              statesById[rawAgentID] == nil else {
            throw AgentSessionError.population(.admission(.duplicateAdmission))
        }
        guard ordinal.rawValue < Int.max,
              let nextOrdinal = AgentPopulationOrdinal(rawValue: ordinal.rawValue + 1) else {
            throw AgentSessionError.population(.ordinalOverflow)
        }
        let migrationID = AgentMigrationID(
            rawValue: "migration-\(String(format: "%08d", ordinal.rawValue))"
        )!
        try prevalidateCausalAppend(count: 4)
        let proposed = try requiredPopulationEvent(
            kind: .migrationProposed,
            actorID: agentID,
            subjectID: agentID,
            causes: [registry.lastPopulationEventID],
            payload: migrationPayload(
                migrationID: migrationID,
                migrantID: agentID,
                intent: intent,
                observation: observation,
                status: .proposed,
                reason: nil
            ),
            summary: "migration proposed id=\(migrationID.rawValue) migrant=\(rawAgentID)"
        )
        let memberEvent = try requiredPopulationEvent(
            kind: .populationMemberRegistered,
            actorID: agentID,
            subjectID: agentID,
            causes: [proposed.eventID],
            payload: .population(
                settlementID: registry.settlement.settlementID.rawValue,
                memberID: rawAgentID,
                ordinal: ordinal.rawValue,
                founder: false,
                status: AgentPopulationMembershipStatus.migrating.rawValue,
                populationBefore: registry.members.count,
                populationAfter: registry.members.count + 1
            ),
            summary: "migrant member registered id=\(rawAgentID)"
        )
        let admitted = try requiredPopulationEvent(
            kind: .migrationAdmitted,
            actorID: agentID,
            subjectID: agentID,
            causes: [proposed.eventID, memberEvent.eventID].sorted(),
            payload: migrationPayload(
                migrationID: migrationID,
                migrantID: agentID,
                intent: intent,
                observation: observation,
                status: .admitted,
                reason: nil
            ),
            summary: "migration admitted id=\(migrationID.rawValue)"
        )
        let started = try requiredPopulationEvent(
            kind: .migrationStarted,
            actorID: agentID,
            subjectID: agentID,
            causes: [admitted.eventID],
            payload: migrationPayload(
                migrationID: migrationID,
                migrantID: agentID,
                intent: intent,
                observation: observation,
                status: .inTransit,
                reason: nil
            ),
            summary: "migration started id=\(migrationID.rawValue)"
        )
        let routeValue = AgentNavigationRoute(
            purpose: .migrationArrival,
            target: observation.receptionPosition,
            positions: route,
            plannedAtTick: tick,
            visitedNodeCount: route.count
        )
        statesById[rawAgentID] = AgentSessionAgentState(
            agentID: agentID,
            state: "migrating",
            position: observation.entryPosition,
            needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0.2, safety: 1),
            health: 100,
            fear: 0,
            homePosition: observation.receptionPosition,
            nearbyAgents: [],
            currentGoal: AgentGoal(
                kind: .migrateToSettlement,
                reason: "admitted migrant must reach settlement reception",
                startedAtTick: tick,
                urgency: 79
            ),
            lastAction: nil,
            lastActionEffect: nil,
            memory: [],
            tickCreated: tick,
            ticksAlive: 0,
            observationCount: 0,
            nearbyObservationCount: 0,
            goalSelectionCount: 0,
            goalChangeCount: 0,
            actionCount: 0,
            actionEffectCount: 0,
            movementCount: 0,
            totalManhattanDistanceMoved: 0,
            returnHomeMoveCount: 0,
            totalDistanceReducedTowardHome: 0,
            navigationProgress: AgentNavigationProgress(
                status: .active,
                route: routeValue,
                routeIndex: 0,
                replanCount: 0,
                consecutiveBlockedMoves: 0,
                lastPlanTick: tick
            )
        )
        let member = AgentPopulationMemberRecord(
            agentID: agentID,
            ordinal: ordinal,
            settlementID: registry.settlement.settlementID,
            status: .migrating,
            founder: false,
            registeredTick: tick,
            arrivalTick: nil,
            migrationID: migrationID,
            entryPosition: observation.entryPosition,
            receptionPosition: observation.receptionPosition,
            registrationEventID: memberEvent.eventID,
            arrivalEventID: nil
        )
        let migration = AgentMigrationRecord(
            migrationID: migrationID,
            migrantID: agentID,
            ordinal: ordinal,
            origin: intent.origin,
            destinationSettlementID: intent.destinationSettlementID,
            entryPosition: observation.entryPosition,
            receptionPosition: observation.receptionPosition,
            route: route,
            routeCursor: 0,
            admittedTick: tick,
            startedTick: tick,
            arrivedTick: nil,
            deadlineTick: tick + registry.configuration.maximumMigrationTicks,
            status: .inTransit,
            failure: nil,
            proposedEventID: proposed.eventID,
            admittedEventID: admitted.eventID,
            startedEventID: started.eventID,
            arrivedEventID: nil,
            lastMovementEventID: nil,
            replanCount: 0
        )
        registry.members.append(member)
        registry.members.sort { $0.agentID < $1.agentID }
        registry.migrations.append(migration)
        registry.migrations.sort { $0.migrationID < $1.migrationID }
        registry.settlement.inTransitIDs.append(agentID)
        registry.settlement.inTransitIDs.sort()
        registry.nextPopulationOrdinal = nextOrdinal
        registry.lastPopulationEventID = started.eventID
        populationRegistry = registry
        return migration
    }

    public mutating func clearPopulationDiagnostics() throws {
        guard var registry = populationRegistry else {
            throw AgentSessionError.population(.disabled)
        }
        let removable = registry.migrations.filter {
            $0.status == .rejected || $0.status == .cancelled
        }
        registry.migrations.removeAll {
            $0.status == .rejected || $0.status == .cancelled
        }
        registry.evictionCounts = AgentPopulationEvictionCounts()
        let event = try requiredPopulationEvent(
            kind: .populationStateCleared,
            causes: [registry.lastPopulationEventID],
            payload: .population(
                settlementID: registry.settlement.settlementID.rawValue,
                memberID: nil,
                ordinal: nil,
                founder: nil,
                status: "diagnosticsCleared",
                populationBefore: registry.members.count,
                populationAfter: registry.members.count
            ),
            summary: "population diagnostics cleared migrations=\(removable.count)"
        )
        registry.lastPopulationEventID = event.eventID
        populationRegistry = registry
    }

    func isMigratingAgent(_ agentID: String) -> Bool {
        populationRegistry?.members.first {
            $0.agentID.rawValue == agentID && $0.status == .migrating
        } != nil
    }

    func migrationRecord(for agentID: String) -> AgentMigrationRecord? {
        populationRegistry?.migrations.first {
            $0.migrantID.rawValue == agentID
                && ($0.status == .admitted || $0.status == .inTransit)
        }
    }

    mutating func expireActiveMigrationIfNeeded(at migrationTick: Int) throws {
        guard var registry = populationRegistry,
              let index = registry.migrations.firstIndex(where: {
                  ($0.status == .admitted || $0.status == .inTransit)
                      && migrationTick > $0.deadlineTick
              }) else { return }
        let migration = registry.migrations[index]
        let event = try requiredPopulationEvent(
            kind: .migrationFailed,
            actorID: migration.migrantID,
            subjectID: migration.migrantID,
            causes: [
                migration.admittedEventID,
                migration.lastMovementEventID,
            ].compactMap { $0 }.sorted(),
            payload: .migration(
                migrationID: migration.migrationID.rawValue,
                migrantID: migration.migrantID.rawValue,
                origin: migration.origin.rawValue,
                destination: migration.destinationSettlementID.rawValue,
                entry: migration.entryPosition,
                reception: migration.receptionPosition,
                status: AgentMigrationStatus.failed.rawValue,
                reason: AgentMigrationFailure.deadlineExceeded.rawValue,
                routeLength: migration.route.count
            ),
            summary: "migration failed deadline id=\(migration.migrationID.rawValue)"
        )
        registry.migrations[index].status = .failed
        registry.migrations[index].failure = .deadlineExceeded
        registry.lastPopulationEventID = event.eventID
        populationRegistry = registry
    }

    mutating func updatePopulationAfterMovementEvents() throws {
        guard var registry = populationRegistry else { return }
        let activeIndices = registry.migrations.indices.filter {
            registry.migrations[$0].status == .admitted
                || registry.migrations[$0].status == .inTransit
        }.sorted {
            registry.migrations[$0].migrationID < registry.migrations[$1].migrationID
        }
        for index in activeIndices {
            let migrantID = registry.migrations[index].migrantID
            guard var state = statesById[migrantID.rawValue] else {
                registry.migrations[index].status = .failed
                registry.migrations[index].failure = .memberMissing
                continue
            }
            registry.migrations[index].routeCursor = state.navigationProgress.routeIndex
            registry.migrations[index].replanCount = state.navigationProgress.replanCount
            registry.migrations[index].lastMovementEventID = lastOutcomeEventByAgentID[migrantID]
            guard state.position == registry.migrations[index].receptionPosition,
                  state.navigationProgress.status == .arrived,
                  state.navigationProgress.routeIndex
                    == registry.migrations[index].route.count - 1 else { continue }
            let migration = registry.migrations[index]
            let arrival = try requiredPopulationEvent(
                kind: .migrationArrived,
                actorID: migrantID,
                subjectID: migrantID,
                causes: [
                    migration.admittedEventID,
                    migration.lastMovementEventID,
                ].compactMap { $0 }.sorted(),
                payload: .migration(
                    migrationID: migration.migrationID.rawValue,
                    migrantID: migrantID.rawValue,
                    origin: migration.origin.rawValue,
                    destination: migration.destinationSettlementID.rawValue,
                    entry: migration.entryPosition,
                    reception: migration.receptionPosition,
                    status: AgentMigrationStatus.arrived.rawValue,
                    reason: nil,
                    routeLength: migration.route.count
                ),
                summary: "migration arrived id=\(migration.migrationID.rawValue)"
            )
            let resident = try requiredPopulationEvent(
                kind: .populationMemberRegistered,
                actorID: migrantID,
                subjectID: migrantID,
                causes: [arrival.eventID],
                payload: .population(
                    settlementID: registry.settlement.settlementID.rawValue,
                    memberID: migrantID.rawValue,
                    ordinal: migration.ordinal.rawValue,
                    founder: false,
                    status: AgentPopulationMembershipStatus.resident.rawValue,
                    populationBefore: registry.members.count,
                    populationAfter: registry.members.count
                ),
                summary: "migrant became resident id=\(migrantID.rawValue)"
            )
            registry.migrations[index].status = .arrived
            registry.migrations[index].arrivedTick = tick
            registry.migrations[index].arrivedEventID = arrival.eventID
            if let memberIndex = registry.members.firstIndex(where: {
                $0.agentID == migrantID
            }) {
                registry.members[memberIndex].status = .resident
                registry.members[memberIndex].arrivalTick = tick
                registry.members[memberIndex].arrivalEventID = resident.eventID
            }
            registry.settlement.inTransitIDs.removeAll { $0 == migrantID }
            if !registry.settlement.residentIDs.contains(migrantID) {
                registry.settlement.residentIDs.append(migrantID)
                registry.settlement.residentIDs.sort()
            }
            registry.lastPopulationEventID = resident.eventID
            state.state = "idle"
            state.homePosition = migration.receptionPosition
            state.currentGoal = AgentGoal(
                kind: .idle,
                reason: "migration arrived at settlement reception",
                startedAtTick: tick,
                urgency: 0
            )
            state.navigationProgress = AgentNavigationProgress()
            statesById[migrantID.rawValue] = state
            populationRegistry = registry
            try registerHouseholdArrivalIfNeeded(
                agentID: migrantID,
                residenceAnchor: migration.receptionPosition,
                causeEventID: resident.eventID
            )
        }
        populationRegistry = registry
        try validateHouseholdCrossDomainIfEnabled()
        try validateDependentCareCrossDomainIfEnabled()
    }

    static func validatePopulationRegistry(
        _ registry: AgentPopulationRegistry,
        agents: [AgentSessionAgentState],
        clock: AgentSimulationClock,
        departedAgentIDs: Set<AgentID> = []
    ) throws {
        let agentIDs = Set(agents.map(\.agentID))
        guard registry.configuration.maximumActivePopulation >= 3,
              registry.settlement.settlementID == .main,
              registry.settlement.capacity == registry.configuration.maximumActivePopulation,
              registry.members.count == agentIDs.count,
              registry.members.count <= registry.settlement.capacity,
              Set(registry.members.map(\.agentID)) == agentIDs,
              Set(registry.members.map(\.ordinal)).count == registry.members.count,
              registry.nextPopulationOrdinal.rawValue
                > (registry.members.map(\.ordinal.rawValue).max() ?? -1),
              registry.migrations.count <= registry.configuration.maximumMigrationRecords,
              registry.evictionCounts.terminalMigrations >= 0,
              registry.evictionCounts.diagnostics >= 0 else {
            throw AgentCheckpointError.invalidBound("population registry")
        }
        let active = registry.migrations.filter {
            $0.status == .admitted || $0.status == .inTransit
        }
        guard active.count <= registry.configuration.maximumConcurrentMigrations,
              registry.settlement.residentIDs == registry.settlement.residentIDs.sorted(),
              registry.settlement.inTransitIDs == registry.settlement.inTransitIDs.sorted(),
              Set(registry.settlement.residentIDs).isSubset(of: agentIDs),
              Set(registry.settlement.inTransitIDs).isSubset(of: agentIDs) else {
            throw AgentCheckpointError.invalidBound("population settlement")
        }
        for member in registry.members {
            guard member.settlementID == registry.settlement.settlementID,
                  member.registeredTick <= clock.tick.rawValue,
                  member.arrivalTick.map({ $0 <= clock.tick.rawValue }) ?? true,
                  member.registrationEventID.simulationID == clock.simulationID,
                  member.arrivalEventID?.simulationID == clock.simulationID
                    || member.arrivalEventID == nil else {
                throw AgentCheckpointError.invalidReference(member.agentID.rawValue)
            }
        }
        for migration in registry.migrations {
            let referencesActive = agentIDs.contains(migration.migrantID)
            let referencesDeparted = departedAgentIDs.contains(migration.migrantID)
                && migration.status.isTerminal
            guard (referencesActive || referencesDeparted),
                  migration.route.count >= 2,
                  migration.route.count - 1 <= registry.configuration.maximumRouteLength,
                  migration.route.first == migration.entryPosition,
                  migration.route.last == migration.receptionPosition,
                  migration.route.indices.contains(migration.routeCursor),
                  migration.deadlineTick >= migration.startedTick,
                  migration.replanCount <= registry.configuration.maximumMigrationReplans,
                  migration.proposedEventID.simulationID == clock.simulationID,
                  migration.admittedEventID.simulationID == clock.simulationID,
                  migration.startedEventID.simulationID == clock.simulationID else {
                throw AgentCheckpointError.invalidReference(migration.migrationID.rawValue)
            }
        }
    }

    private func migrationPayload(
        migrationID: AgentMigrationID,
        migrantID: AgentID,
        intent: AgentMigrationAdmissionIntent,
        observation: AgentMigrationWorldObservation,
        status: AgentMigrationStatus,
        reason: AgentMigrationFailure?
    ) -> AgentCausalPayload {
        .migration(
            migrationID: migrationID.rawValue,
            migrantID: migrantID.rawValue,
            origin: intent.origin.rawValue,
            destination: intent.destinationSettlementID.rawValue,
            entry: observation.entryPosition,
            reception: observation.receptionPosition,
            status: status.rawValue,
            reason: reason?.rawValue,
            routeLength: observation.route.count
        )
    }

    private mutating func requiredPopulationEvent(
        kind: AgentCausalEventKind,
        actorID: AgentID? = nil,
        subjectID: AgentID? = nil,
        causes: [AgentCausalEventID] = [],
        payload: AgentCausalPayload,
        summary: String
    ) throws -> AgentCausalEvent {
        guard let event = try recordCausalEvent(
            kind: kind,
            origin: .populationTransition,
            actorID: actorID,
            subjectID: subjectID,
            causes: causes,
            payload: payload,
            summary: summary
        ) else {
            throw AgentSessionError.population(.causalLedgerRequired)
        }
        return event
    }
}

extension AgentMigrationStatus {
    var isTerminal: Bool {
        switch self {
        case .arrived, .rejected, .cancelled, .failed: return true
        case .proposed, .admitted, .inTransit: return false
        }
    }
}

extension AgentCausalEventKind {
    var isPopulation: Bool {
        switch self {
        case .populationRegistryInitialized, .populationMemberRegistered,
             .migrationProposed, .migrationAdmitted, .migrationStarted,
             .migrationArrived, .migrationRejected, .migrationCancelled,
             .migrationFailed, .populationMemberExited, .populationStateCleared:
            return true
        case .populationMemberBorn:
            return true
        default:
            return false
        }
    }
}
