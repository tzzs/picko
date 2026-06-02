#if canImport(Photos)
import Photos

public enum PhotoLibraryAuthorizationStatus: Equatable {
    case notDetermined
    case restricted
    case denied
    case authorized
    case limited

    public init(platformStatus: PHAuthorizationStatus) {
        switch platformStatus {
        case .notDetermined:
            self = .notDetermined
        case .restricted:
            self = .restricted
        case .denied:
            self = .denied
        case .authorized:
            self = .authorized
        case .limited:
            self = .limited
        @unknown default:
            self = .restricted
        }
    }
}

public protocol PhotoLibraryAuthorizing {
    func authorizationStatus() -> PhotoLibraryAuthorizationStatus
    func requestAuthorization() async -> PhotoLibraryAuthorizationStatus
}
#endif
