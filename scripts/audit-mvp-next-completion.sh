#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/audit-mvp-next-completion.sh [--plan PLAN_MD] [--product-spec SPEC_MD] [--verification VERIFICATION_MD] [--runbook RUNBOOK_MD] [--evidence EVIDENCE_MD] [--manual-dir DIR] [--handoff HANDOFF_MD] [--date YYYY-MM-DD] [--host-timestamp ID]

Runs a read-only completion audit for the MVP Next Development Plan. The audit
combines static document checks, external evidence handoff/readiness checks,
Phase 5 evidence directory cleanliness, Phase 5 status, final evidence
completeness, and whole-plan status.

This script does not read Photos libraries, launch apps, capture screenshots,
run benchmarks, delete assets, or edit evidence files.
USAGE
}

plan_path="docs/MVP-Next-Development-Plan.md"
product_spec_path="docs/MVP-Product-Spec.md"
verification_path="docs/Phase-5-Verification.md"
runbook_path="docs/Phase-5-External-Evidence-Runbook.md"
evidence_path="docs/phase-5-evidence-$(date +%Y-%m-%d).md"
manual_dir="docs/phase-5-evidence/manual-$(date +%Y-%m-%d)"
handoff_path=""
capture_date="$(date +%Y-%m-%d)"
host_capture_timestamp="$(date +%Y%m%d-%H%M%S)"
evidence_path_provided=0
manual_dir_provided=0
handoff_path_provided=0
capture_date_provided=0
host_capture_timestamp_provided=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --plan)
      if [[ $# -lt 2 ]]; then
        echo "--plan requires a path." >&2
        exit 64
      fi
      plan_path="$2"
      shift 2
      ;;
    --product-spec)
      if [[ $# -lt 2 ]]; then
        echo "--product-spec requires a path." >&2
        exit 64
      fi
      product_spec_path="$2"
      shift 2
      ;;
    --verification)
      if [[ $# -lt 2 ]]; then
        echo "--verification requires a path." >&2
        exit 64
      fi
      verification_path="$2"
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
    --handoff)
      if [[ $# -lt 2 ]]; then
        echo "--handoff requires a path." >&2
        exit 64
      fi
      handoff_path="$2"
      handoff_path_provided=1
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

if [[ "$evidence_path_provided" -eq 0 && ! -f "$evidence_path" ]]; then
  latest_evidence=""
  while IFS= read -r candidate; do
    latest_evidence="$candidate"
    break
  done < <(find docs -maxdepth 1 -type f -name 'phase-5-evidence-*.md' -print 2>/dev/null | sort -r)
  if [[ -n "$latest_evidence" ]]; then
    evidence_path="$latest_evidence"
  fi
fi

if [[ "$manual_dir_provided" -eq 0 && "$evidence_path" =~ ^docs/phase-5-evidence-([0-9]{4}-[0-9]{2}-[0-9]{2})\.md$ ]]; then
  evidence_date="${BASH_REMATCH[1]}"
  evidence_manual_dir="docs/phase-5-evidence/manual-$evidence_date"
  if [[ -d "$evidence_manual_dir" ]]; then
    manual_dir="$evidence_manual_dir"
  fi
fi

if [[ -z "$handoff_path" ]]; then
  handoff_path="docs/phase-5-evidence/phase-5-external-handoff-$capture_date.md"
fi

if [[ "$handoff_path_provided" -eq 0 && ! -f "$handoff_path" ]]; then
  latest_handoff=""
  while IFS= read -r candidate; do
    latest_handoff="$candidate"
    break
  done < <(find docs/phase-5-evidence -maxdepth 1 -type f -name 'phase-5-external-handoff-*.md' -print 2>/dev/null | sort -r)
  if [[ -n "$latest_handoff" ]]; then
    handoff_path="$latest_handoff"
  fi
fi

if [[ "$capture_date_provided" -eq 0 && -f "$handoff_path" ]]; then
  handoff_capture_date="$(sed -n 's/^Date: \([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\)$/\1/p' "$handoff_path" | head -n 1)"
  if [[ -n "$handoff_capture_date" ]]; then
    capture_date="$handoff_capture_date"
  fi
fi

if [[ "$capture_date" == *"TBD"* || ! "$capture_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "--date must be a concrete YYYY-MM-DD value." >&2
  exit 64
fi

if [[ "$host_capture_timestamp_provided" -eq 0 && -f "$handoff_path" ]]; then
  handoff_host_capture_timestamp="$(sed -n 's/^Host baseline timestamp: `\([^`][^`]*\)`$/\1/p' "$handoff_path" | head -n 1)"
  if [[ -n "$handoff_host_capture_timestamp" ]]; then
    host_capture_timestamp="$handoff_host_capture_timestamp"
  fi
fi

if [[ "$host_capture_timestamp" == *"TBD"* || ! "$host_capture_timestamp" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "--host-timestamp must be a concrete filename-safe value." >&2
  exit 64
fi

status=0

run_gate() {
  local label="$1"
  shift

  printf '\n== %s ==\n' "$label"
  if "$@"; then
    printf '[ready] %s\n' "$label"
  else
    printf '[missing] %s\n' "$label"
    status=1
  fi
}

printf 'Picko MVP Next Completion Audit\n'
printf 'Worktree: %s\n' "$(pwd)"
printf 'Plan: %s\n' "$plan_path"
printf 'Product spec: %s\n' "$product_spec_path"
printf 'Evidence: %s\n' "$evidence_path"
printf 'Manual evidence: %s\n' "$manual_dir"
printf 'External handoff: %s\n' "$handoff_path"
printf 'Date: %s\n' "$capture_date"
printf 'Host timestamp: %s\n' "$host_capture_timestamp"

run_gate "Verification document coverage" \
  scripts/check-phase-5-verification-doc.sh "$verification_path"

run_gate "Evidence template coverage" \
  scripts/check-phase-5-evidence-template.sh docs/Phase-5-Evidence-Template.md

run_gate "Phase 5 shell literal safety" \
  scripts/check-phase-5-shell-literal-safety.sh

run_gate "External evidence runbook coverage" \
  scripts/check-phase-5-external-runbook.sh "$runbook_path"

run_gate "External evidence readiness" \
  scripts/check-phase-5-external-evidence-readiness.sh \
    --evidence "$evidence_path" \
    --manual-dir "$manual_dir" \
    --runbook "$runbook_path" \
    --date "$capture_date" \
    --host-timestamp "$host_capture_timestamp"

run_gate "External evidence handoff freshness" \
  scripts/check-phase-5-external-handoff.sh \
    --handoff "$handoff_path" \
    --evidence "$evidence_path" \
    --manual-dir "$manual_dir" \
    --date "$capture_date" \
    --host-timestamp "$host_capture_timestamp"

run_gate "Phase 5 evidence directory cleanliness" \
  scripts/check-phase-5-evidence-cleanliness.sh docs/phase-5-evidence

run_gate "Phase 5 status has no remaining gaps" \
  scripts/report-phase-5-status.sh \
    --evidence "$evidence_path" \
    --date "$capture_date" \
    --host-timestamp "$host_capture_timestamp" \
    --fail-on-incomplete

run_gate "Final Phase 5 evidence completeness" \
  scripts/check-phase-5-evidence.sh "$evidence_path"

run_gate "MVP Next whole-plan completion" \
  scripts/report-mvp-next-development-status.sh \
    --plan "$plan_path" \
    --product-spec "$product_spec_path" \
    --evidence "$evidence_path" \
    --manual-dir "$manual_dir" \
    --handoff "$handoff_path" \
    --date "$capture_date" \
    --host-timestamp "$host_capture_timestamp" \
    --fail-on-incomplete

if [[ "$status" -eq 0 ]]; then
  printf '\nMVP Next completion audit passed.\n'
else
  printf '\nMVP Next completion audit failed; continue the missing evidence or implementation work above.\n'
fi

exit "$status"
