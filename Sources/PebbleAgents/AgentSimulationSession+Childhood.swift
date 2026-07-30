extension AgentSimulationSession {
    public var childhoodV2Enabled: Bool {
        dependentCareState?.childhoodV2 != nil
    }

    public func childhoodSnapshot() -> AgentChildhoodSnapshot {
        guard let childhood = dependentCareState?.childhoodV2 else {
            return AgentChildhoodSnapshot(
                enabled: false, configuration: nil, guardianships: [],
                socialProfiles: [], exposures: [], atRiskDependentIDs: [],
                totalGuardianshipCount: 0, totalExposureCount: 0,
                evictionCounts: AgentChildhoodEvictionCounts(),
                digest: AgentChildhoodDigest.make("disabled")
            )
        }
        let active = Set(childhood.guardianships.compactMap {
            $0.status == .active ? $0.dependentID : nil
        })
        let atRisk = dependentLifecycleIDsForChildhood().filter {
            !active.contains($0)
        }
        return AgentChildhoodSnapshot(
            enabled: true, configuration: childhood.configuration,
            guardianships: childhood.guardianships.sorted(by: guardianshipSort),
            socialProfiles: childhood.socialProfiles.sorted {
                $0.agentID < $1.agentID
            },
            exposures: childhood.exposures.sorted(by: socialExposureSort),
            atRiskDependentIDs: atRisk,
            totalGuardianshipCount: childhood.totalGuardianshipCount,
            totalExposureCount: childhood.totalExposureCount,
            evictionCounts: childhood.evictionCounts,
            digest: childhoodDigest(childhood)
        )
    }

    public func currentGuardian(
        for dependentID: AgentID
    ) throws -> AgentGuardianshipAssignment? {
        guard let childhood = dependentCareState?.childhoodV2 else { return nil }
        guard historicalPerson(for: dependentID) != nil else {
            throw AgentSessionError.dependentCare(.unknownDependent(dependentID))
        }
        return childhood.guardianships.first {
            $0.dependentID == dependentID && $0.status == .active
        }
    }

    public func socialDevelopmentProfile(
        for agentID: AgentID
    ) -> AgentSocialDevelopmentProfile? {
        dependentCareState?.childhoodV2?.socialProfiles.first {
            $0.agentID == agentID
        }
    }

    public func childhoodCapabilities(
        for agentID: AgentID
    ) throws -> AgentChildhoodCapabilitySnapshot {
        let policy = try stageCapabilityPolicy(for: agentID)
        let allowed = policy.allowed.sorted { $0.rawValue < $1.rawValue }
        let refused = AgentStageCapability.allCases.filter {
            !policy.permits($0)
        }.sorted { $0.rawValue < $1.rawValue }
        let stage = lifecycleState?.members.first {
            $0.agentID == agentID
        }?.currentStage
        let readiness: Int
        switch stage {
        case .newborn:
            readiness = 0
        case .juvenile:
            let values = Dictionary(uniqueKeysWithValues:
                (socialDevelopmentProfile(for: agentID)?.values ?? []).map {
                    ($0.dimension, $0.basisPoints)
                }
            )
            let positive = [
                .guardianContinuity, .stableCareExposure,
                .supervisedInteraction, .teachingExposure,
                .successfulPracticeExposure,
            ].reduce(0) {
                $0 + (values[$1] ?? 0)
            }
            let unmet = values[.unmetCareExposure] ?? 0
            readiness = max(0, min(7_500, positive / 5 - unmet / 4))
        case .mature:
            readiness = 10_000
        case nil:
            readiness = 0
        }
        return AgentChildhoodCapabilitySnapshot(
            allowed: allowed, refused: refused,
            autonomyReadinessBasisPoints: readiness
        )
    }

    public mutating func setChildhoodV2Enabled(
        _ enabled: Bool,
        configuration: AgentChildhoodConfiguration = .live
    ) throws {
        guard enabled else {
            if childhoodV2Enabled {
                throw AgentSessionError.dependentCare(.unsafeDisable)
            }
            return
        }
        var candidate = self
        try candidate.initializeChildhoodV2InPlace(configuration: configuration)
        try candidate.validateDependentCareCrossDomainIfEnabled()
        self = candidate
    }

    private mutating func initializeChildhoodV2InPlace(
        configuration: AgentChildhoodConfiguration
    ) throws {
        guard var care = dependentCareState else {
            throw AgentSessionError.childhood(.dependentCareRequired)
        }
        guard care.childhoodV2 == nil else {
            throw AgentSessionError.childhood(.alreadyEnabled)
        }
        let dependents = dependentLifecycleIDsForChildhood()
        guard dependents.count <= configuration.maximumSocialProfiles,
              dependents.count <= configuration.maximumRetainedGuardianships else {
            throw AgentSessionError.childhood(.assignmentCapacityReached)
        }
        try prevalidateCausalAppend(count: 1 + dependents.count * 2)
        let initializationDigest = AgentChildhoodDigest.make(
            dependents.map(\.rawValue).joined(separator: ",")
        )
        let initialized = try requiredDependentCareEvent(
            kind: .childhoodV2Initialized,
            causes: [care.lastCareEventID],
            payload: childhoodPayload(
                dependentID: nil, guardianID: nil, householdID: nil,
                status: "initialized", reason: nil, quantity: dependents.count,
                digest: initializationDigest, care: care
            ),
            summary: "childhood V2 initialized dependents=\(dependents.count)"
        )
        var childhood = AgentChildhoodState(
            configuration: configuration, guardianships: [],
            socialProfiles: [], exposures: [], totalGuardianshipCount: 0,
            totalExposureCount: 0, transitionTick: tick,
            transitionsAtTick: 1, evictionCounts: AgentChildhoodEvictionCounts(),
            rollingDigest: initializationDigest,
            initializedEventID: initialized.eventID,
            lastEventID: initialized.eventID
        )
        care.lastCareEventID = initialized.eventID
        for dependentID in dependents {
            ensureSocialProfile(
                for: dependentID, sourceEventID: initialized.eventID,
                childhood: &childhood
            )
            if let selection = deterministicGuardian(
                for: dependentID, childhood: childhood, excluding: []
            ) {
                try startGuardianship(
                    dependentID: dependentID, guardianID: selection.guardianID,
                    householdID: selection.householdID, basis: selection.basis,
                    causeEventID: childhood.lastEventID, at: tick,
                    care: &care, childhood: &childhood
                )
            } else {
                try recordGuardianUnavailable(
                    dependentID: dependentID, causeEventID: childhood.lastEventID,
                    reason: "noEligibleGuardian", at: tick,
                    care: &care, childhood: &childhood
                )
            }
        }
        childhood.rollingDigest = AgentChildhoodDigest.make(
            "\(childhood.rollingDigest)|enabled|\(tick)|"
                + "\(childhood.guardianships.count)|\(childhood.exposures.count)"
        )
        care.childhoodV2 = childhood
        care.rollingDigest = AgentDependentCareDigest.make(
            "\(care.rollingDigest)|childhoodV2|\(childhoodDigest(childhood))"
        )
        dependentCareState = care
    }

    /// Records bounded, explicit temporary help without changing parentage,
    /// guardianship, household membership, ownership, or profession.
    public mutating func delegateDependentCare(
        dependentID: AgentID,
        to caregiverID: AgentID
    ) throws {
        var candidate = self
        try candidate.delegateDependentCareInPlace(
            dependentID: dependentID, to: caregiverID
        )
        try candidate.validateDependentCareCrossDomainIfEnabled()
        self = candidate
    }

    private mutating func delegateDependentCareInPlace(
        dependentID: AgentID,
        to caregiverID: AgentID
    ) throws {
        guard var care = dependentCareState,
              let childhood = care.childhoodV2,
              let guardian = childhood.guardianships.first(where: {
                  $0.dependentID == dependentID && $0.status == .active
              }) else {
            throw AgentSessionError.childhood(.unknownDependent(dependentID))
        }
        guard caregiverID != dependentID,
              guardianEligible(
                caregiverID, for: dependentID, childhood: childhood,
                excluding: [], enforceGuardianCapacity: false
              ),
              (try currentMembership(of: caregiverID))?.householdID
                == guardian.householdID else {
            throw AgentSessionError.childhood(.invalidDelegation(caregiverID))
        }
        if let activeIndex = care.assignments.firstIndex(where: {
            $0.dependentID == dependentID && $0.status == .active
        }) {
            if care.assignments[activeIndex].caregiverID == caregiverID { return }
            try endCareAssignment(
                at: activeIndex, reason: .reassigned,
                causeEventID: guardian.startedEventID, tick: tick, state: &care
            )
        }
        try startCareAssignment(
            dependentID: dependentID, caregiverID: caregiverID,
            householdID: guardian.householdID,
            causeEventID: guardian.startedEventID, tick: tick, state: &care
        )
        care.assignments.sort(by: careAssignmentSortForChildhood)
        care.childhoodV2 = childhood
        dependentCareState = care
    }

    public mutating func reassignGuardian(
        dependentID: AgentID,
        to guardianID: AgentID
    ) throws {
        var candidate = self
        try candidate.reassignGuardianInPlace(
            dependentID: dependentID, to: guardianID
        )
        try candidate.validateDependentCareCrossDomainIfEnabled()
        self = candidate
    }

    private mutating func reassignGuardianInPlace(
        dependentID: AgentID,
        to guardianID: AgentID
    ) throws {
        guard var care = dependentCareState,
              var childhood = care.childhoodV2 else {
            throw AgentSessionError.childhood(.dependentCareRequired)
        }
        guard guardianEligible(
            guardianID, for: dependentID, childhood: childhood,
            excluding: [], enforceGuardianCapacity: true
        ), let householdID = (try currentMembership(of: dependentID))?.householdID,
           (try currentMembership(of: guardianID))?.householdID == householdID else {
            throw AgentSessionError.childhood(.ineligibleGuardian(guardianID))
        }
        if let index = childhood.guardianships.firstIndex(where: {
            $0.dependentID == dependentID && $0.status == .active
        }) {
            if childhood.guardianships[index].guardianID == guardianID { return }
            try endGuardianship(
                at: index, reason: .explicitReassignment,
                causeEventID: childhood.lastEventID, at: tick,
                care: &care, childhood: &childhood
            )
        }
        try startGuardianship(
            dependentID: dependentID, guardianID: guardianID,
            householdID: householdID, basis: .explicitReassignment,
            causeEventID: childhood.lastEventID, at: tick,
            care: &care, childhood: &childhood
        )
        care.childhoodV2 = childhood
        dependentCareState = care
    }

    func deterministicV2Caregiver(
        for dependentID: AgentID,
        projectedLoads: [AgentID: Int],
        configuration: AgentDependentCareConfiguration,
        excluding: Set<AgentID>
    ) -> AgentID? {
        guard let childhood = dependentCareState?.childhoodV2,
              let householdID = (try? currentMembership(of: dependentID))??.householdID
        else { return nil }
        let activeLoads = Dictionary(grouping:
            dependentCareState?.assignments.filter {
                $0.status == .active && $0.dependentID != dependentID
            } ?? [], by: \.caregiverID
        ).mapValues(\.count)
        let guardian = childhood.guardianships.first {
            $0.dependentID == dependentID && $0.status == .active
        }?.guardianID
        return lifecycleState?.members.compactMap { member -> AgentID? in
            let id = member.agentID
            guard member.currentStage == .mature, id != dependentID,
                  !excluding.contains(id),
                  (try? currentMembership(of: id))??.householdID == householdID,
                  guardianEligible(
                    id, for: dependentID, childhood: childhood,
                    excluding: excluding, enforceGuardianCapacity: false
                  ),
                  (activeLoads[id] ?? 0) + (projectedLoads[id] ?? 0)
                    < configuration.maximumDependentsPerCaregiver else { return nil }
            return id
        }.sorted { lhs, rhs in
            let lhsGuardian = lhs == guardian
            let rhsGuardian = rhs == guardian
            if lhsGuardian != rhsGuardian { return lhsGuardian }
            let lhsLoad = (activeLoads[lhs] ?? 0) + (projectedLoads[lhs] ?? 0)
            let rhsLoad = (activeLoads[rhs] ?? 0) + (projectedLoads[rhs] ?? 0)
            if lhsLoad != rhsLoad { return lhsLoad < rhsLoad }
            return lhs < rhs
        }.first
    }

    mutating func registerChildhoodBirth(
        childID: AgentID,
        causeEventID: AgentCausalEventID,
        care: inout AgentDependentCareState
    ) throws {
        guard var childhood = care.childhoodV2 else { return }
        guard childhood.socialProfiles.count
                < childhood.configuration.maximumSocialProfiles else {
            throw AgentSessionError.childhood(.exposureCapacityReached)
        }
        ensureSocialProfile(
            for: childID, sourceEventID: causeEventID, childhood: &childhood
        )
        if let selection = deterministicGuardian(
            for: childID, childhood: childhood, excluding: []
        ) {
            try startGuardianship(
                dependentID: childID, guardianID: selection.guardianID,
                householdID: selection.householdID, basis: selection.basis,
                causeEventID: causeEventID, at: tick,
                care: &care, childhood: &childhood
            )
        } else {
            try recordGuardianUnavailable(
                dependentID: childID, causeEventID: causeEventID,
                reason: "birthNoEligibleGuardian", at: tick,
                care: &care, childhood: &childhood
            )
        }
        care.childhoodV2 = childhood
    }

    mutating func applyChildhoodV2TickBoundary(
        at boundaryTick: Int,
        care: inout AgentDependentCareState
    ) throws {
        guard var childhood = care.childhoodV2 else { return }
        resetChildhoodTransitionCounter(&childhood, at: boundaryTick)
        let dependentSet = Set(dependentLifecycleIDsForChildhood())
        for index in childhood.guardianships.indices.filter({
            childhood.guardianships[$0].status == .active
                && !dependentSet.contains(childhood.guardianships[$0].dependentID)
        }).sorted(by: {
            childhood.guardianships[$0].dependentID
                < childhood.guardianships[$1].dependentID
        }) {
            let dependentID = childhood.guardianships[index].dependentID
            let alive = statesById[dependentID.rawValue] != nil
            try endGuardianship(
                at: index, reason: alive ? .dependentMatured : .dependentDied,
                causeEventID: childhood.lastEventID, at: boundaryTick,
                care: &care, childhood: &childhood
            )
        }
        for dependentID in dependentSet.sorted() {
            if let index = childhood.guardianships.firstIndex(where: {
                $0.dependentID == dependentID && $0.status == .active
            }), !guardianshipRemainsEligible(
                childhood.guardianships[index], childhood: childhood,
                excluding: []
            ) {
                let assignment = childhood.guardianships[index]
                let guardianAlive = statesById[assignment.guardianID.rawValue] != nil
                let sameHousehold = (try? currentMembership(of: assignment.guardianID))?
                    .householdID == assignment.householdID
                try endGuardianship(
                    at: index,
                    reason: guardianAlive
                        ? (sameHousehold ? .guardianIncapacitated : .householdSeparated)
                        : .guardianDied,
                    causeEventID: childhood.lastEventID, at: boundaryTick,
                    care: &care, childhood: &childhood
                )
            }
            guard !childhood.guardianships.contains(where: {
                $0.dependentID == dependentID && $0.status == .active
            }) else { continue }
            if let selection = deterministicGuardian(
                for: dependentID, childhood: childhood, excluding: []
            ) {
                try startGuardianship(
                    dependentID: dependentID, guardianID: selection.guardianID,
                    householdID: selection.householdID, basis: selection.basis,
                    causeEventID: childhood.lastEventID, at: boundaryTick,
                    care: &care, childhood: &childhood
                )
                if !care.assignments.contains(where: {
                    $0.dependentID == dependentID && $0.status == .active
                }) {
                    try startCareAssignment(
                        dependentID: dependentID,
                        caregiverID: selection.guardianID,
                        householdID: selection.householdID,
                        causeEventID: childhood.lastEventID,
                        tick: boundaryTick, state: &care
                    )
                }
            } else {
                let latestUnavailableSequence = childhood.exposures
                    .filter {
                        $0.agentID == dependentID
                            && $0.dimension == .unmetCareExposure
                    }
                    .map(\.sourceEventID.sequence)
                    .max()
                let latestGuardianshipSequence = childhood.guardianships
                    .filter { $0.dependentID == dependentID }
                    .flatMap {
                        [$0.startedEventID.sequence, $0.endedEventID?.sequence]
                            .compactMap { $0 }
                    }
                    .max()
                let alreadyAtRisk: Bool
                if let latestUnavailableSequence {
                    alreadyAtRisk = latestGuardianshipSequence.map {
                        latestUnavailableSequence > $0
                    } ?? true
                } else {
                    alreadyAtRisk = false
                }
                guard !alreadyAtRisk else { continue }
                try recordGuardianUnavailable(
                    dependentID: dependentID,
                    causeEventID: childhood.lastEventID,
                    reason: "replacementUnavailable", at: boundaryTick,
                    care: &care, childhood: &childhood
                )
            }
        }
        childhood.guardianships.sort(by: guardianshipSort)
        childhood.socialProfiles.sort { $0.agentID < $1.agentID }
        childhood.exposures.sort(by: socialExposureSort)
        childhood.rollingDigest = AgentChildhoodDigest.make(
            "\(childhood.rollingDigest)|tick|\(boundaryTick)|"
                + "\(childhood.guardianships.count)|\(childhood.exposures.count)"
        )
        care.childhoodV2 = childhood
    }

    mutating func applyChildhoodDeath(
        agentID: AgentID,
        lethalAgentIDs: Set<AgentID>,
        causeEventID: AgentCausalEventID,
        at deathTick: Int,
        care: inout AgentDependentCareState
    ) throws {
        guard var childhood = care.childhoodV2 else { return }
        resetChildhoodTransitionCounter(&childhood, at: deathTick)
        if let dependentIndex = childhood.guardianships.firstIndex(where: {
            $0.dependentID == agentID && $0.status == .active
        }) {
            try endGuardianship(
                at: dependentIndex, reason: .dependentDied,
                causeEventID: causeEventID, at: deathTick,
                care: &care, childhood: &childhood
            )
        }
        let affected = childhood.guardianships.compactMap {
            $0.status == .active && $0.guardianID == agentID
                ? $0.dependentID : nil
        }.sorted()
        for dependentID in affected {
            guard let index = childhood.guardianships.firstIndex(where: {
                $0.dependentID == dependentID && $0.guardianID == agentID
                    && $0.status == .active
            }) else { continue }
            try endGuardianship(
                at: index, reason: .guardianDied,
                causeEventID: causeEventID, at: deathTick,
                care: &care, childhood: &childhood
            )
            if let selection = deterministicGuardian(
                for: dependentID, childhood: childhood,
                excluding: lethalAgentIDs
            ) {
                try startGuardianship(
                    dependentID: dependentID, guardianID: selection.guardianID,
                    householdID: selection.householdID,
                    basis: .emergencyHouseholdFallback,
                    causeEventID: childhood.lastEventID, at: deathTick,
                    care: &care, childhood: &childhood
                )
            } else {
                try recordGuardianUnavailable(
                    dependentID: dependentID,
                    causeEventID: childhood.lastEventID,
                    reason: "guardianDiedNoReplacement", at: deathTick,
                    care: &care, childhood: &childhood
                )
            }
        }
        care.childhoodV2 = childhood
    }

    mutating func recordChildhoodCareOutcome(
        dependentID: AgentID,
        participantID: AgentID?,
        dimension: AgentSocialDevelopmentDimension,
        sourceEventID: AgentCausalEventID,
        deltaBasisPoints: Int,
        care: inout AgentDependentCareState
    ) throws {
        guard var childhood = care.childhoodV2 else { return }
        try recordChildhoodExposure(
            dependentID: dependentID, participantID: participantID,
            dimension: dimension, sourceEventID: sourceEventID,
            deltaBasisPoints: deltaBasisPoints,
            care: &care, childhood: &childhood
        )
        care.childhoodV2 = childhood
    }

    mutating func recordTeachingSocialDevelopment(
        studentID: AgentID,
        teacherID: AgentID,
        sourceEventID: AgentCausalEventID,
        guidedPractice: Bool
    ) throws {
        guard var care = dependentCareState,
              care.childhoodV2 != nil,
              lifecycleState?.members.first(where: {
                  $0.agentID == studentID
              })?.currentStage != .mature else { return }
        try recordChildhoodCareOutcome(
            dependentID: studentID, participantID: teacherID,
            dimension: guidedPractice
                ? .successfulPracticeExposure : .teachingExposure,
            sourceEventID: sourceEventID,
            deltaBasisPoints: guidedPractice ? 180 : 120,
            care: &care
        )
        dependentCareState = care
    }

    private func deterministicGuardian(
        for dependentID: AgentID,
        childhood: AgentChildhoodState,
        excluding: Set<AgentID>
    ) -> (
        guardianID: AgentID,
        householdID: AgentHouseholdID,
        basis: AgentGuardianshipBasis
    )? {
        guard let householdID = (try? currentMembership(of: dependentID))??.householdID,
              let lifecycle = lifecycleState else { return nil }
        let parents = Set(kinshipState?.parentageRecords.first {
            $0.childID == dependentID
        }?.canonicalParentIDs ?? [])
        let kin = kinshipRelativeIDs(for: dependentID)
        let activeLoads = Dictionary(grouping: childhood.guardianships.filter {
            $0.status == .active && $0.dependentID != dependentID
        }, by: \.guardianID).mapValues(\.count)
        return lifecycle.members.compactMap { member -> (
            AgentID, AgentHouseholdID, AgentGuardianshipBasis, Int
        )? in
            let id = member.agentID
            guard member.currentStage == .mature,
                  guardianEligible(
                    id, for: dependentID, childhood: childhood,
                    excluding: excluding, enforceGuardianCapacity: true
                  ),
                  (try? currentMembership(of: id))??.householdID == householdID
            else { return nil }
            let basis: AgentGuardianshipBasis
            let tier: Int
            if parents.contains(id) {
                basis = .canonicalParent
                tier = 0
            } else if kin.contains(id) {
                basis = .kinshipRelative
                tier = 1
            } else {
                basis = .householdAdult
                tier = 2
            }
            return (id, householdID, basis, tier)
        }.sorted { lhs, rhs in
            if lhs.3 != rhs.3 { return lhs.3 < rhs.3 }
            let lhsLoad = activeLoads[lhs.0] ?? 0
            let rhsLoad = activeLoads[rhs.0] ?? 0
            if lhsLoad != rhsLoad { return lhsLoad < rhsLoad }
            return lhs.0 < rhs.0
        }.first.map { ($0.0, $0.1, $0.2) }
    }

    private func guardianEligible(
        _ guardianID: AgentID,
        for dependentID: AgentID,
        childhood: AgentChildhoodState,
        excluding: Set<AgentID>,
        enforceGuardianCapacity: Bool
    ) -> Bool {
        guard guardianID != dependentID, !excluding.contains(guardianID),
              let agent = statesById[guardianID.rawValue], agent.health > 0,
              lifecycleState?.members.first(where: {
                  $0.agentID == guardianID
              })?.currentStage == .mature,
              populationRegistry?.members.contains(where: {
                  $0.agentID == guardianID
                      && ($0.status == .founderResident || $0.status == .resident)
              }) == true,
              !isMigratingAgent(guardianID.rawValue),
              (try? currentMembership(of: guardianID)) != nil else { return false }
        guard enforceGuardianCapacity else { return true }
        return childhood.guardianships.filter {
            $0.status == .active && $0.guardianID == guardianID
                && $0.dependentID != dependentID
        }.count < childhood.configuration.maximumDependentsPerGuardian
    }

    private func guardianshipRemainsEligible(
        _ assignment: AgentGuardianshipAssignment,
        childhood: AgentChildhoodState,
        excluding: Set<AgentID>
    ) -> Bool {
        guardianEligible(
            assignment.guardianID, for: assignment.dependentID,
            childhood: childhood, excluding: excluding,
            enforceGuardianCapacity: false
        ) && (try? currentMembership(of: assignment.guardianID))??.householdID
            == assignment.householdID
            && (try? currentMembership(of: assignment.dependentID))??.householdID
                == assignment.householdID
    }

    private func kinshipRelativeIDs(for dependentID: AgentID) -> Set<AgentID> {
        guard let kinship = kinshipState else { return [] }
        let directParents = Set(kinship.parentageRecords.first {
            $0.childID == dependentID
        }?.canonicalParentIDs ?? [])
        var values = directParents
        for record in kinship.parentageRecords {
            if record.canonicalParentIDs.contains(where: {
                directParents.contains($0)
            }) {
                values.insert(record.childID)
            }
            if directParents.contains(record.childID) {
                values.formUnion(record.canonicalParentIDs)
            }
        }
        values.remove(dependentID)
        return values
    }

    private mutating func startGuardianship(
        dependentID: AgentID,
        guardianID: AgentID,
        householdID: AgentHouseholdID,
        basis: AgentGuardianshipBasis,
        causeEventID: AgentCausalEventID,
        at assignmentTick: Int,
        care: inout AgentDependentCareState,
        childhood: inout AgentChildhoodState
    ) throws {
        guard !childhood.guardianships.contains(where: {
            $0.dependentID == dependentID && $0.status == .active
        }) else {
            throw AgentSessionError.childhood(.duplicateGuardian(dependentID))
        }
        guard childhood.guardianships.count
                < childhood.configuration.maximumRetainedGuardianships
                || childhood.guardianships.contains(where: {
                    $0.status == .ended
                }) else {
            throw AgentSessionError.childhood(.assignmentCapacityReached)
        }
        guard guardianEligible(
            guardianID, for: dependentID, childhood: childhood,
            excluding: [], enforceGuardianCapacity: true
        ) else {
            throw AgentSessionError.childhood(.ineligibleGuardian(guardianID))
        }
        let event = try requiredDependentCareEvent(
            kind: .guardianshipAssigned, actorID: guardianID,
            subjectID: dependentID, causes: [causeEventID],
            payload: childhoodPayload(
                dependentID: dependentID, guardianID: guardianID,
                householdID: householdID, status: "guardianAssigned",
                reason: basis.rawValue,
                quantity: childhood.guardianships.count + 1,
                digest: childhood.rollingDigest, care: care
            ),
            summary: "guardian assigned dependent=\(dependentID.rawValue) "
                + "guardian=\(guardianID.rawValue) basis=\(basis.rawValue)",
            instant: childhoodInstant(assignmentTick)
        )
        childhood.guardianships.append(AgentGuardianshipAssignment(
            dependentID: dependentID, guardianID: guardianID,
            householdID: householdID, basis: basis,
            startedTick: assignmentTick, startedEventID: event.eventID,
            endedTick: nil, endedEventID: nil, endedReason: nil,
            status: .active
        ))
        childhood.totalGuardianshipCount += 1
        childhood.lastEventID = event.eventID
        care.lastCareEventID = event.eventID
        try countChildhoodTransition(&childhood, at: assignmentTick)
        try recordChildhoodExposure(
            dependentID: dependentID, participantID: guardianID,
            dimension: .guardianContinuity, sourceEventID: event.eventID,
            deltaBasisPoints: 100, at: assignmentTick,
            care: &care, childhood: &childhood
        )
        evictChildhoodHistoryIfNeeded(&childhood)
    }

    private mutating func endGuardianship(
        at index: Int,
        reason: AgentGuardianshipEndReason,
        causeEventID: AgentCausalEventID,
        at assignmentTick: Int,
        care: inout AgentDependentCareState,
        childhood: inout AgentChildhoodState
    ) throws {
        guard childhood.guardianships.indices.contains(index),
              childhood.guardianships[index].status == .active else { return }
        let assignment = childhood.guardianships[index]
        let event = try requiredDependentCareEvent(
            kind: .guardianshipEnded, actorID: assignment.guardianID,
            subjectID: assignment.dependentID,
            causes: Array(
                Set([assignment.startedEventID, causeEventID])
            ).sorted(),
            payload: childhoodPayload(
                dependentID: assignment.dependentID,
                guardianID: assignment.guardianID,
                householdID: assignment.householdID, status: "guardianEnded",
                reason: reason.rawValue, quantity: childhood.guardianships.count,
                digest: childhood.rollingDigest, care: care
            ),
            summary: "guardian ended dependent=\(assignment.dependentID.rawValue) "
                + "reason=\(reason.rawValue)",
            instant: childhoodInstant(assignmentTick)
        )
        childhood.guardianships[index].endedTick = assignmentTick
        childhood.guardianships[index].endedEventID = event.eventID
        childhood.guardianships[index].endedReason = reason
        childhood.guardianships[index].status = .ended
        childhood.lastEventID = event.eventID
        care.lastCareEventID = event.eventID
        try countChildhoodTransition(&childhood, at: assignmentTick)
    }

    private mutating func recordGuardianUnavailable(
        dependentID: AgentID,
        causeEventID: AgentCausalEventID,
        reason: String,
        at eventTick: Int,
        care: inout AgentDependentCareState,
        childhood: inout AgentChildhoodState
    ) throws {
        let event = try requiredDependentCareEvent(
            kind: .guardianUnavailable, subjectID: dependentID,
            causes: [causeEventID],
            payload: childhoodPayload(
                dependentID: dependentID, guardianID: nil,
                householdID: (try? currentMembership(of: dependentID))??.householdID,
                status: "atRisk", reason: reason, quantity: 0,
                digest: childhood.rollingDigest, care: care
            ),
            summary: "guardian unavailable dependent=\(dependentID.rawValue) "
                + "reason=\(reason)",
            instant: childhoodInstant(eventTick)
        )
        childhood.lastEventID = event.eventID
        care.lastCareEventID = event.eventID
        try countChildhoodTransition(&childhood, at: eventTick)
        try recordChildhoodExposure(
            dependentID: dependentID, participantID: nil,
            dimension: .unmetCareExposure, sourceEventID: event.eventID,
            deltaBasisPoints: 150, at: eventTick,
            care: &care, childhood: &childhood
        )
    }

    private mutating func recordChildhoodExposure(
        dependentID: AgentID,
        participantID: AgentID?,
        dimension: AgentSocialDevelopmentDimension,
        sourceEventID: AgentCausalEventID,
        deltaBasisPoints: Int,
        at eventTick: Int? = nil,
        care: inout AgentDependentCareState,
        childhood: inout AgentChildhoodState
    ) throws {
        let exposureTick = eventTick ?? tick
        guard deltaBasisPoints > 0,
              !childhood.exposures.contains(where: {
                  $0.agentID == dependentID && $0.dimension == dimension
                      && $0.sourceEventID == sourceEventID
              }) else { return }
        ensureSocialProfile(
            for: dependentID, sourceEventID: sourceEventID,
            childhood: &childhood
        )
        guard let profileIndex = childhood.socialProfiles.firstIndex(where: {
            $0.agentID == dependentID
        }), let valueIndex = childhood.socialProfiles[profileIndex].values
            .firstIndex(where: { $0.dimension == dimension }) else {
            throw AgentSessionError.childhood(.invalidState("social profile"))
        }
        let before = childhood.socialProfiles[profileIndex].values[valueIndex]
            .basisPoints
        let after = min(
            childhood.configuration.maximumDimensionBasisPoints,
            before + deltaBasisPoints
        )
        let effectiveDelta = after - before
        guard effectiveDelta > 0 else { return }
        let ordinal = childhood.totalExposureCount + 1
        guard ordinal > childhood.totalExposureCount else {
            throw AgentSessionError.childhood(.exposureCapacityReached)
        }
        let event = try requiredDependentCareEvent(
            kind: .socialDevelopmentChanged, actorID: participantID,
            subjectID: dependentID, causes: [sourceEventID],
            payload: childhoodPayload(
                dependentID: dependentID, guardianID: participantID,
                householdID: (try? currentMembership(of: dependentID))??.householdID,
                status: "socialDevelopmentChanged",
                reason: "\(dimension.rawValue):\(before)>\(after)",
                quantity: effectiveDelta, digest: childhood.rollingDigest,
                care: care
            ),
            summary: "social development \(dependentID.rawValue) "
                + "\(dimension.rawValue) \(before)>\(after)",
            instant: childhoodInstant(exposureTick)
        )
        childhood.socialProfiles[profileIndex].values[valueIndex].basisPoints = after
        childhood.socialProfiles[profileIndex].values[valueIndex].lastChangedTick =
            exposureTick
        childhood.socialProfiles[profileIndex].values[valueIndex].lastEventID = event.eventID
        childhood.socialProfiles[profileIndex].totalExposureCount += 1
        childhood.socialProfiles[profileIndex].lastSignificantChangeTick =
            exposureTick
        childhood.socialProfiles[profileIndex].lastEventID = event.eventID
        childhood.exposures.append(AgentSocialDevelopmentExposure(
            ordinal: ordinal, agentID: dependentID, dimension: dimension,
            deltaBasisPoints: effectiveDelta,
            valueAfterBasisPoints: after, tick: exposureTick,
            sourceEventID: sourceEventID, transitionEventID: event.eventID,
            participantID: participantID
        ))
        childhood.totalExposureCount = ordinal
        childhood.lastEventID = event.eventID
        care.lastCareEventID = event.eventID
        try countChildhoodTransition(&childhood, at: exposureTick)
        childhood.rollingDigest = AgentChildhoodDigest.make(
            "\(childhood.rollingDigest)|exposure|\(ordinal)|"
                + "\(dependentID.rawValue)|\(dimension.rawValue)|"
                + "\(before)>\(after)|\(sourceEventID.rawValue)"
        )
        evictChildhoodHistoryIfNeeded(&childhood)
    }

    private func ensureSocialProfile(
        for dependentID: AgentID,
        sourceEventID: AgentCausalEventID,
        childhood: inout AgentChildhoodState
    ) {
        guard !childhood.socialProfiles.contains(where: {
            $0.agentID == dependentID
        }) else { return }
        let values = AgentSocialDevelopmentDimension.allCases.sorted().map {
            AgentSocialDevelopmentValue(
                dimension: $0, basisPoints: 0,
                lastChangedTick: tick, lastEventID: sourceEventID
            )
        }
        childhood.socialProfiles.append(AgentSocialDevelopmentProfile(
            agentID: dependentID, values: values, totalExposureCount: 0,
            lastSignificantChangeTick: tick, lastEventID: sourceEventID
        ))
    }

    private func childhoodPayload(
        dependentID: AgentID?,
        guardianID: AgentID?,
        householdID: AgentHouseholdID?,
        status: String,
        reason: String?,
        quantity: Int,
        digest: String,
        care: AgentDependentCareState
    ) -> AgentCausalPayload {
        .dependentCare(
            dependentID: dependentID?.rawValue,
            caregiverID: guardianID?.rawValue,
            householdID: householdID?.rawValue,
            needID: nil, needKind: nil,
            assignmentCount: care.assignments.count,
            needCount: care.activeNeeds.count,
            status: status, reason: reason,
            materialQuantity: quantity, digest: digest
        )
    }

    private func resetChildhoodTransitionCounter(
        _ childhood: inout AgentChildhoodState,
        at transitionTick: Int
    ) {
        if childhood.transitionTick != transitionTick {
            childhood.transitionTick = transitionTick
            childhood.transitionsAtTick = 0
        }
    }

    private func childhoodInstant(_ rawTick: Int) -> AgentSimulationInstant {
        AgentSimulationInstant(
            simulationID: clock.simulationID,
            tick: AgentSimulationTick(rawValue: rawTick)!
        )
    }

    private func countChildhoodTransition(
        _ childhood: inout AgentChildhoodState,
        at transitionTick: Int
    ) throws {
        resetChildhoodTransitionCounter(&childhood, at: transitionTick)
        guard childhood.transitionsAtTick
                < childhood.configuration.maximumTransitionsPerTick else {
            throw AgentSessionError.childhood(
                .invalidState("transitions per tick")
            )
        }
        childhood.transitionsAtTick += 1
    }

    private func evictChildhoodHistoryIfNeeded(
        _ childhood: inout AgentChildhoodState
    ) {
        childhood.guardianships.sort(by: guardianshipSort)
        while childhood.guardianships.count
                > childhood.configuration.maximumRetainedGuardianships,
              let index = childhood.guardianships.firstIndex(where: {
                  $0.status == .ended
              }) {
            childhood.guardianships.remove(at: index)
            childhood.evictionCounts.guardianships += 1
        }
        childhood.exposures.sort(by: socialExposureSort)
        for agentID in Set(childhood.exposures.map(\.agentID)).sorted() {
            while childhood.exposures.filter({
                $0.agentID == agentID
            }).count > childhood.configuration.maximumExposuresPerChild,
                  let index = childhood.exposures.firstIndex(where: {
                      $0.agentID == agentID
                  }) {
                childhood.exposures.remove(at: index)
                childhood.evictionCounts.exposures += 1
            }
        }
        while childhood.exposures.count
                > childhood.configuration.maximumRetainedExposures {
            childhood.exposures.removeFirst()
            childhood.evictionCounts.exposures += 1
        }
    }

    func childhoodDigest(_ childhood: AgentChildhoodState) -> String {
        let guardians = childhood.guardianships.sorted(by: guardianshipSort).map {
            "g|\($0.dependentID.rawValue)|\($0.guardianID.rawValue)|"
                + "\($0.householdID.rawValue)|\($0.basis.rawValue)|"
                + "\($0.startedTick)|\($0.endedTick.map(String.init) ?? "open")"
        }.joined(separator: ";")
        let profiles = childhood.socialProfiles.sorted {
            $0.agentID < $1.agentID
        }.map { profile in
            "\(profile.agentID.rawValue):"
                + profile.values.sorted {
                    $0.dimension < $1.dimension
                }.map {
                    "\($0.dimension.rawValue)=\($0.basisPoints)"
                }.joined(separator: ",")
        }.joined(separator: ";")
        let exposures = childhood.exposures.sorted(by: socialExposureSort).map {
            "\($0.ordinal)|\($0.agentID.rawValue)|\($0.dimension.rawValue)|"
                + "\($0.valueAfterBasisPoints)|\($0.sourceEventID.rawValue)"
        }.joined(separator: ";")
        return AgentChildhoodDigest.make(
            "\(childhood.rollingDigest)|\(guardians)|\(profiles)|\(exposures)|"
                + "\(childhood.totalGuardianshipCount)|"
                + "\(childhood.totalExposureCount)|"
                + "\(childhood.evictionCounts.guardianships)|"
                + "\(childhood.evictionCounts.exposures)"
        )
    }

    private func dependentLifecycleIDsForChildhood() -> [AgentID] {
        lifecycleState?.members.compactMap {
            $0.currentStage == .newborn || $0.currentStage == .juvenile
                ? $0.agentID : nil
        }.sorted() ?? []
    }

    static func validateChildhoodState(
        _ childhood: AgentChildhoodState,
        care: AgentDependentCareState,
        population: AgentPopulationRegistry,
        lifecycle: AgentLifecycleState,
        kinship: AgentKinshipState,
        households: AgentHouseholdState,
        mortality: AgentMortalityState?,
        agents: [AgentSessionAgentState],
        clock: AgentSimulationClock,
        causalLatestSequence: UInt64,
        causalDroppedEventCount: UInt64,
        causalEvents: [AgentCausalEvent]
    ) throws {
        _ = try AgentChildhoodConfiguration(
            maximumRetainedGuardianships:
                childhood.configuration.maximumRetainedGuardianships,
            maximumDependentsPerGuardian:
                childhood.configuration.maximumDependentsPerGuardian,
            maximumSocialProfiles:
                childhood.configuration.maximumSocialProfiles,
            maximumRetainedExposures:
                childhood.configuration.maximumRetainedExposures,
            maximumExposuresPerChild:
                childhood.configuration.maximumExposuresPerChild,
            maximumTransitionsPerTick:
                childhood.configuration.maximumTransitionsPerTick,
            minimumSupervisionTicks:
                childhood.configuration.minimumSupervisionTicks,
            maximumDimensionBasisPoints:
                childhood.configuration.maximumDimensionBasisPoints
        )
        let activeAgentIDs = Set(agents.map(\.agentID))
        let activeResidentIDs = Set(population.members.compactMap {
            $0.status == .founderResident || $0.status == .resident
                ? $0.agentID : nil
        })
        let stageByID = Dictionary(uniqueKeysWithValues: lifecycle.members.map {
            ($0.agentID, $0.currentStage)
        })
        let membershipByID = Dictionary(uniqueKeysWithValues:
            households.membershipPeriods.compactMap {
                $0.leftTick == nil ? ($0.agentID, $0.householdID) : nil
            }
        )
        let historicalIDs = Set(kinship.historicalPersons.map(\.agentID))
            .union(lifecycle.members.map(\.agentID))
        let deathTickByID = Dictionary(uniqueKeysWithValues:
            (mortality?.records ?? []).map {
                ($0.agentID, $0.deathTick)
            }
        )
        let activeDependents = Set(lifecycle.members.compactMap {
            $0.currentStage == .newborn || $0.currentStage == .juvenile
                ? $0.agentID : nil
        })
        let activeGuardianships = childhood.guardianships.filter {
            $0.status == .active
        }
        guard childhood.guardianships
                == childhood.guardianships.sorted(by: guardianshipSort),
              childhood.socialProfiles == childhood.socialProfiles.sorted(by: {
                  $0.agentID < $1.agentID
              }),
              childhood.exposures
                == childhood.exposures.sorted(by: socialExposureSort),
              childhood.guardianships.count
                <= childhood.configuration.maximumRetainedGuardianships,
              childhood.socialProfiles.count
                <= childhood.configuration.maximumSocialProfiles,
              childhood.exposures.count
                <= childhood.configuration.maximumRetainedExposures,
              childhood.totalGuardianshipCount
                == childhood.guardianships.count
                    + childhood.evictionCounts.guardianships,
              childhood.totalExposureCount
                == childhood.exposures.count
                    + childhood.evictionCounts.exposures,
              childhood.transitionTick >= 0,
              childhood.transitionTick <= clock.tick.rawValue,
              childhood.transitionsAtTick >= 0,
              childhood.transitionsAtTick
                <= childhood.configuration.maximumTransitionsPerTick,
              childhood.initializedEventID.simulationID == clock.simulationID,
              childhood.lastEventID.simulationID == clock.simulationID,
              childhood.initializedEventID.sequence
                <= childhood.lastEventID.sequence,
              childhood.lastEventID.sequence.rawValue <= causalLatestSequence,
              childhood.lastEventID.sequence <= care.lastCareEventID.sequence,
              !childhood.rollingDigest.isEmpty,
              Set(activeGuardianships.map(\.dependentID)).count
                == activeGuardianships.count else {
            throw AgentChildhoodError.invalidState("bounds, ordering, or counters")
        }
        let guardianLoads = Dictionary(
            grouping: activeGuardianships, by: \.guardianID
        ).mapValues(\.count)
        guard guardianLoads.allSatisfy({
            $0.value <= childhood.configuration.maximumDependentsPerGuardian
        }) else {
            throw AgentChildhoodError.invalidState("guardian load")
        }
        let parentageByChild = Dictionary(uniqueKeysWithValues:
            kinship.parentageRecords.map { ($0.childID, $0) }
        )
        func kinRelative(_ guardianID: AgentID, _ dependentID: AgentID) -> Bool {
            let parents = Set(
                parentageByChild[dependentID]?.canonicalParentIDs ?? []
            )
            if parents.contains(guardianID) { return true }
            return kinship.parentageRecords.contains { record in
                record.childID == guardianID
                    && record.canonicalParentIDs.contains(where: {
                        parents.contains($0)
                    })
                    || parents.contains(record.childID)
                        && record.canonicalParentIDs.contains(guardianID)
            }
        }
        for assignment in childhood.guardianships {
            guard assignment.guardianID != assignment.dependentID,
                  historicalIDs.contains(assignment.dependentID),
                  historicalIDs.contains(assignment.guardianID),
                  assignment.startedTick >= 0,
                  assignment.startedTick <= clock.tick.rawValue,
                  assignment.startedEventID.simulationID == clock.simulationID
            else {
                throw AgentChildhoodError.invalidState("guardianship identity")
            }
            if assignment.status == .active {
                guard assignment.endedTick == nil,
                      assignment.endedEventID == nil,
                      assignment.endedReason == nil,
                      activeDependents.contains(assignment.dependentID),
                      activeAgentIDs.contains(assignment.dependentID),
                      activeAgentIDs.contains(assignment.guardianID),
                      activeResidentIDs.contains(assignment.guardianID),
                      stageByID[assignment.guardianID] == .mature,
                      membershipByID[assignment.dependentID]
                        == assignment.householdID,
                      membershipByID[assignment.guardianID]
                        == assignment.householdID else {
                    throw AgentChildhoodError.invalidState("active guardianship")
                }
            } else {
                guard let endedTick = assignment.endedTick,
                      let endedEventID = assignment.endedEventID,
                      assignment.endedReason != nil,
                      endedTick >= assignment.startedTick,
                      endedTick <= clock.tick.rawValue,
                      assignment.startedEventID.sequence
                        < endedEventID.sequence else {
                    throw AgentChildhoodError.invalidState("ended guardianship")
                }
            }
            switch assignment.basis {
            case .canonicalParent:
                guard parentageByChild[assignment.dependentID]?
                    .canonicalParentIDs.contains(assignment.guardianID) == true
                else {
                    throw AgentChildhoodError.invalidState(
                        "canonical parent guardian basis"
                    )
                }
            case .kinshipRelative:
                guard kinRelative(
                    assignment.guardianID, assignment.dependentID
                ) else {
                    throw AgentChildhoodError.invalidState(
                        "kinship guardian basis"
                    )
                }
            case .householdAdult, .explicitReassignment,
                 .emergencyHouseholdFallback:
                break
            }
        }
        guard Set(childhood.socialProfiles.map(\.agentID)).count
                == childhood.socialProfiles.count,
              activeDependents.isSubset(
                of: Set(childhood.socialProfiles.map(\.agentID))
              ) else {
            throw AgentChildhoodError.invalidState("social profile coverage")
        }
        let expectedDimensions = AgentSocialDevelopmentDimension.allCases
            .sorted()
        for profile in childhood.socialProfiles {
            let retainedProfileExposures = childhood.exposures.filter {
                $0.agentID == profile.agentID
            }
            guard historicalIDs.contains(profile.agentID),
                  profile.values.map(\.dimension) == expectedDimensions,
                  Set(profile.values.map(\.dimension)).count
                    == expectedDimensions.count,
                  profile.values.allSatisfy({
                      (0...childhood.configuration.maximumDimensionBasisPoints)
                        .contains($0.basisPoints)
                          && $0.lastChangedTick >= 0
                          && $0.lastChangedTick <= clock.tick.rawValue
                          && $0.lastChangedTick
                            <= (deathTickByID[profile.agentID] ?? Int.max)
                          && $0.lastEventID.simulationID == clock.simulationID
                          && $0.lastEventID.sequence.rawValue
                            <= causalLatestSequence
                  }),
                  profile.totalExposureCount >= 0,
                  profile.totalExposureCount
                    >= retainedProfileExposures.count,
                  profile.totalExposureCount
                    <= childhood.totalExposureCount,
                  profile.lastSignificantChangeTick >= 0,
                  profile.lastSignificantChangeTick <= clock.tick.rawValue,
                  profile.lastSignificantChangeTick
                    <= (deathTickByID[profile.agentID] ?? Int.max),
                  profile.lastEventID.simulationID == clock.simulationID,
                  profile.lastEventID.sequence.rawValue <= causalLatestSequence
            else {
                throw AgentChildhoodError.invalidState("social profile")
            }
            for value in profile.values {
                if let latest = retainedProfileExposures.last(where: {
                    $0.dimension == value.dimension
                }), latest.valueAfterBasisPoints != value.basisPoints {
                    throw AgentChildhoodError.invalidState(
                        "social profile exposure projection"
                    )
                }
            }
        }
        for agentID in Set(childhood.exposures.map(\.agentID)) {
            guard childhood.exposures.filter({
                $0.agentID == agentID
            }).count <= childhood.configuration.maximumExposuresPerChild else {
                throw AgentChildhoodError.invalidState("per-child exposures")
            }
        }
        guard childhood.exposures.map(\.ordinal).allSatisfy({ $0 > 0 }),
              Set(childhood.exposures.map(\.ordinal)).count
                == childhood.exposures.count,
              Set(childhood.exposures.map(\.transitionEventID)).count
                == childhood.exposures.count,
              Set(childhood.exposures.map {
                  "\($0.agentID.rawValue)|\($0.dimension.rawValue)|"
                      + $0.sourceEventID.rawValue
              }).count == childhood.exposures.count,
              childhood.exposures.allSatisfy({
                  historicalIDs.contains($0.agentID)
                      && $0.deltaBasisPoints > 0
                      && $0.deltaBasisPoints <= $0.valueAfterBasisPoints
                      && (1...childhood.configuration.maximumDimensionBasisPoints)
                        .contains($0.valueAfterBasisPoints)
                      && $0.ordinal <= childhood.totalExposureCount
                      && $0.tick >= 0 && $0.tick <= clock.tick.rawValue
                      && $0.tick
                        <= (deathTickByID[$0.agentID] ?? Int.max)
                      && $0.sourceEventID.simulationID == clock.simulationID
                      && $0.transitionEventID.simulationID
                        == clock.simulationID
                      && $0.sourceEventID.sequence
                        < $0.transitionEventID.sequence
              }) else {
            throw AgentChildhoodError.invalidState("social exposures")
        }
        guard causalDroppedEventCount <= causalLatestSequence,
              UInt64(causalEvents.count)
                == causalLatestSequence - causalDroppedEventCount else {
            throw AgentChildhoodError.invalidCausalReference(
                childhood.lastEventID
            )
        }
        let eventsByID = Dictionary(uniqueKeysWithValues: causalEvents.map {
            ($0.eventID, $0)
        })
        func validateReference(
            _ eventID: AgentCausalEventID,
            _ matches: (AgentCausalEvent) -> Bool
        ) throws {
            guard eventID.simulationID == clock.simulationID,
                  eventID.sequence.rawValue <= causalLatestSequence else {
                throw AgentChildhoodError.invalidCausalReference(eventID)
            }
            if let event = eventsByID[eventID] {
                guard matches(event) else {
                    throw AgentChildhoodError.invalidCausalReference(eventID)
                }
            } else if eventID.sequence.rawValue > causalDroppedEventCount {
                throw AgentChildhoodError.invalidCausalReference(eventID)
            }
        }
        try validateReference(childhood.initializedEventID) {
            $0.kind == .childhoodV2Initialized
                && $0.origin == .dependentCareTransition
                && !$0.causes.isEmpty
        }
        try validateReference(childhood.lastEventID) {
            [.childhoodV2Initialized, .guardianshipAssigned,
             .guardianshipEnded, .guardianUnavailable,
             .socialDevelopmentChanged].contains($0.kind)
                && $0.origin == .dependentCareTransition
        }
        let retainedChildhoodEvents = causalEvents.filter {
            $0.origin == .dependentCareTransition
                && [.childhoodV2Initialized, .guardianshipAssigned,
                    .guardianshipEnded, .guardianUnavailable,
                    .socialDevelopmentChanged].contains($0.kind)
        }
        if let latest = retainedChildhoodEvents.max(by: {
            $0.sequence < $1.sequence
        }) {
            guard latest.eventID == childhood.lastEventID else {
                throw AgentChildhoodError.invalidCausalReference(
                    childhood.lastEventID
                )
            }
        }
        for assignment in childhood.guardianships {
            try validateReference(assignment.startedEventID) { event in
                guard event.kind == .guardianshipAssigned,
                      event.origin == .dependentCareTransition,
                      event.actorID == assignment.guardianID,
                      event.subjectID == assignment.dependentID,
                      event.simulationTick.rawValue == assignment.startedTick,
                      case let .dependentCare(
                          dependentID, guardianID, householdID, _, _, _, _,
                          status, reason, _, _
                      ) = event.payload else { return false }
                return dependentID == assignment.dependentID.rawValue
                    && guardianID == assignment.guardianID.rawValue
                    && householdID == assignment.householdID.rawValue
                    && status == "guardianAssigned"
                    && reason == assignment.basis.rawValue
                    && !event.causes.isEmpty
            }
            if let endedEventID = assignment.endedEventID,
               let endedTick = assignment.endedTick,
               let endedReason = assignment.endedReason {
                try validateReference(endedEventID) { event in
                    guard event.kind == .guardianshipEnded,
                          event.origin == .dependentCareTransition,
                          event.actorID == assignment.guardianID,
                          event.subjectID == assignment.dependentID,
                          event.simulationTick.rawValue == endedTick,
                          case let .dependentCare(
                              dependentID, guardianID, householdID, _, _, _, _,
                              status, reason, _, _
                          ) = event.payload else { return false }
                    return dependentID == assignment.dependentID.rawValue
                        && guardianID == assignment.guardianID.rawValue
                        && householdID == assignment.householdID.rawValue
                        && status == "guardianEnded"
                        && reason == endedReason.rawValue
                        && event.causes.contains(assignment.startedEventID)
                }
            }
        }
        for exposure in childhood.exposures {
            try validateReference(exposure.sourceEventID) { event in
                switch exposure.dimension {
                case .guardianContinuity:
                    guard event.kind == .guardianshipAssigned,
                          event.actorID == exposure.participantID,
                          event.subjectID == exposure.agentID,
                          case let .dependentCare(
                              dependentID, guardianID, _, _, _, _, _, status,
                              _, _, _
                          ) = event.payload else { return false }
                    return dependentID == exposure.agentID.rawValue
                        && guardianID == exposure.participantID?.rawValue
                        && status == "guardianAssigned"
                case .stableCareExposure, .supervisedInteraction:
                    guard event.kind == .careNeedResolved,
                          event.actorID == exposure.participantID,
                          event.subjectID == exposure.agentID,
                          case let .dependentCare(
                              dependentID, caregiverID, _, _, needKind, _, _,
                              status, _, _, _
                          ) = event.payload else { return false }
                    let isSupervision = needKind
                        == AgentCareNeedKind.supervision.rawValue
                    return dependentID == exposure.agentID.rawValue
                        && caregiverID == exposure.participantID?.rawValue
                        && status == "resolved"
                        && (exposure.dimension == .supervisedInteraction
                            ? isSupervision : !isSupervision)
                case .teachingExposure:
                    guard event.kind == .demonstrationObserved,
                          event.actorID == exposure.participantID,
                          event.subjectID == exposure.agentID,
                          case let .teaching(
                              _, _, _, teacherID, studentID, _, _, _, status,
                              _, _
                          ) = event.payload else { return false }
                    return teacherID == exposure.participantID?.rawValue
                        && studentID == exposure.agentID.rawValue
                        && status == "attended"
                case .successfulPracticeExposure:
                    guard event.kind == .guidedPracticeLinked,
                          event.actorID == exposure.agentID,
                          event.subjectID == exposure.agentID,
                          case let .teaching(
                              _, _, _, teacherID, studentID, _, _, _, status,
                              _, _
                          ) = event.payload else { return false }
                    return teacherID == exposure.participantID?.rawValue
                        && studentID == exposure.agentID.rawValue
                        && status == "linked"
                case .unmetCareExposure:
                    guard (event.kind == .careNeedUnmet
                            || event.kind == .guardianUnavailable),
                          event.actorID == exposure.participantID,
                          event.subjectID == exposure.agentID,
                          case let .dependentCare(
                              dependentID, caregiverID, _, _, _, _, _, status,
                              _, _, _
                          ) = event.payload else { return false }
                    return dependentID == exposure.agentID.rawValue
                        && caregiverID == exposure.participantID?.rawValue
                        && (status == "unmet" || status == "atRisk")
                }
            }
            try validateReference(exposure.transitionEventID) { event in
                guard event.kind == .socialDevelopmentChanged,
                      event.origin == .dependentCareTransition,
                      event.subjectID == exposure.agentID,
                      event.actorID == exposure.participantID,
                      event.simulationTick.rawValue == exposure.tick,
                      event.causes == [exposure.sourceEventID],
                      case let .dependentCare(
                          dependentID, participantID, _, _, _, _, _, status,
                          reason, delta, _
                      ) = event.payload else { return false }
                return dependentID == exposure.agentID.rawValue
                    && participantID == exposure.participantID?.rawValue
                    && status == "socialDevelopmentChanged"
                    && reason?.hasPrefix(
                        "\(exposure.dimension.rawValue):"
                    ) == true
                    && delta == exposure.deltaBasisPoints
            }
        }
    }
}

private func guardianshipSort(
    _ lhs: AgentGuardianshipAssignment,
    _ rhs: AgentGuardianshipAssignment
) -> Bool {
    if lhs.dependentID != rhs.dependentID {
        return lhs.dependentID < rhs.dependentID
    }
    if lhs.startedTick != rhs.startedTick {
        return lhs.startedTick < rhs.startedTick
    }
    return lhs.startedEventID < rhs.startedEventID
}

private func socialExposureSort(
    _ lhs: AgentSocialDevelopmentExposure,
    _ rhs: AgentSocialDevelopmentExposure
) -> Bool {
    lhs.ordinal < rhs.ordinal
}

private func careAssignmentSortForChildhood(
    _ lhs: AgentCareAssignment,
    _ rhs: AgentCareAssignment
) -> Bool {
    if lhs.dependentID != rhs.dependentID {
        return lhs.dependentID < rhs.dependentID
    }
    if lhs.startedTick != rhs.startedTick {
        return lhs.startedTick < rhs.startedTick
    }
    return lhs.startedEventID < rhs.startedEventID
}
