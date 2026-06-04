# Picko macOS MVP App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Build the first runnable macOS SwiftUI MVP workbench for Picko with sidebar navigation, grid review, inspector details, and keyboard commands.

**Architecture:** Add a reusable `PickoMacApp` SwiftPM target for desktop-specific state and views, then wire it into an XcodeGen-managed macOS app target. Reuse `PickoCore`, `PickoPhotos`, and existing mock fixtures while keeping macOS layout native through `NavigationSplitView`, `Table`/`LazyVGrid`, toolbar actions, and command shortcuts.

**Tech Stack:** Swift 5.9+, SwiftUI, SwiftData, XcodeGen, xcodebuild, XCTest, macOS 14+.

---

## File Structure

- Modify: `Package.swift`
  - Add `PickoMacApp` library target depending on `PickoApp`, `PickoCore`, and `PickoPhotos`.
  - Add `PickoMacAppTests`.
- Create: `Sources/PickoMacApp/PickoMacWorkbenchModel.swift`
  - Selection and desktop action routing.
- Create: `Sources/PickoMacApp/Views/PickoMacRootView.swift`
  - `NavigationSplitView` sidebar-detail-inspector shell.
- Create: `Sources/PickoMacApp/Views/PickoMacSidebarView.swift`
- Create: `Sources/PickoMacApp/Views/PickoMacGridReviewView.swift`
- Create: `Sources/PickoMacApp/Views/PickoMacInspectorView.swift`
- Create: `Sources/PickoMacApp/Views/PickoMacBasketView.swift`
- Create: `Sources/PickoMacApp/Views/PickoMacSimilarGroupsView.swift`
- Create: `Sources/PickoMacApp/Views/PickoMacTimeLocationView.swift`
- Create: `Apps/Picko/macOS/PickoMacApp.swift`
  - Thin macOS `@main` app wrapper and command definitions.
- Modify: `project.yml`
  - Add macOS app target `PickoMac` and `PickoMacTests`.
- Create: `Tests/PickoMacAppTests/PickoMacAppTests.swift`
  - Unit tests for selection/actions and view construction.
- Create: `Tests/PickoMacTests/PickoMacTests.swift`
  - macOS app target smoke test.

## Task 1: Add Desktop Model Target

**Files:**
- Modify: `Package.swift`
- Create: `Sources/PickoMacApp/PickoMacWorkbenchModel.swift`
- Create: `Tests/PickoMacAppTests/PickoMacAppTests.swift`

- [x] **Step 1: Write failing desktop model test**

```swift
import XCTest
@testable import PickoMacApp

final class PickoMacAppTests: XCTestCase {
    func testSelectingAssetUpdatesInspectorSelection() {
        let model = PickoMacWorkbenchModel.preview()

        model.selectAsset(id: "preview-2")

        XCTAssertEqual(model.selectedAsset?.id, "preview-2")
    }
}
```

Run: `swift test --filter PickoMacAppTests/testSelectingAssetUpdatesInspectorSelection`
Expected: FAIL because `PickoMacApp` does not exist.

- [x] **Step 2: Add target and model**

Add `PickoMacApp` and `PickoMacAppTests` to `Package.swift`. Implement `PickoMacWorkbenchModel` as an `@Observable` type that wraps `PickoAppModel.preview()`, tracks sidebar selection, selected asset id, and exposes keep/pre-delete/undo commands.

- [x] **Step 3: Verify desktop model test**

Run: `swift test --filter PickoMacAppTests/testSelectingAssetUpdatesInspectorSelection`
Expected: PASS.

## Task 2: Build macOS Split View Workbench

**Files:**
- Create: `Sources/PickoMacApp/Views/PickoMacRootView.swift`
- Create: `Sources/PickoMacApp/Views/PickoMacSidebarView.swift`
- Create: `Sources/PickoMacApp/Views/PickoMacGridReviewView.swift`
- Create: `Sources/PickoMacApp/Views/PickoMacInspectorView.swift`
- Modify: `Tests/PickoMacAppTests/PickoMacAppTests.swift`

- [x] **Step 1: Write failing root view construction test**

```swift
func testMacRootViewCanBeConstructed() {
    let view = PickoMacRootView(model: .preview())

    XCTAssertNotNil(view)
}
```

Run: `swift test --filter PickoMacAppTests/testMacRootViewCanBeConstructed`
Expected: FAIL because `PickoMacRootView` does not exist.

- [x] **Step 2: Implement split view**

Implement a `NavigationSplitView` with native sidebar rows for Home, Similar, Time, Location, and Basket. The detail pane should show a grid of mock assets and selection. The inspector should show date, dimensions, bytes, status, and recommended reason for the selected asset.

- [x] **Step 3: Verify view construction**

Run: `swift test --filter PickoMacAppTests/testMacRootViewCanBeConstructed`
Expected: PASS.

## Task 3: Add Basket, Similar, Time, and Location Views

**Files:**
- Create: `Sources/PickoMacApp/Views/PickoMacBasketView.swift`
- Create: `Sources/PickoMacApp/Views/PickoMacSimilarGroupsView.swift`
- Create: `Sources/PickoMacApp/Views/PickoMacTimeLocationView.swift`

- [x] **Step 1: Implement desktop feature panes**

Add panes for the remaining sidebar destinations. Keep these mock-data driven but wired to `PickoMacWorkbenchModel` actions so pre-delete basket state updates from grid and command actions.

- [x] **Step 2: Verify package tests**

Run: `swift test --filter PickoMacAppTests`
Expected: PASS.

## Task 4: Add macOS Xcode Target

**Files:**
- Modify: `project.yml`
- Create: `Apps/Picko/macOS/PickoMacApp.swift`
- Create: `Tests/PickoMacTests/PickoMacTests.swift`

- [x] **Step 1: Add XcodeGen target**

Add a macOS application target named `PickoMac`, bundle id `com.tanzz.PickoMac`, deployment target macOS 14.0, and dependency on local package product `PickoMacApp`.

- [x] **Step 2: Add macOS app wrapper and commands**

Create `PickoMacApp.swift` with `WindowGroup`, `PickoMacRootView(model: .preview())`, and commands for `K`, `D`, `Z`, `Space`, and `1`.

- [x] **Step 3: Generate project**

Run: `xcodegen generate`
Expected: `Picko.xcodeproj` includes `PickoMac` and `PickoMacTests`.

## Task 5: Build and Test macOS Target

**Files:**
- Modify: `docs/MVP-Next-Development-Plan.md`
- Modify: `docs/MVP-Product-Spec.md`
- Modify: `docs/superpowers/plans/2026-05-31-picko-macos-mvp-app.md`

- [x] **Step 1: Run Swift package tests**

Run: `swift test`
Expected: PASS.

- [x] **Step 2: Run macOS Xcode build**

Run: `xcodebuild -project Picko.xcodeproj -scheme PickoMac -configuration Debug -derivedDataPath /private/tmp/picko-mac-derived-data build`
Expected: BUILD SUCCEEDED.

- [x] **Step 3: Run macOS unit tests**

Run: `xcodebuild -project Picko.xcodeproj -scheme PickoMac -configuration Debug -derivedDataPath /private/tmp/picko-mac-derived-data test`
Expected: tests pass.

- [x] **Step 4: Update docs**

Mark Phase 4 as completed if package tests, macOS build, and macOS tests pass. If launch verification is not available through current tooling, document that build/test verification passed and launch is the next manual step.

## Self-Review

- This plan uses desktop-native split view and inspector patterns.
- Keyboard commands are exposed through the macOS app wrapper.
- No photo contents or sensitive metadata are logged.
- Real Photos integration remains behind `PickoPhotos`; mock fixtures keep MVP desktop UI deterministic.
