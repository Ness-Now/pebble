extension AgentSimulationSession {
    public mutating func createConstructionProject(_ project: AgentConstructionProject) throws {
        guard constructionProject == nil else {
            throw AgentSessionError.constructionProjectAlreadyExists
        }
        guard let builder = statesById[project.builderAgentId] else {
            throw AgentSessionError.unknownAgentId(project.builderAgentId)
        }
        guard project.blueprint == .fixedLeanToV1,
              project.previousHomePosition == builder.homePosition,
              project.status == .acquiringMaterials,
              project.placedCellIndices.isEmpty,
              project.materialEscrow.total == 0,
              project.placedMaterialTotals.total == 0 else {
            throw AgentSessionError.constructionBuilderMismatch(project.builderAgentId)
        }
        constructionProject = project
        buildAutoEnabled = false
    }

    public mutating func setBuildAutoEnabled(_ enabled: Bool) throws {
        let changed = buildAutoEnabled != enabled
        if enabled, constructionProject == nil {
            throw AgentSessionError.constructionProjectMissing
        }
        defer { if changed { recordFeatureToggle(name: "construction", enabled: enabled) } }
        if enabled, var project = constructionProject {
            project.resumeAfterRecoverableFailure()
            constructionProject = project
        }
        buildAutoEnabled = enabled
        guard !enabled, let project = constructionProject,
              var builder = statesById[project.builderAgentId] else { return }
        if builder.currentGoal.kind == .buildShelter {
            builder.currentGoal = AgentGoal(
                kind: .idle,
                reason: "construction suspended",
                startedAtTick: tick,
                urgency: 0
            )
            builder.navigationProgress = AgentNavigationProgress()
        }
        statesById[builder.id] = builder
    }

    public func constructionDemand() -> AgentConstructionDemand? {
        guard let project = constructionProject,
              let builder = statesById[project.builderAgentId],
              project.status == .planned
                || project.status == .acquiringMaterials
                || project.status == .readyToFund else { return nil }
        return AgentConstructionDemand(
            projectId: project.projectId,
            missing: project.missingMaterials(
                campStock: campStock,
                builderInventory: builder.resourceInventory
            )
        )
    }

    public func constructionMaterialSurveyTarget(
        for agentId: String,
        observations: [AgentResourceObservation],
        atTick surveyTick: Int
    ) -> AgentPosition? {
        guard let state = statesById[agentId],
              let eligible = constructionEligibleResources(for: state),
              !eligible.isEmpty else { return nil }
        let failedKeys = Set(failedNaturalResourceTargetKeysByAgentId[agentId] ?? [])
        let hasSelectableResource = observations.contains {
            eligible.contains($0.resource)
                && !failedKeys.contains($0.identity.stableKey)
                && state.resourceInventory.canAdd($0.resource)
        }
        guard !hasSelectableResource else { return nil }
        return AgentConstructionMaterialSurvey.horizontalTarget(
            home: state.homePosition,
            currentPosition: state.position,
            tick: surveyTick
        )
    }

    @discardableResult
    public mutating func fundConstructionProject(
        fundingId: String,
        builderAgentId: String,
        fundingTick: Int
    ) throws -> AgentConstructionProject {
        var candidate = self
        let project = try candidate.fundConstructionProjectInPlace(
            fundingId: fundingId,
            builderAgentId: builderAgentId,
            fundingTick: fundingTick
        )
        self = candidate
        return project
    }

    mutating func fundConstructionProjectInPlace(
        fundingId: String,
        builderAgentId: String,
        fundingTick: Int
    ) throws -> AgentConstructionProject {
        try prevalidateCausalAppend(count: 1)
        guard buildAutoEnabled else { throw AgentSessionError.constructionDisabled }
        guard fundingTick == tick else {
            throw AgentSessionError.constructionFundingTickMismatch(fundingId)
        }
        guard !processedConstructionFundingIds.contains(fundingId) else {
            throw AgentSessionError.duplicateConstructionFunding(fundingId)
        }
        guard processedConstructionFundingIds.count < Self.maximumConstructionEventCount else {
            throw AgentSessionError.constructionEventLimitReached
        }
        guard var project = constructionProject else {
            throw AgentSessionError.constructionProjectMissing
        }
        guard project.builderAgentId == builderAgentId,
              statesById[builderAgentId]?.position == statesById[builderAgentId]?.homePosition,
              project.status == .readyToFund || project.status == .acquiringMaterials,
              project.placedCellIndices.isEmpty else {
            throw AgentSessionError.invalidConstructionFunding(fundingId)
        }
        guard campStock.canRemove(project.materialRequirements) else {
            throw AgentSessionError.invalidConstructionFunding(fundingId)
        }
        var nextStock = campStock
        guard nextStock.remove(project.materialRequirements),
              let escrow = try? AgentConstructionMaterialState(
                  amounts: project.materialRequirements
              ) else {
            throw AgentSessionError.invalidConstructionFunding(fundingId)
        }
        project.fund(escrow)
        campStock = nextStock
        constructionProject = project
        guard conservationSnapshot().balanced else {
            throw AgentSessionError.invalidConstructionFunding(fundingId)
        }
        guard var builder = statesById[builderAgentId] else {
            throw AgentSessionError.unknownAgentId(builderAgentId)
        }
        appendMemory(AgentMemoryEntry(
            tick: tick,
            type: "construction_funded",
            summary: "\(project.projectId) funded with 6 wood and 3 stone",
            importance: 0.60
        ), to: &builder.memory)
        statesById[builderAgentId] = builder
        processedConstructionFundingIds.insert(fundingId)
        recordAcceptedOperation(
            kind: .constructionFunding,
            agentId: builderAgentId,
            operationId: fundingId,
            status: "funded",
            detail: project.projectId
        )
        return project
    }

    public func prevalidatePlacement(_ intent: AgentPlacementIntent) throws {
        guard buildAutoEnabled else { throw AgentSessionError.constructionDisabled }
        guard intent.tick == tick else {
            throw AgentSessionError.constructionPlacementTickMismatch(intent.placementId)
        }
        guard !processedConstructionPlacementIds.contains(intent.placementId) else {
            throw AgentSessionError.duplicateConstructionPlacement(intent.placementId)
        }
        guard lastConstructionPlacementTick != tick else {
            throw AgentSessionError.invalidConstructionPlacement(intent.placementId)
        }
        guard processedConstructionPlacementIds.count < Self.maximumConstructionEventCount else {
            throw AgentSessionError.constructionEventLimitReached
        }
        guard let project = constructionProject else {
            throw AgentSessionError.constructionProjectMissing
        }
        guard project.projectId == intent.projectId,
              project.builderAgentId == intent.builderAgentId,
              project.status == .funded || project.status == .building,
              project.nextCellIndex == intent.cellIndex,
              let cell = project.nextCell,
              cell.resource == intent.resource,
              project.nextTarget == intent.target,
              project.nextWorkPosition == intent.workPosition,
              project.materialEscrow.canRemove(intent.resource),
              statesById[intent.builderAgentId]?.position == intent.workPosition else {
            throw AgentSessionError.invalidConstructionPlacement(intent.placementId)
        }
    }

    public mutating func applyPlacementOutcome(_ outcome: AgentPlacementOutcome) throws {
        var candidate = self
        try candidate.applyPlacementOutcomeInPlace(outcome)
        self = candidate
    }

    public mutating func recordConstructionFailure(
        failureId: String,
        projectId: String,
        builderAgentId: String,
        failure: AgentConstructionFailure,
        reason: String
    ) throws {
        var candidate = self
        try candidate.recordConstructionFailureInPlace(
            failureId: failureId,
            projectId: projectId,
            builderAgentId: builderAgentId,
            failure: failure,
            reason: reason
        )
        self = candidate
    }

    mutating func recordConstructionFailureInPlace(
        failureId: String,
        projectId: String,
        builderAgentId: String,
        failure: AgentConstructionFailure,
        reason: String
    ) throws {
        guard !failureId.isEmpty,
              !processedConstructionFailureIds.contains(failureId),
              processedConstructionFailureIds.count < Self.maximumConstructionEventCount,
              var project = constructionProject,
              project.projectId == projectId,
              project.builderAgentId == builderAgentId,
              var builder = statesById[builderAgentId] else {
            throw AgentSessionError.invalidConstructionPlacement(failureId)
        }
        project.recordFailure(failure)
        appendMemory(AgentMemoryEntry(
            tick: tick,
            type: "construction_blocked",
            summary: "\(projectId) blocked: \(reason)",
            importance: 0.55
        ), to: &builder.memory)
        constructionProject = project
        statesById[builderAgentId] = builder
        processedConstructionFailureIds.insert(failureId)
        guard conservationSnapshot().balanced else {
            throw AgentSessionError.invalidConstructionPlacement(failureId)
        }
    }

    mutating func applyPlacementOutcomeInPlace(
        _ outcome: AgentPlacementOutcome
    ) throws {
        try prevalidateCausalAppend(count: 1)
        guard outcome.tick == tick else {
            throw AgentSessionError.constructionPlacementTickMismatch(outcome.placementId)
        }
        guard !processedConstructionPlacementIds.contains(outcome.placementId) else {
            throw AgentSessionError.duplicateConstructionPlacement(outcome.placementId)
        }
        guard lastConstructionPlacementTick != tick else {
            throw AgentSessionError.invalidConstructionPlacement(outcome.placementId)
        }
        guard processedConstructionPlacementIds.count < Self.maximumConstructionEventCount else {
            throw AgentSessionError.constructionEventLimitReached
        }
        guard var project = constructionProject,
              var builder = statesById[outcome.builderAgentId],
              project.projectId == outcome.projectId,
              project.builderAgentId == outcome.builderAgentId,
              project.nextCellIndex == outcome.cellIndex,
              project.nextTarget == outcome.target,
              project.nextCell?.resource == outcome.resource else {
            throw AgentSessionError.invalidConstructionPlacement(outcome.placementId)
        }
        guard outcome.status == .succeeded, project.applyPlacement(outcome) else {
            throw AgentSessionError.invalidConstructionPlacement(outcome.placementId)
        }
        builder.navigationProgress = AgentNavigationProgress(lastInvalidation: .targetChanged)
        appendMemory(AgentMemoryEntry(
            tick: tick,
            type: "construction_block_placed",
            summary: "\(project.projectId) placed cell \(outcome.cellIndex) \(outcome.resource.rawValue)",
            importance: 0.45
        ), to: &builder.memory)
        constructionProject = project
        statesById[builder.id] = builder
        processedConstructionPlacementIds.insert(outcome.placementId)
        lastConstructionPlacementTick = tick
        guard conservationSnapshot().balanced else {
            throw AgentSessionError.invalidConstructionPlacement(outcome.placementId)
        }
        recordAcceptedOperation(
            kind: .constructionPlacement,
            agentId: outcome.builderAgentId,
            operationId: outcome.placementId,
            status: outcome.status.rawValue,
            detail: "\(outcome.projectId):cell=\(outcome.cellIndex)"
        )
    }

    public mutating func completeConstructionProject(
        projectId: String,
        completionTick: Int
    ) throws {
        var candidate = self
        try candidate.completeConstructionProjectInPlace(
            projectId: projectId,
            completionTick: completionTick
        )
        self = candidate
    }

    mutating func completeConstructionProjectInPlace(
        projectId: String,
        completionTick: Int
    ) throws {
        try prevalidateCausalAppend(count: 1)
        guard completionTick == tick,
              var project = constructionProject,
              project.projectId == projectId,
              project.status == .building,
              project.nextCellIndex == project.blueprint.cells.count,
              project.placedCellIndices == project.blueprint.cells.map(\.index),
              project.materialEscrow.total == 0,
              project.placedMaterialTotals.amounts == project.materialRequirements,
              var builder = statesById[project.builderAgentId] else {
            throw AgentSessionError.constructionCompletionInvalid(projectId)
        }
        project.complete(at: completionTick)
        builder.homePosition = project.restPosition
        builder.navigationProgress = AgentNavigationProgress()
        appendMemory(AgentMemoryEntry(
            tick: tick,
            type: "shelter_completed",
            summary: "\(project.projectId) completed; home moved to shelter rest cell",
            importance: 0.80
        ), to: &builder.memory)
        constructionProject = project
        statesById[builder.id] = builder
        guard conservationSnapshot().balanced else {
            throw AgentSessionError.constructionCompletionInvalid(projectId)
        }
        recordAcceptedOperation(
            kind: .constructionCompletion,
            agentId: project.builderAgentId,
            operationId: "\(projectId):completion:\(completionTick)",
            status: "completed",
            detail: projectId
        )
    }

    public func prevalidateConstructionClear(projectId: String) throws {
        guard let project = constructionProject, project.projectId == projectId else {
            throw AgentSessionError.constructionProjectMissing
        }
        let refund = AgentResourceAmounts.normalize(
            project.materialEscrow.amounts + project.placedMaterialTotals.amounts
        )
        guard campStock.canAdd(refund) else {
            throw AgentSessionError.constructionClearInvalid(projectId)
        }
    }

    public mutating func clearConstructionProject(projectId: String) throws {
        var candidate = self
        try candidate.clearConstructionProjectInPlace(projectId: projectId)
        self = candidate
    }

    mutating func clearConstructionProjectInPlace(projectId: String) throws {
        try prevalidateCausalAppend(count: 1)
        try prevalidateConstructionClear(projectId: projectId)
        guard let project = constructionProject,
              var builder = statesById[project.builderAgentId] else {
            throw AgentSessionError.constructionClearInvalid(projectId)
        }
        let refund = AgentResourceAmounts.normalize(
            project.materialEscrow.amounts + project.placedMaterialTotals.amounts
        )
        var nextStock = campStock
        if !refund.isEmpty, !nextStock.add(refund) {
            throw AgentSessionError.constructionClearInvalid(projectId)
        }
        builder.homePosition = project.previousHomePosition
        builder.navigationProgress = AgentNavigationProgress()
        if builder.currentGoal.kind == .buildShelter {
            builder.currentGoal = AgentGoal(
                kind: .idle,
                reason: "construction cleared",
                startedAtTick: tick,
                urgency: 0
            )
        }
        appendMemory(AgentMemoryEntry(
            tick: tick,
            type: "construction_cleared",
            summary: "\(projectId) terrain and materials restored",
            importance: 0.45
        ), to: &builder.memory)
        campStock = nextStock
        constructionProject = nil
        buildAutoEnabled = false
        statesById[builder.id] = builder
        guard conservationSnapshot().balanced else {
            throw AgentSessionError.constructionClearInvalid(projectId)
        }
        recordAcceptedOperation(
            kind: .constructionClear,
            agentId: project.builderAgentId,
            operationId: "\(projectId):clear:\(tick)",
            status: "cleared",
            detail: projectId
        )
    }

    mutating func refreshConstructionProjectStatus() {
        guard buildAutoEnabled, var project = constructionProject,
              project.status == .planned || project.status == .acquiringMaterials else { return }
        let ready = project.materialRequirements.allSatisfy {
            campStock.count(of: $0.resource) >= $0.quantity
        }
        if ready {
            project.markReadyToFund()
            constructionProject = project
        }
    }

    func constructionEligibleResources(
        for state: AgentSessionAgentState
    ) -> [AgentResourceKind]? {
        guard buildAutoEnabled,
              let project = constructionProject,
              project.builderAgentId == state.id,
              project.status == .planned
                || project.status == .acquiringMaterials
                || project.status == .readyToFund else { return nil }
        let missing = project.missingMaterials(
            campStock: campStock,
            builderInventory: state.resourceInventory
        )
        guard let maximumDeficit = missing.map(\.quantity).max() else { return [] }
        return missing.filter { $0.quantity == maximumDeficit }.map(\.resource)
    }

    func isFundedConstructionBuilder(_ state: AgentSessionAgentState) -> Bool {
        guard buildAutoEnabled,
              let project = constructionProject,
              project.builderAgentId == state.id else { return false }
        return project.status == .funded
            || project.status == .building
            || project.status == .blocked
            || project.status == .completed
    }

    func hasActiveConstructionTask(_ state: AgentSessionAgentState) -> Bool {
        guard buildAutoEnabled,
              let project = constructionProject,
              project.builderAgentId == state.id else { return false }
        return project.status != .completed
    }

    func shouldBuildShelter(_ state: AgentSessionAgentState) -> Bool {
        guard hasActiveConstructionTask(state), let project = constructionProject else {
            return false
        }
        return project.status == .readyToFund
            || project.status == .funded
            || project.status == .building
            || project.status == .blocked
    }

}
