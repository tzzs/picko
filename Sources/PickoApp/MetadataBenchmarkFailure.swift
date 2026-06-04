import PickoPhotos

public enum MetadataBenchmarkFailure: Equatable {
    case photosAccessNotGranted(PhotoLibraryAuthorizationStatus)
    case benchmarkRunFailed

    public var message: String {
        switch self {
        case .photosAccessNotGranted(let status):
            return "Photos benchmark could not run because photo library access is \(status.evidenceDescription)."
        case .benchmarkRunFailed:
            return "Metadata benchmark failed before results could be captured. Check the test library setup and retry."
        }
    }
}

private extension PhotoLibraryAuthorizationStatus {
    var evidenceDescription: String {
        switch self {
        case .notDetermined:
            return "not determined"
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        case .authorized:
            return "authorized"
        case .limited:
            return "limited"
        }
    }
}
