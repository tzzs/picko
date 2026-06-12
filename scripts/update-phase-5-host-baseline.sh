#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/update-phase-5-host-baseline.sh --evidence EVIDENCE_MD --baseline-json BASELINE_JSON

Updates the Host Photos-Backed Metadata Baseline table in an existing Phase 5
evidence document. The evidence document must record the complete host Photos
--validate-only preflight command. The baseline JSON must be Photos-backed,
must not be synthetic, must use the formal deterministic capture filename, and
must include positive 1k, 10k, and 50k rows.
USAGE
}

evidence_path=""
baseline_json=""

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
    --baseline-json)
      if [[ $# -lt 2 ]]; then
        echo "--baseline-json requires a path." >&2
        exit 64
      fi
      baseline_json="$2"
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

if [[ -z "$evidence_path" || -z "$baseline_json" ]]; then
  usage >&2
  exit 64
fi

if [[ ! -f "$evidence_path" ]]; then
  echo "Missing evidence document: $evidence_path" >&2
  exit 66
fi

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

python3 - "$evidence_path" "$baseline_json" <<'PY'
import json
import re
import shlex
import sys
from pathlib import Path

evidence_path = Path(sys.argv[1])
baseline_path = Path(sys.argv[2])
document = evidence_path.read_text()
report = json.loads(baseline_path.read_text())
host_section_headers = {
    "## Host Photos-Backed Metadata Baseline",
    "## Host Photos 支撑的元数据基线",
    "## 主机 Photos 支撑的元数据基线",
}
sensitive_library_phrases = (
    "production personal",
    "personal photos",
    "personal library",
    "production photos",
    "production library",
)

host_section_lines = []
in_host_section = False
for raw_line in document.splitlines():
    if raw_line.startswith("## "):
        if in_host_section:
            break
        in_host_section = raw_line.strip() in host_section_headers
        continue
    if in_host_section:
        host_section_lines.append(raw_line)

if not host_section_lines:
    raise SystemExit("evidence document must record the complete host Photos --validate-only preflight command")

host_section = "\n".join(host_section_lines)
has_passed_preflight = (
    ("Preflight status:" in host_section and "Passed" in host_section)
    or ("预检状态：" in host_section and "通过" in host_section)
)
if not has_passed_preflight:
    raise SystemExit("evidence document must record a Passed host Photos --validate-only preflight status")

for line in host_section_lines:
    if "capture-metadata-baseline.sh" not in line or "--validate-only" not in line:
        continue
    try:
        tokens = shlex.split(line.replace("\\", " "))
    except ValueError:
        continue
    token_set = set(tokens)
    if not {
        "--photos",
        "--confirm-non-production-photos",
        "--validate-only",
        "1000",
        "10000",
        "50000",
    }.issubset(token_set):
        continue
    if "--photos-library-label" not in token_set:
        continue
    try:
        preflight_label = tokens[tokens.index("--photos-library-label") + 1]
    except (ValueError, IndexError):
        continue
    preflight_label_lower = preflight_label.lower()
    if "non-production" not in preflight_label_lower:
        continue
    if any(phrase in preflight_label_lower for phrase in sensitive_library_phrases):
        raise SystemExit("evidence document host Photos preflight label must not reference production or personal Photos")
    break
else:
    raise SystemExit("evidence document must record the complete host Photos --validate-only preflight command")

mode = str(report.get("mode", ""))
if "photos" not in mode.lower() or "synthetic" in mode.lower():
    raise SystemExit(f"--baseline-json must be Photos-backed, got mode: {mode or '<missing>'}")
library_label = str(report.get("photosLibraryLabel", ""))
library_label_lower = library_label.lower()
if not library_label or "non-production" not in library_label_lower:
    raise SystemExit("--baseline-json must include photosLibraryLabel with Non-production")
if any(phrase in library_label_lower for phrase in sensitive_library_phrases):
    raise SystemExit("--baseline-json photosLibraryLabel must not reference production or personal Photos")

rows = {}
for row in report.get("rows", []):
    try:
        count = int(row["assetCount"])
        elapsed = float(row["elapsedSeconds"])
        rate = float(row["assetsPerSecond"])
    except (KeyError, TypeError, ValueError) as error:
        raise SystemExit(f"--baseline-json has invalid row: {error}")
    if elapsed <= 0 or rate <= 0:
        raise SystemExit(f"--baseline-json has non-positive timing for assetCount: {count}")
    rows[count] = (elapsed, rate)

for count in (1000, 10000, 50000):
    if count not in rows:
        raise SystemExit(f"--baseline-json missing assetCount row: {count}")

lines = document.splitlines()
mode_text = f"{mode or 'Photos-backed'}; {library_label}"
for count in (1000, 10000, 50000):
    count_label = f"{count:,}"
    elapsed, rate = rows[count]
    replacement = f"| {count_label} | {elapsed:.4f} | {rate:.4f} | {mode_text} |"
    row_pattern = re.compile(rf"^\|\s*{re.escape(count_label)}\s*\|")
    for index, line in enumerate(lines):
        if row_pattern.match(line):
            lines[index] = replacement
            break
    else:
        raise SystemExit(f"could not find host baseline row for {count_label}")

for index, line in enumerate(lines):
    if line.startswith("Raw JSON evidence path:") or line.startswith("原始 JSON 证据路径："):
        if line.startswith("原始 JSON 证据路径"):
            lines[index] = f"原始 JSON 证据路径：`{baseline_path}`"
        else:
            lines[index] = f"Raw JSON evidence path: `{baseline_path}`"
        break
else:
    raise SystemExit("could not find raw JSON evidence path row")

evidence_path.write_text("\n".join(lines) + "\n")
PY

echo "Updated Host Photos-backed baseline in $evidence_path"
