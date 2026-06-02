#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/record-phase-5-completeness-gates.sh [--allow-temp] --evidence EVIDENCE_MD [--manual-dir DIR] [--artifact-prefix TEXT]

Runs the Phase 5 evidence and manual-evidence checkers, then records the
Evidence completeness and Manual evidence completeness gate rows as Passed.
The script verifies a temporary copy first so the two completeness rows do not
create a circular TBD dependency.

Options:
  --allow-temp            Pass --allow-temp to scripts/check-phase-5-evidence.sh.
  --evidence EVIDENCE_MD  Phase 5 evidence document to verify and update.
  --manual-dir DIR        Manual evidence directory. Defaults to the directory
                          referenced by scripts/check-phase-5-manual-evidence.sh
                          in the evidence document.
  --artifact-prefix TEXT  Prefix used in the Evidence column. Defaults to a
                          timestamped Terminal run string.
USAGE
}

allow_temp=0
evidence_path=""
manual_dir=""
artifact_prefix="Terminal run $(date '+%Y-%m-%d %H:%M %Z')"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --allow-temp)
      allow_temp=1
      shift
      ;;
    --evidence)
      if [[ $# -lt 2 ]]; then
        echo "--evidence requires a path." >&2
        exit 64
      fi
      evidence_path="$2"
      shift 2
      ;;
    --manual-dir)
      if [[ $# -lt 2 ]]; then
        echo "--manual-dir requires a path." >&2
        exit 64
      fi
      manual_dir="$2"
      shift 2
      ;;
    --artifact-prefix)
      if [[ $# -lt 2 ]]; then
        echo "--artifact-prefix requires a value." >&2
        exit 64
      fi
      artifact_prefix="$2"
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

if [[ -z "$evidence_path" ]]; then
  usage >&2
  exit 64
fi

if [[ ! -f "$evidence_path" ]]; then
  echo "Missing evidence document: $evidence_path" >&2
  exit 66
fi

artifact_prefix_lower="$(printf '%s' "$artifact_prefix" | tr '[:upper:]' '[:lower:]')"
if [[ -z "$artifact_prefix" || "$artifact_prefix_lower" == *"tbd"* || "$artifact_prefix" == *"|"* || "$artifact_prefix" == *$'\n'* || "$artifact_prefix" == *$'\r'* ]]; then
  echo "--artifact-prefix must be concrete single-line text without table separators." >&2
  exit 64
fi

if [[ "$allow_temp" -eq 1 && "$evidence_path" != /tmp/* && "$evidence_path" != /private/tmp/* ]]; then
  echo "--allow-temp is only for temporary smoke evidence under /tmp or /private/tmp." >&2
  exit 64
fi

if [[ -z "$manual_dir" ]]; then
  manual_dir="$(python3 - "$evidence_path" <<'PY'
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text()
match = re.search(r"check-phase-5-manual-evidence\.sh\s+(`?)([^`\s|)]+)\1", text)
if not match:
    raise SystemExit("could not find scripts/check-phase-5-manual-evidence.sh reference in evidence document")
print(match.group(2))
PY
)"
fi

if [[ ! -d "$manual_dir" ]]; then
  echo "Missing manual evidence directory: $manual_dir" >&2
  exit 66
fi

scripts/check-phase-5-manual-evidence.sh "$manual_dir"

temp_evidence="$(mktemp /tmp/picko-phase-5-completeness-preflight.XXXXXX)"
trap 'rm -f "$temp_evidence"' EXIT
cp "$evidence_path" "$temp_evidence"

scripts/update-phase-5-gate.sh \
  --evidence "$temp_evidence" \
  --gate "Evidence completeness" \
  --result "Passed" \
  --artifact "Preflight: scripts/check-phase-5-evidence.sh $evidence_path" >/dev/null

scripts/update-phase-5-gate.sh \
  --evidence "$temp_evidence" \
  --gate "Manual evidence completeness" \
  --result "Passed" \
  --artifact "Preflight: scripts/check-phase-5-manual-evidence.sh $manual_dir" >/dev/null

evidence_command=(scripts/check-phase-5-evidence.sh)
if [[ "$allow_temp" -eq 1 ]]; then
  evidence_command+=(--allow-temp)
fi
evidence_command+=("$temp_evidence")
"${evidence_command[@]}"

artifact_evidence_command="scripts/check-phase-5-evidence.sh"
if [[ "$allow_temp" -eq 1 ]]; then
  artifact_evidence_command+=" --allow-temp"
fi
artifact_evidence_command+=" $evidence_path"

scripts/update-phase-5-gate.sh \
  --evidence "$evidence_path" \
  --gate "Evidence completeness" \
  --result "Passed" \
  --artifact "$artifact_prefix: $artifact_evidence_command"

scripts/update-phase-5-gate.sh \
  --evidence "$evidence_path" \
  --gate "Manual evidence completeness" \
  --result "Passed" \
  --artifact "$artifact_prefix: scripts/check-phase-5-manual-evidence.sh $manual_dir"

echo "Recorded Phase 5 completeness gates in $evidence_path"
