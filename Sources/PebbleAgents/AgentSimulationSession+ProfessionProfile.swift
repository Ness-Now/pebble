extension AgentSimulationSession {
    public func professionProfile(for agentID: AgentID) -> AgentProfessionProfile? {
        guard let state = workCommitmentState,
              lifecycleState?.members.contains(where: { $0.agentID == agentID }) == true else {
            return nil
        }
        let histories = state.domainHistories.filter { $0.workerID == agentID }
        let evidence = state.retainedEvidence.filter { $0.workerID == agentID }
        let recentStart = max(0, tick - state.configuration.recentHistoryWindowTicks + 1)
        let recentEvidence = evidence.filter { $0.recordedAtTick >= recentStart }
        let domains = Set(
            histories.map(\.domain) + evidence.map(\.domain)
                + (skillProfile(for: agentID)?.domainPractices.map(\.domain) ?? [])
        ).sorted()
        guard !domains.isEmpty else { return nil }

        let recentUnits = Dictionary(uniqueKeysWithValues: domains.map { domain in
            (domain, workProfileUnits(recentEvidence.filter { $0.domain == domain }))
        })
        let lifetimeUnits = Dictionary(uniqueKeysWithValues: domains.map { domain in
            let history = histories.first { $0.domain == domain }
            let outcomeUnits = (history?.successCount ?? 0) * 4
                + (history?.failureCount ?? 0) * 2
                + (history?.blockedCount ?? 0)
                + (history?.interruptionCount ?? 0)
            return (domain, outcomeUnits + (history?.completedCommitmentCount ?? 0) * 2)
        })
        let profileUnits = Dictionary(uniqueKeysWithValues: domains.map { domain in
            (domain, (recentUnits[domain] ?? 0) * 3 + (lifetimeUnits[domain] ?? 0))
        })
        let recentShares = workBasisPointShares(recentUnits)
        let lifetimeShares = workBasisPointShares(lifetimeUnits)
        let profileShares = workBasisPointShares(profileUnits)
        let ordered = domains.sorted { lhs, rhs in
            let l = profileShares[lhs] ?? 0
            let r = profileShares[rhs] ?? 0
            return l == r ? lhs < rhs : l > r
        }
        let primary = ordered.first.flatMap { (profileUnits[$0] ?? 0) > 0 ? $0 : nil }
        let secondary = ordered.filter { $0 != primary && (profileUnits[$0] ?? 0) > 0 }
        let activities = domains.map { domain in
            let history = histories.first { $0.domain == domain }
            let apprenticeshipCount = workApprenticeshipEvidenceCount(
                agentID: agentID, domain: domain
            )
            return AgentProfessionDomainActivity(
                domain: domain,
                recentWorkUnits: recentUnits[domain] ?? 0,
                lifetimeWorkUnits: lifetimeUnits[domain] ?? 0,
                recentShareBasisPoints: recentShares[domain] ?? 0,
                lifetimeShareBasisPoints: lifetimeShares[domain] ?? 0,
                profileShareBasisPoints: profileShares[domain] ?? 0,
                skillPracticeUnits: practiceUnits(agentID: agentID, domain: domain),
                apprenticeshipEvidenceCount: apprenticeshipCount,
                successfulOutcomeCount: history?.successCount ?? 0,
                failedOutcomeCount: history?.failureCount ?? 0,
                blockedOutcomeCount: history?.blockedCount ?? 0,
                interruptedOutcomeCount: history?.interruptionCount ?? 0,
                completedCommitmentCount: history?.completedCommitmentCount ?? 0,
                lastWorkTick: history?.lastWorkTick ?? 0
            )
        }
        let active = state.commitments.filter {
            $0.workerID == agentID && $0.status.isOpen
        }.count
        let continuity = histories.reduce(0) { $0 + $1.completedCommitmentCount }
        let skillEvidence = domains.reduce(0) {
            $0 + practiceUnits(agentID: agentID, domain: $1)
        }
        let apprenticeshipEvidence = domains.reduce(0) {
            $0 + workApprenticeshipEvidenceCount(agentID: agentID, domain: $1)
        }
        let reliability = state.localReputations.filter { $0.workerID == agentID }.reduce(0) {
            $0 + $1.successCount + $1.failureCount + $1.blockedCount + $1.interruptionCount
        }
        let recentConcentration = workConcentration(recentShares)
        let lifetimeConcentration = workConcentration(lifetimeShares)
        let blendedConcentration = workConcentration(profileShares)
        let descriptor = primary.map(workDisplayDescriptor)
        let activityText = activities.map {
            "\($0.domain.rawValue):\($0.recentWorkUnits):\($0.lifetimeWorkUnits):"
                + "\($0.profileShareBasisPoints):\($0.skillPracticeUnits):"
                + "\($0.completedCommitmentCount):\($0.lastWorkTick)"
        }.joined(separator: ";")
        let digest = AgentWorkDigest.make(
            "profile|\(agentID.rawValue)|\(tick)|\(activityText)|\(active)|"
                + "\(continuity)|\(skillEvidence)|\(apprenticeshipEvidence)|"
                + "\(reliability)|\(recentConcentration)|\(lifetimeConcentration)|"
                + "\(blendedConcentration)"
        )
        return AgentProfessionProfile(
            agentID: agentID, primaryWorkDomain: primary,
            secondaryDomains: secondary, domainActivity: activities,
            activeCommitmentCount: active, commitmentContinuity: continuity,
            skillEvidenceUnits: skillEvidence,
            apprenticeshipEvidenceCount: apprenticeshipEvidence,
            reliabilityEvidenceCount: reliability,
            recentSpecializationBasisPoints: recentConcentration,
            lifetimeSpecializationBasisPoints: lifetimeConcentration,
            specializationStrengthBasisPoints: blendedConcentration,
            displayDescriptor: descriptor, lastRecomputedTick: tick, digest: digest
        )
    }

    public func professionProfiles() -> [AgentProfessionProfile] {
        guard workCommitmentState != nil else { return [] }
        return (lifecycleState?.members.map(\.agentID).sorted() ?? []).compactMap {
            professionProfile(for: $0)
        }
    }

    public func specializationMetrics() -> [AgentSpecializationMetric] {
        professionProfiles().map {
            AgentSpecializationMetric(
                agentID: $0.agentID, primaryDomain: $0.primaryWorkDomain,
                recentConcentrationBasisPoints: $0.recentSpecializationBasisPoints,
                lifetimeConcentrationBasisPoints: $0.lifetimeSpecializationBasisPoints,
                blendedConcentrationBasisPoints: $0.specializationStrengthBasisPoints,
                domainCoverage: $0.domainActivity.filter { $0.lifetimeWorkUnits > 0 }.count
            )
        }
    }

    public func workDependencyMetrics() -> [AgentWorkDependencyMetric] {
        guard let state = workCommitmentState else { return [] }
        let demandedDomains = Set(state.demands.filter {
            $0.status.isActive && $0.expiresAtTick >= tick
        }.map(\.domain)).sorted()
        let capable = lifecycleState?.members.filter { member in
            member.currentStage == .mature
                && populationRegistry?.members.first(where: {
                    $0.agentID == member.agentID
                })?.status != .migrating
                && (statesById[member.agentID.rawValue]?.health ?? 0) > 0
        }.map(\.agentID).sorted() ?? []
        let recentStart = max(0, tick - state.configuration.recentHistoryWindowTicks + 1)
        return demandedDomains.map { domain in
            let demands = state.demands.filter {
                $0.domain == domain && $0.status.isActive && $0.expiresAtTick >= tick
            }
            let committed = Set(state.commitments.filter {
                $0.domain == domain && $0.status.isOpen
            }.map(\.workerID)).sorted()
            let recent = state.retainedEvidence.filter {
                $0.domain == domain && $0.status == .succeeded
                    && $0.recordedAtTick >= recentStart
            }
            let byWorker = Dictionary(grouping: recent, by: \.workerID).mapValues {
                $0.reduce(0) { $0 + $1.quantity }
            }
            let total = byWorker.values.reduce(0, +)
            let topShare = total == 0 ? 0 : (byWorker.values.max()! * 10_000) / total
            return AgentWorkDependencyMetric(
                domain: domain, activeDemandCount: demands.count,
                committedWorkerIDs: committed, knownCapableWorkerCount: capable.count,
                replacementDepth: max(0, capable.count - committed.count),
                recentTopWorkerShareBasisPoints: topShare,
                singleWorkerDependency: committed.count == 1
                    || (total > 0 && byWorker.count == 1)
            )
        }
    }

    public func workCoordinationMetrics() -> AgentWorkCoordinationMetrics {
        guard let state = workCommitmentState else {
            return AgentWorkCoordinationMetrics(
                activeDemandCount: 0, activeCommitmentCount: 0,
                suspendedCommitmentCount: 0, fulfilledCommitmentCount: 0,
                reassignmentCount: 0, coveredDemandCount: 0, uncoveredDemandCount: 0
            )
        }
        let activeDemands = state.demands.filter {
            $0.status.isActive && $0.expiresAtTick >= tick
        }
        let covered = activeDemands.filter { demand in
            state.commitments.contains {
                $0.demandID == demand.demandID && $0.status.isOpen
            }
        }.count
        return AgentWorkCoordinationMetrics(
            activeDemandCount: activeDemands.count,
            activeCommitmentCount: state.commitments.filter { $0.status == .active }.count,
            suspendedCommitmentCount: state.commitments.filter { $0.status == .suspended }.count,
            fulfilledCommitmentCount: state.commitments.filter { $0.status == .fulfilled }.count,
            reassignmentCount: state.totalReassignmentCount,
            coveredDemandCount: covered, uncoveredDemandCount: activeDemands.count - covered
        )
    }

    private func workProfileUnits(_ evidence: [AgentWorkEvidence]) -> Int {
        evidence.reduce(0) { total, item in
            let weight: Int
            switch item.status {
            case .succeeded: weight = 4
            case .failed: weight = 2
            case .blocked, .interrupted: weight = 1
            }
            return total + item.quantity * weight
        }
    }

    private func workBasisPointShares(
        _ units: [AgentSkillDomain: Int]
    ) -> [AgentSkillDomain: Int] {
        let positive = units.filter { $0.value > 0 }
        let total = positive.values.reduce(0, +)
        guard total > 0 else { return [:] }
        var shares = Dictionary(uniqueKeysWithValues: positive.map {
            ($0.key, ($0.value * 10_000) / total)
        })
        var remaining = 10_000 - shares.values.reduce(0, +)
        let order = positive.keys.sorted { lhs, rhs in
            let l = (positive[lhs]! * 10_000) % total
            let r = (positive[rhs]! * 10_000) % total
            return l == r ? lhs < rhs : l > r
        }
        var index = 0
        while remaining > 0 {
            shares[order[index % order.count], default: 0] += 1
            remaining -= 1
            index += 1
        }
        return shares
    }

    private func workConcentration(_ shares: [AgentSkillDomain: Int]) -> Int {
        guard !shares.isEmpty else { return 0 }
        return shares.values.reduce(0) { $0 + ($1 * $1) / 10_000 }
    }

    private func workApprenticeshipEvidenceCount(
        agentID: AgentID,
        domain: AgentSkillDomain
    ) -> Int {
        guard let teaching = teachingState else { return 0 }
        return teaching.apprenticeships.filter {
            $0.domain == domain && ($0.teacherID == agentID || $0.studentID == agentID)
        }.count
    }

    private func workDisplayDescriptor(_ domain: AgentSkillDomain) -> String {
        switch domain {
        case .foraging: return "forager"
        case .materialHandling: return "material handler"
        case .construction: return "builder"
        case .caregiving: return "caregiver"
        case .cultivation: return "cultivator"
        case .fishing: return "fisher"
        case .hunting: return "hunter"
        case .husbandry: return "herder"
        }
    }
}
