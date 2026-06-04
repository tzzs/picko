#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/create-phase-5-evidence.sh [--baseline-json PATH] [--output PATH]
  scripts/create-phase-5-evidence.sh [--baseline-json PATH] OUTPUT

Creates a Phase 5 evidence document. When --baseline-json is provided,
the host Photos-backed metadata baseline table is filled from that JSON.
The baseline JSON must live under docs/phase-5-evidence/ and use the formal
metadata-baseline-photos-1000-10000-50000-TIMESTAMP.json filename.
USAGE
}

output="docs/phase-5-evidence-$(date +%Y-%m-%d).md"
baseline_json=""
template="docs/Phase-5-Evidence-Template.md"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --baseline-json)
      if [[ $# -lt 2 ]]; then
        echo "--baseline-json requires a path." >&2
        exit 64
      fi
      baseline_json="$2"
      shift 2
      ;;
    --output)
      if [[ $# -lt 2 ]]; then
        echo "--output requires a path." >&2
        exit 64
      fi
      output="$2"
      shift 2
      ;;
    --*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 64
      ;;
    *)
      output="$1"
      shift
      ;;
  esac
done

if [[ ! -f "$template" ]]; then
  echo "Missing evidence template: $template" >&2
  exit 66
fi

if [[ -n "$baseline_json" ]]; then
  if [[ "$baseline_json" != docs/phase-5-evidence/* ]]; then
    echo "--baseline-json must point under docs/phase-5-evidence/: $baseline_json" >&2
    exit 64
  fi

  baseline_filename="$(basename "$baseline_json")"
  if [[ ! "$baseline_filename" =~ ^metadata-baseline-photos-1000-10000-50000-[A-Za-z0-9._-]+\.json$ ]]; then
    echo "--baseline-json filename must match metadata-baseline-photos-1000-10000-50000-TIMESTAMP.json." >&2
    exit 64
  fi

  if [[ ! -f "$baseline_json" ]]; then
    echo "Missing baseline JSON: $baseline_json" >&2
    exit 66
  fi
fi

macos="$(sw_vers -productVersion 2>/dev/null || echo TBD)"
macos_build="$(sw_vers -buildVersion 2>/dev/null || echo TBD)"
xcode="$(xcodebuild -version 2>/dev/null | tr '\n' ' ' | sed 's/[[:space:]]*$//' || echo TBD)"
arch="$(uname -m 2>/dev/null || echo TBD)"
today="$(date +%Y-%m-%d)"

mkdir -p "$(dirname "$output")"

sed \
  -e "s/日期：YYYY-MM-DD/日期：${today}/" \
  -e "s/__ENV_MACOS__/${macos}, build ${macos_build}/" \
  -e "s/__ENV_XCODE__/${xcode}/" \
  -e "s/__ENV_ARCHITECTURE__/${arch}/" \
  "$template" > "$output"

if [[ -n "$baseline_json" ]]; then
  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required to fill baseline JSON into the evidence document." >&2
    exit 69
  fi

  python3 - "$output" "$baseline_json" <<'PY'
import json
import sys
from pathlib import Path

output_path = Path(sys.argv[1])
baseline_path = Path(sys.argv[2])
document = output_path.read_text()
report = json.loads(baseline_path.read_text())
mode = str(report.get("mode", ""))
if "photos" not in mode.lower() or "synthetic" in mode.lower():
    raise SystemExit(f"--baseline-json must be Photos-backed, got mode: {mode or '<missing>'}")
library_label = str(report.get("photosLibraryLabel", ""))
library_label_lower = library_label.lower()
if not library_label or "non-production" not in library_label_lower:
    raise SystemExit("--baseline-json must include photosLibraryLabel with Non-production")
sensitive_library_phrases = (
    "production personal",
    "personal photos",
    "personal library",
    "production photos",
    "production library",
)
if any(phrase in library_label_lower for phrase in sensitive_library_phrases):
    raise SystemExit("--baseline-json photosLibraryLabel must not reference production or personal Photos")

rows = {int(row["assetCount"]): row for row in report.get("rows", [])}

for count in (1000, 10000, 50000):
    row = rows.get(count)
    if row is None:
        raise SystemExit(f"--baseline-json missing assetCount row: {count}")

    seconds_value = float(row["elapsedSeconds"])
    rate_value = float(row["assetsPerSecond"])
    if seconds_value <= 0 or rate_value <= 0:
        raise SystemExit(f"--baseline-json has non-positive timing for assetCount: {count}")

    seconds = f"{seconds_value:.4f}"
    rate = f"{rate_value:.4f}"
    notes = f"{report.get('mode', 'Photos-backed')}; {library_label}"

    document = document.replace(f"__HOST_PHOTOS_{count}_SECONDS__", seconds)
    document = document.replace(f"__HOST_PHOTOS_{count}_RATE__", rate)
    document = document.replace(f"__HOST_PHOTOS_{count}_NOTES__", notes)

document = document.replace("__HOST_PHOTOS_JSON_PATH__", str(baseline_path))
output_path.write_text(document)
PY
else
  sed -i '' \
    -e "s/__HOST_PHOTOS_1000_SECONDS__/TBD/g" \
    -e "s/__HOST_PHOTOS_1000_RATE__/TBD/g" \
    -e "s/__HOST_PHOTOS_1000_NOTES__/TBD/g" \
    -e "s/__HOST_PHOTOS_10000_SECONDS__/TBD/g" \
    -e "s/__HOST_PHOTOS_10000_RATE__/TBD/g" \
    -e "s/__HOST_PHOTOS_10000_NOTES__/TBD/g" \
    -e "s/__HOST_PHOTOS_50000_SECONDS__/TBD/g" \
    -e "s/__HOST_PHOTOS_50000_RATE__/TBD/g" \
    -e "s/__HOST_PHOTOS_50000_NOTES__/TBD/g" \
    -e "s|__HOST_PHOTOS_JSON_PATH__|TBD|g" \
    "$output"
fi

echo "Created $output"
