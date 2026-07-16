import Foundation
import PebbleAgents

enum PebbleAgentOverlayMode: String {
    case off
    case compact
    case full
}

struct PebbleAgentDebugState {
    let globalLines: [String]
    let focusedAgentLines: [String]
    let statusSummary: String

    init(
        snapshot: AgentSessionSnapshot,
        causalSummary: AgentCausalLedgerSummary,
        socialSnapshot: AgentSocialSnapshot,
        physicalSnapshot: AgentPhysicalChannelSnapshot,
        cooperationSnapshot: AgentCooperationSnapshot,
        populationSnapshot: AgentPopulationSnapshot,
        mode: PebbleAgentOverlayMode,
        paused: Bool,
        cognitiveHz: Int,
        movementEnabled: Bool,
        followMode: PebbleAgentFollowMode,
        demoActive: Bool,
        focusedAgentId: String?,
        observedGoalKinds: [String],
        lastInfluencedDecisionTrace: AgentFeedbackDecisionTrace?,
        lastInfluencedDecisionAgentId: String?,
        runtimeErrorCount: Int,
        droppedCatchUpSteps: Int,
        worldTick: Int?,
        lastError: String?,
        interaction: PebbleAgentInteractionState,
        economyFixtures: PebbleAgentEconomyFixtureState,
        economyReason: String,
        naturalGateEnabled: Bool,
        naturalState: PebbleAgentNaturalResourceState,
        buildGateEnabled: Bool,
        constructionState: PebbleAgentConstructionState,
        constructionSiteDiagnostics: PebbleAgentConstructionSiteDiagnostics,
        constructionReason: String
    ) {
        let focus = snapshot.agents.first { $0.id == focusedAgentId } ?? snapshot.agents.first
        let status = paused ? "paused" : "running"
        statusSummary = "status=\(status) tick=\(snapshot.tick) hz=\(cognitiveHz) agents=\(snapshot.agentCount)"
        guard let agent = focus else {
            globalLines = ["PEBBLE AGENTS - 3D LIVE PROTOTYPE"]
            focusedAgentLines = ["No focused agent"]
            return
        }

        let currentFeedback = agent.lastFeedbackDecisionTrace.flatMap {
            $0.memoryRecordsUsed.isEmpty ? nil : $0
        } ?? lastInfluencedDecisionTrace
        let socialLines = Self.socialLines(snapshot: socialSnapshot, focusedAgentId: agent.id)
        let physicalLines = Self.physicalLines(
            snapshot: physicalSnapshot,
            focusedAgentId: agent.id
        )
        let cooperationLines = Self.cooperationLines(
            snapshot: cooperationSnapshot,
            focusedAgentId: agent.id
        )
        let populationLines = Self.populationLines(
            snapshot: populationSnapshot,
            focusedAgentId: agent.id
        )
        if mode == .compact {
            let decisionAgent = lastInfluencedDecisionAgentId.flatMap { id in
                snapshot.agents.first { $0.id == id }
            } ?? agent
            globalLines = [
                "PEBBLE AGENTS - 3D LIVE PROTOTYPE",
                "status: \(status)  demo: \(demoActive ? "on" : "off")  tick: \(snapshot.tick)",
                "sim=\(causalSummary.simulationID.rawValue) tick=\(causalSummary.currentTick.rawValue) seq=\(causalSummary.latestSequence) events=\(causalSummary.retainedEventCount) dropped=\(causalSummary.droppedEventCount)",
                "worldTick: \(worldTick.map(String.init) ?? "none")",
                "clock: \(cognitiveHz) Hz  paused: \(paused ? "yes" : "no")",
                "movement: \(movementEnabled ? "on" : "off")  follow: \(followMode.statusText)",
                "agents: \(snapshot.agentCount) focus: \(agent.id) goals: \(Self.short(observedGoalKinds.joined(separator: ","), limit: 22))",
            ]
            let base = currentFeedback?.baseDirection?.rawValue ?? currentFeedback?.baseAction.name ?? agent.lastAction?.name ?? "none"
            let final = currentFeedback?.finalDirection?.rawValue ?? currentFeedback?.finalAction.name ?? agent.lastAction?.name ?? "none"
            let movement = agent.lastMovementOutcome.map {
                "\($0.status.rawValue) \($0.requestedDirection?.rawValue ?? "none")"
            } ?? "none"
            let perception = agent.lastWorldObservation.map {
                "t/b/d \($0.traversableNeighborCount)/\($0.blockedNeighborCount)/\($0.dangerousDropCount)"
            } ?? "none"
            let memory = currentFeedback?.memoryRecordsUsed.first.map {
                "\($0.type)@\($0.tick) age \($0.ageTicks)"
            } ?? "none"
            let factor = currentFeedback?.dominantFactor.kind.rawValue ?? "basePolicy"
            let reason = currentFeedback?.reason ?? agent.lastAction?.reason ?? "none"
            let interactionTarget = interaction.target.map(Self.position) ?? "none"
            let resourceSeen = agent.lastResourceObservations.first.map {
                "\($0.resource.rawValue)@\(Self.position($0.target)) d=\($0.distanceManhattan)"
            } ?? "none"
            let activeTarget = agent.activeResourceTarget.map {
                "\(Self.position($0.target)) \($0.source.rawValue) s\($0.selectedAtTick)/l\($0.lastSeenAtTick)"
            } ?? "none"
            let navigation = agent.navigationProgress
            let route = "\(navigation.status.rawValue) \(navigation.routeIndex)/\(max(0, (navigation.route?.positions.count ?? 1) - 1)) rem \(navigation.stepsRemaining)"
            let nextStep = navigation.nextStep.map(Self.position) ?? "none"
            let interactionOutcome = agent.lastInteractionOutcome
            let survival = agent.survivalProgress
            let interactionMemory = agent.recentMemory.last { memory in
                memory.type == "resource_harvested" || memory.type == "interaction_blocked" || memory.type == "inventory_full"
            }?.type ?? "none"
            focusedAgentLines = [
                "FOCUS \(agent.id) pos \(Self.position(agent.position)) home d=\(agent.distanceFromHome)",
                "need: \(Self.dominantNeed(agent.needs))  goal: \(agent.currentGoal.kind.rawValue)",
                "action: \(base) > \(final)\(currentFeedback?.actionChanged == true ? " changed" : "")",
                "movement: \(movement)",
                "perception: \(perception)",
                "memory used\(lastInfluencedDecisionAgentId.map { " (\($0))" } ?? ""): \(memory)",
                "factor: \(factor)",
                "reason: \(Self.short(reason, limit: 38))",
                "memory/retrieved/influenced/dedup: \(decisionAgent.memoryCount)/\(decisionAgent.memoryRetrievalCount)/\(decisionAgent.memoryInfluencedDecisionCount)/\(decisionAgent.feedbackMemoryDeduplicatedCount)",
                "inventory: \(agent.resourceInventory.totalCount)/\(agent.resourceInventory.capacity) food/wood/stone \(agent.resourceInventory.count(of: .foodRaw))/\(agent.resourceInventory.count(of: .wood))/\(agent.resourceInventory.count(of: .stone))",
                "economy: \(snapshot.economyEnabled ? "on" : "off") quota \(snapshot.deliveryQuota) stock \(snapshot.campStock.totalCount) fixtures \(economyFixtures.fixtures.filter { !$0.harvested }.count)/\(economyFixtures.fixtures.count)",
                "delivery/conservation: \(agent.lastDeliveryOutcome?.status.rawValue ?? "none") / \(snapshot.conservation.balanced ? "exact" : "diverged")",
                "build: \(snapshot.buildAutoEnabled ? "on" : "off") \(snapshot.constructionProject?.status.rawValue ?? "none") cells \(snapshot.constructionProject?.placedCellIndices.count ?? 0)/9 next \(snapshot.constructionProject?.nextCellIndex ?? 0)",
                String(format: "survival: %@ %@ h/f %.2f/%.2f hp %d consumed %d", snapshot.survivalEnabled ? "on" : "off", survival?.status.rawValue ?? "off", agent.needs.hunger, agent.needs.fatigue, agent.health, snapshot.conservation.consumedTotal),
                "resourceSeen: \(resourceSeen)",
                "natural: \(snapshot.naturalResourcesEnabled ? "on" : "off") gate \(naturalGateEnabled ? "on" : "off") scan \(naturalState.lastScan.worldBlockReadCount)/\(naturalState.lastScan.candidateCount)/\(naturalState.lastScan.observationsEmitted) harvest/rollback \(naturalState.harvestCount)/\(naturalState.rollbackCount)",
                "activeTarget: \(activeTarget)",
                "reservation: \(agent.resourceReservation?.agentId ?? "none")  navigation: \(route)",
                "next/replans/failure: \(nextStep) / \(navigation.replanCount) / \(navigation.lastFailure?.rawValue ?? navigation.lastInvalidation?.rawValue ?? "none")",
                "interaction: \(interaction.active ? (interaction.harvested ? "harvested" : "ready") : "inactive") target \(interactionTarget) auto \(interaction.autoEnabled ? "on" : "off")",
                "outcome: \(interactionOutcome?.status.rawValue ?? "none") delta \(interactionOutcome?.inventoryDelta.quantity ?? 0) memory \(interactionMemory)",
                "rollback: \(interaction.rollbackCount) \(Self.short(interaction.lastRollback, limit: 30))",
                "errors: \(runtimeErrorCount)  catchup dropped: \(droppedCatchUpSteps)",
            ] + socialLines + physicalLines + cooperationLines + populationLines
            return
        }

        globalLines = [
            "PEBBLE AGENTS - 3D LIVE PROTOTYPE",
            "mode: full  demo: \(demoActive ? "on" : "off")  follow: \(followMode.statusText)",
            movementEnabled ? "movement: enabled / safe cardinal steps" : "movement: disabled / intent only",
            "status: \(status)",
            "seed: \(snapshot.seed)  tick: \(snapshot.tick)  cognitive: \(cognitiveHz) Hz",
            "sim=\(causalSummary.simulationID.rawValue) tick=\(causalSummary.currentTick.rawValue) seq=\(causalSummary.latestSequence) events=\(causalSummary.retainedEventCount) dropped=\(causalSummary.droppedEventCount)",
            "worldTick: \(worldTick.map(String.init) ?? "none")",
            "agents: \(snapshot.agentCount)  focus: \(agent.id)",
        ] + Self.goalLines(observedGoalKinds)
            + ["errors: \(runtimeErrorCount)  catchup dropped: \(droppedCatchUpSteps)"]
            + (lastError.map { ["last error: \(Self.short($0))"] } ?? [])

        let action = agent.lastAction
        let deltas = action.map {
            "(\($0.dx.map(String.init) ?? "nil"), \($0.dy.map(String.init) ?? "nil"), \($0.dz.map(String.init) ?? "nil"))"
        } ?? "n/a"
        let nearby = agent.nearbyAgents.map(\.id).joined(separator: ", ")
        let worldLines: [String]
        if let observation = agent.lastWorldObservation,
           let effect = agent.lastWorldPerceptionEffect {
            let weather = observation.thundering ? "thunder" : observation.raining ? "rain" : "clear"
            worldLines = [
                "world sensed from: \(Self.position(observation.position)) tick: \(observation.worldTick)",
                "biome: \(observation.biomeName ?? "unknown") time: \(observation.dayTime) \(weather)",
                "light c/s/b: \(observation.combinedLight.map(String.init) ?? "?")/\(observation.skyLight.map(String.init) ?? "?")/\(observation.blockLight.map(String.init) ?? "?") surfaceY: \(observation.center.surfaceY.map(String.init) ?? "?")",
                "center ready/ground: \(observation.center.chunkReady)/\(observation.center.groundPresent) feet/head: \(observation.center.feetClear)/\(observation.center.headClear)",
                "neighbors t/b/d: \(observation.traversableNeighborCount)/\(observation.blockedNeighborCount)/\(observation.dangerousDropCount)",
                "perception: \(Self.short(effect.reason))",
                String(format: "safety %.2f>%.2f fear %d>%d", effect.safetyBefore, effect.safetyAfter, effect.fearBefore, effect.fearAfter),
                String(format: "curiosity %.3f>%.3f observations: %d", effect.curiosityBefore, effect.curiosityAfter, agent.observationCount),
            ]
        } else {
            worldLines = ["world perception: none observations: \(agent.observationCount)"]
        }
        var feedbackLines = [
            "feedback write/dedup/retrieved/used: \(agent.feedbackMemoryWriteCount)/\(agent.feedbackMemoryDeduplicatedCount)/\(agent.memoryRetrievalCount)/\(agent.memoryInfluencedDecisionCount)",
        ]
        if let decision = currentFeedback, let memory = decision.memoryRecordsUsed.first {
            if let lastInfluencedDecisionAgentId {
                feedbackLines.append("decision agent: \(lastInfluencedDecisionAgentId)")
            }
            feedbackLines.append("memory used: \(memory.type)@\(memory.tick) age \(memory.ageTicks)")
            feedbackLines.append("memory summary: \(Self.short(memory.summary, limit: 26))")
            let base = decision.baseDirection?.rawValue ?? decision.baseAction.name
            let final = decision.finalDirection?.rawValue ?? decision.finalAction.name
            feedbackLines.append("decision: \(base) > \(final) changed")
            feedbackLines.append("dominant: \(decision.dominantFactor.kind.rawValue)")
            feedbackLines.append("feedback reason: \(Self.short(decision.reason, limit: 30))")
        } else {
            feedbackLines.append("memory used: none dominant: basePolicy")
            feedbackLines.append("decision: base action retained")
        }
        var movementLines: [String] = []
        if let movement = agent.lastMovementOutcome {
            movementLines.append("last move: \(movement.status.rawValue) request: \(movement.requestedDirection?.rawValue ?? "none")")
            movementLines.append("move from/to: \(Self.position(movement.fromPosition)) > \(Self.position(movement.toPosition))")
            movementLines.append("applied: \(movement.appliedDX),\(movement.appliedDY),\(movement.appliedDZ) \(Self.short(movement.resolutionReason, limit: 22))")
        } else {
            movementLines.append("last movement: none")
        }
        movementLines.append("move count/dist/home/reduced: \(agent.movementCount)/\(agent.totalManhattanDistanceMoved)/\(agent.returnHomeMoveCount)/\(agent.totalDistanceReducedTowardHome)")

        let fullResourceSeen = agent.lastResourceObservations.first.map {
            "\($0.resource.rawValue)@\(Self.position($0.target)) \($0.direction.rawValue) distance \($0.distanceManhattan) \($0.source.rawValue)#\($0.expectedBlockFingerprint.map(String.init) ?? "none")"
        } ?? "none"
        let fullActiveTarget = agent.activeResourceTarget.map {
            "\(Self.position($0.target)) \($0.source.rawValue)#\($0.expectedBlockFingerprint.map(String.init) ?? "none") selected \($0.selectedAtTick) seen \($0.lastSeenAtTick)"
        } ?? "none"
        let reservationExpiry = agent.resourceReservation.map { String($0.expiresAtTick) } ?? "none"
        let navigationNext = agent.navigationProgress.nextStep.map(Self.position) ?? "none"
        var lines = [
            "FOCUS - \(agent.id)",
            "current position: \(Self.position(agent.position)) state: \(agent.state)",
            "home position: \(Self.position(agent.homePosition)) distance: \(agent.distanceFromHome)",
        ] + feedbackLines + movementLines + worldLines + [
            String(format: "needs h %.3f f %.3f c %.3f s %.3f", agent.needs.hunger, agent.needs.fatigue, agent.needs.curiosity, agent.needs.safety),
            "dominant: \(Self.dominantNeed(agent.needs)) fear: \(agent.fear) health: \(agent.health)",
            "goal: \(agent.currentGoal.kind.rawValue) urgency: \(agent.currentGoal.urgency)",
            "goal reason: \(Self.short(agent.currentGoal.reason))",
            "action: \(action?.name ?? "none") deltas: \(deltas)",
            "action target/resource: \(action?.target.map(Self.position) ?? "none") / \(action?.resource?.rawValue ?? "none")",
            "reason/effect: \(Self.short(action?.reason ?? "none", limit: 18)) / \(Self.short(agent.lastActionEffect?.effect ?? "none", limit: 18))",
            "nearby: \(nearby.isEmpty ? "none" : nearby) memory: \(agent.memoryCount)",
            "inventory total/capacity: \(agent.resourceInventory.totalCount)/\(agent.resourceInventory.capacity)",
            "inventory sandbox/food/wood/stone: \(agent.resourceInventory.count(of: .sandboxResource))/\(agent.resourceInventory.count(of: .foodRaw))/\(agent.resourceInventory.count(of: .wood))/\(agent.resourceInventory.count(of: .stone))",
            "economy/quota/reason: \(snapshot.economyEnabled ? "on" : "off") / \(snapshot.deliveryQuota) / \(Self.short(economyReason, limit: 22))",
            "camp stock sandbox/food/wood/stone: \(snapshot.campStock.count(of: .sandboxResource))/\(snapshot.campStock.count(of: .foodRaw))/\(snapshot.campStock.count(of: .wood))/\(snapshot.campStock.count(of: .stone))",
            "fixtures available/harvested: \(economyFixtures.fixtures.filter { !$0.harvested }.count)/\(economyFixtures.fixtures.filter(\.harvested).count)",
            "delivery outcome/memory: \(agent.lastDeliveryOutcome?.status.rawValue ?? "none") / \(agent.recentMemory.last { $0.type == "resource_delivered" }?.type ?? "none")",
            "survival/status: \(snapshot.survivalEnabled ? "on" : "off") / \(agent.survivalProgress?.status.rawValue ?? "off")",
            String(format: "hunger %.2f threshold/recovery %.2f/%.2f", agent.needs.hunger, snapshot.survivalConfiguration.hungryThreshold, snapshot.survivalConfiguration.hungerRecoveryThreshold),
            String(format: "fatigue %.2f threshold/recovery %.2f/%.2f health %d", agent.needs.fatigue, snapshot.survivalConfiguration.fatigueThreshold, snapshot.survivalConfiguration.fatigueRecoveryThreshold, agent.health),
            "critical/food consumed/starvation damage: \(agent.survivalProgress?.consecutiveCriticalHungerTicks ?? 0)/\(agent.survivalProgress?.foodConsumedCount ?? 0)/\(agent.survivalProgress?.starvationDamageTaken ?? 0)",
            "consumption outcome/memory: \(agent.survivalProgress?.lastConsumptionOutcome?.status.rawValue ?? "none") / \(agent.survivalProgress?.lastMemoryType?.rawValue ?? agent.recentMemory.last { $0.type == "food_consumed" || $0.type == "consumption_blocked" || $0.type == "starvation_damage" }?.type ?? "none")",
            "conservation harvested=carried+stock+consumed+escrow+constructed: \(snapshot.conservation.harvestedTotal)=\(snapshot.conservation.carriedTotal)+\(snapshot.conservation.campStockTotal)+\(snapshot.conservation.consumedTotal)+\(snapshot.conservation.constructionEscrowTotal)+\(snapshot.conservation.constructedTotal) \(snapshot.conservation.balanced ? "exact" : "diverged")",
            "build gate/auto/project: \(buildGateEnabled ? "on" : "off") / \(snapshot.buildAutoEnabled ? "on" : "off") / \(snapshot.constructionProject?.projectId ?? "none")",
            "blueprint/status/origin: \(snapshot.constructionProject?.blueprintId ?? AgentBlueprint.fixedLeanToV1Id) / \(snapshot.constructionProject?.status.rawValue ?? "none") / \(snapshot.constructionProject.map { Self.position($0.origin) } ?? "none")",
            "materials required wood/stone: 6/3 escrow \(snapshot.constructionProject?.materialEscrow.count(of: .wood) ?? 0)/\(snapshot.constructionProject?.materialEscrow.count(of: .stone) ?? 0)",
            "constructed wood/stone: \(snapshot.constructionProject?.placedMaterialTotals.count(of: .wood) ?? 0)/\(snapshot.constructionProject?.placedMaterialTotals.count(of: .stone) ?? 0) cells \(snapshot.constructionProject?.placedCellIndices.count ?? 0)/9",
            "next cell/target/work: \(snapshot.constructionProject?.nextCellIndex ?? 0) / \(snapshot.constructionProject?.nextTarget.map(Self.position) ?? "none") / \(snapshot.constructionProject?.nextWorkPosition.map(Self.position) ?? "none")",
            "construction world placed/rollback: \(constructionState.placedCount)/\(constructionState.rollbackCount) last \(Self.short(constructionState.lastPlacement, limit: 26))",
            "construction failure/clear: \(Self.short(snapshot.constructionProject?.lastFailure?.rawValue ?? constructionState.lastFailure, limit: 24)) / \(Self.short(constructionState.lastClear, limit: 24))",
            "site candidates/reads/origin: \(constructionSiteDiagnostics.candidatesConsidered)/\(constructionSiteDiagnostics.positionsRead)/\(constructionSiteDiagnostics.selectedOrigin.map(Self.position) ?? "none")",
            "shelter rest/home/reason: \(snapshot.constructionProject.map { Self.position($0.restPosition) } ?? "none") / \(Self.position(agent.homePosition)) / \(Self.short(constructionReason, limit: 24))",
            "natural gate/mode/radius/vertical: \(naturalGateEnabled ? "on" : "off") / \(snapshot.naturalResourcesEnabled ? "on" : "off") / \(PebbleAgentNaturalResourceAdapter.configuration.horizontalRadius) / -\(PebbleAgentNaturalResourceAdapter.configuration.verticalBelow)...+\(PebbleAgentNaturalResourceAdapter.configuration.verticalAbove)",
            "natural scan read/candidate/emitted/mapped: \(naturalState.lastScan.worldBlockReadCount)/\(naturalState.lastScan.candidateCount)/\(naturalState.lastScan.observationsEmitted)/\(naturalState.lastScan.mappedBlockCount)",
            "natural harvest/rollback/last: \(naturalState.harvestCount)/\(naturalState.rollbackCount) / \(Self.short(naturalState.lastHarvest, limit: 28)) / \(Self.short(naturalState.lastRollback, limit: 28))",
            "resource seen: \(fullResourceSeen)",
            "active resource target: \(fullActiveTarget)",
            "resource reservation owner: \(agent.resourceReservation?.agentId ?? "none") expires: \(reservationExpiry)",
            "navigation status/route/index: \(agent.navigationProgress.status.rawValue) / \(agent.navigationProgress.route?.positions.count ?? 0) / \(agent.navigationProgress.routeIndex)",
            "navigation destination: \(agent.navigationProgress.route?.purpose.rawValue ?? "none") @ \(agent.navigationProgress.route.map { Self.position($0.target) } ?? "none")",
            "navigation remaining/next/replans: \(agent.navigationProgress.stepsRemaining) / \(navigationNext) / \(agent.navigationProgress.replanCount)",
            "navigation invalidation/failure: \(agent.navigationProgress.lastInvalidation?.rawValue ?? "none") / \(agent.navigationProgress.lastFailure?.rawValue ?? "none")",
            "interaction target/status: \(interaction.target.map(Self.position) ?? "none") / \(interaction.active ? (interaction.harvested ? "harvested" : "ready") : "inactive") auto: \(interaction.autoEnabled ? "on" : "off")",
            "interaction auto reason: \(Self.short(interaction.autoReason, limit: 28))",
            "interaction outcome: \(agent.lastInteractionOutcome?.status.rawValue ?? "none") reason: \(Self.short(agent.lastInteractionOutcome?.reason ?? "none", limit: 24))",
            "interaction delta/memory: \(agent.lastInteractionOutcome?.inventoryDelta.quantity ?? 0) / \(agent.recentMemory.last?.type ?? "none")",
            "interaction rollback: \(interaction.rollbackCount) \(Self.short(interaction.lastRollback, limit: 28))",
        ]
        lines += socialLines
        lines += physicalLines
        lines += cooperationLines
        lines += populationLines
        lines.append("ticks: \(agent.ticksAlive) goals: \(agent.goalChangeCount) actions/effects: \(agent.actionCount)/\(agent.actionEffectCount)")
        focusedAgentLines = lines
    }

    private static func dominantNeed(_ needs: AgentNeedsSnapshot) -> String {
        let values = [
            ("hunger", needs.hunger),
            ("fatigue", needs.fatigue),
            ("curiosity", needs.curiosity),
            ("safety", 1 - needs.safety),
        ]
        return values.max { $0.1 < $1.1 }?.0 ?? "none"
    }

    private static func socialLines(
        snapshot: AgentSocialSnapshot,
        focusedAgentId: String
    ) -> [String] {
        guard snapshot.enabled else { return [] }
        let beliefs = snapshot.beliefs.filter { $0.ownerID.rawValue == focusedAgentId }
        let pending = beliefs.filter { $0.status == .unverified }.count
        let confirmed = beliefs.filter { $0.status == .confirmed }.count
        let contradicted = beliefs.filter { $0.status == .contradicted }.count
        let verification = snapshot.activeVerifications.first {
            $0.verifierID.rawValue == focusedAgentId
        }
        let trust = snapshot.trustRelations.filter {
            $0.sourceID.rawValue == focusedAgentId
        }.map {
            "\($0.targetID.rawValue):\($0.score)"
        }.joined(separator: ",")
        let message = snapshot.messages.filter {
            $0.senderID.rawValue == focusedAgentId || $0.recipientID.rawValue == focusedAgentId
        }.max {
            if $0.sentAtTick != $1.sentAtTick { return $0.sentAtTick < $1.sentAtTick }
            return $0.messageID < $1.messageID
        }
        let fact = snapshot.facts.filter {
            $0.observerID.rawValue == focusedAgentId
        }.max {
            if $0.observedAtTick != $1.observedAtTick {
                return $0.observedAtTick < $1.observedAtTick
            }
            return $0.factID < $1.factID
        }
        let belief = beliefs.max {
            if $0.receivedAtTick != $1.receivedAtTick {
                return $0.receivedAtTick < $1.receivedAtTick
            }
            return $0.beliefID < $1.beliefID
        }
        return [
            "social=on beliefs=\(pending)/\(confirmed)/\(contradicted)",
            "verify=\(verification.map { position($0.position) } ?? "none") trust=\(trust.isEmpty ? "none" : trust)",
            "lastMessage=\(message?.messageID.rawValue ?? "none")",
            "social fact=\(fact.map { "\($0.resource.rawValue)@\(position($0.position)) by \($0.observerID.rawValue)" } ?? "none")",
            "social belief=\(belief.map { "\($0.status.rawValue) from \($0.senderID.rawValue): \(short($0.reason, limit: 22))" } ?? "none")",
            "social cause=\(belief?.verificationEventID?.rawValue ?? fact?.directObservationEventID.rawValue ?? "none")",
        ]
    }

    private static func physicalLines(
        snapshot: AgentPhysicalChannelSnapshot,
        focusedAgentId: String
    ) -> [String] {
        guard snapshot.enabled else { return [] }
        let signal = snapshot.signals.filter {
            $0.senderID.rawValue == focusedAgentId
                || $0.intendedRecipientID.rawValue == focusedAgentId
        }.last
        let perception = signal.flatMap { selected in
            snapshot.perceptions.filter {
                $0.signalID == selected.signalID
                    && ($0.observerID.rawValue == focusedAgentId || $0.isIntendedRecipient)
            }.last
        }
        let pose = signal.map { selected in
            snapshot.presentations.contains {
                $0.signalID == selected.signalID && $0.presentedAtTick != nil
                    && snapshot.tick <= $0.expiresAtTick
            }
        } ?? false
        return [
            "physical=on",
            "signal=\(signal?.signalID.rawValue ?? "none")",
            "channel=\(perception?.outcome.rawValue ?? "none")",
            "sound=\(perception?.soundClarity ?? 0) gesture=\(perception?.gestureClarity ?? 0)",
            "gesturePose=\(pose ? "on" : "off")",
        ]
    }

    private static func cooperationLines(
        snapshot: AgentCooperationSnapshot,
        focusedAgentId: String
    ) -> [String] {
        guard snapshot.enabled else { return [] }
        let task = snapshot.tasks.filter {
            $0.issuerID.rawValue == focusedAgentId || $0.helperID.rawValue == focusedAgentId
        }.last
        let role: String
        if task?.issuerID.rawValue == focusedAgentId {
            role = "issuer"
        } else if task?.helperID.rawValue == focusedAgentId {
            role = "helper"
        } else {
            role = "none"
        }
        let partner = task.map {
            $0.issuerID.rawValue == focusedAgentId
                ? $0.helperID.rawValue
                : $0.issuerID.rawValue
        } ?? "none"
        let reliability = task.flatMap { selected in
            snapshot.relations.first {
                $0.issuerID == selected.issuerID && $0.helperID == selected.helperID
            }?.reliabilityScore
        } ?? 0
        return [
            "cooperation=on",
            "task=\(task?.taskID.rawValue ?? "none") role=\(role)",
            "taskStatus=\(task?.status.rawValue ?? "none")",
            "taskResource=\(task.map { "\($0.resource.rawValue) \($0.contributedQuantity)/\($0.requestedQuantity)" } ?? "none")",
            "partner=\(partner) reliability=\(reliability)",
        ]
    }

    private static func populationLines(
        snapshot: AgentPopulationSnapshot,
        focusedAgentId: String
    ) -> [String] {
        guard snapshot.enabled,
              let member = snapshot.members.first(where: {
                  $0.agentID.rawValue == focusedAgentId
              }) else {
            return []
        }
        let migration = member.migrationID.flatMap { migrationID in
            snapshot.migrations.first { $0.migrationID == migrationID }
        }
        let capacity = snapshot.settlement?.capacity ?? 0
        let progress = migration.map {
            "\($0.routeCursor)/\(max(0, $0.route.count - 1))"
        } ?? "none"
        return [
            "population=on settlement=\(member.settlementID.rawValue) population=\(snapshot.members.count)/\(capacity)",
            "memberStatus=\(member.status.rawValue) migration=\(migration?.migrationID.rawValue ?? "none") migrationProgress=\(progress)",
        ]
    }

    private static func goalLines(_ goals: [String]) -> [String] {
        var lines: [String] = []
        var current = "goals:"
        for goal in goals {
            let candidate = current == "goals:" ? "\(current) \(goal)" : "\(current), \(goal)"
            if candidate.count > 34 {
                lines.append(current)
                current = "goals+: \(goal)"
            } else {
                current = candidate
            }
        }
        lines.append(current)
        return lines
    }

    private static func short(_ text: String, limit: Int = 32) -> String {
        guard text.count > limit else { return text }
        return String(text.prefix(limit - 1)) + "~"
    }

    private static func position(_ position: AgentPosition) -> String {
        "\(position.x),\(position.y),\(position.z)"
    }
}
