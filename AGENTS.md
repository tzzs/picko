# Repository Guidelines

## Project Structure & Module Organization

The main product spec lives in `docs/MVP-Product-Spec.md`. Shared organizing logic now lives in the Swift Package under `Sources/`, with tests in `Tests/`.

Keep planning and architecture notes under `docs/`. Prefer `Sources/` for shared logic, `Tests/` for automated tests, and platform-specific app targets plus `Resources/` or asset catalogs for UI assets.

## Build, Test, and Development Commands

Current commands:

- `swift test`: run all Swift Package tests.
- `swift run PickoBenchmarks`: run the synthetic metadata indexing benchmark for 1k, 10k, and 50k asset fixtures.
- `.build/debug/PickoBenchmarks --json 1000 10000 50000`: emit machine-readable benchmark JSON after the executable has been built.
- `scripts/seed-simulator-photos-fixture.sh --count 1000 --simulator booted`: generate deterministic JPEG test assets and import them into a booted iOS Simulator Photos library for app-level Photos checks.
- `scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production Mac Photos test library" --validate-only 1000 10000 50000`: preflight the host Photos-backed baseline command without building or reading the Mac Photos library.
- `scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production Mac Photos test library" --timestamp YYYYMMDD-HHMMSS 1000 10000 50000`: formal host Photos-backed capture command printed by `scripts/prepare-phase-5-host-baseline-capture.sh`; run it only after preparing a non-production Mac Photos library.
- `scripts/audit-privacy-logging.sh`: fail if product code introduces broad logging calls that could expose photo contents or sensitive metadata.
- `scripts/verify-phase-5-local.sh`: run local Phase 5 gates that do not require real Photos state.
- `scripts/verify-phase-5-platform.sh`: run iOS simulator build/tests and macOS app target tests for Phase 5 platform verification.
- `scripts/check-phase-5-shell-literal-safety.sh`: verify Phase 5 checker pattern arrays do not contain raw backticks that Bash would execute as command substitution.
- `scripts/check-phase-5-verification-doc.sh docs/Phase-5-Verification.md`: verify the Phase 5 verification document still lists the current local evidence toolchain and safety helpers.
- `scripts/check-phase-5-evidence-template.sh docs/Phase-5-Evidence-Template.md`: verify the evidence template keeps default helper commands before explicit reproducibility commands and rejects legacy host Photos capture commands without deterministic timestamps.
- `scripts/create-phase-5-evidence.sh`: create a Phase 5 evidence file from `docs/Phase-5-Evidence-Template.md`.
- `scripts/check-phase-5-external-runbook.sh docs/Phase-5-External-Evidence-Runbook.md`: verify the remaining external evidence runbook still contains required commands and safety guardrails.
- Default Phase 5 operator commands:
  - `scripts/report-phase-5-status.sh`: print current evidence gaps using the latest active evidence package and handoff timestamp.
  - `scripts/phase-5-external-evidence-checklist.sh`: print remaining external Photos evidence commands using the active evidence package.
  - `scripts/prepare-phase-5-host-baseline-capture.sh`: print guarded host Photos capture/write-back commands without reading Photos.
  - `scripts/prepare-phase-5-macos-manual-capture.sh`: print macOS manual screenshot/write-back commands without opening Photos or Picko.
  - `scripts/create-phase-5-external-evidence-handoff.sh --output docs/phase-5-evidence/phase-5-external-handoff-YYYY-MM-DD.md`: regenerate a read-only operator handoff from the active package.
  - `scripts/check-phase-5-external-handoff.sh`: verify the latest generated handoff is still aligned with the current deterministic evidence commands.
  - `scripts/report-mvp-next-development-status.sh --fail-on-incomplete`: print the whole MVP Next plan status from local evidence; it remains non-zero while external Phase 5 evidence is missing.
  - `scripts/finalize-phase-5-evidence.sh`: after all external evidence is written back, record final completeness gates and verify the evidence document has no remaining gaps.
  - `scripts/audit-mvp-next-completion.sh`: run the read-only whole-plan completion audit; it remains non-zero while Phase 5 external evidence is missing.
- Explicit Phase 5 reproducibility commands may add `--evidence docs/phase-5-evidence-YYYY-MM-DD.md`, `--manual-dir docs/phase-5-evidence/manual-YYYY-MM-DD`, `--date YYYY-MM-DD`, and `--host-timestamp YYYYMMDD-HHMMSS` to pin a specific evidence package.
- `scripts/update-phase-5-environment.sh --evidence docs/phase-5-evidence-YYYY-MM-DD.md --field "iOS Simulator" --value "iPhone MODEL, iOS VERSION, disposable Photos library"`: record final Phase 5 environment rows after external evidence capture.
- `scripts/record-phase-5-completeness-gates.sh --evidence docs/phase-5-evidence-YYYY-MM-DD.md`: after all external evidence is captured, verify and record the final Phase 5 completeness gates.
- `xcodegen generate`: regenerate `Picko.xcodeproj` from `project.yml` after target or build setting changes.
- `xcodebuild -project Picko.xcodeproj -scheme Picko -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test`: run iOS app and UI tests.
- `xcodebuild -project Picko.xcodeproj -scheme PickoMac -configuration Debug test`: run macOS app tests.

## Coding Style & Naming Conventions

Use Swift conventions: four-space indentation, `UpperCamelCase` for types, `lowerCamelCase` for members, and descriptive enum cases. Keep domain logic small and testable.

User-facing copy should emphasize “keep” and “review” flows rather than aggressive deletion language.

## Testing Guidelines

XCTest is configured through Swift Package Manager. Start with unit tests for shared organizing logic, then add UI tests where needed. Focus on deterministic coverage for metadata parsing, grouping, similarity thresholds, scoring, undo, and the pre-delete basket.

Name tests by behavior, for example `testSimilarAssetsAreGroupedWithinTimeWindow()`.

## Commit & Pull Request Guidelines

Follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/): `type[scope]: description`, with optional body/footer. Use `feat` for new features, `fix` for bug fixes, and `BREAKING CHANGE:` in the footer or body when needed. Common supporting types include `docs`, `refactor`, `test`, `chore`, `build`, and `ci`.

Pull requests should include a short summary, the reason for the change, test results or a note that tests are not yet available, and screenshots or screen recordings for UI changes. Link related issues or product-spec sections when relevant.

## Security & Privacy Notes

Picko handles photo-library data. Prefer local processing, avoid logging photo contents or sensitive metadata, and document any future cloud or analytics behavior before implementation.
