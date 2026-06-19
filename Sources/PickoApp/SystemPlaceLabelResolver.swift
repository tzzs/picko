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
        PhotoPlaceLabelFormatter.label(
            city: firstNonEmpty([
                placemark.locality,
                placemark.subAdministrativeArea,
                placemark.administrativeArea
            ]),
            region: firstNonEmpty([
                placemark.administrativeArea,
                placemark.subAdministrativeArea
            ]),
            country: placemark.country,
            place: firstNonEmpty([
                placemark.name,
                placemark.subLocality,
                placemark.thoroughfare
            ]),
            areaOfInterest: placemark.areasOfInterest?.first,
            naturalFeature: firstNonEmpty([
                placemark.inlandWater,
                placemark.ocean
            ])
        )
    }

    private static func firstNonEmpty(_ values: [String?]) -> String? {
        values
            .compactMap { value in
                value?.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .first { !$0.isEmpty }
    }
}

enum PhotoPlaceLabelFormatter {
    static func label(
        city: String?,
        region: String?,
        country: String?,
        place: String?,
        areaOfInterest: String?,
        naturalFeature: String?
    ) -> String? {
        let city = firstNonEmpty([city])
        let detail = firstNonEmpty([areaOfInterest, place, naturalFeature])

        if let city {
            return combinedLabel(context: city, detail: detail)
        }

        let widerContext = firstNonEmpty([country, region])
        if let widerContext {
            return combinedLabel(context: widerContext, detail: detail)
        }

        return detail
    }

    private static func combinedLabel(context: String, detail: String?) -> String {
        guard let detail, !isDuplicate(context: context, detail: detail) else {
            return context
        }

        return "\(context) · \(detail)"
    }

    private static func isDuplicate(context: String, detail: String) -> Bool {
        let foldedContext = context.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let foldedDetail = detail.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        return foldedContext == foldedDetail || foldedDetail.contains(foldedContext)
    }

    private static func firstNonEmpty(_ values: [String?]) -> String? {
        values
            .compactMap { value in
                value?.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .first { !$0.isEmpty }
    }
}
