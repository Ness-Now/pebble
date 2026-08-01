public struct AgentEstateID:
    RawRepresentable, Codable, Hashable, Comparable, Sendable
{
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...192).contains(rawValue.utf8.count),
              rawValue.utf8.allSatisfy({
                  (65...90).contains($0) || (97...122).contains($0)
                      || (48...57).contains($0) || $0 == 45 || $0 == 95
              }) else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct AgentEstateAssetEntryID:
    RawRepresentable, Codable, Hashable, Comparable, Sendable
{
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...224).contains(rawValue.utf8.count),
              rawValue.utf8.allSatisfy({
                  (65...90).contains($0) || (97...122).contains($0)
                      || (48...57).contains($0) || $0 == 45 || $0 == 95
              }) else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum AgentEstateError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration(String)
    case causalLedgerRequired
    case mortalityRequired
    case materialRightsRequired
    case lifecycleRequired
    case kinshipRequired
    case householdsRequired
    case childhoodRequired
    case familyRequired
    case alreadyEnabled
    case disabled
    case unsafeDisable
    case unknownEstate(AgentEstateID)
    case unknownAsset(AgentEstateAssetEntryID)
    case invalidAdministrator(AgentID)
    case invalidAcceptance(String)
    case invalidSettlement(String)
    case capacityExceeded(String)
    case invalidState(String)

    public var description: String {
        switch self {
        case let .invalidConfiguration(reason):
            return "invalid estate configuration: \(reason)"
        case .causalLedgerRequired: return "estates require the causal ledger"
        case .mortalityRequired: return "estates require mortality"
        case .materialRightsRequired: return "estates require Material Rights"
        case .lifecycleRequired: return "estates require lifecycle"
        case .kinshipRequired: return "estates require kinship"
        case .householdsRequired: return "estates require households"
        case .childhoodRequired: return "estates require childhood V2"
        case .familyRequired: return "estates require family V1"
        case .alreadyEnabled: return "estates already enabled"
        case .disabled: return "estates disabled"
        case .unsafeDisable: return "estate disable refused after durable activation"
        case let .unknownEstate(id): return "unknown estate \(id.rawValue)"
        case let .unknownAsset(id): return "unknown estate asset \(id.rawValue)"
        case let .invalidAdministrator(id):
            return "invalid estate administrator \(id.rawValue)"
        case let .invalidAcceptance(id):
            return "invalid estate administrator acceptance \(id)"
        case let .invalidSettlement(reason):
            return "invalid estate settlement: \(reason)"
        case let .capacityExceeded(bound):
            return "estate capacity exceeded: \(bound)"
        case let .invalidState(reason):
            return "invalid estate state: \(reason)"
        }
    }
}

public struct AgentEstateConfiguration: Codable, Equatable, Sendable {
    public let maximumRetainedEstates: Int
    public let maximumOpenEstates: Int
    public let maximumAssetsPerEstate: Int
    public let maximumObligationsPerEstate: Int
    public let maximumBeneficiariesPerEstate: Int
    public let maximumAdministrationsPerEstate: Int
    public let maximumSettlementAttemptsPerAsset: Int
    public let maximumProcessedOperationIDs: Int
    public let maximumTransitionsPerTick: Int

    public init(
        maximumRetainedEstates: Int = 32,
        maximumOpenEstates: Int = 32,
        maximumAssetsPerEstate: Int = 16,
        maximumObligationsPerEstate: Int = 16,
        maximumBeneficiariesPerEstate: Int = 32,
        maximumAdministrationsPerEstate: Int = 16,
        maximumSettlementAttemptsPerAsset: Int = 16,
        maximumProcessedOperationIDs: Int = 512,
        maximumTransitionsPerTick: Int = 128
    ) throws {
        guard (1...128).contains(maximumRetainedEstates),
              (1...64).contains(maximumOpenEstates),
              maximumOpenEstates <= maximumRetainedEstates,
              (1...64).contains(maximumAssetsPerEstate),
              (1...64).contains(maximumObligationsPerEstate),
              (1...64).contains(maximumBeneficiariesPerEstate),
              (1...32).contains(maximumAdministrationsPerEstate),
              (1...64).contains(maximumSettlementAttemptsPerAsset),
              (1...4096).contains(maximumProcessedOperationIDs),
              (1...512).contains(maximumTransitionsPerTick) else {
            throw AgentEstateError.invalidConfiguration("bounds")
        }
        self.maximumRetainedEstates = maximumRetainedEstates
        self.maximumOpenEstates = maximumOpenEstates
        self.maximumAssetsPerEstate = maximumAssetsPerEstate
        self.maximumObligationsPerEstate = maximumObligationsPerEstate
        self.maximumBeneficiariesPerEstate = maximumBeneficiariesPerEstate
        self.maximumAdministrationsPerEstate = maximumAdministrationsPerEstate
        self.maximumSettlementAttemptsPerAsset = maximumSettlementAttemptsPerAsset
        self.maximumProcessedOperationIDs = maximumProcessedOperationIDs
        self.maximumTransitionsPerTick = maximumTransitionsPerTick
    }

    public static let live = try! AgentEstateConfiguration()
}

public enum AgentEstateStatus: String, Codable, CaseIterable, Sendable {
    case openUnadministered
    case openAdministered
    case partiallySettled
    case blocked
    case settled
    case dormantNoSuccessor

    public var isTerminal: Bool {
        self == .settled
    }
}

public enum AgentEstateBeneficiaryTier: String, Codable, CaseIterable, Sendable {
    case primaryPartnerAndChildren
    case secondaryParents
    case tertiarySiblings
    case none
}

public enum AgentEstateBeneficiaryBasis: String, Codable, CaseIterable, Sendable {
    case activeUnionPartnerAtDeath
    case canonicalChild
    case canonicalParent
    case fullSibling
    case halfSibling
}

public struct AgentEstateBeneficiary: Codable, Equatable, Sendable {
    public let agentID: AgentID
    public let tier: AgentEstateBeneficiaryTier
    public let basis: AgentEstateBeneficiaryBasis
    public let weight: Int
    public let lifeStageAtPlan: AgentLifeStage
    public let guardianIDAtPlan: AgentID?
    public internal(set) var allocationCount: Int
}

public struct AgentEstateSuccessorEligibilityRow:
    Codable, Equatable, Sendable
{
    public let agentID: AgentID
    public let tier: AgentEstateBeneficiaryTier
    public let basis: AgentEstateBeneficiaryBasis
    public let eligibleAtDeath: Bool
    public let lifeStageAtPlan: AgentLifeStage?
    public let guardianIDAtPlan: AgentID?
}

public struct AgentEstateActiveUnionAtDeathEvidence:
    Codable, Equatable, Sendable
{
    public let unionID: AgentUnionID
    public let partnerID: AgentID
    public let activationTick: Int
    public let activationEventID: AgentCausalEventID
}

public struct AgentEstateSuccessorPlanProof:
    Codable, Equatable, Sendable
{
    public let version: Int
    public let estateID: AgentEstateID
    public let decedentID: AgentID
    public let deathID: AgentDeathID
    public let deathBoundaryTick: Int
    public let selectedTier: AgentEstateBeneficiaryTier
    public let eligibilityRows: [AgentEstateSuccessorEligibilityRow]
    public let activeUnionAtDeath:
        AgentEstateActiveUnionAtDeathEvidence?
    public let successorPlanEventID: AgentCausalEventID
    public let planDigest: String
}

public enum AgentEstateAdministratorBasis:
    String, Codable, CaseIterable, Sendable
{
    case activeUnionPartnerAtDeath
    case matureCanonicalChild
    case matureCanonicalParent
    case matureSibling
    case matureHouseholdAdult
}

public enum AgentEstateAdministrationStatus:
    String, Codable, CaseIterable, Sendable
{
    case nominated
    case active
    case ended
}

public enum AgentEstateAdministratorEndReason:
    String, Codable, CaseIterable, Sendable
{
    case died
    case incapacitated
    case migrating
    case unavailable
    case estateSettled
}

public struct AgentEstateAdministration: Codable, Equatable, Sendable {
    public let administratorID: AgentID
    public let basis: AgentEstateAdministratorBasis
    public let nominatedAtTick: Int
    public let lifeStageAtNomination: AgentLifeStage
    public let nominationEventID: AgentCausalEventID
    public internal(set) var acceptedAtTick: Int?
    public internal(set) var acceptanceOperationID: String?
    public internal(set) var acceptanceEventID: AgentCausalEventID?
    public internal(set) var endedAtTick: Int?
    public internal(set) var endedReason: AgentEstateAdministratorEndReason?
    public internal(set) var endedEventID: AgentCausalEventID?
    public internal(set) var status: AgentEstateAdministrationStatus
}

public enum AgentEstateAssetStatus: String, Codable, CaseIterable, Sendable {
    case pendingClassification
    case pendingSettlement
    case blocked
    case transferred
    case returnedToVerifiedOwner
    case nonTransferable

    public var isTerminal: Bool {
        self == .transferred || self == .returnedToVerifiedOwner
            || self == .nonTransferable
    }
}

public enum AgentEstateAssetBlockReason:
    String, Codable, CaseIterable, Sendable
{
    case sociallyUnregistered
    case physicalAssetMissing
    case physicalIdentityMismatch
    case quantityMismatch
    case unsafeContainer
    case thirdPartyClaim
    case ownerConflict
    case noAdministrator
    case noSuccessor
    case minorCustodyUnavailable
    case beneficiaryUnavailableForCustody
    case reconciliationPending
}

public struct AgentEstateAssetEntry: Codable, Equatable, Sendable {
    public let entryID: AgentEstateAssetEntryID
    public let materialRightsAssetID: AgentMaterialAssetID?
    public let materialIdentity: AgentMaterialIdentitySnapshot
    public let quantity: Int
    public let mortalityExitReceiptID: String
    public let mortalityExitHolderID: String?
    public let mortalityExitTick: Int
    public let holderAtOpening: AgentMaterialHolderObservation?
    public let custodianAtOpening: AgentID?
    public let ownerAtOpening: AgentMaterialRecognizedOwnership?
    public let claimsAtOpening: [AgentMaterialClaim]
    public let permissionsAtOpening: [AgentMaterialUsePermission]
    public internal(set) var classificationEventID: AgentCausalEventID?
    public let assignedBeneficiaryID: AgentID?
    public internal(set) var intendedCustodianID: AgentID?
    public internal(set) var custodyRevalidatedAtTick: Int?
    public internal(set) var custodyRevalidationEventID: AgentCausalEventID?
    public internal(set) var status: AgentEstateAssetStatus
    public internal(set) var blockReason: AgentEstateAssetBlockReason?
    public internal(set) var settlementAttemptCount: Int
    public internal(set) var destinationObservation:
        AgentMaterialHolderObservation?
    public internal(set) var settlementObservation:
        AgentMaterialHolderObservation?
    public internal(set) var settlementReceiptID: String?
    public internal(set) var settlementEventID: AgentCausalEventID?
}

public enum AgentEstateObligationDisposition:
    String, Codable, CaseIterable, Sendable
{
    case personalEnded
    case nonTransferable
}

public struct AgentEstateObligationEntry: Codable, Equatable, Sendable {
    public let referenceID: String
    public let disposition: AgentEstateObligationDisposition
    public let reason: String
    public let sourceEventID: AgentCausalEventID
}

public struct AgentEstateRecord: Codable, Equatable, Sendable {
    public let estateID: AgentEstateID
    public let decedentID: AgentID
    public let deathID: AgentDeathID
    public let deathTick: Int
    public let schemaVersion: Int
    public let physicalCustodyResolution:
        AgentMortalityPhysicalCustodyResolution
    public let openedAtTick: Int
    public let openingEventID: AgentCausalEventID
    public let successorPlanEventID: AgentCausalEventID
    public let successorPlanProof: AgentEstateSuccessorPlanProof?
    public let beneficiaryTier: AgentEstateBeneficiaryTier
    public internal(set) var status: AgentEstateStatus
    public internal(set) var deathEventID: AgentCausalEventID?
    public internal(set) var administrations: [AgentEstateAdministration]
    public internal(set) var beneficiaries: [AgentEstateBeneficiary]
    public internal(set) var assets: [AgentEstateAssetEntry]
    public internal(set) var obligations: [AgentEstateObligationEntry]
    public internal(set) var settledAtTick: Int?
    public internal(set) var settledEventID: AgentCausalEventID?
    public internal(set) var lastEventID: AgentCausalEventID
}

public struct AgentEstateEvictionCounts: Codable, Equatable, Sendable {
    public internal(set) var settledEstates: Int

    public init(settledEstates: Int = 0) {
        self.settledEstates = max(0, settledEstates)
    }
}

public struct AgentEstateState: Codable, Equatable, Sendable {
    public let configuration: AgentEstateConfiguration
    public let activationTick: Int
    public let activationDeathCount: Int
    public let initializedEventID: AgentCausalEventID
    public internal(set) var estates: [AgentEstateRecord]
    public internal(set) var processedOperationIDs: [String]
    public internal(set) var transitionTick: Int
    public internal(set) var transitionsAtTick: Int
    public internal(set) var totalEstateCount: Int
    public internal(set) var totalSettlementCount: Int
    public internal(set) var evictionCounts: AgentEstateEvictionCounts
    public internal(set) var rollingDigest: String
    public internal(set) var lastEventID: AgentCausalEventID
}

public struct AgentEstateSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let activationTick: Int?
    public let configuration: AgentEstateConfiguration?
    public let estates: [AgentEstateRecord]
    public let totalEstateCount: Int
    public let totalSettlementCount: Int
    public let evictionCounts: AgentEstateEvictionCounts
    public let digest: String
}

public struct AgentEstatePhysicalSettlementOutcome:
    Codable, Equatable, Sendable
{
    public let operationID: String
    public let estateID: AgentEstateID
    public let entryID: AgentEstateAssetEntryID
    public let administratorID: AgentID
    public let beneficiaryID: AgentID
    public let intendedCustodianID: AgentID?
    public let sourceObservation: AgentMaterialHolderObservation
    public let destinationObservation: AgentMaterialHolderObservation
    public let sourceFingerprintAfterTransfer: String
    public let destinationFingerprintBeforeTransfer: String
    public let physicalReceiptID: String

    public init(
        operationID: String,
        estateID: AgentEstateID,
        entryID: AgentEstateAssetEntryID,
        administratorID: AgentID,
        beneficiaryID: AgentID,
        intendedCustodianID: AgentID?,
        sourceObservation: AgentMaterialHolderObservation,
        destinationObservation: AgentMaterialHolderObservation,
        sourceFingerprintAfterTransfer: String,
        destinationFingerprintBeforeTransfer: String,
        physicalReceiptID: String
    ) {
        self.operationID = operationID
        self.estateID = estateID
        self.entryID = entryID
        self.administratorID = administratorID
        self.beneficiaryID = beneficiaryID
        self.intendedCustodianID = intendedCustodianID
        self.sourceObservation = sourceObservation
        self.destinationObservation = destinationObservation
        self.sourceFingerprintAfterTransfer = sourceFingerprintAfterTransfer
        self.destinationFingerprintBeforeTransfer =
            destinationFingerprintBeforeTransfer
        self.physicalReceiptID = physicalReceiptID
    }
}

enum AgentEstateDigest {
    static func make(_ text: String) -> String {
        AgentMortalityDigest.make("estate-v1|\(text)")
    }
}
