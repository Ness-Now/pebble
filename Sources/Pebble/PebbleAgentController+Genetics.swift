import PebbleAgents

extension PebbleAgentController {
    func handleGenetics(
        _ arguments: [String]
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab genetics <on|status>"
        guard geneticsFeatureEnabled else {
            return failure(
                "Genetics disabled. Set PEBBLELAB_APP_AGENTS_GENETICS=1 before launch."
            )
        }
        guard arguments.count == 1,
              let command = arguments.first?.lowercased(),
              var candidate = session else {
            return failure(usage)
        }
        do {
            switch command {
            case "on":
                if !candidate.geneticsEnabled {
                    var recorder = replayRecorder
                    if try applyRecordedOperationIfActive(
                        .setGeneticsEnabled(true, configuration: .live),
                        session: &candidate,
                        recorder: &recorder
                    ) == nil {
                        try candidate.setGeneticsEnabled(true)
                    }
                    session = candidate
                    replayRecorder = recorder
                }
                return geneticsStatus(candidate)
            case "status":
                return geneticsStatus(candidate)
            default:
                return failure(usage)
            }
        } catch {
            return failure("Genetics command failed atomically: \(error)")
        }
    }

    func geneticsStatus(
        _ candidate: AgentSimulationSession
    ) -> PebbleAgentCommandResult {
        let snapshot = candidate.geneticsSnapshot()
        let rows = snapshot.genotypes.map { genotype in
            let development = snapshot.development.first {
                $0.agentID == genotype.agentID
            }
            let phenotype = snapshot.phenotypes.first {
                $0.agentID == genotype.agentID
            }
            let loci = genotype.loci.map { locus in
                let alleles = locus.contributions.map {
                    "\($0.contributorID.rawValue):\($0.allele.rawValue)"
                }.joined(separator: "+")
                return "\(locus.locus.rawValue)=\(alleles)"
            }.joined(separator: ",")
            let traits = phenotype?.traits.map {
                "\($0.traitID.rawValue):\($0.expressedModifierBasisPoints)"
            }.joined(separator: ",") ?? "none"
            return [
                genotype.agentID.rawValue,
                genotype.origin.rawValue,
                genotype.genotypeID.rawValue,
                genotype.contributorIDs.map(\.rawValue).joined(separator: ","),
                loci,
                String(development?.expressionMaturityBasisPoints ?? -1),
                development?.trajectory.rawValue ?? "none",
                traits,
                String(genotype.creationEventID.sequence.rawValue),
            ].joined(separator: "/")
        }.joined(separator: ";")
        let message = [
            "genetics status",
            "enabled=\(snapshot.enabled ? 1 : 0)",
            "schema=\(candidate.durableState().schemaVersion)",
            "model=\(snapshot.configuration?.modelVersion ?? 0)",
            "tick=\(candidate.tick)",
            "profiles=\(snapshot.genotypes.count)",
            "rows=\(rows.isEmpty ? "none" : rows)",
            "transitions=\(snapshot.totalTransitionCount)",
            "evicted=\(snapshot.transitionEvictionCount)",
            "digest=\(snapshot.digest)",
            "mutation=none",
        ].joined(separator: " ")
        trace(message)
        return success(message)
    }
}
