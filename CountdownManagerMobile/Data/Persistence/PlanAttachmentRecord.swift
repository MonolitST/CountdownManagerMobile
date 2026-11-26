import Foundation
import GRDB

struct PlanAttachmentRecord: Codable, FetchableRecord, PersistableRecord, Identifiable, Equatable {
    static let databaseTableName = "plan_attachments"

    let id: UUID
    let planID: UUID
    let checklistItemID: UUID?
    let position: Int
    let name: String
    let contentType: String?
    let byteCount: Int64?
    let linkURL: String?

    init(_ attachment: PlanAttachment, planID: UUID, position: Int) {
        id = attachment.id
        self.planID = planID
        checklistItemID = attachment.checklistItemID
        self.position = position
        name = attachment.name
        switch attachment.contents {
        case let .file(type, count):
            contentType = type
            byteCount = count
            linkURL = nil
        case let .link(url):
            contentType = nil
            byteCount = nil
            linkURL = url.absoluteString
        }
    }

    func attachment() throws -> PlanAttachment {
        let contents: PlanAttachment.Contents
        if let linkURL, let url = PlanAttachment.webURL(from: linkURL) {
            contents = .link(url)
        } else if let contentType, let byteCount, PlanAttachment.isValidFilename(name) {
            contents = .file(contentType: contentType, byteCount: byteCount)
        } else {
            throw PlannerStorageError.invalidAttachment
        }
        return PlanAttachment(id: id, checklistItemID: checklistItemID, name: name, contents: contents)
    }
}
