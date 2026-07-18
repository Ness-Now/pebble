extension AgentSimulationSession {
    public var dependentCareEnabled: Bool { dependentCareState != nil }

    public func dependentCareSnapshot() -> AgentDependentCareSnapshot {
        guard let state = dependentCareState else {
            return AgentDependentCareSnapshot(
                enabled: false, configuration: nil, assignments: [], activeNeeds: [],
                activeEngagements: [], terminalOutcomes: [], atRiskDependentIDs: [],
                totalAssignmentCount: 0, totalNeedCount: 0, totalEngagementCount: 0,
                totalOutcomeCount: 0, evictionCounts: AgentCareEvictionCounts(),
                digest: AgentDependentCareDigest.make("disabled")
            )
        }
        let assignments = state.assignments.sorted(by: careAssignmentSort)
        let needs = state.activeNeeds.sorted(by: careNeedSort)
        let engagements = state.activeEngagements.sorted(by: careEngagementSort)
        let activeDependents = Set(assignments.compactMap {
            $0.status == .active ? $0.dependentID : nil
        })
        let atRisk = dependentLifecycleIDs().filter { !activeDependents.contains($0) }
        return AgentDependentCareSnapshot(
            enabled: true, configuration: state.configuration,
            assignments: assignments, activeNeeds: needs,
            activeEngagements: engagements,
            terminalOutcomes: state.terminalOutcomes,
            atRiskDependentIDs: atRisk,
            totalAssignmentCount: state.totalAssignmentCount,
            totalNeedCount: state.totalNeedCount,
            totalEngagementCount: state.totalEngagementCount,
            totalOutcomeCount: state.totalOutcomeCount,
            evictionCounts: state.evictionCounts,
            digest: dependentCareDigest(state)
        )
    }

    public func currentCareAssignment(
        for dependentID: AgentID
    ) throws -> AgentCareAssignment? {
        guard let state = dependentCareState else { return nil }
        guard historicalPerson(for: dependentID) != nil else {
            throw AgentSessionError.dependentCare(.unknownDependent(dependentID))
        }
        return state.assignments.first {
            $0.dependentID == dependentID && $0.status == .active
        }
    }

    public func activeCareNeeds(for dependentID: AgentID) throws -> [AgentCareNeed] {
        guard let state = dependentCareState else { return [] }
        guard historicalPerson(for: dependentID) != nil else {
            throw AgentSessionError.dependentCare(.unknownDependent(dependentID))
        }
        return state.activeNeeds.filter { $0.dependentID == dependentID }
            .sorted(by: careNeedSort)
    }

    public func stageCapabilityPolicy(for agentID: AgentID) throws -> AgentStageCapabilityPolicy {
        guard let member = lifecycleState?.members.first(where: { $0.agentID == agentID }) else {
            throw AgentSessionError.dependentCare(.unknownDependent(agentID))
        }
        return AgentStageCapabilityPolicy.policy(for: member.currentStage)
    }

    func requireStageCapability(
        _ capability: AgentStageCapability,
        for agentID: AgentID
    ) throws {
        guard dependentCareState != nil else { return }
        let policy = try stageCapabilityPolicy(for: agentID)
        guard policy.permits(capability) else {
            throw AgentSessionError.dependentCare(.capabilityDenied(agentID, capability))
        }
    }

    func permitsStageCapability(
        _ capability: AgentStageCapability,
        for agentID: AgentID
    ) -> Bool {
        guard dependentCareState != nil else { return true }
        return (try? stageCapabilityPolicy(for: agentID).permits(capability)) == true
    }

    public func careTarget(for caregiverID: AgentID) -> AgentID? {
        activeCareEngagement(for: caregiverID)?.dependentID
    }

    public func careEngagement(for caregiverID: AgentID) -> AgentCareEngagement? {
        activeCareEngagement(for: caregiverID)
    }

    public mutating func setDependentCareEnabled(
        _ enabled: Bool,
        configuration: AgentDependentCareConfiguration = .live
    ) throws {
        if enabled {
            var candidate = self
            try candidate.initializeDependentCareInPlace(configuration: configuration)
            try candidate.validateDependentCareCrossDomainIfEnabled()
            self = candidate
        } else if dependentCareState != nil {
            throw AgentSessionError.dependentCare(.unsafeDisable)
        }
    }

    func activeCareEngagement(for caregiverID: AgentID) -> AgentCareEngagement? {
        guard let state = dependentCareState else { return nil }
        let needsByID = Dictionary(uniqueKeysWithValues: state.activeNeeds.map {
            ($0.needID, $0)
        })
        return state.activeEngagements.filter {
            $0.caregiverID == caregiverID && needsByID[$0.needID]?.status == .active
        }.sorted { lhs, rhs in
            let lhsPriority = careExecutionPriority(lhs.kind)
            let rhsPriority = careExecutionPriority(rhs.kind)
            if lhsPriority != rhsPriority { return lhsPriority < rhsPriority }
            if lhs.dependentID != rhs.dependentID { return lhs.dependentID < rhs.dependentID }
            return lhs.engagementID < rhs.engagementID
        }.first
    }

    func dependentCareForcedGoal(
        for agentID: AgentID,
        stage: AgentLifeStage?
    ) -> AgentGoalKind? {
        guard dependentCareState != nil, let stage else { return nil }
        switch stage {
        case .newborn:
            return .idle
        case .juvenile:
            guard let state = statesById[agentID.rawValue] else { return .idle }
            if state.resourceInventory.count(of: .foodRaw) > 0,
               state.needs.hunger >= configuration.survivalConfiguration.hungryThreshold {
                return .satisfyHunger
            }
            return state.position == state.homePosition ? .idle : .dependentReturnHome
        case .mature:
            return activeCareEngagement(for: agentID) == nil ? nil : .provideDependentCare
        }
    }

    mutating func applyDependentCareTickBoundary(at careTick: Int) throws {
        guard var care = dependentCareState else { return }
        if care.transitionTick != careTick {
            care.transitionTick = careTick
            care.transitionsAtTick = 0
        }
        let dependentIDs = dependentLifecycleIDs()
        let dependentSet = Set(dependentIDs)
        let staleAssignments = care.assignments.indices.filter {
            care.assignments[$0].status == .active
                && !dependentSet.contains(care.assignments[$0].dependentID)
        }.sorted { care.assignments[$0].dependentID < care.assignments[$1].dependentID }
        for index in staleAssignments {
            try endCareAssignment(
                at: index, reason: .dependentMatured,
                causeEventID: care.lastCareEventID, tick: careTick, state: &care
            )
        }
        let staleNeedIDs = Set(care.activeNeeds.compactMap { need in
            dependentSet.contains(need.dependentID) ? nil : need.needID
        })
        for needID in staleNeedIDs.sorted() {
            try closeCareNeed(
                needID: needID, reason: .dependentMatured,
                caregiverID: nil, tick: careTick, state: &care
            )
        }

        for dependentID in dependentIDs {
            var activeIndex = care.assignments.firstIndex {
                $0.dependentID == dependentID && $0.status == .active
            }
            if let index = activeIndex,
               !careAssignmentRemainsEligible(care.assignments[index]) {
                try endCareAssignment(
                    at: index, reason: .householdSeparated,
                    causeEventID: care.lastCareEventID, tick: careTick, state: &care
                )
                activeIndex = nil
            }
            if activeIndex == nil,
               let caregiverID = deterministicCaregiver(
                   for: dependentID, configuration: care.configuration, excluding: []
               ) {
                guard let caregiverMembership = try currentMembership(of: caregiverID),
                      let dependentMembership = try currentMembership(of: dependentID) else {
                    throw AgentSessionError.dependentCare(.unknownDependent(dependentID))
                }
                if caregiverMembership.householdID != dependentMembership.householdID {
                    try moveMembersInPlace(
                        memberIDs: [dependentID], to: caregiverMembership.householdID
                    )
                }
                try startCareAssignment(
                    dependentID: dependentID, caregiverID: caregiverID,
                    householdID: caregiverMembership.householdID,
                    causeEventID: care.lastCareEventID, tick: careTick, state: &care
                )
            }

            let assignment = care.assignments.first {
                $0.dependentID == dependentID && $0.status == .active
            }
            guard let dependent = statesById[dependentID.rawValue],
                  let stage = lifecycleState?.members.first(where: {
                      $0.agentID == dependentID
                  })?.currentStage else { continue }
            if dependent.needs.hunger >= care.configuration.nourishmentHungerThreshold {
                try raiseCareNeedIfNeeded(
                    dependentID: dependentID, kind: .nourishment,
                    severity: min(100, Int((dependent.needs.hunger * 100).rounded())),
                    caregiverID: assignment?.caregiverID, tick: careTick, state: &care
                )
            }
            let lastSupervision = care.terminalOutcomes.reversed().first {
                $0.dependentID == dependentID && $0.kind == .supervision
            }?.tick
            if !care.activeNeeds.contains(where: {
                $0.dependentID == dependentID && $0.kind == .supervision
            }), lastSupervision == nil
                || careTick - lastSupervision! >= care.configuration.supervisionIntervalTicks {
                try raiseCareNeedIfNeeded(
                    dependentID: dependentID, kind: .supervision,
                    severity: stage == .newborn ? 60 : 30,
                    caregiverID: assignment?.caregiverID, tick: careTick, state: &care
                )
            }
            if stage == .juvenile,
               manhattanDistance(dependent.position, dependent.homePosition)
                > care.configuration.careInteractionDistance {
                try raiseCareNeedIfNeeded(
                    dependentID: dependentID, kind: .returnHome, severity: 50,
                    caregiverID: assignment?.caregiverID, tick: careTick, state: &care
                )
            }
        }

        let openAssignments = Dictionary(uniqueKeysWithValues: care.assignments.compactMap {
            $0.status == .active ? ($0.dependentID, $0) : nil
        })
        for index in care.activeNeeds.indices.sorted(by: {
            careNeedSort(care.activeNeeds[$0], care.activeNeeds[$1])
        }) {
            let dependentID = care.activeNeeds[index].dependentID
            guard let assignment = openAssignments[dependentID] else {
                if care.activeNeeds[index].status != .unmet {
                    let unmet = try requiredDependentCareEvent(
                        kind: .careNeedUnmet, subjectID: dependentID,
                        causes: [care.activeNeeds[index].raisedEventID, care.lastCareEventID].sorted(),
                        payload: carePayload(
                            dependentID: dependentID, caregiverID: nil,
                            householdID: (try? currentMembership(of: dependentID))??.householdID,
                            need: (care.activeNeeds[index].needID, care.activeNeeds[index].kind),
                            assignmentCount: care.assignments.count,
                            needCount: care.activeNeeds.count, status: "unmet",
                            reason: "noCaregiver", materialQuantity: 0,
                            digest: care.rollingDigest
                        ),
                        summary: "care need unmet id=\(care.activeNeeds[index].needID.rawValue) reason=noCaregiver",
                        instant: careInstant(careTick)
                    )
                    care.activeNeeds[index].status = .unmet
                    care.lastCareEventID = unmet.eventID
                    try countCareTransition(&care, at: careTick)
                }
                continue
            }
            care.activeNeeds[index].assignedCaregiverID = assignment.caregiverID
            if care.activeNeeds[index].status == .unmet {
                let foodAvailable = care.activeNeeds[index].kind != .nourishment
                    || statesById[assignment.caregiverID.rawValue]!.resourceInventory
                        .count(of: .foodRaw) > 0
                    || campStock.count(of: .foodRaw) > 0
                guard foodAvailable else { continue }
                care.activeNeeds[index].status = .active
            }
            guard !care.activeEngagements.contains(where: {
                $0.needID == care.activeNeeds[index].needID
            }) else { continue }
            guard care.activeEngagements.count < care.configuration.maximumActiveEngagements else {
                throw AgentSessionError.dependentCare(.invalidState("engagement capacity"))
            }
            let engagementID = AgentCareEngagementID(
                rawValue: "care-engagement-\(String(format: "%08d", care.totalEngagementCount + 1))"
            )!
            let kind: AgentCareEngagementKind
            switch care.activeNeeds[index].kind {
            case .nourishment: kind = .provideFood
            case .supervision: kind = .supervise
            case .returnHome: kind = .assistReturnHome
            }
            let started = try requiredDependentCareEvent(
                kind: .careEngagementStarted,
                actorID: assignment.caregiverID, subjectID: dependentID,
                causes: [care.activeNeeds[index].raisedEventID, assignment.startedEventID].sorted(),
                payload: carePayload(
                    dependentID: dependentID, caregiverID: assignment.caregiverID,
                    householdID: assignment.householdID,
                    need: (care.activeNeeds[index].needID, care.activeNeeds[index].kind),
                    assignmentCount: care.assignments.count,
                    needCount: care.activeNeeds.count, status: "engaged",
                    reason: kind.rawValue, materialQuantity: 0, digest: care.rollingDigest
                ),
                summary: "care engagement started id=\(engagementID.rawValue)",
                instant: careInstant(careTick)
            )
            care.activeEngagements.append(AgentCareEngagement(
                engagementID: engagementID, needID: care.activeNeeds[index].needID,
                dependentID: dependentID, caregiverID: assignment.caregiverID,
                kind: kind, startedTick: careTick, startedEventID: started.eventID
            ))
            care.totalEngagementCount += 1
            care.lastCareEventID = started.eventID
            try countCareTransition(&care, at: careTick)
        }
        care.assignments.sort(by: careAssignmentSort)
        care.activeNeeds.sort(by: careNeedSort)
        care.activeEngagements.sort(by: careEngagementSort)
        care.rollingDigest = AgentDependentCareDigest.make(
            "\(care.rollingDigest)|tick|\(careTick)|\(care.assignments.count)|\(care.activeNeeds.count)|\(care.activeEngagements.count)"
        )
        dependentCareState = care
    }

    @discardableResult
    public mutating func provideDependentNourishment(
        _ intent: AgentCareProvisionIntent
    ) throws -> AgentCareProvisionResult {
        var candidate = self
        let result = try candidate.provideDependentNourishmentInPlace(intent)
        try candidate.validateDependentCareCrossDomainIfEnabled()
        self = candidate
        return result
    }

    private mutating func provideDependentNourishmentInPlace(
        _ intent: AgentCareProvisionIntent
    ) throws -> AgentCareProvisionResult {
        guard var care = dependentCareState else {
            throw AgentSessionError.dependentCare(.invalidNeed(intent.needID.rawValue))
        }
        guard intent.tick == tick,
              let needIndex = care.activeNeeds.firstIndex(where: {
                  $0.needID == intent.needID && $0.dependentID == intent.dependentID
                      && $0.kind == .nourishment
              }),
              let engagement = care.activeEngagements.first(where: {
                  $0.needID == intent.needID && $0.caregiverID == intent.caregiverID
              }),
              let assignment = care.assignments.first(where: {
                  $0.dependentID == intent.dependentID
                      && $0.caregiverID == intent.caregiverID && $0.status == .active
              }),
              var caregiver = statesById[intent.caregiverID.rawValue],
              var dependent = statesById[intent.dependentID.rawValue] else {
            throw AgentSessionError.dependentCare(.invalidNeed(intent.needID.rawValue))
        }
        guard manhattanDistance(caregiver.position, dependent.position)
                <= care.configuration.careInteractionDistance else {
            throw AgentSessionError.dependentCare(.interactionTooFar)
        }
        try prevalidateCausalAppend(count: skillsEnabled ? 4 : 3)
        let inventoryFoodBefore = caregiver.resourceInventory.count(of: .foodRaw)
        let campFoodBefore = campStock.count(of: .foodRaw)
        let source: AgentCareFoodSource
        if inventoryFoodBefore > 0 { source = .caregiverInventory }
        else if campFoodBefore > 0 { source = .campStock }
        else { source = .none }
        let hungerBefore = dependent.needs.hunger
        if source == .none {
            let unmet = try requiredDependentCareEvent(
                kind: .careNeedUnmet, actorID: intent.caregiverID,
                subjectID: intent.dependentID,
                causes: [engagement.startedEventID],
                payload: carePayload(
                    dependentID: intent.dependentID, caregiverID: intent.caregiverID,
                    householdID: assignment.householdID,
                    need: (intent.needID, .nourishment),
                    assignmentCount: care.assignments.count,
                    needCount: care.activeNeeds.count, status: "unmet",
                    reason: "foodUnavailable", materialQuantity: 0,
                    digest: care.rollingDigest
                ),
                summary: "care nourishment unmet need=\(intent.needID.rawValue) foodUnavailable"
            )
            care.activeNeeds[needIndex].status = .unmet
            care.activeEngagements.removeAll { $0.needID == intent.needID }
            care.lastCareEventID = unmet.eventID
            try countCareTransition(&care, at: tick)
            dependentCareState = care
            return AgentCareProvisionResult(
                provisionID: intent.provisionID, needID: intent.needID,
                caregiverID: intent.caregiverID, dependentID: intent.dependentID,
                tick: tick, succeeded: false, foodSource: .none,
                foodBefore: 0, foodAfter: 0, consumedByDependent: 0,
                hungerBefore: hungerBefore, hungerAfter: hungerBefore,
                reason: "no real foodRaw available"
            )
        }
        var inventory = caregiver.resourceInventory
        var stock = campStock
        let removed = source == .caregiverInventory
            ? inventory.remove(.foodRaw, quantity: 1)
            : stock.remove(.foodRaw, quantity: 1)
        var consumed = consumedResourceTotals
        guard removed, consumed.add(.foodRaw, quantity: 1) else {
            throw AgentSessionError.dependentCare(.materialDebitRequired)
        }
        let hungerAfter = max(
            0, hungerBefore - configuration.survivalConfiguration.foodNutrition
        )
        caregiver.resourceInventory = inventory
        dependent.needs.hunger = hungerAfter
        if var progress = dependent.survivalProgress {
            progress.consecutiveCriticalHungerTicks = 0
            progress.foodConsumedCount = min(
                AgentSurvivalProgress.maximumEventCount, progress.foodConsumedCount + 1
            )
            progress.status = hungerAfter <= configuration.survivalConfiguration
                .hungerRecoveryThreshold ? .stable : .hungry
            dependent.survivalProgress = progress
        }
        appendMemory(AgentMemoryEntry(
            tick: tick, type: "food_consumed",
            summary: "\(intent.dependentID.rawValue) received 1 foodRaw from \(intent.caregiverID.rawValue)",
            importance: 0.50
        ), to: &dependent.memory)
        statesById[intent.caregiverID.rawValue] = caregiver
        statesById[intent.dependentID.rawValue] = dependent
        campStock = stock
        consumedResourceTotals = consumed
        let material = try recordCausalEvent(
            kind: .consumption, origin: .worldOutcome,
            actorID: intent.caregiverID, subjectID: intent.dependentID,
            operationID: AgentOperationID(rawValue: intent.provisionID),
            causes: [engagement.startedEventID],
            payload: .operation(
                status: "succeeded",
                detail: "provider=\(intent.caregiverID.rawValue) consumer=\(intent.dependentID.rawValue) source=\(source.rawValue) quantity=1"
            ),
            summary: "care material consumption provider=\(intent.caregiverID.rawValue) consumer=\(intent.dependentID.rawValue)"
        )!
        let provided = try requiredDependentCareEvent(
            kind: .careProvided, actorID: intent.caregiverID,
            subjectID: intent.dependentID, causes: [material.eventID],
            payload: carePayload(
                dependentID: intent.dependentID, caregiverID: intent.caregiverID,
                householdID: assignment.householdID,
                need: (intent.needID, .nourishment),
                assignmentCount: care.assignments.count,
                needCount: care.activeNeeds.count, status: "provided",
                reason: source.rawValue, materialQuantity: 1,
                digest: care.rollingDigest
            ),
            summary: "care provided need=\(intent.needID.rawValue) quantity=1"
        )
        let skillEventID = try creditPracticeAfterMaterialSuccess(
            agentID: intent.caregiverID,
            domain: .caregiving,
            sourceSuccessEventID: provided.eventID
        )
        let resolved = try requiredDependentCareEvent(
            kind: .careNeedResolved, actorID: intent.caregiverID,
            subjectID: intent.dependentID, causes: [skillEventID ?? provided.eventID],
            payload: carePayload(
                dependentID: intent.dependentID, caregiverID: intent.caregiverID,
                householdID: assignment.householdID,
                need: (intent.needID, .nourishment),
                assignmentCount: care.assignments.count,
                needCount: care.activeNeeds.count - 1, status: "resolved",
                reason: "provided", materialQuantity: 1, digest: care.rollingDigest
            ),
            summary: "care need resolved id=\(intent.needID.rawValue)"
        )
        care.activeNeeds.remove(at: needIndex)
        care.activeEngagements.removeAll { $0.needID == intent.needID }
        appendCareOutcome(AgentCareOutcome(
            needID: intent.needID, dependentID: intent.dependentID,
            caregiverID: intent.caregiverID, kind: .nourishment, status: .resolved,
            terminalReason: .provided, tick: tick, foodSource: source,
            materialQuantity: 1, hungerBefore: hungerBefore, hungerAfter: hungerAfter,
            terminalEventID: resolved.eventID
        ), state: &care)
        care.lastCareEventID = resolved.eventID
        try countCareTransition(&care, at: tick, count: 2)
        care.rollingDigest = AgentDependentCareDigest.make(
            "\(care.rollingDigest)|food|\(intent.dependentID.rawValue)|\(source.rawValue)|1|\(hungerBefore)>\(hungerAfter)|\(tick)"
        )
        dependentCareState = care
        guard conservationSnapshot().balanced else {
            throw AgentSessionError.dependentCare(.materialDebitRequired)
        }
        let foodBefore = source == .caregiverInventory ? inventoryFoodBefore : campFoodBefore
        let foodAfter = source == .caregiverInventory
            ? caregiver.resourceInventory.count(of: .foodRaw)
            : campStock.count(of: .foodRaw)
        return AgentCareProvisionResult(
            provisionID: intent.provisionID, needID: intent.needID,
            caregiverID: intent.caregiverID, dependentID: intent.dependentID,
            tick: tick, succeeded: true, foodSource: source,
            foodBefore: foodBefore, foodAfter: foodAfter, consumedByDependent: 1,
            hungerBefore: hungerBefore, hungerAfter: hungerAfter,
            reason: "one real foodRaw debited and consumed atomically"
        )
    }

    @discardableResult
    public mutating func completeDependentCareInteraction(
        caregiverID: AgentID,
        dependentID: AgentID
    ) throws -> Bool {
        var candidate = self
        let completed = try candidate.completeDependentCareInteractionInPlace(
            caregiverID: caregiverID, dependentID: dependentID
        )
        try candidate.validateDependentCareCrossDomainIfEnabled()
        self = candidate
        return completed
    }

    private mutating func completeDependentCareInteractionInPlace(
        caregiverID: AgentID,
        dependentID: AgentID
    ) throws -> Bool {
        guard var care = dependentCareState,
              let engagement = care.activeEngagements.first(where: {
                  $0.caregiverID == caregiverID && $0.dependentID == dependentID
                      && $0.kind != .provideFood
              }),
              let need = care.activeNeeds.first(where: { $0.needID == engagement.needID }),
              let caregiver = statesById[caregiverID.rawValue],
              let dependent = statesById[dependentID.rawValue] else { return false }
        guard manhattanDistance(caregiver.position, dependent.position)
                <= care.configuration.careInteractionDistance else {
            throw AgentSessionError.dependentCare(.interactionTooFar)
        }
        if need.kind == .returnHome, dependent.position != dependent.homePosition { return false }
        try prevalidateCausalAppend(count: 2)
        let assignment = care.assignments.first {
            $0.dependentID == dependentID && $0.status == .active
        }!
        let provided = try requiredDependentCareEvent(
            kind: .careProvided, actorID: caregiverID, subjectID: dependentID,
            causes: [engagement.startedEventID],
            payload: carePayload(
                dependentID: dependentID, caregiverID: caregiverID,
                householdID: assignment.householdID,
                need: (need.needID, need.kind), assignmentCount: care.assignments.count,
                needCount: care.activeNeeds.count, status: "provided",
                reason: engagement.kind.rawValue, materialQuantity: 0,
                digest: care.rollingDigest
            ), summary: "care provided need=\(need.needID.rawValue)"
        )
        let terminalReason: AgentCareNeedTerminalReason = need.kind == .supervision
            ? .supervised : .returnedHome
        let resolved = try requiredDependentCareEvent(
            kind: .careNeedResolved, actorID: caregiverID, subjectID: dependentID,
            causes: [provided.eventID],
            payload: carePayload(
                dependentID: dependentID, caregiverID: caregiverID,
                householdID: assignment.householdID,
                need: (need.needID, need.kind), assignmentCount: care.assignments.count,
                needCount: care.activeNeeds.count - 1, status: "resolved",
                reason: terminalReason.rawValue, materialQuantity: 0,
                digest: care.rollingDigest
            ), summary: "care need resolved id=\(need.needID.rawValue)"
        )
        care.activeNeeds.removeAll { $0.needID == need.needID }
        care.activeEngagements.removeAll { $0.needID == need.needID }
        appendCareOutcome(AgentCareOutcome(
            needID: need.needID, dependentID: dependentID, caregiverID: caregiverID,
            kind: need.kind, status: .resolved, terminalReason: terminalReason,
            tick: tick, foodSource: .none, materialQuantity: 0,
            hungerBefore: nil, hungerAfter: nil, terminalEventID: resolved.eventID
        ), state: &care)
        care.lastCareEventID = resolved.eventID
        try countCareTransition(&care, at: tick, count: 2)
        care.rollingDigest = AgentDependentCareDigest.make(
            "\(care.rollingDigest)|resolved|\(need.needID.rawValue)|\(tick)"
        )
        dependentCareState = care
        return true
    }

    private func careAssignmentRemainsEligible(
        _ assignment: AgentCareAssignment
    ) -> Bool {
        guard assignment.status == .active,
              let caregiver = statesById[assignment.caregiverID.rawValue],
              caregiver.health > 0,
              statesById[assignment.dependentID.rawValue] != nil,
              lifecycleState?.members.first(where: {
                  $0.agentID == assignment.caregiverID
              })?.currentStage == .mature,
              populationRegistry?.members.contains(where: {
                  $0.agentID == assignment.caregiverID
                      && ($0.status == .founderResident || $0.status == .resident)
              }) == true,
              !isMigratingAgent(assignment.caregiverID.rawValue),
              let dependentMembership = try? currentMembership(of: assignment.dependentID),
              let caregiverMembership = try? currentMembership(of: assignment.caregiverID),
              dependentMembership.householdID == assignment.householdID,
              caregiverMembership.householdID == assignment.householdID else { return false }
        return householdState?.households.contains {
            $0.householdID == assignment.householdID && $0.status == .active
        } == true
    }

    private mutating func startCareAssignment(
        dependentID: AgentID,
        caregiverID: AgentID,
        householdID: AgentHouseholdID,
        causeEventID: AgentCausalEventID,
        tick assignmentTick: Int,
        state: inout AgentDependentCareState
    ) throws {
        guard !state.assignments.contains(where: {
            $0.dependentID == dependentID && $0.status == .active
        }) else {
            throw AgentSessionError.dependentCare(.duplicateAssignment(dependentID))
        }
        guard state.assignments.count < state.configuration.maximumAssignments else {
            throw AgentSessionError.dependentCare(.assignmentCapacityReached)
        }
        let load = state.assignments.filter {
            $0.caregiverID == caregiverID && $0.status == .active
        }.count
        guard load < state.configuration.maximumDependentsPerCaregiver else {
            throw AgentSessionError.dependentCare(.caregiverCapacityReached(caregiverID))
        }
        guard lifecycleState?.members.first(where: {
            $0.agentID == caregiverID
        })?.currentStage == .mature else {
            throw AgentSessionError.dependentCare(.ineligibleCaregiver(caregiverID))
        }
        let started = try requiredDependentCareEvent(
            kind: .careAssignmentStarted, actorID: caregiverID, subjectID: dependentID,
            causes: [causeEventID],
            payload: carePayload(
                dependentID: dependentID, caregiverID: caregiverID,
                householdID: householdID, need: nil,
                assignmentCount: state.assignments.count + 1,
                needCount: state.activeNeeds.count, status: "started",
                reason: "deterministicReassignment", materialQuantity: 0,
                digest: state.rollingDigest
            ),
            summary: "care assignment started dependent=\(dependentID.rawValue) caregiver=\(caregiverID.rawValue)",
            instant: careInstant(assignmentTick)
        )
        state.assignments.append(AgentCareAssignment(
            dependentID: dependentID, caregiverID: caregiverID,
            householdID: householdID, startedTick: assignmentTick,
            startedEventID: started.eventID, endedTick: nil, endedEventID: nil,
            endedReason: nil, status: .active
        ))
        state.totalAssignmentCount += 1
        state.lastCareEventID = started.eventID
        for index in state.activeNeeds.indices where
            state.activeNeeds[index].dependentID == dependentID {
            state.activeNeeds[index].assignedCaregiverID = caregiverID
            if state.activeNeeds[index].status == .unmet {
                state.activeNeeds[index].status = .active
            }
        }
        try countCareTransition(&state, at: assignmentTick)
    }

    private mutating func endCareAssignment(
        at index: Int,
        reason: AgentCareAssignmentEndReason,
        causeEventID: AgentCausalEventID,
        tick assignmentTick: Int,
        state: inout AgentDependentCareState
    ) throws {
        guard state.assignments.indices.contains(index),
              state.assignments[index].status == .active else { return }
        let assignment = state.assignments[index]
        let ended = try requiredDependentCareEvent(
            kind: .careAssignmentEnded, actorID: assignment.caregiverID,
            subjectID: assignment.dependentID,
            causes: [assignment.startedEventID, causeEventID].sorted(),
            payload: carePayload(
                dependentID: assignment.dependentID,
                caregiverID: assignment.caregiverID,
                householdID: assignment.householdID, need: nil,
                assignmentCount: state.assignments.count,
                needCount: state.activeNeeds.count, status: "ended",
                reason: reason.rawValue, materialQuantity: 0,
                digest: state.rollingDigest
            ),
            summary: "care assignment ended dependent=\(assignment.dependentID.rawValue) reason=\(reason.rawValue)",
            instant: careInstant(assignmentTick)
        )
        state.assignments[index].endedTick = assignmentTick
        state.assignments[index].endedEventID = ended.eventID
        state.assignments[index].endedReason = reason
        state.assignments[index].status = .ended
        state.activeEngagements.removeAll {
            $0.dependentID == assignment.dependentID
                && $0.caregiverID == assignment.caregiverID
        }
        for needIndex in state.activeNeeds.indices where
            state.activeNeeds[needIndex].dependentID == assignment.dependentID {
            state.activeNeeds[needIndex].assignedCaregiverID = nil
        }
        state.lastCareEventID = ended.eventID
        try countCareTransition(&state, at: assignmentTick)
    }

    private mutating func raiseCareNeedIfNeeded(
        dependentID: AgentID,
        kind: AgentCareNeedKind,
        severity: Int,
        caregiverID: AgentID?,
        tick needTick: Int,
        state: inout AgentDependentCareState
    ) throws {
        guard !state.activeNeeds.contains(where: {
            $0.dependentID == dependentID && $0.kind == kind
        }) else { return }
        guard state.activeNeeds.count < state.configuration.maximumActiveNeeds else {
            throw AgentSessionError.dependentCare(.needCapacityReached)
        }
        let needID = AgentCareNeedID(
            rawValue: "care-need-\(String(format: "%08d", state.totalNeedCount + 1))"
        )!
        let householdID = ((try? currentMembership(of: dependentID)) ?? nil)?.householdID
        let raised = try requiredDependentCareEvent(
            kind: .careNeedRaised, actorID: caregiverID, subjectID: dependentID,
            causes: [state.lastCareEventID],
            payload: carePayload(
                dependentID: dependentID, caregiverID: caregiverID,
                householdID: householdID, need: (needID, kind),
                assignmentCount: state.assignments.count,
                needCount: state.activeNeeds.count + 1, status: "active",
                reason: nil, materialQuantity: 0, digest: state.rollingDigest
            ),
            summary: "care need raised id=\(needID.rawValue) kind=\(kind.rawValue)",
            instant: careInstant(needTick)
        )
        state.activeNeeds.append(AgentCareNeed(
            needID: needID, dependentID: dependentID, kind: kind,
            severity: max(0, min(100, severity)), raisedTick: needTick,
            raisedEventID: raised.eventID, status: .active,
            assignedCaregiverID: caregiverID, resolvedTick: nil,
            terminalReason: nil, terminalEventID: nil
        ))
        state.totalNeedCount += 1
        state.lastCareEventID = raised.eventID
        try countCareTransition(&state, at: needTick)
    }

    private mutating func closeCareNeed(
        needID: AgentCareNeedID,
        reason: AgentCareNeedTerminalReason,
        caregiverID: AgentID?,
        tick needTick: Int,
        state: inout AgentDependentCareState
    ) throws {
        guard let index = state.activeNeeds.firstIndex(where: { $0.needID == needID }) else {
            return
        }
        let need = state.activeNeeds[index]
        let closed = try requiredDependentCareEvent(
            kind: .careNeedUnmet, actorID: caregiverID, subjectID: need.dependentID,
            causes: [need.raisedEventID, state.lastCareEventID].sorted(),
            payload: carePayload(
                dependentID: need.dependentID, caregiverID: caregiverID,
                householdID: ((try? currentMembership(of: need.dependentID)) ?? nil)?.householdID,
                need: (need.needID, need.kind),
                assignmentCount: state.assignments.count,
                needCount: state.activeNeeds.count - 1, status: "closed",
                reason: reason.rawValue, materialQuantity: 0,
                digest: state.rollingDigest
            ),
            summary: "care need closed id=\(need.needID.rawValue) reason=\(reason.rawValue)",
            instant: careInstant(needTick)
        )
        state.activeNeeds.remove(at: index)
        state.activeEngagements.removeAll { $0.needID == need.needID }
        appendCareOutcome(AgentCareOutcome(
            needID: need.needID, dependentID: need.dependentID,
            caregiverID: caregiverID, kind: need.kind, status: .closed,
            terminalReason: reason, tick: needTick, foodSource: .none,
            materialQuantity: 0, hungerBefore: nil, hungerAfter: nil,
            terminalEventID: closed.eventID
        ), state: &state)
        state.lastCareEventID = closed.eventID
        try countCareTransition(&state, at: needTick)
    }

    private func careInstant(_ rawTick: Int) -> AgentSimulationInstant {
        AgentSimulationInstant(
            simulationID: clock.simulationID,
            tick: AgentSimulationTick(rawValue: rawTick)!
        )
    }

    private func countCareTransition(
        _ state: inout AgentDependentCareState,
        at transitionTick: Int,
        count: Int = 1
    ) throws {
        if state.transitionTick != transitionTick {
            state.transitionTick = transitionTick
            state.transitionsAtTick = 0
        }
        guard count >= 0,
              state.transitionsAtTick + count
                <= state.configuration.maximumCareTransitionsPerTick else {
            throw AgentSessionError.dependentCare(.transitionCapacityReached)
        }
        state.transitionsAtTick += count
    }

    private func appendCareOutcome(
        _ outcome: AgentCareOutcome,
        state: inout AgentDependentCareState
    ) {
        state.terminalOutcomes.append(outcome)
        state.totalOutcomeCount += 1
        while state.terminalOutcomes.count > state.configuration.maximumRetainedOutcomes {
            let evicted = state.terminalOutcomes.removeFirst()
            state.evictionCounts.outcomes += 1
            state.rollingDigest = AgentDependentCareDigest.make(
                "\(state.rollingDigest)|evicted|\(evicted.needID.rawValue)|\(evicted.terminalEventID.rawValue)"
            )
        }
    }

    private mutating func initializeDependentCareInPlace(
        configuration: AgentDependentCareConfiguration
    ) throws {
        guard causalLedger.isEnabled else {
            throw AgentSessionError.dependentCare(.causalLedgerRequired)
        }
        guard dependentCareState == nil else {
            throw AgentSessionError.dependentCare(.alreadyEnabled)
        }
        guard populationRegistry != nil else {
            throw AgentSessionError.dependentCare(.populationRequired)
        }
        guard lifecycleState != nil else {
            throw AgentSessionError.dependentCare(.lifecycleRequired)
        }
        guard kinshipState != nil else {
            throw AgentSessionError.dependentCare(.kinshipRequired)
        }
        guard householdState != nil else {
            throw AgentSessionError.dependentCare(.householdsRequired)
        }
        guard survivalEnabled else {
            throw AgentSessionError.dependentCare(.survivalRequired)
        }
        let dependents = dependentLifecycleIDs()
        guard dependents.count <= configuration.maximumDependents else {
            throw AgentSessionError.dependentCare(.dependentCapacityReached)
        }
        guard dependents.count <= configuration.maximumAssignments else {
            throw AgentSessionError.dependentCare(.assignmentCapacityReached)
        }
        guard dependents.count <= configuration.maximumActiveNeeds else {
            throw AgentSessionError.dependentCare(.needCapacityReached)
        }
        guard dependents.count * 2 + 1 <= configuration.maximumCareTransitionsPerTick else {
            throw AgentSessionError.dependentCare(.transitionCapacityReached)
        }

        var selections: [(dependent: AgentID, caregiver: AgentID?, household: AgentHouseholdID)] = []
        var projectedLoads: [AgentID: Int] = [:]
        for dependentID in dependents {
            guard let current = try currentMembership(of: dependentID) else {
                throw AgentSessionError.dependentCare(.unknownDependent(dependentID))
            }
            let caregiver = deterministicCaregiver(
                for: dependentID,
                projectedLoads: projectedLoads,
                configuration: configuration,
                excluding: []
            )
            var targetHouseholdID = current.householdID
            if let caregiver,
               let caregiverMembership = try currentMembership(of: caregiver),
               caregiverMembership.householdID != current.householdID {
                try moveMembers(memberIDs: [dependentID], to: caregiverMembership.householdID)
                targetHouseholdID = caregiverMembership.householdID
            }
            if let caregiver { projectedLoads[caregiver, default: 0] += 1 }
            selections.append((dependentID, caregiver, targetHouseholdID))
        }

        try prevalidateCausalAppend(count: 1 + selections.count * 2)
        let initializationDigest = AgentDependentCareDigest.make(
            selections.map {
                "\($0.dependent.rawValue)>\($0.caregiver?.rawValue ?? "atRisk")@\($0.household.rawValue)"
            }.joined(separator: ";")
        )
        let initialized = try requiredDependentCareEvent(
            kind: .dependentCareInitialized,
            payload: carePayload(
                dependentID: nil, caregiverID: nil, householdID: nil,
                need: nil, assignmentCount: selections.compactMap(\.caregiver).count,
                needCount: selections.count, status: "initialized", reason: nil,
                materialQuantity: 0, digest: initializationDigest
            ),
            summary: "dependent care initialized dependents=\(selections.count)"
        )
        var state = AgentDependentCareState(
            configuration: configuration, assignments: [], activeNeeds: [],
            activeEngagements: [], terminalOutcomes: [], totalAssignmentCount: 0,
            totalNeedCount: 0, totalEngagementCount: 0, totalOutcomeCount: 0,
            transitionTick: tick, transitionsAtTick: 1,
            evictionCounts: AgentCareEvictionCounts(), rollingDigest: initializationDigest,
            initializedEventID: initialized.eventID, lastCareEventID: initialized.eventID
        )
        for selection in selections {
            var assignmentEventID: AgentCausalEventID?
            if let caregiverID = selection.caregiver {
                let started = try requiredDependentCareEvent(
                    kind: .careAssignmentStarted,
                    actorID: caregiverID, subjectID: selection.dependent,
                    causes: [state.lastCareEventID],
                    payload: carePayload(
                        dependentID: selection.dependent, caregiverID: caregiverID,
                        householdID: selection.household, need: nil,
                        assignmentCount: state.assignments.count + 1,
                        needCount: state.activeNeeds.count, status: "started",
                        reason: "initialization", materialQuantity: 0,
                        digest: state.rollingDigest
                    ),
                    summary: "care assignment started dependent=\(selection.dependent.rawValue) caregiver=\(caregiverID.rawValue)"
                )
                state.assignments.append(AgentCareAssignment(
                    dependentID: selection.dependent, caregiverID: caregiverID,
                    householdID: selection.household, startedTick: tick,
                    startedEventID: started.eventID, endedTick: nil, endedEventID: nil,
                    endedReason: nil, status: .active
                ))
                state.totalAssignmentCount += 1
                state.lastCareEventID = started.eventID
                state.transitionsAtTick += 1
                assignmentEventID = started.eventID
            }
            let needID = AgentCareNeedID(
                rawValue: "care-need-\(String(format: "%08d", state.totalNeedCount + 1))"
            )!
            let raised = try requiredDependentCareEvent(
                kind: .careNeedRaised,
                actorID: selection.caregiver, subjectID: selection.dependent,
                causes: [assignmentEventID ?? state.lastCareEventID],
                payload: carePayload(
                    dependentID: selection.dependent, caregiverID: selection.caregiver,
                    householdID: selection.household,
                    need: (needID, .supervision), assignmentCount: state.assignments.count,
                    needCount: state.activeNeeds.count + 1, status: "active",
                    reason: selection.caregiver == nil ? "noCaregiver" : "initialization",
                    materialQuantity: 0, digest: state.rollingDigest
                ),
                summary: "care need raised id=\(needID.rawValue) kind=supervision"
            )
            state.activeNeeds.append(AgentCareNeed(
                needID: needID, dependentID: selection.dependent, kind: .supervision,
                severity: selection.caregiver == nil ? 100 : 40, raisedTick: tick,
                raisedEventID: raised.eventID, status: .active,
                assignedCaregiverID: selection.caregiver, resolvedTick: nil,
                terminalReason: nil, terminalEventID: nil
            ))
            state.totalNeedCount += 1
            state.lastCareEventID = raised.eventID
            state.transitionsAtTick += 1
        }
        state.assignments.sort(by: careAssignmentSort)
        state.activeNeeds.sort(by: careNeedSort)
        state.rollingDigest = AgentDependentCareDigest.make(
            "\(state.rollingDigest)|initialized|\(state.assignments.count)|\(state.activeNeeds.count)|\(tick)"
        )
        dependentCareState = state
    }

    func deterministicCaregiver(
        for dependentID: AgentID,
        projectedLoads: [AgentID: Int] = [:],
        configuration: AgentDependentCareConfiguration? = nil,
        excluding: Set<AgentID>
    ) -> AgentID? {
        guard let household = try? currentMembership(of: dependentID),
              let kinship = kinshipState, let lifecycle = lifecycleState,
              let population = populationRegistry else { return nil }
        let limit = configuration?.maximumDependentsPerCaregiver
            ?? dependentCareState?.configuration.maximumDependentsPerCaregiver ?? 4
        let activeLoads = Dictionary(grouping: dependentCareState?.assignments.filter {
            $0.status == .active && $0.dependentID != dependentID
        } ?? [], by: \.caregiverID).mapValues(\.count)
        let parents = Set(kinship.parentageRecords.first {
            $0.childID == dependentID
        }?.canonicalParentIDs ?? [])
        let eligible = lifecycle.members.compactMap { member -> AgentID? in
            guard member.currentStage == .mature,
                  member.agentID != dependentID,
                  !excluding.contains(member.agentID),
                  let agent = statesById[member.agentID.rawValue], agent.health > 0,
                  population.members.contains(where: {
                      $0.agentID == member.agentID
                          && ($0.status == .founderResident || $0.status == .resident)
                  }),
                  !isMigratingAgent(member.agentID.rawValue),
                  (activeLoads[member.agentID] ?? 0) + (projectedLoads[member.agentID] ?? 0) < limit,
                  (try? currentMembership(of: member.agentID)) != nil else { return nil }
            return member.agentID
        }
        return eligible.sorted { lhs, rhs in
            let leftHousehold = (try? currentMembership(of: lhs))??.householdID
            let rightHousehold = (try? currentMembership(of: rhs))??.householdID
            func tier(_ id: AgentID, _ candidateHousehold: AgentHouseholdID?) -> Int {
                if parents.contains(id), candidateHousehold == household.householdID { return 0 }
                if candidateHousehold == household.householdID { return 1 }
                if parents.contains(id) { return 2 }
                return 3
            }
            let leftTier = tier(lhs, leftHousehold)
            let rightTier = tier(rhs, rightHousehold)
            if leftTier != rightTier { return leftTier < rightTier }
            let leftLoad = (activeLoads[lhs] ?? 0) + (projectedLoads[lhs] ?? 0)
            let rightLoad = (activeLoads[rhs] ?? 0) + (projectedLoads[rhs] ?? 0)
            if leftLoad != rightLoad { return leftLoad < rightLoad }
            return lhs < rhs
        }.first.flatMap { id in
            let membership = (try? currentMembership(of: id)) ?? nil
            let tier = parents.contains(id)
                ? (membership?.householdID == household.householdID ? 0 : 2)
                : (membership?.householdID == household.householdID ? 1 : 3)
            return tier < 3 ? id : nil
        }
    }

    func prevalidateDependentCareBirth(
        parentIDs: [AgentID]
    ) throws -> (caregiverID: AgentID, householdID: AgentHouseholdID)? {
        guard let care = dependentCareState else { return nil }
        guard parentIDs.count == 2 else {
            throw AgentSessionError.dependentCare(.invalidState("birth parents"))
        }
        guard care.assignments.count < care.configuration.maximumAssignments else {
            throw AgentSessionError.dependentCare(.assignmentCapacityReached)
        }
        guard care.assignments.filter({ $0.status == .active }).count
                < care.configuration.maximumDependents else {
            throw AgentSessionError.dependentCare(.dependentCapacityReached)
        }
        guard care.activeNeeds.count < care.configuration.maximumActiveNeeds else {
            throw AgentSessionError.dependentCare(.needCapacityReached)
        }
        var preview = care
        try countCareTransition(&preview, at: tick, count: 2)
        let loads = Dictionary(grouping: care.assignments.filter {
            $0.status == .active
        }, by: \.caregiverID).mapValues(\.count)
        let candidates = parentIDs.sorted().filter { parentID in
            lifecycleState?.members.first(where: {
                $0.agentID == parentID
            })?.currentStage == .mature
                && statesById[parentID.rawValue].map { $0.health > 0 } == true
                && populationRegistry?.members.contains(where: {
                    $0.agentID == parentID
                        && ($0.status == .founderResident || $0.status == .resident)
                }) == true
                && !isMigratingAgent(parentID.rawValue)
                && (loads[parentID] ?? 0)
                    < care.configuration.maximumDependentsPerCaregiver
        }.sorted {
            let left = loads[$0] ?? 0
            let right = loads[$1] ?? 0
            return left == right ? $0 < $1 : left < right
        }
        guard let caregiverID = candidates.first else {
            throw AgentSessionError.dependentCare(.invalidState("birth has no eligible parent caregiver"))
        }
        guard let membership = try currentMembership(of: caregiverID) else {
            throw AgentSessionError.dependentCare(.unknownCaregiver(caregiverID))
        }
        return (caregiverID, membership.householdID)
    }

    mutating func registerDependentCareBirth(
        childID: AgentID,
        caregiverID: AgentID,
        householdID: AgentHouseholdID,
        causeEventID: AgentCausalEventID
    ) throws -> AgentCausalEventID? {
        guard var care = dependentCareState else { return nil }
        try startCareAssignment(
            dependentID: childID, caregiverID: caregiverID,
            householdID: householdID, causeEventID: causeEventID,
            tick: tick, state: &care
        )
        try raiseCareNeedIfNeeded(
            dependentID: childID, kind: .supervision, severity: 60,
            caregiverID: caregiverID, tick: tick, state: &care
        )
        care.assignments.sort(by: careAssignmentSort)
        care.activeNeeds.sort(by: careNeedSort)
        care.rollingDigest = AgentDependentCareDigest.make(
            "\(care.rollingDigest)|birth|\(childID.rawValue)|\(caregiverID.rawValue)|\(householdID.rawValue)|\(tick)"
        )
        dependentCareState = care
        return care.lastCareEventID
    }

    mutating func applyDependentCareDeath(
        agentID: AgentID,
        lethalAgentIDs: Set<AgentID>,
        causeEventID: AgentCausalEventID,
        at deathTick: Int
    ) throws -> AgentCausalEventID? {
        guard var care = dependentCareState else { return nil }
        let deadAsDependent = care.assignments.indices.filter {
            care.assignments[$0].status == .active
                && care.assignments[$0].dependentID == agentID
        }
        for index in deadAsDependent {
            try endCareAssignment(
                at: index, reason: .dependentDied,
                causeEventID: causeEventID, tick: deathTick, state: &care
            )
        }
        let deadDependentNeedIDs = care.activeNeeds.compactMap {
            $0.dependentID == agentID ? $0.needID : nil
        }.sorted()
        for needID in deadDependentNeedIDs {
            try closeCareNeed(
                needID: needID, reason: .dependentDied,
                caregiverID: nil, tick: deathTick, state: &care
            )
        }

        let affectedDependents = care.assignments.compactMap { assignment in
            assignment.status == .active && assignment.caregiverID == agentID
                ? assignment.dependentID : nil
        }.sorted()
        for dependentID in affectedDependents {
            guard let index = care.assignments.firstIndex(where: {
                $0.status == .active && $0.dependentID == dependentID
                    && $0.caregiverID == agentID
            }) else { continue }
            try endCareAssignment(
                at: index, reason: .caregiverDied,
                causeEventID: causeEventID, tick: deathTick, state: &care
            )
            if let replacement = deterministicCaregiver(
                for: dependentID,
                configuration: care.configuration,
                excluding: lethalAgentIDs
            ), let replacementMembership = try currentMembership(of: replacement),
               let dependentMembership = try currentMembership(of: dependentID) {
                if replacementMembership.householdID != dependentMembership.householdID {
                    try moveMembersInPlace(
                        memberIDs: [dependentID], to: replacementMembership.householdID
                    )
                }
                try startCareAssignment(
                    dependentID: dependentID, caregiverID: replacement,
                    householdID: replacementMembership.householdID,
                    causeEventID: care.lastCareEventID,
                    tick: deathTick, state: &care
                )
            } else {
                for needIndex in care.activeNeeds.indices where
                    care.activeNeeds[needIndex].dependentID == dependentID {
                    care.activeNeeds[needIndex].assignedCaregiverID = nil
                    guard care.activeNeeds[needIndex].status != .unmet else { continue }
                    let need = care.activeNeeds[needIndex]
                    let unmet = try requiredDependentCareEvent(
                        kind: .careNeedUnmet, subjectID: dependentID,
                        causes: [need.raisedEventID, care.lastCareEventID].sorted(),
                        payload: carePayload(
                            dependentID: dependentID, caregiverID: nil,
                            householdID: ((try? currentMembership(of: dependentID)) ?? nil)?.householdID,
                            need: (need.needID, need.kind),
                            assignmentCount: care.assignments.count,
                            needCount: care.activeNeeds.count, status: "unmet",
                            reason: "caregiverDiedNoReplacement", materialQuantity: 0,
                            digest: care.rollingDigest
                        ),
                        summary: "care need unmet id=\(need.needID.rawValue) caregiver died",
                        instant: careInstant(deathTick)
                    )
                    care.activeNeeds[needIndex].status = .unmet
                    care.lastCareEventID = unmet.eventID
                    try countCareTransition(&care, at: deathTick)
                }
            }
        }
        care.assignments.sort(by: careAssignmentSort)
        care.activeNeeds.sort(by: careNeedSort)
        care.activeEngagements.sort(by: careEngagementSort)
        care.rollingDigest = AgentDependentCareDigest.make(
            "\(care.rollingDigest)|death|\(agentID.rawValue)|\(deathTick)"
        )
        dependentCareState = care
        return care.lastCareEventID
    }

    func validateDependentCareCrossDomainIfEnabled() throws {
        guard let state = dependentCareState else { return }
        guard let population = populationRegistry else {
            throw AgentSessionError.dependentCare(.populationRequired)
        }
        guard let lifecycle = lifecycleState else {
            throw AgentSessionError.dependentCare(.lifecycleRequired)
        }
        guard kinshipState != nil else {
            throw AgentSessionError.dependentCare(.kinshipRequired)
        }
        guard let households = householdState else {
            throw AgentSessionError.dependentCare(.householdsRequired)
        }
        guard survivalEnabled else {
            throw AgentSessionError.dependentCare(.survivalRequired)
        }
        do {
            try Self.validateDependentCareState(
                state, population: population, lifecycle: lifecycle,
                households: households,
                agents: statesById.values.sorted { $0.agentID < $1.agentID },
                clock: clock, causalLatestSequence: causalLedger.latestSequence,
                causalDroppedEventCount: causalLedger.droppedEventCount,
                causalEvents: causalLedger.events
            )
        } catch let error as AgentDependentCareError {
            throw AgentSessionError.dependentCare(error)
        }
    }

    static func validateDependentCareState(
        _ state: AgentDependentCareState,
        population: AgentPopulationRegistry,
        lifecycle: AgentLifecycleState,
        households: AgentHouseholdState,
        agents: [AgentSessionAgentState],
        clock: AgentSimulationClock,
        causalLatestSequence: UInt64,
        causalDroppedEventCount: UInt64,
        causalEvents: [AgentCausalEvent]
    ) throws {
        _ = try AgentDependentCareConfiguration(
            maximumDependents: state.configuration.maximumDependents,
            maximumAssignments: state.configuration.maximumAssignments,
            maximumActiveNeeds: state.configuration.maximumActiveNeeds,
            maximumActiveEngagements: state.configuration.maximumActiveEngagements,
            maximumRetainedOutcomes: state.configuration.maximumRetainedOutcomes,
            maximumDependentsPerCaregiver: state.configuration.maximumDependentsPerCaregiver,
            maximumCareTransitionsPerTick: state.configuration.maximumCareTransitionsPerTick,
            nourishmentHungerThreshold: state.configuration.nourishmentHungerThreshold,
            careInteractionDistance: state.configuration.careInteractionDistance,
            supervisionIntervalTicks: state.configuration.supervisionIntervalTicks
        )
        let activeIDs = Set(agents.map(\.agentID))
        let residents = Set(population.members.compactMap {
            $0.status == .founderResident || $0.status == .resident ? $0.agentID : nil
        })
        let stageByID = Dictionary(uniqueKeysWithValues: lifecycle.members.map {
            ($0.agentID, $0.currentStage)
        })
        let openMemberships = Dictionary(uniqueKeysWithValues: households.membershipPeriods
            .filter { $0.leftTick == nil }.map { ($0.agentID, $0.householdID) })
        let householdStatus = Dictionary(uniqueKeysWithValues: households.households.map {
            ($0.householdID, $0.status)
        })
        let openAssignments = state.assignments.filter { $0.status == .active }
        let activeNeedKeys = state.activeNeeds.map {
            "\($0.dependentID.rawValue)|\($0.kind.rawValue)"
        }
        guard state.assignments == state.assignments.sorted(by: careAssignmentSort),
              state.activeNeeds == state.activeNeeds.sorted(by: careNeedSort),
              state.activeEngagements == state.activeEngagements.sorted(by: careEngagementSort),
              state.terminalOutcomes == state.terminalOutcomes.sorted(by: {
                  if $0.tick != $1.tick { return $0.tick < $1.tick }
                  return $0.terminalEventID < $1.terminalEventID
              }),
              state.assignments.count <= state.configuration.maximumAssignments,
              state.activeNeeds.count <= state.configuration.maximumActiveNeeds,
              state.activeEngagements.count <= state.configuration.maximumActiveEngagements,
              state.terminalOutcomes.count <= state.configuration.maximumRetainedOutcomes,
              openAssignments.count <= state.configuration.maximumDependents,
              openAssignments.map(\.dependentID).count == Set(openAssignments.map(\.dependentID)).count,
              state.activeNeeds.map(\.needID).count == Set(state.activeNeeds.map(\.needID)).count,
              activeNeedKeys.count == Set(activeNeedKeys).count,
              state.activeEngagements.map(\.engagementID).count
                == Set(state.activeEngagements.map(\.engagementID)).count,
              state.activeEngagements.map(\.needID).count
                == Set(state.activeEngagements.map(\.needID)).count,
              state.totalAssignmentCount == state.assignments.count,
              state.totalNeedCount >= state.activeNeeds.count,
              state.totalEngagementCount >= state.activeEngagements.count,
              state.totalOutcomeCount == state.terminalOutcomes.count + state.evictionCounts.outcomes,
              state.transitionTick >= 0, state.transitionTick <= clock.tick.rawValue,
              state.transitionsAtTick >= 0,
              state.transitionsAtTick <= state.configuration.maximumCareTransitionsPerTick,
              state.initializedEventID.simulationID == clock.simulationID,
              state.lastCareEventID.simulationID == clock.simulationID,
              state.initializedEventID.sequence <= state.lastCareEventID.sequence,
              state.lastCareEventID.sequence.rawValue <= causalLatestSequence,
              !state.rollingDigest.isEmpty else {
            throw AgentDependentCareError.invalidState("bounds, ordering, or counters")
        }
        let load = Dictionary(grouping: openAssignments, by: \.caregiverID).mapValues(\.count)
        guard load.allSatisfy({ $0.value <= state.configuration.maximumDependentsPerCaregiver }) else {
            throw AgentDependentCareError.invalidState("caregiver load")
        }
        for assignment in state.assignments {
            guard assignment.startedTick >= 0, assignment.startedTick <= clock.tick.rawValue,
                  assignment.startedEventID.simulationID == clock.simulationID else {
                throw AgentDependentCareError.invalidState("assignment identity or stage")
            }
            if assignment.status == .active {
                guard assignment.endedTick == nil, assignment.endedEventID == nil,
                      assignment.endedReason == nil,
                      activeIDs.contains(assignment.dependentID),
                      activeIDs.contains(assignment.caregiverID),
                      residents.contains(assignment.dependentID),
                      residents.contains(assignment.caregiverID),
                      (stageByID[assignment.dependentID] == .newborn
                        || stageByID[assignment.dependentID] == .juvenile),
                      stageByID[assignment.caregiverID] == .mature,
                      openMemberships[assignment.dependentID] == assignment.householdID,
                      openMemberships[assignment.caregiverID] == assignment.householdID,
                      householdStatus[assignment.householdID] == .active else {
                    throw AgentDependentCareError.invalidState("open assignment")
                }
            } else {
                guard let endedTick = assignment.endedTick,
                      let endedEventID = assignment.endedEventID,
                      assignment.endedReason != nil,
                      endedTick >= assignment.startedTick,
                      endedTick <= clock.tick.rawValue,
                      assignment.startedEventID.sequence < endedEventID.sequence else {
                    throw AgentDependentCareError.invalidState("ended assignment")
                }
            }
        }
        for need in state.activeNeeds {
            guard activeIDs.contains(need.dependentID),
                  stageByID[need.dependentID] != .mature,
                  need.raisedTick >= 0, need.raisedTick <= clock.tick.rawValue,
                  need.raisedEventID.simulationID == clock.simulationID,
                  need.status == .active || need.status == .unmet,
                  need.resolvedTick == nil, need.terminalReason == nil,
                  need.terminalEventID == nil else {
                throw AgentDependentCareError.invalidNeed(need.needID.rawValue)
            }
        }
        let needsByID = Dictionary(uniqueKeysWithValues: state.activeNeeds.map {
            ($0.needID, $0)
        })
        for engagement in state.activeEngagements {
            guard let need = needsByID[engagement.needID],
                  need.dependentID == engagement.dependentID,
                  need.assignedCaregiverID == engagement.caregiverID,
                  activeIDs.contains(engagement.caregiverID),
                  stageByID[engagement.caregiverID] == .mature else {
                throw AgentDependentCareError.invalidEngagement(engagement.engagementID.rawValue)
            }
        }
        guard causalDroppedEventCount <= causalLatestSequence,
              UInt64(causalEvents.count) == causalLatestSequence - causalDroppedEventCount,
              causalEvents.enumerated().allSatisfy({ index, event in
                  event.sequence.rawValue == causalDroppedEventCount + UInt64(index) + 1
              }) else {
            throw AgentDependentCareError.invalidCausalReference(state.lastCareEventID)
        }
        let eventsByID = Dictionary(uniqueKeysWithValues: causalEvents.map {
            ($0.eventID, $0)
        })
        func validateReference(
            _ eventID: AgentCausalEventID,
            matches: (AgentCausalEvent) -> Bool
        ) throws {
            guard eventID.simulationID == clock.simulationID,
                  eventID.sequence.rawValue <= causalLatestSequence else {
                throw AgentDependentCareError.invalidCausalReference(eventID)
            }
            if let event = eventsByID[eventID] {
                guard matches(event) else {
                    throw AgentDependentCareError.invalidCausalReference(eventID)
                }
                return
            }
            // The ledger retains the contiguous suffix droppedEventCount + 1 ... latestSequence.
            // An absent reference is therefore legitimate only when its exact sequence is in
            // the authoritative discarded prefix, never merely because it is old-looking.
            guard eventID.sequence.rawValue <= causalDroppedEventCount else {
                throw AgentDependentCareError.invalidCausalReference(eventID)
            }
        }
        func matchesCareEnvelope(
            _ event: AgentCausalEvent,
            kind: AgentCausalEventKind,
            tick: Int?,
            actorID: AgentID?,
            subjectID: AgentID?,
            dependentID: AgentID?,
            caregiverID: AgentID?,
            householdID: AgentHouseholdID?,
            needID: AgentCareNeedID?,
            needKind: AgentCareNeedKind?,
            status: String
        ) -> Bool {
            guard event.kind == kind, event.origin == .dependentCareTransition,
                  tick == nil || event.simulationTick.rawValue == tick,
                  event.actorID == actorID, event.subjectID == subjectID,
                  case let .dependentCare(
                      payloadDependentID, payloadCaregiverID, payloadHouseholdID,
                      payloadNeedID, payloadNeedKind, _, _, payloadStatus, _, _, _
                  ) = event.payload else { return false }
            return payloadDependentID == dependentID?.rawValue
                && payloadCaregiverID == caregiverID?.rawValue
                && payloadHouseholdID == householdID?.rawValue
                && payloadNeedID == needID?.rawValue
                && payloadNeedKind == needKind?.rawValue
                && payloadStatus == status
        }
        func isCareKind(_ kind: AgentCausalEventKind) -> Bool {
            switch kind {
            case .dependentCareInitialized, .careAssignmentStarted, .careAssignmentEnded,
                 .careNeedRaised, .careEngagementStarted, .careProvided,
                 .careNeedResolved, .careNeedUnmet:
                return true
            default:
                return false
            }
        }
        let retainedCareEvents = causalEvents.filter {
            $0.origin == .dependentCareTransition && isCareKind($0.kind)
        }
        if let latestRetainedCareEvent = retainedCareEvents.max(by: {
            $0.sequence < $1.sequence
        }) {
            guard latestRetainedCareEvent.eventID == state.lastCareEventID else {
                throw AgentDependentCareError.invalidCausalReference(state.lastCareEventID)
            }
        } else if state.lastCareEventID.sequence.rawValue > causalDroppedEventCount {
            throw AgentDependentCareError.invalidCausalReference(state.lastCareEventID)
        }
        try validateReference(state.initializedEventID) { event in
            matchesCareEnvelope(
                event, kind: .dependentCareInitialized, tick: nil,
                actorID: nil, subjectID: nil, dependentID: nil, caregiverID: nil,
                householdID: nil, needID: nil, needKind: nil, status: "initialized"
            ) && event.causes.isEmpty
        }
        try validateReference(state.lastCareEventID) { event in
            event.origin == .dependentCareTransition && isCareKind(event.kind)
        }
        for assignment in state.assignments {
            try validateReference(assignment.startedEventID) { event in
                matchesCareEnvelope(
                    event, kind: .careAssignmentStarted, tick: assignment.startedTick,
                    actorID: assignment.caregiverID, subjectID: assignment.dependentID,
                    dependentID: assignment.dependentID,
                    caregiverID: assignment.caregiverID,
                    householdID: assignment.householdID,
                    needID: nil, needKind: nil, status: "started"
                ) && !event.causes.isEmpty
            }
            if let endedEventID = assignment.endedEventID,
               let endedTick = assignment.endedTick {
                try validateReference(endedEventID) { event in
                    matchesCareEnvelope(
                        event, kind: .careAssignmentEnded, tick: endedTick,
                        actorID: assignment.caregiverID, subjectID: assignment.dependentID,
                        dependentID: assignment.dependentID,
                        caregiverID: assignment.caregiverID,
                        householdID: assignment.householdID,
                        needID: nil, needKind: nil, status: "ended"
                    ) && event.causes.contains(assignment.startedEventID)
                }
            }
        }
        for need in state.activeNeeds {
            try validateReference(need.raisedEventID) { event in
                guard event.kind == .careNeedRaised,
                      event.origin == .dependentCareTransition,
                      event.simulationTick.rawValue == need.raisedTick,
                      event.subjectID == need.dependentID,
                      case let .dependentCare(
                          payloadDependentID, _, _, payloadNeedID, payloadNeedKind,
                          _, _, payloadStatus, _, _, _
                      ) = event.payload else { return false }
                return payloadDependentID == need.dependentID.rawValue
                    && payloadNeedID == need.needID.rawValue
                    && payloadNeedKind == need.kind.rawValue
                    && payloadStatus == "active"
                    && !event.causes.isEmpty
            }
        }
        for engagement in state.activeEngagements {
            try validateReference(engagement.startedEventID) { event in
                matchesCareEnvelope(
                    event, kind: .careEngagementStarted, tick: engagement.startedTick,
                    actorID: engagement.caregiverID, subjectID: engagement.dependentID,
                    dependentID: engagement.dependentID,
                    caregiverID: engagement.caregiverID,
                    householdID: openMemberships[engagement.dependentID],
                    needID: engagement.needID,
                    needKind: needsByID[engagement.needID]?.kind,
                    status: "engaged"
                ) && !event.causes.isEmpty
            }
        }
        for outcome in state.terminalOutcomes {
            let expectedKind: AgentCausalEventKind = outcome.status == .resolved
                ? .careNeedResolved : .careNeedUnmet
            try validateReference(outcome.terminalEventID) { event in
                guard event.kind == expectedKind,
                      event.origin == .dependentCareTransition,
                      event.simulationTick.rawValue == outcome.tick,
                      event.actorID == outcome.caregiverID,
                      event.subjectID == outcome.dependentID,
                      case let .dependentCare(
                          payloadDependentID, payloadCaregiverID, _, payloadNeedID,
                          payloadNeedKind, _, _, payloadStatus, _, payloadQuantity, _
                      ) = event.payload else { return false }
                return payloadDependentID == outcome.dependentID.rawValue
                    && payloadCaregiverID == outcome.caregiverID?.rawValue
                    && payloadNeedID == outcome.needID.rawValue
                    && payloadNeedKind == outcome.kind.rawValue
                    && payloadStatus == outcome.status.rawValue
                    && payloadQuantity == outcome.materialQuantity
                    && !event.causes.isEmpty
            }
            guard outcome.status == .resolved,
                  let terminalEvent = eventsByID[outcome.terminalEventID],
                  let terminalCauseID = terminalEvent.causes.first else { continue }
            let providedEventID: AgentCausalEventID
            if let intermediary = eventsByID[terminalCauseID],
               intermediary.kind == .skillPracticeCredited,
               intermediary.origin == .skillTransition,
               intermediary.actorID == outcome.caregiverID,
               intermediary.subjectID == outcome.caregiverID,
               intermediary.causes.count == 1,
               case let .skill(_, domain, units, _, sourceID, _, status, _)
                    = intermediary.payload,
               domain == AgentSkillDomain.caregiving.rawValue,
               units == 1, status == "credited",
               sourceID == intermediary.causes[0].rawValue {
                providedEventID = intermediary.causes[0]
            } else {
                providedEventID = terminalCauseID
            }
            try validateReference(providedEventID) { event in
                guard event.kind == .careProvided,
                      event.origin == .dependentCareTransition,
                      event.simulationTick.rawValue == outcome.tick,
                      event.actorID == outcome.caregiverID,
                      event.subjectID == outcome.dependentID,
                      case let .dependentCare(
                          payloadDependentID, payloadCaregiverID, _, payloadNeedID,
                          payloadNeedKind, _, _, payloadStatus, _, payloadQuantity, _
                      ) = event.payload else { return false }
                return payloadDependentID == outcome.dependentID.rawValue
                    && payloadCaregiverID == outcome.caregiverID?.rawValue
                    && payloadNeedID == outcome.needID.rawValue
                    && payloadNeedKind == outcome.kind.rawValue
                    && payloadStatus == "provided"
                    && payloadQuantity == outcome.materialQuantity
                    && !event.causes.isEmpty
            }
            guard outcome.kind == .nourishment,
                  let providedEvent = eventsByID[providedEventID],
                  let materialEventID = providedEvent.causes.first else { continue }
            try validateReference(materialEventID) { event in
                guard event.kind == .consumption, event.origin == .worldOutcome,
                      event.simulationTick.rawValue == outcome.tick,
                      event.actorID == outcome.caregiverID,
                      event.subjectID == outcome.dependentID,
                      case let .operation(status, detail) = event.payload else { return false }
                return status == "succeeded"
                    && detail.contains("provider=\(outcome.caregiverID?.rawValue ?? "none")")
                    && detail.contains("consumer=\(outcome.dependentID.rawValue)")
                    && detail.contains("quantity=\(outcome.materialQuantity)")
            }
        }
    }

    private func dependentLifecycleIDs() -> [AgentID] {
        lifecycleState?.members.compactMap {
            $0.currentStage == .newborn || $0.currentStage == .juvenile ? $0.agentID : nil
        }.sorted() ?? []
    }

    private mutating func requiredDependentCareEvent(
        kind: AgentCausalEventKind,
        actorID: AgentID? = nil,
        subjectID: AgentID? = nil,
        causes: [AgentCausalEventID] = [],
        payload: AgentCausalPayload,
        summary: String,
        instant: AgentSimulationInstant? = nil
    ) throws -> AgentCausalEvent {
        let effectiveInstant = instant ?? simulationInstant
        guard let event = try causalLedger.append(
            instant: effectiveInstant, kind: kind, origin: .dependentCareTransition,
            actorID: actorID, subjectID: subjectID, operationID: nil,
            causes: causes, payload: payload, summary: summary
        ) else { throw AgentSessionError.dependentCare(.causalLedgerRequired) }
        return event
    }

    private func carePayload(
        dependentID: AgentID?, caregiverID: AgentID?, householdID: AgentHouseholdID?,
        need: (AgentCareNeedID, AgentCareNeedKind)?, assignmentCount: Int,
        needCount: Int, status: String, reason: String?, materialQuantity: Int,
        digest: String
    ) -> AgentCausalPayload {
        .dependentCare(
            dependentID: dependentID?.rawValue, caregiverID: caregiverID?.rawValue,
            householdID: householdID?.rawValue, needID: need?.0.rawValue,
            needKind: need?.1.rawValue, assignmentCount: assignmentCount,
            needCount: needCount, status: status, reason: reason,
            materialQuantity: materialQuantity, digest: digest
        )
    }

    private func dependentCareDigest(_ state: AgentDependentCareState) -> String {
        AgentDependentCareDigest.make([
            state.rollingDigest,
            state.assignments.sorted(by: careAssignmentSort).map {
                "a|\($0.dependentID.rawValue)|\($0.caregiverID.rawValue)|\($0.householdID.rawValue)|\($0.startedTick)|\($0.endedTick.map(String.init) ?? "open")"
            }.joined(separator: ";"),
            state.activeNeeds.sorted(by: careNeedSort).map {
                "n|\($0.needID.rawValue)|\($0.dependentID.rawValue)|\($0.kind.rawValue)|\($0.status.rawValue)"
            }.joined(separator: ";"),
            state.activeEngagements.sorted(by: careEngagementSort).map {
                "e|\($0.engagementID.rawValue)|\($0.needID.rawValue)|\($0.caregiverID.rawValue)"
            }.joined(separator: ";"),
            "totals|\(state.totalAssignmentCount)|\(state.totalNeedCount)|\(state.totalEngagementCount)|\(state.totalOutcomeCount)|\(state.evictionCounts.outcomes)",
        ].joined(separator: "|"))
    }
}

private func careAssignmentSort(_ lhs: AgentCareAssignment, _ rhs: AgentCareAssignment) -> Bool {
    if lhs.dependentID != rhs.dependentID { return lhs.dependentID < rhs.dependentID }
    if lhs.startedTick != rhs.startedTick { return lhs.startedTick < rhs.startedTick }
    return lhs.startedEventID < rhs.startedEventID
}

private func careNeedSort(_ lhs: AgentCareNeed, _ rhs: AgentCareNeed) -> Bool {
    if lhs.dependentID != rhs.dependentID { return lhs.dependentID < rhs.dependentID }
    if lhs.kind != rhs.kind { return lhs.kind.rawValue < rhs.kind.rawValue }
    return lhs.needID < rhs.needID
}

private func careEngagementSort(
    _ lhs: AgentCareEngagement,
    _ rhs: AgentCareEngagement
) -> Bool {
    if lhs.caregiverID != rhs.caregiverID { return lhs.caregiverID < rhs.caregiverID }
    if lhs.dependentID != rhs.dependentID { return lhs.dependentID < rhs.dependentID }
    return lhs.engagementID < rhs.engagementID
}

private func careExecutionPriority(_ kind: AgentCareEngagementKind) -> Int {
    switch kind {
    case .provideFood: return 0
    case .assistReturnHome: return 1
    case .supervise, .approachDependent: return 2
    }
}
