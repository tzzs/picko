#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/check-phase-5-external-evidence-readiness.sh --evidence EVIDENCE_MD --manual-dir MANUAL_DIR [--runbook RUNBOOK_MD] [--label LABEL] [--date YYYY-MM-DD] [--host-timestamp ID]

Checks whether the remaining operator-only Phase 5 external evidence package is
ready for safe capture. This is a read-only preflight: it does not read Photos
libraries, launch apps, capture screenshots, run benchmarks, or edit evidence.
USAGE
}

evidence_path=""
manual_dir=""
runbook_path="docs/Phase-5-External-Evidence-Runbook.md"
library_label="Non-production Mac Photos test library"
capture_date="$(date +%Y-%m-%d)"
host_capture_timestamp="readiness-host-smoke"

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
    --manual-dir)
      if [[ $# -lt 2 ]]; then
        echo "--manual-dir requires a directory." >&2
        exit 64
      fi
      manual_dir="$2"
      shift 2
      ;;
    --runbook)
      if [[ $# -lt 2 ]]; then
        echo "--runbook requires a path." >&2
        exit 64
      fi
      runbook_path="$2"
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
    --date)
      if [[ $# -lt 2 ]]; then
        echo "--date requires YYYY-MM-DD." >&2
        exit 64
      fi
      capture_date="$2"
      shift 2
      ;;
    --host-timestamp)
      if [[ $# -lt 2 ]]; then
        echo "--host-timestamp requires a filename-safe value." >&2
        exit 64
      fi
      host_capture_timestamp="$2"
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

if [[ -z "$evidence_path" || -z "$manual_dir" ]]; then
  usage >&2
  exit 64
fi

if [[ ! -f "$evidence_path" ]]; then
  echo "Missing evidence document: $evidence_path" >&2
  exit 66
fi

if [[ ! -d "$manual_dir" ]]; then
  echo "Missing manual evidence directory: $manual_dir" >&2
  exit 66
fi

if [[ "$host_capture_timestamp" =~ (^|[[:space:]/-])TBD([[:space:]/-]|$) \
  || ! "$host_capture_timestamp" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "--host-timestamp must be a concrete filename-safe value." >&2
  exit 64
fi

scripts/check-phase-5-shell-literal-safety.sh >/dev/null
scripts/check-phase-5-external-runbook.sh "$runbook_path" >/dev/null
scripts/check-phase-5-evidence-cleanliness.sh docs/phase-5-evidence >/dev/null
scripts/check-phase-5-manual-evidence.sh --structure-only "$manual_dir" >/dev/null

python3 - "$evidence_path" "$manual_dir" "$capture_date" "$host_capture_timestamp" <<'PY'
import re
import sys
from pathlib import Path

evidence_path = Path(sys.argv[1])
manual_dir = sys.argv[2]
capture_date = sys.argv[3]
host_capture_timestamp = sys.argv[4]
text = evidence_path.read_text()
host_section_headers = {
    "## Host Photos-Backed Metadata Baseline",
    "## Host Photos 支撑的元数据基线",
    "## 主机 Photos 支撑的元数据基线",
}

if not any(header in text for header in host_section_headers):
    raise SystemExit("evidence document is missing a host Photos-backed metadata baseline section.")

host_capture_pattern = re.compile(
    r'scripts/capture-metadata-baseline\.sh --photos --confirm-non-production-photos --photos-library-label "Non-production Mac Photos test library" --timestamp [A-Za-z0-9._-]+ 1000 10000 50000'
)
host_capture_match = host_capture_pattern.search(text)
if not host_capture_match:
    raise SystemExit("evidence document is missing a deterministic host Photos capture command with --timestamp.")

required_ordered_patterns = [
    "scripts/prepare-phase-5-host-baseline-capture.sh",
    'scripts/prepare-phase-5-host-baseline-capture.sh --evidence ',
    'scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production Mac Photos test library" --validate-only 1000 10000 50000',
    "scripts/prepare-phase-5-manual-evidence.sh",
    "scripts/prepare-phase-5-macos-manual-capture.sh",
    f"scripts/prepare-phase-5-macos-manual-capture.sh --manual-dir {manual_dir} --evidence {evidence_path} --date {capture_date}",
    f"screencapture -i {manual_dir}/macos/authorization/macos-first-photos-authorization-{capture_date}.png",
    f"screencapture -i {manual_dir}/macos/delete-confirmation/macos-system-photos-delete-confirmation-{capture_date}.png",
    f"scripts/check-phase-5-manual-evidence.sh {manual_dir}",
]

positions = []
cursor = 0
for pattern in required_ordered_patterns:
    position = text.find(pattern, cursor)
    if position == -1:
        raise SystemExit(f"evidence document is missing operator guidance: {pattern}")
    positions.append(position)
    cursor = position + len(pattern)
host_capture_position = text.find(host_capture_match.group(0), positions[2] + len(required_ordered_patterns[2]))
if host_capture_position == -1:
    raise SystemExit("evidence document deterministic host Photos capture command appears before the preflight command.")
positions.insert(3, host_capture_position)

if positions != sorted(positions):
    raise SystemExit("evidence document operator guidance is in the wrong order.")

legacy_host_capture = 'scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production Mac Photos test library" 1000 10000 50000'
if legacy_host_capture in text:
    raise SystemExit("evidence document still contains the legacy host capture command without --timestamp.")
PY

host_capture_output="$(scripts/prepare-phase-5-host-baseline-capture.sh \
  --evidence "$evidence_path" \
  --label "$library_label" \
  --timestamp "$host_capture_timestamp" \
  --date "$capture_date")"
if ! printf '%s\n' "$host_capture_output" | rg --quiet --fixed-strings "scripts/capture-metadata-baseline.sh"; then
  echo "Host baseline capture guide did not include the capture command." >&2
  exit 1
fi
if ! printf '%s\n' "$host_capture_output" | rg --quiet --fixed-strings "scripts/update-phase-5-host-baseline.sh"; then
  echo "Host baseline capture guide did not include the write-back command." >&2
  exit 1
fi
if ! printf '%s\n' "$host_capture_output" | rg --quiet --fixed-strings -- "--timestamp \"$host_capture_timestamp\""; then
  echo "Host baseline capture guide did not include a deterministic timestamp for the captured JSON." >&2
  exit 1
fi
if ! printf '%s\n' "$host_capture_output" | rg --quiet --fixed-strings -- "metadata-baseline-photos-1000-10000-50000-$host_capture_timestamp.json"; then
  echo "Host baseline capture guide did not include the deterministic write-back JSON path." >&2
  exit 1
fi
host_baseline_json_path="docs/phase-5-evidence/metadata-baseline-photos-1000-10000-50000-$host_capture_timestamp.json"
if [[ -e "$host_baseline_json_path" ]]; then
  echo "Host baseline JSON target already exists; choose a new --host-timestamp or archive the existing evidence first: $host_baseline_json_path" >&2
  exit 1
fi
if ! printf '%s\n' "$host_capture_output" | rg --quiet --fixed-strings -- "scripts/report-phase-5-status.sh --evidence $evidence_path --date $capture_date --host-timestamp $host_capture_timestamp"; then
  echo "Host baseline capture guide did not include the deterministic status rerun command." >&2
  exit 1
fi

macos_capture_output="$(scripts/prepare-phase-5-macos-manual-capture.sh \
  --validate-only \
  --manual-dir "$manual_dir" \
  --evidence "$evidence_path" \
  --date "$capture_date")"
macos_authorization_path="$manual_dir/macos/authorization/macos-first-photos-authorization-$capture_date.png"
macos_delete_confirmation_path="$manual_dir/macos/delete-confirmation/macos-system-photos-delete-confirmation-$capture_date.png"
for target_capture_path in "$macos_authorization_path" "$macos_delete_confirmation_path"; do
  if [[ -e "$target_capture_path" ]]; then
    echo "macOS capture target already exists; choose a new --date or archive the existing evidence first: $target_capture_path" >&2
    exit 1
  fi
done
if ! printf '%s\n' "$macos_capture_output" | rg --quiet --fixed-strings "$macos_authorization_path"; then
  echo "macOS capture guide did not include the authorization artifact path." >&2
  exit 1
fi
if ! printf '%s\n' "$macos_capture_output" | rg --quiet --fixed-strings "$macos_delete_confirmation_path"; then
  echo "macOS capture guide did not include the delete-confirmation artifact path." >&2
  exit 1
fi
if ! printf '%s\n' "$macos_capture_output" | rg --quiet --fixed-strings "Do not click the system Delete button"; then
  echo "macOS capture guide did not include the no-system-Delete safety warning." >&2
  exit 1
fi
if ! printf '%s\n' "$macos_capture_output" | rg --quiet --fixed-strings "press Escape or click Cancel"; then
  echo "macOS capture guide did not include the cancel-after-capture safety warning." >&2
  exit 1
fi

checklist_output="$(scripts/phase-5-external-evidence-checklist.sh \
  --evidence "$evidence_path" \
  --manual-dir "$manual_dir" \
  --date "$capture_date" \
  --host-timestamp "$host_capture_timestamp")"
if ! printf '%s\n' "$checklist_output" | rg --quiet --fixed-strings "scripts/finalize-phase-5-evidence.sh --evidence $evidence_path --date $capture_date --host-timestamp $host_capture_timestamp"; then
  echo "External evidence checklist did not include the final evidence wrapper command." >&2
  exit 1
fi
if ! printf '%s\n' "$checklist_output" | rg --quiet --fixed-strings "First print the active-package capture guide:"; then
  echo "External evidence checklist did not prioritize the default host baseline capture guide." >&2
  exit 1
fi
if ! printf '%s\n' "$checklist_output" | rg --quiet --fixed-strings "Suggested macOS capture guide before opening the relevant system prompt:"; then
  echo "External evidence checklist did not prioritize the default macOS capture guide." >&2
  exit 1
fi
if ! printf '%s\n' "$checklist_output" | rg --quiet --fixed-strings "scripts/audit-mvp-next-completion.sh --plan docs/MVP-Next-Development-Plan.md --product-spec docs/MVP-Product-Spec.md --verification docs/Phase-5-Verification.md --runbook docs/Phase-5-External-Evidence-Runbook.md --evidence $evidence_path --manual-dir $manual_dir --handoff docs/phase-5-evidence/phase-5-external-handoff-$capture_date.md --date $capture_date --host-timestamp $host_capture_timestamp"; then
  echo "External evidence checklist did not include the whole-plan completion audit command." >&2
  exit 1
fi
if ! printf '%s\n' "$checklist_output" | rg --quiet --fixed-strings "Phase 5 shell literal safety gate"; then
  echo "External evidence checklist did not mention Phase 5 shell literal safety coverage." >&2
  exit 1
fi
if ! printf '%s\n' "$checklist_output" | rg --quiet --fixed-strings "evidence directory cleanliness"; then
  echo "External evidence checklist did not mention evidence directory cleanliness coverage." >&2
  exit 1
fi
if ! printf '%s\n' "$checklist_output" | rg --quiet --fixed-strings -- "--path $macos_authorization_path"; then
  echo "External evidence checklist did not include the concrete macOS authorization write-back path." >&2
  exit 1
fi
if ! printf '%s\n' "$checklist_output" | rg --quiet --fixed-strings -- "--path $macos_delete_confirmation_path"; then
  echo "External evidence checklist did not include the concrete macOS delete-confirmation write-back path." >&2
  exit 1
fi
if printf '%s\n' "$checklist_output" | rg --quiet --fixed-strings "$manual_dir/macos/authorization/ARTIFACT"; then
  echo "External evidence checklist emitted a placeholder macOS authorization write-back path." >&2
  exit 1
fi
if printf '%s\n' "$checklist_output" | rg --quiet --fixed-strings "$manual_dir/macos/delete-confirmation/ARTIFACT"; then
  echo "External evidence checklist emitted a placeholder macOS delete-confirmation write-back path." >&2
  exit 1
fi

status_output="$(scripts/report-phase-5-status.sh \
  --evidence "$evidence_path" \
  --date "$capture_date" \
  --host-timestamp "$host_capture_timestamp")"
for expected_text in \
  "Host Photos-backed baseline on a non-production Mac Photos library" \
  "Manual Photos verification evidence for: First Photos authorization / macOS; Pre-delete basket triggers Photos confirmation / macOS" \
  "scripts/prepare-phase-5-host-baseline-capture.sh" \
  "scripts/prepare-phase-5-macos-manual-capture.sh"
do
  if ! printf '%s\n' "$status_output" | rg --quiet --fixed-strings "$expected_text"; then
    echo "Status report is missing expected external evidence readiness text: $expected_text" >&2
    exit 1
  fi
done

unexpected_status_patterns=(
  "Create the final Phase 5 evidence document"
  "Record concrete iOS Simulator"
  "Record concrete non-production Photos library"
  "iOS Simulator Photos-backed in-app benchmark evidence"
  "Runtime privacy log evidence"
)

for unexpected_text in "${unexpected_status_patterns[@]}"; do
  if printf '%s\n' "$status_output" | rg --quiet --fixed-strings "$unexpected_text"; then
    echo "Status report has an unexpected remaining evidence category: $unexpected_text" >&2
    exit 1
  fi
done

echo "Phase 5 external evidence readiness check passed."
