import Foundation

enum WeatherService {
    static func forecast(for place: WeatherPlace) async throws -> WeatherForecast {
        try await get(host: "api.open-meteo.com", path: "/v1/forecast", query: [
            "latitude": String(place.latitude), "longitude": String(place.longitude),
            "current": "temperature_2m,weather_code", "daily": "temperature_2m_min,temperature_2m_max",
            "timezone": "auto", "forecast_days": "1"
        ])
    }

    static func cities(matching name: String, language: String) async throws -> [WeatherCity] {
        let response: CityResults = try await get(host: "geocoding-api.open-meteo.com", path: "/v1/search",
                                                  query: ["name": name, "language": language, "count": "10"])
        return response.results ?? []
    }

    private static func get<Response: Decodable>(host: String, path: String,
                                                  query: [String: String]) async throws -> Response {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = components.url else { throw URLError(.badURL) }
        let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url, timeoutInterval: 12))
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode(Response.self, from: data)
    }

    private struct CityResults: Decodable {
        let results: [WeatherCity]?
    }
}
