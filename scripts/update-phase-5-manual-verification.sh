#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/update-phase-5-manual-verification.sh --evidence EVIDENCE_MD --scenario SCENARIO --platform PLATFORM --result RESULT --path EVIDENCE_PATH --notes NOTES

Updates one row in the Phase 5 Manual Photos Verification table. Use this only
after the screenshot, recording, or log artifact has been captured with
non-production Photos assets.

Known scenarios:
  First Photos authorization
  Limited library state
  Pre-delete basket triggers Photos confirmation
  Recently Deleted recovery explanation
USAGE
}

evidence_path=""
scenario=""
platform=""
result=""
artifact_path=""
notes=""

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
    --scenario)
      if [[ $# -lt 2 ]]; then
        echo "--scenario requires a value." >&2
        exit 64
      fi
      scenario="$2"
      shift 2
      ;;
    --platform)
      if [[ $# -lt 2 ]]; then
        echo "--platform requires a value." >&2
        exit 64
      fi
      platform="$2"
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
    --path)
      if [[ $# -lt 2 ]]; then
        echo "--path requires a value." >&2
        exit 64
      fi
      artifact_path="$2"
      shift 2
      ;;
    --notes)
      if [[ $# -lt 2 ]]; then
        echo "--notes requires a value." >&2
        exit 64
      fi
      notes="$2"
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

if [[ -z "$evidence_path" || -z "$scenario" || -z "$platform" || -z "$result" || -z "$artifact_path" || -z "$notes" ]]; then
  usage >&2
  exit 64
fi

if [[ ! -f "$evidence_path" ]]; then
  echo "Missing evidence document: $evidence_path" >&2
  exit 66
fi

case "$scenario" in
  "First Photos authorization"|"Limited library state"|"Pre-delete basket triggers Photos confirmation"|"Recently Deleted recovery explanation")
    ;;
  *)
    echo "--scenario must name a known Manual Photos Verification row." >&2
    exit 64
    ;;
esac

case "$platform" in
  "iOS"|"macOS"|"iOS/macOS")
    ;;
  *)
    echo "--platform must be one of: iOS, macOS, iOS/macOS." >&2
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

expected_path_fragment=""
case "$scenario|$platform" in
  "First Photos authorization|iOS")
    expected_path_fragment="/ios/authorization/"
    ;;
  "Limited library state|iOS")
    expected_path_fragment="/ios/limited-library/"
    ;;
  "Pre-delete basket triggers Photos confirmation|iOS")
    expected_path_fragment="/ios/delete-confirmation/"
    ;;
  "First Photos authorization|macOS")
    expected_path_fragment="/macos/authorization/"
    ;;
  "Pre-delete basket triggers Photos confirmation|macOS")
    expected_path_fragment="/macos/delete-confirmation/"
    ;;
  "Recently Deleted recovery explanation|iOS/macOS")
    expected_path_fragment="/"
    ;;
  *)
    echo "--scenario and --platform do not name a known Manual Photos Verification row." >&2
    exit 64
    ;;
esac

if [[ "$artifact_path" != docs/phase-5-evidence/manual-*/* ]]; then
  echo "--path must point under docs/phase-5-evidence/manual-*/: $artifact_path" >&2
  exit 64
fi

if [[ "$scenario|$platform" == "Recently Deleted recovery explanation|iOS/macOS" ]]; then
  case "$artifact_path/" in
    *"/ios/delete-confirmation/"*|*"/macos/delete-confirmation/"*|*"/privacy/"*)
      ;;
    *)
      echo "--path for $scenario / $platform must point under ios/delete-confirmation, macos/delete-confirmation, or privacy evidence." >&2
      exit 64
      ;;
  esac
elif [[ "$artifact_path/" != *"$expected_path_fragment"* ]]; then
  echo "--path for $scenario / $platform must point under $expected_path_fragment evidence." >&2
  exit 64
fi

if [[ ! -f "$artifact_path" ]]; then
  echo "Missing manual evidence artifact: $artifact_path" >&2
  exit 66
fi
if [[ ! -s "$artifact_path" ]]; then
  echo "Manual evidence artifact must not be empty: $artifact_path" >&2
  exit 64
fi

artifact_extension="${artifact_path##*.}"
artifact_extension="$(printf '%s' "$artifact_extension" | tr '[:upper:]' '[:lower:]')"
case "$artifact_extension" in
  png|jpg|jpeg|heic|mov|mp4|log|txt)
    ;;
  *)
    echo "--path must point to a captured screenshot, recording, log, or text evidence file." >&2
    exit 64
    ;;
esac

case "$artifact_extension" in
  log|txt)
    scripts/audit-runtime-privacy-logs.sh "$artifact_path" >/dev/null
    ;;
esac

notes_lower="$(printf '%s' "$notes" | tr '[:upper:]' '[:lower:]')"
if [[ "$notes_lower" == *"tbd"* || "$notes" == *"|"* || "$notes" == *$'\n'* || "$notes" == *$'\r'* ]]; then
  echo "--notes must be concrete single-line text without table separators." >&2
  exit 64
fi

if [[ "$notes_lower" == *"personal photos"* \
  || "$notes_lower" == *"personal library"* \
  || "$notes_lower" == *"production personal"* \
  || "$notes_lower" == "production photos"* \
  || "$notes_lower" == "production photos "* \
  || "$notes_lower" == *" production photos"* \
  || "$notes_lower" == "production library"* \
  || "$notes_lower" == "production library "* \
  || "$notes_lower" == *" production library"* ]]; then
  echo "--notes must not reference personal or production Photos libraries." >&2
  exit 64
fi

python3 - "$evidence_path" "$scenario" "$platform" "$result" "$artifact_path" "$notes" <<'PY'
import re
import sys
from pathlib import Path

evidence_path = Path(sys.argv[1])
scenario = sys.argv[2]
platform = sys.argv[3]
result = sys.argv[4]
artifact_path = sys.argv[5]
notes = sys.argv[6]

lines = evidence_path.read_text().splitlines()
row_aliases = {
    ("首次 Photos 授权", "iOS"): ("First Photos authorization", "iOS"),
    ("受限图库状态", "iOS"): ("Limited library state", "iOS"),
    ("Limited library 状态", "iOS"): ("Limited library state", "iOS"),
    ("预删除篮触发 Photos 确认", "iOS"): ("Pre-delete basket triggers Photos confirmation", "iOS"),
    ("首次 Photos 授权", "macOS"): ("First Photos authorization", "macOS"),
    ("预删除篮触发 Photos 确认", "macOS"): ("Pre-delete basket triggers Photos confirmation", "macOS"),
    ("“最近删除”恢复说明", "iOS/macOS"): ("Recently Deleted recovery explanation", "iOS/macOS"),
    ("\"最近删除\"恢复说明", "iOS/macOS"): ("Recently Deleted recovery explanation", "iOS/macOS"),
}
result_aliases = {
    "Passed": "通过",
    "Failed": "失败",
    "Blocked": "受阻",
}

for index, line in enumerate(lines):
    stripped = line.strip()
    if not stripped.startswith("|") or not stripped.endswith("|"):
        continue
    parts = [part.strip() for part in stripped.strip("|").split("|")]
    if len(parts) != 5:
        continue
    row_scenario, row_platform = row_aliases.get((parts[0], parts[1]), (parts[0], parts[1]))
    if row_scenario == scenario and row_platform == platform:
        display_result = result_aliases.get(result, result) if (parts[0], parts[1]) in row_aliases else result
        lines[index] = f"| {parts[0]} | {parts[1]} | {display_result} | `{artifact_path}` | {notes} |"
        evidence_path.write_text("\n".join(lines) + "\n")
        break
else:
    raise SystemExit(f"could not find Manual Photos Verification row: {scenario} / {platform}")
PY

echo "Updated Manual Photos Verification row for $scenario / $platform in $evidence_path"
