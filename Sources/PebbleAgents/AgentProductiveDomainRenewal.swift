public struct AgentRenewableLivestockTaskContext: Equatable, Sendable {
    public let actorID: AgentID
    public let recordID: AgentManagedAnimalRecordID
    public let compatibleFeedAvailable: Bool
    public let productToolAvailable: Bool

    public init(
        actorID: AgentID,
        recordID: AgentManagedAnimalRecordID,
        compatibleFeedAvailable: Bool,
        productToolAvailable: Bool
    ) {
        self.actorID = actorID
        self.recordID = recordID
        self.compatibleFeedAvailable = compatibleFeedAvailable
        self.productToolAvailable = productToolAvailable
    }
}

extension AgentProductiveSource {
    /// Stable source identity plus its material renewal generation. Observation
    /// and opportunity IDs are deliberately excluded.
    public var logicalGenerationKey: String {
        "\(sourceKey)#renewal-\(renewalCount)"
    }
}

extension AgentSimulationSession {
    public func productiveSource(
        domain: AgentAutonomousActivityDomain,
        at position: AgentPosition,
        eligibleOnly: Bool = true
    ) -> AgentProductiveSource? {
        (autonomousActivityState?.productiveSourceState?.sources ?? [])
            .filter {
                $0.domain == domain
                    && $0.physicalPosition == position
                    && (!eligibleOnly || $0.viability.eligible)
            }
            .sorted {
                if $0.sourceKey != $1.sourceKey {
                    return $0.sourceKey < $1.sourceKey
                }
                return $0.firstObservedTick < $1.firstObservedTick
            }
            .first
    }

    /// Read-only, actor-neutral task proposal. Pebble supplies only current
    /// physical custody facts; the durable livestock and source states retain
    /// authority over identity, bounded repetition, and target selection.
    public func renewableLivestockTaskRequest(
        _ context: AgentRenewableLivestockTaskContext
    ) -> AgentLivestockTaskRequest? {
        guard let state = livestockState,
              let record = state.managedAnimals.first(where: {
                  $0.recordID == context.recordID
              }),
              record.status.resolvedLiving,
              state.herds.contains(where: { $0.herdID == record.herdID }),
              statesById[context.actorID.rawValue]?.health ?? 0 > 0,
              activeCareEngagement(for: context.actorID) == nil,
              !state.activeTasks.contains(where: {
                  !$0.status.terminal
                      && ($0.primaryAnimalRecordID == record.recordID
                          || $0.secondaryAnimalRecordID == record.recordID)
              }),
              let source = productiveSource(
                  for: "livestock:animal:\(record.recordID.rawValue)"
              ),
              source.viability.eligible,
              source.physicalPosition == record.lastKnownPosition else {
            return nil
        }

        let kind: AgentLivestockTaskKind
        if record.productReady {
            guard context.productToolAvailable else { return nil }
            kind = .collectProduct
        } else if !record.breedingReady && context.compatibleFeedAvailable {
            kind = .feed
        } else {
            return nil
        }
        let identity = AgentLivestockDigest.make([
            context.actorID.rawValue,
            source.logicalGenerationKey,
            source.materialFingerprint,
            kind.rawValue,
        ].joined(separator: "|"))
        guard let taskID = AgentLivestockTaskID(
            rawValue: "renewable-\(kind.rawValue)-\(identity)"
        ),
              !state.activeTasks.contains(where: { $0.taskID == taskID }),
              !state.retainedTaskRecords.contains(where: {
                  $0.outcome.taskID == taskID
              }) else {
            return nil
        }
        return AgentLivestockTaskRequest(
            taskID: taskID,
            herdID: record.herdID,
            kind: kind,
            primaryAnimalRecordID: record.recordID,
            responsibleAgentID: context.actorID,
            targetPosition: record.lastKnownPosition
        )
    }
}
