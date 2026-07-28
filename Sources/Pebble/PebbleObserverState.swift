import Foundation
import PebbleAgents
import PebbleCore

enum PebbleObserverView: Equatable {
    case individual
    case globalChronicle
    case causalEvent(AgentCausalEventID)
}

struct PebbleObserverUIState: Equatable {
    var isOpen = false
    var selectedAgentID: AgentID?
    var view: PebbleObserverView = .individual
    var chroniclePage = 0
    var chronicleFilter = AgentObserverChronicleFilter()
}

struct PebbleObserverPresentation {
    let title: String
    let subtitle: String
    let lines: [String]
    let selectedAgentID: AgentID?
    let snapshotGeneration: String
}

extension PebbleAgentController {
    func observerPresentation(world: World) -> PebbleObserverPresentation? {
        guard observerUIState.isOpen,
              let snapshot = observerSnapshot(world: world) else { return nil }
        let selected = observerUIState.selectedAgentID.flatMap { selected in
            snapshot.individuals.first { $0.agentID == selected }
        } ?? snapshot.individuals.first
        let subtitle = [
            "schema \(snapshot.header.schemaVersion)",
            "world \(snapshot.header.worldBinding.worldID)",
            "tick \(snapshot.header.asOfTick)",
            "seq \(snapshot.header.causalSequence)",
        ].joined(separator: "  ")
        let lines: [String]
        switch observerUIState.view {
        case .individual:
            lines = observerIndividualLines(selected, snapshot: snapshot)
        case .globalChronicle:
            lines = observerGlobalLines(snapshot, state: observerUIState)
        case let .causalEvent(eventID):
            lines = observerCausalLines(eventID, snapshot: snapshot)
        }
        return PebbleObserverPresentation(
            title: "PEBBLE CIVILIZATION — OBSERVER V1 [READ ONLY]",
            subtitle: subtitle,
            lines: lines,
            selectedAgentID: selected?.agentID,
            snapshotGeneration: snapshot.header.snapshotGeneration
        )
    }

    func observerSnapshot(world: World) -> AgentObserverSnapshot? {
        guard let session, let worldID = persistenceWorldID else { return nil }
        do {
            let store = try PebbleAgentPersistenceStore(worldID: worldID)
            let binding = try AgentObserverWorldBinding(
                worldID: worldID,
                storageIdentity: store.storageIdentity,
                seed: world.seed,
                dimension: persistenceDimension,
                observedWorldTick: world.time
            )
            return session.observerSnapshot(worldBinding: binding)
        } catch {
            return nil
        }
    }

    private func observerIndividualLines(
        _ individual: AgentObserverIndividual?,
        snapshot: AgentObserverSnapshot
    ) -> [String] {
        guard let individual else {
            return ["[UNKNOWN] No individual is available in this bounded projection."]
        }
        let needs = individual.needs.map {
            "\($0.code)=\($0.presentation)"
        }.joined(separator: "  ")
        var lines = [
            "[CIVILIZATION] individual \(individual.agentID.rawValue)",
            "life=\(individual.lifeState)  availability=\(individual.availability)",
            "[PHYSICAL OBSERVATION] position "
                + observerPosition(individual.observedPhysicalPosition),
            "source=\(individual.physicalPositionSource)",
            "[CIVILIZATION STATE] needs \(needs)",
            "activity=\(individual.activity.action)  goal=\(individual.activity.goal)",
            "progress=\(individual.activity.progress)  commitment="
                + "\(individual.activity.commitmentID ?? "none")",
            "[AUTHORITATIVE REASON] \(individual.activity.reason.category.rawValue)"
                + "/\(individual.activity.reason.code.rawValue)",
            individual.activity.reason.presentation,
            "dependency=\(individual.activity.reason.targetOrDependency ?? "none")",
            "causal=\(individual.activity.reason.causalEventID?.rawValue ?? "unavailable")",
            "[SOCIAL] household=\(individual.household.householdID?.rawValue ?? individual.household.status)"
                + " members=\(individual.household.memberIDs.map(\.rawValue).joined(separator: ","))",
            "profession=\(individual.profession.primaryDomain ?? individual.profession.status)"
                + " commitments=\(individual.profession.activeCommitmentCount)",
        ]
        if individual.relations.isEmpty {
            lines.append("[SOCIAL] relations=unknown-or-none")
        } else {
            lines.append("[SOCIAL] relations")
            lines += individual.relations.prefix(3).map {
                "  \($0.kind.rawValue):\($0.otherAgentID.rawValue) \($0.presentation)"
            }
        }
        if individual.materialAssets.isEmpty {
            lines.append("[SOCIAL CLAIM / PERMISSION] assets=none")
        } else {
            lines.append("[PHYSICAL + SOCIAL RIGHTS]")
            for asset in individual.materialAssets.prefix(2) {
                lines += [
                    "  asset=\(asset.assetID.rawValue) item=\(asset.itemKey) x\(asset.quantity)",
                    "  [PHYSICAL] holder=\(asset.physicalHolder) observed@\(asset.physicalObservationTick)",
                    "  [SOCIAL] custodian=\(asset.custodianID?.rawValue ?? "none")"
                        + " owner=\(asset.recognizedOwnerID?.rawValue ?? "none")",
                    "  claims=\(asset.claimantIDs.map(\.rawValue).joined(separator: ","))"
                        + " users=\(asset.authorizedUserIDs.map(\.rawValue).joined(separator: ","))",
                    "  conflict=\(asset.conflict ? "YES" : "no")"
                        + " reconciliation=\(asset.reconciliationOutcome ?? "not-run")",
                ]
            }
        }
        lines.append("[CAUSAL HISTORY] newest individual references")
        let eventsByID = Dictionary(
            uniqueKeysWithValues: snapshot.globalChronicle.map { ($0.eventID, $0) }
        )
        lines += individual.recentEventIDs.prefix(3).map { eventID in
            if let event = eventsByID[eventID] {
                return "  #\(event.sequence) \(event.kind.rawValue): \(event.summary)"
            }
            return "  \(eventID.rawValue) [truncated from global page]"
        }
        if individual.recentEventsTruncated {
            lines.append("  [TRUNCATED] earlier individual events are not displayed")
        }
        if snapshot.truncation.isTruncated {
            lines.append(
                "[TRUNCATED] a=\(snapshot.truncation.agentsOmitted)"
                    + " r=\(snapshot.truncation.relationsOmitted)"
                    + " assets=\(snapshot.truncation.assetsOmitted)"
                    + " events=\(snapshot.truncation.chronicleEventsOmitted)"
            )
        }
        return lines
    }

    private func observerGlobalLines(
        _ snapshot: AgentObserverSnapshot,
        state: PebbleObserverUIState
    ) -> [String] {
        let pageSize = 18
        let page = snapshot.chroniclePage(
            filter: state.chronicleFilter,
            offset: state.chroniclePage * pageSize,
            limit: pageSize
        )
        var lines = [
            "[CAUSAL HISTORY] global timeline — newest first",
            "page=\(state.chroniclePage + 1) shown=\(page.values.count)/\(page.totalCount)"
                + " more=\(page.hasMore ? "yes" : "no")",
            "selection: /lab observer select <agent> | /lab observer reason",
        ]
        lines += page.values.map {
            "#\($0.sequence) t\($0.tick) \($0.kind.rawValue) [\($0.result)] "
                + "\($0.summary)"
        }
        if snapshot.truncation.chronicleEventsOmitted > 0 {
            lines.append(
                "[TRUNCATED] \(snapshot.truncation.chronicleEventsOmitted)"
                    + " older events omitted or evicted"
            )
        }
        return lines
    }

    private func observerCausalLines(
        _ eventID: AgentCausalEventID,
        snapshot: AgentObserverSnapshot
    ) -> [String] {
        let events = Dictionary(
            uniqueKeysWithValues: snapshot.globalChronicle.map { ($0.eventID, $0) }
        )
        guard let event = events[eventID] else {
            return [
                "[CAUSAL HISTORY] requested event unavailable",
                eventID.rawValue,
                "[UNKNOWN / TRUNCATED] it is outside the retained Observer page.",
            ]
        }
        var lines = [
            "[CAUSAL HISTORY] event #\(event.sequence)",
            "id=\(event.eventID.rawValue)",
            "tick=\(event.tick) kind=\(event.kind.rawValue) origin=\(event.origin.rawValue)",
            "actor=\(event.actorID?.rawValue ?? "none")"
                + " subject=\(event.subjectID?.rawValue ?? "none")",
            "operation=\(event.operationID ?? "none") result=\(event.result)",
            "summary=\(event.summary)",
            "detail=\(event.detail)",
            "assets=\(event.assetIDs.map(\.rawValue).joined(separator: ",").nilIfEmpty ?? "none")",
            "[CAUSAL PARENTS]",
        ]
        if event.causes.isEmpty {
            lines.append("  none recorded")
        } else {
            lines += event.causes.map { cause in
                if let parent = events[cause] {
                    return "  #\(parent.sequence) \(parent.kind.rawValue): \(parent.summary)"
                }
                return "  \(cause.rawValue) [missing / truncated]"
            }
        }
        if event.missingCauseCount > 0 {
            lines.append(
                "[TRUNCATED] \(event.missingCauseCount) causal parent(s) unavailable"
            )
        }
        lines += [
            "",
            "/lab observer individual — return to selected individual",
            "/lab observer global — return to global timeline",
        ]
        return lines
    }

    private func observerPosition(_ position: AgentPosition) -> String {
        "\(position.x),\(position.y),\(position.z)"
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
