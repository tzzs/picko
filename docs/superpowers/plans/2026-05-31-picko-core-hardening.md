# Picko Core Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Strengthen `PickoCore` before UI integration by adding deterministic location-aware grouping, broader state-store coverage, and a testable recommendation scoring unit.

**Architecture:** Keep all hardening inside `PickoCore` and its tests. Extract recommendation scoring from `SimilarityEngine` into a small `RecommendationEngine`, then make `SimilarityEngine` consume it. Extend grouping configuration with optional location distance so metadata-first grouping remains deterministic and locally testable.

**Tech Stack:** Swift 5.9+, Swift Package Manager, XCTest.

---

## File Structure

- Create: `Sources/PickoCore/RecommendationEngine.swift`
  - Scores candidate keep assets using favorite, edited, resolution, and file-size signals.
- Modify: `Sources/PickoCore/SimilarityEngine.swift`
  - Adds optional location threshold configuration.
  - Uses `RecommendationEngine`.
- Modify: `Tests/PickoCoreTests/PickoCoreTests.swift`
  - Adds focused tests for store actions, grouping boundaries, and recommendation order.

## Task 1: Review State Store Boundaries

**Files:**
- Modify: `Tests/PickoCoreTests/PickoCoreTests.swift`
- Modify: `Sources/PickoCore/ReviewStateStore.swift`

- [x] **Step 1: Write failing tests for keep, skip, and duplicate pre-delete**

```swift
func testKeepRemovesAssetFromDeletionQueue() {
    let asset = makeAsset(id: "a1", fileSizeBytes: 10)
    var store = ReviewStateStore(assets: [asset])

    store.apply(.preDelete("a1"))
    store.apply(.keep("a1"))

    XCTAssertEqual(store.asset(id: "a1")?.status, .kept)
    XCTAssertTrue(store.deletionQueue.itemIds.isEmpty)
}

func testSkipMarksAssetSkippedWithoutQueueingForDeletion() {
    let asset = makeAsset(id: "a1", fileSizeBytes: 10)
    var store = ReviewStateStore(assets: [asset])

    store.apply(.skip("a1"))

    XCTAssertEqual(store.asset(id: "a1")?.status, .skipped)
    XCTAssertTrue(store.deletionQueue.itemIds.isEmpty)
}

func testPreDeletingSameAssetTwiceDoesNotDuplicateQueueItem() {
    let asset = makeAsset(id: "a1", fileSizeBytes: 10)
    var store = ReviewStateStore(assets: [asset])

    store.apply(.preDelete("a1"))
    store.apply(.preDelete("a1"))

    XCTAssertEqual(store.deletionQueue.itemIds, ["a1"])
    XCTAssertEqual(store.deletionQueue.estimatedBytes, 10)
}
```

Run: `swift test --filter PickoCoreTests/testKeepRemovesAssetFromDeletionQueue` and the two sibling tests.
Expected: PASS if current store already handles these; if not, fail for the specific missing behavior.

- [x] **Step 2: Patch only missing behavior**

If any test fails, update `ReviewStateStore.setStatus` or `DeletionQueue.add` so non-pre-delete statuses restore queue membership and duplicate pre-delete does not duplicate item ids.

- [x] **Step 3: Verify store boundaries**

Run: `swift test --filter PickoCoreTests`
Expected: PASS.

## Task 2: Recommendation Engine

**Files:**
- Create: `Sources/PickoCore/RecommendationEngine.swift`
- Modify: `Sources/PickoCore/SimilarityEngine.swift`
- Modify: `Tests/PickoCoreTests/PickoCoreTests.swift`

- [x] **Step 1: Write failing recommendation priority tests**

```swift
func testRecommendationPrefersEditedAssetOverLargerUneditedAsset() {
    let base = Date(timeIntervalSince1970: 1_000)
    let assets = [
        makeAsset(id: "a1", creationDate: base, pixelWidth: 6000, pixelHeight: 4000, fileSizeBytes: 8_000_000, isEdited: false),
        makeAsset(id: "a2", creationDate: base, pixelWidth: 3000, pixelHeight: 2000, fileSizeBytes: 2_000_000, isEdited: true)
    ]

    let recommended = RecommendationEngine().recommendedKeepIds(from: assets, keepCount: 1)

    XCTAssertEqual(recommended, ["a2"])
}

func testRecommendationReturnsRequestedKeepCountInScoreOrder() {
    let assets = [
        makeAsset(id: "a1", pixelWidth: 1000, pixelHeight: 1000, fileSizeBytes: 1),
        makeAsset(id: "a2", pixelWidth: 4000, pixelHeight: 3000, fileSizeBytes: 1),
        makeAsset(id: "a3", pixelWidth: 3000, pixelHeight: 2000, fileSizeBytes: 1)
    ]

    let recommended = RecommendationEngine().recommendedKeepIds(from: assets, keepCount: 2)

    XCTAssertEqual(recommended, ["a2", "a3"])
}
```

Run: `swift test --filter PickoCoreTests/testRecommendationPrefersEditedAssetOverLargerUneditedAsset`
Expected: FAIL because `RecommendationEngine` does not exist.

- [x] **Step 2: Implement recommendation engine**

Implement public `RecommendationEngine` with:

```swift
public struct RecommendationEngine: Equatable {
    public init() {}

    public func recommendedKeepIds(from assets: [PhotoAsset], keepCount: Int) -> [PhotoAsset.ID] {
        guard keepCount > 0 else { return [] }
        return assets
            .sorted { lhs, rhs in
                let lhsScore = score(for: lhs)
                let rhsScore = score(for: rhs)
                if lhsScore == rhsScore { return lhs.id < rhs.id }
                return lhsScore > rhsScore
            }
            .prefix(keepCount)
            .map(\.id)
    }

    public func score(for asset: PhotoAsset) -> Int64 {
        var value = Int64(asset.pixelWidth * asset.pixelHeight)
        value += asset.fileSizeBytes / 1_000
        if asset.isFavorite { value += 10_000_000_000 }
        if asset.isEdited { value += 1_000_000_000 }
        return value
    }
}
```

- [x] **Step 3: Make `SimilarityEngine` use `RecommendationEngine`**

Replace private `recommendedKeepId(from:)` and `qualityScore(for:)` with `RecommendationEngine().recommendedKeepIds(from: assets, keepCount: 1)`.

- [x] **Step 4: Verify recommendation tests**

Run: `swift test --filter PickoCoreTests/testRecommendation`
Expected: PASS.

## Task 3: Location-Aware Similarity

**Files:**
- Modify: `Sources/PickoCore/SimilarityEngine.swift`
- Modify: `Tests/PickoCoreTests/PickoCoreTests.swift`

- [x] **Step 1: Write failing location threshold test**

```swift
func testAssetsOutsideLocationThresholdAreNotGrouped() {
    let base = Date(timeIntervalSince1970: 1_000)
    let assets = [
        makeAsset(id: "a1", creationDate: base, location: .init(latitude: 31.2304, longitude: 121.4737), thumbnailHash: "same", perceptualHash: "same"),
        makeAsset(id: "a2", creationDate: base.addingTimeInterval(10), location: .init(latitude: 39.9042, longitude: 116.4074), thumbnailHash: "same", perceptualHash: "same")
    ]

    let groups = SimilarityEngine(configuration: .init(timeWindow: 60, locationThresholdMeters: 100)).groups(from: assets)

    XCTAssertTrue(groups.isEmpty)
}
```

Run: `swift test --filter PickoCoreTests/testAssetsOutsideLocationThresholdAreNotGrouped`
Expected: FAIL because `locationThresholdMeters` does not exist.

- [x] **Step 2: Extend configuration and distance check**

Add `locationThresholdMeters: Double? = nil` to `SimilarityEngine.Configuration`. When both compared assets have locations and the threshold is present, use haversine distance and require distance <= threshold. When one or both locations are missing, do not fail the match solely on location.

- [x] **Step 3: Verify location threshold**

Run: `swift test --filter PickoCoreTests/testAssetsOutsideLocationThresholdAreNotGrouped`
Expected: PASS.

## Task 4: Similarity Boundary Tests

**Files:**
- Modify: `Tests/PickoCoreTests/PickoCoreTests.swift`

- [x] **Step 1: Add media and time boundary tests**

```swift
func testAssetsWithDifferentMediaTypesAreNotGrouped() {
    let base = Date(timeIntervalSince1970: 1_000)
    let assets = [
        makeAsset(id: "a1", mediaType: .photo, creationDate: base, thumbnailHash: "same", perceptualHash: "same"),
        makeAsset(id: "a2", mediaType: .video, creationDate: base.addingTimeInterval(10), thumbnailHash: "same", perceptualHash: "same")
    ]

    let groups = SimilarityEngine(configuration: .init(timeWindow: 60)).groups(from: assets)

    XCTAssertTrue(groups.isEmpty)
}

func testAssetsOutsideTimeWindowAreNotGroupedEvenWhenHashesMatch() {
    let base = Date(timeIntervalSince1970: 1_000)
    let assets = [
        makeAsset(id: "a1", creationDate: base, thumbnailHash: "same", perceptualHash: "same"),
        makeAsset(id: "a2", creationDate: base.addingTimeInterval(120), thumbnailHash: "same", perceptualHash: "same")
    ]

    let groups = SimilarityEngine(configuration: .init(timeWindow: 60)).groups(from: assets)

    XCTAssertTrue(groups.isEmpty)
}
```

Run: `swift test --filter PickoCoreTests/testAssetsWithDifferentMediaTypesAreNotGrouped` and sibling test.
Expected: PASS with existing behavior; if either fails, patch `SimilarityEngine.areSimilar`.

## Self-Review

- This plan does not introduce UI work.
- Every behavior has a direct XCTest.
- Recommendation scoring remains metadata-only and local-first.
- Location filtering is opt-in so existing grouping behavior remains backward-compatible.
