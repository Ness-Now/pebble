public enum AgentCausalLedgerPolicy: Codable, Equatable, Sendable {
    case disabled
    case bounded(maxEvents: Int)
}

public enum AgentCausalLedgerError: Error, Equatable {
    case invalidBound(Int)
    case sequenceOverflow
    case payloadMismatch(AgentCausalEventKind)
    case tooManyCauses(Int)
    case duplicateCause(AgentCausalEventID)
    case crossSimulationCause(AgentCausalEventID)
    case nonPriorCause(AgentCausalEventID)
}

public struct AgentCausalSequence: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: UInt64

    public init?(rawValue: UInt64) {
        guard rawValue > 0 else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: AgentCausalSequence, rhs: AgentCausalSequence) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct AgentCausalEventID: Codable, Hashable, Comparable, Sendable {
    public let simulationID: AgentSimulationID
    public let sequence: AgentCausalSequence

    public init(simulationID: AgentSimulationID, sequence: AgentCausalSequence) {
        self.simulationID = simulationID
        self.sequence = sequence
    }

    public var rawValue: String {
        let digits = String(sequence.rawValue)
        let padded = String(repeating: "0", count: max(0, 20 - digits.count)) + digits
        return "\(simulationID.rawValue)/event-\(padded)"
    }

    public static func < (lhs: AgentCausalEventID, rhs: AgentCausalEventID) -> Bool {
        if lhs.simulationID != rhs.simulationID { return lhs.simulationID < rhs.simulationID }
        return lhs.sequence < rhs.sequence
    }
}

public enum AgentCausalEventKind: String, Codable, CaseIterable, Sendable {
    case sessionLifecycle
    case featureToggle
    case perception
    case goalTransition
    case actionSelected
    case tickCompleted
    case movement
    case interaction
    case delivery
    case consumption
    case physicalFoodSurvivalInitialized
    case physicalFoodConsumed
    case constructionFunding
    case constructionPlacement
    case constructionCompletion
    case constructionClear
    case resourceFactGrounded
    case socialMessageSent
    case socialMessageReceived
    case socialBeliefChanged
    case socialVerification
    case trustChanged
    case socialStateCleared
    case physicalSignalEmitted
    case physicalSignalPerceived
    case physicalSignalDecoded
    case physicalSignalExpired
    case physicalStateCleared
    case sharedTaskCreated
    case sharedTaskSignaled
    case sharedTaskOffered
    case sharedTaskAccepted
    case sharedTaskDeclined
    case sharedTaskStarted
    case sharedTaskProgress
    case sharedTaskCompleted
    case sharedTaskExpired
    case sharedTaskCancelled
    case sharedTaskFailed
    case sharedTaskSuperseded
    case cooperationReliabilityChanged
    case cooperationStateCleared
    case populationRegistryInitialized
    case populationMemberRegistered
    case migrationProposed
    case migrationAdmitted
    case migrationStarted
    case migrationArrived
    case migrationRejected
    case migrationCancelled
    case migrationFailed
    case populationStateCleared
    case settlementMetricsInitialized
    case settlementMacroPulse
    case settlementMetricsCleared
    case settlementMetricsDisabled
    case localEcologyInitialized
    case ecologyPatchRegistered
    case ecologyPatchRegenerated
    case ecologyForageResolved
    case ecologyPatchDepleted
    case ecologyPatchInvalidated
    case subsistencePressureChanged
    case localEcologyStateCleared
    case mortalityInitialized
    case lethalHealthDepletion
    case agentDeathFinalized
    case populationMemberExited
    case mortalityResourcesRetired
    case mortalityCommitmentsResolved
    case mortalityStateCleared
    case lifecycleInitialized
    case lifecycleMemberRegistered
    case lifeStageChanged
    case reproductionEnabled
    case reproductionDisabled
    case reproductionPlanCreated
    case reproductionPlanCancelled
    case birthSiteValidated
    case populationMemberBorn
    case birthFinalized
    case lifecycleMemberExited
    case lifecycleStateCleared
    case kinshipInitialized
    case kinshipPersonRegistered
    case kinshipParentageRecorded
    case householdsInitialized
    case householdCreated
    case householdMembershipStarted
    case householdMembershipEnded
    case householdDissolved
    case dependentCareInitialized
    case careAssignmentStarted
    case careAssignmentEnded
    case careNeedRaised
    case careEngagementStarted
    case careProvided
    case careNeedResolved
    case careNeedUnmet
    case skillsInitialized
    case skillPracticeCredited
    case teachingInitialized
    case apprenticeshipStarted
    case demonstrationObserved
    case apprenticeshipEnded
    case guidedPracticeLinked
    case ecologicalObservationInitialized
    case ecologicalObservationRecorded
    case agricultureInitialized
    case agriculturalPlotPlanned
    case agriculturalCellPrepared
    case agriculturalCropPlanted
    case agriculturalCropMatured
    case agriculturalCropHarvested
    case agriculturalSurplusStored
    case agriculturalCellReconciled
    case wildSubsistenceInitialized
    case subsistenceOpportunitySelected
    case fishingCatchAcquired
    case wildAnimalHunted
    case wildResourceGathered
    case wildSubsistenceAttemptFailed
    case livestockInitialized
    case livestockGroupEstablished
    case managedAnimalAdded
    case animalFed
    case animalBreedingObserved
    case animalProductAcquired
    case managedAnimalLost
    case livestockTaskCompleted
    case workCommitmentsInitialized
    case workDemandRefreshed
    case workMatchingSelected
    case workCommitmentStarted
    case workCommitmentRenewed
    case workCommitmentSuspended
    case workCommitmentResumed
    case workCommitmentFulfilled
    case workCommitmentEnded
    case workCommitmentReassigned
    case workOutcomeValidated
    case workReputationUpdated
    case materialRightsInitialized
    case materialAssetRegistered
    case materialPhysicalCustodyObserved
    case materialClaimChanged
    case materialOwnershipRecognized
    case materialCustodyChanged
    case materialUsePermissionChanged
    case materialUseDecided
}

public enum AgentCausalOrigin: String, Codable, Sendable {
    case session
    case externalObservation
    case cognitiveTransition
    case worldOutcome
    case controllerCommand
    case lifecycle
    case socialTransition
    case physicalTransition
    case cooperationTransition
    case populationTransition
    case settlementTransition
    case ecologyTransition
    case mortalityTransition
    case lifecycleTransition
    case kinshipTransition
    case householdTransition
    case dependentCareTransition
    case skillTransition
    case teachingTransition
    case ecologicalObservationTransition
    case agricultureTransition
    case wildSubsistenceTransition
    case livestockTransition
    case workCommitmentTransition
    case materialRightsTransition
}

public enum AgentCausalPayload: Codable, Equatable, Sendable {
    case lifecycle(status: String, agentCount: Int)
    case feature(name: String, enabled: Bool)
    case perception(worldObserved: Bool, resourceObservationCount: Int, memoriesAdded: Int)
    case cognitive(goal: String, action: String, goalChanged: Bool)
    case movement(status: String, from: AgentPosition, to: AgentPosition)
    case operation(status: String, detail: String)
    case resourceFact(
        factID: String,
        observerID: String,
        resource: AgentResourceKind,
        position: AgentPosition,
        fingerprint: Int
    )
    case socialMessage(messageID: String, factID: String, status: String)
    case socialBelief(beliefID: String, messageID: String, status: String, reason: String)
    case socialVerification(
        beliefID: String,
        expectedFingerprint: Int,
        observedFingerprint: Int?,
        result: String
    )
    case trust(relationID: String, before: Int, delta: Int, after: Int)
    case socialClear(facts: Int, messages: Int, beliefs: Int, trustRelations: Int)
    case physicalSignal(
        signalID: String,
        senderID: String,
        recipientID: String,
        factID: String,
        source: AgentPosition,
        pointed: AgentPosition,
        modalities: String
    )
    case physicalPerception(
        signalID: String,
        observerID: String,
        intended: Bool,
        soundClarity: Int,
        gestureClarity: Int,
        occlusions: Int,
        lineOfSight: Bool,
        outcome: String
    )
    case physicalClear(signals: Int, perceptions: Int, presentations: Int)
    case cooperationTask(
        taskID: String,
        projectID: String,
        issuerID: String,
        helperID: String,
        resource: AgentResourceKind,
        requested: Int,
        contributed: Int,
        status: String,
        reason: String
    )
    case cooperationReliability(
        relationID: String,
        taskID: String,
        before: Int,
        delta: Int,
        after: Int
    )
    case cooperationClear(tasks: Int, offers: Int, relations: Int)
    case population(
        settlementID: String,
        memberID: String?,
        ordinal: Int?,
        founder: Bool?,
        status: String,
        populationBefore: Int,
        populationAfter: Int
    )
    case migration(
        migrationID: String,
        migrantID: String,
        origin: String,
        destination: String,
        entry: AgentPosition,
        reception: AgentPosition,
        status: String,
        reason: String?,
        routeLength: Int
    )
    case settlementMetrics(
        frameID: String?,
        settlementID: String,
        macroSequence: UInt64,
        fromTickExclusive: Int,
        toTickInclusive: Int,
        condition: String,
        population: Int,
        urgent: Int,
        migrating: Int,
        engaged: Int,
        stable: Int,
        movementDelta: Int,
        materialActivityDelta: Int,
        socialActivityDelta: Int,
        cooperationActivityDelta: Int,
        coverageComplete: Bool,
        status: String
    )
    case ecologyPatch(
        patchID: String?,
        settlementID: String,
        position: AgentPosition?,
        fingerprint: Int?,
        yieldBefore: Int,
        yieldDelta: Int,
        yieldAfter: Int,
        capacity: Int,
        status: String,
        reason: String
    )
    case ecologyForage(
        forageID: String,
        patchID: String,
        agentID: String,
        status: String,
        yieldBefore: Int,
        yieldAfter: Int,
        inventoryBefore: Int,
        inventoryAfter: Int
    )
    case subsistencePressure(
        previous: String?,
        current: String,
        population: Int,
        hungry: Int,
        critical: Int,
        available: Int,
        carried: Int,
        stocked: Int,
        regenerated: Int,
        consumed: Int,
        starvationDamage: Int
    )
    case ecologyClear(forageHistory: Int, pressureFrames: Int)
    case mortalityDeath(
        deathID: String,
        agentID: String,
        cause: String,
        tick: Int,
        healthBefore: Int,
        healthAfter: Int,
        hunger: Double,
        populationBefore: Int,
        populationAfter: Int,
        membershipStatus: String,
        position: AgentPosition,
        carriedQuantity: Int,
        cancelledCommitments: Int,
        reason: String
    )
    case mortalityResources(
        deathID: String,
        amounts: [AgentResourceAmount],
        terminalBefore: Int,
        terminalAfter: Int,
        conservationExact: Bool
    )
    case mortalityCommitments(
        deathID: String,
        reservations: Int,
        socialVerifications: Int,
        signals: Int,
        tasksAndOffers: Int,
        constructionBlocked: Bool,
        reason: String
    )
    case mortalityClear(exitFrames: Int)
    case lifecycleMember(
        memberID: String?,
        ordinal: Int?,
        origin: String?,
        stage: String?,
        age: Int?,
        status: String
    )
    case reproductionPlan(
        planID: String?,
        progenitorIDs: [String],
        createdTick: Int?,
        dueTick: Int?,
        status: String,
        reason: String?
    )
    case birth(
        birthID: String,
        planID: String,
        newbornID: String,
        ordinal: Int,
        progenitorIDs: [String],
        position: AgentPosition,
        fingerprint: Int,
        status: String
    )
    case kinship(
        childID: String?,
        birthID: String?,
        parentIDs: [String],
        personCount: Int,
        parentageCount: Int,
        digest: String,
        status: String
    )
    case household(
        householdID: String?,
        ordinal: Int?,
        settlementID: String?,
        agentID: String?,
        residenceAnchor: AgentPosition?,
        householdCount: Int,
        membershipCount: Int,
        reason: String?,
        status: String,
        digest: String
    )
    case dependentCare(
        dependentID: String?,
        caregiverID: String?,
        householdID: String?,
        needID: String?,
        needKind: String?,
        assignmentCount: Int,
        needCount: Int,
        status: String,
        reason: String?,
        materialQuantity: Int,
        digest: String
    )
    case skill(
        agentID: String?,
        domain: String?,
        practiceUnits: Int,
        cumulativePracticeUnits: Int,
        sourceSuccessEventID: String?,
        practiceRecordCount: Int,
        status: String,
        digest: String
    )
    case teaching(
        apprenticeshipID: String?,
        demonstrationID: String?,
        exposureID: String?,
        teacherID: String?,
        studentID: String?,
        domain: String?,
        sourceSuccessEventID: String?,
        skillPracticeEventID: String?,
        status: String,
        reason: String?,
        digest: String
    )
    case ecologicalObservation(
        observerID: String?,
        worldContextKey: String?,
        dimensionKey: String?,
        resultCount: Int,
        worldReads: Int,
        truncated: Bool,
        status: String,
        digest: String
    )
    case agriculture(
        plotID: String?,
        cellIndex: Int?,
        actionID: String?,
        status: String,
        physicalFingerprint: Int,
        itemKey: String?,
        quantity: Int,
        digest: String
    )
    case wildSubsistence(
        opportunityID: String?,
        attemptID: String?,
        strategy: String?,
        targetKey: String?,
        status: String,
        quantity: Int,
        digest: String
    )
    case livestock(
        herdID: String?,
        animalRecordID: String?,
        taskID: String?,
        actionID: String?,
        status: String,
        quantity: Int,
        digest: String
    )
    case work(
        demandID: String?,
        commitmentID: String?,
        workerID: String?,
        observerID: String?,
        domain: String?,
        sourceEventID: String?,
        status: String,
        quantity: Int,
        score: Int,
        digest: String
    )

    var canonicalText: String {
        switch self {
        case let .lifecycle(status, agentCount):
            return "lifecycle|\(status)|\(agentCount)"
        case let .feature(name, enabled):
            return "feature|\(name)|\(enabled ? 1 : 0)"
        case let .perception(worldObserved, resourceObservationCount, memoriesAdded):
            return "perception|\(worldObserved ? 1 : 0)|\(resourceObservationCount)|\(memoriesAdded)"
        case let .cognitive(goal, action, goalChanged):
            return "cognitive|\(goal)|\(action)|\(goalChanged ? 1 : 0)"
        case let .movement(status, from, to):
            return "movement|\(status)|\(from.x),\(from.y),\(from.z)|\(to.x),\(to.y),\(to.z)"
        case let .operation(status, detail):
            return "operation|\(status)|\(detail)"
        case let .resourceFact(factID, observerID, resource, position, fingerprint):
            return "resourceFact|\(factID)|\(observerID)|\(resource.rawValue)|\(position.x),\(position.y),\(position.z)|\(fingerprint)"
        case let .socialMessage(messageID, factID, status):
            return "socialMessage|\(messageID)|\(factID)|\(status)"
        case let .socialBelief(beliefID, messageID, status, reason):
            return "socialBelief|\(beliefID)|\(messageID)|\(status)|\(reason)"
        case let .socialVerification(
            beliefID, expectedFingerprint, observedFingerprint, result
        ):
            return "socialVerification|\(beliefID)|\(expectedFingerprint)|\(observedFingerprint.map(String.init) ?? "none")|\(result)"
        case let .trust(relationID, before, delta, after):
            return "trust|\(relationID)|\(before)|\(delta)|\(after)"
        case let .socialClear(facts, messages, beliefs, trustRelations):
            return "socialClear|\(facts)|\(messages)|\(beliefs)|\(trustRelations)"
        case let .physicalSignal(
            signalID, senderID, recipientID, factID, source, pointed, modalities
        ):
            return "physicalSignal|\(signalID)|\(senderID)|\(recipientID)|\(factID)|\(source.x),\(source.y),\(source.z)|\(pointed.x),\(pointed.y),\(pointed.z)|\(modalities)"
        case let .physicalPerception(
            signalID, observerID, intended, soundClarity, gestureClarity,
            occlusions, lineOfSight, outcome
        ):
            return "physicalPerception|\(signalID)|\(observerID)|\(intended ? 1 : 0)|\(soundClarity)|\(gestureClarity)|\(occlusions)|\(lineOfSight ? 1 : 0)|\(outcome)"
        case let .physicalClear(signals, perceptions, presentations):
            return "physicalClear|\(signals)|\(perceptions)|\(presentations)"
        case let .cooperationTask(
            taskID, projectID, issuerID, helperID, resource,
            requested, contributed, status, reason
        ):
            return "cooperationTask|\(taskID)|\(projectID)|\(issuerID)|\(helperID)|\(resource.rawValue)|\(requested)|\(contributed)|\(status)|\(reason)"
        case let .cooperationReliability(relationID, taskID, before, delta, after):
            return "cooperationReliability|\(relationID)|\(taskID)|\(before)|\(delta)|\(after)"
        case let .cooperationClear(tasks, offers, relations):
            return "cooperationClear|\(tasks)|\(offers)|\(relations)"
        case let .population(
            settlementID, memberID, ordinal, founder, status, populationBefore, populationAfter
        ):
            return "population|\(settlementID)|\(memberID ?? "none")|\(ordinal.map(String.init) ?? "none")|\(founder.map { $0 ? "1" : "0" } ?? "none")|\(status)|\(populationBefore)|\(populationAfter)"
        case let .migration(
            migrationID, migrantID, origin, destination, entry, reception,
            status, reason, routeLength
        ):
            return "migration|\(migrationID)|\(migrantID)|\(origin)|\(destination)|\(entry.x),\(entry.y),\(entry.z)|\(reception.x),\(reception.y),\(reception.z)|\(status)|\(reason ?? "none")|\(routeLength)"
        case let .settlementMetrics(
            frameID, settlementID, macroSequence, fromTickExclusive, toTickInclusive,
            condition, population, urgent, migrating, engaged, stable, movementDelta,
            materialActivityDelta, socialActivityDelta, cooperationActivityDelta,
            coverageComplete, status
        ):
            return "settlementMetrics|\(frameID ?? "none")|\(settlementID)|\(macroSequence)|"
                + "\(fromTickExclusive)|\(toTickInclusive)|\(condition)|\(population)|"
                + "\(urgent)|\(migrating)|\(engaged)|\(stable)|\(movementDelta)|"
                + "\(materialActivityDelta)|\(socialActivityDelta)|"
                + "\(cooperationActivityDelta)|\(coverageComplete ? 1 : 0)|\(status)"
        case let .ecologyPatch(
            patchID, settlementID, position, fingerprint, yieldBefore, yieldDelta,
            yieldAfter, capacity, status, reason
        ):
            let point = position.map { "\($0.x),\($0.y),\($0.z)" } ?? "none"
            return "ecologyPatch|\(patchID ?? "none")|\(settlementID)|\(point)|"
                + "\(fingerprint.map(String.init) ?? "none")|\(yieldBefore)|\(yieldDelta)|"
                + "\(yieldAfter)|\(capacity)|\(status)|\(reason)"
        case let .ecologyForage(
            forageID, patchID, agentID, status, yieldBefore, yieldAfter,
            inventoryBefore, inventoryAfter
        ):
            return "ecologyForage|\(forageID)|\(patchID)|\(agentID)|\(status)|"
                + "\(yieldBefore)|\(yieldAfter)|\(inventoryBefore)|\(inventoryAfter)"
        case let .subsistencePressure(
            previous, current, population, hungry, critical, available, carried,
            stocked, regenerated, consumed, starvationDamage
        ):
            return "subsistencePressure|\(previous ?? "none")|\(current)|\(population)|"
                + "\(hungry)|\(critical)|\(available)|\(carried)|\(stocked)|"
                + "\(regenerated)|\(consumed)|\(starvationDamage)"
        case let .ecologyClear(forageHistory, pressureFrames):
            return "ecologyClear|\(forageHistory)|\(pressureFrames)"
        case let .mortalityDeath(
            deathID, agentID, cause, tick, healthBefore, healthAfter, hunger,
            populationBefore, populationAfter, membershipStatus, position,
            carriedQuantity, cancelledCommitments, reason
        ):
            return "mortalityDeath|\(deathID)|\(agentID)|\(cause)|\(tick)|"
                + "\(healthBefore)|\(healthAfter)|\(hunger)|\(populationBefore)|"
                + "\(populationAfter)|\(membershipStatus)|\(position.x),\(position.y),\(position.z)|"
                + "\(carriedQuantity)|\(cancelledCommitments)|\(reason)"
        case let .mortalityResources(
            deathID, amounts, terminalBefore, terminalAfter, conservationExact
        ):
            let resources = AgentResourceAmounts.normalize(amounts).map {
                "\($0.resource.rawValue):\($0.quantity)"
            }.joined(separator: ",")
            return "mortalityResources|\(deathID)|\(resources)|\(terminalBefore)|"
                + "\(terminalAfter)|\(conservationExact ? 1 : 0)"
        case let .mortalityCommitments(
            deathID, reservations, socialVerifications, signals, tasksAndOffers,
            constructionBlocked, reason
        ):
            return "mortalityCommitments|\(deathID)|\(reservations)|"
                + "\(socialVerifications)|\(signals)|\(tasksAndOffers)|"
                + "\(constructionBlocked ? 1 : 0)|\(reason)"
        case let .mortalityClear(exitFrames):
            return "mortalityClear|\(exitFrames)"
        case let .lifecycleMember(memberID, ordinal, origin, stage, age, status):
            return "lifecycleMember|\(memberID ?? "none")|\(ordinal.map(String.init) ?? "none")|"
                + "\(origin ?? "none")|\(stage ?? "none")|\(age.map(String.init) ?? "none")|\(status)"
        case let .reproductionPlan(
            planID, progenitorIDs, createdTick, dueTick, status, reason
        ):
            return "reproductionPlan|\(planID ?? "none")|\(progenitorIDs.joined(separator: ","))|"
                + "\(createdTick.map(String.init) ?? "none")|\(dueTick.map(String.init) ?? "none")|"
                + "\(status)|\(reason ?? "none")"
        case let .birth(
            birthID, planID, newbornID, ordinal, progenitorIDs, position,
            fingerprint, status
        ):
            return "birth|\(birthID)|\(planID)|\(newbornID)|\(ordinal)|"
                + "\(progenitorIDs.joined(separator: ","))|\(position.x),\(position.y),\(position.z)|"
                + "\(fingerprint)|\(status)"
        case let .kinship(
            childID, birthID, parentIDs, personCount, parentageCount, digest, status
        ):
            return "kinship|\(childID ?? "none")|\(birthID ?? "none")|"
                + "\(parentIDs.joined(separator: ","))|\(personCount)|\(parentageCount)|"
                + "\(digest)|\(status)"
        case let .household(
            householdID, ordinal, settlementID, agentID, residenceAnchor,
            householdCount, membershipCount, reason, status, digest
        ):
            let anchor = residenceAnchor.map { "\($0.x),\($0.y),\($0.z)" } ?? "none"
            return "household|\(householdID ?? "none")|"
                + "\(ordinal.map(String.init) ?? "none")|\(settlementID ?? "none")|"
                + "\(agentID ?? "none")|\(anchor)|\(householdCount)|"
                + "\(membershipCount)|\(reason ?? "none")|\(status)|\(digest)"
        case let .dependentCare(
            dependentID, caregiverID, householdID, needID, needKind,
            assignmentCount, needCount, status, reason, materialQuantity, digest
        ):
            return "dependentCare|\(dependentID ?? "none")|\(caregiverID ?? "none")|"
                + "\(householdID ?? "none")|\(needID ?? "none")|\(needKind ?? "none")|"
                + "\(assignmentCount)|\(needCount)|\(status)|\(reason ?? "none")|"
                + "\(materialQuantity)|\(digest)"
        case let .skill(
            agentID, domain, practiceUnits, cumulativePracticeUnits,
            sourceSuccessEventID, practiceRecordCount, status, digest
        ):
            return "skill|\(agentID ?? "none")|\(domain ?? "none")|"
                + "\(practiceUnits)|\(cumulativePracticeUnits)|"
                + "\(sourceSuccessEventID ?? "none")|\(practiceRecordCount)|"
                + "\(status)|\(digest)"
        case let .teaching(
            apprenticeshipID, demonstrationID, exposureID, teacherID, studentID,
            domain, sourceSuccessEventID, skillPracticeEventID, status, reason, digest
        ):
            return "teaching|\(apprenticeshipID ?? "none")|"
                + "\(demonstrationID ?? "none")|\(exposureID ?? "none")|"
                + "\(teacherID ?? "none")|\(studentID ?? "none")|"
                + "\(domain ?? "none")|\(sourceSuccessEventID ?? "none")|"
                + "\(skillPracticeEventID ?? "none")|\(status)|"
                + "\(reason ?? "none")|\(digest)"
        case let .ecologicalObservation(
            observerID, worldContextKey, dimensionKey, resultCount, worldReads,
            truncated, status, digest
        ):
            return "ecologicalObservation|\(observerID ?? "none")|"
                + "\(worldContextKey ?? "none")|\(dimensionKey ?? "none")|"
                + "\(resultCount)|\(worldReads)|\(truncated ? 1 : 0)|\(status)|\(digest)"
        case let .agriculture(
            plotID, cellIndex, actionID, status, physicalFingerprint,
            itemKey, quantity, digest
        ):
            return "agriculture|\(plotID ?? "none")|\(cellIndex.map(String.init) ?? "none")|"
                + "\(actionID ?? "none")|\(status)|\(physicalFingerprint)|"
                + "\(itemKey ?? "none")|\(quantity)|\(digest)"
        case let .wildSubsistence(
            opportunityID, attemptID, strategy, targetKey, status, quantity, digest
        ):
            return "wildSubsistence|\(opportunityID ?? "none")|\(attemptID ?? "none")|"
                + "\(strategy ?? "none")|\(targetKey ?? "none")|\(status)|\(quantity)|\(digest)"
        case let .livestock(herdID, animalRecordID, taskID, actionID, status, quantity, digest):
            return "livestock|\(herdID ?? "none")|\(animalRecordID ?? "none")|"
                + "\(taskID ?? "none")|\(actionID ?? "none")|\(status)|\(quantity)|\(digest)"
        case let .work(
            demandID, commitmentID, workerID, observerID, domain,
            sourceEventID, status, quantity, score, digest
        ):
            return "work|\(demandID ?? "none")|\(commitmentID ?? "none")|"
                + "\(workerID ?? "none")|\(observerID ?? "none")|\(domain ?? "none")|"
                + "\(sourceEventID ?? "none")|\(status)|\(quantity)|\(score)|\(digest)"
        }
    }
}

public struct AgentCausalEvent: Codable, Equatable, Sendable {
    public static let maximumCauseCount = 8
    public let schemaVersion: Int
    public let eventID: AgentCausalEventID
    public let simulationID: AgentSimulationID
    public let sequence: AgentCausalSequence
    public let simulationTick: AgentSimulationTick
    public let instant: AgentSimulationInstant
    public let kind: AgentCausalEventKind
    public let origin: AgentCausalOrigin
    public let actorID: AgentID?
    public let subjectID: AgentID?
    public let operationID: AgentOperationID?
    public let causes: [AgentCausalEventID]
    public let payload: AgentCausalPayload
    public let summary: String
    public let digest: String

    init(
        id: AgentCausalEventID,
        instant: AgentSimulationInstant,
        kind: AgentCausalEventKind,
        origin: AgentCausalOrigin,
        actorID: AgentID?,
        subjectID: AgentID?,
        operationID: AgentOperationID?,
        causes: [AgentCausalEventID],
        payload: AgentCausalPayload,
        summary: String
    ) throws {
        try Self.validate(payload: payload, for: kind)
        try Self.validate(causes: causes, for: id)
        schemaVersion = 1
        eventID = id
        simulationID = instant.simulationID
        sequence = id.sequence
        simulationTick = instant.tick
        self.instant = instant
        self.kind = kind
        self.origin = origin
        self.actorID = actorID
        self.subjectID = subjectID
        self.operationID = operationID
        self.causes = causes
        self.payload = payload
        self.summary = String(summary.prefix(160))
        digest = Self.digest(
            "\(id.rawValue)|\(instant.tick.rawValue)|\(kind.rawValue)|\(origin.rawValue)|"
                + "\(actorID?.rawValue ?? "-")|\(subjectID?.rawValue ?? "-")|"
                + "\(operationID?.rawValue ?? "-")|"
                + causes.map(\.rawValue).joined(separator: ",")
                + "|\(payload.canonicalText)|\(self.summary)"
        )
    }

    public static func validate(
        payload: AgentCausalPayload,
        for kind: AgentCausalEventKind
    ) throws {
        let matches: Bool
        switch (kind, payload) {
        case (.sessionLifecycle, .lifecycle), (.tickCompleted, .lifecycle),
             (.featureToggle, .feature), (.perception, .perception),
             (.goalTransition, .cognitive), (.actionSelected, .cognitive),
             (.movement, .movement), (.interaction, .operation),
             (.delivery, .operation), (.consumption, .operation),
             (.physicalFoodSurvivalInitialized, .feature),
             (.physicalFoodConsumed, .operation),
             (.constructionFunding, .operation), (.constructionPlacement, .operation),
             (.constructionCompletion, .operation), (.constructionClear, .operation),
             (.resourceFactGrounded, .resourceFact),
             (.socialMessageSent, .socialMessage),
             (.socialMessageReceived, .socialMessage),
             (.socialBeliefChanged, .socialBelief),
             (.socialVerification, .socialVerification),
             (.trustChanged, .trust),
             (.socialStateCleared, .socialClear),
             (.physicalSignalEmitted, .physicalSignal),
             (.physicalSignalPerceived, .physicalPerception),
             (.physicalSignalDecoded, .physicalPerception),
             (.physicalSignalExpired, .physicalSignal),
             (.physicalStateCleared, .physicalClear),
             (.sharedTaskCreated, .cooperationTask),
             (.sharedTaskSignaled, .cooperationTask),
             (.sharedTaskOffered, .cooperationTask),
             (.sharedTaskAccepted, .cooperationTask),
             (.sharedTaskDeclined, .cooperationTask),
             (.sharedTaskStarted, .cooperationTask),
             (.sharedTaskProgress, .cooperationTask),
             (.sharedTaskCompleted, .cooperationTask),
             (.sharedTaskExpired, .cooperationTask),
             (.sharedTaskCancelled, .cooperationTask),
             (.sharedTaskFailed, .cooperationTask),
             (.sharedTaskSuperseded, .cooperationTask),
             (.cooperationReliabilityChanged, .cooperationReliability),
             (.cooperationStateCleared, .cooperationClear),
             (.populationRegistryInitialized, .population),
             (.populationMemberRegistered, .population),
             (.populationStateCleared, .population),
             (.migrationProposed, .migration),
             (.migrationAdmitted, .migration),
             (.migrationStarted, .migration),
             (.migrationArrived, .migration),
             (.migrationRejected, .migration),
             (.migrationCancelled, .migration),
             (.migrationFailed, .migration),
             (.settlementMetricsInitialized, .settlementMetrics),
             (.settlementMacroPulse, .settlementMetrics),
             (.settlementMetricsCleared, .settlementMetrics),
             (.settlementMetricsDisabled, .settlementMetrics),
             (.localEcologyInitialized, .ecologyPatch),
             (.ecologyPatchRegistered, .ecologyPatch),
             (.ecologyPatchRegenerated, .ecologyPatch),
             (.ecologyPatchDepleted, .ecologyPatch),
             (.ecologyPatchInvalidated, .ecologyPatch),
             (.ecologyForageResolved, .ecologyForage),
             (.subsistencePressureChanged, .subsistencePressure),
             (.localEcologyStateCleared, .ecologyClear),
             (.mortalityInitialized, .mortalityDeath),
             (.lethalHealthDepletion, .mortalityDeath),
             (.agentDeathFinalized, .mortalityDeath),
             (.populationMemberExited, .mortalityDeath),
             (.mortalityResourcesRetired, .mortalityResources),
             (.mortalityCommitmentsResolved, .mortalityCommitments),
             (.mortalityStateCleared, .mortalityClear),
             (.lifecycleInitialized, .lifecycleMember),
             (.lifecycleMemberRegistered, .lifecycleMember),
             (.lifeStageChanged, .lifecycleMember),
             (.lifecycleMemberExited, .lifecycleMember),
             (.lifecycleStateCleared, .lifecycleMember),
             (.reproductionEnabled, .reproductionPlan),
             (.reproductionDisabled, .reproductionPlan),
             (.reproductionPlanCreated, .reproductionPlan),
             (.reproductionPlanCancelled, .reproductionPlan),
             (.birthSiteValidated, .birth),
             (.populationMemberBorn, .birth),
             (.birthFinalized, .birth),
             (.kinshipInitialized, .kinship),
             (.kinshipPersonRegistered, .kinship),
             (.kinshipParentageRecorded, .kinship),
             (.householdsInitialized, .household),
             (.householdCreated, .household),
             (.householdMembershipStarted, .household),
             (.householdMembershipEnded, .household),
             (.householdDissolved, .household),
             (.dependentCareInitialized, .dependentCare),
             (.careAssignmentStarted, .dependentCare),
             (.careAssignmentEnded, .dependentCare),
             (.careNeedRaised, .dependentCare),
             (.careEngagementStarted, .dependentCare),
             (.careProvided, .dependentCare),
             (.careNeedResolved, .dependentCare),
             (.careNeedUnmet, .dependentCare),
             (.skillsInitialized, .skill),
             (.skillPracticeCredited, .skill),
             (.teachingInitialized, .teaching),
             (.apprenticeshipStarted, .teaching),
             (.demonstrationObserved, .teaching),
             (.apprenticeshipEnded, .teaching),
             (.guidedPracticeLinked, .teaching),
             (.ecologicalObservationInitialized, .ecologicalObservation),
             (.ecologicalObservationRecorded, .ecologicalObservation),
             (.agricultureInitialized, .agriculture),
             (.agriculturalPlotPlanned, .agriculture),
             (.agriculturalCellPrepared, .agriculture),
             (.agriculturalCropPlanted, .agriculture),
             (.agriculturalCropMatured, .agriculture),
             (.agriculturalCropHarvested, .agriculture),
             (.agriculturalSurplusStored, .agriculture),
             (.agriculturalCellReconciled, .agriculture),
             (.wildSubsistenceInitialized, .wildSubsistence),
             (.subsistenceOpportunitySelected, .wildSubsistence),
             (.fishingCatchAcquired, .wildSubsistence),
             (.wildAnimalHunted, .wildSubsistence),
             (.wildResourceGathered, .wildSubsistence),
             (.wildSubsistenceAttemptFailed, .wildSubsistence),
             (.livestockInitialized, .livestock),
             (.livestockGroupEstablished, .livestock),
             (.managedAnimalAdded, .livestock),
             (.animalFed, .livestock),
             (.animalBreedingObserved, .livestock),
             (.animalProductAcquired, .livestock),
             (.managedAnimalLost, .livestock),
             (.livestockTaskCompleted, .livestock),
             (.workCommitmentsInitialized, .work),
             (.workDemandRefreshed, .work),
             (.workMatchingSelected, .work),
             (.workCommitmentStarted, .work),
             (.workCommitmentRenewed, .work),
             (.workCommitmentSuspended, .work),
             (.workCommitmentResumed, .work),
             (.workCommitmentFulfilled, .work),
             (.workCommitmentEnded, .work),
             (.workCommitmentReassigned, .work),
             (.workOutcomeValidated, .work),
             (.workReputationUpdated, .work),
             (.materialRightsInitialized, .feature),
             (.materialAssetRegistered, .operation),
             (.materialPhysicalCustodyObserved, .operation),
             (.materialClaimChanged, .operation),
             (.materialOwnershipRecognized, .operation),
             (.materialCustodyChanged, .operation),
             (.materialUsePermissionChanged, .operation),
             (.materialUseDecided, .operation):
            matches = true
        default:
            matches = false
        }
        guard matches else { throw AgentCausalLedgerError.payloadMismatch(kind) }
    }

    public static func validate(
        causes: [AgentCausalEventID],
        for eventID: AgentCausalEventID
    ) throws {
        guard causes.count <= maximumCauseCount else {
            throw AgentCausalLedgerError.tooManyCauses(causes.count)
        }
        var prior: AgentCausalEventID?
        for cause in causes {
            guard cause.simulationID == eventID.simulationID else {
                throw AgentCausalLedgerError.crossSimulationCause(cause)
            }
            guard cause.sequence < eventID.sequence else {
                throw AgentCausalLedgerError.nonPriorCause(cause)
            }
            if prior == cause { throw AgentCausalLedgerError.duplicateCause(cause) }
            prior = cause
        }
        guard causes == causes.sorted() else {
            throw AgentCausalLedgerError.nonPriorCause(causes[0])
        }
    }

    static func digest(_ text: String) -> String {
        var value: UInt64 = 14_695_981_039_346_656_037
        for byte in text.utf8 {
            value ^= UInt64(byte)
            value &*= 1_099_511_628_211
        }
        let digits = String(value, radix: 16, uppercase: false)
        return String(repeating: "0", count: 16 - digits.count) + digits
    }
}

public struct AgentCausalLedgerSummary: Codable, Equatable, Sendable {
    public let simulationID: AgentSimulationID
    public let currentTick: AgentSimulationTick
    public let latestSequence: UInt64
    public let nextSequence: UInt64?
    public let retainedEventCount: Int
    public let droppedEventCount: UInt64
    public let firstRetainedEventID: AgentCausalEventID?
    public let lastRetainedEventID: AgentCausalEventID?
    public let retainedCauseCoverageComplete: Bool
    public let digest: String
}

public struct AgentCausalLedgerSnapshot: Codable, Equatable, Sendable {
    public let summary: AgentCausalLedgerSummary
    public let events: [AgentCausalEvent]
}

struct AgentCausalLedger {
    let policy: AgentCausalLedgerPolicy
    private(set) var events: [AgentCausalEvent] = []
    private(set) var latestSequence: UInt64 = 0
    private(set) var droppedEventCount: UInt64 = 0
    private(set) var rollingDigest = AgentCausalEvent.digest("")

    var isEnabled: Bool {
        if case .bounded = policy { return true }
        return false
    }

    init(policy: AgentCausalLedgerPolicy) throws {
        if case let .bounded(maxEvents) = policy, maxEvents <= 0 {
            throw AgentCausalLedgerError.invalidBound(maxEvents)
        }
        self.policy = policy
    }

    init(restoring state: AgentCausalLedgerDurableState) throws {
        if case let .bounded(maxEvents) = state.policy, maxEvents <= 0 {
            throw AgentCausalLedgerError.invalidBound(maxEvents)
        }
        policy = state.policy
        events = state.events
        latestSequence = state.latestSequence
        droppedEventCount = state.droppedEventCount
        rollingDigest = state.rollingDigest
    }

    func prevalidateAppend(count: Int) throws {
        guard case .bounded = policy else { return }
        guard count >= 0, UInt64(count) <= UInt64.max - latestSequence else {
            throw AgentCausalLedgerError.sequenceOverflow
        }
    }

    mutating func append(
        instant: AgentSimulationInstant,
        kind: AgentCausalEventKind,
        origin: AgentCausalOrigin,
        actorID: AgentID? = nil,
        subjectID: AgentID? = nil,
        operationID: AgentOperationID? = nil,
        causes: [AgentCausalEventID] = [],
        payload: AgentCausalPayload,
        summary: String
    ) throws -> AgentCausalEvent? {
        guard case let .bounded(maxEvents) = policy else { return nil }
        guard latestSequence < UInt64.max else { throw AgentCausalLedgerError.sequenceOverflow }
        let sequence = AgentCausalSequence(rawValue: latestSequence + 1)!
        let event = try AgentCausalEvent(
            id: AgentCausalEventID(simulationID: instant.simulationID, sequence: sequence),
            instant: instant,
            kind: kind,
            origin: origin,
            actorID: actorID,
            subjectID: subjectID,
            operationID: operationID,
            causes: causes,
            payload: payload,
            summary: summary
        )
        latestSequence = sequence.rawValue
        rollingDigest = AgentCausalEvent.digest("\(rollingDigest)|\(event.digest)")
        events.append(event)
        if events.count > maxEvents {
            let removed = events.count - maxEvents
            events.removeFirst(removed)
            droppedEventCount += UInt64(removed)
        }
        return event
    }

    func snapshot(instant: AgentSimulationInstant, tail limit: Int? = nil) -> AgentCausalLedgerSnapshot {
        let selected = limit.map { Array(events.suffix(max(0, $0))) } ?? events
        return AgentCausalLedgerSnapshot(
            summary: AgentCausalLedgerSummary(
                simulationID: instant.simulationID,
                currentTick: instant.tick,
                latestSequence: latestSequence,
                nextSequence: latestSequence == UInt64.max ? nil : latestSequence + 1,
                retainedEventCount: events.count,
                droppedEventCount: droppedEventCount,
                firstRetainedEventID: events.first?.eventID,
                lastRetainedEventID: events.last?.eventID,
                retainedCauseCoverageComplete: droppedEventCount == 0,
                digest: rollingDigest
            ),
            events: selected
        )
    }
}
