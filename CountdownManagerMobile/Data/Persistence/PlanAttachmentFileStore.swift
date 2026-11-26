import Foundation

struct PlanAttachmentFileStore {
    let directory: URL

    func fileURL(for attachment: PlanAttachment) -> URL? {
        guard attachment.isFile, PlanAttachment.isValidFilename(attachment.name) else { return nil }
        return folder(for: attachment.id).appending(component: attachment.name, directoryHint: .notDirectory)
    }

    func install(_ attachments: [PlanAttachment], from imports: [UUID: URL]) throws -> [UUID] {
        let manager = FileManager.default
        var installed: [UUID] = []
        do {
            for attachment in attachments where attachment.isFile {
                guard let destination = fileURL(for: attachment), let source = imports[attachment.id] else {
                    throw PlannerStorageError.missingAttachmentFile
                }
                let folder = folder(for: attachment.id)
                try manager.createDirectory(at: directory, withIntermediateDirectories: true)
                guard !manager.fileExists(atPath: folder.path(percentEncoded: false)) else {
                    throw PlannerStorageError.duplicateIdentifiers
                }
                try manager.createDirectory(at: folder, withIntermediateDirectories: false)
                installed.append(attachment.id)
                try manager.copyItem(at: source, to: destination)
            }
        } catch {
            remove(ids: installed)
            throw error
        }
        return installed
    }

    func remove(ids: [UUID]) {
        for id in ids { try? FileManager.default.removeItem(at: folder(for: id)) }
    }

    func removeOrphans(keeping ids: Set<UUID>) {
        guard let entries = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
            return
        }
        for entry in entries {
            guard let id = UUID(uuidString: entry.lastPathComponent), entry.lastPathComponent == id.uuidString,
                  !ids.contains(id) else { continue }
            try? FileManager.default.removeItem(at: entry)
        }
    }

    private func folder(for id: UUID) -> URL {
        directory.appending(component: id.uuidString, directoryHint: .isDirectory)
    }
}
