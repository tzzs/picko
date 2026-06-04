#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/update-phase-5-ios-benchmark.sh --evidence EVIDENCE_MD --count COUNT --seconds SECONDS --rate ASSETS_PER_SECOND --path EVIDENCE_PATH

Updates one iOS Simulator Photos-backed benchmark row in a Phase 5 evidence
document. The evidence path must already exist under docs/phase-5-evidence/.

Example:
  scripts/update-phase-5-ios-benchmark.sh \
    --evidence docs/phase-5-evidence-2026-05-31.md \
    --count 10000 \
    --seconds 610.2500 \
    --rate 16.3867 \
    --path docs/phase-5-evidence/ios-metadata-benchmark/photos-10000-2026-05-31.jpg
USAGE
}

evidence_path=""
count=""
seconds=""
rate=""
artifact_path=""

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
    --count)
      if [[ $# -lt 2 ]]; then
        echo "--count requires a value." >&2
        exit 64
      fi
      count="$2"
      shift 2
      ;;
    --seconds)
      if [[ $# -lt 2 ]]; then
        echo "--seconds requires a value." >&2
        exit 64
      fi
      seconds="$2"
      shift 2
      ;;
    --rate)
      if [[ $# -lt 2 ]]; then
        echo "--rate requires a value." >&2
        exit 64
      fi
      rate="$2"
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

if [[ -z "$evidence_path" || -z "$count" || -z "$seconds" || -z "$rate" || -z "$artifact_path" ]]; then
  usage >&2
  exit 64
fi

if [[ ! -f "$evidence_path" ]]; then
  echo "Missing evidence document: $evidence_path" >&2
  exit 66
fi

if [[ "$artifact_path" != docs/phase-5-evidence/* ]]; then
  echo "--path must point under docs/phase-5-evidence/: $artifact_path" >&2
  exit 64
fi

if [[ ! -f "$artifact_path" ]]; then
  echo "Missing benchmark evidence file: $artifact_path" >&2
  exit 66
fi
if [[ ! -s "$artifact_path" ]]; then
  echo "Benchmark evidence file must not be empty: $artifact_path" >&2
  exit 64
fi
artifact_extension="${artifact_path##*.}"
artifact_extension="$(printf '%s' "$artifact_extension" | tr '[:upper:]' '[:lower:]')"
case "$artifact_extension" in
  png|jpg|jpeg|heic|mov|mp4)
    ;;
  *)
    echo "--path must point to a captured screenshot or recording evidence file." >&2
    exit 64
    ;;
esac

python3 - "$evidence_path" "$count" "$seconds" "$rate" "$artifact_path" <<'PY'
import re
import sys
from pathlib import Path

evidence_path = Path(sys.argv[1])
count_text = sys.argv[2]
seconds_text = sys.argv[3]
rate_text = sys.argv[4]
artifact_path = sys.argv[5]

try:
    count = int(count_text)
    seconds = float(seconds_text)
    rate = float(rate_text)
except ValueError as error:
    raise SystemExit(f"invalid numeric argument: {error}")

if count not in (1000, 10000, 50000):
    raise SystemExit("--count must be one of: 1000, 10000, 50000")

if seconds <= 0 or rate <= 0:
    raise SystemExit("--seconds and --rate must be positive")

count_label = f"{count:,}"
replacement = f"| {count_label} | {seconds:.4f} | {rate:.4f} | `{artifact_path}` |"
lines = evidence_path.read_text().splitlines()
row_pattern = re.compile(rf"^\|\s*{re.escape(count_label)}\s*\|")

replaced = False
in_ios_section = False
for index, line in enumerate(lines):
    if line.startswith("## "):
        in_ios_section = line.strip() == "## iOS Simulator Photos-Backed Benchmark"
        continue

    if not in_ios_section:
        continue

    if row_pattern.match(line):
        lines[index] = replacement
        replaced = True
        break

if not replaced:
    raise SystemExit(f"could not find iOS benchmark row for {count_label}")

evidence_path.write_text("\n".join(lines) + "\n")
PY

echo "Updated iOS Photos-backed benchmark row for $count assets in $evidence_path"
