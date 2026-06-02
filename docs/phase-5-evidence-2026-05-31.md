# Picko Phase 5 Evidence

日期：2026-05-31
工作目录：`/Users/tanzz/workspaces/picko/.worktrees/mvp-core`

## Environment

| Field | Value |
| --- | --- |
| macOS | 26.4, build 25E246 |
| Xcode | Xcode 26.5 Build version 17F42 |
| Architecture | arm64 |
| iOS Simulator | iPhone 17 Pro, iOS 26.5 Simulator, id 0CF79391-989B-47A5-B853-1422340684F8; platform/UI smoke verified; Photos-backed 1k/10k/50k benchmark evidence captured |
| Test Photos Library | Non-production iOS Simulator generated fixture on iPhone 17 Pro simulator; host Mac Photos baseline still requires a separate non-production Mac Photos library |

## Automated Gates

| Gate | Command | Result | Evidence |
| --- | --- | --- | --- |
| Local Phase 5 | `scripts/verify-phase-5-local.sh` | Passed | Terminal run 2026-05-31 20:03 CST: scripts/verify-phase-5-local.sh |
| Platform Phase 5 | `scripts/verify-phase-5-platform.sh` | Passed | Terminal run 2026-05-31 21:46 CST: scripts/verify-phase-5-platform.sh; PickoUITests 5 passed including Clear Picko State sample basket flow |
| Privacy logging | `scripts/audit-privacy-logging.sh` | Passed | Terminal run 2026-05-31 20:03 CST: scripts/audit-privacy-logging.sh via scripts/verify-phase-5-local.sh |
| Evidence completeness | `scripts/check-phase-5-evidence.sh docs/phase-5-evidence-YYYY-MM-DD.md` | TBD | TBD |
| Manual evidence completeness | `scripts/check-phase-5-manual-evidence.sh docs/phase-5-evidence/manual-2026-05-31` | TBD | `docs/phase-5-evidence/manual-2026-05-31/README.md` |

## Host Photos-Backed Metadata Baseline

Command:

```sh
scripts/prepare-phase-5-host-baseline-capture.sh
scripts/prepare-phase-5-host-baseline-capture.sh --evidence docs/phase-5-evidence-2026-05-31.md --label "Non-production Mac Photos test library" --timestamp 20260601-photos-baseline --date 2026-06-01
scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production Mac Photos test library" --validate-only 1000 10000 50000
scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production Mac Photos test library" --timestamp 20260601-photos-baseline 1000 10000 50000
```

Preflight status: Passed locally on 2026-06-01 with `--validate-only`; this checked the non-production label, formal 1k/10k/50k counts, and project evidence output directory without building or reading the current Mac Photos library.

| Asset count | Elapsed seconds | Assets / second | Notes |
| ---: | ---: | ---: | --- |
| 1,000 | TBD | TBD | TBD |
| 10,000 | TBD | TBD | TBD |
| 50,000 | TBD | TBD | TBD |

Raw JSON evidence path: `TBD`

## iOS Simulator Photos-Backed Benchmark

Fixture setup:

```sh
scripts/seed-simulator-photos-fixture.sh --count 1000 --simulator booted
scripts/seed-simulator-photos-fixture.sh --count 10000 --simulator booted
scripts/seed-simulator-photos-fixture.sh --count 50000 --simulator booted
```

App launch arguments:

```text
--picko-run-metadata-benchmark --picko-benchmark-counts=1000,10000,50000
```

| Asset count | Elapsed seconds | Assets / second | Evidence |
| ---: | ---: | ---: | --- |
| 1,000 | 58.9891 | 16.9523 | `docs/phase-5-evidence/ios-metadata-benchmark/photos-1000-2026-05-31.jpg` |
| 10,000 | 26.3797 | 379.0787 | `docs/phase-5-evidence/ios-metadata-benchmark/photos-10000-2026-05-31.jpg` |
| 50,000 | 331.2685 | 150.9350 | `docs/phase-5-evidence/ios-metadata-benchmark/photos-50000-2026-05-31.jpg` |

Screenshot or recording paths: see the 1,000 / 10,000 / 50,000 evidence rows above.

## Manual Photos Verification

Prepare evidence folders:

```sh
scripts/prepare-phase-5-manual-evidence.sh
scripts/prepare-phase-5-macos-manual-capture.sh
scripts/prepare-phase-5-macos-manual-capture.sh --manual-dir docs/phase-5-evidence/manual-2026-05-31 --evidence docs/phase-5-evidence-2026-05-31.md --date 2026-06-01
screencapture -i docs/phase-5-evidence/manual-2026-05-31/macos/authorization/macos-first-photos-authorization-2026-06-01.png
screencapture -i docs/phase-5-evidence/manual-2026-05-31/macos/delete-confirmation/macos-system-photos-delete-confirmation-2026-06-01.png
scripts/check-phase-5-manual-evidence.sh docs/phase-5-evidence/manual-2026-05-31
```

| Scenario | Platform | Result | Evidence path | Notes |
| --- | --- | --- | --- | --- |
| First Photos authorization | iOS | Passed | `docs/phase-5-evidence/manual-2026-05-31/ios/authorization/ios-first-photos-authorization-2026-05-31.jpg` | Non-production iOS Simulator Photos fixture; system first authorization dialog captured before granting limited access |
| Limited library state | iOS | Passed | `docs/phase-5-evidence/manual-2026-05-31/ios/limited-library/ios-limited-library-picker-2026-05-31.jpg` | Non-production iOS Simulator generated fixture; limited-library picker captured with one selected generated asset |
| Pre-delete basket triggers Photos confirmation | iOS | Passed | `docs/phase-5-evidence/manual-2026-05-31/ios/delete-confirmation/ios-system-photos-delete-confirmation-2026-05-31.jpg` | Non-production iOS Simulator generated fixture; Picko basket confirmation continued to system Photos delete confirmation without tapping Delete |
| First Photos authorization | macOS | TBD | TBD | TBD |
| Pre-delete basket triggers Photos confirmation | macOS | TBD | TBD | TBD |
| Recently Deleted recovery explanation | iOS/macOS | Passed | `docs/phase-5-evidence/manual-2026-05-31/ios/delete-confirmation/ios-picko-confirmation-recently-deleted-2026-05-31.jpg` | Shared Picko confirmation copy explains Photos Recently Deleted recovery before system confirmation |

## Privacy Review

| Check | Result | Evidence |
| --- | --- | --- |
| Product code has no broad logging calls | Passed | Terminal run 2026-05-31 20:03 CST: scripts/audit-privacy-logging.sh via scripts/verify-phase-5-local.sh |
| Runtime logs checked for photo contents or sensitive metadata | Passed | scripts/audit-runtime-privacy-logs.sh docs/phase-5-evidence/privacy/ios-runtime-2026-05-31.log |
| Thumbnail cache remains in process memory only | Passed | Code review: Sources/PickoPhotos/PhotoThumbnailProvider.swift, Sources/PickoApp/Views/PickoThumbnailView.swift, Tests/PickoPhotosTests/PickoPhotosTests.swift |
