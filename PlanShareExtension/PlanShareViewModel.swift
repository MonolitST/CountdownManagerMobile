import Foundation
import Observation

@MainActor
@Observable
final class PlanShareViewModel {
    private(set) var plans: [Plan]?
    private(set) var isSaving = false
    var errorMessage: String?

    @ObservationIgnored private let providers: [NSItemProvider]
    @ObservationIgnored private var repository: SQLitePlannerRepository?

    init(providers: [NSItemProvider]) {
        self.providers = providers
    }

    func load() {
        guard plans == nil, errorMessage == nil else { return }
        do {
            let repository = try PlannerSharedLocation.openForSharing()
            let saved = try repository.load()
            self.repository = repository
            plans = saved.plans.sorted {
                if $0.isFavorite != $1.isFavorite { return $0.isFavorite }
                return $0.day < $1.day
            }
        } catch {
            plans = []
            errorMessage = String(localized: "Open Countdown Manager first to make your plans available.")
        }
    }

    func save(to planID: UUID) async -> Bool {
        guard let repository, !isSaving else { return false }
        isSaving = true
        defer { isSaving = false }

        var items: [PlanSharedItem] = []
        defer { items.compactMap(\.importedFile).forEach { ImportedPlanFile.discard($0.url) } }
        do {
            for provider in providers {
                try Task.checkCancellation()
                if let item = try await PlanSharedItem.load(from: provider) { items.append(item) }
            }
            try Task.checkCancellation()
            let files = Dictionary(uniqueKeysWithValues: items.compactMap(\.importedFile).map { ($0.id, $0.url) })
            try repository.addSharedAttachments(items.map(\.attachment), to: planID, importing: files)
            return true
        } catch is CancellationError {
            return false
        } catch {
            errorMessage = String(localized: "Couldn’t add the attachment. Check the plan and try again.")
            return false
        }
    }
}
