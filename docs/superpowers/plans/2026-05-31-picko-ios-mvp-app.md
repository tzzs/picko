# Picko iOS MVP App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Build the first runnable iOS SwiftUI MVP shell for Picko, driven by `PickoCore`, `PickoPhotos`, mock data, and SwiftData-backed review persistence.

**Architecture:** Add an XcodeGen-managed iOS app project so the app can build, install, and launch on iOS Simulator. Keep reusable UI and app state in a `PickoApp` Swift package target for unit testing, then wire a thin iOS app target around it. Use native `TabView` and `NavigationStack`, local-first SwiftData models, and mock data until real photo-library thumbnails are connected.

**Tech Stack:** Swift 5.9+, SwiftUI, SwiftData, XcodeGen, XcodeBuildMCP, XCTest, iOS 17+.

---

## File Structure

- Create: `project.yml`
  - XcodeGen project for the `Picko` iOS app target.
- Modify: `Package.swift`
  - Add `PickoApp` library target depending on `PickoCore` and `PickoPhotos`.
  - Add `PickoAppTests` target.
- Create: `Sources/PickoApp/PickoAppModel.swift`
  - Root observable app state and mock session actions.
- Create: `Sources/PickoApp/Persistence/ReviewDecisionRecord.swift`
  - SwiftData model for persisted review decisions.
- Create: `Sources/PickoApp/Persistence/ReviewDecisionStore.swift`
  - SwiftData-backed store protocol and implementation.
- Create: `Sources/PickoApp/Fixtures/PickoPreviewFixtures.swift`
  - Mock assets and similar groups.
- Create: `Sources/PickoApp/Views/PickoRootView.swift`
  - Native `TabView` app shell.
- Create: `Sources/PickoApp/Views/OnboardingView.swift`
- Create: `Sources/PickoApp/Views/HomeView.swift`
- Create: `Sources/PickoApp/Views/SingleReviewView.swift`
- Create: `Sources/PickoApp/Views/SimilarGroupReviewView.swift`
- Create: `Sources/PickoApp/Views/PreDeleteBasketView.swift`
- Create: `Apps/Picko/iOS/PickoApp.swift`
  - Thin `@main` app target with SwiftData `modelContainer`.
- Create: `Apps/Picko/iOS/Info.plist`
  - Photos permission strings.
- Create: `Tests/PickoAppTests/PickoAppTests.swift`
  - App model and persistence tests.

## Task 1: Add App Package Target

**Files:**
- Modify: `Package.swift`
- Create: `Sources/PickoApp/PickoAppModel.swift`
- Create: `Tests/PickoAppTests/PickoAppTests.swift`

- [x] **Step 1: Write failing app model test**

```swift
import XCTest
import PickoCore
@testable import PickoApp

final class PickoAppTests: XCTestCase {
    func testPreDeleteActionUpdatesBasketCount() {
        let model = PickoAppModel.preview()

        model.preDeleteCurrentAsset()

        XCTAssertEqual(model.deletionQueueCount, 1)
    }
}
```

Run: `swift test --filter PickoAppTests/testPreDeleteActionUpdatesBasketCount`
Expected: FAIL because `PickoApp` does not exist.

- [x] **Step 2: Add target and minimal model**

Add `PickoApp` and `PickoAppTests` to `Package.swift`. Implement `PickoAppModel` as an `@Observable` reference type that owns `ReviewStateStore`, ordered asset IDs, current index, and actions for keep/pre-delete/skip/undo.

- [x] **Step 3: Verify model test**

Run: `swift test --filter PickoAppTests/testPreDeleteActionUpdatesBasketCount`
Expected: PASS.

## Task 2: Add SwiftData Persistence

**Files:**
- Create: `Sources/PickoApp/Persistence/ReviewDecisionRecord.swift`
- Create: `Sources/PickoApp/Persistence/ReviewDecisionStore.swift`
- Modify: `Tests/PickoAppTests/PickoAppTests.swift`

- [x] **Step 1: Write failing SwiftData store test**

```swift
func testSwiftDataStorePersistsReviewDecision() throws {
    let store = try ReviewDecisionStore.inMemory()

    try store.save(assetId: "a1", status: .preDeleted)

    XCTAssertEqual(try store.status(for: "a1"), .preDeleted)
}
```

Run: `swift test --filter PickoAppTests/testSwiftDataStorePersistsReviewDecision`
Expected: FAIL because `ReviewDecisionStore` does not exist.

- [x] **Step 2: Implement SwiftData record and store**

Create a `@Model` `ReviewDecisionRecord` with `assetId`, `statusRawValue`, and `updatedAt`. Implement `ReviewDecisionStore` with `ModelContainer`, `ModelContext`, `save(assetId:status:)`, `status(for:)`, and an `inMemory()` test factory.

- [x] **Step 3: Verify persistence test**

Run: `swift test --filter PickoAppTests/testSwiftDataStorePersistsReviewDecision`
Expected: PASS.

## Task 3: Build SwiftUI MVP Screens

**Files:**
- Create: `Sources/PickoApp/Fixtures/PickoPreviewFixtures.swift`
- Create: `Sources/PickoApp/Views/PickoRootView.swift`
- Create: `Sources/PickoApp/Views/OnboardingView.swift`
- Create: `Sources/PickoApp/Views/HomeView.swift`
- Create: `Sources/PickoApp/Views/SingleReviewView.swift`
- Create: `Sources/PickoApp/Views/SimilarGroupReviewView.swift`
- Create: `Sources/PickoApp/Views/PreDeleteBasketView.swift`
- Modify: `Tests/PickoAppTests/PickoAppTests.swift`

- [x] **Step 1: Write failing view construction test**

```swift
func testRootViewCanBeConstructedWithPreviewModel() {
    let view = PickoRootView(model: .preview())

    XCTAssertNotNil(view)
}
```

Run: `swift test --filter PickoAppTests/testRootViewCanBeConstructedWithPreviewModel`
Expected: FAIL because `PickoRootView` does not exist.

- [x] **Step 2: Implement root and screens**

Implement native `TabView` tabs for Home, Review, Similar, and Basket. Use `NavigationStack` inside tabs. Keep actions wired to `PickoAppModel`. Use copy that emphasizes keep/review/pre-delete basket and avoids aggressive deletion language.

- [x] **Step 3: Verify view construction**

Run: `swift test --filter PickoAppTests/testRootViewCanBeConstructedWithPreviewModel`
Expected: PASS.

## Task 4: Add Runnable iOS App Target

**Files:**
- Create: `project.yml`
- Create: `Apps/Picko/iOS/PickoApp.swift`
- Create: `Apps/Picko/iOS/Info.plist`

- [x] **Step 1: Write XcodeGen project config**

Create a `project.yml` with an iOS application target named `Picko`, bundle id `com.picko.app`, deployment target iOS 17.0, package dependency on the local Swift package, and dependency on product `PickoApp`.

- [x] **Step 2: Add thin app entry point**

Create `Apps/Picko/iOS/PickoApp.swift` with `@main`, `WindowGroup`, `PickoRootView(model: .preview())`, and `.modelContainer(for: ReviewDecisionRecord.self)`.

- [x] **Step 3: Generate Xcode project**

Run: `xcodegen generate`
Expected: `Picko.xcodeproj` is generated.

## Task 5: Build and Launch on iOS Simulator

**Files:**
- Modify: `docs/MVP-Next-Development-Plan.md`
- Modify: `docs/superpowers/plans/2026-05-31-picko-ios-mvp-app.md`

- [x] **Step 1: Configure XcodeBuildMCP defaults**

Use XcodeBuildMCP to set project `Picko.xcodeproj`, scheme `Picko`, and an available iOS simulator.

- [x] **Step 2: Build and run simulator app**

Run XcodeBuildMCP `build_run_sim`.
Expected: app builds, installs, and launches.

- [x] **Step 3: Capture a screenshot**

Use XcodeBuildMCP `screenshot`.
Expected: screenshot shows the Picko iOS shell with the native tab structure.

- [x] **Step 4: Update docs**

Mark Phase 3 status as in progress or completed depending on whether simulator launch and screenshot verification pass.

## Self-Review

- This plan keeps iOS first and macOS later.
- UI uses native SwiftUI `TabView`, not a custom tab bar.
- The first app runs on mock data while `PickoPhotos` remains available for later real-library integration.
- SwiftData is introduced in the first persistence slice.
