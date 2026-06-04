#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/prepare-phase-5-host-baseline-capture.sh [--evidence EVIDENCE_MD] [--label LABEL] [--timestamp ID] [--date YYYY-MM-DD]

Prints the guarded host macOS Photos-backed baseline capture and write-back
commands for Phase 5. This script validates that the target evidence document
already records a Passed --validate-only preflight, but it does not read Photos
libraries, build, run the benchmark, or edit evidence.
USAGE
}

evidence_path="docs/phase-5-evidence-$(date +%Y-%m-%d).md"
library_label="Non-production Mac Photos test library"
capture_timestamp="$(date +%Y%m%d-%H%M%S)"
capture_date="$(date +%Y-%m-%d)"
evidence_path_provided=0
capture_timestamp_provided=0
capture_date_provided=0

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
      evidence_path_provided=1
      shift 2
      ;;
    --label)
      if [[ $# -lt 2 ]]; then
        echo "--label requires a value." >&2
        exit 64
      fi
      library_label="$2"
      shift 2
      ;;
    --timestamp)
      if [[ $# -lt 2 ]]; then
        echo "--timestamp requires a value." >&2
        exit 64
      fi
      capture_timestamp="$2"
      capture_timestamp_provided=1
      shift 2
      ;;
    --date)
      if [[ $# -lt 2 ]]; then
        echo "--date requires YYYY-MM-DD." >&2
        exit 64
      fi
      capture_date="$2"
      capture_date_provided=1
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

if [[ "$evidence_path_provided" -eq 0 && ! -f "$evidence_path" ]]; then
  shopt -s nullglob
  evidence_candidates=(docs/phase-5-evidence-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md)
  shopt -u nullglob
  if [[ "${#evidence_candidates[@]}" -gt 0 ]]; then
    evidence_path="${evidence_candidates[$((${#evidence_candidates[@]} - 1))]}"
  fi
fi

handoff_path="docs/phase-5-evidence/phase-5-external-handoff-$capture_date.md"
if [[ ! -f "$handoff_path" ]]; then
  shopt -s nullglob
  handoff_candidates=(docs/phase-5-evidence/phase-5-external-handoff-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md)
  shopt -u nullglob
  if [[ "${#handoff_candidates[@]}" -gt 0 ]]; then
    handoff_path="${handoff_candidates[$((${#handoff_candidates[@]} - 1))]}"
    if [[ "$capture_date_provided" -eq 0 && "$handoff_path" =~ phase-5-external-handoff-([0-9]{4}-[0-9]{2}-[0-9]{2})\.md$ ]]; then
      capture_date="${BASH_REMATCH[1]}"
    fi
  fi
fi

if [[ "$capture_timestamp_provided" -eq 0 && -f "$handoff_path" ]]; then
  handoff_capture_timestamp="$(sed -n 's/^Host baseline timestamp: `\([^`][^`]*\)`$/\1/p' "$handoff_path" | head -n 1)"
  if [[ -n "$handoff_capture_timestamp" ]]; then
    capture_timestamp="$handoff_capture_timestamp"
  fi
fi

if [[ ! -f "$evidence_path" ]]; then
  echo "Missing evidence document: $evidence_path" >&2
  exit 66
fi

if [[ "$capture_timestamp" == *"TBD"* || ! "$capture_timestamp" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "--timestamp must be a concrete filename-safe value." >&2
  exit 64
fi

if [[ "$capture_date" == *"TBD"* || ! "$capture_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "--date must be a concrete YYYY-MM-DD value." >&2
  exit 64
fi

label_lower="$(printf '%s' "$library_label" | tr '[:upper:]' '[:lower:]')"
if [[ -z "$library_label" || "$library_label" == *"|"* || "$library_label" == *"TBD"* ]]; then
  echo "--label must be a concrete non-production library description." >&2
  exit 64
fi
if [[ "$label_lower" != *"non-production"* ]]; then
  echo "--label must explicitly say Non-production." >&2
  exit 64
fi
if [[ "$label_lower" == *"production personal"* \
  || "$label_lower" == *"personal photos"* \
  || "$label_lower" == *"personal library"* \
  || "$label_lower" == *"production photos"* \
  || "$label_lower" == *"production library"* ]]; then
  echo "--label must not reference a production or personal Photos library." >&2
  exit 64
fi

python3 - "$evidence_path" "$library_label" <<'PY'
import shlex
import sys
from pathlib import Path

evidence_path = Path(sys.argv[1])
expected_label = sys.argv[2]
document = evidence_path.read_text()

host_section_lines = []
in_host_section = False
for raw_line in document.splitlines():
    if raw_line.startswith("## "):
        if in_host_section:
            break
        in_host_section = raw_line.strip() == "## Host Photos-Backed Metadata Baseline"
        continue
    if in_host_section:
        host_section_lines.append(raw_line)

if not host_section_lines:
    raise SystemExit("evidence document is missing ## Host Photos-Backed Metadata Baseline")

host_section = "\n".join(host_section_lines)
if "Preflight status:" not in host_section or "Passed" not in host_section:
    raise SystemExit("host Photos baseline preflight is not recorded as Passed")

expected_counts = {"1000", "10000", "50000"}
found_preflight = False
found_label = False
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
        "--photos-library-label",
        "--validate-only",
    }.issubset(token_set):
        continue
    if not expected_counts.issubset(token_set):
        continue
    found_preflight = True
    try:
        label = tokens[tokens.index("--photos-library-label") + 1]
    except (ValueError, IndexError):
        continue
    found_label = label == expected_label

if not found_preflight:
    raise SystemExit("host Photos baseline preflight command is incomplete")
if not found_label:
    raise SystemExit("host Photos baseline preflight label does not match --label")
PY

baseline_json="docs/phase-5-evidence/metadata-baseline-photos-1000-10000-50000-$capture_timestamp.json"

cat <<GUIDE
Picko Phase 5 host Photos-backed baseline capture guide

Safety:
- Use only a non-production Mac Photos library prepared for this evidence run.
- This script only validates the recorded preflight and prints commands.
- It does not read Photos libraries, build, run benchmarks, or edit evidence.
- Do not run the capture command against a production or personal Photos library.

Capture the formal 1k/10k/50k baseline:

  scripts/capture-metadata-baseline.sh \\
    --photos \\
    --confirm-non-production-photos \\
    --photos-library-label "$library_label" \\
    --timestamp "$capture_timestamp" \\
    1000 10000 50000

Write the captured JSON back to the evidence document:

  scripts/update-phase-5-host-baseline.sh \\
    --evidence $evidence_path \\
    --baseline-json $baseline_json

Then rerun:

  scripts/report-phase-5-status.sh --evidence $evidence_path --date $capture_date --host-timestamp $capture_timestamp
GUIDE
