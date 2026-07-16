import Foundation
import PebbleAgents

struct PebbleAgentStoredCheckpoint {
    let manifest: AgentCheckpointManifest
    let checkpoint: AgentSessionCheckpoint
}

struct PebbleAgentStoredReplay {
    let manifest: AgentReplayJournalManifest
    let journal: AgentReplayJournal
}

enum PebbleAgentPersistenceStoreError: Error, CustomStringConvertible {
    case invalidManagedRoot
    case missingBundle(String)
    case existingBundle(String)
    case checkpointLimitReached
    case invalidBundle(String)
    case symbolicLink(String)
    case storageDigestMismatch
    case sizeLimit(Int)

    var description: String {
        switch self {
        case .invalidManagedRoot: return "invalid managed persistence root"
        case let .missingBundle(name): return "persistence bundle not found: \(name)"
        case let .existingBundle(name): return "persistence bundle already exists: \(name)"
        case .checkpointLimitReached: return "checkpoint limit reached"
        case let .invalidBundle(reason): return "invalid persistence bundle: \(reason)"
        case let .symbolicLink(path): return "symbolic link refused in persistence bundle: \(path)"
        case .storageDigestMismatch: return "persistence storage digest mismatch"
        case let .sizeLimit(bytes): return "persistence size limit exceeded: \(bytes) bytes"
        }
    }
}

struct PebbleAgentPersistenceStore {
    let managedRoot: URL
    let worldID: String

    init(worldID: String, fileManager: FileManager = .default) throws {
        guard !worldID.isEmpty else { throw PebbleAgentPersistenceStoreError.invalidManagedRoot }
        let applicationSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        managedRoot = applicationSupport
            .appendingPathComponent("Pebble", isDirectory: true)
            .appendingPathComponent("PebbleLabAgents", isDirectory: true)
        self.worldID = worldID
    }

    var storageIdentity: String {
        "sqlite-world:\(worldID)"
    }

    var worldRoot: URL {
        let component = AgentCheckpointDigest.sha256(Data(worldID.utf8)).rawValue
        return managedRoot.appendingPathComponent(component, isDirectory: true)
    }

    func checkpointNames(fileManager: FileManager = .default) throws -> [AgentCheckpointName] {
        try names(in: checkpointRoot, fileManager: fileManager)
    }

    func replayNames(fileManager: FileManager = .default) throws -> [AgentCheckpointName] {
        try names(in: replayRoot, fileManager: fileManager)
    }

    func saveCheckpoint(
        name: AgentCheckpointName,
        checkpoint: AgentSessionCheckpoint,
        manifest: AgentCheckpointManifest,
        fileManager: FileManager = .default
    ) throws {
        guard manifest.name == name,
              manifest.checkpointID == checkpoint.checkpointID,
              manifest.semanticDigest == checkpoint.semanticDigest else {
            throw PebbleAgentPersistenceStoreError.invalidBundle("checkpoint manifest identity")
        }
        let sessionBytes = try AgentCheckpointCodec.encode(checkpoint)
        guard sessionBytes.count <= AgentCheckpointLimits.maximumCheckpointBytes else {
            throw PebbleAgentPersistenceStoreError.sizeLimit(sessionBytes.count)
        }
        guard sessionBytes.count == manifest.byteLength,
              AgentCheckpointDigest.sha256(sessionBytes) == manifest.storageDigest else {
            throw PebbleAgentPersistenceStoreError.storageDigestMismatch
        }
        try prepareRoots(fileManager: fileManager)
        let existing = try checkpointNames(fileManager: fileManager)
        guard !existing.contains(name) else {
            throw PebbleAgentPersistenceStoreError.existingBundle(name.rawValue)
        }
        guard existing.count < AgentCheckpointLimits.maximumCheckpointsPerWorld else {
            throw PebbleAgentPersistenceStoreError.checkpointLimitReached
        }
        try writeBundle(
            parent: checkpointRoot,
            name: name,
            files: [
                "manifest.json": try encodedLine(manifest),
                "session.json": sessionBytes,
            ],
            verify: { directory in
                let loaded = try loadCheckpoint(name: name, fileManager: fileManager, root: directory)
                guard loaded.checkpoint.semanticDigest == checkpoint.semanticDigest else {
                    throw PebbleAgentPersistenceStoreError.storageDigestMismatch
                }
            },
            fileManager: fileManager
        )
    }

    func loadCheckpoint(
        name: AgentCheckpointName,
        fileManager: FileManager = .default
    ) throws -> PebbleAgentStoredCheckpoint {
        try loadCheckpoint(
            name: name,
            fileManager: fileManager,
            root: checkpointRoot.appendingPathComponent(name.rawValue, isDirectory: true)
        )
    }

    func deleteCheckpoint(
        name: AgentCheckpointName,
        fileManager: FileManager = .default
    ) throws {
        let directory = checkpointRoot.appendingPathComponent(name.rawValue, isDirectory: true)
        guard fileManager.fileExists(atPath: directory.path) else {
            throw PebbleAgentPersistenceStoreError.missingBundle(name.rawValue)
        }
        try refuseSymbolicLink(directory, fileManager: fileManager)
        try fileManager.removeItem(at: directory)
    }

    func saveReplay(
        name: AgentCheckpointName,
        journal: AgentReplayJournal,
        fileManager: FileManager = .default
    ) throws {
        guard journal.manifest.name == name else {
            throw PebbleAgentPersistenceStoreError.invalidBundle("replay manifest name")
        }
        let operations = try AgentReplayCodec.encodeRecords(journal.records)
        guard operations.count <= AgentCheckpointLimits.maximumReplayBytes else {
            throw PebbleAgentPersistenceStoreError.sizeLimit(operations.count)
        }
        guard operations.count == journal.manifest.operationsByteLength,
              AgentCheckpointDigest.sha256(operations) == journal.manifest.operationsStorageDigest else {
            throw PebbleAgentPersistenceStoreError.storageDigestMismatch
        }
        try prepareRoots(fileManager: fileManager)
        guard !(try replayNames(fileManager: fileManager)).contains(name) else {
            throw PebbleAgentPersistenceStoreError.existingBundle(name.rawValue)
        }
        try writeBundle(
            parent: replayRoot,
            name: name,
            files: [
                "manifest.json": try encodedLine(journal.manifest),
                "operations.ndjson": operations,
            ],
            verify: { directory in
                let loaded = try loadReplay(name: name, fileManager: fileManager, root: directory)
                guard loaded.journal.records.count == journal.records.count else {
                    throw PebbleAgentPersistenceStoreError.invalidBundle("replay record count")
                }
            },
            fileManager: fileManager
        )
    }

    func loadReplay(
        name: AgentCheckpointName,
        fileManager: FileManager = .default
    ) throws -> PebbleAgentStoredReplay {
        try loadReplay(
            name: name,
            fileManager: fileManager,
            root: replayRoot.appendingPathComponent(name.rawValue, isDirectory: true)
        )
    }

    private var checkpointRoot: URL {
        worldRoot.appendingPathComponent("checkpoints", isDirectory: true)
    }

    private var replayRoot: URL {
        worldRoot.appendingPathComponent("replays", isDirectory: true)
    }

    private func prepareRoots(fileManager: FileManager) throws {
        try fileManager.createDirectory(at: checkpointRoot, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: replayRoot, withIntermediateDirectories: true)
        for directory in [managedRoot, worldRoot, checkpointRoot, replayRoot] {
            try refuseSymbolicLink(directory, fileManager: fileManager)
        }
    }

    private func names(
        in directory: URL,
        fileManager: FileManager
    ) throws -> [AgentCheckpointName] {
        guard fileManager.fileExists(atPath: directory.path) else { return [] }
        try refuseSymbolicLink(directory, fileManager: fileManager)
        return try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles]
        ).compactMap { url in
            let values = try url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            guard values.isSymbolicLink != true, values.isDirectory == true else { return nil }
            return AgentCheckpointName(rawValue: url.lastPathComponent)
        }.sorted()
    }

    private func loadCheckpoint(
        name: AgentCheckpointName,
        fileManager: FileManager,
        root: URL
    ) throws -> PebbleAgentStoredCheckpoint {
        try validateBundleDirectory(root, name: name, fileManager: fileManager)
        let manifestURL = root.appendingPathComponent("manifest.json")
        let sessionURL = root.appendingPathComponent("session.json")
        let manifestBytes = try readRegularFile(manifestURL, limit: 1_048_576, fileManager: fileManager)
        let manifest = try AgentCheckpointCodec.decode(AgentCheckpointManifest.self, from: manifestBytes)
        guard AgentCheckpointSchema.supports(manifest.schemaVersion),
              manifest.name == name,
              manifest.byteLength <= AgentCheckpointLimits.maximumCheckpointBytes else {
            throw PebbleAgentPersistenceStoreError.invalidBundle("checkpoint manifest")
        }
        let sessionBytes = try readRegularFile(
            sessionURL,
            limit: AgentCheckpointLimits.maximumCheckpointBytes,
            fileManager: fileManager
        )
        guard sessionBytes.count == manifest.byteLength,
              AgentCheckpointDigest.sha256(sessionBytes) == manifest.storageDigest else {
            throw PebbleAgentPersistenceStoreError.storageDigestMismatch
        }
        let checkpoint = try AgentCheckpointCodec.decode(AgentSessionCheckpoint.self, from: sessionBytes)
        _ = try AgentSimulationSession.validate(checkpoint)
        guard checkpoint.checkpointID == manifest.checkpointID,
              checkpoint.semanticDigest == manifest.semanticDigest else {
            throw PebbleAgentPersistenceStoreError.storageDigestMismatch
        }
        return PebbleAgentStoredCheckpoint(manifest: manifest, checkpoint: checkpoint)
    }

    private func loadReplay(
        name: AgentCheckpointName,
        fileManager: FileManager,
        root: URL
    ) throws -> PebbleAgentStoredReplay {
        try validateBundleDirectory(root, name: name, fileManager: fileManager)
        let manifestBytes = try readRegularFile(
            root.appendingPathComponent("manifest.json"),
            limit: 1_048_576,
            fileManager: fileManager
        )
        let manifest = try AgentCheckpointCodec.decode(AgentReplayJournalManifest.self, from: manifestBytes)
        guard AgentReplaySchema.supports(manifest.schemaVersion),
              manifest.name == name,
              manifest.recordCount <= AgentCheckpointLimits.maximumReplayRecords,
              manifest.operationsByteLength <= AgentCheckpointLimits.maximumReplayBytes else {
            throw PebbleAgentPersistenceStoreError.invalidBundle("replay manifest")
        }
        let operations = try readRegularFile(
            root.appendingPathComponent("operations.ndjson"),
            limit: AgentCheckpointLimits.maximumReplayBytes,
            fileManager: fileManager
        )
        guard operations.count == manifest.operationsByteLength,
              AgentCheckpointDigest.sha256(operations) == manifest.operationsStorageDigest else {
            throw PebbleAgentPersistenceStoreError.storageDigestMismatch
        }
        let records = try AgentReplayCodec.decodeRecords(operations)
        guard records.count == manifest.recordCount else {
            throw PebbleAgentPersistenceStoreError.invalidBundle("replay record count")
        }
        let journal = AgentReplayJournal(manifest: manifest, records: records)
        return PebbleAgentStoredReplay(manifest: manifest, journal: journal)
    }

    private func validateBundleDirectory(
        _ directory: URL,
        name: AgentCheckpointName,
        fileManager: FileManager
    ) throws {
        let allowedNames = [name.rawValue, ".\(name.rawValue).tmp"]
        let parent = directory.deletingLastPathComponent().standardizedFileURL.path
        guard allowedNames.contains(directory.lastPathComponent),
              (parent == checkpointRoot.standardizedFileURL.path
                || parent == replayRoot.standardizedFileURL.path) else {
            throw PebbleAgentPersistenceStoreError.invalidManagedRoot
        }
        guard fileManager.fileExists(atPath: directory.path) else {
            throw PebbleAgentPersistenceStoreError.missingBundle(name.rawValue)
        }
        try refuseSymbolicLink(directory, fileManager: fileManager)
    }

    private func writeBundle(
        parent: URL,
        name: AgentCheckpointName,
        files: [String: Data],
        verify: (URL) throws -> Void,
        fileManager: FileManager
    ) throws {
        let final = parent.appendingPathComponent(name.rawValue, isDirectory: true)
        let temporary = parent.appendingPathComponent(".\(name.rawValue).tmp", isDirectory: true)
        guard !fileManager.fileExists(atPath: final.path) else {
            throw PebbleAgentPersistenceStoreError.existingBundle(name.rawValue)
        }
        if fileManager.fileExists(atPath: temporary.path) {
            try refuseSymbolicLink(temporary, fileManager: fileManager)
            try fileManager.removeItem(at: temporary)
        }
        try fileManager.createDirectory(at: temporary, withIntermediateDirectories: false)
        do {
            for filename in files.keys.sorted() {
                try files[filename]!.write(
                    to: temporary.appendingPathComponent(filename),
                    options: [.atomic]
                )
            }
            try verify(temporary)
            try fileManager.moveItem(at: temporary, to: final)
        } catch {
            if fileManager.fileExists(atPath: temporary.path) {
                try? fileManager.removeItem(at: temporary)
            }
            throw error
        }
    }

    private func readRegularFile(
        _ url: URL,
        limit: Int,
        fileManager: FileManager
    ) throws -> Data {
        try refuseSymbolicLink(url, fileManager: fileManager)
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        guard attributes[.type] as? FileAttributeType == .typeRegular else {
            throw PebbleAgentPersistenceStoreError.invalidBundle("non-regular file \(url.lastPathComponent)")
        }
        let size = (attributes[.size] as? NSNumber)?.intValue ?? limit + 1
        guard size <= limit else { throw PebbleAgentPersistenceStoreError.sizeLimit(size) }
        let bytes = try Data(contentsOf: url, options: [.mappedIfSafe])
        guard bytes.count <= limit else { throw PebbleAgentPersistenceStoreError.sizeLimit(bytes.count) }
        return bytes
    }

    private func refuseSymbolicLink(_ url: URL, fileManager: FileManager) throws {
        let values = try url.resourceValues(forKeys: [.isSymbolicLinkKey])
        if values.isSymbolicLink == true {
            throw PebbleAgentPersistenceStoreError.symbolicLink(url.path)
        }
    }

    private func encodedLine<T: Encodable>(_ value: T) throws -> Data {
        try AgentCheckpointCodec.encode(value) + Data([0x0a])
    }
}
