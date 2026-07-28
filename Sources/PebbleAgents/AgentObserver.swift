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
    public let maximumCausalDepth: Int
    public let maximumPresentationTextLength: Int

    public init(
        maximumAgents: Int = 64,
        maximumRelationsPerAgent: Int = 16,
        maximumAssetsPerAgent: Int = 16,
        maximumChronicleEvents: Int = 96,
        maximumEventsPerAgent: Int = 24,
        maximumCausalDepth: Int = 8,
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
        guard (1...AgentCausalEvent.maximumCauseCount).contains(maximumCausalDepth) else {
            throw AgentObserverError.invalidConfiguration("causal depth")
        }
        guard (32...512).contains(maximumPresentationTextLength) else {
            throw AgentObserverError.invalidConfiguration("presentation text")
        }
        self.maximumAgents = maximumAgents
        self.maximumRelationsPerAgent = maximumRelationsPerAgent
        self.maximumAssetsPerAgent = maximumAssetsPerAgent
        self.maximumChronicleEvents = maximumChronicleEvents
        self.maximumEventsPerAgent = maximumEventsPerAgent
        self.maximumCausalDepth = maximumCausalDepth
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
    public let textWasTruncated: Bool

    public var isTruncated: Bool {
        agentsOmitted > 0 || relationsOmitted > 0 || assetsOmitted > 0
            || chronicleEventsOmitted > 0 || perAgentEventsOmitted > 0
            || textWasTruncated
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
}

public struct AgentObserverSnapshot: Codable, Equatable, Sendable {
    public let header: AgentObserverSnapshotHeader
    public let individuals: [AgentObserverIndividual]
    /// Newest event first. Sequence remains the stable total order.
    public let globalChronicle: [AgentObserverChronicleEvent]
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
                recentEventsTruncated: omittedEvents > 0
            )
        }
        let generationSource = [
            "observer-v1", simulationID.rawValue, worldBinding.worldID,
            worldBinding.storageIdentity, String(tick),
            String(ledger.summary.latestSequence), ledger.summary.digest,
            rights.records.map(\.asset.assetID.rawValue).joined(separator: ","),
            reconciliation.recentRuns.last?.runID ?? "none",
        ].joined(separator: "|")
        let truncation = AgentObserverTruncation(
            agentsOmitted: max(0, sortedAgents.count - visibleAgents.count),
            relationsOmitted: relationsOmitted,
            assetsOmitted: assetsOmitted,
            chronicleEventsOmitted: chronicleOmitted,
            perAgentEventsOmitted: perAgentEventsOmitted,
            textWasTruncated: textWasTruncated
        )
        return AgentObserverSnapshot(
            header: AgentObserverSnapshotHeader(
                schemaVersion: 1,
                sessionIdentity: simulationID,
                worldBinding: worldBinding,
                asOfTick: tick,
                causalSequence: ledger.summary.latestSequence,
                snapshotGeneration: observerDigest(generationSource)
            ),
            individuals: individuals,
            globalChronicle: chronicle,
            truncation: truncation
        )
    }
}

private extension AgentSimulationSession {
    func observerChronicleEvent(
        _ event: AgentCausalEvent,
        transition: AgentMaterialRightsTransition?,
        retainedEventIDs: Set<AgentCausalEventID>,
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
            causes: Array(event.causes.prefix(AgentCausalEvent.maximumCauseCount)),
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
        let relevantTransitions = rights.recentTransitions.reversed().compactMap {
            transition -> (AgentMaterialRightsTransition, AgentCausalEvent)? in
            guard let eventID = transition.eventID,
                  let event = ledgerEvents.last(where: { $0.eventID == eventID }),
                  event.actorID == agentID else { return nil }
            return (transition, event)
        }
        if let (transition, event) = relevantTransitions.first,
           transition.kind == .useAttempt,
           transition.reason.hasPrefix("denied:") {
            return observerStructuredReason(
                code: .useRefused, category: .refused, subject: agentID,
                target: transition.assetID.rawValue, event: event,
                presentation: "Use refused: \(transition.reason.dropFirst(7))",
                data: [
                    ("asset", transition.assetID.rawValue),
                    ("decision", transition.reason),
                ], textLimit: textLimit
            )
        }
        if let resolution = reconciliation.recentRuns.last?.activityResults.last(where: {
            resolution in
            resolution.actorID == agentID
                && activities.activeActivities.contains {
                    $0.activityID == resolution.activityID
                }
        }) {
            let event = resolution.eventID.flatMap { id in
                ledgerEvents.last { $0.eventID == id }
            }
            let keepsActive = resolution.policy.keepsActivityActive
            return observerStructuredReason(
                code: keepsActive ? .persistenceReconciled : .interruptedAfterRestart,
                category: keepsActive ? .interruptedReconciled : .replanning,
                subject: agentID, target: resolution.activityID, event: event,
                presentation: resolution.reason,
                data: [
                    ("policy", resolution.policy.rawValue),
                    ("activity", resolution.activityID),
                ], textLimit: textLimit
            )
        }
        if let activity = activities.activeActivities.first(where: {
            $0.candidate.actorID == agentID
        }) {
            let permittedAsset = rights.records.first { record in
                record.recognizedOwnership?.ownerID == agentID
                    || record.permissions.contains {
                        $0.userID == agentID
                            && $0.allowedUses.map(\.rawValue)
                                .contains(activity.candidate.actionKey)
                    }
                    || record.permissions.contains { $0.userID == agentID }
            }
            let permissionEvent = permittedAsset.flatMap { asset in
                rights.recentTransitions.reversed().first {
                    $0.assetID == asset.asset.assetID
                        && ($0.kind == .useGranted
                            || $0.kind == .ownershipRecognized)
                }?.eventID
            }.flatMap { id in
                ledgerEvents.last { $0.eventID == id }
            }
            return observerStructuredReason(
                code: permissionEvent == nil ? .activeActivity : .authorizedActivity,
                category: .acting, subject: agentID,
                target: permittedAsset?.asset.assetID.rawValue
                    ?? activity.candidate.stableReference,
                event: permissionEvent,
                presentation: "Executing \(activity.candidate.actionKey) for "
                    + "\(activity.candidate.source.rawValue)",
                data: [
                    ("activity", activity.activityID),
                    ("lifecycle", activity.lifecycle.rawValue),
                    ("source", activity.candidate.source.rawValue),
                ], textLimit: textLimit
            )
        }
        if let record = activities.recentRecords.reversed().first(where: {
            $0.activity.candidate.actorID == agentID
                && $0.outcome.completedAtTick >= (agent.lastAction?.tick ?? 0)
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
            return observerStructuredReason(
                code: code, category: category, subject: agentID,
                target: record.activity.candidate.stableReference, event: event,
                presentation: record.outcome.reason,
                data: [
                    ("activity", record.activity.activityID),
                    ("lifecycle", record.outcome.lifecycle.rawValue),
                ], textLimit: textLimit
            )
        }
        if let action = agent.lastAction {
            let event = ledgerEvents.reversed().first {
                $0.actorID == agentID && $0.kind == .actionSelected
            }
            let waiting = action.name == "wait" || action.name == "rest"
            return observerStructuredReason(
                code: waiting ? .waitingForCondition : .goalAction,
                category: waiting ? .waiting : .acting, subject: agentID,
                target: action.target.map {
                    "\($0.x),\($0.y),\($0.z)"
                }, event: event, presentation: action.reason,
                data: [
                    ("action", action.name),
                    ("goal", agent.currentGoal.kind.rawValue),
                ], textLimit: textLimit
            )
        }
        return observerStructuredReason(
            code: .noCurrentAction, category: .waiting, subject: agentID,
            target: nil, event: nil, presentation: agent.currentGoal.reason,
            data: [("goal", agent.currentGoal.kind.rawValue)],
            textLimit: textLimit
        )
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
