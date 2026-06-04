#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/create-phase-5-external-evidence-handoff.sh --output HANDOFF_MD [--evidence EVIDENCE_MD] [--manual-dir DIR] [--runbook RUNBOOK_MD] [--label LABEL] [--date YYYY-MM-DD] [--host-timestamp ID]

Creates a read-only Phase 5 external evidence handoff document from the current
status report and external evidence checklist. This script validates readiness,
but it does not read Photos libraries, launch apps, capture screenshots, run
benchmarks, delete assets, or edit the evidence document.

When evidence, manual directory, date, or host timestamp are omitted, the script
uses the latest generated external handoff when present, then falls back to the
latest Phase 5 evidence document and matching manual evidence directory.
USAGE
}

evidence_path="docs/phase-5-evidence-$(date +%Y-%m-%d).md"
manual_dir=""
runbook_path="docs/Phase-5-External-Evidence-Runbook.md"
library_label="Non-production Mac Photos test library"
capture_date="$(date +%Y-%m-%d)"
host_capture_timestamp="$(date +%Y%m%d-%H%M%S)"
output_path=""
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
    --output)
      if [[ $# -lt 2 ]]; then
        echo "--output requires a path." >&2
        exit 64
      fi
      output_path="$2"
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

if [[ -z "$output_path" ]]; then
  usage >&2
  exit 64
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

if [[ -f "$handoff_path" ]]; then
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
  if [[ "$host_capture_timestamp_provided" -eq 0 ]]; then
    handoff_capture_timestamp="$(sed -n 's/^Host baseline timestamp: `\([^`][^`]*\)`$/\1/p' "$handoff_path" | head -n 1)"
    if [[ -n "$handoff_capture_timestamp" ]]; then
      host_capture_timestamp="$handoff_capture_timestamp"
    fi
  fi
fi

if [[ "$evidence_path_provided" -eq 0 && ! -f "$evidence_path" ]]; then
  shopt -s nullglob
  evidence_candidates=(docs/phase-5-evidence-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md)
  shopt -u nullglob
  if [[ "${#evidence_candidates[@]}" -gt 0 ]]; then
    evidence_path="${evidence_candidates[$((${#evidence_candidates[@]} - 1))]}"
  fi
fi

if [[ "$manual_dir_provided" -eq 0 && -z "$manual_dir" ]]; then
  if [[ "$evidence_path" =~ phase-5-evidence-([0-9]{4}-[0-9]{2}-[0-9]{2})\.md$ ]]; then
    manual_dir="docs/phase-5-evidence/manual-${BASH_REMATCH[1]}"
  else
    manual_dir="docs/phase-5-evidence/manual-$capture_date"
  fi
fi

if [[ "$manual_dir_provided" -eq 0 && ! -d "$manual_dir" ]]; then
  shopt -s nullglob
  manual_candidates=(docs/phase-5-evidence/manual-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
  shopt -u nullglob
  if [[ "${#manual_candidates[@]}" -gt 0 ]]; then
    manual_dir="${manual_candidates[$((${#manual_candidates[@]} - 1))]}"
  fi
fi

if [[ ! -f "$evidence_path" ]]; then
  echo "Missing evidence document: $evidence_path" >&2
  exit 66
fi

if [[ ! -d "$manual_dir" ]]; then
  echo "Missing manual evidence directory: $manual_dir" >&2
  exit 66
fi

if [[ ! -f "$runbook_path" ]]; then
  echo "Missing runbook: $runbook_path" >&2
  exit 66
fi

if [[ "$capture_date" == *"TBD"* || ! "$capture_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "--date must be a concrete YYYY-MM-DD value." >&2
  exit 64
fi

if [[ "$host_capture_timestamp" == *"TBD"* || ! "$host_capture_timestamp" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "--host-timestamp must be a concrete filename-safe value." >&2
  exit 64
fi

if [[ "$output_path" == *"TBD"* || "$output_path" == *"|"* ]]; then
  echo "--output must be concrete and table-safe." >&2
  exit 64
fi

case "$output_path" in
  docs/phase-5-evidence/*.md|/tmp/*.md|/private/tmp/*.md)
    ;;
  *)
    echo "--output must be a Markdown file under docs/phase-5-evidence/ or a temp smoke path." >&2
    exit 64
    ;;
esac
mkdir -p "$(dirname "$output_path")"

readiness_output="$(scripts/check-phase-5-external-evidence-readiness.sh \
  --evidence "$evidence_path" \
  --manual-dir "$manual_dir" \
  --runbook "$runbook_path" \
  --label "$library_label" \
  --date "$capture_date" \
  --host-timestamp "$host_capture_timestamp")"

status_output="$(scripts/report-phase-5-status.sh \
  --evidence "$evidence_path" \
  --date "$capture_date" \
  --host-timestamp "$host_capture_timestamp")"

checklist_output="$(scripts/phase-5-external-evidence-checklist.sh \
  --evidence "$evidence_path" \
  --manual-dir "$manual_dir" \
  --date "$capture_date" \
  --host-timestamp "$host_capture_timestamp")"

render() {
  cat <<MARKDOWN
# Picko Phase 5 External Evidence Handoff

Date: $capture_date

Worktree: \`$PWD\`
Evidence: \`$evidence_path\`
Manual evidence directory: \`$manual_dir\`
Runbook: \`$runbook_path\`
Host baseline timestamp: \`$host_capture_timestamp\`
Photos library label: \`$library_label\`

## Safety Boundary

- Use only a prepared non-production Mac Photos library.
- Do not run host Photos capture against a production or personal Photos library.
- Do not click the system Delete button while capturing delete-confirmation evidence.
- After capturing delete-confirmation evidence, press Escape or click Cancel to dismiss the system confirmation without deleting assets.
- Do not capture personal photo thumbnails, faces, filenames, Finder paths, map/location details, or sensitive metadata.
- Do not recreate an existing manual evidence folder unless it is missing; the prepare script preserves an existing README so operator status notes are not overwritten.
- This handoff was generated by a read-only script. It did not read Photos libraries, launch apps, capture screenshots, run benchmarks, delete assets, or edit the evidence document.

## Completion Claim Boundary

- Do not mark Phase 5 or the MVP Next Development Plan complete until the host Photos-backed 1k/10k/50k baseline JSON is captured from a prepared non-production Mac Photos library and written back to the evidence document.
- Do not mark Phase 5 or the MVP Next Development Plan complete until both macOS manual evidence artifacts are captured from a non-production Mac Photos library and written back to the evidence document.
- If any command, screenshot, recording, or note would reference a personal or production Photos library, stop and prepare a non-production library instead.
- The only completion proof is a passing finalizer followed by a passing whole-plan audit.

## Readiness Result

\`\`\`text
$readiness_output
\`\`\`

## Current Status

\`\`\`text
$status_output
\`\`\`

## Operator Checklist

\`\`\`text
$checklist_output
\`\`\`

## Final Whole-Plan Audit

This audit also covers the Phase 5 shell literal safety gate, evidence template
coverage, runbook coverage, handoff freshness, evidence directory cleanliness,
final evidence completeness, and the MVP plan/spec status.

\`\`\`sh
scripts/audit-mvp-next-completion.sh --plan docs/MVP-Next-Development-Plan.md --product-spec docs/MVP-Product-Spec.md --verification docs/Phase-5-Verification.md --runbook docs/Phase-5-External-Evidence-Runbook.md --evidence $evidence_path --manual-dir $manual_dir --handoff $output_path --date $capture_date --host-timestamp $host_capture_timestamp
\`\`\`
MARKDOWN
}

render > "$output_path"
echo "Created Phase 5 external evidence handoff: $output_path"
