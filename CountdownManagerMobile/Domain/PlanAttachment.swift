import Foundation
import UniformTypeIdentifiers

struct PlanAttachment: Codable, Equatable, Identifiable, Sendable {
    enum Contents: Codable, Equatable, Sendable {
        case file(contentType: String, byteCount: Int64)
        case link(URL)
    }

    let id: UUID
    let checklistItemID: UUID?
    let name: String
    let contents: Contents

    var isFile: Bool {
        if case .file = contents { return true }
        return false
    }

    var isPhoto: Bool {
        guard case let .file(contentType, _) = contents else { return false }
        return UTType(contentType)?.conforms(to: .image) == true
    }

    static func isValidFilename(_ name: String) -> Bool {
        !name.isEmpty && name != "." && name != ".." && !name.contains("/") && !name.contains("\\")
    }

    static func webURL(from text: String) -> URL? {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        let input = text.contains("://") ? text : "https://\(text)"
        guard let url = URL(string: input), let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http", let host = url.host(), !host.isEmpty,
              url.user == nil, url.password == nil else { return nil }
        return url
    }
}
