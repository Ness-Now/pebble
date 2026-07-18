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

    public func careTarget(for caregiverID: AgentID) -> AgentID? {
        guard let state = dependentCareState else { return nil }
        let needsByID = Dictionary(uniqueKeysWithValues: state.activeNeeds.map {
            ($0.needID, $0)
        })
        return state.activeEngagements.filter {
            $0.caregiverID == caregiverID && needsByID[$0.needID]?.status == .active
        }.sorted(by: careEngagementSort).first?.dependentID
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
        guard state.assignments == state.assignments.sorted(by: careAssignmentSort),
              state.activeNeeds == state.activeNeeds.sorted(by: careNeedSort),
              state.activeEngagements == state.activeEngagements.sorted(by: careEngagementSort),
              state.assignments.count <= state.configuration.maximumAssignments,
              state.activeNeeds.count <= state.configuration.maximumActiveNeeds,
              state.activeEngagements.count <= state.configuration.maximumActiveEngagements,
              state.terminalOutcomes.count <= state.configuration.maximumRetainedOutcomes,
              openAssignments.count <= state.configuration.maximumDependents,
              openAssignments.map(\.dependentID).count == Set(openAssignments.map(\.dependentID)).count,
              state.activeNeeds.map(\.needID).count == Set(state.activeNeeds.map(\.needID)).count,
              state.activeEngagements.map(\.engagementID).count
                == Set(state.activeEngagements.map(\.engagementID)).count,
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
                  assignment.startedEventID.simulationID == clock.simulationID,
                  stageByID[assignment.dependentID] != .mature else {
                throw AgentDependentCareError.invalidState("assignment identity or stage")
            }
            if assignment.status == .active {
                guard assignment.endedTick == nil, assignment.endedEventID == nil,
                      assignment.endedReason == nil,
                      activeIDs.contains(assignment.dependentID),
                      activeIDs.contains(assignment.caregiverID),
                      residents.contains(assignment.dependentID),
                      residents.contains(assignment.caregiverID),
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
        let referencedEventIDs = [state.initializedEventID, state.lastCareEventID]
            + state.assignments.flatMap { assignment in
                [assignment.startedEventID] + (assignment.endedEventID.map { [$0] } ?? [])
            }
            + state.activeNeeds.map(\.raisedEventID)
            + state.activeEngagements.map(\.startedEventID)
            + state.terminalOutcomes.map(\.terminalEventID)
        for eventID in referencedEventIDs {
            guard eventID.simulationID == clock.simulationID,
                  eventID.sequence.rawValue <= causalLatestSequence,
                  causalEvents.contains(where: { $0.eventID == eventID })
                    || eventID.sequence.rawValue <= causalDroppedEventCount else {
                throw AgentDependentCareError.invalidCausalReference(eventID)
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
