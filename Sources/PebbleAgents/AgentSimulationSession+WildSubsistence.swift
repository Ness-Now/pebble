extension AgentSimulationSession {
    public var wildSubsistenceEnabled: Bool { wildSubsistenceState != nil }

    public func wildSubsistenceSnapshot() -> AgentWildSubsistenceSnapshot {
        guard let state = wildSubsistenceState else {
            return AgentWildSubsistenceSnapshot(
                enabled: false, configuration: nil, opportunities: [], retainedOutcomes: [],
                totalOpportunityCount: 0, totalAttemptCount: 0, successfulCounts: [:],
                evictionCounts: AgentWildSubsistenceEvictionCounts(),
                digest: AgentWildSubsistenceDigest.make("disabled")
            )
        }
        return AgentWildSubsistenceSnapshot(
            enabled: true, configuration: state.configuration,
            opportunities: state.opportunities.sorted(by: subsistenceOpportunitySort),
            retainedOutcomes: state.retainedOutcomes.sorted(by: subsistenceOutcomeRecordSort),
            totalOpportunityCount: state.totalOpportunityCount,
            totalAttemptCount: state.totalAttemptCount,
            successfulCounts: state.successfulCounts,
            evictionCounts: state.evictionCounts,
            digest: wildSubsistenceDigest(state)
        )
    }

    public mutating func setWildSubsistenceEnabled(
        _ enabled: Bool,
        configuration: AgentWildSubsistenceConfiguration = .live
    ) throws {
        if enabled {
            guard wildSubsistenceState == nil else {
                throw AgentSessionError.wildSubsistence(.alreadyEnabled)
            }
            guard causalLedger.policy != .disabled else {
                throw AgentSessionError.wildSubsistence(.causalLedgerRequired)
            }
            guard populationRegistry != nil else {
                throw AgentSessionError.wildSubsistence(.populationRequired)
            }
            guard lifecycleState != nil else {
                throw AgentSessionError.wildSubsistence(.lifecycleRequired)
            }
            guard skillState != nil else {
                throw AgentSessionError.wildSubsistence(.skillsRequired)
            }
            guard ecologicalObservationState != nil else {
                throw AgentSessionError.wildSubsistence(.ecologicalObservationRequired)
            }
            var candidate = self
            try candidate.prevalidateCausalAppend(count: 1)
            let digest = AgentWildSubsistenceDigest.make("empty")
            let event = try candidate.requiredWildSubsistenceEvent(
                kind: .wildSubsistenceInitialized,
                payload: candidate.wildSubsistencePayload(
                    strategy: nil, status: "initialized", quantity: 0, digest: digest
                ),
                summary: "wild subsistence initialized without retroactive outcomes"
            )
            candidate.wildSubsistenceState = AgentWildSubsistenceState(
                configuration: configuration, opportunities: [], retainedOutcomes: [],
                processedAttemptIDs: [], totalOpportunityCount: 0, totalAttemptCount: 0,
                successfulCounts: [:], evictionCounts: AgentWildSubsistenceEvictionCounts(),
                rollingDigest: digest, initializedEventID: event.eventID,
                lastSubsistenceEventID: event.eventID,
                transitionTick: candidate.tick, attemptsAtTick: 0
            )
            try candidate.validateWildSubsistenceStateIfEnabled()
            self = candidate
        } else if wildSubsistenceState != nil {
            throw AgentSessionError.wildSubsistence(.unsafeDisable)
        }
    }

    /// Returns only strategies supported by fresh local evidence and current
    /// equipment/capability facts. Scores use experienced history, not hidden
    /// Core loot tables or global resource counts.
    public func eligibleSubsistenceStrategies(
        _ context: AgentSubsistenceDecisionContext
    ) throws -> [AgentSubsistenceStrategyCandidate] {
        guard let state = wildSubsistenceState else {
            throw AgentSessionError.wildSubsistence(.disabled)
        }
        guard (1...64).contains(context.maximumDistance),
              (0...100).contains(context.subsistencePressure) else {
            throw AgentSessionError.wildSubsistence(.invalidOpportunity("decision bounds"))
        }
        guard statesById[context.actorID.rawValue]?.health ?? 0 > 0 else {
            throw AgentSessionError.wildSubsistence(.unknownAgent(context.actorID))
        }
        guard lifecycleState?.members.first(where: {
            $0.agentID == context.actorID
        })?.currentStage == .mature else {
            throw AgentSessionError.wildSubsistence(.incapableAgent(context.actorID))
        }
        guard let record = ecologicalObservations(for: context.actorID).first,
              record.observation.isFresh(atSimulationTick: tick) else {
            return context.agricultureAvailable
                ? [agricultureCandidate(context: context, origin: statesById[context.actorID.rawValue]!.position)]
                : []
        }
        let observation = record.observation
        let origin = observation.origin
        let reserved = Set(state.opportunities.filter {
            $0.status == .selected && $0.expiresAtTick >= tick
                && $0.actorID != context.actorID
                && ($0.strategy == .hunting || $0.strategy == .wildGathering)
        }.map(\.targetKey))
        var candidates: [AgentSubsistenceStrategyCandidate] = []

        if context.agricultureAvailable {
            candidates.append(agricultureCandidate(context: context, origin: origin))
        }
        if context.fishingRodAvailable {
            for affordance in observation.fishing where affordance.candidate {
                let distance = subsistenceDistance(origin, affordance.position)
                guard distance <= context.maximumDistance else { continue }
                candidates.append(subsistenceCandidate(
                    strategy: .fishing, targetKey: "water:\(subsistencePoint(affordance.position))",
                    position: affordance.position, sourceObservationEventID: record.causalEventID,
                    distance: distance, pressure: context.subsistencePressure,
                    actorID: context.actorID, baseScore: 62, equipmentScore: 12
                ))
            }
        }
        if context.huntingWeaponAvailable {
            for animal in observation.animals where animal.lifeStage == .adult {
                let distance = subsistenceDistance(origin, animal.position)
                let key = "animal:\(animal.speciesKey)@\(subsistencePoint(animal.position))"
                let currentlyManaged = livestockState?.managedAnimals.contains {
                    $0.status.resolvedLiving && $0.speciesKey == animal.speciesKey
                        && $0.lastKnownPosition == animal.position
                } ?? false
                guard distance <= context.maximumDistance, !reserved.contains(key),
                      !currentlyManaged else { continue }
                candidates.append(subsistenceCandidate(
                    strategy: .hunting, targetKey: key, position: animal.position,
                    sourceObservationEventID: record.causalEventID, distance: distance,
                    pressure: context.subsistencePressure, actorID: context.actorID,
                    baseScore: 56, equipmentScore: 12
                ))
            }
        }
        let gatherable = Set(["sweet_berry_bush", "cave_vines", "cave_vines_plant",
                              "red_mushroom", "brown_mushroom", "melon", "pumpkin"])
        for plant in observation.plants where gatherable.contains(plant.plantKey) {
            let distance = subsistenceDistance(origin, plant.position)
            let key = "plant:\(plant.plantKey)@\(subsistencePoint(plant.position))"
            guard distance <= context.maximumDistance, !reserved.contains(key) else { continue }
            candidates.append(subsistenceCandidate(
                strategy: .wildGathering, targetKey: key, position: plant.position,
                sourceObservationEventID: record.causalEventID, distance: distance,
                pressure: context.subsistencePressure, actorID: context.actorID,
                baseScore: 66, equipmentScore: 0
            ))
        }
        return candidates.sorted(by: subsistenceCandidateSort)
    }

    @discardableResult
    public mutating func selectWildSubsistenceOpportunity(
        _ context: AgentSubsistenceDecisionContext
    ) throws -> AgentSubsistenceOpportunity {
        var candidate = self
        let result = try candidate.selectWildSubsistenceOpportunityInPlace(context)
        try candidate.validateWildSubsistenceStateIfEnabled()
        self = candidate
        return result
    }

    private mutating func selectWildSubsistenceOpportunityInPlace(
        _ context: AgentSubsistenceDecisionContext
    ) throws -> AgentSubsistenceOpportunity {
        guard var state = wildSubsistenceState else {
            throw AgentSessionError.wildSubsistence(.disabled)
        }
        let expired = state.opportunities.filter {
            $0.status == .selected && $0.expiresAtTick < tick
        }.map(\.opportunityID)
        if !expired.isEmpty {
            for index in state.opportunities.indices where expired.contains(state.opportunities[index].opportunityID) {
                state.opportunities[index].status = .expired
            }
        }
        let activeCount = state.opportunities.filter { $0.status == .selected }.count
        guard activeCount < state.configuration.maximumActiveOpportunities else {
            throw AgentSessionError.wildSubsistence(.opportunityCapacityReached)
        }
        let choices = try eligibleSubsistenceStrategies(context)
        guard let choice = choices.first else {
            throw AgentSessionError.wildSubsistence(.noEligibleStrategy)
        }
        let source = choice.sourceObservationEventID?.rawValue ?? "agriculture"
        let identity = AgentWildSubsistenceDigest.make(
            "\(simulationID.rawValue)|\(context.actorID.rawValue)|\(choice.strategy.rawValue)|"
                + "\(choice.targetKey)|\(source)|\(tick)|\(state.totalOpportunityCount + 1)"
        )
        let opportunityID = AgentSubsistenceOpportunityID(rawValue: "subsistence-opportunity-\(identity)")!
        guard !state.opportunities.contains(where: { $0.opportunityID == opportunityID }) else {
            throw AgentSessionError.wildSubsistence(.invalidOpportunity("duplicate identity"))
        }
        try prevalidateCausalAppend(count: 1)
        let digest = AgentWildSubsistenceDigest.make(
            "\(state.rollingDigest)|select|\(opportunityID.rawValue)|\(choice.score)"
        )
        let causes = choice.sourceObservationEventID.map { [$0] } ?? []
        let event = try requiredWildSubsistenceEvent(
            kind: .subsistenceOpportunitySelected, actorID: context.actorID,
            causes: causes,
            payload: wildSubsistencePayload(
                opportunityID: opportunityID, strategy: choice.strategy,
                targetKey: choice.targetKey, status: "selected", quantity: 0,
                digest: digest
            ),
            summary: "subsistence opportunity selected strategy=\(choice.strategy.rawValue) target=\(choice.targetKey)"
        )
        let opportunity = AgentSubsistenceOpportunity(
            opportunityID: opportunityID, actorID: context.actorID,
            strategy: choice.strategy, targetKey: choice.targetKey,
            lastObservedPosition: choice.targetPosition,
            sourceObservationEventID: choice.sourceObservationEventID,
            selectedAtTick: tick,
            expiresAtTick: tick + state.configuration.opportunityLifetimeTicks,
            score: choice.score, reason: choice.reason, status: .selected,
            selectedEventID: event.eventID, terminalEventID: nil
        )
        state.opportunities.append(opportunity)
        state.opportunities.sort(by: subsistenceOpportunitySort)
        state.totalOpportunityCount += 1
        state.lastSubsistenceEventID = event.eventID
        state.rollingDigest = digest
        evictTerminalOpportunitiesIfNeeded(&state)
        wildSubsistenceState = state
        return opportunity
    }

    @discardableResult
    public mutating func recordWildSubsistenceOutcome(
        _ outcome: AgentSubsistenceOutcome
    ) throws -> AgentSubsistenceOutcomeRecord {
        var candidate = self
        let record = try candidate.recordWildSubsistenceOutcomeInPlace(outcome)
        try candidate.validateWildSubsistenceStateIfEnabled()
        self = candidate
        return record
    }

    private mutating func recordWildSubsistenceOutcomeInPlace(
        _ outcome: AgentSubsistenceOutcome
    ) throws -> AgentSubsistenceOutcomeRecord {
        guard var state = wildSubsistenceState else {
            throw AgentSessionError.wildSubsistence(.disabled)
        }
        guard !state.processedAttemptIDs.contains(outcome.attemptID) else {
            throw AgentSessionError.wildSubsistence(.duplicateAttempt(outcome.attemptID))
        }
        if state.transitionTick != tick {
            state.transitionTick = tick
            state.attemptsAtTick = 0
        }
        guard state.attemptsAtTick < state.configuration.maximumAttemptsPerTick else {
            throw AgentSessionError.wildSubsistence(.attemptsPerTickReached)
        }
        guard let opportunityIndex = state.opportunities.firstIndex(where: {
            $0.opportunityID == outcome.opportunityID
        }) else {
            throw AgentSessionError.wildSubsistence(.unknownOpportunity(outcome.opportunityID))
        }
        let opportunity = state.opportunities[opportunityIndex]
        guard opportunity.status == .selected,
              opportunity.actorID == outcome.actorID,
              opportunity.strategy == outcome.strategy,
              opportunity.targetKey == outcome.targetKey,
              opportunity.lastObservedPosition == outcome.targetPosition,
              opportunity.sourceObservationEventID == outcome.sourceObservationEventID,
              opportunity.expiresAtTick >= tick,
              outcome.completedAtTick == tick,
              outcome.strategy.isWild else {
            throw AgentSessionError.wildSubsistence(.invalidOutcome("opportunity mismatch or stale"))
        }
        guard outcome.physicalCausalIDs.count <= state.configuration.maximumPhysicalCausalIDsPerOutcome,
              Set(outcome.physicalCausalIDs).count == outcome.physicalCausalIDs.count,
              outcome.physicalCausalIDs.allSatisfy({ $0 > 0 }),
              outcome.acquiredItems.count <= state.configuration.maximumAcquiredItemKindsPerOutcome,
              outcome.acquiredItems.allSatisfy({
                  $0.count > 0 && !$0.identity.itemKey.isEmpty
                      && $0.identity.itemKey.count <= 160 && $0.identity.damage >= 0
              }),
              // CIV-16 fingerprints are bounded canonical custody JSON, not
              // a short hash. Nine real slots can legitimately exceed 256 B.
              (outcome.custodyFingerprint?.utf8.count ?? 0) <= 16_384,
              (outcome.attribution?.count ?? 0) <= 160 else {
            throw AgentSessionError.wildSubsistence(.invalidOutcome("physical evidence bounds"))
        }
        if outcome.status.isMaterialSuccess {
            guard !outcome.physicalCausalIDs.isEmpty, !outcome.acquiredItems.isEmpty,
                  outcome.acquiredQuantity > 0,
                  outcome.custodyFingerprint?.isEmpty == false,
                  outcome.attribution?.isEmpty == false else {
                throw AgentSessionError.wildSubsistence(.invalidOutcome("material success evidence"))
            }
        } else if outcome.status == .failed || outcome.status == .interrupted {
            guard outcome.physicalCausalIDs.isEmpty, outcome.acquiredItems.isEmpty else {
                throw AgentSessionError.wildSubsistence(.invalidOutcome("failed attempt material claim"))
            }
        }
        try prevalidateCausalAppend(count: outcome.status.isMaterialSuccess && skillState != nil ? 2 : 1)
        let digest = AgentWildSubsistenceDigest.make(
            "\(state.rollingDigest)|outcome|\(outcome.attemptID.rawValue)|"
                + "\(outcome.status.rawValue)|\(outcome.acquiredQuantity)"
        )
        let kind: AgentCausalEventKind
        if outcome.status.isMaterialSuccess {
            switch outcome.strategy {
            case .fishing: kind = .fishingCatchAcquired
            case .hunting: kind = .wildAnimalHunted
            case .wildGathering: kind = .wildResourceGathered
            case .agriculture:
                throw AgentSessionError.wildSubsistence(.invalidOutcome("agriculture belongs to CIV-22"))
            }
        } else {
            kind = .wildSubsistenceAttemptFailed
        }
        let event = try requiredWildSubsistenceEvent(
            kind: kind, actorID: outcome.actorID,
            operationID: AgentOperationID(rawValue: outcome.attemptID.rawValue),
            causes: [opportunity.selectedEventID],
            payload: wildSubsistencePayload(
                opportunityID: outcome.opportunityID, attemptID: outcome.attemptID,
                strategy: outcome.strategy, targetKey: outcome.targetKey,
                status: outcome.status.rawValue, quantity: outcome.acquiredQuantity,
                digest: digest
            ),
            summary: "wild subsistence \(outcome.strategy.rawValue) \(outcome.status.rawValue) quantity=\(outcome.acquiredQuantity)"
        )
        state.opportunities[opportunityIndex].status = {
            switch outcome.status {
            case .succeeded, .reconciled: return .completed
            case .failed: return .failed
            case .interrupted: return .interrupted
            }
        }()
        state.opportunities[opportunityIndex].terminalEventID = event.eventID
        wildSubsistenceState = state

        let skillDomain: AgentSkillDomain?
        switch outcome.strategy {
        case .fishing: skillDomain = .fishing
        case .hunting: skillDomain = .hunting
        case .wildGathering: skillDomain = .foraging
        case .agriculture: skillDomain = nil
        }
        let practiceEventID = outcome.status.isMaterialSuccess
            ? try skillDomain.flatMap {
                try creditPracticeAfterMaterialSuccess(
                    agentID: outcome.actorID, domain: $0,
                    sourceSuccessEventID: event.eventID
                )
            }
            : nil

        state = wildSubsistenceState!
        let record = AgentSubsistenceOutcomeRecord(
            outcome: outcome, subsistenceEventID: event.eventID,
            skillPracticeEventID: practiceEventID, digest: digest
        )
        state.retainedOutcomes.append(record)
        state.retainedOutcomes.sort(by: subsistenceOutcomeRecordSort)
        state.processedAttemptIDs.append(outcome.attemptID)
        state.totalAttemptCount += 1
        state.attemptsAtTick += 1
        if outcome.status.isMaterialSuccess {
            state.successfulCounts[outcome.strategy, default: 0] += 1
        }
        if state.retainedOutcomes.count > state.configuration.maximumRetainedOutcomes {
            let remove = state.retainedOutcomes.count - state.configuration.maximumRetainedOutcomes
            state.retainedOutcomes.removeFirst(remove)
            state.evictionCounts.outcomes += remove
        }
        if state.processedAttemptIDs.count > state.configuration.maximumProcessedAttemptIDs {
            let remove = state.processedAttemptIDs.count - state.configuration.maximumProcessedAttemptIDs
            state.processedAttemptIDs.removeFirst(remove)
            state.evictionCounts.processedAttemptIDs += remove
        }
        state.lastSubsistenceEventID = event.eventID
        state.rollingDigest = digest
        evictTerminalOpportunitiesIfNeeded(&state)
        wildSubsistenceState = state
        return record
    }

    func validateWildSubsistenceStateIfEnabled() throws {
        guard let state = wildSubsistenceState else { return }
        try Self.validateWildSubsistenceState(
            state, agents: Set(statesById.values.map(\.agentID)), clock: clock,
            causalLatestSequence: causalLedger.latestSequence,
            causalDroppedEventCount: causalLedger.droppedEventCount,
            causalEvents: causalLedger.events
        )
    }

    static func validateWildSubsistenceState(
        _ state: AgentWildSubsistenceState,
        agents: Set<AgentID>,
        clock: AgentSimulationClock,
        causalLatestSequence: UInt64,
        causalDroppedEventCount: UInt64,
        causalEvents: [AgentCausalEvent]
    ) throws {
        _ = try AgentWildSubsistenceConfiguration(
            maximumActiveOpportunities: state.configuration.maximumActiveOpportunities,
            opportunityLifetimeTicks: state.configuration.opportunityLifetimeTicks,
            maximumRetainedOutcomes: state.configuration.maximumRetainedOutcomes,
            maximumProcessedAttemptIDs: state.configuration.maximumProcessedAttemptIDs,
            maximumAttemptsPerTick: state.configuration.maximumAttemptsPerTick,
            maximumPhysicalCausalIDsPerOutcome: state.configuration.maximumPhysicalCausalIDsPerOutcome,
            maximumAcquiredItemKindsPerOutcome: state.configuration.maximumAcquiredItemKindsPerOutcome
        )
        guard state.opportunities.filter({ $0.status == .selected }).count
                <= state.configuration.maximumActiveOpportunities,
              state.retainedOutcomes.count <= state.configuration.maximumRetainedOutcomes,
              state.processedAttemptIDs.count <= state.configuration.maximumProcessedAttemptIDs,
              Set(state.opportunities.map(\.opportunityID)).count == state.opportunities.count,
              Set(state.processedAttemptIDs).count == state.processedAttemptIDs.count,
              state.totalOpportunityCount >= state.opportunities.count,
              state.totalAttemptCount >= state.retainedOutcomes.count,
              state.transitionTick <= clock.tick.rawValue,
              (0...state.configuration.maximumAttemptsPerTick).contains(state.attemptsAtTick),
              state.evictionCounts.opportunities >= 0,
              state.evictionCounts.outcomes >= 0,
              state.evictionCounts.processedAttemptIDs >= 0 else {
            throw AgentWildSubsistenceError.invalidState("bounds, uniqueness, or counters")
        }
        let knownEvents = Dictionary(uniqueKeysWithValues: causalEvents.map { ($0.eventID, $0) })
        func validReference(_ id: AgentCausalEventID) -> Bool {
            id.simulationID == clock.simulationID
                && id.sequence.rawValue <= causalLatestSequence
                && (knownEvents[id] != nil || id.sequence.rawValue <= causalDroppedEventCount)
        }
        guard validReference(state.initializedEventID),
              validReference(state.lastSubsistenceEventID),
              state.opportunities.allSatisfy({ opportunity in
                  agents.contains(opportunity.actorID)
                      && !opportunity.targetKey.isEmpty && opportunity.targetKey.count <= 200
                      && opportunity.selectedAtTick <= clock.tick.rawValue
                      && opportunity.expiresAtTick >= opportunity.selectedAtTick
                      && validReference(opportunity.selectedEventID)
                      && opportunity.sourceObservationEventID.map(validReference) ?? true
                      && opportunity.terminalEventID.map(validReference) ?? true
              }),
              state.retainedOutcomes.allSatisfy({ record in
                  agents.contains(record.outcome.actorID)
                      && record.outcome.completedAtTick <= clock.tick.rawValue
                      && record.outcome.strategy.isWild
                      && validReference(record.subsistenceEventID)
                      && record.skillPracticeEventID.map(validReference) ?? true
              }),
              state.successfulCounts.allSatisfy({ $0.key.isWild && $0.value >= 0 }) else {
            throw AgentWildSubsistenceError.invalidState("references or histories")
        }
    }

    private func agricultureCandidate(
        context: AgentSubsistenceDecisionContext,
        origin: AgentPosition
    ) -> AgentSubsistenceStrategyCandidate {
        let history = recentSubsistenceSuccessCount(actorID: context.actorID, strategy: .agriculture)
        return AgentSubsistenceStrategyCandidate(
            strategy: .agriculture, targetKey: "agriculture:managed-local",
            targetPosition: origin, sourceObservationEventID: nil, distance: 0,
            score: 70 + context.subsistencePressure / 10 + min(8, history * 2),
            reason: "managed plot available locally; physical execution remains CIV-22"
        )
    }

    private func subsistenceCandidate(
        strategy: AgentSubsistenceStrategy,
        targetKey: String,
        position: AgentPosition,
        sourceObservationEventID: AgentCausalEventID,
        distance: Int,
        pressure: Int,
        actorID: AgentID,
        baseScore: Int,
        equipmentScore: Int
    ) -> AgentSubsistenceStrategyCandidate {
        let domain: AgentSkillDomain? = strategy == .fishing
            ? .fishing : (strategy == .hunting ? .hunting : (strategy == .wildGathering ? .foraging : nil))
        let practice = domain.map { practiceUnits(agentID: actorID, domain: $0) } ?? 0
        let experience = recentSubsistenceSuccessCount(actorID: actorID, strategy: strategy)
        let score = baseScore + equipmentScore + pressure / 8
            + min(10, practice) + min(8, experience * 2) - distance * 4
        return AgentSubsistenceStrategyCandidate(
            strategy: strategy, targetKey: targetKey, targetPosition: position,
            sourceObservationEventID: sourceObservationEventID, distance: distance,
            score: score,
            reason: "fresh local observation distance=\(distance) equipment=\(equipmentScore > 0 ? "present" : "not-required") practice=\(practice) recent=\(experience)"
        )
    }

    private func recentSubsistenceSuccessCount(
        actorID: AgentID,
        strategy: AgentSubsistenceStrategy
    ) -> Int {
        wildSubsistenceState?.retainedOutcomes.reversed().prefix(16).filter {
            $0.outcome.actorID == actorID && $0.outcome.strategy == strategy
                && $0.outcome.status.isMaterialSuccess
        }.count ?? 0
    }

    private func subsistenceDistance(_ a: AgentPosition, _ b: AgentPosition) -> Int {
        abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z)
    }

    private func subsistencePoint(_ position: AgentPosition) -> String {
        "\(position.x),\(position.y),\(position.z)"
    }

    private func subsistenceCandidateSort(
        _ lhs: AgentSubsistenceStrategyCandidate,
        _ rhs: AgentSubsistenceStrategyCandidate
    ) -> Bool {
        if lhs.score != rhs.score { return lhs.score > rhs.score }
        if lhs.distance != rhs.distance { return lhs.distance < rhs.distance }
        if lhs.strategy != rhs.strategy { return lhs.strategy < rhs.strategy }
        return lhs.targetKey < rhs.targetKey
    }

    private func subsistenceOpportunitySort(
        _ lhs: AgentSubsistenceOpportunity,
        _ rhs: AgentSubsistenceOpportunity
    ) -> Bool {
        if lhs.selectedAtTick != rhs.selectedAtTick { return lhs.selectedAtTick < rhs.selectedAtTick }
        return lhs.opportunityID < rhs.opportunityID
    }

    private func subsistenceOutcomeRecordSort(
        _ lhs: AgentSubsistenceOutcomeRecord,
        _ rhs: AgentSubsistenceOutcomeRecord
    ) -> Bool {
        if lhs.outcome.completedAtTick != rhs.outcome.completedAtTick {
            return lhs.outcome.completedAtTick < rhs.outcome.completedAtTick
        }
        return lhs.outcome.attemptID < rhs.outcome.attemptID
    }

    private func wildSubsistenceDigest(_ state: AgentWildSubsistenceState) -> String {
        let successes = AgentSubsistenceStrategy.allCases.map {
            "\($0.rawValue):\(state.successfulCounts[$0, default: 0])"
        }.joined(separator: ",")
        let canonical = [
            "enabled=1",
            "bounds=\(state.configuration.maximumActiveOpportunities),\(state.configuration.opportunityLifetimeTicks),\(state.configuration.maximumRetainedOutcomes),\(state.configuration.maximumProcessedAttemptIDs),\(state.configuration.maximumAttemptsPerTick)",
            state.opportunities.sorted(by: subsistenceOpportunitySort).map {
                "o|\($0.opportunityID.rawValue)|\($0.actorID.rawValue)|\($0.strategy.rawValue)|\($0.targetKey)|\($0.status.rawValue)|\($0.selectedAtTick)|\($0.expiresAtTick)"
            }.joined(separator: ";"),
            state.retainedOutcomes.sorted(by: subsistenceOutcomeRecordSort).map {
                "r|\($0.outcome.attemptID.rawValue)|\($0.outcome.strategy.rawValue)|\($0.outcome.status.rawValue)|\($0.outcome.acquiredQuantity)|\($0.subsistenceEventID.rawValue)"
            }.joined(separator: ";"),
            "totals=\(state.totalOpportunityCount),\(state.totalAttemptCount)|success=\(successes)",
            "evicted=\(state.evictionCounts.opportunities),\(state.evictionCounts.outcomes),\(state.evictionCounts.processedAttemptIDs)",
            "rolling=\(state.rollingDigest)|events=\(state.initializedEventID.rawValue),\(state.lastSubsistenceEventID.rawValue)",
        ].joined(separator: "|")
        return AgentWildSubsistenceDigest.make(canonical)
    }

    private func evictTerminalOpportunitiesIfNeeded(_ state: inout AgentWildSubsistenceState) {
        let limit = state.configuration.maximumActiveOpportunities * 4
        guard state.opportunities.count > limit else { return }
        var remove = state.opportunities.count - limit
        var retained: [AgentSubsistenceOpportunity] = []
        for opportunity in state.opportunities {
            if remove > 0 && opportunity.status.isTerminal {
                remove -= 1
                state.evictionCounts.opportunities += 1
            } else {
                retained.append(opportunity)
            }
        }
        state.opportunities = retained
    }

    @discardableResult
    private mutating func requiredWildSubsistenceEvent(
        kind: AgentCausalEventKind,
        actorID: AgentID? = nil,
        operationID: AgentOperationID? = nil,
        causes: [AgentCausalEventID] = [],
        payload: AgentCausalPayload,
        summary: String
    ) throws -> AgentCausalEvent {
        guard let event = try recordCausalEvent(
            kind: kind, origin: .wildSubsistenceTransition, actorID: actorID,
            operationID: operationID, causes: causes, payload: payload, summary: summary
        ) else {
            throw AgentWildSubsistenceError.causalLedgerRequired
        }
        return event
    }

    private func wildSubsistencePayload(
        opportunityID: AgentSubsistenceOpportunityID? = nil,
        attemptID: AgentSubsistenceAttemptID? = nil,
        strategy: AgentSubsistenceStrategy?,
        targetKey: String? = nil,
        status: String,
        quantity: Int,
        digest: String
    ) -> AgentCausalPayload {
        .wildSubsistence(
            opportunityID: opportunityID?.rawValue,
            attemptID: attemptID?.rawValue,
            strategy: strategy?.rawValue,
            targetKey: targetKey,
            status: status,
            quantity: quantity,
            digest: digest
        )
    }
}
