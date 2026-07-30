import Foundation

public enum AgentObserverError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration(String)
    case invalidWorldBinding(String)

    public var description: String {
        switch self {
        case let .invalidConfiguration(reason):
            return "invalid Observer configuration: \(reason)"
        case let .invalidWorldBinding(reason):
            return "invalid Observer World binding: \(reason)"
        }
    }
}

/// Bounded presentation policy. It controls only a read projection and cannot
/// change the causal ledger or any civilization transition.
public struct AgentObserverConfiguration: Codable, Equatable, Sendable {
    public let maximumAgents: Int
    public let maximumRelationsPerAgent: Int
    public let maximumAssetsPerAgent: Int
    public let maximumChronicleEvents: Int
    public let maximumEventsPerAgent: Int
    public let maximumDirectCausesPerEvent: Int
    public let maximumPresentationTextLength: Int

    public init(
        maximumAgents: Int = 64,
        maximumRelationsPerAgent: Int = 16,
        maximumAssetsPerAgent: Int = 16,
        maximumChronicleEvents: Int = 96,
        maximumEventsPerAgent: Int = 24,
        maximumDirectCausesPerEvent: Int = 8,
        maximumPresentationTextLength: Int = 160
    ) throws {
        guard (1...512).contains(maximumAgents) else {
            throw AgentObserverError.invalidConfiguration("agents")
        }
        guard (1...128).contains(maximumRelationsPerAgent) else {
            throw AgentObserverError.invalidConfiguration("relations")
        }
        guard (1...128).contains(maximumAssetsPerAgent) else {
            throw AgentObserverError.invalidConfiguration("assets")
        }
        guard (1...1024).contains(maximumChronicleEvents) else {
            throw AgentObserverError.invalidConfiguration("chronicle events")
        }
        guard (1...256).contains(maximumEventsPerAgent) else {
            throw AgentObserverError.invalidConfiguration("events per agent")
        }
        guard (1...AgentCausalEvent.maximumCauseCount).contains(
            maximumDirectCausesPerEvent
        ) else {
            throw AgentObserverError.invalidConfiguration(
                "direct causes per event"
            )
        }
        guard (32...512).contains(maximumPresentationTextLength) else {
            throw AgentObserverError.invalidConfiguration("presentation text")
        }
        self.maximumAgents = maximumAgents
        self.maximumRelationsPerAgent = maximumRelationsPerAgent
        self.maximumAssetsPerAgent = maximumAssetsPerAgent
        self.maximumChronicleEvents = maximumChronicleEvents
        self.maximumEventsPerAgent = maximumEventsPerAgent
        self.maximumDirectCausesPerEvent = maximumDirectCausesPerEvent
        self.maximumPresentationTextLength = maximumPresentationTextLength
    }

    public static let live = try! AgentObserverConfiguration()
}

/// Plain facts supplied by Pebble after the real World is available. This
/// binds a projection to physical authority without giving PebbleAgents a
/// World reference.
public struct AgentObserverWorldBinding: Codable, Equatable, Sendable {
    public let worldID: String
    public let storageIdentity: String
    public let seed: UInt32
    public let dimension: Int
    public let observedWorldTick: Int

    public init(
        worldID: String,
        storageIdentity: String,
        seed: UInt32,
        dimension: Int,
        observedWorldTick: Int
    ) throws {
        guard (1...160).contains(worldID.count),
              (1...240).contains(storageIdentity.count),
              worldID.allSatisfy({ $0.isASCII && !$0.isNewline }),
              storageIdentity.allSatisfy({ $0.isASCII && !$0.isNewline }),
              observedWorldTick >= 0 else {
            throw AgentObserverError.invalidWorldBinding(
                "identity, storage identity, or tick"
            )
        }
        self.worldID = worldID
        self.storageIdentity = storageIdentity
        self.seed = seed
        self.dimension = dimension
        self.observedWorldTick = observedWorldTick
    }
}

public struct AgentObserverSnapshotHeader: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let sessionIdentity: AgentSimulationID
    public let worldBinding: AgentObserverWorldBinding
    public let asOfTick: Int
    public let causalSequence: UInt64
    public let snapshotGeneration: String
}

public struct AgentObserverTruncation: Codable, Equatable, Sendable {
    public let agentsOmitted: Int
    public let relationsOmitted: Int
    public let assetsOmitted: Int
    public let chronicleEventsOmitted: UInt64
    public let perAgentEventsOmitted: Int
    public let directCausesOmitted: Int
    public let textWasTruncated: Bool
    public let deathsOmitted: Int

    public var isTruncated: Bool {
        agentsOmitted > 0 || relationsOmitted > 0 || assetsOmitted > 0
            || chronicleEventsOmitted > 0 || perAgentEventsOmitted > 0
            || directCausesOmitted > 0 || textWasTruncated
            || deathsOmitted > 0
    }
}

public struct AgentObserverNeed: Codable, Equatable, Sendable {
    public let code: String
    public let normalizedBasisPoints: Int
    public let presentation: String
}

public enum AgentObserverReasonCategory: String, Codable, CaseIterable, Sendable {
    case acting
    case waiting
    case blocked
    case refused
    case failed
    case replanning
    case interruptedReconciled
    case unknownUnavailable
}

public enum AgentObserverReasonCode: String, Codable, CaseIterable, Sendable {
    case authorizedActivity
    case activeActivity
    case goalAction
    case waitingForCondition
    case boundedPhysicalBlock
    case useRefused
    case physicalAttemptFailed
    case boundedReplan
    case persistenceReconciled
    case interruptedAfterRestart
    case noCurrentAction
    case unavailable
    case physiologicalIncapacity
}

public struct AgentObserverPresentationDatum: Codable, Equatable, Sendable {
    public let key: String
    public let value: String

    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

public struct AgentObserverStructuredReason: Codable, Equatable, Sendable {
    public let code: AgentObserverReasonCode
    public let category: AgentObserverReasonCategory
    public let authoritativeSubjectID: AgentID
    public let targetOrDependency: String?
    public let causalEventID: AgentCausalEventID?
    public let causalSequence: UInt64?
    public let presentation: String
    public let presentationData: [AgentObserverPresentationDatum]
}

public struct AgentObserverActivity: Codable, Equatable, Sendable {
    public let activityID: String?
    public let action: String
    public let goal: String
    public let commitmentID: String?
    public let progress: String
    public let startedAtTick: Int
    public let updatedAtTick: Int
    public let reason: AgentObserverStructuredReason
}

public struct AgentObserverHousehold: Codable, Equatable, Sendable {
    public let status: String
    public let householdID: AgentHouseholdID?
    public let residenceAnchor: AgentPosition?
    public let memberIDs: [AgentID]
}

public struct AgentObserverFamilyIndividual: Codable, Equatable, Sendable {
    public let activeUnionPartnerID: AgentID?
    public let formerUnionPartnerIDs: [AgentID]
    public let relations: [AgentFamilyRelation]
    public let relationsTruncated: Bool
    public let lineageIDs: [AgentLineageID]
    public let houseMemberships: [AgentHouseMembershipPeriod]
}

public struct AgentObserverUnion: Codable, Equatable, Sendable {
    public let unionID: AgentUnionID
    public let partnerIDs: [AgentID]
    public let status: AgentUnionStatus
    public let proposalTick: Int
    public let acceptanceTick: Int
    public let activationTick: Int
    public let terminationTick: Int?
    public let terminationReason: AgentUnionTerminationReason?
    public let sourceEventID: AgentCausalEventID
    public let coResident: Bool
}

public struct AgentObserverLineage: Codable, Equatable, Sendable {
    public let lineageID: AgentLineageID
    public let rootPersonID: AgentID
    public let foundationTick: Int
    public let descendantCount: Int
    public let memberIDs: [AgentID]
    public let maximumDepthApplied: Int
    public let truncated: Bool
}

public struct AgentObserverHouse: Codable, Equatable, Sendable {
    public let houseID: AgentHouseID
    public let founderIDs: [AgentID]
    public let status: AgentHouseStatus
    public let foundationTick: Int
    public let activeMemberships: [AgentHouseMembershipPeriod]
    public let livingMemberCount: Int
    public let householdIDs: [AgentHouseholdID]
}

public struct AgentObserverFamilyAuthority: Codable, Equatable, Sendable {
    public let unions: [AgentObserverUnion]
    public let lineages: [AgentObserverLineage]
    public let houses: [AgentObserverHouse]
}

public enum AgentObserverRelationKind: String, Codable, CaseIterable, Sendable {
    case household
    case parent
    case child
    case trust
    case nearbyPhysicalObservation
}

public struct AgentObserverRelation: Codable, Equatable, Sendable {
    public let kind: AgentObserverRelationKind
    public let otherAgentID: AgentID
    public let value: Int?
    public let sourceEventID: AgentCausalEventID?
    public let presentation: String
}

public struct AgentObserverProfession: Codable, Equatable, Sendable {
    public let status: String
    public let primaryDomain: String?
    public let secondaryDomains: [String]
    public let activeCommitmentCount: Int
    public let presentation: String
}

public struct AgentObserverMaterialAsset: Codable, Equatable, Sendable {
    public let assetID: AgentMaterialAssetID
    public let itemKey: String
    public let quantity: Int
    public let physicalHolder: String
    public let physicalObservationTick: Int
    public let custodianID: AgentID?
    public let recognizedOwnerID: AgentID?
    public let claimantIDs: [AgentID]
    public let authorizedUserIDs: [AgentID]
    public let permittedUsesByUser: [AgentObserverPresentationDatum]
    public let conflict: Bool
    public let reconciliationOutcome: String?
    public let reconciliationEventID: AgentCausalEventID?
}

public struct AgentObserverHealthFactor: Codable, Equatable, Sendable {
    public let code: AgentPhysiologicalFactorCode
    public let severityBasisPoints: Int
    public let harmful: Bool
    public let source: String
}

public struct AgentObserverPhysiology: Codable, Equatable, Sendable {
    public let vitalStatus: AgentVitalStatus
    public let ageTicks: Int
    public let lifeStage: AgentLifeStage
    public let ageBand: AgentPhysiologicalAgeBand
    public let condition: AgentHealthCondition
    public let trend: AgentHealthTrend
    public let healthReserve: Int
    public let energyReserveBasisPoints: Int
    public let stressBasisPoints: Int
    public let recoveryCapacityBasisPoints: Int
    public let ageVulnerabilityBasisPoints: Int
    public let activeFactors: [AgentObserverHealthFactor]
    public let limitation: String?
    public let recentEpisodeCount: Int
    public let episodesTruncated: Bool
    public let lastCausalEventID: AgentCausalEventID
}

public struct AgentObserverGeneticContribution: Codable, Equatable, Sendable {
    public let allele: AgentGeneticAllele
    public let contributorID: AgentID
    public let sourceGenotypeID: AgentGenotypeID?
    public let sourceAlleleIndex: Int
}

public struct AgentObserverGeneticLocus: Codable, Equatable, Sendable {
    public let locus: AgentGeneticLocus
    public let contributions: [AgentObserverGeneticContribution]
    public let potentialBasisPoints: Int
}

public struct AgentObserverDevelopment: Codable, Equatable, Sendable {
    public let active: Bool
    public let ageTicks: Int
    public let lifeStage: AgentLifeStage
    public let expressionMaturityBasisPoints: Int
    public let physiologicalExposureBasisPoints: Int
    public let developmentalReserveBasisPoints: Int
    public let trajectory: AgentDevelopmentTrajectory
    public let lastSignificantChangeTick: Int
    public let stoppedAtTick: Int?
    public let lastEventID: AgentCausalEventID
}

public struct AgentObserverPhenotypeTrait: Codable, Equatable, Sendable {
    public let traitID: AgentPhenotypeTraitID
    public let geneticPotentialBasisPoints: Int
    public let developmentalFactorBasisPoints: Int
    public let physiologicalExpressionFactorBasisPoints: Int
    public let expressedModifierBasisPoints: Int
    public let lowerBoundBasisPoints: Int
    public let upperBoundBasisPoints: Int
    public let provenance: String
    public let lastSignificantChangeTick: Int
    public let lastEventID: AgentCausalEventID
}

public struct AgentObserverGenetics: Codable, Equatable, Sendable {
    public let modelVersion: Int
    public let genotypeID: AgentGenotypeID
    public let origin: AgentGenotypeOrigin
    public let contributorIDs: [AgentID]
    public let loci: [AgentObserverGeneticLocus]
    public let creationEventID: AgentCausalEventID
    public let development: AgentObserverDevelopment
    public let phenotype: [AgentObserverPhenotypeTrait]
}

public struct AgentObserverSocialDevelopmentValue:
    Codable, Equatable, Sendable
{
    public let dimension: AgentSocialDevelopmentDimension
    public let basisPoints: Int
    public let lastChangedTick: Int
    public let lastEventID: AgentCausalEventID
}

public struct AgentObserverChildCareNeed: Codable, Equatable, Sendable {
    public let needID: AgentCareNeedID
    public let kind: AgentCareNeedKind
    public let severity: Int
    public let status: AgentCareNeedStatus
    public let assignedCaregiverID: AgentID?
    public let requiresPhysicalFood: Bool
    public let raisedTick: Int
    public let raisedEventID: AgentCausalEventID
}

public struct AgentObserverChildhood: Codable, Equatable, Sendable {
    public let ageTicks: Int
    public let lifeStage: AgentLifeStage
    public let currentPhysicalLocation: AgentPosition
    public let homePosition: AgentPosition
    public let dependencyStatus: String
    public let atRisk: Bool
    public let guardianID: AgentID?
    public let guardianshipBasis: AgentGuardianshipBasis?
    public let guardianshipHouseholdID: AgentHouseholdID?
    public let guardianshipStartedTick: Int?
    public let guardianshipStatus: AgentGuardianshipStatus?
    public let latestGuardianshipEndReason: AgentGuardianshipEndReason?
    public let currentCaregiverID: AgentID?
    public let currentCareEngagement: AgentCareEngagementKind?
    public let currentCareEngagedTicks: Int?
    public let activeNeeds: [AgentObserverChildCareNeed]
    public let unmetNeedKinds: [AgentCareNeedKind]
    public let latestCareOutcome: AgentCareNeedTerminalReason?
    public let allowedCapabilities: [AgentStageCapability]
    public let refusedCapabilities: [AgentStageCapability]
    public let autonomyReadinessBasisPoints: Int
    public let socialDevelopment: [AgentObserverSocialDevelopmentValue]
    public let socialTrajectory: String
    public let recentExposureEventIDs: [AgentCausalEventID]
    public let lastSignificantChangeTick: Int?
}

public struct AgentObserverDeath: Codable, Equatable, Sendable {
    public let agentID: AgentID
    public let deathID: AgentDeathID
    public let deathTick: Int
    public let cause: AgentMortalityCause
    public let ageTicks: Int?
    public let lifeStage: AgentLifeStage?
    public let finalPosition: AgentPosition
    public let finalHealth: Int
    public let deathEventID: AgentCausalEventID
    public let preservedMaterialClaims: [AgentMaterialAssetID]
    public let genetics: AgentObserverGenetics?
}

public struct AgentObserverChronicleEvent: Codable, Equatable, Sendable {
    public let eventID: AgentCausalEventID
    public let sequence: UInt64
    public let tick: Int
    public let kind: AgentCausalEventKind
    public let origin: AgentCausalOrigin
    public let actorID: AgentID?
    public let subjectID: AgentID?
    public let operationID: String?
    public let assetIDs: [AgentMaterialAssetID]
    public let causes: [AgentCausalEventID]
    public let directCausesOmitted: Int
    public let missingCauseCount: Int
    public let result: String
    public let detail: String
    public let summary: String
}

public struct AgentObserverIndividual: Codable, Equatable, Sendable {
    public let agentID: AgentID
    public let lifeState: String
    public let availability: String
    public let observedPhysicalPosition: AgentPosition
    public let physicalPositionSource: String
    public let needs: [AgentObserverNeed]
    public let activity: AgentObserverActivity
    public let household: AgentObserverHousehold
    public let relations: [AgentObserverRelation]
    public let relationsTruncated: Bool
    public let profession: AgentObserverProfession
    public let materialAssets: [AgentObserverMaterialAsset]
    public let materialAssetsTruncated: Bool
    public let recentEventIDs: [AgentCausalEventID]
    public let recentEventsTruncated: Bool
    public let physiology: AgentObserverPhysiology?
    public let genetics: AgentObserverGenetics?
    public let childhood: AgentObserverChildhood?
    public let family: AgentObserverFamilyIndividual?
}

public struct AgentObserverSnapshot: Codable, Equatable, Sendable {
    public let header: AgentObserverSnapshotHeader
    public let individuals: [AgentObserverIndividual]
    /// Newest event first. Sequence remains the stable total order.
    public let globalChronicle: [AgentObserverChronicleEvent]
    public let recentDeaths: [AgentObserverDeath]
    public let familyAuthority: AgentObserverFamilyAuthority?
    public let truncation: AgentObserverTruncation
}

public struct AgentObserverChronicleFilter: Codable, Equatable, Sendable {
    public let agentID: AgentID?
    public let assetID: AgentMaterialAssetID?
    public let eventKind: AgentCausalEventKind?

    public init(
        agentID: AgentID? = nil,
        assetID: AgentMaterialAssetID? = nil,
        eventKind: AgentCausalEventKind? = nil
    ) {
        self.agentID = agentID
        self.assetID = assetID
        self.eventKind = eventKind
    }
}

public struct AgentObserverIndividualPage: Codable, Equatable, Sendable {
    public let offset: Int
    public let totalCount: Int
    public let values: [AgentObserverIndividual]
    public let hasMore: Bool
}

public struct AgentObserverChroniclePage: Codable, Equatable, Sendable {
    public let offset: Int
    public let totalCount: Int
    public let values: [AgentObserverChronicleEvent]
    public let hasMore: Bool
}

extension AgentObserverSnapshot {
    public func individual(_ id: AgentID) -> AgentObserverIndividual? {
        individuals.first { $0.agentID == id }
    }

    public func individualPage(
        offset: Int,
        limit: Int
    ) -> AgentObserverIndividualPage {
        let safeOffset = max(0, min(offset, individuals.count))
        let safeLimit = max(1, min(limit, 64))
        let values = Array(individuals.dropFirst(safeOffset).prefix(safeLimit))
        return AgentObserverIndividualPage(
            offset: safeOffset, totalCount: individuals.count, values: values,
            hasMore: safeOffset + values.count < individuals.count
        )
    }

    public func chroniclePage(
        filter: AgentObserverChronicleFilter = AgentObserverChronicleFilter(),
        offset: Int,
        limit: Int
    ) -> AgentObserverChroniclePage {
        let matches = globalChronicle.filter { event in
            (filter.agentID == nil
                || event.actorID == filter.agentID
                || event.subjectID == filter.agentID)
                && (filter.assetID == nil
                    || event.assetIDs.contains(filter.assetID!))
                && (filter.eventKind == nil
                    || event.kind == filter.eventKind)
        }
        let safeOffset = max(0, min(offset, matches.count))
        let safeLimit = max(1, min(limit, 64))
        let values = Array(matches.dropFirst(safeOffset).prefix(safeLimit))
        return AgentObserverChroniclePage(
            offset: safeOffset, totalCount: matches.count, values: values,
            hasMore: safeOffset + values.count < matches.count
        )
    }
}

extension AgentSimulationSession {
    /// Produces one immutable, deterministic projection. Every domain snapshot
    /// is captured synchronously from this value-semantic aggregate; no tick or
    /// causal event can be advanced by this nonmutating method.
    public func observerSnapshot(
        worldBinding: AgentObserverWorldBinding,
        configuration: AgentObserverConfiguration = .live
    ) -> AgentObserverSnapshot {
        let session = snapshot()
        let ledger = causalLedgerSnapshot()
        let rights = materialRightsSnapshot()
        let activities = autonomousActivitySnapshot()
        let work = workCommitmentSnapshot()
        let households = householdSnapshot()
        let kinship = kinshipSnapshot()
        let social = socialSnapshot()
        let reconciliation = persistenceReconciliationSnapshot()
        let homeostasis = homeostasisSnapshot()
        let mortality = mortalitySnapshot()
        let genetics = geneticsSnapshot()
        let care = dependentCareSnapshot()
        let childhood = childhoodSnapshot()
        let family = familySnapshot()
        let textLimit = configuration.maximumPresentationTextLength

        let materialTransitionByEventID = Dictionary(
            uniqueKeysWithValues: rights.recentTransitions.compactMap { transition in
                transition.eventID.map { ($0, transition) }
            }
        )
        let retainedEventIDs = Set(ledger.events.map(\.eventID))
        let retainedEvents = Array(ledger.events.suffix(configuration.maximumChronicleEvents))
        let chronicle = retainedEvents.reversed().map { event in
            observerChronicleEvent(
                event,
                transition: materialTransitionByEventID[event.eventID],
                retainedEventIDs: retainedEventIDs,
                maximumDirectCauses: configuration.maximumDirectCausesPerEvent,
                textLimit: textLimit
            )
        }
        let chronicleOmitted = ledger.summary.droppedEventCount
            + UInt64(max(0, ledger.events.count - retainedEvents.count))

        let sortedAgents = session.agents.sorted { $0.id < $1.id }
        let visibleAgents = Array(sortedAgents.prefix(configuration.maximumAgents))
        var relationsOmitted = 0
        var assetsOmitted = 0
        var perAgentEventsOmitted = 0
        var textWasTruncated = false

        let individuals = visibleAgents.compactMap { agent -> AgentObserverIndividual? in
            guard let agentID = AgentID(rawValue: agent.id) else { return nil }
            let relevantEvents = ledger.events.filter {
                $0.actorID == agentID || $0.subjectID == agentID
            }
            let visibleEventIDs = relevantEvents.suffix(
                configuration.maximumEventsPerAgent
            ).reversed().map(\.eventID)
            let omittedEvents = max(0, relevantEvents.count - visibleEventIDs.count)
            perAgentEventsOmitted += omittedEvents

            let relations = observerRelations(
                for: agentID,
                agent: agent,
                households: households,
                kinship: kinship,
                social: social,
                textLimit: textLimit
            )
            let visibleRelations = Array(
                relations.prefix(configuration.maximumRelationsPerAgent)
            )
            relationsOmitted += max(0, relations.count - visibleRelations.count)

            let relevantAssetIDs = Set<AgentMaterialAssetID>(
                rights.recentTransitions.compactMap { transition in
                    guard let eventID = transition.eventID,
                          let event = ledger.events.first(where: {
                              $0.eventID == eventID
                          }), event.actorID == agentID else { return nil }
                    return transition.assetID
                }
            )
            let assetRows = rights.records.filter { record in
                record.lastVerifiedHolder.holder.agentID == agentID
                    || record.custodianID == agentID
                    || record.recognizedOwnership?.ownerID == agentID
                    || record.claims.contains { $0.claimantID == agentID }
                    || record.permissions.contains { $0.userID == agentID }
                    || relevantAssetIDs.contains(record.asset.assetID)
            }.map { record in
                observerMaterialAsset(record, reconciliation: reconciliation)
            }.sorted { $0.assetID < $1.assetID }
            let visibleAssets = Array(
                assetRows.prefix(configuration.maximumAssetsPerAgent)
            )
            assetsOmitted += max(0, assetRows.count - visibleAssets.count)

            let reason = observerReason(
                for: agentID,
                agent: agent,
                activities: activities,
                rights: rights,
                reconciliation: reconciliation,
                ledgerEvents: ledger.events,
                textLimit: textLimit
            )
            let activity = observerActivity(
                for: agentID,
                agent: agent,
                activities: activities,
                work: work,
                reason: reason,
                textLimit: textLimit
            )
            let household = observerHousehold(
                for: agentID, snapshot: households
            )
            let profession = observerProfession(
                for: agentID, snapshot: work, textLimit: textLimit
            )
            if reason.presentation.count >= textLimit
                || visibleRelations.contains(where: { $0.presentation.count >= textLimit })
                || profession.presentation.count >= textLimit {
                textWasTruncated = true
            }
            return AgentObserverIndividual(
                agentID: agentID,
                lifeState: agent.isAlive ? "alive" : "dead",
                availability: observerAvailability(
                    agent: agent, activity: activity, work: work
                ),
                observedPhysicalPosition: agent.position,
                physicalPositionSource: "Pebble verified session projection",
                needs: observerNeeds(agent.needs),
                activity: activity,
                household: household,
                relations: visibleRelations,
                relationsTruncated: relations.count > visibleRelations.count,
                profession: profession,
                materialAssets: visibleAssets,
                materialAssetsTruncated: assetRows.count > visibleAssets.count,
                recentEventIDs: visibleEventIDs,
                recentEventsTruncated: omittedEvents > 0,
                physiology: homeostasis.profiles.first {
                    $0.agentID == agentID
                }.map {
                    observerPhysiology($0, healthReserve: agent.health)
                },
                genetics: observerGenetics(agentID, snapshot: genetics),
                childhood: observerChildhood(
                    agentID, care: care, childhood: childhood
                ),
                family: observerFamilyIndividual(agentID, snapshot: family)
            )
        }
        let retainedDeaths = Array(
            mortality.records.suffix(configuration.maximumAgents)
        )
        let recentDeaths = retainedDeaths.reversed().map { record in
            AgentObserverDeath(
                agentID: record.agentID,
                deathID: record.deathID,
                deathTick: record.deathTick,
                cause: record.cause,
                ageTicks: record.demographicAgeTicks,
                lifeStage: record.lifeStage,
                finalPosition: record.finalPosition,
                finalHealth: record.finalHealth,
                deathEventID: record.deathEventID,
                preservedMaterialClaims: rights.records.compactMap {
                    $0.custodianID == record.agentID
                        || $0.recognizedOwnership?.ownerID == record.agentID
                        || $0.claims.contains(where: {
                            $0.claimantID == record.agentID
                        })
                        ? $0.asset.assetID : nil
                }.sorted(),
                genetics: observerGenetics(record.agentID, snapshot: genetics)
            )
        }
        let generationSource = [
            "observer-v1", simulationID.rawValue, worldBinding.worldID,
            worldBinding.storageIdentity, String(tick),
            String(ledger.summary.latestSequence), ledger.summary.digest,
            rights.records.map(\.asset.assetID.rawValue).joined(separator: ","),
            reconciliation.recentRuns.last?.runID ?? "none",
            homeostasis.digest,
            mortality.digest,
            genetics.digest,
            childhood.digest,
            family.digest,
        ].joined(separator: "|")
        let familyAuthority = observerFamilyAuthority(family)
        let truncation = AgentObserverTruncation(
            agentsOmitted: max(0, sortedAgents.count - visibleAgents.count),
            relationsOmitted: relationsOmitted,
            assetsOmitted: assetsOmitted,
            chronicleEventsOmitted: chronicleOmitted,
            perAgentEventsOmitted: perAgentEventsOmitted,
            directCausesOmitted: chronicle.reduce(0) {
                $0 + $1.directCausesOmitted
            },
            textWasTruncated: textWasTruncated,
            deathsOmitted: max(0, mortality.records.count - retainedDeaths.count)
        )
        return AgentObserverSnapshot(
            header: AgentObserverSnapshotHeader(
                schemaVersion: childhood.enabled
                    ? (family.enabled ? 5 : 4)
                    : (family.enabled ? 5
                        : (genetics.enabled ? 3 : (homeostasis.enabled ? 2 : 1))),
                sessionIdentity: simulationID,
                worldBinding: worldBinding,
                asOfTick: tick,
                causalSequence: ledger.summary.latestSequence,
                snapshotGeneration: observerDigest(generationSource)
            ),
            individuals: individuals,
            globalChronicle: chronicle,
            recentDeaths: recentDeaths,
            familyAuthority: familyAuthority,
            truncation: truncation
        )
    }
}

private extension AgentSimulationSession {
    func observerFamilyIndividual(
        _ agentID: AgentID,
        snapshot: AgentFamilySnapshot
    ) -> AgentObserverFamilyIndividual? {
        guard snapshot.enabled else {
            return nil
        }
        let relationProjection = try? familyRelationProjection(of: agentID)
        let relations = relationProjection?.relations ?? []
        let activePartner = snapshot.unions.first {
            $0.status == .active && $0.partnerIDs.contains(agentID)
        }?.partnerIDs.first { $0 != agentID }
        let former = snapshot.unions.compactMap {
            $0.status == .ended && $0.partnerIDs.contains(agentID)
                ? $0.partnerIDs.first(where: { $0 != agentID }) : nil
        }.sorted()
        let lineageIDs = ((try? lineages(containing: agentID)) ?? [])
            .map(\.lineage.lineageID).sorted()
        let memberships = snapshot.houseMembershipPeriods.filter {
            $0.agentID == agentID && $0.leftTick == nil
        }.sorted {
            if $0.houseID != $1.houseID { return $0.houseID < $1.houseID }
            return $0.joinedEventID < $1.joinedEventID
        }
        return AgentObserverFamilyIndividual(
            activeUnionPartnerID: activePartner,
            formerUnionPartnerIDs: former,
            relations: relations,
            relationsTruncated: relationProjection?.truncated ?? false,
            lineageIDs: lineageIDs,
            houseMemberships: memberships
        )
    }

    func observerFamilyAuthority(
        _ snapshot: AgentFamilySnapshot
    ) -> AgentObserverFamilyAuthority? {
        guard snapshot.enabled else { return nil }
        let unions = snapshot.unions.map { union in
            let memberships = householdSnapshot().currentMemberships
            let left = memberships.first { $0.agentID == union.partnerIDs[0] }
            let right = memberships.first { $0.agentID == union.partnerIDs[1] }
            return AgentObserverUnion(
                unionID: union.unionID, partnerIDs: union.partnerIDs,
                status: union.status, proposalTick: union.proposalTick,
                acceptanceTick: union.acceptanceTick,
                activationTick: union.activationTick,
                terminationTick: union.terminationTick,
                terminationReason: union.terminationReason,
                sourceEventID: union.terminationEventID ?? union.activationEventID,
                coResident: left?.householdID == right?.householdID
                    && left != nil && right != nil
            )
        }
        let lineages = snapshot.lineages.compactMap { lineage in
            try? lineageProjection(lineage.lineageID)
        }.map {
            AgentObserverLineage(
                lineageID: $0.lineage.lineageID,
                rootPersonID: $0.lineage.rootPersonID,
                foundationTick: $0.lineage.foundationTick,
                descendantCount: $0.totalDescendantCount,
                memberIDs: $0.memberIDs,
                maximumDepthApplied: $0.maximumDepthApplied,
                truncated: $0.truncated
            )
        }
        let houses = snapshot.houses.compactMap { house in
            try? houseProjection(house.houseID)
        }.map {
            AgentObserverHouse(
                houseID: $0.house.houseID,
                founderIDs: $0.house.founderIDs,
                status: $0.house.status,
                foundationTick: $0.house.foundationTick,
                activeMemberships: $0.activeMemberships,
                livingMemberCount: $0.livingMemberCount,
                householdIDs: $0.householdIDs
            )
        }
        return AgentObserverFamilyAuthority(
            unions: unions, lineages: lineages, houses: houses
        )
    }
}

private struct AgentObserverReasonCandidate {
    let reason: AgentObserverStructuredReason
    let tick: Int
    let causalSequence: UInt64
    let tieBreakPriority: Int
}

private extension AgentSimulationSession {
    func observerChildhood(
        _ agentID: AgentID,
        care: AgentDependentCareSnapshot,
        childhood: AgentChildhoodSnapshot
    ) -> AgentObserverChildhood? {
        guard childhood.enabled,
              let policy = try? stageCapabilityPolicy(for: agentID),
              let capabilities = try? childhoodCapabilities(for: agentID),
              let agent = statesById[agentID.rawValue],
              let lifecycleMember = lifecycleState?.members.first(where: {
                  $0.agentID == agentID
              }),
              let ageTicks = try? lifecycleMember.age(at: tick)
        else { return nil }
        let guardian = childhood.guardianships.first {
            $0.dependentID == agentID && $0.status == .active
        }
        let assignment = care.assignments.first {
            $0.dependentID == agentID && $0.status == .active
        }
        let engagement = care.activeEngagements.first {
            $0.dependentID == agentID
        }
        let latestOutcome = care.terminalOutcomes
            .filter { $0.dependentID == agentID }
            .sorted {
                $0.tick == $1.tick
                    ? $0.terminalEventID > $1.terminalEventID
                    : $0.tick > $1.tick
            }
            .first
        let latestEndedGuardianship = childhood.guardianships
            .filter {
                $0.dependentID == agentID && $0.status == .ended
            }
            .sorted {
                ($0.endedTick ?? -1) == ($1.endedTick ?? -1)
                    ? ($0.endedEventID ?? $0.startedEventID)
                        > ($1.endedEventID ?? $1.startedEventID)
                    : ($0.endedTick ?? -1) > ($1.endedTick ?? -1)
            }
            .first
        let profile = childhood.socialProfiles.first {
            $0.agentID == agentID
        }
        let exposures = childhood.exposures.filter {
            $0.agentID == agentID
        }.sorted {
            $0.ordinal > $1.ordinal
        }
        let atRisk = childhood.atRiskDependentIDs.contains(agentID)
        let activeNeeds = care.activeNeeds.filter {
            $0.dependentID == agentID
        }.sorted {
            if $0.kind != $1.kind {
                return $0.kind.rawValue < $1.kind.rawValue
            }
            return $0.needID < $1.needID
        }
        let socialTrajectory: String
        if atRisk || exposures.first?.dimension == .unmetCareExposure {
            socialTrajectory = "careDeficitExposure"
        } else if exposures.isEmpty {
            socialTrajectory = "noRecordedExposure"
        } else {
            socialTrajectory = "experienceLinkedGrowth"
        }
        return AgentObserverChildhood(
            ageTicks: ageTicks,
            lifeStage: policy.stage,
            currentPhysicalLocation: agent.position,
            homePosition: agent.homePosition,
            dependencyStatus: policy.stage == .mature
                ? "independent" : (atRisk ? "atRisk" : "guarded"),
            atRisk: atRisk,
            guardianID: guardian?.guardianID,
            guardianshipBasis: guardian?.basis,
            guardianshipHouseholdID: guardian?.householdID,
            guardianshipStartedTick: guardian?.startedTick,
            guardianshipStatus: guardian?.status,
            latestGuardianshipEndReason:
                latestEndedGuardianship?.endedReason,
            currentCaregiverID: assignment?.caregiverID,
            currentCareEngagement: engagement?.kind,
            currentCareEngagedTicks: engagement.map {
                $0.verifiedEngagedTicks
            },
            activeNeeds: activeNeeds.map {
                AgentObserverChildCareNeed(
                    needID: $0.needID, kind: $0.kind,
                    severity: $0.severity, status: $0.status,
                    assignedCaregiverID: $0.assignedCaregiverID,
                    requiresPhysicalFood: $0.kind == .nourishment,
                    raisedTick: $0.raisedTick,
                    raisedEventID: $0.raisedEventID
                )
            },
            unmetNeedKinds: activeNeeds.filter {
                $0.status == .unmet
            }.map(\.kind),
            latestCareOutcome: latestOutcome?.terminalReason,
            allowedCapabilities: capabilities.allowed,
            refusedCapabilities: capabilities.refused,
            autonomyReadinessBasisPoints:
                capabilities.autonomyReadinessBasisPoints,
            socialDevelopment: profile?.values.sorted {
                $0.dimension < $1.dimension
            }.map {
                AgentObserverSocialDevelopmentValue(
                    dimension: $0.dimension,
                    basisPoints: $0.basisPoints,
                    lastChangedTick: $0.lastChangedTick,
                    lastEventID: $0.lastEventID
                )
            } ?? [],
            socialTrajectory: socialTrajectory,
            recentExposureEventIDs: Array(
                exposures.prefix(8).map(\.sourceEventID)
            ),
            lastSignificantChangeTick: profile?.lastSignificantChangeTick
        )
    }

    func observerGenetics(
        _ agentID: AgentID,
        snapshot: AgentGeneticsSnapshot
    ) -> AgentObserverGenetics? {
        guard let genotype = snapshot.genotypes.first(where: {
            $0.agentID == agentID
        }),
        let development = snapshot.development.first(where: {
            $0.agentID == agentID
        }),
        let phenotype = snapshot.phenotypes.first(where: {
            $0.agentID == agentID
        }) else { return nil }
        return AgentObserverGenetics(
            modelVersion: genotype.schemaVersion,
            genotypeID: genotype.genotypeID,
            origin: genotype.origin,
            contributorIDs: genotype.contributorIDs,
            loci: genotype.loci.map { locus in
                AgentObserverGeneticLocus(
                    locus: locus.locus,
                    contributions: locus.contributions.map {
                        AgentObserverGeneticContribution(
                            allele: $0.allele,
                            contributorID: $0.contributorID,
                            sourceGenotypeID: $0.sourceGenotypeID,
                            sourceAlleleIndex: $0.sourceAlleleIndex
                        )
                    },
                    potentialBasisPoints: locus.potentialBasisPoints
                )
            },
            creationEventID: genotype.creationEventID,
            development: AgentObserverDevelopment(
                active: development.active,
                ageTicks: development.ageTicks,
                lifeStage: development.lifeStage,
                expressionMaturityBasisPoints:
                    development.expressionMaturityBasisPoints,
                physiologicalExposureBasisPoints:
                    development.physiologicalExposureBasisPoints,
                developmentalReserveBasisPoints:
                    development.developmentalReserveBasisPoints,
                trajectory: development.trajectory,
                lastSignificantChangeTick:
                    development.lastSignificantChangeTick,
                stoppedAtTick: development.stoppedAtTick,
                lastEventID: development.lastEventID
            ),
            phenotype: phenotype.traits.map {
                AgentObserverPhenotypeTrait(
                    traitID: $0.traitID,
                    geneticPotentialBasisPoints:
                        $0.geneticPotentialBasisPoints,
                    developmentalFactorBasisPoints:
                        $0.developmentalFactorBasisPoints,
                    physiologicalExpressionFactorBasisPoints:
                        $0.physiologicalExpressionFactorBasisPoints,
                    expressedModifierBasisPoints:
                        $0.expressedModifierBasisPoints,
                    lowerBoundBasisPoints: $0.lowerBoundBasisPoints,
                    upperBoundBasisPoints: $0.upperBoundBasisPoints,
                    provenance: $0.provenance,
                    lastSignificantChangeTick:
                        $0.lastSignificantChangeTick,
                    lastEventID: $0.lastEventID
                )
            }
        )
    }

    func observerPhysiology(
        _ profile: AgentHomeostasisProfile,
        healthReserve: Int
    ) -> AgentObserverPhysiology {
        AgentObserverPhysiology(
            vitalStatus: profile.vitalStatus,
            ageTicks: profile.ageTicks,
            lifeStage: profile.lifeStage,
            ageBand: profile.ageBand,
            condition: profile.condition,
            trend: profile.trend,
            healthReserve: healthReserve,
            energyReserveBasisPoints: profile.energyReserveBasisPoints,
            stressBasisPoints: profile.stressBasisPoints,
            recoveryCapacityBasisPoints:
                profile.recoveryCapacityBasisPoints,
            ageVulnerabilityBasisPoints:
                profile.ageVulnerabilityBasisPoints,
            activeFactors: profile.activeFactors.map {
                AgentObserverHealthFactor(
                    code: $0.code,
                    severityBasisPoints: $0.severityBasisPoints,
                    harmful: $0.harmful,
                    source: $0.source
                )
            },
            limitation: profile.vitalStatus == .incapacitated
                ? "incapacitated: autonomous actions are suspended"
                : nil,
            recentEpisodeCount: profile.recentEpisodes.count,
            episodesTruncated: profile.episodeEvictionCount > 0,
            lastCausalEventID: profile.lastEventID
        )
    }

    func observerChronicleEvent(
        _ event: AgentCausalEvent,
        transition: AgentMaterialRightsTransition?,
        retainedEventIDs: Set<AgentCausalEventID>,
        maximumDirectCauses: Int,
        textLimit: Int
    ) -> AgentObserverChronicleEvent {
        let assetIDs = transition.map { [$0.assetID] } ?? []
        let result: String
        let detail: String
        if let transition {
            result = transition.status
            detail = transition.reason
        } else if case let .operation(status, operationDetail) = event.payload {
            result = status
            detail = operationDetail
        } else {
            result = "recorded"
            detail = event.payload.canonicalText
        }
        let visibleCauses = Array(event.causes.prefix(maximumDirectCauses))
        return AgentObserverChronicleEvent(
            eventID: event.eventID,
            sequence: event.sequence.rawValue,
            tick: event.simulationTick.rawValue,
            kind: event.kind,
            origin: event.origin,
            actorID: event.actorID,
            subjectID: event.subjectID,
            operationID: event.operationID?.rawValue,
            assetIDs: assetIDs,
            causes: visibleCauses,
            directCausesOmitted: max(
                0, event.causes.count - visibleCauses.count
            ),
            missingCauseCount: event.causes.filter {
                !retainedEventIDs.contains($0)
            }.count,
            result: observerText(result, limit: textLimit),
            detail: observerText(detail, limit: textLimit),
            summary: observerText(event.summary, limit: textLimit)
        )
    }

    func observerReason(
        for agentID: AgentID,
        agent: AgentSnapshot,
        activities: AgentAutonomousActivitySnapshot,
        rights: AgentMaterialRightsSnapshot,
        reconciliation: AgentPersistenceReconciliationSnapshot,
        ledgerEvents: [AgentCausalEvent],
        textLimit: Int
    ) -> AgentObserverStructuredReason {
        let activeActivity = activities.activeActivities.first(where: {
            $0.candidate.actorID == agentID
        })
        var candidates: [AgentObserverReasonCandidate] = []
        if let profile = homeostasisProfile(for: agentID),
           profile.vitalStatus == .incapacitated {
            let event = ledgerEvents.last {
                $0.eventID == profile.lastEventID
            }
            candidates.append(AgentObserverReasonCandidate(
                reason: observerStructuredReason(
                    code: .physiologicalIncapacity,
                    category: .blocked,
                    subject: agentID,
                    target: profile.activeFactors.first(where: \.harmful)?
                        .code.rawValue,
                    event: event,
                    presentation:
                        "Physiological incapacity prevents autonomous action",
                    data: [
                        ("condition", profile.condition.rawValue),
                        ("trend", profile.trend.rawValue),
                        ("energy", String(profile.energyReserveBasisPoints)),
                        ("stress", String(profile.stressBasisPoints)),
                    ],
                    textLimit: textLimit
                ),
                tick: profile.lastUpdatedTick,
                causalSequence: event?.sequence.rawValue ?? 0,
                tieBreakPriority: 100
            ))
        }

        let latestUseAttempt = rights.recentTransitions.compactMap {
            transition -> (AgentMaterialRightsTransition, AgentCausalEvent)? in
            guard transition.kind == .useAttempt,
                  let eventID = transition.eventID,
                  let event = ledgerEvents.last(where: {
                      $0.eventID == eventID
                  }),
                  event.actorID == agentID else {
                return nil
            }
            return (transition, event)
        }.max {
            $0.1.sequence < $1.1.sequence
        }
        if let (transition, event) = latestUseAttempt,
           transition.reason.hasPrefix("denied:") {
            let isRelevantToCurrentActivity = activeActivity.map {
                AgentMaterialAssetID(
                    rawValue: $0.candidate.stableReference
                ) == transition.assetID
            } ?? true
            if isRelevantToCurrentActivity {
                candidates.append(AgentObserverReasonCandidate(
                    reason: observerStructuredReason(
                        code: .useRefused, category: .refused,
                        subject: agentID, target: transition.assetID.rawValue,
                        event: event,
                        presentation: "Use refused: "
                            + String(transition.reason.dropFirst(7)),
                        data: [
                            ("asset", transition.assetID.rawValue),
                            ("decision", transition.reason),
                        ],
                        textLimit: textLimit
                    ),
                    tick: event.simulationTick.rawValue,
                    causalSequence: event.sequence.rawValue,
                    tieBreakPriority: 50
                ))
            }
        }

        if let activity = activeActivity,
           let resolution = reconciliation.recentRuns.last?.activityResults.last(
               where: {
                   $0.actorID == agentID
                       && $0.activityID == activity.activityID
               }
           ) {
            let event = resolution.eventID.flatMap { id in
                ledgerEvents.last { $0.eventID == id }
            }
            let keepsActive = resolution.policy.keepsActivityActive
            candidates.append(AgentObserverReasonCandidate(
                reason: observerStructuredReason(
                    code: keepsActive
                        ? .persistenceReconciled : .interruptedAfterRestart,
                    category: keepsActive
                        ? .interruptedReconciled : .replanning,
                    subject: agentID, target: resolution.activityID,
                    event: event, presentation: resolution.reason,
                    data: [
                        ("policy", resolution.policy.rawValue),
                        ("activity", resolution.activityID),
                    ],
                    textLimit: textLimit
                ),
                tick: event?.simulationTick.rawValue ?? activity.updatedAtTick,
                causalSequence: event?.sequence.rawValue ?? 0,
                tieBreakPriority: 60
            ))
        }

        if let activity = activeActivity {
            let materialUse = AgentMaterialUseKind(
                rawValue: activity.candidate.actionKey
            )
            let referencedAssetID = AgentMaterialAssetID(
                rawValue: activity.candidate.stableReference
            )
            let referencedRecord = referencedAssetID.flatMap { assetID in
                rights.records.first { $0.asset.assetID == assetID }
            }
            let ownerAuthorizes = materialUse != nil
                && referencedRecord?.recognizedOwnership?.ownerID == agentID
            let permissionAuthorizes = materialUse.map { use in
                referencedRecord?.permissions.contains {
                    $0.userID == agentID && $0.permits(use, at: tick)
                } == true
            } ?? false
            let authorizationIsExact = ownerAuthorizes || permissionAuthorizes
            let authorizationKinds: Set<AgentMaterialRightsTransitionKind> =
                Set(
                    (ownerAuthorizes ? [.ownershipRecognized] : [])
                        + (permissionAuthorizes ? [.useGranted] : [])
                )
            let authorizationEvent = referencedAssetID.flatMap { assetID in
                rights.recentTransitions.compactMap {
                    transition -> AgentCausalEvent? in
                    guard transition.assetID == assetID,
                          authorizationKinds.contains(transition.kind),
                          let eventID = transition.eventID else {
                        return nil
                    }
                    return ledgerEvents.last { $0.eventID == eventID }
                }.max { $0.sequence < $1.sequence }
            }
            candidates.append(AgentObserverReasonCandidate(
                reason: observerStructuredReason(
                    code: authorizationIsExact
                        ? .authorizedActivity : .activeActivity,
                    category: .acting, subject: agentID,
                    target: authorizationIsExact
                        ? referencedAssetID?.rawValue
                        : activity.candidate.stableReference,
                    event: authorizationEvent,
                    presentation: "Executing "
                        + "\(activity.candidate.actionKey) for "
                        + "\(activity.candidate.source.rawValue)",
                    data: [
                        ("activity", activity.activityID),
                        ("lifecycle", activity.lifecycle.rawValue),
                        ("source", activity.candidate.source.rawValue),
                    ],
                    textLimit: textLimit
                ),
                tick: activity.updatedAtTick,
                causalSequence: 0,
                tieBreakPriority: 40
            ))
        }

        if activeActivity == nil,
           let record = activities.recentRecords.filter({
               $0.activity.candidate.actorID == agentID
           }).max(by: {
               if $0.outcome.completedAtTick != $1.outcome.completedAtTick {
                   return $0.outcome.completedAtTick
                       < $1.outcome.completedAtTick
               }
               return $0.activity.activityID < $1.activity.activityID
           }) {
            let category: AgentObserverReasonCategory
            let code: AgentObserverReasonCode
            switch record.outcome.lifecycle {
            case .blocked:
                if record.outcome.reason.localizedCaseInsensitiveContains("failed") {
                    category = .failed
                    code = .physicalAttemptFailed
                } else {
                    category = .blocked
                    code = record.outcome.reason.localizedCaseInsensitiveContains("replan")
                        ? .boundedReplan : .boundedPhysicalBlock
                }
            case .interrupted, .stale:
                category = .replanning
                code = .boundedReplan
            default:
                category = .waiting
                code = .waitingForCondition
            }
            let event = record.outcome.sourceEventID.flatMap { id in
                ledgerEvents.last { $0.eventID == id }
            }
            candidates.append(AgentObserverReasonCandidate(
                reason: observerStructuredReason(
                    code: code, category: category, subject: agentID,
                    target: record.activity.candidate.stableReference,
                    event: event, presentation: record.outcome.reason,
                    data: [
                        ("activity", record.activity.activityID),
                        ("lifecycle", record.outcome.lifecycle.rawValue),
                    ],
                    textLimit: textLimit
                ),
                tick: record.outcome.completedAtTick,
                causalSequence: event?.sequence.rawValue ?? 0,
                tieBreakPriority: 30
            ))
        }

        if activeActivity == nil, let action = agent.lastAction {
            let event = ledgerEvents.reversed().first {
                guard $0.actorID == agentID,
                      $0.kind == .actionSelected,
                      $0.simulationTick.rawValue == action.tick,
                      case let .cognitive(_, recordedAction, _) = $0.payload
                else {
                    return false
                }
                return recordedAction == action.name
            }
            let waiting = action.name == "wait" || action.name == "rest"
            candidates.append(AgentObserverReasonCandidate(
                reason: observerStructuredReason(
                    code: waiting ? .waitingForCondition : .goalAction,
                    category: waiting ? .waiting : .acting,
                    subject: agentID,
                    target: action.target.map {
                        "\($0.x),\($0.y),\($0.z)"
                    },
                    event: event, presentation: action.reason,
                    data: [
                        ("action", action.name),
                        ("goal", agent.currentGoal.kind.rawValue),
                    ],
                    textLimit: textLimit
                ),
                tick: action.tick,
                causalSequence: event?.sequence.rawValue ?? 0,
                tieBreakPriority: 20
            ))
        }

        if let current = candidates.max(by: observerReasonCandidateLessThan) {
            return current.reason
        }
        return observerStructuredReason(
            code: .noCurrentAction, category: .waiting,
            subject: agentID, target: nil, event: nil,
            presentation: agent.currentGoal.reason,
            data: [("goal", agent.currentGoal.kind.rawValue)],
            textLimit: textLimit
        )
    }

    func observerReasonCandidateLessThan(
        _ lhs: AgentObserverReasonCandidate,
        _ rhs: AgentObserverReasonCandidate
    ) -> Bool {
        if lhs.tick != rhs.tick {
            return lhs.tick < rhs.tick
        }
        if lhs.causalSequence != rhs.causalSequence {
            return lhs.causalSequence < rhs.causalSequence
        }
        return lhs.tieBreakPriority < rhs.tieBreakPriority
    }

    func observerActivity(
        for agentID: AgentID,
        agent: AgentSnapshot,
        activities: AgentAutonomousActivitySnapshot,
        work: AgentWorkCommitmentSnapshot,
        reason: AgentObserverStructuredReason,
        textLimit: Int
    ) -> AgentObserverActivity {
        if let activity = activities.activeActivities.first(where: {
            $0.candidate.actorID == agentID
        }) {
            return AgentObserverActivity(
                activityID: activity.activityID,
                action: observerText(activity.candidate.actionKey, limit: textLimit),
                goal: "civilizationActivity",
                commitmentID: activity.candidate.commitmentID?.rawValue,
                progress: activity.lifecycle.rawValue,
                startedAtTick: activity.selectedAtTick,
                updatedAtTick: activity.updatedAtTick,
                reason: reason
            )
        }
        let commitment = work.commitments.first {
            $0.workerID == agentID && $0.status.isOpen
        }
        return AgentObserverActivity(
            activityID: nil,
            action: observerText(agent.lastAction?.name ?? "none", limit: textLimit),
            goal: agent.currentGoal.kind.rawValue,
            commitmentID: commitment?.commitmentID.rawValue,
            progress: commitment?.status.rawValue ?? agent.state,
            startedAtTick: commitment?.startedAtTick ?? agent.currentGoal.startedAtTick,
            updatedAtTick: agent.lastAction?.tick ?? tick,
            reason: reason
        )
    }

    func observerRelations(
        for agentID: AgentID,
        agent: AgentSnapshot,
        households: AgentHouseholdSnapshot,
        kinship: AgentKinshipSnapshot,
        social: AgentSocialSnapshot,
        textLimit: Int
    ) -> [AgentObserverRelation] {
        var rows: [AgentObserverRelation] = []
        if let membership = households.currentMemberships.first(where: {
            $0.agentID == agentID
        }) {
            for member in households.currentMemberships where
                member.householdID == membership.householdID
                    && member.agentID != agentID {
                rows.append(AgentObserverRelation(
                    kind: .household, otherAgentID: member.agentID, value: nil,
                    sourceEventID: nil,
                    presentation: observerText(
                        "member of \(membership.householdID.rawValue)",
                        limit: textLimit
                    )
                ))
            }
        }
        if let parentage = kinship.parentageRecords.first(where: {
            $0.childID == agentID
        }) {
            rows += parentage.canonicalParentIDs.map {
                AgentObserverRelation(
                    kind: .parent, otherAgentID: $0, value: nil,
                    sourceEventID: parentage.recordedEventID,
                    presentation: "parent"
                )
            }
        }
        for parentage in kinship.parentageRecords where
            parentage.canonicalParentIDs.contains(agentID) {
            rows.append(AgentObserverRelation(
                kind: .child, otherAgentID: parentage.childID, value: nil,
                sourceEventID: parentage.recordedEventID,
                presentation: "child"
            ))
        }
        for trust in social.trustRelations where
            trust.sourceID == agentID || trust.targetID == agentID {
            rows.append(AgentObserverRelation(
                kind: .trust,
                otherAgentID: trust.sourceID == agentID
                    ? trust.targetID : trust.sourceID,
                value: trust.score,
                sourceEventID: trust.lastChangeEventID,
                presentation: "local trust \(trust.score)"
            ))
        }
        for nearby in agent.nearbyAgents {
            guard let other = AgentID(rawValue: nearby.id) else { continue }
            rows.append(AgentObserverRelation(
                kind: .nearbyPhysicalObservation, otherAgentID: other,
                value: nearby.distanceManhattan, sourceEventID: nil,
                presentation: "observed distance \(nearby.distanceManhattan)"
            ))
        }
        return rows.sorted {
            if $0.kind.rawValue != $1.kind.rawValue {
                return $0.kind.rawValue < $1.kind.rawValue
            }
            return $0.otherAgentID < $1.otherAgentID
        }
    }

    func observerHousehold(
        for agentID: AgentID,
        snapshot: AgentHouseholdSnapshot
    ) -> AgentObserverHousehold {
        guard snapshot.enabled else {
            return AgentObserverHousehold(
                status: "unavailable", householdID: nil,
                residenceAnchor: nil, memberIDs: []
            )
        }
        guard let membership = snapshot.currentMemberships.first(where: {
            $0.agentID == agentID
        }) else {
            return AgentObserverHousehold(
                status: "none", householdID: nil,
                residenceAnchor: nil, memberIDs: []
            )
        }
        return AgentObserverHousehold(
            status: "current", householdID: membership.householdID,
            residenceAnchor: membership.residenceAnchor,
            memberIDs: snapshot.currentMemberships.compactMap {
                $0.householdID == membership.householdID ? $0.agentID : nil
            }.sorted()
        )
    }

    func observerProfession(
        for agentID: AgentID,
        snapshot: AgentWorkCommitmentSnapshot,
        textLimit: Int
    ) -> AgentObserverProfession {
        guard snapshot.enabled else {
            return AgentObserverProfession(
                status: "unavailable", primaryDomain: nil,
                secondaryDomains: [], activeCommitmentCount: 0,
                presentation: "Work/profession projection unavailable"
            )
        }
        guard let profile = snapshot.professionProfiles.first(where: {
            $0.agentID == agentID
        }) else {
            return AgentObserverProfession(
                status: "no evidence", primaryDomain: nil,
                secondaryDomains: [], activeCommitmentCount: 0,
                presentation: "No validated profession evidence"
            )
        }
        return AgentObserverProfession(
            status: "derived",
            primaryDomain: profile.primaryWorkDomain?.rawValue,
            secondaryDomains: profile.secondaryDomains.map(\.rawValue),
            activeCommitmentCount: profile.activeCommitmentCount,
            presentation: observerText(
                profile.displayDescriptor ?? "No stable descriptor",
                limit: textLimit
            )
        )
    }

    func observerMaterialAsset(
        _ record: AgentMaterialRightsRecord,
        reconciliation: AgentPersistenceReconciliationSnapshot
    ) -> AgentObserverMaterialAsset {
        let result = reconciliation.latestResults.last {
            $0.assetID == record.asset.assetID
        }
        let permissions = record.permissions.sorted {
            if $0.userID != $1.userID { return $0.userID < $1.userID }
            return $0.permissionID < $1.permissionID
        }.map {
            AgentObserverPresentationDatum(
                key: $0.userID.rawValue,
                value: $0.allowedUses.map(\.rawValue).joined(separator: ",")
            )
        }
        return AgentObserverMaterialAsset(
            assetID: record.asset.assetID,
            itemKey: record.asset.materialIdentity.itemKey,
            quantity: record.asset.quantity,
            physicalHolder: record.lastVerifiedHolder.holder.stableText,
            physicalObservationTick: record.lastVerifiedHolder.observedAtTick,
            custodianID: record.custodianID,
            recognizedOwnerID: record.recognizedOwnership?.ownerID,
            claimantIDs: record.claims.map(\.claimantID).sorted(),
            authorizedUserIDs: record.permissions.map(\.userID).sorted(),
            permittedUsesByUser: permissions,
            conflict: record.hasConflict,
            reconciliationOutcome: result?.outcome.rawValue,
            reconciliationEventID: result?.eventID
        )
    }

    func observerNeeds(_ needs: AgentNeedsSnapshot) -> [AgentObserverNeed] {
        [
            ("hunger", needs.hunger),
            ("fatigue", needs.fatigue),
            ("curiosity", needs.curiosity),
            ("safety", needs.safety),
        ].map {
            AgentObserverNeed(
                code: $0.0,
                normalizedBasisPoints: Int(
                    (max(0, min(1, $0.1)) * 10_000).rounded()
                ),
                presentation: String(format: "%.2f", $0.1)
            )
        }
    }

    func observerAvailability(
        agent: AgentSnapshot,
        activity: AgentObserverActivity,
        work: AgentWorkCommitmentSnapshot
    ) -> String {
        guard agent.isAlive else { return "unavailable:dead" }
        if work.commitments.contains(where: {
            $0.workerID.rawValue == agent.id && $0.status == .suspended
        }) {
            return "unavailable:suspended"
        }
        return activity.activityID == nil ? "available" : "engaged"
    }

    func observerStructuredReason(
        code: AgentObserverReasonCode,
        category: AgentObserverReasonCategory,
        subject: AgentID,
        target: String?,
        event: AgentCausalEvent?,
        presentation: String,
        data: [(String, String)],
        textLimit: Int
    ) -> AgentObserverStructuredReason {
        AgentObserverStructuredReason(
            code: code, category: category,
            authoritativeSubjectID: subject,
            targetOrDependency: target.map {
                observerText($0, limit: textLimit)
            },
            causalEventID: event?.eventID,
            causalSequence: event?.sequence.rawValue,
            presentation: observerText(presentation, limit: textLimit),
            presentationData: data.map {
                AgentObserverPresentationDatum(
                    key: observerText($0.0, limit: textLimit),
                    value: observerText($0.1, limit: textLimit)
                )
            }.sorted { $0.key < $1.key }
        )
    }

    func observerText(_ text: String, limit: Int) -> String {
        text.count <= limit ? text : String(text.prefix(max(1, limit - 1))) + "…"
    }

    func observerDigest(_ text: String) -> String {
        var value: UInt64 = 14_695_981_039_346_656_037
        for byte in text.utf8 {
            value ^= UInt64(byte)
            value &*= 1_099_511_628_211
        }
        let digits = String(value, radix: 16)
        return String(repeating: "0", count: max(0, 16 - digits.count)) + digits
    }
}

private extension AgentMaterialPhysicalHolder {
    var agentID: AgentID? {
        guard case let .agent(agentID) = self else { return nil }
        return agentID
    }
}
