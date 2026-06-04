# Picko Photos Adapter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Add an Apple-platform Photos adapter target that maps Photos library authorization, asset metadata, resource size estimates, and delete requests into Picko domain APIs.

**Architecture:** Keep `PickoCore` independent from Photos by introducing a separate `PickoPhotos` SwiftPM target that depends on `PickoCore` and imports Photos only behind Apple platform availability. Put protocol-friendly mapping logic in small units so tests can use plain fake snapshots instead of constructing `PHAsset`.

**Tech Stack:** Swift 5.9+, Swift Package Manager, Photos framework, XCTest.

---

## File Structure

- Modify: `Package.swift`
  - Add `PickoPhotos` library product.
  - Add `PickoPhotos` target depending on `PickoCore`.
  - Add `PickoPhotosTests` target depending on `PickoPhotos`.
- Create: `Sources/PickoPhotos/PhotoLibraryAuthorization.swift`
  - Defines `PhotoLibraryAuthorizationStatus` and `PhotoLibraryAuthorizing`.
- Create: `Sources/PickoPhotos/PhotoAssetSnapshot.swift`
  - Defines a testable snapshot of Photos metadata.
- Create: `Sources/PickoPhotos/PhotoAssetMapper.swift`
  - Maps `PhotoAssetSnapshot` into `PickoCore.PhotoAsset`.
- Create: `Sources/PickoPhotos/PhotosLibraryAdapter.swift`
  - Wraps Photos authorization, asset fetch, resource size estimate, and delete request APIs.
- Create: `Tests/PickoPhotosTests/PickoPhotosTests.swift`
  - Covers authorization status mapping and asset snapshot mapping.

## Task 1: Add Package Target

**Files:**
- Modify: `Package.swift`

- [x] **Step 1: Add `PickoPhotos` product and targets**

Update `Package.swift` so the package exposes both library products:

```swift
products: [
    .library(name: "PickoCore", targets: ["PickoCore"]),
    .library(name: "PickoPhotos", targets: ["PickoPhotos"])
],
targets: [
    .target(name: "PickoCore"),
    .target(name: "PickoPhotos", dependencies: ["PickoCore"]),
    .testTarget(name: "PickoCoreTests", dependencies: ["PickoCore"]),
    .testTarget(name: "PickoPhotosTests", dependencies: ["PickoPhotos"])
]
```

- [x] **Step 2: Add empty target placeholder**

Create `Sources/PickoPhotos/PickoPhotos.swift`:

```swift
public enum PickoPhotos {}
```

- [x] **Step 3: Verify target compiles**

Run: `swift test`
Expected: PASS with existing `PickoCoreTests`.

## Task 2: Authorization Domain API

**Files:**
- Create: `Sources/PickoPhotos/PhotoLibraryAuthorization.swift`
- Test: `Tests/PickoPhotosTests/PickoPhotosTests.swift`

- [x] **Step 1: Write failing authorization mapping test**

```swift
import XCTest
@testable import PickoPhotos

final class PickoPhotosTests: XCTestCase {
    func testAuthorizationStatusPreservesLimitedAccess() {
        XCTAssertEqual(PhotoLibraryAuthorizationStatus(platformStatus: .limited), .limited)
    }
}
```

Run: `swift test --filter PickoPhotosTests/testAuthorizationStatusPreservesLimitedAccess`
Expected: FAIL because `PhotoLibraryAuthorizationStatus` does not exist.

- [x] **Step 2: Implement authorization status**

```swift
import Photos

public enum PhotoLibraryAuthorizationStatus: Equatable {
    case notDetermined
    case restricted
    case denied
    case authorized
    case limited

    public init(platformStatus: PHAuthorizationStatus) {
        switch platformStatus {
        case .notDetermined: self = .notDetermined
        case .restricted: self = .restricted
        case .denied: self = .denied
        case .authorized: self = .authorized
        case .limited: self = .limited
        @unknown default: self = .restricted
        }
    }
}

public protocol PhotoLibraryAuthorizing {
    func authorizationStatus() -> PhotoLibraryAuthorizationStatus
    func requestAuthorization() async -> PhotoLibraryAuthorizationStatus
}
```

- [x] **Step 3: Verify authorization mapping**

Run: `swift test --filter PickoPhotosTests/testAuthorizationStatusPreservesLimitedAccess`
Expected: PASS.

## Task 3: Asset Snapshot Mapping

**Files:**
- Create: `Sources/PickoPhotos/PhotoAssetSnapshot.swift`
- Create: `Sources/PickoPhotos/PhotoAssetMapper.swift`
- Modify: `Tests/PickoPhotosTests/PickoPhotosTests.swift`

- [x] **Step 1: Write failing asset mapping test**

```swift
func testPhotoSnapshotMapsToCoreAsset() {
    let snapshot = PhotoAssetSnapshot(
        localIdentifier: "asset-1",
        mediaType: .image,
        creationDate: Date(timeIntervalSince1970: 100),
        latitude: 31.2,
        longitude: 121.4,
        pixelWidth: 4000,
        pixelHeight: 3000,
        fileSizeBytes: 3_500_000,
        isFavorite: true,
        isEdited: false,
        isScreenshot: false,
        duration: nil,
        thumbnailHash: nil,
        perceptualHash: nil
    )

    let asset = PhotoAssetMapper().asset(from: snapshot)

    XCTAssertEqual(asset.id, "asset-1")
    XCTAssertEqual(asset.mediaType, .photo)
    XCTAssertEqual(asset.location?.latitude, 31.2)
    XCTAssertEqual(asset.fileSizeBytes, 3_500_000)
    XCTAssertTrue(asset.isFavorite)
}
```

Run: `swift test --filter PickoPhotosTests/testPhotoSnapshotMapsToCoreAsset`
Expected: FAIL because `PhotoAssetSnapshot` and `PhotoAssetMapper` do not exist.

- [x] **Step 2: Implement snapshot and mapper**

Create a public snapshot with `MediaType` cases `.image`, `.video`, `.livePhoto`, `.screenshot`. Create `PhotoAssetMapper.asset(from:)` that maps media type, optional latitude/longitude, dimensions, file size, flags, duration, hashes, and default review status into `PickoCore.PhotoAsset`.

- [x] **Step 3: Verify mapping**

Run: `swift test --filter PickoPhotosTests/testPhotoSnapshotMapsToCoreAsset`
Expected: PASS.

## Task 4: Photos Framework Adapter

**Files:**
- Create: `Sources/PickoPhotos/PhotosLibraryAdapter.swift`
- Modify: `Tests/PickoPhotosTests/PickoPhotosTests.swift`

- [x] **Step 1: Write protocol conformance test**

```swift
func testPhotosLibraryAdapterConformsToAuthorizationProtocol() {
    let adapter: PhotoLibraryAuthorizing = PhotosLibraryAdapter()

    XCTAssertNotNil(adapter)
}
```

Run: `swift test --filter PickoPhotosTests/testPhotosLibraryAdapterConformsToAuthorizationProtocol`
Expected: FAIL because `PhotosLibraryAdapter` does not exist.

- [x] **Step 2: Implement adapter shell**

Implement `PhotosLibraryAdapter` as `PhotoLibraryAuthorizing` with:

```swift
public final class PhotosLibraryAdapter: PhotoLibraryAuthorizing {
    public init() {}

    public func authorizationStatus() -> PhotoLibraryAuthorizationStatus {
        PhotoLibraryAuthorizationStatus(platformStatus: PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    public func requestAuthorization() async -> PhotoLibraryAuthorizationStatus {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: PhotoLibraryAuthorizationStatus(platformStatus: status))
            }
        }
    }
}
```

- [x] **Step 3: Verify adapter shell**

Run: `swift test --filter PickoPhotosTests/testPhotosLibraryAdapterConformsToAuthorizationProtocol`
Expected: PASS.

## Task 5: Adapter Protocols for Indexing and Deletion

**Files:**
- Modify: `Sources/PickoPhotos/PhotosLibraryAdapter.swift`
- Modify: `Tests/PickoPhotosTests/PickoPhotosTests.swift`

- [x] **Step 1: Write failing protocol tests**

```swift
func testPhotosLibraryAdapterExposesIndexingAndDeletionContracts() {
    let adapter = PhotosLibraryAdapter()
    let indexer: PhotoAssetIndexing = adapter
    let deleter: PhotoDeleting = adapter

    XCTAssertNotNil(indexer)
    XCTAssertNotNil(deleter)
}
```

Run: `swift test --filter PickoPhotosTests/testPhotosLibraryAdapterExposesIndexingAndDeletionContracts`
Expected: FAIL because `PhotoAssetIndexing` and `PhotoDeleting` do not exist.

- [x] **Step 2: Implement protocols and minimal adapter methods**

Add:

```swift
public protocol PhotoAssetIndexing {
    func fetchAssetSnapshots() async throws -> [PhotoAssetSnapshot]
}

public protocol PhotoDeleting {
    func requestDeletion(assetIds: [String]) async throws
}
```

Implement `PhotosLibraryAdapter.fetchAssetSnapshots()` with `PHAsset.fetchAssets(with: nil)` and `PhotosLibraryAdapter.requestDeletion(assetIds:)` with `PHPhotoLibrary.shared().performChanges`.

- [x] **Step 3: Verify full package**

Run: `swift test`
Expected: PASS.

## Self-Review

- This plan keeps Photos out of `PickoCore`.
- Tests avoid constructing `PHAsset` directly by mapping `PhotoAssetSnapshot`.
- Deletion is only exposed as a user-triggered request wrapper around Photos changes.
- iOS/macOS UI work is intentionally left for the later iOS MVP plan.
