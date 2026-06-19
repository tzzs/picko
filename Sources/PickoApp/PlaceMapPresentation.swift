import Foundation
import MapKit
import PickoCore
import SwiftUI

struct PlaceMapPresentation: Identifiable {
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

    private static func region(for annotations: [Annotation]) -> MKCoordinateRegion {
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
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLatitude - minLatitude) * 1.6, 0.08),
            longitudeDelta: max((maxLongitude - minLongitude) * 1.6, 0.08)
        )

        return MKCoordinateRegion(center: center, span: span)
    }
}
