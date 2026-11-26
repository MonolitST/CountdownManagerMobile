import Foundation
import Observation
import PhotosUI
import SwiftUI

enum PlanAttachmentTarget: Hashable, Identifiable {
    case plan
    case checklistItem(UUID)

    var id: Self { self }

    var checklistItemID: UUID? {
        if case let .checklistItem(id) = self { return id }
        return nil
    }
}

@MainActor
@Observable
final class PlanAttachmentEditorViewModel {
    private(set) var attachments: [PlanAttachment]
    private(set) var isImporting = false
    var errorMessage: String?

    @ObservationIgnored private(set) var imports: [UUID: URL] = [:]
    @ObservationIgnored private var importTask: Task<Void, Never>?

    init(attachments: [PlanAttachment]) {
        self.attachments = attachments
    }

    deinit {
        importTask?.cancel()
        imports.values.forEach(ImportedPlanFile.discard)
    }

    func addPhotos(_ photos: [PhotosPickerItem], to target: PlanAttachmentTarget) {
        importItems(photos, to: target) { photo in
            guard let file = try await photo.loadTransferable(type: ImportedPlanFile.self) else {
                throw PlannerStorageError.invalidAttachment
            }
            return file
        }
    }

    func addFiles(_ result: Result<[URL], Error>, to target: PlanAttachmentTarget) {
        switch result {
        case let .success(urls):
            importItems(urls, to: target) { url in
                try await Task.detached(priority: .userInitiated) {
                    try ImportedPlanFile.fromFiles(url)
                }.value
            }
        case .failure:
            reportImportFailure()
        }
    }

    func addLink(_ url: URL, title: String, to target: PlanAttachmentTarget) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        attachments.append(PlanAttachment(
            id: UUID(), checklistItemID: target.checklistItemID,
            name: trimmed.isEmpty ? url.host(percentEncoded: false) ?? url.absoluteString : trimmed,
            contents: .link(url)
        ))
    }

    func remove(_ attachment: PlanAttachment) {
        attachments.removeAll { $0.id == attachment.id }
        if let importURL = imports.removeValue(forKey: attachment.id) {
            ImportedPlanFile.discard(importURL)
        }
    }

    func removeAttachments(for checklistItemID: UUID) {
        for attachment in attachments where attachment.checklistItemID == checklistItemID {
            remove(attachment)
        }
    }

    private func importItems<Item: Sendable>(
        _ items: [Item], to target: PlanAttachmentTarget, load: @escaping @Sendable (Item) async throws -> ImportedPlanFile
    ) {
        guard !isImporting, !items.isEmpty else { return }
        isImporting = true
        importTask = Task { [weak self] in
            var failed = false
            for item in items {
                do {
                    try Task.checkCancellation()
                    let file = try await load(item)
                    guard let self, !Task.isCancelled else {
                        ImportedPlanFile.discard(file.url)
                        return
                    }
                    imports[file.id] = file.url
                    attachments.append(file.attachment(for: target.checklistItemID))
                } catch {
                    if Task.isCancelled { return }
                    failed = true
                }
            }
            self?.isImporting = false
            self?.importTask = nil
            if failed { self?.reportImportFailure() }
        }
    }

    private func reportImportFailure() {
        errorMessage = String(localized: "Couldn’t import one or more attachments.")
    }
}
