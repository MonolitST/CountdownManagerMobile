import CoreLocation
import MapKit
import Observation

@MainActor
@Observable
final class WeatherLocationService: NSObject, @preconcurrency CLLocationManagerDelegate {
    private(set) var authorization: CLAuthorizationStatus = .notDetermined
    private(set) var place: WeatherPlace?
    private(set) var isLocating = false
    private(set) var failed = false

    @ObservationIgnored private let manager = CLLocationManager()
    @ObservationIgnored private var cityLookup: Task<Void, Never>?
    @ObservationIgnored private var automatic = false
    @ObservationIgnored private var active = false

    override init() {
        super.init()
        authorization = manager.authorizationStatus
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.delegate = self
    }

    var accessDenied: Bool { authorization == .denied || authorization == .restricted }

    func configure(automatic: Bool, active: Bool) {
        self.automatic = automatic
        self.active = active
        if !automatic {
            cancelLookup()
            place = nil
            failed = false
        } else if active {
            locateIfAuthorized()
        } else {
            cancelLookup()
        }
    }

    func useCurrentLocation() {
        automatic = true
        if authorization == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else {
            locateIfAuthorized()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization = manager.authorizationStatus
        if accessDenied {
            cancelLookup()
            place = nil
        }
        locateIfAuthorized()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isLocating, automatic, active, cityLookup == nil else { return }
        guard let location = locations.last(where: { $0.horizontalAccuracy >= 0 }) else {
            finishFailure()
            return
        }
        let latitude = (location.coordinate.latitude * 100).rounded() / 100
        let longitude = (location.coordinate.longitude * 100).rounded() / 100
        if let place, place.latitude == latitude, place.longitude == longitude,
           place.name != String(localized: "Current location") {
            isLocating = false
            return
        }

        let approximate = CLLocation(latitude: latitude, longitude: longitude)
        cityLookup = Task { [weak self] in
            let name = await Self.cityName(near: approximate)
            guard let self, !Task.isCancelled else { return }
            place = WeatherPlace(name: name ?? String(localized: "Current location"),
                                 latitude: latitude, longitude: longitude)
            isLocating = false
            cityLookup = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        guard isLocating, cityLookup == nil else { return }
        finishFailure()
    }

    private func locateIfAuthorized() {
        guard automatic, active, !isLocating,
              authorization == .authorizedWhenInUse || authorization == .authorizedAlways else { return }
        failed = false
        isLocating = true
        manager.requestLocation()
    }

    private func finishFailure() {
        isLocating = false
        failed = true
    }

    private func cancelLookup() {
        guard isLocating else { return }
        isLocating = false
        manager.stopUpdatingLocation()
        cityLookup?.cancel()
        cityLookup = nil
    }

    private static func cityName(near location: CLLocation) async -> String? {
        if #available(iOS 26.0, *) {
            guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
            request.preferredLocale = AppDate.locale
            let items = try? await request.mapItems
            return items?.compactMap { $0.addressRepresentations?.cityName }.first
        } else {
            let places = try? await CLGeocoder().reverseGeocodeLocation(location, preferredLocale: AppDate.locale)
            return places?.first?.locality
        }
    }
}
