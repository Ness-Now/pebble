import Foundation
import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func debugState(f3Visible: Bool) -> PebbleAgentDebugState? {
        let mode = overlayModeByCommand
            ?? (f3Visible ? .full : overlayEnabledByEnvironment ? .compact : .off)
        guard let session, mode != .off else { return nil }
        let latestInfluenced = lastInfluencedTracesByAgentId.sorted {
            if $0.value.tick != $1.value.tick { return $0.value.tick > $1.value.tick }
            return $0.key < $1.key
        }.first
        let focusedInfluenced = focusedAgentId.flatMap { lastInfluencedTracesByAgentId[$0] }
        return PebbleAgentDebugState(
            snapshot: session.snapshot(),
            causalSummary: session.causalLedgerSnapshot().summary,
            socialSnapshot: session.socialSnapshot(),
            mode: mode,
            paused: isPaused,
            cognitiveHz: cognitiveHz,
            movementEnabled: movementEnabled,
            followMode: followMode,
            demoActive: demoActive,
            focusedAgentId: focusedAgentId,
            observedGoalKinds: observedGoalKinds.sorted(),
            lastInfluencedDecisionTrace: focusedInfluenced ?? latestInfluenced?.value,
            lastInfluencedDecisionAgentId: focusedInfluenced == nil ? latestInfluenced?.key : focusedAgentId,
            runtimeErrorCount: runtimeErrorCount,
            droppedCatchUpSteps: droppedCatchUpSteps,
            worldTick: lastWorldTick,
            lastError: lastError,
            interaction: interactionExecutor.state(
                gateEnabled: interactionFeatureEnabled,
                autoEnabled: autoInteractionEnabled,
                autoReason: lastAutoInteractionReason
            ),
            economyFixtures: interactionExecutor.economyState(),
            economyReason: lastEconomyReason,
            naturalGateEnabled: naturalFeatureEnabled,
            naturalState: naturalResourceExecutor.state,
            buildGateEnabled: buildFeatureEnabled,
            constructionState: constructionExecutor.state,
            constructionSiteDiagnostics: lastConstructionSiteDiagnostics,
            constructionReason: lastConstructionReason
        )
    }

    func effectiveOverlayMode(f3Visible: Bool) -> PebbleAgentOverlayMode {
        overlayModeByCommand
            ?? (f3Visible ? .full : overlayEnabledByEnvironment ? .compact : .off)
    }

    func followTargetId() -> String? {
        switch followMode {
        case .off: return nil
        case .focusedAgent: return focusedAgentId
        case let .fixedAgent(agentId): return agentId
        }
    }

    func applyFollow(player: Player) {
        guard followMode != .off else { return }
        guard let agentId = followTargetId(), let probe = probesByAgentId[agentId] else {
            let prior = followMode.statusText
            followMode = .off
            trace("follow off reason=target unavailable target=\(prior)")
            return
        }
        _ = cameraFollow.orient(player: player, toward: probe)
    }

}
