#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/capture-metadata-baseline.sh [--photos --confirm-non-production-photos --photos-library-label LABEL] [--validate-only] [--output DIR] [--timestamp ID] [asset-count ...]

Examples:
  scripts/capture-metadata-baseline.sh
  scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production Mac Photos test library" 1000 10000 50000
  scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production Mac Photos test library" --validate-only 1000 10000 50000
  scripts/capture-metadata-baseline.sh --output /private/tmp/picko-evidence 1000

Writes a pure JSON benchmark report from .build/debug/PickoBenchmarks.
Use --photos only with a non-production Photos library. The explicit
--confirm-non-production-photos acknowledgement and a non-production
--photos-library-label value are required for --photos.
Use --validate-only to check the formal host Photos baseline command without
building or reading the current Mac Photos library.
Use --timestamp to make the output JSON filename deterministic for evidence
write-back; it must contain only letters, numbers, dots, underscores, or hyphens.
USAGE
}

output_dir="docs/phase-5-evidence"
use_photos=false
confirmed_non_production_photos=false
photos_library_label=""
validate_only=false
timestamp_override=""
counts=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --photos)
      use_photos=true
      shift
      ;;
    --confirm-non-production-photos)
      confirmed_non_production_photos=true
      shift
      ;;
    --validate-only)
      validate_only=true
      shift
      ;;
    --photos-library-label)
      if [[ $# -lt 2 ]]; then
        echo "--photos-library-label requires a value." >&2
        exit 64
      fi
      photos_library_label="$2"
      shift 2
      ;;
    --output)
      if [[ $# -lt 2 ]]; then
        echo "--output requires a directory." >&2
        exit 64
      fi
      output_dir="$2"
      shift 2
      ;;
    --timestamp)
      if [[ $# -lt 2 ]]; then
        echo "--timestamp requires a value." >&2
        exit 64
      fi
      timestamp_override="$2"
      shift 2
      ;;
    --*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 64
      ;;
    *)
      counts+=("$1")
      shift
      ;;
  esac
done

if [[ -n "$timestamp_override" ]]; then
  if [[ "$timestamp_override" == *"TBD"* || ! "$timestamp_override" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "--timestamp must be a concrete filename-safe value." >&2
    exit 64
  fi
fi

if [[ ${#counts[@]} -eq 0 ]]; then
  counts=(1000 10000 50000)
fi

for count in "${counts[@]}"; do
  if ! [[ "$count" =~ ^[1-9][0-9]*$ ]]; then
    echo "Asset counts must be positive integers: $count" >&2
    exit 64
  fi
done

if [[ "$use_photos" == true && "$confirmed_non_production_photos" != true ]]; then
  echo "--photos requires --confirm-non-production-photos to avoid reading a personal Photos library by mistake." >&2
  exit 64
fi

if [[ "$use_photos" == true ]]; then
  label_lower="$(printf '%s' "$photos_library_label" | tr '[:upper:]' '[:lower:]')"
  if [[ -z "$photos_library_label" || "$photos_library_label" == *"|"* || "$photos_library_label" == *"TBD"* ]]; then
    echo "--photos requires --photos-library-label with a concrete non-production library description." >&2
    exit 64
  fi
  if [[ "$label_lower" != *"non-production"* ]]; then
    echo "--photos-library-label must explicitly say Non-production." >&2
    exit 64
  fi
  if [[ "$label_lower" == *"production personal"* \
    || "$label_lower" == *"personal photos"* \
    || "$label_lower" == *"personal library"* \
    || "$label_lower" == *"production photos"* \
    || "$label_lower" == *"production library"* ]]; then
    echo "--photos-library-label must not reference a production or personal Photos library." >&2
    exit 64
  fi

  case "$output_dir" in
    docs/phase-5-evidence|docs/phase-5-evidence/*)
      ;;
    *)
      echo "--photos output must be under docs/phase-5-evidence/ so the captured JSON can be used as Phase 5 evidence." >&2
      exit 64
      ;;
  esac

  required_counts=(1000 10000 50000)
  if [[ "${#counts[@]}" -ne "${#required_counts[@]}" ]]; then
    echo "--photos baseline capture requires exactly: 1000 10000 50000" >&2
    exit 64
  fi

  for required_count in "${required_counts[@]}"; do
    found_required_count=false
    for count in "${counts[@]}"; do
      if [[ "$count" -eq "$required_count" ]]; then
        found_required_count=true
        break
      fi
    done

    if [[ "$found_required_count" != true ]]; then
      echo "--photos baseline capture requires exactly: 1000 10000 50000" >&2
      exit 64
    fi
  done
fi

if [[ "$validate_only" == true ]]; then
  if [[ "$use_photos" == true ]]; then
    echo "Photos baseline preflight passed: non-production label, formal 1k/10k/50k counts, and project evidence output directory are valid."
  else
    echo "Synthetic baseline preflight passed."
  fi
  exit 0
fi

export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-/private/tmp/picko-clang-module-cache}"
mkdir -p "$CLANG_MODULE_CACHE_PATH"

benchmark_executable="${PICKO_BENCHMARK_EXECUTABLE:-.build/debug/PickoBenchmarks}"
if [[ "$benchmark_executable" == ".build/debug/PickoBenchmarks" && ! -x "$benchmark_executable" ]]; then
  swift build --disable-sandbox --product PickoBenchmarks
fi
if [[ ! -x "$benchmark_executable" ]]; then
  echo "Missing benchmark executable: $benchmark_executable" >&2
  exit 66
fi

mkdir -p "$output_dir"

mode="synthetic"
args=(--json)
if [[ "$use_photos" == true ]]; then
  mode="photos"
  args=(--photos --json)
fi

timestamp="${timestamp_override:-$(date +%Y%m%d-%H%M%S)}"
counts_slug="$(IFS=-; echo "${counts[*]}")"
output_path="${output_dir}/metadata-baseline-${mode}-${counts_slug}-${timestamp}.json"
output_temp="${output_path}.tmp"
if [[ -e "$output_path" ]]; then
  echo "Refusing to overwrite existing baseline JSON: $output_path" >&2
  exit 73
fi
rm -f "$output_temp"
trap 'rm -f "${output_temp:-}"' ERR

"$benchmark_executable" "${args[@]}" "${counts[@]}" > "$output_temp"

if [[ "$use_photos" == true ]]; then
  python3 - "$output_temp" "$photos_library_label" <<'PY'
import json
import sys
from pathlib import Path

output_path = Path(sys.argv[1])
label = sys.argv[2]
report = json.loads(output_path.read_text())
report["photosLibraryLabel"] = label
output_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
PY
fi

python3 - "$output_temp" "$use_photos" "$photos_library_label" "${counts[@]}" <<'PY'
import json
import sys
from pathlib import Path

output_path = Path(sys.argv[1])
use_photos = sys.argv[2] == "true"
expected_label = sys.argv[3]
expected_counts = {int(value) for value in sys.argv[4:]}

try:
    report = json.loads(output_path.read_text())
except Exception as error:
    raise SystemExit(f"Benchmark output is not valid JSON: {error}")

mode = str(report.get("mode", ""))
mode_lower = mode.lower()
if use_photos:
    if "photos" not in mode_lower or "synthetic" in mode_lower:
        raise SystemExit(f"Photos baseline output must be Photos-backed, got mode: {mode or '<missing>'}")
    label = str(report.get("photosLibraryLabel", ""))
    if label != expected_label:
        raise SystemExit("Photos baseline output label does not match --photos-library-label")
else:
    if not mode or "synthetic" not in mode_lower:
        raise SystemExit(f"Synthetic baseline output must be synthetic, got mode: {mode or '<missing>'}")

rows = report.get("rows", [])
if not isinstance(rows, list) or not rows:
    raise SystemExit("Benchmark output did not contain rows")

seen_counts = set()
for row in rows:
    try:
        count = int(row["assetCount"])
        elapsed = float(row["elapsedSeconds"])
        rate = float(row["assetsPerSecond"])
    except (KeyError, TypeError, ValueError) as error:
        raise SystemExit(f"Benchmark output has invalid row: {error}")
    if elapsed <= 0 or rate <= 0:
        raise SystemExit(f"Benchmark output has non-positive timing for assetCount: {count}")
    seen_counts.add(count)

missing = sorted(expected_counts - seen_counts)
if missing:
    raise SystemExit("Benchmark output missing assetCount rows: " + ", ".join(str(count) for count in missing))
PY

mv "$output_temp" "$output_path"
echo "$output_path"
