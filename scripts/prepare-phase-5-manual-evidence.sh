#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/prepare-phase-5-manual-evidence.sh [--output DIR]

Creates a manual Phase 5 evidence folder with a README checklist for Photos
authorization, limited library, delete confirmation, benchmark screenshots,
and runtime privacy review. Runtime logs are optional supplemental artifacts
once the main evidence document already references a passing runtime privacy
audit. Existing README files are preserved so operator status notes are not
overwritten. Use only non-production Photos assets.
USAGE
}

output_dir="docs/phase-5-evidence/manual-$(date +%Y-%m-%d)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --output)
      if [[ $# -lt 2 ]]; then
        echo "--output requires a directory." >&2
        exit 64
      fi
      output_dir="$2"
      shift 2
      ;;
    --*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 64
      ;;
    *)
      echo "Unexpected argument: $1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

mkdir -p \
  "$output_dir/ios/authorization" \
  "$output_dir/ios/limited-library" \
  "$output_dir/ios/delete-confirmation" \
  "$output_dir/ios/metadata-benchmark" \
  "$output_dir/macos/authorization" \
  "$output_dir/macos/delete-confirmation" \
  "$output_dir/privacy"

readme="$output_dir/README.md"
if [[ ! -f "$readme" ]]; then
cat > "$readme" <<'README'
# Picko Phase 5 Manual Evidence Checklist

Use only non-production Photos assets. Do not capture personal photos, faces,
locations, filenames, or sensitive metadata in screenshots or recordings.

## iOS Photos Authorization

- Evidence path: `ios/authorization/`
- Capture first-launch Photos permission prompt.
- Confirm Picko copy emphasizes review/keep flow.
- Confirm denial or unavailable state shows the fallback action.
- Result: `PASS / FAIL / BLOCKED`

## iOS Limited Library

- Evidence path: `ios/limited-library/`
- Select a small non-production subset.
- Confirm Picko loads only available assets.
- Confirm benchmark/error text does not expose asset metadata.
- Result: `PASS / FAIL / BLOCKED`

## iOS Delete Confirmation

- Evidence path: `ios/delete-confirmation/`
- Queue non-production assets into the pre-delete basket.
- Confirm Photos system deletion confirmation appears only after basket confirmation.
- Confirm Picko copy mentions Recently Deleted recovery.
- Result: `PASS / FAIL / BLOCKED`

## iOS Photos-Backed Metadata Benchmark

- Evidence path: `ios/metadata-benchmark/`
- Seed non-production simulator assets before launching benchmark mode.
- Launch with `--picko-run-metadata-benchmark --picko-benchmark-counts=1000,10000,50000`.
- Capture result rows or `metadata-benchmark-summary`; final completeness is checked from the main Phase 5 evidence document's iOS benchmark rows.
- Result: `PASS / FAIL / BLOCKED`

## macOS Photos Authorization

- Evidence path: `macos/authorization/`
- First run `scripts/prepare-phase-5-macos-manual-capture.sh` to print the active-package capture and write-back guide.
- Explicit reproducibility: `scripts/prepare-phase-5-macos-manual-capture.sh --manual-dir MANUAL_DIR --evidence docs/phase-5-evidence-YYYY-MM-DD.md --date YYYY-MM-DD`.
- Capture first-launch Photos permission prompt with a non-production library.
- Confirm fallback state remains clear if access is denied.
- Suggested artifact: `macos/authorization/macos-first-photos-authorization-YYYY-MM-DD.png`.
- Optional capture command after the prompt is visible: `screencapture -i macos/authorization/macos-first-photos-authorization-YYYY-MM-DD.png`.
- Keep the capture tight: include the Picko permission prompt and avoid personal photo thumbnails, faces, filenames, map/location details, or Finder paths.
- Result: `PASS / FAIL / BLOCKED`

## macOS Delete Confirmation

- Evidence path: `macos/delete-confirmation/`
- First run `scripts/prepare-phase-5-macos-manual-capture.sh` to print the active-package capture and write-back guide.
- Explicit reproducibility: `scripts/prepare-phase-5-macos-manual-capture.sh --manual-dir MANUAL_DIR --evidence docs/phase-5-evidence-YYYY-MM-DD.md --date YYYY-MM-DD`.
- Queue non-production assets into the pre-delete basket.
- Confirm Photos system deletion confirmation appears only after basket confirmation.
- Confirm queued ids, not arbitrary library assets, are used for deletion.
- Suggested artifact: `macos/delete-confirmation/macos-system-photos-delete-confirmation-YYYY-MM-DD.png`.
- Optional capture command after the system confirmation is visible: `screencapture -i macos/delete-confirmation/macos-system-photos-delete-confirmation-YYYY-MM-DD.png`.
- Do not click the system Delete button during evidence capture.
- After capture, press Escape or click Cancel to dismiss the system confirmation without deleting assets.
- Keep the capture tight: include the Picko basket confirmation or Photos system confirmation and avoid personal photo thumbnails, faces, filenames, map/location details, or Finder paths.
- Result: `PASS / FAIL / BLOCKED`

## Runtime Privacy Review

- Evidence path: `privacy/`
- Runtime or system logs are optional supplemental artifacts once the main Phase 5 evidence document already references a passing runtime privacy audit.
- If collecting supplemental logs, run the app against non-production assets.
- Inspect any captured runtime/system logs for photo contents, filenames, locations, or sensitive metadata.
- Run `scripts/audit-runtime-privacy-logs.sh LOG_PATH` before recording any captured runtime or OS logs.
- Confirm thumbnail cache remains process-memory only and Picko does not write thumbnails to disk.
- Result: `PASS / FAIL / BLOCKED`
README
fi

echo "$output_dir"
