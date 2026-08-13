import Foundation

public enum AgentReplaySchema {
    public static let currentVersion = 1
    public static let populationVersion = 2
    public static let settlementMetricsVersion = 3
    public static let localEcologyVersion = 4
    public static let mortalityVersion = 5
    public static let lifecycleVersion = 6
    public static let kinshipVersion = 7
    public static let householdVersion = 8
    public static let dependentCareVersion = 9
    public static let skillVersion = 10
    public static let teachingVersion = 11
    public static let ecologicalObservationVersion = 12
    public static let agricultureVersion = 13
    public static let wildSubsistenceVersion = 14
    public static let livestockVersion = 15
    public static let workCommitmentVersion = 16
    public static let physicalFoodSurvivalVersion = 17
    public static let autonomousActivityVersion = 18
    public static let materialRightsVersion = 19
    public static let persistenceReconciliationVersion = 20
    public static let homeostasisVersion = 21
    public static let geneticsVersion = 22
    public static let childhoodVersion = 23
    public static let verifiedSupervisionVersion = 24
    public static let familyVersion = 25
    public static let durableHouseConsentVersion = 26
    public static let legacyEstateVersion = 27
    public static let estateVersion = 28
    public static let renewableSubsistenceVersion = 29
    public static let independentEcologicalReceiptVersion = 30
    public static let productionVersion = 31

    public static func supports(_ version: Int) -> Bool {
        version == currentVersion || version == populationVersion
            || version == settlementMetricsVersion || version == localEcologyVersion
            || version == mortalityVersion || version == lifecycleVersion
            || version == kinshipVersion || version == householdVersion
            || version == dependentCareVersion || version == skillVersion
            || version == teachingVersion || version == ecologicalObservationVersion
            || version == agricultureVersion || version == wildSubsistenceVersion
            || version == livestockVersion || version == workCommitmentVersion
            || version == physicalFoodSurvivalVersion || version == autonomousActivityVersion
            || version == materialRightsVersion || version == persistenceReconciliationVersion
            || version == homeostasisVersion || version == geneticsVersion
            || version == childhoodVersion || version == verifiedSupervisionVersion
            || version == familyVersion || version == durableHouseConsentVersion
            || version == legacyEstateVersion || version == estateVersion
            || version == renewableSubsistenceVersion
            || version == independentEcologicalReceiptVersion
            || version == productionVersion
    }
}

public struct AgentReplayRecordSequence: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: UInt64

    public init?(rawValue: UInt64) {
        guard rawValue > 0 else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: AgentReplayRecordSequence, rhs: AgentReplayRecordSequence) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum AgentReplayOperationKind: String, Codable, CaseIterable, Sendable {
    case advanceTick
    case externalUpdate
    case movementOutcomes
    case verifiedPhysicalMovements
    case interactionOutcome
    case deliveryOutcome
    case consumptionOutcome
    case economyFeature
    case naturalResourcesFeature
    case survivalFeature
    case constructionFeature
    case socialFeature
    case physicalFeature
    case cooperationFeature
    case constructionProjectCreation
    case constructionFunding
    case constructionPlacement
    case constructionFailure
    case constructionCompletion
    case constructionClear
    case socialVerification
    case socialClear
    case physicalPresentationClaim
    case physicalClear
    case cooperationClear
    case populationFeature
    case populationRegistryInitialization
    case migrationAdmission
    case populationClear
    case settlementMetricsFeature
    case settlementMetricsClear
    case settlementPulseBoundary
    case localEcologyFeature
    case localEcologyInitialization
    case ecologyHabitatValidation
    case ecologyForageOutcomes
    case ecologyClear
    case mortalityFeature
    case mortalityClear
    case mortalityPhysicalCustodyResolution
    case mortalityFinalization
    case lifecycleFeature
    case reproductionFeature
    case birthSiteObservation
    case lifecycleClear
    case kinshipFeature
    case householdFeature
    case householdFormation
    case householdMove
    case dependentCareFeature
    case dependentCareProvision
    case dependentCareInteraction
    case dependentCareSupervisionProgress
    case skillFeature
    case teachingFeature
    case apprenticeshipStart
    case teachingDemonstration
    case apprenticeshipEnd
    case guidedPractice
    case ecologicalObservationFeature
    case ecologicalObservationRecord
    case agricultureFeature
    case agriculturalPlotPlanning
    case agriculturalReservation
    case agriculturalAction
    case wildSubsistenceFeature
    case subsistenceOpportunitySelection
    case wildSubsistenceOutcome
    case livestockFeature
    case livestockOperation
    case workCommitmentFeature
    case workCommitmentOperation
    case physicalFoodSurvivalFeature
    case validatedPhysicalFoodConsumption
    case autonomousActivityFeature
    case autonomousActivitySelection
    case autonomousActivityOutcome
    case productiveSourceFeature
    case productiveSourceObservations
    case productiveSourceSuccess
    case productiveSourceReview
    case validatedPhysicalDependentFood
    case materialRightsFeature
    case materialRightsOperation
    case homeostasisFeature
    case geneticsFeature
    case childhoodFeature
    case dependentCareDelegation
    case guardianshipReassignment
    case familyFeature
    case unionProposal
    case unionAcceptance
    case unionTermination
    case lineageFoundation
    case houseFoundation
    case houseMembership
    case estateFeature
    case estateAdministration
    case estateSettlement
    case productionFeature
    case productionNeed
    case productionOpportunity
    case productionOutcome
    case producedGoodUse
}

public enum AgentReplayOperation: Codable {
    case advanceTick(
        perceptions: [AgentPerceptionInput],
        physicalObservations: [AgentPhysicalSignalObservation]
    )
    case externalUpdate(AgentExternalUpdate)
    case movementOutcomes([AgentMovementOutcome])
    case verifiedPhysicalMovements([AgentVerifiedPhysicalMovement])
    case interactionOutcome(AgentInteractionOutcome)
    case deliveryOutcome(AgentDeliveryOutcome)
    case consumptionOutcome(AgentConsumptionOutcome)
    case setEconomyEnabled(Bool)
    case setNaturalResourcesEnabled(Bool)
    case setSurvivalEnabled(Bool)
    case setBuildAutoEnabled(Bool)
    case setSocialEnabled(Bool)
    case setPhysicalEnabled(Bool)
    case setCooperationEnabled(Bool)
    case createConstructionProject(AgentConstructionProject)
    case fundConstructionProject(fundingID: String, builderAgentID: String, tick: Int)
    case applyPlacementOutcome(AgentPlacementOutcome)
    case recordConstructionFailure(
        failureID: String,
        projectID: String,
        builderAgentID: String,
        failure: AgentConstructionFailure,
        reason: String
    )
    case completeConstructionProject(projectID: String, tick: Int)
    case clearConstructionProject(projectID: String)
    case applySocialVerification(AgentSocialVerificationObservation)
    case clearSocialState
    case claimPhysicalPresentationRequests
    case clearPhysicalState
    case clearCooperationState
    case setPopulationEnabled(
        Bool,
        settlementAnchor: AgentPosition?,
        receptionPosition: AgentPosition?,
        configuration: AgentPopulationConfiguration
    )
    case initializePopulationRegistry(
        settlementAnchor: AgentPosition,
        receptionPosition: AgentPosition,
        configuration: AgentPopulationConfiguration
    )
    case admitMigration(
        intent: AgentMigrationAdmissionIntent,
        observation: AgentMigrationWorldObservation
    )
    case clearPopulationDiagnostics
    case setSettlementMetricsEnabled(Bool, configuration: AgentSettlementMetricsConfiguration)
    case clearSettlementMetrics
    case settlementPulseBoundary
    case setLocalEcologyEnabled(Bool)
    case initializeLocalEcology(
        observations: [AgentEcologyHabitatObservation],
        configuration: AgentLocalEcologyConfiguration
    )
    case applyHabitatValidation([AgentEcologyHabitatObservation])
    case applyForageOutcomes(
        intents: [AgentForageIntent],
        habitatValidations: [AgentEcologyHabitatObservation]
    )
    case clearEcologyDiagnostics
    case setMortalityEnabled(Bool, configuration: AgentMortalityConfiguration)
    case clearMortalityDiagnostics
    case applyMortalityPhysicalCustodyOutcome(
        AgentMortalityPhysicalCustodyOutcome
    )
    case finalizePendingMortality(AgentID)
    case setLifecycleEnabled(Bool, configuration: AgentLifecycleConfiguration)
    case setReproductionEnabled(Bool)
    case applyBirthSiteObservation(AgentBirthSiteObservation)
    case clearLifecycleDiagnostics
    case setKinshipEnabled(Bool, configuration: AgentKinshipConfiguration)
    case setHouseholdsEnabled(Bool, configuration: AgentHouseholdConfiguration)
    case formHousehold(memberIDs: [AgentID], residenceAnchor: AgentPosition)
    case moveHouseholdMembers(memberIDs: [AgentID], householdID: AgentHouseholdID)
    case setDependentCareEnabled(Bool, configuration: AgentDependentCareConfiguration)
    case provideDependentNourishment(AgentCareProvisionIntent)
    case completeDependentCareInteraction(caregiverID: AgentID, dependentID: AgentID)
    case verifyDependentCareSupervisionTick(
        caregiverID: AgentID, dependentID: AgentID
    )
    case setSkillsEnabled(Bool, configuration: AgentSkillConfiguration)
    case setTeachingEnabled(Bool, configuration: AgentTeachingConfiguration)
    case startApprenticeship(AgentMentorSelectionRequest)
    case recordTeachingDemonstration(AgentTeachingObservation)
    case endApprenticeship(
        apprenticeshipID: AgentApprenticeshipID,
        participantID: AgentID,
        reason: AgentApprenticeshipEndReason
    )
    case linkGuidedPractice(
        exposureID: AgentLearningExposureID,
        studentSourceSuccessEventID: AgentCausalEventID,
        skillPracticeEventID: AgentCausalEventID
    )
    case setEcologicalObservationEnabled(
        Bool,
        configuration: AgentEcologicalObservationConfiguration
    )
    case recordEcologicalObservation(AgentEcologicalObservation)
    case recordEcologicalObservationWithPhysicalReceipt(
        AgentEcologicalObservation,
        physicalReceiptID: AgentPhysicalObservationReceiptID
    )
    case setAgricultureEnabled(Bool, configuration: AgentAgricultureConfiguration)
    case planAgriculturalPlot(
        plannerID: AgentID,
        positions: [AgentPosition],
        crop: AgentAgriculturalCrop,
        sourceObservationEventID: AgentCausalEventID,
        designatedStorageLocationID: String
    )
    case reserveAgriculturalCell(
        plotID: AgentAgriculturalPlotID,
        cellIndex: Int,
        contenders: [AgentID]
    )
    case recordAgriculturalAction(AgentAgriculturalActionOutcome)
    case renewAgriculturalPlot(
        plotID: AgentAgriculturalPlotID,
        plannerID: AgentID,
        sourceObservationEventID: AgentCausalEventID
    )
    case setWildSubsistenceEnabled(Bool, configuration: AgentWildSubsistenceConfiguration)
    case selectWildSubsistenceOpportunity(AgentSubsistenceDecisionContext)
    case recordWildSubsistenceOutcome(AgentSubsistenceOutcome)
    case setLivestockEnabled(Bool, configuration: AgentLivestockConfiguration)
    case applyLivestockOperation(AgentLivestockOperation)
    case setWorkCommitmentsEnabled(
        Bool, configuration: AgentWorkCommitmentConfiguration
    )
    case applyWorkCommitmentOperation(AgentWorkCommitmentOperation)
    case setPhysicalFoodSurvivalEnabled(Bool)
    case validatedPhysicalFoodConsumption(AgentValidatedPhysicalFoodConsumptionOutcome)
    case setAutonomousActivityEnabled(
        Bool, configuration: AgentAutonomousActivityConfiguration
    )
    case selectAutonomousActivities([AgentAutonomousActivityCandidate])
    case autonomousActivityOutcome(AgentAutonomousActivityOutcome)
    case setProductiveSourceLifecycleEnabled(
        Bool, configuration: AgentProductiveSourceConfiguration
    )
    case recordProductiveSourceObservations(
        [AgentProductiveSourceObservation]
    )
    case recordProductiveSourceSuccess(
        sourceKey: String,
        expectedMaterialFingerprint: String,
        physicalReceiptID: String
    )
    case reviewProductiveSources
    case validatedPhysicalDependentFood(AgentValidatedPhysicalDependentFoodOutcome)
    case setMaterialRightsEnabled(Bool, configuration: AgentMaterialRightsConfiguration)
    case applyMaterialRightsOperation(AgentMaterialRightsOperation)
    case setHomeostasisEnabled(
        Bool, configuration: AgentHomeostasisConfiguration
    )
    case setGeneticsEnabled(
        Bool, configuration: AgentGeneticsConfiguration
    )
    case setChildhoodV2Enabled(
        Bool, configuration: AgentChildhoodConfiguration
    )
    case delegateDependentCare(dependentID: AgentID, caregiverID: AgentID)
    case reassignGuardian(dependentID: AgentID, guardianID: AgentID)
    case setFamilyV1Enabled(
        Bool, configuration: AgentFamilyConfiguration
    )
    case proposeUnion(AgentFamilyInteractionReceipt)
    case acceptUnion(
        proposalID: AgentUnionProposalID,
        receipt: AgentFamilyInteractionReceipt
    )
    case endUnion(
        unionID: AgentUnionID,
        reason: AgentUnionTerminationReason,
        receipt: AgentFamilyInteractionReceipt
    )
    case foundLineage(rootPersonID: AgentID, actorID: AgentID, operationID: String)
    case foundHouse(founderID: AgentID, operationID: String)
    case coFoundHouse(
        founderIDs: [AgentID], receipts: [AgentFamilyInteractionReceipt]
    )
    case joinHouse(
        houseID: AgentHouseID,
        request: AgentFamilyInteractionReceipt,
        acceptance: AgentFamilyInteractionReceipt
    )
    case leaveHouse(houseID: AgentHouseID, agentID: AgentID, operationID: String)
    case setEstatesEnabled(Bool, configuration: AgentEstateConfiguration)
    case acceptEstateAdministration(
        estateID: AgentEstateID,
        administratorID: AgentID,
        operationID: String
    )
    case applyEstatePhysicalSettlement(AgentEstatePhysicalSettlementOutcome)
    case setProductionEnabled(Bool, configuration: AgentProductionConfiguration)
    case raiseProductionNeed(
        needID: AgentProductionNeedID,
        actorID: AgentID,
        reason: AgentProductionNeedReason,
        desiredOutputItemKey: String,
        quantity: Int,
        priority: Int
    )
    case recordProductionOpportunity(AgentProductionOpportunityObservation)
    case recordVerifiedProduction(AgentVerifiedProductionOutcome)
    case recordProducedGoodUse(AgentProducedGoodUseOutcome)

    public var kind: AgentReplayOperationKind {
        switch self {
        case .advanceTick: return .advanceTick
        case .externalUpdate: return .externalUpdate
        case .movementOutcomes: return .movementOutcomes
        case .verifiedPhysicalMovements: return .verifiedPhysicalMovements
        case .interactionOutcome: return .interactionOutcome
        case .deliveryOutcome: return .deliveryOutcome
        case .consumptionOutcome: return .consumptionOutcome
        case .setEconomyEnabled: return .economyFeature
        case .setNaturalResourcesEnabled: return .naturalResourcesFeature
        case .setSurvivalEnabled: return .survivalFeature
        case .setBuildAutoEnabled: return .constructionFeature
        case .setSocialEnabled: return .socialFeature
        case .setPhysicalEnabled: return .physicalFeature
        case .setCooperationEnabled: return .cooperationFeature
        case .createConstructionProject: return .constructionProjectCreation
        case .fundConstructionProject: return .constructionFunding
        case .applyPlacementOutcome: return .constructionPlacement
        case .recordConstructionFailure: return .constructionFailure
        case .completeConstructionProject: return .constructionCompletion
        case .clearConstructionProject: return .constructionClear
        case .applySocialVerification: return .socialVerification
        case .clearSocialState: return .socialClear
        case .claimPhysicalPresentationRequests: return .physicalPresentationClaim
        case .clearPhysicalState: return .physicalClear
        case .clearCooperationState: return .cooperationClear
        case .setPopulationEnabled: return .populationFeature
        case .initializePopulationRegistry: return .populationRegistryInitialization
        case .admitMigration: return .migrationAdmission
        case .clearPopulationDiagnostics: return .populationClear
        case .setSettlementMetricsEnabled: return .settlementMetricsFeature
        case .clearSettlementMetrics: return .settlementMetricsClear
        case .settlementPulseBoundary: return .settlementPulseBoundary
        case .setLocalEcologyEnabled: return .localEcologyFeature
        case .initializeLocalEcology: return .localEcologyInitialization
        case .applyHabitatValidation: return .ecologyHabitatValidation
        case .applyForageOutcomes: return .ecologyForageOutcomes
        case .clearEcologyDiagnostics: return .ecologyClear
        case .setMortalityEnabled: return .mortalityFeature
        case .clearMortalityDiagnostics: return .mortalityClear
        case .applyMortalityPhysicalCustodyOutcome:
            return .mortalityPhysicalCustodyResolution
        case .finalizePendingMortality: return .mortalityFinalization
        case .setLifecycleEnabled: return .lifecycleFeature
        case .setReproductionEnabled: return .reproductionFeature
        case .applyBirthSiteObservation: return .birthSiteObservation
        case .clearLifecycleDiagnostics: return .lifecycleClear
        case .setKinshipEnabled: return .kinshipFeature
        case .setHouseholdsEnabled: return .householdFeature
        case .formHousehold: return .householdFormation
        case .moveHouseholdMembers: return .householdMove
        case .setDependentCareEnabled: return .dependentCareFeature
        case .provideDependentNourishment: return .dependentCareProvision
        case .completeDependentCareInteraction: return .dependentCareInteraction
        case .verifyDependentCareSupervisionTick:
            return .dependentCareSupervisionProgress
        case .setSkillsEnabled: return .skillFeature
        case .setTeachingEnabled: return .teachingFeature
        case .startApprenticeship: return .apprenticeshipStart
        case .recordTeachingDemonstration: return .teachingDemonstration
        case .endApprenticeship: return .apprenticeshipEnd
        case .linkGuidedPractice: return .guidedPractice
        case .setEcologicalObservationEnabled: return .ecologicalObservationFeature
        case .recordEcologicalObservation,
             .recordEcologicalObservationWithPhysicalReceipt:
            return .ecologicalObservationRecord
        case .setAgricultureEnabled: return .agricultureFeature
        case .planAgriculturalPlot: return .agriculturalPlotPlanning
        case .reserveAgriculturalCell: return .agriculturalReservation
        case .recordAgriculturalAction: return .agriculturalAction
        case .renewAgriculturalPlot: return .agriculturalAction
        case .setWildSubsistenceEnabled: return .wildSubsistenceFeature
        case .selectWildSubsistenceOpportunity: return .subsistenceOpportunitySelection
        case .recordWildSubsistenceOutcome: return .wildSubsistenceOutcome
        case .setLivestockEnabled: return .livestockFeature
        case .applyLivestockOperation: return .livestockOperation
        case .setWorkCommitmentsEnabled: return .workCommitmentFeature
        case .applyWorkCommitmentOperation: return .workCommitmentOperation
        case .setPhysicalFoodSurvivalEnabled: return .physicalFoodSurvivalFeature
        case .validatedPhysicalFoodConsumption: return .validatedPhysicalFoodConsumption
        case .setAutonomousActivityEnabled: return .autonomousActivityFeature
        case .selectAutonomousActivities: return .autonomousActivitySelection
        case .autonomousActivityOutcome: return .autonomousActivityOutcome
        case .setProductiveSourceLifecycleEnabled:
            return .productiveSourceFeature
        case .recordProductiveSourceObservations:
            return .productiveSourceObservations
        case .recordProductiveSourceSuccess:
            return .productiveSourceSuccess
        case .reviewProductiveSources:
            return .productiveSourceReview
        case .validatedPhysicalDependentFood: return .validatedPhysicalDependentFood
        case .setMaterialRightsEnabled: return .materialRightsFeature
        case .applyMaterialRightsOperation: return .materialRightsOperation
        case .setHomeostasisEnabled: return .homeostasisFeature
        case .setGeneticsEnabled: return .geneticsFeature
        case .setChildhoodV2Enabled: return .childhoodFeature
        case .delegateDependentCare: return .dependentCareDelegation
        case .reassignGuardian: return .guardianshipReassignment
        case .setFamilyV1Enabled: return .familyFeature
        case .proposeUnion: return .unionProposal
        case .acceptUnion: return .unionAcceptance
        case .endUnion: return .unionTermination
        case .foundLineage: return .lineageFoundation
        case .foundHouse, .coFoundHouse: return .houseFoundation
        case .joinHouse, .leaveHouse: return .houseMembership
        case .setEstatesEnabled: return .estateFeature
        case .acceptEstateAdministration: return .estateAdministration
        case .applyEstatePhysicalSettlement: return .estateSettlement
        case .setProductionEnabled: return .productionFeature
        case .raiseProductionNeed: return .productionNeed
        case .recordProductionOpportunity: return .productionOpportunity
        case .recordVerifiedProduction: return .productionOutcome
        case .recordProducedGoodUse: return .producedGoodUse
        }
    }

    public var operationID: AgentOperationID? {
        let raw: String?
        switch self {
        case let .interactionOutcome(outcome): raw = outcome.interactionId
        case let .deliveryOutcome(outcome): raw = outcome.deliveryId
        case let .consumptionOutcome(outcome): raw = outcome.consumptionId
        case let .fundConstructionProject(fundingID, _, _): raw = fundingID
        case let .applyPlacementOutcome(outcome): raw = outcome.placementId
        case let .recordConstructionFailure(failureID, _, _, _, _): raw = failureID
        case let .completeConstructionProject(projectID, tick): raw = "\(projectID):completion:\(tick)"
        case let .clearConstructionProject(projectID): raw = "\(projectID):clear"
        case let .applySocialVerification(observation): raw = "social-verification:\(observation.beliefID.rawValue)"
        case let .applyBirthSiteObservation(observation):
            raw = "birth-site:\(observation.planID.rawValue):\(observation.observedTick)"
        case let .proposeUnion(receipt): raw = receipt.receiptID
        case let .acceptUnion(_, receipt): raw = receipt.receiptID
        case let .endUnion(_, _, receipt): raw = receipt.receiptID
        case let .foundLineage(_, _, operationID): raw = operationID
        case let .foundHouse(_, operationID): raw = operationID
        case let .coFoundHouse(_, receipts):
            raw = receipts.map(\.receiptID).sorted().joined(separator: "+")
        case let .joinHouse(_, request, acceptance):
            raw = [request.receiptID, acceptance.receiptID].sorted().joined(separator: "+")
        case let .leaveHouse(_, _, operationID): raw = operationID
        case let .acceptEstateAdministration(_, _, operationID):
            raw = operationID
        case let .applyEstatePhysicalSettlement(outcome):
            raw = outcome.operationID
        case let .raiseProductionNeed(needID, _, _, _, _, _):
            raw = "need:\(needID.rawValue)"
        case let .recordProductionOpportunity(observation):
            raw = "observe:\(observation.opportunityID.rawValue)"
        case let .recordVerifiedProduction(outcome):
            raw = outcome.operationID
        case let .recordProducedGoodUse(outcome):
            raw = outcome.operationID
        case let .provideDependentNourishment(intent): raw = intent.provisionID
        case let .startApprenticeship(request):
            raw = "teaching-start:\(request.requestID)"
        case let .recordTeachingDemonstration(observation):
            raw = "teaching-demo:\(observation.teacherID.rawValue):"
                + "\(observation.studentID.rawValue):"
                + "\(observation.sourceSuccessEventID.rawValue)"
        case let .endApprenticeship(apprenticeshipID, _, _):
            raw = "teaching-end:\(apprenticeshipID.rawValue)"
        case let .linkGuidedPractice(_, _, skillPracticeEventID):
            raw = "teaching-guided:\(skillPracticeEventID.rawValue)"
        case let .recordEcologicalObservation(observation):
            raw = "ecological-observation:\(observation.observerID.rawValue):"
                + "\(observation.observedAtSimulationTick):\(observation.digest)"
        case let .recordEcologicalObservationWithPhysicalReceipt(
            observation, physicalReceiptID
        ):
            raw = "ecological-observation:\(observation.observerID.rawValue):"
                + "\(observation.observedAtSimulationTick):\(observation.digest):"
                + physicalReceiptID.rawValue
        case let .recordAgriculturalAction(outcome): raw = outcome.actionID.rawValue
        case let .renewAgriculturalPlot(
            plotID, plannerID, sourceObservationEventID
        ):
            raw = "agriculture-renew:\(plotID.rawValue):"
                + "\(plannerID.rawValue):\(sourceObservationEventID.rawValue)"
        case let .recordWildSubsistenceOutcome(outcome): raw = outcome.attemptID.rawValue
        case let .applyLivestockOperation(operation): raw = operation.operationIDText
        case let .applyWorkCommitmentOperation(operation):
            switch operation {
            case .refreshDemands: raw = "work-refresh"
            case let .start(demandID, _): raw = "work-start:\(demandID.rawValue)"
            case let .renew(commitmentID): raw = "work-renew:\(commitmentID.rawValue)"
            case let .suspend(commitmentID, _): raw = "work-suspend:\(commitmentID.rawValue)"
            case let .resume(commitmentID): raw = "work-resume:\(commitmentID.rawValue)"
            case let .end(commitmentID, _): raw = "work-end:\(commitmentID.rawValue)"
            case let .replace(commitmentID, _): raw = "work-replace:\(commitmentID.rawValue)"
            case let .recordOutcome(outcome): raw = "work-outcome:\(outcome.sourceSuccessEventID.rawValue)"
            case .review: raw = "work-review"
            }
        case let .validatedPhysicalFoodConsumption(outcome):
            raw = outcome.consumptionID
        case let .autonomousActivityOutcome(outcome):
            raw = outcome.activityID
        case let .validatedPhysicalDependentFood(outcome):
            raw = outcome.intent.provisionID
        case let .applyMaterialRightsOperation(operation):
            raw = operation.operationID
        case let .applyMortalityPhysicalCustodyOutcome(outcome):
            raw = outcome.operationID
        case let .finalizePendingMortality(agentID):
            raw = "mortality-finalize:\(agentID.rawValue)"
        case let .selectWildSubsistenceOpportunity(context):
            raw = "subsistence-select:\(context.actorID.rawValue)"
        case let .planAgriculturalPlot(
            plannerID, _, crop, sourceObservationEventID, _
        ):
            raw = "agriculture-plan:\(plannerID.rawValue):\(crop.rawValue):"
                + sourceObservationEventID.rawValue
        default: raw = nil
        }
        return raw.flatMap(AgentOperationID.init(rawValue:))
    }
}

public struct AgentReplayApplicationResult {
    public let tick: Int
    public let causalSequence: UInt64
    public let causalDigest: String
    public let tickResult: AgentSessionTickResult?
    public let socialVerificationResult: AgentSocialVerificationResult?
    public let claimedPhysicalPresentations: [AgentPhysicalPresentationRequest]

    init(
        tick: Int,
        causalSequence: UInt64,
        causalDigest: String,
        tickResult: AgentSessionTickResult? = nil,
        socialVerificationResult: AgentSocialVerificationResult? = nil,
        claimedPhysicalPresentations: [AgentPhysicalPresentationRequest] = []
    ) {
        self.tick = tick
        self.causalSequence = causalSequence
        self.causalDigest = causalDigest
        self.tickResult = tickResult
        self.socialVerificationResult = socialVerificationResult
        self.claimedPhysicalPresentations = claimedPhysicalPresentations
    }
}

public struct AgentReplayRecord: Codable {
    public let schemaVersion: Int
    public let simulationID: AgentSimulationID
    public let recordSequence: AgentReplayRecordSequence
    public let operationKind: AgentReplayOperationKind
    public let operation: AgentReplayOperation
    public let expectedTickBefore: Int
    public let preStateSemanticDigest: AgentCheckpointDigest
    public let postStateSemanticDigest: AgentCheckpointDigest
    public let causalSequenceBefore: UInt64
    public let causalSequenceAfter: UInt64
    public let causalDigestAfter: String
    public let operationID: AgentOperationID?

    public init(
        schemaVersion: Int = AgentReplaySchema.currentVersion,
        simulationID: AgentSimulationID,
        recordSequence: AgentReplayRecordSequence,
        operation: AgentReplayOperation,
        expectedTickBefore: Int,
        preStateSemanticDigest: AgentCheckpointDigest,
        postStateSemanticDigest: AgentCheckpointDigest,
        causalSequenceBefore: UInt64,
        causalSequenceAfter: UInt64,
        causalDigestAfter: String
    ) {
        self.schemaVersion = schemaVersion
        self.simulationID = simulationID
        self.recordSequence = recordSequence
        operationKind = operation.kind
        self.operation = operation
        self.expectedTickBefore = expectedTickBefore
        self.preStateSemanticDigest = preStateSemanticDigest
        self.postStateSemanticDigest = postStateSemanticDigest
        self.causalSequenceBefore = causalSequenceBefore
        self.causalSequenceAfter = causalSequenceAfter
        self.causalDigestAfter = causalDigestAfter
        operationID = operation.operationID
    }
}

public struct AgentReplayJournalManifest: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let name: AgentCheckpointName
    public let baseCheckpointID: AgentCheckpointID
    public let baseCheckpointDigest: AgentCheckpointDigest
    public let simulationID: AgentSimulationID
    public let initialTick: Int
    public let recordCount: Int
    public let droppedRecordCount: Int
    public let replayable: Bool
    public let nonReplayableReason: String?
    public let operationsStorageDigest: AgentCheckpointDigest
    public let operationsByteLength: Int

    public init(
        schemaVersion: Int = AgentReplaySchema.currentVersion,
        name: AgentCheckpointName,
        baseCheckpointID: AgentCheckpointID,
        baseCheckpointDigest: AgentCheckpointDigest,
        simulationID: AgentSimulationID,
        initialTick: Int,
        recordCount: Int,
        droppedRecordCount: Int,
        replayable: Bool,
        nonReplayableReason: String?,
        operationsStorageDigest: AgentCheckpointDigest,
        operationsByteLength: Int
    ) {
        self.schemaVersion = schemaVersion
        self.name = name
        self.baseCheckpointID = baseCheckpointID
        self.baseCheckpointDigest = baseCheckpointDigest
        self.simulationID = simulationID
        self.initialTick = initialTick
        self.recordCount = recordCount
        self.droppedRecordCount = droppedRecordCount
        self.replayable = replayable
        self.nonReplayableReason = nonReplayableReason
        self.operationsStorageDigest = operationsStorageDigest
        self.operationsByteLength = operationsByteLength
    }
}

public struct AgentReplayJournal {
    public let manifest: AgentReplayJournalManifest
    public let records: [AgentReplayRecord]

    public init(manifest: AgentReplayJournalManifest, records: [AgentReplayRecord]) {
        self.manifest = manifest
        self.records = records
    }
}

public struct AgentReplayDivergence: Codable, Equatable, Sendable {
    public let recordSequence: UInt64
    public let operationKind: AgentReplayOperationKind
    public let operationID: AgentOperationID?
    public let reason: String
    public let expectedDigest: AgentCheckpointDigest?
    public let actualDigest: AgentCheckpointDigest?
    public let expectedTick: Int?
    public let actualTick: Int?
    public let expectedCausalSequence: UInt64?
    public let actualCausalSequence: UInt64?

    public init(
        recordSequence: UInt64,
        operationKind: AgentReplayOperationKind,
        operationID: AgentOperationID?,
        reason: String,
        expectedDigest: AgentCheckpointDigest? = nil,
        actualDigest: AgentCheckpointDigest? = nil,
        expectedTick: Int? = nil,
        actualTick: Int? = nil,
        expectedCausalSequence: UInt64? = nil,
        actualCausalSequence: UInt64? = nil
    ) {
        self.recordSequence = recordSequence
        self.operationKind = operationKind
        self.operationID = operationID
        self.reason = reason
        self.expectedDigest = expectedDigest
        self.actualDigest = actualDigest
        self.expectedTick = expectedTick
        self.actualTick = actualTick
        self.expectedCausalSequence = expectedCausalSequence
        self.actualCausalSequence = actualCausalSequence
    }
}

public struct AgentReplayReport: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let verified: Bool
    public let baseCheckpointID: AgentCheckpointID
    public let simulationID: AgentSimulationID
    public let recordsApplied: Int
    public let finalTick: Int
    public let finalSemanticDigest: AgentCheckpointDigest
    public let finalCausalSequence: UInt64
    public let finalCausalDigest: String
    public let divergence: AgentReplayDivergence?

    init(
        schemaVersion: Int = AgentReplaySchema.currentVersion,
        verified: Bool,
        baseCheckpointID: AgentCheckpointID,
        simulationID: AgentSimulationID,
        recordsApplied: Int,
        finalTick: Int,
        finalSemanticDigest: AgentCheckpointDigest,
        finalCausalSequence: UInt64,
        finalCausalDigest: String,
        divergence: AgentReplayDivergence?
    ) {
        self.schemaVersion = schemaVersion
        self.verified = verified
        self.baseCheckpointID = baseCheckpointID
        self.simulationID = simulationID
        self.recordsApplied = recordsApplied
        self.finalTick = finalTick
        self.finalSemanticDigest = finalSemanticDigest
        self.finalCausalSequence = finalCausalSequence
        self.finalCausalDigest = finalCausalDigest
        self.divergence = divergence
    }
}

public struct AgentReplayResult {
    public let report: AgentReplayReport
    public let session: AgentSimulationSession

    init(report: AgentReplayReport, session: AgentSimulationSession) {
        self.report = report
        self.session = session
    }
}

public enum AgentReplayError: Error, Equatable, CustomStringConvertible {
    case unsupportedSchema(Int)
    case baseCheckpointMismatch
    case currentStateMismatch
    case capacityReached(Int)
    case byteLimitReached(Int)
    case recordSequenceOverflow
    case invalidJournal(String)

    public var description: String {
        switch self {
        case let .unsupportedSchema(version): return "unsupported replay schema \(version)"
        case .baseCheckpointMismatch: return "replay base checkpoint mismatch"
        case .currentStateMismatch: return "replay current state differs from base checkpoint"
        case let .capacityReached(count): return "replay record capacity reached at \(count)"
        case let .byteLimitReached(bytes): return "replay byte limit reached at \(bytes)"
        case .recordSequenceOverflow: return "replay record sequence overflow"
        case let .invalidJournal(reason): return "invalid replay journal: \(reason)"
        }
    }
}

public struct AgentReplayRecorder {
    public let baseCheckpointID: AgentCheckpointID
    public let baseCheckpointDigest: AgentCheckpointDigest
    public let simulationID: AgentSimulationID
    public let initialTick: Int
    public private(set) var schemaVersion: Int
    public private(set) var records: [AgentReplayRecord]
    public private(set) var droppedRecordCount: Int
    public private(set) var nonReplayableReason: String?

    public var isReplayable: Bool {
        droppedRecordCount == 0 && nonReplayableReason == nil
    }

    public init(checkpoint: AgentSessionCheckpoint, session: AgentSimulationSession) throws {
        _ = try AgentSimulationSession.validate(checkpoint)
        let currentDigest = try session.durableStateDigest()
        guard checkpoint.simulationID == session.simulationID,
              checkpoint.tick.rawValue == session.tick,
              checkpoint.semanticDigest == currentDigest else {
            throw AgentReplayError.currentStateMismatch
        }
        baseCheckpointID = checkpoint.checkpointID
        baseCheckpointDigest = checkpoint.semanticDigest
        simulationID = checkpoint.simulationID
        initialTick = checkpoint.tick.rawValue
        schemaVersion = checkpoint.schemaVersion
            == AgentCheckpointSchema.productionVersion
            ? AgentReplaySchema.productionVersion
            : checkpoint.schemaVersion
            == AgentCheckpointSchema.independentEcologicalReceiptVersion
            ? AgentReplaySchema.independentEcologicalReceiptVersion
            : checkpoint.schemaVersion
            == AgentCheckpointSchema.renewableSubsistenceVersion
            ? AgentReplaySchema.renewableSubsistenceVersion
            : session.estatesEnabled
            ? (checkpoint.schemaVersion
                == AgentCheckpointSchema.legacyEstateVersion
                ? AgentReplaySchema.legacyEstateVersion
                : AgentReplaySchema.estateVersion)
            : (session.familyV1Enabled
                ? AgentReplaySchema.durableHouseConsentVersion
                : (session.childhoodV2Enabled
                    ? AgentReplaySchema.verifiedSupervisionVersion
                    : checkpoint.schemaVersion))
        records = []
        droppedRecordCount = 0
        nonReplayableReason = nil
    }

    @discardableResult
    public mutating func apply(
        _ operation: AgentReplayOperation,
        to session: inout AgentSimulationSession
    ) throws -> AgentReplayApplicationResult {
        guard isReplayable else {
            throw AgentReplayError.invalidJournal(nonReplayableReason ?? "records dropped")
        }
        guard records.count < AgentCheckpointLimits.maximumReplayRecords else {
            throw AgentReplayError.capacityReached(records.count)
        }
        if case let .setSettlementMetricsEnabled(enabled, _) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.settlementMetricsVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "settlement metrics activation must be the first v3 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.settlementMetricsVersion
        }
        if case .initializeLocalEcology = operation,
           schemaVersion < AgentReplaySchema.localEcologyVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "local ecology initialization must be the first v4 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.localEcologyVersion
        }
        if case let .setMortalityEnabled(enabled, _) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.mortalityVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "mortality activation must be the first v5 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.mortalityVersion
        }
        if case let .setLifecycleEnabled(enabled, _) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.lifecycleVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "lifecycle activation must be the first v6 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.lifecycleVersion
        }
        if case let .setKinshipEnabled(enabled, _) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.kinshipVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "kinship activation must be the first v7 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.kinshipVersion
        }
        if case let .setHouseholdsEnabled(enabled, _) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.householdVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "household activation must be the first v8 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.householdVersion
        }
        if case let .setDependentCareEnabled(enabled, _) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.dependentCareVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "dependent care activation must be the first v9 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.dependentCareVersion
        }
        if case let .setSkillsEnabled(enabled, _) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.skillVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "skill activation must be the first v10 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.skillVersion
        }
        if case let .setTeachingEnabled(enabled, _) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.teachingVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "teaching activation must be the first v11 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.teachingVersion
        }
        if case let .setEcologicalObservationEnabled(enabled, _) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.ecologicalObservationVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "ecological observation activation must be the first v12 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.ecologicalObservationVersion
        }
        if case .recordEcologicalObservationWithPhysicalReceipt = operation,
           schemaVersion
            < AgentReplaySchema.independentEcologicalReceiptVersion {
            schemaVersion = AgentReplaySchema
                .independentEcologicalReceiptVersion
        }
        if case let .setAgricultureEnabled(enabled, _) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.agricultureVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "agriculture activation must be the first v13 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.agricultureVersion
        }
        if case let .setWildSubsistenceEnabled(enabled, _) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.wildSubsistenceVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "wild subsistence activation must be the first v14 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.wildSubsistenceVersion
        }
        if case let .setLivestockEnabled(enabled, _) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.livestockVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "livestock activation must be the first v15 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.livestockVersion
        }
        if case let .setWorkCommitmentsEnabled(enabled, _) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.workCommitmentVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "work commitment activation must be the first v16 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.workCommitmentVersion
        }
        if case let .setPhysicalFoodSurvivalEnabled(enabled) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.physicalFoodSurvivalVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "physical food survival activation must be the first v17 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.physicalFoodSurvivalVersion
        }
        if case let .setAutonomousActivityEnabled(enabled, _) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.autonomousActivityVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "autonomous activity activation must be the first v18 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.autonomousActivityVersion
        }
        if case let .setMaterialRightsEnabled(enabled, _) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.materialRightsVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "material rights activation must be the first v19 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.materialRightsVersion
        }
        if case let .setHomeostasisEnabled(enabled, _) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.homeostasisVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "homeostasis activation must be the first v21 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.homeostasisVersion
        }
        if case let .setGeneticsEnabled(enabled, _) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.geneticsVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "genetics activation must be the first v22 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.geneticsVersion
        }
        if case let .setChildhoodV2Enabled(enabled, _) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.verifiedSupervisionVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "childhood V2 activation must be the first v24 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.verifiedSupervisionVersion
        }
        if case let .setFamilyV1Enabled(enabled, _) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.durableHouseConsentVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "family V1 activation must be the first v26 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.durableHouseConsentVersion
        }
        if case let .setEstatesEnabled(enabled, _) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.estateVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "estate activation must be the first v27 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.estateVersion
        }
        if case let .setProductionEnabled(enabled, _) = operation,
           enabled,
           schemaVersion < AgentReplaySchema.productionVersion {
            guard records.isEmpty else {
                throw AgentReplayError.invalidJournal(
                    "production activation must be the first v31 replay operation"
                )
            }
            schemaVersion = AgentReplaySchema.productionVersion
        }
        guard session.simulationID == simulationID else { throw AgentReplayError.currentStateMismatch }
        let preDigest = try session.durableStateDigest()
        let tickBefore = session.tick
        let causalBefore = session.causalLedgerSnapshot().summary
        var candidate = session
        let result = try candidate.applyReplayOperation(operation)
        let postDigest = try candidate.durableStateDigest()
        let causalAfter = candidate.causalLedgerSnapshot().summary
        let record = AgentReplayRecord(
            schemaVersion: schemaVersion,
            simulationID: simulationID,
            recordSequence: AgentReplayRecordSequence(rawValue: UInt64(records.count + 1))!,
            operation: operation,
            expectedTickBefore: tickBefore,
            preStateSemanticDigest: preDigest,
            postStateSemanticDigest: postDigest,
            causalSequenceBefore: causalBefore.latestSequence,
            causalSequenceAfter: causalAfter.latestSequence,
            causalDigestAfter: causalAfter.digest
        )
        let prospective = try AgentReplayCodec.encodeRecords(records + [record])
        guard prospective.count <= AgentCheckpointLimits.maximumReplayBytes else {
            throw AgentReplayError.byteLimitReached(prospective.count)
        }
        session = candidate
        records.append(record)
        return result
    }

    public mutating func markNonReplayable(_ reason: String) {
        if nonReplayableReason == nil { nonReplayableReason = reason }
    }

    public func journal(named name: AgentCheckpointName) throws -> AgentReplayJournal {
        let bytes = try AgentReplayCodec.encodeRecords(records)
        let manifest = AgentReplayJournalManifest(
            schemaVersion: schemaVersion,
            name: name,
            baseCheckpointID: baseCheckpointID,
            baseCheckpointDigest: baseCheckpointDigest,
            simulationID: simulationID,
            initialTick: initialTick,
            recordCount: records.count,
            droppedRecordCount: droppedRecordCount,
            replayable: isReplayable,
            nonReplayableReason: nonReplayableReason,
            operationsStorageDigest: AgentCheckpointDigest.sha256(bytes),
            operationsByteLength: bytes.count
        )
        return AgentReplayJournal(manifest: manifest, records: records)
    }
}

public enum AgentReplayCodec {
    public static func encodeRecords(_ records: [AgentReplayRecord]) throws -> Data {
        guard records.count <= AgentCheckpointLimits.maximumReplayRecords else {
            throw AgentReplayError.capacityReached(records.count)
        }
        var data = Data()
        for record in records {
            data.append(try AgentCheckpointCodec.encode(record))
            data.append(0x0a)
            guard data.count <= AgentCheckpointLimits.maximumReplayBytes else {
                throw AgentReplayError.byteLimitReached(data.count)
            }
        }
        return data
    }

    public static func decodeRecords(_ data: Data) throws -> [AgentReplayRecord] {
        guard data.count <= AgentCheckpointLimits.maximumReplayBytes else {
            throw AgentReplayError.byteLimitReached(data.count)
        }
        guard data.isEmpty || data.last == 0x0a else {
            throw AgentReplayError.invalidJournal("truncated NDJSON")
        }
        let lines = data.split(separator: 0x0a, omittingEmptySubsequences: true)
        guard lines.count <= AgentCheckpointLimits.maximumReplayRecords else {
            throw AgentReplayError.capacityReached(lines.count)
        }
        return try lines.map {
            try AgentCheckpointCodec.decode(AgentReplayRecord.self, from: Data($0))
        }
    }
}

public enum AgentSessionReplayer {
    public static func replay(
        checkpoint: AgentSessionCheckpoint,
        journal: AgentReplayJournal
    ) throws -> AgentReplayResult {
        try validateJournalEnvelope(checkpoint: checkpoint, journal: journal)
        var candidate = try AgentSimulationSession.restoring(checkpoint)
        for (index, record) in journal.records.enumerated() {
            let expectedRecordSequence = UInt64(index + 1)
            let actualDigest = try candidate.durableStateDigest()
            let causalBefore = candidate.causalLedgerSnapshot().summary
            if record.schemaVersion != journal.manifest.schemaVersion
                || record.recordSequence.rawValue != expectedRecordSequence
                || record.operationKind != record.operation.kind
                || record.operationID != record.operation.operationID
                || record.simulationID != candidate.simulationID
                || record.expectedTickBefore != candidate.tick
                || record.preStateSemanticDigest != actualDigest
                || record.causalSequenceBefore != causalBefore.latestSequence {
                return try divergentResult(
                    checkpoint: checkpoint,
                    candidate: candidate,
                    record: record,
                    recordsApplied: index,
                    reason: "pre-state or record envelope mismatch",
                    actualDigest: actualDigest,
                    actualCausalSequence: causalBefore.latestSequence
                )
            }
            do {
                _ = try candidate.applyReplayOperation(record.operation)
            } catch {
                return try divergentResult(
                    checkpoint: checkpoint,
                    candidate: candidate,
                    record: record,
                    recordsApplied: index,
                    reason: "operation rejected: \(error)",
                    actualDigest: try candidate.durableStateDigest(),
                    actualCausalSequence: candidate.causalLedgerSnapshot().summary.latestSequence
                )
            }
            let postDigest = try candidate.durableStateDigest()
            let causalAfter = candidate.causalLedgerSnapshot().summary
            if postDigest != record.postStateSemanticDigest
                || causalAfter.latestSequence != record.causalSequenceAfter
                || causalAfter.digest != record.causalDigestAfter {
                return try divergentResult(
                    checkpoint: checkpoint,
                    candidate: candidate,
                    record: record,
                    recordsApplied: index,
                    reason: "post-state mismatch",
                    actualDigest: postDigest,
                    actualCausalSequence: causalAfter.latestSequence
                )
            }
        }
        let digest = try candidate.durableStateDigest()
        let causal = candidate.causalLedgerSnapshot().summary
        return AgentReplayResult(
            report: AgentReplayReport(
                schemaVersion: journal.manifest.schemaVersion,
                verified: true,
                baseCheckpointID: checkpoint.checkpointID,
                simulationID: candidate.simulationID,
                recordsApplied: journal.records.count,
                finalTick: candidate.tick,
                finalSemanticDigest: digest,
                finalCausalSequence: causal.latestSequence,
                finalCausalDigest: causal.digest,
                divergence: nil
            ),
            session: candidate
        )
    }

    static func validateJournalEnvelope(
        checkpoint: AgentSessionCheckpoint,
        journal: AgentReplayJournal
    ) throws {
        let manifest = journal.manifest
        guard AgentReplaySchema.supports(manifest.schemaVersion) else {
            throw AgentReplayError.unsupportedSchema(manifest.schemaVersion)
        }
        let compatibleSchema = manifest.schemaVersion == checkpoint.schemaVersion
            || (manifest.schemaVersion == AgentReplaySchema.settlementMetricsVersion
                && checkpoint.schemaVersion == AgentCheckpointSchema.populationVersion)
            || (manifest.schemaVersion == AgentReplaySchema.localEcologyVersion
                && (checkpoint.schemaVersion == AgentCheckpointSchema.populationVersion
                    || checkpoint.schemaVersion == AgentCheckpointSchema.settlementMetricsVersion))
            || (manifest.schemaVersion == AgentReplaySchema.mortalityVersion
                && (checkpoint.schemaVersion == AgentCheckpointSchema.populationVersion
                    || checkpoint.schemaVersion == AgentCheckpointSchema.settlementMetricsVersion
                    || checkpoint.schemaVersion == AgentCheckpointSchema.localEcologyVersion))
            || (manifest.schemaVersion == AgentReplaySchema.lifecycleVersion
                && checkpoint.schemaVersion <= AgentCheckpointSchema.mortalityVersion)
            || (manifest.schemaVersion == AgentReplaySchema.kinshipVersion
                && checkpoint.schemaVersion == AgentCheckpointSchema.lifecycleVersion)
            || (manifest.schemaVersion == AgentReplaySchema.householdVersion
                && checkpoint.schemaVersion == AgentCheckpointSchema.kinshipVersion)
            || (manifest.schemaVersion == AgentReplaySchema.dependentCareVersion
                && checkpoint.schemaVersion == AgentCheckpointSchema.householdVersion)
            || (manifest.schemaVersion == AgentReplaySchema.skillVersion
                && checkpoint.schemaVersion <= AgentCheckpointSchema.dependentCareVersion)
            || (manifest.schemaVersion == AgentReplaySchema.teachingVersion
                && checkpoint.schemaVersion <= AgentCheckpointSchema.skillVersion)
            || (manifest.schemaVersion == AgentReplaySchema.ecologicalObservationVersion
                && checkpoint.schemaVersion <= AgentCheckpointSchema.teachingVersion)
            || (manifest.schemaVersion == AgentReplaySchema.agricultureVersion
                && checkpoint.schemaVersion <= AgentCheckpointSchema.ecologicalObservationVersion)
            || (manifest.schemaVersion == AgentReplaySchema.wildSubsistenceVersion
                && checkpoint.schemaVersion <= AgentCheckpointSchema.agricultureVersion)
            || (manifest.schemaVersion == AgentReplaySchema.livestockVersion
                && checkpoint.schemaVersion <= AgentCheckpointSchema.wildSubsistenceVersion)
            || (manifest.schemaVersion == AgentReplaySchema.workCommitmentVersion
                && checkpoint.schemaVersion <= AgentCheckpointSchema.livestockVersion)
            || (manifest.schemaVersion == AgentReplaySchema.physicalFoodSurvivalVersion
                && checkpoint.schemaVersion <= AgentCheckpointSchema.workCommitmentVersion)
            || (manifest.schemaVersion == AgentReplaySchema.autonomousActivityVersion
                && checkpoint.schemaVersion <= AgentCheckpointSchema.physicalFoodSurvivalVersion)
            || (manifest.schemaVersion == AgentReplaySchema.materialRightsVersion
                && checkpoint.schemaVersion <= AgentCheckpointSchema.autonomousActivityVersion)
            || (manifest.schemaVersion == AgentReplaySchema.homeostasisVersion
                && checkpoint.schemaVersion
                    <= AgentCheckpointSchema.persistenceReconciliationVersion)
            || (manifest.schemaVersion == AgentReplaySchema.geneticsVersion
                && checkpoint.schemaVersion
                    <= AgentCheckpointSchema.homeostasisVersion)
            || (manifest.schemaVersion == AgentReplaySchema.childhoodVersion
                && checkpoint.schemaVersion
                    <= AgentCheckpointSchema.geneticsVersion)
            || (manifest.schemaVersion
                    == AgentReplaySchema.verifiedSupervisionVersion
                && checkpoint.schemaVersion
                    <= AgentCheckpointSchema.childhoodVersion)
            || (manifest.schemaVersion == AgentReplaySchema.familyVersion
                && checkpoint.schemaVersion
                    <= AgentCheckpointSchema.verifiedSupervisionVersion)
            || (manifest.schemaVersion
                    == AgentReplaySchema.durableHouseConsentVersion
                && checkpoint.schemaVersion
                    <= AgentCheckpointSchema.familyVersion)
            || (manifest.schemaVersion == AgentReplaySchema.estateVersion
                && checkpoint.schemaVersion
                    <= AgentCheckpointSchema.legacyEstateVersion)
            || (manifest.schemaVersion
                    == AgentReplaySchema.renewableSubsistenceVersion
                && checkpoint.schemaVersion
                    <= AgentCheckpointSchema.estateVersion)
            || (manifest.schemaVersion
                    == AgentReplaySchema.independentEcologicalReceiptVersion
                && checkpoint.schemaVersion
                    <= AgentCheckpointSchema.renewableSubsistenceVersion)
            || (manifest.schemaVersion == AgentReplaySchema.productionVersion
                && checkpoint.schemaVersion
                    <= AgentCheckpointSchema.independentEcologicalReceiptVersion)
        guard manifest.baseCheckpointID == checkpoint.checkpointID,
              manifest.baseCheckpointDigest == checkpoint.semanticDigest,
              manifest.simulationID == checkpoint.simulationID,
              manifest.initialTick == checkpoint.tick.rawValue,
              compatibleSchema else {
            throw AgentReplayError.baseCheckpointMismatch
        }
        guard manifest.replayable, manifest.droppedRecordCount == 0,
              manifest.recordCount == journal.records.count else {
            throw AgentReplayError.invalidJournal("manifest counts or replayable flag")
        }
        let bytes = try AgentReplayCodec.encodeRecords(journal.records)
        guard bytes.count == manifest.operationsByteLength,
              AgentCheckpointDigest.sha256(bytes) == manifest.operationsStorageDigest else {
            throw AgentReplayError.invalidJournal("operations storage digest")
        }
    }

    static func divergentResult(
        checkpoint: AgentSessionCheckpoint,
        candidate: AgentSimulationSession,
        record: AgentReplayRecord,
        recordsApplied: Int,
        reason: String,
        actualDigest: AgentCheckpointDigest,
        actualCausalSequence: UInt64
    ) throws -> AgentReplayResult {
        let causal = candidate.causalLedgerSnapshot().summary
        let divergence = AgentReplayDivergence(
            recordSequence: record.recordSequence.rawValue,
            operationKind: record.operationKind,
            operationID: record.operationID,
            reason: reason,
            expectedDigest: reason.hasPrefix("pre")
                ? record.preStateSemanticDigest : record.postStateSemanticDigest,
            actualDigest: actualDigest,
            expectedTick: record.expectedTickBefore,
            actualTick: candidate.tick,
            expectedCausalSequence: reason.hasPrefix("pre")
                ? record.causalSequenceBefore : record.causalSequenceAfter,
            actualCausalSequence: actualCausalSequence
        )
        return AgentReplayResult(
            report: AgentReplayReport(
                schemaVersion: record.schemaVersion,
                verified: false,
                baseCheckpointID: checkpoint.checkpointID,
                simulationID: candidate.simulationID,
                recordsApplied: recordsApplied,
                finalTick: candidate.tick,
                finalSemanticDigest: actualDigest,
                finalCausalSequence: causal.latestSequence,
                finalCausalDigest: causal.digest,
                divergence: divergence
            ),
            session: candidate
        )
    }
}

extension AgentSimulationSession {
    @discardableResult
    public mutating func applyReplayOperation(
        _ operation: AgentReplayOperation
    ) throws -> AgentReplayApplicationResult {
        var candidate = self
        var claimed: [AgentPhysicalPresentationRequest] = []
        var tickResult: AgentSessionTickResult?
        var socialVerificationResult: AgentSocialVerificationResult?
        switch operation {
        case let .advanceTick(perceptions, physicalObservations):
            tickResult = try candidate.advanceTick(
                perceptions: perceptions,
                physicalObservations: physicalObservations
            )
        case let .externalUpdate(update):
            try candidate.applyExternalUpdate(update)
        case let .movementOutcomes(outcomes):
            try candidate.applyMovementOutcomes(outcomes)
        case let .verifiedPhysicalMovements(movements):
            try candidate.applyVerifiedPhysicalMovements(movements)
        case let .interactionOutcome(outcome):
            try candidate.applyInteractionOutcome(outcome)
        case let .deliveryOutcome(outcome):
            try candidate.applyDeliveryOutcome(outcome)
        case let .consumptionOutcome(outcome):
            try candidate.applyConsumptionOutcome(outcome)
        case let .setEconomyEnabled(enabled):
            candidate.setEconomyEnabled(enabled)
        case let .setNaturalResourcesEnabled(enabled):
            candidate.setNaturalResourcesEnabled(enabled)
        case let .setSurvivalEnabled(enabled):
            candidate.setSurvivalEnabled(enabled)
        case let .setBuildAutoEnabled(enabled):
            try candidate.setBuildAutoEnabled(enabled)
        case let .setSocialEnabled(enabled):
            try candidate.setSocialEnabled(enabled)
        case let .setPhysicalEnabled(enabled):
            try candidate.setPhysicalEnabled(enabled)
        case let .setCooperationEnabled(enabled):
            try candidate.setCooperationEnabled(enabled)
        case let .createConstructionProject(project):
            try candidate.createConstructionProject(project)
        case let .fundConstructionProject(fundingID, builderAgentID, tick):
            _ = try candidate.fundConstructionProject(
                fundingId: fundingID,
                builderAgentId: builderAgentID,
                fundingTick: tick
            )
        case let .applyPlacementOutcome(outcome):
            try candidate.applyPlacementOutcome(outcome)
        case let .recordConstructionFailure(failureID, projectID, builderAgentID, failure, reason):
            try candidate.recordConstructionFailure(
                failureId: failureID,
                projectId: projectID,
                builderAgentId: builderAgentID,
                failure: failure,
                reason: reason
            )
        case let .completeConstructionProject(projectID, tick):
            try candidate.completeConstructionProject(projectId: projectID, completionTick: tick)
        case let .clearConstructionProject(projectID):
            try candidate.clearConstructionProject(projectId: projectID)
        case let .applySocialVerification(observation):
            socialVerificationResult = try candidate.applySocialVerification(observation)
        case .clearSocialState:
            try candidate.clearSocialState()
        case .claimPhysicalPresentationRequests:
            claimed = candidate.claimPhysicalPresentationRequests()
        case .clearPhysicalState:
            try candidate.clearPhysicalState()
        case .clearCooperationState:
            try candidate.clearCooperationState()
        case let .setPopulationEnabled(
            enabled, settlementAnchor, receptionPosition, configuration
        ):
            try candidate.setPopulationEnabled(
                enabled,
                settlementAnchor: settlementAnchor,
                receptionPosition: receptionPosition,
                configuration: configuration
            )
        case let .initializePopulationRegistry(
            settlementAnchor, receptionPosition, configuration
        ):
            try candidate.initializePopulationRegistry(
                settlementAnchor: settlementAnchor,
                receptionPosition: receptionPosition,
                configuration: configuration
            )
        case let .admitMigration(intent, observation):
            _ = try candidate.admitMigration(intent: intent, observation: observation)
        case .clearPopulationDiagnostics:
            try candidate.clearPopulationDiagnostics()
        case let .setSettlementMetricsEnabled(enabled, configuration):
            try candidate.setSettlementMetricsEnabled(enabled, configuration: configuration)
        case .clearSettlementMetrics:
            try candidate.clearSettlementMetrics()
        case .settlementPulseBoundary:
            _ = try candidate.applySettlementMetricsPulseIfDue()
        case let .setLocalEcologyEnabled(enabled):
            try candidate.setLocalEcologyEnabled(enabled)
        case let .initializeLocalEcology(observations, configuration):
            try candidate.initializeLocalEcology(
                observations: observations,
                configuration: configuration
            )
        case let .applyHabitatValidation(observations):
            _ = try candidate.applyLocalEcologyEndOfTick(habitatValidations: observations)
        case let .applyForageOutcomes(intents, habitatValidations):
            _ = try candidate.applyForageIntents(
                intents,
                habitatValidations: habitatValidations
            )
        case .clearEcologyDiagnostics:
            try candidate.clearLocalEcologyDiagnostics()
        case let .setMortalityEnabled(enabled, configuration):
            try candidate.setMortalityEnabled(enabled, configuration: configuration)
        case .clearMortalityDiagnostics:
            try candidate.clearMortalityDiagnostics()
        case let .applyMortalityPhysicalCustodyOutcome(outcome):
            _ = try candidate.applyMortalityPhysicalCustodyOutcome(outcome)
        case let .finalizePendingMortality(agentID):
            _ = try candidate.finalizePendingMortality(for: agentID)
        case let .setLifecycleEnabled(enabled, configuration):
            try candidate.setLifecycleEnabled(enabled, configuration: configuration)
        case let .setReproductionEnabled(enabled):
            try candidate.setReproductionEnabled(enabled)
        case let .applyBirthSiteObservation(observation):
            _ = try candidate.applyBirthSiteObservation(observation)
        case .clearLifecycleDiagnostics:
            try candidate.clearLifecycleDiagnostics()
        case let .setKinshipEnabled(enabled, configuration):
            try candidate.setKinshipEnabled(enabled, configuration: configuration)
        case let .setHouseholdsEnabled(enabled, configuration):
            try candidate.setHouseholdsEnabled(enabled, configuration: configuration)
        case let .formHousehold(memberIDs, residenceAnchor):
            _ = try candidate.formHousehold(
                memberIDs: memberIDs,
                residenceAnchor: residenceAnchor
            )
        case let .moveHouseholdMembers(memberIDs, householdID):
            try candidate.moveMembers(memberIDs: memberIDs, to: householdID)
        case let .setDependentCareEnabled(enabled, configuration):
            try candidate.setDependentCareEnabled(enabled, configuration: configuration)
        case let .provideDependentNourishment(intent):
            _ = try candidate.provideDependentNourishment(intent)
        case let .completeDependentCareInteraction(caregiverID, dependentID):
            _ = try candidate.completeDependentCareInteraction(
                caregiverID: caregiverID, dependentID: dependentID
            )
        case let .verifyDependentCareSupervisionTick(
            caregiverID, dependentID
        ):
            _ = try candidate.verifyDependentCareSupervisionTick(
                caregiverID: caregiverID, dependentID: dependentID
            )
        case let .setSkillsEnabled(enabled, configuration):
            try candidate.setSkillsEnabled(enabled, configuration: configuration)
        case let .setTeachingEnabled(enabled, configuration):
            try candidate.setTeachingEnabled(enabled, configuration: configuration)
        case let .startApprenticeship(request):
            _ = try candidate.selectMentorAndStartApprenticeship(request)
        case let .recordTeachingDemonstration(observation):
            _ = try candidate.recordTeachingDemonstration(observation)
        case let .endApprenticeship(apprenticeshipID, participantID, reason):
            try candidate.endApprenticeship(
                apprenticeshipID, by: participantID, reason: reason
            )
        case let .linkGuidedPractice(
            exposureID, studentSourceSuccessEventID, skillPracticeEventID
        ):
            _ = try candidate.linkGuidedPractice(
                exposureID: exposureID,
                studentSourceSuccessEventID: studentSourceSuccessEventID,
                skillPracticeEventID: skillPracticeEventID
            )
        case let .setEcologicalObservationEnabled(enabled, configuration):
            try candidate.setEcologicalObservationEnabled(
                enabled, configuration: configuration
            )
        case let .recordEcologicalObservation(observation):
            _ = try candidate.recordEcologicalObservation(observation)
        case let .recordEcologicalObservationWithPhysicalReceipt(
            observation, physicalReceiptID
        ):
            _ = try candidate.recordEcologicalObservation(
                observation,
                physicalReceiptID: physicalReceiptID
            )
        case let .setAgricultureEnabled(enabled, configuration):
            try candidate.setAgricultureEnabled(enabled, configuration: configuration)
        case let .planAgriculturalPlot(
            plannerID, positions, crop, sourceObservationEventID,
            designatedStorageLocationID
        ):
            _ = try candidate.planAgriculturalPlot(
                plannerID: plannerID, positions: positions, crop: crop,
                sourceObservationEventID: sourceObservationEventID,
                designatedStorageLocationID: designatedStorageLocationID
            )
        case let .reserveAgriculturalCell(plotID, cellIndex, contenders):
            _ = try candidate.reserveAgriculturalCell(
                plotID: plotID, cellIndex: cellIndex, contenders: contenders
            )
        case let .recordAgriculturalAction(outcome):
            _ = try candidate.recordAgriculturalActionSuccess(outcome)
        case let .renewAgriculturalPlot(
            plotID, plannerID, sourceObservationEventID
        ):
            _ = try candidate.renewAgriculturalPlot(
                plotID: plotID,
                plannerID: plannerID,
                sourceObservationEventID: sourceObservationEventID
            )
        case let .setWildSubsistenceEnabled(enabled, configuration):
            try candidate.setWildSubsistenceEnabled(enabled, configuration: configuration)
        case let .selectWildSubsistenceOpportunity(context):
            _ = try candidate.selectWildSubsistenceOpportunity(context)
        case let .recordWildSubsistenceOutcome(outcome):
            _ = try candidate.recordWildSubsistenceOutcome(outcome)
        case let .setLivestockEnabled(enabled, configuration):
            try candidate.setLivestockEnabled(enabled, configuration: configuration)
        case let .applyLivestockOperation(operation):
            try candidate.applyLivestockOperation(operation)
        case let .setWorkCommitmentsEnabled(enabled, configuration):
            try candidate.setWorkCommitmentsEnabled(enabled, configuration: configuration)
        case let .applyWorkCommitmentOperation(operation):
            _ = try candidate.applyWorkCommitmentOperation(operation)
        case let .setPhysicalFoodSurvivalEnabled(enabled):
            try candidate.setPhysicalFoodSurvivalEnabled(enabled)
        case let .validatedPhysicalFoodConsumption(outcome):
            try candidate.applyValidatedPhysicalFoodConsumption(outcome)
        case let .setAutonomousActivityEnabled(enabled, configuration):
            try candidate.setAutonomousActivityEnabled(enabled, configuration: configuration)
        case let .selectAutonomousActivities(candidates):
            _ = try candidate.selectAutonomousActivities(candidates)
        case let .autonomousActivityOutcome(outcome):
            _ = try candidate.recordAutonomousActivityOutcome(outcome)
        case let .setProductiveSourceLifecycleEnabled(enabled, configuration):
            try candidate.setProductiveSourceLifecycleEnabled(
                enabled, configuration: configuration
            )
        case let .recordProductiveSourceObservations(observations):
            _ = try candidate.recordProductiveSourceObservations(observations)
        case let .recordProductiveSourceSuccess(
            sourceKey, expectedMaterialFingerprint, physicalReceiptID
        ):
            _ = try candidate.recordProductiveSourceSuccess(
                sourceKey: sourceKey,
                expectedMaterialFingerprint: expectedMaterialFingerprint,
                physicalReceiptID: physicalReceiptID
            )
        case .reviewProductiveSources:
            _ = try candidate.reviewProductiveSources()
        case let .validatedPhysicalDependentFood(outcome):
            _ = try candidate.applyValidatedPhysicalDependentFood(outcome)
        case let .setMaterialRightsEnabled(enabled, configuration):
            try candidate.setMaterialRightsEnabled(enabled, configuration: configuration)
        case let .applyMaterialRightsOperation(operation):
            _ = try candidate.applyMaterialRightsOperation(operation)
        case let .setHomeostasisEnabled(enabled, configuration):
            try candidate.setHomeostasisEnabled(
                enabled, configuration: configuration
            )
        case let .setGeneticsEnabled(enabled, configuration):
            try candidate.setGeneticsEnabled(
                enabled, configuration: configuration
            )
        case let .setChildhoodV2Enabled(enabled, configuration):
            try candidate.setChildhoodV2Enabled(
                enabled, configuration: configuration
            )
        case let .delegateDependentCare(dependentID, caregiverID):
            try candidate.delegateDependentCare(
                dependentID: dependentID, to: caregiverID
            )
        case let .reassignGuardian(dependentID, guardianID):
            try candidate.reassignGuardian(
                dependentID: dependentID, to: guardianID
            )
        case let .setFamilyV1Enabled(enabled, configuration):
            try candidate.setFamilyV1Enabled(enabled, configuration: configuration)
        case let .proposeUnion(receipt):
            _ = try candidate.proposeUnion(receipt)
        case let .acceptUnion(proposalID, receipt):
            _ = try candidate.acceptUnion(proposalID: proposalID, receipt: receipt)
        case let .endUnion(unionID, reason, receipt):
            try candidate.endUnion(unionID: unionID, reason: reason, receipt: receipt)
        case let .foundLineage(rootPersonID, actorID, operationID):
            _ = try candidate.foundLineage(
                rootPersonID: rootPersonID, actorID: actorID,
                operationID: operationID
            )
        case let .foundHouse(founderID, operationID):
            _ = try candidate.foundHouse(
                founderID: founderID, operationID: operationID
            )
        case let .coFoundHouse(founderIDs, receipts):
            _ = try candidate.coFoundHouse(
                founderIDs: founderIDs, receipts: receipts
            )
        case let .joinHouse(houseID, request, acceptance):
            try candidate.joinHouse(
                houseID, request: request, acceptance: acceptance
            )
        case let .leaveHouse(houseID, agentID, operationID):
            try candidate.leaveHouse(
                houseID, agentID: agentID, operationID: operationID
            )
        case let .setEstatesEnabled(enabled, configuration):
            try candidate.setEstatesEnabled(
                enabled, configuration: configuration
            )
        case let .acceptEstateAdministration(
            estateID, administratorID, operationID
        ):
            _ = try candidate.acceptEstateAdministration(
                estateID: estateID,
                administratorID: administratorID,
                operationID: operationID
            )
        case let .applyEstatePhysicalSettlement(outcome):
            _ = try candidate.applyEstatePhysicalSettlement(outcome)
        case let .setProductionEnabled(enabled, configuration):
            try candidate.setProductionEnabled(
                enabled, configuration: configuration
            )
        case let .raiseProductionNeed(
            needID, actorID, reason, desiredOutputItemKey, quantity, priority
        ):
            try candidate.raiseProductionNeed(
                needID: needID, actorID: actorID, reason: reason,
                desiredOutputItemKey: desiredOutputItemKey,
                quantity: quantity, priority: priority
            )
        case let .recordProductionOpportunity(observation):
            try candidate.recordProductionOpportunity(observation)
        case let .recordVerifiedProduction(outcome):
            try candidate.recordVerifiedProduction(outcome)
        case let .recordProducedGoodUse(outcome):
            try candidate.recordProducedGoodUse(outcome)
        }
        self = candidate
        let causal = causalLedgerSnapshot().summary
        return AgentReplayApplicationResult(
            tick: tick,
            causalSequence: causal.latestSequence,
            causalDigest: causal.digest,
            tickResult: tickResult,
            socialVerificationResult: socialVerificationResult,
            claimedPhysicalPresentations: claimed
        )
    }
}
