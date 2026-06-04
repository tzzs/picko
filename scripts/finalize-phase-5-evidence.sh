#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/finalize-phase-5-evidence.sh [--allow-temp] [--evidence EVIDENCE_MD] [--manual-dir DIR] [--date YYYY-MM-DD] [--host-timestamp ID] [--artifact-prefix TEXT]

Records the final Phase 5 completeness gates, then verifies that the final
evidence document has no remaining gaps. Run this only after the host
Photos-backed baseline JSON and all manual Photos evidence rows are recorded.
The finalizer also checks the Phase 5 evidence template before recording the
final gates so stale operator command templates cannot be finalized.

Options:
  --allow-temp            Allow temp evidence paths for local smoke tests only.
  --evidence EVIDENCE_MD  Phase 5 evidence document to finalize. Defaults to
                          the latest docs/phase-5-evidence-YYYY-MM-DD.md file.
  --manual-dir DIR        Manual evidence directory. Defaults to the directory
                          matching the evidence document date when present.
  --date YYYY-MM-DD       Date to use in status-report guidance. Defaults to
                          the latest external handoff's Date when present,
                          then today's date.
  --host-timestamp ID     Timestamp/id to use in generated host baseline
                          guidance. Defaults to the latest external handoff's
                          Host baseline timestamp when present, then a
                          timestamped value.
  --artifact-prefix TEXT  Prefix used in final gate evidence rows. Defaults to
                          a timestamped Terminal run string.
USAGE
}

allow_temp=0
evidence_path=""
manual_dir=""
capture_date="$(date +%Y-%m-%d)"
host_capture_timestamp="$(date +%Y%m%d-%H%M%S)"
artifact_prefix="Terminal run $(date '+%Y-%m-%d %H:%M %Z')"
capture_date_provided=0
host_capture_timestamp_provided=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --allow-temp)
      allow_temp=1
      shift
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
        echo "--manual-dir requires a path." >&2
        exit 64
      fi
      manual_dir="$2"
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
    --artifact-prefix)
      if [[ $# -lt 2 ]]; then
        echo "--artifact-prefix requires a value." >&2
        exit 64
      fi
      artifact_prefix="$2"
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

if [[ -z "$evidence_path" ]]; then
  latest_evidence=""
  while IFS= read -r candidate; do
    latest_evidence="$candidate"
    break
  done < <(find docs -maxdepth 1 -type f -name 'phase-5-evidence-*.md' -print 2>/dev/null | sort -r)
  evidence_path="$latest_evidence"
fi

if [[ ! -f "$evidence_path" ]]; then
  echo "Missing evidence document: $evidence_path" >&2
  exit 66
fi

if [[ -z "$manual_dir" && "$evidence_path" =~ ^docs/phase-5-evidence-([0-9]{4}-[0-9]{2}-[0-9]{2})\.md$ ]]; then
  evidence_date="${BASH_REMATCH[1]}"
  evidence_manual_dir="docs/phase-5-evidence/manual-$evidence_date"
  if [[ -d "$evidence_manual_dir" ]]; then
    manual_dir="$evidence_manual_dir"
  fi
fi

latest_handoff=""
if [[ "$capture_date_provided" -eq 0 || "$host_capture_timestamp_provided" -eq 0 ]]; then
  while IFS= read -r candidate; do
    latest_handoff="$candidate"
    break
  done < <(find docs/phase-5-evidence -maxdepth 1 -type f -name 'phase-5-external-handoff-*.md' -print 2>/dev/null | sort -r)
fi

if [[ "$capture_date_provided" -eq 0 && -n "$latest_handoff" ]]; then
  handoff_capture_date="$(sed -n 's/^Date: \([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\)$/\1/p' "$latest_handoff" | head -n 1)"
  if [[ -n "$handoff_capture_date" ]]; then
    capture_date="$handoff_capture_date"
  fi
fi

if [[ "$host_capture_timestamp_provided" -eq 0 && -n "$latest_handoff" ]]; then
  handoff_host_capture_timestamp="$(sed -n 's/^Host baseline timestamp: `\([^`][^`]*\)`$/\1/p' "$latest_handoff" | head -n 1)"
  if [[ -n "$handoff_host_capture_timestamp" ]]; then
    host_capture_timestamp="$handoff_host_capture_timestamp"
  fi
fi

if [[ "$capture_date" =~ (^|[[:space:]/-])TBD([[:space:]/-]|$) || "$capture_date" == *"|"* ]]; then
  echo "--date must be concrete and table-safe." >&2
  exit 64
fi

if [[ "$host_capture_timestamp" =~ (^|[[:space:]/-])TBD([[:space:]/-]|$) \
  || ! "$host_capture_timestamp" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "--host-timestamp must be a concrete filename-safe value." >&2
  exit 64
fi

if [[ "$allow_temp" -eq 1 && "$evidence_path" != /* ]]; then
  evidence_path="$PWD/$evidence_path"
fi

if [[ "$allow_temp" -eq 1 && -n "$manual_dir" && "$manual_dir" != /* ]]; then
  manual_dir="$PWD/$manual_dir"
fi

scripts/check-phase-5-evidence-cleanliness.sh docs/phase-5-evidence >/dev/null
scripts/check-phase-5-evidence-template.sh docs/Phase-5-Evidence-Template.md >/dev/null

record_command=(scripts/record-phase-5-completeness-gates.sh --evidence "$evidence_path" --artifact-prefix "$artifact_prefix")
check_command=(scripts/check-phase-5-evidence.sh)
if [[ "$allow_temp" -eq 1 ]]; then
  record_command=(scripts/record-phase-5-completeness-gates.sh --allow-temp --evidence "$evidence_path" --artifact-prefix "$artifact_prefix")
  check_command+=(--allow-temp)
fi

if [[ -n "$manual_dir" ]]; then
  record_command+=(--manual-dir "$manual_dir")
fi

"${record_command[@]}"
scripts/report-phase-5-status.sh \
  --evidence "$evidence_path" \
  --date "$capture_date" \
  --host-timestamp "$host_capture_timestamp" \
  --fail-on-incomplete
check_command+=("$evidence_path")
"${check_command[@]}"

echo "Final Phase 5 evidence verified: $evidence_path"
