import CoreLocation
import Foundation
import PickoCore

public actor SystemPlaceLabelResolver: PlaceLabelResolving {
    private let geocoder = CLGeocoder()
    private var cache: [String: String] = [:]

    public init() {}

    public func label(for location: PhotoAsset.Location) async -> String? {
        let key = cacheKey(for: location)
        if let cached = cache[key] {
            return cached
        }

        let coordinate = CLLocation(latitude: location.latitude, longitude: location.longitude)
        guard let placemark = try? await geocoder.reverseGeocodeLocation(coordinate).first,
              let label = Self.label(from: placemark) else {
            return nil
        }

        cache[key] = label
        return label
    }

    private func cacheKey(for location: PhotoAsset.Location) -> String {
        String(format: "%.4f,%.4f", location.latitude, location.longitude)
    }

    private static func label(from placemark: CLPlacemark) -> String? {
        let city = firstNonEmpty([
            placemark.locality,
            placemark.subAdministrativeArea,
            placemark.administrativeArea
        ])
        let place = firstNonEmpty([
            placemark.name,
            placemark.subLocality,
            placemark.thoroughfare,
            placemark.areasOfInterest?.first
        ])

        if let city, let place, !place.localizedCaseInsensitiveContains(city) {
            return "\(city) · \(place)"
        }

        return city
    }

    private static func firstNonEmpty(_ values: [String?]) -> String? {
        values
            .compactMap { value in
                value?.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .first { !$0.isEmpty }
    }
}
