public struct AgentMaterialAssetID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...160).contains(rawValue.count),
              rawValue.allSatisfy({
                  $0.isASCII && ($0.isLetter || $0.isNumber || "-_:.".contains($0))
              }) else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentMaterialClaimID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...160).contains(rawValue.count),
              rawValue.allSatisfy({
                  $0.isASCII && ($0.isLetter || $0.isNumber || "-_:.".contains($0))
              }) else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentMaterialPermissionID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...160).contains(rawValue.count),
              rawValue.allSatisfy({
                  $0.isASCII && ($0.isLetter || $0.isNumber || "-_:.".contains($0))
              }) else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// A Civilization reference to a bounded quantity of one physical stack
/// identity. Pebble currently has no per-unit UUID: compatible units are
/// fungible and this reference must be rebound only from verified Pebble
/// observations. It is neither an item nor an inventory entry.
public struct AgentMaterialAssetReference: Codable, Equatable, Sendable {
    public let assetID: AgentMaterialAssetID
    public let materialIdentity: AgentMaterialIdentitySnapshot
    public let quantity: Int

    public init(
        assetID: AgentMaterialAssetID,
        materialIdentity: AgentMaterialIdentitySnapshot,
        quantity: Int
    ) {
        self.assetID = assetID
        self.materialIdentity = materialIdentity
        self.quantity = quantity
    }
}

/// Last verified physical holder observation. PebbleCore remains authoritative;
/// a checkpoint restores this observation, not the World or a holder.
public enum AgentMaterialPhysicalHolder: Codable, Equatable, Hashable, Sendable {
    case agent(AgentID)
    case container(String)

    public var stableText: String {
        switch self {
        case let .agent(id): return "agent:\(id.rawValue)"
        case let .container(id): return "container:\(id)"
        }
    }
}

public struct AgentMaterialHolderObservation: Codable, Equatable, Sendable {
    public let holder: AgentMaterialPhysicalHolder
    public let materialIdentity: AgentMaterialIdentitySnapshot
    public let quantity: Int
    public let custodyFingerprint: String
    public let physicalReceiptID: String
    public let observedAtTick: Int

    public init(
        holder: AgentMaterialPhysicalHolder,
        materialIdentity: AgentMaterialIdentitySnapshot,
        quantity: Int,
        custodyFingerprint: String,
        physicalReceiptID: String,
        observedAtTick: Int
    ) {
        self.holder = holder
        self.materialIdentity = materialIdentity
        self.quantity = quantity
        self.custodyFingerprint = custodyFingerprint
        self.physicalReceiptID = physicalReceiptID
        self.observedAtTick = observedAtTick
    }
}

public enum AgentMaterialClaimBasis: String, Codable, CaseIterable, Sendable {
    case produced
    case received
    case found
    case retained
    case contested
}

public struct AgentMaterialClaim: Codable, Equatable, Sendable {
    public let claimID: AgentMaterialClaimID
    public let claimantID: AgentID
    public let basis: AgentMaterialClaimBasis
    public let assertedAtTick: Int

    public init(
        claimID: AgentMaterialClaimID,
        claimantID: AgentID,
        basis: AgentMaterialClaimBasis,
        assertedAtTick: Int
    ) {
        self.claimID = claimID
        self.claimantID = claimantID
        self.basis = basis
        self.assertedAtTick = assertedAtTick
    }
}

/// Recognition is explicitly local: only these bounded witnesses recognize the
/// selected claim. It is not settlement-wide consensus or a legal oracle.
public struct AgentMaterialRecognizedOwnership: Codable, Equatable, Sendable {
    public let claimID: AgentMaterialClaimID
    public let ownerID: AgentID
    public let recognizingAgentIDs: [AgentID]
    public let recognizedAtTick: Int

    public init(
        claimID: AgentMaterialClaimID,
        ownerID: AgentID,
        recognizingAgentIDs: [AgentID],
        recognizedAtTick: Int
    ) {
        self.claimID = claimID
        self.ownerID = ownerID
        self.recognizingAgentIDs = recognizingAgentIDs.sorted()
        self.recognizedAtTick = recognizedAtTick
    }
}

public enum AgentMaterialUseKind: String, Codable, CaseIterable, Comparable, Sendable {
    case transferCustody
    case consume
    case place
    case toolUse

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentMaterialUsePermission: Codable, Equatable, Sendable {
    public let permissionID: AgentMaterialPermissionID
    public let grantorID: AgentID
    public let userID: AgentID
    public let allowedUses: [AgentMaterialUseKind]
    public let grantedAtTick: Int
    public let expiresAtTick: Int?

    public init(
        permissionID: AgentMaterialPermissionID,
        grantorID: AgentID,
        userID: AgentID,
        allowedUses: [AgentMaterialUseKind],
        grantedAtTick: Int,
        expiresAtTick: Int? = nil
    ) {
        self.permissionID = permissionID
        self.grantorID = grantorID
        self.userID = userID
        self.allowedUses = Array(Set(allowedUses)).sorted()
        self.grantedAtTick = grantedAtTick
        self.expiresAtTick = expiresAtTick
    }

    public func permits(_ use: AgentMaterialUseKind, at tick: Int) -> Bool {
        allowedUses.contains(use) && (expiresAtTick.map { tick <= $0 } ?? true)
    }
}

public struct AgentMaterialRightsConfiguration: Codable, Equatable, Sendable {
    public let maximumAssets: Int
    public let maximumClaimsPerAsset: Int
    public let maximumPermissionsPerAsset: Int
    public let maximumRecognitionWitnesses: Int
    public let maximumRetainedTransitions: Int
    public let maximumProcessedOperationIDs: Int

    public init(
        maximumAssets: Int = 128,
        maximumClaimsPerAsset: Int = 8,
        maximumPermissionsPerAsset: Int = 16,
        maximumRecognitionWitnesses: Int = 32,
        maximumRetainedTransitions: Int = 256,
        maximumProcessedOperationIDs: Int = 512
    ) throws {
        guard (1...512).contains(maximumAssets),
              (1...32).contains(maximumClaimsPerAsset),
              (1...64).contains(maximumPermissionsPerAsset),
              (1...128).contains(maximumRecognitionWitnesses),
              (1...4096).contains(maximumRetainedTransitions),
              (1...4096).contains(maximumProcessedOperationIDs) else {
            throw AgentMaterialRightsError.invalidConfiguration
        }
        self.maximumAssets = maximumAssets
        self.maximumClaimsPerAsset = maximumClaimsPerAsset
        self.maximumPermissionsPerAsset = maximumPermissionsPerAsset
        self.maximumRecognitionWitnesses = maximumRecognitionWitnesses
        self.maximumRetainedTransitions = maximumRetainedTransitions
        self.maximumProcessedOperationIDs = maximumProcessedOperationIDs
    }

    public static let live = try! AgentMaterialRightsConfiguration()
}

public struct AgentMaterialRightsRecord: Codable, Equatable, Sendable {
    public let asset: AgentMaterialAssetReference
    public internal(set) var lastVerifiedHolder: AgentMaterialHolderObservation
    public internal(set) var custodianID: AgentID?
    public internal(set) var claims: [AgentMaterialClaim]
    public internal(set) var recognizedOwnership: AgentMaterialRecognizedOwnership?
    public internal(set) var permissions: [AgentMaterialUsePermission]

    public init(
        asset: AgentMaterialAssetReference,
        lastVerifiedHolder: AgentMaterialHolderObservation,
        custodianID: AgentID? = nil,
        claims: [AgentMaterialClaim] = [],
        recognizedOwnership: AgentMaterialRecognizedOwnership? = nil,
        permissions: [AgentMaterialUsePermission] = []
    ) {
        self.asset = asset
        self.lastVerifiedHolder = lastVerifiedHolder
        self.custodianID = custodianID
        self.claims = claims.sorted { $0.claimID < $1.claimID }
        self.recognizedOwnership = recognizedOwnership
        self.permissions = permissions.sorted { $0.permissionID < $1.permissionID }
    }

    public var hasConflict: Bool {
        let claimants = Set(claims.map(\.claimantID))
        guard !claimants.isEmpty else { return false }
        return claimants.count > 1
            || recognizedOwnership.map { !claimants.contains($0.ownerID) } == true
    }
}

public enum AgentMaterialUseVerdict: String, Codable, Sendable {
    case allowed
    case denied
}

public enum AgentMaterialUseReason: String, Codable, Sendable {
    case recognizedOwner
    case explicitPermission
    case unknownAsset
    case stalePhysicalObservation
    case physicalAssetUnresolved
    case requesterNotPhysicalHolder
    case noUseRight
}

public struct AgentMaterialUseRequest: Codable, Equatable, Sendable {
    public let requestID: String
    public let assetID: AgentMaterialAssetID
    public let actorID: AgentID
    public let use: AgentMaterialUseKind
    public let verifiedHolder: AgentMaterialHolderObservation

    public init(
        requestID: String,
        assetID: AgentMaterialAssetID,
        actorID: AgentID,
        use: AgentMaterialUseKind,
        verifiedHolder: AgentMaterialHolderObservation
    ) {
        self.requestID = requestID
        self.assetID = assetID
        self.actorID = actorID
        self.use = use
        self.verifiedHolder = verifiedHolder
    }
}

public struct AgentMaterialUseDecision: Codable, Equatable, Sendable {
    public let request: AgentMaterialUseRequest
    public let verdict: AgentMaterialUseVerdict
    public let reason: AgentMaterialUseReason
    public let conflictObserved: Bool

    public init(
        request: AgentMaterialUseRequest,
        verdict: AgentMaterialUseVerdict,
        reason: AgentMaterialUseReason,
        conflictObserved: Bool
    ) {
        self.request = request
        self.verdict = verdict
        self.reason = reason
        self.conflictObserved = conflictObserved
    }
}

public enum AgentMaterialPhysicalAttemptStatus: String, Codable, Sendable {
    case notAttempted
    case succeeded
    case failed
    case rolledBack
}

public enum AgentMaterialExecutionDisposition: String, Codable, Sendable {
    case authorized
    case observedTransgression
}

public struct AgentMaterialPhysicalTransferOutcome: Codable, Equatable, Sendable {
    public let operationID: String
    public let decision: AgentMaterialUseDecision
    public let disposition: AgentMaterialExecutionDisposition
    public let status: AgentMaterialPhysicalAttemptStatus
    public let destinationObservation: AgentMaterialHolderObservation?
    public let physicalReceiptID: String?

    public init(
        operationID: String,
        decision: AgentMaterialUseDecision,
        disposition: AgentMaterialExecutionDisposition,
        status: AgentMaterialPhysicalAttemptStatus,
        destinationObservation: AgentMaterialHolderObservation?,
        physicalReceiptID: String?
    ) {
        self.operationID = operationID
        self.decision = decision
        self.disposition = disposition
        self.status = status
        self.destinationObservation = destinationObservation
        self.physicalReceiptID = physicalReceiptID
    }
}

public struct AgentMaterialUseAttemptOutcome: Codable, Equatable, Sendable {
    public let operationID: String
    public let decision: AgentMaterialUseDecision
    public let status: AgentMaterialPhysicalAttemptStatus
    public let resultingObservation: AgentMaterialHolderObservation?
    public let physicalReceiptID: String?

    public init(
        operationID: String,
        decision: AgentMaterialUseDecision,
        status: AgentMaterialPhysicalAttemptStatus,
        resultingObservation: AgentMaterialHolderObservation?,
        physicalReceiptID: String?
    ) {
        self.operationID = operationID
        self.decision = decision
        self.status = status
        self.resultingObservation = resultingObservation
        self.physicalReceiptID = physicalReceiptID
    }
}

/// A Pebble-verified physical exit for one rights-tracked asset held by an
/// actor whose physiology is terminal. It changes only the observed physical
/// holder; custody, ownership, claims, and permissions remain untouched.
public struct AgentMaterialMortalityExitOutcome: Codable, Equatable, Sendable {
    public let operationID: String
    public let assetID: AgentMaterialAssetID
    public let terminalAgentID: AgentID
    public let sourceObservation: AgentMaterialHolderObservation
    public let destinationObservation: AgentMaterialHolderObservation
    public let physicalReceiptID: String

    public init(
        operationID: String,
        assetID: AgentMaterialAssetID,
        terminalAgentID: AgentID,
        sourceObservation: AgentMaterialHolderObservation,
        destinationObservation: AgentMaterialHolderObservation,
        physicalReceiptID: String
    ) {
        self.operationID = operationID
        self.assetID = assetID
        self.terminalAgentID = terminalAgentID
        self.sourceObservation = sourceObservation
        self.destinationObservation = destinationObservation
        self.physicalReceiptID = physicalReceiptID
    }
}

public enum AgentMaterialRightsOperation: Codable, Equatable, Sendable {
    case register(
        operationID: String,
        asset: AgentMaterialAssetReference,
        observation: AgentMaterialHolderObservation
    )
    case assertClaim(
        operationID: String,
        assetID: AgentMaterialAssetID,
        claimID: AgentMaterialClaimID,
        claimantID: AgentID,
        basis: AgentMaterialClaimBasis
    )
    case withdrawClaim(
        operationID: String,
        assetID: AgentMaterialAssetID,
        claimID: AgentMaterialClaimID,
        actorID: AgentID
    )
    case recognizeOwnership(
        operationID: String,
        assetID: AgentMaterialAssetID,
        claimID: AgentMaterialClaimID,
        recognizingAgentIDs: [AgentID]
    )
    case delegateCustody(
        operationID: String,
        assetID: AgentMaterialAssetID,
        custodianID: AgentID,
        actorID: AgentID
    )
    case grantUse(
        operationID: String,
        assetID: AgentMaterialAssetID,
        permissionID: AgentMaterialPermissionID,
        grantorID: AgentID,
        userID: AgentID,
        allowedUses: [AgentMaterialUseKind],
        expiresAtTick: Int?
    )
    case revokeUse(
        operationID: String,
        assetID: AgentMaterialAssetID,
        permissionID: AgentMaterialPermissionID,
        actorID: AgentID
    )
    case physicalTransfer(AgentMaterialPhysicalTransferOutcome)
    case useAttempt(AgentMaterialUseAttemptOutcome)
    case mortalityPhysicalExit(AgentMaterialMortalityExitOutcome)

    public var operationID: String {
        switch self {
        case let .register(id, _, _),
             let .assertClaim(id, _, _, _, _),
             let .withdrawClaim(id, _, _, _),
             let .recognizeOwnership(id, _, _, _),
             let .delegateCustody(id, _, _, _),
             let .grantUse(id, _, _, _, _, _, _),
             let .revokeUse(id, _, _, _):
            return id
        case let .physicalTransfer(outcome): return outcome.operationID
        case let .useAttempt(outcome): return outcome.operationID
        case let .mortalityPhysicalExit(outcome): return outcome.operationID
        }
    }
}

public enum AgentMaterialRightsTransitionKind: String, Codable, Sendable {
    case assetRegistered
    case claimAsserted
    case claimWithdrawn
    case ownershipRecognized
    case custodyDelegated
    case useGranted
    case useRevoked
    case physicalTransfer
    case useAttempt
    case mortalityPhysicalExit
}

public struct AgentMaterialRightsTransition: Codable, Equatable, Sendable {
    public let operationID: String
    public let kind: AgentMaterialRightsTransitionKind
    public let assetID: AgentMaterialAssetID
    public let status: String
    public let reason: String
    public let eventID: AgentCausalEventID?

    public init(
        operationID: String,
        kind: AgentMaterialRightsTransitionKind,
        assetID: AgentMaterialAssetID,
        status: String,
        reason: String,
        eventID: AgentCausalEventID?
    ) {
        self.operationID = operationID
        self.kind = kind
        self.assetID = assetID
        self.status = status
        self.reason = reason
        self.eventID = eventID
    }
}

public struct AgentMaterialRightsState: Codable, Equatable, Sendable {
    public let configuration: AgentMaterialRightsConfiguration
    public internal(set) var records: [AgentMaterialRightsRecord]
    public internal(set) var recentTransitions: [AgentMaterialRightsTransition]
    public internal(set) var processedOperationIDs: [String]
    public internal(set) var droppedTransitionCount: UInt64
    public internal(set) var droppedOperationIDCount: UInt64

    public init(
        configuration: AgentMaterialRightsConfiguration = .live,
        records: [AgentMaterialRightsRecord] = [],
        recentTransitions: [AgentMaterialRightsTransition] = [],
        processedOperationIDs: [String] = [],
        droppedTransitionCount: UInt64 = 0,
        droppedOperationIDCount: UInt64 = 0
    ) {
        self.configuration = configuration
        self.records = records.sorted { $0.asset.assetID < $1.asset.assetID }
        self.recentTransitions = recentTransitions
        self.processedOperationIDs = processedOperationIDs
        self.droppedTransitionCount = droppedTransitionCount
        self.droppedOperationIDCount = droppedOperationIDCount
    }
}

public struct AgentMaterialRightsSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let records: [AgentMaterialRightsRecord]
    public let recentTransitions: [AgentMaterialRightsTransition]
    public let droppedTransitionCount: UInt64
    public let conflictCount: Int

    public init(state: AgentMaterialRightsState?) {
        enabled = state != nil
        records = state?.records ?? []
        recentTransitions = state?.recentTransitions ?? []
        droppedTransitionCount = state?.droppedTransitionCount ?? 0
        conflictCount = records.filter(\.hasConflict).count
    }
}

public enum AgentMaterialRightsApplicationStatus: String, Codable, Sendable {
    case applied
    case duplicate
}

public struct AgentMaterialRightsApplicationResult: Codable, Equatable, Sendable {
    public let status: AgentMaterialRightsApplicationStatus
    public let operationID: String
    public let assetID: AgentMaterialAssetID
}

public enum AgentMaterialRightsError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration
    case disabled
    case causalLedgerRequired
    case invalidOperation(String)
    case unknownAsset(AgentMaterialAssetID)
    case unknownAgent(AgentID)
    case assetLimitReached
    case claimLimitReached
    case permissionLimitReached
    case recognitionLimitReached
    case duplicateAsset(AgentMaterialAssetID)
    case duplicateClaim(AgentMaterialClaimID)
    case duplicatePermission(AgentMaterialPermissionID)
    case unknownClaim(AgentMaterialClaimID)
    case unknownPermission(AgentMaterialPermissionID)
    case unauthorized(String)
    case stalePhysicalObservation(AgentMaterialAssetID)
    case invalidPhysicalOutcome(String)
    case invalidState(String)

    public var description: String {
        switch self {
        case .invalidConfiguration: return "invalid material-rights configuration"
        case .disabled: return "material rights disabled"
        case .causalLedgerRequired: return "material rights require causal ledger"
        case let .invalidOperation(id): return "invalid material-rights operation \(id)"
        case let .unknownAsset(id): return "unknown material asset \(id.rawValue)"
        case let .unknownAgent(id): return "unknown material-rights agent \(id.rawValue)"
        case .assetLimitReached: return "material asset limit reached"
        case .claimLimitReached: return "material claim limit reached"
        case .permissionLimitReached: return "material permission limit reached"
        case .recognitionLimitReached: return "material recognition witness limit reached"
        case let .duplicateAsset(id): return "duplicate material asset \(id.rawValue)"
        case let .duplicateClaim(id): return "duplicate material claim \(id.rawValue)"
        case let .duplicatePermission(id): return "duplicate material permission \(id.rawValue)"
        case let .unknownClaim(id): return "unknown material claim \(id.rawValue)"
        case let .unknownPermission(id): return "unknown material permission \(id.rawValue)"
        case let .unauthorized(reason): return "unauthorized material-rights transition: \(reason)"
        case let .stalePhysicalObservation(id):
            return "stale physical observation for \(id.rawValue)"
        case let .invalidPhysicalOutcome(id): return "invalid physical outcome \(id)"
        case let .invalidState(reason): return "invalid material-rights state: \(reason)"
        }
    }
}
