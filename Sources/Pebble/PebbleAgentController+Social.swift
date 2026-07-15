import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func handleSocial(_ arguments: [String]) -> PebbleAgentCommandResult {
        let subcommand = arguments.first?.lowercased() ?? "status"
        let usage = "Usage: /lab social <on|off|status|clear>"
        guard arguments.count == 1 else { return failure(usage) }
        guard var session else { return failure("No active PebbleAgents session.") }

        do {
            switch subcommand {
            case "on":
                guard socialFeatureEnabled else {
                    return failure(
                        "PebbleAgents social disabled. Set PEBBLELAB_APP_AGENTS_SOCIAL=1 before launch."
                    )
                }
                if try applyCommandMutationIfRecording(
                    .setSocialEnabled(true), session: &session
                ) == nil {
                    try session.setSocialEnabled(true)
                }
                self.session = session
                trace("social=on tick=\(session.tick) mutation=none")
                return success(
                    "PebbleAgents social on; interaction, economy, natural harvest, and construction unchanged."
                )
            case "off":
                if try applyCommandMutationIfRecording(
                    .setSocialEnabled(false), session: &session
                ) == nil {
                    try session.setSocialEnabled(false)
                }
                self.session = session
                trace("social=off tick=\(session.tick) mutation=none retained=1")
                return success(
                    "PebbleAgents social off; facts, beliefs, messages, and directed trust retained."
                )
            case "clear":
                guard socialFeatureEnabled else {
                    return failure(
                        "PebbleAgents social disabled. Set PEBBLELAB_APP_AGENTS_SOCIAL=1 before launch."
                    )
                }
                if try applyCommandMutationIfRecording(
                    .clearSocialState, session: &session
                ) == nil {
                    try session.clearSocialState()
                }
                self.session = session
                trace("social clear tick=\(session.tick) mutation=none")
                return success(
                    "PebbleAgents social state cleared; World, inventory, stock, and causal history preserved."
                )
            case "status":
                let summary = session.socialSummary()
                let snapshot = session.socialSnapshot()
                let active = snapshot.activeVerifications.map {
                    "\($0.verifierID.rawValue)@\(positionText($0.position))"
                }.joined(separator: ",")
                let trust = snapshot.trustRelations.map {
                    "\($0.sourceID.rawValue)→\($0.targetID.rawValue)=\($0.score)"
                }.joined(separator: ",")
                let message = "social status gate=\(socialFeatureEnabled ? "enabled" : "disabled") enabled=\(summary.enabled ? "yes" : "no") messages=\(summary.retainedMessageCount) unverified=\(summary.unverifiedBeliefCount) confirmed=\(summary.confirmedBeliefCount) contradicted=\(summary.contradictedBeliefCount) expired=\(summary.expiredBeliefCount) ignored=\(summary.ignoredBeliefCount) active=\(active.isEmpty ? "none" : active) trustEdges=\(summary.trustEdgeCount) trust=\(trust.isEmpty ? "none" : trust) events=\(summary.socialCausalEventCount) evicted=\(summary.evictionCounts.facts),\(summary.evictionCounts.messages),\(summary.evictionCounts.beliefs),\(summary.evictionCounts.trustRelations) digest=\(summary.digest)"
                trace(message)
                return success(message)
            default:
                return failure(usage)
            }
        } catch {
            return failure("PebbleAgents social command failed: \(error)")
        }
    }

    func socialResourceObservations(
        world: World,
        agent: AgentSnapshot,
        snapshot: AgentSessionSnapshot,
        player: Player
    ) throws -> [AgentResourceObservation] {
        guard session?.socialEnabled == true, agent.id == focusedAgentId else { return [] }
        let occupied = snapshot.agents.filter { $0.id != agent.id }.map(\.position)
        let playerPosition = AgentPosition(
            x: Int(player.x.rounded(.down)),
            y: Int(player.y.rounded(.down)),
            z: Int(player.z.rounded(.down))
        )
        let scan = try naturalResourceAdapter.scan(
            world: world,
            agent: agent,
            occupiedAgentPositions: occupied,
            playerPosition: playerPosition
        )
        if session?.cooperationEnabled == true,
           snapshot.constructionProject?.builderAgentId == agent.id {
            return Array(scan.observations.sorted {
                let lhsOrder = $0.resource == .stone ? 0 : 1
                let rhsOrder = $1.resource == .stone ? 0 : 1
                if lhsOrder != rhsOrder { return lhsOrder < rhsOrder }
                return AgentResourcePerception.sortsBefore($0, $1)
            }.prefix(AgentResourcePerception.maximumObservationCount))
        }
        return Array(scan.observations.prefix(1))
    }

    func socialNavigationObservation(
        world: World,
        agent: AgentSnapshot,
        request: AgentSocialVerificationRequest,
        occupiedAgentPositions: [AgentPosition]
    ) -> AgentNavigationObservation? {
        if agent.navigationProgress.status == .active,
           agent.navigationProgress.route?.purpose == .socialVerification,
           let target = agent.navigationProgress.route?.target {
            return navigationAdapter.observe(
                world: world,
                agent: agent,
                target: target,
                occupiedAgentPositions: occupiedAgentPositions,
                goalMode: target == request.position ? .cardinalAdjacent : .exact
            )
        }
        if AgentBoundedTravel.requiresWaypoint(from: agent.position, to: request.position) {
            return navigationAdapter.observeBoundedTravel(
                world: world,
                agent: agent,
                destination: request.position,
                occupiedAgentPositions: occupiedAgentPositions
            )
        }
        return navigationAdapter.observe(
            world: world,
            agent: agent,
            target: request.position,
            occupiedAgentPositions: occupiedAgentPositions,
            goalMode: .cardinalAdjacent
        )
    }

    func traceSocialState(snapshot: AgentSessionSnapshot) {
        guard let session, session.socialEnabled else { return }
        let social = session.socialSnapshot()
        let fact = social.facts.first.map {
            "\($0.factID.rawValue) observer=\($0.observerID.rawValue) resource=\($0.resource.rawValue) position=\(positionText($0.position)) fingerprint=\($0.expectedBlockFingerprint) perception=\($0.directObservationEventID.rawValue)"
        } ?? "none"
        let message = social.messages.first.map {
            "\($0.messageID.rawValue) sender=\($0.senderID.rawValue) recipient=\($0.recipientID.rawValue) sentEvent=\($0.sentEventID.rawValue) receivedEvent=\($0.receivedEventID.rawValue)"
        } ?? "none"
        let belief = social.beliefs.first.map {
            "\($0.beliefID.rawValue) owner=\($0.ownerID.rawValue) status=\($0.status.rawValue) verifyEvent=\($0.verificationEventID?.rawValue ?? "none")"
        } ?? "none"
        let trust = social.trustRelations.map {
            "\($0.sourceID.rawValue)→\($0.targetID.rawValue)=\($0.score)@\($0.lastChangeEventID?.rawValue ?? "none")"
        }.joined(separator: ",")
        let active = social.activeVerifications.first.map {
            "\($0.verifierID.rawValue)@\(positionText($0.position))"
        } ?? "none"
        let verifier = social.activeVerifications.first.flatMap { request in
            snapshot.agents.first { $0.id == request.verifierID.rawValue }
        }
        let route = verifier?.navigationProgress.route.map {
            $0.positions.map(positionText).joined(separator: ">")
        } ?? "none"
        let navigation = verifier.map {
            "\($0.navigationProgress.route?.purpose.rawValue ?? "none"):\($0.navigationProgress.status.rawValue):\($0.navigationProgress.routeIndex)/\(max(0, ($0.navigationProgress.route?.positions.count ?? 1) - 1))"
        } ?? "none"
        let inventories = snapshot.agents.map {
            "\($0.id):\($0.resourceInventory.totalCount)"
        }.joined(separator: ",")
        trace("social tick=\(snapshot.tick) fact=\(fact) messages=\(message) belief=\(belief) trust=\(trust.isEmpty ? "none" : trust) active=\(active) navigation=\(navigation) route=\(route) inventories=\(inventories) stock=\(snapshot.campStock.totalCount) construction=\(snapshot.constructionProject?.projectId ?? "none") conservation=\(snapshot.conservation.balanced ? "exact" : "diverged") events=\(social.socialCausalEventCount) digest=\(social.digest)")
    }
}
