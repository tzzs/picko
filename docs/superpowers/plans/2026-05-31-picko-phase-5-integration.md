# Picko Phase 5 Integration Verification Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Connect real Photos indexing, SwiftData review state, iOS/macOS app flows, delete confirmation, and metadata indexing performance checks into a verifiable MVP integration slice.

**Architecture:** Keep `PickoCore` independent. Use `PickoPhotos` for Photos authorization/indexing/deletion, `PickoApp` for bootstrap and persistence orchestration, and thin platform app wrappers for launch behavior. Use SwiftData for first-version local persistence.

**Tech Stack:** Swift 5.9+, SwiftUI, SwiftData, Photos, XcodeGen, XcodeBuildMCP, XCTest, iOS 17+, macOS 14+.

---

## Task 1: Real Photos Bootstrap for iOS

**Files:**
- Modify: `Sources/PickoApp/PickoAppModel.swift`
- Create: `Sources/PickoApp/PhotoLibraryBootstrapper.swift`
- Create: `Sources/PickoApp/Views/PickoLibraryBootstrapView.swift`
- Modify: `Apps/Picko/iOS/PickoApp.swift`
- Modify: `Tests/PickoAppTests/PickoAppTests.swift`
- Modify: `Tests/PickoUITests/PickoUITests.swift`

- [x] Add `PickoAppModel.loadingFromPhotoLibrary(indexer:mapper:similarityEngine:decisionStore:photoDeleter:)`.
- [x] Add `PhotoLibraryBootstrapper` to resolve Photos authorization, load snapshots, merge SwiftData decisions, and attach a `PhotoDeleting` implementation.
- [x] Add `PickoLibraryBootstrapView` with loading, loaded, and fallback states.
- [x] Switch iOS app entry from `.preview()` to `PickoLibraryBootstrapView()`.
- [x] Add a sample-library launch argument for deterministic UI smoke tests.

## Task 2: SwiftData Review State Restoration

**Files:**
- Modify: `Sources/PickoApp/Persistence/ReviewDecisionStore.swift`
- Create: `Sources/PickoApp/Persistence/ReviewSessionRecord.swift`
- Create: `Sources/PickoApp/Persistence/GroupDecisionRecord.swift`
- Create: `Sources/PickoApp/Persistence/BasketItemRecord.swift`
- Modify: `Tests/PickoAppTests/PickoAppTests.swift`

- [x] Add `ReviewDecisionStore.save(state:)`.
- [x] Add `ReviewDecisionStore.applyingSavedDecisions(to:)`.
- [x] Verify restored pre-delete decisions rebuild `DeletionQueue`.
- [x] Persist `ReviewSession` records.
- [x] Persist `SimilarGroup` decision records.
- [x] Persist ordered pre-delete basket item records.
- [x] Make `save(state:)` persist asset decisions, group decisions, and ordered basket state.
- [x] Automatically persist review state after single-asset actions, group keep actions, undo, restore, clear basket, and successful delete confirmation.
- [x] Ensure models loaded through real Photos bootstrap keep the same SwiftData store for future actions.

## Task 3: Delete Confirmation Boundary

**Files:**
- Modify: `Sources/PickoApp/PickoAppModel.swift`
- Modify: `Sources/PickoApp/Views/PreDeleteBasketView.swift`
- Modify: `Tests/PickoAppTests/PickoAppTests.swift`

- [x] Add `PickoAppModel.confirmPreDeleteBasket(deleter:)`.
- [x] Ensure only queued basket ids are sent to `PhotoDeleting`.
- [x] Clear the basket only after deletion request succeeds.
- [x] Add UI confirmation that calls Photos only from the pre-delete basket.

## Task 4: Metadata Indexing Performance Harness

**Files:**
- Create: `Sources/PickoPhotos/AssetIndexingBenchmark.swift`
- Create: `Sources/PickoPhotos/SyntheticPhotoAssetIndexer.swift`
- Create: `Tools/PickoBenchmarks/main.swift`
- Create: `scripts/seed-simulator-photos-fixture.sh`
- Create: `Sources/PickoApp/BenchmarkLaunchConfiguration.swift`
- Create: `Sources/PickoApp/Views/MetadataBenchmarkView.swift`
- Modify: `Apps/Picko/iOS/PickoApp.swift`
- Modify: `Sources/PickoPhotos/PhotosLibraryAdapter.swift`
- Modify: `Tests/PickoAppTests/PickoAppTests.swift`
- Modify: `Tests/PickoUITests/PickoUITests.swift`
- Modify: `Tests/PickoPhotosTests/PickoPhotosTests.swift`
- Create: `docs/Phase-5-Verification.md`

- [x] Add `AssetIndexingBenchmark` for repeatable metadata snapshot timing.
- [x] Verify benchmark reports fetched snapshot count.
- [x] Add a synthetic controlled fixture for repeatable 1k, 10k, and 50k metadata baseline runs.
- [x] Add a `PickoBenchmarks` executable runner for synthetic and Photos-backed baseline modes.
- [x] Add Photos fetch-limit support so host macOS 1k, 10k, and 50k Photos-backed runs are controllable after preparing a non-production Mac Photos library.
- [x] Capture synthetic controlled baseline runs for 1k, 10k, and 50k assets in `docs/Phase-5-Verification.md`.
- [x] Add a simulator fixture seeding script that generates deterministic JPEG assets and imports them with `xcrun simctl addmedia` for app-level Photos checks.
- [x] Add observable batch progress and sorted index ranges to the simulator fixture seeding script for long 10k/50k imports.
- [x] Add a checkpointed chunk importer for resumable 10k/50k simulator media imports.
- [x] Smoke-test fixture image generation without importing media into Simulator.
- [x] Add an iOS in-app metadata benchmark trigger behind launch arguments.
- [x] Verify the iOS in-app benchmark screen with a synthetic UI smoke test.
- [x] Add stable benchmark summary and result accessibility identifiers for evidence capture.
- [x] Add safe benchmark error text for Photos authorization and benchmark setup failures.
- [x] Add machine-readable JSON benchmark reports for host synthetic and Photos-backed baseline capture.
- [x] Add a baseline JSON capture script and evidence generator support so benchmark reports can fill Phase 5 evidence rows.
- [x] Add a sample pre-delete basket launch path and UI smoke test for disabled Photos confirmation without a real deleter.
- [x] Add a denied-library launch path and UI smoke test for clear fallback when Photos access is unavailable.
- [x] Add macOS denied-library launch path and bootstrap construction coverage.
- [x] Add and run static privacy logging audit for product code.
- [x] Add runtime privacy log audit script for captured manual Photos verification logs.
- [x] Add and run local Phase 5 verification script for non-Photos external-state gates.
- [x] Add Phase 5 platform verification script for Xcode iOS/macOS gates.
- [x] Run Phase 5 platform verification script end to end.
- [x] Add Phase 5 evidence template and generator for manual Photos verification records.
- [x] Smoke-test Phase 5 evidence generation with a captured baseline JSON path.
- [x] Add a manual evidence folder/checklist generator for remaining Photos and privacy verification.
- [ ] Capture host macOS Photos-backed baseline runs for 1k, 10k, and 50k assets.
- [x] Capture iOS Simulator Photos-backed benchmark screen result for 1k assets after seeding test media.
- [x] Capture iOS Simulator Photos-backed benchmark screen results for 10k and 50k assets after seeding test media.

## Task 4.5: Real Thumbnail Loading and Cache Privacy

**Files:**
- Create: `Sources/PickoPhotos/PhotoThumbnailProvider.swift`
- Modify: `Sources/PickoPhotos/PhotosLibraryAdapter.swift`
- Create: `Sources/PickoApp/Views/PickoThumbnailView.swift`
- Modify: `Sources/PickoApp/PickoAppModel.swift`
- Modify: `Sources/PickoApp/PhotoLibraryBootstrapper.swift`
- Modify: `Sources/PickoApp/Views/PickoLibraryBootstrapView.swift`
- Modify: `Sources/PickoApp/Views/SingleReviewView.swift`
- Modify: `Sources/PickoMacApp/PickoMacWorkbenchModel.swift`
- Modify: `Sources/PickoMacApp/Views/PickoMacGridReviewView.swift`
- Modify: `Tests/PickoPhotosTests/PickoPhotosTests.swift`
- Modify: `Tests/PickoAppTests/PickoAppTests.swift`

- [x] Add `PhotoThumbnailProviding` and `PhotoThumbnailRequest`.
- [x] Add `MemoryCachingPhotoThumbnailProvider` so thumbnail bytes stay in process memory and are not written to disk by Picko.
- [x] Make `PhotosLibraryAdapter` provide thumbnail data through Photos APIs.
- [x] Pass thumbnail provider through bootstrap into `PickoAppModel`.
- [x] Render thumbnail data in iOS review and macOS grid views with placeholder fallback.
- [x] Verify provider caching and view construction with tests.

## Task 5: Platform Verification

**Files:**
- Modify: `docs/MVP-Next-Development-Plan.md`
- Modify: `docs/MVP-Product-Spec.md`
- Modify: `AGENTS.md`

- [x] Run `swift test`.
- [x] Run iOS simulator build.
- [x] Run iOS `PickoTests`.
- [x] Run iOS `PickoUITests`, including synthetic in-app metadata benchmark launch, sample basket confirmation boundary, and denied-library fallback.
- [x] Run macOS `PickoMac` tests.
- [x] Run static privacy logging audit.
- [x] Run local Phase 5 verification script.
- [x] Syntax-check Phase 5 platform verification script.
- [x] Smoke-test Phase 5 evidence generator.
- [ ] Capture manual screenshots or recordings for macOS real Photos authorization and delete confirmation.
- [x] Add `docs/Phase-5-Verification.md` as the evidence log for automated baselines and pending manual Photos evidence.

## Task 6: macOS Real Library Bootstrap and Delete Confirmation

**Files:**
- Modify: `Apps/Picko/macOS/PickoMacApp.swift`
- Modify: `Sources/PickoMacApp/PickoMacWorkbenchModel.swift`
- Create: `Sources/PickoMacApp/Views/PickoMacLibraryBootstrapView.swift`
- Modify: `Sources/PickoMacApp/Views/PickoMacBasketView.swift`
- Modify: `Tests/PickoMacAppTests/PickoMacAppTests.swift`

- [x] Add a macOS bootstrap view that loads the real Photos library through `PhotoLibraryBootstrapper`.
- [x] Keep the macOS command menu pointed at the loaded workbench model.
- [x] Make macOS selected-asset actions go through `PickoAppModel` persistence methods.
- [x] Add a macOS pre-delete basket confirmation entry that calls Photos only after user confirmation.
- [x] Cover macOS bootstrap construction, persisted selected-asset actions, basket view construction, and queued-id deletion confirmation with tests.

## Remaining Phase 5 Work

- Run host macOS Photos-backed 1k/10k/50k indexing baseline on a prepared non-production Mac Photos library.
- Verify macOS first Photos authorization manually with a non-production test library.
- Verify macOS pre-delete basket system Photos confirmation manually with non-production test assets, then cancel the system delete prompt.
