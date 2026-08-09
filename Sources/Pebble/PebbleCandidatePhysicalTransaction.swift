import Foundation
import PebbleAgents
import PebbleCore

enum PebbleCandidateBufferedWorldEffect {
    case sound(String, Double, Double, Double, Double, Double)
    case particles(String, Double, Double, Double, Int, Double, Int)
    case vibration(Double, Double, Double, Int, EntityRef?)
}

func captureCandidateWorldEffects<Result>(
    world: World,
    operation: () throws -> Result
) rethrows -> (Result, [PebbleCandidateBufferedWorldEffect]) {
    let originalHooks = world.hooks
    var buffered: [PebbleCandidateBufferedWorldEffect] = []
    var transactionalHooks = originalHooks
    transactionalHooks.playSound = { name, x, y, z, volume, pitch in
        buffered.append(.sound(name, x, y, z, volume, pitch))
    }
    transactionalHooks.addParticles = { name, x, y, z, count, spread, data in
        buffered.append(.particles(name, x, y, z, count, spread, data))
    }
    transactionalHooks.onVibration = { x, y, z, radius, source in
        buffered.append(.vibration(x, y, z, radius, source))
    }
    world.hooks = transactionalHooks
    defer { world.hooks = originalHooks }
    return (try operation(), buffered)
}

func publishCandidateWorldEffects(
    _ effects: [PebbleCandidateBufferedWorldEffect],
    world: World
) {
    for effect in effects {
        switch effect {
        case let .sound(name, x, y, z, volume, pitch):
            world.hooks.playSound(name, x, y, z, volume, pitch)
        case let .particles(name, x, y, z, count, spread, data):
            world.hooks.addParticles(name, x, y, z, count, spread, data)
        case let .vibration(x, y, z, radius, source):
            world.hooks.onVibration?(x, y, z, radius, source)
        }
    }
}

enum PebbleCandidatePhysicalTransactionError: Error, CustomStringConvertible {
    case nestedCandidate(String)
    case noOpenCandidate(String)
    case compensationCapacity(Int)
    case duplicateCompensation(String)
    case invalidReservation(String)
    case injectedRegistrationFailure(String)
    case compensationFailed(String, String)

    var description: String {
        switch self {
        case let .nestedCandidate(operation):
            return "nested physical candidate refused: \(operation)"
        case let .noOpenCandidate(mutation):
            return "physical compensation has no open candidate: \(mutation)"
        case let .compensationCapacity(maximum):
            return "physical compensation capacity reached: \(maximum)"
        case let .duplicateCompensation(id):
            return "duplicate physical compensation: \(id)"
        case let .invalidReservation(id):
            return "invalid physical compensation reservation: \(id)"
        case let .injectedRegistrationFailure(id):
            return "injected physical compensation registration failure: \(id)"
        case let .compensationFailed(id, reason):
            return "physical compensation failed: \(id): \(reason)"
        }
    }
}

struct PebbleCandidatePhysicalCompensationReservation: Equatable {
    let transactionID: String
    let ordinal: Int
    let compensationID: String
}

final class PebbleCandidatePhysicalCompensation {
    let reservation: PebbleCandidatePhysicalCompensationReservation
    let mutation: String
    let agentID: String?
    let probeID: String?
    let expectedBefore: String
    private let observedState: () -> String
    private let compensateImpl: () throws -> Bool
    private let commitImpl: () -> Void
    private(set) var consumed = false

    init(
        reservation: PebbleCandidatePhysicalCompensationReservation,
        mutation: String,
        agentID: String? = nil,
        probeID: String? = nil,
        expectedBefore: String,
        observedState: @escaping () -> String,
        compensate: @escaping () throws -> Bool,
        commit: @escaping () -> Void = {}
    ) {
        self.reservation = reservation
        self.mutation = mutation
        self.agentID = agentID
        self.probeID = probeID
        self.expectedBefore = expectedBefore
        self.observedState = observedState
        compensateImpl = compensate
        commitImpl = commit
    }

    var observed: String { observedState() }

    func compensate() throws {
        guard !consumed else {
            throw PebbleCandidatePhysicalTransactionError.duplicateCompensation(
                reservation.compensationID
            )
        }
        consumed = true
        guard try compensateImpl() else {
            throw PebbleCandidatePhysicalTransactionError.compensationFailed(
                reservation.compensationID,
                "expected=\(expectedBefore) observed=\(observedState())"
            )
        }
    }

    func commit() {
        guard !consumed else { return }
        consumed = true
        commitImpl()
    }
}

struct PebbleCandidatePhysicalRollbackReport {
    let transactionID: String
    let completed: [String]
    let remaining: [String]
    let failedCompensationID: String?
    let failure: String?
    let failedMutation: String?
    let expectedPhysicalState: String?
    let observedPhysicalState: String?
    let agentID: String?
    let probeID: String?
}

/// One bounded journal per controller candidate publication boundary.
///
/// Reservations are ordered before mutation. A locally failed adapter restores
/// itself and never registers its reservation. A locally verified adapter
/// registers exactly one one-shot token. Global rollback consumes registered
/// tokens in reverse mutation order.
final class PebbleCandidatePhysicalTransaction {
    static let maximumCompensations = 128

    let transactionID: String
    let operation: String
    let physicalWorldTick: Int
    let injectedCompensationFailurePrefix: String?
    let injectedRegistrationFailurePrefix: String?
    private var nextOrdinal = 0
    private var compensations: [Int: PebbleCandidatePhysicalCompensation] = [:]
    private var compensationIDs = Set<String>()
    private(set) var registrationFailureIDs: [String] = []
    private(set) var locallyCompensatedRegistrationIDs: [String] = []
    private(set) var locallyCompensatedRegistrationDiagnostics: [String] = []
    private(set) var committed = false
    private(set) var rolledBack = false

    init(
        transactionID: String,
        operation: String,
        physicalWorldTick: Int,
        injectedCompensationFailurePrefix: String? = nil,
        injectedRegistrationFailurePrefix: String? = nil
    ) {
        self.transactionID = transactionID
        self.operation = operation
        self.physicalWorldTick = physicalWorldTick
        self.injectedCompensationFailurePrefix =
            injectedCompensationFailurePrefix
        self.injectedRegistrationFailurePrefix =
            injectedRegistrationFailurePrefix
    }

    func reserve(
        compensationID: String
    ) throws -> PebbleCandidatePhysicalCompensationReservation {
        guard !committed, !rolledBack else {
            throw PebbleCandidatePhysicalTransactionError.noOpenCandidate(
                compensationID
            )
        }
        guard nextOrdinal < Self.maximumCompensations else {
            throw PebbleCandidatePhysicalTransactionError.compensationCapacity(
                Self.maximumCompensations
            )
        }
        guard !compensationIDs.contains(compensationID) else {
            throw PebbleCandidatePhysicalTransactionError.duplicateCompensation(
                compensationID
            )
        }
        nextOrdinal += 1
        compensationIDs.insert(compensationID)
        return PebbleCandidatePhysicalCompensationReservation(
            transactionID: transactionID,
            ordinal: nextOrdinal,
            compensationID: compensationID
        )
    }

    func reserve(
        compensationPrefix: String
    ) throws -> PebbleCandidatePhysicalCompensationReservation {
        try reserve(compensationID: "\(compensationPrefix):\(nextOrdinal + 1)")
    }

    func register(_ compensation: PebbleCandidatePhysicalCompensation) throws {
        let reservation = compensation.reservation
        guard !committed, !rolledBack else {
            throw PebbleCandidatePhysicalTransactionError.noOpenCandidate(
                reservation.compensationID
            )
        }
        if let injectedRegistrationFailurePrefix,
           reservation.compensationID.hasPrefix(
               injectedRegistrationFailurePrefix
           ) {
            throw PebbleCandidatePhysicalTransactionError
                .injectedRegistrationFailure(reservation.compensationID)
        }
        guard reservation.transactionID == transactionID,
              compensationIDs.contains(reservation.compensationID),
              compensations[reservation.ordinal] == nil else {
            throw PebbleCandidatePhysicalTransactionError.invalidReservation(
                reservation.compensationID
            )
        }
        compensations[reservation.ordinal] = compensation
    }

    /// Transfers a locally verified mutation to the candidate journal.
    ///
    /// If registration is refused, compensations registered after this
    /// reservation are necessarily nested child mutations from the same
    /// synchronous adapter call. They are consumed first in reverse order,
    /// followed by the offered parent compensation. Exact local restoration
    /// leaves neither token registered. A non-verifiable restoration retains a
    /// consumed diagnostic token so the enclosing candidate rollback must hard
    /// fail instead of treating the reservation gap as clean.
    func registerOrCompensate(
        _ compensation: PebbleCandidatePhysicalCompensation
    ) throws {
        do {
            try register(compensation)
            return
        } catch let registrationError {
            let reservation = compensation.reservation
            registrationFailureIDs.append(reservation.compensationID)
            let ownsReservation = reservation.transactionID == transactionID
                && compensationIDs.contains(reservation.compensationID)
            if ownsReservation, !committed, !rolledBack {
                let childOrdinals = compensations.keys.filter {
                    $0 > reservation.ordinal
                }.sorted(by: >)
                for childOrdinal in childOrdinals {
                    guard let child = compensations[childOrdinal] else {
                        continue
                    }
                    do {
                        try compensateAfterRegistrationFailure(child)
                        locallyCompensatedRegistrationIDs.append(
                            child.reservation.compensationID
                        )
                        locallyCompensatedRegistrationDiagnostics.append(
                            localCompensationDiagnostic(child)
                        )
                        compensations.removeValue(forKey: childOrdinal)
                    } catch {
                        if compensations[reservation.ordinal] == nil {
                            compensations[reservation.ordinal] = compensation
                        }
                        throw PebbleCandidatePhysicalTransactionError
                            .compensationFailed(
                                child.reservation.compensationID,
                                "registration=\(registrationError) local=\(error)"
                            )
                    }
                }
            }
            do {
                try compensateAfterRegistrationFailure(compensation)
                locallyCompensatedRegistrationIDs.append(
                    reservation.compensationID
                )
                locallyCompensatedRegistrationDiagnostics.append(
                    localCompensationDiagnostic(compensation)
                )
            } catch {
                if ownsReservation, !committed, !rolledBack,
                   compensations[reservation.ordinal] == nil {
                    compensations[reservation.ordinal] = compensation
                }
                throw PebbleCandidatePhysicalTransactionError
                    .compensationFailed(
                        reservation.compensationID,
                        "registration=\(registrationError) local=\(error)"
                    )
            }
            throw registrationError
        }
    }

    private func compensateAfterRegistrationFailure(
        _ compensation: PebbleCandidatePhysicalCompensation
    ) throws {
        if let injectedCompensationFailurePrefix,
           compensation.reservation.compensationID.hasPrefix(
               injectedCompensationFailurePrefix
           ) {
            throw PebbleCandidatePhysicalTransactionError.compensationFailed(
                compensation.reservation.compensationID,
                "injected registration-seam collision/non-verifiable restore"
            )
        }
        try compensation.compensate()
    }

    private func localCompensationDiagnostic(
        _ compensation: PebbleCandidatePhysicalCompensation
    ) -> String {
        "\(compensation.reservation.compensationID):expected={"
            + "\(compensation.expectedBefore)}:observed={\(compensation.observed)}"
    }

    var registeredCompensationIDs: [String] {
        compensations.keys.sorted().compactMap {
            compensations[$0]?.reservation.compensationID
        }
    }

    var reservedCompensationIDs: [String] {
        compensationIDs.sorted()
    }

    var registeredBoundaryDiagnostics: [String] {
        compensations.keys.sorted().compactMap { ordinal in
            guard let compensation = compensations[ordinal] else { return nil }
            return "\(compensation.reservation.compensationID):before={"
                + "\(compensation.expectedBefore)}:after={\(compensation.observed)}"
        }
    }

    func commit() {
        guard !committed, !rolledBack else { return }
        for ordinal in compensations.keys.sorted() {
            compensations[ordinal]?.commit()
        }
        committed = true
        compensations.removeAll(keepingCapacity: false)
    }

    func rollback() -> PebbleCandidatePhysicalRollbackReport {
        guard !committed, !rolledBack else {
            return PebbleCandidatePhysicalRollbackReport(
                transactionID: transactionID,
                completed: [], remaining: registeredCompensationIDs,
                failedCompensationID: nil,
                failure: "candidate transaction is no longer open",
                failedMutation: nil,
                expectedPhysicalState: nil,
                observedPhysicalState: nil,
                agentID: nil,
                probeID: nil
            )
        }
        let ordered = compensations.keys.sorted(by: >)
        var completed: [String] = []
        for (index, ordinal) in ordered.enumerated() {
            guard let compensation = compensations[ordinal] else { continue }
            if let injectedCompensationFailurePrefix,
               compensation.reservation.compensationID.hasPrefix(
                   injectedCompensationFailurePrefix
               ) {
                let remaining = ordered.dropFirst(index + 1).compactMap {
                    compensations[$0]?.reservation.compensationID
                }
                return PebbleCandidatePhysicalRollbackReport(
                    transactionID: transactionID,
                    completed: completed,
                    remaining: remaining,
                    failedCompensationID:
                        compensation.reservation.compensationID,
                    failure: "injected compensation collision/non-verifiable restore",
                    failedMutation: compensation.mutation,
                    expectedPhysicalState: compensation.expectedBefore,
                    observedPhysicalState: compensation.observed,
                    agentID: compensation.agentID,
                    probeID: compensation.probeID
                )
            }
            do {
                try compensation.compensate()
                completed.append(compensation.reservation.compensationID)
            } catch {
                let remaining = ordered.dropFirst(index + 1).compactMap {
                    compensations[$0]?.reservation.compensationID
                }
                return PebbleCandidatePhysicalRollbackReport(
                    transactionID: transactionID,
                    completed: completed,
                    remaining: remaining,
                    failedCompensationID: compensation.reservation.compensationID,
                    failure: String(describing: error),
                    failedMutation: compensation.mutation,
                    expectedPhysicalState: compensation.expectedBefore,
                    observedPhysicalState: compensation.observed,
                    agentID: compensation.agentID,
                    probeID: compensation.probeID
                )
            }
        }
        rolledBack = true
        compensations.removeAll(keepingCapacity: false)
        return PebbleCandidatePhysicalRollbackReport(
            transactionID: transactionID,
            completed: completed,
            remaining: [],
            failedCompensationID: nil,
            failure: nil,
            failedMutation: nil,
            expectedPhysicalState: nil,
            observedPhysicalState: nil,
            agentID: nil,
            probeID: nil
        )
    }
}

struct PebbleCandidatePhysicalHardFailure: CustomStringConvertible {
    let operation: String
    let transactionID: String
    let mutation: String
    let expectedPhysicalState: String
    let observedPhysicalState: String
    let compensationAttempt: String
    let compensationError: String
    let completedCompensations: [String]
    let remainingCompensations: [String]
    let publishedSessionStatus: String
    let physicalWorldTick: Int
    let candidateReceiptIDs: [String]
    let worldID: String
    let sessionID: String
    let checkpointID: String?
    let agentID: String?
    let probeID: String?

    var description: String {
        "operation=\(operation) transaction=\(transactionID) mutation=\(mutation) "
            + "expected={\(expectedPhysicalState)} observed={\(observedPhysicalState)} "
            + "attempt=\(compensationAttempt) error=\(compensationError) "
            + "completed=\(completedCompensations.joined(separator: ",")) "
            + "remaining=\(remainingCompensations.joined(separator: ",")) "
            + "publishedSession=\(publishedSessionStatus) worldTick=\(physicalWorldTick) "
            + "candidateReceipts=\(candidateReceiptIDs.joined(separator: ",")) "
            + "world=\(worldID) session=\(sessionID) "
            + "checkpoint=\(checkpointID ?? "none") agent=\(agentID ?? "none") "
            + "probe=\(probeID ?? "none")"
    }
}

extension PebbleAgentController {
    func makeCandidatePhysicalHardFailure(
        transaction: PebbleCandidatePhysicalTransaction,
        rollback: PebbleCandidatePhysicalRollbackReport,
        receiptFailure: String?,
        receiptIDs: [String],
        session: AgentSimulationSession,
        world: World
    ) -> PebbleCandidatePhysicalHardFailure {
        let compensationError = [
            receiptFailure.map { "receipt=\($0)" },
            rollback.failure.map { "physical=\($0)" },
        ].compactMap { $0 }.joined(separator: "; ")
        return PebbleCandidatePhysicalHardFailure(
            operation: transaction.operation,
            transactionID: transaction.transactionID,
            mutation: rollback.failedMutation
                ?? "candidate World receipt mutation",
            expectedPhysicalState: rollback.expectedPhysicalState
                ?? "all candidate receipts absent",
            observedPhysicalState: rollback.observedPhysicalState
                ?? "candidate receipts=\(receiptIDs.joined(separator: ","))",
            compensationAttempt: rollback.failedCompensationID
                ?? "World receipt rollback",
            compensationError: compensationError,
            completedCompensations: rollback.completed,
            remainingCompensations: rollback.remaining,
            publishedSessionStatus: "unchanged",
            physicalWorldTick: world.time,
            candidateReceiptIDs: receiptIDs,
            worldID: persistenceWorldID ?? "unknown",
            sessionID: session.simulationID.rawValue,
            checkpointID: nil,
            agentID: rollback.agentID,
            probeID: rollback.probeID
        )
    }
}
