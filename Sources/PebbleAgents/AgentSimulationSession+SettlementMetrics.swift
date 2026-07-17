extension AgentSimulationSession {
    public var settlementMetricsEnabled: Bool { settlementMetricsState != nil }

    public mutating func setSettlementMetricsEnabled(
        _ enabled: Bool,
        configuration: AgentSettlementMetricsConfiguration = .live
    ) throws {
        if enabled {
            guard settlementMetricsState == nil else {
                throw AgentSessionError.settlementMetrics(.alreadyEnabled)
            }
            guard let registry = populationRegistry else {
                throw AgentSessionError.settlementMetrics(.populationRequired)
            }
            guard causalLedger.isEnabled else {
                throw AgentSessionError.settlementMetrics(.causalLedgerRequired)
            }
            guard configuration.maximumAgentClassifications
                    >= registry.configuration.maximumActivePopulation else {
                throw AgentSessionError.settlementMetrics(
                    .invalidConfiguration("agent classifications below population capacity")
                )
            }
            guard tick <= Int.max - configuration.macroIntervalTicks else {
                throw AgentSessionError.settlementMetrics(.invalidBaseline("next pulse overflow"))
            }
            try prevalidateCausalAppend(count: 1)
            guard let event = try recordCausalEvent(
                kind: .settlementMetricsInitialized,
                origin: .settlementTransition,
                payload: settlementMetricsPayload(
                    status: "initialized",
                    settlementID: registry.settlement.settlementID,
                    macroSequence: .zero,
                    fromTick: tick,
                    toTick: tick,
                    coverageComplete: true
                ),
                summary: "settlement metrics initialized settlement=\(registry.settlement.settlementID.rawValue)"
            ) else {
                throw AgentSessionError.settlementMetrics(.causalLedgerRequired)
            }
            settlementMetricsState = AgentSettlementMetricsState(
                configuration: configuration,
                settlementID: registry.settlement.settlementID,
                macroSequence: .zero,
                lastPulseTick: tick,
                nextPulseTick: tick + configuration.macroIntervalTicks,
                baseline: settlementMetricsBaseline(causalSequence: event.sequence.rawValue),
                frames: [],
                evictionCounts: AgentSettlementMetricsEvictionCounts(),
                initializedEventID: event.eventID,
                lastSettlementEventID: event.eventID
            )
            return
        }

        guard let state = settlementMetricsState else {
            throw AgentSessionError.settlementMetrics(.disabled)
        }
        try prevalidateCausalAppend(count: 1)
        _ = try requiredSettlementMetricsEvent(
            kind: .settlementMetricsDisabled,
            state: state,
            status: "disabled",
            frame: state.frames.last,
            summary: "settlement metrics disabled settlement=\(state.settlementID.rawValue)"
        )
        settlementMetricsState = nil
    }

    public mutating func clearSettlementMetrics() throws {
        guard var state = settlementMetricsState else {
            throw AgentSessionError.settlementMetrics(.disabled)
        }
        try prevalidateCausalAppend(count: 1)
        let event = try requiredSettlementMetricsEvent(
            kind: .settlementMetricsCleared,
            state: state,
            status: "cleared",
            frame: state.frames.last,
            summary: "settlement metrics cleared settlement=\(state.settlementID.rawValue)"
        )
        guard tick <= Int.max - state.configuration.macroIntervalTicks else {
            throw AgentSessionError.settlementMetrics(.invalidBaseline("next pulse overflow"))
        }
        state.lastPulseTick = tick
        state.nextPulseTick = tick + state.configuration.macroIntervalTicks
        state.baseline = settlementMetricsBaseline(causalSequence: event.sequence.rawValue)
        state.frames = []
        state.evictionCounts = AgentSettlementMetricsEvictionCounts()
        state.lastSettlementEventID = event.eventID
        settlementMetricsState = state
    }

    @discardableResult
    public mutating func applySettlementMetricsPulseIfDue()
        throws -> AgentSettlementMetricFrame?
    {
        guard var state = settlementMetricsState else { return nil }
        guard tick >= state.nextPulseTick else { return nil }
        guard tick == state.nextPulseTick else {
            throw AgentSessionError.settlementMetrics(
                .invalidPulseBoundary(expected: state.nextPulseTick, actual: tick)
            )
        }
        guard state.macroSequence.rawValue < UInt64.max,
              let nextSequence = AgentSettlementMacroSequence(
                  rawValue: state.macroSequence.rawValue + 1
              ) else {
            throw AgentSessionError.settlementMetrics(.macroSequenceOverflow)
        }
        try prevalidateCausalAppend(count: 1)
        let frame = try makeSettlementMetricFrame(
            state: state,
            macroSequence: nextSequence
        )
        try validateSettlementMetricFrame(frame, state: state)
        let event = try requiredSettlementMetricsEvent(
            kind: .settlementMacroPulse,
            state: state,
            status: "pulse",
            frame: frame,
            summary: "settlement pulse frame=\(frame.frameID.rawValue) condition=\(frame.condition.rawValue)"
        )
        state.macroSequence = nextSequence
        state.lastPulseTick = tick
        guard tick <= Int.max - state.configuration.macroIntervalTicks else {
            throw AgentSessionError.settlementMetrics(.invalidBaseline("next pulse overflow"))
        }
        state.nextPulseTick = tick + state.configuration.macroIntervalTicks
        state.frames.append(frame)
        if state.frames.count > state.configuration.maximumMetricFrames {
            let removed = state.frames.count - state.configuration.maximumMetricFrames
            state.frames.removeFirst(removed)
            state.evictionCounts.frames += removed
        }
        state.baseline = settlementMetricsBaseline(causalSequence: event.sequence.rawValue)
        state.lastSettlementEventID = event.eventID
        settlementMetricsState = state
        return frame
    }

    public func settlementMetricsSnapshot() -> AgentSettlementMetricsSnapshot {
        guard let state = settlementMetricsState else {
            return AgentSettlementMetricsSnapshot(
                enabled: false,
                tick: tick,
                configuration: nil,
                settlementID: nil,
                macroSequence: .zero,
                lastPulseTick: nil,
                nextPulseTick: nil,
                frames: [],
                evictionCounts: AgentSettlementMetricsEvictionCounts(),
                digest: AgentSettlementMetricsDigest.make("disabled|\(tick)")
            )
        }
        let canonical = [
            "enabled=1",
            "tick=\(tick)",
            "settlement=\(state.settlementID.rawValue)",
            "sequence=\(state.macroSequence.rawValue)",
            "last=\(state.lastPulseTick)",
            "next=\(state.nextPulseTick)",
            "evicted=\(state.evictionCounts.frames)",
            state.frames.map { "\($0.frameID.rawValue):\($0.digest)" }.joined(separator: ","),
        ].joined(separator: "|")
        return AgentSettlementMetricsSnapshot(
            enabled: true,
            tick: tick,
            configuration: state.configuration,
            settlementID: state.settlementID,
            macroSequence: state.macroSequence,
            lastPulseTick: state.lastPulseTick,
            nextPulseTick: state.nextPulseTick,
            frames: state.frames,
            evictionCounts: state.evictionCounts,
            digest: AgentSettlementMetricsDigest.make(canonical)
        )
    }

    public func settlementMetricsSnapshot(
        for agentID: AgentID
    ) -> AgentSettlementAgentMetricsSnapshot {
        let state = settlementMetricsState
        return AgentSettlementAgentMetricsSnapshot(
            enabled: state != nil,
            tick: tick,
            settlementID: state?.settlementID,
            macroSequence: state?.macroSequence ?? .zero,
            classification: state?.frames.last?.activity.classifications.first {
                $0.agentID == agentID
            }
        )
    }

    public func settlementMetricsSummary() -> AgentSettlementMetricsSummary {
        let snapshot = settlementMetricsSnapshot()
        let frame = snapshot.frames.last
        return AgentSettlementMetricsSummary(
            enabled: snapshot.enabled,
            settlementID: snapshot.settlementID,
            microTick: tick,
            macroIntervalTicks: snapshot.configuration?.macroIntervalTicks,
            macroSequence: snapshot.macroSequence.rawValue,
            lastPulseTick: snapshot.lastPulseTick,
            nextPulseTick: snapshot.nextPulseTick,
            retainedFrameCount: snapshot.frames.count,
            evictedFrameCount: snapshot.evictionCounts.frames,
            condition: frame?.condition,
            population: frame?.population.members ?? populationRegistry?.members.count ?? 0,
            capacity: frame?.population.capacity
                ?? populationRegistry?.configuration.maximumActivePopulation ?? 0,
            urgent: frame?.activity.urgentCount ?? 0,
            migrating: frame?.activity.migratingCount ?? 0,
            engaged: frame?.activity.engagedCount ?? 0,
            stable: frame?.activity.stableCount ?? 0,
            movementDelta: frame?.throughput.movementDelta ?? 0,
            materialActivityDelta: frame?.throughput.materialActivityDelta ?? 0,
            socialActivityDelta: frame?.social.eventDelta ?? 0,
            cooperationActivityDelta: frame?.cooperation.eventDelta ?? 0,
            causalCoverageComplete: frame?.causalCoverageComplete,
            digest: snapshot.digest
        )
    }

    func validateSettlementMetricsState(_ state: AgentSettlementMetricsState) throws {
        guard let registry = populationRegistry,
              state.settlementID == registry.settlement.settlementID else {
            throw AgentSessionError.settlementMetrics(.populationRequired)
        }
        _ = try AgentSettlementMetricsConfiguration(
            macroIntervalTicks: state.configuration.macroIntervalTicks,
            maximumMetricFrames: state.configuration.maximumMetricFrames,
            maximumAgentClassifications: state.configuration.maximumAgentClassifications,
            maximumCausalEventsPerWindow: state.configuration.maximumCausalEventsPerWindow,
            fixedPointScale: state.configuration.fixedPointScale
        )
        guard state.configuration.maximumAgentClassifications
                >= registry.configuration.maximumActivePopulation,
              state.lastPulseTick >= 0,
              state.lastPulseTick <= tick,
              state.nextPulseTick == state.lastPulseTick + state.configuration.macroIntervalTicks,
              state.nextPulseTick > tick,
              state.baseline.tick == state.lastPulseTick,
              state.baseline.causalSequence <= causalLedger.latestSequence,
              state.frames.count <= state.configuration.maximumMetricFrames,
              state.evictionCounts.frames >= 0,
              state.initializedEventID.simulationID == simulationID,
              state.lastSettlementEventID.simulationID == simulationID,
              state.initializedEventID.sequence <= state.lastSettlementEventID.sequence,
              state.lastSettlementEventID.sequence.rawValue <= causalLedger.latestSequence else {
            throw AgentSessionError.settlementMetrics(.invalidBaseline("durable state"))
        }
        var priorSequence: UInt64 = 0
        for frame in state.frames {
            try validateSettlementMetricFrame(frame, state: state)
            guard frame.macroSequence.rawValue > priorSequence,
                  frame.macroSequence <= state.macroSequence,
                  frame.toTickInclusive <= state.lastPulseTick else {
                throw AgentSessionError.settlementMetrics(.invalidFrame("history order"))
            }
            priorSequence = frame.macroSequence.rawValue
        }
    }

    private func makeSettlementMetricFrame(
        state: AgentSettlementMetricsState,
        macroSequence: AgentSettlementMacroSequence
    ) throws -> AgentSettlementMetricFrame {
        guard let registry = populationRegistry,
              registry.settlement.settlementID == state.settlementID else {
            throw AgentSessionError.settlementMetrics(.populationRequired)
        }
        guard state.baseline.tick == state.lastPulseTick,
              state.baseline.tick < tick,
              state.baseline.causalSequence <= causalLedger.latestSequence else {
            throw AgentSessionError.settlementMetrics(.invalidBaseline("pulse window"))
        }
        let ledgerEnd = causalLedger.latestSequence
        let sequenceSpan = ledgerEnd - state.baseline.causalSequence
        let firstRequired = state.baseline.causalSequence + 1
        let firstRetained = causalLedger.events.first?.sequence.rawValue
        let causalCoverageComplete = sequenceSpan
                <= UInt64(state.configuration.maximumCausalEventsPerWindow)
            && (sequenceSpan == 0 || (firstRetained ?? UInt64.max) <= firstRequired)
        let windowEvents = causalLedger.events.filter {
            $0.sequence.rawValue > state.baseline.causalSequence
                && $0.sequence.rawValue <= ledgerEnd
                && !$0.kind.isSettlementMetrics
        }
        let countedEvents = causalCoverageComplete ? windowEvents : []
        let classifications = try registry.members.sorted {
            $0.agentID < $1.agentID
        }.map { member -> AgentSettlementAgentClassification in
            guard let agent = statesById[member.agentID.rawValue] else {
                throw AgentSessionError.settlementMetrics(
                    .invalidFrame("missing member \(member.agentID.rawValue)")
                )
            }
            return settlementClassification(agent: agent, member: member)
        }
        let urgent = classifications.filter { $0.tier == .microUrgent }.count
        let migrating = classifications.filter { $0.tier == .microMigrating }.count
        let engaged = classifications.filter { $0.tier == .microEngaged }.count
        let stable = classifications.filter { $0.tier == .macroObservedStable }.count
        let agents = registry.members.sorted { $0.agentID < $1.agentID }.compactMap {
            statesById[$0.agentID.rawValue]
        }
        let scale = state.configuration.fixedPointScale
        let welfare = try AgentSettlementWelfareMetrics(
            hunger: AgentMetricFixedPointDistribution(
                values: try agents.map { try AgentMetricFixedPoint(value: $0.needs.hunger, scale: scale) }
            ),
            fatigue: AgentMetricFixedPointDistribution(
                values: try agents.map { try AgentMetricFixedPoint(value: $0.needs.fatigue, scale: scale) }
            ),
            curiosity: AgentMetricFixedPointDistribution(
                values: try agents.map { try AgentMetricFixedPoint(value: $0.needs.curiosity, scale: scale) }
            ),
            safety: AgentMetricFixedPointDistribution(
                values: try agents.map { try AgentMetricFixedPoint(value: $0.needs.safety, scale: scale) }
            ),
            minimumHealth: agents.map(\.health).min() ?? 0,
            meanHealth: agents.isEmpty ? 0
                : agents.reduce(0) { $0 + $1.health } / agents.count,
            maximumFear: agents.map(\.fear).max() ?? 0,
            hungryCount: agents.filter {
                $0.needs.hunger >= configuration.survivalConfiguration.hungryThreshold
            }.count,
            criticalHungerCount: agents.filter {
                $0.needs.hunger >= configuration.survivalConfiguration.criticalHungerThreshold
            }.count,
            fatiguedCount: agents.filter {
                $0.needs.fatigue >= configuration.survivalConfiguration.fatigueThreshold
            }.count
        )
        let homeDistances = agents.map { manhattanDistance($0.position, $0.homePosition) }
        let anchorDistances = agents.map {
            manhattanDistance($0.position, registry.settlement.anchor)
        }
        let conservation = conservationSnapshot()
        let movementTotal = agents.reduce(0) { $0 + $1.movementCount }
        let distanceTotal = agents.reduce(0) { $0 + $1.totalManhattanDistanceMoved }
        let settledMaterialTotal = conservation.campStockTotal
            + conservation.constructionEscrowTotal + conservation.constructedTotal
        func operationCount(_ kind: AgentCausalEventKind) -> Int {
            countedEvents.filter {
                guard $0.kind == kind,
                      case let .operation(status, _) = $0.payload else { return false }
                return status == "succeeded" || status == "funded"
                    || status == "completed" || status == "restored"
            }.count
        }
        let populationEventDelta = countedEvents.filter { $0.kind.isPopulation }.count
        let admissionDelta = countedEvents.filter { $0.kind == .migrationAdmitted }.count
        let arrivalDelta = countedEvents.filter { $0.kind == .migrationArrived }.count
        let deathDelta = countedEvents.filter { $0.kind == .agentDeathFinalized }.count
        let exitDelta = countedEvents.filter { $0.kind == .populationMemberExited }.count
        let birthDelta = countedEvents.filter { $0.kind == .populationMemberBorn }.count
        let mortalityMetrics = mortalityState.map { mortality in
            AgentSettlementMortalityMetrics(
                deathDelta: deathDelta,
                exitDelta: exitDelta,
                retainedDeathCount: mortality.records.count,
                totalDeathCount: mortality.totalDeathCount,
                terminalResourceQuantity: mortality.unrecoveredAtDeath.totalCount
            )
        }
        let throughput = AgentSettlementThroughputMetrics(
            movementDelta: max(0, movementTotal - state.baseline.movementCount),
            distanceDelta: max(0, distanceTotal - state.baseline.distanceMoved),
            successfulInteractionDelta: operationCount(.interaction),
            harvestedUnitDelta: max(
                0, conservation.harvestedTotal - state.baseline.harvestedUnits
            ),
            deliveryDelta: operationCount(.delivery),
            deliveredUnitDelta: max(
                0, settledMaterialTotal - state.baseline.settledMaterialUnits
            ),
            consumptionDelta: max(
                0, conservation.consumedTotal - state.baseline.consumedUnits
            ),
            constructionPlacementDelta: operationCount(.constructionPlacement),
            constructionCompletionDelta: operationCount(.constructionCompletion)
        )
        let socialSnapshot = socialSnapshot()
        let physicalSnapshot = physicalChannelSnapshot()
        let cooperationSnapshot = cooperationSnapshot()
        let socialMetrics = AgentSettlementSocialMetrics(
            factsRetained: socialSnapshot.facts.count,
            messagesRetained: socialSnapshot.messages.count,
            beliefsRetained: socialSnapshot.beliefs.count,
            trustEdges: socialSnapshot.trustRelations.count,
            eventDelta: countedEvents.filter { $0.kind.isSettlementSocialActivity }.count
        )
        let physicalMetrics = AgentSettlementPhysicalMetrics(
            signalsRetained: physicalSnapshot.signals.count,
            exactCount: physicalSnapshot.perceptions.filter { $0.outcome == .exact }.count,
            ambiguousCount: physicalSnapshot.perceptions.filter {
                $0.outcome == .ambiguous
            }.count,
            missedCount: physicalSnapshot.perceptions.filter { $0.outcome == .missed }.count,
            inconclusiveCount: physicalSnapshot.perceptions.filter {
                $0.outcome == .inconclusive
            }.count,
            eventDelta: countedEvents.filter { $0.kind.isSettlementPhysicalActivity }.count
        )
        let cooperationMetrics = AgentSettlementCooperationMetrics(
            activeTasks: cooperationSnapshot.tasks.filter {
                $0.status == .accepted || $0.status == .active
            }.count,
            completedTasks: cooperationSnapshot.tasks.filter {
                $0.status == .completed
            }.count,
            reliabilityEdges: cooperationSnapshot.relations.count,
            eventDelta: countedEvents.filter { $0.kind.isCooperation }.count
        )
        let activeMigrationCount = registry.migrations.filter {
            $0.status == .admitted || $0.status == .inTransit
        }.count
        let condition: AgentSettlementCondition
        let reason: String
        if !causalCoverageComplete {
            condition = .incomplete
            reason = "causal_window_incomplete"
        } else if urgent > 0 || !conservation.balanced {
            condition = .strained
            reason = urgent > 0 ? "urgent_agents" : "conservation_divergence"
        } else if activeMigrationCount > 0 || admissionDelta > 0 || arrivalDelta > 0
            || deathDelta > 0 || exitDelta > 0 || birthDelta > 0 {
            condition = .transitioning
            reason = activeMigrationCount > 0 ? "migration_active"
                : (birthDelta > 0 ? "local_birth" : "population_changed")
        } else if throughput.movementDelta > 0 || throughput.materialActivityDelta > 0
            || socialMetrics.eventDelta > 0 || physicalMetrics.eventDelta > 0
            || cooperationMetrics.eventDelta > 0 || populationEventDelta > 0 {
            condition = .active
            reason = "accepted_window_activity"
        } else {
            condition = .stable
            reason = "no_collective_activity"
        }
        return AgentSettlementMetricFrame(
            frameID: AgentSettlementMetricFrameID(
                settlementID: state.settlementID,
                macroSequence: macroSequence,
                endTick: tick
            ),
            settlementID: state.settlementID,
            macroSequence: macroSequence,
            fromTickExclusive: state.lastPulseTick,
            toTickInclusive: tick,
            causalSequenceStartExclusive: state.baseline.causalSequence,
            causalSequenceEndInclusive: ledgerEnd,
            causalCoverageComplete: causalCoverageComplete,
            population: AgentSettlementPopulationMetrics(
                capacity: registry.settlement.capacity,
                members: registry.members.count,
                founders: registry.members.filter(\.founder).count,
                residents: registry.members.filter {
                    $0.status == .founderResident || $0.status == .resident
                }.count,
                migrants: registry.members.filter { $0.status == .migrating }.count,
                admissionDelta: admissionDelta,
                arrivalDelta: arrivalDelta
            ),
            activity: AgentSettlementActivityMetrics(
                urgentCount: urgent,
                migratingCount: migrating,
                engagedCount: engaged,
                stableCount: stable,
                classifications: classifications
            ),
            welfare: welfare,
            spatial: AgentSettlementSpatialMetrics(
                agentsAtHome: homeDistances.filter { $0 == 0 }.count,
                agentsAwayFromHome: homeDistances.filter { $0 != 0 }.count,
                totalDistanceFromHome: homeDistances.reduce(0, +),
                maximumDistanceFromHome: homeDistances.max() ?? 0,
                totalDistanceFromAnchor: anchorDistances.reduce(0, +),
                maximumDistanceFromAnchor: anchorDistances.max() ?? 0,
                distinctOccupiedPositions: Set(agents.map(\.position)).count
            ),
            material: AgentSettlementMaterialMetrics(
                campStock: conservation.campStock,
                carried: conservation.carried,
                harvested: conservation.harvested,
                consumed: conservation.consumed,
                constructionEscrow: conservation.constructionEscrow,
                constructed: conservation.constructed,
                conservationBalanced: conservation.balanced,
                unrecoveredAtDeath: mortalityState == nil
                    ? nil : conservation.unrecoveredAtDeath
            ),
            throughput: throughput,
            social: socialMetrics,
            physical: physicalMetrics,
            cooperation: cooperationMetrics,
            populationEventDelta: populationEventDelta,
            mortality: mortalityMetrics,
            condition: condition,
            reasonCode: reason
        )
    }

    private func settlementClassification(
        agent: AgentSessionAgentState,
        member: AgentPopulationMemberRecord
    ) -> AgentSettlementAgentClassification {
        let urgentReason: String?
        if agent.currentGoal.kind == .satisfyHunger
            || agent.needs.hunger >= configuration.survivalConfiguration.criticalHungerThreshold {
            urgentReason = "hunger"
        } else if agent.currentGoal.kind == .seekSafety || agent.needs.safety < 0.5 {
            urgentReason = "safety"
        } else if agent.health <= 25 {
            urgentReason = "health"
        } else if agent.fear >= 70 {
            urgentReason = "fear"
        } else if agent.currentGoal.kind == .rest {
            urgentReason = "rest"
        } else {
            urgentReason = nil
        }
        if let urgentReason {
            return AgentSettlementAgentClassification(
                agentID: agent.agentID,
                tier: .microUrgent,
                reason: urgentReason
            )
        }
        if member.status == .migrating || isMigratingAgent(agent.id) {
            return AgentSettlementAgentClassification(
                agentID: agent.agentID,
                tier: .microMigrating,
                reason: "migration"
            )
        }
        let hasTask = sharedTasks.contains {
            ($0.issuerID == agent.agentID || $0.helperID == agent.agentID)
                && !$0.status.isTerminal
        }
        let hasSocialVerification = activeSocialVerificationByAgentId[agent.id] != nil
        let hasPendingSignal = physicalSignals.contains {
            $0.status == .pending
                && ($0.senderID == agent.agentID || $0.intendedRecipientID == agent.agentID)
        }
        let constructionActive = constructionProject?.isActive == true
            && constructionProject?.builderAgentId == agent.id
        let engaged = agent.currentGoal.kind != .idle
            || agent.navigationProgress.status == .active
            || agent.activeResourceTarget != nil
            || reservationsByTarget.values.contains { $0.agentId == agent.id }
            || !agent.resourceInventory.isEmpty
            || constructionActive || hasTask || hasSocialVerification || hasPendingSignal
        let stableAction = agent.lastAction == nil || agent.lastAction?.name == "wait"
        let stable = member.status != .migrating
            && agent.currentGoal.kind == .idle
            && stableAction
            && agent.position == agent.homePosition
            && agent.resourceInventory.isEmpty
            && agent.navigationProgress.status != .active
            && agent.navigationProgress.route == nil
            && agent.activeResourceTarget == nil
            && !reservationsByTarget.values.contains { $0.agentId == agent.id }
            && !hasTask && !hasSocialVerification && !hasPendingSignal && !constructionActive
        return AgentSettlementAgentClassification(
            agentID: agent.agentID,
            tier: stable && !engaged ? .macroObservedStable : .microEngaged,
            reason: stable && !engaged ? "idle_at_home" : "micro_commitment"
        )
    }

    private func settlementMetricsBaseline(
        causalSequence: UInt64
    ) -> AgentSettlementMetricBaseline {
        let conservation = conservationSnapshot()
        return AgentSettlementMetricBaseline(
            tick: tick,
            causalSequence: causalSequence,
            movementCount: statesById.values.reduce(0) { $0 + $1.movementCount },
            distanceMoved: statesById.values.reduce(0) {
                $0 + $1.totalManhattanDistanceMoved
            },
            harvestedUnits: conservation.harvestedTotal,
            consumedUnits: conservation.consumedTotal,
            settledMaterialUnits: conservation.campStockTotal
                + conservation.constructionEscrowTotal + conservation.constructedTotal,
            mortalityDeathCount: mortalityState?.totalDeathCount
        )
    }

    private func validateSettlementMetricFrame(
        _ frame: AgentSettlementMetricFrame,
        state: AgentSettlementMetricsState
    ) throws {
        let expectedID = AgentSettlementMetricFrameID(
            settlementID: state.settlementID,
            macroSequence: frame.macroSequence,
            endTick: frame.toTickInclusive
        )
        let classifications = frame.activity.classifications
        guard frame.frameID == expectedID,
              frame.settlementID == state.settlementID,
              frame.fromTickExclusive < frame.toTickInclusive,
              frame.toTickInclusive - frame.fromTickExclusive
                == state.configuration.macroIntervalTicks,
              frame.causalSequenceStartExclusive <= frame.causalSequenceEndInclusive,
              classifications.count == frame.population.members,
              classifications.count <= state.configuration.maximumAgentClassifications,
              classifications.map(\.agentID) == classifications.map(\.agentID).sorted(),
              Set(classifications.map(\.agentID)).count == classifications.count,
              frame.activity.urgentCount + frame.activity.migratingCount
                + frame.activity.engagedCount + frame.activity.stableCount
                == frame.population.members,
              frame.population.members >= 0,
              frame.population.residents + frame.population.migrants
                == frame.population.members,
              frame.reasonCode.count <= 64 else {
            throw AgentSessionError.settlementMetrics(.invalidFrame("contract"))
        }
    }

    private mutating func requiredSettlementMetricsEvent(
        kind: AgentCausalEventKind,
        state: AgentSettlementMetricsState,
        status: String,
        frame: AgentSettlementMetricFrame?,
        summary: String
    ) throws -> AgentCausalEvent {
        let prior = causalLedger.events.last?.eventID
        let causes = Array(Set([prior, state.lastSettlementEventID].compactMap { $0 })).sorted()
        guard let event = try recordCausalEvent(
            kind: kind,
            origin: .settlementTransition,
            causes: Array(causes.prefix(AgentCausalEvent.maximumCauseCount)),
            payload: settlementMetricsPayload(
                status: status,
                settlementID: state.settlementID,
                macroSequence: frame?.macroSequence ?? state.macroSequence,
                fromTick: frame?.fromTickExclusive ?? state.lastPulseTick,
                toTick: frame?.toTickInclusive ?? tick,
                coverageComplete: frame?.causalCoverageComplete ?? true,
                frame: frame
            ),
            summary: summary
        ) else {
            throw AgentSessionError.settlementMetrics(.causalLedgerRequired)
        }
        return event
    }

    private func settlementMetricsPayload(
        status: String,
        settlementID: AgentSettlementID,
        macroSequence: AgentSettlementMacroSequence,
        fromTick: Int,
        toTick: Int,
        coverageComplete: Bool,
        frame: AgentSettlementMetricFrame? = nil
    ) -> AgentCausalPayload {
        .settlementMetrics(
            frameID: frame?.frameID.rawValue,
            settlementID: settlementID.rawValue,
            macroSequence: macroSequence.rawValue,
            fromTickExclusive: fromTick,
            toTickInclusive: toTick,
            condition: frame?.condition.rawValue ?? "none",
            population: frame?.population.members ?? populationRegistry?.members.count ?? 0,
            urgent: frame?.activity.urgentCount ?? 0,
            migrating: frame?.activity.migratingCount ?? 0,
            engaged: frame?.activity.engagedCount ?? 0,
            stable: frame?.activity.stableCount ?? 0,
            movementDelta: frame?.throughput.movementDelta ?? 0,
            materialActivityDelta: frame?.throughput.materialActivityDelta ?? 0,
            socialActivityDelta: frame?.social.eventDelta ?? 0,
            cooperationActivityDelta: frame?.cooperation.eventDelta ?? 0,
            coverageComplete: coverageComplete,
            status: status
        )
    }
}

extension AgentCausalEventKind {
    var isSettlementMetrics: Bool {
        switch self {
        case .settlementMetricsInitialized, .settlementMacroPulse,
             .settlementMetricsCleared, .settlementMetricsDisabled:
            return true
        default:
            return false
        }
    }

    var isSettlementSocialActivity: Bool {
        switch self {
        case .resourceFactGrounded, .socialMessageSent, .socialMessageReceived,
             .socialBeliefChanged, .socialVerification, .trustChanged,
             .socialStateCleared:
            return true
        default:
            return false
        }
    }

    var isSettlementPhysicalActivity: Bool {
        switch self {
        case .physicalSignalEmitted, .physicalSignalPerceived,
             .physicalSignalDecoded, .physicalSignalExpired, .physicalStateCleared:
            return true
        default:
            return false
        }
    }
}
