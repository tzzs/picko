#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/check-phase-5-evidence.sh [--allow-temp] EVIDENCE_MD

Checks a completed Phase 5 evidence document for unresolved placeholders and
missing local evidence file references.

Options:
  --allow-temp  Allow /tmp JSON references for local smoke tests.
USAGE
}

allow_temp=0
if [[ "${1:-}" == "--allow-temp" ]]; then
  allow_temp=1
  shift
fi

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 64
fi

evidence_path="$1"
if [[ "$evidence_path" == "--help" || "$evidence_path" == "-h" ]]; then
  usage
  exit 0
fi

if [[ ! -f "$evidence_path" ]]; then
  echo "Missing evidence document: $evidence_path" >&2
  exit 66
fi

status=0
baseline_json_count=0
manual_evidence_count=0

if rg --line-number --color never '(^|[^A-Za-z])TBD([^A-Za-z]|$)|待补充|__[A-Z0-9_]+__' "$evidence_path"; then
  cat >&2 <<'MESSAGE'

Phase 5 evidence is incomplete.
Replace all TBD values and template placeholders before treating Phase 5
evidence as complete.
MESSAGE
  status=1
fi

if ! python3 - "$evidence_path" <<'PY'
import subprocess
import subprocess
import re
import sys
from pathlib import Path

evidence_path = Path(sys.argv[1])
field_aliases = {
    "iOS Simulator": "iOS Simulator",
    "iOS 模拟器": "iOS Simulator",
    "Test Photos Library": "Test Photos Library",
    "测试照片图库": "Test Photos Library",
}
values = {}
for line in evidence_path.read_text().splitlines():
    parts = [part.strip() for part in line.strip().strip("|").split("|")]
    if len(parts) == 2 and parts[0] in field_aliases:
        values[field_aliases[parts[0]]] = parts[1]

ios = values.get("iOS Simulator", "")
if not ios or "TBD" in ios or "待补充" in ios:
    raise SystemExit("missing concrete iOS Simulator environment row")

library = values.get("Test Photos Library", "")
library_lower = library.lower()
if not library or "TBD" in library or "待补充" in library:
    raise SystemExit("missing concrete Test Photos Library environment row")
if "non-production" not in library_lower and "非生产" not in library:
    raise SystemExit("Test Photos Library must explicitly say Non-production")
sensitive_library_phrases = (
    "production personal",
    "personal photos",
    "personal library",
    "production photos",
    "production library",
)
if any(phrase in library_lower for phrase in sensitive_library_phrases):
    raise SystemExit("Test Photos Library must not reference production or personal Photos")
PY
then
  echo "Invalid Phase 5 Environment evidence rows." >&2
  status=1
fi

while IFS= read -r referenced_path; do
  [[ -z "$referenced_path" ]] && continue
  if [[ ! -f "$referenced_path" && ! -d "$referenced_path" ]]; then
    echo "Missing referenced evidence path: $referenced_path" >&2
    status=1
  fi
done < <(rg --only-matching --no-line-number 'docs/phase-5-evidence/[^ `|)]+' "$evidence_path" | sort -u)

while IFS= read -r json_path; do
  [[ -z "$json_path" ]] && continue
  if [[ "$allow_temp" -eq 0 && "$json_path" != docs/phase-5-evidence/* ]]; then
    echo "Final evidence must reference project evidence JSON, not temp JSON: $json_path" >&2
    status=1
    continue
  fi

  if [[ ! -f "$json_path" ]]; then
    echo "Missing referenced JSON evidence file: $json_path" >&2
    status=1
    continue
  fi

  if ! python3 - "$json_path" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
report = json.loads(path.read_text())
mode = str(report.get("mode", ""))
if "photos" not in mode.lower() or "synthetic" in mode.lower():
    raise SystemExit(f"not Photos-backed mode: {mode or '<missing>'}")
library_label = str(report.get("photosLibraryLabel", ""))
library_label_lower = library_label.lower()
if not library_label or "non-production" not in library_label_lower:
    raise SystemExit("missing non-production photosLibraryLabel")
sensitive_library_phrases = (
    "production personal",
    "personal photos",
    "personal library",
    "production photos",
    "production library",
)
if any(phrase in library_label_lower for phrase in sensitive_library_phrases):
    raise SystemExit("photosLibraryLabel references production or personal Photos")

rows = report.get("rows")
if not isinstance(rows, list):
    raise SystemExit("missing rows array")

by_count = {}
for row in rows:
    try:
        count = int(row["assetCount"])
        elapsed = float(row["elapsedSeconds"])
        rate = float(row["assetsPerSecond"])
    except (KeyError, TypeError, ValueError) as error:
        raise SystemExit(f"invalid row: {error}")
    if elapsed <= 0 or rate <= 0:
        raise SystemExit(f"non-positive timing for assetCount {count}")
    by_count[count] = row

missing = [str(count) for count in (1000, 10000, 50000) if count not in by_count]
if missing:
    raise SystemExit("missing assetCount rows: " + ", ".join(missing))
PY
  then
    echo "Invalid Photos baseline JSON evidence: $json_path" >&2
    status=1
  else
    baseline_json_count=$((baseline_json_count + 1))
  fi
done < <(rg --only-matching --no-line-number '(/private)?/tmp/[^ `|)]*\.json|docs/phase-5-evidence/[^ `|)]*\.json' "$evidence_path" | sort -u)

if [[ "$baseline_json_count" -eq 0 ]]; then
  echo "Missing Photos-backed baseline JSON evidence reference." >&2
  status=1
elif ! python3 - "$evidence_path" <<'PY'
import shlex
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text()
host_section_headers = {
    "## Host Photos-Backed Metadata Baseline",
    "## Host Photos 支撑的元数据基线",
    "## 主机 Photos 支撑的元数据基线",
}
host_section_lines = []
in_host_section = False
for raw_line in text.splitlines():
    if raw_line.startswith("## "):
        if in_host_section:
            break
        in_host_section = raw_line.strip() in host_section_headers
        continue
    if in_host_section:
        host_section_lines.append(raw_line)

if not host_section_lines:
    raise SystemExit("missing complete host Photos baseline preflight command")

host_section = "\n".join(host_section_lines)
has_passed_preflight = (
    ("Preflight status:" in host_section and "Passed" in host_section)
    or ("预检状态：" in host_section and "通过" in host_section)
)
if not has_passed_preflight:
    raise SystemExit("missing passed host Photos baseline preflight status")

sensitive_library_phrases = (
    "production personal",
    "personal photos",
    "personal library",
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
        "--validate-only",
        "1000",
        "10000",
        "50000",
    }.issubset(token_set):
        continue
    if "--photos-library-label" not in token_set:
        continue
    try:
        label = tokens[tokens.index("--photos-library-label") + 1]
    except (ValueError, IndexError):
        continue
    label_lower = label.lower()
    if "non-production" not in label_lower:
        continue
    if any(phrase in label_lower for phrase in sensitive_library_phrases):
        raise SystemExit("host Photos baseline preflight label references production or personal Photos")
    raise SystemExit(0)

raise SystemExit("missing complete host Photos baseline preflight command")
PY
then
  echo "Missing complete host Photos baseline preflight command with --validate-only, 1k/10k/50k counts, and Passed preflight status." >&2
  status=1
fi

ios_missing_benchmark_counts_file="$(mktemp "${TMPDIR:-/tmp}/picko-ios-missing-benchmark.XXXXXX")"
python3 - "$evidence_path" > "$ios_missing_benchmark_counts_file" <<'PY'
import sys
from pathlib import Path

evidence_path = Path(sys.argv[1])
required = ["1,000", "10,000", "50,000"]
supported_extensions = {".png", ".jpg", ".jpeg", ".heic", ".mov", ".mp4"}
found = set()
in_ios_section = False
ios_section_headers = {
    "## iOS Simulator Photos-Backed Benchmark",
    "## iOS Simulator Photos 支撑的 Benchmark",
    "## iOS 模拟器 Photos 支撑的基准测试",
}

for line in evidence_path.read_text().splitlines():
    if line.startswith("## "):
        in_ios_section = line.strip() in ios_section_headers
        continue

    if not in_ios_section:
        continue

    stripped = line.strip()
    if not stripped.startswith("|") or not stripped.endswith("|"):
        continue

    parts = [part.strip() for part in stripped.strip("|").split("|")]
    if len(parts) < 4 or parts[0] not in required:
        continue

    try:
        elapsed = float(parts[1].replace(",", ""))
        rate = float(parts[2].replace(",", ""))
    except ValueError:
        continue

    artifact_path = parts[3].strip().strip("`").strip()
    artifact = Path(artifact_path)
    if (
        elapsed > 0
        and rate > 0
        and artifact_path.startswith("docs/phase-5-evidence/")
        and artifact.is_file()
        and artifact.stat().st_size > 0
        and artifact.suffix.lower() in supported_extensions
    ):
        found.add(parts[0])

for count in required:
    if count not in found:
        print(count)
PY

if [[ -s "$ios_missing_benchmark_counts_file" ]]; then
  while IFS= read -r count_label; do
    [[ -z "$count_label" ]] && continue
    echo "Missing iOS Photos-backed benchmark evidence row for $count_label." >&2
  done < "$ios_missing_benchmark_counts_file"
  status=1
fi
rm -f "$ios_missing_benchmark_counts_file"

if ! python3 - "$evidence_path" "$allow_temp" <<'PY'
import subprocess
import re
import sys
from pathlib import Path

evidence_path = Path(sys.argv[1])
allow_temp = sys.argv[2] == "1"
in_privacy_section = False
privacy_section_headers = {"## Privacy Review", "## 隐私审查"}
runtime_privacy_checks = {
    "Runtime logs checked for photo contents or sensitive metadata",
    "Runtime 日志已检查照片内容或敏感元数据",
    "运行时日志已检查照片内容或敏感元数据",
}

for line in evidence_path.read_text().splitlines():
    if line.startswith("## "):
        if in_privacy_section:
            break
        in_privacy_section = line.strip() in privacy_section_headers
        continue
    if not in_privacy_section:
        continue

    stripped = line.strip()
    if not stripped.startswith("|") or not stripped.endswith("|"):
        continue

    parts = [part.strip() for part in stripped.strip("|").split("|")]
    if len(parts) != 3:
        continue

    check, result, evidence = parts
    if check not in runtime_privacy_checks:
        continue
    if result not in {"Passed", "通过"} or "TBD" in evidence or "待补充" in evidence:
        continue
    if "scripts/audit-runtime-privacy-logs.sh" not in evidence:
        continue

    match = re.search(r"((?:/tmp/[^ `|)]+)|(?:docs/phase-5-evidence/privacy/[^ `|)]+))", evidence)
    if not match:
        continue
    log_path = match.group(1)
    if not allow_temp and not log_path.startswith("docs/phase-5-evidence/privacy/"):
        continue
    if (
        Path(log_path).is_file()
        and Path(log_path).stat().st_size > 0
        and subprocess.run(
            ["scripts/audit-runtime-privacy-logs.sh", log_path],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        ).returncode == 0
    ):
        raise SystemExit(0)

raise SystemExit(1)
PY
then
  echo "Missing runtime privacy log audit evidence reference." >&2
  status=1
fi

if ! python3 - "$evidence_path" "$allow_temp" <<'PY'
import re
import sys
from pathlib import Path

evidence_path = Path(sys.argv[1])
allow_temp = sys.argv[2] == "1"
required_rows = [
    ("First Photos authorization", "iOS"),
    ("Limited library state", "iOS"),
    ("Pre-delete basket triggers Photos confirmation", "iOS"),
    ("First Photos authorization", "macOS"),
    ("Pre-delete basket triggers Photos confirmation", "macOS"),
    ("Recently Deleted recovery explanation", "iOS/macOS"),
]
row_aliases = {
    ("首次 Photos 授权", "iOS"): ("First Photos authorization", "iOS"),
    ("Limited library 状态", "iOS"): ("Limited library state", "iOS"),
    ("受限图库状态", "iOS"): ("Limited library state", "iOS"),
    ("预删除篮触发 Photos 确认", "iOS"): ("Pre-delete basket triggers Photos confirmation", "iOS"),
    ("首次 Photos 授权", "macOS"): ("First Photos authorization", "macOS"),
    ("预删除篮触发 Photos 确认", "macOS"): ("Pre-delete basket triggers Photos confirmation", "macOS"),
    ("“最近删除”恢复说明", "iOS/macOS"): ("Recently Deleted recovery explanation", "iOS/macOS"),
    ("\"最近删除\"恢复说明", "iOS/macOS"): ("Recently Deleted recovery explanation", "iOS/macOS"),
}
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

rows = {}
for line in evidence_path.read_text().splitlines():
    stripped = line.strip()
    if not stripped.startswith("|") or not stripped.endswith("|"):
        continue

    parts = [part.strip() for part in stripped.strip("|").split("|")]
    if len(parts) < 5:
        continue

    if len(parts) != 5:
        scenario = parts[0] if len(parts) > 0 else ""
        platform = parts[1] if len(parts) > 1 else ""
        key = row_aliases.get((scenario, platform), (scenario, platform))
        if key in required_rows:
            rows[key] = ("__INVALID_COLUMN_COUNT__", "", "")
        continue

    scenario, platform, result, artifact_path, notes = parts[:5]
    key = row_aliases.get((scenario, platform), (scenario, platform))
    if key not in required_rows:
        continue

    artifact_path = artifact_path.strip("`").strip()
    rows[key] = (result, artifact_path, notes)

missing = []
invalid = []
for key in required_rows:
    row = rows.get(key)
    label = f"{key[0]} / {key[1]}"
    if row is None:
        missing.append(label)
        continue

    result, artifact_path, notes = row
    if result == "__INVALID_COLUMN_COUNT__":
        invalid.append(f"{label}: row must contain exactly five columns")
        continue
    if result not in {"Passed", "通过"}:
        invalid.append(f"{label}: result must be Passed or 通过")
    if allow_temp:
        if not (artifact_path.startswith("docs/phase-5-evidence/manual-") or artifact_path.startswith("/tmp/")):
            invalid.append(f"{label}: evidence path must be under docs/phase-5-evidence/manual-* or /tmp")
    elif not artifact_path.startswith("docs/phase-5-evidence/manual-"):
        invalid.append(f"{label}: evidence path must be under docs/phase-5-evidence/manual-*")

    if artifact_path and not any(fragment in f"{artifact_path}/" for fragment in expected_fragments[key]):
        invalid.append(f"{label}: evidence path must match the scenario/platform folder")
    if not artifact_path or not Path(artifact_path).is_file():
        invalid.append(f"{label}: missing evidence artifact")
    elif Path(artifact_path).stat().st_size <= 0:
        invalid.append(f"{label}: evidence artifact must not be empty")
    elif Path(artifact_path).suffix.lower() not in supported_artifact_extensions:
        invalid.append(f"{label}: evidence artifact file type is not supported")
    elif text_artifact_contains_sensitive_metadata(Path(artifact_path)):
        invalid.append(f"{label}: text evidence artifact contains sensitive photo metadata")
    if not notes or "TBD" in notes or "待补充" in notes or "|" in notes:
        invalid.append(f"{label}: notes must be concrete")
    elif notes_reference_personal_or_production_library(notes):
        invalid.append(f"{label}: notes must not reference personal or production Photos libraries")

if missing:
    raise SystemExit("missing Manual Photos Verification rows: " + "; ".join(missing))
if invalid:
    raise SystemExit("invalid Manual Photos Verification rows: " + "; ".join(invalid))
PY
then
  echo "Invalid Manual Photos Verification rows." >&2
  status=1
fi

while IFS= read -r manual_dir; do
  [[ -z "$manual_dir" ]] && continue
  if [[ "$allow_temp" -eq 0 && "$manual_dir" != docs/phase-5-evidence/manual-* ]]; then
    echo "Final evidence must reference project manual evidence, not temp manual evidence: $manual_dir" >&2
    status=1
    continue
  fi

  if [[ ! -d "$manual_dir" ]]; then
    echo "Missing manual evidence directory: $manual_dir" >&2
    status=1
    continue
  fi

  if ! scripts/check-phase-5-manual-evidence.sh "$manual_dir"; then
    echo "Manual evidence checker failed for: $manual_dir" >&2
    status=1
  else
    manual_evidence_count=$((manual_evidence_count + 1))
  fi
done < <(rg --only-matching --replace '$1' 'check-phase-5-manual-evidence\.sh[[:space:]]+((/tmp/[^ `|)]+)|docs/phase-5-evidence/manual-[^ `|)]+)' "$evidence_path" | sort -u)

if [[ "$manual_evidence_count" -eq 0 ]]; then
  echo "Missing manual evidence checker reference." >&2
  status=1
fi

if [[ "$status" -ne 0 ]]; then
  exit "$status"
fi

echo "Phase 5 evidence check passed: no unresolved placeholders or missing evidence files."
