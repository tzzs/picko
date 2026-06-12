#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/report-phase-5-status.sh [--evidence PATH] [--date YYYY-MM-DD] [--host-timestamp ID] [--fail-on-incomplete]

Reports the current Phase 5 evidence status without reading Photos libraries,
booting Simulator, importing media, or triggering delete requests.

Options:
  --evidence PATH       Inspect a specific final evidence document.
  --date YYYY-MM-DD     Date to use in generated macOS capture helper commands.
  --host-timestamp ID   Timestamp/id to use in generated host baseline commands.
  --fail-on-incomplete  Exit non-zero when required Phase 5 evidence is missing.
USAGE
}

evidence_path=""
capture_date="$(date +%Y-%m-%d)"
host_capture_timestamp="$(date +%Y%m%d-%H%M%S)"
fail_on_incomplete=0
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
    --fail-on-incomplete)
      fail_on_incomplete=1
      shift
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

missing=0
evidence_document_ready=1
environment_ready=1
ios_environment_ready=0
test_library_environment_ready=0
ios_benchmark_ready=1
runtime_privacy_ready=0
ios_benchmark_missing_counts=()
manual_missing_labels=()

pass() {
  printf '[ready] %s\n' "$1"
}

warn() {
  printf '[missing] %s\n' "$1"
  missing=1
}

info() {
  printf '[info] %s\n' "$1"
}

validate_photos_json() {
  local json_path="$1"
  python3 - "$json_path" <<'PY'
import json
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
report = json.loads(path.read_text())
mode = str(report.get("mode", ""))
if "photos" not in mode.lower() or "synthetic" in mode.lower():
    raise SystemExit(1)
library_label = str(report.get("photosLibraryLabel", ""))
library_label_lower = library_label.lower()
if not library_label or "non-production" not in library_label_lower:
    raise SystemExit(1)
sensitive_library_phrases = (
    "production personal",
    "personal photos",
    "personal library",
    "production photos",
    "production library",
)
if any(phrase in library_label_lower for phrase in sensitive_library_phrases):
    raise SystemExit(1)

rows = report.get("rows")
if not isinstance(rows, list):
    raise SystemExit(1)

by_count = {}
for row in rows:
    try:
        count = int(row["assetCount"])
        elapsed = float(row["elapsedSeconds"])
        rate = float(row["assetsPerSecond"])
    except (KeyError, TypeError, ValueError):
        raise SystemExit(1)
    if elapsed <= 0 or rate <= 0:
        raise SystemExit(1)
    by_count[count] = row

missing = [count for count in (1000, 10000, 50000) if count not in by_count]
if missing:
    raise SystemExit(1)
PY
}

ios_row_artifact_path() {
  local count_label="$1"
  local source_path="$2"
  python3 - "$count_label" "$source_path" <<'PY'
import sys
from pathlib import Path

count_label = sys.argv[1]
source_path = Path(sys.argv[2])

in_ios_section = False
ios_section_headers = {
    "## iOS Simulator Photos-Backed Benchmark",
    "## iOS Simulator Photos 支撑的 Benchmark",
    "## iOS 模拟器 Photos 支撑的基准测试",
}
for line in source_path.read_text().splitlines():
    if line.startswith("## "):
        in_ios_section = line.strip() in ios_section_headers
        continue

    if not in_ios_section:
        continue

    stripped = line.strip()
    if not stripped.startswith("|") or not stripped.endswith("|"):
        continue

    parts = [part.strip() for part in stripped.strip("|").split("|")]
    if len(parts) < 4 or parts[0] != count_label:
        continue

    try:
        float(parts[1].replace(",", ""))
        float(parts[2].replace(",", ""))
    except ValueError:
        continue

    artifact_path = parts[3].strip().strip("`").strip()
    if artifact_path.startswith("docs/phase-5-evidence/"):
        print(artifact_path)
        break
PY
}

has_ios_benchmark_row() {
  local count_label="$1"
  local source_path="$2"
  python3 - "$count_label" "$source_path" <<'PY'
import sys
from pathlib import Path

count_label = sys.argv[1]
source_path = Path(sys.argv[2])

in_ios_section = False
ios_section_headers = {
    "## iOS Simulator Photos-Backed Benchmark",
    "## iOS Simulator Photos 支撑的 Benchmark",
    "## iOS 模拟器 Photos 支撑的基准测试",
}
for line in source_path.read_text().splitlines():
    if line.startswith("## "):
        in_ios_section = line.strip() in ios_section_headers
        continue

    if not in_ios_section:
        continue

    stripped = line.strip()
    if not stripped.startswith("|") or not stripped.endswith("|"):
        continue

    parts = [part.strip() for part in stripped.strip("|").split("|")]
    if len(parts) < 4 or parts[0] != count_label:
        continue

    try:
        float(parts[1].replace(",", ""))
        float(parts[2].replace(",", ""))
    except ValueError:
        continue

    artifact_path = parts[3].strip().strip("`").strip()
    if artifact_path.startswith("docs/phase-5-evidence/"):
        raise SystemExit(0)

raise SystemExit(1)
PY
}

ios_benchmark_artifact_status() {
  local artifact_path="$1"
  local artifact_extension

  if [[ ! -f "$artifact_path" ]]; then
    printf 'missing\n'
    return
  fi

  if [[ ! -s "$artifact_path" ]]; then
    printf 'empty\n'
    return
  fi

  artifact_extension="${artifact_path##*.}"
  artifact_extension="$(printf '%s' "$artifact_extension" | tr '[:upper:]' '[:lower:]')"
  case "$artifact_extension" in
    png|jpg|jpeg|heic|mov|mp4)
      printf 'ready\n'
      ;;
    *)
      printf 'unsupported\n'
      ;;
  esac
}

has_passed_table_row() {
  local row_label="$1"
  local source_path="$2"
  rg --quiet "\\|[[:space:]]*$row_label[[:space:]]*\\|([^|]*\\|)?[[:space:]]*(Passed|通过)[[:space:]]*\\|[[:space:]]*[^|]*[^[:space:]|][[:space:]]*\\|" "$source_path"
}

has_any_passed_table_row() {
  local source_path="$1"
  shift

  local row_label
  for row_label in "$@"; do
    if has_passed_table_row "$row_label" "$source_path"; then
      return 0
    fi
  done

  return 1
}

has_manual_verification_row() {
  local scenario="$1"
  local platform="$2"
  local source_path="$3"
  python3 - "$scenario" "$platform" "$source_path" <<'PY'
import re
import sys
from pathlib import Path

scenario = sys.argv[1]
platform = sys.argv[2]
source_path = Path(sys.argv[3])
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

for line in source_path.read_text().splitlines():
    stripped = line.strip()
    if not stripped.startswith("|") or not stripped.endswith("|"):
        continue

    parts = [part.strip() for part in stripped.strip("|").split("|")]
    if len(parts) != 5:
        continue

    row_scenario, row_platform, result, artifact_path, notes = parts
    row_scenario, row_platform = row_aliases.get((row_scenario, row_platform), (row_scenario, row_platform))
    if row_scenario != scenario or row_platform != platform:
        continue

    artifact_path = artifact_path.strip("`").strip()
    if (
        result in {"Passed", "通过"}
        and artifact_path.startswith("docs/phase-5-evidence/manual-")
        and any(fragment in f"{artifact_path}/" for fragment in expected_fragments[(scenario, platform)])
        and Path(artifact_path).is_file()
        and Path(artifact_path).stat().st_size > 0
        and Path(artifact_path).suffix.lower() in supported_artifact_extensions
        and not text_artifact_contains_sensitive_metadata(Path(artifact_path))
        and notes
        and "TBD" not in notes
        and "待补充" not in notes
        and not notes_reference_personal_or_production_library(notes)
    ):
        raise SystemExit(0)

raise SystemExit(1)
PY
}

host_baseline_preflight_ready() {
  local source_path="$1"

  [[ -f "$source_path" ]] || return 1

  python3 - "$source_path" <<'PY'
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
    raise SystemExit(1)

section = "\n".join(host_section_lines)
has_passed_preflight = (
    ("Preflight status:" in section and "Passed" in section)
    or ("预检状态：" in section and "通过" in section)
)
if not has_passed_preflight:
    raise SystemExit(1)

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
        raise SystemExit(1)
    raise SystemExit(0)

raise SystemExit(1)
PY
}

environment_value() {
  local field_name="$1"
  local source_path="$2"
  python3 - "$field_name" "$source_path" <<'PY'
import sys
from pathlib import Path

field_name = sys.argv[1]
source_path = Path(sys.argv[2])
field_aliases = {
    "iOS Simulator": {"iOS Simulator", "iOS 模拟器"},
    "Test Photos Library": {"Test Photos Library", "测试照片图库"},
}
accepted_fields = field_aliases.get(field_name, {field_name})

for line in source_path.read_text().splitlines():
    parts = [part.strip() for part in line.strip().strip("|").split("|")]
    if len(parts) == 2 and parts[0] in accepted_fields:
        print(parts[1])
        break
PY
}

runtime_privacy_artifact_path() {
  local source_path="$1"
  python3 - "$source_path" <<'PY'
import re
import sys
from pathlib import Path

source_path = Path(sys.argv[1])
in_privacy_section = False
privacy_section_headers = {"## Privacy Review", "## 隐私审查"}
runtime_privacy_checks = {
    "Runtime logs checked for photo contents or sensitive metadata",
    "Runtime 日志已检查照片内容或敏感元数据",
    "运行时日志已检查照片内容或敏感元数据",
}

for line in source_path.read_text().splitlines():
    if line.startswith("## "):
        if in_privacy_section:
            break
        in_privacy_section = line.strip() in privacy_section_headers
        continue
    if not in_privacy_section:
        continue
    if not any(check in line for check in runtime_privacy_checks):
        continue
    if "audit-runtime-privacy-logs.sh" not in line:
        continue
    if "TBD" in line or "待补充" in line or "LOG_PATH" in line:
        continue

    match = re.search(r"docs/phase-5-evidence/privacy/[^ `|)]+", line)
    if match:
        print(match.group(0))
        break
PY
}

printf 'Picko Phase 5 Status\n'
printf 'Worktree: %s\n\n' "$(pwd)"

if [[ -n "$evidence_path" && -f "$evidence_path" ]]; then
  info "Final evidence document candidate: $evidence_path"
  if scripts/check-phase-5-evidence.sh "$evidence_path" >/tmp/picko-phase-5-evidence-check.log 2>&1; then
    pass "Final Phase 5 evidence document passes completeness check."
  else
    warn "Final Phase 5 evidence document is not complete. Details: /tmp/picko-phase-5-evidence-check.log"
  fi
else
  evidence_document_ready=0
  warn "No final evidence document found. Create one with scripts/create-phase-5-evidence.sh."
fi

if [[ -n "$evidence_path" && -f "$evidence_path" ]]; then
  ios_simulator_value="$(environment_value "iOS Simulator" "$evidence_path")"
  if [[ -n "$ios_simulator_value" && "$ios_simulator_value" != *"TBD"* && "$ios_simulator_value" != *"待补充"* ]]; then
    ios_environment_ready=1
    pass "Environment row has concrete value: iOS Simulator."
  else
    environment_ready=0
    warn "Environment row is missing concrete value: iOS Simulator."
  fi

  test_library_value="$(environment_value "Test Photos Library" "$evidence_path")"
  test_library_lower="$(printf '%s' "$test_library_value" | tr '[:upper:]' '[:lower:]')"
  if [[ -n "$test_library_value" \
    && "$test_library_value" != *"TBD"* \
    && "$test_library_value" != *"待补充"* \
    && ( "$test_library_lower" == *"non-production"* || "$test_library_value" == *"非生产"* ) \
    && "$test_library_lower" != *"production personal"* \
    && "$test_library_lower" != *"personal photos"* \
    && "$test_library_lower" != *"personal library"* \
    && "$test_library_lower" != *"production photos"* \
    && "$test_library_lower" != *"production library"* ]]; then
    test_library_environment_ready=1
    pass "Environment row has concrete non-production value: Test Photos Library."
  else
    environment_ready=0
    warn "Environment row is missing concrete non-production value: Test Photos Library."
  fi

  while IFS='|' read -r gate_name gate_alias; do
    if has_any_passed_table_row "$evidence_path" "$gate_name" "$gate_alias"; then
      pass "Automated gate is recorded as Passed: $gate_name."
    else
      warn "Automated gate is not recorded as Passed: $gate_name."
    fi
  done <<'GATE_ROWS'
Local Phase 5|本地 Phase 5
Platform Phase 5|平台 Phase 5
Privacy logging|隐私日志
GATE_ROWS

  while IFS='|' read -r privacy_check privacy_alias; do
    if has_any_passed_table_row "$evidence_path" "$privacy_check" "$privacy_alias"; then
      pass "Privacy review is recorded as Passed: $privacy_check."
    else
      warn "Privacy review is not recorded as Passed: $privacy_check."
    fi
  done <<'PRIVACY_ROWS'
Product code has no broad logging calls|产品代码没有宽泛日志调用
Thumbnail cache remains in process memory only|缩略图缓存仅保留在进程内存中
PRIVACY_ROWS

  while IFS='|' read -r scenario platform; do
    [[ -z "$scenario" || -z "$platform" ]] && continue
    if has_manual_verification_row "$scenario" "$platform" "$evidence_path"; then
      pass "Manual verification row has captured evidence: $scenario / $platform."
    else
      manual_missing_labels+=("$scenario / $platform")
      warn "Manual verification row is missing captured evidence: $scenario / $platform."
    fi
  done <<'MANUAL_ROWS'
First Photos authorization|iOS
Limited library state|iOS
Pre-delete basket triggers Photos confirmation|iOS
First Photos authorization|macOS
Pre-delete basket triggers Photos confirmation|macOS
Recently Deleted recovery explanation|iOS/macOS
MANUAL_ROWS
fi

baseline_ready=0
if [[ -n "$evidence_path" && -f "$evidence_path" ]]; then
  while IFS= read -r json_path; do
    [[ -z "$json_path" ]] && continue
    if [[ -f "$json_path" ]] && validate_photos_json "$json_path" >/dev/null 2>&1; then
      pass "Host Photos-backed 1k/10k/50k baseline JSON is referenced in final evidence: $json_path"
      baseline_ready=1
      break
    fi
  done < <(rg --only-matching --no-line-number 'docs/phase-5-evidence/[^ `|)]*\.json' "$evidence_path" | sort -u)
fi

if [[ "$baseline_ready" -eq 0 ]]; then
  if host_baseline_preflight_ready "$evidence_path"; then
    warn "Host Photos-backed 1k/10k/50k baseline JSON is missing from final evidence. Preflight is recorded as Passed; first run scripts/prepare-phase-5-host-baseline-capture.sh before capturing with the prepared non-production Mac Photos library. Explicit reproducibility: scripts/prepare-phase-5-host-baseline-capture.sh --evidence ${evidence_path:-docs/phase-5-evidence-YYYY-MM-DD.md} --label \"Non-production Mac Photos test library\" --timestamp $host_capture_timestamp --date $capture_date."
  else
    warn "Host Photos-backed 1k/10k/50k baseline JSON is missing from final evidence. Use a non-production Photos library, preflight with scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label \"Non-production Mac Photos test library\" --validate-only 1000 10000 50000, then run scripts/prepare-phase-5-host-baseline-capture.sh before capture and write-back. Explicit reproducibility: scripts/prepare-phase-5-host-baseline-capture.sh --evidence ${evidence_path:-docs/phase-5-evidence-YYYY-MM-DD.md} --label \"Non-production Mac Photos test library\" --timestamp $host_capture_timestamp --date $capture_date."
  fi
fi

ios_source="docs/Phase-5-Verification.md"
if [[ -n "$evidence_path" && -f "$evidence_path" ]]; then
  ios_source="$evidence_path"
fi

for count_label in "1,000" "10,000" "50,000"; do
  ios_artifact_path="$(ios_row_artifact_path "$count_label" "$ios_source")"
  if [[ -n "$ios_artifact_path" ]]; then
    ios_artifact_status="$(ios_benchmark_artifact_status "$ios_artifact_path")"
    case "$ios_artifact_status" in
      ready)
        pass "iOS Photos-backed benchmark row exists with local evidence for $count_label assets."
        ;;
      missing)
        ios_benchmark_ready=0
        ios_benchmark_missing_counts+=("$count_label")
        warn "iOS Photos-backed benchmark row references missing local evidence for $count_label assets: $ios_artifact_path"
        ;;
      empty)
        ios_benchmark_ready=0
        ios_benchmark_missing_counts+=("$count_label")
        warn "iOS Photos-backed benchmark row references empty local evidence for $count_label assets: $ios_artifact_path"
        ;;
      unsupported)
        ios_benchmark_ready=0
        ios_benchmark_missing_counts+=("$count_label")
        warn "iOS Photos-backed benchmark row references unsupported local evidence for $count_label assets: $ios_artifact_path"
        ;;
    esac
  elif has_ios_benchmark_row "$count_label" "$ios_source"; then
    ios_benchmark_ready=0
    ios_benchmark_missing_counts+=("$count_label")
    warn "iOS Photos-backed benchmark row is missing local evidence for $count_label assets."
  else
    ios_benchmark_ready=0
    ios_benchmark_missing_counts+=("$count_label")
    warn "iOS Photos-backed benchmark row is missing for $count_label assets."
  fi
done

manual_ready=0
manual_structure_ready=0
prepared_manual_dir="docs/phase-5-evidence/manual-$capture_date"
while IFS= read -r manual_dir; do
  [[ -z "$manual_dir" ]] && continue
  if scripts/check-phase-5-manual-evidence.sh "$manual_dir" >/dev/null 2>&1; then
    pass "Manual Photos evidence directory passes completeness check: $manual_dir"
    manual_ready=1
    break
  elif [[ "$manual_structure_ready" -eq 0 ]] && scripts/check-phase-5-manual-evidence.sh --structure-only "$manual_dir" >/dev/null 2>&1; then
    info "Manual Photos evidence structure is prepared but captured files are still missing: $manual_dir"
    manual_structure_ready=1
    prepared_manual_dir="$manual_dir"
  fi
done < <(find docs/phase-5-evidence -maxdepth 1 -type d -name 'manual-*' -print 2>/dev/null | sort -r)

if [[ "$manual_ready" -eq 0 ]]; then
  if [[ "$manual_structure_ready" -eq 0 ]]; then
    warn "Manual Photos evidence directory is missing. Prepare it with scripts/prepare-phase-5-manual-evidence.sh."
  elif [[ "${#manual_missing_labels[@]}" -gt 0 ]]; then
    printf -v manual_missing_joined '%s; ' "${manual_missing_labels[@]}"
    manual_missing_joined="${manual_missing_joined%; }"
    warn "Manual Photos evidence directory is incomplete for: $manual_missing_joined."
  else
    warn "Manual Photos evidence directory is incomplete. Capture non-production authorization/delete/privacy evidence into the prepared folders."
  fi
fi

runtime_privacy_line=""
runtime_privacy_artifact=""
if [[ -n "$evidence_path" && -f "$evidence_path" ]]; then
  runtime_privacy_line="$(rg 'Runtime logs checked for photo contents or sensitive metadata|Runtime 日志已检查照片内容或敏感元数据|运行时日志已检查照片内容或敏感元数据' "$evidence_path" || true)"
  runtime_privacy_artifact="$(runtime_privacy_artifact_path "$evidence_path")"
fi

if [[ "$runtime_privacy_line" == *"audit-runtime-privacy-logs.sh"* \
  && "$runtime_privacy_line" == *"docs/phase-5-evidence/"* \
  && "$runtime_privacy_line" != *"TBD"* \
  && "$runtime_privacy_line" != *"待补充"* \
  && "$runtime_privacy_line" != *"LOG_PATH"* \
  && -n "$runtime_privacy_artifact" \
  && -f "$runtime_privacy_artifact" \
  && -s "$runtime_privacy_artifact" ]] \
  && scripts/audit-runtime-privacy-logs.sh "$runtime_privacy_artifact" >/dev/null 2>&1; then
  pass "Runtime privacy log audit evidence is referenced in final evidence."
  runtime_privacy_ready=1
else
  warn "Runtime privacy log audit evidence is missing from final evidence."
fi

if [[ "$missing" -eq 0 ]]; then
  printf '\nNo remaining Phase 5 evidence gaps detected.\n'
  printf 'Confirm whole-plan completion with scripts/audit-mvp-next-completion.sh --plan docs/MVP-Next-Development-Plan.md --product-spec docs/MVP-Product-Spec.md --verification docs/Phase-5-Verification.md --runbook docs/Phase-5-External-Evidence-Runbook.md --evidence %s --manual-dir %s --handoff docs/phase-5-evidence/phase-5-external-handoff-%s.md --date %s --host-timestamp %s.\n' "${evidence_path:-docs/phase-5-evidence-YYYY-MM-DD.md}" "$prepared_manual_dir" "$capture_date" "$capture_date" "$host_capture_timestamp"
  printf 'The whole-plan audit covers the MVP plan, product spec, Phase 5 shell literal safety gate, evidence template coverage, runbook, handoff, evidence directory cleanliness, and evidence status together.\n'
else
  next_index=1
  printf '\nNext required external evidence:\n'
  printf 'For the default active-package command sequence, run scripts/phase-5-external-evidence-checklist.sh.\n'
  printf 'For explicit reproducibility, run scripts/phase-5-external-evidence-checklist.sh --evidence %s --manual-dir %s --date %s --host-timestamp %s.\n' "${evidence_path:-docs/phase-5-evidence-YYYY-MM-DD.md}" "${prepared_manual_dir:-docs/phase-5-evidence/manual-YYYY-MM-DD}" "$capture_date" "$host_capture_timestamp"
  if [[ "$evidence_document_ready" -eq 0 ]]; then
    printf '%d. Create the final Phase 5 evidence document with scripts/create-phase-5-evidence.sh.\n' "$next_index"
    next_index=$((next_index + 1))
  fi
  if [[ "$environment_ready" -eq 0 ]]; then
    if [[ "$ios_environment_ready" -eq 0 && "$test_library_environment_ready" -eq 0 ]]; then
      printf '%d. Record concrete iOS Simulator and non-production Photos library environment rows.\n' "$next_index"
    elif [[ "$ios_environment_ready" -eq 0 ]]; then
      printf '%d. Record concrete iOS Simulator environment row.\n' "$next_index"
    else
      printf '%d. Record concrete non-production Photos library environment row.\n' "$next_index"
    fi
    next_index=$((next_index + 1))
  fi
  if [[ "$baseline_ready" -eq 0 ]]; then
    printf '%d. Host Photos-backed baseline on a non-production Mac Photos library: run scripts/prepare-phase-5-host-baseline-capture.sh. Explicit reproducibility: scripts/prepare-phase-5-host-baseline-capture.sh --evidence %s --label "Non-production Mac Photos test library" --timestamp %s --date %s.\n' "$next_index" "${evidence_path:-docs/phase-5-evidence-YYYY-MM-DD.md}" "$host_capture_timestamp" "$capture_date"
    next_index=$((next_index + 1))
  fi
  if [[ "$ios_benchmark_ready" -eq 0 ]]; then
    printf -v ios_missing_joined '%s, ' "${ios_benchmark_missing_counts[@]}"
    ios_missing_joined="${ios_missing_joined%, }"
    printf '%d. iOS Simulator Photos-backed in-app benchmark evidence for missing rows or artifacts: %s assets.\n' "$next_index" "$ios_missing_joined"
    next_index=$((next_index + 1))
  fi
  if [[ "${#manual_missing_labels[@]}" -gt 0 ]]; then
    printf -v manual_missing_joined '%s; ' "${manual_missing_labels[@]}"
    manual_missing_joined="${manual_missing_joined%; }"
    printf '%d. Manual Photos verification evidence for: %s. For macOS captures, run scripts/prepare-phase-5-macos-manual-capture.sh. Explicit reproducibility: scripts/prepare-phase-5-macos-manual-capture.sh --manual-dir %s --evidence %s --date %s.\n' "$next_index" "$manual_missing_joined" "$prepared_manual_dir" "${evidence_path:-docs/phase-5-evidence-YYYY-MM-DD.md}" "$capture_date"
    next_index=$((next_index + 1))
  elif [[ "$manual_ready" -eq 0 ]]; then
    printf '%d. Complete the remaining files in the prepared manual evidence directory.\n' "$next_index"
    next_index=$((next_index + 1))
  fi
  if [[ "$runtime_privacy_ready" -eq 0 ]]; then
    printf '%d. Runtime privacy log evidence from non-production Photos runs.\n' "$next_index"
  fi
  printf 'After all rows and evidence files are written back, run scripts/finalize-phase-5-evidence.sh, then run scripts/audit-mvp-next-completion.sh.\n'
  printf 'For explicit finalization reproducibility, run scripts/finalize-phase-5-evidence.sh --evidence %s --date %s --host-timestamp %s, then run scripts/audit-mvp-next-completion.sh --plan docs/MVP-Next-Development-Plan.md --product-spec docs/MVP-Product-Spec.md --verification docs/Phase-5-Verification.md --runbook docs/Phase-5-External-Evidence-Runbook.md --evidence %s --manual-dir %s --handoff docs/phase-5-evidence/phase-5-external-handoff-%s.md --date %s --host-timestamp %s.\n' "${evidence_path:-docs/phase-5-evidence-YYYY-MM-DD.md}" "$capture_date" "$host_capture_timestamp" "${evidence_path:-docs/phase-5-evidence-YYYY-MM-DD.md}" "$prepared_manual_dir" "$capture_date" "$capture_date" "$host_capture_timestamp"
  printf 'The whole-plan audit covers the MVP plan, product spec, Phase 5 shell literal safety gate, evidence template coverage, runbook, handoff, evidence directory cleanliness, and evidence status together.\n'
fi

if [[ "$missing" -ne 0 && "$fail_on_incomplete" -ne 0 ]]; then
  exit 1
fi
