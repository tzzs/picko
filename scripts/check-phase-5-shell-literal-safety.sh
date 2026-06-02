#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/check-phase-5-shell-literal-safety.sh [SCRIPT ...]

Checks Phase 5 shell checker arrays for raw backticks that Bash would treat as
command substitution when the script is executed. Use plain text or escaped
backticks in required_patterns-style arrays.
USAGE
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

if [[ $# -gt 0 ]]; then
  files=("$@")
else
  files=(
    scripts/audit-mvp-next-completion.sh
    scripts/check-phase-5-evidence.sh
    scripts/check-phase-5-external-evidence-readiness.sh
    scripts/check-phase-5-external-handoff.sh
    scripts/check-phase-5-external-runbook.sh
    scripts/check-phase-5-manual-evidence.sh
    scripts/check-phase-5-verification-doc.sh
    scripts/report-mvp-next-development-status.sh
    scripts/report-phase-5-status.sh
  )
fi

python3 - "${files[@]}" <<'PY'
import re
import sys
from pathlib import Path

array_names = {
    "required_patterns",
    "unexpected_status_patterns",
}

status = 0
for raw_path in sys.argv[1:]:
    path = Path(raw_path)
    if not path.exists():
        print(f"Missing script: {path}", file=sys.stderr)
        status = 66
        continue

    active_array = None
    for line_number, line in enumerate(path.read_text().splitlines(), start=1):
        stripped = line.strip()
        match = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)=\($", stripped)
        if match and match.group(1) in array_names:
            active_array = match.group(1)
            continue
        if active_array and stripped == ")":
            active_array = None
            continue
        if not active_array:
            continue

        for index, character in enumerate(line):
            if character != "`":
                continue
            if index > 0 and line[index - 1] == "\\":
                continue
            print(
                f"{path}:{line_number}: raw backtick in {active_array}; "
                "use plain text or escape it as \\`.",
                file=sys.stderr,
            )
            status = 1
            break

sys.exit(status)
PY

echo "Phase 5 shell literal safety check passed."
