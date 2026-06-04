#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/check-phase-5-external-handoff.sh [--handoff HANDOFF_MD] [--evidence EVIDENCE_MD] [--manual-dir DIR] [--date YYYY-MM-DD] [--host-timestamp ID]

Checks that a generated Phase 5 external evidence handoff contains the expected
read-only safety boundaries, remaining evidence categories, deterministic
date/timestamp commands, finalizer command, whole-plan audit command, and audit
coverage wording. This static check does not read Photos libraries, launch apps,
capture screenshots, run benchmarks, delete assets, or edit evidence files.
USAGE
}

handoff_path=""
evidence_path=""
manual_dir=""
capture_date="$(date +%Y-%m-%d)"
host_capture_timestamp="$(date +%Y%m%d-%H%M%S)"
evidence_path_provided=0
manual_dir_provided=0
capture_date_provided=0
host_capture_timestamp_provided=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --handoff)
      if [[ $# -lt 2 ]]; then
        echo "--handoff requires a path." >&2
        exit 64
      fi
      handoff_path="$2"
      shift 2
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
    --manual-dir)
      if [[ $# -lt 2 ]]; then
        echo "--manual-dir requires a directory." >&2
        exit 64
      fi
      manual_dir="$2"
      manual_dir_provided=1
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
    --host-timestamp)
      if [[ $# -lt 2 ]]; then
        echo "--host-timestamp requires a filename-safe value." >&2
        exit 64
      fi
      host_capture_timestamp="$2"
      host_capture_timestamp_provided=1
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

if [[ -z "$handoff_path" ]]; then
  latest_handoff=""
  while IFS= read -r candidate; do
    latest_handoff="$candidate"
    break
  done < <(find docs/phase-5-evidence -maxdepth 1 -type f -name 'phase-5-external-handoff-*.md' -print 2>/dev/null | sort -r)
  handoff_path="$latest_handoff"
fi

if [[ ! -f "$handoff_path" ]]; then
  echo "Missing handoff document: $handoff_path" >&2
  exit 66
fi

if [[ "$evidence_path_provided" -eq 0 ]]; then
  handoff_evidence_path="$(sed -n 's/^Evidence: `\([^`][^`]*\)`$/\1/p' "$handoff_path" | head -n 1)"
  if [[ -n "$handoff_evidence_path" ]]; then
    evidence_path="$handoff_evidence_path"
  fi
fi

if [[ "$manual_dir_provided" -eq 0 ]]; then
  handoff_manual_dir="$(sed -n 's/^Manual evidence directory: `\([^`][^`]*\)`$/\1/p' "$handoff_path" | head -n 1)"
  if [[ -n "$handoff_manual_dir" ]]; then
    manual_dir="$handoff_manual_dir"
  fi
fi

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

if [[ "$capture_date_provided" -eq 0 ]]; then
  handoff_capture_date="$(sed -n 's/^Date: \([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\)$/\1/p' "$handoff_path" | head -n 1)"
  if [[ -n "$handoff_capture_date" ]]; then
    capture_date="$handoff_capture_date"
  fi
fi

if [[ "$host_capture_timestamp_provided" -eq 0 ]]; then
  handoff_host_capture_timestamp="$(sed -n 's/^Host baseline timestamp: `\([^`][^`]*\)`$/\1/p' "$handoff_path" | head -n 1)"
  if [[ -n "$handoff_host_capture_timestamp" ]]; then
    host_capture_timestamp="$handoff_host_capture_timestamp"
  fi
fi

if [[ "$capture_date" == *"TBD"* || ! "$capture_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "--date must be a concrete YYYY-MM-DD value." >&2
  exit 64
fi

if [[ "$host_capture_timestamp" == *"TBD"* || ! "$host_capture_timestamp" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "--host-timestamp must be a concrete filename-safe value." >&2
  exit 64
fi

required_patterns=(
  "# Picko Phase 5 External Evidence Handoff"
  "Date: $capture_date"
  "Evidence: \`$evidence_path\`"
  "Manual evidence directory: \`$manual_dir\`"
  "Host baseline timestamp: \`$host_capture_timestamp\`"
  "Phase 5 external evidence readiness check passed."
  "Do not run host Photos capture against a production or personal Photos library."
  "Do not click the system Delete button while capturing delete-confirmation evidence."
  "After capturing delete-confirmation evidence, press Escape or click Cancel to dismiss the system confirmation without deleting assets."
  "Do not recreate an existing manual evidence folder unless it is missing; the prepare script preserves an existing README so operator status notes are not overwritten."
  "This handoff was generated by a read-only script."
  "## Completion Claim Boundary"
  "Do not mark Phase 5 or the MVP Next Development Plan complete until the host Photos-backed 1k/10k/50k baseline JSON is captured from a prepared non-production Mac Photos library and written back to the evidence document."
  "Do not mark Phase 5 or the MVP Next Development Plan complete until both macOS manual evidence artifacts are captured from a non-production Mac Photos library and written back to the evidence document."
  "If any command, screenshot, recording, or note would reference a personal or production Photos library, stop and prepare a non-production library instead."
  "The only completion proof is a passing finalizer followed by a passing whole-plan audit."
  "Host Photos-backed baseline on a non-production Mac Photos library: run scripts/prepare-phase-5-host-baseline-capture.sh. Explicit reproducibility:"
  "Manual Photos verification evidence for: First Photos authorization / macOS; Pre-delete basket triggers Photos confirmation / macOS"
  "For macOS captures, run scripts/prepare-phase-5-macos-manual-capture.sh. Explicit reproducibility:"
  "First print the active-package capture guide:"
  "scripts/prepare-phase-5-host-baseline-capture.sh --evidence $evidence_path --label \"Non-production Mac Photos test library\" --timestamp $host_capture_timestamp --date $capture_date"
  "metadata-baseline-photos-1000-10000-50000-$host_capture_timestamp.json"
  "Suggested macOS capture guide before opening the relevant system prompt:"
  "scripts/prepare-phase-5-macos-manual-capture.sh --manual-dir $manual_dir --evidence $evidence_path --date $capture_date"
  "scripts/finalize-phase-5-evidence.sh --evidence $evidence_path --date $capture_date --host-timestamp $host_capture_timestamp"
  "This audit also covers the Phase 5 shell literal safety gate"
  "evidence template coverage"
  "handoff freshness, evidence directory cleanliness"
  "final evidence completeness, and the MVP plan/spec status"
  "scripts/audit-mvp-next-completion.sh --plan docs/MVP-Next-Development-Plan.md --product-spec docs/MVP-Product-Spec.md --verification docs/Phase-5-Verification.md --runbook docs/Phase-5-External-Evidence-Runbook.md --evidence $evidence_path --manual-dir $manual_dir --handoff $handoff_path --date $capture_date --host-timestamp $host_capture_timestamp"
)

status=0
for pattern in "${required_patterns[@]}"; do
  if ! rg --quiet --fixed-strings -- "$pattern" "$handoff_path"; then
    echo "Phase 5 external evidence handoff is missing: $pattern" >&2
    status=1
  fi
done

if rg --quiet --fixed-strings "YYYYMMDD-HHMMSS" "$handoff_path"; then
  echo "Phase 5 external evidence handoff contains placeholder host timestamp." >&2
  status=1
fi

if rg --quiet --fixed-strings "ARTIFACT" "$handoff_path"; then
  echo "Phase 5 external evidence handoff contains placeholder artifact text." >&2
  status=1
fi

if rg --quiet --fixed-strings "TBD" "$handoff_path"; then
  echo "Phase 5 external evidence handoff contains TBD placeholder text." >&2
  status=1
fi

if [[ "$status" -ne 0 ]]; then
  exit "$status"
fi

echo "Phase 5 external evidence handoff check passed."
