#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/record-runtime-privacy-evidence.sh --evidence EVIDENCE_MD --log LOG_PATH [--log LOG_PATH ...]

Audits captured runtime or system logs, then marks the runtime Privacy Review
row as Passed only when the audit succeeds. Use only logs captured from
non-production Photos test runs.
USAGE
}

evidence_path=""
logs=()

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
    --log)
      if [[ $# -lt 2 ]]; then
        echo "--log requires a path." >&2
        exit 64
      fi
      logs+=("$2")
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

if [[ -z "$evidence_path" || "${#logs[@]}" -eq 0 ]]; then
  usage >&2
  exit 64
fi

if [[ ! -f "$evidence_path" ]]; then
  echo "Missing evidence document: $evidence_path" >&2
  exit 66
fi

for log_path in "${logs[@]}"; do
  if [[ "$log_path" != docs/phase-5-evidence/privacy/* ]]; then
    echo "--log must point under docs/phase-5-evidence/privacy/: $log_path" >&2
    exit 64
  fi
done

scripts/audit-runtime-privacy-logs.sh "${logs[@]}"

artifact="scripts/audit-runtime-privacy-logs.sh ${logs[*]}"
scripts/update-phase-5-privacy-review.sh \
  --evidence "$evidence_path" \
  --check "Runtime logs checked for photo contents or sensitive metadata" \
  --result "Passed" \
  --artifact "$artifact"

echo "Recorded runtime privacy evidence in $evidence_path"
