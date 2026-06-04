#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/update-phase-5-privacy-review.sh --evidence EVIDENCE_MD --check CHECK_NAME --result RESULT --artifact ARTIFACT

Updates one row in the Phase 5 Privacy Review table. Use this only for privacy
checks that have concrete current evidence.

Known checks:
  Product code has no broad logging calls
  Runtime logs checked for photo contents or sensitive metadata
  Thumbnail cache remains in process memory only
USAGE
}

evidence_path=""
check_name=""
result=""
artifact=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --evidence)
      if [[ $# -lt 2 ]]; then
        echo "--evidence requires a path." >&2
        exit 64
      fi
      evidence_path="$2"
      shift 2
      ;;
    --check)
      if [[ $# -lt 2 ]]; then
        echo "--check requires a value." >&2
        exit 64
      fi
      check_name="$2"
      shift 2
      ;;
    --result)
      if [[ $# -lt 2 ]]; then
        echo "--result requires a value." >&2
        exit 64
      fi
      result="$2"
      shift 2
      ;;
    --artifact)
      if [[ $# -lt 2 ]]; then
        echo "--artifact requires a value." >&2
        exit 64
      fi
      artifact="$2"
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

if [[ -z "$evidence_path" || -z "$check_name" || -z "$result" || -z "$artifact" ]]; then
  usage >&2
  exit 64
fi

if [[ ! -f "$evidence_path" ]]; then
  echo "Missing evidence document: $evidence_path" >&2
  exit 66
fi

case "$check_name" in
  "Product code has no broad logging calls"|"Runtime logs checked for photo contents or sensitive metadata"|"Thumbnail cache remains in process memory only")
    ;;
  *)
    echo "--check must name a known Privacy Review row." >&2
    exit 64
    ;;
esac

case "$result" in
  "Passed"|"Failed"|"Blocked")
    ;;
  *)
    echo "--result must be one of: Passed, Failed, Blocked." >&2
    exit 64
    ;;
esac

artifact_lower="$(printf '%s' "$artifact" | tr '[:upper:]' '[:lower:]')"
if [[ -z "$artifact" || "$artifact_lower" == *"tbd"* || "$artifact" == *"|"* || "$artifact" == *$'\n'* || "$artifact" == *$'\r'* ]]; then
  echo "--artifact must be concrete single-line text without table separators." >&2
  exit 64
fi

python3 - "$evidence_path" "$check_name" "$result" "$artifact" <<'PY'
import re
import sys
from pathlib import Path

evidence_path = Path(sys.argv[1])
check_name = sys.argv[2]
result = sys.argv[3]
artifact = sys.argv[4]

lines = evidence_path.read_text().splitlines()
row_pattern = re.compile(rf"^\|\s*{re.escape(check_name)}\s*\|\s*[^|]+\|\s*[^|]+\|$")

for index, line in enumerate(lines):
    if row_pattern.match(line):
        lines[index] = f"| {check_name} | {result} | {artifact} |"
        evidence_path.write_text("\n".join(lines) + "\n")
        break
else:
    raise SystemExit(f"could not find Privacy Review row: {check_name}")
PY

echo "Updated Privacy Review row for $check_name in $evidence_path"
