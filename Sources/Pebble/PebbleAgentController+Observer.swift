import Foundation
import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func handleObserver(
        _ arguments: [String],
        world: World
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab observer <open|close|status|next|previous"
            + "|select <agentID>|individual|global|reason|event <sequence>"
            + "|page <next|previous|number>|filter <clear|agent ID|asset ID|kind KIND>>"
        guard observerFeatureEnabled else {
            return failure(
                "Observer disabled. Set PEBBLELAB_APP_AGENTS_OBSERVER=1 before launch."
            )
        }
        guard let command = arguments.first?.lowercased() else {
            return failure(usage)
        }
        guard let initialSession = session else {
            return failure("Observer requires an active PebbleAgents session.")
        }
        let digestBefore = try? initialSession.durableStateDigest()
        let tickBefore = initialSession.tick
        let sequenceBefore = initialSession.causalLedgerSnapshot().summary.latestSequence

        switch command {
        case "open":
            guard arguments.count == 1,
                  let snapshot = observerSnapshot(world: world) else {
                return failure(usage)
            }
            observerUIState.isOpen = true
            if observerUIState.selectedAgentID == nil
                || !snapshot.individuals.contains(where: {
                    $0.agentID == observerUIState.selectedAgentID
                }) {
                observerUIState.selectedAgentID = focusedAgentId.flatMap(AgentID.init(rawValue:))
                    ?? snapshot.individuals.first?.agentID
            }
            observerUIState.view = .individual
        case "close":
            guard arguments.count == 1 else { return failure(usage) }
            observerUIState.isOpen = false
        case "status":
            guard arguments.count == 1 else { return failure(usage) }
        case "next", "previous":
            guard arguments.count == 1,
                  let snapshot = observerSnapshot(world: world),
                  !snapshot.individuals.isEmpty else {
                return failure(usage)
            }
            let ids = snapshot.individuals.map(\.agentID)
            let current = observerUIState.selectedAgentID.flatMap(ids.firstIndex) ?? 0
            let delta = command == "next" ? 1 : -1
            observerUIState.selectedAgentID = ids[
                (current + delta + ids.count) % ids.count
            ]
            observerUIState.view = .individual
        case "select":
            guard arguments.count == 2,
                  let selected = AgentID(rawValue: arguments[1]),
                  let snapshot = observerSnapshot(world: world),
                  snapshot.individuals.contains(where: {
                      $0.agentID == selected
                  }) else {
                return failure(usage)
            }
            observerUIState.selectedAgentID = selected
            observerUIState.view = .individual
        case "individual":
            guard arguments.count == 1 else { return failure(usage) }
            observerUIState.view = .individual
        case "global":
            guard arguments.count == 1 else { return failure(usage) }
            observerUIState.view = .globalChronicle
        case "page":
            guard arguments.count == 2 else { return failure(usage) }
            if arguments[1] == "next" {
                observerUIState.chroniclePage += 1
            } else if arguments[1] == "previous" {
                observerUIState.chroniclePage = max(
                    0, observerUIState.chroniclePage - 1
                )
            } else if let page = Int(arguments[1]), page >= 1 {
                observerUIState.chroniclePage = page - 1
            } else {
                return failure(usage)
            }
            observerUIState.view = .globalChronicle
        case "filter":
            guard arguments.count == 2 || arguments.count == 3 else {
                return failure(usage)
            }
            switch arguments[1] {
            case "clear" where arguments.count == 2:
                observerUIState.chronicleFilter = AgentObserverChronicleFilter()
            case "agent" where arguments.count == 3:
                guard let id = AgentID(rawValue: arguments[2]) else {
                    return failure(usage)
                }
                observerUIState.chronicleFilter = AgentObserverChronicleFilter(
                    agentID: id
                )
            case "asset" where arguments.count == 3:
                guard let id = AgentMaterialAssetID(rawValue: arguments[2]) else {
                    return failure(usage)
                }
                observerUIState.chronicleFilter = AgentObserverChronicleFilter(
                    assetID: id
                )
            case "kind" where arguments.count == 3:
                guard let kind = AgentCausalEventKind(rawValue: arguments[2]) else {
                    return failure(usage)
                }
                observerUIState.chronicleFilter = AgentObserverChronicleFilter(
                    eventKind: kind
                )
            default:
                return failure(usage)
            }
            observerUIState.chroniclePage = 0
            observerUIState.view = .globalChronicle
        case "reason":
            guard arguments.count == 1,
                  let snapshot = observerSnapshot(world: world),
                  let selected = selectedObserverIndividual(snapshot),
                  let eventID = selected.activity.reason.causalEventID else {
                return failure("Selected reason has no retained causal event.")
            }
            observerUIState.view = .causalEvent(eventID)
        case "event":
            guard arguments.count == 2,
                  let sequence = UInt64(arguments[1]),
                  let snapshot = observerSnapshot(world: world),
                  let event = snapshot.globalChronicle.first(where: {
                      $0.sequence == sequence
                  }) else {
                return failure(usage)
            }
            observerUIState.view = .causalEvent(event.eventID)
        default:
            return failure(usage)
        }

        guard let currentSession = session else {
            return failure("Observer session disappeared during a read-only command.")
        }
        let digestAfter = try? currentSession.durableStateDigest()
        let tickAfter = currentSession.tick
        let sequenceAfter = currentSession.causalLedgerSnapshot().summary.latestSequence
        let digestStable = digestBefore != nil && digestBefore == digestAfter
        let tickStable = tickBefore == tickAfter
        let sequenceStable = sequenceBefore == sequenceAfter
        guard digestStable, tickStable, sequenceStable else {
            return failure("Observer violated its read-only boundary.")
        }
        if command == "close" {
            let message = "observer closed mutation=none tickStable=1 causalStable=1 digestStable=1"
            trace(message)
            return success(message)
        }
        guard let snapshot = observerSnapshot(world: world),
              let selected = selectedObserverIndividual(snapshot) else {
            return failure("Observer could not produce its authoritative projection.")
        }
        let asset = selected.materialAssets.first
        let physiology = selected.physiology
        let genetics = selected.genetics
        let childhood = selected.childhood
        let family = selected.family
        let view: String
        switch observerUIState.view {
        case .individual: view = "individual"
        case .globalChronicle: view = "global"
        case let .causalEvent(id): view = "event:\(id.sequence.rawValue)"
        }
        let reasonEventText = selected.activity.reason.causalSequence
            .map(String.init) ?? "none"
        let contributorText = genetics?.contributorIDs.map(\.rawValue)
            .joined(separator: ",") ?? "unavailable"
        let phenotypeText = genetics?.phenotype.map { trait in
            trait.traitID.rawValue + ":"
                + String(trait.expressedModifierBasisPoints)
        }.joined(separator: ",") ?? "unavailable"
        let familyRelationText = family?.relations.map {
            "\($0.kind.rawValue):\($0.relatedPersonID.rawValue)"
                + ":\($0.source.rawValue)"
        }.joined(separator: ",") ?? "none"
        let familyHouseText = family?.houseMemberships.map {
            "\($0.houseID.rawValue):\($0.basis.rawValue)"
        }.joined(separator: ",") ?? "none"
        let formerPartnerText = family?.formerUnionPartnerIDs.map(\.rawValue)
            .joined(separator: ",") ?? "none"
        let familyLineageText = family?.lineageIDs.map(\.rawValue)
            .joined(separator: ",") ?? "none"
        let familyHouseIDText = family?.houseMemberships.map {
            $0.houseID.rawValue
        }.joined(separator: ",") ?? "none"
        let latestEstate = snapshot.estateAuthority?.estates.last
        let renewable = snapshot.renewableSubsistence?.last
        let message = [
            "observer status",
            "open=\(observerUIState.isOpen ? 1 : 0)",
            "view=\(view)",
            "selected=\(selected.agentID.rawValue)",
            "schema=\(snapshot.header.schemaVersion)",
            "world=\(snapshot.header.worldBinding.worldID)",
            "storage=\(snapshot.header.worldBinding.storageIdentity)",
            "simulation=\(snapshot.header.sessionIdentity.rawValue)",
            "tick=\(snapshot.header.asOfTick)",
            "sequence=\(snapshot.header.causalSequence)",
            "generation=\(snapshot.header.snapshotGeneration)",
            "activity=\(selected.activity.action)",
            "reason=\(selected.activity.reason.category.rawValue)"
                + ":\(selected.activity.reason.code.rawValue)",
            "reasonEvent=\(reasonEventText)",
            "holder=\(asset?.physicalHolder ?? "none")",
            "custodian=\(asset?.custodianID?.rawValue ?? "none")",
            "owner=\(asset?.recognizedOwnerID?.rawValue ?? "none")",
            "claims=\(asset?.claimantIDs.map(\.rawValue).joined(separator: ",") ?? "none")",
            "users=\(asset?.authorizedUserIDs.map(\.rawValue).joined(separator: ",") ?? "none")",
            "events=\(selected.recentEventIDs.count)",
            "vital=\(physiology?.vitalStatus.rawValue ?? "unavailable")",
            "age=\(physiology?.ageTicks ?? -1)",
            "stage=\(physiology?.lifeStage.rawValue ?? "unavailable")",
            "healthCondition=\(physiology?.condition.rawValue ?? "unavailable")",
            "healthTrend=\(physiology?.trend.rawValue ?? "unavailable")",
            "energy=\(physiology?.energyReserveBasisPoints ?? -1)",
            "stress=\(physiology?.stressBasisPoints ?? -1)",
            "genotype=\(genetics?.genotypeID.rawValue ?? "unavailable")",
            "geneticOrigin=\(genetics?.origin.rawValue ?? "unavailable")",
            "geneticContributors=" + contributorText,
            "development=\(genetics?.development.expressionMaturityBasisPoints ?? -1)",
            "trajectory=\(genetics?.development.trajectory.rawValue ?? "unavailable")",
            "phenotype=" + phenotypeText,
            "dependency=\(childhood?.dependencyStatus ?? "unavailable")",
            "guardian=\(childhood?.guardianID?.rawValue ?? "unavailable")",
            "guardianshipBasis=\(childhood?.guardianshipBasis?.rawValue ?? "unavailable")",
            "caregiver=\(childhood?.currentCaregiverID?.rawValue ?? "unavailable")",
            "careEngagedTicks=\(childhood?.currentCareEngagedTicks ?? -1)",
            "autonomyReadiness=\(childhood?.autonomyReadinessBasisPoints ?? -1)",
            "socialDimensions=\(childhood?.socialDevelopment.count ?? 0)",
            "childhoodAtRisk=\(childhood?.atRisk == true ? 1 : 0)",
            "unionPartner=\(family?.activeUnionPartnerID?.rawValue ?? "none")",
            "formerPartners=\(formerPartnerText.isEmpty ? "none" : formerPartnerText)",
            "familyRelations=\(familyRelationText.isEmpty ? "none" : familyRelationText)",
            "lineages=\(familyLineageText.isEmpty ? "none" : familyLineageText)",
            "houses=\(familyHouseIDText.isEmpty ? "none" : familyHouseIDText)",
            "houseMemberships=\(familyHouseText.isEmpty ? "none" : familyHouseText)",
            "estate=\(latestEstate?.estateID.rawValue ?? "none")",
            "estateStatus=\(latestEstate?.status.rawValue ?? "none")",
            "estateAdministrator=\(latestEstate?.administratorID?.rawValue ?? "none")",
            "estateTier=\(latestEstate?.beneficiaryTier.rawValue ?? "none")",
            "estateAssets=\(latestEstate?.totalAssetCount ?? 0)",
            "estateSettledAssets=\(latestEstate?.settledAssetCount ?? 0)",
            "estateBlockedAssets=\(latestEstate?.blockedAssetCount ?? 0)",
            "renewablePlot=\(renewable?.plotID.rawValue ?? "none")",
            "renewableCrop=\(renewable?.crop.rawValue ?? "none")",
            "renewableCycle=\(renewable?.cycleOrdinal ?? 0)",
            "renewableFirstOutput=\(renewable?.firstOutputQuantity ?? 0)",
            "renewableConsumed=\(renewable?.consumedQuantity ?? 0)",
            "renewableReserved=\(renewable?.reservedOutputQuantity ?? 0)",
            "renewableSecondInput=\(renewable?.secondInputQuantity ?? 0)",
            "renewableSecondOutput=\(renewable?.secondOutputQuantity ?? 0)",
            "renewableStatus=\(renewable?.status.rawValue ?? "none")",
            "renewableBlock=\(renewable?.blockReason ?? "none")",
            "deaths=\(snapshot.recentDeaths.count)",
            "truncated=\(snapshot.truncation.isTruncated ? 1 : 0)",
            "mutation=none",
            "tickStable=1",
            "causalStable=1",
            "digestStable=1",
        ].joined(separator: " ")
        trace(message)
        return success(message)
    }

    func handleObserverProof(
        _ arguments: [String],
        world: World
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab observer-proof <setup|status>"
        guard arguments.count == 1 else { return failure(usage) }
        guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1",
              observerFeatureEnabled, persistenceFeatureEnabled,
              persistenceReconciliationFeatureEnabled,
              materialFeatureEnabled else {
            return failure("Observer proof requires all CIV-26/27 proof gates.")
        }
        switch arguments[0].lowercased() {
        case "setup":
            guard var staged = session, activeWorld === world, isPaused else {
                return failure("Observer proof requires an active paused session.")
            }
            guard let record = staged.materialRightsSnapshot().records.first,
                  let actor = AgentID(rawValue: "agent_2") else {
                return failure(
                    "Observer proof requires the CIV-27 rights/reconciliation fixture."
                )
            }
            let request = AgentMaterialUseRequest(
                requestID: "civ28-live-refused-use",
                assetID: record.asset.assetID,
                actorID: actor,
                use: .toolUse,
                verifiedHolder: record.lastVerifiedHolder
            )
            let decision = staged.evaluateMaterialUse(request)
            guard decision.verdict == .denied else {
                return failure("Observer refusal fixture unexpectedly received authorization.")
            }
            do {
                _ = try staged.applyMaterialRightsOperation(.useAttempt(
                    AgentMaterialUseAttemptOutcome(
                        operationID: "civ28-live-refused-use",
                        decision: decision,
                        status: .notAttempted,
                        resultingObservation: nil,
                        physicalReceiptID: nil
                    )
                ))
                session = staged
                let event = staged.materialRightsSnapshot().recentTransitions.last?.eventID
                let message = [
                    "observer proof setup",
                    "actor=\(actor.rawValue)",
                    "asset=\(record.asset.assetID.rawValue)",
                    "verdict=\(decision.verdict.rawValue)",
                    "reason=\(decision.reason.rawValue)",
                    "physicalAttempt=none",
                    "holder=\(record.lastVerifiedHolder.holder.stableText)",
                    "event=\(event?.sequence.rawValue ?? 0)",
                    "mutation=causalFixtureOnly",
                ].joined(separator: " ")
                trace(message)
                return success(message)
            } catch {
                return failure("Observer refusal fixture failed atomically: \(error)")
            }
        case "status":
            guard let current = session,
                  let ordinary = observerSnapshot(world: world) else {
                return failure("Observer proof has no active projection.")
            }
            let tiny = try! AgentObserverConfiguration(
                maximumAgents: 2,
                maximumRelationsPerAgent: 1,
                maximumAssetsPerAgent: 1,
                maximumChronicleEvents: 1,
                maximumEventsPerAgent: 1,
                maximumDirectCausesPerEvent: 1,
                maximumPresentationTextLength: 64
            )
            let digestBefore = try? current.durableStateDigest()
            let bounded = current.observerSnapshot(
                worldBinding: ordinary.header.worldBinding,
                configuration: tiny
            )
            let digestAfter = try? current.durableStateDigest()
            guard digestBefore != nil, digestBefore == digestAfter,
                  bounded.truncation.isTruncated,
                  bounded.truncation.agentsOmitted == 1,
                  bounded.truncation.chronicleEventsOmitted > 0 else {
                return failure("Observer bounded/truncation proof failed.")
            }
            let message = [
                "observer proof status",
                "sameGeneration=\(ordinary.header.snapshotGeneration)",
                "boundedAgents=\(bounded.individuals.count)",
                "agentsOmitted=\(bounded.truncation.agentsOmitted)",
                "eventsOmitted=\(bounded.truncation.chronicleEventsOmitted)",
                "truncationVisible=1",
                "mutation=none",
                "digestStable=1",
            ].joined(separator: " ")
            trace(message)
            return success(message)
        default:
            return failure(usage)
        }
    }

    private func selectedObserverIndividual(
        _ snapshot: AgentObserverSnapshot
    ) -> AgentObserverIndividual? {
        observerUIState.selectedAgentID.flatMap { selected in
            snapshot.individuals.first { $0.agentID == selected }
        } ?? snapshot.individuals.first
    }
}
