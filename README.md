# Picko

Picko, also known as 拾影, is an Apple-platform photo review app for quickly choosing which photos to keep from similar, duplicate, burst, screenshot, and event-based sets. The product is designed around a low-risk review flow: users keep the best items first, queue the rest in a pre-delete basket, and only then hand off deletion to the system Photos confirmation flow.

The repository currently contains a Swift Package with shared organizing logic, Photos integration adapters, iOS and macOS app shells, benchmark tooling, and Phase 5 verification scripts.

## Current Scope

- `PickoCore`: deterministic review state, similarity grouping, recommendation scoring, deletion queue logic, and shared models.
- `PickoPhotos`: Photos authorization, asset snapshot mapping, metadata indexing, thumbnail loading, and deletion request protocols.
- `PickoApp`: shared iOS-facing SwiftUI views, SwiftData review persistence, bootstrap flow, and benchmark launch configuration.
- `PickoMacApp`: macOS workbench views and model wiring for batch review.
- `Tools/PickoBenchmarks`: synthetic and Photos-backed metadata indexing benchmarks.
- `docs/`: product plan, MVP next-development plan, Phase 5 verification runbooks, and evidence templates.

## Requirements

- macOS with Xcode capable of building Swift 5.9 projects.
- iOS 17 and macOS 14 deployment targets.
- XcodeGen for regenerating `Picko.xcodeproj` after project target or build setting changes.
- A non-production Photos library or disposable simulator Photos library for Photos-backed verification.

## Quick Start

Run the shared package tests:

```sh
swift test
```

Run synthetic metadata indexing benchmarks:

```sh
swift run PickoBenchmarks
```

Generate the Xcode project after changing `project.yml`:

```sh
xcodegen generate
```

Run the iOS app tests from the generated project:

```sh
xcodebuild -project Picko.xcodeproj -scheme Picko -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

If that simulator is not installed locally, replace `iPhone 17 Pro` with an available iOS 17+ simulator name.

Run the macOS app tests:

```sh
xcodebuild -project Picko.xcodeproj -scheme PickoMac -configuration Debug test
```

## Verification

Local Phase 5 gates that do not require a real Photos state:

```sh
scripts/verify-phase-5-local.sh
```

Platform Phase 5 gates:

```sh
scripts/verify-phase-5-platform.sh
```

Current external Photos evidence status:

```sh
scripts/report-phase-5-status.sh
scripts/phase-5-external-evidence-checklist.sh
```

The Phase 5 external evidence workflow intentionally separates safe preflight helpers from commands that read a Photos library or capture screenshots. Use the documented helper scripts in `docs/Phase-5-External-Evidence-Runbook.md` before collecting host Photos-backed baselines or macOS manual evidence.

## Privacy Model

Picko handles photo-library data. The intended MVP behavior is local-first:

- core organizing logic does not import Photos directly;
- Photos deletion is requested only from the pre-delete basket and remains subject to system confirmation;
- review decisions are persisted locally with SwiftData;
- thumbnails are kept in process memory for the MVP rather than written as a Picko disk cache;
- product code should avoid broad logging that could expose photo contents or sensitive metadata.

Run the privacy logging audit before publishing changes that touch app or Photos code:

```sh
scripts/audit-privacy-logging.sh
```

## Documentation

- Product spec: `docs/MVP-Product-Spec.md`
- Development plan: `docs/MVP-Next-Development-Plan.md`
- Phase 5 verification: `docs/Phase-5-Verification.md`
- External evidence runbook: `docs/Phase-5-External-Evidence-Runbook.md`

## License

Picko is released under the MIT License. See `LICENSE` for details.
