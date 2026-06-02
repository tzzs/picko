#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/check-phase-5-evidence-template.sh [TEMPLATE_MD]

Checks that the Phase 5 evidence template keeps the guarded default helper
commands before explicit Photos capture commands. This is a static document
check; it does not read Photos libraries, launch apps, capture screenshots,
run benchmarks, delete assets, or edit evidence files.
USAGE
}

template_path="${1:-docs/Phase-5-Evidence-Template.md}"

if [[ "$template_path" == "--help" || "$template_path" == "-h" ]]; then
  usage
  exit 0
fi

if [[ $# -gt 1 ]]; then
  usage >&2
  exit 64
fi

if [[ ! -f "$template_path" ]]; then
  echo "Missing Phase 5 evidence template: $template_path" >&2
  exit 66
fi

required_patterns=(
  "## Host Photos-Backed Metadata Baseline"
  "scripts/prepare-phase-5-host-baseline-capture.sh"
  "scripts/prepare-phase-5-host-baseline-capture.sh --evidence docs/phase-5-evidence-YYYY-MM-DD.md --label \"Non-production Mac Photos test library\" --timestamp YYYYMMDD-HHMMSS --date YYYY-MM-DD"
  "scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label \"Non-production Mac Photos test library\" --validate-only 1000 10000 50000"
  "scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label \"Non-production Mac Photos test library\" --timestamp YYYYMMDD-HHMMSS 1000 10000 50000"
  "Preflight status: TBD"
  "Raw JSON evidence path: \`__HOST_PHOTOS_JSON_PATH__\`"
  "## Manual Photos Verification"
  "scripts/prepare-phase-5-manual-evidence.sh"
  "scripts/prepare-phase-5-macos-manual-capture.sh"
  "scripts/prepare-phase-5-macos-manual-capture.sh --manual-dir docs/phase-5-evidence/manual-YYYY-MM-DD --evidence docs/phase-5-evidence-YYYY-MM-DD.md --date YYYY-MM-DD"
  "scripts/check-phase-5-manual-evidence.sh docs/phase-5-evidence/manual-YYYY-MM-DD"
)

status=0
for pattern in "${required_patterns[@]}"; do
  if ! rg --quiet --fixed-strings -- "$pattern" "$template_path"; then
    echo "Phase 5 evidence template is missing: $pattern" >&2
    status=1
  fi
done

legacy_capture='scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production Mac Photos test library" 1000 10000 50000'
if rg --quiet --fixed-strings -- "$legacy_capture" "$template_path"; then
  echo "Phase 5 evidence template still contains the legacy host capture command without --timestamp." >&2
  status=1
fi

if ! python3 - "$template_path" <<'PY'
import sys
from pathlib import Path

source = Path(sys.argv[1]).read_text()

ordered_pairs = [
    (
        "scripts/prepare-phase-5-host-baseline-capture.sh\n",
        'scripts/prepare-phase-5-host-baseline-capture.sh --evidence docs/phase-5-evidence-YYYY-MM-DD.md --label "Non-production Mac Photos test library" --timestamp YYYYMMDD-HHMMSS --date YYYY-MM-DD',
        "host baseline helper",
    ),
    (
        'scripts/prepare-phase-5-host-baseline-capture.sh --evidence docs/phase-5-evidence-YYYY-MM-DD.md --label "Non-production Mac Photos test library" --timestamp YYYYMMDD-HHMMSS --date YYYY-MM-DD',
        'scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production Mac Photos test library" --validate-only 1000 10000 50000',
        "host baseline explicit helper before preflight",
    ),
    (
        'scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production Mac Photos test library" --validate-only 1000 10000 50000',
        'scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production Mac Photos test library" --timestamp YYYYMMDD-HHMMSS 1000 10000 50000',
        "host baseline preflight before formal capture",
    ),
    (
        "scripts/prepare-phase-5-macos-manual-capture.sh\n",
        "scripts/prepare-phase-5-macos-manual-capture.sh --manual-dir docs/phase-5-evidence/manual-YYYY-MM-DD --evidence docs/phase-5-evidence-YYYY-MM-DD.md --date YYYY-MM-DD",
        "macOS manual helper",
    ),
    (
        "scripts/prepare-phase-5-macos-manual-capture.sh --manual-dir docs/phase-5-evidence/manual-YYYY-MM-DD --evidence docs/phase-5-evidence-YYYY-MM-DD.md --date YYYY-MM-DD",
        "scripts/check-phase-5-manual-evidence.sh docs/phase-5-evidence/manual-YYYY-MM-DD",
        "macOS manual helper before manual check",
    ),
]

for earlier, later, label in ordered_pairs:
    earlier_index = source.find(earlier)
    later_index = source.find(later, earlier_index + len(earlier)) if earlier_index != -1 else -1
    if earlier_index == -1 or later_index == -1 or earlier_index > later_index:
        print(
            f"Phase 5 evidence template has invalid command order for {label}.",
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

echo "Phase 5 evidence template check passed."
