import Foundation
import GRDB

enum PlannerSharedLocation {
    static let databaseFilename = "planner.sqlite"
    static let attachmentsDirectoryName = "Attachments"

    static var sharedDirectory: URL? {
        guard let group = Bundle.main.object(forInfoDictionaryKey: "CountdownAppGroup") as? String else { return nil }
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)?
            .appending(path: "Planner", directoryHint: .isDirectory)
    }

    static func prepare(legacy: URL, shared: URL) throws {
        let manager = FileManager.default
        let targetDatabase = shared.appending(path: databaseFilename)
        guard !manager.fileExists(atPath: targetDatabase.path(percentEncoded: false)) else { return }

        let staging = shared.deletingLastPathComponent()
            .appending(component: "PlannerMigration-\(UUID().uuidString)", directoryHint: .isDirectory)
        try manager.createDirectory(at: staging, withIntermediateDirectories: true)
        defer { try? manager.removeItem(at: staging) }

        let sourceDatabase = legacy.appending(path: databaseFilename)
        if manager.fileExists(atPath: sourceDatabase.path(percentEncoded: false)) {
            var configuration = Configuration()
            configuration.readonly = true
            let source = try DatabaseQueue(path: sourceDatabase.path(percentEncoded: false), configuration: configuration)
            let destination = try DatabaseQueue(path: staging.appending(path: databaseFilename).path(percentEncoded: false))
            try source.backup(to: destination)
            let files = legacy.appending(path: attachmentsDirectoryName)
            if manager.fileExists(atPath: files.path(percentEncoded: false)) {
                try manager.copyItem(at: files, to: staging.appending(path: attachmentsDirectoryName))
            }
        } else {
            _ = try SQLitePlannerRepository(directory: staging)
        }
        try manager.moveItem(at: staging, to: shared)
    }

    static func openForSharing() throws -> SQLitePlannerRepository {
        guard let sharedDirectory,
              FileManager.default.fileExists(
                atPath: sharedDirectory.appending(path: databaseFilename).path(percentEncoded: false)
              ) else { throw PlannerStorageError.sharedPlannerUnavailable }
        return try SQLitePlannerRepository(directory: sharedDirectory)
    }
}
