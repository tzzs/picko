#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/check-phase-5-evidence-cleanliness.sh [EVIDENCE_DIR]

Checks that the project Phase 5 evidence directory does not contain local smoke
artifacts created by verification scripts. This is read-only and does not read
Photos libraries, launch apps, capture screenshots, run benchmarks, delete
assets, or edit evidence files.
USAGE
}

evidence_dir="${1:-docs/phase-5-evidence}"

if [[ "$evidence_dir" == "--help" || "$evidence_dir" == "-h" ]]; then
  usage
  exit 0
fi

if [[ $# -gt 1 ]]; then
  usage >&2
  exit 64
fi

if [[ ! -d "$evidence_dir" ]]; then
  echo "Missing Phase 5 evidence directory: $evidence_dir" >&2
  exit 66
fi

status=0
while IFS= read -r artifact; do
  echo "Phase 5 evidence directory contains local smoke artifact: $artifact" >&2
  status=1
done < <(
  find "$evidence_dir" \
    -mindepth 1 \
    \( \
      -name '*smoke*' \
      -o -name '*.tmp' \
      -o -path "$evidence_dir/manual-smoke*" \
      -o -path "$evidence_dir/manual-status-*" \
      -o -path "$evidence_dir/status-ios-smoke*" \
    \) \
    -print 2>/dev/null | sort
)

if [[ "$status" -ne 0 ]]; then
  exit "$status"
fi

echo "Phase 5 evidence directory cleanliness check passed."
