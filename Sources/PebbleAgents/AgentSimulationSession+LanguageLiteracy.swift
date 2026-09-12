/// Historical use receipt, not another competence store. CIV-42 checks its
/// existing sparse learned form/sense associations before issuing this receipt.
/// CIV-45's retained boundary protects accepted receipts after lexical mortality
/// cleanup or exposure-history compaction; current competence is never revived.
public struct AgentLanguageLiteracyReceipt: Codable, Equatable, Sendable {
    public let ownerID: AgentID
    public let associationIDs: [AgentLanguageAssociationID]
    public let knowledgeEventIDs: [AgentCausalEventID]
    public let languageBoundaryEventID: AgentCausalEventID
    public let useEventID: AgentCausalEventID
}

extension AgentSimulationSession {
    func validateWrittenRealization(_ realization: AgentLanguageRealization) throws {
        guard let language = languageState,
              realization.lexicalUses.count == 3,
              realization.lexicalUses.map(\.role) == [.referentKind, .predicate, .value],
              realization.lexicalUses.map({ AgentLanguageSenseUse(
                role: $0.role, senseID: $0.senseID
              ) }) == realization.semanticContent.senses,
              realization.lexicalUses.allSatisfy({
                languageLexicalAuthorityIsValid(
                    senseID: $0.senseID,
                    form: $0.form,
                    innovationID: $0.innovationID,
                    state: language
                )
              }),
              realization.rendering.text == languageDeterministicText(
                content: realization.semanticContent,
                lexicalUses: realization.lexicalUses
              ) else {
            throw AgentSessionError.language(.invalidState("written realization"))
        }
    }

    /// CIV-42 checks vocabulary only. CIV-45 separately requires causally
    /// learned written notation; oral lexical competence never grants it.
    func writtenLanguageAssociations(
        ownerID: AgentID, realization: AgentLanguageRealization
    ) throws -> [AgentLanguageLexicalAssociation] {
        guard let language = languageState, language.enabled,
              statesById[ownerID.rawValue] != nil else {
            throw AgentSessionError.language(.unknownAgent(ownerID.rawValue))
        }
        try validateWrittenRealization(realization)
        return try realization.lexicalUses.map { use in
            guard let association = language.lexicalAssociations.first(where: {
                $0.ownerID == ownerID && $0.packID == language.pack.packID
                    && $0.senseID == use.senseID && $0.form == use.form
                    && $0.competence == .known
            }) else {
                throw AgentSessionError.language(.missingLexicalKnowledge(use.senseID.rawValue))
            }
            return association
        }
    }

    mutating func useWrittenLanguage(
        ownerID: AgentID, realization: AgentLanguageRealization,
        recordID: String, cause: AgentCausalEventID
    ) throws -> AgentLanguageLiteracyReceipt {
        let associations = try writtenLanguageAssociations(
            ownerID: ownerID, realization: realization
        )
        guard let boundary = languageState?.provenanceBoundary else {
            throw AgentSessionError.language(.invalidState("literacy language boundary"))
        }
        let event = try requiredLanguageEvent(
            kind: .languageWrittenFormsUsed, actorID: ownerID, subjectID: nil,
            causes: Array(Set([cause, boundary.eventID])).sorted(),
            recordID: recordID,
            propositionID: realization.semanticContent.sourcePropositionID,
            status: "knownWrittenForms", reason: writingDigest(realization),
            summary: "language known written forms used"
        )
        return AgentLanguageLiteracyReceipt(
            ownerID: ownerID, associationIDs: associations.map(\.associationID),
            knowledgeEventIDs: associations.map(\.lastEventID),
            languageBoundaryEventID: boundary.eventID, useEventID: event.eventID
        )
    }

    func validateHistoricalWrittenLanguage(
        _ receipt: AgentLanguageLiteracyReceipt,
        ownerID: AgentID, realization: AgentLanguageRealization,
        recordID: String
    ) throws {
        try validateWrittenRealization(realization)
        guard let language = languageState,
              receipt.ownerID == ownerID,
              receipt.associationIDs == realization.lexicalUses.map({
                languageAssociationID(ownerID: ownerID, packID: language.pack.packID,
                                      senseID: $0.senseID, form: $0.form)
              }), receipt.knowledgeEventIDs.count == 3,
              receipt.knowledgeEventIDs.allSatisfy({
                $0.simulationID == simulationID && $0.sequence.rawValue > 0
                    && $0.sequence < receipt.useEventID.sequence
              }), receipt.languageBoundaryEventID.simulationID == simulationID,
              receipt.languageBoundaryEventID.sequence.rawValue > 0,
              receipt.languageBoundaryEventID.sequence < receipt.useEventID.sequence else {
            throw AgentSessionError.language(.invalidState("historical literacy receipt"))
        }
        for id in receipt.knowledgeEventIDs {
            if let event = causalLedger.events.first(where: { $0.eventID == id }) {
                guard event.origin == .languageTransition, event.subjectID == ownerID,
                      event.kind == .languagePriorSeeded
                        || event.kind == .languageSemanticCommunicated
                        || event.kind == .languageLexicalInnovated else {
                    throw AgentSessionError.language(.invalidState("written lexical acquisition event"))
                }
            } else if id.sequence.rawValue > causalLedger.droppedEventCount {
                throw AgentSessionError.language(.invalidState("missing written lexical acquisition"))
            }
        }
        if let event = causalLedger.events.first(where: { $0.eventID == receipt.languageBoundaryEventID }) {
            guard event.kind == .languageInitialized, event.origin == .languageTransition,
                  event.actorID == nil, event.subjectID == nil,
                  case let .language(recordID, _, status, _) = event.payload,
                  recordID == language.pack.packID.rawValue, status == "provenanceBoundary" else {
                throw AgentSessionError.language(.invalidState("written historical language boundary"))
            }
        } else if receipt.languageBoundaryEventID.sequence.rawValue > causalLedger.droppedEventCount {
            throw AgentSessionError.language(.invalidState("missing written language boundary"))
        }
        try validateWritingEvent(receipt.useEventID, kind: .languageWrittenFormsUsed,
            actorID: ownerID, payload: .language(recordID: recordID,
                propositionID: realization.semanticContent.sourcePropositionID.rawValue,
                status: "knownWrittenForms", reason: writingDigest(realization)))
    }
}
