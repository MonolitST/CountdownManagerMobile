import CoreTransferable
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct ImportedPlanFile: Transferable, Sendable {
    let id: UUID
    let url: URL
    private let contentType: String
    private let byteCount: Int64

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .image) { received in
            try copyToTemporaryStorage(received.file)
        }
    }

    static func fromFiles(_ url: URL) throws -> Self {
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess { url.stopAccessingSecurityScopedResource() }
        }
        var coordinationError: NSError?
        var result: Result<Self, Error>?
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { readableURL in
            result = Result { try copyToTemporaryStorage(readableURL) }
        }
        if let coordinationError { throw coordinationError }
        guard let result else { throw PlannerStorageError.missingAttachmentFile }
        return try result.get()
    }

    func attachment(for checklistItemID: UUID?) -> PlanAttachment {
        PlanAttachment(id: id, checklistItemID: checklistItemID, name: url.lastPathComponent,
                       contents: .file(contentType: contentType, byteCount: byteCount))
    }

    static func discard(_ url: URL) {
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    private static func copyToTemporaryStorage(_ source: URL) throws -> Self {
        let values = try source.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey, .contentTypeKey])
        guard values.isRegularFile == true, values.isSymbolicLink != true, let size = values.fileSize, size > 0 else {
            throw PlannerStorageError.invalidAttachment
        }

        let name = source.lastPathComponent
        guard PlanAttachment.isValidFilename(name) else { throw PlannerStorageError.invalidAttachment }
        let type: UTType
        let filename: String
        if values.contentType == .pdf || UTType(filenameExtension: source.pathExtension) == .pdf {
            guard CGPDFDocument(source as CFURL) != nil else { throw PlannerStorageError.invalidAttachment }
            type = .pdf
            filename = source.pathExtension.lowercased() == "pdf" ? name : name + ".pdf"
        } else {
            guard let image = CGImageSourceCreateWithURL(source as CFURL, nil),
                  let identifier = CGImageSourceGetType(image) as String?, let imageType = UTType(identifier),
                  imageType.conforms(to: .image), CGImageSourceGetCount(image) > 0 else {
                throw PlannerStorageError.invalidAttachment
            }
            type = imageType
            if UTType(filenameExtension: source.pathExtension) == imageType {
                filename = name
            } else if let ext = imageType.preferredFilenameExtension {
                filename = source.deletingPathExtension().lastPathComponent + "." + ext
            } else {
                filename = name
            }
        }

        let id = UUID()
        let folder = URL.temporaryDirectory.appending(path: "PlanAttachmentImports", directoryHint: .isDirectory)
            .appending(component: id.uuidString, directoryHint: .isDirectory)
        let destination = folder.appending(component: filename, directoryHint: .notDirectory)
        let manager = FileManager.default
        do {
            try manager.createDirectory(at: folder, withIntermediateDirectories: true)
            try manager.copyItem(at: source, to: destination)
        } catch {
            try? manager.removeItem(at: folder)
            throw error
        }
        return Self(id: id, url: destination, contentType: type.identifier, byteCount: Int64(size))
    }
}
