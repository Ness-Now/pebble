import PebbleAgents
import PebbleCore

struct PebbleMortalityMaterialExitRollback {
    let transactionID: String
    let agentID: AgentID
    let probe: LabCoreAgentEntity
    let container: BlockEntityData
    let materials: [AgentMaterialStackSnapshot]
    let probeInventoryBefore: [ItemStack?]
    let containerInventoryBefore: [ItemStack?]
}

enum PebbleMortalityBoundaryFailurePoint: Equatable {
    case none
    case beforePhysicalResolution(Int)
    case afterPhysicalTransfers
    case afterProbeRemoval
    case beforePublication
}

struct PebbleMortalityPhysicalExitCompletion {
    let agentID: AgentID
    let kind: AgentMortalityPhysicalCustodyResolutionKind
    let physicalReceiptID: String
    let destinationHolderID: String?
    let materials: [AgentMaterialStackSnapshot]
    let trackedAssetIDs: [AgentMaterialAssetID]
    let rollback: PebbleMortalityMaterialExitRollback?
}

private struct PebbleMortalityProbeBoundaryState {
    let agentID: String
    let probe: LabCoreAgentEntity
    let x: Double
    let y: Double
    let z: Double
    let previousX: Double
    let previousY: Double
    let previousZ: Double
    let inventory: [ItemStack?]

    init(agentID: String, probe: LabCoreAgentEntity) {
        self.agentID = agentID
        self.probe = probe
        x = probe.x
        y = probe.y
        z = probe.z
        previousX = probe.prevX
        previousY = probe.prevY
        previousZ = probe.prevZ
        inventory = copyItemInventory(probe.carriedItems)
    }

    func matches(
        world: World,
        probesByAgentID: [String: LabCoreAgentEntity]
    ) -> Bool {
        probesByAgentID[agentID] === probe
            && probe.world === world
            && !probe.dead
            && world.entities.filter { $0 === probe }.count == 1
            && probe.x == x && probe.y == y && probe.z == z
            && probe.prevX == previousX
            && probe.prevY == previousY
            && probe.prevZ == previousZ
            && probe.carriedItems == inventory
    }
}

extension PebbleAgentController {
    func handleMortality(_ arguments: [String]) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab mortality <on|off|status|clear>"
        guard arguments.count == 1 else { return failure(usage) }
        guard var candidate = session else { return failure("No active PebbleAgents session.") }
        let subcommand = arguments[0].lowercased()
        do {
            switch subcommand {
            case "on":
                guard mortalityFeatureEnabled else {
                    return failure(
                        "Mortality disabled. Set PEBBLELAB_APP_AGENTS_MORTALITY=1 before launch."
                    )
                }
                guard !candidate.mortalityEnabled else {
                    return failure("Mortality is already enabled.")
                }
                if try applyCommandMutationIfRecording(
                    .setMortalityEnabled(true, configuration: .embodiedLive),
                    session: &candidate
                ) == nil {
                    try candidate.setMortalityEnabled(
                        true, configuration: .embodiedLive
                    )
                }
                session = candidate
                let summary = candidate.mortalitySummary()
                trace(
                    "mortality enabled tick=\(candidate.tick) active=\(summary.activeAgentCount) "
                        + "deaths=0 terminal=0 mutation=none"
                )
                return success(
                    "Mortality enabled: active=\(summary.activeAgentCount) "
                        + "maximumDeathsPerTick=\(AgentMortalityConfiguration.embodiedLive.maximumDeathsPerTick) "
                        + "records=\(AgentMortalityConfiguration.embodiedLive.maximumRetainedDeathRecords) "
                        + "physicalCustodyVerification=required."
                )
            case "off":
                guard candidate.mortalityEnabled else {
                    return failure("Mortality is already disabled.")
                }
                if try applyCommandMutationIfRecording(
                    .setMortalityEnabled(false, configuration: .live),
                    session: &candidate
                ) == nil {
                    try candidate.setMortalityEnabled(false)
                }
                session = candidate
                trace("mortality disabled tick=\(candidate.tick) mutation=none")
                return success("Mortality disabled; active agents unchanged.")
            case "clear":
                guard candidate.mortalityEnabled else {
                    return failure("Mortality is disabled.")
                }
                if try applyCommandMutationIfRecording(
                    .clearMortalityDiagnostics,
                    session: &candidate
                ) == nil {
                    try candidate.clearMortalityDiagnostics()
                }
                session = candidate
                trace("mortality diagnostics cleared tick=\(candidate.tick)")
                return success("Mortality exit diagnostics cleared; death records unchanged.")
            case "status":
                return mortalityStatus(candidate)
            default:
                return failure(usage)
            }
        } catch {
            return failure("Mortality command failed: \(error)")
        }
    }

    func handlePopulationExits(_ arguments: [String]) -> PebbleAgentCommandResult {
        guard arguments == ["status"] else {
            return failure("Usage: /lab exits status")
        }
        guard let session else { return failure("No active PebbleAgents session.") }
        let exits = session.populationExitSnapshot()
        let latest = exits.last
        let message = "population exits count=\(exits.count) "
            + "latestDeath=\(latest?.deathID.rawValue ?? "none") "
            + "agent=\(latest?.agentID.rawValue ?? "none") "
            + "tick=\(latest?.tick ?? -1) "
            + "population=\(latest.map { "\($0.populationBefore)>\($0.populationAfter)" } ?? "none")"
        trace(message)
        return success(message)
    }

    func reconcileMortalityProbes(
        previous: AgentSessionSnapshot,
        current: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?,
        world: World,
        failurePoint: PebbleMortalityBoundaryFailurePoint = .none
    ) throws {
        let sessionBefore = current
        let recorderBefore = recorder
        let probesBefore = probesByAgentId
        let probeStatesBefore = probesBefore.keys.sorted().compactMap { id in
            probesBefore[id].map {
                PebbleMortalityProbeBoundaryState(agentID: id, probe: $0)
            }
        }
        let worldEntitiesBefore = world.entities
        let influencedBefore = lastInfluencedTracesByAgentId
        let focusBefore = focusedAgentId
        let followBefore = followMode
        let materialGatewayBefore = materialCustodyGateway.boundarySnapshot()
        let materialAttemptBefore = mortalityMaterialExitAttempt
        var completions: [PebbleMortalityPhysicalExitCompletion] = []
        var removedProbes: [LabCoreAgentEntity] = []
        do {
            completions = try resolvePendingMortalityMaterialExits(
                session: &current,
                recorder: &recorder,
                world: world,
                failurePoint: failurePoint
            )
            if failurePoint == .afterPhysicalTransfers {
                throw ControllerError.mortalityBoundary(
                    "injected after physical transfers"
                )
            }
            let expected = current.expectedActiveAgentIDs().map(\.rawValue).sorted()
            let previousIDs = previous.agents.map(\.id).sorted()
            let removedIDs = previousIDs.filter { !expected.contains($0) }
            guard removedIDs.allSatisfy({ id in
                guard let probe = probesByAgentId[id] else { return false }
                return world.entities.contains { entity in entity === probe }
                    && probe.carriedItems.allSatisfy { $0 == nil }
            }) else {
                throw ControllerError.mortalityBoundary(
                    "terminal probe missing or nonempty before removal"
                )
            }
            for id in removedIDs {
                guard let probe = probesByAgentId[id] else {
                    throw ControllerError.mortalityBoundary(
                        "terminal probe missing for \(id)"
                    )
                }
                guard removeLabCoreAgentProbe(probe, from: world) else {
                    throw ControllerError.mortalityBoundary(
                        "terminal probe removal failed for \(id)"
                    )
                }
                removedProbes.append(probe)
                probesByAgentId.removeValue(forKey: id)
                lastInfluencedTracesByAgentId.removeValue(forKey: id)
            }
            if failurePoint == .afterProbeRemoval {
                throw ControllerError.mortalityBoundary(
                    "injected after probe removal"
                )
            }
            let worldProbeIDs = world.entities.compactMap {
                ($0 as? LabCoreAgentEntity)?.labAgentId
            }.sorted()
            guard probesByAgentId.keys.sorted() == expected,
                  worldProbeIDs == expected else {
                throw ControllerError.mortalityBoundary(
                    "active probes do not match active agents "
                        + "expected=\(expected) actual=\(worldProbeIDs)"
                )
            }
            if let focusedAgentId, !expected.contains(focusedAgentId) {
                self.focusedAgentId = expected.first
            }
            if expected.isEmpty {
                focusedAgentId = nil
                followMode = .off
            } else if let target = followTargetId(), !expected.contains(target) {
                followMode = .off
            }
            let recordsByAgent = Dictionary(uniqueKeysWithValues:
                current.mortalitySnapshot().records.map {
                    ($0.agentID.rawValue, $0)
                }
            )
            guard removedIDs.allSatisfy({ recordsByAgent[$0] != nil }) else {
                throw ControllerError.mortalityBoundary(
                    "terminal record missing after probe removal"
                )
            }
            if failurePoint == .beforePublication {
                throw ControllerError.mortalityBoundary(
                    "injected before mortality publication"
                )
            }
            for completion in completions.sorted(by: {
                $0.agentID < $1.agentID
            }) {
                guard let death = recordsByAgent[
                    completion.agentID.rawValue
                ], let physical = death.physicalCustodyResolution else {
                    throw ControllerError.mortalityBoundary(
                        "terminal physical resolution missing"
                    )
                }
                let physicalStacks = completion.materials.map {
                    "\($0.identity.itemKey):\($0.count)"
                }.joined(separator: ",")
                trace(
                    "mortality physical custody tick=\(death.deathTick) "
                        + "agent=\(completion.agentID.rawValue) "
                        + "kind=\(physical.kind.rawValue) "
                        + "trackedAssets=\(completion.trackedAssetIDs.map(\.rawValue).joined(separator: ",")) "
                        + "physicalStacks=\(physicalStacks) "
                        + "receipt=\(physical.physicalReceiptID) "
                        + "destination=\(physical.destinationHolderID ?? "none") "
                        + "probeEmpty=1 socialRecordsInvented=0"
                )
                trace(
                    "mortality material exit tick=\(death.deathTick) "
                        + "agent=\(completion.agentID.rawValue) "
                        + "terminalHomeostasis="
                        + "\(death.terminalPhysiologyEventID?.rawValue ?? "none") "
                        + "pending=\(death.pendingMaterialExitEventID?.rawValue ?? "none") "
                        + "physicalEvent=\(physical.eventID.rawValue) "
                        + "materialEvent=\(death.materialExitEventIDs.last?.rawValue ?? "none") "
                        + "lethal=\(death.lethalDamageEventID.rawValue) "
                        + "resources=\(death.resourcesRetiredEventID.rawValue) "
                        + "commitments=\(death.commitmentsResolvedEventID.rawValue) "
                        + "exit=\(death.populationExitEventID.rawValue) "
                        + "death=\(death.deathEventID.rawValue) "
                        + "assets=\(completion.trackedAssetIDs.map(\.rawValue).joined(separator: ",")) "
                        + "holderBefore=agent:\(completion.agentID.rawValue) "
                        + "holderAfter=\(physical.destinationHolderID ?? "none") "
                        + "quantity=\(physical.itemCount)>\(physical.itemCount) "
                        + "receipt=\(physical.physicalReceiptID) "
                        + "socialRoles=unchanged inheritance=none"
                )
            }
            for id in removedIDs {
                let record = recordsByAgent[id]!
                trace(
                    "mortality exit tick=\(record.deathTick) "
                        + "death=\(record.deathID.rawValue) agent=\(id) "
                        + "cause=\(record.cause.rawValue) "
                        + "health=\(record.healthBeforeLethalDamage)>\(record.finalHealth) "
                        + "population=\(previous.agentCount)>\(expected.count) "
                        + "terminal=\(record.carriedInventory.reduce(0) { $0 + $1.quantity }) "
                        + "probes=\(previousIDs.count)>\(expected.count) "
                        + "focus=\(focusedAgentId ?? "none") "
                        + "corpse=none worldMutation=none"
                )
            }
        } catch {
            for probe in removedProbes where !world.entities.contains(where: {
                $0 === probe
            }) {
                world.addEntity(probe)
            }
            probesByAgentId = probesBefore
            lastInfluencedTracesByAgentId = influencedBefore
            focusedAgentId = focusBefore
            followMode = followBefore
            let physicalRollback = rollbackMortalityMaterialExits(
                completions.compactMap(\.rollback), world: world
            )
            materialCustodyGateway.restoreBoundarySnapshot(
                materialGatewayBefore
            )
            mortalityMaterialExitAttempt = materialAttemptBefore
            current = sessionBefore
            recorder = recorderBefore
            let sameWorldEntities = worldEntitiesBefore.count
                    == world.entities.count
                && worldEntitiesBefore.allSatisfy { before in
                    world.entities.contains { $0 === before }
                }
            let exact = physicalRollback && sameWorldEntities
                && probeStatesBefore.allSatisfy {
                    $0.matches(
                        world: world,
                        probesByAgentID: probesByAgentId
                    )
                }
                && probesByAgentId.keys.sorted()
                    == probesBefore.keys.sorted()
                && focusedAgentId == focusBefore
                && followMode == followBefore
            guard exact else {
                throw ControllerError.mortalityRollbackBoundary(
                    "full mortality boundary rollback failed after \(error)"
                )
            }
            throw ControllerError.mortalityBoundary(
                "full mortality boundary rollback verified after \(error)"
            )
        }
    }

    @discardableResult
    func resolvePendingMortalityMaterialExits(
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?,
        world: World,
        failurePoint: PebbleMortalityBoundaryFailurePoint = .none
    ) throws -> [PebbleMortalityPhysicalExitCompletion] {
        let pending = session.pendingMortalityTransitions()
        guard !pending.isEmpty else { return [] }
        let sessionBefore = session
        let recorderBefore = recorder
        let gatewayBefore = materialCustodyGateway.boundarySnapshot()
        let attemptBefore = mortalityMaterialExitAttempt
        var completed: [PebbleMortalityPhysicalExitCompletion] = []
        do {
            for (offset, transition) in pending.enumerated() {
                if failurePoint == .beforePhysicalResolution(offset + 1) {
                    throw ControllerError.mortalityBoundary(
                        "injected before physical resolution \(offset + 1)"
                    )
                }
                guard let probe = probesByAgentId[
                    transition.agentID.rawValue
                ], probe.world === world,
                      world.entities.contains(where: { $0 === probe }) else {
                    throw ControllerError.mortalityBoundary(
                        "terminal material source missing "
                            + transition.agentID.rawValue
                    )
                }
                let rightsBefore = transition.requiredMaterialAssetIDs.compactMap {
                    assetID -> AgentMaterialRightsRecord? in
                    session.materialRightsSnapshot().records.first {
                        $0.asset.assetID == assetID
                    }
                }
                guard rightsBefore.count
                        == transition.requiredMaterialAssetIDs.count,
                      rightsBefore.allSatisfy({
                          $0.lastVerifiedHolder.holder
                              == .agent(transition.agentID)
                      }) else {
                    throw ControllerError.mortalityBoundary(
                        "terminal material rights source mismatch"
                    )
                }
                let source = PebbleAgentMaterialCustodyEndpoint.liveAgent(
                    probe, in: world
                )
                let sourceCustody = try materialCustodyGateway.inspect(source)
                let allCarried = sourceCustody.slots.compactMap { $0 }
                let probeInventoryBefore = copyItemInventory(probe.carriedItems)
                guard allCarried.count <= AgentMortalityConfiguration
                        .embodiedLive
                        .maximumMaterialExitsPerDeath else {
                    throw ControllerError.mortalityBoundary(
                        "terminal carried material bound"
                    )
                }
                let sourceFingerprint = try materialCustodyGateway.fingerprint(
                    source
                )
                guard rightsBefore.allSatisfy({ record in
                    record.lastVerifiedHolder.custodyFingerprint
                        == sourceFingerprint
                        && allCarried.filter { stack in
                            stack.identity
                                == record.lastVerifiedHolder.materialIdentity
                        }.reduce(0) { $0 + $1.count }
                            >= record.lastVerifiedHolder.quantity
                }) else {
                    throw ControllerError.mortalityBoundary(
                        "terminal material source stale"
                    )
                }
                mortalityMaterialExitAttempt += 1
                if allCarried.isEmpty {
                    guard rightsBefore.isEmpty else {
                        throw ControllerError.mortalityBoundary(
                            "terminal rights asset missing from physical custody"
                        )
                    }
                    let receipt = "mortality-custody:"
                        + "\(transition.agentID.rawValue):t\(session.tick):"
                        + "empty:a\(mortalityMaterialExitAttempt)"
                    let outcome = AgentMortalityPhysicalCustodyOutcome(
                        operationID: receipt,
                        terminalAgentID: transition.agentID,
                        kind: .verifiedEmpty,
                        physicalReceiptID: receipt,
                        destinationHolderID: nil,
                        stackCount: 0,
                        itemCount: 0,
                        verifiedAtTick: session.tick
                    )
                    var staged = session
                    var stagedReplay = recorder
                    if try applyRecordedOperationIfActive(
                        .applyMortalityPhysicalCustodyOutcome(outcome),
                        session: &staged,
                        recorder: &stagedReplay
                    ) == nil {
                        _ = try staged.applyMortalityPhysicalCustodyOutcome(
                            outcome
                        )
                    }
                    if try applyRecordedOperationIfActive(
                        .finalizePendingMortality(transition.agentID),
                        session: &staged,
                        recorder: &stagedReplay
                    ) == nil {
                        _ = try staged.finalizePendingMortality(
                            for: transition.agentID
                        )
                    }
                    session = staged
                    recorder = stagedReplay
                    completed.append(PebbleMortalityPhysicalExitCompletion(
                        agentID: transition.agentID,
                        kind: .verifiedEmpty,
                        physicalReceiptID: receipt,
                        destinationHolderID: nil,
                        materials: [],
                        trackedAssetIDs:
                            transition.requiredMaterialAssetIDs,
                        rollback: nil
                    ))
                    continue
                }
                let candidates = mortalityMaterialExitContainers(
                    around: probe, world: world
                )
                guard !candidates.isEmpty else {
                    throw ControllerError.mortalityBoundary(
                        "no verified physical container for terminal material exit"
                    )
                }

                var selectedRollback: PebbleMortalityMaterialExitRollback?
                var stagedSession: AgentSimulationSession?
                var stagedRecorder: AgentReplayRecorder?
                var publicationError: Error?
                var lastStatus = PebbleAgentMaterialTransactionStatus
                    .incompatibleDestination
                for container in candidates {
                    let destination = PebbleAgentMaterialCustodyEndpoint.container(
                        container, in: world
                    )
                    let containerBefore = copyItemInventory(
                        container.items ?? []
                    )
                    let transactionID = "mortality-exit:"
                        + "\(transition.agentID.rawValue):t\(session.tick):"
                        + "a\(mortalityMaterialExitAttempt):"
                        + "\(container.x),\(container.y),\(container.z)"
                    let request = PebbleAgentMaterialBatchTransactionRequest(
                        transactionID: transactionID,
                        materials: allCarried,
                        expectedSourceFingerprint: sourceFingerprint,
                        expectedDestinationFingerprint:
                            try materialCustodyGateway.fingerprint(destination)
                    )
                    var candidateSession: AgentSimulationSession?
                    var candidateRecorder: AgentReplayRecorder?
                    let physical = materialCustodyGateway.transferBatch(
                        request,
                        from: source,
                        to: destination,
                        verifyAfterMutation: {
                            do {
                                let fingerprint = try self.materialCustodyGateway
                                    .fingerprint(destination)
                                let holder = AgentMaterialPhysicalHolder.container(
                                    "\(container.x),\(container.y),\(container.z)"
                                )
                                var staged = session
                                var stagedReplay = recorder
                                for before in rightsBefore.sorted(by: {
                                    $0.asset.assetID < $1.asset.assetID
                                }) {
                                    let operationID = transactionID + ":"
                                        + before.asset.assetID.rawValue
                                    let outcome = AgentMaterialMortalityExitOutcome(
                                        operationID: operationID,
                                        assetID: before.asset.assetID,
                                        terminalAgentID: transition.agentID,
                                        sourceObservation: before.lastVerifiedHolder,
                                        destinationObservation:
                                            AgentMaterialHolderObservation(
                                                holder: holder,
                                                materialIdentity:
                                                    before.lastVerifiedHolder
                                                        .materialIdentity,
                                                quantity:
                                                    before.lastVerifiedHolder
                                                        .quantity,
                                                custodyFingerprint: fingerprint,
                                                physicalReceiptID: transactionID,
                                                observedAtTick: staged.tick
                                            ),
                                        physicalReceiptID: transactionID
                                    )
                                    if try self.applyRecordedOperationIfActive(
                                        .applyMaterialRightsOperation(
                                            .mortalityPhysicalExit(outcome)
                                        ),
                                        session: &staged,
                                        recorder: &stagedReplay
                                    ) == nil {
                                        _ = try staged.applyMaterialRightsOperation(
                                            .mortalityPhysicalExit(outcome)
                                        )
                                    }
                                }
                                let physicalOutcome =
                                    AgentMortalityPhysicalCustodyOutcome(
                                        operationID: transactionID
                                            + ":physical-custody",
                                        terminalAgentID: transition.agentID,
                                        kind: .transferred,
                                        physicalReceiptID: transactionID,
                                        destinationHolderID:
                                            "container:\(container.x),"
                                                + "\(container.y),\(container.z)",
                                        stackCount: allCarried.count,
                                        itemCount: allCarried.reduce(0) {
                                            $0 + $1.count
                                        },
                                        verifiedAtTick: staged.tick
                                    )
                                if try self.applyRecordedOperationIfActive(
                                    .applyMortalityPhysicalCustodyOutcome(
                                        physicalOutcome
                                    ),
                                    session: &staged,
                                    recorder: &stagedReplay
                                ) == nil {
                                    _ = try staged
                                        .applyMortalityPhysicalCustodyOutcome(
                                            physicalOutcome
                                        )
                                }
                                if try self.applyRecordedOperationIfActive(
                                    .finalizePendingMortality(
                                        transition.agentID
                                    ),
                                    session: &staged,
                                    recorder: &stagedReplay
                                ) == nil {
                                    _ = try staged.finalizePendingMortality(
                                        for: transition.agentID
                                    )
                                }
                                candidateSession = staged
                                candidateRecorder = stagedReplay
                                return true
                            } catch {
                                publicationError = error
                                return false
                            }
                        }
                    )
                    lastStatus = physical.status
                    if physical.succeeded, let candidateSession {
                        stagedSession = candidateSession
                        stagedRecorder = candidateRecorder
                        selectedRollback = PebbleMortalityMaterialExitRollback(
                            transactionID: transactionID,
                            agentID: transition.agentID,
                            probe: probe,
                            container: container,
                            materials: allCarried,
                            probeInventoryBefore: probeInventoryBefore,
                            containerInventoryBefore: containerBefore
                        )
                        break
                    }
                    if physical.status != .destinationFull {
                        break
                    }
                }
                guard let stagedSession, let selectedRollback else {
                    throw publicationError
                        ?? ControllerError.mortalityBoundary(
                            "terminal material exit \(lastStatus.rawValue)"
                        )
                }
                let completion = PebbleMortalityPhysicalExitCompletion(
                    agentID: transition.agentID,
                    kind: .transferred,
                    physicalReceiptID: selectedRollback.transactionID,
                    destinationHolderID:
                        "container:\(selectedRollback.container.x),"
                            + "\(selectedRollback.container.y),"
                            + "\(selectedRollback.container.z)",
                    materials: allCarried,
                    trackedAssetIDs: transition.requiredMaterialAssetIDs,
                    rollback: selectedRollback
                )
                completed.append(completion)
                let rightsAfter = stagedSession.materialRightsSnapshot().records
                    .filter {
                        transition.requiredMaterialAssetIDs.contains(
                            $0.asset.assetID
                        )
                    }.sorted { $0.asset.assetID < $1.asset.assetID }
                guard rightsBefore.count == rightsAfter.count,
                      zip(
                    rightsBefore.sorted { $0.asset.assetID < $1.asset.assetID },
                    rightsAfter
                ).allSatisfy({
                    before, after in
                    before.asset == after.asset
                        && before.custodianID == after.custodianID
                        && before.claims == after.claims
                        && before.recognizedOwnership
                            == after.recognizedOwnership
                        && before.permissions == after.permissions
                        && before.lastVerifiedHolder.holder
                            == .agent(transition.agentID)
                        && after.lastVerifiedHolder.holder
                            == .container(
                                "\(selectedRollback.container.x),"
                                    + "\(selectedRollback.container.y),"
                                    + "\(selectedRollback.container.z)"
                            )
                }) else {
                    throw ControllerError.mortalityBoundary(
                        "terminal material social state changed"
                    )
                }
                session = stagedSession
                recorder = stagedRecorder
                guard let death = session.mortalitySnapshot().records.last(
                    where: { $0.agentID == transition.agentID }
                ) else {
                    throw ControllerError.mortalityBoundary(
                        "terminal death was not finalized"
                    )
                }
                guard death.physicalCustodyResolution?.physicalReceiptID
                        == selectedRollback.transactionID else {
                    throw ControllerError.mortalityBoundary(
                        "terminal physical receipt was not retained"
                    )
                }
            }
            return completed
        } catch {
            let rolledBack = rollbackMortalityMaterialExits(
                completed.compactMap(\.rollback), world: world
            )
            session = sessionBefore
            recorder = recorderBefore
            materialCustodyGateway.restoreBoundarySnapshot(gatewayBefore)
            mortalityMaterialExitAttempt = attemptBefore
            guard rolledBack else {
                throw ControllerError.mortalityRollbackBoundary(
                    "terminal material rollback failed after \(error)"
                )
            }
            throw ControllerError.mortalityBoundary(
                "terminal material rollback verified after \(error)"
            )
        }
    }

    func mortalityMaterialExitContainers(
        around probe: LabCoreAgentEntity,
        world: World
    ) -> [BlockEntityData] {
        let originX = Int(probe.x.rounded(.down))
        let originY = Int(probe.y.rounded(.down))
        let originZ = Int(probe.z.rounded(.down))
        var candidates: [BlockEntityData] = []
        var seen = Set<String>()
        for radius in 0...16 {
            for dy in -4...4 {
                for dx in -radius...radius {
                    let remaining = radius - abs(dx)
                    let dzValues = remaining == 0
                        ? [0] : [-remaining, remaining]
                    for dz in dzValues {
                        let x = originX + dx
                        let y = originY + dy
                        let z = originZ + dz
                        let key = "\(x),\(y),\(z)"
                        guard seen.insert(key).inserted,
                              world.isChunkReady(x >> 4, z >> 4),
                              let container = world.getBlockEntity(x, y, z),
                              container.type == "container",
                              container.items != nil else { continue }
                        candidates.append(container)
                        if candidates.count == 32 { return candidates }
                    }
                }
            }
        }
        return candidates
    }

    private func rollbackMortalityMaterialExits(
        _ completed: [PebbleMortalityMaterialExitRollback],
        world: World
    ) -> Bool {
        for item in completed.reversed() {
            if !world.entities.contains(where: { $0 === item.probe }) {
                world.addEntity(item.probe)
                probesByAgentId[item.agentID.rawValue] = item.probe
            }
            let source = PebbleAgentMaterialCustodyEndpoint.container(
                item.container, in: world
            )
            let destination = PebbleAgentMaterialCustodyEndpoint.liveAgent(
                item.probe, in: world
            )
            guard let sourceFingerprint = try? materialCustodyGateway
                .fingerprint(source),
                  let destinationFingerprint = try? materialCustodyGateway
                    .fingerprint(destination) else { return false }
            let rollback = materialCustodyGateway.transferBatch(
                PebbleAgentMaterialBatchTransactionRequest(
                    transactionID: item.transactionID + ":rollback",
                    materials: item.materials,
                    expectedSourceFingerprint: sourceFingerprint,
                    expectedDestinationFingerprint: destinationFingerprint
                ),
                from: source,
                to: destination,
                verifyAfterMutation: {
                    item.probe.carriedItems == item.probeInventoryBefore
                        && item.container.items == item.containerInventoryBefore
                }
            )
            guard rollback.succeeded,
                  item.probe.carriedItems == item.probeInventoryBefore,
                  item.container.items == item.containerInventoryBefore else {
                return false
            }
        }
        return true
    }

    private func mortalityStatus(_ session: AgentSimulationSession) -> PebbleAgentCommandResult {
        let summary = session.mortalitySummary()
        let population = session.populationSummary()
        let message = "mortality gate=\(mortalityFeatureEnabled ? "enabled" : "disabled") "
            + "active=\(summary.enabled ? "yes" : "no") agents=\(summary.activeAgentCount) "
            + "deaths=\(summary.totalDeathCount) retained=\(summary.retainedDeathCount) "
            + "evicted=\(summary.evictedDeathCount) "
            + "latest=\(summary.latestDeathID?.rawValue ?? "none") "
            + "victim=\(summary.latestAgentID?.rawValue ?? "none") "
            + "tick=\(summary.latestDeathTick ?? -1) terminal=\(summary.unrecoveredTotal) "
            + "members=\(population.memberCount) nextOrdinal=\(population.nextPopulationOrdinal ?? -1) "
            + "probes=\(probesByAgentId.count) digest=\(summary.digest)"
        trace(message)
        return success(message)
    }
}
