# Picko Phase 5 Manual Evidence Checklist

Use only non-production Photos assets. Do not capture personal photos, faces,
locations, filenames, or sensitive metadata in screenshots or recordings.

## Current Evidence Status

Completed:

- iOS first Photos authorization: `ios/authorization/ios-first-photos-authorization-2026-05-31.jpg`
- iOS limited library picker: `ios/limited-library/ios-limited-library-picker-2026-05-31.jpg`
- iOS pre-delete basket to system Photos confirmation: `ios/delete-confirmation/ios-system-photos-delete-confirmation-2026-05-31.jpg`
- Picko Recently Deleted recovery copy: `ios/delete-confirmation/ios-picko-confirmation-recently-deleted-2026-05-31.jpg`
- iOS Photos-backed metadata benchmark screenshot: `ios/metadata-benchmark/ios-photos-backed-50000-benchmark-2026-05-31.jpg`
- Runtime privacy log evidence: `privacy/ios-runtime-privacy-log-2026-05-31.log`

Still required:

- macOS first Photos authorization screenshot or recording under `macos/authorization/`.
- macOS pre-delete basket triggering Photos system confirmation under `macos/delete-confirmation/`.
- Host macOS Photos-backed 1k/10k/50k baseline JSON is tracked in the main Phase 5 evidence document, not this manual folder.

## iOS Photos Authorization

- Evidence path: `ios/authorization/`
- Capture first-launch Photos permission prompt.
- Confirm Picko copy emphasizes review/keep flow.
- Confirm denial or unavailable state shows the fallback action.
- Result: `PASS`

## iOS Limited Library

- Evidence path: `ios/limited-library/`
- Select a small non-production subset.
- Confirm Picko loads only available assets.
- Confirm benchmark/error text does not expose asset metadata.
- Result: `PASS`

## iOS Delete Confirmation

- Evidence path: `ios/delete-confirmation/`
- Queue non-production assets into the pre-delete basket.
- Confirm Photos system deletion confirmation appears only after basket confirmation.
- Confirm Picko copy mentions Recently Deleted recovery.
- Result: `PASS`

## iOS Photos-Backed Metadata Benchmark

- Evidence path: `ios/metadata-benchmark/`
- Seed non-production simulator assets before launching benchmark mode.
- Launch with `--picko-run-metadata-benchmark --picko-benchmark-counts=1000,10000,50000`.
- Capture result rows or `metadata-benchmark-summary`.
- Final benchmark completeness is checked from the main Phase 5 evidence document rows; this folder is operator context.
- Result: `PASS`

## macOS Photos Authorization

- Evidence path: `macos/authorization/`
- First run `scripts/prepare-phase-5-macos-manual-capture.sh` to print the active-package capture and write-back guide.
- Explicit reproducibility: `scripts/prepare-phase-5-macos-manual-capture.sh --manual-dir docs/phase-5-evidence/manual-2026-05-31 --evidence docs/phase-5-evidence-2026-05-31.md --date 2026-06-03`.
- Capture first-launch Photos permission prompt with a non-production library.
- Confirm fallback state remains clear if access is denied.
- Suggested artifact: `macos/authorization/macos-first-photos-authorization-2026-06-03.png`.
- Optional capture command after the prompt is visible: `screencapture -i docs/phase-5-evidence/manual-2026-05-31/macos/authorization/macos-first-photos-authorization-2026-06-03.png`.
- Keep the capture tight: include the Picko permission prompt and avoid personal photo thumbnails, faces, filenames, map/location details, or Finder paths.
- Result: `PENDING`

## macOS Delete Confirmation

- Evidence path: `macos/delete-confirmation/`
- First run `scripts/prepare-phase-5-macos-manual-capture.sh` to print the active-package capture and write-back guide.
- Explicit reproducibility: `scripts/prepare-phase-5-macos-manual-capture.sh --manual-dir docs/phase-5-evidence/manual-2026-05-31 --evidence docs/phase-5-evidence-2026-05-31.md --date 2026-06-03`.
- Queue non-production assets into the pre-delete basket.
- Confirm Photos system deletion confirmation appears only after basket confirmation.
- Confirm queued ids, not arbitrary library assets, are used for deletion.
- Suggested artifact: `macos/delete-confirmation/macos-system-photos-delete-confirmation-2026-06-03.png`.
- Optional capture command after the system confirmation is visible: `screencapture -i docs/phase-5-evidence/manual-2026-05-31/macos/delete-confirmation/macos-system-photos-delete-confirmation-2026-06-03.png`.
- Do not click the system Delete button during evidence capture.
- After capture, press Escape or click Cancel to dismiss the system confirmation without deleting assets.
- Keep the capture tight: include the Picko basket confirmation or Photos system confirmation and avoid personal photo thumbnails, faces, filenames, map/location details, or Finder paths.
- Result: `PENDING`

## Runtime Privacy Review

- Evidence path: `privacy/`
- Runtime or system logs are optional supplemental artifacts once the main Phase 5 evidence document already references a passing runtime privacy audit.
- If collecting supplemental logs, run the app against non-production assets.
- Inspect any captured runtime/system logs for photo contents, filenames, locations, or sensitive metadata.
- Run `scripts/audit-runtime-privacy-logs.sh LOG_PATH` before recording any captured runtime or OS logs.
- Confirm thumbnail cache remains process-memory only and Picko does not write thumbnails to disk.
- Result: `PASS`
