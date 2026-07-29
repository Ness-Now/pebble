private struct AgentHomeostasisProposal {
    let agentID: AgentID
    var profile: AgentHomeostasisProfile
    var state: AgentSessionAgentState
    let previousCondition: AgentHealthCondition
    let healthBefore: Int
    let previousDominantFactor: AgentPhysiologicalFactorCode?
    let dominantFactor: AgentPhysiologicalFactorCode?
    let reason: String
    let publishesTransition: Bool
}

extension AgentSimulationSession {
    public var homeostasisEnabled: Bool { homeostasisState != nil }

    public func homeostasisSnapshot() -> AgentHomeostasisSnapshot {
        guard let state = homeostasisState else {
            return AgentHomeostasisSnapshot(
                enabled: false, tick: tick, configuration: nil, profiles: [],
                recentTransitions: [], totalTransitionCount: 0,
                transitionEvictionCount: 0,
                digest: AgentHomeostasisDigest.make("disabled|\(tick)")
            )
        }
        let profiles = state.profiles.sorted { $0.agentID < $1.agentID }
        let transitions = state.recentTransitions.sorted {
            if $0.tick != $1.tick { return $0.tick < $1.tick }
            if $0.eventID != $1.eventID { return $0.eventID < $1.eventID }
            return $0.agentID < $1.agentID
        }
        let profileText = profiles.map { profile in
            let factors = profile.activeFactors.sorted {
                $0.code.rawValue < $1.code.rawValue
            }.map {
                "\($0.code.rawValue):\($0.severityBasisPoints):\($0.harmful):\($0.source)"
            }.joined(separator: ",")
            let episodes = profile.recentEpisodes.sorted {
                if $0.startedAtTick != $1.startedAtTick {
                    return $0.startedAtTick < $1.startedAtTick
                }
                return $0.episodeID < $1.episodeID
            }.map {
                [
                    $0.episodeID,
                    $0.cause.rawValue,
                    String($0.startedAtTick),
                    String($0.endedAtTick ?? -1),
                    String($0.lastUpdatedTick),
                    $0.worstCondition.rawValue,
                    $0.trend.rawValue,
                    $0.lastEventID.rawValue,
                ].joined(separator: ":")
            }.joined(separator: ",")
            return [
                profile.agentID.rawValue,
                profile.vitalStatus.rawValue,
                profile.condition.rawValue,
                profile.trend.rawValue,
                String(profile.energyReserveBasisPoints),
                String(profile.stressBasisPoints),
                String(profile.recoveryCapacityBasisPoints),
                String(profile.ageTicks),
                profile.lifeStage.rawValue,
                profile.ageBand.rawValue,
                String(profile.ageVulnerabilityBasisPoints),
                factors,
                episodes,
                String(profile.episodeEvictionCount),
                String(profile.lastUpdatedTick),
                profile.lastEventID.rawValue,
            ].joined(separator: ":")
        }.joined(separator: ";")
        let transitionText = transitions.map { transition in
            [
                transition.eventID.rawValue,
                transition.agentID.rawValue,
                "\(transition.conditionBefore.rawValue)>\(transition.conditionAfter.rawValue)",
                "\(transition.healthBefore)>\(transition.healthAfter)",
                transition.reason,
            ].joined(separator: ":")
        }.joined(separator: ";")
        let configurationText = [
            state.configuration.maximumProfiles,
            state.configuration.maximumFactorsPerProfile,
            state.configuration.maximumEpisodesPerProfile,
            state.configuration.maximumRetainedTransitions,
            state.configuration.ageVulnerabilityStartTicks,
            state.configuration.ageVulnerabilityPerTickBasisPoints,
            state.configuration.maximumAgeVulnerabilityBasisPoints,
            state.configuration.recoveryPerTick,
            state.configuration.stressRecoveryPerTick,
            state.configuration.baseHealthDamagePerTick,
            state.configuration.healthRecoveryPerTick,
            state.configuration.incapacityHealthThreshold,
        ].map(String.init).joined(separator: ",")
        let canonical = [
            "tick=\(tick)",
            "configuration=\(configurationText)",
            profileText,
            transitionText,
            "total=\(state.totalTransitionCount)",
            "evicted=\(state.transitionEvictionCount)",
            "last=\(state.lastEventID.rawValue)",
        ].joined(separator: "|")
        return AgentHomeostasisSnapshot(
            enabled: true, tick: tick, configuration: state.configuration,
            profiles: profiles, recentTransitions: transitions,
            totalTransitionCount: state.totalTransitionCount,
            transitionEvictionCount: state.transitionEvictionCount,
            digest: AgentHomeostasisDigest.make(canonical)
        )
    }

    public func homeostasisProfile(
        for agentID: AgentID
    ) -> AgentHomeostasisProfile? {
        homeostasisState?.profiles.first { $0.agentID == agentID }
    }

    public func vitalStatus(for agentID: AgentID) -> AgentVitalStatus? {
        if let profile = homeostasisProfile(for: agentID) {
            return profile.vitalStatus
        }
        if mortalityState?.records.contains(where: { $0.agentID == agentID }) == true {
            return .dead
        }
        return statesById[agentID.rawValue] == nil ? nil : .alive
    }

    public mutating func setHomeostasisEnabled(
        _ enabled: Bool,
        configuration: AgentHomeostasisConfiguration = .live
    ) throws {
        var candidate = self
        try candidate.setHomeostasisEnabledInPlace(
            enabled, configuration: configuration
        )
        self = candidate
    }

    private mutating func setHomeostasisEnabledInPlace(
        _ enabled: Bool,
        configuration: AgentHomeostasisConfiguration
    ) throws {
        if !enabled {
            guard homeostasisState != nil else {
                throw AgentSessionError.homeostasis(.disabled)
            }
            throw AgentSessionError.homeostasis(.unsafeDisable)
        }
        guard homeostasisState == nil else {
            throw AgentSessionError.homeostasis(.alreadyEnabled)
        }
        guard causalLedger.isEnabled else {
            throw AgentSessionError.homeostasis(.causalLedgerRequired)
        }
        guard survivalEnabled else {
            throw AgentSessionError.homeostasis(.survivalRequired)
        }
        guard mortalityState != nil else {
            throw AgentSessionError.homeostasis(.mortalityRequired)
        }
        guard lifecycleState != nil else {
            throw AgentSessionError.homeostasis(.lifecycleRequired)
        }
        guard populationRegistry != nil else {
            throw AgentSessionError.homeostasis(.populationRequired)
        }
        _ = try AgentHomeostasisConfiguration(
            maximumProfiles: configuration.maximumProfiles,
            maximumFactorsPerProfile: configuration.maximumFactorsPerProfile,
            maximumEpisodesPerProfile: configuration.maximumEpisodesPerProfile,
            maximumRetainedTransitions: configuration.maximumRetainedTransitions,
            ageVulnerabilityStartTicks: configuration.ageVulnerabilityStartTicks,
            ageVulnerabilityPerTickBasisPoints:
                configuration.ageVulnerabilityPerTickBasisPoints,
            maximumAgeVulnerabilityBasisPoints:
                configuration.maximumAgeVulnerabilityBasisPoints,
            recoveryPerTick: configuration.recoveryPerTick,
            stressRecoveryPerTick: configuration.stressRecoveryPerTick,
            baseHealthDamagePerTick: configuration.baseHealthDamagePerTick,
            healthRecoveryPerTick: configuration.healthRecoveryPerTick,
            incapacityHealthThreshold: configuration.incapacityHealthThreshold
        )
        let activeIDs = statesById.values.map(\.agentID).sorted()
        guard activeIDs.count <= configuration.maximumProfiles else {
            throw AgentSessionError.homeostasis(.profileLimitReached)
        }
        try prevalidateCausalAppend(count: activeIDs.count + 1)
        guard let initialized = try recordCausalEvent(
            kind: .homeostasisInitialized,
            origin: .homeostasisTransition,
            payload: .operation(
                status: "initialized",
                detail: "profiles=\(activeIDs.count)"
            ),
            summary: "homeostasis initialized profiles=\(activeIDs.count)"
        ) else {
            throw AgentSessionError.homeostasis(.causalLedgerRequired)
        }
        var profiles: [AgentHomeostasisProfile] = []
        var last = initialized.eventID
        for agentID in activeIDs {
            guard let state = statesById[agentID.rawValue] else {
                throw AgentSessionError.homeostasis(.unknownAgent(agentID))
            }
            let age = try demographicAge(for: agentID)
            let stage = lifecycleStage(for: agentID, age: age)
            guard let event = try recordCausalEvent(
                kind: .homeostasisProfileRegistered,
                origin: .homeostasisTransition,
                actorID: agentID,
                subjectID: agentID,
                causes: [initialized.eventID],
                payload: .operation(
                    status: "registered",
                    detail: "age=\(age) stage=\(stage.rawValue)"
                ),
                summary: "homeostasis profile registered agent=\(agentID.rawValue)"
            ) else {
                throw AgentSessionError.homeostasis(.causalLedgerRequired)
            }
            last = event.eventID
            profiles.append(initialHomeostasisProfile(
                agentID: agentID, state: state, age: age, stage: stage,
                eventID: event.eventID, configuration: configuration
            ))
        }
        homeostasisState = AgentHomeostasisState(
            configuration: configuration,
            profiles: profiles,
            recentTransitions: [],
            totalTransitionCount: 0,
            transitionEvictionCount: 0,
            initializedEventID: initialized.eventID,
            lastEventID: last
        )
    }

    mutating func registerHomeostasisProfileIfEnabled(
        for agentID: AgentID,
        causeEventID: AgentCausalEventID
    ) throws {
        guard var homeostasis = homeostasisState else { return }
        guard !homeostasis.profiles.contains(where: { $0.agentID == agentID }),
              let state = statesById[agentID.rawValue] else {
            throw AgentSessionError.homeostasis(.invalidState(
                "duplicate or unavailable profile \(agentID.rawValue)"
            ))
        }
        guard homeostasis.profiles.count < homeostasis.configuration.maximumProfiles else {
            throw AgentSessionError.homeostasis(.profileLimitReached)
        }
        let age = try demographicAge(for: agentID)
        let stage = lifecycleStage(for: agentID, age: age)
        try prevalidateCausalAppend(count: 1)
        guard let event = try recordCausalEvent(
            kind: .homeostasisProfileRegistered,
            origin: .homeostasisTransition,
            actorID: agentID,
            subjectID: agentID,
            causes: [causeEventID],
            payload: .operation(
                status: "registered",
                detail: "age=\(age) stage=\(stage.rawValue)"
            ),
            summary: "homeostasis profile registered agent=\(agentID.rawValue)"
        ) else {
            throw AgentSessionError.homeostasis(.causalLedgerRequired)
        }
        homeostasis.profiles.append(initialHomeostasisProfile(
            agentID: agentID, state: state, age: age, stage: stage,
            eventID: event.eventID, configuration: homeostasis.configuration
        ))
        homeostasis.profiles.sort { $0.agentID < $1.agentID }
        homeostasis.lastEventID = event.eventID
        homeostasisState = homeostasis
    }

    mutating func applyHomeostasisBoundary(at boundaryTick: Int) throws {
        guard var homeostasis = homeostasisState else { return }
        var proposals: [AgentHomeostasisProposal] = []
        for profile in homeostasis.profiles.sorted(by: { $0.agentID < $1.agentID }) {
            guard let state = statesById[profile.agentID.rawValue] else {
                throw AgentSessionError.homeostasis(.invalidState(
                    "active profile without agent \(profile.agentID.rawValue)"
                ))
            }
            proposals.append(try homeostasisProposal(
                profile: profile, state: state, at: boundaryTick,
                configuration: homeostasis.configuration
            ))
        }
        let transitionCount = proposals.filter(\.publishesTransition).count
        try prevalidateCausalAppend(count: transitionCount)
        for proposal in proposals {
            var updated = proposal
            if proposal.publishesTransition {
                let cause = [proposal.profile.lastEventID]
                guard let event = try recordCausalEvent(
                    kind: proposal.profile.vitalStatus == .incapacitated
                        ? .homeostasisIncapacityChanged : .homeostasisChanged,
                    origin: .homeostasisTransition,
                    actorID: proposal.agentID,
                    subjectID: proposal.agentID,
                    causes: cause,
                    payload: .operation(
                        status: proposal.profile.condition.rawValue,
                        detail: proposal.reason
                    ),
                    summary: "homeostasis \(proposal.agentID.rawValue) "
                        + "\(proposal.previousCondition.rawValue)>"
                        + "\(proposal.profile.condition.rawValue)"
                ) else {
                    throw AgentSessionError.homeostasis(.causalLedgerRequired)
                }
                updated.profile.lastEventID = event.eventID
                updateHealthEpisodes(
                    profile: &updated.profile,
                    previousDominant: proposal.previousDominantFactor,
                    dominant: proposal.dominantFactor,
                    at: boundaryTick,
                    eventID: event.eventID,
                    configuration: homeostasis.configuration
                )
                homeostasis.recentTransitions.append(AgentHomeostasisTransition(
                    agentID: proposal.agentID,
                    tick: boundaryTick,
                    conditionBefore: proposal.previousCondition,
                    conditionAfter: updated.profile.condition,
                    trend: updated.profile.trend,
                    vitalStatus: updated.profile.vitalStatus,
                    healthBefore: proposal.healthBefore,
                    healthAfter: updated.state.health,
                    energyReserveBasisPoints:
                        updated.profile.energyReserveBasisPoints,
                    stressBasisPoints: updated.profile.stressBasisPoints,
                    dominantFactor: proposal.dominantFactor,
                    reason: proposal.reason,
                    eventID: event.eventID
                ))
                homeostasis.totalTransitionCount += 1
                homeostasis.lastEventID = event.eventID
                if updated.profile.vitalStatus == .incapacitated,
                   let activity = activeAutonomousActivity(for: proposal.agentID) {
                    _ = try recordAutonomousActivityOutcome(
                        AgentAutonomousActivityOutcome(
                            activityID: activity.activityID,
                            actorID: proposal.agentID,
                            lifecycle: .interrupted,
                            completedAtTick: boundaryTick,
                            sourceEventID: event.eventID,
                            reason: "physiological incapacity"
                        )
                    )
                }
            }
            statesById[proposal.agentID.rawValue] = updated.state
            if let index = homeostasis.profiles.firstIndex(where: {
                $0.agentID == proposal.agentID
            }) {
                homeostasis.profiles[index] = updated.profile
            }
        }
        if homeostasis.recentTransitions.count
            > homeostasis.configuration.maximumRetainedTransitions {
            let removed = homeostasis.recentTransitions.count
                - homeostasis.configuration.maximumRetainedTransitions
            homeostasis.recentTransitions.removeFirst(removed)
            homeostasis.transitionEvictionCount += removed
        }
        homeostasisState = homeostasis
    }

    mutating func removeHomeostasisProfileAfterDeath(_ agentID: AgentID) throws {
        guard var homeostasis = homeostasisState else { return }
        guard let index = homeostasis.profiles.firstIndex(where: {
            $0.agentID == agentID
        }) else {
            throw AgentSessionError.homeostasis(.invalidState(
                "death missing profile \(agentID.rawValue)"
            ))
        }
        homeostasis.profiles.remove(at: index)
        homeostasisState = homeostasis
    }

    func isPhysiologicallyIncapacitated(_ agentID: AgentID) -> Bool {
        guard let vital = homeostasisProfile(for: agentID)?.vitalStatus else {
            return false
        }
        return vital == .incapacitated || vital == .dead
    }

    private func homeostasisProposal(
        profile original: AgentHomeostasisProfile,
        state originalState: AgentSessionAgentState,
        at boundaryTick: Int,
        configuration: AgentHomeostasisConfiguration
    ) throws -> AgentHomeostasisProposal {
        var profile = original
        var state = originalState
        let healthBefore = state.health
        let age = try demographicAgeAtBoundary(
            for: profile.agentID, tick: boundaryTick
        )
        let stage = lifecycleStage(for: profile.agentID, age: age)
        let ageVulnerability = min(
            configuration.maximumAgeVulnerabilityBasisPoints,
            max(0, age - configuration.ageVulnerabilityStartTicks)
                * configuration.ageVulnerabilityPerTickBasisPoints
        )
        let hunger = basisPoints(state.needs.hunger)
        let fatigue = basisPoints(state.needs.fatigue)
        let survival = self.configuration.survivalConfiguration
        let hungry = hunger >= basisPoints(survival.hungryThreshold)
        let criticalHunger = hunger >= basisPoints(
            survival.criticalHungerThreshold
        )
        let exhausted = fatigue >= basisPoints(survival.fatigueThreshold)
        let recoveredHunger = hunger <= basisPoints(
            survival.hungerRecoveryThreshold
        )
        let recoveredFatigue = fatigue <= basisPoints(
            survival.fatigueRecoveryThreshold
        )
        var factors: [AgentPhysiologicalFactor] = []
        if hungry {
            factors.append(AgentPhysiologicalFactor(
                code: .hunger,
                severityBasisPoints: criticalHunger ? hunger : hunger / 2,
                harmful: true,
                source: "AgentNeeds.hunger"
            ))
        } else if recoveredHunger {
            factors.append(AgentPhysiologicalFactor(
                code: .nourishment,
                severityBasisPoints: 10_000 - hunger,
                harmful: false,
                source: "AgentNeeds.hunger at recovered bound"
            ))
        }
        if exhausted {
            factors.append(AgentPhysiologicalFactor(
                code: .fatigue,
                severityBasisPoints: fatigue,
                harmful: true,
                source: "AgentNeeds.fatigue"
            ))
        } else if recoveredFatigue {
            factors.append(AgentPhysiologicalFactor(
                code: .rest,
                severityBasisPoints: 10_000 - fatigue,
                harmful: false,
                source: "AgentNeeds.fatigue at recovered bound"
            ))
        }
        if criticalHunger && exhausted {
            factors.append(AgentPhysiologicalFactor(
                code: .compoundedDeprivation,
                severityBasisPoints: min(10_000, (hunger + fatigue) / 2),
                harmful: true,
                source: "combined hunger and fatigue"
            ))
        }
        if ageVulnerability > 0 {
            factors.append(AgentPhysiologicalFactor(
                code: .ageVulnerability,
                severityBasisPoints: ageVulnerability,
                harmful: true,
                source: "monotone lifecycle age"
            ))
        }
        let resilienceModifier = phenotypeModifier(
            .homeostaticResilience, for: profile.agentID
        )
        let recoveryModifier = phenotypeModifier(
            .recoveryEfficiency, for: profile.agentID
        )
        let toleranceModifier = phenotypeModifier(
            .deprivationTolerance, for: profile.agentID
        )
        let phenotypeMagnitude = [
            resilienceModifier, recoveryModifier, toleranceModifier,
        ].map(abs).max() ?? 0
        if geneticsEnabled, phenotypeMagnitude > 0 {
            factors.append(AgentPhysiologicalFactor(
                code: .phenotypeExpression,
                severityBasisPoints: phenotypeMagnitude,
                harmful: false,
                source: "bounded CIV-30 modifiers resilience="
                    + "\(resilienceModifier) recovery=\(recoveryModifier) "
                    + "tolerance=\(toleranceModifier)"
            ))
        }
        factors.sort {
            if $0.harmful != $1.harmful { return $0.harmful && !$1.harmful }
            if $0.severityBasisPoints != $1.severityBasisPoints {
                return $0.severityBasisPoints > $1.severityBasisPoints
            }
            return $0.code.rawValue < $1.code.rawValue
        }
        factors = Array(factors.prefix(configuration.maximumFactorsPerProfile))

        var drain = 0
        if hungry { drain += criticalHunger ? 1_200 : 400 }
        if exhausted { drain += 700 }
        if criticalHunger && exhausted { drain += 400 }
        drain = max(0, drain * (10_000 - toleranceModifier) / 10_000)
        let recovering = recoveredHunger && recoveredFatigue
        let energyBefore = profile.energyReserveBasisPoints
        let stressBefore = profile.stressBasisPoints
        if recovering {
            profile.energyReserveBasisPoints = min(
                10_000,
                profile.energyReserveBasisPoints
                    + max(
                        1,
                        configuration.recoveryPerTick
                            * (10_000 + recoveryModifier) / 10_000
                    )
            )
            profile.stressBasisPoints = max(
                0,
                profile.stressBasisPoints
                    - max(
                        1,
                        configuration.stressRecoveryPerTick
                            * (10_000 + recoveryModifier) / 10_000
                    )
            )
        } else {
            profile.energyReserveBasisPoints = max(
                0, profile.energyReserveBasisPoints - drain
            )
            profile.stressBasisPoints = min(
                10_000,
                profile.stressBasisPoints
                    + max(
                        0,
                        drain * (10_000 - resilienceModifier) / 10_000
                    )
                    + ageVulnerability / 10
            )
        }
        profile.recoveryCapacityBasisPoints = max(
            0,
            min(
                10_000,
                10_000 - ageVulnerability
                    - profile.stressBasisPoints / 2
                    + recoveryModifier
            )
        )

        if profile.stressBasisPoints >= 6_000,
           profile.energyReserveBasisPoints <= 3_500 {
            let damage = min(
                state.health,
                configuration.baseHealthDamagePerTick
                    + ageVulnerability / 1_000
                    + (criticalHunger && exhausted ? 2 : 0)
            )
            state.health -= damage
            if var progress = state.survivalProgress, criticalHunger {
                progress.starvationDamageTaken = min(
                    100, progress.starvationDamageTaken + damage
                )
                progress.lastMemoryType = .starvationDamage
                state.survivalProgress = progress
            }
        } else if recovering, state.health < 100,
                  profile.recoveryCapacityBasisPoints > 0 {
            state.health = min(
                100,
                state.health + max(
                    1,
                    configuration.healthRecoveryPerTick
                        * (10_000 + recoveryModifier) / 10_000
                )
            )
        }

        let condition = healthCondition(
            health: state.health,
            energy: profile.energyReserveBasisPoints,
            stress: profile.stressBasisPoints,
            incapacityThreshold: configuration.incapacityHealthThreshold
        )
        let vital: AgentVitalStatus
        switch condition {
        case .incapacitated: vital = .incapacitated
        case .dead: vital = .dead
        default: vital = .alive
        }
        let trend: AgentHealthTrend
        if state.health > healthBefore
            || (profile.energyReserveBasisPoints > energyBefore
                && profile.stressBasisPoints < stressBefore) {
            trend = .recovering
        } else if state.health < healthBefore
            || profile.energyReserveBasisPoints < energyBefore
            || profile.stressBasisPoints > stressBefore {
            trend = .worsening
        } else {
            trend = .stable
        }
        let dominant = factors.first(where: \.harmful)?.code
        let previousDominant = original.activeFactors.first(where: \.harmful)?.code
        profile.vitalStatus = vital
        profile.condition = condition
        profile.trend = trend
        profile.ageTicks = age
        profile.lifeStage = stage
        profile.ageBand = physiologicalAgeBand(
            age: age, stage: stage,
            vulnerabilityStart: configuration.ageVulnerabilityStartTicks
        )
        profile.ageVulnerabilityBasisPoints = ageVulnerability
        profile.activeFactors = factors
        profile.lastUpdatedTick = boundaryTick
        if vital == .incapacitated {
            state.state = "incapacitated"
        }
        let publishes = original.condition != condition
            || original.trend != trend
            || original.vitalStatus != vital
            || original.ageBand != profile.ageBand
            || healthBefore != state.health
            || previousDominant != dominant
        let reason = [
            "hunger=\(hunger)",
            "fatigue=\(fatigue)",
            "energy=\(energyBefore)>\(profile.energyReserveBasisPoints)",
            "stress=\(stressBefore)>\(profile.stressBasisPoints)",
            "health=\(healthBefore)>\(state.health)",
            "age=\(age)",
            "factor=\(dominant?.rawValue ?? "none")",
            "phenotype=\(resilienceModifier),\(recoveryModifier),\(toleranceModifier)",
        ].joined(separator: " ")
        return AgentHomeostasisProposal(
            agentID: profile.agentID, profile: profile, state: state,
            previousCondition: original.condition,
            healthBefore: healthBefore,
            previousDominantFactor: previousDominant,
            dominantFactor: dominant,
            reason: reason,
            publishesTransition: publishes
        )
    }

    private func initialHomeostasisProfile(
        agentID: AgentID,
        state: AgentSessionAgentState,
        age: Int,
        stage: AgentLifeStage,
        eventID: AgentCausalEventID,
        configuration: AgentHomeostasisConfiguration
    ) -> AgentHomeostasisProfile {
        AgentHomeostasisProfile(
            agentID: agentID,
            vitalStatus: .alive,
            condition: .stable,
            trend: .stable,
            energyReserveBasisPoints: 10_000,
            stressBasisPoints: 0,
            recoveryCapacityBasisPoints: 10_000,
            ageTicks: age,
            lifeStage: stage,
            ageBand: physiologicalAgeBand(
                age: age, stage: stage,
                vulnerabilityStart: configuration.ageVulnerabilityStartTicks
            ),
            ageVulnerabilityBasisPoints: 0,
            activeFactors: [],
            recentEpisodes: [],
            episodeEvictionCount: 0,
            lastUpdatedTick: tick,
            lastEventID: eventID
        )
    }

    private func updateHealthEpisodes(
        profile: inout AgentHomeostasisProfile,
        previousDominant: AgentPhysiologicalFactorCode?,
        dominant: AgentPhysiologicalFactorCode?,
        at tick: Int,
        eventID: AgentCausalEventID,
        configuration: AgentHomeostasisConfiguration
    ) {
        if previousDominant != dominant {
            if !profile.recentEpisodes.isEmpty,
               profile.recentEpisodes[profile.recentEpisodes.count - 1].endedAtTick == nil {
                profile.recentEpisodes[profile.recentEpisodes.count - 1].endedAtTick = tick
                profile.recentEpisodes[profile.recentEpisodes.count - 1].lastUpdatedTick = tick
                profile.recentEpisodes[profile.recentEpisodes.count - 1].trend =
                    profile.trend
                profile.recentEpisodes[profile.recentEpisodes.count - 1].lastEventID = eventID
            }
            if let dominant {
                profile.recentEpisodes.append(AgentHealthEpisode(
                    episodeID: "health-\(profile.agentID.rawValue)-t\(tick)-\(dominant.rawValue)",
                    cause: dominant,
                    startedAtTick: tick,
                    endedAtTick: nil,
                    lastUpdatedTick: tick,
                    worstCondition: profile.condition,
                    trend: profile.trend,
                    lastEventID: eventID
                ))
            }
        } else if !profile.recentEpisodes.isEmpty,
                  profile.recentEpisodes[profile.recentEpisodes.count - 1].endedAtTick == nil {
            if healthConditionRank(profile.condition)
                > healthConditionRank(
                    profile.recentEpisodes[profile.recentEpisodes.count - 1].worstCondition
                ) {
                profile.recentEpisodes[profile.recentEpisodes.count - 1].worstCondition =
                    profile.condition
            }
            profile.recentEpisodes[profile.recentEpisodes.count - 1].lastUpdatedTick = tick
            profile.recentEpisodes[profile.recentEpisodes.count - 1].trend =
                profile.trend
            profile.recentEpisodes[profile.recentEpisodes.count - 1].lastEventID = eventID
        }
        if profile.recentEpisodes.count > configuration.maximumEpisodesPerProfile {
            let removed = profile.recentEpisodes.count
                - configuration.maximumEpisodesPerProfile
            profile.recentEpisodes.removeFirst(removed)
            profile.episodeEvictionCount += removed
        }
    }

    private func lifecycleStage(for agentID: AgentID, age: Int) -> AgentLifeStage {
        guard let lifecycle = lifecycleState else { return .mature }
        if age < lifecycle.configuration.newbornDurationTicks { return .newborn }
        if age < lifecycle.configuration.maturityAgeTicks { return .juvenile }
        return .mature
    }

    private func demographicAgeAtBoundary(
        for agentID: AgentID,
        tick boundaryTick: Int
    ) throws -> Int {
        guard let member = lifecycleState?.members.first(where: {
            $0.agentID == agentID
        }) else {
            throw AgentSessionError.homeostasis(.unknownAgent(agentID))
        }
        return try member.age(at: boundaryTick)
    }

    private func physiologicalAgeBand(
        age: Int,
        stage: AgentLifeStage,
        vulnerabilityStart: Int
    ) -> AgentPhysiologicalAgeBand {
        switch stage {
        case .newborn: return .dependent
        case .juvenile: return .juvenile
        case .mature:
            return age < vulnerabilityStart ? .prime : .laterLife
        }
    }

    private func healthCondition(
        health: Int,
        energy: Int,
        stress: Int,
        incapacityThreshold: Int
    ) -> AgentHealthCondition {
        if health <= 0 { return .dead }
        if health <= incapacityThreshold && health > 0 {
            return .incapacitated
        }
        if health <= 35 || energy <= 1_500 || stress >= 9_000 {
            return .critical
        }
        if health <= 60 || energy <= 3_500 || stress >= 7_000 {
            return .impaired
        }
        if health <= 85 || energy <= 6_000 || stress >= 4_000 {
            return .strained
        }
        return .stable
    }

    private func healthConditionRank(_ condition: AgentHealthCondition) -> Int {
        switch condition {
        case .stable: return 0
        case .strained: return 1
        case .impaired: return 2
        case .critical: return 3
        case .incapacitated: return 4
        case .dead: return 5
        }
    }

    private func basisPoints(_ value: Double) -> Int {
        Int((min(1, max(0, value)) * 10_000).rounded())
    }

    static func validateHomeostasisState(
        _ state: AgentHomeostasisState,
        agents: [AgentSessionAgentState],
        lifecycle: AgentLifecycleState?,
        autonomy: AgentAutonomousActivityState?,
        pendingMortalityAgentIDs: Set<AgentID>,
        clock: AgentSimulationClock,
        causalLatestSequence: UInt64
    ) throws {
        _ = try AgentHomeostasisConfiguration(
            maximumProfiles: state.configuration.maximumProfiles,
            maximumFactorsPerProfile:
                state.configuration.maximumFactorsPerProfile,
            maximumEpisodesPerProfile:
                state.configuration.maximumEpisodesPerProfile,
            maximumRetainedTransitions:
                state.configuration.maximumRetainedTransitions,
            ageVulnerabilityStartTicks:
                state.configuration.ageVulnerabilityStartTicks,
            ageVulnerabilityPerTickBasisPoints:
                state.configuration.ageVulnerabilityPerTickBasisPoints,
            maximumAgeVulnerabilityBasisPoints:
                state.configuration.maximumAgeVulnerabilityBasisPoints,
            recoveryPerTick: state.configuration.recoveryPerTick,
            stressRecoveryPerTick:
                state.configuration.stressRecoveryPerTick,
            baseHealthDamagePerTick:
                state.configuration.baseHealthDamagePerTick,
            healthRecoveryPerTick:
                state.configuration.healthRecoveryPerTick,
            incapacityHealthThreshold:
                state.configuration.incapacityHealthThreshold
        )
        guard let lifecycle else {
            throw AgentCheckpointError.invalidBound("homeostasis lifecycle")
        }
        let activeIDs = Set(agents.map(\.agentID))
        let profileIDs = state.profiles.map(\.agentID)
        let activeActivities = Set(
            autonomy?.activeActivities.map(\.candidate.actorID) ?? []
        )
        guard state.profiles.count <= state.configuration.maximumProfiles,
              Set(profileIDs) == activeIDs,
              Set(profileIDs).count == profileIDs.count,
              state.recentTransitions.count
                <= state.configuration.maximumRetainedTransitions,
              state.totalTransitionCount
                == state.recentTransitions.count + state.transitionEvictionCount,
              state.transitionEvictionCount >= 0,
              state.initializedEventID.simulationID == clock.simulationID,
              state.lastEventID.simulationID == clock.simulationID,
              state.lastEventID.sequence.rawValue <= causalLatestSequence,
              Set(state.recentTransitions.map(\.eventID)).count
                == state.recentTransitions.count else {
            throw AgentCheckpointError.invalidBound("homeostasis")
        }
        for profile in state.profiles {
            guard let agent = agents.first(where: {
                $0.agentID == profile.agentID
            }), let member = lifecycle.members.first(where: {
                $0.agentID == profile.agentID
            }) else {
                throw AgentCheckpointError.invalidReference(
                    profile.agentID.rawValue
                )
            }
            let age = try member.age(at: clock.tick.rawValue)
            let isPendingMortality = pendingMortalityAgentIDs.contains(
                profile.agentID
            )
            guard (isPendingMortality
                    ? (profile.vitalStatus == .dead
                        && profile.condition == .dead
                        && agent.health == 0
                        && !activeActivities.contains(profile.agentID))
                    : (profile.vitalStatus != .dead
                        && profile.condition != .dead
                        && agent.health > 0)),
                  profile.ageTicks == age,
                  profile.lifeStage == member.currentStage,
                  (0...10_000).contains(profile.energyReserveBasisPoints),
                  (0...10_000).contains(profile.stressBasisPoints),
                  (0...10_000).contains(
                    profile.recoveryCapacityBasisPoints
                  ),
                  (0...state.configuration.maximumAgeVulnerabilityBasisPoints)
                    .contains(profile.ageVulnerabilityBasisPoints),
                  profile.lastUpdatedTick >= 0,
                  profile.lastUpdatedTick <= clock.tick.rawValue,
                  profile.lastEventID.simulationID == clock.simulationID,
                  profile.lastEventID.sequence.rawValue <= causalLatestSequence,
                  profile.activeFactors.count
                    <= state.configuration.maximumFactorsPerProfile,
                  Set(profile.activeFactors.map(\.code)).count
                    == profile.activeFactors.count,
                  profile.activeFactors.allSatisfy({
                      (0...10_000).contains($0.severityBasisPoints)
                          && !$0.source.isEmpty
                  }),
                  profile.recentEpisodes.count
                    <= state.configuration.maximumEpisodesPerProfile,
                  profile.episodeEvictionCount >= 0,
                  profile.recentEpisodes.allSatisfy({
                      $0.startedAtTick >= 0
                          && $0.startedAtTick <= profile.lastUpdatedTick
                          && $0.lastUpdatedTick >= $0.startedAtTick
                          && $0.lastUpdatedTick <= profile.lastUpdatedTick
                          && ($0.endedAtTick == nil
                              || ($0.endedAtTick! >= $0.startedAtTick
                                  && $0.endedAtTick! == $0.lastUpdatedTick))
                          && $0.lastEventID.simulationID
                              == clock.simulationID
                          && $0.lastEventID.sequence.rawValue
                              <= causalLatestSequence
                  }),
                  profile.vitalStatus != .incapacitated
                    || (!activeActivities.contains(profile.agentID)
                        && agent.health
                            <= state.configuration.incapacityHealthThreshold)
            else {
                throw AgentCheckpointError.invalidBound(
                    "homeostasis profile \(profile.agentID.rawValue)"
                )
            }
        }
        for transition in state.recentTransitions {
            guard transition.tick >= 0,
                  transition.tick <= clock.tick.rawValue,
                  transition.eventID.simulationID == clock.simulationID,
                  transition.eventID.sequence.rawValue <= causalLatestSequence,
                  (0...100).contains(transition.healthBefore),
                  (0...100).contains(transition.healthAfter),
                  (0...10_000).contains(
                    transition.energyReserveBasisPoints
                  ),
                  (0...10_000).contains(transition.stressBasisPoints),
                  !transition.reason.isEmpty,
                  transition.reason.count <= 512 else {
                throw AgentCheckpointError.invalidBound(
                    "homeostasis transition"
                )
            }
        }
    }
}
