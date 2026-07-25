/// Ephemeral physical evidence that a species-compatible feed is in an
/// inhabitant's verified custody. This is deliberately not checkpointed: the
/// adapter must rebuild it from current physical truth before each proposal.
public struct AgentAutonomousLivestockFeedContext: Equatable, Sendable {
    public let speciesKey: String
    public let compatibleFeedQuantity: Int
    public let reservedPlantingQuantity: Int

    public init(
        speciesKey: String,
        compatibleFeedQuantity: Int,
        reservedPlantingQuantity: Int
    ) {
        self.speciesKey = speciesKey
        self.compatibleFeedQuantity = compatibleFeedQuantity
        self.reservedPlantingQuantity = reservedPlantingQuantity
    }
}

/// Ephemeral binding between a fresh ecological observation and one exactly
/// resolved physical animal. `candidateKey` belongs to the live adapter and is
/// never copied into durable simulation state.
public struct AgentAutonomousLivestockAnimalContext: Equatable, Sendable {
    public let candidateKey: String
    public let sourceObservationEventID: AgentCausalEventID
    public let speciesKey: String
    public let position: AgentPosition
    public let lifeStage: AgentAnimalLifeStage

    public init(
        candidateKey: String,
        sourceObservationEventID: AgentCausalEventID,
        speciesKey: String,
        position: AgentPosition,
        lifeStage: AgentAnimalLifeStage
    ) {
        self.candidateKey = candidateKey
        self.sourceObservationEventID = sourceObservationEventID
        self.speciesKey = speciesKey
        self.position = position
        self.lifeStage = lifeStage
    }
}

/// Current physical availability supplied by the live adapter. Cognitive
/// capability and urgent human-care priority are still checked by the shared
/// session and cannot be asserted by this context.
public struct AgentAutonomousLivestockActorContext: Equatable, Sendable {
    public let actorID: AgentID
    public let physicalPosition: AgentPosition
    public let canPerformPhysicalLivestockWork: Bool
    public let compatibleFeeds: [AgentAutonomousLivestockFeedContext]
    public let animals: [AgentAutonomousLivestockAnimalContext]

    public init(
        actorID: AgentID,
        physicalPosition: AgentPosition,
        canPerformPhysicalLivestockWork: Bool,
        compatibleFeeds: [AgentAutonomousLivestockFeedContext],
        animals: [AgentAutonomousLivestockAnimalContext]
    ) {
        self.actorID = actorID
        self.physicalPosition = physicalPosition
        self.canPerformPhysicalLivestockWork = canPerformPhysicalLivestockWork
        self.compatibleFeeds = compatibleFeeds
        self.animals = animals
    }
}

public struct AgentAutonomousLivestockAdmissionProposal: Equatable, Sendable {
    public let candidateKey: String
    public let recordID: AgentManagedAnimalRecordID
    public let sourceObservationEventID: AgentCausalEventID
    public let position: AgentPosition
    public let lifeStage: AgentAnimalLifeStage
    public let feedTaskID: AgentLivestockTaskID
}

/// A bounded, read-only proposal expressed entirely through existing CIV-24
/// operations. Applying it remains the caller's transactional responsibility.
public struct AgentAutonomousLivestockInitiationProposal: Equatable, Sendable {
    public let responsibleAgentID: AgentID
    public let herdID: AgentLivestockHerdID
    public let speciesKey: String
    public let managementArea: AgentLivestockManagementArea
    public let admissions: [AgentAutonomousLivestockAdmissionProposal]

    public var operations: [AgentLivestockOperation] {
        var result: [AgentLivestockOperation] = [
            .establishHerd(
                herdID: herdID,
                speciesKey: speciesKey,
                managementArea: managementArea,
                responsibleAgentIDs: [responsibleAgentID]
            )
        ]
        result.append(contentsOf: admissions.map {
            .admitObservedAnimal(
                recordID: $0.recordID,
                herdID: herdID,
                actorID: responsibleAgentID,
                speciesKey: speciesKey,
                position: $0.position,
                lifeStage: $0.lifeStage,
                sourceObservationEventID: $0.sourceObservationEventID,
                compatibleFeedAvailable: true
            )
        })
        result.append(contentsOf: admissions.map {
            .queueTask(AgentLivestockTaskRequest(
                taskID: $0.feedTaskID,
                herdID: herdID,
                kind: .feed,
                primaryAnimalRecordID: $0.recordID,
                responsibleAgentID: responsibleAgentID,
                targetPosition: $0.position
            ))
        })
        return result
    }
}

extension AgentSimulationSession {
    /// Selects one role-neutral livestock opportunity from fresh local evidence.
    /// The method has no side effects and produces no proposal once durable herd
    /// ownership already exists.
    public func autonomousLivestockInitiationProposal(
        contexts: [AgentAutonomousLivestockActorContext]
    ) throws -> AgentAutonomousLivestockInitiationProposal? {
        guard let livestock = livestockState, livestock.herds.isEmpty else { return nil }
        try validateAutonomousLivestockContexts(contexts)

        let orderedContexts = contexts.sorted { $0.actorID < $1.actorID }
        var groups: [AutonomousLivestockCandidateGroup] = []
        for context in orderedContexts {
            guard context.canPerformPhysicalLivestockWork,
                  let actor = statesById[context.actorID.rawValue],
                  actor.health > 0,
                  actor.position == context.physicalPosition,
                  lifecycleState?.members.first(where: {
                      $0.agentID == context.actorID
                  })?.currentStage == .mature,
                  activeCareEngagement(for: context.actorID) == nil,
                  let observationRecord = ecologicalObservations(
                      for: context.actorID
                  ).first,
                  observationRecord.observation.origin == context.physicalPosition,
                  observationRecord.observation.diagnostics.completion == .complete
            else { continue }

            let feedBySpecies = Dictionary(
                uniqueKeysWithValues: context.compatibleFeeds.map {
                    ($0.speciesKey, $0)
                }
            )
            for speciesKey in feedBySpecies.keys.sorted() {
                guard let feed = feedBySpecies[speciesKey] else { continue }
                let eligibleFeed = feed.compatibleFeedQuantity
                    - feed.reservedPlantingQuantity
                let capacity = min(
                    4,
                    livestock.configuration.maximumManagedAnimalsPerHerd,
                    livestock.configuration.maximumActiveTasks,
                    eligibleFeed
                )
                guard capacity > 0 else { continue }

                var seenPhysicalPositions: Set<AgentPosition> = []
                let matchingAnimals = context.animals.filter {
                    $0.speciesKey == speciesKey
                        && $0.sourceObservationEventID
                            == observationRecord.causalEventID
                        && autonomousLivestockObservationContains(
                            $0,
                            record: observationRecord
                        )
                }.sorted {
                    autonomousLivestockAnimalSort(
                        $0,
                        $1,
                        origin: context.physicalPosition
                    )
                }.filter {
                    seenPhysicalPositions.insert($0.position).inserted
                }
                let selected = Array(matchingAnimals.prefix(capacity))
                guard !selected.isEmpty,
                      let area = autonomousLivestockManagementArea(
                          actorPosition: context.physicalPosition,
                          animals: selected
                      )
                else { continue }
                groups.append(AutonomousLivestockCandidateGroup(
                    actorID: context.actorID,
                    speciesKey: speciesKey,
                    sourceObservationEventID: observationRecord.causalEventID,
                    managementArea: area,
                    animals: selected,
                    totalDistance: selected.reduce(0) {
                        $0 + autonomousLivestockDistance(
                            context.physicalPosition,
                            $1.position
                        )
                    }
                ))
            }
        }

        guard let selectedGroup = groups.sorted(
            by: autonomousLivestockGroupSort
        ).first else { return nil }
        let identitySeed = [
            simulationID.rawValue,
            String(tick),
            selectedGroup.actorID.rawValue,
            selectedGroup.speciesKey,
            selectedGroup.sourceObservationEventID.rawValue
        ].map(autonomousLivestockCanonicalField).joined(separator: "|")
            + "|animals="
            + selectedGroup.animals.map {
                autonomousLivestockCanonicalField($0.candidateKey)
            }.joined(separator: "|")
        let identityDigest = AgentLivestockDigest.make(identitySeed)
        guard let herdID = AgentLivestockHerdID(
            rawValue: "autonomous-herd-\(identityDigest)"
        ) else { return nil }
        let admissions = selectedGroup.animals.enumerated().compactMap {
            index, animal -> AgentAutonomousLivestockAdmissionProposal? in
            guard let recordID = AgentManagedAnimalRecordID(
                rawValue: "autonomous-animal-\(identityDigest)-\(index)"
            ), let taskID = AgentLivestockTaskID(
                rawValue: "autonomous-feed-\(identityDigest)-\(index)"
            ) else { return nil }
            return AgentAutonomousLivestockAdmissionProposal(
                candidateKey: animal.candidateKey,
                recordID: recordID,
                sourceObservationEventID: animal.sourceObservationEventID,
                position: animal.position,
                lifeStage: animal.lifeStage,
                feedTaskID: taskID
            )
        }
        guard admissions.count == selectedGroup.animals.count else { return nil }
        return AgentAutonomousLivestockInitiationProposal(
            responsibleAgentID: selectedGroup.actorID,
            herdID: herdID,
            speciesKey: selectedGroup.speciesKey,
            managementArea: selectedGroup.managementArea,
            admissions: admissions
        )
    }

    private func validateAutonomousLivestockContexts(
        _ contexts: [AgentAutonomousLivestockActorContext]
    ) throws {
        let maximumAnimalContexts = ecologicalObservationState?.configuration
            .maximumResultsPerScan ?? 0
        guard contexts.count <= min(256, statesById.count),
              Set(contexts.map(\.actorID)).count == contexts.count,
              contexts.allSatisfy({
                  statesById[$0.actorID.rawValue] != nil
                      && $0.compatibleFeeds.count <= 128
                      && $0.animals.count <= maximumAnimalContexts
              })
        else {
            throw AgentSessionError.livestock(
                .invalidInitiationContext("actor or collection bounds")
            )
        }
        for context in contexts {
            guard Set(context.compatibleFeeds.map(\.speciesKey)).count
                    == context.compatibleFeeds.count,
                  Set(context.animals.map(\.candidateKey)).count
                    == context.animals.count
            else {
                throw AgentSessionError.livestock(
                    .invalidInitiationContext("duplicate feed or animal context")
                )
            }
            for feed in context.compatibleFeeds {
                guard autonomousLivestockSpeciesIsValid(feed.speciesKey),
                      feed.compatibleFeedQuantity >= 0,
                      feed.reservedPlantingQuantity >= 0,
                      feed.reservedPlantingQuantity
                        <= feed.compatibleFeedQuantity
                else {
                    throw AgentSessionError.livestock(
                        .invalidInitiationContext("feed evidence")
                    )
                }
            }
            for animal in context.animals {
                guard autonomousLivestockCandidateKeyIsValid(
                          animal.candidateKey
                      ),
                      autonomousLivestockSpeciesIsValid(animal.speciesKey)
                else {
                    throw AgentSessionError.livestock(
                        .invalidInitiationContext("animal evidence")
                    )
                }
            }
        }
    }

    private func autonomousLivestockObservationContains(
        _ candidate: AgentAutonomousLivestockAnimalContext,
        record: AgentEcologicalObservationRecord
    ) -> Bool {
        guard candidate.sourceObservationEventID.simulationID == simulationID,
              record.observation.isFresh(atSimulationTick: tick),
              record.observation.animals.contains(where: {
                  $0.speciesKey == candidate.speciesKey
                      && $0.position == candidate.position
                      && $0.lifeStage == candidate.lifeStage
                      && $0.count > 0
              }),
              let horizontalX = autonomousLivestockAxisDistance(
                  record.observation.origin.x,
                  candidate.position.x
              ),
              let horizontalZ = autonomousLivestockAxisDistance(
                  record.observation.origin.z,
                  candidate.position.z
              ),
              let vertical = autonomousLivestockAxisDistance(
                  record.observation.origin.y,
                  candidate.position.y
              ),
              let observationConfiguration = ecologicalObservationState?
                .configuration
        else { return false }
        return max(horizontalX, horizontalZ)
                <= record.observation.diagnostics.radius
            && vertical <= observationConfiguration.verticalRadius
    }
}

private struct AutonomousLivestockCandidateGroup {
    let actorID: AgentID
    let speciesKey: String
    let sourceObservationEventID: AgentCausalEventID
    let managementArea: AgentLivestockManagementArea
    let animals: [AgentAutonomousLivestockAnimalContext]
    let totalDistance: Int
}

private func autonomousLivestockGroupSort(
    _ lhs: AutonomousLivestockCandidateGroup,
    _ rhs: AutonomousLivestockCandidateGroup
) -> Bool {
    if lhs.animals.count != rhs.animals.count {
        return lhs.animals.count > rhs.animals.count
    }
    if lhs.totalDistance != rhs.totalDistance {
        return lhs.totalDistance < rhs.totalDistance
    }
    if lhs.actorID != rhs.actorID { return lhs.actorID < rhs.actorID }
    if lhs.speciesKey != rhs.speciesKey {
        return lhs.speciesKey < rhs.speciesKey
    }
    return lhs.sourceObservationEventID < rhs.sourceObservationEventID
}

private func autonomousLivestockAnimalSort(
    _ lhs: AgentAutonomousLivestockAnimalContext,
    _ rhs: AgentAutonomousLivestockAnimalContext,
    origin: AgentPosition
) -> Bool {
    let lhsDistance = autonomousLivestockDistance(origin, lhs.position)
    let rhsDistance = autonomousLivestockDistance(origin, rhs.position)
    if lhsDistance != rhsDistance { return lhsDistance < rhsDistance }
    if lhs.position != rhs.position {
        return AgentEcologicalObservation.positionSort(
            lhs.position,
            rhs.position
        )
    }
    if lhs.lifeStage != rhs.lifeStage {
        return lhs.lifeStage.rawValue < rhs.lifeStage.rawValue
    }
    return lhs.candidateKey < rhs.candidateKey
}

private func autonomousLivestockManagementArea(
    actorPosition: AgentPosition,
    animals: [AgentAutonomousLivestockAnimalContext]
) -> AgentLivestockManagementArea? {
    let positions = [actorPosition] + animals.map(\.position)
    guard let minimumX = positions.map(\.x).min(),
          let maximumX = positions.map(\.x).max(),
          let minimumY = positions.map(\.y).min(),
          let maximumY = positions.map(\.y).max(),
          let minimumZ = positions.map(\.z).min(),
          let maximumZ = positions.map(\.z).max(),
          let paddedMinimumX = autonomousLivestockAdding(minimumX, -2),
          let paddedMaximumX = autonomousLivestockAdding(maximumX, 2),
          let paddedMinimumY = autonomousLivestockAdding(minimumY, -1),
          let paddedMaximumY = autonomousLivestockAdding(maximumY, 1),
          let paddedMinimumZ = autonomousLivestockAdding(minimumZ, -2),
          let paddedMaximumZ = autonomousLivestockAdding(maximumZ, 2),
          let width = autonomousLivestockAxisDistance(
              paddedMinimumX,
              paddedMaximumX
          ),
          let height = autonomousLivestockAxisDistance(
              paddedMinimumY,
              paddedMaximumY
          ),
          let depth = autonomousLivestockAxisDistance(
              paddedMinimumZ,
              paddedMaximumZ
          ),
          width <= 128,
          height <= 32,
          depth <= 128
    else { return nil }
    return AgentLivestockManagementArea(
        minimum: AgentPosition(
            x: paddedMinimumX,
            y: paddedMinimumY,
            z: paddedMinimumZ
        ),
        maximum: AgentPosition(
            x: paddedMaximumX,
            y: paddedMaximumY,
            z: paddedMaximumZ
        )
    )
}

private func autonomousLivestockDistance(
    _ lhs: AgentPosition,
    _ rhs: AgentPosition
) -> Int {
    let x = autonomousLivestockAxisDistance(lhs.x, rhs.x) ?? Int.max / 4
    let y = autonomousLivestockAxisDistance(lhs.y, rhs.y) ?? Int.max / 4
    let z = autonomousLivestockAxisDistance(lhs.z, rhs.z) ?? Int.max / 4
    let (xy, xyOverflow) = x.addingReportingOverflow(y)
    let (xyz, xyzOverflow) = xy.addingReportingOverflow(z)
    return xyOverflow || xyzOverflow ? Int.max : xyz
}

private func autonomousLivestockAxisDistance(
    _ lhs: Int,
    _ rhs: Int
) -> Int? {
    let (difference, overflow) = lhs.subtractingReportingOverflow(rhs)
    guard !overflow, difference != Int.min else { return nil }
    return Swift.abs(difference)
}

private func autonomousLivestockAdding(
    _ value: Int,
    _ adjustment: Int
) -> Int? {
    let (result, overflow) = value.addingReportingOverflow(adjustment)
    return overflow ? nil : result
}

private func autonomousLivestockSpeciesIsValid(_ value: String) -> Bool {
    (1...160).contains(value.utf8.count)
        && value.utf8.allSatisfy { (33...126).contains($0) }
}

private func autonomousLivestockCandidateKeyIsValid(_ value: String) -> Bool {
    (1...512).contains(value.utf8.count)
        && value.utf8.allSatisfy { (33...126).contains($0) }
}

private func autonomousLivestockCanonicalField(_ value: String) -> String {
    "\(value.utf8.count):\(value)"
}
