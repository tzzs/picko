#!/usr/bin/env bash
set -euo pipefail

export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-/private/tmp/picko-clang-module-cache}"
mkdir -p "$CLANG_MODULE_CACHE_PATH"

cleanup_project_smoke_artifacts() {
  rm -f \
    docs/phase-5-evidence/host-baseline-smoke.json \
    docs/phase-5-evidence/metadata-baseline-photos-1000-10000-50000-checklist-existing-json.json \
    docs/phase-5-evidence/metadata-baseline-photos-1000-10000-50000-readiness-existing-json.json \
    docs/phase-5-evidence/metadata-baseline-photos-1000-10000-50000-generator-smoke.json \
    docs/phase-5-evidence/metadata-baseline-photos-1000-10000-50000-generator-partial-smoke.json \
    docs/phase-5-evidence/photos-baseline-generator-smoke.json \
    docs/phase-5-evidence/metadata-baseline-photos-1000-10000-50000-host-smoke.json \
    docs/phase-5-evidence/metadata-baseline-photos-1000-10000-50000-synthetic-smoke.json \
    docs/phase-5-evidence/status-complete-baseline-smoke.json \
    docs/phase-5-evidence/status-stray-baseline-smoke.json \
    docs/phase-5-evidence/ios-metadata-benchmark/empty-artifact-smoke.jpg \
    docs/phase-5-evidence/ios-metadata-benchmark/final-checker-unsupported-smoke.txt \
    docs/phase-5-evidence/ios-metadata-benchmark/unsupported-artifact-smoke.txt \
    docs/phase-5-evidence/privacy/runtime-smoke.log \
    docs/phase-5-evidence/privacy/status-complete-empty-runtime-smoke.log \
    docs/phase-5-evidence/privacy/status-complete-runtime-smoke.log \
    docs/phase-5-evidence/privacy/status-complete-sensitive-runtime-smoke.log \
    docs/phase-5-evidence/privacy/status-empty-runtime-smoke.log \
    docs/phase-5-evidence/privacy/status-sensitive-runtime-smoke.log \
    docs/phase-5-evidence/privacy/status-wrong-section-runtime-smoke.log

  for smoke_dir in \
    docs/phase-5-evidence/manual-smoke \
    docs/phase-5-evidence/manual-status-bad-notes-smoke \
    docs/phase-5-evidence/manual-status-complete-smoke \
    docs/phase-5-evidence/manual-status-directory-smoke \
    docs/phase-5-evidence/manual-status-empty-smoke \
    docs/phase-5-evidence/manual-status-failed-smoke \
    docs/phase-5-evidence/manual-status-mismatch-smoke \
    docs/phase-5-evidence/manual-status-sensitive-content-smoke \
    docs/phase-5-evidence/manual-status-unsupported-smoke \
    docs/phase-5-evidence/manual-unsupported-smoke \
    docs/phase-5-evidence/status-complete-ios \
    docs/phase-5-evidence/status-ios-smoke
  do
    rm -rf "$smoke_dir"
  done
}

cleanup_project_smoke_artifacts
trap cleanup_project_smoke_artifacts EXIT

echo "== Bash syntax =="
bash -n scripts/audit-privacy-logging.sh
bash -n scripts/audit-mvp-next-completion.sh
bash -n scripts/audit-runtime-privacy-logs.sh
bash -n scripts/capture-metadata-baseline.sh
bash -n scripts/check-phase-5-external-evidence-readiness.sh
bash -n scripts/check-phase-5-external-handoff.sh
bash -n scripts/check-phase-5-evidence-cleanliness.sh
bash -n scripts/check-phase-5-evidence-template.sh
bash -n scripts/check-phase-5-external-runbook.sh
bash -n scripts/check-phase-5-shell-literal-safety.sh
bash -n scripts/check-phase-5-verification-doc.sh
bash -n scripts/create-phase-5-external-evidence-handoff.sh
bash -n scripts/import-simulator-photos-fixture-chunked.sh
bash -n scripts/prepare-phase-5-host-baseline-capture.sh
bash -n scripts/prepare-phase-5-manual-evidence.sh
bash -n scripts/prepare-phase-5-macos-manual-capture.sh
bash -n scripts/check-phase-5-manual-evidence.sh
bash -n scripts/seed-simulator-photos-fixture.sh
bash -n scripts/create-phase-5-evidence.sh
bash -n scripts/check-phase-5-evidence.sh
bash -n scripts/report-phase-5-status.sh
bash -n scripts/phase-5-external-evidence-checklist.sh
bash -n scripts/finalize-phase-5-evidence.sh
bash -n scripts/record-runtime-privacy-evidence.sh
bash -n scripts/record-phase-5-completeness-gates.sh
bash -n scripts/report-mvp-next-development-status.sh
bash -n scripts/update-phase-5-host-baseline.sh
bash -n scripts/update-phase-5-ios-benchmark.sh
bash -n scripts/update-phase-5-environment.sh
bash -n scripts/update-phase-5-gate.sh
bash -n scripts/update-phase-5-manual-verification.sh
bash -n scripts/update-phase-5-privacy-review.sh
bash -n scripts/verify-phase-5-platform.sh

echo "== External evidence runbook smoke =="
scripts/check-phase-5-shell-literal-safety.sh
scripts/check-phase-5-evidence-cleanliness.sh docs/phase-5-evidence
cleanliness_root_only_dir="/tmp/picko-phase-5-cleanliness-smoke-root-only"
rm -rf "$cleanliness_root_only_dir"
mkdir -p "$cleanliness_root_only_dir"
scripts/check-phase-5-evidence-cleanliness.sh "$cleanliness_root_only_dir" >/dev/null
rm -rf "$cleanliness_root_only_dir"
cleanliness_bad_dir="/tmp/picko-phase-5-cleanliness-smoke"
rm -rf "$cleanliness_bad_dir"
mkdir -p "$cleanliness_bad_dir/manual-smoke/ios/authorization"
printf 'local smoke artifact\n' > "$cleanliness_bad_dir/manual-smoke/ios/authorization/evidence.txt"
if scripts/check-phase-5-evidence-cleanliness.sh "$cleanliness_bad_dir" >/dev/null; then
  echo "Phase 5 evidence cleanliness checker accepted a smoke artifact." >&2
  exit 1
fi
rm -rf "$cleanliness_bad_dir"
literal_safety_bad_script="/tmp/picko-phase-5-literal-safety-bad-$$.sh"
{
  printf '%s\n' "required_patterns=("
  printf '  "%sscripts/finalize-phase-5-evidence.sh%s followed by %sscripts/audit-mvp-next-completion.sh%s"\n' '`' '`' '`' '`'
  printf '%s\n' ")"
} > "$literal_safety_bad_script"
if scripts/check-phase-5-shell-literal-safety.sh "$literal_safety_bad_script" >/dev/null; then
  echo "Phase 5 shell literal safety accepted raw backticks in required_patterns." >&2
  exit 1
fi
literal_safety_good_script="/tmp/picko-phase-5-literal-safety-good-$$.sh"
cat > "$literal_safety_good_script" <<'SH'
required_patterns=(
  "Evidence: \`docs/phase-5-evidence.md\`"
)
SH
scripts/check-phase-5-shell-literal-safety.sh "$literal_safety_good_script" >/dev/null
scripts/check-phase-5-verification-doc.sh docs/Phase-5-Verification.md
scripts/check-phase-5-evidence-template.sh docs/Phase-5-Evidence-Template.md
template_legacy_host_capture="/tmp/picko-phase-5-template-legacy-host-capture-$$.md"
cp docs/Phase-5-Evidence-Template.md "$template_legacy_host_capture"
python3 - "$template_legacy_host_capture" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
source = path.read_text()
source = source.replace(
    'scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production Mac Photos test library" --timestamp YYYYMMDD-HHMMSS 1000 10000 50000',
    'scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production Mac Photos test library" 1000 10000 50000',
)
path.write_text(source)
PY
if scripts/check-phase-5-evidence-template.sh "$template_legacy_host_capture" >/dev/null; then
  echo "Phase 5 evidence template checker accepted legacy host capture without --timestamp." >&2
  exit 1
fi
template_bad_macos_order="/tmp/picko-phase-5-template-bad-macos-order-$$.md"
cp docs/Phase-5-Evidence-Template.md "$template_bad_macos_order"
python3 - "$template_bad_macos_order" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
source = path.read_text()
old = """scripts/prepare-phase-5-manual-evidence.sh
scripts/prepare-phase-5-macos-manual-capture.sh
scripts/prepare-phase-5-macos-manual-capture.sh --manual-dir docs/phase-5-evidence/manual-YYYY-MM-DD --evidence docs/phase-5-evidence-YYYY-MM-DD.md --date YYYY-MM-DD
scripts/check-phase-5-manual-evidence.sh docs/phase-5-evidence/manual-YYYY-MM-DD"""
new = """scripts/prepare-phase-5-manual-evidence.sh
scripts/check-phase-5-manual-evidence.sh docs/phase-5-evidence/manual-YYYY-MM-DD
scripts/prepare-phase-5-macos-manual-capture.sh
scripts/prepare-phase-5-macos-manual-capture.sh --manual-dir docs/phase-5-evidence/manual-YYYY-MM-DD --evidence docs/phase-5-evidence-YYYY-MM-DD.md --date YYYY-MM-DD"""
if old not in source:
    raise SystemExit("manual command block not found")
path.write_text(source.replace(old, new))
PY
if scripts/check-phase-5-evidence-template.sh "$template_bad_macos_order" >/dev/null; then
  echo "Phase 5 evidence template checker accepted macOS manual commands in the wrong order." >&2
  exit 1
fi
if scripts/audit-mvp-next-completion.sh \
  --plan docs/MVP-Next-Development-Plan.md \
  --product-spec docs/MVP-Product-Spec.md \
  --verification docs/Phase-5-Verification.md \
  --runbook docs/Phase-5-External-Evidence-Runbook.md \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --handoff docs/phase-5-evidence/phase-5-external-handoff-2026-06-03.md \
  --date 2026-06-03 \
  --host-timestamp 20260603-photos-baseline >/tmp/picko-mvp-next-completion-audit-smoke.log; then
  echo "MVP Next completion audit accepted incomplete Phase 5 evidence." >&2
  exit 1
fi
for expected_text in \
  "Picko MVP Next Completion Audit" \
  "Verification document coverage" \
  "Evidence template coverage" \
  "Phase 5 shell literal safety" \
  "External evidence runbook coverage" \
  "External evidence readiness" \
  "External evidence handoff freshness" \
  "Phase 5 evidence directory cleanliness" \
  "Phase 5 status has no remaining gaps" \
  "Final Phase 5 evidence completeness" \
  "MVP Next whole-plan completion" \
  "MVP Next completion audit failed"
do
  if ! grep -q "$expected_text" /tmp/picko-mvp-next-completion-audit-smoke.log; then
    echo "MVP Next completion audit is missing expected text: $expected_text" >&2
    exit 1
  fi
done
if scripts/audit-mvp-next-completion.sh >/tmp/picko-mvp-next-completion-audit-default-smoke.log; then
  echo "Default MVP Next completion audit accepted incomplete Phase 5 evidence." >&2
  exit 1
fi
for expected_text in \
  "Evidence: docs/phase-5-evidence-2026-05-31.md" \
  "Manual evidence: docs/phase-5-evidence/manual-2026-05-31" \
  "External handoff: docs/phase-5-evidence/phase-5-external-handoff-2026-06-03.md" \
  "Host timestamp: 20260603-photos-baseline" \
  "MVP Next completion audit failed"
do
  if ! grep -q "$expected_text" /tmp/picko-mvp-next-completion-audit-default-smoke.log; then
    echo "Default MVP Next completion audit is missing expected text: $expected_text" >&2
    exit 1
  fi
done
if grep -q "Evidence: docs/phase-5-evidence-2026-06-03.md" /tmp/picko-mvp-next-completion-audit-default-smoke.log; then
  echo "Default MVP Next completion audit ignored the active evidence package." >&2
  exit 1
fi
scripts/check-phase-5-external-runbook.sh docs/Phase-5-External-Evidence-Runbook.md
scripts/check-phase-5-external-evidence-readiness.sh \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --runbook docs/Phase-5-External-Evidence-Runbook.md \
  --label "Non-production Mac Photos test library" \
  --date 2026-06-03 \
  --host-timestamp readiness-host-smoke
readiness_legacy_host_evidence="/tmp/picko-phase-5-readiness-legacy-host.md"
cp docs/phase-5-evidence-2026-05-31.md "$readiness_legacy_host_evidence"
python3 - "$readiness_legacy_host_evidence" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
source = path.read_text()
source = source.replace(
    'scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production Mac Photos test library" --timestamp 20260603-photos-baseline 1000 10000 50000',
    'scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production Mac Photos test library" 1000 10000 50000',
)
path.write_text(source)
PY
if scripts/check-phase-5-external-evidence-readiness.sh \
  --evidence "$readiness_legacy_host_evidence" \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --runbook docs/Phase-5-External-Evidence-Runbook.md \
  --label "Non-production Mac Photos test library" \
  --date 2026-06-03 \
  --host-timestamp 20260603-photos-baseline >/dev/null; then
  echo "Phase 5 external evidence readiness accepted legacy host capture without --timestamp." >&2
  exit 1
fi
readiness_missing_macos_helper_evidence="/tmp/picko-phase-5-readiness-missing-macos-helper.md"
cp docs/phase-5-evidence-2026-05-31.md "$readiness_missing_macos_helper_evidence"
python3 - "$readiness_missing_macos_helper_evidence" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
lines = [
    line for line in path.read_text().splitlines()
    if "prepare-phase-5-macos-manual-capture.sh" not in line
]
path.write_text("\n".join(lines) + "\n")
PY
if scripts/check-phase-5-external-evidence-readiness.sh \
  --evidence "$readiness_missing_macos_helper_evidence" \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --runbook docs/Phase-5-External-Evidence-Runbook.md \
  --label "Non-production Mac Photos test library" \
  --date 2026-06-03 \
  --host-timestamp 20260603-photos-baseline >/dev/null; then
  echo "Phase 5 external evidence readiness accepted evidence missing the macOS manual capture helper." >&2
  exit 1
fi
macos_helper_validate_only_dir="/tmp/picko-phase-5-macos-helper-validate-only-$$"
scripts/prepare-phase-5-manual-evidence.sh --output "$macos_helper_validate_only_dir" >/dev/null
rm -rf "$macos_helper_validate_only_dir/macos"
scripts/prepare-phase-5-macos-manual-capture.sh \
  --validate-only \
  --manual-dir "$macos_helper_validate_only_dir" \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --date 2026-06-03 >/dev/null
if [[ -d "$macos_helper_validate_only_dir/macos" ]]; then
  echo "macOS manual capture helper --validate-only created capture directories." >&2
  exit 1
fi
rm -rf "$macos_helper_validate_only_dir"
if scripts/check-phase-5-external-evidence-readiness.sh \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --runbook docs/Phase-5-External-Evidence-Runbook.md \
  --label "Production personal Photos library" \
  --date 2026-06-03 \
  --host-timestamp readiness-host-smoke >/dev/null; then
  echo "Phase 5 external evidence readiness accepted a production/personal Photos label." >&2
  exit 1
fi
if scripts/check-phase-5-external-evidence-readiness.sh \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --runbook docs/Phase-5-External-Evidence-Runbook.md \
  --label "Non-production Mac Photos test library" \
  --date 2026-06-03 \
  --host-timestamp "bad/path" >/dev/null; then
  echo "Phase 5 external evidence readiness accepted a non filename-safe host timestamp." >&2
  exit 1
fi
readiness_existing_json="docs/phase-5-evidence/metadata-baseline-photos-1000-10000-50000-readiness-existing-json.json"
printf '{"existing":true}\n' > "$readiness_existing_json"
readiness_existing_json_log="/tmp/picko-phase-5-readiness-existing-json.log"
if scripts/check-phase-5-external-evidence-readiness.sh \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --runbook docs/Phase-5-External-Evidence-Runbook.md \
  --label "Non-production Mac Photos test library" \
  --date 2026-06-03 \
  --host-timestamp readiness-existing-json >"$readiness_existing_json_log" 2>&1; then
  echo "Phase 5 external evidence readiness accepted a pre-existing host baseline JSON target path." >&2
  exit 1
fi
if ! grep -q "Host baseline JSON target already exists" "$readiness_existing_json_log"; then
  echo "Phase 5 external evidence readiness failed for the wrong reason when host baseline JSON already exists." >&2
  cat "$readiness_existing_json_log" >&2
  exit 1
fi
rm -f "$readiness_existing_json"
readiness_existing_artifact_dir="/tmp/picko-phase-5-readiness-existing-artifact"
rm -rf "$readiness_existing_artifact_dir"
scripts/prepare-phase-5-manual-evidence.sh --output "$readiness_existing_artifact_dir" >/dev/null
mkdir -p "$readiness_existing_artifact_dir/macos/authorization"
printf 'existing capture\n' > "$readiness_existing_artifact_dir/macos/authorization/macos-first-photos-authorization-2026-06-03.png"
if scripts/check-phase-5-external-evidence-readiness.sh \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --manual-dir "$readiness_existing_artifact_dir" \
  --runbook docs/Phase-5-External-Evidence-Runbook.md \
  --label "Non-production Mac Photos test library" \
  --date 2026-06-03 \
  --host-timestamp readiness-host-smoke >/dev/null; then
  echo "Phase 5 external evidence readiness accepted a pre-existing macOS capture artifact path." >&2
  exit 1
fi
rm -rf "$readiness_existing_artifact_dir"
readiness_extra_gap_evidence="/tmp/picko-phase-5-readiness-extra-gap.md"
python3 - docs/phase-5-evidence-2026-05-31.md "$readiness_extra_gap_evidence" <<'PY'
import sys
from pathlib import Path

source = Path(sys.argv[1])
target = Path(sys.argv[2])
text = source.read_text()
text = text.replace(
    "| iOS Simulator | iPhone 17 Pro, iOS 26.5 Simulator, id 0CF79391-989B-47A5-B853-1422340684F8; platform/UI smoke verified; Photos-backed 1k/10k/50k benchmark evidence captured |",
    "| iOS Simulator | TBD |",
)
target.write_text(text)
PY
if scripts/check-phase-5-external-evidence-readiness.sh \
  --evidence "$readiness_extra_gap_evidence" \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --runbook docs/Phase-5-External-Evidence-Runbook.md \
  --label "Non-production Mac Photos test library" \
  --date 2026-06-03 \
  --host-timestamp readiness-host-smoke >/dev/null; then
  echo "Phase 5 external evidence readiness accepted evidence with an extra environment gap." >&2
  exit 1
fi
mvp_status_smoke="/tmp/picko-mvp-next-status-smoke.log"
mvp_status_default_smoke="/tmp/picko-mvp-next-status-default-smoke.log"
scripts/report-mvp-next-development-status.sh > "$mvp_status_default_smoke"
for expected_text in \
  "Phase 5 evidence document exists: docs/phase-5-evidence-2026-05-31.md" \
  "Phase 5 manual evidence directory exists: docs/phase-5-evidence/manual-2026-05-31" \
  "External evidence readiness preflight passes" \
  "External evidence handoff is current: docs/phase-5-evidence/phase-5-external-handoff-2026-06-03.md" \
  "timestamp 20260603-photos-baseline"
do
  if ! grep -q "$expected_text" "$mvp_status_default_smoke"; then
    echo "MVP Next default status report is missing expected text: $expected_text" >&2
    exit 1
  fi
done
if grep -q "Phase 5 evidence document is missing: docs/phase-5-evidence-2026-06-03.md" "$mvp_status_default_smoke"; then
  echo "MVP Next default status report ignored the latest existing evidence document." >&2
  exit 1
fi
scripts/report-mvp-next-development-status.sh \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --handoff docs/phase-5-evidence/phase-5-external-handoff-2026-06-03.md \
  --date 2026-06-03 \
  --host-timestamp 20260603-photos-baseline > "$mvp_status_smoke"
for expected_text in \
  "Picko MVP Next Development Status" \
  "Photos Adapter phase completion is recorded" \
  "Core Hardening phase completion is recorded" \
  "iOS MVP phase completion is recorded" \
  "macOS MVP phase completion is recorded" \
  "Phase 5 in-progress state is recorded" \
  "Plan SwiftData first-version persistence decision is recorded" \
  "Plan default operator command guidance is recorded" \
  "Plan default Phase 5 status command is recorded" \
  "Plan default external evidence checklist command is recorded" \
  "Plan default host baseline helper command is recorded" \
  "Plan default macOS manual capture helper command is recorded" \
  "Plan default handoff generation command is recorded" \
  "Plan default handoff check command is recorded" \
  "Plan default finalizer command is recorded" \
  "Plan default whole-plan audit command is recorded" \
  "Repository guidelines default operator command guidance is recorded" \
  "Repository guidelines default Phase 5 status command is recorded" \
  "Repository guidelines default external evidence checklist command is recorded" \
  "Repository guidelines default host baseline helper command is recorded" \
  "Repository guidelines default macOS manual capture helper command is recorded" \
  "Repository guidelines default handoff generation command is recorded" \
  "Repository guidelines default handoff check command is recorded" \
  "Repository guidelines default finalizer command is recorded" \
  "Repository guidelines default whole-plan audit command is recorded" \
  "Product spec SwiftData first-version persistence decision is recorded" \
  "Product spec JSON storage boundary is recorded" \
  "Host Photos-backed baseline gap is recorded" \
  "macOS manual evidence gap is recorded" \
  "PickoCore target exists" \
  "External evidence readiness preflight passes" \
  "External evidence handoff is current" \
  "Phase 5 evidence directory cleanliness passes" \
  "MVP Next Development Plan is still waiting on Phase 5 external evidence" \
  "MVP Next Development Plan status: incomplete"
do
  if ! grep -q "$expected_text" "$mvp_status_smoke"; then
    echo "MVP Next status report is missing expected text: $expected_text" >&2
    exit 1
  fi
done
if scripts/report-mvp-next-development-status.sh \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --handoff docs/phase-5-evidence/phase-5-external-handoff-2026-06-03.md \
  --date 2026-06-03 \
  --host-timestamp 20260603-photos-baseline \
  --fail-on-incomplete >/dev/null; then
  echo "MVP Next status report accepted incomplete Phase 5 evidence with --fail-on-incomplete." >&2
  exit 1
fi
mvp_stale_plan="/tmp/picko-mvp-next-stale-plan-smoke.md"
python3 - docs/MVP-Next-Development-Plan.md "$mvp_stale_plan" <<'PY'
import sys
from pathlib import Path

source = Path(sys.argv[1])
target = Path(sys.argv[2])
text = source.read_text()
text = text.replace("host Photos-backed 真实基线仍待采集", "host Photos-backed 真实基线已采集")
text = text.replace("macOS 手工截图仍待采集", "macOS 手工截图已采集")
target.write_text(text)
PY
if scripts/report-mvp-next-development-status.sh \
  --plan "$mvp_stale_plan" \
  --product-spec docs/MVP-Product-Spec.md \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --handoff docs/phase-5-evidence/phase-5-external-handoff-2026-06-03.md \
  --date 2026-06-03 \
  --host-timestamp 20260603-photos-baseline \
  --fail-on-incomplete >/dev/null; then
  echo "MVP Next status report accepted a stale plan that omitted remaining Phase 5 gaps." >&2
  exit 1
fi
mvp_stale_product_spec="/tmp/picko-mvp-next-stale-product-spec-smoke.md"
python3 - docs/MVP-Product-Spec.md "$mvp_stale_product_spec" <<'PY'
import sys
from pathlib import Path

source = Path(sys.argv[1])
target = Path(sys.argv[2])
text = source.read_text()
text = text.replace("第一版确认使用 SwiftData，不采用纯 JSON 轻量文件作为主存储。", "第一版本地存储方案待定。")
text = text.replace("JSON 仍可用于 benchmark report、evidence、导入导出或调试快照，但不作为第一版用户整理状态的权威存储。", "JSON 可作为第一版用户整理状态存储。")
target.write_text(text)
PY
if scripts/report-mvp-next-development-status.sh \
  --plan docs/MVP-Next-Development-Plan.md \
  --product-spec "$mvp_stale_product_spec" \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --handoff docs/phase-5-evidence/phase-5-external-handoff-2026-06-03.md \
  --date 2026-06-03 \
  --host-timestamp 20260603-photos-baseline \
  --fail-on-incomplete >/dev/null; then
  echo "MVP Next status report accepted a product spec that omitted the SwiftData/JSON persistence decision." >&2
  exit 1
fi
handoff_smoke="/tmp/picko-phase-5-external-handoff-smoke.md"
scripts/create-phase-5-external-evidence-handoff.sh \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --runbook docs/Phase-5-External-Evidence-Runbook.md \
  --label "Non-production Mac Photos test library" \
  --date 2026-06-03 \
  --host-timestamp handoff-host-smoke \
  --output "$handoff_smoke" >/tmp/picko-phase-5-external-handoff-create.log
for expected_text in \
  "Picko Phase 5 External Evidence Handoff" \
  "Phase 5 external evidence readiness check passed." \
  "Host Photos-backed baseline on a non-production Mac Photos library: run scripts/prepare-phase-5-host-baseline-capture.sh. Explicit reproducibility:" \
  "Manual Photos verification evidence for: First Photos authorization / macOS; Pre-delete basket triggers Photos confirmation / macOS" \
  "For macOS captures, run scripts/prepare-phase-5-macos-manual-capture.sh. Explicit reproducibility:" \
  "First print the active-package capture guide:" \
  "Suggested macOS capture guide before opening the relevant system prompt:" \
  "Completion Claim Boundary" \
  "Do not mark Phase 5 or the MVP Next Development Plan complete until the host Photos-backed 1k/10k/50k baseline JSON is captured from a prepared non-production Mac Photos library and written back to the evidence document." \
  "Do not mark Phase 5 or the MVP Next Development Plan complete until both macOS manual evidence artifacts are captured from a non-production Mac Photos library and written back to the evidence document." \
  "The only completion proof is a passing finalizer followed by a passing whole-plan audit." \
  "After capturing delete-confirmation evidence, press Escape or click Cancel to dismiss the system confirmation without deleting assets." \
  "metadata-baseline-photos-1000-10000-50000-handoff-host-smoke.json" \
  "scripts/finalize-phase-5-evidence.sh --evidence docs/phase-5-evidence-2026-05-31.md --date 2026-06-03 --host-timestamp handoff-host-smoke" \
  "This audit also covers the Phase 5 shell literal safety gate" \
  "evidence template coverage" \
  "handoff freshness, evidence directory cleanliness" \
  "final evidence completeness, and the MVP plan/spec status" \
  "scripts/audit-mvp-next-completion.sh --plan docs/MVP-Next-Development-Plan.md --product-spec docs/MVP-Product-Spec.md --verification docs/Phase-5-Verification.md --runbook docs/Phase-5-External-Evidence-Runbook.md --evidence docs/phase-5-evidence-2026-05-31.md --manual-dir docs/phase-5-evidence/manual-2026-05-31 --handoff $handoff_smoke --date 2026-06-03 --host-timestamp handoff-host-smoke" \
  "This handoff was generated by a read-only script"
do
  if ! grep -q -- "$expected_text" "$handoff_smoke"; then
    echo "Phase 5 external evidence handoff is missing expected text: $expected_text" >&2
    exit 1
  fi
done
if grep -q "YYYYMMDD-HHMMSS" "$handoff_smoke"; then
  echo "Phase 5 external evidence handoff emitted a placeholder host timestamp." >&2
  exit 1
fi
handoff_default_smoke="/tmp/picko-phase-5-external-handoff-default-smoke.md"
scripts/create-phase-5-external-evidence-handoff.sh \
  --output "$handoff_default_smoke" >/tmp/picko-phase-5-external-handoff-default-create.log
for expected_text in \
  'Date: 2026-06-03' \
  'Evidence: `docs/phase-5-evidence-2026-05-31.md`' \
  'Manual evidence directory: `docs/phase-5-evidence/manual-2026-05-31`' \
  'Host baseline timestamp: `20260603-photos-baseline`' \
  "Host Photos-backed baseline on a non-production Mac Photos library: run scripts/prepare-phase-5-host-baseline-capture.sh. Explicit reproducibility:" \
  "For macOS captures, run scripts/prepare-phase-5-macos-manual-capture.sh. Explicit reproducibility:" \
  'metadata-baseline-photos-1000-10000-50000-20260603-photos-baseline.json' \
  "scripts/finalize-phase-5-evidence.sh --evidence docs/phase-5-evidence-2026-05-31.md --date 2026-06-03 --host-timestamp 20260603-photos-baseline" \
  "scripts/audit-mvp-next-completion.sh --plan docs/MVP-Next-Development-Plan.md --product-spec docs/MVP-Product-Spec.md --verification docs/Phase-5-Verification.md --runbook docs/Phase-5-External-Evidence-Runbook.md --evidence docs/phase-5-evidence-2026-05-31.md --manual-dir docs/phase-5-evidence/manual-2026-05-31 --handoff $handoff_default_smoke --date 2026-06-03 --host-timestamp 20260603-photos-baseline"
do
  if ! grep -q -- "$expected_text" "$handoff_default_smoke"; then
    echo "Default Phase 5 external evidence handoff is missing expected text: $expected_text" >&2
    exit 1
  fi
done
if grep -Eq "metadata-baseline-photos-1000-10000-50000-[0-9]{8}-[0-9]{6}[.]json" "$handoff_default_smoke"; then
  echo "Default Phase 5 external evidence handoff used a fresh timestamp instead of the latest handoff timestamp." >&2
  exit 1
fi
if scripts/create-phase-5-external-evidence-handoff.sh \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --runbook docs/Phase-5-External-Evidence-Runbook.md \
  --label "Non-production Mac Photos test library" \
  --date 2026-06-03 \
  --host-timestamp handoff-host-smoke >/dev/null; then
  echo "Phase 5 external evidence handoff accepted a missing --output path." >&2
  exit 1
fi
if scripts/create-phase-5-external-evidence-handoff.sh \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --runbook docs/Phase-5-External-Evidence-Runbook.md \
  --label "Non-production Mac Photos test library" \
  --date 2026-06-03 \
  --host-timestamp "bad/path" \
  --output "$handoff_smoke" >/dev/null; then
  echo "Phase 5 external evidence handoff accepted a non filename-safe host timestamp." >&2
  exit 1
fi
scripts/check-phase-5-external-handoff.sh \
  --handoff "$handoff_smoke" \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --date 2026-06-03 \
  --host-timestamp handoff-host-smoke
scripts/check-phase-5-external-handoff.sh \
  --handoff "$handoff_smoke" \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31
scripts/check-phase-5-external-handoff.sh
if scripts/check-phase-5-external-handoff.sh \
  --handoff "$handoff_smoke" \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --date 2026-06-03 \
  --host-timestamp wrong-host-smoke >/dev/null; then
  echo "Phase 5 external evidence handoff checker accepted a mismatched host timestamp." >&2
  exit 1
fi
handoff_placeholder_smoke="/tmp/picko-phase-5-external-handoff-placeholder-smoke.md"
cp "$handoff_smoke" "$handoff_placeholder_smoke"
printf '\nTBD\n' >> "$handoff_placeholder_smoke"
if scripts/check-phase-5-external-handoff.sh \
  --handoff "$handoff_placeholder_smoke" \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --date 2026-06-03 \
  --host-timestamp handoff-host-smoke >/dev/null; then
  echo "Phase 5 external evidence handoff checker accepted a placeholder handoff." >&2
  exit 1
fi

echo "== Privacy logging audit =="
scripts/audit-privacy-logging.sh
printf 'Metadata Benchmark completed without sensitive details.\n' > /tmp/picko-runtime-log-smoke.log
scripts/audit-runtime-privacy-logs.sh /tmp/picko-runtime-log-smoke.log

echo "== Simulator fixture generation smoke =="
scripts/seed-simulator-photos-fixture.sh --count 3 --output /tmp/picko-fixture-smoke --generate-only
scripts/import-simulator-photos-fixture-chunked.sh --count 3 --simulator booted --output /tmp/picko-fixture-chunked-smoke --generate-only

echo "== SwiftPM tests =="
swift test --disable-sandbox

echo "== Synthetic benchmark JSON =="
if [[ ! -x .build/debug/PickoBenchmarks ]]; then
  swift build --disable-sandbox --product PickoBenchmarks
fi

.build/debug/PickoBenchmarks --json 10 > /tmp/picko-benchmark-smoke.json
if ! grep -q '"mode" : "Synthetic fixture"' /tmp/picko-benchmark-smoke.json; then
  echo "Benchmark JSON did not include the expected mode." >&2
  exit 1
fi

if ! grep -q '"assetCount" : 10' /tmp/picko-benchmark-smoke.json; then
  echo "Benchmark JSON did not include the expected asset count." >&2
  exit 1
fi

echo "== Baseline capture script smoke =="
baseline_path="$(scripts/capture-metadata-baseline.sh --output /tmp/picko-phase-5-evidence-smoke 10)"
if [[ ! -f "$baseline_path" ]]; then
  echo "Baseline capture script did not create an output file." >&2
  exit 1
fi

if ! grep -q '"assetCount" : 10' "$baseline_path"; then
  echo "Captured baseline JSON did not include the expected asset count." >&2
  exit 1
fi

rm -f /tmp/picko-phase-5-evidence-smoke/metadata-baseline-synthetic-10-local-smoke-run.json
timestamped_baseline_path="$(scripts/capture-metadata-baseline.sh --output /tmp/picko-phase-5-evidence-smoke --timestamp local-smoke-run 10)"
if [[ "$timestamped_baseline_path" != "/tmp/picko-phase-5-evidence-smoke/metadata-baseline-synthetic-10-local-smoke-run.json" ]]; then
  echo "Baseline capture script did not honor the explicit timestamp in the output path." >&2
  exit 1
fi
if [[ ! -f "$timestamped_baseline_path" ]]; then
  echo "Baseline capture script did not create the timestamped output file." >&2
  exit 1
fi
if scripts/capture-metadata-baseline.sh --output /tmp/picko-phase-5-evidence-smoke --timestamp local-smoke-run 10 >/dev/null; then
  echo "Baseline capture script overwrote an existing timestamped output file." >&2
  exit 1
fi

if scripts/capture-metadata-baseline.sh --output /tmp/picko-phase-5-evidence-smoke --timestamp "bad/path" 10 >/dev/null; then
  echo "Baseline capture script accepted a non filename-safe timestamp." >&2
  exit 1
fi

if scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production smoke library" --output /tmp/picko-phase-5-evidence-smoke 1000 >/dev/null; then
  echo "Photos-backed baseline capture accepted an incomplete formal count set." >&2
  exit 1
fi

if scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --output /tmp/picko-phase-5-evidence-smoke 1000 10000 50000 >/dev/null; then
  echo "Photos-backed baseline capture accepted a missing non-production library label." >&2
  exit 1
fi

scripts/capture-metadata-baseline.sh \
  --photos \
  --confirm-non-production-photos \
  --photos-library-label "Non-production smoke library" \
  --validate-only \
  1000 10000 50000 >/tmp/picko-phase-5-photos-preflight.log
if ! grep -q "Photos baseline preflight passed" /tmp/picko-phase-5-photos-preflight.log; then
  echo "Photos-backed baseline preflight did not confirm the formal evidence command." >&2
  exit 1
fi

if scripts/capture-metadata-baseline.sh \
  --photos \
  --confirm-non-production-photos \
  --photos-library-label "Non-production smoke library" \
  --validate-only \
  --output /tmp/picko-phase-5-evidence-smoke \
  1000 10000 50000 >/dev/null; then
  echo "Photos-backed baseline preflight accepted an output path outside project evidence." >&2
  exit 1
fi

if scripts/capture-metadata-baseline.sh \
  --photos \
  --confirm-non-production-photos \
  --photos-library-label "Non-production production library" \
  --validate-only \
  1000 10000 50000 >/dev/null; then
  echo "Photos-backed baseline preflight accepted a label that references a production library." >&2
  exit 1
fi

fake_benchmark_missing_row="/tmp/picko-fake-benchmark-missing-row.sh"
cat > "$fake_benchmark_missing_row" <<'SH'
#!/usr/bin/env bash
cat <<'JSON'
{"mode":"Photos-backed fixture","rows":[{"assetCount":1000,"elapsedSeconds":1.0,"assetsPerSecond":1000.0},{"assetCount":10000,"elapsedSeconds":2.0,"assetsPerSecond":5000.0}]}
JSON
SH
chmod +x "$fake_benchmark_missing_row"
fake_missing_row_output="docs/phase-5-evidence/metadata-baseline-photos-1000-10000-50000-fake-missing-row-smoke.json"
rm -f "$fake_missing_row_output" "$fake_missing_row_output.tmp"
if PICKO_BENCHMARK_EXECUTABLE="$fake_benchmark_missing_row" scripts/capture-metadata-baseline.sh \
  --photos \
  --confirm-non-production-photos \
  --photos-library-label "Non-production smoke library" \
  --timestamp fake-missing-row-smoke \
  1000 10000 50000 >/dev/null; then
  echo "Photos-backed baseline capture accepted benchmark JSON missing the 50k row." >&2
  exit 1
fi
if [[ -f "$fake_missing_row_output" || -f "$fake_missing_row_output.tmp" ]]; then
  echo "Photos-backed baseline capture left an invalid benchmark JSON artifact after validation failed." >&2
  exit 1
fi

host_capture_preflight_evidence="/tmp/picko-phase-5-host-capture-preflight-evidence.md"
cat > "$host_capture_preflight_evidence" <<'MARKDOWN'
## Host Photos-Backed Metadata Baseline

```sh
scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production smoke library" --validate-only 1000 10000 50000
```

Preflight status: Passed locally in smoke with `--validate-only`; no Photos library was read.
MARKDOWN
host_capture_guide="$(scripts/prepare-phase-5-host-baseline-capture.sh \
  --evidence "$host_capture_preflight_evidence" \
  --label "Non-production smoke library" \
  --timestamp smoke-host-run \
  --date 2026-06-03)"
for expected_text in \
  "scripts/capture-metadata-baseline.sh" \
  "--confirm-non-production-photos" \
  "--photos-library-label \"Non-production smoke library\"" \
  "--timestamp \"smoke-host-run\"" \
  "scripts/update-phase-5-host-baseline.sh" \
  "metadata-baseline-photos-1000-10000-50000-smoke-host-run.json" \
  "scripts/report-phase-5-status.sh --evidence $host_capture_preflight_evidence --date 2026-06-03 --host-timestamp smoke-host-run" \
  "Do not run the capture command against a production or personal Photos library"
do
  if ! printf '%s\n' "$host_capture_guide" | grep -q -- "$expected_text"; then
    echo "Host baseline capture guide is missing expected text: $expected_text" >&2
    exit 1
  fi
done
host_capture_default_guide="/tmp/picko-phase-5-host-capture-default-smoke.log"
scripts/prepare-phase-5-host-baseline-capture.sh > "$host_capture_default_guide"
for expected_text in \
  "--evidence docs/phase-5-evidence-2026-05-31.md" \
  "--timestamp \"20260603-photos-baseline\"" \
  "metadata-baseline-photos-1000-10000-50000-20260603-photos-baseline.json" \
  "scripts/report-phase-5-status.sh --evidence docs/phase-5-evidence-2026-05-31.md --date 2026-06-03 --host-timestamp 20260603-photos-baseline"
do
  if ! grep -q -- "$expected_text" "$host_capture_default_guide"; then
    echo "Host baseline default capture guide is missing expected text: $expected_text" >&2
    exit 1
  fi
done
if grep -q "docs/phase-5-evidence-2026-06-03.md" "$host_capture_default_guide"; then
  echo "Host baseline default capture guide ignored the latest existing evidence document." >&2
  exit 1
fi
if scripts/prepare-phase-5-host-baseline-capture.sh \
  --evidence "$host_capture_preflight_evidence" \
  --label "Non-production other library" >/dev/null; then
  echo "Host baseline capture guide accepted a label that did not match the recorded preflight." >&2
  exit 1
fi
if scripts/prepare-phase-5-host-baseline-capture.sh \
  --evidence "$host_capture_preflight_evidence" \
  --label "Production personal Photos library" >/dev/null; then
  echo "Host baseline capture guide accepted a production/personal library label." >&2
  exit 1
fi
if scripts/prepare-phase-5-host-baseline-capture.sh \
  --evidence "$host_capture_preflight_evidence" \
  --label "Non-production smoke library" \
  --timestamp "bad/path" >/dev/null; then
  echo "Host baseline capture guide accepted a non filename-safe timestamp." >&2
  exit 1
fi
if scripts/prepare-phase-5-host-baseline-capture.sh \
  --evidence "$host_capture_preflight_evidence" \
  --label "Non-production smoke library" \
  --date "TBD" >/dev/null; then
  echo "Host baseline capture guide accepted a placeholder date." >&2
  exit 1
fi

evidence_path="/tmp/picko-phase-5-evidence-smoke/phase-5-evidence.md"
if scripts/create-phase-5-evidence.sh --baseline-json "$baseline_path" "$evidence_path" >/dev/null; then
  echo "Evidence generator accepted synthetic baseline JSON as host Photos-backed evidence." >&2
  exit 1
fi

generator_photos_baseline="docs/phase-5-evidence/metadata-baseline-photos-1000-10000-50000-generator-smoke.json"
generator_partial_photos_baseline="docs/phase-5-evidence/metadata-baseline-photos-1000-10000-50000-generator-partial-smoke.json"
generator_bad_name_photos_baseline="docs/phase-5-evidence/photos-baseline-generator-smoke.json"
rm -f "$generator_photos_baseline" "$generator_partial_photos_baseline" "$generator_bad_name_photos_baseline"
printf '{"mode":"Photos-backed fixture","photosLibraryLabel":"Non-production smoke library","rows":[{"assetCount":1000,"elapsedSeconds":1.0,"assetsPerSecond":1000.0}]}\n' > "$generator_partial_photos_baseline"
if scripts/create-phase-5-evidence.sh --baseline-json "$generator_partial_photos_baseline" "$evidence_path" >/dev/null; then
  echo "Evidence generator accepted incomplete Photos-backed baseline JSON." >&2
  exit 1
fi

printf '{"mode":"Photos-backed fixture","photosLibraryLabel":"Non-production smoke library","rows":[{"assetCount":1000,"elapsedSeconds":1.0,"assetsPerSecond":1000.0},{"assetCount":10000,"elapsedSeconds":2.0,"assetsPerSecond":5000.0},{"assetCount":50000,"elapsedSeconds":10.0,"assetsPerSecond":5000.0}]}\n' > "$generator_photos_baseline"
printf '{"mode":"Photos-backed fixture","photosLibraryLabel":"Non-production smoke library","rows":[{"assetCount":1000,"elapsedSeconds":1.0,"assetsPerSecond":1000.0},{"assetCount":10000,"elapsedSeconds":2.0,"assetsPerSecond":5000.0},{"assetCount":50000,"elapsedSeconds":10.0,"assetsPerSecond":5000.0}]}\n' > "$generator_bad_name_photos_baseline"
if scripts/create-phase-5-evidence.sh --baseline-json "$generator_bad_name_photos_baseline" "$evidence_path" >/dev/null; then
  echo "Evidence generator accepted a host Photos baseline JSON without the formal filename." >&2
  exit 1
fi
scripts/create-phase-5-evidence.sh --baseline-json "$generator_photos_baseline" "$evidence_path" >/dev/null
if ! grep -q "Raw JSON evidence path: \`$generator_photos_baseline\`" "$evidence_path"; then
  echo "Evidence generator did not include the baseline JSON path." >&2
  exit 1
fi
if ! grep -q "Preflight status: TBD" "$evidence_path"; then
  echo "Evidence generator did not preserve the host Photos preflight status row." >&2
  exit 1
fi
rm -f "$generator_photos_baseline" "$generator_partial_photos_baseline" "$generator_bad_name_photos_baseline"

echo "== Evidence completeness checker smoke =="
incomplete_evidence="/tmp/picko-phase-5-incomplete-evidence.md"
complete_evidence="/tmp/picko-phase-5-complete-evidence.md"
unsafe_environment_evidence="/tmp/picko-phase-5-unsafe-environment-evidence.md"
partial_baseline="/tmp/picko-phase-5-partial-baseline.json"
synthetic_full_baseline="/tmp/picko-phase-5-synthetic-full-baseline.json"
missing_manual_evidence="/tmp/picko-phase-5-missing-manual-evidence.md"
manual_output_dir="/tmp/picko-phase-5-manual-evidence-smoke-$$"
rm -rf "$manual_output_dir"
manual_dir="$(scripts/prepare-phase-5-manual-evidence.sh --output "$manual_output_dir")"

if [[ ! -f "$manual_dir/README.md" ]]; then
  echo "Manual evidence checklist was not created." >&2
  exit 1
fi

if ! grep -q "iOS Delete Confirmation" "$manual_dir/README.md"; then
  echo "Manual evidence checklist is missing delete confirmation guidance." >&2
  exit 1
fi

if ! grep -q "Runtime or system logs are optional supplemental artifacts" "$manual_dir/README.md"; then
  echo "Manual evidence checklist does not clarify that runtime logs are optional once the main evidence audit is recorded." >&2
  exit 1
fi

printf 'operator status note\n' >> "$manual_dir/README.md"
scripts/prepare-phase-5-manual-evidence.sh --output "$manual_dir" >/dev/null
if ! grep -q "operator status note" "$manual_dir/README.md"; then
  echo "Manual evidence preparation overwrote an existing README." >&2
  exit 1
fi

scripts/check-phase-5-manual-evidence.sh --structure-only "$manual_dir"
macos_capture_guide="$(scripts/prepare-phase-5-macos-manual-capture.sh \
  --manual-dir "$manual_dir" \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --date 2026-06-03)"
for expected_text in \
  "screencapture -i $manual_dir/macos/authorization/macos-first-photos-authorization-2026-06-03.png" \
  "screencapture -i $manual_dir/macos/delete-confirmation/macos-system-photos-delete-confirmation-2026-06-03.png" \
  "Do not click the system Delete button" \
  "--scenario \"First Photos authorization\"" \
  "--scenario \"Pre-delete basket triggers Photos confirmation\""
do
  if ! printf '%s\n' "$macos_capture_guide" | grep -q -- "$expected_text"; then
    echo "macOS manual capture guide is missing expected text: $expected_text" >&2
    exit 1
  fi
done
macos_capture_default_guide="/tmp/picko-phase-5-macos-capture-default-smoke.log"
scripts/prepare-phase-5-macos-manual-capture.sh > "$macos_capture_default_guide"
for expected_text in \
  "screencapture -i docs/phase-5-evidence/manual-2026-05-31/macos/authorization/macos-first-photos-authorization-2026-06-03.png" \
  "screencapture -i docs/phase-5-evidence/manual-2026-05-31/macos/delete-confirmation/macos-system-photos-delete-confirmation-2026-06-03.png" \
  "--evidence docs/phase-5-evidence-2026-05-31.md" \
  "scripts/check-phase-5-manual-evidence.sh docs/phase-5-evidence/manual-2026-05-31"
do
  if ! grep -q -- "$expected_text" "$macos_capture_default_guide"; then
    echo "macOS manual default capture guide is missing expected text: $expected_text" >&2
    exit 1
  fi
done
if grep -q "docs/phase-5-evidence-2026-06-03.md" "$macos_capture_default_guide" \
  || grep -q "docs/phase-5-evidence/manual-2026-06-03" "$macos_capture_default_guide"; then
  echo "macOS manual default capture guide ignored the latest existing evidence package." >&2
  exit 1
fi
if scripts/prepare-phase-5-macos-manual-capture.sh \
  --manual-dir /tmp/picko-manual \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --date 2026-06-03 >/dev/null; then
  echo "macOS manual capture guide accepted a manual evidence directory outside project evidence." >&2
  exit 1
fi
if scripts/prepare-phase-5-macos-manual-capture.sh \
  --manual-dir "$manual_dir" \
  --evidence /tmp/picko-phase-5-missing-evidence.md \
  --date 2026-06-03 >/dev/null; then
  echo "macOS manual capture guide accepted a missing evidence document." >&2
  exit 1
fi
missing_macos_manual_rows_evidence="/tmp/picko-phase-5-missing-macos-manual-rows.md"
cat > "$missing_macos_manual_rows_evidence" <<'MARKDOWN'
| Scenario | Platform | Result | Evidence path | Notes |
| --- | --- | --- | --- | --- |
| First Photos authorization | iOS | Passed | `docs/phase-5-evidence/manual-smoke/ios/authorization/evidence.txt` | Non-production smoke |
MARKDOWN
if scripts/prepare-phase-5-macos-manual-capture.sh \
  --manual-dir "$manual_dir" \
  --evidence "$missing_macos_manual_rows_evidence" \
  --date 2026-06-03 >/dev/null; then
  echo "macOS manual capture guide accepted evidence without the required macOS manual rows." >&2
  exit 1
fi
existing_macos_capture_log="/tmp/picko-phase-5-existing-macos-capture.log"
printf 'existing capture\n' > "$manual_dir/macos/authorization/macos-first-photos-authorization-2026-06-03.png"
if scripts/prepare-phase-5-macos-manual-capture.sh \
  --manual-dir "$manual_dir" \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --date 2026-06-03 >"$existing_macos_capture_log" 2>&1; then
  echo "macOS manual capture guide accepted a pre-existing authorization screenshot target." >&2
  exit 1
fi
if ! grep -q "macOS manual capture target already exists" "$existing_macos_capture_log"; then
  echo "macOS manual capture guide failed for the wrong reason when a screenshot target already exists." >&2
  cat "$existing_macos_capture_log" >&2
  exit 1
fi
rm -f "$manual_dir/macos/authorization/macos-first-photos-authorization-2026-06-03.png"
manual_usage="$(scripts/check-phase-5-manual-evidence.sh --help)"
if ! printf '%s\n' "$manual_usage" | grep -q "required manual interaction scenario directories"; then
  echo "Manual evidence checker help does not describe required capture directories precisely." >&2
  exit 1
fi
if printf '%s\n' "$manual_usage" | grep -q "each scenario directory"; then
  echo "Manual evidence checker help still implies optional metadata benchmark captures are required." >&2
  exit 1
fi
if scripts/check-phase-5-manual-evidence.sh "$manual_dir"; then
  echo "Manual evidence checker accepted an empty manual evidence directory." >&2
  exit 1
fi

for evidence_dir in \
  "$manual_dir/ios/authorization" \
  "$manual_dir/ios/limited-library" \
  "$manual_dir/ios/delete-confirmation" \
  "$manual_dir/macos/authorization" \
  "$manual_dir/macos/delete-confirmation" \
  "$manual_dir/privacy"
do
  printf 'non-production evidence placeholder\n' > "$evidence_dir/evidence.txt"
done
scripts/check-phase-5-manual-evidence.sh "$manual_dir"
manual_direct_unsupported_dir="$(scripts/prepare-phase-5-manual-evidence.sh --output "/tmp/picko-phase-5-manual-unsupported-smoke-$$")"
for evidence_dir in \
  "$manual_direct_unsupported_dir/ios/authorization" \
  "$manual_direct_unsupported_dir/ios/limited-library" \
  "$manual_direct_unsupported_dir/ios/delete-confirmation" \
  "$manual_direct_unsupported_dir/macos/authorization" \
  "$manual_direct_unsupported_dir/macos/delete-confirmation" \
  "$manual_direct_unsupported_dir/privacy"
do
  printf 'non-production evidence placeholder\n' > "$evidence_dir/evidence.txt"
done
rm -f "$manual_direct_unsupported_dir/macos/authorization/evidence.txt"
printf 'not a supported manual artifact\n' > "$manual_direct_unsupported_dir/macos/authorization/evidence.swift"
if scripts/check-phase-5-manual-evidence.sh "$manual_direct_unsupported_dir"; then
  echo "Manual evidence checker accepted an unsupported captured artifact file type." >&2
  exit 1
fi
manual_direct_empty_dir="$(scripts/prepare-phase-5-manual-evidence.sh --output "/tmp/picko-phase-5-manual-empty-smoke-$$")"
for evidence_dir in \
  "$manual_direct_empty_dir/ios/authorization" \
  "$manual_direct_empty_dir/ios/limited-library" \
  "$manual_direct_empty_dir/ios/delete-confirmation" \
  "$manual_direct_empty_dir/macos/authorization" \
  "$manual_direct_empty_dir/macos/delete-confirmation" \
  "$manual_direct_empty_dir/privacy"
do
  printf 'non-production evidence placeholder\n' > "$evidence_dir/evidence.txt"
done
: > "$manual_direct_empty_dir/macos/delete-confirmation/evidence.txt"
if scripts/check-phase-5-manual-evidence.sh "$manual_direct_empty_dir"; then
  echo "Manual evidence checker accepted an empty captured artifact file." >&2
  exit 1
fi
manual_direct_sensitive_dir="$(scripts/prepare-phase-5-manual-evidence.sh --output "/tmp/picko-phase-5-manual-sensitive-smoke-$$")"
for evidence_dir in \
  "$manual_direct_sensitive_dir/ios/authorization" \
  "$manual_direct_sensitive_dir/ios/limited-library" \
  "$manual_direct_sensitive_dir/ios/delete-confirmation" \
  "$manual_direct_sensitive_dir/macos/authorization" \
  "$manual_direct_sensitive_dir/macos/delete-confirmation" \
  "$manual_direct_sensitive_dir/privacy"
do
  printf 'non-production evidence placeholder\n' > "$evidence_dir/evidence.txt"
done
printf 'localIdentifier=ABC123\n' > "$manual_direct_sensitive_dir/privacy/evidence.log"
if scripts/check-phase-5-manual-evidence.sh "$manual_direct_sensitive_dir"; then
  echo "Manual evidence checker accepted a text/log artifact containing sensitive metadata." >&2
  exit 1
fi

printf 'Result: TBD\n' > "$incomplete_evidence"
if scripts/check-phase-5-evidence.sh --allow-temp "$incomplete_evidence"; then
  echo "Evidence completeness checker accepted an incomplete evidence document." >&2
  exit 1
fi

printf '{"mode":"Photos-backed fixture","photosLibraryLabel":"Non-production smoke library","rows":[{"assetCount":1000,"elapsedSeconds":1.0,"assetsPerSecond":1000.0}]}\n' > "$partial_baseline"
printf 'Result: Passed\nEvidence: %s\n' "$partial_baseline" > "$complete_evidence"
if scripts/check-phase-5-evidence.sh --allow-temp "$complete_evidence"; then
  echo "Evidence completeness checker accepted an incomplete Photos baseline JSON." >&2
  exit 1
fi

printf '{"mode":"Synthetic fixture","rows":[{"assetCount":1000,"elapsedSeconds":1.0,"assetsPerSecond":1000.0},{"assetCount":10000,"elapsedSeconds":2.0,"assetsPerSecond":5000.0},{"assetCount":50000,"elapsedSeconds":10.0,"assetsPerSecond":5000.0}]}\n' > "$synthetic_full_baseline"
{
  printf 'Host Photos baseline: %s\n' "$synthetic_full_baseline"
  printf '## iOS Simulator Photos-Backed Benchmark\n'
  printf '| 1,000 | 1.0000 | 1000.0000 | docs/phase-5-evidence/ios-metadata-benchmark/photos-1000-2026-05-31.jpg |\n'
  printf '| 10,000 | 2.0000 | 5000.0000 | docs/phase-5-evidence/ios-metadata-benchmark/photos-1000-2026-05-31.jpg |\n'
  printf '| 50,000 | 10.0000 | 5000.0000 | docs/phase-5-evidence/ios-metadata-benchmark/photos-1000-2026-05-31.jpg |\n'
  printf '## Privacy Review\n'
  printf '| Check | Result | Evidence |\n'
  printf '| --- | --- | --- |\n'
  printf '| Runtime logs checked for photo contents or sensitive metadata | Passed | scripts/audit-runtime-privacy-logs.sh /tmp/picko-runtime-log-smoke.log |\n'
  printf 'Manual evidence checked: scripts/check-phase-5-manual-evidence.sh %s\n' "$manual_dir"
} > "$complete_evidence"
if scripts/check-phase-5-evidence.sh --allow-temp "$complete_evidence"; then
  echo "Evidence completeness checker accepted synthetic baseline JSON as Photos-backed evidence." >&2
  exit 1
fi

full_baseline="/tmp/picko-phase-5-full-baseline.json"
printf '{"mode":"Photos-backed fixture","photosLibraryLabel":"Non-production smoke library","rows":[{"assetCount":1000,"elapsedSeconds":1.0,"assetsPerSecond":1000.0},{"assetCount":10000,"elapsedSeconds":2.0,"assetsPerSecond":5000.0},{"assetCount":50000,"elapsedSeconds":10.0,"assetsPerSecond":5000.0}]}\n' > "$full_baseline"
{
  printf '## Host Photos-Backed Metadata Baseline\n'
  printf 'Host Photos baseline: %s\n' "$full_baseline"
  printf 'scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production smoke library" --validate-only 1000 10000 50000\n'
  printf 'Preflight status: Passed locally in smoke with --validate-only; no Photos library was read.\n'
  printf '## iOS Simulator Photos-Backed Benchmark\n'
  printf '| 1,000 | 1.0000 | 1000.0000 | docs/phase-5-evidence/ios-metadata-benchmark/photos-1000-2026-05-31.jpg |\n'
  printf '| 10,000 | 2.0000 | 5000.0000 | docs/phase-5-evidence/ios-metadata-benchmark/photos-1000-2026-05-31.jpg |\n'
  printf '| 50,000 | 10.0000 | 5000.0000 | docs/phase-5-evidence/ios-metadata-benchmark/photos-1000-2026-05-31.jpg |\n'
  printf '## Privacy Review\n'
  printf '| Check | Result | Evidence |\n'
  printf '| --- | --- | --- |\n'
  printf '| Runtime logs checked for photo contents or sensitive metadata | Passed | scripts/audit-runtime-privacy-logs.sh /tmp/picko-runtime-log-smoke.log |\n'
} > "$missing_manual_evidence"
if scripts/check-phase-5-evidence.sh --allow-temp "$missing_manual_evidence"; then
  echo "Evidence completeness checker accepted final evidence without manual evidence checker output." >&2
  exit 1
fi

{
  cat "$missing_manual_evidence"
  printf 'Manual evidence checked: scripts/check-phase-5-manual-evidence.sh %s\n' "$manual_dir"
} > "$complete_evidence"
if scripts/check-phase-5-evidence.sh --allow-temp "$complete_evidence"; then
  echo "Evidence completeness checker accepted final evidence without concrete Environment rows." >&2
  exit 1
fi

{
  cat "$complete_evidence"
  printf '| Field | Value |\n'
  printf '| --- | --- |\n'
  printf '| iOS Simulator | iPhone 17 Pro, iOS 26.4, disposable Photos library |\n'
  printf '| Test Photos Library | Production personal Photos library |\n'
} > "$unsafe_environment_evidence"
if scripts/check-phase-5-evidence.sh --allow-temp "$unsafe_environment_evidence"; then
  echo "Evidence completeness checker accepted a production Photos library environment row." >&2
  exit 1
fi

{
  printf '| Field | Value |\n'
  printf '| --- | --- |\n'
  printf '| iOS Simulator | iPhone 17 Pro, iOS 26.4, disposable Photos library |\n'
  printf '| Test Photos Library | Non-production simulator fixture and non-production Mac Photos library |\n'
  cat "$complete_evidence"
} > "$complete_evidence.with-environment"
if scripts/check-phase-5-evidence.sh --allow-temp "$complete_evidence.with-environment"; then
  echo "Evidence completeness checker accepted final evidence without Manual Photos Verification rows." >&2
  exit 1
fi

{
  cat "$complete_evidence.with-environment"
  printf '| Scenario | Platform | Result | Evidence path | Notes |\n'
  printf '| --- | --- | --- | --- | --- |\n'
  printf '| First Photos authorization | iOS | Passed | `%s/ios/authorization/evidence.txt` | Non-production smoke |\n' "$manual_dir"
  printf '| Limited library state | iOS | Passed | `%s/ios/limited-library/evidence.txt` | Non-production smoke |\n' "$manual_dir"
  printf '| Pre-delete basket triggers Photos confirmation | iOS | Passed | `%s/ios/delete-confirmation/evidence.txt` | Non-production smoke |\n' "$manual_dir"
  printf '| First Photos authorization | macOS | Passed | `%s/macos/authorization/evidence.txt` | Non-production smoke |\n' "$manual_dir"
  printf '| Pre-delete basket triggers Photos confirmation | macOS | Passed | `%s/macos/delete-confirmation/evidence.txt` | Non-production smoke |\n' "$manual_dir"
  printf '| Recently Deleted recovery explanation | iOS/macOS | Passed | `%s/privacy/evidence.txt` | Non-production smoke |\n' "$manual_dir"
} > "$complete_evidence.with-manual-rows"
missing_baseline_preflight_evidence="/tmp/picko-phase-5-missing-baseline-preflight-evidence.md"
sed '/--validate-only/d' "$complete_evidence.with-manual-rows" > "$missing_baseline_preflight_evidence"
if scripts/check-phase-5-evidence.sh --allow-temp "$missing_baseline_preflight_evidence"; then
  echo "Evidence completeness checker accepted host Photos baseline evidence without a --validate-only preflight command." >&2
  exit 1
fi
incomplete_baseline_preflight_evidence="/tmp/picko-phase-5-incomplete-baseline-preflight-evidence.md"
{
  printf '## Host Photos-Backed Metadata Baseline\n'
  printf 'scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production smoke library" --validate-only 1000\n'
  sed '/--validate-only/d' "$complete_evidence.with-manual-rows"
} > "$incomplete_baseline_preflight_evidence"
if scripts/check-phase-5-evidence.sh --allow-temp "$incomplete_baseline_preflight_evidence"; then
  echo "Evidence completeness checker accepted a host Photos baseline preflight without the full 1k/10k/50k count set." >&2
  exit 1
fi
sensitive_baseline_preflight_evidence="/tmp/picko-phase-5-sensitive-baseline-preflight-evidence.md"
{
  printf '## Host Photos-Backed Metadata Baseline\n'
  printf 'scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production production library" --validate-only 1000 10000 50000\n'
  sed '/--validate-only/d' "$complete_evidence.with-manual-rows"
} > "$sensitive_baseline_preflight_evidence"
if scripts/check-phase-5-evidence.sh --allow-temp "$sensitive_baseline_preflight_evidence"; then
  echo "Evidence completeness checker accepted a host Photos baseline preflight label that references a production library." >&2
  exit 1
fi
wrong_section_baseline_preflight_evidence="/tmp/picko-phase-5-wrong-section-baseline-preflight-evidence.md"
{
  printf '## Operator Notes\n'
  printf 'scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production smoke library" --validate-only 1000 10000 50000\n'
  printf 'Preflight status: Passed locally in smoke with --validate-only; no Photos library was read.\n'
  sed '/--validate-only/d' "$complete_evidence.with-manual-rows"
} > "$wrong_section_baseline_preflight_evidence"
if scripts/check-phase-5-evidence.sh --allow-temp "$wrong_section_baseline_preflight_evidence"; then
  echo "Evidence completeness checker accepted a host Photos baseline preflight outside the host baseline section." >&2
  exit 1
fi
missing_baseline_preflight_status_evidence="/tmp/picko-phase-5-missing-baseline-preflight-status-evidence.md"
{
  printf '## Host Photos-Backed Metadata Baseline\n'
  printf 'scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production smoke library" --validate-only 1000 10000 50000\n'
  sed '/--validate-only/d' "$complete_evidence.with-manual-rows"
} > "$missing_baseline_preflight_status_evidence"
if scripts/check-phase-5-evidence.sh --allow-temp "$missing_baseline_preflight_status_evidence"; then
  echo "Evidence completeness checker accepted host Photos baseline evidence without a Passed preflight status." >&2
  exit 1
fi
{
  printf '## Host Photos-Backed Metadata Baseline\n'
  printf 'scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production smoke library" --validate-only 1000 10000 50000\n'
  printf 'Preflight status: Passed locally in smoke with --validate-only; no Photos library was read.\n'
  cat "$complete_evidence.with-manual-rows"
} > "$complete_evidence.with-manual-rows-and-preflight"
mv "$complete_evidence.with-manual-rows-and-preflight" "$complete_evidence.with-manual-rows"
wrong_section_runtime_privacy_evidence="/tmp/picko-phase-5-wrong-section-runtime-privacy-evidence.md"
python3 - "$complete_evidence.with-manual-rows" "$wrong_section_runtime_privacy_evidence" <<'PY'
import sys
from pathlib import Path

source = Path(sys.argv[1])
target = Path(sys.argv[2])
text = source.read_text()
text = text.replace("## Privacy Review", "## Operator Notes", 1)
target.write_text(text)
PY
if scripts/check-phase-5-evidence.sh --allow-temp "$wrong_section_runtime_privacy_evidence"; then
  echo "Evidence completeness checker accepted runtime privacy audit evidence outside the Privacy Review section." >&2
  exit 1
fi
sensitive_runtime_privacy_log="/tmp/picko-phase-5-sensitive-runtime-privacy-smoke.log"
sensitive_runtime_privacy_evidence="/tmp/picko-phase-5-sensitive-runtime-privacy-evidence.md"
printf 'localIdentifier: sensitive-runtime-smoke\n' > "$sensitive_runtime_privacy_log"
sed "s|/tmp/picko-runtime-log-smoke.log|$sensitive_runtime_privacy_log|" \
  "$complete_evidence.with-manual-rows" > "$sensitive_runtime_privacy_evidence"
if scripts/check-phase-5-evidence.sh --allow-temp "$sensitive_runtime_privacy_evidence"; then
  echo "Evidence completeness checker accepted runtime privacy log evidence containing sensitive metadata." >&2
  rm -f "$sensitive_runtime_privacy_log"
  exit 1
fi
rm -f "$sensitive_runtime_privacy_log"
iOS_unsupported_benchmark_artifact="docs/phase-5-evidence/ios-metadata-benchmark/final-checker-unsupported-smoke.txt"
printf 'not a screenshot or recording\n' > "$iOS_unsupported_benchmark_artifact"
ios_unsupported_benchmark_evidence="/tmp/picko-phase-5-ios-unsupported-benchmark-evidence.md"
sed "s|docs/phase-5-evidence/ios-metadata-benchmark/photos-1000-2026-05-31.jpg|$iOS_unsupported_benchmark_artifact|" \
  "$complete_evidence.with-manual-rows" > "$ios_unsupported_benchmark_evidence"
if scripts/check-phase-5-evidence.sh --allow-temp "$ios_unsupported_benchmark_evidence"; then
  echo "Evidence completeness checker accepted an unsupported iOS benchmark artifact file type." >&2
  exit 1
fi
rm -f "$iOS_unsupported_benchmark_artifact"
scripts/check-phase-5-evidence.sh --allow-temp "$complete_evidence.with-manual-rows"
manual_mismatch_evidence="/tmp/picko-phase-5-manual-mismatch-evidence.md"
sed "s|$manual_dir/macos/authorization/evidence.txt|$manual_dir/ios/authorization/evidence.txt|" \
  "$complete_evidence.with-manual-rows" > "$manual_mismatch_evidence"
if scripts/check-phase-5-evidence.sh --allow-temp "$manual_mismatch_evidence"; then
  echo "Evidence completeness checker accepted a manual row pointing at the wrong scenario folder." >&2
  exit 1
fi
manual_directory_artifact_evidence="/tmp/picko-phase-5-manual-directory-artifact-evidence.md"
sed "s|$manual_dir/macos/authorization/evidence.txt|$manual_dir/macos/authorization|" \
  "$complete_evidence.with-manual-rows" > "$manual_directory_artifact_evidence"
if scripts/check-phase-5-evidence.sh --allow-temp "$manual_directory_artifact_evidence"; then
  echo "Evidence completeness checker accepted a manual row pointing at a directory instead of a captured artifact file." >&2
  exit 1
fi
manual_unsupported_artifact="docs/phase-5-evidence/manual-unsupported-smoke/macos/authorization/evidence.swift"
mkdir -p "$(dirname "$manual_unsupported_artifact")"
printf 'not a captured evidence artifact\n' > "$manual_unsupported_artifact"
manual_unsupported_artifact_evidence="/tmp/picko-phase-5-manual-unsupported-artifact-evidence.md"
sed "s|$manual_dir/macos/authorization/evidence.txt|$manual_unsupported_artifact|" \
  "$complete_evidence.with-manual-rows" > "$manual_unsupported_artifact_evidence"
if scripts/check-phase-5-evidence.sh --allow-temp "$manual_unsupported_artifact_evidence"; then
  echo "Evidence completeness checker accepted an unsupported manual artifact file type." >&2
  exit 1
fi
rm -f "$manual_unsupported_artifact"
rm -rf "$(dirname "$(dirname "$(dirname "$manual_unsupported_artifact")")")"
manual_bad_notes_evidence="/tmp/picko-phase-5-manual-bad-notes-evidence.md"
{
  cat "$complete_evidence.with-manual-rows"
  printf '| First Photos authorization | macOS | Passed | `%s/macos/authorization/evidence.txt` | TBD |\n' "$manual_dir"
} > "$manual_bad_notes_evidence"
if scripts/check-phase-5-evidence.sh --allow-temp "$manual_bad_notes_evidence"; then
  echo "Evidence completeness checker accepted a manual row with placeholder notes." >&2
  exit 1
fi
manual_table_break_notes_evidence="/tmp/picko-phase-5-manual-table-break-notes-evidence.md"
{
  cat "$complete_evidence.with-manual-rows"
  printf '| First Photos authorization | macOS | Passed | `%s/macos/authorization/evidence.txt` | Non-production | table break |\n' "$manual_dir"
} > "$manual_table_break_notes_evidence"
if scripts/check-phase-5-evidence.sh --allow-temp "$manual_table_break_notes_evidence"; then
  echo "Evidence completeness checker accepted a manual row with table-breaking notes." >&2
  exit 1
fi
manual_sensitive_notes_evidence="/tmp/picko-phase-5-manual-sensitive-notes-evidence.md"
{
  cat "$complete_evidence.with-manual-rows"
  printf '| First Photos authorization | macOS | Passed | `%s/macos/authorization/evidence.txt` | Personal Photos library smoke |\n' "$manual_dir"
} > "$manual_sensitive_notes_evidence"
if scripts/check-phase-5-evidence.sh --allow-temp "$manual_sensitive_notes_evidence"; then
  echo "Evidence completeness checker accepted a manual row with personal/production Photos notes." >&2
  exit 1
fi
manual_sensitive_content_artifact="$manual_dir/macos/authorization/sensitive.txt"
printf 'localIdentifier: sensitive-smoke\n' > "$manual_sensitive_content_artifact"
manual_sensitive_content_evidence="/tmp/picko-phase-5-manual-sensitive-content-evidence.md"
sed "s|$manual_dir/macos/authorization/evidence.txt|$manual_sensitive_content_artifact|" \
  "$complete_evidence.with-manual-rows" > "$manual_sensitive_content_evidence"
if scripts/check-phase-5-evidence.sh --allow-temp "$manual_sensitive_content_evidence"; then
  echo "Evidence completeness checker accepted a text manual artifact containing sensitive metadata." >&2
  exit 1
fi
rm -f "$manual_sensitive_content_artifact"
manual_empty_artifact="$manual_dir/macos/authorization/empty.txt"
: > "$manual_empty_artifact"
manual_empty_artifact_evidence="/tmp/picko-phase-5-manual-empty-artifact-evidence.md"
sed "s|$manual_dir/macos/authorization/evidence.txt|$manual_empty_artifact|" \
  "$complete_evidence.with-manual-rows" > "$manual_empty_artifact_evidence"
if scripts/check-phase-5-evidence.sh --allow-temp "$manual_empty_artifact_evidence"; then
  echo "Evidence completeness checker accepted an empty manual artifact file." >&2
  exit 1
fi
rm -f "$manual_empty_artifact"

echo "== iOS benchmark evidence updater smoke =="
ios_update_evidence="/tmp/picko-phase-5-ios-update-evidence.md"
cat > "$ios_update_evidence" <<'MARKDOWN'
## iOS Simulator Photos-Backed Benchmark

| Asset count | Elapsed seconds | Assets / second | Evidence |
| ---: | ---: | ---: | --- |
| 1,000 | TBD | TBD | TBD |
| 10,000 | TBD | TBD | TBD |
| 50,000 | TBD | TBD | TBD |
MARKDOWN
scripts/update-phase-5-ios-benchmark.sh \
  --evidence "$ios_update_evidence" \
  --count 1000 \
  --seconds 58.9891 \
  --rate 16.9523 \
  --path docs/phase-5-evidence/ios-metadata-benchmark/photos-1000-2026-05-31.jpg
if ! grep -q '| 1,000 | 58.9891 | 16.9523 | `docs/phase-5-evidence/ios-metadata-benchmark/photos-1000-2026-05-31.jpg` |' "$ios_update_evidence"; then
  echo "iOS benchmark evidence updater did not update the expected row." >&2
  exit 1
fi

ios_scoped_update_evidence="/tmp/picko-phase-5-ios-scoped-update-evidence.md"
cat > "$ios_scoped_update_evidence" <<'MARKDOWN'
## Host Photos-Backed Metadata Baseline

| Asset count | Elapsed seconds | Assets / second | Notes |
| ---: | ---: | ---: | --- |
| 10,000 | TBD | TBD | TBD |

## iOS Simulator Photos-Backed Benchmark

| Asset count | Elapsed seconds | Assets / second | Evidence |
| ---: | ---: | ---: | --- |
| 10,000 | TBD | TBD | TBD |
MARKDOWN
scripts/update-phase-5-ios-benchmark.sh \
  --evidence "$ios_scoped_update_evidence" \
  --count 10000 \
  --seconds 26.3797 \
  --rate 379.0787 \
  --path docs/phase-5-evidence/ios-metadata-benchmark/photos-10000-2026-05-31.jpg
if ! awk '
  /^## Host Photos-Backed Metadata Baseline$/ { section = "host"; next }
  /^## iOS Simulator Photos-Backed Benchmark$/ { section = "ios"; next }
  section == "host" && /\| 10,000 \| TBD \| TBD \| TBD \|/ { host_ready = 1 }
  section == "ios" && /\| 10,000 \| 26\.3797 \| 379\.0787 \| `docs\/phase-5-evidence\/ios-metadata-benchmark\/photos-10000-2026-05-31\.jpg` \|/ { ios_ready = 1 }
  END { exit !(host_ready && ios_ready) }
' "$ios_scoped_update_evidence"; then
  echo "iOS benchmark evidence updater modified the wrong section or missed the iOS section." >&2
  exit 1
fi

if scripts/update-phase-5-ios-benchmark.sh \
  --evidence "$ios_update_evidence" \
  --count 1000 \
  --seconds 58.9891 \
  --rate 16.9523 \
  --path /tmp/not-project-evidence.jpg >/dev/null; then
  echo "iOS benchmark evidence updater accepted a non-project evidence path." >&2
  exit 1
fi

empty_ios_benchmark_artifact="docs/phase-5-evidence/ios-metadata-benchmark/empty-artifact-smoke.jpg"
: > "$empty_ios_benchmark_artifact"
if scripts/update-phase-5-ios-benchmark.sh \
  --evidence "$ios_update_evidence" \
  --count 1000 \
  --seconds 58.9891 \
  --rate 16.9523 \
  --path "$empty_ios_benchmark_artifact" >/dev/null; then
  echo "iOS benchmark evidence updater accepted an empty evidence artifact." >&2
  exit 1
fi
rm -f "$empty_ios_benchmark_artifact"

unsupported_ios_benchmark_artifact="docs/phase-5-evidence/ios-metadata-benchmark/unsupported-artifact-smoke.txt"
printf 'not a screenshot or recording\n' > "$unsupported_ios_benchmark_artifact"
if scripts/update-phase-5-ios-benchmark.sh \
  --evidence "$ios_update_evidence" \
  --count 1000 \
  --seconds 58.9891 \
  --rate 16.9523 \
  --path "$unsupported_ios_benchmark_artifact" >/dev/null; then
  echo "iOS benchmark evidence updater accepted an unsupported evidence artifact type." >&2
  exit 1
fi
rm -f "$unsupported_ios_benchmark_artifact"

echo "== External evidence checklist smoke =="
external_checklist="/tmp/picko-phase-5-external-checklist-smoke.log"
external_checklist_default="/tmp/picko-phase-5-external-checklist-default-smoke.log"
scripts/phase-5-external-evidence-checklist.sh > "$external_checklist_default"
for expected_text in \
  "docs/phase-5-evidence-2026-05-31.md" \
  "docs/phase-5-evidence/manual-2026-05-31" \
  "--timestamp 20260603-photos-baseline" \
  "metadata-baseline-photos-1000-10000-50000-20260603-photos-baseline.json" \
  "scripts/finalize-phase-5-evidence.sh --evidence docs/phase-5-evidence-2026-05-31.md --date 2026-06-03 --host-timestamp 20260603-photos-baseline"
do
  if ! grep -q -- "$expected_text" "$external_checklist_default"; then
    echo "External evidence default checklist is missing expected text: $expected_text" >&2
    exit 1
  fi
done
scripts/phase-5-external-evidence-checklist.sh \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --date 2026-06-03 \
  --host-timestamp checklist-host-smoke > "$external_checklist"
if grep -q '^[[:space:]]*--count 1000[[:space:]]*\\$' "$external_checklist"; then
  echo "External evidence checklist included a 1,000 iOS benchmark write-back even though current evidence already has local 1,000 evidence." >&2
  exit 1
fi
if grep -q "scripts/update-phase-5-ios-benchmark.sh" "$external_checklist"; then
  echo "External evidence checklist included iOS benchmark write-back steps even though all current iOS benchmark evidence is ready." >&2
  exit 1
fi
if ! grep -q "No iOS Simulator benchmark import, launch, or write-back step is currently required." "$external_checklist"; then
  echo "External evidence checklist did not state that iOS benchmark steps are unnecessary after all rows are ready." >&2
  exit 1
fi
if ! grep -q -- "--timestamp checklist-host-smoke" "$external_checklist"; then
  echo "External evidence checklist did not include the deterministic host baseline timestamp option." >&2
  exit 1
fi
if ! grep -q -- "--date 2026-06-03" "$external_checklist"; then
  echo "External evidence checklist did not include the deterministic host baseline status date option." >&2
  exit 1
fi
if ! grep -q "metadata-baseline-photos-1000-10000-50000-checklist-host-smoke.json" "$external_checklist"; then
  echo "External evidence checklist did not emit the deterministic host baseline JSON path." >&2
  exit 1
fi
if grep -q "YYYYMMDD-HHMMSS" "$external_checklist"; then
  echo "External evidence checklist emitted a placeholder host baseline timestamp." >&2
  exit 1
fi
checklist_existing_json="docs/phase-5-evidence/metadata-baseline-photos-1000-10000-50000-checklist-existing-json.json"
printf '{"existing":true}\n' > "$checklist_existing_json"
external_checklist_existing_json="/tmp/picko-phase-5-external-checklist-existing-json.log"
scripts/phase-5-external-evidence-checklist.sh \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --date 2026-06-03 \
  --host-timestamp checklist-existing-json > "$external_checklist_existing_json"
if ! grep -q "Host baseline JSON target already exists" "$external_checklist_existing_json"; then
  echo "External evidence checklist did not warn when the deterministic host baseline JSON target already exists." >&2
  exit 1
fi
rm -f "$checklist_existing_json"
if ! grep -q "macos-first-photos-authorization-2026-06-03.png" "$external_checklist" \
  || ! grep -q "macos-system-photos-delete-confirmation-2026-06-03.png" "$external_checklist"; then
  echo "External evidence checklist did not emit date-specific macOS capture paths." >&2
  exit 1
fi
if grep -q "macos-first-photos-authorization-YYYY-MM-DD.png" "$external_checklist" \
  || grep -q "macos-system-photos-delete-confirmation-YYYY-MM-DD.png" "$external_checklist"; then
  echo "External evidence checklist emitted placeholder macOS capture paths." >&2
  exit 1
fi
checklist_existing_macos_dir="/tmp/picko-phase-5-checklist-existing-macos"
rm -rf "$checklist_existing_macos_dir"
scripts/prepare-phase-5-manual-evidence.sh --output "$checklist_existing_macos_dir" >/dev/null
printf 'existing capture\n' > "$checklist_existing_macos_dir/macos/authorization/macos-first-photos-authorization-2026-06-03.png"
external_checklist_existing_macos="/tmp/picko-phase-5-external-checklist-existing-macos.log"
scripts/phase-5-external-evidence-checklist.sh \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --manual-dir "$checklist_existing_macos_dir" \
  --date 2026-06-03 \
  --host-timestamp checklist-host-smoke > "$external_checklist_existing_macos"
if ! grep -q "macOS manual capture target already exists" "$external_checklist_existing_macos"; then
  echo "External evidence checklist did not warn when a deterministic macOS capture target already exists." >&2
  exit 1
fi
rm -rf "$checklist_existing_macos_dir"
missing_external_checklist="/tmp/picko-phase-5-external-checklist-missing-evidence.log"
scripts/phase-5-external-evidence-checklist.sh \
  --evidence /tmp/picko-phase-5-missing-evidence.md \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --date 2026-06-03 \
  --host-timestamp checklist-host-smoke > "$missing_external_checklist"
if ! grep -q "scripts/create-phase-5-evidence.sh /tmp/picko-phase-5-missing-evidence.md" "$missing_external_checklist"; then
  echo "External evidence checklist did not include evidence document creation for a missing evidence path." >&2
  exit 1
fi
ios_missing_external_evidence="/tmp/picko-phase-5-external-checklist-ios-missing.md"
ios_missing_external_checklist="/tmp/picko-phase-5-external-checklist-ios-missing.log"
ios_unsupported_external_evidence="/tmp/picko-phase-5-external-checklist-ios-unsupported.md"
ios_unsupported_external_checklist="/tmp/picko-phase-5-external-checklist-ios-unsupported.log"
ios_unsupported_external_artifact="docs/phase-5-evidence/ios-metadata-benchmark/external-checklist-unsupported-smoke.txt"
cat > "$ios_missing_external_evidence" <<'MARKDOWN'
| Asset count | Elapsed seconds | Assets / second | Evidence |
| ---: | ---: | ---: | --- |
| 1,000 | TBD | TBD | TBD |
| 10,000 | 2.0000 | 5000.0000 | `docs/phase-5-evidence/ios-metadata-benchmark/photos-10000-2026-05-31.jpg` |
| 50,000 | 10.0000 | 5000.0000 | `docs/phase-5-evidence/ios-metadata-benchmark/photos-50000-2026-05-31.jpg` |
MARKDOWN
scripts/phase-5-external-evidence-checklist.sh \
  --evidence "$ios_missing_external_evidence" \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --date 2026-06-03 \
  --host-timestamp checklist-host-smoke > "$ios_missing_external_checklist"
if ! grep -q '^[[:space:]]*--count 1000[[:space:]]*\\$' "$ios_missing_external_checklist"; then
  echo "External evidence checklist did not include a write-back command for missing 1,000 iOS benchmark evidence." >&2
  exit 1
fi
if ! grep -q "scripts/update-phase-5-ios-benchmark.sh" "$ios_missing_external_checklist"; then
  echo "External evidence checklist did not include iOS benchmark updater steps for missing iOS benchmark evidence." >&2
  exit 1
fi
printf 'unsupported benchmark artifact smoke\n' > "$ios_unsupported_external_artifact"
cat > "$ios_unsupported_external_evidence" <<MARKDOWN
| Asset count | Elapsed seconds | Assets / second | Evidence |
| ---: | ---: | ---: | --- |
| 1,000 | 1.0000 | 1000.0000 | \`$ios_unsupported_external_artifact\` |
| 10,000 | 2.0000 | 5000.0000 | \`docs/phase-5-evidence/ios-metadata-benchmark/photos-10000-2026-05-31.jpg\` |
| 50,000 | 10.0000 | 5000.0000 | \`docs/phase-5-evidence/ios-metadata-benchmark/photos-50000-2026-05-31.jpg\` |
MARKDOWN
scripts/phase-5-external-evidence-checklist.sh \
  --evidence "$ios_unsupported_external_evidence" \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --date 2026-06-03 \
  --host-timestamp checklist-host-smoke > "$ios_unsupported_external_checklist"
if ! grep -q '^[[:space:]]*--count 1000[[:space:]]*\\$' "$ios_unsupported_external_checklist"; then
  echo "External evidence checklist treated unsupported 1,000 iOS benchmark evidence as ready." >&2
  rm -f "$ios_unsupported_external_artifact"
  exit 1
fi
rm -f "$ios_unsupported_external_artifact"
if ! grep -q "Host Photos-backed baseline" "$external_checklist"; then
  echo "External evidence checklist did not include host baseline steps." >&2
  exit 1
fi
if ! grep -q -- "--photos-library-label" "$external_checklist"; then
  echo "External evidence checklist did not include the guarded host Photos baseline command." >&2
  exit 1
fi
if ! grep -q "scripts/update-phase-5-manual-verification.sh" "$external_checklist"; then
  echo "External evidence checklist did not include manual verification updater steps." >&2
  exit 1
fi
if ! grep -q "already prepared at docs/phase-5-evidence/manual-2026-05-31" "$external_checklist"; then
  echo "External evidence checklist did not preserve the existing manual evidence directory." >&2
  exit 1
fi
if ! grep -q "Do not recreate it unless the folder is missing" "$external_checklist"; then
  echo "External evidence checklist did not warn against recreating an existing manual evidence directory." >&2
  exit 1
fi
if ! grep -q -- '--scenario "First Photos authorization"' "$external_checklist" \
  || ! grep -q -- '--platform "macOS"' "$external_checklist"; then
  echo "External evidence checklist did not include the remaining macOS manual verification steps." >&2
  exit 1
fi
if ! grep -q -- "--path docs/phase-5-evidence/manual-2026-05-31/macos/authorization/macos-first-photos-authorization-2026-06-03.png" "$external_checklist"; then
  echo "External evidence checklist did not emit the concrete macOS authorization write-back path." >&2
  exit 1
fi
if ! grep -q -- "--path docs/phase-5-evidence/manual-2026-05-31/macos/delete-confirmation/macos-system-photos-delete-confirmation-2026-06-03.png" "$external_checklist"; then
  echo "External evidence checklist did not emit the concrete macOS delete-confirmation write-back path." >&2
  exit 1
fi
if grep -q -- "docs/phase-5-evidence/manual-2026-05-31/macos/.*/ARTIFACT" "$external_checklist"; then
  echo "External evidence checklist emitted placeholder macOS manual write-back paths." >&2
  exit 1
fi
if grep -q -- '--scenario "Limited library state"' "$external_checklist"; then
  echo "External evidence checklist included iOS limited-library write-back even though current iOS evidence is ready." >&2
  exit 1
fi
if grep -q -- '--scenario "Recently Deleted recovery explanation"' "$external_checklist"; then
  echo "External evidence checklist included Recently Deleted write-back even though current recovery evidence is ready." >&2
  exit 1
fi
if grep -q "scripts/record-runtime-privacy-evidence.sh" "$external_checklist"; then
  echo "External evidence checklist included runtime privacy write-back even though current runtime privacy evidence is ready." >&2
  exit 1
fi
if grep -q "scripts/update-phase-5-environment.sh" "$external_checklist"; then
  echo "External evidence checklist included environment updater steps even though current environment rows are ready." >&2
  exit 1
fi
external_partial_environment_evidence="/tmp/picko-phase-5-external-partial-environment.md"
cat > "$external_partial_environment_evidence" <<'MARKDOWN'
| Field | Value |
| --- | --- |
| iOS Simulator | iPhone 17 Pro, iOS 26.5 Simulator |
| Test Photos Library | Non-production / TBD |
MARKDOWN
scripts/phase-5-external-evidence-checklist.sh \
  --evidence "$external_partial_environment_evidence" \
  --manual-dir docs/phase-5-evidence/manual-2026-05-31 \
  --date 2026-06-03 \
  --host-timestamp checklist-host-smoke > /tmp/picko-phase-5-external-partial-environment.log
if grep -q -- '--field "iOS Simulator"' /tmp/picko-phase-5-external-partial-environment.log; then
  echo "External evidence checklist asked to update iOS Simulator after that environment row was ready." >&2
  exit 1
fi
if ! grep -q -- '--field "Test Photos Library"' /tmp/picko-phase-5-external-partial-environment.log; then
  echo "External evidence checklist did not ask to update the remaining Test Photos Library row." >&2
  exit 1
fi
if ! grep -q "scripts/finalize-phase-5-evidence.sh --evidence docs/phase-5-evidence-2026-05-31.md --date 2026-06-03 --host-timestamp checklist-host-smoke" "$external_checklist"; then
  echo "External evidence checklist did not include final evidence wrapper steps." >&2
  exit 1
fi
if ! grep -q "Default finalization command:" "$external_checklist" \
  || ! grep -q "  scripts/finalize-phase-5-evidence.sh$" "$external_checklist" \
  || ! grep -q "  scripts/audit-mvp-next-completion.sh$" "$external_checklist"; then
  echo "External evidence checklist did not put default finalizer and whole-plan audit commands first." >&2
  exit 1
fi
if ! grep -q "Explicit finalization reproducibility:" "$external_checklist"; then
  echo "External evidence checklist did not label explicit finalization commands separately." >&2
  exit 1
fi
if ! grep -q "scripts/audit-mvp-next-completion.sh --plan docs/MVP-Next-Development-Plan.md --product-spec docs/MVP-Product-Spec.md --verification docs/Phase-5-Verification.md --runbook docs/Phase-5-External-Evidence-Runbook.md --evidence docs/phase-5-evidence-2026-05-31.md --manual-dir docs/phase-5-evidence/manual-2026-05-31 --handoff docs/phase-5-evidence/phase-5-external-handoff-2026-06-03.md --date 2026-06-03 --host-timestamp checklist-host-smoke" "$external_checklist"; then
  echo "External evidence checklist did not include whole-plan completion audit guidance." >&2
  exit 1
fi
if ! grep -q "scripts/record-phase-5-completeness-gates.sh" "$external_checklist"; then
  echo "External evidence checklist did not include equivalent manual completeness gate steps." >&2
  exit 1
fi
if ! grep -q "scripts/report-phase-5-status.sh --evidence docs/phase-5-evidence-2026-05-31.md --date 2026-06-03 --host-timestamp checklist-host-smoke --fail-on-incomplete" "$external_checklist"; then
  echo "External evidence checklist did not include deterministic final status report guidance." >&2
  exit 1
fi
if ! grep -q "The finalizer checks the Phase 5 evidence directory cleanliness and evidence template" "$external_checklist"; then
  echo "External evidence checklist did not explain finalizer evidence cleanliness and template checks." >&2
  exit 1
fi
if grep -q "swift run PickoBenchmarks --photos" "$external_checklist"; then
  echo "External evidence checklist suggested the unguarded Photos benchmark command." >&2
  exit 1
fi

echo "== Environment evidence updater smoke =="
environment_update_evidence="/tmp/picko-phase-5-environment-update-evidence.md"
cat > "$environment_update_evidence" <<'MARKDOWN'
| Field | Value |
| --- | --- |
| macOS | 26.4, build 25E246 |
| Xcode | Xcode 26.5 Build version 17F42 |
| Architecture | arm64 |
| iOS Simulator | TBD |
| Test Photos Library | Non-production / TBD |
MARKDOWN
scripts/update-phase-5-environment.sh \
  --evidence "$environment_update_evidence" \
  --field "iOS Simulator" \
  --value "iPhone 17 Pro, iOS 26.4, disposable Photos library"
if ! grep -q '| iOS Simulator | iPhone 17 Pro, iOS 26.4, disposable Photos library |' "$environment_update_evidence"; then
  echo "Environment updater did not update the iOS Simulator row." >&2
  exit 1
fi
scripts/update-phase-5-environment.sh \
  --evidence "$environment_update_evidence" \
  --field "Test Photos Library" \
  --value "Non-production simulator fixture and non-production Mac Photos library"
if ! grep -q '| Test Photos Library | Non-production simulator fixture and non-production Mac Photos library |' "$environment_update_evidence"; then
  echo "Environment updater did not update the Test Photos Library row." >&2
  exit 1
fi
if scripts/update-phase-5-environment.sh \
  --evidence "$environment_update_evidence" \
  --field "Test Photos Library" \
  --value "Production personal Photos library" >/dev/null; then
  echo "Environment updater accepted a production Photos library value." >&2
  exit 1
fi
if scripts/update-phase-5-environment.sh \
  --evidence "$environment_update_evidence" \
  --field "Unknown Field" \
  --value "Non-production" >/dev/null; then
  echo "Environment updater accepted an unknown field." >&2
  exit 1
fi

echo "== Host baseline evidence updater smoke =="
host_update_evidence="/tmp/picko-phase-5-host-update-evidence.md"
host_update_json="docs/phase-5-evidence/metadata-baseline-photos-1000-10000-50000-host-smoke.json"
host_update_synthetic_json="docs/phase-5-evidence/metadata-baseline-photos-1000-10000-50000-synthetic-smoke.json"
host_update_bad_name_json="docs/phase-5-evidence/host-baseline-smoke.json"
mkdir -p "$(dirname "$host_update_json")"
cat > "$host_update_evidence" <<'MARKDOWN'
| Asset count | Elapsed seconds | Assets / second | Notes |
| ---: | ---: | ---: | --- |
| 1,000 | TBD | TBD | TBD |
| 10,000 | TBD | TBD | TBD |
| 50,000 | TBD | TBD | TBD |

Raw JSON evidence path: `TBD`
MARKDOWN
printf '{"mode":"Photos-backed fixture","photosLibraryLabel":"Non-production smoke library","rows":[{"assetCount":1000,"elapsedSeconds":1.0,"assetsPerSecond":1000.0},{"assetCount":10000,"elapsedSeconds":2.0,"assetsPerSecond":5000.0},{"assetCount":50000,"elapsedSeconds":10.0,"assetsPerSecond":5000.0}]}\n' > "$host_update_json"
printf '{"mode":"Photos-backed fixture","photosLibraryLabel":"Non-production smoke library","rows":[{"assetCount":1000,"elapsedSeconds":1.0,"assetsPerSecond":1000.0},{"assetCount":10000,"elapsedSeconds":2.0,"assetsPerSecond":5000.0},{"assetCount":50000,"elapsedSeconds":10.0,"assetsPerSecond":5000.0}]}\n' > "$host_update_bad_name_json"
host_update_missing_preflight_evidence="/tmp/picko-phase-5-host-update-missing-preflight-evidence.md"
cp "$host_update_evidence" "$host_update_missing_preflight_evidence"
if scripts/update-phase-5-host-baseline.sh \
  --evidence "$host_update_missing_preflight_evidence" \
  --baseline-json "$host_update_json" >/dev/null; then
  echo "Host baseline evidence updater accepted evidence without a complete --validate-only preflight command." >&2
  exit 1
fi
host_update_sensitive_preflight_evidence="/tmp/picko-phase-5-host-update-sensitive-preflight-evidence.md"
{
  printf '## Host Photos-Backed Metadata Baseline\n'
  printf 'scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production production library" --validate-only 1000 10000 50000\n'
  printf 'Preflight status: Passed locally in smoke with --validate-only; no Photos library was read.\n'
  cat "$host_update_evidence"
} > "$host_update_sensitive_preflight_evidence"
if scripts/update-phase-5-host-baseline.sh \
  --evidence "$host_update_sensitive_preflight_evidence" \
  --baseline-json "$host_update_json" >/dev/null; then
  echo "Host baseline evidence updater accepted a preflight label that references a production library." >&2
  exit 1
fi
host_update_wrong_section_preflight_evidence="/tmp/picko-phase-5-host-update-wrong-section-preflight-evidence.md"
{
  printf '## Operator Notes\n'
  printf 'scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production smoke library" --validate-only 1000 10000 50000\n'
  printf 'Preflight status: Passed locally in smoke with --validate-only; no Photos library was read.\n'
  cat "$host_update_evidence"
} > "$host_update_wrong_section_preflight_evidence"
if scripts/update-phase-5-host-baseline.sh \
  --evidence "$host_update_wrong_section_preflight_evidence" \
  --baseline-json "$host_update_json" >/dev/null; then
  echo "Host baseline evidence updater accepted a preflight command outside the host baseline section." >&2
  exit 1
fi
host_update_missing_preflight_status_evidence="/tmp/picko-phase-5-host-update-missing-preflight-status-evidence.md"
{
  printf '## Host Photos-Backed Metadata Baseline\n'
  printf 'scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production smoke library" --validate-only 1000 10000 50000\n'
  cat "$host_update_evidence"
} > "$host_update_missing_preflight_status_evidence"
if scripts/update-phase-5-host-baseline.sh \
  --evidence "$host_update_missing_preflight_status_evidence" \
  --baseline-json "$host_update_json" >/dev/null; then
  echo "Host baseline evidence updater accepted evidence without a Passed preflight status." >&2
  exit 1
fi
if scripts/update-phase-5-host-baseline.sh \
  --evidence "$host_update_evidence" \
  --baseline-json "$host_update_bad_name_json" >/dev/null; then
  echo "Host baseline evidence updater accepted a JSON filename outside the formal capture naming scheme." >&2
  exit 1
fi
{
  printf '## Host Photos-Backed Metadata Baseline\n'
  printf 'scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production smoke library" --validate-only 1000 10000 50000\n'
  printf 'Preflight status: Passed locally in smoke with --validate-only; no Photos library was read.\n'
  cat "$host_update_evidence"
} > "$host_update_evidence.with-preflight"
mv "$host_update_evidence.with-preflight" "$host_update_evidence"
scripts/update-phase-5-host-baseline.sh \
  --evidence "$host_update_evidence" \
  --baseline-json "$host_update_json"
if ! grep -q '| 10,000 | 2.0000 | 5000.0000 | Photos-backed fixture; Non-production smoke library |' "$host_update_evidence"; then
  echo "Host baseline evidence updater did not update the expected row." >&2
  exit 1
fi
if ! grep -q "Raw JSON evidence path: \`$host_update_json\`" "$host_update_evidence"; then
  echo "Host baseline evidence updater did not update the raw JSON path." >&2
  exit 1
fi

printf '{"mode":"Synthetic fixture","rows":[{"assetCount":1000,"elapsedSeconds":1.0,"assetsPerSecond":1000.0},{"assetCount":10000,"elapsedSeconds":2.0,"assetsPerSecond":5000.0},{"assetCount":50000,"elapsedSeconds":10.0,"assetsPerSecond":5000.0}]}\n' > "$host_update_synthetic_json"
if scripts/update-phase-5-host-baseline.sh \
  --evidence "$host_update_evidence" \
  --baseline-json "$host_update_synthetic_json" >/dev/null; then
  echo "Host baseline evidence updater accepted a synthetic baseline JSON." >&2
  exit 1
fi
printf '{"mode":"Photos-backed fixture","photosLibraryLabel":"Non-production personal library","rows":[{"assetCount":1000,"elapsedSeconds":1.0,"assetsPerSecond":1000.0},{"assetCount":10000,"elapsedSeconds":2.0,"assetsPerSecond":5000.0},{"assetCount":50000,"elapsedSeconds":10.0,"assetsPerSecond":5000.0}]}\n' > "$host_update_synthetic_json"
if scripts/update-phase-5-host-baseline.sh \
  --evidence "$host_update_evidence" \
  --baseline-json "$host_update_synthetic_json" >/dev/null; then
  echo "Host baseline evidence updater accepted a label that references a personal library." >&2
  exit 1
fi
rm -f "$host_update_json" "$host_update_synthetic_json" "$host_update_bad_name_json"

echo "== Automated gate evidence updater smoke =="
gate_update_evidence="/tmp/picko-phase-5-gate-update-evidence.md"
cat > "$gate_update_evidence" <<'MARKDOWN'
| Gate | Command | Result | Evidence |
| --- | --- | --- | --- |
| Local Phase 5 | `scripts/verify-phase-5-local.sh` | TBD | TBD |
| Platform Phase 5 | `scripts/verify-phase-5-platform.sh` | TBD | TBD |
MARKDOWN
scripts/update-phase-5-gate.sh \
  --evidence "$gate_update_evidence" \
  --gate "Local Phase 5" \
  --result "Passed" \
  --artifact "Terminal smoke"
if ! grep -q '| Local Phase 5 | `scripts/verify-phase-5-local.sh` | Passed | Terminal smoke |' "$gate_update_evidence"; then
  echo "Automated gate evidence updater did not update the expected row." >&2
  exit 1
fi

if scripts/update-phase-5-gate.sh \
  --evidence "$gate_update_evidence" \
  --gate "Unknown Gate" \
  --result "Passed" \
  --artifact "Terminal smoke" >/dev/null; then
  echo "Automated gate evidence updater accepted an unknown gate." >&2
  exit 1
fi

if scripts/update-phase-5-gate.sh \
  --evidence "$gate_update_evidence" \
  --gate "Local Phase 5" \
  --result "Passed" \
  --artifact "TBD" >/dev/null; then
  echo "Automated gate evidence updater accepted a placeholder artifact." >&2
  exit 1
fi

if scripts/update-phase-5-gate.sh \
  --evidence "$gate_update_evidence" \
  --gate "Local Phase 5" \
  --result "Passed" \
  --artifact "Terminal smoke | table break" >/dev/null; then
  echo "Automated gate evidence updater accepted a table-breaking artifact." >&2
  exit 1
fi

echo "== Completeness gate recorder smoke =="
complete_gate_evidence="/tmp/picko-phase-5-completeness-gate-evidence.md"
complete_gate_manual_dir="$(scripts/prepare-phase-5-manual-evidence.sh --output "/tmp/picko-phase-5-completeness-gate-manual-$$")"
complete_gate_baseline="/tmp/picko-phase-5-completeness-gate-baseline.json"
for evidence_dir in \
  "$complete_gate_manual_dir/ios/authorization" \
  "$complete_gate_manual_dir/ios/limited-library" \
  "$complete_gate_manual_dir/ios/delete-confirmation" \
  "$complete_gate_manual_dir/ios/metadata-benchmark" \
  "$complete_gate_manual_dir/macos/authorization" \
  "$complete_gate_manual_dir/macos/delete-confirmation" \
  "$complete_gate_manual_dir/privacy"
do
  printf 'non-production evidence placeholder\n' > "$evidence_dir/evidence.txt"
done
printf '{"mode":"Photos-backed fixture","photosLibraryLabel":"Non-production smoke library","rows":[{"assetCount":1000,"elapsedSeconds":1.0,"assetsPerSecond":1000.0},{"assetCount":10000,"elapsedSeconds":2.0,"assetsPerSecond":5000.0},{"assetCount":50000,"elapsedSeconds":10.0,"assetsPerSecond":5000.0}]}\n' > "$complete_gate_baseline"
cat > "$complete_gate_evidence" <<MARKDOWN
| Field | Value |
| --- | --- |
| iOS Simulator | iPhone 17 Pro, iOS 26.4, disposable Photos library |
| Test Photos Library | Non-production simulator fixture and non-production Mac Photos library |

| Gate | Command | Result | Evidence |
| --- | --- | --- | --- |
| Evidence completeness | \`scripts/check-phase-5-evidence.sh docs/phase-5-evidence-YYYY-MM-DD.md\` | TBD | TBD |
| Manual evidence completeness | \`scripts/check-phase-5-manual-evidence.sh $complete_gate_manual_dir\` | TBD | \`$complete_gate_manual_dir/README.md\` |

## Host Photos-Backed Metadata Baseline

scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production smoke library" --validate-only 1000 10000 50000
Preflight status: Passed locally in smoke with --validate-only; no Photos library was read.
Host Photos baseline: $complete_gate_baseline
## iOS Simulator Photos-Backed Benchmark

| 1,000 | 1.0000 | 1000.0000 | docs/phase-5-evidence/ios-metadata-benchmark/photos-1000-2026-05-31.jpg |
| 10,000 | 2.0000 | 5000.0000 | docs/phase-5-evidence/ios-metadata-benchmark/photos-1000-2026-05-31.jpg |
| 50,000 | 10.0000 | 5000.0000 | docs/phase-5-evidence/ios-metadata-benchmark/photos-1000-2026-05-31.jpg |

## Privacy Review

| Check | Result | Evidence |
| --- | --- | --- |
| Runtime logs checked for photo contents or sensitive metadata | Passed | scripts/audit-runtime-privacy-logs.sh /tmp/picko-runtime-log-smoke.log |

| Scenario | Platform | Result | Evidence path | Notes |
| --- | --- | --- | --- | --- |
| First Photos authorization | iOS | Passed | \`$complete_gate_manual_dir/ios/authorization/evidence.txt\` | Non-production smoke |
| Limited library state | iOS | Passed | \`$complete_gate_manual_dir/ios/limited-library/evidence.txt\` | Non-production smoke |
| Pre-delete basket triggers Photos confirmation | iOS | Passed | \`$complete_gate_manual_dir/ios/delete-confirmation/evidence.txt\` | Non-production smoke |
| First Photos authorization | macOS | Passed | \`$complete_gate_manual_dir/macos/authorization/evidence.txt\` | Non-production smoke |
| Pre-delete basket triggers Photos confirmation | macOS | Passed | \`$complete_gate_manual_dir/macos/delete-confirmation/evidence.txt\` | Non-production smoke |
| Recently Deleted recovery explanation | iOS/macOS | Passed | \`$complete_gate_manual_dir/privacy/evidence.txt\` | Non-production smoke |

Manual evidence checked: scripts/check-phase-5-manual-evidence.sh $complete_gate_manual_dir
MARKDOWN
scripts/record-phase-5-completeness-gates.sh \
  --allow-temp \
  --artifact-prefix "Terminal smoke" \
  --evidence "$complete_gate_evidence"
if ! grep -q '| Evidence completeness | `scripts/check-phase-5-evidence.sh docs/phase-5-evidence-YYYY-MM-DD.md` | Passed | Terminal smoke: scripts/check-phase-5-evidence.sh --allow-temp /tmp/picko-phase-5-completeness-gate-evidence.md |' "$complete_gate_evidence"; then
  echo "Completeness gate recorder did not update the evidence completeness row." >&2
  exit 1
fi
if ! grep -q "| Manual evidence completeness | \`scripts/check-phase-5-manual-evidence.sh $complete_gate_manual_dir\` | Passed | Terminal smoke: scripts/check-phase-5-manual-evidence.sh $complete_gate_manual_dir |" "$complete_gate_evidence"; then
  echo "Completeness gate recorder did not update the manual evidence completeness row." >&2
  exit 1
fi

if scripts/record-phase-5-completeness-gates.sh \
  --allow-temp \
  --artifact-prefix "TBD" \
  --evidence "$complete_gate_evidence" >/dev/null; then
  echo "Completeness gate recorder accepted a placeholder artifact prefix." >&2
  exit 1
fi

if scripts/record-phase-5-completeness-gates.sh \
  --allow-temp \
  --artifact-prefix "Terminal | smoke" \
  --evidence "$complete_gate_evidence" >/dev/null; then
  echo "Completeness gate recorder accepted a table-breaking artifact prefix." >&2
  exit 1
fi

project_allow_temp_gate_evidence="docs/phase-5-evidence/completeness-gate-allow-temp-smoke.md"
cp "$complete_gate_evidence" "$project_allow_temp_gate_evidence"
if scripts/record-phase-5-completeness-gates.sh \
  --allow-temp \
  --artifact-prefix "Terminal smoke" \
  --evidence "$project_allow_temp_gate_evidence" >/dev/null; then
  rm -f "$project_allow_temp_gate_evidence"
  echo "Completeness gate recorder accepted --allow-temp for project evidence." >&2
  exit 1
fi
rm -f "$project_allow_temp_gate_evidence"

incomplete_gate_evidence="/tmp/picko-phase-5-completeness-gate-incomplete.md"
cp "$complete_gate_evidence" "$incomplete_gate_evidence"
sed -i '' 's/Host Photos baseline:/Host Photos baseline: TBD/' "$incomplete_gate_evidence"
if scripts/record-phase-5-completeness-gates.sh \
  --allow-temp \
  --artifact-prefix "Terminal smoke" \
  --evidence "$incomplete_gate_evidence" >/dev/null; then
  echo "Completeness gate recorder accepted incomplete evidence." >&2
  exit 1
fi

if scripts/finalize-phase-5-evidence.sh \
  --allow-temp \
  --artifact-prefix "TBD" \
  --evidence "$complete_gate_evidence" \
  --manual-dir "$complete_gate_manual_dir" \
  --date 2026-06-03 \
  --host-timestamp finalizer-host-smoke >/dev/null; then
  echo "Final evidence wrapper accepted a placeholder artifact prefix." >&2
  exit 1
fi

if scripts/finalize-phase-5-evidence.sh \
  --allow-temp \
  --artifact-prefix "Terminal smoke" \
  --evidence "$complete_gate_evidence" \
  --manual-dir "$complete_gate_manual_dir" \
  --date 2026-06-03 \
  --host-timestamp "bad/path" >/dev/null; then
  echo "Final evidence wrapper accepted a non filename-safe host timestamp." >&2
  exit 1
fi

if ! scripts/finalize-phase-5-evidence.sh --help \
  | grep -q "Defaults to the latest external handoff's"; then
  echo "Final evidence wrapper help does not document default handoff timestamp behavior." >&2
  exit 1
fi
if ! scripts/finalize-phase-5-evidence.sh --help \
  | grep -q "latest docs/phase-5-evidence-YYYY-MM-DD.md file"; then
  echo "Final evidence wrapper help does not document default evidence behavior." >&2
  exit 1
fi

if scripts/finalize-phase-5-evidence.sh \
  --allow-temp \
  --artifact-prefix "Terminal smoke" \
  --evidence "$incomplete_gate_evidence" \
  --manual-dir "$complete_gate_manual_dir" \
  --date 2026-06-03 \
  --host-timestamp finalizer-host-smoke >/dev/null; then
  echo "Final evidence wrapper accepted incomplete evidence." >&2
  exit 1
fi

finalizer_default_timestamp_evidence="/tmp/picko-phase-5-finalizer-default-timestamp.md"
cp "$complete_gate_evidence" "$finalizer_default_timestamp_evidence"
finalizer_default_timestamp_log="/tmp/picko-phase-5-finalizer-default-timestamp.log"
if scripts/finalize-phase-5-evidence.sh \
  --allow-temp \
  --artifact-prefix "Terminal smoke" \
  --evidence "$finalizer_default_timestamp_evidence" \
  --manual-dir "$complete_gate_manual_dir" \
  --date 2026-06-03 > "$finalizer_default_timestamp_log"; then
  :
fi
if ! grep -q -- "--host-timestamp 20260603-photos-baseline" "$finalizer_default_timestamp_log"; then
  echo "Final evidence wrapper default host timestamp did not use the latest handoff timestamp." >&2
  exit 1
fi
if grep -q -- "metadata-baseline-photos-1000-10000-50000-[0-9]\\{8\\}-[0-9]\\{6\\}.json" "$finalizer_default_timestamp_log"; then
  echo "Final evidence wrapper default host timestamp used a fresh timestamp instead of the latest handoff timestamp." >&2
  exit 1
fi

finalizer_default_workspace="/tmp/picko-phase-5-finalizer-default-workspace"
rm -rf "$finalizer_default_workspace"
mkdir -p "$finalizer_default_workspace/docs/phase-5-evidence"
cp -R docs/phase-5-evidence/. "$finalizer_default_workspace/docs/phase-5-evidence/"
cp docs/Phase-5-Evidence-Template.md "$finalizer_default_workspace/docs/Phase-5-Evidence-Template.md"
cp "$complete_gate_evidence" "$finalizer_default_workspace/docs/phase-5-evidence-2026-05-31.md"
rm -rf "$finalizer_default_workspace/docs/phase-5-evidence/manual-2026-05-31"
cp -R "$complete_gate_manual_dir" "$finalizer_default_workspace/docs/phase-5-evidence/manual-2026-05-31"
cp docs/phase-5-evidence/phase-5-external-handoff-2026-06-03.md "$finalizer_default_workspace/docs/phase-5-evidence/phase-5-external-handoff-2026-06-03.md"
ln -s "$PWD/scripts" "$finalizer_default_workspace/scripts"
finalizer_default_workspace_log="/tmp/picko-phase-5-finalizer-default-workspace.log"
(
  cd "$finalizer_default_workspace"
  if scripts/finalize-phase-5-evidence.sh --allow-temp --artifact-prefix "Terminal smoke"; then
    :
  fi
) > "$finalizer_default_workspace_log"
if ! grep -q "Final evidence document candidate: .*/docs/phase-5-evidence-2026-05-31.md" "$finalizer_default_workspace_log"; then
  echo "Final evidence wrapper did not default to the latest evidence document." >&2
  exit 1
fi
if ! grep -q -- "--host-timestamp 20260603-photos-baseline" "$finalizer_default_workspace_log"; then
  echo "Final evidence wrapper default command did not use the latest handoff timestamp." >&2
  exit 1
fi
rm -rf "$finalizer_default_workspace"

project_finalizer_smoke="docs/phase-5-evidence/finalizer-cleanliness-smoke.tmp"
printf 'local smoke artifact\n' > "$project_finalizer_smoke"
if scripts/finalize-phase-5-evidence.sh \
  --allow-temp \
  --artifact-prefix "Terminal smoke" \
  --evidence "$complete_gate_evidence" \
  --manual-dir "$complete_gate_manual_dir" \
  --date 2026-06-03 \
  --host-timestamp finalizer-host-smoke >/dev/null; then
  rm -f "$project_finalizer_smoke"
  echo "Final evidence wrapper accepted a polluted project evidence directory." >&2
  exit 1
fi
rm -f "$project_finalizer_smoke"

echo "== Privacy review evidence updater smoke =="
privacy_update_evidence="/tmp/picko-phase-5-privacy-update-evidence.md"
cat > "$privacy_update_evidence" <<'MARKDOWN'
| Check | Result | Evidence |
| --- | --- | --- |
| Product code has no broad logging calls | TBD | `scripts/audit-privacy-logging.sh` |
| Thumbnail cache remains in process memory only | TBD | Code review / TBD |
MARKDOWN
scripts/update-phase-5-privacy-review.sh \
  --evidence "$privacy_update_evidence" \
  --check "Thumbnail cache remains in process memory only" \
  --result "Passed" \
  --artifact "Code review smoke"
if ! grep -q '| Thumbnail cache remains in process memory only | Passed | Code review smoke |' "$privacy_update_evidence"; then
  echo "Privacy review evidence updater did not update the expected row." >&2
  exit 1
fi

if scripts/update-phase-5-privacy-review.sh \
  --evidence "$privacy_update_evidence" \
  --check "Unknown privacy check" \
  --result "Passed" \
  --artifact "Code review smoke" >/dev/null; then
  echo "Privacy review evidence updater accepted an unknown check." >&2
  exit 1
fi

if scripts/update-phase-5-privacy-review.sh \
  --evidence "$privacy_update_evidence" \
  --check "Thumbnail cache remains in process memory only" \
  --result "Passed" \
  --artifact "TBD" >/dev/null; then
  echo "Privacy review evidence updater accepted a placeholder artifact." >&2
  exit 1
fi

if scripts/update-phase-5-privacy-review.sh \
  --evidence "$privacy_update_evidence" \
  --check "Thumbnail cache remains in process memory only" \
  --result "Passed" \
  --artifact "Code review | table break" >/dev/null; then
  echo "Privacy review evidence updater accepted a table-breaking artifact." >&2
  exit 1
fi

echo "== Runtime privacy evidence recorder smoke =="
runtime_privacy_evidence="/tmp/picko-phase-5-runtime-privacy-evidence.md"
runtime_privacy_log="docs/phase-5-evidence/privacy/runtime-smoke.log"
mkdir -p "$(dirname "$runtime_privacy_log")"
printf 'Runtime verification completed without sensitive fields.\n' > "$runtime_privacy_log"
cat > "$runtime_privacy_evidence" <<'MARKDOWN'
| Check | Result | Evidence |
| --- | --- | --- |
| Runtime logs checked for photo contents or sensitive metadata | TBD | `scripts/audit-runtime-privacy-logs.sh docs/phase-5-evidence/privacy/LOG_PATH` / TBD |
MARKDOWN
scripts/record-runtime-privacy-evidence.sh \
  --evidence "$runtime_privacy_evidence" \
  --log "$runtime_privacy_log"
if ! grep -q '| Runtime logs checked for photo contents or sensitive metadata | Passed | scripts/audit-runtime-privacy-logs.sh docs/phase-5-evidence/privacy/runtime-smoke.log |' "$runtime_privacy_evidence"; then
  echo "Runtime privacy evidence recorder did not update the expected row." >&2
  exit 1
fi
rm -f "$runtime_privacy_log"

printf 'localIdentifier: secret\n' > /tmp/picko-runtime-sensitive-smoke.log
if scripts/record-runtime-privacy-evidence.sh \
  --evidence "$runtime_privacy_evidence" \
  --log /tmp/picko-runtime-sensitive-smoke.log >/dev/null; then
  echo "Runtime privacy evidence recorder accepted a non-project log path." >&2
  exit 1
fi

echo "== Manual verification evidence updater smoke =="
manual_update_evidence="/tmp/picko-phase-5-manual-update-evidence.md"
manual_update_artifact="docs/phase-5-evidence/manual-smoke/ios/authorization/evidence.txt"
mkdir -p "$(dirname "$manual_update_artifact")"
printf 'non-production manual evidence smoke\n' > "$manual_update_artifact"
cat > "$manual_update_evidence" <<'MARKDOWN'
| Scenario | Platform | Result | Evidence path | Notes |
| --- | --- | --- | --- | --- |
| First Photos authorization | iOS | TBD | TBD | TBD |
| First Photos authorization | macOS | TBD | TBD | TBD |
MARKDOWN
scripts/update-phase-5-manual-verification.sh \
  --evidence "$manual_update_evidence" \
  --scenario "First Photos authorization" \
  --platform "iOS" \
  --result "Passed" \
  --path "$manual_update_artifact" \
  --notes "Manual updater smoke"
if ! grep -q '| First Photos authorization | iOS | Passed | `docs/phase-5-evidence/manual-smoke/ios/authorization/evidence.txt` | Manual updater smoke |' "$manual_update_evidence"; then
  echo "Manual verification evidence updater did not update the expected row." >&2
  exit 1
fi
rm -f "$manual_update_artifact"

if scripts/update-phase-5-manual-verification.sh \
  --evidence "$manual_update_evidence" \
  --scenario "Unknown scenario" \
  --platform "iOS" \
  --result "Passed" \
  --path /tmp/not-project-evidence.txt \
  --notes "Manual updater smoke" >/dev/null; then
  echo "Manual verification evidence updater accepted an unknown scenario." >&2
  exit 1
fi

manual_mismatch_artifact="docs/phase-5-evidence/manual-smoke/ios/authorization/evidence.txt"
mkdir -p "$(dirname "$manual_mismatch_artifact")"
printf 'non-production mismatched manual evidence smoke\n' > "$manual_mismatch_artifact"
if scripts/update-phase-5-manual-verification.sh \
  --evidence "$manual_update_evidence" \
  --scenario "First Photos authorization" \
  --platform "macOS" \
  --result "Passed" \
  --path "$manual_mismatch_artifact" \
  --notes "Manual updater smoke" >/dev/null; then
  echo "Manual verification evidence updater accepted a path from the wrong scenario folder." >&2
  exit 1
fi
rm -f "$manual_mismatch_artifact"

manual_directory_artifact_dir="docs/phase-5-evidence/manual-smoke/macos/authorization"
mkdir -p "$manual_directory_artifact_dir"
if scripts/update-phase-5-manual-verification.sh \
  --evidence "$manual_update_evidence" \
  --scenario "First Photos authorization" \
  --platform "macOS" \
  --result "Passed" \
  --path "$manual_directory_artifact_dir" \
  --notes "Manual updater smoke" >/dev/null; then
  echo "Manual verification evidence updater accepted a directory instead of a captured artifact file." >&2
  exit 1
fi

manual_unsupported_update_artifact="docs/phase-5-evidence/manual-smoke/macos/authorization/evidence.swift"
printf 'not a captured evidence artifact\n' > "$manual_unsupported_update_artifact"
if scripts/update-phase-5-manual-verification.sh \
  --evidence "$manual_update_evidence" \
  --scenario "First Photos authorization" \
  --platform "macOS" \
  --result "Passed" \
  --path "$manual_unsupported_update_artifact" \
  --notes "Manual updater smoke" >/dev/null; then
  echo "Manual verification evidence updater accepted an unsupported artifact file type." >&2
  exit 1
fi
rm -f "$manual_unsupported_update_artifact"

manual_bad_notes_artifact="docs/phase-5-evidence/manual-smoke/macos/authorization/evidence.txt"
printf 'non-production bad notes smoke\n' > "$manual_bad_notes_artifact"
if scripts/update-phase-5-manual-verification.sh \
  --evidence "$manual_update_evidence" \
  --scenario "First Photos authorization" \
  --platform "macOS" \
  --result "Passed" \
  --path "$manual_bad_notes_artifact" \
  --notes "TBD" >/dev/null; then
  echo "Manual verification evidence updater accepted placeholder notes." >&2
  exit 1
fi
if scripts/update-phase-5-manual-verification.sh \
  --evidence "$manual_update_evidence" \
  --scenario "First Photos authorization" \
  --platform "macOS" \
  --result "Passed" \
  --path "$manual_bad_notes_artifact" \
  --notes "Non-production | table break" >/dev/null; then
  echo "Manual verification evidence updater accepted table-breaking notes." >&2
  exit 1
fi
if scripts/update-phase-5-manual-verification.sh \
  --evidence "$manual_update_evidence" \
  --scenario "First Photos authorization" \
  --platform "macOS" \
  --result "Passed" \
  --path "$manual_bad_notes_artifact" \
  --notes "Production Photos library" >/dev/null; then
  echo "Manual verification evidence updater accepted personal/production Photos notes." >&2
  exit 1
fi
rm -f "$manual_bad_notes_artifact"

manual_sensitive_content_update_artifact="docs/phase-5-evidence/manual-smoke/macos/authorization/sensitive.txt"
printf 'localIdentifier: sensitive-smoke\n' > "$manual_sensitive_content_update_artifact"
if scripts/update-phase-5-manual-verification.sh \
  --evidence "$manual_update_evidence" \
  --scenario "First Photos authorization" \
  --platform "macOS" \
  --result "Passed" \
  --path "$manual_sensitive_content_update_artifact" \
  --notes "Non-production smoke" >/dev/null; then
  echo "Manual verification evidence updater accepted a text artifact containing sensitive metadata." >&2
  exit 1
fi
rm -f "$manual_sensitive_content_update_artifact"
manual_empty_update_artifact="docs/phase-5-evidence/manual-smoke/macos/authorization/empty.txt"
: > "$manual_empty_update_artifact"
if scripts/update-phase-5-manual-verification.sh \
  --evidence "$manual_update_evidence" \
  --scenario "First Photos authorization" \
  --platform "macOS" \
  --result "Passed" \
  --path "$manual_empty_update_artifact" \
  --notes "Non-production smoke" >/dev/null; then
  echo "Manual verification evidence updater accepted an empty manual artifact file." >&2
  exit 1
fi
rm -f "$manual_empty_update_artifact"

echo "== Phase 5 status report smoke =="
status_default_smoke="/tmp/picko-phase-5-status-default-smoke.log"
scripts/report-phase-5-status.sh > "$status_default_smoke"
for expected_text in \
  "Final evidence document candidate: docs/phase-5-evidence-2026-05-31.md" \
  "For the default active-package command sequence, run scripts/phase-5-external-evidence-checklist.sh." \
  "For explicit reproducibility, run scripts/phase-5-external-evidence-checklist.sh --evidence docs/phase-5-evidence-2026-05-31.md --manual-dir docs/phase-5-evidence/manual-2026-05-31 --date 2026-06-03 --host-timestamp 20260603-photos-baseline." \
  "After all rows and evidence files are written back, run scripts/finalize-phase-5-evidence.sh, then run scripts/audit-mvp-next-completion.sh." \
  "Host Photos-backed baseline on a non-production Mac Photos library: run scripts/prepare-phase-5-host-baseline-capture.sh. Explicit reproducibility: scripts/prepare-phase-5-host-baseline-capture.sh --evidence docs/phase-5-evidence-2026-05-31.md --label \"Non-production Mac Photos test library\" --timestamp 20260603-photos-baseline --date 2026-06-03."
do
  if ! grep -q "$expected_text" "$status_default_smoke"; then
    echo "Phase 5 default status report is missing expected text: $expected_text" >&2
    exit 1
  fi
done
status_missing_environment_evidence="/tmp/picko-phase-5-status-missing-environment.md"
cat > "$status_missing_environment_evidence" <<'MARKDOWN'
| Field | Value |
| --- | --- |
| iOS Simulator | TBD |
| Test Photos Library | Non-production / TBD |
MARKDOWN
scripts/report-phase-5-status.sh \
  --evidence "$status_missing_environment_evidence" \
  --date 2026-06-03 \
  --host-timestamp status-host-smoke >/tmp/picko-phase-5-status-smoke.log
if ! grep -q "Picko Phase 5 Status" /tmp/picko-phase-5-status-smoke.log; then
  echo "Phase 5 status report did not print the expected heading." >&2
  exit 1
fi

if ! grep -q "Environment row is missing concrete value: iOS Simulator." /tmp/picko-phase-5-status-smoke.log; then
  echo "Phase 5 status report did not flag the missing iOS Simulator environment row." >&2
  exit 1
fi

if ! grep -q "Environment row is missing concrete non-production value: Test Photos Library." /tmp/picko-phase-5-status-smoke.log; then
  echo "Phase 5 status report did not flag the missing Test Photos Library environment row." >&2
  exit 1
fi

status_ready_evidence="/tmp/picko-phase-5-status-ready-environment.md"
status_partial_environment_evidence="/tmp/picko-phase-5-status-partial-environment.md"
status_ios_evidence="/tmp/picko-phase-5-status-ios-evidence.md"
status_ios_artifact="docs/phase-5-evidence/status-ios-smoke/photos-1000-smoke.jpg"
status_ios_unsupported_evidence="/tmp/picko-phase-5-status-ios-unsupported-evidence.md"
status_ios_unsupported_artifact="docs/phase-5-evidence/status-ios-smoke/unsupported-1000.txt"
status_stray_baseline="docs/phase-5-evidence/status-stray-baseline-smoke.json"
status_ready_preflight_evidence="/tmp/picko-phase-5-status-ready-preflight.md"
cat > "$status_ready_evidence" <<'MARKDOWN'
| Field | Value |
| --- | --- |
| iOS Simulator | iPhone 17 Pro, iOS 26.4, disposable Photos library |
| Test Photos Library | Non-production simulator fixture and non-production Mac Photos library |
MARKDOWN
cat > "$status_partial_environment_evidence" <<'MARKDOWN'
| Field | Value |
| --- | --- |
| iOS Simulator | iPhone 17 Pro, iOS 26.5 Simulator |
| Test Photos Library | Non-production / TBD |
MARKDOWN
mkdir -p "$(dirname "$status_ios_artifact")"
printf 'non-production benchmark screenshot smoke\n' > "$status_ios_artifact"
cat > "$status_ios_evidence" <<MARKDOWN
## iOS Simulator Photos-Backed Benchmark

| Asset count | Elapsed seconds | Assets / second | Evidence |
| ---: | ---: | ---: | --- |
| 1,000 | 1.0000 | 1000.0000 | \`$status_ios_artifact\` |
| 10,000 | 2.0000 | 5000.0000 | \`docs/phase-5-evidence/status-ios-smoke/missing-10000.jpg\` |
MARKDOWN
scripts/report-phase-5-status.sh --evidence "$status_ios_evidence" >/tmp/picko-phase-5-status-ios.log
if ! grep -q "iOS Photos-backed benchmark row exists with local evidence for 1,000 assets." /tmp/picko-phase-5-status-ios.log; then
  echo "Phase 5 status report did not mark an existing iOS benchmark artifact ready." >&2
  rm -f "$status_ios_artifact"
  exit 1
fi
if ! grep -q "iOS Photos-backed benchmark row references missing local evidence for 10,000 assets: docs/phase-5-evidence/status-ios-smoke/missing-10000.jpg" /tmp/picko-phase-5-status-ios.log; then
  echo "Phase 5 status report did not flag a missing iOS benchmark artifact." >&2
  rm -f "$status_ios_artifact"
  exit 1
fi
if ! grep -q "iOS Photos-backed benchmark row is missing for 50,000 assets." /tmp/picko-phase-5-status-ios.log; then
  echo "Phase 5 status report did not distinguish a missing iOS benchmark row from a missing artifact." >&2
  rm -f "$status_ios_artifact"
  exit 1
fi
printf 'unsupported benchmark artifact smoke\n' > "$status_ios_unsupported_artifact"
cat > "$status_ios_unsupported_evidence" <<MARKDOWN
## iOS Simulator Photos-Backed Benchmark

| Asset count | Elapsed seconds | Assets / second | Evidence |
| ---: | ---: | ---: | --- |
| 1,000 | 1.0000 | 1000.0000 | \`$status_ios_unsupported_artifact\` |
MARKDOWN
scripts/report-phase-5-status.sh --evidence "$status_ios_unsupported_evidence" >/tmp/picko-phase-5-status-ios-unsupported.log
if grep -q "iOS Photos-backed benchmark row exists with local evidence for 1,000 assets." /tmp/picko-phase-5-status-ios-unsupported.log; then
  echo "Phase 5 status report marked an unsupported iOS benchmark artifact ready." >&2
  rm -f "$status_ios_artifact" "$status_ios_unsupported_artifact"
  exit 1
fi
if ! grep -q "iOS Photos-backed benchmark row references unsupported local evidence for 1,000 assets: $status_ios_unsupported_artifact" /tmp/picko-phase-5-status-ios-unsupported.log; then
  echo "Phase 5 status report did not flag an unsupported iOS benchmark artifact." >&2
  rm -f "$status_ios_artifact" "$status_ios_unsupported_artifact"
  exit 1
fi
rm -f "$status_ios_artifact"
rm -f "$status_ios_unsupported_artifact"
printf '{"mode":"Photos-backed fixture","photosLibraryLabel":"Non-production smoke library","rows":[{"assetCount":1000,"elapsedSeconds":1.0,"assetsPerSecond":1000.0},{"assetCount":10000,"elapsedSeconds":2.0,"assetsPerSecond":5000.0},{"assetCount":50000,"elapsedSeconds":10.0,"assetsPerSecond":5000.0}]}\n' > "$status_stray_baseline"
scripts/report-phase-5-status.sh --evidence "$status_ready_evidence" >/tmp/picko-phase-5-status-ready-environment.log
if ! grep -q "Environment row has concrete value: iOS Simulator." /tmp/picko-phase-5-status-ready-environment.log; then
  echo "Phase 5 status report did not mark the iOS Simulator environment row ready." >&2
  exit 1
fi
if ! grep -q "Environment row has concrete non-production value: Test Photos Library." /tmp/picko-phase-5-status-ready-environment.log; then
  echo "Phase 5 status report did not mark the Test Photos Library environment row ready." >&2
  exit 1
fi
scripts/report-phase-5-status.sh --evidence "$status_partial_environment_evidence" >/tmp/picko-phase-5-status-partial-environment.log
if grep -q "Record concrete iOS Simulator" /tmp/picko-phase-5-status-partial-environment.log; then
  echo "Phase 5 status report asked for iOS Simulator evidence even though that row is ready." >&2
  exit 1
fi
if ! grep -q "Record concrete non-production Photos library environment row." /tmp/picko-phase-5-status-partial-environment.log; then
  echo "Phase 5 status report did not ask for the remaining Test Photos Library environment row." >&2
  exit 1
fi
if ! grep -q "Host Photos-backed 1k/10k/50k baseline JSON is missing." /tmp/picko-phase-5-status-ready-environment.log; then
  echo "Phase 5 status report treated an unreferenced Photos baseline JSON as ready." >&2
  rm -f "$status_stray_baseline"
  exit 1
fi
cat > "$status_ready_preflight_evidence" <<'MARKDOWN'
## Host Photos-Backed Metadata Baseline

Command:

```sh
scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production Mac Photos test library" --validate-only 1000 10000 50000
scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production Mac Photos test library" 1000 10000 50000
```

Preflight status: Passed locally in smoke with `--validate-only`; no Photos library was read.
MARKDOWN
scripts/report-phase-5-status.sh --evidence "$status_ready_preflight_evidence" >/tmp/picko-phase-5-status-ready-preflight.log
if ! grep -q "Preflight is recorded as Passed" /tmp/picko-phase-5-status-ready-preflight.log; then
  echo "Phase 5 status report did not distinguish a recorded host Photos preflight from a missing preflight." >&2
  rm -f "$status_stray_baseline"
  exit 1
fi
if ! grep -q "scripts/prepare-phase-5-host-baseline-capture.sh" /tmp/picko-phase-5-status-ready-preflight.log; then
  echo "Phase 5 status report did not point host baseline capture at the safe preparation helper." >&2
  rm -f "$status_stray_baseline"
  exit 1
fi
scripts/report-phase-5-status.sh \
  --evidence "$status_ready_preflight_evidence" \
  --date 2026-06-03 \
  --host-timestamp ready-preflight-smoke >/tmp/picko-phase-5-status-ready-preflight-timestamp.log
if ! grep -q -- "--timestamp ready-preflight-smoke" /tmp/picko-phase-5-status-ready-preflight-timestamp.log; then
  echo "Phase 5 status report did not include a deterministic timestamp in the ready-preflight host baseline guidance." >&2
  rm -f "$status_stray_baseline"
  exit 1
fi
if ! grep -q -- "--date 2026-06-03" /tmp/picko-phase-5-status-ready-preflight-timestamp.log; then
  echo "Phase 5 status report did not include the deterministic date in the ready-preflight host baseline guidance." >&2
  rm -f "$status_stray_baseline"
  exit 1
fi
rm -f "$status_stray_baseline"

if ! grep -q "Next required external evidence" /tmp/picko-phase-5-status-smoke.log; then
  echo "Phase 5 status report did not print the expected next evidence section." >&2
  exit 1
fi

if ! grep -q "Record concrete iOS Simulator and non-production Photos library environment rows." /tmp/picko-phase-5-status-smoke.log; then
  echo "Phase 5 status report did not include environment write-back in next required evidence." >&2
  exit 1
fi
if ! grep -q "scripts/prepare-phase-5-host-baseline-capture.sh" /tmp/picko-phase-5-status-smoke.log; then
  echo "Phase 5 status report did not include the host baseline preparation helper in next required evidence." >&2
  exit 1
fi
if ! grep -q "For the default active-package command sequence, run scripts/phase-5-external-evidence-checklist.sh." /tmp/picko-phase-5-status-smoke.log; then
  echo "Phase 5 status report did not put the default external evidence checklist command first." >&2
  exit 1
fi
if ! grep -q "For explicit reproducibility, run scripts/phase-5-external-evidence-checklist.sh --evidence" /tmp/picko-phase-5-status-smoke.log \
  || ! grep -q -- "--manual-dir docs/phase-5-evidence/manual-2026-05-31" /tmp/picko-phase-5-status-smoke.log \
  || ! grep -q -- "--date 2026-06-03 --host-timestamp status-host-smoke" /tmp/picko-phase-5-status-smoke.log; then
  echo "Phase 5 status report did not point to the guarded external evidence checklist." >&2
  exit 1
fi
if ! grep -q -- "--timestamp status-host-smoke --date 2026-06-03" /tmp/picko-phase-5-status-smoke.log; then
  echo "Phase 5 status report did not include the deterministic host baseline timestamp." >&2
  exit 1
fi
if ! grep -q "then run scripts/prepare-phase-5-host-baseline-capture.sh before capture and write-back." /tmp/picko-phase-5-status-smoke.log \
  || ! grep -q "Explicit reproducibility: scripts/prepare-phase-5-host-baseline-capture.sh --evidence" /tmp/picko-phase-5-status-smoke.log \
  || ! grep -q -- "--timestamp status-host-smoke --date 2026-06-03" /tmp/picko-phase-5-status-smoke.log; then
  echo "Phase 5 status report did not put the default host baseline helper before explicit reproducibility guidance." >&2
  exit 1
fi
if ! grep -q "scripts/prepare-phase-5-macos-manual-capture.sh" /tmp/picko-phase-5-status-smoke.log; then
  echo "Phase 5 status report did not include the macOS manual capture preparation helper in next required evidence." >&2
  exit 1
fi
if ! grep -q "For macOS captures, run scripts/prepare-phase-5-macos-manual-capture.sh. Explicit reproducibility:" /tmp/picko-phase-5-status-smoke.log \
  || ! grep -q -- "--manual-dir docs/phase-5-evidence/manual-2026-05-31" /tmp/picko-phase-5-status-smoke.log \
  || ! grep -q -- "--date 2026-06-03" /tmp/picko-phase-5-status-smoke.log; then
  echo "Phase 5 status report did not put the default macOS capture helper before explicit reproducibility guidance." >&2
  exit 1
fi
if grep -q "manual-YYYY-MM-DD" /tmp/picko-phase-5-status-smoke.log; then
  echo "Phase 5 status report emitted placeholder manual evidence guidance." >&2
  exit 1
fi
if ! grep -q "After all rows and evidence files are written back, run scripts/finalize-phase-5-evidence.sh, then run scripts/audit-mvp-next-completion.sh." /tmp/picko-phase-5-status-smoke.log; then
  echo "Phase 5 status report did not put the default finalizer and whole-plan audit commands first." >&2
  exit 1
fi
if ! grep -q "For explicit finalization reproducibility, run scripts/finalize-phase-5-evidence.sh --evidence" /tmp/picko-phase-5-status-smoke.log \
  || ! grep -q -- "--date 2026-06-03 --host-timestamp status-host-smoke" /tmp/picko-phase-5-status-smoke.log; then
  echo "Phase 5 status report did not include final evidence wrapper guidance." >&2
  exit 1
fi
if ! grep -q "Phase 5 shell literal safety gate" /tmp/picko-phase-5-status-smoke.log; then
  echo "Phase 5 status report did not mention whole-plan audit shell literal safety coverage." >&2
  exit 1
fi
if ! grep -q "evidence template coverage" /tmp/picko-phase-5-status-smoke.log; then
  echo "Phase 5 status report did not mention whole-plan audit evidence template coverage." >&2
  exit 1
fi
if ! grep -q "evidence directory cleanliness" /tmp/picko-phase-5-status-smoke.log; then
  echo "Phase 5 status report did not mention whole-plan audit evidence directory cleanliness coverage." >&2
  exit 1
fi

if scripts/report-phase-5-status.sh \
  --evidence "$status_missing_environment_evidence" \
  --host-timestamp "bad/path" >/tmp/picko-phase-5-status-bad-timestamp.log; then
  echo "Phase 5 status report accepted a non filename-safe host timestamp." >&2
  exit 1
fi

if scripts/report-phase-5-status.sh \
  --evidence /tmp/picko-phase-5-missing-evidence.md \
  --fail-on-incomplete >/tmp/picko-phase-5-status-missing-evidence.log; then
  echo "Phase 5 status report accepted a missing evidence document with --fail-on-incomplete." >&2
  exit 1
fi
if ! grep -q "Create the final Phase 5 evidence document with scripts/create-phase-5-evidence.sh." /tmp/picko-phase-5-status-missing-evidence.log; then
  echo "Phase 5 status report did not include evidence document creation in next required evidence." >&2
  exit 1
fi

status_failed_manual_evidence="/tmp/picko-phase-5-status-failed-manual-evidence.md"
status_failed_manual_artifact="docs/phase-5-evidence/manual-status-failed-smoke/ios/authorization/evidence.txt"
mkdir -p "$(dirname "$status_failed_manual_artifact")"
printf 'non-production failed manual status smoke\n' > "$status_failed_manual_artifact"
cat > "$status_failed_manual_evidence" <<MARKDOWN
| Scenario | Platform | Result | Evidence path | Notes |
| --- | --- | --- | --- | --- |
| First Photos authorization | iOS | Failed | \`$status_failed_manual_artifact\` | Non-production smoke |
MARKDOWN
scripts/report-phase-5-status.sh \
  --evidence "$status_failed_manual_evidence" >/tmp/picko-phase-5-status-failed-manual.log
if grep -q "Manual verification row has captured evidence: First Photos authorization / iOS." /tmp/picko-phase-5-status-failed-manual.log; then
  echo "Phase 5 status report marked a failed manual verification row as ready." >&2
  exit 1
fi
rm -f "$status_failed_manual_artifact"

status_missing_manual_artifact_evidence="/tmp/picko-phase-5-status-missing-manual-artifact-evidence.md"
cat > "$status_missing_manual_artifact_evidence" <<'MARKDOWN'
| Scenario | Platform | Result | Evidence path | Notes |
| --- | --- | --- | --- | --- |
| First Photos authorization | iOS | Passed | `docs/phase-5-evidence/manual-status-missing-smoke/ios/authorization/missing.txt` | Non-production smoke |
MARKDOWN
scripts/report-phase-5-status.sh \
  --evidence "$status_missing_manual_artifact_evidence" >/tmp/picko-phase-5-status-missing-manual-artifact.log
if grep -q "Manual verification row has captured evidence: First Photos authorization / iOS." /tmp/picko-phase-5-status-missing-manual-artifact.log; then
  echo "Phase 5 status report marked a manual verification row with missing artifact as ready." >&2
  exit 1
fi

status_mismatched_manual_artifact="docs/phase-5-evidence/manual-status-mismatch-smoke/ios/authorization/evidence.txt"
mkdir -p "$(dirname "$status_mismatched_manual_artifact")"
printf 'non-production mismatched manual status smoke\n' > "$status_mismatched_manual_artifact"
status_mismatched_manual_evidence="/tmp/picko-phase-5-status-mismatched-manual-evidence.md"
cat > "$status_mismatched_manual_evidence" <<MARKDOWN
| Scenario | Platform | Result | Evidence path | Notes |
| --- | --- | --- | --- | --- |
| First Photos authorization | macOS | Passed | \`$status_mismatched_manual_artifact\` | Non-production smoke |
MARKDOWN
scripts/report-phase-5-status.sh \
  --evidence "$status_mismatched_manual_evidence" >/tmp/picko-phase-5-status-mismatched-manual.log
if grep -q "Manual verification row has captured evidence: First Photos authorization / macOS." /tmp/picko-phase-5-status-mismatched-manual.log; then
  echo "Phase 5 status report marked a manual verification row with a mismatched scenario folder as ready." >&2
  exit 1
fi
rm -f "$status_mismatched_manual_artifact"

status_directory_manual_dir="docs/phase-5-evidence/manual-status-directory-smoke/macos/authorization"
mkdir -p "$status_directory_manual_dir"
status_directory_manual_evidence="/tmp/picko-phase-5-status-directory-manual-evidence.md"
cat > "$status_directory_manual_evidence" <<MARKDOWN
| Scenario | Platform | Result | Evidence path | Notes |
| --- | --- | --- | --- | --- |
| First Photos authorization | macOS | Passed | \`$status_directory_manual_dir\` | Non-production smoke |
MARKDOWN
scripts/report-phase-5-status.sh \
  --evidence "$status_directory_manual_evidence" >/tmp/picko-phase-5-status-directory-manual.log
if grep -q "Manual verification row has captured evidence: First Photos authorization / macOS." /tmp/picko-phase-5-status-directory-manual.log; then
  echo "Phase 5 status report marked a manual verification row pointing at a directory as ready." >&2
  exit 1
fi

status_unsupported_manual_artifact="docs/phase-5-evidence/manual-status-unsupported-smoke/macos/authorization/evidence.swift"
mkdir -p "$(dirname "$status_unsupported_manual_artifact")"
printf 'not a captured evidence artifact\n' > "$status_unsupported_manual_artifact"
status_unsupported_manual_evidence="/tmp/picko-phase-5-status-unsupported-manual-evidence.md"
cat > "$status_unsupported_manual_evidence" <<MARKDOWN
| Scenario | Platform | Result | Evidence path | Notes |
| --- | --- | --- | --- | --- |
| First Photos authorization | macOS | Passed | \`$status_unsupported_manual_artifact\` | Non-production smoke |
MARKDOWN
scripts/report-phase-5-status.sh \
  --evidence "$status_unsupported_manual_evidence" >/tmp/picko-phase-5-status-unsupported-manual.log
if grep -q "Manual verification row has captured evidence: First Photos authorization / macOS." /tmp/picko-phase-5-status-unsupported-manual.log; then
  echo "Phase 5 status report marked a manual verification row with unsupported artifact type as ready." >&2
  exit 1
fi
rm -f "$status_unsupported_manual_artifact"

status_bad_notes_manual_artifact="docs/phase-5-evidence/manual-status-bad-notes-smoke/macos/authorization/evidence.txt"
mkdir -p "$(dirname "$status_bad_notes_manual_artifact")"
printf 'non-production bad notes manual status smoke\n' > "$status_bad_notes_manual_artifact"
status_bad_notes_manual_evidence="/tmp/picko-phase-5-status-bad-notes-manual-evidence.md"
cat > "$status_bad_notes_manual_evidence" <<MARKDOWN
| Scenario | Platform | Result | Evidence path | Notes |
| --- | --- | --- | --- | --- |
| First Photos authorization | macOS | Passed | \`$status_bad_notes_manual_artifact\` | Non-production | table break |
MARKDOWN
scripts/report-phase-5-status.sh \
  --evidence "$status_bad_notes_manual_evidence" >/tmp/picko-phase-5-status-bad-notes-manual.log
if grep -q "Manual verification row has captured evidence: First Photos authorization / macOS." /tmp/picko-phase-5-status-bad-notes-manual.log; then
  echo "Phase 5 status report marked a manual verification row with table-breaking notes as ready." >&2
  exit 1
fi
status_sensitive_notes_manual_evidence="/tmp/picko-phase-5-status-sensitive-notes-manual-evidence.md"
cat > "$status_sensitive_notes_manual_evidence" <<MARKDOWN
| Scenario | Platform | Result | Evidence path | Notes |
| --- | --- | --- | --- | --- |
| First Photos authorization | macOS | Passed | \`$status_bad_notes_manual_artifact\` | Personal Photos library smoke |
MARKDOWN
scripts/report-phase-5-status.sh \
  --evidence "$status_sensitive_notes_manual_evidence" >/tmp/picko-phase-5-status-sensitive-notes-manual.log
if grep -q "Manual verification row has captured evidence: First Photos authorization / macOS." /tmp/picko-phase-5-status-sensitive-notes-manual.log; then
  echo "Phase 5 status report marked a manual verification row with personal/production Photos notes as ready." >&2
  exit 1
fi
status_sensitive_content_manual_artifact="docs/phase-5-evidence/manual-status-sensitive-content-smoke/macos/authorization/sensitive.txt"
mkdir -p "$(dirname "$status_sensitive_content_manual_artifact")"
printf 'localIdentifier: sensitive-smoke\n' > "$status_sensitive_content_manual_artifact"
status_sensitive_content_manual_evidence="/tmp/picko-phase-5-status-sensitive-content-manual-evidence.md"
cat > "$status_sensitive_content_manual_evidence" <<MARKDOWN
| Scenario | Platform | Result | Evidence path | Notes |
| --- | --- | --- | --- | --- |
| First Photos authorization | macOS | Passed | \`$status_sensitive_content_manual_artifact\` | Non-production smoke |
MARKDOWN
scripts/report-phase-5-status.sh \
  --evidence "$status_sensitive_content_manual_evidence" >/tmp/picko-phase-5-status-sensitive-content-manual.log
if grep -q "Manual verification row has captured evidence: First Photos authorization / macOS." /tmp/picko-phase-5-status-sensitive-content-manual.log; then
  echo "Phase 5 status report marked a manual verification row with sensitive text artifact content as ready." >&2
  exit 1
fi
rm -f "$status_sensitive_content_manual_artifact"
status_empty_manual_artifact="docs/phase-5-evidence/manual-status-empty-smoke/macos/authorization/empty.txt"
mkdir -p "$(dirname "$status_empty_manual_artifact")"
: > "$status_empty_manual_artifact"
status_empty_manual_evidence="/tmp/picko-phase-5-status-empty-manual-evidence.md"
cat > "$status_empty_manual_evidence" <<MARKDOWN
| Scenario | Platform | Result | Evidence path | Notes |
| --- | --- | --- | --- | --- |
| First Photos authorization | macOS | Passed | \`$status_empty_manual_artifact\` | Non-production smoke |
MARKDOWN
scripts/report-phase-5-status.sh \
  --evidence "$status_empty_manual_evidence" >/tmp/picko-phase-5-status-empty-manual.log
if grep -q "Manual verification row has captured evidence: First Photos authorization / macOS." /tmp/picko-phase-5-status-empty-manual.log; then
  echo "Phase 5 status report marked a manual verification row with an empty artifact as ready." >&2
  exit 1
fi
rm -f "$status_empty_manual_artifact"
rm -f "$status_bad_notes_manual_artifact"

status_missing_runtime_log_evidence="/tmp/picko-phase-5-status-missing-runtime-log-evidence.md"
status_empty_runtime_log="docs/phase-5-evidence/privacy/status-empty-runtime-smoke.log"
status_empty_runtime_evidence="/tmp/picko-phase-5-status-empty-runtime-evidence.md"
status_sensitive_runtime_log="docs/phase-5-evidence/privacy/status-sensitive-runtime-smoke.log"
status_sensitive_runtime_evidence="/tmp/picko-phase-5-status-sensitive-runtime-evidence.md"
cat > "$status_missing_runtime_log_evidence" <<'MARKDOWN'
| Check | Result | Evidence |
| --- | --- | --- |
| Runtime logs checked for photo contents or sensitive metadata | Passed | scripts/audit-runtime-privacy-logs.sh docs/phase-5-evidence/privacy/missing-runtime-smoke.log |
MARKDOWN
scripts/report-phase-5-status.sh \
  --evidence "$status_missing_runtime_log_evidence" >/tmp/picko-phase-5-status-missing-runtime-log.log
if grep -q "Runtime privacy log audit evidence is referenced in final evidence." /tmp/picko-phase-5-status-missing-runtime-log.log; then
  echo "Phase 5 status report marked a missing runtime privacy log artifact as ready." >&2
  exit 1
fi
mkdir -p "$(dirname "$status_empty_runtime_log")"
: > "$status_empty_runtime_log"
cat > "$status_empty_runtime_evidence" <<MARKDOWN
## Privacy Review

| Check | Result | Evidence |
| --- | --- | --- |
| Runtime logs checked for photo contents or sensitive metadata | Passed | scripts/audit-runtime-privacy-logs.sh $status_empty_runtime_log |
MARKDOWN
scripts/report-phase-5-status.sh \
  --evidence "$status_empty_runtime_evidence" >/tmp/picko-phase-5-status-empty-runtime.log
if grep -q "Runtime privacy log audit evidence is referenced in final evidence." /tmp/picko-phase-5-status-empty-runtime.log; then
  echo "Phase 5 status report marked an empty runtime privacy log artifact as ready." >&2
  rm -f "$status_empty_runtime_log"
  exit 1
fi
rm -f "$status_empty_runtime_log"
printf 'localIdentifier: sensitive-runtime-smoke\n' > "$status_sensitive_runtime_log"
cat > "$status_sensitive_runtime_evidence" <<MARKDOWN
## Privacy Review

| Check | Result | Evidence |
| --- | --- | --- |
| Runtime logs checked for photo contents or sensitive metadata | Passed | scripts/audit-runtime-privacy-logs.sh $status_sensitive_runtime_log |
MARKDOWN
scripts/report-phase-5-status.sh \
  --evidence "$status_sensitive_runtime_evidence" >/tmp/picko-phase-5-status-sensitive-runtime.log
if grep -q "Runtime privacy log audit evidence is referenced in final evidence." /tmp/picko-phase-5-status-sensitive-runtime.log; then
  echo "Phase 5 status report marked a sensitive runtime privacy log artifact as ready." >&2
  rm -f "$status_sensitive_runtime_log"
  exit 1
fi
rm -f "$status_sensitive_runtime_log"
status_wrong_section_runtime_log="docs/phase-5-evidence/privacy/status-wrong-section-runtime-smoke.log"
status_wrong_section_runtime_evidence="/tmp/picko-phase-5-status-wrong-section-runtime-evidence.md"
mkdir -p "$(dirname "$status_wrong_section_runtime_log")"
printf 'non-production runtime status smoke\n' > "$status_wrong_section_runtime_log"
cat > "$status_wrong_section_runtime_evidence" <<MARKDOWN
## Operator Notes

| Check | Result | Evidence |
| --- | --- | --- |
| Runtime logs checked for photo contents or sensitive metadata | Passed | scripts/audit-runtime-privacy-logs.sh $status_wrong_section_runtime_log |
MARKDOWN
scripts/report-phase-5-status.sh \
  --evidence "$status_wrong_section_runtime_evidence" >/tmp/picko-phase-5-status-wrong-section-runtime.log
if grep -q "Runtime privacy log audit evidence is referenced in final evidence." /tmp/picko-phase-5-status-wrong-section-runtime.log; then
  echo "Phase 5 status report marked runtime privacy evidence outside Privacy Review as ready." >&2
  exit 1
fi
rm -f "$status_wrong_section_runtime_log"

if scripts/report-phase-5-status.sh \
  --evidence docs/phase-5-evidence-2026-05-31.md \
  --fail-on-incomplete >/tmp/picko-phase-5-status-fail-on-incomplete.log; then
  echo "Phase 5 status report accepted incomplete final evidence with --fail-on-incomplete." >&2
  exit 1
fi
if ! grep -q "Manual Photos evidence directory is incomplete for: First Photos authorization / macOS; Pre-delete basket triggers Photos confirmation / macOS." /tmp/picko-phase-5-status-fail-on-incomplete.log; then
  echo "Phase 5 status report did not list the concrete remaining manual evidence gaps." >&2
  exit 1
fi
if grep -q "Capture non-production authorization/delete/privacy evidence" /tmp/picko-phase-5-status-fail-on-incomplete.log; then
  echo "Phase 5 status report still asks for generic manual evidence categories after concrete row analysis." >&2
  exit 1
fi

status_complete_evidence="/tmp/picko-phase-5-status-complete-evidence.md"
status_complete_baseline="docs/phase-5-evidence/status-complete-baseline-smoke.json"
status_complete_manual_dir="docs/phase-5-evidence/manual-status-complete-smoke"
status_complete_privacy_log="docs/phase-5-evidence/privacy/status-complete-runtime-smoke.log"
status_complete_ios_1000="docs/phase-5-evidence/status-complete-ios/photos-1000-smoke.jpg"
status_complete_ios_10000="docs/phase-5-evidence/status-complete-ios/photos-10000-smoke.jpg"
status_complete_ios_50000="docs/phase-5-evidence/status-complete-ios/photos-50000-smoke.jpg"
trap 'rm -rf "$status_complete_manual_dir" "$(dirname "$status_complete_ios_1000")"; rm -f "$status_complete_baseline" "$status_complete_privacy_log"; cleanup_project_smoke_artifacts' EXIT
mkdir -p "$(dirname "$status_complete_baseline")" "$(dirname "$status_complete_privacy_log")" "$(dirname "$status_complete_ios_1000")"
printf '{"mode":"Photos-backed fixture","photosLibraryLabel":"Non-production smoke library","rows":[{"assetCount":1000,"elapsedSeconds":1.0,"assetsPerSecond":1000.0},{"assetCount":10000,"elapsedSeconds":2.0,"assetsPerSecond":5000.0},{"assetCount":50000,"elapsedSeconds":10.0,"assetsPerSecond":5000.0}]}\n' > "$status_complete_baseline"
printf 'non-production runtime log smoke\n' > "$status_complete_privacy_log"
printf 'non-production benchmark screenshot smoke\n' > "$status_complete_ios_1000"
printf 'non-production benchmark screenshot smoke\n' > "$status_complete_ios_10000"
printf 'non-production benchmark screenshot smoke\n' > "$status_complete_ios_50000"
scripts/prepare-phase-5-manual-evidence.sh --output "$status_complete_manual_dir" >/dev/null
for evidence_dir in \
  "$status_complete_manual_dir/ios/authorization" \
  "$status_complete_manual_dir/ios/limited-library" \
  "$status_complete_manual_dir/ios/delete-confirmation" \
  "$status_complete_manual_dir/ios/metadata-benchmark" \
  "$status_complete_manual_dir/macos/authorization" \
  "$status_complete_manual_dir/macos/delete-confirmation" \
  "$status_complete_manual_dir/privacy"
do
  printf 'non-production evidence placeholder\n' > "$evidence_dir/evidence.txt"
done
cat > "$status_complete_evidence" <<MARKDOWN
| Field | Value |
| --- | --- |
| iOS Simulator | iPhone 17 Pro, iOS 26.4, disposable Photos library |
| Test Photos Library | Non-production simulator fixture and non-production Mac Photos library |

| Gate | Command | Result | Evidence |
| --- | --- | --- | --- |
| Local Phase 5 | \`scripts/verify-phase-5-local.sh\` | Passed | Terminal smoke |
| Platform Phase 5 | \`scripts/verify-phase-5-platform.sh\` | Passed | Terminal smoke |
| Privacy logging | \`scripts/audit-privacy-logging.sh\` | Passed | Terminal smoke |

## Host Photos-Backed Metadata Baseline

scripts/capture-metadata-baseline.sh --photos --confirm-non-production-photos --photos-library-label "Non-production smoke library" --validate-only 1000 10000 50000
Preflight status: Passed locally in smoke with --validate-only; no Photos library was read.
Raw JSON evidence path: \`$status_complete_baseline\`

## iOS Simulator Photos-Backed Benchmark

| Asset count | Elapsed seconds | Assets / second | Evidence |
| ---: | ---: | ---: | --- |
| 1,000 | 1.0000 | 1000.0000 | \`$status_complete_ios_1000\` |
| 10,000 | 2.0000 | 5000.0000 | \`$status_complete_ios_10000\` |
| 50,000 | 10.0000 | 5000.0000 | \`$status_complete_ios_50000\` |

## Privacy Review

| Check | Result | Evidence |
| --- | --- | --- |
| Product code has no broad logging calls | Passed | \`scripts/audit-privacy-logging.sh\` |
| Thumbnail cache remains in process memory only | Passed | Code review smoke |
| Runtime logs checked for photo contents or sensitive metadata | Passed | scripts/audit-runtime-privacy-logs.sh $status_complete_privacy_log |

| Scenario | Platform | Result | Evidence path | Notes |
| --- | --- | --- | --- | --- |
| First Photos authorization | iOS | Passed | \`$status_complete_manual_dir/ios/authorization/evidence.txt\` | Non-production smoke |
| Limited library state | iOS | Passed | \`$status_complete_manual_dir/ios/limited-library/evidence.txt\` | Non-production smoke |
| Pre-delete basket triggers Photos confirmation | iOS | Passed | \`$status_complete_manual_dir/ios/delete-confirmation/evidence.txt\` | Non-production smoke |
| First Photos authorization | macOS | Passed | \`$status_complete_manual_dir/macos/authorization/evidence.txt\` | Non-production smoke |
| Pre-delete basket triggers Photos confirmation | macOS | Passed | \`$status_complete_manual_dir/macos/delete-confirmation/evidence.txt\` | Non-production smoke |
| Recently Deleted recovery explanation | iOS/macOS | Passed | \`$status_complete_manual_dir/privacy/evidence.txt\` | Non-production smoke |

Manual evidence checked: scripts/check-phase-5-manual-evidence.sh $status_complete_manual_dir
MARKDOWN
scripts/report-phase-5-status.sh \
  --evidence "$status_complete_evidence" \
  --fail-on-incomplete >/tmp/picko-phase-5-status-complete.log
if ! grep -q "No remaining Phase 5 evidence gaps detected." /tmp/picko-phase-5-status-complete.log; then
  echo "Phase 5 status report did not print the complete-state summary." >&2
  exit 1
fi
if ! grep -q "scripts/audit-mvp-next-completion.sh" /tmp/picko-phase-5-status-complete.log \
  || ! grep -q "Phase 5 shell literal safety gate" /tmp/picko-phase-5-status-complete.log \
  || ! grep -q "evidence template coverage" /tmp/picko-phase-5-status-complete.log \
  || ! grep -q "evidence directory cleanliness" /tmp/picko-phase-5-status-complete.log; then
  echo "Phase 5 status report complete-state summary did not include whole-plan audit guidance." >&2
  exit 1
fi
if grep -q "Next required external evidence" /tmp/picko-phase-5-status-complete.log; then
  echo "Phase 5 status report printed next external evidence for a complete evidence document." >&2
  exit 1
fi
scripts/phase-5-external-evidence-checklist.sh \
  --evidence "$status_complete_evidence" \
  --manual-dir "$status_complete_manual_dir" \
  --date 2026-06-03 >/tmp/picko-phase-5-external-complete.log
if ! grep -q "Host Photos-backed baseline JSON is already referenced; no capture or write-back step is currently required." /tmp/picko-phase-5-external-complete.log; then
  echo "External evidence checklist did not skip host baseline steps for complete evidence." >&2
  exit 1
fi
if grep -q "scripts/update-phase-5-host-baseline.sh" /tmp/picko-phase-5-external-complete.log; then
  echo "External evidence checklist included host baseline write-back for complete evidence." >&2
  exit 1
fi
scripts/phase-5-external-evidence-checklist.sh \
  --evidence "$status_ready_preflight_evidence" \
  --manual-dir "$status_complete_manual_dir" \
  --date 2026-06-03 >/tmp/picko-phase-5-external-ready-preflight.log
if ! grep -q "Host Photos-backed baseline preflight is already recorded as Passed." /tmp/picko-phase-5-external-ready-preflight.log; then
  echo "External evidence checklist did not skip the host baseline preflight after it was recorded." >&2
  exit 1
fi
if grep -q -- "--validate-only" /tmp/picko-phase-5-external-ready-preflight.log; then
  echo "External evidence checklist still asked to run --validate-only after a recorded host baseline preflight." >&2
  exit 1
fi
status_complete_bad_privacy_section_evidence="/tmp/picko-phase-5-status-complete-bad-privacy-section-evidence.md"
status_complete_empty_runtime_log="docs/phase-5-evidence/privacy/status-complete-empty-runtime-smoke.log"
status_complete_empty_runtime_evidence="/tmp/picko-phase-5-status-complete-empty-runtime-evidence.md"
status_complete_sensitive_runtime_log="docs/phase-5-evidence/privacy/status-complete-sensitive-runtime-smoke.log"
status_complete_sensitive_runtime_evidence="/tmp/picko-phase-5-status-complete-sensitive-runtime-evidence.md"
cp "$status_complete_evidence" "$status_complete_bad_privacy_section_evidence"
python3 - "$status_complete_bad_privacy_section_evidence" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()
text = text.replace("## Privacy Review", "## Operator Notes", 1)
path.write_text(text)
PY
scripts/phase-5-external-evidence-checklist.sh \
  --evidence "$status_complete_bad_privacy_section_evidence" \
  --manual-dir "$status_complete_manual_dir" \
  --date 2026-06-03 >/tmp/picko-phase-5-external-complete-bad-privacy-section.log
if grep -q "Runtime privacy log audit evidence is already referenced" /tmp/picko-phase-5-external-complete-bad-privacy-section.log; then
  echo "External evidence checklist skipped runtime privacy write-back when evidence was outside Privacy Review." >&2
  exit 1
fi
if ! grep -q "scripts/record-runtime-privacy-evidence.sh" /tmp/picko-phase-5-external-complete-bad-privacy-section.log; then
  echo "External evidence checklist did not ask to record runtime privacy evidence after Privacy Review section was missing." >&2
  exit 1
fi
: > "$status_complete_empty_runtime_log"
python3 - "$status_complete_evidence" "$status_complete_empty_runtime_evidence" "$status_complete_privacy_log" "$status_complete_empty_runtime_log" <<'PY'
import sys
from pathlib import Path

source = Path(sys.argv[1])
target = Path(sys.argv[2])
old_log = sys.argv[3]
new_log = sys.argv[4]
target.write_text(source.read_text().replace(old_log, new_log))
PY
scripts/phase-5-external-evidence-checklist.sh \
  --evidence "$status_complete_empty_runtime_evidence" \
  --manual-dir "$status_complete_manual_dir" \
  --date 2026-06-03 >/tmp/picko-phase-5-external-complete-empty-runtime.log
if grep -q "Runtime privacy log audit evidence is already referenced" /tmp/picko-phase-5-external-complete-empty-runtime.log; then
  echo "External evidence checklist skipped runtime privacy write-back when the referenced runtime log was empty." >&2
  rm -f "$status_complete_empty_runtime_log"
  exit 1
fi
if ! grep -q "scripts/record-runtime-privacy-evidence.sh" /tmp/picko-phase-5-external-complete-empty-runtime.log; then
  echo "External evidence checklist did not ask to record runtime privacy evidence after the referenced log was empty." >&2
  rm -f "$status_complete_empty_runtime_log"
  exit 1
fi
rm -f "$status_complete_empty_runtime_log"
printf 'localIdentifier: sensitive-runtime-smoke\n' > "$status_complete_sensitive_runtime_log"
python3 - "$status_complete_evidence" "$status_complete_sensitive_runtime_evidence" "$status_complete_privacy_log" "$status_complete_sensitive_runtime_log" <<'PY'
import sys
from pathlib import Path

source = Path(sys.argv[1])
target = Path(sys.argv[2])
old_log = sys.argv[3]
new_log = sys.argv[4]
target.write_text(source.read_text().replace(old_log, new_log))
PY
scripts/phase-5-external-evidence-checklist.sh \
  --evidence "$status_complete_sensitive_runtime_evidence" \
  --manual-dir "$status_complete_manual_dir" \
  --date 2026-06-03 >/tmp/picko-phase-5-external-complete-sensitive-runtime.log
if grep -q "Runtime privacy log audit evidence is already referenced" /tmp/picko-phase-5-external-complete-sensitive-runtime.log; then
  echo "External evidence checklist skipped runtime privacy write-back when the referenced runtime log contained sensitive metadata." >&2
  rm -f "$status_complete_sensitive_runtime_log"
  exit 1
fi
if ! grep -q "scripts/record-runtime-privacy-evidence.sh" /tmp/picko-phase-5-external-complete-sensitive-runtime.log; then
  echo "External evidence checklist did not ask to record runtime privacy evidence after the referenced log contained sensitive metadata." >&2
  rm -f "$status_complete_sensitive_runtime_log"
  exit 1
fi
rm -f "$status_complete_sensitive_runtime_log"
status_complete_bad_host_section_evidence="/tmp/picko-phase-5-status-complete-bad-host-section-evidence.md"
cp "$status_complete_evidence" "$status_complete_bad_host_section_evidence"
python3 - "$status_complete_bad_host_section_evidence" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()
text = text.replace("## Host Photos-Backed Metadata Baseline", "## Operator Notes", 1)
path.write_text(text)
PY
scripts/phase-5-external-evidence-checklist.sh \
  --evidence "$status_complete_bad_host_section_evidence" \
  --manual-dir "$status_complete_manual_dir" \
  --date 2026-06-03 >/tmp/picko-phase-5-external-complete-bad-host-section.log
if grep -q "Host Photos-backed baseline JSON is already referenced; no capture or write-back step is currently required." /tmp/picko-phase-5-external-complete-bad-host-section.log; then
  echo "External evidence checklist skipped host baseline steps when preflight evidence was outside the host baseline section." >&2
  exit 1
fi
if ! grep -q "scripts/update-phase-5-host-baseline.sh" /tmp/picko-phase-5-external-complete-bad-host-section.log; then
  echo "External evidence checklist did not ask to write back host baseline after host preflight section was missing." >&2
  exit 1
fi
status_complete_with_gates_evidence="/tmp/picko-phase-5-status-complete-with-gates-evidence.md"
cp "$status_complete_evidence" "$status_complete_with_gates_evidence"
cat >> "$status_complete_with_gates_evidence" <<MARKDOWN

| Gate | Command | Result | Evidence |
| --- | --- | --- | --- |
| Evidence completeness | \`scripts/check-phase-5-evidence.sh docs/phase-5-evidence-YYYY-MM-DD.md\` | Passed | Terminal smoke |
| Manual evidence completeness | \`scripts/check-phase-5-manual-evidence.sh $status_complete_manual_dir\` | Passed | Terminal smoke |
MARKDOWN
scripts/phase-5-external-evidence-checklist.sh \
  --evidence "$status_complete_with_gates_evidence" \
  --manual-dir "$status_complete_manual_dir" \
  --date 2026-06-03 >/tmp/picko-phase-5-external-complete-with-gates.log
if ! grep -q "Final completeness gates are already recorded as Passed; no write-back step is currently required." /tmp/picko-phase-5-external-complete-with-gates.log; then
  echo "External evidence checklist did not skip final completeness gates for complete evidence." >&2
  exit 1
fi
if grep -q "scripts/finalize-phase-5-evidence.sh" /tmp/picko-phase-5-external-complete-with-gates.log; then
  echo "External evidence checklist included final evidence wrapper write-back for complete evidence." >&2
  exit 1
fi
if grep -q "scripts/record-phase-5-completeness-gates.sh" /tmp/picko-phase-5-external-complete-with-gates.log; then
  echo "External evidence checklist included manual completeness gate write-back for complete evidence." >&2
  exit 1
fi
if ! grep -q "Phase 5 shell literal safety gate" /tmp/picko-phase-5-external-complete-with-gates.log; then
  echo "External evidence checklist complete branch did not mention whole-plan audit shell literal safety coverage." >&2
  exit 1
fi
if ! grep -q "evidence template coverage" /tmp/picko-phase-5-external-complete-with-gates.log; then
  echo "External evidence checklist complete branch did not mention whole-plan audit evidence template coverage." >&2
  exit 1
fi
if ! grep -q "evidence directory cleanliness" /tmp/picko-phase-5-external-complete-with-gates.log; then
  echo "External evidence checklist complete branch did not mention whole-plan audit evidence directory cleanliness coverage." >&2
  exit 1
fi
status_complete_bad_gates_evidence="/tmp/picko-phase-5-status-complete-bad-gates-evidence.md"
cp "$status_complete_evidence" "$status_complete_bad_gates_evidence"
cat >> "$status_complete_bad_gates_evidence" <<'MARKDOWN'

| Gate | Command | Result | Evidence |
| --- | --- | --- | --- |
| Evidence completeness | `scripts/not-the-evidence-checker.sh docs/phase-5-evidence-YYYY-MM-DD.md` | Passed | Terminal smoke |
| Manual evidence completeness | `scripts/not-the-manual-checker.sh docs/phase-5-evidence/manual-YYYY-MM-DD` | Passed | Terminal smoke |
MARKDOWN
scripts/phase-5-external-evidence-checklist.sh \
  --evidence "$status_complete_bad_gates_evidence" \
  --manual-dir "$status_complete_manual_dir" \
  --date 2026-06-03 >/tmp/picko-phase-5-external-complete-bad-gates.log
if grep -q "Final completeness gates are already recorded as Passed" /tmp/picko-phase-5-external-complete-bad-gates.log; then
  echo "External evidence checklist skipped final completeness gates with mismatched gate commands." >&2
  exit 1
fi
if ! grep -q "scripts/finalize-phase-5-evidence.sh" /tmp/picko-phase-5-external-complete-bad-gates.log; then
  echo "External evidence checklist did not ask to finalize evidence after mismatched gate commands." >&2
  exit 1
fi
if ! grep -q "scripts/record-phase-5-completeness-gates.sh" /tmp/picko-phase-5-external-complete-bad-gates.log; then
  echo "External evidence checklist did not include equivalent manual completeness gates after mismatched gate commands." >&2
  exit 1
fi

cleanup_project_smoke_artifacts
scripts/check-phase-5-evidence-cleanliness.sh docs/phase-5-evidence

echo "Phase 5 local verification passed."
