import Foundation

extension AgentSimulationSession {
    public var lifecycleEnabled: Bool { lifecycleState != nil }
    public var reproductionEnabled: Bool { lifecycleState?.reproductionEnabled == true }

    public func lifecycleSnapshot() -> AgentLifecycleSnapshot {
        guard let lifecycle = lifecycleState else {
            return AgentLifecycleSnapshot(
                enabled: false,
                reproductionEnabled: false,
                members: [],
                plans: [],
                births: [],
                frames: [],
                totalBirthCount: 0,
                evictionCounts: AgentLifecycleEvictionCounts(),
                digest: AgentLifecycleDigest.make("disabled")
            )
        }
        let members = lifecycle.members.sorted { $0.agentID < $1.agentID }
        let plans = lifecycle.plans.sorted { $0.planID < $1.planID }
        let births = lifecycle.births.sorted {
            if $0.birthTick != $1.birthTick { return $0.birthTick < $1.birthTick }
            return $0.birthID < $1.birthID
        }
        let canonical = [
            "settlement=\(lifecycle.settlementID.rawValue)",
            "reproduction=\(lifecycle.reproductionEnabled ? 1 : 0)",
            members.map { member in
                let age = (try? member.age(at: tick)) ?? -1
                return "m|\(member.agentID.rawValue)|\(member.ordinal.rawValue)|\(member.origin.rawValue)|\(age)|\(member.currentStage.rawValue)|\(member.progenitorIDs.map(\.rawValue).joined(separator: ","))|\(member.completedBirthCount)|\(member.lastCompletedBirthTick.map(String.init) ?? "none")"
            }.joined(separator: ";"),
            plans.map {
                "p|\($0.planID.rawValue)|\($0.progenitorIDs.map(\.rawValue).joined(separator: ","))|\($0.createdTick)|\($0.dueTick)|\($0.populationAtPlanning)|\($0.pressureAtPlanning.rawValue)|\($0.status.rawValue)|\($0.reason?.rawValue ?? "none")"
            }.joined(separator: ";"),
            births.map {
                "b|\($0.birthID.rawValue)|\($0.newbornID.rawValue)|\($0.ordinal.rawValue)|\($0.birthTick)|\($0.progenitorIDs.map(\.rawValue).joined(separator: ","))|\($0.position.x),\($0.position.y),\($0.position.z)|\($0.worldFingerprint)"
            }.joined(separator: ";"),
            "total=\(lifecycle.totalBirthCount)|rolling=\(lifecycle.rollingDigest)",
            "evictions=\(lifecycle.evictionCounts.births),\(lifecycle.evictionCounts.plans),\(lifecycle.evictionCounts.frames)",
        ].joined(separator: "|")
        return AgentLifecycleSnapshot(
            enabled: true,
            reproductionEnabled: lifecycle.reproductionEnabled,
            members: members,
            plans: plans,
            births: births,
            frames: lifecycle.frames,
            totalBirthCount: lifecycle.totalBirthCount,
            evictionCounts: lifecycle.evictionCounts,
            digest: AgentLifecycleDigest.make(canonical)
        )
    }

    public func lifecycleSummary() -> AgentLifecycleSummary {
        let snapshot = lifecycleSnapshot()
        let latest = snapshot.births.last
        return AgentLifecycleSummary(
            enabled: snapshot.enabled,
            reproductionEnabled: snapshot.reproductionEnabled,
            newbornCount: snapshot.members.filter { $0.currentStage == .newborn }.count,
            juvenileCount: snapshot.members.filter { $0.currentStage == .juvenile }.count,
            matureCount: snapshot.members.filter { $0.currentStage == .mature }.count,
            activePlanCount: snapshot.plans.filter { !$0.status.isTerminal }.count,
            retainedBirthCount: snapshot.births.count,
            totalBirthCount: snapshot.totalBirthCount,
            latestBirthID: latest?.birthID,
            latestNewbornID: latest?.newbornID,
            digest: snapshot.digest
        )
    }

    public func reproductionSnapshot() -> AgentReproductionSnapshot {
        guard let lifecycle = lifecycleState, let registry = populationRegistry else {
            return AgentReproductionSnapshot(
                enabled: false,
                eligibleMatureResidentIDs: [],
                eligiblePairs: [],
                activePlans: [],
                populationCount: 0,
                populationCapacity: 0,
                pressure: nil,
                accessibleFood: 0,
                lastCancellationReason: nil,
                digest: AgentLifecycleDigest.make("reproduction-disabled")
            )
        }
        let eligibility = reproductionEligibility(
            lifecycle: lifecycle, registry: registry, evaluationTick: tick
        )
        let active = lifecycle.plans.filter { $0.status == .planned }.sorted {
            $0.planID < $1.planID
        }
        let lastCancellation = lifecycle.plans.reversed().first {
            $0.status == .cancelled || $0.status == .failed
        }?.reason
        let canonical = [
            "enabled=\(lifecycle.reproductionEnabled ? 1 : 0)",
            "residents=\(eligibility.candidates.map(\.agentID.rawValue).joined(separator: ","))",
            "pairs=\(eligibility.pairs.map { $0.map(\.agentID.rawValue).joined(separator: "+") }.joined(separator: ","))",
            "plans=\(active.map(\.planID.rawValue).joined(separator: ","))",
            "population=\(registry.members.count)/\(registry.configuration.maximumActivePopulation)",
            "pressure=\(eligibility.pressure?.rawValue ?? "none")",
            "food=\(eligibility.accessibleFood)",
            "last=\(lastCancellation?.rawValue ?? "none")",
        ].joined(separator: "|")
        return AgentReproductionSnapshot(
            enabled: lifecycle.reproductionEnabled,
            eligibleMatureResidentIDs: eligibility.candidates.map(\.agentID),
            eligiblePairs: eligibility.pairs.map { $0.map(\.agentID) },
            activePlans: active,
            populationCount: registry.members.count,
            populationCapacity: registry.configuration.maximumActivePopulation,
            pressure: eligibility.pressure,
            accessibleFood: eligibility.accessibleFood,
            lastCancellationReason: lastCancellation,
            digest: AgentLifecycleDigest.make(canonical)
        )
    }

    public func birthsSnapshot() -> [AgentBirthRecord] {
        lifecycleSnapshot().births
    }

    public func demographicAge(for agentID: AgentID) throws -> Int {
        guard let member = lifecycleState?.members.first(where: { $0.agentID == agentID }) else {
            throw AgentSessionError.lifecycle(.invalidMember(agentID.rawValue))
        }
        return try member.age(at: tick)
    }

    public func pendingBirthSitePlan() -> AgentReproductionPlan? {
        lifecycleState?.plans.first {
            $0.status == .planned && $0.dueTick <= tick
        }
    }

    public mutating func setLifecycleEnabled(
        _ enabled: Bool,
        configuration: AgentLifecycleConfiguration = .live
    ) throws {
        if enabled {
            var candidate = self
            try candidate.initializeLifecycleInPlace(configuration: configuration)
            self = candidate
        } else if lifecycleState != nil {
            throw AgentSessionError.lifecycle(.unsafeDisable)
        }
    }

    private mutating func initializeLifecycleInPlace(
        configuration: AgentLifecycleConfiguration
    ) throws {
        guard causalLedger.isEnabled else {
            throw AgentSessionError.lifecycle(.causalLedgerRequired)
        }
        guard lifecycleState == nil else {
            throw AgentSessionError.lifecycle(.alreadyEnabled)
        }
        guard let registry = populationRegistry else {
            throw AgentSessionError.lifecycle(.populationRequired)
        }
        let activeIDs = statesById.values.map(\.agentID).sorted()
        guard activeIDs == registry.members.map(\.agentID).sorted(),
              registry.settlement.capacity == registry.configuration.maximumActivePopulation,
              Set(registry.settlement.residentIDs + registry.settlement.inTransitIDs)
                == Set(activeIDs) else {
            throw AgentSessionError.lifecycle(.settlementRequired)
        }
        try prevalidateCausalAppend(count: activeIDs.count + 1)
        let initialized = try requiredLifecycleEvent(
            kind: .lifecycleInitialized,
            payload: .lifecycleMember(
                memberID: nil, ordinal: nil, origin: nil, stage: nil, age: nil,
                status: "initialized"
            ),
            summary: "lifecycle initialized members=\(activeIDs.count)"
        )
        var members: [AgentLifecycleMember] = []
        var latest = initialized.eventID
        for populationMember in registry.members.sorted(by: { $0.agentID < $1.agentID }) {
            let origin: AgentLifecycleOrigin = populationMember.founder
                ? .bootstrapResident : .importedMigrant
            let event = try requiredLifecycleEvent(
                kind: .lifecycleMemberRegistered,
                actorID: populationMember.agentID,
                subjectID: populationMember.agentID,
                causes: [initialized.eventID],
                payload: .lifecycleMember(
                    memberID: populationMember.agentID.rawValue,
                    ordinal: populationMember.ordinal.rawValue,
                    origin: origin.rawValue,
                    stage: AgentLifeStage.mature.rawValue,
                    age: configuration.maturityAgeTicks,
                    status: "registered"
                ),
                summary: "lifecycle member registered id=\(populationMember.agentID.rawValue) mature=1"
            )
            latest = event.eventID
            members.append(AgentLifecycleMember(
                agentID: populationMember.agentID,
                ordinal: populationMember.ordinal,
                settlementID: registry.settlement.settlementID,
                origin: origin,
                lifecycleRegisteredTick: tick,
                initialAgeTicks: configuration.maturityAgeTicks,
                currentStage: .mature,
                lastStageTransitionTick: tick,
                progenitorIDs: [],
                birthID: nil,
                lastCompletedBirthTick: nil,
                completedBirthCount: 0,
                registrationEventID: event.eventID,
                lastLifecycleEventID: event.eventID
            ))
        }
        lifecycleState = AgentLifecycleState(
            configuration: configuration,
            settlementID: registry.settlement.settlementID,
            reproductionEnabled: false,
            members: members,
            plans: [],
            births: [],
            frames: [],
            totalBirthCount: 0,
            rollingDigest: AgentLifecycleDigest.make("initialized|\(tick)|\(activeIDs.count)"),
            evictionCounts: AgentLifecycleEvictionCounts(),
            initializedEventID: initialized.eventID,
            lastLifecycleEventID: latest
        )
    }

    public mutating func setReproductionEnabled(_ enabled: Bool) throws {
        var candidate = self
        try candidate.setReproductionEnabledInPlace(enabled)
        self = candidate
    }

    private mutating func setReproductionEnabledInPlace(_ enabled: Bool) throws {
        guard var lifecycle = lifecycleState else {
            throw AgentSessionError.lifecycle(.disabled)
        }
        guard lifecycle.reproductionEnabled != enabled else { return }
        let activePlanCount = lifecycle.plans.filter { $0.status == .planned }.count
        try prevalidateCausalAppend(count: enabled ? 1 : activePlanCount + 1)
        if !enabled {
            for index in lifecycle.plans.indices where lifecycle.plans[index].status == .planned {
                let plan = lifecycle.plans[index]
                let cancelled = try requiredLifecycleEvent(
                    kind: .reproductionPlanCancelled,
                    causes: [plan.createdEventID],
                    payload: reproductionPlanPayload(
                        plan, status: .cancelled, reason: .reproductionDisabled
                    ),
                    summary: "reproduction plan cancelled id=\(plan.planID.rawValue) reason=reproductionDisabled"
                )
                lifecycle.plans[index].status = .cancelled
                lifecycle.plans[index].reason = .reproductionDisabled
                lifecycle.plans[index].resolvedTick = tick
                lifecycle.plans[index].terminalEventID = cancelled.eventID
                lifecycle.lastLifecycleEventID = cancelled.eventID
            }
        }
        let event = try requiredLifecycleEvent(
            kind: enabled ? .reproductionEnabled : .reproductionDisabled,
            causes: [lifecycle.lastLifecycleEventID],
            payload: .reproductionPlan(
                planID: nil, progenitorIDs: [], createdTick: nil, dueTick: nil,
                status: enabled ? "enabled" : "disabled", reason: nil
            ),
            summary: "reproduction \(enabled ? "enabled" : "disabled")"
        )
        lifecycle.reproductionEnabled = enabled
        lifecycle.lastLifecycleEventID = event.eventID
        lifecycleState = lifecycle
    }

    mutating func applyLifecycleStageBoundary(at lifecycleTick: Int) throws {
        guard var lifecycle = lifecycleState else { return }
        let transitions = try lifecycle.members.indices.compactMap { index -> (Int, AgentLifeStage, Int)? in
            guard statesById[lifecycle.members[index].agentID.rawValue] != nil else { return nil }
            let age = try lifecycle.members[index].age(at: lifecycleTick)
            let stage = lifeStage(age: age, configuration: lifecycle.configuration)
            return stage == lifecycle.members[index].currentStage ? nil : (index, stage, age)
        }.sorted { lifecycle.members[$0.0].agentID < lifecycle.members[$1.0].agentID }
        try prevalidateCausalAppend(count: transitions.count)
        for (index, stage, age) in transitions {
            let member = lifecycle.members[index]
            let event = try requiredLifecycleEvent(
                kind: .lifeStageChanged,
                actorID: member.agentID,
                subjectID: member.agentID,
                causes: [member.lastLifecycleEventID],
                payload: .lifecycleMember(
                    memberID: member.agentID.rawValue,
                    ordinal: member.ordinal.rawValue,
                    origin: member.origin.rawValue,
                    stage: stage.rawValue,
                    age: age,
                    status: "stageChanged"
                ),
                summary: "life stage changed id=\(member.agentID.rawValue) \(member.currentStage.rawValue)>\(stage.rawValue) age=\(age)"
            )
            lifecycle.members[index].currentStage = stage
            lifecycle.members[index].lastStageTransitionTick = lifecycleTick
            lifecycle.members[index].lastLifecycleEventID = event.eventID
            lifecycle.lastLifecycleEventID = event.eventID
        }
        lifecycleState = lifecycle
    }

    mutating func evaluateReproductionPlanIfDue(at evaluationTick: Int) throws {
        guard var lifecycle = lifecycleState, lifecycle.reproductionEnabled,
              lifecycle.plans.allSatisfy({ $0.status != .planned }),
              evaluationTick % lifecycle.configuration.reproductionEvaluationIntervalTicks == 0,
              lifecycle.births.last.map({
                  evaluationTick - $0.birthTick
                    >= lifecycle.configuration.reproductionCooldownTicks
              }) ?? true,
              let registry = populationRegistry,
              registry.members.count < registry.configuration.maximumActivePopulation,
              let ecology = localEcologyState,
              ecology.currentPressure == .abundant || ecology.currentPressure == .adequate else {
            return
        }
        let eligibility = reproductionEligibility(
            lifecycle: lifecycle, registry: registry, evaluationTick: evaluationTick
        )
        guard eligibility.accessibleFood > 0,
              let pair = eligibility.pairs.first else { return }
        let planningPressure = ecology.currentPressure!
        let progenitors = pair.map(\.agentID).sorted()
        let planID = AgentReproductionPlanID(
            rawValue: "reproduction-plan-\(String(format: "%08d", evaluationTick))-\(progenitors[0].rawValue)-\(progenitors[1].rawValue)"
        )!
        let dueTick = evaluationTick + lifecycle.configuration.reproductionPlanDelayTicks
        let event = try requiredLifecycleEvent(
            kind: .reproductionPlanCreated,
            actorID: progenitors[0],
            subjectID: progenitors[1],
            causes: Array(Set(progenitors.compactMap { id in
                lifecycle.members.first { $0.agentID == id }?.lastLifecycleEventID
            })).sorted(),
            payload: .reproductionPlan(
                planID: planID.rawValue,
                progenitorIDs: progenitors.map(\.rawValue),
                createdTick: evaluationTick,
                dueTick: dueTick,
                status: AgentReproductionPlanStatus.planned.rawValue,
                reason: nil
            ),
            summary: "reproduction plan created id=\(planID.rawValue) due=\(dueTick)"
        )
        lifecycle.plans.append(AgentReproductionPlan(
            planID: planID,
            settlementID: lifecycle.settlementID,
            progenitorIDs: progenitors,
            createdTick: evaluationTick,
            dueTick: dueTick,
            populationAtPlanning: registry.members.count,
            pressureAtPlanning: planningPressure,
            resolvedTick: nil,
            status: .planned,
            reason: nil,
            createdEventID: event.eventID,
            terminalEventID: nil
        ))
        lifecycle.lastLifecycleEventID = event.eventID
        lifecycleState = lifecycle
    }

    public mutating func applyBirthSiteObservation(
        _ observation: AgentBirthSiteObservation
    ) throws -> AgentBirthRecord? {
        var candidate = self
        let record = try candidate.applyBirthSiteObservationInPlace(observation)
        self = candidate
        return record
    }

    private mutating func applyBirthSiteObservationInPlace(
        _ observation: AgentBirthSiteObservation
    ) throws -> AgentBirthRecord? {
        guard var lifecycle = lifecycleState else {
            throw AgentSessionError.lifecycle(.disabled)
        }
        guard lifecycle.reproductionEnabled else {
            throw AgentSessionError.lifecycle(.reproductionDisabled)
        }
        guard let planIndex = lifecycle.plans.firstIndex(where: {
            $0.planID == observation.planID && $0.status == .planned
        }) else {
            throw AgentSessionError.lifecycle(.invalidPlan(observation.planID.rawValue))
        }
        let plan = lifecycle.plans[planIndex]
        let accessibleFood = localEcologySummary().currentYield
            + statesById.values.reduce(0) {
                $0 + $1.resourceInventory.count(of: .foodRaw)
            } + campStock.count(of: .foodRaw)
        guard observation.observedTick == tick, tick >= plan.dueTick,
              observation.settlementID == plan.settlementID,
              observation.candidateIndex >= 0,
              observation.candidateIndex < lifecycle.configuration.maximumBirthSiteCandidates,
              (1...lifecycle.configuration.maximumBirthSiteCandidates)
                .contains(observation.candidatesConsidered),
              (1...lifecycle.configuration.maximumBirthSiteWorldReads)
                .contains(observation.worldReads) else {
            throw AgentSessionError.lifecycle(.invalidObservation(observation.planID.rawValue))
        }
        guard observation.isValid else {
            let cancelled = try requiredLifecycleEvent(
                kind: .reproductionPlanCancelled,
                causes: [plan.createdEventID],
                payload: reproductionPlanPayload(
                    plan, status: .failed, reason: .birthSiteUnavailable
                ),
                summary: "reproduction plan failed id=\(plan.planID.rawValue) reason=birthSiteUnavailable"
            )
            lifecycle.plans[planIndex].status = .failed
            lifecycle.plans[planIndex].reason = .birthSiteUnavailable
            lifecycle.plans[planIndex].resolvedTick = tick
            lifecycle.plans[planIndex].terminalEventID = cancelled.eventID
            lifecycle.lastLifecycleEventID = cancelled.eventID
            lifecycleState = lifecycle
            return nil
        }
        guard var registry = populationRegistry else {
            throw AgentSessionError.lifecycle(.populationRequired)
        }
        guard registry.members.count < registry.configuration.maximumActivePopulation else {
            try cancelReproductionPlan(
                &lifecycle, index: planIndex, plan: plan,
                reason: .populationFull, status: .cancelled
            )
            lifecycleState = lifecycle
            return nil
        }
        let criticalHunger = configuration.survivalConfiguration.criticalHungerThreshold
        let parentsEligible = plan.progenitorIDs.count == 2
            && plan.progenitorIDs == plan.progenitorIDs.sorted()
            && Set(plan.progenitorIDs).count == 2
            && plan.progenitorIDs.allSatisfy { id in
                guard registry.settlement.residentIDs.contains(id),
                      let state = statesById[id.rawValue], state.health > 0,
                      state.needs.hunger < criticalHunger,
                      let member = lifecycle.members.first(where: { $0.agentID == id }),
                      member.currentStage == .mature,
                      member.completedBirthCount
                        < lifecycle.configuration.maximumParentBirthCount else { return false }
                return member.lastCompletedBirthTick.map {
                    tick - $0 >= lifecycle.configuration.reproductionCooldownTicks
                } ?? true
            }
        guard parentsEligible,
              let firstParent = lifecycle.members.first(where: {
                  $0.agentID == plan.progenitorIDs[0]
              }),
              let secondParent = lifecycle.members.first(where: {
                  $0.agentID == plan.progenitorIDs[1]
              }),
              areUnrelated(firstParent, secondParent) else {
            try cancelReproductionPlan(
                &lifecycle, index: planIndex, plan: plan,
                reason: .parentIneligible, status: .cancelled
            )
            lifecycleState = lifecycle
            return nil
        }
        guard localEcologyState?.currentPressure == .abundant
                || localEcologyState?.currentPressure == .adequate,
              accessibleFood > 0 else {
            try cancelReproductionPlan(
                &lifecycle, index: planIndex, plan: plan,
                reason: .subsistenceUnavailable, status: .cancelled
            )
            lifecycleState = lifecycle
            return nil
        }
        guard plan.progenitorIDs.count == 2,
              plan.progenitorIDs == plan.progenitorIDs.sorted(),
              Set(plan.progenitorIDs).count == 2,
              parentsEligible else {
            throw AgentSessionError.lifecycle(.invalidPlan(plan.planID.rawValue))
        }
        let ordinal = registry.nextPopulationOrdinal
        guard ordinal.rawValue < Int.max,
              let nextOrdinal = AgentPopulationOrdinal(rawValue: ordinal.rawValue + 1),
              let newbornID = AgentID(rawValue: "agent_\(ordinal.rawValue)"),
              statesById[newbornID.rawValue] == nil,
              !lifecycle.members.contains(where: { $0.agentID == newbornID }) else {
            throw AgentSessionError.lifecycle(.ordinalOverflow)
        }
        let birthID = AgentBirthID(
            rawValue: "birth-\(String(format: "%08d", lifecycle.totalBirthCount + 1))"
        )!
        try prevalidateCausalAppend(count: 3)
        let site = try requiredLifecycleEvent(
            kind: .birthSiteValidated,
            actorID: plan.progenitorIDs[0],
            subjectID: newbornID,
            causes: [plan.createdEventID],
            payload: birthPayload(
                birthID: birthID, plan: plan, newbornID: newbornID,
                ordinal: ordinal, observation: observation, status: "siteValidated"
            ),
            summary: "birth site validated plan=\(plan.planID.rawValue) position=\(positionText(observation.position))"
        )
        let born = try requiredLifecycleEvent(
            kind: .populationMemberBorn,
            actorID: plan.progenitorIDs[0],
            subjectID: newbornID,
            causes: [site.eventID],
            payload: birthPayload(
                birthID: birthID, plan: plan, newbornID: newbornID,
                ordinal: ordinal, observation: observation, status: "born"
            ),
            summary: "population member born id=\(newbornID.rawValue) birth=\(birthID.rawValue)"
        )
        let finalized = try requiredLifecycleEvent(
            kind: .birthFinalized,
            actorID: plan.progenitorIDs[0],
            subjectID: newbornID,
            causes: [born.eventID],
            payload: birthPayload(
                birthID: birthID, plan: plan, newbornID: newbornID,
                ordinal: ordinal, observation: observation, status: "finalized"
            ),
            summary: "birth finalized id=\(birthID.rawValue) newborn=\(newbornID.rawValue)"
        )
        statesById[newbornID.rawValue] = AgentSessionAgentState(
            agentID: newbornID,
            state: "idle",
            position: observation.position,
            needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0.2, safety: 1),
            health: 100,
            fear: 0,
            homePosition: observation.position,
            nearbyAgents: [],
            currentGoal: AgentGoal(
                kind: .idle, reason: "local birth awaiting next cognitive tick",
                startedAtTick: tick, urgency: 0
            ),
            lastAction: nil,
            lastActionEffect: nil,
            memory: [AgentMemoryEntry(
                tick: tick, type: "local_birth",
                summary: "born in settlement \(registry.settlement.settlementID.rawValue)",
                importance: 1
            )],
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
            totalDistanceReducedTowardHome: 0
        )
        registry.members.append(AgentPopulationMemberRecord(
            agentID: newbornID,
            ordinal: ordinal,
            settlementID: registry.settlement.settlementID,
            status: .resident,
            founder: false,
            registeredTick: tick,
            arrivalTick: tick,
            migrationID: nil,
            entryPosition: nil,
            receptionPosition: observation.position,
            registrationEventID: born.eventID,
            arrivalEventID: born.eventID
        ))
        registry.members.sort { $0.agentID < $1.agentID }
        registry.settlement.residentIDs.append(newbornID)
        registry.settlement.residentIDs.sort()
        registry.nextPopulationOrdinal = nextOrdinal
        registry.lastPopulationEventID = born.eventID
        let lifecycleMember = AgentLifecycleMember(
            agentID: newbornID,
            ordinal: ordinal,
            settlementID: lifecycle.settlementID,
            origin: .localBirth,
            lifecycleRegisteredTick: tick,
            initialAgeTicks: 0,
            currentStage: .newborn,
            lastStageTransitionTick: tick,
            progenitorIDs: plan.progenitorIDs,
            birthID: birthID,
            lastCompletedBirthTick: nil,
            completedBirthCount: 0,
            registrationEventID: born.eventID,
            lastLifecycleEventID: finalized.eventID
        )
        lifecycle.members.append(lifecycleMember)
        lifecycle.members.sort { $0.agentID < $1.agentID }
        for parentID in plan.progenitorIDs {
            if let index = lifecycle.members.firstIndex(where: { $0.agentID == parentID }) {
                lifecycle.members[index].completedBirthCount += 1
                lifecycle.members[index].lastCompletedBirthTick = tick
                lifecycle.members[index].lastLifecycleEventID = finalized.eventID
            }
        }
        lifecycle.plans[planIndex].status = .completed
        lifecycle.plans[planIndex].reason = .completed
        lifecycle.plans[planIndex].resolvedTick = tick
        lifecycle.plans[planIndex].terminalEventID = finalized.eventID
        let record = AgentBirthRecord(
            birthID: birthID,
            planID: plan.planID,
            newbornID: newbornID,
            ordinal: ordinal,
            settlementID: lifecycle.settlementID,
            progenitorIDs: plan.progenitorIDs,
            birthTick: tick,
            position: observation.position,
            worldFingerprint: observation.worldFingerprint,
            siteValidatedEventID: site.eventID,
            populationBornEventID: born.eventID,
            finalizedEventID: finalized.eventID
        )
        lifecycle.births.append(record)
        lifecycle.totalBirthCount += 1
        if lifecycle.frames.last?.tick == tick {
            let prior = lifecycle.frames.removeLast()
            lifecycle.frames.append(AgentLifecycleFrame(
                tick: prior.tick,
                newbornCount: prior.newbornCount + 1,
                juvenileCount: prior.juvenileCount,
                matureCount: prior.matureCount,
                activePlanCount: 0,
                birthDelta: prior.birthDelta + 1,
                maturityDelta: prior.maturityDelta,
                totalBirthCount: lifecycle.totalBirthCount
            ))
        }
        lifecycle.rollingDigest = AgentLifecycleDigest.make(
            "\(lifecycle.rollingDigest)|\(birthID.rawValue)|\(newbornID.rawValue)|\(tick)"
        )
        lifecycle.lastLifecycleEventID = finalized.eventID
        trimLifecycleHistories(&lifecycle)
        populationRegistry = registry
        lifecycleState = lifecycle
        return record
    }

    mutating func registerImportedLifecycleMemberIfNeeded(_ member: AgentPopulationMemberRecord) throws {
        guard var lifecycle = lifecycleState,
              !lifecycle.members.contains(where: { $0.agentID == member.agentID }) else { return }
        let event = try requiredLifecycleEvent(
            kind: .lifecycleMemberRegistered,
            actorID: member.agentID,
            subjectID: member.agentID,
            causes: [member.registrationEventID],
            payload: .lifecycleMember(
                memberID: member.agentID.rawValue,
                ordinal: member.ordinal.rawValue,
                origin: AgentLifecycleOrigin.importedMigrant.rawValue,
                stage: AgentLifeStage.mature.rawValue,
                age: lifecycle.configuration.maturityAgeTicks,
                status: "registered"
            ),
            summary: "imported lifecycle member registered id=\(member.agentID.rawValue)"
        )
        lifecycle.members.append(AgentLifecycleMember(
            agentID: member.agentID,
            ordinal: member.ordinal,
            settlementID: member.settlementID,
            origin: .importedMigrant,
            lifecycleRegisteredTick: tick,
            initialAgeTicks: lifecycle.configuration.maturityAgeTicks,
            currentStage: .mature,
            lastStageTransitionTick: tick,
            progenitorIDs: [],
            birthID: nil,
            lastCompletedBirthTick: nil,
            completedBirthCount: 0,
            registrationEventID: event.eventID,
            lastLifecycleEventID: event.eventID
        ))
        lifecycle.members.sort { $0.agentID < $1.agentID }
        lifecycle.lastLifecycleEventID = event.eventID
        lifecycleState = lifecycle
    }

    mutating func applyLifecycleDeath(
        agentID: AgentID,
        causeEventID: AgentCausalEventID,
        at deathTick: Int
    ) throws {
        guard var lifecycle = lifecycleState,
              let memberIndex = lifecycle.members.firstIndex(where: {
                  $0.agentID == agentID
              }) else { return }
        let activePlanIndices = lifecycle.plans.indices.filter {
            lifecycle.plans[$0].status == .planned
                && lifecycle.plans[$0].progenitorIDs.contains(agentID)
        }
        for index in activePlanIndices {
            let plan = lifecycle.plans[index]
            let cancelled = try requiredLifecycleEvent(
                kind: .reproductionPlanCancelled,
                actorID: agentID,
                subjectID: agentID,
                causes: [causeEventID, plan.createdEventID].sorted(),
                payload: reproductionPlanPayload(plan, status: .cancelled, reason: .parentDied),
                summary: "reproduction plan cancelled id=\(plan.planID.rawValue) reason=parentDied"
            )
            lifecycle.plans[index].status = .cancelled
            lifecycle.plans[index].reason = .parentDied
            lifecycle.plans[index].resolvedTick = deathTick
            lifecycle.plans[index].terminalEventID = cancelled.eventID
            lifecycle.lastLifecycleEventID = cancelled.eventID
        }
        let member = lifecycle.members[memberIndex]
        let exited = try requiredLifecycleEvent(
            kind: .lifecycleMemberExited,
            actorID: agentID,
            subjectID: agentID,
            causes: [causeEventID, lifecycle.lastLifecycleEventID].sorted(),
            payload: .lifecycleMember(
                memberID: agentID.rawValue,
                ordinal: member.ordinal.rawValue,
                origin: member.origin.rawValue,
                stage: member.currentStage.rawValue,
                age: try member.age(at: deathTick),
                status: "exited"
            ),
            summary: "lifecycle member exited id=\(agentID.rawValue)"
        )
        lifecycle.members.remove(at: memberIndex)
        lifecycle.lastLifecycleEventID = exited.eventID
        lifecycleState = lifecycle
    }

    public mutating func clearLifecycleDiagnostics() throws {
        var candidate = self
        guard var lifecycle = candidate.lifecycleState else {
            throw AgentSessionError.lifecycle(.disabled)
        }
        let terminalPlans = lifecycle.plans.filter(\.status.isTerminal).count
        let frameCount = lifecycle.frames.count
        let event = try candidate.requiredLifecycleEvent(
            kind: .lifecycleStateCleared,
            causes: [lifecycle.lastLifecycleEventID],
            payload: .lifecycleMember(
                memberID: nil, ordinal: nil, origin: nil, stage: nil, age: nil,
                status: "diagnosticsCleared"
            ),
            summary: "lifecycle diagnostics cleared plans=\(terminalPlans) frames=\(frameCount)"
        )
        lifecycle.plans.removeAll(where: \.status.isTerminal)
        lifecycle.frames.removeAll()
        lifecycle.evictionCounts = AgentLifecycleEvictionCounts()
        lifecycle.lastLifecycleEventID = event.eventID
        candidate.lifecycleState = lifecycle
        self = candidate
    }

    mutating func appendLifecycleFrame(at frameTick: Int) throws {
        guard var lifecycle = lifecycleState else { return }
        let priorBirths = lifecycle.frames.last?.totalBirthCount ?? lifecycle.totalBirthCount
        let maturityDelta = causalLedger.events.reduce(into: 0) { count, event in
            guard event.simulationTick.rawValue == frameTick,
                  event.kind == .lifeStageChanged,
                  case let .lifecycleMember(_, _, _, stage, _, _) = event.payload,
                  stage == AgentLifeStage.mature.rawValue else { return }
            count += 1
        }
        let frame = AgentLifecycleFrame(
            tick: frameTick,
            newbornCount: lifecycle.members.filter { $0.currentStage == .newborn }.count,
            juvenileCount: lifecycle.members.filter { $0.currentStage == .juvenile }.count,
            matureCount: lifecycle.members.filter { $0.currentStage == .mature }.count,
            activePlanCount: lifecycle.plans.filter { $0.status == .planned }.count,
            birthDelta: lifecycle.totalBirthCount - priorBirths,
            maturityDelta: maturityDelta,
            totalBirthCount: lifecycle.totalBirthCount
        )
        lifecycle.frames.append(frame)
        trimLifecycleHistories(&lifecycle)
        lifecycleState = lifecycle
    }

    static func validateLifecycleState(
        _ lifecycle: AgentLifecycleState,
        population: AgentPopulationRegistry,
        agents: [AgentSessionAgentState],
        clock: AgentSimulationClock,
        causalLatestSequence: UInt64
    ) throws {
        _ = try AgentLifecycleConfiguration(
            newbornDurationTicks: lifecycle.configuration.newbornDurationTicks,
            maturityAgeTicks: lifecycle.configuration.maturityAgeTicks,
            reproductionEvaluationIntervalTicks:
                lifecycle.configuration.reproductionEvaluationIntervalTicks,
            reproductionPlanDelayTicks: lifecycle.configuration.reproductionPlanDelayTicks,
            reproductionCooldownTicks: lifecycle.configuration.reproductionCooldownTicks,
            maximumConcurrentPlans: lifecycle.configuration.maximumConcurrentPlans,
            maximumBirthsPerTick: lifecycle.configuration.maximumBirthsPerTick,
            maximumRetainedBirthRecords: lifecycle.configuration.maximumRetainedBirthRecords,
            maximumRetainedPlanRecords: lifecycle.configuration.maximumRetainedPlanRecords,
            maximumParentBirthCount: lifecycle.configuration.maximumParentBirthCount,
            maximumBirthSiteCandidates: lifecycle.configuration.maximumBirthSiteCandidates,
            birthSiteRadius: lifecycle.configuration.birthSiteRadius,
            maximumBirthSiteWorldReads: lifecycle.configuration.maximumBirthSiteWorldReads,
            maximumLifecycleFrames: lifecycle.configuration.maximumLifecycleFrames
        )
        let activeIDs = Set(agents.map(\.agentID))
        let memberIDs = lifecycle.members.map(\.agentID)
        let birthIDs = lifecycle.births.map(\.birthID)
        let planIDs = lifecycle.plans.map(\.planID)
        guard lifecycle.settlementID == population.settlement.settlementID,
              Set(memberIDs) == activeIDs,
              memberIDs.count == Set(memberIDs).count,
              lifecycle.members.map(\.ordinal).count == Set(lifecycle.members.map(\.ordinal)).count,
              lifecycle.members.count <= population.configuration.maximumActivePopulation,
              lifecycle.plans.count <= lifecycle.configuration.maximumRetainedPlanRecords,
              lifecycle.births.count <= lifecycle.configuration.maximumRetainedBirthRecords,
              lifecycle.frames.count <= lifecycle.configuration.maximumLifecycleFrames,
              lifecycle.plans.filter({ $0.status == .planned }).count
                <= lifecycle.configuration.maximumConcurrentPlans,
              birthIDs.count == Set(birthIDs).count,
              planIDs.count == Set(planIDs).count,
              lifecycle.totalBirthCount >= lifecycle.births.count,
              !lifecycle.rollingDigest.isEmpty,
              lifecycle.initializedEventID.simulationID == clock.simulationID,
              lifecycle.lastLifecycleEventID.simulationID == clock.simulationID,
              lifecycle.lastLifecycleEventID.sequence.rawValue <= causalLatestSequence,
              lifecycle.evictionCounts.births >= 0,
              lifecycle.evictionCounts.plans >= 0,
              lifecycle.evictionCounts.frames >= 0 else {
            throw AgentCheckpointError.invalidBound("lifecycle")
        }
        for member in lifecycle.members {
            let age = try member.age(at: clock.tick.rawValue)
            let expected = age < lifecycle.configuration.newbornDurationTicks
                ? AgentLifeStage.newborn
                : (age < lifecycle.configuration.maturityAgeTicks ? .juvenile : .mature)
            guard member.currentStage == expected,
                  population.members.contains(where: {
                      $0.agentID == member.agentID && $0.ordinal == member.ordinal
                  }),
                  member.progenitorIDs == member.progenitorIDs.sorted(),
                  Set(member.progenitorIDs).count == member.progenitorIDs.count,
                  member.progenitorIDs.count == (member.origin == .localBirth ? 2 : 0),
                  member.completedBirthCount >= 0,
                  member.completedBirthCount <= lifecycle.configuration.maximumParentBirthCount else {
                throw AgentCheckpointError.invalidReference(member.agentID.rawValue)
            }
        }
        for birth in lifecycle.births {
            guard birth.progenitorIDs.count == 2,
                  birth.progenitorIDs == birth.progenitorIDs.sorted(),
                  birth.birthTick <= clock.tick.rawValue,
                  birth.siteValidatedEventID.sequence < birth.populationBornEventID.sequence,
                  birth.populationBornEventID.sequence < birth.finalizedEventID.sequence else {
                throw AgentCheckpointError.invalidReference(birth.birthID.rawValue)
            }
        }
    }

    private func lifeStage(
        age: Int,
        configuration: AgentLifecycleConfiguration
    ) -> AgentLifeStage {
        if age < configuration.newbornDurationTicks { return .newborn }
        if age < configuration.maturityAgeTicks { return .juvenile }
        return .mature
    }

    private func areUnrelated(
        _ lhs: AgentLifecycleMember,
        _ rhs: AgentLifecycleMember
    ) -> Bool {
        guard lhs.agentID != rhs.agentID,
              !lhs.progenitorIDs.contains(rhs.agentID),
              !rhs.progenitorIDs.contains(lhs.agentID) else { return false }
        return Set(lhs.progenitorIDs).isDisjoint(with: Set(rhs.progenitorIDs))
    }

    private func reproductionEligibility(
        lifecycle: AgentLifecycleState,
        registry: AgentPopulationRegistry,
        evaluationTick: Int
    ) -> (
        candidates: [AgentLifecycleMember],
        pairs: [[AgentLifecycleMember]],
        accessibleFood: Int,
        pressure: AgentSubsistencePressureLevel?
    ) {
        let accessibleFood = localEcologySummary().currentYield
            + statesById.values.reduce(0) {
                $0 + $1.resourceInventory.count(of: .foodRaw)
            } + campStock.count(of: .foodRaw)
        let residentIDs = Set(registry.settlement.residentIDs)
        let activeParentIDs = Set(lifecycle.plans.filter { $0.status == .planned }
            .flatMap(\.progenitorIDs))
        let critical = configuration.survivalConfiguration.criticalHungerThreshold
        let candidates = lifecycle.members.filter { member in
            guard residentIDs.contains(member.agentID), member.currentStage == .mature,
                  !activeParentIDs.contains(member.agentID),
                  member.completedBirthCount < lifecycle.configuration.maximumParentBirthCount,
                  let state = statesById[member.agentID.rawValue], state.health > 0,
                  state.needs.hunger < critical else { return false }
            return member.lastCompletedBirthTick.map {
                evaluationTick - $0 >= lifecycle.configuration.reproductionCooldownTicks
            } ?? true
        }.sorted { $0.agentID < $1.agentID }
        var pairs: [[AgentLifecycleMember]] = []
        for leftIndex in candidates.indices {
            for rightIndex in candidates.indices where rightIndex > leftIndex {
                let left = candidates[leftIndex]
                let right = candidates[rightIndex]
                if areUnrelated(left, right) { pairs.append([left, right]) }
            }
        }
        pairs.sort { lhs, rhs in
            let lhsBirths = lhs[0].completedBirthCount + lhs[1].completedBirthCount
            let rhsBirths = rhs[0].completedBirthCount + rhs[1].completedBirthCount
            if lhsBirths != rhsBirths { return lhsBirths < rhsBirths }
            let lhsLast = max(
                lhs[0].lastCompletedBirthTick ?? Int.min,
                lhs[1].lastCompletedBirthTick ?? Int.min
            )
            let rhsLast = max(
                rhs[0].lastCompletedBirthTick ?? Int.min,
                rhs[1].lastCompletedBirthTick ?? Int.min
            )
            if lhsLast != rhsLast { return lhsLast < rhsLast }
            if lhs[0].agentID != rhs[0].agentID { return lhs[0].agentID < rhs[0].agentID }
            return lhs[1].agentID < rhs[1].agentID
        }
        return (candidates, pairs, accessibleFood, localEcologyState?.currentPressure)
    }

    private mutating func trimLifecycleHistories(_ lifecycle: inout AgentLifecycleState) {
        if lifecycle.births.count > lifecycle.configuration.maximumRetainedBirthRecords {
            let removed = lifecycle.births.count
                - lifecycle.configuration.maximumRetainedBirthRecords
            lifecycle.births.removeFirst(removed)
            lifecycle.evictionCounts.births += removed
        }
        if lifecycle.plans.count > lifecycle.configuration.maximumRetainedPlanRecords {
            let terminal = lifecycle.plans.indices.filter {
                lifecycle.plans[$0].status.isTerminal
            }
            let removeCount = lifecycle.plans.count
                - lifecycle.configuration.maximumRetainedPlanRecords
            for index in terminal.prefix(removeCount).reversed() {
                lifecycle.plans.remove(at: index)
                lifecycle.evictionCounts.plans += 1
            }
        }
        if lifecycle.frames.count > lifecycle.configuration.maximumLifecycleFrames {
            let removed = lifecycle.frames.count - lifecycle.configuration.maximumLifecycleFrames
            lifecycle.frames.removeFirst(removed)
            lifecycle.evictionCounts.frames += removed
        }
    }

    private func reproductionPlanPayload(
        _ plan: AgentReproductionPlan,
        status: AgentReproductionPlanStatus,
        reason: AgentReproductionPlanReason?
    ) -> AgentCausalPayload {
        .reproductionPlan(
            planID: plan.planID.rawValue,
            progenitorIDs: plan.progenitorIDs.map(\.rawValue),
            createdTick: plan.createdTick,
            dueTick: plan.dueTick,
            status: status.rawValue,
            reason: reason?.rawValue
        )
    }

    private mutating func cancelReproductionPlan(
        _ lifecycle: inout AgentLifecycleState,
        index: Int,
        plan: AgentReproductionPlan,
        reason: AgentReproductionPlanReason,
        status: AgentReproductionPlanStatus
    ) throws {
        let event = try requiredLifecycleEvent(
            kind: .reproductionPlanCancelled,
            causes: [plan.createdEventID],
            payload: reproductionPlanPayload(plan, status: status, reason: reason),
            summary: "reproduction plan cancelled id=\(plan.planID.rawValue) reason=\(reason.rawValue)"
        )
        lifecycle.plans[index].status = status
        lifecycle.plans[index].reason = reason
        lifecycle.plans[index].resolvedTick = tick
        lifecycle.plans[index].terminalEventID = event.eventID
        lifecycle.lastLifecycleEventID = event.eventID
    }

    private func birthPayload(
        birthID: AgentBirthID,
        plan: AgentReproductionPlan,
        newbornID: AgentID,
        ordinal: AgentPopulationOrdinal,
        observation: AgentBirthSiteObservation,
        status: String
    ) -> AgentCausalPayload {
        .birth(
            birthID: birthID.rawValue,
            planID: plan.planID.rawValue,
            newbornID: newbornID.rawValue,
            ordinal: ordinal.rawValue,
            progenitorIDs: plan.progenitorIDs.map(\.rawValue),
            position: observation.position,
            fingerprint: observation.worldFingerprint,
            status: status
        )
    }

    private mutating func requiredLifecycleEvent(
        kind: AgentCausalEventKind,
        actorID: AgentID? = nil,
        subjectID: AgentID? = nil,
        causes: [AgentCausalEventID] = [],
        payload: AgentCausalPayload,
        summary: String
    ) throws -> AgentCausalEvent {
        guard let event = try recordCausalEvent(
            kind: kind,
            origin: .lifecycleTransition,
            actorID: actorID,
            subjectID: subjectID,
            causes: causes,
            payload: payload,
            summary: summary
        ) else {
            throw AgentSessionError.lifecycle(.causalLedgerRequired)
        }
        return event
    }
}

extension AgentCausalEventKind {
    public var isLifecycle: Bool {
        switch self {
        case .lifecycleInitialized, .lifecycleMemberRegistered, .lifeStageChanged,
             .reproductionEnabled, .reproductionDisabled, .reproductionPlanCreated,
             .reproductionPlanCancelled, .birthSiteValidated, .populationMemberBorn,
             .birthFinalized, .lifecycleMemberExited, .lifecycleStateCleared:
            return true
        default:
            return false
        }
    }
}
