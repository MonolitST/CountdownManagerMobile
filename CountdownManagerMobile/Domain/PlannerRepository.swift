import Foundation

protocol PlannerRepository {
    func load() throws -> PlannerData
    func save(_ updated: PlannerData, replacing previous: PlannerData, importing files: [UUID: URL]) throws
    func fileURL(for attachment: PlanAttachment) -> URL?
    func consumeSharedUpdate() throws -> (planID: UUID, data: PlannerData)?
}

extension PlannerRepository {
    func save(_ updated: PlannerData, replacing previous: PlannerData) throws {
        try save(updated, replacing: previous, importing: [:])
    }
}
