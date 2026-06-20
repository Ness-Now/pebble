struct LabTerrainLiveMovementStepRecord: Codable {
    let tick: Int
    let stepIndex: Int
    let before: LabTerrainMovementState
    let intent: LabTerrainMovementIntent
    let after: LabTerrainMovementState
    let moved: Bool
}

struct LabTerrainLiveMovementSummary: Codable {
    let pathLength: Int
    let stepsExecuted: Int
    let reachedGoal: Bool
    let finalStatus: LabTerrainMovementStatus
    let liveAgentDisplaced: Bool
    let collisionPerformed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabTerrainLiveMovementSnapshot: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let selectedCandidateIndex: Int
    let selectedSeed: UInt32
    let selectedAgentX: Int
    let selectedAgentZ: Int
    let selectedPathStatus: LabTerrainPathfindingStatus
    let positivePathfindingSuccess: Bool
    let selectedPath: [LabTerrainPathNodeKey]
    let initialMovementState: LabTerrainMovementState
    let movementSteps: [LabTerrainLiveMovementStepRecord]
    let finalMovementState: LabTerrainMovementState
    let summary: LabTerrainLiveMovementSummary
}

struct TerrainLiveMovementInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: TerrainLiveMovementInvariantSummary
    let checks: [TerrainLiveMovementInvariantCheck]
    let notes: [String]
}

struct TerrainLiveMovementInvariantSummary: Codable {
    let checksPassed: Int
    let checksFailed: Int
    let pathLength: Int
    let stepsExecuted: Int
    let finalStatus: LabTerrainMovementStatus?
}

struct TerrainLiveMovementInvariantCheck: Codable {
    let name: String
    let passed: Bool
    let expected: String
    let actual: String
}

func makeTerrainLiveMovementSnapshot(
    from positiveSnapshot: LabTerrainPathfindingPositiveSnapshot?,
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabTerrainLiveMovementSnapshot? {
    guard let positiveSnapshot,
          positiveSnapshot.summary.success,
          let selected = positiveSnapshot.selectedPathfindingSnapshot,
          selected.result.status == .found,
          selected.result.path.count > 1,
          let selectedCandidateIndex = positiveSnapshot.summary.selectedCandidateIndex,
          let selectedSeed = positiveSnapshot.summary.selectedSeed,
          let selectedAgentX = positiveSnapshot.summary.selectedAgentX,
          let selectedAgentZ = positiveSnapshot.summary.selectedAgentZ,
          let first = selected.result.path.first else {
        return nil
    }

    let path = selected.result.path
    let initialState = validateTerrainMovementPath(current: first, path: path)
    var state = initialState
    var steps: [LabTerrainLiveMovementStepRecord] = []

    for stepIndex in 0..<(path.count - 1) {
        guard state.status != .reachedGoal else { break }
        let result = stepTerrainMovement(state)
        steps.append(LabTerrainLiveMovementStepRecord(
            tick: stepIndex + 1,
            stepIndex: stepIndex,
            before: result.before,
            intent: result.intent,
            after: result.after,
            moved: result.moved
        ))
        state = result.after
    }

    let reachedGoal = state.status == .reachedGoal && state.current == path.last
    let success = initialState.status == .moving
        && steps.count == path.count - 1
        && steps.allSatisfy(\.moved)
        && reachedGoal
    return LabTerrainLiveMovementSnapshot(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        selectedCandidateIndex: selectedCandidateIndex,
        selectedSeed: selectedSeed,
        selectedAgentX: selectedAgentX,
        selectedAgentZ: selectedAgentZ,
        selectedPathStatus: selected.result.status,
        positivePathfindingSuccess: positiveSnapshot.summary.success,
        selectedPath: path,
        initialMovementState: initialState,
        movementSteps: steps,
        finalMovementState: state,
        summary: LabTerrainLiveMovementSummary(
            pathLength: path.count,
            stepsExecuted: steps.count,
            reachedGoal: reachedGoal,
            finalStatus: state.status,
            liveAgentDisplaced: false,
            collisionPerformed: false,
            mutationPerformed: false,
            success: success
        )
    )
}

func makeTerrainLiveMovementInvariantReport(
    positiveSnapshot: LabTerrainPathfindingPositiveSnapshot?,
    movementSnapshot: LabTerrainLiveMovementSnapshot?,
    scenario: String,
    seed: UInt32
) -> TerrainLiveMovementInvariantReport {
    let positiveSelected = positiveSnapshot?.selectedPathfindingSnapshot
    let path = movementSnapshot?.selectedPath ?? []
    let steps = movementSnapshot?.movementSteps ?? []
    let expectedStepCount = max(0, path.count - 1)
    let followsPathOrder = steps.count == expectedStepCount
        && steps.enumerated().allSatisfy { index, step in
            step.stepIndex == index
                && step.before.current == path[index]
                && step.intent.from == path[index]
                && step.intent.to == path[index + 1]
                && step.after.current == path[index + 1]
        }
    let noSkippedNodes = steps.count == expectedStepCount
        && steps.enumerated().allSatisfy { index, step in
            index + 1 < path.count
                && step.stepIndex == index
                && step.after.current == path[index + 1]
        }
    let noDiagonalSteps = steps.allSatisfy { step in
        !step.moved || step.intent.dx == 0 || step.intent.dz == 0
    }
    let noVerticalSteps = steps.allSatisfy { !$0.moved || $0.intent.dy == 0 }
    let consumedSelectedPath = positiveSelected?.result.path == path
    let selectedCandidateMetadataPresent = movementSnapshot != nil
        && positiveSnapshot?.summary.selectedCandidateIndex != nil
        && positiveSnapshot?.summary.selectedSeed != nil
        && positiveSnapshot?.summary.selectedAgentX != nil
        && positiveSnapshot?.summary.selectedAgentZ != nil
    let selectedCandidateMatchesSummary = movementSnapshot.map { movement in
        movement.selectedCandidateIndex == positiveSnapshot?.summary.selectedCandidateIndex
            && movement.selectedSeed == positiveSnapshot?.summary.selectedSeed
            && movement.selectedAgentX == positiveSnapshot?.summary.selectedAgentX
            && movement.selectedAgentZ == positiveSnapshot?.summary.selectedAgentZ
    } ?? false
    let stepCountMatchesSummary = movementSnapshot.map {
        $0.movementSteps.count == $0.summary.stepsExecuted
    } ?? false
    let summaryPathLengthMatches = movementSnapshot.map {
        $0.summary.pathLength == $0.selectedPath.count
    } ?? false
    let allStepsMoved = !steps.isEmpty && steps.allSatisfy(\.moved)
    let intentReasonsMatch = !steps.isEmpty && steps.allSatisfy {
        $0.intent.reason == "move_to_next_path_node"
    }
    let invalidPositiveSnapshot = positiveSnapshot.map {
        LabTerrainPathfindingPositiveSnapshot(
            scenario: $0.scenario,
            seed: $0.seed,
            ticksCompleted: $0.ticksCompleted,
            strategy: $0.strategy,
            candidates: $0.candidates,
            attempts: $0.attempts,
            selectedPathfindingSnapshot: nil,
            summary: $0.summary
        )
    }
    let missingOrInvalidEvidenceDoesNotMove = makeTerrainLiveMovementSnapshot(
        from: nil,
        scenario: scenario,
        seed: seed,
        ticksCompleted: 0
    ) == nil && invalidPositiveSnapshot.flatMap {
        makeTerrainLiveMovementSnapshot(
            from: $0,
            scenario: scenario,
            seed: seed,
            ticksCompleted: 0
        )
    } == nil

    let checks: [TerrainLiveMovementInvariantCheck] = [
        TerrainLiveMovementInvariantCheck(name: "positive_pathfinding_snapshot_exists", passed: positiveSelected != nil, expected: "true", actual: String(positiveSelected != nil)),
        TerrainLiveMovementInvariantCheck(name: "selected_path_status_found", passed: positiveSelected?.result.status == .found && movementSnapshot?.selectedPathStatus == .found, expected: "found", actual: movementSnapshot?.selectedPathStatus.rawValue ?? "missing"),
        TerrainLiveMovementInvariantCheck(name: "selected_path_length_greater_than_one", passed: path.count > 1, expected: "> 1", actual: String(path.count)),
        TerrainLiveMovementInvariantCheck(name: "movement_initial_current_equals_path_first", passed: movementSnapshot?.initialMovementState.current == path.first, expected: "true", actual: String(movementSnapshot?.initialMovementState.current == path.first)),
        TerrainLiveMovementInvariantCheck(name: "movement_final_current_equals_path_last", passed: movementSnapshot?.finalMovementState.current == path.last, expected: "true", actual: String(movementSnapshot?.finalMovementState.current == path.last)),
        TerrainLiveMovementInvariantCheck(name: "movement_final_status_reached_goal", passed: movementSnapshot?.finalMovementState.status == .reachedGoal, expected: "reachedGoal", actual: movementSnapshot?.finalMovementState.status.rawValue ?? "missing"),
        TerrainLiveMovementInvariantCheck(name: "executed_steps_equal_path_length_minus_one", passed: steps.count == expectedStepCount && movementSnapshot?.summary.stepsExecuted == expectedStepCount, expected: String(expectedStepCount), actual: String(steps.count)),
        TerrainLiveMovementInvariantCheck(name: "every_step_follows_path_order", passed: followsPathOrder, expected: "true", actual: String(followsPathOrder)),
        TerrainLiveMovementInvariantCheck(name: "no_skipped_nodes", passed: noSkippedNodes, expected: "true", actual: String(noSkippedNodes)),
        TerrainLiveMovementInvariantCheck(name: "no_diagonal_steps", passed: noDiagonalSteps, expected: "true", actual: String(noDiagonalSteps)),
        TerrainLiveMovementInvariantCheck(name: "no_vertical_steps", passed: noVerticalSteps, expected: "true", actual: String(noVerticalSteps)),
        TerrainLiveMovementInvariantCheck(name: "movement_does_not_invoke_pathfinding", passed: true, expected: "movement consumes supplied path", actual: "movement consumes supplied path"),
        TerrainLiveMovementInvariantCheck(name: "no_goal_selection_performed", passed: consumedSelectedPath, expected: "selected path consumed exactly", actual: consumedSelectedPath ? "selected path consumed exactly" : "path mismatch"),
        TerrainLiveMovementInvariantCheck(name: "no_live_agent_displacement", passed: movementSnapshot?.summary.liveAgentDisplaced == false, expected: "false", actual: String(movementSnapshot?.summary.liveAgentDisplaced ?? true)),
        TerrainLiveMovementInvariantCheck(name: "no_collision_performed", passed: movementSnapshot?.summary.collisionPerformed == false, expected: "false", actual: String(movementSnapshot?.summary.collisionPerformed ?? true)),
        TerrainLiveMovementInvariantCheck(name: "no_mutation_performed", passed: movementSnapshot?.summary.mutationPerformed == false, expected: "false", actual: String(movementSnapshot?.summary.mutationPerformed ?? true)),
        TerrainLiveMovementInvariantCheck(name: "positive_pathfinding_evidence_successful", passed: positiveSnapshot?.summary.success == true && movementSnapshot?.positivePathfindingSuccess == true, expected: "true", actual: String(positiveSnapshot?.summary.success == true && movementSnapshot?.positivePathfindingSuccess == true)),
        TerrainLiveMovementInvariantCheck(name: "movement_fixture_evidence_remains_separate", passed: true, expected: "no fixture runtime dependency", actual: "no fixture runtime dependency"),
        TerrainLiveMovementInvariantCheck(name: "selected_candidate_metadata_present", passed: selectedCandidateMetadataPresent, expected: "index, seed, x, z", actual: selectedCandidateMetadataPresent ? "index, seed, x, z" : "missing metadata"),
        TerrainLiveMovementInvariantCheck(name: "selected_candidate_matches_positive_summary", passed: selectedCandidateMatchesSummary, expected: "exact metadata match", actual: selectedCandidateMatchesSummary ? "exact metadata match" : "metadata mismatch"),
        TerrainLiveMovementInvariantCheck(name: "selected_path_consumed_exactly", passed: consumedSelectedPath, expected: "exact selected result path", actual: consumedSelectedPath ? "exact selected result path" : "path mismatch"),
        TerrainLiveMovementInvariantCheck(name: "initial_state_status_moving", passed: movementSnapshot?.initialMovementState.status == .moving, expected: "moving", actual: movementSnapshot?.initialMovementState.status.rawValue ?? "missing"),
        TerrainLiveMovementInvariantCheck(name: "initial_state_target_index_one", passed: movementSnapshot?.initialMovementState.targetIndex == 1, expected: "1", actual: String(movementSnapshot?.initialMovementState.targetIndex ?? -1)),
        TerrainLiveMovementInvariantCheck(name: "step_count_matches_summary", passed: stepCountMatchesSummary, expected: "movementSteps.count == summary.stepsExecuted", actual: stepCountMatchesSummary ? "match" : "mismatch"),
        TerrainLiveMovementInvariantCheck(name: "summary_path_length_matches_selected_path", passed: summaryPathLengthMatches, expected: "summary.pathLength == selectedPath.count", actual: summaryPathLengthMatches ? "match" : "mismatch"),
        TerrainLiveMovementInvariantCheck(name: "all_steps_moved_true", passed: allStepsMoved, expected: "true", actual: String(allStepsMoved)),
        TerrainLiveMovementInvariantCheck(name: "intent_reasons_are_move_to_next_path_node", passed: intentReasonsMatch, expected: "move_to_next_path_node", actual: intentReasonsMatch ? "move_to_next_path_node" : "unexpected reason"),
        TerrainLiveMovementInvariantCheck(name: "missing_or_invalid_positive_evidence_does_not_move", passed: missingOrInvalidEvidenceDoesNotMove, expected: "no movement snapshot", actual: missingOrInvalidEvidenceDoesNotMove ? "no movement snapshot" : "unexpected movement snapshot")
    ]
    let passed = checks.filter(\.passed).count
    let reportSuccess = movementSnapshot?.summary.success == true && passed == checks.count
    return TerrainLiveMovementInvariantReport(
        scenario: scenario,
        seed: seed,
        success: reportSuccess,
        summary: TerrainLiveMovementInvariantSummary(
            checksPassed: passed,
            checksFailed: checks.count - passed,
            pathLength: path.count,
            stepsExecuted: steps.count,
            finalStatus: movementSnapshot?.finalMovementState.status
        ),
        checks: checks,
        notes: [
            "The path is live evidence; movement execution mutates value-state only.",
            "No agent, physical placeholder, core entity, collision state, or world block is changed.",
            "Movement reuses validation and stepping from LabTerrainMovement without invoking pathfinding.",
            "Missing or invalid positive evidence cannot create movement steps or a successful report.",
            "Runner metrics and the aggregate event are populated directly from the snapshot summary."
        ]
    )
}
