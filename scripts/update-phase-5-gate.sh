#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/update-phase-5-gate.sh --evidence EVIDENCE_MD --gate GATE_NAME --result RESULT --artifact ARTIFACT

Updates one row in the Phase 5 Automated Gates table. Use this only after the
gate command has actually been run.

Example:
  scripts/update-phase-5-gate.sh \
    --evidence docs/phase-5-evidence-2026-05-31.md \
    --gate "Local Phase 5" \
    --result "Passed" \
    --artifact "Terminal run 2026-05-31: scripts/verify-phase-5-local.sh"
USAGE
}

evidence_path=""
gate_name=""
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
    --gate)
      if [[ $# -lt 2 ]]; then
        echo "--gate requires a value." >&2
        exit 64
      fi
      gate_name="$2"
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

if [[ -z "$evidence_path" || -z "$gate_name" || -z "$result" || -z "$artifact" ]]; then
  usage >&2
  exit 64
fi

if [[ ! -f "$evidence_path" ]]; then
  echo "Missing evidence document: $evidence_path" >&2
  exit 66
fi

case "$gate_name" in
  "Local Phase 5"|"Platform Phase 5"|"Privacy logging"|"Evidence completeness"|"Manual evidence completeness")
    ;;
  *)
    echo "--gate must name a known Automated Gates row." >&2
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

python3 - "$evidence_path" "$gate_name" "$result" "$artifact" <<'PY'
import re
import sys
from pathlib import Path

evidence_path = Path(sys.argv[1])
gate_name = sys.argv[2]
result = sys.argv[3]
artifact = sys.argv[4]

text = evidence_path.read_text()
lines = text.splitlines()

row_pattern = re.compile(rf"^\|\s*{re.escape(gate_name)}\s*\|\s*(`[^`]+`|[^|]+)\|\s*[^|]+\|\s*[^|]+\|$")

for index, line in enumerate(lines):
    match = row_pattern.match(line)
    if match:
        command = match.group(1).strip()
        lines[index] = f"| {gate_name} | {command} | {result} | {artifact} |"
        evidence_path.write_text("\n".join(lines) + "\n")
        break
else:
    raise SystemExit(f"could not find Automated Gates row: {gate_name}")
PY

echo "Updated Automated Gates row for $gate_name in $evidence_path"
