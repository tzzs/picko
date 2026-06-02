#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/phase-5-external-evidence-checklist.sh [--evidence EVIDENCE_MD] [--manual-dir DIR] [--date YYYY-MM-DD] [--host-timestamp ID]

Prints the remaining Phase 5 external evidence commands and write-back steps.
This is a read-only checklist: it does not read Photos libraries, boot
Simulator, import media, delete assets, or edit evidence files.
USAGE
}

evidence_path="docs/phase-5-evidence-$(date +%Y-%m-%d).md"
manual_dir="docs/phase-5-evidence/manual-$(date +%Y-%m-%d)"
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
        echo "--host-timestamp requires a value." >&2
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

if [[ "$host_capture_timestamp" == *"TBD"* || ! "$host_capture_timestamp" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "--host-timestamp must be a concrete filename-safe value." >&2
  exit 64
fi

host_baseline_json_path="docs/phase-5-evidence/metadata-baseline-photos-1000-10000-50000-$host_capture_timestamp.json"
macos_authorization_path="$manual_dir/macos/authorization/macos-first-photos-authorization-$capture_date.png"
macos_delete_confirmation_path="$manual_dir/macos/delete-confirmation/macos-system-photos-delete-confirmation-$capture_date.png"

missing_ios_benchmark_counts() {
  local source_path="$1"

  if [[ ! -f "$source_path" ]]; then
    printf '1000\n10000\n50000\n'
    return
  fi

  python3 - "$source_path" <<'PY'
import subprocess
import subprocess
import re
import sys
from pathlib import Path

source_path = Path(sys.argv[1])
rows = {}
supported_extensions = {".png", ".jpg", ".jpeg", ".heic", ".mov", ".mp4"}

for line in source_path.read_text().splitlines():
    stripped = line.strip()
    if not stripped.startswith("|") or not stripped.endswith("|"):
        continue

    parts = [part.strip() for part in stripped.strip("|").split("|")]
    if len(parts) < 4:
        continue

    count_text = parts[0].replace(",", "")
    if count_text not in {"1000", "10000", "50000"}:
        continue

    try:
        elapsed = float(parts[1].replace(",", ""))
        rate = float(parts[2].replace(",", ""))
    except ValueError:
        elapsed = 0.0
        rate = 0.0

    artifact_path = parts[3].strip().strip("`").strip()
    rows[int(count_text)] = (
        elapsed > 0
        and rate > 0
        and artifact_path.startswith("docs/phase-5-evidence/")
        and Path(artifact_path).is_file()
        and Path(artifact_path).stat().st_size > 0
        and Path(artifact_path).suffix.lower() in supported_extensions
    )

for count in (1000, 10000, 50000):
    if not rows.get(count, False):
        print(count)
PY
}

environment_value() {
  local field_name="$1"
  local source_path="$2"

  if [[ ! -f "$source_path" ]]; then
    return
  fi

  python3 - "$field_name" "$source_path" <<'PY'
import sys
from pathlib import Path

field_name = sys.argv[1]
source_path = Path(sys.argv[2])

for line in source_path.read_text().splitlines():
    parts = [part.strip() for part in line.strip().strip("|").split("|")]
    if len(parts) == 2 and parts[0] == field_name:
        print(parts[1])
        break
PY
}

manual_verification_ready() {
  local scenario="$1"
  local platform="$2"
  local source_path="$3"

  if [[ ! -f "$source_path" ]]; then
    return 1
  fi

  python3 - "$scenario" "$platform" "$source_path" <<'PY'
import re
import sys
from pathlib import Path

scenario = sys.argv[1]
platform = sys.argv[2]
source_path = Path(sys.argv[3])
expected_fragments = {
    ("First Photos authorization", "iOS"): ["/ios/authorization/"],
    ("Limited library state", "iOS"): ["/ios/limited-library/"],
    ("Pre-delete basket triggers Photos confirmation", "iOS"): ["/ios/delete-confirmation/"],
    ("First Photos authorization", "macOS"): ["/macos/authorization/"],
    ("Pre-delete basket triggers Photos confirmation", "macOS"): ["/macos/delete-confirmation/"],
    ("Recently Deleted recovery explanation", "iOS/macOS"): [
        "/ios/delete-confirmation/",
        "/macos/delete-confirmation/",
        "/privacy/",
    ],
}
supported_artifact_extensions = {
    ".png",
    ".jpg",
    ".jpeg",
    ".heic",
    ".mov",
    ".mp4",
    ".log",
    ".txt",
}
text_artifact_extensions = {".log", ".txt"}
sensitive_artifact_pattern = re.compile(
    r"picko-fixture-[0-9]+\.jpg|Picko [0-9]{1,6}|localIdentifier|PHAsset|"
    r"latitude|longitude|GPS|CLLocation|assetIds?[:=]|file(name|URL|Path)",
    re.IGNORECASE,
)
sensitive_note_phrases = (
    "personal photos",
    "personal library",
    "production personal",
)
sensitive_note_prefixes = (
    "production photos",
    "production library",
)

def notes_reference_personal_or_production_library(notes: str) -> bool:
    lowered = notes.lower()
    if any(phrase in lowered for phrase in sensitive_note_phrases):
        return True
    return any(
        lowered == prefix or lowered.startswith(prefix + " ") or f" {prefix}" in lowered
        for prefix in sensitive_note_prefixes
    )

def text_artifact_contains_sensitive_metadata(path: Path) -> bool:
    if path.suffix.lower() not in text_artifact_extensions:
        return False
    return sensitive_artifact_pattern.search(path.read_text(errors="ignore")) is not None

for line in source_path.read_text().splitlines():
    stripped = line.strip()
    if not stripped.startswith("|") or not stripped.endswith("|"):
        continue

    parts = [part.strip() for part in stripped.strip("|").split("|")]
    if len(parts) != 5:
        continue

    row_scenario, row_platform, result, artifact_path, notes = parts
    artifact_path = artifact_path.strip("`").strip()
    if (
        row_scenario == scenario
        and row_platform == platform
        and result == "Passed"
        and artifact_path.startswith("docs/phase-5-evidence/manual-")
        and any(fragment in f"{artifact_path}/" for fragment in expected_fragments[(scenario, platform)])
        and Path(artifact_path).is_file()
        and Path(artifact_path).stat().st_size > 0
        and Path(artifact_path).suffix.lower() in supported_artifact_extensions
        and not text_artifact_contains_sensitive_metadata(Path(artifact_path))
        and notes
        and "TBD" not in notes
        and not notes_reference_personal_or_production_library(notes)
    ):
        raise SystemExit(0)

raise SystemExit(1)
PY
}

runtime_privacy_ready() {
  local source_path="$1"

  if [[ ! -f "$source_path" ]]; then
    return 1
  fi

  python3 - "$source_path" <<'PY'
import subprocess
import re
import sys
from pathlib import Path

source_path = Path(sys.argv[1])
in_privacy_section = False

for line in source_path.read_text().splitlines():
    if line.startswith("## "):
        if in_privacy_section:
            break
        in_privacy_section = line.strip() == "## Privacy Review"
        continue
    if not in_privacy_section:
        continue
    if "Runtime logs checked for photo contents or sensitive metadata" not in line:
        continue
    if "audit-runtime-privacy-logs.sh" not in line:
        continue
    if "TBD" in line or "LOG_PATH" in line:
        continue

    match = re.search(r"docs/phase-5-evidence/privacy/[^ `|)]+", line)
    if (
        match
        and Path(match.group(0)).is_file()
        and Path(match.group(0)).stat().st_size > 0
        and subprocess.run(
            ["scripts/audit-runtime-privacy-logs.sh", match.group(0)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        ).returncode == 0
    ):
        raise SystemExit(0)

raise SystemExit(1)
PY
}

host_baseline_ready() {
  local source_path="$1"

  if [[ ! -f "$source_path" ]]; then
    return 1
  fi

  python3 - "$source_path" <<'PY'
import json
import re
import sys
from pathlib import Path

source_path = Path(sys.argv[1])
text = source_path.read_text()
host_section_lines = []
in_host_section = False
for line in text.splitlines():
    if line.startswith("## "):
        if in_host_section:
            break
        in_host_section = line.strip() == "## Host Photos-Backed Metadata Baseline"
        continue
    if in_host_section:
        host_section_lines.append(line)

if not host_section_lines:
    raise SystemExit(1)

host_section = "\n".join(host_section_lines)
normalized = " ".join(host_section.replace("\\\n", " ").split())
if "Preflight status:" not in host_section or "Passed" not in host_section:
    raise SystemExit(1)

required_tokens = (
    "scripts/capture-metadata-baseline.sh",
    "--photos",
    "--confirm-non-production-photos",
    "--photos-library-label",
    "--validate-only",
    "1000",
    "10000",
    "50000",
)

if not all(token in normalized for token in required_tokens):
    raise SystemExit(1)

label_match = re.search(r'--photos-library-label\s+"([^"]+)"', normalized)
if not label_match:
    raise SystemExit(1)

label = label_match.group(1).lower()
unsafe_phrases = (
    "personal photos",
    "personal library",
    "production personal",
    "production photos",
    "production library",
)
if "non-production" not in label or any(phrase in label for phrase in unsafe_phrases):
    raise SystemExit(1)

for match in re.finditer(r"docs/phase-5-evidence/[^ `|)]+\.json", text):
    json_path = Path(match.group(0))
    if not json_path.is_file():
        continue

    try:
        payload = json.loads(json_path.read_text())
    except Exception:
        continue

    mode = str(payload.get("mode", "")).lower()
    if "photos" not in mode or "synthetic" in mode:
        continue

    library_label = str(payload.get("photosLibraryLabel", "")).lower()
    if "non-production" not in library_label or any(
        phrase in library_label for phrase in unsafe_phrases
    ):
        continue

    rows = {}
    for row in payload.get("rows", []):
        try:
            count = int(row.get("assetCount"))
            elapsed = float(row.get("elapsedSeconds"))
            rate = float(row.get("assetsPerSecond"))
        except (TypeError, ValueError):
            continue
        rows[count] = elapsed > 0 and rate > 0

    if all(rows.get(count, False) for count in (1000, 10000, 50000)):
        raise SystemExit(0)

raise SystemExit(1)
PY
}

host_baseline_preflight_ready() {
  local source_path="$1"

  if [[ ! -f "$source_path" ]]; then
    return 1
  fi

  python3 - "$source_path" <<'PY'
import shlex
import sys
from pathlib import Path

source_path = Path(sys.argv[1])
host_section_lines = []
in_host_section = False
for line in source_path.read_text().splitlines():
    if line.startswith("## "):
        if in_host_section:
            break
        in_host_section = line.strip() == "## Host Photos-Backed Metadata Baseline"
        continue
    if in_host_section:
        host_section_lines.append(line)

if not host_section_lines:
    raise SystemExit(1)

host_section = "\n".join(host_section_lines)
if "Preflight status:" not in host_section or "Passed" not in host_section:
    raise SystemExit(1)

unsafe_phrases = (
    "personal photos",
    "personal library",
    "production personal",
    "production photos",
    "production library",
)
for line in host_section_lines:
    if "capture-metadata-baseline.sh" not in line or "--validate-only" not in line:
        continue
    try:
        tokens = shlex.split(line.replace("\\", " "))
    except ValueError:
        continue
    token_set = set(tokens)
    if not {
        "--photos",
        "--confirm-non-production-photos",
        "--photos-library-label",
        "--validate-only",
        "1000",
        "10000",
        "50000",
    }.issubset(token_set):
        continue
    try:
        label = tokens[tokens.index("--photos-library-label") + 1]
    except (ValueError, IndexError):
        continue
    label = label.lower()
    if "non-production" in label and not any(phrase in label for phrase in unsafe_phrases):
        raise SystemExit(0)

raise SystemExit(1)
PY
}

final_completeness_ready() {
  local source_path="$1"

  if [[ ! -f "$source_path" ]]; then
    return 1
  fi

  python3 - "$source_path" <<'PY'
import sys
from pathlib import Path

source_path = Path(sys.argv[1])
required = {
    "Evidence completeness": "scripts/check-phase-5-evidence.sh",
    "Manual evidence completeness": "scripts/check-phase-5-manual-evidence.sh",
}
ready = {gate: False for gate in required}

for line in source_path.read_text().splitlines():
    stripped = line.strip()
    if not stripped.startswith("|") or not stripped.endswith("|"):
        continue

    parts = [part.strip() for part in stripped.strip("|").split("|")]
    if len(parts) != 4:
        continue

    gate, command, result, evidence = parts
    if (
        gate in required
        and required[gate] in command
        and result == "Passed"
        and evidence
        and "TBD" not in evidence
    ):
        ready[gate] = True

raise SystemExit(0 if all(ready.values()) else 1)
PY
}

ios_environment_missing=1
test_library_environment_missing=1

ios_simulator_value="$(environment_value "iOS Simulator" "$evidence_path")"
if [[ -n "$ios_simulator_value" && "$ios_simulator_value" != *"TBD"* ]]; then
  ios_environment_missing=0
fi

test_library_value="$(environment_value "Test Photos Library" "$evidence_path")"
test_library_lower="$(printf '%s' "$test_library_value" | tr '[:upper:]' '[:lower:]')"
if [[ -n "$test_library_value" \
  && "$test_library_value" != *"TBD"* \
  && "$test_library_lower" == *"non-production"* \
  && "$test_library_lower" != *"production personal"* \
  && "$test_library_lower" != *"personal photos"* \
  && "$test_library_lower" != *"personal library"* \
  && "$test_library_lower" != *"production photos"* \
  && "$test_library_lower" != *"production library"* ]]; then
  test_library_environment_missing=0
fi

ios_benchmark_counts=()
while IFS= read -r count; do
  [[ -z "$count" ]] && continue
  ios_benchmark_counts+=("$count")
done < <(missing_ios_benchmark_counts "$evidence_path")

format_count_label() {
  case "$1" in
    1000) printf '1,000' ;;
    10000) printf '10,000' ;;
    50000) printf '50,000' ;;
    *) printf '%s' "$1" ;;
  esac
}

ios_benchmark_count_labels=""
for count in ${ios_benchmark_counts[@]+"${ios_benchmark_counts[@]}"}; do
  if [[ -n "$ios_benchmark_count_labels" ]]; then
    ios_benchmark_count_labels+=", "
  fi
  ios_benchmark_count_labels+="$(format_count_label "$count")"
done
if [[ -z "$ios_benchmark_count_labels" ]]; then
  ios_benchmark_count_labels="none"
fi

manual_entries=(
  "First Photos authorization|iOS|$manual_dir/ios/authorization|Non-production Photos library"
  "Limited library state|iOS|$manual_dir/ios/limited-library|Non-production limited library"
  "Pre-delete basket triggers Photos confirmation|iOS|$manual_dir/ios/delete-confirmation|System Photos confirmation after Picko basket confirmation"
  "First Photos authorization|macOS|$manual_dir/macos/authorization|Non-production Mac Photos library first authorization prompt captured"
  "Pre-delete basket triggers Photos confirmation|macOS|$manual_dir/macos/delete-confirmation|Non-production Mac Photos library system delete confirmation captured without clicking Delete"
  "Recently Deleted recovery explanation|iOS/macOS|$manual_dir/ios/delete-confirmation|Copy explains Photos Recently Deleted recovery"
)

manual_artifact_path() {
  local scenario="$1"
  local platform="$2"
  local artifact_dir="$3"

  case "$scenario|$platform" in
    "First Photos authorization|macOS")
      printf '%s/macos-first-photos-authorization-%s.png' "$artifact_dir" "$capture_date"
      ;;
    "Pre-delete basket triggers Photos confirmation|macOS")
      printf '%s/macos-system-photos-delete-confirmation-%s.png' "$artifact_dir" "$capture_date"
      ;;
    *)
      printf '%s/ARTIFACT' "$artifact_dir"
      ;;
  esac
}

missing_manual_entries=()
missing_manual_dirs=()
for entry in "${manual_entries[@]}"; do
  IFS='|' read -r scenario platform artifact_dir notes <<<"$entry"
  if ! manual_verification_ready "$scenario" "$platform" "$evidence_path"; then
    missing_manual_entries+=("$entry")
    already_recorded=0
    for existing_dir in ${missing_manual_dirs[@]+"${missing_manual_dirs[@]}"}; do
      if [[ "$existing_dir" == "$artifact_dir" ]]; then
        already_recorded=1
        break
      fi
    done
    if [[ "$already_recorded" -eq 0 ]]; then
      missing_manual_dirs+=("$artifact_dir")
    fi
  fi
done

runtime_privacy_missing=1
if runtime_privacy_ready "$evidence_path"; then
  runtime_privacy_missing=0
fi

host_baseline_missing=1
if host_baseline_ready "$evidence_path"; then
  host_baseline_missing=0
fi
host_baseline_preflight_missing=1
if host_baseline_preflight_ready "$evidence_path"; then
  host_baseline_preflight_missing=0
fi

final_completeness_missing=1
if final_completeness_ready "$evidence_path"; then
  final_completeness_missing=0
fi

cat <<CHECKLIST
Picko Phase 5 External Evidence Checklist

Evidence document:
  $evidence_path

Manual evidence directory:
  $manual_dir

Important guardrails:
  - Use only non-production Photos libraries and simulator media.
  - Do not capture personal photos, faces, filenames, locations, or sensitive metadata.
  - Do not run host Photos commands against a production Mac Photos library.
  - This checklist is read-only; run the commands manually when the target environment is ready.

CHECKLIST

if [[ ! -f "$evidence_path" ]]; then
  cat <<CHECKLIST
0. Create the final evidence document

The evidence document does not exist yet. Create it before writing back captured rows:

  scripts/create-phase-5-evidence.sh $evidence_path

CHECKLIST
fi

cat <<CHECKLIST

1. Host Photos-backed baseline

CHECKLIST

if [[ "$host_baseline_missing" -ne 0 && -e "$host_baseline_json_path" ]]; then
  cat <<CHECKLIST
Host baseline JSON target already exists for this --host-timestamp:

  $host_baseline_json_path

Choose a new --host-timestamp or archive the existing evidence before running the capture command.

CHECKLIST
fi

if [[ "$host_baseline_missing" -eq 0 ]]; then
  cat <<CHECKLIST
Host Photos-backed baseline JSON is already referenced; no capture or write-back step is currently required.

CHECKLIST
elif [[ "$host_baseline_preflight_missing" -eq 0 ]]; then
  cat <<CHECKLIST
Host Photos-backed baseline preflight is already recorded as Passed. First print the active-package capture guide:

  scripts/prepare-phase-5-host-baseline-capture.sh

Explicit reproducibility:

  scripts/prepare-phase-5-host-baseline-capture.sh \\
    --evidence $evidence_path \\
    --label "Non-production Mac Photos test library" \\
    --timestamp $host_capture_timestamp \\
    --date $capture_date

  scripts/capture-metadata-baseline.sh \\
    --photos \\
    --confirm-non-production-photos \\
    --photos-library-label "Non-production Mac Photos test library" \\
    --timestamp $host_capture_timestamp \\
    1000 10000 50000

Write the captured JSON back to the evidence document:

  scripts/update-phase-5-host-baseline.sh \\
    --evidence $evidence_path \\
    --baseline-json docs/phase-5-evidence/metadata-baseline-photos-1000-10000-50000-$host_capture_timestamp.json

CHECKLIST
else
  cat <<CHECKLIST
Prepare a non-production Mac Photos library, then preflight the formal 1k/10k/50k baseline command without reading the Photos library:

  scripts/capture-metadata-baseline.sh \\
    --photos \\
    --confirm-non-production-photos \\
    --photos-library-label "Non-production Mac Photos test library" \\
    --validate-only \\
    1000 10000 50000

After the preflight passes, first print the active-package capture guide:

  scripts/prepare-phase-5-host-baseline-capture.sh

Explicit reproducibility:

  scripts/prepare-phase-5-host-baseline-capture.sh \\
    --evidence $evidence_path \\
    --label "Non-production Mac Photos test library" \\
    --timestamp $host_capture_timestamp \\
    --date $capture_date

  scripts/capture-metadata-baseline.sh \\
    --photos \\
    --confirm-non-production-photos \\
    --photos-library-label "Non-production Mac Photos test library" \\
    --timestamp $host_capture_timestamp \\
    1000 10000 50000

Write the captured JSON back to the evidence document:

  scripts/update-phase-5-host-baseline.sh \\
    --evidence $evidence_path \\
    --baseline-json docs/phase-5-evidence/metadata-baseline-photos-1000-10000-50000-$host_capture_timestamp.json

CHECKLIST
fi

cat <<CHECKLIST
2. iOS Simulator Photos-backed benchmark evidence

Missing or incomplete benchmark counts in the target evidence document:

  $ios_benchmark_count_labels
CHECKLIST

if [[ "${#ios_benchmark_counts[@]}" -eq 0 ]]; then
  cat <<CHECKLIST
No iOS Simulator benchmark import, launch, or write-back step is currently required.

CHECKLIST
else
  cat <<CHECKLIST
Boot a disposable simulator and seed non-production media in resumable chunks:

CHECKLIST

  for count in "${ios_benchmark_counts[@]}"; do
    cat <<CHECKLIST
  scripts/import-simulator-photos-fixture-chunked.sh --count $count --simulator booted --chunk-size 500 --batch-size 100
CHECKLIST
  done

  cat <<CHECKLIST

CHECKLIST
fi

if [[ "$ios_environment_missing" -eq 1 ]]; then
  cat <<CHECKLIST
Record the simulator environment after the target simulator and OS are confirmed:

  scripts/update-phase-5-environment.sh \\
    --evidence $evidence_path \\
    --field "iOS Simulator" \\
    --value "iPhone MODEL, iOS VERSION, disposable Photos library"

CHECKLIST
fi

if [[ "${#ios_benchmark_counts[@]}" -gt 0 ]]; then
cat <<CHECKLIST
Launch Picko with the Photos-backed benchmark trigger:

  --picko-run-metadata-benchmark --picko-benchmark-counts=1000,10000,50000

Save screenshots or recordings under:

  docs/phase-5-evidence/ios-metadata-benchmark/

Write each captured row back to the evidence document:

CHECKLIST

  for count in "${ios_benchmark_counts[@]}"; do
    cat <<CHECKLIST
  scripts/update-phase-5-ios-benchmark.sh \\
    --evidence $evidence_path \\
    --count $count \\
    --seconds ELAPSED_SECONDS \\
    --rate ASSETS_PER_SECOND \\
    --path docs/phase-5-evidence/ios-metadata-benchmark/photos-$count-YYYY-MM-DD.jpg

CHECKLIST
  done
fi

cat <<CHECKLIST

3. Manual Photos verification

Manual evidence folder:

CHECKLIST

if [[ -d "$manual_dir" ]]; then
  cat <<CHECKLIST
  already prepared at $manual_dir

Do not recreate it unless the folder is missing; the prepare script preserves an existing README so operator status notes are not overwritten.

CHECKLIST
else
  cat <<CHECKLIST
  scripts/prepare-phase-5-manual-evidence.sh --output $manual_dir

CHECKLIST
fi

cat <<CHECKLIST

Capture the required non-production artifacts:

CHECKLIST

if [[ "${#missing_manual_dirs[@]}" -eq 0 ]]; then
  cat <<CHECKLIST
  none

CHECKLIST
else
  for artifact_dir in "${missing_manual_dirs[@]}"; do
    cat <<CHECKLIST
  $artifact_dir/
CHECKLIST
  done
  cat <<CHECKLIST

CHECKLIST

  for target_capture_path in "$macos_authorization_path" "$macos_delete_confirmation_path"; do
    if [[ -e "$target_capture_path" ]]; then
      cat <<CHECKLIST
macOS manual capture target already exists for this --date:

  $target_capture_path

Choose a new --date or archive the existing evidence before running screencapture.

CHECKLIST
    fi
  done

  cat <<CHECKLIST
Suggested macOS capture guide before opening the relevant system prompt:

  scripts/prepare-phase-5-macos-manual-capture.sh

Explicit reproducibility:

  scripts/prepare-phase-5-macos-manual-capture.sh \\
    --manual-dir $manual_dir \\
    --evidence $evidence_path \\
    --date $capture_date

  screencapture -i $macos_authorization_path
  screencapture -i $macos_delete_confirmation_path

Capture only non-production Photos prompts or confirmations. Keep screenshots tight and avoid personal photo thumbnails, faces, filenames, map/location details, or Finder paths. Do not click the system Delete button while collecting delete-confirmation evidence; after capture, press Escape or click Cancel to dismiss the system confirmation without deleting assets.

CHECKLIST
fi

if [[ "$test_library_environment_missing" -eq 1 ]]; then
  cat <<CHECKLIST
Record the non-production Photos library scope after both iOS and macOS evidence environments are confirmed:

  scripts/update-phase-5-environment.sh \\
    --evidence $evidence_path \\
    --field "Test Photos Library" \\
    --value "Non-production simulator fixture and non-production Mac Photos library"

CHECKLIST
fi

if [[ "${#missing_manual_entries[@]}" -eq 0 ]]; then
  cat <<CHECKLIST
All manual verification rows already reference captured local evidence.

CHECKLIST
else
cat <<CHECKLIST
Write the manual verification rows back to the evidence document:

CHECKLIST

for entry in "${missing_manual_entries[@]}"; do
  IFS='|' read -r scenario platform artifact_dir notes <<<"$entry"
  artifact_path="$(manual_artifact_path "$scenario" "$platform" "$artifact_dir")"
  cat <<CHECKLIST
  scripts/update-phase-5-manual-verification.sh \\
    --evidence $evidence_path \\
    --scenario "$scenario" \\
    --platform "$platform" \\
    --result "Passed" \\
    --path $artifact_path \\
    --notes "$notes"

CHECKLIST
done
fi

if [[ "$runtime_privacy_missing" -eq 1 ]]; then
  cat <<CHECKLIST
4. Runtime privacy evidence

Capture runtime or system logs from non-production Photos runs under:

  docs/phase-5-evidence/privacy/

Audit and record the logs:

  scripts/record-runtime-privacy-evidence.sh \\
    --evidence $evidence_path \\
    --log docs/phase-5-evidence/privacy/runtime-YYYY-MM-DD.log

CHECKLIST
else
  cat <<CHECKLIST
4. Runtime privacy evidence

Runtime privacy log audit evidence is already referenced; no write-back step is currently required.

CHECKLIST
fi

cat <<CHECKLIST
5. Final completeness gates

CHECKLIST

if [[ "$final_completeness_missing" -eq 0 ]]; then
  cat <<CHECKLIST
Final completeness gates are already recorded as Passed; no write-back step is currently required.

Default final status commands:

  scripts/report-phase-5-status.sh --fail-on-incomplete
  scripts/check-phase-5-evidence.sh $evidence_path
  scripts/audit-mvp-next-completion.sh

Explicit final status reproducibility:

  scripts/report-phase-5-status.sh --evidence $evidence_path --date $capture_date --host-timestamp $host_capture_timestamp --fail-on-incomplete
  scripts/check-phase-5-evidence.sh $evidence_path
  scripts/audit-mvp-next-completion.sh --plan docs/MVP-Next-Development-Plan.md --product-spec docs/MVP-Product-Spec.md --verification docs/Phase-5-Verification.md --runbook docs/Phase-5-External-Evidence-Runbook.md --evidence $evidence_path --manual-dir $manual_dir --handoff docs/phase-5-evidence/phase-5-external-handoff-$capture_date.md --date $capture_date --host-timestamp $host_capture_timestamp

The whole-plan audit verifies the MVP plan, product spec, Phase 5 shell literal safety gate, evidence template coverage, runbook, handoff, evidence directory cleanliness, and evidence status together.
CHECKLIST
else
  cat <<CHECKLIST
After all rows and evidence files are present, finalize the evidence:

Default finalization command:

  scripts/finalize-phase-5-evidence.sh
  scripts/audit-mvp-next-completion.sh

Explicit finalization reproducibility:

  scripts/finalize-phase-5-evidence.sh --evidence $evidence_path --date $capture_date --host-timestamp $host_capture_timestamp
  scripts/audit-mvp-next-completion.sh --plan docs/MVP-Next-Development-Plan.md --product-spec docs/MVP-Product-Spec.md --verification docs/Phase-5-Verification.md --runbook docs/Phase-5-External-Evidence-Runbook.md --evidence $evidence_path --manual-dir $manual_dir --handoff docs/phase-5-evidence/phase-5-external-handoff-$capture_date.md --date $capture_date --host-timestamp $host_capture_timestamp

The finalizer checks the Phase 5 evidence directory cleanliness and evidence template, records the final completeness gates, runs the final status report, and runs the final evidence checker. The whole-plan audit then verifies the MVP plan, product spec, Phase 5 shell literal safety gate, evidence template coverage, runbook, handoff, evidence directory cleanliness, and evidence status together. Equivalent manual sequence before the whole-plan audit:

  scripts/record-phase-5-completeness-gates.sh --evidence $evidence_path
  scripts/report-phase-5-status.sh --evidence $evidence_path --date $capture_date --host-timestamp $host_capture_timestamp --fail-on-incomplete
  scripts/check-phase-5-evidence.sh $evidence_path
CHECKLIST
fi
