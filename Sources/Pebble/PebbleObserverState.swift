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
            title: "PEBBLE CIVILIZATION — OBSERVER V"
                + "\(snapshot.header.schemaVersion) [READ ONLY]",
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
        if let family = individual.family {
            lines += [
                "[UNIONS / FAMILY — DERIVED, READ ONLY]",
                "activePartner=\(family.activeUnionPartnerID?.rawValue ?? "none")"
                    + " former="
                    + (family.formerUnionPartnerIDs.isEmpty
                        ? "none"
                        : family.formerUnionPartnerIDs.map(\.rawValue)
                            .joined(separator: ",")),
                "lineages="
                    + (family.lineageIDs.isEmpty
                        ? "none"
                        : family.lineageIDs.map(\.rawValue).joined(separator: ",")),
                "houses="
                    + (family.houseMemberships.isEmpty
                        ? "none"
                        : family.houseMemberships.map {
                            "\($0.houseID.rawValue):\($0.basis.rawValue)"
                        }.joined(separator: ",")),
            ]
            lines += family.relations.prefix(12).map {
                "  \($0.kind.rawValue):\($0.relatedPersonID.rawValue)"
                    + " source=\($0.source.rawValue)"
                    + " causal=\($0.sourceEventID.rawValue)"
            }
            if family.relationsTruncated {
                lines.append("[TRUNCATED] bounded family relation projection")
            }
            lines.append(
                "[SEPARATE AUTHORITIES] household, guardian, caregiver and ownership unchanged"
            )
        }
        if let childhood = individual.childhood {
            lines += [
                "[CHILDHOOD / GUARDIANSHIP — READ ONLY]",
                "age=\(childhood.ageTicks)"
                    + " stage=\(childhood.lifeStage.rawValue)"
                    + " dependency=\(childhood.dependencyStatus)"
                    + " readiness=\(childhood.autonomyReadinessBasisPoints)",
                "position=\(observerPosition(childhood.currentPhysicalLocation))"
                    + " home=\(observerPosition(childhood.homePosition))",
                "guardian=\(childhood.guardianID?.rawValue ?? "none")"
                    + " basis=\(childhood.guardianshipBasis?.rawValue ?? "none")"
                    + " status=\(childhood.guardianshipStatus?.rawValue ?? "none")"
                    + " atRisk=\(childhood.atRisk ? "YES" : "no")",
                "caregiver=\(childhood.currentCaregiverID?.rawValue ?? "none")"
                    + " engagement=\(childhood.currentCareEngagement?.rawValue ?? "none")"
                    + " verified=\(childhood.currentCareEngagedTicks.map(String.init) ?? "none")",
                "needs="
                    + (childhood.activeNeeds.isEmpty
                        ? "none"
                        : childhood.activeNeeds.map {
                            "\($0.kind.rawValue):\($0.severity):"
                                + "\($0.status.rawValue)"
                        }
                            .joined(separator: ","))
                    + " outcome=\(childhood.latestCareOutcome?.rawValue ?? "none")",
                "allowed="
                    + childhood.allowedCapabilities.map(\.rawValue)
                        .joined(separator: ","),
                "refused="
                    + childhood.refusedCapabilities.map(\.rawValue)
                        .joined(separator: ","),
                "[SOCIAL DEVELOPMENT — CAUSAL EXPOSURE]"
                    + " trajectory=\(childhood.socialTrajectory)",
            ]
            lines += childhood.socialDevelopment.map {
                "  \($0.dimension.rawValue)=\($0.basisPoints)"
                    + " changed@\(String($0.lastChangedTick))"
                    + " causal=\($0.lastEventID.rawValue)"
            }
            if !childhood.recentExposureEventIDs.isEmpty {
                lines.append(
                    "sources="
                        + childhood.recentExposureEventIDs.map(\.rawValue)
                            .joined(separator: ",")
                )
            }
        }
        if let genetics = individual.genetics {
            lines += [
                "[GENOTYPE — IMMUTABLE INHERITED POTENTIAL]",
                "id=\(genetics.genotypeID.rawValue)"
                    + " origin=\(genetics.origin.rawValue)"
                    + " model=v\(genetics.modelVersion)",
                "contributors="
                    + genetics.contributorIDs.map(\.rawValue)
                        .joined(separator: ",")
                    + " causal=\(genetics.creationEventID.rawValue)",
            ]
            lines += genetics.loci.map { locus in
                let alleles = locus.contributions.map {
                    "\($0.contributorID.rawValue):\($0.allele.rawValue)"
                }.joined(separator: "+")
                return "  \(locus.locus.rawValue)=\(alleles)"
                    + " potential=\(locus.potentialBasisPoints)"
            }
            lines += [
                "[DEVELOPMENT — LIFE-COURSE EXPRESSION]",
                "age=\(genetics.development.ageTicks)"
                    + " stage=\(genetics.development.lifeStage.rawValue)"
                    + " active=\(genetics.development.active ? "yes" : "no")",
                "maturity=\(genetics.development.expressionMaturityBasisPoints)"
                    + " exposure=\(genetics.development.physiologicalExposureBasisPoints)"
                    + " reserve=\(genetics.development.developmentalReserveBasisPoints)"
                    + " trajectory=\(genetics.development.trajectory.rawValue)",
                "[PHENOTYPE — CURRENT EXPRESSED PHYSIOLOGY]",
            ]
            lines += genetics.phenotype.map {
                "  \($0.traitID.rawValue)"
                    + " potential=\($0.geneticPotentialBasisPoints)"
                    + " development=\($0.developmentalFactorBasisPoints)"
                    + " expressed=\($0.expressedModifierBasisPoints)"
                    + " bounds=\($0.lowerBoundBasisPoints)...\($0.upperBoundBasisPoints)"
            }
            lines.append(
                "[SEPARATE SYSTEMS] health below; skill/status remain social"
            )
        }
        if let physiology = individual.physiology {
            let factorText = physiology.activeFactors.map {
                "\($0.code.rawValue):\($0.severityBasisPoints)"
            }.joined(separator: ",")
            lines += [
                "[HOMEOSTASIS / HEALTH]",
                "vital=\(physiology.vitalStatus.rawValue)"
                    + " condition=\(physiology.condition.rawValue)"
                    + " trend=\(physiology.trend.rawValue)",
                "age=\(physiology.ageTicks)"
                    + " stage=\(physiology.lifeStage.rawValue)"
                    + " band=\(physiology.ageBand.rawValue)"
                    + " vulnerability=\(physiology.ageVulnerabilityBasisPoints)",
                "health=\(physiology.healthReserve)"
                    + " energy=\(physiology.energyReserveBasisPoints)"
                    + " stress=\(physiology.stressBasisPoints)"
                    + " recovery=\(physiology.recoveryCapacityBasisPoints)",
                "factors=\(factorText.isEmpty ? "none" : factorText)",
                "limitation=\(physiology.limitation ?? "none")"
                    + " causal=\(physiology.lastCausalEventID.rawValue)",
            ]
        }
        if individual.relations.isEmpty {
            lines.append("[SOCIAL] relations=unknown-or-none")
        } else {
            lines.append("[SOCIAL] relations")
            lines += individual.relations.prefix(3).map {
                "  \($0.kind.rawValue):\($0.otherAgentID.rawValue) \($0.presentation)"
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
        if let death = snapshot.recentDeaths.first {
            lines.append(
                "[MORTALITY] latest=\(death.agentID.rawValue)"
                    + " cause=\(death.cause.rawValue)"
                    + " tick=\(death.deathTick)"
                    + " claimsPreserved=\(death.preservedMaterialClaims.count)"
            )
        }
        if let estate = snapshot.estateAuthority?.estates.last {
            lines += [
                "[ESTATE / SUCCESSION — AUTHORITATIVE, READ ONLY]",
                "estate=\(estate.estateID.rawValue)"
                    + " decedent=\(estate.decedentID.rawValue)"
                    + " status=\(estate.status.rawValue)",
                "administrator=\(estate.administratorID?.rawValue ?? "none")"
                    + " adminStatus=\(estate.administratorStatus?.rawValue ?? "none")"
                    + " tier=\(estate.beneficiaryTier.rawValue)",
                "assets=\(estate.totalAssetCount)"
                    + " settled=\(estate.settledAssetCount)"
                    + " pending=\(estate.pendingAssetCount)"
                    + " blocked=\(estate.blockedAssetCount)",
                "beneficiaries="
                    + (estate.beneficiaries.isEmpty
                        ? "none"
                        : estate.beneficiaries.map {
                            "\($0.agentID.rawValue):\($0.basis.rawValue)"
                        }.joined(separator: ",")),
            ]
            lines += estate.assets.prefix(4).map {
                "  \($0.entryID.rawValue)"
                    + " x\($0.quantity)"
                    + " holder=\($0.physicalHolder ?? "unresolved")"
                    + " owner=\($0.currentOwnerID?.rawValue ?? "none")"
                    + " custodian=\($0.currentCustodianID?.rawValue ?? "none")"
                    + " beneficiary=\($0.beneficiaryID?.rawValue ?? "none")"
                    + " custodian=\($0.intendedCustodianID?.rawValue ?? "none")"
                    + " status=\($0.status.rawValue)"
                    + " block=\($0.blockReason?.rawValue ?? "none")"
            }
        }
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
        if event.directCausesOmitted > 0 {
            lines.append(
                "[TRUNCATED] \(event.directCausesOmitted)"
                    + " direct causal parent reference(s) omitted by Observer bound"
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
