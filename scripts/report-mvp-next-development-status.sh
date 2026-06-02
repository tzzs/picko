#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/report-mvp-next-development-status.sh [--plan PLAN_MD] [--product-spec SPEC_MD] [--agents AGENTS_MD] [--evidence EVIDENCE_MD] [--manual-dir DIR] [--handoff HANDOFF_MD] [--date YYYY-MM-DD] [--host-timestamp ID] [--fail-on-incomplete]

Reports the current MVP Next Development Plan status from local, read-only
evidence. This script does not read Photos libraries, launch apps, capture
screenshots, run benchmarks, delete assets, or edit evidence files.
USAGE
}

evidence_path="docs/phase-5-evidence-$(date +%Y-%m-%d).md"
manual_dir="docs/phase-5-evidence/manual-$(date +%Y-%m-%d)"
plan_path="docs/MVP-Next-Development-Plan.md"
product_spec_path="docs/MVP-Product-Spec.md"
agents_path="AGENTS.md"
handoff_path=""
capture_date="$(date +%Y-%m-%d)"
host_capture_timestamp="$(date +%Y%m%d-%H%M%S)"
fail_on_incomplete=0
evidence_path_provided=0
manual_dir_provided=0
handoff_path_provided=0
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
    --plan)
      if [[ $# -lt 2 ]]; then
        echo "--plan requires a path." >&2
        exit 64
      fi
      plan_path="$2"
      shift 2
      ;;
    --product-spec)
      if [[ $# -lt 2 ]]; then
        echo "--product-spec requires a path." >&2
        exit 64
      fi
      product_spec_path="$2"
      shift 2
      ;;
    --agents)
      if [[ $# -lt 2 ]]; then
        echo "--agents requires a path." >&2
        exit 64
      fi
      agents_path="$2"
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
    --handoff)
      if [[ $# -lt 2 ]]; then
        echo "--handoff requires a path." >&2
        exit 64
      fi
      handoff_path="$2"
      handoff_path_provided=1
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

if [[ "$capture_date" == *"TBD"* || ! "$capture_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "--date must be a concrete YYYY-MM-DD value." >&2
  exit 64
fi

if [[ -z "$handoff_path" ]]; then
  handoff_path="docs/phase-5-evidence/phase-5-external-handoff-$capture_date.md"
fi

if [[ "$handoff_path_provided" -eq 0 && ! -f "$handoff_path" ]]; then
  shopt -s nullglob
  handoff_candidates=(docs/phase-5-evidence/phase-5-external-handoff-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md)
  shopt -u nullglob
  if [[ "${#handoff_candidates[@]}" -gt 0 ]]; then
    handoff_path="${handoff_candidates[$((${#handoff_candidates[@]} - 1))]}"
  fi
fi

if [[ "$capture_date_provided" -eq 0 && -f "$handoff_path" ]]; then
  handoff_capture_date="$(sed -n 's/^Date: \([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\)$/\1/p' "$handoff_path" | head -n 1)"
  if [[ -n "$handoff_capture_date" ]]; then
    capture_date="$handoff_capture_date"
  fi
fi

if [[ "$host_capture_timestamp_provided" -eq 0 && -f "$handoff_path" ]]; then
  handoff_host_capture_timestamp="$(sed -n 's/^Host baseline timestamp: `\([^`][^`]*\)`$/\1/p' "$handoff_path" | head -n 1)"
  if [[ -n "$handoff_host_capture_timestamp" ]]; then
    host_capture_timestamp="$handoff_host_capture_timestamp"
  fi
fi

if [[ "$host_capture_timestamp" == *"TBD"* || ! "$host_capture_timestamp" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "--host-timestamp must be a concrete filename-safe value." >&2
  exit 64
fi

missing=0

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

require_path() {
  local label="$1"
  local path="$2"
  if [[ -e "$path" ]]; then
    pass "$label exists: $path"
  else
    warn "$label is missing: $path"
  fi
}

require_fixed_string() {
  local label="$1"
  local pattern="$2"
  local path="$3"
  if [[ -f "$path" ]] && rg --quiet --fixed-strings -- "$pattern" "$path"; then
    pass "$label is recorded."
  else
    warn "$label is missing or stale."
  fi
}

phase5_status_output="$(scripts/report-phase-5-status.sh \
  --evidence "$evidence_path" \
  --date "$capture_date" \
  --host-timestamp "$host_capture_timestamp")"

printf 'Picko MVP Next Development Status\n'
printf 'Worktree: %s\n\n' "$(pwd)"

printf 'Plan source:\n'
require_path "MVP Next Development Plan" "$plan_path"
require_path "MVP Product Spec" "$product_spec_path"
require_path "Repository Guidelines" "$agents_path"
require_fixed_string "Photos Adapter phase completion" "### Phase 2: Photos Access Adapter" "$plan_path"
require_fixed_string "Core Hardening phase completion" "### Phase 2.5: Core Follow-up Hardening" "$plan_path"
require_fixed_string "iOS MVP phase completion" "### Phase 3: iOS MVP App" "$plan_path"
require_fixed_string "macOS MVP phase completion" "### Phase 4: macOS MVP App" "$plan_path"
require_fixed_string "Phase 5 integration section" "### Phase 5: Integration Verification" "$plan_path"
require_fixed_string "Phase 5 in-progress state" "状态：进行中。" "$plan_path"
require_fixed_string "Plan SwiftData first-version persistence decision" "SwiftData 是第一版用户整理状态的权威本地存储。" "$plan_path"
require_fixed_string "Plan default operator command guidance" "默认优先运行无参数 status、checklist、host baseline helper、macOS capture helper、handoff checker、finalizer 和 whole-plan audit 命令" "$plan_path"
require_fixed_string "Plan default Phase 5 status command" "scripts/report-phase-5-status.sh" "$plan_path"
require_fixed_string "Plan default external evidence checklist command" "scripts/phase-5-external-evidence-checklist.sh" "$plan_path"
require_fixed_string "Plan default host baseline helper command" "scripts/prepare-phase-5-host-baseline-capture.sh" "$plan_path"
require_fixed_string "Plan default macOS manual capture helper command" "scripts/prepare-phase-5-macos-manual-capture.sh" "$plan_path"
require_fixed_string "Plan default handoff generation command" "需要重新生成 handoff 时优先运行默认 active-package 命令" "$plan_path"
require_fixed_string "Plan default handoff check command" "生成后优先运行无参数 \`scripts/check-phase-5-external-handoff.sh\` 检查最新 handoff 未过期" "$plan_path"
require_fixed_string "Plan default finalizer command" "scripts/finalize-phase-5-evidence.sh" "$plan_path"
require_fixed_string "Plan default whole-plan audit command" "scripts/audit-mvp-next-completion.sh" "$plan_path"
require_fixed_string "Plan evidence template checker command" "scripts/check-phase-5-evidence-template.sh" "$plan_path"
require_fixed_string "Repository guidelines default operator command guidance" "Default Phase 5 operator commands:" "$agents_path"
require_fixed_string "Repository guidelines default Phase 5 status command" "scripts/report-phase-5-status.sh" "$agents_path"
require_fixed_string "Repository guidelines default external evidence checklist command" "scripts/phase-5-external-evidence-checklist.sh" "$agents_path"
require_fixed_string "Repository guidelines default host baseline helper command" "scripts/prepare-phase-5-host-baseline-capture.sh" "$agents_path"
require_fixed_string "Repository guidelines default macOS manual capture helper command" "scripts/prepare-phase-5-macos-manual-capture.sh" "$agents_path"
require_fixed_string "Repository guidelines default handoff generation command" "scripts/create-phase-5-external-evidence-handoff.sh --output docs/phase-5-evidence/phase-5-external-handoff-YYYY-MM-DD.md" "$agents_path"
require_fixed_string "Repository guidelines default handoff check command" "scripts/check-phase-5-external-handoff.sh" "$agents_path"
require_fixed_string "Repository guidelines default finalizer command" "scripts/finalize-phase-5-evidence.sh" "$agents_path"
require_fixed_string "Repository guidelines default whole-plan audit command" "scripts/audit-mvp-next-completion.sh" "$agents_path"
require_fixed_string "Repository guidelines evidence template checker command" "scripts/check-phase-5-evidence-template.sh docs/Phase-5-Evidence-Template.md" "$agents_path"
require_fixed_string "Product spec SwiftData first-version persistence decision" "第一版确认使用 SwiftData，不采用纯 JSON 轻量文件作为主存储。" "$product_spec_path"
require_fixed_string "Product spec JSON storage boundary" "JSON 仍可用于 benchmark report、evidence、导入导出或调试快照，但不作为第一版用户整理状态的权威存储。" "$product_spec_path"
require_fixed_string "Host Photos-backed baseline gap" "host Photos-backed 真实基线仍待采集" "$plan_path"
require_fixed_string "macOS manual evidence gap" "macOS 手工截图仍待采集" "$plan_path"
printf '\n'

printf 'Phase structure:\n'
require_path "PickoCore target" "Sources/PickoCore"
require_path "PickoPhotos target" "Sources/PickoPhotos"
require_path "PickoApp target" "Sources/PickoApp"
require_path "PickoMacApp target" "Sources/PickoMacApp"
require_path "Swift package manifest" "Package.swift"
require_path "Xcode project" "Picko.xcodeproj"
printf '\n'

printf 'Phase 5 local evidence package:\n'
require_path "Phase 5 evidence document" "$evidence_path"
require_path "Phase 5 manual evidence directory" "$manual_dir"
if scripts/check-phase-5-external-evidence-readiness.sh \
  --evidence "$evidence_path" \
  --manual-dir "$manual_dir" \
  --date "$capture_date" \
  --host-timestamp "$host_capture_timestamp" >/dev/null 2>&1; then
  pass "External evidence readiness preflight passes."
else
  warn "External evidence readiness preflight fails."
fi
if [[ -f "$handoff_path" ]]; then
  if scripts/check-phase-5-external-handoff.sh \
    --handoff "$handoff_path" \
    --evidence "$evidence_path" \
    --manual-dir "$manual_dir" \
    --date "$capture_date" \
    --host-timestamp "$host_capture_timestamp" >/dev/null 2>&1; then
    pass "External evidence handoff is current: $handoff_path"
  else
    warn "External evidence handoff is stale or invalid: $handoff_path"
  fi
else
  warn "External evidence handoff is missing: $handoff_path"
fi
if scripts/check-phase-5-evidence-cleanliness.sh docs/phase-5-evidence >/dev/null 2>&1; then
  pass "Phase 5 evidence directory cleanliness passes."
else
  warn "Phase 5 evidence directory cleanliness fails."
fi
if scripts/check-phase-5-evidence-template.sh docs/Phase-5-Evidence-Template.md >/dev/null 2>&1; then
  pass "Phase 5 evidence template checker passes."
else
  warn "Phase 5 evidence template checker fails."
fi
printf '\n'

printf 'Phase 5 evidence status:\n'
printf '%s\n' "$phase5_status_output"

if printf '%s\n' "$phase5_status_output" | rg --quiet --fixed-strings "No remaining Phase 5 evidence gaps detected."; then
  pass "MVP Next Development Plan has no remaining Phase 5 evidence gaps."
else
  warn "MVP Next Development Plan is still waiting on Phase 5 external evidence."
fi

if [[ "$missing" -ne 0 ]]; then
  printf '\nMVP Next Development Plan status: incomplete.\n'
  if [[ "$fail_on_incomplete" -eq 1 ]]; then
    exit 1
  fi
else
  printf '\nMVP Next Development Plan status: complete by current local evidence.\n'
fi
