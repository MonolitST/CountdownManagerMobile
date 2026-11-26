import Foundation
import Observation

@MainActor
@Observable
final class CitySearch {
    enum Phase {
        case idle, searching, results([WeatherCity]), failed
    }

    var query = ""
    private(set) var phase: Phase = .idle

    var term: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

    func loadMatches(for term: String) async {
        guard !Task.isCancelled, term == self.term else { return }
        guard term.count >= 2 else {
            phase = .idle
            return
        }
        phase = .searching

        do {
            try await Task.sleep(for: .milliseconds(300))
            let matches = try await WeatherService.cities(matching: term, language: AppDate.languageCode)
            guard !Task.isCancelled, term == self.term else { return }
            phase = .results(matches)
        } catch {
            guard !Task.isCancelled, term == self.term else { return }
            phase = .failed
        }
    }
}
