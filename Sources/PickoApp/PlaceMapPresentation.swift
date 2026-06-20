import Foundation
import MapKit
import PickoCore
import SwiftUI

struct PlaceMapPresentation: Identifiable {
    private static let overviewPaddingMultiplier = 3.4

    struct Annotation: Identifiable, Equatable {
        var id: String
        var title: String
        var count: Int
        var latitude: Double
        var longitude: Double

        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }

    var annotations: [Annotation]
    var region: MKCoordinateRegion
    var interactionModes: MapInteractionModes {
        [.pan, .zoom]
    }
    var prefersMapTapToExpand: Bool {
        true
    }

    var id: String {
        annotations.map(\.id).joined(separator: "|")
    }

    init(groups: [PhotoCollectionGroup]) {
        annotations = groups.compactMap { group in
            guard let location = group.representativeLocation else {
                return nil
            }

            return Annotation(
                id: group.id,
                title: group.title,
                count: group.assetIds.count,
                latitude: location.latitude,
                longitude: location.longitude
            )
        }

        region = Self.region(for: annotations)
    }

    func fittingRegion(forAspectRatio aspectRatio: Double) -> MKCoordinateRegion {
        Self.region(for: annotations, aspectRatio: aspectRatio, paddingMultiplier: 1.6)
    }

    func thumbnailRegion(forAspectRatio aspectRatio: Double) -> MKCoordinateRegion {
        Self.region(
            for: Self.primaryCluster(from: annotations),
            aspectRatio: aspectRatio,
            paddingMultiplier: Self.overviewPaddingMultiplier
        )
    }

    func detailRegion(forAspectRatio aspectRatio: Double) -> MKCoordinateRegion {
        Self.region(
            for: Self.primaryCluster(from: annotations),
            aspectRatio: aspectRatio,
            paddingMultiplier: Self.overviewPaddingMultiplier
        )
    }

    private static func region(
        for annotations: [Annotation],
        aspectRatio: Double = 1.0,
        paddingMultiplier: Double = 1.6
    ) -> MKCoordinateRegion {
        guard !annotations.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 360)
            )
        }

        let latitudes = annotations.map(\.latitude)
        let longitudes = annotations.map(\.longitude)
        let minLatitude = latitudes.min() ?? 0
        let maxLatitude = latitudes.max() ?? 0
        let minLongitude = longitudes.min() ?? 0
        let maxLongitude = longitudes.max() ?? 0

        let center = CLLocationCoordinate2D(
            latitude: (minLatitude + maxLatitude) / 2,
            longitude: (minLongitude + maxLongitude) / 2
        )

        let normalizedAspectRatio = max(aspectRatio, 0.1)
        let normalizedPaddingMultiplier = max(paddingMultiplier, 1.0)
        var latitudeDelta = max((maxLatitude - minLatitude) * normalizedPaddingMultiplier, 0.08)
        var longitudeDelta = max((maxLongitude - minLongitude) * normalizedPaddingMultiplier, 0.08)

        if longitudeDelta < latitudeDelta * normalizedAspectRatio {
            longitudeDelta = latitudeDelta * normalizedAspectRatio
        } else if latitudeDelta < longitudeDelta / normalizedAspectRatio {
            latitudeDelta = longitudeDelta / normalizedAspectRatio
        }

        let span = MKCoordinateSpan(
            latitudeDelta: min(latitudeDelta, 180),
            longitudeDelta: min(longitudeDelta, 360)
        )

        return MKCoordinateRegion(center: center, span: span)
    }

    private static func primaryCluster(from annotations: [Annotation]) -> [Annotation] {
        guard annotations.count > 2 else {
            return annotations
        }

        let nearbyThresholdMeters = 1_200_000.0
        let minimumClusterCount = max(2, Int(ceil(Double(annotations.count) * 0.5)))
        let candidates = annotations.map { seed in
            annotations.filter { distanceMeters(from: seed, to: $0) <= nearbyThresholdMeters }
        }
        let bestCandidate = candidates.max { lhs, rhs in
            if lhs.count == rhs.count {
                return regionArea(for: lhs) > regionArea(for: rhs)
            }
            return lhs.count < rhs.count
        } ?? annotations

        guard bestCandidate.count >= minimumClusterCount else {
            return annotations
        }

        return bestCandidate.sorted { $0.id < $1.id }
    }

    private static func regionArea(for annotations: [Annotation]) -> Double {
        guard annotations.count > 1 else {
            return 0
        }

        let latitudes = annotations.map(\.latitude)
        let longitudes = annotations.map(\.longitude)
        let latitudeDelta = (latitudes.max() ?? 0) - (latitudes.min() ?? 0)
        let longitudeDelta = (longitudes.max() ?? 0) - (longitudes.min() ?? 0)
        return latitudeDelta * longitudeDelta
    }

    private static func distanceMeters(from lhs: Annotation, to rhs: Annotation) -> Double {
        let earthRadiusMeters = 6_371_000.0
        let latitude1 = degreesToRadians(lhs.latitude)
        let latitude2 = degreesToRadians(rhs.latitude)
        let deltaLatitude = degreesToRadians(rhs.latitude - lhs.latitude)
        let deltaLongitude = degreesToRadians(rhs.longitude - lhs.longitude)
        let a = sin(deltaLatitude / 2) * sin(deltaLatitude / 2)
            + cos(latitude1) * cos(latitude2) * sin(deltaLongitude / 2) * sin(deltaLongitude / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadiusMeters * c
    }

    private static func degreesToRadians(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }
}
