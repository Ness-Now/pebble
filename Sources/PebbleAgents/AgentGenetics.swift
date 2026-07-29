public enum AgentGeneticLocus: String, Codable, CaseIterable, Comparable, Sendable {
    case homeostaticResilience
    case recoveryEfficiency
    case deprivationTolerance
    case expressionTempo

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum AgentGeneticAllele: String, Codable, CaseIterable, Sendable {
    case reduced
    case reference
    case enhanced

    public var contributionBasisPoints: Int {
        switch self {
        case .reduced: return -400
        case .reference: return 0
        case .enhanced: return 400
        }
    }
}

public enum AgentGenotypeOrigin: String, Codable, CaseIterable, Sendable {
    case founder
    case inherited
}

public struct AgentGenotypeID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...160).contains(rawValue.count),
              rawValue.allSatisfy({
                  $0.isASCII && ($0.isLetter || $0.isNumber || "-_.".contains($0))
              }) else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct AgentGeneticContribution: Codable, Equatable, Sendable {
    public let allele: AgentGeneticAllele
    public let contributorID: AgentID
    public let sourceGenotypeID: AgentGenotypeID?
    public let sourceAlleleIndex: Int
}

public struct AgentGeneticLocusRecord: Codable, Equatable, Sendable {
    public let locus: AgentGeneticLocus
    public let contributions: [AgentGeneticContribution]

    public var potentialBasisPoints: Int {
        contributions.reduce(0) {
            $0 + $1.allele.contributionBasisPoints
        }
    }
}

public struct AgentGenotypeRecord: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let genotypeID: AgentGenotypeID
    public let agentID: AgentID
    public let origin: AgentGenotypeOrigin
    public let contributorIDs: [AgentID]
    public let loci: [AgentGeneticLocusRecord]
    public let createdAtTick: Int
    public let birthID: AgentBirthID?
    public let creationEventID: AgentCausalEventID
    public let immutableDigest: String
}

public enum AgentDevelopmentTrajectory: String, Codable, CaseIterable, Sendable {
    case protected
    case stable
    case strained
}

public struct AgentDevelopmentRecord: Codable, Equatable, Sendable {
    public let agentID: AgentID
    public internal(set) var active: Bool
    public internal(set) var ageTicks: Int
    public internal(set) var lifeStage: AgentLifeStage
    public internal(set) var expressionMaturityBasisPoints: Int
    public internal(set) var physiologicalExposureBasisPoints: Int
    public internal(set) var developmentalReserveBasisPoints: Int
    public internal(set) var trajectory: AgentDevelopmentTrajectory
    public internal(set) var lastUpdatedTick: Int
    public internal(set) var lastSignificantChangeTick: Int
    public internal(set) var lastSignificantMaturityBasisPoints: Int
    public internal(set) var updateCount: Int
    public internal(set) var stoppedAtTick: Int?
    public internal(set) var lastEventID: AgentCausalEventID
}

public enum AgentPhenotypeTraitID: String, Codable, CaseIterable, Comparable, Sendable {
    case deprivationTolerance
    case expressionTempo
    case homeostaticResilience
    case recoveryEfficiency

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var locus: AgentGeneticLocus {
        switch self {
        case .homeostaticResilience: return .homeostaticResilience
        case .recoveryEfficiency: return .recoveryEfficiency
        case .deprivationTolerance: return .deprivationTolerance
        case .expressionTempo: return .expressionTempo
        }
    }
}

public struct AgentPhenotypeTrait: Codable, Equatable, Sendable {
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

public struct AgentPhenotypeRecord: Codable, Equatable, Sendable {
    public let agentID: AgentID
    public internal(set) var traits: [AgentPhenotypeTrait]
    public internal(set) var lastUpdatedTick: Int
}

public enum AgentGeneticsTransitionKind: String, Codable, CaseIterable, Sendable {
    case enabled
    case founderAssigned
    case inherited
    case developmentChanged
    case phenotypeChanged
    case developmentStopped
}

public struct AgentGeneticsTransition: Codable, Equatable, Sendable {
    public let kind: AgentGeneticsTransitionKind
    public let agentID: AgentID?
    public let tick: Int
    public let detail: String
    public let eventID: AgentCausalEventID
}

public struct AgentGeneticsConfiguration: Codable, Equatable, Sendable {
    public let modelVersion: Int
    public let maximumProfiles: Int
    public let maximumRetainedTransitions: Int
    public let significantChangeBasisPoints: Int
    public let maximumExpressedModifierBasisPoints: Int

    public init(
        modelVersion: Int = 1,
        maximumProfiles: Int = 512,
        maximumRetainedTransitions: Int = 512,
        significantChangeBasisPoints: Int = 250,
        maximumExpressedModifierBasisPoints: Int = 800
    ) throws {
        guard modelVersion == 1 else {
            throw AgentGeneticsError.invalidConfiguration("model version")
        }
        guard (1...512).contains(maximumProfiles) else {
            throw AgentGeneticsError.invalidConfiguration("profiles")
        }
        guard (1...2_048).contains(maximumRetainedTransitions) else {
            throw AgentGeneticsError.invalidConfiguration("transitions")
        }
        guard (1...1_000).contains(significantChangeBasisPoints) else {
            throw AgentGeneticsError.invalidConfiguration("significance")
        }
        guard (100...1_000).contains(maximumExpressedModifierBasisPoints) else {
            throw AgentGeneticsError.invalidConfiguration("modifier bound")
        }
        self.modelVersion = modelVersion
        self.maximumProfiles = maximumProfiles
        self.maximumRetainedTransitions = maximumRetainedTransitions
        self.significantChangeBasisPoints = significantChangeBasisPoints
        self.maximumExpressedModifierBasisPoints =
            maximumExpressedModifierBasisPoints
    }

    public static let live = try! AgentGeneticsConfiguration()
}

public enum AgentGeneticsError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration(String)
    case causalLedgerRequired
    case lifecycleRequired
    case homeostasisRequired
    case populationRequired
    case alreadyEnabled
    case disabled
    case unsafeDisable
    case profileLimitReached
    case unknownAgent(AgentID)
    case missingParentGenotype(AgentID)
    case invalidState(String)

    public var description: String {
        switch self {
        case let .invalidConfiguration(value):
            return "invalid genetics configuration: \(value)"
        case .causalLedgerRequired: return "genetics requires the causal ledger"
        case .lifecycleRequired: return "genetics requires lifecycle"
        case .homeostasisRequired: return "genetics requires homeostasis"
        case .populationRequired: return "genetics requires population"
        case .alreadyEnabled: return "genetics already enabled"
        case .disabled: return "genetics disabled"
        case .unsafeDisable: return "genetics disable refused after durable state"
        case .profileLimitReached: return "genetics profile limit reached"
        case let .unknownAgent(id): return "unknown genetics agent \(id.rawValue)"
        case let .missingParentGenotype(id):
            return "missing genetic contributor \(id.rawValue)"
        case let .invalidState(reason): return "invalid genetics state: \(reason)"
        }
    }
}

public struct AgentGeneticsState: Codable, Equatable, Sendable {
    public let configuration: AgentGeneticsConfiguration
    public internal(set) var genotypes: [AgentGenotypeRecord]
    public internal(set) var development: [AgentDevelopmentRecord]
    public internal(set) var phenotypes: [AgentPhenotypeRecord]
    public internal(set) var recentTransitions: [AgentGeneticsTransition]
    public internal(set) var totalTransitionCount: Int
    public internal(set) var transitionEvictionCount: Int
    public let initializedEventID: AgentCausalEventID
    public internal(set) var lastEventID: AgentCausalEventID
}

public struct AgentGeneticsSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let tick: Int
    public let configuration: AgentGeneticsConfiguration?
    public let genotypes: [AgentGenotypeRecord]
    public let development: [AgentDevelopmentRecord]
    public let phenotypes: [AgentPhenotypeRecord]
    public let recentTransitions: [AgentGeneticsTransition]
    public let totalTransitionCount: Int
    public let transitionEvictionCount: Int
    public let digest: String
}

extension AgentSimulationSession {
    public var geneticsEnabled: Bool { geneticsState != nil }

    public func geneticsSnapshot() -> AgentGeneticsSnapshot {
        guard let state = geneticsState else {
            return AgentGeneticsSnapshot(
                enabled: false, tick: tick, configuration: nil, genotypes: [],
                development: [], phenotypes: [], recentTransitions: [],
                totalTransitionCount: 0, transitionEvictionCount: 0,
                digest: AgentGeneticsDigest.make("disabled|\(tick)")
            )
        }
        let genotypes = state.genotypes.sorted { $0.agentID < $1.agentID }
        let development = state.development.sorted { $0.agentID < $1.agentID }
        let phenotypes = state.phenotypes.sorted { $0.agentID < $1.agentID }
        let transitions = state.recentTransitions.sorted {
            if $0.tick != $1.tick { return $0.tick < $1.tick }
            return $0.eventID < $1.eventID
        }
        let genotypeText = genotypes.map { genotype -> String in
            genotype.agentID.rawValue + ":" + genotype.immutableDigest + ":"
                + genotype.creationEventID.rawValue
        }.joined(separator: ";")
        let developmentText = development.map { value -> String in
            [
                value.agentID.rawValue, String(value.active),
                String(value.ageTicks), value.lifeStage.rawValue,
                String(value.expressionMaturityBasisPoints),
                String(value.physiologicalExposureBasisPoints),
                String(value.developmentalReserveBasisPoints),
                value.trajectory.rawValue, String(value.lastUpdatedTick),
                String(value.updateCount), String(value.stoppedAtTick ?? -1),
                value.lastEventID.rawValue,
            ].joined(separator: ":")
        }.joined(separator: ";")
        let phenotypeText = phenotypes.map { phenotype -> String in
                let traits = phenotype.traits.map { trait -> String in
                    let eventIDText = trait.lastEventID.rawValue
                    return "\(trait.traitID.rawValue):"
                        + "\(trait.expressedModifierBasisPoints):"
                        + "\(trait.lastSignificantChangeTick):\(eventIDText)"
                }.joined(separator: ",")
                let agentText = phenotype.agentID.rawValue
                return agentText + ":" + traits
        }.joined(separator: ";")
        let transitionText = transitions.map { transition -> String in
                let eventIDText = transition.eventID.rawValue
                let kindText = transition.kind.rawValue
                let agentText = transition.agentID?.rawValue ?? "-"
                return "\(eventIDText):\(kindText):\(agentText):"
                    + transition.detail
        }.joined(separator: ";")
        let canonical = [
            "v=\(state.configuration.modelVersion)",
            "tick=\(tick)",
            genotypeText,
            developmentText,
            phenotypeText,
            transitionText,
            "total=\(state.totalTransitionCount)",
            "evicted=\(state.transitionEvictionCount)",
            "last=\(state.lastEventID.rawValue)",
        ].joined(separator: "|")
        return AgentGeneticsSnapshot(
            enabled: true, tick: tick, configuration: state.configuration,
            genotypes: genotypes, development: development,
            phenotypes: phenotypes, recentTransitions: transitions,
            totalTransitionCount: state.totalTransitionCount,
            transitionEvictionCount: state.transitionEvictionCount,
            digest: AgentGeneticsDigest.make(canonical)
        )
    }

    public func genotype(for agentID: AgentID) -> AgentGenotypeRecord? {
        geneticsState?.genotypes.first { $0.agentID == agentID }
    }

    public func development(for agentID: AgentID) -> AgentDevelopmentRecord? {
        geneticsState?.development.first { $0.agentID == agentID }
    }

    public func phenotype(for agentID: AgentID) -> AgentPhenotypeRecord? {
        geneticsState?.phenotypes.first { $0.agentID == agentID }
    }

    public func phenotypeModifier(
        _ traitID: AgentPhenotypeTraitID,
        for agentID: AgentID
    ) -> Int {
        phenotype(for: agentID)?.traits.first {
            $0.traitID == traitID
        }?.expressedModifierBasisPoints ?? 0
    }

    public mutating func setGeneticsEnabled(
        _ enabled: Bool,
        configuration: AgentGeneticsConfiguration = .live
    ) throws {
        var candidate = self
        try candidate.setGeneticsEnabledInPlace(enabled, configuration: configuration)
        self = candidate
    }

    private mutating func setGeneticsEnabledInPlace(
        _ enabled: Bool,
        configuration: AgentGeneticsConfiguration
    ) throws {
        if !enabled {
            guard geneticsState != nil else {
                throw AgentSessionError.genetics(.disabled)
            }
            throw AgentSessionError.genetics(.unsafeDisable)
        }
        guard geneticsState == nil else {
            throw AgentSessionError.genetics(.alreadyEnabled)
        }
        guard causalLedger.isEnabled else {
            throw AgentSessionError.genetics(.causalLedgerRequired)
        }
        guard lifecycleState != nil else {
            throw AgentSessionError.genetics(.lifecycleRequired)
        }
        guard homeostasisState != nil else {
            throw AgentSessionError.genetics(.homeostasisRequired)
        }
        guard populationRegistry != nil else {
            throw AgentSessionError.genetics(.populationRequired)
        }
        _ = try AgentGeneticsConfiguration(
            modelVersion: configuration.modelVersion,
            maximumProfiles: configuration.maximumProfiles,
            maximumRetainedTransitions: configuration.maximumRetainedTransitions,
            significantChangeBasisPoints: configuration.significantChangeBasisPoints,
            maximumExpressedModifierBasisPoints:
                configuration.maximumExpressedModifierBasisPoints
        )
        let agentIDs = statesById.values.map(\.agentID).sorted()
        guard agentIDs.count <= configuration.maximumProfiles else {
            throw AgentSessionError.genetics(.profileLimitReached)
        }
        try prevalidateCausalAppend(count: agentIDs.count + 1)
        guard let initialized = try recordCausalEvent(
            kind: .geneticsInitialized,
            origin: .geneticsTransition,
            payload: .operation(
                status: "initialized",
                detail: "model=v\(configuration.modelVersion) founders=\(agentIDs.count)"
            ),
            summary: "genetics initialized founders=\(agentIDs.count)"
        ) else {
            throw AgentSessionError.genetics(.causalLedgerRequired)
        }
        geneticsState = AgentGeneticsState(
            configuration: configuration, genotypes: [], development: [],
            phenotypes: [], recentTransitions: [
                AgentGeneticsTransition(
                    kind: .enabled, agentID: nil, tick: tick,
                    detail: "model=v\(configuration.modelVersion)",
                    eventID: initialized.eventID
                )
            ],
            totalTransitionCount: 1, transitionEvictionCount: 0,
            initializedEventID: initialized.eventID,
            lastEventID: initialized.eventID
        )
        for agentID in agentIDs {
            try assignFounderGenotype(
                to: agentID, causeEventID: initialized.eventID
            )
        }
        trimGeneticsTransitions()
        try validateGeneticsCrossDomainIfEnabled()
    }

    mutating func assignFounderGenotype(
        to agentID: AgentID,
        causeEventID: AgentCausalEventID
    ) throws {
        guard var genetics = geneticsState else {
            throw AgentSessionError.genetics(.disabled)
        }
        guard statesById[agentID.rawValue] != nil else {
            throw AgentSessionError.genetics(.unknownAgent(agentID))
        }
        guard genetics.genotypes.allSatisfy({ $0.agentID != agentID }) else {
            throw AgentSessionError.genetics(.invalidState(
                "duplicate founder assignment \(agentID.rawValue)"
            ))
        }
        let loci = AgentGeneticLocus.allCases.sorted().map { locus in
            AgentGeneticLocusRecord(
                locus: locus,
                contributions: (0..<2).map { copy in
                    AgentGeneticContribution(
                        allele: deterministicAllele(
                            domain: "founder", agentID: agentID,
                            locus: locus, copy: copy,
                            modelVersion: genetics.configuration.modelVersion
                        ),
                        contributorID: agentID,
                        sourceGenotypeID: nil,
                        sourceAlleleIndex: copy
                    )
                }
            )
        }
        let genotypeID = makeGenotypeID(
            agentID, modelVersion: genetics.configuration.modelVersion
        )
        let immutable = genotypeDigest(
            id: genotypeID, agentID: agentID, origin: .founder,
            contributors: [agentID], loci: loci, birthID: nil
        )
        guard let event = try recordCausalEvent(
            kind: .founderGenotypeAssigned,
            origin: .geneticsTransition,
            actorID: agentID,
            subjectID: agentID,
            causes: [causeEventID],
            payload: .operation(
                status: "founderAssigned",
                detail: "genotype=\(genotypeID.rawValue) digest=\(immutable)"
            ),
            summary: "founder genotype assigned agent=\(agentID.rawValue)"
        ) else {
            throw AgentSessionError.genetics(.causalLedgerRequired)
        }
        let record = AgentGenotypeRecord(
            schemaVersion: genetics.configuration.modelVersion,
            genotypeID: genotypeID, agentID: agentID, origin: .founder,
            contributorIDs: [agentID], loci: loci, createdAtTick: tick,
            birthID: nil, creationEventID: event.eventID,
            immutableDigest: immutable
        )
        let age = try demographicAge(for: agentID)
        let stage = geneticLifeStage(age: age)
        let development = initialDevelopment(
            agentID: agentID, genotype: record, age: age, stage: stage,
            eventID: event.eventID
        )
        let phenotype = derivePhenotype(
            genotype: record, development: development,
            previous: nil, eventID: event.eventID, at: tick,
            configuration: genetics.configuration
        )
        genetics.genotypes.append(record)
        genetics.development.append(development)
        genetics.phenotypes.append(phenotype)
        genetics.recentTransitions.append(AgentGeneticsTransition(
            kind: .founderAssigned, agentID: agentID, tick: tick,
            detail: "genotype=\(genotypeID.rawValue)", eventID: event.eventID
        ))
        genetics.totalTransitionCount += 1
        genetics.lastEventID = event.eventID
        sortGeneticsState(&genetics)
        geneticsState = genetics
    }

    mutating func registerImportedGenotypeIfEnabled(
        for agentID: AgentID,
        causeEventID: AgentCausalEventID
    ) throws {
        guard let genetics = geneticsState else { return }
        guard genetics.genotypes.allSatisfy({ $0.agentID != agentID }) else {
            throw AgentSessionError.genetics(.invalidState(
                "duplicate imported genotype \(agentID.rawValue)"
            ))
        }
        guard genetics.genotypes.count
                < genetics.configuration.maximumProfiles else {
            throw AgentSessionError.genetics(.profileLimitReached)
        }
        try prevalidateCausalAppend(count: 1)
        try assignFounderGenotype(
            to: agentID,
            causeEventID: causeEventID
        )
    }

    func inheritedGenotypePreview(
        childID: AgentID,
        birthID: AgentBirthID,
        contributorIDs: [AgentID]
    ) throws -> (
        AgentGenotypeRecord, AgentDevelopmentRecord, AgentPhenotypeRecord
    )? {
        guard let genetics = geneticsState else { return nil }
        guard contributorIDs.count == 2,
              contributorIDs == contributorIDs.sorted(),
              Set(contributorIDs).count == 2 else {
            throw AgentSessionError.genetics(.invalidState(
                "canonical genetic contributors"
            ))
        }
        let parents = try contributorIDs.map { contributorID in
            guard let record = genetics.genotypes.first(where: {
                $0.agentID == contributorID
            }) else {
                throw AgentSessionError.genetics(
                    .missingParentGenotype(contributorID)
                )
            }
            return record
        }
        let loci = AgentGeneticLocus.allCases.sorted().map { locus in
            let contributions = parents.map { parent in
                let parentLocus = parent.loci.first { $0.locus == locus }!
                let index = deterministicIndex(
                    domain: [
                        "inherit", simulationID.rawValue, birthID.rawValue,
                        childID.rawValue, parent.agentID.rawValue,
                        locus.rawValue,
                        "v\(genetics.configuration.modelVersion)",
                    ].joined(separator: "|"),
                    upperBound: 2
                )
                return AgentGeneticContribution(
                    allele: parentLocus.contributions[index].allele,
                    contributorID: parent.agentID,
                    sourceGenotypeID: parent.genotypeID,
                    sourceAlleleIndex: index
                )
            }.sorted {
                if $0.contributorID != $1.contributorID {
                    return $0.contributorID < $1.contributorID
                }
                return $0.sourceAlleleIndex < $1.sourceAlleleIndex
            }
            return AgentGeneticLocusRecord(
                locus: locus, contributions: contributions
            )
        }
        let genotypeID = makeGenotypeID(
            childID, modelVersion: genetics.configuration.modelVersion
        )
        let immutable = genotypeDigest(
            id: genotypeID, agentID: childID, origin: .inherited,
            contributors: contributorIDs, loci: loci, birthID: birthID
        )
        let provisionalEvent = genetics.lastEventID
        let genotype = AgentGenotypeRecord(
            schemaVersion: genetics.configuration.modelVersion,
            genotypeID: genotypeID, agentID: childID, origin: .inherited,
            contributorIDs: contributorIDs, loci: loci, createdAtTick: tick,
            birthID: birthID, creationEventID: provisionalEvent,
            immutableDigest: immutable
        )
        let development = initialDevelopment(
            agentID: childID, genotype: genotype, age: 0, stage: .newborn,
            eventID: provisionalEvent
        )
        let phenotype = derivePhenotype(
            genotype: genotype, development: development, previous: nil,
            eventID: provisionalEvent, at: tick,
            configuration: genetics.configuration
        )
        return (genotype, development, phenotype)
    }

    mutating func publishInheritedGenotype(
        preview: (
            AgentGenotypeRecord, AgentDevelopmentRecord, AgentPhenotypeRecord
        ),
        causeEventIDs: [AgentCausalEventID]
    ) throws -> AgentCausalEventID {
        guard var genetics = geneticsState else {
            throw AgentSessionError.genetics(.disabled)
        }
        let source = preview.0
        guard genetics.genotypes.count < genetics.configuration.maximumProfiles,
              genetics.genotypes.allSatisfy({ $0.agentID != source.agentID })
        else {
            throw AgentSessionError.genetics(.profileLimitReached)
        }
        let causes = Array(Set(
            causeEventIDs + source.contributorIDs.compactMap { id in
                genetics.genotypes.first(where: { $0.agentID == id })?
                    .creationEventID
            }
        )).sorted()
        guard let event = try recordCausalEvent(
            kind: .genotypeInherited,
            origin: .geneticsTransition,
            actorID: source.contributorIDs.first,
            subjectID: source.agentID,
            causes: causes,
            payload: .operation(
                status: "inherited",
                detail: "genotype=\(source.genotypeID.rawValue) contributors="
                    + source.contributorIDs.map(\.rawValue).joined(separator: ",")
            ),
            summary: "genotype inherited child=\(source.agentID.rawValue)"
        ) else {
            throw AgentSessionError.genetics(.causalLedgerRequired)
        }
        let genotype = replacingCreationEvent(source, with: event.eventID)
        let development = replacingDevelopmentEvent(preview.1, with: event.eventID)
        let phenotype = replacingPhenotypeEvent(preview.2, with: event.eventID)
        genetics.genotypes.append(genotype)
        genetics.development.append(development)
        genetics.phenotypes.append(phenotype)
        genetics.recentTransitions.append(AgentGeneticsTransition(
            kind: .inherited, agentID: source.agentID, tick: tick,
            detail: "genotype=\(source.genotypeID.rawValue)",
            eventID: event.eventID
        ))
        genetics.totalTransitionCount += 1
        genetics.lastEventID = event.eventID
        sortGeneticsState(&genetics)
        geneticsState = genetics
        trimGeneticsTransitions()
        return event.eventID
    }

    mutating func applyGeneticsDevelopmentBoundary(at boundaryTick: Int) throws {
        guard let source = geneticsState else { return }
        let agentIDs = statesById.values.map(\.agentID).sorted()
        struct Proposal {
            let agentID: AgentID
            let development: AgentDevelopmentRecord
            let phenotype: AgentPhenotypeRecord
            let developmentSignificant: Bool
            let phenotypeSignificant: Bool
            let causeIDs: [AgentCausalEventID]
        }
        var proposals: [Proposal] = []
        for agentID in agentIDs {
            guard let genotype = source.genotypes.first(where: {
                $0.agentID == agentID
            }),
            let priorDevelopment = source.development.first(where: {
                $0.agentID == agentID
            }),
            let priorPhenotype = source.phenotypes.first(where: {
                $0.agentID == agentID
            }) else {
                throw AgentSessionError.genetics(.invalidState(
                    "living agent without genetics \(agentID.rawValue)"
                ))
            }
            let age = try geneticDemographicAge(
                for: agentID, at: boundaryTick
            )
            let stage = geneticLifeStage(age: age)
            let updated = updatedDevelopment(
                priorDevelopment, genotype: genotype, age: age, stage: stage,
                homeostasis: homeostasisProfile(for: agentID),
                boundaryTick: boundaryTick
            )
            let phenotype = derivePhenotype(
                genotype: genotype, development: updated,
                previous: priorPhenotype,
                eventID: priorDevelopment.lastEventID,
                at: boundaryTick, configuration: source.configuration
            )
            let devSignificant = stage != priorDevelopment.lifeStage
                || updated.trajectory != priorDevelopment.trajectory
                || abs(
                    updated.expressionMaturityBasisPoints
                        - priorDevelopment.lastSignificantMaturityBasisPoints
                ) >= source.configuration.significantChangeBasisPoints
            let phenotypeDelta = zip(
                phenotype.traits, priorPhenotype.traits
            ).map { pair in
                abs(
                    pair.0.expressedModifierBasisPoints
                        - pair.1.expressedModifierBasisPoints
                )
            }.max() ?? 0
            let phenotypeSignificant = phenotypeDelta
                >= source.configuration.significantChangeBasisPoints
            let causes = Array(Set([
                priorDevelopment.lastEventID,
                homeostasisProfile(for: agentID)?.lastEventID,
                lifecycleState?.members.first(where: {
                    $0.agentID == agentID
                })?.lastLifecycleEventID,
            ].compactMap { $0 })).sorted()
            proposals.append(Proposal(
                agentID: agentID, development: updated,
                phenotype: phenotype,
                developmentSignificant: devSignificant,
                phenotypeSignificant: phenotypeSignificant,
                causeIDs: causes
            ))
        }
        try prevalidateCausalAppend(count: proposals.reduce(0) {
            $0 + ($1.developmentSignificant ? 1 : 0)
                + ($1.phenotypeSignificant ? 1 : 0)
        })
        var genetics = source
        for proposal in proposals {
            var development = proposal.development
            var phenotype = proposal.phenotype
            var latest = development.lastEventID
            if proposal.developmentSignificant {
                guard let event = try recordCausalEvent(
                    kind: .developmentChanged,
                    origin: .geneticsTransition,
                    actorID: proposal.agentID,
                    subjectID: proposal.agentID,
                    causes: proposal.causeIDs,
                    payload: .operation(
                        status: proposal.development.trajectory.rawValue,
                        detail: "maturity="
                            + "\(proposal.development.expressionMaturityBasisPoints) "
                            + "exposure="
                            + "\(proposal.development.physiologicalExposureBasisPoints)"
                    ),
                    summary: "development changed agent=\(proposal.agentID.rawValue)"
                ) else {
                    throw AgentSessionError.genetics(.causalLedgerRequired)
                }
                latest = event.eventID
                development.lastEventID = event.eventID
                development.lastSignificantChangeTick = boundaryTick
                development.lastSignificantMaturityBasisPoints =
                    development.expressionMaturityBasisPoints
                genetics.recentTransitions.append(AgentGeneticsTransition(
                    kind: .developmentChanged, agentID: proposal.agentID,
                    tick: boundaryTick,
                    detail: "maturity=\(development.expressionMaturityBasisPoints)",
                    eventID: event.eventID
                ))
                genetics.totalTransitionCount += 1
            }
            if proposal.phenotypeSignificant {
                guard let event = try recordCausalEvent(
                    kind: .phenotypeChanged,
                    origin: .geneticsTransition,
                    actorID: proposal.agentID,
                    subjectID: proposal.agentID,
                    causes: [latest],
                    payload: .operation(
                        status: "expressed",
                        detail: phenotype.traits.map {
                            "\($0.traitID.rawValue)="
                                + "\($0.expressedModifierBasisPoints)"
                        }.joined(separator: ",")
                    ),
                    summary: "phenotype changed agent=\(proposal.agentID.rawValue)"
                ) else {
                    throw AgentSessionError.genetics(.causalLedgerRequired)
                }
                latest = event.eventID
                phenotype = replacingPhenotypeEvent(
                    phenotype, with: event.eventID,
                    significantTick: boundaryTick
                )
                genetics.recentTransitions.append(AgentGeneticsTransition(
                    kind: .phenotypeChanged, agentID: proposal.agentID,
                    tick: boundaryTick, detail: "expressed",
                    eventID: event.eventID
                ))
                genetics.totalTransitionCount += 1
            }
            development.lastEventID = latest
            if let index = genetics.development.firstIndex(where: {
                $0.agentID == proposal.agentID
            }) {
                genetics.development[index] = development
            }
            if let index = genetics.phenotypes.firstIndex(where: {
                $0.agentID == proposal.agentID
            }) {
                genetics.phenotypes[index] = phenotype
            }
            genetics.lastEventID = latest
        }
        sortGeneticsState(&genetics)
        geneticsState = genetics
        trimGeneticsTransitions()
    }

    mutating func stopGeneticDevelopmentAfterDeath(
        _ agentID: AgentID,
        at deathTick: Int,
        causeEventID: AgentCausalEventID
    ) throws {
        guard var genetics = geneticsState else { return }
        guard let index = genetics.development.firstIndex(where: {
            $0.agentID == agentID
        }), genetics.development[index].active else {
            throw AgentSessionError.genetics(.invalidState(
                "death missing active development \(agentID.rawValue)"
            ))
        }
        genetics.development[index].active = false
        genetics.development[index].stoppedAtTick = deathTick
        genetics.development[index].lastUpdatedTick = deathTick
        genetics.development[index].lastEventID = causeEventID
        genetics.recentTransitions.append(AgentGeneticsTransition(
            kind: .developmentStopped, agentID: agentID, tick: deathTick,
            detail: "death", eventID: causeEventID
        ))
        genetics.totalTransitionCount += 1
        genetics.lastEventID = causeEventID
        geneticsState = genetics
        trimGeneticsTransitions()
    }

    func validateGeneticsCrossDomainIfEnabled() throws {
        guard let genetics = geneticsState else { return }
        try Self.validateGeneticsState(
            genetics,
            agents: statesById.values.sorted {
                $0.agentID < $1.agentID
            },
            lifecycle: lifecycleState,
            mortality: mortalityState,
            clock: clock,
            causalLatestSequence: causalLedger.latestSequence,
            causalDroppedEventCount: causalLedger.droppedEventCount,
            causalEvents: causalLedger.events
        )
    }

    static func validateGeneticsState(
        _ genetics: AgentGeneticsState,
        agents: [AgentSessionAgentState],
        lifecycle: AgentLifecycleState?,
        mortality: AgentMortalityState?,
        clock: AgentSimulationClock,
        causalLatestSequence: UInt64,
        causalDroppedEventCount: UInt64,
        causalEvents: [AgentCausalEvent]
    ) throws {
        _ = try AgentGeneticsConfiguration(
            modelVersion: genetics.configuration.modelVersion,
            maximumProfiles: genetics.configuration.maximumProfiles,
            maximumRetainedTransitions:
                genetics.configuration.maximumRetainedTransitions,
            significantChangeBasisPoints:
                genetics.configuration.significantChangeBasisPoints,
            maximumExpressedModifierBasisPoints:
                genetics.configuration.maximumExpressedModifierBasisPoints
        )
        let genotypeIDs = genetics.genotypes.map(\.genotypeID)
        let agentIDs = genetics.genotypes.map(\.agentID)
        let developmentIDs = genetics.development.map(\.agentID)
        let phenotypeIDs = genetics.phenotypes.map(\.agentID)
        let livingIDs = Set(agents.map(\.agentID))
        let deadIDs = Set(mortality?.records.map(\.agentID) ?? [])
        guard genetics.genotypes.count <= genetics.configuration.maximumProfiles,
              genetics.recentTransitions.count
                <= genetics.configuration.maximumRetainedTransitions,
              genotypeIDs.count == Set(genotypeIDs).count,
              agentIDs.count == Set(agentIDs).count,
              Set(agentIDs) == Set(developmentIDs),
              Set(agentIDs) == Set(phenotypeIDs),
              livingIDs.isSubset(of: Set(agentIDs)),
              Set(agentIDs).isSubset(of: livingIDs.union(deadIDs)),
              genetics.totalTransitionCount >= genetics.recentTransitions.count,
              genetics.transitionEvictionCount >= 0,
              genetics.initializedEventID.simulationID == clock.simulationID,
              genetics.lastEventID.sequence.rawValue <= causalLatestSequence
        else {
            throw AgentCheckpointError.invalidBound("genetics")
        }
        guard let lifecycle else {
            throw AgentCheckpointError.invalidReference("genetics lifecycle")
        }
        guard causalDroppedEventCount <= causalLatestSequence,
              UInt64(causalEvents.count)
                == causalLatestSequence - causalDroppedEventCount,
              causalEvents.enumerated().allSatisfy({ index, event in
                  event.sequence.rawValue
                    == causalDroppedEventCount + UInt64(index) + 1
              }) else {
            throw AgentCheckpointError.invalidCausalState
        }
        let retainedEvent: (AgentCausalEventID) throws -> AgentCausalEvent? = {
            eventID in
            guard eventID.simulationID == clock.simulationID,
                  eventID.sequence.rawValue <= causalLatestSequence else {
                throw AgentCheckpointError.invalidCausalState
            }
            if let event = causalEvents.first(where: {
                $0.eventID == eventID
            }) {
                return event
            }
            guard causalDroppedEventCount > 0,
                  eventID.sequence.rawValue <= causalDroppedEventCount else {
                throw AgentCheckpointError.invalidCausalState
            }
            return nil
        }
        for genotype in genetics.genotypes {
            guard genotype.schemaVersion == genetics.configuration.modelVersion,
                  genotype.loci.map(\.locus)
                    == AgentGeneticLocus.allCases.sorted(),
                  genotype.contributorIDs == genotype.contributorIDs.sorted(),
                  genotype.contributorIDs.count
                    == (genotype.origin == .inherited ? 2 : 1),
                  Set(genotype.contributorIDs).count
                    == genotype.contributorIDs.count,
                  (genotype.origin == .founder
                    && genotype.birthID == nil
                    && genotype.contributorIDs == [genotype.agentID])
                    || (genotype.origin == .inherited
                        && genotype.birthID != nil),
                  genotype.createdAtTick <= clock.tick.rawValue,
                  genotype.creationEventID.simulationID == clock.simulationID,
                  genotype.creationEventID.sequence.rawValue
                    <= causalLatestSequence,
                  genotype.immutableDigest == genotypeDigest(
                    id: genotype.genotypeID, agentID: genotype.agentID,
                    origin: genotype.origin,
                    contributors: genotype.contributorIDs,
                    loci: genotype.loci, birthID: genotype.birthID
                  ) else {
                throw AgentCheckpointError.invalidReference(
                    genotype.agentID.rawValue
                )
            }
            let matchingBirths = lifecycle.births.filter {
                $0.newbornID == genotype.agentID
            }
            switch genotype.origin {
            case .founder:
                guard matchingBirths.isEmpty,
                      lifecycle.members.first(where: {
                          $0.agentID == genotype.agentID
                      })?.origin != .localBirth else {
                    throw AgentCheckpointError.invalidReference(
                        genotype.agentID.rawValue
                    )
                }
            case .inherited:
                guard matchingBirths.count == 1,
                      let birth = matchingBirths.first,
                      genotype.birthID == birth.birthID,
                      genotype.contributorIDs == birth.progenitorIDs,
                      genotype.createdAtTick == birth.birthTick,
                      birth.siteValidatedEventID.sequence
                        < genotype.creationEventID.sequence,
                      genotype.creationEventID.sequence
                        < birth.populationBornEventID.sequence,
                      lifecycle.members.first(where: {
                          $0.agentID == genotype.agentID
                      }).map({
                          $0.origin == .localBirth
                              && $0.birthID == birth.birthID
                              && $0.progenitorIDs == birth.progenitorIDs
                      }) ?? true else {
                    throw AgentCheckpointError.invalidReference(
                        genotype.agentID.rawValue
                    )
                }
                if let event = try retainedEvent(
                    genotype.creationEventID
                ) {
                    let expectedDetail =
                        "genotype=\(genotype.genotypeID.rawValue) contributors="
                            + genotype.contributorIDs.map(\.rawValue)
                                .joined(separator: ",")
                    guard event.kind == .genotypeInherited,
                          event.origin == .geneticsTransition,
                          event.simulationTick.rawValue == birth.birthTick,
                          event.actorID == birth.progenitorIDs.first,
                          event.subjectID == birth.newbornID,
                          event.operationID == nil,
                          event.causes.contains(
                              birth.siteValidatedEventID
                          ),
                          case let .operation(status, detail) = event.payload,
                          status == "inherited",
                          detail == expectedDetail else {
                        throw AgentCheckpointError.invalidCausalState
                    }
                }
                if let site = try retainedEvent(
                    birth.siteValidatedEventID
                ) {
                    guard site.kind == .birthSiteValidated,
                          site.origin == .lifecycleTransition,
                          site.simulationTick.rawValue == birth.birthTick,
                          site.actorID == birth.progenitorIDs.first,
                          site.subjectID == birth.newbornID,
                          site.operationID == nil,
                          case let .birth(
                              birthID, planID, newbornID, ordinal,
                              progenitorIDs, position, fingerprint, status
                          ) = site.payload,
                          birthID == birth.birthID.rawValue,
                          planID == birth.planID.rawValue,
                          newbornID == birth.newbornID.rawValue,
                          ordinal == birth.ordinal.rawValue,
                          progenitorIDs
                            == birth.progenitorIDs.map(\.rawValue),
                          position == birth.position,
                          fingerprint == birth.worldFingerprint,
                          status == "siteValidated" else {
                        throw AgentCheckpointError.invalidCausalState
                    }
                }
                if let born = try retainedEvent(
                    birth.populationBornEventID
                ) {
                    guard born.kind == .populationMemberBorn,
                          born.origin == .lifecycleTransition,
                          born.simulationTick.rawValue == birth.birthTick,
                          born.actorID == birth.progenitorIDs.first,
                          born.subjectID == birth.newbornID,
                          born.operationID == nil,
                          born.causes.contains(
                              birth.siteValidatedEventID
                          ),
                          born.causes.contains(
                              genotype.creationEventID
                          ),
                          case let .birth(
                              birthID, planID, newbornID, ordinal,
                              progenitorIDs, position, fingerprint, status
                          ) = born.payload,
                          birthID == birth.birthID.rawValue,
                          planID == birth.planID.rawValue,
                          newbornID == birth.newbornID.rawValue,
                          ordinal == birth.ordinal.rawValue,
                          progenitorIDs
                            == birth.progenitorIDs.map(\.rawValue),
                          position == birth.position,
                          fingerprint == birth.worldFingerprint,
                          status == "born" else {
                        throw AgentCheckpointError.invalidCausalState
                    }
                }
            }
            for locus in genotype.loci {
                guard locus.contributions.count == 2,
                      locus.contributions.map(\.contributorID).sorted()
                        == (genotype.origin == .founder
                            ? [genotype.agentID, genotype.agentID]
                            : genotype.contributorIDs),
                      locus.contributions.allSatisfy({
                          (0...1).contains($0.sourceAlleleIndex)
                              && genotype.contributorIDs.contains($0.contributorID)
                              && (genotype.origin == .inherited
                                  ? $0.sourceGenotypeID != nil
                                  : $0.sourceGenotypeID == nil)
                      }) else {
                    throw AgentCheckpointError.invalidReference(
                        genotype.agentID.rawValue
                    )
                }
                if genotype.origin == .inherited {
                    for contribution in locus.contributions {
                        guard let parent = genetics.genotypes.first(where: {
                            $0.agentID == contribution.contributorID
                                && $0.genotypeID
                                    == contribution.sourceGenotypeID
                        }),
                        let parentLocus = parent.loci.first(where: {
                            $0.locus == locus.locus
                        }),
                        parentLocus.contributions[
                            contribution.sourceAlleleIndex
                        ].allele == contribution.allele else {
                            throw AgentCheckpointError.invalidReference(
                                genotype.agentID.rawValue
                            )
                        }
                    }
                }
            }
        }
        for member in lifecycle.members {
            guard let genotype = genetics.genotypes.first(where: {
                $0.agentID == member.agentID
            }) else {
                throw AgentCheckpointError.invalidReference(
                    member.agentID.rawValue
                )
            }
            switch member.origin {
            case .localBirth:
                guard genotype.origin == .inherited,
                      let birthID = member.birthID,
                      genotype.birthID == birthID,
                      genotype.contributorIDs == member.progenitorIDs,
                      lifecycle.births.filter({
                          $0.newbornID == member.agentID
                              && $0.birthID == birthID
                      }).count == 1 else {
                    throw AgentCheckpointError.invalidReference(
                        member.agentID.rawValue
                    )
                }
            case .bootstrapResident, .importedMigrant:
                guard genotype.origin == .founder,
                      genotype.birthID == nil else {
                    throw AgentCheckpointError.invalidReference(
                        member.agentID.rawValue
                    )
                }
            }
        }
        for birth in lifecycle.births {
            guard genetics.genotypes.filter({
                $0.agentID == birth.newbornID
                    && $0.origin == .inherited
                    && $0.birthID == birth.birthID
                    && $0.contributorIDs == birth.progenitorIDs
                    && $0.createdAtTick == birth.birthTick
            }).count == 1 else {
                throw AgentCheckpointError.invalidReference(
                    birth.newbornID.rawValue
                )
            }
        }
        for development in genetics.development {
            guard (0...10_000).contains(
                    development.expressionMaturityBasisPoints
                  ),
                  (0...10_000).contains(
                    development.physiologicalExposureBasisPoints
                  ),
                  (0...10_000).contains(
                    development.developmentalReserveBasisPoints
                  ),
                  development.lastUpdatedTick <= clock.tick.rawValue,
                  development.updateCount >= 0,
                  development.active == livingIDs.contains(development.agentID),
                  (development.active && development.stoppedAtTick == nil)
                    || (!development.active
                        && development.stoppedAtTick != nil) else {
                throw AgentCheckpointError.invalidReference(
                    development.agentID.rawValue
                )
            }
            if development.active,
               let member = lifecycle.members.first(where: {
                   $0.agentID == development.agentID
               }) {
                guard development.ageTicks == (try member.age(at: clock.tick.rawValue)),
                      development.lifeStage == member.currentStage else {
                    throw AgentCheckpointError.invalidReference(
                        development.agentID.rawValue
                    )
                }
            }
        }
        for phenotype in genetics.phenotypes {
            guard phenotype.traits.map(\.traitID)
                    == AgentPhenotypeTraitID.allCases.sorted(),
                  phenotype.traits.allSatisfy({
                      $0.lowerBoundBasisPoints
                        == -genetics.configuration
                            .maximumExpressedModifierBasisPoints
                          && $0.upperBoundBasisPoints
                            == genetics.configuration
                                .maximumExpressedModifierBasisPoints
                          && $0.expressedModifierBasisPoints
                            >= $0.lowerBoundBasisPoints
                          && $0.expressedModifierBasisPoints
                            <= $0.upperBoundBasisPoints
                  }),
                  phenotype.lastUpdatedTick <= clock.tick.rawValue,
                  let genotype = genetics.genotypes.first(where: {
                      $0.agentID == phenotype.agentID
                  }),
                  let development = genetics.development.first(where: {
                      $0.agentID == phenotype.agentID
                  }) else {
                throw AgentCheckpointError.invalidReference(
                    phenotype.agentID.rawValue
                )
            }
            let expected = derivePhenotypeStatic(
                genotype: genotype, development: development,
                previous: phenotype,
                eventID: phenotype.traits.first!.lastEventID,
                at: phenotype.lastUpdatedTick,
                configuration: genetics.configuration
            )
            guard zip(phenotype.traits, expected.traits).allSatisfy({ pair in
                pair.0.traitID == pair.1.traitID
                    && pair.0.geneticPotentialBasisPoints
                        == pair.1.geneticPotentialBasisPoints
                    && pair.0.developmentalFactorBasisPoints
                        == pair.1.developmentalFactorBasisPoints
                    && pair.0.physiologicalExpressionFactorBasisPoints
                        == pair.1.physiologicalExpressionFactorBasisPoints
                    && pair.0.expressedModifierBasisPoints
                        == pair.1.expressedModifierBasisPoints
            }) else {
                throw AgentCheckpointError.invalidReference(
                    phenotype.agentID.rawValue
                )
            }
        }
    }
}

private extension AgentSimulationSession {
    func initialDevelopment(
        agentID: AgentID,
        genotype: AgentGenotypeRecord,
        age: Int,
        stage: AgentLifeStage,
        eventID: AgentCausalEventID
    ) -> AgentDevelopmentRecord {
        let exposure = currentExposure(homeostasisProfile(for: agentID))
        let maturity = maturityBasisPoints(
            age: age, stage: stage, genotype: genotype
        )
        return AgentDevelopmentRecord(
            agentID: agentID, active: true, ageTicks: age, lifeStage: stage,
            expressionMaturityBasisPoints: maturity,
            physiologicalExposureBasisPoints: exposure,
            developmentalReserveBasisPoints: 10_000 - exposure,
            trajectory: trajectory(exposure),
            lastUpdatedTick: tick, lastSignificantChangeTick: tick,
            lastSignificantMaturityBasisPoints: maturity,
            updateCount: 0, stoppedAtTick: nil, lastEventID: eventID
        )
    }

    func geneticDemographicAge(
        for agentID: AgentID,
        at boundaryTick: Int
    ) throws -> Int {
        guard let member = lifecycleState?.members.first(where: {
            $0.agentID == agentID
        }) else {
            throw AgentSessionError.genetics(.unknownAgent(agentID))
        }
        return try member.age(at: boundaryTick)
    }

    func geneticLifeStage(age: Int) -> AgentLifeStage {
        guard let configuration = lifecycleState?.configuration else {
            return .mature
        }
        if age < configuration.newbornDurationTicks { return .newborn }
        if age < configuration.maturityAgeTicks { return .juvenile }
        return .mature
    }

    func updatedDevelopment(
        _ prior: AgentDevelopmentRecord,
        genotype: AgentGenotypeRecord,
        age: Int,
        stage: AgentLifeStage,
        homeostasis: AgentHomeostasisProfile?,
        boundaryTick: Int
    ) -> AgentDevelopmentRecord {
        let sample = currentExposure(homeostasis)
        let exposure = min(
            10_000, max(
                0,
                (prior.physiologicalExposureBasisPoints * 7 + sample) / 8
            )
        )
        var value = prior
        value.ageTicks = age
        value.lifeStage = stage
        value.expressionMaturityBasisPoints = max(
            prior.expressionMaturityBasisPoints,
            maturityBasisPoints(age: age, stage: stage, genotype: genotype)
        )
        value.physiologicalExposureBasisPoints = exposure
        value.developmentalReserveBasisPoints = 10_000 - exposure
        value.trajectory = trajectory(exposure)
        value.lastUpdatedTick = boundaryTick
        value.updateCount += 1
        return value
    }

    func currentExposure(_ profile: AgentHomeostasisProfile?) -> Int {
        guard let profile else { return 0 }
        let energyDeficit = 10_000 - profile.energyReserveBasisPoints
        return min(
            10_000,
            max(0, (energyDeficit + profile.stressBasisPoints) / 2)
        )
    }

    func trajectory(_ exposure: Int) -> AgentDevelopmentTrajectory {
        if exposure >= 6_000 { return .strained }
        if exposure <= 2_000 { return .protected }
        return .stable
    }

    func maturityBasisPoints(
        age: Int,
        stage: AgentLifeStage,
        genotype: AgentGenotypeRecord
    ) -> Int {
        let tempo = genotype.loci.first {
            $0.locus == .expressionTempo
        }?.potentialBasisPoints ?? 0
        guard let lifecycle = lifecycleState else { return 10_000 }
        switch stage {
        case .newborn:
            let duration = max(1, lifecycle.configuration.newbornDurationTicks)
            let progress = min(2_500, max(0, age) * 2_500 / duration)
            return min(2_500, max(0, progress + tempo / 4))
        case .juvenile:
            let span = max(
                1, lifecycle.configuration.maturityAgeTicks
                    - lifecycle.configuration.newbornDurationTicks
            )
            let elapsed = max(
                0, age - lifecycle.configuration.newbornDurationTicks
            )
            let progress = 2_500 + min(5_000, elapsed * 5_000 / span)
            return min(7_500, max(2_500, progress + tempo / 2))
        case .mature:
            return 10_000
        }
    }

    func derivePhenotype(
        genotype: AgentGenotypeRecord,
        development: AgentDevelopmentRecord,
        previous: AgentPhenotypeRecord?,
        eventID: AgentCausalEventID,
        at tick: Int,
        configuration: AgentGeneticsConfiguration
    ) -> AgentPhenotypeRecord {
        Self.derivePhenotypeStatic(
            genotype: genotype, development: development, previous: previous,
            eventID: eventID, at: tick, configuration: configuration
        )
    }

    func deterministicAllele(
        domain: String,
        agentID: AgentID,
        locus: AgentGeneticLocus,
        copy: Int,
        modelVersion: Int
    ) -> AgentGeneticAllele {
        let index = deterministicIndex(
            domain: [
                domain, simulationID.rawValue, agentID.rawValue,
                locus.rawValue, String(copy), "v\(modelVersion)",
            ].joined(separator: "|"),
            upperBound: AgentGeneticAllele.allCases.count
        )
        return AgentGeneticAllele.allCases[index]
    }

    func deterministicIndex(domain: String, upperBound: Int) -> Int {
        var value: UInt64 = 14_695_981_039_346_656_037
        for byte in domain.utf8 {
            value ^= UInt64(byte)
            value &*= 1_099_511_628_211
        }
        return Int(value % UInt64(upperBound))
    }

    func makeGenotypeID(
        _ agentID: AgentID,
        modelVersion: Int
    ) -> AgentGenotypeID {
        let digest = AgentGeneticsDigest.make(
            "\(simulationID.rawValue)|\(agentID.rawValue)|v\(modelVersion)"
        )
        return AgentGenotypeID(
            rawValue: "genotype-\(agentID.rawValue)-v\(modelVersion)-\(digest)"
        )!
    }

    mutating func trimGeneticsTransitions() {
        guard var genetics = geneticsState else { return }
        let excess = genetics.recentTransitions.count
            - genetics.configuration.maximumRetainedTransitions
        if excess > 0 {
            genetics.recentTransitions.removeFirst(excess)
            genetics.transitionEvictionCount += excess
        }
        geneticsState = genetics
    }

    func sortGeneticsState(_ genetics: inout AgentGeneticsState) {
        genetics.genotypes.sort { $0.agentID < $1.agentID }
        genetics.development.sort { $0.agentID < $1.agentID }
        genetics.phenotypes.sort { $0.agentID < $1.agentID }
    }

    static func derivePhenotypeStatic(
        genotype: AgentGenotypeRecord,
        development: AgentDevelopmentRecord,
        previous: AgentPhenotypeRecord?,
        eventID: AgentCausalEventID,
        at tick: Int,
        configuration: AgentGeneticsConfiguration
    ) -> AgentPhenotypeRecord {
        let physiologicalFactor = min(
            10_000,
            max(
                8_000,
                8_000 + development.developmentalReserveBasisPoints / 5
            )
        )
        let traits = AgentPhenotypeTraitID.allCases.sorted().map { traitID in
            let potential = genotype.loci.first {
                $0.locus == traitID.locus
            }?.potentialBasisPoints ?? 0
            let developmental = development.expressionMaturityBasisPoints
            let expressed = min(
                configuration.maximumExpressedModifierBasisPoints,
                max(
                    -configuration.maximumExpressedModifierBasisPoints,
                    potential * developmental / 10_000
                        * physiologicalFactor / 10_000
                )
            )
            let prior = previous?.traits.first { $0.traitID == traitID }
            return AgentPhenotypeTrait(
                traitID: traitID,
                geneticPotentialBasisPoints: potential,
                developmentalFactorBasisPoints: developmental,
                physiologicalExpressionFactorBasisPoints:
                    physiologicalFactor,
                expressedModifierBasisPoints: expressed,
                lowerBoundBasisPoints:
                    -configuration.maximumExpressedModifierBasisPoints,
                upperBoundBasisPoints:
                    configuration.maximumExpressedModifierBasisPoints,
                provenance: "genotype+\(development.lifeStage.rawValue)"
                    + "+boundedHomeostasisExposure",
                lastSignificantChangeTick:
                    prior?.lastSignificantChangeTick ?? tick,
                lastEventID: prior?.lastEventID ?? eventID
            )
        }
        return AgentPhenotypeRecord(
            agentID: genotype.agentID, traits: traits, lastUpdatedTick: tick
        )
    }
}

private func genotypeDigest(
    id: AgentGenotypeID,
    agentID: AgentID,
    origin: AgentGenotypeOrigin,
    contributors: [AgentID],
    loci: [AgentGeneticLocusRecord],
    birthID: AgentBirthID?
) -> String {
    AgentGeneticsDigest.make([
        id.rawValue, agentID.rawValue, origin.rawValue,
        contributors.map(\.rawValue).joined(separator: ","),
        birthID?.rawValue ?? "none",
        loci.map { locus in
            "\(locus.locus.rawValue)=" + locus.contributions.map {
                "\($0.contributorID.rawValue):\($0.allele.rawValue):"
                    + "\($0.sourceGenotypeID?.rawValue ?? "founder"):"
                    + "\($0.sourceAlleleIndex)"
            }.joined(separator: ",")
        }.joined(separator: ";"),
    ].joined(separator: "|"))
}

private func replacingCreationEvent(
    _ value: AgentGenotypeRecord,
    with eventID: AgentCausalEventID
) -> AgentGenotypeRecord {
    AgentGenotypeRecord(
        schemaVersion: value.schemaVersion, genotypeID: value.genotypeID,
        agentID: value.agentID, origin: value.origin,
        contributorIDs: value.contributorIDs, loci: value.loci,
        createdAtTick: value.createdAtTick, birthID: value.birthID,
        creationEventID: eventID, immutableDigest: value.immutableDigest
    )
}

private func replacingDevelopmentEvent(
    _ value: AgentDevelopmentRecord,
    with eventID: AgentCausalEventID
) -> AgentDevelopmentRecord {
    var copy = value
    copy.lastEventID = eventID
    return copy
}

private func replacingPhenotypeEvent(
    _ value: AgentPhenotypeRecord,
    with eventID: AgentCausalEventID,
    significantTick: Int? = nil
) -> AgentPhenotypeRecord {
    AgentPhenotypeRecord(
        agentID: value.agentID,
        traits: value.traits.map {
            AgentPhenotypeTrait(
                traitID: $0.traitID,
                geneticPotentialBasisPoints: $0.geneticPotentialBasisPoints,
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
                    significantTick ?? $0.lastSignificantChangeTick,
                lastEventID: eventID
            )
        },
        lastUpdatedTick: value.lastUpdatedTick
    )
}

private enum AgentGeneticsDigest {
    static func make(_ text: String) -> String {
        var value: UInt64 = 14_695_981_039_346_656_037
        for byte in text.utf8 {
            value ^= UInt64(byte)
            value &*= 1_099_511_628_211
        }
        let digits = String(value, radix: 16, uppercase: false)
        return String(repeating: "0", count: max(0, 16 - digits.count))
            + digits
    }
}
