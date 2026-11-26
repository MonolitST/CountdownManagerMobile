import Foundation
import GRDB

struct SQLitePlannerRepository: PlannerRepository {
    private let database: DatabaseQueue
    private let attachmentFiles: PlanAttachmentFileStore

    static func local() throws -> Self {
        let legacy = URL.applicationSupportDirectory.appending(path: "CountdownManagerMobile")
        guard let shared = PlannerSharedLocation.sharedDirectory else { return try Self(directory: legacy) }
        try PlannerSharedLocation.prepare(legacy: legacy, shared: shared)
        return try Self(directory: shared)
    }

    init(directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var configuration = Configuration()
        configuration.journalMode = .wal
        configuration.busyMode = .timeout(3)
        database = try DatabaseQueue(
            path: directory.appending(path: PlannerSharedLocation.databaseFilename).path(percentEncoded: false),
            configuration: configuration
        )
        attachmentFiles = PlanAttachmentFileStore(
            directory: directory.appending(path: PlannerSharedLocation.attachmentsDirectoryName, directoryHint: .isDirectory)
        )
        try PlannerDatabaseMigration.migrator.migrate(database)
        try database.write { db in
            let ids = try UUID.fetchAll(db, sql: "SELECT id FROM plan_attachments WHERE contentType IS NOT NULL")
            attachmentFiles.removeOrphans(keeping: Set(ids))
        }
    }

    func load() throws -> PlannerData {
        try database.read(Self.read)
    }

    private static func read(_ db: Database) throws -> PlannerData {
        guard let settings = try SettingsRecord.fetchOne(db, key: 1) else {
            throw PlannerStorageError.missingSettings
        }
        let items = try ChecklistItemRecord.order(Column("position"), Column("itemID")).fetchAll(db)
        let checklists = Dictionary(grouping: items, by: \.planID)
        let attachments = try PlanAttachmentRecord.order(Column("position"), Column("id")).fetchAll(db)
        let planAttachments = Dictionary(grouping: attachments, by: \.planID)
        let plans = try PlanRecord.order(Column("position"), Column("id")).fetchAll(db).map { record in
            try record.plan(checklist: checklists[record.id, default: []].map(\.item),
                            attachments: planAttachments[record.id, default: []].map { try $0.attachment() })
        }
        let reminders = try ReminderRecord.order(Column("position"), Column("id")).fetchAll(db).map { record in
            try record.reminder()
        }
        let focus = try FocusSessionRecord.fetchOne(db, key: 1)?.session
        return try PlannerData(plans: plans, reminders: reminders, settings: settings.settings(), focus: focus)
    }

    func fileURL(for attachment: PlanAttachment) -> URL? {
        attachmentFiles.fileURL(for: attachment)
    }

    func save(_ updated: PlannerData, replacing previous: PlannerData, importing files: [UUID: URL]) throws {
        try write(installing: updated.attachmentsAdded(since: previous), from: files) { db in
            try Self.writeChanges(updated, replacing: previous, in: db)
        }
        attachmentFiles.remove(ids: previous.attachmentsAdded(since: updated).filter(\.isFile).map(\.id))
    }

    func addSharedAttachments(_ attachments: [PlanAttachment], to planID: UUID, importing files: [UUID: URL]) throws {
        guard !attachments.isEmpty else { throw PlannerStorageError.invalidAttachment }
        try write(installing: attachments, from: files) { db in
            guard try PlanRecord.exists(db, key: planID) else { throw PlannerStorageError.missingPlan }
            let start = try Int.fetchOne(
                db, sql: "SELECT IFNULL(MAX(position) + 1, 0) FROM plan_attachments WHERE planID = ?", arguments: [planID]
            ) ?? 0
            for (index, attachment) in attachments.enumerated() {
                try PlanAttachmentRecord(attachment, planID: planID, position: start + index).insert(db)
            }
            try db.execute(sql: """
                INSERT INTO shared_attachment_destination (id, planID) VALUES (1, ?)
                ON CONFLICT(id) DO UPDATE SET planID = excluded.planID
                """, arguments: [planID])
        }
    }

    func consumeSharedUpdate() throws -> (planID: UUID, data: PlannerData)? {
        try database.write { db in
            guard let destination = try UUID.fetchOne(
                db, sql: "SELECT planID FROM shared_attachment_destination WHERE id = 1"
            ) else { return nil }
            let data = try Self.read(db)
            try db.execute(sql: "DELETE FROM shared_attachment_destination WHERE id = 1")
            return (destination, data)
        }
    }

    private func write(installing attachments: [PlanAttachment], from files: [UUID: URL],
                       changes: (Database) throws -> Void) throws {
        var installed: [UUID] = []
        do {
            try database.write { db in
                try changes(db)
                installed = try attachmentFiles.install(attachments, from: files)
            }
        } catch {
            attachmentFiles.remove(ids: installed)
            throw error
        }
    }

    private static func writeChanges(_ updated: PlannerData, replacing previous: PlannerData, in db: Database) throws {
        try Self.saveChanges(
            updated.plans.enumerated().map { PlanRecord($0.element, position: $0.offset) },
            replacing: previous.plans.enumerated().map { PlanRecord($0.element, position: $0.offset) },
            in: db
        )
        try Self.saveChanges(
            ChecklistItemRecord.orderedRecords(for: updated.plans),
            replacing: ChecklistItemRecord.orderedRecords(for: previous.plans),
            in: db
        )
        try Self.saveChanges(attachmentRecords(in: updated), replacing: attachmentRecords(in: previous), in: db)
        try Self.saveChanges(
            updated.reminders.enumerated().map { ReminderRecord($0.element, position: $0.offset) },
            replacing: previous.reminders.enumerated().map { ReminderRecord($0.element, position: $0.offset) },
            in: db
        )
        if updated.settings != previous.settings {
            try SettingsRecord(updated.settings).update(db)
        }
        if updated.focus != previous.focus {
            if let focus = updated.focus {
                try FocusSessionRecord(focus).upsert(db)
            } else {
                _ = try FocusSessionRecord.deleteOne(db, key: 1)
            }
        }
    }

    private static func attachmentRecords(in data: PlannerData) -> [PlanAttachmentRecord] {
        data.plans.flatMap { plan in
            plan.attachments.enumerated().map { position, attachment in
                PlanAttachmentRecord(attachment, planID: plan.id, position: position)
            }
        }
    }

    private static func saveChanges<Record: PersistableRecord & Identifiable & Equatable>(
        _ records: [Record], replacing previous: [Record], in db: Database
    ) throws {
        let ids = Set(records.map(\.id))
        guard ids.count == records.count else { throw PlannerStorageError.duplicateIdentifiers }
        let previousByID = Dictionary(previous.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for record in previous where !ids.contains(record.id) {
            _ = try record.delete(db)
        }
        for record in records where record != previousByID[record.id] {
            try record.upsert(db)
        }
    }
}

enum PlannerStorageError: Error {
    case missingSettings
    case invalidSettings
    case duplicateIdentifiers
    case invalidAdvanceNotice
    case invalidReminderRule
    case invalidAttachment
    case missingAttachmentFile
    case sharedPlannerUnavailable
    case missingPlan
}
