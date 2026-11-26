import Foundation
import UniformTypeIdentifiers

enum PlanSharedItem: Sendable {
    case file(ImportedPlanFile)
    case link(URL)

    @MainActor
    static func load(from provider: NSItemProvider) async throws -> Self? {
        let fileType = provider.registeredTypeIdentifiers.first { identifier in
            guard let type = UTType(identifier) else { return false }
            return type.conforms(to: .image) || type.conforms(to: .pdf)
        }
        if let fileType {
            return try await withCheckedThrowingContinuation { continuation in
                provider.loadFileRepresentation(forTypeIdentifier: fileType) { url, error in
                    continuation.resume(with: Result {
                        if let error { throw error }
                        guard let url else { throw PlannerStorageError.missingAttachmentFile }
                        return .file(try ImportedPlanFile.fromFiles(url))
                    })
                }
            }
        }

        let type = provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) ? UTType.fileURL : .url
        guard provider.hasItemConformingToTypeIdentifier(type.identifier) else { return nil }
        return try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: type.identifier, options: nil) { item, error in
                continuation.resume(with: Result {
                    if let error { throw error }
                    if let url = item as? URL {
                        if url.isFileURL { return .file(try ImportedPlanFile.fromFiles(url)) }
                        if let webURL = PlanAttachment.webURL(from: url.absoluteString) { return .link(webURL) }
                    }
                    if let text = item as? String, let webURL = PlanAttachment.webURL(from: text) {
                        return .link(webURL)
                    }
                    throw PlannerStorageError.invalidAttachment
                })
            }
        }
    }

    var attachment: PlanAttachment {
        switch self {
        case let .file(file):
            return file.attachment(for: nil)
        case let .link(url):
            return PlanAttachment(id: UUID(), checklistItemID: nil,
                                  name: url.host(percentEncoded: false) ?? url.absoluteString, contents: .link(url))
        }
    }

    var importedFile: ImportedPlanFile? {
        if case let .file(file) = self { return file }
        return nil
    }
}
