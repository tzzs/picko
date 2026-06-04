#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/check-phase-5-verification-doc.sh [VERIFICATION_MD]

Checks that the Phase 5 verification document lists the current local evidence
toolchain, safety-oriented external evidence helpers, and whole-plan status
checker. This is a static document check; it does not read Photos libraries,
launch apps, capture screenshots, run benchmarks, delete assets, or edit
evidence files.
USAGE
}

verification_path="${1:-docs/Phase-5-Verification.md}"

if [[ "$verification_path" == "--help" || "$verification_path" == "-h" ]]; then
  usage
  exit 0
fi

if [[ $# -gt 1 ]]; then
  usage >&2
  exit 64
fi

if [[ ! -f "$verification_path" ]]; then
  echo "Missing Phase 5 verification document: $verification_path" >&2
  exit 66
fi

required_patterns=(
  "scripts/verify-phase-5-local.sh"
  "scripts/verify-phase-5-platform.sh"
  "scripts/audit-mvp-next-completion.sh"
  "the handoff Date, and the handoff host baseline timestamp"
  "default audit command checks the active evidence package instead of a missing same-day shell"
  "scripts/audit-privacy-logging.sh"
  "scripts/audit-runtime-privacy-logs.sh"
  "scripts/create-phase-5-evidence.sh"
  "scripts/check-phase-5-evidence-template.sh"
  "scripts/check-phase-5-evidence.sh"
  "scripts/check-phase-5-evidence-cleanliness.sh"
  "scripts/check-phase-5-manual-evidence.sh"
  "scripts/report-phase-5-status.sh"
  "host baseline timestamp recorded in the latest external handoff"
  "Date recorded in the latest external handoff, and the host baseline timestamp recorded in the latest external handoff"
  "default status output that ignores the latest handoff Date or handoff timestamp"
  "scripts/report-mvp-next-development-status.sh"
  "uses the latest existing docs/phase-5-evidence-YYYY-MM-DD.md file"
  "Date recorded in the current handoff"
  "host baseline timestamp recorded in the current handoff"
  "scripts/phase-5-external-evidence-checklist.sh"
  "Date recorded in the latest external handoff"
  "default checklist output that ignores the latest evidence package, handoff Date, or handoff timestamp"
  "scripts/create-phase-5-external-evidence-handoff.sh"
  "the handoff generator uses the latest generated external handoff when present, then falls back to the latest Phase 5 evidence document and matching manual evidence directory"
  "default handoff generation stays aligned with the active evidence package"
  "scripts/check-phase-5-external-handoff.sh"
  "When no handoff path, evidence path, manual evidence directory, date, or host timestamp is supplied, the handoff checker uses the latest generated handoff and reads the evidence path, manual evidence directory, Date, and Host baseline timestamp fields from that handoff"
  "default handoff freshness checks stay aligned with the generated active evidence package"
  "generated handoff checks that ignore the handoff Date or Host baseline timestamp"
  "default handoff checks that ignore the latest generated handoff package"
  "scripts/check-phase-5-external-runbook.sh"
  "scripts/check-phase-5-external-evidence-readiness.sh"
  "scripts/check-phase-5-shell-literal-safety.sh"
  "scripts/prepare-phase-5-host-baseline-capture.sh"
  "scripts/prepare-phase-5-host-baseline-capture.sh --evidence docs/phase-5-evidence-YYYY-MM-DD.md --label \"Non-production Mac Photos test library\" --timestamp YYYYMMDD-HHMMSS --date YYYY-MM-DD"
  "the host baseline capture helper uses the latest existing Phase 5 evidence document and the host baseline timestamp recorded in the latest external handoff"
  "default host baseline capture guide stays aligned with the active evidence package"
  "scripts/prepare-phase-5-macos-manual-capture.sh"
  "scripts/prepare-phase-5-macos-manual-capture.sh --manual-dir DIR --evidence docs/phase-5-evidence-YYYY-MM-DD.md --date YYYY-MM-DD"
  "the macOS capture helper uses the latest existing Phase 5 evidence document and the matching manual evidence directory"
  "default macOS manual capture guide stays aligned with the active evidence package"
  "scripts/finalize-phase-5-evidence.sh"
  "When no evidence path, manual directory, date, or host timestamp is supplied, the finalizer uses the latest existing Phase 5 evidence document, the matching manual evidence directory, the Date recorded in the latest external handoff, and the host baseline timestamp recorded in the latest external handoff"
  "runs the Phase 5 evidence template checker"
  "the finalizer uses the host baseline timestamp recorded in the latest external handoff"
  "default finalizer status guidance stays aligned with the active evidence package"
  "default finalizer status guidance that ignores the latest handoff Date or handoff timestamp"
  "finalizer defaults that fail to use the latest existing Phase 5 evidence document"
  "stale evidence templates"
  "scripts/record-phase-5-completeness-gates.sh"
  "scripts/update-phase-5-host-baseline.sh"
  "scripts/update-phase-5-manual-verification.sh"
  "scripts/update-phase-5-ios-benchmark.sh"
  "scripts/update-phase-5-environment.sh"
  "scripts/update-phase-5-gate.sh"
  "scripts/update-phase-5-privacy-review.sh"
  "does not read Photos libraries"
  "evidence directory cleanliness"
  "local smoke artifacts"
  "host macOS Photos-backed"
  "metadata-baseline-photos-1000-10000-50000-TIMESTAMP.json"
  "Existing baseline JSON files are never overwritten"
  "Formal capture writes to a temporary JSON path first"
  "moves the file to the final deterministic evidence path only after validation passes"
  "The evidence generator requires the same formal"
  "The evidence template checker requires default helper commands before explicit reproducibility commands"
  "Photos-backed JSON with an ad hoc filename"
  "macOS manual"
  "rejects pre-existing macOS screenshot target paths before printing capture commands"
  "SwiftData"
  "product spec SwiftData/JSON persistence boundary"
  "completion claim boundary wording"
  "cancel-after-capture warning"
  "Phase 5 and the MVP Next Development Plan must not be marked complete until the host Photos-backed 1k/10k/50k baseline JSON and both macOS manual evidence artifacts are captured from non-production Photos libraries"
  "requires a concrete --output path"
  "whole-plan audit coverage wording"
  "whole-plan audit guidance after write-back"
  "states that the whole-plan audit covers the Phase 5 shell literal safety gate"
  "complete-state summary instead of external-evidence instructions and still prints the whole-plan completion audit command"
  "default active-package command sequence"
  "explicit reproducibility"
  "default finalizer and whole-plan audit commands"
  "the finalizer followed by the whole-plan audit"
  "default finalizer and whole-plan audit commands before explicit finalization reproducibility commands"
  "Phase 5 shell literal safety checks"
  "Phase 5 shell literal safety checker"
  "runs the Phase 5 evidence directory cleanliness checker"
  "evidence template coverage"
  "local smoke artifacts in the project evidence directory"
  "empty captures cannot be recorded as benchmark evidence"
  "unsupported artifact types cannot be recorded as benchmark evidence"
  "points an iOS benchmark row at an empty or unsupported screenshot/recording artifact"
  "empty or unsupported iOS benchmark artifacts are not reported ready"
  "empty or unsupported iOS benchmark artifacts are treated as missing by the external checklist"
  "external checklist warns the operator to choose a new timestamp or archive existing evidence before capture"
  "missing host baseline JSON target collision warnings"
  "warns when date-specific macOS capture targets already exist so screenshots are not overwritten"
  "missing pre-existing macOS capture target path warnings"
  "prepare script preserves an existing README so operator status notes are not overwritten"
  "manual evidence directory already exists"
  "avoiding accidental README status-note loss"
  "empty runtime privacy logs are not reported ready"
  "empty runtime privacy logs are treated as missing by the external checklist"
  "runtime privacy logs with sensitive Photos patterns are not accepted as final evidence"
  "runtime privacy logs with sensitive Photos patterns are not reported ready"
  "runtime privacy logs with sensitive Photos patterns are treated as missing by the external checklist"
  "concrete single-line artifact text without"
  "malformed artifact text cannot corrupt the evidence table"
  "malformed gate evidence cannot corrupt the evidence table"
  "Phase 5 shell literal safety gate and evidence template coverage through the whole-plan audit"
  "Phase 5 shell literal safety gate coverage, evidence template coverage, handoff freshness, evidence directory cleanliness and final evidence completeness coverage"
  "whole-plan audit coverage wording for Phase 5 shell literal safety"
  "finalizer command, and whole-plan audit command"
  "external checklist emits concrete macOS write-back paths plus the final evidence wrapper and whole-plan audit commands"
  "rejects pre-existing host baseline JSON target paths before operator capture can collide with existing evidence"
  "rejects pre-existing macOS capture target paths before operator screenshots can overwrite evidence"
  "external checklist emits concrete macOS write-back paths plus the final evidence wrapper, whole-plan audit commands, Phase 5 shell literal safety gate coverage wording, evidence template coverage wording, and evidence directory cleanliness coverage wording"
  "evidence directory cleanliness coverage wording"
  "explicitly states that the whole-plan audit covers the Phase 5 shell literal safety gate"
  "Do not recreate an existing manual evidence folder unless it is missing"
  "both the pending-finalization and already-finalized branches"
)

status=0
for pattern in "${required_patterns[@]}"; do
  if ! rg --quiet --fixed-strings -- "$pattern" "$verification_path"; then
    echo "Phase 5 verification document is missing: $pattern" >&2
    status=1
  fi
done

if ! python3 - "$verification_path" <<'PY'
import sys
from pathlib import Path

source = Path(sys.argv[1]).read_text()
ordered_pairs = [
    (
        "scripts/prepare-phase-5-host-baseline-capture.sh\n",
        'scripts/prepare-phase-5-host-baseline-capture.sh --evidence docs/phase-5-evidence-YYYY-MM-DD.md --label "Non-production Mac Photos test library" --timestamp YYYYMMDD-HHMMSS --date YYYY-MM-DD',
        "host baseline capture helper",
    ),
    (
        "scripts/prepare-phase-5-macos-manual-capture.sh\n",
        "scripts/prepare-phase-5-macos-manual-capture.sh --manual-dir DIR --evidence docs/phase-5-evidence-YYYY-MM-DD.md --date YYYY-MM-DD",
        "macOS manual capture helper",
    ),
]

for default_command, explicit_command, label in ordered_pairs:
    default_index = source.find(default_command)
    explicit_index = source.find(explicit_command)
    if default_index == -1 or explicit_index == -1 or default_index > explicit_index:
        print(
            f"Phase 5 verification document must list the default {label} before explicit reproducibility.",
            file=sys.stderr,
        )
        raise SystemExit(1)
PY
then
  status=1
fi

if [[ "$status" -ne 0 ]]; then
  exit "$status"
fi

echo "Phase 5 verification document check passed."
