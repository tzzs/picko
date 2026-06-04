#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/prepare-phase-5-macos-manual-capture.sh [--validate-only] [--manual-dir DIR] [--evidence EVIDENCE_MD] [--date YYYY-MM-DD]

Prepares and prints the macOS Phase 5 manual evidence capture commands for the
two remaining external Photos scenarios. This script does not open Photos, read
Photos libraries, launch Picko, capture the screen, or edit the evidence file.
Use --validate-only when callers need to verify the guide without creating
missing capture directories.
USAGE
}

manual_dir="docs/phase-5-evidence/manual-$(date +%Y-%m-%d)"
evidence_path="docs/phase-5-evidence-$(date +%Y-%m-%d).md"
capture_date="$(date +%Y-%m-%d)"
validate_only=0
manual_dir_provided=0
evidence_path_provided=0
capture_date_provided=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --validate-only)
      validate_only=1
      shift
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
    --evidence)
      if [[ $# -lt 2 ]]; then
        echo "--evidence requires a path." >&2
        exit 64
      fi
      evidence_path="$2"
      evidence_path_provided=1
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
  shopt -s nullglob
  evidence_candidates=(docs/phase-5-evidence-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md)
  shopt -u nullglob
  if [[ "${#evidence_candidates[@]}" -gt 0 ]]; then
    evidence_path="${evidence_candidates[$((${#evidence_candidates[@]} - 1))]}"
  fi
fi

if [[ "$manual_dir_provided" -eq 0 && "$evidence_path" =~ ^docs/phase-5-evidence-([0-9]{4}-[0-9]{2}-[0-9]{2})\.md$ ]]; then
  evidence_date="${BASH_REMATCH[1]}"
  evidence_manual_dir="docs/phase-5-evidence/manual-$evidence_date"
  if [[ -d "$evidence_manual_dir" ]]; then
    manual_dir="$evidence_manual_dir"
  fi
fi

if [[ "$capture_date_provided" -eq 0 ]]; then
  handoff_path="docs/phase-5-evidence/phase-5-external-handoff-$capture_date.md"
  if [[ ! -f "$handoff_path" ]]; then
    shopt -s nullglob
    handoff_candidates=(docs/phase-5-evidence/phase-5-external-handoff-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md)
    shopt -u nullglob
    if [[ "${#handoff_candidates[@]}" -gt 0 ]]; then
      handoff_path="${handoff_candidates[$((${#handoff_candidates[@]} - 1))]}"
      if [[ "$handoff_path" =~ phase-5-external-handoff-([0-9]{4}-[0-9]{2}-[0-9]{2})\.md$ ]]; then
        capture_date="${BASH_REMATCH[1]}"
      fi
    fi
  fi
fi

case "$manual_dir" in
  docs/phase-5-evidence/manual-*|/tmp/picko-phase-5-*|/private/tmp/picko-phase-5-*)
    ;;
  *)
    echo "--manual-dir must be under docs/phase-5-evidence/manual-*; /tmp/picko-phase-5-* is allowed only for local smoke tests." >&2
    exit 64
    ;;
esac

if [[ "$capture_date" =~ (^|[[:space:]/-])TBD([[:space:]/-]|$) || "$capture_date" == *"|"* ]]; then
  echo "--date must be concrete and table-safe." >&2
  exit 64
fi

if [[ ! -f "$evidence_path" ]]; then
  echo "Missing evidence document: $evidence_path" >&2
  exit 66
fi

if [[ "$validate_only" -eq 0 ]]; then
  mkdir -p "$manual_dir/macos/authorization" "$manual_dir/macos/delete-confirmation"
fi

readme="$manual_dir/README.md"
if [[ ! -f "$readme" ]]; then
  echo "Missing manual evidence README: $readme" >&2
  echo "Run: scripts/prepare-phase-5-manual-evidence.sh --output $manual_dir" >&2
  exit 66
fi

required_patterns=(
  "Use only non-production Photos assets"
  "macOS Photos Authorization"
  "macOS Delete Confirmation"
  "screencapture -i"
  "Do not click the system Delete button"
  "press Escape or click Cancel"
  "avoid personal photo thumbnails"
)

for pattern in "${required_patterns[@]}"; do
  if ! rg --quiet --fixed-strings "$pattern" "$readme"; then
    echo "Manual evidence README is missing required safety guidance: $pattern" >&2
    exit 65
  fi
done

python3 - "$evidence_path" <<'PY'
import sys
from pathlib import Path

evidence_path = Path(sys.argv[1])
required_rows = {
    ("First Photos authorization", "macOS"),
    ("Pre-delete basket triggers Photos confirmation", "macOS"),
}
found_rows = set()

for line in evidence_path.read_text().splitlines():
    stripped = line.strip()
    if not stripped.startswith("|") or not stripped.endswith("|"):
        continue
    parts = [part.strip() for part in stripped.strip("|").split("|")]
    if len(parts) != 5:
        continue
    scenario, platform = parts[0], parts[1]
    if (scenario, platform) in required_rows:
        found_rows.add((scenario, platform))

missing = required_rows - found_rows
if missing:
    labels = "; ".join(f"{scenario} / {platform}" for scenario, platform in sorted(missing))
    raise SystemExit(f"evidence document is missing required macOS manual verification rows: {labels}")
PY

authorization_path="$manual_dir/macos/authorization/macos-first-photos-authorization-$capture_date.png"
delete_confirmation_path="$manual_dir/macos/delete-confirmation/macos-system-photos-delete-confirmation-$capture_date.png"

for target_capture_path in "$authorization_path" "$delete_confirmation_path"; do
  if [[ -e "$target_capture_path" ]]; then
    echo "macOS manual capture target already exists; choose a new --date or archive the existing evidence first: $target_capture_path" >&2
    exit 1
  fi
done

cat <<GUIDE
Picko Phase 5 macOS manual evidence capture guide

Safety:
- Use only a non-production Mac Photos library.
- Keep screenshots tight; avoid personal photo thumbnails, faces, filenames, map/location details, and Finder paths.
- Do not click the system Delete button while collecting delete-confirmation evidence.
- After capture, press Escape or click Cancel to dismiss the system confirmation without deleting assets.
- This script only prepares paths and commands; it does not read Photos libraries or capture the screen.

Capture after each relevant system prompt is visible:

  screencapture -i $authorization_path
  screencapture -i $delete_confirmation_path

After both files exist, validate the manual evidence folder:

  scripts/check-phase-5-manual-evidence.sh $manual_dir

Write the macOS rows back to the evidence document:

  scripts/update-phase-5-manual-verification.sh \\
    --evidence $evidence_path \\
    --scenario "First Photos authorization" \\
    --platform "macOS" \\
    --result "Passed" \\
    --path "$authorization_path" \\
    --notes "Non-production Mac Photos library first authorization prompt captured"

  scripts/update-phase-5-manual-verification.sh \\
    --evidence $evidence_path \\
    --scenario "Pre-delete basket triggers Photos confirmation" \\
    --platform "macOS" \\
    --result "Passed" \\
    --path "$delete_confirmation_path" \\
    --notes "Non-production Mac Photos library system delete confirmation captured without clicking Delete"
GUIDE
