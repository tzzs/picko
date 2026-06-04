#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/check-phase-5-manual-evidence.sh [--structure-only] MANUAL_EVIDENCE_DIR

Checks the Phase 5 manual evidence folder created by
prepare-phase-5-manual-evidence.sh. Structure-only mode validates the skeleton;
default mode also requires required manual interaction scenario directories to
contain captured screenshot, recording, log, or text evidence. The
ios/metadata-benchmark folder is optional operator context because final iOS
benchmark completeness is checked from the main Phase 5 evidence document.
USAGE
}

structure_only=0
if [[ "${1:-}" == "--structure-only" ]]; then
  structure_only=1
  shift
fi

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 64
fi

manual_dir="$1"
if [[ "$manual_dir" == "--help" || "$manual_dir" == "-h" ]]; then
  usage
  exit 0
fi

if [[ ! -d "$manual_dir" ]]; then
  echo "Missing manual evidence directory: $manual_dir" >&2
  exit 66
fi

required_dirs=(
  "ios/authorization"
  "ios/limited-library"
  "ios/delete-confirmation"
  "ios/metadata-benchmark"
  "macos/authorization"
  "macos/delete-confirmation"
  "privacy"
)

required_readme_patterns=(
  "Use only non-production Photos assets"
  "iOS Photos Authorization"
  "iOS Limited Library"
  "iOS Delete Confirmation"
  "iOS Photos-Backed Metadata Benchmark"
  "macOS Photos Authorization"
  "macOS Delete Confirmation"
  "scripts/prepare-phase-5-macos-manual-capture.sh"
  "Explicit reproducibility"
  "macos-first-photos-authorization"
  "macos-system-photos-delete-confirmation"
  "screencapture -i"
  "Do not click the system Delete button"
  "press Escape or click Cancel"
  "avoid personal photo thumbnails"
  "Runtime Privacy Review"
)

required_capture_dirs=(
  "ios/authorization"
  "ios/limited-library"
  "ios/delete-confirmation"
  "macos/authorization"
  "macos/delete-confirmation"
  "privacy"
)

is_supported_artifact() {
  local lower_path
  lower_path="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "$lower_path" in
    *.png|*.jpg|*.jpeg|*.heic|*.mov|*.mp4|*.log|*.txt)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

requires_text_audit() {
  local lower_path
  lower_path="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "$lower_path" in
    *.log|*.txt)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

status=0
readme="$manual_dir/README.md"
if [[ ! -f "$readme" ]]; then
  echo "Missing manual evidence README: $readme" >&2
  status=1
else
  for pattern in "${required_readme_patterns[@]}"; do
    if ! rg --quiet --fixed-strings "$pattern" "$readme"; then
      echo "Manual evidence README is missing: $pattern" >&2
      status=1
    fi
  done
fi

for relative_dir in "${required_dirs[@]}"; do
  evidence_dir="$manual_dir/$relative_dir"
  if [[ ! -d "$evidence_dir" ]]; then
    echo "Missing manual evidence scenario directory: $evidence_dir" >&2
    status=1
  fi
done

if [[ "$structure_only" -eq 0 ]]; then
  for relative_dir in "${required_capture_dirs[@]}"; do
    evidence_dir="$manual_dir/$relative_dir"
    if [[ ! -d "$evidence_dir" ]]; then
      continue
    fi
    has_artifact=0
    while IFS= read -r artifact_path; do
      [[ -z "$artifact_path" ]] && continue
      has_artifact=1
      if [[ ! -s "$artifact_path" ]]; then
        echo "Manual evidence artifact must not be empty: $artifact_path" >&2
        status=1
        continue
      fi
      if ! is_supported_artifact "$artifact_path"; then
        echo "Manual evidence artifact file type is not supported: $artifact_path" >&2
        status=1
        continue
      fi
      if requires_text_audit "$artifact_path"; then
        if ! scripts/audit-runtime-privacy-logs.sh "$artifact_path" >/dev/null; then
          echo "Manual evidence text/log artifact failed privacy audit: $artifact_path" >&2
          status=1
        fi
      fi
    done < <(find "$evidence_dir" -type f ! -name '.DS_Store' ! -name '.gitkeep' -print)

    if [[ "$has_artifact" -eq 0 ]]; then
      echo "Missing captured manual evidence file in: $evidence_dir" >&2
      status=1
    fi
  done
fi

if [[ "$status" -ne 0 ]]; then
  exit "$status"
fi

if [[ "$structure_only" -eq 1 ]]; then
  echo "Phase 5 manual evidence structure check passed."
else
  echo "Phase 5 manual evidence check passed."
fi
