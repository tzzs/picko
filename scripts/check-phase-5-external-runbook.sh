#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/check-phase-5-external-runbook.sh [RUNBOOK_MD]

Checks that the Phase 5 external evidence runbook still contains the required
operator commands, safety guardrails, and final completion condition. This is a
static document check; it does not read Photos libraries, capture screenshots,
run benchmarks, or edit evidence.
USAGE
}

runbook_path="${1:-docs/Phase-5-External-Evidence-Runbook.md}"

if [[ "$runbook_path" == "--help" || "$runbook_path" == "-h" ]]; then
  usage
  exit 0
fi

if [[ $# -gt 1 ]]; then
  usage >&2
  exit 64
fi

if [[ ! -f "$runbook_path" ]]; then
  echo "Missing Phase 5 external evidence runbook: $runbook_path" >&2
  exit 66
fi

required_patterns=(
  "Host macOS Photos-backed 1k/10k/50k metadata indexing baseline JSON"
  "macOS first Photos authorization screenshot or recording"
  "macOS pre-delete basket to Photos system delete confirmation screenshot or recording"
  "scripts/report-phase-5-status.sh"
  "--evidence docs/phase-5-evidence-2026-05-31.md"
  "--host-timestamp 20260601-photos-baseline"
  "scripts/create-phase-5-external-evidence-handoff.sh"
  "Default handoff generation:"
  "scripts/create-phase-5-external-evidence-handoff.sh \\"
  "uses the latest generated external handoff when present"
  "default handoff generation aligned with the active evidence package"
  "--output docs/phase-5-evidence/phase-5-external-handoff-2026-06-01.md"
  "scripts/check-phase-5-external-handoff.sh"
  "Explicit reproducibility:"
  "--handoff docs/phase-5-evidence/phase-5-external-handoff-2026-06-01.md"
  "completion claim boundary"
  "Next Development Plan are not complete until the host Photos-backed 1k/10k/50k"
  "baseline JSON, both macOS manual evidence artifacts, the finalizer, and the"
  "accepted by the whole-plan audit"
  "First print the active-package guarded capture commands:"
  "scripts/prepare-phase-5-host-baseline-capture.sh"
  "Explicit reproducibility:"
  "--timestamp 20260601-photos-baseline"
  "scripts/capture-metadata-baseline.sh"
  "--confirm-non-production-photos"
  "--photos-library-label \"Non-production Mac Photos test library\""
  "scripts/update-phase-5-host-baseline.sh"
  "metadata-baseline-photos-1000-10000-50000-20260601-photos-baseline.json"
  "Print the active-package macOS capture guide first:"
  "scripts/prepare-phase-5-macos-manual-capture.sh"
  "manual evidence folder is already prepared"
  "Do not recreate it unless the folder is missing"
  "scripts/prepare-phase-5-manual-evidence.sh"
  "preserves an existing README so operator status notes are not overwritten"
  "--date 2026-06-01"
  "screencapture -i docs/phase-5-evidence/manual-2026-05-31/macos/authorization/macos-first-photos-authorization-2026-06-01.png"
  "screencapture -i docs/phase-5-evidence/manual-2026-05-31/macos/delete-confirmation/macos-system-photos-delete-confirmation-2026-06-01.png"
  "scripts/check-phase-5-manual-evidence.sh docs/phase-5-evidence/manual-2026-05-31"
  "scripts/update-phase-5-manual-verification.sh"
  "scripts/record-phase-5-completeness-gates.sh"
  "Default finalization command:"
  "scripts/finalize-phase-5-evidence.sh"
  "scripts/audit-mvp-next-completion.sh"
  "Explicit finalization reproducibility:"
  "scripts/finalize-phase-5-evidence.sh"
  "scripts/audit-mvp-next-completion.sh"
  "--plan docs/MVP-Next-Development-Plan.md"
  "--product-spec docs/MVP-Product-Spec.md"
  "--verification docs/Phase-5-Verification.md"
  "--runbook docs/Phase-5-External-Evidence-Runbook.md"
  "--handoff docs/phase-5-evidence/phase-5-external-handoff-2026-06-01.md"
  "Phase 5 shell literal safety gate"
  "evidence template coverage"
  "scripts/report-phase-5-status.sh --evidence docs/phase-5-evidence-2026-05-31.md --date 2026-06-01 --host-timestamp 20260601-photos-baseline --fail-on-incomplete"
  "scripts/check-phase-5-evidence.sh docs/phase-5-evidence-2026-05-31.md"
  "Do not run the capture command against a production or personal Photos library"
  "Do not click the system Delete button"
  "press Escape or click Cancel"
  "Do not capture personal photo thumbnails"
  "does not read Photos libraries"
  "The goal is complete only when the status report"
  "the Phase 5 shell literal safety gate is"
  "the whole-plan completion audit passes"
)

status=0
for pattern in "${required_patterns[@]}"; do
  if ! rg --quiet --fixed-strings -- "$pattern" "$runbook_path"; then
    echo "Phase 5 external evidence runbook is missing: $pattern" >&2
    status=1
  fi
done

if [[ "$status" -ne 0 ]]; then
  exit "$status"
fi

echo "Phase 5 external evidence runbook check passed."
