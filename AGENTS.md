# Repository Guidelines

## Project Structure & Module Organization

This repository is currently docs-first. The main product spec lives in `docs/MVP-Product-Spec.md`.

Keep planning and architecture notes under `docs/`. When code is added, prefer `Sources/` for shared logic, `Tests/` for automated tests, and platform-specific app targets plus `Resources/` or asset catalogs for UI assets.

## Build, Test, and Development Commands

No build system is committed yet, so do not invent commands until a Swift Package, Xcode project, or workspace exists. When tooling arrives, document the real commands in this file, for example:

- `swift test`: run Swift Package tests, if a SwiftPM package is added.
- `xcodebuild test -scheme Picko -destination 'platform=iOS Simulator,name=iPhone 16'`: run simulator tests, if an Xcode scheme is added.
- `xcodebuild build -scheme Picko`: compile the app target.

## Coding Style & Naming Conventions

Use Swift conventions: four-space indentation, `UpperCamelCase` for types, `lowerCamelCase` for members, and descriptive enum cases. Keep domain logic small and testable.

User-facing copy should emphasize “keep” and “review” flows rather than aggressive deletion language.

## Testing Guidelines

No test framework is configured yet. When code is added, start with unit tests for shared organizing logic, then add UI tests where needed. Focus on deterministic coverage for metadata parsing, grouping, similarity thresholds, scoring, undo, and the pre-delete basket.

Name tests by behavior, for example `testSimilarAssetsAreGroupedWithinTimeWindow()`.

## Commit & Pull Request Guidelines

Follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/): `type[scope]: description`, with optional body/footer. Use `feat` for new features, `fix` for bug fixes, and `BREAKING CHANGE:` in the footer or body when needed. Common supporting types include `docs`, `refactor`, `test`, `chore`, `build`, and `ci`.

Pull requests should include a short summary, the reason for the change, test results or a note that tests are not yet available, and screenshots or screen recordings for UI changes. Link related issues or product-spec sections when relevant.

## Security & Privacy Notes

Picko handles photo-library data. Prefer local processing, avoid logging photo contents or sensitive metadata, and document any future cloud or analytics behavior before implementation.
