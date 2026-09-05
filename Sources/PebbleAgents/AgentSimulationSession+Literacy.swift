public struct AgentWritingLesson: Codable, Equatable, Sendable {
    public let teacherID: AgentID
    public let teacherGrantEventID: AgentCausalEventID
    public let artifactID: String
    public let teacherReceipt: AgentWritingPhysicalReceipt
    public let learnerReceipt: AgentWritingPhysicalReceipt
    public let lexicalUse: AgentLanguageLiteracyReceipt
    public let eventID: AgentCausalEventID
}

/// Capability for the one V1 four-line notation, distinct from knowing words.
/// Two explicit local guided uses establish it. Founders may receive an
/// explicitly recorded educational prior; activation grants nobody literacy.
/// Rows are historical learning evidence; a departed owner has no capability.
public struct AgentWritingLiteracyRecord: Codable, Equatable, Sendable {
    public let ownerID: AgentID
    public let packID: AgentLanguagePackID
    public let priorEventID: AgentCausalEventID?
    public internal(set) var lessons: [AgentWritingLesson]
    public var grantEventID: AgentCausalEventID? {
        priorEventID ?? (lessons.count == 2 ? lessons.last?.eventID : nil)
    }
}

extension AgentSimulationSession {
    public func canUseWritingNotation(_ ownerID: AgentID) -> Bool {
        statesById[ownerID.rawValue] != nil && writingState?.literacyRecords.contains(where: {
            $0.ownerID == ownerID && $0.grantEventID != nil
        }) == true
    }

    func requireWritingLiteracy(_ ownerID: AgentID) throws {
        guard canUseWritingNotation(ownerID) else {
            throw AgentWritingError.unavailable("written notation not learned")
        }
    }

    public mutating func seedWritingEducationalPrior(for ownerID: AgentID) throws {
        guard var state = writingState, state.enabled, let language = languageState,
              statesById[ownerID.rawValue] != nil,
              !state.literacyRecords.contains(where: { $0.ownerID == ownerID }),
              state.literacyRecords.count < state.configuration.maximumLiteracyRecords else {
            throw AgentWritingError.unavailable("literacy prior admission")
        }
        var candidate = self
        let event = try candidate.requiredWritingEvent(.writingLiteracyAcquired,
            actorID: ownerID, recordID: ownerID.rawValue,
            detail: "explicitEducationalPrior:\(language.pack.packID.rawValue)")
        state.literacyRecords.append(AgentWritingLiteracyRecord(ownerID: ownerID,
            packID: language.pack.packID, priorEventID: event.eventID, lessons: []))
        state.literacyRecords.sort { $0.ownerID < $1.ownerID }
        // Preserve a boundary refreshed by this operation's causal append.
        state.boundary = candidate.writingState?.boundary
        candidate.writingState = state
        try candidate.commitWritingBoundary(causes: [event.eventID])
        try candidate.validateWritingState()
        self = candidate
    }

    public mutating func practiceWritingNotation(artifactID: String, teacherID: AgentID,
        learnerID: AgentID, teacherReceipt: AgentWritingPhysicalReceipt,
        learnerReceipt: AgentWritingPhysicalReceipt) throws {
        guard let state = writingState, state.enabled,
              teacherID != learnerID, !canUseWritingNotation(learnerID),
              let artifact = state.artifacts.first(where: { $0.artifactID == artifactID }),
              let teacherGrant = state.literacyRecords.first(where: {
                $0.ownerID == teacherID
              })?.grantEventID else { throw AgentWritingError.unavailable("notation lesson") }
        try requireWritingLiteracy(teacherID)
        try requireWritingReceipt(teacherReceipt, plan: artifact.plan, actorID: teacherID)
        try requireWritingReceipt(learnerReceipt, plan: artifact.plan, actorID: learnerID)
        _ = try writtenLanguageAssociations(ownerID: teacherID, realization: artifact.plan.realization)
        _ = try writtenLanguageAssociations(ownerID: learnerID, realization: artifact.plan.realization)
        var record = state.literacyRecords.first(where: { $0.ownerID == learnerID })
            ?? AgentWritingLiteracyRecord(ownerID: learnerID, packID: languageState!.pack.packID,
                                          priorEventID: nil, lessons: [])
        guard record.lessons.allSatisfy({ $0.learnerReceipt.observedAtTick < tick }),
              record.lessons.count < 2,
              state.literacyRecords.contains(where: { $0.ownerID == learnerID })
                || state.literacyRecords.count < state.configuration.maximumLiteracyRecords else {
            throw AgentWritingError.unavailable("lesson repetition or literacy capacity")
        }
        var candidate = self
        let recordID = "lesson:\(learnerID.rawValue):\(record.lessons.count + 1)"
        let lexicalUse = try candidate.useWrittenLanguage(ownerID: learnerID,
            realization: artifact.plan.realization, recordID: recordID, cause: artifact.inscriptionEventID)
        let event = try candidate.requiredWritingEvent(.writingLiteracyAcquired,
            actorID: learnerID, causes: [lexicalUse.useEventID, teacherGrant],
            recordID: recordID, detail: writingDigest([teacherReceipt, learnerReceipt]))
        record.lessons.append(AgentWritingLesson(teacherID: teacherID,
            teacherGrantEventID: teacherGrant, artifactID: artifactID,
            teacherReceipt: teacherReceipt, learnerReceipt: learnerReceipt,
            lexicalUse: lexicalUse, eventID: event.eventID))
        candidate.writingState!.literacyRecords.removeAll { $0.ownerID == learnerID }
        candidate.writingState!.literacyRecords.append(record)
        candidate.writingState!.literacyRecords.sort { $0.ownerID < $1.ownerID }
        try candidate.commitWritingBoundary(causes: [event.eventID])
        try candidate.validateWritingState()
        self = candidate
    }

    func validateWritingLiteracy() throws {
        guard let state = writingState, let language = languageState else { return }
        let records = state.literacyRecords
        guard records.count <= state.configuration.maximumLiteracyRecords,
              Set(records.map(\.ownerID)).count == records.count,
              records.map(\.ownerID) == records.map(\.ownerID).sorted() else {
            throw AgentWritingError.invalidState("literacy identities and bound")
        }
        for record in records {
            guard record.packID == language.pack.packID,
                  AgentID(rawValue: record.ownerID.rawValue) != nil else {
                throw AgentWritingError.invalidState("literacy owner/pack")
            }
            if let prior = record.priorEventID {
                guard record.lessons.isEmpty else { throw AgentWritingError.invalidState("prior plus lessons") }
                try validateWritingEvent(prior, kind: .writingLiteracyAcquired,
                    actorID: record.ownerID, payload: .writing(recordID: record.ownerID.rawValue,
                        detail: "explicitEducationalPrior:\(record.packID.rawValue)"))
            } else {
                guard (1...2).contains(record.lessons.count) else {
                    throw AgentWritingError.invalidState("literacy learning count")
                }
                var previousTick = -1
                for (index, lesson) in record.lessons.enumerated() {
                    let recordID = "lesson:\(record.ownerID.rawValue):\(index + 1)"
                    guard lesson.teacherID != record.ownerID,
                          let grant = records.first(where: { $0.ownerID == lesson.teacherID })?.grantEventID,
                          grant == lesson.teacherGrantEventID, grant.sequence < lesson.eventID.sequence,
                          let artifact = state.artifacts.first(where: { $0.artifactID == lesson.artifactID }),
                          writingReceiptMatches(lesson.teacherReceipt, plan: artifact.plan),
                          writingReceiptMatches(lesson.learnerReceipt, plan: artifact.plan),
                          lesson.teacherReceipt.actorID == lesson.teacherID,
                          lesson.learnerReceipt.actorID == record.ownerID,
                          lesson.teacherReceipt.observedAtTick == lesson.learnerReceipt.observedAtTick,
                          lesson.learnerReceipt.observedAtTick > previousTick,
                          lesson.learnerReceipt.observedAtTick <= tick,
                          lesson.learnerReceipt.observedAtTick >= artifact.plan.preparedAtTick,
                          artifact.inscriptionEventID.sequence < lesson.lexicalUse.useEventID.sequence,
                          lesson.lexicalUse.useEventID.sequence < lesson.eventID.sequence else {
                        throw AgentWritingError.invalidState("causal local notation lesson")
                    }
                    previousTick = lesson.learnerReceipt.observedAtTick
                    try validateHistoricalWrittenLanguage(lesson.lexicalUse, ownerID: record.ownerID,
                        realization: artifact.plan.realization, recordID: recordID)
                    try validateWritingEvent(lesson.eventID, kind: .writingLiteracyAcquired,
                        actorID: record.ownerID, payload: .writing(recordID: recordID,
                            detail: writingDigest([lesson.teacherReceipt, lesson.learnerReceipt])))
                }
            }
        }
        for artifact in state.artifacts {
            try validateHistoricalNotationGrant(ownerID: artifact.plan.authorID,
                                               useEventID: artifact.literacy.useEventID)
        }
        for reading in state.readings {
            try validateHistoricalNotationGrant(ownerID: reading.readerID,
                                               useEventID: reading.literacy.useEventID)
        }
    }

    private func validateHistoricalNotationGrant(ownerID: AgentID, useEventID: AgentCausalEventID) throws {
        guard let grant = writingState?.literacyRecords.first(where: { $0.ownerID == ownerID })?.grantEventID,
              grant.sequence < useEventID.sequence else {
            throw AgentWritingError.invalidState("writing without learned notation")
        }
    }
}
