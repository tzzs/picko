#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/update-phase-5-environment.sh --evidence EVIDENCE_MD --field FIELD --value VALUE

Updates one row in the Phase 5 Environment table after the environment has
been confirmed during external evidence capture.

Known fields:
  iOS Simulator
  Test Photos Library
USAGE
}

evidence_path=""
field_name=""
field_value=""

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
    --field)
      if [[ $# -lt 2 ]]; then
        echo "--field requires a value." >&2
        exit 64
      fi
      field_name="$2"
      shift 2
      ;;
    --value)
      if [[ $# -lt 2 ]]; then
        echo "--value requires a value." >&2
        exit 64
      fi
      field_value="$2"
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

if [[ -z "$evidence_path" || -z "$field_name" || -z "$field_value" ]]; then
  usage >&2
  exit 64
fi

if [[ ! -f "$evidence_path" ]]; then
  echo "Missing evidence document: $evidence_path" >&2
  exit 66
fi

case "$field_name" in
  "iOS Simulator"|"Test Photos Library")
    ;;
  *)
    echo "--field must be one of: iOS Simulator, Test Photos Library." >&2
    exit 64
    ;;
esac

if [[ "$field_value" == *"|"* || "$field_value" == *$'\n'* ]]; then
  echo "--value must not contain table separators or newlines." >&2
  exit 64
fi

if [[ "$field_value" =~ (^|[[:space:]/-])TBD([[:space:]/-]|$) ]]; then
  echo "--value must be concrete, not TBD." >&2
  exit 64
fi

if [[ "$field_name" == "Test Photos Library" ]]; then
  lower_value="$(printf '%s' "$field_value" | tr '[:upper:]' '[:lower:]')"
  if [[ "$lower_value" != *"non-production"* ]]; then
    echo "--value for Test Photos Library must explicitly say Non-production." >&2
    exit 64
  fi
  if [[ "$lower_value" == *"production personal"* \
    || "$lower_value" == *"personal photos"* \
    || "$lower_value" == *"personal library"* \
    || "$lower_value" == *"production photos"* \
    || "$lower_value" == *"production library"* ]]; then
    echo "--value for Test Photos Library must not reference a production or personal Photos library." >&2
    exit 64
  fi
fi

python3 - "$evidence_path" "$field_name" "$field_value" <<'PY'
import re
import sys
from pathlib import Path

evidence_path = Path(sys.argv[1])
field_name = sys.argv[2]
field_value = sys.argv[3]

lines = evidence_path.read_text().splitlines()
row_pattern = re.compile(rf"^\|\s*{re.escape(field_name)}\s*\|\s*[^|]+\|$")

for index, line in enumerate(lines):
    if row_pattern.match(line):
        lines[index] = f"| {field_name} | {field_value} |"
        evidence_path.write_text("\n".join(lines) + "\n")
        break
else:
    raise SystemExit(f"could not find Environment row: {field_name}")
PY

echo "Updated Environment row for $field_name in $evidence_path"
